# Personalisation and AI (Lumi) copy

**Scope.**

- **Covered here:** UI strings in ARB about personalised content and AI, the wording of
  insight templates, and how Claude Code should judge generated text when reviewing a screen.
- **Not covered:** the generated text itself, which comes from server prompts:
  - `firebase/functions/src/ai.ts` (summaries / handover);
  - `assistant-model.ts`, `assistant-care-model.ts` (Lumi).

  **Don't change prompts or backend behaviour from this skill.** Prompt changes are a separate
  task with evals (`docs/assistant/evaluation.md`). Live-model runs cost money: only for new or
  changed cases.

## 1. Five kinds of statement: never blur them

| Kind | Definition | vi wording | en wording | Example |
|---|---|---|---|---|
| **1. Observed fact** | Directly logged by the family | Plain past: "Bú bình 120 ml lúc 07:30" | "Bottle, 120 ml at 07:30" | A care row |
| **2. Calculated summary** | Arithmetic on logs, with its window | "Hôm nay: 6 cữ · 720 ml"; "TB 7 ngày" | "Today: 6 feeds · 720 ml"; "7-day average" | `perDay` "TB mỗi ngày" |
| **3. Pattern-based suggestion** | A heuristic on several days | "Gần đây…", "thường…", "có thể thử…" | "Recently…", "usually…", "you could try…" | D-102 "Gần đây ít hơn khoảng 2 giờ so với trước" |
| **4. Prediction** | About the future | "Cữ tới **khoảng** 10:30", "có thể" | "Next feed **around** 10:30", "may" | Always approximate, never a promise |
| **5. AI interpretation** | Model-generated text | Attributed: "Lumi tóm tắt…", "Bản tóm tắt bằng AI" + basis | "Lumi's summary…", "AI summary" + basis | Handover (`aiHandoverTitle`) |

**Rules:**

- **Never present 3, 4 or 5 as 1.** Predictions carry "khoảng / có thể / around / may".
  Interpretations are labelled as AI and say what they're based on (the window, the logs).
- **Comparisons need a basis:** say what is compared with what, and only when the data
  supports it (enough days, logged consistently). Otherwise say nothing, or say "chưa đủ ngày để
  so sánh" / "not enough days to compare yet".
- **No diagnosis, no "abnormal" without a reliable basis.** Use "thường thấy ở…", "nếu bạn lo,
  hãy hỏi bác sĩ" / "if you're worried, ask your doctor". One health disclaimer per screen (D-102),
  as in `rhSetupDisclaimer`.
- **The app doesn't know the baby's needs.** No "Bé cần…", "Bé đang đói", "Bé thiếu ngủ" from
  logs.

| ✗ Avoid | ✓ Prefer (vi) | ✓ Prefer (en) | Condition |
|---|---|---|---|
| "Bé đang thiếu ngủ." | "Giấc ngủ hôm nay ngắn hơn những ngày gần đây." | "Today's sleep is shorter than on recent days." | Only with enough recent days logged |
| "Bé sắp đói." | "Cữ tới khoảng 10:30." | "Next feed around 10:30." | Based on the recent interval |
| "Bé phát triển chậm." | (don't generate) | (don't generate) | Development judgements are not app copy |
| "Lumi thấy bé quấy vì mọc răng." | "Lumi chưa biết nguyên nhân. Nếu bé quấy kéo dài, hãy hỏi bác sĩ." | "Lumi can't tell the cause. If the fussiness lasts, ask your doctor." | Always |

## 2. Lumi's voice in the UI

Lumi should:

- **use the app language** (the locale override, `lib/app/locale.dart`);
- **be concise:** one or two sentences, then an action;
- **say what it used** ("Từ ghi nhận 7 ngày qua" / "From the last 7 days of logs");
- **mark uncertainty** in the place it applies, as `asConfirmDate` does ("Ngày chưa chắc: chạm vào
  ngày để chọn hoặc xác nhận trước khi lưu.");
- **draft, not decide:** the parent checks before saving. This is current product truth:
  `asModuleSub` "Trợ lý đọc và tạo bản nháp · bạn kiểm tra trước khi lưu";
- **offer one practical next step;**
- **never** fabricate observations, claim to have "seen", "noticed" or "understood" beyond the
  data, use emotional pressure, or praise itself.

**Words to watch:** `asEmptyBody` "Trợ lý **hiểu** và tạo bản nháp" / "The assistant
**understands** and drafts" overstates. Prefer "đọc tin nhắn và tạo bản nháp" / "reads your message
and drafts". This is a non-canonical wording change: do it when the screen is touched.

| Situation | vi (model) | en (model) |
|---|---|---|
| Greeting with data | "Hôm nay bé đã bú 4 cữ. Bạn muốn ghi gì tiếp?" | "4 feeds logged today. What would you like to log next?" |
| Not enough data | "Mới có 2 ngày ghi nhận, chưa đủ để thấy nhịp ngủ." | "Only 2 days logged so far, not enough to see a sleep pattern yet." |
| Uncertain parse | "Mình chưa chắc giờ bú. Chọn giờ trước khi lưu nhé." | "I'm not sure about the feed time. Pick it before saving." |
| Out of scope or health | "Lumi không thay được bác sĩ. Nếu bé sốt cao hoặc bỏ bú, hãy gọi bác sĩ ngay." | "Lumi can't replace a doctor. If your baby has a high fever or won't feed, call a doctor now." |
| Credits used up (Premium v2, calm) | "Lumi đã dùng hết {n} credit tháng này" (`pv2E07Title`, current) | "Lumi has used all {n} credits this month" (current) |

Lumi refers to itself as "Lumi" in third-person UI labels. In chat bubbles, first person
("mình" / "I") is acceptable if the product already does so; check the assistant goldens before
changing.

## 3. Personalisation from profile and logs

- **Name.**
  - Use `{name}` (the baby's nickname) where it helps the parent tell babies apart or makes a
    moment personal: milestones, memories, push for multi-baby families.
  - Use "bé" / "your baby" in routine UI.
  - Push uses `{{baby_name}}` with the "bé" / "your baby" fallback, and respects "Hiện tên bé trong
    thông báo" (D-094).
- **Age** via `ageLong` / `ageShort` + ARB; guidance is phrased as typical ranges ("thường từ…").
- **Family activity:** "{who} ghi" / "by {who}" (`careLoggedBy`). Name the actor, never judge
  ("Mẹ chưa ghi hôm nay" ✗).
- **Preferences:** reflect them back plainly ("Bạn đã ẩn gợi ý này" / "You hid this suggestion").
- **Role-aware:** never show the reader a state that belongs to someone else (`senior-ui-ux` §2A).
  Relatives see read-only wording.
- **Privacy:** no child names, DOB, photos, captions or care values in logs, analytics or push
  beyond the registry (CLAUDE.md security rule; R-120).

## 4. Smart suggestions (Smart Engagement)

- **The product name in UI** is "Gợi ý thông minh" / "Smart suggestions" (`engTitle`). Never
  "Smart Engagement" (internal).
- **Tone is optional and respectful:** `engBody` "Xem khi thuận tiện. Bạn luôn là người quyết định
  lưu hay tạo kỷ niệm." / "Take a look when convenient. You always decide what to save or create."
  That is the model.
- **Forbidden:**
  - streaks;
  - "Bạn đã bỏ lỡ…" / "You missed…";
  - guilt about un-logged days;
  - fake urgency;
  - milestone FOMO used to sell Premium.
