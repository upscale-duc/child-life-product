// Per-scene choreography: every layer and text is anchored to a VO line (scene.cue) so the
// picture re-times with the recording. Figma notes (Notes · PIxx) give the order and intent.
import { colors, type LayerCue, type TextCue } from './engine';
import type { Scene, SceneId } from './timeline';

export type SceneChoreo = {
  /** Default START→HERO start and HERO→END start (local frames). */
  in: number;
  out: number;
  stagger: number;
  layers: Record<string, LayerCue & { flip?: number }>;
  texts: TextCue[];
  thread: { in: number; inDur: number; out: number; outDur: number; opacity?: number };
};

const build: Record<SceneId, (s: Scene) => SceneChoreo> = {
  // Vision: sun rises, the thread draws the journey; each stage pops as the line reaches it.
  PI01: (s) => {
    const draw = 18,
      drawDur = 140;
    const at = (frac: number) => Math.round(draw + drawDur * frac);
    const out = s.duration - 64;
    return {
      in: 0,
      out,
      stagger: 3,
      layers: {
        'Accent/Sun': { in: 0, inDur: 40, ease: 'move', out, outDur: 56 },
        'Accent/SunHalo': { in: 0, inDur: 46, ease: 'move', out, outDur: 56 },
        'Card/Stage/0-12m': { in: 0, out, outDur: 56, ease: 'move', float: 0 },
        'Card/StageChip/0-12m': { in: 30, out, outDur: 50 },
        'Card/Stage/1-3y': { in: at(0.39), out, outDur: 50 },
        'Card/StageChip/1-3y': { in: at(0.39) + 8, out, outDur: 44 },
        'Card/Stage/3-6y': { in: at(0.67), out, outDur: 50 },
        'Card/StageChip/3-6y': { in: at(0.67) + 8, out, outDur: 44 },
        'Card/Stage/6-12y': { in: at(0.89), out, outDur: 50 },
        'Card/StageChip/6-12y': { in: at(0.89) + 8, out, outDur: 44 },
      },
      texts: [
        { name: 'Headline', text: 'Growing up,', at: s.cue('PI01a') + 4, out: out - 4 },
        { name: 'Headline/2', text: 'one moment at a time.', at: s.cue('PI01a') + 40, out: out - 2, color: colors.mintDeep },
        {
          name: 'SupportingText',
          text: 'Child Life walks alongside your family —\nstarting with the very first year.',
          at: s.cue('PI01b') + 6,
          out,
        },
      ],
      thread: { in: draw, inDur: drawDur, out, outDur: 56 },
    };
  },
  // Firsts: the photo slides right; three notes pop around it on "a lot to keep track of".
  PI02: (s) => {
    const notes = s.cue('PI02b') + 14;
    return {
      in: 0,
      out: notes,
      stagger: 12,
      layers: {
        'Photo/motherbaby': { in: 0, inDur: 40, ease: 'move', out: notes, outDur: 40, float: 1.5 },
        'Card/Note · Last feed · 9:10?': { in: 0, out: notes, outDur: 24, ease: 'spring' },
        'Card/Note · Nap at 1:30?': { in: 0, out: notes + 12, outDur: 24, ease: 'spring' },
        'Card/Note · Vitamin D': { in: 0, out: notes + 24, outDur: 24, ease: 'spring' },
      },
      texts: [
        { name: 'Headline', text: 'Full of firsts.', at: s.cue('PI02a') + 34, dimTo: 0.35, dimAt: notes },
        { name: 'Headline/2', text: 'And a lot to keep track of.', at: s.cue('PI02b'), color: colors.muted },
      ],
      thread: { in: 0, inDur: 40, out: notes, outDur: 40 },
    };
  },
  // Juggle: one piece per VO beat; the thread tangles. Busy but calm (no red, no shake).
  PI03: (s) => {
    const c = s.cue('PI03c');
    return {
      in: 0,
      out: s.duration - 36,
      stagger: 0,
      layers: {
        'Photo/motherbaby': { in: 0, inDur: 30, ease: 'move', out: s.duration - 40, outDur: 36, float: 1.5 },
        'Card/Note · Last feed · 9:10?': { in: 0, inDur: 26, out: s.duration - 40, outDur: 36 },
        'Card/Note · Next nap?': { in: s.cue('PI03b'), out: s.duration - 40, outDur: 36 },
        'Card/Message · Did she eat yet?': { in: c + 10, out: s.duration - 40, outDur: 36 },
        'Card/Message · Yes — 120 ml at 9': { in: c + 30, out: s.duration - 40, outDur: 36 },
        'Card/Family · loose': { in: c + 56, out: s.duration - 40, outDur: 36 },
        'Card/Note · Vaccine · Sat': { in: c + 74, out: s.duration - 40, outDur: 36 },
        'Card/Note · Bath tonight': { in: 0, out: c + 92, outDur: 26, ease: 'spring' },
      },
      texts: [
        {
          name: 'Headline',
          text: 'The last feed. The next nap.',
          at: s.cue('PI03a'),
          reveal: [{ from: s.cue('PI03b'), text: ' The next nap.' }],
          dimTo: 0.5,
          dimAt: s.duration - 30,
        },
        { name: 'SupportingText', text: 'The little updates, so everyone knows how the day is going.', at: c + 4, out: s.duration - 30 },
      ],
      thread: { in: 0, inDur: c + 60, out: s.duration - 40, outDur: 36 },
    };
  },
  // Moment: notes fade back, the smile rises and fills the right side, then drifts away.
  PI04: (s) => {
    const out = s.cue('PI04e') + 30;
    return {
      in: 8,
      out,
      stagger: 3,
      layers: {
        'Photo/smile': { in: 18, inDur: 64, ease: 'move', out, outDur: 70, float: 1.5, z: 5 },
      },
      texts: [
        {
          name: 'Headline',
          text: 'A smile. A sound.',
          at: s.cue('PI04c') - 2,
          reveal: [{ from: s.cue('PI04d') - 2, text: ' A sound.' }],
          out: s.duration - 26,
          maxWidth: 900,
        },
        { name: 'SupportingText', text: 'A moment you want to remember.', at: s.cue('PI04e'), out: s.duration - 22, maxWidth: 900 },
      ],
      thread: { in: 10, inDur: 90, out, outDur: 70 },
    };
  },
  // Meet: everything converges into the logo; the thread becomes the band under it.
  // END: each note dissolves exactly where its real UI appears.
  PI05: (s) => {
    const logo = s.cue('PI05a') + 2;
    const out = s.cueEnd('PI05b') - 8;
    return {
      in: 0,
      out,
      stagger: 2,
      layers: {
        'Photo/smile': { in: 0, inDur: logo, ease: 'move', out, outDur: 40, float: 0 },
        'Card/Note · Last feed · 9:10?': { in: 0, inDur: logo, ease: 'move', out, outDur: 40 },
        'Card/Note · Next nap?': { in: 2, inDur: logo, ease: 'move', out, outDur: 40 },
        'Card/Note · Vaccine · Sat': { in: 4, inDur: logo, ease: 'move', out: out + 8, outDur: 40 },
        Logo: { in: logo, inDur: 30, out, outDur: 40, ease: 'spring', float: 0 },
        'UICrop/HomNay_BuBinh': { in: 0, out: out + 6, outDur: 34, ease: 'spring' },
        'UICrop/HomNay_NhacNho': { in: 0, out: out + 16, outDur: 34, ease: 'spring' },
      },
      texts: [
        { name: 'Headline', text: 'A shared space for caring for your child,', at: s.cue('PI05b') + 2, out: out - 8, align: 'center' },
        { name: 'Headline/2', text: 'and keeping their story close.', at: s.cue('PI05b') + 62, out: out - 6, align: 'center', color: colors.mintDeep },
      ],
      thread: { in: 4, inDur: logo + 16, out, outDur: 40 },
    };
  },
  // QuickCare: widget tap → Apple Watch → Siri "Saved", then the hand-off to the next carer.
  PI06: (s) => {
    const widget = s.cue('PI06b') + 2;
    const out = s.cue('PI06c') - 12;
    return {
      in: 0,
      out,
      stagger: 10,
      layers: {
        'Photo/feeding': { in: 0, inDur: 36, ease: 'move', out, outDur: 40, float: 1.5 },
        'UICrop/Widget': { in: widget, out, outDur: 36 },
        'AppScreen/AppleWatch': { in: widget + 46, out: out + 4, outDur: 36 },
        'Card/Siri': { in: widget + 86, out: out + 8, outDur: 36 },
        'Photo/father': { in: 0, out: out + 6, outDur: 40, ease: 'move', float: 1.5 },
        'Card/BanGiao': { in: 0, out: out + 18, outDur: 30, ease: 'spring' },
        'Card/Member/Me': { in: 0, out: out + 30, outDur: 28, ease: 'spring' },
        'Card/Member/CoLan': { in: 0, out: out + 38, outDur: 28, ease: 'spring' },
        'UICrop/HomNay_BuBinh': { in: 0, out: out + 48, outDur: 28, ease: 'spring' },
      },
      texts: [
        { name: 'Headline', text: 'Log it in a tap.', at: s.cue('PI06a') + 2, out: out - 6 },
        { name: 'SupportingText', text: 'Phone widget · Apple Watch · Siri', at: widget - 4, out: out - 6 },
        { name: 'Headline', text: 'Pick up where they left off.', at: s.cue('PI06c') + 4 },
      ],
      thread: { in: 0, inDur: widget + 90, out, outDur: 44 },
    };
  },
  // Lumi: the button pops, the real CH04 drafts open from it; then age ideas + reminders.
  PI07: (s) => {
    const out = s.cue('PI07c') - 8;
    return {
      in: 0,
      out,
      stagger: 6,
      layers: {
        'Accent/Lumi': { in: 2, inDur: 24, out, outDur: 40, ease: 'spring', z: 3 },
        'UICrop/Lumi_Drafts': { in: s.cue('PI07a') + 30, inDur: 34, out: out - 4, outDur: 34 },
        'Card/GoiYHomNay': { in: 0, out: out + 10, outDur: 34, ease: 'spring' },
        'List/NhacViec': { in: 0, out: s.cue('PI07d') - 6, outDur: 30, ease: 'spring' },
      },
      texts: [
        { name: 'Headline', text: 'Tell Lumi.', at: s.cue('PI07a') + 10, out: out - 10 },
        { name: 'Headline/2', text: 'It drafts the log for you.', at: s.cue('PI07b'), out: out - 8, color: colors.mintDeep },
        { name: 'SupportingText', text: 'You check it, then save.', at: s.cue('PI07b') + 40, out: out - 6 },
        { name: 'Headline', text: 'Ideas that fit their age.', at: s.cue('PI07c') + 6 },
        { name: 'Headline/2', text: 'Reminders when they matter.', at: s.cue('PI07d'), color: colors.mintDeep },
      ],
      thread: { in: 0, inDur: 60, out, outDur: 50 },
    };
  },
  // Grow: chart line, milestone with a real photo, then the family album.
  PI08: (s) => {
    const out = s.cue('PI08c') + 16;
    return {
      in: 0,
      out,
      stagger: 6,
      layers: {
        'Card/GrowthChart': { in: 0, inDur: 40, ease: 'move', out, outDur: 40 },
        'Card/Milestone': { in: s.cue('PI08b') - 6, out, outDur: 40 },
        'UICrop/Album_CaNha': { in: 0, out: out + 6, outDur: 36, ease: 'spring' },
        'Card/Family': { in: 0, out: out + 30, outDur: 28, ease: 'spring' },
      },
      texts: [
        { name: 'Headline', text: 'Celebrate the firsts.', at: s.cue('PI08b'), out: s.duration - 26 },
        { name: 'SupportingText', text: 'And bring your family along as your child grows.', at: s.cue('PI08c'), out: s.duration - 22 },
      ],
      thread: { in: 0, inDur: 60, out, outDur: 40 },
    };
  },
  // Keepsakes: polaroids sit on the thread; the "1 tháng" card flips, the video opens and grows.
  PI09: (s) => {
    const out = s.cue('PI09b') - 12;
    return {
      in: 0,
      out,
      stagger: 7,
      layers: {
        'Card/Thiep': { in: s.cue('PI09a') + 52, inDur: 34, out, outDur: 50, flip: 1 },
        'Card/VideoPreview': { in: s.cue('PI09a') + 92, out, outDur: 56, ease: 'move', z: 4 },
      },
      texts: [
        { name: 'Headline', text: 'Everyday photos,', at: s.cue('PI09a') + 4, out: out - 8 },
        { name: 'Headline/2', text: 'turned into keepsakes.', at: s.cue('PI09a') + 44, out: out - 6, color: colors.mintDeep },
        { name: 'Headline', text: 'The days you’re living now', at: s.cue('PI09b') },
        { name: 'Headline/2', text: 'are the memories you’ll treasure later.', at: s.cue('PI09c'), color: colors.mintDeep },
      ],
      thread: { in: 0, inDur: 40, out, outDur: 56 },
    };
  },
  // Hold: the concept line, the journey back up to the sun, then the logo end card (hold > 4 s).
  PI10: (s) => {
    const out = s.cue('PI10c') - 14;
    return {
      in: 0,
      out,
      stagger: 18,
      layers: {
        'Card/Note · Last feed · 9:10?': { in: 0, inDur: 40, ease: 'move' },
        'Card/Note · Next nap?': { in: 4, inDur: 40, ease: 'move' },
        'Accent/Sun': { in: 40, inDur: 70, ease: 'move', out, outDur: 50 },
        'Photo/newborn': { in: s.cue('PI10b') - 10, out, outDur: 36 },
        'Photo/toddler': { in: s.cue('PI10b') + 12, out: out + 4, outDur: 36 },
        'Photo/child6': { in: s.cue('PI10b') + 34, out: out + 8, outDur: 36 },
        Logo: { in: 0, out: s.cue('PI10c') - 2, outDur: 30, ease: 'spring', float: 0 },
        CTA: { in: 0, out: s.cue('PI10d') + 40, outDur: 26, ease: 'spring', float: 0 },
      },
      texts: [
        { name: 'Headline', text: 'Less to keep track of.', at: s.cue('PI10a') - 4, out: out - 6 },
        { name: 'Headline/2', text: 'More to hold on to.', at: s.cue('PI10b'), out: out - 4, color: colors.mintDeep },
        { name: 'SupportingText', text: 'Growing together, every step of the way.', at: s.cue('PI10d'), align: 'center' },
      ],
      thread: { in: 30, inDur: 100, out, outDur: 56 },
    };
  },
};

const cache = new Map<string, SceneChoreo>();
export const choreo = (scene: Scene) => {
  const key = `${scene.lang}:${scene.id}`;
  let c = cache.get(key);
  if (!c) cache.set(key, (c = build[scene.id](scene)));
  return c;
};
