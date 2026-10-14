package app.childlife.child_life

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * Home-screen widgets W1–W5 on Android (android-plan.md A5, D-004 — mirroring iOS's
 * ios/widget/CareWidgets.swift and MemoryWidgets.swift): small Bú bình / Bú mẹ / Giấc ngủ / Thay
 * tã, medium "Ghi nhanh", large "Hôm nay", and the camera / photo shortcuts; plus the ongoing
 * timer notice that stands in for the Live Activity on the lock screen (Q-064). Drawn with
 * RemoteViews from the glance snapshot; buttons log through GlanceActions without opening the
 * app; everything else opens the app on the route iOS opens.
 */
object GlanceUi {
    private val care = listOf("bottle", "breast", "sleep", "diaper")

    // ---------- Refresh ----------

    /** Redraws every widget and the timer notice; called whenever the snapshot changes. */
    fun refresh(context: Context) {
        val app = context.applicationContext
        val manager = AppWidgetManager.getInstance(app)
        val snap = Glance.snapshot(app)?.let(::Snap)
        val now = System.currentTimeMillis()
        fun each(cls: Class<*>, draw: (Snap?) -> RemoteViews) {
            val ids = runCatching { manager.getAppWidgetIds(ComponentName(app, cls)) }.getOrDefault(IntArray(0))
            if (ids.isNotEmpty()) {
                runCatching { manager.updateAppWidget(ids, draw(snap)) }
                    .onFailure { debugTrace(app, "widget ${cls.simpleName}: ${it.javaClass.simpleName}") }
            }
        }
        each(BottleWidget::class.java) { small(app, "bottle", it, now) }
        each(BreastWidget::class.java) { small(app, "breast", it, now) }
        each(SleepWidget::class.java) { small(app, "sleep", it, now) }
        each(DiaperWidget::class.java) { small(app, "diaper", it, now) }
        each(QuickWidget::class.java) { quick(app, it, now) }
        each(TodayWidget::class.java) { today(app, it, now) }
        each(CameraWidget::class.java) { shortcut(app, "camera", it) }
        each(LibraryWidget::class.java) { shortcut(app, "library", it) }
        runCatching { TimerNotice.sync(app, snap) }
    }

    private val main = android.os.Handler(android.os.Looper.getMainLooper())

    /**
     * "Hoàn tác" shows for 5 s, then the normal state again: redrawn from this process when it is
     * still there, else by a short WorkManager job (an inexact alarm may come minutes late, and a
     * receiver held for it would hold up the Undo tap, since broadcasts come one at a time).
     */
    fun refreshAfterUndo(context: Context) {
        val app = context.applicationContext
        main.postDelayed({ Thread { refresh(app) }.start() }, Snap.UNDO_MS + 300)
        WorkManager.getInstance(app).enqueueUniqueWork(
            "glance.undo", androidx.work.ExistingWorkPolicy.REPLACE,
            androidx.work.OneTimeWorkRequestBuilder<GlanceRefreshWorker>()
                .setInitialDelay(Snap.UNDO_MS + 1_000, TimeUnit.MILLISECONDS).build(),
        )
    }

    /** Every 15 minutes while widgets are placed: "45 phút trước" moves on, offline logs go up. */
    fun schedule(context: Context) {
        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            "glance.refresh", ExistingPeriodicWorkPolicy.KEEP,
            PeriodicWorkRequestBuilder<GlanceRefreshWorker>(15, TimeUnit.MINUTES).build(),
        )
    }

    // ---------- Links and buttons ----------

    private fun link(context: Context, path: String): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
            .setAction(Intent.ACTION_VIEW)
            .setData(Uri.parse("${context.packageName}://app$path"))
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        return PendingIntent.getActivity(context, path.hashCode(), intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
    }

    fun action(context: Context, op: String): PendingIntent {
        val intent = Intent(context, GlanceActionReceiver::class.java).setAction("app.childlife.glance.$op")
        return PendingIntent.getBroadcast(context, op.hashCode(), intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
    }

    /** The app's own log for [type] over Hôm nay; read-only members just get Hôm nay. */
    private fun logPath(s: Snap, type: String) = if (s.canLog) "/today?log=$type" else "/today"

    // ---------- Palette ----------

    // Plain lookups (no reflection), so release shrinking keeps every resource.
    private fun soft(t: String) = when (t) {
        "bottle" -> R.drawable.widget_bg_bottle
        "breast" -> R.drawable.widget_bg_breast
        "sleep" -> R.drawable.widget_bg_sleep
        else -> R.drawable.widget_bg_diaper
    }
    private fun pill(t: String) = when (t) {
        "bottle" -> R.drawable.widget_pill_bottle
        "breast" -> R.drawable.widget_pill_breast
        "sleep" -> R.drawable.widget_pill_sleep
        else -> R.drawable.widget_pill_diaper
    }
    private fun badge(t: String) = when (t) {
        "bottle" -> R.drawable.widget_badge_bottle
        "breast" -> R.drawable.widget_badge_breast
        "sleep" -> R.drawable.widget_badge_sleep
        else -> R.drawable.widget_badge_diaper
    }
    private fun art(t: String) = when (t) {
        "bottle" -> R.drawable.widget_art_bottle
        "breast" -> R.drawable.widget_art_breast
        "sleep" -> R.drawable.widget_art_sleep
        else -> R.drawable.widget_art_diaper
    }
    private fun inkRes(t: String) = when (t) {
        "bottle" -> R.color.care_bottle_ink
        "breast" -> R.color.care_breast_ink
        "sleep" -> R.color.care_sleep_ink
        else -> R.color.care_diaper_ink
    }

    /** White, or a palette colour by resource so Android 12+ picks Light or Night care itself. */
    private const val WHITE = 0

    private fun color(context: Context, v: RemoteViews, id: Int, res: Int) {
        when {
            res == WHITE -> v.setTextColor(id, 0xFFFFFFFF.toInt())
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ->
                v.setColorInt(id, "setTextColor", themed(context, res, night = false), themed(context, res, night = true))
            else -> v.setTextColor(id, context.getColor(res))
        }
    }

    /** A colour as Light or Night care defines it, whatever the phone shows now. */
    private fun themed(context: Context, res: Int, night: Boolean): Int {
        val config = android.content.res.Configuration(context.resources.configuration)
        config.uiMode = (config.uiMode and android.content.res.Configuration.UI_MODE_NIGHT_MASK.inv()) or
            (if (night) android.content.res.Configuration.UI_MODE_NIGHT_YES else android.content.res.Configuration.UI_MODE_NIGHT_NO)
        return context.createConfigurationContext(config).getColor(res)
    }

    /** The ids of one tile: the tile, its badge, label and meta. */
    private fun tileIds(t: String) = when (t) {
        "bottle" -> listOf(R.id.tile_bottle, R.id.tile_bottle_badge, R.id.tile_bottle_label, R.id.tile_bottle_meta)
        "breast" -> listOf(R.id.tile_breast, R.id.tile_breast_badge, R.id.tile_breast_label, R.id.tile_breast_meta)
        "sleep" -> listOf(R.id.tile_sleep, R.id.tile_sleep_badge, R.id.tile_sleep_label, R.id.tile_sleep_meta)
        else -> listOf(R.id.tile_diaper, R.id.tile_diaper_badge, R.id.tile_diaper_label, R.id.tile_diaper_meta)
    }

    /** The ids of one recent row: dot, time, text, by. */
    private fun recentIds(n: Int) = when (n) {
        1 -> listOf(R.id.recent1_dot, R.id.recent1_time, R.id.recent1_text, R.id.recent1_by)
        2 -> listOf(R.id.recent2_dot, R.id.recent2_time, R.id.recent2_text, R.id.recent2_by)
        else -> listOf(R.id.recent3_dot, R.id.recent3_time, R.id.recent3_text, R.id.recent3_by)
    }

    private fun button(context: Context, v: RemoteViews, id: Int, text: String, bg: Int, colorRes: Int, click: PendingIntent) {
        v.setViewVisibility(id, View.VISIBLE)
        v.setTextViewText(id, text)
        v.setInt(id, "setBackgroundResource", bg)
        color(context, v, id, colorRes)
        v.setOnClickPendingIntent(id, click)
    }

    private fun hideButtons(v: RemoteViews) {
        for (id in listOf(R.id.btn1, R.id.btn2, R.id.btn3)) v.setViewVisibility(id, View.GONE)
    }

    private fun chrono(v: RemoteViews, id: Int, elapsedMs: Long, running: Boolean) {
        v.setViewVisibility(id, View.VISIBLE)
        v.setChronometer(id, SystemClock.elapsedRealtime() - elapsedMs, null, running)
    }

    // ---------- Small (W1) ----------

    /** Empty / signed-out (81:608, 81:625). */
    private fun special(context: Context, s: Snap?): RemoteViews {
        val v = RemoteViews(context.packageName, R.layout.widget_small)
        val signedIn = s?.signedIn == true
        v.setInt(R.id.root, "setBackgroundResource", R.drawable.widget_bg)
        v.setTextViewText(R.id.title, s?.text("appName", "Child Life") ?: "Child Life")
        color(context, v, R.id.title, R.color.cl_mint_text)
        v.setViewVisibility(R.id.art, View.GONE)
        v.setViewVisibility(R.id.check, View.GONE)
        v.setViewVisibility(R.id.chrono, View.GONE)
        v.setTextViewText(R.id.big, if (signedIn) s!!.text("emptyTitle", "Hôm nay chưa ghi")
            else s?.text("signedOutTitle", "Đăng nhập để dùng widget") ?: "Đăng nhập để dùng widget")
        v.setTextViewText(R.id.sub, if (signedIn) s!!.text("emptySub", "Ghi cữ đầu tiên nhé")
            else s?.text("openApp", "Mở app") ?: "Mở app")
        hideButtons(v)
        val open = link(context, if (signedIn) "/today" else "/")
        button(context, v, R.id.btn1, if (signedIn) s!!.text("quickLog", "+ Ghi nhanh")
            else s?.text("openChildLife", "Mở Child Life") ?: "Mở Child Life",
            R.drawable.widget_pill_mint, R.color.cl_on_mint, open)
        v.setOnClickPendingIntent(R.id.root, open)
        return v
    }

    fun small(context: Context, type: String, s: Snap?, now: Long): RemoteViews {
        if (s == null || !s.signedIn || s.isEmpty) return special(context, s)
        val f = GlanceFormat(s)
        val v = RemoteViews(context.packageName, R.layout.widget_small)
        val white = WHITE
        val inkColor = inkRes(type)
        v.setInt(R.id.root, "setBackgroundResource", R.drawable.widget_bg)
        color(context, v, R.id.title, inkColor)
        v.setViewVisibility(R.id.art, View.VISIBLE)
        v.setImageViewResource(R.id.art, art(type))
        v.setViewVisibility(R.id.check, View.GONE)
        v.setViewVisibility(R.id.chrono, View.GONE)
        v.setViewVisibility(R.id.big, View.VISIBLE)
        color(context, v, R.id.chrono, inkColor)
        hideButtons(v)
        fun checked() {
            v.setViewVisibility(R.id.art, View.GONE)
            v.setViewVisibility(R.id.check, View.VISIBLE)
            v.setInt(R.id.check, "setBackgroundResource", badge(type))
            v.setInt(R.id.root, "setBackgroundResource", soft(type))
        }
        fun loggedState(logged: Logged, title: String, second: String) {
            v.setTextViewText(R.id.title, title)
            checked()
            v.setTextViewText(R.id.big, s.text("justNow", "Vừa xong"))
            v.setTextViewText(R.id.sub, s.text("logged", mapOf("what" to logged.label, "name" to s.text("you", "Bạn"))))
            button(context, v, R.id.btn1, s.text("undo", "Hoàn tác"), R.drawable.widget_pill_surface, inkColor,
                action(context, "undo:${logged.recordId}"))
            button(context, v, R.id.btn2, second, pill(type), white, link(context, "/care/record/${logged.recordId}"))
            v.setOnClickPendingIntent(R.id.root, link(context, "/care/record/${logged.recordId}"))
        }
        when (type) {
            "bottle" -> {
                val logged = s.loggedNow("bottle", now)
                if (logged != null) {
                    loggedState(logged, s.text("bottle", "Bú bình"), s.text("edit", "Sửa"))
                } else {
                    v.setTextViewText(R.id.title, s.text("bottle", "Bú bình"))
                    val l = s.lastBottle
                    v.setTextViewText(R.id.big, l?.let { f.ago(it.at, now) } ?: s.text("noneYet", "Chưa có"))
                    v.setTextViewText(R.id.sub, l?.let { listOfNotNull(it.amountMl?.let { ml -> "$ml ml" }, f.by(it.by)).joinToString(" · ") } ?: "")
                    if (s.canLog) {
                        val label = l?.amountMl?.let { s.text("plusMl", mapOf("ml" to "$it")) } ?: s.text("quickLog", "+ Ghi nhanh")
                        button(context, v, R.id.btn1, label, pill(type), white, action(context, "bottle"))
                    }
                    v.setOnClickPendingIntent(R.id.root, link(context, logPath(s, "bottle")))
                }
            }
            "breast" -> {
                val t = s.breast
                if (t != null) {
                    v.setTextViewText(R.id.title, s.text("feeding", "Đang bú"))
                    v.setInt(R.id.root, "setBackgroundResource", soft(type))
                    v.setViewVisibility(R.id.big, View.GONE)
                    chrono(v, R.id.chrono, t.totalMs(now), !t.paused)
                    v.setTextViewText(R.id.sub, "${s.text("breastSide.${t.activeSide ?: "left"}", "")} · " +
                        s.text("sinceTime", mapOf("time" to f.time(t.startedAt))))
                    if (s.canLog) {
                        button(context, v, R.id.btn1, s.text("switchSide", "Đổi bên"), R.drawable.widget_pill_surface, inkColor,
                            action(context, "switch"))
                        button(context, v, R.id.btn2, s.text("done", "Xong"), pill(type), white, action(context, "end:breast"))
                    }
                    v.setOnClickPendingIntent(R.id.root, link(context, "/care/timer/breast"))
                } else {
                    v.setTextViewText(R.id.title, s.text("breast", "Bú mẹ"))
                    val l = s.lastBreast
                    if (l != null) {
                        val fresh = now - l.at < 300_000
                        v.setTextViewText(R.id.big, if (fresh) s.text("justNow", "Vừa xong") else f.duration(now - l.at))
                        val dur = f.duration((l.durationMin ?: 0) * 60_000L)
                        v.setTextViewText(R.id.sub, if (fresh) s.text("fedFor", mapOf("t" to dur, "name" to l.by))
                            else s.text("agoFor", mapOf("t" to dur)))
                    } else {
                        v.setTextViewText(R.id.big, s.text("noneYet", "Chưa có"))
                        v.setTextViewText(R.id.sub, "")
                    }
                    if (s.canLog) {
                        button(context, v, R.id.btn1, s.text("startBreast", "Bắt đầu bú"), pill(type), white, action(context, "start:breast"))
                    }
                    v.setOnClickPendingIntent(R.id.root, link(context, logPath(s, "breast")))
                }
            }
            "sleep" -> {
                val t = s.sleep
                if (t != null) {
                    v.setTextViewText(R.id.title, s.text("sleeping", "Đang ngủ"))
                    v.setInt(R.id.root, "setBackgroundResource", soft(type))
                    v.setViewVisibility(R.id.big, View.GONE)
                    chrono(v, R.id.chrono, now - t.startedAt, true)
                    v.setTextViewText(R.id.sub, s.text("since", mapOf("time" to f.time(t.startedAt), "name" to t.byName)))
                    if (s.canLog) {
                        button(context, v, R.id.btn1, s.text("wake", "Thức dậy"), pill(type), white, action(context, "end:sleep"))
                    }
                    v.setOnClickPendingIntent(R.id.root, link(context, "/care/timer/sleep"))
                } else {
                    v.setTextViewText(R.id.title, s.text("sleepTitle", "Giấc ngủ"))
                    val woke = s.lastWokeAt
                    if (woke != null) {
                        if (now - woke < 300_000) {
                            v.setTextViewText(R.id.big, s.text("justWoke", "Vừa thức dậy"))
                            v.setTextViewText(R.id.sub, s.text("slept", mapOf("t" to f.duration((s.lastSleepMin ?: 0) * 60_000L))))
                        } else {
                            v.setTextViewText(R.id.big, s.text("awakeFor", mapOf("t" to f.duration(now - woke))))
                            v.setTextViewText(R.id.sub, s.text("wokeAt", mapOf("time" to f.time(woke))))
                        }
                    } else {
                        v.setTextViewText(R.id.big, s.text("noneYet", "Chưa có"))
                        v.setTextViewText(R.id.sub, "")
                    }
                    if (s.canLog) {
                        button(context, v, R.id.btn1, s.text("startSleep", "Bắt đầu ngủ"), pill(type), white, action(context, "start:sleep"))
                    }
                    v.setOnClickPendingIntent(R.id.root, link(context, logPath(s, "sleep")))
                }
            }
            else -> {
                val logged = s.loggedNow("diaper", now)
                if (logged != null) {
                    loggedState(logged, s.text("diaper", "Thay tã"), s.text("changeType", "Đổi loại"))
                } else {
                    v.setTextViewText(R.id.title, s.text("diaper", "Thay tã"))
                    val l = s.lastDiaper
                    if (l != null) {
                        val fresh = now - l.at < 60_000
                        v.setTextViewText(R.id.big, if (fresh) s.text("justNow", "Vừa xong") else f.duration(now - l.at))
                        v.setTextViewText(R.id.sub, if (fresh) "${f.diaper(l.kind)} · ${f.by(l.by)}"
                            else s.text("agoKind", mapOf("kind" to f.diaper(l.kind))))
                    } else {
                        v.setTextViewText(R.id.big, s.text("noneYet", "Chưa có"))
                        v.setTextViewText(R.id.sub, "")
                    }
                    if (s.canLog) {
                        listOf(R.id.btn1 to "wet", R.id.btn2 to "dirty", R.id.btn3 to "both").forEach { (id, kind) ->
                            val first = kind == "wet"
                            button(context, v, id, f.diaper(kind), if (first) pill(type) else R.drawable.widget_pill_surface,
                                if (first) white else inkColor, action(context, "diaper:$kind"))
                        }
                    }
                    v.setOnClickPendingIntent(R.id.root, link(context, logPath(s, "diaper")))
                }
            }
        }
        return v
    }

    // ---------- Header and tiles (W2) ----------

    private fun header(context: Context, v: RemoteViews, s: Snap, now: Long, trailing: String?) {
        val f = GlanceFormat(s)
        val logged = s.logged?.takeIf { now < it.at + Snap.UNDO_MS }
        if (logged != null) {
            v.setViewVisibility(R.id.header, View.GONE)
            v.setViewVisibility(R.id.toast, View.VISIBLE)
            val type = s.text(logged.type, logged.type)
            val what = if (logged.label.isEmpty() || logged.label == type) type else "$type · ${logged.label}"
            v.setTextViewText(R.id.toast_text, "✓  " + s.text("loggedToast", mapOf("what" to what)))
            v.setTextViewText(R.id.toast_undo, s.text("undo", "Hoàn tác"))
            v.setOnClickPendingIntent(R.id.toast_undo, action(context, "undo:${logged.recordId}"))
            return
        }
        v.setViewVisibility(R.id.toast, View.GONE)
        v.setViewVisibility(R.id.header, View.VISIBLE)
        v.setTextViewText(R.id.nickname, s.nickname ?: "")
        if (s.pending > 0) {
            v.setTextViewText(R.id.header_right, s.text("pending", mapOf("n" to "${s.pending}")))
            color(context, v, R.id.header_right, R.color.cl_pending)
        } else {
            v.setTextViewText(R.id.header_right, trailing ?: s.text("summary",
                mapOf("feeds" to "${s.feedsToday}", "sleep" to f.duration(s.sleptTodayMin * 60_000L, short = true))))
            color(context, v, R.id.header_right, R.color.cl_muted)
        }
    }

    private fun tiles(context: Context, v: RemoteViews, s: Snap, now: Long) {
        val f = GlanceFormat(s)
        fun since(at: Long?) = at?.let { f.duration(now - it, short = true) } ?: "—"
        for (type in care) {
            val (tile, badgeId, labelId, metaId) = tileIds(type)
            val logged = s.loggedNow(type, now) != null
            v.setTextViewText(labelId, when (type) {
                "bottle" -> s.text("bottle", "Bú bình")
                "breast" -> if (s.breast != null) s.text("feeding", "Đang bú") else s.text("breast", "Bú mẹ")
                "sleep" -> if (s.sleep != null) s.text("sleeping", "Đang ngủ") else s.text("sleep", "Ngủ")
                else -> s.text("diaper", "Thay tã")
            })
            v.setTextViewText(metaId, when {
                logged -> s.text("justNow", "Vừa xong")
                type == "bottle" -> since(s.lastBottle?.at)
                type == "breast" -> s.breast?.let { f.duration(it.totalMs(now), short = true) } ?: since(s.lastBreast?.at)
                type == "sleep" -> s.sleep?.let { f.duration(now - it.startedAt, short = true) }
                    ?: s.lastWokeAt?.let { s.text("awakeShort", mapOf("t" to f.duration(now - it, short = true))) } ?: "—"
                else -> since(s.lastDiaper?.at)
            })
            when {
                logged -> {
                    v.setViewVisibility(badgeId, View.VISIBLE)
                    v.setTextViewText(badgeId, "✓")
                    color(context, v, badgeId, WHITE)
                    v.setInt(badgeId, "setBackgroundResource", badge(type))
                }
                s.canLog -> {
                    v.setViewVisibility(badgeId, View.VISIBLE)
                    v.setTextViewText(badgeId, "+")
                    color(context, v, badgeId, inkRes(type))
                    v.setInt(badgeId, "setBackgroundResource", R.drawable.widget_badge_surface)
                }
                else -> v.setViewVisibility(badgeId, View.GONE)
            }
            // A tile opens the app's own log for its type, a running timer opens itself (owner
            // request 2026-10-11); read-only members: Hôm nay.
            val running = (type == "sleep" && s.sleep != null) || (type == "breast" && s.breast != null)
            v.setOnClickPendingIntent(tile, link(context, if (!s.canLog) "/today" else if (running) "/care/timer/$type" else logPath(s, type)))
        }
    }

    fun quick(context: Context, s: Snap?, now: Long): RemoteViews {
        if (s == null || !s.signedIn) return special(context, s)
        val v = RemoteViews(context.packageName, R.layout.widget_quick)
        header(context, v, s, now, null)
        tiles(context, v, s, now)
        v.setOnClickPendingIntent(R.id.root, link(context, "/today"))
        return v
    }

    fun today(context: Context, s: Snap?, now: Long): RemoteViews {
        if (s == null || !s.signedIn) return special(context, s)
        val f = GlanceFormat(s)
        val v = RemoteViews(context.packageName, R.layout.widget_today)
        header(context, v, s, now, f.day(now))
        // Sleep card.
        val t = s.sleep
        val woke = s.lastWokeAt
        v.setViewVisibility(R.id.sleep_chrono, View.GONE)
        when {
            t != null -> {
                v.setTextViewText(R.id.sleep_title, s.text("sleeping", "Đang ngủ"))
                chrono(v, R.id.sleep_chrono, now - t.startedAt, true)
                v.setTextViewText(R.id.sleep_sub, "")
                v.setViewVisibility(R.id.sleep_sub, View.GONE)
            }
            woke != null -> {
                v.setTextViewText(R.id.sleep_title, s.text("awakeFor", mapOf("t" to f.duration(now - woke))))
                v.setViewVisibility(R.id.sleep_sub, View.VISIBLE)
                v.setTextViewText(R.id.sleep_sub, "${s.text("wokeAt", mapOf("time" to f.time(woke)))} · " +
                    s.text("sleptToday", mapOf("t" to f.duration(s.sleptTodayMin * 60_000L, short = true))))
            }
            else -> {
                v.setTextViewText(R.id.sleep_title, s.text("sleepTitle", "Giấc ngủ"))
                v.setViewVisibility(R.id.sleep_sub, View.GONE)
            }
        }
        if (s.canLog) {
            v.setViewVisibility(R.id.sleep_button, View.VISIBLE)
            v.setTextViewText(R.id.sleep_button, if (t != null) s.text("wake", "Thức dậy") else s.text("sleep", "Ngủ"))
            v.setOnClickPendingIntent(R.id.sleep_button, action(context, if (t != null) "end:sleep" else "start:sleep"))
        } else {
            v.setViewVisibility(R.id.sleep_button, View.GONE)
        }
        tiles(context, v, s, now)
        v.setTextViewText(R.id.recent_title, s.text("recent", "Gần đây"))
        val rows = listOf(R.id.recent1, R.id.recent2, R.id.recent3)
        val recent = s.recent.take(3)
        rows.forEachIndexed { i, row ->
            val r = recent.getOrNull(i)
            if (r == null) {
                v.setViewVisibility(row, View.GONE)
                return@forEachIndexed
            }
            val (dot, time, text, by) = recentIds(i + 1)
            v.setViewVisibility(row, View.VISIBLE)
            v.setImageViewResource(dot, badge(r.type.takeIf { it in care } ?: "sleep"))
            v.setTextViewText(time, f.time(r.at))
            v.setTextViewText(text, r.text)
            v.setTextViewText(by, r.by)
            v.setOnClickPendingIntent(row, link(context, "/care/record/${r.id}"))
        }
        v.setTextViewText(R.id.totals, s.text("totals", mapOf(
            "bottles" to "${s.bottlesToday}", "ml" to "${s.bottleMlToday}",
            "breasts" to "${s.breastsToday}", "diapers" to "${s.diapersToday}",
        )))
        v.setOnClickPendingIntent(R.id.root, link(context, "/today"))
        return v
    }

    // ---------- Shortcuts ----------

    fun shortcut(context: Context, kind: String, s: Snap?): RemoteViews {
        val v = RemoteViews(context.packageName, R.layout.widget_shortcut)
        val camera = kind == "camera"
        v.setTextViewText(R.id.title, s?.text("appName", "Child Life") ?: "Child Life")
        v.setImageViewResource(R.id.icon, if (camera) R.drawable.widget_icon_camera else R.drawable.widget_icon_library)
        // Android's widget opens the photo camera; videos are on the app's add sheet (Q-066).
        v.setTextViewText(R.id.label, if (camera) s?.text("memCameraPhoto", "Chụp ảnh") ?: "Chụp ảnh"
            else s?.text("memLibrary", "Thêm từ Ảnh") ?: "Thêm từ Ảnh")
        val name = s?.nickname
        v.setTextViewText(R.id.sub, if (name != null && s.signedIn) s.text("memFor", mapOf("name" to name)) else "")
        val allowed = s != null && s.signedIn && s.canAddMemories
        v.setOnClickPendingIntent(R.id.root, link(context, if (allowed) "/memories?add=${if (camera) "camera" else "library"}" else "/today"))
        return v
    }
}

/** Widget buttons: logs and timers without opening the app (GlanceActions). */
class GlanceActionReceiver : BroadcastReceiver() {
    private val io = Executors.newSingleThreadExecutor()

    override fun onReceive(context: Context, intent: Intent) {
        val op = intent.action?.removePrefix("app.childlife.glance.") ?: return
        val app = context.applicationContext
        val pending = goAsync()
        io.execute {
            try {
                run(app, op)
            } catch (_: Exception) {
                // Nothing about the child is logged; the widget redraws as it is.
            } finally {
                runCatching { GlanceUi.refresh(app) }
                pending.finish()
            }
        }
    }

    private fun run(context: Context, op: String) {
        val (name, arg) = op.split(":", limit = 2).let { it[0] to it.getOrNull(1) }
        when (name) {
            "bottle" -> {
                GlanceActions.logBottle(context)
                GlanceUi.refreshAfterUndo(context)
            }
            "diaper" -> {
                GlanceActions.logDiaper(context, arg ?: "wet")
                GlanceUi.refreshAfterUndo(context)
            }
            "undo" -> arg?.let { GlanceActions.undo(context, it) }
            "start" -> GlanceActions.start(context, arg ?: "sleep")
            "end" -> GlanceActions.end(context, arg ?: "sleep")
            "switch" -> GlanceActions.switchSide(context)
            "refresh" -> GlanceFirestore.flushPending(context)
        }
    }


}

class GlanceRefreshWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        runCatching { GlanceFirestore.flushPending(applicationContext) }
        GlanceUi.refresh(applicationContext)
        return Result.success()
    }
}

/** One provider per widget kind; each draws from the shared snapshot. */
abstract class GlanceWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        GlanceUi.refresh(context)
        GlanceUi.schedule(context)
    }

    override fun onEnabled(context: Context) = GlanceUi.schedule(context)
}

class BottleWidget : GlanceWidget()
class BreastWidget : GlanceWidget()
class SleepWidget : GlanceWidget()
class DiaperWidget : GlanceWidget()
class QuickWidget : GlanceWidget()
class TodayWidget : GlanceWidget()
class CameraWidget : GlanceWidget()
class LibraryWidget : GlanceWidget()

/**
 * The lock-screen half of the iOS Live Activity (Q-064): a running sleep or breastfeeding timer
 * as an ongoing notice with its chronometer and the same buttons ("Thức dậy"; "Đổi bên", "Kết
 * thúc"), answered by GlanceActions without opening the app.
 */
object TimerNotice {
    const val CHANNEL = "timers"

    private fun ensureChannel(context: Context) {
        val nm = context.getSystemService(NotificationManager::class.java)
        if (nm.getNotificationChannel(CHANNEL) != null) return
        // Dart creates it in the app language (AndroidChannels); this is the first-run fallback.
        nm.createNotificationChannel(NotificationChannel(CHANNEL, "Bộ đếm giờ", NotificationManager.IMPORTANCE_LOW))
    }

    fun sync(context: Context, s: Snap?) {
        val nm = NotificationManagerCompat.from(context)
        for (type in listOf("sleep", "breast")) {
            val t = if (s?.signedIn == true) (if (type == "sleep") s.sleep else s.breast) else null
            if (t == null || s == null) {
                nm.cancel("timer-$type", 0)
                continue
            }
            ensureChannel(context)
            if (!nm.areNotificationsEnabled()) continue
            val f = GlanceFormat(s)
            val now = System.currentTimeMillis()
            val name = s.nickname ?: ""
            val b = NotificationCompat.Builder(context, CHANNEL)
                .setSmallIcon(R.drawable.ic_stat_notify)
                .setColor(context.getColor(R.color.notify_accent))
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setSilent(true)
                .setCategory(NotificationCompat.CATEGORY_STOPWATCH)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setContentIntent(link(context, "/care/timer/$type"))
            if (type == "sleep") {
                b.setContentTitle(s.text("sleepingTitle", mapOf("name" to name)))
                b.setContentText(s.text("since", mapOf("time" to f.time(t.startedAt), "name" to t.byName)))
                b.setUsesChronometer(true).setShowWhen(true).setWhen(t.startedAt)
                if (s.canLog) {
                    b.addAction(0, s.text("wake", "Thức dậy"), GlanceUi.action(context, "end:sleep"))
                    b.addAction(0, s.text("editTimeShort", "Sửa giờ"), link(context, "/care/timer/sleep"))
                }
            } else {
                val side = s.text("breastSide.${t.activeSide ?: "left"}", "")
                b.setContentTitle(s.text("breastTitle", mapOf("side" to side)))
                if (t.paused) {
                    b.setContentText("${s.text("paused", "Tạm dừng")} · ${f.duration(t.totalMs(now))}")
                } else {
                    b.setContentText(s.text("sinceTime", mapOf("time" to f.time(t.startedAt))))
                    b.setUsesChronometer(true).setShowWhen(true).setWhen(now - t.totalMs(now))
                }
                if (s.canLog) {
                    b.addAction(0, s.text("switchSide", "Đổi bên"), GlanceUi.action(context, "switch"))
                    b.addAction(0, s.text("endFeed", "Kết thúc"), GlanceUi.action(context, "end:breast"))
                }
            }
            runCatching { nm.notify("timer-$type", 0, b.build()) }
        }
    }

    private fun link(context: Context, path: String): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
            .setAction(Intent.ACTION_VIEW)
            .setData(Uri.parse("${context.packageName}://app$path"))
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        return PendingIntent.getActivity(context, ("notice$path").hashCode(), intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
    }
}
