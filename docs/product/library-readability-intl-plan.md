# Library readability, thumbnails and families abroad: review and plan (2026-10-19)

**Owner request (D-087):** "cải thiện cách hiển thị nội dung của mấy bài viết trong mục ăn dặm (vì
chữ dài nên cần cải thiện ui/ux để dễ đọc hơn); thumbnail hiện tại đang bị lặp lại; đã support đa
quốc gia chưa, nội dung bài viết còn một số gọi 115; review tất cả." The choices marked **P-166**
are engineering defaults the owner can overturn.

## 1. Review findings

**Readability (4d reader, shared by both libraries).** The body is 16 pt with line height 1.6 and
"Aa" scales it, but:
- solids guides run 4–6 minutes (900–1,300 words), with paragraphs up to about 600 characters;
- there is no table of contents, no reading progress and no way back to the top;
- "Hiểu lầm thường gặp" bullets pack three ideas into one line ("A → B → C");
- step guides are plain bullets ("Bước 3 · …") with no numbering;
- the emergency advice ("Gọi 115 ngay khi…") is an ordinary yellow doctor callout near the end, with
  no call button;
- on a tablet, lines run the full width.

**Thumbnails.** Every solids guide has `topic: 'feeding'` and no cover, so every row shows the same
bottle on blue. Recipes show the same bottle too. The icon set has no food icons.

**Families abroad.** D-078 already gives Sơ cứu, Nhịp lớn lên's health pack and the Ăn dặm meal
sheet the family's number (30 countries, `emergencyNumbers`), and D-084 gives six countries their
vaccine schedule. The editorial content does not follow:
- "115" is written into 199 places: care guides 136, solids guides 53, recipes 7, reference
  milestones 2, plus one article title ("…khi nào gọi 115");
- "trạm y tế" (a Vietnamese commune health station) appears in 4 care guides as the place to go;
- Dinh dưỡng's vitamin A rounds are Việt Nam's national campaign, but they show for every family;
- the portal neither hints at nor checks the token, and its previews show raw text.

App interface strings carry no hard-coded "115".

## 2. Decisions (P-166)

| # | Topic | Decision |
|---|---|---|
| 1 | Emergency number in content | Content writes `{emergency}`. The app fills in the family's country number from `emergencyNumbers`, or 115 when no country or number is known. This applies to titles, summaries, blocks, recipes and milestones, and the portal preview shows "115". Titles say "gọi cấp cứu" rather than a number. `literalEmergencyProblems` warns in the portal and fails the seed tests. |
| 2 | Urgent callout | A new callout tone `urgent` (red, alert icon) is used for "Gọi {emergency} ngay khi…". It has a full-width "Gọi {number}" button that dials the family's number, plus "Sơ cứu" when a matching first-aid page exists. Older app builds show it as a doctor callout. |
| 3 | Reader | Changes to the 4d reader: (a) a "Trong bài này" contents card built from the headings, where tapping scrolls to the heading; (b) a thin reading-progress bar under the top bar, and a "Lên đầu" button after one screen; (c) the first `note` callout styled as a key-takeaways card ("Tóm tắt nhanh", mint, check icon); (d) myth bullets "A → B → C" shown as a small card with the labels Hiểu lầm / Vì sao / Nên làm; (e) step guides shown as numbered steps (lines that start "Bước N ·"), with the lead-in before ":" in semibold; (f) 24 pt above headings, 14 pt between paragraphs, a mint accent bar on headings, lines capped at 640 pt wide; (g) related guides and "Bài tiếp theo" in the same library at the end. Nothing changes for screen readers except the new headings and buttons. |
| 4 | Content length | Paragraphs of at most about 450 characters (split, not cut). Enumerations become bullets. The seed tests enforce the paragraph cap on the solids guides. |
| 5 | Thumbnails | Eleven new line icons in the Figma line style (24 × 24, stroke 1.8, `currentColor`): bowl, spoon, carrot, apple, fish, egg, cup, high chair, shield, hand, calendar. Solids guides get a `subtopic`, each with its own icon and tint. Recipes take theirs from the main ingredient's group (vegetable, fruit, animal protein, legumes, dairy, grain), falling back to the texture. A cover image still wins when staff upload one. |
| 6 | Vitamin A outside Việt Nam | Families whose country is not VN see vitamin A as an ordinary nutrient article. The campaign rounds, 9g, the "1–2/12" tag and the reminder are hidden, and a note says "Lịch uống vitamin A theo chương trình của Việt Nam; ở nơi bạn sống, hãy hỏi bác sĩ của bé." |
| 7 | "Trạm y tế" | The care guides say "trạm y tế hoặc phòng khám gần nhà" ("a local clinic" in English). Text that is about Việt Nam's own programmes keeps the term. |
| 8 | Republishing | The changed content goes to dev as new revisions (import → publish, `--only articles,recipes,milestones`). An app build older than this release would show "{emergency}" as text. Dev has no such users, but prod must ship the app first and the content after. |
