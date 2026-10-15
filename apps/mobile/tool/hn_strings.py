# Hôm nay · cá nhân hoá (D-076 #1, #4, #8): EN01–EN03 after a baby is created, the Home invite
# 559:57870 and "Dành cho bé hôm nay" 559:57583. Vietnamese = Figma copy (adapted where product
# rules differ: no baby name in notification samples, R-120; no unenforced caps), English =
# engineering draft (D-012). Idempotent. Usage: python3 tool/hn_strings.py
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

# EN01–EN03 (559:2288, 559:2383, 559:2458).
s('hnStepOf', 'Bước {step} trên {count}', 'Step {step} of {count}', 'EN01–EN03 step bars, for screen readers.', step='int', count='int')
s('hnContinueCount', 'Tiếp tục · {count} mục', 'Continue · {count} {count, plural, =1{item} other{items}}', 'EN01 button with the number of interests picked (559:2288).', count='int')
s('hnNotifTitle', 'Để Child Life nhắc bạn đúng lúc', 'Let Child Life remind you at the right time', 'EN03 title (559:2458).')
s('hnNotifBody', 'Chỉ những gì bạn vừa chọn và nhắc việc bạn tự đặt. Không quảng cáo.', 'Only what you just picked and the reminders you set. No ads.', 'EN03 subtitle; the Figma "tối đa 2 gợi ý mỗi ngày" is not promised until a cap exists.')
s('hnNotifExamples', 'Bạn có thể nhận những loại sau', 'You may get these', 'EN03 example card header.')
s('hnNotifExampleTag', 'Ví dụ', 'Example', 'EN03 example card tag.')
s('hnNotifVaccine', 'Nhắc lịch tiêm', 'Vaccine reminders', 'EN03 example row title.')
s('hnNotifVaccineWhen', 'Trước lịch tiêm', 'Before the visit', 'EN03 example row timing.')
s('hnNotifVaccineSample', '“Mai có lịch tiêm 6 trong 1 lúc 08:30.”', '“6-in-1 vaccine tomorrow at 08:30.”', 'EN03 example notification; no baby name (R-120).')
s('hnNotifRhythm', 'Nhịp lớn lên', 'Growing rhythm', 'EN03 example row title.')
s('hnNotifRhythmWhen', 'Trước 3 ngày', '3 days before', 'EN03 example row timing (NL02c stage reminder).')
s('hnNotifRhythmSample', '“Theo lịch tham khảo, con sắp đến giai đoạn 1.”', '“By the reference calendar, stage 1 is coming up.”', 'EN03 example notification; no baby name (R-120).')
s('hnNotifWeek', 'Tóm tắt tuần', 'Weekly summary', 'EN03 example row title (EN09).')
s('hnNotifWeekWhen', 'Chủ nhật 20:30', 'Sunday 20:30', 'EN03 example row timing.')
s('hnNotifWeekSample', '“Một tuần của con đã sẵn sàng để xem lại.”', '“Your little one’s week is ready to look back on.”', 'EN03 example notification; no baby name (R-120).')
s('hnNotifAllow', 'Bật thông báo', 'Turn on notifications', 'EN03 primary button; only this asks the system.')
s('hnNotifSettingsHint', 'Tắt hoặc chỉnh lại trong Tôi › Thông báo', 'Turn off or adjust in Me › Notifications', 'EN03 caption under the buttons.')
s('hnNotifDenied', 'Thông báo chưa bật. Bạn có thể bật trong Cài đặt của máy.', "Notifications are still off. You can turn them on in your phone's Settings.", 'Toast when the system prompt was refused.')

# Home invite 559:57870.
s('hnInviteTitle', 'Hôm nay theo cách của nhà bạn', "Today, your family's way", 'Home invite card title (559:57870).')
s('hnInviteBody', 'Chọn điều bạn quan tâm · 30\u00a0giây', 'Pick what matters to you · 30\u00a0seconds', 'Home invite card subtitle.')
s('hnInviteStart', 'Bắt đầu', 'Start', 'Home invite card button; opens EN01.')
s('hnInviteClose', 'Ẩn lời mời cá nhân hoá', 'Hide the personalisation invite', 'Home invite close button, for screen readers.')
s('hnInviteHidden', 'Đã ẩn. Bạn vẫn chỉnh được trong Tôi › Cá nhân hoá.', 'Hidden. You can still adjust this in Me › Personalisation.', 'Toast after closing the Home invite.')

# "Dành cho bé hôm nay" 559:57583.
s('hnForBabyBecause', 'Theo điều bạn quan tâm', 'Based on what you care about', 'Line under "Dành cho bé hôm nay" when the person picked interests.')
s('hnForBabyNoInterests', 'Chưa chọn điều bạn quan tâm', 'No interests picked yet', 'Line under "Dành cho bé hôm nay" without interests.')
s('hnForBabyChange', 'Đổi', 'Change', 'Link that opens EN01 (interests).')
s('hnForBabyPick', 'Chọn', 'Pick', 'Link that opens EN01 when nothing is picked yet.')
s('hnRhythmPill', 'Nhịp lớn lên · Beta', 'Growing rhythm · Beta', 'Pill on the Home Nhịp lớn lên card.')
s('hnRhythmExpected', 'Theo lịch tham khảo, dự kiến {range}.', 'By the reference calendar, expected {range}.', 'Home Nhịp lớn lên card body.', range='String')
s('hnRhythmSoothing', 'Cả nhà ghi nhận con cần được dỗ nhiều hơn {days} ngày qua.', 'The family noted more soothing over the past {days, plural, =1{day} other{{days} days}}.', "Home Nhịp lớn lên card: days with a 'needs more soothing' check-in lately.", days='int')
s('hnCardPage', 'Thẻ {page} trên {count}', 'Card {page} of {count}', 'Suggestion carousel dots, for screen readers.', page='int', count='int')
s('hnCardOptions', 'Tuỳ chọn cho thẻ này', 'Options for this card', 'Suggestion card × button, for screen readers.')

# Hôm nay information architecture (owner, 2026-10-15): one compact suggestion with "Vì sao gợi ý
# này?", "Để ý tuần này", and "Tuần này của {bé}" as one card with a teaser from real content.
# Numbering: "Tuần thứ N" is the week of life (completed weeks + 1); "N tuần tuổi" counts
# completed weeks only.
s('hnWhyLink', 'Vì sao gợi ý này?', 'Why this suggestion?', 'Small link on the Home suggestion card; opens the explanation sheet.')
s('hnWhyTitle', 'Vì sao gợi ý này', 'Why this suggestion', 'Title of the explanation sheet of the Home suggestion.')
s('hnWhyFeedbackShort', 'Đã điều chỉnh theo phản hồi của nhà mình.', 'Adjusted to your family’s feedback.', 'One-line reason on the Home suggestion when feedback changed the ranking (PS02); the details are in the sheet.')
s('hnWhyHow', 'Gợi ý dựa trên điều nhà mình ghi nhận, tuổi của bé và điều bạn quan tâm. Đây không phải chẩn đoán.', 'Suggestions come from what your family noted, your baby’s age and what you care about. This is not a diagnosis.', 'Footnote of the explanation sheet of the Home suggestion.')
s('hnWatchThisWeek', 'Để ý tuần này', 'Worth a look this week', 'Small heading above the Home carousel (milestones, reads, stage).')
s('hnWeekKicker', 'Tuần thứ {n} · {age}', 'Week {n} · {age}', 'Home "Tuần này" card: the week of life (completed weeks + 1) and the age ("4 tuần tuổi").', n='int', age='String')
s('hnWeekKickerOnly', 'Tuần thứ {n}', 'Week {n}', 'Home "Tuần này" card when the age is not readable (caregivers): the week of life of the content.', n='int')
s('hnMonthKicker', 'Tháng thứ {n} · {age}', 'Month {n} · {age}', 'Home "Tuần này" card from 3 months: the month of life (completed months + 1) and the age.', n='int', age='String')
s('hnMonthKickerOnly', 'Tháng thứ {n}', 'Month {n}', 'Home "Tuần này" card from 3 months when the age is not readable (caregivers).', n='int')
s('hnWeekOpen', 'Xem tuần này', 'See this week', 'Action of the Home "Tuần này" card.')
s('hnWeekOpenIdeas', 'Xem {count} gợi ý cho tuần này', '{count, plural, =1{See 1 idea for this week} other{See {count} ideas for this week}}', 'Action of the Home "Tuần này" card with the number of tips the content holds.', count='int')
s('hnWeekRhythmSub', 'Wonder Weeks · dự kiến {range}', 'Wonder Weeks · expected {range}', 'Home "Tuần này" card, Nhịp lớn lên row: the reference window.', range='String')
s('hnRhythmComingDays', 'Còn {days} ngày đến giai đoạn {n}', '{days, plural, =1{Stage {n} in 1 day} other{Stage {n} in {days} days}}', 'Home "Tuần này" card, Nhịp lớn lên row: the next reference stage and the days until its window.', n='int', days='int')
s('hnRhythmNow', 'Đang trong giai đoạn {n}', 'In stage {n}', 'Home "Tuần này" card, Nhịp lớn lên row: today is inside the reference window.', n='int')
s('hnWeekSummaryLast', 'Tóm tắt tuần trước', 'Last week’s summary', 'Home "Tuần này" card row opening EN09 (Monday to Saturday: the last completed week).')
s('hnWeekSummaryThis', 'Tóm tắt tuần này', 'This week’s summary', 'Home "Tuần này" card row opening EN09 on Sunday (the week ending today).')

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
