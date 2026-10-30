package app.childlife.child_life

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** The Cùng Chăm Con widgets' reading of the snapshot's `plan`, and their "Xong" (Figma 1356:23340). */
class GlancePlanTest {
    private fun item(id: String, time: String, task: String, mine: Boolean, done: Boolean, name: String = "") =
        """{"id":"$id","time":"$time","dueAt":0,"task":"$task","name":"$name","mine":$mine,"done":$done,"opensApp":false}"""

    private fun snapshot(vararg items: String) = JSONObject(
        """{"babyId":"b1","plan":{"date":"2026-10-30","helper":false,"me":"Ba","faces":["PersonBa","PersonMe"],
        "names":{"bottle":"Bú bình"},"items":[${items.joinToString(",")}]}}""",
    )

    @Test fun nextIsTheFirstOpenTaskOfMineAndProgressIsTheFamilys() {
        val s = snapshot(
            item("a", "07:00", "bottle", mine = true, done = true),
            item("b", "08:00", "bath", mine = false, done = true),
            item("c", "09:00", "vitamin", mine = true, done = false, name = "Vitamin D3"),
            item("d", "10:00", "read", mine = false, done = false),
            item("e", "11:00", "bottle", mine = true, done = false),
        )
        val p = Snap(s).plan!!
        assertEquals("c", p.next?.id)
        assertEquals(listOf("c", "e"), p.open.map { it.id })
        assertEquals(2, p.doneCount)
        assertEquals(5, p.total)
        assertFalse(p.rest)
        assertEquals("Vitamin D3", p.nameOf(p.next!!))
        // A task added on another phone comes without its name: the app's name for its key.
        assertEquals("Bú bình", p.nameOf(p.open[1]))
        assertEquals(listOf("PersonBa", "PersonMe"), p.faces)
    }

    @Test fun restWhenNothingOfMineIsLeft() {
        assertTrue(Snap(snapshot(item("a", "07:00", "bottle", mine = true, done = true),
            item("b", "08:00", "bath", mine = false, done = false))).plan!!.rest)
        assertTrue(Snap(snapshot()).plan!!.rest)
        assertNull(Snap(JSONObject("""{"plan":null}""")).plan)
    }

    @Test fun doneCallsTheFunctionAndPatchesTheSnapshot() {
        assertEquals(
            "setCarePlanItemStatus" to mapOf("babyId" to "b1", "date" to "2026-10-30", "itemId" to "pi_1", "status" to "done"),
            Plan.request("b1", "2026-10-30", "pi_1"),
        )
        val s = snapshot(item("pi_1", "09:00", "vitamin", mine = true, done = false))
        assertTrue(Plan.mark(s, "pi_1", true))
        assertTrue(Snap(s).plan!!.rest)
        assertTrue(Plan.mark(s, "pi_1", false))
        assertEquals("pi_1", Snap(s).plan!!.next?.id)
        assertFalse(Plan.mark(s, "gone", true))
        assertFalse(Plan.mark(JSONObject("{}"), "pi_1", true))
    }
}
