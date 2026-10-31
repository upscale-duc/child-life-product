# 09 · Phased implementation plan

Each slice is shippable on dev on its own, touches only Product Hub files plus the listed shared
lines (staff function, route, messages, rules comment, indexes), and ends with tests and a
design-review render of new portal screens (Light/Dark × vi/en via
`apps/portal/test/design-review`). Prod deploy of any slice needs owner approval.

## Phase 1 — Product knowledge foundation

**Progress (2026-10-31):** PH1.0–PH1.6 and PH1.9 built and tested (contracts 9, ingest 20,
emulator 10, portal 17 tests); PH1.7 run against an emulator with the real repository (254 sources,
504 decisions, 49 features, 2 plan conflicts) — the first real sync on dev waits for deploy and commit;
PH1.8 uploads not started. The registry is JSON (`registry/features.json`), not YAML.

**Success criterion:** the Product Owner can browse and understand the verified product
structure without asking developers.

| Slice | Scope | Main files | Tests | Depends on |
|---|---|---|---|---|
| **PH1.0 Contracts & access** | `product-hub.ts` schemas, enums, `productCoverage()`, `parseBusinessMap()`; `product` staff function + role defaults; route `product` + empty Overview shell; `messages-product-hub.ts` | `packages/contracts/src/product-hub.ts`, `staff.ts` (+1 function), `apps/portal/src/context.ts`, `Shell.tsx`, `messages-product-hub.ts` | contracts unit (coverage scoring table-driven; business-map parser on the real file → ≥ 540 ids, 0 unparsed or listed); staff level tests; portal routing test | Q-PH-01, Q-PH-02 |
| **PH1.1 Registry seed** | `docs/product-hub/registry/features.json` with the 49 features of [02](02-feature-inventory.md): ids, names vi/en, pillar, globs, hubKey, figma nodes | JSON + schema in contracts | schema test; "every glob matches ≥ 1 file at HEAD"; "every hubKey is a `FeatureKey`"; "every `FeatureKey` has a registry row" | PH1.0 |
| **PH1.2 Sync tool (dry run)** | `product-hub-sync.ts`: discover, hash, parse, chunk, facts, decisions, links, conflicts (tier claims, dead refs), change detection vs a previous manifest; prints the change set | `firebase/functions/scripts/product-hub-sync.ts`, `src/product-hub-ingest.ts` (pure) | fixtures: added/changed/moved/deleted, idempotent re-run, table chunking, id extraction, secret refusal, size limit, tier-conflict fixture (Scenario C) | PH1.1 |
| **PH1.3 Submit, review, apply** | callables `productHubSyncSubmit`, `productHubChangeSets`, `productHubReviewChangeSet`, `productHubSources`, `productHubSource`; Sources tab (library + review queue + diff) | `src/product-hub.ts`, `index.ts` exports, `apps/portal/src/screens/product/Sources.tsx` | functions integration on emulator: unauthorized/insufficient level refused; own change set cannot be approved by self; approve applies + versions; reject keeps old; approved section becomes stale, not overwritten (Scenario D); rules tests (deny) | PH1.2 |
| **PH1.4 Catalog & feature page** | callables `productHubFeatures`, `productHubFeature`, `productHubSaveSection`, `productHubApproveSection`; Catalog table + filters in URL; feature page tabs; coverage panel | `screens/product/Catalog.tsx`, `Feature.tsx`, `CoveragePanel.tsx` | portal: filters, empty states, coverage gaps shown (Scenario F); functions: section versioning, approve not-own | PH1.3 |
| **PH1.5 Plans & entitlements** | callable `productHubPlans` (contracts defaults + live `config/features`, `config/entitlements`, decision links, conflicts); Plans tab, read-only, link to `/features` | `screens/product/Plans.tsx` | correct three-layer badge for fixtures; no write path (test that the callable module imports no writer) | PH1.4 |
| **PH1.6 Overview** | callable `productHubOverview` (counts from approved registry only; "—" when unreviewed); tiles link to filtered catalog | `screens/product/Overview.tsx` | counts match fixtures; no analytics placeholders | PH1.4 |
| **PH1.7 First content pass** | Run the sync on dev; owner/eng review the first change set; draft narrative for **3 pilot features** — `care.feeding` (Scenario A), `remember.auto_save`, `platform.lumi` — from existing docs, each claim sourced | data only | Scenario A walkthrough recorded in the PO guide | PH1.3–1.6 |
| **PH1.8 Uploads** (1b) | upload start/process callables, text extraction (md, txt, docx, pdf text layer), archive/replace/delete | `src/product-hub-upload.ts`, Sources upload UI | type/size refusal; extraction fixtures; delete needs `full` | PH1.3 |
| **PH1.9 Docs** | Developer guide (sync usage, adding a feature to the seed), Product Owner guide (vi) | `docs/product-hub/guide-developer.md`, `guide-product-owner.md` | — | all |

## Phase 2 — AI Product Copilot

**Progress (2026-10-31):** PH2.0–PH2.3 built on Claude (D-157): search artifact rebuilt at each
approval, `productCopilotAsk` with server-side grounding, conversations, "Lưu thành…" drafts,
Copilot tab and feature sheet, knowledge search in Sources. Fake suite: retrieval recall@8 = 1.0
on 24 questions; emulator suite 8 cases. PH2.4 live eval: a small run after deploy.

**Success criterion:** the Product Owner asks how a feature works and gets an evidence-grounded
answer.

| Slice | Scope |
|---|---|
| PH2.0 Search | `productHubBuildIndex`, `productHubSearch`; search box in Sources and Catalog; retrieval eval (fake suite, recall@8 ≥ 0.8 on 40 questions) |
| PH2.1 Copilot core | `product-copilot.ts` prompt + answer schema + citation validation; `productCopilotAsk`; limits in `config/limits` |
| PH2.2 Copilot UI | global page, feature side sheet, suggested questions, citations preview, freshness and missing-evidence display, conversation history |
| PH2.3 Save as draft | `productHubCreateDraft` from an answer; drafts list in Decisions (minimal) |
| PH2.4 Live eval | live suite on changed cases; owner OK for a full run |

## Phase 3 — Product management

**Progress (2026-10-31):** built — journeys registry (`registry/journeys.json`, 10 journeys from
the UX journey audit, synced and source-checked), Hành trình tab, Quyết định tab (D/R/P/Q/G with
the supersession chain and open questions by feature), opportunities with a two-person accept,
Copilot drafts promoted to opportunities, conflict actions (confirm / dismiss / resolve / accept the
difference / reopen, with a note or a decision id), "Tìm mâu thuẫn" on Claude (suggestions only,
two real sources each), section history with a line diff.

User Journeys (seeded from `docs/product-audit/07-ux-journey-audit.md` and plan-site flows A–F,
each step linked to features); Decisions tab (D/R/P/Q/G mirror with filters, supersession chain,
"open questions by feature"); Opportunities (draft → triaged → accepted/declined, evidence
links); conflict resolution workflow; AI-suggested conflicts (suggested only); section diff and
version review.

**Success criterion:** the Product Owner identifies and manages improvement opportunities.

## Phase 4 — Product intelligence

Feature ↔ metric links to `docs/product-analytics/02-metric-dictionary.md` ids; Insights tab
reading `staffProductAnalytics` aggregates (no family-level data); instrumentation status per
metric ("defined / instrumented / has data"); freshness monitor (stale approvals, dead refs per
revision); CI dry-run + submit; Copilot may receive aggregate metrics with their date range.

**Success criterion:** the Product Owner evaluates performance and makes evidence-based
decisions — only once the app has real users.

## Acceptance scenarios → where they are proven

| Scenario | Proven in |
|---|---|
| A Feature understanding (Feeding) | PH1.4 + PH1.7 walkthrough |
| B Photos permission revoked | PH2.1 eval case (answer cites or says needs verification) |
| C Conflicting Lumi entitlement | PH1.2 tier-conflict fixture + PH1.5 Plans conflict row + PH2 eval |
| D Markdown changes | PH1.3 integration test |
| E Sleep improvement ideas | PH2.3 (draft, not decision) |
| F Coverage gap | PH1.4 portal test + contracts coverage table |

## Effort (rough, engineering days)

PH1.0 1 · PH1.1 1.5 · PH1.2 3 · PH1.3 3 · PH1.4 3 · PH1.5 1.5 · PH1.6 1 · PH1.7 1–2 (+ owner
review time) · PH1.8 2 · PH1.9 1 → **Phase 1 ≈ 18–19 days**. Phase 2 ≈ 8–10. Phase 3 ≈ 10.
Phase 4 depends on launch.

## Recommended order to start

PH1.0 → PH1.1 → PH1.2 can begin as soon as Q-PH-01/02 are answered (or with the proposed
defaults). PH1.1 (registry JSON) and PH1.2 (sync tool) touch different files and can run in
parallel once PH1.0's contracts exist.
