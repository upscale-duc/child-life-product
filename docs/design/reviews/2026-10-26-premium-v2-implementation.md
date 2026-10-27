# Premium v2 — implementation and export-quality review

Date: 2026-10-26 · Owner decisions D-124, D-125 · Figma section `1153:5491`, file `sJLG1fAXKDnDr9YI6Yx8ex`.

## Tóm tắt cho owner

Đã triển khai luồng Premium dạng danh sách 5 quyền lợi, gộp thiệp và video, có phần chi tiết và phân biệt gói năm/tháng dùng chung cho cả nhà. Điểm vào trả phí nói rõ Premium trước khi bấm và màn chọn gói đưa đúng chức năng đó lên đầu. Không tự mở thanh toán khi gặp lỗi quyền, vùng, mất kết nối hoặc giới hạn vận hành.

Video có lựa chọn chất lượng ngay trước nút xuất. Free chọn sẵn HD 720p; Full HD ghi “Cần Premium · Tìm hiểu” và mở giới thiệu trước khi người dùng chủ động xem gói. Premium mặc định Full HD và vẫn chọn được HD. Đóng giới thiệu không thay đổi lựa chọn hay bản dựng. Nút xuất ghi đúng chất lượng. Cả hai gói không giới hạn số lượt xuất trong Premium v2.

Portal dev đã deploy ngày 26/10/2026; app, Functions và renderer chưa deploy trong lần này. Thanh toán thật vẫn chờ IAP theo quyết định hiện hành; nút đăng ký thông báo bước thanh toán sắp mở, không tạo thành công giả.

## Review and structure

Readers: a parent finishing a video, a Free family exploring one benefit, an existing Premium family, and a member who cannot manage billing. Five-second questions: what needs Premium, what Free still does, which quality will be exported, and the actual charge/period.

- **Paywall: RESTRUCTURE.** A fresh run confirmed the four old `pw06_explore` renders before edits; the old carousel hid benefits and put plan choices in the fixed footer. The approved Figma list is the structural alternative: plans scroll, five benefits remain reachable, the total/primary action stays fixed. The requested benefit precedes plans, without repeating that row in the rest of the list. The six legacy illustration cards remain reusable; the live benefit navigation has five pages.
- **Video editors: REFINE.** Add one quality selector above the primary action in both legacy-template and personalized-template editors. Keep photo order, copy, preview, audience, music and draft flows.
- **Entries: REFINE.** Replace vague upgrade destinations with explicit Premium labels. Keep non-Premium gate reasons and existing Free actions.

| Content | Action | Reason |
|---|---|---|
| Separate card/video upgrade cards | Merge | One keepsakes benefit, one upgrade decision |
| Carousel plus comparison table on the main paywall | Relocate | Scannable rows; details and comparison are deliberate taps |
| Plan choices in the fixed footer | Relocate | Scrollable choices; the primary remains reachable at 200% text |
| Video trial/monthly counters and refill promises | Remove/rewrite | Superseded by D-124 |
| Generic “Tìm hiểu thêm” leading to a plan | Rewrite | “Xem Premium”/“Cần Premium” before tap |
| Annual equivalent, actual charge, billing period and legal links | Preserve | The annual total is charged, not its monthly equivalent |
| Family manager action, Free paths and drafts | Preserve | No surprise purchase or lost work |
| Unknown family plan | Explain | Never assume Free and sell an upgrade on a failed lookup |

## Entry inventory

| Entry | Before the gated action | Destination / retained behaviour |
|---|---|---|
| Card and video templates | Premium artwork badge; “Dùng mẫu Premium” on use CTA | Named-template introduction → explicit “Xem Premium”; same draft/resume |
| Full HD export | Quality option says “Cần Premium · Tìm hiểu” | Full HD introduction → explicit plans; HD stays selected on cancel |
| Rhythm home, own rhythm, week and result | “Cần Premium” or “Xem Premium”, beside the feature explanation | Rhythm benefit first; other gate reasons explain themselves |
| AI handover | Existing AI/Free-template explanation; explicit “Xem Premium” | Feature-specific introduction; no upgrade for role/region/service problems |
| Lumi / credits | Existing exhausted-credit explanation and explicit Premium action | Lumi-focused benefit; Premium credit refill is separate from video |
| Storage | Existing near-full/full inline explanation and Premium action | Storage-focused plan; existing Premium goes to add-on information |
| Invite writer with seats full | Current plan notice and Premium CTA before sending invite | Seat introduction; keep relative invitation and selected relation |
| Family plan / Me | Explicit Premium or plan-management action | General plans or manager-specific action |

Search covered `openPaywall`, `paywallLocation`, `Routes.premium`, `showGateSheet` and `ensureTemplateAllowed` callers in mobile. Direct navigation to the Premium route is intentional plan browsing, not a hidden paid-feature action.

## Quality and server policy

- V2 request schema accepts only `hd720` / `fullHd1080`. The server freezes the selected quality; Free cannot request Full HD or premium video/card templates, even if the old catalog setting is `everyone`.
- Missing quality on an older request defaults to 720p for v2 Free. A failed Full HD/premium-template job cannot be retried after downgrade. Previously completed files keep their quality and access rules.
- Render at the original artwork/layout dimensions and scale the output, preserving aspect ratio ([Remotion scale API](https://www.remotion.dev/docs/options/scale)). For 9:16, the tested MP4s are H.264 **720×1280** and **1080×1920**. The existing 4:5 layout maps to 720×900 / 1080×1350; that format was not separately smoke-rendered in this pass. Export resolution cannot restore detail missing from source photos.
- V2 video windows explicitly report `unlimited`. Ledger reservations remain idempotent usage history and settle jobs already in flight; they cannot reject on an export count. No huge-number “unlimited” sentinel.
- Remove the v2 daily count cap. Retain storage checks and existing active-job protection; a temporary three-requests-per-minute burst guard explains retrying after a minute and never offers an upgrade. Lumi allowance and seat/storage policies are unchanged.
- Historical count configuration fields remain readable for old plan versions and v1 rollout. The portal no longer edits/displays video-count allowances; new v2 video allowance adjustments are refused. Historical refunds remain supported.
- Quality UI and unlimited claims follow `premium_v2`; the flag-off editor retains its original CTA and Full HD export behaviour. Release server, renderer and app together before exposing the new policy to families.

## Rendered evidence and iteration

Fresh renders: vi/en × Light/Night care, yearly/monthly, manager/member, five details, payment summary, Free/Premium quality, cancellation and downgrade. Premium paywall/details also have 200% text renders. Opened the contact sheets for all 31 Premium states and inspected the primary screens at full size. Reused the shared sheet route with a dark theme; no shared widget API/default was changed.

Fixed during review: oversized section headings, a one-pixel illustration overflow, white margins around a dark detail sheet, a cluttered combined hero, an outdated Free-plan video-refill promise, and the video allowance row in Lumi usage. Illustrations use a fixed demo canvas; live copy scales normally and detail content scrolls above its fixed close action.

Self-review: purpose and selected quality are visible; one dominant primary; five benefits reachable without swipe discovery; charge/period retained; context is feature-specific; roles and drafts preserved; languages/themes and large text rendered. No newly introduced Blocker/High found in these rendered and tested states. This is an engineering/design review, not a user study or screen-reader certification.

Images (current tested baselines):

- [Plans](../../../apps/mobile/test/golden/goldens/pv2/pw06_explore_light_vi.png), [monthly](../../../apps/mobile/test/golden/goldens/pv2/pw_monthly_light_vi.png), [payment details](../../../apps/mobile/test/golden/goldens/pv2/payment_details_light_vi.png).
- [Keepsakes detail](../../../apps/mobile/test/golden/goldens/pv2/detail_memories_light_vi.png), [rhythm detail](../../../apps/mobile/test/golden/goldens/pv2/detail_rhythm_light_en.png), [large text](../../../apps/mobile/test/golden/goldens/pv2/pw_large_light_vi.png).
- [Export editor](../../../apps/mobile/test/golden/goldens/mm/mm07_quality_hd_light.png), [Free quality choices](../../../apps/mobile/test/golden/goldens/pv2/quality_free_light_vi.png), [Premium quality choices](../../../apps/mobile/test/golden/goldens/pv2/quality_premium_nightCare_vi.png).

## Validation

- Flutter analyze; core Premium/keepsakes widget tests; rhythm/week/handover/invite regression tests.
- 124 Premium golden renders; 8 editor renders (v2 quality and flag-off); 8 Lumi usage/exhausted renders; 28 changed rhythm/AI entry renders. Updated only affected baselines.
- Contracts: 925 tests across 48 files.
- Firestore emulator: 43 keepsake/quota/plan tests, 23 memory/card tests; renderer 14 tests including frozen quality and idempotent jobs.
- Portal: 16 Premium/operations tests. Typecheck: Functions, renderer, portal and Firebase tests. ESLint on changed production TS modules; `git diff --check`.
- Real synthetic one-second MP4 smoke render at both quality levels; ffprobe confirmed H.264 720×1280 and 1080×1920. Script: `apps/renderer/scripts/check-export-quality.ts`.

The wider fresh golden run exposed four existing mismatches in `mm01_photos`/`mm03_nudge` (vi, both themes), from concurrent Memories/engagement work already present before this task. Their baselines were not overwritten. Other concurrent Tự lưu edits and localization keys were preserved. No simulator/device purchase, production Firebase, App Store/Play billing, or real-family load test was performed.

## Portal deployment · 2026-10-26

Deployed only `hosting:admin` on `child-life-dev` at 20:25 (Asia/Ho_Chi_Minh): https://child-life-dev-admin.web.app. Firebase Hosting version `c322a1b52de5eb18`. Shared packages built, all 729 portal tests in 21 files passed, and the dev build/typecheck passed. Post-deploy HTTP checks confirmed the index and linked JS/CSS match the local build byte-for-byte. This release updates plan-quality presentation and removes export-count editing/metrics; it does not deploy the mobile app, Functions, renderer or billing.
