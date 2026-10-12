# Sơ cứu trẻ em: seed pack notes (for medical review)

`pack.seed.json` follows `firstAidPackSchema` (`packages/contracts/src/first-aid.ts`), except that image fields hold a slug (for example `vo-lung`). The seed script maps each slug to an image id (`{slug}_{hash8}`). Source: `docs/discovery/figma-extract/20-v11-content-features.md`, Part D (7b–7i) and Parts E and F (TH01–TH24). Every Vietnamese string comes word for word from the design, except the ones listed in section 1. All English is an engineering draft for owner review (D-012).

## 0. Top-level note: content not in the design

> **CPR "Từ 1 tuổi" (child CPR, `cpr` / variant `from-1`) is NOT drawn.** It was written from standard paediatric BLS guidance: heel of one hand, lower half of the breastbone, about 5 cm, 100–120/min, 30:2, and 5 initial rescue breaths to mirror the infant page. The CPR protocol `child` (`compressionText` "Gót một bàn tay giữa ngực, ấn sâu khoảng 5 cm. Ấn theo nhịp tiếng bíp.") is also authored. A medical reviewer must sign these off before prod.

## 1. Strings written that are NOT in the design

### Undrawn variants (vi and en both authored)

**`cpr` / `from-1` ("Từ 1 tuổi")**, `cpr: "child"`, ageMonths 12–null

- The banner and both callouts are reused from the drawn infant variant.
- Step 1 "Mở đường thở": "Một tay đặt lên trán, ngửa đầu, nâng cằm. Có vật cản thấy rõ trong miệng: lấy ra." This is the infant text without "nhẹ" (a child gets a fuller head tilt).
- Step 2 "Thổi ngạt 5 lần": "Bịt mũi bé, miệng bạn trùm kín miệng bé. Thổi đều, nhìn ngực bé phồng lên."
- Step 3 "Ép ngực 30 lần": "Gót một bàn tay giữa ngực, nửa dưới xương ức. Ấn sâu khoảng 5 cm, 100–120 lần/phút." It has the same chips "× 30" and "100–120 lần/phút".
- Step 4 "Thổi ngạt 2 lần, lặp lại": the same text as the infant variant.
- Review point: the 5 initial breaths follow ERC. AHA lay-rescuer guidance starts with compressions (C-A-B). The reviewer should choose one approach for both ages.

**`bleeding` / `object` ("Có dị vật")**, TH09

- Steps:
  1. "Không rút dị vật ra" / "Để nguyên vật đâm vào vết thương. Rút ra có thể làm máu chảy nhiều hơn."
  2. "Ép gạc quanh dị vật" / "Đặt gạc hoặc vải sạch quanh dị vật, ép nhẹ quanh mép vết thương. Không ấn lên dị vật."
  3. "Đệm quanh, đưa bé đi viện" / "Đệm gạc hai bên cho dị vật không lay động, băng nhẹ quanh. Giữ bé nằm yên và đưa đến cơ sở y tế ngay."
- Không được làm: "Rút dị vật ra khỏi vết thương" · "Ấn hoặc băng chặt đè lên dị vật".
- Đưa bé đi viện ngay khi: "Có dị vật đâm vào: luôn đưa bé đi viện" · "Máu chảy nhiều, không cầm được: gọi 115". The second item is the drawn TH09 bullet with ": gọi 115" added.
- The wording follows TH07 step 4 ("Có dị vật: không rút ra, ép băng quanh dị vật").

**`eye-injury` / `swelling-bleeding` ("Sưng, chảy máu")**, TH14

- Steps:
  1. "Chườm lạnh nhẹ quanh mắt" / "Bọc túi đá hoặc khăn lạnh trong khăn sạch, đặt nhẹ quanh mắt 10–15 phút. Không ấn lên nhãn cầu."
  2. "Chảy máu: che nhẹ bằng gạc" / "Đặt gạc sạch che hờ lên mắt, không ép. Cho bé ngồi, đầu hơi cao."
  3. "Đưa bé đi khám mắt" / "Mắt chảy máu hoặc sưng nhiều sau va đập cần bác sĩ kiểm tra."
- Không được làm: "Xoa, dụi hoặc ấn lên mắt" · "Tự nhỏ thuốc hay dung dịch không rõ nguồn gốc" (drawn) · "Rút vật đâm vào mắt ra".
- Đưa bé đi viện ngay khi: reused word for word from the drawn TH14 box, which looks shared by both variants.

### Other authored content

- **CPR protocols:** the `infant` `compressionText` is the 7i body copy (drawn). The `child` `compressionText` is authored (see section 0). Both use 110/min, 30:2, as instructed.
- **Keywords:** all of them are authored in vi and en (5–8 per situation), except these taken from the design:
  - "Co giật do sốt", the 7c alternative title for `seizure`.
  - "Ngừng thở ở trẻ sinh non", the TH03 detail-page title for `apnoea`.
  - Review point: some keywords widen a page's scope, for example "Đuối nước" (drowning) on `cpr`, "Pin cúc áo" (button battery) on `poisoning`, "Ngồi trong xe nóng" on `heatstroke`, and "Hoá chất vào mắt" on `eye-injury`. Button batteries and chemical eye splashes need specific advice that these pages don't give. Drop those keywords if the reviewer prefers.
- **Category English titles:** Urgent, Wounds & burns, Insects & animals, Health.
- **quickSearch English:** trouble breathing, turning blue, bleeding, vomiting, rash, insects.

### English-only decisions

- US spelling, to match `app_en.arb` (diaper, color): diarrhea, jewelry, color, apnea, flashlight.
- "bé" is "baby" on infant-focused pages (CPR under 1, choking under 1, milk choking, apnoea, seizure, jaundice). It is "the child" on pages whose illustrations show a preschooler (TH06–TH23).
- Heading "Không được làm" is "Do not". Items are written as gerunds ("Tilting the head back"), so they read as "Do not: …".
- "Đưa bé đi viện ngay khi" is "Take baby to hospital right away if". "Khi nào cần đi khám" is "When to see a doctor". "Vàng da sinh lý" is "Normal jaundice". "Cần đi khám ngay" is "See a doctor now".
- The `cpr` title in English is plain "CPR" (vi "Hồi sức tim phổi (CPR)"). The `apnoea` title is "Stopped breathing (newborn)". "Kiến ba khoang" is "Rove beetle".
- "tổng đài" is "the operator". "cồn 70 độ" is "70% alcohol". "bác sĩ tai mũi họng" is "an ear, nose and throat doctor".
- The `jaundice` lead "Phân biệt sinh lý và bệnh lý" is "Telling normal jaundice from jaundice that needs care". This is a plain rewording, not literal.

## 2. Where the design was ambiguous, and what I chose

1. **TH03 title.** 7b says "Ngừng thở (sơ sinh)" but the detail page says "Ngừng thở ở trẻ sinh non". I used the 7b title, as instructed, and added the detail title as a keyword. `ageMonths` is 0–3, as instructed, even though the detail title says premature babies.
2. **Choking "Từ 1 tuổi" hero.** 7e still shows `Illus/FA/Vỗ lưng`, an infant back blow, and the design notes flag this as wrong for the age. I set variant `hero: "ep-bung"`. As a result, the abdominal-thrust image appears twice on that variant: as the hero and as the step 1 image. Set it to `null` to match the design exactly.
3. **Choking under-1 step 1 image.** Reading mode (7d) has no image inside step 1, but step mode (7f) shows `Vỗ lưng`, which is the hero. I left the step image as `null`. Step mode should fall back to the situation or variant hero when a step has no image.
4. **CPR "Từ 1 tuổi" images.** No child CPR illustration exists.
   - The variant `hero` is `null`, so the infant hero `ep-tim-so-sinh` will show.
   - Step 1 `image` is `null` (`mo-duong-tho` probably shows an infant; I did not check the bitmap).
   - The CPR protocol `child.image` is `null`.
   - Illustrations needed: child CPR (heel of hand) and a child airway image.
5. **TH08 "Không được làm" image** (`Illus/FA/Ngửa đầu (sai)`, with a red ✗). The schema has no image on callouts, so I dropped it. Its slug would be `ngua-dau-sai`. A schema change is needed if this image should show.
6. **TH06 step 4 image.** The layer is `Illus/FA/Mang theo vỏ thuốc`, but the bitmap is the hero `Hoá chất` (asset `fe122`). I used the layer name, as instructed: `mang-theo-vo-thuoc`. The seed script must upload the same bitmap under that slug, or alias it to `hoa-chat`.
7. **Shared callouts across variants.** Choking 7d and 7e have word-for-word identical banners and callouts, so I copied them into both variants. For TH14 the design suggests shared boxes. I reused the warning box and wrote a separate Don't box. For TH09 the drawn warning box belongs to `no-object`, and `object` has its own boxes.
8. **7c search.** The result sublines in 7c are body-text snippets, not leads. The schema has no snippet field, so search should also match step and callout text. 7c uses a separate `Icon/FA/Co giật do sốt` (thermometer). The schema allows one icon per situation, so it is unused. Its slug would be `icon-co-giat-do-sot`.
9. **Copy kept verbatim although it was flagged.**
   - TH10's warning box includes "Thay băng khi băng bị ướt, bẩn", which is aftercare.
   - TH12 Bong gân sits in "Vết thương & bỏng".
   - TH16, TH17 and TH22 put don'ts inside step text.
   - TH03, TH09 (no-object), TH12, TH16, TH17, TH21, TH22 and TH23 have no Don't box.
   - TH23 suggests warm milk with no age note.
10. **Emergency flags.** These follow the instructions (TH01–TH07, choking, TH19, TH20). TH13, TH16 and TH21 mention "gọi 115" in a bullet but are not flagged, which matches the design.
11. **TH24** has `steps: []`, so step mode must be hidden. Its callouts are in page order: positive, negative, warning.
12. **TH21** has two warning callouts in page order: "Khi nào cần đi khám", then "Đưa bé đi viện ngay khi".
13. **Variant ids.**
    - Age variants: `under-1` (0–12, exclusive) and `from-1` (12–null).
    - Condition variants: `no-object` / `object` (TH09) and `object` / `swelling-bleeding` (TH14).
    - In each case the first variant is the one drawn as selected.
14. **Choking** has `code: null`. 7d and 7e are not in the TH row.
15. **Values for the reviewer** (all copied from the design, not chosen by engineering):
    - CPR: 5 initial breaths, 4 cm depth, 100–120/min, 110 bpm metronome.
    - Choking: 5 + 5.
    - Times: nosebleed 10 min, cool water 15–20 min, sprain 48 h, seizure 5 min, vomiting 12 h.
    - Temperatures: 38 °C / 38,5 °C / 39 °C.
    - Jaundice: 48–72 h, 1 week (preterm 2 weeks).

## 3. Image slugs per situation

Icons come from 7b `Icon/FA/*` and have the prefix `icon-`. Heroes and step images come from `Illus/FA/*`.

| Situation       | Code | Icon                     | Hero                     | Step images (variant · step)                                                |
| --------------- | ---- | ------------------------ | ------------------------ | --------------------------------------------------------------------------- |
| cpr             | TH01 | icon-hoi-suc-tim-phoi    | ep-tim-so-sinh           | under-1 · 1: mo-duong-tho; from-1: none (hero falls back to ep-tim-so-sinh) |
| choking         | —    | icon-hoc-di-vat          | vo-lung                  | under-1 · 2: an-nguc; from-1 · hero override ep-bung, step 1: ep-bung       |
| milk-aspiration | TH02 | icon-sac-sua             | nam-nghieng-vo-lung      | 2: kich-thich-long-ban-chan; 3: vo-lung                                     |
| apnoea          | TH03 | icon-ngung-tho           | kich-thich-long-ban-chan | —                                                                           |
| seizure         | TH04 | icon-co-giat             | nam-nghieng-an-toan      | —                                                                           |
| anaphylaxis     | TH05 | icon-soc-phan-ve         | nam-ngua-ke-cao-chan     | —                                                                           |
| poisoning       | TH06 | icon-uong-nham-hoa-chat  | hoa-chat                 | 2: nam-nghieng-an-toan; 4: mang-theo-vo-thuoc (same bitmap as hoa-chat)     |
| traffic         | TH07 | icon-tai-nan-giao-thong  | khong-di-chuyen          | 4: ep-gac-cam-mau                                                           |
| nosebleed       | TH08 | icon-chay-mau-cam        | cui-dau-bop-mui          | — (Don't-box image ngua-dau-sai dropped)                                    |
| bleeding        | TH09 | icon-vet-thuong-chay-mau | ep-gac-cam-mau           | —                                                                           |
| bandaging       | TH10 | icon-bang-bo-co-ban      | quan-bang                | —                                                                           |
| scald           | TH11 | icon-bong-nuoc-soi       | xa-nuoc-mat              | —                                                                           |
| sprain          | TH12 | icon-bong-gan            | chuom-lanh-mat-ca        | —                                                                           |
| fracture        | TH13 | icon-gay-xuong           | nep-co-dinh              | —                                                                           |
| eye-injury      | TH14 | icon-ton-thuong-mat      | rua-mat                  | —                                                                           |
| dog-bite        | TH15 | icon-cho-can             | rua-xa-phong             | —                                                                           |
| bee-sting       | TH16 | icon-ong-dot             | kheu-ngoi-ong            | —                                                                           |
| rove-beetle     | TH17 | icon-kien-ba-khoang      | gat-kien                 | —                                                                           |
| ear-insect      | TH18 | icon-con-trung-vao-tai   | den-pin-vao-tai          | —                                                                           |
| snake-bite      | TH19 | icon-ran-can             | ran-can-bang-nhe         | —                                                                           |
| heatstroke      | TH20 | icon-say-nang            | lam-mat-co-the           | —                                                                           |
| temperature     | TH21 | icon-do-than-nhiet       | do-nhiet-do              | —                                                                           |
| food-poisoning  | TH22 | icon-ngo-doc-thuc-pham   | uong-nuoc-bu             | —                                                                           |
| cold-exposure   | TH23 | icon-nhiem-lanh          | quan-chan-am             | —                                                                           |
| jaundice        | TH24 | icon-vang-da-so-sinh     | so-sanh-vang-da          | —                                                                           |

CPR protocols: `infant.image` is `ep-tim-so-sinh`. `child.image` is `null`.

**Distinct illustrations (29):**

- an-nguc, chuom-lanh-mat-ca, cui-dau-bop-mui, den-pin-vao-tai, do-nhiet-do
- ep-bung, ep-gac-cam-mau, ep-tim-so-sinh, gat-kien, hoa-chat
- kheu-ngoi-ong, khong-di-chuyen, kich-thich-long-ban-chan, lam-mat-co-the, mang-theo-vo-thuoc
- mo-duong-tho, nam-nghieng-an-toan, nam-nghieng-vo-lung, nam-ngua-ke-cao-chan, nep-co-dinh
- quan-bang, quan-chan-am, ran-can-bang-nhe, rua-mat, rua-xa-phong
- so-sanh-vang-da, uong-nuoc-bu, vo-lung, xa-nuoc-mat

**Distinct icons (25):** one per situation, as listed in the table.

**Not used (no schema slot):** `ngua-dau-sai` (TH08 Don't box) and `icon-co-giat-do-sot` (7c).

**Badges baked into bitmaps:** cui-dau-bop-mui ✓, quan-bang ✓, gat-kien ✓, hoa-chat ✓, ngua-dau-sai ✗. They can't be localised and need alt text.
