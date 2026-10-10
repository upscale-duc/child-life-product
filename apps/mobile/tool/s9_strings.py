# One-off generator for the S9 ARB entries (Kỷ niệm: timeline, photos, add, picker, compose,
# milestones, upload queue, batch actions, viewer, sharing private items). Vietnamese = Figma
# source, English = engineering draft (D-012). Usage: python3 tool/s9_strings.py
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

def pl(one, other):
    return '{count, plural, =1{' + one + '} other{' + other + '}}'

# Tabs and header (10a)
s('memJournal', 'Nhật ký', 'Journal', 'Memory tab (10a).')
s('memPhotos', 'Ảnh', 'Photos', 'Memory tab (10b).')
s('memAlbums', 'Album', 'Albums', 'Memory tab (10d, S10).')
s('memStories', 'Câu chuyện', 'Stories', 'Memory tab (S12).')
s('memSoonTitle', 'Sắp có', 'Coming soon', 'Tabs not built yet (S10, S12).')
s('memSoonBody', 'Phần này có trong bản cập nhật tới.', 'This part arrives in a coming update.', 'Tabs not built yet.')
s('a11yViewOptions', 'Cách xem', 'View options', 'Header sliders button.')
s('a11yAddMemory', 'Thêm vào Kỷ niệm', 'Add to Memories', 'Header + button.')
s('memWeek', 'Tuần thứ {week}', 'Week {week}', '10a week group (R-113).', week='int')
s('memBeforeBirth', 'Trước ngày chào đời', 'Before birth', 'Week group for earlier dates.')
s('memPhotoCount', '{count} ảnh', pl('1 photo', '{count} photos'), 'Count.', count='int')
s('memVideoCount', '{count} video', pl('1 video', '{count} videos'), 'Count.', count='int')
s('memItemCount', '{count} mục', pl('1 item', '{count} items'), 'Count (10b5).', count='int')
s('memTodayAt', 'Hôm nay · {time}', 'Today · {time}', 'Entry date.', time='String')
s('memYesterdayAt', 'Hôm qua · {time}', 'Yesterday · {time}', 'Entry date.', time='String')
s('memEmptyTitle', 'Chưa có kỷ niệm nào', 'No memories yet', 'Empty journal (not drawn).')
s('memEmptyBody', 'Chạm + để thêm ảnh, video hoặc ghi chú đầu tiên của {name}.', 'Tap + to add {name}’s first photo, video or note.', 'Empty journal.', name='String')
s('memPhotosEmpty', 'Ảnh và video của {name} sẽ hiện ở đây.', '{name}’s photos and videos will show here.', 'Empty grid.', name='String')
s('memNoMatch', 'Không có mục nào khớp cách xem này.', 'Nothing matches these view options.', 'Filtered empty.')
s('memProcessing', 'Đang xử lý', 'Processing', 'Tile before ready.')
# UploadPill (132:898)
s('upUploading', 'Đang tải {done}/{total} mục', 'Uploading {done} of {total}', 'UploadPill.', done='int', total='int')
s('upUploadingHint', 'Cứ làm việc khác, xong sẽ báo bạn', 'Carry on — we’ll tell you when it’s done', 'UploadPill.')
s('upPaused', 'Tạm dừng · chờ mạng', 'Paused · waiting for network', 'UploadPill.')
s('upPausedHint', 'Tự tải tiếp khi có mạng', 'Resumes by itself when online', 'UploadPill.')
s('upPausedByYou', 'Đã tạm dừng', 'Paused', 'UploadPill after "Tạm dừng".')
s('upPausedByYouHint', 'Chạm để tiếp tục', 'Tap to resume', 'UploadPill.')
s('upFailed', '{count} mục chưa tải được', pl('1 item not uploaded', '{count} items not uploaded'), 'UploadPill.', count='int')
s('upFailedHint', 'Chạm để thử lại hoặc bỏ qua', 'Tap to retry or skip', 'UploadPill.')
s('upDone', 'Đã tải xong {count} mục', pl('Uploaded 1 item', 'Uploaded {count} items'), 'UploadPill.', count='int')
s('upToldFamily', 'Đã báo cho {names}', 'Told {names}', 'UploadPill done.', names='String')
s('upParentsOnly', 'Chỉ ba mẹ xem được', 'Only parents can see them', 'UploadPill done, Chỉ ba mẹ.')
s('upWaitingWifi', '{count} video chờ Wi-Fi', pl('1 video waiting for Wi-Fi', '{count} videos waiting for Wi-Fi'), 'UploadPill.', count='int')
s('upWaitingWifiHint', 'Video tự tải khi có Wi-Fi', 'Videos upload by themselves on Wi-Fi', 'UploadPill.')
s('upWaitingQuota', 'Hết dung lượng · {count} mục giữ trên máy', 'Storage full · {count} kept on this phone', 'UploadPill (R-121).', count='int')
s('upWaitingQuotaHint', 'Chạm để xem', 'Tap to see', 'UploadPill (R-121).')
s('upPreparing', 'Đang chuẩn bị {count} mục', pl('Preparing 1 item', 'Preparing {count} items'), 'UploadPill before the session.', count='int')
# 10a2
s('addTitle', 'Thêm vào Kỷ niệm', 'Add to Memories', '10a2 / 10h title.')
s('addRecent', 'Ảnh mới chụp hôm nay', 'Taken today', '10a2 recent strip.')
s('addRecentHint', 'Chạm để thêm nhanh', 'Tap to add quickly', '10a2.')
s('addCamera', 'Chụp ảnh hoặc quay video', 'Take a photo or video', '10a2.')
s('addCameraHint', 'Lưu thẳng vào Kỷ niệm', 'Saves straight to Memories', '10a2.')
s('addLibrary', 'Chọn từ Thư viện ảnh', 'Choose from Photos', '10a2.')
s('addLibraryHint', 'Chọn nhiều ảnh, video một lần', 'Pick several photos and videos at once', '10a2.')
s('addFiles', 'Chọn từ Tệp', 'Choose from Files', '10a2.')
s('addFilesHint', 'iCloud Drive, Google Drive, USB…', 'iCloud Drive, Google Drive, USB…', '10a2.')
s('addNote', 'Viết ghi chú', 'Write a note', '10a2.')
s('addNoteHint', 'Kỷ niệm chỉ có chữ, thêm ảnh sau', 'A memory in words — add photos later', '10a2.')
# 10g picker
s('pickRecent', 'Gần đây', 'Recent', '10g chip.')
s('pickVideos', 'Video', 'Videos', '10g chip.')
s('pickAlbums', 'Album', 'Albums', '10g chip.')
s('pickSummary', '{count} mục · {photos} ảnh, {videos} video', '{count} items · {photos} photos, {videos} videos', '10g tray.', count='int', photos='int', videos='int')
s('pickMax', 'Tối đa {count} mục/lần', 'Up to {count} at a time', '10g tray (R-102).', count='int')
s('pickAdd', 'Thêm {count} mục', pl('Add 1 item', 'Add {count} items'), '10g primary.', count='int')
s('pickLimit', 'Mỗi lần thêm tối đa {count} mục.', 'You can add up to {count} at a time.', '10g limit toast.', count='int')
s('pickNoAccess', 'Child Life chưa được xem thư viện ảnh.', 'Child Life can’t see your photo library yet.', '10g denied (not drawn).')
s('pickLimited', 'Bạn đang cho xem một số ảnh.', 'You’re sharing some photos only.', '10g limited access.')
s('pickChooseMore', 'Chọn thêm', 'Choose more', '10g limited access.')
s('pickEmpty', 'Chưa có ảnh nào ở đây', 'No photos here', '10g empty.')
s('pickAlbumsTitle', 'Chọn album', 'Choose an album', '10g album chip sheet.')
# 10h compose
s('composeCaption', 'Viết vài dòng… (không bắt buộc)', 'Write a few lines… (optional)', '10h caption.')
s('composeNoteHint', 'Viết điều bạn muốn nhớ…', 'Write what you want to remember…', 'Note compose.')
s('composeDate', 'Ngày', 'Date', '10h row.')
s('composeByCapture', 'Theo ngày chụp', 'By capture date', '10h value.')
s('composeMilestone', 'Mốc', 'Milestone', '10h row.')
s('composeNoMilestone', 'Không gắn mốc', 'No milestone', '10h value / 10h3 clear.')
s('composeWho', 'Ai thấy', 'Who sees', '10h section.')
s('audParents', 'Chỉ ba mẹ', 'Parents only', 'Audience.')
s('audParentsHint', 'Chỉ ba mẹ xem được', 'Only parents can see it', 'Audience card.')
s('audFamily', 'Gia đình', 'Family', 'Audience.')
s('audFamilyHint', 'Cả nhà cùng xem', 'The whole family sees it', 'Audience card.')
s('composeNotify', 'Báo cho gia đình', 'Tell the family', '10h toggle.')
s('composeNotifyHint', 'Gia đình nhận 1 thông báo', 'The family gets 1 notification', '10h toggle.')
s('composeUpload', 'Tải lên {count} mục', pl('Upload 1 item', 'Upload {count} items'), '10h primary.', count='int')
s('composeSaveNote', 'Lưu ghi chú', 'Save note', 'Note primary.')
s('composeFootnote', 'Ảnh tải ở nền — xong sẽ báo bạn.', 'Photos upload in the background — we’ll tell you when done.', '10h footnote.')
s('composeNoteRequired', 'Viết vài chữ cho ghi chú.', 'Write a few words for the note.', 'Note validation.')
s('composeNoteSaved', 'Đã lưu ghi chú', 'Note saved', 'Toast.')
s('composeMore', '+{count}', '+{count}', '10h strip overflow.', count='int')
# 10h2
s('dateTitle', 'Ngày của kỷ niệm', 'Date of the memory', '10h2 title.')
s('dateByCaptureHint', 'Mỗi ảnh giữ ngày riêng · {range}', 'Each photo keeps its own date · {range}', '10h2.', range='String')
s('dateOneForAll', 'Một ngày cho tất cả', 'One date for all', '10h2.')
s('dateOneForAllHint', 'Dùng khi ngày chụp bị sai', 'Use when the capture date is wrong', '10h2.')
s('dateBeforeBirth', 'Không chọn được ngày trước khi {name} chào đời.', 'You can’t pick a date before {name} was born.', '10h2 helper.', name='String')
# 10h3 / 10h4
s('msTitle', 'Gắn mốc', 'Tag a milestone', '10h3 title / 10b3 row.')
s('msSearch', 'Tìm hoặc gõ mốc mới…', 'Search or type a new milestone…', '10h3 search.')
s('msSuggest', 'Gợi ý cho bé {age}', 'Suggestions at {age}', '10h3 section.', age='String')
s('msOwn', 'Mốc nhà mình đã tạo', 'Our family’s milestones', '10h3 section.')
s('msCreate', 'Tạo mốc mới', 'Create a milestone', '10h3 / 10h4.')
s('msOnePer', 'Mỗi kỷ niệm 1 mốc', 'One milestone per memory', '10h3.')
s('msName', 'Tên mốc', 'Milestone name', '10h4 field.')
s('msPreview', 'Xem trước', 'Preview', '10h4.')
s('msShared', 'Mốc mới được lưu cho cả nhà dùng lại lần sau.', 'New milestones are saved for the whole family to reuse.', '10h4 helper (R-105).')
s('msCreateTag', 'Tạo & gắn mốc', 'Create & tag', '10h4 primary.')
s('msNameRequired', 'Đặt tên cho mốc.', 'Name the milestone.', '10h4 validation.')
s('msChip', '{name} · {date}', '{name} · {date}', 'Milestone chip.', name='String', date='String')
for key, vi, en in [
    ('FirstSmile', 'Lần đầu cười', 'First smile'),
    ('FirstBath', 'Lần đầu tắm', 'First bath'),
    ('LiftsHead', 'Ngẩng đầu', 'Lifts head'),
    ('FirstOuting', 'Lần đầu đi dạo', 'First outing'),
    ('OneMonth', 'Đầy tháng', 'One month old'),
    ('MeetsGrandparents', 'Lần đầu gặp ông bà', 'Meets grandparents'),
    ('RollsOver', 'Lần đầu lật người', 'First roll-over'),
    ('Laughs', 'Cười thành tiếng', 'First laugh'),
    ('FirstSolids', 'Lần đầu ăn dặm', 'First solids'),
    ('SitsUp', 'Tự ngồi', 'Sits up'),
    ('FirstTooth', 'Chiếc răng đầu tiên', 'First tooth'),
    ('Crawls', 'Biết bò', 'Crawls'),
    ('FirstWord', 'Tiếng nói đầu tiên', 'First word'),
    ('FirstSteps', 'Bước đi đầu tiên', 'First steps'),
    ('FirstBirthday', 'Thôi nôi', 'First birthday'),
]:
    s('ms' + key, vi, en, 'Preset milestone (10h3; after the first six: engineering suggestion).')
# 10i queue
s('qTitle', 'Đang tải lên', 'Uploading', '10i title.')
s('qSummary', '{done}/{total} mục · còn khoảng {time}', '{done} of {total} · about {time} left', '10i summary.', done='int', total='int', time='String')
s('qSummaryNoEta', '{done}/{total} mục', '{done} of {total}', '10i summary.', done='int', total='int')
s('qPause', 'Tạm dừng', 'Pause', '10i button.')
s('qResume', 'Tiếp tục', 'Resume', '10i button (not drawn).')
s('qNotice', 'Gia đình sẽ được báo khi tải xong', 'The family will be told when it’s done', '10i summary.')
s('qFailed', '{count} mục lỗi', pl('1 failed', '{count} failed'), '10i errors.', count='int')
s('qUnreadable', '{count} tệp không đọc được', pl('1 unreadable file', '{count} unreadable files'), '10i errors.', count='int')
s('rowProgress', '{percent}% · {sent}/{total}', '{percent}% · {sent}/{total}', 'QueueRow uploading.', percent='int', sent='String', total='String')
s('rowWaitingWifi', 'Chờ Wi-Fi · video {size}', 'Waiting for Wi-Fi · video {size}', 'QueueRow.', size='String')
s('rowFailed', 'Mất kết nối khi đang tải', 'Connection lost while uploading', 'QueueRow.')
s('rowUnreadable', 'Tệp bị lỗi · không thử lại được', 'File is damaged · can’t retry', 'QueueRow.')
s('rowDone', 'Đã tải lên', 'Uploaded', 'QueueRow.')
s('rowQueued', 'Đang chờ', 'Waiting', 'QueueRow (not drawn).')
s('rowPaused', 'Tạm dừng', 'Paused', 'QueueRow (not drawn).')
s('rowWaitingQuota', 'Hết dung lượng · giữ trên máy', 'Storage full · kept on this phone', 'QueueRow (R-121).')
s('rowCancelled', 'Đã huỷ', 'Cancelled', 'QueueRow (not drawn).')
s('rowPreparing', 'Đang chuẩn bị', 'Preparing', 'QueueRow (not drawn).')
s('qWifiOnly', 'Video chỉ tải qua Wi-Fi', 'Videos over Wi-Fi only', '10i toggle.')
s('qWifiOnlyHint', 'Ảnh vẫn tải bằng dữ liệu di động', 'Photos still use mobile data', '10i toggle.')
s('qRetryAll', 'Thử lại tất cả ({count})', 'Retry all ({count})', '10i button.', count='int')
s('qFootnote', 'Mục lỗi được giữ trên máy · tự thử lại khi có mạng.', 'Failed items stay on this phone · retried when back online.', '10i footnote.')
s('qEmpty', 'Không còn gì đang tải.', 'Nothing is uploading.', '10i empty.')
s('a11yCancelUpload', 'Huỷ tải {name}', 'Cancel {name}', 'QueueRow ×.', name='String')
# 10b grid, select, actions
s('memMonth', 'Tháng {month}, {year}', '{monthName} {year}', 'Month header (10b).', month='int', year='int', monthName='String')
s('memFilterMonth', 'Tháng', 'Month', '10b chip.')
s('memSelect', 'Chọn', 'Select', '10b chip.')
s('memSelectMonth', 'Chọn cả tháng', 'Select month', '10b2.')
s('memSelected', '{count} mục đã chọn', pl('1 selected', '{count} selected'), '10b2 pill / 10b3 title.', count='int')
s('a11yShareOptions', 'Chia sẻ và tuỳ chọn', 'Share and options', '10b2 pill.')
s('a11yDeleteSelected', 'Xoá mục đã chọn', 'Delete selected', '10b2 pill.')
s('actWho', 'Ai thấy', 'Who sees', '10b3.')
s('actAlbum', 'Album', 'Album', '10b3 (S10).')
s('actDownload', 'Tải về', 'Download', '10b3 / 10f.')
s('actSend', 'Gửi đi', 'Send', '10b3.')
s('actMore', 'Thêm', 'More', '10b3 section.')
s('actFavorite', 'Thêm vào Yêu thích', 'Add to Favourites', '10b3 (S10).')
s('actFavoriteHint', 'Gom vào album Yêu thích của bạn', 'Collects into your Favourites album', '10b3.')
s('actMilestoneHint', 'Ví dụ: Lần đầu cười', 'e.g. First smile', '10b3.')
s('actDate', 'Đổi ngày', 'Change date', '10b3.')
s('actDateHint', 'Khi ngày chụp bị sai', 'When the capture date is wrong', '10b3.')
s('actStory', 'Kể thành câu chuyện', 'Make it a story', '10b3 (S12).')
s('actStoryHint', 'Dùng {count} mục này làm bản nháp', pl('Use this item as a draft', 'Use these {count} items as a draft'), '10b3.', count='int')
s('actCover', 'Đặt làm ảnh bìa album', 'Set as album cover', '10b3 (S10).')
s('actCoverHint', 'Chỉ dùng khi chọn 1 ảnh', 'Only with 1 photo selected', '10b3.')
s('actSoon', 'Sắp có', 'Coming soon', '10b3 rows of later slices.')
s('whoItemsTitle', 'Ai thấy {count} mục này?', pl('Who sees this item?', 'Who sees these {count} items?'), 'Audience sheet from 10b3 (not drawn).', count='int')
s('toastSaved', 'Đã lưu {count} mục vào Ảnh', pl('Saved 1 item to Photos', 'Saved {count} items to Photos'), 'Download toast.', count='int')
s('toastSaving', 'Đang lưu vào Ảnh…', 'Saving to Photos…', 'Download toast.')
s('toastSaveFailed', 'Chưa lưu được vào Ảnh. Thử lại nhé.', 'Couldn’t save to Photos. Please try again.', 'Download failed.')
s('toastDateChanged', 'Đã đổi ngày {count} mục', pl('Changed the date of 1 item', 'Changed the date of {count} items'), 'Toast.', count='int')
s('toastTagged', 'Đã gắn mốc cho {count} mục', pl('Tagged 1 item', 'Tagged {count} items'), 'Toast.', count='int')
s('toastParentsOnly', 'Đã chuyển {count} mục sang Chỉ ba mẹ', pl('Moved 1 item to Parents only', 'Moved {count} items to Parents only'), 'Toast.', count='int')
s('toastShared', 'Đã chia sẻ {count} mục với gia đình', pl('Shared 1 item with the family', 'Shared {count} items with the family'), 'Toast (10o).', count='int')
s('toastDeleted', 'Đã xoá {count} mục', pl('Deleted 1 item', 'Deleted {count} items'), 'Toast (10b4) with undo.', count='int')
s('toastActionFailed', 'Chưa làm được. Kiểm tra mạng và thử lại.', 'That didn’t work. Check the connection and try again.', 'Batch action failed.')
# 10b4
s('delTitle', 'Xoá {count} mục?', pl('Delete 1 item?', 'Delete {count} items?'), '10b4 title.', count='int')
s('delBody', 'Mục sẽ biến mất khỏi Kỷ niệm của cả gia đình. Ảnh gốc trên máy bạn vẫn còn.', 'They’ll disappear from the whole family’s Memories. The originals on your phone stay.', '10b4.')
s('delRecover', 'Khôi phục được trong 30 ngày ở “Đã xoá gần đây”.', 'You can restore them for 30 days from “Recently deleted”.', '10b4.')
s('delParentsOnly', 'Chỉ ba mẹ mới xoá được.', 'Only parents can delete.', '10b4.')
s('delN', 'Xoá {count} mục', pl('Delete 1 item', 'Delete {count} items'), '10b4 button.', count='int')
# 10b5
s('gotoTitle', 'Đi tới tháng', 'Go to month', '10b5 title.')
s('gotoMonthShort', 'Th {month}', '{monthName}', '10b5 cell.', month='int', monthName='String')
s('gotoNote', '{name} sinh ngày {date} · năm khác sẽ hiện khi có ảnh', '{name} was born on {date} · other years appear once they have photos', '10b5 footnote.', name='String', date='String')
s('scrubberMonth', 'Th {month}, {year}', '{monthName} {year}', 'Date scrubber.', month='int', year='int', monthName='String')
# 10c
s('viewTitle', 'Cách xem', 'View options', '10c title.')
s('viewGroup', 'Nhóm theo', 'Group by', '10c.')
s('viewDay', 'Ngày', 'Day', '10c.')
s('viewWeek', 'Tuần', 'Week', '10c.')
s('viewMonth', 'Tháng', 'Month', '10c.')
s('viewLayout', 'Kiểu xem', 'Layout', '10c.')
s('viewSmall', 'Lưới nhỏ', 'Small grid', '10c.')
s('viewLarge', 'Lưới lớn', 'Large grid', '10c.')
s('viewList', 'Danh sách', 'List', '10c.')
s('viewShow', 'Hiện', 'Show', '10c.')
s('viewWithMilestone', 'Có mốc', 'With milestone', '10c.')
s('viewAsRelative', 'Xem như người thân', 'View as a relative', '10c.')
s('viewAsRelativeHint', 'Kiểm tra người thân đang thấy những gì', 'Check what relatives can see', '10c.')
s('viewApply', 'Áp dụng', 'Apply', '10c primary.')
s('viewAsRelativeBanner', 'Đang xem như người thân', 'Viewing as a relative', 'Preview banner (not drawn).')
s('viewAsRelativeExit', 'Thoát', 'Exit', 'Preview banner.')
s('dayGroup', '{date} · {counts}', '{date} · {counts}', 'Day/month group header.', date='String', counts='String')
# 10f viewer
s('viewerPosted', '{date} · {who} đăng', '{date} · posted by {who}', '10f meta.', date='String', who='String')
s('viewerShare', 'Chia sẻ', 'Share', '10f action.')
s('viewerVideoLoading', 'Đang tải video…', 'Loading video…', '10f video.')
s('viewerVideoFailed', 'Chưa mở được video.', 'Couldn’t open the video.', '10f video.')
s('a11yPlay', 'Phát video', 'Play video', '10f video.')
# 10o
s('shareTitle', 'Chia sẻ với gia đình?', 'Share with the family?', '10o title.')
s('sharePrivatePhotos', '{count} ảnh riêng tư', pl('1 private photo', '{count} private photos'), '10o items.', count='int')
s('sharePrivateItems', '{count} mục riêng tư', pl('1 private item', '{count} private items'), '10o items with videos.', count='int')
s('shareWillSee', 'Sẽ thấy sau khi chia sẻ', 'Will see them after sharing', '10o section.')
s('shareRelatives', '{count} người thân', pl('1 relative', '{count} relatives'), '10o row.', count='int')
s('shareCaregivers', 'Người chăm ({names}) không thấy Kỷ niệm.', 'Caregivers ({names}) don’t see Memories.', '10o note.', names='String')
s('shareNotifyHint', 'Gửi 1 thông báo chung, không kèm ảnh', 'Send 1 general notice, without photos', '10o toggle.')
s('shareN', 'Chia sẻ {count} mục', pl('Share 1 item', 'Share {count} items'), '10o primary.', count='int')
s('shareNPhotos', 'Chia sẻ {count} ảnh', pl('Share 1 photo', 'Share {count} photos'), '10o primary.', count='int')
# 10a3 camera
s('camDest', 'Lưu vào Kỷ niệm của {name}', 'Saving to {name}’s Memories', '10a3 chip.', name='String')
s('camFlash', 'Flash', 'Flash', '10a3.')
s('camVideo', 'VIDEO', 'VIDEO', '10a3 mode.')
s('camPhoto', 'ẢNH', 'PHOTO', '10a3 mode.')
s('camDone', 'Xong ({count})', 'Done ({count})', '10a3.', count='int')
s('camHint', 'Chụp liên tục · bấm Xong để soạn & chia sẻ', 'Keep shooting · tap Done to write & share', '10a3.')
s('camUnavailable', 'Máy này chưa mở được camera.', 'This phone’s camera isn’t available.', '10a3 error.')
s('a11yShutter', 'Chụp', 'Take', '10a3.')

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
