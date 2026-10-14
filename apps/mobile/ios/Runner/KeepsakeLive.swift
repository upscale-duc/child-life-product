import Flutter
import Foundation
import UIKit

#if canImport(ActivityKit)
import ActivityKit
#endif

/// MM08 Live Activity, app side (channel "childlife/keepsakeLive"): "start" on "Tạo video" with
/// push updates on, each push token handed to Flutter ("token") so Functions can move it on;
/// "update" from the job while the app is open, ending it when the job finishes.
enum KeepsakeLive {
  private static var channel: FlutterMethodChannel?
  private static var watched = Set<String>()

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "childlife/keepsakeLive", binaryMessenger: messenger)
    self.channel = channel
    channel.setMethodCallHandler { call, result in
      let a = call.arguments as? [String: Any] ?? [:]
      #if canImport(ActivityKit)
      if #available(iOS 16.2, *) {
        switch call.method {
        case "start":
          Task { result(await start(a)) }
        case "update":
          Task {
            await update(a)
            result(nil)
          }
        case "resume":
          // After a relaunch: hand Flutter the tokens of activities still running.
          for activity in Activity<KeepsakeJobAttributes>.activities { watch(activity) }
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
        return
      }
      #endif
      result(call.method == "start" ? false : nil)
    }
  }

  #if canImport(ActivityKit)
  @available(iOS 16.2, *)
  private static func state(_ a: [String: Any]) -> KeepsakeJobAttributes.ContentState {
    KeepsakeJobAttributes.ContentState(
      status: a["status"] as? String ?? "queued",
      step: a["step"] as? String,
      progress: a["progress"] as? Int ?? 0
    )
  }

  @available(iOS 16.2, *)
  private static func start(_ a: [String: Any]) async -> Bool {
    guard let jobId = a["jobId"] as? String, let babyId = a["babyId"] as? String else { return false }
    if let existing = Activity<KeepsakeJobAttributes>.activities.first(where: { $0.attributes.jobId == jobId }) {
      watch(existing)
      return true
    }
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return false }
    let attributes = KeepsakeJobAttributes(
      jobId: jobId, babyId: babyId, copy: a["copy"] as? [String: String] ?? [:])
    let content = ActivityContent(state: state(a), staleDate: nil)
    do {
      let activity = try Activity.request(attributes: attributes, content: content, pushType: .token)
      watch(activity)
      return true
    } catch {
      return false
    }
  }

  /// Sends each push token of [activity] to Flutter (they can change while it runs).
  @available(iOS 16.2, *)
  private static func watch(_ activity: Activity<KeepsakeJobAttributes>) {
    guard !watched.contains(activity.id) else { return }
    watched.insert(activity.id)
    let jobId = activity.attributes.jobId
    let babyId = activity.attributes.babyId
    Task {
      for await data in activity.pushTokenUpdates {
        let token = data.map { String(format: "%02x", $0) }.joined()
        await MainActor.run {
          channel?.invokeMethod("token", arguments: ["jobId": jobId, "babyId": babyId, "token": token])
        }
      }
    }
  }

  @available(iOS 16.2, *)
  private static func update(_ a: [String: Any]) async {
    guard let jobId = a["jobId"] as? String else { return }
    let st = state(a)
    for activity in Activity<KeepsakeJobAttributes>.activities where activity.attributes.jobId == jobId {
      let content = ActivityContent(state: st, staleDate: nil)
      if st.status == "completed" || st.status == "failed" {
        await activity.end(content, dismissalPolicy: .after(Date().addingTimeInterval(30 * 60)))
      } else if activity.content.state != st {
        await activity.update(content)
      }
    }
  }
  #endif
}
