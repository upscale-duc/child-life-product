import Flutter
import Foundation
import Network
import UIKit
import UserNotifications

#if canImport(ActivityKit)
import ActivityKit
#endif

/// 10j "Khoá máy · tải nền & báo xong": memory uploads keep going while the phone is locked or
/// the app is closed. Each file goes to Firebase Storage with the resumable protocol: a small
/// "start" request (with the person's ID token) returns an upload URL, and a background
/// URLSession sends the file there with "upload, finalize" — iOS carries on with it after the app
/// is suspended or killed, and wakes the app when it is done.
///
/// The Dart queue (lib/features/memories/upload_queue.dart) stays the owner of the items: it
/// hands files over here, and asks for each file's outcome before sending it again, so a file
/// that finished while the app was gone is never uploaded twice. Outcomes are kept (by storage
/// path) until Dart forgets them. Nothing about the child is logged; the lock screen shows counts
/// and the baby's nickname only, never a photo.
final class BackgroundUploads: NSObject, URLSessionDataDelegate {
  static let shared = BackgroundUploads()

  struct Job: Codable {
    var path: String
    var state: String  // running · done · failed
    var sent: Int64
    var total: Int64
    var code: String?
    var babyId: String
    var video: Bool
    var wifiOnly: Bool
    var updated: Date

    var counts: Bool { !path.hasSuffix(".poster") }
    var json: [String: Any] {
      ["state": state, "sent": sent, "total": total, "code": code ?? NSNull()]
    }
  }

  /// One "run": from the first file handed over until nothing is left running.
  struct Run: Codable {
    var total = 0
    var done = 0
    var failed = 0
    var babyId: String?
    /// What Dart says the whole lô is (files still being prepared included), so "2/69" reads
    /// right from the first file; `total` only counts files handed over so far.
    var expected: Int?

    var shown: Int { max(total, expected ?? 0) }
  }

  private static var identifier: String { (Bundle.main.bundleIdentifier ?? "app.childlife") + ".uploads" }
  private let jobsKey = "uploads.jobs"
  private let runKey = "uploads.run"
  private let lock = NSLock()
  private var jobs: [String: Job] = [:]
  private var run = Run()
  private var lastEmit: [String: Date] = [:]
  private var lastActivity = Date.distantPast
  private let path = NWPathMonitor()
  private var onWifi = true

  /// Set by AppDelegate when iOS relaunches the app for this session's events.
  var backgroundCompletion: (() -> Void)?
  /// Progress and outcomes for Dart (on the main thread).
  var emit: (([String: Any]) -> Void)?

  private lazy var session: URLSession = {
    let c = URLSessionConfiguration.background(withIdentifier: Self.identifier)
    c.sessionSendsLaunchEvents = true
    c.isDiscretionary = false
    // One file at a time, in order ("Đang tải 4/7"), each with its full bandwidth; and a patient
    // wait for Storage's answer after the last byte, so iOS never resends a finished upload
    // (a resent "finalize" is refused and the file would look failed).
    c.httpMaximumConnectionsPerHost = 1
    c.timeoutIntervalForRequest = 300
    let q = OperationQueue()
    q.maxConcurrentOperationCount = 1
    return URLSession(configuration: c, delegate: self, delegateQueue: q)
  }()

  private override init() {
    super.init()
    let d = UserDefaults.standard
    if let data = d.data(forKey: jobsKey), let saved = try? JSONDecoder().decode([String: Job].self, from: data) {
      // Outcomes Dart never collected (the batch was removed meanwhile) are not kept forever.
      let week = Date().addingTimeInterval(-7 * 86_400)
      jobs = saved.filter { $0.value.state == "running" || $0.value.updated > week }
    }
    if let data = d.data(forKey: runKey), let saved = try? JSONDecoder().decode(Run.self, from: data) { run = saved }
    path.pathUpdateHandler = { [weak self] p in self?.onWifi = p.usesInterfaceType(.wifi) || p.usesInterfaceType(.wiredEthernet) }
    path.start(queue: DispatchQueue(label: "uploads.path"))
    NotificationCenter.default.addObserver(
      self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
  }

  private var reconciled = false

  /// Reconnects to the background session so outcomes from while the app was gone arrive, and
  /// checks once that every job still "running" has a task behind it.
  func resume() {
    let s = session
    guard !reconciled else { return }
    reconciled = true
    s.getAllTasks { [weak self] tasks in self?.reconcile(with: tasks) }
  }

  /// A job the session no longer knows (iOS dropped it after a force quit, a reboot, or a
  /// purge) would otherwise stay "running" forever, and the Dart queue would wait on it just as
  /// long — the item sat at "Đang tải" while the lock screen had moved on. Such jobs become
  /// `failed` / `lost`, which the queue sends afresh. Jobs started in the last seconds are left
  /// alone: their task may not be registered yet.
  private func reconcile(with tasks: [URLSessionTask]) {
    let live = Set(tasks.compactMap { $0.taskDescription })
    let cutoff = Date().addingTimeInterval(-10)
    var lost: [String] = []
    lock.lock()
    for (path, job) in jobs where job.state == "running" && !live.contains(path) && job.updated < cutoff {
      var j = job
      j.state = "failed"
      j.code = "lost"
      j.updated = Date()
      jobs[path] = j
      if j.counts { run.failed += 1 }
      lost.append(path)
    }
    let idle = !lost.isEmpty && !jobs.values.contains(where: { $0.state == "running" })
    if idle { run = Run() }
    if !lost.isEmpty { save() }
    lock.unlock()
    for path in lost { send(["event": "failed", "path": path, "code": "lost"]) }
    if !lost.isEmpty { Task { await updateActivity(force: true) } }
  }

  // MARK: Dart channel

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "childlife/uploads", binaryMessenger: messenger)
    let me = BackgroundUploads.shared
    me.emit = { event in channel.invokeMethod("event", arguments: event) }
    me.resume()
    channel.setMethodCallHandler { call, result in
      let args = call.arguments as? [String: Any] ?? [:]
      switch call.method {
      case "start":
        Task {
          let out = await me.start(args)
          DispatchQueue.main.async { result(out) }
        }
      case "status":
        result(me.status(args["path"] as? String ?? ""))
      case "forget":
        me.forget(args["path"] as? String ?? "")
        result(nil)
      case "cancel":
        me.cancel(args["path"] as? String ?? "")
        result(nil)
      case "cancelAll":
        me.cancelAll()
        result(nil)
      case "expect":
        me.expect(args["babyId"] as? String ?? "", count: args["count"] as? Int ?? 0)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  func status(_ path: String) -> [String: Any]? {
    lock.lock()
    defer { lock.unlock() }
    return jobs[path]?.json
  }

  func forget(_ path: String) {
    lock.lock()
    if jobs[path]?.state != "running" { jobs[path] = nil }
    save()
    lock.unlock()
  }

  /// Hands a file over. A file already running or finished is not sent again.
  func start(_ a: [String: Any]) async -> [String: Any] {
    guard let path = a["path"] as? String, let file = a["file"] as? String,
      let contentType = a["contentType"] as? String, let token = a["token"] as? String,
      let bucket = a["bucket"] as? String, let babyId = a["babyId"] as? String
    else { return ["state": "failed", "code": "bad-request"] }
    let wifiOnly = a["wifiOnly"] as? Bool ?? false
    lock.lock()
    if let existing = jobs[path], existing.state != "failed" {
      lock.unlock()
      return existing.json
    }
    lock.unlock()
    guard let size = (try? FileManager.default.attributesOfItem(atPath: file))?[.size] as? NSNumber else {
      return ["state": "failed", "code": "file-missing"]
    }

    // 1. Start a resumable upload (needs the network now; the bytes can wait).
    let host = (a["host"] as? String).map { "http://\($0):9199" } ?? "https://firebasestorage.googleapis.com"
    var comps = URLComponents(string: "\(host)/v0/b/\(bucket)/o")!
    comps.queryItems = [URLQueryItem(name: "name", value: path)]
    var req = URLRequest(url: comps.url!)
    req.httpMethod = "POST"
    req.setValue("Firebase \(token)", forHTTPHeaderField: "Authorization")
    req.setValue("resumable", forHTTPHeaderField: "X-Goog-Upload-Protocol")
    req.setValue("start", forHTTPHeaderField: "X-Goog-Upload-Command")
    req.setValue("\(size.int64Value)", forHTTPHeaderField: "X-Goog-Upload-Header-Content-Length")
    req.setValue(contentType, forHTTPHeaderField: "X-Goog-Upload-Header-Content-Type")
    req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    req.httpBody = try? JSONSerialization.data(withJSONObject: ["name": path, "contentType": contentType])
    let uploadURL: URL
    do {
      let (_, response) = try await URLSession.shared.data(for: req)
      let http = response as? HTTPURLResponse
      guard let http, (200..<300).contains(http.statusCode) else {
        return ["state": "failed", "code": Self.code(http?.statusCode)]
      }
      guard let link = http.value(forHTTPHeaderField: "X-Goog-Upload-URL"), let url = URL(string: link) else {
        return ["state": "failed", "code": "no-upload-url"]
      }
      uploadURL = url
    } catch {
      return ["state": "failed", "code": "network"]
    }

    // 2. The bytes, from the file, in the background session.
    var up = URLRequest(url: uploadURL)
    up.httpMethod = "POST"
    up.setValue("Firebase \(token)", forHTTPHeaderField: "Authorization")
    up.setValue("upload, finalize", forHTTPHeaderField: "X-Goog-Upload-Command")
    up.setValue("0", forHTTPHeaderField: "X-Goog-Upload-Offset")
    up.setValue(contentType, forHTTPHeaderField: "Content-Type")
    // "Video chỉ tải qua Wi-Fi" (D-033): iOS holds the video until Wi-Fi, even with the app closed.
    up.allowsCellularAccess = !wifiOnly
    up.allowsExpensiveNetworkAccess = !wifiOnly
    let task = session.uploadTask(with: up, fromFile: URL(fileURLWithPath: file))
    task.taskDescription = path

    let job = Job(
      path: path, state: "running", sent: 0, total: size.int64Value, code: nil, babyId: babyId,
      video: a["video"] as? Bool ?? false, wifiOnly: wifiOnly, updated: Date())
    lock.lock()
    if !jobs.values.contains(where: { $0.state == "running" }) { run = Run(babyId: babyId) }
    jobs[path] = job
    if job.counts { run.total += 1 }
    save()
    lock.unlock()
    task.resume()
    await updateActivity(force: true)
    return job.json
  }

  /// The size of the lô about to be handed over (see `Run.expected`).
  func expect(_ babyId: String, count: Int) {
    lock.lock()
    if !jobs.values.contains(where: { $0.state == "running" }) { run = Run(babyId: babyId) }
    run.expected = count
    save()
    lock.unlock()
    Task { await updateActivity(force: true) }
  }

  func cancel(_ path: String) {
    lock.lock()
    if let j = jobs[path], j.state == "running", j.counts { run.total = max(0, run.total - 1) }
    jobs[path] = nil
    save()
    lock.unlock()
    session.getAllTasks { tasks in
      for t in tasks where t.taskDescription == path { t.cancel() }
    }
    Task { await updateActivity(force: true) }
  }

  /// "Tạm dừng": everything handed over stops; Dart hands it over again on resume.
  func cancelAll() {
    lock.lock()
    jobs = jobs.filter { $0.value.state != "running" }
    run = Run()
    save()
    lock.unlock()
    session.getAllTasks { tasks in tasks.forEach { $0.cancel() } }
    Task { await updateActivity(force: true) }
  }

  private func save() {
    let d = UserDefaults.standard
    d.set(try? JSONEncoder().encode(jobs), forKey: jobsKey)
    d.set(try? JSONEncoder().encode(run), forKey: runKey)
  }

  private static func code(_ status: Int?) -> String {
    switch status {
    case nil: return "network"
    case 401: return "unauthenticated"
    case 403: return "unauthorized"
    case 404: return "object-not-found"
    default: return "http-\(status!)"
    }
  }

  private func send(_ event: [String: Any]) {
    DispatchQueue.main.async { self.emit?(event) }
  }

  // MARK: URLSession

  func urlSession(
    _ session: URLSession, task: URLSessionTask, didSendBodyData _: Int64, totalBytesSent sent: Int64,
    totalBytesExpectedToSend _: Int64
  ) {
    guard let path = task.taskDescription else { return }
    lock.lock()
    jobs[path]?.sent = sent
    let now = Date()
    let due = now.timeIntervalSince(lastEmit[path] ?? .distantPast) > 0.25
    if due { lastEmit[path] = now }
    lock.unlock()
    if due { send(["event": "progress", "path": path, "sent": sent]) }
    Task { await updateActivity() }
  }

  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    guard let path = task.taskDescription else { return }
    let status = (task.response as? HTTPURLResponse)?.statusCode
    lock.lock()
    guard var job = jobs[path], job.state == "running" else {
      // Cancelled and forgotten already.
      lock.unlock()
      return
    }
    if let e = error as NSError?, e.domain == NSURLErrorDomain, e.code == NSURLErrorCancelled {
      jobs[path] = nil
      if job.counts { run.total = max(0, run.total - 1) }
      save()
      lock.unlock()
      send(["event": "cancelled", "path": path])
      return
    }
    if error == nil, let status, (200..<300).contains(status) {
      job.state = "done"
      job.sent = job.total
      if job.counts { run.done += 1 }
    } else {
      job.state = "failed"
      job.code = error == nil ? Self.code(status) : "network"
      if job.counts { run.failed += 1 }
    }
    job.updated = Date()
    jobs[path] = job
    let idle = !jobs.values.contains(where: { $0.state == "running" })
    let finished = run
    if idle { run = Run() }
    save()
    lock.unlock()
    send(["event": job.state, "path": path, "code": job.code ?? NSNull()])
    Task {
      await updateActivity(force: true)
      if idle { await finish(finished) }
    }
  }

  func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
    DispatchQueue.main.async {
      self.backgroundCompletion?()
      self.backgroundCompletion = nil
    }
  }

  // MARK: Lock screen

  private var copy: [String: String] { GlanceSnapshot.load()?.copy ?? [:] }

  private func text(_ key: String, _ fallback: String, _ values: [String: String] = [:]) -> String {
    var s = copy[key] ?? fallback
    for (k, v) in values { s = s.replacingOccurrences(of: "{\(k)}", with: v) }
    return s
  }

  /// "Đã tải xong 7 mục" (one) / "7 mục chưa tải lên được": only when the app is not in front.
  private func finish(_ r: Run) async {
    let active = await MainActor.run { UIApplication.shared.applicationState == .active }
    guard !active, r.total > 0 else { return }
    let n = ["n": "\(r.failed > 0 ? r.failed : r.done)"]
    let one = (r.failed > 0 ? r.failed : r.done) == 1 ? ".one" : ""
    if r.failed > 0 {
      await notify(
        "uploads.failed", text("upload.failedTitle\(one)", "{n} mục chưa tải lên được", n),
        text("upload.failedBody", "Mở Child Life để thử lại."))
    } else {
      await notify(
        "uploads.done", text("upload.doneTitle\(one)", "Đã tải xong {n} mục", n),
        text("upload.doneBody", "Ảnh và video đã có trong Kỷ niệm."))
    }
  }

  /// 10j "1 video đang chờ Wi‑Fi": when the app is left with videos held for Wi-Fi.
  @objc private func didEnterBackground() {
    lock.lock()
    let waiting = jobs.values.filter { $0.state == "running" && $0.video && $0.wifiOnly && $0.counts }.count
    lock.unlock()
    guard waiting > 0, !onWifi else { return }
    let n = ["n": "\(waiting)"]
    Task {
      await notify(
        "uploads.wifi", text("upload.wifiTitle\(waiting == 1 ? ".one" : "")", "{n} video đang chờ Wi‑Fi", n),
        text("upload.wifiBody", "Ảnh vẫn đang tải. Video sẽ tự tải khi có Wi‑Fi."))
    }
  }

  private func notify(_ id: String, _ title: String, _ body: String) async {
    let center = UNUserNotificationCenter.current()
    let settings = await center.notificationSettings()
    guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.threadIdentifier = "uploads"
    try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: nil))
  }

  /// The upload Live Activity ("LiveActivity/Upload"): started while the app is in front, updated
  /// from the background as files finish, ended when nothing is left.
  private func updateActivity(force: Bool = false) async {
    #if canImport(ActivityKit)
    guard #available(iOS 16.2, *) else { return }
    lock.lock()
    let now = Date()
    if !force && now.timeIntervalSince(lastActivity) < 1 {
      lock.unlock()
      return
    }
    lastActivity = now
    let running = jobs.values.filter { $0.counts && $0.state == "running" }
    let r = run
    // Files done count whole; the ones still going by their own share of bytes.
    let partial = running.reduce(0.0) { $0 + ($1.total > 0 ? Double($1.sent) / Double($1.total) : 0) }
    // "1 video chờ Wi‑Fi" only while there is no Wi-Fi: on Wi-Fi the same video is uploading.
    let waiting = onWifi ? 0 : running.filter { $0.video && $0.wifiOnly }.count
    lock.unlock()
    let existing = Activity<UploadAttributes>.activities
    guard !running.isEmpty, r.shown > 0 else {
      for a in existing { await a.end(nil, dismissalPolicy: .immediate) }
      return
    }
    let fraction = (Double(r.done + r.failed) + partial) / Double(r.shown)
    let state = UploadAttributes.ContentState(
      done: r.done + r.failed, total: r.shown, fraction: min(1, max(0, fraction)), waitingWifi: waiting)
    let content = ActivityContent(state: state, staleDate: nil)
    if let current = existing.first {
      await current.update(content)
      return
    }
    let canStart = await MainActor.run { UIApplication.shared.applicationState == .active }
    guard canStart, ActivityAuthorizationInfo().areActivitiesEnabled else { return }
    let snap = GlanceSnapshot.load()
    let nickname = snap?.babyId == r.babyId ? snap?.nickname : nil
    let title = nickname.map { text("upload.title", "Kỷ niệm của {name}", ["name": $0]) }
      ?? text("upload.titlePlain", "Kỷ niệm")
    let keys = ["appName", "upload.progress", "upload.notify", "upload.waiting"]
    var liveCopy: [String: String] = ["title": title]
    for k in keys { liveCopy[k] = copy[k] }
    _ = try? Activity.request(attributes: UploadAttributes(copy: liveCopy), content: content, pushType: nil)
    #endif
  }
}
