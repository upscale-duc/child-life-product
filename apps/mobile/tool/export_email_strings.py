# Exports download from the email link only (owner, 2026-10-12): the Tài khoản row says the link was
# emailed. Vietnamese = source, English = engineering draft (D-012). Idempotent.
# Usage: python3 tool/export_email_strings.py
import json, collections, pathlib

S = {
    'acExportEmailed': (
        'Đã gửi link tải qua email · hết hạn {when}',
        'Download link emailed · expires {when}',
        'Tài khoản → Xuất dữ liệu row once the file is ready (download only from the email).',
        {'when': 'String'},
    ),
}

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
            m['placeholders'] = {k: {'type': v} for k, v in ph.items()}
            data['@' + key] = m
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
print(len(S), 'strings')
