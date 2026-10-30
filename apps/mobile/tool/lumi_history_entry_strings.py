"""L4 (lumi-plan §7): the Lumi entry above Lịch sử chăm sóc's timeline. Run from apps/mobile."""
VI = '''  "asHistoryAsk": "Hỏi Lumi: “hôm nay bé bú mấy cữ?”",
  "@asHistoryAsk": {
    "description": "One-line Lumi entry above the Lịch sử chăm sóc timeline (L4, lumi-plan §7): opens Lumi for this baby with an empty composer; the quoted words are an example of what to type. EN is an engineering draft for owner review."
  },
'''
EN = '''  "asHistoryAsk": "Ask Lumi: “How many feeds today?”",
'''
for path, block, anchor in [
    ('lib/l10n/app_vi.arb', VI, '  "asModuleExpenseTitle": '),
    ('lib/l10n/app_en.arb', EN, '  "asModuleExpenseTitle": '),
]:
    s = open(path, encoding='utf-8').read()
    if '"asHistoryAsk"' in s:
        continue
    assert s.count(anchor) == 1, path
    s = s.replace(anchor, block + anchor)
    open(path, 'w', encoding='utf-8').write(s)
