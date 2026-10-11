# v1.0 improvement · 22 Ghi bú bình · gợi ý nhanh (346:47151): last amount prefilled, quick picks
# by age. Vietnamese = Figma, English = engineering draft (D-012). Idempotent.
# Usage: python3 tool/v1i_bottle_strings.py
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

s('amountFromLast', 'Lượng sữa · đã điền theo lần trước', 'Amount · filled in from last time', '22 field label when prefilled.')
s('lastBottleAt', 'Lần trước {ml} ml · {time}', 'Last time {ml} ml · {time}', '22 caption.', ml='int', time='String')
s('bottleSuggestFor', 'Gợi ý cho bé {age}', 'Suggested for {age}', '22 caption; age like "3 tuần".', age='String')
s('bottleSuggestNewborn', 'Gợi ý cho bé sơ sinh', 'Suggested for a newborn', '22 caption, first week.')
s('bottleQuickPick', '{ml} ml', '{ml} ml', '22 quick-pick chip (a11y).', ml='int')

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
