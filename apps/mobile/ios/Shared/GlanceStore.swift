import Foundation

// Shared by the app, the widget extension and the Live Activity intents (S8). The app writes a
// "glance snapshot" of Today into the App Group; widgets render it; App Intents log through
// Firestore REST and patch the snapshot so the widget changes at once (W5). No child photos
// are ever written here, only the nickname and care times the lock screen shows (S8 acceptance).

enum Glance {
  /// `CLAppGroup` from Info.plist (set per flavor by tool/ios_flavors.rb).
  static var appGroup: String? { Bundle.main.object(forInfoDictionaryKey: "CLAppGroup") as? String }

  static var defaults: UserDefaults? { appGroup.flatMap(UserDefaults.init(suiteName:)) }

  static let snapshotKey = "glance.snapshot"
  static let pendingKey = "glance.pending"
  static let undoWindow: TimeInterval = 5
}

/// A member's "Mẹ ghi" label, exactly as Rules check it against the membership (D-024).
struct GlanceAuthor: Codable, Hashable {
  var name: String
  var relation: String
  var relationCustom: String?
}

struct GlanceLast: Codable, Hashable {
  var at: Date
  var by: String
  var amountMl: Int?
  var milk: String?
  var kind: String?
  var side: String?
  var durationMin: Int?
}

struct GlanceSide: Codable, Hashable {
  var accumulatedMs: Int
  var runningSince: Date?

  func elapsed(at now: Date) -> TimeInterval {
    Double(accumulatedMs) / 1000 + (runningSince.map { max(0, now.timeIntervalSince($0)) } ?? 0)
  }
}

/// A running timer (sleep / breast), mirrored from `babies/{b}/timers/{type}`.
struct GlanceTimer: Codable, Hashable {
  var type: String
  var sessionId: String
  var startedAt: Date
  var startedBy: String
  var byName: String
  var left: GlanceSide?
  var right: GlanceSide?
  var paused: Bool

  var activeSide: String? {
    if left?.runningSince != nil { return "left" }
    if right?.runningSince != nil { return "right" }
    return nil
  }

  func total(at now: Date) -> TimeInterval {
    if type == "sleep" { return max(0, now.timeIntervalSince(startedAt)) }
    return (left?.elapsed(at: now) ?? 0) + (right?.elapsed(at: now) ?? 0)
  }

  /// The date a `Text(timerInterval:)` counts from so it shows [total] right now.
  func displayStart(at now: Date) -> Date { now.addingTimeInterval(-total(at: now)) }
}

struct GlanceRecent: Codable, Hashable {
  var id: String
  var at: Date
  var type: String
  var text: String
  var by: String
}

/// "Đã ghi Thay tã · Ướt" + "Hoàn tác" for ~5 s after a one-tap log (W4/W5).
struct GlanceLogged: Codable, Hashable {
  var recordId: String
  var type: String
  var label: String
  var at: Date
  /// What the tile showed before, restored by "Hoàn tác".
  var previous: GlanceLast?
}

/// A Cùng Chăm Con task on the plan widgets (lib/features/glance/glance_plan.dart).
struct GlancePlanItem: Codable, Hashable {
  var id: String
  var time: String
  var dueAt: Date
  var task: String
  var name: String
  var mine: Bool
  var done: Bool
  /// "Xong" writes a care log or starts the sleep timer first (D-138): it opens the app.
  var opensApp: Bool
}

/// Today's plan for the Cùng Chăm Con widgets (Figma 1356:23340).
struct GlancePlan: Codable, Hashable {
  var date: String
  var helper: Bool
  /// "Ba" in "Việc của Ba".
  var me: String
  /// Art names of the family on "Cả nhà 2/10".
  var faces: [String]
  /// Task names by key, for tasks added on another phone.
  var names: [String: String]
  var items: [GlancePlanItem]

  var mine: [GlancePlanItem] { items.filter(\.mine) }
  var open: [GlancePlanItem] { mine.filter { !$0.done } }
  var doneCount: Int { items.filter(\.done).count }
}

struct GlanceSnapshot: Codable {
  var signedIn: Bool
  var canLog: Bool
  /// Cùng nuôi add memories (the camera and photo widgets); optional so older snapshots decode.
  var canAddMemories: Bool?
  var locale: String
  var projectId: String
  var apiKey: String
  /// Local emulators (debug runs only): host:port for Auth and Firestore.
  var emulatorHost: String?
  var uid: String?
  var babyId: String?
  var nickname: String?
  var author: GlanceAuthor?
  var lastBottle: GlanceLast?
  var lastBreast: GlanceLast?
  var lastDiaper: GlanceLast?
  var lastWokeAt: Date?
  var lastSleepMin: Int?
  var sleptTodayMin: Int
  var feedsToday: Int
  var bottleMlToday: Int
  var bottlesToday: Int
  var breastsToday: Int
  var diapersToday: Int
  var sleep: GlanceTimer?
  var breast: GlanceTimer?
  var recent: [GlanceRecent]
  var logged: GlanceLogged?
  var pending: Int
  /// Cùng Chăm Con; null without a plan this person can tick today.
  var plan: GlancePlan? = nil
  var copy: [String: String]
  var generatedAt: Date

  func text(_ key: String, _ fallback: String = "") -> String { copy[key] ?? fallback }

  /// `{x}` placeholders replaced in order of the arguments.
  func text(_ key: String, _ values: [String: String]) -> String {
    var s = copy[key] ?? key
    for (k, v) in values { s = s.replacingOccurrences(of: "{\(k)}", with: v) }
    return s
  }

  static func load() -> GlanceSnapshot? {
    guard let data = Glance.defaults?.data(forKey: Glance.snapshotKey) else { return nil }
    return try? GlanceCoding.decoder.decode(GlanceSnapshot.self, from: data)
  }

  func save() {
    guard let data = try? GlanceCoding.encoder.encode(self) else { return }
    Glance.defaults?.set(data, forKey: Glance.snapshotKey)
  }

  static func update(_ change: (inout GlanceSnapshot) -> Void) {
    guard var s = load() else { return }
    change(&s)
    s.save()
  }
}

enum GlanceCoding {
  static let encoder: JSONEncoder = {
    let e = JSONEncoder()
    e.dateEncodingStrategy = .millisecondsSince1970
    return e
  }()

  static let decoder: JSONDecoder = {
    let d = JSONDecoder()
    d.dateDecodingStrategy = .millisecondsSince1970
    return d
  }()
}

/// Writes that could not reach Firestore (offline): retried by the next intent or app launch,
/// shown as "Chưa đồng bộ · N bản ghi chờ" (W4 Offline). Creates are idempotent (fixed ids).
enum GlancePending {
  static func all() -> [Data] { (Glance.defaults?.array(forKey: Glance.pendingKey) as? [Data]) ?? [] }

  static func add(_ commit: Data) {
    var list = all()
    list.append(commit)
    Glance.defaults?.set(list, forKey: Glance.pendingKey)
    GlanceSnapshot.update { $0.pending = list.count }
  }

  static func replace(_ list: [Data]) {
    Glance.defaults?.set(list, forKey: Glance.pendingKey)
    GlanceSnapshot.update { $0.pending = list.count }
  }
}
