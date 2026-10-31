# Hiểu con · "Điều đáng chú ý" (D-150, D-151; Figma 1104:1883 AI01–AI06). Vietnamese = the
# Figma copy where it fits the computed facts, English = engineering draft (D-012). Idempotent.
# Usage: python3 tool/insight_strings.py
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

s('hcTitle', 'Hiểu con', 'Know your baby', 'Hiểu con: feature and screen title (D-151 #2).')
s('hcUpdated', 'Từ ghi nhận của gia đình · cập nhật {time}', "From your family's logs · updated {time}", 'Hiểu con: under the title; time of the computation.', time='String')
s('hcNotable', 'Điều đáng chú ý', 'Worth noticing', 'Insight card label and section title (D-151 #2).')
s('hcLongestUp', 'Khoảng ngủ đêm dài nhất đang dài hơn', 'Longest night stretch is getting longer', 'S1 title, longer than the week before.')
s('hcLongestDown', 'Khoảng ngủ đêm dài nhất đang ngắn hơn', 'Longest night stretch is getting shorter', 'S1 title, shorter than the week before.')
s('hcTotalUp', 'Đêm gần đây ngủ nhiều hơn', 'More night sleep lately', 'S2 title, more than the week before.')
s('hcTotalDown', 'Đêm gần đây ngủ ít hơn', 'Less night sleep lately', 'S2 title, less than the week before.')
s('hcFeedsUp', 'Đêm gần đây bú nhiều cữ hơn', 'More night feeds lately', 'F3 title, more than the week before.')
s('hcFeedsDown', 'Đêm gần đây bú ít cữ hơn', 'Fewer night feeds lately', 'F3 title, fewer than the week before.')
s('hcVsBefore', 'TB {value} · tuần trước {baseline}', 'Avg {value} · week before {baseline}', 'Insight summary line: recent average and the week before.', value='String', baseline='String')
s('hcFeedOne', '1 cữ', '1 feed', 'A night-feed average of exactly one.')
s('hcFeedMany', '{n} cữ', '{n} feeds', 'A night-feed average other than one ("2", "1,4").', n='String')
s('hcMore', 'nhiều hơn {amount}', '{amount} more', 'Spoken form of the +delta chip.', amount='String')
s('hcLess', 'ít hơn {amount}', '{amount} less', 'Spoken form of the −delta chip.', amount='String')
s('hcBasedOn', 'Dựa trên {valid}/{total} đêm có ghi', 'Based on {valid} of {total} nights logged', 'Coverage line of an insight (instead of a confidence level).', valid='int', total='int')
s('hcLegendBefore', 'Tuần trước', 'Week before', 'Chart legend: the baseline nights.')
s('hcLegendRecent', 'Gần đây', 'Recent', 'Chart legend: the recent nights.')
s('hcLegendAverage', 'Trung bình', 'Average', 'Chart legend: the dashed average lines.')
s('hcNightsLogged', '{valid}/{total} đêm có ghi', '{valid}/{total} nights logged', 'Chart legend end and the first basis row.', valid='int', total='int')
s('hcChartA11y', 'Gần đây trung bình {value}, tuần trước {baseline}, {valid} trên {total} đêm có ghi', 'Recent average {value}, the week before {baseline}, {valid} of {total} nights logged', 'Screen-reader summary of the comparison chart.', value='String', baseline='String', valid='int', total='int')
s('hcSleep', 'Giấc ngủ', 'Sleep', 'Insight detail: category above the title.')
s('hcFeeds', 'Bú', 'Feeding', 'Insight detail: category above the title.')
s('hcKicker', '{category} · {range}', '{category} · {range}', 'Insight detail: category and the recent nights.', category='String', range='String')
s('hcAvgRecent', 'Trung bình {n} đêm gần đây. Tuần trước: {baseline}.', 'Average of the last {n} nights. The week before: {baseline}.', 'Insight detail: under the big value.', n='int', baseline='String')
s('hcBasis', 'Dựa trên', 'Based on', 'Insight detail: basis section title.')
s('hcLeftOut', 'Đêm {dates} chưa ghi đủ nên không tính', 'Not counted: {dates} (not fully logged)', 'Basis row: recent nights left out.', dates='String')
s('hcNightWindow', 'Đêm từ {from} đến {to}', 'Night: {from} to {to}', 'Basis row: the night window (D-151 #1).', **{'from': 'String', 'to': 'String'})
s('hcMeasureLongest', 'Khoảng ngủ liền dài nhất mỗi đêm', 'The longest single sleep each night', 'Basis row: what S1 measures.')
s('hcMeasureTotal', 'Tổng giờ ngủ trong đêm', 'Total sleep during the night', 'Basis row: what S2 measures.')
s('hcMeasureFeeds', 'Số cữ bú bình và bú mẹ trong đêm', 'Bottle and breast feeds during the night', 'Basis row: what F3 measures.')
s('hcComparedWith', 'So với {n} đêm trước đó', 'Compared with the {n} nights before', 'Basis row: the baseline.', n='int')
s('hcLoggedBy', 'Ghi bởi {names}', 'Logged by {names}', 'Basis row: who logged the recent nights (never ranked).', names='String')
s('hcSeeSleepStats', 'Xem thống kê giấc ngủ', 'See sleep statistics', 'Insight detail primary button (sleep kinds).')
s('hcSeeFeedStats', 'Xem thống kê bú', 'See feeding statistics', 'Insight detail primary button (night feeds).')
s('hcDisclaimer', 'Thông tin tính từ ghi nhận của gia đình, không thay cho lời khuyên của bác sĩ.', "Figures come from your family's logs and don't replace your doctor's advice.", 'Hiểu con: the one health note per screen (D-102).')
s('hcUpdating', 'Đang tính lại theo ghi nhận vừa sửa', 'Recalculating with the latest changes', 'A record of the window changed: figures hidden until the server recomputes.')
s('hcUpdatingBody', 'Vài phút nữa sẽ có số mới.', 'New figures in a few minutes.', 'Second line of the recalculating notice.')
s('hcSparseTitle', 'Chưa đủ đêm để thấy nhịp của {name}', "Not enough nights yet to see {name}'s pattern", 'AI04: not enough logged nights.', name='String')
s('hcSparseBody', 'Cứ ghi như bình thường. Khi đủ đêm có ghi, Child Life sẽ cho bạn biết điều gì đang thay đổi.', "Keep logging as usual. Once there are enough logged nights, Child Life will tell you what's changing.", 'AI04 body.')
s('hcSparseProgress', '{valid}/{needed} đêm có ghi đủ', '{valid}/{needed} fully logged nights', 'AI04 progress label.', valid='int', needed='int')
s('hcNothing', 'Tuần này giấc ngủ đêm và cữ bú đêm không có thay đổi đáng chú ý.', 'No notable change in night sleep or night feeds this week.', 'Hiểu con: enough nights, nothing worth saying.')
s('hcByActivity', 'Theo từng việc', 'By activity', 'Hiểu con: per-activity section (last 7 complete days).')
s('hcSleepPerDay', 'TB {duration} mỗi ngày', 'Avg {duration} a day', 'Per-activity row: sleep.', duration='String')
s('hcFeedsPerDay', 'TB {count} cữ mỗi ngày', 'Avg {count} feeds a day', 'Per-activity row: bottle and breast feeds.', count='String')
s('hcBottlePerDay', 'bình {ml} ml', 'bottle {ml} ml', 'Per-activity row: bottle ml a day, after the feed count.', ml='String')
s('hcNoLogs7', 'Chưa có ghi trong 7 ngày qua', 'Nothing logged in the last 7 days', 'Per-activity row with no record in the week (missing is never zero).')
s('hcDiapersPerDay', 'TB {count} lần mỗi ngày', 'Avg {count} a day', 'Per-activity row: diapers.', count='String')
s('hcTeaserSleep', 'Có một thay đổi về giấc ngủ đêm của {name} tuần này', "Something changed in {name}'s night sleep this week", 'Free invite on Hôm nay (D-151 #9): the kind only, no figures.', name='String')
s('hcTeaserFeeds', 'Có một thay đổi về cữ bú đêm của {name} tuần này', "Something changed in {name}'s night feeds this week", 'Free invite on Hôm nay (D-151 #9): the kind only, no figures.', name='String')
s('hcAskLumi', 'Hỏi Lumi về điều này', 'Ask Lumi about this', 'Insight detail: opens Lumi with the "how is it worked out" question (D-151 #7).')
s('hcAskLumiNote', 'Câu hỏi này không tốn lượt hỗ trợ AI', 'This question uses no AI credits', 'Under the Lumi button: the prefilled question is read by the rules (0 credits).')
s('hcAskLumiSleep', 'Điều đáng chú ý về giấc ngủ đêm được tính thế nào?', 'How was "Worth noticing" about night sleep worked out?', 'Prefilled Lumi question (sleep insights); must keep "Điều đáng chú ý" / "Worth noticing" (the rule read).')
s('hcAskLumiFeeds', 'Điều đáng chú ý về cữ bú đêm được tính thế nào?', 'How was "Worth noticing" about night feeds worked out?', 'Prefilled Lumi question (night feeds); must keep "Điều đáng chú ý" / "Worth noticing" (the rule read).')
s('hcFeedbackTitle', 'Thông tin này có ích không?', 'Was this useful?', 'Insight detail: feedback block title.')
s('hcHelpful', 'Có ích', 'Useful', 'Insight feedback choice.')
s('hcNotHelpful', 'Chưa có ích', 'Not useful', 'Insight feedback choice.')
s('hcMute', 'Không hiện loại thông tin này nữa', "Don't show this kind again", 'Insight feedback: hide this kind of insight for me.')
s('hcThanks', 'Cảm ơn bạn đã cho biết', 'Thanks for letting us know', 'Toast after insight feedback.')
s('hcMuted', 'Đã ẩn loại thông tin này', 'This kind is hidden', 'Toast after muting an insight kind.')
s('hcWeekNotable', 'Điều đáng chú ý nhất', 'Most worth noticing', 'Tổng kết tuần: the week\'s top insight (AI06).')
s('hcOpen', 'Mở Hiểu con', 'Open Know your baby', 'Screen-reader hint on the Hôm nay card.')

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
