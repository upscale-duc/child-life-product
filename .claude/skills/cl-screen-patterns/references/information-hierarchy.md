# Information hierarchy

**The goal is meaningful density, not minimalism:** show what the parent needs, in an order they
can scan, with the next action in reach.

## 1. User goals before data structure

Don't mirror Firestore collections, models or features in the layout. Order by the parent's
questions. On Hôm nay they are:

1. What is happening now? (an ongoing sleep or timer, who is on duty)
2. What happened recently? (last feed, sleep, diaper: relative time + who)
3. What needs attention? (overdue or upcoming reminders, vaccines)
4. What can I record quickly? (tiles, the dock "+")

The rendered Today (`s4/19_today`, `ax/ax10_today_0_1`) already follows 2 → 4 → 3 through its
four care tiles, the reminders block and the dock. Keep that order logic when adding sections.

## 2. The five-second test

For every substantial screen, write down:

| | Example: History (`s6/20_history`) |
|---|---|
| **Primary takeaway** | What was logged today, at a glance (the summary tiles + 24 h strip) |
| **Current or relevant state** | Selected day (day strip, "Thu 8"), active filter |
| **Next useful action** | Change day / filter, open an entry |

These three must be findable without scrolling on a 375 × 812 phone. **A hero card is not
required:** a large title plus a compact grouped list is often the right answer (settings, Me
`s11/13a_me_parent`). Use a hero only when one answer dominates (an ongoing sleep, Handover's
"Đang thức · 40 phút").

## 3. Visual levels

| Level | Use for | Implementation (values in `cl-design-foundations`) |
|---|---|---|
| Page title | Where am I | `largeTitle` via `ClNavHeader` / `MePage` / `ClPinnedHeaderScaffold` header |
| Hero | The single dominant answer, if any | `numeral` / `numeralXl` + state chip; one per screen |
| Section heading | What the group contains ("Nhắc việc · 3") | `ClSectionHeader` (+ link) or `MeSection` for settings groups |
| Primary value | The number or state that answers the row | `bodyStrong` / `numeral`, tabular |
| Secondary metadata | When, who, unit context ("45 phút trước · Bạn ghi") | `caption` / `label` in `inkMuted` |
| Status | Pending, overdue, ongoing | `ClSyncStatus`, a warm chip, icon + words |
| Supporting description | Only when it changes the decision | One line, `label` muted |
| Actions | The next step | One dominant primary (D-105); whole-surface taps |
| Disclosure | Detail, history, AI summary, explanations | A tap target / expander (Handover's "Tóm tắt mấy ngày qua") |

**Avoid:**

- multiple competing hero cards;
- every section at the same weight;
- a card around everything (borders and shadows on borders);
- repeated headings (a section heading + a card title saying the same);
- subtitles that restate the title;
- more than one accent family per section (care colours *are* the accents on care screens);
- decoration without a job (illustration on a data row).

## 4. Choosing the density form

| Content | Form | Example in the app |
|---|---|---|
| Several facts of the same kind | Compact rows in one group | Me rows (`MeRow` in `ClCardGroup`) |
| 2–4 headline numbers | Stat tiles in a row | Sleep stats "6g 2p · 2 giấc · 6g 30p" |
| The latest state of a few categories | Rich tiles (colour, art, value, meta) | Today care tiles |
| A day's events | Timeline (time column + rail) | History "Chiều 13:00–18:00" group |
| A day at a glance | 24 h strip | History summary, Handover |
| A trend over 7 / 30 days | Bars + average line | Sleep stats chart |
| Many media | Grid by period | Memories photos by week |
| Optional detail | Expandable section | Handover summary |

**Density never comes from shrinking text** (no type below `caption`, `cl-design-foundations`). It
comes from grouping, one fact per line, removing duplication, and disclosure.

## 5. Grouping rules

- **Group by meaning for the reader**, not by data type: "Tiếp theo" (Handover) mixes the next
  feed, a medicine reminder and an overdue vaccine because they answer one question.
- **One group = one container.** Rows sit in a `ClCardGroup`, not a card per row.
- **Repeated structures look identical** within a screen (all reminder rows, all tiles).
- **A section with nothing useful hides**, or shows one muted line. Don't reserve empty space for
  a fixed layout.

## 6. Progressive disclosure: what may hide, what may not

| May go behind a tap | Must stay visible |
|---|---|
| History beyond today; long lists ("Xem tất cả") | The current state and anything overdue |
| AI summaries and explanations | Safety information (first aid, health warnings, "Gọi 115") |
| Methodology ("Vì sao", basis of a range) | Consent, cost and price, data-loss consequences |
| Secondary actions (rename, export, delete) | Whether data is saved, pending or failed |
| Personalisation settings | The next action |

## 7. Order of sections (any screen)

1. Urgency for **this reader's role** (overdue, ongoing, needs attention).
2. Frequency of use (what they come for daily).
3. Recency (what just happened).
4. Context: age band, time of day, Night care, Adaptive ranking where it applies (see
   `dashboards-and-overviews.md`).
5. Everything else: discovery, education, upsell, last and quiet.
