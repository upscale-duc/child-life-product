package app.childlife.child_life

import java.io.File
import java.io.FileOutputStream
import java.io.RandomAccessFile
import java.nio.ByteBuffer

/**
 * A copy of a recording with its index ("moov") moved in front of the media ("mdat"), nothing
 * re-encoded, so a player starts after the first bytes (owner, 2026-10-12; what
 * `AVAssetExportSession.shouldOptimizeForNetworkUse` does on iOS). Phones write the index last.
 *
 * Written from the ISO base media file format (ISO/IEC 14496-12): top-level boxes are scanned,
 * the moov box is moved right after ftyp, and every chunk offset (stco / co64) that pointed past
 * that spot is shifted by the moov box's size. False when there is nothing to do (the index is
 * already first) or the file is not something this handles; the caller then copies it as it is.
 */
object FastStart {
    private data class Box(val type: String, val offset: Long, val size: Long)

    private val containers = setOf("moov", "trak", "mdia", "minf", "stbl")
    private const val MAX_MOOV = 64L * 1024 * 1024

    fun run(src: File, dst: File): Boolean {
        val boxes = RandomAccessFile(src, "r").use { topLevel(it) } ?: return false
        val moov = boxes.firstOrNull { it.type == "moov" } ?: return false
        val mdat = boxes.firstOrNull { it.type == "mdat" } ?: return false
        if (moov.offset < mdat.offset || moov.size > MAX_MOOV) return false
        val ftyp = boxes.firstOrNull { it.type == "ftyp" }
        val insertAt = if (ftyp != null && ftyp.offset < moov.offset) ftyp.offset + ftyp.size else 0L

        val index = ByteArray(moov.size.toInt())
        RandomAccessFile(src, "r").use {
            it.seek(moov.offset)
            it.readFully(index)
        }
        if (!shift(ByteBuffer.wrap(index), 8, index.size, insertAt, moov.offset, moov.size)) return false

        val tmp = File(dst.path + ".part")
        try {
            RandomAccessFile(src, "r").channel.use { input ->
                FileOutputStream(tmp).channel.use { out ->
                    copy(input, out, 0, insertAt)
                    out.write(ByteBuffer.wrap(index))
                    copy(input, out, insertAt, moov.offset - insertAt)
                    val after = moov.offset + moov.size
                    copy(input, out, after, src.length() - after)
                }
            }
            dst.delete()
            if (!tmp.renameTo(dst)) return false
            return true
        } catch (_: Exception) {
            tmp.delete()
            return false
        }
    }

    private fun copy(
        input: java.nio.channels.FileChannel,
        out: java.nio.channels.FileChannel,
        from: Long,
        count: Long,
    ) {
        var done = 0L
        while (done < count) {
            val n = input.transferTo(from + done, count - done, out)
            if (n <= 0) throw java.io.IOException("short copy")
            done += n
        }
    }

    /** The top-level boxes, or null if the file does not parse as one. */
    private fun topLevel(f: RandomAccessFile): List<Box>? {
        val out = mutableListOf<Box>()
        val length = f.length()
        var at = 0L
        val head = ByteArray(16)
        while (at + 8 <= length) {
            f.seek(at)
            f.readFully(head, 0, 8)
            var size = ByteBuffer.wrap(head, 0, 4).int.toLong() and 0xFFFFFFFFL
            val type = String(head, 4, 4, Charsets.ISO_8859_1)
            if (size == 1L) {
                if (at + 16 > length) return null
                f.readFully(head, 8, 8)
                size = ByteBuffer.wrap(head, 8, 8).long
            } else if (size == 0L) {
                size = length - at
            }
            if (size < 8 || at + size > length) return null
            out += Box(type, at, size)
            at += size
        }
        return out
    }

    /**
     * Walks the boxes in [buf] between [from] and [to], shifting chunk offsets that pointed into
     * [insertAt, moovAt) by [moovSize]. False on anything it cannot handle safely.
     */
    private fun shift(buf: ByteBuffer, from: Int, to: Int, insertAt: Long, moovAt: Long, moovSize: Long): Boolean {
        var at = from
        while (at + 8 <= to) {
            val size = buf.getInt(at).toLong() and 0xFFFFFFFFL
            val type = String(ByteArray(4) { buf.get(at + 4 + it) }, Charsets.ISO_8859_1)
            if (size < 8 || at + size > to) return false
            val end = at + size.toInt()
            when (type) {
                "cmov" -> return false
                in containers -> if (!shift(buf, at + 8, end, insertAt, moovAt, moovSize)) return false
                "stco" -> {
                    val count = buf.getInt(at + 12)
                    if (at + 16 + 4L * count > end) return false
                    for (i in 0 until count) {
                        val p = at + 16 + 4 * i
                        val old = buf.getInt(p).toLong() and 0xFFFFFFFFL
                        val new = moved(old, insertAt, moovAt, moovSize)
                        if (new > 0xFFFFFFFFL) return false
                        buf.putInt(p, new.toInt())
                    }
                }
                "co64" -> {
                    val count = buf.getInt(at + 12)
                    if (at + 16 + 8L * count > end) return false
                    for (i in 0 until count) {
                        val p = at + 16 + 8 * i
                        buf.putLong(p, moved(buf.getLong(p), insertAt, moovAt, moovSize))
                    }
                }
            }
            at = end
        }
        return true
    }

    private fun moved(old: Long, insertAt: Long, moovAt: Long, moovSize: Long): Long =
        if (old >= insertAt && old < moovAt) old + moovSize else old
}
