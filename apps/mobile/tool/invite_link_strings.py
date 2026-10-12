# One-tap invite links (owner, 2026-10-12): the email's "Nhận lời mời" (AppsFlyer OneLink or
# /i/<token>) joins at once. Vietnamese = owner, English = engineering draft (D-012). Idempotent.
# Usage: python3 tool/invite_link_strings.py
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

s('inviteLinkJoining', 'Đang nhận lời mời…', 'Accepting the invite…', 'While an invite link joins.')
s('inviteLinkJoined', 'Bạn đã cùng chăm {baby}. Đổi tên trong Gia đình.', 'You now care for {baby}. Change your name in Family.', 'Toast after joining from a link.', baby='String')
s('inviteLinkDefaultName', 'Người thân', 'Family member', 'Name given when joining from a link (owner, 2026-10-12).')

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
