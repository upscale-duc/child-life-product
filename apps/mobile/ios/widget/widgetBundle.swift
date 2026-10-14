import SwiftUI
import WidgetKit

/// Child Life widgets (S8, Figma W1–W5): small per care type, medium quick log, large Today,
/// lock-screen accessories, the Sleep / Breast Live Activity with its Dynamic Island, and the
/// background upload Live Activity (10j), the Video kỷ niệm one (MM08), and the camera / photo-library shortcuts to Kỷ niệm.
@main
struct ChildLifeWidgets: WidgetBundle {
  var body: some Widget {
    BottleWidget()
    BreastWidget()
    SleepWidget()
    DiaperWidget()
    QuickLogWidget()
    TodayWidget()
    LockWidget()
    LockSleepWidget()
    LockFeedWidget()
    MemoryCameraWidget()
    MemoryLibraryWidget()
    CareLiveActivityWidget()
    UploadLiveActivityWidget()
    KeepsakeLiveActivityWidget()
  }
}
