# Ăn dặm: product review and plan (2026-10-18)

**Sources**
- App, Figma cluster 5 (5a–5h):
  - `313:1681` Bật theo dõi ăn dặm
  - `313:1746` Nhật ký
  - `313:1872` Ghi bữa ăn
  - `314:1786` Lịch sử bữa ăn
  - `314:1901` Món đã thử
  - `314:1987` Thư viện ăn dặm
  - `314:2095` Bài ăn dặm (công thức)
  - `314:2169` Hôm nay · thẻ ăn dặm

  Extracted in `docs/discovery/figma-extract/20-v11-content-features.md` §5 (frame notes, implied
  data model, 16 open questions).
- Related, already built: Dinh dưỡng theo giai đoạn (D-083, `docs/product/nutrition-plan.md`), the
  article library with `library: 'solids'` (D-073, D-080), Sơ cứu TH05 Sốc phản vệ, the Today
  customise sheet (A2) and the personalization principles (D-072, `packages/contracts/src/personalization.ts`).

**Owner request (2026-10-18):** "phân tích để làm tính năng ăn dặm này trên portal và mobile app
… với tư cách là product owner / product manager. Nên có tính năng cá nhân hoá để gợi ý ăn dặm cho
bé (khi đủ tuổi ăn dặm). Sau đó bạn là chuyên gia chăm sóc em bé, tạo ra những bài viết về ăn dặm
để làm thành thư viện ăn dặm." Recorded as **D-085**. The choices marked **P-164** are product
defaults the owner can overturn.

**Owner answers (2026-10-18, D-085):** (1) personalization is **free**; (2) meal **photos are
allowed**; (3) meals **appear in Lịch sử, Thống kê and the care export**; (4) tracking starts **from 6
months only**.

The design is an example. This plan fixes the flows, rules, safety cases and the personalization
the screens leave open.

## 1. Where we start

**The design (5a–5h).** A per-baby opt-in (5a). A diary with a week strip, today's meals and the foods
tried (5b). A meal sheet: slot, time, dish, ingredients with a "lần đầu" marker, amount and how the
baby took it (5c). Meal history (5d) and foods tried by group (5e). A library of guides and recipes
filtered by age and method (5f). A recipe page with "Ghi vào nhật ký" (5g). A Today card (5h).

**What the code already has**
- The article model has `library: 'care' | 'solids'`. Seven solids articles are seeded, but **the app
  shows only `care` articles** (`library_screens.dart`, `library_today.dart`), so nobody can read them
  today.
- Dinh dưỡng (D-083) gives each stage `solids.meals` and `solids.texture`, a sample day, iron focus and
  tips. It removed the "Ăn dặm" teaser tile (P-163 #11); the solids diary brings a real tile back.
- Care records (`babies/{b}/records`), the offline outbox pattern, soft delete and the 30-day bin.
- The baby purge deletes every subcollection (`account.ts`, `listCollections`), so new per-baby
  collections are purged with the baby.

**What the design misses** (extraction §5, 16 questions): allergy or symptom recording, an age gate,
roles, a food catalogue for "lần đầu" and groups, recipe quantities and texture, and any suggestion
of what to offer next. Section 3 closes each one.

## 2. Product goals

**Problem.** Vietnamese parents start solids with conflicting advice (bột từ 4 tháng, cháo rây,
kiêng tôm cá, ép ăn), worry about allergies and choking, and forget what the baby has already tried
and how it went. Grandparents and nannies feed the baby too.

**Goals**
1. One place to log a meal in under 15 seconds, shared by everyone who feeds the baby.
2. A trustworthy library (guides and recipes) for the baby's age, written from WHO, Bộ Y tế / Viện
   Dinh dưỡng, AAP, NHS and ASCIA guidance.
3. **Personal suggestions** once the baby is old enough: what to offer next, which common allergens
   to introduce and keep up, iron-rich foods, recipes built from foods the baby already likes.
4. Safety: a clear path when something goes wrong after a food (symptoms → doctor, or 115).

**Non-goals (V1):** meal plans to buy, calorie or nutrient counting, portion targets, a diagnosis of
allergy, premature corrected age, a shopping list.

**Success measures** (counts only, no child data)
- 40% of families with a baby aged 6–12 months turn tracking on within 30 days of the release.
- Of those, 60% log at least 3 meals in their first week.
- 30% of suggestion cards get an action ("Ghi bữa", "Xem công thức").
- Library: at least 3 solids articles or recipes opened per active solids family per month.

## 3. Gaps and decisions (P-164)

| # | Gap | Decision |
|---|---|---|
| 1 | Entry point and IA (5a has none; 8a lists "Ăn dặm" as coming soon). | A live **"Ăn dặm"** tile in Chăm sóc › "Chăm hằng ngày", after Dinh dưỡng. Before tracking is on it opens 5a; after, 5b. Dinh dưỡng 9b gets a link row "Ăn dặm hôm nay · N bữa · Mở nhật ký" while tracking is on. The quick-log chooser (+) gets "Ăn dặm" while tracking is on. The 5h Today card follows the 5a toggle and the A2 row. |
| 2 | Age gate (5a has none). | **Owner: from 6 months only (D-085 #4).** Age in completed months from the date of birth (caregivers: `vaccinePlan.scheduleFrom`, P-133). **Under 6 months**: the tile says "Từ 6 tháng" (from 4 months: "Sắp đến lúc ăn dặm"); 5a shows "Chưa đến lúc ăn dặm" with the readiness guide, the library, and "Nhắc tôi khi bé gần 6 tháng" (a one-time reminder at 5 months 2 weeks); tracking cannot start. **From 6 months**: tracking starts. A family whose doctor advised an earlier start is told to follow the doctor and use the library; the diary opens at 6 months. No date of birth: "Cần ngày sinh của bé" (Cùng nuôi can add it). |
| 3 | What is per baby (5a). | `babies/{b}/solids/settings`: `enabled`, `startedOn` (the first meal's date, editable), `showOnToday`, `method` (`spoon` Truyền thống · `blw` · `mixed` Kết hợp; default `mixed`, asked once in 5a as an optional chip row), `hidden` (foods the family does not want suggested), `updatedAt`, `updatedBy`. Written by Cùng nuôi only. |
| 4 | Meal storage. | A new per-baby collection `babies/{b}/meals/{id}`, written by the app like care records: client ids, the Firestore cache as the offline outbox, soft delete with undo and the 30-day bin. **Owner: meals appear in Lịch sử, Thống kê and the care export (D-085 #3)**: Lịch sử gets an "Ăn dặm" filter and rows, Thống kê a "Bữa ăn dặm" card (meals per day, new foods per week), and the care export a meals sheet. They read the `meals` collection, so the care record types stay as they are. |
| 5 | Meal fields (5c). | `occurredAt`; `slot` (Sáng · Trưa · Chiều · Tối · Phụ, preselected from the time, editable); `dish` (free text, optional when ingredients are set); `ingredients` (catalogue ids, plus up to 3 free-text names); `amount` (Vài thìa · ½ chén · 1 chén · Tự nhập = number + unit thìa / chén / ml / g); `reaction` (Thích · Bình thường · Chưa hợp); `symptoms` (#6); `note` (≤ 300); `recipeId` (from 5g); `createdBy`; **`photo`** (owner: allowed, D-085 #2): one photo per meal, taken or picked in 5c, stored like Kỷ niệm media (family storage quota, upload queue, private to the baby's members, removed with the meal after the bin), shown as the 5b/5d thumbnail; without a photo the card shows the ingredient icon. |
| 6 | **Allergy and symptoms** (the design has none). | 5c gets "Có dấu hiệu bất thường sau khi ăn?" → chips: Nổi mẩn, mề đay · Nôn · Tiêu chảy · Quấy khóc bất thường · Sưng môi, mặt · Khó thở, ho, khò khè · Khác. Choosing **Sưng môi, mặt** or **Khó thở** shows a red card at once: "Gọi 115 ngay nếu bé khó thở, sưng môi hoặc lưỡi, lả đi" with "Gọi 115" and "Sơ cứu: Sốc phản vệ" (TH05), before saving. Any symptom marks the meal's new foods "Có dấu hiệu sau khi ăn" in 5e and keeps them out of suggestions until a Cùng nuôi taps "Bác sĩ đã cho ăn lại". The app never says "dị ứng" as a fact; it says "có dấu hiệu sau khi ăn" and points to a doctor. |
| 7 | "Lần đầu", groups and counts (5b/5c/5e). | Computed on the device from the meals: a catalogue food not in any earlier meal is "lần đầu". Free-text ingredients count as tried but sit in group "Khác" and are never suggested. Counts come from the data, so 5b and 5e always agree (extraction Q4). 5e shows, per food: first tried, times, the **latest** reaction (Q3), and a "Có dấu hiệu" tag if any meal with it had symptoms. |
| 8 | Food catalogue (portal). | A new editorial kind **`food`** (`fd_…`), about 120 common Vietnamese baby foods: name and synonyms (vi/en), `group` (Rau củ · Trái cây · Tinh bột · Đạm động vật · Đậu và hạt · Sữa và chế phẩm · Chất béo), `allergen` (egg · peanut · milk · wheat · soy · fish · shellfish · sesame · treeNut · none), `ironRich`, `minAgeMonths` (honey 12; cow's milk as a drink 12), `prep` per texture stage (e.g. "Nho: cắt dọc làm tư"), `chokingNote`, `suggest` (whether the engine may propose it) and `priority`. |
| 9 | Recipes are thin (5g). | A new editorial kind **`recipe`** (`rcp_…`): title, cover, `ageMonths {from, to}`, `texture` (Nghiền mịn · Nghiền lợn cợn · Cắt nhỏ, mềm · Cầm tay · Ăn cùng gia đình), `methods` (spoon / blw), servings, prep and cook minutes, ingredients `{ foodId | null, name, qty, unit }`, steps (≤ 8), storage note, tip, related article ids, sources. Allergens are derived from the foods. "Ghi vào nhật ký" opens 5c with the dish, ingredients and `recipeId`. |
| 10 | Unsafe recipes. | Server gates on Gửi duyệt and Duyệt: a recipe whose age starts below an ingredient's `minAgeMonths` is refused (`food-too-young`); a seasoning in the ingredients (muối, đường, nước mắm, hạt nêm, bột ngọt, nước tương, mật ong…) or an instruction to add one ("nêm chút nước mắm", "nêm nếm vừa ăn", "add a pinch of salt"; negations such as "không nêm muối" pass), or a dose, is refused (`unsafe-copy`, extending the D-083 check). Honey counts as an added sweetener at any age (WHO: no free sugars before 2 years); under 12 months it is also `food-too-young`. |
| 11 | The library (5f). | Two content types in one list: **Hướng dẫn** (articles with `library: 'solids'`, the existing kind) and **Công thức** (recipes). Filters: age band preset from the baby (4–5 · 6–8 · 9–11 · 12–23 · 24–36 tháng), type, method. Search covers titles, keywords and ingredient names. "Dành cho {bé}" (#12) heads the list once tracking is on. Saved items appear in 4f "Đã lưu › Ăn dặm" (the segment exists in the design); recipes are saved in `users/{uid}/savedArticles` next to the guides, so they follow the person. |
| 12 | **Personalization** (owner ask). | On-device rules from the baby's age, stage, meals, tried foods, symptoms and settings, against published foods and recipes (section 7). At most **1 primary + 2 secondary** suggestions a day, each with a plain "vì sao" line and one action. Free for every family in V1. No meal data leaves the device for this. |
| 13 | Roles (Q12). | **Cùng nuôi**: everything. **Người chăm sóc**: log, edit and delete their own meals, see the diary, suggestions and library; cannot change settings, "Bác sĩ đã cho ăn lại" or hidden foods. **Người thân** with daily-care rights: read only. Meals show who logged them (5d row, meal detail). |
| 14 | Edit, delete, details (Q14). | Meal detail (tap a card or row): all fields, who logged, "Sửa", "Xoá" (undo toast, 30-day bin). Food detail (tap a 5e row): meals with it, reactions, symptom history, "Không gợi ý món này", and for Cùng nuôi "Bác sĩ đã cho ăn lại". A filter sheet and a full list for 5f. |
| 15 | Integration with Dinh dưỡng. | The stage's `solids.meals` and `texture` show under 5b's day header as information ("Giai đoạn 6–8 tháng · 2–3 bữa mỗi ngày · nghiền, đặc dần"), never as a target or a judgement. Iron-rich suggestions use the catalogue's `ironRich`, consistent with 9d Sắt. |
| 16 | Notifications. | None in V1 beyond the optional "gần 6 tháng" reminder (#2). No daily nag to log meals. |
| 17 | Wording. | No "suy dinh dưỡng", "béo phì", "biếng ăn" as a label, "thiếu chất"; no doses; no "phải ăn hết". Reaction "Chưa hợp" stays neutral. The 5e footnote stays: "Đây là ghi chép của gia đình bạn, không phải đánh giá hay khuyến nghị dinh dưỡng." Content without a qualified review carries the D-082 footnote. |
| 18 | Night care, vi/en, offline. | Every screen in Light and Night care; every string in the ARB / portal catalogs (D-012); logging works offline; content is cached after the first open. |

## 4. Data model

**Per baby (app writes; Firestore Rules mirror the contract shapes)**
- `babies/{b}/solids/settings`: `{ enabled, startedOn | null, showOnToday, method, hidden: foodId[] ≤ 50, cleared: foodId[] ≤ 50, updatedAt, updatedBy }`. Read: `canReadCare`. Write: Cùng nuôi, baby open.
- `babies/{b}/meals/{id}`: `{ occurredAt, slot, dish, ingredients: { foodIds ≤ 12, free ≤ 3 }, amount: { preset } | { value, unit }, reaction, symptoms ≤ 7, note, recipeId | null, photo: mediaRef | null, createdBy, createdAt, updatedAt, deletedAt | null }`. Photos follow the Kỷ niệm storage paths, quota and Storage Rules. Read: `canReadCare`. Create / update: `canLog`, baby open, valid shape, `createdBy == auth.uid` on create, own meals only for caregivers (as `canEditRecord`). Delete: never (soft delete; the bin job purges after 30 days).
- Derived on the device, never stored: tried foods, first-try flags, counts, group counts, suggestion state. Snoozes ("Để sau") are kept on the device.

**Editorial (portal → app; the `content-library.ts` workflow, D-079 policy)**
- `contentFoods/{fd_…}` and `contentRecipes/{rcp_…}`, published docs readable by signed-in users.
- Solids guides stay articles (`contentArticles`, `library: 'solids'`).

**No child data** (meals, foods tried, symptoms, settings) goes to logs, analytics or crash keys.

## 5. App flows (Flutter)

**Care tile.** "Ăn dặm" with subline: "Từ 6 tháng" (under 4 months) · "Sắp đến lúc ăn dặm" (4–5 months) · "Bắt đầu theo dõi" (6+ months, off) · "Hôm nay · N bữa" (on).

**5a Bật theo dõi** (per baby, BabySwitcher)
- Hero, title, three benefits, as drawn.
- Age state (#2): under 6 months, the "Chưa đến lúc" page (readiness guide, library, reminder); otherwise nothing.
- Optional "Cách cho ăn": Truyền thống · BLW · Kết hợp (default Kết hợp), with a one-line help.
- Toggle "Hiện “Ăn dặm hôm nay” trên Hôm nay" (default on).
- "Bắt đầu theo dõi" (Cùng nuôi). A caregiver sees "Nhờ ba mẹ bật theo dõi ăn dặm" and the library.

**5b Nhật ký**
1. "Gợi ý cho {bé} hôm nay" (section 7): 1 primary card and up to 2 smaller ones; hidden while there is nothing to say.
2. Week strip (swipe for earlier weeks), dots on days with meals.
3. Day header "Hôm nay · N bữa" and the stage line (#15).
4. Meal cards: slot · time, dish (or the ingredients joined), amount · reaction, ingredient chips (✦ for first try), a small "Có dấu hiệu" tag if symptoms were recorded, and who logged it.
5. "Món đã thử · N" chips → 5e.
6. FAB "Ghi bữa" → 5c.
- Empty day: "Chưa có bữa nào hôm nay" + "Ghi bữa".

**5c Ghi bữa** (sheet; also from the quick log, the Today card, 5g and a suggestion)
- Slot (preselected from the time), time, date (up to 7 days back), dish.
- Ingredients: a search picker over the catalogue (synonyms, recent and liked first, the group shown), plus "Thêm tên khác" for free text. First-try chips are marked live.
- Amount, reaction, "Có dấu hiệu bất thường?" with the chips and the 115 card (#6), note, photo (camera or library).
- "Lưu bữa". Saving offline shows the usual pending state.

**5d Lịch sử / 5e Món đã thử.** As drawn, plus the who line, the symptom tag, the group chips (the 7 catalogue groups + Khác), the latest reaction, and food detail (#14).

**5f Thư viện ăn dặm.** Search, filters (#11), "Dành cho {bé}" (3 recipes from section 7), "Hướng dẫn" (featured: the newest guide for the age band, then the list), "Công thức · {band}". Works without tracking.

**5g Công thức.** Cover, chips (Công thức · age · total minutes · texture · methods), servings, ingredients with quantities (✦ "Bé chưa thử" when tracking is on, ⚠ for a food with symptoms), steps, storage, tip, allergen line ("Có trứng"), the D-082 footnote or reviewer, sources, "Lưu", "Ghi vào nhật ký". An age warning if the recipe starts above the baby's age.

**5h Today card.** "Ăn dặm hôm nay · N bữa", latest dish and time, first tries today, "Ghi bữa", and the primary suggestion's title as a second line when there is one.

## 6. Portal (React)

A new menu entry under NỘI DUNG: **Ăn dặm**, with tabs:
1. **Thực phẩm** (catalogue): list by group with allergen, min age, iron, "Gợi ý" flags; editor with a phone preview of the 5e row and food detail; coverage "N món theo nhóm, N món giàu sắt, 9/9 nhóm dị ứng có món".
2. **Công thức**: list by age band with texture, methods, minutes and status; editor (fields of #9) with live allergen and "lần đầu" derivation, the `food-too-young` and `unsafe-copy` checks before Gửi duyệt, and a 5g preview; coverage "Công thức theo độ tuổi" (at least 6 per band 6–8 · 9–11 · 12–23 before the tile goes live).
3. **Hướng dẫn**: the existing article list filtered to `library: 'solids'` (same editor).

Both new kinds use the review queue, the approval policy (D-079), the qualified review on prod, "Nhập bản nháp mẫu" and `content-release.ts`.

## 7. Personalization: "Gợi ý cho {bé}"

**When.** Tracking on, which means the baby is at least 6 months old (D-085 #4). Free for every
family (D-085 #1). Recomputed on open and after each saved meal.

**Inputs (all on the device).** Age in months and days since `startedOn`; `method`; the meals of the
last 30 days; tried foods with first date, times, latest reaction and symptom flag; `hidden` and
`cleared`; published foods and recipes; the current Dinh dưỡng stage.

**Rules, in priority order** (each makes at most one card; the top card is primary)

| # | Rule | Fires when | Card (example for Na, 7 months) | Action |
|---|---|---|---|---|
| S1 | Safety after symptoms | a meal in the last 3 days had symptoms | "Theo dõi sau dấu hiệu hôm 07/10 (Cà rốt). Tạm chưa thử món mới vài ngày và hỏi bác sĩ nếu còn lo." While it holds (3 days, even when snoozed) nothing new and no allergen is suggested (S2, S3, S4, S6), and S5 offers only foods the baby has eaten. | "Đọc: Nhận biết phản ứng" |
| S2 | First foods | fewer than 5 foods tried | "Món tiếp theo cho Na: Bí đỏ, Khoai lang hoặc Thịt gà xay (giàu sắt)." | "Ghi bữa" (prefilled) |
| S3 | Allergen introduction | ≥ 5 foods tried, ≥ 7 days since start, no new allergen in 3 days | "Đã đến lúc thử trứng chín kỹ: buổi sáng, ở nhà, một lượng nhỏ." Order: egg → peanut (paste) → milk (yoghurt, in cooking) → wheat → fish → soy → sesame → shellfish → tree nuts (paste). | "Xem công thức" |
| S4 | Keep allergens up | an introduced allergen without symptoms not offered in 7 days | "Cho Na ăn lại trứng tuần này để duy trì." | "Ghi bữa" |
| S5 | Iron | ≥ 6 months, meals logged on the last 2 days, none with an iron-rich food | "Hôm nay thêm một món giàu sắt: thịt bò, gan gà hoặc đậu nghiền." Prefers foods tried and liked. | "Xem công thức" |
| S6 | Next new food | no new food in 2 days | 3 foods: allowed for the age, not tried, not hidden, not an allergen (S3 handles those), from the group with the fewest tries, vegetables before fruit early on, then `priority`. | "Ghi bữa" |
| S7 | Retry a "Chưa hợp" | latest reaction "Chưa hợp" (no symptoms), last offered ≥ 3 days ago, fewer than 10 tries | "Thử lại cà rốt theo cách khác: nghiền mịn hơn hoặc trộn với khoai lang Na thích. Bé có thể cần 8–15 lần mới quen." | "Ghi bữa" |
| S8 | Variety | a group not offered in 7 days | "Tuần này Na chưa ăn trái cây nào." | "Xem gợi ý" |
| S9 | Texture step | first open in a new Dinh dưỡng stage | "Na 8 tháng: thử cháo đặc, nghiền lợn cợn và thức ăn cầm tay mềm." (from the stage's `texture`) | "Đọc hướng dẫn" |

**Recipes "Dành cho {bé}"** (5f, and the "Xem công thức" action): published recipes for the age and
method with no hidden or symptom food, at most one untried ingredient (the suggested food if any),
ranked by the number of tried-and-liked ingredients, then newest.

**Feedback.** "Để sau" snoozes that card for 3 days (on the device). "Không gợi ý món này" adds the
food to `hidden` (Cùng nuôi) or snoozes it (caregivers). A logged meal that contains the suggested
food completes the card.

**Guardrails.** Never suggest a food above its `minAgeMonths`, a hidden food, or one with symptoms
not cleared. Never compare the baby with others or name amounts as targets. Every card has a "vì
sao" line. With no published foods the section is hidden (the feature still logs).

## 8. Content plan

- **Guides (now):** 23 solids articles: the 7 seeded plus 16 new ones written for this plan
  (`firebase/functions/src/solids-seed.ts`): first meals, methods (truyền thống / BLW), Vietnamese
  bột and cháo, iron-rich foods, hunger and fullness cues, foods to avoid under 1, reactions and
  when to call 115, preparation and storage, sample menus 6–8 and 9–11 months, finger foods,
  refusal, constipation, sick or teething days, family meals from 12 months, equipment.
- **Foods (phase C):** about 120 catalogue entries with groups, allergens, minimum ages and
  preparation by texture.
- **Recipes (phase C):** at least 30, 6+ per age band, Vietnamese home cooking first (cháo, súp,
  rau củ nghiền, cơm nát), each with quantities, texture and storage.
- All drafts are imported with "Nhập bản nháp mẫu" and follow the approval policy; on prod they need
  the qualified review.

## 9. Delivery (PM)

| Phase | Scope | Done when |
|---|---|---|
| A · Library | App 5f with solids guides (no recipes yet), saved › Ăn dặm, the Care tile opening 5f for babies not yet tracking; publish the 23 guides on dev | Guides readable on iOS and Android, Light and Night care, vi and en |
| B · Diary | 5a–5e, 5h, quick log, symptoms and the 115 card, settings, meals collection, meal photos, Rules, purge and bin; meals in Lịch sử, Thống kê and the care export | Meals logged offline sync, photos upload through the queue; caregiver limits hold in Rules tests |
| C · Foods and recipes | `food` and `recipe` kinds, gates, portal tabs, 5g, ingredient picker on the catalogue, "Ghi vào nhật ký" | The seeded catalogue and 30 recipes published on dev |
| D · Personalization | Section 7 engine and cards in 5b, 5f, 5h | Every rule has a unit test with the Na fixtures below |

Phases A and B can ship separately; D needs C.

## 10. Acceptance (QA seeds)

Na, born 2026-03-01, viewed on 2026-10-08 (7 months), method Kết hợp, started 2026-09-28.
1. Under 4 months (born 2026-07-01): the tile says "Từ 6 tháng"; 5a cannot start; the reminder is set for 5 months 2 weeks.
2. At 5 months 20 days: the tile says "Sắp đến lúc ăn dặm", 5a still cannot start; at 6 months 0 days tracking starts.
3. Log "Cháo cà rốt thịt gà" with Gạo, Cà rốt, Thịt gà (never logged before): "Thịt gà · lần đầu" shows in 5c, 5b and 5h; 5e counts 15.
4. Choose "Khó thở": the 115 card shows before saving; after saving, Thịt gà shows "Có dấu hiệu" in 5e and is never suggested; S1 is the primary card for 3 days.
5. A caregiver logs a meal and edits it; they cannot edit a parent's meal, change settings or clear a food (Rules tests).
6. 5 foods tried, started 10 days ago, no allergen yet: S3 suggests egg; after an egg meal without symptoms, peanut is next after 3 days; S4 fires on day 8 without egg.
7. Two days of meals without an iron-rich food at 7 months: S5 shows and prefers a tried, liked iron food.
8. A recipe for 6 months with honey: Gửi duyệt is refused (`food-too-young`); with "nêm chút nước mắm": refused (`unsafe-copy`).
9. Delete the baby: `meals` and `solids` are purged with it.
10. Night care and English on every screen.

## 11. Owner answers (2026-10-18)

1. Personalization: free.
2. Meal photos: allowed (stored like Kỷ niệm).
3. Meals in Lịch sử, Thống kê and the care export: yes.
4. Tracking starts from 6 months only.

## 12. Owner additions (2026-10-19, D-086)

**Owner request:** "cả 2 và cần biết được lịch sử bé ngày nào đã ăn món gì này nọ … rồi cá nhân hoá
gợi ý ăn dặm món phù hợp" (Figma `313:1681`, `313:1746`, `314:1786`).

1. **Dishes made.** A recipe page (Child Life or the family's own) shows "Nhà mình đã làm N lần ·
   gần nhất 07/10 · Na thích" (the latest reaction of those meals) and "Các lần đã làm" (the meals
   cooked from it, newest first). Meal detail shows "Theo công thức: {tên} ›". It reads the meals'
   `recipeId`, now `rcp_…` or the family's `fr_…`.
2. **Công thức nhà mình** (`babies/{b}/recipes/{fr_…}`, `familyRecipeSchema`):
   - Created from scratch ("Thêm công thức nhà mình" in 5f) or with "Lưu thành công thức" on a meal
     (title = the dish, its ingredients prefilled).
   - Title, one photo (Storage `babies/{b}/recipes/{file}.jpg`, like meal photos), ingredients from
     the catalogue or free names with optional quantity and unit, up to 12 steps, a note.
   - Shared by everyone who cares for the baby. Cùng nuôi and Người chăm sóc create; the writer or a
     Cùng nuôi edits and deletes (soft delete, undo, the 30-day bin); relatives with daily-care
     rights read.
   - The family's own text is never blocked. The app nudges: honey under 12 months, an added
     seasoning (the same phrases as `solidsCopyProblems`), the catalogue choking note for the baby's
     age, "⚠ Có dấu hiệu" on foods with recorded symptoms, "✦ Bé chưa thử" on new foods.
   - Shown first in 5f ("Nhà mình"), in 4f "Đã lưu › Ăn dặm" under "Nhà mình", and as one-tap chips
     at the top of 5c ("Món nhà mình": recent family recipes prefill the meal and `recipeId`).
   - Purged with the baby; a deleted member's recipes keep "Người dùng đã xoá"; the care export adds
     `family-recipes.csv`.
3. **Which day the baby ate what.**
   - 5d gets "Lịch": a month calendar with a dot and the number of meals per day, back to the first
     meal, tap a day for its meals (5b layout).
   - 5d search over dish, ingredient and recipe names: "Cà rốt" lists every day with carrot, grouped
     by day, newest first.
   - Food detail lists every date the food was eaten (paged), with the reaction and any signs.
   - 5b's week strip scrolls to earlier weeks and has "Hôm nay".
4. **Personalization** is built (§7, free). Family recipes now join "Dành cho {bé}" with the same
   ranking and a "Nhà mình" tag, so a dish the family already makes and the baby likes comes back as
   a suggestion when it fits the day's rule.
