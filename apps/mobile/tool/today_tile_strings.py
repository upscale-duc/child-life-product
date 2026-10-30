# Hôm nay care tiles (owner, 2026-10-30: "mấy cái card bỏ text là ai ghi đi. và ở bú bình cần hiển
# thị thêm giờ cuối cùng đã bú"). Vietnamese is the source; English is an engineering draft for
# owner review (D-012). Idempotent. Usage: python3 tool/today_tile_strings.py && flutter gen-l10n
import json, collections, pathlib

S = collections.OrderedDict()
S['careAtTime'] = ('Lúc {time}', 'At {time}',
                  'Hôm nay Bú bình tile, the line under "45 phút trước": the clock time of the last feed. EN is an engineering draft for owner review.',
                  {'time': 'String'})

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
            data['@' + key] = collections.OrderedDict(description=desc, placeholders={k: {'type': v} for k, v in ph.items()})
    data.pop('careAgoAt', None)
    data.pop('@careAgoAt', None)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
print(len(S), 'strings')
