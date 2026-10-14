import type { KeepsakeComposition } from '@child-life/contracts';
import type { ComponentType } from 'react';
import type { StoryProps } from '../kit/core';
import { Chapter1Story, chapter1, chapter1Frames, chapter1Poster } from './chapter1';
import {
  FPS,
  MemoryStory,
  posterFrame,
  type MemoryStoryProps,
  type StoryStyle,
} from './MemoryStory';

/**
 * Every composition a video template may name (`keepsakeCompositions`, D-068 #7): how to draw it,
 * how long it is for given props, and its poster frame. Root, the renderer and the preview player
 * all read this, so a new composition is one entry here (and a renderer deploy).
 */
export interface StoryEntry {
  Component: ComponentType<StoryProps>;
  frames: (p: StoryProps) => number;
  poster: (p: StoryProps) => number;
}

const v1 = (style: StoryStyle): StoryEntry => ({
  Component: (p) => <MemoryStory {...(p as MemoryStoryProps)} style={style} />,
  frames: (p) => Math.round(p.durationSec * FPS),
  poster: (p) => posterFrame(p.durationSec, p.photos.length),
});

const ch1 = (id: string): StoryEntry => ({
  Component: (p) => <Chapter1Story {...p} composition={id} />,
  frames: (p) => chapter1Frames(id, p),
  poster: (p) => chapter1Poster(id, p),
});

export const stories: Record<KeepsakeComposition, StoryEntry> = {
  FirstMonth: v1('polaroid'),
  FirstWeek: v1('fullBleed'),
  HundredDays: v1('polaroid'),
  LittleMoments: v1('fullBleed'),
  ...(Object.fromEntries(Object.keys(chapter1).map((id) => [id, ch1(id)])) as Record<
    Exclude<KeepsakeComposition, 'FirstMonth' | 'FirstWeek' | 'HundredDays' | 'LittleMoments'>,
    StoryEntry
  >),
};

/** The entry for a template's composition (unknown names fall back to LittleMoments). */
export const storyOf = (id: string | null | undefined): StoryEntry =>
  stories[(id ?? '') as KeepsakeComposition] ?? stories.LittleMoments;
