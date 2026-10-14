import SwiftUI

/// Child Life on Apple Watch (Figma page "Apple Watch" 464:18; plan docs/product/apple-watch-plan.md).
/// Wave 1: W01 Hôm nay, W02 Bú bình, W03 Bú mẹ, W04 Ngủ, W05 Thay tã, W06 Đã lưu, W11 Ban đêm,
/// W12 Chọn bé, W13 Chưa có mạng.
@main
struct ChildLifeWatchApp: App {
  @StateObject private var store = WatchStore()
  @Environment(\.scenePhase) private var scenePhase

  init() { WatchLink.shared.activate() }

  var body: some Scene {
    WindowGroup {
      RootView()
        .environmentObject(store)
        .onReceive(NotificationCenter.default.publisher(for: WatchLink.changed)) { _ in store.reload() }
        .onChange(of: scenePhase) { _, phase in
          guard phase == .active else { return }
          store.reload()
          Task { await store.flush() }
        }
    }
  }
}

struct RootView: View {
  @EnvironmentObject var store: WatchStore

  var body: some View {
    ZStack {
      NavigationStack(path: $store.path) {
        content
          .screenTitle(store.phase == .ready ? (store.snapshot?.nickname ?? "") : "Child Life", color: .white)
          .navigationDestination(for: WatchStore.Route.self) { route in
            switch route {
            case .bottle: BottleView()
            case .breast: BreastView()
            case .sleep: SleepView()
            case .diaper: DiaperView()
            case .babies: BabyPickerView()
            }
          }
      }
      if let saved = store.saved {
        SavedView(saved: saved)
          .transition(.opacity.combined(with: .scale(scale: 0.96)))
          .zIndex(1)
      }
    }
    .animation(.easeOut(duration: 0.2), value: store.saved)
    .alert(WatchText.t("watchFailed"), isPresented: $store.failed) {
      Button("OK", role: .cancel) {}
    }
  }

  @ViewBuilder private var content: some View {
    switch store.phase {
    case .unlinked: LinkView()
    case .cannotLog:
      Text(WatchText.t("watchCannotLog"))
        .font(.system(size: 15))
        .multilineTextAlignment(.center)
        .foregroundStyle(.secondary)
    case .ready: HomeView()
    }
  }
}

/// Not linked yet (G-092): sign in on the iPhone and the watch picks the session up.
struct LinkView: View {
  @EnvironmentObject var store: WatchStore

  var body: some View {
    ScrollView {
      VStack(spacing: 10) {
        Image(systemName: "iphone.and.arrow.forward")
          .font(.system(size: 30))
          .foregroundStyle(Color(hex: 0x3fd0c3))
        Text(WatchText.t("watchLinkTitle"))
          .font(.system(size: 17, weight: .semibold))
        Text(WatchText.t("watchLinkBody"))
          .font(.system(size: 13))
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
        #if DEBUG
        Button(WatchText.t("watchDemo")) { store.startDemo() }
          .buttonStyle(PillButtonStyle(fill: WatchColor.button))
          .padding(.top, 4)
        #endif
      }
    }
  }
}
