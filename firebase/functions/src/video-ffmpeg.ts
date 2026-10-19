import { spawn } from 'node:child_process';
import { createWriteStream, existsSync } from 'node:fs';
import { mkdtemp, readFile, rm, stat } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { tmpdir } from 'node:os';
import { extname, join } from 'node:path';
import { pipeline } from 'node:stream/promises';
import type { getStorage } from 'firebase-admin/storage';
import type { OpenedVideo, RenditionSpec, VideoInfo, VideoOps } from './video-renditions.js';

/**
 * ffmpeg behind VideoOps (P-170). The runtime's own ffmpeg / ffprobe are used when present
 * (Ubuntu's 4.4 build, with libzimg for HDR tone mapping); otherwise the binaries that the
 * installer packages bring from npm. `FFMPEG_PATH` / `FFPROBE_PATH` override both.
 *
 * Output: H.264 High (libx264, veryfast, CRF 23 under a bitrate cap), AAC 128 kbit/s stereo,
 * `+faststart` (index first), metadata dropped (the original's location tag never reaches the
 * rendition, P-033). HDR sources are tone-mapped to BT.709 when the build can; failing that,
 * converted by primaries only; failing that, taken as they are.
 */

type Bucket = ReturnType<ReturnType<typeof getStorage>['bucket']>;

const load = createRequire(import.meta.url);

export function binaries(): { ffmpeg: string; ffprobe: string } {
  const pick = (kind: 'ffmpeg' | 'ffprobe') => {
    const env = process.env[kind === 'ffmpeg' ? 'FFMPEG_PATH' : 'FFPROBE_PATH'];
    if (env) return env;
    const system = `/usr/bin/${kind}`;
    if (existsSync(system)) return system;
    const pkg = kind === 'ffmpeg' ? '@ffmpeg-installer/ffmpeg' : '@ffprobe-installer/ffprobe';
    return (load(pkg) as { path: string }).path;
  };
  return { ffmpeg: pick('ffmpeg'), ffprobe: pick('ffprobe') };
}

/** Runs a binary; resolves with stdout, rejects with a short code-like message. */
export function run(
  bin: string,
  args: string[],
  deadlineMs: number,
): Promise<{ stdout: string; stderr: string }> {
  return new Promise((resolve, reject) => {
    const child = spawn(bin, args, { stdio: ['ignore', 'pipe', 'pipe'] });
    let stdout = '';
    let stderr = '';
    let timedOut = false;
    const timer = setTimeout(
      () => {
        timedOut = true;
        child.kill('SIGKILL');
      },
      Math.max(1000, deadlineMs),
    );
    child.stdout.on('data', (d: Buffer) => {
      if (stdout.length < 1_000_000) stdout += d.toString('utf8');
    });
    child.stderr.on('data', (d: Buffer) => {
      stderr = (stderr + d.toString('utf8')).slice(-8_000);
    });
    child.on('error', (e) => {
      clearTimeout(timer);
      reject(new Error(`spawn: ${e.message}`));
    });
    child.on('close', (code) => {
      clearTimeout(timer);
      if (timedOut) reject(new Error('timeout'));
      else if (code !== 0) {
        const last = stderr.trim().split('\n').pop()?.trim() ?? '';
        reject(new Error(`exit ${code}: ${last.slice(0, 160)}`));
      } else resolve({ stdout, stderr });
    });
  });
}

interface ProbeStream {
  codec_type?: string;
  codec_name?: string;
  width?: number;
  height?: number;
  duration?: string;
  avg_frame_rate?: string;
  r_frame_rate?: string;
  color_transfer?: string;
  color_primaries?: string;
  tags?: Record<string, string>;
  side_data_list?: { rotation?: number }[];
}

const ratio = (s: string | undefined): number | null => {
  if (!s) return null;
  const [a, b] = s.split('/').map(Number);
  if (!a || !Number.isFinite(a)) return null;
  const v = b ? a / b : a;
  return Number.isFinite(v) && v > 0 ? v : null;
};

export function parseProbe(json: string): VideoInfo | null {
  let parsed: { streams?: ProbeStream[]; format?: { duration?: string } };
  try {
    parsed = JSON.parse(json) as typeof parsed;
  } catch {
    return null;
  }
  const streams = parsed.streams ?? [];
  const v = streams.find((s) => s.codec_type === 'video');
  if (!v || !v.width || !v.height) return null;
  const rotation =
    v.side_data_list?.find((d) => typeof d.rotation === 'number')?.rotation ??
    Number(v.tags?.rotate ?? 0);
  const turned = Math.abs(Math.round(rotation)) % 180 === 90;
  const seconds = Number(v.duration ?? parsed.format?.duration ?? 0);
  return {
    width: turned ? v.height : v.width,
    height: turned ? v.width : v.height,
    durationMs: Number.isFinite(seconds) ? Math.round(seconds * 1000) : 0,
    fps: ratio(v.avg_frame_rate) ?? ratio(v.r_frame_rate),
    hdr:
      v.color_transfer === 'smpte2084' ||
      v.color_transfer === 'arib-std-b67' ||
      v.color_primaries === 'bt2020',
    videoCodec: v.codec_name ?? null,
    hasAudio: streams.some((s) => s.codec_type === 'audio'),
  };
}

export async function probeFile(ffprobe: string, file: string): Promise<VideoInfo | null> {
  try {
    const { stdout } = await run(
      ffprobe,
      ['-v', 'error', '-print_format', 'json', '-show_streams', '-show_format', file],
      60_000,
    );
    return parseProbe(stdout);
  } catch {
    return null;
  }
}

/** The video filter chains to try, best first; the last always works. */
export function filterChains(spec: RenditionSpec, info: VideoInfo): string[] {
  const base: string[] = [];
  if (spec.width !== info.width || spec.height !== info.height) {
    base.push(`scale=${spec.width}:${spec.height}:flags=lanczos`);
  }
  if (spec.fps) base.push(`fps=${spec.fps}`);
  const plain = [...base, 'format=yuv420p'].join(',');
  if (!spec.hdr) return [plain];
  return [
    [
      ...base,
      'zscale=t=linear:npl=100',
      'format=gbrpf32le',
      'zscale=p=bt709',
      'tonemap=tonemap=hable:desat=0',
      'zscale=t=bt709:m=bt709:r=tv',
      'format=yuv420p',
    ].join(','),
    // No libzimg: primaries and matrix to BT.709, HLG taken as the near-gamma curve it is.
    [...base, 'colorspace=iall=bt2020:itrc=bt2020-10:all=bt709:format=yuv420p'].join(','),
    plain,
  ];
}

export function encodeArgs(input: string, output: string, chain: string, spec: RenditionSpec) {
  return [
    '-hide_banner',
    '-nostdin',
    '-y',
    '-loglevel',
    'error',
    '-i',
    input,
    '-map',
    '0:v:0',
    '-map',
    '0:a:0?',
    '-map_metadata',
    '-1',
    '-map_chapters',
    '-1',
    '-sn',
    '-dn',
    '-vf',
    chain,
    '-c:v',
    'libx264',
    '-preset',
    'veryfast',
    '-crf',
    String(spec.crf),
    '-maxrate',
    `${spec.maxrateKbps}k`,
    '-bufsize',
    `${spec.maxrateKbps * 2}k`,
    '-profile:v',
    'high',
    '-level',
    '4.1',
    '-pix_fmt',
    'yuv420p',
    '-g',
    '60',
    '-sc_threshold',
    '0',
    ...(spec.hdr
      ? ['-color_primaries', 'bt709', '-color_trc', 'bt709', '-colorspace', 'bt709']
      : []),
    '-c:a',
    'aac',
    '-b:a',
    '128k',
    '-ac',
    '2',
    '-ar',
    '48000',
    '-max_muxing_queue_size',
    '1024',
    '-movflags',
    '+faststart',
    '-f',
    'mp4',
    output,
  ];
}

/** Encodes [input] into [output]; HDR chains fall back in order within the deadline. */
export async function transcodeFile(
  ffmpeg: string,
  input: string,
  output: string,
  spec: RenditionSpec,
  info: VideoInfo,
  deadlineMs: number,
): Promise<void> {
  const started = Date.now();
  const chains = filterChains(spec, info);
  let last: Error | null = null;
  for (const chain of chains) {
    const left = deadlineMs - (Date.now() - started);
    if (left < 5_000) break;
    try {
      await run(ffmpeg, encodeArgs(input, output, chain, spec), left);
      return;
    } catch (e) {
      last = e instanceof Error ? e : new Error(String(e));
      // A timeout is not a chain problem; nothing else will finish either.
      if (last.message === 'timeout') throw last;
    }
  }
  throw last ?? new Error('no chain');
}

/** A JPEG frame from half a second in (or the first frame of a very short clip). */
export async function posterFrame(
  ffmpeg: string,
  video: string,
  file: string,
): Promise<Uint8Array | null> {
  for (const at of ['0.5', '0']) {
    try {
      await run(
        ffmpeg,
        [
          '-hide_banner',
          '-nostdin',
          '-y',
          '-loglevel',
          'error',
          '-ss',
          at,
          '-i',
          video,
          '-frames:v',
          '1',
          '-q:v',
          '3',
          '-f',
          'image2',
          file,
        ],
        60_000,
      );
      const bytes = await readFile(file);
      if (bytes.length > 0) return new Uint8Array(bytes);
    } catch {
      // Try the start.
    }
  }
  return null;
}

/** The production VideoOps: originals come from the bucket into /tmp and renditions go back. */
export function ffmpegVideo(bucket: Bucket, bins = binaries()): VideoOps {
  return {
    async open(objectPath): Promise<OpenedVideo | null> {
      const dir = await mkdtemp(join(tmpdir(), 'clv-'));
      const input = join(dir, `in${extname(objectPath) || '.mp4'}`);
      const close = () => rm(dir, { recursive: true, force: true });
      try {
        await pipeline(bucket.file(objectPath).createReadStream(), createWriteStream(input));
      } catch (e) {
        await close();
        throw new Error(`download: ${e instanceof Error ? e.message.slice(0, 80) : 'failed'}`, {
          cause: e,
        });
      }
      const info = await probeFile(bins.ffprobe, input);
      if (!info) {
        await close();
        return null;
      }
      return {
        info,
        async transcode(outPath, spec, { deadlineMs, poster }) {
          const output = join(dir, 'display.mp4');
          await transcodeFile(bins.ffmpeg, input, output, spec, info, deadlineMs);
          const bytes = (await stat(output)).size;
          await bucket.upload(output, {
            destination: outPath,
            resumable: true,
            contentType: 'video/mp4',
            metadata: { cacheControl: 'private, max-age=31536000' },
          });
          const frame = poster
            ? await posterFrame(bins.ffmpeg, output, join(dir, 'poster.jpg'))
            : null;
          return { bytes, poster: frame };
        },
        close,
      };
    },
  };
}
