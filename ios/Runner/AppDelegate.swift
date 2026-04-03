import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let appGroupId = "group.com.clib.clib"
  private let sharedKey = "SharedURLs"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 로컬 알림 delegate 설정
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // MethodChannel 설정
    let messenger = engineBridge.applicationRegistrar.messenger()
    let channel = FlutterMethodChannel(name: "com.clib.clib/share", binaryMessenger: messenger)

    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard let self = self else { return }

      switch call.method {
      case "getSharedURLs":
        let urls = self.getSharedURLs()
        result(urls)
      case "clearSharedURLs":
        self.clearSharedURLs()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func getSharedURLs() -> [String] {
    guard let userDefaults = UserDefaults(suiteName: appGroupId) else { return [] }
    return userDefaults.stringArray(forKey: sharedKey) ?? []
  }

  private func clearSharedURLs() {
    guard let userDefaults = UserDefaults(suiteName: appGroupId) else { return }
    userDefaults.removeObject(forKey: sharedKey)
    userDefaults.synchronize()
  }
}
