# Kỷ niệm 2.0 — Video kỷ niệm & Thiệp cột mốc: review and plan (2026-10-13)

Source: Figma page **"v1.0 - improvement"** `345:35701`, row 1 (MM01 – MM09, y 32100) and row "MM · Thiệp cột mốc
& các trạng thái" `530:9514` (MM10 – MM17), extracted in `docs/discovery/figma-extract/29-remember-2.md`.
Owner decisions are **D-068**; open items **Q-062** (music) and design gap **G-107**.

Status (2026-10-14): **Thiệp cột mốc and Video kỷ niệm are both deployed on dev** with `milestone_cards` and `memory_story` on for every family there. Renderer: Cloud Run `keepsake-renderer`, queue `keepsake-render`, preview page `child-life-dev-keepsake.web.app`. Nothing committed yet; not tried on a phone yet.

## 1. What the design settles

- **Two products, one family ("Sáng tạo")**:
  - **Thiệp cột mốc**: one image rendered **on the phone**, in Dọc 4:5, Vuông or Story 9:16, exported as PNG or
    JPG. It has no processing state.
  - **Video kỷ niệm**: always 9:16 ("Ảnh + chữ + nhạc"), rendered **asynchronously**. It takes 1–2 minutes and
    the parent may leave the screen.
- **Both are saved to Kỷ niệm automatically**, as **Chỉ ba mẹ** with no family notice, and listed in **Câu
  chuyện**. They also appear in the **Ảnh** grid, badged "Thiệp" / "Câu chuyện" and counted in the week header.
  Neither appears in Album or Nhật ký unless the parent adds it.
- **Prefilled from the baby's profile**: name, age at the occasion, occasion date.
- **Nothing is auto-picked or auto-shared** (MM16: "Bạn luôn tự chọn ảnh và quyết định chia sẻ").
- **Video photos** come from Kỷ niệm (pre-filtered to the template's age window) or the device library. Pick
  order is scene order. Each template has a minimum and a maximum.
- **Failure keeps every input as a draft** in Câu chuyện. Not having enough photos offers three ways out (MM13).

## 2. Owner decisions (D-068, 2026-10-13)

| # | Question | Owner | What it means |
|---|---|---|---|
| 1 | Server video renderer | "remotion vì nó miễn phí cho cá nhân mà" | **Remotion on Cloud Run**. Free under the Remotion License while the company has at most 3 people; a Company License is needed past that |
| 2 | Câu chuyện tab vs today's Stories (D-041) | "thêm 1 section cho cái hiện tại", "thêm section mới trong đó luôn, tại nó cũng liên quan tới câu chuyện" | MM15 comes first: the quick-create row, then **Video kỷ niệm** and **Thiệp cột mốc**. Today's Stories list follows as its own section, unchanged (filters, drafts, AI suggestions, "Viết") |
| 3 | "★ Cao cấp" templates while there is no paid plan | "Beta như tự lưu" | **Free beta, no time limit**. The badge stays as drawn. Access is a rollout flag per family (P-148 pattern). The catalog carries `tier` so premium gating can start with the paid plan (Q-058) |
| 4 | Video ready when the app is closed | "Thêm push" | MM17 in-app banner **plus a push to the creator only**. This reuses `babies/{b}/notifications` with `recipients: [uid]` and `deliverNotice` |
| 5 | Storage quota | "Tính luôn" | Generated cards and videos count toward the family quota like any upload |
| 6 | Light theme | "Component tự có light mà" | Only Night is drawn. Light comes from the same `cl` components and tokens, so no extra frames are needed |
| 7 | Where template artwork lives | "Hình ảnh template cũng nên control và distribute ở portal ko hard code template hình ảnh trong app" | **Nothing about a template is built into the app.** A card is data: layers from a fixed set of primitives, with pictures uploaded in the portal. The app has one generic renderer and reads the published catalog. Video motion stays in Remotion code (no JSON animation engine in V1), but its pictures, music and texts come from the portal (§4.1) |
| 8 | Who decides Miễn phí / Cao cấp | "Tôi cần miễn phí hay premium thì control ở portal nha" | In the portal: each template's `tier`, plus the catalog's `premium {access: everyone \| hidden, badges}`. `subscribers` is added with the paid plan (Q-058). It is published like any catalog change, bumps no template version, and is enforced by `createMemorySession` / the video request. The app hides Cao cấp when `hidden`, and also on any mode it does not know |

## 3. What already exists and is reused (no duplicates)

| Need | Reused | Where |
|---|---|---|
| Save an image or video into Kỷ niệm | Upload session, quota reservation, renditions, global upload pill | `createMemorySession` (`firebase/functions/src/memories.ts` `createMemory`), `onMediaUploaded`, `UploadQueue.enqueue` |
| Milestone on a memory | `MilestoneRef`, presets `p_*`, family milestones | `memory_models.dart`, R-103 / R-105 |
| Render a widget to an image | `RepaintBoundary.toImage` as in the Stories card | `stories/share_screens.dart` `CardScreen` (R-161) |
| Share / save to device | `share_plus`, `gal` | `media_viewer.dart`, `auto_save/library_save.dart` |
| Per-family rollout | `config/flags` + `featureAccess` callable | `contracts/src/config.ts`, `functions/src/features.ts` (P-148) |
| Push | Notices with `recipients` → `deliverNotice` → FCM | `functions/src/social.ts`, `index.ts` `pushSender` |
| Staff catalog editing and artwork | Sơ cứu content workflow: draft → a second person approves → publish → rollback; pictures uploaded once, public, immutable | `functions/src/content.ts`, portal Sơ cứu page |
| Long jobs | Firestore job documents, retry and expiry on schedules, `staffRerunJob` | `deletionJobs`, `dataJobs` |

## 4. Data model

### 4.1 Template catalog (D-068 #7: managed in the portal, never built into the app)

The schema is in `packages/contracts/src/keepsakes.ts` and is shared by the portal, Functions and tests. The full contract between portal and app, field by field with examples, is
[`keepsake-template-format.md`](keepsake-template-format.md). The app
mirrors it in `apps/mobile/lib/features/keepsakes/keepsake_catalog.dart`.

```
KeepsakeTemplate {
  id: 'card_round' | 'video_first_month' | …     version: int (assigned on publish, never reused)
  kind: 'card' | 'video'      tier: 'free' | 'premium' (badge only in the beta)      status, order
  name, description: {vi, en}      occasions[]      ageDays {min, max} | null
  layouts: { portrait?, square?, story?: Layer[] } | null      // cards: the formats offered are the keys
  composition: 'FirstMonth' | … | null                          // videos: the Remotion composition
  assets: { music?, … }                                         // videos: uploaded files by role
  photos {min, max}      scenes [{hint, optional}]      texts [{key, default, max}]
  palette {background, ink, accent}      palettes[] ("Màu")      durationSec      thumb
}
Layer = background {color, asset?} | photo {slot, rect, shape: rect|circle, radius}
      | text {field: occasion|name|date|nameDate|quote|title, rect, font, weight, size, color, opacity, align, italic, maxLines}
      | shape {shape: rect|circle|star, rect, color, gradientTo?, radius, stroke}
      | image {asset, rect, fit, opacity}
rect = fractions of the card (x, y, w, h); sizes and radii = fractions of the card width;
color = 'background' | 'ink' | 'accent' (palette slot, swapped by "Màu") or #RRGGBB[AA]
```

- **Assets** are uploaded in the portal (`staffKeepsakesAsset`). Pictures are re-encoded to WebP at most 2160 px
  wide, with alpha kept. Music is stored as MP3 or M4A. Each asset is named by its content hash
  (`{name}_{hash8}.webp`) and stored public and immutable at `content/keepsakes/`. This is template artwork,
  never child media. The app loads assets through the same disk cache as media.
- **Workflow**: the same as Sơ cứu (D-058, `content.ts`):
  - One draft of the whole catalog: `content/keepsakes/versions/kv_…`.
  - Gửi duyệt → a second person with "Nội dung · Duyệt" approves, which publishes
    `publicConfig/keepsakes` (version label `ks_YYYYMMDD_NN`).
  - Trả lại, Huỷ nháp and Dùng lại bản này (rollback) work as in Sơ cứu.
  - Every step is in the staff audit log.
- **Versions**: on publish, a template identical to the published one keeps its number. Any change gets the
  next number after the highest ever used (`assignKeepsakeVersions`; `content/keepsakes.highest`), so a
  rollback never reuses a number. Archived templates drop out of what the app reads.
- **Compatibility**: the app skips any format whose layers it cannot read, and any template with no format
  left, so an older app never draws a newer template wrongly. Fonts are bundled: Be Vietnam Pro (its own
  `Be Vietnam Pro Keepsake` family with Bold for cards), Lora and Dancing Script.
- **Seed**: `keepsakeSeedV1` (`keepsakes-seed.ts`) holds MM10's four cards (geometry measured from MM10 /
  MM11; Vuông and Story are engineering layouts, G-107) and four videos. The portal loads it into the first
  draft. It is not in the app; Flutter tests read a generated copy (`test/helpers/keepsake_seed.json`, guarded
  by a drift test).
- **What a creation remembers**: `generated: {kind, templateId, templateVersion, occasion, format}` on the
  memory and its media item. A saved file is never re-rendered by a later version.

### 4.2 Occasions ("Chọn dịp", MM10)

- **Age occasions** (cake icon) are computed from the date of birth: `d7` 7 ngày, `m1` 1 tháng, `d100` 100
  ngày, `y1` Sinh nhật 1 tuổi. The date is DOB + n, and the milestone ref is a preset (`p_one_month`,
  `p_first_birthday`, new `p_seven_days`, `p_hundred_days`).
- **First-time occasions** (heart and star icons) are `p_first_smile`, `p_rolls_over`, `p_crawls` and
  `p_first_steps`. The date comes from the newest memory tagged with that milestone, otherwise today.
- **"Gợi ý"** marks the next age occasion within 14 days, else the most recent one in the past 30 days.
- **The memory is dated on the occasion day** (single-date mode), or today if that day is still ahead. This
  settles G-107's "Tuần 4 vs Tuần 5" by the milestone date.

### 4.3 Render jobs (video, A3)

`babies/{b}/keepsakeJobs/{jobId}`:

```
{ uid, requestId, templateId, templateVersion, mediaIds[], texts, audience,
  status: 'queued'|'rendering'|'completed'|'failed', progress 0–100, step,
  attempts, error, outputMediaId, memoryId, createdAt, updatedAt }
```

- `jobId` is derived from uid and the client `requestId`, so a retried call never makes a second job. The
  output's `memoryId` and `mediaId` are derived from `jobId`, so a retried completion never makes a second
  memory.
- **Drafts** (MM13 "Lưu nháp", MM14) are `babies/{b}/keepsakeDrafts/{id}`, private to the creator and
  written by the app under Rules.

## 5. Video architecture (A3)

```
app ──requestMemoryStory(requestId, babyId, template@v, mediaIds, texts, audience)──▶ Functions
   checks: Cùng nuôi, flag memory_story, template published & kind video, media belong to the baby,
   ready and not deleted, photo count within the template, at most 1 active job per baby, a daily cap,
   quota (estimated output bytes reserved)
   ──▶ keepsakeJobs/{jobId} (queued) ──▶ Cloud Tasks queue `keepsake-render` (asia-southeast1,
       max 3 dispatches/s, 3 attempts, 30 s → 5 min backoff) ──OIDC──▶ Cloud Run `keepsake-renderer`
       (private, concurrency 1, max 3 instances, 4 vCPU / 8 GiB, timeout 10 min)
   renderer: claim the job (transaction: queued → rendering, attempts+1)
           → read display.jpg renditions with the service account (never a public URL)
           → Remotion renderMedia(composition = template.renderer, props) → MP4 H.264 1080×1920 + poster
           → write babies/{b}/media/{mediaId}/original.mp4 and poster.jpg; update job progress / step
           → job completed (or failed with a code)
Functions onKeepsakeJobWritten (completed): create the memory + media item with derived ids (idempotent),
   count the bytes to the quota, write a notice with recipients [uid] → deliverNotice → push (D-068 #4)
app: watches the job (MM08 progress → MM09), in-app banner (MM17), retry = same job, attempt+1 (MM14)
sweeper (onSchedule, 15 min): rendering for more than 15 min → failed `timeout`; delete /tmp leftovers
   and partial outputs of failed jobs; purge drafts unused for 60 days
```

- **Media used in V1**: photos only. Videos in Kỷ niệm are stored as recorded with no renditions yet (SP-3).
  Clips in stories can come after SP-3.
- **Logs**: job id, template, timings and error codes only. Never names, texts or paths with names (the
  Remotion props carry the baby's name).
- **Music (Q-062 open)**: one track per template, uploaded in the portal (`assets.music`, `content/keepsakes/`). Until licensed tracks are
  supplied, videos render without music and the MM07 row reads as the template's track name.
- **Where it lives**: `apps/renderer` (Node 22, Remotion 4, Dockerfile with Chrome Headless Shell). It deploys
  through a new `scripts/deploy-renderer.sh dev` (Cloud Run, the queue and IAM: the tasks service account
  gets `run.invoker`, the renderer service account gets Storage object admin on the bucket and Firestore user).
  Prod needs owner approval.

## 6. Security

- **Rules**:
  - `keepsakeJobs`: Cùng nuôi of the baby read; no client writes.
  - `keepsakeDrafts`: only the creator reads and writes, shape validated.
  - `publicConfig/keepsakes`: signed-in users read.
  - Catalog assets in Storage: signed-in users read, staff write through callables.
  - Child media rules are unchanged.
- **Access**:
  - Only Cùng nuôi create (R-119); caregivers never see Kỷ niệm.
  - Relatives see a creation only if it is shared with Gia đình.
  - Flags `milestone_cards` and `memory_story` are evaluated per family by `featureAccess` (P-148 pattern) and
    enforced in `createMemorySession` (when `generated` is set) and `requestMemoryStory`.
- **Validation**: zod in `contracts` for templates, `generated`, job requests and staff edits. The server
  re-reads the template version and never trusts client-sent slot rules.

## 7. Build steps

| Step | Scope | Figma | Needs |
|---|---|---|---|
| **A1** ✅ local | Contracts: layered catalog schema, seed, occasions, `generated` on `createMemoryRequestSchema`; flags `milestone_cards`, `memory_story`; `featureAccess` returns both; `createMemorySession` stores `generated` and checks the flag; catalog workflow + asset upload callables; Rules for `publicConfig/keepsakes` and `content/keepsakes/` | — | — |
| **A2** ✅ local | Flutter Thiệp cột mốc: generic layer renderer, MM10 choose, MM11 edit (Ảnh / Bố cục / Lời nhắn / Màu, drag and pinch the photo), MM12 done; export 2160 px PNG + JPEG; save through the upload queue; share / save to device | MM10–MM12 | A1 |
| **A3** ✅ local | Kỷ niệm entries: MM01 "Tạo từ kỷ niệm" on Ảnh, MM02 sheet group, Câu chuyện sections (D-068 #2), "Thiệp" badge in the Ảnh grid and week counts | MM01, MM02, MM15, MM16, MM17 badge | A2 |
| **B1** ✅ local | Portal "Mẫu kỷ niệm" on the callables of A1: start from the seed, edit templates (form + layer JSON with validation and a live preview drawn like the app), upload pictures and music, tier / eligibility / order, submit, approve, archive, rollback | — (G-107: portal not drawn) | A1 |
| **C1** ✅ local | Video backend: `requestMemoryStory`, `retryMemoryStory`, jobs, Rules, sweeper, notice; Cloud Tasks enqueue | — | A1 |
| **C2** ✅ local | `apps/renderer`: Remotion compositions Tháng đầu tiên, 7 ngày đầu đời, 100 ngày yêu thương, Khoảnh khắc nhỏ; Dockerfile; deploy script; dev deploy | — | C1, Q-062 for music |
| **C3** ✅ local | Flutter video: template picker (MM04/MM05 not found, built from MM10's grid), MM06 / MM13 pick, MM07 finish, MM08 progress, MM09 done, MM14 failed, drafts, MM17 banner | MM06–MM09, MM13, MM14, MM17 | C1, C2 |
| **D1** ✅ local | MM03 milestone nudge and local notifications (D-068 #9; §9.4) | MM03 | A2 |

Every step: unit, widget and golden tests in Light and Night; Rules tests (`pnpm test:rules`); functions tests on
an isolated emulator config; checklist rows only after end-to-end on dev, iOS and Android.

## 8. Risks and trade-offs

- **Remotion licence**: free while the company has at most 3 people (D-068 #1). Past that, a Company License
  is needed. This must be re-checked before hiring.
- **Cloud Run cost and cold start**: min instances 0, so the first render after idle pays a cold start of about
  10–20 s. "Thường mất 1–2 phút" covers it. Caps: 3 instances, 1 active job per baby, a daily limit per
  family in `config/limits`.
- **The first non-Functions infrastructure**: Cloud Run, Cloud Tasks and a second deploy path. ffmpeg (SP-3)
  would be cheaper but cannot do the drawn animation and type quality.
- **Card render fidelity**: offscreen rendering at a fixed logical size with bundled fonts (no system
  fallback), the photo loaded at full resolution before capture, and a golden test per layout × format.
- **Music licensing (Q-062)** blocks only the soundtrack, not the feature.

## 9. As built

### 9.1 A1 + A2 (2026-10-13, local only)

- **Contracts**:
  - `packages/contracts/src/keepsakes.ts`: schema, layers, occasions, `generated`, portal requests,
    `assignKeepsakeVersions`.
  - `keepsakes-seed.ts`.
  - `memories.ts`: `generated` (nullable, default null, so older apps are unchanged).
  - `config.ts`: the flags and `FeatureAccess`.
  - Tests: `test/keepsakes.test.ts`.
- **Functions**:
  - `keepsake-content.ts`, with `staffKeepsakes`, `staffKeepsakesDraft`, `staffKeepsakesAct` and
    `staffKeepsakesAsset` in `index.ts`.
  - `features.ts`: per-family flags.
  - `memories.ts`: `generated` is stored and the flag checked.
  - Tests: `firebase/tests/keepsake-content.integration.test.ts`, `memories.integration.test.ts` (Thiệp cột
    mốc) and `features.integration.test.ts`.
- **Rules**:
  - `publicConfig/keepsakes` can be read.
  - `content/keepsakes/{file}` can be read publicly; writes go through Functions only.
- **Portal**: labels for the two flags (A10).
- **App**:
  - `apps/mobile/lib/features/keepsakes/`: catalog, occasions, renderer, access and screens.
  - Routes `/memories/card`, `/card/edit` and `/card/done`.
  - 50 `ks*` strings in vi and en.
  - `BeVietnamPro-Bold.ttf` in its own family.
  - Tests: `test/features/keepsake_test.dart` and goldens `test/golden/goldens/mm/` (Light and Night).
- **Not yet**:
  - No entry point in Kỷ niệm (A3).
  - No portal screen (B1), so no catalog on dev yet.
  - No "Tạo video" tile on MM12 until C3.
  - Nothing deployed.
  - Nothing tried on a phone.

### 9.2 Cao cấp control + B1 portal (2026-10-13, local only)

- **D-068 #8**:
  - The catalog's `premium {access: everyone | hidden, badges}` sits beside each template's `tier`.
  - `createMemorySession` re-reads `publicConfig/keepsakes` and refuses (`template-unavailable`):
    - an unknown template, or a non-card;
    - a version newer than the published one (an older one still on a phone is accepted);
    - a Cao cấp template while Cao cấp is hidden.
  - The app hides Cao cấp when `hidden` (or on an unknown mode) and the badges when they are off.
- **Portal** `apps/portal/src/screens/Keepsakes.tsx`, NỘI DUNG › Mẫu kỷ niệm, `/keepsakes`, `content.*`
  levels:
  - Bản đang dùng, the draft, and Sửa / Lưu nháp / Gửi duyệt / Duyệt & xuất bản / Trả lại / Huỷ nháp /
    Dùng lại bản này, each with a reason.
  - "Bắt đầu từ bộ mẫu đầu tiên" (the seed).
  - Miễn phí / Cao cấp panel.
  - Template list: tier, status, order, live version, "sẽ lên phiên bản mới".
  - Template editor: names, photos, age, occasions, palette, default message, thumbnail, layers as JSON
    per format checked against the shared schema, with a live HTML preview drawn like the app; videos get
    composition, length, music and scenes.
  - Thư viện: upload pictures and music, click a name to copy it.
  - History with rollback.
  - The whole set is checked against `keepsakeCatalogSchema` before saving.
- **Tests**: `apps/portal/test/keepsakes.test.tsx`; the v1 sidebar order now includes Mẫu kỷ niệm.
- **To try on dev**:
  1. `scripts/deploy.sh dev firestore,storage,functions,hosting:admin`. See the parallel-sessions note:
     deploy only after checking HEAD has the peers' Rules.
  2. In the portal, "Bắt đầu từ bộ mẫu đầu tiên", then Lưu nháp, then Gửi duyệt; a second person
     approves.
  3. In A10, turn on `milestone_cards`.

### 9.3 A3 entries in Kỷ niệm (2026-10-13, local only)

- **MM01** `KeepsakeCreateSection` on the Ảnh tab, under the Tự lưu entry: "Tạo từ kỷ niệm của {bé}",
  "Xem mẫu", and the Thiệp cột mốc tile with two published cards fanned.
- **MM02** the `+` sheet's "SÁNG TẠO & TỰ ĐỘNG" group with the Thiệp cột mốc tile.
  - The Tự lưu row drawn there is left to the Tự lưu work (D-066 keeps its entries on the tabs).
- **MM15 / D-068 #2** `KeepsakeStorySections` at the top of Câu chuyện:
  - the quick-create row;
  - "Thiệp cột mốc · N thiệp" (opening one goes to the usual viewer, with Tải về and Chia sẻ);
  - then "Câu chuyện của gia đình" over today's stories, which are unchanged. That title is not drawn
    (G-107).
- **MM17**:
  - "☆ Thiệp" badge on the tile (with the lock when Chỉ ba mẹ).
  - The week caption counts cards apart ("…, 1 thiệp").
  - `MediaItem.generatedKind` is read from `generated.kind`.
- **Visibility**: everything shows only to Cùng nuôi in a family with `milestone_cards` on. Relatives see
  the Thiệp section only for cards shared with Gia đình.
- **Video tiles** (MM01, MM02, MM15) are hidden until C3.
- **Tests**:
  - Entries in `test/features/keepsake_test.dart`; goldens `mm01_photos_*` and `mm15_stories_*`.
  - `memoryOverrides` now switches Kỷ niệm 2.0 off by default, so existing tests and goldens are
    unchanged.
  - Full suite: 1462 passed.

### 9.4 D1 milestone nudges (2026-10-14, local only)

- **Code**: `apps/mobile/lib/features/keepsakes/keepsake_nudges.dart`.
  - `planNudges` is pure: on-the-day plus look-back, with stable slots.
  - `inAppNudge` decides what MM03 shows.
  - `NudgeStore` keeps the phone's first open, the look-back slots, × and Để sau in SharedPreferences.
  - `nudgeNotification` builds the notification and `nudgeOfPayload` reads its payload.
- **Notifications**:
  - Scheduled by the existing `ReminderNotificationSync`, which cancels any pending notification it was
    not given. Nudge ids have bit 30 set, so they never collide with reminders.
  - At most the next 2 on-the-day nudges and 3 look-backs per phone, kept under iOS's 64 pending.
  - Tapping one selects the baby and opens `/memories/card?occasion=…`.
  - Feature access is remembered on the phone, so going offline does not cancel nudges already scheduled.
- **MM03 card** (`MilestoneNudgeCard`): takes MM01's place on Ảnh while an occasion is in its window. It
  offers "Tạo thiệp" (primary, because Tạo video waits for C3), "Để sau" and ×.
- **Tests**:
  - Planner, notification and payload tests, plus the MM03 flow, in `test/features/keepsake_test.dart`.
  - Golden `mm03_nudge_*`.
  - `familyOverrides(nudges: false)` keeps other tests' notification lists unchanged.
  - Full suite: 1468 passed.

### 9.5 C1 – C3 Video kỷ niệm (2026-10-14, local only)

- **Contracts** (`keepsake-jobs.ts`):
  - the request, retry and task schemas;
  - limits: 1 active job per baby, 10 a day per family, 3 attempts, 15 min to render, 30 min queued,
    40 MB of quota room;
  - error codes, and the frozen `KeepsakeJobInput` (a snapshot of the template, photo paths, texts, name,
    date line, mark, music).
- **Functions** (`keepsake-jobs.ts`):
  - `requestMemoryStory` checks:
    - a Cùng nuôi, the `memory_story` flag, `media_upload` not paused;
    - a published video template allowed by Cao cấp;
    - the photo count, and photos that are this baby's, ready and not deleted;
    - one at a time per baby, the daily cap, quota room.
  - `requestMemoryStory` then derives the job id from caller + requestId, snapshots the inputs and queues a
    Cloud Task.
  - `retryMemoryStory` is for the person who asked, on a failed job.
  - `onKeepsakeJobWritten` → `completeKeepsakeJob` runs on completion. It makes the poster and thumb from
    the renderer's frame and files the memory and video item with ids derived from the job (ready, Chỉ ba
    mẹ by default, dated on the occasion). It counts the bytes and writes a notice to the person who asked
    (push "Video kỷ niệm đã sẵn sàng").
  - `sweepKeepsakeJobsEvery15` fails stuck jobs.
  - Dispatch is Cloud Tasks over REST with an OIDC token from `keepsake-tasks@`. It is off until
    `KEEPSAKE_RENDERER_URL` is set (`.env.<project>`, written by the renderer deploy, copied by
    `build-deploy.mjs`).
- **Rules**: `keepsakeJobs` are read only by the Cùng nuôi who asked and written by no client.
- **Indexes**:
  - collection group: `familyId`+`createdAt`, `status`+`startedAt`, `status`+`updatedAt`;
  - collection: `uid`+`createdAt` desc.
- **Renderer** (`apps/renderer`, Remotion 4.0.529):
  - compositions FirstMonth / FirstWeek / HundredDays / LittleMoments, built from one `MemoryStory`
    (intro mark and title, a slow-zoom scene per photo with cross-fades, the parents' message as the
    outro, optional music with fades, bundled Be Vietnam Pro);
  - `runJob`: claim, download to a private temp folder served on 127.0.0.1 only, render H.264 1080×1920
    plus a poster frame, upload, complete; retry and final-failure handling;
  - Cloud Run server, esbuild + Remotion bundle build, Dockerfile, `scripts/deploy-renderer.sh`.
- **App** (`memory_story_screens.dart`, `keepsake_jobs.dart`):
  - template list (stands in for MM04 / MM05, G-107);
  - MM06 pick in scene order: from Kỷ niệm, or the phone, whose photos are first saved to Kỷ niệm as Chỉ
    ba mẹ and picked once ready;
  - MM13: not enough photos, the phone, a shorter template;
  - MM07: prefilled title and message, drag to reorder, music row (no picker, Q-062), Ai xem được;
  - MM08 progress and steps, MM09 ready (watch, save, share, open, matching card), MM14 failed (Thử lại /
    Chỉnh lại lựa chọn).
- **Entries** for video:
  - the MM01 / MM02 tiles and MM15's quick-create and "Video kỷ niệm" section with drafts and renders in
    progress;
  - MM03 "Tạo video";
  - MM12 "Tạo video 1 tháng";
  - the MM17 banner;
  - the push opens MM09.
- **Tests**:
  - contracts 74;
  - Firebase: keepsake-content 4, keepsake-jobs 5, memories 20, features and Rules 3;
  - renderer 3 (emulator);
  - Flutter: `memory_story_test.dart` 9 plus goldens `mm06`–`mm09`, `mm14` in Light and Night; the full
    suite has 1487 passing.
- **Before trying on dev**:
  1. Owner go-ahead for `scripts/deploy-renderer.sh dev` (Cloud Run, Cloud Tasks, Artifact Registry,
     Cloud Build, two service accounts).
  2. `scripts/deploy.sh dev firestore,functions` (indexes, rules, the new functions with the renderer URL).
  3. Turn on `memory_story`.
  4. Upload licensed music in the portal (Q-062); until then videos have no music.

### 9.6 Previews, suggestions, composition list (2026-10-14)

- **Previews on the phone** (`keepsake_preview.dart`, `apps/renderer/player`): the renderer's own
  compositions play in a WebView, so the preview shows what the server will render.
  - Mechanism: `@remotion/player` on Hosting target `player` (dev `child-life-dev-keepsake.web.app`,
    built by `scripts/deploy.sh <env> hosting:player`). The app sends the props through a JavaScript
    channel.
  - "Xem mẫu" on each template: the template with sample illustrations (`player/samples`, never a child's
    photo) and the baby's name.
  - "Xem trước" on MM07: the chosen photos as data URLs (thumbnails) plus the texts. Photos never leave
    the phone, and no render is spent.
  - A new composition gets a preview with the renderer deploy; no app release is needed.
  - The page sends no requests of its own (CSP `default-src 'self'`; template music only from
    `firebasestorage`).
  - New dependency: `webview_flutter` 4.14.1 (owner OK, 2026-10-14).
- **Suggestions without an occasion**: the template list opened from MM01 or `+` marks "Gợi ý" and puts
  first the templates for the occasion the baby is near (the card rule), and those whose age window holds
  the baby's age.
- **Compositions**: `keepsakeCompositions` in contracts is the list; the schema accepts only these and
  the portal shows a select with a short description. The renderer registers exactly these (test
  `apps/renderer/test/compositions.test.ts`). Adding one: contracts + renderer composition → deploy the
  renderer, the player page, functions and the portal → staff can pick it. No app release.
- **Dev deploys this day**:
  - Renderer infrastructure: `scripts/deploy-renderer.sh dev`, owner OK.
  - Functions, rules and indexes, and portal admin, with invoker checks: the callables answer JSON 401;
    the HTML 403s are scheduled and trigger functions only.
  - Player site.
  - `memory_story` on (`seed-keepsakes.ts --video`).

### 9.7 Thư viện nhạc and real preview videos (owner, 2026-10-14)

- **Music library** in the portal (Mẫu kỷ niệm → Thư viện nhạc): tracks with title vi/en, artist, mood,
  length, file, licence (kind, source, licence/invoice no., expiry) and status, with a player.
  - A published track needs its source and reference; the licence never reaches the app.
  - Each video template has a "Nhạc mặc định" chosen from published tracks.
  - Shapes: `keepsakeMusicSchema`, `catalog.music`, `template.defaultMusic` (contract doc §3.1).
- **MM07 "Nhạc nền"**: the default track's title; tapping opens a sheet with every published track,
  "Nghe thử" (audioplayers, already a dependency), and "Không dùng nhạc". The pick goes to
  `requestMemoryStory` as `musicId` (left out = default, null = none); "Xem trước" uses the same track.
- **Xem mẫu = a real video**: the template's `preview` MP4, uploaded in the portal (made from licensed
  sample photos), plays with media_kit. Without one, the Remotion player sample stays.
- **Large uploads**: the portal writes to `content/keepsakes-incoming/{uid}/` (Storage Rules: staff
  claim, own uid, ≤ 50 MB, image/audio/mp4), then `staffKeepsakesAsset {name, incoming}` sniffs, stores
  under the content hash and deletes the temporary file.
- **Dev deploy**: storage rules, admin portal, `staffKeepsakes*`, `requestMemoryStory`,
  `retryMemoryStory`; the callables answer JSON 401. The app side is not on the phone yet.
- **Fixed the same day**:
  - Approval did not copy `music` into `publicConfig/keepsakes`. Now the public doc carries published
    tracks without licence (`keepsakePublicMusicSchema`, `publicKeepsakeMusic`), and the full tracks
    are kept for staff in `content/keepsakes.music`. Functions and the app read the public shape.
  - Unchanged templates got a new version when Firestore returned map keys in another order;
    `assignKeepsakeVersions` now compares with sorted keys.
- **Dev samples (owner: "tự làm mấy video mẫu upload lên luôn")**:
  - Two original tracks from `apps/renderer/scripts/compose-music.mjs`: "Ru êm" (gentle) and "Nắng
    mai" (happy), 75 s each, licence `original`.
  - Four Xem mẫu MP4s (720×1280) from `apps/renderer/scripts/make-previews.ts`: the server's
    compositions, CC0 StockSnap photos (`apps/renderer/preview-credits.md`) and the name "Bông".
  - Published on dev with `seed-keepsakes.ts --media <dir>`: tracks, default music per video
    template, previews.
  - **Owner, before prod**: CC0 says nothing about model releases. Review the photos, or swap in
    photos the company licenses. The preview texts are Vietnamese only (one file per template).
- **Portal Mẫu kỷ niệm reorganised (owner: "tổ chức UI lại cho gọn gàng")**:
  - Tabs: Mẫu · Nhạc nền · Tệp · Cài đặt (Miễn phí / Cao cấp) · Lịch sử.
  - Mẫu: a gallery of Thiệp cột mốc and Video kỷ niệm with pictures; video covers, duration, and the
    preview playing on hover.
  - Editor: the form in sections (Thông tin chung, Dịp & độ tuổi, Màu & lời, Bố cục / Video), with the
    preview, preview video and cover on a sticky side. Tier, status and order moved here from the
    list.
  - Nhạc nền: a list with play, licence and "Mặc định cho"; a form only while editing.
  - Tệp: filter by kind, and where each file is used ("Chưa dùng" otherwise).
- **Video covers**: uploading an MP4 (Tệp, or "Tải video mẫu lên" in the editor) also takes a frame
  from the local file as `{name}-cover`. The editor uses the first photo scene and sets `preview` and
  `thumb`. The bucket has no CORS, so frames are never read from Storage. Dev's four videos got covers
  from `make-previews.ts --covers` (the server's poster frame).
- **Not done**: no golden for the music sheet.

### 9.8 Creative set for Chapter 01 (proposal, 2026-10-14)

`docs/product/remember-2-templates.md`: 12 cards (C01–C12) and 12 videos (V01–V12) with palettes,
slots, vi/en copy, layer stacks per format, scene timelines, and the contract extensions they need
(E-1 … E-13). Every template carries the Child Life logo (D-068 #10). Not built yet.

### 9.9 Production decisions applied (owner, 2026-10-14)

1. **Art library:** 20 original SVGs in `design/keepsake-art` (manifest, licence: owned), rasterised
   to transparent WebP and uploaded on dev as `art-*` assets (`seed-keepsakes.ts --art`). Grows
   toward 40; no third-party illustrations.
2. **Music:** moods `emotional`, `dreamy`, `festive` added. Five original placeholder tracks on dev
   (Ru êm, Nắng mai, Bình minh, Mơ màng, Tiệc vui); licensed tracks still to be bought.
3. **Multi-photo cards:** the MM11 editor keeps one photo per slot (`CardDraft.photos`), each with
   its own position and zoom; tapping a slot makes it the one "Ảnh" fills (outlined on screen,
   never in the export); "Lưu thiệp" waits for every required slot. The saved card is still one
   picture, so the server rule is unchanged.
4. **Sample photos:** real people only with licence + model / guardian release, enforced by
   `make-previews.ts`. The CC0 StockSnap previews and covers were deleted from dev Storage;
   placeholders (illustrations) are in use.
5. **Branding:** `brand` layer for cards (the one-colour lockup from `keepsake-brand.ts`, tinted to
   the palette's ink, at most one per format; the portal flags a format without one) and `brand`
   config for videos (corner mark, closing lockup, opacity). The four seed cards and four seed
   videos carry it and were republished as new versions on dev (cards v3–v4, videos v4). Cards
   already saved and videos already rendered are untouched; older jobs render without it.

### 9.10 Chapter 01 set built (2026-10-14)

- **Contracts (E-1–E-4, E-7–E-9, E-13):** text fields `age` / `ageNumber` / `ageUnit` / `birthStats` /
  `headline` / `message` / `photoLabel0-1`; fonts `playfair` / `baloo` / `patrickHand`; `rotate`,
  `letterSpacing`, `caps`; 17 new occasions (no nudges for them); template text keys `headline` /
  `closing` / `lines` / `letter`; 12 compositions; video requests carry `locale` and the new texts;
  jobs freeze per-photo age labels and V01's birth stats.
- **Cards C01–C12:** `scripts/src/keepsakes-chapter1.ts` (three formats each, logo on every one),
  built into `design/keepsake-templates/chapter1.json` with the art library's asset names. App: one
  content builder (`keepsake_card_content.dart`) for ages, labels and birth stats; MM10 offers the
  new occasions only when they fit the baby.
- **Videos V01–V12:** data in `packages/contracts/src/keepsakes-chapter1-videos.ts`; motion in
  `apps/renderer/src/compositions/chapter1.tsx` on the scene kit `src/kit/core.tsx`; one registry for
  Root, the renderer's poster and the WebView player. MM07 shows the template's extra texts.
- **Art:** 42 original SVGs (`design/keepsake-art`), rasterised to WebP with stable names.
- **Previews:** all 16 video templates rendered with the CC0 sample photos (D-068 #11), the
  original tracks and the logo.
- **Portal:** "Nhập mẫu (JSON)" imports `chapter1.json` into a draft (for prod, after the art is
  uploaded in Tệp).

