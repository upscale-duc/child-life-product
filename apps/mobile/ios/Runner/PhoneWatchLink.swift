import Foundation
import WatchConnectivity

/// The phone's half of the Apple Watch link (G-092, P-142): whenever the app hands the glance kit
/// a session or a snapshot, the same goes to the watch app as the application context (latest
/// wins, delivered when the watch next runs). The watch then logs to Firestore on its own.
final class PhoneWatchLink: NSObject, WCSessionDelegate {
  static let shared = PhoneWatchLink()

  func activate() {
    guard WCSession.isSupported() else { return }
    WCSession.default.delegate = self
    WCSession.default.activate()
  }

  /// Sends the current session (or "signed out") and snapshot. Without a paired watch with the
  /// app installed, WatchConnectivity refuses it and nothing happens.
  func push() {
    guard WCSession.isSupported() else { return }
    let session = WCSession.default
    guard session.activationState == .activated, session.isPaired else { return }
    var context: [String: Any] = ["sentAt": Date().timeIntervalSince1970]
    if let s = GlanceAuth.load() {
      context["uid"] = s.uid
      context["refreshToken"] = s.refreshToken
    } else {
      context["signedOut"] = true
    }
    if let data = Glance.defaults?.data(forKey: Glance.snapshotKey) { context["snapshot"] = data }
    try? session.updateApplicationContext(context)
  }

  func session(
    _ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?
  ) {
    push()
  }

  func sessionWatchStateDidChange(_ session: WCSession) { push() }

  func sessionDidBecomeInactive(_ session: WCSession) {}

  /// The user switched watches: talk to the new one.
  func sessionDidDeactivate(_ session: WCSession) { session.activate() }
}
