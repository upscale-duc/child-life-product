"""Clarify Premium paywall benefits (Figma flow 1134:3884, 2026-10-26).

Copy only: retain configured quotas, interpolation, billing/legal text and permissions.
Idempotent; preserves metadata/placeholder types and unrelated catalogue entries.
Run: python3 tool/premium_paywall_wording.py && flutter gen-l10n
"""
import json
from pathlib import Path

COPY = {
    'pv2HeadVideo': ('Tạo video kỷ niệm của {name}', 'Create a memory video for {name}'),
    'pv2HeadCard': ('Tạo thiệp dành riêng cho {name}', 'Create a card for {name}'),
    'pv2HeadCaregivers': ('Thêm người cùng chăm {name}', 'Invite more people to care for {name}'),
    'pv2HeadExplore': ('Nâng cấp lên Premium', 'Upgrade to Premium'),
    'pv2ReasonCaregivers': ('Gói Free: {used} / {limit} người có quyền ghi.', 'Free plan: {used} / {limit} people with logging access.'),
    'pv2CardVideoTitle': ('Ghép ảnh thành video kỷ niệm', 'Turn photos into a memory video'),
    'pv2CardVideoBody': ('Chọn ảnh, thêm lời nhắn và nhạc cho video của con.', 'Choose photos, add a message and set your video to music.'),
    'pv2CardVideoLimit': ('{n} lượt xuất video mỗi tháng', '{n, plural, one{{n} video export per month} other{{n} video exports per month}}'),
    'pv2CardCardBody': ('Thêm tên, ảnh và lời nhắn theo mẫu bạn chọn.', 'Add a name, photos and a message to your chosen design.'),
    'pv2CardLumiTitle': ('Hỏi Lumi về nhật ký của con', 'Ask Lumi about your baby’s logs'),
    'pv2CardLumiBody': ('Lumi tóm tắt nhật ký, soạn bản ghi để bạn xem lại rồi lưu.', 'Get log summaries and drafts to review before saving.'),
    'pv2CardLumiLimit': ('{n} credit/tháng · cả nhà dùng chung', '{n, plural, one{{n} credit/month} other{{n} credits/month}} · shared by your family'),
    'pv2CardRhythmTitle': ('Nhìn lại nhịp bú, ngủ của con', 'Look back at feeds and sleep'),
    'pv2CardRhythmBody': ('Lumi tóm tắt nhật ký, kèm thời gian so sánh và nguồn.', 'Lumi summarises the logs with comparison dates and sources.'),
    'pv2CardRhythmLimit': ('Dùng chung {n} credit Lumi/tháng', 'Uses the same {n, plural, one{{n} monthly Lumi credit} other{{n} monthly Lumi credits}}'),
    'pv2CardStorageTitle': ('Thêm chỗ lưu ảnh và video', 'More room for photos and videos'),
    'pv2CardStorageBody': ('Dung lượng dùng chung cho ảnh và video của cả gia đình.', 'Shared storage for your family’s photos and videos.'),
    'pv2CardStorageLimit': ('{gb} GB dùng chung cho cả nhà', '{gb} GB shared by your family'),
    'pv2CardCaregiversTitle': ('Cùng ghi nhật ký chăm con', 'Keep care logs together'),
    'pv2CardCaregiversBody': ('Cùng ghi cữ bú, giấc ngủ và xem cập nhật trong nhật ký.', 'Log feeds and sleep together, and check updates in the journal.'),
    'pv2CardCaregiversLimit': ('{premium} người có quyền ghi · Free: {free}', '{premium, plural, one{{premium} person can log care} other{{premium} people can log care}} · Free: {free}'),
    'pv2CompareTitle': ('So sánh Free và Premium', 'Compare Free and Premium'),
    'pv2RowLumi': ('Lumi', 'Lumi'),
    'pv2RowVideo': ('Xuất video kỷ niệm', 'Memory video exports'),
    'pv2RowCaregivers': ('Người có quyền ghi', 'People who can log care'),
    'pv2RowRhythmPremium': ('Tóm tắt tuần · có nguồn', 'Weekly summary · with sources'),
    'pv2PeriodYear': ('Gói năm', 'Yearly plan'),
    'pv2PeriodMonth': ('Gói tháng', 'Monthly plan'),
    'pv2DemoUploading': ('3 video đang tải lên', '3 videos uploading'),
    'pv2DemoCareNote': ('Free cũng có nhật ký chung; Premium thêm chỗ cho người ghi.', 'Shared logs are included in Free; Premium lets more people log care.'),
}

root = Path(__file__).resolve().parent.parent / 'lib' / 'l10n'
for index, locale in enumerate(('vi', 'en')):
    path = root / f'app_{locale}.arb'
    data = json.loads(path.read_text())
    for key, values in COPY.items():
        if key not in data:
            raise SystemExit(f'Missing {key} in {path.name}')
        data[key] = values[index]
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
print(f'Updated {len(COPY)} Premium paywall strings in both languages')

# D-124 supersedes the earlier count-based copy. Keep reruns safe after the reviewed flow ships.
import runpy
runpy.run_path(str(Path(__file__).with_name('premium_flow_strings.py')))
