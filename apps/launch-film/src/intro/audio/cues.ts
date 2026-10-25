// Executable cue sheet for the Product Introduction (see design/intro/audio-cues.md).
// Every cue is anchored to a VO line or a choreography beat, so it moves with a new recording.
import { choreo } from '../choreo';
import { interactionFrames } from '../Extras';
import { FPS, type Film, type SceneId } from '../timeline';

const sec = (s: number) => Math.round(s * FPS);

export type MusicCue = {
  id: string;
  from: number;
  to: number;
  /** Source second of the prepared 76 BPM track at `from` (bar-aligned, measured downbeats 0.80 + 3.158·k). */
  source: number;
  volume: number;
  fadeIn: number;
  fadeOut: number;
  purpose: string;
};
export type SfxCue = { id: string; file: string; at: number; volume: number; purpose: string };

const bar = (60 / 76) * 4;
const cache = new Map<string, ReturnType<typeof build>>();
export const audioFor = (film: Film) => {
  let a = cache.get(film.lang);
  if (!a) cache.set(film.lang, (a = build(film)));
  return a;
};
function build(film: Film) {
  const { sceneById } = film;
  const at = (id: SceneId, local: number) => sceneById(id).from + local;
  const cue = (id: SceneId, line: string, offset = 0) => at(id, sceneById(id).cue(line) + offset);
  const meet = cue('PI05', 'PI05a');
  const m4 = meet + sec(bar * 4); // C1 runs four bars, then skips the source's 4 s break
  const m5 = m4 + sec(bar * 6); // repeat one bar so the source's quiet coda lands after "treasure later"
  // Closing phrase starts on the C2 downbeat nearest the end logo.
  const logo = cue('PI10', 'PI10c');
  const m6 = m5 + sec(bar * Math.max(1, Math.round((logo / FPS - m5 / FPS + 0.6) / bar)));

  const music: MusicCue[] = [
    {
      id: 'music-vision-pulse',
      from: 0,
      to: at('PI04', 40),
      // The source pulse enters at 19.0 s — put it on "And a lot to keep track of".
      source: 19.0 - cue('PI02', 'PI02b', -2) / FPS,
      volume: 0.95,
      fadeIn: 12,
      fadeOut: 44,
      purpose: 'Open felt piano for the vision; the soft pulse arrives with the mental load (PI02–03)',
    },
    {
      id: 'music-settle',
      from: at('PI04', 0),
      to: meet + 2,
      source: 108.17,
      volume: 0.8,
      fadeIn: 30,
      fadeOut: 26,
      purpose: 'Pull back to sparse piano while the moment slips by; near-silence before "Meet"',
    },
    { id: 'music-reveal', from: meet, to: m4 + 8, source: 120.8, volume: 1, fadeIn: 4, fadeOut: 8, purpose: 'New phrase on "Meet Child Life", rising into quick care' },
    { id: 'music-open', from: m4, to: m5 + 8, source: 142.9, volume: 1, fadeIn: 8, fadeOut: 8, purpose: 'Full movement for coordination, Lumi, growth' },
    { id: 'music-peak', from: m5, to: m6 + 12, source: 158.69, volume: 1, fadeIn: 8, fadeOut: 12, purpose: 'Emotional peak under keepsakes; resolves to the quiet coda after "treasure later"' },
    { id: 'music-ending', from: m6, to: film.total, source: 187.12, volume: 1, fadeIn: 10, fadeOut: 40, purpose: 'Real closing phrase of the recording rings out under the end card' },
  ];

  const pi01 = choreo(sceneById('PI01')).layers;
  const pi02 = choreo(sceneById('PI02')).layers;
  const pi03 = choreo(sceneById('PI03')).layers;
  const pi08 = choreo(sceneById('PI08')).layers;
  const pi09 = choreo(sceneById('PI09')).layers;
  const i06 = interactionFrames(sceneById('PI06'));
  const i07 = interactionFrames(sceneById('PI07'));
  const i09 = interactionFrames(sceneById('PI09'));

  const sfx: SfxCue[] = [
    ...(['0-12m', '1-3y', '3-6y', '6-12y'] as const).map((stage, i) => ({
      id: `SFX01-${stage}`,
      file: `stage-${i + 1}`,
      at: at('PI01', i === 0 ? 24 : pi01[`Card/Stage/${stage}`].in! + 4),
      volume: [0.42, 0.34, 0.27, 0.21][i],
      purpose: 'Each journey station appears — tiny chime, softer each time',
    })),
    ...(['Card/Note · Last feed · 9:10?', 'Card/Note · Nap at 1:30?', 'Card/Note · Vitamin D'] as const).map((n, i) => ({
      id: `SFX02-${i + 1}`,
      file: `paper-${i + 1}`,
      at: at('PI02', pi02[n].out! + 2),
      volume: 0.3,
      purpose: 'Card/Note appears — light paper',
    })),
    { id: 'SFX03', file: 'message-tick', at: at('PI03', pi03['Card/Message · Yes — 120 ml at 9'].in! + 4), volume: 0.3, purpose: '"Yes — 120 ml at 9" bubble' },
    { id: 'SFX04a', file: 'open-chord', at: meet - 4, volume: 0.42, purpose: 'Open chord on "Meet Child Life"' },
    { id: 'SFX04', file: 'brand-chime', at: cue('PI05', 'PI05a', 4), volume: 0.5, purpose: 'Logo appears — brand chime' },
    { id: 'SFX05', file: 'tap', at: at('PI06', i06.widgetTap), volume: 0.5, purpose: 'Tap "+" on the widget' },
    { id: 'SFX06', file: 'confirm-tick', at: at('PI06', i06.siriSaved), volume: 0.36, purpose: 'Siri card shows "Saved…"' },
    { id: 'SFX07', file: 'lumi-chime', at: at('PI07', i07.lumi - 2), volume: 0.34, purpose: 'Lumi button appears' },
    { id: 'SFX08', file: 'milestone-chime', at: at('PI08', pi08['Card/Milestone'].in! + 6), volume: 0.34, purpose: 'Milestone card appears' },
    { id: 'SFX09', file: 'paper-thick', at: at('PI09', pi09['Card/Thiep'].in! + 2), volume: 0.42, purpose: 'The "1 tháng" card flips' },
    { id: 'SFX10', file: 'video-chime', at: at('PI09', i09.videoReady), volume: 0.3, purpose: 'Video preview opens' },
    { id: 'SFX10b', file: 'lift', at: cue('PI09', 'PI09b', -40), volume: 0.3, purpose: 'Soft lift into "the days you\'re living now"' },
    { id: 'SFX11', file: 'closing-chime', at: cue('PI10', 'PI10c', 2), volume: 0.5, purpose: 'Logo at the end — closing chime, same family as SFX04' },
  ];

  return { music, sfx, voLines: film.scenes.flatMap((s) => s.lines) };
}
