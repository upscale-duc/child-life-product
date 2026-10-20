# Product UX journey audit

**Quan sát từ code** trừ các câu đánh dấu “giả thuyết/cần device/chưa xác minh”. Chưa có session device hoặc user study của lượt audit này; widget/golden artifacts sẵn có không chứng minh trải nghiệm runtime hiện tại. Entry points dùng route/module thật, tên UI có thể thay theo locale/role/flag.

Mỗi journey ghi đúng 10 khía cạnh được yêu cầu. Next action có nhãn “đề xuất” là opportunity, không mô tả feature đã ship.

## J01 · Bắt đầu và tạo hồ sơ bé

Bằng chứng: [E01 · `bootstrap`](../../apps/mobile/lib/app/bootstrap.dart#L24); [E02 · `routerProvider`](../../apps/mobile/lib/app/router.dart#L130); [E03 · `membershipsProvider / sessionProvider`](../../apps/mobile/lib/app/session.dart#L51); [E04 · `SelectedBabyId / HomeShell`](../../apps/mobile/lib/features/home/home_shell.dart#L50); [E36 · `maxBabyAgeYears / baby profile contracts`](../../packages/contracts/src/baby.ts#L45).

| #   | Khía cạnh                 | Audit                                                                                                                           |
| --- | ------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Entry point hiện tại      | Welcome/tour hoặc auth; returning-user path dựa device preferences.                                                             |
| 2   | Screens và bước           | Đăng nhập → who/relation → baby profile → trackers → Today. Thêm bé từ baby switcher dùng lại setup.                            |
| 3   | User inputs               | Identity, tên người dùng, nickname, DOB, gender tùy chọn, timezone, country và trackers.                                        |
| 4   | System processing         | Firebase Auth; createBabyProfile tạo family/profile/member idempotent; đợi membership cập nhật trước routing.                   |
| 5   | Loading và error          | SessionLoading/splash; cache rỗng không được tin như không có bé; backend DOB/limit/network errors. Live auth failure chưa thử. |
| 6   | Completion state          | Today với selected membership và empty tour nếu chưa có record.                                                                 |
| 7   | Next action               | Có quick log/tour. Đề xuất chỉ một “ghi việc đầu tiên” theo role, không thêm onboarding form mới.                               |
| 8   | Friction                  | Giả thuyết: nhiều trường trước value đầu; guest vs saved account khó hiểu. Chưa có quan sát user/device.                        |
| 9   | Missing/unverified states | Không thấy thiếu state hệ thống rõ từ mẫu đã đọc; cần thử auth cancel, offline fresh install, callback chậm và large text.      |
| 10  | Improvement cụ thể        | Đo setup completion→first useful action; kiểm thông điệp consent/role theo VI/EN và thời gian thực trước rút bớt bước.          |

## J02 · Thêm Moment thủ công và upload

Bằng chứng: [E10 · `UploadQueue.enqueue / cancel / FileQueueStore`](../../apps/mobile/lib/features/memories/upload_queue.dart#L777); [E11 · `BackgroundTransport`](../../apps/mobile/lib/features/memories/background_uploads.dart#L20); [E14 · `createMemory / processUpload / purgeMediaBin`](../../firebase/functions/src/memories.ts#L157); [E16 · `MemoryRepository.watchMemories / watchMedia`](../../apps/mobile/lib/features/memories/memory_repository.dart#L22).

| #   | Khía cạnh                 | Audit                                                                                                                      |
| --- | ------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| 1   | Entry point hiện tại      | Memories tab +; share extension/inbox cũng đưa vào cùng queue.                                                             |
| 2   | Screens và bước           | Chọn ảnh/video hoặc ghi chú → ngày/caption/mốc/album/audience → Add → queue/pill → timeline/viewer.                        |
| 3   | User inputs               | Media, date mode/capture date, caption, milestone, album, parents/family, notifyFamily.                                    |
| 4   | System processing         | Prepare/copy/compress/remux → persist queue → createMemorySession/reserve → native upload → processUpload/recomputeMemory. |
| 5   | Loading và error          | Pending session, waiting Wi-Fi/quota, preparing, uploading, failed/paused/unreadable/cancelled; byte sent chưa phải ready. |
| 6   | Completion state          | Queue item uploaded và server ready/published là các mốc riêng. Code đã có pill và reconciliation.                         |
| 7   | Next action               | Xem media, đưa vào album, tạo card/video hoặc share. Đề xuất CTA sau ready, không sau chỉ prepare.                         |
| 8   | Friction                  | MEM-06: ledger count tới sớm; FAM-01: task còn local khi đổi account. Giả thuyết progress dài khó hiểu cần device.         |
| 9   | Missing/unverified states | Chưa có ledger queued→ready rõ; cần thử server unreadable sau upload, token hết hạn lúc app đóng và cancel/retry.          |
| 10  | Improvement cụ thể        | Giữ một queue; bổ sung state reconciliation/UID boundary, đo time-to-ready và loss/retry, không xây uploader mới.          |

## J03 · Auto Save lần đầu và review

Bằng chứng: [E05 · `autoSaveSupported / AutoSaveNative`](../../apps/mobile/lib/features/auto_save/auto_save_native.dart#L9); [E06 · `AutoSaveTuning / matchBaby / groupAndRank`](../../apps/mobile/lib/features/auto_save/auto_save_engine.dart#L118); [E07 · `AutoSave / AutoSaveBackground`](../../apps/mobile/ios/Runner/AutoSave.swift#L14); [E08 · `AutoSaveStore / AutoSaveState / LedgerState`](../../apps/mobile/lib/features/auto_save/auto_save_store.dart#L446); [E09 · `AutoSaveController.approve / recordUploaded`](../../apps/mobile/lib/features/auto_save/auto_save_controller.dart#L835); [E53 · `autoSaveFlagProvider`](../../apps/mobile/lib/features/auto_save/auto_save_widgets.dart#L33).

| #   | Khía cạnh                 | Audit                                                                                                                            |
| --- | ------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Entry point hiện tại      | Memories Auto Save hoặc Today banner, chỉ iOS và có rollout/role.                                                                |
| 2   | Screens và bước           | Intro → consent → chọn bé + ảnh mẫu → Photos permission → scan → review near-copy groups → chọn audience/confirm → queue.        |
| 3   | User inputs               | Ảnh mẫu, thời gian quét, chọn/bỏ/chuyển bé, reject, loại ảnh/video, quyền Photos, thông báo.                                     |
| 4   | System processing         | PhotoKit thay đổi → local Vision prints → matchBaby/groupAndRank → pending local; chỉ ảnh approve mới upload.                    |
| 5   | Loading và error          | Full/limited/denied permission; no faces/no candidates, scan progress, iCloud missing và quota; native call fail soft.           |
| 6   | Completion state          | Approve mới đưa vào queue; hiện savedByMonth tăng theo queued. Đã lưu cloud chưa được suy ra ở đây.                              |
| 7   | Next action               | Mở queue hoặc Memories; chỉnh ảnh mẫu/settings và review ảnh mới khi có.                                                         |
| 8   | Friction                  | Tên “Tự lưu” có thể khiến tưởng không cần duyệt; đây là giả thuyết. Threshold nhận diện chưa có real-photo benchmark.            |
| 9   | Missing/unverified states | Queued-vs-ready ledger và cleanup khi account đổi thiếu boundary rõ; Android Auto Save không thuộc beta hiện tại.                |
| 10  | Improvement cụ thể        | Giải thích review/control ngay intro; đo precision bằng ảnh đồng ý tham gia beta, có “không phải bé” và undo sẵn để tái sử dụng. |

## J04 · Tìm lịch sử, album và chia sẻ nội bộ

Bằng chứng: [E15 · `recomputeEffective / album audience`](../../firebase/functions/src/albums.ts#L44); [E16 · `MemoryRepository.watchMemories / watchMedia`](../../apps/mobile/lib/features/memories/memory_repository.dart#L22); [E28 · `activeMember / canReadCare / assistantSharer`](../../firebase/firestore.rules#L18); [E29 · `uploadAllowed / canSee / shared`](../../firebase/storage.rules#L32).

| #   | Khía cạnh                 | Audit                                                                                                                |
| --- | ------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| 1   | Entry point hiện tại      | Memories timeline/age filters/albums và viewer.                                                                      |
| 2   | Screens và bước           | Chọn ngày/tuổi/album → mở ảnh → chọn/add album → audience confirmation → family view.                                |
| 3   | User inputs               | Khoảng thời gian, album name/items, cover và parents/family.                                                         |
| 4   | System processing         | Firestore live streams + effectiveAudience từ item/album/story; relative query shared only.                          |
| 5   | Loading và error          | Empty album/timeline, offline/cached và repository errors có code; stream có hard cap và không load more.            |
| 6   | Completion state          | Album/media xuất hiện đúng role; chia sẻ là widening có thể ảnh hưởng nhiều item.                                    |
| 7   | Next action               | Family xem/love; parent tạo story/card. Đề xuất next action gắn nội dung đã chọn.                                    |
| 8   | Friction                  | MEM-02: ảnh cũ ngoài cap biến mất khỏi tìm kiếm client. Giả thuyết người dùng khó hiểu effectiveAudience cần device. |
| 9   | Missing/unverified states | Không có pagination boundary/end-of-history rõ cho các stream capped.                                                |
| 10  | Improvement cụ thể        | Truy vấn theo range/cursor; test 1.001/5.001 và nhiều năm; giữ cảnh báo ảnh vẫn shared qua album/story khác.         |

## J05 · Thiệp và Milestone Magic

Bằng chứng: [E23 · `PremiumKeepsakeEditor / _save`](../../apps/mobile/lib/features/keepsakes/premium_keepsake_editor.dart#L34); [E24 · `resolveKeepsakeCopy / premiumTextFit`](../../apps/mobile/lib/features/keepsakes/keepsake_personalization.dart#L8); [E31 · `_MemorySheet._save / createMilestoneMemory`](../../apps/mobile/lib/features/milestones/milestone_sheets.dart#L352); [E58 · `openMilestoneCard`](../../apps/mobile/lib/features/milestones/milestone_card_link.dart#L75); [E60 · `keepVideoDraft / keepCardDraft / resumeAfterPurchase`](../../apps/mobile/lib/features/keepsakes/keepsake_resume.dart#L136).

| #   | Khía cạnh                 | Audit                                                                                                                               |
| --- | ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Entry point hiện tại      | Memories card entry, nudge dịp, hoặc milestone detail/MS01 “Giữ khoảnh khắc”.                                                       |
| 2   | Screens và bước           | Chọn occasion/template/tier → preview/editor → crop/text/format/locale → export → done → save/share.                                |
| 3   | User inputs               | Ảnh, crop/zoom, tên/ngày/lời nhắn; premium fields/confirmation tùy template, nhạc cho video premium.                                |
| 4   | System processing         | Template layers + copy fallback + text-fit; export image local; lưu qua memory queue; premium gate/resume nếu cần.                  |
| 5   | Loading và error          | Thiếu ảnh/field, text không fit, loading artwork/export, quota/gate errors. Không coi local PNG là server-ready.                    |
| 6   | Completion state          | Thành phẩm cục bộ + queued memory; hoàn tất cloud sau upload/processing.                                                            |
| 7   | Next action               | Lưu vào thư viện máy, chia sẻ hoặc xem trong Memories; không tự mở family audience.                                                 |
| 8   | Friction                  | Giả thuyết: nhiều template khó chọn, long VI copy/crop có thể lỗi thực tế; test widget chưa chứng minh chất lượng full output.      |
| 9   | Missing/unverified states | Chưa xác minh background/restart giữ state của editor premium; cần thử trước kết luận draft loss. Không gọi đây là gap đã xác nhận. |
| 10  | Improvement cụ thể        | Thử đúng 4 mẫu phase hiện tại ở VI/EN/format đã hỗ trợ; giữ native preview, validate local and server và review thành phẩm.         |

## J06 · Tạo Memory Story video

Bằng chứng: [E17 · `requestMemoryStory / retryMemoryStory / sweepKeepsakeJobs`](../../firebase/functions/src/keepsake-jobs.ts#L105); [E18 · `completeKeepsakeJob`](../../firebase/functions/src/keepsake-jobs.ts#L604); [E19 · `runJob / finish / progress`](../../apps/renderer/src/job.ts#L86); [E21 · `stories / storyOf`](../../apps/renderer/src/compositions/registry.tsx#L37); [E25 · `MemoryStoryTemplatesScreen / Photos / Finish / Job`](../../apps/mobile/lib/features/keepsakes/memory_story_screens.dart#L288).

| #   | Khía cạnh                 | Audit                                                                                                                       |
| --- | ------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| 1   | Entry point hiện tại      | Memories video entry hoặc occasion/template preview.                                                                        |
| 2   | Screens và bước           | Templates → photos/order/scene preview → finish (text/music/audience) → request → job progress → ready/play/download/share. |
| 3   | User inputs               | Template/version, media IDs và thứ tự, copy/locale, music/none, audience; requestId giữ khi retry.                          |
| 4   | System processing         | Server validate role/catalog/media/quota → Cloud Tasks → private renderer → completeKeepsakeJob → Memories.                 |
| 5   | Loading và error          | Photo-count, missing photo/music, busy/quota/premium, queued/rendering/timeout/failed; retry job có sẵn.                    |
| 6   | Completion state          | Completed renderer chưa phải memory filed; JobScreen chờ output/media và có retry/share sau ready.                          |
| 7   | Next action               | Xem full video, download/share và đưa gia đình xem nếu chọn; đề xuất source-review khi retry template đổi.                  |
| 8   | Friction                  | MEM-01/CON-01 ảnh hưởng reliability; MEM-05 preview version mismatch. Chất lượng nhạc/motion chưa được quan sát thực.       |
| 9   | Missing/unverified states | Artifact fencing và deletion cancel thiếu; “render xong nhưng chưa filed” cần test fault recovery.                          |
| 10  | Improvement cụ thể        | Đóng hai P0, verify end-to-end on device; phân biệt runtime/job tests với full Remotion render + nghe audio.                |

## J07 · Story viết bằng AI và external link

Bằng chứng: [E26 · `weekSources / suggestStory / suggestForAll / saveStory`](../../firebase/functions/src/stories.ts#L220); [E51 · `createShareLink / projection / handleShare / revokeShareLink`](../../firebase/functions/src/links.ts#L373).

| #   | Khía cạnh                 | Audit                                                                                                                       |
| --- | ------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| 1   | Entry point hiện tại      | Stories view, weekly suggestion hoặc tạo/edit story thủ công.                                                               |
| 2   | Screens và bước           | Đọc draft → edit blocks/photos → AI assist tùy chọn → save audience/notify → share link options → recipient web.            |
| 3   | User inputs               | Title/paragraph/media, tone/length op, locale, audience, expiry/passcode/hideIdentity/allowDownload.                        |
| 4   | System processing         | weekSources text/counts + provider guard/fallback; saveStory tính ảnh được mở quyền; link projection giới hạn media shared. |
| 5   | Loading và error          | Ít hơn 5 items/no flag/weekly limit/budget, AI unavailable/fallback, missing media, link expired/revoked/passcode errors.   |
| 6   | Completion state          | Saved story; external link chỉ cho story saved. Người nhận thấy projection hiện còn hợp lệ.                                 |
| 7   | Next action               | Copy/share link, xem/revoke ở sharedOut; người nhận không buộc tạo account cho link này.                                    |
| 8   | Friction                  | MEM-03: scheduled story luôn VI. Giả thuyết count/copy chưa đủ cảm xúc hoặc review private photos bị bỏ qua cần user test.  |
| 9   | Missing/unverified states | Chưa xác minh link khi author bị revoke hoặc source xóa đồng thời; không khẳng định thiếu các state expiry.                 |
| 10  | Improvement cụ thể        | Sửa locale; kiểm sharing boundary và browser states; monthly recap chỉ mở rộng sau data/privacy gates.                      |

## J08 · Lưu mốc rồi giữ thành kỷ niệm

Bằng chứng: [E31 · `_MemorySheet._save / createMilestoneMemory`](../../apps/mobile/lib/features/milestones/milestone_sheets.dart#L352); [E32 · `FirestoreMilestoneRepository.linkMemory / remove`](../../apps/mobile/lib/features/milestones/milestone_repository.dart#L250); [E58 · `openMilestoneCard`](../../apps/mobile/lib/features/milestones/milestone_card_link.dart#L75).

| #   | Khía cạnh                 | Audit                                                                                                       |
| --- | ------------------------- | ----------------------------------------------------------------------------------------------------------- |
| 1   | Entry point hiện tại      | Utilities milestones, Today suggested milestone hoặc rhythm MS01.                                           |
| 2   | Screens và bước           | Reference/custom milestone → observed date/note/photos → save → create memory hoặc card → milestone detail. |
| 3   | User inputs               | Tên mốc/ngày/note, ảnh local, audience; template tier nếu tạo card.                                         |
| 4   | System processing         | Lưu record; ảnh giữ local tới createMilestoneMemory; queue/create rồi best-effort backlink memoryIds.       |
| 5   | Loading và error          | Validation, write errors, pending photo; unawaited backlink không chặn “đã tạo” toast.                      |
| 6   | Completion state          | Milestone observed; memory có tag nhưng backlink có thể chưa xong.                                          |
| 7   | Next action               | Xem ký ức/card từ mốc, thêm note. Đề xuất pending-link status chỉ khi có việc chưa sync.                    |
| 8   | Friction                  | CON-03: lost update/crash giữa hai writes. Giả thuyết người dùng hiểu “lưu mốc” đã lưu ảnh cần device.      |
| 9   | Missing/unverified states | Không có durable retry/outbox cho backlink hoặc báo kết quả link riêng.                                     |
| 10  | Improvement cụ thể        | Atomic link/idempotent repair; giữ snapshot tag khi mốc bị xóa và không nhân đôi memories.                  |

## J09 · Mời người thân và nhận vai trò

Bằng chứng: [E03 · `membershipsProvider / sessionProvider`](../../apps/mobile/lib/app/session.dart#L51); [E04 · `SelectedBabyId / HomeShell`](../../apps/mobile/lib/features/home/home_shell.dart#L50); [E27 · `createInvite / acceptInvite / updateMember / removeMember`](../../firebase/functions/src/family.ts#L101); [E28 · `activeMember / canReadCare / assistantSharer`](../../firebase/firestore.rules#L18).

| #   | Khía cạnh                 | Audit                                                                                                                       |
| --- | ------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| 1   | Entry point hiện tại      | Family screen từ header/Tôi; code/deep link/my emailed invites.                                                             |
| 2   | Screens và bước           | Chọn relation/role/rights → code/link/email → preview → join identity/account hoặc guest → membership → đúng tab theo role. |
| 3   | User inputs               | Relation khác quyền; display name, email invite, extraRights, role, code/token; người nhận chọn cách lưu account.           |
| 4   | System processing         | Invite hash/token/rate-limit/7-day TTL; accept transaction một lần; đợi membership stream để route.                         |
| 5   | Loading và error          | Wrong/locked/expired/revoked/used/already member; anonymous save/merge và wait states có implementation.                    |
| 6   | Completion state          | Member active; parent Today, relative Memories, caregiver Care theo tabs/rights.                                            |
| 7   | Next action               | Ghi Care đầu tiên hoặc xem/love ảnh shared; owner xem member detail.                                                        |
| 8   | Friction                  | Giả thuyết role terms/guest permanence chưa rõ; không có user research khẳng định tỷ lệ bỏ cuộc.                            |
| 9   | Missing/unverified states | Không thấy thiếu invitation closed state; cần thử mở link từ app tắt, code collision/rate-limit và app account khác.        |
| 10  | Improvement cụ thể        | Đo invitation→accepted→first role-appropriate action bằng operational aggregates; giải thích quyền ngắn gọn dùng UI sẵn.    |

## J10 · Thu hồi quyền, logout và đổi gia đình

Bằng chứng: [E03 · `membershipsProvider / sessionProvider`](../../apps/mobile/lib/app/session.dart#L51); [E04 · `SelectedBabyId / HomeShell`](../../apps/mobile/lib/features/home/home_shell.dart#L50); [E12 · `StorageMediaBytes.read / playable / file`](../../apps/mobile/lib/features/memories/media_bytes.dart#L33); [E13 · `signOutThisDevice / PushRegistration._leave`](../../apps/mobile/lib/features/memories/push_registration.dart#L368); [E27 · `createInvite / acceptInvite / updateMember / removeMember`](../../firebase/functions/src/family.ts#L101); [E59 · `LostAccessScreen / avatar invalidation`](../../apps/mobile/lib/features/family/join_screens.dart#L788).

| #   | Khía cạnh                 | Audit                                                                                                                                      |
| --- | ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| 1   | Entry point hiện tại      | Member detail đổi quyền/expiry/remove; account logout/remote signout; baby switcher.                                                       |
| 2   | Screens và bước           | Owner xác nhận thay đổi → member stream/guard đổi quyền → lost-access screen; logout→auth→B login.                                         |
| 3   | User inputs               | Member/role/access date, selected baby; xác nhận sign-out khi có uploads theo UI hiện tại.                                                 |
| 4   | System processing         | Server membership/time deny; expire job; client forget avatar; session membership tính lại. Local cache/queue chưa có UID boundary đầy đủ. |
| 5   | Loading và error          | Offline cache, expiry trong khi mở app, denied next server read; cached local bytes không bị Rules kiểm lại.                               |
| 6   | Completion state          | Revoked member không được request mới; chưa đủ chứng minh dữ liệu local đã xóa.                                                            |
| 7   | Next action               | Chọn bé còn quyền hoặc xin invite lại; account B chỉ được mở state của B.                                                                  |
| 8   | Friction                  | FAM-01; một account có role khác từng bé có thể khiến tab đổi — cần kiểm clarity trên máy.                                                 |
| 9   | Missing/unverified states | Cleanup native tasks/media/face/resume state khi logout/revoke thiếu contract chung.                                                       |
| 10  | Improvement cụ thể        | Ưu tiên session lifecycle, test offline/same-install accounts/two-family role changes trước bổ sung family dashboard.                      |

## J11 · Care nhanh và phối hợp bàn giao

Bằng chứng: [E04 · `SelectedBabyId / HomeShell`](../../apps/mobile/lib/features/home/home_shell.dart#L50); [E33 · `TodayForBabySection / forBabyCardsProvider`](../../apps/mobile/lib/features/today/today_for_baby.dart#L45); [E35 · `personalizedDay / updatePersonalization / reservePersonalizedDigest`](../../firebase/functions/src/personalization-v2.ts#L398); [E43 · `worker health / rules / model / settle pipeline`](../../firebase/functions/src/assistant-worker.ts#L444).

| #   | Khía cạnh                 | Audit                                                                                                               |
| --- | ------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| 1   | Entry point hiện tại      | Today quick-log/timer, Care tab, Lumi hoặc handover entry.                                                          |
| 2   | Screens và bước           | Chọn record/timer → nhập/xác nhận → timeline; handover xem summary/nhận việc/acknowledge theo phần v2.              |
| 3   | User inputs               | Loại/lượng/thời điểm/interval/timer; assignee/work revision khi claim.                                              |
| 4   | System processing         | Shared per-baby records, overlap/conflicts, server coordination; nguồn thiếu log không được hiểu là bé không làm.   |
| 5   | Loading và error          | Offline pending/conflict/timer đang chạy; summary fallback và quyền role. Scope audit không chạy mọi care widget.   |
| 6   | Completion state          | Record/sleep timer shared hoặc handover acknowledged/claim state rõ.                                                |
| 7   | Next action               | Người chăm tiếp nhận việc; Today đề xuất phù hợp hoặc giữ milestone nếu phát hiện kỹ năng.                          |
| 8   | Friction                  | Giả thuyết độ nhận biết ai đã nhận việc/chuyển ca khi hai máy offline chưa biết; không nói handover claim bị thiếu. |
| 9   | Missing/unverified states | Cross-device OS/device behavior chưa xác minh; underlying model có revision/claim rồi.                              |
| 10  | Improvement cụ thể        | Device two-person script và accuracy sources; không mở rộng AI medical interpretation trước content validation.     |

## J12 · Home cá nhân hóa, sổ tay và digest

Bằng chứng: [E33 · `TodayForBabySection / forBabyCardsProvider`](../../apps/mobile/lib/features/today/today_for_baby.dart#L45); [E34 · `personalizedSourceCardsProvider`](../../apps/mobile/lib/features/rhythm/personalization_sources.dart#L22); [E35 · `personalizedDay / updatePersonalization / reservePersonalizedDigest`](../../firebase/functions/src/personalization-v2.ts#L398); [E50 · `PersonalImpression / personalEvent`](../../apps/mobile/lib/features/rhythm/personalization_events.dart#L25).

| #   | Khía cạnh                 | Audit                                                                                                                       |
| --- | ------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| 1   | Entry point hiện tại      | Today “Dành cho bé hôm nay”, personal day, interests/preferences và notification settings.                                  |
| 2   | Screens và bước           | Xem lý do/primary card → open → save/intend/tried/helpful/hide; context/focus/notebook; bật digest chọn install/time.       |
| 3   | User inputs               | Interests/fewer, capacity/focus, note scope/expiry, feedback outcome, digest consent/time/quiet hours.                      |
| 4   | System processing         | Eligibility/expiry/ranking theo nguồn; no health suggestions when health; reserve unique digest lease và local OS schedule. |
| 5   | Loading và error          | Loading/stale/expired/no published content; fallback; permission disabled; safe no-op khi digest không đủ điều kiện.        |
| 6   | Completion state          | Context/note/response server state và notification đã schedule; schedule chưa chứng minh delivery.                          |
| 7   | Next action               | Thử một hoạt động rồi feedback đúng thời điểm; work/handovers có next step sẵn.                                             |
| 8   | Friction                  | Giả thuyết nhiều card tranh primary/cognitive load; MET-01: impressions/outcomes aggregate chưa đủ nối cohort.              |
| 9   | Missing/unverified states | Chưa có device evidence delivery/restart/install transfer; không thiếu consumer digest ở snapshot này.                      |
| 10  | Improvement cụ thể        | Giữ at-most supporting cards và source reasons; đo actual usefulness; test quiet hours/day rollover và two installs.        |

## J13 · Lumi: hỏi dữ liệu, ghi và xác nhận

Bằng chứng: [E41 · `openAiModelGateway / buildUnderstandRequest`](../../firebase/functions/src/assistant-model.ts#L767); [E42 · `OPENAI_MODEL / OPENAI_MODEL_UNDERSTANDING / assistantGateway`](../../firebase/functions/src/index.ts#L1407); [E43 · `worker health / rules / model / settle pipeline`](../../firebase/functions/src/assistant-worker.ts#L444); [E44 · `assistantRead / allowsAssistantRead / read cards`](../../firebase/functions/src/assistant-reads.ts#L954); [E45 · `assistantPool / assistantUsage / recentUsage`](../../firebase/functions/src/assistant-usage.ts#L78); [E46 · `purgeAssistantForUser / purgeAssistantForBaby / TTL`](../../firebase/functions/src/assistant-lifecycle.ts#L89).

| #   | Khía cạnh                 | Audit                                                                                                                               |
| --- | ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Entry point hiện tại      | Lumi floating entry hoặc assistant routes với selected child scope.                                                                 |
| 2   | Screens và bước           | Consent lần đầu → chat text/voice/photo → rules/model → clarify/read_card/draft → confirm/edit/cancel → record hoặc module link.    |
| 3   | User inputs               | Natural language VI/EN, time clarification, attachment, xác nhận draft; scope không do model quyết định.                            |
| 4   | System processing         | Trusted role/timezone, schema/evidence/allowlist; free rules/known reads; model khi cần; writers ghi sau confirm và settle credits. |
| 5   | Loading và error          | Health route, consent required, denied role, no credit, network timeout, invalid output, pending clarification/retry/reconnect.     |
| 6   | Completion state          | Có câu trả lời nguồn/asOf hoặc confirmed record; read-only card mở đúng module/bé. Live semantic accuracy chưa verify.              |
| 7   | Next action               | Xem nguồn/module, sửa/xóa vừa ghi, theo dõi hoặc thử activity; không tự chạy lời khuyên y tế.                                       |
| 8   | Friction                  | LUM-01: chi phí ước tính; LUM-02: model/prompt quality mới chưa có live evaluation. FAM-01 ảnh hưởng local context/privacy.         |
| 9   | Missing/unverified states | Không coi tests fake-provider là chứng minh VI/EN model thật. OS voice/photo permissions và reconnect cần device.                   |
| 10  | Improvement cụ thể        | Đóng eval gate, token telemetry và đúng scope; thêm memory-generation tool chỉ sau nguồn/share policy được xác định.                |

## J14 · Premium và tiếp tục công việc đang làm

Bằng chứng: [E17 · `requestMemoryStory / retryMemoryStory / sweepKeepsakeJobs`](../../firebase/functions/src/keepsake-jobs.ts#L105); [E23 · `PremiumKeepsakeEditor / _save`](../../apps/mobile/lib/features/keepsakes/premium_keepsake_editor.dart#L34); [E52 · `ResumeDrafts / keep / saved / drop`](../../apps/mobile/lib/features/premium/purchase_resume.dart#L14); [E57 · `loadEntitlementContext / checkCapability`](../../firebase/functions/src/entitlements.ts#L106); [E60 · `keepVideoDraft / keepCardDraft / resumeAfterPurchase`](../../apps/mobile/lib/features/keepsakes/keepsake_resume.dart#L136).

| #   | Khía cạnh                 | Audit                                                                                                                                                    |
| --- | ------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Entry point hiện tại      | Premium template/capability gate, plan/settings hoặc paywall context.                                                                                    |
| 2   | Screens và bước           | Chọn template → ensureAllowed → paywall → store purchase/verify → refresh capabilities → resume draft/editor.                                            |
| 3   | User inputs               | Offer/store account, lựa chọn plan, draft local; không thay giá/credit trong audit.                                                                      |
| 4   | System processing         | Server grants/bindings/quota; snapshot request and resume ref; local draft serialization.                                                                |
| 5   | Loading và error          | Cancelled/pending/rejected/binding mismatch/network/quota; Premium quota mock từng invalid override; thay đổi song song đã sửa và analyze chạy lại xanh. |
| 6   | Completion state          | Capability đúng và resume task; store purchase thực chưa test lượt audit.                                                                                |
| 7   | Next action               | Tiếp tục tạo thành phẩm và chỉ count conversion sau verify, không sau mở paywall.                                                                        |
| 8   | Friction                  | QA-01 đã đóng; giả thuyết paywall interruption/draft fidelity sau kill chưa xác minh, không tự kết luận state loss.                                      |
| 9   | Missing/unverified states | Live purchase/refund/revoke + app restart chưa chạy; không gọi toàn bộ Premium missing.                                                                  |
| 10  | Improvement cụ thể        | Giữ quality gate hiện đã xanh; sandbox end-to-end với state/draft fidelity; giữ offer và credits hiện tại.                                               |

## J15 · Lưu trữ, export và xóa dữ liệu

Bằng chứng: [E14 · `createMemory / processUpload / purgeMediaBin`](../../firebase/functions/src/memories.ts#L157); [E18 · `completeKeepsakeJob`](../../firebase/functions/src/keepsake-jobs.ts#L604); [E19 · `runJob / finish / progress`](../../apps/renderer/src/job.ts#L86); [E30 · `babyStep / accountStep / runDeletionJob / runExport`](../../firebase/functions/src/account.ts#L480); [E46 · `purgeAssistantForUser / purgeAssistantForBaby / TTL`](../../firebase/functions/src/assistant-lifecycle.ts#L89); [E51 · `createShareLink / projection / handleShare / revokeShareLink`](../../firebase/functions/src/links.ts#L373).

| #   | Khía cạnh                 | Audit                                                                                                                                  |
| --- | ------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Entry point hiện tại      | Me/storage/account/baby profile; trash và sharedOut.                                                                                   |
| 2   | Screens và bước           | Xem quota/bin → restore/delete/export; owner nhập nickname xác nhận xóa bé → job progress → completion.                                |
| 3   | User inputs               | Target/confirmation, export kind/locale, account ownership transfer khi cần, revoke link.                                              |
| 4   | System processing         | Storage/object purge→recursive docs→assistant cleanup→quota reconcile→verify; jobs idempotent và có resume.                            |
| 5   | Loading và error          | Job step errors/retry, blocked owner conditions, expired export; render đang chạy có thể viết sau lock.                                |
| 6   | Completion state          | Bin restore hoặc verified deletion/export download; cloud purge chưa chứng minh cache OS/download ngoài app biến mất.                  |
| 7   | Next action               | Tải export/revoke link/xem trạng thái job; không tự đánh dấu deleted trước verify.                                                     |
| 8   | Friction                  | CON-01 và FAM-01; user có thể hiểu account deletion xóa mọi shared record dù policy giữ — cần clarity testing.                         |
| 9   | Missing/unverified states | Worker↔delete coordination thiếu ở render; local device purge contract chưa đầy đủ.                                                    |
| 10  | Improvement cụ thể        | P0 fix + emulator race tests; device offline/logout/revoke; validate export thực có phạm vi đúng, không thêm data classes ngoài scope. |

## J16 · Bé lớn lên và đọc ký ức nhiều năm

Bằng chứng: [E16 · `MemoryRepository.watchMemories / watchMedia`](../../apps/mobile/lib/features/memories/memory_repository.dart#L22); [E36 · `maxBabyAgeYears / baby profile contracts`](../../packages/contracts/src/baby.ts#L45); [E37 · `ageInUnit / stageFor / stageBuckets`](../../packages/contracts/src/content.ts#L538); [E38 · `babyAge / ageLong / ageShort`](../../apps/mobile/lib/core/format/age.dart#L8); [E39 · `lbAgeIn / lbStageFor / LbAgeBand`](../../apps/mobile/lib/features/library/content_calc.dart#L8); [E40 · `futureStage.band / journey.stages`](../../apps/landing/src/content/vi.ts#L628).

| #   | Khía cạnh                 | Audit                                                                                                                 |
| --- | ------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| 1   | Entry point hiện tại      | Age labels/Home/stages/library hoặc Memories lọc tháng/năm.                                                           |
| 2   | Screens và bước           | Đổi ngày/tuổi → stage/content Home cập nhật → lịch sử cũ vẫn đọc; không có chapter migration screen.                  |
| 3   | User inputs               | DOB/timezone edits nếu cần, filters và custom milestone.                                                              |
| 4   | System processing         | Calendar age/stage matching/age-based suggestions; same babyId giữ dữ liệu; landing future stages là roadmap.         |
| 5   | Loading và error          | No matching stage/empty historical range; hard stream cap; tuổi cuối tháng giữa core và library khác.                 |
| 6   | Completion state          | Xem giai đoạn và memory lịch sử; chưa chứng minh Chapter 02–04 đầy đủ.                                                |
| 7   | Next action               | Đọc lại/xuất lịch sử hoặc ghi milestone custom; ngoài support scope cần message rõ.                                   |
| 8   | Friction                  | CH-01/CH-02/MEM-02; giả thuyết infant tracker irrelevant với bé lớn cần research, không mặc định phát triển tuổi lớn. |
| 9   | Missing/unverified states | Central supported Chapter policy chưa tìm thấy; không thiếu khả năng lưu DOB lớn hơn 12m.                             |
| 10  | Improvement cụ thể        | Giữ read/export continuity; thống nhất tuổi/scope; chỉ mở roadmap chặng sau khi gate Chapter 01 đạt.                  |

## Đánh giá UX xuyên suốt và script thử thiết bị

| Chủ đề           | Bằng chứng code                                                                                | Điều cần quan sát thực tế                                                                                  |
| ---------------- | ---------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| Discoverability  | Entry Today/Memories/Lumi, nudges, module links đã có                                          | Có tìm được tính năng mà không hướng dẫn; đo task success/time, không suy ra từ số entry                   |
| Cognitive load   | Profile/setup, card/template editors, Home primary + supporting cards                          | Một quyết định chính mỗi màn, phân biệt bắt buộc/tùy chọn, role changes và nhiều bé                        |
| Visual hierarchy | Theme/tokens, Semantics, disabled/loading branches, Light/Night care                           | Kiểm large text/VoiceOver/TalkBack, tương phản, focus, keyboard, safe area và reduced motion trên màn thật |
| Emotional value  | Milestone→Moment→card/story và family album có nền tảng                                        | Parent có muốn giữ/chia sẻ thành phẩm, tránh copy khẳng định người/sự kiện chưa xác nhận                   |
| Empty states     | First Today tour, permission denied/limited, no content/photos, no stage, quota/error branches | Text có giúp hoàn tất việc thay vì dẫn vòng; empty-data khác offline khác no-access                        |
| Trust & recovery | Private audience, sources/asOf, review photos, retry/bin/consent/revoke                        | Người dùng hiểu đâu đã lưu cloud/đã chia sẻ/AI suy luận; phục hồi sau mạng yếu/app kill                    |

Ma trận device tối thiểu: iOS + Android; VI + EN; Light + Night care; font mặc định + lớn; parent/caregiver/relative; 0/1/nhiều bé thuộc hai gia đình; online/offline/reconnect; locked/background/killed; low storage/quota; permission deny/limited/revoke. Android Auto Save đánh dấu **không thuộc scope beta**, vẫn thử manual/background upload.

Thực hiện theo rủi ro, không nhân Cartesian toàn bộ tổ hợp: trước tiên FAM-01/MEM-01/CON-01, rồi một hành trình hoàn chỉnh first-care→first-memory→family, sau đó negative cases quanh boundaries. Ghi build SHA/catalog version/model+prompt và video/screenshot có consent; không lưu ảnh trẻ vào analytics. Mỗi failed task phải có entry, bước lỗi, expected/actual, khả năng tự phục hồi và link issue.
