# Cùng Chăm Con rebuilt to the Figma section 1349:22026 (D-137: this feature matches its frames).
# Vietnamese is the Figma copy; English is an engineering draft for owner review (D-012).
# Idempotent. Usage: python3 tool/care_plan_figma_strings.py && flutter gen-l10n
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

NOTE = ' EN is an engineering draft for owner review.'

# 04 / 04b summary card
s('cpTodayCount', '{count, plural, other{Hôm nay có {count} việc}}', '{count, plural, =1{1 task today} other{{count} tasks today}}',
  'Cùng Chăm Con 04: the day card before anything is done (Figma 1380:21966).' + NOTE, count='int')
s('cpFirstTask', 'Việc đầu tiên {time} · {task}', 'First up {time} · {task}',
  'Cùng Chăm Con 04: the first task of the day.' + NOTE, time='String', task='String')
s('cpPersonCount', '{name} · {count}', '{name} · {count}',
  'Cùng Chăm Con 04: a person and how many tasks they have today.', name='String', count='int')
s('cpPersonDone', '{name} xong {count}', '{name} did {count}',
  'Cùng Chăm Con 04b: thanks a person for the tasks they did (only people who did some).' + NOTE, name='String', count='int')
s('cpLeftCheer', '{count, plural, other{Còn {count} việc nữa thôi, cả nhà cố lên!}}', '{count, plural, =1{Just 1 more to go, you\'ve got this!} other{Just {count} more to go, you\'ve got this!}}',
  'Cùng Chăm Con 04b: encouragement once something is done (Figma 1380:22470).' + NOTE, count='int')
# 04-0 Chưa có lịch hôm nay
s('cpStartSub', 'Tạo nhanh trong 1 chạm, sửa sau cũng được', 'One tap to start, change it any time',
  'Cùng Chăm Con 04-0: under "Hôm nay chưa có lịch" (Figma 1390:21780).' + NOTE)
s('cpStartRhythmOf', 'Theo nhịp {name}', 'Follow {name}\'s rhythm',
  'Cùng Chăm Con 01 / 04-0: the rhythm draft with the baby\'s name.' + NOTE, name='String')
s('cpChosen', 'Đã chọn', 'Your pick', 'Cùng Chăm Con 04-0: badge on the way the family chose before.' + NOTE)
s('cpChosenSub', 'Cách cả nhà chọn lúc đầu', 'The way your family chose',
  'Cùng Chăm Con 04-0: under the remembered way.' + NOTE)
s('cpCreateToday', 'Tạo lịch hôm nay', 'Make today\'s plan', 'Cùng Chăm Con 04-0: primary action.' + NOTE)
s('cpCreateDay', 'Tạo lịch', 'Make the plan', 'Cùng Chăm Con 04-0 / 01c: primary action for another day, or Tự tạo.' + NOTE)

# 01 Chọn cách lên lịch
s('cpChooseTitle', 'Lên lịch cho {name}', 'Plan the day for {name}',
  'Cùng Chăm Con 01: the page title (Figma 1377:21908).' + NOTE, name='String')
s('cpSuggestBadge', 'Gợi ý', 'Suggested', 'Cùng Chăm Con 01: badge on "Theo nhịp" (the family\'s own rhythm).' + NOTE)
s('cpRhythmFrom', 'Từ 7 ngày ghi nhận', 'From the last 7 days logged',
  'Cùng Chăm Con 01: under "Theo nhịp" (D-136 #2: 7 of 7 days).' + NOTE)
s('cpEasySection', 'Theo EASY', 'EASY routines', 'Cùng Chăm Con 01: the EASY templates section.' + NOTE)
s('cpEasy35Sub', '6 tuần – 4 tháng · 3–4 giấc', '6 weeks – 4 months · 3–4 naps',
  'Cùng Chăm Con 01: who EASY 3.5 is for (docs/design/explorations/cung-cham-con/templates-draft.md).' + NOTE)
s('cpEasy4Sub', '4 – 6 tháng · 3 giấc', '4 – 6 months · 3 naps',
  'Cùng Chăm Con 01: who EASY 4 is for (D-136 #4: EASY only under 6 months).' + NOTE)
s('cpFitsAge', 'Hợp tuổi', 'Fits the age', 'Cùng Chăm Con 01: badge on the EASY that fits the baby\'s age.' + NOTE)
s('cpOtherSection', 'Khác', 'Other ways', 'Cùng Chăm Con 01: the other ways to start the day.' + NOTE)
s('cpByAge', 'Theo tuổi', 'By age', 'Cùng Chăm Con 01: the age-based template (basic).' + NOTE)
s('cpByAgeSub', 'Nếp chuẩn cho bé {age}', 'A usual day at {age}',
  'Cùng Chăm Con 01: under "Theo tuổi"; age is "4 tháng" / "2 tuổi".' + NOTE, age='String')
s('cpSelfMade', 'Tự tạo', 'Make your own', 'Cùng Chăm Con 01: start with no tasks and add them.' + NOTE)
s('cpSelfMadeSub', 'Tự đặt giờ và việc', 'Set your own times and tasks', 'Cùng Chăm Con 01: under "Tự tạo".' + NOTE)
s('cpPreview', 'Xem trước lịch', 'Preview the plan',
  'Cùng Chăm Con 01: primary action for a way that makes a draft to check first.' + NOTE)

# 02 Gợi ý cho Teddy (a draft day)
s('cpTodayPlan', 'Lịch hôm nay', 'Today\'s plan', 'Cùng Chăm Con 02: the bar title on a draft day (Figma 1388:21646).' + NOTE)
s('cpDraftHeading', 'Gợi ý cho {name}', 'Suggested for {name}',
  'Cùng Chăm Con 02: a drafted day, before anyone uses it (D-136).' + NOTE, name='String')
s('cpDraftFromRhythm', 'Theo nhịp 7 ngày qua', 'From the last 7 days',
  'Cùng Chăm Con 02: the draft came from the baby\'s own rhythm.' + NOTE)
s('cpDraftFrom', 'Theo {way}', 'From {way}',
  'Cùng Chăm Con 02: the draft came from a template ("Theo EASY 4", "Theo tuổi").' + NOTE, way='String')
s('cpChangeShort', 'Đổi cách', 'Change', 'Cùng Chăm Con 02: pick another way for the draft.' + NOTE)
s('cpDraftNote', 'Giờ chỉ là gợi ý, con vẫn dẫn nhịp', 'Times are a guide; your baby leads',
  'Cùng Chăm Con 02: under the draft, above "Dùng lịch này".' + NOTE)
s('cpTimelineA11y', 'Ngày của bé: {feeds} cữ bú, {sleeps} giấc ngủ', 'The day: {feeds} feeds, {sleeps} sleeps',
  'Cùng Chăm Con 02: what the day strip shows, for screen readers.' + NOTE, feeds='int', sleeps='int')

# 05 Giao việc
s('cpAssignSpan', '{count, plural, other{{count} việc}} · {from} – {to}', '{count, plural, =1{1 task} other{{count} tasks}} · {from} – {to}',
  'Cùng Chăm Con 05: under "Giao ca sáng cho ai?", the part of the day being given (Figma 1381:22083).' + NOTE,
  count='int', **{'from': 'String'}, to='String')
s('cpMemberLine', '{relation} · {load}', '{relation} · {load}',
  'Cùng Chăm Con 05: a person\'s relation and how many tasks they have ("Bà nội · 1 việc hôm nay").',
  relation='String', load='String')
s('cpManyPeople', 'Nhiều người', 'Several people', 'Cùng Chăm Con 05: give the task or the part of the day to more than one person.' + NOTE)
s('cpManyPeopleGroup', 'Chọn người cho từng việc', 'Pick someone for each task',
  'Cùng Chăm Con 05: under "Nhiều người" for a part of the day: closes the sheet so each task is given on its own.' + NOTE)
s('cpManyPeopleTask', 'Cùng làm việc này', 'Do this task together',
  'Cùng Chăm Con 05: under "Nhiều người" for one task: pick several people.' + NOTE)
# 06 Thêm việc
s('cpAddToPlan', 'Thêm vào lịch', 'Add to the plan', 'Cùng Chăm Con 06: primary action (Figma 1381:22208).' + NOTE)
s('cpSearchTask', 'Tìm việc, vd: uống thuốc', 'Find a task, e.g. medicine', 'Cùng Chăm Con 06: search field placeholder.' + NOTE)
s('cpSuggestedFor', 'Hay dùng cho bé {age}', 'Common at {age}',
  'Cùng Chăm Con 06: the tasks a child of this age usually has; age is "4 tháng" / "2 tuổi".' + NOTE, age='String')
s('cpCatFood', 'Ăn uống', 'Food and drink', 'Cùng Chăm Con 06: task group.' + NOTE)
s('cpCatPlay', 'Chơi & vận động', 'Play and movement', 'Cùng Chăm Con 06: task group.' + NOTE)
s('cpCatCare', 'Sức khoẻ & vệ sinh', 'Health and hygiene', 'Cùng Chăm Con 06: task group.' + NOTE)
s('cpCreateOwn', 'Tạo việc riêng', 'Create your own', 'Cùng Chăm Con 06: a task with its own name (dashed chip).' + NOTE)
s('cpNoTaskFound', 'Không có việc nào khớp. Tạo việc riêng nhé.', 'No task matches. Create your own.',
  'Cùng Chăm Con 06: the search found nothing.' + NOTE)
# 06b Sửa / xoá việc
s('cpShiftOf', 'Ca {period}', '{period}', 'Cùng Chăm Con 06b: under the task name ("Ca tối"); period is lower-case Sáng / Chiều / Tối.' + NOTE, period='String')
s('cpDoer', 'Người làm', 'Who', 'Cùng Chăm Con 06b: the row with who does the task (Figma 1360:23266).' + NOTE)
s('cpApply', 'Áp dụng', 'Repeat', 'Cùng Chăm Con 06b: today only or every day.' + NOTE)
s('cpSkipOk', 'Bỏ qua hôm nay cũng được', 'Fine to skip it today', 'Cùng Chăm Con 06b: the gentle skip notice.' + NOTE)
s('cpSkipShort', 'Bỏ qua', 'Skip', 'Cùng Chăm Con 06b: skip today (in the notice).' + NOTE)
s('cpUnskipShort', 'Làm lại', 'Undo skip', 'Cùng Chăm Con 06b: a skipped task is back on today.' + NOTE)
s('cpDeleteShort', 'Xoá', 'Delete', 'Cùng Chăm Con 06b: delete the task (beside Lưu).' + NOTE)

# Existing ids whose Vietnamese copy now follows Figma (English unchanged).
VI = {
    'cpAssignGroup': 'Giao cả ca',
    'cpAssignWhoMorning': 'Giao ca sáng cho ai?',
    'cpAssignWhoAfternoon': 'Giao ca chiều cho ai?',
    'cpAssignWhoEvening': 'Giao ca tối cho ai?',
}

root = pathlib.Path(__file__).resolve().parent.parent / 'lib' / 'l10n'
RENAME = {}
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
    if locale == 'vi':
        for key, vi in VI.items():
            assert key in data, key
            data[key] = vi
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
print(len(S) + len(RENAME), 'strings')
