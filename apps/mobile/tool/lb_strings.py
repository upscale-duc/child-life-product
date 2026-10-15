# Thư viện chăm bé (Figma v1.1 4a–4f) and Giai đoạn của bé (2a–2c; D-076 #5 renamed "Thẻ theo
# tuổi", which the app never says). The app's own copy only: articles and stages come from the
# portal. Vietnamese = Figma, English = engineering draft for owner review (D-012). Idempotent.
# Usage: python3 tool/lb_strings.py
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

def pl(one, other):
    return '{count, plural, =1{' + one + '} other{' + other + '}}'

# 4a Thư viện chăm bé
s('lbTitle', 'Thư viện chăm bé', 'Baby-care library', '4a title; Chăm sóc tile.')
s('lbSaved', 'Đã lưu', 'Saved', '4a pill, 4f title, 4e save pill when saved.')
s('lbSearchHint', 'Tìm: ngủ ngày, nấc, hăm tã…', 'Search: naps, hiccups, nappy rash…', '4a / 4b search placeholder.')
s('lbTopicFeeding', 'Bú & sữa', 'Feeding & milk', '4a topic tile.')
s('lbTopicSleep', 'Giấc ngủ', 'Sleep', '4a topic tile.')
s('lbTopicTeething', 'Mọc răng', 'Teething', '4a topic tile.')
s('lbTopicIllness', 'Sốt & ốm vặt', 'Fever & minor illness', '4a topic tile.')
s('lbTopicDailyCare', 'Chăm hằng ngày', 'Daily care', '4a topic tile.')
s('lbTopicDevelopment', 'Phát triển', 'Development', '4a topic tile.')
s('lbForBaby', 'Hợp với {name} · {age}', 'For {name} · {age}', '4a section: articles for the baby\'s age.', name='String', age='String')
s('lbSeeMore', 'Xem thêm', 'See more', '4a section link → 4b with the age band.')
s('lbRecent', 'Mới cập nhật', 'Recently updated', '4a section.')
s('lbMinutes', '{count} phút đọc', pl('1 min read', '{count} min read'), 'Reading time.', count='int')
s('lbMinutesShort', '{count} phút', pl('1 min', '{count} min'), 'Reading time on cards.', count='int')
s('lbRangeWeeks', '{from}–{to} tuần', '{from}–{to} weeks', 'Age range in weeks.', **{'from': 'int', 'to': 'int'})
s('lbRangeMonths', '{from}–{to} tháng', '{from}–{to} months', 'Age range in months.', **{'from': 'int', 'to': 'int'})
s('lbRangeYears', '{from}–{to} tuổi', '{from}–{to} years', 'Age range in years.', **{'from': 'int', 'to': 'int'})
s('lbStageWeek', '{count} tuần', pl('Week 1', 'Week {count}'), '2a stage covering one week.', count='int')
s('lbStageMonth', '{count} tháng', pl('1 month', '{count} months'), '2a stage covering one month.', count='int')
s('lbReviewedBy', 'Được {reviewer} · {credential} rà soát {month}', 'Reviewed by {reviewer} · {credential}, {month}', '4d byline / 2b footnote once an expert signed it (no claim before, P-141).', reviewer='String', credential='String', month='String')
s('lbIllustrative', 'Nội dung minh hoạ · chờ chuyên môn duyệt', 'Illustrative content · awaiting expert review', 'Badge until an expert approves (D-073 #2).')
s('lbIllustrativeShort', 'Minh hoạ · chờ duyệt', 'Illustrative · not reviewed yet', 'Compact badge on rows and cards.')
s('lbOfflineLibrary', 'Không có kết nối. Thư viện đang hiện bản đã lưu trên máy.', 'No connection. The library is showing the copy saved on this phone.', 'Offline banner (2c pattern).')
s('lbOfflineStages', 'Không có kết nối. Giai đoạn của bé đang hiện bản đã lưu trên máy.', 'No connection. Your baby’s stages are showing the copy saved on this phone.', '2c offline banner (renamed from "Thẻ theo tuổi", D-076 #5).')
s('lbEmptyTitle', 'Thư viện đang được chuẩn bị', 'The library is on its way', 'Nothing published yet.')
s('lbEmptyBody', 'Bài viết sẽ hiện ở đây ngay khi được xuất bản.', 'Articles will appear here as soon as they are published.', 'Nothing published yet.')
s('lbEmptyOfflineTitle', 'Chưa có bản lưu trên máy', 'Nothing saved on this phone yet', 'Offline before the first load.')
s('lbEmptyOfflineBody', 'Kết nối mạng một lần để tải nội dung, sau đó đọc được cả khi không có mạng.', 'Connect once to download the content; after that it reads offline too.', 'Offline before the first load.')

# 4b / 4c
s('lbResults', '{count} bài viết', pl('1 article', '{count} articles'), '4b result count.', count='int')
s('lbFilters', 'Bộ lọc', 'Filters', '4b pill, 4c title.')
s('lbFiltersCount', 'Bộ lọc · {count}', 'Filters · {count}', '4b pill with filters on.', count='int')
s('lbRemoveFilter', 'Bỏ lọc {label}', 'Remove filter {label}', '4b removable chip (a11y).', label='String')
s('lbClearSearch', 'Xoá tìm kiếm', 'Clear search', '4b clear button (a11y).')
s('lbSortTitle', 'Sắp xếp', 'Sort by', '4b sort sheet.')
s('lbSortRelevant', 'Liên quan nhất', 'Most relevant', '4b sort.')
s('lbSortNewest', 'Mới cập nhật', 'Recently updated', '4b sort.')
s('lbSortShortest', 'Đọc nhanh nhất', 'Quickest read', '4b sort.')
s('lbNoResults', 'Không tìm thấy bài phù hợp', 'No matching articles', '4b no results.')
s('lbNoResultsHint', 'Thử từ khoá khác hoặc bỏ bớt bộ lọc.', 'Try other words or fewer filters.', '4b no results.')
s('lbFilterTopic', 'Chủ đề', 'Topic', '4c group.')
s('lbFilterAge', 'Độ tuổi', 'Age', '4c group.')
s('lbFilterTime', 'Thời gian đọc', 'Reading time', '4c group.')
s('lbTimeShort', 'Dưới 3 phút', 'Under 3 min', '4c chip.')
s('lbTimeMedium', '3–6 phút', '3–6 min', '4c chip.')
s('lbTimeLong', 'Trên 6 phút', 'Over 6 min', '4c chip.')
s('lbReset', 'Đặt lại', 'Reset', '4c secondary.')
s('lbShowN', 'Xem {count} bài', pl('See 1 article', 'See {count} articles'), '4c primary (live count).', count='int')

# 4d / 4e
s('lbSave', 'Lưu', 'Save', '4d bar; row bookmark (a11y).')
s('lbUnsave', 'Bỏ lưu', 'Remove from saved', 'Bookmark when saved (a11y).')
s('lbSavedToast', 'Đã lưu · xem trong Thư viện › Đã lưu', 'Saved · find it in Library › Saved', '4e toast.')
s('lbView', 'Xem', 'View', '4e toast action → 4f.')
s('lbUnsavedToast', 'Đã bỏ lưu', 'Removed from saved', 'Toast after unsaving.')
s('lbUndo', 'Hoàn tác', 'Undo', 'Unsave toast action.')
s('lbSaveFailed', 'Chưa lưu được. Thử lại nhé.', 'Couldn’t save. Please try again.', 'Save error toast.')
s('lbTextSize', 'Cỡ chữ', 'Text size', '4d "Aa" (a11y).')
s('lbRelated', 'Bài viết liên quan', 'Related articles', '4d / 2b section.')
s('lbSources', 'Nguồn tham khảo', 'Sources', '4d section, 2b footnote.')
s('lbOpenFirstAid', 'Dấu hiệu nguy hiểm? Mở Sơ cứu trẻ em', 'Danger signs? Open child first aid', '4d "Khi nào nên hỏi bác sĩ" callout link (the guide works offline).')
s('lbArticleFootnote', 'Nội dung tham khảo, không thay thế chẩn đoán của bác sĩ. Mỗi bé phát triển theo nhịp riêng.', 'For reference only; it does not replace a doctor’s diagnosis. Every baby grows at their own pace.', '4d footnote.')
s('lbArticleMissing', 'Bài viết này không còn trong thư viện', 'This article is no longer in the library', 'Unknown or withdrawn article.')
s('lbArticleMissingBody', 'Bài có thể đã được gỡ để cập nhật. Mở lại Thư viện chăm bé.', 'It may have been taken down for an update. Open the library again.', 'Unknown or withdrawn article.')

# 4f
s('lbSavedToday', '{topic} · lưu hôm nay', '{topic} · saved today', '4f row meta.', topic='String')
s('lbSavedOn', '{topic} · lưu {date}', '{topic} · saved {date}', '4f row meta.', topic='String', date='String')
s('lbSavedEmptyTitle', 'Chưa lưu bài nào', 'Nothing saved yet', '4f empty.')
s('lbSavedEmptyBody', 'Bấm Lưu khi đọc một bài để giữ lại đây.', 'Tap Save while reading an article to keep it here.', '4f empty.')
s('lbUpdated', 'Bài “{title}” vừa được cập nhật. Mở để xem bản mới.', '“{title}” has been updated. Open it to see the new version.', '4f banner (no expert claim: it may still be illustrative).', title='String')

# 2a–2c Giai đoạn của bé
s('lbStagesTitle', 'Giai đoạn của bé', 'Your baby’s stages', '2a title; Chăm sóc tile (D-076 #5, never "thẻ").')
s('lbStagesIntro', 'Gợi ý ngắn cho từng giai đoạn. Mỗi bé phát triển theo nhịp riêng.', 'Short ideas for each stage. Every baby grows at their own pace.', '2a intro (no review claim).')
s('lbHere', 'Bé đang ở đây', 'Baby is here', '2a current stage pill.')
s('lbDoing', 'Bé đang thế nào', 'How your baby is doing', '2b card.')
s('lbTry', 'Ba mẹ có thể thử', 'Things to try together', '2b card.')
s('lbMilestones', 'Mốc thường gặp', 'Common milestones', '2b section (when Mốc phát triển is available).')
s('lbWeekCardSub', 'Gợi ý cho tuần này trong Nhịp lớn lên', 'This week’s ideas in Growing rhythm', '2b link to "Tuần này của {bé}" (D-072 #5).')
s('lbStageFootnote', 'Mỗi bé phát triển theo nhịp riêng.', 'Every baby develops at their own pace.', '2b footnote.')
s('lbStageMissing', 'Giai đoạn này không còn trong ứng dụng', 'This stage is no longer available', 'Unknown or withdrawn stage.')
s('lbStageMissingBody', 'Mở lại Giai đoạn của bé để xem các giai đoạn hiện có.', 'Open Your baby’s stages again to see what is available.', 'Unknown or withdrawn stage.')
s('lbStagesEmptyTitle', 'Nội dung theo giai đoạn đang được chuẩn bị', 'Stage content is on its way', '2a nothing published yet.')
s('lbStagesEmptyBody', 'Gợi ý cho từng giai đoạn sẽ hiện ở đây ngay khi được xuất bản.', 'Ideas for each stage will appear here as soon as they are published.', '2a nothing published yet.')
s('lbNoDobTitle', 'Thêm ngày sinh của bé', 'Add your baby’s date of birth', '2c card.')
s('lbNoDobBody', 'Để Child Life gợi ý đúng theo tuổi, nhắc Wonder Week và mốc phát triển.', 'So Child Life can suggest what fits their age and remind you of Wonder Weeks and milestones.', '2c card.')
s('lbNoDobAction', 'Thêm ngày sinh', 'Add date of birth', '2c tinted button → Sửa hồ sơ bé.')
s('lbNoDobViewerTitle', 'Chưa biết bé đang ở giai đoạn nào', 'Your baby’s stage isn’t known here', '2c for a member who may not see the date of birth.')
s('lbNoDobViewer', 'Bạn chưa được xem ngày sinh của {name}, nên app chưa đánh dấu giai đoạn hiện tại. Bạn vẫn đọc được mọi giai đoạn.', 'You can’t see {name}’s date of birth, so the current stage isn’t marked. You can still read every stage.', '2c for caregivers / relatives without "Thông tin bé".', name='String')

# Hôm nay "Dành cho bé hôm nay" small cards (today_for_baby.dart carousel)
s('lbTodayStageKicker', 'Giai đoạn của bé · {range}', 'Your baby’s stage · {range}', 'Today card kicker for the current stage.', range='String')
s('lbTodayStageAction', 'Xem giai đoạn', 'See this stage', 'Today card action → 2b.')
s('lbTodayRead', 'Đọc bài', 'Read', 'Today article card action → 4d.')

# Existing strings renamed by D-076 #5 (and the library tile's review claim, P-141).
RENAME = {
    'careAgeCards': ('Giai đoạn của bé', 'Your baby’s stages', 'Chăm sóc tile → Giai đoạn của bé (D-076 #5; formerly "Thẻ theo tuổi").'),
    'careLibrarySub': ('Bài viết chăm bé theo tuổi', 'Baby-care articles by age', 'Chăm sóc tile subtitle (no review claim until reviewed, P-141).'),
    'careAgeCardsSub': ('Gợi ý cho từng tuần, từng tháng', 'Ideas week by week, month by month', 'Chăm sóc tile subtitle.'),
    'careLibrary': ('Thư viện chăm bé', 'Baby-care library', 'Chăm sóc tile → Thư viện chăm bé.'),
}

root = pathlib.Path(__file__).resolve().parent.parent / 'lib' / 'l10n'
for locale, idx in (('vi', 0), ('en', 1)):
    path = root / f'app_{locale}.arb'
    data = json.loads(path.read_text(), object_pairs_hook=collections.OrderedDict)
    for key, (vi, en, desc) in RENAME.items():
        if key not in data:
            raise SystemExit(f'{key} is gone: check the rename')
        data[key] = (vi, en)[idx]
        if locale == 'vi':
            data['@' + key] = collections.OrderedDict(description=desc)
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
print(len(S), 'strings,', len(RENAME), 'renamed')
