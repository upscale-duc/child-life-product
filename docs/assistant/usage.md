# Child Life Assistant — credits (usage)

Brief p.17–18, proposal P-159, Figma CH19–CH24 ("Mức dùng", Free gần hết / hết lượt, nâng cấp,
tiếp tục, Premium hết lượt). Code: `firebase/functions/src/assistant-usage.ts` (pool, snapshot),
`quota.ts` (shared ledger, multi-unit reservations), `assistant.ts` (`quoteTask`, `startTask`,
`submitClarification`, `cancelTask`), `assistant-worker.ts` (settle), contracts `creditsFor`,
`usageForOutcome`. Every number below is **QA configuration, not an offer** (Q-071).

A credit is the person's unit of "one assistant task"; it is never a model token. Provider cost is
tracked separately (`config/ai`, 300 VND per call in the AI budget) and never shown in the app.

## What a task costs

| Task                                                                           | Credits (`config/entitlements.quotas.assistant`) |
| ------------------------------------------------------------------------------ | ------------------------------------------------ |
| Text (a log batch, a question about the log, a care question, a meal question) | `textCredits` = 1                                |
| Photo task (receipt, note; 1–3 photos, per task not per photo)                 | `imageCredits` = 3                               |
| Health support (keyword signs at start, or structured signs from the model)    | 0                                                |
| Clarification answers in the same task (≤ 4 rounds)                            | 0 extra                                          |
| Edit a draft (`patchDraft`), save (`confirmDrafts`), discard, cancel           | 0                                                |
| Feedback (`submitAssistantFeedback`), "Thử tối nay" (`planAssistantActivity`)  | 0                                                |
| Direct logging in the modules, templates, video                                | never assistant credits                          |

One logical task is one goal with the quoted input and scope: "8 giờ bú 120 ml, 9 giờ ngủ tới 10 giờ"
is one text task (1 credit) even with two drafts. Widening the scope (another photo, another child)
is a new quote and a new task.

## Pools and windows

One **household pool** (`assistant`) in the shared ledger `families/{f}/quota/{windowId}` +
`quotaOps/assistant_<taskId>` (`units` = credits, `holder` = task id):

| Plan (from stored grants, never the client)                                                          | Limit           | Window                                                                                       | Window id                                |
| ---------------------------------------------------------------------------------------------------- | --------------- | -------------------------------------------------------------------------------------------- | ---------------------------------------- |
| Free                                                                                                 | `free` = 20     | calendar month in the **household's** time zone (family zone, else the baby's, else Vietnam) | `assistant_cal_<yyyy-mm>`                |
| Premium (a valid `paid` or `promo` grant giving `templates.premium` in this environment; beta never) | `premium` = 200 | the grant's paid period (`periodStart` → `validUntil`)                                       | `assistant_paid_<grantId>_<periodStart>` |

The limit is frozen into the window when it is created. A repeated verified purchase event keeps
the same grant id and period, hence the same window (no second pool, M08). An unverified (pending)
purchase gives no paid pool. AI summaries (handover) keep their own v2 quota (Q-074); video keeps
its own.

`getAssistantUsage` / the quote's `usage` (CH19): `plan, limit, used, reserved, remaining = limit −
used − reserved, resetsAt, policyVersion, textCredits, imageCredits`. An unused window reads empty.

## Lifecycle of one task's credits

```
quoteTask ──(no reservation, TTL 5 min)──▶ startTask ──reserve N──▶ worker
                                             │                        ├─ useful result ──────▶ commit once
                                             │                        ├─ asks a question ────▶ hold (same reservation)
                                             │                        │     └─ answered ─────▶ next round, same N
                                             │                        └─ anything else ──────▶ release
                                             └─ 0 left / model off ──▶ blocked (nothing reserved)
```

1. **Quote** (`quoteTask`): exact credits for the modality, `allowed`, and the first failing gate:
   `CONSENT_REQUIRED` → `AI_UNAVAILABLE` (`assistant_live` off, no provider key, monthly AI budget
   spent) → `USAGE_EXHAUSTED` (`remaining < credits`). Never calls a model, never reserves,
   single-use, expires after 5 minutes.
2. **Reserve** (`startTask`): in the same transaction that creates the task, `reserveQuota` holds
   `credits` units in the pool's current window. The quote must still match: owner, scope,
   modality, photo count, plan / grant, credits and window (`QUOTE_MISMATCH` otherwise;
   `QUOTE_EXPIRED` after 5 min). Concurrent starts can never over-reserve (M02).
3. **Hold** while the task waits for an answer (`awaiting_clarification`): the same reservation,
   no new charge, ≤ 4 rounds. An answer later than 30 minutes releases it (`QUOTE_EXPIRED`, the
   task fails; a new quote is needed). The worker's attempt cap (3) counts per run, so all four
   rounds can run.
4. **Commit exactly once** on a useful validated result (`usageForOutcome`): an answer with grounds
   (a log summary, approved care guidance, ≥ 1 approved recipe) or ≥ 1 readable draft — even if
   the person later edits or discards it. Saving drafts is not needed for the charge.
5. **Release** (once, idempotent) on: health support; unreadable or refused photos; provider error
   or timeout; invalid or rejected model output (unknown tool / key / part, advice inside `care`);
   only unavailable modules or a denied role; care paused (`assistant_care` off) or region
   unsupported with nothing else useful; **care fallback** (no approved guidance or recipe fits —
   outcome `fallback`, shown as an answer, state `ready`); photo tasks with nothing to save;
   consent withdrawn or membership lost mid-run; cancel before a result; 3 failed attempts;
   clarification expiry. A late worker after cancel is fenced and can neither commit nor write.
6. **Cancel** (`cancelTask`): unfinished tasks release; a `ready` task keeps its charge (no
   refund after a useful answer).

Every move is an event (`usage_updated { usage, credits }`) and is visible in `getAssistantTask`
(`task.usage`: `none | reserved | committed | released`).

## Exhaustion

- **New work at 0** (or below the task's cost): the quote says `USAGE_EXHAUSTED`; `startTask`
  creates the task **`blocked`** with nothing reserved, keeps the input (text, attachment ids,
  original send instant) and appends a `usage_notice` (`USAGE_EXHAUSTED`, remaining 0). No model
  call, no photo processing.
- **Ready drafts still save at 0** (D08): `confirmDrafts` uses no model and no credits while the
  24 h draft TTL holds — the person never has to buy to save what was already prepared.
- **Health support is free at 0**, also without consent and with `assistant_care` off (U10, J10,
  CH28).
- Direct logging, templates (`templates.premium`) and the video quota are unaffected by an empty
  assistant pool (J09).
- Free exhausted → CH21 (direct logging still works; upsell only with `assistant_upsell`).
  Premium exhausted → CH24 (no extra purchase; wait for `resetsAt`).

## Upgrade and resume (CH22 → CH23)

A `blocked` task resumes when the **same `clientRequestId` and the same input** come back to
`startTask` with a fresh quote. After a verified upgrade the quote is computed at the paid pool, so
the task reserves once there and goes `queued`; "today" stays the original send instant. A replay
of a non-blocked task returns the same task without a new charge (U01); the same request id with a
different input is `IDEMPOTENCY_CONFLICT` (U02). The Free window is not charged for the resumed
task.

## Configuration and kill switches

- `config/entitlements.quotas.assistant` `{ free, premium, textCredits, imageCredits }` (portal);
  `policyVersion` is recorded on quotes and tasks.
- Flags (P-161): `assistant` (all new work), `assistant_live` (model calls; off → blocked
  `AI_UNAVAILABLE`, nothing reserved), `assistant_images`, `assistant_care` (guidance / recipes;
  off → released, logging and summaries keep working), `assistant_writes` (confirm),
  `assistant_upsell`.
- Recovery: `sweepAssistant` (every 10 min) requeues tasks whose worker lease ended, fails
  unanswered clarifications after 30 min (released) and deletes quotes older than a day.
