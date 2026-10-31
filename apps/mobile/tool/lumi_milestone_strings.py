"""L5 (Mốc): the buttons on Lumi's "bé biết lẫy rồi" milestone offer. Run from apps/mobile."""
VI = '''  "asRecordMilestone": "Ghi nhận mốc",
  "@asRecordMilestone": {
    "description": "Button on Lumi's offer under a new skill that is a reference milestone (\\"bé biết lẫy rồi\\"): opens the milestone's page with its record sheet on the day said; saved there. L5 lumi-plan. EN is an engineering draft for owner review."
  },
  "asViewMilestone": "Xem mốc",
  "@asViewMilestone": {
    "description": "Button on Lumi's note that the milestone said is already recorded: opens its page. L5 lumi-plan. EN is an engineering draft for owner review."
  },
'''
EN = '''  "asRecordMilestone": "Record milestone",
  "asViewMilestone": "View milestone",
'''
for path, block, anchor in [
    ('lib/l10n/app_vi.arb', VI, '  "asOpenVaccines": '),
    ('lib/l10n/app_en.arb', EN, '  "asOpenVaccines": '),
]:
    s = open(path, encoding='utf-8').read()
    if '"asRecordMilestone"' in s:
        continue
    assert s.count(anchor) == 1, path
    s = s.replace(anchor, block + anchor)
    open(path, 'w', encoding='utf-8').write(s)
