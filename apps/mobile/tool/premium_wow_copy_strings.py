# Sprint Premium F6 (owner, 2026-10-30; docs/audits/2026-10-29-lumi-ca-nhan-hoa-nhip.md R1 / F6): the
# Premium cards sell what Premium now adds, not what Hôm nay already shows free. The demo stays the
# Figma one (vi is an exported image); the title says a log takes one sentence (L8, D-140); "Hiểu nhịp con" names "Sắp tới" (W1) and "Chuẩn bị đi khám" (U1).
# Sets values of existing keys only. Vietnamese is the source; English is an engineering draft for
# owner review (D-012). Idempotent. Usage: python3 tool/premium_wow_copy_strings.py && flutter gen-l10n
import json, collections, pathlib

SET = collections.OrderedDict()
SET['pv2CardLumiTitle'] = ('Nói một câu, Lumi ghi giúp', 'Say it once, Lumi logs it')
SET['pv2CardLumiBody'] = ('Ghi cữ bú, giấc ngủ bằng lời, hỏi lại nhật ký bất cứ lúc nào.',
                          'Log feeds and sleep in your own words, and ask about the log any time.')
SET['pv2CardRhythmTitle'] = ('Biết trước cữ bú, giấc ngủ', 'Know the next feed and nap')
SET['pv2CardRhythmBody'] = ('Theo nhịp riêng của con, kèm bản tóm tắt mang đi khám.',
                            'From your baby’s own rhythm, with a summary to take to the doctor.')

root = pathlib.Path(__file__).resolve().parent.parent / 'lib' / 'l10n'
for locale, idx in (('vi', 0), ('en', 1)):
    path = root / f'app_{locale}.arb'
    data = json.loads(path.read_text(), object_pairs_hook=collections.OrderedDict)
    for key, values in SET.items():
        assert key in data, key
        data[key] = values[idx]
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
print(len(SET), 'strings')
