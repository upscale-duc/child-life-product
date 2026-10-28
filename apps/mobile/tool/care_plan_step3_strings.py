# Cùng Chăm Con, step 3 (D-135; ANALYSIS-2026-10-28 §3, §4): the helper's Hôm nay on a shift
# (Figma 16), the handover to both parents (17) with the shift totals, the tasks left and the
# helper's message, and receipts for the family. Vietnamese is the source; English is an
# engineering draft for owner review (D-012). Idempotent.
# Usage: python3 tool/care_plan_step3_strings.py && flutter gen-l10n
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

NOTE = ' EN is an engineering draft for owner review.'

# Helper's Hôm nay (16)
s('cpShiftHello', 'Chào {name}', 'Hi, {name}',
  'Helper\'s Hôm nay on a shift: the short greeting (their own name as the family calls them).' + NOTE, name='String')
s('cpShiftLeft', '{count, plural, other{Còn {count} việc trong ca}}',
  '{count, plural, =1{1 task left in your shift} other{{count} tasks left in your shift}}',
  'Helper\'s shift card: open tasks of theirs today.' + NOTE, count='int')
s('cpShiftAllDone', 'Xong hết việc trong ca', 'Everything in your shift is done',
  'Helper\'s shift card when all their tasks today are done or skipped.' + NOTE)
s('cpShiftStart', 'Bắt đầu ca', 'Start shift',
  'Helper\'s shift card: say they are now caring for the baby (the family sees "Cô Lan đang trông").' + NOTE)
s('cpShiftOnSince', 'Đang trông từ {time}', 'Caring since {time}',
  'Helper\'s shift card while on duty.' + NOTE, time='String')
s('cpMyTasks', 'Việc của tôi', 'My tasks',
  'Helper\'s Hôm nay: their Cùng Chăm Con tasks today.' + NOTE)
s('cpNotesTitle', 'Ghi chú cho bố mẹ', 'Notes for the parents',
  'Helper\'s Hôm nay: quick notes kept on this phone during the shift, filled into the handover message.' + NOTE)
s('cpNoteAteWell', 'Ăn ngon', 'Ate well', 'Helper note tag.' + NOTE)
s('cpNoteFussy', 'Quấy nhẹ', 'A bit fussy', 'Helper note tag.' + NOTE)
s('cpNoteSleptWell', 'Ngủ sâu', 'Slept well', 'Helper note tag.' + NOTE)
s('cpNoteSmiles', 'Cười nhiều', 'Lots of smiles', 'Helper note tag.' + NOTE)
s('cpNoteMore', 'Viết thêm…', 'Add a note…',
  'Helper notes: placeholder of the free text field.' + NOTE)
s('cpHandoverToParents', 'Bàn giao cho bố mẹ', 'Hand over to the parents',
  'Helper\'s Hôm nay: opens Bàn giao to send it to both parents.' + NOTE)

# Bàn giao (17)
s('hoToParents', 'Bàn giao cho {names}', 'Handover for {names}',
  'Bàn giao, a helper sending: who receives it (both parents, D-135 Q1).' + NOTE, names='String')
s('hoShiftEnds', 'Hết ca {time}', 'Shift ends {time}',
  'Bàn giao, a helper sending: the time of their last task today.' + NOTE, time='String')
s('hoInShift', 'Trong ca', 'This shift',
  'Bàn giao: totals since the helper started their shift.' + NOTE)
s('hoShiftFeeds', '{count, plural, other{{count} cữ}}', '{count, plural, =1{1 feed} other{{count} feeds}}',
  'Bàn giao "Trong ca": feeds (bottle and breast).' + NOTE, count='int')
s('hoShiftDiapers', '{count, plural, other{{count} lần}}', '{count, plural, =1{1 change} other{{count} changes}}',
  'Bàn giao "Trong ca": diaper changes.' + NOTE, count='int')
s('hoShiftDirty', '{count, plural, other{đi ngoài {count}}}', '{count, plural, =1{1 dirty} other{{count} dirty}}',
  'Bàn giao "Trong ca": dirty diapers among them.' + NOTE, count='int')
s('hoShiftFeedLabel', 'Bú', 'Feeds', 'Bàn giao "Trong ca" tile label.' + NOTE)
s('hoShiftSleepLabel', 'Ngủ', 'Sleep', 'Bàn giao "Trong ca" tile label.' + NOTE)
s('hoShiftDiaperLabel', 'Tã', 'Diapers', 'Bàn giao "Trong ca" tile label.' + NOTE)
s('cpRemainingTitle', 'Việc còn lại hôm nay', 'Still to do today',
  'Bàn giao: the day\'s open Cùng Chăm Con tasks.' + NOTE)
s('hoMessage', 'Lời nhắn', 'Message',
  'Bàn giao: the helper\'s words for the parents (from their shift notes, editable).' + NOTE)
s('hoMessageAdd', 'Viết lời nhắn', 'Write a message',
  'Bàn giao: no message yet, write one.' + NOTE)
s('hoSendToParents', 'Gửi cho bố mẹ', 'Send to the parents',
  'Bàn giao, a helper: send it to both parents at once.' + NOTE)
s('hoSentToFamily', '{name} gửi cho cả nhà · {time}', '{name} sent this to the family · {time}',
  'Bàn giao, a parent reading a helper\'s handover: who sent it, when.' + NOTE, name='String', time='String')

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
