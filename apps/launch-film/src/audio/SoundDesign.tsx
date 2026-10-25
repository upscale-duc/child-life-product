import { Audio } from '@remotion/media';
import { Sequence, staticFile, useCurrentFrame, useVideoConfig, interpolate } from 'remotion';
import { timeline } from '../timeline';
import { audioCues, type AudioCue } from './cues';
import prepared from './prepared.json';
const Track = ({ cue, trim }: { cue: AudioCue; trim: number }) => {
  const frame = useCurrentFrame() + trim;
  const attack = Math.min(1, Math.max(0, frame / Math.max(1, cue.fadeIn)));
  const release = Math.min(1, Math.max(0, (cue.duration - 1 - frame) / Math.max(1, cue.fadeOut)));
  let gain = cue.volume * attack * release;
  // Deliberate breathing spaces and a broad, gentle keepsake swell.
  if (cue.kind === 'music') {
    const global = timeline.find((s) => s.id === cue.sceneId)!.from + cue.localFrame + frame;
    const seconds = global / 30;
    const breathing = interpolate(
      seconds,
      [
        0, 14.1, 14.2, 14.9, 15.3, 41.5, 43.67, 47.8, 48.7, 61.05, 61.45, 62, 66.7, 67.25, 68, 82,
        86, 90,
      ],
      [1, 1, 0.64, 0.64, 1, 1, 1.12, 1, 0.75, 0.8, 0.42, 0.8, 0.8, 0.4, 0.8, 1, 1, 1],
      { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' },
    );
    gain *= breathing;
  }
  const sourceFrom = cue.id === 'music-resolve' ? prepared.endingStartFrame : cue.sourceFrom;
  return <Audio src={staticFile(cue.src)} trimBefore={sourceFrom + trim} volume={gain} />;
};
export const SoundDesign = ({ startAtSeconds = 0 }: { startAtSeconds?: number }) => {
  const { fps, durationInFrames } = useVideoConfig();
  const offset = Math.round(startAtSeconds * fps);
  return (
    <>
      {audioCues.map((cue) => {
        const start = timeline.find((s) => s.id === cue.sceneId)!.from + cue.localFrame;
        const visibleStart = Math.max(start, offset),
          visibleEnd = Math.min(start + cue.duration, offset + durationInFrames);
        if (visibleEnd <= visibleStart) return null;
        return (
          <Sequence
            key={cue.id}
            name={`${cue.kind}: ${cue.id}`}
            from={visibleStart - offset}
            durationInFrames={visibleEnd - visibleStart}
            layout="none"
          >
            <Track cue={cue} trim={visibleStart - start} />
          </Sequence>
        );
      })}
    </>
  );
};
