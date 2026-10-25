/** CC0 dedication: this original DSP code and the generated waveforms.
 * No recordings, samples, external instrument banks, or paid services are used.
 * Fixed seed makes asset regeneration deterministic. */
import { writeFileSync, mkdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
const dir = fileURLToPath(new URL('../public/audio/sfx/', import.meta.url));
mkdirSync(dir, { recursive: true });
const rate = 48000;
let seed = 29102026;
const noise = () => {
  seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
  return seed / 2147483648 - 1;
};
function write(name, seconds, fn, peak = 0.22) {
  const samples = Math.ceil(seconds * rate),
    a = new Float64Array(samples);
  let max = 0,
    state = 0;
  for (let i = 0; i < samples; i++) {
    state = 0.93 * state + 0.07 * noise();
    a[i] = fn(i / rate, seconds, state);
    max = Math.max(max, Math.abs(a[i]));
  }
  const b = Buffer.alloc(44 + samples * 4);
  b.write('RIFF');
  b.writeUInt32LE(b.length - 8, 4);
  b.write('WAVEfmt ', 8);
  b.writeUInt32LE(16, 16);
  b.writeUInt16LE(1, 20);
  b.writeUInt16LE(2, 22);
  b.writeUInt32LE(rate, 24);
  b.writeUInt32LE(rate * 4, 28);
  b.writeUInt16LE(4, 32);
  b.writeUInt16LE(16, 34);
  b.write('data', 36);
  b.writeUInt32LE(samples * 4, 40);
  for (let i = 0; i < samples; i++) {
    const v = Math.round((a[i] / Math.max(max, 1e-8)) * peak * 32767);
    b.writeInt16LE(v, 44 + i * 4);
    b.writeInt16LE(Math.round(v * 0.97), 46 + i * 4);
  }
  writeFileSync(dir + name + '.wav', b);
}
const fade = (t, d, a = 0.015, r = 0.08) => Math.min(1, t / a, Math.max(0, (d - t) / r));
for (const [name, f] of [
  ['felt-note', 261.6256],
  ['felt-note-high', 329.6276],
])
  write(
    name,
    0.9,
    (t, d, n) =>
      fade(t, d, 0.018, 0.2) *
      Math.exp(-t * 5) *
      (Math.sin(2 * Math.PI * f * t) +
        0.14 * Math.sin(2 * Math.PI * f * 2 * t) * Math.exp(-t * 10) +
        0.035 * n),
  );
write(
  'soft-tap',
  0.2,
  (t, d, n) =>
    fade(t, d, 0.003, 0.05) *
    Math.exp(-t * 55) *
    (0.7 * Math.sin(2 * Math.PI * (155 - 70 * t) * t) + 0.14 * n),
  0.18,
);
write('soft-air', 0.65, (t, d, n) => Math.sin((Math.PI * t) / d) ** 2 * n, 0.13);
write(
  'paper',
  0.7,
  (t, d, n) =>
    fade(t, d, 0.025, 0.1) *
    n *
    (Math.exp(-(((t - 0.17) / 0.095) ** 2)) + 0.45 * Math.exp(-(((t - 0.4) / 0.08) ** 2))),
  0.15,
);
write(
  'warm-swell',
  1.7,
  (t, d, n) => Math.sin((Math.PI * t) / d) ** 2 * (n + 0.04 * Math.sin(2 * Math.PI * 130.8128 * t)),
  0.13,
);
write(
  'logo-signature',
  1.8,
  (t, d, n) => {
    let v = 0;
    for (const [at, f] of [
      [0, 174.614],
      [0.18, 261.626],
      [0.38, 349.228],
    ]) {
      const x = t - at;
      if (x > 0)
        v += Math.min(1, x / 0.025) * Math.exp(-x * 5) * Math.sin(2 * Math.PI * f * x) * 0.11;
    }
    return fade(t, d, 0.02, 0.4) * (v + 0.1 * n * Math.sin((Math.PI * t) / d) ** 2);
  },
  0.2,
);
console.log('Generated seven original CC0 sound-design assets');
