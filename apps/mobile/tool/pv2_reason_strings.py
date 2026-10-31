# D-154 P3 (owner, 2026-10-31): the reason line under "Ý tưởng hôm nay" when the diary (sleep
# shorter than usual) or the current reference stage picked it. Vietnamese = owner tone, English =
# engineering draft (D-012). Idempotent. Usage: python3 tool/pv2_reason_strings.py
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

s('pv2BecauseDiary', 'Giấc ngủ gần đây ít hơn thường ngày (từ nhật ký)', 'Sleep has been shorter than usual lately (from the diary)', 'D-154 P3: reason line of the idea of the day when the diary picked it (DATA_INSIGHT). A fact from the log, never a cause.')
s('pv2BecauseStage', 'Hợp với giai đoạn tham khảo hiện tại', 'Fits the current reference stage', 'D-154 P3: reason line of the idea of the day when it is linked to the reference stage the baby is in (STAGE).')

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
