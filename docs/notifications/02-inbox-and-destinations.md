# 02 · Notification Center (inbox) and destination registry

**P-174.** Code:

- `apps/mobile/lib/features/notifications/` (screen, repository, models, links, `notification_destinations.dart`)
- `lib/features/memories/push_registration.dart`
- contract `notificationDestinations` in `packages/contracts/src/notification-platform.ts`

## 1. The inbox is independent of the OS

The inbox is `users/{uid}/notifications/{n_…}`. Functions write each row **before** any push, in the same transaction as the ledger entry. The OS notification and the row are separate objects:

- Swiping a push away in Notification Center does not touch the row.
- Failing to deliver a push does not remove the row.
- A muted kind (EN07 switch off) gets no row and no push. The ledger keeps the fact for the family timeline.
- Quiet hours and the push kill switch keep the row and skip the push.

Rows are kept 90 days. The daily sweep deletes rows past `expireAt`, and the app hides expired rows even if they are still cached.

Local notifications are not mirrored — owner decision D-092 #5 (G-109b closed). These are device-scheduled one-off reminders, rhythm and milestone nudges, and the personal-day digest. The OS gives no reliable "shown" signal, so writing a row on schedule would claim a display that may never have happened (several devices, notifications disabled, the app killed before the schedule). The server-side counterparts are already rows: rule reminders, vaccines and ENG-02/06 pushes. The server-side counterparts are the record of what matters.

## 2. App behaviour

| Need | Implementation |
| --- | --- |
| List, chronological | `watchInbox(uid, limit)`, `orderBy createdAt desc`. Sections Hôm nay / Tuần này / Trước đó. |
| Chips | Tất cả · Kỷ niệm · Gia đình · Chăm sóc · Khác, from the row's `group`. Older rows without `group` use the kind mapping (mirror of `inboxGroupOf`). Unknown kinds go to Khác. |
| Pagination | 30 rows per page; "Xem thông báo cũ hơn" adds 30 and keeps the current page on screen while it loads. |
| Pull to refresh, loading, error, empty | `MePage.onRefresh`, skeleton with a semantics label, error with Retry, empty, and empty-after-filter states. |
| Unread badge | `watchUnreadCount`: `readAt == null`, limit 99, with archived and expired rows filtered out. Equality only, so no composite index is needed. |
| Mark read / all read | Client sets `readAt` (Rules: once, at request time). The `notificationOnInboxRead` trigger copies it to the ledger, so every device and the Portal agree. |
| Archive | Swipe sets `archivedAt` (once). No undo, because Rules allow a single write. |
| Accessibility | Labels on rows (unread state), chips and buttons. |
| Localisation | Copy stored in vi and en on the row. The app shows the app language and falls back to vi. Chrome strings use `nt*` ARB keys. |

### Multi-device and accounts

- **Read state:** synchronised through Firestore, the same row on every device.
- **Tokens and devices:** devices are `users/{uid}/devices/{d_…}`, one token each, refreshed with `onTokenRefresh`. A provider "unregistered" answer drops the token; the device row stays until it signs out.
- **Sign-out:** the app deletes its device row and now also calls `FirebaseMessaging.deleteToken()`, so a shared phone stops receiving the previous account's pushes. The token-refresh subscription is cancelled.
- **Account switching:** the inbox provider is keyed by uid, and queries are path-scoped to `users/{uid}`, so a different account can never query another user's rows. Rules deny it on the server.
  - **Known limitation:** the Firestore offline cache on the device is not cleared on sign-out (the app never calls `clearPersistence`). The cached documents are unreachable from another account's queries, but they remain on disk until evicted. Clearing persistence safely needs all listeners stopped first and is left to the account-scope owner.
- **Revoked membership, deleted baby:** the resolver opens nothing for a baby that is not in the session's active memberships. The row can only open the inbox, with the toast "Nội dung này không còn".
- **Deleted resource:** an album, story or job that is gone falls back along the chain.

## 3. Destination registry

The 18 semantic ids are listed below. The Portal's "Điểm đến" table shows the same data from the contract. The app mirror is `notification_destinations.dart`; a contract test fails if any id is missing there.

| Id | Screen | Params | Permission | Fallback | Completion |
| --- | --- | --- | --- | --- | --- |
| CARE_RULE_REMINDER | rule reminder card | babyId, ruleId, dueAt? | care_read | CARE_REMINDERS | log / snooze / skip |
| CARE_REMINDERS | Nhắc nhở | babyId | care_read | INBOX | — |
| CARE_VACCINES | Sổ tiêm | babyId, date? | care_read | INBOX | record the dose |
| SPENDING | Chi tiêu | babyId | spending access | INBOX | — |
| SPENDING_IMPORT | import result | babyId, importId `im_…` | spending access | SPENDING | — |
| MEMORIES | Kỷ niệm | babyId | member | INBOX | — |
| MEMORIES_ALBUM | album | babyId, albumId | memories_read | MEMORIES | — |
| MEMORIES_STORY | story | babyId, storyId | memories_read | MEMORIES | — |
| MEMORIES_SHARED | album/share:{shareId} — the moments one "Báo cho gia đình" share made visible (owner, 2026-10-23); items carry `sharedIn` | babyId, shareId | memories_read | MEMORIES | — |
| MEMORIES_VIDEO_JOB | video result | babyId, jobId `ksj_…` | member | MEMORIES | watch / save / share |
| MEMORIES_PENDING_REVIEW | Tự lưu review (ENG-01) | babyId, engagementId | server re-auth | MEMORIES | approved photos cloud-ready |
| MEMORIES_KEEPSAKE_SUGGESTION | video templates (ENG-02) | babyId, engagementId | server re-auth | MEMORIES | keepsake video completed |
| MEMORIES_WEEKLY_RECAP | week recap (ENG-03) | babyId, engagementId | server re-auth | MEMORIES | view the week's content |
| FAMILY_MESSAGES | Lời nhắn | babyId | co_parent | INBOX | — |
| FAMILY_SHARED_CONTENT | family recap (ENG-05) | babyId, engagementId | server re-auth | MEMORIES | view shared content |
| FAMILY_STORAGE | Dung lượng | — | signed_in | INBOX | — |
| FAMILY_MEMBERS | Thành viên gia đình | babyId | member | INBOX | — |
| LUMI_INSIGHT | personal day (ENG-06) | babyId, engagementId | server re-auth | INBOX | view the source suggestion |
| INBOX | Hộp thông báo | — | signed_in | — | — |

Rules:

- **No editable URLs.** Templates cannot carry a destination or a link: the validator rejects `http(s)://`, markup and `${`. The destination is chosen by the producer from the registry and stored on the row and in push data (`destination`).
- **Older rows** without `destination` derive it from kind and ids (`destinationFor`).
- **Older apps** that do not know an id keep using the legacy `route` field, which is still written.

### The one resolver (inbox tap and push open)

`openNotification` handles a push opened from cold start, background or foreground, and an inbox tap. It runs these steps in order:

1. For a push only, waits up to 10 s for the session and memberships to load.
2. Requires a signed-in user. A signed-out or anonymous engagement push is queued for 10 minutes and replayed after sign-in (`EngagementLaunchQueue`).
3. Requires the row's baby to be in the current memberships. Otherwise only INBOX can open.
4. Checks the destination's permission (care read, Memories read, coParent, or spending access). Engagement destinations go to `actOnEngagement`, where the server re-authorises: owner uid, membership, fences, source.
5. Validates params with the contract regexes.
6. Navigates with the existing screens. If that fails, it walks the fallback chain.
7. Shows a toast unless it reached the first target: "Đã mở mục gần nhất" for a fallback, "Nội dung này không còn" when only INBOX is left, and the engagement "expired" copy for a failed engagement push.
8. Reports `recordNotificationOpen {inboxId, surface, outcome, destination}` fire-and-forget.
9. Marks the row read (client `readAt`).

Holding a notification id never grants access: the row path is the caller's own, the resolver checks current membership, and engagement links are re-authorised on the server.

Reading a row is not completing its action. The action dimension moves only on the producer's authoritative outcome (doc 03).

## 4. Device validation (not yet executed)

Real-device runs have **not** been done in this work. The checklist is in [08-operations.md](08-operations.md#device-validation-checklist).
