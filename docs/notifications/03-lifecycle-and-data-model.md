# 03 · Lifecycle, ledger and data model

**P-174.** Code:

- `firebase/functions/src/notifications.ts` (send, retries, receipts)
- `notification-ledger.ts` (transitions, stats, purge)
- contract `canTransition` and state lists in `notification-platform.ts`

## 1. Four independent dimensions

| Dimension | States | Who moves it |
| --- | --- | --- |
| Lifecycle | created → persisted → expired \| cancelled | `notifyUsers` (persisted, or cancelled when muted). The daily sweep moves it to expired. |
| Delivery | pending · scheduled · attempted · accepted · rejected · retry_pending · failed · cancelled · unknown | Send, retries, staff retry. |
| Read | unread → read | Inbox read trigger; open receipt. |
| Action | none \| not_started → started → completed \| expired \| unavailable | Smart Engagement stages (`engStage` → `noteEngagementAction`). |

Allowed delivery edges:

| From | To |
| --- | --- |
| pending | scheduled, attempted, cancelled, unknown |
| scheduled | attempted, cancelled, unknown |
| attempted | accepted, rejected, retry_pending, failed, unknown, cancelled |
| retry_pending | attempted, failed, cancelled |
| failed | retry_pending (staff retry only) |

`accepted`, `rejected`, `cancelled` and `unknown` are terminal.

`canTransition` rejects every other edge. That covers a backwards move, a move out of a terminal state, and a move to the same state. So a stale worker or a duplicate retry cannot overwrite a newer outcome.

Meaning of the delivery states:

- **`accepted`:** FCM/APNs took at least one token. It never means the device displayed the notification. Device presentation is not observable server-side.
- **`rejected`:** every token was permanently refused (unregistered or invalid). The tokens are dropped.
- **`retry_pending` → `failed`:** a transient provider error. Attempts are bounded at 3, with backoff of 1, 5 and 30 minutes. When retries are exhausted the state is `failed` with reason `retry_exhausted`, which acts as the dead-letter queue. It is visible in Portal → Gửi & lỗi, where staff with `notifications.ops` may requeue a non-ENG, unexpired row once.
- **`unknown`:** an ambiguous Smart Engagement send. It is never retried (ENG-00 rule: the slot is consumed, and there is no catch-up burst).
- **`cancelled` reasons:**
  - `setting_off`
  - `quiet_hours`
  - `no_device`
  - `no_sender` (emulator)
  - `kill_switch`
  - `expired` (push expiry passed before a retry)
  - `aborted` (row archived before a retry)

Opening is recorded apart from all four: `openedAt`, `openSurface` (push | inbox), `navigation` (navigated | fallback | unavailable), `navigatedAt`. Only the first open counts.

## 2. Collections

| Path | Written by | Read by | Content | Retention |
| --- | --- | --- | --- | --- |
| `users/{uid}/notifications/n_{notice id}` | Functions; owner sets `readAt` / `archivedAt` once | owner | Generic copy vi/en (R-120), kind, legacy category, `group`, route, `destination`, ids in `data`, `templateId`, `templateVersion`, `ledgerId`, `pushed` | 90 days (`expireAt`) |
| `notificationDeliveries/d_{sha256(uid, kind:id)[:40]}` | Functions | Functions; Portal through staff callables | uid, familyId, babyId, kind, group, producer, template id and version, destination, dedup key, correlation id, engagement id and kind, the 4 dimensions, reasons, attempts, token counts, timestamps of each transition, push platform options (for retries), bounded `history[24]` of `{at, dimension, to, reason}`, `deleteAfter` | 120 days (`deleteAfter`; daily sweep + prepared TTL) |
| `notificationStats/{yyyy-mm-dd}_{shard 0–7}` | Functions, in the same transaction as each transition | Portal stats | Counters `t.*` (totals), `k.<kind>.*`, `g.<group>.*`, `v.<template~id>@<version>.*` — no identifiers | Kept (aggregate) |
| `notificationTemplates/{id}` + `/versions/{n}` | staff callables | Functions (send) and Portal | Draft, status, `live {version, copy}`, immutable published versions | Kept |
| `config/notifications` | staff callable | Functions | `templatesEnabled`, `retryEnabled`, `pushPaused{group}` | Kept |
| `babies/{id}/notifications/{notice}` | domain writers (unchanged) | `deliverNotice` | Family notice to deliver once | Unchanged |

Rules: every new collection is denied to clients (deny-all at the end of `firestore.rules`). Tests are in `firebase/tests/notifications.rules.test.ts`. The owner cannot change `destination`, `ledgerId`, `templateVersion` or any other platform field of an inbox row.

Indexes (`firebase/firestore.indexes.json`, prepared, **not applied** to any environment):

- `notificationDeliveries (delivery ↑, nextAttemptAt ↑)` — retries
- `(delivery ↑, createdAt ↓)` — problems list
- `(familyId ↑, createdAt ↓)` — timeline
- TTL on `deleteAfter`

## 3. Idempotency and ordering

- **Dedup key:** the producer's notice id. It is already per event: rule + due time, dose date + kind, batch id, job id, import outcome, ENG id.
  - The inbox id is `n_{id}`.
  - The ledger id hashes the uid with `kind:id`.
  - The transaction creates both only if the ledger entry is absent. A retried trigger or schedule gets `duplicate` and writes nothing.
- **Persist before push:** the row and the ledger entry are committed first, then `attempted`, then the provider call, then the outcome. A crash between steps leaves `pending` or `attempted`, never a lost row.
- **Correlation id:** the ENG intent id for engagement notices, otherwise the notice id. The intent id links the ledger to `engagementIntents`, so the family timeline joins the two.
- **Stats are exact once:** a counter moves only inside the transaction that moves its dimension for the first time. A retried attempt does not count `attempted` again.

## 4. Privacy and retention

- **No content in the ledger:** no copy, names, captions, tokens or payloads (an integration test asserts it). Error codes are provider codes only, never messages.
- **Account deletion** (`personal` job and Auth onDelete) and **baby deletion** (`documents` job) call `purgeNotificationLedger`. Aggregate stats hold no identifiers and stay.
- **Portal access:** Portal access goes through staff callables. Family-level views are audited. Recipients are masked (`m1`, `m2` …) per response.
