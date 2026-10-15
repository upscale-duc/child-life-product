# Child Life Assistant — security, consent and retention (slices A2–A3, 2026-10-15)

Sources: brief v3 p.14–15, p.19 ("Bảo mật, consent & retention"), p.24 (M06, M07, M09); Figma CH09,
CH12, CH14, CH26 and gap G05 (`docs/discovery/figma-extract/31-chat-assistant.md`); decisions P-156,
P-157, P-158, P-160 and open questions Q-076–Q-078 (`docs/product/business-map.md`). Code paths are
under `firebase/functions/src/assistant*.ts`; Rules in `firebase/firestore.rules` and
`firebase/storage.rules` (blocks "Child Life Assistant").

> The model reads and prepares; the server decides and writes. Every check below runs on the
> server, because the Admin SDK bypasses Rules.

## 1. Authentication and authorization

| Check | Where |
|---|---|
| Signed-in **account** (anonymous "Vào ngay" refused, `account-required`); uid from the token only | `assistantCall` → `requireAccount` (`index.ts`) |
| Active membership of the scope's baby on **every** call (quote, upload target, start, clarify, patch, confirm, read); `NOT_MEMBER` without saying whether the baby exists | `loadTrustedScope` (`assistant-common.ts`) |
| Owner-only tasks, drafts, conversations, attachments (P-158); a foreign id reads as `NOT_MEMBER` | `ownTask`, `verifyAttachmentsForStart`, Rules `assistantOwner` |
| Role per module at prepare **and** at confirm (roles can change after the preview, M05): care / check-ins `rhythm.checkin`; Chi tiêu Cùng nuôi or `extraRights.recordSpending`; reminders Cùng nuôi only; feedback `rhythm.feedback` | `moduleAllows` (`assistant-tools.ts`), `confirmDraftItem` |
| The scope is bound at task start; tools read only `babies/{scope.babyId}/…` and the household's quota; the model never names a path, uid, collection or URL | `TrustedScope`, read / prepare tools |
| Paid plans never change a role ("Premium không đổi vai trò") | `familyCan` / module checks ignore the plan |

App Check is **not enforced** on the assistant callables yet (no callable in the repo enforces it);
it should be switched on with the app's App Check rollout (open item, owner decision).

## 2. Photos (slice A3)

- **No credits → no upload** (U03, J08): `createAttachmentUpload` gives a target only for the
  caller's unexpired, unused, allowed image quote, re-checking the household's credits, the photo
  flag (`assistant_images`) and the consent at that moment.
- **Owned path, create once**: Storage `assistant/{uid}/{at_*}` — the uploader only, `resource ==
  null`, image MIME allowlist (`jpeg|png|heic|webp`), ≤ 8 MB, and the attachment document must say
  `uploading` with the same MIME, a size no larger than declared and an unexpired target (one
  Firestore read). No client read, update or delete; no public or signed download URL is ever made
  for a receipt.
- **Server file checks** (Rules limit the path, type and size but are not file validation): at
  start the object must exist with the declared type and size (generation pinned); in the worker the
  magic bytes must match the declared type and sharp must decode it within 40 MP / ≥ 32 px **before
  any provider call** (M06). A refused photo is marked `rejected`, its credits released.
- **Minimum sent**: only the chosen photo(s), re-encoded to JPEG ≤ 2048 px with EXIF / GPS / ICC
  stripped; plus the locale, the anchor date / time / zone and the quote's intent hint. No names,
  birth date, household data or other records go to the provider.
- **Photo text is data** (brief p.15): the system prompt says so; the strict reading schema has no
  field for a tool, a URL, a uid or a path; an extra key fails the schema (`rejected`, 0 credits);
  a note line with a link or an e-mail address is never turned into a task; the backend never
  fetches a URL read from a photo or produced by the model; scanned photos are never published to
  Kỷ niệm or sent to relatives.
- **Medicine**: a prescription or a medicine line is never scheduled, never turned into a dose, and
  its text is neither kept (the cached reading keeps only the line kind) nor repeated in the chat.

## 3. Writes

Every domain write goes through a deterministic writer after the person's confirm, producing exactly
the document the app's form writes (the Rules' key sets; a shared-shape test runs each writer's
output against the client create rules), with a deterministic id (replays adopt, never duplicate),
per-item transactions and an execution row (ids and hashes only). Clients can never write
`source: 'assistant'`. A suspected duplicate expense is a warning to acknowledge, never a merge.

## 4. Consent (P-160)

- `users/{uid}/settings/ai.assistant = { version: 'assistant-consent-v1', grantedAt }`, separate from
  the summaries consent. Without it nothing reaches the provider and no upload target is given; the
  rest of the app keeps working.
- Withdrawal: open tasks (`queued`, `blocked`, `awaiting_clarification`) fail with `CONSENT_REQUIRED`
  and release their credits; a running task drops its output at settle; **every photo of the person
  is deleted** (Storage-confirmed, else pending and retried).
- The consent text (CH26, app) must say what is sent (messages, the chosen photos, the minimal
  context), to which provider, that the provider is asked not to store it (`store: false`), how long
  photos stay (§5) and that deleting in Child Life does not reach copies on the device, device
  backups or anything a provider keeps beyond its own terms (brief p.19). The final wording is the
  owner's (Q-076, G05).

## 5. Retention — honest by construction (G05, I05, M07)

| Item | Policy |
|---|---|
| Photo, "Giữ ảnh hoá đơn" (**default**, D-075 #3) | kept only while an expense draft that keeps it can still be saved (24 h) or a question about a receipt is open; on save a re-encoded copy goes to the expense's receipt (Chi tiêu permissions apply) and the original is deleted; otherwise deleted (a note photo right after reading) |
| Photo, "Xoá ảnh sau khi đọc" (opt-out) | deleted right after the reading is settled, or at cancel / consent withdrawal / conversation deletion |
| Never-started uploads | deleted 1 h after the target expired |
| Deletion state | `deleted` + `deletedAt` **only** after Storage confirmed (delete returned and the object is gone); a failure is `deletion_pending` with a retry time (2, 4, 8 … min, ≤ 6 h), retried by `sweepAssistantFiles`; the app must show "đang xoá", never "đã xoá", until then (CH12's footnote must read the snapshot's `attachments[].state`) |
| Cached reading | server-only, kept while a question is open, deleted at settle |
| Conversations, drafts | until the owner deletes the conversation, or the account / baby is deleted (expired drafts keep their state; their photos are released) |
| Executions, request ledger | 30 days |
| Provider | `store: false` on every request; no provider-side deletion is promised beyond the provider's terms |

Account deletion purges the person's assistant data (Storage prefix `assistant/{uid}/` included)
and baby deletion every member's assistant data about that baby; confirmed domain records follow the
module's own rules (they stay with the family, or go with the baby). Deleting a conversation never
deletes a saved expense, reminder, record or check-in — the app explains this before deleting.

## 6. Logging and observability

- Logs carry ids, states, counts and reason codes only: never user text, drafts, readings, photos,
  hashes, amounts, merchants, Storage paths with content, provider requests or replies, tokens or
  signed URLs. `HttpsError` details are reason codes and field names / problem codes.
- Provider failures surface as `ModelUnavailable(kind)` without request or reply text.
- Tasks store `model`, `promptVersion`, `modelCalls`, outcome kind and part types for cost and
  quality tracking; the AI budget is charged per call (`config/ai`), never shown in the app.
- No framework debug trace of raw payloads exists (no Genkit, P-155).

## 7. Open items

- App Check enforcement on the assistant callables (rollout decision).
- D-075 #3 (was Q-076): receipts are kept with the expense by default; the provider retention text
  (G05) is still the owner's copy — it must not promise deletion before it is confirmed.
- D-075 #4 / #5 (were Q-077 / Q-078): done. A receipt in any Chi tiêu currency (`expenseCurrencies`,
  16 codes) is drafted in that currency's minor units; others stay in review. A note line may become
  a date-only reminder, and an assignee is only ever picked from eligible members (never a name read
  from the photo); the writer re-checks the assignee at confirm (`INVALID_ASSIGNEE`).
- HEIC: accepted at upload, but the server decodes only what its sharp build supports; the app
  should convert HEIC to JPEG before upload (a refused photo costs nothing).
- Live provider behaviour on real receipts / notes is not proven by these tests (fake gateway).
