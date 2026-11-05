import 'package:flutter/services.dart';

class LauncherIconPreset {
  final int id;
  final String title;
  final String description;
  final String assetPath;

  const LauncherIconPreset({
    required this.id,
    required this.title,
    required this.description,
    required this.assetPath,
  });
}

class LauncherIconService {
  LauncherIconService._();

  static const MethodChannel _channel = MethodChannel('com.shopmate.pos/launcher_icon');

  static const List<LauncherIconPreset> presets = [
    LauncherIconPreset(
      id: 1,
      title: 'Classic Blue',
      description: 'Store Awning & POS Terminal',
      assetPath: 'assets/launcher_icons/launcher_1.png',
    ),
    LauncherIconPreset(
      id: 2,
      title: 'Neon Green',
      description: 'Cyber Scanner & Barcode Stripe',
      assetPath: 'assets/launcher_icons/launcher_2.png',
    ),
    LauncherIconPreset(
      id: 3,
      title: 'Warm Amber',
      description: 'Shopping Tag & POS Terminal',
      assetPath: 'assets/launcher_icons/launcher_3.png',
    ),
    LauncherIconPreset(
      id: 4,
      title: 'Neon Purple',
      description: 'Premium Store Bag & POS Terminal',
      assetPath: 'assets/launcher_icons/launcher_4.png',
    ),
  ];

  static Future<bool> setLauncherIcon(int preset) async {
    try {
      final bool? success = await _channel.invokeMethod<bool>('setLauncherIcon', {'preset': preset});
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<int> getCurrentLauncherIcon() async {
    try {
      final int? active = await _channel.invokeMethod<int>('getCurrentLauncherIcon');
      return active ?? 1;
    } catch (_) {
      return 1;
    }
  }
}

