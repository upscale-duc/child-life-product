"""Keepsake flow UX, 2026-10-26 (D-109–D-112).
Vietnamese source; English is an engineering draft for owner review.
Idempotent, preserving existing keys and metadata.
Run from apps/mobile: python3 tool/keepsake_ux_strings.py && flutter gen-l10n
"""
import json
from pathlib import Path

STRINGS = {
    'ksCardSaveAudience': (
        'Lưu vào Kỷ niệm · Chỉ ba mẹ', 'Save to Memories · Parents only',
        {'description': 'Card editor: destination and audience before saving; does not claim the card is already saved.'},
    ),
    'ksCardMissingPhotos': (
        'Chọn thêm {n} ảnh để lưu thiệp',
        '{n, plural, =1{Choose 1 more photo to save your card} other{Choose {n} more photos to save your card}}',
        {'description': 'Card editor: why Save is unavailable; n is the number of required photo slots still empty.',
         'placeholders': {'n': {'type': 'int'}}},
    ),
    'ksAddDevicePhotos': (
        'Thêm ảnh từ máy', 'Add photos from device',
        {'description': 'Video photo picker: opens the device library to add photos to scenes; an action, not a source tab.'},
    ),
}
for lang in ['vi', 'en']:
    path = Path(__file__).resolve().parents[1] / f'lib/l10n/app_{lang}.arb'
    data = json.loads(path.read_text())
    for key, (vi, en, metadata) in STRINGS.items():
        data[key] = vi if lang == 'vi' else en
        data['@' + key] = metadata
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
