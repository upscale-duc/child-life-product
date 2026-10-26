# Component evolution: missing-component protocol, duplication audit, quality checklist

## 1. Missing-component protocol

### Step 1: Search

- **Code:** `core/widgets/` (and `component-catalog.md`), the showcase
  (`features/showcase/showcase_sections.dart`), the shared feature widgets (`MeRow`, `MeNotice`,
  `MediaTile`, `CareSheetFrame`…).
- **Similar screens:** the archetype references in `cl-screen-patterns` → `screen-archetypes.md`.
- **Duplicates:** `grep -rn "class .*Card\|class .*Banner\|class .*Pill" apps/mobile/lib/features`
  to see whether someone already built it, maybe under another prefix.

### Step 2: Evaluate

| The need is… | Signals |
|---|---|
| **A one-off composition** | One screen; existing pieces arranged differently |
| **A reusable pattern** | The same arrangement already exists (or is needed) in 2+ features |
| **A missing variant** of an existing component | Same purpose and interaction, a new state or option (e.g. an error line for `ClTextField`) |
| **A genuinely new component** | A purpose or interaction no component covers (e.g. a stat tile, a shared confirm sheet) |

### Step 3: Decide

- **One-off composition**
  - Compose existing widgets locally, in the screen file, as a private widget if it helps
    readability.
  - Don't abstract prematurely, and don't give it a feature prefix as if it were a kit.
- **Extending an existing component**
  - Only if the new behaviour fits the component's **purpose**.
  - Keep existing call sites working (defaults unchanged).
  - Add semantic options (`tone:`, `variant:`), not styling knobs (`radius:`, `padding:`,
    `color:`).
  - Don't add flags unrelated to the component's job.
  - Update its showcase entry and goldens.
- **A new reusable component**
  - Justify it with recurring use (2+ features) or a strong cross-feature design need.
  - One clear responsibility, a semantic API, both palettes, accessibility built in.
  - Golden coverage (Light / Night × vi / en) and a **showcase section**.
  - Lives in `lib/core/widgets/` with a `Cl` prefix. Never a new feature-prefixed kit
    (`XxCard`), and never a `Cl` class inside a feature folder (`ClRedDot` in
    `features/family/my_invites.dart` is the one existing exception and should move).
  - When **promoting** an existing feature widget (`MeNotice` → core), move it, keep the API,
    migrate imports, and keep goldens identical, or look at and accept every diff.

### Step 4: Autonomy level (`senior-ui-ux` §3, D-109)

**L1 / L2: proceed without owner approval.** This covers:

- swapping a duplicate for an equivalent component;
- promoting a feature widget to core;
- extending a component with a semantic variant;
- building a new shared component (e.g. the `ClCard` family, `ClNotice`) from **existing
  tokens**;
- migrating screens to it, even where that visibly restyles a major screen;
- interaction affordances that reach the same destinations.

**L3: ask the owner** when the change:

- needs a **new design token** or a new design-system direction (the D-106 protocol in
  `cl-design-foundations`);
- changes behaviour (what a control does, where it goes, who can use it);
- introduces a new product capability.

Show before / after goldens either way, and open every diff.

## 2. Duplication audit (read-only, 2026-10-25)

Classes:

1. **Reuse:** an existing shared component should be used.
2. **Extend:** an existing component could be extended.
3. **Future shared component:** a candidate for a new shared component.
4. **Intentional:** feature-specific by design; leave it alone.
5. **Decision needed:** requires a product or design decision.

Counts are refs / files in `features/`.

| Pattern | Implementations (refs / files) | Class | Notes |
|---|---|---|---|
| **Card foundation** | `RhCard` 51/19, `PrintCard` 34/10, `AsCard` 26/3, `NuCard` 16/8, `SpCard` 11/6, `AxCard` 10/1, `LbCard` 5/2, 43 private `_*Card` | **3** + **5** | The `ClCard` family (`card-system.md`). The radius choice (24 vs a compact radius) is an owner decision. `AsCard` (chat bubbles, fixed width) and `PrintCard` (product picker) may stay intentional (**4**) |
| **Row group container** | `SpGroup` 26/6, `LbGroup` 17/6, `NuGroup` 15/8, `MtGroupCard` 7/2, `FaGroup` 5/2 | **1** | Same job as `ClCardGroup`; they differ in radius (16 vs 24) and hairlines. Visible change, so show goldens |
| **Notice / banner** | `MeNotice` 36/14, `RhInfoBox` 26/17, `NuBanner` 17/9, `PrintNotice` 17/6, `SpBanner` 15/6, `AsNoticeCard` 11/2, `VxBanner` 7/2, `LbOfflineBanner` 4/1, `ClErrorBanner` (unused) | **3** (promote `MeNotice` → core `ClNotice`, absorbing `ClErrorBanner`) | Tones to unify: info, warn, error, + mint / neutral. `NuBanner`'s "never red" (P-163) shows tone choice is semantic |
| **Footnote** | `AsFootnote` 14/3, `RhNote` 12/7, `NuFootnote` 7/6, `SdFootnote` 5/2, `MtContentNote` 5/2 | **3** | A tiny shared footnote (`caption`, `inkMuted`, optional icon) |
| **Section heading** | `LbSection` 20/6, `NuSection` 13/7, `RhCardHeading` 7/5, `MtSection` 7/2, `NuCardHeader` 5/3, private `_SectionTitle` / `_Label` | **1** | `ClSectionHeader` (page) or `MeSection` (group label). Check which semantics each one has before swapping |
| **Page frame** | `SpPage` 22/6, `SdPage` 15/4, `LbPage` 15/5, `NuPage` 12/6, `AutoSavePage` 11/4, `MtPage` 10/2 vs `MePage` 29/15 | **2** | Several wrap feature context (scopes or providers), so promote `MePage` to core and extend it; don't merge blindly |
| **Round icon button** | `RhRoundIcon` 20/15, `KeepsakeRoundIcon` 9/3, `AsRoundButton` 8/2, `SpRoundIcon` 8/4, `FaRoundButton` 5/2, `LbRoundButton` 4/2, `MtRoundIcon`, paywall `_RoundIcon` | **3** | A core 44 pt round icon button (`ClRoundButton` is the 64 pt "next") |
| **Tinted icon chip** | `NuIconChip` 20/7, `CategoryBadge` 8/3, `RhIconTile` 7/5, `QuickActionIcon` 4/2, `MtGroupIcon`, the `AxCard` chip, the care-hub tile | **3** | Care-colour-aware icon chip; also the leading slot of interactive / insight cards |
| **Pill / chip / tag** | `SdTag` 22/5, `AsChip` 15/4, `LbChip` 14/5, `RhPill` 11/6, `SdPill` 11/4, `RhChip` 10/4, `MtChip` 9/3, `NuTag` 7/5, `FaTag` 7/2, `MtBadge`, `SpPill`, `PrintPill` | **2** (`ClChip` styles) / **4** for interactive food chips (`SdFoodChip`) | Static tags converge on `ClChip` + new semantic styles; selection chips on `ClFilterChip` |
| **Pill buttons** | `RhPillButton` 24/9, `AsButton` 24/3, `SpBottomButton` 8/5, `LbPillButton` 6/4 | **1** | `ClButton` styles cover them; check sizes |
| **Empty state** | `NuEmpty` 15/7, `LbEmpty` 14/6, assistant `_EmptyState`, history `_EmptyDay` | **1** | `ClEmptyState` (screen-level); a dashboard section's "one muted line" is a pattern, not a component |
| **Confirm sheet** | `rhConfirm` 8/5, `confirmDeleteMedia`, `confirmRemoveRecord`, `showDeleteCategorySheet`, `showDeleteBabySheet` | **3** | Promote `rhConfirm` to a core confirm helper; rich variants (media preview) compose on top |
| **Date / time picker sheet** | 13 files with `CupertinoDatePicker` / `CupertinoPicker` sheets: `pickCareTime`, `pickVxDate`, `pickMilestoneDay`, `pickReminderTime` / `Day`, `pickAssistantDate` / `Time` … | **3** | `ClDateTimeSheet` with Night-care theming built in |
| **Amount input** | `AmountInput` 10/2 (care), `SpAmountInput` 10/4, `AsAmountAsk`; `ClAmountField` unused | **2** / **5** | Decide whether `ClAmountField` (big numeral) or care's inline input is the house pattern |
| **Field error** | `_ErrorText` (care), ad-hoc elsewhere | **2** | Add an error line to `ClTextField` |
| **Spinners** | `CircularProgressIndicator` 31, `LinearProgressIndicator` 13, `CupertinoActivityIndicator` 7 | **1** | `ClSkeleton`, `ClButton(loading:)`, `withClProgress`, `ClProgress` |
| **Drag handle** | `DragHandle` (`today/today_layout.dart`), `_Handle` (spending) | **1** | `ClSheetHeader` already draws the grabber |
| **Premium components** | `PremiumGoldButton`, `PremiumInlineCard`, `_PlanCard` ×2 | **4** (`_PlanCard` ×2 → **1**) | A sanctioned separate language; dedupe only within Premium |
| **Assistant chat kit** | `AsBubble`, `AsComposer`, `AsDraftCard`… | **4** | A conversational UI with its own needs; reuse core tokens, not core layouts |
| **First aid danger UI** | `FaCallButton`, `FaCalloutBox` | **4** | Danger semantics; must not be reused for ordinary errors |

## 3. Migration candidates (priority = screens affected × visible inconsistency × maintenance ÷ risk)

| # | Candidate | User impact | Effort | Risk | First step |
|---|---|---|---|---|---|
| 1 | **Shared notice** (`MeNotice` → core `ClNotice`; banners converge) | High: about 70 notices across ~45 files look and behave differently | M | Low–Med (visual diffs) | Promote `MeNotice` unchanged, then migrate `RhInfoBox` / `NuBanner` / `SpBanner` when touched |
| 2 | **Insight / stat tile** (inside the insight card) | High: numbers become visuals (`senior-ui-ux` §5.4) on Today, stats, history | M | Low (new) | Build from stats `_Card` / `AiStateCard` anatomy; usable inside existing cards before `ClCard` exists |
| 3 | **Async state + confirm + field error** (skeleton / error-retry wrapper; promote `rhConfirm`; `ClTextField` error line) | High: invisible loading and errors (264 `.value ??` reads) | M | Low | `rhConfirm` → core first (smallest) |
| 4 | **`ClCard` family** (standard / action / insight / media) | High: every feature's main surface | L (ranked after 2–3 for effort) | Med (radius decision, many goldens) | Owner decision on the compact radius; build `standard` + `action` first |
| 5 | **`ClDateTimeSheet`** | Medium: 13 pickers with drifting Night care styling | M | Low | Generalise `pickCareTime` |
| 6 | Row containers → `ClCardGroup`; pill buttons → `ClButton`; empty states → `ClEmptyState` | Medium | S each | Low–Med | When the screen is touched |
| 7 | Icon chip + round icon button in core | Medium | S | Low | Together with #4 (the card's leading slot) |

**Migrations happen when a screen is touched for another reason, or as a dedicated batch**
(`senior-ui-ux` → `references/multi-screen-execution.md`): verified and reported, never a silent
bulk rewrite.

## 4. Quality checklist: a new or modified reusable component

**Product**

- [ ] One clear purpose that a real task needs; name it in the doc comment.
- [ ] The interaction fits the task; no controls the user doesn't need.
- [ ] Meaningful states (default, pressed, selected, disabled, loading, error, empty) as they
      apply.

**Design** (values per `cl-design-foundations`)

- [ ] Semantic tokens only; radius and spacing from the scale.
- [ ] Light and Night care both correct; no `isNightCare ? A : B` where a token exists.
- [ ] Clear internal hierarchy; no nested elevation.
- [ ] Purposeful variation via semantic variants, not styling knobs.

**Engineering**

- [ ] A small, semantic API; defaults cover the common case.
- [ ] One responsibility; no business logic or repository calls in core widgets.
- [ ] No feature assumptions (no feature models or providers) in `core/widgets`.
- [ ] No duplication of an existing core widget; promoted widgets keep their API.

**Accessibility**

- [ ] 44 pt targets (`ClPressable`).
- [ ] One readable `semanticLabel` per tappable; headers marked; decorative icons excluded.
- [ ] Wraps or grows at 200 % text; no fixed heights around text.
- [ ] Status is never colour alone.

**Verification**

- [ ] Golden tests: Light / Night × vi / en (`test/golden/`), plus disabled, loading and error
      states where applicable.
- [ ] A showcase entry (`features/showcase/showcase_sections.dart`) for core components.
- [ ] Rendered and looked at before / after; affected screens' goldens reviewed.
