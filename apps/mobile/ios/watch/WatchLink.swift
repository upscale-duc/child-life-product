import Foundation
import WatchConnectivity

/// The watch's half of linking (G-092, P-142): the iPhone app sends the signed-in session (uid +
/// refresh token, as the widgets keep it) and its glance snapshot over WatchConnectivity. The
/// watch keeps the token in its own keychain and writes to Firestore by itself afterwards, so it
/// keeps working when the phone is out of reach.
final class WatchLink: NSObject, WCSessionDelegate {
  static let shared = WatchLink()
  static let changed = Notification.Name("WatchLink.changed")

  func activate() {
    guard WCSession.isSupported() else { return }
    WCSession.default.delegate = self
    WCSession.default.activate()
  }

  func session(
    _ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?
  ) {
    if activationState == .activated { apply(session.receivedApplicationContext) }
  }

  func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
    apply(applicationContext)
  }

  func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
    apply(userInfo)
  }

  private func apply(_ message: [String: Any]) {
    guard !message.isEmpty else { return }
    if message["signedOut"] as? Bool == true {
      WatchSync.signOut()
    } else {
      if let uid = message["uid"] as? String, let token = message["refreshToken"] as? String {
        let current = GlanceAuth.load()
        // Keep a still-valid ID token when the same person's session is sent again.
        if current?.uid != uid || current?.refreshToken != token {
          GlanceAuth.save(GlanceSession(uid: uid, refreshToken: token))
        }
      }
      if let data = message["snapshot"] as? Data { WatchSync.receive(data) }
    }
    DispatchQueue.main.async { NotificationCenter.default.post(name: Self.changed, object: nil) }
  }
}
