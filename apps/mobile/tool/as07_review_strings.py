# AS07 review "Có thể có {tên}" (owner, 2026-10-26: "cần phân tích kỹ và improve màn hình này"):
# the line under the title says only what to do (everything is ticked), not the total or the
# check time (Tự lưu shows that). Vietnamese is the source; English is an engineering draft for owner review (D-012).
# Idempotent. Usage: python3 tool/as07_review_strings.py && flutter gen-l10n
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

s('autoSaveReviewTicked', 'App đã chọn sẵn ảnh rõ nhất. Bỏ chọn mục không muốn lưu.', "The clearest ones are ticked. Untick anything you don't want to save.",
  'AS07 line under "Có thể có {tên}": the app ticks the clearest of each group (not near-copies, not "Đã có"). EN is an engineering draft for owner review.')

# D-123 rework (owner, 2026-10-26: "làm đi làm lại vẫn ko đúng và khó hiểu. hãy phân tích lại
# ui/ux"): every file is a tile and every count counts files; near-copies are shown together; the
# "Đã có" ones wait folded at the end; the top-bar toggle is back instead of a sheet.
s('autoSaveSelectAll', 'Chọn hết', 'Tick all',
  'AS07 top bar when nothing in view is ticked: ticks every new item (not "Đã có"). EN is an engineering draft for owner review.')
s('autoSaveDeselectAll', 'Bỏ chọn hết', 'Untick all',
  'AS07 top bar while something in view is ticked. EN is an engineering draft for owner review.')
s('autoSaveGroupBestOnly', 'Chỉ giữ ảnh rõ nhất', 'Keep the clearest only',
  'AS07 near-copy block, when all of them are ticked: untick all but the clearest. EN is an engineering draft for owner review.')
s('autoSaveSavedSection', '{count, plural, other{Đã có trong Kỷ niệm · {count}}}', '{count, plural, other{Already in Memories · {count}}}',
  'AS07 folded section at the end: items the app thinks are already in Kỷ niệm (a guess, same capture second). EN is an engineering draft for owner review.',
  count='int')
s('autoSaveSavedHint', 'Không chọn sẵn. Mở ra để chọn nếu app nhầm.', "Not ticked. Open to tick any the app got wrong.",
  'AS07 under "Đã có trong Kỷ niệm": they start unticked and can be ticked. EN is an engineering draft for owner review.')
s('autoSaveLegend', '“Trên iCloud”: tệp gốc chưa có trong máy, sẽ lấy về khi có mạng.',
  '“In iCloud”: the original isn’t on this phone yet and is fetched when online.',
  'AS07 legend under the grid (the "Đã có" explanation lives on its own section). EN is an engineering draft for owner review.')

s('autoSaveWeekSheet', 'Tuần tuổi', 'Week of age',
  'AS07 sheet title behind the week pill (one row of pills instead of two bars, owner 2026-10-26: "hai cái tabbar … chiếm nhiều diện tích"). EN is an engineering draft for owner review.')
s('autoSaveKindSheet', 'Hiện', 'Show',
  'AS07 sheet title behind the Ảnh & video pill. EN is an engineering draft for owner review.')

s('autoSaveFilterAll', 'Ảnh & video · {count}', 'Photos & videos · {count}',
  'AS07 kind pill and its first option, like Kỷ niệm Ảnh "Ảnh & video". EN is an engineering draft for owner review.',
  count='int')

# Owner, 2026-10-26: each week says how much is already in Kỷ niệm and how much waits, in words
# and a small bar ("toàn số vậy cũng khó hiểu", "nghe cọc").
s('autoSaveWeekRowTitle', 'Tuần {n} · {range}', 'Week {n} · {range}',
  'AS07 week sheet row: the week of age and its days ("15–21/10"). EN is an engineering draft for owner review.',
  n='int', range='String')
s('autoSaveWeekRowBefore', 'Trước sinh', 'Before birth',
  'AS07 week sheet row for photos taken before the birth date. EN is an engineering draft for owner review.')
s('autoSaveWeekRowProgress', '{saved} đã có trong Kỷ niệm · {waiting} chờ bạn xem',
  '{saved} in Memories · {waiting} waiting for you',
  'AS07 week sheet row: files of that week already in Kỷ niệm, and suggestions to review. EN is an engineering draft for owner review.',
  saved='int', waiting='int')
s('autoSaveWeekRowWaiting', '{waiting} chờ bạn xem', '{waiting} waiting for you',
  'AS07 week sheet row when nothing of that week is in Kỷ niệm yet. EN is an engineering draft for owner review.',
  waiting='int')
s('autoSaveWeekRowDone', 'Đã xem hết · {saved} trong Kỷ niệm', 'All reviewed · {saved} in Memories',
  'AS07 week sheet row for a week already sent. EN is an engineering draft for owner review.',
  saved='int')

# Owner, 2026-10-26: "có nên thêm 1 option là chọn tất cả các tuần để upload toàn bộ ko": one
# review across every week; the per-upload limit (D-070) still holds the rest for next time.
s('autoSaveAllWeeks', 'Tất cả các tuần · {count}', 'All weeks · {count}',
  'AS07 week pill when every week is shown together. EN is an engineering draft for owner review.',
  count='int')
s('autoSaveAllWeeksRow', 'Tất cả các tuần', 'All weeks',
  'AS07 week sheet, first row: review every week at once. EN is an engineering draft for owner review.')

# Owner, 2026-10-26: "có vẻ đếm ko đúng. nhìn button" (199 to review, "Tiếp tục với 105 mục"):
# the footer says ticked of total and why the rest are not ticked.

# Owner, 2026-10-26: "bạn lại bắt user tính toán nữa … chỉ cần duyệt 199 hình đó thôi và button nên
# hiển thị tải lên 199 hình khi chọn tất cả … section đã có … nếu chọn thì button cứ tăng lên":
# counts are of what is not yet in Kỷ niệm; ticked "Đã có" items show as an extra.

# Lines the review no longer shows (no code uses them): the week and grouping explanations, the
# total-and-check-time sub-line, and the per-day count.
GONE = ['autoSaveWeekHint', 'autoSaveGroupedHint', 'autoSaveReviewSub', 'autoSaveDayCount',
        'autoSaveSelectAlready', 'autoSaveHideAlready', 'autoSaveQuickSelect', 'autoSaveSelectBest',
        'autoSaveSelectBestHint', 'autoSaveSelectEverything', 'autoSaveModeNone', 'autoSaveModeCustom',
        'autoSaveAlreadySection', 'autoSaveAlreadyHide', 'autoSaveAlreadyShow', 'autoSaveAlreadyPick',
        'autoSaveAlreadyHidden', 'autoSaveAlreadyIncluded', 'autoSaveCopiesTicked', 'autoSaveCopyTag',
        'autoSaveMerged', 'autoSaveGroupCollapse', 'autoSaveUntickedSaved',
        'autoSaveTickedOf', 'autoSaveUntickedLead', 'autoSaveUntickedCopies', 'autoSaveUntickedByHand',
        'autoSaveTickedPlusSaved']

# Existing keys this script rewrites on purpose.
REWRITE = {'autoSaveReviewTicked', 'autoSaveLegend', 'autoSaveSelectAll', 'autoSaveDeselectAll', 'autoSaveFilterAll'}

root = pathlib.Path(__file__).resolve().parent.parent / 'lib' / 'l10n'
for locale, idx in (('vi', 0), ('en', 1)):
    path = root / f'app_{locale}.arb'
    data = json.loads(path.read_text(), object_pairs_hook=collections.OrderedDict)
    for key, (vi, en, desc, ph) in S.items():
        meta = data.get('@' + key)
        if locale == 'vi' and key in data and key not in REWRITE and (meta or {}).get('description') != desc:
            raise SystemExit(f'{key} already exists for something else: pick another id')
        data[key] = (vi, en)[idx]
        if locale == 'vi':
            meta = collections.OrderedDict(description=desc)
            if ph:
                meta['placeholders'] = {k: {'type': v} for k, v in ph.items()}
            data['@' + key] = meta
    for key in GONE:
        data.pop(key, None)
        data.pop('@' + key, None)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
print(len(S), 'strings')
