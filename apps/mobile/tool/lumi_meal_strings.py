"""L5 (lumi-plan §5): Lumi meals in the Ăn dặm diary. Run from apps/mobile."""
VI = '''  "asEditMeal": "Sửa bữa ăn",
  "@asEditMeal": {
    "description": "Title of Lumi's draft editor for a solids meal (L5): the dish and its time, saved to the Ăn dặm diary. EN is an engineering draft for owner review."
  },
  "asHistoryAskMeal": "Kể bữa ăn với Lumi: “trưa nay ăn cháo bí đỏ”",
  "@asHistoryAskMeal": {
    "description": "One-line Lumi entry on the Ăn dặm diary (L4/L5, lumi-plan §7): opens Lumi with the meal hint; the quoted words are an example of what to type. EN is an engineering draft for owner review."
  },
'''
EN = '''  "asEditMeal": "Edit meal",
  "asHistoryAskMeal": "Tell Lumi about a meal: “Pumpkin porridge at lunch”",
'''
for path, block, anchor in [
    ('lib/l10n/app_vi.arb', VI, '  "asEditGrowth": '),
    ('lib/l10n/app_en.arb', EN, '  "asEditGrowth": '),
]:
    s = open(path, encoding='utf-8').read()
    if '"asEditMeal"' in s:
        continue
    assert s.count(anchor) == 1, path
    s = s.replace(anchor, block + anchor)
    open(path, 'w', encoding='utf-8').write(s)
