package app.childlife.child_life

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.net.Uri
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import java.util.concurrent.Executors
import org.json.JSONObject

/**
 * Cùng Chăm Con on the Home Screen (Figma 1356:23340; iOS: the plan widgets in ios/widget and
 * GlanceActions.planDone): medium "Việc của tôi" (the next task of mine + "Cả nhà 2/10"), small
 * "Cả nhà cùng chăm" (the family's ring, or "Nghỉ chút nhé"), large "Việc của tôi" (up to five
 * open tasks of mine). Drawn from the snapshot's `plan` (lib/features/glance/glance_plan.dart);
 * redrawn by GlanceUi.refresh with every other widget. Progress is the family's, never per person
 * (D-135 Q8).
 */
data class PlanItem(
    val id: String,
    val time: String,
    val dueAt: Long,
    val task: String,
    val name: String,
    val mine: Boolean,
    val done: Boolean,
    /** "Xong" writes a care log or starts the sleep timer first (D-138): it opens the app. */
    val opensApp: Boolean,
) {
    companion object {
        fun from(o: JSONObject) = PlanItem(
            o.optString("id"), o.optString("time"), o.optLong("dueAt"), o.optString("task"),
            o.optString("name"), o.optBoolean("mine"), o.optBoolean("done"), o.optBoolean("opensApp"),
        )
    }
}

/** Today's plan as the widgets read it: items in time order, skipped ones already out. */
class Plan(val json: JSONObject) {
    val date get() = json.optString("date")
    val helper get() = json.optBoolean("helper")
    /** "Ba" in "Việc của Ba". */
    val me get() = json.optString("me")
    val faces: List<String>
        get() = json.optJSONArray("faces")?.let { a -> (0 until a.length()).map { a.optString(it) } } ?: emptyList()
    val items: List<PlanItem>
        get() = json.optJSONArray("items")?.let { a ->
            (0 until a.length()).mapNotNull { a.optJSONObject(it) }.map(PlanItem::from)
        } ?: emptyList()

    val mine get() = items.filter { it.mine }
    /** Mine and not done yet, overdue ones included. */
    val open get() = mine.filter { !it.done }
    /** The task the medium widget offers to tick. */
    val next get() = open.firstOrNull()
    val doneCount get() = items.count { it.done }
    val total get() = items.size
    /** "Nghỉ chút nhé": nothing of mine left to do (or nothing planned at all). */
    val rest get() = open.isEmpty()

    /** The task's name; one added on another phone may come without, so the app's name for its key. */
    fun nameOf(item: PlanItem): String = item.name.takeIf { it.isNotEmpty() }
        ?: json.optJSONObject("names")?.optString(item.task)?.takeIf { it.isNotEmpty() }
        ?: item.task

    companion object {
        /** The `setCarePlanItemStatus` call a widget "Xong" makes (as iOS and the task push's "Xong"). */
        fun request(babyId: String, date: String, itemId: String): Pair<String, Map<String, Any?>> =
            "setCarePlanItemStatus" to mapOf("babyId" to babyId, "date" to date, "itemId" to itemId, "status" to "done")

        /** Ticks (or unticks) [itemId] in a snapshot; false when it is not there any more. */
        fun mark(snapshot: JSONObject, itemId: String, done: Boolean): Boolean {
            val items = snapshot.optJSONObject("plan")?.optJSONArray("items") ?: return false
            for (i in 0 until items.length()) {
                val o = items.optJSONObject(i) ?: continue
                if (o.optString("id") == itemId) {
                    o.put("done", done)
                    return true
                }
            }
            return false
        }
    }
}

val Snap.plan: Plan? get() = json.optJSONObject("plan")?.let(::Plan)

object PlanUi {
    // ---------- Copy ----------

    private fun fill(s: Snap?, key: String, fallback: String, values: Map<String, String> = emptyMap()): String {
        var out = s?.text(key, fallback) ?: fallback
        for ((k, v) in values) out = out.replace("{$k}", v)
        return out
    }

    private fun mineTitle(s: Snap, p: Plan) = fill(s, "plan.mine", "Việc của {name}", mapOf("name" to p.me))
    private fun family(s: Snap, p: Plan) =
        fill(s, "plan.family", "Cả nhà {done}/{total}", mapOf("done" to "${p.doneCount}", "total" to "${p.total}"))
    private fun rest(s: Snap) = fill(s, "plan.rest", "Nghỉ chút nhé")
    private fun none(s: Snap?) = if (s == null || !s.signedIn) fill(s, "signedOutTitle", "Đăng nhập để dùng widget")
        else fill(s, "plan.none", "Hôm nay chưa có lịch")
    private fun count(s: Snap, key: String, n: Int, fallback: String, one: String) =
        if (n == 1) fill(s, "$key.one", one) else fill(s, key, fallback, mapOf("n" to "$n"))

    // ---------- Art ----------

    // Plain lookups (no reflection), so release shrinking keeps every resource.
    fun art(task: String) = when (task) {
        "bottle" -> R.drawable.widget_art_bottle
        "breast", "pump", "vitamin", "water", "medicine" -> R.drawable.widget_art_breast
        "sleep" -> R.drawable.widget_art_sleep
        "diaper", "potty" -> R.drawable.widget_art_diaper
        "bath" -> R.drawable.widget_art_bath
        "read" -> R.drawable.widget_art_read
        else -> R.drawable.widget_art_baby
    }

    private fun tint(task: String) = when (task) {
        "bottle", "bath", "water" -> "bottle"
        "breast", "pump", "vitamin", "medicine" -> "breast"
        "sleep", "read" -> "sleep"
        "diaper", "potty" -> "diaper"
        else -> "neutral"
    }

    private fun tile(task: String) = when (tint(task)) {
        "bottle" -> R.drawable.widget_tile_bottle
        "breast" -> R.drawable.widget_tile_breast
        "sleep" -> R.drawable.widget_tile_sleep
        "diaper" -> R.drawable.widget_tile_diaper
        else -> R.drawable.widget_tile_neutral
    }

    private fun mini(task: String) = when (tint(task)) {
        "bottle" -> R.drawable.widget_plan_mini_bottle
        "breast" -> R.drawable.widget_plan_mini_breast
        "sleep" -> R.drawable.widget_plan_mini_sleep
        "diaper" -> R.drawable.widget_plan_mini_diaper
        else -> R.drawable.widget_plan_mini_neutral
    }

    fun face(key: String) = when (key) {
        "PersonBa" -> R.drawable.widget_face_ba
        "PersonMe" -> R.drawable.widget_face_me
        "PersonBaNoi" -> R.drawable.widget_face_ba_noi
        "PersonOng" -> R.drawable.widget_face_ong
        "PersonHelper" -> R.drawable.widget_face_helper
        else -> null
    }

    // ---------- Links and buttons ----------

    private fun link(context: Context, path: String): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
            .setAction(Intent.ACTION_VIEW)
            .setData(Uri.parse("${context.packageName}://app$path"))
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        return PendingIntent.getActivity(context, ("plan$path").hashCode(), intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
    }

    private fun together(context: Context, s: Snap?) = link(context, if (s?.signedIn == true) "/care/together" else "/")

    /**
     * A task's "đã làm": ticked from here (PlanActionReceiver), or, for a task that writes a log
     * first, its log over Hôm nay (`planDone`, glance_bridge.dart).
     */
    private fun doneClick(context: Context, p: Plan, item: PlanItem): PendingIntent =
        if (item.opensApp) link(context, "/today?planDone=${item.id}&date=${p.date}")
        else PendingIntent.getBroadcast(
            context, ("plan.done:${item.id}").hashCode(),
            Intent(context, PlanActionReceiver::class.java).setAction("${PlanActionReceiver.PREFIX}${item.id}"),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

    private fun doneButton(context: Context, v: RemoteViews, id: Int, s: Snap, p: Plan, item: PlanItem) {
        if (!s.canLog) {
            v.setViewVisibility(id, View.GONE)
            return
        }
        v.setViewVisibility(id, View.VISIBLE)
        v.setContentDescription(id, fill(s, "plan.markDone", "Đánh dấu đã làm: {task}", mapOf("task" to p.nameOf(item))))
        v.setOnClickPendingIntent(id, doneClick(context, p, item))
    }

    /** A palette colour by resource, so Android 12+ picks Light or Night care itself (as GlanceUi). */
    private fun color(context: Context, v: RemoteViews, id: Int, res: Int) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            v.setColorInt(id, "setTextColor", themed(context, res, night = false), themed(context, res, night = true))
        } else {
            v.setTextColor(id, context.getColor(res))
        }
    }

    private fun themed(context: Context, res: Int, night: Boolean): Int {
        val config = Configuration(context.resources.configuration)
        config.uiMode = (config.uiMode and Configuration.UI_MODE_NIGHT_MASK.inv()) or
            (if (night) Configuration.UI_MODE_NIGHT_YES else Configuration.UI_MODE_NIGHT_NO)
        return context.createConfigurationContext(config).getColor(res)
    }

    private fun ring(v: RemoteViews, id: Int, p: Plan) =
        v.setProgressBar(id, maxOf(1, p.total), p.doneCount, false)

    // ---------- Medium: the next task of mine ----------

    fun next(context: Context, s: Snap?): RemoteViews {
        val v = RemoteViews(context.packageName, R.layout.widget_plan_next)
        v.setOnClickPendingIntent(R.id.root, together(context, s))
        val p = s?.takeIf { it.signedIn }?.plan
        if (s == null || p == null) {
            v.setInt(R.id.tile, "setBackgroundResource", R.drawable.widget_tile_neutral)
            v.setImageViewResource(R.id.art, R.drawable.widget_art_baby)
            v.setViewVisibility(R.id.mine, View.GONE)
            v.setTextViewText(R.id.task, none(s))
            v.setViewVisibility(R.id.done, View.GONE)
            v.setViewVisibility(R.id.family_row, View.INVISIBLE)
            return v
        }
        v.setViewVisibility(R.id.mine, View.VISIBLE)
        v.setTextViewText(R.id.mine, mineTitle(s, p))
        val item = p.next
        if (item == null) {
            v.setInt(R.id.tile, "setBackgroundResource", R.drawable.widget_bg_plan_rest)
            v.setImageViewResource(R.id.art, R.drawable.widget_art_baby)
            v.setTextViewText(R.id.task, rest(s))
            v.setViewVisibility(R.id.done, View.GONE)
        } else {
            v.setInt(R.id.tile, "setBackgroundResource", tile(item.task))
            v.setImageViewResource(R.id.art, art(item.task))
            v.setTextViewText(R.id.task, "${item.time} · ${p.nameOf(item)}")
            doneButton(context, v, R.id.done, s, p, item)
        }
        v.setViewVisibility(R.id.family_row, View.VISIBLE)
        ring(v, R.id.ring, p)
        v.setTextViewText(R.id.family, family(s, p))
        val faces = p.faces.mapNotNull(::face).take(4)
        listOf(R.id.face1, R.id.face2, R.id.face3, R.id.face4).forEachIndexed { i, id ->
            val res = faces.getOrNull(i)
            if (res == null) {
                v.setViewVisibility(id, View.GONE)
            } else {
                v.setViewVisibility(id, View.VISIBLE)
                v.setImageViewResource(id, res)
            }
        }
        return v
    }

    // ---------- Small: the family's progress ----------

    fun family(context: Context, s: Snap?): RemoteViews {
        val v = RemoteViews(context.packageName, R.layout.widget_plan_family)
        v.setOnClickPendingIntent(R.id.root, together(context, s))
        val p = s?.takeIf { it.signedIn }?.plan
        v.setViewVisibility(R.id.none, View.GONE)
        v.setViewVisibility(R.id.progress_box, View.GONE)
        v.setViewVisibility(R.id.rest_box, View.GONE)
        when {
            s == null || p == null -> {
                v.setInt(R.id.root, "setBackgroundResource", R.drawable.widget_bg)
                v.setViewVisibility(R.id.none, View.VISIBLE)
                v.setTextViewText(R.id.none, none(s))
            }
            p.rest -> {
                v.setInt(R.id.root, "setBackgroundResource", R.drawable.widget_bg_plan_rest)
                v.setViewVisibility(R.id.rest_box, View.VISIBLE)
                v.setTextViewText(R.id.rest, rest(s))
            }
            else -> {
                v.setInt(R.id.root, "setBackgroundResource", R.drawable.widget_bg)
                v.setViewVisibility(R.id.progress_box, View.VISIBLE)
                ring(v, R.id.ring, p)
                v.setTextViewText(R.id.count, "${p.doneCount}/${p.total}")
                v.setContentDescription(R.id.count, family(s, p))
                v.setTextViewText(R.id.left, count(s, "plan.left", p.total - p.doneCount, "Còn {n} việc", "Còn 1 việc"))
            }
        }
        return v
    }

    // ---------- Large: my open tasks ----------

    private fun rowIds(n: Int) = when (n) {
        1 -> listOf(R.id.row1, R.id.row1_time, R.id.row1_tile, R.id.row1_art, R.id.row1_name, R.id.row1_done)
        2 -> listOf(R.id.row2, R.id.row2_time, R.id.row2_tile, R.id.row2_art, R.id.row2_name, R.id.row2_done)
        3 -> listOf(R.id.row3, R.id.row3_time, R.id.row3_tile, R.id.row3_art, R.id.row3_name, R.id.row3_done)
        4 -> listOf(R.id.row4, R.id.row4_time, R.id.row4_tile, R.id.row4_art, R.id.row4_name, R.id.row4_done)
        else -> listOf(R.id.row5, R.id.row5_time, R.id.row5_tile, R.id.row5_art, R.id.row5_name, R.id.row5_done)
    }

    fun mine(context: Context, s: Snap?): RemoteViews {
        val v = RemoteViews(context.packageName, R.layout.widget_plan_mine)
        v.setOnClickPendingIntent(R.id.root, together(context, s))
        val p = s?.takeIf { it.signedIn }?.plan
        val faceKey = if (p?.helper == true) "PersonHelper" else p?.faces?.firstOrNull()
        v.setImageViewResource(R.id.face, faceKey?.let(::face) ?: R.drawable.widget_art_baby)
        v.setViewVisibility(R.id.count, View.GONE)
        val open = p?.open ?: emptyList()
        if (s == null || p == null || open.isEmpty()) {
            v.setTextViewText(R.id.mine, if (s != null && p != null) mineTitle(s, p) else fill(s, "appName", "Child Life"))
            v.setViewVisibility(R.id.rows, View.GONE)
            v.setViewVisibility(R.id.rest_box, View.VISIBLE)
            v.setTextViewText(R.id.rest, if (s != null && p != null) rest(s) else none(s))
            return v
        }
        v.setTextViewText(R.id.mine, mineTitle(s, p))
        v.setViewVisibility(R.id.count, View.VISIBLE)
        v.setTextViewText(R.id.count, count(s, "plan.count", open.size, "{n} việc", "1 việc"))
        v.setViewVisibility(R.id.rest_box, View.GONE)
        v.setViewVisibility(R.id.rows, View.VISIBLE)
        for (n in 1..5) {
            val ids = rowIds(n)
            val (row, time, tileId, artId, name) = ids
            val done = ids[5]
            val item = open.getOrNull(n - 1)
            if (item == null) {
                v.setViewVisibility(row, View.GONE)
                continue
            }
            val first = n == 1
            v.setViewVisibility(row, View.VISIBLE)
            v.setTextViewText(time, item.time)
            color(context, v, time, if (first) R.color.cl_mint_text else R.color.cl_ink)
            v.setInt(tileId, "setBackgroundResource", mini(item.task))
            v.setImageViewResource(artId, art(item.task))
            v.setTextViewText(name, p.nameOf(item))
            v.setImageViewResource(done, if (first) R.drawable.widget_plan_hollow_first else R.drawable.widget_plan_hollow)
            doneButton(context, v, done, s, p, item)
        }
        return v
    }
}

/**
 * A widget "Xong" on a task that needs nothing written (vitamin, đọc sách): ticked at once on
 * every plan widget, then by the `setCarePlanItemStatus` Function as this person (the ID token,
 * once more refreshed on 401, as PushActionReceiver); put back if the Function says no or cannot
 * be reached. No child data in logs.
 */
class PlanActionReceiver : BroadcastReceiver() {
    private val io = Executors.newSingleThreadExecutor()

    override fun onReceive(context: Context, intent: Intent) {
        val itemId = intent.action?.takeIf { it.startsWith(PREFIX) }?.removePrefix(PREFIX) ?: return
        val app = context.applicationContext
        val pending = goAsync()
        io.execute {
            try {
                done(app, itemId)
            } catch (_: Exception) {
                // The widgets redraw from the snapshot as it is.
            } finally {
                pending.finish()
            }
        }
    }

    private fun done(context: Context, itemId: String) {
        val s = Glance.snapshot(context)?.let(::Snap) ?: return
        if (!s.signedIn || !s.canLog) return
        val babyId = s.babyId ?: return
        val plan = s.plan ?: return
        // A second tap while the first is on its way does nothing.
        if (plan.items.none { it.id == itemId && !it.done }) return
        val project = s.projectId.takeIf { it.isNotEmpty() } ?: return
        Glance.updateSnapshot(context) { Plan.mark(it, itemId, true) }
        val (name, data) = Plan.request(babyId, plan.date, itemId)
        val client = CallableClient(project, s.emulatorHost)
        var status: Int? = null
        var token = AuthToken.idToken(context)
        if (token != null) {
            status = client.call(name, token, data)
            if (status == 401) {
                token = AuthToken.idToken(context, force = true)
                status = token?.let { client.call(name, it, data) }
            }
        }
        debugTrace(context, "$name answered $status")
        if (status !in 200..299) Glance.updateSnapshot(context) { Plan.mark(it, itemId, false) }
    }

    companion object {
        const val PREFIX = "app.childlife.plan.done:"
    }
}

class PlanNextWidget : GlanceWidget()
class PlanFamilyWidget : GlanceWidget()
class PlanMineWidget : GlanceWidget()
