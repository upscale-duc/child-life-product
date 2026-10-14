import ActivityKit
import SwiftUI
import WidgetKit

/// MM08 as a Live Activity: a Video kỷ niệm being made, then ready (or not). The step and a bar
/// while it renders; tapping opens the job (MM08 / MM09 / MM14). No photo, no baby name.
struct KeepsakeLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: KeepsakeJobAttributes.self) { context in
      KeepsakeLockView(a: context.attributes, st: context.state)
        .activityBackgroundTint(Color.clSurface)
        .activitySystemActionForegroundColor(Color.clInk)
        .widgetURL(KeepsakeText.link(context.attributes))
    } dynamicIsland: { context in
      let a = context.attributes
      let st = context.state
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          KeepsakeBadge(st: st).padding(.leading, 4)
        }
        DynamicIslandExpandedRegion(.trailing) {
          if KeepsakeText.running(st) {
            Text(KeepsakeText.percent(st)).font(.system(size: 20, weight: .semibold).monospacedDigit())
              .foregroundStyle(Color.clMint).lineLimit(1)
          }
        }
        DynamicIslandExpandedRegion(.center) {
          VStack(alignment: .leading, spacing: 2) {
            Text(KeepsakeText.line(a, st)).font(.system(size: 15, weight: .semibold)).lineLimit(1)
              .minimumScaleFactor(0.8)
            Text(KeepsakeText.sub(a, st)).font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(1)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        DynamicIslandExpandedRegion(.bottom) {
          if KeepsakeText.running(st) {
            ProgressView(value: KeepsakeText.fraction(st)).tint(Color.clMint).padding(.horizontal, 4)
          }
        }
      } compactLeading: {
        Image(systemName: KeepsakeText.symbol(st)).foregroundStyle(KeepsakeText.tint(st))
      } compactTrailing: {
        if KeepsakeText.running(st) {
          Text(KeepsakeText.percent(st)).monospacedDigit().foregroundStyle(Color.clMint).lineLimit(1)
            .minimumScaleFactor(0.7).frame(width: 44, alignment: .trailing)
        } else {
          Image(systemName: st.status == "completed" ? "checkmark" : "arrow.clockwise")
            .foregroundStyle(KeepsakeText.tint(st))
        }
      } minimal: {
        if KeepsakeText.running(st) {
          ProgressView(value: KeepsakeText.fraction(st)) {
            Image(systemName: "film").font(.system(size: 8, weight: .bold))
          }
          .progressViewStyle(.circular).tint(Color.clMint)
        } else {
          Image(systemName: KeepsakeText.symbol(st)).foregroundStyle(KeepsakeText.tint(st))
        }
      }
      .widgetURL(KeepsakeText.link(a))
      .keylineTint(Color.clMint)
    }
  }
}

enum KeepsakeText {
  static func running(_ st: KeepsakeJobAttributes.ContentState) -> Bool {
    st.status == "queued" || st.status == "rendering"
  }

  static func fraction(_ st: KeepsakeJobAttributes.ContentState) -> Double {
    min(1, max(0, Double(st.progress) / 100))
  }

  static func percent(_ st: KeepsakeJobAttributes.ContentState) -> String { "\(st.progress)%" }

  /// "Đang dựng video", "Video đã sẵn sàng", "Chưa tạo được video".
  static func line(_ a: KeepsakeJobAttributes, _ st: KeepsakeJobAttributes.ContentState) -> String {
    switch st.status {
    case "completed": return a.copyText("completed", "Video đã sẵn sàng")
    case "failed": return a.copyText("failed", "Chưa tạo được video")
    case "queued": return a.copyText("queued", "Đang chờ tạo video")
    default:
      switch st.step {
      case "compose": return a.copyText("compose", "Đang ghép nhạc và chữ")
      case "export": return a.copyText("export", "Đang xuất video")
      default: return a.copyText("arrange", "Đang sắp xếp ảnh")
      }
    }
  }

  /// The template while it renders; what a tap does once it is done.
  static func sub(_ a: KeepsakeJobAttributes, _ st: KeepsakeJobAttributes.ContentState) -> String {
    switch st.status {
    case "completed": return a.copyText("completedSub", "Chạm để xem, lưu và chia sẻ")
    case "failed": return a.copyText("failedSub", "Chạm để thử lại")
    default: return a.copyText("template", a.copyText("title", "Video kỷ niệm"))
    }
  }

  static func symbol(_ st: KeepsakeJobAttributes.ContentState) -> String {
    switch st.status {
    case "completed": return "checkmark.circle.fill"
    case "failed": return "exclamationmark.circle.fill"
    default: return "film"
    }
  }

  static func tint(_ st: KeepsakeJobAttributes.ContentState) -> Color {
    st.status == "failed" ? Color.clPending : Color.clMint
  }

  static func link(_ a: KeepsakeJobAttributes) -> URL {
    GlanceLink.url("/memories/video/job/\(a.jobId)?baby=\(a.babyId)")
  }
}

struct KeepsakeBadge: View {
  let st: KeepsakeJobAttributes.ContentState

  var body: some View {
    Image(systemName: st.status == "completed" ? "checkmark" : st.status == "failed" ? "exclamationmark" : "film")
      .font(.system(size: 15, weight: .bold))
      .foregroundStyle(Color.clOnMint)
      .frame(width: 36, height: 36)
      .background(KeepsakeText.tint(st), in: Circle())
  }
}

struct KeepsakeLockView: View {
  let a: KeepsakeJobAttributes
  let st: KeepsakeJobAttributes.ContentState

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 6) {
        Text(a.copyText("appName", "Child Life")).font(.system(size: 12, weight: .semibold))
        Text("·")
        Text(a.copyText("title", "Video kỷ niệm")).font(.system(size: 12)).lineLimit(1)
      }
      .foregroundStyle(Color.clMuted)
      HStack(spacing: 12) {
        KeepsakeBadge(st: st)
        VStack(alignment: .leading, spacing: 2) {
          Text(KeepsakeText.line(a, st)).font(.system(size: 16, weight: .semibold)).foregroundStyle(Color.clInk)
            .lineLimit(1).minimumScaleFactor(0.8)
          Text(KeepsakeText.sub(a, st)).font(.system(size: 13)).foregroundStyle(Color.clMuted).lineLimit(1)
        }
        Spacer(minLength: 0)
        if KeepsakeText.running(st) {
          Text(KeepsakeText.percent(st)).font(.system(size: 22, weight: .semibold).monospacedDigit())
            .foregroundStyle(Color.clMintText).lineLimit(1)
        }
      }
      if KeepsakeText.running(st) {
        ProgressView(value: KeepsakeText.fraction(st)).tint(Color.clMint)
      }
    }
    .padding(16)
  }
}
