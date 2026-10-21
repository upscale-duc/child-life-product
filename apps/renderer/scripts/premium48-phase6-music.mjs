// Original synthesized scores: marimba/guitar 96 BPM; guitar harmonics/wood percussion 82 BPM.
// No third-party recordings, soundfonts, samples or borrowed melodies.
import { Buffer } from 'node:buffer';
import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
const out = process.argv[2];
if (!out) throw new Error('Output directory required');
mkdirSync(out, { recursive: true });
const rate = 48000,
  n = rate * 35;
for (const [name, bpm, root, compare] of [
  ['p48-milestone', 96, 60, false],
  ['p48-discover', 82, 55, true],
]) {
  const channels = [new Float64Array(n), new Float64Array(n)];
  function note(midi, start, length, gain, pan = 0, voice = 'piano') {
    const at = Math.round(start * rate),
      count = Math.min(n - at, Math.round(length * rate)),
      f = 440 * 2 ** ((midi - 69) / 12);
    for (let i = 0; i < count; i++) {
      const t = i / rate,
        strings = voice === 'strings',
        guitar = voice === 'guitar' || voice === 'ukulele',
        bell = voice === 'glock';
      const attack = Math.min(1, t / (strings ? 0.55 : guitar ? 0.008 : 0.026)),
        tail = Math.min(1, Math.max(0, (length - t) / (strings ? 0.75 : 0.24)));
      let wave = 0;
      if (bell)
        wave =
          Math.sin(2 * Math.PI * f * t) * Math.exp(-t * 2.5) +
          0.18 * Math.sin(2 * Math.PI * f * 2.76 * t) * Math.exp(-t * 4);
      for (let h = 1; h <= (bell ? 0 : strings ? 3 : guitar ? 7 : 5); h++) {
        const decay = strings
          ? 1
          : guitar
            ? Math.exp(-t * (0.9 + h * 0.28))
            : Math.exp(-t / (2.5 / h ** 0.25));
        wave +=
          (Math.sin(2 * Math.PI * f * h * t) * decay) / h ** (strings ? 2.4 : guitar ? 1.6 : 2);
        if (strings) wave += (Math.sin(2 * Math.PI * f * h * 1.0015 * t) * 0.22) / h ** 2.6;
      }
      const sample = wave * attack * tail * gain;
      channels[0][at + i] += sample * (0.7 - pan * 0.18);
      channels[1][at + i] += sample * (0.7 + pan * 0.18);
    }
  }
  const beat = 60 / bpm;
  const chords = compare
    ? [
        [0, 7, 12],
        [5, 9, 12],
        [2, 7, 11],
        [7, 11, 14],
      ]
    : [
        [0, 4, 7],
        [9, 12, 16],
        [5, 9, 12],
        [7, 11, 14],
      ];
  function wood(start, gain) {
    const at = Math.round(start * rate);
    let seed = 73;
    for (let i = 0; i < Math.min(rate * 0.09, n - at); i++) {
      seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
      const t = i / rate;
      const sample =
        ((seed / 4294967296 - 0.5) * 0.3 + Math.sin(2 * Math.PI * 720 * t)) *
        Math.exp(-t * 75) *
        gain;
      channels[0][at + i] += sample * 0.7;
      channels[1][at + i] += sample * 0.7;
    }
  }
  function marimba(midi, start, gain) {
    const at = Math.round(start * rate),
      f = 440 * 2 ** ((midi - 69) / 12);
    for (let i = 0; i < Math.min(rate * 1.7, n - at); i++) {
      const t = i / rate,
        sample =
          (Math.sin(2 * Math.PI * f * t) * Math.exp(-t * 3.8) +
            0.13 * Math.sin(2 * Math.PI * f * 4 * t) * Math.exp(-t * 12)) *
          Math.min(1, t / 0.004) *
          gain;
      channels[0][at + i] += sample * 0.68;
      channels[1][at + i] += sample * 0.72;
    }
  }
  for (let bar = 0; bar * 4 * beat < 31; bar++) {
    const start = bar * 4 * beat,
      chord = chords[bar % 4];
    note(root - 12 + chord[0], start, 3.2, 0.038, -0.25, 'guitar');
    if (compare) {
      for (const [j, k] of [0, 2, 1, 2, 0, 1].entries())
        note(
          root + 12 + chord[k],
          start + j * beat * 0.5,
          2.4,
          0.04,
          ((j % 3) - 1) * 0.4,
          'guitar',
        );
      wood(start + beat, 0.017);
      wood(start + 3 * beat, 0.013);
    } else {
      for (const [j, k] of [0, 1, 2, 1, 2, 0].entries())
        marimba(root + chord[k] + 12, start + j * beat * 0.5, start >= 14 ? 0.055 : 0.044);
      for (const [offset, k] of [
        [0, 0],
        [1.5, 2],
        [3, 1],
      ])
        note(root + chord[k], start + offset * beat, 2.7, 0.035, 0.18, 'guitar');
    }
  }
  for (const interval of [0, 4, 7]) note(root + interval, 31.7, 3.3, 0.03, 0, 'guitar');
  const pcm = Buffer.alloc(n * 4),
    header = Buffer.alloc(44);
  for (let i = 0; i < n; i++)
    for (let c = 0; c < 2; c++) {
      const fade = Math.min(1, i / (rate * 0.4), (n - 1 - i) / (rate * 1.2));
      pcm.writeInt16LE(Math.round(Math.tanh(channels[c][i] * fade) * 30000), i * 4 + c * 2);
    }
  header.write('RIFF');
  header.writeUInt32LE(36 + pcm.length, 4);
  header.write('WAVEfmt ', 8);
  header.writeUInt32LE(16, 16);
  header.writeUInt16LE(1, 20);
  header.writeUInt16LE(2, 22);
  header.writeUInt32LE(rate, 24);
  header.writeUInt32LE(rate * 4, 28);
  header.writeUInt16LE(4, 32);
  header.writeUInt16LE(16, 34);
  header.write('data', 36);
  header.writeUInt32LE(pcm.length, 40);
  writeFileSync(join(out, `${name}.wav`), Buffer.concat([header, pcm]));
}
