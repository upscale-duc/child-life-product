package app.childlife.child_life

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import org.json.JSONObject

/**
 * The glance snapshot as native code reads it (the JSON `buildGlanceSnapshot` writes; iOS:
 * GlanceSnapshot in ios/Shared/GlanceStore.swift). Dates are epoch milliseconds. A thin view
 * over the JSON, so what native code adds (`logged`, `pending`) survives Dart's next write.
 */
class Snap(val json: JSONObject) {
    val signedIn get() = json.optBoolean("signedIn")
    val canLog get() = json.optBoolean("canLog")
    val canAddMemories get() = json.optBoolean("canAddMemories")
    val locale get() = json.optString("locale", "vi")
    val projectId get() = json.optString("projectId")
    val emulatorHost get() = json.optString("emulatorHost").takeIf { it.isNotEmpty() && !json.isNull("emulatorHost") }
    val uid get() = str("uid")
    val babyId get() = str("babyId")
    val nickname get() = str("nickname")
    val author get() = json.optJSONObject("author")
    val lastBottle get() = last("lastBottle")
    val lastBreast get() = last("lastBreast")
    val lastDiaper get() = last("lastDiaper")
    val lastWokeAt get() = long("lastWokeAt")
    val lastSleepMin get() = long("lastSleepMin")?.toInt()
    val sleptTodayMin get() = json.optInt("sleptTodayMin")
    val feedsToday get() = json.optInt("feedsToday")
    val bottleMlToday get() = json.optInt("bottleMlToday")
    val bottlesToday get() = json.optInt("bottlesToday")
    val breastsToday get() = json.optInt("breastsToday")
    val diapersToday get() = json.optInt("diapersToday")
    val sleep get() = timer("sleep")
    val breast get() = timer("breast")
    val pending get() = json.optInt("pending")
    val logged get() = json.optJSONObject("logged")?.let { Logged.from(it) }
    val recent: List<Recent>
        get() = json.optJSONArray("recent")?.let { a ->
            (0 until a.length()).mapNotNull { a.optJSONObject(it) }.map {
                Recent(it.optString("id"), it.optLong("at"), it.optString("type"), it.optString("text"), it.optString("by"))
            }
        } ?: emptyList()

    val isEmpty get() = lastBottle == null && lastBreast == null && lastDiaper == null && sleep == null &&
        breast == null && lastWokeAt == null

    fun str(k: String) = json.optString(k).takeIf { it.isNotEmpty() && !json.isNull(k) }
    fun long(k: String) = if (json.has(k) && !json.isNull(k)) json.optLong(k) else null
    private fun last(k: String) = json.optJSONObject(k)?.let { Last.from(it) }
    private fun timer(k: String) = json.optJSONObject(k)?.let { Timer.from(it) }

    fun text(key: String, fallback: String = ""): String =
        json.optJSONObject("copy")?.optString(key)?.takeIf { it.isNotEmpty() } ?: fallback

    fun text(key: String, values: Map<String, String>): String {
        var s = json.optJSONObject("copy")?.optString(key)?.takeIf { it.isNotEmpty() } ?: key
        for ((k, v) in values) s = s.replace("{$k}", v)
        return s
    }

    fun loggedNow(type: String, now: Long): Logged? =
        logged?.takeIf { it.type == type && now < it.at + UNDO_MS }

    companion object {
        const val UNDO_MS = 5_000L
    }
}

data class Last(
    val at: Long,
    val by: String,
    val amountMl: Int? = null,
    val milk: String? = null,
    val kind: String? = null,
    val side: String? = null,
    val durationMin: Int? = null,
) {
    fun toJson(): JSONObject = JSONObject().put("at", at).put("by", by).put("amountMl", amountMl ?: JSONObject.NULL)
        .put("milk", milk ?: JSONObject.NULL).put("kind", kind ?: JSONObject.NULL).put("side", side ?: JSONObject.NULL)
        .put("durationMin", durationMin ?: JSONObject.NULL)

    companion object {
        fun from(o: JSONObject) = Last(
            at = o.optLong("at"), by = o.optString("by"),
            amountMl = if (o.isNull("amountMl")) null else o.optInt("amountMl"),
            milk = o.optString("milk").takeIf { it.isNotEmpty() && !o.isNull("milk") },
            kind = o.optString("kind").takeIf { it.isNotEmpty() && !o.isNull("kind") },
            side = o.optString("side").takeIf { it.isNotEmpty() && !o.isNull("side") },
            durationMin = if (o.isNull("durationMin") || !o.has("durationMin")) null else o.optInt("durationMin"),
        )
    }
}

data class Side(val accumulatedMs: Long, val runningSince: Long?) {
    fun elapsedMs(now: Long) = accumulatedMs + (runningSince?.let { maxOf(0, now - it) } ?: 0)
    fun toJson(): JSONObject = JSONObject().put("accumulatedMs", accumulatedMs).put("runningSince", runningSince ?: JSONObject.NULL)

    companion object {
        fun from(o: JSONObject?) = o?.let {
            Side(it.optLong("accumulatedMs"), if (it.isNull("runningSince") || !it.has("runningSince")) null else it.optLong("runningSince"))
        }
    }
}

data class Timer(
    val type: String,
    val sessionId: String,
    val startedAt: Long,
    val startedBy: String,
    val byName: String,
    val left: Side?,
    val right: Side?,
    val paused: Boolean,
) {
    val activeSide get() = when {
        left?.runningSince != null -> "left"
        right?.runningSince != null -> "right"
        else -> null
    }

    fun totalMs(now: Long) =
        if (type == "sleep") maxOf(0, now - startedAt) else (left?.elapsedMs(now) ?: 0) + (right?.elapsedMs(now) ?: 0)

    fun toJson(): JSONObject = JSONObject().put("type", type).put("sessionId", sessionId).put("startedAt", startedAt)
        .put("startedBy", startedBy).put("byName", byName).put("left", left?.toJson() ?: JSONObject.NULL)
        .put("right", right?.toJson() ?: JSONObject.NULL).put("paused", paused)

    companion object {
        fun from(o: JSONObject) = Timer(
            o.optString("type"), o.optString("sessionId"), o.optLong("startedAt"), o.optString("startedBy"),
            o.optString("byName"), Side.from(o.optJSONObject("left")), Side.from(o.optJSONObject("right")),
            o.optBoolean("paused"),
        )
    }
}

data class Recent(val id: String, val at: Long, val type: String, val text: String, val by: String)

/** "Đã ghi Thay tã · Ướt" + "Hoàn tác" for 5 s after a one-tap log (W4/W5). */
data class Logged(val recordId: String, val type: String, val label: String, val at: Long, val previous: Last?) {
    fun toJson(): JSONObject = JSONObject().put("recordId", recordId).put("type", type).put("label", label).put("at", at)
        .put("previous", previous?.toJson() ?: JSONObject.NULL)

    companion object {
        fun from(o: JSONObject) = Logged(
            o.optString("recordId"), o.optString("type"), o.optString("label"), o.optLong("at"),
            o.optJSONObject("previous")?.let { Last.from(it) },
        )
    }
}

/** Times and durations in the app's words (ios/widget/GlanceTheme.swift GlanceFormat). */
class GlanceFormat(private val s: Snap) {
    private val locale = if (s.locale == "en") Locale.UK else Locale.forLanguageTag("vi-VN")

    fun time(ms: Long): String = SimpleDateFormat("HH:mm", locale).format(Date(ms))

    fun day(ms: Long): String {
        val out = SimpleDateFormat(if (s.locale == "en") "EEEE d MMMM" else "EEEE, d MMMM", locale).format(Date(ms))
        return out.replaceFirstChar { it.titlecase(locale) }
    }

    /** "1 giờ 25 phút" / "45 phút" (long) or "1g 25p" / "45p" (short). */
    fun duration(ms: Long, short: Boolean = false): String {
        val total = maxOf(0, ms / 60_000).toInt()
        val h = total / 60
        val m = total % 60
        val p = if (short) "durS" else "dur"
        return when {
            h == 0 -> s.text("$p.m", mapOf("m" to "${maxOf(m, 1)}"))
            m == 0 -> s.text("$p.h", mapOf("h" to "$h"))
            else -> s.text("$p.hm", mapOf("h" to "$h", "m" to "$m"))
        }
    }

    fun ago(at: Long, now: Long): String =
        if (now - at < 60_000) s.text("justNow", "Vừa xong") else s.text("ago", mapOf("t" to duration(now - at)))

    fun by(name: String) = s.text("loggedBy", mapOf("name" to name))

    fun diaper(kind: String?) = s.text("diaper.${kind ?: "wet"}", kind ?: "")
}
