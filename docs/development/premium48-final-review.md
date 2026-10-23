# Premium 48 · Phases 7–12

Owner request, 22 October 2026: implement all six remaining phases together, each with
two cards and two videos, new original artwork, fresh sample photos and new music.
English demo child names remain in both locales. Existing group headings and Child
Life branding remain. This supersedes the earlier pause after every phase.

| Phase | Cards / videos   | Subjects                                                    | New SVGs | New photos | New scores |
| ----- | ---------------- | ----------------------------------------------------------- | -------- | ---------- | ---------- |
| 7     | C13/V13, C14/V14 | Held With Love; Across Generations                          | 20       | 10         | 2          |
| 8     | C15/V15, C16/V16 | Your Circle of Love; A Day With You                         | 20       | 8          | 2          |
| 9     | C17/V17, C18/V18 | The Tiniest Details; Sleep Softly, Little One               | 20       | 8          | 2          |
| 10    | C19/V19, C20/V20 | One Hundred Days With You; Your First Celebration           | 21       | 10         | 4          |
| 11    | C21/V21, C22/V22 | Our First Little Adventure; Twelve Months of You            | 20       | 17         | 2          |
| 12    | C23/V23, C24/V24 | A Letter on Your First Birthday; Our Family, One Year Later | 20       | 10         | 2          |

New total: **24 templates, 121 original SVGs, 63 distinct stock photos, 14 original
synthesized scores**. Premium collection now has 48 templates across twelve phases;
the catalog also retains the 32 earlier legacy templates. Production is unchanged.

## Review artifacts

- Combined gallery: `artifacts/premium48-final/index.html`.
- Individual galleries: `artifacts/premium48-phase7/` through `premium48-phase12/`.
- Each gallery has Vietnamese / English and 4:5 / 9:16 selectors, eight actual
  Flutter PNG/JPEG exports, eight Remotion MP4/posters, music players, photo credits,
  SVG originals/zip and a link to its Figma board.
- New demo names: Henry, Grace, Jack, Isla, Leo, Sophie, Lucas, Chloe, Theo, Alice,
  Oscar and Ruby. Actual entered/profile names are preserved, never translated.
- Photo manifests: `design/sample-photos/premium48-phase{7..12}-licence.json`.
  Pexels source/creator/license links are included. Each photo is distinct by source
  and SHA-256 from previous phases and every other new phase. Images illustrate
  layouts; they do not establish the same child/family, an age or actual chronology.
- Original editable vectors are in the existing Personal Duckie asset file:
  [Figma assets](https://www.figma.com/design/8xApPL1XnwD4n1bpr0dPhq).
  Six new pages are ordered 7–12; all earlier pages are preserved. Board IDs:
  `36:835`, `36:661`, `36:3`, `36:331`, `36:174`, `36:515`. Structural checks:
  121 imported SVGs, 281 vector nodes, zero image paints, zero overflowing text.
  Each board screenshot has been inspected; the final V1 file was not modified.

## Behavior

- Required photos: C13–24 = **2, 2, 4, 4, 3, 1, 3, 3, 3, 12, 1, 3**;
  V13–24 = **5, 5, 4, 4, 4, 4, 5, 5, 5, 12, 5, 5**. Five-input stories keep
  independent inputs. Four-input stories intentionally reprise all four in the
  closing collage. No implicit photo cycling fills missing slots.
- V22 follows the exact 1500-frame / 50-second cue sheet: 45-frame opening,
  75-frame monthly heroes, group holds, a three-second twelve-photo grid and a
  three-second final hero. Other stories are 1050 frames / 35 seconds at 30 fps.
  Crossfades occupy the existing timeline. Poster: V22 frame 1440, others frame 990.
- The twelve-month card/video requires all twelve photo slots before export.
  Missing slots stay empty in the editor; they are never filled with repeats.
  Month labels and month-specific captions require explicit order confirmation.
  There is no shortened-month export mode in this release.
- C20/V20 requires a named occasion and an explicit decoration choice: neutral,
  Tết/Lunar New Year or Christmas. Locale does not select the holiday. Only the
  chosen pair of ornaments renders; the other sets remain hidden. The mobile
  editor chooses the matching original score unless the parent selects another
  track or mutes it. Preview uses Christmas photos and the Christmas score.
- A first celebration/trip, a hundred-day milestone, a sleeping child, hand/foot
  details, holding/playing and a morning-to-evening sequence are never inferred
  from uploads. Parent confirmations select specific copy; otherwise complete
  neutral sentences replace it. A hundred-day numeral appears only when selected.
- Relative/narrator names are optional, with authored fallbacks; no mother/father
  or missing family member is invented. Unknown dates stay empty. V23 permits
  edited letter paragraphs and defaults its missing signature to the family.
- Card image `when` conditions use frozen authored copy, including the explicit
  celebration theme. A single metadata label no longer repositions unrelated
  birthday-letter paragraphs. Video reduced motion skips graphic movement/zoom;
  music mute remains independent.

## Implementation and validation

- New catalog factory: `packages/contracts/src/keepsakes-premium48-final.ts`.
  Twelve registered renderer compositions:
  `apps/renderer/src/compositions/premium48-final.tsx`.
- Art generator, catalog/fixture builder, Figma import and gallery builder:
  `scripts/src/*premium48-final.ts`. Scores:
  `apps/renderer/scripts/premium48-final-music.mjs`. No outside recording,
  soundfont, sample or borrowed melody is used.
- Contracts phases 1–12: **235 tests passed**. Renderer and job behavior under
  Firestore emulator: **35 tests passed**. Portal keepsake tests: **17 passed**.
  Mobile editor/render checks: **14 passed**, covering explicit theme selection,
  conditional ornaments, letter bounds and VI/EN parity for all twelve phases.
  Another **38 mobile keepsake and route regression tests passed**.
- All 48 new MP4s passed codec, frame count, dimensions, audio, no-black-frame
  and English-demo-name checks. See each phase's `audio-black-qa.json` and
  `video-qa.json`. All 48 PNGs were rendered with the actual Flutter card renderer
  and bundled fonts. Review fixes include the celebration mask, letter paragraph
  positioning and selected demo crops.
- Typechecks for contracts/scripts/renderer/portal passed; Flutter analyze has
  no issues. Lint and formatting apply to changed task files. QA receipts and
  SHA-256 handoff manifests are next to the rendered artifacts.

## Dev deployment

- Renderer image `premium48-final-20261022`, Cloud Build
  `5540b7af-8ae4-4b88-a079-679f1919e735` succeeded. Revision
  **keepsake-renderer-00015-srq** serves 100% traffic. Existing private access,
  service configuration and IAM were retained.
- The five keepsake functions were updated successfully. Portal and player:
  https://child-life-dev-admin.web.app and https://child-life-dev-keepsake.web.app.
  Hosting bundle hashes match the builds; receipt:
  `artifacts/premium48-final/hosting-qa.json`.
- Portal was built in an isolated checkout with the template changes, keeping
  unrelated in-progress notification edits out of this deployment. Those working
  files were preserved in the original workspace.
- Six catalog publications add exactly four templates each and preserve every
  other template, music track, staff draft and Premium access `everyone`. The last
  version is **ks_p48_phase12_1792641944236**, with 80 templates total, 48 Premium 48
  templates and 31 music tracks. Per-phase snapshots/receipts: `published.json`
  and `catalog-before.json` in each artifact directory.
- Public **40/40 video templates** have distinct playable VI/EN MP4s and localized
  posters. Coverage: `artifacts/premium48-final/public-coverage.json`. Catalog QA
  confirms all 56 earlier templates, all 17 earlier tracks, Premium access and the
  staff draft are preserved: `catalog-qa.json` in the same directory.
- **12/12 actual dev server exports completed and were filed as memories**, one
  Vietnamese 9:16 video with default music and one English 4:5 muted/reduced-motion
  video per phase. Downloaded files have the expected dimensions, duration and
  frame count; all six muted outputs contain zero audio tracks. V22 is 1500 frames
  / 50 seconds. Explicit Tết selection and the confirmed hundred-day numeral were
  exercised; V22 grid and final hero, dates and names were visually inspected.
  `artifacts/premium48-final/dev-smoke-qa.json` combines all results. Each phase's
  `dev-smoke/` holds output files, screenshots, `media-qa.json` and `cleanup.json`.
  All six synthetic families and their uploaded/generated Storage files were removed.
- All **14 new scores** have distinct hashes from one another and the twelve
  preceding Premium scores, with measured loudness between −18 and −14 LUFS and
  peaks below −1 dBTP; `artifacts/premium48-final/music-qa.json`.

## Limits

Dev only. Physical print quality, manual iPhone/Android acceptance and every
Light/Night state are not signed off. Photo inputs are supported; clip inputs,
voiceover/ducking and shortened missing-month exports are not implemented here.
Cards have a four-second animated app preview and export static PNG/JPEG. Music
is synthesized and remains subject to the owner's listening review.
