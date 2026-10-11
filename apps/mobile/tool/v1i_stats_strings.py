# v1.0 improvement · stats: 20g "Bú mỗi ngày" (feeds per day, bottle vs breast) and 20h "Tổng giờ
# ngủ mỗi ngày" (total sleep per day, night vs day). Vietnamese = Figma (345:35701), English =
# engineering draft (D-012). Idempotent. Usage: python3 tool/v1i_stats_strings.py
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

s('feedsPerDayTitle', 'Bú mỗi ngày', 'Feeds per day', '20g card.')
s('feedsPerDayHint', 'Số cữ bú bình và bú mẹ · {days} ngày', 'Bottle and breast feeds · {days} days', '20g card subtitle.', days='int')
s('feedsDayTip', '{day} · {bottles} bình {ml} ml · {breasts} mẹ {minutes}p', '{day} · {bottles} bottle {ml} ml · {breasts} breast {minutes}m', '20g selected-day callout.', day='String', bottles='int', ml='int', breasts='int', minutes='int')
s('feedsAvgLine', 'TB {count} cữ', 'Avg {count}', '20g average line.', count='int')
s('bottleShareLine', 'Bú bình {pct}% · {ml} ml/ngày', 'Bottle {pct}% · {ml} ml/day', '20g share.', pct='int', ml='int')
s('breastShareLine', 'Bú mẹ {pct}% · {minutes} phút/ngày', 'Breast {pct}% · {minutes} min/day', '20g share.', pct='int', minutes='int')
s('kpiFeedsPerDay', 'TB mỗi ngày', 'Avg per day', '20g KPI caption.')
s('kpiBottlePerDay', 'Bú bình/ngày', 'Bottle/day', '20g KPI caption.')
s('kpiBreastPerDay', 'Bú mẹ/ngày', 'Breast/day', '20g KPI caption.')
s('sleepPerDayTitle', 'Tổng giờ ngủ mỗi ngày', 'Total sleep per day', '20h card.')
s('sleepPerDayHint', 'Đêm 18:00–06:00 · Ngày 06:00–18:00', 'Night 18:00–06:00 · Day 06:00–18:00', '20h card subtitle.')
s('sleepDayTip', '{day} · {total} · đêm {night} · ngày {daytime}', '{day} · {total} · night {night} · day {daytime}', '20h selected-day callout.', day='String', total='String', night='String', daytime='String')
s('sleepAvgLine', 'TB {total}', 'Avg {total}', '20h average line.', total='String')
s('legendNightSleep', 'Ngủ đêm', 'Night sleep', '20h legend.')
s('legendDaySleep', 'Ngủ ngày', 'Day sleep', '20h legend.')
s('sleepSteadyInsight', 'Tổng giờ ngủ ổn định quanh {hours} giờ/ngày trong {days} ngày qua.', 'Total sleep has stayed around {hours} h a day over the last {days} days.', '20h insight when days differ by 2 h or less.', hours='int', days='int')
s('sleepRangeInsight', 'Tổng giờ ngủ từ {min} đến {max} mỗi ngày trong {days} ngày qua.', 'Total sleep ran from {min} to {max} a day over the last {days} days.', '20h insight otherwise.', min='String', max='String', days='int')

# 20g type / range pickers and the per-type cards (346:354, 346:590, 391:3185, 391:3373).
s('feedKindTitle', 'Loại bú', 'Feed type', '20g type sheet title.')
s('feedKindAll', 'Tất cả', 'All', '20g type: all feeds.')
s('feedKindAllHint', 'Bú bình và bú mẹ', 'Bottle and breast', '20g type caption.')
s('feedKindBottleHint', 'Theo lượng sữa (ml)', 'By milk volume (ml)', '20g type caption.')
s('feedKindBreastHint', 'Theo thời gian bú (phút)', 'By feeding time (minutes)', '20g type caption.')
s('rangeTitle', 'Khoảng thời gian', 'Time range', '20g range sheet title.')
s('rangeCustom', 'Tuỳ chọn', 'Custom', '20g range: custom.')
s('rangeCustomHint', 'Chọn từ ngày – đến ngày', 'Choose from – to date', '20g range caption.')
s('rangeSpan', '{from} – {to}', '{from} – {to}', '20g range caption / pill.', **{'from': 'String', 'to': 'String'})
s('kpiPerFeed', 'TB mỗi cữ', 'Avg per feed', '20g KPI caption.')
s('milkPerDayTitle', 'Lượng sữa mỗi ngày', 'Milk per day', '20g Bú bình card.')
s('milkPerDayHint', 'Tổng ml bú bình · {days} ngày', 'Total bottle ml · {days} days', '20g Bú bình card subtitle.', days='int')
s('milkDayTip', '{day} · {ml} ml · {count} cữ', '{day} · {ml} ml · {count} feeds', '20g Bú bình callout.', day='String', ml='int', count='int')
s('mlAvgLine', 'TB {ml} ml', 'Avg {ml} ml', '20g Bú bình average line.', ml='int')
s('legendExpressedMilk', 'Sữa mẹ vắt', 'Expressed milk', '20g Bú bình legend.')
s('legendFormula', 'Sữa công thức', 'Formula', '20g Bú bình legend.')
s('breastPerDayTitle', 'Thời gian bú mẹ mỗi ngày', 'Breastfeeding time per day', '20g Bú mẹ card.')
s('breastPerDayHint', 'Tổng phút · bên trái và bên phải', 'Total minutes · left and right', '20g Bú mẹ card subtitle.')
s('breastDayTip', '{day} · {minutes} phút · {count} cữ', '{day} · {minutes} min · {count} feeds', '20g Bú mẹ callout.', day='String', minutes='int', count='int')
s('minutesAvgLine', 'TB {minutes} phút', 'Avg {minutes} min', '20g Bú mẹ average line.', minutes='int')
s('legendLeftSide', 'Bên trái', 'Left', '20g Bú mẹ legend.')
s('legendRightSide', 'Bên phải', 'Right', '20g Bú mẹ legend.')
s('breastByTimeNote', 'Bú mẹ khó đo lượng sữa, nên app thống kê bằng thời gian bú.', 'Breast milk is hard to measure, so the app counts breastfeeding by time.', '20g Bú mẹ banner.')
s('minutesAndFeeds', '{minutes} phút · {count} cữ', '{minutes} min · {count} feeds', '20g Bú mẹ day/night detail.', minutes='int', count='int')
s('lastNightBreastInsight', 'Đêm qua bú mẹ {count} cữ, {minutes} phút ({time}).', 'Last night: {count} breastfeeds, {minutes} min ({time}).', '20g Bú mẹ insight.', count='int', minutes='int', time='String')

root = pathlib.Path(__file__).resolve().parent.parent / 'lib' / 'l10n'
for locale, idx in (('vi', 0), ('en', 1)):
    path = root / f'app_{locale}.arb'
    data = json.loads(path.read_text(), object_pairs_hook=collections.OrderedDict)
    for key, (vi, en, desc, ph) in S.items():
        # Never take over another screen's key (whoTitle once clobbered 10a's title).
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
