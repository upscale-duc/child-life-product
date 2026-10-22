# 04 · Smart Engagement ENG-00–06 on the unified platform

**P-174.** The full Smart Engagement V1 specification remains:

- [12 audit](../product-audit/12-smart-reminder-audit.md)
- [13 rules](../product-audit/13-engagement-rules.md)
- [15 journeys](../product-audit/15-engagement-journeys.md)
- [16 memory campaigns](../product-audit/16-memory-campaigns.md)
- [17 implementation](../product-audit/17-engagement-implementation.md)
- [18 code audit](../product-audit/18-smart-reminder-code-audit.md)

This page says how the engine sits on the platform and what changed in P-174. The owner approved assumptions A-01–A-14 (D-092 #3). The policy (`config/engagement`: approval, caps, quiet hours, device lease) is edited in Portal → Thông báo & Gắn kết → Cài đặt, audited; flags still default off in code and are turned on per environment.

## 1. One pipeline

```
discover (getEngagement / inbox / care observers)
  → engagementIntents (decideEngagement: eligibility, caps, quiet hours, snooze, fatigue, consent)
  → dispatchEngagement: atomic reservation → final recheck
  → notifyUsers  ← the same entry point every producer uses
       → inbox row + ledger entry (persist first) → provider → accepted / failed / unknown
  → engStage(stage) → Product Analytics fact (existing)
                    → ledger action dimension (new: started / completed / expired / unavailable)
```

Smart Engagement has no delivery code of its own. It passes the following to `notifyUsers`:

- `retry: false`: an ambiguous send is `unknown` and is never resent. The ENG-00 slot stays consumed.
- `engagement {id, kind}`: links the ledger to the intent. The family timeline joins them, and the action dimension follows the intent.
- `template: eng.*`: the Portal can edit ENG copy. Version 0 equals `engagementCopy` (unit-tested).
- `destination`: an ENG-specific semantic id. The app sends it to `actOnEngagement`, which re-authorises on the server.

Suppressed opportunities never reach the inbox. An `in_app_only` decision shows on the Memories shelf, not as an inbox row. The family timeline shows suppressed and in-app intents as `e_…` entries without a ledger row.

## 2. Scenario status

| Scenario | Source and trigger | Platform kind / destination | Completion (authoritative) | Status |
| --- | --- | --- | --- | --- |
| ENG-00 | Shared engine: eligibility, scheduling, idempotency, quiet hours, caps 1/24 h and 3/7 d, snooze 48 h, fatigue, kill switches, consent, locale, multi-device lease, multi-caregiver | — | — | Implemented, default off |
| ENG-01 Pending photos | Opaque review episode; push ≥ 24 h after first server observation, expires after 7 d | `photoSuggestion` / MEMORIES_PENDING_REVIEW | Approved batches cloud-ready | Implemented; needs device privacy validation (A-13) |
| ENG-02 Milestone | m1 · d100 · m6 · y1 from DOB in the baby's zone; D−3 09:00; window D−7…D+14 | `keepsakePrompt` / MEMORIES_KEEPSAKE_SUGGESTION | Ready keepsake video (not a tap or a render request) | Implemented; **#21 fixed** (see below) |
| ENG-03 Weekly digest | Closed ISO week with saved memories (save time, not capture time) | `weeklySummary` / MEMORIES_WEEKLY_RECAP | Authorised view of the week's content | Implemented |
| ENG-04 Care | Observes user-configured rule reminders; never sends, never budgeted | rides `reminderRule` / CARE_RULE_REMINDER | Logged / snoozed / skipped occurrence | Implemented; **#19 fixed** |
| ENG-05 Family | Groups unseen family inbox rows over 30 min; 24 h expiry | `familyActivity` / FAMILY_SHARED_CONTENT | Authorised view of the shared content | Implemented |
| ENG-06 Lumi insight | Existing opted-in personal day; no extra AI generation; ≥ 7 d between sends; no health/busy context | `rhythm` / LUMI_INSIGHT | View of the source suggestion | Implemented |

## 3. Late onboarding and historical memories

These rules hold since doc 17 and are covered by `engagement.integration.test.ts`, including joins at 1, 3, 6, 9 and 12 months:

- **Dates come from the DOB.** A family's onboarding date never shifts a milestone date.
- **Past milestones are offered in-app only.** They appear as a retrospective in-app suggestion when historical ready photos and a usable template exist. The engine never pushes a past milestone (`decideEngagement` returns `in_app_only` for retrospective context). A family joining at 3 months never gets "your baby is about to turn one month".
- **Fixed in P-174 (doc 18 #21):** the retrospective suggestion now has its own source key, `campaign:<occasion>:retro`. It can follow a current campaign that closed without a keepsake (doc 13 §44). A finished keepsake, a dismissal or a keepsake in flight still suppresses it.
- **Nothing is spent automatically:** no credits are spent and nothing is rendered without the user's explicit action.

## 4. Doc 18 open items

| # | Item | P-174 outcome |
| --- | --- | --- |
| 10 | Push only reaches people with a device lease from the last 2 h (proactive kinds other than ENG-01) | **Fixed (D-092 #6).** The lease lasts `deviceLeaseDays` (policy, default 30, 1–60). A send still needs a live token, no sign-out and current membership; sign-out or revocation ends the lease at once. Test in `engagement.integration.test.ts`. |
| 19 | Care pushes waited on ~5 engagement reads per recipient | **Fixed.** One config read per baby (`careEngagementOn`). With engagement off, the per-recipient observation and adapter callback are skipped. |
| 20 | Client refresh can hit the 100/h limit | **Open.** The fix belongs in `engagement_repository.dart`, which another session was editing during this work. A debounce of ~60 s on resume/media-count refresh is recommended. |
| 21 | Retrospective cannot follow a current campaign | **Fixed** (see §3). The test is updated in `engagement.integration.test.ts`. |
| 22 | Photo age measured from UTC midnight; fatigue resume does not re-arm intents | **Fixed.** Age counts from midnight in the baby's zone. Resume re-arms intents that `fatigue_paused` suppressed while their window is open. A window that already closed stays closed (no catch-up). New test. |

## 5. Activation gates (unchanged)

The gates below still apply before any ENG flag is turned on:

- Doc 17 A-01–A-14 approvals.
- Doc 18 #10 and #20.
- Real-device push matrix ([08](08-operations.md)).
- Staging-to-Portal reconciliation.
- A demonstration of the kill switches.
