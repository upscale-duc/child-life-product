import { defaultKeepsakeVideoBrand } from '@child-life/contracts';
import { Composition, type CalculateMetadataFunction } from 'remotion';
import type { StoryProps } from '../kit/core';
import { FPS, type MemoryStoryProps } from './MemoryStory';
import { stories, storyOf } from './registry';

/** The compositions a video template may name (`keepsakeCompositions`; see registry.tsx). */
export const compositions = stories;

/** Sample props for the Studio and the sample render (no child data). */
export const sampleProps: MemoryStoryProps = {
  photos: [],
  title: 'Tháng đầu tiên của Teddy',
  message: 'Một tháng qua, con dạy ba mẹ biết yêu thương nhiều hơn.',
  name: 'Teddy',
  dateLine: '17.09 – 17.10.2026',
  mark: '1',
  palette: { background: '#E4F4F1', ink: '#173D44', accent: '#2BA89A' },
  music: null,
  durationSec: 45,
  brand: { ...defaultKeepsakeVideoBrand },
};

const metadata =
  (id: string): CalculateMetadataFunction<MemoryStoryProps> =>
  ({ props }) => ({ durationInFrames: storyOf(id).frames(props as StoryProps) });

export function Root() {
  return (
    <>
      {Object.entries(stories).map(([id, entry]) => (
        <Composition
          key={id}
          id={id}
          component={(p: MemoryStoryProps) => <entry.Component {...(p as StoryProps)} />}
          width={1080}
          height={1920}
          fps={FPS}
          durationInFrames={45 * FPS}
          defaultProps={sampleProps}
          calculateMetadata={metadata(id)}
        />
      ))}
    </>
  );
}
