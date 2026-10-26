# Screen states

Every screen is designed for every state it can actually reach. **Only model distinctions the
implementation supports** (verified-business-meaning rule, `cl-ux-writing` → `ui-copy-patterns.md`
§5). Components for each state are in `cl-components` → `forms-and-feedback.md`; wording is in
`cl-ux-writing`.

## 1. Critical rules

1. **Never present stale information as current.**
   - Old data carries its time ("cập nhật 10:00", as in Handover `ai/su01_*`) or a stale notice
     ("Có ghi nhận mới · Tạo lại", `ai/su01_stale`).
   - Cached and offline views say so (`aiStateOfflineTitle` "Đang xem bản đã lưu").
2. **Never imply success before the implementation confirms the success condition.**
   - A toast that says "Đã ghi" after a local, optimistic write is correct: it *is* saved on the
     device.
   - Claiming others can see it is not, until the write reaches the server.
3. **Don't let loading look like empty.**
   - Today, much data is read as `.value ?? default` (264 sites), so a loading screen can render
     as "nothing logged".
   - When a screen's empty state could mislead (e.g. "Chưa có" on a care tile while data is still
     loading), show a skeleton until the first value arrives.
   - **Verified in code:** Today, History, Stats and Me draw no loading state
     (`today_screen.dart:70`, `history_screen.dart:156`, `stats_screens.dart:151`). History's
     `_EmptyDay` and Stats' "—" can therefore flash. Only Handover uses skeletons
     (`ai/handover_screen.dart:820`). Not visible in goldens, which render loaded data.

## 2. Data availability: the verified distinctions

| Data | States the code has | What each means for the UI |
|---|---|---|
| **Care records** (feeds, sleep, diapers…) | **Saved locally, pending** (`metadata.hasPendingWrites`, `features/care/care_models.dart`), then **on the server** (pending clears). Server **rejection** later → `careSaveFailed` toast | Pending: on this device only; others can't see it yet (`pendingFootnote`). Rendered: tile meta becomes "Chờ đồng bộ" + the offline banner (`s4/9a_today_offline`, `9b_pending`). Rejected: the record disappears locally; say so |
| **Media uploads** | `QueueState` (`features/memories/upload_queue.dart`): pendingSession, queued, waitingWifi, waitingQuota, uploading, paused, failed, **uploaded**, unreadable, cancelled | **uploaded ≠ visible to the family:** bytes are on the server, then processing decides ready vs unreadable. Show "đang xử lý" until ready; don't say "đã chia sẻ" at "uploaded". UI: `UploadPill`, queue `s9/10i_queue_states` |
| **Keepsake / Memory Story jobs** | `KeepsakeJobStatus` queued, rendering, completed, failed (`features/keepsakes/keepsake_jobs.dart`) | Rendered: `mm/mm08_rendering`, `mm09_ready`, `mm14_failed` |
| **AI summaries** (Handover) | Template version, fresh, stale, offline (saved copy), failed (`aiState*` keys; D-103 auto-refresh on open) | Each has its own notice; facts above stay usable |

Saved locally / queued / uploading / uploaded / available to family: use **only** the rows above.
For any other data type, check its repository before writing a status.

## 3. State catalogue

| State | Hierarchy and layout | Actions | Feedback | Accuracy |
|---|---|---|---|---|
| **Initial** (no selection yet) | Ask for the one choice needed (baby, period) | The choice | — | — |
| **Loading** | Skeleton shaped like the content (`ClSkeleton`); keep the header and title real | Disabled or hidden for content that isn't there yet | No spinner in the middle of the screen | Don't render an "empty" message |
| **Loaded** | Normal hierarchy | Normal | — | Show "as of" where it matters |
| **Empty (first time)** | `ClEmptyState` for a whole area: what's missing, then one action. A dashboard section hides or shows one muted line | The creating action | — | "Chưa có" only once loading is done |
| **Empty period** (no logs that day) | Keep navigation (day strip, filters); one quiet line in place of the list (`s6/20e_history_empty`) | Log for that day ("Ghi bù"), change day | — | — |
| **Partial data** | Show what exists; mark what's missing ("Chưa có" on a tile, rendered on Today's Sleep tile) | Fill the gap | — | Compute insights only with enough data (`insights-and-data-visualization.md`) |
| **Error (load)** | Keep the frame; an error notice in place of the content (`MeNotice(tone: error)` / inbox `ntLoadFailed*`) | Retry | What happened + what to do | Don't show cached data as fresh |
| **Error (action)** | Stay on the same screen; keep the input | Retry / edit | `showClToast(error: true)` | Say what wasn't saved |
| **Offline** | Warm banner at the top (`s4/9a_today_offline`); content stays usable | Logging still works (local writes) | Banner + item-level status | Pending items labelled |
| **Pending sync** | Item-level status replaces "who logged" meta (rendered "Chờ đồng bộ") | Normal | — | Others can't see them yet |
| **Processing** (AI, render, import) | In-place progress with an honest time hint ("có thể mất nửa phút", `imBusyAi`); a job card for long jobs | Cancel if supported; leave and come back | Toast / push when done | — |
| **Success** | The result is visible where the user is (tile updates + toast + undo) | Undo | `ClHaptics.success()` + toast | Wording matches the real success condition |
| **Permission restricted** (role) | Hide actions the role can't take. Read-only label where useful ("Bạn được xem chăm sóc hằng ngày, không ghi", `todayViewOnly`). Never show another person's state as yours | Ask the owner, if relevant | — | Rules are the authority (D-018) |
| **First run** | Coachmark / tour once (`ClTourTip`, `home/today_tour.dart`); the empty states teach the first action | The first log | — | — |
| **Multiple children** | Baby switcher in the header (`ClBabySwitcher`); every screen is scoped to the selected baby; push names the baby (D-094) | Switch baby | — | Never mix babies in one list without labelling |
| **Long content** | Paginate or group by period; collapse older groups; "Xem tất cả" | Jump to a date | — | — |
| **Health day** (a health sign logged, or the first-aid route) | Safety information first; AI text suppressed (Handover hides AI wording when there is a health sign, `ai/handover_screen.dart`); the free health route is never behind Premium | "Gọi 115" / first aid reachable | Calm, factual | Never diagnose |
| **Subscription restricted** | Show the feature's value and what Free keeps; one calm upsell (Premium surfaces, `pv2/pw*` sheets) | Upgrade / Later | — | Quotas from config, never hard-coded in copy |

## 4. Night care

Night care is a palette and a behaviour (no shimmer, no bounce, success-only haptics). States
must:

- be readable on dark fills;
- not flash: no animated success celebrations at night;
- keep banners calm (warm, not red).

Check every new state in the Night care goldens (`*_nightCare_*.png`).
