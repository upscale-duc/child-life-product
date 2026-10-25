import source from '../design/v2/figma-design.json';
import type { SceneId } from './timeline';
export type Layer = {
  id: string;
  assetKey?: string;
  alternateAssetKey?: string;
  alternateMix?: number;
  color?: { r: number; g: number; b: number; a?: number };
  children?: Layer[];
  gradient?: { position: number; color: { r: number; g: number; b: number; a?: number } }[];
  textEnter?: number;
  siriAnswer?: boolean;
  name: string;
  x: number;
  y: number;
  w: number;
  h: number;
  opacity: number;
  rotation: number;
  cornerRadius?: number;
  characters?: string;
  fontSize?: number;
  fontName?: { family: string; style: string };
  lineHeight?: { unit: string; value?: number };
  letterSpacing?: { unit: string; value: number };
  textAlignHorizontal?: string;
};
export type State = 'START' | 'MID' | 'HERO' | 'END' | 'HERO_9x16' | 'HERO_DARK';
export function frameState(id: SceneId, state: State): Layer[] {
  return (source.frames.find((f) => f.name.startsWith(id + '_') && f.name.endsWith('_' + state))
    ?.layers ?? []) as Layer[];
}
// Copy stays separate from motion. This is the Figma text, including intended line breaks.
export const copy = Object.fromEntries(
  source.frames.map((f) => [
    f.name,
    Object.fromEntries(
      f.layers.filter((l) => 'characters' in l).map((l) => [l.name, (l as Layer).characters]),
    ),
  ]),
);

export const cssColor = (c?: Layer['color']) =>
  c
    ? `rgb(${Math.round(c.r * 255)} ${Math.round(c.g * 255)} ${Math.round(c.b * 255)} / ${c.a ?? 1})`
    : undefined;
