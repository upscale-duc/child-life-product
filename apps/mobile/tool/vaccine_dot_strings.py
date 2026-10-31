# Tiêm chủng · Theo vắc xin: every dose shows a date (owner, 2026-10-30: "một số mốc ko show ngày
# ko biết là ngày nào"). A dose ticked without a date says so instead of "—". Vietnamese is the
# source; English is an engineering draft for owner review (D-012). Idempotent.
# Usage: python3 tool/vaccine_dot_strings.py && flutter gen-l10n
import json, collections, pathlib

S = collections.OrderedDict()
S['vxDotAddDate'] = ('Thêm ngày', 'Add date',
                     'Under a ticked dose with no date, for someone who can add it (opens the dose page).', {})
S['vxDotNoDate'] = ('Chưa ghi', 'No date',
                    'Under a ticked dose with no date, for someone who can only look.', {})

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
            m = collections.OrderedDict(description=desc)
            if ph:
                m['placeholders'] = {k: {'type': v} for k, v in ph.items()}
            data['@' + key] = m
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
print(len(S), 'strings')
