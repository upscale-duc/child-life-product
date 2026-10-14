# Premium & Cá nhân hoá, Slice 1 (plan docs/product/premium-personalization-plan.md, D-072).
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
s('pmTemplateBetaNote', 'Beta cá nhân hoá không gồm mẫu Premium.', 'The personalisation beta doesn’t include Premium templates.', 'MO02 note for beta families (brief p.3, extract 30 Q2).')

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
