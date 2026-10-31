# 05 · Data architecture

## 1. Principles

1. **Two layers per feature, with provenance on every field.**
   - *Extracted facts* — code modules, callables, flags, capabilities, tests, decision ids, doc
     mentions — written only by the trusted sync from a pinned revision. Never hand-edited;
     re-running the sync replaces them.
   - *Curated narrative* — summary, user problem, value, UX flow, business rules, metrics,
     opportunities — written by staff (or drafted by AI) and **approved** before it counts.
   Every value carries `source: 'sync' | 'staff' | 'ai'`, `status: 'draft' | 'approved' |
   'rejected' | 'superseded'`, `revision`, `updatedBy`, `updatedAt`.
2. **No second entitlement store.** Tiers, capabilities, flags and limits are read from
   `@child-life/contracts` (defaults, at sync) and `config/*` (live, at request). Product Hub
   stores only *links* and *intended/approved policy text*.
3. **business-map.md stays the decision source** in Phases 1–2. `productDecisions` is a parsed,
   read-only mirror keyed by id. New decisions drafted in the Hub are exported for the owner to
   add to the business map (Q-PH-03 proposes when, if ever, the Hub becomes the source).
4. **Staff-only, server-written.** Every collection is denied to clients by the existing
   catch-all in `firebase/firestore.rules`; reads and writes go through `productHub*` callables
   wrapped by `staffCall`. No path under `babies/`, `families/` or `users/`.
5. **Bounded documents and queries.** No document over ~200 KB; lists are paginated; no
   unbounded collection-group scans from the portal.

Naming follows the repo (camelCase top-level collections: `contentDrafts`, `staffAudit`).

## 2. Collections

| Collection | Doc id | Written by | Key fields | Size / count |
|---|---|---|---|---|
| `productFeatures` | `care.feeding` | sync (facts) + callables (narrative status) | `name{vi,en}`, `pillar`, `chapters[]`, `ageMonths{min,max}`, `platforms[]`, `hubKey?`, `lifecycle`, `implementation`, `verification`, `release`, `owner`, `facts{modules[], callables[], collections[], flags[], capabilities[], tests[], figmaNodes[]}`, `coverage{score, missing[], computedAt}`, `revision`, `syncedAt` | ~50 docs, < 30 KB each |
| `productFeatures/{id}/sections` | `problem`, `value`, `ux`, `rules`, `access`, `metrics`, `issues` … | callables | `current{body{vi,en}, claims[]}`, `status`, `approvedBy/At`, `version` | ≤ 12 per feature |
| `productFeatures/{id}/sections/{s}/versions` | auto | callables | full previous body, author, reason, decision ref | append-only |
| `productLinks` | hash of (from, to, relation) | sync / staff / ai | `from{kind:'feature',id}`, `to{kind:'feature'|'source'|'decision'|'journey'|'metric'|'code'|'test'|'figma', id}`, `relation` (`depends_on`, `documents`, `decided_by`, `implements`, `tests`, `measures`, `designed_in`), `source`, `status`, `evidence` (chunk id / line) | ~5–10 k; queried by `from.id` or `to.id` (two indexes) |
| `productSources` | stable hash of repo path, or `up_<uuid>` | sync / upload callable | `kind` (`repo_md`, `upload_md`, `upload_pdf`, `upload_docx`, `upload_txt`, `decision_registry`, `figma_ref`, `code_summary`), `path`, `title`, `authority`, `approval`, `verification`, `contentHash`, `commit`, `storagePath?`, `status` (`active`, `moved`, `deleted`, `archived`, `processing`, `failed`), `features[]` (≤ 30, for filtering), `decisions[]` (≤ 50), `headings[]`, `docDate?`, `syncedAt` | ~250 |
| `productSources/{id}/versions` | `contentHash` | sync / upload | `commit`, `syncedAt`, `chunkIds[]`, `diffStat` | one per change |
| `productChunks` | `{sourceId}_{hash8}` | sync / processing | `sourceId`, `version`, `headingPath[]`, `anchor`, `text` (≤ 4 KB), `lang`, `ids[]` (D/R/P/Q/G mentioned), `features[]`, `terms` not stored (index lives in the search artifact) | ~5 k, < 6 KB each |
| `productDecisions` | `D-150` | sync (from business-map) | `kind` (`D`,`R`,`P`,`Q`,`G`), `title`, `text`, `date`, `status` (`approved`, `superseded`, `open`, `resolved`), `resolves[]`, `supersedes[]`, `features[]`, `source{path, line, commit}` | ~550 |
| `productDrafts` | auto | callables (staff, AI) | `type` (`opportunity`, `ux_improvement`, `rule_clarification`, `investigation`, `hypothesis`, `decision_proposal`, `section_update`), `feature?`, `body`, `evidence[]`, `fromConversation?`, `status`, `createdBy` | grows slowly |
| `productOpportunities` (Phase 3) | auto | callables | problem, evidence[], hypothesis, proposal, impact, effort, priority, status, successCriteria, decisions[] | — |
| `productJourneys` (Phase 3) | `first_memory` … | callables | goal, trigger, preconditions, steps[{text, feature}], alternatives, errors, completion, metrics[] | ~20 |
| `productConflicts` | hash | sync / staff | `topic`, `feature?`, `claims[{sourceId, chunkId, authority, text, date}]`, `status` (`open`, `resolved`, `accepted_difference`), `resolution?`, `decision?` | small |
| `productSyncRuns` | auto | sync | `by`, `revision`, `dryRun`, `config hash`, counts {added, changed, moved, deleted, unchanged}, `changeSet` | one per run |
| `productChangeSets` | auto | sync / upload | `runId`, `items[{sourceId, change, before, after, linkSuggestions[]}]` (items in a subcollection if > 200), `status` (`pending`, `approved`, `rejected`, `partially_approved`), `reviewedBy/At` | review queue |
| `productConversations` (Phase 2) | auto | callables | `owner uid`, `scope` (`global` or feature id), `title`, `lastAt`, `expiresAt` (TTL 180 d, Q-PH-06) | per staff member |
| `productConversations/{c}/messages` | auto | callables | `role`, `text`, `citations[{chunkId, sourceId, revision, authority}]`, `confidence`, `missingEvidence[]`, `model`, `promptVersion` | — |

**Storage:** `productHub/uploads/{sourceId}/{version}/{filename}` (originals, staff-only via
signed URLs from callables; Storage Rules deny all client access) and
`productHub/index/{revision}.json.gz` (compiled search index, see [06](06-knowledge-ingestion.md)).

**Audit:** every mutation appends `staffAudit` with actions `product.sync.apply`,
`product.changeset.review`, `product.section.approve`, `product.source.upload|archive|delete`,
`product.draft.create|approve`, `product.conflict.resolve`.

## 3. Status model per feature (four fields, never merged)

```
lifecycle:       planned | designed | in_development | built | deprecated
implementation:  not_found | partial | implemented
verification:    unverified | code_read | tests_pass | device_verified
release:         not_released | beta | released | withdrawn
```

`verification = device_verified` reuses the figma-coverage-checklist definition (dev Firebase,
iOS + Android, Light + Night, code + test paths). `tests_pass` needs a CI or sync-time test
result tied to a revision; the sync does **not** run tests itself in v1, it records results
supplied with `--test-report`.

## 4. Knowledge coverage score (deterministic)

Lives in `packages/contracts/src/product-hub.ts` so portal, functions and tests compute the same
number. Nine dimensions, each scored from its state, weighted, summed to 0–100:

| Dimension | Weight | Counts as present when |
|---|---:|---|
| User problem | 12 | `problem` section approved |
| Value proposition | 8 | `value` section approved |
| User flow | 14 | `ux` section approved with entry point, main flow and ≥ 1 error state |
| Business rules | 16 | `rules` approved and every rule has an id or a code/doc source |
| Edge cases | 10 | `rules.edgeCases` non-empty and sourced |
| Entitlements | 10 | feature has a tier (hubKey or capability) **and** no open entitlement conflict |
| Technical references | 10 | ≥ 1 module + ≥ 1 test fact from the latest sync |
| Success metrics | 10 | ≥ 1 metric linked; full points only if instrumented (`measures` link to a product-analytics metric id) |
| Product decisions | 10 | ≥ 1 `decided_by` link, or an explicit "no decision needed" approved by staff |

State factors: approved = 1.0, draft = 0.4, missing = 0. **Penalties** (shown separately, not
hidden in the score): stale (source changed since approval) −0.5 of that dimension; open
conflict on the feature caps the score at 69. Output: `{score, dimensions[], missing[],
unverified[], stale[], conflicts[], nextActions[]}` — next actions are fixed strings per missing
dimension, never AI-generated. Document count is not an input.

## 5. Indexes (to add to `firebase/firestore.indexes.json`)

| Collection | Fields |
|---|---|
| `productLinks` | `from.id` ASC, `relation` ASC · `to.id` ASC, `relation` ASC |
| `productSources` | `status` ASC, `syncedAt` DESC · `features` ARRAY, `syncedAt` DESC · `authority` ASC, `syncedAt` DESC |
| `productChunks` | `sourceId` ASC, `version` ASC |
| `productDecisions` | `kind` ASC, `date` DESC · `features` ARRAY, `date` DESC |
| `productChangeSets` | `status` ASC, `createdAt` DESC |
| `productConversations` | `owner` ASC, `lastAt` DESC |
| `productDrafts` | `status` ASC, `createdAt` DESC · `feature` ASC, `createdAt` DESC |

## 6. Security rules

No new `allow` rules. A comment block in `firestore.rules` names the `product*` collections as
staff-only through callables (like `contentDrafts`), and rules tests in `firebase/tests` assert
that a signed-in family member and a signed-in staff member are both denied direct reads and
writes. Storage: explicit deny on `productHub/**`.

## 7. Contracts

`packages/contracts/src/product-hub.ts` (new): zod schemas for every record and callable request
/ response, the enums above, `productCoverage()`, `featureIdSchema`, and a pure
`parseBusinessMap(markdown)` used by both the sync and its tests.
