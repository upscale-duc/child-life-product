# One-off generator for the S10 ARB entries (albums 10d–10e10, 10h5, favourites, loves, relatives
# 11c–11h, "Nhắn ba mẹ" D-034). Vietnamese = Figma source, English = engineering draft (D-012);
# parent-side message copy is engineering copy awaiting design review. Usage:
# python3 tool/s10_strings.py
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

def pl(one, other):
    return '{count, plural, =1{' + one + '} other{' + other + '}}'

# 10d / 11e
s('albCount', '{count} album', pl('1 album', '{count} albums'), '10d bar.', count='int')
s('albNew', 'Album mới', 'New album', '10d button / new-album sheet.')
s('albFavorites', 'Yêu thích', 'Favourites', 'Automatic album (10e2).')
s('albFavoritesMine', 'của riêng bạn', 'yours only', '11e card.')
s('albOnlyYou', 'Chỉ mình bạn', 'Only you', '10e2 pill.')
s('albFavoritesHint', 'ảnh bạn đã đánh dấu', 'photos you marked', '10e2 subtitle.')
s('albFromMilestones', 'Gom từ mốc bạn đã gắn', 'From the milestones you tagged', '10d section.')
s('albByMilestone', 'Gom theo mốc', 'By milestone', '11e section for relatives (gap note).')
s('albShared', '{count} album ba mẹ chia sẻ', pl('1 album the parents shared', '{count} albums the parents shared'), '11e subtitle.', count='int')
s('albEmpty', 'Chưa có album nào', 'No albums yet', '10d empty (not drawn).')
s('albEmptyBody', 'Tạo album để gom ảnh theo chủ đề, như Giờ tắm hay Bàn tay nhỏ.', 'Make albums to gather photos by theme, like Bath time or Little hands.', '10d empty.')
s('albUpdated', '{counts} · cập nhật {when}', '{counts} · updated {when}', '10e hero.', counts='String', when='String')
s('albAddPhotos', 'Thêm ảnh', 'Add photos', '10e bar.')
s('albStory', 'Kể thành chuyện', 'Make it a story', '10e bar (S12).')
s('albSharedBy', '{who} chia sẻ với gia đình', '{who} shared with the family', '11f chip.', who='String')
s('albNoItems', 'Album này chưa có ảnh nào.', 'This album has no photos yet.', '10e empty.')
s('albWhoButton', 'Ai thấy album này', 'Who sees this album', '10e bar / 10e3 / 10e6.')
# 10e3
s('albOptions', 'Tuỳ chọn album', 'Album options', '10e ••• button (a11y) / 10e3.')
s('albRename', 'Đổi tên album', 'Rename album', '10e3 / 10e4.')
s('albCover', 'Đổi ảnh bìa', 'Change cover', '10e3.')
s('albWhoFamilyHint', 'Mọi người thân trong gia đình', 'Every relative in the family', '10e3.')
s('albSelect', 'Chọn ảnh', 'Select photos', '10e3.')
s('albSelectHint', 'Bỏ khỏi album, đổi ai thấy…', 'Remove from the album, change who sees…', '10e3.')
s('albSort', 'Sắp xếp', 'Sort', '10e3 / 10e7.')
s('albDownload', 'Tải cả album về máy', 'Download the whole album', '10e3.')
s('albDownloadHint', '{counts} · khoảng {size}', '{counts} · about {size}', '10e3.', counts='String', size='String')
s('albDelete', 'Xoá album', 'Delete album', '10e3 / 10e10.')
s('albDeleteHint', 'Chỉ xoá album, ảnh vẫn còn trong Kỷ niệm', 'Deletes the album only; photos stay in Memories', '10e3.')
# 10e4
s('albName', 'Tên album', 'Album name', '10e4 field.')
s('albSuggestions', 'Gợi ý', 'Suggestions', '10e4.')
s('albSuggestBath', 'Giờ tắm', 'Bath time', '10e4 chip.')
s('albSuggestSun', 'Tắm nắng', 'Sunbathing', '10e4 chip.')
s('albSuggestSwim', 'Lần đầu đi bơi', 'First swim', '10e4 chip.')
s('albSuggestHands', 'Bàn tay nhỏ', 'Little hands', 'New album chip.')
s('albSuggestSleep', 'Ngủ ngoan', 'Sleeping sweetly', 'New album chip.')
s('albSaveName', 'Lưu tên', 'Save name', '10e4.')
s('albNameRequired', 'Đặt tên cho album.', 'Name the album.', 'Validation.')
s('albCreate', 'Tạo album', 'Create album', 'New album primary (not drawn).')
s('albCreated', 'Đã tạo album “{name}”', 'Created “{name}”', 'Toast.', name='String')
# 10e5
s('albCoverTitle', 'Chọn ảnh bìa', 'Choose a cover', '10e5 title.')
s('albSetCover', 'Đặt làm ảnh bìa', 'Set as cover', '10e5 / 10b3.')
s('albCoverSet', 'Đã đổi ảnh bìa', 'Cover changed', 'Toast.')
# 10e6
s('albAppliesTo', 'Áp dụng cho cả {count} mục trong album', 'Applies to all {count} items in the album', '10e6 note.', count='int')
s('albLaterFollow', 'Ảnh thêm sau này cũng theo quyền của album. Người chăm không thấy Kỷ niệm.', 'Photos added later follow the album too. Caregivers don’t see Memories.', '10e6 note.')
s('albNoticeHint', '1 thông báo chung, không kèm ảnh', '1 general notice, without photos', '10e6 toggle.')
s('albStayShared', '{count} mục vẫn được gia đình thấy vì còn nằm trong album Gia đình khác.', pl('1 item stays visible to the family because it is in another Family album.', '{count} items stay visible to the family because they are in another Family album.'), 'Toast after Chỉ ba mẹ (D-002).', count='int')
s('albAudienceSaved', 'Đã đổi ai thấy album', 'Album audience changed', 'Toast.')
# 10e7
s('sortNewest', 'Mới nhất', 'Newest', '10e7.')
s('sortNewestHint', 'Ảnh chụp gần đây ở trên', 'Recent shots first', '10e7.')
s('sortOldest', 'Cũ nhất', 'Oldest', '10e7.')
s('sortOldestHint', 'Kể lại từ đầu, hợp để xem lại', 'From the beginning, good for looking back', '10e7.')
s('sortAdded', 'Mới thêm vào album', 'Recently added', '10e7.')
s('sortAddedHint', 'Theo lúc bạn thêm ảnh', 'By when photos were added', '10e7.')
# 10e8
s('albRemove', 'Bỏ khỏi album', 'Remove from album', '10e8 bar.')
s('albRemoved', 'Đã bỏ {count} mục khỏi album', pl('Removed 1 item from the album', 'Removed {count} items from the album'), 'Toast.', count='int')
# 10e9
s('dlTitle', 'Tải về máy', 'Download', '10e9 title.')
s('dlSummary', '{count} mục · khoảng {size}', '{count} items · about {size}', '10e9.', count='int', size='String')
s('dlInto', 'Lưu vào album “{name}” trong app Ảnh', 'Saves into a “{name}” album in Photos', '10e9.', name='String')
s('dlWifi', 'Chỉ tải qua Wi-Fi', 'Wi-Fi only', '10e9 toggle.')
s('dlWifiHint', 'Video lớn sẽ đợi Wi-Fi', 'Large videos wait for Wi-Fi', '10e9.')
s('dlN', 'Tải {count} mục', pl('Download 1 item', 'Download {count} items'), '10e9 primary.', count='int')
s('dlFootnote', 'Tải ở nền — xong sẽ báo bạn.', 'Downloads in the background — we’ll tell you when done.', '10e9.')
s('dlNeedsWifi', 'Đang chờ Wi-Fi để tải video.', 'Waiting for Wi-Fi to download videos.', 'Toast.')
# 10e10
s('albDeleteTitle', 'Xoá album “{name}”?', 'Delete “{name}”?', '10e10 title.', name='String')
s('albDeleteBody', '{count} ảnh và video vẫn còn ở tab Ảnh và Nhật ký. Chỉ album bị xoá.', '{count} photos and videos stay in Photos and Journal. Only the album goes.', '10e10.', count='int')
s('albDeleteFamily', 'Gia đình sẽ không thấy album này nữa.', 'The family won’t see this album any more.', '10e10.')
s('albDeleted', 'Đã xoá album', 'Album deleted', 'Toast.')
# 10h5 / 10b3 album picker
s('albPickTitle', 'Thêm vào album', 'Add to album', '10h5 title.')
s('albPickNew', 'Tạo album mới', 'New album', '10h5 row.')
s('albPickHint', 'Có thể chọn nhiều album. Ảnh vẫn theo quyền “Ai thấy” bạn đã chọn.', 'You can pick several albums. Photos still follow the “Who sees” you chose.', '10h5 helper.')
s('albPickNone', 'Chưa chọn', 'None', '10h value.')
s('albPickMore', '{first} +{count}', '{first} +{count}', '10h value, several albums.', first='String', count='int')
s('albAdded', 'Đã thêm {count} mục vào “{name}”', pl('Added 1 item to “{name}”', 'Added {count} items to “{name}”'), 'Toast.', count='int', name='String')
s('albFamilySwitched', 'Album Gia đình: “Ai thấy” chuyển sang Gia đình.', 'Family album: “Who sees” switched to Family.', '10h hint (D-002).')
s('albPickFromMemories', 'Chọn từ Kỷ niệm', 'Choose from Memories', 'Add photos to album.')
# favourites, loves, messages
s('favAdded', 'Đã thêm vào Yêu thích', 'Added to Favourites', 'Toast.')
s('favRemoved', 'Đã bỏ khỏi Yêu thích', 'Removed from Favourites', 'Toast.')
s('love', 'Thương', 'Love', 'Action.')
s('lovesNamed', '{names} thương', '{names} loved this', 'Entry loves (parents).', names='String')
s('lovesCount', '{count} lượt thương', pl('1 love', '{count} loves'), 'Entry loves.', count='int')
s('messageAction', 'Nhắn', 'Message', '11g pill.')
s('messageParents', 'Nhắn ba mẹ', 'Message the parents', '11c action / composer title.')
s('messagePlaceholder', 'Nhắn ba mẹ…', 'Message the parents…', '11i field.')
s('messageTo', 'Nhắn {who}', 'Message {who}', 'Composer title for a caregiver (12e).', who='String')
s('messageSend', 'Gửi', 'Send', 'Composer.')
s('messageSent', 'Đã gửi lời nhắn', 'Message sent', 'Toast.')
s('messageHint', 'Chỉ ba mẹ đọc được. Đây không phải trò chuyện.', 'Only the parents read it. It isn’t a chat.', 'Composer (D-034).')
s('messageFailed', 'Chưa gửi được. Kiểm tra mạng và thử lại.', 'Couldn’t send. Check the connection and try again.', 'Toast.')
s('messagesTitle', 'Lời nhắn', 'Messages', 'Parents list (D-034).')
s('messagesEmpty', 'Chưa có lời nhắn nào.', 'No messages yet.', 'Parents list empty.')
s('messagesUnread', '{count} chưa đọc', pl('1 unread', '{count} unread'), 'Me row.', count='int')
s('messagesAboutPhoto', 'về một ảnh', 'about a photo', 'Context.')
s('messagesAboutMemory', 'về một kỷ niệm', 'about a memory', 'Context.')
s('messagesAboutAlbum', 'về album “{name}”', 'about “{name}”', 'Context.', name='String')
s('messagesAboutAlbumGeneric', 'về một album', 'about an album', 'Context.')
s('messagesAboutStory', 'về một câu chuyện', 'about a story', 'Context.')
s('messagesAboutRecord', 'về một ghi chép chăm sóc', 'about a care entry', 'Context.')
s('messagesOnItem', 'Lời nhắn ({count})', 'Messages ({count})', 'Viewer thread (parents).', count='int')
s('messageFrom', '{who} · {when}', '{who} · {when}', 'Message meta.', who='String', when='String')
# relatives 11c / 11g / 11h
s('relSubtitle', 'Những gì ba mẹ chia sẻ với gia đình', 'What the parents share with the family', '11c subtitle.')
s('relEmptyTitle', 'Chưa có kỷ niệm nào được chia sẻ', 'Nothing shared yet', '11h.')
s('relEmptyBody', 'Khi ba mẹ chia sẻ ảnh với gia đình, bạn sẽ nhận một thông báo và thấy ở đây.', 'When the parents share photos with the family, you’ll get a notification and see them here.', '11h.')
s('viewerShared', '{date} · {who} chia sẻ', '{date} · shared by {who}', '11g meta.', date='String', who='String')
s('viewerInAlbum', '{meta} · album {name}', '{meta} · album {name}', '10f meta with album.', meta='String', name='String')

def placeholders(ph):
    return {k: {'type': v} for k, v in ph.items()}

root = pathlib.Path(__file__).resolve().parent.parent / 'lib' / 'l10n'
for locale, idx in (('vi', 0), ('en', 1)):
    path = root / f'app_{locale}.arb'
    data = json.loads(path.read_text(), object_pairs_hook=collections.OrderedDict)
    for key, (vi, en, desc, ph) in S.items():
        data[key] = (vi, en)[idx]
        if locale == 'vi':
            meta = collections.OrderedDict(description=desc)
            if ph:
                meta['placeholders'] = placeholders(ph)
            data['@' + key] = meta
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
print(len(S), 'strings')
