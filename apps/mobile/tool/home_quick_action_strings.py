"""Home card action labels; Vietnamese is the source, English draft for review."""
import json
from pathlib import Path
strings = {
    'todayOtherAmount': ('Khác', 'Other'),
    'todayDiaperBoth': ('Cả hai', 'Both'),
    'todayStartSleep': ('Bắt đầu ngủ', 'Start sleep'),
    'todayViewSession': ('Xem phiên đang chạy', 'View active session'),
}
root = Path(__file__).resolve().parents[1] / 'lib/l10n'
for language, index in [('vi', 0), ('en', 1)]:
    path = root / f'app_{language}.arb'
    data = json.loads(path.read_text())
    for key, values in strings.items():
        data[key] = values[index]
        if language == 'vi':
            data[f'@{key}'] = {'description': 'Home quick care action; opens the existing care flow, never saves a preset automatically.'}
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
