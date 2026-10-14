import Foundation

#if canImport(ActivityKit)
import ActivityKit
#endif

/// MM08 on the lock screen and in the Dynamic Island: a Video kỷ niệm being made. Started by the
/// app on "Tạo video" (ios/Runner/KeepsakeLive.swift), moved on by Functions through FCM
/// (`attachMemoryStoryLive`, `onKeepsakeJobWritten`) and by the app while it is open, drawn by
/// the widget extension. Step and percent only — never a photo, a text or the baby's name (R-116).
struct KeepsakeJobAttributes: Codable, Hashable {
  var jobId: String
  var babyId: String
  /// The app's ARB copy (D-012): "appName", "title", "template", the step and result lines.
  var copy: [String: String]

  /// Matches `KeepsakeLiveState` in packages/contracts (the server's pushes decode into it).
  struct ContentState: Codable, Hashable {
    /// queued · rendering · completed · failed
    var status: String
    /// arrange · compose · export
    var step: String?
    var progress: Int
  }

  func copyText(_ key: String, _ fallback: String) -> String { copy[key] ?? fallback }
}

#if canImport(ActivityKit)
@available(iOS 16.1, *)
extension KeepsakeJobAttributes: ActivityAttributes {}
#endif
