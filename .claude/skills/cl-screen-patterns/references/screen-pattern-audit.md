# Screen-pattern audit (read-only, 2026-10-25)

**Evidence levels:**

- **R (rendered):** seen in a golden PNG (path given). Goldens are 375 × 812 at 100 % text with
  fixture data.
- **C (code only):** read in source; not visible in the goldens.
- **H (hypothesis):** needs a visual or behavioural check before acting.

**Not inspected visually:** increased text scale (no harness, except assistant tests), long-name
fixtures (none exist), small or large phones, real devices, motion. No finding below claims
anything about them.

**Approval** was written before D-109. Read it with the autonomy levels (`senior-ui-ux` §3):

- **Routine:** L1 / L2.
- **Owner (behaviour)** #7 and **Owner (navigation)** #10: **L2.** Hiding "+" during selection
  keeps adding reachable once selection ends; making the History / Stats baby chip open the
  existing picker reuses an existing destination.
- **Owner (term)** #3 and #14: still **L3** (canonical terms).

## 1. Strengths to preserve (R)

| Screen | What works | Golden |
|---|---|---|
| History | Day strip + filters + summary (2 × 2 totals + 24 h strip) + part-of-day timeline with group totals | `s6/20_history_*` |
| Sleep / feed stats | Period switch, 3 stat tiles, stacked bars with an average line, window defined under the title | `s6/20h_*`, `20g_*` |
| Bottle log sheet | Pre-filled amount ("theo lần trước"), presets, time defaults to now, one primary | `s4/22_bottle` |
| Quick log | Six large one-handed tiles in care colours | `s4/19a_quick_log` |
| Handover | Facts → "Tiếp theo" predictions with basis → AI collapsed with date range; overdue in warm; stale notice | `ai/su01_ai`, `su01_stale` |
| Today care tiles | Latest state per category with relative time + who; "Chưa có / Chạm để ghi" | `s4/19_today`, `ax/ax10_*` |
| Offline Today | Warm banner + per-tile "Chờ đồng bộ" | `s4/9a_today_offline` |
| Me | Profile card, storage bar with a per-baby split, grouped rows with values | `s11/13a_me_parent` |
| Memory Story photo step | Scene slots with progress and the minimum, count + primary pinned | `mm/mm06_photos` |
| Paywall v2 | Entry-specific personalised headline, price on the CTA, legal line visible, Free vs Premium comparison | `pv2/pw01_video`, `pv40b_free` |

## 2. Findings

| # | Screen | User job | Current composition | Issue | Evidence | Proposed improvement | Benefit | Severity | Approval | Confidence |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Today (adaptive) | See what's next | Reminders `AxCard`: title on the left, status and time right-aligned on one line | The time column truncates: "còn 2 n…", en "yesterday 18:…", "in 2 d…". The overdue time is lost | **R** `ax/ax10_today_0_1_light_vi`, `_nightCare_en` | Put status / time under the title (two-line row, as legacy Today does) or use a shorter relative form; never ellipsise the time | Overdue and next items are readable at a glance | **High** | Routine | High |
| 2 | Today ↔ Handover | Notice what's overdue | Today: "Quá hạn · hôm qua 18:00" in error red; Handover: "Quá hạn tiêm" on `sunshineSoft` | The same meaning in two colours; red reads as alarm (rule: warm for attention, danger only for real danger, `senior-ui-ux` §5.4) | **R** `s4/19_today_light_vi`, `ai/su01_ai_light_vi` | Use the warm attention treatment (sunshineSoft + ink + icon) for overdue everywhere | Calm, consistent urgency signals | Medium | Routine (check if red was intentional) | High |
| 3 | Today (legacy vs adaptive) | Find reminders | Legacy header "Nhắc việc · 3"; adaptive card "Nhắc nhở" | Two names for one section depending on a flag | **R** `s4/19_today`, `ax/ax10_*` | Use one term (`cl-ux-writing` audit #9) | Consistent navigation language | Medium | **Owner** (canonical term) | High |
| 4 | History (en) | Read the day's totals | Summary "1 feeds · 15 min"; "4 feeds · 420 / ml" wraps | A plural bug in rendered UI; the unit wraps away from the value | **R** `s6/20_history_nightCare_en` | ICU plural (`rhythmFeeds`); keep value + unit together (non-breaking space / no wrap between them) | Correct, scannable totals | **Blocker** (grammar) | Routine | High |
| 5 | Today, History, Stats, Me | Trust what's shown | Data read as `.value ?? const []`; no skeleton | Empty states ("Chưa có", `_EmptyDay`, "—") can show while data is still loading | **C** `today_screen.dart:70`, `history_screen.dart:156`, `stats_screens.dart:151`; **H** visually (goldens render loaded data) | Skeletons shaped like the content until the first value arrives; reserve empty copy for real emptiness | No false "nothing logged" moments | **High** | Routine (presentation only) | Medium |
| 6 | Memories (select) | Pick items to share or delete | Floating "5 mục đã chọn" bar over the grid | The bar covers part of a grid row (items under it can't be seen or tapped) | **R** `s9/10b2_select_light_vi` | Add bottom padding equal to the bar's height while selecting | Every item stays reachable | Medium | Routine | High |
| 7 | Memories (select) | Know the current mode | The header "+" (add) stays visible next to "Xong" while selecting | Create and select affordances coexist | **R** composition; **H** whether it confuses | Hide or disable "+" in selection mode, if the product agrees | One mode at a time | Low | Owner (behaviour) | Medium |
| 8 | Memories | Switch tab | Big title tabs; "Câu chuyện" clipped to "Câu" at 375 pt | The 4th (and 5th, keepsakes) destination is barely discoverable | **R** `s9/10a_journal`, `10b2_select`; **H** discoverability | Keep the title tabs but ensure the selected tab is fully visible; consider a hint of scroll | Easier discovery of Stories and Keepsakes | Low | Routine | Medium |
| 9 | Onboarding (trackers) | Choose what to track | 4 check tiles (selected) + 2 rows with radio-like circles (unselected) | Two selection styles for one multi-select question | **R** `s2/12_trackers_light_vi`; **H** that it confuses (it may signal "suggested" vs "optional") | One style, or label the two groups ("Gợi ý" / "Thêm") | Clear choice model | Low | Routine | Medium |
| 10 | History, Stats | Switch baby | The baby chip in the top bar is a label (no tap) | Multi-child parents can switch on tabs but not here; the same chip looks tappable elsewhere | **C** `history_screen.dart:358`, `stats_screens.dart:170`; **H** intent | Make it tappable (opens the picker), or style it as a plain label | Fewer dead taps | Medium | Owner (navigation) | Medium |
| 11 | Today (adaptive) | Feel welcomed | "Chào buổi chiều, Teddy" | The greeting addresses the baby while the reader is the parent (the legacy title is "Hôm nay") | **R** `ax/ax10_*`; **H** intent | Confirm the intended addressee; if the parent, greet the parent or show the baby's state | Clear voice | Low | Owner (copy, `cl-ux-writing`) | Low |
| 12 | Paywall v2 | Understand terms | Legal line under the CTA: small, muted, on dark gradient | May fall below a comfortable size and contrast | **R** `pv2/pw01_video_light_vi`; **H** exact contrast and size | Measure; keep ≥ 12 px and AA on the dark fill (`PremiumPalette.textMuted`) | Readable terms | Medium | Routine | Medium |
| 13 | Today care tiles | Glance at the latest | Meta "Kết thúc 3 giờ 20 phút trước" wraps to two lines in a tile | A long relative phrase pushes "who" down | **R** `s4/19_today_light_vi` | Relative-first shorter form ("3 giờ trước") with the clock on the detail | Faster scanning | Low | Routine (copy via `cl-ux-writing`) | High |
| 14 | Milestone cards | Choose a template | Premium templates badged "Cao cấp" (`ksPremium`); en "Premium" | vi uses "Cao cấp" here and "Premium" elsewhere | **R** `mm/mm10_choose_light`; ARB | One term (glossary: Premium) | Consistent plan language | Low | **Owner** (term) | High |
| 15 | Sleep stats | Get the takeaway | Summary sentence restates the bar range | The sentence adds little beyond the chart | **R** `s6/20h_sleep_stats_light_vi` | Make the sentence the takeaway (compare with the previous period, if the data supports it) | More meaning per line | Low | Routine | Medium |
| 16 | All screens | Trust layout at scale | No text-scale or long-name goldens | Resilience at 200 % text and with long names is unverified | **C** test harness | Add text-scale + long-name variants to key goldens (Today, History, sheets) | Catches clipping before parents do | **High** (evidence gap) | Routine (tests only) | High |
| 17 | Several | — | Five frames (pinned header, hand-rolled Scaffold + `ClTopBar`, `OnboardingScaffold`, `MePage`, dark paywall); hand-rolled cards (`AxCard`, stats `_Kpis`) | Inconsistent structure in code; not a user-visible problem in the goldens | **C** (code survey) | Converge when touched (`cl-components` card system) | Maintainability | Low | Routine | High |

## 3. Highest-impact screens for future work

| Rank | Screen | Why |
|---|---|---|
| 1 | **Hôm nay** (both paths) | Most opened; #1, #2, #3, #5, #11, #13. Fix truncation, overdue colour and loading first |
| 2 | **History + Stats** | Daily use, trust in numbers; #4, #5, #10, #15 |
| 3 | **Memories selection** | Destructive actions on cherished data; #6, #7, #8 |
| 4 | **Test coverage** | #16 makes every other change safer |
| 5 | **Onboarding trackers, paywall legal line** | One-time but first or decisive impressions; #9, #12 |

**Prioritise** confusion, speed, trust and tired-parent usability **over** cosmetic consistency
(#17 is last on purpose).
