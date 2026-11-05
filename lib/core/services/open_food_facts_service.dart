import 'dart:io';
import 'package:dio/dio.dart';
import '../utils/image_helper.dart';

class OpenFoodFactsProduct {
  final String barcode;
  final String name;
  final String? brand;
  final String? imageUrl;
  final String? quantity;

  const OpenFoodFactsProduct({
    required this.barcode,
    required this.name,
    this.brand,
    this.imageUrl,
    this.quantity,
  });

  String get displayName {
    if (brand != null && brand!.isNotEmpty && !name.toLowerCase().contains(brand!.toLowerCase())) {
      return '$brand $name';
    }
    return name;
  }
}

class OpenFoodFactsService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 6),
      headers: {
        'User-Agent': 'ShopmatePOS/1.0',
      },
    ),
  );

  /// Looks up product details from Open Food Facts API v2 with fallback to UPCItemDB.
  /// Returns null on network error, offline state, or 404.
  static Future<OpenFoodFactsProduct?> lookup(String rawBarcode) async {
    final barcode = rawBarcode.replaceAll(RegExp(r'\s+'), '').trim();
    if (barcode.isEmpty) return null;

    final candidates = _candidateBarcodes(barcode);

    for (final code in candidates) {
      final result = await _lookupSingleCode(code, originalBarcode: barcode);
      if (result != null) return result;
    }

    return null;
  }

  static List<String> _candidateBarcodes(String code) {
    final list = <String>[code];
    if (code.length == 12 && RegExp(r'^\d{12}$').hasMatch(code)) {
      // 1. Missing 13th check digit calculation (common when scanners or manual entry drop the last checksum)
      int sumOdd = 0;
      int sumEven = 0;
      for (int i = 0; i < 12; i++) {
        final d = int.parse(code[i]);
        if (i % 2 == 0) {
          sumOdd += d;
        } else {
          sumEven += d;
        }
      }
      final total = sumOdd + (sumEven * 3);
      final checkDigit = (10 - (total % 10)) % 10;
      list.add('$code$checkDigit');

      // 2. UPC-A to EAN-13 padding with leading 0
      list.add('0$code');
    }
    return list;
  }

  static Future<OpenFoodFactsProduct?> _lookupSingleCode(String barcode, {required String originalBarcode}) async {
    // 1. Try OpenFoodFacts API v2
    try {
      final offUrl = 'https://world.openfoodfacts.org/api/v2/product/$barcode.json';
      final response = await _dio.get(offUrl);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map && data['status'] == 1 && data['product'] != null) {
          final prod = data['product'] as Map;
          final name = prod['product_name']?.toString().trim() ??
              prod['product_name_en']?.toString().trim();

          if (name != null && name.isNotEmpty) {
            return OpenFoodFactsProduct(
              barcode: originalBarcode,
              name: name,
              brand: prod['brands']?.toString().trim(),
              imageUrl: prod['image_front_url']?.toString() ?? prod['image_url']?.toString(),
              quantity: prod['quantity']?.toString().trim(),
            );
          }
        }
      }
    } catch (_) {}

    // 2. Try Open Products Facts (for non-food household goods)
    try {
      final opfUrl = 'https://world.openproductsfacts.org/api/v0/product/$barcode.json';
      final response = await _dio.get(opfUrl);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map && (data['status'] == 1 || data['status'] == '1') && data['product'] != null) {
          final prod = data['product'] as Map;
          final name = prod['product_name']?.toString().trim() ??
              prod['product_name_en']?.toString().trim();
          if (name != null && name.isNotEmpty) {
            return OpenFoodFactsProduct(
              barcode: originalBarcode,
              name: name,
              brand: prod['brands']?.toString().trim(),
              imageUrl: prod['image_front_url']?.toString() ?? prod['image_url']?.toString(),
              quantity: prod['quantity']?.toString().trim(),
            );
          }
        }
      }
    } catch (_) {}

    // 3. Try Open Beauty Facts (for cosmetics, personal care & hygiene)
    try {
      final obfUrl = 'https://world.openbeautyfacts.org/api/v0/product/$barcode.json';
      final response = await _dio.get(obfUrl);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map && (data['status'] == 1 || data['status'] == '1') && data['product'] != null) {
          final prod = data['product'] as Map;
          final name = prod['product_name']?.toString().trim() ??
              prod['product_name_en']?.toString().trim();
          if (name != null && name.isNotEmpty) {
            return OpenFoodFactsProduct(
              barcode: originalBarcode,
              name: name,
              brand: prod['brands']?.toString().trim(),
              imageUrl: prod['image_front_url']?.toString() ?? prod['image_url']?.toString(),
              quantity: prod['quantity']?.toString().trim(),
            );
          }
        }
      }
    } catch (_) {}

    // 4. Fallback to UPCItemDB Trial API
    try {
      final upcUrl = 'https://api.upcitemdb.com/prod/trial/lookup?upc=$barcode';
      final response = await _dio.get(upcUrl);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map && data['items'] is List && (data['items'] as List).isNotEmpty) {
          final item = (data['items'] as List).first as Map;
          final title = item['title']?.toString().trim();
          if (title != null && title.isNotEmpty) {
            String? img;
            if (item['images'] is List && (item['images'] as List).isNotEmpty) {
              img = (item['images'] as List).first?.toString();
            }
            return OpenFoodFactsProduct(
              barcode: originalBarcode,
              name: title,
              brand: item['brand']?.toString().trim(),
              imageUrl: img,
            );
          }
        }
      }
    } catch (_) {}

    // 5. Fallback to Web Search via DuckDuckGo HTML (handles Indian FMCG & local barcodes)
    try {
      final ddgUrl = 'https://html.duckduckgo.com/html/?q=$barcode';
      final response = await _dio.get(
        ddgUrl,
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          },
        ),
      );
      if (response.statusCode == 200 && response.data != null) {
        final html = response.data.toString();
        final regex = RegExp(
          r'<h2 class="result__title">\s*<a[^>]*class="result__a"[^>]*>(.*?)<\/a>',
          dotAll: true,
        );
        final matches = regex.allMatches(html);
        for (final match in matches.take(4)) {
          final rawTitle = match.group(1);
          if (rawTitle != null && rawTitle.isNotEmpty) {
            final cleanName = _cleanSearchResultTitle(rawTitle, barcode);
            if (cleanName.isNotEmpty) {
              return OpenFoodFactsProduct(
                barcode: originalBarcode,
                name: cleanName,
              );
            }
          }
        }
      }
    } catch (_) {}

    return null;
  }

  static String _cleanSearchResultTitle(String raw, String barcode) {
    var title = raw.replaceAll(RegExp(r'<[^>]*>'), ''); // strip HTML tags
    // Decode common HTML entities
    title = title
        .replaceAll('&amp;', '&')
        .replaceAll('&#39;', "'")
        .replaceAll('&quot;', '"')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ');

    // Strip common site suffixes and prefixes
    title = title.replaceAll(
      RegExp(r'\s*[-|•]\s*(bigbasket|BigBasket|Amazon(\.in)?|Flipkart|JioMart|Blinkit|Zepto|eBay|mrdeal|Solapur|Sarvam Supermarket).*$', caseSensitive: false),
      '',
    );
    title = title.replaceAll(RegExp(r'^\s*Buy\s+', caseSensitive: false), '');
    title = title.replaceAll(RegExp(r'\s*at\s+DuckDuckGo.*$', caseSensitive: false), '');
    title = title.replaceAll(RegExp(r'\s*Online at Best Price.*$', caseSensitive: false), '');
    final clean = title.trim();

    if (clean.toLowerCase() == barcode.toLowerCase() ||
        clean.toLowerCase().contains('duckduckgo') ||
        clean.length < 3) {
      return '';
    }
    return clean;
  }

  /// Downloads, center-crops to 1:1, and caches the product image locally
  static Future<String?> downloadAndCacheImage(String imageUrl, String barcode) async {
    try {
      final savedPath = await ImageHelper.processAndSaveWebImage(imageUrl);
      if (File(savedPath).existsSync()) {
        return savedPath;
      }
    } catch (_) {}
    return null;
  }
}

