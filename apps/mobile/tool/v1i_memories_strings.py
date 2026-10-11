# v1.0 improvement · Nhật ký gọn hơn (382:2793): Ảnh by week / month of age, Hiển thị, Đi tới tuần.
# Vietnamese = Figma, English = engineering draft (D-012). Idempotent.
# Usage: python3 tool/v1i_memories_strings.py
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

U = collections.OrderedDict()

s('photoByTitle', 'Xem ảnh theo', 'View photos by', 'SH Ảnh · Xem theo (391:2761) title.')
s('photoByWeek', 'Tuần tuổi', 'Week of age', 'Grouping option.')
s('photoByWeekSub', 'Tuần 1, tuần 2… hợp với năm đầu đời', 'Week 1, week 2… suits the first year', 'Grouping option caption.')
s('photoByAgeMonth', 'Tháng tuổi', 'Month of age', 'Grouping option.')
s('photoByAgeMonthSub', '1 tháng, 2 tháng…', '1 month, 2 months…', 'Grouping option caption.')
s('photoByMonth', 'Tháng trong năm', 'Calendar month', 'Grouping option.')
s('photoByMonthSub', 'Tháng 10, tháng 9…', 'October, September…', 'Grouping option caption.')
s('photoPillWeek', 'Theo tuần tuổi', 'By week of age', '10b grouping pill.')
s('photoPillAgeMonth', 'Theo tháng tuổi', 'By month of age', '10b grouping pill.')
s('photoPillMonth', 'Theo tháng', 'By month', '10b grouping pill.')
s('photoShowTitle', 'Hiển thị', 'Show', 'SH Ảnh · Loại (391:2888) title.')
s('photoShowAll', 'Ảnh & video', 'Photos & videos', 'Type option and pill.')
s('photoShowPhotos', 'Chỉ ảnh', 'Photos only', 'Type option and pill.')
s('photoShowVideos', 'Chỉ video', 'Videos only', 'Type option and pill.')
s('photoShowFavorites', 'Đã yêu thích', 'Favourites', 'Type option and pill.')
s('photoGotoWeek', 'Đi tới tuần', 'Go to week', 'SH Ảnh · Chọn tuần (391:3028) title.')
s('photoGotoAgeMonth', 'Đi tới tháng tuổi', 'Go to month of age', 'Jump sheet title, month of age.')
s('photoAgeMonth', 'Tháng thứ {month}', 'Month {month}', 'Section title, month of age.', month='int')
s('photoScrubWeek', 'Tuần {week}', 'Week {week}', 'Scrubber pill.', week='int')
s('photoScrubAgeMonth', 'Tháng {month}', 'Month {month}', 'Scrubber pill, month of age.', month='int')
s('photoSelectSection', 'Chọn tất cả', 'Select all', 'Select a whole week / month of age.')

root = pathlib.Path(__file__).resolve().parent.parent / 'lib' / 'l10n'
for locale, idx in (('vi', 0), ('en', 1)):
    path = root / f'app_{locale}.arb'
    data = json.loads(path.read_text(), object_pairs_hook=collections.OrderedDict)
    for key, values in U.items():
        if key not in data:
            raise SystemExit(f'{key} is not an existing id')
        data[key] = values[idx]
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
print(len(S), 'strings,', len(U), 'updated')
