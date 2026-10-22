# 06 · Notification and engagement metrics

**P-174.** This page adds the notification metrics. It extends the [Product Analytics metric dictionary](../product-analytics/02-metric-dictionary.md) and [engagement measurement](../product-analytics/05-engagement-measurement.md) and does not replace them.

Executive, acquisition, retention, Memories, adoption and cost metrics stay in Product Analytics (Portal → Phân tích sản phẩm). The ENG-01–06 funnel stays there too, keyed on eligible opportunities. The Notifications module reads that funnel and does not recompute it.

## 1. Source and pipeline

There is one source of truth: the ledger (`notificationDeliveries`). Each first-time transition increments `notificationStats/{day}_{shard}` in the same transaction. The day is the entry's **creation** day in Asia/Ho_Chi_Minh. The Portal sums at most 92 days × 8 shards.

There is no client event stream for notifications. Opens arrive through the authenticated callable `recordNotificationOpen`, and the server checks the row path is the caller's own.

## 2. Dictionary

Unit for all of them: one ledger entry = one recipient × one notice. Freshness: real time (written with the transition). Event version: ledger `v: 1`.

| Metric | Definition | Numerator / denominator | Notes |
| --- | --- | --- | --- |
| created | Notices addressed to a recipient | count | Includes muted ones |
| muted | Recipient's EN07 switch was off: no row, no push | count | |
| inbox | Rows persisted | count | = created − muted |
| held | Quiet hours held the push; the row stays | count | |
| no_device | No signed-in device with a token | count | |
| cancelled | Push not attempted for another stop reason (kill switch, no sender, expired, aborted) | count | |
| attempted | Entries with ≥ 1 provider call | count | Counted once whatever the retries |
| accepted | Provider accepted ≥ 1 token | count | **Not device delivery** |
| provider acceptance rate | accepted / attempted | — | Shown as "—" when attempted = 0 |
| rejected | Every token permanently refused | count | |
| retry | Entries that entered `retry_pending` | count | |
| failed | Retries exhausted or retry off | count | |
| unknown | Ambiguous ENG sends | count | |
| failure rate | (failed + unknown) / attempted | — | |
| read | Rows read (any device, any way) | count | |
| read rate | read / inbox | — | Includes "mark all read" |
| opened (push / inbox) | First open of the row, with surface | count | |
| open rate | opened / inbox | — | Opening ≠ completing |
| navigated / fallback / unavailable | Where the first open landed | count | |
| navigation success | navigated / opened | — | |
| action completed | Action dimension reached `completed` (ENG only) | count | Authoritative engine outcome |
| render_error | A published template could not render; version 0 was sent | count | Ops alarm |

Breakdowns: per day, kind, group, and template id @ version. Not by user, family or device.

## 3. Rules that keep the numbers honest

- **Provider acceptance is not delivery.** No metric claims device presentation.
- **Opening is not completing**, and completion is not causation. Engagement completion uses the engine's eligible-cohort conversion in Product Analytics, including completion without an open. No causal lift is claimed. Experiment and holdout assignment stays off (doc 17).
- **Missing opens are not "ignored".** An older app does not send open receipts, and an OS swipe is never a dismissal. Rows from before the ledger existed have no stats. Days before `sourceStartDay` are shown as "no data", not zero.
- **Duplicates and late events:** dedup by notice id means a retried producer adds nothing. Retries add no second `attempted`. A late read or open counts on the entry's creation day.
- **Multi-device and multi-caregiver:** the unit is the recipient, so two devices of one person are one entry. Two caregivers are two entries.
- **Privacy:** stats documents carry no identifiers. Family-level data only appears in the audited timeline.

## 4. Tests

Stats tests cover exact-once counting under retries and duplicate producers, independent read/open counts, and aggregation across shards. They are in `firebase/tests/notification-platform.integration.test.ts`.

The Portal's rate helpers return "—" for zero denominators (`apps/portal/test/notifications.test.tsx`).
