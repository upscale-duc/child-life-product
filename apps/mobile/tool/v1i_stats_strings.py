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
