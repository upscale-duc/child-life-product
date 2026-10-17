# Child Life content review: Thư viện chăm bé, Giai đoạn của bé, Mốc phát triển

Reviewed 2026-10-16 in the roles of paediatrician, IBCLC and developmental specialist. **This is an editorial draft, not a clinical certification.** Nothing here replaces the signed review that `contentReviewSchema` / B03 needs before prod.

Scope read: `firebase/functions/src/content-seed.ts` (34 articles, 16 stages, vi + en), `content/milestones/milestones.seed.json` (56 items, `mst_20261015_02`), the schemas in `packages/contracts/src/{content,milestones}.ts`, the two seed tests and both SEED-NOTES. Drafts are in `../additions/library.json`. They are checked by a scratchpad script that runs the same rules as `content-seed.test.ts` and `milestones.test.ts` against the repo's built `@child-life/contracts`, and all checks pass.

Overall: the library is unusually careful. It cites sources, names where guidance bodies disagree, corrects local practices without blaming parents, and routes emergencies to Sơ cứu. **I found no P0 (likely-harm) error.** The findings below are mostly guidance that has gone out of date, wording that can be misread, Việt Nam-only content written as if it applied everywhere (the main blocker for going multi-country), and gaps.

---

## 1. Executive summary: top 10 issues

1. **Breast engorgement and mastitis advice is out of date (P1).** `art_breastfeeding_start` says to use warmth before feeds and to stroke "from the lump towards the nipple". ABM Clinical Protocol #36 (2022) advises against heat and deep massage. It recommends cold packs, very light lymphatic strokes towards the armpit, no over-expressing and NSAIDs. → F01, replacement drafted.
2. **One English safe-sleep bullet reads as "do not use sleep sacks" (P1).** `art_safe_sleep`: "Do not use weighted blankets, sleep sacks or swaddles". Two bullets earlier the article recommends sleep sacks. → F04.
3. **The never-bed-share list leaves out "extremely tired" (P1).** NHS and Lullaby Trust both list it, and exhausted parents falling asleep is the main real-world risk. → F05.
4. **G6PD advice leaves out naphthalene mothballs (băng phiến) (P1).** G6PD deficiency is common in Việt Nam and South-East Asia, and mothballs used on baby clothes are a classic trigger for haemolysis. → F13.
5. **Language and social "talk to the doctor" ages run 2 months behind the CDC act-early age (P1).** `says_three_words` and `checks_back` use 20 months where CDC uses 18. Early referral matters most for social-communication signs, so drop the +2 rule for these items. → F20.
6. **The emergency number is hardcoded (P2, multi-country blocker).** "115" appears **45× in vi and 47× in en across 29 of 34 articles** (35 vi blocks), plus 1 milestone. It is not in any stage. 16 articles add an English gloss "(Vietnam emergency)". The test `health articles name the Vietnamese emergency number` locks this in. → §3 convention and the token proposal.
7. **Việt Nam programmes are written as universal (P2).** This covers the EPI schedule and BCG care, the 30-minute post-vaccine wait (it is Việt Nam law; most countries use about 15 minutes), the 38.5 °C medicine threshold, routine zinc, the car and motorbike law, and every help line. UK readers are also told the opposite of NHS advice on paracetamol after MenB (UKHSA advises giving it straight after the 8- and 12-week doses). → F07–F12, F14.
8. **Guidance diverges and a clinician must choose (P2).** Two cases. Button battery: NHS says nothing by mouth; the US poison centre says honey for children ≥ 1 year on the way to hospital. Iron for breastfed babies: the AAP 2026 report says from about 4–6 months; NHS and European practice do not supplement healthy term babies routinely. The text now states both and stays true either way. → F06, F10.
9. **English house style is inconsistent (P3).** D-012 says British spelling, yet the English uses "diaper" 80×, "crib" 42×, "pacifier" and "stroller", with "Mom" next to "Mum" and "favor/diarrhea/pasteurized" next to "colour/diarrhoea". "Vietnam" in the articles sits beside "Việt Nam" in the milestones. Myths are written in three styles ("→ … →" in 9 articles, "Nên:" in 5, plain sentences in the rest). Some source labels do not match their URLs. The product also speaks in a clinical voice once ("Child Life khuyên…", F21). → F15–F19, F21–F24.
10. **There are gaps for 0–24 months (P1/P2).** Nothing on bronchiolitis or RSV (the commonest reason a baby under 1 is admitted), giving medicines safely, growth charts, preterm babies and corrected age, carbon monoxide from charcoal braziers during ở cữ, newborn skin and rôm sảy, fussy eating, toddler milk, tantrums, or a standalone hand, foot and mouth article. **10 complete articles are drafted** (§6). I also recommend extending milestones and stages to 36 months in V1.1, with 12 milestones and 2 stages drafted.

---

## 2. Findings table

Severity: **P0** likely harm · **P1** wrong, outdated or misleading · **P2** multi-country / regional · **P3** tone, typo, consistency. "R#" is the index in `additions/library.json → replacements` (0-based). Every R entry carries the current text, the full new vi and en, the path, and `readingMinutesAfter` where the edit moves the reading time.

| ID | Item · field / block | Sev | Current text (excerpt) | Proposed vi / en (the change) | Source |
|---|---|---|---|---|---|
| F01 | `art_breastfeeding_start` · body[10].items[1] and [2] | P1 | "Chườm ấm trước khi bú, chườm mát giữa các cữ" / "xoa nhẹ từ cục về phía núm vú" | vi: "…chỉ vắt đủ cho dễ chịu, không cố vắt kiệt. Chườm mát hoặc túi lạnh bọc khăn giữa các cữ…; tránh chườm nóng lâu" · "không bóp nặn hay xoa bóp mạnh vào cục cứng. Chỉ vuốt rất nhẹ… về phía nách, chườm mát, hỏi bác sĩ về thuốc giảm đau, chống viêm…" / en: "…not to empty the breast. Use cool packs… avoid prolonged heat" · "do not squeeze or massage the lump hard… very light strokes… towards the armpit…" (R0, R1). The NHS breast-pain source is replaced by ABM | ABM Protocol #36, Breastfeed Med 2022;17:360 (bfmed.org/protocols) |
| F02 | `art_breastfeeding_start` · "What to watch" diapers, and the same-day callout | P3 | "from day 5 at least 6 heavy wet diapers"; "see a doctor the same day if from day 5 fewer than 6" | NHS: day 5–6 ≥ 5, day 7+ ≥ 6. Suggest "từ ngày 5–6 ít nhất 5 tã, từ ngày 7 ít nhất 6" / "days 5–6 at least 5, from day 7 at least 6". The current wording is safe but triggers extra visits | NHS "Is my baby getting enough breast milk?" |
| F03 | `art_breastfeeding_start` · body[17] doctor callout | P3 | en has "Call 115 (Vietnam emergency) too if you, the mother…", which vi does not have | vi "Cũng gọi 115 nếu mẹ thấy rất mệt…" / en "Call too if you, the mother…" (R2) | parity |
| F04 | `art_safe_sleep` · body[5].items[6] (en) | P1 | "Do not use weighted blankets, sleep sacks or swaddles" | en "weighted blankets, weighted sleep sacks or weighted swaddles"; vi "chăn, túi ngủ hay đồ quấn có gắn vật nặng" (R3) | AAP 2022 safe sleep |
| F05 | `art_safe_sleep` · body[8].items[3] | P1 | the never-bed-share list leaves out exhaustion | add "hoặc đang quá mệt" / "or is extremely tired" (R4) | NHS SIDS; Lullaby Trust |
| F06 | `art_solids_choking_safety` · body[14] doctor callout | P2 | "Gọi 115 ngay; trong lúc chờ, không cho bé ăn uống…" | "…không cho bé ăn uống gì trừ khi nhân viên y tế hay trung tâm chống độc hướng dẫn. Ở Mỹ, trung tâm chống độc có thể hướng dẫn cho trẻ trên 1 tuổi uống mật ong…" / en equivalent (R10). The CDC choking-hazards source is replaced by NCPC. **A clinician picks one policy for the Sơ cứu pack too** | NCPC button battery guideline; NHS / GOSH |
| F07 | `art_after_vaccines` · body[3] | P2 | the Việt Nam EPI schedule stated as *the* schedule; source is Vinmec citing TT 38/2017 (superseded) | prefix "Ở Việt Nam:" and add "Ở nước khác, lịch và loại vắc xin khác nhau…" / "Other countries use different schedules…" (R5). Rotavirus is entering the EPI (2024 → nationwide 2026); add it once an MoH page is cited | UNICEF Viet Nam rota pages; TT 13/2026 |
| F08 | `art_after_vaccines` · body[8].items[0] | P2 | "Stay at least 30 minutes, as Vietnam's Ministry of Health requires" | keep 30 min as the default and add "Ở Việt Nam đây là quy định của Bộ Y tế; nhiều nước khác khuyên khoảng 15 phút" (R6) | Canadian Immunization Guide (already cited) |
| F09 | `art_after_vaccines` · body[10].items[4] | P2 | "Only use fever medicine if your baby is uncomfortable" | add "Ở Anh: NHS khuyên cho bé uống paracetamol ngay sau mũi MenB (8 và 12 tuần)…" / "In the UK: the NHS advises infant paracetamol right after the MenB jab…" (R7). The generic CDC page is replaced by UKHSA | GOV.UK "MenB vaccine and paracetamol" (8 + 12 weeks since 1 Jul 2025) |
| F10 | `art_vitamin_d_iron` · body[12].items[0] | P2 | "AAP recommends an iron supplement from about 4 months…" stated as the answer | "các hướng dẫn khác nhau. AAP (báo cáo năm 2026)… NHS (Anh) không khuyên bổ sung thường quy cho bé đủ tháng khoẻ mạnh…" / en (R8). **The reviewer should check the full AAP 2026 text: Guideline Central reports "by 4 mo, or wait to 6 mo", while the HealthyChildren summary says "by 6 months"** | AAP clinical report, Pediatrics, 22 Jun 2026; NHS vitamins page |
| F11 | `art_fever_when_to_call` · body[7] | P2 | "Many guidelines in Vietnam use 38.5 °C" | regional-note form "Ở Việt Nam: …" / "In Việt Nam: …" (R11) | convention |
| F12 | `art_diarrhoea_dehydration` · body[5].items[4] | P2 | "WHO recommends zinc for 10–14 days" | "…nhất là ở các nước thu nhập thấp và trung bình như Việt Nam; ở Anh, Mỹ, Úc, kẽm không được dùng thường quy" / en (R12) | WHO diarrhoea fact sheet; NICE CG84 (no zinc) |
| F13 | `art_newborn_jaundice` · body[13].items[2] | P1 | G6PD: "ask which foods and medicines to avoid" | add "như đậu tằm, và không dùng băng phiến để cất quần áo, chăn màn của bé" / "such as fava beans, and do not use naphthalene mothballs…" (R13) | standard G6PD avoidance lists (the reviewer adds a G6PD source; the NHS G6PD URL tried returned 404) |
| F14 | `art_parent_wellbeing` body[14]; `art_separation_anxiety` body[11] | P2 | Ngày Mai, Bạch Mai and 111 given as the help lines | prefix "Ở Việt Nam:" and add "Ở nước khác: hỏi bác sĩ về đường dây hỗ trợ nơi bạn sống" (R14, R15). Country numbers go in region config (§3) | — |
| F15 | `stg_w0` doing[1]; also `stg_w3` tryThis[0], `follows_faces`, `looks_at_toy` | P3 | "Bé nhìn rõ nhất ở khoảng 20–30 cm" | SEED-NOTES §2 lists "20–30 cm newborn focus" as **dropped as unverified**, yet it is still in 4 items. Either cite AAP HealthyChildren ("8 to 12 inches") or drop the number: "Bé nhìn rõ nhất những gì ở gần, cỡ khoảng cách tới mặt ba mẹ khi bế…" / "Your baby sees close things best…" (R19 for stg_w0) | AAP HealthyChildren newborn vision |
| F16 | `stg_m10` tryThis[0] | P3 | "push… a small chair" | "thùng giấy hay đồ chơi đẩy chắc chắn… không dùng xe tập đi có bánh" / "a sturdy push toy… avoid wheeled baby walkers" (R20) | AAP walkers |
| F17 | 16 articles · English doctor callouts | P3 | "(115 is the emergency number in Vietnam.)", "Call 115 (Vietnam emergency)" | replace with the §3 pattern "Call 115 (Việt Nam) or local emergency services" | convention |
| F18 | `art_vitamin_d_iron` · body[3] | P3 | AAP formula threshold "about 800 ml to 1 litre" | "dưới khoảng 1 lít (32 oz) sữa công thức mỗi ngày thì cần bổ sung" / "less than about 1 litre (32 oz)" (R9) | AAP vitamin D |
| F19 | `stg_m8` tryThis[2] (en) | P3 | "You're sad Mom is going to work" | "Mum" (R21); a house-style decision is needed for all en (F23) | D-012 |
| F20 | milestones `says_three_words`, `checks_back` · talkToDoctor | P1 | "khoảng 20 tháng" / "around 20 months" | 18 months (R17, R18). Rule: social-communication notes use the CDC age exactly (responds_to_name 9, points_to_ask 15, points_to_show 18 already do) | CDC 18 months; Zubler 2022 |
| F21 | `art_newborn_jaundice` · body[11] | P2 | "Child Life khuyên theo mốc thận trọng hơn" | "Bài này theo mốc thận trọng hơn" / "This article follows the more cautious timing" (R16). The app must not act as the prescriber | liability / tone |
| F22 | `art_solids_choking_safety` sources[5], [6]; `art_vitamin_d_iron`; `art_teething` | P3 | the labels "FDA … import alert 33-15", "Why it's important to take care of baby teeth", "Vitamin D for babies…", "Good oral health starts early" point to pages with other titles (a recall notice, "How to prevent tooth decay", "Vitamin D on the double", "Brushing up on oral health") | make each label the page's real title, or swap in the intended page | — |
| F23 | all English | P3 | US terms with UK spelling mixed together: diaper 80, crib 42 (cot 9), pacifier 5, stroller 5, Mom/Mum, favor, color, diarrhea (6) next to diarrhoea (30), pasteurized, fiber, checkup | decide en-GB vs en-US. Recommendation: en-GB spelling with neutral or explained terms now; add an en-US variant later for US/CA (the schema would need a third locale) | D-012 |
| F24 | 34 articles · "Hiểu lầm thường gặp" | P3 | three formats | standardise on `“Myth”: why families do it, why it is a problem. Nên: …` (the sleep articles) | house structure |
| F25 | `art_home_safety_falls` · body[5].items[3] | P3 | windows open "dưới 6,5 cm"; balustrade gaps "6,5 cm" | no source. It is stricter than the US (window stops < 4 in / 10 cm), UK (100 mm sphere) and AU (125 mm) standards, so it is not unsafe; cite a source or align to "khoảng 10 cm" | ASTM F2090; UK Building Regs K |
| F26 | `art_home_safety_falls` · "Cover low power sockets" | P2 | universal advice | UK: plug-in socket covers are discouraged because BS 1363 sockets have shutters. Add a regional note "Ở Anh: không dùng nắp che ổ điện" | RoSPA / Electrical Safety First |
| F27 | `art_fever_when_to_call`, `art_crying_colic`, `art_cold_cough` · cạo gió myth | P2 | harms: bruising, delay | add for diaspora: "Ở nước ngoài, vết cạo gió có thể bị nhầm là dấu hiệu bạo hành khi đi khám; hãy nói rõ với nhân viên y tế" / "Abroad, coining marks can be mistaken for abuse; tell the health worker" | clinical teaching (paediatric literature on coining) |
| F28 | `art_car_motorbike` (whole article) | P2 | Việt Nam law (Luật 36/2024 Điều 10(3), Điều 33) is the backbone | wrap the law paragraphs as "Ở Việt Nam:". For other markets add a one-line legal note: UK (child restraint until 12 y or 135 cm), AU (rear-facing to at least 6 months, AS/NZS 1754), US/CA (state / provincial laws). **A Việt Nam lawyer must confirm** the motorbike helmet rule for children under 6 and Decree 168/2024 fines | Luật 36/2024; WHO road traffic fact sheet (71 % and 74 % figures verified on 2026-10-16) |
| F29 | `art_fever_when_to_call` · paracetamol bullet | P3 | "NHS says it can be given from 2 months" | add "nếu bé sinh đủ tháng và nặng trên 4 kg" / "if born after 37 weeks and over 4 kg" (the NHS wording) | NHS paracetamol for children |
| F30 | `art_safe_sleep` | P2 | — | US readers: the Safe Sleep for Babies Act 2022 bans inclined sleepers and crib bumpers; worth one line in the US regional note | US Public Law 117-126 |
| F31 | fever, HFMD sections | P2 | the dengue and HFMD sections are always shown | keep for VN, SG, MY, ID, PH and TH; mark as a regional section for UK and CA. Dengue is relevant in northern Queensland and for travel | WHO dengue |
| F32 | `art_formula_bottle` body[4]; `art_expressing_storing_milk` body[3]; `art_bathing_at_home` body[3] | P2 | "Ở Việt Nam, nên…" written mid-paragraph | move into the "Ở Việt Nam:" form, so the CDC / NHS sentences still stand for other markets | convention |
| F33 | `art_after_vaccines` sources | P3 | the schedule rests on Vinmec citing the superseded TT 38/2017 | cite the MoH EPI schedule or TT 13/2026 annex | SEED-NOTES §3 |

Checked and found correct (no change): AAP 940 → "falls by 770" words per hour (matches the HealthyChildren page) · WHO child restraints 71 % and helmets 74 % · AAP 2026 iron report exists (June 2026), so the seed source is real · WHO IMCI breathing thresholds · NICE jaundice 14/21 days · CDC milk-storage limits · NIAID 2017 peanut tiers · CDC 2022 milestone wording · the PMID fixes in the milestone notes.

---

## 3. Hardcoded "115" and Việt Nam-only content

### Counts (seed `content-seed.ts` and `milestones.seed.json` as read)

| What | vi | en | Where |
|---|---|---|---|
| "115" in article text | **45** (in 35 blocks) | **47** | 29 of 34 articles; none in `art_diaper_rash`, `art_tummy_time`, `art_talk_play_first_year`, `art_screens_language`, `art_separation_anxiety` |
| English gloss "(Vietnam emergency)" / "(115 is the emergency number in Vietnam.)" | — | 16 articles | breastfeeding_start, expressing, spit_up, vitamin_d_iron, solids_readiness, solids_textures, water_juice, fever, cold_cough, diarrhoea, jaundice, after_vaccines, constipation, home_safety, car_motorbike, parent_wellbeing |
| "115" in milestones | 1 | 1 | `mouths_objects` (already uses the good pattern "115 in Việt Nam") |
| "115" in stages | 0 | 0 | — |
| Other VN numbers | 111 in 2 articles; Ngày Mai 096 306 1414 in 1 | same | separation_anxiety, parent_wellbeing |
| Việt Nam laws, schedules and programmes stated in the text | **5 articles, 13 vi / 12 en mentions** | | car_motorbike (Luật 36/2024 Điều 10(3) from 1/7/2026, Luật 118/2025, Điều 33, "quy chuẩn kỹ thuật quốc gia"), after_vaccines (EPI schedule, BCG, Bộ Y tế 30 min, TT 13/2026), fever (BV Nhi TW dengue and HFMD advice, 38.5 °C), home_safety (Bộ Y tế/WHO drowning), parent_wellbeing (Viện SKTT Bạch Mai) |
| "Vietnam / Việt Nam" mentioned at all | 8 vi / 31 en | | 20 articles + 1 milestone |

The test `health articles name the Vietnamese emergency number` (content-seed.test.ts) requires "115" in every `illness` article's vi doctor-callout text. Any multi-country change has to change this test too.

### Proposal

**Now (no schema change, passes today's tests).** Use the convention string in `additions/library.json`:
- vi keeps "Gọi 115 …" in the doctor callouts.
- en titles read "Call 115 (Việt Nam) or local emergency services now if" and the text says "call emergency services". The English sentence is then true in every market.
- Every law, schedule, hotline or local practice becomes one self-contained "Ở Việt Nam: … / In Việt Nam: …" paragraph or bullet, and the text around it stays correct without it.

**V1.1 (engineering + owner decision).**
1. `publicConfig/regions/{cc}` with `emergency`, `poisons`, `mentalHealth`, `childProtection`, `nonUrgentAdvice`. Each entry carries a source URL and a `verifiedOn` date and is shown in Sơ cứu and at the end of every doctor callout.
2. A content token, e.g. `{emergency}`, that the app resolves per region. The seed test then requires the token instead of "115".
3. An optional `regions: string[]` on paragraph, bullet and callout blocks, or a `regionNotes` array on the article, so the app hides notes for other markets. Both need a `content.ts` contract change and a portal B02 editor change.

Draft region table. **Every number must be re-verified from an official page before it is published**; the ones marked † I am less sure of.

| Market | Emergency | Non-urgent / advice | Poisons | Perinatal / mental health | Child protection |
|---|---|---|---|---|---|
| Việt Nam | 115 (ambulance); 113 police, 114 fire, 112 rescue | — | Trung tâm Chống độc Bạch Mai † (number to confirm) | Ngày Mai 096 306 1414 (not 24/7) | 111 |
| US | 911 | paediatrician line | 1-800-222-1222 | 988; National Maternal Mental Health Hotline 1-833-852-6262 | Childhelp 1-800-422-4453 † |
| UK | 999 / 112 | NHS 111 | via NHS 111 | Samaritans 116 123 | NSPCC 0808 800 5000 † |
| Australia | 000 (112 mobile) | healthdirect 1800 022 222 | 13 11 26 | PANDA 1300 726 306; Lifeline 13 11 14 | state lines † |
| Canada | 911 | 811 (most provinces) | provincial centres | 988 | provincial † |
| Singapore | 995 (ambulance), 999 police | 1777 non-emergency ambulance | — † | SOS 1767; IMH 6389 2222 † | ComCare / NAVH † |
| Malaysia | 999 (112 mobile) | — | — † | Talian HEAL 15555 † | Talian Kasih 15999 † |
| Philippines | 911 | — | — † | NCMH 1553 † | — † |
| Indonesia | 112; 119 ambulance † | — | — † | 119 ext 8 † | SAPA 129 † |
| Thailand | 1669 (medical), 191 police | — | — † | 1323 | 1300 † |

Topic-level regional differences the region notes must carry: post-vaccine wait (VN 30 min vs ~15 min elsewhere); UK MenB paracetamol; BCG (universal in VN, PH, ID, MY, TH, SG; selective in UK and AU; not used in the US and most of CA); formula water (VN and SEA: always boil; US and CA: safe tap water for healthy babies over 2 months); vitamin D (AAP/CA 400 IU for every breastfed baby; NHS 8.5–10 µg; Australia supplements only babies at risk †); routine iron (AAP vs NHS/EU); zinc (LMIC only); car-seat law per country; motorbike passengers (VN, ID, TH, MY, PH); dengue and HFMD sections (tropical markets); socket covers (UK); hammock / *duyan* / *buaian* (VN, PH, MY, ID; the Malaysian spring-cot "buaian" is a known sleep risk †).

---

## 4. Answers to the SEED-NOTES questions

### Library SEED-NOTES

**§1 Where guidance differs.** I agree with every choice in the table. Five refinements:
- **Iron**: the AAP 2026 report is real, but summaries disagree on "by 4 mo" vs "by 6 mo". Check the full text and present the NHS position too (F10).
- **Post-vaccine wait**: keep 30 minutes as Việt Nam law, and add the regional note (F08).
- **Vitamin D**: add Canada (400 IU, same as AAP) and Australia (at-risk babies only †) in the region notes.
- **Peanut, high risk**: the 2021 US/Canadian consensus (Fleischer et al.) also says no routine pre-testing. That supports "ask the doctor", not "test first".
- **Hot water for formula**: right for VN and SEA; give US and Canada the CDC/AAP option as a regional note.

**§2 Claims kept as specialist advice: my view.**
- **Agree, keep:** hammock risk (the AAP's 10° rule, plus the US Safe Sleep for Babies Act 2022 banning inclined sleepers); green vomit → emergency (bilious vomiting in an infant is a surgical emergency: malrotation or volvulus; "115 or go to the ED" is right); cạo gió bruising and delay (add the diaspora note F27); cooling patches only cool the forehead; never inserting stalks or soap, no soap enemas; no poultices on injection sites; normal bathing after any vaccine (no body restricts it); "thóp lõm / môi khô" as dehydration signs (standard teaching; NICE CG84 lists dry mucous membranes and sunken eyes); mother faint or confused → emergency (sepsis or haemorrhage); thermos water may not be ≥ 70 °C; lap-holding in cars; a child in front of a motorbike rider takes the first impact; adult helmets on children; never leave a child in a car; never decant chemicals; tablecloth pulling; covering water jars; any drowning → emergency care; never shake a baby; the ở cữ notes (respectful, correct).
- **Change:** socket covers need a UK exception (F26). For postnatal screening questionnaires, the EPDS has Vietnamese versions; the reviewer should name the instrument the MoH uses, or keep it generic as now.

**§2 Secondary and unreachable sources.**
- **Fathers**: cite Paulson & Bazemore, *JAMA* 2010;303:1961 (10.4 %) directly.
- **Camphor**: keep poison.org plus the AAP "rubs only from 2".
- **WHO powdered-formula guideline**: cite *Safe preparation, storage and handling of powdered infant formula* (WHO/FAO 2007) for the 70 °C rule.
- **VN complementary-feeding PDF**: use the Viện Dinh dưỡng page when it can be reached.
- **Law 118/2025**: a Vietnamese lawyer checks the gazette text.

**§2 Dropped claims.**
- Keep dropped: wake windows, nap counts, foremilk/hindmilk, baby-blues %, stair gates "until 2".
- Can be restored with a source:
  - **Throw away mixed ORS after 24 h** (WHO ORS guidance).
  - **Pale-stool colour card** for biliary atresia (Taiwan national programme; it fits the jaundice article's pale-stool warning).
  - **Replace a car seat after a crash** (NHTSA criteria).
  - **HFMD: fever ≥ 39 °C or lasting ≥ 48 h** is now in the drafted `art_hfmd`; it follows Vietnamese guidance, and Decision 1003/QĐ-BYT (2012) grades startles.

**§3 Việt Nam specifics.**
- **Car seats and motorbikes**: a lawyer must confirm the dates and the children's helmet obligation.
- **Vaccination**: re-source from the MoH (F33). Rotavirus is being added (UNICEF Viet Nam: 32 → 41 provinces in 2024–25, nationwide by 2026).
- **G6PD**: add mothballs (F13).
- **111**: widely described as free and 24/7; confirm on an official page.
- **115**: cite the national emergency-number allocation (113 / 114 / 115, plus 112 for search and rescue) instead of "local knowledge".

**§5 First-aid alignment.** Agree with the listed items. The button-battery policy in the first-aid pack must match whatever F06 decides.

### Milestones SEED-NOTES

- **A doctor note on all 56 items?** Yes. It follows the CDC 2022 logic that missing any checklist item is the act-early trigger. Keep the notes short and invariant, and avoid stacking several conditions in one sentence. The tone is good and never diagnoses.
- **Doctor ages at the window end vs the CDC age.** Keep window end = CDC age (+1/+2) for motor and cognitive items. For **social-communication** items use the CDC age exactly (F20: `says_three_words`, `checks_back` 20 → 18). Loss of skills is "now", at any age (already stated).
- **Hearing-check wording for families without newborn screening.** The current line is good. Add once (in `recognises_voices`, say): any parental worry about hearing deserves a hearing test at any age, whatever the newborn screen showed (JCIH 2019).
- **Walker tone.** Fine: firm, not judgemental. Name "xe tập đi có bánh" specifically and offer the alternative (push toys, cruising), as F16 does.
- **Corrected age.** It should apply to babies born before 37 weeks until 24 months (AAP; NICE NG72 follows preterm babies to 2 years corrected). The profile already stores the due date (`dueDateSchema` in `rhythm.ts`), so `milestoneWindow` can count from the due date when gestation was under 37 weeks and corrected age is under 24 months, with a visible "theo tuổi hiệu chỉnh" label. Owner decision plus engineering. Until then, the drafted `art_preterm_corrected_age` tells parents how to adjust by hand and says the app counts from birth.
- **Aligning with the Bộ Y tế "Sổ theo dõi sức khỏe bà mẹ và trẻ em".** Recommended. Crosswalk the handbook's milestone ages against the seed and document any differences. I could not see the handbook text, so this is a task for the VN reviewer.
- **Regional word choice.** Titles should carry both forms where North and South differ: "Lẫy (lật)" already does; consider "thìa (muỗng)" in feeding text and "măm (ăn)". Much of the diaspora reading in Vietnamese is Southern-dialect, so add Southern synonyms to `keywords.vi` (muỗng, bú bình, tả lót) for search.
- **`follows_faces` in cognitive.** Acceptable. To match the CDC cognitive item ("Watches you as you move"), consider retitling it "Nhìn theo khi bạn di chuyển". Changing the title needs a Figma/golden check, because it is a locked design item.

---

## 5. Prioritised gap list (0–24 months) and the 36-month question

**Drafted now (in `additions/library.json`, all passing the seed rules):**
1. `art_bronchiolitis_rsv` (illness)
2. `art_hfmd` (illness, Asia-specific risks)
3. `art_medicine_safety` (illness, step guide)
4. `art_heat_cold_safety` (daily care, including carbon monoxide from charcoal braziers during ở cữ)
5. `art_growth_charts` (development)
6. `art_preterm_corrected_age` (development)
7. `art_newborn_skin_rashes` (daily care, including rôm sảy and slate-grey patches)
8. `art_picky_eating_toddler` (solids)
9. `art_toddler_milk` (solids, quick Q&A)
10. `art_toddler_tantrums` (development)

**Next, by priority:**
11. **Dengue in infants and toddlers** (VN and SEA; expand beyond the fever paragraph; mosquito protection, including DEET/picaridin from 2 months per AAP †).
12. **Measles and vaccine worries** (VN outbreaks 2024–25; on-time MR/MMR).
13. **Thalassaemia and anaemia in families** (high carrier rates in VN and SEA; premarital and prenatal screening, iron vs thalassaemia trait).
14. **Ear infections and ear pain.**
15. **Cow's milk protein allergy** (reflux, blood in stool, formula choices).
16. **Returning to work while breastfeeding** (VN 6-month leave vs US/UK; pumping at work, workplace rights per market).
17. **Newborn screening results** (heel prick, hearing, pulse oximetry; what "retest" means).
18. **Baby carriers and slings** (airway, the T.I.C.K.S. rules).
19. **Oral thrush and tongue-tie** (quick Q&A).
20. **Fever without a source and UTI in infants.**
21. **Hip dysplasia and torticollis.**
22. **Undescended testes, hernia and hydrocele** (quick Q&A).
23. **Choosing childcare and when to keep a child home.**
24. **Bilingual and multilingual families** (high value for the diaspora; extend the NHS advice).
25. **Grandparents and confinement customs** (one respectful article that links the ở cữ myths).
26. **Water safety beyond the bath** (pools, ponds, swim lessons from age 1 per AAP).
27. **Vegetarian and vegan babies.**
28. **Moving from cot to bed and toddler sleep** (18–36 months).
29. **A new sibling.**
30. **Dog bites and pets.**

**Should milestones and stages extend to 36 months? Yes, in V1.1, not in V1.** Figma V1 and D-076 #6 fix 0–24 months. Reasons to extend:
- CDC has 30-month and 3-year checklists, read on 2026-10-16.
- AAP Bright Futures has 30- and 36-month visits; the NHS has the 2–2½-year review.
- Children in Việt Nam often start nhà trẻ or mẫu giáo between 18 and 36 months.
- Families keep using a baby app well past the second birthday.

Drafted: **12 milestones** (3 per group: 7 at 24–30 months, 5 at 30–36 months, orders 570–680) and **2 stages**, `stg_m24` (24–30) and `stg_m30` (30–36). They are checked against `milestoneSeedSchema`, the banned-word list, `stageContentStrictSchema` and the 3 + 3 rule.

Importing them needs these changes:
1. Add `m24` and `m30` to `stageBuckets` (B05 then shows "x / 18").
2. In `content-seed.test.ts`, the stage-equality and `covered === 16` assertions.
3. In `milestones.test.ts`, the assertion that the largest `to` is 24 (it becomes 36).
4. Optionally a 104–156-week band in the article coverage test.
5. A Figma update (read-only for us) for B05/B07 copy that says 0–24.

The schemas already allow it: `maxAgeMonths` is 36 for milestones and 60 for stages.

---

## 6. Notes on the drafted additions

- **Shape.** Every article uses the `seedArticles` item shape `{id, reviewerLabel, data}`, with `cover: null` and `readingMinutes` equal to `readingMinutesOf(body.vi)` (articles 4–5 min, quick Q&A 2 min, step guide 4 min).
- **House structure.** Tóm tắt nhanh → Hiểu đúng → Ba mẹ có thể làm gì → Theo dõi → Hiểu lầm thường gặp (in the "Nên:" form) → doctor callouts last.
- **Parity.** vi and en have the same block shape and the same number of keywords.
- **Sources.** At least 2 per article, all https. The new URLs were checked: 200, except CDC pages, which block scripts (403) but were read through a web fetch.
- **Emergency text.** Illness articles name 115 in the vi doctor text, and the English follows the multi-country pattern.
- **Links.** Related links resolve against the seed plus the additions. Milestone links use only existing ids.
- **Replacements.** The 22 replacements give the current text, full vi and en, the path (`{lang}` stands for `vi` / `en`), severity and reason, and `replaceSources` where a source is swapped to stay within 8. Five of them change the reading time by one minute: `art_breastfeeding_start` 6 → 7, `art_after_vaccines` 4 → 5, `art_solids_choking_safety` 5 → 6, `art_diarrhoea_dehydration` 4 → 5, `art_parent_wellbeing` 6 → 7. Recompute `readingMinutes` when applying them, or the seed test fails.
- **Claims to check in the drafts:**
  - HFMD exclusion "about 7–14 days": Vietnamese practice varies and no Bộ Y tế text was found.
  - "Ở Việt Nam: charcoal warming during ở cữ is still practised": local knowledge, no cited page.
  - NHS cradle-cap method.
  - The EV71 / Asia-Pacific framing: WHO pages, archived.
  - Stage `stg_m30`'s toilet-training line (NHS).
  - Fussy eating "10–15 tries": NHS page.
  - Toddler milk: AAP 2023 via the HealthyChildren summary (the report itself was not opened); NHS rice-drink-under-5 rule via the NHS drinks page.

---

## 7. What a clinician must sign before prod

Per item, in the portal (B03): a `review` `{reviewer, credential, reviewedOn}` and **all five checks** (accuracy, safety, sources, tone, bilingual). An item can only be approved by someone other than its last editor. Re-review every 12 months (`reReviewMonths`).

| Content | Who signs (minimum) |
|---|---|
| Illness, safety, sleep, skin, vaccines, all 115/emergency thresholds | Licensed paediatrician (VN chứng chỉ hành nghề) |
| Breastfeeding, expressing | IBCLC, plus the paediatrician for the red flags |
| Solids, milk, vitamin D, iron, water/juice | Paediatric dietitian, plus the paediatrician for supplement statements |
| Milestones, stages, development articles | Developmental paediatrician or child psychologist |
| Parent wellbeing | Perinatal psychiatrist or clinical psychologist |
| Medicine safety and any named medicine or age limit | Paediatric pharmacist |
| Car seat, motorbike, any statute, schedule or programme | Vietnamese lawyer (and the MoH source for the EPI) |
| Vietnamese medical terminology and dialect | Vietnamese medical editor |
| Each new market's regional notes and help lines | A locally licensed clinician in that market |

Points to sign explicitly, beyond the general read:
1. **Every emergency trigger:** fever under 3 months; 3–6 months ≥ 39 °C; breathing-rate thresholds (WHO and NICE ≥ 70 bronchiolitis); head-injury criteria; HFMD and dengue warning signs.
2. **Every number or age cut-off:** vitamin D 400 IU / 10 µg; honey before 12 months; whole nuts before 5 years; cough and cold medicines under 2; ibuprofen 3/6 months; paracetamol 2 months; milk volumes; the 30-minute wait; ORS method; formula 70 °C and 2 h; breast-milk storage.
3. **Bed-sharing harm-reduction wording** and the hammock line.
4. **The two divergence decisions:** F06 button battery and F10 iron.
5. **The help-line table:** numbers, hours and 24/7 status, with a re-verification date.
6. **Every deep link to Sơ cứu trẻ em:** it must exist and say the same thing.
7. **The English translation as a separate check** ("bilingual"), with the house-style decision (F23).
8. **No product clinical voice** (F21) and no claim of review anywhere (the test already enforces this).
9. **For the 36-month additions, the owner's scope decision first.**

Legal and owner, not clinical: the app-level disclaimer ("thông tin tham khảo, không thay thế khám bệnh"), data-free analytics for content views (CLAUDE.md), and the prod publishing gate (`REVIEW_REQUIRED`) staying on.
