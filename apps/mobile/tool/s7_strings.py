# One-off generator for the S7 ARB entries (Reminders 8a–8e, 12f, ReminderPeek, notifications).
# Vietnamese = Figma source, English = engineering draft (D-012); copy for D-029…D-032 and the
# not-drawn states is engineering copy awaiting design review. Usage: python3 tool/s7_strings.py
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

INFO_VI = 'Gia đình thấy nhắc việc trong app. Thông báo chỉ được đặt trên máy tạo nhắc việc.'
INFO_EN = 'The family sees reminders in the app. Notifications are set only on the device that created the reminder.'

# 8a / 12f list
s('remindersTitle', 'Nhắc việc', 'Reminders', '8a title (127:13602).')
s('remindersOverdue', 'Quá hạn', 'Overdue', '8a group.')
s('remindersUpcoming', 'Sắp tới', 'Upcoming', '8a group.')
s('remindersDone', 'Đã xong', 'Done', '8a group.')
s('remindersInfo', INFO_VI, INFO_EN, '8a info line (R-091).')
s('reminderNew', 'Nhắc việc mới', 'New reminder', '8a button / 8b title.')
s('reminderCreatedBy', '{who} tạo', 'by {who}', 'ReminderRow meta ("Mẹ tạo").', who='String')
s('reminderOverdueMeta', 'Quá hạn · {when}', 'Overdue · {when}', 'ReminderRow overdue meta.', when='String')
s('reminderDoneMeta', '{who} đánh dấu xong · {date}', '{who} marked done · {date}', 'ReminderRow done meta.', who='String', date='String')
s('dayToday', 'hôm nay', 'today', 'Relative day word.')
s('dayYesterday', 'hôm qua', 'yesterday', 'Relative day word.')
s('dayTomorrow', 'ngày mai', 'tomorrow', 'Relative day word.')
s('remindersEmpty', 'Chưa có nhắc việc', 'No reminders yet', 'Empty list (not drawn).')
s('remindersEmptyBody', 'Ghi lịch tiêm, tái khám hay việc cần mua để cả nhà cùng thấy.', 'Add vaccinations, check-ups or things to buy so the whole family sees them.', 'Empty list body (not drawn).')
s('remindersCaregiverNote', 'Ba mẹ tạo nhắc việc. Bạn xem và đánh dấu Xong.', 'Parents create reminders. You view them and mark them done.', '12f role note (192:1327).')
s('remindersNotifOff', 'Đã lưu nhắc việc. Chưa bật thông báo trên máy này.', 'Reminder saved. Notifications are off on this device.', '8d notice (127:13867).')
s('remindersOpenSettings', 'Cài đặt', 'Settings', '8d link.')
s('reminderSaved', 'Đã lưu nhắc việc', 'Reminder saved', '8c toast.')
s('reminderMarkedDone', 'Đã đánh dấu xong', 'Marked done', 'Toast.')
s('reminderMarkedUndone', 'Đã đánh dấu chưa xong', 'Marked not done', 'Toast (D-030).')
s('reminderDeleted', 'Đã xoá nhắc việc', 'Reminder deleted', 'Toast (D-030).')
s('reminderMoved', 'Thông báo sẽ đến trên máy này', 'Notifications will come to this device', 'Toast (D-029).')
# 8b sheet
s('reminderEditTitle', 'Sửa nhắc việc', 'Edit reminder', '8e button / edit sheet title.')
s('reminderWhat', 'Việc cần nhớ', 'Thing to remember', '8b field.')
s('reminderWhatHint', 'Ví dụ: Tiêm 6 trong 1', 'e.g. 6-in-1 vaccine', '8b placeholder.')
s('reminderWhen', 'Ngày giờ', 'Date & time', '8b / 8e row.')
s('reminderLead', 'Báo trước', 'Remind me', '8b / 8e row.')
s('reminderFootnote', 'Theo giờ của {name} ({zone}). ' + INFO_VI, 'In {name}’s time zone ({zone}). ' + INFO_EN, '8b footnote.', name='String', zone='String')
s('reminderSave', 'Lưu nhắc việc', 'Save reminder', '8b button.')
s('reminderTitleRequired', 'Nhập việc cần nhớ.', 'Enter what to remember.', 'Validation.')
s('reminderPastTime', 'Chọn thời điểm sau bây giờ.', 'Choose a time after now.', 'Validation (D-031).')
s('leadOnTime', 'Đúng giờ', 'At the time', 'Báo trước option (D-031).')
s('leadOneDay', '1 ngày', '1 day', 'Báo trước option (D-031).')
s('leadBefore', '{lead} trước', '{lead} before', 'Báo trước value in lists.', lead='String')
s('reminderDelete', 'Xoá nhắc việc', 'Delete reminder', 'Edit sheet (D-030).')
s('reminderDeleteTitle', 'Xoá nhắc việc này?', 'Delete this reminder?', 'Confirm (D-030).')
s('reminderDeleteBody', 'Cả nhà sẽ không thấy nhắc việc này nữa.', 'No one in the family will see it any more.', 'Confirm (D-030).')
# 8c pre-prompt
s('notifPromptTitle', 'Bật thông báo trên máy này?', 'Turn on notifications on this device?', '8c (127:13809).')
s('notifPromptBody', INFO_VI, INFO_EN, '8c body.')
s('notifPromptAllow', 'Bật thông báo', 'Turn on notifications', '8c primary.')
# 8e detail
s('reminderOverline', 'Nhắc việc · {name}', 'Reminder · {name}', '8e overline.', name='String')
s('reminderTimeZone', 'Múi giờ', 'Time zone', '8e row.')
s('reminderNotify', 'Thông báo', 'Notification', '8e row.')
s('reminderDeviceOf', '{device} của {name}', '{name}’s {device}', '8e value ("iPhone của Mai").', device='String', name='String')
s('reminderNoDevice', 'Chưa đặt trên máy nào', 'Not set on any device', '8e value, no device (D-029).')
s('reminderCreator', 'Người tạo', 'Created by', '8e row.')
s('reminderDoneRow', 'Đã xong', 'Done', '8e row for a done reminder.')
s('reminderDetailNote', 'Thông báo chỉ được đặt trên máy tạo nhắc việc. Đánh dấu xong khi đã làm.', 'Notifications are set only on the device that created the reminder. Mark it done once it’s done.', '8e note.')
s('reminderMarkDone', 'Đánh dấu đã xong', 'Mark as done', '8e primary.')
s('reminderUndo', 'Đánh dấu chưa xong', 'Mark as not done', '8e for a done reminder (D-030).')
s('moveNotifTitle', 'Nhận thông báo trên máy này?', 'Get notifications on this device?', 'D-029 sheet.')
s('moveNotifBody', 'Thông báo của nhắc việc này sẽ chuyển sang {device}. Máy đang giữ thông báo sẽ không báo nữa.', 'This reminder’s notification moves to {device}. The device that has it now stops notifying.', 'D-029 sheet.', device='String')
s('moveNotifAction', 'Chuyển sang máy này', 'Move to this device', 'D-029 sheet.')
# ReminderPeek (128:665)
s('reminderPeekLabel', 'Nhắc việc · {count}', 'Reminders · {count}', 'ReminderPeek label.', count='int')
s('reminderInDays', 'còn {count} ngày', '{count, plural, =1{in 1 day} other{in {count} days}}', 'ReminderPeek countdown.', count='int')
s('reminderInDuration', 'còn {duration}', 'in {duration}', 'ReminderPeek countdown, same day.', duration='String')
s('reminderPeekEmpty', 'Chưa có nhắc việc sắp tới', 'No upcoming reminders', 'ReminderPeek empty (not drawn).')
s('reminderPeekAdd', 'Tạo nhắc việc', 'Add a reminder', 'ReminderPeek empty action.')
# Notifications
s('notifBody', '{name} · {when}', '{name} · {when}', 'Local notification body.', name='String', when='String')
s('notifChannel', 'Nhắc việc', 'Reminders', 'Android channel name.')
s('notifChannelDescription', 'Nhắc việc của gia đình', 'Family reminders', 'Android channel description.')
s('a11yMarkDone', 'Đánh dấu xong: {title}', 'Mark done: {title}', 'Row check.', title='String')
s('a11yUndoDone', 'Bỏ đánh dấu xong: {title}', 'Mark not done: {title}', 'Row check (D-030).', title='String')

def placeholders(ph):
    return {k: {'type': v} for k, v in ph.items()}

root = pathlib.Path(__file__).resolve().parent.parent / 'lib' / 'l10n'
for locale, idx in (('vi', 0), ('en', 1)):
    path = root / f'app_{locale}.arb'
    data = json.loads(path.read_text(), object_pairs_hook=collections.OrderedDict)
    for key, (vi, en, desc, ph) in S.items():
        data[key] = (vi, en)[idx]
        if locale == 'vi':
            meta = collections.OrderedDict(description=desc)
            if ph:
                meta['placeholders'] = placeholders(ph)
            data['@' + key] = meta
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
print(len(S), 'strings')
