# 01 — Executive summary: Child Life pre-release audit

**Date:** 2026-10-29 · **Snapshot:** `s2-onboarding` @ `8e53ea55` (audit started at `ebcdcf49`) · **Mode:**
audit-only; no code, data, baseline or deployment changed · **Decision: NO-GO for public release**
([10](10-release-decision.md)). A closed beta is reachable after 6 concrete conditions.

## Readiness at a glance

| Dimension             | Rating       | One-line reason                                                                                         |
| --------------------- | ------------ | ------------------------------------------------------------------------------------------------------- |
| Product completeness  | 🟡 Partial   | Core loop built in depth on dev; 0/155 screens verified end to end; widgets blocked on the Apple team   |
| Business readiness    | 🔴 Not ready | No launch scope or targets; Premium cannot be bought; landing promises features the app lacks           |
| Technical readiness   | 🟡 Partial   | Strong architecture and tests; the release candidate is not green and not under CI                      |
| UX readiness          | 🟡 Partial   | Mature design system and copy parity; Today loading guard failing; paywall dead end if Premium v2 is on |
| Security readiness    | 🔴 Not ready | Rules strong (1,175 tests green); invite-code brute force bypassable; no App Check; staff without 2FA   |
| Privacy / legal       | 🔴 Not ready | No privacy policy or terms; child-data, face-matching and AI consent undecided                          |
| Operational readiness | 🔴 Not ready | No prod environment for the apps; no backup, restore or alerting evidence; no launch flag matrix        |

## Major risks

1. **REL-01 (P0):** production does not exist for the apps. The prod build refuses to start by design.
2. **LEG-01 (P0):** children's photos, care data, face matching and AI processing have no approved
   policy or consent (Q-020, Q-055, Q-070).
3. **SEC-01 (P0):** a 6-digit invite code alone grants membership. The lockout keys on a spoofable header
   and on cheap identities.
4. **QA-01 / QA-02 (P1):** no green build. Lint, format, 9 Flutter tests and the CI-ordered `pnpm test` fail.
   One failing guard protects parents from double-logging feeds.
5. **COM-01 (P1):** Premium v2 sets Free storage to 1 GB, but no purchase path exists.

## Findings by severity and category (deduplicated by root cause)

| Category                   | P0    | P1     | P2     | P3    | Total  |
| -------------------------- | ----- | ------ | ------ | ----- | ------ |
| Release & operations       | 1     | 3      | 0      | 1     | 5      |
| Legal & privacy            | 1     | 0      | 1      | 0     | 2      |
| Security                   | 1     | 2      | 1      | 2     | 6      |
| QA & functional            | 0     | 2      | 3      | 1     | 6      |
| Product & business         | 0     | 3      | 3      | 0     | 6      |
| UX/UI                      | 0     | 0      | 2      | 1     | 3      |
| Architecture & performance | 0     | 0      | 2      | 2     | 4      |
| **Total**                  | **3** | **10** | **12** | **7** | **32** |

Merged duplicates: UX-01 → QA-02, UX-02 → COM-01, UX-05 → PRD-04, PRIV-02 → LEG-01; share-link passcode → SEC-01.

## Finding index

| ID       | Sev | Title                                                          | Verification                       | File                                 |
| -------- | --- | -------------------------------------------------------------- | ---------------------------------- | ------------------------------------ |
| REL-01   | P0  | Prod not provisioned; prod build cannot start                  | Code inspection                    | [08](08-production-readiness.md)     |
| LEG-01   | P0  | No privacy policy or terms; consent undecided                  | Documentation gap                  | [08](08-production-readiness.md)     |
| SEC-01   | P0  | Invite code brute force; IP limit uses first XFF hop           | Code inspection; exploit suspected | [06](06-security-privacy.md)         |
| QA-01    | P1  | No green build; branch not under CI                            | Executed test                      | [07](07-qa-test-coverage.md)         |
| QA-02    | P1  | Today "loading ≠ empty" guard failing (SY-1)                   | Executed test                      | [03](03-functional-bugs.md)          |
| SEC-02   | P1  | No App Check anywhere                                          | Code inspection                    | [06](06-security-privacy.md)         |
| SEC-03   | P1  | Staff portal without second factor                             | Documentation (owner decision)     | [06](06-security-privacy.md)         |
| COM-01   | P1  | No purchase path; Premium v2 limits trap Free users            | Code inspection                    | [02](02-product-business.md)         |
| PRD-01   | P1  | No launch scope or targets; health reviewer open               | Documentation gap                  | [02](02-product-business.md)         |
| PRD-02   | P1  | V1 scope unverified end to end (0/155 ☑; S16 not started)      | Documentation gap                  | [02](02-product-business.md)         |
| OPS-01   | P1  | No backup, restore, alerting or runbooks                       | Documentation gap                  | [08](08-production-readiness.md)     |
| OPS-02   | P1  | No launch flag matrix; core flags default off                  | Code inspection                    | [08](08-production-readiness.md)     |
| STORE-01 | P1  | Store disclosures and listing not prepared                     | Documentation gap / suspected      | [08](08-production-readiness.md)     |
| FN-01    | P2  | 8 more deterministic test failures                             | Executed test                      | [03](03-functional-bugs.md)          |
| PRIV-01  | P2  | Diagnostics consent pre-ticked                                 | Code inspection                    | [06](06-security-privacy.md)         |
| DATA-01  | P2  | Care and receipt photos bypass the quota                       | Suspected                          | [06](06-security-privacy.md)         |
| QA-03    | P2  | Golden comparisons in untagged tests                           | Executed test                      | [07](07-qa-test-coverage.md)         |
| QA-04    | P2  | No release-candidate E2E proof                                 | Documentation gap                  | [07](07-qa-test-coverage.md)         |
| PRD-03   | P2  | Landing promises not in the app (Q-008, Q-009, Q-039)          | Documentation                      | [02](02-product-business.md)         |
| PRD-04   | P2  | English copy unreviewed                                        | Code inspection                    | [02](02-product-business.md)         |
| ANA-01   | P2  | Launch measurement off (PA-05 pending)                         | Code inspection                    | [02](02-product-business.md)         |
| UX-03    | P2  | Navigation complexity across flag combinations                 | Improvement opportunity            | [04](04-ux-ui.md)                    |
| UX-04    | P2  | Accessibility not verified on devices                          | Documentation gap                  | [04](04-ux-ui.md)                    |
| ARC-02   | P2  | Dark modules still deploy schedules and triggers               | Suspected                          | [05](05-architecture-performance.md) |
| PERF-01  | P2  | Performance unmeasured (listeners, cold start, long histories) | Suspected (risk, not defect)       | [05](05-architecture-performance.md) |
| FN-02    | P3  | Refused offline writes after restart not surfaced              | Code inspection                    | [03](03-functional-bugs.md)          |
| SEC-04   | P3  | `String(error)` in logs                                        | Suspected                          | [06](06-security-privacy.md)         |
| RULE-01  | P3  | Some deletes skip `babyOpen`                                   | Code inspection                    | [06](06-security-privacy.md)         |
| UX-06    | P3  | Dev screens in prod routes                                     | Code inspection                    | [04](04-ux-ui.md)                    |
| REL-02   | P3  | Versioning and release process                                 | Documentation gap                  | [08](08-production-readiness.md)     |
| ARC-01   | P3  | Very large single files                                        | Code inspection                    | [05](05-architecture-performance.md) |
| ARC-03   | P3  | Lint and format scan local worktrees                           | Executed check                     | [05](05-architecture-performance.md) |

## Strengths worth keeping

- Rules are deny-by-default and schema-validated: 97 files and 1,175 emulator tests are green.
- Deletion is verified and resumable. Video jobs are lease-fenced (renderer 37/37 with emulator). Local data is isolated per account.
- Server-only entitlements: a client "success" never grants Premium.
- 6,596 strings at full vi/en parity. 2,200 goldens in Light and Night care.
- 37 kill switches with safe defaults. Strict environment separation in app, web and deploy scripts.

## Report map

[00 Product understanding](00-product-understanding.md) · [02 Product & business](02-product-business.md) ·
[03 Functional & bugs](03-functional-bugs.md) · [04 UX/UI](04-ux-ui.md) ·
[05 Architecture & performance](05-architecture-performance.md) · [06 Security & privacy](06-security-privacy.md) ·
[07 QA & tests](07-qa-test-coverage.md) · [08 Production readiness](08-production-readiness.md) ·
[09 Action plan](09-action-plan.md) · [10 Release decision](10-release-decision.md) ·
[11 Coverage & limitations](11-audit-coverage-and-progress.md)
