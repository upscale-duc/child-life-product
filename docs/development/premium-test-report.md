# Premium & Cá nhân hoá — test report (2026-10-15)

| | |
|---|---|
| Policy | fixture pack v2.0, `qa-policy-v2` (synthetic only, `not_production_seed`) |
| Commit | `e9e8272` (branch `s2-onboarding`); server deployed to dev at `0a33f29` |
| Clock | fixture clock 2026-10-14 (Asia/Ho_Chi_Minh); tests use fixed instants |
| Environments | contracts vitest (Node 22); Firestore + Storage emulators on an isolated config; Flutter tests on macOS (iOS / Android not run); dev Firebase `child-life-dev` for deploy checks |
| Locales | vi and en (goldens per screen in both; Light and Night care) |
| Plan | `docs/product/premium-personalization-plan.md`; decisions D-072, D-073, D-074; proposals P-151–P-154 |

**PASS** = ran and matched. **BLOCKED** = needs something not available (credentials, devices, reviewers).
**POSTPONED** = the owner moved it to a later slice (D-074). `verify_reference.py` output is reference
simulation only and is not used as evidence here.

## 1. Fixture cases through the real code (48 / 48)

| Cases | Expected | Actual / evidence | Status |
|---|---|---|---|
| E01–E15 entitlement | as in `fixtures.json` | `resolveCapability` + `familyCan` (editor → Cùng nuôi, viewer → Người thân with "Chăm sóc hằng ngày"): `packages/contracts/test/entitlements.test.ts` | PASS |
| B01–B06 baseline | as in pack | `sleepBaseline` (TS) `test/rhythm.test.ts`; Dart port `apps/mobile/test/features/rhythm_baseline_test.dart` | PASS (TS + Dart) |
| C01–C06 calendar | as in pack (offsets 21/30 are test values, never published) | `calendarState` (TS) + Dart port `rhythm_calc_test.dart` | PASS (TS + Dart) |
| R01–R06 ranking | as in pack | `rankCandidates`: `test/rhythm.test.ts` | PASS |
| X01–X03 observations | as in pack | `observationState` (TS) + Dart port | PASS (TS + Dart) |
| A01–A08 AI gate | as in pack | `aiGate`: `test/ai-quota-billing.test.ts`; end to end with a fake provider: `firebase/tests/ai-summary.integration.test.ts` | PASS |
| Q01–Q04 quota | as in pack | `applyQuotaOp`; through Firestore transactions: `firebase/tests/quota.integration.test.ts` | PASS (sequential; see M10) |

## 2. Integration matrix M01–M18

| ID | Expected | Actual / evidence | Status |
|---|---|---|---|
| M01 | Free user on an advanced endpoint → PREMIUM_REQUIRED; logging, content, calendar, health work | `entitlements.integration.test.ts` "M01"; `rhythm.integration.test.ts` free → `free_content` + age card | PASS (emulator) |
| M02 | Viewer with a paid household → ROLE_DENIED for edit / AI / render; reads continue | `entitlements.integration.test.ts` "M02"; AI caregiver / relative cases in `ai-summary.integration.test.ts` | PASS (emulator) |
| M03 | Household A cannot reach household B's facts, assets, jobs | `entitlements.rules.test.ts`, `rhythm.rules.test.ts`, `ai-summary.rules.test.ts`, API cases in `ai-summary.integration.test.ts` | PASS (emulator) |
| M04 | Client writes premium=true, grants, quota → denied; server ignores them | `entitlements.rules.test.ts`, `billing.rules.test.ts`, `ai-summary.rules.test.ts` | PASS (emulator) |
| M05 | Auto-renew off → access until expiry | `entitlements.integration.test.ts` "M05"; `billing.integration.test.ts` (fake adapter) | PASS (emulator, fake store) |
| M06 | Pending / unverified / duplicate restore → no grant, no new binding | `billing.integration.test.ts` (pending, already_bound, not_owner) | PASS (fake store); real store POSTPONED |
| M07 | Renew / expire / grace / revoke, duplicate and old events → reconcile to current status | `billing.integration.test.ts` M07 ×4 (events fed to the reconcile function) | PASS (fake store); store notifications POSTPONED |
| M08 | Sandbox purchase never grants production | `entitlements.integration.test.ts` "M08"; `billing.integration.test.ts` | PASS (emulator) |
| M09 | Beta ends → history readable, new A gated, no charge | `entitlements.integration.test.ts` "M09"; app PR04 strips (`premium_purchase_test.dart`) | PASS (emulator + widget) |
| M10 | 20 concurrent requests, 1 slot → ≤ 1 accepted | `video-quota.integration.test.ts`, `quota.integration.test.ts`: exactly 1 of 20 on the emulator | PASS (emulator only); dev run BLOCKED (needs `test_` families seeded on dev) |
| M11 | Retry / success twice / failure twice → one job, one commit or release | `video-quota.integration.test.ts` M11 ×6; renderer fencing `apps/renderer/test/job.test.ts` | PASS (emulator) |
| M12 | Reserved before expiry completes after; new job after expiry gated | `video-quota.integration.test.ts` M12 | PASS (emulator) |
| M13 | Missing days, open timer, duplicates, partial day → no false zero-day | `dayQuality` tests (TS + Dart); `rhythm.integration.test.ts` M13 | PASS |
| M14 | Mother normal + father changed → both kept, mixed; edits invalidate summaries | `rhythm.integration.test.ts` M14; summaries stale in `ai-summary.integration.test.ts` | PASS (emulator) |
| M15 | AI consent off, timeout, unknown ids, instruction in a note → no unauthorised generation, fallback, health first | `ai-summary.integration.test.ts` (26 cases, fake provider) | PASS (fake provider); real OpenAI on dev BLOCKED (`OPENAI_API_KEY` secret unset → template) |
| M16 | EN/VI, travel / time-zone change → same facts, right language, no duplicate windows | quota window zone tests (`quota.integration.test.ts`), cache key per locale, goldens vi / en | PASS (emulator); device travel BLOCKED |
| M17 | Buy from a template → resume exact template and photos; no duplicate purchase | server resume (`billing.integration.test.ts`), app resume with a fake store (`premium_purchase_test.dart`) | PASS (fakes); real purchase POSTPONED |
| M18 | Concern → suggestion → try → feedback → next open changes | `rhythm.integration.test.ts` M18; `recommend` tests; app PS02 widget + goldens | PASS (emulator + widget) |

## 3. Suites (actual runs at the commit above)

| Suite | Result |
|---|---|
| `packages/contracts` vitest | 180 pass |
| `firebase/tests` (rules + integration, isolated emulator) | all Premium / Rhythm / AI / quota / billing files pass; 7 failures in account ×3, links ×2, stories ×1, reminder-rules ×1, which fail the same way on a clean checkout of the pre-Premium HEAD |
| `apps/portal` vitest | 126 pass |
| `apps/renderer` vitest | 22 pass |
| Flutter `test/features` + `test/app` | 818 pass (incl. EN09 weekly summary) |
| Flutter goldens | Premium, Rhythm, AI goldens pass (Light / Night × vi / en); only pre-existing family 14a / 14f / 9x and first-aid fa7b / fa7h goldens fail |
| `flutter analyze`, `pnpm lint`, typechecks | clean |

## 4. Not verified (required before production — `docs/operations/premium-rollout.md` §4)

| Check | Status | Why |
|---|---|---|
| End to end on iPhone and Android against dev, Light / Night | BLOCKED | Not run on devices yet; checklist §21 rows stay ◐ |
| Store sandbox lifecycle (purchase, renew, cancel, grace, refund, restore) | POSTPONED | D-074: real Apple / Google payment later |
| Real OpenAI output on dev + bilingual human audit of meaning, reassurance, causality | BLOCKED | Secret not set on dev; audit needs reviewers |
| Medical / content review per region | BLOCKED | Q-069 reviewer; `content/rhythm/SEED-NOTES.md` §6 |
| Firestore indexes and race behaviour on dev | partly | Indexes deployed with this commit; concurrency only on the emulator |
| Wonder Weeks name / model rights | BLOCKED | D-072 #7 legal check |
