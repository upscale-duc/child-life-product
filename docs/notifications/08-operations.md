# 08 · Operations: switches, monitoring, rollback, release and device validation

**P-174.** Nothing in this work was deployed. Every step below that touches an environment needs the owner's approval. Dev deploys go through `scripts/deploy.sh dev <targets>`; prod is out of scope.

## 1. Switches

| Switch | Where | Default | Effect | Safe fallback |
| --- | --- | --- | --- | --- |
| `config/notifications.templatesEnabled` | Portal → Cài đặt | on | Off: every producer sends version 0 (code copy) | Always safe |
| `config/notifications.retryEnabled` | Portal → Cài đặt | on | Off: a transient provider error is `failed` at once | Rows are still persisted |
| `config/notifications.pushPaused.<group>` | Portal → Cài đặt | all off | On: rows are written, push cancelled (`kill_switch`) for memories / family / care / other | Pausing **care** stops reminders the user set; confirm with the owner first |
| Template pause / rollback | Portal → Mẫu nội dung | — | Back to version 0 or an older version | Sending continues |
| ENG flags (`engagement*Enabled`, `engagementPushEnabled`) | Feature hub (existing audited workflow) | off | See doc 17 | Disabling never revives legacy optional producers |
| Smart Engagement policy `config/engagement` (approved, caps, quiet default, `deviceLeaseDays`) | Portal → Cài đặt (D-092), `staffSetEngagementPolicy`, `notifications.ops` | missing = off | Approval gate + limits; only the strict schema is written | Turn `approved` off: every proactive suggestion stops at the next tick |

Every switch change writes `staffAudit`. The runtime caches `config/notifications` and templates for 60 s per instance, so a change takes effect within a minute.

## 2. Monitoring

| Signal | Where | Alarm (suggested) |
| --- | --- | --- |
| Failures and exhausted retries | Gửi & lỗi → problems; stats `failed`, `unknown` | Failure rate > 2 % of attempted over a day |
| Retry backlog | `retry_pending` count; `retryNotificationPush` logs (`notification retries`) | Backlog > 500 or older than 1 h |
| Provider acceptance drop | accepted / attempted per kind | −20 % day over day |
| Template render errors | stats `render_error` | Any > 0 after a publish |
| Inbox persistence failures | Functions error logs of the producers (`… failed`); the persist transaction throws to the caller | Any |
| Read-sync failures | `notification read sync failed` warnings | Sustained |
| Delayed schedules | Cloud Scheduler run history for `retryNotificationPush`, `ringRuleReminders`, `engagementTick` | Missed runs |
| Ledger ↔ inbox consistency | Every inbox row written since P-174 has `ledgerId`; every ledger `inboxId` has a row until it expires | Spot-check per week; a reconciliation job is a follow-up |

Structured logs carry counts and codes only, never ids of children, copy or tokens. The correlation id is the ENG intent id or the notice id.

Cost bounds per call:

| Operation | Bound |
| --- | --- |
| Retries | ≤ 100 per 5-min tick, one instance |
| Timeline | ≤ 300 ledger rows + 300 intents + 20 rule docs per baby |
| Stats | ≤ 92 × 8 docs |

There is no unbounded listener: the app inbox is limited to 30 rows per page plus a 99-row unread query.

## 3. Troubleshooting

| Symptom | Check |
| --- | --- |
| "I didn't get a push" | Timeline → entry → delivery: `setting_off` (EN07 off), `quiet_hours`, `no_device` (no token: app not opened since reinstall or sign-out), `kill_switch`, `rejected` (token dead), `failed` (provider), `accepted` (the provider took it; device or OS settings decide display) |
| "I see it twice" | It should not happen from a producer retry (dedup). Two rows mean two notice ids: check the producer's id. |
| "The tap opened the wrong place" | Entry → destination and navigation (`fallback` / `unavailable`): resource gone, membership revoked, or an older app |
| ENG suggestion never sent | Entry detail → first failing rule (consent, caps, quiet hours, lease, source) |

## 4. Rollback

| Change | Rollback |
| --- | --- |
| Template | Rollback to version 0 or pause, effective within 60 s |
| Push problem | Pause the group's push; rows keep arriving |
| Backend | Redeploy the previous Functions revision. The new fields are optional and the app ignores them. Old app versions keep using `route` / `kind`. The ledger and stats can stay; deleting them is not required. |
| App | The previous app version reads the same rows (unknown chips fall to "Khác") |

## 5. Production readiness checklist

- [ ] Owner approves P-174 (and G-109 gaps), retention (ledger 120 d; stats kept), and the permission mapping.
- [ ] Apply the indexes and TTL to **dev** (`firestore:indexes`), deploy the Functions listed below and the Portal to dev, verify, then prod with separate approval.
  - Functions: `notificationOnInboxRead`, `retryNotificationPush`, `recordNotificationOpened`, the `staffNotification*` callables, plus every changed producer function.
- [ ] Read the last line of `scripts/deploy.sh <env> …`: after every deploy that includes functions it runs `scripts/verify-deploy.mjs` (D-092, one-person operations). The script redeploys functions whose new revision failed to start (CPU quota) after the quota recovers, re-adds the public invoker to callables that lost it (callables only), and prints `✔ verify …` or what is still wrong. `invoker: 'public'` in code does not help: firebase-functions 7.4 ignores it for callables. Never probe callables by calling them in bulk, because ~200 calls exhaust the Cloud Run CPU quota for real users for ~15 min.
- [ ] Approve Smart Engagement on the target environment from Portal → Cài đặt (no REST command needed).
- [ ] Release the app (resolver, chips, open receipts, `deleteToken`); it is backward compatible with the old server.
- [ ] Execute the device checklist below on iOS and Android, recording app and backend revisions.
- [ ] Reconcile one day of dev: inbox rows = ledger `inbox`; push counts against FCM console.
- [ ] Demonstrate each kill switch and a template rollback on dev.
- [ ] Smart Engagement gates (doc 04 §5) before any ENG flag.

## 6. Device validation checklist

**Status: not executed** in this work. It needs signed builds on physical devices and the dev backend with this change deployed.

For each of iOS and Android, in Light and Night care:

| # | Scenario | Expected |
| --- | --- | --- |
| 1 | Foreground: a family notice arrives | No OS banner (current behaviour); bell dot and inbox row appear live |
| 2 | Background: tap the push | Opens the destination (album / story / messages / storage / video / reminder card); row read; ledger `openSurface=push`, `navigation=navigated` |
| 3 | Terminated (cold start): tap the push | Same as 2 after splash; rule reminder card opens |
| 4 | Clear the push from Notification Center, then open the app | Row still in the inbox, unread |
| 5 | Offline: open the inbox | Cached rows shown; refresh shows the error / retry state |
| 6 | Restart the app | Read state persists; unread badge correct |
| 7 | Push permission denied | Rows still arrive; ledger `no_device` or `accepted` per token state; in-app suggestions still shown |
| 8 | Two devices, same account | Read on one → read on the other within seconds |
| 9 | Sign out, sign in as another account on the same phone | No pushes for the previous account (token deleted); inbox shows only the new account's rows |
| 10 | Membership revoked, then tap an old row | "Nội dung này không còn"; nothing of the old baby opens |
| 11 | Deleted album or story, then tap | Falls back to Kỷ niệm with "Đã mở mục gần nhất" |
| 12 | Engagement push after sign-out | Queued; opens after sign-in within 10 min, else expires |
| 13 | Quiet hours | Row arrives, no push; reminder the user set still rings |
| 14 | Portal template published | Next push uses the new copy in vi and en; ledger version n |
