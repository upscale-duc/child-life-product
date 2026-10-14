import Foundation

/// Watch copy from Localizable.xcstrings, generated from the ARB catalogs by
/// tool/watch_strings.py (D-012). The language follows the phone app's choice (snapshot locale,
/// G-081), not the watch's.
enum WatchText {
  static var locale = "vi"

  private static var bundle: Bundle {
    let code = locale.hasPrefix("en") ? "en" : "vi"
    guard let path = Bundle.main.path(forResource: code, ofType: "lproj"), let b = Bundle(path: path)
    else { return .main }
    return b
  }

  /// `{x}` placeholders filled from [values].
  static func t(_ key: String, _ values: [String: String] = [:]) -> String {
    var s = bundle.localizedString(forKey: key, value: key, table: nil)
    for (k, v) in values { s = s.replacingOccurrences(of: "{\(k)}", with: v) }
    return s
  }

  /// "2:15" — hours and minutes since (W01 tiles, W04 sleep, complications).
  static func hm(_ interval: TimeInterval) -> String {
    let minutes = max(0, Int(interval / 60))
    return "\(minutes / 60):" + String(format: "%02d", minutes % 60)
  }

  /// "0:09:23" — a running timer, always with the hour so it never reads like the "2:15" (h:mm)
  /// of the other tiles.
  static func hms(_ interval: TimeInterval) -> String {
    let seconds = max(0, Int(interval))
    return "\(seconds / 3600):" + String(format: "%02d:%02d", (seconds % 3600) / 60, seconds % 60)
  }

  /// "8:12" / "1:02:03" — a running feed or pump (tabular figures in the views).
  static func ms(_ interval: TimeInterval) -> String {
    let seconds = max(0, Int(interval))
    let h = seconds / 3600, m = (seconds % 3600) / 60, s = seconds % 60
    return h > 0 ? "\(h):" + String(format: "%02d:%02d", m, s) : "\(m):" + String(format: "%02d", s)
  }

  /// "13:05" in the 24-hour clock both languages use (en_GB, vi_VN).
  static func clock(_ date: Date) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: locale.hasPrefix("en") ? "en_GB" : "vi_VN")
    f.dateFormat = "HH:mm"
    return f.string(from: date)
  }
}
