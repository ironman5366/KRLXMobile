#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
#import "mediaHandler-Swift.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  FlutterMethodChannel* mediaChannel = [FlutterMethodChannel
                                            methodChannelWithName:@"com.willbeddow/media"
                                            binaryMessenger:controller];

    [mediaChannel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
      // TODO
    }];
  // Override point for customization after application launch.
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
