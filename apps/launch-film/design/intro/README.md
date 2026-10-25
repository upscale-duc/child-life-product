# Child Life — Product Introduction V2 (rev 2)

This folder is the handoff for Codex to build the product introduction video in Remotion, running locally.

## Concept

> **Less to keep track of. More to hold on to.**

The film tells one story. It is not a feature tour:

1. **Vision:** the app walks alongside the child from the first day to growing up.
2. Parents' lives are full of firsts, with scattered information and a lot to remember.
3. A moment slips by.
4. **Child Life appears.**
5. The same life becomes coordinated, and the story is kept.
6. Back to the vision.

Real UI appears only to prove a benefit in the story. Feature content follows dev.childlife.app:

- the four-stage vision
- quick logging (widget, Apple Watch, Siri)
- shared family care and handoff
- Lumi drafting logs from a message
- age-based suggestions and reminders
- milestones and growth
- keepsake cards and videos
- the private family album

### The recurring motif: `Accent/Thread`

A single mint thread runs through the whole film. It is borrowed from the journey path on the website hero.

| Scene | What the thread does |
|---|---|
| PI01 | Draws the journey up to the sun |
| PI03 | Tangles around the notes |
| PI04 | Loosens |
| PI05 | Becomes the band under the logo |
| PI06–08 | Links photos to UI |
| PI09 | Becomes a timeline of photos |
| PI10 | Returns to the journey (newborn → toddler → child), then becomes the band under the logo |

Each keyframe stores the thread's path `d` in `timeline.json` as `threadPath` (viewBox 1920×1080).

## Video specs

| Spec | Value |
|---|---|
| Resolution | 1920×1080 |
| Frame rate | 30fps |
| Target length | **90s (2700 frames)**, including pauses |
| Scenes | 10, with stable IDs **PI01–PI10** |
| Font | Be Vietnam Pro: 600 for headlines, 500 for supporting text |

**Colors (Child Life variables):**

| Role | Variable | Hex |
|---|---|---|
| Background | `cloud` | #F6FCFB |
| Text | `ink` | #173D44 |
| Muted text | `ink-muted` | #55707A |
| Accent | `mint` | #2CBFB3 |
| Strong accent | `mint-deep` | #087F7B |
| Sun | `sunshine` | #FFD166 |

> ⚠️ **Every timing is an ESTIMATE that has not been matched to a recorded voice-over.** The lines for PI01, PI06 and PI07 are **PROPOSED** and need approval; see `script.en.md`. Once the voice-over is recorded, re-time to it and keep the scene IDs unchanged.

## Design source (Figma)

| What | Where |
|---|---|
| File | `sJLG1fAXKDnDr9YI6Yx8ex` |
| Page | **Child Life — Product Introduction V2** (`844:1883`). Older designs are untouched. |
| Overview | `Storyboard · PI V2` and `Motif & nguồn · PI V2` at the top of the page |
| Keyframes | `PIxx_<Name>_<start>-<end>s_START/HERO/END` (1920×1080). Node IDs are in `storyboard.md` and `timeline.json`. |
| Scene notes | `Notes · PIxx` next to each scene: VO, on-screen text, motion, transitions, audio cues |

**Layer naming.** Layers that animate are kept separate:

- `Background`
- `Headline`, `Headline/2`, `SupportingText`
- `Photo/*`, `Card/*`, `UICrop/*`, `AppScreen/*`
- `Accent/Thread`, `Accent/Sun`, `Accent/Lumi`
- `Logo`, `CTA`

A layer with the same name in START, HERO and END is the same element, so interpolate between those states.

## Reference video

The YouTube video `mtPqxJBMXCQ` could **not be watched**. Only its metadata was readable: "Explainer Video for Madison…", from the What a Story channel. This storyboard **does not analyse or borrow** its content or motion.

## Files

| File | Contents |
|---|---|
| `README.md` | Concept, sources, and this handoff guide |
| `script.en.md` | VO lines (locked or proposed), reading direction, pauses, and the product claims checked |
| `storyboard.md` | For each scene: ID, VO, on-screen text, action, transition |
| `audio-cues.md` | Music, sound effects, in/out points, emotional intent |
| `assets.md` | Source assets, Figma nodes, the photo audit, usage rights, and what is still missing |
| `timeline.json` | Estimated timeline with stable IDs and the layer state at each keyframe |

## Build steps for Codex

1. **Composition.** Read `timeline.json`. Create `<Composition id="ChildLifeIntroV2" 1920×1080 fps=30 durationInFrames=2700>` with a `<Series>` of 10 `<Sequence>`s.
2. **Assets.** Export them as listed in `assets.md`: UI as PNG @2x/3x, logo and accents as SVG. Download the full-size photos from StockSnap; the copies in Figma are only 960px.
3. **Thread.** Render `Accent/Thread` once, above the `Series`, as a single SVG `<path>`.
   - Within a scene, morph between its `threadPath` values using `@remotion/paths` or `flubber`.
   - Between scenes, crossfade over 6 frames.
   - Draw it on with `strokeDashoffset`.
4. **Easing.**

   | Motion | Setting |
   |---|---|
   | Element entering | `spring({stiffness:120, damping:20, mass:1})` |
   | Text entering | opacity 0→1, translateY 24→0, 18 frames, `Easing.bezier(0.3,0,0,1)` |
   | Text leaving | 8 frames, `Easing.bezier(0.4,0,1,1)` |
   | Stagger between elements | 3–12 frames; never bring everything in at once |
5. **Audio.** Add VO, music and SFX as placeholder tracks using the timestamps in `audio-cues.md`. Re-time once the real VO exists.
