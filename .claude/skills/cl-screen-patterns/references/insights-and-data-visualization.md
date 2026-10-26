# Insights and data visualisation

**Core principle: a number answers a question; it doesn't decorate.**

Before showing any statistic, answer six questions:

1. What question does it answer ("Tuần này bé ngủ có đủ không?" is the parent's question, not
   the app's verdict)?
2. What period does it cover (today / 7 / 30 days; night window 18:00–06:00)?
3. What is it compared with (the baby's own recent days, never an invented norm)?
4. Is a chart needed, or is a number with a range enough?
5. Can the parent act on it?
6. Could it mislead (small sample, missing days, a partial day, mixed units)?

Wording, certainty and the five kinds of statement are in `cl-ux-writing` →
`personalization-and-ai-copy.md`. This file covers layout.

## 1. Rendered references

| Screen | Golden | What it does well |
|---|---|---|
| Sleep stats | `s6/20h_sleep_stats` (+ `_days`, `_today`) | Period segmented (Hôm nay / 7 ngày / 30 ngày); three stat tiles (average per day, sessions per day, longest); stacked bars night / day per day with a dashed average line labelled "TB 6g 2p"; window defined under the title ("Đêm 18:00–06:00 · Ngày 06:00–18:00"); a selected-day callout; one summary sentence |
| Feed stats | `s6/20g_feed_stats` (+ `_30`, `_days`, `2_feed_stats_today`) | The same frame for feeds (`StackedDaysChart`) |
| History summary | `s6/20_history` | Per-category totals in a 2 × 2 grid with care-colour rules + a 24 h strip with a legend |
| Handover | `ai/su01_ai` | A hero state ("Đang thức · 40 phút") with its basis; a 24 h strip from yesterday 10:00 to now; a prediction with its basis ("Cữ bú tới khoảng 12:40 · theo các cữ hôm nay") + a progress bar; the AI summary collapsed with its date range and creation time |
| Growth | `s6/20d_history_growth` (WHO curves, `WhoGrowthChart`) | Measurements against reference curves |

## 2. Choosing the visual

| The question | Use | Avoid |
|---|---|---|
| How much / how many (one value) | A big tabular value + unit + label (`numeral`) | A chart for one number |
| A few headline values side by side | 2–4 stat tiles, at most one emphasised | 6 tiles of equal weight |
| Value vs the baby's usual | Value + range or delta in words ("thường 8–9 giờ"), or a bar with a reference line | Colour-only good / bad; clinical labels |
| Over a day | A 24 h timeline strip (sleep blocks, feed and diaper ticks) | A list of 12 rows for a pattern |
| Over 7 / 30 days | Bars per day (stacked for night / day), a dashed average | A line chart for counts per day |
| A continuous measure over age | A line against WHO percentile bands | Bars |
| Next expected event | Approximate time + basis + a soft progress bar | An exact time ("12:40") without "khoảng" |
| Trend direction | Words + a small arrow, with the basis ("Gần đây ít hơn khoảng 2 giờ so với trước", D-102) | Arrows alone; % changes on tiny numbers |
| An interpretation | One sentence, labelled (AI or "theo …"), behind a tap if long | Paragraphs mixed into data |

**Don't add a chart to every insight.** One chart per question; the summary sentence states the
takeaway the chart supports. Rendered note: sleep stats' sentence restates the range the bars
already show. That's acceptable, but prefer a sentence that adds the takeaway.

## 3. Facts vs suggestions vs AI: make the difference visible in the layout

| Kind | Layout signal |
|---|---|
| Observed facts | Plain values in rows, tiles, strips; with "who logged" meta |
| Calculated summaries | Values with their period ("TB 7 ngày", the window under the title) |
| Pattern suggestions | A separate "Cách giúp bé" / suggestion chip or row, visually lighter, never inside a fact tile |
| Predictions | "khoảng …" + the basis line + a soft bar |
| AI interpretations | Their own collapsible section, labelled, with the date range and generation time; a stale notice when newer logs exist (`ai/su01_stale`) |

The Handover screen (`ai/su01_ai`) is the reference: facts on top, "Tiếp theo" predictions in the
middle with their basis, AI below the fold and collapsed.

## 4. Missing data, small samples, uncertainty

- **Partial today:** label it ("Hôm nay · đến 15:05"); don't average a partial day with full
  days without saying so.
- **Small samples** (fewer than the days the insight needs): show the values, skip the
  interpretation, and say why ("Mới có 2 ngày ghi nhận, chưa đủ để thấy nhịp ngủ").
- **Missing days:** show gaps as gaps, not zeros.
- **Mixed sources** (bottle in ml, breastfeeding in minutes): never sum them into one number;
  separate series or tiles.
- **No invented clinical thresholds.** Reference ranges come only from the bundled WHO data
  (`features/care/who_growth*.dart`) or an owner-approved source. "Usual" means the baby's own
  history.
- **Predictions** are approximate and disappear when their basis is too thin.

## 5. Accessibility

- **Every chart has `Semantics(label:)` with the takeaway sentence;** stat tiles read value + unit
  + label; tabular digits (`ClTabularText`).
- **Compact units** ("6g 2p") need spoken forms ("6 giờ 2 phút").
- **Legends** use the care colours *and* text labels. Colour never carries the series alone.
- **Night care:** the bars use the night care palette; the average line and labels stay readable.
