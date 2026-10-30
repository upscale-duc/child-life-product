# 02 — Product & business audit

Basis: `docs/product/business-map.md` (D-, R-, P-, Q-, G- ids), slice reports S0–S15b, the implementation plan,
the 2026-10-20 product audit and 2026-10-26 flow-error audit, and code. Product understanding is in
[00](00-product-understanding.md). Requirements were not invented here. Where intent is missing, the
gap is named.

## 1. Value delivery

The core loop is **log care together → hand over → keep memories → share with family on your
terms**. It is built end to end on dev with unusual depth:

- server-enforced audiences;
- offline care with refusal messages;
- resumable, verified deletion;
- an export pipeline;
- per-family kill switches;
- bilingual copy at full parity (6,596 keys each).

The product principles (calm, no guilt, intentional sharing) show in the rules: no streaks, attribution
"Mẹ ghi", audience on every item.

The risk is **breadth before proof**. About 40 modules ship in one binary. Spending, print studio, nutrition,
solids, vaccines, first aid, library, the Lumi assistant, keepsake videos, Cùng Chăm Con, rhythm and
personalisation sit behind 37 flags. Yet no screen has passed the project's own end-to-end bar (checklist:
0/155 ☑), and no document says which of these the first users get.

## 2. Findings

### COM-01 · P1 · Premium cannot be bought; Premium v2 limits would trap Free users

|              |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| ------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Expected     | If Free limits exist, there is a way to lift them (D-101 Premium monthly / yearly, add-ons +20 / +50 GB).                                                                                                                                                                                                                                                                                                                                                                                                                          |
| Actual       | There is no store adapter. Every purchase answers `billing-not-configured` (`firebase/functions/src/billing.ts:27-34`, D-074 "IAP later"). The paywall says "Bước thanh toán sắp mở" ("the payment step is coming", `pv2PaySoonTitle`). Under `premium_v2`, Free storage is **1 GB per family** with no grandfathering, and Lumi gets **30 one-time credits** (`packages/contracts/src/premium-v2.ts:56`, D-101 Q-095/Q-096). SKUs and prices are open (Q-058, Q-071); so is subscription ownership when the buyer leaves (Q-073). |
| Impact       | If `premium_v2` is on at launch, a family fills 1 GB with a few videos and every upload path ends at a paywall that cannot take money. That is a dead end in the product's main emotional feature, and there is zero revenue. If it is off, the legacy 10 GB quota applies (R-040) and there is still no revenue.                                                                                                                                                                                                                  |
| Fix          | Decide the launch model explicitly. **(a)** Launch free with `premium_v2` off, hide all upgrade prompts, and state the storage limit honestly. **(b)** Ship StoreKit / Play Billing adapters and server notifications first. Close Q-058, Q-071 and Q-073 before (b).                                                                                                                                                                                                                                                              |
| Effort       | (a) S · (b) L                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| Verification | **Confirmed by code inspection**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |

### PRD-01 · P1 · Launch scope and success criteria are not defined

- No launch scope (modules and flags for the first public users), no launch metric targets, no beta plan
  for real families outside the team. Q-069 (medical reviewer for activities and health routing) is still
  partly open while health-adjacent content (first aid, vaccines, nutrition, Lumi care guidance) is built.
- **Impact:** the release decision cannot be checked against intent. Health-adjacent content without a
  named reviewer is a trust and liability risk. AI and health claims are L3 owner decisions under D-109.
- **Fix:** a one-page launch definition with an owner sign-off. It covers the module and flag matrix (pairs with OPS-02),
  target metrics (activation, D7, first ready memory), the reviewer for health content, and the beta cohort.
- Effort S · **Documentation gap**.

### PRD-02 · P1 · V1 scope is not verified end to end

- The checklist rule: a row is ticked only when it works on dev Firebase on iOS and Android, Light and Night
  care, with code and tests filled in. Status: screens 0 ☑ / 85 ◐; widgets 0 (S8 blocked on the Apple team);
  business flows A–F 0 ☑; engineering-supplied states (G-) 0 of 35 reviewed; admin portal 0 ☑
  (`docs/product/figma-coverage-checklist.md:15-23`). S16 "Verify & release readiness" has not started
  (`implementation-plan.md:393-395`).
- **Impact:** features look complete in code and goldens but are unproven on real devices and backends,
  which is the "features that appear functional but are not" risk.
- **Fix:** run S16 on the launch scope only (PRD-01), not on all of V1. Effort L · **Documentation gap**.

### PRD-03 · P2 · Promises on the landing site the app does not keep

- Q-008: the landing says caregivers can send photos to parents, but in the app caregivers never see Memories. Q-009:
  "Ông ngoại đã xem 12 ảnh mới" seen receipts do not exist in the app. Q-039: interval reminders, choosing who is
  reminded, and notification actions are promised without a decision. Still open in
  `business-map.md` §13.
- **Impact:** expectation mismatch at first use, which erodes trust. **Fix:** align the landing copy with the launch scope.
  Effort S · **Confirmed by documentation**.

### PRD-04 · P2 · English is an unreviewed engineering draft

- D-012 / CLAUDE.md: Vietnamese is the source and English is drafted by engineering for owner review. Many ARB
  descriptions still say "EN is an engineering draft for owner review" (e.g. `app_vi.arb:33044`).
- **Impact:** if English is offered at launch, tone and accuracy (health, money, privacy wording) are
  unreviewed. **Fix:** owner or native review of the launch-scope strings, or launch Vietnamese-only.
  Effort M · **Confirmed by inspection**.

### ANA-01 · P2 · The product cannot measure its launch yet

- The analytics foundation is built: closed event contracts, server-side cohorts, D1/D7/D30, a portal dashboard
  (`docs/product-analytics/08-foundation-implementation.md`). But the `product_analytics` flag is off and **PA-05
  privacy review is pending** (400-day retention needs review). There is no client analytics SDK (by design).
- **Impact:** with the flag off, activation, retention and funnel drop-offs are invisible after launch.
- **Fix:** finish PA-05, turn the flag on for the launch cohort, and build the minimal dashboard in §4.
  Effort S–M · **Confirmed by inspection**.

## 3. Journey completeness (business view)

| Journey                           | Complete?                       | Gap                                                                   |
| --------------------------------- | ------------------------------- | --------------------------------------------------------------------- |
| First run → first log             | Yes (dev)                       | Prod cannot start (REL-01)                                            |
| Invite family → family sees photo | Yes (dev)                       | Universal links need the Apple team; invite code brute force (SEC-01) |
| Daily care, handover              | Yes                             | SY-1 guard failing (QA-02)                                            |
| Storage full → more storage       | **Dead end** if `premium_v2` on | COM-01                                                                |
| Leave / delete                    | Yes                             | Strong                                                                |
| Get help                          | Yes (ticket + portal)           | Diagnostics consent pre-ticked (PRIV-01)                              |
| Widgets / lock screen / LA        | Partial                         | S8 blocked                                                            |

## 4. Minimal launch analytics dashboard (recommended)

All of these come from the existing contracts in `packages/contracts/src/product-analytics.ts`. Nothing new is invented.

1. **Activation funnel:** account → baby created → first care record → second member joined → first ready memory (7-day window).
2. **Retention:** D1 / D7 / D30 per signup week; weekly meaningful families.
3. **Collaboration:** share of families with ≥ 2 active writers; invites sent → accepted.
4. **Reliability:** refused care writes, upload failures by reason, deletion and export job failures, renderer failures, Crashlytics crash-free users.
5. **Cost:** AI tokens and credits per active family, Storage GB per family, renderer minutes.
6. **Premium (when billing exists):** paywall views → purchase start → verified grant.
