# Smart Engagement V1 — implementation evidence

**21/10/2026 · code implemented locally, activation and release pending.** ENG-00–06 have connected source, decision, action and measurement paths. This report records local verification; it does not certify production delivery or close the full launch checklist. No deployment, production configuration, billing or IAP changes were made. The launch strategy remains **Production Launch with Measurement**, together with the app, without a separate limited-user pilot.

The owner authorized implementation. Product-policy assumptions A-01–A-11 in [the audit](12-smart-reminder-audit.md) still require approval before activation. All new flags default off; `config/engagement.approved` defaults false. Missing/malformed policy fails closed. Engine activation also requires the existing `product_analytics` flag.

## Implemented paths

| Scope  | Connected behavior and entry points                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| ENG-00 | `packages/contracts/src/engagement.ts`, `firebase/functions/src/engagement.ts`: strict contracts, seven deterministic decisions, private logical intents, atomic account-wide capacity reservation, per-family campaign marker, current authorization/source checks, consent, categories, quiet hours, snooze, fatigue and cancellation. `index.ts` exposes safe authenticated callables, a five-minute coordinator and daily cleanup. Existing notification delivery remains the adapter. |
| ENG-01 | `engagement_local.dart`, `engagement_repository.dart`, `engagement_background.dart`, Auto Save integration: UID-owned opaque review episodes survive restart. Server first observation establishes T0; push is due no earlier than T0+24h, expires after seven days and requires fresh local source proof. Approved batches must actually become ready before completion. No automatic approval/upload. A resolved review with no approved ready batch cancels the invitation.             |
| ENG-02 | `engagement-sources.ts`: m1, d100, m6 and y1 use actual DOB/timezone, historical ready photos, existing published catalog, scene requirements, existing access/feature rules and completed/in-progress keepsakes. One eligible opt-in coParent is selected for push using recent verified Memories activity, with stable UID ordering for ties. A card suppresses another invitation without claiming video completion. m6 has its own default-off flag.                                   |
| ENG-03 | Closed ISO-week recap uses **ready/saved time**, rather than photo capture time, excludes drafts/deleted/invisible sources and reuses Memories/Story viewers. The authorized week link returns actual source IDs. Opening the recap is separate from viewing its content.                                                                                                                                                                                                                  |
| ENG-04 | `engagement-observers.ts`, `reminder-rules.ts`: observes existing due Care occurrences and adapter outcomes before channel preferences remove recipients. Logged/skipped/snoozed/missed outcomes retain their meaning. Existing Care schedules, assignees, quiet-hour exceptions, local delivery and budgets remain owned by the Care system. Proactive fatigue does not disable configured Care.                                                                                          |
| ENG-05 | Existing Family inbox/domain references create a grouped optional recap: 30-minute group, 24-hour expiry, current audience and membership checks. Reuses existing immediate Family notifications and links; their delivery takes priority through spacing. Completing requires an authorized view of the matching content.                                                                                                                                                                 |
| ENG-06 | Reuses the existing opted-in personalized day, selected device and due time. Requires sufficient current activity, an actionable existing recommendation, no health/busy context and an unexpired source. No additional AI generation. Minimum seven days between proactive Lumi sends; viewing the actual source completes it. The legacy optional digest producer yields after handoff.                                                                                                  |

Mobile entry points are `apps/mobile/lib/features/engagement/`, Memories shelf, existing notification settings, push/inbox link handling and actual source viewers. Copy and controls support Vietnamese and English. The shelf handles loading, empty, offline/retry, dismiss, snooze, unavailable/expired source and paused preferences. System notification denial leaves eligible in-app suggestions available. Deep links reauthorize on the server; login retains only a validated opaque token in memory for at most ten minutes. Switching accounts cannot reuse a private route from the previous account.

## Late onboarding and campaign behavior

Onboarding at 1/3/6/9/12 months does not shift milestone dates. Calendar month arithmetic clamps month-end/leap dates; 100 days uses elapsed calendar days. Current campaigns use the existing D−7 through D+14 in-app window, D−3 09:00 due time and end-of-D+1 push expiry. These values remain product assumptions.

Past milestones enter a **retrospective in-app shelf only** when qualifying historical media and a usable existing template exist. The nearest eligible past milestone appears first, with one backfill suggestion visible at a time. It opens the existing occasion/template selection; creating/rendering/sharing still requires the user's explicit actions. Historical photo dates never backdate app activity. Missing history, a capped history query or an inaccessible catalog does not become evidence of a missing keepsake. Ready generated video is authoritative completion; a tap or render request is not.

Six-month support reuses the existing m6 occasion/templates. No new template art, renderer, purchases, entitlement bypass or background generation was introduced. The existing editor remains responsible for revalidating the user's chosen template/media.

## Policy, privacy and delivery boundaries

- New proactive push requires explicit new consent, its per-category choice, the existing notification category, live registered device, cached granted OS capability, recipient IANA timezone, an approved enabled policy and a fresh source. Defaults never imply consent.
- Proactive limits are at most one per rolling 24 hours and three per rolling seven days per account across babies/devices. Two dismissals in seven days reduce to at most one per seven days; three dismissals or three observed-unanswered suggestions in fourteen days pause for at least fourteen days and require explicit resume. Positive response never increases volume. A completed photo/milestone action quiets new proactive push for at least 48 hours. Snooze is 48 hours within validity. These thresholds remain configurable only within the conservative schema limits.
- `engagementFatigueEnabled` gates custom fatigue thresholds; turning it off retains the conservative default protection and existing pauses. Category/master/push flags are independent kill switches. Care remains outside the proactive budget. Existing Care/Family activity wins at least sixty minutes of spacing; Memories rank above the optional weekly/Family/Lumi opportunities.
- Default quiet hours for new pushes are 22:00–07:00 unless the user has explicit existing quiet settings. Missing recipient zone prevents push. Quiet-hour or snooze delays beyond expiry expire the opportunity; no catch-up burst.
- ENG-01/02/06 require acknowledgement that the competing optional local producer was cancelled on that device. Care and transactional alerts are excluded from this cancellation. Handoff is UID-owned and latched: disabling the new engine must not silently reactivate old optional producers.
- The reservation precedes external push I/O. A timeout/ambiguous send consumes its slot and is never automatically resent. `accepted` means the provider accepted a token; it does not mean device presentation. A known permanent adapter failure is `failed`; uncertain handoff stays `unknown`. OS swipe is never a product dismissal. Actual suggestion visibility plus a closed response window and reverified source is required to infer an ignored suggestion.
- No PhotoKit IDs, image bytes, face samples, names, DOB, Care text or Lumi conversation enter analytics or notification copy. Restricted DOB is used only to derive campaign eligibility. Push text is generic. Private source IDs stay within authorized operational data; Portal receives aggregate measurements.
- `engagementIntents`, `engagementReceipts`, `engagementCampaigns` and `engagementFences` have no direct client access. New private settings/device leases are also denied by Rules. Account/baby deletion purges engine state and writes replay fences; late refresh/domain callbacks cannot restore it. Prepared TTL/index definitions have **not** been applied to any environment.
- Headless ENG-01 preflight verifies persisted Auth UID, registered device and **every cached biometric baby scope** on the server before opening the local store. Only a current coParent with enabled Auto Save may obtain a fresh lease of at most 24 hours, bounded by membership expiry. Offline/unknown cannot renew; it can only use an already unexpired original lease. An explicit denied/revoked scope blocks scanning. Metadata sync transmits only the opaque episode and approved cloud-batch references. This path needs native/device privacy validation before activation. Android automatic scanning has not been added; unsupported source capability remains unavailable.

## Measurement and Portal

The engine now emits real idempotent server stages to the existing Analytics Foundation: eligible, scheduled, attempted, accepted, opened, completed, dismissed, snoozed, suppressed, cancelled, expired, unknown and failed. Eligibility is recorded before channel decisions. Original eligible/window timestamps and authoritative completion time are retained, including delayed source observation. Adapter errors cannot break existing Care delivery.

The existing Product Analytics Portal exposes ENG-01–06 stages/reasons, eligible-cohort conversion and maturity through its existing aggregate API. The new `failed` stage is visible in Vietnamese/English tables and exports. Feature controls expose new engagement flags through the existing audited flag workflow. Normal aggregation privacy thresholds still apply; no example baseline or growth lift was inserted.

This does **not** claim the entire analytics strategy is finished. [The foundation report](../product-analytics/08-foundation-implementation.md) still tracks discovery→review→approval→cloud-ready joins and the complete opportunity→template→render→share funnel. The ENG-02 reminder outcome measures ready video; it does not substitute for template-open conversion. Family eligibility currently comes from existing inbox events, so muted legacy categories without an inbox do not form an exhaustive independent domain-event denominator. Full live staging→Portal reconciliation is pending.

Six rule-based segment definitions are implemented/tested as a pure contract; frozen per-opportunity segment snapshots and segment drilldowns are not yet exposed. The cross-category `group_into_digest` decision is specified/tested, but automatic regrouping into another digest is not activated. Existing weekly and Family grouping work through their own sources. Experiment/grouping flags remain reserved/off: no control assignment, experiment, causal lift or statistical significance is claimed. These open measurement/policy items must be resolved against the V1 acceptance criteria before release, rather than silently marked complete.

## Local verification

All counts below are synthetic automated fixtures, not production baselines.

| Check                       | Result                                                                                                                                                                                                                                                                                                                          |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Contracts                   | 712 passed, including all seven decisions, caps, quiet-hour expiry, calendar clamping and join ages 1/3/6/9/12 months.                                                                                                                                                                                                          |
| Functions unit regression   | 486 passed, one pre-existing skipped test.                                                                                                                                                                                                                                                                                      |
| Firestore integration/Rules | 58 passed across engagement, notification adapter, Care rules, product analytics and personalization suites. Sixteen engagement cases cover retries, concurrent budgets, OS handoff, source completion, retrospective campaigns, fatigue, deletion fences, authoritative viewing, Family/Lumi reuse and headless authorization. |
| Mobile                      | 178 passed across eleven relevant suites. Includes six new local episode/account/launch tests. `flutter analyze`: no issues.                                                                                                                                                                                                    |
| Portal                      | 240 passed. Typecheck and dev bundle build pass; the existing large-chunk build advisory remains.                                                                                                                                                                                                                               |
| Static/build                | Contracts/Functions/Rules-tests/Portal typechecks, local Functions deploy-bundle build, targeted ESLint and Swift syntax parse pass. Building a deploy bundle is not a deployment.                                                                                                                                              |

Commands used include:

```sh
pnpm --filter @child-life/contracts test
pnpm --filter child-life-functions test
pnpm --filter child-life-functions build
pnpm --filter child-life-rules-tests typecheck
pnpm --filter child-life-portal test
pnpm --filter child-life-portal typecheck
pnpm --filter child-life-portal build:dev
firebase emulators:exec --only firestore --project demo-child-life \
  "pnpm --filter child-life-rules-tests exec vitest run engagement.integration.test.ts notifications.integration.test.ts reminder-rules.integration.test.ts product-analytics.integration.test.ts personalization-v2.integration.test.ts"
# apps/mobile
flutter analyze
flutter test test/features/engagement_test.dart test/features/auto_save_test.dart \
  test/features/keepsake_test.dart test/features/memory_story_test.dart \
  test/features/notifications_test.dart test/features/reminder_test.dart \
  test/features/rule_reminders_test.dart test/features/story_test.dart \
  test/features/product_analytics_test.dart test/features/rhythm_plans_test.dart \
  test/app/local_privacy_guard_test.dart
```

The emulator run used an isolated temporary configuration and demo projects. Real iOS/Android push, headless Firebase startup, OS cancellation/expiry and cold/warm links have **not** been certified. Swift parsing is not a native app build or a device test. A physical iPhone was discovered; no physical Android was listed. No app was installed on those devices during this work.

## Approval refinements and release gates

In addition to A-01–A-11, resolve these concrete implementation choices before activation:

1. **A-12 — terminal dedup retention:** source-bearing intents expire thirty days after the conversion window; hashed terminal/campaign replay markers and deletion fences retain up to approximately 400 days. Markers contain private owner/baby references for erasure, without source payload. This exceeds the audit's original thirty-day receipt proposal and needs privacy approval or a replacement that preserves duplicate prevention. TTL activation is a separate approved environment change.
2. **A-13 — authenticated headless renewal:** approve/test the preflight lease flow above. It strengthens live authorization compared with the legacy offline-only path, while introducing Auth/Functions initialization in the headless engine. Until the privacy/device gate passes, ENG-01 stays off.
3. **A-14 — bounded source/history processing:** per-account refresh budget 100/hour; at most 200 intents inspected per account; campaign evidence caps at 2,001 media and 1,001 jobs; Family group at most fifty inbox references; coordinator processes at most 100 due intents per tick. Unproven capped campaign history prevents a campaign. Measured load, stale-intent cleanup/fairness and safe unavailable behavior at those bounds remain release gates, not a claimed scalability result.

Before release, complete outstanding analytics/segment acceptance, approve policy/retention, test real iOS and Android capability matrices, reconcile known source events through staging→Portal, perform privacy/deletion validation and demonstrate category/master kill switches and rollback. Record app/backend/config revisions and expected versus observed results. No limited-user pilot or fabricated significance threshold is required.

Approved rollback disables new push/category/master flags, invalidates leases and cancels pending optional local notifications best effort. It retains user memories, approved uploads, keepsake jobs, configured Care routines, consent and terminal replay markers. Already accepted remote pushes cannot be recalled; links still reauthorize. Do not reenable legacy optional producers automatically after handoff. Deployment/configuration and store release require separate owner approval.
