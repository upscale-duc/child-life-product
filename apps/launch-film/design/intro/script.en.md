# Script: English voice-over (rev 2)

Target length is about 90 seconds including pauses. All timings are **estimates** until a voice-over is recorded. Do not speed up the read to hit these marks; re-time the picture to the recording instead.

- **LOCKED** lines are from the original brief.
- **PROPOSED** lines are new in rev 2. They add the vision and the features from dev.childlife.app, and they replace the "in sync" claim. They need sign-off before recording.

## Reading direction

- **Voice:** natural, warm English, like a thoughtful parent talking to a friend. It is not an announcer. Mid-low pitch, clear articulation, a light smile on the warm lines.
- **Pace:** about 130–140 words per minute.

  | Scenes | Pace and feel |
  |---|---|
  | PI01 | Calm and open, like a promise |
  | PI02–03 | Slightly quicker and busier |
  | PI04 | Slows right down |
  | PI05–08 | Steady and practical |
  | PI09–10 | Warm and unhurried |
- **Avoid:** sales emphasis, upward inflection on every line, leaning hard on "Child Life", and reading the feature names in PI06 like a list.
- **Pauses:** `[0.3s]` is a breath, `[0.6s]` a clear pause, `[0.8s]` a held pause.
- **Takes:** record two of every line, one as written and one a little softer.

## Script

| ID | Est. time | Status | Line | Direction |
|---|---|---|---|---|
| PI01 | 00–08 | PROPOSED | Every child grows up one moment at a time. [0.4s] Child Life is here to walk alongside your family — [0.3s] starting with the very first year. | Open and calm, like a promise. "starting with the very first year" is honest and gentle, not a disclaimer. |
| PI02 | 08–14 | LOCKED | Life with a little one is full of firsts. [0.4s] And a lot to keep track of. | Smile on "firsts". The second sentence is lighter, like a knowing laugh. |
| PI03 | 14–23 | LOCKED | The last feed. [0.3s] The next nap. [0.3s] The little updates you share so everyone knows how the day is going. | Lists the mental load. Short and crisp, without sounding stressed. |
| PI04 | 23–30 | LOCKED | And somewhere between it all, [0.4s] another first happens. [0.5s] A smile. [0.3s] A sound. [0.4s] A moment you want to remember. | Slow down clearly. "A smile. A sound." is close to the mic, nearly a whisper. |
| PI05 | 30–37 | LOCKED | [0.6s] Meet Child Life. [0.4s] A shared space for caring for your child, and keeping their story close. | Fresh, calm and sure. |
| PI06 | 37–47 | PROPOSED | Log a feed in a tap — [0.2s] from a home-screen widget, your Apple Watch, or just by asking Siri. [0.4s] So whoever looks after your little one next can pick up where you left off. | Practical and light. The three devices flow as one breath, not a list. |
| PI07 | 47–58 | PROPOSED | Or just tell Lumi what happened — [0.2s] it drafts the log for you to check. [0.5s] And each day brings ideas that fit your child's age, [0.2s] with reminders right when they matter. | Reassuring. Stress "for you to check": the parent stays in control. |
| PI08 | 58–66 | LOCKED | Follow the little changes. [0.3s] Celebrate the firsts. [0.3s] And bring your family along as your child grows. | Brighter, with rising warmth. |
| PI09 | 66–78 | LOCKED | Turn everyday photos into keepsakes you can return to— [0.4s] because the days you're living now [0.3s] are the memories you'll treasure later. | The emotional peak. Slow down on "treasure later". |
| PI10 | 78–90 | LOCKED | [0.5s] Less to keep track of. [0.6s] More to hold on to. [0.8s] Child Life. [0.3s] Growing together, every step of the way. | The concept line is light. The brand name is said simply; the tagline closes softly. |

The original brief line "Keep everyday care in sync…" is replaced by PI06. See the next section.

## Product claims checked

Each claim was checked against the Figma file, the project docs, dev.childlife.app, and the app screenshot you sent.

| Line | Claim | Evidence | Status / proposal |
|---|---|---|---|
| PI01 | "walk alongside your family — starting with the very first year" | Website: "Đồng hành cùng con khôn lớn". Stages 0–12 months "Đang có trong app", 1–3 years "Chặng tiếp theo", 3–6 and 6–12 years "Trong tương lai". | ✓ The wording only promises the first year. On screen, stages 2–4 are labeled "Coming next" or "In the future". |
| PI02–03 | Problem framing | Not a product promise | ✓ |
| PI05 | "A shared space…" | Family invites and roles (14a–14e), shared log, Kỷ niệm (memories) | ✓ |
| PI06 | "Log a feed in a tap — widget, Apple Watch, Siri" | Widget W1 (76:5441), Apple Watch W01 (475:4588). Website: "Một chạm trên đồng hồ, widget, nút điều khiển iOS — hoặc nói với Siri". | ⚠ **CONFIRM Siri** (Siri/App Intents) is in the release. If not, use: "…from a home-screen widget or your Apple Watch". Wear OS is "sắp có" (coming soon), so it is left out. |
| PI06 | "pick up where you left off" | The "Bàn giao cho người chăm tiếp" handoff card is in the real-app screenshot. SU01 handoff screen exists. | ⚠ **CONFIRM** it ships in the release build. The v1.1 handoff note still says "Dev to confirm". |
| PI06 (removed) | "Keep everyday care in sync" | No spec confirms real-time sync. | ✗ Replaced by the PI06 line above. |
| PI07 | "tell Lumi… it drafts the log for you to check" | CH04: one message → 2 drafts → "Lưu 2 mục đã chọn" (save 2 selected). Rule: "AI đề xuất… Xem trước + xác nhận trước khi ghi" (AI proposes; preview and confirm before writing). | ✓ Accurate. Do not imply Lumi saves on its own. Lumi has a free monthly quota, so avoid "unlimited". |
| PI07 | "ideas that fit your child's age, with reminders" | Today screen: "Dành cho bé hôm nay", "Để ý tuần này", reminders. Website: "Gợi ý & nhắc lịch đúng tuổi". | ✓ This is not medical advice. |
| PI08 | Growth, milestones, family | 20d growth chart (WHO band hidden), 3a–3g milestones, family album | ✓ |
| PI09 | "Turn everyday photos into keepsakes" | MM10–MM12 cards, MM04–MM09 videos | ⚠ **CONFIRM free tier.** Some templates are Premium or have an export quota. Fallback: "cards and videos you can return to". |
| PI10 | Tagline | Brand vision | ✓ Paired with the closing card "Coming soon to iPhone & Android". |

The film does **not** show any of the following:

- notifications or real-time status
- chat typing animations
- a health assessment on the growth chart
- store badges
- pricing or a paywall
