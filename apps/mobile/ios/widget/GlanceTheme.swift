import SwiftUI
import WidgetKit

/// Design tokens (packages/design-tokens): Light and Night care values, following the system
/// appearance on the Home and Lock screen.
extension Color {
  init(light: UInt32, dark: UInt32) {
    self.init(
      UIColor { trait in
        let v = trait.userInterfaceStyle == .dark ? dark : light
        return UIColor(
          red: CGFloat((v >> 16) & 0xff) / 255, green: CGFloat((v >> 8) & 0xff) / 255,
          blue: CGFloat(v & 0xff) / 255, alpha: 1)
      })
  }

  static let clInk = Color(light: 0x173d44, dark: 0xe6f2f1)
  static let clMuted = Color(light: 0x55707a, dark: 0x9db3b4)
  static let clSurface = Color(light: 0xffffff, dark: 0x15242a)
  static let clCloud = Color(light: 0xf6fcfb, dark: 0x0c1719)
  static let clSurface2 = Color(light: 0xeef6f5, dark: 0x1c2e33)
  static let clMintDeep = Color(light: 0x087f7b, dark: 0x3fd0c3)
  static let clOnMint = Color(light: 0xffffff, dark: 0x062a2c)
  static let clMint = Color(light: 0x2cbfb3, dark: 0x2cbfb3)
  static let clMintText = Color(light: 0x06716d, dark: 0x3fd0c3)
  static let clPending = Color(light: 0x7a5600, dark: 0xffd166)
}

/// One care type's tile colours (care/<type>/soft · ink · accent).
struct CarePalette {
  let soft: Color
  let ink: Color
  let accent: Color
  let art: String

  static func of(_ type: String) -> CarePalette {
    switch type {
    case "bottle":
      return .init(soft: Color(light: 0xe5f1fb, dark: 0x16314a), ink: Color(light: 0x1d5f99, dark: 0x9ccbf5),
        accent: Color(light: 0x3b8fd9, dark: 0x5aa6e8), art: "MiniBottle")
    case "breast":
      return .init(soft: Color(light: 0xfceaf0, dark: 0x3a1f2a), ink: Color(light: 0xa33a5e, dark: 0xf5b3c8),
        accent: Color(light: 0xe07a9a, dark: 0xe88aa8), art: "MiniDrop")
    case "sleep":
      return .init(soft: Color(light: 0xedeefc, dark: 0x23244a), ink: Color(light: 0x4447a8, dark: 0xbdbff7),
        accent: Color(light: 0x6c6fd8, dark: 0x8a8deb), art: "MiniMoon")
    default:
      return .init(soft: Color(light: 0xe7f4e3, dark: 0x1e3320), ink: Color(light: 0x2f6b24, dark: 0xa8da9c),
        accent: Color(light: 0x5daa4e, dark: 0x74bf63), art: "MiniDiaper")
    }
  }
}

/// Strings come from the app's ARB catalogs through the snapshot (D-012); durations and times
/// are formatted here so each timeline entry reads correctly at its own moment.
struct GlanceFormat {
  let s: GlanceSnapshot

  var locale: Locale { Locale(identifier: s.locale == "en" ? "en_GB" : "vi_VN") }

  func time(_ d: Date) -> String {
    let f = DateFormatter()
    f.locale = locale
    f.dateFormat = "HH:mm"
    return f.string(from: d)
  }

  func day(_ d: Date) -> String {
    let f = DateFormatter()
    f.locale = locale
    f.setLocalizedDateFormatFromTemplate(s.locale == "en" ? "EEEE d MMMM" : "EEEE, d MMMM")
    let out = f.string(from: d)
    return out.prefix(1).uppercased() + out.dropFirst()
  }

  /// "1 giờ 25 phút" / "45 phút" (long) or "1g 25p" / "45p" (short).
  func duration(_ seconds: TimeInterval, short: Bool = false) -> String {
    let total = max(0, Int(seconds / 60))
    let h = total / 60
    let m = total % 60
    let p = short ? "durS" : "dur"
    if h == 0 { return s.text("\(p).m", ["m": "\(max(m, 1))"]) }
    if m == 0 { return s.text("\(p).h", ["h": "\(h)"]) }
    return s.text("\(p).hm", ["h": "\(h)", "m": "\(m)"])
  }

  /// "45 phút trước" / "Vừa xong".
  func ago(_ d: Date, now: Date) -> String {
    now.timeIntervalSince(d) < 60 ? s.text("justNow", "Vừa xong") : s.text("ago", ["t": duration(now.timeIntervalSince(d))])
  }

  func by(_ name: String) -> String { s.text("loggedBy", ["name": name]) }

  func diaper(_ kind: String?) -> String { s.text("diaper.\(kind ?? "wet")", kind ?? "") }
}

/// Deep links into the app (W5 "Những chỗ sẽ mở app"): the app's own URL scheme + a route.
enum GlanceLink {
  static var scheme: String { (Bundle.main.object(forInfoDictionaryKey: "CLURLScheme") as? String) ?? "childlife" }
  static func url(_ path: String) -> URL { URL(string: "\(scheme)://app\(path)")! }
  static let today = "/today"
  static func timer(_ type: String) -> String { "/care/timer/\(type)" }
  static func record(_ id: String) -> String { "/care/record/\(id)" }

  /// The app's own log for [type] (amount, kind, side, time — as from the Hôm nay tile), opened
  /// over Hôm nay; read-only members just get Hôm nay (owner request 2026-10-11).
  static func log(_ type: String, _ s: GlanceSnapshot) -> String { s.canLog ? "/today?log=\(type)" : today }
}
