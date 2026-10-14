package app.childlife.child_life

import android.content.Context
import com.google.firebase.auth.FirebaseAuth
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import org.json.JSONArray
import org.json.JSONObject

/**
 * Firestore REST values and writes, the same documents the app writes (ios/Shared/
 * GlanceFirestore.swift), so the same Rules check them; `createdAt` / `updatedAt` / `deletedAt`
 * use the REQUEST_TIME transform because Rules require them to equal `request.time`.
 */
object FS {
    fun str(s: String): JSONObject = JSONObject().put("stringValue", s)
    fun int(i: Long): JSONObject = JSONObject().put("integerValue", i.toString())
    fun int(i: Int): JSONObject = int(i.toLong())
    fun bool(b: Boolean): JSONObject = JSONObject().put("booleanValue", b)
    fun time(ms: Long): JSONObject = JSONObject().put("timestampValue", iso(ms))
    fun nul(): JSONObject = JSONObject().put("nullValue", JSONObject.NULL)
    fun map(m: Map<String, JSONObject>): JSONObject =
        JSONObject().put("mapValue", JSONObject().put("fields", JSONObject().apply { m.forEach { (k, v) -> put(k, v) } }))
    fun arr(list: List<JSONObject>): JSONObject =
        JSONObject().put("arrayValue", JSONObject().put("values", JSONArray(list)))

    fun iso(ms: Long): String =
        SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply { timeZone = TimeZone.getTimeZone("UTC") }
            .format(Date(ms))

    fun parseIso(s: String): Long? = listOf("yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'", "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
        "yyyy-MM-dd'T'HH:mm:ss'Z'").firstNotNullOfOrNull { p ->
        runCatching {
            SimpleDateFormat(p, Locale.US).apply { timeZone = TimeZone.getTimeZone("UTC") }.parse(s)?.time
        }.getOrNull()
    }

    private fun transforms(serverTime: List<String>) =
        JSONArray(serverTime.map { JSONObject().put("fieldPath", it).put("setToServerValue", "REQUEST_TIME") })

    private fun fields(m: Map<String, JSONObject>) = JSONObject().apply { m.forEach { (k, v) -> put(k, v) } }

    /** Create (fails if it exists — a retry of a create that landed is then a success). */
    fun create(path: String, f: Map<String, JSONObject>, serverTime: List<String>): JSONObject = JSONObject()
        .put("update", JSONObject().put("name", path).put("fields", fields(f)))
        .put("currentDocument", JSONObject().put("exists", false))
        .put("updateTransforms", transforms(serverTime))

    fun patch(path: String, f: Map<String, JSONObject>, serverTime: List<String>): JSONObject = JSONObject()
        .put("update", JSONObject().put("name", path).put("fields", fields(f)))
        .put("updateMask", JSONObject().put("fieldPaths", JSONArray(f.keys.toList())))
        .put("currentDocument", JSONObject().put("exists", true))
        .put("updateTransforms", transforms(serverTime))

    fun delete(path: String): JSONObject = JSONObject().put("delete", path)
}

object GlanceFirestore {
    enum class Outcome { DONE, OFFLINE, SIGNED_OUT, REJECTED }

    private const val PENDING = "glance.pending"

    fun root(s: Snap) = "projects/${s.projectId}/databases/(default)/documents"

    private fun base(s: Snap) = s.emulatorHost?.let { "http://${if (':' in it) it else "$it:8080"}/v1" }
        ?: "https://firestore.googleapis.com/v1"

    /** What a commit's answer means (the iOS rules: an existing create or a failed precondition is done). */
    fun outcome(status: Int, body: String): Outcome = when {
        status == 200 -> Outcome.DONE
        status == 401 -> Outcome.SIGNED_OUT
        status == 409 -> Outcome.DONE
        status == 400 && "FAILED_PRECONDITION" in body -> Outcome.DONE
        status in 500..599 -> Outcome.OFFLINE
        else -> Outcome.REJECTED
    }

    private fun token(context: Context): Pair<String?, Outcome?> {
        if (FirebaseAuth.getInstance().currentUser == null) return null to Outcome.SIGNED_OUT
        val t = AuthToken.idToken(context) ?: return null to Outcome.OFFLINE
        return t to null
    }

    /** Sends one commit; offline or without a session here it waits ("Chưa đồng bộ"). */
    fun commit(context: Context, s: Snap, writes: List<JSONObject>, queueIfOffline: Boolean = true): Outcome {
        val body = JSONObject().put("writes", JSONArray(writes)).toString()
        val outcome = send(context, s, body)
        if ((outcome == Outcome.OFFLINE || outcome == Outcome.SIGNED_OUT) && queueIfOffline) addPending(context, body)
        return outcome
    }

    fun send(context: Context, s: Snap, body: String): Outcome {
        val (token, failed) = token(context)
        if (token == null) return failed ?: Outcome.OFFLINE
        val c = URL("${base(s)}/${root(s)}:commit").openConnection() as HttpURLConnection
        return try {
            c.requestMethod = "POST"
            c.doOutput = true
            c.connectTimeout = 15_000
            c.readTimeout = 15_000
            c.setRequestProperty("Authorization", "Bearer $token")
            c.setRequestProperty("Content-Type", "application/json")
            val bytes = body.toByteArray()
            c.setFixedLengthStreamingMode(bytes.size)
            c.outputStream.use { it.write(bytes) }
            val status = c.responseCode
            val text = runCatching { (if (status < 400) c.inputStream else c.errorStream)?.bufferedReader()?.readText() }
                .getOrNull() ?: ""
            outcome(status, text)
        } catch (_: IOException) {
            Outcome.OFFLINE
        } finally {
            c.disconnect()
        }
    }

    // ---------- Offline queue ----------

    private fun prefs(context: Context) = context.applicationContext.getSharedPreferences("childlife.glance", Context.MODE_PRIVATE)

    fun pending(context: Context): List<String> = runCatching {
        val a = JSONArray(prefs(context).getString(PENDING, "[]"))
        (0 until a.length()).map { a.getString(it) }
    }.getOrDefault(emptyList())

    private fun setPending(context: Context, list: List<String>) {
        prefs(context).edit().putString(PENDING, JSONArray(list).toString()).apply()
        Glance.updateSnapshot(context) { it.put("pending", list.size) }
    }

    private fun addPending(context: Context, body: String) = synchronized(this) {
        setPending(context, pending(context) + body)
    }

    /** Retries queued writes, oldest first; keeps what still cannot be sent. */
    fun flushPending(context: Context) = synchronized(this) {
        val list = pending(context)
        if (list.isEmpty()) return
        val s = Glance.snapshot(context)?.let(::Snap) ?: return
        val left = mutableListOf<String>()
        for (body in list) {
            if (left.isNotEmpty()) {
                left += body
                continue
            }
            val outcome = send(context, s, body)
            if (outcome == Outcome.OFFLINE || outcome == Outcome.SIGNED_OUT) left += body
        }
        setPending(context, left)
    }

    /**
     * The live timer document (another device may have changed or ended it): its fields, null when
     * it is gone, or [UNKNOWN] offline.
     */
    val UNKNOWN = JSONObject()

    fun timer(context: Context, s: Snap, babyId: String, type: String): JSONObject? {
        val token = token(context).first ?: return UNKNOWN
        val c = URL("${base(s)}/${root(s)}/babies/$babyId/timers/$type").openConnection() as HttpURLConnection
        return try {
            c.connectTimeout = 10_000
            c.readTimeout = 10_000
            c.setRequestProperty("Authorization", "Bearer $token")
            when (c.responseCode) {
                404 -> null
                200 -> JSONObject(c.inputStream.bufferedReader().readText()).optJSONObject("fields") ?: UNKNOWN
                else -> UNKNOWN
            }
        } catch (_: IOException) {
            UNKNOWN
        } finally {
            c.disconnect()
        }
    }
}
