import AVFoundation
import Combine
import ImageIO
import SwiftUI
import UIKit
import UniformTypeIdentifiers

// 10k "Thêm vào Kỷ niệm" (Figma 150:17772, R-117, D-046): shared photos and videos are copied into
// the App Group with a manifest (baby, Ai thấy, Báo cho gia đình); the app adds them to its upload
// queue the next time it opens. The baby list and every string come from the app (D-012), written
// to the App Group as `share.targets`. Nothing here talks to the network.

struct ShareTarget: Codable, Identifiable, Hashable {
  let id: String
  let nickname: String
}

struct ShareConfig: Codable {
  var signedIn: Bool
  var babies: [ShareTarget]
  var lastBabyId: String?
  var maxItems: Int
  var copy: [String: String]
}

struct SharedItem: Codable {
  let file: String
  let type: String
  let name: String
  let captureAt: String
  let width: Int?
  let height: Int?
  let durationMs: Int?
}

struct ShareManifest: Codable {
  let version: Int
  let babyId: String
  let audience: String
  let notifyFamily: Bool
  let createdAt: String
  let items: [SharedItem]
}

final class ShareViewController: UIViewController {
  private let model = ShareModel()

  override func viewDidLoad() {
    super.viewDidLoad()
    model.finish = { [weak self] added in
      guard let context = self?.extensionContext else { return }
      if added {
        context.completeRequest(returningItems: nil)
      } else {
        context.cancelRequest(withError: NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError))
      }
    }
    let host = UIHostingController(rootView: ShareView(model: model))
    addChild(host)
    host.view.frame = view.bounds
    host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(host.view)
    host.didMove(toParent: self)
    model.load(inputs: extensionContext?.inputItems as? [NSExtensionItem] ?? [])
  }
}

@MainActor
final class ShareModel: ObservableObject {
  @Published var config: ShareConfig?
  @Published var thumbs: [UIImage] = []
  @Published var photos = 0
  @Published var videos = 0
  @Published var loading = true
  @Published var babyId: String?
  @Published var family = true  // D-001: "Gia đình" preselected.
  @Published var notify = true
  var finish: (Bool) -> Void = { _ in }

  private var items: [SharedItem] = []
  private let folder = "share_" + UUID().uuidString.lowercased()
  private let group = Bundle.main.object(forInfoDictionaryKey: "CLAppGroup") as? String

  private var batchDir: URL? {
    guard let group,
      let root = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)
    else { return nil }
    return root.appendingPathComponent("ShareInbox/\(folder)", isDirectory: true)
  }

  var ready: Bool { config?.signedIn == true && !(config?.babies.isEmpty ?? true) }
  var canAdd: Bool { ready && !loading && !items.isEmpty && babyId != nil }

  func text(_ key: String, _ fallback: String) -> String { config?.copy[key] ?? fallback }

  func count(_ key: String, _ n: Int) -> String {
    text(n == 1 ? "\(key)One" : "\(key)Other", "{n}").replacingOccurrences(of: "{n}", with: "\(n)")
  }

  func load(inputs: [NSExtensionItem]) {
    if let group, let data = UserDefaults(suiteName: group)?.data(forKey: "share.targets") {
      config = try? JSONDecoder().decode(ShareConfig.self, from: data)
    }
    let babies = config?.babies ?? []
    babyId = babies.first(where: { $0.id == config?.lastBabyId })?.id ?? babies.first?.id
    guard ready, let dir = batchDir, let config else {
      loading = false
      return
    }
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let providers = Array(inputs.flatMap { $0.attachments ?? [] }.prefix(config.maxItems))
    Task {
      for (index, provider) in providers.enumerated() {
        guard let result = await copy(provider, index: index, into: dir) else { continue }
        let (item, thumb) = result
        items.append(item)
        if item.type == "video" { videos += 1 } else { photos += 1 }
        if let thumb, thumbs.count < 3 { thumbs.append(thumb) }
      }
      loading = false
    }
  }

  func add() {
    guard canAdd, let dir = batchDir, let babyId else { return }
    let manifest = ShareManifest(
      version: 1, babyId: babyId, audience: family ? "family" : "parents",
      notifyFamily: family && notify, createdAt: Self.iso(Date()), items: items)
    // Written last: a folder without a manifest is an unfinished share the app ignores.
    if let data = try? JSONEncoder().encode(manifest) {
      try? data.write(to: dir.appendingPathComponent("manifest.json"), options: .atomic)
    }
    finish(true)
  }

  func cancel() {
    if let dir = batchDir { try? FileManager.default.removeItem(at: dir) }
    finish(false)
  }

  // MARK: Copying

  private func copy(_ provider: NSItemProvider, index: Int, into dir: URL) async -> (SharedItem, UIImage?)? {
    let isMovie = provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier)
    guard isMovie || provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) else { return nil }
    let type: UTType = isMovie ? .movie : .image
    guard let url = await fileCopy(provider, type: type, index: index, into: dir) else { return nil }
    return isMovie ? await videoItem(url) : imageItem(url)
  }

  private func fileCopy(_ provider: NSItemProvider, type: UTType, index: Int, into dir: URL) async -> URL? {
    let viaFile: URL? = await withCheckedContinuation { done in
      _ = provider.loadFileRepresentation(forTypeIdentifier: type.identifier) { source, _ in
        // The source is deleted when this returns, so copy before resuming.
        guard let source else { return done.resume(returning: nil) }
        let ext = source.pathExtension.isEmpty ? (type == .movie ? "mov" : "jpg") : source.pathExtension.lowercased()
        let target = dir.appendingPathComponent("\(index).\(ext)")
        try? FileManager.default.removeItem(at: target)
        do {
          try FileManager.default.copyItem(at: source, to: target)
          done.resume(returning: target)
        } catch {
          done.resume(returning: nil)
        }
      }
    }
    if viaFile != nil || type == .movie { return viaFile }
    // Some apps share images only as data (screenshots, edited images).
    return await withCheckedContinuation { done in
      _ = provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
        guard let data else { return done.resume(returning: nil) }
        let target = dir.appendingPathComponent("\(index).img")
        done.resume(returning: (try? data.write(to: target)) != nil ? target : nil)
      }
    }
  }

  private func imageItem(_ url: URL) -> (SharedItem, UIImage?)? {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
      CGImageSourceGetCount(source) > 0
    else { return nil }
    let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] ?? [:]
    var width = props[kCGImagePropertyPixelWidth] as? Int
    var height = props[kCGImagePropertyPixelHeight] as? Int
    if let orientation = props[kCGImagePropertyOrientation] as? Int, orientation >= 5 {
      swap(&width, &height)
    }
    let exif = props[kCGImagePropertyExifDictionary] as? [CFString: Any]
    let taken = (exif?[kCGImagePropertyExifDateTimeOriginal] as? String).flatMap(Self.exifDate)
    let options: [CFString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceThumbnailMaxPixelSize: 240,
      kCGImageSourceCreateThumbnailWithTransform: true,
    ]
    let thumb = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary).map(UIImage.init(cgImage:))
    let item = SharedItem(
      file: url.lastPathComponent, type: "photo", name: url.lastPathComponent,
      captureAt: Self.iso(taken ?? Date()), width: width, height: height, durationMs: nil)
    return (item, thumb)
  }

  private func videoItem(_ url: URL) async -> (SharedItem, UIImage?)? {
    let asset = AVURLAsset(url: url)
    guard let duration = try? await asset.load(.duration) else { return nil }
    var size: CGSize?
    if let track = try? await asset.loadTracks(withMediaType: .video).first,
      let natural = try? await track.load(.naturalSize),
      let transform = try? await track.load(.preferredTransform)
    {
      let r = natural.applying(transform)
      size = CGSize(width: abs(r.width), height: abs(r.height))
    }
    var created: Date?
    if let item = try? await asset.load(.creationDate) {
      created = try? await item.load(.dateValue)
    }
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    generator.maximumSize = CGSize(width: 240, height: 240)
    let thumb = (try? await generator.image(at: .zero).image).map(UIImage.init(cgImage:))
    let item = SharedItem(
      file: url.lastPathComponent, type: "video", name: url.lastPathComponent,
      captureAt: Self.iso(created ?? Date()),
      width: size.map { Int($0.width) }, height: size.map { Int($0.height) },
      durationMs: Int(CMTimeGetSeconds(duration) * 1000))
    return (item, thumb)
  }

  private static func iso(_ date: Date) -> String {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime]
    return f.string(from: date)
  }

  /// EXIF "2026:10:11 08:36:42" is local time on the device that took the photo.
  private static func exifDate(_ s: String) -> Date? {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "yyyy:MM:dd HH:mm:ss"
    return f.date(from: s)
  }
}

// MARK: - View

private extension Color {
  /// Design tokens `ink` / `mint-deep` (light) and their Night values.
  static let ink = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.90, green: 0.95, blue: 0.95, alpha: 1) : UIColor(red: 0.09, green: 0.24, blue: 0.27, alpha: 1) })
  static let onInk = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.05, green: 0.09, blue: 0.10, alpha: 1) : .white })
  static let mint = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.25, green: 0.82, blue: 0.76, alpha: 1) : UIColor(red: 0.03, green: 0.50, blue: 0.48, alpha: 1) })
}

struct ShareView: View {
  @ObservedObject var model: ShareModel

  var body: some View {
    VStack(spacing: 0) {
      header
      Divider()
      ScrollView { content.padding(20) }
    }
    .background(Color(UIColor.systemGroupedBackground))
    .tint(.mint)
  }

  private var header: some View {
    HStack {
      Button(model.text("cancel", "Huỷ")) { model.cancel() }
      Spacer()
      Text(model.text("title", "Thêm vào Kỷ niệm")).font(.headline).foregroundColor(.ink)
      Spacer()
      if model.ready {
        Button(model.text("add", "Thêm")) { model.add() }
          .font(.body.weight(.semibold))
          .disabled(!model.canAdd)
      } else {
        Text(model.text("add", "Thêm")).hidden()
      }
    }
    .padding(.horizontal, 16)
    .frame(height: 56)
  }

  @ViewBuilder private var content: some View {
    if model.loading {
      ProgressView().frame(maxWidth: .infinity).padding(.top, 40)
    } else if model.config?.signedIn != true {
      message(model.text("signedOut", "Mở Child Life và đăng nhập để thêm ảnh vào Kỷ niệm."))
    } else if model.config?.babies.isEmpty ?? true {
      message(model.text("noBaby", "Chỉ ba mẹ thêm được kỷ niệm."))
    } else if !model.canAdd {
      message(model.text("nothing", "Không có ảnh hay video nào để thêm."))
    } else {
      form
    }
  }

  private func message(_ text: String) -> some View {
    VStack(spacing: 16) {
      Text(text).multilineTextAlignment(.center).foregroundColor(.ink)
      Button(model.text("close", "Đóng")) { model.cancel() }.font(.body.weight(.semibold))
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 40)
  }

  private var countLabel: String {
    [model.photos > 0 ? model.count("photos", model.photos) : nil,
     model.videos > 0 ? model.count("videos", model.videos) : nil]
      .compactMap { $0 }.joined(separator: " · ")
  }

  private var form: some View {
    VStack(alignment: .leading, spacing: 20) {
      HStack(spacing: 8) {
        ForEach(Array(model.thumbs.enumerated()), id: \.offset) { _, image in
          Image(uiImage: image).resizable().scaledToFill()
            .frame(width: 64, height: 64).clipShape(RoundedRectangle(cornerRadius: 12))
        }
        Text(countLabel).font(.subheadline).foregroundColor(.secondary).padding(.leading, 4)
      }

      row {
        Text(model.text("baby", "Bé")).foregroundColor(.ink)
        Spacer()
        if let babies = model.config?.babies, babies.count > 1 {
          Picker("", selection: Binding(get: { model.babyId ?? "" }, set: { model.babyId = $0 })) {
            ForEach(babies) { Text($0.nickname).tag($0.id) }
          }
          .pickerStyle(.menu)
        } else {
          Text(model.config?.babies.first?.nickname ?? "").fontWeight(.semibold).foregroundColor(.ink)
        }
      }

      VStack(alignment: .leading, spacing: 10) {
        Text(model.text("who", "Ai thấy")).font(.subheadline.weight(.semibold)).foregroundColor(.ink)
        HStack(spacing: 10) {
          chip(model.text("parents", "Chỉ ba mẹ"), icon: "lock.fill", on: !model.family) { model.family = false }
          chip(model.text("family", "Gia đình"), icon: "person.2.fill", on: model.family) { model.family = true }
        }
      }

      if model.family {
        row {
          VStack(alignment: .leading, spacing: 2) {
            Text(model.text("notify", "Báo cho gia đình")).foregroundColor(.ink)
            Text(model.text("notifyHint", "Gửi 1 thông báo khi tải xong")).font(.footnote).foregroundColor(.secondary)
          }
          Spacer()
          Toggle("", isOn: $model.notify).labelsHidden()
        }
      }

      Text(model.text("footnote", "Ảnh sẽ tải lên khi bạn mở Child Life."))
        .font(.footnote).foregroundColor(.secondary)
    }
  }

  private func row<C: View>(@ViewBuilder _ content: () -> C) -> some View {
    HStack { content() }
      .padding(.horizontal, 16).frame(minHeight: 56)
      .background(Color(UIColor.secondarySystemGroupedBackground))
      .clipShape(RoundedRectangle(cornerRadius: 16))
  }

  private func chip(_ label: String, icon: String, on: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Label(label, systemImage: icon)
        .font(.subheadline.weight(.medium))
        .padding(.horizontal, 16).frame(height: 44)
        .foregroundColor(on ? .onInk : .ink)
        .background(on ? Color.ink : Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(Capsule())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(on ? .isSelected : [])
  }
}
