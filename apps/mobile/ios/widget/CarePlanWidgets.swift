import AppIntents
import SwiftUI
import WidgetKit

// Cùng Chăm Con widgets (Figma 1356:23340): "Việc của Ba" (the person's next task with Xong and
// the family's progress), "Cả nhà 2/10" (or "Nghỉ chút nhé" once nothing is left for them), and
// "Việc của Cô Lan" (a helper's list). The data is the snapshot's `plan`, refreshed from
// Firestore on each timeline so ticks made on other phones show; "Xong" on a task that writes a
// care log or starts the sleep timer opens the app for it (D-138), the others tick right here.

extension Color {
  static let clCardSun = Color(light: 0xffd166, dark: 0x3a3115)
  static let clPeachSoft = Color(light: 0xffe3da, dark: 0x3a2620)
  static let clMintSoft = Color(light: 0xe6f7f5, dark: 0x123536)
  static let clSeparator = Color(light: 0xdce8e7, dark: 0x26393e)
}

@available(iOS 17.0, *)
struct PlanDoneIntent: AppIntent {
  static var title: LocalizedStringResource = "Mark done"
  static var isDiscoverable = false
  @Parameter(title: "Task") var itemId: String
  init() {}
  init(itemId: String) { self.itemId = itemId }
  func perform() async throws -> some IntentResult {
    _ = await GlanceActions.planDone(itemId)
    return .result()
  }
}

/// The task's picture and tile colour (the app's CarePlanArt).
struct PlanArt: View {
  let task: String
  var size: CGFloat = 56

  var body: some View {
    let (soft, art, symbol): (Color, String?, String) = {
      switch task {
      case "bottle", "solids", "water": return (CarePalette.of("bottle").soft, task == "bottle" ? "MiniBottle" : nil, "cup.and.saucer")
      case "breast", "pump": return (CarePalette.of("breast").soft, "MiniDrop", "drop")
      case "sleep": return (CarePalette.of("sleep").soft, "MiniMoon", "moon")
      case "diaper", "potty": return (CarePalette.of("diaper").soft, task == "diaper" ? "MiniDiaper" : nil, "circle.dotted")
      case "bath": return (.clMintSoft, "MiniBath", "bathtub")
      case "read": return (.clPeachSoft, "MiniBook", "book")
      case "vitamin": return (CarePalette.of("breast").soft, "MiniDrop", "drop")
      case "medicine", "temperature": return (.clPeachSoft, nil, task == "medicine" ? "cross.case" : "thermometer")
      case "tummy": return (Color(light: 0xfff4d6, dark: 0x3a3115), nil, "figure.child")
      case "walk": return (.clMintSoft, nil, "sun.max")
      case "teeth": return (.clMintSoft, nil, "sparkles")
      default: return (.clSurface2, nil, "star")
      }
    }()
    ZStack {
      RoundedRectangle(cornerRadius: size * 0.28, style: .continuous).fill(soft)
      if let art {
        Image(art).resizable().scaledToFit().frame(width: size * 0.7, height: size * 0.7)
      } else {
        Image(systemName: symbol).font(.system(size: size * 0.4, weight: .medium)).foregroundStyle(Color.clInk)
      }
    }
    .frame(width: size, height: size)
  }
}

/// The family's progress as a ring (track + teal arc).
struct PlanRing: View {
  let done: Int
  let total: Int
  var width: CGFloat = 8

  var body: some View {
    ZStack {
      Circle().stroke(Color.clSeparator, lineWidth: width)
      Circle()
        .trim(from: 0, to: total == 0 ? 0 : CGFloat(done) / CGFloat(total))
        .stroke(Color.clMintDeep, style: StrokeStyle(lineWidth: width, lineCap: .round))
        .rotationEffect(.degrees(-90))
    }
  }
}

/// Faces of the family, overlapping (Figma "Cả nhà 2/10").
struct PlanFaces: View {
  let faces: [String]
  var size: CGFloat = 24

  var body: some View {
    HStack(spacing: -size * 0.3) {
      ForEach(Array(faces.prefix(4).enumerated()), id: \.offset) { _, art in
        Image(art).resizable().scaledToFit().frame(width: size, height: size)
          .background(Color.clSurface, in: Circle())
          .overlay(Circle().stroke(Color.clSurface, lineWidth: 1.5))
      }
    }
  }
}

/// "Xong" for one task: ticked here, or the app opened for its log (D-138).
struct PlanDoneButton<Label: View>: View {
  let s: GlanceSnapshot
  let plan: GlancePlan
  let item: GlancePlanItem
  @ViewBuilder let label: () -> Label

  var body: some View {
    if !s.canLog {
      EmptyView()
    } else if item.opensApp {
      Link(destination: GlanceLink.url("/today?planDone=\(item.id)&date=\(plan.date)")) { label() }
        .accessibilityLabel(s.text("plan.markDone", ["task": item.name]))
    } else {
      Button(intent: PlanDoneIntent(itemId: item.id)) { label() }
        .buttonStyle(.plain)
        .accessibilityLabel(s.text("plan.markDone", ["task": item.name]))
    }
  }
}

extension GlanceSnapshot {
  func planCount(_ key: String, _ n: Int) -> String {
    n == 1 ? text("\(key).one", "\(n)") : text(key, ["n": "\(n)"])
  }
}

/// Plan widgets read the plan as stored now before drawing (ticks from other phones).
struct PlanProvider: TimelineProvider {
  func placeholder(in context: Context) -> GlanceEntry { GlanceEntry(date: Date(), snapshot: .planSample) }

  func getSnapshot(in context: Context, completion: @escaping (GlanceEntry) -> Void) {
    let s = GlanceSnapshot.load()
    completion(GlanceEntry(date: Date(), snapshot: s?.plan == nil && context.isPreview ? .planSample : s))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<GlanceEntry>) -> Void) {
    Task {
      await GlanceActions.refreshPlan()
      let now = Date()
      completion(
        Timeline(
          entries: [GlanceEntry(date: now, snapshot: GlanceSnapshot.load())],
          policy: .after(now.addingTimeInterval(15 * 60))))
    }
  }
}

// MARK: - Việc của Ba (medium)

struct PlanNextView: View {
  let entry: GlanceEntry

  var body: some View {
    if let s = entry.snapshot, s.signedIn {
      Group {
        if let plan = s.plan {
          VStack(alignment: .leading, spacing: 10) {
            if let next = plan.open.first {
              HStack(spacing: 12) {
                PlanArt(task: next.task, size: 56)
                VStack(alignment: .leading, spacing: 2) {
                  Text(s.text("plan.mine", ["name": plan.me])).font(.system(size: 13))
                    .foregroundStyle(Color.clMuted).lineLimit(1)
                  Text("\(next.time) · \(next.name)").font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.clInk).lineLimit(1).minimumScaleFactor(0.7)
                }
                Spacer(minLength: 0)
                PlanDoneButton(s: s, plan: plan, item: next) {
                  Image(systemName: "checkmark").font(.system(size: 18, weight: .bold)).foregroundStyle(Color.clOnMint)
                    .frame(width: 48, height: 48).background(Color.clMintDeep, in: Circle())
                }
              }
            } else {
              HStack(spacing: 12) {
                Image("BabyFace").resizable().scaledToFit().frame(width: 48, height: 48)
                Text(s.text("plan.rest", "Nghỉ chút nhé")).font(.system(size: 20, weight: .semibold))
                  .foregroundStyle(Color.clInk).lineLimit(1)
                Spacer(minLength: 0)
              }
            }
            Spacer(minLength: 0)
            HStack(spacing: 8) {
              PlanRing(done: plan.doneCount, total: plan.items.count, width: 3).frame(width: 18, height: 18)
              Text(s.text("plan.family", ["done": "\(plan.doneCount)", "total": "\(plan.items.count)"]))
                .font(.system(size: 13)).foregroundStyle(Color.clMuted).lineLimit(1)
              Spacer(minLength: 0)
              PlanFaces(faces: plan.faces)
            }
          }
        } else {
          PlanEmpty(s: s)
        }
      }
      .environment(\.locale, GlanceFormat(s: s).locale)
      .widgetURL(GlanceLink.url("/care/together"))
    } else {
      SpecialSmall(s: entry.snapshot)
    }
  }
}

struct PlanEmpty: View {
  let s: GlanceSnapshot
  var body: some View {
    VStack(spacing: 8) {
      Image("BabyFace").resizable().scaledToFit().frame(width: 40, height: 40)
      Text(s.text("plan.none", "Hôm nay chưa có lịch")).font(.system(size: 14, weight: .semibold))
        .foregroundStyle(Color.clInk).multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

// MARK: - Cả nhà 2/10 · Nghỉ chút nhé (small)

struct PlanFamilyView: View {
  let entry: GlanceEntry

  /// Nothing left for this person today: the yellow "Nghỉ chút nhé".
  static func resting(_ s: GlanceSnapshot?) -> Bool {
    guard let plan = s?.plan, s?.signedIn == true else { return false }
    return plan.open.isEmpty
  }

  var body: some View {
    if let s = entry.snapshot, s.signedIn {
      Group {
        if let plan = s.plan {
          if Self.resting(s) {
            VStack(spacing: 10) {
              Image("BabyFace").resizable().scaledToFit().frame(width: 64, height: 64)
                .frame(width: 88, height: 88).background(Color.clMint, in: Circle())
              Text(s.text("plan.rest", "Nghỉ chút nhé")).font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.clInk).lineLimit(1).minimumScaleFactor(0.8)
            }
          } else {
            let left = plan.items.count - plan.doneCount
            VStack(spacing: 8) {
              ZStack {
                PlanRing(done: plan.doneCount, total: plan.items.count, width: 9)
                Text("\(plan.doneCount)/\(plan.items.count)").font(.system(size: 22, weight: .semibold).monospacedDigit())
                  .foregroundStyle(Color.clInk).minimumScaleFactor(0.6)
              }
              .frame(width: 84, height: 84)
              Text(s.planCount("plan.left", left)).font(.system(size: 13)).foregroundStyle(Color.clMuted)
                .lineLimit(1).minimumScaleFactor(0.8)
            }
          }
        } else {
          PlanEmpty(s: s)
        }
      }
      .environment(\.locale, GlanceFormat(s: s).locale)
      .widgetURL(GlanceLink.url("/care/together"))
    } else {
      SpecialSmall(s: entry.snapshot)
    }
  }
}

// MARK: - Việc của Cô Lan (large)

struct PlanListView: View {
  let entry: GlanceEntry

  var body: some View {
    if let s = entry.snapshot, s.signedIn {
      Group {
        if let plan = s.plan {
          VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
              if let face = plan.helper ? "PersonHelper" : plan.faces.first {
                Image(face).resizable().scaledToFit().frame(width: 26, height: 26)
              }
              Text(s.text("plan.mine", ["name": plan.me])).font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.clInk).lineLimit(1)
              Spacer(minLength: 4)
              Text(s.planCount("plan.count", plan.open.count)).font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.clMintText).padding(.horizontal, 10).frame(height: 24)
                .background(Color.clMintSoft, in: Capsule())
            }
            if plan.open.isEmpty {
              Spacer(minLength: 0)
              HStack {
                Spacer()
                VStack(spacing: 8) {
                  Image("BabyFace").resizable().scaledToFit().frame(width: 56, height: 56)
                  Text(s.text("plan.rest", "Nghỉ chút nhé")).font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.clInk)
                }
                Spacer()
              }
            } else {
              VStack(spacing: 6) {
                ForEach(Array(plan.open.prefix(5).enumerated()), id: \.element.id) { index, item in
                  let first = index == 0
                  HStack(spacing: 12) {
                    Text(item.time).font(.system(size: 15, weight: first ? .semibold : .regular).monospacedDigit())
                      .foregroundStyle(first ? Color.clMintText : Color.clInk).frame(width: 46, alignment: .leading)
                    PlanArt(task: item.task, size: 32)
                    Text(item.name).font(.system(size: 15)).foregroundStyle(Color.clInk).lineLimit(1)
                    Spacer(minLength: 0)
                    PlanDoneButton(s: s, plan: plan, item: item) {
                      Circle().stroke(first ? Color.clMintDeep : Color.clMuted.opacity(0.6), lineWidth: 2)
                        .frame(width: 26, height: 26).frame(width: 36, height: 36).contentShape(Rectangle())
                    }
                  }
                  .frame(height: 40)
                }
              }
            }
            Spacer(minLength: 0)
          }
        } else {
          PlanEmpty(s: s)
        }
      }
      .environment(\.locale, GlanceFormat(s: s).locale)
      .widgetURL(GlanceLink.url("/care/together"))
    } else {
      SpecialSmall(s: entry.snapshot)
    }
  }
}

// MARK: - Widgets

struct PlanNextWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "app.childlife.plan.next", provider: PlanProvider()) { entry in
      PlanNextView(entry: entry).containerBackground(Color.clSurface, for: .widget)
    }
    .configurationDisplayName("glanceGalleryPlanMineName")
    .description("glanceGalleryPlanMineBlurb")
    .supportedFamilies([.systemMedium])
  }
}

struct PlanFamilyWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "app.childlife.plan.family", provider: PlanProvider()) { entry in
      PlanFamilyView(entry: entry)
        .containerBackground(PlanFamilyView.resting(entry.snapshot) ? Color.clCardSun : Color.clSurface, for: .widget)
    }
    .configurationDisplayName("glanceGalleryPlanFamilyName")
    .description("glanceGalleryPlanFamilyBlurb")
    .supportedFamilies([.systemSmall])
  }
}

struct PlanListWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "app.childlife.plan.list", provider: PlanProvider()) { entry in
      PlanListView(entry: entry).containerBackground(Color.clSurface, for: .widget)
    }
    .configurationDisplayName("glanceGalleryPlanMineName")
    .description("glanceGalleryPlanMineBlurb")
    .supportedFamilies([.systemLarge])
  }
}

// MARK: - Gallery sample (Figma)

extension GlanceSnapshot {
  static var planSample: GlanceSnapshot {
    var s = GlanceSnapshot.sample
    let now = Date()
    func item(_ id: Int, _ time: String, _ task: String, _ name: String, mine: Bool, done: Bool = false) -> GlancePlanItem {
      GlancePlanItem(
        id: "pi_\(id)", time: time, dueAt: now, task: task, name: name, mine: mine, done: done,
        opensApp: ["bottle", "breast", "pump", "diaper", "sleep"].contains(task))
    }
    s.plan = GlancePlan(
      date: "", helper: false, me: "Ba", faces: ["PersonBa", "PersonMe", "PersonBaNoi", "PersonHelper"],
      names: [:],
      items: [
        item(1, "07:00", "bottle", "Bú bình", mine: false, done: true),
        item(2, "08:30", "sleep", "Ngủ", mine: false, done: true),
        item(3, "09:00", "vitamin", "Vitamin D3", mine: true),
        item(4, "10:30", "diaper", "Thay tã", mine: true),
        item(5, "11:30", "bottle", "Bú bình", mine: true),
        item(6, "12:00", "sleep", "Ngủ trưa", mine: true),
        item(7, "13:00", "bottle", "Bú bình", mine: true),
        item(8, "14:30", "diaper", "Thay tã", mine: false),
        item(9, "18:30", "bath", "Tắm", mine: false),
        item(10, "20:00", "read", "Đọc sách", mine: false),
      ])
    return s
  }
}
