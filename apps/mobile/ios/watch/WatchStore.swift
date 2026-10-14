import SwiftUI
import WatchKit

/// What the watch shows and does. Data and writes go through the glance kit (ios/Shared): the
/// same snapshot shape the widgets read, the same Firestore REST commits the widgets send, so the
/// same Rules check them (D-022, D-024) and the same offline queue keeps them (W13).
@MainActor
final class WatchStore: ObservableObject {
  enum Route: Hashable { case bottle, breast, sleep, diaper, babies }
  enum Phase { case unlinked, cannotLog, ready }

  /// W06 "Đã ghi tã ướt · 10:24 · Mẹ ghi · Hoàn tác".
  struct Saved: Equatable {
    var id = UUID()
    var title: String
    var at: Date
    var by: String
    /// The record "Hoàn tác" soft-deletes.
    var undoRecord: String?
  }

  @Published private(set) var snapshot: GlanceSnapshot?
  @Published private(set) var hasSession = false
  @Published var path: [Route] = []
  @Published var saved: Saved?
  @Published var failed = false
  /// W04 offers "Hoàn tác" until then, right after this watch started the sleep.
  @Published var sleepUndoUntil: Date?

  static let demoKey = "watch.demo"

  var demo: Bool { Glance.defaults?.bool(forKey: Self.demoKey) ?? false }

  var phase: Phase {
    guard let s = snapshot, s.signedIn, hasSession || demo else { return .unlinked }
    return s.canLog && s.babyId != nil ? .ready : .cannotLog
  }

  init() {
    reload()
    #if DEBUG
    // Debug runs: `-watchDemo YES` opens the sample data, `-watchRoute bottle|breast|sleep|diaper|babies`
    // opens a screen (simulator checks without tapping).
    let args = UserDefaults.standard
    if args.bool(forKey: "watchDemo"), phase == .unlinked { startDemo() }
    let routes: [String: Route] = ["bottle": .bottle, "breast": .breast, "sleep": .sleep, "diaper": .diaper, "babies": .babies]
    if let route = args.string(forKey: "watchRoute").flatMap({ routes[$0] }) { path = [route] }
    // `-watchAction wet|bottle|wake|left|switch|stop`: run one action on launch.
    if let action = args.string(forKey: "watchAction") {
      Task {
        switch action {
        case "wet": await logDiaper("wet")
        case "bottle": await logBottle(150)
        case "wake": await endSleep()
        case "sleep": await startSleep()
        case "left": await startBreast("left"); path = [.breast]
        case "switch": await switchSide(); path = [.breast]
        case "stop": await endBreast()
        default: break
        }
      }
    }
    #endif
  }

  func reload() {
    snapshot = GlanceSnapshot.load()
    hasSession = GlanceAuth.load() != nil
    // `-watchLocale en` (debug runs) overrides the phone's language.
    WatchText.locale = UserDefaults.standard.string(forKey: "watchLocale") ?? snapshot?.locale ?? "vi"
  }

  /// W11: inside the default night schedule (21:00–06:00, as the app's Night care), or forced
  /// with `-watchNight YES|NO` on debug runs.
  func night(at date: Date) -> Bool {
    let args = UserDefaults.standard
    if args.object(forKey: "watchNight") != nil { return args.bool(forKey: "watchNight") }
    let hour = Calendar.current.component(.hour, from: date)
    return hour >= 21 || hour < 6
  }

  // MARK: Actions

  private func run(_ action: () async -> GlanceActions.Result) async -> Bool {
    WatchSync.markLocalChange()
    let result = await action()
    // Sample data never leaves the watch: nothing to queue.
    if demo { GlancePending.replace([]) }
    reload()
    if result == .notAllowed {
      failed = true
      WKInterfaceDevice.current().play(.failure)
      return false
    }
    return true
  }

  private var byName: String { snapshot?.author?.name ?? "" }

  private func showSaved(_ title: String, undoRecord: String?) {
    path.removeAll()
    let next = Saved(title: title, at: Date(), by: byName, undoRecord: undoRecord)
    saved = next
    WKInterfaceDevice.current().play(.success)
    Task {
      try? await Task.sleep(for: .seconds(Glance.undoWindow))
      if saved?.id == next.id { saved = nil }
    }
  }

  func logDiaper(_ kind: String) async {
    guard await run({ await GlanceActions.logDiaper(kind) }) else { return }
    let key = kind == "wet" ? "watchLoggedWet" : kind == "dirty" ? "watchLoggedDirty" : "watchLoggedBoth"
    showSaved(WatchText.t(key), undoRecord: snapshot?.logged?.recordId)
  }

  /// W02: the crown's amount; the milk of the last bottle, else breast milk as the app's sheet.
  func logBottle(_ ml: Int) async {
    let milk = snapshot?.lastBottle?.milk ?? "breastMilk"
    guard await run({ await GlanceActions.logBottle(amountMl: ml, milk: milk) }) else { return }
    showSaved(WatchText.t("watchLoggedBottle", ["ml": "\(ml)"]), undoRecord: snapshot?.logged?.recordId)
  }

  /// Tapping Ngủ while no sleep runs starts it at once and opens W04: the running clock is the
  /// confirmation (a check mark is for a finished log); W04 offers "Hoàn tác" for 5 s (P-142).
  func startSleep() async {
    guard await run({ await GlanceActions.start("sleep") }) else { return }
    sleepUndoUntil = Date().addingTimeInterval(Glance.undoWindow)
    path = [.sleep]
    WKInterfaceDevice.current().play(.start)
  }

  /// "Hoàn tác" on W04: the sleep just started is cancelled, nothing is recorded.
  func cancelStartedSleep() async {
    sleepUndoUntil = nil
    path.removeAll()
    _ = await run({ await GlanceActions.cancel("sleep") })
  }

  func endSleep() async {
    sleepUndoUntil = nil
    let record = snapshot?.sleep.map { "r_\($0.sessionId)" }
    guard await run({ await GlanceActions.end("sleep") }) else { return }
    showSaved(WatchText.t("watchLoggedSleep"), undoRecord: record)
  }

  func startBreast(_ side: String) async {
    _ = await run({ await GlanceActions.start("breast", side: side) })
  }

  func switchSide() async {
    _ = await run({ await GlanceActions.switchSide() })
    WKInterfaceDevice.current().play(.click)
  }

  func endBreast() async {
    let record = snapshot?.breast.map { "r_\($0.sessionId)" }
    guard await run({ await GlanceActions.end("breast") }) else { return }
    showSaved(WatchText.t("watchLoggedBreast"), undoRecord: record)
  }

  func undo() async {
    guard let id = saved?.undoRecord else { return }
    saved = nil
    _ = await run({ await GlanceActions.undo(id) })
  }

  /// W13 "3 lần ghi chờ gửi": try again now.
  func flush() async {
    guard !demo, let s = snapshot, s.pending > 0 else { return }
    await GlanceFirestore.flushPending(s)
    reload()
  }

  #if DEBUG
  /// "Xem thử": sample data on a watch that is not linked, so the screens can be tried in the
  /// simulator without a signed-in phone. Debug builds only; nothing is sent.
  func startDemo() {
    Glance.defaults?.set(true, forKey: Self.demoKey)
    WatchDemo.snapshot().save()
    reload()
  }
  #endif
}

/// Snapshots arriving from the phone (WatchLink) — kept apart from the store so the
/// WatchConnectivity delegate can apply them off the main actor.
enum WatchSync {
  private static let lastLocalKey = "watch.lastLocalChange"

  static func markLocalChange() {
    Glance.defaults?.set(Date().timeIntervalSince1970, forKey: lastLocalKey)
  }

  /// The phone's snapshot, unless it was made before the watch's own last write (it would take
  /// that write back off the screen until the next one arrives).
  static func receive(_ data: Data) {
    guard var next = try? GlanceCoding.decoder.decode(GlanceSnapshot.self, from: data) else { return }
    let lastLocal = Glance.defaults?.double(forKey: lastLocalKey) ?? 0
    let wasDemo = Glance.defaults?.bool(forKey: WatchStore.demoKey) ?? false
    if !wasDemo && next.generatedAt.timeIntervalSince1970 < lastLocal { return }
    let previous = GlanceSnapshot.load()
    next.pending = GlancePending.all().count
    if let logged = previous?.logged, logged.at.addingTimeInterval(Glance.undoWindow) > Date() {
      next.logged = logged
    }
    next.save()
    Glance.defaults?.set(false, forKey: WatchStore.demoKey)
  }

  static func signOut() {
    GlanceAuth.clear()
    GlanceSnapshot.update { s in
      s.signedIn = false
      s.sleep = nil
      s.breast = nil
    }
  }
}
