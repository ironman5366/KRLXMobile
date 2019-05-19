import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:android_webview/android_webview.dart';

void main() {
  const MethodChannel channel = MethodChannel('android_webview');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await AndroidWebview.platformVersion, '42');
  });
}
