// Original synthesized review scores: nylon-style plucks at 78 BPM; acoustic + soft piano at 76.
// Deterministic synthesis; no external recordings, samples or borrowed melodies.
import { Buffer } from 'node:buffer';
import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
const out = process.argv[2];
if (!out) throw new Error('Output directory required');
mkdirSync(out, { recursive: true });
const rate = 48000,
  n = rate * 35;
for (const [name, bpm, root, month] of [
  ['p48-home', 78, 55, false],
  ['p48-month', 76, 60, true],
]) {
  const channels = [new Float64Array(n), new Float64Array(n)];
  function note(midi, start, length, gain, pan = 0, piano = false, bell = false) {
    const f = 440 * 2 ** ((midi - 69) / 12),
      at = Math.round(start * rate),
      count = Math.min(n - at, Math.round(length * rate));
    for (let i = 0; i < count; i++) {
      const t = i / rate;
      const attack = Math.min(1, t / (piano ? 0.018 : 0.007));
      const tail = Math.min(1, Math.max(0, (length - t) / 0.22));
      let wave = 0;
      for (let harmonic = 1; harmonic <= 5; harmonic++) {
        const multiplier = bell ? (harmonic === 1 ? 1 : 2.7 + harmonic * 0.57) : harmonic;
        const decay = bell ? 1.1 : piano ? 1.8 : 1.5 / (1 + (harmonic - 1) * 0.35);
        wave +=
          (Math.sin(2 * Math.PI * f * multiplier * t) * Math.exp(-t / decay)) /
          harmonic ** (piano ? 2 : 1.7);
      }
      const value = wave * attack * tail * gain;
      channels[0][at + i] += value * (0.7 - pan * 0.18);
      channels[1][at + i] += value * (0.7 + pan * 0.18);
    }
  }
  const beat = 60 / bpm;
  const chords = month
    ? [
        [0, 4, 7],
        [9, 12, 16],
        [5, 9, 12],
        [7, 11, 14],
      ]
    : [
        [0, 4, 7],
        [5, 9, 12],
        [2, 5, 9],
        [7, 11, 14],
      ];
  for (let bar = 0; bar * 4 * beat < 31; bar++) {
    const chord = chords[bar % 4],
      start = bar * 4 * beat;
    const pattern = [0, 2, 1, 2, 0, 1, 2, 1];
    for (let j = 0; j < 8; j++)
      note(root + chord[pattern[j]], start + j * 0.5 * beat, 2.6, 0.055, ((j % 3) - 1) * 0.5);
    note(root - 12 + chord[0], start, 3.5, 0.065, -0.2);
    if (month) {
      note(root + 12 + chord[0], start + 0.25 * beat, 3.2, 0.03, 0.35, true);
      if (start >= 21)
        for (const interval of chord) note(root + interval, start, 3.2, 0.027, 0.2, true);
    }
    if (bar % 2 === 1)
      for (const [offset, interval] of [
        [1, 7],
        [2.5, 4],
        [3.5, 2],
      ])
        note(root + 12 + chord[0] + interval, start + offset * beat, 1.7, 0.026, 0.4, month);
  }
  if (!month)
    for (const [start, midi] of [
      [28.4, 79],
      [29.1, 76],
      [30, 74],
    ])
      note(midi, start, 1.7, 0.028, 0.2, false, true);
  for (const interval of [0, 4, 7]) note(root + interval, 31.8, 3.2, 0.035, 0, month);
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
