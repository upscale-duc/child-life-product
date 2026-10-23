# 01 · Existing system audit and notification catalog

**P-174, 22/10/2026.** The catalog lives in code: `notificationTypes` in `packages/contracts/src/notification-platform.ts`. The Portal's "Danh mục" tab renders it. This page explains it and records the audit that led to it. Where this page and the code disagree, the code wins. A contract test (`packages/contracts/test/notification-platform.test.ts`) fails if a kind is missing from the catalog, or if a catalog row disagrees with the EN07 switch or the quiet-hours rule the inbox applies.

## 1. Audit (before P-174)

| Area | Found | Classification | Action |
| --- | --- | --- | --- |
| `notifyUsers` (`firebase/functions/src/notifications.ts`) | The only inbox writer. Applies EN07 switches and quiet hours, pushes per device language, drops dead tokens. | Reusable | Kept as the single entry point. It now persists first, writes the ledger and supports templates (doc 03). |
| Inbox `users/{uid}/notifications` | Written by Functions only. The owner sets `readAt` / `archivedAt` once. Kept 90 days. | Reusable | New optional fields: `destination`, `group`, `templateId`, `templateVersion`, `ledgerId`. |
| Inbox id | `n_{notice id}-{send time}` | Conflicting with dedup | Now `n_{notice id}`. A producer retry finds the row. |
| Provider error | Thrown after the row was written. No retry, no record. | Partial | Persisted as `retry_pending`. Bounded retries, then `failed` (doc 03). |
| Family notices `babies/{id}/notifications` | Claimed once by `deliverNotice`. `familyNotice()` ids were time-based; `onMessageCreated` used `set`. | Partial | Ids are per source and minute and use `create`. `onMessageCreated` uses `create`. |
| Copy | Hard-coded in 7 places. | Missing management | Templates with version 0 = code copy (doc 05). |
| Routes | 6-value `route` enum. Album, story, messages and storage opened Memories or nothing. | Partial | 17 semantic destinations with fallbacks (doc 02). |
| Smart Engagement | ENG-00–06 implemented, default off, already a producer of `notifyUsers`. | Reusable, open items | Linked to the ledger (action dimension); doc 18 #19, #21, #22 fixed (doc 04). |
| Product Analytics | Foundation, six sections, ENG stages. | Reusable | Not duplicated. Notification delivery metrics come from the ledger (doc 06). |
| Mobile inbox | Live list of 100 rows, chips Nhắc việc · Cho bé · Gia đình. | Partial | Chips, pagination, refresh, loading/error states, resolver (doc 02). |
| Push handling | Cold, background and foreground opens handled. | Partial | One resolver for push and inbox; spending membership check; FCM token deleted on sign-out. |
| Direct FCM sends outside `notifyUsers` | Keepsake Live Activity updates and the Android progress data push. | Correct as is | Not notifications: no inbox row by design, listed here only. |
| Mail | Auth, deletion, export, ownership, support and storage emails. | Separate channel | Catalogued as gaps where no push exists. |

## 2. Catalog

Groups (the app's chips): **Kỷ niệm** (memories), **Gia đình** (family), **Chăm sóc** (care), **Khác** (other). The legacy `category` field (reminders / baby / family / general) is still written for older app versions.

| Kind | Group | Producer · trigger | Recipients | Template(s) | Destination | EN07 switch | Quiet hours | Dedup | Action |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `reminderRule` | care | `ringRuleReminders` every minute | Rule recipients still coParent/caregiver | `care.rule_due` | CARE_RULE_REMINDER | reminders | rings | rule + due time | care occurrence (ENG-04) |
| `vaccine` | care | `ringVaccineReminderPush` every 5 min: D−3, eve 19:00, morning | coParent + caregiver (or chosen) | `care.vaccine_3d`, `_eve`, `_morning` | CARE_VACCINES | vaccines | rings | `vaccineReminders/{date}_{kind}` marker | none |
| `spending` | care | recurring 00:30, budget 80 %, import done/failed | coParents; importer | `spending.recurring`, `.budget80`, `.import_done`, `.import_failed` | SPENDING / SPENDING_IMPORT | spending | held | day / month / import outcome | none |
| `memories` | memories | upload batch closed | coParent + relative except uploader | `memories.new_moments` | MEMORIES | memories | held | batch id | none |
| `shared` | memories | media shared with family | same, except sharer | `memories.new_moments` | MEMORIES_SHARED (MEMORIES for rows before it) | memories | held | source + minute | none |
| `album` | memories | album shared/updated | same, except editor | `memories.new_moments` | MEMORIES_ALBUM | memories | held | album + minute | none |
| `story` | memories | story saved to family | same, except author | `memories.new_story` | MEMORIES_STORY | memories | held | story + minute | none |
| `message` | family | "Nhắn ba mẹ" | coParents except sender | `family.message` | FAMILY_MESSAGES | messages | held | message id | none |
| `storage` | family | 80 / 95 / 100 % | owner + coParents | `family.storage_almost_full`, `.storage_full` | FAMILY_STORAGE | storage | held | `storageNoticeState` | none |
| `storageGranted` | family | staff grant | parents | `family.storage_granted` | FAMILY_STORAGE | always | held | request id | none |
| `keepsakeVideo` | memories | render done | requester | `memories.video_ready` | MEMORIES_VIDEO_JOB | always | held | job id | none |
| `keepsakeVideoFailed` | memories | render failed | requester | `memories.video_failed` | MEMORIES_VIDEO_JOB | always | held | job + retries | none |
| `photoSuggestion` | memories | ENG-01 | Auto Save coParent, leased device | `eng.pending_photos` | MEMORIES_PENDING_REVIEW | photoSuggestions | held | ENG id | engagement |
| `keepsakePrompt` | memories | ENG-02 | one opted-in coParent | `eng.keepsake_suggestion` | MEMORIES_KEEPSAKE_SUGGESTION | keepsakePrompts | held | family campaign marker | engagement |
| `weeklySummary` | memories | ENG-03 | opted-in member | `eng.weekly_recap` | MEMORIES_WEEKLY_RECAP | weeklySummary | held | ENG id per week | engagement |
| `familyActivity` | family | ENG-05 | opted-in member | `eng.family_recap` | FAMILY_SHARED_CONTENT | familyActivity | held | ENG id per 30-min group | engagement |
| `rhythm` | other | ENG-06 | opted-in member | `eng.lumi_insight` | LUMI_INSIGHT | rhythm | held | ENG id | engagement |
| `memberJoined` | family | `acceptInvite` (in its transaction) | coParents except the newcomer | `family.member_joined` | FAMILY_MEMBERS | familyMembers | held | invite id | none |
| `inviteDeclined` | family | `declineInvite` | the inviter | `family.invite_declined` | FAMILY_MEMBERS | familyMembers | held | invite id | none |
| `roleChanged` | family | `updateMember` when the role changes (not relation / date edits) | that member | `family.role_changed` | FAMILY_MEMBERS | always | held | member + time | none |
| `memberRemoved` | family | `removeMember` | the removed person | `family.member_removed` | INBOX (no access left) | always | held | member + time | none |
| `stage`, `milestone`, `article` | other | **reserved**: no V1 sender; the EN07 switch is kept | — | — | INBOX | stages / milestones / articles | held | — | none |
| `test` | other | **reserved**: engineering delivery check | — | — | INBOX | always | held | — | none |

ENG-04 does not have a kind of its own. It measures the Care reminder (`reminderRule`) without changing it, so promotional caps never block a reminder the person set.

### Gaps (G-109, resolved by D-092)

Invitation accepted / declined, role changed and member removed became notifications (rows above, owner D-092). Two events stay outside push and are shown in the catalog as such:

| Event | Channel | Note |
| --- | --- | --- |
| Invitation received | Email / link | The invitee has no account yet. |
| Security / account changes | Email | Verification, password reset, deletion, ownership transfer. |

## 3. Shared contract per type

Every row above defines: stable kind, group, producer, trigger, recipient rule, priority, template ids (with version), localisation (vi/en built in), placeholders (per template, doc 05), channels (push + inbox; engagement also in-app), inbox persistence (90 days), destination and params (doc 02), push expiry (ENG only), dedup key, read behaviour (row read on open or on "mark all"), action criteria (doc 02 `completion`), analytics (doc 06) and permission (destination permission + producer recipient rule).

Overlapping producers do not double up:

- The family notice is the only producer of `memories` / `shared` / `album` / `story` / `message`.
- ENG-05 groups the inbox rows those notices create into one optional recap. It never sends the transactional notice again.
- ENG-04 observes Care and never sends.
- ENG-01/02/06 acknowledge an OS handoff before the legacy local producer is cancelled (doc 17).
