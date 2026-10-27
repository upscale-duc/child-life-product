import { videoRenderScale } from '@child-life/contracts';
import { renderMedia, renderStill, selectComposition, ensureBrowser } from '@remotion/renderer';
import { cpus } from 'node:os';
import { storyOf } from './compositions/registry';
import type { StoryProps } from './kit/core';
import type { Renderer } from './job';

/**
 * Remotion on this machine: the compositions are bundled at image build time (`build/bundle`),
 * Chrome Headless Shell is installed in the image, one render at a time (Cloud Run concurrency 1).
 */
export async function remotionRenderer(serveUrl: string): Promise<Renderer> {
  await ensureBrowser();
  return {
    async render({ composition: id, props, quality, video, poster, onProgress }) {
      const composition = await selectComposition({ serveUrl, id, inputProps: props });
      const scale = videoRenderScale(quality ?? 'fullHd1080');
      await renderMedia({
        scale,
        composition,
        serveUrl,
        inputProps: props,
        codec: 'h264',
        crf: 20,
        pixelFormat: 'yuv420p',
        audioCodec: 'aac',
        outputLocation: video,
        concurrency: Math.max(1, cpus().length),
        timeoutInMilliseconds: 60_000,
        onProgress: ({ progress }) => onProgress(progress),
      });
      await renderStill({
        scale,
        composition,
        serveUrl,
        inputProps: props,
        frame: storyOf(id).poster(props as StoryProps),
        output: poster,
        imageFormat: 'jpeg',
        jpegQuality: 88,
      });
      return {
        durationMs: Math.round((composition.durationInFrames / composition.fps) * 1000),
        width: Math.round(composition.width * scale),
        height: Math.round(composition.height * scale),
      };
    },
  };
}
