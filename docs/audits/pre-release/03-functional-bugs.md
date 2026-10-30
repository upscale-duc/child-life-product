# 03 — Functional & bug audit

Method: module-by-module code reading of the riskiest paths (care writes and offline, timers, invites,
deletion, upload and quota, auth merge), the full automated suites ([07](07-qa-test-coverage.md)), and
re-checks of the defects found by the 2026-10-20 product audit and the 2026-10-26 flow-error audit. No
device or dev-Firebase runtime test was performed. Runtime claims below come only from executed tests.

## Findings

### QA-02 · P1 · Today's "loading ≠ empty" guard fails after the D-137 Today change

|                |                                                                                                                                                                                                                                                                                       |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Module         | Today / care                                                                                                                                                                                                                                                                          |
| Expected       | While records load, Today shows skeletons labelled "Đang tải nhịp hôm nay" (`axTilesLoading`) and never "Chưa có…" (D-127 standing rule: "unknown is never shown as empty"). This prevents duplicate feeds when the network is slow (flow-error audit 2026-10-26 §1).                 |
| Actual         | `test/features/care_flow_errors_test.dart:23-35` (SY-1 loading) fails on HEAD `8e53ea55`: no widget has the semantics label `axTilesLoading`. The test's "no 'Chưa có'" assertions run before that line and pass. `today_screen.dart` last changed in `78212ad1` (2026-10-29, D-137). |
| Impact         | If the skeleton is gone, a parent may see an empty-looking Today on a slow start and log a feed twice. If only the label moved, accessibility users lose the loading announcement. Either way the guard no longer protects the rule.                                                  |
| Reproduction   | `cd apps/mobile && flutter test test/features/care_flow_errors_test.dart`                                                                                                                                                                                                             |
| Fix            | Triage: restore the labelled skeleton on Today's care tiles, or update the test to the new structure while keeping the rule.                                                                                                                                                          |
| Effort / Conf. | S / High that the test fails; Medium on user impact                                                                                                                                                                                                                                   |
| Verification   | **Confirmed by executed test** (twice, deterministic)                                                                                                                                                                                                                                 |

### FN-01 · P2 · Eight more deterministic test failures hide behaviour regressions

All of these fail on two consecutive runs on HEAD (see [07](07-qa-test-coverage.md) for the list):

| Test                                                                                | Failure                                                        | Likely meaning (needs triage)                                                           |
| ----------------------------------------------------------------------------------- | -------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| `history_test.dart` "Today 'Lịch sử' opens History"                                 | `Bad state: No element` at `history_test.dart:38`              | The "Lịch sử" entry point on Today is missing or moved: a navigation path may be lost   |
| `premium_test.dart` MO02 beta family                                                | text "Dùng mẫu miễn phí" not found                             | D-127 Q6 canonical term not shown in subscribers mode                                   |
| `print_studio_test.dart` ×4                                                         | golden pixel mismatch (`goldens/print/current_options.png`, …) | Print UI changed without baseline update, or a regression; see QA-03                    |
| `solids_screens_test.dart` 5h quick log; `me_test.dart` 13a/13g/13h storage by role | "A Timer is still pending after the widget tree was disposed"  | A widget starts a timer that outlives it (possible leak) or a test that does not settle |

Verification: **Confirmed by executed test**. User impact **Suspected**. Effort S each.

### FN-02 · P3 · Refused offline writes from a previous app session are not reported

- `CareOutbox` counts refused writes "since the app started" and restarts at 0 (`apps/mobile/lib/features/care/care_repository.dart:276-305`).
  Firestore keeps queued writes across restarts. If the server refuses them after a restart (for example, the role changed
  while offline), the per-write toast never appears, because the write future belonged to the
  previous process. The code comment acknowledges this.
- **Impact:** a caregiver whose access ended offline may believe the logs were saved. Rare.
- **Fix:** after start, compare pending local records with the server, or surface "N ghi chép không lưu được".
- Effort M · Confidence Medium · **Confirmed by code inspection**; impact **Suspected**.

### Earlier defects re-checked (code inspection only)

| Earlier finding                                                             | Status now                                                                                                                                        |
| --------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| FAM-01 local data not scoped per account (P0, 2026-10-20)                   | Fixed in code: `AccountLocalScope` (`app/account_local_scope.dart:21-60`)                                                                         |
| MEM-01 stale render worker overwrites bytes (P0)                            | Fixed per report; renderer fencing tests exist (`apps/renderer/test/job.test.ts`), but **could not be executed** here without an emulator (QA-01) |
| CON-01 render filed while baby deleting (P0)                                | Fixed: deletion waits for leases and releases reservations (`firebase/functions/src/account.ts:530-566`)                                          |
| AU-1 temporary-account merge could lose babies on network drop (2026-10-26) | Fixed: claim runs in a second Firebase app before switching (`features/auth/auth_repository.dart:357-388`)                                        |
| D-127 flow rules (unknown ≠ empty, seats, storage arithmetic)               | Implemented in `07d794d2`; **SY-1 and MO02 guards now fail** (QA-02, FN-01)                                                                       |

## Module notes (no defect found in the parts read)

- **Care writes:** the record id comes from the timer session, so two phones ending the same timer cannot create
  duplicates (`care_repository.dart:225-241`). Refused writes name the record and say when the
  reason is a permission change (`care_format.dart:150-177`).
- **Invites:** codes are unique among live invites (`family.ts:244-253`); seat checks before join
  (D-127 Q3). Security issue in [06 · SEC-01](06-security-privacy.md).
- **Deletion:** steps are resumable and verified; see [06](06-security-privacy.md).
- **Billing:** a client's "success" never grants. Grants come only from provider status fetched by the server
  (`firebase/functions/src/billing.ts:27-44`). There is no adapter yet (COM-01 in [02](02-product-business.md)).

## Not covered at runtime

Timezone and day-boundary behaviour, background upload, push and deep-link destinations, widgets, Live
Activity and multi-device concurrency were **not** exercised on devices or dev Firebase in this audit.
They are listed in the regression suite in [07](07-qa-test-coverage.md).
