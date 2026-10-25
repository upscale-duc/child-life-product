---
name: senior-ui-ux
description: Work as a senior UI/UX designer before writing UI code in Child Life (mobile app, portal, landing). Use whenever a screen, card, sheet, notification copy, empty/error state or any user-facing number is added, changed or "improved", and whenever the owner reports that a screen is hard to read, confusing or "không tốt". Covers the user's job, information hierarchy, turning numbers into visuals, Vietnamese copy, states, the Cl design system, mockup-before-code and visual verification.
---

# Senior UI/UX pass (Child Life)

The owner's feedback (2026-10-25): screens changed "như software developer" read badly — walls of
text, numbers in sentences, duplicated blocks, chips that contradict each other, labels that mean
something else. Every UI change goes through this pass **before** code, and is checked **as an
image** after.

## 1. Who, when, what job (write it down first)
- Who opens this screen (Cùng nuôi, Người chăm sóc, Người thân; a tired parent at 3 a.m., a
  grandparent taking over) and in what moment.
- The one question it must answer in **5 seconds**, and the next two in 30 seconds. Everything
  else is secondary or goes behind a tap.
- What they do next (one primary action, at most one secondary). A button's label names where it
  goes; its destination matches the card it sits on ("Xem chi tiết" on a weekly card opens the
  week, not today).
- Role-aware: never show the reader a state that belongs to someone else (a sender's "Mình sẽ
  thử", "Đã nhận bàn giao" to the person who gave it).

## 2. Audit what is there (look, don't read code)
- Render the current screen: golden test or simulator screenshot, **vi**, Light and Night care,
  with realistic data (not empty fixtures). Read the image like the user would.
- List problems as the user would say them. Usual suspects in this app:
  - a paragraph where a list or a number belongs; the same facts twice (a sentence and rows);
  - raw formats: `2026-10-23`, `YYYY-MM-DD: …; …`, minutes without unit, ids;
  - two states at once that read as a contradiction ("Có ích" + "Mình sẽ thử");
  - engineering words ("bản ghi", "đối soát", "quan sát", "intent", "hoàn tất nhắc việc không
    tự tạo bản ghi");
  - dates without times where time matters; old data presented as current;
  - an empty section that still takes space; a section title that does not say what is in it;
  - too many sizes/weights of text competing; long screens with no anchor.

## 3. Hierarchy
- One hero per screen (the answer to the 5-second question), then 2–4 sections max, each with a
  plain heading that says what is inside ("Bé lúc này", "Sắp tới", "Cần lưu ý").
- Order by urgency for the reader, not by how the data is stored.
- Group, don't list: rows in one `ClCardGroup`, not one card per row. Hide empty sections or give
  them one short muted line.
- Progressive disclosure: history, AI summaries, explanations go below or behind a tap.

## 4. Numbers become visuals
Never put two or more numbers in a sentence. Pick the form by the question:
- **How many / how much** → stat tile: big tabular number (`ClTabularText`), short label under it,
  unit attached ("120 ml", "9 giờ 40 phút"). 2–3 tiles in a row, one highlighted at most.
- **Compared with usual** → number + the usual range or a small delta ("Đêm qua 9 giờ · thường
  8–9 giờ"), or a bar against the range; say which is better only when it is clinically safe.
- **When** → relative first, clock second ("2 giờ trước · 07:30"); an ongoing state with its
  start and duration ("Đang ngủ · từ 21:27 · 10 giờ"). Dates as `24/10`, today/yesterday as
  "Hôm nay"/"Hôm qua".
- **Over a day** → a 24 h timeline strip (sleep blocks, feed and diaper ticks) beats a list.
- **Over a week** → 7 small bars or dots, not a sentence of counts.
- **Progress / next** → "Cữ tới khoảng 10:30" with a soft progress bar since the last feed.
- Overdue or attention states use the warm palette (sunshine/peach soft + `colors.ink`), danger
  only for real danger. Colour never carries meaning alone: icon + text too.

## 5. Copy (Vietnamese first; Figma copy is the source when it exists)
- The parent's words, short, warm, no blame: "Bé đã làm được", "Thử lại lần nữa", "Ảnh mới đã
  được xử lý rồi". Avoid "quan sát", "bản ghi", "đối soát", "thực thể", "xác nhận" when a plain
  verb works.
- Labels are states from the reader's point of view; buttons are verbs (1–3 words).
- Every user-facing string goes through ARB (vi template, en with the same ids).
- Copy that differs from Figma is an owner decision: record it in `docs/product/business-map.md`.

## 6. States
Design and render each: loading (skeleton shaped like the content), empty (an invitation, not an
apology), error/offline (what happened + what to do), partial data, health day (the free health
route, no AI text), no permission (role), first run. Long names, 3+ babies, en strings.

## 7. Build with the design system
- `Cl*` widgets and `context.cl` tokens only; spacing `ClSpace`, radius `ClRadius`; icons from
  `ClIcons` (enum, check the name exists).
- Night care: text on `sunshineSoft`/`peachSoft` uses `colors.ink`, never `onWarm`.
- Tabular numbers for anything that changes; minimum tap target 44 pt; semantics labels that read
  the whole tile ("Bú, 120 ml, 2 giờ trước").

## 8. Mockup before code (for anything bigger than a label)
- Check Figma `sJLG1fAXKDnDr9YI6Yx8ex` (read-only, saved extraction in
  `docs/discovery/figma-extract/`) for the screen or the nearest pattern.
- No design: show the owner a mockup first (an inline visual or an HTML artifact) with realistic
  Vietnamese data, plus 3–5 bullets of rationale. Build after the OK.

## 9. Verify as an image
- Golden tests in Light + Night care × vi + en with realistic fixtures; open the new PNGs and look
  at them before committing. Compare before/after.
- Run the checklist in §2 against the new image. If any item still applies, iterate.
- Report to the owner with the image (before → after), not only a description.
