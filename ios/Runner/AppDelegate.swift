import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let appGroupId = "group.com.clib.clib"
  private let sharedKey = "SharedURLs"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.clib.clib/share", binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler { [weak self] (call, result) in
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

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
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
