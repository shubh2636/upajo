import 'package:flutter/services.dart';

class ScreenSecurity {
  static const MethodChannel _channel = MethodChannel('com.upajo.app/security');

  /// Prevents screenshots and screen recording on sensitive screens (e.g. KYC, bank/UPI, payments)
  static Future<void> enableSecureScreen() async {
    try {
      await _channel.invokeMethod('enableSecureScreen');
    } catch (_) {
      // Gracefully no-op on platforms without MethodChannel support (e.g. unit tests, web)
    }
  }

  /// Restores normal screen capture permissions when leaving sensitive screen
  static Future<void> disableSecureScreen() async {
    try {
      await _channel.invokeMethod('disableSecureScreen');
    } catch (_) {
      // Gracefully no-op
    }
  }
}

