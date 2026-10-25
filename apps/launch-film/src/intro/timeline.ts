// Product Introduction V2 (Figma 844:1883). Picture is timed to the voice-over, not the
// estimated marks in keyframes.json: each scene = lead + VO lines (+ pauses) + tail.
// Re-run scripts/make-vo.mjs after a new recording and the whole film re-times; scene IDs stay PI01–PI10.
import voEn from './vo.json';
import voVi from './vo.vi.json';
import keyframes from './keyframes.json';

export const FPS = 30;
export type Lang = 'en' | 'vi';
export type SceneId = 'PI01' | 'PI02' | 'PI03' | 'PI04' | 'PI05' | 'PI06' | 'PI07' | 'PI08' | 'PI09' | 'PI10';

// Seconds of picture before the first line and after the last line of each scene.
const pacing: Record<SceneId, { lead: number; tail: number }> = {
  PI01: { lead: 0.9, tail: 0.8 }, // sun rises before the first word
  PI02: { lead: 0.4, tail: 0.6 },
  PI03: { lead: 0.3, tail: 0.8 }, // short hold before the moment
  PI04: { lead: 0.5, tail: 1.0 }, // the moment slips by; near-silence before "Meet"
  PI05: { lead: 0.7, tail: 1.5 }, // notes turn into real UI after the line
  PI06: { lead: 0.5, tail: 0.7 },
  PI07: { lead: 0.5, tail: 0.8 },
  PI08: { lead: 0.4, tail: 0.8 },
  PI09: { lead: 0.5, tail: 1.5 }, // emotional peak breathes
  PI10: { lead: 0.6, tail: 5.0 }, // end card holds > 4 s, no fade to black
};

export type VoLine = { id: string; scene: SceneId; text: string; from: number; duration: number; local: number };
export type Scene = {
  id: SceneId;
  lang: Lang;
  slug: string;
  from: number;
  duration: number;
  lines: VoLine[];
  /** Local frame where a VO line starts. */
  cue: (id: string) => number;
  /** Local frame where a VO line ends. */
  cueEnd: (id: string) => number;
  keyframes: (typeof keyframes)['scenes'][number]['keyframes'];
};

const f = (s: number) => Math.round(s * FPS);
type VoFile = { lines: { id: string; scene: string; text: string; pauseAfter: number; duration: number }[] };

const build = (lang: Lang, vo: VoFile) => {
  let cursor = 0;
  const scenes: Scene[] = keyframes.scenes.map((k) => {
    const id = k.id as SceneId;
    const { lead, tail } = pacing[id];
    let t = lead;
    const lines: VoLine[] = [];
    for (const l of vo.lines.filter((l) => l.scene === id)) {
      lines.push({ id: l.id, scene: id, text: l.text, local: f(t), from: cursor + f(t), duration: f(l.duration) });
      t += l.duration + l.pauseAfter;
    }
    const duration = f(t + tail);
    const scene: Scene = {
      id,
      lang,
      slug: k.slug,
      from: cursor,
      duration,
      lines,
      cue: (line) => {
        const hit = lines.find((l) => l.id === line);
        if (!hit) throw new Error(`No VO line ${line} in ${id}`);
        return hit.local;
      },
      cueEnd: (line) => {
        const hit = lines.find((l) => l.id === line)!;
        return hit.local + hit.duration;
      },
      keyframes: k.keyframes,
    };
    cursor += duration;
    return scene;
  });
  return { lang, scenes, total: cursor, sceneById: (id: SceneId) => scenes.find((s) => s.id === id)! };
};

export type Film = ReturnType<typeof build>;
export const films: Record<Lang, Film> = { en: build('en', voEn), vi: build('vi', voVi) };
