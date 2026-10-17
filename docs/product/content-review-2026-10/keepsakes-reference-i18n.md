# Keepsakes, growth reference and multi-country readiness: localisation review

Reviewer role: localisation lead and baby-brand content designer, with WHO/CDC growth background.
Date: 2026-10-16. Tree: `s2-onboarding` working copy, read-only (other sessions are editing
`apps/portal` and `apps/mobile`, so line numbers there may move). No Firebase, Figma or network
calls were made. Companion file: `../additions/keepsakes.json` (17 new templates, new occasions,
label and text fixes, all as texts only).

Severity used below: **BLOCKER** (wrong or unsafe outside Việt Nam, or broken copy users will see),
**HIGH** (needed before a market opens), **MED** (quality), **OK**.

---

## 0. The ten things to know

1. **The Sơ cứu emergency number is Vietnamese everywhere.** The pack has one `emergencyNumber`
   (`packages/contracts/src/first-aid.ts:151`), the app falls back to `'115'`
   (`apps/mobile/lib/features/first_aid/first_aid_modes.dart:110`), and "115" is written into the
   text 41 times in `content/first-aid/pack.seed.json` (vi and en: "Call 115 now"), 93 times in the
   article seed (`firebase/functions/src/content-seed.ts`) and twice in milestones. A parent in the
   US who taps "Call 115" reaches nobody. Rhythm's health screen and Lumi already do it right (per
   country, no default: `packages/contracts/src/personalization.ts:154-162`,
   `apps/mobile/lib/features/rhythm/health_screen.dart:42-43`). **BLOCKER for any non-VN user,
   including Vietnamese families abroad on day one.**
2. **The vaccine schedule is Việt Nam's** (TCMR + dịch vụ: BCG and hep B at birth, JE at 9/10/24
   months, measles alone at 9 months, VA-Mengoc-BC; `packages/contracts/src/vaccines.ts:4-11,
   48-230`) and is shown to every family. **BLOCKER outside VN.**
3. **The app knows the household's country only if someone set it** in Gói / Nhịp lớn lên
   (D-072 #3; `families/{id}.country`, `packages/contracts/src/entitlements.ts:272-273, 415-425`;
   picker `apps/mobile/lib/features/premium/premium_models.dart:205`, 12 countries, no "Khác").
   Only Lumi, Rhythm health, spending currency and premium read it; Sơ cứu, vaccines, growth,
   articles, milestones and keepsakes ignore it.
4. **No unit system exists**: kg, cm, ml and °C only (input limits `packages/contracts/src/care.ts:20-31`,
   ARB `growthWeightRequired`, `ksBirthStats`). Only Lumi parses "4 oz"
   (`packages/contracts/src/assistant-text.ts:808`). A US birth card reads "3.35 kg · 50 cm".
5. **Unsupported device languages fall back to Vietnamese**
   (`apps/mobile/lib/app/locale.dart:7-8, 52-59`): a German, Thai or Japanese phone opens in
   Vietnamese. Dates are hard-coded day-first in about 30 places (`DateFormat('dd/MM')`, `'d/M'`,
   `'dd.MM.yyyy'`), including the date printed on every keepsake card
   (`apps/mobile/lib/features/keepsakes/keepsake_card_content.dart:14`).
6. **The growth data are correct WHO 2006 values** (spot-checked, §2.2), but the portal's growth
   (and vaccine) tables are **not read by the app**: only `reference_bottle` is
   (`apps/mobile/lib/features/care/bottle_suggestions.dart:106`; growth is hard-coded LMS in
   `who_growth_data.g.dart`). Approving a growth version on `/reference/length` changes nothing,
   although the portal says "App tải bản mới ở lần mở kế tiếp" and P-138 says it should.
7. **The 24-month length → height switch is smeared**: the LMS table jumps from day 730 (length,
   boys 87.80) straight to day 761 (height, 87.97), so days 731–760 interpolate across the 0.7 cm
   step, and the app never asks whether the child was measured lying or standing
   (`apps/mobile/tool/who_growth_data.py:27-28`, `packages/contracts/src/care.ts:61-70`).
8. **No gestational age, so no corrected age**: preterm babies will be flagged "Dưới mức tham
   chiếu" for months (`packages/contracts/src/baby.ts:93-94` has only DOB and gender).
9. **Keepsakes: copy is mostly good in both languages, but the system sentences around it break**:
   nudges produce "Biết bò của Bơ!", "Mia’s Sits up!", "Mia is First birthday today 🎂"-style text
   (ARB `ksNudgeFirst` / `ksNudgeSoon` + chip labels, `app_en.arb:2748-2755, 2801-2804, 2924-2927`),
   the closing signature "Mom & Dad" / "Ba mẹ" is hard-coded in the renderer
   (`apps/renderer/src/compositions/chapter1.tsx:284`), and the English mixes US and UK.
10. **Keepsake occasions stop at the first birthday, and after the planned archive (§6.3 step 5 of
    `docs/product/remember-2-templates.md`) there is no free card for 100 ngày** — one of the four
    nudged occasions (D-068 #9). First tooth, first foods and first word have only the premium C09.

---

## 1. Keepsakes (Kỷ niệm 2.0)

### 1.1 What exists

| Source | Content |
|---|---|
| `packages/contracts/src/keepsakes-seed.ts` | Seed v1: 4 cards (`card_round`, `card_full_photo`, `card_blush`, `card_starry_night`), 4 videos (`first_month`, `first_week`, `hundred_days`, `little_moments`). To be archived (§6.3 step 5). |
| `scripts/src/keepsakes-chapter1.ts` | Chapter 01 cards C01–C12 (welcome, first week, monthly, teddy, blooming, dreamy star, first smile, I can do it, tiny firsts, then & now, 100 days, first birthday). |
| `packages/contracts/src/keepsakes-chapter1-videos.ts` | Videos V01–V12 with ~110 scene hints. |
| `packages/contracts/src/keepsakes.ts:43-71` | 26 occasions: birth, d7, m1–m11, d100, y1 + 10 "firsts". |
| `apps/mobile/lib/l10n/app_vi.arb` / `app_en.arb` `ks*` | Occasion labels, card big titles (`ksTitleY1`), default quotes (`ksQuote*`), achievements, nudges. |
| `scripts/src/seed-keepsakes.ts:205-211` | Music: Ru êm / Hush, Nắng mai / Morning sun, Bình minh / First light, Mơ màng / Daydream, Tiệc vui / Party time — originals, artist "Child Life". |

There are no on-screen music credit lines in videos (artist shows only in the MM07 picker,
`memory_story_screens.dart:2759`); with originals that is fine. When licensed tracks arrive, see
§1.6.

### 1.2 Vietnamese quality

Overall the template copy is natural and warm, in the right register ("ba mẹ", "con"), with good
idioms: "Trăm ngày bình an, trọn đời hạnh phúc", "Lớn thêm một chút, thương thêm thật nhiều",
"Chậm thôi con, ba mẹ muốn nhớ hết". Issues:

| Where | Issue | Fix |
|---|---|---|
| `keepsakes-chapter1-videos.ts:165, 187` "Chuyện tình nhỏ" | "chuyện tình" reads as romance between a couple | "Chuyện thương nhỏ" or "Câu chuyện yêu thương" |
| "Ba & Mẹ", "ba mẹ" throughout; `keepsakes-chapter1-videos.ts:483`; renderer `chapter1.tsx:284` | Northern families say "bố"; single parents, grandparents raising a child | `{parents}` token built from the family's relation chips (R-008: Mẹ, Ba, Bố, Bà…), fallback "ba mẹ". Signature never hard-coded |
| Chip labels "Biết bò", "Biết ngồi", "Đứng vững" vs "Lần đầu biết lẫy" | Mixed forms; inside `ksNudgeFirst` "{occasion} của {name}!" they give "Biết bò của Bơ!" | Noun forms: "Lần đầu biết bò", "Lần đầu tự ngồi", "Lần đầu tự đứng"; and a new nudge frame (json `occasionLabelChanges.firstNudge`) |
| Keepsake vs milestone names | `ksOccM1` "1 tháng" vs `msOneMonth` "Đầy tháng"; `ksOccY1` "Sinh nhật 1 tuổi" vs `msFirstBirthday` "Thôi nôi"; `ksOccFirstWord` "Tiếng gọi đầu tiên" vs `msFirstWord` "Tiếng nói đầu tiên"; `ksOccFirstSolids` "Bữa ăn dặm đầu tiên" vs `msFirstSolids` "Lần đầu ăn dặm" | One name per concept. Recommend "Đầy tháng" and "Thôi nôi" (what Vietnamese families say and celebrate). **Figma MM10 shows "1 tháng" and "Sinh nhật 1 tuổi"** (`docs/discovery/figma-extract/29-remember-2.md:120`), so this needs an owner decision |
| Nudge "Hôm nay {name} tròn {occasion} 🎂" with m1 | Correct but flat; Vietnamese say "Hôm nay Bơ đầy tháng!" | Per-occasion phrase (json `ageNudgePhrase`) |
| "Nhìn con làm được nè" (C08) | "nè" is Southern colloquial; fine as playful, slightly regional | Keep, or "Nhìn con làm được này!" if the owner wants neutral |

Cultural notes for VN (not bugs): đầy tháng and thôi nôi are still often dated by the **lunar
calendar** and đầy tháng is sometimes held as "đầy cữ"; the app counts Gregorian DOB + 1 month
(`keepsake_occasions.dart` `dateFor`). A later "Tính theo âm lịch" option per family is worth it; the
Vietnamese lunar calendar must be computed at UTC+7, not with a Chinese (UTC+8) library, or some
dates differ by a day. Cards must stay secular: no altar, offering tray or "Mười hai bà Mụ" imagery.
C11's seal carries only the numeral "100" (spec §3 C11) — keep it free of Chinese characters.

### 1.3 English quality

Good, idiomatic defaults ("A little bigger, loved a lot more", "Slow down, we want to remember it
all", "Keep smiling, little sunshine!"). Issues:

- **US and UK mixed in one catalog**: "Mom & Dad", "With Mom", "diaper", "crib" (US) next to
  "favourite", "colours", "Watercolour" (UK) in keepsakes, and "Mum" in the app ARB
  (`tourShareChipMom` "by Mum"), "cot" in Rhythm content, "crib" in articles. Pick one base. I
  recommend **`en` = US spelling and words** (largest English market and diaspora) with an
  **`en_GB` overlay** (Flutter falls back from `en_GB` to `en`) used for GB, AU, NZ, IE, SG, MY.
  Only a few hundred strings differ (Mum, nappy, cot, pram, nursery, paediatrician, colour,
  favourite, -ise). The keepsake `{vi, en}` schema (`keepsakes.ts:79`) would need an optional
  `en_GB` key.
- Chip labels used as nouns break nudges: "Sits up", "Stands up", "First meal" (should be "First
  foods"), "First roll"; `ksTitleY1` "1 year" gives "Mia is 1 year today". Proposed set in json
  `occasionLabelChanges`.
- Straight vs curly apostrophes mixed (`keepsakes-chapter1.ts:1231` "you've" vs
  `keepsakes-chapter1-videos.ts:268` "you’ve"; `{name}'s` in the seed): on a printed card in
  Playfair/Lora the straight one looks like a typo. Use ’ everywhere.
- "Little love story" is fine in English; "Welcome, little one" is both the name and the title of
  C01 (harmless).
- Dates on cards: the spec says en = "MMM d, yyyy" (`remember-2-templates.md` §1.4) but the app
  prints `dd.MM.yyyy` for every locale (`keepsake_card_content.dart:14`,
  `memory_story_screens.dart:63`). 03.04.2026 is 3 April to a Vietnamese or British reader and
  March 4 to an American. On a picture that is shared forever, use a spelled month: en-US "April 3,
  2026", en-GB "3 April 2026".

### 1.4 Occasions across markets: proposed set and English names

| Occasion | VN | Western (US/UK/AU/CA) | East/SE Asia | Proposal |
|---|---|---|---|---|
| Birth / announcement | báo tin | birth announcement (very strong in US, with lb/oz + inches) | everywhere | keep; unit-aware `birthStats` |
| 7 days | not a VN rite; nice "first week" | "one week" | JP お七夜 oshichiya (naming, 7th night, birth day = day 1, so DOB+6) | keep; en "One week" |
| 1 month | **Đầy tháng** (major) | "one month" | CN/SG/MY "full month" (满月, red eggs), KR 삼칠일 (21 days, minor) | vi "Đầy tháng", en "One month"; SG/MY English variant "Full month". **Not "Full moon"** (reads astronomical in the West; only SG/MY English uses it for the party) |
| 100 days | 100 ngày (popular, modern) | not a tradition; still cute ("100 days of you") | KR 백일 baek-il (big), JP お食い初め okuizome (first meal ceremony), CN 百日 | keep; for KR/JP the day count starts at 1 on the birth day (DOB+99) — make counting a per-region rule when those markets open (verify with native reviewers) |
| 6 months | — | US "half birthday" | — | add alias "Nửa năm" / "Half birthday" (en_GB "Six months") |
| 1 year | **Thôi nôi** (biggest), bốc đồ / thử tài | first birthday, smash cake | KR 돌 dol + doljabi, CN 抓周 zhuazhou, JP 一升餅 isshō-mochi | vi chip "Thôi nôi", en "First birthday"; add the pick-game card (works for VN, KR, CN/TW/SG/MY) |
| 2 and 3 years | sinh nhật | birthdays | birthdays | **add** (the app tracks to 5 years) |
| Festivals | Tết, **Trung thu (children's festival)** | holiday season (secular framing) | Lunar New Year, Mid-Autumn, Chuseok | Tết + Trung thu for vi culture and LNY markets; one neutral "First holiday season" that parents retitle |
| Religious rites | cúng đầy tháng / thôi nôi (folk rite) | baptism, christening, naming, bris | aqiqah, mundan | **No templates**; the neutral card and editable titles cover them |
| Firsts | all | all | all | add first bath, outing, meeting grandparents (presets already exist: `p_first_bath`, `p_first_outing`, `p_meets_grandparents`), first trip, first haircut, first day at daycare |

Two axes matter here and should not be confused: **country** decides laws, numbers, schedules and
units; **family culture (in practice the UI language, or an explicit "truyền thống nhà mình"
setting)** decides occasions like Tết, đầy tháng and thôi nôi. A Vietnamese family in Texas wants
Tết and thôi nôi and also 911, lb/oz and the CDC vaccine schedule.

### 1.5 Missing for launch (drafted in `additions/keepsakes.json`)

Free gaps that hurt now:
- `card_hundred_days_simple` (d100) — after the archive every d100 card is premium (C04, C05, C06,
  C10, C11); under `premium.access: 'subscribers'` the 100-day nudge would end on a paywall.
- `card_first_tooth`, `card_first_foods`, `card_first_word` — today only premium C09.
- `card_full_month` (Đầy tháng), `card_half_birthday`, `card_second_birthday`, `video_year_two`,
  and either `y2`/`y3` occasions or m13–m23 on C03 (cheapest, json `monthlyExtension`).

Cross-market additions: `card_thoi_noi_pick`, `card_first_bath`, `card_meets_grandparents`,
`card_first_trip`, `card_first_haircut`, `card_first_daycare`, `card_first_tet`,
`card_first_mid_autumn`, `card_first_holidays`. All need artwork (listed per template under
`x_artwork`) and new milestone presets where marked `x_newPreset`.

Content-safety notes on new art (in the json): no honey, whole nuts, whole grapes or popcorn on the
first-foods card; bath card frames the face with foreground bubbles and a one-line sharing tip; no
GPS/EXIF place on trip cards and no location metadata in exports; no candle-lit lantern next to the
baby; no snow in the summer variant (AU/NZ/SG/southern VN); Vietnamese zodiac has the Cat where the
Chinese has the Rabbit, so no Chinese zodiac art on Tết by default.

### 1.6 Contract and system changes keepsakes need

1. `regions` (and optional `culture`) on templates and occasions (`keepsakes.ts:327-338`): suggest
   the Tết card in VN/SG/MY/TW/KR/HK and to vi-language families anywhere.
2. New occasions (json `proposedOccasions`) — the occasion enum is compiled into the contract and the
   Dart enum, so each is an app release; consider moving occasion labels into the published catalog.
3. `{parents}` text token; optional `en_GB` in `localized()`.
4. Nudge sentences per occasion (json `ageNudgePhrase`) instead of `{occasion}` slotted into one frame.
5. Music licence (`keepsakes.ts:167-176`): add `territories` and user-distribution rights, and buy only
   tracks not in YouTube Content ID / Meta Rights Manager, or parents' exports get muted or claimed.
   The briefs in `remember-2-templates.md:1394-1402` use moods (`romantic`, `uplifting`, `cinematic`)
   that are not in `keepsakeMoods` (`keepsakes.ts:139`).

---

## 2. Growth reference (`/reference/length`, app 20d / 20i)

### 2.1 Dataset and generation

- **Source**: WHO Child Growth Standards (2006), LMS by day of age 0–1856 from the WHO `anthro`
  repository (`weianthro`, `lenanthro`, `hcanthro`), written into
  `apps/mobile/lib/features/care/who_growth_data.g.dart` by `apps/mobile/tool/who_growth_data.py`
  (daily to 91 d, weekly to 730 d, then monthly to 60 mo; linear interpolation of L, M, S between
  rows, `who_growth.dart:38-61`).
- **Indicators**: weight-for-age, length/height-for-age, head circumference-for-age (HC added
  2026-10-16). **Not present**: weight-for-length/height, BMI-for-age, arm circumference,
  subscapular/triceps skinfolds. Weight-for-length is the indicator WHO and paediatricians use for
  wasting/overweight under 2; BMI-for-age from 2 years. Neither is required for a parent app, but
  without them a heavy-but-long or light-but-short baby is judged on weight-for-age alone.
- **Band**: P3–P97 (z = ±1.8808, `who_growth.dart:20-24`), z-score computed by LMS
  (`who_growth.dart:82-95`). Reasonable for parents (WHO clinical cut-offs are ±2 SD = P2.3/P97.7).
- **Portal tables** (`packages/contracts/src/who-reference.g.ts`, generated by
  `packages/contracts/scripts/who-reference.mjs` from the same Dart LMS): P3/median/P97, weekly 0–13 and
  monthly 0–60, weight and length only. **Head circumference is missing from the portal datasets**
  (`packages/contracts/src/reference.ts:12-17`).

### 2.2 Spot-check against WHO tables (median, cm; boys / girls)

| Age | WHO (length 0–24, height 24+) | Repo (`who-reference.g.ts`) | Verdict |
|---|---|---|---|
| 0 mo | 49.9 / 49.1 | 49.88 / 49.15 | OK |
| 6 mo | 67.6 / 65.7 | 67.64 / 65.75 | OK (+0.02 from day rounding) |
| 12 mo | 75.7 / 74.0 | 75.74 / 74.00 | OK |
| 24 mo **length** | 87.8 / 86.4 | 87.81 / 86.41 | OK — the repo's 24-month row is **length** |
| 24 mo **height** | 87.1 / 85.7 | not shown | the values in the brief are the height row; the repo has no height row at 24 mo |
| 36 mo height | 96.1 / 95.1 | 96.09 / 95.06 | OK |
| 60 mo height | 110.0 / 109.4 | 109.96 / 109.42 | OK |
| Boys length P3 / P97 at birth | 46.3 / 53.4 | 46.32 / 53.44 | OK |
| Weight median 0 / 6 / 12 mo, boys | 3.3 / 7.9 / 9.6 kg | 3.35 / 7.94 / 9.65 | OK |
| Weight median 12 mo, girls | 8.9 kg | 8.95 | OK |
| Weight median 60 mo, boys | 18.3 kg | 18.34 | OK |
| HC median at birth, boys / girls | 34.5 / 33.9 | 34.46 / 33.88 (Dart LMS) | OK |

Conclusion: the numbers are right to ±0.02 (rounding of 30.4375-day months to whole days). Q-045's
"import WHO only" stance is right; nobody should be typing these.

### 2.3 Problems

| # | Problem | Where | Severity | Fix |
|---|---|---|---|---|
| G1 | Portal growth and vaccine versions are never read by the app; only bottle is | `ReferenceRepository` used only by `bottle_suggestions.dart`; growth = hard-coded LMS; P-138 says otherwise | HIGH (staff believe they publish) | Either wire the app to `reference_growth_*` (and carry LMS rows, not P3/P50/P97, so z-scores survive) or mark the growth tabs read-only "Bản gói sẵn trong app" and change `reference.confirm.approve.note` for them |
| G2 | 24-month switch smeared over days 730→761 | `who_growth_data.py:27-28` (days list has 730, then 761) | MED | Add day 731 (first height row) so the step is sharp; label the 24-mo rows "24 tháng (nằm)" and "24 tháng (đứng)" in the portal |
| G3 | No measurement position | `growthDataSchema`, `care.ts:61-70` | MED | Optional `position: 'lying' \| 'standing'`; WHO rule: standing under 731 d → +0.7 cm, lying from 731 d → −0.7 cm before the z-score. Default by age when absent |
| G4 | "Chiều dài" label after 2 years | portal `messages.ts:1353`, app `whoBelowLengthNote`… | MED | "Chiều dài / chiều cao" ("Length / height"); after 24 mo the note says "chiều cao" |
| G5 | No gestational age / corrected age | `baby.ts:93-94` | HIGH for preterm families | Optional "Bé sinh lúc … tuần" in the profile; under 37 weeks use corrected age for the band and chart until 24 months (common practice; some units go to 36 months for < 28 weeks); before term-equivalent age show no WHO band (INTERGROWTH-21st preterm postnatal standards or Fenton apply there; check licensing before using either). Show "Tuổi điều chỉnh: 3 tháng 1 tuần" next to the age |
| G6 | Units kg/cm only | everywhere | HIGH for US, MED for UK/CA | §3.5 item 6 |
| G7 | Head circumference has no portal dataset | `reference.ts:12-17` | LOW | Add `growth.head` if G1 is wired |
| G8 | Gender "unspecified" defaults to the boy table on 20i | `growth_standards_screen.dart:74` | LOW | Fine with a visible toggle; never show a band in history without a sex (already the case) |

### 2.4 Asian and other national charts

- **WHO 2006 is the right default** for Việt Nam (Bộ Y tế uses WHO 2006) and for 0–2 years in
  most target markets. **US**: CDC recommends WHO for 0–2 and the CDC 2000 charts from 2 years
  (with the 2022 extended BMI charts). **UK**: the "UK-WHO" charts (WHO from 2 weeks to 4 years,
  UK90 at birth and for preterm) in the Red Book. **Japan**: national 乳幼児身体発育曲線 from the MHLW
  survey (2010 data; a newer survey was run — verify the current edition), printed in the 母子手帳.
  **Korea**: the 2017 KDCA charts use WHO under 3 years and Korean data from 3 years. **Singapore**:
  HPB charts — I could not confirm which reference the current Health Booklet uses (verify).
  **Australia/NZ**: WHO 0–2 (CDC from 2 in many services; verify state practice).
- Recommendation: keep WHO for everyone in V1, label it clearly ("Theo chuẩn WHO; bác sĩ của bé có
  thể dùng biểu đồ của nước bạn"), and add a `standard` field (`who2006`, `cdc2000`, `jp`…) on the
  dataset so a country can switch after 24 months later. The visible difference before 2 years is
  small; after 2 years US/JP/KR charts differ enough that parents will compare against the clinic
  booklet and ask why.

### 2.5 Units for US/UK users

- **US**: weight in lb + oz (birth and infancy), length in inches (to 1/4 in or 0.1 in), head in
  inches, temperature °F, volume US fl oz (29.57 ml).
- **UK**: kg in the Red Book, but parents still quote birth weight in lb/oz; length cm; °C; fl oz
  rarely, and UK fl oz is 28.41 ml (not the 29.57 that Lumi uses, `assistant-text.ts:808`).
- **Canada**: metric officially, lb/oz common for babies; °C. **AU/NZ/SG**: metric throughout.
- Store SI only, convert at display and input, show the other unit in the 20i table header, keep the
  band computed in SI. Rounding rules: lb/oz to the nearest ounce, inches to 0.25 in, °F to 0.1.

---

## 3. Multi-country readiness

### 3.1 How the app knows language, country and units today

| Axis | Source | Used by | Gap |
|---|---|---|---|
| Language | device, override in Tôi → Ngôn ngữ (`locale.dart`) | all UI | vi/en only; **fallback is vi**; no en_GB |
| Format region | none (DateFormat is given only the language, often hard-coded patterns) | — | US sees day-first dates |
| Household country | asked, never inferred (D-072 #3); `setFamilySettings` | Lumi emergency number, Rhythm health, entitlements regions, spending currency (`spending.ts:97-118`) | not asked at onboarding; 12-country picker without "Khác"; ignored by first aid, vaccines, growth, articles, milestones, keepsakes |
| Units | none | — | metric hard-coded |
| Time zone | family/baby zone (`inBabyZone`) | reminders, Lumi | OK |

### 3.2 Matrix: content area × issue

| Area (source) | Hard-coded VN numbers / law | VN-only schedule or practice | Languages | Units | Date formats | Culture | Region field today |
|---|---|---|---|---|---|---|---|
| **Sơ cứu** (`content/first-aid/pack.seed.json`, `first-aid.ts`) | **BLOCKER**: "115" ×41 in text + single `emergencyNumber` + app fallback `'115'`; no poison-control line (US 1-800-222-1222, UK NHS 111, AU 13 11 26) | **HIGH**: CPR/choking/burns follow one guideline set. ANZCOR uses chest thrusts (not abdominal) for choking children; AHA and ERC differ on sequences and breath counts; burns cooling 20 min (ANZCOR/UK) vs "10+ min" (some US sources). Needs per-region review, not just translation | vi/en | °C ×6 (fever thresholds) | `review.reviewedOn` shown as MM/yyyy (`library_widgets.dart:98`) | "Uống nhầm thuốc → Gọi 115 ngay" is right for VN; in US/UK/AU the first call is poison control unless symptomatic | none (one pack) |
| **Nhịp lớn lên** activities, age cards, health pack (`content/rhythm/content.seed.json`, `personalization.ts`) | OK: per-country emergency table (12 countries) | age cards global | vi/en per item (`locales`) | °C ×36 | — | "Wonder Weeks" stage labels need a rights check per market (D-072 #7) | activities `regions` (all empty = global), recipes `regions` (required), age cards none |
| **Articles + Giai đoạn** (`firebase/functions/src/content-seed.ts`, 34 articles, 16 stages) | **BLOCKER**: "115" ×93; Thông tư 13/2026 30-minute post-vaccine wait; "Always boil in Việt Nam" | **HIGH**: motorbike safety (×25), cạo gió, dengue, VN myths section; diaspora still wants the myths, US English users do not | vi/en | °C ×80, ml | — | myths block is culture, not country | **none** on articles/stages |
| **Milestones** (`content/milestones/milestones.seed.json`) | MED: 2× "115 in Việt Nam" | OK: CDC 2022 / WHO MGRS windows are global | vi/en | — | — | OK | none (fine: global) |
| **Vaccines** (`packages/contracts/src/vaccines.ts`, `vaccine_schedule.g.dart`) | VN programme names ("Tiêm chủng mở rộng" → en "Free programme") | **BLOCKER**: VN-only schedule (BCG at birth, JE, measles 9 mo, MenBC); UK (8/12/16 weeks, MenB), US (2/4/6 months, HepB series), AU (NIP 6 weeks start), SG (NCIS), CA (per province) all differ | vi/en | — | — | — | none; portal dataset not read by the app |
| **Growth reference** | — | OK: WHO is global (§2.4 for national charts after 2 y) | vi/en | **HIGH**: kg/cm only | — | — | none |
| **Bottle quick picks** (`reference.ts:98-104`) | — | OK | — | ml only (US fl oz) | — | — | none |
| **Keepsakes** (`keepsakes*.ts`, ARB `ks*`) | — | occasions VN-centric (fine), stops at y1 | vi/en; en US/UK mixed; renderer locale `'vi' \| 'en'` only (`apps/renderer/src/kit/core.tsx:50`) | `birthStats` kg/cm | `dd.MM.yyyy` printed on cards; nudge `d/M` | "Mom & Dad"/"Ba mẹ" hard-coded; Tết/Trung thu missing | none |
| **Lumi** (assistant) | OK: emergency from country; REGION_UNSUPPORTED exists | recipes by region | vi/en | parses oz; replies in ml/kg | — | — | via country |
| **Spending** | VND default when no country | — | — | currency by country | `dd/MM` ×10 | — | via country |
| **App shell** | — | — | **vi fallback** for other languages | — | ~30 hard-coded patterns | — | — |

### 3.3 Which countries, in which order

Approximate figures from memory (births per year, latest available; Vietnamese-origin population);
verify before a business case.

| Market | Births / yr | Vietnamese diaspora | IAP spend | Language cost | Regulatory / medical risk | Verdict |
|---|---|---|---|---|---|---|
| Việt Nam | ≈1.4 M | — | low | none | VN PDPL (Law 91/2025, in force 2026) + Decree 13/2023: parental consent, cross-border transfer dossier because data sit in `asia-southeast1` (Singapore) — verify with counsel | **Now** |
| United States | ≈3.6 M | ≈2.2–2.3 M (largest) | highest | none (en-US base) | FDA: first-aid reference, symptom checklists and tracking fall under enforcement discretion when they inform and route to care; state health-privacy laws (Washington MHMDA, CCPA "sensitive PI"), Illinois BIPA/Texas CUBI for the on-device face matching in auto-save; class-action climate | **Phase 1 (vi diaspora) → Phase 2 (English)** |
| Canada | ≈0.35 M | ≈0.25–0.3 M | high | **French needed for Québec** (Charter of the French language / Bill 96) | PIPEDA, Québec Law 25; vaccine schedules are **provincial** | Phase 1 diaspora (English provinces), English later than US |
| Australia (+NZ) | ≈0.29 M (+0.06) | ≈0.3 M | high | en-GB overlay | TGA SaMD rules (2021): check whether symptom routing is excluded — verify; Privacy Act (health info sensitive) | **Phase 2 English pilot** (metric, single NIP, clean legal picture) |
| Singapore | ≈0.03 M | small | high | en-GB overlay | PDPA; HSA SaMD guidance | Phase 2 with AU (also full-month / 100-day culture) |
| United Kingdom | ≈0.66 M | ≈0.05–0.1 M | high | en-GB overlay | UK GDPR (health = special category, DPIA, explicit consent); MHRA software-as-medical-device scope | Phase 2b |
| Japan / Korea / Taiwan (diaspora) | 0.69 M / 0.24 M / 0.13 M | ≈0.6 M / ≈0.3 M / ≈0.3 M (many Vietnamese mothers in multicultural families in KR/TW) | high | vi UI is enough for the mother; the partner may need ja/ko/zh-TW later | APPI / PIPA (strict consent for overseas transfer) / PDPA-TW | **Phase 1 diaspora** for the country safety layer only (emergency 119, local schedules in vi/en) |
| Germany / France (diaspora) | 0.68 M / 0.66 M | ≈0.2 M / ≈0.3 M | medium | vi/en enough for diaspora | **EU MDR Rule 11**: personalised symptom triage could be class IIa; GDPR Art 9 + Art 27 EU representative; SCCs for Singapore storage | Phase 3, diaspora only, after an MDR qualification opinion |
| Philippines / Malaysia | ≈1.4 M / ≈0.4 M | small | low | English works (fil/ms optional) | moderate | Phase 3 |
| Indonesia / Thailand | ≈4.4 M / ≈0.46 M | small | low | id / th translation + medical review | moderate | Phase 4 |

Why this order: Vietnamese families abroad are the cheapest real expansion (no new UI language;
the brand, tone and occasions already fit) and they hit exactly the country-specific layer that is
missing today, so fixing it for them is the same work an English launch needs. English markets
then need only the en-GB overlay, units, region-reviewed first aid and schedules. AU/NZ/SG before
the US because they are metric, Commonwealth English and legally simpler; the US is the biggest
prize but needs imperial units, a US-reviewed first-aid pack and a state-privacy/biometrics review.
Germany and France wait on an MDR opinion; Indonesia and Thailand on translation cost.

Store and medical-claim posture for every market: Apple guideline 1.4.1 (medical apps reviewed
with greater scrutiny; disclose data and methodology for health measurements; remind users to see a
doctor) — the app already cites WHO and says "trao đổi với bác sĩ"; keep "Bình thường" as "Trong
khoảng tham chiếu" / "Within the reference range" rather than "Normal". Google Play's health-apps
declaration applies too. Keep first aid and the health pack as **general information that routes to
emergency services**, never "con an toàn" (the disclaimer already says so), never dosing, and
never personalised diagnosis; that is what keeps it out of FDA device scope and lowers MDR risk.
COPPA is not triggered by parents entering data about their baby (it covers data collected from a
child), but the state laws above are.

### 3.4 Minimum content-architecture changes

1. **Country on every family, asked at onboarding** for new families (one screen after the baby
   profile; "Bạn đang sống ở đâu?"), with a full ISO list and "Khác"; existing families keep D-072
   #3's ask. Owner decision needed (extends D-072 #3).
2. **One reviewed region table** (`publicConfig/regions`, two-person approval like reference data):
   per country `ambulance`, `poison`, `healthLine` (UK 111, AU healthdirect), `units` defaults,
   `vaccineSchedule` id, `growthStandard`, `firstAidVariant`, enabled content. Replace
   `firstAidPackSchema.emergencyNumber` (`first-aid.ts:151`) and the health pack's own `regions`
   (`personalization.ts:154-162`) with it. Number fields must allow `1-800-222-1222` (today's
   regex is `^\d{3,4}$`).
3. **Tokens instead of numbers in text**: `{emergency}`, `{poison}`, `{healthLine}` in first aid,
   articles, milestones, Lumi copy; a content test fails on any literal 115/911/999/112 in text.
   When the country is unknown, never dial a default: show "Gọi số cấp cứu nơi bạn ở" with a one-tap
   country picker (fixes `first_aid_modes.dart:110`; matches the Rhythm health screen).
4. **`regions` (and `excludeRegions`) on content items**, empty = global, on articles, stages, first-aid
   situations and variants, age cards, keepsake templates and occasions; optional per-region text
   overrides on a variant (e.g. choking steps for AU, poison steps for US). Separate **`culture`**
   tags (vi) for VN practices and occasions, matched to the UI language or a family setting.
5. **Vaccine schedules per country**: `reference_vaccines_{CC}`; generalise `vaccineProgrammes`
   (`public`, `optional`, `atBirth`, `choice`) with per-country labels ("Tiêm chủng mở rộng" only
   for VN); no schedule for a country = free logging, no reference timeline, no "mũi kế tiếp".
6. **Units**: display preference per device, default from country (US imperial, GB weight lb/oz
   optional, rest metric); weight kg | lb-oz, length cm | in, temperature °C | °F, volume ml | US fl oz
   | UK fl oz. Store SI only; one conversion module in Dart and TS (Lumi, portal, renderer).
   Temperatures in content as tokens (`{temp:38.0}`) so "38 °C" renders "100.4 °F".
7. **Locale**: fall back to `en`, not `vi`, for unsupported device languages; add `en_GB`; pass the
   full device locale (language + region) to `DateFormat` skeletons (`yMd`, `MMMd`, `yMMMMd`)
   instead of the ~30 hard-coded patterns.
8. **Growth**: `standard` on datasets, measurement position, gestational age (§2.3).
9. **Keepsakes**: §1.6.

### 3.5 Phased plan

**Phase 0 — before the VN production launch (no new market, but stop shipping VN assumptions as
code)**
- First aid: `{emergency}` token in the seed text, region table with VN only, no `'115'` fallback
  in code (VN families get 115 from the table). Same token in articles and milestones.
- Locale fallback to `en`; card dates and the nudge date locale-aware; English base = US, fix the
  mixed spellings in keepsakes; nudge sentence fixes; `{parents}` token.
- Keepsakes: free d100, first tooth / foods / word cards; decide "Đầy tháng" / "Thôi nôi" naming.
- Portal: say plainly that growth (and vaccine) tables are bundled in the app until G1 is built.
- Growth: add the day-731 row (one-line change in the generator plus regenerate).

**Phase 1 — Vietnamese families abroad (vi UI) in US, CA (English provinces), AU, JP, KR, TW**
- Country asked at onboarding; region table rows for those countries (ambulance, poison, health
  line) reviewed by someone who checks each number.
- Vaccine schedules for US (CDC/ACIP), AU (NIP), CA (one province first, e.g. Ontario), JP, KR, TW
  — written in vi/en, reviewed by a clinician per country; others get free logging.
- Units (US imperial), °F; measurement position; gestational age and corrected age.
- First-aid region variants where guidelines differ (choking, CPR sequence, burns, poisoning).
- Articles: `regions` / `culture` on items; VN-law sentences tagged VN.
- Keepsakes: Tết, Trung thu, meeting the grandparents, first trip.
- Legal: US state health-privacy and biometrics review (auto-save face matching), APPI/PIPA
  transfer consent; VN cross-border dossier.

**Phase 2 — English launch: AU + NZ + SG first, then US + CA, then UK + IE**
- en_GB overlay; store listings; a native English copy pass on all content (today drafted by
  engineering).
- Medical review of first aid and articles per region (Resuscitation Council UK / ANZCOR / AHA–Red
  Cross); Apple 1.4.1 and Play health declarations.
- Keepsakes: neutral holiday card, half birthday, second birthday and year-two video, unit-aware
  birth card.
- Growth: optional CDC 2000 after 24 months for US, UK-WHO note for UK.

**Phase 3 — PH, MY; EU diaspora (DE, FR)** after an EU MDR qualification opinion on symptom
routing, GDPR DPIA and an EU representative. **Phase 4 — ID, TH, and ja/ko/zh-TW UIs**, each with
native medical reviewers and national growth charts.

---

## 4. What I could not verify

- Birth counts, diaspora sizes and the regulatory statements in §3.3 are from memory, not from
  sources opened today; the SG growth-chart reference, the current Japanese chart edition, AU state
  practice after 2 years, TGA treatment of symptom routing and VN PDPL transfer rules all need a
  check by someone with the current documents.
- Day-count conventions (KR baek-il, JP okuizome/oshichiya, VN 100 ngày and lunar-dated đầy tháng /
  thôi nôi) should be confirmed with native reviewers before they become rules.
- I did not run the app, the renderer or any test; line numbers in `apps/mobile` and `apps/portal`
  may have moved because other sessions are editing those trees.
- I did not read all 7,747 lines of `content-seed.ts` or every first-aid step; counts of "115", °C,
  "motorbike" etc. are grep counts.
- I did not check Figma for keepsake screens beyond the saved extraction
  (`docs/discovery/figma-extract/29-remember-2.md`).
- Emergency numbers in the Rhythm health pack (VN 115, US/CA 911, GB 999, AU 000, NZ 111, SG 995,
  DE/FR 112, JP/KR/TW 119) match my knowledge; poison and health-line numbers quoted above should be
  re-checked before they are published.
