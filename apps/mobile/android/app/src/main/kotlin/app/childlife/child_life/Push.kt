package app.childlife.child_life

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.google.firebase.messaging.RemoteMessage
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService
import java.util.concurrent.Executors
import org.json.JSONObject

/**
 * Pushes the app draws itself on Android (android-plan.md A6). The firebase_messaging plugin's
 * service still hands every message to Flutter; before that:
 * - rule and vaccine reminders (`draw = 1`) are drawn with the iOS category's actions — "Ghi …"
 *   opens the app on the log, "Báo lại sau 15 phút" / "Bỏ qua lần này" / "Nhắc lại sáng mai"
 *   answer the Function from here without opening it (as ios/Runner/RuleNotifications.swift);
 * - a Video kỷ niệm being made (`keepsakeProgress`) keeps an ongoing progress notice (MM08).
 * Titles and bodies come from the server in the device's language; button labels from the
 * glance copy (ARB). Ids and counts only, never a photo or a caption.
 */
class PushService : FlutterFirebaseMessagingService() {
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        val data = remoteMessage.data
        runCatching {
            when {
                data["kind"] == "keepsakeProgress" -> KeepsakeProgress.fromPush(applicationContext, data)
                data["draw"] == "1" -> {
                    // Open on Hôm nay: Flutter shows 1g at once instead (push_registration.dart).
                    val ruleInFront = data["kind"] == "reminderRule" && BackgroundUploads.appVisible
                    if (!ruleInFront) PushNotices.show(applicationContext, data)
                }
            }
        }
        super.onMessageReceived(remoteMessage)
    }
}

object PushNotices {
    const val CHANNEL = "reminders"
    const val EXTRA_PUSH = "app.childlife.push"
    const val EXTRA_ACTION = "app.childlife.pushAction"
    private const val ACTION_ANSWER = "app.childlife.ANSWER"

    fun ensureChannel(context: Context) {
        val nm = context.getSystemService(NotificationManager::class.java)
        if (nm.getNotificationChannel(CHANNEL) != null) return
        // Dart creates it in the app language (AndroidChannels); this is the first-run fallback.
        nm.createNotificationChannel(NotificationChannel(CHANNEL, "Nhắc việc", NotificationManager.IMPORTANCE_HIGH))
    }

    private fun json(data: Map<String, String>) = JSONObject(data as Map<*, *>).toString()

    /** Opens the app with the push (and the action that was chosen, if any). */
    private fun open(context: Context, data: Map<String, String>, action: String?, request: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
            .setAction("app.childlife.PUSH.$request")
            .putExtra(EXTRA_PUSH, json(data))
            .putExtra(EXTRA_ACTION, action)
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        return PendingIntent.getActivity(context, request, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
    }

    /** Answers the Function in the background (PushActionReceiver). */
    private fun answer(context: Context, data: Map<String, String>, action: String, request: Int): PendingIntent {
        val intent = Intent(context, PushActionReceiver::class.java)
            .setAction("$ACTION_ANSWER.$request")
            .putExtra(EXTRA_PUSH, json(data))
            .putExtra(EXTRA_ACTION, action)
        return PendingIntent.getBroadcast(context, request, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
    }

    fun tagOf(data: Map<String, String>) = data["tag"]?.takeIf { it.isNotEmpty() } ?: data["kind"] ?: "push"

    fun show(context: Context, data: Map<String, String>) {
        ensureChannel(context)
        val nm = NotificationManagerCompat.from(context)
        if (!nm.areNotificationsEnabled()) return
        val tag = tagOf(data)
        val base = tag.hashCode() and 0x0FFFFFFF
        fun label(key: String, fallback: String) = Glance.text(context, key, fallback)
        val b = NotificationCompat.Builder(context, CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_notify)
            .setColor(context.getColor(R.color.notify_accent))
            .setContentTitle(data["title"] ?: "")
            .setContentText(data["body"] ?: "")
            .setStyle(NotificationCompat.BigTextStyle().bigText(data["body"] ?: ""))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setAutoCancel(true)
            .setContentIntent(open(context, data, null, base))
        when (data["kind"]) {
            "reminderRule" -> {
                val log = when (data["type"]) {
                    "sleep" -> label("rule.log.sleep", "Ghi giấc ngủ")
                    "diaper" -> label("rule.log.diaper", "Ghi thay tã")
                    "pump" -> label("rule.log.pump", "Ghi hút sữa")
                    else -> label("rule.log.feed", "Ghi lần bú")
                }
                b.addAction(0, log, open(context, data, "log", base + 1))
                b.addAction(0, label("rule.snooze", "Báo lại sau 15 phút"), answer(context, data, "snooze", base + 2))
                b.addAction(0, label("rule.skip", "Bỏ qua lần này"), answer(context, data, "skip", base + 3))
            }
            "careTaskDue" -> {
                // Figma N1: "Xong" opens the app when a task writes a log or starts the sleep
                // timer (D-138), else answers from here; "Nhắc lại 10 phút" draws it again later.
                val done = label("ct.done", "Xong")
                b.addAction(0, done,
                    if (data["opensApp"] == "1") open(context, data, "done", base + 1)
                    else answer(context, data, "ctDone", base + 1))
                b.addAction(0, label("ct.snooze", "Nhắc lại 10 phút"), answer(context, data, "ctSnooze", base + 2))
            }
            "vaccine" -> {
                b.addAction(0, label("vx.view", "Xem lịch tiêm"), open(context, data, "view", base + 1))
                b.addAction(0, label("vx.snooze", "Nhắc lại sáng mai"), answer(context, data, "vxSnooze", base + 2))
                b.addAction(0, label("vx.move", "Dời lịch"), open(context, data, "move", base + 3))
            }
        }
        runCatching { nm.notify(tag, 0, b.build()) }
    }

    fun cancel(context: Context, data: Map<String, String>) =
        NotificationManagerCompat.from(context).cancel(tagOf(data), 0)

    fun dataOf(json: String?): Map<String, String>? = json?.let {
        runCatching {
            val o = JSONObject(it)
            o.keys().asSequence().associateWith { k -> o.optString(k) }
        }.getOrNull()
    }
}

/** "Báo lại sau 15 phút", "Bỏ qua lần này", "Nhắc lại sáng mai": answered without opening the app. */
class PushActionReceiver : BroadcastReceiver() {
    private val io = Executors.newSingleThreadExecutor()

    override fun onReceive(context: Context, intent: Intent) {
        val data = PushNotices.dataOf(intent.getStringExtra(PushNotices.EXTRA_PUSH)) ?: return
        val action = intent.getStringExtra(PushNotices.EXTRA_ACTION) ?: return
        val app = context.applicationContext
        if (action == "ctShow") {
            PushNotices.show(app, data)
            return
        }
        PushNotices.cancel(app, data)
        if (action == "ctSnooze") {
            snooze(app, intent)
            return
        }
        val pending = goAsync()
        io.execute {
            try {
                answer(app, data, action)
            } finally {
                pending.finish()
            }
        }
    }

    /** "Nhắc lại 10 phút": the same notice, drawn again in ten minutes. */
    private fun snooze(context: Context, intent: Intent) {
        val again = Intent(context, PushActionReceiver::class.java)
            .setAction("app.childlife.CT_SHOW.${System.currentTimeMillis()}")
            .putExtra(PushNotices.EXTRA_PUSH, intent.getStringExtra(PushNotices.EXTRA_PUSH))
            .putExtra(PushNotices.EXTRA_ACTION, "ctShow")
        val pending = PendingIntent.getBroadcast(context, 0, again,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        val alarms = context.getSystemService(android.app.AlarmManager::class.java)
        alarms.setAndAllowWhileIdle(android.app.AlarmManager.RTC_WAKEUP,
            System.currentTimeMillis() + 10 * 60_000L, pending)
    }

    private fun answer(context: Context, data: Map<String, String>, action: String) {
        val snap = Glance.snapshot(context) ?: return
        val project = snap.optString("projectId").takeIf { it.isNotEmpty() } ?: return
        val emulator = snap.optString("emulatorHost").takeIf { it.isNotEmpty() && !snap.isNull("emulatorHost") }
        val client = CallableClient(project, emulator)
        var token = AuthToken.idToken(context) ?: return
        for (call in requests(data, action)) {
            var status = client.call(call.first, token, call.second)
            if (status == 401) {
                token = AuthToken.idToken(context, force = true) ?: return
                status = client.call(call.first, token, call.second)
            }
            debugTrace(context, "${call.first} answered $status")
        }
    }

    companion object {
        /** Every call an action makes: one per task for a task push's "Xong". */
        fun requests(data: Map<String, String>, action: String): List<Pair<String, Map<String, Any?>>> {
            if (action != "ctDone") return listOfNotNull(request(data, action))
            val babyId = data["babyId"] ?: return emptyList()
            val date = data["date"] ?: return emptyList()
            return (data["items"] ?: "").split(',').filter { it.isNotEmpty() }.map {
                "setCarePlanItemStatus" to mapOf("babyId" to babyId, "date" to date, "itemId" to it, "status" to "done")
            }
        }

        /** The Function and its data for an action (the same requests as iOS). */
        fun request(data: Map<String, String>, action: String): Pair<String, Map<String, Any?>>? {
            val babyId = data["babyId"] ?: return null
            return when (action) {
                "snooze", "skip" -> {
                    val ruleId = data["ruleId"] ?: return null
                    val dueAt = data["dueAt"]?.toLongOrNull() ?: return null
                    "answerRuleReminder" to buildMap {
                        put("babyId", babyId)
                        put("ruleId", ruleId)
                        put("action", action)
                        put("dueAt", dueAt)
                        if (action == "snooze") put("minutes", 15)
                    }
                }
                "vxSnooze" -> "snoozeVaccine" to mapOf("babyId" to babyId, "date" to (data["date"] ?: return null))
                else -> null
            }
        }
    }
}

/**
 * `childlife/rules` on Android: the push a drawn notice opened the app with, and the action
 * chosen on it ("log", "view", "move"), each taken once — what iOS's takeLaunchAction gives.
 */
object PushLaunch {
    @Volatile private var push: Map<String, String>? = null
    @Volatile private var action: Map<String, String>? = null
    @Volatile private var channel: MethodChannel? = null

    fun register(messenger: BinaryMessenger) {
        val c = MethodChannel(messenger, "childlife/rules")
        channel = c
        c.setMethodCallHandler { call, result ->
            when (call.method) {
                "takeLaunchAction" -> result.success(action.also { action = null })
                "takeTappedPush" -> result.success(push.also { push = null })
                "refreshCategories" -> result.success(null)
                else -> result.notImplemented()
            }
        }
    }

    fun receive(context: Context, intent: Intent?) {
        // Debug builds only: `adb shell am start ... --es app.childlife.debugDraw '<push data>'`
        // draws a push as if FCM had brought it (the emulator suite sends none).
        if (isDebuggable(context)) {
            PushNotices.dataOf(intent?.getStringExtra("app.childlife.debugDraw"))?.let { data ->
                intent?.removeExtra("app.childlife.debugDraw")
                if (data["kind"] == "keepsakeProgress") KeepsakeProgress.fromPush(context, data)
                else PushNotices.show(context, data)
                return
            }
        }
        val data = PushNotices.dataOf(intent?.getStringExtra(PushNotices.EXTRA_PUSH)) ?: return
        val chosen = intent?.getStringExtra(PushNotices.EXTRA_ACTION)
        intent?.removeExtra(PushNotices.EXTRA_PUSH)
        PushNotices.cancel(context, data)
        push = data
        action = chosen?.let {
            mapOf("action" to it, "babyId" to (data["babyId"] ?: ""), "ruleId" to (data["ruleId"] ?: ""),
                "type" to (data["type"] ?: ""))
        }
        channel?.invokeMethod("tapped", null)
    }
}

/** MM08 on Android: a Video kỷ niệm being made, as an ongoing progress notice. */
object KeepsakeProgress {
    private const val PREFS = "childlife.keepsake"
    private val main = android.os.Handler(android.os.Looper.getMainLooper())

    fun register(context: Context, messenger: BinaryMessenger) {
        val app = context.applicationContext
        MethodChannel(messenger, "childlife/keepsakeLive").setMethodCallHandler { call, result ->
            val a = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
            when (call.method) {
                "start" -> {
                    (a["copy"] as? Map<*, *>)?.let { copy ->
                        app.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                            .putString("copy", JSONObject(copy).toString()).apply()
                    }
                    show(app, a["jobId"] as? String ?: "", a["babyId"] as? String ?: "", "queued", null, 0)
                    result.success(true)
                }
                "update" -> {
                    val jobId = a["jobId"] as? String ?: ""
                    show(app, jobId, babyOf(app, jobId), a["status"] as? String ?: "queued", a["step"] as? String,
                        (a["progress"] as? Number)?.toInt() ?: 0)
                    result.success(null)
                }
                "resume" -> result.success(null)
                else -> result.notImplemented()
            }
        }
    }

    fun fromPush(context: Context, data: Map<String, String>) {
        main.post {
            show(context, data["jobId"] ?: return@post, data["babyId"] ?: "", data["status"] ?: "queued",
                data["step"]?.takeIf { it.isNotEmpty() }, data["progress"]?.toIntOrNull() ?: 0)
        }
    }

    private fun copy(context: Context, key: String, fallback: String): String =
        runCatching {
            JSONObject(context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString("copy", "{}")!!)
                .optString(key).takeIf { it.isNotEmpty() }
        }.getOrNull() ?: fallback

    private fun babyOf(context: Context, jobId: String) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString("baby.$jobId", "") ?: ""

    fun show(context: Context, jobId: String, babyId: String, status: String, step: String?, progress: Int) {
        if (jobId.isEmpty()) return
        val nm = NotificationManagerCompat.from(context)
        val tag = "ks-$jobId"
        // Finished or failed: the "Video đã sẵn sàng" / failure push says so; the progress goes.
        if (status == "completed" || status == "failed") {
            nm.cancel(tag, 0)
            return
        }
        if (babyId.isNotEmpty()) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString("baby.$jobId", babyId).apply()
        }
        BackgroundUploads.ensureChannel(context)
        if (!nm.areNotificationsEnabled()) return
        val text = when (step) {
            "arrange" -> copy(context, "arrange", "Đang sắp ảnh")
            "compose" -> copy(context, "compose", "Đang ghép video")
            "export" -> copy(context, "export", "Đang xuất video")
            else -> copy(context, "queued", "Đang chờ tạo")
        }
        val link = Uri.parse("${context.packageName}://app/memories/video/job/$jobId?baby=${babyId.ifEmpty { babyOf(context, jobId) }}")
        val open = PendingIntent.getActivity(context, tag.hashCode(),
            Intent(context, MainActivity::class.java).setAction(Intent.ACTION_VIEW).setData(link)
                .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        val n = NotificationCompat.Builder(context, BackgroundUploads.CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_notify)
            .setColor(context.getColor(R.color.notify_accent))
            .setContentTitle(copy(context, "title", "Video kỷ niệm"))
            .setContentText("$text · $progress%")
            .setProgress(100, progress.coerceIn(0, 100), status == "queued")
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setContentIntent(open)
            .build()
        runCatching { nm.notify(tag, 0, n) }
    }
}

fun isDebuggable(context: Context) =
    context.applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE != 0

/** Debug builds only, and only names and status codes (nothing about the child). */
fun debugTrace(context: Context, message: String) {
    if (isDebuggable(context)) android.util.Log.i("CLPush", message)
}
