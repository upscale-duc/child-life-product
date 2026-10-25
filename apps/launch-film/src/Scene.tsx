import React from 'react';
import { AbsoluteFill, useCurrentFrame, useVideoConfig } from 'remotion';
import { sceneLayers } from './animation';
import { LayerView } from './shared';
import { useBrand, useTheme } from './theme';
import type { SceneId } from './timeline';
// Bridge elements use one persistent React layer tree above the Series in the full film.
export const isBridge = (name: string) =>
  name === 'Accent/Band' ||
  name === 'Accent/Sun' ||
  name === 'Accent/Lumi' ||
  name.startsWith('AppScreen/') ||
  name.startsWith('Photo/MeVaBe');
export const Scene: React.FC<{ id: SceneId; inFilm?: boolean }> = ({ id, inFilm = false }) => {
  const f = useCurrentFrame();
  const brand = useBrand(),
    theme = useTheme();
  const { width } = useVideoConfig();
  return (
    <AbsoluteFill style={{ background: inFilm ? 'transparent' : brand.cloud, zIndex: 1 }}>
      {sceneLayers(id, f, width === 1080, theme)
        .filter((l) => !inFilm || (!isBridge(l.name) && l.name !== 'Background'))
        .map((l) => (
          <LayerView key={l.name} layer={l} frame={f} />
        ))}
    </AbsoluteFill>
  );
};
