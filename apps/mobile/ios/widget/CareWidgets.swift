import AppIntents
import SwiftUI
import WidgetKit

// Home-screen widgets W1–W5 (Components 73:399): Small Bottle / Breast / Sleep / Diaper with their
// logged and running states, Medium quick log, Large; Empty and Signed-out states; Offline header.

struct GlanceEntry: TimelineEntry {
  let date: Date
  let snapshot: GlanceSnapshot?
}

struct GlanceProvider: TimelineProvider {
  func placeholder(in context: Context) -> GlanceEntry { GlanceEntry(date: Date(), snapshot: .sample) }

  func getSnapshot(in context: Context, completion: @escaping (GlanceEntry) -> Void) {
    completion(GlanceEntry(date: Date(), snapshot: GlanceSnapshot.load() ?? .sample))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<GlanceEntry>) -> Void) {
    Task {
      var snap = GlanceSnapshot.load()
      if let s = snap, s.pending > 0 {
        // Offline logs go up as soon as the network is back (W4 Offline).
        await GlanceFirestore.flushPending(s)
        snap = GlanceSnapshot.load()
      }
      let now = Date()
      var entries = [GlanceEntry(date: now, snapshot: snap)]
      // "Hoàn tác" for ~5 s, then the normal state again.
      if var s = snap, let logged = s.logged {
        let end = logged.at.addingTimeInterval(Glance.undoWindow)
        if end > now {
          s.logged = nil
          entries.append(GlanceEntry(date: end, snapshot: s))
        } else {
          s.logged = nil
          entries[0] = GlanceEntry(date: now, snapshot: s)
        }
      }
      let base = entries.last!.snapshot
      for i in 1...12 {
        entries.append(GlanceEntry(date: now.addingTimeInterval(Double(i) * 300), snapshot: base))
      }
      completion(Timeline(entries: entries.sorted { $0.date < $1.date }, policy: .atEnd))
    }
  }
}

// MARK: - Building blocks

struct PillButton<Label: View>: View {
  let fill: Color
  let ink: Color
  @ViewBuilder let label: Label
  var body: some View {
    label
      .font(.system(size: 13, weight: .semibold))
      .foregroundStyle(ink)
      .lineLimit(1)
      .minimumScaleFactor(0.8)
      .frame(maxWidth: .infinity, minHeight: 32)
      .background(fill, in: Capsule())
  }
}

struct CheckBadge: View {
  let color: Color
  var body: some View {
    Image(systemName: "checkmark")
      .font(.system(size: 10, weight: .bold))
      .foregroundStyle(.white)
      .frame(width: 18, height: 18)
      .background(color, in: Circle())
  }
}

/// "Child Life" Empty / Signed-out small widget (81:608, 81:625).
struct SpecialSmall: View {
  let s: GlanceSnapshot?
  var body: some View {
    let signedIn = s?.signedIn ?? false
    VStack(alignment: .leading, spacing: 4) {
      Text(s?.text("appName", "Child Life") ?? "Child Life")
        .font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.clMintText)
      Spacer(minLength: 0)
      Text(signedIn ? s!.text("emptyTitle", "Hôm nay chưa ghi") : s?.text("signedOutTitle", "Đăng nhập để dùng widget") ?? "Đăng nhập để dùng widget")
        .font(.system(size: 17, weight: .semibold)).foregroundStyle(Color.clInk)
        .lineLimit(3).minimumScaleFactor(0.8)
      Text(signedIn ? s!.text("emptySub", "Ghi cữ đầu tiên nhé") : s?.text("openApp", "Mở app") ?? "Mở app")
        .font(.system(size: 12)).foregroundStyle(Color.clMuted)
      Spacer(minLength: 0)
      PillButton(fill: .clMintDeep, ink: .clOnMint) {
        Text(signedIn ? s!.text("quickLog", "+ Ghi nhanh") : s?.text("openChildLife", "Mở Child Life") ?? "Mở Child Life")
      }
    }
    .widgetURL(GlanceLink.url(signedIn ? GlanceLink.today : "/"))
  }
}

extension GlanceSnapshot {
  var isEmpty: Bool {
    lastBottle == nil && lastBreast == nil && lastDiaper == nil && sleep == nil && breast == nil
      && lastWokeAt == nil
  }

  func loggedNow(_ type: String, at date: Date) -> GlanceLogged? {
    guard let l = logged, l.type == type, date < l.at.addingTimeInterval(Glance.undoWindow) else { return nil }
    return l
  }
}

// MARK: - Small widgets

struct SmallCareView: View {
  let type: String
  let entry: GlanceEntry

  var body: some View {
    if let s = entry.snapshot, s.signedIn, !s.isEmpty {
      let f = GlanceFormat(s: s)
      Group {
        switch type {
        case "bottle": bottle(s, f)
        case "breast": breast(s, f)
        case "sleep": sleep(s, f)
        default: diaper(s, f)
        }
      }
      .environment(\.locale, f.locale)
    } else {
      SpecialSmall(s: entry.snapshot)
    }
  }

  private func header(_ title: String, _ p: CarePalette, check: Bool = false) -> some View {
    HStack(spacing: 6) {
      Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(p.ink)
      Spacer(minLength: 0)
      if check { CheckBadge(color: p.accent) } else {
        Image(p.art).resizable().scaledToFit().frame(width: 28, height: 28)
      }
    }
  }

  private func big(_ text: String) -> some View {
    Text(text).font(.system(size: 20, weight: .semibold)).foregroundStyle(Color.clInk)
      .lineLimit(2).minimumScaleFactor(0.7)
  }

  private func sub(_ text: String) -> some View {
    Text(text).font(.system(size: 12)).foregroundStyle(Color.clMuted).lineLimit(1).minimumScaleFactor(0.8)
  }

  @ViewBuilder private func bottle(_ s: GlanceSnapshot, _ f: GlanceFormat) -> some View {
    let p = CarePalette.of("bottle")
    if let logged = s.loggedNow("bottle", at: entry.date) {
      VStack(alignment: .leading, spacing: 4) {
        header(s.text("bottle", "Bú bình"), p, check: true)
        Spacer(minLength: 0)
        big(s.text("justNow", "Vừa xong"))
        sub(s.text("logged", ["what": logged.label, "name": s.text("you", "Bạn")]))
        Spacer(minLength: 0)
        HStack(spacing: 6) {
          Button(intent: UndoLogIntent(recordId: logged.recordId)) {
            PillButton(fill: .clSurface, ink: p.ink) { Text(s.text("undo", "Hoàn tác")) }
          }.buttonStyle(.plain)
          Link(destination: GlanceLink.url(GlanceLink.record(logged.recordId))) {
            PillButton(fill: p.accent, ink: .white) { Text(s.text("edit", "Sửa")) }
          }
        }
      }
      .containerBackground(p.soft, for: .widget)
    } else {
      VStack(alignment: .leading, spacing: 4) {
        header(s.text("bottle", "Bú bình"), p)
        Spacer(minLength: 0)
        big(s.lastBottle.map { f.ago($0.at, now: entry.date) } ?? s.text("noneYet", "Chưa có"))
        if let l = s.lastBottle {
          sub([l.amountMl.map { "\($0) ml" }, f.by(l.by)].compactMap { $0 }.joined(separator: " · "))
        }
        Spacer(minLength: 0)
        if s.canLog {
          Button(intent: LogBottleIntent()) {
            PillButton(fill: p.accent, ink: .white) {
              Text(s.lastBottle?.amountMl.map { s.text("plusMl", ["ml": "\($0)"]) } ?? s.text("quickLog", "+ Ghi nhanh"))
            }
          }.buttonStyle(.plain)
        }
      }
      .widgetURL(GlanceLink.url(GlanceLink.log("bottle", s)))
    }
  }

  @ViewBuilder private func breast(_ s: GlanceSnapshot, _ f: GlanceFormat) -> some View {
    let p = CarePalette.of("breast")
    if let t = s.breast {
      VStack(alignment: .leading, spacing: 4) {
        header(s.text("feeding", "Đang bú"), p)
        Spacer(minLength: 0)
        Group {
          if t.paused {
            Text(f.duration(t.total(at: entry.date)))
          } else {
            Text(timerInterval: t.displayStart(at: entry.date)...Date.distantFuture, countsDown: false)
          }
        }
        .font(.system(size: 26, weight: .semibold).monospacedDigit()).foregroundStyle(p.ink)
        sub("\(s.text("breastSide.\(t.activeSide ?? "left")", "")) · \(s.text("sinceTime", ["time": f.time(t.startedAt)]))")
        Spacer(minLength: 0)
        if s.canLog {
          HStack(spacing: 6) {
            Button(intent: SwitchSideIntent()) {
              PillButton(fill: .clSurface, ink: p.ink) { Text(s.text("switchSide", "Đổi bên")) }
            }.buttonStyle(.plain)
            Button(intent: EndTimerIntent(type: "breast")) {
              PillButton(fill: p.accent, ink: .white) { Text(s.text("done", "Xong")) }
            }.buttonStyle(.plain)
          }
        }
      }
      .containerBackground(p.soft, for: .widget)
      .widgetURL(GlanceLink.url(GlanceLink.timer("breast")))
    } else {
      VStack(alignment: .leading, spacing: 4) {
        header(s.text("breast", "Bú mẹ"), p)
        Spacer(minLength: 0)
        if let l = s.lastBreast {
          big(entry.date.timeIntervalSince(l.at) < 300 ? s.text("justNow", "Vừa xong") : f.duration(entry.date.timeIntervalSince(l.at)))
          sub(entry.date.timeIntervalSince(l.at) < 300
            ? s.text("fedFor", ["t": f.duration(Double(l.durationMin ?? 0) * 60), "name": l.by])
            : s.text("agoFor", ["t": f.duration(Double(l.durationMin ?? 0) * 60)]))
        } else {
          big(s.text("noneYet", "Chưa có"))
        }
        Spacer(minLength: 0)
        if s.canLog {
          Button(intent: StartTimerIntent(type: "breast", side: "left")) {
            PillButton(fill: p.accent, ink: .white) { Text(s.text("startBreast", "Bắt đầu bú")) }
          }.buttonStyle(.plain)
        }
      }
      .widgetURL(GlanceLink.url(GlanceLink.log("breast", s)))
    }
  }

  @ViewBuilder private func sleep(_ s: GlanceSnapshot, _ f: GlanceFormat) -> some View {
    let p = CarePalette.of("sleep")
    if let t = s.sleep {
      VStack(alignment: .leading, spacing: 4) {
        header(s.text("sleeping", "Đang ngủ"), p)
        Spacer(minLength: 0)
        Text(timerInterval: t.startedAt...Date.distantFuture, countsDown: false)
          .font(.system(size: 26, weight: .semibold).monospacedDigit()).foregroundStyle(p.ink)
        sub(s.text("since", ["time": f.time(t.startedAt), "name": t.byName]))
        Spacer(minLength: 0)
        if s.canLog {
          Button(intent: EndTimerIntent(type: "sleep")) {
            PillButton(fill: p.accent, ink: .white) { Text(s.text("wake", "Thức dậy")) }
          }.buttonStyle(.plain)
        }
      }
      .containerBackground(p.soft, for: .widget)
      .widgetURL(GlanceLink.url(GlanceLink.timer("sleep")))
    } else {
      VStack(alignment: .leading, spacing: 4) {
        header(s.text("sleepTitle", "Giấc ngủ"), p)
        Spacer(minLength: 0)
        if let woke = s.lastWokeAt {
          if entry.date.timeIntervalSince(woke) < 300 {
            big(s.text("justWoke", "Vừa thức dậy"))
            sub(s.text("slept", ["t": f.duration(Double(s.lastSleepMin ?? 0) * 60)]))
          } else {
            big(s.text("awakeFor", ["t": f.duration(entry.date.timeIntervalSince(woke))]))
            sub(s.text("wokeAt", ["time": f.time(woke)]))
          }
        } else {
          big(s.text("noneYet", "Chưa có"))
        }
        Spacer(minLength: 0)
        if s.canLog {
          Button(intent: StartTimerIntent(type: "sleep")) {
            PillButton(fill: p.accent, ink: .white) { Text(s.text("startSleep", "Bắt đầu ngủ")) }
          }.buttonStyle(.plain)
        }
      }
      .widgetURL(GlanceLink.url(GlanceLink.log("sleep", s)))
    }
  }

  @ViewBuilder private func diaper(_ s: GlanceSnapshot, _ f: GlanceFormat) -> some View {
    let p = CarePalette.of("diaper")
    if let logged = s.loggedNow("diaper", at: entry.date) {
      VStack(alignment: .leading, spacing: 4) {
        header(s.text("diaper", "Thay tã"), p, check: true)
        Spacer(minLength: 0)
        big(s.text("justNow", "Vừa xong"))
        sub(s.text("logged", ["what": logged.label, "name": s.text("you", "Bạn")]))
        Spacer(minLength: 0)
        HStack(spacing: 6) {
          Button(intent: UndoLogIntent(recordId: logged.recordId)) {
            PillButton(fill: .clSurface, ink: p.ink) { Text(s.text("undo", "Hoàn tác")) }
          }.buttonStyle(.plain)
          Link(destination: GlanceLink.url(GlanceLink.record(logged.recordId))) {
            PillButton(fill: p.accent, ink: .white) { Text(s.text("changeType", "Đổi loại")) }
          }
        }
      }
      .containerBackground(p.soft, for: .widget)
    } else {
      VStack(alignment: .leading, spacing: 4) {
        header(s.text("diaper", "Thay tã"), p)
        Spacer(minLength: 0)
        if let l = s.lastDiaper {
          big(entry.date.timeIntervalSince(l.at) < 60 ? s.text("justNow", "Vừa xong") : f.duration(entry.date.timeIntervalSince(l.at)))
          sub(entry.date.timeIntervalSince(l.at) < 60
            ? "\(f.diaper(l.kind)) · \(f.by(l.by))"
            : s.text("agoKind", ["kind": f.diaper(l.kind)]))
        } else {
          big(s.text("noneYet", "Chưa có"))
        }
        Spacer(minLength: 0)
        if s.canLog {
          HStack(spacing: 4) {
            ForEach(["wet", "dirty", "both"], id: \.self) { kind in
              Button(intent: LogDiaperIntent(kind: kind)) {
                PillButton(fill: kind == "wet" ? p.accent : .clSurface, ink: kind == "wet" ? .white : p.ink) {
                  Text(f.diaper(kind))
                }
              }.buttonStyle(.plain)
            }
          }
        }
      }
      .widgetURL(GlanceLink.url(GlanceLink.log("diaper", s)))
    }
  }
}

/// One small widget per care type (Widget requires a parameterless init). Gallery names and blurbs
/// are keys in Localizable.xcstrings, generated from the ARB catalogs by tool/s8_widget_strings.py.
private func smallConfiguration(_ kind: String, _ type: String, _ name: LocalizedStringResource,
  _ blurb: LocalizedStringResource) -> some WidgetConfiguration {
  StaticConfiguration(kind: kind, provider: GlanceProvider()) { entry in
    SmallCareView(type: type, entry: entry).containerBackground(Color.clSurface, for: .widget)
  }
  .configurationDisplayName(name)
  .description(blurb)
  .supportedFamilies([.systemSmall])
}

struct BottleWidget: Widget {
  var body: some WidgetConfiguration {
    smallConfiguration("app.childlife.bottle", "bottle", "glanceGalleryBottleName", "glanceGalleryBottleBlurb")
  }
}

struct BreastWidget: Widget {
  var body: some WidgetConfiguration {
    smallConfiguration("app.childlife.breast", "breast", "glanceGalleryBreastName", "glanceGalleryBreastBlurb")
  }
}

struct SleepWidget: Widget {
  var body: some WidgetConfiguration {
    smallConfiguration("app.childlife.sleep", "sleep", "glanceGallerySleepName", "glanceGallerySleepBlurb")
  }
}

struct DiaperWidget: Widget {
  var body: some WidgetConfiguration {
    smallConfiguration("app.childlife.diaper", "diaper", "glanceGalleryDiaperName", "glanceGalleryDiaperBlurb")
  }
}

// MARK: - Quick-log tiles (Medium / Large)

struct QuickTile: View {
  let type: String
  let s: GlanceSnapshot
  let date: Date

  var body: some View {
    let p = CarePalette.of(type)
    let f = GlanceFormat(s: s)
    let logged = s.loggedNow(type, at: date) != nil
    let content = VStack(alignment: .leading, spacing: 2) {
      HStack(alignment: .top) {
        Image(p.art).resizable().scaledToFit().frame(width: 30, height: 30)
        Spacer(minLength: 0)
        if logged { CheckBadge(color: p.accent) } else if s.canLog {
          Image(systemName: "plus").font(.system(size: 10, weight: .bold)).foregroundStyle(p.ink)
            .frame(width: 18, height: 18).background(Color.clSurface, in: Circle())
        }
      }
      Spacer(minLength: 0)
      Text(label(s)).font(.system(size: 12, weight: .semibold)).foregroundStyle(p.ink).lineLimit(1)
      Text(meta(s, f, logged: logged)).font(.system(size: 11, weight: logged ? .semibold : .regular))
        .foregroundStyle(logged ? p.ink : Color.clMuted).lineLimit(1).minimumScaleFactor(0.8)
    }
    .padding(8)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(p.soft, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

    // A tile opens the app's own log for its type, as the Hôm nay tile does (ml, kind, side,
    // time; Sleep asks "đang ngủ hay đã ngủ xong"); a running timer opens itself. Owner request
    // 2026-10-11: logging from the widget goes through the same choices as the app.
    if !s.canLog {
      content
    } else if (type == "sleep" && s.sleep != nil) || (type == "breast" && s.breast != nil) {
      Link(destination: GlanceLink.url(GlanceLink.timer(type))) { content }
    } else {
      Link(destination: GlanceLink.url(GlanceLink.log(type, s))) { content }
    }
  }

  private func label(_ s: GlanceSnapshot) -> String {
    switch type {
    case "bottle": return s.text("bottle", "Bú bình")
    case "breast": return s.breast != nil ? s.text("feeding", "Đang bú") : s.text("breast", "Bú mẹ")
    case "sleep": return s.sleep != nil ? s.text("sleeping", "Đang ngủ") : s.text("sleep", "Ngủ")
    default: return s.text("diaper", "Thay tã")
    }
  }

  private func meta(_ s: GlanceSnapshot, _ f: GlanceFormat, logged: Bool) -> String {
    if logged { return s.text("justNow", "Vừa xong") }
    func since(_ d: Date?) -> String { d.map { f.duration(date.timeIntervalSince($0), short: true) } ?? "—" }
    switch type {
    case "bottle": return since(s.lastBottle?.at)
    case "breast":
      if let t = s.breast { return f.duration(t.total(at: date), short: true) }
      return since(s.lastBreast?.at)
    case "sleep":
      if let t = s.sleep { return f.duration(date.timeIntervalSince(t.startedAt), short: true) }
      return s.lastWokeAt.map { s.text("awakeShort", ["t": f.duration(date.timeIntervalSince($0), short: true)]) } ?? "—"
    default: return since(s.lastDiaper?.at)
    }
  }
}

/// Header: avatar + nickname + summary; the Undo toast while a log is fresh; "Chưa đồng bộ".
struct GlanceHeader: View {
  let s: GlanceSnapshot
  let date: Date
  var trailing: String? = nil

  /// "Bú bình · 120 ml" / "Thay tã · Ướt"; just the type when there is nothing more to say.
  private func toastWhat(_ logged: GlanceLogged) -> String {
    let type = s.text(logged.type, logged.type)
    return logged.label.isEmpty || logged.label == type ? type : "\(type) · \(logged.label)"
  }

  var body: some View {
    let f = GlanceFormat(s: s)
    if let logged = s.logged, date < logged.at.addingTimeInterval(Glance.undoWindow) {
      HStack(spacing: 8) {
        Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundStyle(Color.clMint)
        Text(s.text("loggedToast", ["what": toastWhat(logged)]))
          .font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.clSurface).lineLimit(1)
          .minimumScaleFactor(0.8)
        Spacer(minLength: 0)
        Button(intent: UndoLogIntent(recordId: logged.recordId)) {
          Text(s.text("undo", "Hoàn tác")).font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.clMint)
        }.buttonStyle(.plain)
      }
      .padding(.horizontal, 12).frame(height: 30)
      .background(Color.clInk, in: Capsule())
    } else {
      HStack(spacing: 6) {
        Image("BabyFace").resizable().scaledToFit().frame(width: 22, height: 22)
        Text(s.nickname ?? "").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.clInk)
        Spacer(minLength: 4)
        if s.pending > 0 {
          Image(systemName: "icloud.slash").font(.system(size: 11)).foregroundStyle(Color.clPending)
          Text(s.text("pending", ["n": "\(s.pending)"])).font(.system(size: 11, weight: .medium))
            .foregroundStyle(Color.clPending).lineLimit(1).minimumScaleFactor(0.8)
        } else {
          Text(trailing ?? s.text("summary", ["feeds": "\(s.feedsToday)", "sleep": f.duration(Double(s.sleptTodayMin) * 60, short: true)]))
            .font(.system(size: 11)).foregroundStyle(Color.clMuted).lineLimit(1).minimumScaleFactor(0.8)
        }
      }
      .frame(height: 30)
    }
  }
}

struct MediumCareView: View {
  let entry: GlanceEntry
  var body: some View {
    if let s = entry.snapshot, s.signedIn {
      VStack(spacing: 8) {
        GlanceHeader(s: s, date: entry.date)
        HStack(spacing: 8) {
          ForEach(["bottle", "breast", "sleep", "diaper"], id: \.self) { QuickTile(type: $0, s: s, date: entry.date) }
        }
      }
      .environment(\.locale, GlanceFormat(s: s).locale)
      .widgetURL(GlanceLink.url(GlanceLink.today))
    } else {
      SpecialSmall(s: entry.snapshot)
    }
  }
}

struct LargeCareView: View {
  let entry: GlanceEntry
  var body: some View {
    if let s = entry.snapshot, s.signedIn {
      let f = GlanceFormat(s: s)
      let p = CarePalette.of("sleep")
      VStack(alignment: .leading, spacing: 10) {
        GlanceHeader(s: s, date: entry.date, trailing: f.day(entry.date))
        // Sleep status card.
        HStack(spacing: 10) {
          Image(p.art).resizable().scaledToFit().frame(width: 36, height: 36)
          VStack(alignment: .leading, spacing: 2) {
            if let t = s.sleep {
              Text(s.text("sleeping", "Đang ngủ")).font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.clInk)
              Text(timerInterval: t.startedAt...Date.distantFuture, countsDown: false)
                .font(.system(size: 12).monospacedDigit()).foregroundStyle(p.ink)
            } else if let woke = s.lastWokeAt {
              Text(s.text("awakeFor", ["t": f.duration(entry.date.timeIntervalSince(woke))]))
                .font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.clInk)
              Text("\(s.text("wokeAt", ["time": f.time(woke)])) · \(s.text("sleptToday", ["t": f.duration(Double(s.sleptTodayMin) * 60, short: true)]))")
                .font(.system(size: 11)).foregroundStyle(Color.clMuted).lineLimit(1)
            } else {
              Text(s.text("sleepTitle", "Giấc ngủ")).font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.clInk)
            }
          }
          Spacer(minLength: 0)
          if s.canLog {
            if s.sleep != nil {
              Button(intent: EndTimerIntent(type: "sleep")) {
                Text(s.text("wake", "Thức dậy")).font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                  .padding(.horizontal, 14).frame(height: 32).background(p.accent, in: Capsule())
              }.buttonStyle(.plain)
            } else {
              Button(intent: StartTimerIntent(type: "sleep")) {
                Text(s.text("sleep", "Ngủ")).font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                  .padding(.horizontal, 14).frame(height: 32).background(p.accent, in: Capsule())
              }.buttonStyle(.plain)
            }
          }
        }
        .padding(10)
        .background(p.soft, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

        HStack(spacing: 8) {
          ForEach(["bottle", "breast", "sleep", "diaper"], id: \.self) { QuickTile(type: $0, s: s, date: entry.date) }
        }
        .frame(height: 86)

        Text(s.text("recent", "Gần đây")).font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.clMuted)
        VStack(spacing: 6) {
          ForEach(s.recent.prefix(3), id: \.id) { r in
            Link(destination: GlanceLink.url(GlanceLink.record(r.id))) {
              HStack(spacing: 8) {
                Circle().fill(CarePalette.of(r.type).accent).frame(width: 7, height: 7)
                Text(f.time(r.at)).font(.system(size: 12).monospacedDigit()).foregroundStyle(Color.clMuted)
                Text(r.text).font(.system(size: 12, weight: .medium)).foregroundStyle(Color.clInk).lineLimit(1)
                Spacer(minLength: 0)
                Text(r.by).font(.system(size: 11)).foregroundStyle(Color.clMuted).lineLimit(1)
              }
            }
          }
        }
        Spacer(minLength: 0)
        Text(s.text("totals", [
          "bottles": "\(s.bottlesToday)", "ml": "\(s.bottleMlToday)", "breasts": "\(s.breastsToday)",
          "diapers": "\(s.diapersToday)",
        ]))
        .font(.system(size: 11)).foregroundStyle(Color.clMuted).lineLimit(2).minimumScaleFactor(0.8)
      }
      .environment(\.locale, f.locale)
      .widgetURL(GlanceLink.url(GlanceLink.today))
    } else {
      SpecialSmall(s: entry.snapshot)
    }
  }
}

struct QuickLogWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "app.childlife.quick", provider: GlanceProvider()) { entry in
      MediumCareView(entry: entry).containerBackground(Color.clSurface, for: .widget)
    }
    .configurationDisplayName("glanceGalleryQuickName")
    .description("glanceGalleryQuickBlurb")
    .supportedFamilies([.systemMedium])
  }
}

struct TodayWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "app.childlife.today", provider: GlanceProvider()) { entry in
      LargeCareView(entry: entry).containerBackground(Color.clSurface, for: .widget)
    }
    .configurationDisplayName("glanceGalleryTodayName")
    .description("glanceGalleryTodayBlurb")
    .supportedFamilies([.systemLarge])
  }
}

// MARK: - Placeholder (Figma sample data, shown in the widget gallery)

extension GlanceSnapshot {
  static var sample: GlanceSnapshot {
    let now = Date()
    return GlanceSnapshot(
      signedIn: true, canLog: false, locale: "vi", projectId: "", apiKey: "", emulatorHost: nil,
      uid: nil, babyId: nil, nickname: "Teddy", author: nil,
      lastBottle: GlanceLast(at: now.addingTimeInterval(-45 * 60), by: "Mẹ", amountMl: 120, milk: "formula"),
      lastBreast: GlanceLast(at: now.addingTimeInterval(-215 * 60), by: "Mẹ", side: "left", durationMin: 15),
      lastDiaper: GlanceLast(at: now.addingTimeInterval(-85 * 60), by: "Cô Lan", kind: "wet"),
      lastWokeAt: now.addingTimeInterval(-120 * 60), lastSleepMin: 80, sleptTodayMin: 470, feedsToday: 2,
      bottleMlToday: 240, bottlesToday: 2, breastsToday: 1, diapersToday: 2, sleep: nil, breast: nil,
      recent: [], logged: nil, pending: 0, copy: [:], generatedAt: now)
  }
}
