package app.childlife.child_life

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/** The lock-screen answers on Android: which Function, with what, and the call itself (A6). */
class PushActionsTest {
    private val rule = mapOf(
        "kind" to "reminderRule", "babyId" to "b1", "ruleId" to "r1", "type" to "feed", "dueAt" to "1760425200000",
    )

    @Test fun ruleAnswersAreTheIosRequests() {
        assertEquals(
            "answerRuleReminder" to mapOf("babyId" to "b1", "ruleId" to "r1", "action" to "snooze",
                "dueAt" to 1760425200000L, "minutes" to 15),
            PushActionReceiver.request(rule, "snooze"),
        )
        assertEquals(
            "answerRuleReminder" to mapOf("babyId" to "b1", "ruleId" to "r1", "action" to "skip",
                "dueAt" to 1760425200000L),
            PushActionReceiver.request(rule, "skip"),
        )
        assertEquals(
            "snoozeVaccine" to mapOf("babyId" to "b1", "date" to "2026-10-20"),
            PushActionReceiver.request(mapOf("kind" to "vaccine", "babyId" to "b1", "date" to "2026-10-20"), "vxSnooze"),
        )
        assertNull(PushActionReceiver.request(rule - "dueAt", "snooze"))
        assertNull(PushActionReceiver.request(rule, "log"))
    }

    @Test fun callsTheFunctionWithTheTokenAndData() {
        assertEquals(
            "https://asia-southeast1-child-life-dev.cloudfunctions.net/answerRuleReminder",
            CallableClient("child-life-dev", null).url("answerRuleReminder"),
        )
        assertEquals(
            "http://10.0.2.2:5001/child-life-dev/asia-southeast1/snoozeVaccine",
            CallableClient("child-life-dev", "10.0.2.2").url("snoozeVaccine"),
        )
        FakeHttp { r ->
            if (r.header("Authorization") == "Bearer id-1") FakeHttp.Response(200, """{"result":{"status":"snoozed"}}""")
            else FakeHttp.Response(401)
        }.use { server ->
            val client = CallableClient("p1", server.host)
            assertEquals(200, client.call("answerRuleReminder", "id-1", mapOf("babyId" to "b1", "minutes" to 15)))
            val sent = server.requests.single()
            assertEquals("/p1/asia-southeast1/answerRuleReminder", sent.target)
            assertEquals("b1", JSONObject(sent.text).getJSONObject("data").getString("babyId"))
            assertEquals(15, JSONObject(sent.text).getJSONObject("data").getInt("minutes"))
            assertEquals(401, client.call("answerRuleReminder", "expired", emptyMap()))
        }
        assertNull(CallableClient("p1", "127.0.0.1:1").call("x", "t", emptyMap()))
    }
}
