# Premium Slice 3 app (grounded AI, plan docs/product/premium-personalization-plan.md §5.5, A1–A3,
# P-151, D-003) and the Nhịp lớn lên leftovers (NL07b observation episodes, the NL02c evening
# check-in prompt). Vietnamese = Figma v2.0 copy (SU01 591:6564, ST01 594:6967, NL07/NL07b
# 573:1109/573:1199, NL10 574:1222, NL10b 574:1317; extract
# docs/discovery/figma-extract/30-personalization-premium.md) where drawn; English = the EN frames
# (591:6830, 594:7096) or an engineering draft for owner review (D-012). The consent text is a
# draft too: it says only what P-151 / D-003 settle and waits for legal (Q-020, Q-070).
# Prefixes: `ai` (AI), `rhEp` / `rhEvening` (rhythm leftovers). Idempotent.
# Usage: python3 tool/ai_strings.py && flutter gen-l10n
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

DRAFT = ' EN is an engineering draft for owner review.'
LEGAL = ' Consent text draft: only what P-151 / D-003 state; legal review Q-020 / Q-070.'

# SU01 Bàn giao (591:6564 / 591:6830).
s('aiHandoverTitle', 'Bàn giao cho người chăm tiếp', 'Handover for the next carer', 'SU01 title; also the entry on Home and NL01.')
s('aiHandoverEntrySub', 'Tóm tắt 3 phần từ ghi nhận của cả nhà', 'A three-part summary from the family’s notes', 'Home / NL01 entry subtitle for a Cùng nuôi.' + DRAFT)
s('aiHandoverEntryLatest', 'Bản mới nhất · {date}', 'Latest · {date}', 'Home / NL01 entry subtitle for a caregiver (reads the latest stored handover).' + DRAFT, date='String')
s('aiHandoverFrom', '{range} · từ {count} ghi nhận của {names}', '{range} · from {count, plural, =1{1 note} other{{count} notes}} by {names}', 'SU01 subtitle ("06/10 – 08/10 · từ 6 ghi nhận của Mẹ, Ba, Cô Lan").', range='String', count='int', names='String')
s('aiHandoverFromCount', '{range} · từ {count} ghi nhận', '{range} · from {count, plural, =1{1 note} other{{count} notes}}', 'SU01 subtitle when the authors are unknown.', range='String', count='int')
s('aiGeneratedAt', 'Tạo lúc {when}', 'Made {when}', 'SU01: when this version was made (NL10 "08/10 · 20:12").' + DRAFT, when='String')
s('aiSectionNoticed', 'Điều đã thấy', 'What was noticed', 'SU01 section 1.')
s('aiSectionHelped', 'Cách từng có ích', 'What helped', 'SU01 section 2.')
s('aiSectionNext', 'Việc có thể chọn tiếp', 'What you could do next', 'SU01 section 3.')
s('aiSectionNote', 'Lưu ý', 'Note', 'SU01 closing note section.' + DRAFT)
s('aiWordedByAi', 'Diễn đạt bởi AI từ ghi nhận đã lưu · số liệu lấy từ nhật ký', 'Worded by AI from saved notes · numbers come from the log', 'SU01 AI label (only on AI-worded text).')
s('aiWordedShort', 'Diễn đạt bởi AI từ ghi nhận đã lưu', 'Worded by AI from saved notes', 'Short AI label (explanation, milestone nudge).')
s('aiTemplateLine', 'Đây là tóm tắt từ những ghi nhận đã lưu.', 'This summary is built from your saved notes.', 'Template label (NL10b / ST01).')
s('aiReport', 'Chưa đúng? Báo lại', 'Not right? Tell us', 'SU01 report button.')
s('aiSendTo', 'Gửi cho {name}', 'Send to {name}', 'SU01 share button naming the caregiver ("Gửi cho Cô Lan").', name='String')
s('aiShare', 'Gửi bản bàn giao', 'Share handover', 'SU01 share button without a caregiver.' + DRAFT)
s('aiShareAiLine', '(Diễn đạt bởi AI từ ghi nhận đã lưu)', '(Worded by AI from saved notes)', 'Shared text footer for AI text.')
s('aiShareTemplateLine', '(Tóm tắt theo mẫu từ ghi nhận đã lưu)', '(Template summary from saved notes)', 'Shared text footer for the template.' + DRAFT)
s('aiLoading', 'Đang tổng hợp ghi nhận…', 'Putting the notes together…', 'SU01 while generating.' + DRAFT)
s('aiNoSections', 'Chưa có đủ ghi nhận để bàn giao. Ghi nhận hôm nay để bắt đầu.', 'Not enough notes for a handover yet. Add today’s note to start.', 'SU01 with no section.' + DRAFT)

# Record links instead of [F1] (SU01 chips "Ghi nhận của Ba · 07/10").
s('aiChipCheckIn', 'Ghi nhận của {who} · {date}', '{who}’s note · {date}', 'SU01 link to a check-in.', who='String', date='String')
s('aiChipCheckInMine', 'Ghi nhận của bạn · {date}', 'Your note · {date}', 'SU01 link to my own check-in.', date='String')
s('aiChipFeedback', 'Phản hồi của {who} · {date}', '{who}’s feedback · {date}', 'SU01 link to feedback.', who='String', date='String')
s('aiChipFeedbackMine', 'Phản hồi của bạn · {date}', 'Your feedback · {date}', 'SU01 link to my own feedback.', date='String')
s('aiChipMilestone', 'Điều mới · {date}', 'Something new · {date}', 'SU01 link to a milestone.', date='String')
s('aiChipSleep', 'Nhật ký giấc ngủ', 'Sleep log', 'SU01 link to the sleep comparison.')
s('aiRecordWho', '{who} · {date}', '{who} · {date}', 'Record sheet: author and date.', who='String', date='String')
s('aiRecordCheckIn', 'Ghi nhận', 'Note', 'Record sheet title for a check-in.')
s('aiRecordFeedback', 'Phản hồi', 'Feedback', 'Record sheet title for feedback.')
s('aiRecordMilestone', 'Điều mới', 'Something new', 'Record sheet title for a milestone.')
s('aiRecordOpenActivity', 'Xem hoạt động', 'Open the activity', 'Record sheet action for feedback.' + DRAFT)
s('aiRecordGone', 'Ghi nhận này không còn trên máy hoặc đã được xoá.', 'This note is no longer on this phone or was deleted.', 'Record sheet when the record is not found.' + DRAFT)

# States (ST01 594:6967 / 594:7096, NL10b 574:1317).
s('aiStateTemplateTitle', 'Đang hiển thị bản theo mẫu', 'Showing the template version', 'ST01 card 3 headline; template states.')
s('aiStateConsentEyebrow', 'AI CHƯA BẬT', 'AI NOT ON', 'Consent missing: eyebrow.' + DRAFT)
s('aiStateConsentBody', 'Bản này dùng mẫu cố định, vẫn đủ 3 phần. Nếu bạn đồng ý, AI chỉ diễn đạt lại những ghi nhận đã lưu.', 'This uses a fixed template with the same three parts. If you agree, AI only rewords the saved notes.', 'Consent missing: body.' + DRAFT)
s('aiStateConsentAction', 'Xem và đồng ý dùng AI', 'Review and allow AI', 'Consent missing: link to the consent screen.' + DRAFT)
s('aiStateOffEyebrow', 'AI ĐANG TẮT', 'AI IS OFF', 'ST01 card 2 eyebrow.')
s('aiStateWithdrawnBody', 'Bạn đã tắt AI. Bàn giao dùng mẫu cố định, vẫn đủ 3 phần: điều đã thấy, cách từng có ích, việc có thể chọn tiếp.', 'You turned AI off. The handover uses a fixed template with the same three parts.', 'ST01 card 2 body (consent withdrawn).')
s('aiStateWithdrawnAction', 'Bật AI trong Cài đặt', 'Turn on AI in Settings', 'ST01 card 2 link → consent screen.')
s('aiStateDisabledBody', 'Tóm tắt bằng AI đang tạm dừng. Bàn giao dùng mẫu cố định, vẫn đủ 3 phần.', 'AI summaries are paused. The handover uses a fixed template with the same three parts.', 'FEATURE_DISABLED (kill switch).' + DRAFT)
s('aiStateErrorEyebrow', 'AI CHƯA PHẢN HỒI', 'AI DIDN’T RESPOND', 'ST01 card 3 eyebrow.')
s('aiStateErrorBody', 'Không trừ lượt AI khi lỗi. Ghi nhận và hướng dẫn sức khoẻ không bị ảnh hưởng.', 'No AI quota is used on errors. Logging and health guidance are unaffected.', 'ST01 card 3 body.')
s('aiStateQuotaEyebrow', 'ĐÃ DÙNG HẾT LƯỢT AI', 'AI LIMIT REACHED', 'QUOTA_EXCEEDED eyebrow.' + DRAFT)
s('aiStateQuotaDay', 'Đã dùng {used}/{limit} lượt AI hôm nay cho bé. Lượt mới từ {when}. Bạn vẫn xem được bản theo mẫu.', 'Used {used} of {limit} AI summaries today for this baby. More from {when}. You can still use the template version.', 'QUOTA_EXCEEDED, daily window.' + DRAFT, used='int', limit='int', when='String')
s('aiStateQuotaMonth', 'Nhà mình đã dùng {used}/{limit} lượt AI kỳ này (chung cho tóm tắt và trợ lý). Lượt mới từ {when}. Bạn vẫn xem được bản theo mẫu.', 'Your household used {used} of {limit} AI credits this period (shared by summaries and the assistant). More from {when}. You can still use the template version.', 'QUOTA_EXCEEDED, monthly window.' + DRAFT, used='int', limit='int', when='String')
s('aiStateQuotaPlain', 'Nhà mình đã dùng hết lượt AI trong kỳ này. Bạn vẫn xem được bản theo mẫu.', 'Your household has used this period’s AI credits. You can still use the template version.', 'QUOTA_EXCEEDED without numbers.' + DRAFT)
s('aiStateTemplateEyebrow', 'BẢN THEO MẪU', 'TEMPLATE VERSION', 'PREMIUM_REQUIRED / other reasons eyebrow.' + DRAFT)
s('aiStatePremiumBody', 'Tóm tắt bằng AI nằm trong Child Life Premium. Bạn vẫn xem được bản theo mẫu.', 'AI summaries are part of Child Life Premium. You can still use the template version.', 'PREMIUM_REQUIRED body (the only state with a plan link).' + DRAFT)
s('aiStateOtherBody', 'AI chưa dùng được cho nhà mình lúc này. Bản theo mẫu vẫn đủ 3 phần.', 'AI isn’t available for your household right now. The template has the same three parts.', 'ROLE_DENIED / REGION_UNAVAILABLE body.' + DRAFT)
s('aiStateStaleTitle', 'Có ghi nhận mới', 'New notes since this', 'Stale (dataVersion changed).' + DRAFT)
s('aiStateStaleBody', 'Bản này được tạo trước những ghi nhận mới nhất.', 'This was made before the latest notes.', 'Stale body.' + DRAFT)
s('aiStateStaleRead', 'Bản này được tạo trước những ghi nhận mới nhất. Ba mẹ có thể tạo lại.', 'This was made before the latest notes. A parent can make it again.', 'Stale body for a caregiver (reads only).' + DRAFT)
s('aiStateStaleAction', 'Tạo lại', 'Make it again', 'Stale: regenerate.' + DRAFT)
s('aiStateOfflineEyebrow', 'NGOẠI TUYẾN', 'OFFLINE', 'ST01 card 4 eyebrow.')
s('aiStateOfflineTitle', 'Đang xem bản đã lưu', 'Showing the saved version', 'Offline with a stored handover.' + DRAFT)
s('aiStateOfflineBody', 'Bản mới và AI cần kết nối. Ghi nhận vẫn lưu trên máy và sẽ đồng bộ khi có mạng.', 'A new version and AI need a connection. Notes still save on this device and sync when online.', 'Offline body (ST01 card 4).')
s('aiStateOfflineEmptyTitle', 'Chưa có bản bàn giao trên máy', 'No handover on this phone yet', 'Offline, nothing stored.' + DRAFT)
s('aiStateFailedTitle', 'Chưa tạo được bản bàn giao', 'Couldn’t make the handover', 'The call failed with nothing stored.' + DRAFT)
s('aiStateFailedBody', 'Ghi nhận của nhà mình vẫn giữ nguyên. Không trừ lượt AI khi lỗi.', 'Your family’s notes are unchanged. No AI quota is used on errors.', 'The call failed body.' + DRAFT)
s('aiReadEmptyTitle', 'Chưa có bản bàn giao', 'No handover yet', 'Caregiver, nothing stored.' + DRAFT)
s('aiReadEmptyBody', 'Khi ba mẹ tạo bản bàn giao, bản mới nhất sẽ hiện ở đây.', 'When a parent makes a handover, the latest one shows here.', 'Caregiver, nothing stored.' + DRAFT)
s('aiHealthBody', 'Hôm nay có dấu hiệu sức khoẻ được ghi nhận, nên bàn giao không dùng AI. Hãy xem hướng dẫn sức khoẻ trước.', 'A health sign was noted today, so the handover doesn’t use AI. See the health guidance first.', 'Health first: no AI text (P-151).' + DRAFT)

# "Chưa đúng? Báo lại".
s('aiReportTitle', 'Điều gì chưa đúng?', 'What’s not right?', 'Report sheet title.' + DRAFT)
s('aiReportBody', 'Chọn một lý do. Không cần viết thêm về bé.', 'Pick one reason. No need to write anything about your baby.', 'Report sheet body.' + DRAFT)
s('aiProblemWrongFact', 'Không khớp với điều nhà mình ghi', 'Doesn’t match what we noted', 'Report reason wrong_fact.' + DRAFT)
s('aiProblemWrongPerson', 'Nhầm người ghi', 'Wrong person', 'Report reason wrong_person.' + DRAFT)
s('aiProblemUnsafe', 'Lời khuyên không an toàn', 'Unsafe advice', 'Report reason unsafe_advice.' + DRAFT)
s('aiProblemLanguage', 'Diễn đạt khó hiểu', 'Hard to understand', 'Report reason language.' + DRAFT)
s('aiProblemOther', 'Lý do khác', 'Something else', 'Report reason other.' + DRAFT)
s('aiReportSend', 'Gửi báo lại', 'Send', 'Report sheet primary.' + DRAFT)
s('aiReportThanks', 'Cảm ơn bạn. Bản tóm tắt này sẽ được xem lại.', 'Thank you. This summary will be reviewed.', 'Toast after a report.' + DRAFT)
s('aiReportFailed', 'Chưa gửi được. Kiểm tra kết nối và thử lại.', 'Couldn’t send. Check the connection and try again.', 'Toast when a report fails.' + DRAFT)

# AI consent (A1; NL10 "Dùng AI để tóm tắt" / "Thu hồi đồng ý").
s('aiConsentTitle', 'Tóm tắt bằng AI', 'AI summaries', 'Consent screen title; Cá nhân hoá row.' + DRAFT)
s('aiConsentIntro', 'Khi bạn đồng ý, Child Life có thể nhờ một dịch vụ AI bên ngoài diễn đạt lại những ghi nhận đã lưu thành bản bàn giao và lời giải thích. AI không thêm điều mới; mọi số liệu vẫn lấy từ nhật ký.', 'If you agree, Child Life may ask an external AI service to reword saved notes into a handover or an explanation. AI adds nothing new; every number still comes from the log.', 'Consent intro.' + LEGAL)
s('aiConsentSentTitle', 'Được gửi đi', 'What is sent', 'Consent: what is sent.' + LEGAL)
s('aiConsentSent1', 'Những ghi nhận dạng chữ đã lưu: điều đã thấy, cách đã thử, phản hồi, điều mới', 'Saved text notes: what was noticed, what was tried, feedback, new things', 'Consent: sent item.' + LEGAL)
s('aiConsentSent2', 'Tên gọi ở nhà của bé và ngày của từng ghi nhận', 'Your baby’s nickname and the date of each note', 'Consent: sent item (D-003 nickname, never the real name).' + LEGAL)
s('aiConsentNeverTitle', 'Không bao giờ gửi', 'Never sent', 'Consent: never sent.' + LEGAL)
s('aiConsentNever1', 'Ảnh và video', 'Photos and videos', 'Consent: never sent (D-003).' + LEGAL)
s('aiConsentNever2', 'Họ tên đầy đủ và ngày sinh của bé', 'Your baby’s full name and date of birth', 'Consent: never sent (plan §5.5).' + LEGAL)
s('aiConsentNever3', 'Ghi nhận về dấu hiệu sức khoẻ', 'Notes about health signs', 'Consent: never sent (P-151).' + LEGAL)
s('aiConsentWhereTitle', 'Ai xử lý, lưu ở đâu', 'Who handles it, where it’s kept', 'Consent: provider and retention.' + LEGAL)
s('aiConsentWhere1', 'Một dịch vụ AI bên ngoài diễn đạt lại; máy chủ Child Life gửi yêu cầu, điện thoại không gửi trực tiếp.', 'An external AI service does the wording; Child Life’s server sends the request, never your phone.', 'Consent: external provider, server-side only (D-003).' + LEGAL)
s('aiConsentWhere2', 'Nhà cung cấp AI không được lưu giữ dữ liệu này.', 'The AI provider must not keep this data.', 'Consent: provider retention (D-003 "provider must not retain data").' + LEGAL)
s('aiConsentWhere3', 'Bản tóm tắt được lưu trong nhà mình. Thu hồi đồng ý sẽ xoá phần chữ do AI viết; bản theo mẫu vẫn dùng được.', 'Summaries are kept in your family. Withdrawing consent deletes the AI-written text; the template keeps working.', 'Consent: what withdrawal does.' + LEGAL)
s('aiConsentShareNotes', 'Cho phép ghi chú của tôi được dùng khi người khác trong nhà tạo tóm tắt', 'Let my notes be used when someone else in the family makes a summary', 'Consent toggle shareMyNotes.' + LEGAL)
s('aiConsentShareNotesSub', 'Nếu tắt, ghi chú bạn tự viết không được gửi khi người khác tạo tóm tắt.', 'If off, notes you write aren’t sent when someone else makes a summary.', 'Consent toggle subtitle.' + LEGAL)
s('aiConsentPersonal', 'Đồng ý này là của riêng bạn; gói của hộ không thay cho nó. Bạn đổi ý lúc nào cũng được.', 'This consent is yours alone; the household plan doesn’t replace it. You can change your mind any time.', 'Consent: per person.' + LEGAL)
s('aiConsentVersion', 'Phiên bản đồng ý: {version}', 'Consent version: {version}', 'Consent: version line.', version='String')
s('aiConsentAgree', 'Đồng ý dùng AI', 'Allow AI', 'Consent primary.' + DRAFT)
s('aiConsentGranted', 'Bạn đã đồng ý ngày {date}', 'You agreed on {date}', 'Consent given line.' + DRAFT, date='String')
s('aiConsentOutdated', 'Nội dung đồng ý đã cập nhật. Hãy xem lại để tiếp tục dùng AI.', 'The consent text changed. Review it to keep using AI.', 'Consent for an older version.' + DRAFT)
s('aiConsentWithdraw', 'Thu hồi đồng ý', 'Withdraw consent', 'Consent: withdraw (NL10 "Thu hồi đồng ý").')
s('aiWithdrawTitle', 'Thu hồi đồng ý?', 'Withdraw consent?', 'Withdraw confirm title.' + DRAFT)
s('aiWithdrawBody', 'AI sẽ không được dùng cho tóm tắt bạn tạo nữa. Phần chữ do AI viết sẽ bị xoá; bản theo mẫu vẫn dùng được.', 'AI won’t be used for summaries you make. AI-written text will be deleted; the template keeps working.', 'Withdraw confirm body.' + LEGAL)
s('aiWithdrawConfirm', 'Thu hồi', 'Withdraw', 'Withdraw confirm button.' + DRAFT)
s('aiConsentSaved', 'Đã lưu lựa chọn của bạn', 'Your choice is saved', 'Toast after consent.' + DRAFT)
s('aiWithdrawn', 'Đã thu hồi đồng ý', 'Consent withdrawn', 'Toast after withdrawal.' + DRAFT)
s('aiConsentFailed', 'Chưa lưu được. Kiểm tra kết nối và thử lại.', 'Couldn’t save. Check the connection and try again.', 'Toast when consent fails.' + DRAFT)
s('aiConsentOn', 'Đang bật', 'On', 'Cá nhân hoá row value.' + DRAFT)
s('aiConsentOff', 'Đang tắt', 'Off', 'Cá nhân hoá row value.' + DRAFT)

# "Giải thích thêm" (PS01 / AC01, kind explain) and the MS01 moment nudge.
s('aiExplainMore', 'Giải thích thêm', 'Explain more', 'PS01 / AC01 link under "Vì sao gợi ý này".' + DRAFT)
s('aiExplainLoading', 'Đang chuẩn bị lời giải thích…', 'Preparing an explanation…', 'Explain loading.' + DRAFT)
s('aiExplainFailed', 'Chưa giải thích thêm được lúc này. Lý do ở trên vẫn đầy đủ.', 'Couldn’t explain more right now. The reason above still stands.', 'Explain failed.' + DRAFT)
s('aiExplainConsent', 'Cần bạn đồng ý dùng AI để giải thích thêm.', 'AI needs your consent to explain more.', 'Explain without consent.' + DRAFT)
s('aiExplainQuota', 'Đã dùng hết lượt AI trong kỳ này. Lý do ở trên vẫn đầy đủ.', 'This period’s AI credits are used up. The reason above still stands.', 'Explain over quota.' + DRAFT)
s('aiExplainUnavailable', 'Giải thích thêm chưa dùng được cho nhà mình lúc này.', 'Explaining more isn’t available for your household right now.', 'Explain for other gate reasons.' + DRAFT)

# NL07b observation episodes (573:1199) and NL07's episode card (573:1109).
s('rhEpSuggestTitle', 'Nhóm thành một đợt quan sát?', 'Group into one observation period?', 'NL07b title.')
s('rhEpSuggestBody', '{count} ngày gần đây có ghi nhận thay đổi: {people} thấy {what}.', '{count} recent days had changes noted by {people}: {what}.', 'NL07b body ("2 ngày gần đây có ghi nhận thay đổi: Mẹ (06/10) và Ba (07/10) thấy …").', count='int', people='String', what='String')
s('rhEpPersonDay', '{who} ({date})', '{who} ({date})', 'NL07b: who and when.', who='String', date='String')
s('rhEpNotWonder', 'Đây chỉ là cách nhà mình theo dõi, không phải xác nhận một giai đoạn Wonder Weeks.', 'This is just how your family keeps track, not confirmation of a Wonder Weeks stage.', 'NL07b disclaimer.')
s('rhEpCreate', 'Tạo đợt quan sát', 'Create observation period', 'NL07b primary.')
s('rhEpNoNeed', 'Không cần', 'No need', 'NL07b secondary.')
s('rhEpOpenTitle', 'Đợt quan sát {start} – nay', 'Observation period {start} – now', 'NL07 episode card title.', start='String')
s('rhEpUpdating', 'Đang cập nhật', 'Updating', 'NL07 episode status pill.')
s('rhEpOpenBody', '{who} xác nhận nhóm {count} ghi nhận thành một đợt. Đợt kết thúc khi cả nhà xác nhận “con đã ổn hơn”.', '{who} grouped {count, plural, =1{1 note} other{{count} notes}} into one period. It ends only when your family taps “Better now”.', 'NL07 episode card body.', who='String', count='int')
s('rhEpBetter', 'Con đã ổn hơn', 'Better now', 'NL07: closes the episode (never automatic).')
s('rhEpCloseTitle', 'Kết thúc đợt quan sát?', 'End this observation period?', 'Close confirm title.' + DRAFT)
s('rhEpCloseBody', 'Đợt sẽ được lưu từ {start} đến hôm nay. Child Life không tự kết thúc đợt khi không có ghi nhận.', 'It will be kept from {start} to today. Child Life never ends a period on its own.', 'Close confirm body.' + DRAFT, start='String')
s('rhEpNotYet', 'Chưa', 'Not yet', 'Close confirm cancel.' + DRAFT)
s('rhEpCreated', 'Đã tạo đợt quan sát', 'Observation period created', 'Toast after NL07b.' + DRAFT)
s('rhEpClosed', 'Đã kết thúc đợt quan sát', 'Observation period ended', 'Toast after "Con đã ổn hơn".' + DRAFT)

# NL02c evening check-in prompt (local notification; no baby name, R-120).
s('rhEveningBody', 'Ghi lại một điều trong vài giây, nếu có. Không có gì khác cũng không sao.', 'Note one thing in a few seconds, if there is one. Nothing different is fine too.', 'Evening check-in notification body (title is rhCheckInEntry).' + DRAFT)

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
