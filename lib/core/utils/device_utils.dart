import 'package:flutter/services.dart';

class DeviceUtils {
  DeviceUtils._();

  static const MethodChannel _channel = MethodChannel('com.shopmate.pos/device_info');

  /// Detects whether the host device is a low-RAM device (e.g. Android Go, <= 2GB RAM)
  static Future<bool> isLowRamDevice() async {
    try {
      final bool? isLow = await _channel.invokeMethod<bool>('isLowRamDevice');
      return isLow ?? false;
    } catch (_) {
      return false;
    }
  }
}

