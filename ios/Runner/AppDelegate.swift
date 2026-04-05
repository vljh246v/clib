import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let appGroupId = "group.com.jaehyun.clib.share"
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
    let channel = FlutterMethodChannel(name: "com.jaehyun.clibapp/share", binaryMessenger: messenger)

    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard let self = self else { return }

      switch call.method {
      case "getSharedURLs":
        let items = self.getSharedItems()
        result(items)
      case "clearSharedURLs":
        self.clearSharedURLs()
        result(nil)
      case "syncLabels":
        if let labels = call.arguments as? [[String: Any]] {
          self.syncLabels(labels)
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func getSharedItems() -> [String] {
    guard let userDefaults = UserDefaults(suiteName: appGroupId) else { return [] }
    return userDefaults.stringArray(forKey: sharedKey) ?? []
  }

  private func clearSharedURLs() {
    guard let userDefaults = UserDefaults(suiteName: appGroupId) else { return }
    userDefaults.removeObject(forKey: sharedKey)
    userDefaults.synchronize()
  }

  private func syncLabels(_ labels: [[String: Any]]) {
    guard let userDefaults = UserDefaults(suiteName: appGroupId) else { return }
    if let data = try? JSONSerialization.data(withJSONObject: labels),
       let jsonString = String(data: data, encoding: .utf8) {
      userDefaults.set(jsonString, forKey: "SharedLabels")
      userDefaults.synchronize()
    }
  }
}
