import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var controller : FlutterViewController?
    private var pushChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
        controller = window?.rootViewController as? FlutterViewController
        pushChannel = FlutterMethodChannel(
          name: "backendless/push_notifications",
          binaryMessenger: controller!.binaryMessenger)

        //uncomment to customize on tap push action
//      if let notificationData = launchOptions?[UIApplication.LaunchOptionsKey(rawValue: "UIApplicationLaunchOptionsRemoteNotificationKey")] {
//          DispatchQueue.main.async {
//              self.pushChannel?.invokeMethod("TAP_PUSH_ACTION", arguments: notificationData as! Dictionary<String, Any>);
//          }
//      }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
      print("Received push notification:")
      for (key, value) in userInfo {
          print("* \(key): \(value)")
      }

      let state = UIApplication.shared.applicationState

      if state == .active
      {
        print("___ACTIVE")
        super.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler);
      }
      else if state == .inactive {
        print("INACTIVE")
        pushChannel?.invokeMethod("TAP_PUSH_ACTION", arguments: userInfo)
      }

      completionHandler(.newData)
  }
}
