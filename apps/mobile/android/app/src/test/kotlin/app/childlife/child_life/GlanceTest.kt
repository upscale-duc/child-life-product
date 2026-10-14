package app.childlife.child_life

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The widget's writes are the iOS widget's (ios/Shared/GlanceActions.swift, GlanceFirestore.swift),
 * field for field, so the same Firestore Rules accept them; and the snapshot reads and formats as
 * on iOS (A5).
 */
class GlanceTest {
    private val snap = Snap(
        JSONObject(
            """
            {"signedIn":true,"canLog":true,"locale":"vi","projectId":"child-life-dev","emulatorHost":null,
             "uid":"u1","babyId":"b1","nickname":"Teddy",
             "author":{"name":"Mai","relation":"mother","relationCustom":null},
             "lastBottle":{"at":1000,"by":"Bạn","amountMl":120,"milk":"formula","kind":null,"side":null,"durationMin":null},
             "breast":{"type":"breast","sessionId":"s1","startedAt":0,"startedBy":"u1","byName":"Bạn",
                       "left":{"accumulatedMs":60000,"runningSince":null},"right":{"accumulatedMs":0,"runningSince":120000},"paused":false},
             "copy":{"dur.m":"{m} phút","dur.h":"{h} giờ","dur.hm":"{h} giờ {m} phút","durS.hm":"{h}g {m}p",
                     "ago":"{t} trước","justNow":"Vừa xong"},
             "recent":[{"id":"r_1","at":5,"type":"diaper","text":"Ướt","by":"Bạn"}],"pending":0}
            """,
        ),
    )

    @Test fun aRecordWriteIsTheAppsDocument() {
        val w = GlanceActions.recordWrite(snap, "b1", "u1", snap.author!!, "r_abc", "bottle", 1_760_000_000_000,
            null, mapOf("amountMl" to FS.int(120), "milk" to FS.str("formula")), 1_760_000_000_500)
        val update = w.getJSONObject("update")
        assertEquals("projects/child-life-dev/databases/(default)/documents/babies/b1/records/r_abc", update.getString("name"))
        val f = update.getJSONObject("fields")
        assertEquals(
            setOf("id", "babyId", "type", "occurredAt", "endedAt", "data", "createdBy", "author", "clientCreatedAt",
                "updatedBy", "deleted", "deletedAt", "deletedBy", "source"),
            f.keys().asSequence().toSet(),
        )
        assertEquals("2025-10-09T08:53:20.000Z", f.getJSONObject("occurredAt").getString("timestampValue"))
        assertTrue(f.getJSONObject("endedAt").has("nullValue"))
        assertEquals("120", f.getJSONObject("data").getJSONObject("mapValue").getJSONObject("fields")
            .getJSONObject("amountMl").getString("integerValue"))
        val author = f.getJSONObject("author").getJSONObject("mapValue").getJSONObject("fields")
        assertEquals("Mai", author.getJSONObject("name").getString("stringValue"))
        assertTrue(author.getJSONObject("relationCustom").has("nullValue"))
        assertEquals("app", f.getJSONObject("source").getString("stringValue"))
        assertFalse(w.getJSONObject("currentDocument").getBoolean("exists"))
        val t = w.getJSONArray("updateTransforms")
        assertEquals(listOf("createdAt", "updatedAt"), (0 until t.length()).map { t.getJSONObject(it).getString("fieldPath") })
        assertEquals("REQUEST_TIME", t.getJSONObject(0).getString("setToServerValue"))
    }

    @Test fun aPatchNamesItsFieldsAndNeedsTheDocument() {
        val w = FS.patch("p/records/r_1", mapOf("deleted" to FS.bool(true), "updatedBy" to FS.str("u1")),
            listOf("deletedAt", "updatedAt"))
        assertEquals(setOf("deleted", "updatedBy"),
            w.getJSONObject("updateMask").getJSONArray("fieldPaths").let { a -> (0 until a.length()).map(a::getString).toSet() })
        assertTrue(w.getJSONObject("currentDocument").getBoolean("exists"))
        assertEquals("p/timers/sleep", FS.delete("p/timers/sleep").getString("delete"))
    }

    @Test fun commitAnswersMeanWhatTheyMeanOnIos() {
        assertEquals(GlanceFirestore.Outcome.DONE, GlanceFirestore.outcome(200, ""))
        assertEquals(GlanceFirestore.Outcome.DONE, GlanceFirestore.outcome(409, "ALREADY_EXISTS"))
        assertEquals(GlanceFirestore.Outcome.DONE, GlanceFirestore.outcome(400, "{\"status\":\"FAILED_PRECONDITION\"}"))
        assertEquals(GlanceFirestore.Outcome.REJECTED, GlanceFirestore.outcome(400, "INVALID_ARGUMENT"))
        assertEquals(GlanceFirestore.Outcome.REJECTED, GlanceFirestore.outcome(403, "PERMISSION_DENIED"))
        assertEquals(GlanceFirestore.Outcome.SIGNED_OUT, GlanceFirestore.outcome(401, ""))
        assertEquals(GlanceFirestore.Outcome.OFFLINE, GlanceFirestore.outcome(503, ""))
    }

    @Test fun theSnapshotReadsAndFormatsAsOnIos() {
        assertEquals(120, snap.lastBottle?.amountMl)
        assertNull(snap.lastBottle?.kind)
        val t = snap.breast!!
        assertEquals("right", t.activeSide)
        assertEquals(60_000L + 180_000L, t.totalMs(300_000))
        assertEquals("r_1", snap.recent.single().id)
        val f = GlanceFormat(snap)
        assertEquals("45 phút", f.duration(45 * 60_000L))
        assertEquals("1 phút", f.duration(10_000))
        assertEquals("2 giờ", f.duration(120 * 60_000L))
        assertEquals("1g 25p", f.duration(85 * 60_000L, short = true))
        assertEquals("Vừa xong", f.ago(0, 30_000))
        assertEquals("45 phút trước", f.ago(0, 45 * 60_000L))
        assertEquals(1_760_000_000_000, FS.parseIso("2025-10-09T08:53:20.000Z"))
        assertEquals(1_760_000_000_000, FS.parseIso("2025-10-09T08:53:20.000000Z"))
    }
}
