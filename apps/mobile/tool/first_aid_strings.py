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
s('faDisclaimer', 'Nội dung tham khảo, không thay thế chẩn đoán của bác sĩ.', 'For reference only. It does not replace a doctor’s diagnosis.', 'Detail footer (no review claimed until one is recorded, P-141).')
s('faReviewed', 'Được {reviewer} rà soát tháng {month}.', 'Reviewed by {reviewer}, {month}.', 'Detail footer once a review is recorded.', reviewer='String', month='String')
s('faSeizureTimer', 'Bấm giờ cơn giật', 'Time the seizure', 'TH04 timer card.')
s('faTimerStart', 'Bắt đầu', 'Start', 'TH04 timer.')
s('faTimerStop', 'Dừng', 'Stop', 'TH04 timer.')
s('faTimerReset', 'Bấm lại', 'Reset', 'TH04 timer after stopping.')
s('faCallFailed', 'Không mở được trình gọi điện. Hãy bấm số {number} trên điện thoại.', 'Couldn’t open the phone app. Dial {number} on your phone.', 'Toast.', number='String')
s('faWeightKg', '{kg} kg', '{kg} kg', '7h baby row weight.', kg='String')
s('faNotFound', 'Không tìm thấy hướng dẫn này. Mở lại Sơ cứu.', 'This guide wasn’t found. Open First aid again.', 'Unknown situation id.')

# Revision 2 (hands-free, 2026-10-12): read aloud, automatic CPR beat, call at once.
s('faReadAloud', 'Đọc to hướng dẫn', 'Read the guide aloud', 'Bottom bar (normal pages).')
s('faReadAloudShort', 'Đọc to', 'Read aloud', 'Speaker button a11y (emergency pages).')
s('faStopReading', 'Dừng đọc', 'Stop reading', 'Bottom bar while reading.')
s('faCountTimes', '× {count} lần', pl('× 1 time', '× {count} times'), 'Static count label on a step (was tap-to-count).', count='int')
s('faCalling', 'Đang gọi {number} · {time}', 'Calling {number} · {time}', 'Green bar after dialling (7h revision 2).', number='String', time='String')
s('faTellOperator', 'Nói với tổng đài', 'Tell the operator', '7h card.')
s('faTellBaby', 'Bé', 'Baby', '7h card row.')
s('faTellCondition', 'Tình trạng', 'Condition', '7h card row.')
s('faMetronomeTitle', 'Nhịp ép đang phát · tự động', 'Compression beat playing · automatic', 'TH01 metronome card.')
s('faMetronomePaused', 'Nhịp ép tạm dừng trong lúc đọc', 'Beat paused while reading', 'TH01 metronome while the guide is read aloud.')
s('faMetronomeBody', 'Bật loa, đặt điện thoại cạnh bé. Ép theo tiếng bíp. Sau mỗi {count} lần, app đọc “thổi ngạt {breaths} lần”.', 'Turn the speaker on and put the phone beside your baby. Press with each beep. After every {count}, the app says “{breaths} rescue breaths”.', 'TH01 metronome card body.', count='int', breaths='int')
s('faSayBreaths', 'Thổi ngạt {count} lần', pl('Give 1 rescue breath', 'Give {count} rescue breaths'), 'Spoken after each set of compressions.', count='int')
s('faSpeakStep', 'Bước {n}. {title}. {body}', 'Step {n}. {title}. {body}', 'Spoken while reading a step aloud.', n='int', title='String', body='String')

OBSOLETE = ['faStepMode', 'faTimes', 'faStepOf', 'faTapToCount', 'faScreenOn', 'faBack', 'faNext', 'faFinish', 'faClose', 'faCprStep', 'faCprRate', 'faCprBeep', 'faCprNextBreaths', 'faCprNextCompressions', 'faCprFootnote', 'faCprPause', 'faCprResume', 'faCprBreathing', 'faCprBreathsDone', 'faCprStopped', 'faCallTitle', 'faCallHandling', 'faCallTell', 'faCallTell1', 'faCallTell2', 'faCallTell3', 'faCallTell4']

root = pathlib.Path(__file__).resolve().parent.parent / 'lib' / 'l10n'
for locale, idx in (('vi', 0), ('en', 1)):
    path = root / f'app_{locale}.arb'
    data = json.loads(path.read_text(), object_pairs_hook=collections.OrderedDict)
    for key in OBSOLETE:
        data.pop(key, None)
        data.pop('@' + key, None)
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
