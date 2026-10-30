"""D-147: Premium invites where a Premium part used to be hidden for Free. Run from apps/mobile."""
VI = '''  "pmInPremium": "Có trong Premium",
  "@pmInPremium": {
    "description": "D-147: the line under a Premium part shown to a Free household as an invite (Hôm nay \\"Sắp tới\\", Chăm sóc \\"Chuẩn bị đi khám\\"); a tap opens Premium. EN is an engineering draft for owner review."
  },
  "cuInvite": "Nhật ký của {name} đã đủ để biết trước khoảng giờ cữ bú và giấc ngủ tiếp theo.",
  "@cuInvite": {
    "description": "Hôm nay \\"Sắp tới\\" for a Free household (D-147): shown only when this baby's log already allows the ranges; the times themselves are Premium. {name} is the baby. No health claim. EN is an engineering draft for owner review.",
    "placeholders": {
      "name": {
        "type": "String"
      }
    }
  },
'''
EN = '''  "pmInPremium": "Included in Premium",
  "cuInvite": "{name}’s log is already enough to know roughly when the next feed and sleep will be.",
'''
for path, block, anchor in [
    ('lib/l10n/app_vi.arb', VI, '  "cuBasis": '),
    ('lib/l10n/app_en.arb', EN, '  "cuBasis": '),
]:
    s = open(path, encoding='utf-8').read()
    # Re-runnable: drop an earlier run's block before inserting this one.
    if '"cuInvite"' in s:
        start = s.index('  "pmInPremium"') if '"pmInPremium"' in s else s.index('  "cuInvite"')
        s = s[:start] + s[s.index(anchor):]
    assert s.count(anchor) == 1, path
    s = s.replace(anchor, block + anchor)
    open(path, 'w', encoding='utf-8').write(s)
