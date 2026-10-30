# 10 — Release decision

## Decision: **NO-GO** for a public release

The question is "is this ready for real users?". The answer turns on facts that are not matters of quality judgement:

1. **There is no production environment for the apps.** A prod build stops at startup by design, because the Firebase
   options for prod are `null` and the prod config files do not exist (REL-01).
2. **There is no approved privacy policy, terms or consent** for a product that stores children's photos,
   health-adjacent care data, face-matching signals and AI-processed notes (LEG-01; Q-020, Q-055, Q-070 open).
   Both stores require a policy URL. Vietnamese law requires a lawful basis for children's data.
3. **A guessable 6-digit code can grant membership to a stranger's baby.** The brute-force limit keys on
   values a client controls (SEC-01; mechanism confirmed in code, live exploitability not tested).
4. **No green build exists for the candidate.** Lint, format, 9 Flutter tests and the CI-ordered `pnpm test` fail, and
   the branch is not under CI (QA-01). One failing guard protects against duplicate feed logging (QA-02).

## Why this is not a quality verdict on the product

The engineering underneath is unusually careful. Evidence:

- 1,175 Rules and integration tests pass on emulators; 2,895 of 2,904 Flutter tests pass; 2,200 goldens.
- Schema-validated deny-by-default Rules; verified, resumable deletion.
- Per-account local isolation; lease-fenced video rendering; server-only grants.
- Full vi/en parity; kill switches for every feature.

The 2026-10-20 P0s are fixed in code, and the renderer fencing tests pass.

## Conditions to move to CONDITIONAL GO (closed beta with invited real families)

1. REL-01 done: prod provisioned, a prod smoke test passed with a staff family on iOS and Android.
2. LEG-01: published privacy policy and terms; consent decided for child data and AI. Tự lưu face matching and AI
   features stay **off** until Q-055 and Q-070 are approved.
3. SEC-01 fixed and re-tested with spoofed `X-Forwarded-For`.
4. QA-01 and QA-02: a CI run on a tagged commit is fully green.
5. Launch definition signed (OPS-02, PRD-01, COM-01 option (a): `premium_v2` off, no upgrade CTAs).
6. OPS-01 minimum: PITR on, budget alert, function error alert, a written rollback step.

## Conditions to move from CONDITIONAL GO to GO (public store release)

1. Beta evidence: the regression suite in [07](07-qa-test-coverage.md) passed on the release candidate on both platforms.
   Crash-free users ≥ 99.5 % over two weeks of beta. No open P0 or P1.
2. SEC-02 App Check enforced. SEC-03 staff second factor decided by the owner.
3. STORE-01 store disclosures accepted by App Review and Play review.
4. ANA-01 measurement on, so launch outcomes are visible.
5. Restore drill completed once (OPS-01).
6. If Premium is part of the launch: store billing shipped and Q-058, Q-071 and Q-073 closed (COM-01 option (b)).
