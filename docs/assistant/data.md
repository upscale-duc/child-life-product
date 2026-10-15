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

Open (not in A2): account / baby deletion jobs do not yet purge `assistant*` collections; a TTL for
`assistantExecutions` / `assistantRequests`; attachments (`assistantAttachments`, Storage) arrive with
A3.
