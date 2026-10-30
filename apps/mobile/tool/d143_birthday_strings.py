# D-143 (3, owner 2026-10-30): a birthday occasion every year from 2 to 12 years, next to the
# first birthday, in Thiệp cột mốc and Video kỷ niệm (keepsake_occasions.dart).
# Vietnamese is the source; English is an engineering draft for owner review (D-012).
# Idempotent. Usage: python3 tool/d143_birthday_strings.py && flutter gen-l10n
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

NOTE = ' EN is an engineering draft for owner review.'

s('ksOccBirthday', 'Sinh nhật {years} tuổi',
  'Turning {years}',
  'MM10 "Chọn dịp" chip for a birthday from 2 to 12 years (D-143); {years} is the age turned (en "Turning {years}": Flutter plurals have no ordinal forms).' + NOTE,
  years='int')
s('ksTitleYears', '{years} tuổi', '{years} years',
  'The big words on a birthday card from 2 to 12 years (like ksTitleY1 "1 tuổi"); {years} is the age turned.' + NOTE,
  years='int')
s('ksQuoteBirthday', 'Thêm một tuổi, thêm bao điều để nhớ', 'Another year, so much to remember',
  'Default "Lời nhắn" on a birthday card from 2 to 12 years (D-143).' + NOTE)

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
