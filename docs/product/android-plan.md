# Android parity — review and plan (2026-10-14)

|          |                                                                                                                                                                                                  |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Status   | Engineering for A1–A7 built (2026-10-14) and checked on the emulator; every exit still needs a phone and the owner items in §5.                                                                  |
| Decision | D-071 (owner, 2026-10-14): no Sign in with Apple on Android; plan everything else. D-004: Android mirrors the iOS design where Figma draws only iOS.                                             |
| Scope    | Every Android gap found in the code and docs on 2026-10-14. Tự lưu (D-066) and the watch app (Q-048) stay iOS-only.                                                                              |
| Done     | As everywhere (CLAUDE.md): works end to end on dev Firebase, on a real Android phone and on iOS, Light and Night care, with code and test paths in the checklist. An emulator run is not "done". |

## 1. Where Android stands

Android has one native file, `apps/mobile/android/app/src/main/kotlin/app/childlife/child_life/MainActivity.kt`, and it only
answers `childlife/screenshot` (FB4). iOS has 33 Swift files. Seven of the eight method channels have no Android side; Dart
guards each one, so Android never crashes, it just goes without.

| Area                                           | iOS today                                                                        | Android today                                                                                   |
| ---------------------------------------------- | -------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| Widgets, lock screen, timer Live Activity (S8) | 11 widget kinds, App Intents that log with the app closed, offline queue, timers | Nothing                                                                                         |
| Background upload (10j)                        | Background URLSession, survives lock and kill; upload Live Activity; done notice | Uploads only while the app runs, one file at a time; no progress or done notice                 |
| Share into the app (10k)                       | Share extension → App Group inbox                                                | No share target                                                                                 |
| Camera (10a2)                                  | System camera, photo or video, video length cap                                  | One photo only; the row still says "Chụp ảnh hoặc quay video"                                   |
| Rule / vaccine notification actions (1f, VX 8) | "Ghi …", "Báo lại sau 15 phút", "Bỏ qua"; vaccine actions                        | No actions. Pushes have no channel (FCM "Miscellaneous"), no tag (repeats stack), no small icon |
| Video kỷ niệm progress (MM08)                  | Live Activity updated by server pushes                                           | Only the finished / failed push                                                                 |
| Sign-in                                        | Apple, email, email link                                                         | Apple button shown but "not configured" (to be hidden, D-071)                                   |
| Links                                          | Universal links dev and prod                                                     | App Links dev only; `assetlinks.json` has the dev app with a debug-key fingerprint              |
| Release                                        | —                                                                                | Release builds signed with the debug key; no Play Console; CI builds a dev debug APK only       |
| Bugs                                           | —                                                                                | "Tải về" cannot get permission on Android 7–10; minSdk 24 (docs say 26)                         |
| Testing                                        | Owner's iPhone                                                                   | Emulators only; FCM never tried on a phone; the checklist has no Android column                 |

## 2. Out of scope

- **Sign in with Apple on Android** (D-071). Google, email and email link remain. People who signed up with Apple on an
  iPhone need another way in on Android (Q-063).
- **Tự lưu kỷ niệm** (D-066). Android would need its own decision and Google Play's photo-permission declaration.
- **Wear OS** (Q-048, "not in V1").
- **Lock-screen widgets.** Android has had none since 5.0. The ongoing timer notification covers the lock screen (Q-064).
- **FB4 before Android 14.** The platform gives no screenshot signal.
- **The "Có Teddy" library filter** stays hidden on Android (D-004).

## 3. How the port is built

- **Same Dart contracts.** Every Android piece answers the channel the iOS piece answers, with the same method names,
  arguments, results and events (`childlife/uploads`, `childlife/glance`, `childlife/share`, `childlife/camera`). The Dart
  providers that return null off iOS gain an Android branch; the rest of the Dart code does not change, and its existing
  tests keep covering it.
- **Same writes.** Widget and notification actions write exactly what the iOS code writes (ids, field sets, server-time
  transforms), so the same Firestore Rules accept them and retries stay idempotent.
- **Same strings.** Native Android text comes from the `copy` maps Dart already sends (the 85 glance keys, upload and
  keepsake copy). Nothing is hard-coded in Kotlin; vi and en stay in the ARB files (D-012).
- **One session.** Widgets, the upload worker and notification actions need a Firebase ID token with the app closed.
  Android's Firebase Auth SDK keeps the session FlutterFire signs in with, so Kotlin asks it (`AuthToken.kt`); iOS shares
  a refresh token through the keychain instead (`GlanceAuth.swift`), which Android's SDK does not hand out.
- **Privacy.** No child data in logs, analytics or crash keys, native code included.
- **Tests.** Dart tests keep their fake channels; Kotlin gets JVM unit tests for request building, state stores and write
  builders (checked against the iOS field sets); each milestone ends with a run on a real Android phone against dev.

## 4. Milestones

Sizes are relative (S ≈ a day or two, M ≈ a week, L ≈ two weeks); no dates are committed. Suggested order:
**A1 → A3 → A4 → A6 → A5**, with A2's owner items started at once and A7 running alongside.

### A1 — Quick fixes and Apple off (S)

1. **Hide the Apple button on Android**: sign-in, "Tài khoản đã tồn tại" and 16d "Lưu tài khoản"
   (`auth_screens.dart`, `family/save_account.dart`). `saveAnonymousWithProvider(apple: true)` is then never reached on
   Android (it calls the iOS-only `_appleCredential()`).
2. **Apple accounts on Android** (Q-063): on the sign-in screen, a short line "Đăng ký bằng Apple trên iPhone? Đăng nhập
   bằng link gửi tới email Apple của bạn." leading to the existing email-link flow. Verify on dev first that an Apple-created
   Firebase account (including a Hide My Email address) is entered, not duplicated, by an email link to the same address.
   Apple forwards mail to Hide My Email addresses only from senders registered in the Apple Developer account (Sign in
   with Apple → email communication), so the domain that sends the sign-in link must be registered there (owner).
3. **"Tải về" on Android 8–10** (7 drops with minSdk 26): `WRITE_EXTERNAL_STORAGE` with `maxSdkVersion="29"` and `requestLegacyExternalStorage`
   (what `gal` needs).
4. **minSdk 26** in `build.gradle.kts`, as the implementation plan says.
5. **Notification basics**: a monochrome small icon (`ic_stat_notify`), FCM `default_notification_icon` and
   `default_notification_channel_id` in the manifest, channels created at start (reminders, care, family and memories,
   uploads), and the server's Android block filled in: `channelId`, `tag` (= the iOS collapse id, so repeats replace each
   other), `icon`, `color`. Server change in `firebase/functions/src/index.ts` (push helper), `reminder-rules.ts`,
   `vaccine-reminders.ts`, `spending.ts`.
6. **Honest copy until A3 / A4**: on Android the camera row reads "Chụp ảnh" and the compose footnote does not promise
   background upload.
7. **Predictive back**: `android:enableOnBackInvokedCallback="true"`.

Exit: unit tests; Android phone shows the icon, channels and replacing notices; "Tải về" works on an Android 10 device or
emulator.

#### A1 as built (2026-10-14)

- **Apple**: `appleSignInShownProvider` (`auth_screens.dart`, iOS only) hides the button on sign-in, "Tài khoản đã tồn
  tại", 16b "Vào bằng cách nào" and 16d. Android's sign-in shows "Đã đăng ký bằng Apple trên iPhone? Nhận link đăng nhập
  qua email Apple" and opens email sign-in, where "Gửi link đăng nhập" lives. Goldens keep drawing iOS (Figma) through
  the provider; `06_sign_in_android` draws Android.
- **Q-063 check** on the Auth emulator: an apple.com account, with a normal address and with a
  `privaterelay.appleid.com` address, signed in by an email link to the same address keeps its uid (`isNewUser: false`)
  and gains the `password` (email link) provider. Still to repeat on dev with a real Apple account; the sender
  registration with Apple's relay is an owner item.
- **Manifest**: `WRITE_EXTERNAL_STORAGE` (max SDK 29) and `requestLegacyExternalStorage` for "Tải về" on Android 8–10;
  `enableOnBackInvokedCallback`; FCM default icon (`ic_stat_notify`, drawn from the logo mark), accent (`notify_accent`,
  light `mintDeep`) and channel (`family`). `minSdk = 26`.
- **Channels**: `reminders`, `family` ("Gia đình & kỷ niệm"), `spending` ("Chi tiêu"), created in the app language by
  `AndroidChannels.sync` (`lib/core/platform/android_channels.dart`) from `push_registration.dart`; local reminders use
  the same icon and id. The uploads channel comes with A3.
- **Server**: every push carries `android.notification` from `androidNotification()` (`firebase/functions/src/social.ts`):
  channel by `data.kind`, icon, colour and `tag` = the iOS collapse id. Test `firebase/functions/test/android-push.test.ts`.
  Not deployed yet.
- **Copy**: on Android the camera row reads "Chụp ảnh" and the compose footnote "Ảnh tải lên khi app đang mở."; golden
  `10a2_add` renders iOS, `10a2_add_android` Android.
- **Checked**: `flutter analyze`, the full app suite, the functions unit tests, a dev debug APK on an API 37 emulator
  (sign-in without Apple, the hint opening email sign-in, the three channels). Not yet on a physical Android phone; a
  real push and "Tải về" on Android 8–10 are unverified.

### A2 — Release and store foundation (S engineering + owner)

Owner items: the upload keystore (kept in the password manager and as a CI secret, never in git), the Play Console
account and app `app.childlife`, Play App Signing, store listing, data-safety form, content rating, privacy-policy URL, an
internal-testing track, and the physical phones (implementation plan: a Pixel 7a, a Galaxy A35-class phone, one low-end
Android 10 phone).

Engineering:

1. Release `signingConfig` read from `key.properties` or environment variables, debug signing only for debug builds.
2. A shared dev keystore so dev App Links verify on every machine, not only the one that built.
3. **Prod App Links**: a `src/prod/AndroidManifest.xml` intent filter for `childlife.app` `/i/` and `/auth/link/`, and
   `assetlinks.json` entries for `app.childlife` (Play App Signing and upload-key fingerprints) beside the dev entry.
4. CI builds a signed dev app bundle; Firebase App Distribution for dev testers.
5. Google sign-in: SHA fingerprints for dev and prod once Google is enabled (not Android-only work).
6. prod `google-services.json` waits for the prod project, as on iOS.

Store publication needs explicit owner approval (CLAUDE.md); A2 only prepares it.

#### A2 engineering as built (2026-10-14)

- **Release signing** (`android/app/build.gradle.kts`): the upload key comes from `android/key.properties` (git-ignored;
  `storeFile` relative to `android/app`, `storePassword`, `keyAlias`, `keyPassword`) or the `CL_ANDROID_KEYSTORE`,
  `CL_ANDROID_STORE_PASSWORD`, `CL_ANDROID_KEY_ALIAS`, `CL_ANDROID_KEY_PASSWORD` environment variables. Without it a
  release build stops with a message instead of signing with the debug key; debug and profile builds are unchanged.
  Checked: a dev release APK built with a throwaway key carries that key's certificate, and R8 keeps the classes the
  manifest and WorkManager load by name.
- **Prod App Links**: `android/app/src/prod/AndroidManifest.xml` opens `https://childlife.app/i/…` and `/auth/link/…`,
  as `Runner-prod.entitlements` does on iOS. Verification waits for the prod `assetlinks.json` entries
  (`apps/landing/scripts/prerender.mjs`, `androidApps.prod`): the upload key and Play App Signing key SHA-256.
- **CI** (`.github/workflows/ci.yml`, `android-dev-release`): on main, a dev release APK signed with the upload key, kept
  14 days as an artifact and sent to the App Distribution group "dev-testers". It skips itself until the owner adds the
  secrets named in the workflow. An APK rather than a bundle: App Distribution only takes bundles for Play-linked apps.
- **Item 2 changed**: rather than a shared dev keystore, `androidApps.dev` lists each key that builds the dev app (the
  owner's debug key today; add the upload key's fingerprint so testers' CI builds open dev links too).
- **Left for the owner**: create the upload key, the secrets, the "dev-testers" group, Play Console with Play App
  Signing, then the fingerprints above; items 5 and 6 as written.

### A3 — Background upload (M)

A Kotlin `BackgroundUploads` behind `childlife/uploads`, so `BackgroundTransport` serves Android unchanged.

1. **Methods and events** as on iOS: `start`, `status`, `forget`, `cancel`, `cancelAll`, `faststart`; events `progress`
   (every 250 ms), `done`, `failed`, `cancelled`; the same failure codes. A non-failed job for the same storage path is
   joined, never re-sent (Storage refuses a second finalize).
2. **Transfer**: the same two-step resumable REST protocol (`X-Goog-Upload-Protocol: resumable`, then
   `upload, finalize`). Android can do better than iOS after a kill: ask the session for its offset
   (`X-Goog-Upload-Command: query`) and continue instead of restarting.
3. **Scheduling**: WorkManager, one long-running worker in a `dataSync` foreground service (Android 14 needs
   `FOREGROUND_SERVICE_DATA_SYNC`). Wi-Fi-only videos use an `UNMETERED` constraint. Android 15 caps `dataSync` at about
   six hours a day; a stopped worker is rescheduled and resumes by offset.
4. **Tokens**: an ID token lasts an hour, longer than a big queue may take with the app closed, so the worker refreshes
   from the shared session store (§3).
5. **Notices**: an ongoing progress notification in place of the upload Live Activity ("Kỷ niệm của {name}", n / total),
   then the same done, failed and Wi-Fi notices as iOS, tapping into `/memories`.
6. **faststart**: a small Kotlin remux that moves the `moov` atom ahead of `mdat` and shifts the chunk offsets, written
   from the MP4 spec, so videos start playing before they are fully downloaded, as on iOS.
7. The compose footnote goes back to promising background upload.

Exit: on a phone, lock and kill the app mid-upload and see it finish; toggle airplane mode and see it resume; a Wi-Fi-only
video waits on mobile data; no duplicate media; the quota reservation reconciles.

#### A3 as built (2026-10-14)

- **Native** (`android/app/src/main/kotlin/app/childlife/child_life/`): `BackgroundUploads.kt` (channel, job store in
  SharedPreferences `childlife.uploads`, run counts, notices), `UploadWorker.kt` (WorkManager `CoroutineWorker`, `dataSync`
  foreground, `UNMETERED` for Wi-Fi-only videos, network failures retried up to 6 times), `ResumableClient.kt` (start,
  query, upload), `FastStart.kt` (moov first, stco / co64 shifted), `AuthToken.kt` (ID token from Firebase
  Auth's own session; first written as a refresh-token exchange, replaced in A6 because Android gives Dart no refresh
  token), `Glance.kt` (the `childlife/glance` bridge: the snapshot). `MainActivity` registers them and tells the uploader when the app is in front.
- **Better than iOS on Android**: bytes go in 8 MiB requests, so what arrived stays when the connection or the app dies,
  and a later run asks Storage (`query`) and goes on from there; a 401 gets a fresh ID token from Firebase Auth once.
- **Dart**: `uploadTransportProvider` and `glanceChannelProvider` serve Android; `faststartVideo` runs on Android;
  emulator builds reach the host at `10.0.2.2` (`emulatorHost`); the `uploads` channel ("Tải lên", default importance) is
  created with the others; the compose footnote promises background upload again.
- **Tests**: JVM unit tests `android/app/src/test/.../FastStartTest.kt`, `ResumableClientTest.kt`
  (`./gradlew :app:testDevDebugUnitTest`); `integration_test/background_upload_test.dart` on the Android emulator against
  local Auth + Storage emulators on their own ports (9188 / 9491).
- **Checked on the API 37 emulator**: a 3 MB file uploads with progress and is not sent twice; a 300 MB upload killed
  (`kill -9`) at 75.5 MB was picked up by a new process at 75,497,472 bytes and finished with the right MD5; the progress
  notice ("Kỷ niệm · Đang tải 0/1 mục", bar, "Xong sẽ báo bạn"). The Storage emulator's own `query` answers were checked with
  curl. Not yet: a real phone, Wi-Fi-only on mobile data, the full memory flow (the shared emulator suite would be reset
  by `memory_flow_test.dart`).

### A4 — Camera and sharing into the app (M)

**Camera.** Android's system camera has no combined photo-and-video mode, so on Android the row opens a two-choice
sheet, "Chụp ảnh" / "Quay video" (Q-066), using `image_picker` (`pickImage` / `pickVideo` with `maxDuration` from
`videoMaxDurationSec`). The result is shaped like the iOS `capture` result (path, kind, name, width, height,
durationMs; photos upright), and the existing size check applies. The in-app camera (10a3) is a separate, cross-platform
item.

**Share target.** `MainActivity` takes `ACTION_SEND` / `ACTION_SEND_MULTIPLE` for images and videos and copies the shared
content into `filesDir/ShareInbox/share_{uuid}/` with a manifest in the iOS format, at once (content-URI grants are
temporary), capped at `mediaItemsPerAdd`. Instead of a native share sheet, the app opens a Flutter sheet with the same
choices as the iOS extension (baby, Chỉ ba mẹ / Gia đình, Báo cho gia đình), then enqueues through the existing drain
(Q-065). `childlife/share` gets `takeInbox` and `finish` on Android; `setTargets` is not needed.

Exit: share 1, 30 and 31 items from Google Photos and Files on a phone; signed out; no baby.

#### A4 as built (2026-10-14)

- **Camera**: Android's add sheet (10a2) has "Chụp ảnh" and "Quay video" (new line icon `assets/icons/video.svg`);
  video goes through `image_picker` `pickVideo` with the server's length cap, then `childlife/camera` "probe"
  (`MediaProbe.kt`, MediaMetadataRetriever) fills length and upright size. A refused camera permission says so with "Mở
  Cài đặt", as 11c does. The sheet's result for it is `cameraVideo` (`video` is "Video kỷ niệm").
- **Share target**: `ShareActivity` (translucent, SEND / SEND_MULTIPLE for `image/*` and `video/*`) forwards the items,
  with their read grant, to `MainActivity`; `SharedInbox.kt` copies them into `files/ShareInbox/share_{uuid}/` with an
  iOS-format manifest (no baby, `skipped` count; length, size and date from MediaProbe or MediaStore) and tells Dart
  ("received"). `share_inbox.dart` `offerSharedBatch` asks for the baby when there are several Cùng nuôi babies, opens
  Kỷ niệm and "Soạn & chia sẻ" (10h) with the files; `finish` removes the manifest only (the queue may still be copying),
  and folders without one go after a day.
- **Tests**: `test/features/share_inbox_test.dart` (a share without a baby waits for the app), goldens
  `10a2_add_android` (two camera rows), `foundations` (the new icon).
- **Checked on the API 37 emulator** against the shared emulator suite (a test parent and baby added, nothing reset): a
  photo shared with a read grant opened the app on Kỷ niệm with "Soạn & chia sẻ"; "Tải lên 1 mục" went through
  WorkManager and the server marked it ready; the photo shows under Tuần 7; "Quay video" asks for the camera permission
  and, refused, shows the Settings message. Found and fixed on the way: a shell share without a grant crashed
  ShareActivity (now opens the app without the items); "Quay video" first opened "Video kỷ niệm" (same sheet result).
  Not yet: a recording on a real camera, sharing 30+ items, a share while signed out.

### A5 — Widgets and the ongoing timer notification (L; the Android half of SP-1)

1. **Jetpack Glance widgets** mirroring iOS (D-004): Bình sữa, Bú mẹ, Giấc ngủ, Thay tã (small), the quick 4-tile widget
   (medium), Hôm nay (large), and the camera / library shortcuts. Read-only members see no "+" buttons, as on iOS.
   Android widget layouts are not in Figma; screenshots go to the owner for review.
2. **Bridge**: `childlife/glance` on Android with `setSession`, `clearSession`, `setSnapshot`, `refresh`; the snapshot JSON
   unchanged, kept in SharedPreferences.
3. **Actions** (Glance `ActionCallback`, no app launch): log bottle, log diaper, undo (5 s), start, end, switch side and
   cancel timers, with the exact iOS writes (`r_<hex>` ids, `r_{sessionId}` for timer records, one timer doc per type,
   REQUEST_TIME transforms; 409 and FAILED_PRECONDITION count as done). Offline commits queue in SharedPreferences and are
   drained by the widgets' update and on app resume.
4. **Running timers**: Glance cannot tick text, so the timer views use a `RemoteViews` `Chronometer`.
5. **Ongoing timer notification** for sleep and breastfeeding (the lock-screen part of the Live Activity): a chronometer
   from `startedAt`, "Kết thúc" and "Đổi bên" actions handled by a receiver with the same writes, tap → `/care/timer/{type}`.
   Android 16 Live Updates later.
6. **Deep links**: an intent filter for `{applicationId}://app/…`, matching iOS, so `/today?log=…`, `/care/timer/…`,
   `/care/record/…` and `/memories?add=…` reach go_router unchanged.

Exit: on a phone, log from a widget with the app killed and offline, then see it sync; undo; timers from the widget and the
notification; signed-out and read-only states; Light and Night care.

#### A5 as built (2026-10-14)

- **RemoteViews, not Jetpack Glance.** Plain `AppWidgetProvider`s with XML layouts (`widget_small`, `widget_quick`,
  `widget_today`, `widget_shortcut`) keep the app free of Compose and give the `Chronometer` running timers need. Eight
  kinds, as listed in item 1; art is generated from the app's SVGs (`tool/android_widget_art.py`), the few strings shown
  before Dart's first snapshot from the ARB files (`tool/android_widget_strings.py`, vi default and `values-en`).
  Colors come from `widget_colors.xml` with a `values-night` twin; on Android 12+ text colors are set with
  `setColorInt(light, night)` so a widget follows the system theme without a redraw (`setColorStateList` with a resource
  made the launcher fall back to the initial layout). Resource ids are listed by hand (no reflection), so shrinking is safe.
- **Bridge and data**: `Glance.kt` (`childlife/glance`) keeps the snapshot JSON; `GlanceData.kt` reads it (`Snap`, the iOS
  `GlanceFormat`); native additions (`logged` for undo, `pending`) survive Dart's next write. `setSession` is a no-op
  on Android: `AuthToken.kt` asks Firebase Auth for an ID token.
- **Actions**: `GlanceActions.kt` writes what `ios/Shared/GlanceActions.swift` writes, through Firestore REST
  `documents:commit` (`GlanceFirestore.kt`): log bottle / diaper, undo within 5 s, start, end and switch side. Offline or
  signed-out commits queue in SharedPreferences ("Chưa đồng bộ n") and are retried on app resume (`refresh`) and by the
  15-minute `GlanceRefreshWorker`. Undo redraws on time through a `Handler` plus a WorkManager backup (inexact alarms
  were late). Read-only members get no buttons; widget taps open the same routes as iOS (`/today`, `/today?log=…`,
  `/care/timer/…`, `/care/record/…`) through Flutter's own deep-link handling.
- **Ongoing timer notification** (`TimerNotice`, channel "Bộ đếm giờ", low importance): a chronometer from the start;
  sleep has "Thức dậy" and "Sửa giờ", breastfeeding "Đổi bên" and "Kết thúc"; tap → `/care/timer/{type}`.
- **Found on the way** (Dart, iOS too): a timer link opened after the timer ended elsewhere left the timer screen blank
  forever; it now goes to Hôm nay after 3 s (`timer_screens.dart`; test in `test/features/timer_test.dart`).
- **Tests**: `GlanceTest.kt` (record write field set, patch and delete, commit outcomes, snapshot reading and formatting).
- **Checked on the API 37 emulator** with the shared emulator suite: every kind renders, Light and dark system theme; a
  bottle logged from the widget, its undo bar gone after 5 s, and undo removing the record; sleep started and ended from
  the widget and from the notification wrote the documents the app reads (Rules accepted them); a feed started, switched
  to the right side and ended from the widget wrote `r_{session}` with both sides, as iOS; "Bẩn" logged in airplane mode
  showed "Chưa đồng bộ · 1" and went up with its original time when the app next opened; taps open Hôm nay, a record and a
  stale timer link. Not yet: a phone, a queued log sent by the 15-minute worker without opening the app, the signed-out
  and read-only states, the owner's review of the layouts (not in Figma).

### A6 — Notification actions and video progress (M)

1. **Rule and vaccine actions.** A system-drawn FCM notification cannot carry action buttons on Android, so the server
   sends these pushes to Android devices (known from `users/{uid}/devices/*.platform`) as high-priority data messages with
   the localized title and body. The app's background handler shows them through `flutter_local_notifications` with the iOS
   actions: "Ghi …" (opens the log sheet), "Báo lại sau 15 phút" and "Bỏ qua" (call `answerRuleReminder` from the background
   isolate), and for vaccines "Xem lịch tiêm", "Nhắc lại sáng mai" (`snoozeVaccine`), "Dời lịch". Tag = the iOS collapse id.
2. **Video kỷ niệm progress.** `attachMemoryStoryLive` on Android stores only the FCM token. The server sends a data message
   on the same triggers as the Live Activity (status, step, each 10 %), and the app keeps an ongoing progress notification
   ("Đang ghép ảnh…", n %), replaced by the finished or failed notice; tap → the job.

Exit: on a phone with the app killed: snooze, skip and log from a rule reminder; the vaccine actions; a video's progress
notification from queued to finished.

#### A6 as built (2026-10-14)

- **Server**: `pushPayload()` (`firebase/functions/src/social.ts`) builds every FCM message. Rule and vaccine reminders
  set `androidDraws`: iOS gets the alert with its category in `aps` (no top-level notification), Android gets title,
  body and tag as data with high priority. `attachMemoryStoryLive` takes a null token (Android, FCM only), and
  `keepsakeJobChanged` sends Android the same moments as the Live Activity through `LiveSender.android` (data:
  status, step, percent). Tests: `functions/test/android-push.test.ts`, `tests/keepsake-jobs.integration.test.ts`
  ("MM08 on Android").
- **Native**: `Push.kt` — `PushService` (extends and replaces the firebase_messaging plugin's service) draws reminders
  with the iOS actions (labels from the glance copy: `rule.*`, `vx.*`) unless a rule rings with the app in front (Flutter
  shows 1g); `PushActionReceiver` answers "Báo lại sau 15 phút", "Bỏ qua lần này" and "Nhắc lại sáng mai" with
  `CallableClient` and an ID token from `AuthToken`; `PushLaunch` (`childlife/rules`) hands Flutter the tapped push and its
  action ("log", "view", "move"); `KeepsakeProgress` (`childlife/keepsakeLive`) keeps the ongoing progress notice and
  removes it at the end. Debug builds also accept `adb shell am start ... --es app.childlife.debugDraw '<data>'` to draw
  a push, since the emulator suite sends none. Tests: `PushActionsTest.kt`.
- **Dart**: `push_registration.dart` routes Android's tapped pushes through `_open` as iOS ones; `KeepsakeLive` runs on
  Android and attaches the job by FCM; `glance_bridge.dart` sends Android only sign-outs. Test:
  `test/features/keepsake_live_test.dart`.
- **Checked on the API 37 emulator** with the shared emulator suite: a drawn rule reminder shows "Log a feed · Remind
  me in 15 minutes · Skip this time"; "Remind me…" on a real ringing rule answered 200 and the server snoozed it
  (`pendingDueAt` cleared, `snoozedUntil` +15 min) without opening the app; "Log a feed" opened the app on the feed sheet;
  the video progress notice ("Video kỷ niệm · Đang ghép video · 42%") showed and went away at the end. Not yet: a real
  FCM delivery on a phone (needs dev FCM and a signed-in dev account), the vaccine actions on a device.
- **Deployed to dev** (2026-10-14): every function that sends pushes (`ringRuleReminders`, `ringVaccineReminderPush`,
  `deliverFamilyNotice`, `addRecurringExpenses`, `spendingBudgetAlert`, `runSpendingImport`), `onKeepsakeJobWritten`,
  `attachMemoryStoryLive`, and D-070's `createMemorySession` and `releaseStaleMemoryUploads`; the callables answer JSON.

### A7 — Verification and tracking (alongside)

1. An Android column in `figma-coverage-checklist.md` (or a per-row note convention, owner's choice) so Android status
   stops hiding in free text; rows for vaccination, spending, first aid, Kỷ niệm 2.0, Góp ý and app updates, which have none.
2. A device pass per milestone on the owner's Android phone: sign-in and invites through App Links, care logging, push
   reminders, uploads, share, widgets, notifications, Light and Night care.
3. The 13 Tôi / Câu chuyện rows proven on the Android emulator only still need their iOS run.

#### A7 as built (2026-10-14)

- The checklist takes the per-row note convention rather than a new column (its rules now say how), and §C has one row
  per Android milestone (A3–A6) with code and test paths, all ◐ until a phone pass.
- §B gains sections 15–20 (Tiêm chủng, Chi tiêu, Sơ cứu & nội dung tiện ích, Kỷ niệm 2.0, Góp ý & đánh giá, Cập nhật ứng
  dụng): 117 rows from the saved Figma extracts, 85 with code (◐), none ticked.
- Items 2 and 3 need the owner's Android phone and an iOS run.

## 5. Owner actions

| Item                                                      | Needed for             |
| --------------------------------------------------------- | ---------------------- |
| One or more physical Android phones                       | Every milestone's exit |
| Upload keystore, Play Console, Play App Signing           | A2, prod App Links     |
| Store listing, data-safety form, content rating           | Store release          |
| Review of Android widget and notification screenshots     | A5, A6                 |
| Answers to Q-063 – Q-066                                  | A1, A4, A5             |
| Register the mail sender with Apple's private email relay | A1 (Q-063)             |

## 6. Questions answered (owner, 2026-10-14)

Q-063 – Q-066 were answered "yes" as proposed: Apple accounts sign in on Android through an email
link to their Apple email; the ongoing timer notification and home-screen widgets stand in for
lock-screen widgets; sharing into the app opens Child Life with the iOS choices in a sheet; the
Android camera offers "Chụp ảnh" / "Quay video".
