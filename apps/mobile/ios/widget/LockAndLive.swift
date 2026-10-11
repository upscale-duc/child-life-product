import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

// W2 Lock screen accessories (75:524 circular Sleep/Feed, 75:525 rectangular, 75:532 inline) and
// W2/W3 Live Activity + Dynamic Island (75:576, 75:606). No photos on the lock screen.

struct LockSleepView: View {
  let entry: GlanceEntry
  var body: some View {
    if let s = entry.snapshot, s.signedIn {
      let f = GlanceFormat(s: s)
      ZStack {
        AccessoryWidgetBackground()
        VStack(spacing: 0) {
          Image(systemName: "moon.fill").font(.system(size: 12))
          if let t = s.sleep {
            Text(timerInterval: t.startedAt...Date.distantFuture, countsDown: false, showsHours: true)
              .font(.system(size: 13, weight: .semibold).monospacedDigit()).multilineTextAlignment(.center)
          } else if let woke = s.lastWokeAt {
            Text(f.duration(entry.date.timeIntervalSince(woke), short: true)).font(.system(size: 13, weight: .semibold))
          }
        }
      }
      .widgetURL(GlanceLink.url(s.sleep != nil ? GlanceLink.timer("sleep") : GlanceLink.today))
    } else {
      ZStack { AccessoryWidgetBackground(); Image(systemName: "moon") }
    }
  }
}

struct LockFeedView: View {
  let entry: GlanceEntry
  var body: some View {
    if let s = entry.snapshot, s.signedIn {
      let f = GlanceFormat(s: s)
      let last = [s.lastBottle?.at, s.lastBreast?.at].compactMap { $0 }.max()
      // Ring: time since the last feed against a 3-hour rhythm.
      let progress = last.map { min(1, entry.date.timeIntervalSince($0) / (3 * 3600)) } ?? 0
      Gauge(value: progress) {
        Image(systemName: "drop.fill")
      } currentValueLabel: {
        Text(last.map { f.duration(entry.date.timeIntervalSince($0), short: true) } ?? "—")
      }
      .gaugeStyle(.accessoryCircularCapacity)
      .widgetURL(GlanceLink.url(GlanceLink.today))
    } else {
      ZStack { AccessoryWidgetBackground(); Image(systemName: "drop") }
    }
  }
}

struct LockRectView: View {
  let entry: GlanceEntry
  var body: some View {
    if let s = entry.snapshot, s.signedIn {
      let f = GlanceFormat(s: s)
      let feed = [s.lastBottle?.at, s.lastBreast?.at].compactMap { $0 }.max()
      VStack(alignment: .leading, spacing: 1) {
        HStack(spacing: 4) {
          Image(systemName: "drop.fill").font(.system(size: 11))
          Text(s.nickname ?? "").font(.system(size: 14, weight: .semibold))
        }
        Text(s.text("lockFeeds", [
          "feed": feed.map { f.duration(entry.date.timeIntervalSince($0), short: true) } ?? "—",
          "diaper": s.lastDiaper.map { f.duration(entry.date.timeIntervalSince($0.at), short: true) } ?? "—",
        ])).font(.system(size: 12)).lineLimit(1)
        if let t = s.sleep {
          HStack(spacing: 3) {
            Text(s.text("sleeping", "Đang ngủ"))
            Text(timerInterval: t.startedAt...Date.distantFuture, countsDown: false).monospacedDigit()
          }.font(.system(size: 12)).lineLimit(1)
        } else {
          Text(s.text("lockSleep", [
            "awake": s.lastWokeAt.map { f.duration(entry.date.timeIntervalSince($0), short: true) } ?? "—",
            "slept": f.duration(Double(s.sleptTodayMin) * 60, short: true),
          ])).font(.system(size: 12)).lineLimit(1)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .widgetURL(GlanceLink.url(GlanceLink.today))
    } else {
      Text(entry.snapshot?.text("signedOutTitle", "Đăng nhập để dùng widget") ?? "Child Life").font(.system(size: 12))
    }
  }
}

struct LockInlineView: View {
  let entry: GlanceEntry
  var body: some View {
    if let s = entry.snapshot, s.signedIn {
      let f = GlanceFormat(s: s)
      if let t = s.sleep {
        Label {
          Text("\(s.nickname ?? "") · ") + Text(timerInterval: t.startedAt...Date.distantFuture, countsDown: false)
        } icon: { Image(systemName: "moon.fill") }
      } else if let feed = [s.lastBottle?.at, s.lastBreast?.at].compactMap({ $0 }).max() {
        Label(s.text("inlineFed", ["name": s.nickname ?? "", "t": f.duration(entry.date.timeIntervalSince(feed))]),
          systemImage: "drop.fill")
      } else {
        Text(s.nickname ?? "Child Life")
      }
    } else {
      Text("Child Life")
    }
  }
}

struct LockWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "app.childlife.lock", provider: GlanceProvider()) { entry in
      LockFamilyView(entry: entry).containerBackground(.clear, for: .widget)
    }
    .configurationDisplayName("Child Life")
    .description("Lần bú, tã và giấc ngủ trên màn hình khoá.")
    .supportedFamilies([.accessoryRectangular, .accessoryInline])
  }
}

struct LockFamilyView: View {
  @Environment(\.widgetFamily) var family
  let entry: GlanceEntry
  var body: some View {
    switch family {
    case .accessoryInline: LockInlineView(entry: entry)
    default: LockRectView(entry: entry)
    }
  }
}

struct LockSleepWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "app.childlife.lock.sleep", provider: GlanceProvider()) { entry in
      LockSleepView(entry: entry).containerBackground(.clear, for: .widget)
    }
    .configurationDisplayName("Giấc ngủ")
    .description("Đang ngủ bao lâu, hoặc đã thức bao lâu.")
    .supportedFamilies([.accessoryCircular])
  }
}

struct LockFeedWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "app.childlife.lock.feed", provider: GlanceProvider()) { entry in
      LockFeedView(entry: entry).containerBackground(.clear, for: .widget)
    }
    .configurationDisplayName("Lần bú")
    .description("Bao lâu từ lần bú gần nhất.")
    .supportedFamilies([.accessoryCircular])
  }
}

// MARK: - Live Activity + Dynamic Island

struct CareLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: CareTimerAttributes.self) { context in
      LiveLockView(context: context)
        .activityBackgroundTint(CarePalette.of(context.attributes.type).soft)
        .activitySystemActionForegroundColor(Color.clInk)
        .widgetURL(GlanceLink.url(GlanceLink.timer(context.attributes.type)))
    } dynamicIsland: { context in
      let a = context.attributes
      let st = context.state
      let p = CarePalette.of(a.type)
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Image(a.type == "sleep" ? "MiniMoon" : "MiniDrop").resizable().scaledToFit().frame(width: 40, height: 40)
        }
        DynamicIslandExpandedRegion(.trailing) {
          LiveTimerText(state: st).font(.system(size: 24, weight: .semibold).monospacedDigit())
            .foregroundStyle(p.accent)
        }
        DynamicIslandExpandedRegion(.center) {
          VStack(alignment: .leading, spacing: 2) {
            Text(LiveText.title(a, st)).font(.system(size: 15, weight: .semibold)).lineLimit(1)
            Text(LiveText.since(a, st)).font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(1)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        DynamicIslandExpandedRegion(.bottom) { LiveButtons(attributes: a, state: st, compact: true) }
      } compactLeading: {
        Image(systemName: a.type == "sleep" ? "moon.fill" : "drop.fill").foregroundStyle(p.accent)
      } compactTrailing: {
        LiveTimerText(state: st).monospacedDigit().foregroundStyle(p.accent).frame(maxWidth: 56)
      } minimal: {
        Image(systemName: a.type == "sleep" ? "moon.fill" : "drop.fill").foregroundStyle(p.accent)
      }
      .widgetURL(GlanceLink.url(GlanceLink.timer(a.type)))
      .keylineTint(p.accent)
    }
  }
}

enum LiveText {
  static func t(_ a: CareTimerAttributes, _ key: String, _ fallback: String) -> String { a.copy[key] ?? fallback }

  static func title(_ a: CareTimerAttributes, _ st: CareTimerAttributes.ContentState) -> String {
    if a.type == "sleep" {
      return t(a, "sleepingTitle", "{name} đang ngủ").replacingOccurrences(of: "{name}", with: a.nickname)
    }
    let side = t(a, "breastSide.\(st.side ?? "left")", "")
    return t(a, "breastTitle", "Bú mẹ · {side}").replacingOccurrences(of: "{side}", with: side.lowercased())
  }

  static func since(_ a: CareTimerAttributes, _ st: CareTimerAttributes.ContentState) -> String {
    let f = DateFormatter()
    f.dateFormat = "HH:mm"
    return t(a, "since", "Từ {time} · {name}")
      .replacingOccurrences(of: "{time}", with: f.string(from: st.startedAt))
      .replacingOccurrences(of: "{name}", with: st.byName)
  }
}

struct LiveTimerText: View {
  let state: CareTimerAttributes.ContentState
  var body: some View {
    if state.paused {
      Image(systemName: "pause.fill")
    } else {
      Text(timerInterval: state.countFrom...Date.distantFuture, countsDown: false)
    }
  }
}

struct LiveButtons: View {
  let attributes: CareTimerAttributes
  let state: CareTimerAttributes.ContentState
  var compact = false
  var body: some View {
    let p = CarePalette.of(attributes.type)
    HStack(spacing: 8) {
      if attributes.type == "sleep" {
        Button(intent: EndTimerIntent(type: "sleep")) {
          Text(LiveText.t(attributes, "wake", "Thức dậy")).frame(maxWidth: .infinity)
        }
        .tint(p.accent)
        Link(destination: GlanceLink.url(GlanceLink.timer("sleep"))) {
          Text(LiveText.t(attributes, compact ? "editTimeShort" : "editTime", "Sửa giờ bắt đầu"))
            .frame(maxWidth: .infinity, minHeight: 34)
            .background(Color.clSurface.opacity(0.9), in: Capsule())
            .foregroundStyle(Color.clInk)
        }
      } else {
        Button(intent: SwitchSideIntent()) {
          Text(LiveText.t(attributes, "switchSide", "Đổi bên")).frame(maxWidth: .infinity)
        }
        .tint(Color.clSurface)
        .foregroundStyle(p.ink)
        Button(intent: EndTimerIntent(type: "breast")) {
          Text(LiveText.t(attributes, "endFeed", "Kết thúc")).frame(maxWidth: .infinity)
        }
        .tint(p.accent)
      }
    }
    .buttonStyle(.borderedProminent)
    .buttonBorderShape(.capsule)
    .font(.system(size: 14, weight: .semibold))
  }
}

struct LiveLockView: View {
  let context: ActivityViewContext<CareTimerAttributes>
  var body: some View {
    let a = context.attributes
    let st = context.state
    let p = CarePalette.of(a.type)
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text(LiveText.t(a, "appName", "Child Life")).font(.system(size: 12, weight: .semibold))
          .foregroundStyle(Color.clMuted)
        Spacer()
        Text(LiveText.t(a, "familySees", "Cả nhà đang thấy")).font(.system(size: 12))
          .foregroundStyle(Color.clMuted)
      }
      HStack(spacing: 12) {
        Image(a.type == "sleep" ? "MiniMoon" : "MiniDrop").resizable().scaledToFit().frame(width: 44, height: 44)
        VStack(alignment: .leading, spacing: 2) {
          Text(LiveText.title(a, st)).font(.system(size: 16, weight: .semibold)).foregroundStyle(Color.clInk)
            .lineLimit(1)
          Text(LiveText.since(a, st)).font(.system(size: 13)).foregroundStyle(Color.clMuted).lineLimit(1)
        }
        Spacer(minLength: 0)
        LiveTimerText(state: st).font(.system(size: 28, weight: .semibold).monospacedDigit())
          .foregroundStyle(p.ink).multilineTextAlignment(.trailing).frame(maxWidth: 120, alignment: .trailing)
      }
      LiveButtons(attributes: a, state: st)
    }
    .padding(16)
  }
}
