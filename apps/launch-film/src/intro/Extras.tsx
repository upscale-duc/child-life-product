// Small UI interactions drawn over the Figma layer, in its node box (HERO px): the widget tap,
// Siri's "Saved" confirmation, the Lumi glow and the video play pulse. Each matches one SFX cue.
import React from 'react';
import { choreo } from './choreo';
import { colors, enter, gentle, layerIn, lerp, type Pose } from './engine';
import type { Scene } from './timeline';

export const interactionFrames = (scene: Scene) => {
  const c = choreo(scene);
  return {
    widgetTap: (c.layers['UICrop/Widget']?.in ?? 0) + 30,
    siriSaved: (c.layers['Card/Siri']?.in ?? 0) + 34,
    lumi: (c.layers['Accent/Lumi']?.in ?? 0) + 6,
    videoReady: (c.layers['Card/VideoPreview']?.in ?? 0) + 20,
  };
};

export const Extras: React.FC<{ scene: Scene; name: string; frame: number; pose: Pose }> = ({ scene, name, frame, pose }) => {
  const f = interactionFrames(scene);
  const hero = layerIn(scene, 'HERO', name) ?? layerIn(scene, 'END', name);
  if (!hero) return null;
  const k = pose.w / hero.w; // node px → current px

  if (scene.id === 'PI06' && name === 'UICrop/Widget') {
    // "+" on the Bú bình tile (W1 Widget/Medium, cropped): centre ≈ (117, 107) in the 566×260 crop.
    const t = frame - f.widgetTap;
    if (t < -6 || t > 30) return null;
    const press = t < 0 ? gentle(frame, f.widgetTap - 6, 6) : 1 - gentle(frame, f.widgetTap, 10);
    const ring = gentle(frame, f.widgetTap, 22);
    return (
      <>
        <div style={dot(117 * k, 107 * k, 34 * k * (1 + 0.15 * press), `${colors.ink}${press > 0 ? '22' : '00'}`)} />
        <div
          style={{
            ...dot(117 * k, 107 * k, lerp(30, 120, ring) * k, 'transparent'),
            border: `${3 * k}px solid ${colors.mint}`,
            opacity: t >= 0 ? 1 - ring : 0,
          }}
        />
      </>
    );
  }
  if (scene.id === 'PI06' && name === 'Card/Siri') {
    // The command shows first; the confirmation row (y≈112–158 of 177) appears with the tick SFX.
    const show = enter(frame, f.siriSaved, 22);
    return (
      <div
        style={{
          position: 'absolute',
          left: 18 * k,
          top: 106 * k,
          width: (hero.w - 36) * k,
          height: 58 * k,
          background: colors.surface,
          borderRadius: 18 * k,
          opacity: 1 - show,
          transform: `translateY(${lerp(0, -6, show)}px)`,
        }}
      />
    );
  }
  if (scene.id === 'PI07' && name === 'Accent/Lumi') {
    const g = gentle(frame, f.lumi, 30);
    return (
      <div
        style={{
          ...dot(pose.w / 2, pose.h / 2, lerp(pose.w * 0.9, pose.w * 1.6, g), `${colors.mint}00`),
          border: `${4 * k}px solid ${colors.mint}`,
          opacity: (1 - g) * 0.6,
        }}
      />
    );
  }
  if (scene.id === 'PI09' && name === 'Card/VideoPreview') {
    // Play button "breathes" once the video is ready.
    const b = frame > f.videoReady ? 0.5 + 0.5 * Math.sin((frame - f.videoReady) / 9) : 0;
    return (
      <div
        style={{
          ...dot(pose.w / 2, pose.h * 0.42, (90 + 26 * b) * k, `rgba(255,255,255,${0.18 * b})`),
          boxShadow: `0 0 ${30 * b * k}px rgba(255,255,255,${0.35 * b})`,
        }}
      />
    );
  }
  return null;
};

const dot = (cx: number, cy: number, d: number, bg: string): React.CSSProperties => ({
  position: 'absolute',
  left: cx - d / 2,
  top: cy - d / 2,
  width: d,
  height: d,
  borderRadius: '50%',
  background: bg,
  pointerEvents: 'none',
});
