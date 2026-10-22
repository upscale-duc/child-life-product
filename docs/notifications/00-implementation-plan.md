# Unified Notifications & Smart Engagement — implementation plan and checklist

**Started 22/10/2026 (P-174).** This file tracks the work and its state. It is updated as each item lands. Anything marked done has a test path. Nothing in this plan deploys to dev or prod; deploys and flag changes need separate owner approval (CLAUDE.md).

## Starting point (audit, 22/10/2026)

| Capability | State before | Notes |
| --- | --- | --- |
| Server inbox `users/{uid}/notifications` via `notifyUsers` | Reusable | One writer; 5 direct callers + family notices (`deliverNotice`). EN07 switches, quiet hours, 90-day retention. |
| Inbox idempotency | Partial | Row id = notice id + send time, so a retried send writes a second row. Producers claim first, but `familyNotice()` ids are time-based and `onMessageCreated` uses `set`. |
| Delivery tracking | Partial | Only `pushed: bool`. Push is sent inline; a provider error throws after the row is written; no retry, no ledger. |
| Templates | Missing | Copy hard-coded per producer (`noticeCopy`, `ruleCopy`, `vaccineCopy`, `recurringCopy`, `budgetCopy`, import inline, `engagementCopy`). |
| Destinations | Partial | `route` enum of 6 values; app opens only 6 targets; album / story / messages / storage fall back to Memories or nothing. |
| Read / open / action states | Partial | `readAt` on the row; no open or navigation record; ENG intents keep their own action state. |
| ENG-00–06 | Implemented, default off | Docs 17/18; open items #10, #19, #20, #21, #22. Producer of `notifyUsers` already (no second pipeline). |
| Product Analytics | Implemented foundation | Six sections, ENG stages; no notification metrics. |
| Mobile Notification Center | Partial | Live list (100 rows), chips Nhắc việc · Cho bé · Gia đình, mark all read, swipe archive. No pagination, pull to refresh, loading or retry state. |
| Push handling | Partial | Cold/background/foreground handled in `push_registration.dart`; no open analytics; spending push skips the membership check; `deleteToken` never called on sign-out. |
| Portal | Missing for notifications | No templates, catalog, delivery ops or family timeline. Families screen and audited staff access exist. |

## Architecture decisions

1. **One platform.** `notifyUsers` stays the only inbox writer. It now also writes a server-only ledger entry per recipient (`notificationDeliveries/{d_…}`) in the same transaction as the inbox row. Smart Engagement keeps calling it.
2. **Idempotent by construction.** Inbox id = `n_{notice id}` (no time). The ledger id = sha-256 of uid + notice id. A retried producer finds both and stops (`duplicate` counted).
3. **Persist first, push after.** The row and ledger are committed before any provider I/O. A transient provider error moves delivery to `retry_pending`; a 5-minute sweeper retries up to 3 attempts with backoff, then `failed`. ENG keeps its rule: an ambiguous send is `unknown`, never retried.
4. **Four dimensions** (lifecycle, delivery, read, action) with one transition table (`canTransition`), so a stale worker cannot overwrite a newer terminal state.
5. **Templates are overrides.** Every type has a built-in copy (version 0) equal to today's push. A Portal-published version replaces it at send time; pause or the ops switch falls back to version 0. Published versions are immutable; rollback points live at an older version. Rows keep `templateId` and `templateVersion`.
6. **Semantic destinations.** `destination` is stored on the row and in push data. The app resolves it through one resolver, checks membership and permission, and walks the fallback chain to the inbox. Old rows derive a destination from `kind` and ids.
7. **Measurement from the ledger.** Every ledger transition increments `notificationStatsDaily/{day}` in the same transaction (exactly once). The Portal reads ≤ 92 daily docs. ENG funnels stay in Product Analytics (no second pipeline).

## Checklist (final state 22/10/2026 — see [09 report](09-implementation-report.md))

### Contracts — `packages/contracts/src/notification-platform.ts`

- [x] Catalog of all 21 kinds + gaps G-109 · destination registry (17) · lifecycle tables · 21 templates, placeholder registry, validator, renderer · staff/app schemas and responses · staff actions `notifications.*` · audit category. Test: `packages/contracts/test/notification-platform.test.ts` (incl. Dart parity)

### Backend — Functions

- [x] `notifyUsers`: persist first, deterministic ids, ledger, templates, destination, kill switch, bounded retries (`notifications.ts`, `notification-ledger.ts`, `notification-runtime.ts`)
- [x] Retry sweeper `retryNotificationPush`; read trigger `notificationOnInboxRead`; app callable `recordNotificationOpen`
- [x] Producers: template ids + values for care, vaccines, spending, import, family notices, ENG; `familyNotice` / `onMessageCreated` dedup
- [x] ENG action state → ledger (`engStage` → `noteEngagementAction`)
- [x] Staff callables (templates ×4, stats, timeline, detail, retry, ops), audited (`notification-templates.ts`, `notification-staff.ts`)
- [x] Rules (deny) + tests; indexes + TTL prepared (not applied)
- [x] Purge with account / baby; 120-day sweep
- [x] Built-in template = producer copy (`firebase/functions/test/notification-templates.test.ts`)
- [x] Emulator tests (`firebase/tests/notification-platform.integration.test.ts` + updated suites)

### ENG-00–06 open items (doc 18)

- [x] #19 · [x] #21 · [x] #22 — tests in `engagement.integration.test.ts`
- [ ] #10 owner decision · [ ] #20 client debounce (file owned by another session)

### Mobile

- [x] Resolver `notification_destinations.dart` shared by inbox and push; open receipts; spending membership check; `deleteToken` on sign-out
- [x] Inbox chips, pagination, refresh, loading / error / retry, unread count query; vi/en ARB; tests + regenerated EN06 goldens
- [ ] Real-device validation (not executed)

### Portal

- [x] Module "Thông báo & Gắn kết" with 8 tabs, editor, timeline + drawer, vi/en, permission gating, tests
- [ ] Browser run against real callables (needs a dev deploy)

### Docs

- [x] 01–08 specs, business map P-174 / G-109, 09 report
