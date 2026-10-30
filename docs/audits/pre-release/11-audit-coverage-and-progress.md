# 11 — Audit coverage, progress and limitations

Audit run 2026-10-29 in one pass (status: **complete**). Branch `s2-onboarding`. The code was read at `ebcdcf49` plus the
working tree. Another session committed `8e53ea55` during the audit, and failing tests were re-run there.
Audit-only: no application code, ARB, golden baseline, Rules, configuration or deployment was changed.
Emulator runs used an isolated scratch config; the other session's emulators were not touched.

## Module coverage

| #   | Module                                                                        | Depth                                                                                                                                    | Result file |
| --- | ----------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| 0   | Discovery: README, business map, plan, checklist, slice reports, prior audits | Read                                                                                                                                     | 00          |
| 1   | Environments and prod provisioning                                            | Code + config read                                                                                                                       | 08          |
| 2   | Firestore Rules                                                               | All 92 `match` blocks listed; helpers and care / timer / record validation read; full suite executed                                     | 06, 07      |
| 3   | Storage Rules                                                                 | Read in full                                                                                                                             | 06          |
| 4   | Functions entry points                                                        | All `onRequest` read; callable wrappers; invite, share and auth-mail limits                                                              | 06          |
| 5   | Identity, session, temporary-account merge                                    | Merge path read                                                                                                                          | 03          |
| 6   | Family and invites                                                            | Lookup, lockout, accept read                                                                                                             | 06          |
| 7   | Care logging, timers, offline outbox                                          | Repository and format read                                                                                                               | 03          |
| 8   | Memories, upload, quota, keepsake render fencing                              | Prior P0 fixes checked; renderer tests executed                                                                                          | 03          |
| 9   | Premium, billing, entitlements                                                | Billing core, plan limits, flags read                                                                                                    | 02          |
| 10  | Lumi / AI                                                                     | Flags, secrets, consent questions (no prompt or model review)                                                                            | 06, 08      |
| 11  | Account / baby deletion, export                                               | Deletion steps read                                                                                                                      | 06          |
| 12  | Analytics, crash reporting                                                    | Bootstrap and analytics docs read                                                                                                        | 02, 08      |
| 13  | Localisation                                                                  | Script: keys, placeholders, untranslated                                                                                                 | 04          |
| 14  | Web (landing, portal)                                                         | Legal page, hosting headers, tests executed                                                                                              | 08          |
| 15  | Store, legal, privacy disclosures                                             | Searched for presence                                                                                                                    | 08          |
| 16  | Automated checks                                                              | Executed (see 07)                                                                                                                        | 07          |
| 17  | Cross-module review                                                           | Done: invite → membership → media access; Premium v2 → storage → upload dead end; deletion → renderer / print leases; flags → navigation | 02, 03      |

## Not covered or not verifiable here

- **No device runtime testing:** iOS and Android, push, deep links, background upload, widgets, Live Activity, Watch.
- **No fresh golden render** (D-111), so no visual claims are made.
- **No live requests** to dev or prod: SEC-01 exploitability, App Check behaviour, `X-Forwarded-For` handling.
- **Infrastructure outside the repo was not inspected:** Cloud Monitoring, IAM, budgets, PITR, Secret Manager access.
- **Not reviewed:** Lumi prompts, model outputs, health-content accuracy, keepsake template content.
- **Per-scheduler review** of 38 schedules and about 45 triggers was not done. Sampled only.
- **Not run:** dependency vulnerability audit, golden suite, `integration_test/`, assistant E2E.
- **Feature modules read only at entry level:** spending, nutrition, solids, vaccines, print studio, library, first aid, rhythm, personalisation, Cùng Chăm Con.

## Resuming

To extend this audit, take one row from "Not covered" above, record its result in the matching file,
and update the finding index in [01](01-executive-summary.md). The findings already recorded need not be
re-derived.
