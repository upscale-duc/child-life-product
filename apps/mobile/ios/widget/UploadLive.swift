import ActivityKit
import SwiftUI
import WidgetKit

/// 10j "LiveActivity/Upload": memory uploads running in the background. Counts and a bar only —
/// "Không kèm ảnh trên màn hình khoá". Tapping opens Kỷ niệm (the queue is one tap away there).
struct UploadLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: UploadAttributes.self) { context in
      UploadLockView(a: context.attributes, st: context.state)
        .activityBackgroundTint(Color.clSurface)
        .activitySystemActionForegroundColor(Color.clInk)
        .widgetURL(GlanceLink.url("/memories"))
    } dynamicIsland: { context in
      let a = context.attributes
      let st = context.state
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          UploadBadge().padding(.leading, 4)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text(UploadText.percent(st)).font(.system(size: 20, weight: .semibold).monospacedDigit())
            .foregroundStyle(Color.clMint).lineLimit(1)
        }
        DynamicIslandExpandedRegion(.center) {
          VStack(alignment: .leading, spacing: 2) {
            Text(UploadText.progress(a, st)).font(.system(size: 15, weight: .semibold)).lineLimit(1)
              .minimumScaleFactor(0.8)
            Text(a.text("title", "Kỷ niệm")).font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(1)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        DynamicIslandExpandedRegion(.bottom) {
          ProgressView(value: st.fraction).tint(Color.clMint).padding(.horizontal, 4)
        }
      } compactLeading: {
        Image(systemName: "arrow.up.circle.fill").foregroundStyle(Color.clMint)
      } compactTrailing: {
        Text(UploadText.percent(st)).monospacedDigit().foregroundStyle(Color.clMint).lineLimit(1)
          .minimumScaleFactor(0.7).frame(width: 44, alignment: .trailing)
      } minimal: {
        ProgressView(value: st.fraction) {
          Image(systemName: "arrow.up").font(.system(size: 9, weight: .bold))
        }
        .progressViewStyle(.circular).tint(Color.clMint)
      }
      .widgetURL(GlanceLink.url("/memories"))
      .keylineTint(Color.clMint)
    }
  }
}

enum UploadText {
  static func percent(_ st: UploadAttributes.ContentState) -> String { "\(Int((st.fraction * 100).rounded()))%" }

  /// "Đang tải 4/7 mục".
  static func progress(_ a: UploadAttributes, _ st: UploadAttributes.ContentState) -> String {
    a.text("upload.progress", "Đang tải {done}/{total} mục", ["done": "\(st.done)", "total": "\(st.total)"])
  }

  /// "Xong sẽ báo bạn", or the videos held for Wi-Fi.
  static func sub(_ a: UploadAttributes, _ st: UploadAttributes.ContentState) -> String {
    st.waitingWifi > 0
      ? a.text("upload.waiting", "{n} video chờ Wi‑Fi", ["n": "\(st.waitingWifi)"])
      : a.text("upload.notify", "Xong sẽ báo bạn")
  }
}

struct UploadBadge: View {
  var body: some View {
    Image(systemName: "arrow.up")
      .font(.system(size: 16, weight: .bold))
      .foregroundStyle(Color.clOnMint)
      .frame(width: 36, height: 36)
      .background(Color.clMint, in: Circle())
  }
}

struct UploadLockView: View {
  let a: UploadAttributes
  let st: UploadAttributes.ContentState

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 6) {
        Text(a.text("appName", "Child Life")).font(.system(size: 12, weight: .semibold))
        Text("·")
        Text(a.text("title", "Kỷ niệm")).font(.system(size: 12)).lineLimit(1)
      }
      .foregroundStyle(Color.clMuted)
      HStack(spacing: 12) {
        UploadBadge()
        VStack(alignment: .leading, spacing: 2) {
          Text(UploadText.progress(a, st)).font(.system(size: 16, weight: .semibold)).foregroundStyle(Color.clInk)
            .lineLimit(1).minimumScaleFactor(0.8)
          Text(UploadText.sub(a, st)).font(.system(size: 13)).foregroundStyle(Color.clMuted).lineLimit(1)
        }
        Spacer(minLength: 0)
        Text(UploadText.percent(st)).font(.system(size: 22, weight: .semibold).monospacedDigit())
          .foregroundStyle(Color.clMintText).lineLimit(1)
      }
      ProgressView(value: st.fraction).tint(Color.clMint)
    }
    .padding(16)
  }
}
