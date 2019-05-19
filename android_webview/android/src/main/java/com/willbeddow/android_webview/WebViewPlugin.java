package com.willbeddow.android_webview;

import io.flutter.plugin.common.PluginRegistry;

public class WebViewPlugin {
    public static void registerWith(PluginRegistry.Registrar registrar) {
        registrar
                .platformViewRegistry()
                .registerViewFactory(
                        "com.willbeddow/android_webview", new WebViewFactory(registrar.messenger()));
    }

}