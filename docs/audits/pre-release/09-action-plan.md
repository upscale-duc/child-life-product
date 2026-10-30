# 09 — Prioritized action plan

Owner = who must act. "Eng" can proceed autonomously; "Owner" is an L3 decision or an account the owner
holds (D-005, D-109).

## Must fix before release

| #   | ID              | Action                                                                                                                                                                                                                        | Owner               | Effort |
| --- | --------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- | ------ |
| 1   | REL-01          | Provision prod (`child-life-ecosystem`): Firebase apps and config files, Apple developer team and `app.childlife` bundle, Play listing, secrets, domains, AASA / assetlinks; deploy Rules, indexes and Functions; seed config | Owner → Eng         | L      |
| 2   | LEG-01          | Lawyer-approved privacy policy and terms (vi + en); decide and build consent for child data, face matching (Tự lưu) and AI (Q-020, Q-055, Q-070); record the consent version                                                  | Owner (legal) → Eng | M      |
| 3   | SEC-01          | Fix the client-IP derivation (rightmost trusted hop), add a global failure budget with an alert, require sign-in for code preview; re-test with spoofed XFF                                                                   | Eng                 | S–M    |
| 4   | QA-01           | CI on the working branch; renderer tests under emulators; ignore `.claude/` and fix tracked lint and format; a green run on a tagged commit                                                                                   | Eng                 | S–M    |
| 5   | QA-02           | Restore or re-specify the Today loading guard (SY-1); triage the other 8 failing tests (FN-01)                                                                                                                                | Eng                 | S      |
| 6   | COM-01          | Decide the launch model: free launch with `premium_v2` off and no upgrade CTAs, **or** ship store billing first (needs Q-058, Q-071, Q-073)                                                                                   | Owner               | S / L  |
| 7   | OPS-02 + PRD-01 | One-page launch definition: modules and flags on, limits, target metrics, beta cohort, health-content reviewer (Q-069)                                                                                                        | Owner               | S      |

## Should fix before release

| #   | ID             | Action                                                                                                                                                       | Owner                 | Effort |
| --- | -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------- | ------ |
| 8   | SEC-02         | App Check (App Attest / Play Integrity / reCAPTCHA) in monitor mode, then enforce; per-IP cap on `sendAuthEmail`                                             | Eng                   | M      |
| 9   | OPS-01         | PITR + daily exports; restore drill; alert policies (function errors, job failures, renderer queue, AI spend, budget); deploy / rollback / incident runbooks | Eng + Owner (billing) | M      |
| 10  | STORE-01       | Privacy labels, data-safety form, age rating, review notes, store copy and screenshots; validate the privacy manifest                                        | Owner + Eng           | M      |
| 11  | SEC-03         | Re-enable staff TOTP (Identity Platform is on) before staff touch prod families                                                                              | Owner decision        | S–M    |
| 12  | PRD-02 / QA-04 | Run S16 on the launch scope: the regression suite in [07](07-qa-test-coverage.md) on iOS + Android against staging-like config                               | Eng                   | L      |
| 13  | ANA-01         | Close the PA-05 privacy review, turn on `product_analytics` for the launch cohort, build the minimal dashboard ([02 §4](02-product-business.md))             | Owner + Eng           | S–M    |
| 14  | PRIV-01        | Diagnostics consent default off                                                                                                                              | Eng                   | S      |
| 15  | UX-02          | No upgrade CTAs while billing is absent; honest storage-full way out                                                                                         | Eng                   | S      |

## Can fix after release

| ID                                             | Action                                                                                           | Effort |
| ---------------------------------------------- | ------------------------------------------------------------------------------------------------ | ------ |
| DATA-01                                        | Count care / receipt photos toward quota or cap them; sweep orphans (validate first)             | M      |
| QA-03                                          | Tag golden comparisons in `print_studio_test.dart`                                               | S      |
| FN-02                                          | Surface refused offline writes after an app restart                                              | M      |
| PERF-01                                        | Low-end device performance pass; Firestore read and cost dashboard                               | M      |
| ARC-02                                         | Make every scheduler check its flag; don't deploy schedules of dark modules                      | M      |
| UX-03/04                                       | Navigation and discoverability check per launch flag set; VoiceOver / TalkBack / 200 % text pass | M      |
| PRD-03                                         | Align landing promises with the app (Q-008, Q-009, Q-039)                                        | S      |
| PRD-04                                         | Native review of English launch strings                                                          | M      |
| SEC-04, RULE-01, UX-06, REL-02, ARC-01, ARC-03 | Hygiene                                                                                          | S each |

## Future product opportunities (not required for launch)

- Monthly recap combining Care, Grow and Remember with per-item audience selection (identified in the 2026-10-20 audit).
- Widgets, Live Activity and Apple Watch once the Apple team exists (S8, Q-047).
- Premium with store billing, storage add-ons and family plan management, after the free launch proves retention.
- Durable cross-device media fingerprints for Tự lưu (2026-10-20 audit).
