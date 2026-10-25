// Accent/Thread — the single mint motif. Rendered once above the scene series so it never cuts:
// it draws on (PI01), morphs between each scene's START/HERO/END threadPath, and bridges scene cuts.
import React from 'react';
import { getLength, interpolatePaths } from '@remotion/paths';
import { colors, gentle, move } from './engine';
import { choreo } from './choreo';
import type { Film, Scene } from './timeline';

const paths = (scene: Scene) => {
  const by = (s: string) => scene.keyframes.find((k) => k.state === s)!.threadPath as string;
  return { S: by('START'), H: by('HERO'), E: by('END') };
};
const opacityOf = (scene: Scene, state: string) =>
  (scene.keyframes.find((k) => k.state === state)!.layers.find((l) => l.name === 'Accent/Thread')?.opacity ?? 1) as number;

const morph = (t: number, a: string, b: string) => (t <= 0.001 ? a : t >= 0.999 ? b : interpolatePaths(t, [0, 1], [a, b]));

export const threadAt = (film: Film, global: number) => {
  const { scenes } = film;
  const i = Math.max(0, scenes.findIndex((s) => global >= s.from && global < s.from + s.duration));
  const scene = scenes[i] ?? scenes[scenes.length - 1];
  const frame = global - scene.from;
  const c = choreo(scene).thread;
  const { S, H, E } = paths(scene);
  const drawOn = H.startsWith(S) && H !== S;
  const p1 = move(frame, c.in, c.inDur);
  const p2 = move(frame, c.out, c.outDur);
  let d = drawOn ? H : morph(p1, S, H);
  let visible = 1;
  if (drawOn) {
    const ls = getLength(S),
      lh = getLength(H);
    visible = (ls + (lh - ls) * p1) / lh;
  }
  if (p2 > 0) {
    d = morph(p2, d, E);
    visible = visible + (1 - visible) * p2;
  }
  // Bridge from the previous scene's END path.
  const prev = scenes[i - 1];
  if (prev && frame < 18) d = morph(move(frame, 0, 18), paths(prev).E, d);
  const opacity =
    opacityOf(scene, 'START') +
    (opacityOf(scene, 'HERO') - opacityOf(scene, 'START')) * gentle(frame, c.in, 16) +
    (opacityOf(scene, 'END') - opacityOf(scene, 'HERO')) * gentle(frame, c.out, 16);
  return { d, visible, opacity: opacity * (c.opacity ?? 1) };
};

export const Thread: React.FC<{ film: Film; frame: number }> = ({ film, frame }) => {
  const { d, visible, opacity } = threadAt(film, frame);
  const length = visible < 0.999 ? getLength(d) : 0;
  return (
    <svg
      width={1920}
      height={1080}
      viewBox="0 0 1920 1080"
      style={{ position: 'absolute', inset: 0, overflow: 'visible', opacity }}
    >
      <path
        d={d}
        fill="none"
        stroke={colors.mint}
        strokeWidth={6}
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeDasharray={visible < 0.999 ? `${length} ${length}` : undefined}
        strokeDashoffset={visible < 0.999 ? length * (1 - visible) : undefined}
      />
    </svg>
  );
};
