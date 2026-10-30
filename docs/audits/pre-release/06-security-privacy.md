# 06 — Security & privacy audit

Scope: Firestore Rules (`firebase/firestore.rules`, 1,861 lines, every `match` path listed and helpers
read), Storage Rules (`firebase/storage.rules`, read in full), Functions entry points
(`firebase/functions/src/index.ts`: callable wrappers and all 5 `onRequest` handlers), invite and share
rate limiting, auth email, secrets, logging, deletion, consent screens. No penetration test or live
request was made against dev or prod.

## What is solid (verified)

- **Deny-by-default Rules** with a final `match /{document=**} { allow read, write: if false; }`
  (`firestore.rules:1857-1858`) and `match /{allPaths=**}` in Storage (`storage.rules:238-240`).
- **Care writes are schema-checked**: key allowlists, ranges, no future times, author must equal the
  writer's own membership (`firestore.rules:988-1010`). D-022 edit rights (`canEditRecord`,
  `:927-929`). Soft delete and restore only (`:1055-1074`).
- **Role and expiry checked on every read** (`activeMember` / `isActive`, `:18-26`); access end dates
  deny at once (R-024).
- **Writes lock while a baby is being deleted** (`babyOpen`, `:32-35`), and seat-suspended writers are
  view-only (`writeSuspended`, `:39-42`).
- **Media reads follow the audience** in both Firestore and Storage; caregivers never read Memories
  (`storage.rules:46-58`).
- **Server-only collections** for billing, grants, quota, assistant executions, notifications ledger,
  analytics (`firestore.rules:287-294, 351-355, 375-387`).
- **Secrets** come from Secret Manager (`OPENAI_API_KEY`, `RESEND_API_KEY`); the only committed keys are
  Firebase client config, allow-listed in `.gitleaks.toml`. No `.env`, keystore or service-account file
  is tracked (checked with `git ls-files`).
- **Deletion** is a resumable job: it waits for render and print leases, purges Storage, recursively deletes
  every baby subcollection, removes linked collection-group documents, analytics, notification ledger
  and assistant data, then verifies (`firebase/functions/src/account.ts:525-600`).
- **Auth email** is limited per address and kind (1/min, 5/day; `auth-mail.ts:80-98`) and does not
  reveal whether an account exists (`linkFor` returns null).
- **Telemetry**: Crashlytics keys are environment and app version only (`apps/mobile/lib/app/bootstrap.dart:59-67`);
  a quick grep of `logger.*` calls found no nickname, caption, email or DOB fields.

## Findings

### SEC-01 · P0 · A 6-digit invite code alone joins a baby, and the brute-force limit can be bypassed

|                        |                                                                                                                                                                                                                                                                                                                                                                                         |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Category               | Security — unauthorized access to child data                                                                                                                                                                                                                                                                                                                                            |
| Description            | `previewInvite` / `acceptInvite` accept `{ code: /^\d{6}$/ }` (`packages/contracts/src/family.ts:45, 110-113`). A valid unexpired code maps straight to the invite (`firebase/functions/src/family.ts:389-410`). The only brute-force control is P-021 lockout: 10 failures in 15 min per **uid** and per **IP** (`family.ts:523-566`, `contracts/family.ts:37-39`).                    |
| Why it can be bypassed | (1) The IP is the **first** `X-Forwarded-For` entry (`index.ts:631-635`). Google's front end appends the real client address, so the first entry is whatever the client sent. (2) `previewInvite` works signed out (`uid` null → IP key only). (3) Temporary identities make new uids cheap. (4) IPv6 hosts can rotate addresses. There is no global limiter and no App Check (SEC-02). |
| Impact                 | With K live invites (TTL 7 days, `inviteTtlDays = 7`), a random code hits with probability K/10⁶. Joining gives the role the inviter chose: relative (shared photos), caregiver (care data) or co-parent (everything about the child). The family gets a "member joined" notice and can remove the person, but by then the child's photos and data have been exposed.                   |
| Expected               | A code alone must not be guessable at scale: a client IP that cannot be spoofed, a global failure budget, and preferably proof of possession (link token) or approval by the inviter for code joins.                                                                                                                                                                                    |
| Evidence               | `index.ts:631-635`, `family.ts:523-566`, `family.ts:389-410`, `contracts/family.ts:34-45`. The share-link passcode uses the same derivation: `clientAddress` takes the first XFF entry (`index.ts:2088-2091`), and attempts are keyed on it (`links.ts:427-461`).                                                                                                                       |
| Reproduction           | Not executed (no requests sent to dev). On a deployed callable, send `previewInvite` with a different `X-Forwarded-For` value on each call and check that `locked` never appears.                                                                                                                                                                                                       |
| Recommended fix        | Take the client address from the right-hand end, or use Cloud Run's trusted hop. Add a global failure counter per hour that triggers a cooldown and an alert. Require a signed-in identity for `previewInvite` by code. Enforce App Check. Consider "inviter approves code joins for coParent/caregiver roles".                                                                         |
| Effort / Confidence    | S–M / **Medium**: the mechanism is confirmed; how spoofable XFF is behind Firebase Hosting and the callable front end still needs one live check.                                                                                                                                                                                                                                       |
| Verification           | Confirmed by code inspection; exploitability **Suspected — requires validation**.                                                                                                                                                                                                                                                                                                       |

### SEC-02 · P1 · App Check is not implemented anywhere

- **Expected:** "App Check: Play Integrity / App Attest … reCAPTCHA Enterprise for web; enforced on
  callables and Firestore/Storage after rollout monitoring" (`docs/development/implementation-plan.md:102`).
- **Actual:** there is no `firebase_app_check` dependency (`apps/mobile/pubspec.yaml`), no `enforceAppCheck` or
  `consumeAppCheckToken` in `firebase/functions/src`, and no App Check in the portal or landing (grep found no matches).
- **Impact:** scripted clients can call AI callables (cost; per-user credits limit only signed-in
  accounts, and temporary accounts are cheap) and `sendAuthEmail` (limited per address, not per caller →
  mail cost and sender-domain reputation). They can also hit invite lookup (SEC-01) and share pages.
- **Fix:** add App Check to mobile (App Attest / Play Integrity) and web. Run it in monitor mode for one release,
  then enforce on callables, Firestore and Storage. Add a per-IP or global cap on `sendAuthEmail`.
- Effort M · Confidence High · **Confirmed by code inspection**.

### SEC-03 · P1 · Staff portal has no second factor

- D-043 / D-053 (owner) dropped TOTP. Staff accounts are email and password only (D-008) and can open the family
  directory, change grants, ownership transfers and data jobs (`docs/development/slice-reports/S15b.md`).
- **Risk:** one phished staff password exposes many families. This is an owner-accepted decision for dev. For a
  production launch with real child data it should be revisited: Identity Platform is already on (D-014), so
  TOTP is available.
- Effort S–M · Confidence High · **Documentation gap (owner decision)**.

### PRIV-01 · P2 · "Send diagnostics" is pre-ticked on the help form

- `apps/mobile/lib/features/me/help_screen.dart:92` `var _diagnostics = true;`. Business map §3
  (`DiagnosticsSnapshot`): "Sent only with user consent". Under Decree 13/2023 and the PDPL, consent
  must be an affirmative act. A pre-ticked box is weak evidence of consent.
- **Fix:** default `false`, or show what is sent and ask. Effort S · Confidence High · **Confirmed by code inspection**.

### PRIV-02 · P0 (merged into LEG-01) · Child-data consent and AI cross-border processing

See [08 · LEG-01](08-production-readiness.md#leg-01). Q-020 (consent, privacy policy, residency), Q-055
(lawyer review, Law 91/2025: children's and biometric data, face matching in Tự lưu) and Q-070 (AI consent and
retention for OpenAI) are all open in `docs/product/business-map.md` §13.

### DATA-01 · P2 · Care photos bypass the family storage quota

- Vaccine, meal, recipe and receipt JPEGs (≤ 4 MB each) are created directly by any Cùng nuôi or caregiver
  (receipts: anyone with spending rights). The rule only checks name, type and size; there is no reservation
  and no count limit (`storage.rules:60-118`). The files are not tied to a document at create time, so a
  failed Firestore write leaves an orphan unless a sweep removes it.
- **Impact:** storage cost abuse by one member; family usage figures under-count. **Suspected — requires
  validation** of whether a sweeper or usage job counts these prefixes (only "30-day bin job" for purged
  meals and recipes is mentioned in the comments). Effort M · Confidence Medium.

### SEC-04 · P3 · Error logs stringify whole errors

- `logger.error(\`${name} failed\`, { error: String(error) })` in several wrappers (`index.ts:1020, 1462,
  1709, 1994, 2172, 2861`). Firestore errors carry document paths (ids, not names). Validation errors may
carry input fragments. One wrapper (`:3011`) already logs only `error.name`.
- **Fix:** log `error.name` + code, as at `:3011`. Effort S · Confidence Low · **Suspected**.

### RULE-01 · P3 · A few deletes skip the "baby is being deleted" lock

- `timers` delete (`firestore.rules:643`), `vaccines` delete (`:460`), `checkins` and `recFeedback`
  delete (`:580, :589`) do not call `babyOpen`. Writes during deletion are harmless because the purge
  follows, but this is inconsistent with the rule stated at `:31`. Effort S · **Confirmed by code inspection**.

## Account isolation and the earlier P0s

The 2026-10-20 audit's privacy P0 **FAM-01** (local data not scoped per account) is addressed in code by
`AccountLocalScope`. It gives each UID its own provider container for queue, media cache, auto-save
store and purchase drafts (`apps/mobile/lib/app/account_local_scope.dart:21-60`;
`docs/product-audit/11-implementation-report.md:9`). **Verification:** confirmed by code inspection only. No
device test switching accounts was run in this audit.

## Not verified

- Live behaviour of `X-Forwarded-For` behind Firebase Hosting and the callable front end (SEC-01).
- Prod IAM, Secret Manager access lists and API-key restrictions (no prod project exists).
- Dependency vulnerability audit (`pnpm audit`, `flutter pub outdated --mode=security`) was not run, to avoid
  network-dependent results. Recommended in [07](07-qa-test-coverage.md).
