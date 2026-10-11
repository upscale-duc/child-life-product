# v1.0 improvement · Chăm sóc (Care) tab, NavBar v1.0.1, Tôi from the avatar, Tuỳ chỉnh Hôm nay
# (370:1246). Vietnamese = Figma, English = engineering draft (D-012). Idempotent.
# Usage: python3 tool/v1i_care_strings.py
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

def pl(one, other):
    return '{count, plural, =1{' + one + '} other{' + other + '}}'

s('tabCare', 'Chăm sóc', 'Care', 'NavBar v1.0.1 tab.')
s('a11yOpenMe', 'Tôi', 'Me', 'Header avatar → Tôi (370:1898).')
s('careTitle', 'Chăm sóc', 'Care', 'Care tab title (370:1971).')
s('careSearchHint', 'Tìm trong Chăm sóc…', 'Search in Care…', 'Care search field.')
s('careDaily', 'Chăm hằng ngày', 'Daily care', 'Care section.')
s('careReminders', 'Nhắc nhở', 'Reminders', 'Care tile.')
s('careRemindersOn', '{count} nhắc đang bật', pl('1 reminder on', '{count} reminders on'), 'Care tile subtitle.', count='int')
s('careRemindersMine', '{count} nhắc giao cho bạn', pl('1 reminder for you', '{count} reminders for you'), 'Care tile subtitle, caregiver (370:2174).', count='int')
s('careStats', 'Thống kê', 'Statistics', 'Care tile.')
s('careStatsSub', 'Bú, ngủ theo ngày', 'Feeding, sleep by day', 'Care tile subtitle.')
s('careHistory', 'Lịch sử', 'History', 'Care tile.')
s('careHistorySub', 'Mọi lần đã ghi', 'Every logged entry', 'Care tile subtitle.')
s('careGrowth', 'Tăng trưởng', 'Growth', 'Care tile.')
s('careGrowthSub', 'Cân nặng, chiều dài', 'Weight, length', 'Care tile subtitle.')
s('careSoon', 'Sớm ra mắt', 'Coming soon', 'Care section and badge.')
s('careSoonToast', 'Phần này sẽ có trong bản cập nhật tới.', 'This arrives in a coming update.', 'Tap on a coming-soon tile.')
s('careWonderWeek', 'Wonder Week', 'Wonder Week', 'Coming-soon tile.')
s('careWonderWeekSub', 'Giai đoạn phát triển dự kiến', 'Expected developmental phases', 'Coming-soon tile.')
s('careAgeCards', 'Thẻ theo tuổi', 'Cards by age', 'Coming-soon tile.')
s('careAgeCardsSub', 'Gợi ý theo tuổi của bé', 'Ideas for your baby’s age', 'Coming-soon tile.')
s('careMilestones', 'Mốc phát triển', 'Milestones', 'Coming-soon tile.')
s('careMilestonesSub', 'Ghi lại lần đầu của con', 'Record your child’s firsts', 'Coming-soon tile.')
s('careLibrary', 'Thư viện chăm bé', 'Baby-care library', 'Coming-soon tile.')
s('careLibrarySub', 'Bài viết được chuyên môn rà soát', 'Expert-reviewed articles', 'Coming-soon tile.')
s('careSolids', 'Ăn dặm', 'Solids', 'Coming-soon tile.')
s('careSolidsSub', 'Nhật ký & thư viện ăn dặm', 'Solids diary & library', 'Coming-soon tile.')
s('careSettings', 'Cài đặt', 'Settings', 'Care section.')
s('careTracking', 'Tuỳ chỉnh theo dõi', 'Customise tracking', 'Care settings row.')
s('careTrackingSub', 'Chọn loại hoạt động cần ghi', 'Choose what to log', 'Care settings row.')
s('careNotifications', 'Thông báo', 'Notifications', 'Care settings row.')
s('careNotificationsSub', 'Nhắc nhở, gia đình', 'Reminders, family', 'Care settings row.')
s('careStatsPick', 'Xem thống kê', 'See statistics', 'Sheet title when tapping Thống kê.')
s('careNoResults', 'Không có mục nào khớp.', 'Nothing matches.', 'Care search, no result.')
s('todayCustomize', 'Tuỳ chỉnh', 'Customise', 'Hôm nay pill (370:1248).')
s('customizeTitle', 'Tuỳ chỉnh Hôm nay', 'Customise Today', 'Sheet title (370:1525).')
s('customizeIntro', 'Bật, tắt và kéo để sắp xếp những gì hiện trên Hôm nay.', 'Turn on, turn off and drag to arrange what shows on Today.', 'Sheet body.')
s('sectionTiles', 'Ô theo dõi nhanh', 'Quick tracking tiles', 'Today section.')
s('sectionTilesSub', 'Bú, ngủ, tã, hút sữa, tăng trưởng', 'Feeding, sleep, diapers, pumping, growth', 'Today section subtitle.')
s('sectionReminders', 'Nhắc việc sắp tới', 'Upcoming reminders', 'Today section.')
s('sectionRhythm', 'Nhịp trong ngày', 'Daily rhythm', 'Today section.')
s('sectionRhythmSub', 'Biểu đồ 24 giờ', '24-hour chart', 'Today section subtitle.')
s('visibleTiles', 'Ô theo dõi hiển thị', 'Visible tracking tiles', 'Customise sheet section.')
s('customizeReset', 'Đặt lại', 'Reset', 'Customise sheet secondary.')
s('customizeDone', 'Xong', 'Done', 'Customise sheet primary.')
s('a11yDragToReorder', 'Kéo để sắp xếp', 'Drag to reorder', 'Drag handle a11y.')

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
