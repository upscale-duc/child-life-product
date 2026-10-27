import { describe, expect, it, vi } from 'vitest';
const mocks = vi.hoisted(() => ({ media: vi.fn(), still: vi.fn() }));
vi.mock('@remotion/renderer', () => ({
  ensureBrowser: vi.fn(),
  selectComposition: vi.fn(async () => ({
    width: 1080,
    height: 1920,
    fps: 30,
    durationInFrames: 90,
  })),
  renderMedia: mocks.media,
  renderStill: mocks.still,
}));
import { remotionRenderer } from '../src/remotion-renderer';
import { sampleProps } from '../src/compositions/Root';

describe('server-frozen export resolution', () => {
  for (const [quality, scale, width, height] of [
    ['hd720', 2 / 3, 720, 1280],
    ['fullHd1080', 1, 1080, 1920],
  ] as const)
    it(`${quality} uses the same scale for video, poster and persisted dimensions`, async () => {
      const renderer = await remotionRenderer('http://localhost');
      const result = await renderer.render({
        composition: 'LittleMoments',
        props: sampleProps,
        quality,
        video: '/tmp/video.mp4',
        poster: '/tmp/poster.jpg',
        onProgress: () => {},
      });
      expect(mocks.media).toHaveBeenLastCalledWith(expect.objectContaining({ scale }));
      expect(mocks.still).toHaveBeenLastCalledWith(expect.objectContaining({ scale }));
      expect(result).toMatchObject({ width, height });
    });
});
