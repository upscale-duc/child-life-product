# Content audit (read-only, 2026-10-25) and review rubric

**Source:** `app_vi.arb` / `app_en.arb`. Each key's usage was confirmed with a grep for `.<key>` in
`lib/`. **No ARB file was changed.**

**Evidence:**

- **Confirmed (C):** the string exists and is referenced in the screen file named.
- **Rendered (R):** also seen on a golden. Not done in this pass.
- **Hypothesis (H):** needs a rendered check before acting.

Proposed copy is a **proposal**. Apply it under `senior-ui-ux` §3: "Approval?" = **Owner** means
a canonical term, legal or consent wording, so ask first; **No** means a routine clarity fix.

**Verified business meaning (`ui-copy-patterns.md` §5).** Each finding's behaviour status is in §1b.

- **Verified behaviour:** the code path was read and the proposal matches it.
- **Needs behavior verification:** keep the current wording until checked; the proposal is not an
  approved replacement.
- **N/A:** grammar, spelling or terminology only.

## 1. Prioritised findings

| # | Key(s) | Current vi | Current en | Screen | Problem | Proposed vi | Proposed en | Reason | Severity | Approval? | Ev. |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | `rhythmFeeds`, `rhythmBreast` | {count} cữ · {ml} ml | {count} feeds · {ml} ml | `today/today_screen.dart`, `care/history_screen.dart` | en shows "1 feeds" (no ICU plural) on Today | (unchanged) | `{count, plural, =1{1 feed} other{{count} feeds}} · {ml} ml` | Broken grammar on the most-seen screen | **Blocker** | No | C |
| 2 | `stFullBody` | plural without `=0`: "{count} mục mới được giữ trên máy…" | Has `=0` (drops the sentence) | `me/storage_screens.dart` | vi and en differ at 0: vi says "0 mục mới được giữ…" | Add `=0{Tạm dừng tải ảnh, video. Ghi chép chăm sóc vẫn lưu bình thường.}` | (unchanged) | Parity of meaning across languages | **Blocker** (if 0 can occur, H) | No | C/H |
| 3 | `offlineBanner`, `syncingBanner` | Đang offline · {count} bản ghi chờ đồng bộ | Offline · {count} waiting to sync | `today/today_screen.dart` | System words on the main screen ("offline", "bản ghi", "đồng bộ"); vi and en nouns differ | Chưa có mạng · {count} ghi nhận chưa gửi cho cả nhà | No connection · {count, plural, =1{1 log} other{{count} logs}} not sent to the family yet | Says the effect the parent cares about (others can't see it yet). Noun follows the #5 decision | High | No (wording) | C |
| 4 | `carePending`, `pendingTitle`, `syncPendingLong` | Chờ đồng bộ / Đã lưu trên máy này. Đang chờ đồng bộ. | Waiting to sync / Saved on this device. Waiting to sync. | Care detail and pending list | Engineering verb as a status | Chưa gửi cho cả nhà / Đã lưu trên máy này. Sẽ tự gửi cho cả nhà khi có mạng. | Not sent to the family yet / Saved on this phone. It'll reach the family when you're online. | A plain state from the reader's point of view | High | No | C |
| 5 | Care-entry noun: `careSaveFailed`, `deleteRecord`, `deleteConfirmTitle`, `memberRecordsKept`, `whoSubtitle` (+ ~14) | "bản ghi" | record / log | Care sheets, care detail, family | The glossary splits ghi nhận / bản ghi / nhật ký and log / record / note | "ghi nhận", or the thing itself ("Xoá cữ bú này?") | "log", or the thing ("Delete this feed?") | One word per concept; parent language | High | **Owner** (canonical) | C |
| 6 | `careSaveFailed` | Chưa lưu được bản ghi. Có thể quyền của bạn đã thay đổi. | The record could not be saved. Your access may have changed. | `care/care_sheets.dart`, `timer_screens.dart` | System noun; the passive en; no next step | Chưa lưu được ghi nhận này. Có thể quyền của bạn vừa thay đổi. *(next-step clause: role-aware, see §1b)* | Couldn't save this log. Your access may have changed. | What happened → what to do. The earlier draft "hỏi ba mẹ của bé" was withdrawn: the reader may be a parent | Medium | No | C |
| 7 | The assistant's name: `asEntryTitle`, `spFromAssistant`, `asEmptyBody`, vs Lumi | Trợ lý Child Life / từ Trợ lý / Trợ lý hiểu… | Child Life assistant / from the Assistant / The assistant understands… | `assistant/assistant_entry.dart`, `spending/spending_format.dart`, `assistant_screens.dart` | Three names for one helper; "hiểu" / "understands" overclaims | Lumi / từ Lumi / Lumi đọc những gì bạn gửi và tạo bản nháp. Bạn kiểm tra trước khi lưu. | Lumi / from Lumi / Lumi reads what you send and drafts it. You check before saving. | One character; honest capability | Medium | **Owner** (name); No (the "hiểu" wording) | C |
| 8 | `asUsageTitle` vs Premium v2 credits | Lượt hỗ trợ AI | AI help | `assistant/assistant_screens.dart` | Conflicts with "Lumi credit" (D-101, `pv2CreditsLeft`) | Credit của Lumi | Lumi credits | One unit name for one resource | Medium | **Owner** | C |
| 9 | `remindersTitle`, `careReminders` vs `reminderNew` | Nhắc nhở | Reminders | `reminders/reminder_screens.dart`, care hub | The screen says "Nhắc nhở", its items "Nhắc việc" | Nhắc việc | Reminders | The title matches its content | Medium | **Owner** | C |
| 10 | `roleRelative` vs `babyPrivacyNote` | Người thân / Người thân chỉ thấy… | **Family member** / **Relatives** only see… | Family labels; onboarding setup | en uses two names for one role | (unchanged) | Family members only see the nickname | en role consistency | Medium | **Owner** (en role name) | C |
| 11 | `rhIntMoments` (+ `pmPlanExpiredBody` "moments") | Kỷ niệm | Moments | `rhythm/rhythm_labels.dart` | en names the Memories feature "Moments" | (unchanged) | Memories | Feature name matches the tab | Low | No | C |
| 12 | `asVideoQuotaTitle` vs `ksVideoTitle` | Xuất video kỷ niệm / Video kỷ niệm | Keepsake video exports / Memory video | Assistant quota; keepsakes | en uses two names for one product | (unchanged) | Memory video exports | Consistency | Low | No | C |
| 13 | `tourShareBody` | Lần ghi gần nhất được đồng bộ cho cả nhà: ai ghi, ghi gì, lúc nào. | The latest log is synced to the whole family… | `onboarding/welcome_screens.dart` | A mechanism word in the first impression | Người cùng chăm thấy ngay lần ghi mới nhất: ai ghi, ghi gì, lúc nào. | Everyone caring for the baby sees the latest log: who logged what, and when. | Benefit, not mechanism; "cả nhà" overstates (relatives without daily care don't see logs, D-018) | Low | No | C |
| 14 | `engOffline` | Chưa kiểm tra được gợi ý. Bạn vẫn có thể tiếp tục dùng ứng dụng. | Suggestions could not be checked. You can continue using the app. | `engagement/engagement_week.dart` | Vague; the second sentence adds nothing; passive en | Chưa tải được gợi ý. Thử lại sau nhé. | Couldn't load suggestions. Try again later. | What happened → what to do. Not "khi có mạng": the key shows on **any** error, not only offline | Low | No | C |
| 15 | `imBusyReading` | Đang đọc dữ liệu… | Reading… | `spending/import/import_screens.dart` | "dữ liệu"; vi and en specificity differ | Đang đọc tệp… | Reading the file… | Name the thing; parity | Low | No | C/H |
| 16 | `sdS1Title` | Theo dõi sau dấu hiệu hôm {date} ({foods}). Tạm chưa thử món mới vài ngày và hỏi bác sĩ nếu còn lo. | Keep an eye on baby after the signs on {date} ({foods})… | `solids/solids_personal.dart` | A two-sentence "title" (22 words); en "on baby" lacks an article | Title: Theo dõi sau dấu hiệu hôm {date} · body: Tạm chưa thử món mới vài ngày. Hỏi bác sĩ nếu bạn còn lo. | Title: Keep an eye on your baby after {date} · body: Hold off new foods for a few days. Ask your doctor if you're still worried. | Health guidance stays visible but structured | Medium | No (keeps meaning) | C/H |
| 17 | `lastNightInsight` | Đêm qua bú {count} cữ, khoảng nghỉ dài nhất {gap} ({from}–{to}). | Last night: {count} feeds, longest gap… | `care/stats_screens.dart` | Four values in one sentence (comparison and scanning); en plural | Tiles: "{count} cữ đêm" + "Nghỉ dài nhất {gap} · {from}–{to}" | "{count, plural…} at night" + "Longest gap {gap} · {from}–{to}" | Scan, not parse (a layout change, via `senior-ui-ux` §5.4) | Low | No | C |
| 18 | `pickSummary`, `albAppliesTo`, `dlSummary`, `albDeleteBody` | — | "{count} items…" | Media picker, albums, download | en plural missing | (unchanged) | ICU plural | Grammar | Medium | No | C |
| 19 | `deleteRecord`, `deleteConfirmTitle`, `deletedToast`, `cancelNoSave`, `cancelConfirmTitle` | Xóa… / Hủy… | — | Care detail, timers | Old-style tone marks (the catalog uses Xoá ×144, Huỷ ×40) | Xoá… / Huỷ… | — | Orthographic consistency | Low | No | C |
| 20 | `todayCustomize` / `customizeTitle` vs `psCustomize`; `Personalisation` vs `Personalize` | — | Customise / Customize; Personalisation / Personalize | Today, print studio, rhythm | en UK / US mix | — | One spelling (recommended: US) | Consistency | Low | **Owner** (UK vs US) | C |
| 21 | `pmPlanOwnerOnly` (+ "hộ", "chủ hộ") | Chỉ chủ hộ mua và quản lý gói… | Only the family owner buys… | `premium/plan_screen.dart` | vi "hộ" (household) next to "gia đình"; en "family owner" vs "household plan" | (keep until decided) | (keep) | Terminology | Low | **Owner** | C |
| 22 | `careDaily` vs `rightDailyCare` | Chăm hằng ngày / Chăm sóc hằng ngày | Daily care / Daily care | Care hub / family rights | Two vi forms for one concept | Keep "Chăm hằng ngày" only as the compact hub label (D-069) | — | Documented exception | Low | No | C |
| 23 | 258 unreferenced keys (e.g. `historySoon` "…sẽ có ở bản tiếp theo." / "…arrives in a later build.") | — | — | none | Dead and engineering-worded copy | Delete in a cleanup | — | Catalog hygiene | Low | No | C (unreferenced in `lib/`; check native first) |
| 24 | `@description` of `{name}` | — | — | 218 / 245 | The description doesn't say whether `{name}` is the baby, a member or the user | Add who it is when touched | — | Translation safety | Low | No | C |
| 25 | Displayed ISO date | — | — | `print_studio/print_address_editor.dart:207` `DateFormat('yyyy-MM-dd')` | A raw ISO date may be shown to the user | `dd/MM/yyyy` | — | Readability | Low | No | **H** (render) |

## 1b. Behaviour verification per finding

| # | Behaviour status | Evidence / what to check |
|---|---|---|
| 1, 2, 18 | N/A (grammar / plural) | — |
| 3, 4 | **Verified behaviour** (care records) | Today's count = recent care records with `pending` = Firestore `metadata.hasPendingWrites` (`features/today/today_screen.dart:74`, `features/care/care_models.dart:351`). Not yet on the server, so other members can't see them. Matches the shipped `pendingFootnote` "Người cùng chăm chưa thấy các bản ghi này". "cả nhà" = members who can see daily care (D-018) |
| 5 | N/A (terminology; owner decision) | — |
| 6 | **Needs behavior verification** (next step) | `careSaveFailed` fires when an optimistic write is later **rejected by the server** (`commitRecord` `failed`, `features/care/care_sheets.dart`; `endTimer` `onError`), not on lost connection. "Quyền đã thay đổi" is the likely cause (Rules), but validation rejections are possible. The next-step clause must be role-aware (a parent vs a caregiver). Keep the current wording's cause hedge ("Có thể") |
| 7 | Verified (drafts + check before saving: `asModuleSub`, draft cards) / **Needs behavior verification** (inputs) | Lumi reads text, photos (`asReadingPhoto`) and voice (`asVoiceStart`), hence "những gì bạn gửi" / "what you send", not "tin nhắn" / "message". The name change is an owner decision |
| 8, 9, 10, 11, 12, 19–22 | N/A (terminology / spelling; some owner decisions) | — |
| 13 | Verified (role nuance) | D-018: relatives see logs only with daily care. The current string's "cả nhà" already overstates; the proposal narrows it |
| 14 | **Verified behaviour** (corrected) | `engOffline` renders on any provider error and on a failed toggle (`features/engagement/engagement_widgets.dart:88`, `:158`), so the proposal no longer blames the connection |
| 15 | **Needs behavior verification** | Verified for the file import (`_file`: csv / xlsx / xls / txt / tsv, `features/spending/import/import_screens.dart:131`). The same label is the generic busy overlay (`:778`); check the other import paths before "tệp" / "file" |
| 16 | Verified (meaning kept) | Same instruction and doctor hedge, restructured |
| 17 | N/A (layout) | — |
| 23 | Verify native use before deleting | `glance_copy.dart`, iOS / Android widget code |
| 24 | N/A | — |
| 25 | **Needs behavior verification** | Render `print_studio/print_address_editor.dart:207` |

**Strengths found (keep them):**

- Premium copy is calm and states what Free keeps (`pmPaywallFreeBody`, `pmExpiredStrip`); no
  pressure words appear in `pm*` / `pv2*`.
- Health notes are careful and kind (`whoBelowHeadNote`: "Mỗi bé lớn theo nhịp riêng — bạn nên
  trao đổi với bác sĩ ở lần khám tới.").
- AI disclaimers are honest (`rhSetupDisclaimer`, `asConfirmDate`).
- The engagement tone respects choice (`engBody`).
- Empty states invite an action (`memEmptyBody`).

## 2. UX writing review rubric

Score each relevant dimension: **2** good · **1** acceptable · **0** problem. Report blockers
first.

| Dimension | Question |
|---|---|
| Clarity | Is the one takeaway obvious in a single read? |
| Conciseness | Is anything repeated or explained that doesn't help the next action? (Never cut safety, consent, cost or data-loss information.) |
| Natural Vietnamese | Would a Vietnamese parent say it this way? No calques or system words |
| Natural English | Would a native app writer ship it? Articles, plurals, sentence case |
| Terminology | Glossary terms; one word per concept; feature names right |
| Action clarity | Does the verb say what happens, and does the destination match? |
| Context awareness | Is the tone right for the moment (night, health, celebration, error, Premium)? |
| Accessibility | Spoken labels complete, units spoken, not colour-only, fits at 200 % |
| Localisation correctness | Placeholders, plurals, dates and numbers per locale; parity of meaning |
| Trust and certainty | Facts, summaries, suggestions, predictions and AI kept distinct; no unsupported claims; no pressure |

**Blockers (must fix before shipping):**

- a button or link misrepresents its action or destination;
- vi and en mean materially different things;
- an AI or insight claims certainty the data doesn't support, or implies a diagnosis;
- a critical warning (health, data loss, payment, privacy) is unclear or hidden;
- a placeholder or plural produces broken grammar ("1 feeds", an empty name);
- a rewrite changes verified product behaviour or business meaning (wider audience, different
  cause, more certainty, a softer term that is less true), or presents unverified wording as
  approved;
- a localised string causes essential information or an action to be truncated or disappear;
- Premium copy uses guilt, fear or false urgency.

**Recommendations (improve when touching):**

- a long subtitle;
- two words for one concept;
- a sentence that could be a label and value;
- a slightly unnatural phrase;
- a technical term on an everyday surface where an equally accurate plain word exists;
- UK / US spelling drift.

Stylistic preference alone is never a blocker.

**Report format:** a table of key | current vi / en | rendered context | issue | proposal vi / en
| severity | approval. Lead with the before / after golden images when the change is visible.
