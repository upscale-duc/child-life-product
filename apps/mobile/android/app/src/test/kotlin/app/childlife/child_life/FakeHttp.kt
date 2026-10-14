package app.childlife.child_life

import java.io.InputStream
import java.net.InetAddress
import java.net.ServerSocket
import java.net.Socket
import kotlin.concurrent.thread

/** A one-request-per-connection HTTP/1.1 server on a free port, for the native clients' tests. */
class FakeHttp(private val handle: (Request) -> Response) : AutoCloseable {
    class Request(val method: String, val target: String, val headers: Map<String, String>, val body: ByteArray) {
        fun header(name: String) = headers[name.lowercase()]
        val text get() = body.decodeToString()
    }

    class Response(val status: Int, val body: String = "", val headers: Map<String, String> = emptyMap())

    private val server = ServerSocket(0, 50, InetAddress.getByName("127.0.0.1"))
    val requests = mutableListOf<Request>()
    val host get() = "127.0.0.1:${server.localPort}"

    init {
        thread(isDaemon = true) {
            while (!server.isClosed) {
                val socket = runCatching { server.accept() }.getOrNull() ?: break
                socket.use { serve(it) }
            }
        }
    }

    override fun close() = server.close()

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
        val first = line(input).split(" ")
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
        val request = Request(first.getOrElse(0) { "" }, first.getOrElse(1) { "" }, headers, body)
        synchronized(requests) { requests += request }
        val r = handle(request)
        val bytes = r.body.toByteArray()
        val head = StringBuilder("HTTP/1.1 ${r.status} X\r\nContent-Length: ${bytes.size}\r\nConnection: close\r\n")
        r.headers.forEach { (k, v) -> head.append("$k: $v\r\n") }
        head.append("\r\n")
        socket.getOutputStream().apply {
            write(head.toString().toByteArray())
            write(bytes)
            flush()
        }
    }
}
