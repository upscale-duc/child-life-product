# 07 · Portal: Notifications & Engagement module

**P-174.** The module lives at `apps/portal/src/screens/notifications/*` and its route is `/notifications/<tab>`. The nav label is "Thông báo & Gắn kết", under Vận hành. Messages are in `src/messages-notifications.ts` (vi/en, tuple pattern). Tests are in `apps/portal/test/notifications.test.tsx`.

The module answers six questions per notification type: what we send, to whom, why, when, where it leads, and what happened afterwards.

## Information architecture

| Tab | Content | Permission |
| --- | --- | --- |
| Tổng quan (Overview) | 7-day KPIs (created, inbox, accepted, failed, opened, read), trend, problem count, ops switch state, "accepted ≠ delivered" note | `notifications.view` |
| Mẫu nội dung (Templates) | List: search, filter, sort; VI/EN, live version, status, draft state, updated at/by, destination, 30-day volume. Editor: doc 05 | view **or** `notifications.edit` (content experts) |
| Danh mục (Catalog) | Every kind by group: trigger, recipients, priority, switch, quiet hours, dedup, templates, destination, ENG link, live/reserved. "Not sent in V1" gaps. Destinations table: screen, params, permission, fallback chain, completion | view |
| Gửi & lỗi (Delivery) | 7/30/90/custom (≤ 92 d) per-kind and per-template-version counts; problem list (retry_pending / failed / unknown) with Retry and a link to the family timeline | view; Retry needs `notifications.ops` |
| Hành trình (Journeys) | ENG-01–06 cards (kind, template, destination, completion) + funnel from the existing Product Analytics engagement section; disabled / no data shown as such | view |
| Dòng thời gian gia đình (Family timeline) | See below | `notifications.timeline` |
| Phân tích (Analytics) | Rates with numerator/denominator, by group and template version, trend with gaps before the first data day, CSV export, link to Product Analytics | view; CSV needs `analytics.export` |
| Cài đặt (Settings) | `templatesEnabled`, `retryEnabled`, push kill switch per group (care with a strong warning), pointer to the Feature hub for ENG flags | view; edit needs `notifications.ops` |

Permission mapping (`packages/contracts/src/staff.ts`):

| Action | Mapped to | Who has it |
| --- | --- | --- |
| view | overview:view | owner, admin, ops, support, eng, analyst |
| edit | content:edit | |
| publish | content:approve | |
| timeline | families:**view** | owner, admin, ops; support's masked level is not enough |
| ops | system:edit | |

## Family timeline

1. Staff enter a family code (`F-XXXX`, or `/notifications/timeline/F-XXXX`) and a date range of up to 92 days. There is no free search across families and no bulk export.
2. **Overview tiles:** notifications, engagement instances, completed, pending, suppressed, failed, last activity.
3. **Entries:**
   - Two sources: ledger rows (`d_…`) and engagement intents that never produced a row (`e_…`: in-app, suppressed).
   - Columns: time, kind, scenario, masked recipient (role + number), template@version, channel, lifecycle, delivery, read, action, reason.
   - Filters: view (all / Smart Engagement only), group, kind, scenario, delivery state, recipient.
   - Paging: "Load more" pages by cursor. A truncation notice shows when the bounded scan (300 rows) is exceeded.
4. **Detail drawer:** why it exists (scenario and source type, or producer); the engine's rule checks in order (pass / fail / unknown, derived from the recorded reason); the decision and reason; template and version; destination; the transition history; and whether push was attempted, the provider accepted, the row was opened, where navigation landed, and whether the action completed. Plus any cancel or expiry and the provider error codes.
5. **Upcoming:**
   - **Confirmed:** only server-held schedules, which today means enabled Care rule reminders (`nextDueAt`).
   - **Predicted:** pending ENG intents (the engine rechecks consent, caps and the source before any send), plus ENG-02 milestone windows opening within 60 days.
   - Each shows its state (scheduled, waiting, suppressed, expiring), times and the conditions that must hold.
6. **Preferences:** muted EN07 switches and engagement consent per masked recipient.

Privacy: the server returns metadata only. No uid, email, name, copy, caption, DOB or photo is returned (an integration test asserts this). Every timeline view and every detail view writes `staffAudit` (`notifications.timeline.view` / `.detail`, category `notifications`).

## Verification state

- Typecheck, unit tests and `build:dev` pass.
- Tests render server-side. Clicks and network calls (save, publish, retry, load more) are exercised against the backend only by the Functions integration tests, not in a browser.
- No dev deployment has been made, so the module has not run against real callables.
