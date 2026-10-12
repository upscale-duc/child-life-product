# Sơ cứu trẻ em (Figma v1.1 7a–7i, TH01–TH24; D-058). The app's own copy only: the guide's text
# comes from the portal pack. Vietnamese = Figma, English = engineering draft (D-012). Idempotent.
# Usage: python3 tool/first_aid_strings.py
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

def pl(one, other):
    return '{count, plural, =1{' + one + '} other{' + other + '}}'

s('faEntryTitle', 'Sơ cứu trẻ em', 'Child first aid', '7a entry banner on Chăm sóc.')
s('faEntrySub', '{count} tình huống · dùng khi không có mạng', pl('1 situation · works offline', '{count} situations · works offline'), '7a banner subline.', count='int')
s('faTitle', 'Sơ cứu', 'First aid', '7b title.')
s('faSubtitle', 'Bình tĩnh, làm theo từng bước. Dùng được cả khi không có mạng.', 'Stay calm and follow the steps. Works even without a connection.', '7b subtitle.')
s('faEmergencyQuestion', 'Bé không thở, tím tái hoặc bất tỉnh?', 'Baby not breathing, turning blue or unconscious?', '7b emergency card.')
s('faCall', 'Gọi {number}', 'Call {number}', 'Red call buttons.', number='String')
s('faStartCpr', 'Bắt đầu hồi sức tim phổi (CPR)', 'Start CPR', '7b emergency card.')
s('faSearchHint', 'Hóc, sốt, bỏng, khó thở…', 'Choking, fever, burns, breathing…', '7b / 7c search placeholder.')
s('faAll', 'Tất cả', 'All', '7b filter chip.')
s('faSortedFor', 'Sắp xếp theo tuổi {name} · {age}', 'Sorted for {name} · {age}', '7b first section subline.', name='String', age='String')
s('faSaved', 'Đã lưu', 'Saved', 'Saved situations screen title; bookmark a11y.')
s('faSavedEmpty', 'Chưa lưu tình huống nào. Bấm dấu trang trên một tình huống để lưu lại đây.', 'Nothing saved yet. Tap the bookmark on a situation to keep it here.', 'Saved screen empty.')
s('faSave', 'Lưu tình huống', 'Save this situation', 'Bookmark a11y.')
s('faUnsave', 'Bỏ lưu', 'Remove from saved', 'Bookmark a11y when saved.')
s('faSavedToast', 'Đã lưu vào Sơ cứu · Đã lưu', 'Saved to First aid · Saved', 'Toast.')
s('faUnsavedToast', 'Đã bỏ lưu', 'Removed from saved', 'Toast.')
s('faResults', '{count} tình huống', pl('1 situation', '{count} situations'), '7c result count.', count='int')
s('faQuickSearch', 'Tìm nhanh', 'Quick search', '7c chips header.')
s('faNoResults', 'Không tìm thấy tình huống phù hợp. Bé gặp nguy hiểm: gọi {number}.', 'No matching situation. If your baby is in danger, call {number}.', '7c no results.', number='String')
s('faOffline', 'Dùng được khi không có mạng', 'Works offline', 'Detail tag.')
s('faMonitoring', 'Theo dõi', 'Monitoring', 'Detail tag (TH21, TH24).')
s('faFollowSteps', 'Làm theo các bước', 'Follow the steps', 'Detail section header.')
s('faStepMode', 'Làm theo từng bước', 'Step by step', 'Bottom bar primary.')
s('faTimes', 'lần', 'times', 'After the count dots (7d).')
s('faDisclaimer', 'Nội dung tham khảo, không thay thế chẩn đoán của bác sĩ.', 'For reference only. It does not replace a doctor’s diagnosis.', 'Detail footer (no review claimed until one is recorded, P-141).')
s('faReviewed', 'Được {reviewer} rà soát tháng {month}.', 'Reviewed by {reviewer}, {month}.', 'Detail footer once a review is recorded.', reviewer='String', month='String')
s('faSeizureTimer', 'Bấm giờ cơn giật', 'Time the seizure', 'TH04 timer card.')
s('faTimerStart', 'Bắt đầu', 'Start', 'TH04 timer.')
s('faTimerStop', 'Dừng', 'Stop', 'TH04 timer.')
s('faTimerReset', 'Bấm lại', 'Reset', 'TH04 timer after stopping.')
s('faStepOf', '{title} · Bước {n}/{total}', '{title} · Step {n}/{total}', '7f progress label.', title='String', n='int', total='int')
s('faTapToCount', 'Chạm để đếm', 'Tap to count', '7f counter card.')
s('faScreenOn', 'Màn hình luôn sáng trong khi bạn làm theo hướng dẫn.', 'The screen stays on while you follow the guide.', '7f footnote.')
s('faBack', 'Quay lại', 'Back', '7f secondary.')
s('faNext', 'Bước tiếp', 'Next step', '7f primary.')
s('faFinish', 'Xong', 'Done', 'Step mode, last step.')
s('faClose', 'Đóng hướng dẫn', 'Close the guide', 'Step / CPR mode close a11y.')
s('faCprStep', '{title} · Bước {n}/{total} · Chu kỳ {cycle}', '{title} · Step {n}/{total} · Cycle {cycle}', '7i progress label.', title='String', n='int', total='int', cycle='int')
s('faCprRate', '{rate} nhịp/phút', '{rate} per minute', '7i beat row.', rate='int')
s('faCprBeep', 'Tiếng bíp và rung theo nhịp', 'Beep and vibration on each beat', '7i.')
s('faCprNextBreaths', 'Tiếp: thổi ngạt {count} lần', pl('Next: 1 rescue breath', 'Next: {count} rescue breaths'), '7i pill.', count='int')
s('faCprNextCompressions', 'Tiếp: ép ngực {count} lần', 'Next: {count} chest compressions', '7i pill on the breaths step.', count='int')
s('faCprFootnote', 'Màn hình luôn sáng. Dừng ép không quá 10 giây.', 'The screen stays on. Never pause compressions for more than 10 seconds.', '7i footnote.')
s('faCprPause', 'Tạm dừng', 'Pause', '7i secondary.')
s('faCprResume', 'Tiếp tục', 'Resume', '7i secondary when paused.')
s('faCprBreathing', 'Bé đã thở lại', 'Baby is breathing again', '7i primary.')
s('faCprBreathsDone', 'Đã thổi {count} lần', pl('1 breath given', '{count} breaths given'), '7i breaths step primary.', count='int')
s('faCprStopped', 'Tiếp tục theo dõi bé đến khi nhân viên y tế tới. Bé ngừng thở lại: bắt đầu lại ngay.', 'Keep watching your baby until medical help arrives. If breathing stops again, start again at once.', 'Toast after "Bé đã thở lại".')
s('faCallTitle', 'Gọi cấp cứu {number}', 'Call emergency {number}', '7h sheet title.', number='String')
s('faCallHandling', 'Đang xử lý: {situation}', 'Now handling: {situation}', '7h baby row.', situation='String')
s('faCallTell', 'Nói rõ với tổng đài', 'Tell the operator', '7h checklist header.')
s('faCallTell1', 'Bé mấy tuổi, chuyện gì đã xảy ra', 'How old your baby is and what happened', '7h checklist.')
s('faCallTell2', 'Bé còn thở, còn tỉnh không', 'Whether your baby is breathing and awake', '7h checklist.')
s('faCallTell3', 'Địa chỉ chính xác, điểm dễ nhận biết', 'The exact address and a landmark', '7h checklist.')
s('faCallTell4', 'Số điện thoại để gọi lại', 'A number to call you back on', '7h checklist.')
s('faCallFailed', 'Không mở được trình gọi điện. Hãy bấm số {number} trên điện thoại.', 'Couldn’t open the phone app. Dial {number} on your phone.', 'Toast.', number='String')
s('faWeightKg', '{kg} kg', '{kg} kg', '7h baby row weight.', kg='String')
s('faNotFound', 'Không tìm thấy hướng dẫn này. Mở lại Sơ cứu.', 'This guide wasn’t found. Open First aid again.', 'Unknown situation id.')

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
