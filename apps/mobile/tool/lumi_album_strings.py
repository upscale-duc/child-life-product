"""L5 (album): the Kỷ niệm row of Lumi's photo sheet. Run from apps/mobile."""
VI = '''  "asPhotoToMemories": "Lưu ảnh của bé vào Kỷ niệm",
  "@asPhotoToMemories": {
    "description": "Row of Lumi's photo sheet, Cùng nuôi only: picks photos and opens Kỷ niệm's own \\"Soạn & chia sẻ\\"; the photo is never sent to Lumi. L5 lumi-plan. EN is an engineering draft for owner review."
  },
  "asPhotoToMemoriesSub": "Không gửi cho Lumi đọc, không tốn lượt",
  "@asPhotoToMemoriesSub": {
    "description": "Under asPhotoToMemories: the photo is not read by Lumi and uses no AI credits. L5 lumi-plan. EN is an engineering draft for owner review."
  },
'''
EN = '''  "asPhotoToMemories": "Save a baby photo to Memories",
  "asPhotoToMemoriesSub": "Not sent to Lumi, uses no credits",
'''
for path, block, anchor in [
    ('lib/l10n/app_vi.arb', VI, '  "asRecordMilestone": '),
    ('lib/l10n/app_en.arb', EN, '  "asRecordMilestone": '),
]:
    s = open(path, encoding='utf-8').read()
    if '"asPhotoToMemories"' in s:
        continue
    assert s.count(anchor) == 1, path
    s = s.replace(anchor, block + anchor)
    open(path, 'w', encoding='utf-8').write(s)
