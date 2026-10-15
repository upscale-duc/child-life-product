# Notification centre (D-076 #2): bell (559:57622), EN06 Hộp thông báo (560:2884), EN07 Cài đặt
# thông báo (560:2981). Vietnamese = Figma copy where drawn, English = engineering draft (D-012).
# "Thẻ theo tuổi" is "Giai đoạn của bé" since D-076 #5. Prefix `nt` (G-056 keys ntMemories … are
# reused, not redefined). Idempotent. Usage: python3 tool/notification_strings.py
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

# Bell in the Hôm nay header (559:57622).
s('ntBell', 'Thông báo', 'Notifications', 'Bell button in the Hôm nay header (a11y label, 559:57622).')
s('ntBellUnread', 'Thông báo, {count} chưa đọc', 'Notifications, {count} unread', 'Bell a11y label with unread notifications.', count='int')

# EN06 Hộp thông báo (560:2884).
s('ntInboxTitle', 'Thông báo', 'Notifications', 'EN06 large title.')
s('ntMarkAllRead', 'Đánh dấu đã đọc', 'Mark all read', 'EN06 top-right link.')
s('ntOpenSettings', 'Cài đặt thông báo', 'Notification settings', 'EN06 top bar: opens EN07 (a11y label of the sliders button).')
s('ntFilterAll', 'Tất cả', 'All', 'EN06 chip.')
s('ntFilterReminders', 'Nhắc việc', 'Reminders', 'EN06 chip.')
s('ntFilterBaby', 'Cho bé', 'For baby', 'EN06 chip.')
s('ntFilterFamily', 'Gia đình', 'Family', 'EN06 chip.')
s('ntSectionToday', 'HÔM NAY', 'TODAY', 'EN06 section header.')
s('ntSectionWeek', 'TUẦN NÀY', 'THIS WEEK', 'EN06 section header: the last 7 days.')
s('ntSectionEarlier', 'TRƯỚC ĐÓ', 'EARLIER', 'EN06 section header: older than 7 days (not drawn).')
s('ntUnread', 'Chưa đọc', 'Unread', 'EN06 unread dot (a11y).')
s('ntEmptyTitle', 'Chưa có thông báo nào', 'No notifications yet', 'EN06 empty state title (not drawn).')
s('ntEmptyBody', 'Nhắc việc, lịch tiêm và tin của gia đình sẽ hiện ở đây.', 'Reminders, vaccinations and family news will show up here.', 'EN06 empty state body.')
s('ntEmptyFiltered', 'Chưa có thông báo nào trong mục này.', 'Nothing in this category yet.', 'EN06 empty state for a chip.')
s('ntLoadFailed', 'Chưa tải được thông báo. Thử lại sau nhé.', 'Couldn’t load notifications. Try again later.', 'EN06 load error.')
s('ntKept', 'Thông báo được giữ 90 ngày. Vuốt sang trái để ẩn.', 'Notifications are kept for 90 days. Swipe left to hide one.', 'EN06 footnote.')
s('ntHide', 'Ẩn', 'Hide', 'EN06 swipe action: archive one row.')
s('ntGone', 'Mục này không còn mở được.', 'This can’t be opened any more.', 'Toast: the notification points to a baby you no longer follow.')

# EN07 Cài đặt thông báo (560:2981).
s('ntMaster', 'Thông báo của Child Life', 'Child Life notifications', 'EN07 master card title.')
s('ntMasterOn', 'Đang bật trong cài đặt hệ thống', 'On in system settings', 'EN07 master card: OS permission granted.')
s('ntMasterOff', 'Đang tắt trong cài đặt hệ thống', 'Off in system settings', 'EN07 master card: OS permission not granted.')
s('ntGroupReminders', 'NHẮC VIỆC BẠN ĐẶT', 'REMINDERS YOU SET', 'EN07 group header.')
s('ntGroupRemindersHint', 'Luôn đến đúng giờ, kể cả trong giờ yên lặng', 'Always on time, even in quiet hours', 'EN07 group helper (reminders ring in quiet hours).')
s('ntCare', 'Bú, ngủ, thay tã', 'Feeding, sleep, diapers', 'EN07 row: rule and one-off reminders.')
s('ntCareHint', 'Nhắc theo quy tắc và nhắc một lần', 'Rule and one-off reminders', 'EN07 row helper.')
s('ntVaccines', 'Tiêm chủng', 'Vaccinations', 'EN07 row.')
s('ntVaccinesHint', 'Trước 3 ngày và tối hôm trước lúc 19:00', '3 days before and the evening before at 19:00', 'EN07 row helper: when vaccine reminders ring (P-133).')
s('ntSpending', 'Chi tiêu', 'Spending', 'EN07 row (engineering addition: Chi tiêu pushes).')
s('ntSpendingHint', 'Khoản định kỳ, 80% ngân sách, kết quả nhập', 'Recurring items, 80% of budget, import results', 'EN07 row helper.')
s('ntGroupBaby', 'GỢI Ý CHO BÉ', 'SUGGESTIONS FOR BABY', 'EN07 group header.')
s('ntGroupBabyHint', 'Gom lại, tối đa 2 thông báo mỗi ngày', 'Bundled, at most 2 a day', 'EN07 group helper.')
s('ntRhythm', 'Nhịp lớn lên', 'Growth rhythm', 'EN07 row.')
s('ntRhythmHint', 'Trước mỗi giai đoạn 3 ngày · check-in tối đa 1/ngày', '3 days before each phase · check-in at most once a day', 'EN07 row helper.')
s('ntStages', 'Giai đoạn của bé', 'Baby’s stages', 'EN07 row ("Thẻ theo tuổi", renamed by D-076 #5).')
s('ntStagesHint', 'Khi bé sang tuần / tháng mới', 'When baby starts a new week / month', 'EN07 row helper.')
s('ntMilestones', 'Mốc phát triển', 'Milestones', 'EN07 row.')
s('ntMilestonesHint', 'Khi đến khoảng tuổi thường gặp', 'When the usual age comes', 'EN07 row helper.')
s('ntArticles', 'Bài viết gợi ý', 'Suggested articles', 'EN07 row.')
s('ntArticlesHint', 'Tối đa 1 bài mỗi tuần', 'At most 1 a week', 'EN07 row helper.')
s('ntWeekly', 'Tóm tắt tuần', 'Weekly summary', 'EN07 row.')
s('ntWeeklyHint', 'Chủ nhật 20:30', 'Sunday 20:30', 'EN07 row helper.')
s('ntGroupFamily', 'KỶ NIỆM & GIA ĐÌNH', 'MEMORIES & FAMILY', 'EN07 group header.')
s('ntPhotos', 'Ảnh mới có thể có bé', 'New photos that may include baby', 'EN07 row.')
s('ntPhotosHint', 'Tự lưu kỷ niệm · tối đa 1 lần/ngày', 'Auto-save · at most once a day', 'EN07 row helper.')
s('ntKeepsakes', 'Gợi ý tạo video, thiệp', 'Video and card ideas', 'EN07 row.')
s('ntKeepsakesHint', 'Vào ngày tròn tháng, 100 ngày', 'On month birthdays and at 100 days', 'EN07 row helper.')
s('ntFamilyActivity', 'Hoạt động của gia đình', 'Family activity', 'EN07 row.')
s('ntFamilyActivityHint', 'Thích, xem kỷ niệm', 'Likes, memory views', 'EN07 row helper.')
s('ntGroupTiming', 'THỜI GIAN', 'TIMING', 'EN07 group header.')
s('ntDigest', 'Giờ nhận gợi ý', 'Suggestion time', 'EN07 row: opens EN02.')
s('ntDigestDaily', '{time} mỗi ngày', '{time} daily', 'EN07 row value.', time='String')
s('ntQuiet', 'Giờ yên lặng', 'Quiet hours', 'EN07 row: opens EN02.')
s('ntQuietRange', '{from} – {to}', '{from} – {to}', 'EN07 quiet hours value.', **{'from': 'String', 'to': 'String'})
s('ntSaveFailed', 'Chưa lưu được. Thử lại nhé.', 'Couldn’t save. Please try again.', 'EN07 toast when a switch fails to save.')

root = pathlib.Path(__file__).resolve().parent.parent / 'lib' / 'l10n'
for locale, idx in (('vi', 0), ('en', 1)):
    path = root / f'app_{locale}.arb'
    data = json.loads(path.read_text(), object_pairs_hook=collections.OrderedDict)
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
