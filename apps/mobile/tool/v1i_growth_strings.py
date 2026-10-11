# v1.0 improvement · growth: 20i "Tiêu chuẩn tăng trưởng WHO" and the WHO comparison on 20d.
# Vietnamese = Figma (345:35701), English = engineering draft (D-012). Idempotent.
# Usage: python3 tool/v1i_growth_strings.py
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

def pl(one, other):
    return '{count, plural, =1{' + one + '} other{' + other + '}}'

s('whoStandardsTitle', 'Tiêu chuẩn tăng trưởng', 'Growth standards', '20i title.')
s('whoIntro', 'Theo bảng chuẩn tăng trưởng trẻ em của WHO. Mỗi bé lớn theo nhịp riêng.', 'From the WHO child growth standards. Every baby grows at their own pace.', '20i subtitle.')
s('whoBoy', 'Bé trai', 'Boy', '20i chip.')
s('whoGirl', 'Bé gái', 'Girl', '20i chip.')
s('whoByWeek', 'Theo tuần', 'By week', '20i chip.')
s('whoByMonth', 'Theo tháng', 'By month', '20i chip.')
s('whoAge', 'Tuổi', 'Age', '20i column.')
s('whoLow', 'Thấp', 'Low', '20i column: 3rd percentile.')
s('whoMedian', 'Trung vị', 'Median', '20i column: median.')
s('whoHigh', 'Cao', 'High', '20i column: 97th percentile.')
s('whoBirth', 'Mới sinh', 'Birth', '20i row.')
s('whoWeeks', '{count} tuần', pl('1 week', '{count} weeks'), '20i row.', count='int')
s('whoMonths', '{count} tháng', pl('1 month', '{count} months'), '20i row.', count='int')
s('whoUnitKg', 'Đơn vị: kg. “Thấp” và “Cao” là ngưỡng dưới và ngưỡng trên của khoảng bình thường.', 'Unit: kg. “Low” and “High” are the lower and upper edges of the normal range.', '20i footnote, weight.')
s('whoUnitCm', 'Đơn vị: cm. “Thấp” và “Cao” là ngưỡng dưới và ngưỡng trên của khoảng bình thường.', 'Unit: cm. “Low” and “High” are the lower and upper edges of the normal range.', '20i footnote, length.')
s('whoDoctor', 'Nếu số đo của bé nằm ngoài khoảng bình thường, hãy trao đổi với bác sĩ của bé.', 'If your baby’s measurement is outside the normal range, talk to their doctor.', '20i banner.')
s('whoSource', 'Nguồn: WHO Child Growth Standards · Child Life cập nhật 09/2026', 'Source: WHO Child Growth Standards · Child Life update 09/2026', '20i source line.')
s('whoBabyAt', '{name} {value} · {status}', '{name} {value} · {status}', '20i: the baby’s row.', name='String', value='String', status='String')
s('whoNormal', 'Bình thường', 'Normal', 'Within the WHO normal range (3rd–97th percentile).')
s('whoBelow', 'Dưới mức tham chiếu', 'Below the reference', 'Under the 3rd percentile (20d).')
s('whoAbove', 'Trên mức tham chiếu', 'Above the reference', 'Over the 97th percentile.')
s('whoOpen', 'Xem tiêu chuẩn tăng trưởng WHO', 'See the WHO growth standards', '20d link to 20i.')
s('whoBand', 'Khoảng bình thường', 'Normal range', '20d chart legend.')
s('whoMedianLine', 'Trung vị WHO', 'WHO median', '20d chart legend.')
s('whoLowerEdge', 'Ngưỡng dưới {value}', 'Lower edge {value}', '20d pill below the band.', value='String')
s('whoUpperEdge', 'Ngưỡng trên {value}', 'Upper edge {value}', '20d pill above the band.', value='String')
s('whoBelowWeightNote', 'Cân nặng của {name} đang thấp hơn khoảng thường gặp ở tuổi này. Mỗi bé lớn theo nhịp riêng — bạn nên trao đổi với bác sĩ ở lần khám tới.', '{name}’s weight is below the usual range for this age. Every baby grows at their own pace — it’s worth raising at the next check-up.', '20d note (347:935).', name='String')
s('whoBelowLengthNote', 'Chiều dài của {name} đang thấp hơn khoảng thường gặp ở tuổi này. Mỗi bé lớn theo nhịp riêng — bạn nên trao đổi với bác sĩ ở lần khám tới.', '{name}’s length is below the usual range for this age. Every baby grows at their own pace — it’s worth raising at the next check-up.', '20d note.', name='String')
s('whoAboveWeightNote', 'Cân nặng của {name} đang cao hơn khoảng thường gặp ở tuổi này. Mỗi bé lớn theo nhịp riêng — bạn nên trao đổi với bác sĩ ở lần khám tới.', '{name}’s weight is above the usual range for this age. Every baby grows at their own pace — it’s worth raising at the next check-up.', '20d note.', name='String')
s('whoAboveLengthNote', 'Chiều dài của {name} đang cao hơn khoảng thường gặp ở tuổi này. Mỗi bé lớn theo nhịp riêng — bạn nên trao đổi với bác sĩ ở lần khám tới.', '{name}’s length is above the usual range for this age. Every baby grows at their own pace — it’s worth raising at the next check-up.', '20d note.', name='String')

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
