import AppIntents
import Foundation

// Buttons on widgets and Live Activities (W5): they run without opening the app. Logs run in
// the widget extension; timer actions are LiveActivityIntents, which iOS runs in the app's
// process so the Live Activity can start or end with the timer.

@available(iOS 17.0, *)
struct LogBottleIntent: AppIntent {
  static var title: LocalizedStringResource = "Log a bottle"
  static var isDiscoverable = false
  func perform() async throws -> some IntentResult {
    _ = await GlanceActions.logBottle()
    return .result()
  }
}

@available(iOS 17.0, *)
struct LogDiaperIntent: AppIntent {
  static var title: LocalizedStringResource = "Log a diaper"
  static var isDiscoverable = false
  @Parameter(title: "Kind") var kind: String
  init() {}
  init(kind: String) { self.kind = kind }
  func perform() async throws -> some IntentResult {
    _ = await GlanceActions.logDiaper(kind)
    return .result()
  }
}

@available(iOS 17.0, *)
struct UndoLogIntent: AppIntent {
  static var title: LocalizedStringResource = "Undo"
  static var isDiscoverable = false
  @Parameter(title: "Record") var recordId: String
  init() {}
  init(recordId: String) { self.recordId = recordId }
  func perform() async throws -> some IntentResult {
    _ = await GlanceActions.undo(recordId)
    return .result()
  }
}

@available(iOS 17.0, *)
struct StartTimerIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Start a timer"
  static var isDiscoverable = false
  @Parameter(title: "Type") var type: String
  @Parameter(title: "Side") var side: String
  init() {}
  init(type: String, side: String = "left") {
    self.type = type
    self.side = side
  }
  func perform() async throws -> some IntentResult {
    _ = await GlanceActions.start(type, side: side)
    return .result()
  }
}

@available(iOS 17.0, *)
struct EndTimerIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "End the timer"
  static var isDiscoverable = false
  @Parameter(title: "Type") var type: String
  init() {}
  init(type: String) { self.type = type }
  func perform() async throws -> some IntentResult {
    _ = await GlanceActions.end(type)
    return .result()
  }
}

@available(iOS 17.0, *)
struct SwitchSideIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Switch side"
  static var isDiscoverable = false
  func perform() async throws -> some IntentResult {
    _ = await GlanceActions.switchSide()
    return .result()
  }
}
