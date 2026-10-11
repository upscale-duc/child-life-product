import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Reminders (S7): show local notifications while the app is open, too.
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ShareInbox") {
      ShareInbox.register(with: registrar.messenger())
    }
  }
}

/// 10k hand-off (D-046): the share extension leaves folders in the App Group's `ShareInbox`, each
/// with a `manifest.json` once "Thêm" is tapped; the app reads them, queues the uploads and
/// removes the folder. `share.targets` tells the extension which babies and strings to show.
enum ShareInbox {
  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "childlife/share", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard let group = Bundle.main.object(forInfoDictionaryKey: "CLAppGroup") as? String,
        let root = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)
      else {
        result(call.method == "takeInbox" ? [] : nil)
        return
      }
      let inbox = root.appendingPathComponent("ShareInbox", isDirectory: true)
      switch call.method {
      case "setTargets":
        let json = (call.arguments as? String)?.data(using: .utf8)
        UserDefaults(suiteName: group)?.set(json, forKey: "share.targets")
        result(nil)
      case "takeInbox":
        result(pending(in: inbox))
      case "finish":
        if let id = call.arguments as? String, !id.isEmpty, !id.contains("/"), !id.contains("..") {
          try? FileManager.default.removeItem(at: inbox.appendingPathComponent(id, isDirectory: true))
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Finished shares, oldest first; unfinished folders older than a day are removed.
  static func pending(in inbox: URL) -> [[String: Any]] {
    let fm = FileManager.default
    let dirs = (try? fm.contentsOfDirectory(at: inbox, includingPropertiesForKeys: [.creationDateKey])) ?? []
    var out: [(Date, [String: Any])] = []
    for dir in dirs {
      let created = (try? dir.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date()
      if let data = try? Data(contentsOf: dir.appendingPathComponent("manifest.json")),
        var json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
      {
        json["id"] = dir.lastPathComponent
        json["dir"] = dir.path
        out.append((created, json))
      } else if created < Date().addingTimeInterval(-86_400) {
        try? fm.removeItem(at: dir)
      }
    }
    return out.sorted { $0.0 < $1.0 }.map { $0.1 }
  }
}
