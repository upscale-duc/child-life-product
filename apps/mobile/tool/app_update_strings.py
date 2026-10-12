# App updates (v1.0 improvement UP1–UP6, D-061). Vietnamese = Figma copy, English = engineering
# draft (D-012). Idempotent. Usage: python3 tool/app_update_strings.py
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

s('upRequiredTitle', 'Cần cập nhật để tiếp tục', 'Update to keep going', 'UP1 title (469:6476).')
s('upRequiredBody', 'Phiên bản này đã cũ và không còn đồng bộ an toàn với cả nhà. Cập nhật mất khoảng 1 phút.', 'This version is too old to sync safely with your family. Updating takes about a minute.', 'UP1 body (469:6477).')
s('upSafeTitle', 'Dữ liệu của bé vẫn an toàn', "Your baby's data is safe", 'UP1 reassurance row.')
s('upSafeBody', 'Ảnh, nhật ký và lịch sử chăm sóc được giữ nguyên', 'Photos, journal and care history stay as they are', 'UP1 reassurance row, second line.')
s('upPendingTitle', '{count} lần ghi chưa đồng bộ', '{count} {count, plural, =1{item} other{items}} not synced yet', 'UP1: uploads still on this phone.', count='int')
s('upPendingBody', 'Sẽ tự gửi lên ngay sau khi cập nhật', 'They go up right after you update', 'UP1 pending row, second line.')
s('upOpenAppStore', 'Cập nhật trên App Store', 'Update on the App Store', 'UP1 button on iOS.')
s('upOpenPlay', 'Cập nhật trên Google Play', 'Update on Google Play', 'UP1 button on Android.')
s('upWhatsNewIn', 'Có gì mới trong {version}', "What's new in {version}", 'UP1 link to the release pages.', version='String')
s('upNewTag', 'Mới · {version}', 'New · {version}', 'UP2 tag.', version='String')
s('upNewTitle', 'Child Life có bản mới', 'A new Child Life is here', 'UP2 title.')
s('upUpdate', 'Cập nhật', 'Update', 'UP2 button; UP6 tag.')
s('upLater', 'Để sau', 'Later', 'UP2 secondary action.')
s('upPageTag', 'Mới trong {version}', 'New in {version}', 'UP3/UP4 tag on the picture.', version='String')
s('upSkip', 'Bỏ qua', 'Skip', 'UP3/UP4 top right.')
s('upNext', 'Tiếp', 'Next', 'UP3/UP4 button.')
s('upPagesDone', 'Xong', 'Done', 'UP3/UP4 button on the last page.')
s('upPageOf', 'Trang {page} trên {count}', 'Page {page} of {count}', 'UP3/UP4 page dots, for screen readers.', page='int', count='int')
s('upBannerTitle', 'Đã cập nhật {version}', 'Updated to {version}', 'UP5 banner title.', version='String')
s('upBannerSee', 'Xem', 'See', 'UP5 banner action.')
s('upBannerClose', 'Đóng thông báo cập nhật', 'Close the update note', 'UP5 close button, for screen readers.')
s('upNewVersion', 'Có bản mới {version}', '{version} is available', 'UP6 Tôi · Phiên bản subtitle.', version='String')
s('upLatestVersion', 'Đây là bản mới nhất', 'You have the latest version', 'UP6 subtitle when up to date.')
s('upFirstAid', 'Sơ cứu', 'First aid', 'UP1: the offline Sơ cứu guide stays reachable while blocked (owner, 2026-10-12).')
s('upNoStore', 'Chưa mở được trang cập nhật. Thử lại sau nhé.', "Couldn't open the update page. Try again later.", 'Toast when the store link is missing or fails.')

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
