package app.childlife.child_life

import java.io.ByteArrayOutputStream
import java.io.File
import java.nio.ByteBuffer
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder

/** FastStart on hand-built files: the index moves first and chunk offsets still find the media. */
class FastStartTest {
    @get:Rule val tmp = TemporaryFolder()

    private fun box(type: String, body: ByteArray): ByteArray =
        ByteBuffer.allocate(8 + body.size).putInt(8 + body.size).put(type.toByteArray(Charsets.ISO_8859_1))
            .put(body).array()

    private fun cat(vararg parts: ByteArray) = ByteArrayOutputStream().apply { parts.forEach { write(it) } }.toByteArray()

    private fun stco(offsets: List<Long>): ByteArray {
        val b = ByteBuffer.allocate(8 + 4 * offsets.size).putInt(0).putInt(offsets.size)
        offsets.forEach { b.putInt(it.toInt()) }
        return box("stco", b.array())
    }

    private fun co64(offsets: List<Long>): ByteArray {
        val b = ByteBuffer.allocate(8 + 8 * offsets.size).putInt(0).putInt(offsets.size)
        offsets.forEach { b.putLong(it) }
        return box("co64", b.array())
    }

    private fun moov(table: ByteArray) =
        box("moov", cat(box("mvhd", ByteArray(20)), box("trak", box("mdia", box("minf", box("stbl", table))))))

    private val ftyp = box("ftyp", "isom\u0000\u0000\u0002\u0000isomiso2mp41".toByteArray(Charsets.ISO_8859_1))
    private val payload = ByteArray(300) { (it * 7).toByte() }
    private val mdat = box("mdat", payload)

    /** Top-level boxes as (type, offset). */
    private fun layout(bytes: ByteArray): List<Pair<String, Int>> {
        val out = mutableListOf<Pair<String, Int>>()
        var at = 0
        while (at + 8 <= bytes.size) {
            val size = ByteBuffer.wrap(bytes, at, 4).int
            out += String(bytes, at + 4, 4, Charsets.ISO_8859_1) to at
            at += size
        }
        return out
    }

    /** The chunk offsets in the first stco / co64 found. */
    private fun offsets(bytes: ByteArray): List<Long> {
        for (i in 0 until bytes.size - 8) {
            val type = String(bytes, i + 4, 4, Charsets.ISO_8859_1)
            if (type == "stco" || type == "co64") {
                val b = ByteBuffer.wrap(bytes)
                val n = b.getInt(i + 12)
                return (0 until n).map {
                    if (type == "stco") b.getInt(i + 16 + 4 * it).toLong() and 0xFFFFFFFFL else b.getLong(i + 16 + 8 * it)
                }
            }
        }
        error("no chunk table")
    }

    private fun write(bytes: ByteArray) = tmp.newFile().apply { writeBytes(bytes) }

    private fun checkMoved(table: (List<Long>) -> ByteArray) {
        // Chunks at the payload's start and 100 bytes in.
        val first = (ftyp.size + 8).toLong()
        val src = write(cat(ftyp, mdat, moov(table(listOf(first, first + 100)))))
        val dst = File(tmp.root, "out.mp4")
        assertTrue(FastStart.run(src, dst))
        val out = dst.readBytes()
        assertEquals(src.length(), dst.length())
        assertEquals(listOf("ftyp", "moov", "mdat"), layout(out).map { it.first })
        val moved = layout(out).first { it.first == "mdat" }.second + 8
        for (o in offsets(out)) {
            val i = o.toInt()
            val j = i - moved
            assertArrayEquals(payload.copyOfRange(j, j + 10), out.copyOfRange(i, i + 10))
        }
    }

    @Test fun movesTheIndexFirstAndShiftsStco() = checkMoved(::stco)

    @Test fun shiftsCo64Too() = checkMoved(::co64)

    @Test fun leavesAFileWhoseIndexIsAlreadyFirst() {
        val src = write(cat(ftyp, moov(stco(listOf(0L))), mdat))
        assertFalse(FastStart.run(src, File(tmp.root, "out.mp4")))
    }

    @Test fun refusesWhatIsNotAnMp4() {
        val src = write("not a video at all".toByteArray())
        assertFalse(FastStart.run(src, File(tmp.root, "out.mp4")))
    }

    @Test fun mediaAfterTheOldIndexKeepsItsOffset() {
        // ftyp · mdat · moov · mdat: the second media box does not move.
        val tail = ByteArray(50) { (100 + it).toByte() }
        val first = (ftyp.size + 8).toLong()
        val probe = moov(stco(listOf(first, 0L)))
        val second = (ftyp.size + mdat.size + probe.size + 8).toLong()
        val src = write(cat(ftyp, mdat, moov(stco(listOf(first, second))), box("mdat", tail)))
        val dst = File(tmp.root, "out.mp4")
        assertTrue(FastStart.run(src, dst))
        val out = dst.readBytes()
        val (a, b) = offsets(out)
        assertArrayEquals(payload.copyOfRange(0, 10), out.copyOfRange(a.toInt(), a.toInt() + 10))
        assertEquals(second, b)
        assertArrayEquals(tail.copyOfRange(0, 10), out.copyOfRange(b.toInt(), b.toInt() + 10))
    }
}
