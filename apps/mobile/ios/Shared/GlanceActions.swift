import Foundation

#if canImport(WidgetKit)
import WidgetKit
#endif

/// One-tap care actions from widgets and Live Activities (W5 "chạy ngầm"): the same documents
/// the app writes (CareRecord.toCreateJson, CareTimer.toJson / toRecord), the snapshot patched
/// first so the widget answers at once, Firestore after. Offline writes wait in the App Group.
enum GlanceActions {
  enum Result { case done, signedOut, notAllowed, nothing }

  static func newHex() -> String { UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased() }

  private static func author(_ a: GlanceAuthor) -> FSValue {
    .map([
      "name": .string(a.name),
      "relation": .string(a.relation),
      "relationCustom": a.relationCustom.map(FSValue.string) ?? .null,
    ])
  }

  private static func ready() -> (GlanceSnapshot, String, String, GlanceAuthor)? {
    guard let s = GlanceSnapshot.load(), s.signedIn, s.canLog, let babyId = s.babyId,
      let uid = s.uid, let author = s.author
    else { return nil }
    return (s, babyId, uid, author)
  }

  private static func recordWrite(
    _ s: GlanceSnapshot, babyId: String, uid: String, author a: GlanceAuthor, id: String,
    type: String, occurredAt: Date, endedAt: Date?, data: [String: FSValue], now: Date
  ) -> FSWrite {
    .create(
      "\(GlanceFirestore.root(s))/babies/\(babyId)/records/\(id)",
      [
        "id": .string(id),
        "babyId": .string(babyId),
        "type": .string(type),
        "occurredAt": .time(occurredAt),
        "endedAt": endedAt.map(FSValue.time) ?? .null,
        "data": .map(data),
        "createdBy": .string(uid),
        "author": author(a),
        "clientCreatedAt": .time(now),
        "updatedBy": .string(uid),
        "deleted": .bool(false),
        "deletedAt": .null,
        "deletedBy": .null,
        "source": .string("app"),
      ],
      serverTime: ["createdAt", "updatedAt"])
  }

  private static func finish(_ outcome: GlanceFirestore.Outcome) -> Result {
    reload()
    switch outcome {
    case .signedOut: return .signedOut
    case .rejected: return .notAllowed
    default: return .done
    }
  }

  static func reload() {
    #if canImport(WidgetKit)
    WidgetCenter.shared.reloadAllTimelines()
    #endif
  }

  // MARK: One-tap logs (Hoàn tác ~5 s)

  /// Small Bottle "+ 120 ml" / Medium "Bú bình": the last amount and milk again.
  static func logBottle() async -> Result {
    guard let (s, babyId, uid, a) = ready() else { return .signedOut }
    let now = Date()
    let id = "r_\(newHex())"
    let amount = s.lastBottle?.amountMl
    let milk = s.lastBottle?.milk ?? "formula"
    GlanceSnapshot.update { snap in
      let previous = snap.lastBottle
      snap.lastBottle = GlanceLast(at: now, by: snap.text("you", "Bạn"), amountMl: amount, milk: milk)
      snap.bottlesToday += 1
      snap.feedsToday += 1
      snap.bottleMlToday += amount ?? 0
      let label = amount.map { snap.text("loggedBottle", ["ml": "\($0)"]) } ?? snap.text("bottle", "Bú bình")
      snap.logged = GlanceLogged(recordId: id, type: "bottle", label: label, at: now, previous: previous)
    }
    reload()
    let write = recordWrite(
      s, babyId: babyId, uid: uid, author: a, id: id, type: "bottle", occurredAt: now, endedAt: nil,
      data: ["amountMl": amount.map(FSValue.int) ?? .null, "milk": .string(milk)], now: now)
    return finish(await GlanceFirestore.commit(s, [write]))
  }

  /// Small Diaper "Ướt / Bẩn / Cả hai", Medium "Thay tã" (= Ướt).
  static func logDiaper(_ kind: String) async -> Result {
    guard let (s, babyId, uid, a) = ready() else { return .signedOut }
    let now = Date()
    let id = "r_\(newHex())"
    GlanceSnapshot.update { snap in
      let previous = snap.lastDiaper
      snap.lastDiaper = GlanceLast(at: now, by: snap.text("you", "Bạn"), kind: kind)
      snap.diapersToday += 1
      snap.logged = GlanceLogged(
        recordId: id, type: "diaper", label: snap.text("loggedDiaper", ["kind": snap.text("diaper.\(kind)", kind)]),
        at: now, previous: previous)
    }
    reload()
    let write = recordWrite(
      s, babyId: babyId, uid: uid, author: a, id: id, type: "diaper", occurredAt: now, endedAt: nil,
      data: ["kind": .string(kind)], now: now)
    return finish(await GlanceFirestore.commit(s, [write]))
  }

  /// "Hoàn tác": the soft delete the app's Undo does (validRecordUpdate).
  static func undo(_ recordId: String) async -> Result {
    guard let (s, babyId, uid, _) = ready() else { return .signedOut }
    GlanceSnapshot.update { snap in
      guard let logged = snap.logged, logged.recordId == recordId else { return }
      switch logged.type {
      case "bottle":
        snap.lastBottle = logged.previous
        snap.bottlesToday = max(0, snap.bottlesToday - 1)
        snap.feedsToday = max(0, snap.feedsToday - 1)
      case "diaper":
        snap.lastDiaper = logged.previous
        snap.diapersToday = max(0, snap.diapersToday - 1)
      default: break
      }
      snap.logged = nil
    }
    reload()
    let write = FSWrite.patch(
      "\(GlanceFirestore.root(s))/babies/\(babyId)/records/\(recordId)",
      ["deleted": .bool(true), "deletedBy": .string(uid), "updatedBy": .string(uid)],
      serverTime: ["deletedAt", "updatedAt"])
    return finish(await GlanceFirestore.commit(s, [write]))
  }

  // MARK: Timers (Bắt đầu ngủ / Thức dậy, Bắt đầu bú / Đổi bên / Xong)

  static func start(_ type: String, side: String = "left") async -> Result {
    guard let (s, babyId, uid, a) = ready() else { return .signedOut }
    if (type == "sleep" ? s.sleep : s.breast) != nil { return .nothing }
    let now = Date()
    let session = newHex()
    let left = GlanceSide(accumulatedMs: 0, runningSince: side == "left" ? now : nil)
    let right = GlanceSide(accumulatedMs: 0, runningSince: side == "right" ? now : nil)
    let timer = GlanceTimer(
      type: type, sessionId: session, startedAt: now, startedBy: uid, byName: s.text("you", "Bạn"),
      left: type == "sleep" ? nil : left, right: type == "sleep" ? nil : right, paused: false)
    GlanceSnapshot.update { snap in
      if type == "sleep" { snap.sleep = timer } else { snap.breast = timer }
    }
    reload()
    let write = FSWrite.create(
      "\(GlanceFirestore.root(s))/babies/\(babyId)/timers/\(type)",
      [
        "type": .string(type),
        "babyId": .string(babyId),
        "sessionId": .string(session),
        "startedAt": .time(now),
        "startedBy": .string(uid),
        "author": author(a),
        "sides": type == "sleep" ? .null : sides(left, right),
        "paused": .bool(false),
        "pausedSides": .array([]),
        "updatedBy": .string(uid),
      ],
      serverTime: ["updatedAt"])
    let outcome = await GlanceFirestore.commit(s, [write])
    await GlanceLive.sync()
    return finish(outcome)
  }

  private static func sides(_ l: GlanceSide, _ r: GlanceSide) -> FSValue {
    func one(_ x: GlanceSide) -> FSValue {
      .map(["accumulatedMs": .int(x.accumulatedMs), "runningSince": x.runningSince.map(FSValue.time) ?? .null])
    }
    return .map(["left": one(l), "right": one(r)])
  }

  /// The timer as it is now on the server (another device may have switched or ended it);
  /// falls back to the snapshot when offline.
  private static func current(_ s: GlanceSnapshot, _ babyId: String, _ type: String) async -> GlanceTimer?? {
    let local = type == "sleep" ? s.sleep : s.breast
    guard let remote = await GlanceFirestore.timer(s, babyId: babyId, type: type) else { return .some(local) }
    guard let f = remote else { return .some(nil) }
    func str(_ k: String) -> String? { (f[k] as? [String: Any])?["stringValue"] as? String }
    let sides = ((f["sides"] as? [String: Any])?["mapValue"] as? [String: Any])?["fields"] as? [String: Any]
    guard let session = str("sessionId"), let startedAt = GlanceFirestore.date(f["startedAt"]) else {
      return .some(local)
    }
    let paused = ((f["paused"] as? [String: Any])?["booleanValue"] as? Bool) ?? false
    return .some(
      GlanceTimer(
        type: type, sessionId: session, startedAt: startedAt, startedBy: str("startedBy") ?? "",
        byName: local?.byName ?? "", left: GlanceFirestore.side(sides?["left"]),
        right: GlanceFirestore.side(sides?["right"]), paused: paused))
  }

  /// "Thức dậy" (sleep) / "Xong" · "Kết thúc" (breast): the session's record `r_<sessionId>` and
  /// the timer's end in one commit, like CareRepository.endTimer.
  static func end(_ type: String) async -> Result {
    guard let (s, babyId, uid, a) = ready() else { return .signedOut }
    guard let found = await current(s, babyId, type), let t = found else {
      GlanceSnapshot.update { snap in if type == "sleep" { snap.sleep = nil } else { snap.breast = nil } }
      await GlanceLive.sync()
      reload()
      return .nothing
    }
    let now = Date()
    let record: FSWrite
    if type == "sleep" {
      let end = min(now, t.startedAt.addingTimeInterval(24 * 3600))
      record = recordWrite(
        s, babyId: babyId, uid: uid, author: a, id: "r_\(t.sessionId)", type: "sleep",
        occurredAt: t.startedAt, endedAt: end, data: [:], now: now)
      GlanceSnapshot.update { snap in
        snap.sleep = nil
        snap.lastWokeAt = now
        snap.lastSleepMin = Int((end.timeIntervalSince(t.startedAt) / 60).rounded())
        snap.sleptTodayMin += snap.lastSleepMin ?? 0
      }
    } else {
      let leftS = t.left?.elapsed(at: now) ?? 0
      let rightS = t.right?.elapsed(at: now) ?? 0
      let minutes = min(240, max(1, Int(((leftS + rightS) / 60).rounded())))
      let side = leftS > 0 && rightS > 0 ? "both" : rightS > 0 ? "right" : "left"
      var data: [String: FSValue] = [
        "side": .string(side),
        "durationMin": .int(minutes),
        "leftMin": .int(Int((leftS / 60).rounded())),
        "rightMin": .int(Int((rightS / 60).rounded())),
      ]
      if let endSide = t.activeSide { data["endSide"] = .string(endSide) }
      record = recordWrite(
        s, babyId: babyId, uid: uid, author: a, id: "r_\(t.sessionId)", type: "breast",
        occurredAt: t.startedAt, endedAt: t.startedAt.addingTimeInterval(Double(minutes) * 60),
        data: data, now: now)
      GlanceSnapshot.update { snap in
        snap.breast = nil
        snap.lastBreast = GlanceLast(at: now, by: snap.text("you", "Bạn"), side: side, durationMin: minutes)
        snap.breastsToday += 1
        snap.feedsToday += 1
      }
    }
    reload()
    let outcome = await GlanceFirestore.commit(
      s, [record, .delete("\(GlanceFirestore.root(s))/babies/\(babyId)/timers/\(type)")])
    await GlanceLive.sync()
    return finish(outcome)
  }

  /// "Đổi bên": stop the running side, start the other (CareTimer.switchTo).
  static func switchSide() async -> Result {
    guard let (s, babyId, uid, _) = ready() else { return .signedOut }
    guard let found = await current(s, babyId, "breast"), var t = found else { return .nothing }
    let now = Date()
    let next = t.activeSide == "left" ? "right" : "left"
    func stop(_ x: GlanceSide?) -> GlanceSide {
      let x = x ?? GlanceSide(accumulatedMs: 0, runningSince: nil)
      return GlanceSide(accumulatedMs: Int(x.elapsed(at: now) * 1000), runningSince: nil)
    }
    func run(_ x: GlanceSide?) -> GlanceSide {
      let x = x ?? GlanceSide(accumulatedMs: 0, runningSince: nil)
      return x.runningSince == nil ? GlanceSide(accumulatedMs: x.accumulatedMs, runningSince: now) : x
    }
    t.left = next == "left" ? run(t.left) : stop(t.left)
    t.right = next == "right" ? run(t.right) : stop(t.right)
    t.paused = false
    let updated = t
    GlanceSnapshot.update { $0.breast = updated }
    reload()
    let write = FSWrite.patch(
      "\(GlanceFirestore.root(s))/babies/\(babyId)/timers/breast",
      [
        "sides": sides(t.left!, t.right!),
        "paused": .bool(false),
        "pausedSides": .array([]),
        "updatedBy": .string(uid),
      ],
      serverTime: ["updatedAt"])
    let outcome = await GlanceFirestore.commit(s, [write])
    await GlanceLive.sync()
    return finish(outcome)
  }
}
