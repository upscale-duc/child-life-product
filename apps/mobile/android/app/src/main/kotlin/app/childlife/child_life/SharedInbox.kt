package app.childlife.child_life

import android.app.Activity
import android.content.ClipData
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.webkit.MimeTypeMap
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.UUID
import java.util.concurrent.Executors
import org.json.JSONArray
import org.json.JSONObject

/**
 * 10k on Android (android-plan.md A4, Q-065): photos and videos shared from another app. The share
 * opens Child Life (ShareActivity hands the files to MainActivity with the read grant); they are
 * copied at once into `files/ShareInbox/share_{uuid}/` with a manifest in the iOS extension's
 * format, without a baby or audience yet, and Dart opens "Soạn & chia sẻ" (10h) for them, asking
 * for the baby first when there are several. Same `childlife/share` contract as iOS.
 */
object SharedInbox {
    const val ACTION = "app.childlife.SHARE"
    private const val TARGETS = "share.targets"
    private const val DAY_MS = 86_400_000L

    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    @Volatile private var channel: MethodChannel? = null

    private fun root(context: Context) = File(context.filesDir, "ShareInbox")

    fun register(context: Context, messenger: BinaryMessenger) {
        val app = context.applicationContext
        val c = MethodChannel(messenger, "childlife/share")
        channel = c
        c.setMethodCallHandler { call, result ->
            when (call.method) {
                "setTargets" -> {
                    prefs(app).edit().putString(TARGETS, call.arguments as? String ?: "").apply()
                    result.success(null)
                }
                "takeInbox" -> io.execute {
                    val out = takeInbox(app)
                    main.post { result.success(out) }
                }
                "finish" -> {
                    finish(app, call.arguments as? String ?: "")
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun prefs(context: Context) = context.getSharedPreferences("childlife.share", Context.MODE_PRIVATE)

    /** At most this many items per share (`publicConfig/limits.mediaItemsPerAdd`, R-102). */
    private fun maxItems(context: Context): Int =
        runCatching { JSONObject(prefs(context).getString(TARGETS, "{}")!!).optInt("maxItems", 30) }
            .getOrDefault(30).coerceAtLeast(1)

    // ---------- Receiving ----------

    /** The shared content's URIs, from ShareActivity's hand-off. */
    @Suppress("DEPRECATION")
    fun uris(intent: Intent): List<Uri> {
        val out = linkedSetOf<Uri>()
        intent.data?.let(out::add)
        intent.clipData?.let { clip -> for (i in 0 until clip.itemCount) clip.getItemAt(i).uri?.let(out::add) }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)?.let(out::addAll)
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)?.let(out::add)
        } else {
            (intent.extras?.get(Intent.EXTRA_STREAM) as? Uri)?.let(out::add)
            intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)?.let(out::addAll)
        }
        return out.toList()
    }

    /** MainActivity, holding the read grant: copies the files and tells Dart when they are in. */
    fun receive(activity: Activity, intent: Intent?) {
        if (intent?.action != ACTION) return
        val uris = uris(intent)
        // Handled once, also after the activity is recreated.
        intent.action = Intent.ACTION_MAIN
        if (uris.isEmpty()) return
        val app = activity.applicationContext
        val resolver = activity.contentResolver
        io.execute {
            runCatching { copy(app, resolver, uris) }
            main.post { channel?.invokeMethod("received", null) }
        }
    }

    private fun copy(context: Context, resolver: android.content.ContentResolver, uris: List<Uri>) {
        val dir = File(root(context), "share_${UUID.randomUUID()}").apply { mkdirs() }
        val items = JSONArray()
        var skipped = 0
        val max = maxItems(context)
        for (uri in uris) {
            val mime = resolver.getType(uri) ?: ""
            val video = mime.startsWith("video/")
            if (!video && !mime.startsWith("image/")) {
                skipped++
                continue
            }
            if (items.length() >= max) {
                skipped++
                continue
            }
            val name = displayName(resolver, uri) ?: "shared"
            val ext = name.substringAfterLast('.', "").lowercase().takeIf { it.length in 2..5 }
                ?: MimeTypeMap.getSingleton().getExtensionFromMimeType(mime) ?: if (video) "mp4" else "jpg"
            val file = File(dir, "${items.length()}.$ext")
            val ok = runCatching {
                resolver.openInputStream(uri)!!.use { input -> file.outputStream().use { input.copyTo(it) } }
            }.isSuccess
            if (!ok || file.length() == 0L) {
                file.delete()
                skipped++
                continue
            }
            val info = runCatching { if (video) MediaProbe.video(file.path) else MediaProbe.photo(file.path) }.getOrNull()
            val taken = info?.takenAt ?: dateTaken(resolver, uri) ?: System.currentTimeMillis()
            items.put(
                JSONObject()
                    .put("file", file.name)
                    .put("type", if (video) "video" else "photo")
                    .put("name", name)
                    .put("captureAt", iso(taken))
                    .put("width", info?.width ?: JSONObject.NULL)
                    .put("height", info?.height ?: JSONObject.NULL)
                    .put("durationMs", info?.durationMs ?: JSONObject.NULL),
            )
        }
        val manifest = JSONObject()
            .put("version", 1)
            // Chosen in the app (Q-065): baby, audience and notice come from "Soạn & chia sẻ".
            .put("babyId", JSONObject.NULL)
            .put("audience", JSONObject.NULL)
            .put("notifyFamily", false)
            .put("createdAt", iso(System.currentTimeMillis()))
            .put("skipped", skipped)
            .put("items", items)
        val tmp = File(dir, "manifest.json.part")
        tmp.writeText(manifest.toString())
        tmp.renameTo(File(dir, "manifest.json"))
    }

    private fun displayName(resolver: android.content.ContentResolver, uri: Uri): String? =
        runCatching {
            resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { c ->
                if (c.moveToFirst()) c.getString(0) else null
            }
        }.getOrNull()

    private fun dateTaken(resolver: android.content.ContentResolver, uri: Uri): Long? =
        runCatching {
            resolver.query(uri, arrayOf(MediaStore.MediaColumns.DATE_TAKEN), null, null, null)?.use { c ->
                if (c.moveToFirst() && !c.isNull(0)) c.getLong(0).takeIf { it > 0 } else null
            }
        }.getOrNull()

    private fun iso(ms: Long): String =
        SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
            .apply { timeZone = TimeZone.getTimeZone("UTC") }
            .format(Date(ms))

    // ---------- Dart ----------

    /** Every share with its manifest, oldest first; leftovers without one older than a day go. */
    fun takeInbox(context: Context): List<Map<String, Any?>> {
        val out = mutableListOf<Pair<String, Map<String, Any?>>>()
        val now = System.currentTimeMillis()
        for (dir in root(context).listFiles().orEmpty()) {
            if (!dir.isDirectory) continue
            val manifest = File(dir, "manifest.json")
            if (!manifest.exists()) {
                if (now - dir.lastModified() > DAY_MS) dir.deleteRecursively()
                continue
            }
            val o = runCatching { JSONObject(manifest.readText()) }.getOrNull() ?: continue
            val map = toMap(o).toMutableMap()
            map["id"] = dir.name
            map["dir"] = dir.path
            out += (o.optString("createdAt") to map)
        }
        return out.sortedBy { it.first }.map { it.second }
    }

    /**
     * Done with a share. Only its manifest goes: the upload queue copies the files when it takes
     * them, which may finish after "Soạn & chia sẻ" closes, so the folder is cleared a day later.
     */
    fun finish(context: Context, id: String) {
        if (id.isEmpty() || '/' in id || ".." in id) return
        File(File(root(context), id), "manifest.json").delete()
    }

    private fun toMap(o: JSONObject): Map<String, Any?> =
        o.keys().asSequence().associateWith { k -> unwrap(o.get(k)) }

    private fun unwrap(v: Any?): Any? = when (v) {
        JSONObject.NULL -> null
        is JSONObject -> toMap(v)
        is JSONArray -> (0 until v.length()).map { unwrap(v.get(it)) }
        else -> v
    }
}

/** The share target (10k): passes the shared items, with their read grant, to MainActivity. */
class ShareActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val uris = SharedInbox.uris(intent)
        if (uris.isNotEmpty()) {
            val forward = Intent(this, MainActivity::class.java)
                .setAction(SharedInbox.ACTION)
                .putParcelableArrayListExtra(Intent.EXTRA_STREAM, ArrayList(uris))
                .addFlags(
                    Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP,
                )
            val clip = ClipData.newRawUri("", uris.first())
            uris.drop(1).forEach { clip.addItem(ClipData.Item(it)) }
            forward.clipData = clip
            try {
                startActivity(forward)
            } catch (_: SecurityException) {
                // The sender did not let us read them: open the app without them.
                runCatching {
                    startActivity(Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                }
            }
        }
        finish()
    }
}
