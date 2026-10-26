# Voice and tone

## 1. The Child Life voice

A calm, capable friend who also has a child, writing in both languages. The voice stays the same
everywhere; the tone shifts with the moment.

| Is | Isn't |
|---|---|
| Warm | Sentimental, syrupy |
| Caring | Patronising ("đừng lo nhé mẹ ơi") |
| Friendly | Childish, cutesy, emoji-heavy |
| Confident | Authoritative, clinical |
| Encouraging | Judging ("bạn quên ghi", "chưa đủ") |
| Clear | Robotic, system-speak |
| Calm | Alarming, urgent |

**Address and naming (verified current practice):**

- vi: the parent is **"bạn"**; the family is **"nhà mình"** (use sparingly, in warm contexts);
  the child is **"bé"**, or the child's name via `{name}` when it helps; "con" in milestone cheers
  ("Con biết bò rồi!").
- en: the parent is **"you"**; the child is "your baby" or the name. The text is gender-neutral
  (they / their); the catalog has no he / she.
- No honorifics ("ạ"), no "mẹ ơi" (the reader may be a father, a grandparent or a caregiver).

**Avoid everywhere:**

- corporate jargon;
- stacked explanations;
- "!" outside celebrations;
- guilt;
- overpromising ("luôn", "đảm bảo", "always", "guaranteed");
- inflated AI enthusiasm ("Tuyệt vời!", "Amazing insight!");
- generic motivation ("Bạn đang làm rất tốt!", "You've got this!").

**Technical terms depend on context** (`ui-copy-patterns.md` §4):

- **Default:** plain wording on everyday surfaces.
- **Where precise terms belong:** sync, offline storage, backups, privacy, permissions, account
  security and troubleshooting, often with a short plain gloss.
- **Accuracy wins over friendliness:** never trade a precise term for warmer words that change
  the meaning (§5 there).

**What exists today (strengths to keep):**

- warmth particles are used lightly ("nhé" 59, "rồi" 57);
- 24 exclamation marks, almost all in keepsake celebrations;
- 9 emoji, all in greetings or celebrations;
- Premium copy has no pressure words: no "bỏ lỡ", "miss out", "last chance".

## 2. Tone by context

| Context | Tone | vi (current or model) | en | Rules |
|---|---|---|---|---|
| **Everyday tracking** | Short, practical, verb-first | "Ghi cữ bú" (`feedSheetTitle`); toast "Đã ghi · Bú bình" (`savedToast`) | "Log a feed"; "Logged · Bottle" | No adjectives. State, then the action. One-hand, half-awake friendly |
| **Milestones and memories** | Warm, celebratory, personal | "Con biết bò rồi!" (`ksAchieveCrawls`); "Hôm nay {name} tròn {occasion} 🎂" (`ksNudgeTodayTitle`) | "{name} is {occasion} today 🎂" | The only place for "!" and an emoji, one at most. Use the name. Celebrate the child, not the app |
| **Sleep and night** | Calm, minimal, reassuring | "Đang ngủ · từ 21:27" | "Asleep · since 21:27" (the app uses 24-hour time in both languages today; see `numbers-dates-and-units.md`) | Fewest words; no questions that need thought; no celebration; never "tại sao bé chưa ngủ" |
| **Health** | Careful, factual, appropriately uncertain | "Child Life không dự đoán chắc chắn ngày quấy hay chẩn đoán nguyên nhân." (`rhSetupDisclaimer`) | "Child Life doesn't predict fussy days with certainty or diagnose causes." | Facts with their basis; "có thể", "thường", "nếu… hãy hỏi bác sĩ". Never imply abnormal development without a reliable basis. One disclaimer per screen (D-102) |
| **Errors** | Plain, blame-free, actionable | "Chưa tải được thông báo" (`ntLoadFailedTitle`) + what to do | "Couldn't load notifications" | What happened → what to do. "Chưa … được" (not yet) rather than "Lỗi" / "thất bại" |
| **Premium** | Clear value, no pressure | "Hết gói vẫn xem dữ liệu, kỷ niệm và file đã xuất." (`pmPaywallFreeBody`) | "After Premium ends you keep your data, moments and exported files." | Say what you get and what you keep. No urgency, no fear of missing milestones, no guilt, no countdown pressure |
| **Lumi (AI)** | Helpful, contextual, transparent | "Ngày chưa chắc: chạm vào ngày để chọn hoặc xác nhận trước khi lưu." (`asConfirmDate`) | "The date isn't certain: tap it to pick or confirm before saving." | Concise by default; say what it is based on; label uncertainty; offer a next step; no diagnosis; never claim to have "seen" or "understood" beyond the data (`personalization-and-ai-copy.md`) |
| **Family and sharing** | Respectful, clear about who sees what | "Người thân chỉ thấy tên thân mật" (`babyPrivacyNote`) | "Relatives only see the nickname" | Name the audience explicitly; consent and privacy copy is never shortened away |
| **Privacy, security, sync, troubleshooting** | Precise, calm, plain gloss where useful | "Đã lưu trên máy này. Đang chờ đồng bộ." (`syncPendingLong`); "Tự gửi khi có mạng. Người cùng chăm chưa thấy các bản ghi này." (`pendingFootnote`) | "Saved on this device. Waiting to sync."; "Sends automatically when online. Others caring for the baby can't see these yet." | Technical terms allowed when accurate (`ui-copy-patterns.md` §4); say what is safe, what isn't yet, and what happens next. Never soften a term into something less true |
| **Onboarding** | Welcoming, concrete | "Ghi bú, ngủ, tã chỉ bằng một tay" (`tourCareTitle`) | "Log feeds, sleep, diapers with one hand" | Benefits as concrete actions; no mechanism talk ("đồng bộ") |

## 3. Tone checks

- Read it aloud as a tired parent at 3 a.m. Does it ask for more attention than it deserves?
- Would a grandparent understand it without help?
- Would a parent of a premature or ill baby feel judged by it?
- Does the English sound like something a native app writer would ship, not a translation?
