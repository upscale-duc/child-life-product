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
| `listAssistantHistory` | `babyId, conversationId \| null, cursor \| null, limit ≤ 50` | `AssistantHistoryPage<AssistantConversationView \| AssistantMessage>` | `conversationId: null` → the caller's own conversations about `babyId`, newest `updatedAt` first, cursor = last conversation id. Otherwise that conversation's messages, newest first, cursor = last sequence. Other members' chats are never listed (P-158). |
| `getAssistantTask` | `taskId, afterSequence \| null` | `AssistantTaskSnapshot` | Task, drafts (with `problems`), events after `afterSequence` (ordered), the task's messages. The authority on reconnect (M11). Owner and still a member. |
| `deleteAssistantConversation` | `conversationId, confirm: true` | `{ deletedTasks }` | Cancels unfinished tasks (credits released), deletes the conversation, its messages, its tasks with drafts and events. Never touches care records, check-ins, feedback, the credit ledger or execution rows. An already deleted conversation answers `deletedTasks: 0`. |

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
