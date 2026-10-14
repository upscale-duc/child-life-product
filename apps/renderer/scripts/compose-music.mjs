// Original placeholder tracks for Thư viện nhạc (licence "original": composed and synthesised
// here, owned by Child Life, nothing to license): Ru êm (gentle), Nắng mai (happy), Bình minh
// (emotional piano), Mơ màng (dreamy), Tiệc vui (festive). Placeholders until commercially
// licensed tracks are bought (owner, 2026-10-14). Writes 16-bit
// stereo WAV files; `make-previews.ts` encodes them to M4A with Remotion's own ffmpeg.
//   node scripts/compose-music.mjs <outDir>
import { Buffer } from 'node:buffer';
import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const RATE = 44_100;
const outDir = process.argv[2];
if (!outDir) throw new Error('usage: compose-music <outDir>');
mkdirSync(outDir, { recursive: true });

const NOTE = { C: 0, D: 2, E: 4, F: 5, G: 7, A: 9, B: 11 };
/** "F#4" → Hz. */
function hz(name) {
  const m = /^([A-G])([#b]?)(\d)$/.exec(name);
  const semis = NOTE[m[1]] + (m[2] === '#' ? 1 : m[2] === 'b' ? -1 : 0) + (Number(m[3]) + 1) * 12;
  return 440 * 2 ** ((semis - 69) / 12);
}

/** A tiny deterministic random, so every run gives the same file. */
let seed = 7;
const rand = () => ((seed = (seed * 1_103_515_245 + 12_345) % 2 ** 31) / 2 ** 31) * 2 - 1;

function track(seconds) {
  const n = Math.ceil(seconds * RATE);
  return { l: new Float32Array(n), r: new Float32Array(n), n };
}

/**
 * One note: a sum of decaying partials (music box / soft pluck / pad), panned.
 * `partials`: [ratio, gain, decay seconds].
 */
function note(t, at, name, len, gain, partials, { attack = 0.004, pan = 0, release = 0.08 } = {}) {
  const f = hz(name);
  const start = Math.floor(at * RATE);
  const total = Math.floor((len + Math.max(...partials.map((p) => p[2])) * 0.6) * RATE);
  const lg = gain * Math.cos(((pan + 1) * Math.PI) / 4);
  const rg = gain * Math.sin(((pan + 1) * Math.PI) / 4);
  for (let i = 0; i < total && start + i < t.n; i++) {
    const s = i / RATE;
    let v = 0;
    for (const [ratio, g, decay] of partials) {
      v += g * Math.exp(-s / decay) * Math.sin(2 * Math.PI * f * ratio * s);
    }
    const env = Math.min(1, s / attack) * (s > len ? Math.exp(-(s - len) / release) : 1);
    t.l[start + i] += v * env * lg;
    t.r[start + i] += v * env * rg;
  }
}

/** Soft room: two cross-fed delays. */
function room(t, mix = 0.22) {
  const a = Math.floor(0.137 * RATE);
  const b = Math.floor(0.211 * RATE);
  for (let i = 0; i < t.n; i++) {
    if (i >= a) t.l[i] += t.r[i - a] * mix;
    if (i >= b) t.r[i] += t.l[i - b] * mix;
  }
}

function writeWav(file, t, fadeOut = 3) {
  let peak = 0;
  for (let i = 0; i < t.n; i++) peak = Math.max(peak, Math.abs(t.l[i]), Math.abs(t.r[i]));
  const scale = 0.8 / (peak || 1);
  const data = Buffer.alloc(t.n * 4);
  for (let i = 0; i < t.n; i++) {
    const s = i / RATE;
    const env = Math.min(1, s / 0.5, (t.n / RATE - s) / fadeOut);
    data.writeInt16LE(Math.round(Math.tanh(t.l[i] * scale * env) * 32_000), i * 4);
    data.writeInt16LE(Math.round(Math.tanh(t.r[i] * scale * env) * 32_000), i * 4 + 2);
  }
  const head = Buffer.alloc(44);
  head.write('RIFF', 0);
  head.writeUInt32LE(36 + data.length, 4);
  head.write('WAVEfmt ', 8);
  head.writeUInt32LE(16, 16);
  head.writeUInt16LE(1, 20);
  head.writeUInt16LE(2, 22);
  head.writeUInt32LE(RATE, 24);
  head.writeUInt32LE(RATE * 4, 28);
  head.writeUInt16LE(4, 32);
  head.writeUInt16LE(16, 34);
  head.write('data', 36);
  head.writeUInt32LE(data.length, 40);
  writeFileSync(file, Buffer.concat([head, data]));
}

const musicBox = [
  [1, 1, 1.1],
  [2, 0.35, 0.5],
  [3, 0.12, 0.3],
  [5.4, 0.05, 0.12],
];
const pad = [
  [1, 1, 3],
  [2, 0.25, 2],
];
const pluck = [
  [1, 1, 0.55],
  [2, 0.5, 0.3],
  [3, 0.25, 0.18],
  [4, 0.12, 0.1],
];
const bassTone = [
  [1, 1, 0.9],
  [2, 0.2, 0.4],
];

// ---- "Ru êm" (gentle): F major, 3/4, 66 bpm, music box over a soft pad. ----
function lullaby() {
  const beat = 60 / 66;
  const bar = 3 * beat;
  const t = track(75);
  const chords = {
    F: ['F3', 'A3', 'C4'],
    Dm: ['D3', 'F3', 'A3'],
    Bb: ['Bb2', 'D3', 'F3'],
    C: ['C3', 'E3', 'G3'],
    Gm: ['G2', 'Bb2', 'D3'],
  };
  // [chord, [[note, beats], …]] per bar.
  const a = [
    [
      'F',
      [
        ['C5', 2],
        ['A4', 1],
      ],
    ],
    [
      'Dm',
      [
        ['D5', 2],
        ['C5', 1],
      ],
    ],
    [
      'Bb',
      [
        ['Bb4', 1],
        ['A4', 1],
        ['G4', 1],
      ],
    ],
    ['C', [['G4', 3]]],
    [
      'F',
      [
        ['C5', 2],
        ['A4', 1],
      ],
    ],
    [
      'Dm',
      [
        ['F5', 2],
        ['E5', 1],
      ],
    ],
    [
      'Gm',
      [
        ['D5', 1],
        ['C5', 1],
        ['Bb4', 1],
      ],
    ],
    ['F', [['A4', 3]]],
  ];
  const b = [
    [
      'Bb',
      [
        ['D5', 2],
        ['F5', 1],
      ],
    ],
    [
      'F',
      [
        ['C5', 2],
        ['A4', 1],
      ],
    ],
    [
      'Gm',
      [
        ['Bb4', 1],
        ['A4', 1],
        ['G4', 1],
      ],
    ],
    [
      'C',
      [
        ['C5', 2],
        ['G4', 1],
      ],
    ],
    [
      'Bb',
      [
        ['D5', 2],
        ['C5', 1],
      ],
    ],
    [
      'F',
      [
        ['A4', 2],
        ['C5', 1],
      ],
    ],
    [
      'C',
      [
        ['G4', 1],
        ['A4', 1],
        ['E4', 1],
      ],
    ],
    ['F', [['F4', 3]]],
  ];
  const up = (bars) =>
    bars.map(([c, ns]) => [c, ns.map(([n, d]) => [n.replace(/\d/, (o) => String(+o + 1)), d])]);
  const song = [...a, ...b, ...a, ...up(b.slice(0, 7)), ['F', [['F5', 3]]], ['F', []]];
  song.forEach(([chord, notes], i) => {
    const at = 0.6 + i * bar;
    if (at > 74) return;
    chords[chord].forEach((n, k) =>
      note(t, at, n, bar * 0.95, 0.07, pad, { attack: 0.6, release: 0.8, pan: k - 1 }),
    );
    note(
      t,
      at,
      chords[chord][0].replace(/\d/, (o) => String(+o - 1)),
      bar * 0.9,
      0.12,
      bassTone,
    );
    let x = at;
    for (const [n, d] of notes) {
      note(t, x, n, d * beat, 0.22, musicBox, { pan: 0.15 });
      // A quiet echo an octave up, like a second comb on the cylinder.
      note(
        t,
        x + 0.012,
        n.replace(/\d/, (o) => String(+o + 1)),
        d * beat * 0.5,
        0.04,
        musicBox,
        {
          pan: -0.3,
        },
      );
      x += d * beat;
    }
  });
  room(t, 0.28);
  return t;
}

// ---- "Nắng mai" (happy): G major, 4/4, 100 bpm, plucks, a walking bass and a light shaker. ----
function morning() {
  const beat = 60 / 100;
  const bar = 4 * beat;
  const t = track(75);
  const prog = ['G', 'D', 'Em', 'C'];
  const chords = {
    G: ['G3', 'B3', 'D4'],
    D: ['D3', 'F#3', 'A3'],
    Em: ['E3', 'G3', 'B3'],
    C: ['C3', 'E3', 'G3'],
  };
  const roots = { G: 'G2', D: 'D2', Em: 'E2', C: 'C2' };
  const phrase = [
    [
      ['B4', 0.5],
      ['D5', 0.5],
      ['G5', 1],
      ['D5', 1],
      ['B4', 1],
    ],
    [
      ['A4', 0.5],
      ['D5', 0.5],
      ['F#5', 1],
      ['E5', 1],
      ['D5', 1],
    ],
    [
      ['G5', 1],
      ['E5', 0.5],
      ['D5', 0.5],
      ['B4', 1],
      ['G4', 1],
    ],
    [
      ['E5', 1.5],
      ['D5', 0.5],
      ['C5', 1],
      ['A4', 1],
    ],
    [
      ['B4', 0.5],
      ['D5', 0.5],
      ['G5', 1],
      ['A5', 1],
      ['G5', 1],
    ],
    [
      ['F#5', 1],
      ['E5', 0.5],
      ['D5', 0.5],
      ['A4', 2],
    ],
    [
      ['B4', 1],
      ['E5', 1],
      ['G5', 1],
      ['E5', 1],
    ],
    [
      ['E5', 1],
      ['D5', 0.5],
      ['C5', 0.5],
      ['G4', 2],
    ],
  ];
  const bars = Math.floor(73 / bar);
  for (let i = 0; i < bars; i++) {
    const at = 0.4 + i * bar;
    const c = i === bars - 1 ? 'G' : prog[i % 4];
    // Strummed chord on 1 and 3, a pluck on the off-beats.
    for (const off of [0, 2]) {
      chords[c].forEach((n, k) =>
        note(t, at + off * beat + k * 0.018, n, beat * 1.6, 0.07, pluck, { pan: (k - 1) * 0.5 }),
      );
    }
    for (const off of [1.5, 3.5])
      note(t, at + off * beat, chords[c][2], beat * 0.4, 0.05, pluck, { pan: 0.4 });
    note(t, at, roots[c], beat * 1.8, 0.2, bassTone);
    note(t, at + 2 * beat, roots[c].replace('2', '3'), beat * 1.6, 0.13, bassTone);
    // Shaker: short noise on every eighth after the intro bars.
    if (i >= 2) {
      for (let e = 0; e < 8; e++) {
        const s0 = Math.floor((at + e * beat * 0.5) * RATE);
        const g = e % 2 ? 0.035 : 0.02;
        for (let k = 0; k < 2200 && s0 + k < t.n; k++) {
          const v = rand() * g * Math.exp(-k / 500);
          t.l[s0 + k] += v * 0.8;
          t.r[s0 + k] += v;
        }
      }
    }
    // The tune enters after two bars and rests for the last one.
    if (i >= 2 && i < bars - 1) {
      let x = at;
      for (const [n, d] of phrase[(i - 2) % 8]) {
        note(t, x, n, d * beat * 0.9, 0.2, pluck, { pan: -0.1 });
        x += d * beat;
      }
    } else if (i === bars - 1) {
      note(t, at, 'G5', bar, 0.18, pluck);
    }
  }
  room(t, 0.18);
  return t;
}

const piano = [
  [1, 1, 1.6],
  [2, 0.45, 0.9],
  [3, 0.18, 0.5],
  [4, 0.08, 0.3],
  [5.02, 0.04, 0.2],
];
const bell = [
  [1, 1, 0.9],
  [2.76, 0.4, 0.4],
  [5.4, 0.15, 0.2],
];
const padTone = [
  [1, 1, 4],
  [2, 0.3, 3],
  [3, 0.1, 2],
];

// ---- "Bình minh" (emotional): felt piano, D major, 70 bpm, broken chords + a simple melody. ----
function pianoDawn() {
  const beat = 60 / 70;
  const bar = 4 * beat;
  const t = track(80);
  const chords = {
    D: ['D3', 'A3', 'D4', 'F#4'],
    A: ['A2', 'E3', 'A3', 'C#4'],
    Bm: ['B2', 'F#3', 'B3', 'D4'],
    G: ['G2', 'D3', 'G3', 'B3'],
    Em: ['E3', 'B3', 'E4', 'G4'],
  };
  const prog = ['D', 'A', 'Bm', 'G', 'D', 'A', 'G', 'A', 'Bm', 'G', 'D', 'A', 'Em', 'G', 'A', 'D'];
  const melody = [
    [
      ['F#5', 2],
      ['E5', 1],
      ['D5', 1],
    ],
    [
      ['E5', 3],
      ['C#5', 1],
    ],
    [
      ['D5', 2],
      ['B4', 2],
    ],
    [
      ['D5', 1],
      ['E5', 1],
      ['G5', 2],
    ],
    [
      ['F#5', 2],
      ['A5', 2],
    ],
    [
      ['G5', 1],
      ['F#5', 1],
      ['E5', 2],
    ],
    [
      ['D5', 2],
      ['B4', 1],
      ['D5', 1],
    ],
    [['E5', 4]],
  ];
  const bars = Math.floor(78 / bar);
  for (let i = 0; i < bars; i++) {
    const at = 0.5 + i * bar;
    const c = chords[i === bars - 1 ? 'D' : prog[i % prog.length]];
    // Left hand: eighth-note arpeggio up and back.
    const order = [0, 1, 2, 3, 2, 1, 2, 3];
    order.forEach((k, e) =>
      note(t, at + e * beat * 0.5, c[k], beat * 0.9, 0.07 + (e === 0 ? 0.04 : 0), piano, {
        pan: -0.25 + k * 0.12,
      }),
    );
    if (i >= 2 && i < bars - 1) {
      let x = at;
      for (const [n, d] of melody[(i - 2) % melody.length]) {
        note(t, x, n, d * beat * 0.95, 0.16, piano, { pan: 0.15 });
        x += d * beat;
      }
    }
    if (i === bars - 1) note(t, at, 'D5', bar, 0.15, piano);
  }
  room(t, 0.3);
  return t;
}

// ---- "Mơ màng" (dreamy): slow pads and bells, F lydian colour, 60 bpm. ----
function dreamyNight() {
  const beat = 1;
  const bar = 4 * beat;
  const t = track(80);
  const chords = [
    ['F3', 'A3', 'C4', 'E4'],
    ['G3', 'B3', 'D4', 'F#4'],
    ['D3', 'F3', 'A3', 'C4'],
    ['C3', 'E3', 'G3', 'B3'],
  ];
  const bells = ['C6', 'A5', 'E6', 'G5', 'B5', 'D6', 'F#5', 'C6'];
  const bars = Math.floor(78 / bar);
  for (let i = 0; i < bars; i++) {
    const at = 0.4 + i * bar;
    chords[i % 4].forEach((n, k) =>
      note(t, at, n, bar * 1.05, 0.06, padTone, {
        attack: 1.2,
        release: 1.5,
        pan: (k - 1.5) * 0.4,
      }),
    );
    note(
      t,
      at,
      chords[i % 4][0].replace(/\d/, (o) => String(+o - 1)),
      bar,
      0.1,
      bassTone,
      {
        attack: 0.4,
      },
    );
    if (i >= 1 && i < bars - 1) {
      for (let b = 0; b < 3; b++) {
        const n = bells[(i * 3 + b) % bells.length];
        note(t, at + b * 1.33 + 0.2, n, 0.6, 0.07, bell, { pan: b % 2 ? 0.5 : -0.5 });
      }
    }
  }
  room(t, 0.4);
  return t;
}

// ---- "Tiệc vui" (festive): glockenspiel tune, plucked bass, soft kick and claps, 118 bpm. ----
function party() {
  const beat = 60 / 118;
  const bar = 4 * beat;
  const t = track(80);
  const prog = ['C', 'G', 'Am', 'F'];
  const roots = { C: 'C2', G: 'G2', Am: 'A2', F: 'F2' };
  const chords = {
    C: ['C4', 'E4', 'G4'],
    G: ['G3', 'B3', 'D4'],
    Am: ['A3', 'C4', 'E4'],
    F: ['F3', 'A3', 'C4'],
  };
  const tune = [
    [
      ['E5', 0.5],
      ['G5', 0.5],
      ['C6', 1],
      ['G5', 1],
      ['E5', 1],
    ],
    [
      ['D5', 0.5],
      ['G5', 0.5],
      ['B5', 1],
      ['A5', 1],
      ['G5', 1],
    ],
    [
      ['C6', 1],
      ['A5', 0.5],
      ['G5', 0.5],
      ['E5', 1],
      ['C5', 1],
    ],
    [
      ['F5', 1],
      ['A5', 1],
      ['G5', 1],
      ['E5', 1],
    ],
  ];
  const bars = Math.floor(78 / bar);
  for (let i = 0; i < bars; i++) {
    const at = 0.3 + i * bar;
    const c = i === bars - 1 ? 'C' : prog[i % 4];
    for (const off of [0, 1, 2, 3]) {
      // Kick on 1 and 3: a short falling sine.
      if (off % 2 === 0) {
        const s0 = Math.floor((at + off * beat) * RATE);
        for (let k = 0; k < 6000 && s0 + k < t.n; k++) {
          const s = k / RATE;
          const v =
            0.35 *
            Math.exp(-s / 0.09) *
            Math.sin(2 * Math.PI * (55 + 90 * Math.exp(-s / 0.03)) * s);
          t.l[s0 + k] += v;
          t.r[s0 + k] += v;
        }
      } else if (i >= 2) {
        // Clap on 2 and 4: filtered noise burst.
        const s0 = Math.floor((at + off * beat) * RATE);
        let last = 0;
        for (let k = 0; k < 5000 && s0 + k < t.n; k++) {
          last = last * 0.6 + rand() * 0.4;
          const v = last * 0.12 * Math.exp(-k / 1400);
          t.l[s0 + k] += v * 0.9;
          t.r[s0 + k] += v;
        }
      }
      chords[c].forEach((n, k) =>
        note(t, at + off * beat + 0.25 * beat, n, beat * 0.35, 0.035, pluck, {
          pan: (k - 1) * 0.6,
        }),
      );
    }
    note(t, at, roots[c], beat * 1.6, 0.22, bassTone);
    note(t, at + 2 * beat, roots[c], beat * 1.4, 0.16, bassTone);
    if (i >= 2 && i < bars - 1) {
      let x = at;
      for (const [n, d] of tune[i % 4]) {
        note(t, x, n, d * beat * 0.8, 0.12, bell, { pan: 0.2 });
        x += d * beat;
      }
    } else if (i === bars - 1) {
      note(t, at, 'C6', bar, 0.14, bell);
    }
  }
  room(t, 0.2);
  return t;
}

writeWav(join(outDir, 'binh-minh.wav'), pianoDawn());
writeWav(join(outDir, 'mo-mang.wav'), dreamyNight());
writeWav(join(outDir, 'tiec-vui.wav'), party());
writeWav(join(outDir, 'ru-em.wav'), lullaby());
writeWav(join(outDir, 'nang-mai.wav'), morning());
console.log('written', outDir);
