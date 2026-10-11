import Foundation

/// Firestore REST (`documents:commit`) with the same documents the app writes, so the same
/// Rules check them (records: validNewRecord / validRecordUpdate; timers: validNewTimer /
/// validTimerUpdate). `createdAt`/`updatedAt`/`deletedAt` use the REQUEST_TIME transform
/// because Rules require them to equal `request.time`.
enum FSValue {
  case string(String)
  case int(Int)
  case bool(Bool)
  case time(Date)
  case null
  case map([String: FSValue])
  case array([FSValue])

  var json: [String: Any] {
    switch self {
    case .string(let s): return ["stringValue": s]
    case .int(let i): return ["integerValue": String(i)]
    case .bool(let b): return ["booleanValue": b]
    case .time(let d): return ["timestampValue": FSValue.iso.string(from: d)]
    case .null: return ["nullValue": NSNull()]
    case .map(let m): return ["mapValue": ["fields": m.mapValues { $0.json }]]
    case .array(let a): return ["arrayValue": ["values": a.map { $0.json }]]
    }
  }

  static let iso: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return f
  }()
}

struct FSWrite {
  var json: [String: Any]

  /// Create (fails if it exists — a retry of a create that landed is then a success).
  static func create(_ path: String, _ fields: [String: FSValue], serverTime: [String]) -> FSWrite {
    FSWrite(json: [
      "update": ["name": path, "fields": fields.mapValues { $0.json }],
      "currentDocument": ["exists": false],
      "updateTransforms": serverTime.map { ["fieldPath": $0, "setToServerValue": "REQUEST_TIME"] },
    ])
  }

  static func patch(_ path: String, _ fields: [String: FSValue], serverTime: [String]) -> FSWrite {
    FSWrite(json: [
      "update": ["name": path, "fields": fields.mapValues { $0.json }],
      "updateMask": ["fieldPaths": Array(fields.keys)],
      "currentDocument": ["exists": true],
      "updateTransforms": serverTime.map { ["fieldPath": $0, "setToServerValue": "REQUEST_TIME"] },
    ])
  }

  static func delete(_ path: String) -> FSWrite { FSWrite(json: ["delete": path]) }
}

enum GlanceFirestore {
  enum Outcome { case done, offline, signedOut, rejected }

  static func root(_ s: GlanceSnapshot) -> String { "projects/\(s.projectId)/databases/(default)/documents" }

  private static func base(_ s: GlanceSnapshot) -> String {
    s.emulatorHost.map { "http://\($0):8080/v1" } ?? "https://firestore.googleapis.com/v1"
  }

  static func commitBody(_ s: GlanceSnapshot, _ writes: [FSWrite]) -> Data? {
    try? JSONSerialization.data(withJSONObject: ["writes": writes.map(\.json)])
  }

  /// Sends one commit. Offline → queued for later; a create that already exists counts as done.
  static func commit(_ s: GlanceSnapshot, _ writes: [FSWrite], queueIfOffline: Bool = true) async -> Outcome {
    guard let body = commitBody(s, writes) else { return .rejected }
    let outcome = await send(s, body)
    if outcome == .offline && queueIfOffline { GlancePending.add(body) }
    return outcome
  }

  static func send(_ s: GlanceSnapshot, _ body: Data) async -> Outcome {
    let token: String
    do { token = try await GlanceAuth.idToken(s).token } catch GlanceAuth.Failure.signedOut {
      return .signedOut
    } catch { return .offline }
    var req = URLRequest(url: URL(string: "\(base(s))/\(root(s)):commit")!)
    req.httpMethod = "POST"
    req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.httpBody = body
    req.timeoutInterval = 15
    guard let (data, response) = try? await URLSession.shared.data(for: req),
      let http = response as? HTTPURLResponse
    else { return .offline }
    switch http.statusCode {
    case 200: return .done
    case 401: return .signedOut
    case 409: return .done  // ALREADY_EXISTS: an earlier attempt landed.
    case 400 where String(data: data, encoding: .utf8)?.contains("FAILED_PRECONDITION") == true:
      return .done
    case 500...599: return .offline
    default: return .rejected
    }
  }

  /// Retries queued writes (oldest first); keeps what still cannot be sent.
  static func flushPending(_ s: GlanceSnapshot) async {
    var left: [Data] = []
    for body in GlancePending.all() {
      if !left.isEmpty { left.append(body); continue }
      let outcome = await send(s, body)
      if outcome == .offline { left.append(body) }
    }
    GlancePending.replace(left)
  }

  /// The live timer document, if any (another device may have changed or ended it).
  static func timer(_ s: GlanceSnapshot, babyId: String, type: String) async -> [String: Any]?? {
    guard let token = try? await GlanceAuth.idToken(s).token else { return .none }
    var req = URLRequest(url: URL(string: "\(base(s))/\(root(s))/babies/\(babyId)/timers/\(type)")!)
    req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    req.timeoutInterval = 10
    guard let (data, response) = try? await URLSession.shared.data(for: req),
      let http = response as? HTTPURLResponse
    else { return .none }
    if http.statusCode == 404 { return .some(nil) }
    guard http.statusCode == 200, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { return .none }
    return .some(json["fields"] as? [String: Any])
  }

  // MARK: Reading REST values

  static func date(_ v: Any?) -> Date? {
    guard let m = v as? [String: Any], let s = m["timestampValue"] as? String else { return nil }
    return iso(s)
  }

  static func iso(_ s: String) -> Date? {
    FSValue.iso.date(from: s) ?? ISO8601DateFormatter().date(from: s)
  }

  static func side(_ v: Any?) -> GlanceSide? {
    guard let m = (v as? [String: Any])?["mapValue"] as? [String: Any],
      let f = m["fields"] as? [String: Any]
    else { return nil }
    let acc = Int(((f["accumulatedMs"] as? [String: Any])?["integerValue"] as? String) ?? "0") ?? 0
    return GlanceSide(accumulatedMs: acc, runningSince: date(f["runningSince"]))
  }
}
