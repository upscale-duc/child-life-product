# Dinh dưỡng theo giai đoạn: review and plan (2026-10-18)

**Sources**
- App, Figma cluster 9 (9a–9g): `440:3934`, `440:3767`, `440:4105`, `440:4217`, `441:3917`, `441:4018`,
  `441:4100`. Extracted in `docs/discovery/figma-extract/20-v11-content-features.md` §9.
- Portal, Figma D01–D04, read 2026-10-18:
  - `442:4354` Giai đoạn list
  - `442:4716` Sửa giai đoạn
  - `442:53582` Vi chất
  - `442:53870` Quy tắc gợi ý

**Owner request (2026-10-18):** "là 1 developer phân tích và triển khai tính năng này … UI/UX là
example … là product owner phân tích flow cho chặt chẽ … sau đó là 1 chuyên gia dinh dưỡng / bác sĩ
soạn nội dung lên portal để app hiển thị". The request brings back the "Dinh dưỡng" tile that D-069
dropped (D-083).

The design is an example. This plan fixes the flows, rules and edge cases the screens leave open. The
choices marked **P-163** are engineering defaults the owner can overturn.

## 1. What the design asks for

**App (Chăm sóc → Dinh dưỡng)**

| Frame | What it is |
|---|---|
| 9a | A **Dinh dưỡng** tile in Chăm sóc with the current stage ("Giai đoạn 6–8 tháng"). |
| 9b | The current stage page: stage card ("Bắt đầu ăn dặm" + one paragraph), "Sữa mỗi ngày" with the 7-day bottle average on a reference band, "Tăng trưởng so với chuẩn WHO" (last weight / length with an in-range tag), "Cần chú ý ở giai đoạn này" (micronutrients), "Một ngày tham khảo", "Gợi ý cho {bé}", source footer. |
| 9c | "Lượng sữa": a 14-day chart of daily bottle amounts against the band, the amounts of every stage (current highlighted), a "talk to a paediatrician" banner, sources. |
| 9d | A micronutrient article (template; iron drawn): why, iron-rich foods, a tip, by age, a "medicine only on prescription" warning, sources. |
| 9e | Growth-based suggestions when the 2 latest weights are below the WHO range: chart, a non-diagnostic banner, 4 tips, "Nhắc đo lại sau 2 tuần", "Xuất báo cáo cho bác sĩ". |
| 9f | Every stage as a timeline (past · current · future). |
| 9g | Vitamin A campaign days (1–2/6, 1–2/12 at the ward health station), taken / upcoming, and a reminder sheet (the day before at 8:00, recipients, add to calendar). |

**Portal (NỘI DUNG → Dinh dưỡng)**
- D01 Giai đoạn: a list with age, title, reference milk, solids, micronutrients, reviewer and status.
- D02 Sửa giai đoạn: general info, milk, solids with a sample day, micronutrients and suggestion cards,
  review, sources. Shows the warning "Không nhập liều thuốc hay vi chất dạng uống".
- D03 Vi chất: a shared library with the stage of focus, foods, medical note and status.
- D04 Quy tắc gợi ý: metric, condition, age, what the app shows, status. Shows the warning "Không dùng
  từ suy dinh dưỡng, béo phì, chậm lớn".
- Statuses: Đang dùng · Chờ duyệt · Nháp. That is the editorial workflow already used by articles,
  stages and milestones.

## 2. Gaps in the design and how this plan closes them (P-163)

| # | Gap | Decision |
|---|---|---|
| 1 | Stage boundaries differ between screens: 9f (0–1, 1–3, 4–5, 6–8, 9–11, 12–23, 24–36), 9c (tuần đầu, 1, 2–5, 6–8 …) and 9d (0–4, 4–6, 6–23). | **One set of stages**, the 9f / D01 one, in completed months: [0,1) [1,4) [4,6) [6,9) [9,12) [12,24) [24,36]. The stage covering the baby's age is "current". Milk tables (9c) list the same stages. Nutrient "by age" rows stay free text, written by the expert. |
| 2 | 9b shows a 600–900 ml band while 180–240 × 4–5 gives 720–1200. | A stage stores **ml per feed**, **feeds per day** and **ml per day** separately. The band uses **ml per day**, as entered by the expert; per-feed and feeds are shown as text. Each is optional (e.g. 0–1 month: no daily band). |
| 3 | Which logs count as "milk". | Feed records with an `amountMl` that are bottle feeds (formula or expressed breast milk). Breastfeeding by duration has no amount and is not counted. The card says "Tham khảo cho bé bú bình" plus the stage's breastfeeding note. |
| 4 | 7-day average with little data. | The average needs **≥ 3 days with bottle amounts** in the last 7 local days. It is the mean of those days' totals, rounded to 10 ml. With fewer days the card shows "Chưa đủ cữ bú bình 7 ngày qua để tính trung bình" and the band without a marker. The marker is clamped to the track. |
| 5 | Copy when the average is outside the band. | A **milk rule** (D04 "Lượng sữa") supplies a gentle line under the card ("Mỗi bé mỗi khác… trao đổi bác sĩ nếu kéo dài"). There is never red or a "too little / too much" judgement. |
| 6 | Growth card target and the 9e trigger. | Last **weight** and **length** with a tag against WHO P3–P97 for the baby's sex and age (existing `who_growth.dart`): "Trong khoảng chuẩn", "Thấp hơn khoảng chuẩn", "Cao hơn khoảng chuẩn". A **growth rule** fires when the **2 latest measurements** of that metric, both in the rule's age range, are on the same side outside P3–P97. When a rule fires, 9b shows a calm banner on top that opens 9e. The growth card opens 9e if a rule fires, else the existing WHO growth screen. |
| 7 | 9e actions. | "Nhắc đo lại sau N ngày" creates a **one-time reminder**, all day, N = the rule's `remindAfterDays` (14 in the design). It is visible to the family (existing reminders, D-075 #5). "Xuất báo cáo cho bác sĩ" opens the share sheet with a **plain-text summary**: the baby's age (no name), the last 4 measurements with their WHO position, the 7-day milk average and the rule's banner. No server call. |
| 8 | Who sees what. | **Cùng nuôi**: everything. **Người chăm sóc**: the tile, stage, milk, nutrients, sample day, tips, stages and vitamin A (read-only). They get no growth card, no growth banner and no 9e (caregivers have no growth tile today). **Người thân**: no Chăm sóc tab, so nothing. Vitamin A "Đã uống" and "Đặt nhắc" are Cùng nuôi only. Caregivers cannot read the date of birth, so their age and stage come from the copy kept on the vaccine plan (`vaccinePlan.scheduleFrom`, P-133). |
| 9 | Missing date of birth, or age past the last stage. | No DOB: the tile subline says "Cần ngày sinh của bé" and the page shows one card linking to the baby profile. Past 36 months: the last stage stays current and the stage card says "Bé đã qua các giai đoạn trong app". |
| 10 | Premature babies. | Out of scope. The footer reminds that a doctor's advice comes first. Corrected age can come later. |
| 11 | When the tile is live. | Like Giai đoạn của bé (D-076): the tile is live once **a published stage covers the baby's age**. Until then it is a "Sớm ra mắt" teaser. The **"Ăn dặm" teaser is removed**, since Dinh dưỡng covers solids by stage. No new feature flag: publishing is the switch, and unpublishing takes it away. |
| 12 | Vitamin A rounds and "Đã uống". | The Vitamin A nutrient carries a structured **campaign**: rounds (month, first day, last day; 1–2/6 and 1–2/12), eligible ages (6–36 months) and the place. The app computes this year's and next year's rounds. Each round is one of: **Đã uống** (recorded), **Sắp tới** (next), **Đã qua** (past and not recorded; neutral grey, never red), **Chưa tới tuổi** (before 6 months). Recording asks for the date (default: the round's first day) and stores it per baby. Undo is allowed. |
| 13 | Vitamin A reminder recipients and calendar. | "Đặt nhắc" creates a **one-time reminder at 08:00 the day before** the round, assigned to the member picked (default: me), visible in Nhắc nhở. "Thêm vào lịch điện thoại" **shares an .ics file** (no calendar permission). Several recipients per reminder is out of scope (the design's "Mẹ, Bố"). |
| 14 | Tapping stages in 9f. | Opens that stage read-only, with the 9b layout minus the personal cards (milk average, growth, banner). |
| 15 | Kẽm / Vitamin D rows not linked in 9b. | Every nutrient opens the 9d template. Vitamin A opens 9g, which links to its 9d article. |
| 16 | Wording and safety. | Copy never says "suy dinh dưỡng", "béo phì", "chậm lớn", "thiếu chất", or gives a dose. The portal **blocks Gửi duyệt** when a field contains those words or a dose pattern (number + mg/IU/UI/mcg), as Nhịp lớn lên does with its forbidden phrases. Every page ends with the D-082 footnote, or the reviewer line once reviewed. |
| 17 | Overlapping stages. | Published stages must not overlap. Approving or publishing a stage whose range overlaps another live stage is refused (`stage-overlap`). The D01 list shows the 0–36-month coverage and any gaps. |

## 3. Content model (portal → app)

All three kinds use the editorial workflow of `content-library.ts`:
- one draft per item in `contentDrafts`;
- Gửi duyệt → Duyệt → Xuất bản;
- the approval policy of D-079;
- the qualified review on prod;
- the review queue.

Published documents go to `contentNutritionStages`, `contentNutrients` and `contentNutritionRules`.
Signed-in members read the published ones (Rules as for `contentStages`). All text is `{vi, en}`.

**NutritionStage** (`nst_…`)
- `ageMonths {from, to}`: whole months, `to` exclusive; the last stage may end at 36 inclusive.
- `title`: e.g. "Bắt đầu ăn dặm".
- `summary`: one paragraph, at most 220 characters.
- `milk`, or null:
  - `perFeedMl {min, max}` | null
  - `feedsPerDay {min, max}` | null
  - `perDayMl {min, max}` | null
  - `breastfeedingNote`
- `solids`, or null:
  - `meals`: e.g. "2–3 bữa"
  - `texture`: e.g. "Bột loãng → cháo rây, nghiền"
- `sampleDay`: up to 8 rows, each `{ slot: morning | noon | afternoon | evening | night, kind: milk | solids | snack | sleep, text }`.
- `nutrientIds`: up to 6, in display order.
- `tips`: up to 4 `{ title, body }`, shown as "Gợi ý cho {bé}" while no growth rule fires.
- `sources`: up to 8 `{ label, url }`.

**Nutrient** (`nut_…`)
- `key`: one of `iron`, `zinc`, `vitaminD`, `vitaminA`, `calcium`, `dha`, `iodine`, `fibre`, `other`. It picks the icon and tint.
- `name`, and `subtitle` (the 9b row line).
- `focus`:
  - `ageMonths {from, to}`
  - `label`: e.g. "Quan trọng từ 6 tháng"
  - `note`: e.g. "4–6 tháng nếu bú mẹ"
- `why`
- `foods`: up to 12 short `{vi, en}` chips.
- `tip`, or null.
- `byAge`: up to 6 rows `{ ageMonths {from, to} | null, label, text }`. The row covering the baby is highlighted.
- `warning`: the medical note, e.g. "Dạng thuốc chỉ theo chỉ định bác sĩ".
- `campaign`, or null:
  - `rounds`: up to 4 `{ month, fromDay, toDay }`
  - `ageMonths {from, to}`
  - `place`
- `sources`

**NutritionRule** (`nru_…`)
- `metric`: `weight` | `length` | `milk` | `measurement`.
- `condition`:
  - `belowRange` | `aboveRange`: the 2 latest in-range measurements, WHO P3 / P97.
  - `milkOutsideStage`: the 7-day average outside the stage band, with ≥ 3 days of data.
  - `noMeasurement`: no weight or length for `days` days (default 30).
- `ageMonths {from, to}`.
- `banner`: the calm sentence. For growth rules it must contain "không phải chẩn đoán".
- `tips`: up to 4 `{ title, body }`.
- `remindAfterDays`: 7–60, or null.
- `export`: whether "Xuất báo cáo cho bác sĩ" shows (growth rules).

**Per-baby state** (written by the app, Cùng nuôi only)
- `babies/{babyId}/nutrition/vitaminA`, as `{ taken: { "2026-06": "2026-06-01" }, updatedAt, updatedBy }`.
- Rules: members of the baby read it; active Cùng nuôi write it; `taken` keys match `^\d{4}-(0[1-9]|1[0-2])$` and values are dates.

**What stays on the device:** rule evaluation and the averages use the baby's own logs on the device.
No child data goes to the server or analytics for this feature.

## 4. App flows (Flutter)

**9a tile**
- Placed in "Chăm hằng ngày", after Tăng trưởng.
- Icon: feed; tint: bottle-soft.
- Subline: "Giai đoạn {label}", "Cần ngày sinh của bé", or the teaser.
- Search matches it like the other tiles.

**9b Dinh dưỡng** (`/care/nutrition`, BabySwitcher at the top). Each section shows only when it has content:
1. Growth banner, if a growth rule fires (Cùng nuôi): sunshine-soft, the rule's banner, "Xem gợi ý" → 9e.
2. Stage card: "{n} tháng · giai đoạn {label}", title, summary, "Xem các giai đoạn" → 9f.
3. Milk card: band from `perDayMl`, marker at the 7-day average (or the "chưa đủ" line), "{bé} trung bình N ml/ngày (7 ngày qua) · {feeds} cữ, {perFeed} ml mỗi cữ. Bú mẹ: {note}", and the milk rule line if it fires. → 9c.
4. Growth card (Cùng nuôi): last weight and length with tags and the date → 9e if a rule fires, else the WHO growth screen. With no measurement it shows "Chưa có lần đo" → add growth.
5. "Cần chú ý ở giai đoạn này": the stage's nutrients. The Vitamin A row shows its next round tag ("1–2/12").
6. "Một ngày tham khảo": slot label and text, icon by kind.
7. "Gợi ý cho {bé}": the stage tips; while a growth rule fires, that rule's tips instead.
8. Footer: the D-082 footnote, then "Thuốc, vi chất dạng uống: theo chỉ định bác sĩ." (the footnote already says it does not replace a doctor). Once an expert signs: the reviewer line, then "Không thay thế tư vấn của bác sĩ. Thuốc, vi chất dạng uống: theo chỉ định bác sĩ."

**9c Lượng sữa**
- 14 local days of bottle totals (0 for days without logs; today highlighted; tap a bar for "dd/mm · N ml").
- The band from the current stage.
- The stages' amounts, current highlighted ("Hiện tại").
- The banner, and the stage's sources.

**9d nutrient:** as drawn. The `byAge` row covering the baby is highlighted. A campaign card links to 9g.

**9e growth suggestions** (Cùng nuôi only)
- Title: "Cân nặng của {bé}" or "Chiều dài của {bé}".
- The existing WHO chart for that metric.
- The rule's banner and tips.
- "Nhắc đo lại sau N ngày": creates the reminder. A toast confirms. If such a reminder is already open, the button says "Đã đặt nhắc · {date}".
- "Xuất báo cáo cho bác sĩ": the share sheet.

**9f Các giai đoạn:** a timeline of the published stages (past · current · future); each card shows the label, the title and the summary clipped to 2 lines. Tapping one opens it read-only.

**9g Vitamin A**
- Eligibility line, then this year's and next year's rounds with their state.
- Tapping a round (Cùng nuôi) gives "Đánh dấu đã uống" or "Bỏ đánh dấu".
- "Đặt nhắc" sheet: "Nhắc trước 1 ngày, lúc 8:00 {date}", Người nhận (one member, default me), "Thêm vào lịch" (.ics share, on by default as in Figma), then "Đặt nhắc". If 08:00 the day before has passed, it rings at 08:00 on the round's first day.
- Before 6 months: "Bé sẽ được uống từ 6 tháng tuổi" and the first eligible round.

**Data**
- Published content: Firestore listeners on the three collections (offline cache; a family that opened it once still sees it offline).
- Logs and growth come from the existing care repositories.
- l10n: every string in the ARB files (vi template + en, D-012).

## 5. Portal (React)

**Navigation:** NỘI DUNG → **Dinh dưỡng** (`/nutrition`), with tabs Giai đoạn · Vi chất · Quy tắc gợi ý. Built on the content kit like Bài viết / Giai đoạn / Mốc.

**D01 Giai đoạn**
- Stat tiles.
- Coverage strip over 0–36 months.
- Table: age, title, milk, solids, nutrient tags, reviewer and date, status.
- "Thêm giai đoạn".

**D02 editor**
- Sticky editor bar: Lưu nháp · Gửi duyệt · Duyệt · Xuất bản.
- Sections: Thông tin chung · Sữa · Ăn dặm & một ngày tham khảo · Vi chất & gợi ý · Nguồn & duyệt.
- Phone preview of 9b.
- The "Không nhập liều thuốc" notice.

**D03 Vi chất:** a list and an editor (focus, foods chips, why, tip, by age, warning, campaign rounds, sources) with a 9d preview.

**D04 Quy tắc gợi ý:** a list and an editor (metric, condition, age, banner, tips, reminder days, export) with a 9e banner preview. It shows the forbidden-words notice.

**Workflow and checks**
- The review queue (Duyệt nội dung) lists the three new kinds.
- Forbidden words and dose patterns block Gửi duyệt, with a message naming the field.
- Stage overlap blocks publishing.
- "Nhập bản nháp mẫu" imports the expert drafts (§7).

## 6. Analytics (no child data)

- `nutrition_opened {stageId}`
- `nutrition_nutrient_opened {nutrientKey}`
- `nutrition_rule_shown {ruleId}`
- `nutrition_remeasure_reminder_set`
- `vitamin_a_marked`
- `vitamin_a_reminder_set`

No ages, weights or names. The app has no analytics SDK yet: the events are wired when it lands.

## 7. Content (expert drafts)

Written by engineering in the role of a paediatric nutrition expert, from WHO, the Vietnamese Ministry
of Health / Viện Dinh dưỡng, AAP and NHS guidance:
- **7 stages**, 0–36 months.
- **7 nutrients**: Sắt, Kẽm, Vitamin D, Vitamin A (with the national campaign rounds), Canxi, DHA, I-ốt.
- **5 rules**:
  - weight below range;
  - weight above range;
  - length below range;
  - milk outside the band;
  - no measurement in 30 days.

They go in as drafts ("Nhập bản nháp mẫu") and follow the approval policy. On prod they need the
qualified review before they go live. `firebase/functions/scripts/content-release.ts` carries the three
kinds (`--only nutritionStages,nutrients,nutritionRules`) in `seeds`, `export`, `import` and `publish`.

## 8. Acceptance (QA seeds)

1. A 7-month baby with DOB: the tile reads "Giai đoạn 6–8 tháng" and 9b shows the 6–8 stage.
2. Fewer than 3 bottle days in 7: no marker, the "chưa đủ" line. 5 days averaging 718 ml: the marker at 720.
3. A 7-day average of 1,000 ml with a 600–900 band: the milk rule line, no red.
4. Two latest weights under P3: the banner on 9b, 9e with tips. Re-measure creates an all-day reminder in 14 days; pressing again shows "Đã đặt nhắc".
5. One low weight followed by one normal: no banner.
6. A caregiver: no growth card, no banner, no 9e; vitamin A is read-only.
7. No DOB: the tile says "Cần ngày sinh"; 9b shows one card.
8. Vitamin A for a 7-month baby on 18/10/2026:
   - next round 1–2/12;
   - June 2026 shows "Chưa tới tuổi" if the baby was under 6 months then;
   - mark taken → "Đã uống dd/mm";
   - set reminder → a reminder at 08:00 on 30/11.
9. A baby past 36 months: the last stage, with "đã qua các giai đoạn".
10. Portal:
    - a stage with "50 mg" in the summary cannot be sent for review;
    - two overlapping stages cannot both go live;
    - the review queue lists nutrition items;
    - unpublishing a stage turns the tile back into a teaser when no stage covers the age.
11. English UI and Night care render every screen.
