# D-108 (owner, 2026-10-25): Hôm nay (Adaptive) Version A — the greeting when the baby has no
# nickname yet, so it never reads "Chào buổi chiều, " with a dangling comma, and the label of
# the care tile skeletons while records load. Vietnamese is the
# source; English is an engineering draft for owner review (D-012).
# Idempotent. Usage: python3 tool/d108_today_strings.py && flutter gen-l10n
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

NOTE = ' D-108, nameless twin of the AX10/AX11 greeting. EN is an engineering draft for owner review.'

s('axGreetMorningNoName', 'Chào buổi sáng ☀️', 'Good morning ☀️', 'Hôm nay greeting before noon when the baby has no nickname.' + NOTE)
s('axGreetAfternoonNoName', 'Chào buổi chiều', 'Good afternoon', 'Hôm nay greeting 12:00–18:00 when the baby has no nickname.' + NOTE)
s('axGreetEveningNoName', 'Chào buổi tối 🌙', 'Good evening 🌙', 'Hôm nay greeting after 18:00 when the baby has no nickname.' + NOTE)
s('axTilesLoading', 'Đang tải nhịp hôm nay', "Loading today's rhythm", 'Screen-reader label of the care tile skeletons on Hôm nay while records load. D-108. EN is an engineering draft for owner review.')

root = pathlib.Path(__file__).resolve().parent.parent / 'lib' / 'l10n'
for locale, idx in (('vi', 0), ('en', 1)):
    path = root / f'app_{locale}.arb'
    data = json.loads(path.read_text(), object_pairs_hook=collections.OrderedDict)
    for key, (vi, en, desc, ph) in S.items():
        # Never take over another screen's key.
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
