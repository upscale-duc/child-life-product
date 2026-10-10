# One-off generator for the S5 ARB entries (sleep, timers, overlap, first-run tour).
# Vietnamese = Figma source, English = engineering draft (D-012). Usage: python3 tool/s5_strings.py
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

# 25a
s('sleepChooserTitle', 'Ghi giấc ngủ', 'Log sleep', '25a sheet title (69:4213).')
s('sleepChooserPrompt', '{baby} đang ngủ hay đã ngủ xong rồi?', 'Is {baby} asleep now, or already awake?', '25a prompt.', baby='String')
s('sleepStartTimer', 'Bắt đầu hẹn giờ', 'Start timer', '25a primary option / 26 link.')
s('sleepStartTimerHint', '{baby} vừa ngủ. Đồng hồ chạy, cả nhà cùng thấy', '{baby} just fell asleep. The timer runs and the family sees it', '25a option subtitle.', baby='String')
s('sleepManual', 'Nhập giấc đã ngủ', 'Enter a past sleep', '25a secondary option.')
s('sleepManualHint', 'Quên bấm giờ? Chọn giờ bắt đầu và kết thúc', 'Forgot the timer? Pick when it started and ended', '25a option subtitle.')
s('sleepChooserFootnote', 'Đổi cách bất cứ lúc nào: từ đồng hồ có thể sửa giờ bắt đầu, từ nhập tay có thể chuyển sang hẹn giờ.', 'Switch any time: the timer lets you fix the start, manual entry can switch to the timer.', '25a footnote.')
# Timers (25, 23b, 23c, 9c)
s('timerFamilySees', 'Cả nhà đang thấy', 'The family can see this', 'Timer sync pill (R-070).')
s('timerOnlyHere', 'Chỉ trên máy này', 'Only on this device', 'Timer / record not synced (9c, 27).')
s('sleepNotSynced', 'Giấc ngủ này chưa được đồng bộ', 'This sleep hasn’t synced yet', '9c note.')
s('timerNotSynced', 'Cữ này chưa được đồng bộ', 'This hasn’t synced yet', 'Feed / pump timer offline note.')
s('sleepTimerTitle', 'Bé {baby} đang ngủ', '{baby} is sleeping', '25 title (47:3028).', baby='String')
s('timerStartedBy', '{who} bắt đầu lúc {time}', '{who} started at {time}', 'Timer subtitle.', who='String', time='String')
s('sleepRingLabel', 'Đang ngủ', 'Asleep', 'Sleep ring label.')
s('sinceTime', 'Từ {time}', 'Since {time}', 'Sleep ring footer.', time='String')
s('endSleep', 'Kết thúc giấc ngủ', 'End sleep', '25 primary.')
s('editStart', 'Sửa giờ bắt đầu', 'Edit start time', '25 secondary.')
s('cancelNoSave', 'Hủy, không lưu', 'Cancel, don’t save', 'Timer plain button.')
s('cancelConfirmTitle', 'Hủy và không lưu?', 'Cancel without saving?', 'Timer cancel confirmation (not drawn).')
s('cancelConfirmBody', 'Thời gian đã chạy sẽ không được ghi.', 'The time so far won’t be logged.', 'Timer cancel confirmation body.')
s('keepTiming', 'Tiếp tục bấm giờ', 'Keep timing', 'Timer cancel confirmation dismiss.')
s('breastTimerTitle', '{baby} đang bú mẹ', '{baby} is breastfeeding', '23b title (112:11135).', baby='String')
s('totalTime', 'Tổng thời gian', 'Total time', 'Timer total label.')
s('sideLeftCaps', 'TRÁI', 'LEFT', 'Side disc label.')
s('sideRightCaps', 'PHẢI', 'RIGHT', 'Side disc label.')
s('feedingNow', 'Đang bú', 'Feeding', 'Active breast disc.')
s('tapToSwitch', 'Chạm để đổi bên', 'Tap to switch', 'Inactive breast disc.')
s('lastEndedLeft', 'Lần trước kết thúc bên trái', 'Last feed ended on the left', '23b hint.')
s('lastEndedRight', 'Lần trước kết thúc bên phải', 'Last feed ended on the right', '23b hint.')
s('endFeed', 'Kết thúc cữ bú', 'End feed', '23b primary.')
s('pauseTimer', 'Tạm dừng', 'Pause', 'Timer secondary.')
s('resumeTimer', 'Tiếp tục', 'Resume', 'Timer secondary while paused.')
s('pausedLabel', 'Tạm dừng', 'Paused', 'Disc state while paused.')
s('pumpTimerTitle', '{who} đang hút sữa', '{who} is pumping', '23c title (113:11207).', who='String')
s('pumpStartedFor', 'Bắt đầu lúc {time} · cho {baby}', 'Started at {time} · for {baby}', '23c subtitle.', time='String', baby='String')
s('pumpingNow', 'Đang hút', 'Pumping', 'Running pump disc.')
s('pumpStopped', 'Đã dừng', 'Stopped', 'Stopped pump disc.')
s('tapToStart', 'Chạm để chạy', 'Tap to start', 'Stopped pump disc hint.')
s('doublePumpHint', 'Hút đôi · chạm 1 bên để dừng riêng', 'Double pumping · tap a side to stop it', '23c hint.')
s('pumpDone', 'Xong · nhập lượng sữa', 'Done · enter amount', '23c primary.')
s('timerInstead', 'Bấm giờ thay vì nhập', 'Time it instead', '23 / 23a plain.')
s('timerJoined', '{who} đã bắt đầu đồng hồ này trước. Bạn đang xem cùng.', '{who} already started this timer. You’re following it.', 'A second start joined the running timer (P-011).', who='String')
# Today sleep tile
s('wokeAt', 'Dậy lúc {time}', 'Woke at {time}', 'Sleep tile line.', time='String')
s('runningSince', 'Từ {time} · {who}', 'Since {time} · {who}', 'Running timer tile line.', time='String', who='String')
# 26
s('manualSleepTitle', 'Nhập giấc ngủ', 'Enter sleep', '26 title (47:3074).')
s('overnight', 'Qua đêm', 'Overnight', '26 chip.')
s('sleepEnd', 'Kết thúc', 'End', '26 end row.')
s('overnightNote', 'Giấc qua đêm được chia vào tổng của từng ngày theo múi giờ của bé ({offset}).', 'An overnight sleep counts toward each day in the baby’s time zone ({offset}).', '26 note.', offset='String')
s('sleepingNow', '{baby} đang ngủ?', 'Is {baby} asleep now?', '26 link row.', baby='String')
s('saveSleep', 'Lưu giấc ngủ', 'Save sleep', '26 primary.')
s('sleepEndBeforeStart', 'Giờ kết thúc phải sau giờ bắt đầu.', 'The end must be after the start.', '26 validation (not drawn).')
s('sleepTooLong', 'Một giấc dài tối đa 24 giờ.', 'A sleep can last 24 hours at most.', '26 validation (not drawn).')
# 27
s('overlapTitle', 'Có hai giấc ngủ trùng nhau', 'Two sleeps overlap', '27 title (47:3145).')
s('overlapBody', 'Chọn bản đúng. App không tự gộp hay ghi đè.', 'Pick the right one. The app never merges or overwrites.', '27 body.')
s('backOnline', 'Đã có mạng lại', 'Back online', '27 sync pill.')
s('keepSelected', 'Giữ bản đã chọn', 'Keep selected', '27 primary.')
s('editMine', 'Sửa tay từ bản của tôi', 'Edit my version', '27 plain.')
s('overlapBanner', 'Có hai giấc ngủ trùng nhau · chọn bản đúng', 'Two sleeps overlap · pick the right one', 'Today banner to 27 (eng-supplied).')
s('overlapKept', 'Đã giữ bản đã chọn. Bản kia vào “Đã xoá gần đây” 30 ngày.', 'Kept. The other one stays in “Recently deleted” for 30 days.', 'Toast after 27.')
s('overlapNotAllowed', 'Bản kia do ba mẹ ghi. Nhờ ba mẹ chọn nhé.', 'The other one was logged by a parent. Ask a parent to choose.', 'Caregiver cannot bin a parent’s sleep (D-022).')
# 18a–18c tour
s('tourStep', 'Bước {n}/3', 'Step {n}/3', 'Tour step.', n='int')
s('tour1Title', 'Ghi cữ bú đầu tiên', 'Log the first feed', '18 tour 1/3 (29:904).')
s('tour1Body', 'Chạm thẻ Bú bình để ghi. Các thẻ khác cũng ghi y như vậy.', 'Tap the Bottle card to log. The other cards work the same way.', '18 tour 1/3 body.')
s('tour2Title', 'Theo dõi {baby} lớn lên', 'Follow {baby} growing', '18b tour 2/3 (103:8099).', baby='String')
s('tour2Body', 'Nhập cân nặng, chiều dài lúc sinh. Mỗi lần đo sau, app tự so với lần trước.', 'Enter weight and length at birth. Each new measurement is compared with the last.', '18b body.')
s('tour3Title', 'Ghi nhanh từ mọi nơi', 'Quick log from anywhere', '18c tour 3/3 (103:8275).')
s('tour3Body', 'Nút + luôn ở đây, ở mọi tab. Chạm để chọn việc cần ghi.', 'The + button is always here, on every tab. Tap it to choose what to log.', '18c body.')
s('tourStart', 'Bắt đầu', 'Start', '18c last action.')

def placeholders(ph):
    return {k: {'type': v} for k, v in ph.items()}

root = pathlib.Path(__file__).resolve().parent.parent / 'lib' / 'l10n'
for locale, idx in (('vi', 0), ('en', 1)):
    path = root / f'app_{locale}.arb'
    data = json.loads(path.read_text(), object_pairs_hook=collections.OrderedDict)
    for key, (vi, en, desc, ph) in S.items():
        data[key] = (vi, en)[idx]
        if locale == 'vi':
            meta = collections.OrderedDict(description=desc)
            if ph:
                meta['placeholders'] = placeholders(ph)
            data['@' + key] = meta
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
print(len(S), 'strings')
