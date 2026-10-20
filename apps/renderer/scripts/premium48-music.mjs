// Original deterministic scores for the phase-1 review. No external samples or melodies.
// Synthesized soft piano; the embrace score adds a sustained low string voice.
// Masters: 48 kHz stereo, 35 seconds. Encode / normalize with the review rendering script.
import { Buffer } from 'node:buffer';
import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
const out = process.argv[2];
if (!out) throw new Error('usage: premium48-music <outDir>');
mkdirSync(out, { recursive: true });
const rate = 48000,
  seconds = 35,
  n = rate * seconds;
for (const [name, bpm, root, strings] of [
  ['p48-arrival', 68, 60, false],
  ['p48-embrace', 64, 57, true],
]) {
  const channels = [new Float64Array(n), new Float64Array(n)];
  function note(midi, start, len, gain, pan = 0, pad = false) {
    const frequency = 440 * 2 ** ((midi - 69) / 12),
      at = Math.round(start * rate),
      count = Math.min(n - at, Math.round((len + 1.5) * rate));
    for (let i = 0; i < count; i++) {
      const t = i / rate;
      const envelope = pad
        ? Math.min(1, t / 0.6) * Math.exp(-t / 8) * Math.min(1, Math.max(0, (len + 0.8 - t) / 0.8))
        : Math.min(1, t / 0.014) *
          Math.exp(-t / 1.8) *
          Math.min(1, Math.max(0, (len + 0.5 - t) / 0.5));
      const wave =
        Math.sin(2 * Math.PI * frequency * t) +
        0.26 * Math.sin(4 * Math.PI * frequency * t) +
        0.07 * Math.sin(6 * Math.PI * frequency * t);
      channels[0][at + i] += wave * envelope * gain * (0.7 - pan * 0.2);
      channels[1][at + i] += wave * envelope * gain * (0.7 + pan * 0.2);
    }
  }
  const beat = 60 / bpm;
  // An original three-note motif, moving between C/F/Am/G (arrival) or A/D/F/E (embrace).
  const chords = [
    [0, 4, 7],
    [5, 9, 12],
    [9, 12, 16],
    [7, 11, 14],
  ];
  for (let bar = 0; bar * 4 * beat < 32; bar++) {
    const chord = chords[bar % 4],
      start = bar * 4 * beat;
    for (let j = 0; j < 3; j++) note(root + chord[j], start + j * beat, 2.8, 0.055, j - 1);
    note(root - 12 + chord[0], start, 3.4, 0.08, -0.2);
    if (strings) note(root - 24 + chord[0], start, 4 * beat, 0.055, 0.3, true);
    if (bar % 2 === 0)
      for (const [k, offset] of [
        [0, 7],
        [1.5, 4],
        [3, 0],
      ])
        note(root + 12 + chord[0] + offset, start + k * beat, 1.7, 0.038, 0.2);
  }
  // Natural, sustained final chord before the renderer's 1.2-second fade.
  for (const interval of [0, 4, 7]) note(root + interval, 31.6, 3.4, 0.045);
  const bytes = Buffer.alloc(n * 4),
    header = Buffer.alloc(44);
  for (let i = 0; i < n; i++) {
    const fade = Math.min(1, i / (rate * 0.4), (n - 1 - i) / (rate * 1.2));
    for (let c = 0; c < 2; c++)
      bytes.writeInt16LE(Math.round(Math.tanh(channels[c][i] * fade) * 30000), i * 4 + c * 2);
  }
  header.write('RIFF');
  header.writeUInt32LE(36 + bytes.length, 4);
  header.write('WAVEfmt ', 8);
  header.writeUInt32LE(16, 16);
  header.writeUInt16LE(1, 20);
  header.writeUInt16LE(2, 22);
  header.writeUInt32LE(rate, 24);
  header.writeUInt32LE(rate * 4, 28);
  header.writeUInt16LE(4, 32);
  header.writeUInt16LE(16, 34);
  header.write('data', 36);
  header.writeUInt32LE(bytes.length, 40);
  writeFileSync(join(out, `${name}.wav`), Buffer.concat([header, bytes]));
}
