# 08 — Production readiness

## Summary

| Area                          | State                                                                                                                                           |
| ----------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| Dev / prod isolation          | **Good design**: flavors, `resolveEnvironment`, separate projects, prod deploy needs `CHILD_LIFE_PROD_APPROVED=yes` (`scripts/deploy.sh:19-25`) |
| Prod environment              | **Not provisioned for the apps** (REL-01)                                                                                                       |
| Legal / privacy disclosures   | **Missing** (LEG-01, STORE-01)                                                                                                                  |
| Crash reporting               | Crashlytics + Performance wired; prod reports from release builds only (`bootstrap.dart:59-86`)                                                 |
| Backend observability         | Structured logs; deploy verification script (`scripts/verify-deploy.mjs`); dashboards and alerts not in repo (OPS-01)                           |
| Backup / restore              | **Not evidenced** (OPS-01)                                                                                                                      |
| Runbooks                      | Only `docs/operations/content-release.md`, `premium-rollout.md`, `docs/assistant/runbook.md`, `docs/notifications/08-operations.md`             |
| Feature flags / kill switches | 37 flags, default off, mirrored to `publicConfig` (good). **No prod launch matrix** (OPS-02)                                                    |
| Release versioning            | `1.0.0+1`; Android CI uses the run number; no release process document (REL-02)                                                                 |
| CI                            | Not run on the release branch (QA-01, [07](07-qa-test-coverage.md))                                                                             |

## Findings

### REL-01 · P0 · Production cannot start: prod is not provisioned for the apps

- **Evidence:**
  - Mobile prod options are missing: `firebaseOptionsFor(prod)` returns `null` (`apps/mobile/lib/app/firebase_options.dart:7-8, 34-35`), so a prod build "stops at startup".
  - There is no `android/app/src/prod/google-services.json` (`build.gradle.kts:46-48`) and no `ios/config/prod` (only `ios/config/dev`).
  - The dev iOS app uses a borrowed bundle id `dev.hsba.app` on an interim Apple team (`environment.dart:7-10`, D-045). The prod `app.childlife` needs the Child Life Apple developer account. S8 widgets / Live Activity and universal links (AASA) wait on that same team (implementation-plan §S8, S13 report).
  - `.firebaserc` maps prod → `child-life-ecosystem` with only a `landing` hosting target. There are no `admin` or `player` targets for prod.
- **Also required:** prod `config/flags`, `config/limits`, `publicConfig/*`, reference tables and content (seed scripts refuse prod by design). Prod secrets: OpenAI, Resend, and APNs keys for prod. Domain DNS for `childlife.app`, and `assetlinks.json` / AASA with the prod fingerprints (`src/prod/AndroidManifest.xml` comment).
- **Impact:** no prod build can run, so there is nothing to release.
- **Fix:** owner provisions prod (D-005). Then run the S16 checklist: add options and config files, deploy Rules and indexes, deploy Functions, seed config, register store apps, set up signing, and prove a smoke test on prod with a staff-only family.
- Effort L (owner-dependent) · Confidence High · **Confirmed by code inspection**.

### LEG-01 · P0 · No privacy policy or terms; consent for child data is undecided {#leg-01}

- **Evidence:** both legal pages say "Đang hoàn thiện" ("being finalised") with a placeholder sentence
  (`apps/landing/src/pages/Legal.tsx:3`, `apps/landing/src/content/vi.ts:1407-1424`). Sign-in has a link only
  and no consent step (R-013). These questions are open: **Q-020** (explicit consent for child data under Decree 13/2023 and the PDPL; data
  residency in Singapore), **Q-055** (lawyer review of face-analysis consent under Law 91/2025 before
  any external beta user), **Q-070** (consent and retention for sending care data to OpenAI)
  (`docs/product/business-map.md:911, 946, 961`).
- **Impact:** App Store and Google Play require a privacy policy URL. Processing children's, biometric (Tự lưu
  face matching) and cross-border AI data without an approved legal basis and consent is a regulatory
  and trust risk for the core promise ("private family space").
- **Fix:** lawyer-approved privacy policy and terms (vi + en). Add a consent step where the law requires one (child
  data; face matching; AI). Record the consent version per account. Restrict AI features until Q-070 is closed.
- Effort M (legal) + S–M (engineering) · Confidence High · **Documentation gap (confirmed)**.

### STORE-01 · P1 · Store disclosures and listing not prepared

- No app-level `PrivacyInfo.xcprivacy` under `apps/mobile/ios` outside `Pods` (searched with `find`). Flutter
  plugins ship their own manifests. Whether the Runner target needs one (required-reason APIs such as
  `UserDefaults` / file timestamps used by app code or native extensions: share, widget, watch) is
  **Suspected — validate with Xcode's privacy report**.
- No App Store privacy labels, Play data-safety answers, age rating rationale, review notes for
  sign-in (Apple / anonymous join), screenshots or store copy were found in the repo.
- The landing has no store links yet (S14 report: "waiting on owner items … store links, legal text").
- Effort M · Confidence Medium · **Documentation gap**.

### OPS-01 · P1 · No backup, restore or incident readiness for production

- The plan promises runbooks for "deploy, rollback / roll-forward, incident, retries & dead letters, quota
  reconciliation, restore (Firestore PITR + scheduled exports to a locked bucket), key rotation"
  (`implementation-plan.md:169`). `docs/operations/` holds only `content-release.md` and
  `premium-rollout.md`. No Firestore PITR or scheduled-export configuration, Cloud Monitoring alert policy
  or budget alert is codified in the repo.
- **Impact:** a bad deploy or accidental mass delete of family memories cannot be rolled back with
  confidence, and failures are only noticed when users report them.
- **Fix:** turn on PITR and daily exports for prod. Write and drill the restore runbook. Add alert policies:
  function error rate, deletion or export job failures, renderer queue age, AI spend, Storage growth,
  and a billing budget alert. Codify them as scripts or Terraform.
- Effort M · Confidence High for absence in the repo · **Documentation gap**. Infrastructure outside the repo
  was not inspected.

### OPS-02 · P1 · Launch configuration is undefined

- All 37 flags default to **off**, including core `media_upload`, `video_upload`, `invites` and
  `story_share_link` (`packages/contracts/src/config.ts:97-134`). Flags such as `premium_v2`, `assistant*`, `auto_save`,
  `adaptive_*`, `personalization` and `ai_assist` are `internal`.
- No document says which flags are on for the first public users, the rollout percentages, or the
  matching `config/limits`. The answer decides storage (10 GB legacy vs 1 GB Free under `premium_v2`), AI
  exposure and which UI ships.
- **Fix:** a launch flag matrix with an owner sign-off, seeded and checked in prod by script, plus a
  "flags drift" check in the portal.
- Effort S · Confidence High · **Confirmed by code inspection**.

### REL-02 · P3 · Release versioning and process

- `version: 1.0.0+1` (`apps/mobile/pubspec.yaml:19`). There is no changelog or release checklist file. The force-update
  mechanism exists (`app_update`, UP1 test) and is a good safety net.
- Effort S · **Documentation gap**.

## Rollback strategy (as it exists)

- **Backend:** redeploy a previous commit with `scripts/deploy.sh` (no tagged releases), plus the kill switches in
  `config/flags`. Rules deploys are global per project and come from the working tree. Several sessions share one tree
  here, so a deploy can carry another session's uncommitted edits. Production needs deploys from a
  tagged, clean commit.
- **Mobile:** forced update (`app_update`) and flags; store rollback is not possible.
