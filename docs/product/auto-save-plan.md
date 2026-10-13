# Tự lưu kỷ niệm — review and plan (2026-10-13)

Source: Figma page **"v1.0 - improvement"** `345:35701`, rows "AS · Tự lưu kỷ niệm · Beta miễn phí" `479:7357`
(AS01 – AS20, AS07N / AS12N) and "AS · Lần mở app sau" `486:7158` (AR01 – AR08), extracted in
`docs/discovery/figma-extract/27-auto-save.md`. Owner request: a future premium feature, offered first as a
free beta. The flow is: scan new photos → analyse on the phone → group near-duplicates → rank quality →
parents confirm → upload.

Status (2026-10-13): **M1 (4ebc0e0), M2 (0423d5f) and M3 (c3dd71f) committed; M3's functions and the portal deployed to dev; `auto_save` still off; nothing tried on a phone yet** (§9.1 – §9.3). Owner decisions are D-066. Engineering proposals P-146 …
P-150 need the owner to confirm them. Open questions are Q-054 … Q-058 and design gaps are G-102 … G-106
(business map).

## 1. What the design settles

- **Nothing uploads or shares on its own.** Parents review first; the library is read-only ("App không xoá hay
  sửa gì trong thư viện"). AS20 (auto-upload into a private area) is a future idea and not part of this beta.
- **On per baby, by a parent only.** A caregiver is blocked (AS03). Each baby needs 3 – 5 sample photos, taken
  from Kỷ niệm or the device library. A baby without samples is paused.
- **Checks have no fixed schedule.** The app checks silently on open (AR01) and in the background when the OS
  allows. Each check only looks at new files, and resumes if interrupted. Scan progress and upload progress
  are shown separately.
- **Upload defaults:** **Chỉ ba mẹ**, **no family notice**, timeline by capture date. These differ from D-001
  on purpose, which D-066 records.
- **"Đã có"** dims a duplicate of something already in Kỷ niệm. **"Trên iCloud"** marks an original that is
  not on the phone yet. When space runs short, the app offers "Tải trước 3 ảnh vừa đủ" (AS18).
- **"Để sau" only hides; "Bỏ qua lần này" drops the batch** (with Hoàn tác).
- **Push:** at most once a day, never in quiet hours (AR03).

## 2. Owner decisions (D-066, 2026-10-13)

| # | Question | Owner | What it means |
|---|---|---|---|
| 1 | How to show near-duplicate groups in AS07 | "Tự bạn đề xuất" | Engineering proposal **P-146** (§3) |
| 2 | Beta or 7-day trial | "Beta đi", "beta ko cần 7 ngày" | A **free beta with no end date**. The 7-day trial waits for the paid plan (Q-058). Access is a rollout flag (**P-148**, §5) |
| 3 | Platforms for the beta | "Chỉ iOS" | iOS only. Android is not built for this feature until a later decision. This is an exception to "done = iOS and Android" for this feature only |
| 4 | Separate consent for face analysis | "Cần thêm đồng ý, nhưng làm sao để user hiểu là không lưu hình ảnh bé, được bảo mật ở phía người dùng" | Its own consent card in plain language that leads with "no photos of the baby are kept, it stays on this phone". Engineering proposal **P-147** (§4); legal review is Q-055 |
| 5 | Settings and samples per device or per family | "Theo từng máy" | Settings, samples, face data, scan cursor and suggestions stay on the device. They are not synced and not uploaded |
| 6 | AS05 "Tiếp tục tải khi app chạy nền" | "Bỏ luôn option tắt tải nền, mặc định là tải nền" | **Always on**, the same as manual uploads (background URLSession, 10j). The switch is removed from AS05 and AS19 (G-104) |
| 7 | A photo with several babies | "Ảnh có nhiều bé luôn", then "nếu khó quá thì chỉ cần ảnh có 1 bé" | **One baby per photo in v1**, AS09 single choice as drawn. Several babies costs a copy per baby (memories and Storage paths carry one `babyId`, so the quota counts it twice), state per photo × baby, and twice the wrong suggestions while matching is loose. The ledger is keyed so it can come later (**P-149**) |
| 8 | How accurate recognition must be in v1 | "Bản đầu tiên ko cần bắt buộc nhận dạng đúng. Chấp nhận gợi ý ảnh để ba mẹ duyệt" | No go / no-go spike. v1 matches with Apple Vision only and accepts misses and wrong guesses; the parent's review is the safety net (**P-149**, §6.1) |

The first draft of this table (earlier the same day) had a 7-day trial from setup, a background switch kept on
by default and several babies per photo. The owner's later answers above replace it.

## 3. Grouping and ranking in the review grid (P-146)

The design pre-selects every suggestion (AS07: 18 items, about 186 MB). The family quota is 10 GB, so the
ranking step should cut what gets uploaded by default. Proposal:

- **Moments.** Within a capture day, suggestions are split into moments: a gap of more than about 3 minutes
  starts a new moment. Inside a moment, photos are grouped by Vision `FeaturePrint` distance. A burst
  (`burstIdentifier`) is always one group. Thresholds live in `config/limits` so they can be tuned without
  a release.
- **The best photo leads.** In each group, the photo with the best score is shown as the tile and is
  **pre-selected**. Two are pre-selected when the group has 6 or more photos and the second scores close to
  the first. Videos are not grouped in v1 and stay pre-selected one by one.
- **Stack tile (G-102).** A group shows one tile with a small stacked edge and a "+4" count. Tapping it opens
  the group in the existing viewer (AS08) with the best photo first. The other photos there start unselected,
  and the parent can tick any of them. The sticky summary counts selected items and size as before, plus one
  line "Đã gộp 23 ảnh giống nhau" so it is clear nothing was thrown away.
- **Score** (relative within a group, never across groups, as Apple advises for Capture Quality):
  Face Capture Quality of the matched baby's face + sharpness + face size; Aesthetics `overallScore` on
  iOS 18+; bonus for `isFavorite` and for the burst photo the user picked. A photo where `isUtility` is true
  (receipts, documents) is dropped before matching. The weights live in `config/limits`.
- **Nothing is hidden.** "Tất cả · n" still counts every suggestion. "Bỏ qua lần này" still covers the whole
  batch, grouped or not.
- **AR05 quick sheet** uses the same groups: one tile per group, pre-selected, with the CTA count based on the
  selection.

## 4. Face-analysis consent (P-147)

The goal is a consent the parent understands in a few seconds and trusts. What worries parents is that a
company keeps pictures of their child's face. The copy answers that first: **Tự lưu keeps no photos of the
baby, and what it remembers stays on this phone.** A child's facial features are still biometric data (Law
91/2025/QH15 on personal data, in force 1/1/2026), so the consent is its own unticked box and is not bundled
with the photo-library prompt.

**Where.** AS05 "Bước 3/3" keeps its cards, but only one of them needs a tick (G-103):

1. **Nhận ra {bé} ngay trên máy này** (new, with a checkbox, unticked).
2. **Cho Child Life xem thư viện ảnh** (as drawn; the CTA leads to the iOS prompt).
3. **Chỉ tải lên mục bạn duyệt** (information only; the background switch is gone, D-066 #6).

The CTA "Cho phép xem ảnh" works once box 1 is ticked. "Để sau · thêm ảnh thủ công" stays. Face data is only
computed after the tick, so AS04 can come first.

**Copy, card 1** (Vietnamese source for owner and design review):

> **Nhận ra {bé} ngay trên máy này**
> Child Life so khuôn mặt trong ảnh mới với ảnh mẫu của {bé} để gợi ý. Mọi việc diễn ra trên điện thoại của bạn.
> ✓ Không lưu ảnh nào của {bé}: ảnh mẫu vẫn nằm trong Kỷ niệm hoặc thư viện của bạn.
> ✓ Chỉ ghi nhớ một dãy số về khuôn mặt, nằm trên máy này, không gửi lên Child Life.
> ✓ Child Life không xem được, không dùng cho quảng cáo. Bạn xoá được bất cứ lúc nào.
> ☐ Tôi đồng ý để Child Life nhận ra {bé} trên máy này
> [Child Life lưu gì?]

English draft (ARB): "Recognise {baby} on this phone only" · "Child Life compares faces in new photos with
{baby}'s sample photos to make suggestions. It all happens on your phone." · "No photos of {baby} are kept:
your samples stay in Memories or your library." · "Only a list of numbers about the face is remembered, on this
phone, never sent to Child Life." · "Child Life can't see it and never uses it for ads. Delete it any time." ·
"I agree to let Child Life recognise {baby} on this phone" · "What does Child Life keep?"

**Card 3:** "Ảnh, video bạn bấm duyệt được tải lên Kỷ niệm như khi bạn tự thêm, và vẫn tải tiếp khi bạn khoá
máy." (EN: "Photos and videos you approve are uploaded to Memories just like when you add them yourself, and
keep uploading when your phone is locked.")

**"Child Life lưu gì?" sheet** (three short blocks, no legal wording):

- **Trên máy này:** dãy số về khuôn mặt từ ảnh mẫu và ảnh bạn đã duyệt; danh sách ảnh đã kiểm tra hoặc đã bỏ
  qua; cài đặt Tự lưu. Không nằm trong bản sao lưu iCloud. Gỡ app là xoá hết.
- **Không bao giờ:** giữ bản sao ảnh mẫu hay ảnh trong thư viện; gửi dữ liệu khuôn mặt lên máy chủ Child Life
  hay cho bên khác; dùng cho quảng cáo.
- **Tải lên Child Life:** chỉ ảnh, video bạn bấm duyệt, với quyền "Ai thấy" bạn chọn (mặc định Chỉ ba mẹ).
- Footer: "Xoá trong Cài đặt Tự lưu › Xoá ảnh mẫu và dữ liệu gợi ý. Tắt Tự lưu thì dữ liệu trên máy tự xoá sau
  30 ngày." and a link to the privacy policy section.

The same reassurance appears once more where people look later: AS02 adds "Ảnh được kiểm tra ngay trên máy,
không gửi đi." to its footnote, and AS19 shows "Dữ liệu nhận diện chỉ nằm trên máy này." above the red delete
link.

**What engineering guarantees** (the copy promises only these):

- No copy of a sample photo or of a face crop is written to disk. Samples are kept as references (a Kỷ niệm
  `mediaId` or a PhotoKit `localIdentifier`); pixels are read, turned into numbers and dropped.
- Face data (prints, scores, which photo matched which baby) never leaves the device. None of it goes into
  Firestore, Storage, logs, analytics or crash keys (CLAUDE.md).
- The store lives in the app's own Application Support (not the App Group), is marked
  `isExcludedFromBackup`, and uses `NSFileProtectionCompleteUntilFirstUserAuthentication` so the background
  task can read it. Removing the app removes it.
- "Xoá ảnh mẫu và dữ liệu gợi ý" (AS19) and withdrawing the consent delete it at once. Turning Tự lưu off
  keeps it for 30 days, so turning it back on is easy, and then deletes it.
- The consent record stays on the device: copy version and time. Analytics gets only an aggregate count of
  consents and withdrawals.
- Apple 5.1.2(vi): face data is used for nothing but this feature. It never leaves the device, so the App
  Store privacy label declares no collection; the privacy policy still describes it.

## 5. Beta access (P-148)

- **Free, no end date** (D-066 #2). There is no trial clock, no entitlement document and no "đến ngày" copy in
  the beta. The badge "Beta miễn phí" stays as drawn.
- **Who gets it:** the rollout flag `auto_save` in `config/flags` (shape in `packages/contracts/src/config.ts`,
  mirrored to `publicConfig`), staged off → internal (staff families) → percentage → every iOS user. The flag
  is also the kill switch: off hides the entry (AS01) and stops scanning; saved memories and pending uploads
  are untouched. Android never shows the entry.
- **When a paid plan comes (Q-058):** beta users get an in-app notice at least 14 days ahead. The 7-day free
  trial then becomes the StoreKit introductory offer; unlocking a digital feature must use IAP (App Store
  guideline 3.1.1). Saved memories are never affected. The entitlement model (`source: beta | storekit`) is
  designed then, not now.
- **Measured with counts only** (no baby data, CLAUDE.md):
  - Funnel AS02 → AS05, and how many tick the face consent.
  - Full vs limited photo access.
  - Approve, unselect and "Không phải ảnh của bé" rates (how often suggestions are wrong).
  - Missed photos: photos a parent later added by hand that the scan had seen but not suggested, counted on
    the device.
  - How often each setup is still used after 7 and 30 days.

## 6. Architecture (iOS)

A native Swift module next to `BackgroundUploads.swift` and `CameraCapture.swift`, called from Flutter over a
method channel. Flutter draws the screens. Analysis results live in a local SQLite store on the device.

| Step | API | Notes |
|---|---|---|
| New files | `PHPhotoLibrary.fetchPersistentChanges(since:)` (iOS 16+, app targets 16.1) | Skip screenshots, hidden photos and files Child Life saved itself (§7) |
| Quick filter | `burstIdentifier`; Aesthetics `isUtility` (iOS 18+) | Receipts and documents out; a burst is one group |
| Faces | `VNDetectFaceRectanglesRequest` on a ~512 px thumbnail, `isNetworkAccessAllowed = false` | iCloud originals are only fetched for upload |
| Which baby | Vision `FeaturePrint` of each face crop vs the baby's samples | §6.1; a licensed face model later (Q-054) |
| Groups and rank | Moments + `FeaturePrint` + scores | §3 |
| Video | 3 – 5 frames for matching; no ranking in v1 | |

### 6.1 Recognising the baby in v1 (P-149)

- **Good enough, not exact** (D-066 #8). Suggestions are proposals and the parent's review catches mistakes.
  There is no go / no-go spike before the beta; the beta measures accuracy (§5) and that decides Q-054.
- **Apple Vision only.** PhotoKit has no public API for the Photos "People" album, and pretrained InsightFace /
  ArcFace weights are non-commercial only, so v1 uses no third-party model:
  1. `VNDetectFaceRectanglesRequest` finds the faces; faces below a minimum size are skipped.
  2. Each face crop (with a margin, turned upright using the face's roll) gets a
     `VNGenerateImageFeaturePrintRequest` print.
  3. The print is compared with the sample prints of each enabled baby. The score is the closest sample
     distance, with a penalty when the face is also close to a "Không phải ảnh của bé" example.
  A general-purpose print on a face crop is expected to tell a baby from adults better than siblings close in
  age apart. That is the accepted trade-off for v1, and the beta numbers show how far it goes.
- **Samples grow with the baby.** The 3 – 5 samples from AS04 start the set. Each approved photo adds the
  matched face as a sample; the set favours recent ages (for example the last 90 days, a few per month) so
  the face the baby has now counts most. "Không phải ảnh của bé" adds the face as a negative example.
- **Loose threshold, best first.** The threshold leans towards suggesting too much (kept in `config/limits`),
  and the review lists the most likely photos first. The wording stays "Có thể có {bé}".
- **One baby per photo** (D-066 #7). Every face is matched; the photo goes to the baby whose face scores best,
  and AS09 (single choice, as drawn) moves it. The ledger keys rows by (`localIdentifier`, `babyId`) so
  several babies per photo can come later without a migration.
- **Videos:** 3 – 5 frames are matched like photos; the video is suggested when one frame matches.
- **Swappable.** The matcher sits behind a small `FaceMatcher` protocol, so a licensed face model (Q-054) can
  replace the Vision print without touching the rest of the pipeline.

### 6.2 When it runs

- **On open (AR01).** Small batches. It yields when the app goes to the background and slows down under high
  `thermalState` or Low Power Mode.
- **In the background.** `BGProcessingTask`, which iOS usually runs while charging. This needs `processing`
  in `UIBackgroundModes`; `Info.plist` has only `remote-notification` today. The AR03 push will mostly arrive
  after a night's charge, so the design's "thời điểm không cố định" is honest.
- **First scan** looks back 30 days, or to the birth date if the baby is younger. This gives a result right
  after setup.

## 7. Dedupe and the download loop (P-150, must ship before the beta)

- Uploads are converted to JPEG and stripped of metadata (P-033), so the server cannot compare bytes. Instead,
  a **ledger on the device** maps PhotoKit `localIdentifier` → Child Life `mediaId`. `PickedMedia`
  (`upload_queue.dart`) does not keep the library id today, and manual picks should start recording it too.
- **Items another family member uploaded:** match capture time + pixel size against the baby's MediaItems
  (metadata only). This is what drives "Đã có".
- **Loop:** photos saved to the phone from Child Life (`album_screens.dart`, `media_viewer.dart` via `Gal`)
  would come back as "new". `Gal` returns no `localIdentifier`, so saving to the library moves to a small
  native call that records the id in the ledger.

## 8. Upload pipeline

Tự lưu is one more source for the existing queue (`QueueBatch`, `createMemorySession`,
`BackgroundUploads.swift`). It adds:

- A `source: autoSave` flag on each memory. It powers "Đã lưu từ Tự lưu · 42 mục" and the metrics.
- The "Đang lấy tệp gốc từ iCloud" state.
- Partial upload when space is short, using the existing `QuotaReservation`. Photos come before videos, then
  the best-ranked items first.
- The 30-items-per-add rule (R-102). A larger approval is split into several sessions on its own.
- **One baby per photo** (P-149). A memory carries a single `babyId`, so several babies would need a copy per
  baby (counted twice against the quota unless stored objects can be shared). That waits until after the beta.
- Approved items always keep uploading in the background through `BackgroundUploads.swift`, as manual uploads
  do. There is no switch (D-066 #6).

## 9. Build steps

1. **M1:**
   - The ledger and dedupe, and the `Gal` loop fix (P-150).
   - The Vision matcher behind `FaceMatcher` (P-149) and the scan pipeline on app open.
   - AS01 – AS19 with grouping (P-146) and the consent card and sheet (P-147); AS05 and AS19 without the
     background switch.
2. **M2.** Background scan, push and AR01 – AR08.
3. **M3:**
   - The `auto_save` flag (P-148).
   - Metrics.
   - Internal, then the beta.
4. **Later:**
   - A licensed face model (Q-054).
   - Several babies per photo.
   - The paid plan with its 7-day trial (Q-058).
   - Android, after its own decision and Google Play's photo-permission declaration.

### 9.1 M1 as built (2026-10-13)

Code: `apps/mobile/lib/features/auto_save/` (engine, store, native wrapper, controller, setup, home and
settings, review), `apps/mobile/ios/Runner/AutoSave.swift`; ledger hook in `upload_queue.dart`
(`PickedMedia.assetId`), "Tải về" through `library_save.dart`; routes under `/memories/auto-save`.
Tests: `test/features/auto_save_engine_test.dart`, `auto_save_test.dart`, `auto_save_screens_test.dart`.
The iOS dev flavour builds for the simulator.

Where it differs from the frames, and why:

- **Who sees it:** iOS only; dev builds, or wherever `publicConfig/flags.auto_save` is on. The server flag
  key is M3 (adding it to `flagKeys` makes today's `config/flags` documents fail to parse, so it needs a
  tolerant schema or a reseed first).
- **AS01 placement:** the app's Kỷ niệm tabs are Ảnh · Album · Nhật ký · Câu chuyện (D-052), not
  "Dòng thời gian / Ảnh & video"; the entry card sits at the top of Ảnh and Nhật ký, and the owner kept it
  there (D-066: "giữ nguyên như cũ"). AS10 says "Nhật ký,
  theo ngày chụp" for the same reason.
- **AS11:** the existing upload queue screen (10i) is used; uploads from Tự lưu are ordinary batches.
  Originals are read (and fetched from iCloud) before the batch is queued, with "Đang chuẩn bị x/y…" on the
  AS10 button, instead of a per-row "Đang lấy tệp gốc từ iCloud".
- **AS12 "Đã lưu từ Tự lưu":** counted on this phone; memories carry no `source` field on the server yet.
- **AS13:** iOS does not tell the app how many photos were shared, so it reads "Đang xem những ảnh bạn đã
  chọn" without the count.
- **AS19 "Chỉ tải qua Wi-Fi":** the app-wide video rule (the Q-056 proposal), labelled "Video chỉ tải qua
  Wi-Fi".
- **Not yet:** background checks, the push and AR01 – AR08 banners (M2); videos are matched on their
  poster frame only; face crops are not turned upright; matching and grouping thresholds are guesses in
  `AutoSaveTuning` until beta photos calibrate them; Tự lưu data stays on the phone after sign-out (the
  ledger and samples of the previous account; to decide).

### 9.2 M2 as built (2026-10-13)

- **Background checks (AR03):** `BGProcessingTask` `childlife.autosave.check` (`processing` in
  `UIBackgroundModes`, listed in `BGTaskSchedulerPermittedIdentifiers`), asked for again after every check,
  about an hour later at the earliest; iOS picks the time. The check is the same Dart code: the running
  app's engine when it is alive, otherwise a headless engine on `autoSaveBackground`
  (`lib/features/auto_save/auto_save_background.dart`), which has no Firebase and no session and uses the
  babies set up on this phone. Turning Tự lưu off or deleting its data cancels the request.
- **Notification (AR03):** posted by the phone, text written in Dart in the app's language: "Có 8 ảnh mới
  có thể có Teddy" / "Chạm để xem và chọn ảnh muốn lưu vào Kỷ niệm.". Only when AS19 "Báo khi có ảnh mới"
  is on, at most one a day. The app has no quiet-hours setting, so Tự lưu uses the reminders' night
  (22:00 – 06:00, "Không nhắc ban đêm"); something found at night is told at 07:00 instead of dropped.
  Nicknames are kept on the phone for this. The tap opens AS07 (`…://app/memories/auto-save/review`).
- **AR02:** the Hôm nay banner sits under the title, above the customisable sections; "Để sau" or × hides
  it until new suggestions arrive. A dot on the Kỷ niệm tab while suggestions wait for the selected baby.
- **AR05 / AR08:** the quick sheet shows the newest 8 groups with their best photo ticked, the defaults
  "Nhật ký · Chỉ ba mẹ / Không báo cho gia đình" with "Đổi" (AS10), "Xem lớn từng ảnh" (AS07) and "Bỏ qua
  lần này" with Hoàn tác.
- **AR06 / AR07:** the existing upload pill and its "Đã tải xong" state, not a separate toast.
- Not verified on a phone: background launches need a real device (iOS rarely runs them in the
  simulator); try with Xcode's `e -l objc -- (void)[[BGTaskScheduler sharedScheduler]
  _simulateLaunchForTaskWithIdentifier:@"childlife.autosave.check"]` while paused in the debugger.

### 9.3 M3 as built (2026-10-13)

- **Flag `auto_save`** in `packages/contracts/src/config.ts`, default off with scope `internal`. `flagsSchema`
  now fills a missing key with its default, so today's `config/flags` documents keep parsing (and every kill
  switch keeps working) after the key is added; the portal's A10 lists it with its labels.
- **`getFeatureAccess`** (`firebase/functions/src/features.ts`): for an active member and baby, whether
  `auto_save` is on for that family (Cùng nuôi only; `internal` from the family document, `percent` from
  the AI-drafts bucket). The app asks for the selected baby and keeps the answer on the phone; checks only
  run for babies answered yes, and a "no" for every baby cancels the background check. Debug runs against
  dev skip the question; release builds, dev included, follow the flag.
- **"Ai được dùng" in A10** (owner: "bật lên thì chọn 1 vài gia đình hoặc là cho all"): turning a flag on,
  or tapping its scope, offers **Một vài gia đình** or **Tất cả gia đình**. Families are added by code
  (F-XXXX, as Gia đình shows it) or a parent's exact email (matched on the server, never shown); the
  flag keeps their ids, the portal and the audit log show codes, `publicConfig` never carries them. A plain
  on / off keeps the list. They count as internal for that flag only (AI drafts read it the same way);
  families marked `internal: true` still count, so no hand edit is needed any more.
- **Counters** (P-148): new `appEvents` names `autoSave*`, an optional `n`, counted in `appEventsDaily` and
  shown in Phân tích › Tính năng as "Tự lưu kỷ niệm (beta iOS)" (and in the CSV). The phone queues them in
  its Tự lưu state and sends them when the app runs, so background checks are counted too.
- **Deployed to dev (2026-10-13):** `getFeatureAccess` (new), `recordAppEvent`, `staffAnalytics`,
  `staffExportAnalytics`, `staffFlags`, `staffSetFlag`, `mirrorPublicConfig`, and the portal.
- **Deployed to dev, second round (2026-10-13):** `staffSetFlag`, `staffFlags`, `getFeatureAccess`,
  `mirrorPublicConfig`, `requestStorySuggestion`, `weeklyStorySuggestions`, and the portal.
- **To roll out on dev:** deploy the functions (`scripts/deploy.sh dev functions:getFeatureAccess,functions:recordAppEvent,functions:staffAnalytics,functions:staffExportAnalytics`)
  and the portal, then in the portal set `auto_save` to "Thử nội bộ" and mark staff
  families `internal: true` (no tool does this yet; by hand in Firestore), then 10 %.
- Tests: `firebase/tests/features.integration.test.ts` (own emulator project, since it rewrites
  `config/flags`), counter cases in `feedback.integration.test.ts` and `analytics.integration.test.ts`,
  `packages/contracts/test/config.test.ts`, mobile `auto_save_test.dart`. The Firebase suite has failures
  that exist on HEAD without these changes (account, links, memories "unused reservations", stories
  "inventing model"), plus some that come and go when files run in parallel.

## 10. Open questions for the owner

- **Q-054** Face model after the beta: buy a commercial licence or train our own? Not needed for the beta,
  which uses Apple Vision only; the beta's numbers decide it.
- **Q-055** A lawyer reviews the P-147 consent and the privacy policy text against Law 91/2025 (children's
  data, biometric data) before the beta.
- **Q-056** Does "Chỉ tải qua Wi-Fi" cover videos only (AS11) or every approved item (AS19)? Proposal: videos
  only, the same as manual uploads.
- **Q-057** Who may turn it on: any Cùng nuôi, or only the parent who owns the family? Proposal: any Cùng nuôi
  (AS03 shows "Bạn là Mẹ"); caregivers and relatives never.
- **Q-058** Price and plan after the beta (monthly or yearly, or bundled with more storage); the 7-day trial
  starts with it. This is not needed for the beta.

Design gaps for review: G-102 stack tile for a group, G-103 the face-analysis consent card and its "Child Life
lưu gì?" sheet, G-104 AS05 and AS19 without the background switch, G-105 withdrawn (AS09 stays single choice),
G-106 the five small mismatches in the frames (AS07 video count, AS13 thumbnails, AS15 slots, Wi-Fi scope
wording, AS07N "Đã có" contrast).
