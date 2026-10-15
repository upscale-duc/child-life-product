# Premium & Cá nhân hoá, Slices 1 and 4 (plan docs/product/premium-personalization-plan.md, D-072, D-074).
# Vietnamese = Figma v2.0 copy (page 568:18) where drawn, English = Figma EN frames or engineering
# draft (D-012). Idempotent. Usage: python3 tool/premium_strings.py
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

# Badges (Quyền/Badge 588:6290).
s('pmBadgePremium', 'Premium', 'Premium', 'Plan badge: paid Premium (588:6290).')
s('pmBadgeBeta', 'Beta', 'Beta', 'Plan badge: personalisation beta (588:6290).')
s('pmBadgeFree', 'Miễn phí', 'Free', 'Plan badge: free (588:6290).')
s('pmBadgePending', 'Đang xác minh', 'Verifying', 'Plan badge: purchase being verified (588:6290).')
s('pmBadgeExpired', 'Hết hạn', 'Expired', 'Plan badge: Premium ended (588:6290).')

# PR03 Gói của hộ (593:6931 / 593:7179).
s('pmPlanTitle', 'Gói của hộ', 'Household plan', 'PR03 title; also the Tôi row.')
s('pmPlanFree', 'Đang dùng miễn phí', 'Using Free', 'PR03 free state title.')
s('pmPlanFreeBody', 'Ghi chép, lịch tham khảo, mẫu cơ bản, hướng dẫn sức khoẻ.', 'Logging, reference calendar, basic templates, health guidance.', 'PR03 free state body.')
s('pmPlanBeta', 'Beta cá nhân hoá đang mở', 'Personalisation beta active', 'PR03 beta state title.')
s('pmPlanBetaBody', 'Gợi ý theo nhu cầu, nhịp riêng của con và tóm tắt AI miễn phí đến {date}. Không gồm mẫu Premium. Không tự trừ tiền khi beta kết thúc.', "Need-based suggestions, your baby's own rhythm and AI summaries are free until {date}. Premium templates aren't included. No automatic charge when the beta ends.", 'PR03 beta state body; group A named in plain words (extract 30 Q19).', date='String')
s('pmPlanPremium', 'Child Life Premium', 'Child Life Premium', 'PR03 Premium state title.')
s('pmPlanRenews', 'Gia hạn tự động {date}', 'Renews {date}', 'PR03 Premium with auto-renew on.', date='String')
s('pmPlanEnds', 'Dùng đến {date} · đã tắt gia hạn', 'Active until {date} · renewal off', 'PR03 Premium with auto-renew off: access stays until then (brief p.9).', date='String')
s('pmPlanShared', 'Cả nhà thấy “Hộ đã có Premium”. Chỉ chủ hộ quản lý gói.', 'Everyone in the family sees “Household has Premium”. Only the family owner manages it.', 'PR03 Premium note (D-072 #1: owner only).')
s('pmPlanHouseholdHas', 'Hộ đã có Premium', 'Household has Premium', 'PR03 for members who do not manage the plan.')
s('pmPlanPending', 'Đang xác minh giao dịch', 'Verifying purchase', 'PR03 pending state title.')
s('pmPlanPendingBody', 'Chưa mở quyền mới; dữ liệu và lựa chọn vẫn giữ.', 'No new access yet; your data and selections are kept.', 'PR03 pending state body.')
s('pmPlanExpired', 'Premium đã hết hạn {date}', 'Premium ended {date}', 'PR03 expired state title.', date='String')
s('pmPlanExpiredBody', 'Vẫn xem dữ liệu, tóm tắt đã lưu, kỷ niệm và file đã xuất. Tạo mới nội dung Premium cần gia hạn.', 'You keep data, saved summaries, moments and exports. Creating new Premium content needs renewal.', 'PR03 expired state body (PR04).')
s('pmPlanBuySoon', 'Mua và quản lý gói ngay trong app sẽ có ở bản sau.', 'Buying and managing the plan in the app comes in a later version.', 'PR03 owner note while in-app purchase is not built (engineering state, Slice 4).')
s('pmPlanOwnerOnly', 'Chỉ chủ hộ mua và quản lý gói. Nhờ chủ hộ nếu cả nhà cần Premium.', 'Only the family owner buys and manages the plan. Ask them if the family needs Premium.', 'PR03 for non-owners (D-072 #1).')
s('pmPlanAlwaysFree', 'Luôn miễn phí', 'Always free', 'PR03 section: what never needs a plan.')
s('pmPlanAlwaysFreeBody', 'Ghi chép, lịch sử, nhắc việc, lịch tham khảo, hướng dẫn sức khoẻ và mọi thứ đã lưu.', 'Logging, history, reminders, reference calendar, health guidance and everything saved.', 'PR03 always-free list (PR01 592:6826).')

# Household region (D-072 #3, ST02 "Đổi khu vực trong hồ sơ hộ").
s('pmRegionRow', 'Khu vực của hộ', 'Household region', 'PR03 row: country of residence.')
s('pmRegionUnset', 'Chưa chọn', 'Not set', 'Region not chosen yet.')
s('pmRegionTitle', 'Gia đình đang sống ở đâu?', 'Where does your family live?', 'Region sheet title (D-072 #3).')
s('pmRegionBody', 'Dùng để chọn nội dung sức khoẻ và hỗ trợ đã duyệt cho khu vực. Child Life không đoán từ ngôn ngữ hay vị trí.', 'Used to pick health content and support approved for your region. Child Life never guesses it from language or location.', 'Region sheet body.')
s('pmRegionOwnerOnly', 'Chủ hộ chọn khu vực của hộ.', 'The family owner sets the household region.', 'Region row note for non-owners.')
s('pmRegionSaved', 'Đã lưu khu vực', 'Region saved', 'Toast after saving the region.')
for code, vi, en in [
    ('VN', 'Việt Nam', 'Vietnam'), ('US', 'Hoa Kỳ', 'United States'), ('GB', 'Vương quốc Anh', 'United Kingdom'),
    ('AU', 'Úc', 'Australia'), ('CA', 'Canada', 'Canada'), ('SG', 'Singapore', 'Singapore'),
    ('NZ', 'New Zealand', 'New Zealand'), ('DE', 'Đức', 'Germany'), ('FR', 'Pháp', 'France'),
    ('JP', 'Nhật Bản', 'Japan'), ('KR', 'Hàn Quốc', 'South Korea'), ('TW', 'Đài Loan', 'Taiwan'),
]:
    s(f'pmCountry{code}', vi, en, f'Country name for {code} in the region picker.')

# MO02 Mẫu Premium · cần quyền (592:6782 / 592:6906).
s('pmUnlockPremium', 'Mở với Premium', 'Unlock with Premium', 'MO02 primary button.')
s('pmUseFreeTemplate', 'Dùng mẫu miễn phí', 'Use a free template', 'MO02 secondary button.')
s('pmCardNoQuota', 'Thẻ Premium không trừ lượt xuất video', 'Premium cards don’t use video export quota', 'MO02 footnote for cards.')
s('pmTemplatePremiumBody', 'Mẫu này dành cho gia đình có Child Life Premium.', 'This template is for families with Child Life Premium.', 'MO02 sheet body.')
s('pmTemplateBetaNote', 'Gói beta hiện tại của nhà mình chưa gồm mẫu Premium.', 'Your current beta doesn’t include Premium templates.', 'MO02 note for beta families (brief p.3, extract 30 Q2).')

# Gate reasons other than PREMIUM_REQUIRED (ST01 / ST02; never a paywall).
s('pmGateRoleTitle', 'Cần quyền của ba mẹ', 'Needs a parent role', 'ROLE_DENIED (ST02 594:7020).')
s('pmGateRoleBody', 'Premium không đổi vai trò. Tạo thẻ, tạo tóm tắt AI hoặc sửa ghi nhận cần quyền của ba mẹ.', 'Premium doesn’t change roles. Creating cards, AI summaries or editing notes needs a parent role.', 'ROLE_DENIED body (ST02).')
s('pmGateRegionTitle', 'Hỗ trợ phù hợp chưa mở ở khu vực này', 'Personalised support isn’t available in your region yet', 'REGION_UNAVAILABLE (ST02).')
s('pmGateRegionBody', 'Chưa có nội dung sức khoẻ được duyệt cho khu vực của hộ. Ghi chép, lịch tham khảo, Kỷ niệm và mẫu cơ bản vẫn dùng bình thường.', 'Health content for your region isn’t approved yet. Logging, reference calendar, Moments and basic templates work as usual.', 'REGION_UNAVAILABLE body (ST02).')
s('pmGateRegionAction', 'Đổi khu vực trong hồ sơ hộ', 'Change region in household profile', 'REGION_UNAVAILABLE action (ST02).')
s('pmGateDisabledTitle', 'Tính năng đang tạm tắt', 'This feature is paused', 'FEATURE_DISABLED.')
s('pmGateDisabledBody', 'Ghi chép, nội dung miễn phí và hướng dẫn sức khoẻ vẫn dùng bình thường.', 'Logging, free content and health guidance keep working.', 'FEATURE_DISABLED body.')
s('pmGateQuotaTitle', 'Đã hết lượt trong kỳ này', 'No exports left this period', 'QUOTA_EXCEEDED (MO04 "Khi hết lượt").')
s('pmGateQuotaBody', 'Bạn vẫn xem mẫu và tạo thẻ ảnh.', 'You can still browse templates and make photo cards.', 'QUOTA_EXCEEDED body (MO04).')
s('pmGateConsentTitle', 'Cần bạn đồng ý dùng AI', 'AI needs your consent', 'CONSENT_REQUIRED.')
s('pmGateConsentBody', 'Bản tóm tắt theo mẫu vẫn dùng được khi chưa bật AI.', 'The template summary still works without AI.', 'CONSENT_REQUIRED body (ST01).')
s('pmGateNotMemberTitle', 'Bạn không còn trong gia đình này', 'You’re no longer in this family', 'NOT_MEMBER.')
s('pmGateOk', 'Đã hiểu', 'Got it', 'Gate sheet close button.')

# ---------------------------------------------------------------------------------------------
# Slice 4 (B4 / Q2): PR01 paywall, PR02 purchase states, MO03 resume, PR03 manage, PR04, MO04 quota.
# Real Apple / Google payment comes later (D-074): the paywall says "Mua trong app sắp có".

# PR01 Quyền lợi & paywall (592:6826 / 592:6950).
s('pmPaywallSubtitle', 'Một gói cho cả hộ. Mở cả hai nhóm quyền lợi.', 'One plan for the whole household. Unlocks both benefit groups.', 'PR01 subtitle.')
s('pmPaywallHere', 'Bạn đang xem', 'You’re here', 'PR01 pill on the benefit group the paywall was opened from (entry A or B).')
s('pmGroupATitle', 'A · Cá nhân hoá & Nhịp lớn lên nâng cao', 'A · Personalisation & advanced rhythm', 'PR01 benefit group A.')
s('pmGroupA1', 'Một việc phù hợp mỗi ngày từ ghi nhận của nhà mình', 'One step a day from your family’s notes', 'PR01 group A benefit 1.')
s('pmGroupA2', 'Nhớ cách đã có ích, bàn giao cho người chăm', 'Remembers what helped, handover for carers', 'PR01 group A benefit 2.')
s('pmGroupA3', 'Tóm tắt AI có căn cứ (có hạn mức)', 'Grounded AI summaries (with limits)', 'PR01 group A benefit 3.')
s('pmGroupBTitle', 'B · Mẫu thẻ & video Premium', 'B · Premium card & video templates', 'PR01 benefit group B.')
s('pmGroupB1', 'Toàn bộ thư viện mẫu Premium', 'The full Premium template library', 'PR01 group B benefit 1.')
s('pmGroupB2', 'Thêm lượt xuất video mỗi kỳ', 'More video exports each period', 'PR01 group B benefit 2 (numbers are config, not shown).')
s('pmPaywallFreeBody', 'Ghi chép, lịch sử, nhắc việc, lịch tham khảo (Wonder Weeks), mẫu cơ bản, hướng dẫn sức khoẻ thiết yếu. Hết gói vẫn xem dữ liệu, kỷ niệm và file đã xuất.', 'Logging, history, reminders, reference calendar (Wonder Weeks), basic templates, essential health guidance. After Premium ends you keep your data, moments and exported files.', 'PR01 always-free box (D-072 #7 label).')
s('pmPeriodMonthly', 'Theo tháng', 'Monthly', 'PR01 plan tile: monthly.')
s('pmPeriodYearly', 'Theo năm', 'Yearly', 'PR01 plan tile: yearly.')
s('pmRenewMonthly', '{price} mỗi tháng, tự động gia hạn đến khi bạn huỷ.', '{price} per month, renews automatically until you cancel.', 'PR01 renewal sentence; price from the storefront.', price='String')
s('pmRenewYearly', '{price} mỗi năm, tự động gia hạn đến khi bạn huỷ.', '{price} per year, renews automatically until you cancel.', 'PR01 renewal sentence; price from the storefront.', price='String')
s('pmRenewTerms', 'Thanh toán qua tài khoản {store} khi bạn xác nhận. Gói tự gia hạn trừ khi bạn tắt ít nhất 24 giờ trước khi kỳ hiện tại kết thúc; quản lý và huỷ trong cài đặt {store}.', 'Payment is charged to your {store} account when you confirm. The plan renews unless you turn it off at least 24 hours before the current period ends; manage or cancel in {store} settings.', 'PR01 auto-renewal disclosure required by the stores (not drawn in Figma).', store='String')
s('pmStoreApple', 'App Store', 'App Store', 'Store name.')
s('pmStoreGoogle', 'Google Play', 'Google Play', 'Store name.')
s('pmContinuePremium', 'Tiếp tục với Premium', 'Continue with Premium', 'PR01 primary button.')
s('pmStoreLegal', 'Giá, kỳ hạn và gia hạn hiển thị theo cửa hàng · huỷ trong cài đặt cửa hàng', 'Price, period and renewal shown by the store · cancel in store settings', 'PR01 legal line under the button.')
s('pmTerms', 'Điều khoản sử dụng', 'Terms of Use', 'PR01 link to the terms (store guidelines).')
s('pmPrivacy', 'Quyền riêng tư', 'Privacy Policy', 'PR01 link to the privacy policy (store guidelines).')
s('pmRestore', 'Khôi phục', 'Restore', 'PR01 / PR03 restore purchases.')
s('pmBuyClosedTitle', 'Mua trong app sắp có', 'In-app purchase is coming soon', 'PR01 owner: purchase not open yet (D-074, premium_billing off or no products).')
s('pmBuyClosedBody', 'Child Life Premium chưa bán trong app. Mọi thứ miễn phí vẫn dùng bình thường; Child Life sẽ báo khi mở.', 'Child Life Premium isn’t sold in the app yet. Everything free keeps working; we’ll let you know when it opens.', 'PR01 owner: purchase not open yet.')
s('pmAskOwnerTitle', 'Nhờ chủ hộ nâng cấp', 'Ask the family owner to upgrade', 'PR01 for members who are not the owner (D-072 #1).')
s('pmAskOwnerBody', 'Chỉ chủ hộ mua và quản lý gói. Khi hộ có Premium, cả nhà cùng dùng.', 'Only the family owner buys and manages the plan. Once the household has Premium, everyone uses it.', 'PR01 for members who are not the owner.')
s('pmHouseholdHasBody', 'Premium đang mở cho cả nhà. Chỉ chủ hộ quản lý gói.', 'Premium is on for the whole family. Only the family owner manages it.', 'PR01 when the household already has Premium.')

# PR02 Mua/Trạng thái (592:6781): Pending, Success, Error, Restore + restore results (not drawn).
s('pmPendingTitle', 'Đang chờ xác nhận thanh toán', 'Waiting for payment confirmation', 'PR02 Pending title.')
s('pmPendingBody', 'Cửa hàng chưa xác nhận giao dịch. Premium chưa được mở. Lựa chọn mẫu và ảnh của bạn vẫn được giữ.', 'The store hasn’t confirmed yet. Premium isn’t active. Your template and photo selection are kept.', 'PR02 Pending body from a template.')
s('pmPendingBodyPlain', 'Cửa hàng chưa xác nhận giao dịch. Premium chưa được mở. Bạn có thể đóng và kiểm tra lại sau.', 'The store hasn’t confirmed yet. Premium isn’t active. You can close this and check again later.', 'PR02 Pending body outside a template.')
s('pmCheckAgain', 'Kiểm tra lại', 'Check again', 'PR02 Pending primary.')
s('pmClose', 'Đóng', 'Close', 'PR02 close.')
s('pmSuccessTitle', 'Hộ đã có Premium', 'Your household has Premium', 'PR02 Success title.')
s('pmSuccessTemplate', 'Tiếp tục đúng mẫu “{name}” với ảnh bạn đã chọn.', 'Continuing with “{name}” and the photos you chose.', 'PR02 Success body from a template.', name='String')
s('pmSuccessRhythm', 'Gợi ý theo nhu cầu, nhịp riêng của con và tóm tắt AI đã mở cho cả nhà.', 'Need-based suggestions, your baby’s own rhythm and AI summaries are on for the whole family.', 'PR02 Success body from Nhịp lớn lên or the plan.')
s('pmContinueCard', 'Tiếp tục tạo thẻ', 'Continue creating', 'PR02 Success primary for a card.')
s('pmContinueVideo', 'Tiếp tục tạo video', 'Continue your video', 'PR02 Success primary for a video.')
s('pmBackToRhythm', 'Về Nhịp lớn lên', 'Back to Growing rhythm', 'PR02 Success primary from entry A (extract open question: return to Nhịp lớn lên).')
s('pmDone', 'Xong', 'Done', 'PR02 Success primary from the plan.')
s('pmErrorTitle', 'Chưa mua được', 'Purchase didn’t complete', 'PR02 Error title.')
s('pmErrorBody', 'Bạn chưa bị trừ tiền nếu cửa hàng không xác nhận. Thử lại hoặc dùng mẫu miễn phí.', 'You aren’t charged unless the store confirms. Try again or use a free template.', 'PR02 Error body from a template.')
s('pmErrorBodyPlain', 'Bạn chưa bị trừ tiền nếu cửa hàng không xác nhận. Thử lại sau nhé.', 'You aren’t charged unless the store confirms. Please try again.', 'PR02 Error body outside a template.')
s('pmErrorVerifyBody', 'Child Life chưa xác minh được giao dịch với cửa hàng. Premium chưa được mở. Nếu cửa hàng đã trừ tiền, bấm Thử lại hoặc Khôi phục.', 'We couldn’t confirm the purchase with the store yet. Premium isn’t active. If you were charged, tap Try again or Restore.', 'PR02 Error: the server could not verify.')
s('pmErrorNetworkBody', 'Chưa kết nối được Child Life. Giao dịch của cửa hàng vẫn được giữ để kiểm tra lại.', 'Couldn’t reach Child Life. The store’s transaction is kept so it can be checked again.', 'PR02 Error: network while verifying.')
s('pmTryAgain', 'Thử lại', 'Try again', 'PR02 Error primary.')
s('pmNotOwnerTitle', 'Chỉ chủ hộ mua và khôi phục gói', 'Only the family owner can buy or restore', 'PR02 not_owner (D-072 #1).')
s('pmNotOwnerBody', 'Nhờ chủ hộ mở Gói của hộ để nâng cấp hoặc khôi phục.', 'Ask the family owner to open Household plan to upgrade or restore.', 'PR02 not_owner body.')
s('pmRestoreTitle', 'Khôi phục giao dịch', 'Restore purchase', 'PR02 Restore confirm title.')
s('pmRestoreBody', 'Child Life kiểm tra giao dịch thuộc tài khoản này và gắn lại cho hộ của bạn. Không chuyển gói từ hộ khác.', 'We check purchases on this account and re-link them to your household. Plans aren’t moved from other households.', 'PR02 Restore confirm body.')
s('pmCancel', 'Huỷ', 'Cancel', 'PR02 Restore confirm secondary.')
s('pmRestoredTitle', 'Đã khôi phục Premium', 'Premium restored', 'Restore result: re-linked (not drawn).')
s('pmRestoredBody', 'Gói của bạn đã gắn lại với hộ này. Cả nhà thấy “Hộ đã có Premium”.', 'Your plan is linked to this household again. Everyone sees “Household has Premium”.', 'Restore result: re-linked.')
s('pmRestoreNoneTitle', 'Không có giao dịch để khôi phục', 'Nothing to restore', 'Restore result: nothing found (not drawn).')
s('pmRestoreNoneBody', 'Tài khoản cửa hàng này chưa có gói Child Life Premium còn hiệu lực.', 'This store account has no active Child Life Premium plan.', 'Restore result: nothing found.')
s('pmRestoreBoundTitle', 'Gói đang dùng cho hộ khác', 'This plan belongs to another household', 'Restore result: already bound to another family (not drawn).')
s('pmRestoreBoundBody', 'Giao dịch này đã gắn với một hộ khác. Child Life không chuyển gói giữa các hộ; liên hệ hỗ trợ nếu cần.', 'This purchase is linked to another household. Plans aren’t moved between households; contact support if you need help.', 'Restore result: already bound.')

# MO02 / MO03.
s('pmTemplateKeepsPhotos', 'Ảnh bạn đã chọn sẽ được giữ sau khi mua', 'Your selected photos are kept after purchase', 'MO02 note: the selection survives the purchase.')
s('pmResumedBanner', 'Đã mở Premium · tiếp tục chỗ bạn đang làm', 'Premium unlocked · picking up where you left off', 'MO03 banner on the template after purchase.')

# PR03 manage, PR04 hết gói (593:6931, 593:6990).
s('pmManageApple', 'Quản lý trong App Store', 'Manage in App Store', 'PR03 owner: subscription management (Apple).')
s('pmManageGoogle', 'Quản lý trong Google Play', 'Manage in Google Play', 'PR03 owner: subscription management (Google).')
s('pmSeePremium', 'Xem Premium', 'See Premium', 'PR03 / quota sheet: open PR01.')
s('pmRenewPremium', 'Gia hạn Premium', 'Renew Premium', 'PR04 renew link.')
s('pmExpiredStrip', 'Premium đã hết hạn. Mọi ghi nhận, phản hồi và bản tóm tắt đã lưu vẫn ở đây.', 'Premium has ended. All notes, feedback and saved summaries are still here.', 'PR04 strip where history stays.')

# MO04 Video · trạng thái xuất & quota (593:6843).
s('pmQuotaTitle', 'Lượt xuất video kỳ này', 'Video exports this period', 'MO04 quota card title.')
s('pmQuotaDetail', '{used} đã dùng · {reserved} đang giữ chỗ · làm mới {date}', '{used} used · {reserved} reserved · resets {date}', 'MO04 quota detail.', used='int', reserved='int', date='String')
s('pmQuotaDetailNoDate', '{used} đã dùng · {reserved} đang giữ chỗ', '{used} used · {reserved} reserved', 'MO04 quota detail without a reset date.', used='int', reserved='int')
s('pmQuotaCards', 'Thẻ ảnh không tính lượt.', 'Cards don’t count.', 'MO04 note.')
s('pmQuotaOutTitle', 'Đã hết lượt xuất video kỳ này', 'No video exports left this period', 'QUOTA_EXCEEDED sheet title (MO04 "Khi hết lượt").')
s('pmQuotaOutBody', 'Vẫn xem mẫu và tạo thẻ ảnh. Video mới chờ kỳ sau, làm mới {date}.', 'You can still browse templates and make cards. New videos wait for the next period, starting {date}.', 'QUOTA_EXCEEDED sheet body.', date='String')
s('pmQuotaOutBodyNoDate', 'Vẫn xem mẫu và tạo thẻ ảnh. Video mới chờ kỳ sau.', 'You can still browse templates and make cards. New videos wait for the next period.', 'QUOTA_EXCEEDED sheet body without a date.')
s('pmQuotaMakeCard', 'Tạo thẻ ảnh', 'Make a card', 'QUOTA_EXCEEDED sheet: go to cards.')
s('pmQuotaPremiumNote', 'Premium có {limit} lượt xuất video mỗi kỳ.', 'Premium includes {limit} video exports each period.', 'QUOTA_EXCEEDED sheet note for free families, only when Premium has more.', limit='int')
s('pmQuotaReserved', 'Giữ 1 lượt · bạn có thể rời màn hình', '1 export reserved · you can leave this screen', 'MO04 queued job.')
s('pmQuotaReleased', 'Đã hoàn lượt giữ chỗ · Thử lại không trừ thêm lượt', 'Reservation released · retry doesn’t use another export', 'MO04 failed job.')

root = pathlib.Path(__file__).resolve().parent.parent / 'lib' / 'l10n'
for locale, idx in (('vi', 0), ('en', 1)):
    path = root / f'app_{locale}.arb'
    data = json.loads(path.read_text(), object_pairs_hook=collections.OrderedDict)
    for key, (vi, en, desc, ph) in S.items():
        meta = data.get('@' + key)
        if locale == 'vi' and key in data and (meta or {}).get('description') != desc:
            raise SystemExit(f'{key} already exists for something else: pick another id')
        data[key] = (vi, en)[idx]
        if locale == 'vi':
            meta = collections.OrderedDict(description=desc)
            if ph:
                meta['placeholders'] = {k: {'type': v} for k, v in ph.items()}
            data['@' + key] = meta
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
print(len(S), 'strings')
