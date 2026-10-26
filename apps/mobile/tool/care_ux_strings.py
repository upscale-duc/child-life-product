# Care UI/UX pass (D-109, 2026-10-25): copy fixes found on rendered Care goldens.
# - en counts that met a noun without ICU plurals ("1 feeds") now use plurals.
# - A number stays on the same line as its unit or noun (no-break space, U+00A0), so a narrow
#   summary column wraps at " · " instead of between "420" and "ml".
# Vietnamese is the source; English is an engineering draft for owner review (D-012).
# Idempotent: rewrites existing values, adds new keys with their metadata.
# Usage: python3 tool/care_ux_strings.py && flutter gen-l10n
import json, collections, pathlib

NB = ' '

# Existing keys: (vi, en). The @ metadata (placeholders, description) is unchanged.
CHANGED = {
    'rhythmFeeds': (
        f'{{count}}{NB}cữ · {{ml}}{NB}ml',
        f'{{count, plural, =1{{1{NB}feed}} other{{{{count}}{NB}feeds}}}} · {{ml}}{NB}ml',
    ),
    'rhythmBreast': (
        f'{{count}}{NB}cữ · {{minutes}}{NB}phút',
        f'{{count, plural, =1{{1{NB}feed}} other{{{{count}}{NB}feeds}}}} · {{minutes}}{NB}min',
    ),
    'minutesAndFeeds': (
        f'{{minutes}}{NB}phút · {{count}}{NB}cữ',
        f'{{minutes}}{NB}min · {{count, plural, =1{{1{NB}feed}} other{{{{count}}{NB}feeds}}}}',
    ),
    'milkDayTip': (
        f'{{day}} · {{ml}}{NB}ml · {{count}}{NB}cữ',
        f'{{day}} · {{ml}}{NB}ml · {{count, plural, =1{{1{NB}feed}} other{{{{count}}{NB}feeds}}}}',
    ),
    'breastDayTip': (
        f'{{day}} · {{minutes}}{NB}phút · {{count}}{NB}cữ',
        f'{{day}} · {{minutes}}{NB}min · {{count, plural, =1{{1{NB}feed}} other{{{{count}}{NB}feeds}}}}',
    ),
    'lastNightInsight': (
        'Đêm qua bú {count} cữ, khoảng nghỉ dài nhất {gap} ({from}–{to}).',
        'Last night: {count, plural, =1{1 feed} other{{count} feeds}}, longest gap {gap} ({from}–{to}).',
    ),
    # D-116 growth flow: shorter, same meaning.
    'rhStageExpectedLine': (
        'Dự kiến {range} · còn {days} ngày',
        'Expected {range} · {days, plural, =1{1 day} other{{days} days}} to go',
    ),
    'rhCalendarDisclaimerShort': (
        'mỗi bé một khác',
        'every baby differs',
    ),
    'mtLead': (
        'Mỗi bé có nhịp riêng.',
        'Every baby has their own pace.',
    ),
    # D-117: the thanks sentence goes; the promise that the team reads every note stays.
    'fbIntro': (
        'Đội ngũ Child Life đọc từng góp ý.',
        'The Child Life team reads every message.',
    ),
    # D-118: the first sentence restated the screen title.
    'lbStagesIntro': (
        'Mỗi bé phát triển theo nhịp riêng.',
        'Every baby grows at their own pace.',
    ),
    # D-119 (owner): the permission prompt keeps only the part about this device.
    'notifPromptBody': (
        'Thông báo chỉ được đặt trên máy tạo nhắc việc.',
        'Notifications are set only on the device that created the reminder.',
    ),
    # D-120: "PNG" is a file format, not something parents choose by.
    'ksCardTileHint': (
        'Ảnh để chia sẻ',
        'An image to share',
    ),
    # D-120: the badge next to the title already says "Beta miễn phí"; the privacy sentence and
    # the accuracy caveat stay, the storage figure says what it is.
    'autoSaveIntroFootnote': (
        'Gợi ý có thể sót hoặc nhầm, nhất là khi ảnh tối, nghiêng hay có nhiều bé. Tệp đã tải tính vào dung lượng của gia đình (đã dùng {usage}).',
        "Suggestions can miss photos or get them wrong, especially dark, tilted or crowded ones. Uploaded files count towards your family's storage ({usage} used).",
    ),
    'autoSaveIntroFootnoteNoUsage': (
        'Gợi ý có thể sót hoặc nhầm, nhất là khi ảnh tối, nghiêng hay có nhiều bé. Tệp đã tải tính vào dung lượng của gia đình.',
        "Suggestions can miss photos or get them wrong, especially dark, tilted or crowded ones. Uploaded files count towards your family's storage.",
    ),
    'autoSaveIntroLead': (
        'Child Life tìm ảnh và video có thể có con. Bạn xem lại rồi mới tải lên.',
        'Child Life finds photos and videos that may show your baby. You check them before anything is uploaded.',
    ),
    'autoSaveStep2Hint': (
        'Ngay trên máy, chỉ những ảnh bạn cho phép xem, không gửi đi',
        'On this phone, only the photos you let it see, never sent anywhere',
    ),
    'autoSaveStep3Hint': (
        'Không tự chia sẻ',
        'Nothing is shared on its own',
    ),
    # D-121: the switch's state only; "Beta miễn phí" is said on the intro.
    'autoSaveOnBeta': (
        'Đang bật',
        'On',
    ),
    'lastNightBreastInsight': (
        'Đêm qua bú mẹ {count} cữ, {minutes} phút ({time}).',
        'Last night: {count, plural, =1{1 breastfeed} other{{count} breastfeeds}}, {minutes} min ({time}).',
    ),
}

# D-110 Simplify: keys whose text no longer shows anywhere (redundant subtitles, a footnote that
# explained what both options already say, an empty-state line that restated its button).
REMOVED = ['careHistorySub', 'careGrowthSub', 'sleepChooserFootnote', 'emptyDayBody',
           # D-115: Tuỳ chỉnh Hôm nay rows are titles only; the intro became axCustomizeHint.
           'axCustomizeIntro', 'axBecauseGoal', 'axPinned', 'axHiddenByAge',
           # D-115: the setup preview (AX06) is a plain ordered list too.
           'axPreviewBecause', 'axBecauseAge', 'axBecauseAlways',
           # D-116: week subtitles that restated the section, the model-version labels.
           'rhWeekRecordedSub', 'rhWeekInsightSub', 'rhCalendarFooter', 'rhModelVersion',
           # D-117: subtitles that restated their title.
           'actFavoriteHint', 'bpGrowthHint',
           # D-118
           'inviteSubtitle',
           # D-119
           'asPhotoTextIsData', 'remindersInfo', 'reminderDetailNote',
           # D-120: the suggestion row no longer explains that parents decide.
           'engBody', 'autoSaveStep1Hint']

# New keys: key -> (vi, en, description, placeholders).
NEW = collections.OrderedDict()
NEW['axCustomizeHint'] = (
    'Kéo để đổi thứ tự. Ghim để luôn ở đầu.',
    'Drag to reorder. Pin to keep at the top.',
    'Tuỳ chỉnh Hôm nay (AX14) instruction under the title (D-115): the two actions that are not obvious; replaces axCustomizeIntro on this screen.',
    {},
)
NEW['rhCalendarNote'] = (
    'Lịch là mô hình tham khảo, chưa được chứng minh chính xác cho từng bé.',
    'The calendar is a reference model, not proven accurate for each baby.',
    'NL03 calendar footer (D-116): rhCalendarFooter without the model version, which is for staff.',
    {},
)
NEW['engMore'] = (
    'Tuỳ chọn gợi ý',
    'Suggestion options',
    'Screen-reader label of the "…" on a smart-suggestion row in Kỷ niệm (D-120): opens Xem / Để sau / Bỏ qua gợi ý.',
    {},
)
NEW['autoSaveOnBetaFree'] = (
    'Đang bật · Beta miễn phí',
    'On · Free beta',
    'Tự lưu settings switch while on and the portal has Tự lưu at the Beta tier (D-122); autoSaveOnBeta otherwise.',
    {},
)
NEW['saveDiaper'] = (
    'Lưu lần thay tã',
    'Save diaper change',
    'Primary button of the diaper sheet (24), named like the other care sheets (saveFeed, savePump, saveSleep).',
    {},
)
NEW['careLoadingRecords'] = (
    'Đang tải ghi chép',
    'Loading entries',
    'Screen-reader label of the History and Stats skeleton while the day\'s care records load.',
    {},
)

root = pathlib.Path(__file__).resolve().parent.parent / 'lib' / 'l10n'
for locale, idx in (('vi', 0), ('en', 1)):
    path = root / f'app_{locale}.arb'
    data = json.loads(path.read_text(), object_pairs_hook=collections.OrderedDict)
    for key in REMOVED:
        data.pop(key, None)
        data.pop('@' + key, None)
    for key, values in CHANGED.items():
        if key not in data:
            raise SystemExit(f'{key} is missing in app_{locale}.arb')
        data[key] = values[idx]
    for key, (vi, en, desc, ph) in NEW.items():
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
print(len(CHANGED), 'changed,', len(NEW), 'new,', len(REMOVED), 'removed')
