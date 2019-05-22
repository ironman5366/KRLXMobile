import UIKit
import Flutter
import AVKit
import MediaPlayer

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    var currentShowName: String = ""
    var currentHosts: String = ""
    var player: AVPlayer? = nil
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let mediaChannel = FlutterMethodChannel(name: "krlx_mobile.willbeddow.com/media",
                                              binaryMessenger: controller)
    mediaChannel.setMethodCallHandler({
        [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        if (call.method == "play"){
            print("Running AVPlay")
            self!.play(call, result: result)
        }
        else if (call.method == "pause"){
            print("Pausing music")
            self!.player!.pause()
        }
        else{
            result(FlutterMethodNotImplemented)
            return
        }
    })
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
    func setupRemoteTransportControls() {
        // Get the shared MPRemoteCommandCenter
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Add handler for Play Command
        commandCenter.playCommand.addTarget { [unowned self] event in
            if self.player!.rate == 0.0 {
                self.player!.play()
                return .success
            }
            return .commandFailed
        }
        
        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            if self.player!.rate == 1.0 {
                self.player!.pause()
                return .success
            }
            return .commandFailed
        }
    }
    
    func setupNowPlaying(title: String) {
        // Define Now Playing Info
        var nowPlayingInfo = [String : Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        
        /*
        if let image = UIImage(named: "lockscreen") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] =
                MPMediaItemArtwork(boundsSize: image.size) { size in
                    return image
            }
        }
        */
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player?.rate
        
        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    private func play(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    
        // flutter cmds dispatched on iOS device :
        if call.method == "play" {
            guard let args = call.arguments else {
                return
            }
            if let myArgs = args as? [String: Any],
                let streamURL = myArgs["contentUrl"] as? String,
                let hosts = myArgs["hosts"] as? String,
                let showName = myArgs["showName"] as? String {
                    result("Params received on iOS = \(hosts), \(currentShowName)")
                    guard let url = URL.init(string: streamURL)
                        else {
                            print("Couldn't resolve streamURL")
                            print(streamURL)
                            return
                    }
                    let playerItem = AVPlayerItem.init(url: url)
                    player = AVPlayer.init(playerItem: playerItem)
                    player?.play()
                    setupRemoteTransportControls()
                    setupNowPlaying(title: showName)
                
            } else {
                result("iOS could not extract flutter arguments in method: (sendParams)")
            }
        } else if call.method == "getPlatformVersion" {
            result("Running on: iOS " + UIDevice.current.systemVersion)
        } else {
            result("Flutter method not implemented on iOS")
        }
    }
}
