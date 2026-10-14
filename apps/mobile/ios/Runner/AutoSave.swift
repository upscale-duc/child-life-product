import AVFoundation
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
  /// Videos are read as a few frames at this longest side: a baby's face is a smaller part of a
  /// video frame than of a photo, and the poster frame alone (often the first, often blurred or
  /// without the baby) matched no video at all.
  static let videoSide: CGFloat = 1024
  static let videoFrames = 5
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
      case "inspectRecent":
        work.async { reply(inspectRecent()) }
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
    // Screenshots and screen recordings are left out below, not in the query: a bitwise
    // `mediaSubtypes` predicate left out every video on the owner's phone (2026-10-14).
    var parts: [NSPredicate] = [NSCompoundPredicate(orPredicateWithSubpredicates: kinds)]
    let fetched: PHFetchResult<PHAsset>
    if let ids {
      options.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: parts)
      fetched = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: options)
    } else {
      // Saved from Zalo, Messenger or AirDrop: the date taken can be old or missing, so a recent
      // addition counts too (Photos sets the modification date when an item comes in).
      let from = (since ?? Date().addingTimeInterval(-30 * 86_400)) as NSDate
      parts.append(
        NSCompoundPredicate(orPredicateWithSubpredicates: [
          NSPredicate(format: "creationDate >= %@", from),
          NSPredicate(format: "modificationDate >= %@", from),
        ]))
      options.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: parts)
      fetched = PHAsset.fetchAssets(with: options)
    }
    var out: [String] = []
    var listedVideos = 0
    out.reserveCapacity(fetched.count)
    let skip: PHAssetMediaSubtype = [.photoScreenshot, .videoScreenRecording]
    fetched.enumerateObjects { asset, _, _ in
      guard asset.mediaSubtypes.intersection(skip).isEmpty else { return }
      out.append(asset.localIdentifier)
      if asset.mediaType == .video { listedVideos += 1 }
    }
    return [
      "ids": out,
      // Dev diagnostics: what the history or the date filter returned before any filtering in Dart.
      "inserted": ids?.count ?? -1,
      "videos": listedVideos,
      "fromHistory": ids != nil,
      "token": current.map(FlutterStandardTypedData.init(bytes:)) as Any,
    ]
  }

  /// Dev diagnostics: the newest library items by date taken and by last change, with what the
  /// check's filter makes of them (file name, kind, dates, source, hidden).
  static func inspectRecent() -> [[String: Any]] {
    func fetch(_ key: String) -> PHFetchResult<PHAsset> {
      let options = PHFetchOptions()
      options.includeHiddenAssets = true
      options.includeAssetSourceTypes = [.typeUserLibrary, .typeCloudShared, .typeiTunesSynced]
      options.sortDescriptors = [NSSortDescriptor(key: key, ascending: false)]
      options.fetchLimit = 40
      return PHAsset.fetchAssets(with: options)
    }
    let skip = PHAssetMediaSubtype.photoScreenshot.rawValue | PHAssetMediaSubtype.videoScreenRecording.rawValue
    var seen = Set<String>()
    var out: [[String: Any]] = []
    for result in [fetch("creationDate"), fetch("modificationDate")] {
      result.enumerateObjects { asset, _, _ in
        guard seen.insert(asset.localIdentifier).inserted else { return }
        let ms = { (d: Date?) in d.map { Int64(($0.timeIntervalSince1970 * 1000).rounded()) } as Any }
        out.append([
          "id": asset.localIdentifier,
          "name": PHAssetResource.assetResources(for: asset).first?.originalFilename ?? "",
          "video": asset.mediaType == .video,
          "mediaType": asset.mediaType.rawValue,
          "subtypes": asset.mediaSubtypes.rawValue,
          "source": asset.sourceType.rawValue,
          "hidden": asset.isHidden,
          "created": ms(asset.creationDate),
          "modified": ms(asset.modificationDate),
          "passes": (asset.mediaType == .image || asset.mediaType == .video)
            && (asset.mediaSubtypes.rawValue & skip) == 0
            && (asset.sourceType.contains(.typeUserLibrary) || asset.sourceType.contains(.typeiTunesSynced))
            && !asset.isHidden,
        ])
      }
    }
    return out
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
          // Diagnostics: the name the parent sees in Photos (IMG_3859), never a caption or a face.
          "name": PHAssetResource.assetResources(for: asset).first?.originalFilename ?? "",
          "captureAt": Int64(((asset.creationDate ?? Date()).timeIntervalSince1970 * 1000).rounded()),
          "video": asset.mediaType == .video,
          "durationMs": Int(asset.duration * 1000),
          "width": asset.pixelWidth,
          "height": asset.pixelHeight,
          "favorite": asset.isFavorite,
          "burstPick": asset.burstSelectionTypes.contains(.userPick),
        ]
        if let burst = asset.burstIdentifier { out["burst"] = burst }
        if asset.mediaType == .video {
          let shots = frames(asset)
          out["frames"] = shots.count
          if !shots.isEmpty {
            describe(frames: shots, into: &out)
            return out
          }
        }
        guard let image = thumbnail(asset) else {
          out["unreadable"] = true
          return out
        }
        describe(image, into: &out)
        // "Utility" (receipts, documents) is judged on photos; a video's poster frame says little.
        if asset.mediaType == .video { out.removeValue(forKey: "utility") }
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

  /// Up to [videoFrames] upright frames spread over a video, from a file already on the phone. An
  /// iCloud-only video gives none and is described from its poster frame instead.
  private static func frames(_ asset: PHAsset) -> [CGImage] {
    let options = PHVideoRequestOptions()
    options.isNetworkAccessAllowed = false
    options.version = .current
    options.deliveryMode = .highQualityFormat
    let got = DispatchSemaphore(value: 0)
    var video: AVAsset?
    PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { av, _, _ in
      video = av
      got.signal()
    }
    guard got.wait(timeout: .now() + 10) == .success, let video else { return [] }
    let length = asset.duration
    guard length > 0 else { return [] }
    let count = length < 2 ? 1 : min(videoFrames, max(3, Int(length / 3)))
    let generator = AVAssetImageGenerator(asset: video)
    generator.appliesPreferredTrackTransform = true
    generator.maximumSize = CGSize(width: videoSide, height: videoSide)
    let tolerance = CMTime(seconds: min(0.5, length / Double(count * 2)), preferredTimescale: 600)
    generator.requestedTimeToleranceBefore = tolerance
    generator.requestedTimeToleranceAfter = tolerance
    let times = (0..<count).map {
      NSValue(time: CMTime(seconds: length * (Double($0) + 0.5) / Double(count), preferredTimescale: 600))
    }
    let lock = NSLock()
    var images: [CGImage] = []
    let done = DispatchGroup()
    times.forEach { _ in done.enter() }
    generator.generateCGImagesAsynchronously(forTimes: times) { _, image, _, _, _ in
      if let image {
        lock.lock()
        images.append(image)
        lock.unlock()
      }
      done.leave()
    }
    if done.wait(timeout: .now() + 20) == .timedOut { generator.cancelAllCGImageGeneration() }
    lock.lock()
    defer { lock.unlock() }
    return images
  }

  /// A video as one item: the faces of every frame (the Dart side keeps the closest to a baby),
  /// and the whole-image print and aesthetics of the frame with the largest face.
  private static func describe(frames: [CGImage], into out: inout [String: Any]) {
    var faces: [[String: Any]] = []
    var lead: [String: Any]?
    var leadSize = -1.0
    for frame in frames {
      autoreleasepool {
        var one: [String: Any] = [:]
        describe(UIImage(cgImage: frame), into: &one)
        let found = one["faces"] as? [[String: Any]] ?? []
        faces.append(contentsOf: found)
        let largest = found.compactMap { $0["size"] as? Double }.max() ?? 0
        if lead == nil || largest > leadSize {
          lead = one
          leadSize = largest
        }
      }
    }
    if let print = lead?["print"] { out["print"] = print }
    if let score = lead?["aesthetics"] { out["aesthetics"] = score }
    out["faces"] = Array(faces.sorted { ($0["size"] as? Double ?? 0) > ($1["size"] as? Double ?? 0) }.prefix(16))
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
