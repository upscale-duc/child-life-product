# Sơ cứu trẻ em: medical and multi-country review of `content/first-aid/pack.seed.json`

**Status: a draft by a reviewer working as a paediatric emergency physician and first-aid content editor. It is not a clinical certification.** Nothing here may ship to prod until a licensed clinician signs it (P-141; `review` is `null` in the seed, so the app shows no "rà soát" line yet). Date: 2026-10-16.

Companion file: `scratchpad/additions/first-aid.json`
- 10 new situations.
- 43 text `replacements` and 54 `structuralChanges`, covering every P0, P1 and P2 fix below and the P3 ones that were cheap.
- Image briefs, category and quick-search changes.

I applied all of it to a copy of the seed and validated the result against the real `firstAidPackSchema` (`packages/contracts/dist/first-aid.js`):
- 35 situations, 0 issues.
- Each new situation also passes `firstAidSituationSchema`.
- After the patch, no string contains a literal `115`.
- vi and en use the same tokens.

I edited no repo file.

Guideline baseline used:
- **AHA/AAP 2025** Part 6 Pediatric BLS, published Oct 2025.
- **ERC 2025** Paediatric Life Support, and RCUK 2025 PBLS, which I read in full.
- **ERC 2025 / ILCOR** First Aid.
- **NICE** NG143 (fever), CG98 (neonatal jaundice), NG232 (head injury), CG84 (diarrhoea and vomiting).
- **NHS** condition pages. I read the febrile seizures page on 2026-10-16.
- **WHO**: rabies (2018 position paper), SEARO snakebite (2016), diarrhoea/ORS, dengue.
- **ASCIA** anaphylaxis action plan.
- **Poison Control** (poison.org) button-battery guideline, which I read: honey 10 ml every 10 min, up to 6 doses, age ≥ 12 months, within 12 h.
- **British Burn Association / ANZBA**: 20 min of cool running water.
- **IADT 2020** dental trauma.

---

## 1. Executive summary: top 10 issues

| # | Sev | Issue | Fix (finding ids → JSON) |
|---|---|---|---|
| 1 | **P0** | **Infant CPR uses the two-finger technique.** It appears in the step text, in the `cpr.infant.compressionText` the metronome reads aloud, and in the `ep-tim-so-sinh` bitmap, where the fingers sit low, close to the xiphoid. AHA 2025 and ERC 2025 both removed two-finger compressions because they don't reach adequate depth. AHA allows two-thumb encircling or the heel of one hand. ERC allows two-thumb encircling in all situations. | Two-thumb encircling, with the heel of one hand as fallback. Redraw the image. (F-CPR-1) |
| 2 | **P0** | **Choking from 1 year: abdominal thrusts only, no back blows.** AHA 2025 now uses cycles of 5 back blows alternating with 5 abdominal thrusts for children. ERC/RCUK 2025 also uses back blows first, then abdominal thrusts, alternating. Neither variant tells the parent what to do when the child becomes unresponsive (start CPR and check the mouth before breaths). The `from-1` hero and step images have no back-blow picture for a child. | Rewrite both variants (F-CHK-1/2). Add the `vo-lung-tre-lon` image. |
| 3 | **P0** | **Infant chest thrusts (choking) are done "with 2 fingers".** The text and the `an-nguc` bitmap both show this. AHA 2025 says heel of one hand; ERC 2025 says two-thumb encircling. | F-CHK-1/2. Redraw `an-nguc`. |
| 4 | **P0** | **The anaphylaxis page never mentions adrenaline (epinephrine).** IM adrenaline is first-line in every guideline. The page also lacks: "don't stand or walk"; sit up if breathless; hold small children flat; a second dose after 5 min; and the warning that symptoms can return (biphasic), so the child always needs hospital. In Việt Nam few families have auto-injectors, so the step is conditional ("nếu có"). | F-ANA-1/2 |
| 5 | **P0** | **Snake-bite first aid is "quấn gạc nhẹ quanh vết cắn".** No guideline recommends a loose dressing at the bite. WHO SEARO 2016 and VN practice say: immobilise the whole limb with a splint, and use a pressure bandage only for neurotoxic elapids. For vipers, splint only. Australia (ANZCOR) uses pressure immobilisation for every snake. The US uses no bandage. There are no "don'ts" for cutting, suction or traditional healers, which are common in VN. | F-SNK-0/1/2. The `ran-can-bang-nhe` image needs a redraw. AU and US need country overrides (see §4). |
| 6 | **P0 outside VN, P2 for a VN-only launch** | **"115" is hard-coded 40 times: 20 vi plus 20 en, in 20 fields across 13 situations.** An English-speaking parent in the US, UK or AU would be told to dial 115. The pack has a single `emergencyNumber`. The app also hard-codes a `'115'` fallback in `first_aid_modes.dart:110`. | `{emergency}` token and a per-country table (§4). Every string in the JSON already uses the token. |
| 7 | **P1 (needs a decision)** | **CPR sequence and missing basics.** There is no "check response and breathing ≤ 10 s" step, no speakerphone, no AED and no compression-only fallback. The "5 initial breaths, 30:2" sequence follows ERC. US, AU and NZ parents are trained compressions-first (AHA/ANZCOR). A clinician must choose one default. | F-CPR-1/2/3, F-CPR-5/6 (ERC kept as default). Decision F-CPR-4 below. |
| 8 | **P1** | **Milk aspiration and newborn apnoea delay escalation.** The steps say to pat gently, flick the sole and "wait until baby cries", with no time limit. When the baby is cyanosed and silent, the airway is severely obstructed: use full back blows and chest thrusts, call for help, and start CPR if the baby goes limp. After any apnoea, the baby needs a medical review even if they recover (AAP BRUE). | F-MILK-1/2, F-APN-1..4 |
| 9 | **P1** | **The poisoning page has no poison-centre route and no skin or eye decontamination.** It doesn't name the folk "antidotes" used in VN (milk, egg white, mung-bean water). Button batteries and magnets appear only as keywords; they need honey and an immediate X-ray. | F-POI-1/2 and the new `swallowed-object` page. |
| 10 | **P1** | **Fever.** The 38.5 °C "watch closely" rule conflicts with NICE: 3–6 months at ≥ 39 °C needs a same-day check, and fever ≥ 5 days needs assessment. Thermometer advice ignores age: ear thermometers only from 6 months (AAP), no forehead strips, no mercury. There is no dengue warning, which is critical in VN/SEA: no ibuprofen or aspirin. There is no non-blanching rash red flag, and °C only is wrong for US parents. | F-TMP-1/2 |

Also important (P1):
- **Burns**: "15–20 min" should be 20 min. Add cling film. The don'ts should name fish sauce, egg white and ice.
- **Bleeding**: raising the limb is no longer recommended. Use firm direct pressure for ≥ 10 min.
- **Dog bite**: wash for 10–15 min should be ≥ 15 min (WHO). "Băng lại" should be "cover loosely" (WHO: don't close the wound). Add "don't wait to watch the dog" for VN.
- **Heatstroke**: use whole-body wetting and fanning. Babies under 6 months get breast milk or formula, not water. Fever medicine doesn't help.
- **ORS**: mix exactly as the packet says; Oresol made too strong causes hypernatraemia.
- **Jaundice**: zone-based reassurance by eye is unreliable (NICE). Add don'ts: no sunlight therapy, no water or sugar water.
- **Seizure**: a first-ever seizure means calling an ambulance (NHS).
- **Traffic**: don't remove the helmet. Don't carry a possibly spine-injured child on a motorbike.

---

## 2. Full findings table

Legend:
- **P0**: could cause harm or contradicts current guidelines.
- **P1**: wrong or misleading.
- **P2**: localisation or multi-country.
- **P3**: tone, clarity, consistency.

The full proposed vi and en text for every row is in `additions/first-aid.json`, under the same finding id (`replacements[].finding` or `structuralChanges[].finding`). Sub-ids such as F-CPR-3b/3c/10 and F-CHK-2b ship inside the whole-array `set` ops filed as `F-CPR-1/2/3` and `F-CHK-1/2`. The P0 texts are quoted in §3.

### 2.1 Hồi sức tim phổi (`cpr`, TH01) and the CPR protocols

| ID | Sev | Path | Current (vi / en) | Proposed | Source |
|---|---|---|---|---|---|
| F-CPR-1 | P0 | `cpr.variants[under-1].steps[2].body`, `cpr[id=infant].compressionText`, `cpr.hero` / `cpr[infant].image` (`ep-tim-so-sinh`) | "2 ngón tay giữa ngực, ngay dưới đường nối hai núm vú. Ấn sâu khoảng 4 cm…" / "Two fingers in the middle of the chest…" | Two thumbs side by side on the lower half of the breastbone, hands encircling the chest. Depth 1/3 of the chest (≈ 4 cm / 1½ in). Full recoil. Heel of one hand if you can't encircle. New image `ep-tim-so-sinh-hai-ngon-cai`. | AHA 2025 Pt 6; ERC 2025 PLS; RCUK 2025 |
| F-CPR-2 | P1 | `cpr.variants[*].steps` (new step 0) | No check step: the page starts at "Mở đường thở" | "Kiểm tra bé": call out, tap, watch the chest ≤ 10 s; if not breathing or only gasping, start | ERC/RCUK 2025; AHA 2025 |
| F-CPR-3 | P1 | `cpr.variants[*].steps` (new last step) | No AED | "Có máy AED: dùng ngay": switch on, pads as pictured, follow the prompts, keep compressing | AHA 2025; RCUK 2025 (paediatric mode < 25 kg; adult pads acceptable) |
| F-CPR-3b | P1 | `steps[4].body` (both) | "…Tiếp tục đến khi bé thở lại…" | Adds "Không thổi ngạt được: cứ ép ngực liên tục" (compression-only fallback) | AHA 2025; ERC 2025 |
| F-CPR-3c | P1 | `under-1.steps[1].body`; `.image` | "ngửa nhẹ đầu"; image `mo-duong-tho` shows an older child with a full head tilt | Infant: head level (neutral), chin lift, no blind sweep; new image `mo-duong-tho-so-sinh`. `mo-duong-tho` moves to `from-1`. | ERC 2025 PLS |
| F-CPR-4 | **Decision** | sequence (both variants) | 5 initial breaths → 30:2 (ERC) | **Recommendation:** keep ERC 5 initial breaths + 30:2 as the default (VN primary market, asphyxial arrests dominate in children; RCUK tells dispatchers to coach untrained bystanders with 30:2 + 5 breaths). Add a per-country `cprSequence` so US/CA/AU/NZ get compressions-first (C-A-B), as they are trained. See §4.4. | ERC 2025 vs AHA 2025 / ANZCOR |
| F-CPR-5 | P1 | `cpr.variants[*].callouts` | Don't box has 2 items; warning box only says "Luôn gọi 115…" | Adds "Lắc mạnh bé để gọi tỉnh" and a positive box "Khi bé thở lại": recovery position (for an infant, held on the side in arms) and monitoring. Token in the warning. | ERC 2025 First Aid; RCUK |
| F-CPR-6 | P1 | `cpr.variants[*].banner` | "Gọi 115 ngay. Có người khác: nhờ gọi giúp." | `{emergency}`, speakerphone, someone fetches an AED. Alone with no phone: 1 min of CPR first (RCUK; AHA says ~2 min for an unwitnessed arrest; the clinician picks one). | RCUK 2025; AHA 2025 |
| F-CPR-7 | P3 | `from-1.hero` | `ep-tim-tre-lon` (present; SEED-NOTES §2.4 is out of date: it says null) | Keep. Also used on `from-1` step 4. | — |
| F-CPR-8 | P3 | `cpr.lead` | "Bé bất tỉnh, không thở hoặc thở ngáp" / "Baby is unconscious…" | "…hoặc chỉ thở ngáp" / "Unresponsive, not breathing or only gasping" (page covers all ages) | — |
| F-CPR-9 | P2 | `cpr[child].compressionText`, all depths | cm only | en adds "(2 in)" / "(1½ in)" for US parents | — |
| F-CPR-10 | P3 | `from-1.steps[3].body` en | "until baby breathes again" | "until the child breathes again" | — |
| F-CPR-11 | P2 | `ratePerMinute: 110`, `compressions 30`, `breaths 2` | — | Correct for lay rescuers under both guidelines. Note that RCUK uses 15:2 for PBLS-trained rescuers. Keep 30:2 for parents. | RCUK 2025 |

### 2.2 Hóc dị vật (`choking`)

| ID | Sev | Path | Current | Proposed | Source |
|---|---|---|---|---|---|
| F-CHK-1 | **P0** | `choking.variants[from-1].steps` | 3 steps: abdominal thrusts only ("Đứng sau lưng bé… Ấn mạnh vào trong, lên trên… lặp lại") | 4 steps: **5 back blows** (count 5, new image `vo-lung-tre-lon`) → **5 abdominal thrusts** (count 5, fist between the navel and the bottom of the breastbone) → alternate; call `{emergency}` on speaker → **goes limp: CPR, check the mouth before breaths** | AHA 2025 (back blows alternating with abdominal thrusts for children); ERC/RCUK 2025 |
| F-CHK-2 | **P0** | `choking.variants[under-1].steps[1]` (+ image `an-nguc`) | "Đặt 2 ngón tay giữa ngực… ấn mạnh 5 lần" | "…nửa dưới xương ức… bằng gót một bàn tay hoặc hai ngón cái"; head lower than the chest; new image `an-nguc-hai-ngon-cai` | AHA 2025 (heel of one hand); ERC 2025 (two-thumb) |
| F-CHK-2b | **P0** | both variants: new step "Bé lả đi: hồi sức tim phổi" | Only "Bé lả đi, không thở: gọi 115 ngay" | Lay on a firm surface, call, start CPR, look in the mouth before breaths | ERC/RCUK 2025; AHA 2025 |
| F-CHK-3 | P1 | callouts (both) | "Thò tay vào miệng bé để móc dị vật"; "Dốc ngược bé lên"; warning has 2 items | "…móc **mò**" (a visible object may be removed); "…bằng hai chân"; adds "Cho uống nước hay nuốt cơm để đẩy dị vật xuống" (VN practice); `from-1` adds "Ép bụng trẻ dưới 1 tuổi"; warning adds "Đã phải ấn ngực / ép bụng: luôn cho bé đi khám" | RCUK 2025 (examine after abdominal thrusts) |
| F-CHK-4 | P1 | `banner` (both) | "Nếu bé còn ho, khóc được: để bé tự ho ra, không vỗ, theo dõi sát." | Adds the severe branch: "Bé không ho, không khóc, không thở được: nhờ người gọi {emergency} và làm ngay các bước dưới." `from-1` uses "ho, nói hoặc khóc". | RCUK 2025 |
| F-CHK-5 | P1 | `choking.lead` | "Bé ho sặc, không khóc, không thở được" / "Baby is coughing and choking…" | "Bé đột ngột không thở, không ho, không khóc được" / "Suddenly can't breathe, cough or cry". The current lead describes mild obstruction, where the page itself says not to intervene. | ERC 2025 |
| F-CHK-6 | P3 | `from-1.hero` = `ep-bung` and `steps[1].image` = `ep-bung` | duplicate (SEED-NOTES §2.2) | Acceptable now that step 0 has its own image | — |

### 2.3 Urgent group (TH02–TH07)

| ID | Sev | Path | Current | Proposed | Source |
|---|---|---|---|---|---|
| F-MILK-1 | P1 | `milk-aspiration.main.banner` | null | "Bé tím tái, không thở hoặc không khóc được: gọi {emergency} và làm như hóc dị vật (vỗ lưng, ấn ngực)." | AHA/ERC 2025 FBAO |
| F-MILK-2 | P1 | `milk-aspiration.main.steps[2].body` | "Đỡ chắc cằm, lật úp bé trên cẳng tay, đầu hơi cúi. Vỗ giữa hai bả vai." | 5 firm back blows with the heel of the hand → 5 chest thrusts → CPR if limp | AHA/ERC 2025 |
| F-MILK-3 | P2 | `callouts[1].items[0]` | "…: gọi 115" | `{emergency}` | — |
| F-MILK-4 | P3 | `title.en` | "Milk choking" | "Choking on milk" | — |
| F-MILK-5 | P3 | `steps[0].body` | "Khum tay vỗ nhẹ…" | Keep for a mild episode. The banner now carries the severe branch. | — |
| F-APN-1 | P1 | `apnoea.main.banner` | null | "Kích thích khoảng 10 giây mà bé chưa thở lại: gọi {emergency} và bắt đầu CPR ngay." | ERC 2025 |
| F-APN-2 | P1 | `steps[0].body` | "…ngửa nhẹ đầu, nâng cằm." | "…đầu ở tư thế thẳng, nâng nhẹ cằm." (neutral position in neonates) | ERC 2025 NLS/PLS |
| F-APN-3 | P1 | `steps[2].body` | "…búng nhẹ lòng bàn chân. Chờ đến khi bé khóc và thở đều trở lại." (no time limit) | "Bé chưa thở: không chờ thêm, gọi {emergency} và làm hồi sức tim phổi." | ERC 2025 |
| F-APN-4 | P1 | `callouts` | 1 warning item | Adds don'ts (shaking, upside-down, blowing on the face) and "Bé đã thở lại: vẫn đưa bé đi khám ngay trong ngày" | AAP BRUE CPG 2016 |
| F-APN-5 | P3 | `ageMonths 0–3`, title vs detail title | — | Keep. The clinician should confirm that the scope is any young infant, not only premature babies. | SEED-NOTES §2.1 |
| F-SZ-1 | P3 | `seizure.steps[1].body` | "Giúp đờm dãi chảy ra…" | "Nếu được… Không ghì giữ. Hết giật: … nằm nghiêng an toàn, kiểm tra hơi thở." | NHS |
| F-SZ-2 | P1 | `seizure.steps[4].body` | "Khi hết cơn giật. Bé sốt: dùng thuốc hạ sốt theo chỉ định bác sĩ." | A first-ever seizure → call `{emergency}` / emergency department. Fever medicine doesn't prevent seizures. | NHS febrile seizures (read 2026-10-16); NICE NG143 |
| F-SZ-3 | P3 | en `steps[0].body`, `steps[1].title`, `steps[4].title` | "baby" on an all-age page | "your child" | — |
| F-SZ-4 | P1 | `seizure.callouts` | — | Don'ts: add the rescue-medicine exception; cold sponging, alcohol, cạo gió, châm kim, bấm huyệt (VN practice). Warning: add first seizure, one-sided seizure, drowsy > 1 h, stiff neck / bulging fontanelle / non-blanching rash, under 6 months. | NHS; NICE NG143/NG240 |
| F-ANA-1 | **P0** | `anaphylaxis.main.steps` | No adrenaline step | 5 steps: adrenaline auto-injector if available (outer thigh); lie flat with legs raised, no standing or walking, sit if breathless, hold a small child flat, recovery position if vomiting; airway; 2nd dose after 5 min; stay, CPR if needed. New image `tiem-adrenaline-dui`. | ASCIA 2023–26; WAO 2020; RCUK 2021 |
| F-ANA-2 | P1 | `anaphylaxis.callouts` | Don't box: only "crowd" | Adds standing/walking, antihistamine instead of adrenaline, waiting to see; warning: always hospital (biphasic) | ASCIA; RCUK |
| F-ANA-3 | P2 | `banner` | "Gọi 115 ngay khi nghi ngờ sốc phản vệ." | `{emergency}` + "kể cả khi đã tiêm adrenaline" | ASCIA |
| F-ANA-4 | P2 | (market) | — | In VN, auto-injectors are rarely prescribed or stocked. The step is conditional and falls back to calling. In US/UK/AU, families of allergic children usually carry 2 pens. | — |
| F-POI-1 | P1 | `poisoning.main.steps` | Step 0 "Gọi 115 ngay"; no skin/eye step | Step 0 "Gọi {poison} ngay", with `{emergency}` for seizures, breathing trouble or drowsiness; "lấy hết thuốc còn trong miệng"; new "Hoá chất dính da, mắt" step (≥ 15 min water); "bao nhiêu, lúc nào" | AAPCC/Poison Control; NHS; ERC FA |
| F-POI-2 | P1 | `poisoning.callouts` | "Tự cho uống thuốc giải, sữa hay nước…" | Names milk, water, egg white, mung-bean water; adds "Để bé nằm ngửa khi bé lơ mơ"; warning adds batteries/magnets → new page; kerosene, gasoline, drain cleaner, pesticide → `{emergency}`. en: "…unless the poison centre says it's safe at home" (US/AU practice). | Poison Control; NCPC battery guideline |
| F-POI-3 | P2 | `keywords` "Dầu hoả" | — | Keep; the page now covers hydrocarbons. "Pin cúc áo" now points to `swallowed-object`. | SEED-NOTES §1 |
| F-TRA-1 | P2 | `traffic.steps[0].title` | "Đảm bảo an toàn, gọi 115" | `{emergency}` | — |
| F-TRA-2 | P1 | `traffic.steps[2].body` | "Nghi chấn thương: không di chuyển đầu, cổ hay bất kỳ bộ phận nào…" | Wait for the ambulance. If you must move the child: several people, keep them in line, flat. | ERC 2025 FA (spinal motion restriction) |
| F-TRA-3 | P1 | `traffic.callouts` | "Bế xốc… Cần 2–3 người cùng nâng bé lên ván cứng" | Don't: yank, bend, or carry on a motorbike; **don't remove the helmet** unless the child isn't breathing or is vomiting; no food or drink. Warning adds head-injury red flags → `{emergency}`. Lay people shouldn't improvise a "ván cứng" lift. | ERC 2025 FA; BRC/St John; NICE NG232 |

### 2.4 Wounds, burns and injuries (TH08–TH14)

| ID | Sev | Path | Current | Proposed | Source |
|---|---|---|---|---|---|
| F-NB-1 | P1 | `nosebleed.steps[1]` | "Bóp cánh mũi 10 phút / Ép **nhẹ** cánh mũi bên chảy máu…" | "Bóp mũi 10–15 phút / Bóp **chặt** phần mềm của mũi… liên tục, không thả ra xem" | NHS; RCH Melbourne |
| F-NB-2 | P1 | `nosebleed.callouts` | Warning "Sau 10 phút máu vẫn chảy" only | After 15 min of pinching or heavy bleeding; after a head or face knock; breathing difficulty or pallor; frequent bleeds or bruising. Don't: "bông, giấy hay lá". | NHS |
| F-BL-1 | P1 | `bleeding.no-object.steps[1]` | "Nâng cao vùng bị thương / Giữ bé ở tư thế thoải mái." | "Ép liên tục ít nhất 10 phút / Ép chặt, không mở ra xem. Máu thấm qua: đặt thêm gạc…" | ERC 2025 FA; AHA/Red Cross 2024 FA (elevation not recommended) |
| F-BL-2 | P1 | `bleeding.no-object.callouts` | Warning without a call; no Don't box | `{emergency}` for heavy bleeding; tetanus advice for nails or soil; Don't: powders, leaves | WHO tetanus 2017 |
| F-BL-3 | P2 | `bleeding.object.callouts[1].items[1]` | "…: gọi 115" | `{emergency}` | — |
| F-BD-1 | P1 | `bandaging.steps[1].body` | "Rửa vết thương bằng nước sạch **hoặc dung dịch sát trùng**…" | Running tap water for a few minutes; "Không cần đổ cồn hay oxy già vào vết thương" (common in VN) | ERC 2025 FA; AHA/RC 2024 |
| F-BD-2 | P3 | `bandaging.callouts[1].items[1]` → `steps[3].body` | Aftercare inside "Đưa bé đi viện ngay khi" | Moved into step 4 | SEED-NOTES §2.9 |
| F-BD-3 | P1 | `bandaging.callouts` | — | Heading "Khi nào cần đi khám"; adds infection signs, gaping cut, tetanus | WHO tetanus |
| F-SC-1 | P2 | `scald.title/lead` | "Bỏng nước sôi" | "Bỏng nước sôi, bỏng nhiệt" / "Scalds and heat burns"; lead adds bô xe and bàn là (exhaust-pipe burns are very common in VN; first aid is the same) | — |
| F-SC-2 | P1 | `scald.steps[0]` | "Xả nước mát 15–20 phút" | **20 min**, cool not icy, still useful up to 3 h; remove clothes and jewelry; keep the child warm | BBA; ANZBA; NHS |
| F-SC-3 | P1 | `scald.steps[1].body` | "Gạc mỏng hoặc vải sạch…" | Cling film or a non-fluffy dressing; don't pop blisters | NHS; BBA |
| F-SC-4 | P1 | `scald.callouts` | Don't: "kem đánh răng, mỡ trăn…"; warning: large or deep, face/hands/genitals | Don't: toothpaste, **nước mắm, lòng trắng trứng**, python fat, oil, butter, leaves; ice; popping blisters. Warning: > the child's palm, white or charred, face/hands/feet/genitals/joints, electrical, chemical, inhalation, under 5 with blisters. | BBA; ANZBA referral criteria; NHS |
| F-SC-5 | P3 | `scald.keywords` | — | + "Bỏng bàn là", "Bỏng lửa" | — |
| F-SP-1 | P1 | `sprain.callouts` | Warning: 48 h only; no Don't box | Don't: massage, heat rubs, rượu thuốc, leaves, **thầy lang**. Warning: can't stand, walk or move it (a growth-plate fracture is more likely than a sprain in children); severe pain or deformity. | NHS; AAP |
| F-SP-2 | P3 | heading for "not better after 48 h" | Under "Đưa bé đi viện ngay khi" | Kept. The design should consider "Khi nào cần đi khám" for the 48 h item. | — |
| F-FR-1 | P1 | `fracture.steps[1].body` | "Dùng thanh thẳng… đặt dọc chi bị gãy…" | Keep the limb as found; splint only if you must transport; include the joints above and below; tie loosely | ERC 2025 FA |
| F-FR-2 | P1 | `fracture.steps[2].body` | "Lau nhẹ, băng vừa phải…" (open fracture) | Cover with clean gauze and press around the wound; don't press on bone or push it back | ERC FA |
| F-FR-3 | P2 | `fracture.steps[3].body` | painkillers only | + "Không cho bé ăn uống (có thể cần gây mê)" | NHS |
| F-FR-4 | P1 | `fracture.callouts` | — | Don't: "thầy lang bó thuốc, đắp lá". Warning: bone visible; cold, blue or numb limb. | ERC FA; VN clinical experience (clinician to confirm) |
| F-EY-1 | P1 | `eye-injury.object.steps` | 3 steps | Adds "Vật cắm vào mắt: không rút; úp cốc giấy; `{emergency}`" | AAO; NHS |
| F-EY-2 | P1 | `eye-injury.*.callouts` | "Tự nhỏ thuốc hay dung dịch không rõ nguồn gốc" | Names **sữa mẹ** and nước lá (common VN practice); adds penetrating or high-speed injury and chemical | AAO |
| F-EY-3 | P1 | `eye-injury.variants` (append `chemical`), `keywords` | Chemical splash not covered (keyword-only gap, SEED-NOTES §1) | 3rd variant "Hoá chất": rinse 15–20 min immediately, call, always see an eye doctor; don't "neutralise" | AAO; ERC FA |

### 2.5 Insects and animals (TH15–TH19)

| ID | Sev | Path | Current | Proposed | Source |
|---|---|---|---|---|---|
| F-DOG-1 | P3 | `dog-bite.title` | "Chó cắn" (the lead covers cats) | "Chó, mèo cắn" / "Dog or cat bite" | — |
| F-DOG-2 | P1 | `dog-bite.steps` | "Rửa xà phòng 10–15 phút"; "Băng lại, đi tiêm phòng" | **≥ 15 min** soap and running water, even for small scratches; povidone-iodine; **che hờ, không băng kín**; same day; "Không chờ theo dõi con vật rồi mới đi tiêm" (vi, rabies-endemic VN). en: "the doctor decides whether shots are needed" (CDC allows 10-day observation in the US). | WHO rabies 2018; CDC PEP |
| F-DOG-3 | P1 | `dog-bite.callouts` | — | Don't: traditional rabies healers; closing or tight bandaging. Warning: face/head/neck/hands; **bats, monkeys, rats**; infection signs. | WHO; AU bat lyssavirus |
| F-DOG-4 | P3 | keywords | — | + Dơi cắn, Khỉ cắn | — |
| F-BEE-1 | P3 | `bee-sting.steps[0].body` | "Dùng nhíp hoặc thẻ cứng khều nhẹ" | Remove quickly with a nail or card; don't squeeze the sac (speed matters more than method) | NHS; Visscher 1996 |
| F-BEE-2 | P3 | `bee-sting.steps[2]` | "Bôi dung dịch sát khuẩn như cồn 70 độ" | "Giảm đau, giảm ngứa": raise the area, ask a pharmacist | NHS |
| F-BEE-3 | P1 | `bee-sting.callouts` | One warning item, "gọi 115" | `{emergency}`; **many stings (wasps or hornets) → hospital even if well** (VN reports of AKI and rhabdomyolysis); mouth or throat sting; previous severe reaction. Don't: squeeze, lime, toothpaste. | NHS; ASCIA; VN hospital reports (clinician to set a threshold) |
| F-RB-1 | P3 | `rove-beetle.steps[1].body` | "Nếu lỡ chạm hoặc chà xát…" | Wash the skin, hands, clothes and towels | DermNet |
| F-RB-2 | P2 | `rove-beetle.callouts` | One item | Don't: crush, rub, scratch, toothpaste, fish sauce. Warning: fluid in the eye; infection. **Region:** SEA, South Asia, Africa, Middle East only. Hide or de-rank in US/UK/CA/NZ (§4.5). | DermNet |
| F-EAR-1 | P2 | `ear-insect.steps` | Flashlight only | Adds "Nhỏ vài giọt dầu" (olive or baby oil, not warm) **only if there are no ear tubes, perforation or discharge** | AAP HealthyChildren; RCH Melbourne (verify) |
| F-EAR-2 | P2 | `ear-insect.callouts` | — | Don't: hot oil, alcohol, water. Warning: **a button battery or magnet in the ear or nose → emergency department**. | NCPC battery guideline |
| F-SNK-0 | P2 | `snake-bite.banner` | null | `{emergency}` or the nearest hospital with antivenom | WHO SEARO 2016 |
| F-SNK-1 | **P0** | `snake-bite.steps` | "Băng nhẹ, tháo trang sức / Quấn gạc nhẹ quanh vết cắn…"; "Ghi nhớ hình dạng, màu sắc của rắn" | Carry the child; remove rings; **splint the whole limb** at heart level; **pressure bandage only if a cobra or krait is suspected; pit viper: splint only**; photo from a distance, don't catch or kill it | WHO SEARO 2016; VN practice (Bạch Mai / Tuổi Trẻ); PLoS NTD 2016 review |
| F-SNK-2 | P1 | `snake-bite.callouts` | "Garo hay buộc chặt"; "Chườm đá, bôi thuốc" | + cutting, sucking, leaves, herbal remedies, **thầy lang**; neurotoxic signs (ptosis, dysphagia) and bleeding gums → `{emergency}` | WHO SEARO |
| F-SNK-3 | P2 | (country) | — | **AU:** ANZCOR 9.4.1 uses pressure immobilisation for all Australian snakes, so the en text is wrong there. **US:** no bandage at all (AHA/Red Cross 2024). Needs per-country variant overrides (§4.5). | ANZCOR; AHA/ARC 2024 |

### 2.6 Health (TH20–TH24)

| ID | Sev | Path | Current | Proposed | Source |
|---|---|---|---|---|---|
| F-HS-1 | P1 | `heatstroke.steps[0].body` | "Tình trạng không khá lên: gọi 115" | Drowsy, confused, seizure or not improving → `{emergency}` now | ERC 2025 FA |
| F-HS-2 | P1 | `heatstroke.steps[1].body` | "…Đắp khăn mát ở nách, bẹn, cổ." | **Wet the whole body and fan continuously**, plus cool cloths | ERC 2025 FA / ILCOR (whole-body cooling) |
| F-HS-3 | P1 | `heatstroke.steps[2].body` | "Nước hoặc dung dịch điện giải…" | ORS sips if alert; **under 6 months: breast milk or formula** (not water) | WHO; AAP |
| F-HS-4 | P1 | `heatstroke.callouts` | — | Don't: alcohol or ice-cold sponging; **fever medicine (ineffective)**. Warning: a child left in a hot car. | AAP; CDC |
| F-TMP-1 | P1 | `temperature.steps` | "Nhiệt kế điện tử hoặc hồng ngoại… Hồng ngoại: đo ở trán hoặc tai"; "Đợi 15 phút sau khi ăn uống" | Digital armpit for every age; **ear only from 6 months**; forehead as a screen only, re-check in the armpit; **no forehead strips, no mercury**; "đo lúc bé nằm yên" (the 15-min rule is for oral thermometers) | NICE NG143; AAP; Minamata |
| F-TMP-2 | P1 | `temperature.callouts` | "3 tháng – 3 tuổi: trên 38,5°C theo dõi sát…"; "Trên 3 tuổi: sốt kéo dài…" | < 3 mo ≥ 38 °C; **3–6 mo ≥ 39 °C same day; fever ≥ 5 days**; **dengue signs → see a doctor, no ibuprofen or aspirin**; non-blanching rash, stiff neck, fontanelle; hard to wake, not drinking, little urine. Don't: cold or alcohol sponging, cạo gió, bundling up, aspirin. en adds °F. | NICE NG143/NG240; WHO dengue; Bộ Y tế SXH 2023 |
| F-TMP-3 | P2 | all °C in en | "38°C" | "38°C (100.4°F)", "39°C (102.2°F)". A `{temp:38}` token is an option later. | — |
| F-FP-1 | P1 | `food-poisoning.steps` | "Cho uống nhiều nước, dung dịch bù nước…" | **ORS spoon by spoon after each loss; mix exactly per the packet (never stronger)**; keep breastfeeding; no antidiarrhoeals, **antiemetics or antibiotics** without a prescription (VN pharmacies sell them freely); wet-diaper count; early refeeding, no fizzy drinks or juice | WHO/UNICEF 2005, 2024; NICE CG84 |
| F-FP-2 | P1 | `food-poisoning.callouts` | "Nôn kéo dài trên 12 giờ" | Sign-based: vomits everything (IMCI), **green vomit, blood in stool**, dehydration signs, under 6 months, severe or distended abdomen. Don't: concentrated Oresol, soft or sports drinks, stopping food. | WHO IMCI; NICE CG84 |
| F-CD-1 | P2 | `cold-exposure.steps[1].body` | — | + hat and socks; **skin-to-skin** for babies | WHO thermal care |
| F-CD-2 | P1 | `cold-exposure.steps[2].body` | "Nước ấm hoặc sữa ấm." | **Under 6 months: only breast milk or formula**; no drinks if drowsy | WHO |
| F-CD-3 | P1 | `cold-exposure.callouts` | — | Don't: rubbing with alcohol or balms, cạo gió, hot baths, open fire, **charcoal in a closed room (CO)**. Warning: cold, sleepy newborn. | WHO; Bạch Mai Poison Control CO advice |
| F-JD-1 | P1 | `jaundice.main.banner` | null | Visual estimation is unreliable → ask for a bilirubin test; daylight; **darker skin: sclera, gums, palms** | NICE CG98 |
| F-JD-2 | P1 | `jaundice.callouts` | "Vàng nhẹ ở mặt, cổ, ngực, bụng trên rốn" (zone reassurance); "Xuất hiện ngay ngày đầu"; warning "Nghi vàng da bệnh lý: đưa bé đi khám ngay" (circular) | Drops "bụng trên rốn"; **"trong 24 giờ đầu"**; palms and soles; pale stools and dark urine; new box "Không nên": **phơi nắng**, water or sugar water, stopping breastfeeding; warning = **acute bilirubin encephalopathy signs** (lethargy, arching, high-pitched cry, seizure) | NICE CG98; AAP 2022 |
| F-JD-3 | P2 | image `so-sanh-vang-da` | Realistic newborn faces | Clinician review of skin tones; add a darker-skin example | NICE CG98 |

### 2.7 Pack level, English and the system

| ID | Sev | Path | Issue | Proposal |
|---|---|---|---|---|
| F-SYS-1 | P0 outside VN | 20 fields / 40 strings; `emergencyNumber`; `first_aid_modes.dart:110` fallback `'115'` | Hard-coded number | §4: `{emergency}` and `{poison}` tokens, a per-country table, and a lint that rejects literal 3–4-digit emergency numbers in text |
| F-SYS-2 | P1 | `review: null` | No reviewer recorded | Must be set at prod approval (P-141) |
| F-SYS-3 | P2 | callouts can't hold images | `ngua-dau-sai` (Don't image) dropped | Optional schema change, `callout.image` |
| F-SYS-4 | P2 | bitmaps with baked ✓/✗ badges (`cui-dau-bop-mui`, `quan-bang`, `gat-kien`, `hoa-chat`) | Can't be localised; need alt text | Alt text per locale; no text baked into new images |
| F-EN-1 | P3 | en heading "Take baby to hospital right away if" on pages that show a preschooler | Reads oddly | "Go to hospital right away if" on child pages; infant pages keep "Take baby…" |
| F-EN-2 | P3 | en "the operator" | US says "dispatcher", UK "call handler" | Keep "operator"; it is understood everywhere |
| F-EN-3 | P2 | "Plaster" keyword (UK) vs US "Band-Aid/bandage" | — | Add "Band-Aid" as a keyword (≤ 20 keywords) |
| F-EN-4 | P2 | "70% alcohol" | US "rubbing alcohol" | Done in the dog-bite step |
| F-CAT-1 | P3 | `categories[wounds].title` | Sprain, fracture, eye, head and teeth are not "wounds" | "Chấn thương & bỏng" / "Injuries & burns" |
| F-QS-1 | P3 | `quickSearch` (6) | Missing fever, seizure, burn, head bump | 12 entries (in the JSON) |
| F-KW-1 | P3 | `cpr.keywords` "Đuối nước" | Drowning now has its own page | Keep (it still helps search); the drowning page links CPR |

---

## 3. P0 texts, quoted (vi / en)

**Infant compressions** (`cpr.variants[under-1].steps[3].body`):
- vi: "Hai tay ôm quanh ngực bé, hai ngón cái đặt cạnh nhau ở nửa dưới xương ức, ngay dưới đường nối hai núm vú. Ấn sâu 1/3 bề dày ngực (khoảng 4 cm), 100–120 lần/phút, để ngực nở lại hết sau mỗi lần. Không ôm được ngực: dùng gót một bàn tay."
- en: "Wrap both hands around baby's chest with your thumbs side by side on the lower half of the breastbone, just below the nipple line. Press down a third of the chest depth (about 4 cm / 1½ in), 100–120 times a minute, letting the chest come all the way back up. If you can't wrap your hands around, use the heel of one hand."
- `cpr[id=infant].compressionText`:
  - vi: "Hai ngón cái giữa ngực, hai tay ôm quanh ngực bé, ấn sâu khoảng 4 cm. Ấn theo nhịp tiếng bíp."
  - en: "Both thumbs on the middle of the chest, hands wrapped around it; press about 4 cm (1½ in) deep. Press with the beep."

**Choking, from 1 year** (`choking.variants[from-1].steps`):
1. "Vỗ lưng 5 lần" / "Give 5 back blows", count 5:
   - vi: "Đứng hoặc quỳ phía sau, hơi lệch sang bên. Một tay đỡ ngực, cho bé cúi người ra trước. Dùng gót bàn tay vỗ mạnh 5 lần giữa hai bả vai. Bé nhỏ: có thể đặt nằm sấp ngang đùi bạn, đầu thấp."
   - en: "Stand or kneel behind and slightly to the side. Support the chest with one hand and lean the child forward. With the heel of your other hand, strike firmly 5 times between the shoulder blades. A small child can lie face-down across your lap, head low."
2. "Ép bụng 5 lần" / "Give 5 abdominal thrusts", count 5:
   - vi: "Quỳ hoặc đứng sau lưng bé, vòng tay ôm eo. Đặt nắm tay giữa rốn và đầu dưới xương ức, tay kia ôm lấy nắm tay. Giật mạnh vào trong, lên trên, 5 lần."
   - en: "Kneel or stand behind and wrap your arms around the waist. Put a fist between the navel and the bottom of the breastbone and grasp it with your other hand. Pull sharply inwards and upwards, 5 times."
3. "Lặp lại đến khi dị vật ra" / "Repeat until the object comes out":
   - vi: "Xen kẽ 5 lần vỗ lưng và 5 lần ép bụng. Chưa ai gọi cấp cứu: gọi {emergency}, bật loa ngoài."
   - en: "Alternate 5 back blows and 5 abdominal thrusts. If nobody has called for help yet: call {emergency} on speaker."
4. "Bé lả đi: hồi sức tim phổi" / "Child goes limp: start CPR":
   - vi: "Đặt bé nằm ngửa trên mặt phẳng cứng, gọi {emergency} và bắt đầu hồi sức tim phổi (CPR). Trước mỗi lần thổi ngạt, nhìn vào miệng: thấy dị vật thì lấy ra."
   - en: "Lay the child on their back on a firm surface, call {emergency} and start CPR. Before each set of breaths, look in the mouth and take out any object you can see."

**Infant chest thrusts** (`choking.variants[under-1].steps[1].body`):
- vi: "Lật bé nằm ngửa dọc cẳng tay, đầu thấp hơn ngực. Ấn mạnh, dứt khoát 5 lần vào nửa dưới xương ức, ngay dưới đường nối hai núm vú, bằng gót một bàn tay hoặc hai ngón cái."
- en: "Turn baby face-up along your forearm, head lower than the chest. Give 5 sharp, firm pushes on the lower half of the breastbone, just below the nipple line, with the heel of one hand or both thumbs."

**Anaphylaxis, step 1** (`anaphylaxis.main.steps[0]`), "Tiêm adrenaline ngay nếu có" / "Use the adrenaline pen if you have one":
- vi: "Bé có bút tiêm adrenaline do bác sĩ kê: tiêm ngay vào mặt ngoài đùi, qua quần áo cũng được. Đây là thuốc quan trọng nhất. Không có bút: gọi {emergency} ngay."
- en: "If your child has an adrenaline (epinephrine) auto-injector, use it now in the outer thigh, through clothing if needed. It is the most important treatment. If you don't have one, call {emergency} straight away."

**Snake bite** (`snake-bite.main.steps[1..2]`):
- vi: "Tháo nhẫn, vòng, quần áo chật gần vết cắn. Nẹp cả chi bị cắn như khi gãy xương, để ngang tầm tim." / "Nghi rắn hổ mang, cạp nong, cạp nia: quấn băng thun từ vết cắn lên hết chi, chặt như băng bong gân, vẫn luồn được một ngón tay. Rắn lục (vết cắn sưng nhanh, chảy máu): chỉ nẹp, không băng ép."
- en: "Take off rings, bracelets and tight clothing near the bite. Splint the whole bitten limb as for a broken bone, at about heart level." / "If it may be a cobra or krait: wrap an elastic bandage from the bite up the whole limb, as firm as for a sprain, so a finger still slips under. For pit vipers (fast swelling, bleeding at the bite): splint only, no pressure bandage."

---

## 4. Multi-country convention

### 4.1 Count

`115` appears **40 times: 20 vi plus 20 en, in 20 string fields across 13 situations**:

| Situation | Fields with "115" |
|---|---|
| cpr | 4 |
| choking | 3 |
| milk-aspiration | 1 |
| apnoea | 1 |
| seizure | 1 |
| anaphylaxis | 2 |
| poisoning | 1 |
| traffic | 1 |
| bleeding | 1 |
| fracture | 1 |
| bee-sting | 1 |
| heatstroke | 2 |
| temperature | 1 |

The number also appears in:
- `pack.emergencyNumber`
- the hard-coded fallback in `apps/mobile/lib/features/first_aid/first_aid_modes.dart:110`
- the portal placeholder and help text

The Lumi health pack already has `regions: [{country, emergencyNumber}]` and `emergencyNumberFor(country)` (`apps/mobile/lib/features/rhythm/rhythm_models.dart:726`). The first-aid pack should reuse that pattern rather than invent a second one.

### 4.2 Proposed convention

1. **Tokens in text.** Exactly two tokens are allowed in any `{vi,en}` string:
   - `{emergency}`: the ambulance number for the resolved country.
   - `{poison}`: renders "<poison-centre label> <number>" when the country has a verified public line. Otherwise it renders the `{emergency}` number. Write sentences so both readings work, for example "Gọi {poison} ngay" reads as "Gọi 115 ngay" in VN and "Call Poison Control 1-800-222-1222 now" in the US.
2. **Schema** (`packages/contracts/src/first-aid.ts`):
   - Add `regions: z.array({ country: /^[A-Z]{2}$/, emergency: /^[0-9]{2,4}$/, poison: { number, label: loc(40), hours?: string } | null, cprSequence: 'breathsFirst' | 'compressionsFirst' }).max(60)`.
   - Keep `emergencyNumber` as the default when the country is unknown.
   - Add a `superRefine` that rejects any token other than these two, requires the same tokens in vi and en, and rejects literal emergency numbers in text (`/\b(115|911|999|000|112|995|119|1669)\b/`).
   - Validate lengths with `{poison}` expanded to its longest value. I used 30 characters.
3. **Country resolution:** family profile country, then the device locale or SIM region, then a one-time picker. **Never silently fall back to 112.** In Việt Nam, 112 is search and rescue, not an ambulance. Show the resolved number and country in the call bar, for example "Gọi 115 · Việt Nam", with a way to change it.
4. **Call bar:** the red pill and bottom button dial `{emergency}`. The poisoning page gets a second button for the poison line when one exists.
5. **Units:** for v1, write dual units in the en text, for example "38°C (100.4°F)" and "about 4 cm (1½ in)". Later, a `{temp:38}` / `{cm:4}` formatter keyed on country can replace this.
6. **Region-scoped content (schema change, P2):** optional `countries: { include?: string[], exclude?: string[] }` on a situation, a variant or a callout item. Uses:
   - Show rove beetle in VN and SEA only.
   - AU and US variants of the snake-bite steps.
   - Show the dengue item in tropical countries.
   - "Don't wait to watch the dog" for VN and SEA.
7. **Folk practices:** keep Vietnamese "don'ts" in both vi and en. The diaspora often runs the app in English, and naming toothpaste, fish sauce, egg white, cạo gió (coin-rubbing) or sun exposure for jaundice is harmless for other readers. Keep python fat (mỡ trăn) in vi only.

### 4.3 Per-country numbers (checked 2026-10-16)

"Verified" means I confirmed the number against an official or primary source in this session. "Known" means it's from my own knowledge and well-established, but I didn't re-check it. "Unverified" means sources conflict or I couldn't confirm. **For any country without a verified poison line, `{poison}` should fall back to `{emergency}`.**

| Country | Ambulance `{emergency}` | Poison line `{poison}` | Status |
|---|---|---|---|
| VN | **115** (113 police, 114 fire) | None verified. Trung tâm Chống độc BV Bạch Mai exists, but I couldn't confirm a public hotline. Fall back to 115. | Ambulance known; poison **unverified** |
| US | **911** | Poison Control **1-800-222-1222** | Verified (poison.org) |
| CA | **911** | **1-844-764-7669** (1-844-POISON-X); Québec **1-800-463-5060**; Nunavut: local public health | Verified (Health Canada, AboutKidsHealth) |
| GB | **999** (112 also works) | No public poison line; **NHS 111**. Northern Ireland's 111 coverage is uncertain. | Known; NI unverified |
| AU | **000** (112 from mobiles) | Poisons Information Centre **13 11 26** | Known (not re-checked) |
| NZ | **111** | National Poisons Centre **0800 764 766** | Known (not re-checked) |
| SG | **995** (1777 non-emergency ambulance) | Three conflicting numbers found (6423 9119, 6775 4595, 1800 223 0123). Fall back to 995. | Poison **unverified** |
| PH | **911** | UP-PGH National Poison Management and Control Center, (02) 8524-1078 | Poison **unverified** |
| MY | **999** (112 from mobiles) | National Poison Centre (USM Penang): 04-657 0099 vs 1-800-88-8099 conflict | Poison **unverified** |
| ID | **119** (health emergency, PSC 119) / **112** (general, many cities); 118 is a legacy ambulance number | HaloBPOM **1500533** (BPOM consumer line, not a dedicated poison centre) | Ambulance **unverified** nationally; HaloBPOM verified as BPOM's line |
| TH | **1669** | Ramathibodi Poison Center **1367** (24/7) | Verified (rama.mahidol.ac.th) |
| JP | **119**; child health advice #8000 | 中毒110番 Osaka **072-727-2499** (24 h); Tsukuba **029-852-9999** (9:00–21:00) | Verified (prefectural pages) |
| KR | **119** | No public poison line found; use 119 | Ambulance known; poison none |
| TW | **119** | Taipei Veterans General Hospital Poison Center: 02-2875-7525 vs 02-2871-7121 conflict | Poison **unverified** |
| DE | **112** | Giftnotruf is regional: city area code + 19240 (e.g. Berlin 030 19240). Fall back to 112 unless the region is known. | Known (not re-checked) |
| FR | **15** (SAMU) or 112 | Centres antipoison are regional (e.g. Paris 01 40 05 48 48). Fall back to 15. | Known (not re-checked) |

### 4.4 CPR sequence by country (decision F-CPR-4)

| | Breaths-first (5 initial breaths, then 30:2) | Compressions-first (30:2, C-A-B) |
|---|---|---|
| Bodies | ERC 2025 / RCUK (EU, UK); used by most VN paediatric teaching | AHA 2025 (US, CA via Heart & Stroke); ANZCOR (AU, NZ) |
| Proposal | Default (VN, GB, DE, FR, and SEA unless a local body says otherwise) | `cprSequence: 'compressionsFirst'` for US, CA, AU, NZ |

The current CPR mode runs off the protocol (compressions and breaths), not step order. I checked `first_aid_modes.dart`. So a compressions-first variant only needs reordered steps. The clinician must still sign off the default.

### 4.5 Content that should change by country

- **Snake bite.** AU uses pressure immobilisation for all snakes. US uses no bandage. VN, SEA and WHO use a splint, plus pressure only for elapids.
- **Rabies.** In VN, SEA, PH, ID and TH, the wording "don't wait" is right. In US, CA and GB, a dog bite is low risk, but bats are a risk in the US and AU.
- **Rove beetle.** Show in SEA, South Asia, Africa and the Middle East only.
- **Dengue warning.** Tropical countries only.
- **Thermometer.** US parents are taught rectal measurement for under-3-month-olds (AAP). The draft says armpit for all ages, which NICE supports. The clinician can either add a US note or accept armpit.
- **Breast milk in the eye, cạo gió, phơi nắng vàng da.** Vietnamese practices, kept in both locales.

---

## 5. Gap analysis

There are 25 situations today and the cap is 40, which leaves 15 slots. I drafted 10, which brings the total to 35 and leaves 5 slots for later.

| Rank | New id | Why | Category / flags |
|---|---|---|---|
| 1 | `drowning` (TH25) | One of the leading causes of child death in VN (UNICEF/WHO estimate ≈ 2,000 child drownings a year; figure to be checked). It is the top injury killer of 1–4-year-olds in the US and AU. The VN practice of holding a child upside down and running to "drain water" delays CPR. Drowning needs breaths early (ERC/AHA 2025). | urgent, emergency |
| 2 | `swallowed-object` (TH28), variants battery-magnet / other | Button batteries cause oesophageal burns within about 2 h. Honey at ≥ 12 months within 12 h (Poison Control: 10 ml every 10 min, ≤ 6 doses). Multiple magnets cause bowel perforation. Fish bone with rice is a VN practice. Today these exist only as a keyword. | urgent, emergency |
| 3 | `unconscious` (TH26), age variants | The recovery position is a core first-aid skill and several pages refer to it ("nằm nghiêng an toàn") without teaching it. The infant version (held on the side in arms) is different. | urgent, emergency |
| 4 | `head-injury` (TH27) | Falls from beds and stairs are the most common paediatric injury. Parents need the NICE/NHS red flags and "an adult with the child for 24 h". "Lăn trứng" is a VN practice. | wounds, monitoring |
| 5 | `electric-shock` (TH29) | Household 220 V, exposed sockets and chargers; the rescuer's own safety comes first. | urgent, emergency |
| 6 | `asthma-attack` (TH34) | Common chronic disease. Reliever plus spacer, 1 puff every 30–60 s up to 10, then call (NHS / Asthma + Lung UK). Steam and cough syrup are VN practices. | health, emergency |
| 7 | `allergic-reaction` (TH31) | Separates mild hives from anaphylaxis, so the anaphylaxis page isn't over-triggered and parents watch for escalation. | health, monitoring |
| 8 | `chemical-burn` (TH30) | Slaked lime (vôi) and drain cleaner are common in VN homes and building sites. Brush off dry powder, rinse 20 min, never "neutralise". | wounds |
| 9 | `breath-holding` (TH32), 6 mo–6 y | A frequent, frightening, benign event that parents confuse with seizures or apnoea. Iron deficiency link (AAP). | health, monitoring |
| 10 | `dental-injury` (TH33), baby / adult tooth | Knocked-out adult tooth: replant or store in milk within 60 min. Never replant a baby tooth (IADT 2020). | wounds |

Also added inside existing pages:
- chemical eye splash (3rd `eye-injury` variant)
- dehydration and ORS (`food-poisoning`)
- exhaust-pipe and iron burns (`scald` scope)
- carbon monoxide from charcoal (`cold-exposure` don't)
- hot car (`heatstroke` warning)

Not drafted, for the 5 remaining slots, in priority order:
- **Jellyfish sting.** Regional: vinegar for tropical box jellyfish in AU, hot water elsewhere. Needs country scoping.
- **Finger crush / door / nail injury.**
- **Sunburn.**
- **Croup / stridor at night.** Borderline: not first aid, but a common 2 a.m. fear.
- **Carbon-monoxide poisoning** as its own page, given the northern VN winter.
- **Poisonous plants and mushrooms.** Can share the poisoning page.
- **Fever.** Already covered by `temperature`. Consider renaming it "Sốt và đo thân nhiệt" for search.

---

## 6. Must be signed by a licensed clinician before prod

The signatory should be a paediatric emergency physician, ideally with a VN practising licence, plus an ERC/AHA instructor for CPR and choking. They must record `review.reviewer`, `review.reviewedOn` and `review.sources` (P-141).

1. **CPR default sequence** (breaths-first vs compressions-first) and the per-country override (F-CPR-4).
2. **CPR wording.** Infant two-thumb text, depths, lone rescuer with no phone (1 min vs 2 min), AED wording, and every replacement CPR and choking illustration (`ep-tim-so-sinh-hai-ngon-cai`, `an-nguc-hai-ngon-cai`, `vo-lung-tre-lon`, `mo-duong-tho-so-sinh`) before upload.
3. **Choking.** Both variants, including the "goes limp" step and the "always get checked after thrusts" rule.
4. **Milk aspiration and newborn apnoea.** Escalation thresholds, and whether `apnoea` should exist as a parent page at all, or point to CPR plus urgent review.
5. **Anaphylaxis.** The adrenaline step as written for a market where auto-injectors are rare, the second-dose timing, and the positions.
6. **Snake bite.** The VN species wording (rắn hổ mang, cạp nong, cạp nia vs rắn lục), pressure-bandage instructions for lay parents, and the AU/US overrides.
7. **Poisoning numbers.** Every entry in §4.3 marked unverified or known, plus the VN poison line. Prefer a verified Bạch Mai hotline, or no `{poison}` in VN.
8. **Fever thresholds.** NICE 3–6 months ≥ 39 °C vs the BV Nhi TW 38.5 °C medication practice, the dengue NSAID warning, and ear thermometers from 6 months vs NICE's 4 weeks.
9. **ORS wording.** Oresol packet sizes sold in VN, and zinc (WHO recommends it for children with diarrhoea in LMICs; it is omitted here and needs a doctor).
10. **Button battery and honey.** Dose, age and time window, wording on "don't delay", and the magnet rule.
11. **Rabies wording.** VN vs CDC observation, and bats and monkeys.
12. **Multiple wasp stings.** Whether to state a number of stings that triggers hospital.
13. **Traffic page.** Helmet removal, and the advice for when parents must self-transport, given real VN ambulance delays.
14. **Head-injury red flags and the "adult present 24 h" wording.**
15. **The 10 new pages**, including the asthma 10-puff regimen (some countries use 4×4×4) and the dental storage media.
16. **Jaundice visuals.** `so-sanh-vang-da` skin tones, and the darker-skin advice.
17. **Traditional-practice don'ts.** Wording per item, so they correct without blame (consistent with library SEED-NOTES §0): thầy lang, cạo gió, phơi nắng, nước mắm, mỡ trăn, sữa mẹ nhỏ mắt, lăn trứng.

Engineering items (not clinical):
- Schema for `regions`, tokens and region scoping.
- Removing the `'115'` fallback in `first_aid_modes.dart:110`.
- Seed-script substitution of `{emergency}` until the renderer ships.
- Alt text for badge bitmaps.
- Upload the new images listed in `newImagesNeeded`.
- Update `SEED-NOTES.md` §2.4: `ep-tim-tre-lon` now exists.
- The portal's first-aid preview must render the tokens.

---

## 7. Sources consulted

- AHA/AAP 2025 Part 6 Pediatric BLS (Pediatrics 157(1) e2025074350; AHA newsroom Oct 2025; HealthyChildren summary). The cpr.heart.org page returned 403, so I used the official summaries.
- RCUK 2025 Paediatric Basic Life Support guidelines (resus.org.uk; read in full). ERC 2025 Paediatric Life Support (Resuscitation 2025) and Executive Summary.
- Poison Control (poison.org) Button Battery Ingestion Triage and Treatment Guideline (read). ESPGHAN 2021 button-battery position paper.
- NHS Febrile seizures (read). NHS Nosebleed, Burns and scalds, Head injury, Insect bites, Asthma attack, Broken bones.
- NICE NG143, CG98, NG232, CG84, NG240 (from knowledge; nice.org.uk returned 403).
- WHO: Rabies position paper (WER 2018) and WHO rabies material; WHO SEARO snakebite guidelines (2016); systematic review in PLoS NTD 2016 (PMC5066967); UN Snakebite SOP 2024; The treatment of diarrhoea (2005); dengue guidance.
- ASCIA Action Plan for Anaphylaxis. British Burn Association / London & South East Burn Network (20 min, within 3 h). IADT 2020 dental trauma guidelines.
- Health Canada 1-844-POISON-X release (2023). Ramathibodi Poison Center contact page. Japan Poison Information Center (Kanagawa, Tochigi and Okayama prefectural pages). HaloBPOM (pom.go.id).
- Tuổi Trẻ, "Rắn lục đuôi đỏ cắn: chỉ nẹp, không băng garo"; Vinmec snakebite first aid (VN practice).
