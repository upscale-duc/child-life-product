# Child Life Assistant — API (slice A2, server core)

Callables in `firebase/functions/src/index.ts` (block "Child Life Assistant, slice A2"), logic in
`firebase/functions/src/assistant.ts`, DTOs in `packages/contracts/src/assistant.ts`. Region
`asia-southeast1`. Every callable needs a signed-in **account** (anonymous "Vào ngay" identities get
`permission-denied`, `account-required`). The uid comes from the token; the plan from stored grants;
the scope is re-verified on every call (Admin SDK bypasses Rules). Nothing the client sends as
`authorUid`, plan or path is trusted.

## Envelope

Request (every command): `contractVersion: 1`, `clientRequestId` (UUID, the idempotency key),
`locale: 'vi' | 'en'`.

Answer (`AssistantResponse<T>`):

| Field | Meaning |
|---|---|
| `contractVersion` | `1` |
| `requestId` | echo of `clientRequestId` |
| `taskId` | the task concerned, or `null` |
| `serverTime` | ISO instant of the server clock |
| `dataVersion` | task `version` / draft `revision` the data describes; `0` if not versioned |
| `status` | `ok` · `blocked` (e.g. start at 0 credits, kept for resume) · `partial` (confirm: some items not saved) |
| `reasonCode` | an `assistantErrors` code when `blocked` / `partial`, else `null` |
| `retryable` | `true` only for `AI_UNAVAILABLE`-type conditions |
| `data` | the payload below |

Hard failures are `HttpsError`s: `message` = the reason code, `details = { reason, retryable, …field
details }` (field names / problem codes only, never values, stacks or provider text).

| Reason | HttpsError code |
|---|---|
| `AUTH_REQUIRED` | `unauthenticated` |
| `NOT_MEMBER`, `READ_DENIED`, `WRITE_DENIED`, `CONSENT_REQUIRED`, `FEATURE_DISABLED`, `REGION_UNSUPPORTED` | `permission-denied` |
| `USAGE_EXHAUSTED` | `resource-exhausted` |
| `IDEMPOTENCY_CONFLICT` | `already-exists` |
| `VALIDATION_FAILED` | `invalid-argument` |
| `AI_UNAVAILABLE` | `unavailable` |
| everything else (`QUOTE_EXPIRED`, `QUOTE_MISMATCH`, `SCOPE_CHANGED`, `DRAFT_*`, `REVIEW_REQUIRED`, `DOMAIN_CONFLICT`, `MODULE_UNAVAILABLE`, `INVALID_STATE`…) | `failed-precondition` |

A task or conversation that does not exist or belongs to someone else answers `NOT_MEMBER` (no
enumeration).

## D-075 changes (2026-10-15)

- **#1 credits**: `getAssistantUsage` / quotes use the Premium limit while any valid grant gives
  `assistant.premium_budget` (paid, promo, or a beta campaign; legacy paid / promo grants with
  `templates.premium` too), else Free (`usage.md`). AI summaries (`generateSummary`,
  `listSummaries`) charge / show the same pool: answers gain `credits: SummaryCredits`, `quota` is
  `{ day: null, month: <pool window> }`; `ai.assistance` no longer answers `PREMIUM_REQUIRED` for
  Free (role, `ai_assist`, region and consent still apply). `getCapabilities` lists the new
  capability `assistant.premium_budget`.
- **#2 shared thread** (`data.md` "Shared conversation per baby"): `startTask` routes a shared task
  (child scope, text, not `expense`, Cùng nuôi / Người chăm sóc) to `cv_<babyId>` whatever
  `conversationId` the app sent (a readable conversation of the same scope, or the shared id
  before it exists; another person's private one → `NOT_MEMBER`); a private task continues the
  caller's own private conversation, else a new one — never the shared thread. `quoteTask` accepts
  the shared thread's id. `getAssistantTask`, `confirmDrafts`, `patchDraft`, `discardDraft` accept
  any active Cùng nuôi / Người chăm sóc for a **shared** task (patch / discard only for a draft
  whose module their role may save; confirm re-checks each item against the confirmer's role);
  private tasks stay owner-only (`NOT_MEMBER`). `submitClarification`, `cancelTask`,
  `submitAssistantFeedback`, `planAssistantActivity` stay author-only. Views gain `task.visibility`,
  `task.author`, `message.author`, `draft.confirmedBy`, `conversation.shared` (`ownerUid` null for
  the shared thread). `listAssistantHistory` (conversations) puts the shared thread first on the
  first page (for Cùng nuôi / Người chăm sóc) and pages the caller's private ones after it (cursor
  `private` = the private list from its start). `deleteAssistantConversation` on the shared thread:
  Cùng nuôi only (`WRITE_DENIED` for a caregiver), deletes every member's tasks of it; answers
  `{ deletedTasks, domainRecordsKept: true }`.

## Commands

| Callable | Request (beyond the envelope) | `data` | Notes |
|---|---|---|---|
| `setAssistantConsent` | `consent: { version } \| null` | `{ assistant: { version, grantedAt } \| null, stoppedTasks }` | Only `assistant-consent-v1`. Writes `assistant` on `users/{uid}/settings/ai` with `mergeFields` (the summaries `consent` is untouched; `setAiConsent` now also merges, so it keeps `assistant`). Withdrawing fails the caller's `queued` / `awaiting_clarification` / `blocked` tasks with `CONSENT_REQUIRED` and releases their credits; a running task drops its output at settle time. |
| `quoteTask` | `conversationId \| null, scope, modality, attachmentCount, intentHint` | `AssistantQuote` | `status: blocked` + `reason` = first failing gate: `CONSENT_REQUIRED` → `AI_UNAVAILABLE` (`assistant_live` off, no provider key, AI budget spent) → `USAGE_EXHAUSTED`. Never calls a model, never reserves. TTL 5 min. `image` needs `assistant_images` (A3). Idempotent per `clientRequestId`. |
| `startTask` | `conversationId \| null, scope, quoteId, text, attachmentIds` | `{ task: AssistantTaskView, usage: AssistantUsage }` | See "Start" below. |
| `submitClarification` | `taskId, expectedVersion, clarificationId, choiceId \| null, text \| null` | `{ task }` | Same task, same reservation, 0 extra credits. Wrong state / version / id → `INVALID_STATE`; a choice not offered or empty free text → `VALIDATION_FAILED`; past the 30-min TTL → credits released, task `failed`, `QUOTE_EXPIRED`. Idempotent per `clientRequestId`. |
| `patchDraft` | `draftId, expectedRevision, payload, confirmedFields` | `{ draft: AssistantDraftView }` | Revision + 1, validated like the form (`draftProblems` against the server clock), no model, no credits, no domain write. `DRAFT_SAVED`, `DRAFT_EXPIRED`, `DRAFT_STALE`, `INVALID_STATE` (discarded), `VALIDATION_FAILED` (schema, kind change). Changed or confirmed fields leave `uncertainFields`; remaining problems put the draft in `needs_review`. |
| `confirmDrafts` | `taskId, selected[{ draftId, revision, acknowledge[] }], scope?` | `ConfirmDraftsResult` | No model, no credits (works at 0 credits while the TTL holds). Needs `assistant` + `assistant_writes`. `scope` (optional) different from the task's → `SCOPE_CHANGED` before anything. Per item: `saved` / `failed` / `conflict` (see "Confirm"). `status: partial` when any item is not saved. Idempotent per `clientRequestId`; the same id with another selection → `IDEMPOTENCY_CONFLICT`. |
| `discardDraft` | `draftId, expectedRevision` | `{ draft }` | State `discarded`; never a domain delete, never a refund. Saved → `DRAFT_SAVED`. |
| `cancelTask` | `taskId` | `{ task }` | Unfinished (`blocked`, `queued`, `processing`, `awaiting_clarification`) → `canceled`, reservation released once; a late worker is fenced. `ready` / `failed` / `canceled` unchanged (no refund for a ready answer). |
| `submitAssistantFeedback` | `taskId, contentId, contentVersion, outcome` | `{ feedbackId \| null, outcome }` | 0 credits, no model. Role `rhythm.feedback` (Cùng nuôi, Người chăm sóc) else `WRITE_DENIED`. `contentId`/`contentVersion` must be a published activity of `publicConfig/content_rhythm`. `helpful` / `unsure` / `not_suitable` → `babies/{b}/recFeedback/fb_<hash(uid,task,content,version)>`; the same again is idempotent, another outcome → `DOMAIN_CONFLICT`. `not_tried` ("Chưa thử") writes nothing to the module, only `feedback[]` on the task. |
| `getAssistantUsage` | `babyId` | `AssistantUsage` | Household pool now (an unused window reads empty). |
| `listAssistantHistory` | `babyId, conversationId \| null, cursor \| null, limit ≤ 50` | `AssistantHistoryPage<AssistantConversationView \| AssistantMessage>` | `conversationId: null` → the baby's shared thread first (Cùng nuôi / Người chăm sóc, first page only, D-075 #2), then the caller's own private conversations about `babyId`, newest `updatedAt` first, cursor = last conversation id (or `private`). Otherwise a readable conversation's messages (with `author`), newest first, cursor = last sequence. Other members' private chats are never listed (P-158). |
| `getAssistantTask` | `taskId, afterSequence \| null` | `AssistantTaskSnapshot` | Task (with `visibility`, `author`), drafts (with `problems`, `confirmedBy`), events after `afterSequence` (ordered), the task's messages (with `author`). The authority on reconnect (M11). Owner — or, for a shared task, any active Cùng nuôi / Người chăm sóc — still a member. |
| `deleteAssistantConversation` | `conversationId, confirm: true` | `{ deletedTasks, domainRecordsKept: true }` | Private: its owner. Shared thread: a Cùng nuôi only (`WRITE_DENIED` otherwise), for everyone (D-075 #2). Cancels unfinished tasks (credits released), deletes the conversation, its messages, its tasks with drafts and events. Never touches care records, check-ins, feedback, reminders, expenses, the credit ledger or execution rows. An already deleted conversation answers `deletedTasks: 0`. |

## Start (`startTask`)

1. Validate (text or attachments required; `image` → `FEATURE_DISABLED` without `assistant_images`,
   else `MODULE_UNAVAILABLE` until A3), membership of `scope`, `assistant` flag.
2. Task id = `tk_<hash(uid, clientRequestId)>`. Same id + same `taskInputKey` → the same task
   (replay, no new charge); a different input → `IDEMPOTENCY_CONFLICT`.
3. Health signs in the text (`healthSignalsIn`, vi/en) → **health support at once**: task `ready`,
   assistant message `[{ type: 'health_support', signs }]`, 0 credits, no quote check, no consent
   check, no model — also at quota 0 (U10, J10).
4. Consent (`CONSENT_REQUIRED`), quote (`QUOTE_MISMATCH` when not the caller's, another scope,
   modality, attachment count, used by another task, or the pool / credits moved since; `QUOTE_EXPIRED`
   after 5 min).
5. Model off (`assistant_live`, no provider key, AI budget spent) → `blocked` / `AI_UNAVAILABLE`,
   nothing reserved. Otherwise `reserveQuota` in the **same transaction** as the task: denied →
   `blocked` / `USAGE_EXHAUSTED` (assistant message `usage_notice`); reserved → task `queued`, quote
   `usedBy`. A window that moved since the quote aborts with `QUOTE_MISMATCH`.
6. A `blocked` task resumes when the same `clientRequestId` and input come with a fresh quote (e.g.
   after a verified upgrade the quote is at the paid pool, CH23): it reserves once and goes `queued`;
   "today" stays the original send instant.

## Worker (`runAssistantTask` trigger on `assistantTasks/{taskId}`)

Claims a `queued` task (or a `processing` one whose lease ended) in a transaction: `processing`,
`lease { holder: <task>#<attempt>, until: +300 s }`. Then: trusted scope → `assistant` flag → health
rule (free) → consent → `assistant_live` + provider + AI budget → one `extract` call (60 s deadline)
→ strict schema → clarification (model field from the catalog, or `time.ampm` when an hour has no
morning/evening anywhere, or `intent` when nothing was found; each field asked once, ≤ 4 rounds) →
read tools → wording (number-guarded) → prepare tools → **one fenced settle transaction**: task still
`processing` with this holder (else nothing is written or charged), consent re-read (withdrawn →
`CONSENT_REQUIRED`), part types allowlisted, credits per `usageForOutcome` (commit once / hold while
asking / release), drafts, assistant message, coalesced events, task state. More than 3 attempts →
`failed` / `AI_UNAVAILABLE`, released. `sweepAssistant` (every 10 min) requeues tasks whose lease ended,
fails unanswered clarifications after 30 min (`QUOTE_EXPIRED`, released) and deletes quotes older than
a day.

Task outcomes → state / credits:

| Outcome | State | Credits | Message parts |
|---|---|---|---|
| drafts (≥ 1) | `ready` | commit | summaries/wording if also read, notices, `draft_reference` × n |
| answer (read tools) | `ready` | commit | `source_summary`, `text` |
| clarification | `awaiting_clarification` | hold | `clarification` |
| health | `ready` | release (0) | `health_support` |
| provider error / timeout | `failed` · `AI_UNAVAILABLE` | release | `text` (no charge) |
| invalid output, unknown tool / intent / field | `failed` · `VALIDATION_FAILED` | release | `text` |
| only unavailable modules / denied role | `failed` · `MODULE_UNAVAILABLE` / `WRITE_DENIED` / `READ_DENIED` | release | notice `text` + `text` |
| consent withdrawn / membership lost | `failed` · `CONSENT_REQUIRED` / `NOT_MEMBER` / `SCOPE_CHANGED` | release | `text` |

## Confirm (per item)

In one transaction per item: draft state (`saved` → answers `saved` with its record, never rewrites
it, even if the record was edited in the form since), TTL (`DRAFT_EXPIRED`), revision
(`DRAFT_STALE`), review (`REVIEW_REQUIRED` while `needs_review` / uncertain / missing), module
(`MODULE_UNAVAILABLE`), membership (`NOT_MEMBER`), role for that module (`WRITE_DENIED`), baby still in
the task's household (`SCOPE_CHANGED`) and open, form validation (`VALIDATION_FAILED` + `problems`),
domain conflict (`conflict` / `DOMAIN_CONFLICT`: an overlapping live sleep unless `acknowledge`
contains `overlap`; a check-in already written by this person for that observation and day). Then
the record, the draft's `saved` state, the execution row and an `item_saved` event commit together.
A record already present at the draft's id is adopted as saved (crash after write, M04). After all
items one assistant message `action_result` is appended.

Record links (built by the server, app routes for A4): care `/care/records/{babyId}/{recordId}`,
check-in `/rhythm/checkins/{babyId}/{checkInId}`.

## Events

`assistantTasks/{taskId}/events/{seq}` — `{ taskId, eventId: "<taskId>:<seq>", sequence, type,
emittedAt, payload }`, sequence 1, 2, 3… with no gaps (the counter moves in the writing
transaction). Types: `accepted` (start, resume, clarification answered), `progress` (claimed),
`clarification_required`, `drafts_ready`, `answer_ready`, `usage_updated` (`{ usage, credits }`),
`item_saved`, `item_failed`, `task_failed` (`{ state: failed | canceled, errorCode }`). No per-token
writes. Clients ignore duplicates / old sequences; after a reconnect, `getAssistantTask` is the
authority.

## Care (slice A5, CH15–CH18, CH28)

Details in `tools.md` "Care tools"; credits in `usage.md`. Callable in `index.ts` (block "slice A5
care"), logic in `firebase/functions/src/assistant-care.ts`.

| Callable | Request (beyond the envelope) | `data` | Notes |
|---|---|---|---|
| `planAssistantActivity` | `taskId, contentId, contentVersion` | `{ plan: AssistantCarePlan, feedbackId }` | "Thử tối nay": an intention, not "đã thử". 0 credits, no model, idempotent per `clientRequestId` and per task + item. Owner, member, role `rhythm.feedback` (`WRITE_DENIED`), the task's own published guidance (`VALIDATION_FAILED`). Writes `care.plan` and `recFeedback` kind `started`. |

Changes to A2 callables: `submitAssistantFeedback` on a care task accepts only that task's guidance
and refuses a tried outcome before the plan's `feedbackOpensAt` (`INVALID_STATE`); `getAssistantTask`
adds `task.care` (`AssistantCareView`, with the CH17 `followUp` once due); `submitClarification`
resets the per-run attempt counter. Worker outcome `fallback` (no approved content fits): state
`ready`, credit released, event `answer_ready`. New parts fields (all optional): `text.code`,
`approved_content.{reasonCode, content, alternatives}`, `recipe_list.{items, excludedCount,
mealLogAvailable}`, `health_support.emergency`.

## Photos (slice A3, CH09–CH14)

Logic in `assistant-attachments.ts` (upload targets, verification, image checks, retention),
`assistant-images.ts` (worker branch), `assistant-image-model.ts` (reading schema / prompt),
`assistant-writers-images.ts` (Chi tiêu and reminder writers), `assistant-lifecycle.ts` (purges,
TTL). Callable and schedules in `index.ts` (block "slice A3 photos"). Security: `security.md`.

| Callable | Request (beyond the envelope) | `data` | Notes |
|---|---|---|---|
| `createAttachmentUpload` | `quoteId, mime (jpeg/png/heic/webp), bytes (≤ 8 MB), sha256, retention (keep_with_record — default, D-075 #3 \| delete_after_read)` | `AssistantUploadTarget { attachmentId, uploadPath, mime, maxBytes, expiresAt, retention }` | The quote must be the caller's, `image`, unexpired, unused and `allowed`; the household must still have the quoted credits **now**, the photo flag and the consent must hold — else the quote's reason / `USAGE_EXHAUSTED` / `FEATURE_DISABLED` / `CONSENT_REQUIRED` and **no target** (U03). One target per photo the quote counted (`VALIDATION_FAILED` beyond). Idempotent per `clientRequestId` (same `at_*`). Target valid 15 min. Nothing reserved. |

The app uploads the bytes once to `uploadPath` (`assistant/{uid}/{at_*}`) with the declared
content type, then calls `startTask` with `attachmentIds` and the same (or a fresh) image quote.

**`startTask` with photos** (replaces A2's `MODULE_UNAVAILABLE`): `modality` from the quote must be
`image` with ≥ 1 attachment (`VALIDATION_FAILED`); before any credit moves each attachment must be
the caller's (`NOT_MEMBER`), of the same household and scope (`SCOPE_CHANGED`), not used by another
task / deleted / refused (`VALIDATION_FAILED`, `details.problem: attachment_used | attachment_gone`),
uploaded before its target expired (`attachment_expired`), and present in Storage with the declared
type and no more than the declared size (`upload_missing | upload_mismatch`). The verified object
generation is bound to the task in the reservation transaction (also while `blocked`, for resume).
A replay of the same request returns the same task even after its photo was deleted. The user
message carries `attachmentIds`.

**Worker (photo tasks)**: after the A2 gates (scope, flag, health, consent, live model), the photos
are re-checked (owner, household, task, `ready`, generation), their bytes sniffed (magic numbers must
match the declared type) and decoded with sharp (≤ 40 MP, ≥ 32 px) **before any provider call**;
only a re-encoded JPEG (≤ 2048 px, no EXIF / GPS / ICC) goes out, once (`readImages`, 90 s). The
reading is cached server-side while a question is open; a clarification never re-sends a photo.

| Outcome | State | Credits (3) | Parts |
|---|---|---|---|
| refused photo (not an image, undecodable, moved, gone) | `failed` · `VALIDATION_FAILED` | release | `text` (no charge) |
| provider error / timeout | `failed` · `AI_UNAVAILABLE` | release | `text` |
| invalid reading (schema, extra key such as a "tool") | `failed` · `VALIDATION_FAILED` | release | `text` |
| unreadable (I01, J05) | `failed` · `OCR_UNREADABLE` | release | retake / type it in |
| receipt → one expense draft (I02–I04, J03) | `ready` | commit | notices (tax included, no total, other currency, possible duplicate) + `draft_reference` |
| note → asks `note.convert` (I06) | `awaiting_clarification` | hold | "Mình thấy N dòng…", "Không chuyển thành việc" list, `clarification` |
| note, weekday ≠ date (I07, G03) → asks `reminder.date.<line>` | `awaiting_clarification` | hold | `clarification` |
| note → reminder drafts for action lines (J04) | `ready` | commit | excluded list, "cần ngày và giờ", "chưa có người phụ trách", `draft_reference` × n |
| mixed (receipt + note / prescription) → asks `image.intent` | `awaiting_clarification` | hold | "nhiều loại nội dung", medicine notice, `clarification` |
| declined (`none`), nothing actionable, prescription only | `ready` | **release** | `text` ("Không tính lượt") |
| role cannot save (Chi tiêu right / Cùng nuôi for reminders) | `failed` · `WRITE_DENIED` | release | notice |

Photo clarifications (server catalog, vi/en, `allowText: false`): `image.intent` (`expense` "Ghi chi
tiêu", `reminders` "Lưu thành nhắc việc", `none` "Không làm gì" — only what the photo holds),
`note.convert` (`reminders`, `none`), `reminder.date.<i>` (`written` = the date as written,
`weekday` = the written weekday's date within ±3 days, `later` = leave the date to the person).

**Drafts**: `expense` `{ merchant, totalMinor (printed total only), currency, date, subtotalMinor,
taxMinor (informational, never added), categoryId (built-in hint or `c_other`), babyId (scope),
keepReceipt (= retention keep_with_record) }`; `reminder` `{ title, date, time (null unless written —
never 09:00), assigneeUid: null }`. Review: an uncertain date / total / currency / title, a missing
total / date / currency / time block confirm until `patchDraft` fixes or confirms them
(`confirmedFields`). `problems` (snapshot) now include the module's own: `CURRENCY_UNSUPPORTED` for
any currency other than VND (Q-077), `MISSING_TIME` and `INVALID_TITLE` (> 80) for reminders, plus
new `PAST_TIME`. These module limits live only in contracts `expenseCurrencySupported`,
`reminderNeedsTime` and `reminderAssigneeSupported` (D-075 #4 / #5 follow-up flips them). Warning `duplicate_suspected` (I03): confirm answers `conflict` /
`DUPLICATE_SUSPECTED` unless `acknowledge` contains it; never merged.

**Confirm (expense / reminder)**: role per module — Chi tiêu: Cùng nuôi or `extraRights.recordSpending`
(Rules `canRecordSpending`); reminders: Cùng nuôi only; else `WRITE_DENIED`. Expense:
`babies/{b}/expenses/x_<hash(draftId)>` (another baby of the household only with the same right
there), whole VND 1…1 000 000 000, date not after today, category built-in or existing; duplicate
re-checked inside the transaction. Reminder: `babies/{b}/reminders/rm_<hash(draftId)>`, due time
from date + time in the baby's zone, not before now (5 min) and ≤ 366 days, lead 60 min, no device.
A record already at the id is adopted (replay). Links: `/utilities/spending/expense/{id}?babyId=`,
`/care/reminders/{id}?babyId=`. With `keepReceipt`, a re-encoded JPEG (≤ 4 MB) is written to
`babies/{b}/expenses/{x}.jpg` before the transaction and set as `receiptPath`; removed again if the
expense is not saved.

**Retention in snapshots**: `getAssistantTask` adds `attachments: AssistantAttachmentView[]`
(`state`, `deletedAt` only once Storage confirmed, `keptWithRecord`, `rejected`). `cancelTask` on an
unfinished photo task deletes its photos at once; `setAssistantConsent(null)` deletes every photo of
the caller; `deleteAssistantConversation` deletes the conversation's photos (a failed delete stays
`deletion_pending` and is retried).

| Schedule | What |
|---|---|
| `sweepAssistantFiles` (15 min) | retries due `deletion_pending`; deletes uploads never started (target + 1 h), "xoá sau khi đọc" photos of finished tasks, kept photos no expense can still use (draft discarded / expired / saved), photos of blocked tasks after 24 h |
| `cleanupAssistant` (daily 03:20 VN) | `assistantExecutions` / `assistantRequests` older than 30 days; cached readings left by an interrupted run (> 1 day, task not asking); attachment rows of deleted tasks once their object is confirmed gone |

