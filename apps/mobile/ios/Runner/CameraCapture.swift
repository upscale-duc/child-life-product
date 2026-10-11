import AVFoundation
import Flutter
import UIKit
import UniformTypeIdentifiers

/// "Chụp ảnh / quay video" (10a2 camera, and the camera widget): the system camera with both
/// photo and video, which image_picker cannot offer in one screen. Photos come back upright as
/// JPEG, videos as the recorded file; both are copied to the temp folder for the upload queue.
/// Video length is capped by the server's limit (D-011) when there is one.
final class CameraCapture: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  static let shared = CameraCapture()
  private var pending: FlutterResult?

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "childlife/camera", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "capture":
        let args = call.arguments as? [String: Any]
        shared.capture(maxDuration: (args?["maxDurationSec"] as? NSNumber)?.doubleValue, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func capture(maxDuration: Double?, result: @escaping FlutterResult) {
    guard pending == nil else {
      result(FlutterError(code: "busy", message: nil, details: nil))
      return
    }
    guard UIImagePickerController.isSourceTypeAvailable(.camera), let top = Self.topController() else {
      result(FlutterError(code: "unavailable", message: nil, details: nil))
      return
    }
    let picker = UIImagePickerController()
    picker.sourceType = .camera
    let available = UIImagePickerController.availableMediaTypes(for: .camera) ?? []
    picker.mediaTypes = [UTType.image.identifier, UTType.movie.identifier].filter(available.contains)
    picker.videoQuality = .typeHigh
    if let d = maxDuration, d > 0 { picker.videoMaximumDuration = d }
    picker.delegate = self
    picker.modalPresentationStyle = .fullScreen
    pending = result
    top.present(picker, animated: true)
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true)
    finish(nil)
  }

  func imagePickerController(
    _ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
  ) {
    picker.dismiss(animated: true)
    let type = info[.mediaType] as? String
    DispatchQueue.global(qos: .userInitiated).async {
      let out: [String: Any]?
      if type == UTType.movie.identifier, let url = info[.mediaURL] as? URL {
        out = Self.video(url)
      } else if let image = info[.originalImage] as? UIImage {
        out = Self.photo(image)
      } else {
        out = nil
      }
      DispatchQueue.main.async { self.finish(out) }
    }
  }

  private func finish(_ value: [String: Any]?) {
    pending?(value)
    pending = nil
  }

  private static func tempURL(_ ext: String) -> URL {
    FileManager.default.temporaryDirectory.appendingPathComponent("cam_\(UUID().uuidString).\(ext)")
  }

  /// Upright pixels (the queue re-encodes without metadata, so the EXIF orientation would be lost).
  private static func photo(_ image: UIImage) -> [String: Any]? {
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = 1
    let upright = UIGraphicsImageRenderer(size: image.size.applying(.init(scaleX: image.scale, y: image.scale)), format: format)
      .image { _ in image.draw(in: CGRect(origin: .zero, size: image.size.applying(.init(scaleX: image.scale, y: image.scale)))) }
    guard let data = upright.jpegData(compressionQuality: 0.92) else { return nil }
    let url = tempURL("jpg")
    do { try data.write(to: url) } catch { return nil }
    return [
      "path": url.path, "kind": "photo", "name": url.lastPathComponent,
      "width": Int(upright.size.width), "height": Int(upright.size.height),
    ]
  }

  /// The recording is removed with the picker: keep a copy.
  private static func video(_ source: URL) -> [String: Any]? {
    let url = tempURL(source.pathExtension.isEmpty ? "mov" : source.pathExtension)
    do { try FileManager.default.copyItem(at: source, to: url) } catch { return nil }
    let asset = AVURLAsset(url: url)
    var out: [String: Any] = [
      "path": url.path, "kind": "video", "name": url.lastPathComponent,
      "durationMs": Int(CMTimeGetSeconds(asset.duration) * 1000),
    ]
    if let track = asset.tracks(withMediaType: .video).first {
      let size = track.naturalSize.applying(track.preferredTransform)
      out["width"] = Int(abs(size.width))
      out["height"] = Int(abs(size.height))
    }
    return out
  }

  private static func topController() -> UIViewController? {
    let window = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first { $0.isKeyWindow }
    var top = window?.rootViewController
    while let next = top?.presentedViewController { top = next }
    return top
  }
}
