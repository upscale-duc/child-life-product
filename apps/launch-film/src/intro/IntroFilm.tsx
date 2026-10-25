import React, { useEffect, useState } from 'react';
import { AbsoluteFill, continueRender, delayRender, Sequence, useCurrentFrame } from 'remotion';
import { Fonts } from '../shared';
import { choreo } from './choreo';
import {
  colors,
  enter,
  FigmaLayer,
  gentle,
  hasAsset,
  imageLayerNames,
  layerIn,
  layerTrack,
  lerp,
  poseAt,
  SceneText,
  type LayerState,
  type Pose,
} from './engine';
import { Extras } from './Extras';
import { Thread } from './Thread';
import { IntroAudio } from './audio/IntroAudio';
import { films, type Film, type Lang, type Scene } from './timeline';

const filmOf = (scene: Scene) => films[scene.lang];
const prevOf = (scene: Scene) => {
  const { scenes } = filmOf(scene);
  return scenes[scenes.indexOf(scene) - 1];
};
const bridgeSource = (scene: Scene, name: string): LayerState | undefined => {
  const prev = prevOf(scene);
  if (!prev) return undefined;
  const from = layerIn(prev, 'END', name);
  const to = layerIn(scene, 'START', name);
  return from && to && from.opacity > 0.05 && to.opacity > 0.05 && hasAsset(scene.id, name) ? from : undefined;
};

export const poseFor = (scene: Scene, name: string, frame: number): Pose => {
  const c = choreo(scene);
  const names = imageLayerNames(scene);
  const i = names.indexOf(name);
  const cue = c.layers[name] ?? {};
  const bridge = bridgeSource(scene, name);
  const pose = poseAt(
    scene,
    name,
    frame,
    {
      ...cue,
      in: cue.in ?? c.in + i * c.stagger,
      inDur: cue.inDur ?? 26,
      out: cue.out ?? c.out + i * c.stagger,
      outDur: cue.outDur ?? 30,
    },
    bridge,
  );
  // A layer already on screen at START of a later scene fades in over the cut (unless it moved across).
  if (!bridge && prevOf(scene) && (layerIn(scene, 'START', name)?.opacity ?? 0) > 0.05) {
    const g = gentle(frame, 2, 16);
    return { ...pose, opacity: pose.opacity * g, scale: pose.scale * lerp(0.97, 1, g) };
  }
  return pose;
};

const Sun: React.FC<{ scene: Scene; frame: number }> = ({ scene, frame }) => (
  <>
    {(['Accent/SunHalo', 'Accent/Sun'] as const).map((name) => {
      if (!layerTrack(scene, name).raw.some(Boolean)) return null;
      const p = poseFor(scene, name, frame);
      if (p.opacity <= 0) return null;
      const halo = name === 'Accent/SunHalo';
      const breathe = 1 + 0.015 * Math.sin(frame / 24);
      return (
        <div
          key={name}
          style={{
            position: 'absolute',
            left: p.x,
            top: p.y + p.ty * 0,
            width: p.w,
            height: p.h,
            borderRadius: '50%',
            opacity: p.opacity,
            transform: `scale(${halo ? breathe * 1.02 : 1})`,
            background: halo
              ? `radial-gradient(circle, ${colors.sun}73 0%, ${colors.sun}33 45%, ${colors.sun}00 70%)`
              : `radial-gradient(circle at 40% 38%, #FFE08F 0%, ${colors.sun} 62%)`,
          }}
        />
      );
    })}
  </>
);

export const SceneLayers: React.FC<{ scene: Scene; frame: number; exclude?: string[]; ghost?: boolean }> = ({
  scene,
  frame,
  exclude = [],
  ghost,
}) => {
  const c = choreo(scene);
  const names = imageLayerNames(scene).filter((n) => !exclude.includes(n));
  return (
    <AbsoluteFill>
      <Sun scene={scene} frame={frame} />
      {names.map((name, i) => {
        const pose = poseFor(scene, name, frame);
        const flip = c.layers[name]?.flip;
        const z = c.layers[name]?.z ?? i;
        if (flip) {
          // Card flip: rotateY 90→0 with the entrance (thick-paper SFX on the same frame).
          const p = enter(frame, c.layers[name]!.in!, 34);
          return (
            <div key={name} style={{ position: 'absolute', inset: 0, zIndex: z, perspective: 1600, transformStyle: 'preserve-3d' }}>
              <div style={{ position: 'absolute', inset: 0, transform: `rotateY(${lerp(88, 0, p)}deg)`, transformOrigin: `${pose.x + pose.w / 2}px ${pose.y + pose.h / 2}px` }}>
                <FigmaLayer scene={scene} name={name} pose={{ ...pose, opacity: pose.opacity * Math.min(1, p * 3) }} />
              </div>
            </div>
          );
        }
        return (
          <FigmaLayer key={name} scene={scene} name={name} pose={pose} z={z}>
            {ghost ? null : <Extras scene={scene} name={name} frame={frame} pose={pose} />}
          </FigmaLayer>
        );
      })}
      <div style={{ position: 'absolute', inset: 0, zIndex: 50 }}>
        {c.texts.map((t) => (
          <SceneText key={`${t.name}-${t.text}`} scene={scene} cue={t} frame={frame} />
        ))}
      </div>
    </AbsoluteFill>
  );
};

/** Render the film only once the brand font is usable, so copy-fitting measures real glyphs. */
const FontGate: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  // fonts.check() is true for an unregistered family, so look for the loaded faces themselves.
  const ready = () =>
    typeof document !== 'undefined' &&
    ['500', '600'].every((w) => [...document.fonts].some((f) => f.family.replace(/"/g, '') === 'ChildLife' && f.weight === w && f.status === 'loaded'));
  const [ok, setOk] = useState(ready);
  const [handle] = useState(() => (ready() ? null : delayRender('Brand font for copy-fitting')));
  useEffect(() => {
    if (ok) return;
    const id = setInterval(() => {
      if (ready()) {
        clearInterval(id);
        setOk(true);
        if (handle !== null) continueRender(handle);
      }
    }, 20);
    return () => clearInterval(id);
  }, [ok, handle]);
  return ok ? <>{children}</> : null;
};

const GHOST = 14;
const SceneView: React.FC<{ scene: Scene }> = ({ scene }) => {
  const frame = useCurrentFrame();
  const prev = prevOf(scene);
  // The previous END dissolves over the cut (layers that continue are moved, not dissolved).
  const ghost = prev && frame < GHOST;
  const bridged = prev ? imageLayerNames(scene).filter((n) => bridgeSource(scene, n)) : [];
  const g = gentle(frame, 0, GHOST);
  return (
    <AbsoluteFill>
      {ghost ? (
        <AbsoluteFill style={{ opacity: 1 - g, transform: `scale(${lerp(1, 0.985, g)})`, filter: `blur(${lerp(0, 3, g)}px)` }}>
          <SceneLayers scene={prev} frame={prev.duration - 1} exclude={bridged} ghost />
        </AbsoluteFill>
      ) : null}
      <SceneLayers scene={scene} frame={frame} />
    </AbsoluteFill>
  );
};

export const IntroFilm: React.FC<{ lang: Lang; muted?: boolean }> = ({ lang, muted }) => {
  const frame = useCurrentFrame();
  const film = films[lang];
  return (
    <AbsoluteFill style={{ background: colors.cloud, overflow: 'hidden' }}>
      <Fonts />
      <FontGate>
        <Thread film={film} frame={frame} />
        {film.scenes.map((s) => (
          <Sequence key={s.id} name={`${s.id} · ${s.slug}`} from={s.from} durationInFrames={s.duration}>
            <SceneView scene={s} />
          </Sequence>
        ))}
      </FontGate>
      {muted ? null : <IntroAudio film={film} />}
    </AbsoluteFill>
  );
};

/** Single-scene preview with the film's own audio slice. */
export const IntroScene: React.FC<{ id: string; lang: Lang }> = ({ id, lang }) => {
  const film: Film = films[lang];
  const scene = film.scenes.find((s) => s.id === id)!;
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill style={{ background: colors.cloud, overflow: 'hidden' }}>
      <Fonts />
      <FontGate>
        <Thread film={film} frame={scene.from + frame} />
        <SceneView scene={scene} />
      </FontGate>
      <IntroAudio film={film} offset={scene.from} />
    </AbsoluteFill>
  );
};
