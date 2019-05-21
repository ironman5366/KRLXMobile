import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let mediaChannel = FlutterMethodChannel(name: "krlx_mobile.willbeddow.com/media",
                                              binaryMessenger: controller)
    mediaChannel.setMethodCallHandler({
        [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
        guard call.method == "play" else {
            result(FlutterMethodNotImplemented)
            return
        }
        self?.playPause(call: call, result: result)
    })
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    private func playPause(call: FlutterMethodCall, result: FlutterResult) {
        
    }
}
