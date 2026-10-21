# Firebase analytics architecture & data governance

**Target architecture; foundation implemented locally, chưa deploy.** Xem [08 — Implementation evidence](08-foundation-implementation.md) về bounded asynchronous materialization, actual storage/retention và gates còn mở; các shape bên dưới là target options, không phải tất cả đã được tạo. Reuse Firebase/Firestore, existing authorization, UI/API và outcome/AI ledgers. Không thêm SDK/BigQuery hoặc rewrite notifications/jobs/billing. IAP/billing analytics **backlog**.

## Luồng dữ liệu và ownership

```text
Existing app domain actions / authorized foreground & review observations
  → existing domain writers + versioned private observation intake
  → validate permission/source/generation → idempotent receipt/contribution
  → private user/family/cohort facts (bounded, deletion-aware)
  → incremental daily/cohort/funnel aggregate + reconciliation watermark
  → existing staff callable API (RBAC + approved filters + suppression)
  → existing Portal Analytics + permitted aggregate CSV

AI provider usage / render metering / approved cloud cost statements
  → existing AI/usage ledgers + versioned cost reconciliation
  → operational cost aggregates with estimate/actual/unknown coverage
```

General `recordAppEvent` không nhận arbitrary entity IDs hoặc raw payload để trở thành behavioral stream. Private cohort/source joins là server-authorized product operational data khác boundary với general analytics; PA-05 privacy review bắt buộc trước implementation. Không export hoặc expose private IDs trong Portal.

| Component owner        | Reuse                                                                               | Modification                                                                                                                                    |
| ---------------------- | ----------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| Contracts / validation | `packages/contracts/src/account.ts`, `staff.ts`, notification/config contracts      | Versioned events/query/results và fixed enums; legacy schema compatibility, server-only completion restriction                                  |
| Authoritative outcomes | `product-outcomes.ts`, `index.ts` domain transitions                                | Bridge same receipt một lần, thêm actor/context chỉ khi proven; no second completion counter independently                                      |
| Aggregate jobs         | `analytics.ts:rollupDay/backfillDays`, existing scheduler                           | V2 incremental facts/checkpoints/shards, late repairs, new metrics alongside legacy; không rescan toàn operational graph cho mỗi Portal request |
| Observation intake     | Existing authenticated callable pattern, local owner/privacy guards                 | Separate private observation callable, bounded local offline queue, dedup/source rights checks                                                  |
| Engagement             | Existing ENG-00 plan/adapters/intents                                               | Consume shared intent/eligibility/attribution receipts, không second scheduler/experiment service                                               |
| Cost                   | `ai-telemetry.ts`, `assistant-staff.ts`, quota/render/storage sources               | Reuse tokens/known/unknown/rate versions; approved metering/reconciliation only, no IAP implementation                                          |
| Portal                 | `staffAnalytics`, `staffExportAnalytics`, `staffCan`, `Loaded/useLoad`, messages/UI | Backward-compatible versioned section requests, aggregate responses with coverage/permissions                                                   |

## Proposed data shapes — private vs aggregate

Paths dưới đây là implementation options cần schema/Rules review, **chưa có trong repo**. Ưu tiên extend existing source facts/receipts khi đúng semantics; không tạo bản sao full documents hoặc duplicate event pipeline.

| Path/scope                                                                      | Data tối thiểu                                                                                                                                   | Privacy/retention/owner                                                                                                                                          |
| ------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Existing `appEventsDaily`, `statsDaily`, `productOutcomesDaily`, `aiUsageDaily` | Existing legacy fields giữ nguyên; add explicit metricVersion/coverage where needed                                                              | Aggregate readers không reinterpret historical definitions; existing schemas không overwrite                                                                     |
| Private `users/{u}/analyticsDays/{Rday}`                                        | Day observed, platform/locale bits, qualified foreground evidence, coarse entry cohort reference                                                 | Server-only read/write despite user parent scope; **không app-readable** analytics tracking store; delete user purge; bounded400d proposal                       |
| Private `families/{f}/outcomeDays/{Rday}` extension hoặc analytics day facts    | Qualified action/module flags, distinct actor-contribution refs, platform/window evidence, semantic version                                      | Reuse outcomeDays if safe; no raw Care/child content. Facts400d proposal; deletion and membership privacy enforced                                               |
| Private cohort/first facts                                                      | Canonical account/family registration/first-action receipt, frozen age-band/locale/Chapter/source eligibility                                    | No DOB copy; restricted date derive coarse bands, context stays private. Source identity needed only authorized reducer; bounded retention                       |
| Private observation receipts/contributions                                      | Opaque receipt key, authorized source generation, stage, actor link if proven, occurred/received time, expiry, aggregate contribution checkpoint | No PhotoKit IDs/face/pixels/text; non-ENG receipts≤120d proposed, ENG joins existing30d after terminal. Existing domain dedup receipts retain existing lifecycle |
| Existing ENG private intent/outbox/reservations                                 | Eligibility, decisions, attempts, completion association                                                                                         | Consume ENG source, retain caps/cancel/expiry; no separate shadow intent or push receipts                                                                        |
| Daily v2 aggregate namespace under stats pipeline                               | Metric definition/version, fixed bucket/shard, counters, histogram where approved, source watermarks, sealedThrough, correction version          | Extend `statsDaily` with v2 summaries and bounded aggregate subdocuments; not unbounded dimensions in one1MiB doc; retained≤25months proposal                    |
| Cohort/funnel materializations                                                  | Entry bucket/unit, stages N/D/unknown/immature, maturity date, stage order coverage, context                                                     | Counts only after reducer, no identity sets in API; approved cells and filters, same suppression for exports                                                     |
| Cost period manifest                                                            | Service/source/currency/period/rate version, observed/estimated/reconciled amount, coverage, checksum private                                    | No raw invoices/secrets/customer identifiers in Portal. Cloud project/family allocation refs private, aggregate cost metadata only                               |
| Query snapshot/cache                                                            | Normalized approved query/version/snapshot/watermarks and aggregate results                                                                      | No per-user rows; short TTL cache, invalidated on correction/delete; query audit access controlled                                                               |

**PA-05 retention details needing approval:** daily identity/cohort facts **400d**, short-lived non-ENG observation receipts≤120d, ENG joins30d after terminal, published aggregate≤25months. A 90d range + preceding90d + D30 maturity needs identity evidence beyond120d; 400d is proposed to support these windows with bounded retention. Retain minimum needed; user/family deletion earlier wins. No indefinite pseudonymous tracking. If privacy review permits shorter facts, unsupported windows/comparisons become unavailable rather than fake approximate counts.

## Exact distinct counts và segmentation

1. **Users:** derive canonical U from auth, registration once; device/app reinstall no new U. Daily foreground receipts dedup U/day/device observations into one U/day. Background scan/digest/notification not app foreground. Device-supplied U never trusted.
2. **Families:** derive F from authorized event-time selected family/source; baby siblings/coParents count once F/window. Legacy heartbeat marking all memberships remains separate A04, not source of v2 exact selected-context activity. Role/viewer dimensions from membership valid at observation.
3. **Window union:** DAU/WAU/MAU/custom active counts = exact union of private U/F contributions, **not sum daily counts, not avg WAU, not sum platform rows**. Precompute7/30/90 windows/checkpoints and approved dimensions. Custom cache/materialization does union server-side with bounded pages; until ready return `preparing`, no placeholder totals.
4. **Filters:** store per-day platform/locale evidence, not only platforms-ever. Same family active iOS and Android appears in each filtered cohort but once All. Chapter event-time vs cohort-entry labels distinct. Allowlisted aggregation lattice prevents unbounded cross-product; unsupported filter combo explicit unavailable/rejected.
5. **Age/late onboarding:** server derives coarse bands from restricted DOB and source timezone, no DOB stored in general analytics. Freeze primary context at onboarding; multi-baby contributions not duplicate user/family cohort. Historical import capture/target dates not registration/usage dates.

Custom ≤366 reporting days (PA-07) is an input cap, not a promise every metric has366d identity history. 400d facts support90d+previous90d/maturity; a366d previous-period comparison can exceed retained evidence. Return `unavailable_history` for uncovered distinct/cohort windows; additive aggregate trends may remain available under separate coverage labels. Do not calculate selected-period distinct by summing precomputed7/30d cardinalities. No identity sketches/error-bound approximation without a separately approved metric version.

## Idempotency, late events và repair

Transaction receipt/contribution lifecycle: validate source/rights → read logical receipt → if existing no-op stage count → write private fact/contribution and aggregate shard delta/checkpoint atomically where feasible. Multi-stage outcomes can bridge legacy/source event, but one source-of-truth receipt registry controls ownership. Provider call attempts legitimately cost multiple times; trigger retries of same attempt do not.

Use bounded aggregate shards to avoid all clients incrementing a single daily hot doc; nightly seal merges deterministic partitions. Contributions carry metricVersion/sourceGeneration to allow rebuild without duplicate append. Aggregate partition writes via staged generation + atomic published pointer/checkpoint, so interrupted rebuilds cannot show mixed generations. Existing legacy totals remain available/versioned during migration.

- occurredAt source-validated; receivedAt server timestamp always. Client heartbeat per local day not enough for R boundaries—derive R instant and track legacy coverage explicitly.
- Late/offline source within proposed72h: mark affected day/cohort/window dirty and recompute, then bump correction version/invalidate caches. Terminal state at occurrence time, not current mutable snapshot guessed retroactively.
- Later valid source after seal: controlled correction path using retained evidence, output revisedThrough/reason. Outside retention/dedup horizon: no blind replay; mark unattributed/unknown coverage, reject stale client replay, do not resurrect purged identity facts or recount closed terminal source. Provider invoice corrections use versioned service-period manifest, not synthetic app events.
- Missing app discovery/visible/open stages remain unknown even if backend ready proves completion; never fabricate intermediate “observed”. Mature denominators and incomplete numerator evidence reported separately.
- Legacy backfill only where timestamp/source provenance survives; do not run production data rebuild during spec phase. Implement dry-run/diff/checksum and approved bounded repair later. Current membership/storage/plan state cannot reconstruct historical facts truthfully.

## Retention/funnel computation

User registration cohort frozen R-day; strict D1/D7/D30 checks qualified foreground on that exact R-day, final only after target day ends+72h settle. Account elapsed7×24h activation differs calendar-day retention; keep both clocks explicit. Weekly family T0..Tk uses full closed ISO weeks, partial week immature. Legacy28–32 D30 stays labeled legacy, not rewritten by new cards.

Funnel unit→source association private, one stage/unit/window. Expose cohort-entry denominator, observed stage count, unknown stage coverage and immature units. Outcomes outside W not converted for that cohort, may still count as standalone completed actions. Group/cancel/snooze/opt-out do not remove already eligible units from denominator. Retrospective milestone has its own14d cohort and no overdue outbound intent.

## Query/result contract (proposed v2)

Extend existing staff callable rather than add public data endpoint. V1 `{tab,days,platform}` reads remain compatible until callers migrate. New request:

```text
schemaVersion: 2
section: overview | acquisition | memories | engagement | features | cost
from / to: date-only reporting range, validated closed days
filters: platform, appLocale, approvedChapter, optional sectionContext/ageBand
comparison: none | previous_equal_period
breakdown: approved dimension or none
metricVersion / optional existing experimentId: allowlisted server registry
```

No user/family/baby IDs, raw field names, arbitrary collection paths, plan filter, SQL or free-form groupBy. Proposed response:

```text
schemaVersion, definitionVersion, sourceStartAt, reportingZone, range,
snapshotId, computedAt, observedThrough, sealedThrough, revisedThrough,
appliedFilters, unsupportedFilters, status,
metrics[]: {metricId, unit, numerator, denominator, value|null,
            window, cohortVersion, maturity, unknownCount|null,
            coverage, sourceBasis, comparison|null, suppressionReason|null},
series/breakdowns: bounded aggregates with same metadata,
quality: rejected/late/unattributed/partial source summaries
```

`status`: ready/provisional/preparing/no_data/unavailable/insufficient/stale/error. Suppressed fields `null`, no hidden numerator/denominator in response/CSV. Money includes currency/basis/period/coverage; counts/rates never share ambiguous `value` without unit. Comparison not computed when version/source range/maturity differs. `snapshotId` identifies an aggregate build, not person/source entity.

## Permissions, privacy and deletion

- Reuse `analytics.view`, `analytics.export` staff action checks server-side and UI. Cost section proposal PA-08 additionally `premium.view`; export requires both read permissions plus export action. Legacy overview:view does not automatically grant model/invoice cost detail. API must check revoked staff permission each call/export; client-side hiding not authorization.
- Firestore deny direct app/client access to analytics private facts and new aggregate internals. Server SA least-privileged paths; Portal uses callable projections. No raw IDs/short family/job codes in responses, CSV or query URLs; ops screens remain separate privilege boundary.
- Small cells PA-05 suppress by unit-specific distinct eligible U/F threshold≥20 (proposal, not anonymization guarantee); no rates/N/D/tooltips/export leaks. Suppress complementary cells/totals if needed to prevent obvious subtraction. Fixed dimension/query lattice, request budget, cached published snapshots and staff query audit limit differencing; privacy review required for custom ranges/overlap. Access control still required even with threshold.
- Account/baby/family deletion immediately cancels source joins and removes eligible private facts/actor contributions. Revoke prevents future source observations and serving restricted content; do not describe current-source revocation as erasing historical operational action automatically. Membership-aware deletion coordinator tracks which contributions must be withdrawn vs historical nonidentifying aggregates can remain under approved policy.
- Recompute affected published aggregates or remove unsafe cells using retained contribution manifests; invalidate cache/CSV snapshots. If exact subtraction impossible after irreversible aggregate anonymization, retain only approved nonidentifying, suppressed aggregates per privacy decision and report correction coverage. Never preserve recoverable identity solely to enable indefinite analytics deletion replay.
- Financial provider records/accounting obligations, if needed, separate access/retention policy; no raw invoices in analytics. IAP receipt retention outside current workstream. Logs contain fixed reason/counts, no child data/tokens/prompts/source paths.

## Cost architecture and BigQuery decision

Observed AI usage stays in existing `aiUsageDaily` with known/unknown/rated coverage and rate-version USD micros. Older VND call-unit estimate not added to token-rate estimate. Commercial quota committed units remain separate. Render instrumentation must measure compute resources/attempts or ingest reconciled allocated bill; output.durationMs can describe artifact, not presumed runtime billing. Storage usage needs byte-hours/egress/requests/renditions and source watermark, closing quota bytes alone insufficient.

Provider/cloud cost import is optional future integration inside operational-cost ticket, **approval before touching billing accounts/exports/IAM/production**. Until connected, actual cost unavailable while observed tokens and rate estimates work. Total includes each workload once by explicit source priority reconciled actual→rated estimate→unknown; missing service coverage means known subtotal, not complete variable cost. Blended cost/F uses same period exact active F, not attribution to each household. Revenue-vs-cost deferred with IAP.

No BigQuery provisioning now. Measure Firestore bounded read/write/query cost, shard contention, document sizes, nightly runtime/repair backlog and interactive latency using synthetic load. If approved budget/SLO fails after bounded partition/materialization design, write ADR comparing BigQuery/export migration with cost, permissions, deletion/privacy and operational complexity. No speculative service spend or new duplicate warehouse pipeline.

## Freshness/completeness monitors

Per source: intake success/rejected schema, producer-version coverage, max occurred/received/processed timestamps, dirty partitions, last successful seal, late/unknown actor/attribution ratios, source reconciliation drift. Daily job idempotency and failure alert separate from product growth. PA-07 budgets proposed, not measured facts. Portal must expose stale/partial/unknown instead of filling gaps with0. Alert/runbook uses aggregate reasons; no child identifiers in general logs.
