# 07 — QA & test coverage

All runs on 2026-10-29, macOS, Flutter 3.44.8 (`.flutter-version`), Node 22, Java 21. They ran against the
working tree at `ebcdcf49`, which became `8e53ea55` during the run because another session committed. The
failing Flutter files were re-run on `8e53ea55` with the same result. Emulator suites used an isolated
config (Firestore 8180, Storage 9399, UI off) because another session's emulators held the default ports.

## Executed checks

| Check                                                                             | Result                                               | Notes                                                                                                                                                                              |
| --------------------------------------------------------------------------------- | ---------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `flutter analyze`                                                                 | **Pass** — no issues                                 |                                                                                                                                                                                    |
| `flutter test --exclude-tags golden`                                              | **Fail** — 2,895 passed, **9 failed**                | Re-run of the 6 failing files: same 9 failures (deterministic). Details in [03](03-functional-bugs.md)                                                                             |
| `pnpm --filter contracts --filter web-config build`                               | Pass                                                 |                                                                                                                                                                                    |
| `pnpm typecheck`                                                                  | **Pass**                                             |                                                                                                                                                                                    |
| `pnpm lint`                                                                       | **Fail** — 52 errors (38 `no-undef`, 14 unused vars) | Includes tracked files: `apps/launch-film/**`, `apps/portal/test/design-review/*.mjs`, `scripts/verify-deploy.mjs:37`. Others are local `.claude/worktrees` copies                 |
| `pnpm format:check`                                                               | **Fail** — 2,533 files                               | 2,245 under local `.claude/worktrees` (not in `.prettierignore`). About 290 elsewhere (`docs/design` 63, `.claude/skills` 49, `apps/renderer` 31, `apps/launch-film` 27 …)         |
| `pnpm test` (as CI runs it)                                                       | **Fail** at `apps/renderer` — 12 of 37 failed        | `PERMISSION_DENIED … demo-child-life`: the test needs the Firestore emulator; `pnpm test` stops at the first failure, so later packages did not run                                |
| `apps/renderer` tests **with** emulator                                           | **Pass** — 37/37                                     | Includes MEM-01 / CON-01 fencing tests                                                                                                                                             |
| contracts / web-config / functions / landing / portal tests                       | **Pass** — 925 / 8 / 510 (+1 skip) / 30 / 729        | Functions, landing and portal re-run with `--no-bail`                                                                                                                              |
| Rules + Functions integration (`firebase/tests`, emulators)                       | **Pass** — 97 files, **1,175 tests**                 |                                                                                                                                                                                    |
| Golden suite (`--tags golden`), device E2E (`integration_test/`), `assistant-e2e` | **Not run**                                          | Goldens are the visual baseline (D-111). Integration tests need a device or simulator and dev Firebase. Not needed for this audit's findings, but required for release (see below) |
| Dependency vulnerability audit                                                    | **Not run**                                          | Recommended: `pnpm audit --prod`, `flutter pub outdated`, OSV scan                                                                                                                 |

**Inventory:** 196 Flutter test files, 2,200 golden PNGs, 10 device integration flows
(`apps/mobile/integration_test/`: onboarding, care, invite, link, me, memory, reminder, background upload, print
smoke), 97 emulator test files, assistant replay and E2E harnesses. Coverage is broad. The weakness is
not missing tests but **tests that are red and not run on the release branch**.

## Findings

### QA-01 · P1 · No green build exists for the release candidate

- **Evidence:**
  - Lint fails on tracked files.
  - Format check fails on about 290 tracked files.
  - 9 Flutter tests fail.
  - `pnpm test` fails because the renderer needs an emulator, and CI runs `pnpm test` before starting any emulator (`.github/workflows/ci.yml` web-and-backend job).
  - CI triggers only on pull requests and pushes to `main` (`ci.yml:3-6`). Work happens on `s2-onboarding`, which is **12 commits ahead of `origin/s2-onboarding`**, while `origin/main` points at `6e3b8d7a` (D-102, several weeks of work behind).
- **Impact:** regressions such as QA-02 reach dev without a gate. Nobody can point to a reproducible, tested
  release commit.
- **Fix:**
  1. Run CI on the working branch.
  2. Move renderer tests under `emulators:exec`, or exclude them from `pnpm test`.
  3. Add `.claude/` and `apps/launch-film` to the lint and format ignores, or fix them.
  4. Fix or triage the 9 Flutter failures.
  5. Cut a release branch or tag only from a green run.
- Effort S–M · Confidence High · **Confirmed by executed test**.

### QA-03 · P2 · Golden comparisons inside untagged tests

- `print_studio_test.dart` compares against `goldens/print/*.png` without the `golden` tag. The non-golden suite
  (Linux in CI) therefore runs pixel checks that are meant for macOS. Four of the nine failures are these.
- **Fix:** tag them `golden`, or split the pixel assertions out. Effort S · **Confirmed by executed test**.

### QA-04 · P2 · Critical journeys have no automated proof on real backends

- The integration flows exist, but there is no record of them passing against dev Firebase on both platforms for the
  release candidate. The Figma checklist ticks a row only after that, and **0 of 155 screens are ticked**
  (`docs/product/figma-coverage-checklist.md:15-23`).
- **Fix:** add a release-candidate E2E run (iOS + Android, dev Firebase) for the regression suite below, with
  the results attached to the release.
- Effort M · **Documentation gap**.

## Recommended release regression suite

Run on iOS and Android, Light and Night care, vi and en, against a staging copy of prod config.

1. **Onboarding:** each provider (Apple, Google, email); unverified email (D-015); temporary-identity join then "Lưu tài khoản" into an existing account (AU-1 merge, network drop mid-claim).
2. **Invites:** link, QR, code and email; expired, revoked or used invite; seats full; wrong-code lockout; access end date passes while signed in.
3. **Care:** quick log online and offline. Edit, delete, undo, restore. Two devices end the same timer. Sleep overlap resolution. Role change while offline (FN-02). Today while loading or failed (SY-1).
4. **Day boundary:** baby time zone ≠ device time zone; midnight-crossing sleep (D-027); DST-free zones plus one DST zone.
5. **Memories:** upload photo and video near the quota and over it (D-126 / D-127); background upload killed mid-way; audience change from album (D-002); relative sees only "Gia đình".
6. **Deletion:** delete a baby during an active render or print lease; delete an account with unsent offline writes; export download after the right is lost.
7. **Notifications:** push tap → correct destination for each type (reminders, care plan N1/N4/N5, handover, new memories). Notifications off. Reminder on another device (D-029).
8. **Flags:** each launch flag off then on at runtime (kill switch shows the A11 notice; nothing crashes).
9. **Premium (if enabled):** Free limits, paywall without billing, seat picker after downgrade.
10. **Security:** Rules suite (already green). An SEC-01 check that the lockout survives XFF changes. App Check enforcement once added.
