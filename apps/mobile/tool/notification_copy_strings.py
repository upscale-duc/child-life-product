# Local notification copy, friendlier (owner, 2026-10-30: "thân thiện ko được cộc lốc"). Server
# pushes live in packages/contracts/src/notification-platform.ts. Vietnamese is the source; English
# is an engineering draft for owner review (D-012). Idempotent: sets values of existing keys and
# adds rhWeekNotifTitle (rhWeekTitle stays the Tuần screen title).
# Usage: python3 tool/notification_copy_strings.py && flutter gen-l10n
import json, collections, pathlib

SET = collections.OrderedDict()
SET['rhEveningBody'] = ('Nếu có điều gì mới, bạn ghi lại vài giây thôi nhé. Không có gì cũng không sao đâu.',
                        'If something’s new, jot it down in a few seconds. Nothing new is fine too.')
SET['pv2TryNowTitle'] = ('Đến giờ thử cùng bé rồi', 'Time to try it with your baby')
SET['pv2TryAskTitle'] = ('Bạn đã thử cùng bé chưa?', 'Did you get to try it?')
SET['pv2TryAskBody'] = ('{title}. Bé thấy thế nào? Chạm để kể lại nhé.',
                        '{title}. How did your baby find it? Tap to tell us.')
SET['wcBody'] = ('Bé đã ngủ {duration}. Nếu bé dậy rồi, chạm để ghi giờ dậy nhé.',
                 'Asleep for {duration}. If your baby’s awake, tap to log the wake time.')
SET['rhWeekNotifBody'] = ('Cùng xem lại những gì cả nhà đã ghi trong tuần nhé.',
                          'Look back at what the family logged this week.')
SET['pv2DigestBody'] = ('Có gợi ý mới cho bé và việc cả nhà đã đặt, xem khi bạn tiện nhé.',
                        'A fresh idea for your baby and the family’s reminders, whenever suits you.')

NEW = collections.OrderedDict()
NEW['rhWeekNotifTitle'] = ('Tuần này của bé thế nào?', 'How was your baby’s week?',
                           'Title of the weekly summary local notification (the Tuần screen keeps rhWeekTitle).')

root = pathlib.Path(__file__).resolve().parent.parent / 'lib' / 'l10n'
for locale, idx in (('vi', 0), ('en', 1)):
    path = root / f'app_{locale}.arb'
    data = json.loads(path.read_text(), object_pairs_hook=collections.OrderedDict)
    for key, pair in SET.items():
        if key not in data:
            raise SystemExit(f'{key} is missing')
        data[key] = pair[idx]
    for key, (vi, en, desc) in NEW.items():
        meta = data.get('@' + key)
        if locale == 'vi' and key in data and (meta or {}).get('description') != desc:
            raise SystemExit(f'{key} already exists for something else: pick another id')
        data[key] = (vi, en)[idx]
        if locale == 'vi':
            data['@' + key] = collections.OrderedDict(description=desc)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
print(len(SET) + len(NEW), 'strings')
