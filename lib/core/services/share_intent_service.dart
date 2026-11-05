import 'dart:async';
import 'dart:developer' as dev;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../utils/image_helper.dart';

class ShareIntentService {
  ShareIntentService._();

  static StreamSubscription? _intentSub;

  static Future<String?> _processSharedPath(String rawPath) async {
    final clean = rawPath.trim();
    if (clean.isEmpty) return null;
    try {
      if (clean.startsWith('http://') ||
          clean.startsWith('https://') ||
          clean.startsWith('data:image')) {
        return await ImageHelper.processAndSaveWebImage(clean);
      } else {
        return await ImageHelper.compressAndSaveLocalImage(clean);
      }
    } catch (e, st) {
      dev.log(
        '[ShareIntentService] Failed to process shared media: $e',
        error: e,
        stackTrace: st,
        name: 'ShareIntentService',
      );
      return null;
    }
  }

  static void initialize({required Function(String imagePath) onImageReceived}) {
    // Listen to incoming shared media while app is in memory
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> files) async {
      if (files.isNotEmpty) {
        final processedPath = await _processSharedPath(files.first.path);
        if (processedPath != null) {
          onImageReceived(processedPath);
        }
      }
    });

    // Check shared media when app is opened via intent
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> files) async {
      if (files.isNotEmpty) {
        final processedPath = await _processSharedPath(files.first.path);
        if (processedPath != null) {
          onImageReceived(processedPath);
        }
        ReceiveSharingIntent.instance.reset();
      }
    });
  }

  static void dispose() {
    _intentSub?.cancel();
  }
}
