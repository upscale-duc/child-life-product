# 08 · Content & UX writing strategy

Proposed copy below is a draft for the cl-ux-writing review. Vietnamese is the source (D-104, D-012); English is written for meaning, not translated word by word. Glossary changes are L3 (canonical terms) and need the owner.

## 1. Audit summary

| Criterion | Finding | Example |
|---|---|---|
| Age relevance | Cross-age surfaces use infant terms | en "Choose baby", "Baby profiles", "Relation to baby"; vi "Chọn bé", "Hồ sơ các bé" |
| Context relevance | First-year framing at entry | `welcomeBody` "… bắt đầu từ năm đầu đời", `welcomeExplore` "Bắt đầu chặng đầu cùng con" |
| Clarity | Good after D-110 / D-117 / D-118 removals | — |
| Emotional tone | Restrained and warm; band sub-lines are good | `axSub36` "Lưu lại một khoảnh khắc nhỏ — mai này sẽ thành câu chuyện lớn." |
| Actionability | Good; one primary action (D-105) | — |
| Reading effort | Low on Today; higher in content (rhythm, library) | — |
| Localization | Same ids in vi/en (enforced); en "baby" appears in 282 strings vs vi "bé" in about 300 | ARB count, this audit |
| Repetition | Two personalization asks (AXA-02) | "Hôm nay theo cách của nhà bạn" + goals |
| Overclaim | `axSub612` "Những ngày đi học, những chuyến đi, những điều con tự hào." is a memory prompt, fine; avoid implying school features exist | — |

## 2. Terminology rules (proposal)

| Context | Vietnamese | English | Rule |
|---|---|---|---|
| Cross-age surfaces (profile, family, switcher, invites, Kỷ niệm) | **Tên con**, "con"; generic "các con" / "hồ sơ của con" | **Child's name**; "child", "children", "your child" | Prefer the name; never "baby" in English here |
| Infant care surfaces (Ghi nhanh, Bú, Tã, Nhịp lớn lên, Ăn dặm) | "bé" stays | "baby" stays | Matches the moment |
| Band-neutral content | "con" | "your child" | Default |
| Ages | "{n} tháng tuổi" < 24 m, "{n} tuổi" after (current `babyAge`) | "{n} months old", "{n} years old" | Keep |
| Developmental content | "thường", "nhiều trẻ", "có thể" | "often", "many children", "may" | Never "should", "phải", "chắc chắn" (rhythm test already enforces "chắc chắn"/"will") |

Vietnamese note: "bé" is affectionate and fine to ~5 years; "con" works for every age and is what parents say. Changing the stored term "Hồ sơ bé" is L3 because it is canonical across app, portal and pushes (D-094 `baby_name` placeholder keeps working).

## 3. Sample bilingual content matrix (five representative ages)

| Slot | Newborn (3 w) | 8 months | 2 years | 5 years | 9 years |
|---|---|---|---|---|---|
| Greeting (vi) | Chào buổi sáng, Teddy ☀️ | Chào buổi sáng, Mây ☀️ | Chào buổi sáng, Bơ ☀️ | Hôm nay của Na thế nào? | Cùng lưu lại hành trình của Bin |
| Greeting (en) | Good morning, Teddy ☀️ | Good morning, Mây ☀️ | Good morning, Bơ ☀️ | How is Na's day going? | Keep Bin's story going |
| Sub-line (vi) | Nhịp hôm nay của con, ghi nhanh trong một chạm. | *(same)* | Hôm nay con lại khám phá thêm điều mới. | Lưu lại một khoảnh khắc nhỏ — mai này sẽ thành câu chuyện lớn. | Những chuyến đi, những điều con tự hào. *(proposal: drop "ngày đi học" until school features exist)* |
| Sub-line (en) | Today's rhythm, one tap to log. | *(same)* | Something new to discover today. | Save a small moment — it becomes a story later. | Trips, and the things Bin is proud of. |
| Empty memories (vi) | Lưu khoảnh khắc đầu tiên của Teddy | Lưu khoảnh khắc của Mây hôm nay | Bước đi đầu, câu nói đầu — lưu lại nhé | Một bức vẽ, một buổi diễn — lưu lại nhé | Một chuyến đi, một giải thưởng — lưu lại nhé |
| Empty memories (en) | Save Teddy's first moment | Save a moment of Mây today | First steps, first words — keep them | A drawing, a show — keep it | A trip, an award — keep it |
| Content end state (vi) | — | — | Nội dung cho {tuổi} đang được chuẩn bị. Bạn vẫn lưu được "lần đầu" của Bơ. | *(same pattern)* | *(same pattern)* |
| Content end state (en) | — | — | Content for {age} is on its way. You can still save Bơ's firsts. | | |
| Reminder suggestion (vi) | Nhắc cữ bú tiếp | Nhắc mũi tiêm 9 tháng | Nhắc khám răng | Nhắc đóng học phí | Nhắc lịch học thêm |
| Reminder suggestion (en) | Next feed | 9-month vaccine | Dentist check | School fees due | Extra class |
| Birthday moment (vi) | — | — | Bơ tròn 2 tuổi. Làm video một năm qua? | Na tròn 5 tuổi. Xem lại một năm của Na? | Bin tròn 9 tuổi. Bin của năm nay và ngày đầu tiên? |
| Birthday moment (en) | — | — | Bơ turns 2. Make a video of the year? | Na turns 5. Look back at Na's year? | Bin turns 9. This year's Bin, next to day one? |
| Push (vi) | Đến giờ bú của Teddy theo nhắc bạn đặt | — | — | Năm ngoái lúc này: 12 ảnh của Na | — |

The 9-year Then & Now line and yearly items depend on features in [10](10-memories-across-childhood.md); do not ship the copy before the feature.

## 4. Localization rules

1. Same id, same meaning, independent phrasing; English may be shorter.
2. Names are placeholders, never concatenated; Vietnamese word order differs ("Video một năm của {tên}" vs "{name}'s year").
3. Plurals via ICU in English; Vietnamese uses counts without plural forms.
4. Emoji only in greetings that already use them (☀️, 🌙); none in content.
5. No age norms in UI copy; content items cite sources and carry review state.
6. Every new string: vi + en in the same change; English marked for owner review.
