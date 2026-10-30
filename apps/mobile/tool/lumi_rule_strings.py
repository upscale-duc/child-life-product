"""L5 (recurring reminders): the button on Lumi's "nhắc … mỗi 3 tiếng" reply. Run from apps/mobile."""
VI = '''  "asSetRule": "Đặt nhắc",
  "@asSetRule": {
    "description": "Button on Lumi's reply to a repeating care reminder (\\"nhắc cữ bú mỗi 3 tiếng\\"): opens the rule editor filled with what was said; nothing is saved until the person saves it there. L5 lumi-plan. EN is an engineering draft for owner review."
  },
'''
EN = '''  "asSetRule": "Set up reminder",
'''
for path, block, anchor in [
    ('lib/l10n/app_vi.arb', VI, '  "asEditMeal": '),
    ('lib/l10n/app_en.arb', EN, '  "asEditMeal": '),
]:
    s = open(path, encoding='utf-8').read()
    if '"asSetRule"' in s:
        continue
    assert s.count(anchor) == 1, path
    s = s.replace(anchor, block + anchor)
    open(path, 'w', encoding='utf-8').write(s)
