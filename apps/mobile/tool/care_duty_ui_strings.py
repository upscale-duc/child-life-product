"""Owner 27/10/2026: parents can care together; clear care-sheet feedback."""
import json
from pathlib import Path

strings = {
    'dutyTake': ('Tôi trông bé', 'I’m caring for my baby', 'Action: starts the viewer’s care shift now.'),
    'dutyStartedAt': ('Từ {time}', 'Since {time}', 'Local start time of the current care shift.'),
    'dutyParents': ('Ba và Mẹ', 'Dad and Mom', 'Two verified parents currently caring together.'),
    'dutyTogether': ('Ba và Mẹ cùng trông', 'Dad and Mom care together', 'Action: records the viewer and the other active parent as caring together.'),
    'dutyTogetherToast': ('Ba và Mẹ đang cùng trông bé. Cả nhà sẽ thấy.', 'Dad and Mom are caring together. Your family can see this.', 'Confirmed only after a successful server write.'),
    'dutyTogetherNow': ('Ba và Mẹ đang cùng trông bé', 'Dad and Mom are caring together', 'Current parent-pair label, with plural grammar.'),
    'dutyTogetherSince': ('Ba và Mẹ cùng trông · từ {time}', 'Dad and Mom are caring · since {time}', 'Parent-pair status with baby-local start time.'),
    'dutyYouNow': ('Bạn đang trông bé', 'You’re caring for your baby', 'Viewer’s own care status; uses correct second-person grammar.'),
    'dutyYouSince': ('Bạn đang trông · từ {time}', 'You’re caring · since {time}', 'Viewer’s own care status with local start time.'),
    'dutyJustStarted': ('Vừa bắt đầu', 'Just started', 'Shift duration under one minute; not rounded up.'),
    'dutyPrevious': ('Trước đó', 'Previously', 'Previous carer or parent pair, not currently on duty.'),
    'dutyLoadFailed': ('Chưa tải được trạng thái trông bé.', 'Couldn’t load care status.', 'Load error in care duty sheet; never shown as nobody caring.'),
    'dutyOwnPart': ('Kết thúc phần của bạn; người còn lại vẫn đang trông bé.', 'End your part; the other parent will still be caring.', 'Shown for a current parent pair before ending only the viewer’s part.'),
}
for lang, index in [('vi', 0), ('en', 1)]:
    path = Path(__file__).resolve().parents[1] / 'lib/l10n' / f'app_{lang}.arb'
    data = json.loads(path.read_text())
    for key, pair in strings.items():
        data[key] = pair[index]
        data['@' + key] = {'description': pair[2]}
        if '{time}' in pair[index]:
            data['@' + key]['placeholders'] = {'time': {'type': 'String'}}
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
