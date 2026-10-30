# Sprint wow W1 "Sắp tới" on Hôm nay and L6 "Bé dậy chưa?" (owner, 2026-10-30; lumi-plan §7.1).
# Vietnamese is the source; English is an engineering draft for owner review (D-012).
# Idempotent. Usage: python3 tool/coming_up_strings.py && flutter gen-l10n
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

NOTE = ' EN is an engineering draft for owner review.'

s('cuTitle', 'Sắp tới', 'Coming up',
  'Hôm nay "Sắp tới" card title: what usually comes next, from this baby\'s own log (sprint wow W1).' + NOTE)
s('cuBasis', 'Theo nhật ký {days} ngày gần đây', 'From the last {days} days of the log',
  'Hôm nay "Sắp tới": under the title, the basis of every range (descriptive, never a schedule).' + NOTE, days='int')
s('cuFeed', 'Cữ bú tiếp', 'Next feed', 'Hôm nay "Sắp tới": the next feed line.' + NOTE)
s('cuSleep', 'Giấc ngủ tiếp', 'Next sleep', 'Hôm nay "Sắp tới": the next nap line while the baby is awake.' + NOTE)
s('cuWake', 'Bé dậy', 'Waking', 'Hôm nay "Sắp tới": while a daytime sleep timer runs, when the baby usually wakes.' + NOTE)
s('cuWindow', 'khoảng {from}–{to}', 'about {from}–{to}',
  'Hôm nay "Sắp tới": a usual range as clock times (the middle half of this baby\'s recent intervals).' + NOTE,
  **{'from': 'String', 'to': 'String'})
s('cuAround', 'khoảng {time}', 'about {time}',
  'Hôm nay "Sắp tới": the usual range when both ends round to the same time.' + NOTE, time='String')
s('cuLastFeed', 'Cữ gần nhất {time}', 'Last feed {time}', 'Hôm nay "Sắp tới": what the feed line counts from.' + NOTE, time='String')
s('cuWokeAt', 'Dậy lúc {time}', 'Woke at {time}', 'Hôm nay "Sắp tới": what the next-sleep line counts from.' + NOTE, time='String')
s('cuAsleepSince', 'Ngủ từ {time}', 'Asleep since {time}',
  'Hôm nay "Sắp tới": what the waking line counts from (the running sleep timer).' + NOTE, time='String')

s('wcTitle', 'Bé dậy chưa?', 'Is your baby awake?',
  'L6 local notification title, to the person who started a sleep timer that is still running (lumi-plan §7.1). No baby name on the lock screen (R-120).' + NOTE)
s('wcBody', 'Bé đã ngủ {duration}. Nếu bé dậy rồi, chạm để ghi giờ dậy nhé.', 'Asleep for {duration}. If your baby’s awake, tap to log the wake time.',
  'L6 notification body: words, never a verdict (no "quá lâu", no health language); opens the sleep timer.' + NOTE, duration='String')
s('ntWakeCheck', 'Hỏi khi đếm giấc ngủ còn chạy', 'Ask when a sleep timer is still running',
  'EN07 Cài đặt thông báo: the L6 "Bé dậy chưa?" switch, on by default, this phone only.' + NOTE)
s('ntWakeCheckHint', 'Chỉ trên máy này, không hỏi trong giờ yên lặng', 'Only on this phone, never in quiet hours',
  'EN07: under the L6 switch; the exception to the group\'s "kể cả trong giờ yên lặng" (lumi-plan §7.1).' + NOTE)

s('asNextFeedReminder', 'Nhắc cữ tiếp', 'Remind me next feed',
  'Lumi L4 (lumi-plan §7, sprint wow): on a feed just saved through Lumi, opens the "after the last feed" reminder with this baby\'s usual gap (Cùng nuôi only).' + NOTE)

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
