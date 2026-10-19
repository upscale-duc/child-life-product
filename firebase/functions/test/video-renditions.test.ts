import { execFileSync } from 'node:child_process';
import { mkdtemp, rm, stat } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import {
  binaries,
  encodeArgs,
  filterChains,
  parseProbe,
  posterFrame,
  probeFile,
  transcodeFile,
} from '../src/video-ffmpeg.js';
import {
  renditionJobDoc,
  renditionJobId,
  renditionLimits,
  renditionSkipReason,
  renditionSpecFor,
  type VideoInfo,
} from '../src/video-renditions.js';

// Streaming renditions (P-170): the spec a source gets, what ffprobe output means, and — with
// the bundled ffmpeg — a real transcode of a generated clip, SDR and HDR-tagged.

const info = (over: Partial<VideoInfo> = {}): VideoInfo => ({
  width: 1920,
  height: 1080,
  durationMs: 24_000,
  fps: 30,
  hdr: false,
  videoCodec: 'hevc',
  hasAudio: true,
  ...over,
});

describe('renditionSpecFor', () => {
  it('keeps 1080p30 as it is, with the 1080p bitrate cap', () => {
    expect(renditionSpecFor(info())).toEqual({
      width: 1920,
      height: 1080,
      fps: null,
      hdr: false,
      maxrateKbps: 6000,
      crf: 23,
    });
  });

  it('scales a 4K60 iPhone clip to 1080p30', () => {
    const s = renditionSpecFor(info({ width: 3840, height: 2160, fps: 59.94 }));
    expect([s.width, s.height, s.fps]).toEqual([1920, 1080, 30]);
  });

  it('limits the short side of a portrait clip, so portrait stays 1080 wide', () => {
    const s = renditionSpecFor(info({ width: 2160, height: 3840 }));
    expect([s.width, s.height]).toEqual([1080, 1920]);
  });

  it('never enlarges and caps 720p lower', () => {
    const s = renditionSpecFor(info({ width: 1280, height: 720 }));
    expect([s.width, s.height, s.maxrateKbps]).toEqual([1280, 720, 3500]);
    expect(renditionSpecFor(info({ width: 1281, height: 721 })).width).toBe(1282);
  });

  it('skips what is too long or too large, and what has no picture', () => {
    expect(renditionSkipReason(info(), 100)).toBeNull();
    expect(renditionSkipReason(info({ durationMs: renditionLimits.maxDurationMs + 1 }), 1)).toBe(
      'too-long',
    );
    expect(renditionSkipReason(info(), renditionLimits.maxInputBytes + 1)).toBe('too-large');
    expect(renditionSkipReason(info({ width: 0 }), 1)).toBe('no-picture');
  });

  it('names job documents by item and attempt', () => {
    expect(renditionJobId('med_1', 1)).toBe('med_1');
    expect(renditionJobId('med_1', 2)).toBe('med_1~2');
    const now = new Date('2026-10-19T07:00:00Z');
    expect(renditionJobDoc('b_1', 'med_1', now)).toMatchObject({
      state: 'queued',
      attempt: 1,
      activeSince: now,
    });
  });
});

describe('parseProbe', () => {
  it('applies the rotation an iPhone writes and reads HDR from the transfer', () => {
    const json = JSON.stringify({
      streams: [
        {
          codec_type: 'video',
          codec_name: 'hevc',
          width: 3840,
          height: 2160,
          duration: '12.5',
          avg_frame_rate: '60000/1001',
          color_transfer: 'arib-std-b67',
          color_primaries: 'bt2020',
          side_data_list: [{ rotation: -90 }],
        },
        { codec_type: 'audio', codec_name: 'aac' },
      ],
      format: { duration: '12.5' },
    });
    expect(parseProbe(json)).toEqual({
      width: 2160,
      height: 3840,
      durationMs: 12_500,
      fps: 60000 / 1001,
      hdr: true,
      videoCodec: 'hevc',
      hasAudio: true,
    });
  });

  it('is null for something that is not a video', () => {
    expect(parseProbe('not json')).toBeNull();
    expect(parseProbe(JSON.stringify({ streams: [{ codec_type: 'audio' }] }))).toBeNull();
  });
});

describe('filterChains', () => {
  it('SDR: scale and frame-rate cap only', () => {
    const src = info({ width: 3840, height: 2160, fps: 60 });
    expect(filterChains(renditionSpecFor(src), src)).toEqual([
      'scale=1920:1080:flags=lanczos,fps=30,format=yuv420p',
    ]);
  });

  it('HDR: tone map first, primaries only next, as is last', () => {
    const src = info({ hdr: true });
    const chains = filterChains(renditionSpecFor(src), src);
    expect(chains).toHaveLength(3);
    expect(chains[0]).toContain('tonemap=');
    expect(chains[1]).toContain('colorspace=');
    expect(chains[2]).toBe('format=yuv420p');
    const args = encodeArgs('in.mov', 'out.mp4', chains[0]!, renditionSpecFor(src));
    expect(args).toContain('+faststart');
    expect(args.slice(args.indexOf('-color_trc'))).toContain('bt709');
    // The original's metadata (a location tag among it) never reaches the rendition.
    expect(args.slice(args.indexOf('-map_metadata') + 1)[0]).toBe('-1');
  });
});

describe('ffmpeg (bundled binary)', () => {
  let dir: string;
  let bins: { ffmpeg: string; ffprobe: string };
  let available = true;

  const make = (file: string, hdr: boolean) =>
    execFileSync(
      bins.ffmpeg,
      [
        '-hide_banner',
        '-nostdin',
        '-y',
        '-loglevel',
        'error',
        '-f',
        'lavfi',
        '-i',
        'testsrc=size=1280x720:rate=60:duration=1.2',
        '-f',
        'lavfi',
        '-i',
        'sine=frequency=440:duration=1.2',
        '-c:v',
        'libx264',
        '-preset',
        'ultrafast',
        '-pix_fmt',
        'yuv420p',
        ...(hdr
          ? ['-color_primaries', 'bt2020', '-color_trc', 'arib-std-b67', '-colorspace', 'bt2020nc']
          : []),
        '-c:a',
        'aac',
        '-shortest',
        file,
      ],
      { stdio: 'pipe' },
    );

  beforeAll(async () => {
    dir = await mkdtemp(join(tmpdir(), 'clv-test-'));
    try {
      bins = binaries();
      execFileSync(bins.ffmpeg, ['-version'], { stdio: 'pipe' });
    } catch {
      available = false;
    }
  });

  afterAll(() => rm(dir, { recursive: true, force: true }));

  it('probes, transcodes with fast start and takes a poster frame', async () => {
    if (!available) return;
    const input = join(dir, 'sdr.mp4');
    make(input, false);
    const src = await probeFile(bins.ffprobe, input);
    expect(src).toMatchObject({ width: 1280, height: 720, hdr: false, hasAudio: true });
    expect(src!.fps).toBeCloseTo(60, 0);
    const spec = renditionSpecFor(src!);
    expect(spec.fps).toBe(30);
    const out = join(dir, 'sdr-display.mp4');
    await transcodeFile(bins.ffmpeg, input, out, spec, src!, 120_000);
    const made = await probeFile(bins.ffprobe, out);
    expect(made).toMatchObject({ width: 1280, height: 720, videoCodec: 'h264', hasAudio: true });
    expect(made!.fps).toBeCloseTo(30, 0);
    // Fast start: the index ("moov") sits before the media ("mdat").
    const { readFile } = await import('node:fs/promises');
    const head = (await readFile(out)).subarray(0, 1024 * 64).toString('latin1');
    expect(head.indexOf('moov')).toBeGreaterThan(0);
    expect(head.indexOf('moov')).toBeLessThan(
      head.indexOf('mdat') < 0 ? 1 << 30 : head.indexOf('mdat'),
    );
    const poster = await posterFrame(bins.ffmpeg, out, join(dir, 'poster.jpg'));
    expect(poster![0]).toBe(0xff);
    expect(poster![1]).toBe(0xd8);
    expect((await stat(out)).size).toBeGreaterThan(1000);
  }, 180_000);

  it('an HDR-tagged source still comes out as BT.709 SDR', async () => {
    if (!available) return;
    const input = join(dir, 'hdr.mp4');
    make(input, true);
    const src = await probeFile(bins.ffprobe, input);
    expect(src?.hdr).toBe(true);
    const out = join(dir, 'hdr-display.mp4');
    await transcodeFile(bins.ffmpeg, input, out, renditionSpecFor(src!), src!, 120_000);
    const made = await probeFile(bins.ffprobe, out);
    expect(made?.hdr).toBe(false);
  }, 180_000);
});
