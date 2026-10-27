# AS10 / AS18 / upload queue flow (owner, 2026-10-26: "thêm lỗi cơ bản về flow khi hết bộ nhớ. ko
# show premium. mà text hiển thị cũng kỳ. hết bộ nhớ lại cho chuẩn bị file. mà khi tải lên lỗi cả
# hết thì ui cứ show mãi. đang chuẩn bị 104 file thì người dùng muốn được xem mỗi file đó chuẩn bị
# gì và đang như thế nào"). Vietnamese is the source; English is an engineering draft for owner
# review (D-012). Idempotent. Usage: python3 tool/as10_upload_flow_strings.py && flutter gen-l10n
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

NOTE = ' EN is an engineering draft for owner review.'
s('autoSaveCheckingSpace', 'Đang kiểm tra dung lượng…', 'Checking space…',
  'AS10 button while the family storage is not known yet: nothing uploads before it is checked.' + NOTE)
s('autoSaveFullTitle', 'Gia đình đã hết dung lượng', "Your family's space is full",
  'AS18 notice when nothing fits.' + NOTE)
s('autoSaveFullBody', '{count, plural, other{{count} mục cần khoảng {need}. Thêm dung lượng để tải lên; các mục vẫn ở trong máy.}}',
  '{count, plural, =1{1 item needs about {need}. Add space to upload it; it stays on your phone.} other{{count} items need about {need}. Add space to upload them; they stay on your phone.}}',
  'AS18 notice body when nothing fits.' + NOTE, count='int', need='String')
s('autoSaveShortTitle', 'Chỉ đủ chỗ cho {fit}/{count} mục', 'Room for {fit} of {count} items',
  'AS18 notice when only some fit.' + NOTE, fit='int', count='int')
s('autoSaveShortBody', 'Cần khoảng {need}, gia đình còn {left}. Ảnh được tải trước video; phần còn lại vẫn ở trong máy.',
  'They need about {need}; your family has {left} left. Photos go first, then videos; the rest stay on your phone.',
  'AS18 notice body when only some fit.' + NOTE, need='String', left='String')
s('autoSavePrepTitle', 'Đang chuẩn bị {done}/{total}', 'Preparing {done} of {total}',
  'AS10 while the chosen files are read and made ready for upload, one by one.' + NOTE, done='int', total='int')
s('autoSavePrepWaiting', 'Chờ', 'Waiting', 'AS10 per-file state: not started yet.' + NOTE)
s('autoSavePrepWorking', 'Đang chuẩn bị', 'Preparing', 'AS10 per-file state: being read and converted.' + NOTE)
s('autoSavePrepQueued', 'Đã vào hàng tải', 'Queued to upload', 'AS10 per-file state: ready, waiting in the upload queue.' + NOTE)
s('autoSavePrepFailed', 'Không đọc được tệp', "Couldn't read the file",
  'AS10 per-file state: the phone could not open it (deleted, damaged or not downloadable).' + NOTE)
s('autoSavePrepDone', 'Xong', 'Done', 'AS10 button after preparation, to continue.' + NOTE)
s('autoSavePrepSummary', '{queued} mục đã vào hàng tải · {failed} không đọc được', '{queued} queued · {failed} unreadable',
  'AS10 after preparation when some files could not be read.' + NOTE, queued='int', failed='int')
s('qQuotaTitle', 'Hết dung lượng gia đình', "Family space is full",
  'Upload queue: items wait because the family storage is full.' + NOTE)
s('qQuotaBody', '{count, plural, other{{count} mục đang chờ, vẫn ở trong máy. Thêm dung lượng để tiếp tục tải.}}',
  '{count, plural, =1{1 item is waiting and stays on your phone. Add space to keep uploading.} other{{count} items are waiting and stay on your phone. Add space to keep uploading.}}',
  'Upload queue, under "Hết dung lượng gia đình".' + NOTE, count='int')
s('qDropWaiting', '{count, plural, other{Bỏ {count} mục khỏi hàng chờ}}',
  '{count, plural, =1{Remove 1 item from the queue} other{Remove {count} items from the queue}}',
  'Upload queue: cancel the items waiting for space (they stay on the phone).' + NOTE, count='int')
s('qDropUnreadable', '{count, plural, other{Bỏ {count} tệp không đọc được}}',
  '{count, plural, =1{Remove 1 unreadable file} other{Remove {count} unreadable files}}',
  'Upload queue: cancel the files that cannot be read.' + NOTE, count='int')
s('qUnreadableHint', 'Máy không mở được các tệp này (có thể đã bị xoá hoặc hỏng).', "Your phone couldn't open these files (they may be deleted or damaged).",
  'Upload queue, under the unreadable count.' + NOTE)
# D-125 (main session, 2026-10-26): every Premium way in says Premium before the tap. The way out of
# a full space is named by plan: Free on Premium v2 → Premium; a Premium family → the paid add-on;
# without v2 → the Dung lượng screen.
s('autoSaveAddSpacePremium', 'Thêm dung lượng với Premium', 'Add space with Premium',
  'AS18 / upload queue, Free family with Premium v2: opens the Premium storage offer (D-125).' + NOTE)
s('autoSaveBuySpace', 'Mua thêm dung lượng', 'Buy more space',
  'AS18 / upload queue, Premium family: opens the paid storage add-on (D-125).' + NOTE)
s('autoSaveManageSpace', 'Quản lý dung lượng', 'Manage space',
  'AS18 / upload queue without Premium v2: opens Dung lượng.' + NOTE)
s('autoSavePremiumSpaceNote', 'Premium có thêm dung lượng cho cả nhà.', 'Premium gives the whole family more space.',
  'AS18 / upload queue notice, Free family with Premium v2: says Premium before the button (D-125).' + NOTE)

# Replaced by the full / short notices and the per-file list; no code uses them.
GONE = ['autoSaveNoRoom', 'autoSavePreparing', 'autoSaveAddSpace']

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
    for key in GONE:
        data.pop(key, None)
        data.pop('@' + key, None)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
print(len(S), 'strings')
