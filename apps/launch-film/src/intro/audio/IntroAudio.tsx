// Three independent stems — VO, music, SFX — each a named Sequence in the Studio timeline.
// Music ducks ~6 dB while the voice speaks (smoothed), per design/intro/audio-cues.md.
import React from 'react';
import { Audio } from '@remotion/media';
import { interpolate, Sequence, staticFile, useCurrentFrame, useVideoConfig } from 'remotion';
import { FPS, type Film } from '../timeline';
import { audioFor, type MusicCue } from './cues';

const MUSIC = 'audio/dream-culture-76bpm.m4a';
const DUCK = 0.5; // −6 dB

/** 0..1 voice activity with 6f attack / 12f release around each VO line. */
export const voiceActivity = (film: Film, global: number) => {
  let v = 0;
  for (const l of audioFor(film).voLines) {
    const a = interpolate(global, [l.from - 6, l.from, l.from + l.duration, l.from + l.duration + 12], [0, 1, 1, 0], {
      extrapolateLeft: 'clamp',
      extrapolateRight: 'clamp',
    });
    v = Math.max(v, a);
  }
  return v;
};

const MusicTrack: React.FC<{ film: Film; cue: MusicCue; trim: number }> = ({ film, cue, trim }) => {
  const local = useCurrentFrame() + trim;
  const len = cue.to - cue.from;
  const env = Math.min(1, local / Math.max(1, cue.fadeIn), Math.max(0, (len - local) / Math.max(1, cue.fadeOut)));
  const duck = 1 - (1 - DUCK) * voiceActivity(film, cue.from + local);
  return (
    <Audio
      src={staticFile(MUSIC)}
      trimBefore={Math.round(cue.source * FPS) + trim}
      volume={cue.volume * Math.max(0, env) * duck}
    />
  );
};

/** Clip a cue to the visible window (supports single-scene previews via `offset`). */
const Window: React.FC<{ name: string; from: number; to: number; offset: number; children: (trim: number) => React.ReactNode }> = ({
  name,
  from,
  to,
  offset,
  children,
}) => {
  const { durationInFrames } = useVideoConfig();
  const start = Math.max(from, offset),
    end = Math.min(to, offset + durationInFrames);
  if (end <= start) return null;
  return (
    <Sequence name={name} from={start - offset} durationInFrames={end - start} layout="none">
      {children(start - from)}
    </Sequence>
  );
};

export const IntroAudio: React.FC<{ film: Film; offset?: number }> = ({ film, offset = 0 }) => {
  const { music, sfx, voLines } = audioFor(film);
  const voDir = film.lang === 'en' ? 'intro/vo' : `intro/vo/${film.lang}`;
  return (
  <>
    {voLines.map((l) => (
      <Window key={l.id} name={`vo: ${l.id}`} from={l.from} to={l.from + l.duration + 6} offset={offset}>
        {(trim) => <Audio src={staticFile(`${voDir}/${l.id}.wav`)} trimBefore={trim} volume={1} />}
      </Window>
    ))}
    {music.map((m) => (
      <Window key={m.id} name={`music: ${m.id}`} from={m.from} to={m.to} offset={offset}>
        {(trim) => <MusicTrack film={film} cue={m} trim={trim} />}
      </Window>
    ))}
    {sfx.map((s) => (
      <Window key={s.id} name={`sfx: ${s.id}`} from={s.at} to={s.at + 6 * FPS} offset={offset}>
        {(trim) => <Audio src={staticFile(`intro/sfx/${s.file}.wav`)} trimBefore={trim} volume={s.volume} />}
      </Window>
    ))}
  </>
);
};
