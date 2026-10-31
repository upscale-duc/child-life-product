# D-154 Q5 (owner, 2026-10-31): a child older than the published Nhịp pack gets one plain line
# saying ideas stop at that age, instead of "nothing fits today" or a Premium invite. Vietnamese =
# owner tone, English = engineering draft (D-012). Idempotent. Usage: python3 tool/pv2_age_strings.py
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

s('pv2IdeasUpToAge', 'Hiện mới có gợi ý cho con đến {years} tuổi.', 'Ideas are only available up to age {years} for now.', 'D-154 Q5: Hôm nay card and Hôm nay của nhà mình when the child is older than every published idea (the pack ends at {years} years). Cross-age wording (D-143).', years='int')

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
