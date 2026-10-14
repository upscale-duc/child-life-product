package app.childlife.child_life

import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import org.json.JSONObject

/**
 * Calls a callable Function over HTTP with an ID token, as ios/Runner/RuleNotifications.swift
 * does for the lock-screen answers: `https://asia-southeast1-{project}.cloudfunctions.net/{name}`,
 * or the emulator on port 5001. Plain JVM code, unit-tested.
 */
class CallableClient(private val projectId: String, private val emulatorHost: String?) {
    fun url(name: String): String =
        emulatorHost?.let { "http://${if (':' in it) it else "$it:5001"}/$projectId/$REGION/$name" }
            ?: "https://$REGION-$projectId.cloudfunctions.net/$name"

    /** The HTTP status, or null with no network. */
    fun call(name: String, idToken: String, data: Map<String, Any?>): Int? {
        val c = URL(url(name)).openConnection() as HttpURLConnection
        return try {
            c.requestMethod = "POST"
            c.doOutput = true
            c.connectTimeout = 15_000
            c.readTimeout = 20_000
            c.setRequestProperty("Content-Type", "application/json")
            c.setRequestProperty("Authorization", "Bearer $idToken")
            val body = JSONObject().put("data", JSONObject(data)).toString().toByteArray()
            c.setFixedLengthStreamingMode(body.size)
            c.outputStream.use { it.write(body) }
            c.responseCode
        } catch (_: IOException) {
            null
        } finally {
            c.disconnect()
        }
    }

    companion object {
        const val REGION = "asia-southeast1"
    }
}
