# 10j background upload strings: the upload Live Activity and the "done / failed / waiting for
# Wi-Fi" notices. The native uploader shows them while the app is suspended, so they travel in the
# glance snapshot's copy map (lib/l10n/glance_copy.dart) like the widget strings. Counts that need
# an English plural have a separate ".one" id. Vietnamese = Figma 10j source, English = draft
# (D-012). Idempotent. Usage: python3 tool/s8_upload_strings.py
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

s('glanceUploadTitle', 'Kỷ niệm của {name}', '{name}’s memories', 'Upload Live Activity header (10j).', name='String')
s('glanceUploadTitlePlain', 'Kỷ niệm', 'Memories', 'Upload Live Activity header without a nickname.')
s('glanceUploadProgress', 'Đang tải {done}/{total} mục', 'Uploading {done} of {total}', 'Upload Live Activity (10j).', done='String', total='String')
s('glanceUploadNotify', 'Xong sẽ báo bạn', 'We’ll let you know when it’s done', 'Upload Live Activity sub (10j).')
s('glanceUploadWaiting', '{n} video chờ Wi‑Fi', 'Videos waiting for Wi‑Fi: {n}', 'Upload Live Activity sub when videos wait (D-033).', n='String')
s('glanceUploadDoneOne', 'Đã tải xong 1 mục', 'Uploaded 1 item', 'Notice when background uploads finish.')
s('glanceUploadDone', 'Đã tải xong {n} mục', 'Uploaded {n} items', 'Notice when background uploads finish.', n='String')
s('glanceUploadDoneBody', 'Ảnh và video đã có trong Kỷ niệm.', 'Your photos and videos are in Memories.', 'Notice body (no photo, 10j).')
s('glanceUploadFailedOne', '1 mục chưa tải lên được', '1 item couldn’t upload', 'Notice when background uploads fail.')
s('glanceUploadFailed', '{n} mục chưa tải lên được', '{n} items couldn’t upload', 'Notice when background uploads fail.', n='String')
s('glanceUploadFailedBody', 'Mở Child Life để thử lại.', 'Open Child Life to try again.', 'Notice body.')
s('glanceUploadWifiOne', '1 video đang chờ Wi‑Fi', '1 video is waiting for Wi‑Fi', 'Notice (10j) when the app is left with a video held for Wi-Fi.')
s('glanceUploadWifi', '{n} video đang chờ Wi‑Fi', '{n} videos are waiting for Wi‑Fi', 'Notice (10j).', n='String')
s('glanceUploadWifiBody', 'Ảnh vẫn đang tải. Video sẽ tự tải khi có Wi‑Fi.', 'Photos are still uploading. Videos will upload on Wi‑Fi.', 'Notice body (10j).')

root = pathlib.Path(__file__).resolve().parent.parent / 'lib' / 'l10n'
for locale, idx in (('vi', 0), ('en', 1)):
    path = root / f'app_{locale}.arb'
    data = json.loads(path.read_text(), object_pairs_hook=collections.OrderedDict)
    for key, (vi, en, desc, ph) in S.items():
        data[key] = (vi, en)[idx]
        if locale == 'vi':
            meta = collections.OrderedDict(description=desc)
            if ph:
                meta['placeholders'] = {k: {'type': v} for k, v in ph.items()}
            data['@' + key] = meta
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
print(len(S), 'strings')
