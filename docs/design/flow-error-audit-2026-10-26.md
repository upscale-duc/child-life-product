# Flow and error-state audit: async, long-running and failing flows (2026-10-26)

**Mode:** audit only (`cl-design-review`, D-109). No code, ARB, token or golden was changed.
**Trigger:** the owner tested Tự lưu kỷ niệm on a device (2026-10-26) and hit several problems:

- an upload started while family storage was 0 B;
- there was no Premium path;
- the copy read "tải trước 0 mục vừa đủ";
- "Đang chuẩn bị 18/104" had no per-file status;
- the queue sat at 0/80 with "Hết dung lượng · giữ trên máy" on every row and a pointless "Tạm dừng".

The owner then said "tôi nghĩ còn nhiều luồng nữa gặp lỗi nữa".

**Out of scope (being fixed in another session):** the Tự lưu AS10 confirm screen and the upload QueueSheet. That fix covers the storage-unknown upload, the full-storage CTA, per-file preparation status and the quota-blocked queue. This report notes the parts that the fix does **not** cover (§2.1).

Paths are relative to `apps/mobile/` unless they start with `firebase/` or `packages/`. ARB line numbers refer to `lib/l10n/app_vi.arb`. Several files have uncommitted edits from other sessions, so line numbers can move by a few lines.

---

## Tóm tắt cho chủ sản phẩm

**Kết luận ngắn:** lỗi chị/anh gặp ở Tự lưu **không phải lỗi riêng lẻ**. Có 5 kiểu lỗi lặp lại ở khắp app.

1. **"Chưa biết" bị hiển thị thành "không có" hoặc "0".** Khi dữ liệu đang tải hoặc tải lỗi, app hiện "Chưa có", "0 B", "0đ", hoặc tệ hơn là "Không có dấu hiệu sức khoẻ nào". Đây chính là gốc của "Đã dùng hết 0 B".
   - **Trang Hôm nay:** khi mở app lúc mạng chậm, app báo "Chưa có ghi chép hôm nay", nên ba mẹ có thể ghi trùng cữ bú.
   - **Màn Bàn giao (người trông bé xem):** khi chưa tải xong, app vẫn ghi ✓ "Không có dấu hiệu sức khoẻ nào trong 2 ngày qua". Đây là lỗi nghiêm trọng nhất về độ tin cậy.
2. **Bắt đầu việc không thể xong.** Thêm ảnh từ Kỷ niệm, thiệp, video kỷ niệm hay ảnh chia sẻ vào app đều **không kiểm tra dung lượng trước**. App chuẩn bị hết tệp rồi mới báo "Hết dung lượng". Một video lớn hơn cả gói Free (1 GB) sẽ chờ mãi. Mời người vào gia đình đã đủ chỗ thì người được mời bấm "Tham gia" lặp lại mãi.
3. **Lỗi không có lối ra, hoặc lối ra sai.**
   - Mẫu Premium bị từ chối khi tải lên chỉ hiện "Chưa tải lên được · Thử lại", và thử lại bao nhiêu lần cũng vậy.
   - Lumi báo "hết lượt AI tháng này" cho cả những lỗi không liên quan (vùng, quyền, tắt tính năng), rồi khoá ô nhập kể cả khi đã sang tháng mới.
   - Dung lượng đầy ở Premium v2 có lúc không còn nút nào để bấm.
4. **Chữ sai lý do.**
   - "Mất kết nối khi đang tải" cho tệp đã bị xoá khỏi máy.
   - "Tệp bị lỗi" khi máy hết bộ nhớ.
   - "Không tìm thấy lời mời" khi chỉ là mất mạng.
   - "Chưa lưu được vào Ảnh" khi lưu hồ sơ bé.
   - "Dung lượng sắp đầy" khi thực ra đã đầy.
   - "Đã tải xong 0 mục".
5. **Số liệu lệch giữa các màn.**
   - Tự lưu đếm số ảnh chờ theo 5 cách khác nhau: thông báo, banner Hôm nay, Kỷ niệm, Tự lưu và màn duyệt.
   - Dung lượng ở Tôi không tính phần đang giữ chỗ, nên Tôi nói "còn chỗ" trong khi hàng đợi nói "hết chỗ".
   - Số chỗ người ghi ở Gói gia đình khác với số server dùng khi mời.

**Nguy cơ mất dữ liệu (cần sửa trước):**

- Gộp tài khoản tạm vào tài khoản có sẵn có thể làm mất bé và gia đình nếu mạng rớt giữa chừng.
- Đăng xuất hoặc xoá tài khoản khi còn ghi chép chưa gửi vẫn nói "mọi ghi chép đã lưu".
- Chạm công tắc thông báo khi màn chưa tải xong sẽ ghi đè các lựa chọn cũ.
- Sửa hồ sơ bé khi chưa tải xong có thể ghi đè ngày sinh bằng ngày hôm nay.

**Đề xuất:** sửa theo **7 đợt** gom theo nguyên nhân gốc (§4). Đợt 1 ("chưa biết ≠ không có") và đợt 4 ("không mất dữ liệu") nên làm ngay. Hầu hết là L1/L2 nên Claude Code tự làm được. Chỉ **8 điểm cần chị/anh quyết** (§5), ví dụ có chặn video lớn hơn gói ngay lúc chọn không, hay dung lượng "đầy" có tính cả phần đang giữ chỗ không.

Phần mua gói qua cửa hàng hiện chưa mở (`UnavailableStoreGateway`), nên các lỗi mua hàng (§2.4 P-x) chưa ai gặp. Vẫn nên sửa trước ngày mở bán.

---

## 1. Method and evidence

| Item | Coverage |
|---|---|
| Flows traced | 1. Uploads and the queue (Kỷ niệm add, quick add, share inbox, story editor, milestone memory, keepsake cards, Video kỷ niệm import)<br>2. Family storage and the Premium v2 storage paths<br>3. Lumi chat, handover / AI summaries, engagement week<br>4. Paywall, purchase controller, plan screens, family plan v2, print studio, exports<br>5. Care sync and offline, invites and join, auth / save account / sign-out / delete, baby profile<br>6. Notification permission, reminders, Tự lưu outside AS10, app update, feedback, milestones |
| Method | Five parallel code traces from screen to controller to repository to ARB, plus server callables where the client meaning depended on them. I re-read the headline claims myself (Today `value ?? []`, HandoverNow, quota parse, invite network → notFound, profile toast, merge order, Lumi kept → exhausted, quota-retry throttle, pill precedence, MM08 spinner, print country jump, storage inline null) |
| Fresh render (D-111) | `tool/golden_freshness.sh` ran in an **isolated copy** in the scratchpad, so the shared `test/golden/failures/` folder was not touched. It covered auto_save_review, memory, album, keepsake, story, premium, premium_v2, ai, assistant_chat, family, notifications and me.<br>Result: **760 Current**, 4 Outdated (`mm/mm01_photos_*`, `mm/mm03_nudge_*`, 2–2.3 % of pixels, from another session's uncommitted keepsake edits; not used as evidence) |
| Rendered (R) evidence opened | `s9/10i_queue_states_light_vi`, `s9/10a_pill_uploads_paused_light_vi`, `mm/mm14_failed_light`, `as/ch25_failure_light_vi`, `ai/su01_quota_light_vi`, `pv2/detail_storage_light_vi` (all Current) |
| Evidence levels | **R** = rendered, **C** = code-confirmed, **H** = hypothesis (depends on server, OS or timing). Most findings are C, because no golden harness renders the failure states found here. |
| Not evaluated | Device runs; 200 % text; Android vs iOS permission dialogs; real store purchases (no store adapter yet); server timing for the H items |

**Missing golden coverage:** none of these states has a golden, and each should get one when it is fixed:

- non-adaptive Today while loading;
- HandoverNow while loading;
- invite opened offline;
- join with seats-full;
- the upload pill with mixed states;
- a refused (Premium) upload;
- MM08 with a missing job;
- the Lumi composer after a gate block;
- storage full in v2 with the plan unknown.

**Severity / priority / autonomy** follow `cl-design-review/references/issue-severity-and-prioritization.md`. Gate ids: G1 business meaning, G2 critical action access, G3 data loss, G5 AI and health claims, G6 primary task.

---

## 2. Findings by flow

Each finding gives: problem → user consequence · evidence · severity / priority / level · fix.

### 2.1 Uploads and the shared upload queue

Entry points that feed `UploadQueue.enqueue`:

- Kỷ niệm add / compose;
- widget quick add;
- share inbox;
- milestone "Tạo kỷ niệm";
- keepsake card save;
- Video kỷ niệm "Thêm từ máy";
- Tự lưu.

**UP-1. No entry point checks storage before preparing (pattern 1).**
- **Problem:** `enqueue` compresses or copies every file before `_createSessions` asks the server, and nothing in `memories/`, `stories/`, `keepsakes/`, `milestones/` or `share_inbox.dart` reads `familyStorageProvider`. The picker accepts videos up to 4 GB (`media_picker.dart:303`), while Free is 1 GB.
- **Consequence:** 30 picked items mean minutes of preparation, then "Hết dung lượng · 30 mục giữ trên máy" (`upWaitingQuota`, 4324). A file larger than the whole plan waits forever.
- **Evidence:** C. `memory_sheets.dart:406-436`, `upload_queue.dart:839-917`, `firebase/functions/src/memories.ts:258-261`.
- **Rating:** Blocker (G6) · P0 · L2. Refusing a file larger than the plan at pick time is **L3** (Q1).
- **Fix:** move the AS10 pre-check (being built elsewhere) into a shared `uploadPreflight(babyId, picked)`. Call it from compose, quick add, share import, milestone, keepsake and video import before preparing anything. When storage is full or unknown, show the same full-storage notice with "Thêm dung lượng" (`showStorageFullSuggestion` in v2, Dung lượng in v1).

**UP-2. Items waiting for space do not resume after space is freed or Premium is bought (pattern 3).**
- **Problem:** `_retryQuota` runs only from `_kick` and is throttled to once every 10 minutes. `retry()` and pull-to-refresh touch only `failed` items.
- **Consequence:** after deleting videos or upgrading, rows still say "Hết dung lượng · giữ trên máy" for up to 10 minutes. The owner's "stuck at 0/80" also has this cause.
- **Evidence:** C. `upload_queue.dart:1182-1193`, `948-966`.
- **Rating:** High · P0 · L1.
- **Fix:** kick without the throttle when storage, capabilities or the purchase state changes; reset `_lastQuotaTry` in `retry()`; run a periodic timer while anything is `waitingQuota`.

**UP-3. Permanent server refusals look retryable (patterns 2 and 4).**
- **Problem:** `PREMIUM_REQUIRED`, `not-enabled`, `template-unavailable`, `not-allowed` and `deleting` set `b.blocked` and mark the items `failed`. The pill and row then show "{n} mục chưa tải được · Chạm để thử lại" / "Chưa tải lên được", and the footnote reads "Mục lỗi được giữ trên máy · tự thử lại khi có mạng" (`qFootnote`, 4887). The reason is never shown, there is no Premium path, and "Thử lại tất cả" repeats the refusal.
- **Consequence:** a premium template card can never be saved, and the user is told it is a network problem.
- **Evidence:** C. `upload_queue.dart:1159-1164`, `memories.ts:195-221`, `memory_widgets.dart:726-731`. The look is R in `s9/10i_queue_states_light_vi`: footnote under failed rows.
- **Rating:** High (G2) · P0 · L1 (copy and actions to existing destinations).
- **Fix:** map `blocked` to copy plus one action:
  - PREMIUM_REQUIRED → paywall;
  - template gone → "Mẫu không còn dùng được · Bỏ";
  - not-allowed → explain the role.

  Hide retry and `qFootnote` for permanent reasons.

**UP-4. Non-network failures say "Mất kết nối" and auto-retry forever (pattern 4).**
- **Problem:** native `file-missing`, `bad-request`, `http-413`, `http-429` and `http-5xx` all become `failed` with `rowFailed` "Mất kết nối khi đang tải" (4838), and the back-online listener re-queues them every time.
- **Evidence:** C. `background_uploads.dart:159-163`, `upload_queue.dart:744-752`, `1371-1379`.
- **Rating:** Medium · P1 · L1.
- **Fix:** classify the codes:
  - `file-missing` → terminal "Tệp trên máy không còn · Bỏ";
  - 4xx → the rejected copy.

  Keep `rowFailed` for transport errors only, and auto-retry only those.

**UP-5. Any preparation error becomes "Tệp bị lỗi · không thử lại được" (pattern 4).**
- **Problem:** disk full while copying, the signed-out `StateError` and iCloud IO errors all turn into `unreadable` (`rowUnreadable`, 4842), which blames the user's file and is final.
- **Evidence:** C. `upload_queue.dart:847-865`, `447`.
- **Rating:** Medium · P1 · L1.
- **Fix:** add a retryable "Máy hết bộ nhớ trống", and keep the signed-out case separate from a truly undecodable file.

**UP-6. Preparation is invisible outside Tự lưu (pattern 5).**
- **Problem:** only Tự lưu calls `setPreparing`. Compose closes its sheet, then awaits `enqueue`, and the batch appears only after every file is prepared. Killing the app in that window loses the pick.
- **Evidence:** C. `memory_sheets.dart:430-436`, `upload_queue.dart:880-903`.
- **Rating:** High · P1 · L2.
- **Fix:** `enqueue` itself publishes "Đang chuẩn bị x/N" with per-item state and persists a placeholder batch first. The per-file status being built for AS10 is reused here.

**UP-7. The pill's state precedence has gaps (patterns 3, 4 and 7).** Main file: `memory_widgets.dart:700-760`. The cases:
- **(a)** Offline before a session exists: the pill shows "Đang chuẩn bị N mục" with a spinner instead of "Tạm dừng · chờ mạng".
- **(b)** Mixed states (quota + failed, quota + Wi-Fi, failed + Wi-Fi) fall through to "Đang tải {done}/{total}" with a spinner.
- **(c)** Uploaded but still processing shows "Đang tải 5/5" with a spinner. `watchMediaStatus` errors drop the subscription (`upload_queue.dart:1111-1115`).
- **(d)** `finished` wins over failures: "Đã tải xong {count} mục" (`upDone`, 4289) can read "Đã tải xong 0 mục", and unreadable items are hidden.
- **Evidence:** C (R for the paused pill: `s9/10a_pill_uploads_paused_light_vi` gives no reason).
- **Rating:** High · P0 · L1.
- **Fix:** write an explicit precedence table: quota > refused > failed > Wi-Fi > offline > processing > uploading > done. Spin only while bytes move. Done copy: "Đã tải 3/5 · 2 tệp lỗi". Resubscribe on error.

**UP-8. Reservations expire after 24 h, and held items then become permanently unretryable (pattern 3).**
- **Problem:** `releaseStaleUploads` cancels `uploading` media after 24 h. Items waiting for Wi-Fi or paused never re-reserve, so they end as "Chưa tải lên được", and "Thử lại" reuses the dead slot.
- **Evidence:** C. `memories.ts:1173-1199`, `packages/contracts/src/memories.ts:47`, `upload_queue.dart:1249-1258`, `1364-1370`.
- **Rating:** High (G3 risk: the user believes the item is kept) · P1 · L2.
- **Fix:** on server `cancelled`, reset `sessionCreated` and reserve again.

**UP-9. A replayed createSession can leave rows on "Đang chuẩn bị" for good.**
- **Evidence:** C path, H trigger. `memories.ts:235-242`, `upload_queue.dart:1141-1149`.
- **Rating:** Medium · P2 · L1.
- **Fix:** for ids missing from both lists, read their media status.

**UP-10. "Đã lưu ghi chú" is shown before any write, and an offline or refused note is invisible.**
- **Problem:** the `composeNoteSaved` toast (4589) fires before `enqueue`. A note batch has no items, so neither the pill nor the journal shows it.
- **Evidence:** C. `memory_sheets.dart:431`, `memory_widgets.dart:684-685`.
- **Rating:** High (G1) · P1 · L2.
- **Fix:** render pending notes in Nhật ký with "Sẽ lưu khi có mạng" or "Chưa lưu được · Thử lại".

**UP-11. Small items.**
- **Description:**
  - The pill thumbnail is blank after upload (`memory_widgets.dart:765` ignores `thumbPath`).
  - `_submit` reads `ref` after the sheet is popped (H, `memory_sheets.dart:~438-445`).
  - The library picker silently drops assets whose file is null, and shows one aggregate toast "Đang chuẩn bị ảnh và video…" (`media_picker.dart:38-40`, `466-491`).
  - The iOS share inbox drops shares for a baby the account can no longer add to, with no message (`share_inbox.dart:218-243`).
- **Rating:** Low–Medium · P2 · L1.

**Still open with the in-progress QueueSheet fix.** The uncommitted `memory_sheets.dart` diff hides "Tạm dừng" unless something can move, and adds the `qQuota` notice with "Thêm dung lượng" and "Bỏ". These remain open: UP-2, UP-3 (`qFootnote` still shows for refused items), UP-7 and UP-1 at the non-AS10 entry points. The Tự lưu `approve()` → `queue.enqueue` call has no handling for quota or persist errors (`auto_save_controller.dart:917-939`).

### 2.2 Family storage and the Premium storage paths

**ST-1. A missing quota is read as 0, which counts as "full": "Đã dùng hết 0 B" (patterns 4 and 7).**
- **Problem:** `FamilyStorage.fromJson` defaults `quotaBytes` to 0. `storageStateOf` returns `full` when `quota <= 0`, and `percent` returns 100. The same pattern exists in v2: `limitBytes` defaults to 0, `storageRatio` is 1 and `full` is true, giving "Đã dùng hết 0 GB" (`pv2E09Title`).
- **Consequence:** this is the "0 B" the owner saw. Unknown storage reads as both full and blocking.
- **Evidence:** C. `lib/features/me/me_models.dart:11-14`, `110-125`; `premium_v2.dart:198-199`, `254-255`; `premium_entries.dart:170-176`. The server always sends a limit (`firebase/functions/src/premium-v2.ts:93-110`), so 0 means "not read".
- **Rating:** Blocker (G1) · P0 · L1.
- **Fix:** make `quotaBytes` and `limitBytes` nullable. Unknown → "Chưa kiểm tra được dung lượng · Thử lại", never full.

**ST-2. Me storage and the queue use different arithmetic (pattern 6).**
- **Problem:** the server decides free space as `limit − used − reserved`, but `getFamilyStorage` returns no reserved bytes and the Me state uses `used` only. Tapping "Hết dung lượng · Chạm để xem" can land on "0,9 GB / 1 GB · Sắp đầy 90 %" with no warning.
  - `heldForQuota` counts every baby in the account, while the pill counts only the selected baby.
  - Percent is `floor` in Me ("Sắp đầy · 84 %") and `round` in the v2 card ("Đã dùng 85 %").
  - `pv2E08BodyPremium` hard-codes "Thêm 20 GB hoặc 50 GB" while the add-ons come from config.
- **Evidence:** C. `firebase/functions/src/memories.ts:258-261`, `account.ts:205-208`, `storage_screens.dart:32-36`, `me_models.dart:111-112`, `premium_entries.dart:179`.
- **Rating:** High · P1 · L2 for the client. **L3** for "does full include reserved?" (Q2).
- **Fix:** have the server return `reservedBytes` and `availableBytes`. Use one source and one rounding. Build the add-on list from `plan.addOns`. When the v2 card shows, drop the duplicate `stFullTitle` heading.

**ST-3. Full storage can have no action (pattern 2).**
- **Problem:** in v2 the request card is hidden and `StoragePremiumInline` returns nothing when `familyPlanV2Provider` is null (error swallowed). The result is a red "Đã dùng hết {quota}" with no button. In v1 the only action is a staff request, which is disabled without an email. In both, the full notice has no "free up space" action.
- **Evidence:** C. `storage_screens.dart:117-135`, `175`; `premium_entries.dart:169-170`; `premium_v2.dart:381-389`.
- **Rating:** High (G2) · P0 · L2.
- **Fix:** whenever storage is full, always show one primary action (v2 "Xem Premium" / "Thêm dung lượng"; v1 the request) and a secondary "Xoá bớt video lớn".

**ST-4. Non-managers are sent to buy storage.**
- **Problem:** `showStorageFullSuggestion` and `StoragePremiumInline` push the add-on page with a gold "Thêm {gb} GB · {price}" CTA to any member. The plan screen hides that CTA from non-managers.
- **Evidence:** C. `premium_entries.dart:124-127`, `195-197`; `family_plan_v2.dart:244-249`, `1400-1434`.
- **Rating:** Medium (permission meaning) · P1 · L2 (same destinations, role-correct variant).
- **Fix:** show non-managers the PW07 "Nhờ {name}…" variant.

**ST-5. Loading is shown as empty.**
- **Problem:** "Chưa có video nào." (`stVideosEmpty`) shows while loading or on error (`storage_screens.dart:348-377`). The storage row in Me stays blank forever on error (`me_screen.dart:355-372`). The add-on page has no loading or error state (`family_plan_v2.dart:1230-1236`, `1400-1409`).
- **Evidence:** C.
- **Rating:** Medium · P1 · L1.

### 2.3 Keepsakes, stories, albums

**KS-1. Cards say "Thiệp đã sẵn sàng! · Đã lưu vào Kỷ niệm" before the server accepts them (pattern 7).**
- **Problem:** the done screen opens straight after `enqueue`. The template / Premium check runs later, in `createMemorySession`, and its failure falls into UP-3. The `KeepsakeJobException` PREMIUM_REQUIRED branch can never fire on this path.
- **Evidence:** C. `milestone_card_screens.dart:1054-1056`, `premium_keepsake_editor.dart:508-529`, `memories.ts:190-222`.
- **Rating:** High (G1) · P0 · L2.
- **Fix:** tie the done screen to the queue item: "Đang lưu vào Kỷ niệm…" → ready, or show the refusal with its action.

**KS-2. Video kỷ niệm learns about limits only at the end (patterns 1 and 4).**
- **Problem:** neither the render quota nor storage is read before the multi-step flow.
  - `quota-full` says "Dung lượng gia đình sắp đầy…" (`ksVideoErrQuota`, 15564), meaning "almost full", when space is already insufficient. It has no action.
  - v2 QUOTA_EXCEEDED shows "Chưa làm được. Kiểm tra mạng và thử lại." (`toastActionFailed`).
- **Evidence:** C. `memory_story_screens.dart:1765-1788`, `2132`.
- **Rating:** High · P1 · L1 (copy and action). Pre-checking on entry is L2.

**KS-3. The MM08 job screen can spin forever with no close button (pattern 3).**
- **Problem:** `if (c == null || job == null)` returns a bare spinner for a stream error, a deleted job or a bad deep link.
- **Evidence:** C. `memory_story_screens.dart:2300-2305`.
- **Rating:** High (G2) · P0 · L1.
- **Fix:** handle error and "loaded but null" with "Không tìm thấy video" plus Đóng.

**KS-4. Failed-job copy blames the connection for server failures.**
- **Problem:** `render-failed` and `upload-failed` fall to `ksVideoFailedNetwork`, "Kết nối bị gián đoạn khi xuất video" (R: `mm/mm14_failed_light`, whose actions are otherwise good).
- **Evidence:** C. `memory_story_screens.dart:2526-2530`.
- **Rating:** Medium · P1 · L1.

**KS-5. "Thêm từ máy" in Video kỷ niệm fails silently.**
- **Problem:** videos are dropped without a word, preparation has no busy state, and held or refused items never fill the scenes.
- **Evidence:** C. `memory_story_screens.dart:750-779`.
- **Rating:** Medium · P1 · L2.

**KS-6. Unbounded spinners (H).**
- **Problem:** a completed job whose output is not yet in the media list keeps Save / Share / Open disabled with "Đang lưu vào Kỷ niệm…". The template preview WebView waits for `ready` with no timeout.
- **Evidence:** H. `memory_story_screens.dart:2306-2312`, `keepsake_preview.dart:328-356`.
- **Rating:** Medium · P2 · L1. Verify first.

**KS-7. Album "Tải về máy" promises things it doesn't do.**
- **Problem:**
  - "Tải ở nền — xong sẽ báo bạn" is a foreground loop with no notification.
  - "Video lớn sẽ đợi Wi-Fi": in fact **all** videos are skipped off Wi-Fi, and nothing resumes.
  - It shows a single "Đang lưu vào Ảnh…" for N items.
  - A mid-batch failure says nothing was saved, so retrying duplicates items.
- **Evidence:** C. `album_screens.dart:1491-1515`.
- **Rating:** Medium (G1) · P1 · L1 (honest copy plus per-item count).

**KS-8. Loading is shown as empty, and saves are reported before they happen.**
- **Problem:**
  - The story editor picker shows "Chưa có ảnh nào ở đây" while loading (`story_editor.dart:221-229`).
  - "Đã chia sẻ" shows "Chưa chia sẻ câu chuyện nào ra ngoài" while loading or on error (`share_screens.dart:1103-1138`).
  - The Albums tab shows its empty hint (`album_screens.dart:57-62`).
  - "Đã lưu nháp" appears before the write, and errors are swallowed (`story_editor.dart:105-115`).
  - A story save failure says "Chưa lưu được vào Ảnh" (`story_editor.dart:1547`).
- **Evidence:** C.
- **Rating:** Medium · P1 · L1.

**KS-9. Milestone "Tạo kỷ niệm" can leave its spinner stuck, and says "Đã tạo kỷ niệm" while the memory is only queued.**
- **Evidence:** C. `milestone_sheets.dart:351-371`.
- **Rating:** Low · P2 · L1.

### 2.4 Paywall, purchases, plan, print, exports

The store is closed today (`UnavailableStoreGateway`, `store_gateway.dart:131-163`), so P-4 to P-7 are **latent**. Fix them before the store opens.

**P-1. A paying household can see the Free / non-owner paywall or plan (pattern 7).**
- **Problem:** `PaywallScreen` and `HouseholdPlanScreen` read the fresh `capabilitiesProvider`. While it is null, the legacy light page renders and then swaps to the dark v2 page. If it fails with no cache, the **owner** sees "Nhờ chủ hộ nâng cấp", and the plan screen says "Đang dùng gói cơ bản".
- **Evidence:** C. `paywall_screen.dart:328-387`, `plan_screen.dart:45-51`, `89`, `175-178`.
- **Rating:** High (G1) · P1 · L1.
- **Fix:** read cache-first (`capabilitiesNowProvider`). Show a neutral skeleton, and an error with "Thử lại" when unknown.

**P-2. Template gates misbehave when the plan or caps are unknown.**
- **Problem:** in v2, a Premium template tap does nothing when the plan cannot load (`premium_gate.dart:177-181`). In legacy, a paying family offline with no cache is offered "Mở với Premium" (`premium_gate.dart:195-217`).
- **Evidence:** C.
- **Rating:** Medium · P1 · L1.
- **Fix:** reuse `_unknownPlan` ("Chưa kiểm tra được gói gia đình").

**P-3. Prices fall back to 0đ.**
- **Problem:** `PlanPrice.fromJson` defaults to 0, so a missing `prices` shows "Đăng ký Premium · 0đ/năm" and "Thanh toán 0đ hôm nay". The same applies to add-ons and the Me inline price.
- **Evidence:** C. `premium_v2.dart:89-95`, `213-214`.
- **Rating:** High (trust) · P1 · L1.
- **Fix:** unknown price → hide it and disable the CTA. Once the store opens, use the storefront price.

**P-4. The v2 CTA has no progress while buying or verifying.**
- **Problem:** `PremiumGoldButton` has no loading state, and the period tiles stay tappable.
- **Evidence:** C. `paywall_v2.dart:1584-1589`, `186-205`; `premium_style.dart:74-114`.
- **Rating:** High (latent) · P1 · L1.

**P-5. Result sheets opened from the plan screen do nothing.**
- **Problem:** "Kiểm tra lại" and "Thử lại" are discarded because the action is ignored and `reset()` runs. Pending is dropped.
- **Evidence:** C. `plan_screen.dart:93-112`.
- **Rating:** High (latent) · P1 · L1.

**P-6. A success that arrives while the Pending sheet is open is lost, and the buy CTA becomes active again (double-buy risk).**
- **Evidence:** C. `paywall_screen.dart:175-176`.
- **Rating:** High (latent) · P1 · L2.

**P-7. A store or product load failure is shown as "Mua trong app sắp có" / "Bước thanh toán sắp mở", with no retry.**
- **Evidence:** C. `billing_repository.dart:70-77`, `paywall_screen.dart:275-277`, `401-406`.
- **Rating:** Medium (latent) · P2 · L1.

**P-8. Family plan v2 copy and gaps.**
- **Problem:**
  - "Người quản lý: người quản lý (bạn)" while members load (`family_plan_v2.dart:111`, `373`).
  - "…một câu chuyện của " with an empty name (`:218`).
  - A plan load failure says "Chưa tải được **lịch sử**" with no retry (`:122-129`).
  - The "Gói của gia đình" row is missing for v2-only families, because `PremiumFeatures.any` omits `premiumV2` (`me_screen.dart:165-167`, `premium_models.dart:220`).
  - An empty `displayName` crashes the member footer (`paywall_v2.dart:1617`, H).
- **Evidence:** C (crash H).
- **Rating:** Medium · P1 · L1. The missing row is L2.

**P-9. Terms and counts disagree.**
- **Problem:**
  - The plan is called "Gói của hộ" / "Cơ bản" in Me and "Gói của gia đình" / "Free" on the plan screen.
  - A seat is called "chỗ người chăm sóc", "chỗ người ghi" or "người có quyền ghi".
  - E12 uses the offer limit, while the plan row uses the server limit.
  - "Dùng mẫu cơ bản" / "…miễn phí tương tự" / "Chọn mẫu miễn phí" are three labels for one action.
- **Evidence:** C.
- **Rating:** Medium · P2 · **L3** (canonical terms, Q6).

**PR-1. Print file export can lock the user in for up to 5 minutes.**
- **Problem:** close, back and system back are all disabled while busy. The only feedback is a spinner with "Đang dựng file in… Bạn có thể cần chờ một chút.", and a timeout gives the generic `psError`.
- **Evidence:** C. `print_repository.dart:82-85`, `print_screen.dart:191`, `446-455`, `502`, `652`, `716`.
- **Rating:** High (G2) · P1 · L2.
- **Fix:** keep close enabled and continue in the background (job doc with progress, like keepsake video), or at least show elapsed time and allow cancel.

**PR-2. An unsupported shipping country silently turns checkout into "Tải file".**
- **Problem:** if `digital` is off, the jump is a dead end.
- **Evidence:** C. `print_screen.dart:1786`, `1802-1805`.
- **Rating:** Medium · P1 · L1.
- **Fix:** add a notice "Chưa giao tới {country}…".

**PR-3. Payment copy contradicts the chosen method.**
- **Problem:** the checkout caption always reads "Trả khi nhận hàng" and the success row "Thanh toán khi nhận", even when Chuyển khoản is selected. "Chuyển khoản / VietQR **ngay**" conflicts with "Bạn chưa cần thanh toán khi đặt hàng".
- **Evidence:** C. `print_screen.dart:1710-1711`, `print_checkout.dart:486`.
- **Rating:** Medium (trust, money) · P1 · L1.

**PR-4. An order timeout shows the generic "Kiểm tra kết nối", although the order may already exist.**
- **Problem:** editing any field regenerates `requestId`, so a retry can create a duplicate.
- **Evidence:** C path, H duplicate. `print_screen.dart:240-248`, `1377-1392`.
- **Rating:** Medium · P1 · L1.
- **Fix:** "Có thể đơn đã được ghi nhận — xem Đơn in".

**PR-5. Order detail quirks.**
- **Problem:**
  - An unknown order shows "Chưa có đơn in" (`print_orders.dart:152-158`).
  - Timestamps are raw `DateTime.toString()` (`:557-560`).
  - An unknown status shows the raw wire string with every step greyed.
  - Cancel gives no toast.
  - The success total is computed on the client (`print_screen.dart:487-490`).
  - English plurals are wrong ("1 frames", "24 page", "+1 exports").
- **Evidence:** C.
- **Rating:** Low–Medium · P2 · L1.

**EX-1. The account data export can spin forever if the server reply lacks `jobId` (uncaught TypeError).**
- **Evidence:** H. `account_screen.dart:417-438`, `me_repository.dart:170-176`.
- **Rating:** Low · P2 · L1.

### 2.5 AI: Lumi, handover, weekly

**AI-1. Any gate refusal on a kept input comes back as "Bạn đã dùng hết lượt hỗ trợ AI tháng này" and locks the composer.**
- **Problem:** this covers consent, region, role, module and kill-switch refusals. `KeptReason.blocked` → `ChatBlockKind.exhausted` → `ComposerMode.out`.
- **Evidence:** C. `assistant_controller.dart:1118-1126`, `516-523`; `assistant_screens.dart:691-698`.
- **Rating:** High (G1) · P0 · L1.
- **Fix:** persist the real reason and rebuild the block with `_blockFor(reason)`.

**AI-2. The exhausted block never clears after the monthly reset or an upgrade.**
- **Problem:** `dismissBlock()` has no callers, the kept bubble "Chưa gửi" has no Send, and the only way out is "Mới" and retyping.
- **Evidence:** C. `assistant_controller.dart:1173`, `assistant_screens.dart:1281-1287`.
- **Rating:** High (G6) · P0 · L1.
- **Fix:** derive `out` from current usage, and add "Gửi" when usage is back.

**AI-3. Old blocked tasks always render the full exhausted card, often with a disabled "Nâng cấp & tiếp tục câu hỏi" and no explanation.**
- **Evidence:** C. `assistant_screens.dart:1601-1617`, `1953-1960`.
- **Rating:** Medium · P1 · L1.

**AI-4. Reset dates.**
- **Problem:**
  - The Free exhausted card has no reset date, even though the code comment says the upsell-off variant shows only that.
  - An empty reset date is interpolated: "Credit sẽ cấp lại . Bạn vẫn…".
  - "Credit" is used in vi copy where the rest says "lượt".
  - The photo quote shows "bạn còn 0" when usage is unknown and offers an upgrade when upsell is off.
- **Evidence:** C. `assistant_screens.dart:1800-1822`, `1930-1962`; `assistant_labels.dart:441-446`.
- **Rating:** Medium · P1 · L1 for the date and fallback. "Credit" vs "lượt" is a term (L3, Q6).

**AI-5. A typed clarification answer is lost silently offline or on failure.**
- **Problem:** the field is cleared before sending and the result is discarded.
- **Evidence:** C. `assistant_screens.dart:331`, `assistant_controller.dart:992-994`, `1553`, `1589-1593`.
- **Rating:** High (G3, the user's words) · P0 · L1.

**AI-6. A timeout is reported as offline and "chưa lưu gì", but the server may have committed. Confirm retries use a new id.**
- **Evidence:** C path, H server. `assistant_repository.dart:51-59`, `assistant_controller.dart:1644`.
- **Rating:** Medium (G1) · P1 · L2.
- **Fix:** treat timeout as "unknown" → refresh the task and show "Đang kiểm tra…"; reuse one `requestId`.

**AI-7. One toast mapping covers every action.**
- **Problem:** "Chưa lưu được. Bản nháp vẫn giữ nguyên." and "Bản nháp vừa thay đổi" appear for clarification, plan, feedback and photo errors that have nothing to do with a draft. Photo errors show twice.
- **Evidence:** C. `assistant_screens.dart:311-320` and the callers listed there.
- **Rating:** Medium · P1 · L1.

**AI-8. Retry handling.**
- **Problem:**
  - `retryable` is parsed but never read, so `permission-denied`, `resource-exhausted` and `failed-precondition` invite endless "Thử lại".
  - An unmapped task failure shows "Có lỗi xảy ra. Chưa có gì được lưu." with no action.
  - In a shared thread, "Thử lại" re-sends **another member's** question as mine.
- **Evidence:** C. `assistant_repository.dart:149`, `assistant_screens.dart:2434-2442`.
- **Rating:** Medium · P1 · L1.

**AI-9. "Lumi đang soạn…" has no client timeout, and listener errors are swallowed.**
- **Problem:** a task that never resolves shows typing forever (C path, H stuck). Non-authors get no Cancel.
- **Evidence:** C path, H stuck. `assistant_widgets.dart:499-624`, `assistant_repository.dart:475-500`.
- **Rating:** Medium · P1 · L1.
- **Fix:** poll after N seconds, then show "Vẫn đang xử lý…", then a failure card with retry.

**AI-10. HandoverNow / HandoverSafety show loading and errors as "nothing" (G5).**
- **Problem:** `.value ?? const []` everywhere. While loading or failed, a carer reads:
  - "Đang thức";
  - "Chưa ghi gần đây";
  - "Hôm nay không có việc nào đã hẹn";
  - ✓ "Không có dấu hiệu sức khoẻ nào trong 2 ngày qua" (`hoNoHealth`, 29943).
- **Consequence:** false reassurance at handover.
- **Evidence:** C. `lib/features/ai/handover_now.dart:57-75`, `271-275`, `324-368`.
- **Rating:** **Blocker (G5 / G1 safety)** · P0 · L1.
- **Fix:** skeleton until loaded, an error line on failure, and never the health-OK line unless the check-ins have loaded. Also omit "Hôm nay 0 lần" (B11).

**AI-11. Opening a sent handover that no longer exists shows the skeleton forever.**
- **Evidence:** C. `handover_screen.dart:195-198`, `247-250`.
- **Rating:** High · P1 · L1.
- **Fix:** "Bản bàn giao này không còn" plus "Tạo bản mới".

**AI-12. Handover generate and send errors.**
- **Problem:**
  - Every generate error shows "Chưa tạo được bản bàn giao" with "Thử lại", even for role or quota errors, and `AiException.offline` is never used.
  - A silent stale refresh can replace the AI version with the template.
  - "Gửi bàn giao" is enabled offline, and every failure says "Kiểm tra mạng".
  - "cập nhật {time} từ nhật ký" uses the wall clock, not the data's freshness.
  - The consent toggle stays flipped after a failed save.
- **Evidence:** C. `handover_screen.dart:103`, `222-226`, `260-269`, `523-536`, `765-766`; `ai_consent_screen.dart:157-167`.
- **Rating:** Medium · P1 · L1.

**AI-13. Quota copy.**
- **Problem:** the eyebrow "ĐÃ DÙNG HẾT LƯỢT AI" sits over "Đã dùng 2/3 lượt AI hôm nay". "Exhausted" counts `reserved` but the text shows `used`. An unknown reset reads "Lượt mới từ —." (R: `ai/su01_quota_light_vi` is fine for the known case).
- **Evidence:** C. `ai_models.dart:257`, `handover_screen.dart:615-623`.
- **Rating:** Medium · P1 · L1.

**AI-14. Handover auto-refresh on open may spend shared AI credits without a tap.**
- **Problem:** any newer `dataVersion` triggers it; AiMomentNudge does the same on milestone save.
- **Evidence:** H. `handover_screen.dart:189-208`, `ai_widgets.dart:336-358`.
- **Rating:** Medium · P2 · **L3** (Q5: charging rule).

**AI-15. Weekly recap.**
- **Problem:**
  - Every error, including expired or other-account, shows "Chưa kiểm tra được gợi ý…" with a retry loop.
  - A media error leaves a skeleton forever, and an empty week shows a blank page.
  - Shelf dismiss failures say "Chưa kiểm tra được gợi ý".
- **Evidence:** C. `engagement_week.dart:41-75`, `engagement_widgets.dart:182-185`.
- **Rating:** Medium · P2 · L1.

### 2.6 Care sync and offline

**SY-1. Non-adaptive Today shows "Chưa có" / "Chưa có ghi chép hôm nay." while records load or after an error (G1).**
- **Problem:** `recentRecordsProvider(...).value ?? const []`. The D-108 skeleton applies only when adaptive is on (the default is off), and the rhythm card falls to its empty state. A stream error stays "empty" forever.
- **Consequence:** a parent on a cold start or slow network logs the same feed twice.
- **Evidence:** C. `lib/features/today/today_screen.dart:70-71`, `133-136`, `593`, `907-921`; `experience_repository.dart:99-103`.
- **Rating:** **Blocker (G1, daily, all roles)** · P0 · L1.
- **Fix:** skeleton whenever `!hasValue`, and an error line on `hasError`.

**SY-2. History and Stats show a skeleton forever on a query error.**
- **Problem:** the screen-reader label says "Đang tải ghi chép" indefinitely.
- **Evidence:** C. `history_screen.dart:166-168`, `273-274`; `stats_screens.dart:204-207`.
- **Rating:** Medium · P1 · L1.
- **Fix:** add an error branch with retry.

**SY-3. The pending count misses deletes, undo restores, edits older than 14 days and timer writes.**
- **Problem:** the banner can clear while unsent writes remain, and "Thử lại ngay" can report "Đã đồng bộ" for rejected or unrelated writes.
- **Evidence:** C (A6 is H). `today_screen.dart:74`, `care_repository.dart:32-44`, `226-234`.
- **Rating:** Medium (G1) · P1 · L2.

**SY-4. A rejected care write gives one generic toast.**
- **Problem:** the toast "Chưa lưu được bản ghi. Có thể quyền của bạn đã thay đổi." does not name the record, is reused for failed deletes and undos, and is shown for the normal two-parent timer race. A rejection after an app restart is silent (H).
- **Evidence:** C. `care_sheets.dart:120-124`, `timer_screens.dart:68-75`, `care_repository.dart:97-102`, `163-164`.
- **Rating:** Medium (G3) · P1 · L1. The persisted outbox is L2.

**SY-5. Stats "Hôm nay" counts from 18:00 yesterday, but only the ml tile says so. Today counts midnight to midnight.**
- **Evidence:** C. `care_calc.dart:441-445`, `stats_screens.dart:511-519`.
- **Rating:** Low–Medium · P2 · L1 (label).

### 2.7 Invites and family join

**FJ-1. An invite link opened offline (or during a backend hiccup) says "Không tìm thấy lời mời".**
- **Problem:** every `FamilyException`, network included, goes to `joinClosed?reason=notFound`.
- **Consequence:** a valid invite looks dead.
- **Evidence:** C. `lib/features/family/join_screens.dart:370-376`, `invite_link_join.dart:81-84`.
- **Rating:** High (G6) · P0 · L1.
- **Fix:** network or unknown → inline error with "Thử lại"; only real closed reasons go to `joinClosed`.

**FJ-2. Joining a full family loops.**
- **Problem:** seats-full on accept shows the inviter-facing "Mời làm người thân để cùng xem album, hoặc đổi quyền một người đang ghi." (`pv2E12FullBody`). The button stays enabled, and the invite-link path falls back to Accept → Confirm → the same toast. The joiner may have just created an anonymous account.
- **Evidence:** C. `join_screens.dart:655-656`, `firebase/functions/src/family.ts:120-137`, `625-628`.
- **Rating:** High (G6) · P0 · L2.
- **Fix:** add a joiner-side `joinClosed?reason=full`, e.g. "Gia đình {baby} đã đủ người ghi. Nhờ {inviter}…". Returning the seat state in the preview is L3 (Q3).

**FJ-3. Seat counts disagree.**
- **Problem:** the plan shows "{used} / {limit} chỗ" from writers only, but the server's `requireSeat` also counts pending writer invites. The plan says "2 / 3 chỗ", then invite creation says "đã dùng hết 3 chỗ".
- **Evidence:** C. `premium-v2.ts:330`, `family.ts:120-137`, `invite_screens.dart:96-100`.
- **Rating:** Medium · P1 · **L3** (Q3).

**FJ-4. A join that succeeds but whose membership arrives late lands on "Nhập mã mời" right after the success toast.**
- **Problem:** `waitForMembership` gives up silently after 10 s.
- **Evidence:** C timing, H outcome. `lib/app/session.dart:230-242`.
- **Rating:** Medium · P1 · L1.

**FJ-5. Small items.**
- **Problem:**
  - "Bạn đã ở trong gia đình {baby}" shows the previously selected baby.
  - `locked` gives "Chưa làm được. Thử lại nhé." instead of `joinLocked(minutes)`.
  - The pending-invites count includes expired invites.
  - A member-list error always blames the network.
  - The countdown never shows less than 1 hour.
- **Evidence:** C. `invite_link_join.dart:62-64`; `join_screens.dart:420-431`, `655`; `family_repository.dart:106-113`; `family_screen.dart:153-158`.
- **Rating:** Low · P2 · L1.

### 2.8 Auth, save account, sign-out, deletion, profile

**AU-1. Merging an anonymous account can permanently lose its families (G3).**
- **Problem:** `mergeAnonymousInto` signs into the existing account **before** `claim`. If the claim fails, the anonymous user is gone and a retry throws. The success toast "Đã gộp vào tài khoản của bạn" can show before the merge, because the wait ends as soon as the target account has any baby.
- **Evidence:** C. `lib/features/auth/auth_repository.dart:342-360`, `save_account.dart:43-52`, `101-102`.
- **Rating:** **Blocker (G3)** · P0 · L2 (client and server order change; same feature).
- **Fix:** verify the target credential server-side first, or persist the anonymous token and retry `claim` after sign-in. Show success only when `moved > 0` and the babies appear.

**AU-2. "Email đã có tài khoản" is a dead end.**
- **Problem:** any password-path error (wrong password, rate limit, network) routes to screen 10, which offers only Apple and Google, or "Dùng email khác". Accounts created by email link or password can't continue. Apple is named on Android, and Google `account-exists-with-different-credential` re-pushes the same screen.
- **Evidence:** C. `auth_repository.dart:131-146`, `51`; `auth_screens.dart:481-482`, `909-944`.
- **Rating:** High (G6) · P0 · L2. Adding "Gửi link đăng nhập" and "Quên mật khẩu" uses existing auth methods; this needs behaviour verification.

**AU-3. Sign-out with unsynced care records says "Mọi ghi chép và kỷ niệm đã lưu trên tài khoản của bạn."**
- **Problem:** only the upload queue is counted. Anonymous sign-out doesn't mention pending records. Account deletion ignores pending writes, and every server failure says "Kiểm tra mạng".
- **Evidence:** C copy, H delivery. `me_screen.dart:494-541`, `home_shell.dart:900-941`, `account_screen.dart:450-499`.
- **Rating:** High (G3) · P0 · L1.
- **Fix:** `waitForPendingWrites().timeout(5s)` first. If writes remain, show "{n} bản ghi chưa gửi" with "Thử gửi ngay" and "Vẫn đăng xuất".

**AU-4. Baby and profile save failures say "Chưa lưu được vào Ảnh. Thử lại nhé." (`toastSaveFailed`, 5047).**
- **Evidence:** C. `baby_profile_screens.dart:565`, `568`; `profile_screen.dart:89`.
- **Rating:** High (trivial) · P0 · L1.
- **Fix:** a dedicated "Chưa lưu được hồ sơ…" string.

**AU-5. Baby edit can be saved before the profile loads.**
- **Problem:** this writes today's date as the date of birth and `unspecified` gender. Save is always enabled, and there is no loading state.
- **Evidence:** C logic, H reach. `baby_profile_screens.dart:533-535`, `577-598`.
- **Rating:** High (G3) · P0 · L1.
- **Fix:** skeleton, Save disabled until prefilled, and never send unloaded fields.

**AU-6. Email-link sign-in.**
- **Problem:** a link failure after a successful sign-in shows an error page, and the `signingIn` phase has no back action and no timeout.
- **Evidence:** C. `email_link.dart:259-279`, `310-322`.
- **Rating:** Low · P2 · L1.

### 2.9 Notifications and reminders

**NT-1. Tapping an EN07 switch before settings load overwrites every stored switch with defaults (G3, preferences).**
- **Problem:** `save()` writes the full map built from `defaults`.
- **Evidence:** C. `notification_settings_screen.dart:84-86`, `101-110`; `notification_models.dart:181-182`.
- **Rating:** High · P0 · L1.
- **Fix:** disable the switches until loaded, or write only `{key: value}`.

**NT-2. Tôi › Thông báo says "Bật" while the OS has notifications off. On EN07 the switches look on and stay usable.**
- **Evidence:** C. `me_screen.dart:154-162`, `notification_settings_screen.dart:122-133`.
- **Rating:** Medium · P1 · L1.

**NT-3. Three separate "already asked" flags.**
- **Problem:** after a refusal at launch, EN03 and the 8c sheet still ask. "Bật thông báo" then does nothing, or shows "Thông báo chưa bật…" with no Settings action.
- **Evidence:** C flags, H timing. `reminder_notifications.dart:271-285`, `today_personalize.dart:105-116`, `390-399`, `reminder_screens.dart:1541-1604`.
- **Rating:** Medium · P1 · L2.

**NT-4. The 8c body says "Thông báo chỉ được đặt trên máy tạo nhắc việc." This is wrong: assigned reminders also ring on the assignee's devices.**
- **Evidence:** C. ARB 3822, `reminder_models.dart:224-226`.
- **Rating:** Medium · P1 · L1.

**NT-5. The Lặp lại (rules) tab has no "notifications off" card, so rule pushes silently never arrive.**
- **Evidence:** C. `reminder_screens.dart:310-316`, `rule_screens.dart`.
- **Rating:** Medium · P1 · L1.

**NT-6. Inbox.**
- **Problem:** "Đánh dấu đã đọc" marks only the loaded page. A page made only of hidden rows shows "Chưa có thông báo nào", and "Xem thêm" is unreachable.
- **Evidence:** C. `inbox_screen.dart:74-103`, `162-196`.
- **Rating:** Low–Medium · P2 · L1.

**NT-7. Smaller items.**
- **Problem:**
  - The "Gợi ý thông minh" group vanishes while loading or on error (C).
  - The two "enabled" providers can disagree (C/H).
  - Push registration is not retried in the same run if the token was null (H).
- **Rating:** Low · P2 · L1.

### 2.10 Tự lưu outside AS10 and the QueueSheet

**AS-1. Five screens count "how many photos are waiting" five ways, against D-123's "one unit everywhere".**

| Surface | What it counts | Code |
|---|---|---|
| Push | items, all babies | `auto_save_controller.dart:214` |
| Hôm nay banner | groups, labelled "ảnh" though videos are included | `auto_save_today.dart:59-60` |
| Kỷ niệm row | items for the selected baby, including "Đã có" | `auto_save_widgets.dart:497` |
| Tự lưu home | items, every baby | `auto_save_home.dart:74` |
| Review | files, excluding "Đã có" | `auto_save_review.dart:278-282` |

- **Evidence:** C.
- **Rating:** High · P0 · L2 (applies an existing decision).
- **Fix:** add one selector, `waitingFiles(babyId)`, and use it on all five surfaces. Copy: "mục" or "ảnh, video".

**AS-2. Review can pre-tick photos already in Kỷ niệm while that list is loading, so duplicates are uploaded.**
- **Problem:** `alreadySavedProvider` uses `value ?? []`, and `_learn` never re-evaluates.
- **Evidence:** C. `auto_save_review.dart:60-76`, `151-164`.
- **Rating:** High (G1) · P0 · L1.

**AS-3. Review says "Ảnh mới đã được xử lý rồi" while Tự lưu is loading or scanning.**
- **Problem:** the title reads "Có thể có " with an empty name.
- **Evidence:** C. `auto_save_review.dart:284-287`, `636-662`.
- **Rating:** High (G1) · P0 · L1.

**AS-4. Returning to the app quickly stops the check, and nothing restarts it.**
- **Evidence:** C. `auto_save_controller.dart:273-276`, `616-635`, `703-706`.
- **Rating:** Medium · P1 · L1.

**AS-5. Babies other than the selected one are never checked.**
- **Problem:** the `allowed` flag is evaluated only for the selected baby, yet the home names them as checked ("Chưa có ảnh mới có thể có {names}").
- **Evidence:** C. `auto_save_controller.dart:644-650`, `auto_save_widgets.dart:35-89`.
- **Rating:** High · P1 · L1.

**AS-6. "Kiểm tra ảnh mới" and pull-to-refresh can silently do nothing.**
- **Problem:** this happens when no kinds are on, the baby isn't allowed, or the user is not a parent.
- **Evidence:** C. `auto_save_controller.dart:618-651`.
- **Rating:** Medium · P1 · L1.
- **Fix:** expose a `blockedReason` and show it in a notice.

**AS-7. Wrong copy.**
- **Problem:**
  - "Đã lưu từ Tự lưu" also counts manual uploads.
  - A sample that failed offline or from iCloud says "Ảnh này chưa thấy rõ mặt".
  - The samples grid shows "Kỷ niệm chưa có ảnh của {name}" while loading.
  - For `notDetermined`, the button reads "Mở Cài đặt điện thoại" but asks for permission, and AS19 shows "Chưa cho phép" and opens Settings, where iOS has no row yet.
  - "0 tệp mới · {names}" above "12 gợi ý chờ duyệt".
  - "0 / 0 tệp" flashes.
- **Evidence:** C. `auto_save_home.dart:102-120`, `258-262`, `356-360`, `573-582`; `auto_save_setup.dart:673-714`; `auto_save_controller.dart:1160-1182`.
- **Rating:** Medium · P1 · L1.

**AS-8. The Hôm nay banner ignores revoked photo access.**
- **Problem:** "Xem & chọn ảnh" leads to tiles that can't load, and every approve fails.
- **Evidence:** C gating. `auto_save_today.dart:23-36`.
- **Rating:** Medium · P1 · L1.

**AS-9. Review marks items the user never saw as skipped.**
- **Problem:** filtered and folded "Đã có" items are skipped and never suggested again. "Hoàn tác" restores the whole Tự lưu state, rolling back unrelated progress.
- **Evidence:** C. `auto_save_review.dart:858-863`, `auto_save_controller.dart:990-994`, `1085-1088`.
- **Rating:** Medium (G3-lite) · P1 · L1.

**AS-10. Two switches control one "Ảnh mới có thể có bé" push.**
- **Problem:** EN07 `photoSuggestions` controls the server push, and AS19 "Báo khi có ảnh mới" controls the local push. Turning one off doesn't stop the other.
- **Evidence:** C. `notification_settings_screen.dart:184`, `auto_save_controller.dart:562-589`.
- **Rating:** Medium · P1 · **L3** (preferences, Q4).

### 2.11 App update, feedback

**UPD-1. On the blocking UP1 screen, the only CTA can silently do nothing.**
- **Problem:** the `launchUrl` result `false` is ignored.
- **Evidence:** C. `app_update_repository.dart:56-59`.
- **Rating:** High (G2 on a blocking screen) · P1 · L1.

**UPD-2. UP1 says "{count} lần ghi chưa đồng bộ" but counts upload-queue files, including failed and quota-held ones.**
- **Evidence:** C. `app_update_screens.dart:136-145`, `211-215`.
- **Rating:** Medium · P1 · L1.

**FB-1. Feedback with a screenshot has no timeout.**
- **Problem:** Storage retries for up to 10 minutes, and each retry creates a new `requestId`, so duplicate tickets are possible.
- **Evidence:** C. `feedback_repository.dart:77-88`.
- **Rating:** Low · P2 · L1.

---

## 3. What was checked and works

Recorded so the next audit does not redo it:

- **Upload queue:** survives an app kill; rebases paths on iOS update; the `uploads-paused` kill switch has its own copy; transient session errors retry after 30 s; Wi-Fi-only video handling; `_reconcileReady` never marks ready on error; `landingCells` excludes refused, held and failed items.
- **Story publish** awaits the server before "Đã lưu câu chuyện".
- **Keepsake video jobs:** the server sweeps stuck jobs every 15 min; there is a progress ring, specific failure reasons and retry (R `mm14_failed`, apart from KS-4).
- **Purchases:** the store's word is never treated as access; Success appears only when `getCapabilities` says premium; the intent survives restarts; members get the PW07 "Nhờ {name}" path, and the server refuses non-owners.
- **Print:** proof approval is required; the `requestId` is idempotent on unchanged retries; order status streams live; photos come only from already-uploaded originals.
- **Lumi:**
  - text send is optimistic with an idempotent id;
  - "saved" appears only from server results;
  - photos are quoted before upload;
  - voice-permission denied leads to Settings;
  - history and usage screens have loading, error and empty states;
  - the handover health route suppresses AI text (R `su01_quota`).
- **Care:**
  - per-record pending chips;
  - timer "Chỉ trên máy này / Cả nhà đang thấy";
  - the sync banner debounces;
  - History and Stats use skeletons (not "Chưa ghi") until the first value.
- **Join:** closed-invite reasons each have a next step; the code entry handles lockout and network; abandoned anonymous joins are signed out.
- **Notifications:** EN07 master switch falls back to Settings when permanently denied; the 8d card opens Settings; the reminder sync waits for every source.
- **Tự lưu:**
  - the order of home states is coherent;
  - limited access offers "Chọn thêm ảnh" and "Cho phép tất cả";
  - native calls have timeouts;
  - `savedByMonth` counts only after server `ready`.
- **Others:** spending CSV, account data export statuses, and the storage request (v1) behave correctly.

---

## 4. Ranked fix backlog: seven batches by root cause

Each batch fixes one root cause across every flow, so the pattern does not come back elsewhere. Within a batch, items are in priority order. "Owner" = needs an L3 decision first (§5). Everything else is L1/L2 and ready to implement.

| # | Batch (root cause) | Items | Priority | Level | Size |
|---|---|---|---|---|---|
| **1** | **Unknown ≠ zero / empty / Free.** Every `.value ?? []`, `?? 0` and `?? free` on a user-facing state gets loading, error and unknown branches. Goldens are added for each loading or error state. | AI-10, SY-1, ST-1, AU-5, NT-1, AS-2, AS-3, P-1, P-3, AI-11, KS-3, SY-2, ST-5, KS-8, AS-7 (samples), P-2, P-8 (placeholders), AI-15 (skeleton) | P0 → P1 | L1 | M |
| **2** | **Upload pipeline honesty.** Shared `uploadPreflight` for every entry point; `enqueue` publishes preparing x/N; explicit pill precedence; quota retry on storage or plan change; error classification (refused / file gone / disk full / network); re-reserve after 24 h; pending notes visible; keepsake card done screen tied to the queue item. | UP-1, UP-2, UP-3, UP-7, KS-1, UP-6, UP-4, UP-5, UP-8, UP-10, KS-2, KS-5, UP-9, UP-11, KS-7 | P0 → P2 | L1/L2 (+Q1, Q2 owner) | L |
| **3** | **Data-loss guards.** Merge order, pending-write checks before sign-out and delete, pending-count source, review "reviewed" set, undo scope, clarification text kept. | AU-1, AU-3, AI-5, SY-3, AS-9, SY-4 | P0 → P1 | L1/L2 | M |
| **4** | **Error mapping: one reason, one copy, one action.** Lumi kept reasons and exhausted lifecycle; `retryable` honoured; FirebaseFunctionsException code map; join network vs closed vs full; auth "exists" screen; profile toast; handover and keepsake failure copy; print timeout and country; account-delete reasons; weekly-recap reasons. | AI-1, AI-2, FJ-1, FJ-2, AU-4, AU-2, AI-3, AI-7, AI-8, AI-12, KS-4, PR-2, PR-4, UPD-1, FJ-4, AI-6, AI-9, AI-15, FJ-5, AU-6 | P0 → P2 | L1/L2 | L |
| **5** | **Counts agree.** One Tự lưu waiting-files selector; storage from one source and one rounding (with reserved); seats incl. pending invites; Stats window labels; UP1 label; AI quota used+reserved. | AS-1, ST-2, FJ-3, SY-5, UPD-2, AI-13, AI-4, P-9 | P0 → P2 | L2 (+Q2, Q3, Q6 owner) | M |
| **6** | **Permissions and settings truth.** One "OS prompt shown" flag; OS-off state in Me and EN07; rules tab card; 8c copy; Tự lưu notDetermined label; scan blocked reasons; other babies checked; access-revoked banner. | NT-2, NT-3, NT-4, NT-5, AS-4, AS-5, AS-6, AS-8, AS-7, NT-6, NT-7, AS-10 (owner) | P1 → P2 | L1/L2 (+Q4) | M |
| **7** | **Purchases before the store opens; print and premium polish.** CTA loading and verifying line; plan-screen sheet actions; pending→success race; store-load retry; non-manager storage variant; full-storage fallback action; print file job; payment-method copy; order detail; plurals. | ST-3, ST-4, PR-1, PR-3, P-4, P-5, P-6, P-7, PR-5, EX-1, FB-1 | P1 → P2 (P0 for the store-opening release) | L1/L2 | M |

**Recommended order:**

- **This week:** batch 1 P0 items (AI-10, SY-1, ST-1, AU-5, NT-1, AS-2, AS-3); batch 3 P0 items (AU-1, AU-3, AI-5); and the one-line fixes AU-4 and FJ-1.
- **Next:** batch 2 builds on the AS10 and QueueSheet work in progress. Start it once that lands, so the pre-check and per-file status are shared rather than duplicated. Then batch 4.
- **Then:** batches 5 and 6.
- **Before opening the store:** batch 7.

**Verification for every batch:** add goldens for each new loading, error or refused state (Light and Night care × vi and en), run a fresh render before and after, and open every diff. For ST-1, UP-1/2 and FJ-2, also do a device run on dev Firebase.

---

## 5. Owner decisions (L3), isolated

Each comes with a recommendation. Current behaviour is kept until the owner decides.

| Q | Decision | Recommendation |
|---|---|---|
| Q1 | Refuse a file larger than the whole plan (e.g. a 1.5 GB video on Free 1 GB) at pick time? | **Yes:** refuse at pick with "Video lớn hơn dung lượng gói ({limit})" plus "Xem Premium". Today it waits forever. |
| Q2 | Does "full" in Tôi › Dung lượng include space reserved by uploads in flight? | **Yes:** the server already decides on `used + reserved`, so the screen should match. Show "đang giữ chỗ cho N mục" as a separate line. |
| Q3 | Do pending writer invites hold a seat in the "x / y chỗ" shown to the family? | **Yes, and say so:** "2 / 3 chỗ · 1 lời mời đang giữ chỗ". Also return the seat state in the invite preview, so a joiner learns the family is full before tapping "Tham gia". |
| Q4 | One switch or two for the "Ảnh mới có thể có bé" push (EN07 `photoSuggestions` vs AS19 "Báo khi có ảnh mới")? | **One:** both rows read and write `photoSuggestions`. |
| Q5 | May handover auto-refresh on open (and AiMomentNudge) spend shared AI credits without a tap? | **No:** show "Có ghi nhận mới · Tạo lại" and spend only on tap, unless the server already treats these as free. Confirm the charging rule first. |
| Q6 | Canonical terms: "Gói của hộ" vs "Gói của gia đình"; "Cơ bản" vs "Free"; seat noun ("người ghi" / "người chăm sóc"); "Credit" vs "lượt"; the free-template button label. | "Gói của gia đình", "Free" (v2), "chỗ người ghi", "lượt", "Dùng mẫu miễn phí". |
| Q7 | Should a non-manager on Premium see "Thêm dung lượng" at all? | **No:** show the member variant "Nhờ {name} thêm dung lượng" (the plan screen already hides it). Recorded here because it touches entitlements; the UI part is L2. |
| Q8 | Print file export: move to a background job with progress (new server job type)? | **Yes**, like keepsake videos. Until then, allow closing with "Đang dựng file… sẽ báo khi xong" only if the server keeps the result; otherwise keep the blocking state but add elapsed time. |
