# Personalization v2 — implementation and review handoff

Date: 2026-10-20. For Claude Fable review. Reference: [consolidated P-172 plan](../product/personalization-v2-plan.md).

The owner requested implementation of v2 and the additional recommendations. The workspace now contains
the implementation below. It has not been deployed or verified on physical devices. This is a code
handoff, not release approval. The original audit describes the earlier code, not the current implementation.

## Scope implemented

| Plan    | Current implementation                                                                                                                                                                                                                                                             | Boundary                                                                                                                                                                                                                                                                                                                            |
| ------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| A1–A2   | Server snapshot of permitted care records; quality-qualified ranges of recorded feed intervals and completed daytime sleep duration; sample/day counts and freshness; factual last-record handover.                                                                                | Observations of the diary, not a prediction or a prescribed schedule. At least 5 samples across 3 days, recent data, limited spread, deduplication and overlap checks. Suppressed on health/unusual-routine days, open sleep conflicts, running sleep timer or truncated queries. No new feed/diaper adequacy or growth thresholds. |
| A3      | Existing `sleepFacts` baseline/recent comparison under `rhythm.advanced`; existing nutrition signals join the feed under their existing permissions.                                                                                                                               | Expanded feed/diaper change detection and growth channel crossing await reviewed coverage criteria and clinical rules; they are not implemented as new clinical signals.                                                                                                                                                            |
| A4      | A feed-interval range opens the existing `afterLast` rule editor with an editable interval and personal recipient default.                                                                                                                                                         | A person must save the rule. No automatic reminder creation or later automatic interval changes.                                                                                                                                                                                                                                    |
| B1      | Explicit digest opt-in, selected installation, stored EN02 clock, quiet hours, fresh meaningful content, busy/health suppression, Sunday weekly-summary deduplication, server reservation and fixed local notification ID.                                                         | Only a future time today is reserved. No background promise for tomorrow, no OS-delivery claim and no remote cancellation guarantee for an offline installation. Opening refetches under current authorization.                                                                                                                     |
| B2      | Existing Sunday summary extended with eligible age content, one activity, editorial `watchFor` and the viewer's rolling seven-day attempted/helpful summary.                                                                                                                       | Reuses the existing weekly entry/notification. Counts are the viewer's current activity responses, not household totals or a causal effect measurement.                                                                                                                                                                             |
| C1–C4   | Save, hide, snooze, dislike, known, intention, confirmed attempt, helpful/unsure and restore. Outcome requires an attempt. Saved status and outcome survive visibility restoration. Shared baby exclusion is explicit and co-parent only.                                          | Legacy `started` remains an intention. Existing baby-level legacy feedback is preserved. Essential health/reminder cards cannot be hidden by content preferences. Personal restoration and shared-exclusion restoration are separate actions.                                                                                       |
| D1      | 24 bilingual, source-linked activities for 12–36 months, including short options, and a deduplicated portal import into the working draft.                                                                                                                                         | `status: draft`, `review: null`. No automatic publishing or reviewer attribution. The draft pack is available at `content/rhythm/toddler-v2.draft.json`.                                                                                                                                                                            |
| D2 / I3 | Closed generic app events; visibility-based impressions; explicit outcomes; per-content/version aggregate generation and answer counts; portal reporting.                                                                                                                          | No child/person IDs in analytics. Generated does not mean shown; scheduled does not mean delivered. Generic impressions cannot supply content-level conversion rates. No automatic content retirement.                                                                                                                              |
| D3      | Existing actual-age behavior retained.                                                                                                                                                                                                                                             | Corrected developmental age remains conditional on Q-086/domain review. Feeding, vaccine and health age policies are unchanged.                                                                                                                                                                                                     |
| E1–E3   | Personal/shared notebook with explicit confirmation, revision conflicts, expiry, edit/delete, expired-note history, structured activity exclusions, and a Lumi composer shortcut that opens an editable draft. Active shared care notes are quoted in deterministic care guidance. | Private text never enters the shared Lumi thread. No automatic extraction/save, arbitrary model instructions or provider memory. Only co-parents set shared avoid constraints.                                                                                                                                                      |
| F1–F2   | Home composes one primary and up to two supporting cards from existing rhythm, reminders, local solids, nutrition, milestones, vaccines and keepsake/content sources. Health wins; roles, deduplication, preferences and expiry apply.                                             | Solids meal data stays on the device. Sources keep their existing capabilities and rules. The complete reminder list remains available outside the feed cap.                                                                                                                                                                        |
| G1–G2   | Optional person-level daily capacity; co-parent-confirmed unusual routine; an editable personal weekly focus, all with timezone-based expiry.                                                                                                                                      | Focus is personal. This version does not introduce a shared household-goal authority or infer interests/emotions.                                                                                                                                                                                                                   |
| H1–H2   | Factual handover, acknowledgement fingerprint and changed-since-read indicator; transactional accept/release/complete of existing reminder work.                                                                                                                                   | Assigned caregivers act on their assigned reminders; co-parents manage work. Assignment/reassignment uses the existing reminder editor. Completion marks that reminder done and never fabricates a care record.                                                                                                                     |
| I1–I2   | Read-time recommendation validation against day, content/version, eligibility and source check-in revision; viewer-keyed legacy cache; access errors discard cached invitations; new snapshot is memory-only; export/purge extended.                                               | Old recommendation/feedback documents are not rewritten or reinterpreted. Transport failures may use the legacy cache only while all local eligibility checks pass.                                                                                                                                                                 |

## Review entry points

- Contract and pure rules: `packages/contracts/src/personalization-v2.ts`; compatible recommendation additions in `personalization.ts`; closed analytics vocabulary in `account.ts`.
- Callable implementation: `firebase/functions/src/personalization-v2.ts` (`getPersonalizedDay`, `updatePersonalizedDay`, `reservePersonalizationDigest` exports in `index.ts`).
- Ranking constraints: `personalization-state.ts`, `rhythm.ts`, and the narrow integration in `assistant-care.ts`. Household stored recommendations use shared constraints; person-specific projection must not retire another person's invitation.
- Analytics: `personalization-stats.ts`, `rhythm-content.ts`, `apps/portal/src/screens/PersonalizationMetrics.tsx`.
- Flutter: `apps/mobile/lib/features/rhythm/personalization_v2_{repository,screen}.dart`, `personalization_sources.dart`, `personalization_digest.dart`, `personalization_events.dart`; Home wiring in `features/today/today_for_baby.dart` and `rhythm_home.dart`.
- Notification integration: `features/reminders/reminder_notifications.dart`; reminder preview in `rule_screens.dart` and router query handling.
- Storage/retention: `firebase/firestore.rules`, `firestore.indexes.json`, `firebase/functions/src/account.ts`.

The workspace already contained ongoing Lumi changes before this implementation. Its entire diff is not
the personalization change. In the shared assistant files this work adds constraints/confirmed shared
notes to care guidance and an explicit notebook-draft shortcut; preserve the other Lumi work during review.

## Storage and authority

- `users/{uid}/personalization/{babyId}`: caller-owned context/focus/responses/acknowledgement. Server writes only; direct reads require owner and current baby care access.
- `babies/{b}/notebook/{id}`: shared or author-private notes. Callable reads project by scope; writes check role, author and revision. A co-parent cannot read/edit another author's personal note. Expired notes remain editable but do not affect ranking or Lumi.
- `babies/{b}/personalization/routine`: co-parent-confirmed routine exception until the next baby-local day.
- `babies/{b}/personalizationExclusions/{activityId}`: explicit co-parent exclusions. Personal response restore cannot remove them; shared restore requires `scope: baby` and co-parent authority.
- `babies/{b}/careWork/{reminderId}`: transactional claim/revision with idempotent replays. The reminder remains the assignment authority.
- `users/{uid}/settings/personalizationDelivery` and `personalizationDigestLease`: explicit channel/install selection and private scheduling reservation. Clients cannot forge a lease. Transferring installs cannot reserve a second slot that day; a pending same-install clock change may replace its future schedule.
- `contentStatsDaily/{VN date}`: content/version counters only. The nightly 02:20 Vietnam job replaces the previous day's generated map idempotently while preserving answer counters.

All callable requests are strict validated shapes. User/baby access is checked on reads and rechecked in
mutation transactions. Notebook and personal response maps have operational caps of 200 entries; these
are bounded-storage safeguards, not a pricing tier. Notebook entries can be removed, including expired ones.
Queries cap records at 1,500 and unfinished reminders at the earliest 100; truncated diaries do not produce
routine ranges. Caregiver handover excludes restricted growth records.

## Verification

Local checks on 2026-10-20:

- `flutter analyze`: no issues.
- 10 affected Flutter test files: 267 passed (new v2, rhythm flow/plans/week, Today, notifications, reminders/rules, Lumi chat/photo care).
- Contracts: 34 files, 577 tests passed.
- Functions: 26 files, 474 passed, 1 skipped.
- Portal: 16 files, 233 tests passed.
- Firestore/Storage emulator: 6 suites, 115 passed (`personalization-v2.integration`, `rhythm.integration`, `rhythm.rules`, `account.integration`, `assistant-care.integration`, `account.rules`).
- Contracts build, Functions/portal/rules-test TypeScript checks and repository ESLint passed; `git diff --check` passed.
- Functions deployment bundle and portal dev build passed. Vite reports a large main JS chunk (about 2.42 MB minified); bundle splitting remains a separate performance concern.

The v2 integration cases cover private-note boundaries/expiry/conflicts, outcome ordering, independent
personal/shared restores, role revocation, growth privacy, two-device work conflict/replay, handover change
acknowledgement, explicit digest consent/install ownership/time/quiet hours and idempotent anonymous
aggregation. Contract cases cover timezone/DST boundaries, source freshness, invalid paths, sparse/noisy
diaries and non-published toddler drafts. Widget cases cover scoped context, stale source removal, available
after-try feedback and caregiver controls. These checks do not establish usefulness in a user study.

## Rollout and remaining verification

No production or dev deployment was performed. Apply the Firestore rules/index changes and wait for
indexes to be ready before deploying the Functions and clients through the existing dev workflow. Keep
the existing rhythm/personalization flags and commercial capabilities; no new billing configuration is required.
There is no migration of a stored digest clock into consent, no automatic rewrite of legacy feedback,
and no automatic publication of the toddler pack.

Before release, exercise the dev backend on iOS and Android in Light/Night care and large text; verify
notification permission denial, app restart, timezone/day rollover, sign-out, access revocation, two installs
and pending-clock changes. A local notification already held by an offline device cannot be recalled
remotely; its generic copy carries no care details. Opening always reauthorizes. Scheduling counters must
not be presented as delivery metrics. Do not mark the Figma device checklist complete from these tests.

Q-080–Q-085 now have concrete implementation choices for review, as described above; this does not invent
new D-xxx decisions or claim commercial/privacy rollout sign-off. Q-069 content review and Q-086 corrected-age
policy remain open. A1/A3's broader clinical interpretation, shared weekly household goals, automatic Lumi
note extraction, offline facts parity and content-attributed impression/conversion reporting are not delivered
by this implementation. They need the domain/product/privacy decisions described in the plan.
