# "Nhập mã mời" for people who already have a baby profile (owner, 2026-10-11): Hồ sơ bé and the
# baby picker open 15 Nhập mã mời. Vietnamese = source, English = engineering draft (D-012).
# Idempotent. Usage: python3 tool/join_code_strings.py
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc):
    S[key] = (vi, en, desc)

s('joinFromProfile', 'Nhập mã mời', 'Enter an invite code', 'Hồ sơ bé / Chọn bé row opening 15 Nhập mã mời.')
s('joinFromProfileHint', 'Được mời chăm một bé khác? Nhập mã 6 số trong lời mời.', 'Invited to care for another baby? Enter the 6-digit code from the invite.', 'Under the row.')

root = pathlib.Path(__file__).resolve().parent.parent / 'lib' / 'l10n'
for locale, idx in (('vi', 0), ('en', 1)):
    path = root / f'app_{locale}.arb'
    data = json.loads(path.read_text(), object_pairs_hook=collections.OrderedDict)
    for key, (vi, en, desc) in S.items():
        meta = data.get('@' + key)
        if locale == 'vi' and key in data and (meta or {}).get('description') != desc:
            raise SystemExit(f'{key} already exists for something else: pick another id')
        data[key] = (vi, en)[idx]
        if locale == 'vi':
            data['@' + key] = collections.OrderedDict(description=desc)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
print(len(S), 'strings')
