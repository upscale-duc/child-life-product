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

  /// Cùng Chăm Con N1 (Figma 1353:22588): Xong · Nhắc lại 10 phút. `CL_CARE_TASK_APP` opens the
  /// app for "Xong" (a log to write or the sleep timer, D-138); `CL_CARE_TASK` marks it done here.
  static let careTaskCategory = "CL_CARE_TASK"
  static let careTaskAppCategory = "CL_CARE_TASK_APP"
  static let careTaskDone = "CT_DONE"
  static let careTaskSnooze = "CT_SNOOZE10"
  /// N2 "Teddy no bụng rồi, nhờ có Mẹ đó!": Thả tim, sent from here without opening the app.
  static let careDoneCategory = "CL_CARE_DONE"
  static let careDoneHeart = "CD_HEART"
  /// A snoozed task push comes back as a local notification with this id prefix.
  static let careTaskSnoozePrefix = "ctsnooze."

  /// L6 "Bé dậy chưa?" (lumi-plan §7.1), a local notification of the app (wake_check.dart):
  /// Dậy rồi · Dậy lúc… open the app on the sleep timer, handed over by `takeWakeAction`;
  /// Vẫn ngủ goes to the plugin's background handler, which asks once more. The second ask
  /// (`_LAST`) has no Vẫn ngủ. Registered here because the plugin would replace these categories.
  static let wakeCheckCategory = "CL_WAKE_CHECK"
  static let wakeCheckLastCategory = "CL_WAKE_CHECK_LAST"
  static let wakeUp = "WC_UP"
  static let wakePick = "WC_AT"
  static let wakeAgain = "WC_AGAIN"
  private static var wakeAction: [String: Any]?

  /// "Ghi …" from a notification, for the app to pick up once Flutter runs.
  private static var launchAction: [String: Any]?

  /// The server push that was tapped (its data, strings only), for the app to take: a cold start
  /// runs Dart long after iOS hands over the tap, and the messaging plugin's own "opened" event
  /// is lost when nothing listens yet. Taken once by `takeTappedPush`.
  private static var tappedPush: [String: String]?
  private static var lastTapId: String?
  private static var channel: FlutterMethodChannel?

  /// Keeps a tapped server push (not a dismissal, not a local notification) and tells Flutter.
  static func recordTap(_ response: UNNotificationResponse) {
    let request = response.notification.request
    guard request.trigger is UNPushNotificationTrigger || request.identifier.hasPrefix(careTaskSnoozePrefix),
      response.actionIdentifier != UNNotificationDismissActionIdentifier
    else { return }
    // The same tap is never opened twice.
    let id = response.notification.request.identifier
    if id == lastTapId { return }
    lastTapId = id
    var data: [String: String] = [:]
    for (key, value) in response.notification.request.content.userInfo {
      if let key = key as? String, key != "aps", let value = value as? String { data[key] = value }
    }
    tappedPush = data
    channel?.invokeMethod("tapped", arguments: nil)
  }

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
    let snooze = UNNotificationAction(
      identifier: careTaskSnooze, title: vi ? "Nhắc lại 10 phút" : "Remind me in 10 min", options: [])
    let careTasks: Set<UNNotificationCategory> = [
      UNNotificationCategory(
        identifier: careTaskCategory,
        actions: [UNNotificationAction(identifier: careTaskDone, title: vi ? "Xong" : "Done", options: []), snooze],
        intentIdentifiers: [], options: []),
      UNNotificationCategory(
        identifier: careTaskAppCategory,
        actions: [
          UNNotificationAction(identifier: careTaskDone, title: vi ? "Xong" : "Done", options: [.foreground]), snooze,
        ],
        intentIdentifiers: [], options: []),
      UNNotificationCategory(
        identifier: careDoneCategory,
        actions: [UNNotificationAction(identifier: careDoneHeart, title: vi ? "Thả tim" : "Send a heart", options: [])],
        intentIdentifiers: [], options: []),
    ]
    let up = UNNotificationAction(identifier: wakeUp, title: vi ? "Dậy rồi" : "Awake now", options: [.foreground])
    let pick = UNNotificationAction(identifier: wakePick, title: vi ? "Dậy lúc…" : "Woke at…", options: [.foreground])
    let again = UNNotificationAction(identifier: wakeAgain, title: vi ? "Vẫn ngủ" : "Still asleep", options: [])
    let wakeChecks: Set<UNNotificationCategory> = [
      UNNotificationCategory(
        identifier: wakeCheckCategory, actions: [up, pick, again], intentIdentifiers: [], options: []),
      UNNotificationCategory(
        identifier: wakeCheckLastCategory, actions: [up, pick], intentIdentifiers: [], options: []),
    ]
    let center = UNUserNotificationCenter.current()
    center.getNotificationCategories { existing in
      let others = existing.filter {
        !$0.identifier.hasPrefix(categoryPrefix) && $0.identifier != vaccineCategory
          && $0.identifier != careTaskCategory && $0.identifier != careTaskAppCategory
          && $0.identifier != careDoneCategory && $0.identifier != wakeCheckCategory
          && $0.identifier != wakeCheckLastCategory
      }
      center.setNotificationCategories(
        others.union(ours).union([vaccine]).union(careTasks).union(wakeChecks))
    }
  }

  /// Handles our actions; false = not ours (let the plugins have it).
  static func handle(_ response: UNNotificationResponse, completion: @escaping () -> Void) -> Bool {
    let content = response.notification.request.content
    if (content.categoryIdentifier == wakeCheckCategory || content.categoryIdentifier == wakeCheckLastCategory)
      && (response.actionIdentifier == wakeUp || response.actionIdentifier == wakePick)
    {
      // When it was tapped: "Dậy rồi" ends the sleep then, not when the app is ready.
      wakeAction = [
        "action": response.actionIdentifier,
        "payload": content.userInfo["payload"] as? String ?? "",
        "at": Int(Date().timeIntervalSince1970 * 1000),
      ]
      channel?.invokeMethod("wakeAction", arguments: nil)
      completion()
      return true
    }
    if content.categoryIdentifier == vaccineCategory {
      return handleVaccine(response, completion: completion)
    }
    if content.categoryIdentifier == careTaskCategory || content.categoryIdentifier == careTaskAppCategory {
      return handleCareTask(response, completion: completion)
    }
    if content.categoryIdentifier == careDoneCategory && response.actionIdentifier == careDoneHeart {
      let info = content.userInfo
      Task {
        if let babyId = info["babyId"] as? String, let date = info["date"] as? String,
          let item = info["item"] as? String
        {
          await callFunction(
            "reactCarePlanItem",
            ["babyId": babyId, "date": date, "itemId": item, "heart": true, "thanks": NSNull()])
        }
        completion()
      }
      return true
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

  private static func handleCareTask(
    _ response: UNNotificationResponse, completion: @escaping () -> Void
  ) -> Bool {
    let content = response.notification.request.content
    let info = content.userInfo
    switch response.actionIdentifier {
    case careTaskSnooze:
      // Comes back in 10 minutes as the same notice, with the same buttons.
      let again = content.mutableCopy() as! UNMutableNotificationContent
      let request = UNNotificationRequest(
        identifier: careTaskSnoozePrefix + UUID().uuidString, content: again,
        trigger: UNTimeIntervalNotificationTrigger(timeInterval: 600, repeats: false))
      UNUserNotificationCenter.current().add(request) { _ in completion() }
      return true
    case careTaskDone where content.categoryIdentifier == careTaskCategory:
      // Nothing to write: done from the lock screen, as the one who tapped it.
      Task {
        if let babyId = info["babyId"] as? String, let date = info["date"] as? String,
          let items = info["items"] as? String
        {
          for itemId in items.split(separator: ",") {
            await callFunction(
              "setCarePlanItemStatus",
              ["babyId": babyId, "date": date, "itemId": String(itemId), "status": "done"])
          }
        }
        completion()
      }
      return true
    case careTaskDone:
      // The app opens on the log (or the sleep timer) of those tasks.
      launchAction = ["action": "done", "babyId": info["babyId"] as? String ?? ""]
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
    self.channel = channel
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "takeLaunchAction":
        result(launchAction)
        launchAction = nil
      case "takeWakeAction":
        result(wakeAction)
        wakeAction = nil
      case "takeTappedPush":
        result(tappedPush)
        tappedPush = nil
      case "refreshCategories":
        registerCategories()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
