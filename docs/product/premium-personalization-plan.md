# Premium & Cá nhân hoá (Nhịp lớn lên) — review and plan (2026-10-14)

Source: brief **Child-Life-Premium-Personalization-Implementation.pdf v2.0** (14/10/2026), test pack
`child-life-premium-test-pack` (fixtures v2.0, policy `qa-policy-v2`, 48 synthetic cases, M01–M18 integration
matrix), Figma page **"Cá nhân hoá & Nhịp lớn lên"** `568:18`. The page holds three generations of frames:

- **v1.1 base** (EN00–EN10, NL01–NL10b, PN01–PN04, 2a–5h, B01–B10, D01–D04, 9a–9g; old Wonder Week 6a–6f kept "chỉ
  để tham khảo").
- **v2.0 revision** (label `588:6308`): H01/H02, C01/C02, PS01/PS01F, AC01/AC02, PS02, SU01, MS01, MO01–MO04,
  PR01–PR04, ST01/ST02, HL01, each in VI and EN, plus components `Quyền/Badge` `588:6290`, `Mẫu/Badge` `588:6307`,
  `Mua/Trạng thái` `592:6781`, annotations `595:7034…7124` and the table **"screen → action → capability"**
  `595:7162` (most rows "Ready for review"; PR01, MO04, PR03 "TBD").

Owner request: "Tôi cần 1 kế hoạch chi tiết để triển khai chức năng này … design có thể là bản tham khảo, không cần
theo 100%, chỉ cần phù hợp với logic và thực tế."

Status (2026-10-15): **Phase 0 and Slice 1 built, deployed on dev with every new flag off** (§10). Owner decisions **D-072** (seven answers, §2.1) and Q-067 (name);
open questions **Q-068 – Q-073** (§11). Figma extract: `docs/discovery/figma-extract/30-personalization-premium.md`.
Proposals will take **P-151…**, gaps **G-108…**.

Order of precedence (brief p.7): owner decisions → business invariants of the brief → approved design →
implementation detail. Where Figma and the brief differ, the brief wins and the difference is logged as a G-id.

---

## 1. What the brief and the design settle

**Business contract**

- **Free forever**: Care logging, nutrition, growth/milestones, vaccines, library, Moments basic (album + basic
  templates), age-based content, interests/preferences, basic reminders, the reference calendar, check-in and its
  history, health guidance, and every saved record, summary and export after a plan ends.
- **One household subscription, "Child Life Premium"**, two value groups:
  - **A**: `personalization.cross_module`, `rhythm.advanced`, `ai.assistance` (quota).
  - **B**: `templates.premium` (card and video templates) plus a larger `render.video` quota.
- **Beta A** is a server grant (allowlist + validity + supported region) that opens A only. It never opens B, never
  becomes a charge and never renews by itself.
- **Seven independent checks**, always server-side: auth → membership/role → kill switch + region → grant
  (paid ∪ beta ∪ promo) → consent (AI) → quota/rate → idempotent execute. A client `premium=true` grants nothing.
  Reason codes: `NOT_MEMBER, ROLE_DENIED, REGION_UNAVAILABLE, FEATURE_DISABLED, PREMIUM_REQUIRED,
  CONSENT_REQUIRED, QUOTA_EXCEEDED`. The UI maps each to its own state; only `PREMIUM_REQUIRED` may show a paywall.
- **Template access ≠ render quota.** Quota does not unlock premium templates; a premium card uses no video quota.
- **Health flag → free health flow**, before any ranking or LLM, no upsell, in every plan state.
- **Missing ≠ zero.** Sparse data gives `insufficient_data` / `SELF_REPORTED_NEED`, never a fake insight.
- **Feedback must visibly change the next visit** (AC02 → PS02). A "personalised" badge does not count.

**Design (v2.0 frames)**

| Flow | Frames (VI / EN) | Capability |
|---|---|---|
| Home Free / Beta-Premium | H01 `589:6281`/`589:6544`, H02 `589:6368`/`589:6631` | module.basic · personalization.cross_module |
| Check-in from one observation, contextual follow-ups | C01 `589:6451`/`589:6714`, C02 `589:6492`/`589:6755` | rhythm.checkin (free) |
| Saved result | PS01 `590:6445`/`590:6593`, PS01F `590:6481`/`590:6629` | cross_module / module.basic |
| Activity not tried → tried → feedback | AC01 `590:6515`/`590:6663`, AC02 `590:6558`/`590:6706` | rhythm.advanced |
| Next visit uses feedback | PS02 `591:6495`/`591:6761` | rhythm.advanced |
| Family handover | SU01 `591:6564`/`591:6830` (+ NL10 `574:1222`, NL10b `574:1317`) | ai.assistance |
| Milestone → Moments | MS01 `591:6632`/`591:6898` (+ NL09 `574:1153`) | moments.basic |
| Template library, premium gate, resume, video quota | MO01 `591:6681`, MO02 `592:6782`, MO03 `593:6797`, MO04 `593:6843` (+ EN) | templates.premium · render.video |
| Paywall, purchase states, household plan, expiry | PR01 `592:6826`, PR02 `592:6885`, PR03 `593:6931`, PR04 `593:6990` (+ EN) | billing · history.read |
| Data/AI states, role/region, health | ST01 `594:6967`, ST02 `594:7020`, HL01 `594:7066` (+ EN) | fallbacks |
| Rhythm overview, setup, calendar, real rhythm | NL01–NL07b `569:973`…`573:1199` | wonder.reference · rhythm.* |
| Preferences, notifications, weekly summary | EN01 `559:2288`, EN02 `559:2383`, EN07 `560:2981`, EN09 `561:3102` | personalization.basic |
| Portal | PN01–PN04 `576:3116`…`576:3679` | content / rules / kill switches |

---

## 2.1 Owner decisions (D-072, 2026-10-14)

| # | Question | Owner | What it means |
|---|---|---|---|
| 1 | Who buys and manages the plan | "chỉ chủ hộ (ba hoặc mẹ)" | Only the family owner (`isOwner` Cùng nuôi) sees "Tiếp tục với Premium", restore and "Quản lý"; everyone else sees "Hộ đã có Premium" or "Nhờ chủ hộ nâng cấp" |
| 2 | Caregiver rights | "đồng ý" | Matrix §6.2 as proposed: caregiver checks in and gives feedback, reads the handover, cannot generate AI |
| 3 | Country for existing families | "hỏi" | Asked on first open of Nhịp lớn lên (owner answers; others see "chờ chủ hộ chọn khu vực" and keep free content). Never inferred from locale/IP |
| 4 | Staging | "bỏ qua khái niệm staging chỉ có dev trước. và test trên dev" | Every brief "staging" check runs on `child-life-dev` with `test_` data: indexes, 20-way concurrency, webhooks, store sandbox. No new project |
| 5 | Free age content | "mức cơ bản mà đổi tên được ko thẻ theo tuổi nghe ko hợp lý" | **R0 is in scope** at a basic level (one card per week of age, VI/EN, published like first aid). The name "Thẻ theo tuổi" is internal only; user-facing name **"Tuần này của {bé}" / "{Baby}'s week"** (Q-067, resolved) |
| 6 | Billing stack | "in ap purchase" | `in_app_purchase` (StoreKit 2 / Play Billing) + our own verification and notifications (§5.2). No RevenueCat |
| 7 | Wonder Weeks label | "combine cả hai" | Section "Lịch tham khảo" / "Reference calendar"; stages "Giai đoạn 1 (Wonder Weeks)" / "Wonder Weeks stage 1", with "tham khảo, không phải đối tác" in the source block. The name/model rights check stays a prod release gate |

---

## 2. Where the brief does not fit the repo (must be resolved, not ignored)

| # | Brief / fixture says | Repo has | Plan |
|---|---|---|---|
| 1 | Roles `editor`, `viewer`, `caregiver`, `admin` | Per-baby `coParent` (+ `isOwner`), `caregiver`, `relative` + `extraRights` (`packages/contracts/src/baby.ts:29`, BM §5) | Add an **action matrix** `familyCan(membership, action)` in contracts (pattern of `staffCan`, `staff.ts`). Fixture adapter maps `editor→coParent`, `viewer→relative`. Matrix §6.2 (confirmed D-072 #2) |
| 2 | Household = billing/quota unit | `families/{f}` with `babyIds[]`; babies point to `familyId`; a user can be member of other families' babies | Grants, quota and billing binding live on **`familyId`**; resolve a baby → its `familyId`. Switching baby never moves a grant |
| 3 | `householdTimeZone` | Time zone is **per baby** (`babies/{b}.timeZone`); `Asia/Ho_Chi_Minh` hard-coded in many modules | Facts/calendar keep the baby's zone (already per baby). Add **`families/{f}.timeZone`** only for quota windows (default = first baby's zone); a change applies from the next window (M16) |
| 4 | Country of residence, region gating | **No country field anywhere**; first-aid pack has one `emergencyNumber` (115) | Add `families/{f}.country` (ISO 3166, set by the owner, asked on first open — D-072 #3), `config/regions` for advanced/health/content regions; emergency number per region in content, never a default hotline |
| 5 | B is paid-only | **D-068 #3**: ★ Cao cấp templates are a free beta for everyone; catalog `premium.access: everyone \| hidden` | Add `premium.access: 'subscribers'` (already foreseen at `keepsakes.ts:451`). Switching to it is an owner decision with ≥14-day notice (P-148). Exports already made stay |
| 6 | `createRenderJob (card)` | Cards render **on the phone** (`exportCard`) and are filed by `createMemorySession`, which already checks tier (`memories.ts:211`) | No server card job. Gate premium cards in `createMemorySession` + catalog read. Premium artwork remains downloadable by design (low risk, noted) |
| 7 | Video quota free 1/month, premium 5/period | Count-based caps `activePerBaby 1`, `perFamilyPerDay 10` (`keepsake-jobs.ts:37–39`), no ledger | Keep the caps as the **operational** rate limit; add a **quota ledger** for the entitlement budget. Numbers come from `config/entitlements`, never code |
| 8 | AI with consent | OpenAI behind `AiProvider` (`ai.ts`, D-003), budget `config/ai` with a racy `chargeAi` (`staff.ts:1279`, read-then-set) | Reuse the adapter; add per-user AI consent; make budget charging transactional |
| 9 | Free Home shows age content, milestones, library | v1.1 content features (Thẻ theo tuổi, Mốc, Thư viện, Wonder Week) are **teasers only** (`care_hub_screen.dart:138`) | **R0 builds a basic age-content pack** (D-072 #5) so H01/PS01F have free content; Mốc and Thư viện stay out of this plan |
| 10 | "Wonder Weeks" label | Extract 20 Q#13: brand licensing unresolved; Figma renames to "Nhịp lớn lên (thay Wonder Week)" | Combined label (D-072 #7): "Lịch tham khảo" + "Giai đoạn N (Wonder Weeks)". Stage names are content strings, so they can be renamed without an app release if the rights check fails |
| 11 | Staging for concurrency/index tests | Only `dev` and `prod` | **Dev only** (D-072 #4): `child-life-dev` with `test_`-prefixed synthetic families plays the brief's staging role |
| 12 | Analytics with dimensions (planSource, entryPoint…) | First-party aggregate counters only (`recordAppEvent` → `appEventsDaily`, no SDK) | Extend `appEvents` and allow a small, closed set of dimension suffixes (`event.dim`). Server-side counters for purchase/usage |

---

## 3. What already exists and is reused

| Need | Reused | Where |
|---|---|---|
| Callable pattern, zod, error mapping | `xxxCall` wrappers, `asHttpsError`, `{code, reason}` | `firebase/functions/src/index.ts:286–1875` |
| Per-family rollout + kill switch | `config/flags`, `isFlagOnForFamily`, `mirrorPublicConfig` | `packages/contracts/src/config.ts`, `config-mirror.ts` |
| Feature access to the app | `getFeatureAccess` → becomes `getCapabilities` (superset, old fields kept for old apps) | `features.ts:30`, `keepsake_access.dart:30` |
| Template tier + server enforcement | `keepsakeTier`, `keepsakeTemplateAllowed` | `keepsakes.ts:35,464`, `memories.ts:211`, `keepsake-jobs.ts:144` |
| Render jobs, idempotent request id, Cloud Tasks, sweeper | `requestMemoryStory` (`jobIdOf(uid, requestId)`), `completeKeepsakeJob`, `sweepKeepsakeJobs`, renderer `runJob` claim | `keepsake-jobs.ts:53–692`, `apps/renderer/src/job.ts:78` |
| Two-person publish of content with rollback | First-aid / keepsake catalog workflow | `keepsake-content.ts`, `first-aid.ts`, portal screens |
| Staff RBAC + audit for grants | `staffCan`, `audit` collection, reason required (P-139) | `contracts/src/staff.ts:38–258` |
| AI adapter, JSON schema, template fallback, budget | `AiProvider`, `templateProvider`, `openAiProvider` | `firebase/functions/src/ai.ts` |
| Per-day care aggregates | `babies/{b}/days/{date}` (`sleepMinutes`…), `summarizeDay` | contracts + `onCareRecordWrite` |
| Overlap / open timers | `babies/{b}/conflicts`, `babies/{b}/timers` | `care_models.dart`, `timer_models.dart` |
| Milestones on memories | `babies/{b}/milestones/{id}` | `memory_repository.createMilestone` |
| Today composition per section | `TodaySection` enum + `TodayLayout.fromJson` merge | `today_layout.dart`, `today_screen.dart` |
| Draft surviving router refresh (resume after purchase) | Thiệp/Video drafts kept across refresh (commit `5db75f8`) | keepsakes screens |
| Offline writes with client ids | Care records `r_` + 32 hex, cache-queued | `care_repository.dart` |
| Tests | contracts vitest, `firebase/tests` rules + integration (emulator, `demo-child-life`), Flutter fakes, goldens, `integration_test` | see §7 |

---

## 4. Data model (contracts first, then Firestore)

New contracts files under `packages/contracts/src/`, all pure and unit-tested:

| File | Content |
|---|---|
| `entitlements.ts` | `capabilities` enum (`module.basic, personalization.basic, wonder.reference, rhythm.checkin, health.guidance, moments.basic, history.read, personalization.cross_module, rhythm.advanced, ai.assistance, templates.premium, render.video`), `freeCapabilities`, `reasonCodes`, `grantSchema`, `resolveCapability(input) → ReasonCode \| 'ALLOWED'`, `capabilitySnapshot` |
| `family-actions.ts` | `familyActions` and `familyCan(membership, action)` (§6.2) |
| `quota.ts` | `quotaWindowKey(feature, policy, zone, now, grant?)`, ledger state machine `reserve/commit/release` with invariant `used + reserved ≤ limit` |
| `billing.ts` | provider-neutral `SubscriptionStatus` (`pending, active, grace, on_hold, expired, revoked, refunded`), `normalizeApple(...)`, `normalizeGoogle(...)`, `grantFromStatus(...)` |
| `rhythm.ts` | reference model schema (stages with `startOffsetDays`/`endOffsetDays`, source, reviewer, version), `calendarState(dueDate, today, stage)`, `sleepBaseline(days)`, `observationState(rows)`, check-in schema |
| `personalization.ts` | `userPreferences`, `currentNeed`, content candidate schema, `eligible(...)`, `rank(...)` (score `3·need + 2·interest + 1·helpful − 2·recent − 4·notSuitable`, tie-break id asc, weights versioned), `recommendationSchema` (`id, contentId@version, reasonCode, supportingFactIds, requiredCapability, state, cooldownUntil, generatedAt`), feedback types |
| `ai-summary.ts` | output schema `sections[]{kind, text, factIds[]}, suggestionContentId, language, modelVersion`, `aiGate(...)`, cache key |

Firestore (all new paths are **server-write-only** unless marked ✍ client-writable):

```
families/{f}                         + country, timeZone, entitlementVersion
families/{f}/grants/{grantId}        source paid|beta|promo, capabilities[], validFrom, validUntil (exclusive),
                                     status, billingOwnerUid, provider, sourceTransactionId(masked ref),
                                     environment test|production, campaignId?, updatedAt
families/{f}/quota/{windowKey}       feature, windowStart, windowEnd, zone, limit, used, reserved
families/{f}/quotaOps/{opKey}        immutable: op reserve|commit|release, requestId, jobId, at
billingAccounts/{provider_origTxId}  familyId, billingOwnerUid, environment, productId, status, expiresAt
purchaseIntents/{intentId}           familyId, uid, entryPoint, resume{kind, templateId, draftRef}, expiresAt
billingEvents/{provider_eventId}     dedup ledger: received, processedAt, outcome (no tokens in clear)
users/{uid}/settings/personalization ✍ interests[], digestTime, quietHours, locale (per person)
users/{uid}/settings/ai              ✍ consent {version, grantedAt} | null
babies/{b}/restricted/profile        + dueDate {date, estimated, gestationWeeks?} (co-parent only)
babies/{b}/checkins/{id}             ✍ author, date (baby zone), observation, answers{}, healthFlag, revision
babies/{b}/days/{date}               + complete {by, at} ("ghi đủ", ✍ by care loggers)
babies/{b}/episodes/{id}             ✍ confirmed observation episodes (NL07b), never auto-closed
babies/{b}/recommendations/{id}      server: one primary + ≤2 secondary, reasonCode, factIds, state
babies/{b}/recFeedback/{id}          ✍ started|helpful|unsure|not_suitable|not_today|less_like_this, contentVersion
babies/{b}/summaries/{id}            AI/fallback snapshot: factIds, contentIds, locale, consentVersion, model,
                                     method ai|fallback|cache, dataVersion, status
babies/{b}/facts/state               dataVersion (bumped on every check-in / care edit)
config/entitlements                  catalog, quotas per plan, beta campaigns, regions, AI quota, policyVersion
publicConfig/entitlements            projection without allowlists
publicConfig/rhythm_reference        published reference model (version, reviewer, locales)
publicConfig/content_activities      published activities / age content (need tags, prerequisites, cooldown,
                                     reason templates, review)
```

Indexes to add: `recFeedback` (contentId, at desc), `checkins` (date desc), `recommendations` (state, generatedAt),
collection-group `grants` (environment, validUntil) for the reconciler. Verify in dev (emulator does not enforce).

---

## 5. Architecture

### 5.1 Capability resolver (server, single source)

`requireCapability(db, caller, babyId, capability, opts)` in `firebase/functions/src/entitlements.ts`:

1. `requireAccount` (exists). 2. membership of `babies/{b}/members/{uid}` (active, `accessUntilAt`) →
`NOT_MEMBER`; `familyCan(m, action)` → `ROLE_DENIED`. 3. kill switch from `config/flags` →
`FEATURE_DISABLED`; free capabilities return `ALLOWED` here. 4. `families/{f}.country` ∈ region list →
`REGION_UNAVAILABLE`. 5. union of grants where `environment == serverEnvironment`, `status ∈ {active, grace}`,
`validFrom ≤ now < validUntil`, capability listed → else `PREMIUM_REQUIRED`. 6. AI only: consent →
`CONSENT_REQUIRED`. 7. quota reserve → `QUOTA_EXCEEDED`.

The order of 1–5 must match `verify_reference.py` exactly (fixtures E01–E15). Response shape for every gated
callable and for `getCapabilities`:
`{allowed, reasonCode, entitlementVersion, plan: free|beta|premium|expired|pending, validUntil, autoRenew,
isBillingOwner, quota: {video: {used, reserved, limit, resetsAt}, ai: …}, requestId}`.

The app caches the last `getCapabilities` answer (as `keepsake_access.dart` does) only to draw UI; a cached
badge never skips the server call.

### 5.2 Billing

Decided (D-072 #6): **`in_app_purchase` on the phone + own server verification**, no third-party billing service.

- **Purchase**: app calls `startPurchase(babyId, productId, entryPoint, resume)` → server checks the caller is the
  family owner (D-072 #1) and creates `purchaseIntents/{id}`; the id is passed as Apple `appAccountToken` / Google
  `obfuscatedExternalAccountId`.
- **Verify**: `verifyPurchase({intentId, provider, signedTransaction | purchaseToken})` → Apple: App Store Server
  Library verifies JWS + calls Get Transaction/Subscription Status; Google: `purchases.subscriptionsv2.get` +
  acknowledge. Writes `billingAccounts` + `families/{f}/grants/paid_*` in one transaction; refuses if the original
  transaction is bound to another family (M06).
- **Notifications**: `appStoreNotifications` (onRequest, JWS verified) and `playRtdn` (Pub/Sub). Both only
  **trigger** a refetch of the authoritative status, dedup by event id in `billingEvents`, never apply an older
  state (M07).
- **Reconciler**: scheduled every 6 h for grants expiring within 48 h or in grace.
- **Restore**: re-verify, never rebind to a different family; "Hộ đã có Premium" for other members.
- **Environment**: sandbox transactions produce `environment: test` grants; the prod resolver ignores them (M08).
- **Manage**: deep link to App Store / Play subscriptions of the billing owner's provider only.

### 5.3 Quota ledger and render

- Reserve in the **same transaction** that creates the job in `requestMemoryStory`; op key = `reserve:{jobId}`.
- Commit in `completeKeepsakeJob` only if the job's `attempt`/lease token still matches (fencing); op key
  `commit:{jobId}`. Release once on terminal failure / cancel before worker; op key `release:{jobId}`.
- `retryMemoryStory` after a release reserves again under the same request id rules (Q03).
- A job reserved before expiry finishes on its template snapshot (`KeepsakeJobInput` is already frozen) (M12).
- Window: free = calendar month in `families/{f}.timeZone`; paid = provider billing period of the grant. Beta A
  without paid uses the free budget.

### 5.4 Personalization engine (one engine, not six)

- **Facts builder** (server, `rhythm-facts.ts`): reads `days/{date}`, `checkins`, open timers, open conflicts,
  `complete` markers → valid days → `sleepBaseline` (B01–B06) → facts `{factId, value, unit, window, coverage}`.
- **Eligibility → ranking** (`personalization.ts`): published + reviewed + locale/region + age + prerequisites +
  role + capability, then score; one primary, ≤2 secondary; cooldown 3 days (config).
- **Card order** (brief p.11): health → reminders the user set → current-need suggestion (A) → age milestones →
  Moments opportunity from confirmed milestones → age/interest content. The reference calendar never wins by default.
- **Free Home is composed on the phone** (age content + reminders + calendar, all public/free data, works offline).
  **Advanced cards come from `composeHome(babyId)`** and are stored in `babies/{b}/recommendations` so they are
  readable offline and on the next open (PS02).
- **After check-in**: the check-in is written directly to Firestore (offline-safe, client id = idempotency key),
  then the app calls `nextAction(babyId, checkInId)`. Offline → "Đã lưu" + ST01 offline state, suggestion later.
  `healthFlag` routes to HL01 locally and on the server, before any ranking or AI.
- **Feedback** is free data (`recFeedback`); only *using* it in advanced ranking needs `rhythm.advanced`.
  "Ít kiểu này hơn" updates the user's preferences immediately and is never locked.

### 5.5 Grounded AI (handover, explain, milestone-to-Moments)

`generateSummary(babyId, kind, locale)`: capability `ai.assistance` → health block → facts snapshot → approved
content candidates → AI quota reserve → `AiProvider` JSON → `aiGate` (schema, fact ids ⊆ snapshot, suggestion ⊆
candidates, locale) → snapshot → commit; any failure → deterministic fallback template (NL10b) and release.
Cache key = `baby + dataVersion + candidateVersion + locale + prompt/model + consentPolicyVersion`. Notes from
another person are sent only if that person's consent covers it; never photos, full name, exact DOB. Notes are
quoted as data, never as instructions. Kill switch `ai_assist` independent of entitlement.

### 5.6 Portal

New `Premium` screen (staff `admin+`): capability catalog (read-only), plan quotas, beta campaigns
(allowlist/percent, validity, regions), promo grants with reason + audit, family entitlement viewer (masked
transaction ids), billing event log. `Nhịp lớn lên` screens PN01–PN04 (reference model versions, stages, activities,
rules & health routing, kill switches) on the existing two-person publish workflow. Keepsakes `PremiumPanel` gains
`subscribers`. System → AI policy (consent version, prompt version, quotas, fallback rate). Content editors can never
grant entitlements.

---

## 6. Security, roles, privacy

### 6.1 Rules

- Deny client writes to `grants`, `quota*`, `billing*`, `purchaseIntents`, `recommendations`, `summaries`,
  `facts/state`, `families/{f}` new fields (M04).
- `checkins`, `recFeedback`, `episodes`, `days.complete`: create/update only by members allowed by the matrix,
  `author.uid == request.auth.uid`, shape validated, no cross-baby references (M03).
- `users/{uid}/settings/*`: owner only.

### 6.2 Action matrix (confirmed D-072 #2)

| Action | Cùng nuôi | Người chăm sóc | Người thân |
|---|---|---|---|
| Check-in, mark day "ghi đủ", feedback on a suggestion | ✅ | ✅ assigned baby | ❌ |
| Read check-ins, rhythm, saved summaries (`history.read`) | ✅ | ✅ | 👁 only with `viewDailyCare` |
| Health flow (HL01) | ✅ | ✅ | ✅ |
| Set due date / reference reminders | ✅ | ❌ | ❌ |
| Generate AI summary | ✅ | ❌ (reads the handover) | ❌ |
| Confirm milestone, create card/video | ✅ | ❌ | ❌ |
| Own preferences / AI consent | ✅ | ✅ | ✅ |
| Buy / restore / manage subscription | owner only (D-072 #1) | ❌ | ❌ |
| Set household country / time zone | owner | ❌ | ❌ |

Premium never changes a role (ST02). A member who leaves loses access even with another family's premium.

### 6.3 Privacy and logging

No child data in logs, analytics or crash keys (existing rule). Store transaction ids hashed in logs; tokens never
logged. Analytics events (brief p.20) are counters with closed dimensions, no free text. Clearing caches on logout /
leave uses the existing sign-out path.

---

## 7. Build steps

Every step: contracts vitest, Flutter unit/widget tests, goldens in Light and Night care (VI and EN for new
screens), Rules tests (`pnpm test:rules`), functions integration on an isolated emulator config (see memory
"parallel sessions"), `flutter analyze`, ARB vi/en parity. Checklist rows only after end-to-end on dev, iOS and
Android. Sizes: S ≤ 2 days, M ≤ 1 week, L > 1 week.

### 7.1 Slice 2 build spec (2026-10-15, D-073)

Contracts are done (`rhythm.ts`, `personalization.ts`, commit `68b0c16`; fixtures B/C/R/X pass). Everything
below builds on them; nobody duplicates their logic.

**Firestore** (✍ = written by the phone, Rules-validated; everything else server-only)

| Path | Who | Notes |
|---|---|---|
| `babies/{b}/restricted/profile.dueDate` | `setDueDate` callable (Cùng nuôi, `rhythm.setup`) | `dueDateSchema`; read with the profile as today |
| ✍ `babies/{b}/checkins/{ci_<32 hex>}` | create/update: author = caller, `rhythm.checkin` roles (Cùng nuôi, Người chăm sóc), baby open; delete: author | `checkInSchema` + `createdAt`/`updatedAt` server timestamps; offline-safe |
| ✍ `babies/{b}/recFeedback/{fb_<32 hex>}` | create: author = caller, `rhythm.feedback` roles | `recFeedbackSchema` + `createdAt` |
| ✍ `users/{uid}/settings/personalization` | owner only | `userPreferencesSchema` |
| `babies/{b}/recommendations/{id}` | server | `Recommendation`; read by `history.read` |
| `babies/{b}/facts/state` | trigger | `{dataVersion}` bumped on every check-in, feedback or care record write |
| `publicConfig/rhythm_reference`, `publicConfig/content_rhythm` | staff workflow | readable by signed-in users (add to the whitelist) |
| `content/rhythm/{doc}` + versions | staff workflow | drafts and history, like `content/firstAid` |
| `config/rhythm` | staff (PN04) | `rhythmConfigSchema`; default `defaultRhythmRules` |

Reads of check-ins, feedback and recommendations follow `familyCan(…, 'history.read')`: Cùng nuôi, Người chăm
sóc, Người thân with "Chăm sóc hằng ngày".

**Callables**

- `setDueDate({babyId, dueDate|null})`.
- `nextAction({babyId, checkInId, locale}) → NextActionAnswer`: `rhythm` flag on; health signs → `health`;
  `usual` → `normal`; else with `personalization.cross_module` → `recommend()` over the published content and the
  baby's feedback → store a `recommendations` doc → `suggestion` / `no_suggestion`; without it → `free_content`
  with the age card and `gate` (the reason code). `sleep` filled from `dayQuality` + `sleepWindows` +
  `sleepBaseline` over the last 17 days of records (DATA_INSIGHT only when `change_detected`).
- `composeHome({babyId, locale})`: the current primary recommendation (H02 / PS02) with `changes` and the last
  feedback behind it; `gate` when the household has no group A; never fails the free Home.
- Staff: `staffRhythm` (view), `staffRhythmDraft`, `staffRhythmAct` (`rhythmDraftSchema`, `rhythmActSchema`),
  `staffRhythmRules` / `staffSetRhythmRules` — the first-aid pattern (`content.ts`).
- Dev seed: `scripts/src/seed-rhythm.ts` publishes `content/rhythm/*.seed.json` to dev only.

**Content** (`content/rhythm/reference.seed.json`, `content/rhythm/content.seed.json`, `content/rhythm/SEED-NOTES.md`):
reference stages, activities, weekly / monthly age cards ("Tuần này của {bé}"), health signs, while-waiting steps,
region emergency numbers. Drafted by engineering from public guidance with sources, every item `review: null`.

**App** (no new tab): Home section "Dành cho bé hôm nay" (H01 free / H02 with group A, check-in entry "Hôm nay
con có gì khác?"), check-in C01 → C02 → NL05b → save → PS01 / PS01F / HL01, AC01 / AC02, PS02 on the next open;
Nhịp lớn lên from the Chăm sóc tile "Wonder Weeks" (NL01, NL01b, NL02a–c, NL03, NL04, NL07, NL07b), MS01; EN01 /
EN02 preferences; the owner's country question on first open (D-072 #3). Everything behind the `rhythm` flag
(per family, from `getCapabilities.features`).

### Phase 0 — prepare (no app code)

| Step | Scope | Size |
|---|---|---|
| **P0.1** | ✅ Extract `568:18` into `figma-extract/30-personalization-premium.md` (v2.0 frames first, VI+EN text, annotations, the mapping table) | M |
| **P0.2** | ✅ Add §21 to `figma-coverage-checklist.md` (rows per v2.0 frame) and the D/P/Q/G ids to `business-map.md` (by hand, no prettier) | S |
| **P0.3** | Owner answers the open Q-ids before their step (§11) | — |
| **P0.4** | ✅ `fixtures.json` copied once to `packages/contracts/test/vectors/premium-v2.json` (synthetic); Dart tests read the same file, as `care_calc_test.dart` reads `care-day.json` | S |

### Slice 1 — capabilities, template gating, fixture harness (brief "Slice 1")

| Step | Scope | Figma | Size |
|---|---|---|---|
| **E1** | `entitlements.ts`, `family-actions.ts`; port **E01–E15** (role adapter editor→coParent, viewer→relative) | — | M |
| **E2** | `families/{f}.country/timeZone`, `config/entitlements`, new flags (`personalization`, `rhythm_advanced`, `ai_assist`, `billing`); `requireCapability`; `getCapabilities` (superset of `getFeatureAccess`); Rules denies; rules tests M03, M04; API test M01, M02 | ST02 | M |
| **E3** | Beta campaigns + promo grants in portal with audit; beta-end notice job (policy from owner); M09 | PR03 beta | M |
| **E4** | Flutter `capabilitiesProvider`, `GateReason` → UI mapping (paywall only for `PREMIUM_REQUIRED`), household profile country/time zone | ST02 | M |
| **Q1** | `premium.access: 'subscribers'` in catalog + portal; `createMemorySession` / `requestMemoryStory` check `templates.premium`; E03 (beta does not open B) end-to-end | MO01, MO02 | S |

Exit: free user calling an advanced endpoint gets `PREMIUM_REQUIRED` while logging, calendar, health keep working;
beta family gets A but not B; fixtures E pass in vitest.

### Slice 2 — Home, rhythm facts, saved result, feedback (no AI)

| Step | Scope | Figma | Size |
|---|---|---|---|
| **R0** | Basic free age-content pack (one card per week of age, VI/EN, `ageDays` range, review block) on the publish workflow (pattern of first aid); Home section "Tuần này của {bé}" + detail "Tuần {n} · điều con có thể làm" (Q-067). Synthetic labelled cards on dev until reviewed | 2a–2c, B05–B06 | L |
| **R1** | `rhythm.ts`, `personalization.ts`; port **B01–B06, C01–C06, R01–R06, X01–X03** to vitest; Dart ports of calendar + observations (client offline) with the same C/X fixtures | — | M |
| **R2** | Due date (NL02b, estimated label), check-ins + Rules, `days.complete`, episodes, preferences (EN01/EN02), `facts/state.dataVersion` bump triggers | NL02a–c, EN01, EN02 | L |
| **R3** | Portal PN01–PN04: reference model versions, activities, rules & health routing, kill switches; dev seed adapter writing **synthetic, labelled "Nội dung minh hoạ · chờ chuyên môn duyệt"** content, `test_` prefix, dev/emulator only | PN01–PN04 | L |
| **R4** | Server facts builder, `composeHome`, `nextAction`, cooldowns, reason codes, health routing; integration tests M13, M14, M18 | — | L |
| **R5** | Flutter: Home H01/H02 as new `TodaySection.forYou` (merge path of `TodayLayout.fromJson`), check-in C01/C02 + health questions NL05b → HL01, PS01/PS01F, AC01/AC02, PS02, NL01/NL01b/NL03/NL04/NL07/NL07b, MS01 (link milestone by id, no photo copy) | H01–PS02, NL*, MS01, HL01 | L |

Exit: save concern → one relevant action → try → feedback → next open shows the changed reason (M18), health flow
free in every plan state, sparse data honest (ST01).

### Slice 3 — grounded AI with consent and fallback

| Step | Scope | Figma | Size |
|---|---|---|---|
| **A1** | AI consent per user (versioned, retention explained), consent off cancels queued work and clears cache | NL10 privacy | M |
| **A2** | `generateSummary` pipeline, AI quota ledger (1/baby/day, 10/family/month from config; cache hit free), transactional budget charge, `aiGate`; port **A01–A08**; fake provider integration M15 | — | L |
| **A3** | Flutter SU01 / NL10 / NL10b / ST01 AI states; readable fact links instead of `[F1]`; "Chưa đúng? Báo lại" (reuses G-074 path) | SU01, NL10, ST01 | M |
| **A4** | Bilingual human eval set (synthetic notes incl. injected instructions), audit sheet; result is a release gate, not a unit test | — | M |

### Slice 4 — real billing, render ledger, international, QA

| Step | Scope | Figma | Size |
|---|---|---|---|
| **B1** | `billing.ts` normalisers + fake provider; `startPurchase`, `verifyPurchase`, `restorePurchase`, event ledger, reconciler; M05–M08 against the fake | — | L |
| **B2** | Apple: App Store Server Library, Notifications V2 endpoint (sandbox URL on dev, prod URL on prod) | — | M |
| **B3** | Google: Play Developer API, RTDN Pub/Sub, acknowledge | — | M |
| **B4** | Flutter `in_app_purchase`: PR01 (entry A/B emphasis, same SKU, storefront price), PR02 pending/success/error/restore, PR03 household plan, PR04 expiry, MO03 resume exact template + media (M17) | PR01–PR04, MO03 | L |
| **Q2** | Quota ledger for video: reserve/commit/release with fencing in `keepsake-jobs.ts` + renderer; MO04 states; M10 (20 concurrent), M11, M12 | MO04 | L |
| **I1** | EN/VI parity of all new strings, date formats via `intl` (no ambiguous dd/mm in EN), units, region content routing, no default hotline; M16 | all | M |
| **O1** | Analytics events (brief p.20), test report generator (case id, policy version, commit, env, platform, locale, clock), rollout/rollback runbook, indexes on dev | — | M |

Rough calendar for one engineer with Claude: Slice 1 ≈ 2 weeks, Slice 2 ≈ 6–7 weeks (R0 included), Slice 3 ≈
2 weeks, Slice 4 ≈ 4 weeks + store review. Slices can be coded in parallel but merge in order; the paywall is not
released before A works end to end (brief p.17).

---

## 8. Test traceability

| Fixture / case | Test home | Kind |
|---|---|---|
| E01–E15 | `packages/contracts/test/entitlements.fixtures.test.ts` | pure |
| B01–B06, C01–C06, X01–X03 | `packages/contracts/test/rhythm.fixtures.test.ts`; Dart `test/features/rhythm/rhythm_fixtures_test.dart` (C, X) | pure |
| R01–R06 | `packages/contracts/test/personalization.fixtures.test.ts` | pure |
| A01–A08 | `packages/contracts/test/ai-gate.fixtures.test.ts` + `firebase/tests/ai-summary.integration.test.ts` (fake provider) | pure + emulator |
| Q01–Q04 | `packages/contracts/test/quota.fixtures.test.ts` + `firebase/tests/quota.integration.test.ts` | pure + emulator |
| M01, M02, M09 | `firebase/tests/entitlements.integration.test.ts` | emulator |
| M03, M04 | `firebase/tests/premium.rules.test.ts` + API tests | rules + emulator |
| M05–M08 | `firebase/tests/billing.integration.test.ts` (fake) → store sandbox on devices | emulator → **BLOCKED** until sandbox accounts exist |
| M10–M12 | `firebase/tests/quota.integration.test.ts` (emulator, best effort) → `scripts/src/qa-quota-race.ts` on dev (`test_` family, 20 parallel callables) | emulator → dev |
| M13, M14, M18 | `firebase/tests/rhythm.integration.test.ts` + Flutter integration flow | emulator + device |
| M15 | AI integration (fake) + A4 human audit | emulator + human |
| M16 | contracts window tests + device locale/zone run | pure + device |
| M17 | Flutter widget test + store sandbox | widget + device |

Report every row with case id, commit SHA, `policyVersion`, platform/locale/env, expected, actual, evidence and
PASS / FAIL / **BLOCKED** (missing credentials or content). `verify_reference.py` output is reported separately as
"reference simulation", never as app validation.

---

## 9. Risks and trade-offs

- **Content is the critical path**, not code: approved activities, age content, health routing per region and the
  reference model need medical reviewers (D-058 pattern). Without them, A cannot open in a region (brief p.13).
- **Store setup lead time**: App Store Connect / Play Console products, sandbox testers, server API keys,
  notification URLs per environment; dev bundle ids must exist in the stores or the prod bundle is tested in
  sandbox against dev (Q).
- **Switching ★ templates from free beta to paid** removes something beta families use today (D-068 #3). Needs the
  notice period and a clear message; existing exports remain.
- **Emulator ≠ production transactions**: concurrency and index evidence must come from dev (D-072 #4). Test data
  on dev must stay `test_`-prefixed and be cleaned by script, since dev also holds real QA families.
- **AI semantics**: id/schema checks do not prove the sentences are right; a human audit EN/VI is a release gate.
- **Scope**: Slice 2 is the largest and depends on content (R0/R3). Keep the paid launch behind it.

---

## 10. As built

### 10.1 Phase 0 + Slice 1 (2026-10-15, dev)

Commits `4aef871` (plan, D-072), `2b492bb` (E1/E2/Q1 server), `ea63d91` (E3 server), `53f6499` (extract 30),
`03ce1a5` (checklist §21), `a54bd8e` (E3 portal), `10d3ccd` (E4 / Q1 app). Deployed to `child-life-dev`:
rules, `getCapabilities`, `setFamilySettings`, `staffPremium`, `staffSetPremiumConfig`, `staffFamilyPremium`,
`staffGrantPromo`, `staffRevokeGrant`, updated `createMemorySession` / `requestMemoryStory`, portal. All
callables answer JSON 401 unauthenticated (invoker check). Flags `rhythm`, `personalization`, `ai_assist`,
`premium_billing` are off and `config/entitlements` is unset (no region open), so nothing changes for families yet;
the Kỷ niệm catalog stays on `everyone` until Q-072.

- **Contracts**: `entitlements.ts` (capabilities, reasons, grants, `resolveCapability`, `householdPlan`,
  `config/entitlements` with Beta A campaigns that can never include templates, staff request schemas),
  `family-actions.ts` (`familyCan`, D-072 #1–#2), `keepsakes.ts` (`subscribers`, `keepsakeTemplateAccess`),
  four flags, staff actions `premium.view / config / grant`, audit category `premium`.
- **Functions**: `entitlements.ts` (context with stored grants + open campaigns per country, test vs production
  grants by project), `premium-staff.ts`; Cao cấp in `subscribers` mode refused with `PREMIUM_REQUIRED`.
- **Rules**: `families/{f}/grants|quota|quotaOps` closed to clients.
- **Portal**: Premium & Cá nhân hoá screen (regions, quotas, campaigns by family code, family lookup, promo
  grant / revoke with reason).
- **App**: `lib/features/premium/` (capabilities, gate sheets per reason, PR03 Gói của hộ with the owner's
  region picker, MO02 for Cao cấp in `subscribers` mode), Tôi row only when a rollout reaches the family.

**Tests (actual runs, 2026-10-15)**

| Layer | Result |
|---|---|
| Fixture pack E01–E15 through the real resolver (`packages/contracts/test/entitlements.test.ts`) | 15/15 pass; contracts suite 109 pass |
| Emulator integration M01, M02, M05, M08, M09, E03/E11 end to end, staff E3 (`entitlements`, `premium-staff`, `memories`, `keepsake-jobs`) | pass |
| Rules M03, M04 (`entitlements.rules.test.ts`) | pass |
| Portal vitest | 100/100 |
| Flutter `premium_test.dart` + `premium_golden_test.dart` (PR03, MO02; Light / Night × vi / en) | pass |
| Full `firebase/tests` suite | 6–8 failures in account / links / stories / reminders that also fail on a clean HEAD worktree (pre-existing, order-dependent) |
| Full Flutter suite | only pre-existing golden failures (family 14a/14f/9x, first aid fa7b/fa7h), unchanged without this work |
| `verify_reference.py` | not used as evidence; reference simulation only |

**Not done / BLOCKED**

- No end-to-end run on a real iPhone / Android against dev yet (checklist rows stay ☐).
- Beta-end notice job: waits for Q-071 (beta dates, notice policy).
- MO02 "Mở với Premium" opens PR03; purchase arrives with B1–B4 (Slice 4).
- Country picker offers 12 countries; other countries need a list decision (G).

## 11. Open questions for the owner and design gaps

Answered: D-072 and Q-067 (2026-10-14). Still open, in the order the steps need them:

| Q | Question | Needed by |
|---|---|---|
| **Q-068** | Where a parent confirms a day was logged completely ("ghi đủ") — not drawn | R2 |
| **Q-069** | Medical reviewer(s); beta regions besides VN | R3, release of A |
| **Q-070** | AI provider stays OpenAI (D-003)? Consent and retention text (Q-020) | A1 |
| **Q-071** | SKUs, price, intro offer, quotas, beta duration and end notice | E3, B4 |
| **Q-072** | When ★ templates become subscribers-only, and the notice to beta families | Q1 switch-on (code ships with `everyone`) |
| **Q-073** | Buyer leaves or hands ownership over: grant stays with the family until expiry? | B1 |

Slice 1 is not blocked: Q1 ships the `subscribers` mode with the catalog still on `everyone`.

**Design gaps to log (G-108…)** — the extract's "Open questions" lists 20 cross-cutting design inconsistencies (mock dates, quota numbers, badge colours, VI/EN drift, entry-A return after purchase); fix them in Figma or log as G-ids before the matching step.


- "Ghi đủ" day confirmation UI (Q-068); household profile screen (country, time zone) and the first-open country
  question (D-072 #3); PR02 variants exist only as a component sheet; portal Premium screen not drawn; EN09
  data-coverage labels and inconsistent fixture dates (brief asks to fix); check-in prompt settings (EN07) vs
  D-068 #9 nudges; "Nhờ chủ hộ nâng cấp" state for non-owner co-parents (D-072 #1, PR01/PR03 show only the buyer).
