import SwiftUI

/// W01 Hôm nay (tiles) by day, W11 Ban đêm (dim red list) at night, with W13's banner on top
/// while writes wait for a connection. Hút sữa and Nhắc tiles come with Wave 2 (W14, W07).
struct HomeView: View {
  @EnvironmentObject var store: WatchStore

  var body: some View {
    TimelineView(.everyMinute) { context in
      ScrollView {
        VStack(spacing: 6) {
          if let s = store.snapshot, s.pending > 0 { OfflineBanner(count: s.pending) }
          if store.night(at: context.date) {
            NightList(now: context.date)
          } else {
            TileGrid(now: context.date)
          }
          Button {
            store.path.append(.babies)
          } label: {
            Text(WatchText.t("watchChooseBabyRow"))
              .font(.system(size: 13))
              .foregroundStyle(.secondary)
              .frame(maxWidth: .infinity, minHeight: 32)
          }
          .buttonStyle(.plain)
        }
      }
    }
  }
}

/// The value and caption a home tile or night row shows for one care type.
struct TileState {
  var value: String
  var caption: String
  var running = false
  var since: Date?
  /// A running timer counts up from here, in h:mm:ss (sleep, breast not paused).
  var countFrom: Date?

  static func of(_ kind: CareKind, _ s: GlanceSnapshot, now: Date) -> TileState {
    func since(_ date: Date?, _ caption: String) -> TileState {
      guard let date else { return TileState(value: "—", caption: WatchText.t("watchNoneYet")) }
      return TileState(value: WatchText.hm(now.timeIntervalSince(date)), caption: caption, since: date)
    }
    switch kind {
    case .bottle: return since(s.lastBottle?.at, WatchText.t("watchSinceFeed"))
    case .breast:
      if let t = s.breast {
        let side = t.activeSide == "right" ? "watchSideRight" : "watchSideLeft"
        return TileState(
          value: WatchText.ms(t.total(at: now)), caption: WatchText.t(side), running: true,
          countFrom: t.paused ? nil : t.displayStart(at: now))
      }
      return since(s.lastBreast?.at, WatchText.t("watchSinceFeed"))
    case .sleep:
      if let t = s.sleep {
        return TileState(
          value: WatchText.hm(now.timeIntervalSince(t.startedAt)), caption: WatchText.t("watchSleeping"),
          running: true, since: t.startedAt, countFrom: t.startedAt)
      }
      return since(s.lastWokeAt, WatchText.t("watchAwake"))
    case .diaper: return since(s.lastDiaper?.at, WatchText.t("watchSinceLast"))
    case .pump, .reminder: return TileState(value: "—", caption: WatchText.t("watchNoneYet"))
    }
  }
}

@MainActor private func open(_ kind: CareKind, _ store: WatchStore) {
  switch kind {
  case .bottle: store.path.append(.bottle)
  case .breast: store.path.append(.breast)
  case .diaper: store.path.append(.diaper)
  case .sleep:
    if store.snapshot?.sleep != nil {
      store.path.append(.sleep)
    } else {
      Task { await store.startSleep() }
    }
  case .pump, .reminder: break
  }
}

struct TileGrid: View {
  @EnvironmentObject var store: WatchStore
  let now: Date

  private let kinds: [CareKind] = [.bottle, .breast, .sleep, .diaper]

  var body: some View {
    let columns = [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)]
    LazyVGrid(columns: columns, spacing: 6) {
      ForEach(kinds) { kind in
        if let s = store.snapshot {
          Button { open(kind, store) } label: { Tile(kind: kind, state: .of(kind, s, now: now)) }
            .buttonStyle(.plain)
        }
      }
    }
  }
}

/// 91 × 79 tile: icon chip + title in the care colour, the time since, a caption. Filled with the
/// care colour while its timer runs (W01's Ngủ tile).
struct Tile: View {
  let kind: CareKind
  let state: TileState

  var body: some View {
    let filled = state.running
    VStack(alignment: .leading, spacing: 2) {
      HStack(spacing: 6) {
        CareIcon(name: kind.icon, size: 12)
          .foregroundStyle(filled ? .white : kind.accent)
          .frame(width: 21, height: 21)
          .background(Circle().fill(filled ? .white.opacity(0.22) : kind.accent.opacity(0.22)))
        Text(kind.title)
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(filled ? .white : kind.accent)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
      }
      ElapsedText(state: state)
        .font(.system(size: 18, weight: .bold).monospacedDigit())
        .foregroundStyle(.white)
        .padding(.top, 2)
      Text(state.caption)
        .font(.system(size: 11))
        .foregroundStyle(filled ? .white.opacity(0.8) : .secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
    .padding(10)
    .frame(maxWidth: .infinity, minHeight: 79, alignment: .leading)
    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(filled ? kind.accent : WatchColor.tile))
    .accessibilityElement(children: .combine)
  }
}

/// W11: rows in dim red, no colour that wakes anyone up.
struct NightList: View {
  @EnvironmentObject var store: WatchStore
  let now: Date

  private let kinds: [CareKind] = [.bottle, .breast, .diaper, .sleep]

  var body: some View {
    VStack(spacing: 6) {
      ForEach(kinds) { kind in
        if let s = store.snapshot {
          let state = TileState.of(kind, s, now: now)
          Button { open(kind, store) } label: {
            HStack {
              Text(kind.title).font(.system(size: 16, weight: .semibold))
              Spacer(minLength: 8)
              Group {
                if state.running || state.since == nil {
                  ElapsedText(state: state)
                } else {
                  Text(WatchText.t("watchAgo", ["t": state.value]))
                }
              }
              .font(.system(size: 13).monospacedDigit())
            }
            .foregroundStyle(WatchColor.nightInk)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(WatchColor.nightRow))
          }
          .buttonStyle(.plain)
        }
      }
    }
  }
}

/// W13 "Đã lưu trên đồng hồ. Sẽ gửi lên khi có mạng." + "3 lần ghi chờ gửi" (tap to retry).
struct OfflineBanner: View {
  @EnvironmentObject var store: WatchStore
  let count: Int

  var body: some View {
    VStack(spacing: 6) {
      HStack(alignment: .top, spacing: 8) {
        CareIcon(name: "Icon-cloud-off", size: 14).foregroundStyle(WatchColor.pending)
        Text(WatchText.t("watchOffline"))
          .font(.system(size: 12))
          .foregroundStyle(WatchColor.pending)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(10)
      .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(WatchColor.pendingSoft))
      Button {
        Task { await store.flush() }
      } label: {
        HStack(spacing: 8) {
          CareIcon(name: "Icon-retry", size: 14)
          Text(WatchText.t("watchPending", ["n": "\(count)"])).font(.system(size: 13, weight: .medium))
          Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 36)
        .background(Capsule().fill(WatchColor.tile))
      }
      .buttonStyle(.plain)
    }
  }
}

/// A running timer's clock; the plain value otherwise.
struct ElapsedText: View {
  let state: TileState

  var body: some View {
    if let from = state.countFrom {
      RunningClock(from: from)
    } else {
      Text(state.value)
    }
  }
}

/// "0:09:23" every second while the screen is on; "0:09" on the Always-On screen, which only
/// redraws once a minute.
struct RunningClock: View {
  let from: Date
  @Environment(\.isLuminanceReduced) private var dimmed

  var body: some View {
    TimelineView(.periodic(from: from, by: dimmed ? 60 : 1)) { context in
      let elapsed = context.date.timeIntervalSince(from)
      Text(dimmed ? WatchText.hm(elapsed) : WatchText.hms(elapsed))
    }
  }
}
