import Flutter
import Foundation
import UserNotifications

/// Rule reminders on the lock screen (v1.0 1f, D-051): the server's push carries the category
/// `CL_RULE_<TYPE>`; long-press offers "Ghi lần bú" (opens the app on the log), "Báo lại sau 15
/// phút" and "Bỏ qua lần này". The last two answer the `answerRuleReminder` Function from here,
/// without opening the app, using the widgets' shared session (GlanceAuth).
enum RuleNotifications {
  static let categoryPrefix = "CL_RULE_"
  static let logAction = "CL_LOG"
  static let snoozeAction = "CL_SNOOZE15"
  static let skipAction = "CL_SKIP"

  /// Sổ tiêm chủng (VX 8, P-133): Xem lịch tiêm · Nhắc lại sáng mai · Dời lịch.
  static let vaccineCategory = "CL_VACCINE"
  static let vaccineView = "VX_VIEW"
  static let vaccineSnooze = "VX_SNOOZE"
  static let vaccineMove = "VX_MOVE"

  /// "Ghi …" from a notification, for the app to pick up once Flutter runs.
  private static var launchAction: [String: Any]?

  private static var vietnamese: Bool {
    // The in-app language (G-081) wins over the device's.
    if let chosen = UserDefaults.standard.string(forKey: "flutter.app.locale") {
      return !chosen.hasPrefix("en")
    }
    return !(Locale.preferredLanguages.first ?? "vi").hasPrefix("en")
  }

  private static func logTitle(_ type: String, vi: Bool) -> String {
    switch type {
    case "SLEEP": return vi ? "Ghi giấc ngủ" : "Log sleep"
    case "DIAPER": return vi ? "Ghi thay tã" : "Log a change"
    case "PUMP": return vi ? "Ghi hút sữa" : "Log pumping"
    default: return vi ? "Ghi lần bú" : "Log a feed"
    }
  }

  /// Registers the four categories next to any others the app's plugins set.
  static func registerCategories() {
    let vi = vietnamese
    let ours = ["FEED", "SLEEP", "DIAPER", "PUMP"].map { type in
      UNNotificationCategory(
        identifier: categoryPrefix + type,
        actions: [
          UNNotificationAction(identifier: logAction, title: logTitle(type, vi: vi), options: [.foreground]),
          UNNotificationAction(
            identifier: snoozeAction, title: vi ? "Báo lại sau 15 phút" : "Remind me in 15 minutes", options: []),
          UNNotificationAction(
            identifier: skipAction, title: vi ? "Bỏ qua lần này" : "Skip this time", options: [.destructive]),
        ],
        intentIdentifiers: [],
        options: [])
    }
    let vaccine = UNNotificationCategory(
      identifier: vaccineCategory,
      actions: [
        UNNotificationAction(identifier: vaccineView, title: vi ? "Xem lịch tiêm" : "View the schedule", options: [.foreground]),
        UNNotificationAction(
          identifier: vaccineSnooze, title: vi ? "Nhắc lại sáng mai" : "Remind me in the morning", options: []),
        UNNotificationAction(identifier: vaccineMove, title: vi ? "Dời lịch" : "Reschedule", options: [.foreground]),
      ],
      intentIdentifiers: [],
      options: [])
    let center = UNUserNotificationCenter.current()
    center.getNotificationCategories { existing in
      let others = existing.filter {
        !$0.identifier.hasPrefix(categoryPrefix) && $0.identifier != vaccineCategory
      }
      center.setNotificationCategories(others.union(ours).union([vaccine]))
    }
  }

  /// Handles our actions; false = not ours (let the plugins have it).
  static func handle(_ response: UNNotificationResponse, completion: @escaping () -> Void) -> Bool {
    let content = response.notification.request.content
    if content.categoryIdentifier == vaccineCategory {
      return handleVaccine(response, completion: completion)
    }
    guard content.categoryIdentifier.hasPrefix(categoryPrefix) else { return false }
    let info = content.userInfo
    switch response.actionIdentifier {
    case snoozeAction, skipAction:
      Task {
        await answer(info, snooze: response.actionIdentifier == snoozeAction)
        completion()
      }
      return true
    case logAction:
      launchAction = [
        "action": "log",
        "babyId": info["babyId"] as? String ?? "",
        "ruleId": info["ruleId"] as? String ?? "",
        "type": info["type"] as? String ?? "",
      ]
      return false
    default:
      return false
    }
  }

  private static func handleVaccine(
    _ response: UNNotificationResponse, completion: @escaping () -> Void
  ) -> Bool {
    let info = response.notification.request.content.userInfo
    switch response.actionIdentifier {
    case vaccineSnooze:
      Task {
        if let babyId = info["babyId"] as? String, let date = info["date"] as? String {
          await callFunction("snoozeVaccine", ["babyId": babyId, "date": date])
        }
        completion()
      }
      return true
    case vaccineView, vaccineMove:
      launchAction = [
        "action": response.actionIdentifier == vaccineView ? "view" : "move",
        "babyId": info["babyId"] as? String ?? "",
      ]
      return false
    default:
      return false
    }
  }

  /// A callable Function from here, with the widgets' shared session (GlanceAuth).
  private static func callFunction(_ name: String, _ data: [String: Any]) async {
    guard let snapshot = GlanceSnapshot.load(),
      let token = try? await GlanceAuth.idToken(snapshot).token
    else { return }
    let region = "asia-southeast1"
    let base = snapshot.emulatorHost.map { "http://\($0):5001/\(snapshot.projectId)/\(region)" }
      ?? "https://\(region)-\(snapshot.projectId).cloudfunctions.net"
    guard let url = URL(string: "\(base)/\(name)") else { return }
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.httpBody = try? JSONSerialization.data(withJSONObject: ["data": data])
    req.timeoutInterval = 20
    _ = try? await URLSession.shared.data(for: req)
  }

  private static func answer(_ info: [AnyHashable: Any], snooze: Bool) async {
    guard let babyId = info["babyId"] as? String, let ruleId = info["ruleId"] as? String,
      let dueText = info["dueAt"] as? String, let dueAt = Int64(dueText),
      let snapshot = GlanceSnapshot.load()
    else { return }
    guard let token = try? await GlanceAuth.idToken(snapshot).token else { return }
    let region = "asia-southeast1"
    let base = snapshot.emulatorHost.map { "http://\($0):5001/\(snapshot.projectId)/\(region)" }
      ?? "https://\(region)-\(snapshot.projectId).cloudfunctions.net"
    guard let url = URL(string: "\(base)/answerRuleReminder") else { return }
    var data: [String: Any] = [
      "babyId": babyId, "ruleId": ruleId, "action": snooze ? "snooze" : "skip", "dueAt": dueAt,
    ]
    if snooze { data["minutes"] = 15 }
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.httpBody = try? JSONSerialization.data(withJSONObject: ["data": data])
    req.timeoutInterval = 20
    _ = try? await URLSession.shared.data(for: req)
  }

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "childlife/rules", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "takeLaunchAction":
        result(launchAction)
        launchAction = nil
      case "refreshCategories":
        registerCategories()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
