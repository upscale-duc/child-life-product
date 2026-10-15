# Mốc phát triển (Figma v1.1 3a–3g, 311:1184 … 311:41795; D-076 #6). The app's own copy only: the
# milestones themselves come from the portal (contentMilestones). Vietnamese = Figma, English =
# engineering draft (D-012). Prefix `mt` (`ms` is Kỷ niệm's milestone picker). Idempotent.
# Usage: python3 tool/milestone_strings.py
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

def pl(one, other):
    return '{count, plural, =1{' + one + '} other{' + other + '}}'

# 3a list
s('mtTitle', 'Mốc phát triển', 'Milestones', '3a title; Tiện ích row; Home card kicker.')
s('mtSummary', '{name} đã có {count} mốc', '{name} has ' + pl('1 milestone', '{count} milestones'), '3a summary card.', name='String', count='int')
s('mtSummaryNone', '{name} chưa có mốc nào', 'No milestones for {name} yet', '3a summary card with no record.', name='String')
s('mtLead', 'Ghi lại khi bạn thấy bé làm được. Mỗi bé có nhịp riêng.', 'Record it when you see your baby do it. Every baby has their own pace.', '3a summary card body.')
s('mtLeadViewer', 'Các mốc tham khảo theo tuổi. Mỗi bé có nhịp riêng.', 'Reference milestones by age. Every baby has their own pace.', '3a summary for caregivers and relatives (they never see the records).')
s('mtFilterAll', 'Tất cả', 'All', '3a filter chip.')
s('mtGroupMotor', 'Vận động', 'Movement', 'Milestone group (B07).')
s('mtGroupCommunication', 'Giao tiếp', 'Communication', 'Milestone group (B07).')
s('mtGroupCognitive', 'Nhận thức', 'Thinking & learning', 'Milestone group (B07).')
s('mtGroupSocial', 'Cảm xúc – xã hội', 'Social & emotional', 'Milestone group (B07).')
s('mtOwn', 'Mốc riêng', 'Our own', 'Own milestones: 3a chip and row subline, 3g title.')
s('mtSeen', 'Đã quan sát', 'Observed', '3a section; 3c sheet title; 3d chip.')
s('mtFollowingSection', 'Đang theo dõi', 'Following', '3a section of milestones saved to follow.')
s('mtAround', 'Gợi ý quanh tuổi của bé', 'Around your baby’s age', '3a section.')
s('mtReferenceSection', 'Mốc tham khảo', 'Reference milestones', '3a section when the baby’s age is not known to this member.')
s('mtOthers', 'Các mốc khác', 'Other milestones', '3a section shown with "Xem tất cả".')
s('mtShowAll', 'Xem tất cả mốc ({count})', 'See all milestones ({count})', '3a toggle.', count='int')
s('mtShowLess', 'Thu gọn', 'Show less', '3a toggle.')
s('mtRangeMonths', 'tham khảo {from}–{to} tháng', 'typically {from}–{to} months', 'Row subline age range.', **{'from': 'int', 'to': 'int'})
s('mtRangeWeeks', 'tham khảo {from}–{to} tuần', 'typically {from}–{to} weeks', 'Row subline age range.', **{'from': 'int', 'to': 'int'})
s('mtRangeChipMonths', 'Tham khảo {from}–{to} tháng', 'Typically {from}–{to} months', '3b age chip.', **{'from': 'int', 'to': 'int'})
s('mtRangeChipWeeks', 'Tham khảo {from}–{to} tuần', 'Typically {from}–{to} weeks', '3b age chip.', **{'from': 'int', 'to': 'int'})
s('mtUpcoming', 'Sắp tới', 'Coming up', '3a tag: the age window starts soon.')
s('mtNotRecorded', 'Chưa ghi', 'Not recorded', '3a tag: not recorded (never "late").')
s('mtFollowingTag', 'Đang theo dõi', 'Following', '3a tag on a followed milestone.')
s('mtCreateOwn', 'Tạo mốc riêng', 'Create your own milestone', '3a dashed button.')
s('mtIllustrative', 'Nội dung minh hoạ · chờ chuyên môn duyệt', 'Illustrative content · pending expert review', 'Footer while the reference content has no qualified review (D-073 #2).')
s('mtReviewed', 'Nội dung được {reviewer} rà soát', 'Reviewed by {reviewer}', 'Footer once reviewed.', reviewer='String')
s('mtEmptyTitle', 'Chưa có mốc tham khảo', 'No reference milestones yet', '3a when nothing is published.')
s('mtEmptyBody', 'Nội dung đang được chuẩn bị. Bạn vẫn có thể tạo mốc riêng của bé.', 'The guide is being prepared. You can still create your own milestones.', '3a when nothing is published (parents).')
s('mtEmptyBodyViewer', 'Nội dung đang được chuẩn bị.', 'The guide is being prepared.', '3a when nothing is published (others).')
s('mtNoDob', 'Thêm ngày sinh của bé để xem gợi ý theo tuổi.', 'Add your baby’s date of birth to see suggestions for their age.', '3a for a parent when the date of birth is missing.')
s('mtEntrySub', 'Ghi lại những điều bé làm được', 'Record what your baby can do', 'Tiện ích row subline.')
s('mtEntrySubViewer', 'Mốc tham khảo theo tuổi của bé', 'Reference milestones for your baby’s age', 'Tiện ích row subline for caregivers and relatives (they read the guide only).')
s('mtEntryCount', '{count} mốc đã ghi', pl('1 milestone recorded', '{count} milestones recorded'), 'Tiện ích row subline with records.', count='int')

# 3b detail
s('mtHowTo', 'Cách nhận biết', 'How to recognise it', '3b card title.')
s('mtReassure', 'Khoảng tuổi chỉ để tham khảo. Mỗi bé có nhịp riêng — nếu bạn băn khoăn, hãy hỏi bác sĩ của bé.', 'Age ranges are for reference only. Every baby has their own pace — if you are unsure, ask your baby’s doctor.', '3b reassurance banner.')
s('mtTalkToDoctor', 'Khi nào nên hỏi bác sĩ', 'When to ask the doctor', '3b callout title (from the portal text).')
s('mtHealthLink', 'Xem hướng dẫn sức khoẻ', 'See health guidance', '3b link to the health guidance (HL01).')
s('mtMarkSeen', 'Đánh dấu đã quan sát', 'Mark as observed', '3b primary button.')
s('mtFollow', 'Lưu để theo dõi', 'Save to follow', '3b plain button.')
s('mtUnfollow', 'Bỏ theo dõi', 'Stop following', '3b plain button on a followed milestone.')
s('mtFollowed', 'Đã lưu để theo dõi', 'Saved to follow', 'Toast.')
s('mtUnfollowed', 'Đã bỏ theo dõi', 'No longer following', 'Toast.')
s('mtSources', 'Nguồn tham khảo', 'Sources', '3b sources heading.')
s('mtParentsRecord', 'Ba mẹ của bé ghi lại các mốc trong mục này.', 'Baby’s parents record milestones here.', '3b / 3a note for caregivers and relatives.')
s('mtNotFound', 'Không tìm thấy mốc này.', 'This milestone wasn’t found.', 'Unknown id.')

# 3c record sheet
s('mtDateDid', 'Ngày bé làm được', 'The day your baby did it', '3c date field.')
s('mtNote', 'Ghi chú', 'Note', '3c / 3g note field.')
s('mtNoteHint', 'Bé làm được lúc nào, ở đâu, với ai…', 'When, where, with whom…', 'Note placeholder.')
s('mtPhotosOptional', 'Ảnh (không bắt buộc)', 'Photos (optional)', '3c label.')
s('mtAddPhotos', 'Thêm ảnh', 'Add photos', 'Camera slot a11y.')
s('mtRemovePhoto', 'Bỏ ảnh này', 'Remove this photo', 'Thumbnail a11y.')
s('mtSave', 'Lưu mốc', 'Save milestone', '3c / 3g primary button.')
s('mtPickDate', 'Chọn ngày', 'Choose a day', 'Date sheet title.')
s('mtSaved', 'Đã lưu mốc', 'Milestone saved', 'Toast after saving.')
s('mtSaveFailed', 'Chưa lưu được. Thử lại nhé.', 'Couldn’t save. Please try again.', 'Toast.')

# 3d / 3f saved
s('mtMeta', '{date} · lúc {name} {age} · {who} ghi', '{date} · {name} was {age} · recorded by {who}', '3d meta line.', date='String', name='String', age='String', who='String')
s('mtMetaNoAge', '{date} · {who} ghi', '{date} · recorded by {who}', '3d meta line without the age.', date='String', who='String')
s('mtKeepTitle', 'Giữ khoảnh khắc này trong Kỷ niệm?', 'Keep this moment in Memories?', '3d card.')
s('mtKeepBody', 'Tạo kỷ niệm với ảnh và ghi chú này, gắn mốc “{name}”.', 'Create a memory with these photos and this note, tagged “{name}”.', '3d card body.', name='String')
s('mtKeepBodyNote', 'Tạo kỷ niệm gắn mốc “{name}” — thêm ảnh nếu bạn muốn.', 'Create a memory tagged “{name}” — add photos if you like.', '3d card body without photos.', name='String')
s('mtCreateMemory', 'Tạo kỷ niệm', 'Create memory', '3d button.')
s('mtCreateCard', 'Tạo thẻ mốc', 'Make a milestone card', '3d / 3f link to Thiệp cột mốc.')
s('mtInMemories', 'Đã lưu trong Kỷ niệm', 'Saved in Memories', '3f row title.')
s('mtSeenByFamily', 'Cả gia đình xem được · {count} ảnh', 'The whole family can see it · ' + pl('1 photo', '{count} photos'), '3f row subline.', count='int')
s('mtSeenByParents', 'Chỉ ba mẹ xem được · {count} ảnh', 'Parents only · ' + pl('1 photo', '{count} photos'), '3f row subline.', count='int')
s('mtSeenByFamilyNote', 'Cả gia đình xem được · ghi chú', 'The whole family can see it · note', '3f row subline (no photo).')
s('mtSeenByParentsNote', 'Chỉ ba mẹ xem được · ghi chú', 'Parents only · note', '3f row subline (no photo).')
s('mtUploading', 'Đang tải lên Kỷ niệm…', 'Uploading to Memories…', '3f row while the memory is on its way.')
s('mtMore', 'Thêm thao tác', 'More actions', '3d overflow a11y.')
s('mtEdit', 'Sửa ghi nhận', 'Edit', '3d action.')
s('mtDelete', 'Xoá ghi nhận', 'Remove this record', '3d action.')
s('mtDeleteTitle', 'Xoá ghi nhận mốc này?', 'Remove this milestone record?', 'Confirm sheet.')
s('mtDeleteBody', 'Ngày và ghi chú sẽ bị xoá. Kỷ niệm đã tạo vẫn ở trong Kỷ niệm.', 'The day and the note are removed. Memories you made stay in Memories.', 'Confirm sheet body.')
s('mtDeleted', 'Đã xoá ghi nhận', 'Record removed', 'Toast.')

# 3e memory sheet
s('mtNewMemory', 'Kỷ niệm mới', 'New memory', '3e sheet title.')
s('mtCaption', 'Chú thích', 'Caption', '3e field.')
s('mtCaptionHint', 'Vài dòng về khoảnh khắc này', 'A few words about this moment', '3e placeholder.')
s('mtTag', 'Mốc · {name}', 'Milestone · {name}', '3e milestone chip.', name='String')
s('mtWhoSees', 'Ai được xem', 'Who can see', '3e label.')
s('mtSaveMemory', 'Lưu kỷ niệm', 'Save memory', '3e button.')
s('mtMemoryCreated', 'Đã tạo kỷ niệm', 'Memory created', '3f toast.')
s('mtCaptionRequired', 'Thêm chú thích hoặc ảnh để lưu kỷ niệm.', 'Add a caption or a photo to save the memory.', '3e validation.')

# 3g own milestone
s('mtOwnLead', 'Những lần đầu tiên chỉ nhà mình có — ghi lại theo cách của bạn.', 'Firsts only your family has — record them your way.', '3g lead.')
s('mtName', 'Tên mốc', 'Milestone name', '3g field.')
s('mtNameHint', 'Ví dụ: Lần đầu về quê', 'e.g. First trip to see the grandparents', '3g placeholder.')
s('mtCount', '{count}/{max} ký tự', '{count}/{max} characters', '3g counter.', count='int', max='int')
s('mtDate', 'Ngày', 'Day', '3g date field.')
s('mtAlsoMemory', 'Tạo kỷ niệm cùng lúc', 'Also create a memory', '3g toggle.')
s('mtAlsoMemorySub', 'Lưu ảnh và ghi chú vào Kỷ niệm', 'Save the photos and note to Memories', '3g toggle subline.')
s('mtEditTitle', 'Sửa mốc', 'Edit milestone', '3g in edit mode.')

# Home "Dành cho bé hôm nay" card
s('mtTodayKicker', 'Mốc có thể thấy · {range}', 'A milestone you may see · {range}', 'Home small card kicker ({range} = "tham khảo 1–3 tháng").', range='String')
s('mtTodayAction', 'Ghi nhận khi bé làm được', 'Record it when you see it', 'Home small card action (Cùng nuôi).')
s('mtTodayActionViewer', 'Xem cách nhận biết', 'How to recognise it', 'Home small card action (others).')

OBSOLETE = ['mtTodayTitle', 'mtTodayOpen']

root = pathlib.Path(__file__).resolve().parent.parent / 'lib' / 'l10n'
for locale, idx in (('vi', 0), ('en', 1)):
    path = root / f'app_{locale}.arb'
    data = json.loads(path.read_text(), object_pairs_hook=collections.OrderedDict)
    for key in OBSOLETE:
        data.pop(key, None)
        data.pop('@' + key, None)
    for key, (vi, en, desc, ph) in S.items():
        meta = data.get('@' + key)
        if locale == 'vi' and key in data and (meta or {}).get('description') != desc:
            raise SystemExit(f'{key} already exists for something else: pick another id')
        data[key] = (vi, en)[idx]
        if locale == 'vi':
            meta = collections.OrderedDict(description=desc)
            if ph:
                meta['placeholders'] = {k: {'type': v} for k, v in ph.items()}
            data['@' + key] = meta
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
print(len(S), 'strings')
