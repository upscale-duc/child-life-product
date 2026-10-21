# Product Analytics V1 — implementation roadmap & approval handoff

**Analytics Foundation + Portal đã implement và kiểm thử local theo yêu cầu tiếp theo của chủ sản phẩm.** Xem [08 — Implementation evidence](08-foundation-implementation.md) để phân biệt phần đã nối nguồn thật với upstream funnels, ENG coordinator, device/privacy/load gates còn mở. Các ticket dưới đây vẫn là acceptance scope đầy đủ, chưa được đóng toàn bộ. Không deploy hoặc thay đổi production. Full ENG-00–06 vẫn cùng V1, **Production Launch with Measurement**, không pilot riêng.

## Scope đã thống nhất

Sáu sections: Overview, Acquisition & Retention, Memories, Smart Engagement, Feature Adoption và **Operational Cost**. Theo chủ sản phẩm, **bỏ IAP/subscription billing khỏi scope hiện tại, đưa backlog**: revenue/MRR/trial/churn/paid conversion/Free-Plus-Pro mapping & filter không launch dependency. Cost Lumi/render/storage/credits tiếp tục, actual unknown nếu chưa có nguồn; không fake zero.

Reuse và dependencies: [audit](01-existing-system-audit.md), [metrics](02-metric-dictionary.md), [events](03-event-tracking-plan.md), [UX](04-portal-dashboard-ux.md), [engagement](05-engagement-measurement.md), [architecture](06-data-architecture.md). Existing [ENG-T01/T02](../product-audit/14-notification-implementation-plan.md#engineering-ready-tickets) không duplicate task: PA-T01–T04 bên dưới thực hiện measurement foundation tương ứng. ENG engine implementation chờ measurement spec/contracts/fixtures gates; producers và final live UI nối tiếp theo dependency, không giả spec completion là engine đã được phép release.

## Approval register bổ sung

[PA-01–PA-08](01-existing-system-audit.md#productanalytics-assumptions-cần-phê-duyệt) chỉ áp dụng phần current scope; PA-01 IAP deferred không chặn. Đề xuất **PA-09**: measurement Care occurrence W=min(due + 24h, next recurrence, existing expiry), onboarding step semantics/creator-vs-viewer paths, cost permissions và aggregate query constraints phải chốt cùng metric/event review. W không sửa Care schedule. Retention PA-05 amendment từ [architecture](06-data-architecture.md#proposed-data-shapes--private-vs-aggregate): facts400d, transient non-ENG receipts120d, ENG joins30d after terminal, aggregates25months; privacy review trước schema/code.

## Delivery sequence

| Stage                                            | Output                                                                                                    | Gate                                                                                                                                        |
| ------------------------------------------------ | --------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| S0 — specification review (lượt này)             | Seven docs, evidence-based gap inventory, formulas/event/UX/architecture/fixtures plan                    | Owner approve spec current scope; resolve PA assumptions needing product/privacy/engineering review. Không code/deploy                      |
| S1 — contracts & Portal foundation               | PA-T01–T04: schema/privacy/query/data contracts, UI primitives/fixture-driven six-section skeleton        | Event/Portal specs + known-count reconciliation pass trước ENG notification engine. Synthetic UI clearly isolated, chưa gọi finished system |
| S2 — real producers & aggregations               | PA-T05–T09: activity/cohorts, domain outcomes, ENG/family/Lumi/cost sources                               | Real app/domain observations→dedup/private facts→aggregates; missing sources marked unknown; no IAP dependency                              |
| S3 — connected Portal & validation               | PA-T10–T12: all six sections live API, filters/export/quality, automated/device/privacy/performance tests | Real-event dev/staging proof from Flutter iOS/Android through Portal, rollback/kill switches, release gates all ENG IDs                     |
| S4 — approved Production Launch with Measurement | App+complete V1 engagement/analytics, actual observational baseline                                       | Explicit implementation/release approval before deployment/config; no limited-user pilot prerequisite; small N descriptive                  |

## Small, independently testable tasks

Mỗi task phải test được bằng scoped fixtures, nêu evidence và rollback. Test paths là existing entry points khi có; new test files đặt cùng convention khi implement. Không claim tests dưới đây đã chạy. Không broad UI/backend rewrite hoặc introducing infrastructure vì dashboard cần chart.

### PA-T01 — Freeze dictionary/contracts and event ownership

- **Entry points:** `packages/contracts/src/account.ts`, `staff.ts`, `config.ts`; `firebase/functions/src/analytics.ts`, `product-outcomes.ts`; ENG-T01 contract work.
- **Change/data:** versioned event/query/response/cohort schemas, source-of-truth owner registry, metric definition/version, unknown/maturity/currency/basis enums; legacy compatibility. Free/Plus/Pro/commerce fields not implemented.
- **Analytics:** full event→metric mappings trong03; no double producer aliases; actor/source private vs aggregate boundary enforced.
- **Acceptance/tests:** unit reject raw child fields/IDs/free dimensions, sample-rate and window formulas/zero denominator, compile server/client schemas, contract compatibility; review PA assumptions/ENG naming parity. No device delivery test claimed by contracts.
- **Dependencies:** spec approval, PA-02/03/04/05/07/08/09 decisions for affected fields; PA-01 excluded.
- **Rollback:** additive versioned readers, old schema remains; reject unsupported writer versions without affecting app domain actions.

### PA-T02 — Privacy, RBAC, deletion & query lattice

- **Entry points:** `firebase/firestore.rules`, `firebase/functions/src/account.ts`, `staff.ts`, staff action contracts, existing Rules/staff integration suites.
- **Change/data:** server-only observation/cohort paths, retention/deletion job hooks, permitted aggregate dimensions/complement suppression, cost read permission composition, export/query audit; no new production IAM action here.
- **Analytics:** fixed rejection/privacy/correction counts, no PII logs.
- **Acceptance/tests:** emulator forged refs/roles/server-only event denied, expired membership/staff revoke, cross-family access, baby/account deletion removes private joins, small-cell UI/API/CSV consistency and subtraction guardrails. Validate role cost restriction distinct overview view.
- **Dependencies:** T01, privacy approval PA-05; ENG existing local UID safety gates preserved.
- **Rollback:** deny new read/intake/export flags, keep safe existing stats; suspend new facts collection rather than relax Rules.

### PA-T03 — Incremental aggregates, snapshots & freshness

- **Entry points:** `firebase/functions/src/analytics.ts`, `index.ts` rollup scheduler, `product-outcomes.ts`, Firestore indexes.
- **Change/data:** bounded shards/checkpoints, private contribution registry, exact union reducers, staged build/publish, source-start/watermark/late-repair metadata; legacy stats fields unchanged.
- **Analytics:** intake/replay/late/unknown/dirty-partition/reconcile coverage metrics.
- **Acceptance/tests:** duplicate/parallel trigger exactly one stage/unit, crash-before/after checkpoint replay, staged generation publish no mixed data,72h late corrections and version invalidation, missing-day ≠0, historical no-evidence unavailable. Load tests scoped to one partition before broad runs.
- **Dependencies:** T01/T02; standalone synthetic source fixtures sufficient at this step.
- **Rollback:** stop new aggregate writer/repair flags, point Portal to last valid v2 snapshot or explicitly legacy metrics; no destructive backfill.

### PA-T04 — Portal six-section shell, reusable metric states & contract fixtures

- **Entry points:** `apps/portal/src/screens/Analytics.tsx`, `context.ts`, `api.ts`, `ui.tsx`, `messages.ts`, `index.css`, `components/ui`.
- **Change/data:** existing Analytics navigation/subroutes, reusable definition/coverage/funnel/heatmap/custom-date controls; fixture-based API adapter only in tests/dev harness. No separate website/design framework, no plan picker.
- **Analytics:** consumes approved metric contracts, no new user events because staff views dashboards.
- **Acceptance/tests:** VI/EN message parity, desktop/tablet light/dark keyboard/a11y states; unit zero/unknown/immature/suppressed/comparison metadata; navigation backwards compatibility; contract fixtures match API schema. Test build watermark visible, fixtures never production fallback.
- **Dependencies:** T01/T02 response contracts, T03 reducer fixture output. **Together complete ENG-T01/T02 measurement foundation gate before notification engine code.**
- **Rollback:** hide new sections behind existing config/approved analytics UI flag, existing Portal shell/screens keep working.

### PA-T05 — Registration, foreground, activation and retention sources

- **Entry points:** `apps/mobile/lib/features/auth/auth_repository.dart`, `features/memories/push_registration.dart`, `features/baby/baby_repository.dart`; `firebase/functions/src/family.ts`, `analytics.ts`, authenticated callable pattern.
- **Change/data:** canonical registration/foreground/context/step receipts; U/F day facts, frozen age/locale/Chapter primary context, strict retention/cohort reducers. Existing day heartbeat reused, no duplicate activity hook.
- **Analytics:** A01–A14 events and schema-version coverage; role-safe creator/viewer activation.
- **Acceptance/tests:** multi-device U once/day, user with two families not automatically active in unopened family, invite-created user doc not false completed registration; denied Photos/notifications not onboarding fail; offline/reinstall/guest-link and timezone boundaries. Physical iOS/Android registration→foreground→domain completion→Portal test later in T12.
- **Dependencies:** T01–T04, restricted DOB→band privacy approval, real context/actor source provenance.
- **Rollback:** disable new observations/aggregation bridge, preserve original auth/push registration and legacy family stats; no account/membership mutation for analytics.

### PA-T06 — Memories/Backfill and authoritative outcome attribution

- **Entry points:** Auto Save controller/store/review, `upload_queue.dart`, `memory_repository.dart`, keepsake/video screens; server `index.ts` outcome triggers, `keepsake-jobs.ts`, `stories.ts`, `links.ts`, `product-outcomes.ts`.
- **Change/data:** source→review→approval→ready batch receipts; Story/card/video/template/render/filed distinction; historical import/backfill context, actor and share-result provenance. Reuse existing render/jobs, no auto upload/render/share.
- **Analytics:** M01–M15, canonical ENG photo/video/backfill events; no duplicate outcome increments.
- **Acceptance/tests:** eight-photo partial scenario, all-skip resolved not ready, queue failure not pending review, text Story no render, render completed not filed, share sheet/link not confirmed; old photos don't backdate activity. Join-age 1/3/6/9/12m and completed keepsake dedup across coParents; iOS scan vs Android manual import tested.
- **Dependencies:** T01–T05; ENG source/journey implementation coordinated with ENG-T05/T06/T08 rather than duplicate tickets.
- **Rollback:** stop new attribution/producers, preserve user decisions/queue/jobs/media/quota; stage/source receipts retained within approved policy.

### PA-T07 — ENG-00–06 lifecycle/cohort analytics

- **Entry points:** existing ENG-T03–T11, notification/local adapters, `personalization-v2.ts`, `reminder-rules.ts`, notification links/navigation.
- **Change/data:** consume one source-eligible/decision/intent/attempt/reservation/outcome pipeline, stage aggregation and policy/fatigue/preference coverage; no second engine/scheduler. All ENG kinds in V1.
- **Analytics:** E01–E06 and kind-specificW, operational safety reasons, direct vs explicitly attributed conversion.
- **Acceptance/tests:** no denominator selection by push opt-in, accepted/scheduled not delivered, unknown local firing remains unknown, replay/token/locale no new opportunity; caps/quiet/snooze/cancel/expiry/priority, Care exempt proactive cap; retrospective no outdated push. Tests contract/emulator before device gate T12.
- **Dependencies:** T01–T04 measurement gates **before engine**, relevant T05/T06 source contracts, ENG privacy/render/delete gates. No pilot/holdout needed.
- **Rollback:** new engine/dispatch/category kill switch, cancel namespace safely, preserve Care/transactional adapters and user schedules. Analytics flag cannot erase opt-out/dismiss history.

### PA-T08 — Feature/Family/Lumi qualified adoption

- **Entry points:** server `family.ts`, `social.ts`, `albums.ts`, `personalization-v2.ts`, `assistant-staff.ts`; mobile source visibility/personalization/Family destinations.
- **Change/data:** authorized views/replies, distinct caregiver/module contribution sets, grounded source feedback, frozen Chapter context; existing counters bridge, no content snapshots.
- **Analytics:** F01–F07, meaningfulvs exposure, role/capability denominators.
- **Acceptance/tests:** relative membership presence not collaboration; two actors same family dedup; self-event excluded; revoked/expired content no qualified view; helpful optional response denominator distinct shown. Grow action not double-counted Care; Chapter unknown no inferred launch scope; sparse Lumi unavailable not fake use.
- **Dependencies:** T01–T06 and ENG source integration where applicable; LUM-02 safety/quality gate remains.
- **Rollback:** disable new adoption/view receipts, keep existing domain interactions/assistant answers/personalization; no behavior change to collect missing events.

### PA-T09 — Operational cost, credits and source reconciliation

- **Entry points:** `ai-telemetry.ts`, `assistant-model.ts`, `ai.ts`, `assistant-staff.ts`, `assistant-usage.ts`, `premium-ops.ts`, `apps/renderer/src/job.ts`, storage usage sources, existing `Assistant.tsx`.
- **Change/data:** reuse observed tokens and rates/credits, add explicit source coverage and cost-period manifests; render compute/storage metering if available, approved external statements ingestion only as separately authorized subtask. **No IAP or subscription integration.**
- **Analytics:** C01–C08, legacy VND vs observed USD estimate vs invoice actual; same workload counted once.
- **Acceptance/tests:** unknown usage/rate not 0 cost; cached tokens/failed paid calls/retries preserve coverage; credits not currency; output duration not compute duration; quota not billable storage. Fixture statements reconcile checksum/period/currency; missing external source visibly unavailable and not blocker for observed-usage dashboard.
- **Dependencies:** T01–T04 cost permissions/definitions, existingLUM-01, approved metering source for actual cost. No account/export/IAM production setup without approval.
- **Rollback:** stop new import/estimate writer, retain existing token/credit usage; show last valid watermark/source unavailable rather than fallback fabricated cost.

### PA-T10 — Connect all sections, filters/drill-down/export

- **Entry points:** `staffAnalytics`/`staffExportAnalytics`, `analytics.ts`, Portal Analytics/API/format/messages and six section components.
- **Change/data:** replace test adapter with live aggregates in real dev build, v2 query normalization/custom snapshots/supported-filter status, exact union/reconciliation, audit-safe CSV; no raw entity drilldown.
- **Analytics:** consume actual event pipeline and quality metadata; suggested checks based on observed data, no AI growth claims.
- **Acceptance/tests:** same query→same snapshot counts across KPI/chart/table/export; dates/timezone/version/N/D/unknown included; unsupported filters clear; previous outside evidenceunavailable. Unit/API/UI integration verifies deniedcost/export paths, no synthetic production fallback, CSV injection escaping.
- **Dependencies:** T03–T09; each section can connect independently as sources land, release requires all current-scope sections working/gracefully unavailable by source.
- **Rollback:** per section UI/API flag + versionedreader fallback with labels, no resetting ingestion/domain data.

### PA-T11 — Automated correctness/privacy/performance pack

- **Entry points:** `packages/contracts/test/`, `firebase/tests/analytics.integration.test.ts`, existing outcome/AI/Rules/staff tests, `apps/portal/test/v1.test.tsx`, `assistant.test.tsx`, mobile unit/widget suites.
- **Change/data:** isolated labeled synthetic datasets and replay/load harness; reconciliation golden aggregates, query budget/staleness monitors, permission/privacy assertions.
- **Analytics:** validate event coverage/maturity/unknown/correction status, no growth target.
- **Acceptance/tests:** fixture matrix below; full relevant tests/typechecks/lint plus small scoped performance workload → approved growing-data run. Detect document size/shard contention/scan runtime, no new service by assumption. Profile custom/previous 90 days exact union, not average/sum.
- **Dependencies:** T01–T10; only broaden test runs when changes/failures/unresolved concerns justify.
- **Rollback:** test fixtures stay isolated and never publish to production namespace; disable expensive new query/materialization when budget violated.

### PA-T12 — Real app end-to-end evidence & release approval

- **Entry points:** real Flutter dev builds iOS/Android, dev Firebase functions/Rules, existing Portal dev build; ENG-T12 runbook and privacy/deletion paths.
- **Change/data:** evidence pack revision app/backend/config/schema/fixture/deviceOS, actual source/action→receipt→aggregate→API→UI/export, rollback/kill switches. **No deploy or production config activation until explicitly approved.**
- **Analytics:** reconcile all four funnels + activity/retention/Family/Lumi/operational cost available-source paths. Source unavailable is honest status, not chart populated with test data.
- **Acceptance/tests:** physical iOS/Android new user plus late join 1/3/6/9/12m, manual import/cloud only/native capability as applicable, offline/restart/permissions/multi device/multi caregiver/timezone, logout A→B/revoke/delete, VI/EN light/dark/tablet Portal. All ENG-00–06 acceptance, privacy/automated gates/kill switch drill complete.
- **Dependencies:** T01–T11, app/P0 render/deletion/ownership releasegates, specification→implementation→release approvals recorded. No IAP completion or separate pilot required.
- **Rollback:** approved runbook stops affected new producers/dispatch/materialization/UI, cancels pending notices with source validation intact, preserves memories/jobs/preferences/Care/transactional/terminal receipts. Post rollback verify counts/rights; cannot recall already accepted push.

## Synthetic fixture & validation matrix

All numerical examples here are **TEST DATA ONLY**, not production baseline or significance evidence. Fixture manifest stores expected counts separately from published seed/prod environment; no server production “demo” fallback.

| Case                                      | Known expectation / verification                                                                                                         |
| ----------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| Two devices, one user, one family         | One activeU, one active F/day; iOS andAndroid each may count1 but All=1, never2                                                          |
| Two caregivers, two babies in same family | One family union, two users; same family occasion completed once; collaboration only if actions/views prove two actors                   |
| Discovery8, approve3, ready 2             | P discovered 8, approved 3, ready 2; ready/approved2/3 and ready/discovered2/8 labeled; no claim3 saved                                  |
| All skip and failed queue                 | Review resolved separate from ready 0; approved upload error not reclassify unreviewed                                                   |
| Render completed not filed / Story draft  | Neither qualified filed/saved; ready filing retry counts logical job once; text Story no render                                          |
| Duplicate/replay/out of order             | Same receipt/stageonce, attempts distinct if real calls; late event repairs watermark/correction version                                 |
| Offline / timezone / DST                  | No activity backdated to capture date; R boundaries vs source S due stay correct; strict D1 vs elapsed 7d not confused                   |
| D30 immature                              | Cohort without full 30d + settle displays immature, not 0 retention; legacy windowed never called strict D30                             |
| Late join / backfill                      | Join 1/3/6/9/12m context correct, past milestone in-app only, actual completion date current, completed keepsake suppress                |
| Small cohort / overlapping filters        | Threshold boundaries/complementary cells/API/CSV nulls; no hidden N in tooltip; unsupported filter rejected                              |
| Legacy clients / missing actor            | Known ready can count domain outcome, unknown discovery/open remains unknown; owner not assigned as actor                                |
| Cost unknown/multicurrency                | Usage tokens known but rate missing→unrated; absent invoice not 0; credits not cash; no mixed currency total without approved conversion |
| Staff/member revoke / deletion            | Unauthorized response contains no data; caches invalidated, private facts/joins removed, unsafe aggregate corrected/suppressed           |
| Empty and growth load                     | No demo series; zero denominator null; bounded reads/latency at approved synthetic scale and recorded revisions, no unmeasured SLO claim |

## Definition of done — working system

Sau spec approval, implementation chỉ hoàn tất khi real application actions trên dev iOS/Android có validated/dedup receipts và server-authoritative completion, aggregate có eligible denominator/window/coverage, Portal sáu sections đọc API thật với permissions/filters/CSV và correctstates, tests/reconciliation/privacy/performance review đạt. Fixture-only UI không đủ. Production activation chỉ sau release approval; new product N nhỏ vẫn descriptive, không fabricated retention lift hoặc statistical significance.

## Backlog — IAP/billing sau này

Theo yêu cầu chủ sản phẩm, **không nằm current scope hoặc release dependency**:

- Hoàn tất in-app purchases và verified store lifecycle thực tế trước finance analytics; restore/retry/refund/test-environment safety theo workstream riêng.
- Versioned Free/Plus/Pro commercial mapping và plan filter, entitlement source vspaid status tách riêng; không tự đổi Premium SKU/capabilities để phục vụ chart.
- Trial→paid, Free→paid, subscription revenue/MRR/churn/refunds, verified transaction amounts/currencies/periods và financial source reconciliation.
- Revenue versus variable cost, FX/recognition conventions và finance permissions/exports khi có authorized reliable sources.

Khi backlog được kích hoạt, revisit dictionary/event/API/privacy/contracts trong version mới; không hồi dựng paid conversion hoặc doanhthu từ `purchaseStarted`, grants, quota credits hoặc display prices. Operationalcost source liên quan cloud/provider spending là separate ops data, không buộc implement IAP.
