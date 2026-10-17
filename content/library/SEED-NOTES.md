# Thư viện chăm bé & Giai đoạn của bé: seed content notes (for expert review)

The seed is `firebase/functions/src/content-seed.ts` (34 articles, 16 stages, vi + en), imported as drafts
through the portal ("Nhập bản nháp mẫu", `staffContentSeed`). `firebase/functions/test/content-seed.test.ts`
checks the strict schemas, reading time, links, vi/en block parity, sources and plain text.

## 0. Status: engineering draft, not approved

- Written by engineering per **D-073 #2** ("làm nội dung như 1 chuyên môn, người duyệt sau") and the owner's
  2026-10-15 request ("soạn như chuyên gia"). Drafted in specialist roles (paediatrician, paediatric nurse,
  IBCLC, paediatric dietitian, child-development specialist, perinatal mental health) from public guidance:
  WHO, UNICEF, AAP / HealthyChildren, NHS, NICE, CDC, Bộ Y tế / Thông tư, Vietnamese hospital pages.
- **Nobody qualified has reviewed it.** Every item publishes as illustrative ("Nội dung minh hoạ · chờ
  chuyên môn duyệt"); prod publishing needs a signed review. The `reviewerLabel` constants name the
  reviewer *role* needed, not a review that happened.
- Structure of every article: Tóm tắt nhanh → Hiểu đúng → Ba mẹ có thể làm gì → Theo dõi → Hiểu lầm thường
  gặp (Vietnamese practices, corrected without blame) → doctor callouts (115 / see a doctor). Emergency
  procedures are not repeated: articles point to Sơ cứu trẻ em.

## 1. Where guidance bodies differ (what the text recommends)

| Topic | Bodies | Text |
|---|---|---|
| Bed-sharing | AAP never; NHS harm-reduction | Separate cot; NHS steps only as harm reduction |
| Newborn / toddler sleep hours | AAP 16–17, NHS ~18; AASM 11–14 vs NHS 12–15 | Ranges with sources |
| Stop swaddling | AAP usually 3–4 mo, some ~2 mo | At the first sign of rolling |
| Fever call threshold | AAP any fever < 2 mo; NHS/NICE < 3 mo ≥ 38 °C; 3–6 mo ≥ 39 °C | NICE/NHS |
| Fever medicine | NICE only if distressed; BV Nhi TW 38.5 °C | Comfort, not a number; both stated |
| Ibuprofen age | NHS ≥ 3 mo and > 5 kg; AAP < 6 mo only on doctor's advice | AAP (cautious); never with dehydration, chickenpox, possible dengue |
| Sponging | NICE/NHS no; CDC after-vaccine page suggests it | No sponging, ice or alcohol |
| Cough / cold medicine | FDA < 2, AAP < 4, MHRA < 6 | Not under 2; older only on doctor's advice |
| Prolonged jaundice | NICE > 14 d term / > 21 d preterm; AAP breastfed up to ~4 wk | NICE |
| Fast breathing | WHO IMCI ≥ 60 / ≥ 50 / ≥ 40; NICE > 60 / > 50 | WHO |
| Post-vaccine wait | Canada ≥ 15 min; VN law 30 min | 30 min (Thông tư 13/2026) |
| Breast milk in fridge | CDC 4 d; NHS 8 d at ≤ 4 °C | CDC (heat, power cuts) |
| Hot water for formula | NHS every feed ≥ 70 °C; CDC/AAP only < 2 mo / preterm | Always boil in Việt Nam |
| Vitamin D | AAP 400 IU from first days; NHS 8.5–10 µg; formula threshold NHS 500 ml vs AAP ~800 ml–1 L | Both stated; combination feeding → ask doctor |
| Iron for breastfed babies | AAP 2026 by 4 mo or wait to 6 mo | From ~4 mo or at the latest at solids; no dose; ask doctor |
| Water < 6 mo | WHO none; NHS sips in heat for formula-fed | None; ask doctor; never dilute formula |
| Whole nuts | AAP until 4, NHS/BSACI 5 | 5 |
| Juice | AAP ≤ 120 ml (1–3 y); NHS dilute 1:10 | None before 1; then ≤ 120 ml 100% juice with a meal |
| Cow's milk 6–11 mo | WHO 2023 allows; NHS/AAP cooking only | NHS/AAP |
| Allergen upkeep | ASCIA/BSACI/CSACI ≥ weekly | At least weekly |
| High-risk peanut | NIAID test first; CSACI don't pre-test | Ask doctor |
| Teething and fever | NHS < 38 °C possible; AAP fever not a symptom | ≥ 38 °C is never teething |
| Teething gels | FDA no; NHS not banned | Avoid |
| Tummy time | AAP 2–3×/day building up; WHO ≥ 30 min/day | Start short, aim ≥ 30 min |
| Screens | WHO none < 1, ≤ 1 h at 2; AAP avoid < 18 mo except video chat; AAP 2026 moved to quality/context | WHO limits; video-call exception credited to AAP |
| Separation anxiety | NHS 6 mo–3 y; AAP ~9 mo + 15–18 mo; CDC 9 mo | All three |
| Perinatal depression | WHO 13% worldwide, ~19.8% developing countries | WHO figures |

## 2. Claims that could not be verified against an opened source

- **Kept as specialist advice (please confirm):** hammock risk (inferred from AAP flat ≤ 10° / NHS chin off
  chest); green vomit → 115 (stricter than NHS); cạo gió bruising and delay; cooling patches cool only the
  forehead; soap / stalk insertion and soap enemas; unclean poultices on injection sites; normal bathing
  after any vaccine (NSW Health confirms for BCG only); thóp lõm / môi khô as dehydration signs; mother very
  unwell / faint → 115; thermos water may not be hot enough; lap-holding in cars unsafe; child in front of a
  motorbike rider takes the first impact; adult helmets too big; never leave a child in a car; cover sockets;
  never decant chemicals into drink bottles; tablecloth pulling; cover water jars; any drowning needs
  emergency care; "never shake a baby"; ở cữ and bathing notes; postnatal screening questionnaires.
- **Secondary sources only:** "about 1 in 10 fathers" (Paulson & Bazemore, JAMA 2010, via RTI page); camphor
  toxicity (poison.org) with AAP "rubs only from age 2"; iron stores "by about 6 months".
- **Unreachable official sources:** Viện Dinh dưỡng / Bộ Y tế complementary-feeding PDF; WHO powdered-formula
  guideline (70 °C / 2 h attributed to NHS and CDC instead); WHO 2022 and NICE CG57 for skin care; the
  official gazette text of Law 118/2025.
- **Dropped because unverified:** newborn wake windows, nap counts, active-sleep share, mercury
  thermometers, "don't wake for medicine", dengue day 3–7, HFMD 48 h, ORS 24 h, rotavirus age limits, stool
  colour cards, Rome IV, banana / rice constipation, formula 150–200 ml/kg/day, foremilk / hindmilk,
  baby-blues %, 20–30 cm newborn focus, car-seat crash replacement, stair gates "until 2", hospital phone
  numbers and hours.

## 3. Việt Nam specifics to check

- **Car seats:** Luật TTATGTĐB 2024 khoản 3 Điều 10 starts **1/7/2026** (postponed by Law 118/2025): children
  under 10 and shorter than 1.35 m may not sit in the driver's row except single-row cars; the driver must
  use / instruct a suitable restraint. Fines left out (Decree 238/2026 reportedly changed them).
- **Motorbikes (Điều 33):** at most 2 passengers when one is a child under 12; everyone wears a standard
  helmet, strap fastened. The section is framed "no safe way; these only reduce risk".
- **Vaccination:** the schedule is cited from Vinmec (Thông tư 38/2017, superseded); Thông tư 13/2026 (from
  1/7/2026) keeps the 30-minute clinic wait and ≥ 24 h home watch. Text says the schedule can change.
- **G6PD deficiency** is common in Việt Nam: jaundice article says to ask the doctor (fava beans).
- **Help lines:** Ngày Mai 096 306 1414 (not 24/7; "check the hours"); 111 child protection (free; 24/7 not
  confirmed); Viện Sức khỏe Tâm thần, Bạch Mai named as an example only; 115 for emergencies (not cited).

## 4. Stages (Giai đoạn của bé)

16 ranges 0–2 weeks … 18–24 months; 3 observable "bé đang làm gì" and 3 "thử cùng bé (vì sao)" each; sources
are the CDC per-age pages. Feeds "8–12 a day" (w0) and the CDC milestone / tip wording were checked; "≥ 30
min tummy time" is WHO 2019; "many walk between 9 and 18 months" follows the milestones seed window.

## 5. Related content fixed

`content/first-aid/pack.seed.json` jaundice now uses NICE thresholds (fades in ~2 weeks; see a doctor if it
lasts > 2 weeks, > 3 weeks if premature). Still to align there (not safety conflicts): thermometer advice
(NICE: armpit electronic < 4 weeks; forehead strips unreliable), the 3–6 months ≥ 39 °C rule, and "uống
nhiều nước" / "nôn > 12 giờ" in Ngộ độc thực phẩm vs WHO / NICE ORS and NHS 2-day guidance. The dev
first-aid content already published needs the same edit through the portal.

## 6. Review pass 2026-10-16

Still an engineering draft in specialist roles; nothing here is a clinical review. Findings, sources
and answers: `docs/product/content-review-2026-10/library.md`.

- **No P0.** P1 fixes applied: engorgement and mastitis follow ABM Protocol #36 (2022: cold, no heat
  or deep massage, no over-expressing); the safe-sleep English no longer reads as "no sleep sacks"
  and adds "extremely tired" to the never-bed-share list; G6PD advice names naphthalene mothballs
  (băng phiến); milk-diet myth in jaundice corrected.
- **Multi-country (P2):** Vietnam-only facts are now framed "Ở Việt Nam: …" / "In Việt Nam: …"
  (vaccine schedule, 30-minute wait, zinc for diarrhoea), the fever article states both NICE and BV
  Nhi TW, and the MenB paracetamol line matches NHS. "115" stays in the text for now (the seed test
  requires it in vi doctor callouts); the long-term plan is the `{emergency}` token already used by
  Sơ cứu (`content/first-aid/proposed/README.md`).
- **10 new articles:** `art_bronchiolitis_rsv`, `art_hfmd`, `art_growth_charts`,
  `art_preterm_corrected_age`, `art_picky_eating_toddler`, `art_toddler_milk`,
  `art_toddler_tantrums`, `art_newborn_skin_rashes`, `art_heat_cold_safety`, `art_medicine_safety`
  (44 in all).
- **Stages:** three P3 wording fixes. 24–36 month milestones and stages are drafted for V1.1 in
  `docs/product/content-review-2026-10/library-24-36-months.json`, not imported.
- **For the clinician:** button batteries (NHS nothing by mouth vs US honey for children over 1),
  iron for breastfed babies (AAP 2026 vs NHS), the Vietnamese HFMD exclusion period, the children's
  motorbike-helmet rule, and every help-line number.
