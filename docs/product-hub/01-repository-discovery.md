# 01 · Repository discovery report

Snapshot: 2026-10-31, branch `s2-onboarding` at `e60e569b` plus a busy working tree (other
sessions' uncommitted changes in mobile, l10n and goldens). Everything below was read from the
repository; nothing was run against dev or prod Firebase. "Verified" here means **read in code**,
not "tested on a device" — see the evidence levels in [02](02-feature-inventory.md#evidence-levels).

## 1. Headline findings

1. **Child Life is much further along than the brief assumes.** 38 Flutter feature modules
   (~215 k lines of Dart under `apps/mobile/lib/features`), ~320 exported Cloud Functions, a
   staff portal with 24 routes, and 244 Markdown files under `docs/`. The Product Hub problem is
   not "no knowledge" but "knowledge in seven places with different authority".
2. **A product-knowledge spine already exists — in prose.** `docs/product/business-map.md`
   (1 042 lines) holds 152 owner decisions (D-xxx), 130 design rules (R-xxx), 95 engineering
   proposals (P-xxx), 100 questions (Q-xxx) and 75 design gaps (G-xxx), each with an id, date
   and evidence. This is the strongest source of *approved intent* and must become first-class
   records in the Hub, not one more document to chunk.
3. **Runtime entitlements are already structured and centralized.** `packages/contracts` defines
   13 capabilities (`entitlements.ts`), a 9-feature catalogue with tiers Free / Premium / Beta
   (`features-hub.ts`, D-089), the flags (`config.ts`) and one server rule (`decideFeature`) used
   by `getCapabilities`, `featureAccess` and gated callables. The portal's **Tính năng & Premium**
   hub (`apps/portal/src/screens/FeatureHub.tsx`, route `/features`) already edits tiers, rollout
   and per-family overrides. Product Hub must **read** this, never fork it.
4. **The portal already has the infrastructure Product Hub needs:** staff identity and a
   per-function level matrix (`packages/contracts/src/staff.ts`), a `staffCall` wrapper with
   server-side checks (`firebase/functions/src/index.ts:2200`), an append-only `staffAudit` log,
   a draft → review → publish workflow with a two-person rule (D-058), bilingual `react-intl`
   catalogs split per area (`messages-*.ts`), shadcn/Radix components, and a fixture-based
   design-review harness (`apps/portal/test/design-review`).
5. **A trusted repo → Firestore publishing path already exists:**
   `firebase/functions/scripts/content-release.ts` runs locally with ADC, writes **drafts only**
   through the same staff callables as the portal, is dry-run by default, records the `--as` staff
   member in the audit log and refuses prod without `CHILD_LIFE_PROD_APPROVED=yes`. The Markdown
   sync should be a sibling of this tool, not new infrastructure.
6. **AI runs through one server-side provider adapter (D-003):** OpenAI (`OPENAI_API_KEY` secret,
   `OPENAI_MODEL` default `gpt-4.1-mini`, D-146), wrapped by `observedAiFetch` telemetry
   (`ai-telemetry.ts`) with a template fallback when no key is set. The Copilot can reuse the
   adapter, the secret and the telemetry; it needs its own prompt and its own budget.
7. **Product analytics exists but is narrow.** `product_analytics` flag (MET-01), callable
   `staffProductAnalytics`, reducer/store (`product-analytics*.ts`), portal `/analytics`, metric
   dictionary and event plan in `docs/product-analytics/`. Product Insights should link features
   to these metrics rather than build a second analytics stack.
8. **Nothing is released yet.** The app is pre-launch (D-147: "ứng dụng chưa golive"); the
   purchase flow is not live; there is no store analytics baseline. Every feature's *release
   availability* is therefore "not released" today, whatever its implementation status. The Hub
   must not show "Released & Verified" for anything until a release exists.
9. **Two earlier inventories exist and are already stale in places:**
   `docs/product-audit/01-current-product-inventory.md` (2026-10-20, Vietnamese, evidence-linked,
   ~23 capabilities) and `docs/product/figma-coverage-checklist.md` (V1 Figma scope, ~500 rows,
   strict "done" definition). Both are inputs, neither is the catalog.

## 2. Architecture as found

| Layer | What exists | Product Hub relevance |
|---|---|---|
| Mobile | Flutter, Riverpod + GoRouter, flavors `dev`/`prod`, ARB l10n (vi template, en), goldens Light/Night × vi/en, iOS widget/Live Activity/share/watch extensions, Android Glance widgets | Source of *implemented behaviour*; module ↔ feature mapping |
| Backend | Functions v2 (`firebase/functions/src`, 125 TypeScript files), Admin SDK, zod validation via `@child-life/contracts`, Cloud Tasks, Cloud Run renderer (`apps/renderer`) | Callables to reference per feature; new `productHub*` callables follow `staffCall` |
| Data | Firestore deny-by-default Rules (`firebase/firestore.rules`), `config/*` → `publicConfig/*` mirror, family data under `babies/{b}` / `families/{f}`, staff-only collections denied to clients by the catch-all | Product Hub collections are staff-only, server-written, never under family paths |
| Portal | React 19 + Vite + Tailwind 4 + shadcn, `react-intl`, Firebase Auth email/password + email link, `staff` claim + `staffMe` levels, 24 routes in `context.ts`, tabs as sub-paths | New route `product` with tab sub-paths, reusing `Page`, `Section`, `FilterBar`, `StatTiles`, `TableScroll`, `Sheet` |
| Contracts | `packages/contracts/src/*.ts` (~70 files), zod schemas + shared logic, built before dependents | Home for `product-hub.ts` schemas and the deterministic coverage score |
| AI | Provider adapter (`ai.ts`), assistant worker, telemetry, credit accounting (`assistant-usage.ts`) | Reuse adapter + telemetry; Copilot budget separate from family credits |
| Analytics | `statsDaily`, `appEventsDaily`, `familyActivity`, `contentStatsDaily`, product-analytics store | Feature → metric links; "unavailable" when the metric has no data |
| Content ops | `content/` seeds, `contentDrafts` + publish callables, `content-release.ts` | Pattern for knowledge sync (draft-only, audited, dry-run) |
| Docs | `docs/` 244 `.md`; plus `.claude/skills` (52), `CLAUDE.md`, `AGENTS.md`, app READMEs | Knowledge Sources corpus; see [03](03-documentation-inventory.md) |
| Design | Figma `sJLG1fAXKDnDr9YI6Yx8ex` (history, read-only), saved extraction `docs/discovery/figma-extract/` (42 files + images) | Design references by node id; never live Figma calls from the Hub |

## 3. Authentication and authorization (as found)

- Portal sign-in: Firebase Auth; access requires the `staff` custom claim or a pending staff
  invitation (`staffAcceptInvite`), then `staffMe` resolves roles → levels on every call (P-134).
- Levels per portal *function*: `none · viewMasked · view · edit · approve · full`. Built-in
  roles: owner, admin, ops, support, eng, analyst, expert, qa; custom roles `r_…`.
  Owner/Admin/QA are locked. `staffCan(levels, action)` is the single check.
- Staff never see photos, videos, captions or care records (staff.ts header, R-180…R-190); they
  see masked emails, anonymous family codes, counts and bytes.
- Every staff mutation writes `staffAudit` (reason optional since D-090).

Product Hub needs a **new staff function** (`product`) so access can be granted independently
of `features` (which can change live tiers). That is a permission-model change → owner decision
(see [10](10-risks-and-open-questions.md), Q-PH-01).

## 4. What can be reused (and what must not be duplicated)

| Reuse | From | How |
|---|---|---|
| Feature tiers, capabilities, flags, overrides | `features-hub.ts`, `entitlements.ts`, `config.ts`, `premium-v2.ts` | Read at sync time and at request time; display only |
| Live entitlement state | `staffFeatureHub` callable | Plans & Entitlements links to `/features` for any change |
| Decisions D/R/P/Q/G | `business-map.md` | Parsed into `productDecisions` records by id; the Markdown stays the source |
| Staff auth, levels, audit | `staff.ts`, `staffCall`, `staffAudit` | Same wrapper, new function `product` |
| Draft-only trusted publish | `content-release.ts` | New `scripts/product-hub-sync.ts` beside it, same flags and safeguards |
| AI provider + telemetry | `ai.ts`, `ai-telemetry.ts`, `OPENAI_API_KEY` | New Copilot prompt module; same adapter |
| Product metrics | `product-analytics.ts`, `docs/product-analytics/02-metric-dictionary.md` | Feature ↔ metric ids |
| Portal UI kit | `ui.tsx`, `content-kit.tsx`, `components/ui/*` | No new design system; existing tokens (`packages/design-tokens`) |
| Design-review harness | `apps/portal/test/design-review` | Fixtures for Product Hub screens, Light/Dark × vi/en |

**Must not duplicate:** a second tier/entitlement store; a second decision log; a second
analytics pipeline; Figma API calls from the portal; any read of family data.

## 5. What is missing today

- No machine-readable **feature registry** spanning all ~45 features (the hub catalogue covers 9
  tierable features only).
- No link table between features and docs, decisions, code, tests, Figma nodes or metrics.
- No search across `docs/` from the portal; Markdown is invisible to non-engineers.
- No mechanism that tells the Product Owner a document is stale relative to code.
- No conflict surfacing: e.g. `docs/product/plans-credits-analysis.md` proposes **Free / Plus /
  Pro** usage tiers (status "proposal") while the implemented and approved model is **Free /
  Premium / Beta** (D-075, D-089, `featureTiers`). Today a reader has to know which wins.
- No grounded Q&A over product knowledge (Lumi is family-facing and must stay separate).

## 6. Constraints that shape the design

- **Shared working tree with parallel sessions** (memory: parallel-sessions-same-branch): Product
  Hub work must touch only its own files; no whole-tree formatting; no commits of others' files.
- **Prod is gated**: deploys only via `scripts/deploy.sh dev`; prod needs owner approval.
- **Firestore rules are deny-by-default**; new collections stay denied to clients and are reached
  only through callables (like `contentDrafts`).
- **Bilingual portal** (D-012): every string in `messages-*.ts` with identical vi/en ids.
- **Privacy**: no child data in logs, analytics or AI prompts; the Copilot corpus is product
  documentation and code metadata only.
