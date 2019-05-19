import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
typedef void WebViewCreatedCallback(WebViewController controller);

class NativeWebView extends StatefulWidget {
  const NativeWebView({
    Key key,
    this.onWebViewCreated,
  }) : super(key: key);

  final WebViewCreatedCallback onWebViewCreated;

  @override
  State<StatefulWidget> createState() => _NativeWebViewState();
}

class _NativeWebViewState extends State<NativeWebView> {
  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      print("Creating webView");
      return AndroidView(
        viewType: 'com.willbeddow/android_webview',
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    }
    return Text(
        'This plugin serves only to run native Android code,'
            ' $defaultTargetPlatform is not supported');
  }

  void _onPlatformViewCreated(int id) {
    print("Finished creating");
    if (widget.onWebViewCreated == null) {
      return;
    }
    widget.onWebViewCreated(new WebViewController._(id));
  }
  static const MethodChannel _channel =
  const MethodChannel('android_webview');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}

class WebViewController {
  WebViewController._(int id)
      : _channel = new MethodChannel('com.willbeddow/android_webview_$id');

  final MethodChannel _channel;

  Future<void> setUrl(String text) async {
    assert(text != null);
    return _channel.invokeMethod('setUrl', text);
  }
}