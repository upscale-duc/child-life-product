import Foundation

#if DEBUG
/// Sample data for "Xem thử" (debug builds only), matching the Figma frames: last bottle 2:15
/// ago (120 ml), last breastfeed 3:35 ago, last diaper 1:25 ago, Teddy asleep for 0:42 (W01).
enum WatchDemo {
  static func snapshot(now: Date = Date()) -> GlanceSnapshot {
    func ago(_ h: Int, _ m: Int) -> Date { now.addingTimeInterval(-Double(h * 3600 + m * 60)) }
    return GlanceSnapshot(
      signedIn: true, canLog: true, canAddMemories: false, locale: "vi", projectId: "demo", apiKey: "",
      emulatorHost: nil, uid: "demo", babyId: "demo", nickname: "Teddy",
      author: GlanceAuthor(name: "Mẹ", relation: "mother", relationCustom: nil),
      lastBottle: GlanceLast(at: ago(2, 15), by: "Mẹ", amountMl: 120, milk: "formula"),
      lastBreast: GlanceLast(at: ago(3, 35), by: "Mẹ", side: "left", durationMin: 14),
      lastDiaper: GlanceLast(at: ago(1, 25), by: "Ba", kind: "wet"),
      lastWokeAt: nil, lastSleepMin: nil, sleptTodayMin: 185, feedsToday: 5, bottleMlToday: 480,
      bottlesToday: 4, breastsToday: 1, diapersToday: 4,
      sleep: GlanceTimer(
        type: "sleep", sessionId: GlanceActions.newHex(), startedAt: ago(0, 42), startedBy: "demo",
        byName: "Mẹ", left: nil, right: nil, paused: false),
      breast: nil, recent: [], logged: nil, pending: 0, copy: [:], generatedAt: now)
  }
}
#endif
