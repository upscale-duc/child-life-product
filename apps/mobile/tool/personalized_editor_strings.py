"""Personalized keepsake editor sections, vi source / en engineering draft.
Run from apps/mobile: python3 tool/personalized_editor_strings.py && flutter gen-l10n.
"""
import json
from pathlib import Path
STRINGS = {
    'p48ClearValue': ('Xoá giá trị', 'Clear value', 'Clears an optional date or time without substituting a default.'),
    'p48InfoTab': ('Thông tin', 'Details', 'Editor section: information about the baby or moment.'),
    'p48TextTab': ('Lời nhắn', 'Wording', 'Editor section: editable text appearing in the finished keepsake.'),
    'p48MediaTab': ('Ảnh & nhạc', 'Photos & music', 'Video editor section: framing the chosen photos and music.'),
    'p48PhotosTab': ('Ảnh', 'Photos', 'Card editor section: actual card artwork and photo editing.'),
    'p48MoreDetails': ('Thêm chi tiết', 'More details', 'Expandable optional moment details, such as birth time and birthplace.'),
    'p48OptionalDetails': ('Tuỳ chọn · Chỉ hiện khi bạn nhập', 'Optional · Shown only when entered', 'Optional moment metadata, omitted from the keepsake when left blank.'),
    'p48Settings': ('Tuỳ chỉnh', 'Options', 'Opens output language, aspect ratio and gentle motion settings.'),
}
for lang in ['vi', 'en']:
    path = Path(__file__).resolve().parents[1] / f'lib/l10n/app_{lang}.arb'
    data = json.loads(path.read_text())
    for key, (vi, en, description) in STRINGS.items():
        data[key] = vi if lang == 'vi' else en
        data['@' + key] = {'description': description}
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
