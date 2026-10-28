# Cùng Chăm Con, step 4 (D-136): how a day's plan is chosen (04-0 with 01 folded in), the draft
# (02 "Dùng lịch này" / "Đổi cách khác") and "Tự tạo lịch mỗi sáng". Vietnamese is the source;
# English is an engineering draft for owner review (D-012). Idempotent.
# Usage: python3 tool/care_plan_step4_strings.py && flutter gen-l10n
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

NOTE = ' EN is an engineering draft for owner review.'

# 04-0 / 01 Chọn cách lên lịch
s('cpStartRhythm', 'Theo nhịp của bé', 'Follow your baby\'s rhythm',
  'Cùng Chăm Con 04-0: a draft from the usual feed and sleep times logged (D-136 #2).' + NOTE)
s('cpStartRhythmSub', 'Bú và ngủ, từ 7 ngày ghi gần đây', 'Feeds and sleep, from the last 7 days logged',
  'Cùng Chăm Con 04-0: what "Theo nhịp của bé" is drafted from.' + NOTE)
s('cpRhythmNotReady', 'Chưa đủ 7 ngày có ghi cả bú và ngủ', 'Not yet 7 days with both feeds and sleep logged',
  'Cùng Chăm Con: toast when the rhythm draft cannot be made (D-136 #2).' + NOTE)
s('cpTemplatesSection', 'Lịch mẫu (chờ duyệt)', 'Sample plans (in review)',
  'Cùng Chăm Con 04-0: the reference templates, shown on dev only until the owner reviews them (D-136 #1).' + NOTE)
s('cpStartBasic', 'Lịch cơ bản theo tuổi', 'Basic plan for your baby\'s age',
  'Cùng Chăm Con 04-0: the age-based template.' + NOTE)
s('cpStartBasicSub', 'Bú, ngủ và vài việc nhẹ nhàng', 'Feeds, sleep and a few gentle routines',
  'Cùng Chăm Con 04-0: what the basic template holds.' + NOTE)
s('cpStartEasy35', 'EASY 3.5', 'EASY 3.5', 'Cùng Chăm Con 04-0: the EASY 3.5 template (a method name, not translated).')
s('cpStartEasy4', 'EASY 4', 'EASY 4', 'Cùng Chăm Con 04-0: the EASY 4 template (a method name, not translated).')
s('cpStartEasySub', 'Khi nhà mình đang theo EASY', 'If your family follows EASY',
  'Cùng Chăm Con 04-0: when an EASY template fits.' + NOTE)
s('cpTemplatesNote', 'Lịch mẫu không phải lịch y tế. Bú và ngủ luôn có thể khác dự kiến.',
  'Sample plans are not medical schedules. Feeds and sleep can always differ from the plan.',
  'Cùng Chăm Con 04-0: under the templates (FLOW §4).' + NOTE)
s('cpChangeTitle', 'Đổi cách lên lịch', 'Choose another way',
  'Cùng Chăm Con: the ways to start the day, in place of a draft.' + NOTE)
s('cpKeepDraft', 'Giữ bản nháp này', 'Keep this draft',
  'Cùng Chăm Con "Đổi cách khác": back to the draft unchanged.' + NOTE)

# 02 the draft
s('cpDraftTitle', 'Bản nháp · chưa nhắc ai', 'Draft · nobody is reminded yet',
  'Cùng Chăm Con: a drafted day, seen by plan managers only (D-136).' + NOTE)
s('cpDraftBody', 'Sửa, thêm hay giao việc tuỳ ý. Dùng lịch này để cả nhà thấy và được nhắc.',
  'Edit, add or assign as you like. Use this plan so everyone sees it and gets reminders.',
  'Cùng Chăm Con: what the draft means and what using it does.' + NOTE)
s('cpDraftUse', 'Dùng lịch này', 'Use this plan', 'Cùng Chăm Con: put the draft in use (the primary action).' + NOTE)
s('cpDraftChange', 'Đổi cách khác', 'Choose another way', 'Cùng Chăm Con: start the draft day another way.' + NOTE)
s('cpDraftUsed', 'Đã dùng lịch hôm nay', 'Today\'s plan is in use',
  'Cùng Chăm Con: toast after "Dùng lịch này".' + NOTE)

# 13, the family's part
s('cpFamilySection', 'Cả nhà', 'Whole family',
  'Cùng Chăm Con settings: the family\'s settings, plan managers only.' + NOTE)
s('cpAutoDraft', 'Tự tạo lịch mỗi sáng', 'Draft a plan every morning',
  'Cùng Chăm Con settings (D-136 #3): off by default.' + NOTE)
s('cpAutoDraftHint', 'Lúc 06:30, theo cách nhà mình lên lịch gần nhất. Bản nháp chỉ được dùng khi có người chọn Dùng lịch này.',
  'At 06:30, the way your family last made a plan. The draft is used only once someone taps Use this plan.',
  'Cùng Chăm Con settings: what the morning draft does.' + NOTE)

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
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
print(len(S) + len(RENAME), 'strings')
