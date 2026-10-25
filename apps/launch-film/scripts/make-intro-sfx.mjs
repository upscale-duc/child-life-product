/** Product Introduction SFX — original DSP synthesis, CC0 (no recordings, samples or paid services).
 * Tuned to the music ("Dream Culture" analyses as D major): chimes use D, F#, A only.
 * Output: public/intro/sfx/*.wav (48 kHz stereo, 16-bit). Deterministic (fixed seed). */
import { mkdirSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
const dir = fileURLToPath(new URL('../public/intro/sfx/', import.meta.url));
mkdirSync(dir, { recursive: true });
const SR = 48000;
let seed = 22102026;
const rnd = () => {
  seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
  return seed / 2147483648 - 1;
};
const N = { D4: 293.66, F4s: 369.99, A4: 440, D5: 587.33, F5s: 739.99, A5: 880, D6: 1174.66, F6s: 1479.98, A6: 1760, D3: 146.83, A3: 220 };

// ---- tiny DSP kit ----
const buf = (sec) => new Float64Array(Math.ceil(sec * SR));
const add = (dst, src, at = 0, gain = 1) => {
  const o = Math.round(at * SR);
  for (let i = 0; i < src.length && o + i < dst.length; i++) dst[o + i] += src[i] * gain;
  return dst;
};
/** Bell/chime: inharmonic partials with independent decays (felt-mallet glass). */
const bell = (f, sec = 2.2, bright = 1) => {
  const b = buf(sec);
  const partials = [
    [1, 1, 2.2],
    [2.0, 0.32 * bright, 4.2],
    [2.76, 0.18 * bright, 6.5],
    [5.4, 0.07 * bright, 11],
    [8.93, 0.025 * bright, 17],
  ];
  for (let i = 0; i < b.length; i++) {
    const t = i / SR;
    const atk = Math.min(1, t / 0.004);
    let v = 0;
    for (const [m, a, d] of partials) v += a * Math.exp(-t * d) * Math.sin(2 * Math.PI * f * m * t + m);
    b[i] = atk * v;
  }
  return b;
};
/** Soft pad tone with slow attack and gentle detune. */
const pad = (freqs, sec, attack, release) => {
  const b = buf(sec);
  for (let i = 0; i < b.length; i++) {
    const t = i / SR;
    const env = Math.min(1, t / attack) * Math.min(1, Math.max(0, (sec - t) / release));
    let v = 0;
    freqs.forEach((f, k) => {
      for (const det of [-0.0025, 0.0025]) {
        const ff = f * (1 + det);
        v += (Math.sin(2 * Math.PI * ff * t + k) + 0.18 * Math.sin(4 * Math.PI * ff * t) + 0.06 * Math.sin(6 * Math.PI * ff * t)) / freqs.length;
      }
    });
    b[i] = env * v * (1 + 0.04 * Math.sin(2 * Math.PI * 0.35 * t));
  }
  return b;
};
/** One-pole low/high pass on noise for paper and air. */
const noise = (sec, lp = 0.2, hp = 0.02) => {
  const b = buf(sec);
  let l = 0,
    h = 0;
  for (let i = 0; i < b.length; i++) {
    l += lp * (rnd() - l);
    h += hp * (l - h);
    b[i] = l - h;
  }
  return b;
};
const shape = (b, fn) => {
  for (let i = 0; i < b.length; i++) b[i] *= fn(i / SR, b.length / SR);
  return b;
};
/** Small Schroeder room (4 combs + 2 allpasses) → stereo pair with a short pre-delay. */
const room = (dry, wet = 0.22, size = 1) => {
  const tail = Math.ceil(1.6 * SR);
  const out = [new Float64Array(dry.length + tail), new Float64Array(dry.length + tail)];
  const combs = [
    [1557, 1617],
    [1491, 1422],
    [1277, 1356],
    [1188, 1116],
  ];
  for (let ch = 0; ch < 2; ch++) {
    const len = out[ch].length;
    const sum = new Float64Array(len);
    for (const pair of combs) {
      const d = Math.round(pair[ch] * size * (SR / 44100));
      const line = new Float64Array(d);
      let idx = 0,
        lp = 0;
      for (let i = 0; i < len; i++) {
        const x = i - 720 >= 0 && i - 720 < dry.length ? dry[i - 720] : 0;
        const y = line[idx];
        lp = 0.72 * y + 0.28 * lp;
        line[idx] = x + lp * 0.8;
        idx = (idx + 1) % d;
        sum[i] += y;
      }
    }
    for (const d0 of [556, 441]) {
      const d = d0 + ch * 23;
      const line = new Float64Array(d);
      let idx = 0;
      for (let i = 0; i < len; i++) {
        const x = sum[i];
        const y = line[idx];
        line[idx] = x + y * 0.5;
        sum[i] = y - x * 0.5;
        idx = (idx + 1) % d;
      }
    }
    for (let i = 0; i < len; i++) out[ch][i] = (i < dry.length ? dry[i] : 0) * (1 - wet * 0.4) + (sum[i] * wet) / 4;
  }
  return out;
};
const write = (name, stereo, peak = 0.5) => {
  const [L, R] = Array.isArray(stereo) ? stereo : [stereo, stereo];
  // Trim trailing near-silence.
  let n = L.length;
  while (n > SR * 0.2 && Math.abs(L[n - 1]) < 1e-5 && Math.abs(R[n - 1]) < 1e-5) n--;
  let max = 1e-9;
  for (let i = 0; i < n; i++) max = Math.max(max, Math.abs(L[i]), Math.abs(R[i]));
  const fadeTail = Math.round(0.05 * SR);
  const b = Buffer.alloc(44 + n * 4);
  b.write('RIFF');
  b.writeUInt32LE(b.length - 8, 4);
  b.write('WAVEfmt ', 8);
  b.writeUInt32LE(16, 16);
  b.writeUInt16LE(1, 20);
  b.writeUInt16LE(2, 22);
  b.writeUInt32LE(SR, 24);
  b.writeUInt32LE(SR * 4, 28);
  b.writeUInt16LE(4, 32);
  b.writeUInt16LE(16, 34);
  b.write('data', 36);
  b.writeUInt32LE(n * 4, 40);
  for (let i = 0; i < n; i++) {
    const g = (peak / max) * Math.min(1, (n - i) / fadeTail);
    b.writeInt16LE(Math.round(Math.max(-1, Math.min(1, L[i] * g)) * 32767), 44 + i * 4);
    b.writeInt16LE(Math.round(Math.max(-1, Math.min(1, R[i] * g)) * 32767), 46 + i * 4);
  }
  writeFileSync(dir + name + '.wav', b);
  console.log(name, (n / SR).toFixed(2) + 's');
};

// PI01 — four journey stations, rising D5 F#5 A5 D6 (levels set in the cue sheet, each softer).
[N.D5, N.F5s, N.A5, N.D6].forEach((f, i) => write(`stage-${i + 1}`, room(bell(f, 1.8, 0.7), 0.3), 0.45));
// PI02 — light paper (three variants so repeats don't sound copied).
for (let k = 1; k <= 3; k++)
  write(
    `paper-${k}`,
    room(
      shape(noise(0.42, 0.35, 0.06), (t) => Math.exp(-(((t - 0.07 - 0.02 * k) / 0.045) ** 2)) + 0.4 * Math.exp(-(((t - 0.2) / 0.05) ** 2))),
      0.12,
      0.6,
    ),
    0.35,
  );
// PI03 — generic soft message tick (not a notification chime).
{
  const b = buf(0.25);
  add(b, shape(bell(N.A6, 0.25, 0.2), (t) => Math.exp(-t * 30)), 0, 0.7);
  add(b, shape(bell(N.D6 * 2, 0.2, 0.2), (t) => Math.exp(-t * 34)), 0.055, 0.45);
  write('message-tick', room(b, 0.12, 0.5), 0.35);
}
// PI05 — "Meet Child Life": open D-major bloom under the brand chime.
write('open-chord', room(pad([N.D3, N.A3, N.D4, N.F4s, N.A4], 4.2, 0.35, 2.4), 0.35, 1.2), 0.5);
{
  const b = buf(3.2);
  [N.D5, N.F5s, N.A5, N.D6].forEach((f, i) => add(b, bell(f, 3, 0.8), i * 0.11, 1 - i * 0.12));
  add(b, shape(noise(3, 0.5, 0.2), (t) => 0.035 * Math.exp(-t * 2) * Math.min(1, t / 0.2)), 0.2);
  write('brand-chime', room(b, 0.32, 1.1), 0.5);
}
// PI06 — tap on the widget "+" and Siri's small confirmation.
{
  const b = buf(0.18);
  add(b, shape(noise(0.18, 0.5, 0.15), (t) => Math.exp(-t * 90)), 0, 0.6);
  for (let i = 0; i < b.length; i++) {
    const t = i / SR;
    b[i] += 0.8 * Math.exp(-t * 60) * Math.sin(2 * Math.PI * (210 - 80 * t) * t);
  }
  write('tap', room(b, 0.08, 0.4), 0.4);
}
{
  const b = buf(0.6);
  add(b, bell(N.A5, 0.5, 0.4), 0, 0.8);
  add(b, bell(N.D6, 0.5, 0.4), 0.075, 0.9);
  write('confirm-tick', room(shape(b, (t) => Math.exp(-t * 6)), 0.18, 0.6), 0.38);
}
// PI07 — Lumi appears: higher sparkle (F#6, A6) than the brand chime.
{
  const b = buf(1.6);
  add(b, bell(N.F6s, 1.4, 0.5), 0, 0.8);
  add(b, bell(N.A6, 1.4, 0.5), 0.07, 0.7);
  add(b, bell(N.D6 * 2, 1.2, 0.4), 0.14, 0.35);
  write('lumi-chime', room(b, 0.3, 0.9), 0.4);
}
// PI08 — milestone: warm A5 + D6 dyad.
{
  const b = buf(2);
  add(b, bell(N.A5, 1.9, 0.6), 0, 0.8);
  add(b, bell(N.D6, 1.9, 0.6), 0.03, 0.7);
  write('milestone-chime', room(b, 0.3, 1), 0.42);
}
// PI09 — thick card flip, video-ready single note, and a soft lift into the emotional line.
{
  const b = buf(0.6);
  add(b, shape(noise(0.6, 0.18, 0.03), (t) => Math.exp(-(((t - 0.12) / 0.07) ** 2)) + 0.7 * Math.exp(-(((t - 0.3) / 0.06) ** 2))), 0, 1);
  for (let i = 0; i < b.length; i++) {
    const t = i / SR - 0.3;
    if (t > 0) b[i] += 0.5 * Math.exp(-t * 28) * Math.sin(2 * Math.PI * 110 * t);
  }
  write('paper-thick', room(b, 0.14, 0.7), 0.45);
}
write('video-chime', room(bell(N.D6, 2.4, 0.6), 0.34, 1.1), 0.4);
write('lift', room(pad([N.D4, N.A4, N.D5, N.F5s], 3.2, 2.2, 0.9), 0.3, 1.2), 0.32);
// PI10 — closing chime: same family as the brand chime, resolving down to D with a long tail.
{
  const b = buf(5);
  [N.A5, N.F5s, N.D5].forEach((f, i) => add(b, bell(f, 4.5, 0.75), i * 0.16, 0.9));
  add(b, bell(N.D4, 4.8, 0.4), 0.32, 0.6);
  add(b, pad([N.D3, N.A3, N.D4, N.F4s], 4.6, 0.6, 3), 0.2, 0.35);
  write('closing-chime', room(b, 0.38, 1.3), 0.52);
}
console.log('Product Introduction SFX generated (CC0).');
