# Child Life Assistant — architecture (v3, 2026-10-15)

Source: brief **Child-Life-Chat-Assistant-Implementation-v3** (28 pages), simulation pack
(`packages/contracts/test/vectors/assistant-v3/`), Figma page `568:18` CH01–CH28, flow map `618:10351`,
components Thẻ nháp `611:7695`, Mức dùng `611:7726`, Ô nhập `611:7763` (extract
`docs/discovery/figma-extract/31-chat-assistant.md`). Contracts: `packages/contracts/src/assistant.ts`.

> Say it or send a photo → the app understands → the parent checks → it goes to the right place.
> The model **reads and prepares**; every domain write is a typed **draft** the person confirms through a
> deterministic endpoint. Free and Premium share every task type with different credit budgets.

## 1. Decisions taken for the repo (proposals P-155–P-161; owner may change)

| # | Decision | Why |
|---|---|---|
| P-155 | **No Genkit for now.** A `ModelGateway` interface in Functions (`assistant-model.ts`) with an OpenAI adapter (raw `fetch`, JSON schema, `store:false`, as `ai.ts` already does, D-003) and a scripted fake for tests. The server — not the model — runs tools: the model returns typed intents / extractions; the worker runs read tools and builds drafts deterministically. | The repo already has the provider pattern; Genkit would be a new bundled dependency tree with dynamic requires (esbuild externals); explicit dispatch is the brief's "kiểm chặt" option. Genkit can wrap the gateway later. |
| P-156 | **Server domain writers** (`assistant-writers.ts`) write care records, check-ins, suggestion feedback, expenses and one-off reminders with the Admin SDK, producing **exactly the documents the Rules accept from the app** (same keys, limits, author block), validated by the contracts schemas, with `source:'assistant'` and a deterministic id from the draft (`r_`/`x_`/`rm_`/`ci_` + hash) so a replayed confirm never writes twice. A shared-shape test checks every writer's output against the Rules on the emulator. | Most modules are client-written with Rules as the only validation; the brief requires confirm through domain services, idempotent per item, partial success. |
| P-157 | **Module support as it exists**: care (bottle, breast, sleep), Chi tiêu (**VND only**, per-baby collection; other currencies → review "Chi tiêu chưa hỗ trợ ngoại tệ"), one-off reminders (**coParent only, date + time required, no date-only, no assignee**), observations = check-ins, feedback = `recFeedback`. **No Tasks, meal log or recipe module** → `MODULE_UNAVAILABLE`; recipes answer "chưa có công thức được duyệt" until reviewed content exists. | Brief: never create a module to satisfy a mock. |
| P-158 | **Conversations are private to their owner**; the owner must still be a member of the scope. Domain records are shared by role; chats are not. | Brief p.8 default. |
| P-159 | **One household credit pool** `assistant` in the shared quota ledger (multi-unit reservations): text 1, photo task 3, health support 0; Free 20 / calendar month (household zone), Premium 200 / paid period — QA config in `config/entitlements.quotas.assistant`, not an offer. AI summaries (handover) keep their own v2 quota until Q-074. Video stays separate. | Brief p.17–18; avoids silently changing shipped v2 behaviour. |
| P-160 | **Consent**: a separate `assistant` consent (messages, photos, context, provider, retention) on `users/{uid}/settings/ai`, version `assistant-consent-v1`; without it nothing is sent to the provider, the app keeps working. | Chat sends photos; scope differs from summaries. |
| P-161 | **Kill switches** (flags): `assistant` (chat overall), `assistant_images`, `assistant_care` (guidance/recipes), `assistant_live` (provider; off = no new model calls), `assistant_writes` (confirm), `assistant_upsell`. Turning care off never blocks summaries or logging; turning the model off keeps history and direct modules. | Brief p.26. |

### 1.1 Owner answers (D-075, 2026-10-15) — override the table above

1. **One credit pool for all AI**: handover / explain / moment summaries charge assistant credits too
   (Free and Premium, different budgets); `ai.assistance` is no longer Premium-only. **A beta campaign may give
   every Premium feature** (group A, Cao cấp templates, the Premium credit budget), chosen per campaign in the
   portal (replaces "Beta A never opens templates" and P-159's separate summary quota).
2. **One shared conversation per baby** for Cùng nuôi and Người chăm sóc (replaces P-158 for child scope);
   messages show who wrote them; **spending stays out**: household / expense tasks remain private to their
   author and never appear in the shared thread.
3. **Receipt photos are kept with the expense** by default (`keep_with_record`).
4. **Chi tiêu supports other currencies** (expense `currency`, amounts in minor units; VND unchanged).
5. **Reminders support date-only and an assignee** (a member who may receive reminders).

## 2. Data (server-written; clients read their own)

| Path | Fields | Read |
|---|---|---|
| `assistantConversations/{cv_*}` | `ownerUid, familyId, scope{type,babyId}, title, locale, createdAt, updatedAt, archivedAt` | owner |
| `…/{cv}/messages/{seq}` | `role user|assistant, parts[] (typed), taskId, sequence, createdAt, attachmentIds` | owner |
| `assistantQuotes/{qt_*}` | `ownerUid, familyId, scope, modality, attachmentCount, credits, pool, windowId, policyVersion, expiresAt, usedBy taskId|null` | owner |
| `assistantTasks/{tk_*}` | `ownerUid, familyId, scope, conversationId, requestId, inputKey, anchorInstant, timezone, locale, modality, quoteId, credits, reservationId, state, version, clarifications[], round, lease{holder,until}, outcomeSummary, errorCode, policyVersion, createdAt, updatedAt` | owner |
| `…/{tk}/drafts/{dr_*}` | `ActionDraft` | owner |
| `…/{tk}/events/{seq}` | `eventId, sequence, type, emittedAt, payload` (coalesced) | owner |
| `assistantAttachments/{at_*}` | `uploaderUid, familyId, scope, storagePath, generation, mime, bytes, sha256, retention, state uploading|ready|deleted|deletion_pending, deletedAt` | owner |
| `assistantExecutions/{dr}_{rev}` | `draftId, revision, requestId, payloadHash, status, recordId, errorCode, createdAt` | none |
| `assistant/{uid}/{at_*}` (Storage) | owner uploads once (`resource == null`), allowlisted MIME, ≤ 8 MB; no client read | — |

Ledger: `families/{f}/quota/{assistant_*}` + `quotaOps` (shared `quota.ts`, `units`).

## 3. Flow

1. `quoteTask` → exact credits, allowed / reason (`USAGE_EXHAUSTED` never calls a model or uploads), usage snapshot, TTL 5 min.
2. Image: `createAttachmentUpload` → owned path → client uploads → server validates (magic bytes, decode with sharp, dimensions) in the worker before any provider call.
3. `startTask(requestId)` → one transaction: verify membership / role / consent / flags / quote → reserve credits (`assistant` window, `units`) → create task `queued` + outbox; same request id + same input → same task; different input → `IDEMPOTENCY_CONFLICT`.
4. Worker (Firestore trigger on `queued`, lease + fencing, ≤ 300 s): build trusted context (scope bound at start; tools read only that scope) → health rule (signals → `health_support`, 0 credits) → gateway extract → validate (schema, allowlist, units, times vs anchor, no future completed logs, AM/PM ambiguity → clarification) → drafts / answer / clarification → commit / hold / release credits (`usageForOutcome`) → events + assistant message.
5. `submitClarification` continues the same task and reservation (≤ 4 rounds).
6. `patchDraft` (revision +1, server validation, 0 credits, no model). `discardDraft`, `cancelTask` (release if no useful output; fenced against late workers).
7. `confirmDrafts` (no model, no credits; works at 0 credits while the draft TTL holds): per item re-check membership, role for that module, scope unchanged, revision, TTL, review; write through the domain writer with a deterministic record id; per-item `saved | failed | conflict`; partial success kept; retry only failed items.
8. `submitFeedback` (0 credits) → `recFeedback`; "Chưa thử" allowed.

Read summaries (CH08) are computed by `careSummary` from records in the scope's local day; the model only words them.

## 4. Security

Auth + membership + action permission on every read / prepare / confirm (Admin SDK bypasses Rules); the model never picks a path, uid, collection or URL; untrusted text in photos is data; unknown tools or part types are rejected (0 credits); no raw prompts, notes, images, tokens or signed URLs in logs; photo deletion shown only when Storage confirms it.

## 5. Build slices (brief p.26, adapted)

| Slice | Content | Agents |
|---|---|---|
| A1 | Contracts (done: `assistant.ts`, multi-unit quota) | — |
| A2 | Server core: config / flags / consent, quote, start, worker + text gateway (fake + OpenAI), clarification, patch, confirm with care / check-in / feedback writers, discard / cancel, usage, history, Rules, tests (pack D, U, S, E; M01–M05, M09–M12) | server-core |
| A3 | Images: attachments + Storage Rules, validation, receipt / note extraction, expense + reminder writers, keep / delete receipt honestly, duplicate warning (reuse spending duplicate key), tests (pack I; M06, M07) | server-images (after A2) |
| A4 | App: chat (CH01–CH08, CH19–CH28) on typed parts, composer, drafts, usage, history, consent, states | app-chat |
| A5 | App: photos and care (CH09–CH18) | app-images-care (after A4) |
| A6 | Portal ops (assistant usage, tasks, kill switches), docs (api, data, tools, usage, security, evaluation, runbook), live eval harness (BLOCKED without key) | portal + me |
