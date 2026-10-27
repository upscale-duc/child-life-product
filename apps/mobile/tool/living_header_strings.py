"""Owner-approved Living Header and device-local appearance, 27/10/2026."""
import json
from pathlib import Path

STRINGS = {
    'hhMorning': ('Chào ngày mới cùng {name}', 'A new day with {name}'),
    'hhMorningNoName': ('Chào ngày mới', 'A new day together'),
    'hhAfternoon': ('Một ngày của {name} thế nào rồi?', 'How is {name}’s day going?'),
    'hhAfternoonNoName': ('Ngày của bé thế nào rồi?', 'How is your baby’s day going?'),
    'hhEvening': ('Chào buổi tối, {name}', 'Good evening, {name}'),
    'hhEveningNoName': ('Chào buổi tối', 'Good evening'),
    'hhBirthday': ('Mừng sinh nhật {name}!', 'Happy birthday, {name}!'),
    'hhDutyNow': ('{name} đang trông bé', '{name} is caring for your baby'),
    'hhDutySince': ('Hiện tại · từ {time}', 'Now · since {time}'),
    'hhDutyRetry': ('Chưa tải được trạng thái trông bé · Thử lại', 'Couldn’t load care status · Retry'),
    'hhSettings': ('Cài đặt giao diện', 'Appearance settings'),
    'hhSettingsSubtitle': ('Hình nền đầu trang Hôm nay', 'Today header background'),
    'hhWallpaper': ('Hình nền', 'Background'),
    'hhPreview': ('Xem trước', 'Preview'),
    'hhPattern': ('Hoạ tiết theo buổi', 'Time-of-day artwork'),
    'hhAvatar': ('Ảnh đại diện của bé', 'Your baby’s profile photo'),
    'hhAvatarMissing': ('Bé chưa có ảnh đại diện; tạm dùng hoạ tiết.', 'No profile photo yet; artwork is shown for now.'),
    'hhSelected': ('Đang chọn', 'Selected'),
    'hhChooseMemory': ('Chọn ảnh từ Kỷ niệm', 'Choose a photo from Memories'),
    'hhPhotoEmpty': ('Chưa có ảnh để chọn trong Kỷ niệm.', 'There are no photos to choose from in Memories yet.'),
    'hhDeviceOnly': ('Chỉ áp dụng trên thiết bị này cho bé đang chọn.', 'Applies to the selected baby on this device only.'),
    'hhApply': ('Áp dụng', 'Apply'),
    'hhSaveFailed': ('Chưa lưu được giao diện. Bạn thử lại nhé.', 'Couldn’t save your appearance settings. Try again.'),
    'hhHeaderSection': ('Trong đầu trang', 'In the header'),
    'hhDutyFixed': ('Trạng thái trông bé nằm cố định trong đầu trang.', 'Care status stays in the header.'),
}

for lang, index in [('vi', 0), ('en', 1)]:
    path = Path(__file__).resolve().parents[1] / 'lib/l10n' / f'app_{lang}.arb'
    data = json.loads(path.read_text())
    for key, pair in STRINGS.items():
        data[key] = pair[index]
        meta = {'description': 'Living Header: owner-approved copy. name is the baby or carer as indicated by the key; time is the local shift-start time.'}
        placeholders = {p: {'type': 'String'} for p in ['name', 'time'] if '{' + p + '}' in pair[index]}
        if placeholders:
            meta['placeholders'] = placeholders
        data['@' + key] = meta
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
