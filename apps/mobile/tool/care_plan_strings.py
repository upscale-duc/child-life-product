# Cùng Chăm Con, step 1 (D-135, owner 2026-10-28: "ok theo đề xuất, làm bước 1 đi"): the shared
# day plan (04 / 04b / 04-0), Giao việc (05), Thêm / Sửa việc (06 / 06b), the Khám phá row and the
# one-time swipe hint. Vietnamese is the source; English is an engineering draft for owner review
# (D-012). Idempotent. Usage: python3 tool/care_plan_strings.py && flutter gen-l10n
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

NOTE = ' EN is an engineering draft for owner review.'

# Entry and screen
s('cpTitle', 'Cùng Chăm Con', 'Care together',
  'Cùng Chăm Con: the Khám phá row and the screen title (D-135).' + NOTE)
s('cpExploreSub', 'Lịch chăm bé chung, giao việc cho cả nhà', 'One care plan, shared by the family',
  'Cùng Chăm Con row subtitle in Khám phá › Gia đình & trợ lý.' + NOTE)
s('cpDayTasks', '{count, plural, other{{count} việc}}',
  '{count, plural, =1{1 task} other{{count} tasks}}',
  'Cùng Chăm Con: how many tasks (the day, a group, a person).' + NOTE, count='int')
s('cpStarts', 'Bắt đầu {time} · {task}', 'Starts {time} · {task}',
  'Cùng Chăm Con summary before anything is done: the first task.' + NOTE, time='String', task='String')
s('cpNext', 'Tiếp theo {time} · {task}', 'Next {time} · {task}',
  'Cùng Chăm Con summary once something is done: the next open task.' + NOTE, time='String', task='String')
s('cpLeft', '{count, plural, other{Còn {count} việc}}',
  '{count, plural, =1{1 left} other{{count} left}}',
  'Cùng Chăm Con summary: open tasks left today.' + NOTE, count='int')
s('cpAllDone', 'Xong hết việc hôm nay', 'Everything is done for today',
  'Cùng Chăm Con summary when every task is done or skipped.' + NOTE)
s('cpProgressA11y', 'Đã làm {done} trên {total} việc', '{done} of {total} tasks done',
  'Cùng Chăm Con progress ring, read by screen readers.' + NOTE, done='int', total='int')
s('cpMorning', 'Sáng', 'Morning', 'Cùng Chăm Con group: tasks before 12:00.' + NOTE)
s('cpAfternoon', 'Chiều', 'Afternoon', 'Cùng Chăm Con group: 12:00–17:59.' + NOTE)
s('cpEvening', 'Tối', 'Evening', 'Cùng Chăm Con group: from 18:00.' + NOTE)
s('cpAssignGroup', 'Giao cả buổi', 'Assign all',
  'Cùng Chăm Con: give every task of this group (Sáng / Chiều / Tối) to the same people. A group is not a shift (D-135).' + NOTE)
s('cpAddTask', 'Thêm việc', 'Add task', 'Cùng Chăm Con: add a task (button, sheet title).' + NOTE)
s('cpAssignShort', 'Giao', 'Assign', 'Cùng Chăm Con task with nobody on it: the chip that opens Giao việc.' + NOTE)
s('cpMarkDone', 'Đánh dấu đã làm: {task}', 'Mark done: {task}',
  'Cùng Chăm Con ring, screen reader label.' + NOTE, task='String')
s('cpMarkOpen', 'Đã làm: {task}. Chạm để bỏ đánh dấu', 'Done: {task}. Tap to undo',
  'Cùng Chăm Con ring of a done task, screen reader label.' + NOTE, task='String')
s('cpDoneToast', 'Đã làm · {task}', 'Done · {task}',
  'Cùng Chăm Con toast after the ring (with Hoàn tác).' + NOTE, task='String')
s('cpDoneBy', '{name} đã làm', '{name} did it',
  'Cùng Chăm Con task line when done, who did it (may differ from who was assigned).' + NOTE, name='String')
s('cpSkipped', 'Bỏ qua hôm nay', 'Skipped today', 'Cùng Chăm Con task line when skipped.' + NOTE)
s('cpEveryDay', 'Mọi ngày', 'Every day', 'Cùng Chăm Con: a task kept for every day (segment and tag).' + NOTE)
s('cpTodayOnly', 'Chỉ hôm nay', 'Today only', 'Cùng Chăm Con: change only this day (segment).' + NOTE)
s('cpSaveFailed', 'Chưa lưu được. Kiểm tra mạng rồi thử lại.', "Couldn't save. Check your connection and try again.",
  'Cùng Chăm Con toast when a change did not reach the server.' + NOTE)
s('cpLoadFailed', 'Chưa tải được lịch. Kiểm tra mạng rồi thử lại.', "Couldn't load the plan. Check your connection and try again.",
  'Cùng Chăm Con when the day cannot be read.' + NOTE)
s('cpSwipeHint', 'Vuốt sang trái để sửa hoặc xoá', 'Swipe left to edit or delete',
  'Cùng Chăm Con one-time hint on the first task (ClTourTip, like the Hôm nay tour).' + NOTE)
s('cpGotIt', 'Đã hiểu', 'Got it', 'Cùng Chăm Con one-time hint button.' + NOTE)

# 04-0 no plan yet
s('cpEmptyToday', 'Hôm nay chưa có lịch', 'No plan for today yet', 'Cùng Chăm Con 04-0 title, today.' + NOTE)
s('cpEmptyDay', 'Ngày này chưa có lịch', 'No plan for this day', 'Cùng Chăm Con 04-0 title, another day.' + NOTE)
s('cpEmptyViewer', 'Khi ba mẹ lên lịch, việc sẽ hiện ở đây.', 'When the parents make a plan, the tasks show here.',
  'Cùng Chăm Con 04-0 for someone who cannot make the plan (Người chăm sóc, Người thân).' + NOTE)
s('cpStartEveryday', 'Dùng lịch mọi ngày', 'Use the everyday plan',
  'Cùng Chăm Con 04-0: start from the tasks kept every day.' + NOTE)
s('cpStartYesterday', 'Giống hôm qua', 'Same as yesterday', 'Cùng Chăm Con 04-0: copy yesterday.' + NOTE)
s('cpStartEmpty', 'Tự thêm việc', 'Add tasks yourself', 'Cùng Chăm Con 04-0: start with no tasks.' + NOTE)

# 05 Giao việc
s('cpAssignWhoMorning', 'Giao việc buổi sáng cho ai?', 'Who takes the morning?', 'Cùng Chăm Con 05 title, group Sáng.' + NOTE)
s('cpAssignWhoAfternoon', 'Giao việc buổi chiều cho ai?', 'Who takes the afternoon?', 'Cùng Chăm Con 05 title, group Chiều.' + NOTE)
s('cpAssignWhoEvening', 'Giao việc buổi tối cho ai?', 'Who takes the evening?', 'Cùng Chăm Con 05 title, group Tối.' + NOTE)
s('cpAssignWhoTask', 'Ai làm việc này?', "Who's doing this?", 'Cùng Chăm Con 05 title, one task.' + NOTE)
s('cpMemberLoad', '{count, plural, =0{Chưa có việc hôm nay} other{{count} việc hôm nay}}',
  '{count, plural, =0{No tasks today} =1{1 task today} other{{count} tasks today}}',
  'Cùng Chăm Con 05: how many tasks this person has on this day.' + NOTE, count='int')
s('cpAssignTo', 'Giao cho {names}', 'Assign to {names}', 'Cùng Chăm Con 05 main button.' + NOTE, names='String')
s('cpAssignNobody', 'Để trống người làm', 'Leave unassigned', 'Cùng Chăm Con 05 main button with nobody chosen.' + NOTE)
s('cpNamesTwo', '{first} và {second}', '{first} and {second}', 'Two people, e.g. "Ba và Mẹ".' + NOTE, first='String', second='String')
s('cpNamesMore', '{first} và {count} người', '{count, plural, =1{{first} and 1 other} other{{first} and {count} others}}',
  'Three or more people: the first and how many more.' + NOTE, first='String', count='int')

# 06 / 06b
s('cpEditTask', 'Sửa việc', 'Edit task', 'Cùng Chăm Con 06b sheet title.' + NOTE)
s('cpCustomName', 'Tên việc', 'Task name', 'Cùng Chăm Con 06: the name of a custom task.' + NOTE)
s('cpCustomHint', 'VD: nhỏ mũi', 'e.g. nose drops', 'Cùng Chăm Con 06: custom task placeholder.' + NOTE)
s('cpTime', 'Giờ', 'Time', 'Cùng Chăm Con 06: time row.' + NOTE)
s('cpWho', 'Ai làm', 'Who', 'Cùng Chăm Con 06: people label.' + NOTE)
s('cpSkipToday', 'Bỏ qua hôm nay', 'Skip today', 'Cùng Chăm Con 06b: skip the task today (can be undone).' + NOTE)
s('cpUnskip', 'Làm lại việc này hôm nay', 'Bring it back today', 'Cùng Chăm Con 06b on a skipped task.' + NOTE)
s('cpSkipToast', 'Đã bỏ qua · {task}', 'Skipped · {task}', 'Cùng Chăm Con toast after skipping (with Hoàn tác).' + NOTE, task='String')
s('cpDelete', 'Xoá việc', 'Delete task', 'Cùng Chăm Con 06b and the swipe action.' + NOTE)
s('cpDeleteTitle', 'Xoá {task}?', 'Delete {task}?', 'Cùng Chăm Con delete confirm title.' + NOTE, task='String')
s('cpDeleteToday', 'Chỉ xoá hôm nay', 'Delete today only',
  'Cùng Chăm Con delete confirm, an everyday task: keep it for the days to come.' + NOTE)
s('cpDeleteEveryDay', 'Xoá cả những ngày sau', 'Delete from every day',
  'Cùng Chăm Con delete confirm, an everyday task: also stop it from now on.' + NOTE)
s('cpDeleteBody', 'Việc đã ghi trong nhật ký chăm sóc vẫn giữ nguyên.', 'Anything logged in care stays as it is.',
  'Cùng Chăm Con delete confirm body: deleting a plan task never deletes a care record (D-135).' + NOTE)
s('cpDeletedToast', 'Đã xoá · {task}', 'Deleted · {task}', 'Cùng Chăm Con toast after delete.' + NOTE, task='String')
s('cpSuggested', 'Hay dùng', 'Common', 'Cùng Chăm Con 06: tasks suggested for the child\'s age first.' + NOTE)
s('cpMoreTasks', 'Việc khác', 'More', 'Cùng Chăm Con 06: the rest of the tasks.' + NOTE)

# Task names (06 picker and task cards)
for key, vi, en in [
    ('cpTaskBottle', 'Bú bình', 'Bottle'),
    ('cpTaskBreast', 'Bú mẹ', 'Breastfeed'),
    ('cpTaskPump', 'Hút sữa', 'Pump'),
    ('cpTaskSolids', 'Ăn dặm', 'Solids'),
    ('cpTaskWater', 'Uống nước', 'Water'),
    ('cpTaskSleep', 'Ngủ', 'Sleep'),
    ('cpTaskDiaper', 'Thay tã', 'Diaper'),
    ('cpTaskBath', 'Tắm', 'Bath'),
    ('cpTaskTummy', 'Nằm sấp', 'Tummy time'),
    ('cpTaskRead', 'Đọc sách', 'Reading'),
    ('cpTaskWalk', 'Đi dạo', 'Walk'),
    ('cpTaskVitamin', 'Vitamin', 'Vitamin'),
    ('cpTaskMedicine', 'Uống thuốc', 'Medicine'),
    ('cpTaskTemperature', 'Đo nhiệt độ', 'Check temp'),
    ('cpTaskTeeth', 'Đánh răng', 'Brush teeth'),
    ('cpTaskPotty', 'Ngồi bô', 'Potty'),
    ('cpTaskCustom', 'Việc riêng', 'Your own task'),
]:
    s(key, vi, en, 'Cùng Chăm Con task name.' + NOTE)

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
