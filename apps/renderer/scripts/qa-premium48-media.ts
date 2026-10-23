import { premium48FinalDesigns } from '@child-life/contracts';
/** Verify an already-rendered Premium review; writes evidence, never changes source media. */
import { execFileSync } from 'node:child_process';
import { readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { dirname, join, resolve } from 'node:path';
const out = resolve(process.argv[2]!);
if (!process.argv[2]) throw new Error('Review directory required');
const require = createRequire(import.meta.url);
const bin = dirname(
  require.resolve(`@remotion/compositor-${process.platform}-${process.arch}/package.json`, {
    paths: [dirname(require.resolve('@remotion/renderer'))],
  }),
);
const ffmpeg = (
  require(resolve('../../firebase/functions/node_modules/@ffmpeg-installer/ffmpeg')) as {
    path: string;
  }
).path;
const files = readdirSync(out).filter((f) => /^V\d{2}-(vi|en)-(story|portrait)\.mp4$/.test(f));
if (files.length !== 8) throw new Error('Expected eight VI/EN × two-format videos');
const report = [];
for (const file of files) {
  const path = join(out, file),
    probe = JSON.parse(
      execFileSync(
        join(bin, 'ffprobe'),
        ['-v', 'error', '-show_streams', '-show_format', '-of', 'json', path],
        { encoding: 'utf8', env: { ...process.env, DYLD_LIBRARY_PATH: bin } },
      ),
    );
  const video = probe.streams.find((s: { codec_type: string }) => s.codec_type === 'video'),
    audio = probe.streams.find((s: { codec_type: string }) => s.codec_type === 'audio');
  if (
    video.nb_frames !== (file.startsWith('V22-') ? '1500' : '1050') ||
    video.width !== 1080 ||
    video.height !== (file.includes('story') ? 1920 : 1350) ||
    video.codec_name !== 'h264' ||
    !['yuv420p', 'yuvj420p'].includes(video.pix_fmt) ||
    Number(video.duration) !== (file.startsWith('V22-') ? 50 : 35) ||
    audio?.codec_name !== 'aac' ||
    audio?.sample_rate !== '48000' ||
    audio?.channels !== 2
  )
    throw new Error('Media format failed: ' + file);
}
// ffmpeg writes filter diagnostics to stderr, so retain those diagnostics without printing large logs.
for (const file of files) {
  const path = join(out, file);
  // spawnSync exposes successful stderr too.
  const { spawnSync } = await import('node:child_process');
  const r = spawnSync(
    ffmpeg,
    [
      '-hide_banner',
      '-i',
      path,
      '-af',
      'loudnorm=I=-16:TP=-1:LRA=9:print_format=json',
      '-vf',
      'blackdetect=d=0.08:pix_th=0.05:pic_th=0.98',
      '-f',
      'null',
      '-',
    ],
    { encoding: 'utf8' },
  );
  const diagnostics = r.stderr;
  if (r.status !== 0) throw new Error('Decode failed: ' + file);
  const match = diagnostics.match(/\{\s*"input_i"[\s\S]*?\}/);
  if (!match) throw new Error('No loudness measurement: ' + file);
  const loudness = JSON.parse(match[0]);
  const noBlack = !/black_start:/.test(diagnostics),
    integrated = Number(loudness.input_i),
    truePeak = Number(loudness.input_tp);
  if (!noBlack || integrated < -18 || integrated > -14 || truePeak > -1)
    throw new Error('Audio/black QA failed: ' + file);
  const props = JSON.parse(readFileSync(path.replace(/\.mp4$/, '.json'), 'utf8'));
  if (
    !(
      Number(out.match(/phase(\d+)$/)?.[1]) >= 7
        ? premium48FinalDesigns.map((d) => String(d.baby))
        : out.endsWith('phase6')
          ? ['Oliver', 'Emma']
          : ['Noah', 'Lily']
    ).includes(props.name) ||
    props.presentation.copy.signature !== props.name
  )
    throw new Error('English demo name lost: ' + file);
  report.push({
    file,
    noBlack,
    integratedLufs: integrated,
    truePeakDbtp: truePeak,
    frames: file.startsWith('V22-') ? 1500 : 1050,
    width: 1080,
    height: file.includes('story') ? 1920 : 1350,
    name: props.name,
  });
}
writeFileSync(join(out, 'audio-black-qa.json'), JSON.stringify(report, null, 2) + '\n');
console.log(
  `${report.length} videos passed codecs, frames, audio, black-frame and English-name QA.`,
);
