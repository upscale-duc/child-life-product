# Child Life — Product Design Skill Gap Analysis

Step 2 of the Product Design Skill System, 2026-10-25. This is analysis only: no skill, CLAUDE.md,
memory or Flutter file was changed. It builds on
[design-system-discovery.md](design-system-discovery.md) (cited as *Discovery §n*).

**Goal.** MB Bank's clarity, scanability, information density and action-oriented UX, combined
with Child Life's warm, family-centred identity.

**New premise (owner, this request).** The Flutter codebase is the source of truth for the current
UI. Figma is outdated and is not required for new screens or UI improvements.

---

## 0. What was read

| Source | What it holds | Size |
|---|---|---|
| `.claude/skills/senior-ui-ux/SKILL.md` | The only design skill: one file, no `references/`, no scripts | 90 lines, 9 sections |
| `CLAUDE.md` | Figma as V1 scope and read-only source; the checklist "done" rule; i18n (D-012); "Figma copy is the Vietnamese source" | 3 UI-relevant rules |
| `docs/product/business-map.md` | Precedence ("Figma wins", line 23); R/P/Q/G taxonomy defined against Figma (lines 18–21); design decisions D-004, D-012, D-013, D-048, D-069, D-096, P-061, P-063, P-064 | 978 lines |
| `docs/product/figma-coverage-checklist.md` | Completion tracked per Figma row | 627 lines |
| Auto-memory (user-level, outside the repo) | `ui-work-as-senior-designer` (loads the skill), `ink-on-soft-warm-fills`, `no-secondary-button-in-info-notice` | 3 design-relevant memories |
| `lib/core/widgets/*.dart` doc comments | Per-widget rules (e.g. "One Primary per screen", "label is a 1–2 word verb", "Calm, no-guilt empty state"), each citing a Figma node | ~40 widgets |

Design guidance today is spread across five places: the skill, CLAUDE.md, the business map,
memories and code comments. Only the skill is loaded on purpose before UI work.

---

## 1. Existing Skill capabilities

`senior-ui-ux` is a **process skill**: a sequence a designer follows. It does not describe the
design system. It was written in response to owner feedback from 2026-10-25 (screens "như
software developer") and is strong on mindset.

| § | Capability | Coverage | Notes |
|---|---|---|---|
| 1 | **Who / when / job.** Persona and moment, the 5-second question and the next two at 30 s, one primary action and at most one secondary, button destination matches its card, role-aware states | Strong | The best section. It already carries the action-first seed. |
| 2 | **Audit by looking.** Render goldens or the simulator (vi, Light and Night care, realistic data), then a list of "usual suspects" | Strong | Doubles as a review checklist (§9 reuses it). |
| 3 | **Hierarchy.** One hero; 2–4 sections with plain headings; order by urgency; group rows in one `ClCardGroup`; hide empty sections; progressive disclosure | Medium | Principles only: no screen templates, spacing rhythm or type-role mapping. |
| 4 | **Numbers become visuals.** Stat tiles, compared-with-usual, relative time, 24 h strip, 7-day bars, progress; warm palette for attention; never colour alone | Strong, unique | The most MB-Bank-aligned guidance. No component backs it (no `ClStatTile`; *Discovery §6.2*). |
| 5 | **Copy.** Parent's words; banned engineering words; labels are states and buttons are verbs (1–3 words); ARB for every string; Figma copy wins | Thin | Principles with five example words. No glossary, CTA lexicon, length budget or placeholder rules. |
| 6 | **States.** Loading, empty, error/offline, partial, health day, no permission, first run, long names, 3+ babies, en | Medium | A complete *list* with no *patterns*: it doesn't say which component or layout each state uses. |
| 7 | **Build with the design system.** `Cl*` and `context.cl` only; `ClSpace` / `ClRadius` / `ClIcons`; Night-care ink rule; tabular numbers; 44 pt; semantics labels | Thin | One paragraph. No component catalogue, no rule for choosing a component, no "what if the component doesn't exist". |
| 8 | **Mockup before code.** Check Figma; otherwise an HTML mockup plus 3–5 bullets, then owner OK | Medium | Depends on Figma first. |
| 9 | **Verify as an image.** Goldens Light + Night × vi + en, look before committing, re-run §2, report before → after | Strong | No rubric, severity or pass bar. |

**Already covered, so the new system must not restate it:**

- the job and 5-second framing;
- render-and-look;
- "numbers become visuals";
- one hero and urgency order;
- progressive disclosure;
- warm palette for attention;
- never colour alone;
- the states list;
- goldens across the 4-way matrix;
- the before → after report.

---

## 2. Missing design capabilities

Each gap is rated by its impact on the goal and on the problems found in *Discovery*.

### 2.1 UX Writing — **gap: large**

The skill has five banned words and three principles. *Discovery §7* found these are not covered:

- **Glossary of canonical terms.** A care entry has 6 variants, family 3, reminders 2, the
  assistant 3 and the caregiver role 3. No rule picks one.
- **CTA lexicon.** One string and one shared ARB key per intent: Xong / Lưu / Thử lại / Để sau /
  Tiếp tục / Xoá / Hoàn tác. Today there are 802 redundant keys and drift such as Continue vs
  Resume and four renderings of "Chọn".
- **Length budgets** per slot: title, subtitle, body, notice, toast, button, push. Today's p90s
  are emergent (*Discovery §7.4*), and 507 strings have two or more sentences.
- **Placeholder semantics.** `{baby}` vs `{name}` vs `{who}`; `{name}` currently means three
  different people.
- **When an explanation goes behind a tap.** "Tìm hiểu thêm" versus inline. Some legal and trust
  copy must stay inline.
- **System-word list with replacements.** The skill bans "bản ghi" but ARB still has "đồng bộ",
  "dữ liệu", "offline" and "xác nhận" on main surfaces, and the skill offers no replacement words.
- **Tone by context.** Calm default, celebration (milestones only), error, health/danger,
  Premium and night-time.
- **English rules.** US vs UK spelling (both used today) and sentence case. The skill is
  vi-only.
- **Vietnamese orthography.** "Xoá" vs "Xóa", "Huỷ" vs "Hủy".
- **ARB authoring.** Key naming for new features, required `@description` content (who
  `{name}` is), and when to reuse a key versus mint a new one.

### 2.2 Content hierarchy — **gap: medium**

The principles exist in §3; the means of carrying them out do not:

- a **type-role map** (which `cl.text.*` style is the hero, section title, row title, meta,
  value or footnote);
- a maximum number of text levels per card;
- a rule for an eyebrow or subtitle above a title.

Without these, implementers invent 15 pt and 13 pt styles (232 literal uses) and `w700` (213),
per *Discovery §4.1*.

### 2.3 Scan-first design — **gap: large**

Only the 5-second question exists. MB Bank-style scanability needs explicit rules:

- **One fact per line.** Label on the left, value on the right edge (the `_LabelValue` pattern
  already exists in `cl_rows.dart`).
- **Leading identity.** A care-colour icon chip from `ClCareColors` in the same position on every
  row.
- **Status at a fixed edge.** Chip or right-aligned value, never mid-sentence.
- **Numbers aligned and tabular.**
- **Truncation and wrap rules** for vi and en.
- **Repeated structures look identical** across features. Today each feature's kit differs
  (*Discovery §5.3*).
- **A "squint test" in review.** Hide the text and check that the structure still reads.

### 2.4 Action-first UX — **gap: large**

The skill offers one rule: one primary action, at most one secondary, label names the
destination. Missing:

- **Placement.**
  - A sticky bottom action bar versus an inline button.
  - The thumb zone (the `ClButton` doc mentions it; the skill does not).
  - The dock "+" (`ClTabDock` / `ClDockAction`).
- **Actions inside dashboard cards.**
  - The "one primary per screen" rule doesn't fit a dashboard of action cards.
  - Each card needs one obvious tap target, plus at most a link in its header.
- **Quick-action grids.** When to show them, how many, and their order (MB Bank's "chức năng
  thường dùng"). `TodayQuickActions` exists but is hidden by default.
- **Undo versus confirm.**
  - The code already prefers undo toasts (`ClToaster`) and confirm sheets (`showClSheet`), but no
    rule says when each applies.
  - Destructive actions: `ClButtonStyle.destructive` versus sheet confirmation.
- **Next-best-action.**
  - After saving: toast + undo, then where the user lands.
  - Empty states as invitations (in §6, but with no pattern).
- **Row-level actions** (chevron, trailing button, swipe via `Dismissible`) and when each is
  allowed.

### 2.5 Information density — **gap: large (new dimension)**

Not addressed at all. MB Bank's density comes from consistent compact rows and grouped lists, not
from smaller text. The skill needs:

- **Density modes** per surface:
  - dashboard: compact and scannable;
  - detail: comfortable;
  - flow/form: spacious, one question per screen in onboarding.
- **Row height ladder.** `ClDetailRow` / `ClInfoRow` 56, `ClListRow` 60, compact 44–48 (needs
  an owner decision).
- **Above-the-fold budget.** How many sections or facts the first viewport must show on a 375 ×
  812 phone.
- **Card versus row.** Use a row in a `ClCardGroup` unless the item has its own visual (photo,
  chart, illustration). This is the rule that stops "one card per row" sprawl.
- **Padding and gap ladder tied to tokens.** Today 2 / 6 / 10 / 14 / 20 are used as literals
  (*Discovery §4.2*).
- **Minimum text size.** 9–11 pt is used about 83 times.

### 2.6 Screen composition — **gap: large**

There are no screen archetypes. Each new screen starts from a blank page, or from whichever
feature kit the implementer last saw, which is how about 15 parallel kits formed. Needed:

- **Archetypes** with their frame, section rhythm and components:
  - tab dashboard (`ClPinnedHeaderScaffold` + `BabyHeader`);
  - detail page;
  - history/list;
  - sheet form (`CareSheetFrame`);
  - multi-step flow (`ClTopBar` + `ClProgress`);
  - gallery;
  - insight/report;
  - settings (`MeRow` / `ClDetailRow` groups);
  - Premium surface (the sanctioned dark exception).
- **Section rhythm.** A fixed gap between sections and between header and content (today s2–s6
  switch per section in `today_screen.dart`).
- **Hero types:** stat hero, status hero, illustration hero, photo hero.
- **Reference implementations.** "Copy this screen" pointers to the cleanest existing code, e.g.
  `onboarding/setup_screens.dart` (0 literals), `care/care_sheets.dart` `CareSheetFrame`, and
  `care/stats_screens.dart`.

### 2.7 Independent screen design without Figma — **gap: blocking**

§8 starts with "Check Figma", and §5 says Figma copy wins. Under the new premise, the skill
offers no way to design without Figma. Needed:

- **Code-as-source lookup order:**
  1. the existing screen;
  2. the nearest archetype;
  3. the reference implementation;
  4. its goldens;
  5. the `showcase` feature (`lib/features/showcase/`) for components.
- **Mockup medium.** A Flutter golden can be the mockup: render a throwaway golden with real
  `Cl*` widgets and realistic vi data. It is truer than an HTML mockup and costs about the same
  [assumption: worth piloting]. HTML or an inline visual stays for quick layout options.
- **Decision recording without Figma.**
  - Today the business map defines R-xxx as "stated in Figma" and G-xxx as "a state Figma does
    not draw".
  - A screen designed in code needs a decision record that cites code paths and golden images
    instead of Figma node ids.
- **Threshold for owner sign-off.**
  - Today it is "anything bigger than a label".
  - A threshold based on scope is needed: new screen / new pattern / changed hierarchy → mockup
    first; component swap or copy within the glossary → build directly.

### 2.8 Design quality review — **gap: medium**

§2 and §9 give a suspects list and "look at the image". Missing:

- **A rubric with pass/fail bars:**
  - scanability (5-second answer visible above the fold);
  - action clarity (one obvious next step);
  - density;
  - copy (glossary, budget, no system words);
  - states coverage;
  - system conformance (no new literals or off-kit widgets);
  - accessibility (200 % text, 44 pt, semantics, contrast, colour-not-alone);
  - Night care;
  - en overflow;
  - role variants.
- **Severity levels** (blocker / should-fix / polish) and a report format with before → after
  images.
- **A mechanical conformance check.** A diff-scoped grep or script for new `Color(0x`,
  `fontSize:` literals, `circular(<literal>)`, `showModalBottomSheet`, `CircularProgressIndicator`
  and `Icons.`. This complements visual review and is what keeps *Discovery §9* from regrowing.
- **A review mode for existing screens** (audit without change), which is what the owner's
  "không tốt" reports need.

### 2.9 Supporting gaps found along the way

- **Component selection.**
  - The skill says "use `Cl*`" but gives neither a catalogue nor a decision table (which row,
    card, chip or banner).
  - It has no "component missing" protocol: promote or extend a core widget, versus build
    locally. This is the root cause of the feature kits (*Discovery §5.3*).
- **Async-state pattern.** The skill lists states, but the codebase reads `.value ??` 264 times
  and `.when` 7 times. The guidance must say *how*: an async wrapper, a skeleton shaped like the
  content, error with retry.
- **Design-system rules held only in memory.** "`ink` on soft warm fills" and "no secondary button
  in an info notice" live only in user auto-memory, so a teammate's machine or a cloud session
  doesn't see them.
- **Platform scope.** The description claims "mobile app, portal, landing", but the content is
  Flutter-only (`Cl*`, Night care, goldens). The portal (React/Tailwind) and landing have no
  equivalent guidance.

---

## 3. Conflicting instructions

| # | Instruction A | Instruction B | Effect | Resolution needed |
|---|---|---|---|---|
| C1 | **New premise:** Flutter code is the UI source of truth; Figma is outdated | `CLAUDE.md` "Final Figma … is the V1 scope", "Figma copy is the Vietnamese source"; business-map line 23 "**Figma wins**"; R-nnn "Stated in Figma … Implement as written"; skill §5 "Figma copy is the source when it exists", §8 "Check Figma" | The agent is told to treat Figma as authoritative in four places, and the premise exists only in this request | **Owner decision (D-xxx)** recorded in business-map, then edits to CLAUDE.md and the skill. Scope question: does Figma remain the *V1 scope* list (what features exist) while code becomes the *visual and copy* authority? Recommended: yes, split "scope" from "look and copy". |
| C2 | Skill §5: "Copy that differs from Figma is an owner decision: record it in business-map" | New premise (Figma not required) | No rule for when a copy change needs the owner | Replace with: copy changes against the **glossary and lexicon** are free; changes to canonical terms, legal/consent copy or tone need the owner. |
| C3 | `figma-coverage-checklist.md` and CLAUDE.md "never mark a Figma row done unless …" | Screens designed without Figma | New or redesigned screens have no row, so "done" is undefined | Keep the checklist for V1 scope; define "done" for code-designed screens (goldens in the 4-way matrix + review rubric pass). |
| C4 | Business-map G-nnn: engineering states are "never counted as Figma-complete until reviewed" | New premise | States designed in code stay "incomplete" forever | Redefine G-nnn review as a design-review rubric pass. |
| C5 | Skill §7: "spacing `ClSpace`, radius `ClRadius`" (strict) | Token scales lack 2 / 6 / 10 / 14 / 20 spacing and 14 / 16 / 20 radius, which are used about 850 times (*Discovery §9.2*) | The rule can't be followed for common layouts, so it is ignored: literals and `card - 6` arithmetic | Token additions (owner-approved, through `tokens.json`) **or** a written "nearest token" rule. Decide before any skill bans literals. |
| C6 | Skill §1: "one primary action, at most one secondary" per screen; `ClButton` doc "One Primary per screen" | Dashboard and Today screens are composed of action cards; MB Bank's model is many quick actions | It is unclear whether a card's tap target counts as an action | Scope the rule: one *filled primary button* per screen or sheet; cards and rows are tappable surfaces, each with one destination. |
| C7 | Skill §5: buttons are verbs of "1–3 words" | `ClButton` doc (`cl_button.dart:19`): "1–2 word verb" | Minor | Pick one (recommended: 1–3, matching vi reality, e.g. "Lưu thay đổi"). |
| C8 | Skill §3: "Hide empty sections **or** give them one short muted line" | Skill §6: empty state is "an invitation, not an apology"; `ClEmptyState` = icon + headline + sentence + action | Three options, no rule | Rule by surface: dashboard section → hide or one muted line; a screen whose whole content is empty → `ClEmptyState`. |
| C9 | D-096: page cards are `surface` + `shadow-card` "in every feature", following the Care cards | Skill §3 "group, don't list: rows in one `ClCardGroup`"; the feature kits use radius 20 / 16 / 14 citing Figma frames | D-096 unified elevation but not radius or padding; the kits remain | The component skill should extend D-096 to one `ClCard` spec (radius, padding, elevation). This is an owner decision because it changes pixels. |
| C10 | Skill description: "mobile app, portal, landing" | Skill body is Flutter-only | Portal work loads irrelevant `Cl*` rules | Narrow it to Flutter; keep portal guidance separate (out of scope for now). |
| C11 | Memory `ui-work-as-senior-designer` restates the skill's steps | The skill itself | Two copies of the same guidance (risk of drift) | The memory should only *point to* the skill, not paraphrase it. |
| C12 | Memories `ink-on-soft-warm-fills`, `no-secondary-button-in-info-notice` | Skill §7 states only the first, in one line | Design-system rules split between repo and user memory | Move both into the foundations/components skill (repo-versioned); trim the memories to pointers. |
| C13 | Widget doc comments cite Figma nodes as justification (e.g. `ClOptionRow` "Figma uses Inter 12 by mistake") | New premise | Harmless history, but it signals Figma authority | No change needed; the skills should say comments are history, not authority. |
| C14 | Skill §5 bans "xác nhận" where a plain verb works | ARB has 37 "xác nhận", 19 "đồng bộ", 19 "bản ghi" | The rule isn't applied to existing copy | Not an instruction conflict: it is debt. The UX-writing skill decides whether to migrate. |

C1 is the only blocker. C5, C6 and C9 need owner decisions before rules are written. The rest are
editorial.

---

## 4. Recommended Skill architecture

### 4.1 Options considered

| Option | Pros | Cons |
|---|---|---|
| **A. Extend `senior-ui-ux` into one large skill** (SKILL.md + `references/`) | One trigger; nothing to route; progressive disclosure via references | The always-loaded body grows; a copy-only or review-only task loads everything; one owner of everything; harder to trigger on "review this screen" or "fix this string" alone |
| **B. Replace with five independent skills** | Narrow triggers | Loses the process spine the owner asked for; risk that no skill or the wrong one triggers on "add a section"; duplication of the framing steps |
| **C. Hybrid: `senior-ui-ux` stays the entry point and process spine, plus five specialised reference skills it routes to** | Keeps the owner's standing workflow and memory trigger intact; each rule lives in one place; specialised skills can also trigger alone (copy-only, review-only); small always-loaded footprint | Six skills to maintain; cross-references must stay correct |

**Recommendation: C (hybrid).** It evolves rather than replaces. The owner's established trigger
(memory + skill name) keeps working, and the five Step 1 skill areas become the reference layer.

### 4.2 Shape

```
senior-ui-ux  (entry · process spine · always first for any UI change)
 │  frame the job → find the pattern → write → build → review → record
 │
 ├── cl-design-foundations    tokens, colour pairs, type roles, spacing/radius ladders,
 │                            elevation, motion, Night care, a11y minimums
 ├── cl-components            catalogue, selection tables, missing-component protocol,
 │                            migration map from feature kits
 ├── cl-screen-patterns       archetypes, composition, scan-first, density, action-first,
 │                            states as patterns, code-as-source lookup  ← the "MB Bank" layer
 ├── cl-ux-writing            glossary, CTA lexicon, length budgets, tone, placeholders,
 │                            vi/en rules, ARB authoring
 └── cl-design-review         rubric, severity, 4-way image check, conformance script,
                              audit-only mode, report format
```

Names are proposals. A `cl-` prefix ties them to the `Cl*` system and keeps them sorted together.

### 4.3 Structural conventions for all six

- **Small SKILL.md, detailed `references/`.**
  - Each SKILL.md holds when-to-use, the 5–10 rules that are always needed, and links.
  - Catalogues, tables and examples go in `references/*.md`, loaded on demand.
  - This keeps context cost low when several skills load at once.
- **Single home per rule.** A rule appears in exactly one skill; the others link to it. A
  "Where rules live" table in `senior-ui-ux` is the index.
- **Code is cited, not copied.** Skills point to `lib/core/widgets/…` and reference screens by
  path, so when code changes the skill stays valid. Avoid pasting widget source.
- **Every rule is checkable,** either visually (goldens) or mechanically (a grep in
  `cl-design-review`).
- **Flutter-scoped.** Portal and landing are out of scope until a separate effort.

---

## 5. Proposed responsibilities for each Skill

### 5.1 `senior-ui-ux` (evolve; stays the entry point)

**Keeps:**

- §1 job / 5-second framing;
- §2 render-and-look;
- §3 hierarchy principles;
- §4 numbers become visuals;
- §9 verify-as-image (trimmed to "run `cl-design-review`").

**Changes:**

- §8 becomes code-first:
  1. find the existing screen, archetype and reference implementation;
  2. make the mockup (golden or HTML);
  3. owner sign-off by threshold.
- Figma becomes optional historical reference.

**Moves out:**

- §5 copy → `cl-ux-writing`;
- §6 states → `cl-screen-patterns`;
- §7 build → `cl-design-foundations` and `cl-components`;
- the §2 suspects list → `cl-design-review`. §2 keeps only "render first".

**Adds:**

- the routing table (§6.2 below);
- the sign-off threshold;
- the decision-recording rule (D-xxx with code and golden paths, no Figma id needed).

**Trigger:** any screen, card, sheet, copy or number change, or an owner "không tốt" report.
This is the current description, narrowed to Flutter.

### 5.2 `cl-design-foundations`

**Owns:**

- **Colour.** Token roles and **safe pairings**: `ink` on `…Soft`, `onWarm` only on bright
  warm fills, `mint` never under text, `error` versus `danger`, care colours. Includes the rules
  now held only in memory.
- **Type.** A role map from `cl.text.*` to hierarchy levels, a weight policy, a minimum size,
  and `ClTabularText` for anything that changes.
- **Spacing and radius ladders.** Either the approved token additions or a "nearest token" rule
  (C5).
- **Icon sizes.**
- **Elevation.** D-096; Night care flat.
- **Motion and haptics.** Pointers to `motion.dart` / `haptics.dart` and D-048 — reference, not
  restatement.
- **Night care behaviour.**
- **Accessibility minimums:** 44 pt, 200 % text, contrast, semantics.
- **The Premium palette exception** (`premium_style.dart`): where it is allowed and where not.
- **Token change procedure:** `tokens.json` → `generate.ts` → Dart + CSS; never edit
  `tokens.g.dart` by hand.

**Does not own:** which widget to use (components) or screen layout (patterns).

### 5.3 `cl-components`

**Owns:**

- **The catalogue** of core `Cl*` widgets and the de facto shared feature widgets (`MeRow`,
  `MeNotice`, `MediaTile`, `CareSheetFrame`, `SavedBabyAvatar`, `BabyHeader`). Each entry has
  purpose, variants and when not to use it, pointing to source and showcase.
- **Selection decision tables:**
  - row (`ClDetailRow` / `ClOptionRow` / `ClListRow` / `MeRow`);
  - container (`ClCardGroup` / card / notice);
  - feedback (toast / notice / sheet / `withClProgress`);
  - chip or tag;
  - button style.
- **Missing-component protocol.**
  - Before writing a private widget, check the catalogue.
  - If the need recurs (2+ features), extend or promote into `lib/core/widgets` with a golden
    and a showcase entry.
  - Never start a new feature-prefixed kit.
  - Promotion candidates from *Discovery §9.1*: `ClCard`, `ClNotice` (from `MeNotice`),
    `ClStatTile`, `ClIconChip`, `ClTag`, `ClDateTimeSheet`, an async wrapper, `ClMediaGrid`.
- **Migration map** from feature-kit widgets (`RhCard`, `NuBanner`, `SpPill` …) to their core
  replacement. It is used when a screen is touched for other reasons ("boy-scout" migration),
  never as a bulk rewrite.
- **Known traps:** secondary button on an info notice; `showModalBottomSheet` /
  `AlertDialog` / `SnackBar` / raw spinners are off-system.

### 5.4 `cl-screen-patterns` (the MB Bank layer)

**Owns:**

- **Code-as-source lookup.** Existing screen → archetype → reference implementation → goldens →
  showcase.
- **Screen archetypes** (dashboard, detail, history/list, sheet form, flow, gallery,
  insight/report, settings, Premium), each with:
  - the frame widget;
  - the section rhythm;
  - the allowed hero types;
  - the action placement;
  - a reference screen path.
- **Scan-first rules** (§2.3 of this document), **density rules** (§2.5) and **action-first
  rules** (§2.4), including the scoped "one primary" rule (C6) and undo versus confirm.
- **Composition.**
  - Section order by urgency for the reader's role.
  - Above-the-fold budget.
  - Card versus row.
  - Empty sections (C8).
- **States as patterns.**
  - Each of the skill §6 states mapped to its layout and component.
  - The async-wrapper usage.
  - Offline and sync presentation in plain words.
- **Data-visual patterns.** A home for "numbers become visuals" *implementation*: stat tile, range
  bar, 24 h strip, 7-day bars, relative time. The *principle* stays in `senior-ui-ux` §4.
- **Dual-path awareness.** Legacy Today versus adaptive `AxCard`; NavBar v1 versus v2. Patterns
  must hold in both until one is retired.

### 5.5 `cl-ux-writing`

**Owns:**

- **Glossary.** Canonical vi/en term per concept, with banned variants: entry/log, family,
  reminder, assistant, roles, memories, Premium/plan, link, sync. These are owner-approved
  (C2).
- **CTA lexicon** with **shared ARB keys** (reuse `actionDone` and similar; never mint
  `xxDone`).
- **Length budgets** per slot, and when copy goes behind "Tìm hiểu thêm".
- **Title, subtitle and body patterns.** Question titles allowed where the screen asks;
  sentence case in en; no trailing period in titles.
- **System-word replacements** (đồng bộ, dữ liệu, bản ghi, offline, xác nhận → plain verbs and
  states). "Labels are states, buttons are verbs" moves here from skill §5.
- **Tone matrix:** default calm, celebration, error, health/danger, night, Premium. Address forms
  ("bạn", "nhà mình", "bé" versus "con", "ba mẹ").
- **Personalisation.** Placeholder semantics (`{baby}` for the child, `{name}` never ambiguous,
  `{who}` for actors), `@description` must state who; when to use the child's name versus "bé".
- **Numbers and dates in copy:** units attached, "Hôm nay" / "Hôm qua", `24/10`, relative then
  clock. Formatting helpers live in `lib/core/format/`.
- **Orthography.** vi tone-mark placement; en US or UK (owner choice).
- **ARB authoring.** Key prefix naming for new features, vi template first, en parity,
  `glance_copy.dart` constraints (no plurals), `pnpm`/`flutter gen-l10n`.
- **Migration stance.** Existing duplicates and variants are fixed when touched, with owner review
  for canonical-term changes, not in bulk.

### 5.6 `cl-design-review`

**Owns:**

- **Rubric** (the dimensions in §2.8), each with a pass bar and a severity of blocker /
  should-fix / polish. Blockers include:
  - no 5-second answer above the fold;
  - two numbers in a sentence;
  - a system word on a main surface;
  - colour-only meaning;
  - Night care unreadable;
  - en overflow or clipping at 200 %;
  - a new off-system widget or literal.
- **Image protocol.**
  - Goldens Light / Night × vi / en with realistic fixtures.
  - Plus a 200 % text-scale render and a long-name / 3-baby render for screens that show names.
  - Before → after pairs in the report.
- **Mechanical conformance check.** A diff-scoped grep or script over changed lines only (new
  `Color(0x`, `fontSize: <n>`, `circular(<n>)`, `FontWeight.w700`, `showModalBottomSheet`,
  `AlertDialog`, `SnackBar`, `CircularProgressIndicator`, `Icons.`, `Text('…')` with letters).
  Ratchet: existing debt is not a failure; new debt is.
- **Audit-only mode.** Review an existing screen without changing it and output findings ranked
  by severity. This is for owner "không tốt" reports and future discovery passes.
- **Report format** to the owner: images first, then findings, then what changed.

---

## 6. How Skills should work together

### 6.1 Standard flow for a UI change

```
1 Frame      senior-ui-ux §1        who / moment / 5-second question / next action / role
2 Look       senior-ui-ux §2        render current screen (goldens or simulator), vi, Light + Night care
3 Find       cl-screen-patterns     existing screen → archetype → reference impl → goldens
             cl-components          pick components from the selection tables; missing → protocol
4 Sign-off?  senior-ui-ux §8        above threshold → mockup (golden or HTML) → owner OK
5 Write      cl-ux-writing          glossary, lexicon, budgets, ARB keys (vi first, en parity)
6 Build      cl-design-foundations  tokens, type roles, safe pairs, a11y minimums
7 Review     cl-design-review       conformance script + 4-way images + rubric; iterate on blockers
8 Record     senior-ui-ux           D-xxx in business-map when a pattern, term or token changes
```

Steps 3–6 load only the references they need. A simple component swap may skip step 4.

### 6.2 Routing table (lives in `senior-ui-ux`)

| Task | Load |
|---|---|
| New screen, or a redesigned screen or section | `senior-ui-ux` → patterns → components → writing → foundations → review |
| "Add a section / card" to an existing screen | `senior-ui-ux` → patterns (composition, density) → components → writing → review |
| Copy-only change (ARB, push or notification text, toast) | `cl-ux-writing` → review (copy dimensions only) |
| Visual fix (colour, spacing, Night care bug) | `cl-design-foundations` → review |
| New or changed reusable widget in `lib/core/widgets` | `cl-components` → foundations → review (+ showcase + goldens) |
| Owner reports a screen is "không tốt" / hard to read | `senior-ui-ux` → `cl-design-review` audit mode → then the full flow |
| Code review of a UI diff | `cl-design-review` |
| Non-UI change (repository, rules, functions) | none |

### 6.3 How Claude Code should apply this automatically

Five layers, from softest to strongest. Layers 1–3 are recommended now; 4–5 are later and
optional.

1. **Skill descriptions (model-triggered).**
   - `senior-ui-ux` keeps a broad description: any Flutter screen, card, sheet, copy or number
     change.
   - Specialised skills get narrow descriptions so they can trigger alone:
     - `cl-ux-writing` on ARB / copy edits;
     - `cl-design-review` on "review / audit / không tốt";
     - `cl-components` on edits under `lib/core/widgets`.
   - Descriptions name file paths (`apps/mobile/lib/features/**`, `lib/l10n/*.arb`) to improve
     matching.
2. **CLAUDE.md pointer** (owner-approved edit, a later step). Add one line under Conventions:
   "UI work in `apps/mobile` (screens, widgets, ARB) starts with the `senior-ui-ux` skill; it
   routes to the `cl-*` skills."
   - Plus the C1 precedence change: Figma = V1 feature scope, code = look and copy.
   - CLAUDE.md is always loaded, so this is the most reliable trigger and the only one that
     reaches teammates and cloud sessions. The user-level memory does neither.
3. **Memory hygiene.**
   - Trim `ui-work-as-senior-designer` to a pointer.
   - Move `ink-on-soft-warm-fills` and `no-secondary-button-in-info-notice` content into
     `cl-design-foundations` / `cl-components`, leaving pointers (C11, C12).
4. **Hook (optional).** A `PreToolUse` hook on `Edit|Write` matching
   `apps/mobile/lib/**/*.dart` or `*.arb` injects a one-line reminder to load `senior-ui-ux` if
   not already loaded this session.
   - It is deterministic, but the reminder fires on non-UI Dart edits too.
   - Recommended only if layers 1–2 prove insufficient.
5. **Mechanical gate (optional, later).** The `cl-design-review` conformance script runs in
   `pnpm`/CI or as a `PostToolUse` hook over the diff, failing on *new* literals and off-system
   widgets.
   - This is the only layer that enforces without relying on the model remembering.
   - It should ratchet, never fail on existing debt.

---

## 7. Recommended implementation order

**Step 0 — owner decisions (prerequisite; no skill text until these are settled).**

1. **C1 precedence.** Figma stays as the V1 *feature scope*; Flutter code becomes the authority
   for *look and copy*. Recorded as a D-xxx, which unblocks CLAUDE.md and business-map edits.
2. **C5 tokens.** Add radius 14 / 16 / 20 and spacing 2 / 6 / 10 / 14 / 20 (and type 15 / 13),
   or adopt "nearest token". This decides whether foundations can ban literals.
3. **C6 and C9.** The scoped "one primary" rule, and a single `ClCard` spec (extending D-096).
4. **Glossary seed.** Canonical terms for the five most-split concepts (entry, family, reminder,
   assistant, caregiver). The owner owns the wording.
5. **Text-scale / tablet policy** (*Discovery §2.4*). Can be deferred; patterns note it as open.

**Then, in order:**

| # | Work | Why this position | Depends on |
|---|---|---|---|
| 1 | **Restructure `senior-ui-ux`**: code-first §8, routing table, sign-off threshold, decision recording; move-outs marked as "→ see cl-…" stubs | Unblocks Figma-free work immediately; establishes the index that prevents duplication | Step 0.1 |
| 2 | **`cl-design-foundations`** | Everything else cites tokens, type roles and safe pairs; absorbs the memory-only rules | Step 0.2 |
| 3 | **`cl-components`** (catalogue + selection tables + missing-component protocol; migration map) | Stops new feature kits forming, the root cause of most *Discovery* gaps | 2 |
| 4 | **`cl-ux-writing`** (can run **in parallel** with 2–3) | Independent of tokens and widgets; highest copy debt; needs the owner's glossary | Step 0.4 |
| 5 | **`cl-screen-patterns`** | The MB Bank layer; composes components, tokens and copy rules, so it is written after them | 2, 3, 4 |
| 6 | **`cl-design-review`** (rubric + conformance script + audit mode) | Written last because it checks against all the others; the script can be prototyped earlier | 2–5 |
| 7 | **Pilot on one screen** (recommended: Today, in both legacy and adaptive paths), using audit mode then the full flow, with before → after goldens | Validates the system end-to-end before wider use; exposes rule conflicts | 1–6 |
| 8 | **Wire automatic application**: CLAUDE.md pointer, memory trims; optional hook / CI ratchet | Only after the skills have proven themselves on the pilot | 7, owner OK |

Promoting the core components (`ClCard`, `ClNotice`, `ClStatTile` …) is **code work**, not skill
work. It should follow step 3, one component at a time with goldens, but that is outside this
skill-design track.
