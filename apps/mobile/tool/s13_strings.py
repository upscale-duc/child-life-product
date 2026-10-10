# One-off generator for the S13 ARB entries (share sheet 14h, cards 14i/14j, private link 14k,
# "Đã chia sẻ ra ngoài" 14m). Vietnamese = Figma source, English = engineering draft (D-012);
# undrawn states (passcode reveal, revoke confirmation, revoked rows) are engineering copy.
# Usage: python3 tool/s13_strings.py
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

def pl(one, other):
    return '{count, plural, =1{' + one + '} other{' + other + '}}'

# 14h
s('shInFamily', 'Trong gia đình', 'In the family', '14h section.')
s('shFamilyReading', 'Gia đình đang đọc', 'The family is reading', '14h row.')
s('shParentsReading', 'Chỉ ba mẹ đang đọc', 'Only the parents are reading', '14h row (parents-only story).')
s('shTapToChange', 'Đã báo cả nhà · chạm để đổi', 'Family told · tap to change', '14h row.')
s('shTapToChangeParents', 'Chạm để đổi', 'Tap to change', '14h row (parents-only).')
s('shOutside', 'Ra ngoài', 'Outside the family', '14h section.')
s('shCard', 'Thiệp ảnh', 'Photo card', '14h row / 14i title.')
s('shCardHint', 'Đẹp để đăng Facebook, Instagram, Zalo', 'Made for Facebook, Instagram, Zalo', '14h row.')
s('shLink', 'Liên kết xem riêng', 'Private link', '14h row / 14k title.')
s('shLinkHint', 'Có hạn · không cần cài app', 'Expires · no app needed', '14h row.')
s('shOutsideNote', 'Chỉ ba mẹ thấy mục “Ra ngoài”. Mặc định ẩn tên thật và ngày sinh.', 'Only parents see “Outside the family”. Real name and birth date are hidden by default.', '14h note.')
s('shPrivatePhotosNote', 'Ảnh Chỉ ba mẹ không hiện khi chia sẻ ra ngoài.', 'Parents-only photos don’t appear outside the family.', '14h note (P-095).')
# 14i
s('cdNext', 'Tiếp', 'Next', '14i top bar.')
s('cdMoment', '1 ảnh', '1 photo', '14i template.')
s('cdThree', '3 ảnh', '3 photos', '14i template.')
s('cdFour', '4 ảnh', '4 photos', '14i template.')
s('cdLetter', 'Chữ', 'Words', '14i template.')
s('cdNight', 'Tối', 'Night', '14i template.')
s('cdQuote', 'Câu trích', 'Quote', '14i option.')
s('cdPhoto', 'Ảnh', 'Photo', '14i option.')
s('cdCover', 'Ảnh bìa', 'Cover photo', '14i option value.')
s('cdShowAge', 'Hiện tuổi thay ngày sinh', 'Show age instead of birth date', '14i option.')
s('cdTo', 'Gửi {name},', 'Dear {name},', 'Letter card greeting.', name='String')
s('cdSigned', '— {who}, {season}', '— {who}, {season}', 'Letter card signature.', who='String', season='String')
s('cdSaved', 'Đã tạo thiệp', 'Card made', 'Toast.')
s('cdSize', 'Ảnh 1080 × 1350', 'Image 1080 × 1350', '14j sheet head.')
# 14k
s('lkExpires', 'Hết hạn sau', 'Expires after', '14k label.')
s('lk24h', '24 giờ', '24 hours', '14k option.')
s('lk7d', '7 ngày', '7 days', '14k option.')
s('lk30d', '30 ngày', '30 days', '14k option.')
s('lkHideIdentity', 'Ẩn tên thật & ngày sinh', 'Hide real name & birth date', '14k toggle.')
s('lkHideIdentityHint', 'Chỉ hiện “{name}” và số tuần tuổi', 'Only “{name}” and the age in weeks', '14k toggle.', name='String')
s('lkDownload', 'Cho tải ảnh về', 'Allow photo downloads', '14k toggle.')
s('lkDownloadHint', 'Tắt: người xem chỉ xem, không lưu', 'Off: viewers can look but not save', '14k toggle.')
s('lkPasscode', 'Hỏi mật mã 4 số', 'Ask for a 4-digit passcode', '14k toggle.')
s('lkPasscodeHint', 'Gửi mật mã riêng cho người nhận', 'Send the passcode to the recipient separately', '14k toggle.')
s('lkNote', 'Bạn thấy được số lượt xem và thu hồi bất cứ lúc nào.', 'You can see the views and revoke it at any time.', '14k note.')
s('lkCopyShare', 'Sao chép & chia sẻ', 'Copy & share', '14k button.')
s('lkCopy', 'Sao chép', 'Copy', '14k chip.')
s('lkCopied', 'Đã sao chép liên kết', 'Link copied', 'Toast.')
s('lkPasscodeTitle', 'Mật mã của liên kết', 'The link’s passcode', 'Passcode reveal (not drawn).')
s('lkPasscodeBody', 'Gửi riêng mật mã này cho người nhận. Child Life không hiện lại mật mã.', 'Send this passcode to the recipient separately. Child Life won’t show it again.', 'Passcode reveal.')
s('lkScreenshotNote', 'Người xem vẫn có thể chụp màn hình.', 'Viewers can still take screenshots.', '14k caveat (R-166).')
# 14m
s('soTitle', 'Đã chia sẻ ra ngoài', 'Shared outside', '14m title / Tôi row.')
s('soOpenCount', pl('1 liên kết đang mở', '{count} liên kết đang mở'), pl('1 link open', '{count} links open'), 'Tôi row value.', count='int')
s('soOpen', 'Đang mở', 'Open', '14m section.')
s('soCards', 'Thiệp ảnh đã lưu', 'Saved cards', '14m section.')
s('soClosed', 'Đã hết hạn', 'Expired', '14m section.')
s('soViewsLeftDays', pl('1 lượt xem · còn {left}', '{count} lượt xem · còn {left}'), pl('1 view · {left} left', '{count} views · {left} left'), '14m row.', count='int', left='String')
s('soDays', pl('1 ngày', '{count} ngày'), pl('1 day', '{count} days'), '14m duration.', count='int')
s('soHours', pl('1 giờ', '{count} giờ'), pl('1 hour', '{count} hours'), '14m duration.', count='int')
s('soRevoke', 'Thu hồi', 'Revoke', '14m chip.')
s('soRevokeTitle', 'Thu hồi liên kết?', 'Revoke the link?', 'Confirmation (not drawn).')
s('soRevokeBody', 'Người có liên kết sẽ không xem được nữa.', 'Anyone with the link won’t be able to open it any more.', 'Confirmation.')
s('soRevoked', 'Đã thu hồi', 'Revoked', 'Row / toast.')
s('soExpiredOn', 'Hết hạn {date}', 'Expired {date}', '14m row.', date='String')
s('soCardRow', 'Ảnh · không thu hồi được', 'Image · can’t be revoked', '14m row.')
s('soEmpty', 'Chưa chia sẻ câu chuyện nào ra ngoài.', 'No stories shared outside yet.', '14m empty.')

def placeholders(ph):
    return {k: {'type': v} for k, v in ph.items()}

root = pathlib.Path(__file__).resolve().parent.parent / 'lib' / 'l10n'
for locale, idx in (('vi', 0), ('en', 1)):
    path = root / f'app_{locale}.arb'
    data = json.loads(path.read_text(), object_pairs_hook=collections.OrderedDict)
    for key, (vi, en, desc, ph) in S.items():
        if key in data and locale == 'vi' and data[key] != vi:
            raise SystemExit(f'key collision: {key}')
        data[key] = (vi, en)[idx]
        if locale == 'vi':
            meta = collections.OrderedDict(description=desc)
            if ph:
                meta['placeholders'] = placeholders(ph)
            data['@' + key] = meta
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
print(len(S), 'strings')
