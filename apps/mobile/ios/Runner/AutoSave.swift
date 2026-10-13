import BackgroundTasks
import Flutter
import Photos
import PhotosUI
import UIKit
import UserNotifications
import Vision

/// Tự lưu kỷ niệm (D-066, AS01 – AS19): the phone's side of the scan. It only reads the library
/// and describes photos; deciding which baby is in a photo, grouping and ranking happen in Dart
/// (lib/features/auto_save/). Nothing here leaves the device and nothing is written to disk except
/// photos the parent saves to the library (P-147, P-150).
enum AutoSave {
  /// Longest side of the image Vision looks at. Local thumbnails are enough; iCloud originals are
  /// only fetched for upload (`isNetworkAccessAllowed = false`).
  static let side: CGFloat = 512
  private static let work = DispatchQueue(label: "childlife.autosave", qos: .utility)

  /// [headless]: the engine started only for a background check (AutoSaveBackground).
  static func register(with messenger: FlutterBinaryMessenger, headless: Bool = false) {
    let channel = FlutterMethodChannel(name: "childlife/autosave", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      let args = call.arguments as? [String: Any] ?? [:]
      let reply: (Any?) -> Void = { out in DispatchQueue.main.async { result(out) } }
      switch call.method {
      case "access":
        result(access(PHPhotoLibrary.authorizationStatus(for: .readWrite)))
      case "requestAccess":
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { reply(access($0)) }
      case "pickMore":
        guard let root = topController() else { return result(nil) }
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: root) { _ in reply(nil) }
      case "openSettings":
        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
        result(nil)
      case "changes":
        work.async { reply(changes(token: (args["token"] as? FlutterStandardTypedData)?.data,
                                   since: (args["since"] as? NSNumber).map { Date(timeIntervalSince1970: $0.doubleValue / 1000) },
                                   photos: args["photos"] as? Bool ?? true,
                                   videos: args["videos"] as? Bool ?? true)) }
      case "analyze":
        let ids = args["ids"] as? [String] ?? []
        work.async { reply(analyze(ids: ids)) }
      case "analyzeFile":
        let path = args["path"] as? String ?? ""
        work.async { reply(analyzeFile(path: path)) }
      case "save":
        save(path: args["path"] as? String ?? "", video: args["video"] as? Bool ?? false,
             album: args["album"] as? String, reply: reply)
      case "backgroundReady":
        AutoSaveBackground.dartReady(channel, headless: headless)
        result(nil)
      case "schedule":
        AutoSaveBackground.schedule()
        result(nil)
      case "unschedule":
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: AutoSaveBackground.taskId)
        result(nil)
      case "excludeFromBackup":
        var url = URL(fileURLWithPath: args["path"] as? String ?? "")
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? url.setResourceValues(values)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  static func access(_ s: PHAuthorizationStatus) -> String {
    switch s {
    case .authorized: return "full"
    case .limited: return "limited"
    case .notDetermined: return "notDetermined"
    default: return "denied"
    }
  }

  // MARK: New files

  /// Library items added since the last check: from the persistent change history when the token
  /// still works, otherwise every item created since `since` (Dart drops the ones it has seen).
  /// Screenshots, screen recordings, hidden items and shared albums are left out. Newest first.
  static func changes(token: Data?, since: Date?, photos: Bool, videos: Bool) -> [String: Any] {
    let library = PHPhotoLibrary.shared()
    let current = try? NSKeyedArchiver.archivedData(
      withRootObject: library.currentChangeToken, requiringSecureCoding: true)
    var ids: [String]? = nil
    if let token,
      let old = try? NSKeyedUnarchiver.unarchivedObject(ofClass: PHPersistentChangeToken.self, from: token)
    {
      if let result = try? library.fetchPersistentChanges(since: old) {
        var inserted = Set<String>()
        for change in result {
          if let details = try? change.changeDetails(for: .asset) {
            inserted.formUnion(details.insertedLocalIdentifiers)
          }
        }
        ids = Array(inserted)
      }
    }
    let options = PHFetchOptions()
    options.includeAssetSourceTypes = [.typeUserLibrary, .typeiTunesSynced]
    options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    var kinds: [NSPredicate] = []
    if photos { kinds.append(NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)) }
    if videos { kinds.append(NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)) }
    if kinds.isEmpty { return ["ids": [String](), "token": current.map(FlutterStandardTypedData.init(bytes:)) as Any] }
    let skip = PHAssetMediaSubtype.photoScreenshot.rawValue | PHAssetMediaSubtype.videoScreenRecording.rawValue
    var parts: [NSPredicate] = [
      NSCompoundPredicate(orPredicateWithSubpredicates: kinds),
      NSPredicate(format: "(mediaSubtypes & %d) == 0", skip),
    ]
    let fetched: PHFetchResult<PHAsset>
    if let ids {
      options.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: parts)
      fetched = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: options)
    } else {
      parts.append(NSPredicate(format: "creationDate >= %@", (since ?? Date().addingTimeInterval(-30 * 86_400)) as NSDate))
      options.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: parts)
      fetched = PHAsset.fetchAssets(with: options)
    }
    var out: [String] = []
    out.reserveCapacity(fetched.count)
    fetched.enumerateObjects { asset, _, _ in out.append(asset.localIdentifier) }
    return [
      "ids": out,
      "fromHistory": ids != nil,
      "token": current.map(FlutterStandardTypedData.init(bytes:)) as Any,
    ]
  }

  // MARK: Describing photos

  static func analyze(ids: [String]) -> [[String: Any]] {
    let fetched = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
    var byId: [String: PHAsset] = [:]
    fetched.enumerateObjects { asset, _, _ in byId[asset.localIdentifier] = asset }
    return ids.map { id in
      autoreleasepool {
        guard let asset = byId[id] else { return ["id": id, "missing": true] }
        var out: [String: Any] = [
          "id": id,
          "captureAt": Int64(((asset.creationDate ?? Date()).timeIntervalSince1970 * 1000).rounded()),
          "video": asset.mediaType == .video,
          "durationMs": Int(asset.duration * 1000),
          "width": asset.pixelWidth,
          "height": asset.pixelHeight,
          "favorite": asset.isFavorite,
          "burstPick": asset.burstSelectionTypes.contains(.userPick),
        ]
        if let burst = asset.burstIdentifier { out["burst"] = burst }
        guard let image = thumbnail(asset) else {
          out["unreadable"] = true
          return out
        }
        describe(image, into: &out)
        return out
      }
    }
  }

  /// A sample photo from Kỷ niệm, already in the app's media cache: described, never copied.
  static func analyzeFile(path: String) -> [String: Any] {
    autoreleasepool {
      var out: [String: Any] = ["id": path]
      guard let image = UIImage(contentsOfFile: path) else {
        out["unreadable"] = true
        return out
      }
      describe(image, into: &out)
      return out
    }
  }

  private static func thumbnail(_ asset: PHAsset) -> UIImage? {
    let options = PHImageRequestOptions()
    options.isSynchronous = true
    options.isNetworkAccessAllowed = false
    options.resizeMode = .fast
    options.deliveryMode = .highQualityFormat
    var image: UIImage?
    let size = CGSize(width: side, height: side)
    PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: options) {
      img, _ in image = img
    }
    if image == nil {
      // Only an iCloud original exists: use the small local preview Photos keeps.
      options.deliveryMode = .fastFormat
      PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: options) {
        img, _ in image = img
      }
    }
    return image
  }

  /// Faces (each with its own print and capture quality), a print of the whole image for
  /// grouping, and Apple's aesthetics score on iOS 18+.
  private static func describe(_ image: UIImage, into out: inout [String: Any]) {
    guard let cg = image.cgImage else {
      out["unreadable"] = true
      return
    }
    let handler = VNImageRequestHandler(cgImage: cg, orientation: orientation(image.imageOrientation))
    let whole = VNGenerateImageFeaturePrintRequest()
    let rects = VNDetectFaceRectanglesRequest()
    var requests: [VNRequest] = [whole, rects]
    var aesthetics: VNRequest?
    if #available(iOS 18.0, *) {
      let r = VNCalculateImageAestheticsScoresRequest()
      aesthetics = r
      requests.append(r)
    }
    try? handler.perform(requests)
    if let p = whole.results?.first { out["print"] = floats(p) }
    if #available(iOS 18.0, *), let a = (aesthetics as? VNCalculateImageAestheticsScoresRequest)?.results?.first {
      out["aesthetics"] = Double(a.overallScore)
      out["utility"] = a.isUtility
    }
    let found = rects.results ?? []
    guard !found.isEmpty else {
      out["faces"] = [[String: Any]]()
      return
    }
    let quality = VNDetectFaceCaptureQualityRequest()
    quality.inputFaceObservations = found
    try? handler.perform([quality])
    let scored = quality.results ?? found
    var faces: [[String: Any]] = []
    for face in scored.prefix(8) {
      let box = face.boundingBox
      var f: [String: Any] = ["size": Double(max(box.width, box.height))]
      if let q = face.faceCaptureQuality { f["quality"] = Double(q) }
      // A print of the face alone (with a margin) stands for who it is; v1 has no face model (P-149).
      let crop = VNGenerateImageFeaturePrintRequest()
      crop.regionOfInterest = box.insetBy(dx: -box.width * 0.25, dy: -box.height * 0.25)
        .intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
      if (try? handler.perform([crop])) != nil, let p = crop.results?.first { f["print"] = floats(p) }
      faces.append(f)
    }
    out["faces"] = faces
  }

  private static func floats(_ p: VNFeaturePrintObservation) -> FlutterStandardTypedData {
    if p.elementType == .float { return FlutterStandardTypedData(float32: p.data) }
    let doubles = p.data.withUnsafeBytes { Array($0.bindMemory(to: Double.self)) }
    let values = doubles.map { Float($0) }
    return FlutterStandardTypedData(float32: values.withUnsafeBufferPointer { Data(buffer: $0) })
  }

  private static func orientation(_ o: UIImage.Orientation) -> CGImagePropertyOrientation {
    switch o {
    case .up: return .up
    case .down: return .down
    case .left: return .left
    case .right: return .right
    case .upMirrored: return .upMirrored
    case .downMirrored: return .downMirrored
    case .leftMirrored: return .leftMirrored
    case .rightMirrored: return .rightMirrored
    @unknown default: return .up
    }
  }

  // MARK: Saving to the library

  /// "Tải về" (10f / 10b3) through PhotoKit instead of `gal`, so the new item's id goes into the
  /// ledger and Tự lưu never suggests a Child Life download back (P-150).
  static func save(path: String, video: Bool, album: String?, reply: @escaping (Any?) -> Void) {
    let url = URL(fileURLWithPath: path)
    let level: PHAccessLevel = album == nil ? .addOnly : .readWrite
    PHPhotoLibrary.requestAuthorization(for: level) { status in
      guard status == .authorized || status == .limited else {
        return reply(FlutterError(code: "denied", message: nil, details: nil))
      }
      var created: String?
      PHPhotoLibrary.shared().performChanges({
        let request = PHAssetCreationRequest.forAsset()
        request.addResource(with: video ? .video : .photo, fileURL: url, options: nil)
        created = request.placeholderForCreatedAsset?.localIdentifier
        guard let album, let placeholder = request.placeholderForCreatedAsset else { return }
        let find = PHFetchOptions()
        find.predicate = NSPredicate(format: "title == %@", album)
        if let existing = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: find).firstObject {
          PHAssetCollectionChangeRequest(for: existing)?.addAssets([placeholder] as NSArray)
        } else {
          PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: album)
            .addAssets([placeholder] as NSArray)
        }
      }) { ok, _ in
        reply(ok ? ["id": created as Any] : FlutterError(code: "failed", message: nil, details: nil))
      }
    }
  }

  private static func topController() -> UIViewController? {
    let scene = UIApplication.shared.connectedScenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
    var top = scene?.windows.first { $0.isKeyWindow }?.rootViewController
    while let next = top?.presentedViewController { top = next }
    return top
  }
}

/// Checks while the app is in the background or closed (M2, AR03). iOS decides when, usually
/// while the phone charges. The check itself is Dart, where matching and grouping live: the app's
/// engine when it is running, otherwise a headless engine started just for the check
/// (`autoSaveBackground` in lib/features/auto_save/auto_save_background.dart). Dart answers with
/// the notification text, or nothing; the notification is posted here.
enum AutoSaveBackground {
  static let taskId = "childlife.autosave.check"

  /// The running app's channel, once its Dart side listens.
  private static var appChannel: FlutterMethodChannel?
  private static var waiting: BGProcessingTask?
  private static var running: (task: BGProcessingTask, channel: FlutterMethodChannel)?
  private static var finished = Set<ObjectIdentifier>()
  private static var headless: FlutterEngine?

  /// From didFinishLaunching: iOS wants the handler before launch ends.
  static func registerTask() {
    BGTaskScheduler.shared.register(forTaskWithIdentifier: taskId, using: .main) { task in
      guard let task = task as? BGProcessingTask else { return task.setTaskCompleted(success: false) }
      start(task)
    }
  }

  /// Asks iOS for the next check; one pending request at a time (same identifier).
  static func schedule() {
    let request = BGProcessingTaskRequest(identifier: taskId)
    request.requiresNetworkConnectivity = false
    request.requiresExternalPower = false
    request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60)
    try? BGTaskScheduler.shared.submit(request)
  }

  static func dartReady(_ channel: FlutterMethodChannel, headless isHeadless: Bool) {
    if !isHeadless { appChannel = channel }
    if let task = waiting { run(task, on: channel) }
  }

  private static func start(_ task: BGProcessingTask) {
    schedule()
    task.expirationHandler = {
      DispatchQueue.main.async {
        guard let current = running, current.task === task else { return finish(task, ok: false) }
        current.channel.invokeMethod("stopBackground", arguments: nil)
        // Dart stops between batches; iOS will not wait long.
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { finish(task, ok: false) }
      }
    }
    if let channel = appChannel {
      return run(task, on: channel)
    }
    waiting = task
    let engine = FlutterEngine(name: "autosave.background", project: nil, allowHeadlessExecution: true)
    engine.run(
      withEntrypoint: "autoSaveBackground",
      libraryURI: "package:child_life/features/auto_save/auto_save_background.dart")
    GeneratedPluginRegistrant.register(with: engine)
    if let registrar = engine.registrar(forPlugin: "AutoSaveBackground") {
      AutoSave.register(with: registrar.messenger(), headless: true)
    }
    headless = engine
    // Nothing set up, or Dart never answered: give the time back.
    DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
      if waiting === task { finish(task, ok: false) }
    }
  }

  private static func run(_ task: BGProcessingTask, on channel: FlutterMethodChannel) {
    if waiting === task { waiting = nil }
    running = (task, channel)
    channel.invokeMethod("backgroundCheck", arguments: nil) { reply in
      if let r = reply as? [String: Any], let title = r["title"] as? String, let body = r["body"] as? String {
        notify(title: title, body: body, at: (r["at"] as? NSNumber).map { Date(timeIntervalSince1970: $0.doubleValue / 1000) })
      }
      finish(task, ok: !(reply is FlutterError))
    }
  }

  private static func finish(_ task: BGProcessingTask, ok: Bool) {
    guard finished.insert(ObjectIdentifier(task)).inserted else { return }
    if waiting === task { waiting = nil }
    if running?.task === task { running = nil }
    task.setTaskCompleted(success: ok)
    headless?.destroyContext()
    headless = nil
  }

  /// AR03: "Có 8 ảnh mới có thể có Teddy"; the tap opens the review (AppDelegate). A find during
  /// quiet hours is shown at [at] (07:00).
  private static func notify(title: String, body: String, at: Date?) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default
    let id = "autosave.\(Int(Date().timeIntervalSince1970))"
    let wait = (at?.timeIntervalSinceNow ?? 0)
    let trigger = wait > 1 ? UNTimeIntervalNotificationTrigger(timeInterval: wait, repeats: false) : nil
    UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
  }
}
