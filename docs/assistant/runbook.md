# Child Life Assistant — runbook (v3, 2026-10-15)

Operations for the chat assistant (CH01–CH28): switches, credits, rollout on dev, checks after a
deploy, recovery and incidents. Design: [`architecture.md`](architecture.md), [`api.md`](api.md),
[`usage.md`](usage.md), [`security.md`](security.md); quality gate: [`evaluation.md`](evaluation.md);
evidence: [`docs/development/assistant-test-report.md`](../development/assistant-test-report.md).
Style and shared steps follow [`docs/operations/premium-rollout.md`](../operations/premium-rollout.md).

Everything ships dark: all six assistant flags default **off** (scope `internal`,
`packages/contracts/src/config.ts`). Deploys go through `scripts/deploy.sh dev <targets>` only.
**Production** (deploys, IAM, secrets, flags, credit numbers, campaigns) needs the owner's explicit
approval (`CHILD_LIFE_PROD_APPROVED=yes`, CLAUDE.md) and the gates in §9. There is no staging: dev
(`child-life-dev`, `test_` families) is where the brief's staging checks run (D-072 #4).

## 1. Switches (P-161) — portal "Tính năng & phát hành", `config/flags`

Each flag has `enabled`, `scope` (`internal` → families marked internal plus the families picked in
the portal, `percent`, `all`) and an optional notice. Flags are read per family on every call and in
the worker, so a change applies to the next call without a deploy.

| Flag | Off means | Tasks already in flight |
|---|---|---|
| `assistant` | No chat: quote, start, clarification answers, confirm, feedback, "Thử tối nay" and upload targets answer `FEATURE_DISABLED`. History, task snapshots, edit / discard / cancel and conversation delete keep working. Direct logging and the in-app health guide are unaffected (health support *inside the chat* needs this flag). | `queued` → the worker fails them `FEATURE_DISABLED`, credits released. `awaiting_clarification` → answers refused; released when the clarification expires (30 min, `sweepAssistant`). `ready` drafts cannot be saved while off; they keep their 24 h TTL, so turning the flag back on within a day lets them save. |
| `assistant_live` | No new model calls: the quote says `AI_UNAVAILABLE`; `startTask` creates the task `blocked` with **nothing reserved** (the input is kept). Health support (keyword signs) still answers, free. | `queued` and newly answered clarifications fail `AI_UNAVAILABLE`, released. Ready drafts still save (no model, no credits). Also triggered automatically when the provider key is missing or the monthly AI budget (`config/ai`) is spent. |
| `assistant_images` | No photo quotes or upload targets; `startTask` with photos `FEATURE_DISABLED`. Text tasks unchanged. | Queued photo tasks are refused in the worker (released); their photos are deleted by `sweepAssistantFiles` per retention. Ready expense / reminder drafts still save. |
| `assistant_care` | Care questions (sleep guidance, recipes) get the notice `CARE_FEATURE_DISABLED`; logging and log questions in the same message still run. Health support never depends on it. | A care round still running settles to the notice; released when nothing else was useful. Plans and feedback on earlier guidance keep working (0 credits). |
| `assistant_writes` | `confirmDrafts` answers `FEATURE_DISABLED`: nothing new is written to care, Chi tiêu, reminders or check-ins from the chat. Direct module writes are unaffected. | Drafts wait; past their 24 h TTL they expire (`DRAFT_EXPIRED`). Credits already committed for useful drafts are not refunded (by design, `usage.md`). |
| `assistant_upsell` | Out of credits shows only the reset date, never a purchase prompt (CH21 without "Nâng cấp"). App-side only (`getCapabilities`). | None. |

Related switches outside the assistant: `ai_assist` (AI summaries; template when off),
`premium_billing` (purchases), `config/entitlements.regions.advanced` (care guidance and recipes are
`REGION_UNSUPPORTED` outside it; logging is not), `config/ai.monthlyBudgetVnd` (portal "Hệ thống &
AI"; spent → every model call stops, assistant and summaries).

## 2. Credits and beta campaigns (D-075 #1) — portal "Premium & Cá nhân hoá"

- **Cấu hình › Credit trợ lý AI** (`config/entitlements.quotas.assistant`): Free per calendar month
  (QA 20), Premium per billing period or per month for a beta (QA 200), credits per text task (1) and
  per photo task (3). AI summaries charge the same pool (1 credit, `aiSummaryCredits`). Every number
  is **QA configuration, not an offer** (Q-071); changing them on prod is an owner decision.
- A new limit applies to **new windows**: the limit is frozen into a window when it is created, so a
  change mid-month affects households whose window for this month does not exist yet. Never edit
  `families/{f}/quota/*` or `quotaOps/*` by hand.
- **Chiến dịch beta**: a campaign may give any Premium capability (D-075 #1); "Trợ lý AI › Hạn mức
  trợ lý Premium" (`assistant.premium_budget`) gives the 200-credit monthly budget, cut to the
  campaign's dates. Always set `validFrom` / `validUntil`, the audience (internal → percent) and a
  reason. When it ends the household returns to the Free window of that month (its own limit, its
  own usage); nothing already prepared is lost.
- Precedence when several grants give the budget: paid, promo, beta, then the latest end
  (`assistant-usage.ts`). A beta with group A only keeps the Free budget.

## 3. Rollout (dev only until §9)

1. **Check the tree**: deploy from a clean worktree at the commit you mean (parallel sessions share
   the tree; never deploy someone else's uncommitted change). `pnpm --filter @child-life/contracts
   --filter @child-life/web-config run build`, then typecheck, lint and the suites in the test report.
2. **Rules and indexes**: `scripts/deploy.sh dev firestore:rules,firestore:indexes,storage`
   (rules blocks "Child Life Assistant" in `firestore.rules` and `storage.rules`; assistant indexes
   in `firestore.indexes.json`, see `data.md`). Check `git log` holds every peer's rules first.
   Wait until the indexes are built (Firebase console) — the emulator does not enforce them.
3. **Functions** — the assistant set only:
   `scripts/deploy.sh dev "functions:setAssistantConsent,functions:quoteTask,functions:startTask,functions:submitClarification,functions:patchDraft,functions:confirmDrafts,functions:discardDraft,functions:cancelTask,functions:submitAssistantFeedback,functions:getAssistantUsage,functions:listAssistantHistory,functions:getAssistantTask,functions:deleteAssistantConversation,functions:planAssistantActivity,functions:createAttachmentUpload,functions:runAssistantTask,functions:sweepAssistant,functions:sweepAssistantFiles,functions:cleanupAssistant"`
   plus, for D-075 #1, `generateSummary`, `listSummaries`, `getCapabilities`, the account deletion
   functions and the staff config callables the portal uses. Then §4.
4. **Portal**: `scripts/deploy.sh dev hosting:admin`.
5. **Secret** (needed only for live model calls, BLOCKED today): `OPENAI_API_KEY` in Secret Manager on
   `child-life-dev` with owner approval for the spend; `OPENAI_MODEL` defaults to `gpt-4.1-mini`.
   Without it the assistant answers `AI_UNAVAILABLE` and reserves nothing.
6. **Flags on dev, in order, for `internal` families with `test_` data**: `assistant` →
   `assistant_writes` → `assistant_live` (only after the key exists) → `assistant_images` →
   `assistant_care` (after content review status is clear) → `assistant_upsell` (only with
   `premium_billing`, D-074). Set the consent copy version first (CH26, Q-076).
7. **Watch** (§8) for a day before widening on dev. Widening beyond `internal` on prod is §9.

## 4. After every deploy

- **Callable invoker (dev)**: some v2 callables on `child-life-dev` lose the public Cloud Run invoker
  and answer an HTML 403, so the app just errors. POST without auth to each new or updated callable:

  ```sh
  for f in setAssistantConsent quoteTask startTask submitClarification patchDraft confirmDrafts \
    discardDraft cancelTask submitAssistantFeedback getAssistantUsage listAssistantHistory \
    getAssistantTask deleteAssistantConversation planAssistantActivity createAttachmentUpload \
    generateSummary listSummaries getCapabilities; do
    printf '%s ' "$f"
    curl -s -o /dev/null -w '%{http_code} %{content_type}\n' -X POST \
      -H 'Content-Type: application/json' -d '{"data":{}}' \
      "https://asia-southeast1-child-life-dev.cloudfunctions.net/$f"
  done
  ```

  JSON 401 (`UNAUTHENTICATED`) is healthy. An HTML 403 needs (dev only without approval):

  ```sh
  gcloud run services add-iam-policy-binding <lowercase-name> --region asia-southeast1 \
    --project child-life-dev --member=allUsers --role=roles/run.invoker
  ```

  `<lowercase-name>` is the function name in lower case (`quotetask`, `confirmdrafts`, …). Never add
  it to event or schedule services (`runassistanttask`, `sweepassistant`, `sweepassistantfiles`,
  `cleanupassistant`, `warmassistant`). Prod IAM changes need the owner.
- **Warm-up (Lumi L2)**: `startTask` and `getAssistantTask` answer `{"data":{"warmup":true}}` with
  `{"result":{"warm":true}}` (200) before any auth or read; `warmAssistant` sends it every 5 min from
  06:00 to 23:59 Asia/Ho_Chi_Minh (no `minInstances`, owner 2026-10-19). A non-200 ping logs
  `assistant warm-up` with the status and milliseconds.
- **Worker trigger** exists on `assistantTasks/{taskId}` and the four schedules show in Cloud
  Scheduler (`sweepAssistant` every 10 min, `sweepAssistantFiles` every 15 min, `cleanupAssistant`
  daily 03:20 Asia/Ho_Chi_Minh, `warmAssistant` `*/5 6-23 * * *` Asia/Ho_Chi_Minh). Since Lumi L2
  text tasks run inside `startTask` / `submitClarification`; the trigger runs photos, hand-offs (an
  inline run out of time) and requeued tasks.
- **Time to card (Lumi L2)**: per-hop timings, ids and states only:

  ```sh
  gcloud logging read 'jsonPayload.message="assistant timing"' --project child-life-dev \
    --freshness=1d --format='value(timestamp,jsonPayload.op,jsonPayload.path,jsonPayload.state,jsonPayload.totalMs)'
  ```
- **Smoke test** with a `test_` family on a device: consent → text batch → drafts → save one →
  history; with `assistant_live` off the task must be `blocked AI_UNAVAILABLE` and the pool unchanged.
- **Logs** carry ids, states and reason codes only; any chat text, amount or path in a log line is an
  incident (§7).

## 5. Recovery

### Stuck tasks and leases

- `processing` with an expired lease (worker died; lease = 300 s) → `sweepAssistant` requeues it;
  the attempt counter caps at 3, then the task fails `AI_UNAVAILABLE` and releases. A late worker is
  fenced (lease holder check) and can neither commit nor write.
- `awaiting_clarification` older than 30 min → failed `QUOTE_EXPIRED`, released, by the sweeper.
- **`queued` that never ran** (the trigger did not fire or threw before claiming): `sweepAssistant`
  nudges a task untouched for 10 min (version bump re-fires the trigger) up to 3 times, then fails it
  `AI_UNAVAILABLE` and releases its credits once. Look a task up in the portal "Trợ lý AI" › Tasks
  (`staffAssistantTask`: states, credits, ledger reservation, events — no content).
- `blocked` tasks hold nothing; they resume only when the person sends the same request again.

### Quota reservations

- Chat reservations are settled by the task lifecycle: commit once on a useful result, release on
  everything else, on cancel, on clarification expiry, on the attempt cap and on consent withdrawal.
- **Leftovers are swept**: `sweepAiQuota` (`quota-sweeper.ts`) releases, once, reservations older than
  30 min whose feature starts with `ai_` (legacy summaries) or that are summary credits in the
  `assistant` pool (`su_*`, D-075 #1). Chat task reservations are left to `sweepAssistant`
  (`assistant-worker.ts`), which requeues a dead worker's task and nudges a task left `queued` for
  10 min (version bump re-fires the trigger) up to 3 times, then fails it `AI_UNAVAILABLE` and
  releases its credits once. Do not edit ledger documents by hand.
- Detect leftovers anyway: `collectionGroup('quotaOps')` with `state == 'reserved'` and `reservedAt`
  older than 1 h should be empty.
- Wrong numbers for a household: raise the limit in the portal (new windows) or give a beta
  campaign; never write `families/{f}/quota*`.

### Photo deletion failures (`deletion_pending`)

- A failed Storage delete marks the attachment `deletion_pending` with a retry time (2, 4, 8 … min,
  capped at 6 h); `sweepAssistantFiles` retries **without a limit**. The app shows "đang xoá", never
  "đã xoá", until Storage confirms (G05).
- Watch: `assistantAttachments` where `state == 'deletion_pending'` and `deletion.attempts ≥ 5`.
  Check the bucket IAM of the functions service account and that the object still exists; once the
  cause is fixed the next sweep deletes it. Never set `deleted` by hand.
- Unused upload targets are deleted 1 h after they expired; a `blocked` task keeps its photo 24 h.

### Provider outage or bad output

1. Function logs show `ModelUnavailable` kinds (`timeout`, `http`, `network`, `empty`, `json`) — never content.
2. Tasks already queued fail `AI_UNAVAILABLE` and release; nobody is charged.
3. If it lasts or answers look wrong: turn **`assistant_live` off** (new tasks `blocked`, nothing
   reserved; drafts still save). AI summaries have their own switch, `ai_assist` (template answers),
   and also fall back to the template when the provider fails.
   For wrong photo readings only, `assistant_images` off; for care, `assistant_care` off.
4. Spend spike: lower `config/ai.monthlyBudgetVnd` (portal "Hệ thống & AI") — reaching it stops every
   model call. Investigate per-task `modelCalls` / `model` / `promptVersion` on `assistantTasks`.
5. When back: turn the flag on; people resend from the kept input (same words, new task).

### Consent withdrawal (CH26, P-160)

`setAssistantConsent` with consent off: `queued`, `received`, `blocked` and `awaiting_clarification`
tasks fail `CONSENT_REQUIRED` and release; a task already running drops its output at settle;
**every photo of the person is deleted** (Storage-confirmed, else `deletion_pending`). Saved records
stay. Support never re-grants consent for a person.

### Account and baby deletion

- Account deletion (`account.ts` → `purgeAssistantForUser`) removes the person's conversations,
  tasks, drafts, quotes, attachments and the Storage prefix `assistant/{uid}/`, and **their
  messages in shared baby threads** (the thread stays for the others). Confirmed domain records follow
  their module (they stay with the family).
- Baby deletion (`purgeAssistantForBaby`) removes every member's assistant data about that baby,
  including the shared thread `cv_<babyId>`.

### Shared-thread deletion (D-075 #2)

A Cùng nuôi may delete the baby's shared thread (`deleteAssistantConversation`); a Người chăm sóc
may not. It removes the chat, its tasks and drafts for everyone (photo and spending tasks are never in
the shared thread; they stay with their author); open work is released; saved
expenses, reminders, records and check-ins stay. The app explains this before deleting. There is no
undo — restore requests are declined.

### TTL

`cleanupAssistant` (daily) deletes execution rows and the request ledger after 30 days and stale
photo readings; `sweepAssistant` deletes quotes older than a day.

## 6. Rollback

| Problem | Do | Never |
|---|---|---|
| Wrong / unsafe model output | `assistant_live` off (or the narrower `assistant_images` / `assistant_care`) | Delete people's tasks or drafts |
| Bad saves into modules | `assistant_writes` off; fix; the person re-saves within the TTL | Edit domain records in bulk |
| Credit bug | Raise limits (new windows) or a beta campaign; flags off if charging is wrong | Edit `quota*` / `quotaOps` |
| Functions regression | Redeploy the previous commit's assistant functions from a clean worktree (`git worktree add … <sha>`, build, `scripts/deploy.sh dev functions:<names>`), then §4 | Deploy from a tree with others' uncommitted changes |
| Rules regression | Redeploy the previous `firestore.rules` / `storage.rules` after checking every peer's rules are in it | — |
| Contract change breaks old apps | Old app versions read unknown part types as a safe card (`DT` "an unknown part type or a newer schema is a safe placeholder"); keep the server's `contractVersion` compatible or gate by app version (`config` app update) | Remove a part type the shipped app renders |

A rollback never loses data: saved records, history, drafts within TTL and credits already settled
stay; only new work stops.

## 7. Incidents

1. **Contain** with the narrowest flag (table §1). For a privacy issue (child data in logs, a photo
   readable by the wrong person, a cross-family read) turn **`assistant` off** at once.
2. **Record** a support ticket with redacted ids only: `taskId`, `familyId`, time, reason code — never
   chat text, photos, amounts or names (brief p.26).
3. **Assess**: which households, which tasks (`assistantTasks` by state / `errorCode` / `updatedAt`),
   credits (`quotaOps` by holder), writes (`assistantExecutions` by draft id → `recordId`).
4. **Fix** in code with a test reproducing it; deploy to dev, re-run §4 and the suites.
5. **Tell** affected families when their data or credits were touched (owner decides wording);
   restore credits only through a campaign or limit change, never by editing the ledger.
6. **Prod** steps (deploy, IAM, secret rotation, flag changes for real families) need the owner's
   explicit approval each time.

## 8. Monitoring (what exists today)

- No `appEventsDaily` counters for the assistant yet (gap). Use Firestore queries on
  `assistantTasks` (state, `errorCode`, `modelCalls`, `model`, `promptVersion`), `assistantAttachments`
  (`deletion_pending`) and `quotaOps` (`reserved` age), the scheduled functions' count logs
  (`assistant sweep`, `assistant files swept`, `assistant cleanup`) and `config/ai` spend.
- Alert-worthy (manual check until alerts exist): queued > 15 min, `deletion_pending` attempts ≥ 5,
  reservations > 1 h, `AI_UNAVAILABLE` rate > 10 % in an hour, AI budget > 80 %.

## 9. Gates before production (brief p.25–26)

- [ ] Every CH01–CH28 row of `figma-coverage-checklist.md` §22 end to end on dev, iOS and Android,
      Light and Night care (no Night care frames exist in Figma: design review of the token-built
      Night versions).
- [ ] Live evaluation passed the thresholds in `evaluation.md` §6, with human review in vi and en;
      model / prompt versions recorded.
- [ ] Consent and retention copy (CH26, G05, Q-076) and the provider's processing terms approved;
      App Check decision for the assistant callables.
- [ ] Care content, recipes and health numbers reviewed per region (Q-069); placeholders off.
- [ ] Credit numbers, Premium price and beta plan decided (Q-071); store payments (D-074) before
      `assistant_upsell` / `premium_billing`.
- [ ] Races (M02, M03) and indexes verified on dev with `test_` families; stale-reservation and
      stuck-`queued` recovery implemented (§5).
- [ ] 0 critical privacy / safety / charging failures in the test report.
