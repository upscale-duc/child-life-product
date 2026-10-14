import SwiftUI

/// Double Tap (watchOS 11, Series 9+ / Ultra 2) runs the screen's main button: the moments when
/// neither hand is free (P-142 §8). Elsewhere the button works as usual.
private struct PrimaryGesture: ViewModifier {
  func body(content: Content) -> some View {
    if #available(watchOS 11.0, *) {
      content.handGestureShortcut(.primaryAction)
    } else {
      content
    }
  }
}

extension View {
  func primaryGesture() -> some View { modifier(PrimaryGesture()) }
}

// MARK: W02 Bú bình · chọn lượng

struct BottleView: View {
  @EnvironmentObject var store: WatchStore
  @State private var ml: Double = 120
  @State private var prefilled = false

  /// 90 · 120 · 150 around the last amount (the age table, P-138, is not on the watch yet).
  private var picks: [Int] {
    let base = store.snapshot?.lastBottle?.amountMl ?? 120
    return [max(10, base - 30), base, min(500, base + 30)]
  }

  var body: some View {
    let kind = CareKind.bottle
    VStack(spacing: 8) {
      VStack(spacing: 0) {
        Text("\(Int(ml))")
          .font(.system(size: 44, weight: .bold).monospacedDigit())
          .contentTransition(.numericText())
        Text(WatchText.t("watchCrownHint"))
          .font(.system(size: 11))
          .foregroundStyle(.secondary)
      }
      .focusable()
      .digitalCrownRotation(
        $ml, from: 10, through: 500, by: 10, sensitivity: .medium, isContinuous: false,
        isHapticFeedbackEnabled: true)
      HStack(spacing: 4) {
        ForEach(picks, id: \.self) { pick in
          Button("\(pick)") { ml = Double(pick) }
            .buttonStyle(ChipStyle(selected: Int(ml) == pick, accent: kind.accent))
        }
      }
      Button {
        Task { await store.logBottle(Int(ml)) }
      } label: {
        HStack(spacing: 6) {
          CareIcon(name: "Icon-check", size: 14)
          Text(WatchText.t("watchSave"))
        }
      }
      .buttonStyle(PillButtonStyle(fill: kind.accent))
      .primaryGesture()
    }
    .screenTitle(kind.title, color: kind.accent)
    .onAppear {
      guard !prefilled else { return }
      prefilled = true
      if let last = store.snapshot?.lastBottle?.amountMl { ml = Double(last) }
    }
  }
}

struct ChipStyle: ButtonStyle {
  var selected: Bool
  var accent: Color

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 14, weight: .semibold).monospacedDigit())
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity, minHeight: 28)
      .background(Capsule().fill(selected ? accent : WatchColor.tile))
      .opacity(configuration.isPressed ? 0.7 : 1)
  }
}

// MARK: W03 Bú mẹ (start screen G-094, then the running timer)

struct BreastView: View {
  @EnvironmentObject var store: WatchStore

  var body: some View {
    let kind = CareKind.breast
    Group {
      if let timer = store.snapshot?.breast {
        TimelineView(.periodic(from: .now, by: 1)) { context in
          running(timer, now: context.date)
        }
      } else {
        start
      }
    }
    .screenTitle(kind.title, color: kind.accent)
  }

  /// The side opposite the last breastfeed is suggested (as the app's sheet).
  private var suggested: String { store.snapshot?.lastBreast?.side == "left" ? "right" : "left" }

  private var start: some View {
    VStack(spacing: 8) {
      Text(WatchText.t("watchBreastStartHint"))
        .font(.system(size: 13))
        .foregroundStyle(.secondary)
      HStack(spacing: 6) {
        ForEach(["left", "right"], id: \.self) { side in
          Button {
            Task { await store.startBreast(side) }
          } label: {
            VStack(spacing: 2) {
              Text(WatchText.t(side == "left" ? "watchSideLeft" : "watchSideRight"))
                .font(.system(size: 17, weight: .semibold))
              if side == suggested {
                Text(WatchText.t("watchSuggested")).font(.system(size: 11)).opacity(0.85)
              }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(
              RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(side == suggested ? CareKind.breast.accent : WatchColor.tile))
          }
          .buttonStyle(.plain)
        }
      }
    }
  }

  private func running(_ t: GlanceTimer, now: Date) -> some View {
    let accent = CareKind.breast.accent
    let active = t.activeSide ?? "left"
    let caption = active == "right" ? "watchBreastTotalRight" : "watchBreastTotalLeft"
    return VStack(spacing: 8) {
      HStack(spacing: 6) {
        ForEach(["left", "right"], id: \.self) { side in
          let isActive = side == active
          let elapsed = (side == "left" ? t.left : t.right)?.elapsed(at: now) ?? 0
          Button {
            if !isActive { Task { await store.switchSide() } }
          } label: {
            VStack(spacing: 2) {
              Text(WatchText.t(side == "left" ? "watchSideLeft" : "watchSideRight"))
                .font(.system(size: 12, weight: .medium))
              Text(WatchText.ms(elapsed))
                .font(.system(size: 21, weight: .bold).monospacedDigit())
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(
              RoundedRectangle(cornerRadius: 16, style: .continuous).fill(isActive ? accent : WatchColor.tile))
          }
          .buttonStyle(.plain)
        }
      }
      Text(WatchText.t(caption, ["t": WatchText.ms(t.total(at: now))]))
        .font(.system(size: 11).monospacedDigit())
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
      HStack(spacing: 6) {
        Button(WatchText.t("watchSwitchSide")) { Task { await store.switchSide() } }
          .buttonStyle(PillButtonStyle(fill: WatchColor.button))
        Button(WatchText.t("watchStop")) { Task { await store.endBreast() } }
          .buttonStyle(PillButtonStyle(fill: WatchColor.danger))
          .primaryGesture()
      }
    }
  }
}

// MARK: W04 Ngủ · đang ngủ

struct SleepView: View {
  @EnvironmentObject var store: WatchStore
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    let kind = CareKind.sleep
    Group {
      if let timer = store.snapshot?.sleep {
        TimelineView(.periodic(from: .now, by: 1)) { context in
          VStack(spacing: 10) {
            ZStack {
              Circle().stroke(kind.accent.opacity(0.3), lineWidth: 6)
              // The breathing ring (R-071), still with Reduce Motion. A phase animator animates only
              // the ring's scale and opacity, never the screen's layout.
              if reduceMotion {
                Circle().stroke(kind.accent, lineWidth: 6)
              } else {
                Circle().stroke(kind.accent, lineWidth: 6)
                  .phaseAnimator([false, true]) { ring, inhale in
                    ring.scaleEffect(inhale ? 1.0 : 0.94).opacity(inhale ? 1 : 0.7)
                  } animation: { _ in .easeInOut(duration: 3) }
              }
              VStack(spacing: 2) {
                RunningClock(from: timer.startedAt)
                  .font(.system(size: 26, weight: .bold).monospacedDigit())
                  .minimumScaleFactor(0.7)
                  .lineLimit(1)
                  .padding(.horizontal, 8)
                Text(WatchText.t("watchSleepSince", ["time": WatchText.clock(timer.startedAt)]))
                  .font(.system(size: 11))
                  .foregroundStyle(.secondary)
              }
            }
            .frame(width: 110, height: 110)
            Button(WatchText.t("watchWokeUp")) { Task { await store.endSleep() } }
              .buttonStyle(PillButtonStyle(fill: kind.accent))
              .primaryGesture()
            if let until = store.sleepUndoUntil, until > context.date {
              Button(WatchText.t("watchUndo")) { Task { await store.cancelStartedSleep() } }
                .buttonStyle(PillButtonStyle(fill: .white.opacity(0.12)))
                .frame(height: 32)
            }
          }
        }
      } else {
        Text(WatchText.t("watchNoneYet")).foregroundStyle(.secondary)
      }
    }
    .screenTitle(kind.title, color: kind.accent)
    .containerBackground(kind.deep.gradient, for: .navigation)
  }
}

// MARK: W05 Thay tã

struct DiaperView: View {
  @EnvironmentObject var store: WatchStore

  var body: some View {
    let kind = CareKind.diaper
    ScrollView {
      VStack(spacing: 6) {
        row("wet", "watchDiaperWet", icon: "Icon-drop")
        row("dirty", "watchDiaperDirty", icon: "Icon-diaper")
        row("both", "watchDiaperBoth", icon: "Icon-check")
      }
    }
    .screenTitle(WatchText.t("watchDiaperTitle"), color: kind.accent)
  }

  private func row(_ kind: String, _ key: String, icon: String) -> some View {
    Button {
      Task { await store.logDiaper(kind) }
    } label: {
      HStack(spacing: 6) {
        CareIcon(name: icon, size: 14)
        Text(WatchText.t(key))
      }
      .frame(minHeight: 41)
    }
    .buttonStyle(PillButtonStyle(fill: WatchColor.tile))
  }
}

// MARK: W06 Đã lưu

struct SavedView: View {
  @EnvironmentObject var store: WatchStore
  let saved: WatchStore.Saved

  var body: some View {
    VStack(spacing: 8) {
      Spacer(minLength: 0)
      ZStack {
        Circle().fill(WatchColor.saved)
        CareIcon(name: "Icon-check", size: 30).foregroundStyle(.white)
      }
      .frame(width: 58, height: 58)
      Text(saved.title)
        .font(.system(size: 17, weight: .semibold))
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .minimumScaleFactor(0.8)
      Text(WatchText.t("watchLoggedBy", ["time": WatchText.clock(saved.at), "name": saved.by]))
        .font(.system(size: 12))
        .foregroundStyle(.secondary)
      if saved.undoRecord != nil {
        Button(WatchText.t("watchUndo")) { Task { await store.undo() } }
          .buttonStyle(PillButtonStyle(fill: WatchColor.tile))
          .frame(height: 32)
      }
      Spacer(minLength: 0)
    }
    .padding(.horizontal, 10)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
    .ignoresSafeArea()
    .contentShape(Rectangle())
    .onTapGesture { store.saved = nil }
  }
}

// MARK: W12 Chọn bé

/// The phone sends one baby today (the selected one); several babies come with the watch's own
/// snapshot (plan step 1).
struct BabyPickerView: View {
  @EnvironmentObject var store: WatchStore

  var body: some View {
    ScrollView {
      VStack(spacing: 6) {
        if let name = store.snapshot?.nickname {
          HStack(spacing: 10) {
            Text(String(name.prefix(1)))
              .font(.system(size: 15, weight: .bold))
              .foregroundStyle(Color(hex: 0x1d5f99))
              .frame(width: 30, height: 30)
              .background(Circle().fill(Color(hex: 0xffa58d)))
            Text(name).font(.system(size: 16, weight: .semibold))
            Spacer(minLength: 0)
            CareIcon(name: "Icon-check", size: 16)
          }
          .padding(.horizontal, 12)
          .frame(maxWidth: .infinity, minHeight: 53)
          .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color(hex: 0x087f7b)))
        }
        Text(WatchText.t("watchOneBabyNote"))
          .font(.system(size: 12))
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .padding(.top, 4)
      }
    }
    .screenTitle(WatchText.t("watchChooseBaby"), color: .white)
  }
}
