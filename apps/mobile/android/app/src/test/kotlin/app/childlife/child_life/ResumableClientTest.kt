package app.childlife.child_life

import java.io.ByteArrayOutputStream
import java.io.InputStream
import java.net.InetAddress
import java.net.ServerSocket
import java.net.Socket
import kotlin.concurrent.thread
import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder

/**
 * ResumableClient against a small fake of Storage's resumable protocol on a free port: start →
 * upload URL, upload from an offset, query after a break.
 */
class ResumableClientTest {
    @get:Rule val tmp = TemporaryFolder()

    private class Request(val target: String, val headers: Map<String, String>, val body: ByteArray) {
        fun header(name: String) = headers[name.lowercase()]
    }

    private lateinit var server: ServerSocket
    private val received = ByteArrayOutputStream()
    private var finalized = false
    private var lastStart: Map<String, String?> = emptyMap()
    private var failNextUploadWith: Int? = null
    private var failAtUpload = 0
    private var uploads = 0
    private val finals = mutableListOf<Boolean>()

    @Before fun up() {
        server = ServerSocket(0, 50, InetAddress.getByName("127.0.0.1"))
        thread(isDaemon = true) {
            while (!server.isClosed) {
                val socket = runCatching { server.accept() }.getOrNull() ?: break
                socket.use { serve(it) }
            }
        }
    }

    @After fun down() = server.close()

    private fun line(input: InputStream): String {
        val b = StringBuilder()
        while (true) {
            val c = input.read()
            if (c < 0 || c == '\n'.code) break
            if (c != '\r'.code) b.append(c.toChar())
        }
        return b.toString()
    }

    private fun serve(socket: Socket) {
        val input = socket.getInputStream()
        val target = line(input).split(" ").getOrElse(1) { "" }
        val headers = mutableMapOf<String, String>()
        while (true) {
            val l = line(input)
            if (l.isEmpty()) break
            val i = l.indexOf(':')
            headers[l.substring(0, i).trim().lowercase()] = l.substring(i + 1).trim()
        }
        val body = ByteArray(headers["content-length"]?.toInt() ?: 0)
        var read = 0
        while (read < body.size) {
            val n = input.read(body, read, body.size - read)
            if (n < 0) break
            read += n
        }
        val (status, extra) = handle(Request(target, headers, body))
        val out = StringBuilder("HTTP/1.1 $status X\r\nContent-Length: 0\r\nConnection: close\r\n")
        extra.forEach { (k, v) -> out.append("$k: $v\r\n") }
        out.append("\r\n")
        socket.getOutputStream().apply {
            write(out.toString().toByteArray())
            flush()
        }
    }

    private fun handle(r: Request): Pair<Int, Map<String, String>> {
        val command = r.header("X-Goog-Upload-Command") ?: ""
        if (r.header("Authorization") != "Firebase token-1") return 401 to emptyMap()
        return when {
            command == "start" -> {
                lastStart = mapOf(
                    "path" to r.target.substringAfter('?'),
                    "length" to r.header("X-Goog-Upload-Header-Content-Length"),
                    "type" to r.header("X-Goog-Upload-Header-Content-Type"),
                    "body" to r.body.decodeToString(),
                )
                200 to mapOf("X-Goog-Upload-URL" to "$base/upload/session-1")
            }
            command == "query" -> 200 to mapOf(
                "X-Goog-Upload-Status" to if (finalized) "final" else "active",
                "X-Goog-Upload-Size-Received" to received.size().toString(),
            )
            command.startsWith("upload") -> {
                assertEquals(received.size().toString(), r.header("X-Goog-Upload-Offset"))
                uploads += 1
                finals += command.contains("finalize")
                if (uploads == failAtUpload) failNextUploadWith = 503
                val fail = failNextUploadWith
                if (fail != null) {
                    // Half the bytes arrive, then the connection "breaks".
                    received.write(r.body, 0, r.body.size / 2)
                    failNextUploadWith = null
                    fail to emptyMap()
                } else {
                    received.write(r.body)
                    finalized = command.contains("finalize")
                    200 to mapOf("X-Goog-Upload-Status" to "final")
                }
            }
            else -> 400 to emptyMap()
        }
    }

    private val host get() = "127.0.0.1:${server.localPort}"
    private val base get() = "http://$host"
    private val client get() = ResumableClient(host, timeoutMs = 5_000)

    @Test fun startsAndUploadsAFile() {
        val bytes = ByteArray(200_000) { it.toByte() }
        val file = tmp.newFile().apply { writeBytes(bytes) }
        val started = client.start("bucket-1", "babies/b/uploads/m1", "token-1", "image/jpeg", file.length())
        assertEquals(ResumableClient.Answer.Started("$base/upload/session-1"), started)
        assertEquals("name=babies%2Fb%2Fuploads%2Fm1", lastStart["path"])
        assertEquals("200000", lastStart["length"])
        assertEquals("image/jpeg", lastStart["type"])
        assertEquals("""{"name":"babies/b/uploads/m1","contentType":"image/jpeg"}""", lastStart["body"])

        var last = 0L
        val done = client.upload((started as ResumableClient.Answer.Started).uploadUrl, "token-1", file,
            "image/jpeg", 0, progress = { last = it }, stopped = { false })
        assertEquals(ResumableClient.Answer.Done, done)
        assertEquals(200_000L, last)
        assertArrayEquals(bytes, received.toByteArray())
    }

    @Test fun goesOnFromWhatArrivedAfterABreak() {
        val bytes = ByteArray(100_000) { (it % 251).toByte() }
        val file = tmp.newFile().apply { writeBytes(bytes) }
        val url = "$base/upload/session-1"
        failNextUploadWith = 503
        val first = client.upload(url, "token-1", file, "video/mp4", 0, progress = {}, stopped = { false })
        assertEquals(ResumableClient.Answer.Failed("http-503"), first)

        val q = client.query(url, "token-1")
        assertEquals(ResumableClient.Answer.Received(50_000), q)
        val second = client.upload(url, "token-1", file, "video/mp4", 50_000, progress = {}, stopped = { false })
        assertEquals(ResumableClient.Answer.Done, second)
        assertArrayEquals(bytes, received.toByteArray())
        assertEquals(ResumableClient.Answer.Done, client.query(url, "token-1"))
    }

    @Test fun sendsBigFilesInPiecesThatEachStay() {
        val bytes = ByteArray(1_000_000) { (it % 241).toByte() }
        val file = tmp.newFile().apply { writeBytes(bytes) }
        val url = "$base/upload/session-1"
        val pieces = ResumableClient(host, timeoutMs = 5_000, chunk = 256 * 1024)
        // The third piece breaks: the two before it stay, and the upload goes on from there.
        failAtUpload = 3
        val first = pieces.upload(url, "token-1", file, "video/mp4", 0, progress = {}, stopped = { false })
        assertEquals(ResumableClient.Answer.Failed("http-503"), first)
        assertEquals(ResumableClient.Answer.Received(2L * 256 * 1024 + 128 * 1024), pieces.query(url, "token-1"))
        val received = (pieces.query(url, "token-1") as ResumableClient.Answer.Received).bytes
        assertEquals(ResumableClient.Answer.Done,
            pieces.upload(url, "token-1", file, "video/mp4", received, progress = {}, stopped = { false }))
        assertArrayEquals(bytes, this.received.toByteArray())
        // 3 pieces (the third broken), then the rest from 640 KiB in 2: only the last finalizes.
        assertEquals(listOf(false, false, false, false, true), finals)
    }

    @Test fun reportsTheIosFailureCodes() {
        val file = tmp.newFile().apply { writeBytes(ByteArray(10)) }
        assertEquals(ResumableClient.Answer.Failed("unauthenticated"),
            client.start("b", "p", "expired", "image/jpeg", file.length()))
        assertEquals("unauthorized", ResumableClient.code(403))
        assertEquals("object-not-found", ResumableClient.code(404))
        assertEquals("http-410", ResumableClient.code(410))
        val nobody = ResumableClient("127.0.0.1:1", timeoutMs = 1_000)
        assertEquals(ResumableClient.Answer.Failed("network"),
            nobody.query("http://127.0.0.1:1/upload/x", "token-1"))
    }
}
