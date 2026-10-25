// Layer engine for the Product Introduction: interpolates the Figma START / HERO / END
// states of each named layer (same name = same element) on per-layer cues from choreo.ts.
import React from 'react';
import { Easing, Img, interpolate, spring, staticFile } from 'remotion';
import layersJson from './layers.json';
import { hasViCard, tr, ViCard } from './i18n';
import type { Scene } from './timeline';

export const FPS = 30;
export const colors = {
  cloud: '#F6FCFB',
  ink: '#173D44',
  muted: '#55707A',
  mint: '#2CBFB3',
  mintDeep: '#087F7B',
  mintText: '#06716D',
  sun: '#FFD166',
  surface: '#FFFFFF',
};
export const FONT = 'ChildLife';

export type LayerState = {
  name: string;
  x: number;
  y: number;
  w: number;
  h: number;
  opacity: number;
  rotation: number;
  text?: string;
};
type StateName = 'START' | 'HERO' | 'END';

// ---------- easing ----------
const clamp = { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' } as const;
/** Element entering: film.spring.soft {120, 20, 1}. */
export const enter = (frame: number, at: number, dur = 26) =>
  spring({ frame: frame - at, fps: FPS, config: { stiffness: 120, damping: 20, mass: 1 }, durationInFrames: dur });
/** Camera-like repositioning: symmetric ease. */
export const move = (frame: number, at: number, dur = 30) =>
  interpolate(frame, [at, at + dur], [0, 1], { ...clamp, easing: Easing.bezier(0.65, 0, 0.35, 1) });
/** Text in: 18f bezier(0.3,0,0,1). */
export const gentle = (frame: number, at: number, dur = 18) =>
  interpolate(frame, [at, at + dur], [0, 1], { ...clamp, easing: Easing.bezier(0.3, 0, 0, 1) });
/** Exit: 8f bezier(0.4,0,1,1). */
export const exit = (frame: number, at: number, dur = 8) =>
  interpolate(frame, [at, at + dur], [0, 1], { ...clamp, easing: Easing.bezier(0.4, 0, 1, 1) });
export const lerp = (a: number, b: number, t: number) => a + (b - a) * t;

// ---------- state lookup ----------
export const states = (scene: Scene) => {
  const by = (s: StateName) => scene.keyframes.find((k) => k.state === s)!;
  return { START: by('START'), HERO: by('HERO'), END: by('END') };
};
export const layerIn = (scene: Scene, state: StateName, name: string): LayerState | undefined =>
  states(scene)[state].layers.find((l) => l.name === name && !('text' in l)) as LayerState | undefined;

/** Fill missing states with the nearest defined geometry at opacity 0, so pop-ins grow in place. */
export const layerTrack = (scene: Scene, name: string) => {
  const raw = (['START', 'HERO', 'END'] as const).map((s) => layerIn(scene, s, name));
  const filled = raw.map((l, i) => {
    if (l) return l;
    const near = raw[i === 0 ? 1 : i === 2 ? 1 : 0] ?? raw.find(Boolean)!;
    return { ...near, opacity: 0 };
  });
  return { S: filled[0], H: filled[1], E: filled[2], raw };
};

export const imageLayerNames = (scene: Scene) => {
  const names: string[] = [];
  for (const k of scene.keyframes)
    for (const l of k.layers)
      if (!('text' in l) && !l.name.startsWith('Accent/') && !names.includes(l.name)) names.push(l.name);
  for (const k of scene.keyframes)
    for (const l of k.layers) if (l.name === 'Accent/Lumi' && !names.includes(l.name)) names.push(l.name);
  return names;
};

// ---------- layer timing ----------
export type LayerCue = {
  /** START→HERO begins (local frame). */
  in?: number;
  inDur?: number;
  /** HERO→END begins. */
  out?: number;
  outDur?: number;
  ease?: 'spring' | 'move';
  /** Idle float amplitude in px (0 = still). */
  float?: number;
  z?: number;
};

export type Pose = {
  x: number;
  y: number;
  w: number;
  h: number;
  rotation: number;
  opacity: number;
  scale: number;
  ty: number;
};

const mix = (a: LayerState, b: LayerState, t: number): LayerState => ({
  ...a,
  x: lerp(a.x, b.x, t),
  y: lerp(a.y, b.y, t),
  w: lerp(a.w, b.w, t),
  h: lerp(a.h, b.h, t),
  rotation: lerp(a.rotation, b.rotation, t),
  opacity: lerp(a.opacity, b.opacity, t),
});

export const poseAt = (
  scene: Scene,
  name: string,
  frame: number,
  cue: Required<Pick<LayerCue, 'in' | 'inDur' | 'out' | 'outDur'>> & LayerCue,
  bridgeFrom?: LayerState,
): Pose => {
  const { S, H, E } = layerTrack(scene, name);
  const curve = cue.ease === 'move' ? move : enter;
  const p1 = curve(frame, cue.in, cue.inDur);
  const p2 = cue.ease === 'spring' ? enter(frame, cue.out, cue.outDur) : move(frame, cue.out, cue.outDur);
  // Opacity follows a gentler ramp than position so springs don't flash.
  // A long 'move' that ends invisible (converging into the logo) keeps its opacity until the last half.
  const o1 =
    cue.ease === 'move' && H.opacity < S.opacity
      ? gentle(frame, cue.in + cue.inDur * 0.5, cue.inDur * 0.5)
      : gentle(frame, cue.in, Math.min(cue.inDur, 16));
  const o2 = gentle(frame, cue.out, Math.min(cue.outDur, 16));
  let start = S;
  if (bridgeFrom) start = mix(bridgeFrom, S, move(frame, 0, 16));
  const g = {
    x: start.x + (H.x - S.x) * p1 + (E.x - H.x) * p2,
    y: start.y + (H.y - S.y) * p1 + (E.y - H.y) * p2,
    w: start.w + (H.w - S.w) * p1 + (E.w - H.w) * p2,
    h: start.h + (H.h - S.h) * p1 + (E.h - H.h) * p2,
    rotation: start.rotation + (H.rotation - S.rotation) * p1 + (E.rotation - H.rotation) * p2,
    opacity: start.opacity + (H.opacity - S.opacity) * o1 + (E.opacity - H.opacity) * o2,
  };
  // Pop: a layer that appears grows from .9 and rises 18px; one that leaves settles to .96.
  let scale = 1,
    ty = 0;
  if (S.opacity < 0.05 && H.opacity > 0.05 && !bridgeFrom) {
    scale *= lerp(0.9, 1, p1);
    ty += lerp(18, 0, Math.min(1, p1));
  }
  if (H.opacity < 0.05 && E.opacity > 0.05) {
    scale *= lerp(0.9, 1, p2);
    ty += lerp(18, 0, Math.min(1, p2));
  }
  if (H.opacity > 0.05 && E.opacity < 0.05) scale *= lerp(1, 0.96, o2);
  const amp = cue.float ?? 2.5;
  ty += amp * Math.sin((frame + name.length * 17) / 38);
  return { ...g, opacity: Math.max(0, Math.min(1, g.opacity)), scale, ty };
};

// ---------- Figma layer image ----------
type LayerAsset = { file: string; state: StateName; svgW: number; svgH: number; originX: number | null; originY: number | null };
const assets = layersJson as unknown as Record<string, LayerAsset>;
export const hasAsset = (sceneId: string, name: string) => Boolean(assets[`${sceneId}|${name}`]);

export const FigmaLayer: React.FC<{ scene: Scene; name: string; pose: Pose; z?: number; children?: React.ReactNode }> = ({
  scene,
  name,
  pose,
  z,
  children,
}) => {
  const a = assets[`${scene.id}|${name}`];
  if (!a || pose.opacity <= 0.002) return null;
  const ref = layerIn(scene, a.state, name)!;
  if (hasViCard(scene.lang, name)) {
    // Re-typeset card: centred in the node box, full Figma rotation, scaled like the export.
    const k = pose.w / ref.w;
    return (
      <div
        data-layer={name}
        style={{
          position: 'absolute',
          left: pose.x + pose.w / 2,
          top: pose.y + pose.h / 2,
          opacity: pose.opacity,
          zIndex: z,
          transform: `translate(-50%, -50%) translateY(${pose.ty}px) rotate(${-pose.rotation}deg) scale(${pose.scale * k})`,
        }}
      >
        <ViCard sceneId={scene.id} name={name} />
      </div>
    );
  }
  // The SVG export includes the drop shadow; keep the node box aligned to the state geometry.
  const padX = ref.x - (a.originX ?? ref.x - (a.svgW - ref.w) / 2);
  const padY = ref.y - (a.originY ?? ref.y - (a.svgH - ref.h) / 2);
  const sx = pose.w / ref.w,
    sy = pose.h / ref.h;
  const cx = pose.x + pose.w / 2,
    cy = pose.y + pose.h / 2;
  return (
    <div
      data-layer={name}
      style={{
        position: 'absolute',
        left: pose.x - padX * sx,
        top: pose.y - padY * sy,
        width: a.svgW * sx,
        height: a.svgH * sy,
        opacity: pose.opacity,
        zIndex: z,
        transformOrigin: `${cx - (pose.x - padX * sx)}px ${cy - (pose.y - padY * sy)}px`,
        // Figma rotation is counter-clockwise; CSS is clockwise.
        transform: `translateY(${pose.ty}px) rotate(${-(pose.rotation - ref.rotation)}deg) scale(${pose.scale})`,
        willChange: 'transform, opacity',
      }}
    >
      <Img src={staticFile(a.file)} style={{ width: '100%', height: '100%', display: 'block' }} />
      {children ? (
        <div style={{ position: 'absolute', left: padX * sx, top: padY * sy, width: pose.w, height: pose.h }}>{children}</div>
      ) : null}
    </div>
  );
};

// ---------- text ----------
export type TextCue = {
  name: string;
  text: string;
  at: number;
  out?: number;
  /** Extra words revealed later on the same line (e.g. "The next nap."). */
  reveal?: { from: number; text: string }[];
  color?: string;
  align?: 'left' | 'center';
  /** Longest allowed line in px; longer copy (e.g. Vietnamese) is set smaller to fit. */
  maxWidth?: number;
  /** Dim to this opacity at `dimAt` (Figma END keeps some headlines at .35/.5). */
  dimTo?: number;
  dimAt?: number;
};

export const textGeometry = (scene: Scene, name: string, text: string) => {
  const hits = scene.keyframes
    .map((k) => ({ k, l: k.layers.find((l) => l.name === name && 'text' in l && (l as LayerState).text === text) as LayerState | undefined }))
    .filter((h) => h.l);
  if (!hits.length) throw new Error(`${scene.id}: no text layer ${name} = ${text}`);
  return { first: hits[0].l!, hero: (hits.find((h) => h.k.state === 'HERO') ?? hits[0]).l!, all: hits.map((h) => h.l!) };
};

/** Widest line of `text` in px, measured in the DOM with the loaded brand font. */
const measured = new Map<string, number>();
const measure = (text: string, weight: number, size: number, tracking: number) => {
  const key = `${weight}|${size}|${tracking}|${text}`;
  const hit = measured.get(key);
  if (hit !== undefined) return hit;
  const el = document.createElement('span');
  Object.assign(el.style, { position: 'absolute', visibility: 'hidden', whiteSpace: 'pre', fontFamily: FONT, fontWeight: String(weight), fontSize: `${size}px`, letterSpacing: `${tracking}px` });
  el.textContent = text;
  document.body.appendChild(el);
  const w = el.offsetWidth;
  el.remove();
  measured.set(key, w);
  return w;
};

const typeFor = (name: string, l: LayerState) => {
  const lines = (l.text ?? '').split('\n').length;
  if (name === 'SupportingText') {
    const size = lines > 1 ? 30 : Math.round(l.h / 1.12);
    return { size, weight: 500, lineHeight: lines > 1 ? l.h / lines / size : 1.12, color: colors.muted, tracking: 0 };
  }
  const size = Math.round(l.h / lines / 1.12);
  return { size, weight: 600, lineHeight: 1.12, color: colors.ink, tracking: -0.015 * size };
};

export const SceneText: React.FC<{ scene: Scene; cue: TextCue; frame: number }> = ({ scene, cue, frame }) => {
  const { first, hero } = textGeometry(scene, cue.name, cue.text);
  const t = typeFor(cue.name, hero);
  const p = gentle(frame, cue.at, 18);
  const settle = enter(frame, cue.at, 30);
  const out = cue.out === undefined ? 0 : exit(frame, cue.out, 8);
  const dim = cue.dimTo === undefined ? 1 : lerp(1, cue.dimTo, gentle(frame, cue.dimAt ?? cue.out ?? 0, 16));
  const opacity = p * (1 - out) * dim;
  if (opacity <= 0.002) return null;
  const x = lerp(first.x, hero.x, settle),
    y = lerp(first.y, hero.y, settle);
  const size = lerp(typeFor(cue.name, first).size, t.size, settle);
  const baseEn = cue.reveal ? cue.text.slice(0, cue.text.length - cue.reveal.map((r) => r.text).join('').length) : cue.text;
  const base = tr(scene.lang, baseEn);
  const full = base + (cue.reveal?.map((r) => tr(scene.lang, r.text)).join('') ?? '');
  const room = cue.maxWidth ?? (cue.align === 'center' ? 1680 : 1920 - hero.x - 100);
  const fit = Math.min(1, room / measure(full, t.weight, t.size, t.tracking));
  return (
    <div
      data-layer={cue.name}
      style={{
        position: 'absolute',
        left: cue.align === 'center' ? x + hero.w / 2 : x,
        top: y,
        textAlign: cue.align ?? 'left',
        whiteSpace: 'pre',
        fontFamily: FONT,
        fontWeight: t.weight,
        fontSize: size * fit,
        lineHeight: t.lineHeight,
        letterSpacing: t.tracking * fit,
        color: cue.color ?? t.color,
        opacity,
        transform: `${cue.align === 'center' ? 'translateX(-50%) ' : ''}translateY(${lerp(24, 0, p) - 16 * out}px)`,
      }}
    >
      {base}
      {cue.reveal?.map((r) => {
        const q = gentle(frame, r.from, 18);
        return (
          <span key={r.text} style={{ opacity: q, display: 'inline-block', whiteSpace: 'pre', transform: `translateY(${lerp(18, 0, q)}px)` }}>
            {tr(scene.lang, r.text)}
          </span>
        );
      })}
    </div>
  );
};
