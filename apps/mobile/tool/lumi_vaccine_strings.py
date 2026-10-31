"""L5 (vaccines): the buttons on Lumi's "bé vừa tiêm 6in1 mũi 2" reply. Run from apps/mobile."""
VI = '''  "asOpenVaccines": "Mở Sổ tiêm chủng",
  "@asOpenVaccines": {
    "description": "Button on Lumi's reply about a shot when no single dose can be opened (no vaccine named, the series already complete, a dose the schedule lacks): opens the vaccination book. L5 lumi-plan. EN is an engineering draft for owner review."
  },
  "asViewDose": "Xem mũi tiêm",
  "@asViewDose": {
    "description": "Button on Lumi's reply when the dose said is already recorded in the vaccination book: opens that dose's page. L5 lumi-plan. EN is an engineering draft for owner review."
  },
'''
EN = '''  "asOpenVaccines": "Open vaccination book",
  "asViewDose": "View shot",
'''
for path, block, anchor in [
    ('lib/l10n/app_vi.arb', VI, '  "asSetRule": '),
    ('lib/l10n/app_en.arb', EN, '  "asSetRule": '),
]:
    s = open(path, encoding='utf-8').read()
    if '"asOpenVaccines"' in s:
        continue
    assert s.count(anchor) == 1, path
    s = s.replace(anchor, block + anchor)
    open(path, 'w', encoding='utf-8').write(s)
