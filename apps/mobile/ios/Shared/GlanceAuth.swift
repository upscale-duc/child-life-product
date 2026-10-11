import Foundation
import Security

/// The signed-in account, shared with the extensions through a keychain access group so a widget
/// or Live Activity button can write as that person without opening the app (S8, W5). The app
/// stores it on sign-in and removes it on sign-out; the item is readable after the first unlock
/// (lock-screen widgets) and never leaves the device.
struct GlanceSession: Codable {
  var uid: String
  var refreshToken: String
  var idToken: String?
  var expiresAt: Date?
}

enum GlanceAuth {
  private static let service = "app.childlife.glance"
  private static let account = "session"

  /// `$(AppIdentifierPrefix)<bundle>.shared` from Info.plist (`CLKeychainGroup`).
  private static var group: String? { Bundle.main.object(forInfoDictionaryKey: "CLKeychainGroup") as? String }

  private static func query() -> [String: Any] {
    var q: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
    if let group { q[kSecAttrAccessGroup as String] = group }
    return q
  }

  static func load() -> GlanceSession? {
    var q = query()
    q[kSecReturnData as String] = true
    q[kSecMatchLimit as String] = kSecMatchLimitOne
    var out: AnyObject?
    guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess, let data = out as? Data
    else { return nil }
    return try? GlanceCoding.decoder.decode(GlanceSession.self, from: data)
  }

  static func save(_ session: GlanceSession) {
    guard let data = try? GlanceCoding.encoder.encode(session) else { return }
    let attrs: [String: Any] = [
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
    ]
    if SecItemUpdate(query() as CFDictionary, attrs as CFDictionary) == errSecItemNotFound {
      var add = query()
      add.merge(attrs) { $1 }
      SecItemAdd(add as CFDictionary, nil)
    }
  }

  static func clear() { SecItemDelete(query() as CFDictionary) }

  enum Failure: Error { case signedOut, network, rejected }

  /// A Firebase ID token for REST calls, refreshed with the shared refresh token when needed.
  static func idToken(_ snapshot: GlanceSnapshot) async throws -> (uid: String, token: String) {
    guard var session = load() else { throw Failure.signedOut }
    if let token = session.idToken, let exp = session.expiresAt, exp > Date().addingTimeInterval(120) {
      return (session.uid, token)
    }
    let base = snapshot.emulatorHost.map { "http://\($0):9099/securetoken.googleapis.com" }
      ?? "https://securetoken.googleapis.com"
    var req = URLRequest(url: URL(string: "\(base)/v1/token?key=\(snapshot.apiKey)")!)
    req.httpMethod = "POST"
    req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    let body = "grant_type=refresh_token&refresh_token=\(session.refreshToken.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "")"
    req.httpBody = body.data(using: .utf8)
    req.timeoutInterval = 15
    let (data, response): (Data, URLResponse)
    do { (data, response) = try await URLSession.shared.data(for: req) } catch { throw Failure.network }
    guard let http = response as? HTTPURLResponse else { throw Failure.network }
    if http.statusCode == 400 || http.statusCode == 401 || http.statusCode == 403 {
      // Revoked / signed out elsewhere: the widget shows "Đăng nhập để dùng widget".
      clear()
      throw Failure.signedOut
    }
    guard http.statusCode == 200,
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let token = json["id_token"] as? String
    else { throw Failure.network }
    let ttl = Double((json["expires_in"] as? String) ?? "3600") ?? 3600
    session.idToken = token
    session.expiresAt = Date().addingTimeInterval(ttl)
    if let refreshed = json["refresh_token"] as? String { session.refreshToken = refreshed }
    save(session)
    return (session.uid, token)
  }
}
