# Child Life Assistant — data (slice A2)

All documents below are written by Functions only (Admin SDK). Client Rules
(`firebase/firestore.rules`, block "Child Life Assistant"): the owner (`ownerUid == auth.uid`) reads
while still an active member of `scope.babyId` (P-158); nobody else reads; no client writes. Executions
and the request ledger are never readable. Synthetic data in tests uses the `test_` prefix.

## Collections

| Path | Written by | Fields |
|---|---|---|
| `assistantConversations/{cv_*}` | `startTask`, worker, confirm, `deleteAssistantConversation` | `id, ownerUid, familyId, scope{type, babyId}, title (null), locale, createdAt, updatedAt, archivedAt (null), messageSeq, lastTaskId`. Id `cv_<hash(taskId)>` for a conversation started by a task. |
| `…/{cv}/messages/{seq:8}` | same | `conversationId, role user\|assistant, parts[] (typed, contracts AssistantPart), taskId, sequence, createdAt, attachmentIds[]`. User text is stored here (owner-private). |
| `assistantQuotes/{qt_*}` | `quoteTask` | `id, ownerUid, familyId, scope, modality, attachmentCount, intentHint, credits, plan free\|premium, grantId, windowId, policyVersion, allowed, reason, expiresAt, usedBy (taskId\|null), createdAt`. |
| `assistantTasks/{tk_*}` | `startTask`, worker, clarification, cancel, confirm (events) | `id, ownerUid, familyId, scope, conversationId, requestId, inputKey (sha256 of contracts taskInputKey), input{text, attachmentIds}, anchorInstant (original send instant), timezone (baby zone), locale, modality, quoteId, credits, plan, windowId, reservationId (assistant_<taskId>\|null), usage none\|reserved\|committed\|released, state, version, round, clarifications[{id, field, round, answer{choiceId,text}\|null, answeredAt}], pendingClarification, clarificationExpiresAt, lease{holder, until}\|null, attempt, errorCode, health (signs\|null), eventSeq, draftIds, outcome{kind, drafts, parts}, modelCalls, model, promptVersion, policyVersion, feedback[], createdAt, updatedAt, readyAt`. |
| `…/{tk}/drafts/{dr_<task hex>_<i>}` | worker, patch, discard, confirm | `ActionDraft` (`id, taskId, itemIndex, scope, payload, missingFields, uncertainFields, revision, state, expiresAt, sourceRefs, recordId, recordLink, errorCode, warnings`) + `ownerUid, createdAt, updatedAt, savedAt, savedBy`. |
| `…/{tk}/events/{seq:8}` | all task transitions | `taskId, eventId, sequence, type, emittedAt, payload`. |
| `assistantExecutions/{draftId}_{revision}` | confirm | `draftId, taskId, ownerUid, revision, requestId, payloadHash (sha256 of canonical payload), status saved\|conflict, recordId, errorCode, createdAt`. No content. |
| `assistantRequests/{sha(uid\|op\|clientRequestId)}` | idempotent commands (quote, clarify, patch, confirm, feedback) | `uid, op, inputHash, response (JSON of the answer), createdAt`. Same id + other input → `IDEMPOTENCY_CONFLICT`. |
| `families/{f}/quota/assistant_*` + `families/{f}/quotaOps/assistant_<taskId>` | `quota.ts` | Shared ledger; `units` = credits; `holder` = taskId. Windows: `assistant_cal_<yyyy-mm>` (Free, household zone), `assistant_paid_<grantId>_<periodStart date>` (Premium). |
| `users/{uid}/settings/ai.assistant` | `setAssistantConsent` | `{ version: 'assistant-consent-v1', grantedAt } \| null` beside the summaries `consent`. |

Domain documents written for confirmed drafts (Rules shapes, `source: 'assistant'`, deterministic ids):

| Draft | Document | Id |
|---|---|---|
| bottle / breast / sleep | `babies/{b}/records/{r}` (exact `validNewRecord` key set, author from the member doc, `createdAt/updatedAt` server time, `clientCreatedAt` = confirm time, deleted fields, `data` per type) | `r_<hash(draftId)>` |
| observation | `babies/{b}/checkins/{ci}` (revision 1, `since: null, tried: [], healthSigns: []`) | the app's id `ci_<sha(babyId\|uid\|date\|observation)>` |
| feedback | `babies/{b}/recFeedback/{fb}` | `fb_<hash(uid, taskId, contentId, version)>` |

The existing `onRecordWritten` trigger then recomputes day summaries and opens sleep-overlap
conflicts exactly as for app writes.

## Indexes (`firebase/firestore.indexes.json`)

- `assistantConversations`: `ownerUid ASC, scope.babyId ASC, updatedAt DESC` (history list).
- `assistantTasks`: `ownerUid ASC, state ASC` (consent withdrawal); `conversationId ASC, ownerUid ASC`
  (conversation deletion).
- Existing `records (type, deleted, occurredAt)` serves the overlap check; single-field indexes serve
  `assistantTasks.state` (sweeper), `assistantQuotes.expiresAt`, `events.sequence`,
  `messages.sequence` / `messages.taskId`.

## Retention

| Data | Kept | Removed |
|---|---|---|
| Conversations, messages, tasks, drafts, events | until the owner deletes the conversation (`deleteAssistantConversation`) or the account / baby deletion jobs run | delete conversation: all of these for that conversation |
| Quotes | short-lived | `sweepAssistant` deletes quotes whose `expiresAt` is over a day old |
| Executions, request ledger | ids and hashes only (no content) | not swept yet (open: TTL policy, see below) |
| Credit ledger (`quota`, `quotaOps`) | for the window's life (audit) | as other quota windows |
| Domain records written by confirm | as any record of the module | never by assistant deletion |

Open in A2, closed by A3 (see "Photos and lifecycle (slice A3)" below): account / baby deletion
purges, the TTL for `assistantExecutions` / `assistantRequests`, attachments.

## Care fields (slice A5)

- `assistantTasks/{tk}.care` (server-written, owner-readable like the task): `{ topic:
  sleep_concern | meal_ideas, sleep: { kind, when, since } | null, guidance: { contentId,
  contentVersion, reasonCode, reviewed, title{vi,en}, timeOfDay } | null, recipeIds[], plan: {
  contentId, contentVersion, plannedFor, plannedAt, feedbackOpensAt } | null, feedback: {
  contentId, contentVersion, outcome, at } | null }`. Facts are what the person reported (choices),
  never a cause.
- `babies/{b}/recFeedback/fb_<hash('feedback-started', uid, task, content, version)>`: kind
  `started` for "Thử tối nay" (same keys as the app's document); the outcome keeps the A2 id.
- `publicConfig/content_rhythm.recipes[]` (optional; contracts `recipeSchema`): published with the
  rhythm content; the portal approval records the review on recipes as on activities.
- No new collection, index or Rules change.


## Photos and lifecycle (slice A3)

| Path | Written by | Fields |
|---|---|---|
| `assistantAttachments/{at_<hash(uid, clientRequestId)>}` | `createAttachmentUpload`, `startTask` (bind), worker, confirm, retention | `id, ownerUid (= uploaderUid), familyId, scope, quoteId, storagePath (assistant/{uid}/{id}), mime, bytes (declared max), sha256 (client's, informational), sha256Server (computed from the bytes by the worker; household duplicate check), retention delete_after_read\|keep_with_record, state uploading\|ready\|deletion_pending\|deleted, generation (verified at start), taskId, uploadExpiresAt (+15 min), rejected, keptPath (the expense receipt copy), savedExpenseIds[], deletion {attempts, nextAttemptAt, lastError: 'storage'}\|null, deletedAt (set only once Storage confirmed), orphan, createdAt, updatedAt`. Owner-readable (Rules `assistantOwner`), never client-written. |
| `assistantTasks/{tk}/imageReading/current` | worker settle | The normalized reading (`ImageReading`: document kind, receipt fields with evidence snippets, note lines — medicine lines keep only their kind, no text), `sha256s`, `keepReceipt`, `promptVersion`, `savedAt`. Kept only while a question is open; deleted in the same settle transaction otherwise. Never client-readable. |
| `assistantQuotes/{qt}.attachmentsIssued` | `createAttachmentUpload` | Upload targets handed out for this quote (≤ `attachmentCount`). |
| `…/messages/{seq}.attachmentIds` | `startTask` | The photos the user message carried. |
| Storage `assistant/{uid}/{at_*}` | the app (once) | The uploaded original. Rules: owner, `resource == null`, `at_` + 32 hex, image allowlist, ≤ 8 MB, and the attachment document says `uploading`, same MIME, size ≤ declared, target unexpired. No client read / update / delete. |

Domain documents for confirmed photo drafts (exact Rules key sets; deterministic ids):

| Draft | Document | Id |
|---|---|---|
| expense | `babies/{b}/expenses/{x}`: `amount (whole VND), categoryId, note (merchant, ≤ 80), spentOn, payer (the confirmer's label, else null), receiptPath (null or babies/{b}/expenses/{x}.jpg), source: 'assistant', sourceRef: draftId, createdBy, author, createdAt, updatedAt, updatedBy, deleted: false, deletedAt: null, deletedBy: null` (`validNewExpense` key set) | `x_<hash(draftId)>` |
| expense receipt (keepReceipt) | Storage `babies/{b}/expenses/{x}.jpg`: re-encoded JPEG ≤ 2048 px, ≤ 4 MB, no metadata (the Chi tiêu receipt path and Rules) | — |
| reminder | `babies/{b}/reminders/{rm}`: `id, babyId, title, dueAt, leadMinutes: 60, notifyDevice: null, createdBy, author, createdAt, updatedAt, updatedBy, done: false, doneAt/doneBy/doneAuthor: null` (`validNewReminder` key set — it has no `source`, so provenance is the execution row) | `rm_<hash(draftId)>` |

Queries (single-field indexes only; no new composite index): attachments by `taskId`, `ownerUid`,
`scope.babyId`, `sha256Server`, `state in […]`; tasks / conversations / quotes by `ownerUid` or
`scope.babyId`; executions by `ownerUid`, `taskId`, `createdAt <`; requests by `uid`, `createdAt <`;
collection group `imageReading` by `savedAt <` (single-field, automatic); expenses by `spentOn`
range.

### Retention (A3)

| Data | Kept | Removed |
|---|---|---|
| Uploaded photo, "xoá sau khi đọc" (opt-out) | until the reading is settled or the task stops | right after settle / cancel / consent withdrawal; `deleted` only when Storage confirms, else `deletion_pending` + retry (backoff 2, 4, 8 … min, ≤ 6 h) |
| Uploaded photo, "giữ ảnh hoá đơn" (**default**, D-075 #3) | while an unsaved expense draft with `keepReceipt` can still be saved (TTL 24 h), or while a question on a photo with a receipt is open; a photo with no receipt (a note) goes right after reading | after the save (a re-encoded copy stays with the expense), or when the draft is discarded / expires / the task fails or is cancelled |
| Uploads never started | — | target expiry + 1 h (sweeper) |
| Photos of a blocked task | 24 h (resume) | then deleted |
| Cached photo reading | while a question is open | at settle; leftovers after 1 day (daily cleanup) |
| Expired, unsaved drafts | **kept** (state and payload) with the owner's conversation — the same content is in its messages, so trimming the draft alone would not reduce exposure | with the conversation, the account or the baby |
| `assistantExecutions`, `assistantRequests` | 30 days | daily cleanup |
| Attachment rows | with their task | with the conversation / account / baby; a pending deletion keeps its row (`orphan`) until Storage confirms |

Lifecycle jobs (`account.ts`): **account deletion** (step `personal`) releases open reservations and
deletes the person's conversations, messages, tasks (drafts, events, readings), quotes, Storage prefix
`assistant/{uid}/`, attachment rows, execution rows and request ledger; the domain records they
confirmed stay with the family (marked "Người dùng đã xoá" by `authored`). **Baby deletion** (step
`documents`) deletes every member's assistant tasks, conversations, quotes, attachments (objects one
by one) and execution rows scoped to that baby. **Consent withdrawal** deletes every photo of the
person (and A2 stops their open tasks). The provider keeps nothing (`store: false`); device copies
and backups are outside the server's reach (said in the consent text).

