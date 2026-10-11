import Foundation

#if canImport(ActivityKit)
import ActivityKit
#endif

/// Live Activity / Dynamic Island for a running Sleep or Breast timer (LiveActivity/Lock screen
/// 75:576, DynamicIsland 75:606). Static strings travel in the attributes (from the app's ARB
/// copy, D-012); the timer state in the content state.
struct CareTimerAttributes: Codable, Hashable {
  var type: String
  var babyId: String
  var nickname: String
  var copy: [String: String]

  struct ContentState: Codable, Hashable {
    var sessionId: String
    var startedAt: Date
    /// `Text(timerInterval:)` counts from here (breast: the sum of both sides so far).
    var countFrom: Date
    var side: String?
    var paused: Bool
    var byName: String
  }
}

#if canImport(ActivityKit)
@available(iOS 16.1, *)
extension CareTimerAttributes: ActivityAttributes {}
#endif

enum GlanceLive {
  /// Activities can only be started by the app itself, not by the widget extension.
  static var isApp: Bool { Bundle.main.bundleURL.pathExtension == "app" }

  static func state(_ t: GlanceTimer, now: Date = Date()) -> CareTimerAttributes.ContentState {
    .init(
      sessionId: t.sessionId, startedAt: t.startedAt, countFrom: t.displayStart(at: now),
      side: t.activeSide, paused: t.paused, byName: t.byName)
  }

  /// Makes the running activities match the snapshot's timers: start, update or end.
  static func sync() async {
    #if canImport(ActivityKit)
    guard isApp, #available(iOS 16.2, *), let s = GlanceSnapshot.load() else { return }
    let enabled = ActivityAuthorizationInfo().areActivitiesEnabled
    for type in ["sleep", "breast"] {
      let timer = s.signedIn ? (type == "sleep" ? s.sleep : s.breast) : nil
      let existing = Activity<CareTimerAttributes>.activities.filter { $0.attributes.type == type }
      guard let timer, let babyId = s.babyId else {
        for a in existing { await a.end(nil, dismissalPolicy: .immediate) }
        continue
      }
      let content = ActivityContent(state: state(timer), staleDate: nil)
      if let current = existing.first(where: { $0.attributes.babyId == babyId }) {
        if current.content.state != content.state { await current.update(content) }
        for other in existing where other.id != current.id { await other.end(nil, dismissalPolicy: .immediate) }
      } else if enabled {
        for other in existing { await other.end(nil, dismissalPolicy: .immediate) }
        let attributes = CareTimerAttributes(
          type: type, babyId: babyId, nickname: s.nickname ?? "", copy: liveCopy(s))
        _ = try? Activity.request(attributes: attributes, content: content, pushType: nil)
      }
    }
    #endif
  }

  static func liveCopy(_ s: GlanceSnapshot) -> [String: String] {
    let keys = [
      "appName", "familySees", "sleepingTitle", "since", "wake", "editTime", "editTimeShort",
      "breastSide.left", "breastSide.right", "breastTitle", "switchSide", "endFeed",
    ]
    var out: [String: String] = [:]
    for k in keys { out[k] = s.copy[k] }
    return out
  }
}
