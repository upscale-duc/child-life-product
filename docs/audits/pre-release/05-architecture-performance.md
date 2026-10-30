# 05 — Architecture & performance audit

## Architecture (verified)

| Aspect            | Assessment                                                                                                                                                                                                |
| ----------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Monorepo          | pnpm workspace; shared **Zod contracts** (`packages/contracts`, 60+ modules, 925 tests) used by Functions, portal and landing. One source for shapes, limits and flags. Strong.                           |
| Mobile            | Flutter + Riverpod, feature folders, GoRouter with a central guard (`app/route_guard.dart`), per-account provider scope (`app/account_local_scope.dart`).                                                 |
| Backend           | Firebase: Firestore (client writes only where Rules validate a full schema), Functions v2 in asia-southeast1, scheduled sweepers, a Cloud Run renderer for keepsake videos (Remotion) with lease fencing. |
| Environments      | Hard refusal of mixed config at startup (`resolveEnvironment`) and in deploy scripts. Strong.                                                                                                             |
| Error propagation | Callable wrappers map domain errors to `HttpsError` with a `reason`. The client maps reasons to copy (D-127).                                                                                             |
| Offline           | Firestore persistence + outbox (`CareOutbox`) + refusal toasts. Restart gap noted (FN-02).                                                                                                                |

## Findings

### ARC-01 · P3 · Very large single files raise change risk

| File                                                        | Lines |
| ----------------------------------------------------------- | ----- |
| `firebase/functions/src/index.ts` (all exports)             | 3,595 |
| `firebase/firestore.rules`                                  | 1,861 |
| `apps/mobile/lib/features/assistant/assistant_screens.dart` | 4,801 |
| `apps/mobile/lib/features/care/history_screen.dart`         | 2,947 |
| `apps/mobile/lib/features/premium/paywall_v2.dart`          | 2,493 |

Several sessions edit the same files in parallel on one branch, so merge collisions and accidental
cross-session deploys are an observed risk (see the rollback section of [08](08-production-readiness.md)). **No rewrite is recommended
before launch.** After launch, split `index.ts` exports by domain (the logic already lives in
domain modules). Effort M · **Confirmed by inspection**.

### ARC-02 · P2 · Breadth multiplies the surface to secure and operate

About 120 Functions modules: 13 HTTP endpoints, 38 schedules, about 45 triggers, plus callables. 37 flags; 92 `match` blocks in
Rules. Each module adds scheduled cost, a failure mode and Rules surface even when its flag is off: schedules and
triggers still deploy. **Fix:** for launch, consider not deploying the schedules of modules whose
flags stay off, or make each scheduler check its flag first (many already do; not audited one by one).
**Suspected — requires validation** per scheduler. Effort M.

### ARC-03 · P3 · Tooling hygiene

ESLint and Prettier scan local `.claude/worktrees` copies (2,245 format warnings, many lint errors). The renderer
test needs an emulator but sits in the plain `pnpm test` (QA-01). Effort S.

## Performance

**Nothing was measured in this audit.** No device profiling, API latency or load test was run.
Evidence that exists:

- Firebase Performance is enabled (`bootstrap.dart:86`). Commit `79ee4e03` fixed iOS swipe-back jank and
  Crashlytics main-thread stalls.
- `docs/assistant/latency-2026-10-19.md` measured assistant latency (not re-run).

### PERF-01 · P2 · Potential risks to measure before launch (not confirmed problems)

| Risk                                     | Why it may matter                                                                                                                                                                             |
| ---------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Listener count on Today                  | 78 `.snapshots()` sites in `lib`. Adaptive Today composes many sections, each may hold a live listener. Watch reads per active family per day (cost) and first-frame time on low-end Android. |
| History and stats on long-lived families | The plan's acceptance "1k-row history scrolls within frame budget" (`implementation-plan.md:291`) has no recorded result.                                                                     |
| Cold start                               | `bootstrap()` awaits Firebase init, Crashlytics setup, `didCrashOnPreviousExecution` and Performance before the first frame (`bootstrap.dart:44-89`).                                         |
| Scheduled jobs at scale                  | 38 schedules. Per-family sweeps (engagement, care plan morning, reminders) scale linearly with families.                                                                                      |
| AI cost                                  | Per-family credits exist. Real token telemetry was added after LUM-01. No budget alert is codified (OPS-01).                                                                                  |

**Fix:** a short performance pass on a low-end Android device and an older iPhone covering cold start, Today first
frame, history with 1k rows, and memory scroll with 5k media. Add read and cost dashboards. Effort M.
