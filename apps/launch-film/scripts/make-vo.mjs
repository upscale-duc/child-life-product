/** Voice-over: one clip per VO phrase so pauses and picture timing stay editable.
 * Usage: make-vo.mjs [en|vi] [lineId]. Output: public/intro/vo[/vi]/*.wav + src/intro/vo[.vi].json.
 * Providers (VO_PROVIDER):
 *  - `edge` (default): scratch Microsoft neural voice via `edge-tts` (pip); binary in EDGE_TTS.
 *  - `elevenlabs`: needs ELEVENLABS_API_KEY in the environment (never commit it). Voice/model come
 *    from the script's `elevenlabs` block or ELEVENLABS_VOICE_ID / ELEVENLABS_MODEL. Neighbouring
 *    lines are sent as previous_text/next_text so the phrases keep one continuous delivery. */
import { spawnSync } from 'node:child_process';
import { createRequire } from 'node:module';
import { mkdirSync, readFileSync, writeFileSync, existsSync, statSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
const require = createRequire(import.meta.url);
const root = fileURLToPath(new URL('../', import.meta.url));
const cliRequire = createRequire(require.resolve('@remotion/cli/package.json'));
const rendererRequire = createRequire(cliRequire.resolve('@remotion/renderer/package.json'));
const compositor = dirname(rendererRequire.resolve('@remotion/compositor-darwin-arm64'));
const env = { ...process.env, DYLD_LIBRARY_PATH: compositor };
const run = (bin, args) => {
  const r = spawnSync(bin, args, { env, encoding: 'utf8' });
  if (r.status !== 0) throw new Error(`${bin} ${args.join(' ')}\n${r.stderr}`);
  return r;
};
const edge = process.env.EDGE_TTS ?? 'edge-tts';
const lang = process.argv[2] === 'vi' ? 'vi' : 'en';
const suffix = lang === 'en' ? '' : `.${lang}`;
const script = JSON.parse(readFileSync(join(root, `scripts/vo-script${suffix}.json`), 'utf8'));
const provider = process.env.VO_PROVIDER === 'elevenlabs' ? 'elevenlabs' : 'edge';
const eleven = {
  voiceId: process.env.ELEVENLABS_VOICE_ID ?? script.elevenlabs?.voiceId,
  model: process.env.ELEVENLABS_MODEL ?? script.elevenlabs?.model ?? 'eleven_multilingual_v2',
  settings: script.elevenlabs?.settings ?? { stability: 0.5, similarity_boost: 0.8, style: 0.2, use_speaker_boost: true, speed: 0.95 },
};
if (provider === 'elevenlabs' && (!process.env.ELEVENLABS_API_KEY || !eleven.voiceId))
  throw new Error('ElevenLabs needs ELEVENLABS_API_KEY and a voice id (ELEVENLABS_VOICE_ID or script.elevenlabs.voiceId)');
// Raw takes are kept per provider so switching back never mixes voices.
const raw = join(root, 'design/vo-raw', provider === 'edge' ? '' : provider, lang === 'en' ? '' : lang);
const out = join(root, lang === 'en' ? 'public/intro/vo' : `public/intro/vo/${lang}`);
mkdirSync(raw, { recursive: true });
mkdirSync(out, { recursive: true });
const only = process.argv[3];

async function elevenLabs(line, all, file) {
  const i = all.indexOf(line);
  const body = {
    text: line.text,
    model_id: eleven.model,
    // Per-line edge `rate` (e.g. "-10%" for the slow, close lines) maps onto ElevenLabs speed (0.7–1.2).
    voice_settings: {
      ...eleven.settings,
      speed: Math.min(1.2, Math.max(0.7, line.speed ?? (eleven.settings.speed ?? 1) * (1 + parseFloat(line.rate ?? '0') / 100))),
    },
    previous_text: all.slice(Math.max(0, i - 2), i).map((l) => l.text).join(' ') || undefined,
    next_text: all[i + 1]?.text,
    ...(eleven.model === 'eleven_multilingual_v2' || eleven.model.startsWith('eleven_turbo') || eleven.model.startsWith('eleven_flash') ? { language_code: lang } : {}),
  };
  for (let attempt = 1; ; attempt++) {
    const res = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${eleven.voiceId}?output_format=mp3_44100_192`, {
      method: 'POST',
      headers: { 'xi-api-key': process.env.ELEVENLABS_API_KEY, 'content-type': 'application/json', accept: 'audio/mpeg' },
      body: JSON.stringify(body),
    });
    if (res.ok) {
      writeFileSync(file, Buffer.from(await res.arrayBuffer()));
      return;
    }
    const msg = await res.text();
    if (attempt === 4 || (res.status < 500 && res.status !== 429)) throw new Error(`ElevenLabs ${res.status} for ${line.id}: ${msg.slice(0, 300)}`);
    await new Promise((r) => setTimeout(r, 3000 * attempt));
  }
}
const lines = [];
for (const line of script.lines) {
  const mp3 = join(raw, `${line.id}.mp3`);
  const wav = join(out, `${line.id}.wav`);
  // Re-synthesise only the requested line or missing clips (delete design/vo-raw[/lang] to redo all).
  if (only ? only === line.id : !(existsSync(mp3) && statSync(mp3).size > 1000)) {
    if (provider === 'elevenlabs') {
      await elevenLabs(line, script.lines, mp3);
    } else
    // The TTS service occasionally stalls: cap each request and retry.
    for (let attempt = 1; ; attempt++) {
      const r = spawnSync(edge, ['--voice', script.voice, `--rate=${line.rate ?? script.rate}`, `--pitch=${script.pitch}`, '--text', line.text, '--write-media', mp3], { encoding: 'utf8', timeout: 15000, stdio: ['ignore', 'pipe', 'pipe'] });
      if (r.status === 0 && statSync(mp3).size > 1000) break;
      if (attempt === 12) throw new Error(`edge-tts failed for ${line.id}: ${r.stderr ?? r.error}`);
      spawnSync('sleep', [String(Math.min(20, 2 * attempt))]);
    }
  }
  // Bundled Remotion ffmpeg has few filters: find head/tail silence, then trim + fade + loudness.
  const det = spawnSync(join(compositor, 'ffmpeg'), ['-hide_banner', '-i', mp3, '-af', 'silencedetect=noise=-48dB:d=0.04', '-f', 'null', '-'], { env, encoding: 'utf8' }).stderr;
  const total = Number(/Duration: (\d+):(\d+):([\d.]+)/.exec(det).slice(1).reduce((a, v) => a * 60 + Number(v), 0));
  const starts = [...det.matchAll(/silence_start: ([\d.-]+)/g)].map((m) => Number(m[1]));
  const ends = [...det.matchAll(/silence_end: ([\d.]+)/g)].map((m) => Number(m[1]));
  const head = starts.length && starts[0] <= 0.01 ? Math.max(0, ends[0] - 0.03) : 0;
  const lastStart = starts.at(-1);
  const tail = lastStart !== undefined && lastStart > head + 0.2 && (ends.length < starts.length || ends.at(-1) >= total - 0.02) ? Math.min(total, lastStart + 0.12) : total;
  run(join(compositor, 'ffmpeg'), ['-hide_banner', '-loglevel', 'error', '-y', '-i', mp3, '-af',
    `atrim=start=${head.toFixed(3)}:end=${tail.toFixed(3)},asetpts=PTS-STARTPTS,loudnorm=I=-17:TP=-2:LRA=7`,
    '-ar', '48000', '-ac', '1', wav]);
  const probe = run(join(compositor, 'ffprobe'), ['-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', wav]);
  const duration = Number(probe.stdout.trim());
  lines.push({ id: line.id, scene: line.scene, text: line.text, pauseAfter: line.pauseAfter, duration: Math.round(duration * 1000) / 1000 });
  console.log(line.id, duration.toFixed(2));
}
mkdirSync(join(root, 'src/intro'), { recursive: true });
writeFileSync(join(root, `src/intro/vo${suffix}.json`), JSON.stringify({ lang, provider, voice: provider === 'edge' ? script.voice : `elevenlabs:${eleven.voiceId}:${eleven.model}`, note: script.note, lines }, null, 2) + '\n');
