# Child Life V1 — Implementation Plan

|        |                                                                                                                                                                                                      |
| ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Status | Plan only. No product code exists yet. No dates are committed; estimates follow the spikes (brief §07).                                                                                              |
| Scope  | Entire final Figma (see [business map](../product/business-map.md) §1). Phases change **order**, never scope.                                                                                        |
| Inputs | Business map, [Figma coverage checklist](../product/figma-coverage-checklist.md), Figma extraction notes in [`../discovery/figma-extract/`](../discovery/figma-extract/), engineering brief rev 2.0. |
| Tags   | R-/P-/Q-/G- ids refer to the business map. SP-n = feasibility spike. S-n = delivery slice.                                                                                                           |

---

## 1. Ground rules

1. **Runnable end-to-end slices.** Each slice ships UI + backend + Rules + native work + tests + monitoring + docs for its Figma scope and runs against the **dev** Firebase project on real iOS and Android devices. A slice is not "done" if any part is mocked.
2. **No fake completion.** Feature flags may stage rollout but a flagged-off or mock-backed feature is reported as _not delivered_. Any Figma node not working end-to-end stays open in the coverage checklist and in the gap report.
3. **Design system before screens.** Tokens and components come from Figma; screens compose them. Golden tests compare against Figma screenshots.
4. **Server decides.** Membership, roles, audience, quota, sharing, deletion and anything sensitive are enforced by Rules and Functions; client checks are UX only.
5. **Idempotent everything.** Client-generated ids / `opId` on every command; workers safe to retry; one notification per logical event.
6. **Dev first.** Owner approval is required for billing, production IAM, production deploys and store publication. Missing credentials are reported as blockers, never worked around.
7. **Report per slice:** what changed, tests actually run (with output), measurements, evidence (screens / recordings / URLs), blockers, next steps. Never "production-ready" from scaffolding.

---

## 2. Starting point (observed 2026-10-10)

| Item                          | State                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Repository                    | `child-life-product`, branch `main`, **no commits**, no remote. Only these docs.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| Flutter                       | 3.44.8 / Dart 3.12.2 installed but on a non-release channel (`[user-branch]`). → Pin a current **stable** SDK per repo with FVM at bootstrap; re-check FlutterFire compatibility then.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| Node / pnpm                   | Node 22.22, pnpm 11.20 — fine for Functions (Node 22 runtime) and web.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| Firebase CLI / gcloud         | firebase-tools 15.15, gcloud 572, signed in with a work account. Dev project **`child-life-dev`** (number 759703503909) is visible to the CLI; it has **no default resource location yet** (Firestore / Storage not created). gcloud needs re-authentication (`gcloud auth login`) before CLI provisioning. No prod project yet.                                                                                                                                                                                                                                                                                                                                                                                 |
| Dev provisioning (2026-10-10) | `child-life-dev`: Blaze billing on; APIs enabled (Firestore, Firebase Storage, Functions, Run, Build, Artifact Registry, Eventarc, Tasks, Scheduler, Secret Manager, App Check, Extensions, IAM Credentials); **Firestore `(default)` Native in asia-southeast1** (PITR off in dev); **default bucket `child-life-dev.firebasestorage.app` in ASIA-SOUTHEAST1**, public access prevention enforced; apps registered: iOS + Android `app.childlife.dev`, web "Child Life Dev Landing" and "Child Life Dev Admin"; Hosting sites `child-life-dev-landing`, `child-life-dev-admin`. **No Rules released yet** (clients denied by default) — S0 deploys explicit deny-all Rules. Custom domains not connected (DNS). |
| Xcode / CocoaPods / Java      | Xcode 26.6, CocoaPods 1.16.2, OpenJDK 21.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| Figma MCP                     | Works read-only; Pro/Full-seat **per-minute rate limit** — batch reads, back off ~90 s. Extraction already saved to the repo so slices rarely need to re-read.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |

**Blockers before Slice 0 can deploy (owner action):**

1. **Dev:** `child-life-dev` exists (2026-10-10). Blaze plan enabled and location confirmed (D-009). **Prod:** project to be created later by the owner (proposed id `child-life-prod`, D-005); prod work stays blocked until then.
2. Region **asia-southeast1 (Singapore)** confirmed by the owner (D-009); Blaze plan enabled on `child-life-dev`. Legal review of residency (Q-020) still pending before prod.
3. **Apple Developer** team (bundle IDs, APNs auth key, Sign in with Apple service, App Groups, Associated Domains), **Google Play Console**, Google OAuth consent screen.
4. Domain **childlife.app** confirmed by the owner. Needed: DNS access to add Firebase Hosting records for the hosts in §3.7 and SPF / DKIM / DMARC for `childlife.app` (prod mail) and `dev.childlife.app` (dev mail).
5. Transactional email provider choice for invite emails (Auth emails use Firebase templates).
6. **OpenAI API** organization, billing and separate API keys for dev and prod (D-003); confirmation of data-use / retention settings (zero data retention if eligible).

---

## 3. Architecture

### 3.1 Repository layout (modular monorepo)

```
apps/
  mobile/                 Flutter app (iOS + Android), flavors dev | prod
    lib/
      app/                bootstrap, env resolver, router, theme, DI
      core/               design system (tokens, components), motion, l10n, utils
      features/<feature>/ presentation/ application/ data/ domain/
    ios/                  Runner + WidgetExtension + LiveActivity + ShareExtension + NotificationService
    android/              app + Glance widgets + share target + timer notification service
  landing/                React + TS + Vite — marketing site + recipient web (/s/*) + invite landing (/i/*)
  portal/                 React + TS + Vite — staff console "Child Life · Vận hành" (Figma Admin portal A01–A12)
packages/
  contracts/              JSON Schemas (zod) shared by Functions & web; generated Dart models for mobile
  care-calc/              pure TypeScript + Dart mirror of stats rules, shared golden test vectors
  web-ui/                 shared web tokens & components (generated from the same token JSON as Flutter)
  design-tokens/          tokens.json exported from Figma variables (Light / Night care) → Dart + CSS
firebase/
  functions/              TS strict, Functions 2nd gen, Admin SDK, zod validation
  workers/                Cloud Run jobs/services for media & AI if Functions limits are hit (SP-3)
  firestore.rules, storage.rules, firestore.indexes.json
  tests/                  Rules + integration tests (emulators)
  firebase.json, .firebaserc (aliases dev / prod; no default)
scripts/                  bootstrap, seed-dev (refuses prod), deploy, env checks
docs/                     product/, development/, architecture/ (ADRs), operations/ (runbooks), discovery/
```

### 3.2 Mobile (Flutter)

- **State & DI:** Riverpod (code-gen providers), immutable models (freezed + json_serializable generated from `packages/contracts`). One state manager.
- **Navigation:** go_router with typed routes; **role-aware shells** (Parent / Caregiver / Relative NavBar variants, `44:362`) rebuilt when the selected baby or membership changes; deep links for invites, verification, widgets, notifications, share extension.
- **Feature-first modules:** `onboarding`, `auth`, `family`, `baby`, `care`, `timers`, `history`, `stats`, `reminders`, `memories`, `upload`, `albums`, `stories`, `sharing`, `storage`, `me`, `widgets_bridge`.
- **Data:** repositories over Firestore (offline persistence on), Storage via native uploader, Functions callables. Pure domain logic (`care-calc` mirror, permission evaluation for UI, formatting) has no Flutter / Firebase imports and is unit-tested.
- **Offline:** Firestore cache is the primary outbox for care, reminders, reactions (direct writes with client ids). `hasPendingWrites` drives "Chờ đồng bộ". Widget / Live Activity / share-extension writes go through an **App Group queue** drained by the app or a background task (SP-5 validates; a local SQLite outbox is the fallback if Firestore cache can't meet "survive restart" on both OSes).
- **Media:** thumbnail-first lazy grids (slivers), bounded memory/disk cache, decode at display size, signed short-lived URLs (see 3.4), `video_player` for playback (HLS/MP4 per SP-3).
- **Heavy work off UI thread:** stats over 30 days, card rendering (1080×1350), image hashing / EXIF strip → isolates or native.
- **Platform channels / native targets** (Swift / Kotlin), see 3.6.

### 3.3 Backend (Firebase in the same GCP project per environment)

- **Firestore** (Native mode, asia-southeast1). Proposed collections (final shapes in `packages/contracts`):
  - `users/{uid}`, `users/{uid}/devices/{deviceId}`, `users/{uid}/favorites/{mediaId}` (private), `users/{uid}/inbox/{id}` (messages, Q-007)
  - `families/{familyId}` (owner, quota, usage), `families/{f}/storageRequests/{id}`
  - `babies/{babyId}` (member-visible: nickname, avatar ref, timezone, trackers, owner, ageAnchor) and `babies/{b}/restricted/profile` (DOB, gender — Cùng nuôi + relatives with viewBabyInfo). Field-level privacy needs separate docs because Rules are document-level.
  - `babies/{b}/members/{uid}`, top-level `invites/{id}` (server-only; code index `inviteCodes/{code}`)
  - `babies/{b}/records/{recordId}`, `/activeTimers/{type}`, `/daySummaries/{yyyy-mm-dd}`, `/conflicts/{id}`, `/reminders/{id}`
  - `babies/{b}/memories/{id}`, `/media/{id}` (item-level `audience`), `/albums/{id}`, `/milestones/{id}`, `/reactions/{target_uid}`, `/messages/{id}`, `/stories/{id}`, `/storyJobs/{id}`, `/cardExports/{id}`
  - server-only: `shareLinks/{id}`, `uploadSessions/{id}`, `jobs/{id}`, `audit/{id}`, `ops/{opId}`
- **Rules:** deny by default; membership via `get(/babies/{b}/members/{uid})`; role checks per §5 of the business map; relatives' queries must constrain `audience == 'family'` (Rules are not filters); schema & invariant validation on direct writes (types, enums, ranges, `createdBy == auth.uid`, immutable fields, `revision` increments).
- **Functions 2nd gen (Node 22, TS strict, zod):** callables for invites, membership, baby lifecycle, upload sessions, audience changes, deletes, links, storage requests, conflict resolution, staff actions; triggers for summaries, overlap detection, counters, notifications; scheduled jobs (membership expiry, reservation cleanup, 30-day purge, weekly story drafts, link expiry); Cloud Tasks queues for media processing, AI generation, deletion jobs, email.
- **Storage:** private bucket, no public download tokens; paths `babies/{b}/media/{mediaId}/{original|display|thumb|poster|video/*}`, `uploads/{sessionId}`; Storage Rules deny client reads except via signed URLs minted after a membership + audience check (decided in SP-2: signed URLs vs Rules with cross-service `firestore.get`).
- **Auth:** Apple, Google, email/password (link verification & reset on custom domain), anonymous (join-now). Custom claims only for staff (`staff: true`, scopes).
- **App Check:** Play Integrity / App Attest (DeviceCheck fallback) for mobile, reCAPTCHA Enterprise for web; enforced on callables and Firestore/Storage after rollout monitoring. Complements, never replaces, auth.
- **Messaging:** FCM for family notifications (generic text, no images, no baby name on lock screen), APNs (token-based, `.p8` in Secret Manager) for Live Activity updates / push-to-start.
- **AI (D-003, R-196):** OpenAI API called only from Functions / workers through an `AiProvider` adapter (OpenAI first, swappable); keys in Secret Manager per environment; **text only** — that week's captions / notes, milestone names, dates and counts, nickname instead of real name, **no photos**; no-retention terms required for prod; strict JSON output schema; ≤ 3 drafts per baby per week; monthly budget with 80% alert and automatic pause at 100% (`ai_story_drafts`); prompts/responses never logged with child data.
- **Limits (D-011):** `config/limits` (video max duration — default unlimited, video max size — default 4 GB, Wi-Fi-only default, family quota default 10 GB, export link TTL 24 h) read by clients and enforced by Functions; changed without an app release.
- **Feature flags (R-189, P-122):** `config/flags` read by clients (public projection) and enforced by Functions; family-bucketed staged rollout; kill switches keep upload queues waiting and auto-resume.
- **Ops aggregates:** scheduled / triggered aggregation into `ops/*` collections (KPIs, funnel, queue health, storage histogram, AI stats) so the portal never queries family data.
- **Secrets:** Secret Manager per project; nothing in clients beyond Firebase web/app configs.

### 3.4 Media pipeline (validated by SP-2 / SP-3)

1. Client `createUploadSession(batchId, items[{mediaId, bytes, type, captureAt}])` → server checks role & audience, **reserves quota transactionally** (`families/{f}.reservedBytes`), creates `memories/{id}` (state `uploading`) and `media/{id}` (state `pending`), returns per-item resumable upload targets.
2. Native background uploader (iOS `URLSession` background config incl. from the share extension; Android `WorkManager`) uploads with resume; video waits for Wi-Fi when the setting is on; photos use cellular.
3. Storage finalize → Task queue → worker: content sniffing (reject unreadable → `Unreadable`), strip location EXIF, generate display + thumb (WebP/AVIF), video poster + renditions; commit reservation with real size; mark `ready`.
4. When the batch is terminal (P-030) → single generic family notification (idempotent on `batchId`), update upload pill state ("Đã báo cho Bà nội, Ông ngoại").
5. Scheduled cleanup releases reservations and deletes orphaned uploads after 24 h.

### 3.5 Web

- **Landing** (`apps/landing`): React + TS + Vite, prerendered static pages for LCP ≤ 2.5 s / CLS ≤ 0.1 / INP ≤ 200 ms; desktop 1440 + mobile 375 from Figma; reduced-motion aware scroll reveals; store links; legal pages (content from owner, Q-020); serves `/.well-known/apple-app-site-association` and `/.well-known/assetlinks.json`.
- **Recipient web** (`/s/{token}` on the landing site): Hosting rewrite → Cloud Function `shareView` renders the story projection server-side (no client Firestore access), passcode form, expired / revoked / not-found / locked states (G-052), signed image URLs honouring `allowDownload` (and the R-166 caveat).
- **Invite landing** (`/i/{token}`): opens the app via universal / app link; fallback page with store badges and code.
- **Portal** (`apps/portal`, Figma `253:18`): staff SPA on `admin(.dev).childlife.app`; **Firebase Auth email/password (no SSO, D-008)** for admin-created staff accounts + **TOTP 2-step** (Identity Platform MFA) (idle sign-out removed by D-062); role claims (Vận hành, Hỗ trợ, Kỹ thuật, trưởng nhóm); App Check; every mutation requires a reason and writes the append-only audit log; reads only aggregates, masked emails and `F-XXXX` family codes — **never photos, videos, captions or care records, never user exports** (R-181…R-187). Portal reads come from server-side callables / aggregate collections, not from family documents.
- Web errors: error boundaries → rate-limited, redacted `logClientError` → Cloud Logging / Error Reporting (Crashlytics does not support web).

### 3.6 Native integrations

| Capability                                                      | iOS (as designed)                                                                    | Android (mimic iOS design — D-004)                                                             | Spike                      |
| --------------------------------------------------------------- | ------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------- | -------------------------- |
| Interactive widgets S/M/L, lock accessories                     | WidgetKit + App Intents (iOS 17+), App Group snapshot + queue                        | Jetpack Glance widgets with action callbacks, same states                                      | SP-1                       |
| Live Activity + Dynamic Island (sleep, breast, upload progress) | ActivityKit, local start + APNs updates; push-to-start on family devices (iOS 17.2+) | Ongoing notification with chronometer + actions (Live Updates / progress-style on Android 16+) | SP-1                       |
| Background upload                                               | URLSession background (app + share extension)                                        | WorkManager foreground-service-typed `dataSync` work                                           | SP-2                       |
| Share from Photos                                               | Share Extension → App Group → background session                                     | Share-target activity (`ACTION_SEND_MULTIPLE`)                                                 | SP-2                       |
| Local reminders                                                 | UNUserNotificationCenter via flutter_local_notifications, timezone-aware             | Exact/inexact alarms per Android 14 policy                                                     | S7                         |
| Sign in with Apple                                              | native                                                                               | web flow (Firebase OAuth)                                                                      | SP-6                       |
| Camera burst, photo/video capture                               | AVFoundation (custom camera, 10a3)                                                   | CameraX                                                                                        | S9                         |
| Photo library multi-select (≤30, "Có Teddy" filter)             | PHPicker / PhotoKit (people album)                                                   | Photo Picker                                                                                   | S9 (face filter: see note) |
| Save album to Photos ("Lưu vào album 'Giờ tắm'")                | PhotoKit album creation                                                              | MediaStore collection                                                                          | S10                        |
| Haptics, Reduce Motion, Dynamic Type                            | native APIs via Flutter                                                              | same                                                                                           | S1                         |
| Universal / App Links                                           | Associated Domains                                                                   | App Links (verified)                                                                           | S3                         |

Note: the "Có Teddy" filter in the library picker (`146:17006`) relies on the OS People album on iOS; Android has no equivalent public API → hidden on Android (D-004).

### 3.7 Environments and isolation

|                                                                                           | dev                                                                                                                                                                                      | prod                                                                                                      |
| ----------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| Firebase project                                                                          | **`child-life-dev`** (exists)                                                                                                                                                            | `child-life-prod` (to be created)                                                                         |
| Bundle / package id                                                                       | `app.childlife.dev` (display "Child Life Dev", tinted icon)                                                                                                                              | `app.childlife`                                                                                           |
| Hosting sites                                                                             | `child-life-dev-landing`, `child-life-dev-admin`                                                                                                                                         | `child-life-prod-landing`, `child-life-prod-admin`                                                        |
| Public hosts                                                                              | **`dev.childlife.app`** — landing, recipient web `/s/{token}`, invite links `/i/{token}`, Auth action handler, AASA / assetlinks for the dev app; **`admin.dev.childlife.app`** — portal | **`childlife.app`** (+ `www` redirect) — same routes for the prod app; **`admin.childlife.app`** — portal |
| Auth domain (OAuth redirects, email action links)                                         | `dev.childlife.app`                                                                                                                                                                      | `childlife.app`                                                                                           |
| Universal / App Links                                                                     | `applinks:dev.childlife.app` → `app.childlife.dev`                                                                                                                                       | `applinks:childlife.app` → `app.childlife`                                                                |
| Email sender                                                                              | `hello@dev.childlife.app` (separate reputation)                                                                                                                                          | `hello@childlife.app`                                                                                     |
| Search indexing                                                                           | `noindex` on every dev host                                                                                                                                                              | landing indexed; `/s/*`, `/i/*`, admin `noindex`                                                          |
| Auth, Firestore, Storage, Functions, Secrets, Tasks, AI provider keys, budgets, telemetry | separate                                                                                                                                                                                 | separate                                                                                                  |
| Builds                                                                                    | App Distribution / TestFlight internal                                                                                                                                                   | Store release (owner approval)                                                                            |

- Typed **env resolver** in Flutter and web refuses to start if the Firebase options, bundle id, flavor and API host don't belong to the same environment.
- `.firebaserc` has aliases only; every deploy script requires `--project dev|prod` and prints the target; `seed-dev` aborts on prod.
- Emulators are the local/test target, not a third environment. Hosting preview channels (`*.web.app`) always use dev.
- A dev build only accepts links and auth redirects from `dev.childlife.app`; a prod build only from `childlife.app` — the env resolver checks the host as well as the Firebase project.
- CI uses Workload Identity Federation (short-lived credentials), least-privilege deployer service accounts per project.

### 3.8 Observability

- Mobile: Crashlytics (Flutter + native + async handlers, dSYM / mapping upload), Performance custom traces (cold start, Today first content, save-record latency, upload throughput, story generation, link open), Analytics only with redacted events (no child data).
- Backend: structured JSON logs with `opId`, `babyIdHash`, no PII; Error Reporting; Cloud Monitoring dashboards & alerts: function error rate, p95 latency, task queue depth / age (stuck jobs), deletion job failures, AI cost/day, storage & egress growth, Firestore reads spikes, crash-free users, budget alerts. Alerts route to the owner's channel (TBD).
- Runbooks (`docs/operations/`): deploy, rollback / roll-forward, incident, retries & dead letters, quota reconciliation, restore (Firestore PITR + scheduled exports to a locked bucket), key rotation, account / baby deletion verification.

---

## 4. Motion and performance contract

Motion follows the Figma **Motion spec** page (`269:19`, R-200; extract `10-motion-spec.md`), generated into code from `packages/design-tokens/tokens.json`:

| Token             | Value   | Curve                                                                           | Used for                          |
| ----------------- | ------- | ------------------------------------------------------------------------------- | --------------------------------- |
| `motion.instant`  | 100 ms  | ease-out (0.2, 0, 0, 1)                                                         | press, switches, touch feedback   |
| `motion.quick`    | 200 ms  | ease-out (0.2, 0, 0, 1)                                                         | chips, sub-tabs, small notices    |
| `motion.standard` | ~350 ms | spring — iOS response 0.35 / damping 0.86; Android damping 0.86 / stiffness 380 | sheets, full-screen photo         |
| `motion.exit`     | 250 ms  | ease-in (0.4, 0, 1, 1)                                                          | closing sheets / photos / notices |
| `motion.gentle`   | 600 ms  | soft ease-out (0.3, 0, 0, 1)                                                    | story cards, milestones, welcome  |

- Press scale 0.96 (photo cards 0.98); disabled 40 %; scrim 0 → 32 %; stagger 30 ms, max 6; shifts: notice 24 px, chip 8 px.
- **Screen transitions: platform default (D-013)** — iOS push with swipe-back, Android default / predictive back; fade under Reduce Motion.
- **Night care:** no bounce, shorter durations, no flashes, no haptics except "success".
- **Reduce Motion:** sheets / screens fade 150 ms, photos cross-fade 200 ms, hearts change colour only, skeletons static, story cards appear instantly.
- **Haptics:** light on tap, success when a save / upload completes, warning before delete or a duplicate time.
- **Never block logging:** saves are optimistic (local response < 100 ms); animations never gate the next tap.
- **Budgets (to be measured, not claimed):** 60 Hz build+raster ≤ 16.7 ms, 120 Hz ≤ 8.3 ms on the agreed device matrix (§8.3) in profile/release; warm cached Today < 1 s; online p95 useful content < 2.5 s; landing Core Web Vitals per brief. If an effect cannot hold 60 fps on low-end devices, drop the effect and keep the feedback (Motion spec rule).

---

## 5. Feasibility spikes (run first, in parallel with Slice 0/1)

Each spike produces a short ADR in `docs/architecture/` with evidence (device recordings, logs, numbers) and a go / fallback decision. Spikes are throwaway branches unless promoted.

| Spike                                        | Question                                                                                                                                                                                                                                      | Method                                                                                                                                                     | Exit criteria                                                                                                                                                                 | Fallback if it fails                                                                                               |
| -------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| **SP-1 Native glanceables**                  | Can Flutter host WidgetKit S/M/L + lock accessories with App Intent logging + 5 s undo, Live Activity + Dynamic Island for sleep/breast with in-place actions, updates pushed to _other_ family devices (push-to-start)? Android equivalents? | Swift extensions + App Group bridge, APNs from a dev Function, Glance widget + ongoing notification on Android; measure update latency & budgets           | Real devices both OS: one-tap log offline → syncs; LA appears on a second family device; actions work locked; documented OS limits (refresh budgets, push-to-start iOS 17.2+) | Show LA only on the starting device; others see in-app "Cả nhà đang thấy" — requires owner approval (explicit gap) |
| **SP-2 Background upload & share extension** | Resumable uploads that survive app kill / lock on both OS, from app and share extension, Wi-Fi-only video, quota reservation, signed-URL vs Rules for serving                                                                                 | Prototype `createUploadSession` + GCS resumable sessions + native uploaders (evaluate `background_downloader` vs custom), 30-item batch incl. 500 MB video | Kill app mid-upload → completes; airplane-mode toggle → resumes; extension memory within limits; no duplicate media; reservation reconciles                                   | Foreground-service upload on Android; iOS: continue in app on next launch with honest pill state                   |
| **SP-3 Media processing & playback**         | HEIC/HEVC/ProRes input, thumbnails, video renditions (Transcoder API vs ffmpeg on Cloud Run), time-to-ready, cost per minute, Flutter playback (HLS vs MP4)                                                                                   | Process a corpus of real iPhone/Android media                                                                                                              | p95 ready time & cost/GB documented; budget set; playback smooth on matrix devices                                                                                            | Client-side HEIC→JPEG; MP4-only renditions                                                                         |
| **SP-4 AI story draft**                      | OpenAI (D-003) draft quality in Vietnamese from **text only** (captions, notes, milestones, dates, counts — R-196); refusal to invent; latency; cost per draft vs budget; no-retention terms verified; adapter keeps provider swappable       | Offline eval set (owner-provided or synthetic family photos), rubric incl. "no invented facts"                                                             | ≥ owner-accepted quality on rubric; zero invented-fact violations on eval set; cost/draft documented                                                                          | Template-based draft (no model) with owner approval; feature stays behind `ai_story_drafts`                        |
| **SP-5 Offline-first care sync**             | Firestore persistence as outbox across process death on both OS; pending indicators; App Group queue drain; overlap detection; clock skew                                                                                                     | Scripted tests with network toggles & kills; two-device race tests                                                                                         | No lost / duplicated records in 500 randomized runs; overlap always surfaced                                                                                                  | Local SQLite outbox replayed into Firestore                                                                        |
| **SP-6 Identity edge cases**                 | Anonymous join → link Apple/Google/email; credential-collision merge; Sign in with Apple on Android; email link verification via universal links                                                                                              | Prototype flows on both OS                                                                                                                                 | All paths keep memberships & authored records                                                                                                                                 | Require account at join (would contradict Figma → owner decision)                                                  |
| **SP-7 Performance baseline**                | Impeller frame times for Today, history (1k rows), photo grid (5k items), timers, sheets on mid-range devices                                                                                                                                 | Profile builds, DevTools timeline, `flutter drive --profile` summaries                                                                                     | Budgets met or documented with mitigation                                                                                                                                     | Reduce effects (shadows/blur) per device class                                                                     |
| **SP-8 Transactional email**                 | Provider deliverability for Vietnamese Gmail/Outlook, unsubscribe, SPF/DKIM/DMARC on childlife.app                                                                                                                                            | Send invite template through 2 candidates                                                                                                                  | Inbox placement on major providers                                                                                                                                            | Firebase Trigger Email extension + SMTP relay                                                                      |

---

## 6. Delivery slices

Common **definition of done** for every slice (in addition to slice criteria): Figma nodes in scope implemented in Light and Night care and listed in the coverage checklist with code + test references; real dev Firebase; Rules + Functions tests for new permissions; widget/golden tests for new components/screens; accessibility (labels, Dynamic Type 200%, contrast, Reduce Motion) checked; analytics/telemetry redaction reviewed; monitoring for new jobs/functions; docs updated (contracts, permissions, runbooks); slice report filed.

### S0 — Repository, environments, CI

- **Scope:** monorepo skeleton (§3.1), feature-flag store `config/flags` (P-122), pinned toolchains (FVM, Node, pnpm), Flutter app with dev/prod flavors (bundle ids, names, icons from Logo page `35:239`), env resolver, Firebase projects wired (blocked on §2), emulators, Rules deny-all baseline, Functions hello-world with zod, landing & portal skeleton apps, Hosting targets per project, Crashlytics + Performance initialized with redaction, CI (format, analyze, typecheck, unit, Rules tests, builds, secret & dependency scan), App Distribution for dev, `README.md` + `CLAUDE.md` with setup/commands, ADR-001 (architecture), ADR-002 (region), ADR-003 (environments).
- **Acceptance:** dev build installs on a real iPhone and Android device and shows a live round-trip (callable + Firestore read) in dev; prod build refuses to start with dev config and vice versa; `seed-dev --project prod` aborts; CI green on a PR; a forced crash appears in Crashlytics with symbols.
- **Depends on:** blockers §2.

### S1 — Design system & app shell

- **Figma:** Foundations `17:467` (34 colour tokens Light/Night care, care category tokens incl. pump, typography Be Vietnam Pro with tabular figures, spacing, radius, shadows), Components `7:4` (≈80 sets), Logo `33:2`, motion tokens (§4), Splash `36:2233`.
- **Mobile:** tokens generated from `packages/design-tokens`; `ChildLifeTheme` with Light / Night care; component library + **showcase app route** (dev only); golden tests per component variant vs Figma screenshots; NavBar per role, TabDock, QuickLogButton; Night care controller (schedule, manual toggle, timer-forced) per P-061 (Q-027); Reduce Motion & Dynamic Type handling; icon set: SF Symbols on iOS; on Android the Figma line icons exported as SVG so the look mimics iOS (D-004).
- **Web:** same tokens as CSS variables; base components for landing/portal.
- **i18n (D-012):** every component and screen string through ARB / ICU catalogs in vi and en; goldens in both languages; English length checked at 200% text size.
- **Acceptance:** every Figma component variant rendered in showcase in both modes with goldens; contrast checks pass (care ink ≥ 5.5:1 as specified); 200% text layouts don't clip; splash ≤ 1 s with reduced-motion variant.
- **Depends on:** S0. Q-027. Domain components (CareTile, TimelineItem, DayRhythm, MemoryCard, MediaTile, UploadPill, QueueRow, StoryCard, widgets, SleepTimer) are built in their feature slices (S4–S13) on top of these primitives.

### S0 status (2026-10-10)

See [slice-reports/S0.md](slice-reports/S0.md) — delivered items, evidence and what remains open.

### S1 status (2026-10-10)

See [slice-reports/S1.md](slice-reports/S1.md).

### S2 — Identity & onboarding (first secure vertical slice)

> **Status:** in progress on branch `s2-onboarding` — [report](slice-reports/S2.md). Email path works end to end (iOS + Android, emulators); Google waits for console enablement, Apple for a developer team.

- **Figma:** 00–05, 06–10, 10a, 11, 11a–11c, 12, 13, 13a, 18–18c (first-run Today shell with empty tiles).
- **Backend:** `users` doc on create, Auth providers (Apple, Google, email/password + link verify/reset with custom domain templates), `createBaby` (family creation per P-001, 3-baby cap, owner membership), baby avatar upload (private), restricted profile doc, Rules + tests.
- **Native:** Sign in with Apple (both OS, SP-6), Google Sign-In, mail-app intent, camera/photo picker, device timezone, launch screens.
- **Tests:** auth flows on devices (Patrol for native dialogs), Rules (cannot read other babies, relatives can't read restricted profile), cap race (two concurrent creates).
- **Acceptance:** new parent goes from splash to empty Today on both OS in dev with a real account; collision flow links accounts; reset & verify links open the app; baby appears with correct timezone; Night care schedule applies app-wide immediately.
- **Depends on:** S1, SP-6. Q-011, Q-017, Q-020.

### S3 — Family, invites, roles, multi-baby

> **Status:** in progress on branch `s2-onboarding` — [report](slice-reports/S3.md). Invite → join → save account → lost access works end to end (iOS + Android, emulators); invite emails wait for the SES keys, iOS universal links for an Apple team; leave family (12g) not built.

- **Figma:** 14a–14f, 14b2, 14c2, 15, 16, 16a–16d, 17, 7a–7d (shell/nav parts), 9d, 12g, 13m (relation per baby).
- **Backend:** invites (6-digit code, QR/link token, 7-day expiry, resend, regenerate), transactional invite email (SP-8), `previewInvite` / `acceptInvite` with rate limits, anonymous join + upgrade + merge (P-007), membership update/remove/expiry job, revocation signal → 9d, audit log.
- **Mobile:** role-aware shells and route guards, baby switcher with content swap, QR scanner, share sheet, universal/app links `/i/{token}`, "Chưa lưu tài khoản" banner.
- **Web:** invite landing page `/i/{token}`, AASA/assetlinks.
- **Tests:** Rules matrix for all three roles (cross-baby leakage, privilege escalation, removed member, expired access), invite expiry/regenerate/brute-force, anonymous upgrade keeps uid & records, revocation purges device cache (integration on device).
- **Acceptance (plan flow A):** expired invite, re-accept, wrong person, removed access, temp identity → account all pass on both OS; caregiver and relative see exactly their tabs per business map §5.
- **Depends on:** S2. Q-006, Q-013, Q-021, Q-023, Q-024.

### S4 — Care logging core & offline

> **Status:** in progress on branch `s2-onboarding` — [report](slice-reports/S4.md). Bottle, breast, pump, diaper and growth logging, record detail with edit / delete / undo, offline save and sync work end to end (iOS + Android, emulators); sleep and timers are S5, History S6.

- **Figma:** 19, 19a, 21, 22, 23, 23a, 24, 28, 7a/7d content, 12b–12e, 9a, 9b, Banner/Error, SyncStatus, LogRow pending.
- **Backend:** record schema + Rules (role, ownership P-004, ranges), `DaySummary` trigger (idempotent recompute), "Đã xoá gần đây" soft-delete + 30-day purge job, counters ("đã ghi 46 lần").
- **Mobile:** Today tiles per trackers, quick log, all sheets with defaults/memory of last choice, keypad, wheels, record detail with attribution, edit/delete + 5 s undo, optimistic UI < 100 ms, pending/synced states, offline banner & sheet, "Nhắn Mẹ" entry (destination per Q-007).
- **Tests:** domain unit tests (defaults, side suggestion, diaper both counting), golden screens, Rules (caregiver edit others → denied), SP-5 harness promoted to CI (randomized offline/kill), duplicate-save idempotency.
- **Acceptance (plan flow B part 1):** double save, two loggers, offline save → kill → relaunch → syncs, edit/delete permissions per role; pumping never in intake totals.
- **Depends on:** S3, SP-5. Q-012, Q-029, Q-030.

### S5 — Timers, sleep, overlap

> **Status:** in progress on branch `s2-onboarding` — [report](slice-reports/S5.md). Sleep / breastfeed / pump timers, manual sleep, overlap resolution and the first-run tour work end to end (iOS + Android, emulators); Live Activities wait for SP-1.

- **Figma:** 23b, 23c, 25a, 25, 26, 27, 9c, CareTile sleep-running, Night care auto-on.
- **Backend:** `activeTimers` transactional slot (P-011), end → exactly one record, overlap detection trigger → `conflicts`, `resolveConflict` callable, loser → 30-day bin.
- **Mobile:** timestamp-based timers (no per-second writes), pause/resume per side, double pump, edit start, cancel confirm, chooser vs immediate start (Q-022), overlap resolver UI, haptics.
- **Tests:** clock-change and timezone edge cases, two devices start/stop races, offline timer conflict, process death while running.
- **Acceptance (plan flow B part 2):** overlapping sleeps never auto-merged; overnight sleep split per day in baby tz; timer survives kill/relaunch with correct elapsed.
- **Depends on:** S4. Q-022, Q-025.

### S6 — History & statistics

> **Status:** in progress on branch `s2-onboarding` — [report](slice-reports/S6.md). History with filters, day strip, date picker, empty-day back-log and growth, plus feeding and sleep statistics (Hôm nay / 7 / 30 ngày), work end to end (iOS + Android, emulators); the 1k-row scroll budget is not measured yet.

- **Figma:** 20, 20a–20h, 20f, 20g2, DayRhythm variants, TimeSectionHeader, GrowthRow, growth chart.
- **Shared logic:** `packages/care-calc` (TS) + Dart mirror with **shared golden vectors** (timezone, DST, midnight, empty days, pending records) — business calculations testable without UI/Firebase.
- **Mobile:** day strip, month calendar (dots, DOB/future bounds), filters, empty-day back-logging, feeding stats (Hôm nay window from 18:00, 7/30 days, hourly avg, day/night by ml, breast sides), sleep stats (rhythm rows, longest per day), 30-day and sleep-today variants (G / Q-031), paginated queries.
- **Acceptance:** every number on 20–20h reproduced from a reconciled seed dataset (fixing Figma mock inconsistencies); 1k-row history scrolls within frame budget.
- **Depends on:** S4, S5. Q-026, Q-031.

### S7 — Reminders

> **Status:** in progress on branch `s2-onboarding` — [report](slice-reports/S7.md). Reminders 8a–8e / 12f, ReminderPeek and local notifications on the bound device work end to end (iOS + Android, emulators); reminder Rules deployed to dev; overdue, baby time-zone change and device takeover not yet run on a device.

- **Figma:** 8a–8e, 12f, ReminderPeek, ReminderRow states.
- **Backend:** reminder Rules (create/edit parents, mark done caregivers), `notifyDevice` binding.
- **Mobile:** local notifications scheduled only on the bound device, permission pre-prompt after first save, denied state with settings deep link, reschedule on edit / timezone change / device change, overdue grouping.
- **Acceptance (plan flow C):** overdue, edit, cancel (Q-018), notifications off, baby timezone change; no server push replaces local notifications.
- **Depends on:** S4. Q-005, Q-018, G-061.

### S8 — Widgets, lock screen, Live Activity, Dynamic Island

> **Status:** waiting on SP-1 — needs real devices, an Apple team (App Groups, keychain sharing) and APNs push-to-start; S9 went first on the parallel memories branch.

- **Figma:** W1–W5, Components `73:399` (Small 10 states, Medium 3, Large, Lock circular/rect/inline, LiveActivity sleep/breast, DynamicIsland), upload Live Activity from 10j.
- **Native:** promote SP-1; App Intents for log/undo/start/stop/switch side; App Group snapshot from `DaySummary`; deep-link table (W5); signed-out / empty / offline states; Android Glance widgets + ongoing timer/upload notifications mirroring the iOS layouts, states and actions (D-004).
- **Acceptance:** one tap logs without opening app (online and offline) with ~5 s undo; LA visible to family devices (or approved fallback); deep links land on the right screen; no child photos on lock screen.
- **Depends on:** S5, S6, SP-1. G-060. Android mirrors iOS layouts and states (D-004).

### S9 — Memories core & upload

> **Status:** in progress on branch `s2-onboarding` — [report](slice-reports/S9.md). Journal, photos grid, add (library, Files, note), compose with milestones, upload queue + server processing (sharp, metadata stripped), viewer, selection actions and delete work end to end (iOS + Android, emulators); backend on dev. In-app burst camera, share extension, upload Live Activity and kill-proof background transfer wait (SP-1/SP-2); albums, loves, favourites done in S10.

- **Figma:** 10a, 10a2, 10a3, 10b, 10b2, 10b3, 10b4, 10b5, 10c, 10f, 10g, 10h, 10h2–10h5, 10i, 10j, 10k, 10o, 13f, MemoryCard, MediaTile, UploadPill, QueueRow.
- **Backend:** promote SP-2/SP-3 pipeline (§3.4), quota reservation, media audience per item with server-computed effective audience (D-002, P-035), milestone presets (age-based) + custom, memory publish rules (P-030), batch notification, soft delete + "Đã xoá gần đây" + purge.
- **Mobile:** add sheet, camera burst, library picker ≤30, files, notes, compose sheets, upload queue/pill, background upload, share extension, grid/timeline (week grouping by baby age), selection & batch actions, month jump, view options incl. "Xem như người thân", viewer.
- **Acceptance (plan flow D):** app killed, network drop, quota full, partial upload, audience changed during processing; no duplicate media/notification/quota on retry; caregivers have no access path (Rules tested).
- **Depends on:** S3, SP-2, SP-3. Q-019, Q-028. Default audience Gia đình (D-001).

### S10 — Albums, audience, relatives, reactions, messages

- **Figma:** 10d, 10e–10e10, 10o (album path), 11a–11h, 7b, favourites album, milestone collections.
- **Backend:** album audience bulk change with confirmation data, multi-album effective-audience rule (D-002), favourites (private), reactions + counters, "Nhắn ba mẹ" (Q-007), relative queries constrained by audience, album download manifest.
- **Mobile:** album CRUD/options, sort, select & remove, download all to Photos (background, Wi-Fi only option), relative UI (no +/Chọn), reactions with names for parents, generic lock-screen notifications.
- **Acceptance:** relative never receives a Chỉ ba mẹ item via any query, notification, album, story, or cache (Rules + integration tests); album delete keeps memories.
- **Depends on:** S9. Q-007, Q-014, Q-015.

> **Status:** in progress on branch `s2-onboarding` — [report](slice-reports/S10.md). Albums (CRUD, options, sort, audience with the multi-album rule), Yêu thích, Thương, "Nhắn ba mẹ" / "Lời nhắn" and the relatives' view work end to end on the emulators; backend on dev. Device push needs APNs (Apple team); background album download waits on SP-2.

### S11 — Me, storage, profiles, account, deletion

- **Figma:** 13a–13n.
- **Backend:** usage aggregation by baby/type (reconciled with Storage), thresholds 80% / 100%, storage request callable + email, baby edit, **baby deletion job** (resumable, verified, quota release, links revoked, LA ended, caches purged), ownership transfer + account deletion (Q-016), device list & remote sign-out (revoke refresh tokens + push signal), unlink provider guard.
- **Also (portal-driven, R-187, Q-037):** data-export requests (care CSV/JSON per baby; media ZIP owner-only) as DataJobs with 24 h signed links; "Trợ giúp & liên hệ" ticket form with diagnostics consent; writes-locked state during deletion; storage grant in-app notice + email.
- **Acceptance (plan flow F):** delete baby leaves zero documents/objects for that baby (verification script), other babies untouched, quota returned; failed job resumes at the failed step; "đã xoá" never shown early; export link expires after 24 h and re-checks ownership at download.
- **Depends on:** S9, S10. Q-016.

> **Status:** in progress on branch `s2-onboarding` — [report](slice-reports/S11.md). Tôi per role, storage (breakdown, 80 % / 100 %, requests), baby profiles (view, edit, verified resumable delete), your profile, account (devices + remote sign-out, ownership transfer, export, deletion), notification settings and help work end to end on Android with the emulators; backend on dev. Staff grants and replies wait for the portal (S14); iOS E2E to be re-run.

### S12 — Stories & AI

- **Figma:** 14a–14g, 11i, StoryCard reader parts.
- **Backend:** weekly draft scheduler + Task queue + OpenAI call through `AiProvider` (D-003, SP-4), structured block output validated against sources (P-092), per-paragraph rewrite/shorter/warmer/alternatives callables with rate & cost limits, drafts, save with audience & single notification, edit after save, source deletion handling.
- **Mobile:** list with filters and card variants, draft editor (block select, toolbar, keyboard AI bar, undo, "Đã sửa · không còn là văn AI"), photo block sheet (≤4, captions, cover), drag reorder & swipe delete, preview & save, saved reader with loves, relative reader with "Nhắn ba mẹ".
- **Acceptance (plan flow E part 1):** AI failure path; source deleted/made private after save; saving a story to Gia đình states how many private photos family readers will see (D-002); cost per draft within agreed budget.
- **Depends on:** S10, SP-4. G-050, G-051.

> **Status:** in progress on branch `s2-onboarding` — [report](slice-reports/S12.md). Stories list, draft editor with AI help, photos, arrange, preview & save, reader (parents and relatives), delete, and the weekly suggestion work end to end on Android with the emulators; backend on dev. Drafts use the template provider until the owner sets `OPENAI_API_KEY` (SP-4 not run); external sharing is S13.

### S13 — External sharing: cards, links, recipient web

- **Figma:** 14h, 14i, 14j, 14k, 14l, 14m, 14n StoryCard templates.
- **Backend:** link create/revoke, token & passcode (P-096), view counting, expiry job, `shareView` SSR with projection (P-095), download gating with signed URLs.
- **Mobile:** card renderer (5 templates, 1080×1350, off UI thread, Lora + Dancing Script bundled — verify Vietnamese glyphs), OS share sheet, saved-cards list, link manager under Tôi.
- **Web:** recipient page states (G-052) on `/s/{token}`.
- **Acceptance (plan flow E part 2):** expired / revoked / wrong passcode / lockout; hidden name & DOB by default; R-166 caveat respected in copy; downloaded cards listed as irrevocable.
- **Depends on:** S12. G-052, G-053.

> **Status:** in progress on branch `s2-onboarding` — [report](slice-reports/S13.md). Share sheet, photo cards (5 templates, Lora / Dancing Script bundled), private links with expiry / identity / downloads / passcode, the recipient page `/s/{token}` with every state, and the link manager under Tôi work end to end on Android with the emulators; backend and hosting on dev.

### S14 — Landing site

> **Status:** delivered on dev (2026-10-10) — [report](slice-reports/S14.md). Prod waits on the owner items listed there.

- **Figma:** Website `210:759` desktop `219:1391` + mobile `233:804` (all sections), legal pages (content from owner).
- **Acceptance:** pixel review vs Figma at 375/768/1440; Lighthouse CI budgets (LCP ≤ 2.5 s, CLS ≤ 0.1, INP ≤ 200 ms); store links; FAQ answers 3–5 supplied by owner (G-065); copy conflicts Q-002/Q-008/Q-009 resolved before prod.
- **Depends on:** S1 (tokens). Can run in parallel with S2–S13.

### S15 — Admin portal ("Child Life · Vận hành")

> **Status:** in progress on branch `s2-onboarding` — [report](slice-reports/S15.md). Sign-in (email + password or email link, D-043), the role matrix, A02–A12 with every staff action audited, the upload kill switch and the AI budget pause work end to end in the browser against the emulators; backend on dev, portal hosting on dev. Staff accounts on dev wait for the owner to run `create-staff.mjs`.

- **Figma:** Admin portal `253:18`: sidebar `253:467`, A01 sign-in, A02 overview, A03 support, A04/A05 storage expansion + approve, A06/A07 data requests + re-run, A08 storage & media health, A09 AI suggestions (budget, settings), A10/A11 feature flags + confirm off, A12 audit log.
- **Backend:** staff accounts in Firebase Auth (email/password or email link, admin-created, D-008 / D-043), role claims & matrix (business map §5.1, P-121), callables for every action with mandatory reason + audit (R-183), storage grant / decline (P-120 > 20 GB), ticket workflow + reply channel, video re-processing, data-job status & re-run, flag toggle / rollout with guard metrics, AI budget meter & auto-pause, ops aggregates, CSV exports of dashboards / audit (logged).
- **Web:** React portal per Figma (desktop 1440), masked emails / `F-XXXX`, empty / loading / error states (G-078), sign-out menu (G-079), team-lead approval UI (G-080).
- **Tests:** staff without claim → nothing; each role only its actions; reason required; audit entries immutable (Rules + IAM); no endpoint returns media URLs, captions or care payloads (contract tests); 30-min idle sign-out.
- **Acceptance:** granting quota resumes WaitingQuota uploads and notifies the owner; kill switch stops new uploads while queues wait and resume; re-run resumes deletion at the failed step; AI pauses at 100% budget; every mutation visible in A12 with actor, role, reason.
- **Depends on:** S0 (Auth + MFA enabled), S9 (uploads), S11 (data jobs, storage requests), S12 (AI). Flags (A10) are needed earlier: the flag store ships in S0, its portal UI here.

### S15b — Admin portal v1.0 (Figma `253:18` section v1.0)

> **Status:** built on branch `s2-onboarding` (2026-10-11; committed 2026-10-12 as b28e85d, 10b4a01, 06cd338, 871bf50; deployed to dev) — [report](slice-reports/S15b.md), [plan](../product/portal-v1.0-plan.md), evidence [`18-admin-portal-v1.md`](../discovery/figma-extract/18-admin-portal-v1.md). Owner decisions D-053 (no 2FA, no family suspension, any email domain, first Owner). App reading of the published growth / vaccine tables waits for the vaccination work.

- Phase 1 — staff RBAC v2 (roles and per-function levels server-side), the v1.0 sidebar, A18–A21 and portal invitations, migration of today's claims; the QA handbook (P-132) stays under PHÁT TRIỂN.
- Phase 2 — families directory A15–A17 on a `familyDirectory` read model, privacy rules P-136, staff-initiated ownership transfer with the owner's confirmation in the app.
- Phase 3 — analytics A13 / A14: mobile device heartbeat (`lastActiveAt`), nightly / weekly rollups, backfill, one set of metric definitions shared with A02 / A15 (P-137).
- Phase 4 — reference data C01–C04 with two-person approval and rollback, delivered through `publicConfig/reference_*`; the app reads it offline-first with a bundled fallback (growth, bottle; vaccines after P-133 lands) (P-138).
- Phase 5 — undrawn states G-085 … G-091, A12 categories (P-139), QA handbook cases, end-to-end on the emulators, dev deploy.

### S16 — Verify & release readiness

- Design QA pass (side-by-side goldens and device screenshots for all 154 screens × 2 modes), accessibility audit, security review (Rules fuzzing, App Check enforcement, dependency audit, pen-test checklist), performance runs on the device matrix, E2E suites on Firebase Test Lab + real devices, monitoring & alert drills, backup/restore drill, runbooks complete, prod provisioning with owner approval, store metadata/privacy labels/data-safety forms, release checklist, testing & release report with known gaps.

### Ordering and parallelism

```
SP-1..SP-8 ──────────────┐ (start immediately, inform S5/S8/S9/S12)
S0 → S1 → S2 → S3 → S4 → S5 → S6 → S7
                     │          └──→ S8 (needs SP-1)
                     └→ S9 (needs SP-2/3) → S10 → S11 → S15
                                   └→ S12 (needs SP-4) → S13
S1 → S14 (parallel)                      S16 after all
```

After S3 stabilises data and permission contracts, care (S4–S8) and memories (S9–S13) can proceed on parallel branches.

---

## 7. Data contracts & API (to be written in S0–S3)

- `packages/contracts`: zod schemas per document and callable request/response, versioned (`schemaVersion`), with generated Dart models; error contract `{code, messageKey, retryable, details}` mapped to calm Vietnamese copy; cursor pagination (`limit ≤ 50`, `startAfter`) for every list.
- `docs/architecture/permissions.md`: the §5 matrix as Rules test table (one test per cell).
- `docs/architecture/data-model.md`: collections, indexes, invariants, retention.

---

## 8. Testing strategy

### 8.1 Layers

| Layer                     | Tooling                                                                                                                 | Gate                  |
| ------------------------- | ----------------------------------------------------------------------------------------------------------------------- | --------------------- |
| Domain / calculations     | `dart test`, `vitest`; shared JSON vectors for care-calc                                                                | every PR              |
| Contracts / schema parity | zod ↔ Dart generated model round-trip tests                                                                             | every PR              |
| Rules                     | `@firebase/rules-unit-testing` on emulators; table-driven per role & audience                                           | every PR              |
| Functions integration     | emulators (Auth, Firestore, Storage, Functions, Tasks stub); idempotency & partial-failure cases                        | every PR              |
| Widgets / goldens         | `flutter test` goldens per component & screen (Light + Night, text scale 1.0 / 2.0)                                     | every PR              |
| Device E2E                | `integration_test` + Patrol (native permission dialogs, notifications, share sheet) on Firebase Test Lab + real devices | nightly + pre-release |
| Native extensions         | XCTest for App Intents / widget timelines; Android instrumented tests for Glance & WorkManager                          | nightly               |
| Web                       | vitest + Playwright (landing, recipient web, portal auth); Lighthouse CI                                                | every PR              |
| Performance               | profile builds, frame timing summaries, startup traces                                                                  | per slice report      |
| Security                  | Rules fuzz, secret scanning, dependency audit, App Check enforcement checks                                             | every PR / weekly     |

### 8.2 Must-have scenario suites (from business map §9)

Cross-family leakage, privilege escalation (caregiver editing parent records, relative changing audience), revoked access mid-session, duplicate commands, partial upload failures, deletion verification, timezone/DST/midnight, offline + process death, two-device races, link abuse (enumeration, passcode brute force).

### 8.3 Proposed device matrix (owner to confirm)

iOS: iPhone SE (3rd gen) or iPhone 12 (60 Hz, mid), iPhone 15 Pro (120 Hz), minimum iOS **16.1** (Live Activities) with interactive widget features on iOS 17+. Android: Pixel 7a and Samsung Galaxy A35-class (mid-range), one low-end Android 10 device; minimum **API 26**.

---

## 9. Security & privacy plan

- Deny-by-default Rules; server-side authorization for every sensitive command; Admin SDK paths tested independently (they bypass Rules).
- Field-level privacy via document split (restricted profile); audience per media item; relatives' queries constrained.
- Private bucket; short-lived signed URLs; EXIF location stripped; no public download tokens.
- Link tokens ≥ 128-bit random; passcode hashed; attempt limits; generic errors.
- Rate limits per action (invites, code redemption, AI rewrites, link views, storage requests).
- Telemetry redaction (names, DOB, photos, captions, care payloads, tokens) enforced by a logging wrapper + tests.
- Revocation: membership change → device purge; deleted / private sources removed from derived assets and links.
- Staff access: Firebase Auth + TOTP, explicit staff/role claims, reason on every action, audit; staff never see child media, captions or care records (R-181).
- Retention: 30-day soft delete bin; baby deletion hard-deletes; account deletion per Q-016; Firestore PITR + scheduled exports; documented restore test.
- Legal: privacy policy, terms, consent, residency — owner/legal (Q-020).

---

## 10. Risks

| Risk                                                                  | Impact                                                  | Mitigation                                                      |
| --------------------------------------------------------------------- | ------------------------------------------------------- | --------------------------------------------------------------- |
| iOS-only native design, Android must mimic it (D-004)                 | Some iOS surfaces (Dynamic Island) have no Android twin | SP-1/SP-2 early; ongoing notifications mirror content & actions |
| Live Activity on other family devices needs APNs push-to-start        | "Cả nhà đang thấy" may be in-app only                   | SP-1 decides; explicit gap if not approved                      |
| Background upload from Flutter + share extension                      | Data loss / battery                                     | SP-2; native uploaders; honest states                           |
| Video processing cost / latency                                       | Budget overrun                                          | SP-3; limits (Q-028); budget alerts + concurrency caps          |
| AI privacy & cost (child photos sent to OpenAI, outside Google Cloud) | Trust / compliance / cross-border transfer              | D-003 adapter, SP-4, caps, redaction, legal review Q-020        |
| Figma internal conflicts (§14 of business map)                        | Rework                                                  | Resolved by documented rules; owner questions                   |
| Firestore Rules complexity (roles × audience × grants)                | Leaks                                                   | Table-driven Rules tests per cell; code review                  |
| Figma MCP rate limits                                                 | Slow design QA                                          | Extraction stored in repo; batch screenshot exports for goldens |
| Environment mix-ups                                                   | Prod data in dev or reverse                             | Env resolver, explicit project flags, separate SAs              |
| Legal (child data, residency)                                         | Release block                                           | Q-020 before prod                                               |

---

## 11. Decisions needed from the owner

Resolved 2026-10-10: D-001 default audience Gia đình, D-002 albums may widen (most permissive wins), D-003 OpenAI first, D-004 Android mimics iOS, D-005 Firebase set up later by owner. Still open: Q-037 mobile entry points for export / support / content report, landing copy replacement for "Ảnh mới mặc định chỉ ba mẹ thấy", Q-011 family/quota ownership, Q-012/Q-013 parent-vs-parent rights, Q-007 messages, Q-016 transfer & account deletion, Q-020 legal; P-060 motion values; §2 blockers (accounts, billing, region, domain, email provider); §8.3 device matrix and minimum OS versions.
