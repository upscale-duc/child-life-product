package app.childlife.child_life

import android.graphics.BitmapFactory
import android.media.ExifInterface
import android.media.MediaMetadataRetriever
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone
import java.util.concurrent.Executors
import android.os.Handler
import android.os.Looper

/**
 * What a photo or recording says about itself: size, length and when it was taken (A4). Used for
 * videos from the system camera (`childlife/camera` "probe") and for files shared into the app.
 * Upright sizes: a portrait recording stored sideways reports its turned size, as iOS does.
 */
object MediaProbe {
    data class Info(val width: Int?, val height: Int?, val durationMs: Long?, val takenAt: Long?)

    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, "childlife/camera").setMethodCallHandler { call, result ->
            when (call.method) {
                "probe" -> {
                    val path = (call.arguments as? Map<*, *>)?.get("path") as? String ?: ""
                    val video = (call.arguments as? Map<*, *>)?.get("video") as? Boolean ?: true
                    io.execute {
                        val i = runCatching { if (video) video(path) else photo(path) }.getOrNull()
                        main.post {
                            result.success(
                                i?.let {
                                    mapOf(
                                        "width" to it.width,
                                        "height" to it.height,
                                        "durationMs" to it.durationMs,
                                        "takenAt" to it.takenAt,
                                    )
                                },
                            )
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    fun video(path: String): Info {
        val r = MediaMetadataRetriever()
        try {
            r.setDataSource(path)
            val w = r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toIntOrNull()
            val h = r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toIntOrNull()
            val turn = r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toIntOrNull() ?: 0
            val sideways = turn == 90 || turn == 270
            return Info(
                width = if (sideways) h else w,
                height = if (sideways) w else h,
                durationMs = r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull(),
                takenAt = r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DATE)?.let(::parseVideoDate),
            )
        } finally {
            r.release()
        }
    }

    fun photo(path: String): Info {
        val o = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, o)
        val exif = runCatching { ExifInterface(path) }.getOrNull()
        val turn = exif?.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)
        val sideways = turn == ExifInterface.ORIENTATION_ROTATE_90 || turn == ExifInterface.ORIENTATION_ROTATE_270 ||
            turn == ExifInterface.ORIENTATION_TRANSPOSE || turn == ExifInterface.ORIENTATION_TRANSVERSE
        val w = o.outWidth.takeIf { it > 0 }
        val h = o.outHeight.takeIf { it > 0 }
        return Info(
            width = if (sideways) h else w,
            height = if (sideways) w else h,
            durationMs = null,
            takenAt = exif?.let {
                parseExifDate(
                    it.getAttribute(ExifInterface.TAG_DATETIME_ORIGINAL) ?: it.getAttribute(ExifInterface.TAG_DATETIME),
                    it.getAttribute(ExifInterface.TAG_OFFSET_TIME_ORIGINAL),
                )
            },
        )
    }

    /** EXIF "2026:10:14 08:00:00", in its own offset when written, else the phone's zone. */
    fun parseExifDate(s: String?, offset: String?): Long? {
        if (s.isNullOrBlank()) return null
        val f = SimpleDateFormat("yyyy:MM:dd HH:mm:ss", Locale.US)
        f.timeZone = offset?.takeIf { it.matches(Regex("[+-]\\d{2}:\\d{2}")) }
            ?.let { TimeZone.getTimeZone("GMT$it") } ?: TimeZone.getDefault()
        return runCatching { f.parse(s)?.time }.getOrNull()?.takeIf { it > 0 }
    }

    /** "20261014T080000.000Z" as MediaMetadataRetriever reports it. */
    fun parseVideoDate(s: String): Long? {
        for (pattern in listOf("yyyyMMdd'T'HHmmss.SSS'Z'", "yyyyMMdd'T'HHmmss'Z'", "yyyyMMdd'T'HHmmss")) {
            val f = SimpleDateFormat(pattern, Locale.US).apply { timeZone = TimeZone.getTimeZone("UTC") }
            val t = runCatching { f.parse(s)?.time }.getOrNull()
            // Some phones write 1904-01-01 when they know nothing.
            if (t != null && t > 0) return t
        }
        return null
    }
}
