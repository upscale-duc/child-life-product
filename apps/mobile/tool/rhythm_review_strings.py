"""D-148: "Đã duyệt bởi Child Life Team" when the credential repeats the reviewer. Run from apps/mobile."""
VI = '''  "rhReviewedByTeam": "Đã duyệt bởi {reviewer}",
  "@rhReviewedByTeam": {
    "description": "Footnote on reviewed Nhịp content when the credential is the reviewer's own name (D-148: \\"Child Life Team\\"). {reviewer} is the reviewer as stored.",
    "placeholders": {
      "reviewer": {
        "type": "String"
      }
    }
  },
'''
EN = '''  "rhReviewedByTeam": "Reviewed by {reviewer}",
'''
for path, block, anchor in [
    ('lib/l10n/app_vi.arb', VI, '  "rhJoinTwo": '),
    ('lib/l10n/app_en.arb', EN, '  "rhJoinTwo": '),
]:
    s = open(path, encoding='utf-8').read()
    if '"rhReviewedByTeam"' in s:
        continue
    assert s.count(anchor) == 1, path
    s = s.replace(anchor, block + anchor)
    open(path, 'w', encoding='utf-8').write(s)
