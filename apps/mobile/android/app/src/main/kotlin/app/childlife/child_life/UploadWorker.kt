package app.childlife.child_life

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.ServiceInfo
import android.os.Build
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.ForegroundInfo
import androidx.work.WorkerParameters
import java.io.File
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Sends one file's bytes to its resumable upload URL (BackgroundUploads.start made it). Runs as
 * a `dataSync` foreground job while it can, so it goes on with the app in the background; if the
 * system stops it (no network, Wi-Fi lost for a Wi-Fi-only video, Android 15's daily limit),
 * WorkManager runs it again later and it asks Storage how much arrived and goes on from there.
 */
class UploadWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    companion object {
        const val PATH = "path"
        const val FILE = "file"
        const val URL = "url"
        const val TOKEN = "token"
        const val TYPE = "contentType"
        const val HOST = "host"

        /** Network failures retried by WorkManager before the file is reported failed. */
        private const val MAX_ATTEMPTS = 6
    }

    /** Debug builds only, and only codes and byte counts (no paths, nothing about the child). */
    private fun trace(message: String) {
        if (applicationContext.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0) {
            Log.i("CLUpload", message)
        }
    }

    override suspend fun getForegroundInfo(): ForegroundInfo {
        val n = BackgroundUploads.progressNotification(applicationContext)
            ?: androidx.core.app.NotificationCompat.Builder(applicationContext, BackgroundUploads.CHANNEL)
                .setSmallIcon(R.drawable.ic_stat_notify)
                .setContentTitle(Glance.text(applicationContext, "upload.titlePlain", "Kỷ niệm"))
                .setSilent(true)
                .build()
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ForegroundInfo(BackgroundUploads.PROGRESS_ID, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        } else {
            ForegroundInfo(BackgroundUploads.PROGRESS_ID, n)
        }
    }

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        val context = applicationContext
        val path = inputData.getString(PATH) ?: return@withContext Result.failure()
        // Cancelled or forgotten meanwhile: nothing to send.
        if (!BackgroundUploads.isRunning(context, path)) return@withContext Result.success()
        val file = File(inputData.getString(FILE) ?: "")
        val url = inputData.getString(URL) ?: ""
        val token = inputData.getString(TOKEN) ?: ""
        val type = inputData.getString(TYPE) ?: "application/octet-stream"
        val client = ResumableClient(inputData.getString(HOST))

        BackgroundUploads.ensureChannel(context)
        // Android 12+ may refuse a foreground start from the background; the job still runs.
        runCatching { setForeground(getForegroundInfo()) }

        if (!file.exists()) {
            BackgroundUploads.finish(context, path, "file-missing")
            return@withContext Result.success()
        }

        // An ID token lasts an hour; a file that waited longer (Wi-Fi, a long queue) gets a fresh
        // one from Firebase Auth (AuthToken), once.
        var answer = transfer(context, path, client, url, token, file, type)
        if (answer == ResumableClient.Answer.Failed("unauthenticated")) {
            AuthToken.idToken(context, force = true)?.let {
                answer = transfer(context, path, client, url, it, file, type)
            }
        }
        when (val a = answer) {
            is ResumableClient.Answer.Done -> {
                BackgroundUploads.finish(context, path, null)
                Result.success()
            }
            is ResumableClient.Answer.Failed -> settle(path, a.code)
            else -> settle(path, "unknown")
        }
    }

    /**
     * A run after one that sent bytes (retried, or the app was killed) asks how much arrived and
     * goes on from there; the first starts at 0.
     */
    private fun transfer(
        context: Context,
        path: String,
        client: ResumableClient,
        url: String,
        token: String,
        file: File,
        type: String,
    ): ResumableClient.Answer {
        var offset = 0L
        if (BackgroundUploads.begin(context, path) || runAttemptCount > 0) {
            when (val q = client.query(url, token)) {
                is ResumableClient.Answer.Received -> {
                    offset = q.bytes
                    trace("resume at $offset of ${file.length()} (attempt $runAttemptCount)")
                }
                else -> return q
            }
        }
        return client.upload(
            url, token, file, type, offset,
            progress = { sent -> BackgroundUploads.progress(context, path, sent) },
            stopped = { isStopped || !BackgroundUploads.isRunning(context, path) },
        )
    }

    /** A dropped connection is tried again (from where it was); anything else is reported. */
    private fun settle(path: String, code: String): Result {
        val context = applicationContext
        trace("stopped with $code (attempt $runAttemptCount, stopped=$isStopped)")
        if (isStopped || !BackgroundUploads.isRunning(context, path)) return Result.retry()
        if (code == "network" && runAttemptCount + 1 < MAX_ATTEMPTS) return Result.retry()
        BackgroundUploads.finish(context, path, code)
        return Result.success()
    }
}
