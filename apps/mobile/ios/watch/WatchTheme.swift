import SwiftUI

/// Watch colours: the Night care values of the care tokens (the widgets' CarePalette), since a
/// watch app is always dark; the night red of W11 is engineering-supplied until it is a token
/// (G-100).
extension Color {
  init(hex: UInt32) {
    self.init(
      red: Double((hex >> 16) & 0xff) / 255, green: Double((hex >> 8) & 0xff) / 255,
      blue: Double(hex & 0xff) / 255)
  }
}

enum CareKind: String, CaseIterable, Identifiable {
  case bottle, breast, sleep, diaper, pump, reminder
  var id: String { rawValue }

  var accent: Color {
    switch self {
    case .bottle: return Color(hex: 0x5aa6e8)
    case .breast: return Color(hex: 0xe88aa8)
    case .sleep: return Color(hex: 0x8a8deb)
    case .diaper: return Color(hex: 0x74bf63)
    case .pump: return Color(hex: 0xb98ad6)
    case .reminder: return Color(hex: 0xe8894a)
    }
  }

  /// Night care "soft" fill behind a running state (W04's whole screen).
  var deep: Color {
    switch self {
    case .sleep: return Color(hex: 0x23244a)
    case .breast: return Color(hex: 0x3a1f2a)
    case .bottle: return Color(hex: 0x16314a)
    case .diaper: return Color(hex: 0x1e3320)
    case .pump: return Color(hex: 0x2e2140)
    case .reminder: return Color(hex: 0x3a2414)
    }
  }

  /// The app's Icon/* glyph (tool/watch_assets.py).
  var icon: String {
    switch self {
    case .bottle: return "Icon-feed"
    case .breast, .pump: return "Icon-drop"
    case .sleep: return "Icon-sleep"
    case .diaper: return "Icon-diaper"
    case .reminder: return "Icon-bell"
    }
  }

  var title: String {
    switch self {
    case .bottle: return WatchText.t("watchTileBottle")
    case .breast: return WatchText.t("watchTileBreast")
    case .sleep: return WatchText.t("watchTileSleep")
    case .diaper: return WatchText.t("watchTileDiaper")
    case .pump: return WatchText.t("watchTilePump")
    case .reminder: return WatchText.t("watchTileReminder")
    }
  }
}

enum WatchColor {
  static let tile = Color(white: 0.14)
  static let button = Color(white: 0.2)
  static let saved = Color(hex: 0x34c759)
  static let pending = Color(hex: 0xffd166)
  static let pendingSoft = Color(hex: 0x3a3214)
  static let danger = Color(hex: 0xdb4a45)
  /// W11 "Màu đỏ dịu, không làm chói mắt".
  static let nightInk = Color(hex: 0xe5533d)
  static let nightRow = Color(hex: 0x2a0d0b)
}

/// The app's Icon/* drawn as a template, tinted by the caller.
struct CareIcon: View {
  let name: String
  var size: CGFloat = 13

  var body: some View {
    Image(name).renderingMode(.template).resizable().scaledToFit().frame(width: size, height: size)
  }
}

/// Full-width pill button in a care colour (Lưu, Bé đã dậy, Dừng · nhập ml …).
struct PillButtonStyle: ButtonStyle {
  var fill: Color
  var ink: Color = .white

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 15, weight: .semibold))
      .foregroundStyle(ink)
      .frame(maxWidth: .infinity, minHeight: 39)
      .background(Capsule().fill(fill))
      .opacity(configuration.isPressed ? 0.7 : 1)
      .scaleEffect(configuration.isPressed ? 0.97 : 1)
  }
}

extension View {
  /// The Figma top row: a small title beside the clock, tinted in the care colour.
  func screenTitle(_ title: String, color: Color) -> some View {
    self
      .navigationTitle { Text(title).foregroundStyle(color) }
      .navigationBarTitleDisplayMode(.inline)
      .tint(color)
  }
}
