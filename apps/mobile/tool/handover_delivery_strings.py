"""Do not equate a missing push endpoint with a recipient disabling permission."""
import json
from pathlib import Path
root = Path(__file__).resolve().parents[1] / 'lib/l10n'
values = {
 'vi': 'Đã gửi bàn giao cho {name} trong app. Có thể chưa có thông báo trên máy; bạn có thể chia sẻ thêm.',
 'en': 'Sent the handover to {name} in the app. A device notification may not arrive. You can also share it.',
}
for language, value in values.items():
 path = root / f'app_{language}.arb'
 data = json.loads(path.read_text())
 data['aiSentNoPush'] = value
 if language == 'vi':
  data['@aiSentNoPush']['description'] = 'Handover is stored in-app but recipient has no registered push endpoint or muted handovers. Never asserts OS notifications are disabled. name is the recipient.'
 path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
