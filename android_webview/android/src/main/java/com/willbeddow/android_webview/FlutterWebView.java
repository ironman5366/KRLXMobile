package com.willbeddow.android_webview;

import android.content.Context;
import android.view.View;
import android.webkit.WebView;
import android.webkit.WebSettings;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

public class FlutterWebView implements PlatformView, MethodChannel.MethodCallHandler {
    private final WebView webView;
    private final MethodChannel methodChannel;

    FlutterWebView(Context context, BinaryMessenger messenger, int id) {
        webView = new WebView(context);
        methodChannel = new MethodChannel(messenger, "com.willbeddow/android_webview_" + id);
        methodChannel.setMethodCallHandler(this);
    }

    @Override
    public View getView() {
        return webView;
    }

    @Override
    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
        switch (methodCall.method) {
            case "setUrl":
                setURL(methodCall, result);
                break;
            default:
                result.notImplemented();
        }

    }

    private void setURL(MethodCall methodCall, MethodChannel.Result result) {
        String text = (String) methodCall.arguments;
        webView.loadUrl(text);
        WebSettings webSettings = webView.getSettings();
        webSettings.setJavaScriptEnabled(true);
        result.success(null);
    }

    @Override
    public void dispose() {}
}