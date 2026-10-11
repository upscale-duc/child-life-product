import Foundation

#if canImport(ActivityKit)
import ActivityKit
#endif

/// The upload Live Activity (10j "LiveActivity/Upload"): "Kỷ niệm của Teddy · Đang tải 4/7 mục ·
/// Xong sẽ báo bạn · 57%". Started and updated by the app (ios/Runner/BackgroundUploads.swift),
/// drawn by the widget extension. Strings come from the app's ARB copy (D-012); counts only —
/// never a photo on the lock screen.
struct UploadAttributes: Codable, Hashable {
  /// "title" (already filled in) and the copy keys the views read.
  var copy: [String: String]

  struct ContentState: Codable, Hashable {
    var done: Int
    var total: Int
    var fraction: Double
    var waitingWifi: Int
  }

  func text(_ key: String, _ fallback: String, _ values: [String: String] = [:]) -> String {
    var s = copy[key] ?? fallback
    for (k, v) in values { s = s.replacingOccurrences(of: "{\(k)}", with: v) }
    return s
  }
}

#if canImport(ActivityKit)
@available(iOS 16.1, *)
extension UploadAttributes: ActivityAttributes {}
#endif
