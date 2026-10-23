import { Premium48Phase6Story } from './premium48-phase6';
import { Premium48FinalStory } from './premium48-final';
import { premium48FinalDesigns } from '@child-life/contracts';
import { Premium48Phase5Story } from './premium48-phase5';
import { Premium48Story, PREMIUM48_FRAMES, PREMIUM48_POSTER } from './premium48';
import { Premium48Phase4Story } from './premium48-phase4';
import { Premium48Phase3Story } from './premium48-phase3';
import { Premium48Phase2Story } from './premium48-phase2';
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
  ...(Object.fromEntries(
    premium48FinalDesigns.map((d) => [
      d.composition,
      {
        Component: (p: StoryProps) => <Premium48FinalStory {...p} number={d.n} />,
        frames: () => (d.n === 22 ? 1500 : 1050),
        poster: () => (d.n === 22 ? 1440 : 990),
      },
    ]),
  ) as unknown as Record<(typeof premium48FinalDesigns)[number]['composition'], StoryEntry>),
  PremiumYouDidIt: {
    Component: (p) => <Premium48Phase6Story {...p} />,
    frames: () => PREMIUM48_FRAMES,
    poster: () => PREMIUM48_POSTER,
  },
  PremiumWorldToDiscover: {
    Component: (p) => <Premium48Phase6Story {...p} discover />,
    frames: () => PREMIUM48_FRAMES,
    poster: () => PREMIUM48_POSTER,
  },
  PremiumOutgrownKeepsake: {
    Component: (p) => <Premium48Phase5Story {...p} />,
    frames: () => PREMIUM48_FRAMES,
    poster: () => PREMIUM48_POSTER,
  },
  PremiumSmileToKeep: {
    Component: (p) => <Premium48Phase5Story {...p} smile />,
    frames: () => PREMIUM48_FRAMES,
    poster: () => PREMIUM48_POSTER,
  },
  PremiumMonthlyChapter: {
    Component: (p) => <Premium48Phase4Story {...p} />,
    frames: () => PREMIUM48_FRAMES,
    poster: () => PREMIUM48_POSTER,
  },
  PremiumThenNow: {
    Component: (p) => <Premium48Phase4Story {...p} compare />,
    frames: () => PREMIUM48_FRAMES,
    poster: () => PREMIUM48_POSTER,
  },
  PremiumLittleThings: {
    Component: (p) => <Premium48Phase3Story {...p} />,
    frames: () => PREMIUM48_FRAMES,
    poster: () => PREMIUM48_POSTER,
  },
  PremiumMonthLetter: {
    Component: (p) => <Premium48Phase3Story {...p} monthLetter />,
    frames: () => PREMIUM48_FRAMES,
    poster: () => PREMIUM48_POSTER,
  },
  PremiumHomecoming: {
    Component: (p) => <Premium48Phase2Story {...p} />,
    frames: () => PREMIUM48_FRAMES,
    poster: () => PREMIUM48_POSTER,
  },
  PremiumFirstMonth: {
    Component: (p) => <Premium48Phase2Story {...p} month />,
    frames: () => PREMIUM48_FRAMES,
    poster: () => PREMIUM48_POSTER,
  },
  PremiumArrival: {
    Component: (p) => <Premium48Story {...p} />,
    frames: () => PREMIUM48_FRAMES,
    poster: () => PREMIUM48_POSTER,
  },
  PremiumEmbrace: {
    Component: (p) => <Premium48Story {...p} embrace />,
    frames: () => PREMIUM48_FRAMES,
    poster: () => PREMIUM48_POSTER,
  },
  FirstMonth: v1('polaroid'),
  FirstWeek: v1('fullBleed'),
  HundredDays: v1('polaroid'),
  LittleMoments: v1('fullBleed'),
  ...(Object.fromEntries(Object.keys(chapter1).map((id) => [id, ch1(id)])) as Record<
    Exclude<
      KeepsakeComposition,
      | 'FirstMonth'
      | 'FirstWeek'
      | 'HundredDays'
      | 'LittleMoments'
      | 'PremiumArrival'
      | 'PremiumEmbrace'
      | 'PremiumHomecoming'
      | 'PremiumFirstMonth'
      | 'PremiumLittleThings'
      | 'PremiumMonthLetter'
      | 'PremiumMonthlyChapter'
      | 'PremiumThenNow'
      | 'PremiumOutgrownKeepsake'
      | 'PremiumSmileToKeep'
      | 'PremiumYouDidIt'
      | 'PremiumWorldToDiscover'
      | (typeof premium48FinalDesigns)[number]['composition']
    >,
    StoryEntry
  >),
};

/** The entry for a template's composition (unknown names fall back to LittleMoments). */
export const storyOf = (id: string | null | undefined): StoryEntry =>
  stories[(id ?? '') as KeepsakeComposition] ?? stories.LittleMoments;
