# 09 · Unified Notifications & Smart Engagement — implementation report

**22/10/2026 · P-174 · implemented locally; nothing deployed, committed or switched on.** This report separates what is verified from what is only implemented, and from what is blocked.

## 1. Executive summary

Child Life now has one notification platform:

- **One entry point, persist first:** every server notification goes through `notifyUsers`. It persists the inbox row and a server-only ledger entry before any push. Ids are derived from the event, so a retry never duplicates.
- **Four independent states:** each entry tracks lifecycle, delivery, read and action separately.
- **Bounded retries:** transient provider failures are retried, then dead-lettered as `failed`.
- **Portal-managed copy:** VI/EN copy is managed in the Portal with immutable versions. Version 0 is today's code copy, proven equal by tests.
- **One resolver:** pushes and inbox taps open through one semantic destination resolver that re-checks membership and permission.
- **Smart Engagement:** ENG-00–06 is a producer on this platform. Three of its open defects are fixed.
- **Portal:** staff get a "Thông báo & Gắn kết" module with templates, catalog, delivery operations, journeys, an audited family timeline, analytics and kill switches.

## 2. Status

| Area | Implemented and verified (automated) | Implemented, not device-verified | Blocked / not implemented |
| --- | --- | --- | --- |
| Persistent inbox, dedup, ledger, 4 states, retries, kill switch | ✔ emulator tests | — | — |
| Templates (draft → review → publish, pause, rollback, versions, audit) | ✔ emulator + unit tests | — | — |
| Destination registry + app resolver | ✔ contract + widget tests | ✔ cold/background/foreground behaviour | Real-device run |
| Inbox UI (chips, paging, refresh, states, unread) | ✔ widget + golden tests | ✔ | Real-device run |
| Open/read receipts, multi-device read sync | ✔ emulator tests | ✔ | — |
| Sign-out token deletion | Code + analyze | ✔ | Device check |
| Family timeline, detail, upcoming (confirmed vs predicted), stats | ✔ emulator tests (masking, audit, isolation) | — | Browser run against deployed callables |
| Portal module (8 tabs) | ✔ typecheck, 304 tests, build | — | Browser run against deployed callables |
| ENG-00–06 on the platform; #19, #21, #22 fixed | ✔ emulator tests | ✔ | #10 (owner decision), #20 (debounce in a file another session owns) |
| Local reminders mirrored into the inbox | — | — | Not implemented by design (G-109b) |
| Invitation / role / removal pushes | — | — | Not in V1, recorded as G-109 |
| Executive / retention / revenue dashboards | Existing Product Analytics (reused, not duplicated) | — | Billing/IAP data remains backlog (doc 08 of product-analytics) |

## 3. Reused, not duplicated

- **Pipeline:** `notifyUsers`, the family-notice pipeline (`deliverNotice`), the inbox collection and its Rules.
- **Smart Engagement:** intents, decisions and budgets, unchanged.
- **Analytics:** the Product Analytics foundation (ENG funnel), linked from the Portal module and not recomputed.
- **Staff access:** staff roles and `staffAudit`.
- **App:** the existing app screens and helpers (`openRulePush`, `openVaccinePush`, `openEngagement`, `keepsakeJobPushOf`).

## 4. Important code paths

| Concern | Path |
| --- | --- |
| Contract (catalog, destinations, lifecycle, templates, API shapes) | `packages/contracts/src/notification-platform.ts` |
| Send, retries, receipts | `firebase/functions/src/notifications.ts` |
| Ledger transitions, stats, purge | `firebase/functions/src/notification-ledger.ts` |
| Runtime template / ops lookup | `firebase/functions/src/notification-runtime.ts` |
| Staff templates + ops | `firebase/functions/src/notification-templates.ts` |
| Staff stats, timeline, detail, retry | `firebase/functions/src/notification-staff.ts` |
| App resolver | `apps/mobile/lib/features/notifications/notification_destinations.dart` |
| Portal module | `apps/portal/src/screens/notifications/` |

## 5. Firestore

**New collections** (all denied to clients):

- `notificationDeliveries`
- `notificationStats`
- `notificationTemplates` (+ `versions`)
- `config/notifications`

**Inbox row:** new optional fields `destination`, `group`, `templateId`, `templateVersion`, `ledgerId`.

**Indexes (prepared, not applied):** on `notificationDeliveries`:

- `(delivery, nextAttemptAt)`
- `(delivery, createdAt desc)`
- `(familyId, createdAt desc)`
- TTL on `deleteAfter`

## 6. Cloud Functions

**New:**

- `retryNotificationPush` (every 5 min, one instance)
- `notificationOnInboxRead` (onUpdate of inbox rows)
- `recordNotificationOpened` (app callable)
- Staff callables:
  - `staffNotificationTemplates`, `staffNotificationTemplate`
  - `staffSaveNotificationTemplate`, `staffNotificationTemplateAction`
  - `staffNotificationStats`, `staffNotificationTimeline`, `staffNotificationDetail`
  - `staffRetryNotification`, `staffSetNotificationOps`

**Modified:**

- Producers: rule reminders, vaccines, spending (recurring, budget, import), family notices (message, album, share, story, storage, video), ENG dispatch.
- `sweepNotificationInbox` (also expires ledger lifecycle and sweeps ledger retention).
- `analyticsOnAccountDeleted` and the deletion jobs (ledger purge).
- `staffCall` (passes template issues to the Portal).

## 7. App and Portal

**App:**

- Inbox chips: Tất cả · Kỷ niệm · Gia đình · Chăm sóc · Khác.
- "Xem thông báo cũ hơn" paging, pull to refresh, skeleton, error/retry.
- A dedicated unread-count query.
- One resolver with fallback toasts.
- Message, storage, album and story rows now open their own screens; before, they opened Memories or nothing.
- `deleteToken` on sign-out.

**Portal:** route `/notifications/<tab>` with Overview, Templates (+ editor), Catalog, Delivery, Journeys, Family timeline (+ drawer), Analytics and Settings. The Shell nav gains an `orCan` option so content experts can reach Templates.

## 8. Test and build results (this machine, 22/10/2026)

| Suite | Result |
| --- | --- |
| Contracts (`vitest`) | 44 files, **784 passed** |
| Functions unit | 30 files, **501 passed**, 1 pre-existing skip |
| Functions typecheck + deploy bundle build | pass (a local build, not a deploy) |
| ESLint on changed TS files | clean |
| Emulator, full `firebase/tests` (isolated ports) | 87 files, **1054 passed, 3 failed** → after fixing the one caused by this change (vaccine test needed ledger cleanup): the 3 suites rerun **33/33 passed**. The other two failures (`quota`, `video-quota` concurrency, "emulator best effort") don't touch notification code and pass in isolation. |
| Emulator, the 15 notification-related suites together | **186 passed** |
| Portal typecheck / tests / `build:dev` | pass / **304 passed** / built |
| Mobile `flutter analyze` (shared tree) | 2 issues, both in `lib/core/design/page_transitions.dart`, an uncommitted edit by another session (not this work) |
| Mobile, scratch copy with that one file at HEAD | analyze **clean**; `test/features` + `test/app` + `test/core`: **2333 passed, 1 failed**. The failure is `swipe_back_shell_test.dart`, the other session's test of that same file. Notification tests 27/27, goldens 24/24, reminder 32/32, spending 31/31, memory story 27/27, engagement 7/7 |

## 9. Device validation

**Not executed.** No build was installed on a device, and no dev deployment carries this change. The checklist is in [08 §6](08-operations.md#6-device-validation-checklist).

## 10. Security and privacy review

- **Deny-by-default:** Rules deny every new collection to clients (tests). Owners still only set `readAt` / `archivedAt` on their rows.
- **No content in the ledger or stats:** no copy, names, captions, DOB, tokens or payloads (an integration test asserts it). Only provider error codes are kept.
- **No child data in templates:** the placeholder registry has no child data. The validator rejects URLs, markup and unknown placeholders. Destinations come only from the registry.
- **Family timeline:** requires families at "view" level and is audited per view and per detail open. Recipients are masked per response, there is no cross-family access (tested), and there is no free search or bulk export.
- **A notification id grants nothing:** opening re-checks the session, membership and permission. Engagement links are re-authorised by the server. Open receipts accept only the caller's own rows.
- **Retention:** inbox 90 days, ledger 120 days. Ledger purged on account and baby deletion. Stats are aggregate.
- **Known residual:**
  - The device Firestore cache is not cleared at sign-out. Queries are uid-path scoped, so another account cannot read the cached rows, but they stay on disk.
  - `actor_name`, the family member's display name, may appear in copy, as R-120 already allows.

## 11. Known limitations

- Templates and ops switches apply within 60 s (per-instance cache).
- Four-eyes publishing is recorded (`selfApproved`), not enforced.
- The timeline scans at most 300 rows per page window (a truncation notice is shown).
- Upcoming "confirmed" covers Care rule reminders only. ENG items are always "predicted", because the engine rechecks at send time.
- Old rows (before the ledger) have no stats; days before `sourceStartDay` show as "no data".
- Older app versions do not send open receipts.

## 12. External blockers

- **Owner decisions:**
  - P-174: retention, permission mapping.
  - G-109: family pushes.
  - Doc 18 #10: the lease.
  - Doc 17 A-01–A-14.
- **Another session's work:**
  - The uncommitted `page_transitions.dart` blocks in-tree mobile tests.
  - `engagement_repository.dart` (#20).
- **Environment:** the dev deploy and a real-device run need approval and devices.

## 13. Production deployment checklist

See [08 §5](08-operations.md#5-production-readiness-checklist): indexes and TTL → Functions → Portal on dev; invoker check; app release; device matrix; reconciliation; kill-switch drill; then prod with separate approval.

## 14. Post-launch monitoring

Watch, per [08 §2](08-operations.md#2-monitoring):

- failure rate and retry backlog
- provider acceptance per kind
- `render_error` after each publish
- open and read rates per template version (descriptive only, no causal claims)
- the ENG eligible-cohort funnel in Product Analytics
- Cloud Scheduler run history
