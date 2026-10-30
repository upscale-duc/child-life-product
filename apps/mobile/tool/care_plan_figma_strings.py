# Cùng Chăm Con rebuilt to the Figma section 1349:22026 (D-137: this feature matches its frames).
# Vietnamese is the Figma copy; English is an engineering draft for owner review (D-012).
# Idempotent. Usage: python3 tool/care_plan_figma_strings.py && flutter gen-l10n
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

NOTE = ' EN is an engineering draft for owner review.'

# 04 / 04b summary card
s('cpTodayCount', '{count, plural, other{Hôm nay có {count} việc}}', '{count, plural, =1{1 task today} other{{count} tasks today}}',
  'Cùng Chăm Con 04: the day card before anything is done (Figma 1380:21966).' + NOTE, count='int')
s('cpFirstTask', 'Việc đầu tiên {time} · {task}', 'First up {time} · {task}',
  'Cùng Chăm Con 04: the first task of the day.' + NOTE, time='String', task='String')
s('cpPersonCount', '{name} · {count}', '{name} · {count}',
  'Cùng Chăm Con 04: a person and how many tasks they have today.', name='String', count='int')
s('cpPersonDone', '{name} xong {count}', '{name} did {count}',
  'Cùng Chăm Con 04b: thanks a person for the tasks they did (only people who did some).' + NOTE, name='String', count='int')
s('cpLeftCheer', '{count, plural, other{Còn {count} việc nữa thôi, cả nhà cố lên!}}', '{count, plural, =1{Just 1 more to go, you\'ve got this!} other{Just {count} more to go, you\'ve got this!}}',
  'Cùng Chăm Con 04b: encouragement once something is done (Figma 1380:22470).' + NOTE, count='int')
# 04-0 Chưa có lịch hôm nay
s('cpStartSub', 'Tạo nhanh trong 1 chạm, sửa sau cũng được', 'One tap to start, change it any time',
  'Cùng Chăm Con 04-0: under "Hôm nay chưa có lịch" (Figma 1390:21780).' + NOTE)
s('cpStartRhythmOf', 'Theo nhịp {name}', 'Follow {name}\'s rhythm',
  'Cùng Chăm Con 01 / 04-0: the rhythm draft with the baby\'s name.' + NOTE, name='String')
s('cpChosen', 'Đã chọn', 'Your pick', 'Cùng Chăm Con 04-0: badge on the way the family chose before.' + NOTE)
s('cpChosenSub', 'Cách cả nhà chọn lúc đầu', 'The way your family chose',
  'Cùng Chăm Con 04-0: under the remembered way.' + NOTE)
s('cpCreateToday', 'Tạo lịch hôm nay', 'Make today\'s plan', 'Cùng Chăm Con 04-0: primary action.' + NOTE)
s('cpCreateDay', 'Tạo lịch', 'Make the plan', 'Cùng Chăm Con 04-0 / 01c: primary action for another day, or Tự tạo.' + NOTE)

# 01 Chọn cách lên lịch
s('cpChooseTitle', 'Lên lịch cho {name}', 'Plan the day for {name}',
  'Cùng Chăm Con 01: the page title (Figma 1377:21908).' + NOTE, name='String')
s('cpSuggestBadge', 'Gợi ý', 'Suggested', 'Cùng Chăm Con 01: badge on "Theo nhịp" (the family\'s own rhythm).' + NOTE)
s('cpRhythmFrom', 'Từ 7 ngày ghi nhận', 'From the last 7 days logged',
  'Cùng Chăm Con 01: under "Theo nhịp" (D-136 #2: 7 of 7 days).' + NOTE)
s('cpEasySection', 'Theo EASY', 'EASY routines', 'Cùng Chăm Con 01: the EASY templates section.' + NOTE)
s('cpEasy35Sub', '6 tuần – 4 tháng · 3–4 giấc', '6 weeks – 4 months · 3–4 naps',
  'Cùng Chăm Con 01: who EASY 3.5 is for (docs/design/explorations/cung-cham-con/templates-draft.md).' + NOTE)
s('cpEasy4Sub', '4 – 6 tháng · 3 giấc', '4 – 6 months · 3 naps',
  'Cùng Chăm Con 01: who EASY 4 is for (D-136 #4: EASY only under 6 months).' + NOTE)
s('cpFitsAge', 'Hợp tuổi', 'Fits the age', 'Cùng Chăm Con 01: badge on the EASY that fits the baby\'s age.' + NOTE)
s('cpOtherSection', 'Khác', 'Other ways', 'Cùng Chăm Con 01: the other ways to start the day.' + NOTE)
s('cpByAge', 'Theo tuổi', 'By age', 'Cùng Chăm Con 01: the age-based template (basic).' + NOTE)
s('cpByAgeSub', 'Nếp chuẩn cho bé {age}', 'A usual day at {age}',
  'Cùng Chăm Con 01: under "Theo tuổi"; age is "4 tháng" / "2 tuổi".' + NOTE, age='String')
s('cpSelfMade', 'Tự tạo', 'Make your own', 'Cùng Chăm Con 01: start with no tasks and add them.' + NOTE)
s('cpSelfMadeSub', 'Tự đặt giờ và việc', 'Set your own times and tasks', 'Cùng Chăm Con 01: under "Tự tạo".' + NOTE)
s('cpPreview', 'Xem trước lịch', 'Preview the plan',
  'Cùng Chăm Con 01: primary action for a way that makes a draft to check first.' + NOTE)

# 02 Gợi ý cho Teddy (a draft day)
s('cpTodayPlan', 'Lịch hôm nay', 'Today\'s plan', 'Cùng Chăm Con 02: the bar title on a draft day (Figma 1388:21646).' + NOTE)
s('cpDraftHeading', 'Gợi ý cho {name}', 'Suggested for {name}',
  'Cùng Chăm Con 02: a drafted day, before anyone uses it (D-136).' + NOTE, name='String')
s('cpDraftFromRhythm', 'Theo nhịp 7 ngày qua', 'From the last 7 days',
  'Cùng Chăm Con 02: the draft came from the baby\'s own rhythm.' + NOTE)
s('cpDraftFrom', 'Theo {way}', 'From {way}',
  'Cùng Chăm Con 02: the draft came from a template ("Theo EASY 4", "Theo tuổi").' + NOTE, way='String')
s('cpChangeShort', 'Đổi cách', 'Change', 'Cùng Chăm Con 02: pick another way for the draft.' + NOTE)
s('cpDraftNote', 'Giờ chỉ là gợi ý, con vẫn dẫn nhịp', 'Times are a guide; your baby leads',
  'Cùng Chăm Con 02: under the draft, above "Dùng lịch này".' + NOTE)
s('cpTimelineA11y', 'Ngày của bé: {feeds} cữ bú, {sleeps} giấc ngủ', 'The day: {feeds} feeds, {sleeps} sleeps',
  'Cùng Chăm Con 02: what the day strip shows, for screen readers.' + NOTE, feeds='int', sleeps='int')

# 05 Giao việc
s('cpAssignSpan', '{count, plural, other{{count} việc}} · {from} – {to}', '{count, plural, =1{1 task} other{{count} tasks}} · {from} – {to}',
  'Cùng Chăm Con 05: under "Giao ca sáng cho ai?", the part of the day being given (Figma 1381:22083).' + NOTE,
  count='int', **{'from': 'String'}, to='String')
s('cpMemberLine', '{relation} · {load}', '{relation} · {load}',
  'Cùng Chăm Con 05: a person\'s relation and how many tasks they have ("Bà nội · 1 việc hôm nay").',
  relation='String', load='String')
s('cpManyPeople', 'Nhiều người', 'Several people', 'Cùng Chăm Con 05: give the task or the part of the day to more than one person.' + NOTE)
s('cpManyPeopleGroup', 'Chọn người cho từng việc', 'Pick someone for each task',
  'Cùng Chăm Con 05: under "Nhiều người" for a part of the day: closes the sheet so each task is given on its own.' + NOTE)
s('cpManyPeopleTask', 'Cùng làm việc này', 'Do this task together',
  'Cùng Chăm Con 05: under "Nhiều người" for one task: pick several people.' + NOTE)
# 06 Thêm việc
s('cpAddToPlan', 'Thêm vào lịch', 'Add to the plan', 'Cùng Chăm Con 06: primary action (Figma 1381:22208).' + NOTE)
s('cpSearchTask', 'Tìm việc, vd: uống thuốc', 'Find a task, e.g. medicine', 'Cùng Chăm Con 06: search field placeholder.' + NOTE)
s('cpSuggestedFor', 'Hay dùng cho bé {age}', 'Common at {age}',
  'Cùng Chăm Con 06: the tasks a child of this age usually has; age is "4 tháng" / "2 tuổi".' + NOTE, age='String')
s('cpCatFood', 'Ăn uống', 'Food and drink', 'Cùng Chăm Con 06: task group.' + NOTE)
s('cpCatPlay', 'Chơi & vận động', 'Play and movement', 'Cùng Chăm Con 06: task group.' + NOTE)
s('cpCatCare', 'Sức khoẻ & vệ sinh', 'Health and hygiene', 'Cùng Chăm Con 06: task group.' + NOTE)
s('cpCreateOwn', 'Tạo việc riêng', 'Create your own', 'Cùng Chăm Con 06: a task with its own name (dashed chip).' + NOTE)
s('cpNoTaskFound', 'Không có việc nào khớp. Tạo việc riêng nhé.', 'No task matches. Create your own.',
  'Cùng Chăm Con 06: the search found nothing.' + NOTE)
# 06b Sửa / xoá việc
s('cpShiftOf', 'Ca {period}', '{period}', 'Cùng Chăm Con 06b: under the task name ("Ca tối"); period is lower-case Sáng / Chiều / Tối.' + NOTE, period='String')
s('cpDoer', 'Người làm', 'Who', 'Cùng Chăm Con 06b: the row with who does the task (Figma 1360:23266).' + NOTE)
s('cpApply', 'Áp dụng', 'Repeat', 'Cùng Chăm Con 06b: today only or every day.' + NOTE)
s('cpSkipOk', 'Bỏ qua hôm nay cũng được', 'Fine to skip it today', 'Cùng Chăm Con 06b: the gentle skip notice.' + NOTE)
s('cpSkipShort', 'Bỏ qua', 'Skip', 'Cùng Chăm Con 06b: skip today (in the notice).' + NOTE)
s('cpUnskipShort', 'Làm lại', 'Undo skip', 'Cùng Chăm Con 06b: a skipped task is back on today.' + NOTE)
s('cpDeleteShort', 'Xoá', 'Delete', 'Cùng Chăm Con 06b: delete the task (beside Lưu).' + NOTE)

# 14 / 15 Hôm nay
s('cpAssignedBadge', 'Phân việc', 'Shared plan',
  'Cùng Chăm Con 14 / 15: badge on a task that comes from the family plan (Figma 1383:22120).' + NOTE)
s('cpAskedBy', '{who} nhờ {me} nhé', '{who} asked you',
  'Cùng Chăm Con 15: who gave this task to the viewer ("Mẹ nhờ Ba nhé"); me is the viewer\'s relation.' + NOTE,
  who='String', me='String')
s('cpDueLaterShort', 'Để sau 10′', 'Later · 10′', 'Cùng Chăm Con 15: snooze ten minutes, beside Đã làm.' + NOTE)

# 13 Cài đặt
s('cpSettingsTitle', 'Cài đặt', 'Settings', 'Cùng Chăm Con 13: the page title (Figma 1354:22802).' + NOTE)
s('cpRemindSection', 'Nhắc việc', 'Reminders', 'Cùng Chăm Con 13: the person\'s own reminder settings.' + NOTE)
s('cpPlanSection', 'Lịch', 'Plan', 'Cùng Chăm Con 13: the family plan settings (plan managers).' + NOTE)

# D-138 Cùng Chăm Con ↔ Care
s('cpAmount', 'Lượng', 'Amount', 'Cùng Chăm Con 06 / 06b: the planned ml of a bottle or pumping (D-138).' + NOTE)
s('cpMl', '{ml} ml', '{ml} ml', 'Cùng Chăm Con: an amount in ml on a chip.', ml='int')
s('cpTaskWithMl', '{task} · {ml} ml', '{task} · {ml} ml', 'Cùng Chăm Con: a task with its planned amount ("Bú bình · 120 ml").', task='String', ml='int')
s('cpNoAmount', 'Chưa định', 'Not set', 'Cùng Chăm Con 06: no planned amount; the log asks.' + NOTE)

s('cpHistoryFrom', 'Việc trong lịch', 'From the plan',
  'Lịch sử: a finished Cùng Chăm Con task that is not a care log (Tắm, Nằm sấp…), D-138.' + NOTE)
s('cpHistoryFromBy', 'Việc trong lịch · {who} làm', 'From the plan · done by {who}',
  'Lịch sử: a finished Cùng Chăm Con task and who did it, D-138.' + NOTE, who='String')

# 20 Lịch sử thay đổi
s('cpHistTitle', 'Lịch sử thay đổi', 'Change history', 'Cùng Chăm Con 20: page title and the 13 row (Figma 1360:23617).' + NOTE)
s('cpHistToday', 'Hôm nay', 'Today', 'Cùng Chăm Con 20: group header.' + NOTE)
s('cpHistYesterday', 'Hôm qua', 'Yesterday', 'Cùng Chăm Con 20: group header.' + NOTE)
s('cpHistMoved', '{task} {from} → {to}', '{task} {from} → {to}', 'Cùng Chăm Con 20: a task moved to another time.', task='String', **{'from': 'String'}, to='String')
s('cpHistEdited', 'Sửa “{task}” {time}', 'Edited “{task}” {time}', 'Cùng Chăm Con 20: a task changed (not its time).' + NOTE, task='String', time='String')
s('cpHistAdded', 'Thêm “{task}” {time}', 'Added “{task}” {time}', 'Cùng Chăm Con 20: a task added.' + NOTE, task='String', time='String')
s('cpHistDeleted', 'Xoá “{task}” {time}', 'Deleted “{task}” {time}', 'Cùng Chăm Con 20: a task deleted.' + NOTE, task='String', time='String')
s('cpHistEveryDay', 'mọi ngày', 'every day', 'Cùng Chăm Con 20: after an add / edit / delete that keeps or removes it every day.' + NOTE)
s('cpHistThatDay', 'chỉ ngày đó', 'that day only', 'Cùng Chăm Con 20: after a delete of one day.' + NOTE)
s('cpHistAssigned', 'Giao “{task}” cho {who}', 'Gave “{task}” to {who}', 'Cùng Chăm Con 20: one task given to people.' + NOTE, task='String', who='String')
s('cpHistAssignedMany', '{count, plural, other{Giao {count} việc cho {who}}}', '{count, plural, =1{Gave 1 task to {who}} other{Gave {count} tasks to {who}}}', 'Cùng Chăm Con 20: a part of the day given at once.' + NOTE, count='int', who='String')
s('cpHistUnassigned', 'Bỏ người làm “{task}”', 'Cleared who does “{task}”', 'Cùng Chăm Con 20: nobody on the task now.' + NOTE, task='String')
s('cpHistSkipped', 'Bỏ qua “{task}” {time}', 'Skipped “{task}” {time}', 'Cùng Chăm Con 20: a task skipped that day.' + NOTE, task='String', time='String')
s('cpHistStarted', 'Lên lịch {way}', 'Planned the day: {way}', 'Cùng Chăm Con 20: the day was started a way ("Lên lịch Giống hôm qua").' + NOTE, way='String')
s('cpHistAutoDraft', 'Tự tạo bản nháp buổi sáng', 'Made the morning draft', 'Cùng Chăm Con 20: the morning draft made by Child Life (D-136 #3).' + NOTE)
s('cpHistPublished', 'Dùng lịch này', 'Used this plan', 'Cùng Chăm Con 20: a draft put in use.' + NOTE)
s('cpHistUndo', 'Hoàn tác', 'Undo', 'Cùng Chăm Con 20: revert this change.' + NOTE)
s('cpHistUndone', 'Đã hoàn tác', 'Undone', 'Cùng Chăm Con 20: toast after Hoàn tác.' + NOTE)
s('cpHistEmpty', 'Chưa có thay đổi nào', 'No changes yet', 'Cùng Chăm Con 20: nothing changed in the last 30 days.' + NOTE)
s('cpHistEmptyBody', 'Ai sửa, thêm hay giao việc sẽ hiện ở đây.', 'Who edits, adds or gives tasks shows here.', 'Cùng Chăm Con 20: empty state body.' + NOTE)
s('cpHistSomeone', 'Một người đã rời nhà', 'Someone who left', 'Cùng Chăm Con 20: the author is no longer in the family.' + NOTE)

# 11 Báo cáo / 12 Thẻ chia sẻ
s('cpReportTitle', 'Cùng nhau chăm', 'Caring together', 'Cùng Chăm Con 11: page title (Figma 1353:22754).' + NOTE)
s('cpReportOpen', 'Xem báo cáo cùng chăm', 'See the caring report', 'Cùng Chăm Con 04: the chart button in the bar (a11y).' + NOTE)
s('cpRangeWeek', 'Tuần', 'Week', 'Cùng Chăm Con 11: range.' + NOTE)
s('cpRangeMonth', 'Tháng', 'Month', 'Cùng Chăm Con 11: range.' + NOTE)
s('cpRangeYear', 'Năm', 'Year', 'Cùng Chăm Con 11: range.' + NOTE)
s('cpReportTasks', '{count, plural, other{việc}}', '{count, plural, =1{task} other{tasks}}', 'Cùng Chăm Con 11: under the number in the ring.' + NOTE, count='int')
s('cpReportHearts', 'tim', 'hearts', 'Cùng Chăm Con 11: thanks received ("48 tim"); counted once thả tim exists (step 5).' + NOTE)
s('cpReportStreak', 'ngày liền', 'days in a row', 'Cùng Chăm Con 11: days in a row with a task done.' + NOTE)
s('cpReportOnTime', 'đúng nhịp', 'on rhythm', 'Cùng Chăm Con 11: share of tasks done within 30 minutes of their time.' + NOTE)
s('cpReportEmpty', 'Chưa có việc nào xong trong khoảng này', 'No tasks done in this period yet', 'Cùng Chăm Con 11: nothing done yet.' + NOTE)
s('cpBadgesWeek', 'Huy hiệu tuần này', 'This week\'s badges', 'Cùng Chăm Con 11: badges section.' + NOTE)
s('cpBadgeBath', 'Siêu tắm', 'Bath star', 'Cùng Chăm Con 11 badge: 3 baths in a week (owner-approved rule, D-138).' + NOTE)
s('cpBadgeNight', 'Cú đêm', 'Night owl', 'Cùng Chăm Con 11 badge: 3 tasks between 22:00 and 05:00 (owner-approved rule, D-138).' + NOTE)
s('cpBadgeStory', 'Kể chuyện', 'Storyteller', 'Cùng Chăm Con 11 badge: 3 reading tasks (owner-approved rule, D-138).' + NOTE)
s('cpBadgeBottle', 'Bình sữa vàng', 'Golden bottle', 'Cùng Chăm Con 11 badge: 10 feeds (owner-approved rule, D-138).' + NOTE)
s('cpBadgeDiaper', 'Tã thần tốc', 'Diaper dash', 'Cùng Chăm Con 11 badge: 10 diapers (owner-approved rule, D-138).' + NOTE)
s('cpBadgeGrand', 'Ông bà siêu sao', 'Super grandparent', 'Cùng Chăm Con 11 badge: a grandparent did 5 tasks (owner-approved rule, D-138).' + NOTE)
s('cpBadgeOnTime', 'Đúng giờ 7 ngày', 'On time all week', 'Cùng Chăm Con 11 badge: 7 days with every task on rhythm (owner-approved rule, D-138).' + NOTE)
s('cpBadgeTeam', 'Đồng đội ăn ý', 'Great team', 'Cùng Chăm Con 11 badge: 3 people did 3 tasks each (owner-approved rule, D-138).' + NOTE)
s('cpBadgeVitamin', 'Vitamin đều đặn', 'Vitamin every day', 'Cùng Chăm Con 11 badge: vitamin 7 days (owner-approved rule, D-138).' + NOTE)
s('cpBadgeLocked', '{name}, chưa đạt', '{name}, not yet', 'Cùng Chăm Con 11: a badge not earned (a11y).' + NOTE, name='String')
s('cpBadgeBy', '{name}, của {who}', '{name}, earned by {who}', 'Cùng Chăm Con 11: who earned a badge (a11y).' + NOTE, name='String', who='String')
s('cpShowFamily', 'Khoe cả nhà', 'Share with the family', 'Cùng Chăm Con 11: primary action, opens the share card.' + NOTE)
s('cpShareTitle', 'Chia sẻ', 'Share', 'Cùng Chăm Con 12: sheet title (Figma 1382:22199).' + NOTE)
s('cpShareWeek', 'Tuần {week}', 'Week {week}', 'Cùng Chăm Con 12: the week number on the card.', week='int')
s('cpShareMonth', 'Tháng {month}', 'Month {month}', 'Cùng Chăm Con 12: the month on the card.', month='int')
s('cpShareHeadline', 'Tuần này cả nhà cùng chăm {name}', 'This week the whole family cared for {name}', 'Cùng Chăm Con 12: card headline (week).' + NOTE, name='String')
s('cpShareHeadlineMonth', 'Tháng này cả nhà cùng chăm {name}', 'This month the whole family cared for {name}', 'Cùng Chăm Con 12: card headline (month).' + NOTE, name='String')
s('cpShareHeadlineYear', 'Năm nay cả nhà cùng chăm {name}', 'This year the whole family cared for {name}', 'Cùng Chăm Con 12: card headline (year).' + NOTE, name='String')
s('cpShareThanks', '{count} lời cảm ơn trong nhà tuần này', '{count} thank-yous at home this week', 'Cùng Chăm Con 12: hearts line (hidden at 0).' + NOTE, count='int')
s('cpShareStory', 'Story', 'Story', 'Cùng Chăm Con 12: share the card image as a story.')
s('cpShareCopy', 'Sao chép', 'Copy', 'Cùng Chăm Con 12: copy the summary text.' + NOTE)
s('cpShareMore', 'Khác', 'More', 'Cùng Chăm Con 12: the system share sheet.' + NOTE)
s('cpShareCopied', 'Đã sao chép', 'Copied', 'Cùng Chăm Con 12: toast after Sao chép.' + NOTE)
s('cpShareText', '{headline}: {count} việc. {people}', '{headline}: {count} tasks. {people}', 'Cùng Chăm Con 12: the copied summary.' + NOTE, headline='String', count='int', people='String')
s('cpShareFailed', 'Chưa chia sẻ được. Thử lại nhé.', 'Couldn\'t share. Try again.', 'Cùng Chăm Con 12: share failed.' + NOTE)

# N1 push buttons on Android (iOS registers its own, RuleNotifications.swift)
s('cpPushSnooze10', 'Nhắc lại 10 phút', 'Remind me in 10 min',
  'Cùng Chăm Con N1: the task push\'s second button; it rings again in ten minutes (Figma 1353:22588).' + NOTE)

# 10 Vừa xong · N2 / N3 (Figma 1353:22683, 1353:22588)
s('cpDidLine', '{who} vừa {task, select, bottle{cho {baby} bú bình} breast{cho {baby} bú mẹ} pump{hút sữa cho {baby}} solids{cho {baby} ăn dặm} water{cho {baby} uống nước} sleep{ru {baby} ngủ} diaper{thay tã cho {baby}} bath{tắm cho {baby}} tummy{cho {baby} nằm sấp} read{đọc sách cho {baby}} walk{đưa {baby} đi dạo} vitamin{cho {baby} uống vitamin} medicine{cho {baby} uống thuốc} temperature{đo nhiệt độ cho {baby}} teeth{đánh răng cho {baby}} potty{cho {baby} ngồi bô} other{xong một việc cho {baby}}}', '{who} just {task, select, bottle{gave {baby} a bottle} breast{breastfed {baby}} pump{pumped milk for {baby}} solids{fed {baby} solids} water{gave {baby} some water} sleep{put {baby} to sleep} diaper{changed {baby}’s diaper} bath{gave {baby} a bath} tummy{did tummy time with {baby}} read{read to {baby}} walk{took {baby} for a walk} vitamin{gave {baby} vitamins} medicine{gave {baby} medicine} temperature{checked {baby}’s temperature} teeth{brushed {baby}’s teeth} potty{helped {baby} on the potty} other{did a task for {baby}}}',
  'Cùng Chăm Con 10: the title, who did what for the baby (mirrors carePlanDidPhrases in contracts).' + NOTE, who='String', task='String', baby='String')
s('cpReactThanks', 'Cảm ơn', 'Thanks', 'Cùng Chăm Con 10: the star reaction.' + NOTE)
s('cpReactGreat', 'Tuyệt', 'Great', 'Cùng Chăm Con 10: the spark reaction.' + NOTE)
s('cpReactHeart', 'Thả tim', 'Send a heart', 'Cùng Chăm Con 10 / N2: the heart reaction (also the push button).' + NOTE)
s('cpThanksName', 'Cảm ơn {who}!', 'Thank you, {who}!', 'Cùng Chăm Con 10: quick line.' + NOTE, who='String')
s('cpThanksProud', '{who} giỏi quá', 'You’re amazing, {who}', 'Cùng Chăm Con 10: quick line.' + NOTE, who='String')
s('cpThanksLove', 'Thương {who}', 'Love you, {who}', 'Cùng Chăm Con 10: quick line.' + NOTE, who='String')
s('cpSendTo', 'Gửi cho {who}', 'Send to {who}', 'Cùng Chăm Con 10: the main action; the one who did it gets a push (N3).' + NOTE, who='String')
s('cpSentTo', 'Đã gửi cho {who}', 'Sent to {who}', 'Cùng Chăm Con 10: toast after sending.' + NOTE, who='String')
s('cpDoneMissing', 'Việc này không còn đánh dấu xong', 'This task is no longer marked done',
  'Cùng Chăm Con 10: the task was un-ticked or deleted since the push.' + NOTE)
s('cpHeartsFrom', '{count, plural, =0{Chưa có tim nào} other{{count} tim từ cả nhà}}', '{count, plural, =0{No hearts yet} =1{1 heart from the family} other{{count} hearts from the family}}',
  'Cùng Chăm Con 10: what the one who did it sees.' + NOTE, count='int')
s('cpTeamTitle', 'Khi người khác làm xong', 'When someone else finishes',
  'Cùng Chăm Con 13: switch for N2 and N3 (per person, on by default).' + NOTE)
s('cpHeartA11y', 'Thả tim cho {who}', 'Send {who} a heart', 'Cùng Chăm Con 10: heart button label for screen readers.' + NOTE, who='String')

# Existing ids whose Vietnamese copy now follows Figma (English unchanged).
VI = {
    'cpAssignGroup': 'Giao cả ca',
    'cpAssignWhoMorning': 'Giao ca sáng cho ai?',
    'cpAssignWhoAfternoon': 'Giao ca chiều cho ai?',
    'cpAssignWhoEvening': 'Giao ca tối cho ai?',
}

root = pathlib.Path(__file__).resolve().parent.parent / 'lib' / 'l10n'
RENAME = {}
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
    for key, (vi, en, desc) in RENAME.items():
        data[key] = (vi, en)[idx]
        if locale == 'vi':
            data['@' + key] = collections.OrderedDict(description=desc)
    if locale == 'vi':
        for key, vi in VI.items():
            assert key in data, key
            data[key] = vi
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
print(len(S) + len(RENAME), 'strings')
