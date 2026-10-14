package app.childlife.child_life

import android.content.Context
import java.util.UUID
import org.json.JSONObject

/**
 * One-tap care actions from widgets and the timer notice (W5 "chạy ngầm"; iOS:
 * ios/Shared/GlanceActions.swift): the same documents the app writes (CareRecord.toCreateJson,
 * CareTimer.toJson / toRecord), the snapshot patched first so the widget answers at once,
 * Firestore after. Offline writes wait (GlanceFirestore's queue). Off the main thread only.
 */
object GlanceActions {
    enum class Result { DONE, SIGNED_OUT, NOT_ALLOWED, NOTHING }

    fun newHex() = UUID.randomUUID().toString().replace("-", "").lowercase()

    private data class Ready(val s: Snap, val babyId: String, val uid: String, val author: JSONObject)

    private fun ready(context: Context): Ready? {
        val s = Glance.snapshot(context)?.let(::Snap) ?: return null
        if (!s.signedIn || !s.canLog) return null
        return Ready(s, s.babyId ?: return null, s.uid ?: return null, s.author ?: return null)
    }

    private fun author(a: JSONObject) = FS.map(
        mapOf(
            "name" to FS.str(a.optString("name")),
            "relation" to FS.str(a.optString("relation")),
            "relationCustom" to (a.optString("relationCustom").takeIf { it.isNotEmpty() && !a.isNull("relationCustom") }
                ?.let(FS::str) ?: FS.nul()),
        ),
    )

    /** The record a log creates (validNewRecord). */
    fun recordWrite(
        r: Snap, babyId: String, uid: String, author: JSONObject, id: String, type: String,
        occurredAt: Long, endedAt: Long?, data: Map<String, JSONObject>, now: Long,
    ): JSONObject = FS.create(
        "${GlanceFirestore.root(r)}/babies/$babyId/records/$id",
        mapOf(
            "id" to FS.str(id),
            "babyId" to FS.str(babyId),
            "type" to FS.str(type),
            "occurredAt" to FS.time(occurredAt),
            "endedAt" to (endedAt?.let(FS::time) ?: FS.nul()),
            "data" to FS.map(data),
            "createdBy" to FS.str(uid),
            "author" to author(author),
            "clientCreatedAt" to FS.time(now),
            "updatedBy" to FS.str(uid),
            "deleted" to FS.bool(false),
            "deletedAt" to FS.nul(),
            "deletedBy" to FS.nul(),
            "source" to FS.str("app"),
        ),
        listOf("createdAt", "updatedAt"),
    )

    private fun finish(context: Context, outcome: GlanceFirestore.Outcome): Result {
        GlanceUi.refresh(context)
        return when (outcome) {
            GlanceFirestore.Outcome.SIGNED_OUT -> Result.SIGNED_OUT
            GlanceFirestore.Outcome.REJECTED -> Result.NOT_ALLOWED
            else -> Result.DONE
        }
    }

    // ---------- One-tap logs (Hoàn tác ~5 s) ----------

    /** Small Bottle "+ 120 ml": the last amount and milk again. */
    fun logBottle(context: Context): Result {
        val (s, babyId, uid, a) = ready(context) ?: return Result.SIGNED_OUT
        val now = System.currentTimeMillis()
        val id = "r_${newHex()}"
        val amount = s.lastBottle?.amountMl
        val milk = s.lastBottle?.milk ?: "formula"
        Glance.updateSnapshot(context) { j ->
            val snap = Snap(j)
            val previous = snap.lastBottle
            j.put("lastBottle", Last(now, snap.text("you", "Bạn"), amount, milk).toJson())
            j.put("bottlesToday", snap.bottlesToday + 1)
            j.put("feedsToday", snap.feedsToday + 1)
            j.put("bottleMlToday", snap.bottleMlToday + (amount ?: 0))
            val label = amount?.let { snap.text("loggedBottle", mapOf("ml" to "$it")) } ?: snap.text("bottle", "Bú bình")
            j.put("logged", Logged(id, "bottle", label, now, previous).toJson())
        }
        val write = recordWrite(s, babyId, uid, a, id, "bottle", now, null,
            mapOf("amountMl" to (amount?.let(FS::int) ?: FS.nul()), "milk" to FS.str(milk)), now)
        val outcome = GlanceFirestore.commit(context, s, listOf(write))
        // Refused (no right to log any more, say): it is not on the widget either.
        if (outcome == GlanceFirestore.Outcome.REJECTED) revert(context, id)
        return finish(context, outcome)
    }

    /** Small Diaper "Ướt / Bẩn / Cả hai". */
    fun logDiaper(context: Context, kind: String): Result {
        val (s, babyId, uid, a) = ready(context) ?: return Result.SIGNED_OUT
        val now = System.currentTimeMillis()
        val id = "r_${newHex()}"
        Glance.updateSnapshot(context) { j ->
            val snap = Snap(j)
            val previous = snap.lastDiaper
            j.put("lastDiaper", Last(now, snap.text("you", "Bạn"), kind = kind).toJson())
            j.put("diapersToday", snap.diapersToday + 1)
            val label = snap.text("loggedDiaper", mapOf("kind" to snap.text("diaper.$kind", kind)))
            j.put("logged", Logged(id, "diaper", label, now, previous).toJson())
        }
        val write = recordWrite(s, babyId, uid, a, id, "diaper", now, null, mapOf("kind" to FS.str(kind)), now)
        val outcome = GlanceFirestore.commit(context, s, listOf(write))
        if (outcome == GlanceFirestore.Outcome.REJECTED) revert(context, id)
        return finish(context, outcome)
    }

    /** Takes a one-tap log back out of the widgets (Hoàn tác, or the server refused it). */
    fun revert(context: Context, recordId: String) {
        Glance.updateSnapshot(context) { j ->
            val snap = Snap(j)
            val logged = snap.logged?.takeIf { it.recordId == recordId } ?: return@updateSnapshot
            when (logged.type) {
                "bottle" -> {
                    j.put("bottleMlToday", maxOf(0, snap.bottleMlToday - (snap.lastBottle?.amountMl ?: 0)))
                    j.put("lastBottle", logged.previous?.toJson() ?: JSONObject.NULL)
                    j.put("bottlesToday", maxOf(0, snap.bottlesToday - 1))
                    j.put("feedsToday", maxOf(0, snap.feedsToday - 1))
                }
                "diaper" -> {
                    j.put("lastDiaper", logged.previous?.toJson() ?: JSONObject.NULL)
                    j.put("diapersToday", maxOf(0, snap.diapersToday - 1))
                }
            }
            j.remove("logged")
        }
    }

    /** "Hoàn tác": the soft delete the app's Undo does (validRecordUpdate). */
    fun undo(context: Context, recordId: String): Result {
        val (s, babyId, uid, _) = ready(context) ?: return Result.SIGNED_OUT
        revert(context, recordId)
        val write = FS.patch(
            "${GlanceFirestore.root(s)}/babies/$babyId/records/$recordId",
            mapOf("deleted" to FS.bool(true), "deletedBy" to FS.str(uid), "updatedBy" to FS.str(uid)),
            listOf("deletedAt", "updatedAt"),
        )
        return finish(context, GlanceFirestore.commit(context, s, listOf(write)))
    }

    // ---------- Timers (Bắt đầu ngủ / Thức dậy, Bắt đầu bú / Đổi bên / Xong) ----------

    private fun sides(l: Side, r: Side) = FS.map(
        mapOf(
            "left" to FS.map(mapOf("accumulatedMs" to FS.int(l.accumulatedMs), "runningSince" to (l.runningSince?.let(FS::time) ?: FS.nul()))),
            "right" to FS.map(mapOf("accumulatedMs" to FS.int(r.accumulatedMs), "runningSince" to (r.runningSince?.let(FS::time) ?: FS.nul()))),
        ),
    )

    fun start(context: Context, type: String, side: String = "left"): Result {
        val (s, babyId, uid, a) = ready(context) ?: return Result.SIGNED_OUT
        if ((if (type == "sleep") s.sleep else s.breast) != null) return Result.NOTHING
        val now = System.currentTimeMillis()
        val session = newHex()
        val left = Side(0, if (side == "left") now else null)
        val right = Side(0, if (side == "right") now else null)
        val timer = Timer(type, session, now, uid, s.text("you", "Bạn"),
            if (type == "sleep") null else left, if (type == "sleep") null else right, false)
        Glance.updateSnapshot(context) { it.put(type, timer.toJson()) }
        val write = FS.create(
            "${GlanceFirestore.root(s)}/babies/$babyId/timers/$type",
            mapOf(
                "type" to FS.str(type),
                "babyId" to FS.str(babyId),
                "sessionId" to FS.str(session),
                "startedAt" to FS.time(now),
                "startedBy" to FS.str(uid),
                "author" to author(a),
                "sides" to if (type == "sleep") FS.nul() else sides(left, right),
                "paused" to FS.bool(false),
                "pausedSides" to FS.arr(emptyList()),
                "updatedBy" to FS.str(uid),
            ),
            listOf("updatedAt"),
        )
        return finish(context, GlanceFirestore.commit(context, s, listOf(write)))
    }

    /** The timer as it is now on the server; the snapshot's when offline; null when it is gone. */
    private fun current(context: Context, s: Snap, babyId: String, type: String): Timer? {
        val local = if (type == "sleep") s.sleep else s.breast
        val f = GlanceFirestore.timer(context, s, babyId, type)
        if (f === GlanceFirestore.UNKNOWN) return local
        if (f == null) return null
        fun str(k: String) = f.optJSONObject(k)?.optString("stringValue")?.takeIf { it.isNotEmpty() }
        fun time(v: JSONObject?) = v?.optString("timestampValue")?.takeIf { it.isNotEmpty() }?.let(FS::parseIso)
        fun side(v: JSONObject?): Side? {
            val m = v?.optJSONObject("mapValue")?.optJSONObject("fields") ?: return null
            return Side(m.optJSONObject("accumulatedMs")?.optString("integerValue")?.toLongOrNull() ?: 0,
                time(m.optJSONObject("runningSince")))
        }
        val session = str("sessionId") ?: return local
        val startedAt = time(f.optJSONObject("startedAt")) ?: return local
        val sides = f.optJSONObject("sides")?.optJSONObject("mapValue")?.optJSONObject("fields")
        return Timer(type, session, startedAt, str("startedBy") ?: "", local?.byName ?: "",
            side(sides?.optJSONObject("left")), side(sides?.optJSONObject("right")),
            f.optJSONObject("paused")?.optBoolean("booleanValue") ?: false)
    }

    /**
     * "Thức dậy" (sleep) / "Xong" · "Kết thúc" (breast): the session's record `r_<sessionId>` and
     * the timer's end in one commit, like CareRepository.endTimer.
     */
    fun end(context: Context, type: String): Result {
        val (s, babyId, uid, a) = ready(context) ?: return Result.SIGNED_OUT
        val t = current(context, s, babyId, type) ?: run {
            Glance.updateSnapshot(context) { it.remove(type) }
            GlanceUi.refresh(context)
            return Result.NOTHING
        }
        val now = System.currentTimeMillis()
        val record = if (type == "sleep") {
            val end = minOf(now, t.startedAt + 24 * 3_600_000L)
            Glance.updateSnapshot(context) { j ->
                val snap = Snap(j)
                val minutes = Math.round((end - t.startedAt) / 60_000.0).toInt()
                j.remove("sleep")
                j.put("lastWokeAt", now)
                j.put("lastSleepMin", minutes)
                j.put("sleptTodayMin", snap.sleptTodayMin + minutes)
            }
            recordWrite(s, babyId, uid, a, "r_${t.sessionId}", "sleep", t.startedAt, end, emptyMap(), now)
        } else {
            val leftS = (t.left?.elapsedMs(now) ?: 0) / 1000.0
            val rightS = (t.right?.elapsedMs(now) ?: 0) / 1000.0
            val minutes = minOf(240, maxOf(1, Math.round((leftS + rightS) / 60).toInt()))
            val side = if (leftS > 0 && rightS > 0) "both" else if (rightS > 0) "right" else "left"
            val data = mutableMapOf(
                "side" to FS.str(side),
                "durationMin" to FS.int(minutes),
                "leftMin" to FS.int(Math.round(leftS / 60).toInt()),
                "rightMin" to FS.int(Math.round(rightS / 60).toInt()),
            )
            t.activeSide?.let { data["endSide"] = FS.str(it) }
            Glance.updateSnapshot(context) { j ->
                val snap = Snap(j)
                j.remove("breast")
                j.put("lastBreast", Last(now, snap.text("you", "Bạn"), side = side, durationMin = minutes).toJson())
                j.put("breastsToday", snap.breastsToday + 1)
                j.put("feedsToday", snap.feedsToday + 1)
            }
            recordWrite(s, babyId, uid, a, "r_${t.sessionId}", "breast", t.startedAt,
                t.startedAt + minutes * 60_000L, data, now)
        }
        val outcome = GlanceFirestore.commit(context, s,
            listOf(record, FS.delete("${GlanceFirestore.root(s)}/babies/$babyId/timers/$type")))
        return finish(context, outcome)
    }

    /** "Đổi bên": stop the running side, start the other (CareTimer.switchTo). */
    fun switchSide(context: Context): Result {
        val (s, babyId, uid, _) = ready(context) ?: return Result.SIGNED_OUT
        val t = current(context, s, babyId, "breast") ?: return Result.NOTHING
        val now = System.currentTimeMillis()
        val next = if (t.activeSide == "left") "right" else "left"
        fun stop(x: Side?) = (x ?: Side(0, null)).let { Side(it.elapsedMs(now), null) }
        fun run(x: Side?) = (x ?: Side(0, null)).let { if (it.runningSince == null) Side(it.accumulatedMs, now) else it }
        val left = if (next == "left") run(t.left) else stop(t.left)
        val right = if (next == "right") run(t.right) else stop(t.right)
        val updated = t.copy(left = left, right = right, paused = false)
        Glance.updateSnapshot(context) { it.put("breast", updated.toJson()) }
        val write = FS.patch(
            "${GlanceFirestore.root(s)}/babies/$babyId/timers/breast",
            mapOf(
                "sides" to sides(left, right),
                "paused" to FS.bool(false),
                "pausedSides" to FS.arr(emptyList()),
                "updatedBy" to FS.str(uid),
            ),
            listOf("updatedAt"),
        )
        return finish(context, GlanceFirestore.commit(context, s, listOf(write)))
    }
}
