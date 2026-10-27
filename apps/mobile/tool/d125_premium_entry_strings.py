# D-125 (owner, 2026-10-26: "bất kì entry point nào cần premium thì cần giới thiệu premium trước cho
# chức năng đó chứ ko dc ấn vào lại show premium một cách bất ngờ"): entries that open Premium say
# so on the label. Vietnamese is the source; English is an engineering draft for owner review.
# Idempotent; rewrites the values it owns. Usage: python3 tool/d125_premium_entry_strings.py && flutter gen-l10n
import json, collections, pathlib

S = {
    'asUpgradeContinue': ('Xem Premium để hỏi tiếp', 'See Premium to keep asking'),
    'asOutBodyFree': ('Câu hỏi của bạn được giữ lại. Premium có thêm lượt Lumi mỗi tháng; bạn vẫn ghi trực tiếp và xem nhật ký như thường.',
                      'Your question is kept. Premium adds monthly Lumi credits; you can still log directly and view logs as usual.'),
    'pv2SeePlans': ('Xem Premium', 'See Premium'),
    # The glossary's term is "Premium" in both languages; the template badge said "Cao cấp".
    'ksPremium': ('Premium', 'Premium'),
}
root = pathlib.Path(__file__).resolve().parent.parent / 'lib' / 'l10n'
for locale, idx in (('vi', 0), ('en', 1)):
    path = root / f'app_{locale}.arb'
    data = json.loads(path.read_text(), object_pairs_hook=collections.OrderedDict)
    for key, vals in S.items():
        if key not in data:
            raise SystemExit(f'{key} is missing')
        data[key] = vals[idx]
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
print(len(S), 'strings')
