import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageHelper {
  ImageHelper._();

  static const String userAgent =
      'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

  static String getThumbnailPath(String fullPath) {
    final dir = p.dirname(fullPath);
    final ext = p.extension(fullPath);
    final base = p.basenameWithoutExtension(fullPath);
    return p.join(dir, '${base}_thumb$ext');
  }

  static Future<String> generateThumbnail(String sourcePath) async {
    final thumbPath = getThumbnailPath(sourcePath);
    if (File(thumbPath).existsSync()) return thumbPath;

    try {
      final compressed = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        thumbPath,
        quality: 75,
        minWidth: 150,
        minHeight: 150,
        format: CompressFormat.jpeg,
      );
      return compressed?.path ?? sourcePath;
    } catch (e) {
      dev.log('[ImageHelper] Thumbnail generation warning: $e', name: 'ImageHelper');
      return sourcePath;
    }
  }

  // Compresses and saves an image from a local file path with unique naming
  static Future<String> compressAndSaveLocalImage(
    String sourcePath, {
    int? productId,
    String? oldImagePath,
  }) async {
    dev.log('[ImageHelper] Step 1: Local image picked from $sourcePath', name: 'ImageHelper');
    final appDir = await getApplicationDocumentsDirectory();
    final productsDir = Directory(p.join(appDir.path, 'products'));
    if (!productsDir.existsSync()) {
      productsDir.createSync(recursive: true);
    }

    final filename = '${productId != null ? 'prod_${productId}_' : 'prod_new_'}${DateTime.now().millisecondsSinceEpoch}.jpg';
    final targetPath = p.join(productsDir.path, filename);

    dev.log('[ImageHelper] Step 2: Compressing local image to $targetPath', name: 'ImageHelper');
    String savedPath = targetPath;
    try {
      final compressed = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        targetPath,
        quality: 80,
        minWidth: 400,
        minHeight: 400,
        format: CompressFormat.jpeg,
      );
      savedPath = compressed?.path ?? targetPath;
    } catch (e) {
      dev.log('[ImageHelper] Native compression failed, copying original bytes: $e', name: 'ImageHelper');
      final bytes = await File(sourcePath).readAsBytes();
      await File(targetPath).writeAsBytes(bytes);
      savedPath = targetPath;
    }

    // If source file was a temporary file from image picker or cache, delete it immediately to free space
    try {
      final normalizedSource = p.normalize(sourcePath).toLowerCase();
      if ((normalizedSource.contains('cache') || normalizedSource.contains('temp')) && normalizedSource != p.normalize(savedPath).toLowerCase()) {
        final srcFile = File(sourcePath);
        if (srcFile.existsSync()) {
          srcFile.deleteSync();
        }
      }
    } catch (_) {}

    // Step 3: Evict old path and delete previous file if different
    if (oldImagePath != null && oldImagePath.isNotEmpty && oldImagePath != savedPath) {
      dev.log('[ImageHelper] Evicting old image at $oldImagePath', name: 'ImageHelper');
      try {
        final oldFile = File(oldImagePath);
        PaintingBinding.instance.imageCache.evict(FileImage(oldFile));
        if (oldFile.existsSync()) oldFile.deleteSync();

        final oldThumb = File(getThumbnailPath(oldImagePath));
        if (oldThumb.existsSync()) {
          PaintingBinding.instance.imageCache.evict(FileImage(oldThumb));
          oldThumb.deleteSync();
        }
      } catch (e) {
        dev.log('[ImageHelper] Cleanup old image warning: $e', name: 'ImageHelper');
      }
    }

    // Generate 150 px thumbnail
    await generateThumbnail(savedPath);
    dev.log('[ImageHelper] Step 4: Local image saved to $savedPath', name: 'ImageHelper');
    return savedPath;
  }

  // Downloads an image from HTTP/HTTPS URL or decodes data: URI and compresses it
  static Future<String> processAndSaveWebImage(
    String sourceUrl, {
    int? productId,
    String? oldImagePath,
  }) async {
    dev.log('[ImageHelper] Step 1: Processing web image (isDataUrl=${sourceUrl.startsWith("data:")}, length=${sourceUrl.length})', name: 'ImageHelper');

    final appDir = await getApplicationDocumentsDirectory();
    final productsDir = Directory(p.join(appDir.path, 'products'));
    if (!productsDir.existsSync()) {
      productsDir.createSync(recursive: true);
    }

    final filename = '${productId != null ? 'prod_${productId}_' : 'prod_new_'}${DateTime.now().millisecondsSinceEpoch}.jpg';
    final targetPath = p.join(productsDir.path, filename);

    Uint8List rawBytes;

    // Step 2: Download or base64 decode
    if (sourceUrl.startsWith('data:image')) {
      dev.log('[ImageHelper] Step 2: Decoding base64 data URI...', name: 'ImageHelper');
      final commaIndex = sourceUrl.indexOf(',');
      final base64Data = commaIndex != -1 ? sourceUrl.substring(commaIndex + 1) : sourceUrl;
      final cleanBase64 = base64Data.replaceAll(RegExp(r'\s+'), '');
      rawBytes = base64Decode(base64.normalize(cleanBase64));
      dev.log('[ImageHelper] Decoded ${rawBytes.length} bytes from base64.', name: 'ImageHelper');
    } else {
      dev.log('[ImageHelper] Step 2: Downloading image over HTTP/HTTPS: $sourceUrl...', name: 'ImageHelper');
      final dio = Dio(
        BaseOptions(
          headers: {'User-Agent': userAgent},
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 400,
        ),
      );
      final response = await dio.get<List<int>>(sourceUrl);
      if (response.data == null || response.data!.isEmpty) {
        throw Exception('Downloaded empty response from image URL');
      }
      rawBytes = Uint8List.fromList(response.data!);
      dev.log('[ImageHelper] Downloaded ${rawBytes.length} bytes successfully.', name: 'ImageHelper');
    }

    // Step 3: Compress image (native platform channel on main isolate)
    dev.log('[ImageHelper] Step 3: Compressing ${rawBytes.length} bytes to 400x400 JPEG...', name: 'ImageHelper');
    Uint8List compressedBytes;
    try {
      compressedBytes = await FlutterImageCompress.compressWithList(
        rawBytes,
        quality: 80,
        minWidth: 400,
        minHeight: 400,
        format: CompressFormat.jpeg,
      );
      dev.log('[ImageHelper] Compressed to ${compressedBytes.length} bytes.', name: 'ImageHelper');
    } catch (e) {
      dev.log('[ImageHelper] FlutterImageCompress fallback to raw bytes: $e', name: 'ImageHelper');
      compressedBytes = rawBytes;
    }

    // Step 4: Write to unique file
    dev.log('[ImageHelper] Step 4: Writing image file to $targetPath', name: 'ImageHelper');
    final file = File(targetPath);
    await file.writeAsBytes(compressedBytes);

    // Evict old path from image cache and delete old file
    if (oldImagePath != null && oldImagePath.isNotEmpty && oldImagePath != targetPath) {
      dev.log('[ImageHelper] Evicting old image at $oldImagePath', name: 'ImageHelper');
      try {
        final oldFile = File(oldImagePath);
        PaintingBinding.instance.imageCache.evict(FileImage(oldFile));
        if (oldFile.existsSync()) oldFile.deleteSync();

        final oldThumb = File(getThumbnailPath(oldImagePath));
        if (oldThumb.existsSync()) {
          PaintingBinding.instance.imageCache.evict(FileImage(oldThumb));
          oldThumb.deleteSync();
        }
      } catch (e) {
        dev.log('[ImageHelper] Old image cleanup warning: $e', name: 'ImageHelper');
      }
    }

    // Generate 150 px thumbnail
    await generateThumbnail(file.path);
    dev.log('[ImageHelper] Step 5: Finished processing. Path: $targetPath', name: 'ImageHelper');

    return file.path;
  }
}
