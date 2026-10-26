# UI copy patterns

**Examples** marked with a `key` are current app copy. Examples marked *(model)* are proposed
wording to imitate; they are not in the app.

**Length guidance** is in words (vi / en) and is a budget, not a law. Exceed it when clarity needs
it, and render it to check fit. Today's medians and p90s: title 4 / 8, subtitle 7 / 12,
body 15 / 25, empty 8 / 16, error 8 / 15.

## 1. Content first: what should be visible

1. **One takeaway per block.** What should the parent know or do after reading it?
2. **Pick the form:**

   | Content | Form |
   |---|---|
   | A state | Label (chip, status) |
   | A quantity | Value with unit (stat, row value) |
   | A relationship or explanation | Sentence |
   | 3+ parallel items | List or rows |
   | Something to do | Button or tappable row |

3. **Don't repeat a fact** already visible (a title and a subtitle saying the same thing; a
   sentence restating the rows).
4. **Facts and recommendations stay separate:** what happened (fact), then what you might do
   (suggestion).
5. **Progressive disclosure.** Mechanism, privacy detail and methodology go behind "Tìm hiểu thêm"
   / "Learn more", **except** consent, safety, cost and data-loss information, which stay
   visible.
6. **Skip the subtitle** unless it adds something the title can't.

Layout decisions are `cl-screen-patterns` (`information-hierarchy.md`); which component to
use is `cl-components`.

## 2. Pattern table

| Pattern | Purpose / structure | vi | en | Good ✓ / bad ✗ | Length | A11y |
|---|---|---|---|---|---|---|
| **Page title** | Name the place or job; a noun | "Lịch sử" (`historyTitle`) | "History" | ✗ "Lịch sử chăm sóc của bé" | 1–3 | `header: true` (built into `ClNavHeader` / `MePage`) |
| **Section heading** | Say what's inside | "Nhắc việc sắp tới" (`sectionReminders`) | "Upcoming reminders" | ✗ "Thông tin" / "Other" | 1–4 | Header semantics |
| **Card title** | The card's answer or subject | "Bàn giao" (`aiHandoverTitle`) | "Handover" | ✗ a full sentence | 1–5 | Part of the card's spoken sentence |
| **Card description** | One line adding *why* or *what next* | "Bản này được tạo trước những ghi nhận mới nhất." (`aiStateStaleBody`) | "This was made before the latest notes." | ✗ two sentences repeating the title | ≤ 15 / ≤ 18 | — |
| **Button** | Verb (+ object when ambiguous); names the result | "Lưu số đo" (`saveGrowth`) | "Save measurement" | ✗ "OK", "Xác nhận", "Submit". Use a longer label only when clearer: "Lưu và thêm" | 1–3 typical | The label is the accessible name; `ClButton` is single-line, so check 200 % |
| **Link** | Destination or verb | "Xem tất cả" *(model)* | "See all" | ✗ "Bấm vào đây" / "Click here" | 1–3 | Says where it goes |
| **Tab / segment** | Parallel nouns | "Ngày · Tuần" *(model)* | "Day · Week" | ✗ mixing verb and noun | 1–2 | — |
| **Chip** | A state or filter value | "Bú" (`filterFeed`) | "Feeds" | ✗ a sentence in a chip | 1–2 | Selected state is announced |
| **Status label** | A state from the reader's point of view, accurate to what the system did (§5) | "Chờ đồng bộ" (`carePending`) → *(model, behaviour verified for care records)* "Chưa gửi cho cả nhà" | "Not sent to the family yet" | ✗ two contradictory statuses together | 1–3 | Icon + words (`ClSyncStatus`) |
| **Form label** | The noun being asked for | "Tiêu đề" (`ksVideoFieldTitle`) | "Title" | ✗ a question as a label *and* a placeholder | 1–3 | Read with the field |
| **Placeholder** | An example or hint, never the label | "VD: 120" *(model)* | "e.g. 120" | ✗ the label as the placeholder only (it disappears on typing) | 1–4 | Not a substitute for the label |
| **Validation** | What to fix, specifically | "Đặt tiêu đề cho câu chuyện." (`sryNeedTitle`) | "Give the story a title." | ✗ "Không hợp lệ" / "Invalid input" | ≤ 10 | Live region (`_ErrorText` pattern) |
| **Empty state** | What's missing → (why) → what to do | "Chưa có kỷ niệm nào" + "Chạm + để thêm ảnh, video hoặc ghi chú đầu tiên của {name}." (`memEmptyTitle` / `memEmptyBody`) | "No memories yet" + "Tap + to add {name}'s first photo, video or note." | ✗ an apology, or a paragraph on the feature | Title ≤ 6, body ≤ 18 | One action |
| **Loading** | Usually no text (skeleton). For a long wait: what + how long | "AI đang đọc, có thể mất nửa phút…" (`imBusyAi`) | "The AI is reading; this can take half a minute…" | ✗ "Đang xử lý dữ liệu…" | ≤ 8 | Live region; "…" not "..." |
| **Success (toast)** | Past tense + the object; undo if reversible | "Đã ghi · {what}" (`savedToast`) | "Logged · {what}" | ✗ "Thành công!" | ≤ 6 | Toast announced |
| **Error** | What happened → what to do. "Chưa … được" | "Bạn chưa bị trừ tiền nếu cửa hàng không xác nhận. Thử lại sau nhé." (`pmErrorBodyPlain`) | "You aren't charged unless the store confirms. Please try again." | ✗ "Lỗi 500", "Đã xảy ra lỗi", blaming the user | Title ≤ 6, body ≤ 20 | Error is text, not colour only |
| **Confirmation** | Question naming the object → consequence → verb buttons | "Xoá {count} mục?" + "Mục sẽ biến mất khỏi Kỷ niệm của cả gia đình…" (`delTitle`, `delBody`) | "Delete {count} items?" (plural) | ✗ "Bạn có chắc không?" + "Đồng ý / Huỷ" | Title ≤ 6, body ≤ 25 | Confirm verb = the action ("Xoá") |
| **Notification** | See §3 | | | | | |
| **Onboarding** | A benefit as a concrete action | "Ghi bú, ngủ, tã chỉ bằng một tay" (`tourCareTitle`) | "Log feeds, sleep, diapers with one hand" | ✗ "Đồng bộ dữ liệu thời gian thực" | Title ≤ 8 | — |
| **Tooltip / coachmark** | One instruction tied to what is pointed at | "Chạm để hỏi Lumi về ghi nhận của bé." (`asLumiIntroBodyViewer`) | "Tap to ask Lumi about your baby's records." | ✗ a feature essay | ≤ 12 | Skippable |
| **Premium paywall** | Value as outcomes → what Free keeps → one calm action | "Hết gói vẫn xem dữ liệu, kỷ niệm và file đã xuất." (`pmPaywallFreeBody`) | "After Premium ends you keep your data, moments and exported files." | ✗ "Đừng bỏ lỡ…", countdowns, "Chỉ hôm nay", a crossed-out fake price | Headline ≤ 8 | Price and period spoken in full |

## 3. Notifications

Messages must make sense **outside the app** (lock screen, watch, preview), and must never promise
a destination or action that doesn't exist.

| Kind | Where the copy lives | Rules | Example (current) |
|---|---|---|---|
| **Push title / body** (server) | Built-in templates `packages/contracts/src/notification-platform.ts` (`notificationTemplates[id].builtin`), editable in the Portal (P-174, `docs/notifications/05-templates.md`) | Title ≤ 65 chars (aim for 40); body ≤ 178 (aim for 110). Placeholders `{{baby_name}}` (falls back to "bé" / "your baby"), `{{actor_name}}`, `{{count}}`, `{{plural:count\|one\|other}}`. No child data beyond the registry (R-120). Starts with a capital letter after rendering | "Đến giờ {{activity_name}} cho {{baby_name}}" / "Time for {{baby_name}}'s {{activity_name}}" |
| **In-app inbox entry** | ARB (`nt*`) + server copy | The same text as the push, plus time; the row says what opens | "Chưa có thông báo nào" (`ntEmptyTitle`) |
| **Smart suggestions** (Smart Engagement) | ARB `eng*`; server `engagement.ts` | Optional by tone: "Xem khi thuận tiện. Bạn luôn là người quyết định…" (`engBody`). Never nag; no streaks or guilt | "Nhìn lại tuần qua" (`engWeekly`) |
| **Reminders** | Server `reminder-rules.ts` + templates | Name the task and the child; time is implicit | (as push) |
| **Background completion** | ARB / templates | Past tense + result + where to see it | "Đã nhập xong chi tiêu" / "Your spending import is done" |
| **Deep-link destination** | ARB | The action label names the destination ("Mở Chi tiêu", "Open Spending") and the destination must exist (`notifications/notification_destinations.dart`) | "Mở Chi tiêu để xem chi tiết." |

**Widgets and Live Activities** take their copy from ARB through `lib/l10n/glance_copy.dart`. The
placeholders there are literal `{x}` text filled in Swift, so **ICU plurals don't work**; write
counts that read correctly for any number ("{n} mục chưa tải lên được") or avoid the plural noun.

## 4. Technical terms: choose by context, not by a ban

**The default is plain, parent-friendly wording.** Technical terms are **allowed, and sometimes
better,** when they help the reader understand or act on:

- data synchronisation;
- offline storage;
- backups;
- privacy;
- permissions;
- account security;
- technical troubleshooting.

Choose by the reader's context, their comprehension, and **accuracy**.

**Rules:**

1. **Never swap a technical term for friendlier words if that changes the meaning.** "Đã sao lưu"
   ≠ "Đã lưu"; "Chờ đồng bộ" ≠ "Đã lưu". The plain version must describe what the system actually
   does (see §5, verified business meaning).
2. **Everyday surfaces** (Today, care logging, memories, toasts): prefer the plain wording when it
   is equally accurate. Name the effect the parent cares about.
3. **Detail, settings, privacy, consent, security and troubleshooting surfaces:** use the precise
   term, and add a short plain gloss if a parent might not know it ("Đồng bộ: gửi ghi nhận lên để
   cả nhà cùng thấy").
4. **Pick one term per concept** within a screen and keep it (glossary §9).
5. **Never** show internal identifiers, error codes, stack details, environment names or build
   jargon on user surfaces. Error codes are allowed only where they help recovery or support (a
   copyable code on a diagnostics or support screen).

| Term (vi / en) | Plain alternative (everyday surfaces) | Keep the term when… | Accuracy note |
|---|---|---|---|
| bản ghi / record | ghi nhận / log, or the thing itself (cữ bú / feed) | — (no context needs "bản ghi") | Same meaning; the canonical noun is an owner decision (glossary §2) |
| đồng bộ, chờ đồng bộ / sync, waiting to sync | chưa gửi cho cả nhà / not sent to the family yet | Sync details, troubleshooting, settings | Verified equivalent for care records: pending = `metadata.hasPendingWrites` (`features/care/care_models.dart`), so not yet on the server and not visible to others. Re-verify for other data types |
| offline / ngoại tuyến | chưa có mạng / no connection | Offline storage explanations, settings | Plain only when the cause *is* no connection. Don't use it for generic failures |
| dữ liệu / data | name it: ảnh, ghi nhận, lịch sử / photos, logs, history | Privacy, export, deletion, consent ("Xuất dữ liệu", `acExport`) | In privacy and export copy, "dữ liệu" is the accurate umbrella term |
| sao lưu / backup | — | Backups (keep the term) | "lưu" is not a backup |
| quyền / access, permissions | — | Permissions (keep); en "access" in role UI | — |
| máy chủ, hệ thống, cấu hình / server, system, configuration | say the effect | Diagnostics, support | — |
| xác nhận (as a button) / Confirm | the verb itself (Xoá, Lưu, Gửi) | Account security ("Xác nhận email", `linkConfirmTitle`), payments | — |
| thực hiện, tiến hành / perform, proceed | the verb | — | — |
| bản (build), phiên bản tiếp theo / build | — | App update screens only ("phiên bản") | — |

## 5. Verified business meaning (non-negotiable)

**Every copy proposal must preserve verified product behaviour and business meaning.** Before
rewriting a **status, action, permission, error or explanation:**

1. **Identify** the current wording (key, vi, en).
2. **Inspect** the relevant business rules (`docs/product/business-map.md`) and the code that
   uses the key (`grep -rn "\.<key>\b" apps/mobile/lib`, then read the trigger).
3. **Determine** what the system actually does: when it shows, for whom (role), and what has or
   hasn't happened.
4. **Verify** that the proposal says exactly that (no more certainty, no wider audience, no
   different cause).
5. **If behaviour is uncertain,** mark the proposal **`Needs behavior verification`** and keep the
   accurate current wording until it is checked.
6. **Never present unverified wording** as an approved replacement.

**Example.** Current "Chờ đồng bộ" / "Waiting to sync" → proposal "Chưa gửi cho cả nhà" / "Not sent
to the family yet". This is acceptable **only because** the implementation confirms the record has
not reached the server, so others can't see it yet. For a data type where that isn't true, keep
"Chờ đồng bộ" or find other accurate wording.

Watch especially:

| Area | What to check |
|---|---|
| Sync and availability | Who can see it, and when |
| Permissions | Which role, what exactly is refused |
| AI capability | What the model actually reads or does |
| Errors | The real cause vs a guessed cause |
| Plans and quotas | Values come from config, not copy |
