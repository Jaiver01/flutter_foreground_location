import UIKit
import Flutter
import flutter_background_service_ios // flutter_background_service

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // flutter_foreground_task
    // SwiftFlutterForegroundTaskPlugin.setPluginRegistrantCallback(registerPlugins)
    // if #available(iOS 10.0, *) {
    //   UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    // }
    // flutter_foreground_task

    // flutter_background_service
    SwiftFlutterBackgroundServicePlugin.taskIdentifier = "your.custom.task.identifier"

    GeneratedPluginRegistrant.register(with: self) // *
    // flutter_background_service

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

// func registerPlugins(registry: FlutterPluginRegistry) {
//   GeneratedPluginRegistrant.register(with: registry)
// }
