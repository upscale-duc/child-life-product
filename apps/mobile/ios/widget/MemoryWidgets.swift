import SwiftUI
import WidgetKit

/// Owner request (2026-10-11): one tap from the Home or Lock Screen to the camera (photo or
/// video) or to the photo library, then the app's own "Soạn & chia sẻ" (10h) for Kỷ niệm. Only
/// Cùng nuôi add memories; anyone else just opens the app.
enum MemoryAdd: String {
  case camera, library

  var symbol: String { self == .camera ? "camera.fill" : "photo.on.rectangle.angled" }

  func link(_ s: GlanceSnapshot?) -> URL {
    guard let s, s.signedIn, s.canAddMemories == true else { return GlanceLink.url(GlanceLink.today) }
    return GlanceLink.url("/memories?add=\(rawValue)")
  }

  var tint: (soft: Color, ink: Color, accent: Color) {
    switch self {
    case .camera:
      return (Color(light: 0xe6f7f5, dark: 0x103a3a), Color.clMintText, Color.clMintDeep)
    case .library:
      return (Color(light: 0xffece6, dark: 0x3a2420), Color(light: 0x9a4a14, dark: 0xf7c0a8),
        Color(light: 0xf08a6c, dark: 0xf08a6c))
    }
  }
}

struct MemoryAddSmallView: View {
  let add: MemoryAdd
  let entry: GlanceEntry

  var body: some View {
    let s = entry.snapshot
    let t = add.tint
    let can = s?.signedIn == true && s?.canAddMemories == true
    VStack(alignment: .leading, spacing: 6) {
      ZStack {
        Circle().fill(t.accent)
        Image(systemName: add.symbol)
          .font(.system(size: 22, weight: .semibold))
          .foregroundStyle(Color.white)
      }
      .frame(width: 48, height: 48)
      Spacer(minLength: 0)
      Text(title(s, can))
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(t.ink)
        .lineLimit(2)
        .minimumScaleFactor(0.8)
      if can, let name = s?.nickname, !name.isEmpty {
        Text(s?.text("memFor", ["name": name]) ?? name)
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(Color.clMuted)
          .lineLimit(1)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .widgetURL(add.link(s))
  }

  private func title(_ s: GlanceSnapshot?, _ can: Bool) -> String {
    guard let s, s.signedIn else { return s?.text("openChildLife", "Mở Child Life") ?? "Mở Child Life" }
    guard can else { return s.text("openChildLife", "Mở Child Life") }
    return add == .camera ? s.text("memCamera", "Chụp ảnh, quay video") : s.text("memLibrary", "Thêm từ Ảnh")
  }
}

struct MemoryAddCircularView: View {
  let add: MemoryAdd
  let entry: GlanceEntry

  var body: some View {
    ZStack {
      AccessoryWidgetBackground()
      Image(systemName: add.symbol)
        .font(.system(size: 22, weight: .semibold))
        .widgetAccentable()
    }
    .widgetURL(add.link(entry.snapshot))
  }
}

struct MemoryAddFamilyView: View {
  @Environment(\.widgetFamily) var family
  let add: MemoryAdd
  let entry: GlanceEntry

  var body: some View {
    switch family {
    case .accessoryCircular:
      MemoryAddCircularView(add: add, entry: entry).containerBackground(.clear, for: .widget)
    default:
      MemoryAddSmallView(add: add, entry: entry).containerBackground(add.tint.soft, for: .widget)
    }
  }
}

struct MemoryCameraWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "app.childlife.memory.camera", provider: GlanceProvider()) { entry in
      MemoryAddFamilyView(add: .camera, entry: entry)
    }
    .configurationDisplayName("glanceGalleryCameraName")
    .description("glanceGalleryCameraBlurb")
    .supportedFamilies([.systemSmall, .accessoryCircular])
  }
}

struct MemoryLibraryWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "app.childlife.memory.library", provider: GlanceProvider()) { entry in
      MemoryAddFamilyView(add: .library, entry: entry)
    }
    .configurationDisplayName("glanceGalleryLibraryName")
    .description("glanceGalleryLibraryBlurb")
    .supportedFamilies([.systemSmall, .accessoryCircular])
  }
}
