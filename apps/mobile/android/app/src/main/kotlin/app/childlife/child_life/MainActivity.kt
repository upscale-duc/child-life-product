package app.childlife.child_life

import android.app.Activity
import android.content.Intent
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * The Flutter host and its native channels on Android (android-plan.md):
 * - `childlife/screenshot` — FB4 (D-065): a screenshot was just taken (Android 14+; no image).
 * - `childlife/uploads` — 10j background uploads (BackgroundUploads, A3).
 * - `childlife/glance` — the session and Today snapshot for native code (Glance).
 * - `childlife/share` — photos and videos shared into the app (SharedInbox, A4).
 * - `childlife/camera` — size and length of what the system camera recorded (MediaProbe, A4).
 * - `childlife/rules` — the reminder a drawn notice opened the app with, and its action (A6).
 * - `childlife/keepsakeLive` — Video kỷ niệm progress as an ongoing notice (A6).
 */
class MainActivity : FlutterActivity() {
    private var screenshots: MethodChannel? = null
    private val screenCapture: Any? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            Activity.ScreenCaptureCallback { screenshots?.invokeMethod("taken", null) }
        } else {
            null
        }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        screenshots = MethodChannel(messenger, "childlife/screenshot")
        BackgroundUploads.register(this, messenger)
        Glance.register(this, messenger)
        SharedInbox.register(this, messenger)
        MediaProbe.register(messenger)
        PushLaunch.register(messenger)
        KeepsakeProgress.register(this, messenger)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        SharedInbox.receive(this, intent)
        PushLaunch.receive(this, intent)
        debugPin(intent)
    }

    /**
     * Debug builds only: `adb shell am start ... --es app.childlife.debugPinWidget quick` asks the
     * launcher to add a widget (it shows its own confirmation), for checking widgets on an emulator.
     */
    private fun debugPin(intent: Intent?) {
        if (!isDebuggable(this)) return
        val kind = intent?.getStringExtra("app.childlife.debugPinWidget") ?: return
        intent.removeExtra("app.childlife.debugPinWidget")
        val cls = when (kind) {
            "bottle" -> BottleWidget::class.java
            "breast" -> BreastWidget::class.java
            "sleep" -> SleepWidget::class.java
            "diaper" -> DiaperWidget::class.java
            "quick" -> QuickWidget::class.java
            "today" -> TodayWidget::class.java
            "camera" -> CameraWidget::class.java
            else -> LibraryWidget::class.java
        }
        android.appwidget.AppWidgetManager.getInstance(this)
            .requestPinAppWidget(android.content.ComponentName(this, cls), null, null)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        SharedInbox.receive(this, intent)
        PushLaunch.receive(this, intent)
        debugPin(intent)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        BackgroundUploads.unregister()
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onStart() {
        super.onStart()
        BackgroundUploads.appVisible = true
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            registerScreenCaptureCallback(mainExecutor, screenCapture as Activity.ScreenCaptureCallback)
        }
    }

    override fun onStop() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            unregisterScreenCaptureCallback(screenCapture as Activity.ScreenCaptureCallback)
        }
        BackgroundUploads.appVisible = false
        BackgroundUploads.onBackground(this)
        super.onStop()
    }
}
