import AppIntents
import Foundation

// One-tap logs on widgets (W1, W2): defined in the widget extension only, so iOS runs them right
// there, with the app closed. Declared in the app too, iOS would look them up in the app and,
// with the app not running, fail ("There is no metadata for LogBottleIntent").

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
