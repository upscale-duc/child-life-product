"""D-124 and Premium v2 review. Preserve unrelated ARB keys and metadata."""
import json
from pathlib import Path
strings = {
'premiumSharedPlans': ('Cả nhà dùng chung, dù chọn gói năm hay gói tháng.', 'Shared with your family on both yearly and monthly plans.'),
'premiumChoosePlan': ('Chọn gói', 'Choose a plan'),
'premiumBenefits': ('Premium có gì?', 'What’s included?'),
'premiumMemories': ('Thiệp & video kỷ niệm', 'Keepsake cards & videos'),
'premiumMemoriesSubtitle': ('Toàn bộ mẫu cao cấp · Video Full HD 1080p', 'All premium templates · Full HD 1080p video'),
'premiumRhythm': ('Gợi ý cá nhân & nhịp nâng cao', 'Personal suggestions & advanced rhythms'),
'premiumRhythmSubtitle': ('Gợi ý theo nhu cầu và nhật ký của con', 'Suggestions based on your baby’s needs and logs'),
'premiumTodayTotal': ('Thanh toán hôm nay', 'Due today'),
'premiumBackToPlans': ('Quay lại chọn gói', 'Back to plans'),
'premiumUnlimitedVideo': ('Xuất video không giới hạn lượt', 'Unlimited video exports'),
'premiumVideoFree': ('Mẫu cơ bản · Video 720p', 'Basic templates · 720p video'),
'premiumVideoPaid': ('Mọi mẫu · Full HD 1080p', 'All templates · Full HD 1080p'),
'premiumVideoDetail': ('Không giới hạn lượt xuất: Free 720p, Premium Full HD 1080p.', 'Unlimited exports: 720p on Free, Full HD 1080p on Premium.'),
'premiumFeatureIntro': ('Tìm hiểu Premium cho tính năng này', 'Explore Premium for this feature'),
'videoQuality': ('Chất lượng video', 'Video quality'),
'videoQualityHd': ('HD 720p', 'HD 720p'),
'videoQualityFullHd': ('Full HD 1080p', 'Full HD 1080p'),
'videoQualityHdHint': ('Tệp nhẹ hơn, dễ chia sẻ', 'Smaller files, easy to share'),
'videoQualityFullHdHint': ('Hình ảnh rõ nét hơn', 'Sharper video'),
'videoQualityPremiumHint': ('Cần Premium · Tìm hiểu', 'Requires Premium · Learn more'),
'videoExportHd': ('Xuất video HD 720p', 'Export HD 720p video'),
'videoExportFullHd': ('Xuất video Full HD 1080p', 'Export Full HD 1080p video'),
'videoFullHdIntroTitle': ('Xuất Full HD với Premium', 'Export in Full HD with Premium'),
'videoFullHdIntroBody': ('Premium cho phép xuất video Full HD 1080p và dùng mọi mẫu cao cấp. Free vẫn xuất HD 720p không giới hạn lượt. Video đang làm được giữ nguyên.', 'Premium includes Full HD 1080p exports and all premium templates. Free still includes unlimited HD 720p exports. Your video stays as it is.'),
'videoContinueHd': ('Tiếp tục với HD 720p', 'Continue with HD 720p'),
'premiumRhythmCompareFree': ('Theo tuổi & lịch tham khảo', 'Age-based suggestions & reference schedules'),
'premiumRhythmComparePaid': ('Gợi ý riêng & nhịp nâng cao', 'Personal suggestions & advanced rhythms'),
'premiumStorageSubtitle': ('Dung lượng chung cho ảnh và video của cả gia đình', 'Shared storage for your family’s photos and videos'),
'premiumSeatsSubtitle': ('Cùng ghi cữ bú, giấc ngủ và xem nhật ký', 'Log feeds and sleep, and view the journal together'),
'premiumUseTemplate': ('Dùng mẫu Premium', 'Use Premium template'),
'videoQualityChecking': ('Đang kiểm tra gói · Thử lại', 'Checking your plan · Try again'),
'videoRenderRateLimit': ('Bạn vừa gửi nhiều yêu cầu tạo video. Thử lại sau một phút nhé.', 'You’ve sent several video requests. Please try again in a minute.'),
'premiumPaymentDetails': ('Chi tiết thanh toán', 'Payment details'),
'premiumTaxIncluded': ('Giá đã gồm thuế.', 'Tax included.'),
'premiumVideoAfterCancel': ('Video đã xuất giữ nguyên chất lượng. Video mới xuất HD 720p, không giới hạn lượt.', 'Existing exports keep their quality. New videos export in HD 720p, with unlimited exports.'),
'premiumPlanCheckFailed': ('Chưa kiểm tra được gói gia đình', 'Couldn’t check your family plan'),
'premiumPlanCheckFailedBody': ('Thử lại khi có kết nối nhé. Nội dung bạn đang làm vẫn được giữ.', 'Try again when you’re connected. Your work is kept.'),
'premiumRhythmDetail': ('Xem nhịp bú, ngủ khi nhật ký đủ dữ liệu. Gợi ý để tham khảo, không chẩn đoán bệnh.', 'View feeding and sleep patterns when there are enough logs. Suggestions are for reference, not a diagnosis.'),
'videoPremiumChanged': ('Video này cần Premium đang còn hiệu lực. Bạn có thể đổi sang mẫu cơ bản và HD 720p; bản dựng vẫn được giữ.', 'This video needs an active Premium plan. You can switch to a basic template and HD 720p; your work is kept.'),
'premiumNeedsPremium': ('Cần Premium', 'Requires Premium'),
}
# Existing placeholder signatures stay compatible with older callers, but never promise counts.
existing = {
'pv2FreeUpsellBody': ('Thêm credit Lumi hằng tháng, mẫu cao cấp, video Full HD và dung lượng chung cho cả nhà.', 'Get monthly Lumi credits, premium templates, Full HD video and more shared storage.'),
'pv2RowLumiFree': ('{n} credit dùng thử một lần', '{n, plural, one{{n} one-time trial credit} other{{n} one-time trial credits}}'),
'asPremiumTeaser': ('Premium có thêm credit Lumi, gợi ý cá nhân và mẫu thiệp, video cao cấp.', 'Premium includes more Lumi credits, personal suggestions and premium card and video templates.'),

'pv2CardVideoEyebrow': ('THIỆP & VIDEO KỶ NIỆM', 'KEEPSAKE CARDS & VIDEOS'),
'pv2CardVideoTitle': ('Kỷ niệm mang dấu ấn của con', 'Keepsakes that feel like your baby'),
'pv2CardVideoBody': ('Chọn mẫu cao cấp, thêm ảnh, tên và lời nhắn.', 'Choose premium templates and add photos, a name and a message.'),
'pv2CardVideoLimit': ('Xuất video không giới hạn lượt', 'Unlimited video exports'),
'pv2RowVideoFree': ('Không giới hạn · 720p', 'Unlimited · 720p'),
'pv2RowVideoPremium': ('Không giới hạn · Full HD 1080p', 'Unlimited · Full HD 1080p'),
'pv2E01Body': ('Mẫu này có trong Premium, cùng khả năng xuất Full HD 1080p không giới hạn lượt. Ảnh và lời nhắn đang chọn được giữ nguyên.', 'Premium includes this template and unlimited Full HD 1080p exports. Your selected photos and message are kept.'),
'pv2CardRhythmTitle': ('Gợi ý cá nhân & nhịp nâng cao', 'Personal suggestions & advanced rhythms'),
'pv2CardRhythmBody': ('Gợi ý theo nhu cầu của bé, nhìn lại nhịp bú, ngủ từ nhật ký.', 'Suggestions for your baby’s needs and feeding and sleep patterns from your logs.'),
'pv2CardRhythmLimit': ('Có trong Premium', 'Included in Premium'),
'pv2RowRhythmFree': ('Theo tuổi & lịch tham khảo', 'Age-based suggestions & reference schedules'),
'pv2RowRhythmPremium': ('Gợi ý riêng & nhịp nâng cao', 'Personal suggestions & advanced rhythms'),
'pv2E13Body': ('Mẫu cao cấp, video Full HD, thêm credit Lumi và dung lượng dùng chung cho cả nhà.', 'Premium templates, Full HD video, more Lumi credits and shared family storage.'),
}
# Exact approved Figma wording (owner review, 2026-10-27).
existing.update(
{'premiumYearSuffix': ('/năm', '/year'),
 'premiumMonthSuffix': ('/tháng', '/month'),
 'premiumSavePercent': ('Tiết kiệm {n}%', 'Save {n}%'),
 'premiumLumiListTitle': ('Hỏi Lumi', 'Ask Lumi'),
 'premiumStorageListTitle': ('{gb} cho cả nhà', '{gb} for your family'),
 'premiumSeatsListTitle': ('{n} người có quyền ghi', '{n} people can log care'),
 'premiumLegalIntro': ('Tự động gia hạn. Huỷ bất cứ lúc nào trong {store}. Khi đăng ký, bạn đồng ý '
                       'với ',
                       'Auto-renews. Cancel anytime in {store}. By subscribing, you agree to the '),
 'premiumPaymentEquivalent': ('Tương đương mỗi tháng', 'Equivalent per month'),
 'premiumPaymentSaving': ('Tiết kiệm so với 12 tháng trả theo tháng',
                          'Savings compared with 12 monthly payments'),
 'premiumPaymentTax': ('Thuế', 'Tax'),
 'premiumPaymentTaxValue': ('Đã gồm trong giá', 'Included in the price'),
 'premiumPaymentRenewal': ('Tự động gia hạn {price}. Muốn huỷ, hãy huỷ trong {store} ít nhất 24 '
                           'giờ trước ngày gia hạn.',
                           'Auto-renews at {price}. To cancel, use {store} at least 24 hours '
                           'before renewal.'),
 'premiumMemoriesBullet1': ('Thiệp: mẫu cao cấp, thêm ảnh, tên và lời nhắn.',
                            'Cards: premium templates, photos, a name and a message.'),
 'premiumMemoriesBullet2': ('Video: ghép ảnh cùng lời nhắn và nhạc.',
                            'Videos: combine photos with a message and music.'),
 'premiumLumiBullet1': ('Hỏi về nhật ký và xem dữ liệu Lumi dùng để trả lời.',
                        'Ask about your journal and see the data behind Lumi’s answers.'),
 'premiumLumiBullet2': ('Nhờ Lumi soạn bản ghi để bạn kiểm tra trước khi lưu.',
                        'Ask Lumi to draft a log for you to check before saving.'),
 'premiumLumiBullet3': ('Credit dùng chung cho cả nhà, được cấp mỗi tháng.',
                        'Credits are shared with your family and refill each month.'),
 'premiumRhythmBullet1': ('Gợi ý theo tuổi, nhu cầu và phản hồi của bạn.',
                          'Suggestions based on age, needs and your feedback.'),
 'premiumRhythmBullet2': ('Xem nhịp bú, ngủ khi nhật ký đủ dữ liệu.',
                          'View feeding and sleep patterns when there are enough logs.'),
 'premiumRhythmBullet3': ('Lumi không chẩn đoán bệnh, chỉ giúp bạn nhìn lại những gì đã ghi.',
                          'Lumi doesn’t diagnose illness; it helps you review what you’ve logged.'),
 'premiumStorageBullet1': ('{gb} cho ảnh và video của cả gia đình.',
                           '{gb} for your family’s photos and videos.'),
 'premiumStorageBullet2': ('Xem mức sử dụng trong Gói của gia đình.',
                           'View usage in Your family plan.'),
 'premiumStorageBullet3': ('Mua thêm dung lượng: Sắp có.', 'Additional storage: Coming soon.'),
 'premiumSeatsBullet1': ('Cùng ghi cữ bú, giấc ngủ và xem cập nhật.',
                         'Log feeds and sleep, and view updates together.'),
 'premiumSeatsBullet2': ('Quyền xem và ghi theo vai trò của từng người.',
                         'Viewing and logging permissions follow each person’s role.'),
 'premiumSeatsBullet3': ('Người thân chỉ xem album không tính vào số chỗ ghi.',
                         'Relatives who only view albums don’t use a logging seat.'),
 'premiumRhythmPager': ('Gợi ý & nhịp nâng cao', 'Suggestions & advanced rhythms'),
 'premiumSeatsPager': ('Người có quyền ghi', 'People who can log care'),
 'premiumSubscribeYearShort': ('Đăng ký gói năm', 'Subscribe yearly'),
 'premiumSubscribeMonthShort': ('Đăng ký gói tháng', 'Subscribe monthly'),
 'pv2Restore': ('Khôi phục giao dịch', 'Restore purchases'),
 'pv2EachMonth': ('Thanh toán hằng tháng', 'Billed monthly'),
 'pv2SubscribeYear': ('Đăng ký gói năm · {price}', 'Subscribe yearly · {price}'),
 'pv2SubscribeMonth': ('Đăng ký gói tháng · {price}', 'Subscribe monthly · {price}'),
 'pv2Terms': ('Điều khoản sử dụng', 'Terms of Use'),
 'premiumStorageSubtitle': ('Dung lượng dùng chung cho ảnh và video của cả nhà',
                            'Shared storage for your family’s photos and videos'),
 'pv2PerMonthApprox': ('Tương đương khoảng {price}/tháng', 'About {price}/month'),
 'pv2CardLumiLimit': ('{n} credit/tháng · cả nhà dùng chung',
                      '{n} credits/month · shared with your family')}
)
reviewed_metadata = {'premiumYearSuffix': {'description': 'Approved Premium Figma 1153:5491, exact UI alignment.'},
 'premiumMonthSuffix': {'description': 'Approved Premium Figma 1153:5491, exact UI alignment.'},
 'premiumSavePercent': {'description': 'Approved Premium Figma 1153:5491, exact UI alignment.',
                        'placeholders': {'n': {'type': 'int'}}},
 'premiumLumiListTitle': {'description': 'Approved Premium Figma 1153:5491, exact UI alignment.'},
 'premiumStorageListTitle': {'description': 'Approved Premium Figma 1153:5491, exact UI alignment.',
                             'placeholders': {'gb': {'type': 'String'}}},
 'premiumSeatsListTitle': {'description': 'Approved Premium Figma 1153:5491, exact UI alignment.',
                           'placeholders': {'n': {'type': 'int'}}},
 'premiumLegalIntro': {'description': 'Approved Premium Figma 1153:5491, exact UI alignment.',
                       'placeholders': {'store': {'type': 'String'}}},
 'premiumPaymentEquivalent': {'description': 'Approved Premium Figma 1153:5491, exact UI '
                                             'alignment.'},
 'premiumPaymentSaving': {'description': 'Approved Premium Figma 1153:5491, exact UI alignment.'},
 'premiumPaymentTax': {'description': 'Approved Premium Figma 1153:5491, exact UI alignment.'},
 'premiumPaymentTaxValue': {'description': 'Approved Premium Figma 1153:5491, exact UI alignment.'},
 'premiumPaymentRenewal': {'description': 'Approved Premium Figma 1153:5491, exact UI alignment.',
                           'placeholders': {'price': {'type': 'String'},
                                            'store': {'type': 'String'}}},
 'premiumMemoriesBullet1': {'description': 'Approved Premium Figma 1153:5491, exact UI alignment.'},
 'premiumMemoriesBullet2': {'description': 'Approved Premium Figma 1153:5491, exact UI alignment.'},
 'premiumLumiBullet1': {'description': 'Approved Premium Figma 1153:5491, exact UI alignment.'},
 'premiumLumiBullet2': {'description': 'Approved Premium Figma 1153:5491, exact UI alignment.'},
 'premiumLumiBullet3': {'description': 'Approved Premium Figma 1153:5491, exact UI alignment.'},
 'premiumRhythmBullet1': {'description': 'Approved Premium Figma 1153:5491, exact UI alignment.'},
 'premiumRhythmBullet2': {'description': 'Approved Premium Figma 1153:5491, exact UI alignment.'},
 'premiumRhythmBullet3': {'description': 'Approved Premium Figma 1153:5491, exact UI alignment.'},
 'premiumStorageBullet1': {'description': 'Approved Premium Figma 1153:5491, exact UI alignment.',
                           'placeholders': {'gb': {'type': 'String'}}},
 'premiumStorageBullet2': {'description': 'Approved Premium Figma 1153:5491, exact UI alignment.'},
 'premiumStorageBullet3': {'description': 'Approved Premium Figma 1153:5491, exact UI alignment.'},
 'premiumSeatsBullet1': {'description': 'Approved Premium Figma 1153:5491, exact UI alignment.'},
 'premiumSeatsBullet2': {'description': 'Approved Premium Figma 1153:5491, exact UI alignment.'},
 'premiumSeatsBullet3': {'description': 'Approved Premium Figma 1153:5491, exact UI alignment.'},
 'premiumRhythmPager': {'description': 'Approved Premium Figma 1153:5491, exact UI alignment.'},
 'premiumSeatsPager': {'description': 'Approved Premium Figma 1153:5491, exact UI alignment.'},
 'premiumSubscribeYearShort': {'description': 'Premium Figma payment-sheet action.'},
 'premiumSubscribeMonthShort': {'description': 'Premium Figma payment-sheet action.'},
 'pv2Restore': {'description': 'Premium v2 (Figma 958:13863, D-101). Paywall top bar: restore '
                               'purchases.'},
 'pv2EachMonth': {'description': 'Premium v2 (Figma 958:13863, D-101). Monthly tile caption.'},
 'pv2SubscribeYear': {'description': 'Premium v2 (Figma 958:13863, D-101). Paywall CTA, yearly.',
                      'placeholders': {'price': {'type': 'String'}}},
 'pv2SubscribeMonth': {'description': 'Premium v2 (Figma 958:13863, D-101). Paywall CTA, monthly.',
                       'placeholders': {'price': {'type': 'String'}}},
 'pv2Terms': {'description': 'Premium v2 (Figma 958:13863, D-101). Paywall legal line link.'},
 'premiumStorageSubtitle': {'description': 'Premium v2: transparent feature introduction or video '
                                           'export quality (D-124).'},
 'pv2PerMonthApprox': {'description': 'Premium v2 (Figma 958:13863, D-101). Yearly tile: the price '
                                      'per month.',
                       'placeholders': {'price': {'type': 'String'}}},
 'pv2CardLumiLimit': {'description': 'Premium v2 (Figma 958:13863, D-101). Feature card limit '
                                     'line.',
                      'placeholders': {'n': {'type': 'int'}}}}
existing.update({'premiumLumiCompareFree': ('{n} credit dùng thử · không cấp lại',
                            '{n, plural, one{{n} trial credit · no refill} other{{n} trial credits '
                            '· no refill}}'),
 'premiumLumiComparePaid': ('{n} credit/tháng · cả nhà dùng chung',
                            '{n, plural, one{{n} credit/month · shared with your family} other{{n} '
                            'credits/month · shared with your family}}'),
 'premiumSeatsCardLimit': ('{premium} người có quyền ghi · Free: {free}',
                           '{premium, plural, one{{premium} logging seat} other{{premium} logging '
                           'seats}} · Free: {free}'),
 'pv2CardLumiLimit': ('{n} credit/tháng · cả nhà dùng chung',
                      '{n, plural, one{{n} credit/month} other{{n} credits/month}} · shared with '
                      'your family')})
reviewed_metadata.update({'premiumLumiCompareFree': {'description': 'Approved Figma Premium details, config-driven '
                                           'allowances.',
                            'placeholders': {'n': {'type': 'int'}}},
 'premiumLumiComparePaid': {'description': 'Approved Figma Premium details, config-driven '
                                           'allowances.',
                            'placeholders': {'n': {'type': 'int'}}},
 'premiumSeatsCardLimit': {'description': 'Approved Figma Premium details, config-driven '
                                          'allowances.',
                           'placeholders': {'free': {'type': 'int'}, 'premium': {'type': 'int'}}},
 'pv2CardLumiLimit': {'description': 'Approved Figma Premium details, config-driven allowances.',
                      'placeholders': {'n': {'type': 'int'}}}})
# Owner's latest Figma revision, 2026-10-27: concise benefit sheets.
existing.update({
    'premiumMemoriesSubtitle': ('Toàn bộ mẫu cao cấp chất lượng cao', 'All high-quality premium templates'),
    'premiumLumiListTitle': ('Trợ lý Lumi', 'Lumi assistant'),
    'premiumLumiPager': ('Hỏi Lumi', 'Ask Lumi'),
    'premiumLumiDetailTitle': ('Hỏi Lumi mọi thứ về con', 'Ask Lumi about your baby'),
    'premiumRhythmDetailTitle': ('Gợi ý cá nhân và nhịp nâng cao của con', 'Personal suggestions and advanced rhythms for your baby'),
    'premiumMemoriesBullet3': ('Không giới hạn lượt xuất chất lượng cao', 'Unlimited high-quality exports'),
    'premiumLumiBullet3': ('{n} credit/tháng dùng chung cho cả nhà, được cấp mỗi tháng.', '{n, plural, one{{n} credit/month shared with your family, refilled monthly.} other{{n} credits/month shared with your family, refilled monthly.}}'),
    'premiumRhythmBullet3': ('Hiểu con hơn mỗi ngày.', 'Understand your baby better every day.'),
    'premiumSeatsBullet3': ('Thoải mái cùng {n} người chăm con', '{n, plural, one{Care for your baby with {n} carer} other{Care for your baby with {n} carers}}'),
})
for key in ['premiumMemoriesSubtitle', 'premiumLumiListTitle', 'premiumLumiPager',
            'premiumLumiDetailTitle', 'premiumRhythmDetailTitle', 'premiumMemoriesBullet3',
            'premiumRhythmBullet3']:
    reviewed_metadata[key] = {'description': 'Owner-updated Premium Figma 1153:5491, 2026-10-27.'}
for key in ['premiumLumiBullet3', 'premiumSeatsBullet3']:
    reviewed_metadata[key] = {
        'description': 'Owner-updated Premium benefit. n is the configured monthly credits or logging seats, never a fixed allowance.',
        'placeholders': {'n': {'type': 'int'}},
    }
# Keep premiumStorageBullet3's Coming soon qualifier while its CTA calls showPaymentSoon.
for lang, ix in [('vi', 0), ('en', 1)]:
    p = Path(__file__).resolve().parents[1] / 'lib/l10n' / f'app_{lang}.arb'
    data = json.loads(p.read_text())
    # Retired key: the current screen uses asOutBodyPremium2 with its typed placeholders.
    data.pop('asOutBodyPremium', None)
    for key, pair in strings.items():
        data[key] = pair[ix]
        data['@' + key] = {'description': 'Premium v2: transparent feature introduction or video export quality (D-124).'}
    for key, pair in existing.items():
        data[key] = pair[ix]
    for key, value in reviewed_metadata.items():
        data['@' + key] = value
    p.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
