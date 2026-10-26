# Timelines and history

Job: understand **what happened, when, and how events relate**, then fix or add an entry.

## 1. Reference: Lịch sử (`features/care/history_screen.dart`)

Rendered `s6/20_history` (vi Light, en Night care), from top to bottom:

1. **Header:** back, title "Lịch sử", baby chip, month picker ("Tháng 10").
2. **Day strip** (`ClDayPill`): T6 2 … T5 8. Today is right-most and selected.
3. **Filter chips** (`ClFilterChip`): Tất cả / Bú / Hút sữa / Ngủ / Tã / … (scrolls).
4. **Day summary card** "Đã ghi hôm nay":
   - a 2 × 2 grid of per-category totals, each with its care-colour rule;
   - a **24 h strip** with a legend.
5. **Timeline grouped by part of day:**
   - a group header with icon, name, range and totals ("Chiều 13:00–18:00 · 1 cữ bú · 120 ml ·
     1 tã");
   - then entries: a time column, an icon on a rail, a title with the value, and "who logged"
     meta;
   - ongoing states inline ("Thức dậy · Đang thức · 2 giờ").

Variants:

| Golden | Variant |
|---|---|
| `20a`–`20d` | Filtered by type |
| `20d_history_growth*` | Growth with WHO curves |
| `20e_history_empty` | Empty day |
| `20f_date_picker` | Date picker |
| `12d_history_caregiver` | Caregiver |

This is the model for any chronological screen.

## 2. Timeline vs list

| Use a **timeline** (time column + rail) when | Use a **list** (grouped rows) when |
|---|---|
| Order and gaps in time matter (care events in a day) | Order doesn't matter, or there's one item per date (milestones achieved, invoices) |
| Durations or overlaps exist (sleep sessions) | Items are mostly the same kind and are scanned by name |
| The reader asks "what happened between 13:00 and 18:00?" | The reader asks "did we do X?" |
| Events of several kinds interleave | Settings-like management (reminder rules) |

Memories use their own **journal** pattern (week groups + entry cards; `galleries-and-memories.md`),
not the care timeline.

## 3. Patterns

| Concern | Pattern |
|---|---|
| **Day grouping** | Day strip for recent days + a month picker for older ones; inside a day, part-of-day groups with totals |
| **Duration** | The start time in the column; the duration in the title or meta ("Ngủ · 1 giờ 40 phút"); ongoing = "Đang …" + since + elapsed |
| **Start and end** | "21:27–23:07" in meta; spans across midnight are shown on the day they started, with "(hôm qua)" / "(yesterday)" on the other day |
| **Overlaps** | Allowed for different kinds (a feed during sleep); **flag** overlapping sleeps at entry time (`s5/27_overlap`); in the 24 h strip draw blocks on one track, ticks on another |
| **Edit an entry** | Tap the entry → the same sheet, pre-filled (`openCareLog(edit:)`); delete inside, confirm or undo |
| **Add for a past day** | From an empty or selected day ("Ghi bù {what}", `backLog`) with the date preset |
| **Filtering** | Chips; the summary and totals follow the filter; "Tất cả" resets |
| **Date navigation** | Strip (7 days) + a picker for months; jump to today |
| **Empty periods** | Keep the navigation; one quiet line + "Ghi bù" (`20e`) |
| **Large datasets** | Current History loads **one day per view** (`rangeRecordsProvider(day-1 … day end)`, `history_screen.dart:150`), so it scales by design; keep that. Stats read a 31-day window. Use lazy lists (`ListView.builder` / slivers) and collapse older groups; never load the whole history into one list |

**Known code-level gaps (from the code, not rendered):**

- **No loading state:** data is `.value ?? const []`, so `_EmptyDay` can flash before the day
  loads.
- **The baby chip in History and Stats is a label without a tap handler**
  (`history_screen.dart:358`, `stats_screens.dart:170`), unlike the tappable `BabyHeader` on
  tabs.
- **Sections are built imperatively** (`children.add`, `history_screen.dart:184-339`), which hides
  the order. Declare the section list when touching it.

## 4. Avoid

- decoration on the rail that hides the times;
- different visual weights for the same kind of event;
- summarising a filtered view with unfiltered totals;
- mixing babies in one timeline without labels;
- relative times only ("2 giờ trước") in history. History needs clock times; relative time
  belongs on dashboards.

## 5. Bilingual and accessibility

- **Clock times are 24-hour in both languages** (current app). Part-of-day names are localised
  (Sáng / Chiều / Tối / Đêm ↔ Morning / Afternoon / Evening / Night).
- **en totals need plurals.** Rendered bug: "1 feeds" in the en History summary
  (`s6/20_history_nightCare_en`, `rhythmFeeds`). This is a `cl-ux-writing` finding.
- **en units can wrap** ("420 / ml"): leave room or allow the value to wrap as a whole.
- **Each entry reads as one sentence:** "14:20, bú bình 120 ml, bạn ghi". Group headers are headers.
