// Original synthesized scores: piano/guitar 88 BPM; piano arpeggio + soft strings 72 BPM.
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
  ['p48-chapter', 88, 60, false],
  ['p48-compare', 72, 53, true],
]) {
  const channels = [new Float64Array(n), new Float64Array(n)];
  function note(midi, start, length, gain, pan = 0, voice = 'piano') {
    const at = Math.round(start * rate),
      count = Math.min(n - at, Math.round(length * rate)),
      f = 440 * 2 ** ((midi - 69) / 12);
    for (let i = 0; i < count; i++) {
      const t = i / rate,
        strings = voice === 'strings',
        guitar = voice === 'guitar';
      const attack = Math.min(1, t / (strings ? 0.55 : guitar ? 0.008 : 0.026)),
        tail = Math.min(1, Math.max(0, (length - t) / (strings ? 0.75 : 0.24)));
      let wave = 0;
      for (let h = 1; h <= (strings ? 3 : guitar ? 7 : 5); h++) {
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
  const beat = 60 / bpm,
    chords = compare
      ? [
          [0, 4, 7],
          [7, 11, 14],
          [9, 12, 16],
          [5, 9, 12],
        ]
      : [
          [0, 4, 7],
          [2, 5, 9],
          [5, 9, 12],
          [7, 11, 14],
        ];
  for (let bar = 0; bar * 4 * beat < 31; bar++) {
    const start = bar * 4 * beat,
      chord = chords[bar % 4];
    note(root - 12 + chord[0], start, 3.6, 0.06, -0.2, 'piano');
    if (compare) {
      for (const [j, index] of [0, 1, 2, 1, 0, 2].entries())
        note(root + chord[index], start + j * beat * 0.5, 3.4, 0.044, ((j % 3) - 1) * 0.4, 'piano');
      if (start >= 13.8)
        for (const interval of chord) note(root + interval, start, 4.1, 0.024, 0.1, 'strings');
      if (bar % 2 === 1) note(root + 12 + chord[1], start + 2.5 * beat, 2.6, 0.026, 0.3, 'piano');
    } else {
      for (const [j, index] of [0, 1, 2, 0, 2, 1, 0, 2].entries())
        note(
          root + chord[index],
          start + j * beat * 0.5,
          1.9,
          0.042,
          ((j % 3) - 1) * 0.4,
          'guitar',
        );
      for (const [offset, interval] of [
        [0, 12],
        [1.5, 7],
        [3, 4],
      ])
        note(root + chord[0] + interval, start + offset * beat, 2.8, 0.03, 0.25, 'piano');
    }
  }
  for (const interval of [0, 4, 7])
    note(root + interval, 31.7, 3.3, 0.029, 0, compare ? 'piano' : 'guitar');
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
