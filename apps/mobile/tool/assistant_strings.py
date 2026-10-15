# Child Life Assistant v3, slice A4 (app chat: CH01–CH08, CH19–CH28; docs/assistant/architecture.md,
# P-155–P-161). Vietnamese = the Figma chat frames (page 568:18, extract
# docs/discovery/figma-extract/31-chat-assistant.md) where drawn; English = the EN frames, or an
# engineering draft for owner review (D-012). Where the design contradicts the business rules the
# rules win and the copy says so in its description (viewer composer, kept-not-auto-sent offline
# input, G02 / G05 wording, health link at 0 credits, no internal status copy such as
# "(chưa chốt)" or "chờ chính sách được duyệt"). Prefix `as`. Idempotent.
# Usage: python3 tool/assistant_strings.py && flutter gen-l10n
import json, collections, pathlib

S = collections.OrderedDict()
def s(key, vi, en, desc, **ph):
    S[key] = (vi, en, desc, ph)

DRAFT = ' EN is an engineering draft for owner review.'
VI_DRAFT = ' VI and EN are engineering drafts (no frame draws this state) for owner review.'
RULE = ' Deviates from the frame on purpose (business rule wins; see the A4 report).'

# CH01 Home entry (612:7579 / 612:7835) and the floating Chat/Nút trợ lý (628:9074).
s('asEntryTitle', 'Trợ lý Child Life', 'Child Life assistant', 'CH01 entry card title.')
s('asEntryLeft', 'Còn {remaining}/{limit} lượt', '{remaining}/{limit} left', 'CH01 entry card usage (server snapshot, never static).', remaining='int', limit='int')
s('asEntryOut', 'Hết lượt · làm mới {date}', 'All used · resets {date}', 'CH01 entry card when the household pool is used up.' + VI_DRAFT, date='String')
s('asComposerHint', 'Hỏi, ghi nhanh hoặc gửi ảnh…', 'Ask, log or send a photo…', 'Chat/Ô nhập placeholder (Trống).')
s('asComposerHintText', 'Hỏi hoặc ghi nhanh…', 'Ask or log…', 'Composer placeholder while photo reading is off (assistant_images).' + VI_DRAFT)
s('asComposerViewer', 'Hỏi về nhật ký của bé…', 'Ask about the logs…', 'Chat/Ô nhập "Chỉ xem" placeholder: a viewer may ask, never log.' + RULE)
s('asComposerOutFree', 'Đã hết lượt AI tháng này', 'AI help used up this month', 'CH21 composer (Hết lượt, Free).')
s('asComposerOutPremium', 'Hết lượt AI · vẫn ghi trực tiếp được', 'Out of AI help · direct logging still works', 'CH24 composer (Hết lượt, Premium).')
s('asComposerAnswer', 'Trả lời câu hỏi…', 'Type your answer…', 'Composer while answering a clarification ("Tự nhập").' + VI_DRAFT)
s('asSend', 'Gửi', 'Send', 'Composer send button label (a11y) and the kept-input send action.')
s('asAddPhoto', 'Ảnh', 'Photo', 'Composer camera button label (a11y).')
s('asChipLogFeed', 'Ghi cữ bú', 'Log a feed', 'CH01 chip and CH21 direct-log button.')
s('asPrefillFeed', 'Con bú bình lúc ', 'Bottle feed at ', 'CH01 "Ghi cữ bú" only prefills the composer; never sends.' + VI_DRAFT)
s('asChipFeedsToday', 'Hôm nay con bú thế nào?', 'How did feeds go today?', 'CH01 chip / CH02 example (prefills this question).')
s('asChipReceipt', 'Chụp hoá đơn', 'Scan a receipt', 'CH01 chip (photo reading on only).')
s('asFabLabel', 'Mở trợ lý', 'Open the assistant', 'Floating assistant button a11y label.' + DRAFT)

# CH01b module entry (612:7657 / 612:7913).
s('asModuleExpenseTitle', 'Chụp hoá đơn hoặc nhắn để ghi', 'Snap a receipt or type to log', 'CH01b entry in Chi tiêu.')
s('asModuleExpenseTextOnly', 'Nhắn để ghi khoản chi', 'Type to log an expense', 'CH01b entry while photo reading is off.' + VI_DRAFT)
s('asModuleSub', 'Trợ lý đọc và tạo bản nháp · bạn kiểm tra trước khi lưu', 'The assistant drafts it · you check before saving', 'CH01b entry subtitle.')

# Chat/Đầu trang and Chat/Mức dùng (611:7726).
s('asScopeHousehold', 'Gia đình', 'Family', 'Chat header scope chip for the household.')
s('asScopeTitle', 'Trò chuyện với', 'Chat about', 'Scope picker sheet title.' + VI_DRAFT)
s('asHistory', 'Lịch sử', 'History', 'Chat header history button (a11y).')
s('asNewChat', 'Hội thoại mới', 'New chat', 'Chat header new button (a11y) and CH03 "Hội thoại mới".')
s('asDetails', 'Chi tiết', 'Details', 'Usage row link to CH19.')
s('asUsageLeft', 'Còn {remaining}/{limit} lượt hỗ trợ AI', '{remaining}/{limit} AI help left', 'Chat/Mức dùng, Còn.', remaining='int', limit='int')
s('asUsageNear', 'Còn {remaining}/{limit} lượt · làm mới {date}', '{remaining}/{limit} left · resets {date}', 'Chat/Mức dùng, Gần hết (CH20).', remaining='int', limit='int', date='String')
s('asUsageOut', 'Đã dùng hết {limit}/{limit} lượt · làm mới {date}', 'All {limit} used · resets {date}', 'Chat/Mức dùng, Hết (CH21 / CH24: same numbers for Free and Premium).', limit='int', date='String')
s('asUsageA11y', 'Lượt hỗ trợ AI của hộ: còn {remaining} trên {limit}, làm mới {date}', 'Household AI help: {remaining} of {limit} left, resets {date}', 'Usage pill screen-reader label.' + VI_DRAFT, remaining='int', limit='int', date='String')
s('asBadgeFree', 'Free', 'Free', 'Plan badge (CH19).')
s('asBadgePremium', 'Premium', 'Premium', 'Plan badge (CH19).')

# CH02 empty chat (612:7711 / 612:7967).
s('asEmptyTitle', 'Hỏi, ghi nhanh hoặc gửi ảnh cho {name}', 'Ask, log or send a photo for {name}', 'CH02 heading (child scope).', name='String')
s('asEmptyTitleText', 'Hỏi hoặc ghi nhanh cho {name}', 'Ask or log for {name}', 'CH02 heading while photo reading is off.' + VI_DRAFT, name='String')
s('asEmptyTitleHousehold', 'Hỏi hoặc ghi nhanh cho cả nhà', 'Ask or log for the family', 'CH02 heading (household scope).' + VI_DRAFT)
s('asEmptyBody', 'Trợ lý hiểu và tạo bản nháp. Bạn kiểm tra trước khi lưu vào đúng chỗ.', 'The assistant understands and drafts. You check before it’s saved in the right place.', 'CH02 body.')
s('asExampleFeed', '“8 giờ con bú bình 120 ml”', '“Bottle 120 ml at 8am”', 'CH02 example card (prefills [asExampleFeedText]).')
s('asExampleFeedText', '8 giờ con bú bình 120 ml', 'Bottle 120 ml at 8am', 'Text the CH02 example prefills (never sent by itself).')
s('asExampleFeedsToday', '“Hôm nay con bú thế nào?”', '“How did feeds go today?”', 'CH02 example card.')
s('asExampleExpense', '“Mua bỉm 310.000 đồng hôm qua”', '“Diapers 310,000 dong yesterday”', 'CH02 example card, household scope (prefills without quotes).' + VI_DRAFT)
s('asExampleExpenseText', 'Mua bỉm 310.000 đồng hôm qua', 'Diapers 310,000 dong yesterday', 'Text the household example prefills.' + VI_DRAFT)
s('asExampleReceipt', 'Chụp hoá đơn → ghi chi tiêu', 'Snap a receipt → log an expense', 'CH02 example card (photo reading on only).')
s('asExampleNote', 'Chụp bảng note → nhắc việc', 'Snap a note → reminders', 'CH02 example card (photo reading on only).')
s('asPrivacyNote', 'Tin nhắn và ảnh bạn gửi được AI xử lý để tạo bản nháp. Không tự lưu. Ảnh gốc giữ hay xoá theo lựa chọn của bạn.', 'Messages and photos you send are processed by AI to make drafts. Nothing saves automatically. You choose whether original photos are kept.', 'CH02 notice. G05: no deletion claim before deletion is confirmed.' + RULE)
s('asPrivacyNoteText', 'Tin nhắn bạn gửi được AI xử lý để tạo bản nháp. Không tự lưu.', 'Messages you send are processed by AI to make drafts. Nothing saves automatically.', 'CH02 notice while photo reading is off.' + VI_DRAFT)

# Thread.
s('asThinking', 'Trợ lý đang đọc…', 'The assistant is reading…', 'Task queued / processing.' + VI_DRAFT)
s('asCancelTask', 'Huỷ', 'Cancel', 'Cancel a task still being prepared (no charge without a useful answer).' + VI_DRAFT)
s('asCanceled', 'Đã huỷ. Không trừ lượt.', 'Canceled. No AI help used.', 'A canceled task.' + VI_DRAFT)
s('asUnsent', 'Chưa gửi', 'Not sent', 'Kept input bubble marker (CH21 / CH25).' + RULE)
s('asSending', 'Đang gửi…', 'Sending…', 'Input bubble while sending.' + VI_DRAFT)
s('asDraftsFound', 'Mình thấy {count} việc. Kiểm tra rồi chọn mục muốn lưu nhé.', '{count, plural, =1{I found 1 thing} other{I found {count} things}}. Check them and choose what to save.', 'CH04 assistant line when the server sent drafts without text.', count='int')
s('asUnsupportedPart', 'Nội dung này cần bản app mới hơn để hiển thị. Không có gì được lưu.', 'This needs a newer app version to show. Nothing was saved.', 'UnsupportedCard for an unknown part type (brief p.11).' + VI_DRAFT)
s('asLoadingChat', 'Đang mở cuộc trò chuyện…', 'Opening the chat…', 'Restoring the last conversation.' + VI_DRAFT)

# Chat/Thẻ nháp (611:7695): labels come from the state enum, never from text.
s('asStateDraft', 'Nháp', 'Draft', 'Draft card state Nháp.')
s('asStateReview', 'Cần kiểm tra', 'Check', 'Draft card state Cần kiểm tra.')
s('asStateSaving', 'Đang lưu', 'Saving', 'Draft card state Đang lưu.' + DRAFT)
s('asStateSaved', 'Đã lưu', 'Saved', 'Draft card state Đã lưu.')
s('asStateFailed', 'Chưa lưu', 'Not saved', 'Draft card state Lưu lỗi (CH07 label).')
s('asStateDiscarded', 'Đã bỏ', 'Removed', 'Draft card state Đã bỏ.' + DRAFT)
s('asStateExpired', 'Hết hạn', 'Expired', 'Draft card past its TTL (DRAFT_EXPIRED).' + VI_DRAFT)
s('asKindBottle', 'Cữ bú bình', 'Bottle feed', 'Draft kind bottle.')
s('asKindBreast', 'Cữ bú mẹ', 'Breastfeed', 'Draft kind breast.' + DRAFT)
s('asKindSleep', 'Giấc ngủ', 'Sleep', 'Draft kind sleep.')
s('asKindExpense', 'Khoản chi', 'Expense', 'Draft kind expense.' + DRAFT)
s('asKindReminder', 'Nhắc việc', 'Reminder', 'Draft kind reminder.' + DRAFT)
s('asKindObservation', 'Ghi nhận', 'Note', 'Draft kind observation (CH16 "Ghi nhận").')
s('asKindMeal', 'Bữa ăn', 'Meal', 'Draft kind meal.' + DRAFT)
s('asKindUnknown', 'Mục chưa hỗ trợ', 'Unsupported item', 'Draft of a kind this app version does not know (never saveable here).' + VI_DRAFT)
s('asModuleCare', '{name} · Nhật ký chăm sóc', '{name} · Care log', 'Draft card scope row (care).', name='String')
s('asModuleSpending', 'Gia đình · Chi tiêu', 'Family · Expenses', 'Draft card scope row (expense).' + DRAFT)
s('asModuleReminders', 'Gia đình · Nhắc việc', 'Family · Reminders', 'Draft card scope row (reminder).' + DRAFT)
s('asModuleRhythm', '{name} · Nhịp lớn lên', '{name} · Growing rhythm', 'Draft card scope row (observation).', name='String')
s('asModuleMeal', '{name} · Ăn dặm', '{name} · Solids', 'Draft card scope row (meal).' + DRAFT, name='String')
s('asDayToday', 'Hôm nay {date}', 'Today {date}', 'Draft line day ("Hôm nay 15/10").', date='String')
s('asDayYesterday', 'Hôm qua {date}', 'Yesterday {date}', 'Draft line day.' + DRAFT, date='String')
s('asAmountMl', '{ml} ml', '{ml} ml', 'Bottle amount.', ml='String')
s('asNoAmount', 'chưa có lượng', 'no amount yet', 'Draft line: amount missing.' + VI_DRAFT)
s('asNoTime', 'chưa có giờ', 'no time yet', 'Draft line: time missing.' + VI_DRAFT)
s('asNoDate', 'chưa có ngày', 'no date yet', 'Draft line: date missing.' + VI_DRAFT)
s('asEdit', 'Sửa', 'Edit', 'Draft card action.')
s('asRemove', 'Bỏ mục này', 'Remove', 'Draft card action.')
s('asOpenLog', 'Mở nhật ký', 'Open log', 'Saved card action (care).')
s('asUndo', 'Hoàn tác', 'Undo', 'Saved card action: opens the record in its module, never deletes by itself (G02).')
s('asOpenSpending', 'Mở Chi tiêu', 'Open Expenses', 'Saved card action (expense).')
s('asOpenReminders', 'Mở nhắc việc', 'Open reminders', 'Saved card action (reminder).' + DRAFT)
s('asOpenRhythm', 'Xem nhịp của con', 'See the rhythm', 'Saved card action (observation).')
s('asSeeLogged', 'Xem bản đã ghi', 'See the logged one', 'Conflict card action (CH07 "Xem bản Ba ghi"; the author is not known here).' + DRAFT)
s('asSaveAnyway', 'Vẫn lưu riêng', 'Save anyway', 'Conflict card action (explicit confirm first).')
s('asViewerDraftNote', 'Chỉ xem · không lưu qua chat', 'View only · can’t save from chat', 'Draft card for a member who may not save that kind.' + VI_DRAFT)

# Draft checks (same as the forms) and per-item errors.
s('asProblemMissingAmount', 'Thêm lượng (ml) trước khi lưu.', 'Add the amount (ml) before saving.', 'MISSING_AMOUNT.' + VI_DRAFT)
s('asProblemInvalidAmount', 'Lượng chưa hợp lệ.', 'That amount isn’t valid.', 'INVALID_AMOUNT.' + VI_DRAFT)
s('asProblemMissingTime', 'Thêm giờ trước khi lưu.', 'Add the time before saving.', 'MISSING_TIME.' + VI_DRAFT)
s('asProblemFutureTime', 'Giờ này ở tương lai — chỉ ghi việc đã xảy ra.', 'That time is in the future — only log what happened.', 'FUTURE_TIME (CH06 "giờ trong tương lai").' + VI_DRAFT)
s('asProblemInvalidTime', 'Giờ kết thúc phải sau giờ bắt đầu.', 'The end must be after the start.', 'INVALID_TIME.' + VI_DRAFT)
s('asProblemMissingDate', 'Chọn ngày trước khi lưu.', 'Pick the date before saving.', 'MISSING_DATE.' + VI_DRAFT)
s('asProblemCurrency', 'Chi tiêu chưa hỗ trợ đơn vị tiền này.', 'Expenses don’t support this currency yet.', 'CURRENCY_UNSUPPORTED (P-157).' + VI_DRAFT)
s('asProblemMissingTitle', 'Thêm tên việc trước khi lưu.', 'Add a title before saving.', 'MISSING_TITLE.' + VI_DRAFT)
s('asNeedsReview', 'Kiểm tra lại mục này rồi lưu.', 'Check this item before saving.', 'needs_review / uncertain fields line.' + VI_DRAFT)
s('asErrConflict', 'Trùng với một bản đã ghi. Chưa lưu.', 'Overlaps something already logged. Not saved.', 'DOMAIN_CONFLICT (CH07 "Trùng với giấc … Chưa lưu.").' + DRAFT)
s('asErrDuplicate', 'Có vẻ mục này đã được ghi. Chưa lưu.', 'This looks already logged. Not saved.', 'DUPLICATE_SUSPECTED.' + VI_DRAFT)
s('asErrWriteDenied', 'Vai trò của bạn chưa được lưu mục này.', 'Your role can’t save this item.', 'WRITE_DENIED on an item.' + VI_DRAFT)
s('asErrExpired', 'Bản nháp đã hết hạn. Nhắn lại để tạo bản mới.', 'This draft expired. Send it again for a new one.', 'DRAFT_EXPIRED.' + VI_DRAFT)
s('asErrStale', 'Bản nháp vừa thay đổi. Xem lại rồi lưu.', 'This draft just changed. Check it, then save.', 'DRAFT_STALE.' + VI_DRAFT)
s('asErrSaveFailed', 'Chưa lưu được. Thử lại không trừ lượt.', 'Couldn’t save. Retrying doesn’t use AI help.', 'A system failure on an item (retryable).' + VI_DRAFT)
s('asErrScope', 'Bé đang chọn đã đổi. Mở lại đúng bé để lưu.', 'The selected baby changed. Open the right baby to save.', 'SCOPE_CHANGED.' + VI_DRAFT)
s('asErrModule', 'Mục này chưa có nơi lưu trong app.', 'The app has nowhere to save this yet.', 'MODULE_UNAVAILABLE on an item.' + VI_DRAFT)

# Chat/Duyệt hàng loạt.
s('asSaveSelected', 'Lưu {count} mục đã chọn', 'Save {count} selected', 'CH04 batch primary.', count='int')
s('asChooseToSave', 'Chọn mục muốn lưu', 'Choose what to save', 'Batch primary with nothing selected (disabled).' + VI_DRAFT)
s('asDiscardAll', 'Bỏ tất cả', 'Discard all', 'CH04 batch secondary.')
s('asPartial', '{saved}/{total} mục đã lưu · {failed} mục chưa lưu', '{saved} of {total} saved · {failed} not saved', 'CH07 summary (counts from the server results, never a fake 2/2).', saved='int', total='int', failed='int')
s('asRetryFailed', 'Thử lại mục lỗi', 'Retry failed item', 'CH07 retry (system failures only).')
s('asRetryFree', 'Thử lại không trừ lượt.', 'Retrying doesn’t use AI help.', 'Under the CH07 retry.' + VI_DRAFT)
s('asSaveOffline', 'Đang ngoại tuyến · chưa lưu gì. Có mạng rồi lưu lại.', 'Offline · nothing saved. Save again when you’re online.', 'Confirm while offline: drafts stay drafts.' + VI_DRAFT)
s('asSaveError', 'Chưa lưu được. Bản nháp vẫn giữ nguyên.', 'Couldn’t save. Your drafts are kept.', 'Confirm call failed.' + VI_DRAFT)
s('asSaveAnywayTitle', 'Vẫn lưu riêng?', 'Save anyway?', 'Confirm sheet for "Vẫn lưu riêng".' + VI_DRAFT)
s('asSaveAnywayBody', 'Mục này trùng với một bản đã ghi. Lưu riêng sẽ có hai bản; bạn sửa hoặc xoá trong nhật ký được.', 'This overlaps something already logged. Saving separately keeps both; you can edit or delete in the log.', 'Confirm sheet body.' + VI_DRAFT)
s('asSaveSeparately', 'Lưu riêng', 'Save separately', 'Confirm sheet primary.' + VI_DRAFT)
s('asCancel', 'Huỷ', 'Cancel', 'Generic cancel in assistant sheets.')

# CH05 clarification (613:7904 / 613:8330).
s('asClarifyFree', 'Câu hỏi làm rõ thuộc cùng tác vụ, không trừ thêm lượt.', 'Clarifying questions are part of the same task and don’t use extra help.', 'CH05 footnote.')
s('asClarifyOwn', 'Tự nhập', 'Enter manually', 'CH05 chip for a typed answer.')
s('asClarifyExpired', 'Câu hỏi đã hết hạn. Nhắn lại để hỏi tiếp.', 'This question expired. Send it again to continue.', 'Clarification past its TTL.' + VI_DRAFT)

# CH06 edit sheet (Chat/Biểu mẫu nháp).
s('asEditBottle', 'Sửa cữ bú bình', 'Edit bottle feed', 'CH06 sheet title (bottle).')
s('asEditBreast', 'Sửa cữ bú mẹ', 'Edit breastfeed', 'CH06 sheet title (breast).' + DRAFT)
s('asEditSleep', 'Sửa giấc ngủ', 'Edit sleep', 'CH06 sheet title (sleep).' + DRAFT)
s('asFieldBaby', 'Bé', 'Baby', 'CH06 field (locked to the chat scope).')
s('asFieldWhen', 'Thời gian', 'Time', 'CH06 date + time field.' + VI_DRAFT)
s('asFieldAmount', 'Lượng (ml)', 'Amount (ml)', 'CH06 amount field.')
s('asFieldStart', 'Bắt đầu', 'Start', 'CH06 sleep start.' + DRAFT)
s('asFieldEnd', 'Kết thúc', 'End', 'CH06 sleep end.' + DRAFT)
s('asFieldMinutes', 'Số phút', 'Minutes', 'CH06 breast duration.' + DRAFT)
s('asFieldSide', 'Bên', 'Side', 'CH06 breast side.' + DRAFT)
s('asBabyLocked', 'Bé giữ theo cuộc trò chuyện; không chuyển bản nháp sang bé khác.', 'The baby stays as in this chat; drafts never move to another baby.', 'CH06 under the locked baby field.' + RULE)
s('asUpdateDraft', 'Cập nhật bản nháp', 'Update draft', 'CH06 primary (updates the draft only, never saves).')
s('asEditFailed', 'Chưa cập nhật được bản nháp. Thử lại.', 'Couldn’t update the draft. Try again.', 'patchDraft failed.' + VI_DRAFT)

# CH08 read summary (613:8155 / 613:8579).
s('asSummaryMeta', '{day} · đến {time}', '{day} · to {time}', 'CH08 meta ("Hôm nay 15/10 · đến 14:20").', day='String', time='String')
s('asSummaryBottle', 'Bú bình · {count} cữ · {ml} ml', 'Bottle · {count, plural, =1{1 feed} other{{count} feeds}} · {ml} ml', 'CH08 bottle row.', count='int', ml='String')
s('asSummaryBreast', 'Bú mẹ · {count} lần · {minutes} phút', 'Breastfeeding · {count, plural, =1{1 time} other{{count} times}} · {minutes} min', 'CH08 nursing row (minutes, never ml).', count='int', minutes='int')
s('asSummaryBreastNote', 'Tính theo phút, không quy đổi ra ml', 'Shown in minutes, not converted to ml', 'CH08 nursing note.')
s('asSummarySleep', 'Giấc ngủ · {count} giấc · {duration}', 'Sleep · {count, plural, =1{1 sleep} other{{count} sleeps}} · {duration}', 'CH08 sleep row.' + DRAFT, count='int', duration='String')
s('asSummaryNone', 'Chưa có ghi nhận nào trong khoảng này.', 'Nothing logged in this period.', 'CH08 with no records.' + VI_DRAFT)
s('asSummaryPartial', 'Tính trên các cữ đã ghi — có thể chưa đầy đủ.', 'Based on the feeds logged — may be incomplete.', 'CH08 coverage partial / unknown ("các cữ đã ghi").' + DRAFT)
s('asSummaryComplete', 'Tính trên các cữ đã ghi trong ngày.', 'Based on the day’s logged feeds.', 'CH08 coverage complete.' + VI_DRAFT)
s('asOpenSourceLog', 'Mở nhật ký nguồn', 'Open source log', 'CH08 source link.')
s('asNoRecordCreated', 'Câu hỏi không tạo cữ bú mới', 'Questions never create new entries', 'CH08 note under the card.')

# CH19 usage details (616:9607 / 616:9984).
s('asUsageTitle', 'Lượt hỗ trợ AI', 'AI help', 'CH19 title.')
s('asUsageOf', '/ {limit} lượt còn lại', '/ {limit} left', 'CH19 total after the big number.', limit='int')
s('asUsageResetFree', 'Làm mới {date} theo múi giờ của hộ · dùng chung cho cả hộ', 'Resets {date} in household time · shared by the household', 'CH19 reset line (Free, calendar month).', date='String')
s('asUsageResetPremium', 'Làm mới {date} theo kỳ Premium · dùng chung cho cả hộ', 'Resets {date} with the Premium period · shared by the household', 'CH19 reset line (Premium).' + VI_DRAFT, date='String')
s('asCostTitle', 'Mỗi việc dùng khoảng', 'Roughly per task', 'CH19 section.')
s('asCostText', 'Câu hỏi, ghi nhanh bằng chữ', 'Questions, quick text logs', 'CH19 cost row.')
s('asCostPhoto', 'Đọc 1 ảnh (hoá đơn, note)', 'Read 1 photo (receipt, note)', 'CH19 cost row.')
s('asCostFollowUp', 'Hỏi lại, sửa, xác nhận cùng tác vụ', 'Follow-ups, edits, confirm', 'CH19 cost row.')
s('asCostError', 'Lỗi hệ thống, ảnh không đọc được', 'System error, unreadable photo', 'CH19 cost row.' + DRAFT)
s('asCostHealth', 'Hướng dẫn sức khoẻ thiết yếu', 'Essential health guidance', 'CH19 cost row (health is free; missing in the frame).' + VI_DRAFT)
s('asCostCredits', '{count} lượt', '{count}', 'CH19 cost value (from the server policy).', count='int')
s('asCostNoExtra', 'Không thêm', 'No extra', 'CH19 cost value (G04: never wraps mid-word).')
s('asCostNotCharged', 'Không trừ', 'Not charged', 'CH19 cost value.')
s('asCostFree', 'Miễn phí', 'Free', 'CH19 cost value (health).' + DRAFT)
s('asRecentTitle', 'Gần đây', 'Recent', 'CH19 recent tasks section.')
s('asRecentText', 'Câu hỏi hoặc ghi nhanh', 'Question or quick log', 'CH19 recent row (text task).' + VI_DRAFT)
s('asRecentPhoto', 'Đọc ảnh', 'Read photo', 'CH19 recent row (photo task).' + VI_DRAFT)
s('asRecentMeta', '{who} · {date} · {credits} lượt', '{who} · {date} · {credits}', 'CH19 recent meta ("Mẹ · 15/10 · 3 lượt").', who='String', date='String', credits='int')
s('asVideoQuotaTitle', 'Xuất video kỷ niệm', 'Keepsake video exports', 'CH19 separate video quota row.' + VI_DRAFT)
s('asVideoQuotaSub', 'Quota riêng, không dùng lượt hỗ trợ AI · còn {left}/{limit}', 'Separate quota, not AI help · {left}/{limit} left', 'CH19 video quota line.' + VI_DRAFT, left='int', limit='int')
s('asPremiumTeaser', 'Premium có nhiều lượt hơn, cùng cá nhân hoá chủ động và mẫu thẻ/video Premium.', 'Premium has more help, plus proactive personalisation and Premium card/video templates.', 'CH19 Premium card (Free only).')
s('asSeePremium', 'Xem Premium', 'See Premium', 'CH19 / CH20 link to the paywall.')
s('asPremiumHousehold', 'Hộ đang dùng Premium. Không có gói chat riêng.', 'Your household has Premium. There’s no separate chat plan.', 'CH19 for a Premium household (no upsell).' + VI_DRAFT)
s('asUsageFailed', 'Chưa tải được mức dùng.', 'Couldn’t load usage.', 'CH19 load error.' + VI_DRAFT)
s('asRetry', 'Thử lại', 'Try again', 'Retry (CH25, CH03, CH19).')

# CH20 photo blocked before send (616:9663 / 616:10040).
s('asPhotoNotSent', 'Ảnh · chưa gửi', 'Photo · not sent', 'CH20 attachment label (nothing uploaded).')
s('asPhotoQuoteTitle', 'Đọc ảnh này cần {credits} lượt, bạn còn {remaining}.', 'Reading this photo needs {credits}, you have {remaining}.', 'CH20 warning (exact quote, not an estimate).', credits='int', remaining='int')
s('asPhotoQuoteFree', 'Bạn có thể nhập tay, đợi làm mới {date}, hoặc nâng cấp để tiếp tục ngay. Ảnh chưa được gửi đi.', 'You can type it in, wait for {date}, or upgrade to continue now. The photo hasn’t been sent.', 'CH20 body (Free).', date='String')
s('asPhotoQuotePremium', 'Bạn có thể nhập tay hoặc đợi làm mới {date}. Ảnh chưa được gửi đi.', 'You can type it in or wait for {date}. The photo hasn’t been sent.', 'CH20 body (Premium: no other pack).' + VI_DRAFT, date='String')
s('asTypeInstead', 'Nhập tay', 'Type it in', 'CH20 secondary.')
s('asRemovePhoto', 'Bỏ ảnh', 'Remove photo', 'Removes the pending photo (never uploaded).' + VI_DRAFT)
s('asPhotoSoon', 'Đọc ảnh sẽ có ở bản cập nhật tới. Ảnh chưa được gửi đi.', 'Reading photos comes in the next update. The photo hasn’t been sent.', 'Photo allowed by the quote while the A5 upload is not in this build.' + VI_DRAFT)

# CH21 Free exhausted (616:9773 / 616:10125) and CH24 Premium exhausted (616:9936 / 616:10288).
s('asOutTitleFree', 'Bạn đã dùng hết lượt hỗ trợ AI tháng này.', 'You’ve used all AI help this month.', 'CH21 title.')
s('asOutBodyFree', 'Câu hỏi của bạn được giữ lại. Bạn vẫn ghi trực tiếp và xem nhật ký miễn phí.', 'Your question is kept. You can still log directly and view logs for free.', 'CH21 body.')
s('asOpenTodayLog', 'Mở nhật ký hôm nay', 'Open today’s log', 'CH21 direct action.')
s('asUpgradeContinue', 'Nâng cấp & tiếp tục câu hỏi', 'Upgrade & continue', 'CH21 primary (paywall; resumes the kept question once after a verified purchase).')
s('asHealthStillOpen', 'Hướng dẫn sức khoẻ thiết yếu vẫn mở, không cần lượt.', 'Essential health guidance stays open, no AI help needed.', 'CH21 / CH24 note, now with a link.' + RULE)
s('asOpenHealth', 'Mở Hướng dẫn sức khoẻ', 'Open Health guidance', 'Link to HL01 (CH21, CH24, CH27, CH28).')
s('asOutTitlePremium', 'Hộ đã dùng hết lượt hỗ trợ AI kỳ này.', 'Your household has used all AI help this period.', 'CH24 title.')
s('asOutBodyPremium', 'Làm mới {date}. Bạn vẫn ghi trực tiếp, xem nhật ký, dùng mẫu Premium và quota xuất video riêng.', 'Resets {date}. You can still log directly, view logs, use Premium templates and your separate video quota.', 'CH24 body.', date='String')
s('asSeeUsage', 'Xem chi tiết mức dùng', 'See usage details', 'CH24 button.')
s('asReadyStillSave', 'Bản nháp đã sẵn sàng vẫn lưu được, không cần lượt.', 'Drafts that are ready can still be saved, no AI help needed.', 'CH21 / CH24 when ready drafts exist (brief p.17).' + VI_DRAFT)

# CH23 resumed after a verified purchase (616:9875 / 616:10227).
s('asResumedBanner', 'Hộ đã có Premium · tiếp tục câu hỏi đang chờ', 'Household has Premium · continuing your question', 'CH23 banner.')
s('asResumedNote', 'Câu hỏi được tính 1 lần sau khi có câu trả lời, không tính lúc hết lượt.', 'The question counts once when answered, not when you were out.', 'CH23 note.')
s('asContinueQuestion', 'Tiếp tục câu hỏi', 'Continue my question', 'PR02 success button when the purchase came from the chat.' + VI_DRAFT)

# CH25 failure / offline (617:9893 / 617:10159): two separate states.
s('asFailTitle', 'Trợ lý chưa phản hồi được', 'The assistant couldn’t respond', 'CH25 error card.')
s('asFailBody', 'Chưa có gì được lưu. Lượt này không bị trừ; thử lại cũng không trừ hai lần.', 'Nothing was saved. This didn’t use AI help, and retrying won’t charge twice.', 'CH25 error body.')
s('asLogDirectly', 'Ghi trực tiếp', 'Log directly', 'CH25 secondary (opens Ghi nhanh).')
s('asOfflineTitle', 'Đang ngoại tuyến', 'Offline', 'CH25 offline card.')
s('asOfflineBody', 'Tin nhắn được giữ lại, chưa gửi. Khi có mạng, bấm Gửi để gửi. Ghi trực tiếp trong các module vẫn lưu trên máy.', 'Your message is kept, not sent. When you’re back online, tap Send. Direct logging in modules still saves on device.', 'CH25 offline body: kept, never auto-sent (no charge without a tap).' + RULE)
s('asGenericError', 'Có lỗi xảy ra. Chưa có gì được lưu.', 'Something went wrong. Nothing was saved.', 'Any other failure.' + VI_DRAFT)

# CH26 consent (617:9955 / 617:10221), P-160 / D-003.
s('asConsentTitle', 'Trước khi dùng trợ lý', 'Before you use the assistant', 'CH26 title.')
s('asConsent1', 'Tin nhắn và ảnh bạn gửi được AI xử lý để hiểu và tạo bản nháp.', 'Messages and photos you send are processed by AI to understand and draft.', 'CH26 row 1.')
s('asConsent2', 'Chỉ gửi ảnh bạn chọn. Ảnh gốc giữ hay xoá theo lựa chọn của bạn; app chỉ báo đã xoá khi việc xoá được xác nhận.', 'Only photos you choose are sent. You choose whether originals are kept; the app says a photo was deleted only once that’s confirmed.', 'CH26 row 2 (G05: no deletion claim before it is confirmed).' + RULE)
s('asConsent3', 'Chỉ dùng tên gọi của bé; không gửi tên đầy đủ hay ngày sinh chính xác.', 'Only your baby’s nickname is used; never the full name or exact birth date.', 'CH26 row 3 (D-003: nickname, never the real name).' + RULE)
s('asConsent4', 'Không tự lưu. Bạn kiểm tra trước khi ghi vào nhật ký.', 'Nothing saves automatically. You check before anything is logged.', 'CH26 row 4.')
s('asConsentProvider', 'Một dịch vụ AI bên ngoài xử lý qua máy chủ Child Life, điện thoại không gửi trực tiếp; nhà cung cấp không được lưu giữ dữ liệu này.', 'An external AI service handles it through Child Life’s server, never directly from your phone; the provider must not keep this data.', 'CH26 provider and retention (D-003), replacing the internal "chờ chính sách được duyệt".' + RULE)
s('asConsentPrivate', 'Cuộc trò chuyện chỉ bạn xem được. Bạn đổi ý lúc nào cũng được.', 'Only you can see your chats. You can change your mind any time.', 'CH26 privacy (P-158) and withdrawal.' + VI_DRAFT)
s('asConsentAgree', 'Đồng ý và bắt đầu', 'Agree and start', 'CH26 primary.')
s('asConsentDecline', 'Không dùng trợ lý', 'Don’t use the assistant', 'CH26 secondary (the app stays usable).')
s('asConsentDeclined', 'Đã không dùng trợ lý. Ghi trực tiếp vẫn dùng như bình thường.', 'Assistant not used. Direct logging works as usual.', 'Toast after declining.' + VI_DRAFT)
s('asConsentFailed', 'Chưa lưu được lựa chọn. Kiểm tra kết nối và thử lại.', 'Couldn’t save your choice. Check the connection and try again.', 'Consent call failed.' + VI_DRAFT)

# CH27 permissions / module / region (617:10025 / 617:10291).
s('asViewerTitle', 'Bạn đang có quyền xem', 'You have view access', 'CH27 viewer card (second person: the viewer is the one chatting).' + RULE)
s('asViewerBody', 'Người chỉ có quyền xem không ghi được qua chat. Bạn vẫn hỏi và xem tổng hợp được.', 'View-only members can’t log through chat. You can still ask and see summaries.', 'CH27 viewer body.')
s('asWriteDeniedTitle', 'Chưa lưu được qua chat', 'Can’t save from chat', 'WRITE_DENIED for a member who writes other modules.' + VI_DRAFT)
s('asWriteDeniedBody', 'Vai trò của bạn chưa được ghi mục này. Bạn vẫn hỏi và xem tổng hợp được.', 'Your role can’t log this. You can still ask and see summaries.', 'WRITE_DENIED body.' + VI_DRAFT)
s('asReadDeniedBody', 'Vai trò của bạn chưa được xem dữ liệu này.', 'Your role can’t see this data.', 'READ_DENIED body.' + VI_DRAFT)
s('asModuleTitle', 'Chưa có nơi lưu việc này', 'Nowhere to save this yet', 'CH27 module unavailable (no direct "Lưu thành nhắc việc": every write is a draft first).' + RULE)
s('asModuleBody', 'App chưa có module cho loại việc này nên không tạo bản ghi. Bạn có thể nhắn lại thành nhắc việc có ngày giờ để có bản nháp kiểm tra.', 'The app has no module for this, so nothing was created. You can ask for a reminder with a date and time instead and check the draft.', 'CH27 module unavailable body.' + VI_DRAFT)
s('asRegionTitle', 'Khu vực chưa hỗ trợ', 'Region not supported', 'CH27 region card.')
s('asRegionBody', 'Gợi ý chăm sóc qua chat chưa mở ở khu vực của hộ. Ghi nhanh và hỏi dữ liệu vẫn dùng được.', 'Care suggestions via chat aren’t available in your region yet. Quick logging and data questions still work.', 'CH27 region body.')
s('asOffTitle', 'Trợ lý đang tạm nghỉ', 'The assistant is paused', 'FEATURE_DISABLED (kill switch, P-161).' + VI_DRAFT)
s('asOffBody', 'Lịch sử và ghi trực tiếp vẫn dùng được.', 'History and direct logging still work.', 'FEATURE_DISABLED body.' + VI_DRAFT)
s('asNotMemberBody', 'Bạn không còn trong gia đình của bé này.', 'You’re no longer in this baby’s family.', 'NOT_MEMBER.' + VI_DRAFT)

# CH28 health in chat (617:10101 / 617:10367).
s('asHealthTitle', 'Hãy liên hệ hỗ trợ y tế ngay', 'Contact medical help now', 'CH28 title.')
s('asHealthBody', 'Trợ lý không phải dịch vụ cấp cứu và không đánh giá được tình trạng của bé.', 'The assistant isn’t an emergency service and can’t assess your baby.', 'CH28 body.')
s('asHealthCall', 'Gọi {number}', 'Call {number}', 'CH28 emergency button with the number from the health pack for the household country.' + RULE, number='String')
s('asHealthCallDoctor', 'Gọi bác sĩ của bé', 'Call your baby’s doctor', 'CH28 when the health pack has no number for the household country (never a default hotline).')
s('asHealthFree', 'Miễn phí · không trừ lượt', 'Free · no AI help used', 'CH28 footnote (without the internal "nội dung y tế chờ duyệt theo vùng").' + RULE)
s('asDialFailed', 'Chưa mở được ứng dụng gọi điện.', 'Couldn’t open the phone app.', 'Dialer failed.' + VI_DRAFT)

# CH03 history (612:7784 / 612:8040).
s('asHistoryTitle', 'Hội thoại', 'Conversations', 'CH03 title.')
s('asHistoryToday', 'HÔM NAY', 'TODAY', 'CH03 section.')
s('asHistoryWeek', 'TUẦN NÀY', 'THIS WEEK', 'CH03 section.')
s('asHistoryEarlier', 'TRƯỚC ĐÓ', 'EARLIER', 'CH03 section.' + DRAFT)
s('asHistoryUntitled', 'Cuộc trò chuyện', 'Chat', 'CH03 row without a title.' + VI_DRAFT)
s('asHistoryFootnote', 'Mỗi bé có lịch sử riêng. Đổi bé không chuyển bản nháp đang chờ sang bé khác.', 'Each baby has its own history. Switching baby never moves pending drafts.', 'CH03 footnote.')
s('asHistoryPrivate', 'Chỉ bạn xem được các cuộc trò chuyện của mình. Bản ghi đã lưu vẫn chia sẻ theo vai trò.', 'Only you can see your chats. Saved records stay shared by role.', 'CH03 privacy line (P-158).' + VI_DRAFT)
s('asHistoryEmpty', 'Chưa có cuộc trò chuyện nào.', 'No chats yet.', 'CH03 empty.' + VI_DRAFT)
s('asHistoryFailed', 'Chưa tải được lịch sử.', 'Couldn’t load the history.', 'CH03 load error ("tải lỗi → thử lại").' + VI_DRAFT)
s('asDeleteChat', 'Xoá cuộc trò chuyện', 'Delete chat', 'CH03 row action.' + VI_DRAFT)
s('asDeleteTitle', 'Xoá cuộc trò chuyện?', 'Delete this chat?', 'CH03 confirm title.' + VI_DRAFT)
s('asDeleteBody', 'Tin nhắn và bản nháp chưa lưu trong cuộc trò chuyện này sẽ bị xoá. Những gì đã lưu vào nhật ký, Chi tiêu hay nhắc việc vẫn giữ nguyên.', 'Its messages and unsaved drafts will be deleted. Anything already saved to the log, Expenses or Reminders stays.', 'CH03 confirm body (domain records stay).' + VI_DRAFT)
s('asDeleteConfirm', 'Xoá', 'Delete', 'CH03 confirm button.' + VI_DRAFT)
s('asDeleted', 'Đã xoá cuộc trò chuyện', 'Chat deleted', 'Toast after the server confirmed the delete.' + VI_DRAFT)
s('asDeleteFailed', 'Chưa xoá được. Thử lại sau.', 'Couldn’t delete. Try again later.', 'Delete failed.' + VI_DRAFT)

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
