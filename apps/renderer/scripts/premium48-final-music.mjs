// Original additive synthesis. Fourteen new arrangements, no external recordings or samples.
import { Buffer } from 'node:buffer';
import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { premium48FinalDesigns } from '@child-life/contracts';
const out = process.argv[2],
  phase = Number(process.argv[3]);
if (!out || phase < 7 || phase > 12) throw new Error('Output directory and phase 7–12 required');
mkdirSync(out, { recursive: true });
const melodies = [
  [12, 7, 4, 9, 7, 4, 2, 0],
  [7, 12, 11, 7, 9, 5, 4, 2],
  [4, 7, 12, 9, 7, 14, 12, 7],
  [0, 7, 9, 4, 7, 2, 5, 4],
  [12, 4, 7, 2, 11, 7, 4, 0],
  [7, 12, 9, 7, 4, 2, 4, 0],
  [0, 4, 9, 7, 12, 14, 9, 7],
  [12, 9, 7, 4, 7, 2, 4, 0],
  [0, 7, 4, 12, 9, 14, 7, 4],
  [4, 7, 12, 16, 14, 9, 7, 12],
  [12, 11, 7, 9, 4, 7, 2, 0],
  [0, 4, 7, 12, 11, 9, 7, 0],
];
for (const d of premium48FinalDesigns.filter((d) => Math.ceil(d.n / 2) === phase))
  for (const variant of d.n === 20 ? ['neutral', 'tet', 'christmas'] : ['default']) {
    const rate = 48000,
      seconds = d.n === 22 ? 50 : 35,
      n = seconds * rate,
      channels = [new Float64Array(n), new Float64Array(n)],
      beat = 60 / d.bpm,
      root = [55, 60, 57, 62, 58, 53, 60, 62, 55, 60, 58, 55][d.n - 13];
    function note(midi, start, length, gain, voice = 'piano', pan = 0) {
      const at = Math.round(start * rate),
        count = Math.max(0, Math.min(n - at, Math.round(length * rate))),
        f = 440 * 2 ** ((midi - 69) / 12);
      for (let i = 0; i < count; i++) {
        const t = i / rate,
          strings = voice === 'strings',
          guitar = voice === 'guitar',
          bell = voice === 'bell',
          attack = Math.min(1, t / (strings ? 0.5 : guitar ? 0.008 : 0.025)),
          tail = Math.min(1, (length - t) / 0.4);
        let wave = 0;
        for (let h = 1; h <= (bell ? 2 : strings ? 4 : guitar ? 7 : 5); h++) {
          const partial = bell && h === 2 ? 2.76 : h,
            decay = strings
              ? 1
              : Math.exp(-t * (guitar ? 1 + h * 0.3 : bell ? 2.8 * h : 0.8 + h * 0.3));
          wave +=
            (Math.sin(2 * Math.PI * f * partial * t) * decay) /
            h ** (strings ? 2.3 : guitar ? 1.7 : 2);
          if (strings) wave += (0.15 * Math.sin(2 * Math.PI * f * partial * 1.001 * t)) / h ** 2.5;
        }
        const v = wave * attack * tail * gain;
        channels[0][at + i] += v * (0.7 - pan * 0.2);
        channels[1][at + i] += v * (0.7 + pan * 0.2);
      }
    }
    function wood(start, gain) {
      const at = Math.round(start * rate);
      for (let i = 0; i < Math.min(rate * 0.1, n - at); i++) {
        const t = i / rate,
          v = Math.sin(2 * Math.PI * (d.n % 2 ? 490 : 670) * t) * Math.exp(-t * 80) * gain;
        channels[0][at + i] += v;
        channels[1][at + i] += v * 0.8;
      }
    }
    const changes =
      d.n % 3 === 0
        ? [
            [0, 4, 7],
            [5, 9, 12],
            [9, 12, 16],
            [7, 11, 14],
          ]
        : d.n % 3 === 1
          ? [
              [0, 4, 7],
              [9, 12, 16],
              [2, 7, 11],
              [5, 9, 12],
            ]
          : [
              [0, 7, 12],
              [5, 9, 12],
              [2, 7, 11],
              [7, 11, 14],
            ];
    const slow = [13, 14, 17, 18, 23].includes(d.n),
      lead =
        d.n === 18 || variant === 'christmas'
          ? 'bell'
          : [15, 16, 21, 24].includes(d.n) || variant === 'neutral' || variant === 'tet'
            ? 'guitar'
            : 'piano';
    for (let bar = 0; bar * 4 * beat < seconds - 3.8; bar++) {
      const start = bar * 4 * beat,
        chord = changes[(bar + Math.floor((d.n - 13) / 3)) % 4];
      note(root - 12 + chord[0], start, beat * 3.8, 0.035, 'guitar', -0.4);
      for (let j = 0; j < 3; j++)
        note(
          root + chord[j],
          start + j * beat * (slow ? 0.8 : 0.5),
          beat * 3,
          0.022,
          d.n === 22 || d.n === 23 ? 'strings' : 'piano',
          (j - 1) * 0.35,
        );
      const melody = melodies[d.n - 13],
        notes = slow ? 2 : 4;
      for (let j = 0; j < notes; j++) {
        let interval = melody[(bar * notes + j) % melody.length];
        if (variant === 'tet') interval = [0, 2, 4, 7, 9][(bar + j) % 5];
        note(
          root + 12 + interval,
          start + j * beat * (slow ? 2 : 1),
          beat * (slow ? 2.8 : 1.8),
          d.n === 18 ? 0.022 : 0.038,
          lead,
          ((j % 3) - 1) * 0.3,
        );
      }
      if ([15, 16, 19, 20, 21].includes(d.n)) {
        wood(start + beat, 0.012);
        wood(start + 3 * beat, 0.009);
      }
    }
    for (const v of [0, 4, 7]) note(root + v, seconds - 3.7, 3.7, 0.026, lead);
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
    writeFileSync(
      join(out, `p48-${d.part}${variant === 'default' ? '' : `-${variant}`}.wav`),
      Buffer.concat([header, pcm]),
    );
  }
