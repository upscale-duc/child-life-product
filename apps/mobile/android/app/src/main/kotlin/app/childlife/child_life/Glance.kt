package app.childlife.child_life

import android.content.Context
import android.content.SharedPreferences
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors
import org.json.JSONObject

/**
 * The Android side of `childlife/glance` (lib/features/glance/glance_bridge.dart; iOS:
 * ios/Shared/Glance*.swift). Dart hands over the "glance snapshot" of Today with every string
 * native code shows (ARB, D-012); widgets, the upload notices and notification actions read it
 * here, with the app closed. The session stays with Firebase Auth (AuthToken). No photos, no
 * child data in logs.
 */
object Glance {
    private const val PREFS = "childlife.glance"
    private const val SNAPSHOT = "glance.snapshot"
    private val lock = Any()
    private val io = Executors.newSingleThreadExecutor()

    private fun prefs(context: Context): SharedPreferences =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun register(context: Context, messenger: BinaryMessenger) {
        val app = context.applicationContext
        MethodChannel(messenger, "childlife/glance").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "setSnapshot" -> {
                        setSnapshot(app, call.arguments as? String ?: "")
                        result.success(null)
                    }
                    // iOS only: Android's Firebase Auth keeps the session (AuthToken).
                    "setSession" -> result.success(null)
                    "clearSession" -> {
                        clearSession(app)
                        result.success(null)
                    }
                    // On every resume: widget logs made offline go up, the widgets redraw.
                    "refresh" -> {
                        io.execute {
                            runCatching { GlanceFirestore.flushPending(app) }
                            GlanceUi.refresh(app)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: IllegalArgumentException) {
                result.error("bad-snapshot", null, null)
            }
        }
    }

    // ---------- Snapshot ----------

    fun snapshot(context: Context): JSONObject? =
        prefs(context).getString(SNAPSHOT, null)?.let { runCatching { JSONObject(it) }.getOrNull() }

    fun setSnapshot(context: Context, json: String) {
        val next = runCatching { JSONObject(json) }.getOrNull() ?: throw IllegalArgumentException()
        synchronized(lock) {
            // What only native code knows survives Dart's rebuild of the snapshot: a one-tap log
            // still in its undo window, and the writes waiting to be sent.
            snapshot(context)?.optJSONObject("logged")?.let { logged ->
                if (System.currentTimeMillis() < logged.optLong("at") + Snap.UNDO_MS) next.put("logged", logged)
            }
            next.put("pending", GlanceFirestore.pending(context).size)
            prefs(context).edit().putString(SNAPSHOT, next.toString()).apply()
        }
        GlanceUi.refresh(context)
    }

    /** Native changes (a widget log, a timer from the notice); the widgets redraw after. */
    fun updateSnapshot(context: Context, change: (JSONObject) -> Unit) {
        synchronized(lock) {
            val snap = snapshot(context) ?: return
            change(snap)
            prefs(context).edit().putString(SNAPSHOT, snap.toString()).apply()
        }
        GlanceUi.refresh(context)
    }

    /** A string from the snapshot's `copy` with `{x}` filled in, or [fallback]. */
    fun text(context: Context, key: String, fallback: String, values: Map<String, String> = emptyMap()): String {
        var s = snapshot(context)?.optJSONObject("copy")?.optString(key)?.takeIf { it.isNotEmpty() } ?: fallback
        for ((k, v) in values) s = s.replace("{$k}", v)
        return s
    }

    // ---------- Session ----------

    /**
     * Signed out: the widgets and notices follow at once. Android keeps no session of its own
     * (AuthToken asks Firebase Auth), so Dart only calls this, never setSession.
     */
    fun clearSession(context: Context) {
        updateSnapshot(context) { s ->
            s.put("signedIn", false)
            for (k in listOf("uid", "babyId", "sleep", "breast")) s.remove(k)
        }
    }
}
