# Dashboards and overviews

**Job:** understand what matters *now* and take the next useful action. A dashboard is a
briefing, not a feature index. Not every feature earns a place.

## 1. Two Today implementations (both live, behind a flag)

| | Legacy Today | Adaptive Today (D-097, P-178) |
|---|---|---|
| Flag | default | `adaptiveOnProvider` = `capabilities.features.adaptiveExperience` (`features/adaptive/experience_repository.dart`) |
| Frame | `ClPinnedHeaderScaffold` + `BabyHeader` (bell, Night care toggle) | Same |
| Top | Date line + "Hôm nay" large title + "Tuỳ chỉnh" pill + care-duty chip (`s4/19_today`) | Greeting ("Chào buổi chiều, Teddy") + "Nhịp hôm nay · Xem lịch sử" (`ax/ax10_today_0_1`) |
| Order | `TodayLayout.defaultOrder`, user-customisable (`showTodayCustomizeSheet`) | `rankToday` (`features/adaptive/adaptive_engine.dart`): pinned → the user's manual order → score |
| Section rendering | `sectionParts` (`today_screen.dart:113`) | `AxCard` widgets (`today_adaptive.dart:138`, hand-rolled radius 20) |
| Rendered | 2 × 2 care tiles, then "Nhắc việc · 3" rows | 2 × 2 care tiles, then a "Nhắc nhở" card (3 upcoming), then "Kỷ niệm gần đây" |

**Patterns must work in both** until one is retired. Don't build a third ordering.

## 2. Content priority (respect the existing engine)

The adaptive score is already defined:

```
score = 0.35·goal + 0.25·age (band defaults) + 0.2·usage (28-day opens) + 0.1·recent (48 h activity) + 0.1·product priority
```

These are the `RankWeights` in `adaptive_engine.dart`. Pins and manual order win over the score.
The candidate set (`availableWidgetsProvider`) already applies role, trackers, flags and spending
access.

**Don't introduce a conflicting ranking.** When designing a new dashboard widget:

1. **Give it a `WidgetId`,** goals and band defaults.
2. **Decide its visibility rule** (role, trackers, flag).
3. **Design its states** (below).
4. **Leave ordering to the engine** (adaptive) or `TodayLayout` (legacy).

**Within a widget, order content by:**

1. urgency (overdue, ongoing);
2. relevance to the reader's role;
3. the reader's goals;
4. frequency;
5. recency;
6. context (time of day, Night care, age band).

## 3. Anatomy of a good dashboard section

| Part | Rule |
|---|---|
| Header | A plain name for what's inside + count when useful ("Nhắc việc · 3") + one link that names its destination ("Xem tất cả" opens the full list) |
| Body | The 1–3 items that matter now, as rows or tiles; never the full list |
| State | Visible status per item (overdue, pending sync, ongoing) |
| Action | Whole-row or whole-card tap; at most one header link; no buttons that duplicate the tap (D-105) |
| Size | Proportional to importance today. A quiet section is one row |

Today's care tiles are the reference for "latest state per category":

- value + relative time + who;
- care colour + art;
- "Chưa có / Chạm để ghi" when empty.

The Handover screen (`ai/su01_ai`) is the reference for a **briefing**:

- the current state hero;
- the latest per category;
- "Tiếp theo";
- suggestions;
- the AI summary collapsed.

## 4. Dynamic composition

| Situation | Behaviour |
|---|---|
| **No care logs yet** | Tiles show "Chưa có" + "Chạm để ghi" / "Ghi lần đầu" (rendered); don't add a separate empty card above them; the first-run tour may point at a tile |
| **Extensive history** | Dashboards still show *today* and *next*; history lives behind "Xem lịch sử" |
| **Multiple children** | Everything is scoped to the selected baby (header switcher); never mix babies in one dashboard section |
| **A reminder is overdue** | It moves to the top of its section with an overdue state (icon + words). **Colour:** the rendered Today uses error red ("Quá hạn · hôm qua 18:00"), while Handover renders the overdue vaccine on `sunshineSoft`. Warm is the documented rule (`senior-ui-ux` §5.4); reconcile when touched |
| **AI insight unavailable** (offline, failed, quota, no consent) | Collapse to one quiet row or hide; never leave an empty AI card. Facts still show |
| **Limited permissions** (relative read-only; caregiver care-only) | Hide actions they can't take (tiles become non-logging, no reminders or quick actions for relatives, `today_screen.dart:67`); keep the facts they may see |
| **A different age group** | Band defaults change the order and the widgets (`ax/ax10`–`ax13`: 0–1, 1–3, 3–6, 6–12 years); a widget that's irrelevant for the band isn't shown |
| **Offline / pending** | Warm banner at the top (`s4/9a_today_offline`) + per-tile "Chờ đồng bộ" |
| **Night care** | The same order; fewer accents; large values first |

**Avoid:**

- a large empty section kept only to preserve a layout;
- hiding critical information (overdue, ongoing, duty, pending sync);
- more than one hero;
- several sections all "Xem tất cả" with the same weight;
- feature promos above care information;
- upsells in the first viewport.

## 5. Other overviews

| Overview | Reference | Notes |
|---|---|---|
| Care hub (Chăm sóc) | `care/care_hub_screen.dart`, `s4/v1i_care_hub` | A directory of tools grouped by job (D-069); it's an index, so rows over cards |
| Explore (NavBar v2) | `adaptive/explore_screen.dart`, `ax/ax20_explore_0_1` | Gathers Care + Utilities by goal |
| Family | `family/family_screen.dart`, `s3/14a_family` | Members, roles, pending invites. A management overview: rows with status |
| Me / Profile | `me/me_screen.dart`, `s11/13a_me_parent` | Profile card, storage bar with a per-baby breakdown, grouped settings rows with current values |
| Rhythm home (Nhịp lớn lên) | `hn/home_parent` | "One hero" rule from D-102 |
