# Proposal — Hôm nay (Adaptive) v2 · 2026-10-25

**Status: PROPOSAL, awaiting owner approval. Nothing here is implemented.** It was produced with
the six design skills (`senior-ui-ux` → `cl-design-review` → `cl-screen-patterns` →
`cl-components` → `cl-ux-writing` → `cl-design-foundations`). Every proposed layout below is a
**Design hypothesis — not visually verified** until Step 9C renders it.

---

## 1. Executive summary

**Today Adaptive already does the hard part well:**

- the care tiles answer "what happened last" at a glance;
- the Adaptive engine orders content by age, goals, usage and recency;
- Night care is calm.

**Its problems are presentation and trust problems, not missing features:**

1. **Reminder status and time are cut off** in vi and en ("còn 2 n…", "yesterday 18:…"), even for
   overdue items. (R)
2. **While data loads, the tiles can say "Chưa có"** ("none yet"), and the greeting can read
   "Chào buổi chiều, ". (C)
3. **Ranked widgets are drawn with inconsistent weight:**
   - a filled primary button inside the first card on 1–3 ("Thêm khoảnh khắc");
   - a large empty placeholder on 3–6;
   - a button inside almost every card on 6–12.

   The eye lands on buttons and placeholders, not on what is happening. (R)
4. **The same things have different names:** "Nhắc nhở" (adaptive) vs "Nhắc việc" (legacy and
   list); "Nhịp hôm nay" vs "Ghi nhanh" for the same tiles; three link labels. (R)
5. **Overdue is error red here** but warm yellow on Bàn giao. (R)

**Proposed outcome: "Adaptive Briefing" (Direction B, with A's care core and C's warmth in
memories).** It keeps the Adaptive order exactly as ranked and gives every widget one calm anatomy:

- a title with a count;
- up to three readable rows;
- one link;
- whole-row taps;
- empty widgets collapsed to a single invitation row.

It shows attention items calmly, never shows loading as empty, and changes no ranking, logging,
reminder, permission, sync or entitlement behaviour.

---

## 2. User jobs and context

| | |
|---|---|
| **Who opens Today** | **Parents and co-parents** (all widgets). **Caregivers:** care widgets only, their own arrangement (D-097 Q-092); they log but don't manage reminders. **Relatives:** Today only with daily-care access (D-018), read-only (`readOnly` hides logging, reminders and quick actions, `today_screen.dart:67`). Several children: the header switcher changes the whole world (plan §1.2 #5) |
| **Moments** | Just woke up ("did the night go OK?"); holding the baby, one thumb, to log a feed; 3 a.m. in Night care; before handing over to a carer; checking what's due today; a quiet moment to look at recent photos |
| **Primary job** | **Know where this child's care stands right now, and act on it in one tap**: log the next thing, or deal with what's due |
| **Five-second understanding** | (1) the last feed, sleep and diaper and how long ago (or what is running now); (2) whether anything is overdue or due soon; (3) where to tap to log |
| **Next action** | Log a care event (tile tap or the dock "+"), or open the overdue reminder |
| **Secondary goals** | Recent memories; growth and vaccines; spending; family duty ("Ai đang trông bé", P-181); suggestions (Dành cho bé); customising Today; discovery for older children |

---

## 3. Current-state assessment

### 3.1 Evidence

| Source | Inspected |
|---|---|
| Code | `today_screen.dart` (data reads :70, `sectionParts`, `lead` spacing, P-181 care duty), `today_adaptive.dart` (`AdaptiveGreeting` :60-130, `AxCard` :138), `adaptive_engine.dart` (`WidgetId`, `bandDefaults`, `RankWeights`, `defaultVisible`, `rankToday`), `reminders/reminder_screens.dart` (`ReminderPeek` :1609, overdue colour :549, :588) |
| Rendered (current; `ax10_today_0_1 light vi` re-run against the code: **passes**, so the goldens match the working tree) | `ax/ax10_today_0_1` (light vi, nightCare vi / en), `ax11_today_1_3_light_vi`, `ax12_today_3_6_light_en`, `ax13_today_6_12_light_vi`, `ax40_first_0_1_light_vi`; legacy `s4/19_today_light_vi`, `s4/9a_today_offline_light_vi` |
| Decisions | D-097 (+ plan §1.2 principles), D-105, D-096, D-018, D-069, P-181 |
| **Not evaluated** | Text scale, long names, small phones, screen reader, motion, devices; adaptive offline / pending (no `ax` golden); caregiver / relative adaptive renders |

**What changed since the Step 8 review:**

- Another session's uncommitted edits (owner feedback 2026-10-25) removed the everyday greeting
  sub-line and tightened the gap under the header.
- They place "Ai đang trông bé" at its ranked position.
- The Customize list now uses the same ranking signals as Today.

None of this resolves TA-1 … TA-8. **That work is still in progress in the shared tree;
implementation must be sequenced after it lands.**

**Fixture caveats:**

- `ax11`–`ax13` show "Teddy · 3 tuần" for older bands;
- memory thumbnails render as grey boxes (no image bytes);
- the first-run `ax40` has reminders.

Layouts are judged, not data combinations.

### 3.2 Known findings re-checked

| ID | Still present? | Cause | Impact | Resolution | Owner decision? |
|---|---|---|---|---|---|
| TA-1 reminder time truncation | **Yes** (R `ax10` vi / en, `ax13` vi) | `ReminderPeek(ax: true)` puts title and status / time on one line; the status column ellipsises | Can't read when or how overdue | Two-line rows: title, then status · time (never ellipsised) | No (routine) |
| TA-2 loading as empty | **Yes** (C `today_screen.dart:70` `recentRecordsProvider(…).value ?? const []` → `todayTileEmpty` "Chưa có") | Async values read with an empty default | A parent may think a log is missing and log twice (H: visibility depends on cache speed) | Tile skeletons until the first value resolves | No (routine) |
| TA-3 overdue colour | **Yes** (R; C `reminder_screens.dart:549, :588` `colors.error`) | Reminder row styling uses `error` | Alarm tone for routine items; inconsistent with Bàn giao (warm) | The warm attention treatment (`sunshineSoft` + `ink` + icon) | Confirm red wasn't intentional |
| TA-4 reminder term | **Yes** (R: card "Nhắc nhở" = `remindersTitle`; legacy "Nhắc việc · 3"; list items "Nhắc việc") | Two keys, two terms | One feature, two names | One term | **Yes** (canonical) |
| TA-5 greeting addressee / empty name | **Yes** (R + C `today_adaptive.dart:68` `baby?.nickname ?? ''`) | The greeting greets the baby by design (AX10); no fallback | Odd voice; a broken string while loading | Keep the per-band greeting; never render an empty name (fall back to "bé" or hide the name) | **Yes** (addressee); the fallback is routine |
| TA-6 empty placeholder (3–6) | **Yes** (R `ax12` en) | "Moment today" widget always draws a media area | Prime space spent on nothing | Empty widget → one invitation row | Yes (changes the AX widget look) |
| TA-7 link labels | **Yes**, and wider: "Xem lịch sử" (0–1), "Lịch sử" (1–3), "Tất cả", "Xem tất cả" | Per-widget keys (`axSeeHistory`, `axHistoryShort`, …) | Inconsistent wayfinding | One rule: list → "Xem tất cả"; history → "Xem lịch sử" | No (copy within terms) |
| TA-8 first-run history link | Present (R `ax40`; H destination is the empty History) | The section header always has the link | A dead end on day one | Hide the history link until there is a record | No |

### 3.3 Information architecture challenges

| Question | Today Adaptive now |
|---|---|
| What's happening now? | **Partly.** Tiles show the latest per category; a running timer shows on its tile; care duty is a ranked widget. No single "now" signal for pending sync in adaptive (legacy has a banner) |
| What happened recently? | **Yes, well:** relative time + who on tiles |
| What needs attention? | **Weakly:** overdue sits inside the reminders card at its ranked position (3rd on 0–1), truncated and red |
| What should I do next? | Clear for logging (tiles, dock). **Competing** with in-card filled buttons on 1–3 / 6–12 |

**Observed issues:**

- **Competing emphasis:** filled "Thêm khoảnh khắc" above the care section on 1–3; a button in
  most 6–12 cards.
- **Low-value space:** grey empty placeholders (3–6) and empty thumbnail strips.
- **Repeated CTAs:** "Ghi lần đầu" on every empty tile in first run (acceptable, but four
  identical pills); "Thêm khoảnh khắc" and the dock "+" on the Memories tab do the same thing.
- **Grouping:**
  - AxCard headers carry an icon chip + title + subtitle count + link, which is good;
  - card radii differ from the core (20 vs 24, hand-rolled);
  - the tiles section has its header *outside* a card while other widgets have it inside: two
    grammars on one screen.
- **Nothing important is hidden too deeply** except the reminder time (truncated) and the
  pending-sync state in adaptive (Needs behavior verification: does `_SyncBanner` render in
  adaptive? The code path is shared, `today_screen.dart:277-286`, so likely yes; no adaptive
  golden).

### 3.4 Adaptive behaviour (documented, no change proposed)

- **Ordering:** `rankToday`: pins → manual order → score
  (0.35 goal / 0.25 age / 0.2 usage / 0.1 recent / 0.1 product).
- **Default visibility** = band defaults ∪ widgets of goals the person added (`defaultVisible`).
  For 3–6 and 6–12 the care tiles **start hidden**. That is approved behaviour (D-097 Q-088:
  "the quick log still starts hidden there") and is consistent with the plan's principles: age
  orders and sets defaults, nothing is locked, and the family can show it again in Tuỳ chỉnh.
- **This proposal changes none of it.** It changes only how ranked, visible widgets are drawn.

---

## 4. Three directions

### Direction A: Care-First

| | |
|---|---|
| Philosophy | Today is a care console: state + logging always first, then attention, then everything else |
| Primary job | Log and check care fast |
| Hierarchy | A fixed care block (now + 2 × 2 tiles + quick log) → attention (reminders) → ranked rest |
| Sections | Header · care block (fixed) · reminders · recent activity list · ranked widgets |
| Primary interaction | Tile tap / dock "+" |
| Strengths | Fastest for 0–1 nights; matches the legacy Today parents know |
| Weaknesses | **Overrides Adaptive order** (the care block always first) and **shows tiles to 3+ by default**: contradicts D-097 Q-088 and the "personalise, don't pretend" principle; parents of older children see a care console they don't use |
| Trade-offs | Speed for babies vs relevance for older children |
| Fit for Child Life | Strong for 0–1, weak for the long-term "grows with the child" vision |
| Complexity | Medium, but **requires a product decision to change ranking**, so out of bounds as a default |

### Direction B: Smart Daily Overview ("Adaptive Briefing")

| | |
|---|---|
| Philosophy | Keep the engine's order; make every ranked widget a calm, scannable briefing with one consistent grammar; surface attention honestly |
| Primary job | See what matters now for this child, at this age, and act |
| Hierarchy | Header · greeting (one line) · conditional attention line · ranked widgets (rank 1 drawn fully; others compact) · Tuỳ chỉnh |
| Sections | Each widget = title + count · ≤ 3 two-line rows or the tile grid · one link; empty → one invitation row |
| Primary interaction | Row / tile taps; the dock "+" |
| Strengths | **Respects Adaptive** (no ranking change); fixes TA-1, TA-6, TA-7 structurally; works for every band and role; mostly presentation |
| Weaknesses | Less emotional on its own; the attention line is a new element (approval) |
| Trade-offs | Consistency vs per-widget flourish (some AX card art is simplified) |
| Fit | Best fit: personal, honest, scalable to older children and new widgets |
| Complexity | Medium: `today_adaptive.dart` widgets, `ReminderPeek(ax:)`, skeletons, a few ARB strings |

### Direction C: Calm Family Dashboard

| | |
|---|---|
| Philosophy | A daily page about the child: identity, a short narrative of the day, moments and family first |
| Primary job | Feel connected; get the gist |
| Hierarchy | Child hero (photo, age) · "Hôm nay của Teddy" narrative · updates · care summary · moments |
| Sections | Hero card, narrative sentence, highlights, compact care, a family moments strip |
| Primary interaction | Reading; tap into memories |
| Strengths | Emotionally rich; great for 3–12 and relatives |
| Weaknesses | **The narrative needs generation logic** (new behaviour; numbers in prose; AI-like claims, G5 risk); slower logging; a hero competes with care at 3 a.m.; duplicates Memories |
| Trade-offs | Warmth vs speed and accuracy |
| Fit | Valuable ideas (warm memory presentation) but wrong as the base of a care dashboard |
| Complexity | High (new content logic, new hero component, copy, AI-safety review) |

---

## 5. Recommendation: Direction B, with A's care core and C's warmth in memories

**Why:**

- **Serves parents:** the attention line and untruncated reminders answer "what needs me?"; the
  care tiles stay the hero when they rank first (0–3); fewer competing buttons make the next
  action obvious.
- **Long-term vision:** scales across age bands and new widgets without a new engine, matching
  the plan's principles (personalise, never pretend; nothing locked; nothing taken away).
- **Adaptive:** order and visibility come from `rankToday` and `defaultVisible` unchanged. Only
  the drawing changes.
- **Avoids complexity:** no new data, no narrative generation, no ranking change; reuses
  `ClCardGroup`, `MeNotice`, `ClSkeleton`, `ClPressable`, `ClSectionHeader` and the existing care
  tiles.
- **Easier to understand:**
  - what's overdue, and when;
  - what's loading vs empty;
  - which link goes where;
  - which widget is empty.
- **Simpler interactions:**
  - one tap target per row;
  - empty widgets ask once;
  - no filled buttons inside cards (D-105).
- **Remaining trade-offs:**
  - some AX card visuals (thumbnail strips, in-card filled buttons) become plainer;
  - the attention line adds one conditional element;
  - Direction A's always-on care block is not adopted, so 3+ families still start without tiles
    (by design).

---

## 6. Screen blueprint (Design hypothesis — not visually verified)

### 6.1 Structure (top to bottom)

| # | Section | Purpose | Priority | Shows | Hierarchy | Interaction → destination | States | Components | Localisation |
|---|---|---|---|---|---|---|---|---|---|
| 0 | Header (unchanged) | Whose world, alerts, Night care | Fixed | Avatar · baby chip (name · age) · bell · Night care toggle | Pinned | Baby chip → profile or picker (`BabyHeader`); bell → inbox | Multi-child (chevron) | `ClPinnedHeaderScaffold`, `BabyHeader` | Long names ellipsise in the chip only |
| 1 | Greeting | Warm orientation, one line | Low weight | Per-band greeting (existing keys), **no empty-name rendering** | `largeTitle` today. **Proposed:** `title` or `title2` so it doesn't outweigh content (decision 6) | None | First run keeps its guidance sub-line (owner 2026-10-25) | `Text`, scale styles | vi greetings wrap to 2 lines (`ax13`); keep ≤ 2 lines |
| 2 | Status banners (existing) | Sync truth | Conditional, top | Overlap conflict / offline / pending (`_SyncBanner`) | Warm notice | → pending list / conflict | Offline, pending | Existing `_SyncBanner` | — |
| 3 | **Attention line (new, approval)** | Surface what needs the parent now, without reordering widgets | Conditional | Only when ≥ 1 overdue or rang-unanswered reminder (and the reader may act on reminders): "Quá hạn · Mua sữa công thức · hôm qua 18:00" (+ "và 1 việc khác") | `MeNotice(tone: warn)`: `sunshineSoft` + `ink` + alert icon; one line + count | Whole row → Reminders list (`Routes` reminders) | Hidden when nothing is overdue; hidden for relatives (`readOnly`) and where reminders aren't available to the role | `MeNotice` (warn) | Item title may be long: 2 lines max; time never truncated |
| 4… | Ranked widgets (order = `rankToday`) | Briefing per topic | By rank | See 6.2 | Rank 1 drawn fully; ranks 2+ compact | Rows / tiles tappable; one header link | Per widget (§9) | `ClSectionHeader` + `ClCardGroup` rows, or the care tile grid | Counts with plurals in en |
| last | Tuỳ chỉnh link (existing `AxCustomizeLink`) | Control | Low | "Tuỳ chỉnh Hôm nay" | Plain link | → `AxCustomizeScreen` | — | Existing | — |

### 6.2 One widget grammar

All ranked widgets except the care tiles:

```
[ClSectionHeader]  Title · count                         [link: Xem tất cả]
[ClCardGroup]
   row: leading icon chip (care / topic colour) · line 1 title (body)
                                                 line 2 status · time (label, inkMuted; warm if attention)
   row …  (max 3 rows; whole row tappable, ClPressable surfaceOpacity)
```

**Rules:**

- **Heading outside the card,** like the tiles section, so the screen has one grammar; the
  header carries the link. This retires the AxCard header-inside pattern.
- **No filled primary inside widgets** (D-105). The only filled primary on Today is none: the
  dock "+" is the frequent action.
- **Empty widget → one invitation row** (icon + "Thêm khoảnh khắc đầu tiên" + chevron) instead of
  placeholders and a button (TA-6).
- **Memories widget (C's warmth):** when there are moments, a strip of up to 3 real thumbnails
  (`MediaTile`, `ClTileShadow`) replaces rows; when empty, the invitation row. No grey
  placeholder boxes.
- **Care tiles** (rank-dependent, usually first for 0–3) keep their 2 × 2 grid and art (a
  strength). The header follows the same pattern ("Nhịp hôm nay" / decision 5). Tile meta
  becomes relative-first ("Kết thúc 3 giờ trước"); exact time on detail; copy through
  `cl-ux-writing`.
- **Reminders widget:** two-line rows; overdue first (the existing sort); warm attention
  colour + icon; never ellipsise the time (TA-1, TA-3).

### 6.3 Above the fold

The first viewport should tell a parent, at 375 × 812:

1. which child;
2. whether anything is overdue (attention line, if any);
3. the top-ranked widget's answer (for 0–3: the four care tiles with last times).

It does **not** need to show every widget. No hero card is added; the greeting is reduced in
weight so content starts higher (decision 6).

### 6.4 Component mapping

| Element | Component | Status |
|---|---|---|
| Frame, header | `ClPinnedHeaderScaffold`, `BabyHeader`, `ClBabySwitcher` | Existing |
| Section headers + links | `ClSectionHeader(title:, linkLabel:, onLink:)` | Existing |
| Widget rows | `ClCardGroup` + `MeRow` (icon, title, subtitle as status, chevron) | Existing (`MeRow` is the house row) |
| Two-line reminder row | `MeRow(title:, subtitle:)` with a warm subtitle colour for overdue | Existing; **`MeRow` has no "attention" tone**. Either pass the colour via `subtitle` styling (needs a small extension: `subtitleTone`) **or** keep the `ReminderPeek` row and fix its layout. **Prefer fixing `ReminderPeek(ax:)`** (no new API) |
| Attention line | `MeNotice(title:, tone: MeTone.warn, icon: ClIcons.alert, onTap:)` | Existing |
| Care tiles | Existing `CareTile` grid (`today_screen.dart`) | Existing |
| Memory strip | `MediaTile` + `ClTileShadow` | Existing |
| Empty invitation row | `MeRow(icon:, title:, onTap:)` | Existing |
| Loading | `ClSkeleton` blocks shaped like tiles and rows | Existing |
| Customize | `AxCustomizeLink` | Existing |
| AxCard | Retired for the widgets above; any widget that still needs a card uses the interim card recipe (`ClRadius.card`, `shadows.card`, `s4`) until the `ClCard` family exists | **Proposed change; visible (radius 20 → 24)** |
| New components | **None required.** Optional `MeRow` tone extension only if `ReminderPeek` can't be fixed in place (approval-free if behaviour-preserving; showcase + goldens) | — |

### 6.5 Visual direction (existing tokens only)

- **Type:**
  - greeting `title2` (proposed) instead of `largeTitle`;
  - section headers `headline`;
  - row title `body`;
  - status `label` / `caption` in `inkMuted`;
  - tile values stay `title2` / `numeral`-like as now (no new sizes).
- **Spacing:**
  - gutter `s4`;
  - `s6` between widgets (one rhythm; retire the per-lead `s2` / `s3` / `s4` variants once
    headers are outside cards);
  - `s3` header → content.
- **Surfaces:**
  - page `cloud`;
  - widget groups `surface` + `shadows.card` (D-096);
  - no card-in-card;
  - Night care relies on `surface` vs `cloud` fills.
- **Accent:**
  - care colours only on the care tiles and row icon chips;
  - attention = `sunshineSoft` + `ink` + icon;
  - no error red unless a save actually failed.
- **Icons:** `ClIcons` in icon chips (`ClRadius.control`), 20 px in 36–40 tiles.
- **Night care:**
  - the same structure;
  - the attention line keeps `ink` on `sunshineSoft` (safe in both palettes);
  - no shimmer (`ClSkeleton` is static at night).
- **Motion:**
  - the existing press opacity (`ClPressable`);
  - the skeleton → content swap without slide (`context.motion(ClMotion.quick)` fade);
  - no new haptics.

---

## 7. UX writing (vi / en)

Existing keys first; **new strings are proposals** (added later via a `tool/*_strings.py` script).

| Slot | vi | en | Source / status |
|---|---|---|---|
| Greeting 0–3 | Chào buổi chiều, {name} | Good afternoon, {name} | `axGreetAfternoon` (existing). Addressee is decision 4 |
| Greeting, no name yet | Chào buổi chiều | Good afternoon | **Proposed** fallback (no comma, no empty name) |
| Greeting 3–6 / 6–12 | Hôm nay của {name} thế nào? / Cùng lưu lại hành trình của {name} | How is {name}'s day going? / Let's keep {name}'s journey | `axGreet36`, `axGreet612` (existing) |
| Care section | Nhịp hôm nay · Xem lịch sử | Today's rhythm · See history | `axRhythmToday`, `axSeeHistory` (existing); 1–3 uses "Ghi nhanh · Lịch sử" (decision 5) |
| Care tile meta | Kết thúc 3 giờ trước · Bạn ghi | Ended 3 h ago · by you | **Proposed** shorter form; verified meaning: same event, rounded relative time; exact time on detail |
| Attention line | Quá hạn · Mua sữa công thức · hôm qua 18:00 | Overdue · Buy formula · yesterday 18:00 | **Proposed**; reuses the existing overdue wording ("Quá hạn"); "+ 1 việc khác" / "+ 1 more" via plural |
| Reminders header | Nhắc việc · 3 | Reminders · 3 | Term = decision 3 ("Nhắc việc" recommended by the glossary) |
| Reminder row | Mua sữa công thức / Quá hạn · hôm qua 18:00 | Buy formula / Overdue · yesterday 18:00 | Existing row strings; layout change only |
| Upcoming row | Tiêm 6 trong 1 / Thứ Bảy 08:30 · còn 2 ngày | 6-in-1 vaccine / Saturday 08:30 · in 2 days | Existing; now untruncated |
| Empty memories | Thêm khoảnh khắc đầu tiên | Add the first moment | **Proposed** (row label); existing `axAddMoment` "Thêm khoảnh khắc" can be reused |
| Empty reminders | Chưa có nhắc việc nào · Tạo nhắc việc | No reminders yet · Create a reminder | **Proposed**; check `ReminderPeek`'s existing empty copy first |
| Links | Xem tất cả · Xem lịch sử | See all · See history | Existing keys; one rule (TA-7) |
| Loading (screen reader) | Đang tải nhịp hôm nay | Loading today's rhythm | **Proposed** semantics label for the skeleton |

**Terminology decisions needed:** decisions 3 and 5. No other new canonical terms are introduced.
"Quá hạn", "Nhắc việc", "Kỷ niệm", "Ghi" and "khoảnh khắc" are existing glossary terms.

---

## 8. State matrix (Design hypothesis — not visually verified)

| # | State | What changes | Still available | Actions enabled | Must never mislead |
|---|---|---|---|---|---|
| 1 | Parent with recent logs | Tiles show the latest values; widgets per rank | All | Log, open, links | Times are relative to *now* in the baby's time zone |
| 2 | Parent, no care logs (not first run) | Tiles "Chưa có" + "Ghi lần đầu" (existing) | All | Log | Only after data has loaded (see 4) |
| 3 | First-time user | First-run greeting + sub-line (existing); history link hidden (TA-8); empty widgets as invitation rows | Customize, dock | Log, add a moment | No links to empty destinations |
| 4 | Loading | Tiles and rows show `ClSkeleton`; greeting without a name until the baby loads; attention line hidden until reminders load | Header, dock | Dock "+" (logging works offline) | **Never "Chưa có" before data resolves** (G1) |
| 5 | Offline | Existing warm banner at the top; content from cache | All | Logging (saved on this device) | Don't say "đã gửi"; pending items marked |
| 6 | Pending sync | Tile meta "Chờ đồng bộ" (existing) + banner | All | All | Saved locally ≠ visible to the family (`hasPendingWrites`) |
| 7 | Error (load failed) | **Needs behavior verification:** providers currently fall back to empty. Proposed: a widget-level `MeNotice(error)` "Chưa tải được · Thử lại" where a provider exposes an error | Other widgets | Retry | Never show "no data" for a failed load |
| 8 | Multiple children | Header chip with chevron; everything scoped to the selected child; the attention line only for this child | Switch child | All | Never mix children |
| 9 | Read-only relative / care-only caregiver | Widgets per `availableWidgetsProvider`; relatives: no logging, reminders or quick actions (existing); attention line hidden when reminders aren't available to the role | Viewing | Open only | Never offer an action the role can't take (G4) |
| 10 | Overdue reminder | Attention line appears (if approved); the reminders row is warm, first in its card | All | Open the reminder | Not error red; time always visible |
| 11 | No reminders | Attention line absent; the reminders widget shows one invitation row (or is hidden by rank / visibility as today) | All | Create (parents) | — |
| 12 | Long child name | Chip ellipsises; the greeting wraps to max 2 lines, then ellipsises the name only | All | All | The greeting never truncates mid-word in a way that changes meaning (H until rendered) |
| 13 | Large text (200 %) | Tiles grow in height (no fixed ratio for text); two-line rows wrap; links may drop under the title | All | All | Values and times never truncated (H until rendered) |
| 14 | Age groups | Order and visibility exactly as `rankToday` / `defaultVisible` (0–1 tiles first; 1–3 memories first; 3–6 moment / create / spending; 6–12 memories / reminders / spending) | Hidden widgets via Tuỳ chỉnh | Per widget | Nothing implies a feature is unavailable because of age |

---

## 9. Accessibility and localisation strategy

**All items below are a design hypothesis, not visually verified.**

| Check | Strategy | Verified in 9C by |
|---|---|---|
| vi + en × Light + Night care | All four variants of `ax10`–`ax13`, `ax40`–`ax43` | Existing golden matrix |
| 200 % text | No fixed tile height around text (tiles currently use `childAspectRatio: 166/156`: a risk); two-line rows | **New** text-scale variant (test-only; pattern from `assistant_chat_feel_test.dart`) |
| Long names | Chip ellipsis; greeting 2 lines | **New** long-name fixture |
| Small phones (320 pt) | Single column; tiles 2-up may need a min width → 1-up | **New** 320 × 640 variant (optional) |
| Screen-reader order | Header → greeting → banners → attention line → widgets (each header marked) → Tuỳ chỉnh; each tile and row one sentence ("Bú bình, 120 ml, 45 phút trước, bạn ghi") | Semantics test (new, test-only) |
| Touch targets | `ClPressable` rows and tiles (≥ 44 pt); no tiny in-card links | Code review |
| Reduced motion | Skeleton static; fade only | Code review |
| Colour independence | Attention = icon + "Quá hạn" text + warm fill | Golden |

---

## 10. Product decisions needed (owner)

1. **Approve Direction B ("Adaptive Briefing")** as the restructure of Hôm nay (Adaptive): one
   widget grammar, headers outside cards, no filled buttons in widgets, empty widgets as one row.
2. **Attention line** (new conditional element above ranked widgets for overdue reminders):
   yes / no. *Requires product approval: it surfaces reminders above their ranked position,
   without changing the ranking itself.*
3. **Canonical term:** "Nhắc việc" (recommended) or "Nhắc nhở" for the reminders feature.
4. **Greeting addressee:** keep greeting the baby ("Chào buổi chiều, Teddy"), or greet the
   parent / use a neutral line.
5. **Care section title:** one title for every band ("Nhịp hôm nay" recommended) or keep the
   per-band "Ghi nhanh" (AX11).
6. **Greeting weight:** reduce from `largeTitle` to `title2` so content starts higher.
7. **Confirm overdue colour** moves from error red to the warm attention treatment (both Todays
   share `ReminderPeek`).

**Not requested:**

- changes to ranking, default visibility, pins, logging rules, reminder calculation, permissions,
  sync, notifications, entitlements or AI;
- making care tiles default-visible for 3+ (that is approved D-097 Q-088 behaviour).

---

## 11. Implementation plan (after approval)

**Prerequisite:** the other session's uncommitted Today edits (`today_screen.dart`,
`today_adaptive.dart`, `ax` goldens) are committed first. One writer on these files at a time.

| Phase | Scope | Approval class | Files |
|---|---|---|---|
| **9B-1 Routine fixes** (independent of the direction) | TA-1 two-line reminder rows; TA-2 tile and row skeletons; TA-3 warm overdue; TA-5 empty-name fallback; TA-7 link rule; TA-8 hide the first-run history link | Routine (TA-3 after decision 7) | `reminders/reminder_screens.dart` (`ReminderPeek`, shared with legacy Today, so the legacy goldens change too), `today/today_screen.dart`, `adaptive/today_adaptive.dart`, ARB via `tool/today_v2_strings.py` |
| **9B-2 Direction B structure** | Headers outside cards; widget rows via `ClCardGroup` / `MeRow`; empty → invitation row; memories strip with real thumbnails; retire `AxCard` for these widgets | Owner (decision 1) | `adaptive/today_adaptive.dart` (Ax widgets), `today_screen.dart` (`sectionParts`) |
| **9B-3 Attention line** | `MeNotice(warn)` fed by the reminders provider; role-gated like `ReminderPeek` | Owner (decision 2) | `today_screen.dart`, ARB |
| **9B-4 Copy and terms** | Decisions 3–6 | Owner | ARB script |
| **Tests** (authorised with 9B) | Text-scale, long-name and semantics variants; fix the age mismatch in the older-band fixtures | Routine (test-only) | `test/golden/adaptive_golden_test.dart`, `test/helpers/adaptive_fixtures.dart` |

**No ranking, provider or business-logic change** in any phase.

---

## 12. Verification plan (Step 9C)

1. **Before images:** the current committed goldens (`git show HEAD:…`) for `ax10`–`ax13`,
   `ax40`–`ax43`, `s4/19_today`, `s4/9a_today_offline`, all four variants.
2. **After images:** the same tests and fixtures; compare per variant. Run without
   `--update-goldens` first and open `test/golden/failures/*_testImage.png`; update baselines
   only as part of the authorised implementation.
3. **New variants** (test-only): 200 % text, long name, (optional) 320 pt, adaptive offline and
   pending, relative and caregiver.
4. **`cl-design-review` rubric** re-scored with the same coverage. Targets:
   - no gate at risk;
   - TA-1 … TA-8 resolved;
   - no new Medium+ findings;
   - dimensions 7–9 ≥ 3 with text-scale coverage.
5. **Outcome per question** in `before-after-evaluation.md`: Improved / No change / Regressed /
   Inconclusive. **No claims about task time or engagement** unless measured (MET-01 events exist
   for widget taps; a before / after on real usage would need an owner-approved measurement
   window).
6. **Tests:** `flutter analyze`, `flutter test --exclude-tags golden`, then
   `flutter test --tags golden test/golden/adaptive_golden_test.dart test/golden/care_golden_test.dart`
   (macOS), checking `s4` legacy Today because `ReminderPeek` is shared.
