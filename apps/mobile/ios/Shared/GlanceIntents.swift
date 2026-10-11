import AppIntents
import Foundation

// Timer buttons on widgets and Live Activities (W5): LiveActivityIntents, which iOS runs in the
// app's process (launching it in the background if needed) so the Live Activity can start or end
// with the timer. The one-tap logs live in the widget extension only (ios/widget/LogIntents.swift).

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
