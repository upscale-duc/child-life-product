# One-off generator for the S12 ARB entries (stories 14a–14g, 11i). Vietnamese = Figma source,
# English = engineering draft (D-012); copy for undrawn states (new-story kind, discard, delete,
# AI unavailable, empty lists) is engineering copy awaiting design review. Usage:
# python3 tool/s12_strings.py
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

def pl(one, other):
    return '{count, plural, =1{' + one + '} other{' + other + '}}'

# 14a
s('srySuggestTag', 'Gợi ý tuần này', 'This week’s suggestion', '14a card tag.')
s('srySuggestSub', pl('Từ 1 ảnh · bạn sửa trước khi lưu', 'Từ {count} ảnh · bạn sửa trước khi lưu'), pl('From 1 photo · edit before saving', 'From {count} photos · edit before saving'), '14a card.', count='int')
s('srySuggestCta', 'Xem bản nháp', 'See the draft', '14a card CTA.')
s('sryDrafts', 'Bản nháp · {count}', 'Drafts · {count}', '14a filter.', count='int')
s('sryShared', 'Đã chia sẻ', 'Shared', '14a filter.')
s('sryToldBy', '{who} kể · {when}', 'Told by {who} · {when}', '14a meta.', who='String', when='String')
s('sryWroteBy', '{who} viết · sửa lần cuối {when}', 'Written by {who} · last edited {when}', '14a letter meta.', who='String', when='String')
s('sryDraft', 'Bản nháp', 'Draft', '14a badge / 14b title.')
s('sryFromSuggestion', 'Nháp từ gợi ý · chưa lưu', 'Draft from a suggestion · not saved', '14a AI draft row.')
s('sryWrite', 'Viết', 'Write', '14a FAB.')
s('sryEmptyTitle', 'Chưa có câu chuyện nào', 'No stories yet', '14a empty (not drawn).')
s('sryEmptyBody', 'Viết lại một khoảnh khắc, hoặc chờ gợi ý cuối tuần từ những gì bạn đã ghi.', 'Write about a moment, or wait for the weekend suggestion from what you logged.', '14a empty.')
s('sryRelEmpty', 'Ba mẹ chưa chia sẻ câu chuyện nào.', 'The parents haven’t shared a story yet.', '11 empty.')
s('sryNewTitle', 'Viết gì?', 'What will you write?', 'New-story sheet (not drawn).')
s('sryKindStory', 'Câu chuyện', 'Story', 'New-story sheet.')
s('sryKindStoryHint', 'Kể một khoảnh khắc, có ảnh', 'Tell a moment, with photos', 'New-story sheet.')
s('sryKindLetter', 'Thư', 'Letter', 'New-story sheet.')
s('sryKindLetterHint', 'Viết thư cho con đọc sau này', 'A letter for your child to read later', 'New-story sheet.')
# 14b
s('srySaveDraft', 'Lưu nháp', 'Save draft', '14b top bar.')
s('sryAiTip', pl('AI viết nháp từ 1 ảnh. Chạm vào bất kỳ đoạn, ảnh hay tiêu đề nào để sửa.', 'AI viết nháp từ {count} ảnh. Chạm vào bất kỳ đoạn, ảnh hay tiêu đề nào để sửa.'), pl('AI drafted this from 1 photo. Tap any paragraph, photo or title to edit.', 'AI drafted this from {count} photos. Tap any paragraph, photo or title to edit.'), '14b tip.', count='int')
s('sryTip', 'Chạm vào bất kỳ đoạn, ảnh hay tiêu đề nào để sửa.', 'Tap any paragraph, photo or title to edit.', '14b tip for a manual story.')
s('sryChangeCover', 'Đổi ảnh bìa', 'Change cover', '14b chip.')
s('sryAddCover', 'Thêm ảnh bìa', 'Add a cover', '14b chip without a cover.')
s('sryTitleHint', 'Tiêu đề', 'Title', '14b title placeholder.')
s('sryParagraphHint', 'Viết vài dòng…', 'Write a few lines…', 'Empty paragraph placeholder.')
s('sryMetaPhotos', pl('1 ảnh', '{count} ảnh'), pl('1 photo', '{count} photos'), '14b meta.', count='int')
s('sryMetaMilestone', 'mốc {name}', 'milestone {name}', '14b meta.', name='String')
s('sryRewrite', 'Viết lại', 'Rewrite', '14b toolbar / 14c AI bar.')
s('sryWarmer', 'Ấm hơn', 'Warmer', '14b toolbar / 14c AI bar.')
s('sryShorter', 'Ngắn hơn', 'Shorter', '14c AI bar.')
s('sryUndo', 'Hoàn tác', 'Undo', '14c AI bar.')
s('sryAddBlock', 'Thêm đoạn · ảnh · mốc', 'Add paragraph · photos · milestone', '14b add row.')
s('sryAddParagraph', 'Đoạn văn', 'Paragraph', 'Add sheet.')
s('sryAddPhotos', 'Ảnh', 'Photos', 'Add sheet.')
s('sryAddMilestone', 'Mốc', 'Milestone', 'Add sheet.')
s('sryAddQuote', 'Câu trích', 'Pull quote', 'Add sheet.')
s('sryArrange', 'Sắp xếp', 'Arrange', '14b button / 14e title.')
s('sryPreviewSave', 'Xem trước & lưu', 'Preview & save', '14b button.')
s('sryDiscardTitle', 'Bỏ thay đổi?', 'Discard changes?', 'Cancel with edits (not drawn).')
s('sryDiscardBody', 'Những gì bạn vừa sửa chưa được lưu.', 'What you just changed isn’t saved.', 'Cancel with edits.')
s('sryDiscard', 'Bỏ thay đổi', 'Discard', 'Cancel with edits.')
s('sryKeepEditing', 'Sửa tiếp', 'Keep editing', 'Cancel with edits / 14f back.')
s('sryDraftSaved', 'Đã lưu nháp', 'Draft saved', 'Toast.')
s('sryDiscardDraft', 'Bỏ bản nháp', 'Discard draft', 'Editor overflow (not drawn).')
# 14c
s('sryEditParagraph', 'Sửa đoạn', 'Edit paragraph', '14c title.')
s('sryEdited', 'Đã sửa · không còn là văn AI', 'Edited · no longer AI text', '14c meta.')
s('sryWords', pl('1 từ', '{count} từ'), pl('1 word', '{count} words'), '14c meta.', count='int')
s('srySuggestFor', 'Gợi ý cho đoạn này', 'Suggestions for this paragraph', '14c section.')
s('sryUseThis', 'Dùng câu này', 'Use this', '14c chip.')
s('sryOtherSuggestion', 'Gợi ý khác', 'Another suggestion', '14c chip.')
s('sryAiUnavailable', 'AI chưa sẵn sàng. Bạn vẫn sửa tay được.', 'AI isn’t available right now. You can still edit by hand.', 'AI error (G-051).')
s('sryAiLimit', 'Hôm nay đã dùng hết lượt gợi ý.', 'You’ve used today’s suggestions.', 'AI daily limit.')
s('sryAiWorking', 'Đang viết…', 'Writing…', 'AI in progress.')
# 14d
s('sryPhotosTitle', 'Ảnh trong câu chuyện', 'Photos in the story', '14d title.')
s('sryChangePhoto', 'Đổi ảnh', 'Change photos', '14d option.')
s('sryChangePhotoHint', 'Chọn từ Kỷ niệm của {name}', 'Pick from {name}’s Memories', '14d option.', name='String')
s('sryAddToGroup', 'Thêm ảnh vào nhóm này', 'Add photos to this group', '14d option.')
s('sryAddToGroupHint', 'Tối đa 4 ảnh một nhóm', 'Up to 4 photos in a group', '14d option.')
s('sryCaption', 'Thêm chú thích', 'Add a caption', '14d option / caption sheet.')
s('sryCaptionHint', 'Hiện nhỏ dưới ảnh', 'Shown small under the photo', '14d option.')
s('sryMakeCover', 'Đặt làm ảnh bìa', 'Make it the cover', '14d option.')
s('sryRemovePhotos', 'Bỏ khỏi câu chuyện', 'Remove from the story', '14d destructive.')
s('sryRemovePhotosHint', 'Ảnh vẫn còn trong Kỷ niệm', 'The photos stay in Memories', '14d destructive.')
# 14e
s('sryArrangeHint', 'Giữ ≡ và kéo để đổi thứ tự. Vuốt trái để xoá khối.', 'Hold ≡ and drag to reorder. Swipe left to delete a block.', '14e hint.')
s('sryCoverRow', 'Ảnh bìa', 'Cover photo', '14e row.')
s('sryParagraphN', 'Đoạn {n}', 'Paragraph {n}', '14e row.', n='int')
s('sryPhotoGroup', 'Nhóm ảnh', 'Photo group', '14e row.')
s('sryMilestoneRow', 'Mốc', 'Milestone', '14e row.')
s('sryQuoteRow', 'Câu trích', 'Pull quote', '14e row.')
# 14f
s('sryPreviewLabel', 'XEM TRƯỚC', 'PREVIEW', '14f label.')
s('sryNeedTitle', 'Đặt tiêu đề cho câu chuyện.', 'Give the story a title.', '14f guard.')
s('sryNeedContent', 'Thêm ít nhất một đoạn hoặc một ảnh.', 'Add at least one paragraph or photo.', '14f guard.')
s('srySaveTitle', 'Lưu câu chuyện', 'Save story', '14f sheet title / button.')
s('sryPrivate', 'Riêng tư', 'Private', '14f card.')
s('sryFamilyRead', 'Cả nhà cùng đọc', 'The whole family reads it', '14f card.')
s('sryOneNotice', '1 thông báo chung', '1 general notification', '14f row.')
s('sryShareAfter', 'Lưu xong mới chia sẻ ra ngoài được.', 'You can share outside once it’s saved.', '14f footnote.')
s('sryPrivatePhotos', pl('1 ảnh đang Chỉ ba mẹ sẽ được gia đình thấy trong câu chuyện này.', '{count} ảnh đang Chỉ ba mẹ sẽ được gia đình thấy trong câu chuyện này.'), pl('1 parents-only photo will be seen by the family in this story.', '{count} parents-only photos will be seen by the family in this story.'), '14f D-002 note.', count='int')
s('srySavedNotified', 'Đã lưu · đã báo cho gia đình', 'Saved · the family was told', '14g toast.')
s('srySaved', 'Đã lưu câu chuyện', 'Story saved', 'Toast.')
# 14g / 11i
s('sryShare', 'Chia sẻ', 'Share', '14g button.')
s('sryWhoReads', 'Ai đọc câu chuyện này', 'Who reads this story', 'Share sheet (S12 part).')
s('sryAudienceChanged', 'Đã đổi ai đọc', 'Readers changed', 'Toast.')
s('sryDelete', 'Xoá câu chuyện', 'Delete story', 'Reader overflow (G-050).')
s('sryDeleteTitle', 'Xoá câu chuyện này?', 'Delete this story?', 'G-050.')
s('sryDeleteBody', 'Cả nhà sẽ không đọc được nữa. Ảnh vẫn còn trong Kỷ niệm.', 'Nobody in the family will see it any more. The photos stay in Memories.', 'G-050.')
s('sryDeleted', 'Đã xoá câu chuyện', 'Story deleted', 'Toast.')
s('sryMetaSaved', '{who} kể · {when} · {audience}', 'Told by {who} · {when} · {audience}', '14g meta.', who='String', when='String', audience='String')
s('sryRelMeta', '{who} chia sẻ với gia đình · {when}', '{who} shared with the family · {when}', '11i meta.', who='String', when='String')
s('sryMilestoneOn', '{name} · {date}', '{name} · {date}', '14g chip.', name='String', date='String')
s('sryMore', 'Tuỳ chọn câu chuyện', 'Story options', 'Reader ••• (a11y).')

def placeholders(ph):
    return {k: {'type': v} for k, v in ph.items()}

root = pathlib.Path(__file__).resolve().parent.parent / 'lib' / 'l10n'
for locale, idx in (('vi', 0), ('en', 1)):
    path = root / f'app_{locale}.arb'
    data = json.loads(path.read_text(), object_pairs_hook=collections.OrderedDict)
    for key, (vi, en, desc, ph) in S.items():
        if key in data and locale == 'vi' and data[key] != vi:
            raise SystemExit(f'key collision: {key}')
        data[key] = (vi, en)[idx]
        if locale == 'vi':
            meta = collections.OrderedDict(description=desc)
            if ph:
                meta['placeholders'] = placeholders(ph)
            data['@' + key] = meta
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
print(len(S), 'strings')
