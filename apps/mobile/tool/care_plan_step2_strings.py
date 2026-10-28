# Cùng Chăm Con, step 2 (D-135; ANALYSIS-2026-10-28 §2, §6): the Hôm nay section "n việc cần làm",
# the "Đến giờ rồi" sheet (Figma 15), the person's task-reminder settings (13, N1) and the helper
# on duty in the Bàn giao row (Q1). Also renames the Tuỳ chỉnh toggle "Ai đang trông bé" →
# "Việc chăm con cần làm" (same id, the stored `duty` choice carries over). Vietnamese is the
# source; English is an engineering draft for owner review (D-012). Idempotent.
# Usage: python3 tool/care_plan_step2_strings.py && flutter gen-l10n
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

NOTE = ' EN is an engineering draft for owner review.'

# Hôm nay section (14)
s('cpHomeTitle', '{count, plural, other{{count} việc cần làm}}',
  '{count, plural, =1{1 task to do} other{{count} tasks to do}}',
  'Hôm nay: header of the viewer\'s open Cùng Chăm Con tasks today (D-135 Q4: shared tasks only, never personal reminders).' + NOTE,
  count='int')
s('cpHomeAll', 'Tất cả', 'All',
  'Hôm nay "n việc cần làm": link to the whole day plan (Cùng Chăm Con).' + NOTE)
s('cpDoneAction', 'Đã làm', 'Done',
  'Cùng Chăm Con: mark this task done (Hôm nay row, "Đến giờ rồi" sheet).' + NOTE)

# "Đến giờ rồi" (15)
s('cpDueTitle', 'Đến giờ rồi', 'It\'s time',
  'Cùng Chăm Con sheet when one of the viewer\'s tasks is due (app open or reminder push).' + NOTE)
s('cpDueLater', 'Để sau 10 phút', 'Later · 10 min',
  '"Đến giờ rồi": put the sheet off for 10 minutes.' + NOTE)
s('cpDueSeeDay', 'Xem cả lịch hôm nay', 'See today\'s plan',
  '"Đến giờ rồi": open the whole Cùng Chăm Con day.' + NOTE)
s('cpDueDoneAll', '{count, plural, other{Đã làm cả {count} việc}}',
  '{count, plural, =1{Done} other{All {count} done}}',
  '"Đến giờ rồi" with several tasks due together: mark them all done.' + NOTE, count='int')
s('cpDoneManyToast', '{count, plural, other{Đã làm {count} việc}}',
  '{count, plural, =1{1 task done} other{{count} tasks done}}',
  'Toast after marking several Cùng Chăm Con tasks done at once.' + NOTE, count='int')
s('cpDueGone', 'Việc này đã xong hoặc đã được bỏ qua', 'That task is already done or skipped',
  'Toast when a reminder push is opened for a task that is no longer open.' + NOTE)

# Reminder settings (13, the person's own part)
s('cpRemindTitle', 'Nhắc việc chăm con', 'Care task reminders',
  'Cùng Chăm Con: this person\'s reminder settings (screen title, settings button label).' + NOTE)
s('cpRemindBefore', 'Nhắc trước', 'Remind me',
  'Cùng Chăm Con settings: how long before a task the reminder comes.' + NOTE)
s('cpRemindHint',
  'Chỉ nhắc việc được giao cho bạn. Các việc cách nhau dưới 15 phút đến trong một thông báo.',
  'Only for tasks given to you. Tasks less than 15 minutes apart come in one notification.',
  'Cùng Chăm Con settings: what is reminded and the grouping rule (N1).' + NOTE)
s('cpLeadMinutes', '{minutes} phút', '{minutes} min',
  'Cùng Chăm Con "Nhắc trước" choice.' + NOTE, minutes='int')
s('cpLeadValue', 'Trước {minutes} phút', '{minutes} min before',
  'Thông báo › Việc chăm con: the current "Nhắc trước" choice.' + NOTE, minutes='int')
s('cpQuietHours', 'Nhắc cả trong giờ yên lặng', 'Also during quiet hours',
  'Cùng Chăm Con settings switch (D-135 Q5, on by default).' + NOTE)
s('cpQuietHoursHint', 'Không làm phiền của điện thoại vẫn có thể chặn thông báo.',
  'Your phone\'s Do Not Disturb can still silence it.',
  'Under "Nhắc cả trong giờ yên lặng": the app cannot override the phone\'s own setting, so it does not promise to.' + NOTE)
s('ntCareTasks', 'Việc chăm con', 'Care tasks',
  'Thông báo › Nhắc việc: opens the Cùng Chăm Con reminder settings.' + NOTE)

# Bàn giao row (Q1: only a helper is ever shown as caring)
s('cpHelperOnUntil', '{name} đang trông · đến {time}', '{name} is caring · until {time}',
  'Hôm nay Bàn giao row: a helper (caregiver role) on duty and the time of their last task today (D-135 Q1, Q2). Never Ba or Mẹ.' + NOTE,
  name='String', time='String')

root = pathlib.Path(__file__).resolve().parent.parent / 'lib' / 'l10n'
RENAME = {
    'axWidgetCareDuty': (
        'Việc chăm con cần làm', 'Care tasks to do',
        'Tuỳ chỉnh Hôm nay / Cài đặt giao diện switch for the "n việc cần làm" section (D-135; stored as `duty`, so the old "Ai đang trông bé" choice carries over).' + NOTE),
}
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
    for key, (vi, en, desc) in RENAME.items():
        data[key] = (vi, en)[idx]
        if locale == 'vi':
            data['@' + key] = collections.OrderedDict(description=desc)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
print(len(S) + len(RENAME), 'strings')
