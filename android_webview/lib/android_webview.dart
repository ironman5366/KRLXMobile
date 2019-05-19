import 'dart:async';

import 'package:flutter/services.dart';

class AndroidWebview {
  static const MethodChannel _channel =
      const MethodChannel('android_webview');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
