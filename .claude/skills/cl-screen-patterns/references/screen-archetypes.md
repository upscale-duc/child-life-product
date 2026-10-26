# Screen archetypes

Start every screen from the nearest archetype and its **reference implementation**, never from a
blank page or a feature kit. Archetypes differ on purpose: **dashboards, galleries, insights and
forms must not look identical.** Consistency comes from foundations and components, not from one
layout.

Implementation status uses `cl-ux-writing`'s vocabulary (Implemented / Approved · Planned /
Proposed). "Golden" = a rendered reference in `apps/mobile/test/golden/goldens/`.

## A. Dashboard / overview

| Field | |
|---|---|
| Examples | Hôm nay (legacy + adaptive), Care hub, Family, Me. **Implemented** |
| User job | Know what matters now; take the next action |
| Five-second answer | The latest state per care category + what's overdue or next |
| Hierarchy | Header (baby, bell, Night care) → greeting or title → state tiles → attention (reminders, duty) → recent memories / suggestions |
| Density | Medium-high: tiles + compact rows; 1–3 items per section |
| Actions | Tile tap = log or open; dock "+" = quick log; section links to full views |
| Components | `ClPinnedHeaderScaffold`, `BabyHeader`, care tiles, `ClSectionHeader`, `ClCardGroup` rows (`cl-components`) |
| States | First run (tiles "Chưa có"), offline / pending banner, read-only role, age bands, multiple babies |
| Accessibility | Each tile one sentence; live updates not chatty |
| vi / en | Tile meta wraps ("Kết thúc 3 giờ 20 phút trước"); reminder times truncate in the adaptive card (rendered) |
| Anti-patterns | Feature index; several heroes; empty sections kept for layout; upsell above care |
| References | `features/today/today_screen.dart`, `features/adaptive/today_adaptive.dart`; goldens `s4/19_today`, `ax/ax10`–`ax13`, `s4/9a_today_offline`. Detail: `dashboards-and-overviews.md` |

## B. Timeline / history

| Field | |
|---|---|
| Examples | Care history, filtered histories, Memories journal (its own variant). **Implemented** |
| User job | What happened, when, and how events relate; fix or add an entry |
| Five-second answer | Today's totals + the day's shape (24 h strip) |
| Hierarchy | Title + month → day strip → filters → day summary → part-of-day groups → entries |
| Density | High, but scannable: time column, one line per event + meta |
| Actions | Tap an entry = edit; "Ghi bù" on empty days; change day / filter |
| Components | `ClDayPill`, `ClFilterChip`, summary card, timeline rail |
| States | Empty day, caregiver (edit own only), relative (read-only), loading (missing today) |
| Accessibility | Each entry one sentence with a clock time |
| vi / en | en plurals ("1 feeds" rendered); units wrap in en |
| Anti-patterns | Relative times only; decoration over times; filtered list with unfiltered totals |
| References | `features/care/history_screen.dart`; goldens `s6/20_history*`, `20e_history_empty`. Detail: `timelines-and-history.md` |

## C. Insights / statistics

| Field | |
|---|---|
| Examples | Sleep stats, feed stats, growth curves, Handover (AI summary). **Implemented** |
| User job | See a pattern and decide whether to change something |
| Five-second answer | 2–3 headline numbers for the chosen period |
| Hierarchy | Title → period switch → stat tiles → main chart → secondary charts → per-day detail |
| Density | Medium: one chart per question |
| Actions | Change period / kind; open a day |
| Components | `ClSegmented`, stat tiles, `StackedDaysChart`, `WhoGrowthChart`, `ClTabularText` |
| States | Today (partial), too little data, gaps, offline |
| Accessibility | Chart summary labels; spoken units |
| vi / en | Compact units ("6g 2p") need spoken forms |
| Anti-patterns | Charts as decoration; invented thresholds; predictions as facts; numbers without period |
| References | `features/care/stats_screens.dart`, `features/ai/handover_screen.dart`; goldens `s6/20g_*`, `20h_*`, `ai/su01_*`. Detail: `insights-and-data-visualization.md` |

## D. Form / data entry

| Field | |
|---|---|
| Examples | Log feed / pump / diaper, sleep timer and manual sleep, growth, reminders, vaccines. **Implemented** |
| User job | Record something quickly and correctly |
| Five-second answer | What am I logging, and is the default right? |
| Hierarchy | Sheet title (care colour) → type switch → main value (big, pre-filled) → presets → secondary fields → time → primary |
| Density | Low: one main field, everything else secondary |
| Actions | One primary ("Lưu cữ bú"); toast + undo after |
| Components | `showClSheet` + `CareSheetFrame`, `ClSegmented`, chips, the time row and picker |
| States | Edit (pre-filled), validation, overlap, offline (saves locally), role (relatives can't log) |
| Accessibility | Big targets, one-handed, labelled fields |
| vi / en | Unit placement; amount labels |
| Anti-patterns | Asking for optional data first; disabling save without saying why; confirm dialogs for reversible logs |
| References | `features/care/care_sheets.dart`, `features/care/timer_screens.dart`; goldens `s4/19a_quick_log`, `22_bottle`, `23_breast`, `24_diaper`, `28_growth`, `s5/*`. Detail: `forms-and-multistep-flows.md` |

## E. Multi-step flow

| Field | |
|---|---|
| Examples | Onboarding setup, invite / join family, Memory Story creation, personalisation setup. **Implemented** (adaptive setup steps behind a flag) |
| User job | Finish a sequence without getting lost |
| Five-second answer | Which step, what is asked, how to continue |
| Hierarchy | Progress → one question title (+ one reassuring line) → choices → primary |
| Density | Low per step |
| Actions | Primary advances; back; skip only when optional |
| Components | `OnboardingScaffold`, `ClTopBar(progress:)`, `ClSelectTile` / `ClOptionRow`, `ClButton` |
| States | Interrupted, resumed, failure on the final step, invite expired / used |
| Accessibility | The step announced; focus to the first field |
| vi / en | Titles as questions; the CTA count ("Xong · 4 mục") |
| Anti-patterns | Two selection styles for one question (rendered `s2/12_trackers`); long explanations per step |
| References | `features/onboarding/setup_screens.dart`, `features/adaptive/adaptive_setup.dart`, `features/family/invite_screens.dart`, keepsake video screens; goldens `s2/*`, `s3/*`, `mm/mm06`–`mm09` |

## F. Gallery / memories

| Field | |
|---|---|
| Examples | Photos, Albums, Journal, Stories, Memory Story video ("Video kỷ niệm"), Milestone cards ("Thiệp cột mốc"; internal "Milestone Magic"). **Implemented**; remember-2 templates **Proposed** |
| User job | Enjoy, find, organise and share memories |
| Five-second answer | The latest moments, grouped by a meaningful period |
| Hierarchy | Title tabs → filter bar → featured or nudge (optional) → grouped grid or entries |
| Density | Visual-high: photos fill the space; quiet chrome |
| Actions | Tap = open; long-press / "Chọn" = select; "+" = add (parents) |
| Components | `MediaTile`, `MemoryEntryCard`, `ClTileShadow`, `ClEmptyState`, the selection pill |
| States | Uploading / processing (`QueueState`), empty, relative view, selection mode |
| Accessibility | Tiles labelled; the selection announced |
| vi / en | Title tabs clip at 375 pt (rendered) |
| Anti-patterns | Dashboard-style stat cards on memory screens; ambiguous selection vs add; overlays covering content |
| References | `features/memories/memories_screen.dart`; goldens `s9/*`, `s10/*`, `s12/*`, `mm/*`, `journal/*`. Detail: `galleries-and-memories.md` |

## G. Settings / management

| Field | |
|---|---|
| Examples | Me, notification settings, family members and permissions, storage, appearance, language, reminder rules. **Implemented** |
| User job | Understand the current configuration and change it safely |
| Five-second answer | The current value of each setting |
| Hierarchy | Title → identity card → grouped rows with current values → destructive group last |
| Density | High: compact rows |
| Actions | Row tap = open detail; toggles inline; destructive actions confirmed |
| Components | `MePage`, `ClCardGroup`, `MeRow`, `MeSection`, `ClToggle` |
| States | Role variants (owner, member), anonymous account, pending uploads at sign-out |
| Accessibility | Row = "label, value" |
| vi / en | Values right-aligned; they wrap rather than truncate |
| Anti-patterns | Explanatory paragraphs per row; destructive actions mixed with ordinary rows |
| References | `features/me/me_screen.dart`; goldens `s11/13a_me_parent`, `13g_me_caregiver`, `13h_me_relative`, `nt/en07_settings` |

## H. Premium / decision

| Field | |
|---|---|
| Examples | Paywall v2, family plan, E-sheets (video, Lumi credit, storage, caregivers), inline Premium cards. **Implemented** (Premium v2, D-101; IAP later) |
| User job | Understand value, compare, and decide calmly |
| Five-second answer | What Premium gives *for this need* + the price |
| Hierarchy | Personalised headline (entry-specific) → feature carousel → Free vs Premium comparison → plan choice → one CTA with the price → legal |
| Density | Medium; visually rich, the sanctioned dark and gold palette |
| Actions | One gold CTA; restore; close; members "ask the manager" |
| Components | `PaywallV2View`, `PremiumPalette`, `PremiumGoldButton`, plan tiles |
| States | Member (not owner), already Premium, store unavailable ("Sắp có"), pending, error, restore |
| Accessibility | Price spoken in full; legal text ≥ 12 px (rendered fine print is small and muted: check) |
| vi / en | Prices store-formatted |
| Anti-patterns | Pressure, countdowns, guilt; upsell blocking care; Plus / Pro tiers (not approved for the app, see glossary) |
| References | `features/premium/paywall_v2.dart`, `premium_entries.dart`, `family_plan_v2.dart`; goldens `pv2/*`, `pm/*` |

## I. AI / conversational

| Field | |
|---|---|
| Examples | Lumi chat (drafts), Handover (AI summary), rhythm insights. **Implemented** behind flags (`features.aiAssist`, assistant flags) |
| User job | Get help in context; keep facts, suggestions and uncertainty apart |
| Five-second answer | What Lumi understood / drafted, and what I need to confirm |
| Hierarchy | Chat header (scope, usage) → thread (my bubbles, Lumi parts, draft cards with state) → composer. Handover: facts → next → AI summary (collapsed) |
| Density | Conversational; draft cards structured like forms |
| Actions | Nothing saves without an explicit tap ("Lưu cữ bú" per draft, or a batch confirm); edit and remove per draft |
| Components | `AsDraftCard`, `AsBatchBar`, `AiStateCard`, `AiLabel` |
| States | Offline, credits used up, consent, health or emergency (free), unreadable photo, partial save, stale summary |
| Accessibility | New messages announced once; drafts navigable as groups |
| vi / en | Lumi replies in the app language |
| Anti-patterns | AI text styled like facts; auto-saving drafts; certainty without basis |
| References | `features/assistant/assistant_screens.dart`, `features/ai/handover_screen.dart`; goldens `as/ch*`, `ai/su01_*` |

## Choosing quickly

```
Is the reader recording something?           → D (one item) or E (a sequence)
Checking what matters now across categories?  → A
Looking back over events in time?             → B
Asking "how is it going / is this normal?"    → C
Enjoying or organising photos and stories?    → F
Changing how the app behaves?                 → G
Deciding about money or a plan?               → H
Talking to Lumi or reading an AI summary?     → I
```
