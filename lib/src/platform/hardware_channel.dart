import 'dart:io';
import 'package:flutter/services.dart';

/// Platform channel for hardware telemetry not available via pure Dart.
class HardwareChannel {
  static const MethodChannel _channel = MethodChannel('dev_guard/hardware');

  static Future<String?> getIosStorageTotal() async {
    if (!Platform.isIOS) return null;
    try {
      final result = await _channel.invokeMethod<String>('getStorageTotal');
      return result;
    } catch (_) {
      return null;
    }
  }
}
