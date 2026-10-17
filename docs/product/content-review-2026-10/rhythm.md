# Nhịp lớn lên: content review (draft, not certified)

**Scope.** `content/rhythm/reference.seed.json` (ref_20261015_01, 10 stages) and `content/rhythm/content.seed.json` (rc_20261015_01: 37 activities, 35 age cards, health pack), read against `SEED-NOTES.md` and `packages/contracts/test/rhythm-content-seed.test.ts`.

**Who wrote this.** An AI reviewer drafted it, taking the roles of a paediatrician, an IBCLC lactation consultant and a child-development specialist. **It is not a clinical sign-off.** It does not replace the signed review that D-058 / `rhythmActSchema` requires, and nothing in it may be quoted as "reviewed by experts". Every proposed item keeps `review: null`.

**Outputs.**
- This file.
- `additions/rhythm.json`, which contains:
  - 16 new activities;
  - 72 replacements (P1–P3; the 13 identical week-card fever lines are one row in the table below);
  - 27 emergency-number additions;
  - 3 stage-link suggestions;
  - answers to §6.

  It was checked against the real `rhythmContentSchema` (built contracts `dist`), with all replacements applied, and passes. It also meets the seed-test constraints for new items: steps 3–5, sources 1–3, https only, `review: null`, `ageDays.to ≤ 760`, vi/en lists of equal length, unique ids and countries, and stage links that overlap the stage window.

**Severity scale.**
- **P0**: causes harm or contradicts current guidance.
- **P1**: wrong or misleading, or a safety-critical omission.
- **P2**: localisation or multi-country issue.
- **P3**: tone, clarity, consistency or typo.

---

## 1. Executive summary: top 10

**No P0 in the text as written.** Nothing in the seed contradicts current WHO, AAP 2022, NHS, NICE or CDC 2022 guidance. The draft is careful and well hedged.

The real risks are **safety-critical omissions for the Vietnamese and South-East Asian setting**, plus several milestone flags that fire too early.

1. **Bed-sharing has no harm-reduction guidance (P1).** Most Vietnamese families bed-share. "Own cot only" advice tends to be ignored as a whole, so the rules that prevent deaths never reach these families: no sofa or armchair, no alcohol, smoking or sedating medicine, not between two adults, not with preterm or low-birthweight babies, no swaddling. I drafted `act_bed_sharing_safer` (NHS/UNICEF UK style, opening with "safest is own cot next to your bed"). It needs an explicit paediatric decision.
2. **Vietnamese sleep hazards are not named (P1).** These are võng (hammock), nôi điện (automatic swings), gối chặn / gối chống bẹp đầu (positioners and "flat-head" pillows), *ủ ấm* (overheating), and *nằm than* (charcoal braziers in closed postpartum rooms, a carbon monoxide risk). Fixes are in `act_safe_sleep_check`; `act_calm_night_feed` also gets the AAP "sofa/armchair is the most dangerous place" line.
3. **Teething (P1).**
   - Vietnamese families mostly use **vòng dâu tằm** (mulberry-wood beads), plus silver anklets and bracelets, not amber. The FDA 2018 warning covers all teething jewellery.
   - **Rubbing gums or tongue with honey** (*rơ lưỡi/rơ nướu mật ong*) is a botulism risk and is not mentioned.
   - Add that teething does not cause significant diarrhoea, which is a common belief.
4. **Solids (P1).**
   - Move `act_first_foods` from day **165 to 183**, so it matches WHO and the Vietnamese MoH (exclusive breastfeeding to 6 months).
   - Reword "never before 4 months", which reads as permission at 4 months.
   - Add **allergen introduction** (ASCIA/NHS/NIAID; this is current guidance in AU, UK and US and is entirely missing).
   - Name the Asian **choking foods**: longan, lychee, rambutan, konjac mini jelly cups, sticky rice cakes, fish bones.
   - Add Vietnamese seasoning (nước mắm, hạt nêm, MSG) and "thick, not watery" porridge.
5. **Drowning prevention is absent (P1 gap).** Drowning is a leading cause of child death in Việt Nam: about 2,000 child deaths a year per MoH/WHO 2025. Water jars, basins and ponds are everyday hazards. I drafted `act_water_safety_home`.
6. **Water, heat and formula (P1/P2).**
   - Say clearly that a breastfed baby under 6 months needs **no water even in hot weather** (WHO/UNICEF; 2024 systematic review).
   - Add the hot-weather nuance for formula-fed babies (NHS) and safe formula preparation (water ≥70 °C, WHO 2007).
   - I drafted `act_hot_weather_comfort`.
7. **Milestone flags fire early, and preterm babies are not handled (P1).**
   - Week 7 flags "no social smile" before 2 months.
   - Week 13 and month 3 flag head control that CDC puts at 4 months.
   - Month 4 flags reaching, a 6-month item.
   - Month 9 says "can't sit **even with support**", which is too lenient at 9 months.
   - Cards use actual age, but milestone expectations for preterm babies should use **corrected age** until 24 months.
8. **US/UK-specific schedules (P2).** "2-month vaccinations", "12-month vaccinations" and "the 9/18/24-month visit" are wrong for some markets: AU, NZ and PH start at 6 weeks, and VN/PH/ID/MY give measles at 9 months. Use "your local schedule" and "at routine check-ups".
9. **Fever and health routing (P2).**
   - State the thermometer method: digital, usually under the arm (NICE).
   - Add a low-temperature danger sign for young babies (<35.5 °C, WHO IMCI).
   - Add "no alcohol rubs" (*lau rượu*), "offer feeds" and "never aspirin".
   - Add when to call for a seizure (first one, longer than 5 minutes).
   - Route `lost_skill` to "see a doctor within days" rather than emergency.
   - Missing signs need a contracts change: non-blanching rash, dengue warning signs, green vomit, button-battery or poison ingestion.
10. **12–24 months is thin, and family wellbeing is minimal.**
    - Only 2 of 37 activities start at 12 months or later.
    - Parental mental health appears in only 2 week cards.
    - Nothing covers partner involvement, oral hygiene, potty readiness, sun or mosquitoes, car seats, or active play.
    - I drafted 16 activities; 5 of them start at 12 months or later, and most of the rest run to 24 months.

**Also worth fixing before prod:**
- Baby walkers (*xe tập đi*), which are very common in Việt Nam.
- Mixed English register: British spelling with US "diaper", plus "cot", "buggy" and "mum".
- Stage-linked activities that skip the age and region filters (`rhythm_calendar.dart:529`).
- Pre-stage notices that may prime parents to expect fussiness (make them opt-in).

---

## 2. Findings

### 2a. Text findings with drafted replacements

Generated from `additions/rhythm.json → replacements`; current text is taken from the seed. Sorted by severity.

| # | Path | Sev | Problem | Current (vi / en) | Proposed vi | Proposed en | Source |
|---|---|---|---|---|---|---|---|
| F01 | `activities[id=act_first_foods].ageDays.from` | P1 | Ranking 'first solid foods' from day 165 (5.4 months) nudges an earlier start than WHO and Việt Nam MoH (exclusive breastfeeding to 6 months); 183 still touches stage_05 (168–188). | 165 | 183 | 183 | WHO IYCF fact sheet; WHO complementary feeding guideline 2023 |
| F02 | `activities[id=act_first_foods].safety` | P1 | 'Don't start before 4 months' reads as permission at 4 months (common grandparent practice in VN); VN seasoning habits (nước mắm, hạt nêm) not covered. | Luôn ngồi cạnh khi con ăn, con phải ngồi thẳng. Không cho mật ong trước 12 tháng, không nêm muối hay đường, không cho hạt nguyên. Không bắt đầu ăn dặm trước 4 tháng tuổi. / Always stay with baby while they eat, sitting upright. No honey before 12 months, no added salt or sugar, no whole nuts. Don’t start solids before 4 months. | Luôn ngồi cạnh khi con ăn, con phải ngồi thẳng. Không cho mật ong trước 12 tháng; không nêm muối, đường, nước mắm, hạt nêm hay bột ngọt; không cho hạt nguyên. Khuyến nghị chung là bắt đầu khi con khoảng 6 tháng; nếu định cho ăn sớm hơn, hãy hỏi bác sĩ trước, và không bao giờ trước 4 tháng tuổi. | Always stay with baby while they eat, sitting upright. No honey before 12 months; no added salt, sugar, fish sauce, stock cubes or MSG; no whole nuts. The general advice is to start at around 6 months; if you’re thinking of starting earlier, ask a doctor first, and never before 4 months. | WHO IYCF fact sheet; NHS first solid foods |
| F03 | `activities[id=act_open_cup].safety` | P1 | Hot climates: giving water to breastfed infants is common in VN and displaces milk; formula-fed hot-weather nuance (NHS). | Dưới 6 tháng, bé bú mẹ hoàn toàn thường không cần thêm nước. Không cho nước ngọt, nước trái cây đóng hộp. / Under 6 months, a fully breastfed baby usually needs no extra water. Avoid sugary drinks and juice. | Dưới 6 tháng, bé bú mẹ hoàn toàn không cần thêm nước, kể cả khi trời nóng: hãy cho bú thường hơn. Bé uống sữa công thức mà trời nóng: hỏi bác sĩ về việc cho thêm nước, không bao giờ pha loãng sữa. Không cho nước ngọt, nước trái cây, trà, cà phê hay sữa đặc có đường. | Under 6 months, a fully breastfed baby doesn’t need extra water, even in hot weather: offer the breast more often. If a formula-fed baby is in hot weather, ask a doctor about extra water, and never dilute the formula. No sugary drinks, juice, tea, coffee or sweetened condensed milk. | WHO/UNICEF; NHS Drinks and cups; AAP recommended drinks 0–5 |
| F04 | `activities[id=act_finger_foods].safety` | P1 | Common Asian choking foods (longan, lychee, rambutan, konjac jelly cups) not named. | Luôn có người lớn ngồi cạnh, con ngồi thẳng. Cắt dọc nho, cà chua bi thành 4; không cho hạt nguyên, bỏng ngô, kẹo cứng. / Always sit with baby, who should be upright. Quarter grapes and cherry tomatoes lengthways; no whole nuts, popcorn or hard sweets. | Luôn có người lớn ngồi cạnh, con ngồi thẳng. Cắt dọc nho, cà chua bi thành 4; nhãn, vải, chôm chôm bóc vỏ, bỏ hạt, cắt nhỏ. Không cho hạt nguyên, bỏng ngô, kẹo cứng, kẹo dẻo hay thạch dạng cốc nhỏ. | Always sit with baby, who should be upright. Quarter grapes and cherry tomatoes lengthways; peel, stone and chop longan, lychee and rambutan. No whole nuts, popcorn, hard sweets, gummies or mini jelly cups. | NHS Foods to avoid; AAP Choking prevention |
| F05 | `activities[id=act_safe_sleep_check].safety` | P1 | VN-common sleep products (võng, nôi điện, gối chặn, gối chống bẹp đầu) are not named; AAP: no incline >10°, no positioners. | Không cho bé ngủ trên sofa, ghế bành, gối cho bú hay ghế rung. Nếu bé ngủ quên trong ghế ô tô hay địu, chuyển con ra mặt phẳng khi có thể. / Never let baby sleep on a sofa, armchair, nursing pillow or bouncer. If baby falls asleep in a car seat or sling, move them to a flat surface when you can. | Không cho bé ngủ trên sofa, ghế bành, gối cho bú, ghế rung, võng hay nôi đưa tự động; không dùng gối chặn, gối chống bẹp đầu hay đệm nghiêng. Nếu bé ngủ quên trong ghế ô tô, địu hay võng, chuyển con ra mặt phẳng, nằm ngửa ngay khi có thể. | Never let baby sleep on a sofa, armchair, nursing pillow, bouncer, hammock or automatic swing, and don’t use wedges, positioners or ‘flat head’ pillows. If baby falls asleep in a car seat, sling or hammock, move them onto their back on a flat surface as soon as you can. | AAP safe sleep (2022) |
| F06 | `activities[id=act_safe_sleep_check].steps[4]` | P1 | Việt Nam 'nằm than' / charcoal braziers in closed postpartum rooms: carbon monoxide risk; 'ủ ấm' overheating. | Không để bé quá nóng, không trùm đầu, không hút thuốc gần bé / Don’t let baby get too hot, keep the head uncovered, keep smoke away | Không để bé quá nóng hay ủ kín, không trùm đầu; không hút thuốc gần bé, không đốt than hay bếp sưởi trong phòng kín | Don’t let baby get too hot or bundled up, keep the head uncovered; keep smoke away, and never burn charcoal or fuel heaters in a closed room | AAP safe sleep (overheating); NHS Carbon monoxide poisoning |
| F07 | `activities[id=act_calm_night_feed].safety` | P1 | Current line treats bed and chair alike; AAP: a cleared adult bed is less hazardous than a sofa/armchair if you might fall asleep. | Nếu cho bú trên giường hoặc ghế, để ý đừng ngủ quên khi bế con; buồn ngủ thì đặt con vào cũi trước. / If you feed in bed or a chair, take care not to fall asleep holding baby; if you feel sleepy, put baby in the cot first. | Nếu cho bú trên giường, dọn gối, chăn ra xa con phòng khi mình ngủ quên; tỉnh dậy thì đặt con nằm ngửa vào cũi. Không cho bú trên sofa hay ghế bành khi đang buồn ngủ: đó là chỗ nguy hiểm nhất nếu ngủ quên. | If you feed in bed, move pillows and covers away from baby in case you doze off, and when you wake, put baby on their back in the cot. Don’t feed on a sofa or armchair when you’re sleepy: that is the most dangerous place to fall asleep with a baby. | AAP safe sleep (2022) |
| F08 | `activities[id=act_swaddle_before_rolling].safety` | P1 | Traditional tight leg-binding in VN; AAP 2022 weighted products; NHS: never swaddle when co-sleeping. | Không bao giờ đặt bé đang quấn nằm sấp hay nằm nghiêng. Ngừng quấn ngay khi bé có dấu hiệu lật. Quấn chặt phần chân có thể ảnh hưởng khớp háng. / Never put a swaddled baby on their tummy or side. Stop as soon as baby shows signs of rolling. Tight wrapping around the legs can harm the hips. | Không bao giờ đặt bé đang quấn nằm sấp hay nằm nghiêng. Ngừng quấn ngay khi bé có dấu hiệu lật. Không quấn bó chân cho “thẳng chân”: chân bé cần co và dạng tự nhiên để khớp háng phát triển. Không dùng khăn hay túi ngủ có tạ, và không quấn khi ngủ chung giường. | Never put a swaddled baby on their tummy or side. Stop as soon as baby shows signs of rolling. Don’t bind the legs straight: they need to bend up and out for healthy hips. No weighted swaddles or sleep sacks, and don’t swaddle if you share a bed. | AAP safe sleep (2022); NHS SIDS; IHDI |
| F09 | `activities[id=act_gentle_burping].steps[0]` | P1 | VI '(không đỡ cổ)' literally says 'don't support the neck', contradicting the safety line 'luôn đỡ đầu và cổ'. | Bế con tựa lên vai, hoặc cho ngồi trên đùi, tay đỡ cằm (không đỡ cổ) / Hold baby against your shoulder, or sit them on your lap supporting the chin (not the throat) | Bế con tựa lên vai, hoặc cho ngồi trên đùi, một tay đỡ ngực và cằm (tránh đè vào cổ họng) | Hold baby against your shoulder, or sit them on your lap with one hand supporting the chest and chin (not the throat) | NHS (burping: support chin and chest) |
| F10 | `activities[id=act_teething_comfort].safety` | P1 | VN uses mulberry-wood bead necklaces/anklets (vòng dâu tằm) far more than amber; honey 'rơ lưỡi/rơ nướu' is a traditional botulism risk; FDA warning covers bracelets/anklets and benzocaine under 2. | Không dùng vòng hổ phách hay vòng đeo cổ, không bôi gel tê hay thuốc không có chỉ định. Mọc răng không gây sốt cao: nếu con sốt, hãy hỏi bác sĩ. / No amber or teething necklaces, and no numbing gels or remedies that weren’t prescribed. Teething doesn’t cause a high fever: if baby has a fever, ask a doctor. | Không đeo vòng hổ phách, vòng dâu tằm hay bất kỳ vòng cổ, vòng tay, vòng chân nào để “chữa” mọc răng; không bôi gel tê, không rơ nướu bằng mật ong, không dùng thuốc không được kê. Mọc răng không gây sốt cao hay tiêu chảy nhiều: nếu con sốt, hãy hỏi bác sĩ. | No amber, wooden-bead or other teething necklaces, bracelets or anklets; no numbing gels, no rubbing gums with honey, and no remedies that weren’t prescribed. Teething doesn’t cause a high fever or bad diarrhoea: if baby has a fever, ask a doctor. | FDA consumer update: Safely soothing teething pain; AAP Teething |
| F11 | `activities[id=act_floor_play].safety` | P1 | Baby walkers (xe tập đi) are widely used in VN; AAP calls for a ban, Canada banned them. Tube houses/apartments: window and balcony falls. | Luôn có người lớn trông. Dọn vật nhỏ có thể nuốt, che ổ điện, chặn cầu thang, cố định đồ đạc dễ đổ. / Always supervised. Clear small objects that could be swallowed, cover sockets, gate stairs and secure furniture that could tip. | Luôn có người lớn trông. Dọn vật nhỏ có thể nuốt, che ổ điện, chặn cầu thang, khoá cửa sổ và ban công, cố định đồ đạc dễ đổ. Không dùng xe tập đi có bánh xe. | Always supervised. Clear small objects that could be swallowed, cover sockets, gate stairs, lock windows and block balconies, and secure furniture that could tip. Don’t use a baby walker on wheels. | AAP Baby walkers: a dangerous choice; NHS Baby and toddler safety |
| F12 | `ageCards[id=age_w02].tips[3]` | P1 | Sunbathing for jaundice is a widespread VN practice; it delays assessment and risks burns/overheating. | — (new item appended) | Nếu da hay mắt con vàng, đừng tự phơi nắng hay tắm lá để chữa: hãy cho bác sĩ xem | If baby’s skin or eyes look yellow, don’t use sunbathing or herbal baths to treat it: get a doctor to check | NHS Jaundice in babies |
| F13 | `ageCards[id=age_w07].watchFor[2]` | P1 | Flagging 'no social smile' at 6–7 weeks is earlier than CDC (2 months) and causes avoidable worry. | Con chưa cười đáp lại khi người thân trò chuyện / Your baby doesn’t smile back when you talk to them | Con bú ít hẳn, khó đánh thức để bú, hoặc ít tã ướt hơn mọi khi | Your baby feeds much less, is hard to wake for feeds, or has fewer wet diapers than usual | CDC milestones 2022 |
| F14 | `activities[id=act_first_foods].steps[2]` | P2 | WHO: thin porridges/broths are low in energy; iron-rich foods first. VN practice of 'nước cháo', 'nước hầm xương'. | Cho vài thìa thức ăn nghiền mịn, mềm (rau, cháo, thịt, cá nghiền) / Offer a few spoons of smooth, soft food (vegetables, porridge, mashed meat or fish) | Cho vài thìa thức ăn mềm, nghiền hoặc dằm, đặc vừa phải: cháo đặc, rau, và món giàu sắt như thịt, cá, trứng nghiền; không chỉ cho nước cháo hay nước hầm xương | Offer a few spoons of soft mashed food, thick rather than runny: thick porridge, vegetables, and iron-rich foods like mashed meat, fish or egg; not just rice water or broth | WHO complementary feeding guideline 2023; AAP Starting solid foods |
| F15 | `activities[id=act_open_cup].summary` | P2 | EN dropped 'boiled'; tap-water safety differs by country. | Từ khoảng 6 tháng, cho con nhấp nước đun sôi để nguội bằng cốc trong bữa ăn. / From around 6 months, offer sips of water from a cup with meals. | Từ khoảng 6 tháng, cho con nhấp nước sạch đun sôi để nguội bằng cốc trong bữa ăn. | From around 6 months, offer sips of safe drinking water from a cup with meals (boiled and cooled if your tap water isn’t safe to drink). | NHS Drinks and cups |
| F16 | `activities[id=act_paced_bottle].safety` | P2 | Safe preparation of powdered formula (Cronobacter) is missing; relevant where water safety varies. | Không kê bình để con bú một mình và không cho con ngậm bình khi ngủ. Pha sữa đúng hướng dẫn trên hộp. / Never prop the bottle or leave baby alone with it, and don’t put baby to sleep with a bottle. Make up formula exactly as the pack says. | Không kê bình để con bú một mình và không cho con ngậm bình khi ngủ. Pha sữa đúng tỉ lệ trên hộp, không loãng hơn hay đặc hơn; dùng nước đã đun sôi để không quá 30 phút (vẫn trên 70°C), làm nguội rồi mới cho bú; bỏ sữa thừa sau cữ bú. | Never prop the bottle or leave baby alone with it, and don’t put baby to sleep with a bottle. Make up formula exactly as the pack says, never weaker or stronger; use water boiled no more than 30 minutes earlier (still at least 70°C), cool it before feeding, and throw away leftovers. | WHO safe preparation of powdered infant formula (2007); NHS Making up baby formula |
| F17 | `activities[id=act_safe_sleep_check].steps[3]` | P2 | Name bassinet/nôi (common) and 'next to your bed' (bridge for bed-sharing families). | Cho bé ngủ trong cũi riêng, đặt trong phòng ba mẹ ít nhất 6 tháng đầu / Baby sleeps in their own cot in your room for at least the first 6 months | Cho bé ngủ trong cũi hoặc nôi riêng, đặt sát giường trong phòng ba mẹ, ít nhất 6 tháng đầu | Baby sleeps in their own cot or bassinet in your room, next to your bed, for at least the first 6 months | AAP safe sleep; NHS SIDS |
| F18 | `activities[id=act_swaddle_before_rolling].title` | P2 | 'Quấn chũn' derives from a product name (nhộng chũn) and some such products wrap the legs; use the generic term. | Quấn chũn cho bé chưa biết lật / Swaddling before baby starts to roll | Quấn khăn cho bé chưa biết lật | Swaddling before baby starts to roll | IHDI hip-healthy swaddling |
| F19 | `activities[id=act_crying_check].safety` | P2 | Multi-caregiver households (grandparents, helpers) in VN/SEA; vigorous bouncing/tossing. | Không bao giờ lắc bé, kể cả khi đang rất mệt hay bực. Nếu thấy mình sắp mất bình tĩnh, hãy đặt con nằm ngửa trong cũi an toàn và ra ngoài vài phút. / Never shake a baby, however tired or frustrated you feel. If you feel you might lose control, lay your baby on their back in a safe cot and step away for a few minutes. | Không bao giờ lắc, tung hay xóc mạnh bé, kể cả khi đang rất mệt hay bực, và hãy dặn cả ông bà, người giúp việc. Nếu thấy mình sắp mất bình tĩnh, hãy đặt con nằm ngửa trong cũi an toàn và ra ngoài vài phút. | Never shake, throw or roughly bounce a baby, however tired or frustrated you feel, and make sure grandparents and helpers know this too. If you feel you might lose control, lay your baby on their back in a safe cot and step away for a few minutes. | AAP Abusive head trauma |
| F20 | `activities[id=act_gentle_rocking].safety` | P2 | As above. | Không bao giờ lắc bé, kể cả khi đang rất mệt hay bực. Nếu thấy mình sắp mất bình tĩnh, hãy đặt con nằm ngửa trong cũi an toàn và ra ngoài vài phút. / Never shake a baby, however tired or frustrated you feel. If you feel you might lose control, lay your baby on their back in a safe cot and step away for a few minutes. | Không bao giờ lắc, tung hay xóc mạnh bé, kể cả khi đang rất mệt hay bực, và hãy dặn cả ông bà, người giúp việc. Nếu thấy mình sắp mất bình tĩnh, hãy đặt con nằm ngửa trong cũi an toàn và ra ngoài vài phút. | Never shake, throw or roughly bounce a baby, however tired or frustrated you feel, and make sure grandparents and helpers know this too. If you feel you might lose control, lay your baby on their back in a safe cot and step away for a few minutes. | AAP Abusive head trauma |
| F21 | `activities[id=act_parent_break].safety` | P2 | As above. | Không bao giờ lắc bé, kể cả khi đang rất mệt hay bực. Nếu thấy mình sắp mất bình tĩnh, hãy đặt con nằm ngửa trong cũi an toàn và ra ngoài vài phút. / Never shake a baby, however tired or frustrated you feel. If you feel you might lose control, lay your baby on their back in a safe cot and step away for a few minutes. | Không bao giờ lắc, tung hay xóc mạnh bé, kể cả khi đang rất mệt hay bực, và hãy dặn cả ông bà, người giúp việc. Nếu thấy mình sắp mất bình tĩnh, hãy đặt con nằm ngửa trong cũi an toàn và ra ngoài vài phút. | Never shake, throw or roughly bounce a baby, however tired or frustrated you feel, and make sure grandparents and helpers know this too. If you feel you might lose control, lay your baby on their back in a safe cot and step away for a few minutes. | AAP Abusive head trauma |
| F22 | `activities[id=act_outdoor_walk].safety` | P2 | Mosquito-borne disease and urban air pollution (Hà Nội, HCMC, Jakarta, Bangkok, Manila) are routine concerns. | Bé dưới 6 tháng nên tránh nắng trực tiếp. Không trùm kín xe đẩy bằng khăn vì có thể làm bé quá nóng. / Keep babies under 6 months out of direct sun. Don’t drape a cloth over the buggy, as baby can overheat. | Bé dưới 6 tháng nên tránh nắng trực tiếp. Không trùm kín xe đẩy bằng khăn vì có thể làm bé quá nóng; dùng màn chống muỗi thoáng thay cho khăn. Những ngày không khí ô nhiễm nặng, cho con chơi trong nhà. | Keep babies under 6 months out of direct sun. Don’t drape a cloth over the buggy, as baby can overheat; use a breathable insect net instead. On days with very poor air quality, play indoors. | AAP Sun safety; WHO Ambient air quality and health |
| F23 | `activities[id=act_warm_bath].safety` | P2 | '2–3 baths a week is plenty' clashes with daily bathing in hot climates; herbal leaf baths (tắm lá) are common in VN. | Không bao giờ để bé một mình trong chậu tắm, dù chỉ một giây. Nước chỉ cần nông. Với bé sơ sinh, tắm 2–3 lần mỗi tuần là đủ. / Never leave baby alone in the bath, even for a moment. Keep the water shallow. For newborns, 2–3 baths a week is plenty. | Không bao giờ để bé một mình trong chậu tắm, dù chỉ một giây. Nước chỉ cần nông. Bé sơ sinh không cần tắm hằng ngày; trời nóng có thể tắm nhanh hoặc lau người. Tháng đầu chỉ cần nước sạch, không cần cho thêm lá, tinh dầu hay sữa tắm. | Never leave baby alone in the bath, even for a moment. Keep the water shallow. Newborns don’t need a bath every day; in hot weather a quick bath or wipe-down is fine. In the first month plain water is enough, with no added leaves, oils or bath products. | NHS Washing and bathing your baby |
| F24 | `ageCards[id=age_w01…age_w13].watchFor[0] (13 cards)` | P2 | No thermometer method stated (axillary is usual in VN; NICE uses electronic axillary under 4 weeks; forehead strips/touch unreliable); low temperature is also a young-infant danger sign. | Sốt từ 38°C trở lên: đưa con đi khám ngay, kể cả khi con trông vẫn ổn / A temperature of 38°C or higher: get your baby seen straight away, even if they seem well | Sốt từ 38°C trở lên (đo bằng nhiệt kế điện tử, thường ở nách), hoặc người lạnh dưới 35,5°C: đưa con đi khám ngay, kể cả khi con trông vẫn ổn | A temperature of 38°C or higher (digital thermometer, usually under the arm), or a cold baby below 35.5°C: get your baby seen straight away, even if they seem well | NICE NG143; WHO IMCI (young infant: <35.5°C) |
| F25 | `health.signs[id=fever_young].label` | P2 | State the method; never by touch or forehead strip. | Sốt từ 38°C trở lên ở bé dưới 3 tháng tuổi / A temperature of 38°C or higher in a baby under 3 months | Sốt từ 38°C trở lên ở bé dưới 3 tháng tuổi (đo bằng nhiệt kế điện tử) | A temperature of 38°C or higher in a baby under 3 months (measured with a digital thermometer) | NICE NG143 |
| F26 | `ageCards[id=age_w08].watchFor[3]` | P2 | Anchor the flag to an age. | Con chưa cười đáp lại khi người thân trò chuyện / Your baby doesn’t smile back when you talk to them | Đến khoảng 8 tuần, con vẫn chưa cười đáp lại khi người thân trò chuyện | By about 8 weeks, your baby still doesn’t smile back when you talk to them | CDC milestones 2022 |
| F27 | `ageCards[id=age_w13].watchFor[1]` | P2 | Steady head when held upright is a CDC 4-month milestone; at week 13 the 2-month item fits. | Con chưa giữ được đầu khi được bế thẳng / Your baby can’t hold their head up when held upright | Con chưa ngẩng đầu lên được chút nào khi nằm sấp | Your baby can’t lift their head at all during tummy time | CDC milestones 2022 |
| F28 | `ageCards[id=age_m03].watchFor[2]` | P2 | As above; soften until 4 months. | Con chưa giữ được đầu khi được bế thẳng / Your baby can’t hold their head up when held upright | Đầu con vẫn ngả hẳn, gần như không giữ được khi được bế thẳng | Your baby’s head still flops with almost no control when held upright | CDC milestones 2022 |
| F29 | `ageCards[id=age_m04].watchFor[2]` | P2 | Reaching to grab is a CDC 6-month milestone. | Con không với lấy hay không đưa đồ vật lên miệng / Your baby doesn’t reach for things or bring them to their mouth | Con không đưa tay lên miệng hoặc không nhìn theo đồ chơi | Your baby doesn’t bring their hands to their mouth or follow a toy with their eyes | CDC milestones 2022 |
| F30 | `ageCards[id=age_m09].watchFor[2]` | P2 | CDC 9 months: sits without support; WHO window ends 9.2 months. 'Even with support' is too late a flag. | Con chưa ngồi được dù có đỡ / Your baby can’t sit even with support | Con chưa tự ngồi được khi không có người đỡ | Your baby can’t sit without support | CDC milestones 2022; WHO MGRS |
| F31 | `ageCards[id=age_m09].tips[2]` | P2 | '9-month visit' is a US (AAP) schedule; not routine in VN and differs in UK (9–12 month review). | Hỏi bác sĩ về khám sàng lọc phát triển ở lần khám quanh 9 tháng / Ask the doctor about a developmental check at the 9-month visit | Ở mỗi lần khám định kỳ, hỏi bác sĩ về sự phát triển của con; nếu chưa có lịch khám, ba mẹ có thể chủ động hẹn | At routine check-ups, ask the doctor about your baby’s development; if none is planned, you can book one | AAP Bright Futures (US); NHS |
| F32 | `ageCards[id=age_m09].tips[3]` | P2 | Measles-containing vaccine is at 9 months in VN, PH, ID, MY; the card is silent. | — (new item appended) | Hỏi bác sĩ về mũi tiêm tiếp theo theo lịch tiêm chủng nơi gia đình sống | Ask the doctor which vaccinations are next on your local schedule | Việt Nam EPI; WHO |
| F33 | `ageCards[id=age_m09].interests` | P2 | Pairs with the vaccination tip. | ["milestones"] | ["milestones", "vaccines"] | ["milestones", "vaccines"] | — |
| F34 | `ageCards[id=age_m18].tips[0]` | P2 | Generic wording; '18-month visit' is US-specific. Keep the autism-screening cue (AAP 18 and 24 months). | Hỏi bác sĩ về khám sàng lọc phát triển ở lần khám 18 tháng / Ask the doctor about developmental screening at the 18-month visit | Hỏi bác sĩ về đánh giá phát triển, gồm cả sàng lọc tự kỷ, ở lần khám quanh 18 tháng hoặc bất cứ khi nào ba mẹ băn khoăn | Ask the doctor about a development review, including autism screening, around 18 months or whenever you have concerns | AAP; CDC |
| F35 | `ageCards[id=age_m24].tips[0]` | P2 | As above. | Hỏi bác sĩ về khám sàng lọc phát triển ở lần khám 24 tháng / Ask the doctor about developmental screening at the 24-month visit | Hỏi bác sĩ về đánh giá phát triển ở lần khám quanh 2 tuổi, hoặc bất cứ khi nào ba mẹ băn khoăn | Ask the doctor about a development review around age 2, or whenever you have concerns | AAP; NHS 2-year review |
| F36 | `ageCards[id=age_w06].tips[2]` | P2 | First infant doses are at 6 weeks in AU, NZ, PH; 8 weeks UK; 2 months VN/US/SG. | Hỏi bác sĩ về lịch tiêm chủng lúc 2 tháng tuổi / Ask the doctor about the 2-month vaccinations | Hỏi bác sĩ về các mũi tiêm đầu tiên theo lịch tiêm chủng nơi gia đình sống | Ask the doctor about the first vaccinations on your local schedule | National schedules |
| F37 | `ageCards[id=age_w08].tips[1]` | P2 | As above. | Đưa con đi khám và tiêm chủng theo lịch 2 tháng / Keep the 2-month check-up and vaccinations | Đưa con đi khám và tiêm chủng theo lịch nơi gia đình sống | Keep your baby’s check-ups and vaccinations on your local schedule | National schedules |
| F38 | `ageCards[id=age_m12].tips[1]` | P2 | Deferring entirely to the doctor leaves a gap that growing-up-milk marketing fills; WHO 2023: animal milk 12–23 months, follow-up formula not recommended. | Hỏi bác sĩ về loại sữa phù hợp sau 1 tuổi và lịch tiêm chủng 12 tháng / Ask the doctor which milk suits after age 1 and about the 12-month vaccinations | Sau 1 tuổi, tiếp tục cho bú mẹ nếu mẹ và con muốn; nếu không bú mẹ, sữa tươi tiệt trùng nguyên kem không đường thường là đủ, không cần sữa công thức “tăng trưởng” | After age 1, keep breastfeeding if you both want to; if not, plain pasteurised full-fat milk is usually enough, and ‘growing-up’ formulas aren’t needed | WHO complementary feeding guideline 2023; AAP |
| F39 | `ageCards[id=age_m12].tips[3]` | P2 | Replaces the '12-month vaccinations' half of the old tip. | — (new item appended) | Hỏi bác sĩ về mũi tiêm tiếp theo theo lịch tiêm chủng nơi gia đình sống | Ask the doctor which vaccinations are next on your local schedule | National schedules |
| F40 | `ageCards[id=age_m12].tips[2]` | P2 | Feeding in front of a phone/TV is very common in VN. | Trước 18 tháng nên tránh cho con xem màn hình, trừ gọi video với người thân / Before 18 months, avoid screens except video calls with family | Trước 18 tháng nên tránh cho con xem màn hình, trừ gọi video với người thân; không cho xem điện thoại hay TV trong bữa ăn | Before 18 months, avoid screens except video calls with family, and no phones or TV at mealtimes | AAP Media and children; WHO 2019 |
| F41 | `ageCards[id=age_m06].tips[2]` | P2 | Fluoride smear is AAP and NHS guidance; fluoride-free 'swallowable' pastes are heavily marketed in VN. | Chải răng nhẹ khi chiếc răng đầu tiên nhú, theo hướng dẫn của nha sĩ hoặc bác sĩ / Brush gently once the first tooth appears, as your dentist or doctor advises | Khi chiếc răng đầu tiên nhú, chải răng hai lần mỗi ngày với lượng kem có fluor bằng hạt gạo | Once the first tooth appears, brush twice a day with a rice-grain smear of fluoride toothpaste | AAP oral health; NHS children's teeth |
| F42 | `ageCards[id=age_m06].tips[0]` | P2 | Iron is the key nutrient gap at 6 months; anaemia is common in VN infants. | Bắt đầu ăn dặm từng thìa nhỏ, để con dẫn dắt / Start solids with small tastes and let baby lead | Bắt đầu ăn dặm từng thìa nhỏ, ưu tiên món giàu sắt như thịt, cá, trứng, và để con dẫn dắt | Start solids with small tastes, including iron-rich foods like meat, fish and egg, and let baby lead | WHO complementary feeding guideline 2023 |
| F43 | `health.whileWaiting[1]` | P2 | When to call is missing; VN folk practices (spoon/chopsticks in mouth, pinching) covered by 'nothing in the mouth'. | Nếu con co giật: đặt con nằm nghiêng trên mặt phẳng an toàn, không cho gì vào miệng, không ghì giữ tay chân, để ý thời gian cơn giật / If your baby has a seizure: lay them on their side on a safe flat surface, put nothing in their mouth, don’t hold their limbs down, and note how long it lasts | Nếu con co giật: đặt con nằm nghiêng trên mặt phẳng an toàn, dọn vật cứng xung quanh, không cho gì vào miệng, không ghì giữ tay chân, để ý thời gian; gọi cấp cứu nếu là lần đầu, cơn kéo dài quá 5 phút hoặc con khó thở sau cơn | If your baby has a seizure: lay them on their side on a safe flat surface, move hard objects away, put nothing in their mouth, don’t hold their limbs down, and time it; call emergency services if it’s the first one, lasts over 5 minutes, or breathing is difficult afterwards | NHS Febrile seizures |
| F44 | `health.whileWaiting[3]` | P2 | Alcohol rubs (lau rượu) are a VN folk remedy; NICE advises against tepid sponging and recommends fluids; aspirin contraindicated (Reye). | Mặc cho con vừa đủ ấm, không ủ kín, không chườm nước lạnh; không tự cho bé dưới 3 tháng dùng thuốc hạ sốt khi chưa hỏi bác sĩ / Dress your baby in light layers, don’t bundle them up or sponge with cold water; don’t give fever medicine to a baby under 3 months without asking a doctor | Mặc cho con đồ mỏng vừa đủ, không ủ kín, không chườm nước lạnh hay lau rượu, cồn; cho con bú thường hơn; không tự cho bé dưới 3 tháng dùng thuốc hạ sốt khi chưa hỏi bác sĩ, và không dùng aspirin cho trẻ | Dress your baby in light layers; don’t bundle them up, sponge with cold water or rub with alcohol; offer feeds more often; don’t give fever medicine to a baby under 3 months without asking a doctor, and never give aspirin | NICE NG143; NHS Fever in children |
| F45 | `activities[id=act_swaddle_before_rolling].steps[4]` | P3 | AAP: rolling usually 3–4 months but can be earlier; current text implies 2 months is typical. | Ngừng quấn khi bé bắt đầu tập lật, thường quanh 2 tháng tuổi / Stop swaddling once baby starts trying to roll, often around 2 months | Ngừng quấn khi bé bắt đầu tập lật; có bé tập lật từ khoảng 2 tháng, nên để ý từ sớm | Stop swaddling once baby starts trying to roll; some try from about 2 months, so watch early | AAP safe sleep (2022) |
| F46 | `activities[id=act_white_noise_low].steps[1]` | P3 | Hugh et al. 2014: ≥200 cm, lowest volume, short duration. | Đặt máy xa cũi (khoảng 2 m), không đặt trong hay sát cũi / Place the device well away from the cot (about 2 m), never in or on it | Đặt máy càng xa cũi càng tốt, ít nhất khoảng 2 m; không đặt trong hay trên thành cũi | Place the device as far from the cot as you can, at least about 2 m away, never in or on it | Hugh et al., Pediatrics 2014;133:677–681 |
| F47 | `health.signs[id=lethargic].label` | P3 | 'Li bì' is the word Vietnamese clinicians and parents use. | Lừ đừ, mềm người, khó đánh thức hoặc không tỉnh táo / Unusually drowsy, floppy, hard to wake or not alert | Lừ đừ, li bì, mềm người, khó đánh thức hoặc không tỉnh táo | Unusually drowsy, floppy, hard to wake or not alert | — |
| F48 | `health.disclaimer` | P3 | VI 'an toàn' vs EN 'fine' do not match; 'không sao' matches and reads naturally. | Child Life không chẩn đoán và không kết luận con “an toàn”. Nếu ba mẹ lo lắng, hãy gọi số cấp cứu hoặc bác sĩ của bé ngay; ba mẹ là người hiểu con nhất. / Child Life does not diagnose and never concludes that your baby is “fine”. If you are worried, call emergency services or your baby’s doctor straight away; you know your baby best. | Child Life không chẩn đoán và không bao giờ kết luận con “không sao”. Nếu ba mẹ lo lắng, hãy gọi số cấp cứu hoặc bác sĩ của bé ngay; ba mẹ là người hiểu con nhất. | Child Life does not diagnose and never concludes that your baby is “fine”. If you are worried, call emergency services or your baby’s doctor straight away; you know your baby best. | — |
| F49 | `activities[id=act_responsive_breastfeeding].steps[3]` | P3 | 'mời bên kia' is unnatural. | Để bé bú hết một bên rồi mới mời bên kia / Let baby finish the first side before offering the other | Để bé bú hết một bên rồi mới cho bú tiếp bên kia | Let baby finish the first side before offering the other | — |
| F50 | `activities[id=act_bedtime_routine].steps[1]` | P3 | Current VI/EN are ambiguous. | Đánh răng hoặc lau nướu nếu con đã có răng / Brush teeth or wipe gums once teeth arrive | Đánh răng nếu con đã có răng (chưa có răng thì lau nướu) | Brush teeth once they’ve come through (wipe the gums before that) | NHS children's teeth |
| F51 | `activities[id=act_tummy_time].summary` | P3 | AC02: no causal promise. | Vài phút nằm sấp khi con thức giúp con luyện cổ, vai và tay. / A few minutes on the tummy while awake helps baby build neck, shoulder and arm strength. | Vài phút nằm sấp khi con thức có thể giúp con luyện cổ, vai và tay. | A few minutes on the tummy while awake may help baby build neck, shoulder and arm strength. | — |
| F52 | `activities[id=act_peekaboo].summary` | P3 | AC02. | Trò ú òa vui và giúp con dần hiểu rằng người và vật vẫn còn đó dù tạm khuất. / Peekaboo is fun and helps baby learn that people and things still exist when hidden. | Trò ú òa vui, và có thể giúp con dần hiểu rằng người và vật vẫn còn đó dù tạm khuất. | Peekaboo is fun, and may help baby learn that people and things are still there when hidden. | — |
| F53 | `activities[id=act_narrate_day].summary` | P3 | AC02. | Nói chuyện thường xuyên với con, kể cả khi con chưa hiểu, giúp con làm quen với ngôn ngữ. / Talking with baby often, even before they understand, helps them tune into language. | Nói chuyện thường xuyên với con, kể cả khi con chưa hiểu, có thể giúp con làm quen với ngôn ngữ. | Talking with baby often, even before they understand, may help them tune into language. | — |
| F54 | `activities[id=act_name_and_point].summary` | P3 | AC02. | Chỉ vào đồ vật và gọi tên giúp con nối từ ngữ với thế giới xung quanh. / Pointing at things and naming them helps baby link words to the world around them. | Chỉ vào đồ vật và gọi tên có thể giúp con nối từ ngữ với thế giới xung quanh. | Pointing at things and naming them may help baby link words to the world around them. | — |
| F55 | `activities[id=act_put_in_take_out].summary` | P3 | AC02. | Trò bỏ đồ vào hộp rồi đổ ra giúp con luyện tay và hiểu “trong, ngoài”. / Dropping things into a box and tipping them out builds hand skills and ideas like “in” and “out”. | Trò bỏ đồ vào hộp rồi đổ ra là dịp để con luyện tay và làm quen với “trong, ngoài”. | Dropping things into a box and tipping them out is a chance to practise hand skills and ideas like “in” and “out”. | — |
| F56 | `activities[id=act_finger_foods].summary` | P3 | AC02. | Cho con tự cầm miếng thức ăn mềm giúp con tập nhai và dùng tay khéo hơn. / Letting baby pick up soft pieces of food helps them practise chewing and using their hands. | Cho con tự cầm miếng thức ăn mềm là dịp để con tập nhai và dùng tay. | Letting baby pick up soft pieces of food gives them a chance to practise chewing and using their hands. | — |
| F57 | `activities[id=act_calm_night_feed].summary` | P3 | VI lacked 'có thể' (EN had 'can'). | Giữ cữ bú đêm nhẹ nhàng, tối và ít kích thích giúp con dễ ngủ lại hơn. / Keeping night feeds dim, quiet and low-key can help baby settle back to sleep. | Giữ cữ bú đêm nhẹ nhàng, tối và ít kích thích có thể giúp con dễ ngủ lại hơn. | Keeping night feeds dim, quiet and low-key can help baby settle back to sleep. | — |
| F58 | `ageCards[id=age_w01].body` | P3 | 'hay 16 giờ' reads as 'or 16 hours'. | Tuần đầu đời, con thường ngủ nhiều (hay 16 giờ trở lên mỗi ngày, chia thành nhiều giấc ngắn) và bú thường xuyên, khoảng 8–12 lần mỗi ngày đêm. Sụt một ít cân trong vài ngày đầu là điều thường gặp. Mỗi bé mỗi khác, ba mẹ cứ theo nhịp của con. / In the first week babies usually sleep a lot (often 16 hours or more a day, in short stretches) and feed often, around 8–12 times in 24 hours. Losing a little weight in the first few days is common. Every baby is different; follow your baby’s lead. | Tuần đầu đời, con thường ngủ nhiều (thường từ 16 giờ trở lên mỗi ngày, chia thành nhiều giấc ngắn) và bú thường xuyên, khoảng 8–12 lần mỗi ngày đêm. Sụt một ít cân trong vài ngày đầu là điều thường gặp. Mỗi bé mỗi khác, ba mẹ cứ theo nhịp của con. | In the first week babies usually sleep a lot (often 16 hours or more a day, in short stretches) and feed often, around 8–12 times in 24 hours. Losing a little weight in the first few days is common. Every baby is different; follow your baby’s lead. | — |
| F59 | `ageCards[id=age_m13].watchFor[1]` | P3 | 'baby' vs 'child' after 12 months. | Con rất ít phát ra âm thanh, hoặc dường như không nghe thấy khi được gọi / Your baby makes very few sounds, or doesn’t seem to hear when called | Con rất ít phát ra âm thanh, hoặc dường như không nghe thấy khi được gọi | Your child makes very few sounds, or doesn’t seem to hear when called | — |
| F60 | `ageCards[id=age_m14].watchFor[1]` | P3 | As above. | Con không quay lại khi được gọi tên / Your baby doesn’t look when you say their name | Con không quay lại khi được gọi tên | Your child doesn’t look when you say their name | — |


### 2b. System, product and content findings without a one-line replacement

| # | Where | Sev | Problem | Recommendation | Source |
|---|---|---|---|---|---|
| S01 | Age cards `watchFor`, stage `skills` | P1 | Milestone expectations use actual age. For a baby born at 32 weeks, the w07 to m06 milestone flags are about 2 months early. | When the profile shows gestation <37 weeks, add a line to milestone sections: "Với bé sinh non, mốc phát triển tính theo tuổi hiệu chỉnh (đến 2 tuổi)" / "For babies born early, use corrected age for milestones (until age 2)". Alternatively, pick the milestone part of the card by corrected age. Keep safety and feeding by actual age, but safe sleep for preterm babies runs from the due date for one year (NHS). | AAP corrected age; NHS SIDS |
| S02 | `healthSigns` (contracts `rhythm.ts:361`) | P1 | Missing "get help now" signs: non-blanching rash (glass test); green or bloody vomit; dengue warning signs (abdominal pain, persistent vomiting, bleeding gums or nose, drowsiness, especially as the fever falls); swallowed button battery, magnet or poison; choking; head injury with drowsiness or vomiting; fever for 5 days or more (NICE). Fever after 3 months has no route of its own. | Extend `healthSigns`. This is a contracts and app change plus copy. The dengue sign matters most in VN, PH, ID, TH and MY. | NHS urgent help under-5s; NICE NG143; WHO dengue |
| S03 | `rhythm_calendar.dart:529` | P1 | Stage `activityIds` are shown without the birth-age filter and without the `regions` filter, so a region-scoped item linked to a stage reaches every country. | Filter stage-linked activities through the same eligibility as `recommend()`, or let the seed test forbid linking region-scoped items. | code |
| S04 | `needs` / `interests` enums | P2 | There is no `safety` or `health` tag. Water, car-seat, sun and walker items can only match through "play" or "moments", and check-ins can never rank them. | Add an interest `safety` (and optionally a need). Until then the drafted safety items use play/bonding + moments. | — |
| S05 | Schema | P2 | Age cards and the health pack have no `regions`. An activity's `regions` cannot say "everyone except X", and households with no country see only `regions: []` items. | See §3.3. | code |
| S06 | English locale | P2 | British spelling (favourite, pyjamas, recognise) sits next to US "diaper", British "cot", "buggy", "mum" and "miaow". It reads oddly to both US and UK parents. | Pick a base register. **Recommendation:** en-GB/AU/SG/NZ as the base ("nappy", "cot", "pram/pushchair", "mum"), then an en-US variant later via ARB (or neutral terms such as "your baby's own sleep space"). At minimum avoid "mum" in shared copy (w06 tip 1) and say "for baby and you". | — |
| S07 | Vietnamese register | P3 | Fluent, natural and warm overall. Two choices to make deliberately: (a) "ba mẹ / tã / nướu" are Southern/standard, while Northern families say "bố mẹ / bỉm / lợi". If the product is Northern-first, decide once at product level; "ba mẹ" is acceptable nationally. (b) "bé" and "con" are mixed inside the same activity (e.g. `act_skin_to_skin`). | Suggested rule: **"con"** when speaking to the parent about their child, **"bé"** only in generic or third-person statements ("bé sơ sinh", "bé dưới 3 tháng"). Medical terms: "li bì" (lethargy) and "bú cụm" (cluster feeding) are the words VN clinicians use. | — |
| S08 | Reference notices | P2 | "Your baby may be fussier next week" can colour how parents read normal behaviour (an expectation effect). The evidence for fixed timing is weak (de Weerth & van Geert 1998). | Make pre-stage notices opt-in (default off). Keep "lịch tham khảo"; never "giải thích vì sao con quấy". | de Weerth & van Geert 1998 |
| S09 | Vitamin D | P2 | US, CA and UK advise daily vitamin D for breastfed infants; VN and AU do not do this routinely. A global card cannot say it. | Drafted `act_vitamin_d_drops` with `regions: ["US","CA","GB"]` as the worked example of region scoping. Reviewers for those markets must confirm the dose wording (AAP 400 IU; NHS 8.5–10 µg). | AAP; NHS vitamins |
| S10 | `act_responsive_breastfeeding` (IBCLC) | P2 | Covers latch only and stops at 183 days. Missing: signs of effective milk transfer (audible swallows, wet and dirty diapers, weight); "pain is not normal"; mastitis needs a same-day doctor; expressing and milk storage (the app logs pumping); breastfeeding beyond 6 months and back-to-work. The id says "responsive" but the content is about latch. | Next batch: `act_milk_is_flowing`, `act_expressing_storing`, `act_breastfeeding_back_to_work`. Extend breastfeeding relevance to 730 days (WHO: to 2 years and beyond). | WHO; NHS breastfeeding; UNICEF UK BFI |
| S11 | `act_feeding_cues` safety | P3 | "doctor or midwife" fits the UK. | Say "health professional" (en) / "nhân viên y tế" (vi). | — |
| S12 | `act_tummy_time` | P3 | No daily total is given. | Optional: "aim to build up to about 30 minutes in total across the day" (WHO 2019, non-mobile infants). | WHO 2019 |
| S13 | Pacifier | P2 | AAP: a dummy at sleep time reduces SIDS risk once breastfeeding is established. Not mentioned. | Reviewer (paediatrician with IBCLC) decides whether to add an optional line to `act_safe_sleep_check`, worded as "có thể cân nhắc" after breastfeeding is established (around 3–4 weeks). | AAP safe sleep 2022 |
| S14 | `act_sing_softly` summary | P3 | "Your voice is the sound baby loves most" is an unprovable claim. | vi "Giọng của ba mẹ là âm thanh quen thuộc với con; không cần hát hay." / en "Your voice is a sound baby knows well; you don’t need to sing well." | — |
| S15 | Health fallback copy | P2 | Without a number the app says "Gọi bác sĩ của bé". Many VN families have no named doctor. | vi "Đưa con đến cơ sở y tế gần nhất hoặc gọi bác sĩ của bé" / en "Go to the nearest clinic or hospital, or call your baby’s doctor". This lives in ARB, not the seed. | — |
| S16 | `health.sources` | P3 | "Bộ Y tế Việt Nam" points to the MoH homepage, which is too generic to support a clinical claim. | Replace with the specific MoH guidance documents the VN reviewer relies on (e.g. national IMCI and newborn-care guidance), and add NICE NG143. | — |
| S17 | Folk practices (VN) | P2 | Common practices with potential harm are not addressed: dầu gió, dầu tràm or camphor/menthol oils on infants' faces and chests (apnoea risk with menthol and camphor in young infants); cạo gió (coining); kiêng tắm / kiêng gió leading to closed hot rooms; "xi tè" early elimination (neutral); sweetened condensed milk as a drink. | Address these respectfully in a later "Thói quen truyền thống" item, written and signed by a VN paediatrician. No evidence-light claims from engineering. | — |
| S18 | Motorbikes (VN) | P2 | Families carrying infants on motorbikes is everyday reality, and the seed is silent. | Owner and paediatrician to decide the stance (there is no safe way to carry an infant on a motorbike; helmets do not suit under-2s). Do not write "how to" copy without that decision. VN car-seat rule (Road Traffic Order and Safety Law 2024, art. 10(3)): from **1 July 2026** per secondary sources (Law 118/2025 amendment). Verify. | thuvienphapluat.vn (secondary) |

---

## 3. Multi-country

### 3.1 Assumptions that hold in only one market

| Assumption in the seed | Holds in | Breaks in | Fix |
|---|---|---|---|
| "2-month vaccinations" (w06, w08) | VN, US, SG | AU, NZ, PH (6 weeks), UK (8 weeks), JP (2 months), DE (U-schedule) | "theo lịch nơi gia đình sống" (drafted) |
| "12-month vaccinations"; no 9-month mention | US, UK, AU | VN, PH, ID, MY (measles at 9 months) | Local-schedule tips at m09 and m12 (drafted) |
| "9/18/24-month visit" screening | US (AAP Bright Futures) | VN (no routine), UK (health-visitor reviews at 1 and 2 years), JP/KR/DE/FR (own schedules) | "At routine check-ups or whenever worried" (drafted) |
| "Postnatal check-ups for baby and mum as booked" | UK (6–8-week check) | VN (not routine for mothers) | Keep, but neutral "for baby and for you" |
| No water before 6 months; tap water "water" | UK (safe tap water) | VN, SEA (boil water) | "safe drinking water, boiled if needed" (drafted) |
| Teething gels banned outright | US (FDA), AAP | UK allows pharmacist-advised lidocaine gels | Keep stricter global rule (acceptable) |
| Paracetamol under 3 months needs a doctor | AAP | NHS allows from 2 months (vaccine fever) | Keep global conservative rule |
| Bed-sharing never | AAP | NHS/UNICEF UK harm-reduction; VN reality | Drafted harm-reduction item |
| Vitamin D for breastfed babies (missing) | US, CA, UK advise it | VN, AU not routine | Region-scoped activity (drafted) |
| Room temperature (absent; NHS says 16–20 °C) | UK | VN, SEA (rooms 28–32 °C) | Good that it's absent; hot-weather item drafted |
| Car seat use assumed (none mentioned) | US, UK, AU, SG | VN (mandatory only from 1/7/2026), motorbike transport | Car-seat item drafted; motorbike stance pending (S18) |
| Allergen introduction (missing) | AU/UK/US guidance | — | Drafted |
| Dengue, mosquitoes, heat, drowning in water jars | — | All of SEA; diaspora visiting VN | Drafted items; S02 for dengue route |
| Growing-up formula marketing | — | VN, SEA (heavy marketing; VN Decree 100/2014 restricts BMS ads for <24 m, to be confirmed by legal) | m12 milk text (drafted); no formula partnerships near this content |
| "Doctor or midwife", "health visitor" | UK | US (pediatrician/nurse), VN (nhân viên y tế) | Neutral "health professional" |
| Diaspora on the vi locale | — | A Vietnamese family in the US/DE/JP reads vi | **Region must come from household country, never from locale.** Global copy stays schedule-neutral. |

### 3.2 Emergency numbers

**Existing 12 entries.** All are correct to my knowledge:
- VN 115 (medical; 113 police, 114 fire)
- US / CA 911
- GB 999 (112 also works)
- AU 000 (112 from mobiles)
- NZ 111
- SG 995 (ambulance/fire; 999 police)
- DE / FR 112 (FR 15 = SAMU, medical-only; keep 112)
- JP / KR / TW 119

The reviewer must still check each one against an official government page and record the date.

**Proposed additions** (`additions/rhythm.json → healthRegions`; "low" = verify before prod):

| Country | Number | Confidence | Note |
|---|---|---|---|
| PH | 911 | low, verify before prod | National Emergency Hotline 911 (since 2016); some sources say 117 still routes behind it. Confirm on gov.ph before prod. |
| MY | 999 | high (reviewer knowledge, re-check official page) | MERS 999 (police, fire, ambulance); 112 from mobiles redirects to 999. |
| ID | 112 | low, verify before prod | 112 is the national integrated number but coverage depends on local rollout; 119 (PSC 119) / 118 are ambulance. Reviewer to choose 112 vs 119. |
| TH | 1669 | high (reviewer knowledge, re-check official page) | 1669 = National Institute for Emergency Medicine (medical). 191 police, 199 fire. 4 digits fits the schema regex. |
| HK | 999 | high (reviewer knowledge, re-check official page) | Police, fire, ambulance. |
| CN | 120 | high (reviewer knowledge, re-check official page) | 120 ambulance (110 police, 119 fire). |
| KH | 119 | low, verify before prod | Ambulance 119 (117 police, 118 fire); service quality varies. |
| IE | 112 | high (reviewer knowledge, re-check official page) | 999 and 112 both work. |
| NL | 112 | high (reviewer knowledge, re-check official page) |  |
| BE | 112 | high (reviewer knowledge, re-check official page) | 112 for ambulance and fire. |
| IT | 112 | low, verify before prod | 112 is national in most regions; 118 still medical in some. Use 112. |
| ES | 112 | high (reviewer knowledge, re-check official page) |  |
| CH | 144 | high (reviewer knowledge, re-check official page) | 144 ambulance; 112 also works. |
| AT | 144 | high (reviewer knowledge, re-check official page) | 144 ambulance; 112 also works. |
| CZ | 155 | high (reviewer knowledge, re-check official page) | 155 ambulance; 112 also works (with foreign-language operators). Large Vietnamese community. |
| PL | 112 | high (reviewer knowledge, re-check official page) | 112 or 999 (ambulance). Vietnamese community in Warsaw. |
| SE | 112 | high (reviewer knowledge, re-check official page) |  |
| NO | 113 | high (reviewer knowledge, re-check official page) | 113 medical; 112 police. |
| DK | 112 | high (reviewer knowledge, re-check official page) |  |
| FI | 112 | high (reviewer knowledge, re-check official page) |  |
| RU | 112 | low, verify before prod | 112 universal; 103 ambulance. Vietnamese community. |
| AE | 998 | high (reviewer knowledge, re-check official page) | 998 ambulance; 999 police. |
| QA | 999 | high (reviewer knowledge, re-check official page) |  |
| SA | 997 | low, verify before prod | 997 ambulance; 911 unified in some regions. |
| IN | 112 | low, verify before prod | 112 national; 108 ambulance in most states. |
| BN | 991 | low, verify before prod | 991 ambulance. |
| LA | 1195 | low, verify before prod | Ambulance numbers vary (1195 / 195 reported). Prefer 'Gọi bác sĩ của bé' until verified. |

Not proposed: ZA 10177 (5 digits, fails `^[0-9]{2,4}$`; 112 works from mobiles), MM, Pacific islands.

**Schema suggestion.** Add optional per-country `nonUrgentNumber` (GB 111) and `poisonsNumber` (US 1-800-222-1222, AU 13 11 26). These need a looser regex and a separate display rule. Keep the "no default hotline" principle.

### 3.3 How regions work today, and how to handle region-specific notes

**What the code does.**
- `activity.regions`:
  - `[]` means **every country**.
  - A non-empty list means **only those countries**.
  - A household with `country === null` sees only `regions: []` items.
  - This applies in `recommend()` (`packages/contracts/src/personalization.ts:414`), `firebase/functions/src/ai-summary.ts:324` and `assistant-care.ts` via `recommend`.
- The mobile app parses `regions` (`rhythm_models.dart:615`) but does not filter on it in the stage calendar (S03).
- `recipes.regions` uses the opposite convention: never empty, and it lists the countries where the recipe was reviewed.
- Age cards and the health pack have no regions; the health pack has the `regions` number table only.

**Recommendations.**
1. **Global defaults stay safe and schedule-neutral.** Every activity, card and health line must be correct in every launch market without a region filter. Most of the drafted replacements do this.
2. **Genuinely different advice becomes a region-scoped variant**, e.g. `act_vitamin_d_drops` with `regions: ["US","CA","GB"]`. Because `[]` cannot express "all except X", replacing a global item for one country means a pair: `act_x` (explicit list of the other launch countries) plus `act_x_vn` (`["VN"]`). Note that null-country households then see neither; prefer additive variants over replacements.
3. **Schema (next contracts version):**
   - (a) `excludeRegions` on activities.
   - (b) `regionNotes: [{ country, note: localized }]` on activities and age cards, for one local line such as "Ở Việt Nam, mũi sởi đầu tiên thường tiêm lúc 9 tháng". The UI shows it under the global text, only for that household country.
   - (c) Review per region, recorded the way `recipes.regions` records where a recipe was reviewed: a VN paediatrician's signature should not approve US vitamin-D dosing.
   - (d) Make the calendar respect regions (S03).
4. **Never infer region from locale** (diaspora on vi, expats on en in VN).

---

## 4. Answers to SEED-NOTES §6

| §6 | Topic | Recommendation | Sources |
|---|---|---|---|
| 1 | Fever thresholds | Keep 38°C under 3 months with maxAgeDays 90 (NICE 'under 3 months'; 3 months ≈ 91.3 days, so day 90 is correct and m03 starting at 91 is consistent). Keep the NICE amber line '39°C or higher at 3–6 months → same day' (NICE NG143 / NHS); it is compatible with Vietnamese hospital advice, which is if anything more cautious. State the method everywhere a number appears: digital thermometer, usually axillary (NICE: electronic axillary under 4 weeks; NICE advises against forehead chemical strips); never by touch. Do NOT lower the threshold for axillary readings in copy (WHO IMCI uses ≥37.5°C axillary for young infants, but a second number confuses parents); instead add a low-temperature line (<35.5°C, WHO IMCI young-infant danger sign) to week cards. Reviewer (paediatrician) to confirm the 35.5°C figure and whether to add 'any fever ≥5 days' (NICE, Kawasaki) to month cards. | NICE NG143; WHO IMCI; NHS Fever in children |
| 2 | Emergency numbers | All 12 listed numbers are correct to my knowledge: VN 115, US/CA 911, GB 999, AU 000, NZ 111, SG 995, DE/FR 112, JP/KR/TW 119. FR: keep 112 (works from any phone, multilingual); 15 (SAMU) is medical-only and could be a second field later. Add PH 911, MY 999, TH 1669, ID 112 (or 119; rollout uneven), HK 999, CN 120, plus EU diaspora countries (CZ 155, PL 112, NL/BE/ES/IE/SE/DK/FI 112, CH/AT 144, NO 113) — see healthRegions with confidence flags. Each number must be re-verified on an official government page by the reviewer before prod. The schema regex ^[0-9]{2,4}$ excludes 5-digit numbers (ZA 10177); fine for now. | National government emergency pages (to be linked by reviewer) |
| 3 | Swaddling | Keep the activity but (a) rename 'Quấn chũn' to the generic 'Quấn khăn' — 'chũn' comes from a product (nhộng chũn) and some such products restrict the legs; (b) keep ageDays 0–60 as the ranking window, while the copy says 'stop at the first signs of trying to roll; some start around 2 months' (AAP: rolling usually 3–4 months but can be earlier); (c) add: no weighted swaddles or sleep sacks (AAP 2022), never swaddle when bed-sharing (NHS), never bind the legs straight (hip dysplasia; IHDI), not in a hot room. NHS caution is respected by these limits. Do not promote swaddling as reducing SIDS (AAP: it does not). | AAP safe sleep 2022; NHS SIDS; IHDI hip-healthy swaddling |
| 4 | Safe sleep / bed-sharing | Yes, add a harm-reduction item (drafted: act_bed_sharing_safer). In Việt Nam bed-sharing is the norm; an all-or-nothing message is ignored and families then miss the rules that matter most (no sofa/armchair, no alcohol/smoking/drowsy medicine, not between two adults, not for preterm/low-birthweight babies, firm flat surface, no swaddle). This mirrors NHS/UNICEF UK practice. It conflicts in tone with AAP ('cannot recommend bed sharing under any circumstances'), so the item opens with 'the safest place is own cot/bassinet next to your bed'. Also name VN-specific hazards in act_safe_sleep_check: võng (hammock), nôi điện/automatic swings, gối chặn/gối chống bẹp đầu (positioners), heavy covers/overheating ('ủ ấm'), and charcoal braziers in closed rooms ('nằm than', CO). This item needs explicit paediatric sign-off before prod; consider showing it only after the family indicates bed-sharing (check-in) rather than ranking it for everyone. | AAP safe sleep 2022; NHS SIDS; NHS carbon monoxide |
| 5 | White noise | Keep 'as far as possible, at least ~2 m, lowest volume that works, turn off/down once asleep, never in or on the cot' (Hugh et al. 2014: 14 machines at max volume averaged 63 dBA at 200 cm; nursery limit 50 dBA). Do not give a dB number in parent copy (few parents can measure it); optionally a help-text line: 'if you have a sound-meter app, under about 50 dB where baby lies'. | Hugh SC et al. Pediatrics 2014;133:677–681 |
| 6 | Feeding | (a) Use 183 for act_first_foods (165 ranks it at 5.4 months, against WHO/VN MoH exclusive breastfeeding to 6 months; 183 still links to stage_05). Reword 'never before 4 months' so it is not read as permission at 4 months. (b) Honey: also name 'rơ lưỡi/rơ nướu bằng mật ong' (VN tradition). (c) Water: exclusively breastfed babies under 6 months need no water even in hot climates (WHO/UNICEF; 2024 systematic review of 18 LMIC studies); formula-fed babies in hot weather: ask a clinician, never dilute (NHS). (d) Milk after 1: say it (WHO 2023: animal milk 12–23 months, follow-up formula not recommended; continue breastfeeding to 2 years and beyond). Note for product/legal: Việt Nam restricts marketing of breast-milk substitutes for under-24-month products (Decree 100/2014 — reviewer to confirm), so no formula partnerships or ads near this content. (e) Add allergen introduction (ASCIA/NHS/NIAID) — drafted act_common_allergens; and Asian choking foods. | WHO IYCF; WHO complementary feeding guideline 2023; NHS Drinks and cups; ASCIA; NIAID 2017 addendum |
| 7 | Vaccination mentions | Remove month-specific schedule claims. First doses are at birth (HepB, VN/US), 6 weeks (AU, NZ, PH), 8 weeks (UK), 2 months (VN, US, SG). Measles-containing vaccine is at 9 months in VN/PH/ID/MY but 12 months in US/UK/AU. Use 'theo lịch tiêm chủng nơi gia đình sống' / 'on your local schedule' and add a 9-month vaccine prompt (drafted). Country schedules belong in the vaccines module (Q-xxx), not in these generic cards. | Việt Nam EPI (TCMR); CDC, UKHSA, Australian Immunisation Handbook schedules |
| 8 | Developmental screening | Rephrase m09/m18/m24 to 'at routine check-ups, or whenever you are worried, ask about development' and keep an autism-screening cue at 18 months (AAP screens at 18 and 24 months). Do not cite visit numbers (US Bright Futures). In VN there is no routine screening; the copy should empower parents to request a check (e.g. ASQ at a paediatric clinic). Add a product note: watchFor lines use actual age, but milestone expectations for preterm babies (<37 weeks) should use corrected age until 24 months (AAP/CDC) — show a note on cards for preterm babies. | AAP developmental surveillance and screening; CDC Learn the Signs |
| 9 | Jaundice and newborn checks | Lines are correct (NHS). Add: do not use sunlight or herbal baths to treat jaundice (common in VN; drafted as w02 tip); pale stools/dark urine is already there and is the key biliary-atresia cue (Taiwan and some VN hospitals use stool colour cards — reviewer may want to mention). Keep '≥6 wet diapers from day 5–6'. Consider adding 'weight check by day 5 and around day 10–14' as a tip. | NHS Jaundice in babies; AAP 2022 hyperbilirubinaemia guideline |
| 10 | Quoted ranges | WHO MGRS windows are quoted correctly when rounded (sitting alone 3.8–9.2, standing with assistance 4.8–11.4, walking alone 8.2–17.6 months). Prefer 'khoảng 4–9 tháng' wording (already 'about'). Crying peaking around 6–8 weeks is consistent with the literature used by AAP/PURPLE. Note CDC 2022 milestones describe what ~75% of children do, not the average — the copy's 'many babies' fits. | WHO MGRS motor milestones; CDC milestones 2022 |
| 11 | Screens | Keep, but align the headline with WHO (no sedentary screen time for under-2s; ≤1 h at 2 years) while keeping the AAP nuance (video calls fine; 18–24 months high-quality, co-viewed). Add 'no screens during meals and the hour before bed' — screen-feeding is very common in VN. | WHO 2019 under-5 guidelines; AAP Media and children |
| 12 | Teething | Keep 'no amber necklaces, no numbing gels; teething does not cause high fever'. Extend to bracelets/anklets and name 'vòng dâu tằm' (mulberry-wood beads, far more common in VN than amber) — FDA 2018 warning covers all teething jewellery; add 'no honey on gums'; add 'nor significant diarrhoea'. Note NHS allows pharmacist-advised lidocaine gels for older babies; our stricter global line follows FDA/AAP (benzocaine not under 2) and is acceptable. | FDA consumer update (teething); AAP Teething |
| 13 | While-waiting steps | Seizure position is correct (on side, nothing in mouth, don't restrain, time it); add 'move hard objects away' and when to call (first seizure, >5 minutes, breathing difficulty after) per NHS. Fever-medicine line: keep 'under 3 months, ask a doctor first' as the global rule (AAP: under 12 weeks call before giving acetaminophen; NHS paracetamol from 2 months is mainly post-vaccine and pack-labelled) — add 'never aspirin', 'no alcohol rubs', 'offer feeds'. CPR hand-off: make sure Sơ cứu opens the INFANT (<1 year) CPR flow for babies, not the child flow. | NHS Febrile seizures; NICE NG143; AAP Fever |
| 14 | lost_skill routing | Agree with softer routing: 'Hẹn bác sĩ trong vài ngày tới / see a doctor within the next few days', no emergency button by default. Escalate to the urgent route only if it comes with another sign (seizure, clusters of sudden jerks or head-drops — possible infantile spasms — floppiness, drowsiness, or after a head injury). Needs a contracts/UI change (health route per sign). | CDC Learn the Signs; NHS urgent help for under-5s |
| 15 | Due date vs birth date | Keep stages on due date and feeding/sleep safety on actual age, but (a) filter stage-linked activities by the birth-age range too (rhythm_calendar.dart shows activityIds unfiltered, also bypassing regions); (b) for preterm babies show milestone watchFor/skills with a 'tuổi hiệu chỉnh / corrected age' note until 24 months; (c) safe-sleep advice for preterm babies follows the due date for a year (NHS) and solids timing for preterm babies needs clinician advice — add a line in act_first_foods for preterm babies when the profile says preterm. | AAP corrected age; NHS SIDS (premature babies) |
| 16 | Coverage beyond 12 months | Ship 0–24 months in the UI (cards already exist and are reasonable) but only once the 12–24-month activity set is filled (drafted: 7 new items aimed at 12–24 m). Plan 24–36 months for V1.x with quarterly cards (27, 30, 33, 36 m; CDC has 30 and 36-month checklists; AAP screens at 30 m) — this needs the test's ageDays.to ≤ 760 limit raised. Remove 'nội dung sau 12 tháng chưa hỗ trợ' from NL03 once 12–24 is reviewed. | CDC milestones (30, 36 months); AAP periodicity |
| 17 | Sources | de Weerth & van Geert (1998, BJDP 16:15–44): 4 mother–infant pairs observed weekly for 15 months; no common pattern of strictly timed emotional instability; large between- and within-infant variability. The seed's label is a fair summary; suggest 'de Weerth & van Geert (1998): 4 infants, weekly for 15 months; no common timing pattern, large individual differences'. Replace the generic 'Bộ Y tế Việt Nam' homepage with specific MoH documents (reviewer to supply, e.g. the national IMCI / newborn-care guidance). Add NICE NG143 to health sources. Re-check the 403 domains in a browser. | de Weerth & van Geert 1998 (abstract, ProQuest record) |
| 18 | Wonder Weeks | Keep as a neutral 'reference calendar' and consider making the pre-stage notices opt-in (default off): telling a parent 'your baby may be fussier next week' can colour how they read normal behaviour (expectation effect), and the evidence for fixed timing is weak. Never say the calendar 'explains' fussiness. Rights check remains a release gate; content does not depend on the label. | de Weerth & van Geert 1998 |

---

## 5. Gap analysis (0–24 months) and coverage

**Current shape.**
- 37 activities. Only `act_big_feelings` (365) and `act_two_choices` (426) start at or after 12 months. Everything else for 12–24 months is a 0–730 carry-over (reading, narrating, bath, bedtime, finger foods, cups).
- Age cards for 13–24 months are good, but their tips repeat the same 5–6 activities.

**Drafted in `additions/rhythm.json` (16 activities).**

| id | Age (days) | Fills | Notes for reviewer |
|---|---|---|---|
| `act_bed_sharing_safer` | 0–365 | Harm reduction for bed-sharing families | Policy decision vs AAP; consider showing only when a family reports bed-sharing |
| `act_hot_weather_comfort` | 0–730 | Heat, hydration, formula in heat | VN/SEA core |
| `act_common_allergens` | 183–365 | Egg, peanut and other allergens | "About twice a week" follows ASCIA; confirm |
| `act_choking_safe_foods` | 183–730 | Asian choking foods, eating upright | Sticky-rice wording is expert opinion; confirm |
| `act_add_a_word` | 365–730 | Toddler language, bilingual homes | — |
| `act_pretend_play` | 456–730 | Symbolic play | — |
| `act_brush_first_teeth` | 183–730 | Oral hygiene, fluoride smear | VN market sells fluoride-free pastes |
| `act_family_meal_self_feed` | 365–730 | Independent eating, no force-feeding or screen-feeding | VN "ép ăn", feeding in front of phones |
| `act_potty_readiness` | 548–730 | Readiness signs 18–24 m | Neutral on "xi tè" |
| `act_water_safety_home` | 183–730 | Drowning prevention (jars, basins, ponds) | Highest-yield safety item for VN |
| `act_partner_care_time` | 0–365 | Father/partner/co-carer involvement | — |
| `act_parent_check_in` | 0–730 | Parental mental health (mothers and fathers), crisis line | Needs a perinatal mental-health reviewer and per-country helplines |
| `act_sun_and_mosquitoes` | 30–730 | Sun, repellent ages, dengue, standing water | DEET/OLE ages per AAP/CDC |
| `act_car_seat_every_trip` | 0–730 | Travel safety | VN law from 1/7/2026 (verify) |
| `act_active_play_every_day` | 365–730 | WHO 180 min, sedentary limits | — |
| `act_vitamin_d_drops` | 0–365, US/CA/GB | Region-scoped example | Dose wording by local reviewer |

Suggested stage links (validated against windows):
- stage_08 + `act_add_a_word`, `act_family_meal_self_feed`
- stage_09 + `act_active_play_every_day`
- stage_10 + `act_pretend_play`

**Still missing (next batch, by priority).**
1. **Breastfeeding beyond the latch** (IBCLC): effective transfer, expressing and storage, back to work, night weaning, breastfeeding to 2 years (S10).
2. **Injury prevention 6–24 m:** burns and scalds (hot soup, tea, *motorbike exhaust burns*, which are very common in VN); poisoning (medicines, cleaning products, essential oils, *dầu gió*); button batteries; falls from beds, balconies and windows.
3. **Toddler sleep:** nap transitions (2 to 1 around 12–18 m), WHO 11–14 h at 1–2 years, early waking, night waking.
4. **Toddler nutrition:** iron-rich foods and anaemia (common in VN); milk volume cap (AAP ~16–24 oz / ~500 ml); picky eating; snacks; sugary drinks.
5. **Illness basics:** diarrhoea and ORS (WHO), hand-washing, diaper rash, constipation, common colds and when to worry. Links to the S02 health signs.
6. **Sibling and new baby; childcare and nhà trẻ start** (often 18–24 m in VN); separation goodbyes.
7. **Travel:** flights and ears, time zones, diaspora trips to VN (vaccines, mosquitoes, water, heat).
8. **Hearing and vision:** newborn hearing screen follow-up, squint and eye checks.
9. **Positive discipline** beyond tantrums: biting and hitting, consistent limits.
10. **Folk practices item** (S17) and the **motorbike stance** (S18). Both need owner and paediatrician decisions first.

**36 months?** Yes, but not for this prod release.
- Ship 0–24 months once 12–24 is reviewed.
- Plan 24–36 for V1.x with quarterly cards (27, 30, 33, 36 m; CDC has 30- and 36-month checklists; AAP screens at 30 m).
- Add 8–10 activities for that range: potty training proper, pretend and peer play, two- and three-word speech, independence, preschool readiness.
- This requires raising the seed test's `ageDays.to ≤ 760` limit and extending the age-card coverage test.
- The "Nhịp" reference calendar ends at stage 10 (≈75 weeks), so it needs no change.

---

## 6. What a qualified reviewer must sign before prod

Nothing in this file or the JSON is approved. Each item stays `review: null` until a named reviewer with a credential signs it through `rhythmActSchema`. Minimum sign-off set:

1. **Paediatrician (VN-licensed), plus one paediatrician for each English launch market or an international reviewer:**
   - the whole health pack: signs, while-waiting steps, fever thresholds and method, the <35.5 °C line, seizure and fever-medicine wording;
   - every `watchFor` line and the `lost_skill` routing;
   - all safe-sleep items, including the **bed-sharing harm-reduction policy**, swaddling, white noise and pacifier;
   - teething;
   - solids timing, allergens, choking foods and vitamin D;
   - repellent ages, sunscreen and dengue wording;
   - water and heat advice.
2. **IBCLC:** feeding cues, latch, paced bottle, night feeds, water and hot weather, formula preparation, bed-sharing in the breastfeeding context, milk after 1 year, and the missing breastfeeding items (S10).
3. **Child-development specialist or speech and language therapist:**
   - age-card bodies and milestone timing;
   - the corrected-age rule (S01);
   - stage skills and the Wonder Weeks framing and notices (S08);
   - language, play, potty, tantrums and screens items.
4. **Perinatal mental-health clinician:** `act_parent_check_in`, `act_parent_break`, the PND lines in w05/w06, and a **per-country crisis route** (helplines are not in the schema yet).
5. **Injury-prevention reviewer:** water safety, car seats, walkers, falls, plus a decision on the motorbike stance.
6. **Legal and compliance:**
   - the Wonder Weeks name and model rights (D-072 #7);
   - breast-milk-substitute marketing rules (WHO Code; VN Decree 100/2014) for the milk copy and any partnerships;
   - each emergency number verified on an official page with a date;
   - market-specific medical-advice disclaimers;
   - B06 footnote "Nội dung do đội chuyên môn Child Life soạn và rà soát" not to ship until true.
7. **Native-language editors:** a Northern-Vietnamese editor (register decision S07) and an English editor for the chosen register (S06).
8. **Sources:** open the 403 domains (cdc.gov, wiley, thewonderweeks.com, unicef.org.uk) in a browser; replace the MoH homepage source; record access dates.

---

## 7. Sources consulted for this review (beyond those already cited in the seed)

- AAP / HealthyChildren.org, "A parent’s guide to safe sleep" (2022 policy): bed-sharing, room-sharing ≥6 months, incline >10°, weighted products, swaddling until signs of rolling (usually 3–4 months, can be earlier), overheating, car seats and slings.
- NHS, "SIDS, reducing the risk": co-sleeping conditions, no swaddling when co-sleeping, room 16–20 °C, preterm babies follow the due date for one year.
- Hugh SC et al., *Pediatrics* 2014;133:677–681 (infant sleep machines: 63 dBA at 200 cm at maximum volume; 50 dBA nursery limit).
- WHO, *Guideline for complementary feeding of infants and young children 6–23 months* (2023): start at 6 months; animal milk from 12–23 months; follow-up formula not recommended.
- WHO / UNICEF on water for breastfed infants in hot climates, and a systematic review of 18 LMIC studies (ENN Field Exchange 69).
- FDA, "Safely soothing teething pain" and the 2018 teething-jewellery safety communication (necklaces, bracelets, anklets; benzocaine not under 2).
- NIAID 2017 addendum (peanut), ASCIA (allergy.org.au), NHS food allergies.
- AAP baby walkers; Health Canada ban (2004).
- AAP and CDC insect repellents (DEET from 2 months; OLE/PMD not under 3); WHO dengue fact sheet (avoid NSAIDs).
- WHO Viet Nam / MoH, World Drowning Prevention Day release (25 July 2025); WHO drowning fact sheet.
- NICE NG143 (fever under 5); WHO IMCI; NHS febrile seizures; NHS jaundice.
- CDC milestones (2022 revision); WHO MGRS motor windows.
- de Weerth & van Geert (1998), *BJDP* 16:15–44: abstract and ProQuest record (4 infants, weekly for 15 months, no common timing pattern).
- Vietnamese Road Traffic Order and Safety Law 2024, art. 10(3), and Law 118/2025 (secondary sources: thuvienphapluat.vn, baovanhoa.vn). **Unverified against the official gazette.**
- Emergency numbers for TH, ID, MY, PH: secondary compilations. PH and ID are flagged as low confidence.

All URLs in `additions/rhythm.json` answered HTTP 200 to `curl` on 2026-10-16, except unicef.org.uk (403, so I did not use it).
