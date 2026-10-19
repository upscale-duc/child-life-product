package app.childlife.child_life

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.work.Constraints
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors
import org.json.JSONObject

/**
 * 10j on Android (android-plan.md A3): memory uploads keep going with the phone locked or the
 * app closed. The same `childlife/uploads` contract as ios/Runner/BackgroundUploads.swift, so
 * the Dart queue (BackgroundTransport) is unchanged: a "start" request with the person's ID token
 * returns an upload URL now, and a WorkManager job (UploadWorker) sends the bytes when the network
 * allows — Wi-Fi only for videos when the person asked (D-033) — and goes on from where it was
 * after the app is killed.
 *
 * Outcomes are kept by storage path until Dart forgets them, so a file that finished while the
 * app was gone is never sent twice. Nothing about the child is logged; notifications show counts
 * and the baby's nickname only, never a photo.
 */
object BackgroundUploads {
    const val TAG = "childlife.upload"
    const val CHANNEL = "uploads"
    const val PROGRESS_ID = 7301
    private const val DONE_ID = 7302
    private const val WIFI_ID = 7303
    private const val PREFS = "childlife.uploads"

    data class Job(
        val path: String,
        var state: String,
        var sent: Long,
        val total: Long,
        var code: String?,
        val babyId: String,
        val video: Boolean,
        val wifiOnly: Boolean,
        var updated: Long,
        /** Bytes have been sent once: a later run asks Storage how much arrived first. */
        var begun: Boolean = false,
    ) {
        val counts get() = !path.endsWith(".poster")

        fun json(): Map<String, Any?> = mapOf("state" to state, "sent" to sent, "total" to total, "code" to code)

        fun toJson(): JSONObject =
            JSONObject().put("path", path).put("state", state).put("sent", sent).put("total", total)
                .put("code", code ?: JSONObject.NULL).put("babyId", babyId).put("video", video)
                .put("wifiOnly", wifiOnly).put("updated", updated).put("begun", begun)

        companion object {
            fun from(o: JSONObject) = Job(
                path = o.getString("path"),
                state = o.getString("state"),
                sent = o.optLong("sent"),
                total = o.optLong("total"),
                code = if (o.isNull("code")) null else o.optString("code"),
                babyId = o.optString("babyId"),
                video = o.optBoolean("video"),
                wifiOnly = o.optBoolean("wifiOnly"),
                updated = o.optLong("updated"),
                begun = o.optBoolean("begun"),
            )
        }
    }

    /** One "run": from the first file handed over until nothing is left running. */
    data class Run(var total: Int = 0, var done: Int = 0, var failed: Int = 0, var babyId: String? = null)

    private val lock = Any()
    private var loaded = false
    private val jobs = mutableMapOf<String, Job>()
    private var run = Run()
    private val lastEmit = mutableMapOf<String, Long>()
    private var lastNotice = 0L
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    /** Progress and outcomes for Dart, while an engine listens. */
    @Volatile private var emit: ((Map<String, Any?>) -> Unit)? = null

    /** Whether the app is in front (MainActivity onStart / onStop). */
    @Volatile var appVisible = false

    // ---------- Dart channel ----------

    fun register(context: Context, messenger: BinaryMessenger) {
        val app = context.applicationContext
        val channel = MethodChannel(messenger, "childlife/uploads")
        emit = { event -> main.post { channel.invokeMethod("event", event) } }
        io.execute { reconcile(app) }
        channel.setMethodCallHandler { call, result ->
            val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
            val path = args["path"] as? String ?: ""
            when (call.method) {
                "start" -> io.execute {
                    val out = start(app, args)
                    main.post { result.success(out) }
                }
                "status" -> result.success(status(app, path))
                "forget" -> {
                    forget(app, path)
                    result.success(null)
                }
                "cancel" -> {
                    cancel(app, path)
                    result.success(null)
                }
                "cancelAll" -> {
                    cancelAll(app)
                    result.success(null)
                }
                "faststart" -> io.execute {
                    val ok = runCatching {
                        FastStart.run(File(args["src"] as? String ?: ""), File(args["dst"] as? String ?: ""))
                    }.getOrDefault(false)
                    main.post { result.success(ok) }
                }
                else -> result.notImplemented()
            }
        }
    }

    fun unregister() {
        emit = null
    }

    fun send(event: Map<String, Any?>) {
        emit?.invoke(event)
    }

    // ---------- State ----------

    private fun prefs(context: Context) = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun load(context: Context) {
        if (loaded) return
        loaded = true
        val p = prefs(context)
        val week = System.currentTimeMillis() - 7 * 86_400_000L
        runCatching {
            val saved = JSONObject(p.getString("uploads.jobs", "{}")!!)
            for (k in saved.keys()) {
                val j = Job.from(saved.getJSONObject(k))
                // Outcomes Dart never collected (the batch was removed meanwhile) are not kept forever.
                if (j.state == "running" || j.updated > week) jobs[k] = j
            }
            val r = JSONObject(p.getString("uploads.run", "{}")!!)
            run = Run(r.optInt("total"), r.optInt("done"), r.optInt("failed"), r.optString("babyId").ifEmpty { null })
        }
    }

    private fun save(context: Context) {
        val all = JSONObject()
        for ((k, j) in jobs) all.put(k, j.toJson())
        val r = JSONObject().put("total", run.total).put("done", run.done).put("failed", run.failed)
            .put("babyId", run.babyId ?: "")
        prefs(context).edit().putString("uploads.jobs", all.toString()).putString("uploads.run", r.toString()).apply()
    }

    fun status(context: Context, path: String): Map<String, Any?>? = synchronized(lock) {
        load(context)
        jobs[path]?.json()
    }

    fun forget(context: Context, path: String) = synchronized(lock) {
        load(context)
        if (jobs[path]?.state != "running") jobs.remove(path)
        save(context)
    }

    @Volatile private var reconciled = false

    /**
     * A job still "running" whose WorkManager work is gone or finished without reporting (the
     * app's data was restored, work was cleared, a crash between the two) would stay "running"
     * forever and the Dart queue would wait on it just as long. Once per process such jobs
     * become `failed` / `lost`, which the queue sends afresh. Jobs started in the last seconds
     * are left alone: their work may not be enqueued yet.
     */
    private fun reconcile(context: Context) {
        if (reconciled) return
        reconciled = true
        val wm = WorkManager.getInstance(context)
        val cutoff = System.currentTimeMillis() - 10_000L
        val candidates = synchronized(lock) {
            load(context)
            jobs.values.filter { it.state == "running" && it.updated < cutoff }.map { it.path }
        }
        val lost = candidates.filter { path ->
            val infos = runCatching { wm.getWorkInfosForUniqueWork(workName(path)).get() }.getOrNull()
            infos == null || infos.isEmpty() || infos.all { it.state.isFinished }
        }
        if (lost.isEmpty()) return
        synchronized(lock) {
            for (path in lost) {
                val j = jobs[path]?.takeIf { it.state == "running" } ?: continue
                j.state = "failed"
                j.code = "lost"
                j.updated = System.currentTimeMillis()
                if (j.counts) run.failed += 1
            }
            if (jobs.values.none { it.state == "running" }) run = Run()
            save(context)
        }
        for (path in lost) send(mapOf("event" to "failed", "path" to path, "code" to "lost"))
        notifyProgress(context)
    }

    // ---------- Start, cancel ----------

    /** Hands a file over. A file already running or finished is not sent again. */
    fun start(context: Context, a: Map<*, *>): Map<String, Any?> {
        val path = a["path"] as? String
        val file = a["file"] as? String
        val contentType = a["contentType"] as? String
        val token = a["token"] as? String
        val bucket = a["bucket"] as? String
        val babyId = a["babyId"] as? String
        if (path == null || file == null || contentType == null || token == null || bucket == null || babyId == null) {
            return mapOf("state" to "failed", "code" to "bad-request")
        }
        val wifiOnly = a["wifiOnly"] as? Boolean ?: false
        val host = a["host"] as? String
        synchronized(lock) {
            load(context)
            jobs[path]?.takeIf { it.state != "failed" }?.let { return it.json() }
        }
        val f = File(file)
        if (!f.exists()) return mapOf("state" to "failed", "code" to "file-missing")

        // 1. Start a resumable upload (needs the network now; the bytes can wait).
        val started = ResumableClient(host).start(bucket, path, token, contentType, f.length())
        if (started !is ResumableClient.Answer.Started) {
            return mapOf("state" to "failed", "code" to (started as? ResumableClient.Answer.Failed)?.code)
        }

        // 2. The bytes, from the file, in a job that outlives the app.
        val job = Job(path, "running", 0, f.length(), null, babyId, a["video"] as? Boolean ?: false, wifiOnly,
            System.currentTimeMillis())
        synchronized(lock) {
            if (jobs.values.none { it.state == "running" }) run = Run(babyId = babyId)
            jobs[path] = job
            if (job.counts) run.total += 1
            save(context)
        }
        val input = Data.Builder()
            .putString(UploadWorker.PATH, path)
            .putString(UploadWorker.FILE, file)
            .putString(UploadWorker.URL, started.uploadUrl)
            .putString(UploadWorker.TOKEN, token)
            .putString(UploadWorker.TYPE, contentType)
            .putString(UploadWorker.HOST, host)
            .build()
        val request = OneTimeWorkRequestBuilder<UploadWorker>()
            .setInputData(input)
            .addTag(TAG)
            .setConstraints(
                Constraints.Builder()
                    // "Video chỉ tải qua Wi-Fi" (D-033): held until an unmetered network.
                    .setRequiredNetworkType(if (wifiOnly) NetworkType.UNMETERED else NetworkType.CONNECTED)
                    .build(),
            )
            .build()
        WorkManager.getInstance(context).enqueueUniqueWork(workName(path), ExistingWorkPolicy.REPLACE, request)
        notifyProgress(context)
        return job.json()
    }

    fun workName(path: String) = "upload:$path"

    fun cancel(context: Context, path: String) {
        synchronized(lock) {
            load(context)
            val j = jobs[path]
            if (j != null && j.state == "running" && j.counts) run.total = maxOf(0, run.total - 1)
            jobs.remove(path)
            save(context)
        }
        WorkManager.getInstance(context).cancelUniqueWork(workName(path))
        send(mapOf("event" to "cancelled", "path" to path))
        notifyProgress(context)
    }

    /** "Tạm dừng": everything handed over stops; Dart hands it over again on resume. */
    fun cancelAll(context: Context) {
        synchronized(lock) {
            load(context)
            jobs.entries.removeAll { it.value.state == "running" }
            run = Run()
            save(context)
        }
        WorkManager.getInstance(context).cancelAllWorkByTag(TAG)
        notifyProgress(context)
    }

    // ---------- From the worker ----------

    fun isRunning(context: Context, path: String): Boolean = synchronized(lock) {
        load(context)
        jobs[path]?.state == "running"
    }

    /** Whether bytes were sent before (so this run resumes), marking that they are now. */
    fun begin(context: Context, path: String): Boolean = synchronized(lock) {
        load(context)
        val j = jobs[path] ?: return false
        val before = j.begun
        if (!before) {
            j.begun = true
            save(context)
        }
        before
    }

    fun progress(context: Context, path: String, sent: Long) {
        val now = System.currentTimeMillis()
        val due = synchronized(lock) {
            load(context)
            jobs[path]?.sent = sent
            val d = now - (lastEmit[path] ?: 0L) > 250
            if (d) lastEmit[path] = now
            d
        }
        if (due) send(mapOf("event" to "progress", "path" to path, "sent" to sent))
        if (now - lastNotice > 1000) notifyProgress(context)
    }

    /** A file is done or failed for good; returns whether the run is over. */
    fun finish(context: Context, path: String, code: String?) {
        val finished: Run?
        synchronized(lock) {
            load(context)
            val job = jobs[path]?.takeIf { it.state == "running" } ?: return
            if (code == null) {
                job.state = "done"
                job.sent = job.total
                if (job.counts) run.done += 1
            } else {
                job.state = "failed"
                job.code = code
                if (job.counts) run.failed += 1
            }
            job.updated = System.currentTimeMillis()
            val idle = jobs.values.none { it.state == "running" }
            finished = if (idle) run.also { run = Run() } else null
            save(context)
        }
        send(mapOf("event" to (if (code == null) "done" else "failed"), "path" to path, "code" to code))
        notifyProgress(context)
        finished?.let { done(context, it) }
    }

    // ---------- Notifications ----------

    fun ensureChannel(context: Context) {
        val nm = context.getSystemService(NotificationManager::class.java)
        if (nm.getNotificationChannel(CHANNEL) != null) return
        // Dart creates it in the app language (AndroidChannels); this is the first-run fallback.
        nm.createNotificationChannel(
            NotificationChannel(CHANNEL, Glance.text(context, "upload.titlePlain", "Kỷ niệm"),
                NotificationManager.IMPORTANCE_DEFAULT),
        )
    }

    private fun openMemories(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
            .setAction(Intent.ACTION_VIEW)
            .setData(Uri.parse("${context.packageName}://app/memories"))
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
        return PendingIntent.getActivity(context, 7300, intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
    }

    /** The ongoing "Kỷ niệm của Teddy · Đang tải 4/7 mục" notice, in place of the Live Activity. */
    fun progressNotification(context: Context): Notification? {
        val (r, running) = synchronized(lock) {
            load(context)
            run.copy() to jobs.values.filter { it.counts && it.state == "running" }.map { it.copy() }
        }
        if (running.isEmpty() || r.total == 0) return null
        ensureChannel(context)
        val partial = running.sumOf { if (it.total > 0) it.sent.toDouble() / it.total else 0.0 }
        val fraction = ((r.done + r.failed + partial) / r.total).coerceIn(0.0, 1.0)
        // "1 video chờ Wi‑Fi" only while there is no Wi-Fi: on Wi-Fi the same video is uploading.
        val waiting = if (onWifi(context)) 0 else running.count { it.video && it.wifiOnly }
        val snap = Glance.snapshot(context)
        val nickname = snap?.optString("nickname")?.takeIf { it.isNotEmpty() && snap.optString("babyId") == r.babyId }
        val title = nickname?.let { Glance.text(context, "upload.title", "Kỷ niệm của {name}", mapOf("name" to it)) }
            ?: Glance.text(context, "upload.titlePlain", "Kỷ niệm")
        var body = Glance.text(context, "upload.progress", "Đang tải {done}/{total} mục",
            mapOf("done" to "${r.done + r.failed}", "total" to "${r.total}"))
        if (waiting > 0) {
            body += " · " + Glance.text(context, "upload.waiting", "{n} video chờ Wi‑Fi", mapOf("n" to "$waiting"))
        }
        return NotificationCompat.Builder(context, CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_notify)
            .setColor(context.getColor(R.color.notify_accent))
            .setContentTitle(title)
            .setContentText(body)
            .setSubText(Glance.text(context, "upload.notify", "Xong sẽ báo bạn"))
            .setProgress(1000, (fraction * 1000).toInt(), false)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setContentIntent(openMemories(context))
            .build()
    }

    fun notifyProgress(context: Context) {
        lastNotice = System.currentTimeMillis()
        val nm = NotificationManagerCompat.from(context)
        val n = progressNotification(context)
        if (n == null) {
            nm.cancel(PROGRESS_ID)
            return
        }
        if (nm.areNotificationsEnabled()) runCatching { nm.notify(PROGRESS_ID, n) }
    }

    /** "Đã tải xong 7 mục" / "7 mục chưa tải lên được": only when the app is not in front. */
    private fun done(context: Context, r: Run) {
        if (appVisible || r.total == 0) return
        val count = if (r.failed > 0) r.failed else r.done
        val one = if (count == 1) ".one" else ""
        val n = mapOf("n" to "$count")
        if (r.failed > 0) {
            notify(context, DONE_ID, Glance.text(context, "upload.failedTitle$one", "{n} mục chưa tải lên được", n),
                Glance.text(context, "upload.failedBody", "Mở Child Life để thử lại."))
        } else {
            notify(context, DONE_ID, Glance.text(context, "upload.doneTitle$one", "Đã tải xong {n} mục", n),
                Glance.text(context, "upload.doneBody", "Ảnh và video đã có trong Kỷ niệm."))
        }
    }

    /** 10j "1 video đang chờ Wi‑Fi": when the app is left with videos held for Wi-Fi. */
    fun onBackground(context: Context) {
        val waiting = synchronized(lock) {
            load(context)
            jobs.values.count { it.state == "running" && it.video && it.wifiOnly && it.counts }
        }
        if (waiting == 0 || onWifi(context)) return
        val n = mapOf("n" to "$waiting")
        notify(context, WIFI_ID,
            Glance.text(context, "upload.wifiTitle${if (waiting == 1) ".one" else ""}", "{n} video đang chờ Wi‑Fi", n),
            Glance.text(context, "upload.wifiBody", "Ảnh vẫn đang tải. Video sẽ tự tải khi có Wi‑Fi."))
    }

    private fun onWifi(context: Context): Boolean {
        val cm = context.getSystemService(ConnectivityManager::class.java)
        val caps = cm.getNetworkCapabilities(cm.activeNetwork) ?: return false
        return caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED)
    }

    private fun notify(context: Context, id: Int, title: String, body: String) {
        ensureChannel(context)
        val nm = NotificationManagerCompat.from(context)
        if (!nm.areNotificationsEnabled()) return
        val n = NotificationCompat.Builder(context, CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_notify)
            .setColor(context.getColor(R.color.notify_accent))
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setContentIntent(openMemories(context))
            .build()
        runCatching { nm.notify(id, n) }
    }
}
