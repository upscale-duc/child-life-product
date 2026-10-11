# G-081 Tôi → Ngôn ngữ (D-012 in-app override): the row and its sheet. Not drawn in Figma; built
# from OptionRow. Language names are written in their own language in both catalogs.
# Idempotent. Usage: python3 tool/g081_language_strings.py
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

s('meLanguage', 'Ngôn ngữ', 'Language', 'Tôi row and sheet title (G-081).')
s('meLanguageDevice', 'Theo máy', 'Same as phone', 'Follow the phone language.')
s('meLanguageDeviceNow', 'Đang dùng {name}', 'Now {name}', 'Subtitle: the language the phone gives.', name='String')
s('meLanguageVi', 'Tiếng Việt', 'Tiếng Việt', 'Endonym, same in every language.')
s('meLanguageEn', 'English', 'English', 'Endonym, same in every language.')
s('meLanguageHint', 'Đổi ngay cho cả app, widget và thông báo trên máy này.', 'Changes the whole app, widgets and notices on this phone right away.', 'Sheet footnote.')

root = pathlib.Path(__file__).resolve().parent.parent / 'lib' / 'l10n'
for locale, idx in (('vi', 0), ('en', 1)):
    path = root / f'app_{locale}.arb'
    data = json.loads(path.read_text(), object_pairs_hook=collections.OrderedDict)
    for key, (vi, en, desc, ph) in S.items():
        # Never take over another screen's key (whoTitle once clobbered 10a's title).
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
