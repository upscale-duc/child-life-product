# Split pv2Shared (2026-10-25): Premium v2 (58c7895f, D-101) rewrote the personalization notes key
# for its plan tag, so the notes "share" switch read "the whole family". A shared (scope 'baby')
# note is read only by members with history.read (co-parents, caregivers, relatives with
# "Chăm sóc hằng ngày", D-018; firebase/functions/src/personalization-v2.ts), so the notes keep the
# earlier wording and Premium gets its own key.
# Vietnamese is the source; English is an engineering draft for owner review (D-012).
# Idempotent. Usage: python3 tool/pv2_shared_strings.py && flutter gen-l10n
import json, collections, pathlib

# Existing keys: key -> (vi, en, description).
CHANGED = {
    'pv2Shared': (
        'Chia sẻ với người được xem chăm sóc bé',
        'Share with members allowed to view baby care',
        'Personalization v2 notes editor: switch that makes a note visible to members who can view '
        'the baby\'s care (scope baby); also the scope label of a shared note.',
    ),
}

# New keys: key -> (vi, en, description).
NEW = collections.OrderedDict()
NEW['pv2PlanShared'] = (
    'Cả nhà dùng chung',
    'Shared by the family',
    'Premium v2 (Figma 958:13863, D-101). Plan card tag (member, PV45).',
)

root = pathlib.Path(__file__).resolve().parent.parent / 'lib' / 'l10n'
for locale, idx in (('vi', 0), ('en', 1)):
    path = root / f'app_{locale}.arb'
    data = json.loads(path.read_text(), object_pairs_hook=collections.OrderedDict)
    for key, (vi, en, desc) in CHANGED.items():
        if key not in data:
            raise SystemExit(f'{key} is missing in app_{locale}.arb')
        data[key] = (vi, en)[idx]
        if locale == 'vi':
            data['@' + key] = collections.OrderedDict(description=desc)
    for key, (vi, en, desc) in NEW.items():
        meta = data.get('@' + key)
        if locale == 'vi' and key in data and (meta or {}).get('description') != desc:
            raise SystemExit(f'{key} already exists for something else: pick another id')
        data[key] = (vi, en)[idx]
        if locale == 'vi':
            data['@' + key] = collections.OrderedDict(description=desc)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
print(len(CHANGED), 'changed,', len(NEW), 'new')
