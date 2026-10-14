package app.childlife.child_life

import java.io.File
import java.io.IOException
import java.io.RandomAccessFile
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder

/**
 * Firebase Storage's resumable protocol, as `ios/Runner/BackgroundUploads.swift` speaks it: a
 * "start" request with the person's ID token returns an upload URL; the bytes go there with
 * "upload, finalize". Android also asks a broken session how much arrived ("query") and goes on
 * from there instead of sending the file again. Plain JVM code, so it is unit-tested.
 */
class ResumableClient(
    /** The Storage emulator host (port 9199 unless it names one), or null for Firebase. */
    private val host: String?,
    private val timeoutMs: Int = 300_000,
    /** Bytes per upload request; a multiple of 256 KiB. */
    private val chunk: Long = 8L * 1024 * 1024,
) {
    sealed interface Answer {
        data class Started(val uploadUrl: String) : Answer
        data class Received(val bytes: Long) : Answer
        data object Done : Answer
        data class Failed(val code: String) : Answer
    }

    private val base: String
        get() = host?.let { if (':' in it) "http://$it" else "http://$it:9199" }
            ?: "https://firebasestorage.googleapis.com"

    fun start(bucket: String, path: String, token: String, contentType: String, size: Long): Answer {
        val name = URLEncoder.encode(path, "UTF-8")
        return request("$base/v0/b/$bucket/o?name=$name", token) { c ->
            c.setRequestProperty("X-Goog-Upload-Protocol", "resumable")
            c.setRequestProperty("X-Goog-Upload-Command", "start")
            c.setRequestProperty("X-Goog-Upload-Header-Content-Length", size.toString())
            c.setRequestProperty("X-Goog-Upload-Header-Content-Type", contentType)
            c.setRequestProperty("Content-Type", "application/json; charset=utf-8")
            val body = """{"name":${quote(path)},"contentType":${quote(contentType)}}""".toByteArray()
            c.setFixedLengthStreamingMode(body.size)
            c.outputStream.use { it.write(body) }
            val status = c.responseCode
            if (status !in 200..299) return@request Answer.Failed(code(status))
            val link = c.getHeaderField("X-Goog-Upload-URL") ?: return@request Answer.Failed("no-upload-url")
            Answer.Started(link)
        }
    }

    /** How much of an earlier upload arrived; Done when Storage already has the whole file. */
    fun query(uploadUrl: String, token: String): Answer =
        request(uploadUrl, token) { c ->
            c.setRequestProperty("X-Goog-Upload-Command", "query")
            c.setFixedLengthStreamingMode(0)
            c.outputStream.close()
            val status = c.responseCode
            if (status !in 200..299) return@request Answer.Failed(code(status))
            if (c.getHeaderField("X-Goog-Upload-Status") == "final") return@request Answer.Done
            Answer.Received(c.getHeaderField("X-Goog-Upload-Size-Received")?.toLongOrNull() ?: 0L)
        }

    /**
     * Sends the file from [offset] in pieces of [chunk] bytes and finalizes it with the last one.
     * Each piece is its own request, so what arrived is kept if the connection or the app dies
     * (a multiple of Storage's 256 KiB granularity). [stopped] is checked as bytes go.
     */
    fun upload(
        uploadUrl: String,
        token: String,
        file: File,
        contentType: String,
        offset: Long,
        progress: (Long) -> Unit,
        stopped: () -> Boolean,
    ): Answer {
        val total = file.length()
        var at = offset
        while (true) {
            val end = minOf(total, at + chunk)
            val last = end == total
            val answer = request(uploadUrl, token) { c ->
                c.setRequestProperty("X-Goog-Upload-Command", if (last) "upload, finalize" else "upload")
                c.setRequestProperty("X-Goog-Upload-Offset", at.toString())
                c.setRequestProperty("Content-Type", contentType)
                c.setFixedLengthStreamingMode(end - at)
                RandomAccessFile(file, "r").use { input ->
                    input.seek(at)
                    c.outputStream.use { out ->
                        val buffer = ByteArray(64 * 1024)
                        var sent = at
                        while (sent < end) {
                            if (stopped()) throw IOException("stopped")
                            val n = input.read(buffer, 0, minOf(buffer.size.toLong(), end - sent).toInt())
                            if (n < 0) throw IOException("short file")
                            out.write(buffer, 0, n)
                            sent += n
                            progress(sent)
                        }
                    }
                }
                val status = c.responseCode
                when {
                    status !in 200..299 -> Answer.Failed(code(status))
                    last -> Answer.Done
                    else -> Answer.Received(end)
                }
            }
            if (answer !is Answer.Received) return answer
            at = end
        }
    }

    private inline fun request(url: String, token: String, block: (HttpURLConnection) -> Answer): Answer {
        val c = URL(url).openConnection() as HttpURLConnection
        return try {
            c.requestMethod = "POST"
            c.doOutput = true
            c.connectTimeout = 30_000
            c.readTimeout = timeoutMs
            c.setRequestProperty("Authorization", "Firebase $token")
            block(c)
        } catch (_: IOException) {
            Answer.Failed("network")
        } finally {
            c.disconnect()
        }
    }

    companion object {
        /** The iOS failure codes, so Dart treats both platforms alike. */
        fun code(status: Int): String =
            when (status) {
                401 -> "unauthenticated"
                403 -> "unauthorized"
                404 -> "object-not-found"
                else -> "http-$status"
            }

        private fun quote(s: String): String =
            "\"" + s.replace("\\", "\\\\").replace("\"", "\\\"") + "\""
    }
}
