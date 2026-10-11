# Camera and photo-library widgets (owner request 2026-10-11): gallery names / blurbs and the
# widget copy, in the ARB catalogs (D-012; Vietnamese by engineering, owner to review). Then run
# tool/s8_widget_strings.py to rewrite ios/widget/Localizable.xcstrings. Idempotent.
# Usage: python3 tool/memory_widget_strings.py && python3 tool/s8_widget_strings.py
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

s('glanceGalleryCameraName', 'Chụp ảnh bé', 'Baby camera', 'Widget gallery name (camera shortcut).')
s('glanceGalleryCameraBlurb', 'Mở camera để chụp ảnh hoặc quay video, rồi lưu vào Kỷ niệm.', 'Open the camera for a photo or a video, then save it to Memories.', 'Widget gallery description.')
s('glanceGalleryLibraryName', 'Thêm từ Ảnh', 'Add from Photos', 'Widget gallery name (photo-library shortcut).')
s('glanceGalleryLibraryBlurb', 'Chọn ảnh, video trong máy để lưu vào Kỷ niệm.', 'Pick photos and videos on this phone to save to Memories.', 'Widget gallery description.')
s('glanceMemCamera', 'Chụp ảnh, quay video', 'Take a photo or video', 'Camera widget title.')
s('glanceMemLibrary', 'Thêm từ Ảnh', 'Add from Photos', 'Photo-library widget title.')
s('glanceMemFor', 'Vào Kỷ niệm của {name}', 'To {name}’s memories', 'Widget subtitle: the baby.', name='String')

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
