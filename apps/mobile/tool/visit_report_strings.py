# Sprint Premium U1 "Chuẩn bị đi khám" (owner, 2026-10-30; docs/audits/2026-10-29-lumi-ca-nhan-hoa-nhip.md §4).
# Vietnamese is the source; English is an engineering draft for owner review (D-012).
# Idempotent. Usage: python3 tool/visit_report_strings.py && flutter gen-l10n
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

NOTE = ' EN is an engineering draft for owner review.'
U1 = 'U1 Chuẩn bị đi khám: '

s('vrTitle', 'Chuẩn bị đi khám', 'Doctor visit summary', U1 + 'page title and the Chăm sóc tile.' + NOTE)
s('vrTileSub', 'Tóm tắt cho bác sĩ', 'A summary for the doctor', U1 + 'under the Chăm sóc tile.' + NOTE)
s('vrCorrectedAge', 'Tuổi hiệu chỉnh {age}', 'Corrected age {age}',
  U1 + 'a preterm baby\'s corrected age (D3, expert review 2026-10-30).' + NOTE, age='String')
s('vrMadeOn', 'Lập ngày {date}', 'Made on {date}', U1 + 'the date of the summary.' + NOTE, date='String')
s('vrGrowth', 'Tăng trưởng', 'Growth', U1 + 'section.' + NOTE)
s('vrWeight', 'Cân nặng', 'Weight', U1 + 'growth row.' + NOTE)
s('vrLength', 'Chiều dài', 'Length', U1 + 'growth row.' + NOTE)
s('vrHead', 'Vòng đầu', 'Head', U1 + 'growth row.' + NOTE)
s('vrMeasuredOn', 'Đo ngày {date}', 'Measured {date}', U1 + 'when the latest measurement was taken.' + NOTE, date='String')
s('vrNoGrowth', 'Chưa có số đo nào', 'No measurements yet', U1 + 'growth section, nothing logged.' + NOTE)
s('vrCare', 'Ăn, ngủ, thay tã · trung bình mỗi ngày', 'Feeds, sleep, diapers · daily average',
  U1 + 'section: each row is the last 7 complete days, the line under it the 7 days before.' + NOTE)
s('vrBefore', 'Tuần trước: {value}', 'Week before: {value}', U1 + 'the same row for the 7 days before.' + NOTE, value='String')
s('vrFeedsMl', '{count} cữ · {ml} ml', '{count} feeds · {ml} ml', U1 + 'bottle feeds and millilitres per day.' + NOTE,
  count='String', ml='String')
s('vrFeedsMin', '{count} cữ · {minutes} phút', '{count} feeds · {minutes} min',
  U1 + 'breastfeeds and minutes per day.' + NOTE, count='String', minutes='String')
s('vrDiapers', 'Ướt {wet} · Bẩn {dirty}', 'Wet {wet} · Dirty {dirty}', U1 + 'diapers per day.' + NOTE,
  wet='String', dirty='String')
s('vrSleepSparse', 'Chưa đủ ngày ghi đủ', 'Not enough complete days',
  U1 + 'sleep average needs enough complete days; missing is never zero.' + NOTE)
s('vrVaccines', 'Tiêm chủng', 'Vaccines', U1 + 'section.' + NOTE)
s('vrVaccinesGiven', 'Đã tiêm {given}/{total} mũi đến hạn', '{given} of {total} doses due so far given', U1 + 'vaccine progress: doses due by today only (a newborn is never "0/30").' + NOTE,
  given='int', total='int')
s('vrVaccineNext', 'Mũi tiếp theo', 'Next doses', U1 + 'vaccine row label.' + NOTE)
s('vrVaccineOverdue', 'Quá hẹn', 'Overdue', U1 + 'vaccine row label.' + NOTE)
s('vrQuestions', 'Câu hỏi cho bác sĩ', 'Questions for the doctor', U1 + 'section.' + NOTE)
s('vrQuestionHint', 'Thêm điều bạn muốn hỏi…', 'Add something to ask…', U1 + 'the question field.' + NOTE)
s('vrQuestionAdd', 'Thêm', 'Add', U1 + 'adds the question.' + NOTE)
s('vrQuestionRemove', 'Xoá câu hỏi “{question}”', 'Remove “{question}”', U1 + 'accessibility label of × on a question.' + NOTE,
  question='String')
s('vrDisclaimer', 'Từ nhật ký gia đình ghi trên Child Life. Không thay cho khám và tư vấn của bác sĩ.',
  'From the family\'s log in Child Life. Not a substitute for a doctor\'s examination or advice.',
  U1 + 'footer; also ends the shared text.' + NOTE)
s('vrShare', 'Gửi cho bác sĩ', 'Send to the doctor', U1 + 'primary action: shares the summary as text.' + NOTE)

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
