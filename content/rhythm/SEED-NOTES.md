# Nhịp lớn lên: seed content notes (for expert review)

`reference.seed.json` follows `referenceModelSchema` (`packages/contracts/src/rhythm.ts`). `content.seed.json` follows `rhythmContentSchema` (`packages/contracts/src/personalization.ts`). `packages/contracts/test/rhythm-content-seed.test.ts` checks both files. The dev seed script (`scripts/src/seed-rhythm.ts`, plan §7.1) publishes them to `child-life-dev` only.

## 0. Status: reviewed, signed "Child Life Team" (D-148)

- **Who wrote it.** Engineering drafted this content per owner decision **D-073 #2** ("làm nội dung như 1 chuyên môn đi. Người duyệt sau") from public guidance (WHO, AAP / HealthyChildren.org, CDC, NHS, UNICEF); every item cites its sources. The 12–36-month pack was rewritten on 2026-10-30 (`docs/product/content-review-2026-10/rhythm-prereview-2026-10-30.md`).
- **Reviewed.** The owner's expert read and approved the 2026-10-30 version (D-141); by owner decision **D-148** every item is signed `{"reviewer": "Child Life Team", "credential": "Child Life Team", "reviewedOn": "2026-10-30"}` (no individual name or title). The app shows "Đã duyệt bởi Child Life Team" / "Reviewed by Child Life Team" instead of "Nội dung minh hoạ · chờ chuyên môn duyệt".
- **Prod.** Prod publishing still goes through the portal (PN01–PN04). The "Wonder Weeks" name and model rights check (D-072 #7) is still a release gate.
- **Language.** Vietnamese is the primary text, written for parents ("ba mẹ", "con", "bé"). English is a parallel draft with the same meaning (D-012). English uses British spelling (favourite, recognise, pyjamas), except "diaper", which matches `app_en.arb`.

## 1. What the seed contains

| File                               | Content                                                                                                                                                 | Count        |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------ |
| `reference.seed.json`              | `ref_20261015_01`, label "Wonder Weeks", stages counted from the **due date**                                                                           | 10 stages    |
| `content.seed.json` → `activities` | `act_*`, all `published`, v1, `locales: [vi, en]`, `regions: []`                                                                                        | 37           |
| `content.seed.json` → `ageCards`   | "Tuần này của {bé}": weekly for weeks 1–13 (days 0–90), then monthly from 3 to 24 months (days 91–760). Chosen by actual age, except a preterm baby (born ≥ 21 days before the due date) gets the corrected age until 24 months (D-141, expert review 2026-10-30) | 35 (13 + 22) |
| `content.seed.json` → `health`     | 8 signs (ids = `healthSigns`), 5 "Trong lúc chờ" steps, disclaimer, 12 region numbers                                                                   | —            |

`version` is `rc_20261015_01`. `publishedAt` is `null` in both files.

## 2. Reference calendar (NL03, NL04, PN02)

**It is a model, not a prediction.**

- The calendar is a published reference. It does not forecast what a given baby will do.
- de Weerth & van Geert (1998) studied this idea independently and did not confirm fixed periods; timing varied a lot between babies. The model's `sources` cite it next to The Wonder Weeks.
- Every stage's `signs` are written as possibilities ("có thể…", "một số bé…", "may…"). Every stage ends with "Một số bé không có thay đổi rõ — điều đó bình thường".
- The test fails if any sign contains "chắc chắn", "definitely" or "will". PN02's "Không được viết" list applies to every edit.

**"Wonder Weeks" is a reference label only (D-072 #7).**

- The name and model rights check is still a release gate before prod.
- Stage names are neutral: "Giai đoạn n · {chủ đề}" / "Stage n · {theme}". The themes are our own words, not the book's leap names or chapter text.
- None of the book's descriptions are reproduced. Signs and skills are generic, age-typical observations (CDC milestones, WHO motor windows).
- If the app shows "(Wonder Weeks)" next to a stage, it takes it from `label` and never implies partnership.

**Windows.**

- Offsets are days after the due date, inclusive at both ends.
- Each window holds the commonly published leap week. Week N from the due date covers days (N−1)·7 … N·7−1.
- Windows are no longer than 3 weeks and do not overlap.
- NL03's mock offsets (e.g. stage 1 on days 20–27) were illustrative and are not used.

| #   | Theme (vi / en)                                      | Days after due date | ≈ Week |
| --- | ---------------------------------------------------- | ------------------- | ------ |
| 1   | Giác quan nhạy hơn / Senses sharpening               | 28–38               | 5      |
| 2   | Nhìn và nghe kỹ hơn / Looking and listening closely  | 49–60               | 8      |
| 3   | Cử động và tiếng nói / Movement and voice            | 77–87               | 12     |
| 4   | Với tay, cầm nắm / Reaching and grasping             | 119–139             | 19     |
| 5   | Gần, xa và người quen / Near, far and familiar faces | 168–188             | 26     |
| 6   | Khám phá đồ vật / Exploring objects                  | 245–265             | 37     |
| 7   | Bắt chước và kết hợp / Copying and combining         | 308–328             | 46     |
| 8   | Thói quen hằng ngày / Everyday routines              | 371–391             | 55     |
| 9   | Thử theo cách của con / Trying their own way         | 434–454             | 64     |
| 10  | Tự lập hơn / Growing independence                    | 511–531             | 75     |

**Other stage fields.**

- **Skills** are age-typical observations ("Kỹ năng tham khảo theo tuổi"), never requirements. The app should keep NL04's line "Kỹ năng không bắt buộc khớp với giai đoạn này" as UI copy. It is not repeated in every stage.
- **Notices** contain no `{bé}` placeholder, so the PN02 limits hold as written. Titles run 36–39 characters (limit 40) and bodies stay under 90 characters; the test enforces both limits.
- **`activityIds`:** each linked activity's age range (from birth) touches the stage window. The test checks this.

## 3. Activities (AC01, NL08, PN03)

Each activity has:

- a title and a one-sentence summary;
- 3–5 steps;
- a safety line ("Không khi…") where relevant;
- duration, age range in days from birth, needs, interests, time of day and 1–3 sources.

The copy never promises outcomes and never claims causality ("có thể giúp", "một số bé", "may help"). The rule follows AC02: "“Có ích” không có nghĩa là cách này gây ra thay đổi".

| id                             | age (days) | needs                    | time    | min | safety |
| ------------------------------ | ---------- | ------------------------ | ------- | --- | ------ |
| `act_skin_to_skin`             | 0–91       | soothing, bonding        | any     | 10  | yes    |
| `act_wind_down_night`          | 14–365     | sleep                    | evening | 15  | yes    |
| `act_white_noise_low`          | 0–183      | sleep, soothing          | evening | 15  | yes    |
| `act_swaddle_before_rolling`   | 0–60       | sleep, soothing          | evening | 5   | yes    |
| `act_safe_sleep_check`         | 0–365      | sleep                    | evening | 2   | yes    |
| `act_day_night`                | 14–122     | sleep                    | any     | 5   | —      |
| `act_calm_night_feed`          | 0–183      | feeding, sleep           | evening | 20  | yes    |
| `act_drowsy_but_awake`         | 61–365     | sleep                    | evening | 10  | —      |
| `act_bedtime_routine`          | 122–730    | sleep                    | evening | 20  | —      |
| `act_warm_bath`                | 14–730     | sleep, bonding           | evening | 15  | yes    |
| `act_feeding_cues`             | 0–183      | feeding                  | any     | 5   | yes    |
| `act_responsive_breastfeeding` | 0–183      | feeding, bonding         | any     | 20  | yes    |
| `act_paced_bottle`             | 0–365      | feeding, bonding         | any     | 20  | yes    |
| `act_gentle_burping`           | 0–183      | feeding, soothing        | any     | 5   | yes    |
| `act_first_foods`              | 165–365    | feeding                  | day     | 15  | yes    |
| `act_finger_foods`             | 213–730    | feeding, milestone       | day     | 15  | yes    |
| `act_open_cup`                 | 183–730    | feeding, milestone       | day     | 5   | yes    |
| `act_crying_check`             | 0–365      | soothing                 | any     | 5   | yes    |
| `act_gentle_rocking`           | 0–365      | soothing                 | any     | 10  | yes    |
| `act_parent_break`             | 0–365      | soothing                 | any     | 10  | yes    |
| `act_teething_comfort`         | 122–730    | soothing                 | any     | 10  | yes    |
| `act_big_feelings`             | 365–730    | soothing                 | any     | 10  | yes    |
| `act_two_choices`              | 426–730    | soothing, milestone      | any     | 5   | —      |
| `act_tummy_time`               | 0–183      | play, milestone          | day     | 3   | yes    |
| `act_tummy_on_chest`           | 0–91       | play, bonding            | any     | 5   | yes    |
| `act_sing_softly`              | 0–365      | play, bonding            | any     | 5   | —      |
| `act_face_to_face`             | 0–122      | bonding, play            | any     | 5   | —      |
| `act_high_contrast`            | 0–122      | play, milestone          | day     | 5   | —      |
| `act_narrate_day`              | 30–730     | play, milestone, bonding | any     | 10  | —      |
| `act_read_together`            | 61–730     | play, bonding, milestone | any     | 10  | —      |
| `act_reach_and_grab`           | 70–244     | play, milestone          | day     | 5   | yes    |
| `act_mirror_play`              | 91–548     | play, milestone          | day     | 5   | —      |
| `act_peekaboo`                 | 152–730    | play, bonding, milestone | any     | 5   | —      |
| `act_floor_play`               | 122–548    | play, milestone          | day     | 15  | yes    |
| `act_put_in_take_out`          | 244–730    | play, milestone          | day     | 10  | yes    |
| `act_name_and_point`           | 244–730    | milestone, play          | any     | 5   | —      |
| `act_outdoor_walk`             | 30–730     | bonding, play, sleep     | day     | 20  | yes    |

Interests map as follows: sleep → `sleep`; feeding → `feeding`; solids and cups → `nutrition`; play and milestones → `milestones`; bonding → `moments`. `act_wind_down_night` keeps the AC01 copy (title and 4 steps) word for word.

## 4. Age cards "Tuần này của {bé}"

**Ranges.**

- Weekly cards `age_w01`…`age_w13` cover days 7(n−1)…7(n−1)+6.
- Monthly cards `age_m03`…`age_m24` start month m at round(m × 30.4375). For example, `age_m03` covers days 91–121 and `age_m24` covers days 730–760.
- Together they cover every day from 0 to 730, and the test checks there are no gaps. `ageCardFor` picks the narrowest card.

**Titles.**

- Weekly cards are titled "Tuần n" / "Week n", counted as week of life: days 0–6 are "Tuần 1".
- Monthly cards are titled "n tháng tuổi" / "n months old", **not** "Tháng n", because "Tháng 5" reads as the month of May.
- Q-067's card pattern "Tuần {n} · điều con có thể làm" can be composed by the app.

**Content.**

- **`body`:** what families often notice, always framed "mỗi bé mỗi khác".
- **`tips`:** 2–4 practical tips.
- **`watchFor`:** when to talk to the baby's doctor, written gently in the style of CDC "Learn the Signs. Act Early.".
  - Every month card includes "Con mất đi một kỹ năng từng làm được".
  - Week cards repeat the fever rule for babies under 3 months.

## 5. Health routing (NL05b, NL06, HL01)

**Signs.** The ids follow `healthSigns` exactly and in order. `fever_young` has `maxAgeDays: 90`; every other sign has `null`. The labels name what parents can see; they are not diagnoses. The wording draws on the WHO IMCI general danger signs and the NHS / AAP "get help now" lists.

**"Trong lúc chờ".** Five steps:

1. Stay with the baby and watch their breathing.
2. Seizure position.
3. Not breathing → emergency services + Sơ cứu CPR.
4. Light clothing, no cold sponging, no fever medicine under 3 months without a doctor.
5. Note the times and bring the vaccination record.

**Disclaimer.** Child Life does not diagnose and never concludes "an toàn". Call emergency services or the baby's doctor.

**Regions.**

| Country | Number |
| ------- | ------ |
| VN      | 115    |
| US      | 911    |
| CA      | 911    |
| GB      | 999    |
| AU      | 000    |
| NZ      | 111    |
| SG      | 995    |
| DE      | 112    |
| FR      | 112    |
| JP      | 119    |
| KR      | 119    |
| TW      | 119    |

A country that is not listed gets "Gọi bác sĩ của bé", never a default hotline.

## 6. Needs a reviewer's attention

1. **Fever thresholds.**
   - 38°C under 3 months is `maxAgeDays: 90`. Day 90 counts as "under 3 months", and the `m03` card starts on day 91. Confirm the cut-off.
   - Cards `m03`–`m05` add the NHS line "39°C or higher at 3–6 months → contact a doctor the same day". Check that this fits Vietnamese practice.
   - The measurement method (rectal / axillary / forehead) is not stated. Axillary readings are common in Việt Nam.
2. **Emergency numbers.** Confirm each one.
   - VN: 115 is the medical number (113 police, 114 fire).
   - GB: 999 (112 also works).
   - AU: 000 (112 from mobiles).
   - SG: 995 is ambulance and fire (999 is police).
   - FR: 112 (15 is SAMU, medical).
   - JP, KR, TW: 119 is ambulance and fire.
3. **Swaddling (`act_swaddle_before_rolling`).**
   - The seed follows AAP: only for babies who cannot roll, always on the back, hips loose, stop at the first signs of rolling. `ageDays` stops at 60.
   - NHS guidance is more cautious, and traditional tight leg-wrapping ("quấn chặt") is common in Việt Nam.
   - Decide whether to keep this activity, and the age cap.
4. **Safe sleep wording.**
   - The seed says: back to sleep, firm flat surface, nothing soft in the cot, own cot in the parents' room for at least 6 months, never on a sofa or nursing pillow.
   - Bed-sharing is common in Việt Nam. Decide whether a harm-reduction line is needed for families who bed-share.
   - `act_skin_to_skin`, `act_tummy_on_chest` and `act_calm_night_feed` warn about falling asleep holding the baby.
5. **White noise.** The copy says "about 2 m away, quieter than normal conversation". The AAP-cited study suggested at least 200 cm and low volume. No dB figure is given. Confirm.
6. **Feeding.**
   - Solids start "around 6 months, never before 4 months". `act_first_foods` starts ranking at day 165; choose 165 or 183.
   - No honey before 12 months, no whole nuts, grapes quartered lengthways.
   - "A fully breastfed baby under 6 months usually needs no extra water". Formula-fed babies in hot weather may differ (NHS); Việt Nam is hot.
   - Milk after 1 year is left to the doctor. Regional practice and growing-up-milk marketing differ.
7. **Vaccination mentions.** Mentions such as "lịch tiêm 2 tháng" and "12 tháng" are generic. Việt Nam's EPI schedule differs from US/UK schedules; check the wording.
8. **Developmental screening.** The tips at 9, 18 and 24 months follow the AAP (US) schedule, which is not routine everywhere. They are phrased as "hỏi bác sĩ" ("ask the doctor").
9. **Jaundice and newborn checks.**
   - Jaundice in the first 24 h, or lasting more than 2 weeks (3 weeks if preterm), with pale stools or dark urine (NHS).
   - From day 5–6, at least 6 wet diapers a day.
10. **Quoted ranges.** The seed quotes these WHO motor windows, rounded: sitting 4–9 months (3.8–9.2), standing with support 5–11 (4.8–11.4), walking alone 8–18 (8.2–17.6). It also says crying peaks at around 6–8 weeks.
11. **Screens.** The seed says: avoid before 18 months except video calls (AAP); at 2 years, at most 1 hour (WHO 2019).
12. **Teething.** No amber necklaces and no numbing gels. "Teething doesn't cause a high fever."
13. **Health "while waiting" steps.** Check the seizure position and the fever-medicine line. NHS allows paracetamol from 2 months and ibuprofen from 3 months; the seed says to ask a doctor under 3 months. Also check the CPR handoff to Sơ cứu.
14. **`lost_skill` routing.** It sits in the health route (HL01) with an emergency button, but losing a skill is usually a "see the doctor soon" sign, not an emergency. Product may want softer routing.
15. **Due date vs birth date.**
    - Stages are counted from the due date. Activities and age cards use actual age from birth (brief p.13).
    - For a preterm baby, a stage's linked activity can fall outside the birth-age range that `recommend()` filters on. NL04 may then show an activity the ranker would not pick.
16. **Coverage beyond 12 months.** NL03 says "nội dung sau 12 tháng chưa hỗ trợ", but the seed has stages 8–10 (≈ 55–75 weeks) and age cards to 24 months. Product to confirm.
17. **Sources.**
    - On 2026-10-15 every URL answered 200 to `curl`, except cdc.gov, onlinelibrary.wiley.com and thewonderweeks.com, which block scripted requests (403). Open those in a browser.
    - NHS links use the post-2025 paths (`nhs.uk/baby/…`).
    - The de Weerth & van Geert summary in the source label should be checked against the paper.
18. **"Wonder Weeks".** The label is a reference only, pending the rights check (D-072 #7). If the check fails, change `label`; stage names and content do not depend on it.

## 7. Review pass 2026-10-16 (`rc_20261016_01`, `ref_20261016_01`)

Engineering review in specialist roles (paediatrician, IBCLC, child development), still a draft:
every item stays `review: null`. Full findings, sources and answers to §6:
`docs/product/content-review-2026-10/rhythm.md`; the change set: `rhythm-additions.json` there.

- **No P0.** 72 text changes (13 P1, 43 P2, 16 P3): `act_first_foods` ranks from day 183 (not 165);
  Vietnamese hazards named (võng, auto swings, wedge / "flat-head" pillows, charcoal braziers in
  closed rooms, mulberry-bead and silver anklets, honey on gums, nước mắm / hạt nêm in solids,
  longan, lychee, rambutan, konjac jelly cups, sticky rice); vaccine and check-up wording made
  schedule-neutral ("theo lịch tiêm ở nơi bạn sống"); fever cards name the thermometer method,
  low temperature, no alcohol rubs, no aspirin; milestone "watch for" ages moved off the window start.
- **16 new activities** (`act_bed_sharing_safer`, `act_hot_weather_comfort`, `act_common_allergens`,
  `act_choking_safe_foods`, `act_add_a_word`, `act_pretend_play`, `act_brush_first_teeth`,
  `act_family_meal_self_feed`, `act_potty_readiness`, `act_water_safety_home`,
  `act_partner_care_time`, `act_parent_check_in`, `act_sun_and_mosquitoes`,
  `act_car_seat_every_trip`, `act_active_play_every_day`, `act_vitamin_d_drops` for US / CA / GB
  only). Stages 8–10 link the new 12–24 month ones.
- **Health regions**: 18 numbers added where the reviewer was confident (MY, TH, HK, CN, IE, NL, BE,
  ES, CH, AT, CZ, PL, SE, NO, DK, FI, AE, QA). Left out until checked on an official page: PH 911,
  ID 112 / 119, KH 119, IT 112, RU 112, SA 997, IN 112, BN 991, LA 1195. A country not listed keeps
  "Gọi bác sĩ của bé" (never a guessed number).
- **Needs a clinician's decision:** `act_bed_sharing_safer` is NHS-style harm reduction (AAP says
  never bed-share); swaddling cap; `lost_skill` routing (see a doctor within days, not emergency).
