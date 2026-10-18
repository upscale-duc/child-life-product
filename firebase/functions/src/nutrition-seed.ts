import type {
  NutrientContent,
  NutritionRuleContent,
  NutritionStageContent,
} from '@child-life/contracts';

/**
 * Expert drafts of Dinh dưỡng theo giai đoạn (D-083, P-163; plan `docs/product/nutrition-plan.md`
 * §7): the stages 0–36 months, the micronutrients and the suggestion rules, written from WHO,
 * Bộ Y tế / Viện Dinh dưỡng, AAP and NHS guidance. "Nhập bản nháp mẫu" imports them as Nháp
 * (an id that exists is left alone); they reach the app only through the editorial workflow
 * (D-076, D-079), and on prod only with the qualified review.
 *
 * Written by engineering in the voice of a paediatric dietitian / paediatrician; nothing here has
 * been reviewed by a qualified person yet, and `reviewerLabel` only says who is expected to review.
 * Copy rules (P-163 #16): plain warm Vietnamese source, faithful English; never a dose ("theo chỉ
 * định bác sĩ"), never a condition name (`nutritionForbiddenWords`), always a doctor when something
 * is off. Feeding follows WHO: exclusive breastfeeding to 6 months, responsive feeding, no salt,
 * sugar, fish sauce or honey before 12 months, no cow's milk as the main drink before 12 months.
 * Milk amounts are references for bottle feeding: AAP (about 30–60 ml per feed in the first week,
 * 90–120 ml by the end of the first month, 180–240 ml at 6 months, on average no more than about
 * 960 ml a day), NHS (about 600 ml at 7–9 months, 400 ml at 10–12 months, at least 350 ml of milk
 * or dairy a day for young children) and AAP drinks guidance (about 480 ml at 12–24 months).
 * Growth-rule banners use the literal `{name}` token; the app puts the baby's name there.
 */

export interface NutritionSeed<T> {
  id: string;
  reviewerLabel: string | null;
  data: T;
}

/** Who is expected to review each item (D01 "Duyệt bởi"); not a claim of review. */
const NUTRITION = 'Nhóm chuyên môn · Dinh dưỡng nhi';

const t = (vi: string, en: string) => ({ vi, en });
const tip = (title: [string, string], body: [string, string]) => ({
  title: t(...title),
  body: t(...body),
});

// ---------- Sources (specific pages, opened when the text was written, 2026-10-18) ----------

const S = {
  whoIycf: {
    label: 'WHO — Infant and young child feeding (fact sheet)',
    url: 'https://www.who.int/news-room/fact-sheets/detail/infant-and-young-child-feeding',
  },
  whoCf2023: {
    label:
      'WHO — Guideline for complementary feeding of infants and young children 6–23 months of age (2023)',
    url: 'https://www.who.int/publications/i/item/9789240081864',
  },
  whoBreastfeedingVn: {
    label: 'WHO Việt Nam — Nuôi con bằng sữa mẹ (Breastfeeding)',
    url: 'https://www.who.int/vietnam/health-topics/breastfeeding',
  },
  whoVitaminA2011: {
    label:
      'WHO — Guideline: vitamin A supplementation in infants and children 6–59 months of age (2011)',
    url: 'https://www.who.int/publications/i/item/9789241501767',
  },
  whoElenaVitaminA: {
    label: 'WHO eLENA — Vitamin A supplementation in infants and children 6–59 months of age',
    url: 'https://www.who.int/tools/elena/interventions/vitamina-children',
  },
  whoDiarrhoea: {
    label: 'WHO — Diarrhoeal disease (fact sheet)',
    url: 'https://www.who.int/news-room/fact-sheets/detail/diarrhoeal-disease',
  },
  whoElenaZincDiarrhoea: {
    label: 'WHO eLENA — Zinc supplementation in the management of diarrhoea',
    url: 'https://www.who.int/tools/elena/interventions/zinc-diarrhoea',
  },
  whoAnaemia: {
    label: 'WHO — Anaemia (fact sheet)',
    url: 'https://www.who.int/news-room/fact-sheets/detail/anaemia',
  },
  whoIodine: {
    label: 'WHO Nutrition Landscape Information System — Iodine deficiency',
    url: 'https://www.who.int/data/nutrition/nlis/info/iodine-deficiency',
  },
  whoGrowthStandards: {
    label: 'WHO — Child growth standards',
    url: 'https://www.who.int/tools/child-growth-standards',
  },
  whoActivity2019: {
    label: 'WHO — To grow up healthy, children need to sit less and play more (2019)',
    url: 'https://www.who.int/news/item/24-04-2019-to-grow-up-healthy-children-need-to-sit-less-and-play-more',
  },
  mohCf2026: {
    label:
      'Viện Dinh dưỡng — Bộ Y tế ban hành Hướng dẫn ăn bổ sung cho trẻ em từ 6 tháng đến 23 tháng tuổi (Quyết định 318/QĐ-BYT, 2026)',
    url: 'https://viendinhduong.vn/vi/professional-activities/tin-tuc-su-kien-hoi-thao-khoa-hoc/bo-y-te-ban-hanh-huong-dan-an-bo-sung-cho-tre-em-tu-6-thang-den-23-thang-tuoi-69a69db7295245a452071b94',
  },
  ninFirst1000Days: {
    label: 'Viện Dinh dưỡng — Nuôi dưỡng và chăm sóc dinh dưỡng 1000 ngày đầu đời (tài liệu)',
    url: 'https://viendinhduong.vn/storage/app/uploads/public/FileUpload/Files/TL_ND%20cham%20soc%20DD%201000%20ngay%20dau%20doi-Childfun.pdf',
  },
  ninZScoreTables: {
    label:
      'Viện Dinh dưỡng — Các bảng biểu đánh giá tình trạng dinh dưỡng trẻ em từ 0 đến dưới 5 tuổi dựa vào Z-score (WHO 2006)',
    url: 'https://viendinhduong.vn/vi/article/tin-tuc/cac-bang-bieu-danh-gia-tinh-trang-dinh-duong-tre-em-tu-0-den-duoi-5-tuoi-dua-vao-z-score-who-2006-67dcda399a9d79fd1e0fa462',
  },
  ninVitaminA: {
    label: 'Viện Dinh dưỡng — Phòng chống thiếu vitamin A cho trẻ',
    url: 'https://viendinhduong.vn/vi/professional-activities/pho-bien-kien-thuc-dinh-duong/phong-chong-thieu-vitamin-a-cho-tre-67e7e300d932331be114a0a1',
  },
  ninVitaminA2026: {
    label: 'Viện Dinh dưỡng — Có nên bổ sung vitamin A liều cao kéo dài cho trẻ? (05/2026)',
    url: 'https://viendinhduong.vn/vi/article/tin-tuc/co-nen-bo-sung-vitamin-a-lieu-cao-keo-dai-cho-tre-6a196b9512d3e2d0cd0bf232',
  },
  skdsVitaminA2026: {
    label:
      'Sức khỏe & Đời sống (Bộ Y tế) — Cha mẹ cần lưu ý gì khi cho con đi uống vitamin A liều cao? (09/2026)',
    url: 'https://suckhoedoisong.vn/cha-me-can-luu-y-gi-khi-cho-con-di-uong-vitamin-a-lieu-cao-169260908144355532.htm',
  },
  hcdcVitaminA: {
    label:
      'HCDC TP.HCM — Ngày 1–2 tháng 6, cho trẻ từ 6 đến dưới 36 tháng tuổi uống vitamin A miễn phí',
    url: 'https://hcdc.vn/ngay-12-thang-6-hay-cho-tre-tu-6-thang-den-duoi-36-thang-tuoi-di-uong-vitamin-a-mien-phi-tai-tram-y-te-7ftN1G.html',
  },
  ninIodisedSalt: {
    label: 'Viện Dinh dưỡng — Lời khuyên số 4: Nên sử dụng muối i-ốt, không ăn mặn',
    url: 'https://viendinhduong.vn/vi/professional-activities/nhung-loi-khuyen-dinh-duong/loi-khuyen-so-4-nen-su-dung-muoi-i-ot-khong-an-man-68d3b63a5b7e1ca8ed02d7c3',
  },
  aapFormulaAmount: {
    label: 'HealthyChildren.org (AAP) — Amount and schedule of baby formula feedings',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/formula-feeding/Pages/Amount-and-Schedule-of-Formula-Feedings.aspx',
  },
  aapHowOftenHowMuch: {
    label: 'HealthyChildren.org (AAP) — How often and how much should your baby eat?',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/feeding-nutrition/Pages/How-Often-and-How-Much-Should-Your-Baby-Eat.aspx',
  },
  aapEnoughMilk: {
    label: 'HealthyChildren.org (AAP) — How to tell if your baby is getting enough breast milk',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/breastfeeding/Pages/How-to-Tell-if-Baby-is-Getting-Enough-Milk.aspx',
  },
  aapStartingSolids: {
    label: 'HealthyChildren.org (AAP) — Starting solid foods',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/feeding-nutrition/Pages/Starting-Solid-Foods.aspx',
  },
  aapOneYearOld: {
    label: 'HealthyChildren.org (AAP) — Feeding and nutrition tips: your 1-year-old',
    url: 'https://www.healthychildren.org/English/ages-stages/toddler/nutrition/Pages/Feeding-and-Nutrition-Your-One-Year-Old.aspx',
  },
  aapDrinks: {
    label: 'HealthyChildren.org (AAP) — Recommended drinks for children age 5 and younger',
    url: 'https://www.healthychildren.org/English/healthy-living/nutrition/Pages/Recommended-Drinks-for-Young-Children-Ages-0-5.aspx',
  },
  aapVitaminD: {
    label: 'HealthyChildren.org (AAP) — Vitamin D for babies, children and adolescents',
    url: 'https://www.healthychildren.org/English/healthy-living/nutrition/Pages/vitamin-d-on-the-double.aspx',
  },
  aapVitaminIron: {
    label: 'HealthyChildren.org (AAP) — Where we stand: vitamin D and iron supplements for babies',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/feeding-nutrition/Pages/Vitamin-Iron-Supplements.aspx',
  },
  aapIron2026: {
    label:
      'HealthyChildren.org (AAP) — Iron deficiency and iron deficiency anemia: AAP updates screening, prevention and treatment guidance (2026)',
    url: 'https://www.healthychildren.org/English/news/Pages/iron-deficiency-anemia-prevention-screening-treatment-AAP-updates-guidance.aspx',
  },
  aapSunSafety: {
    label: 'HealthyChildren.org (AAP) — Sun safety',
    url: 'https://www.healthychildren.org/English/safety-prevention/at-play/Pages/Sun-Safety.aspx',
  },
  cdcHungryFull: {
    label: 'CDC — Signs your child is hungry or full',
    url: 'https://www.cdc.gov/infant-toddler-nutrition/mealtime/signs-your-child-is-hungry-or-full.html',
  },
  cdcIron: {
    label: 'CDC — Infant and toddler nutrition: iron',
    url: 'https://www.cdc.gov/infant-toddler-nutrition/vitamins-minerals/iron.html',
  },
  cdcZinc: {
    label: 'CDC — Infant and toddler nutrition: zinc',
    url: 'https://www.cdc.gov/infant-toddler-nutrition/vitamins-minerals/zinc.html',
  },
  cdcChoking: {
    label: 'CDC — Infant and toddler nutrition: choking hazards',
    url: 'https://www.cdc.gov/infant-toddler-nutrition/foods-and-drinks/choking-hazards.html',
  },
  nhsFirstDays: {
    label: 'NHS — Breastfeeding: the first few days',
    url: 'https://www.nhs.uk/baby/breastfeeding-and-bottle-feeding/breastfeeding/the-first-few-days/',
  },
  nhsBottleAdvice: {
    label: 'NHS — Bottle feeding advice',
    url: 'https://www.nhs.uk/baby/breastfeeding-and-bottle-feeding/bottle-feeding/advice/',
  },
  nhsStartWeaning: {
    label: 'NHS Best Start in Life — How to start weaning your baby',
    url: 'https://www.nhs.uk/best-start-in-life/baby/weaning/how-to-start-weaning-your-baby/',
  },
  nhsFrom6Months: {
    label: 'NHS Best Start in Life — What to feed your baby: from around 6 months',
    url: 'https://www.nhs.uk/best-start-in-life/baby/weaning/what-to-feed-your-baby/from-around-6-months/',
  },
  nhs7to9Months: {
    label: 'NHS Best Start in Life — What to feed your baby: 7 to 9 months',
    url: 'https://www.nhs.uk/best-start-in-life/baby/weaning/what-to-feed-your-baby/7-to-9-months/',
  },
  nhs10to12Months: {
    label: 'NHS Best Start in Life — What to feed your baby: 10 to 12 months',
    url: 'https://www.nhs.uk/best-start-in-life/baby/weaning/what-to-feed-your-baby/10-to-12-months/',
  },
  nhsChokingGagging: {
    label: 'NHS Best Start in Life — Choking and gagging on food',
    url: 'https://www.nhs.uk/best-start-in-life/baby/weaning/safe-weaning/choking-and-gagging-on-food/',
  },
  nhsFoodsToAvoid: {
    label: 'NHS — Foods to avoid giving babies and young children',
    url: 'https://www.nhs.uk/baby/weaning-and-feeding/foods-to-avoid-giving-babies-and-young-children/',
  },
  nhsDrinksCups: {
    label: 'NHS — Drinks and cups for babies and young children',
    url: 'https://www.nhs.uk/baby/weaning-and-feeding/drinks-and-cups-for-babies-and-young-children/',
  },
  nhsYoungChildren: {
    label: 'NHS — What to feed young children',
    url: 'https://www.nhs.uk/baby/weaning-and-feeding/what-to-feed-young-children/',
  },
  nhsVitaminsChildren: {
    label: 'NHS — Vitamins for children',
    url: 'https://www.nhs.uk/baby/weaning-and-feeding/vitamins-for-children/',
  },
  nhsIron: {
    label: 'NHS — Vitamins and minerals: iron',
    url: 'https://www.nhs.uk/conditions/vitamins-and-minerals/iron/',
  },
  nhsCalcium: {
    label: 'NHS — Vitamins and minerals: calcium',
    url: 'https://www.nhs.uk/conditions/vitamins-and-minerals/calcium/',
  },
  nhsIodine: {
    label: 'NHS — Vitamins and minerals: iodine',
    url: 'https://www.nhs.uk/conditions/vitamins-and-minerals/iodine/',
  },
  unicef6to12: {
    label: 'UNICEF — Feeding your baby: 6–12 months',
    url: 'https://www.unicef.org/parenting/food-nutrition/feeding-your-baby-6-12-months',
  },
  unicef1to2: {
    label: 'UNICEF — Feeding your baby: 1–2 years',
    url: 'https://www.unicef.org/parenting/food-nutrition/feeding-your-baby-1-2-years',
  },
  fdaFish: {
    label: 'FDA — Advice about eating fish (including for children)',
    url: 'https://www.fda.gov/food/consumers/advice-about-eating-fish',
  },
} as const;

// ---------- Stages (P-163 #1: [0,1) [1,4) [4,6) [6,9) [9,12) [12,24) [24,36]) ----------

export const seedNutritionStages: readonly NutritionSeed<NutritionStageContent>[] = [
  {
    id: 'nst_0_1m',
    reviewerLabel: NUTRITION,
    data: {
      ageMonths: { from: 0, to: 1 },
      title: t('Những ngày đầu', 'The early days'),
      summary: t(
        'Sữa mẹ là tất cả những gì bé cần. Cho bú sớm trong giờ đầu sau sinh, rồi bú theo nhu cầu cả ngày lẫn đêm, khoảng 8–12 lần mỗi ngày. Bé chưa cần uống nước.',
        'Breast milk is all your baby needs. Breastfeed within the first hour after birth, then on demand day and night, about 8–12 times a day. Your baby does not need water.',
      ),
      // AAP: 30–60 ml per feed in the first week, 90–120 ml by the end of the month. No daily
      // band in the first month (P-163 #2): intake changes too fast from day to day.
      milk: {
        perFeedMl: { min: 30, max: 90 },
        feedsPerDay: { min: 8, max: 12 },
        perDayMl: null,
        breastfeedingNote: t(
          'Cho bú theo nhu cầu, khoảng 8–12 lần mỗi ngày.',
          'Breastfeed on demand, about 8–12 times a day.',
        ),
      },
      solids: null,
      sampleDay: [
        {
          slot: 'morning',
          kind: 'milk',
          text: t(
            'Sữa · bú mẹ khi bé có dấu hiệu đói, khoảng 2–3 giờ một lần',
            'Milk · breastfeed when your baby shows hunger cues, about every 2–3 hours',
          ),
        },
        {
          slot: 'noon',
          kind: 'milk',
          text: t(
            'Sữa · bú bình 30–60 ml mỗi cữ tuần đầu, tăng dần đến 60–90 ml',
            'Milk · bottle 30–60 ml per feed in the first week, rising to 60–90 ml',
          ),
        },
        {
          slot: 'afternoon',
          kind: 'sleep',
          text: t(
            'Ngủ · bé ngủ nhiều, thức dậy chủ yếu để bú',
            'Sleep · your baby sleeps a lot and wakes mostly to feed',
          ),
        },
        {
          slot: 'evening',
          kind: 'milk',
          text: t(
            'Sữa · bé có thể đòi bú nhiều cữ sát nhau, điều này bình thường',
            'Milk · your baby may want several feeds close together; this is normal',
          ),
        },
        {
          slot: 'night',
          kind: 'milk',
          text: t(
            'Sữa · vẫn bú đêm như ban ngày, bé chưa phân biệt ngày đêm',
            'Milk · night feeds as by day; your baby cannot tell day from night yet',
          ),
        },
      ],
      nutrientIds: ['nut_vitamin_d'],
      tips: [
        tip(
          ['Bú sớm, bú thường xuyên', 'Feed early and often'],
          [
            'Sữa non những ngày đầu ít nhưng rất quý. Bé bú càng thường xuyên, sữa về càng nhiều. Ôm bé da kề da giúp bé bú tốt hơn.',
            'Colostrum in the first days is small in amount but precious. The more often your baby feeds, the more milk comes in. Skin-to-skin contact helps your baby feed well.',
          ],
        ),
        tip(
          ['Nhận ra dấu hiệu đói sớm', 'Spot early hunger cues'],
          [
            'Mút tay, chép miệng, quay đầu tìm vú là dấu hiệu đói. Khóc là dấu hiệu muộn: hãy cho bú trước khi bé khóc.',
            'Sucking hands, smacking lips and turning to look for the breast are hunger cues. Crying is a late sign: feed before your baby cries.',
          ],
        ),
        tip(
          ['Bé có đủ sữa không?', 'Is your baby getting enough?'],
          [
            'Từ ngày thứ 5–6: khoảng 6 tã ướt trở lên mỗi ngày, phân vàng. Bé thường lấy lại cân nặng lúc sinh khi khoảng 2 tuần tuổi. Nếu không, hãy hỏi bác sĩ.',
            "From day 5–6: about 6 or more wet nappies a day and yellow stools. Babies usually regain their birth weight by about 2 weeks. If not, talk to your baby's doctor.",
          ],
        ),
        tip(
          ['Không nước, không mật ong', 'No water, no honey'],
          [
            'Bé bú mẹ hoàn toàn không cần uống nước. Không cho uống nước đường, không dùng mật ong (kể cả để rơ lưỡi) trước 12 tháng.',
            'A fully breastfed baby does not need water. No sugar water, and no honey before 12 months, not even to clean the tongue.',
          ],
        ),
      ],
      sources: [
        S.whoIycf,
        S.whoBreastfeedingVn,
        S.aapFormulaAmount,
        S.aapEnoughMilk,
        S.nhsFirstDays,
        S.nhsFoodsToAvoid,
      ],
    },
  },
  {
    id: 'nst_1_3m',
    reviewerLabel: NUTRITION,
    data: {
      ageMonths: { from: 1, to: 4 },
      title: t('Bú đều nhịp', 'Finding a feeding rhythm'),
      summary: t(
        'Sữa mẹ hoặc sữa công thức vẫn là tất cả những gì bé cần. Cữ bú dài và thưa dần, bé bắt đầu có nhịp riêng. Cho bú theo dấu hiệu đói, no thay vì theo giờ cứng nhắc.',
        'Breast milk or formula is still all your baby needs. Feeds get longer and further apart as your baby finds a rhythm. Feed by hunger and fullness cues rather than a strict clock.',
      ),
      // AAP: 90–120 ml by the end of month 1, about 75 ml per 450 g of body weight a day, on
      // average no more than about 960 ml a day.
      milk: {
        perFeedMl: { min: 90, max: 150 },
        feedsPerDay: { min: 6, max: 8 },
        perDayMl: { min: 500, max: 960 },
        breastfeedingNote: t(
          'Cho bú theo nhu cầu, thường 7–9 lần mỗi ngày.',
          'Breastfeed on demand, often 7–9 times a day.',
        ),
      },
      solids: null,
      sampleDay: [
        {
          slot: 'morning',
          kind: 'milk',
          text: t(
            'Sữa · bú mẹ hoặc 90–150 ml sữa công thức',
            'Milk · breastfeed or 90–150 ml of formula',
          ),
        },
        {
          slot: 'noon',
          kind: 'milk',
          text: t(
            'Sữa · cữ bú cách nhau khoảng 2,5–4 giờ, tùy bé',
            'Milk · feeds about 2½–4 hours apart, depending on your baby',
          ),
        },
        {
          slot: 'afternoon',
          kind: 'sleep',
          text: t(
            'Ngủ · xen kẽ giấc ngắn; khi bé thức, cho bé nằm sấp chơi',
            'Sleep · short naps; when awake, give your baby tummy time',
          ),
        },
        {
          slot: 'evening',
          kind: 'milk',
          text: t(
            'Sữa · bé có thể bú dồn vào buổi tối, điều này bình thường',
            'Milk · evening cluster feeds are normal',
          ),
        },
        {
          slot: 'night',
          kind: 'milk',
          text: t(
            'Sữa · bú đêm vẫn cần, giấc đêm dài dần',
            'Milk · night feeds are still needed; night sleep gets longer',
          ),
        },
      ],
      nutrientIds: ['nut_vitamin_d'],
      tips: [
        tip(
          ['Theo dấu hiệu, không theo đồng hồ', 'Follow cues, not the clock'],
          [
            'Đói: mút tay, chép miệng, rúc tìm vú. No: nhả vú hoặc núm bình, quay đi, tay thả lỏng. Không ép bé bú hết bình.',
            "Hungry: sucking hands, smacking lips, rooting. Full: letting go of the breast or teat, turning away, relaxed hands. Don't make your baby finish the bottle.",
          ],
        ),
        tip(
          ['Những ngày đòi bú nhiều', 'Days of extra feeding'],
          [
            'Quanh 6 tuần và 3 tháng, bé có thể đòi bú nhiều hơn trong vài ngày. Cho bú thường xuyên hơn, sữa mẹ sẽ theo kịp.',
            'Around 6 weeks and 3 months, your baby may want to feed more for a few days. Feeding more often helps your milk keep up.',
          ],
        ),
        tip(
          ['Pha sữa đúng cách', 'Make up formula safely'],
          [
            'Pha đúng tỉ lệ ghi trên hộp, không pha đặc hay loãng hơn. Pha xong dùng trong 2 giờ; sữa còn thừa sau cữ bú thì bỏ.',
            "Follow the scoop-to-water ratio on the tin; never make it stronger or weaker. Use within 2 hours of making it, and throw away what's left after a feed.",
          ],
        ),
        tip(
          ['Vitamin D cho bé bú mẹ', 'Vitamin D for breastfed babies'],
          [
            'Bé bú mẹ hoàn toàn hoặc một phần: hỏi bác sĩ về vitamin D dạng giọt và dùng theo chỉ định.',
            'If your baby is fully or partly breastfed, ask the doctor about vitamin D drops and use them as advised.',
          ],
        ),
      ],
      sources: [
        S.aapFormulaAmount,
        S.aapHowOftenHowMuch,
        S.cdcHungryFull,
        S.nhsBottleAdvice,
        S.aapVitaminD,
        S.whoIycf,
      ],
    },
  },
  {
    id: 'nst_4_5m',
    reviewerLabel: NUTRITION,
    data: {
      ageMonths: { from: 4, to: 6 },
      title: t('Chuẩn bị ăn dặm', 'Getting ready for solids'),
      summary: t(
        'Sữa vẫn đủ cho bé đến tròn 6 tháng. Đây là lúc quan sát dấu hiệu sẵn sàng: ngồi vững khi có đỡ, giữ đầu thẳng, tự đưa đồ vào miệng, nuốt được thay vì đẩy ra.',
        'Milk is still enough until your baby turns 6 months. Now is the time to watch for readiness: sitting with support, head steady, bringing things to the mouth, swallowing rather than pushing food out.',
      ),
      // AAP: 180–240 ml per feed by 6 months; on average no more than about 960 ml a day.
      milk: {
        perFeedMl: { min: 150, max: 210 },
        feedsPerDay: { min: 5, max: 6 },
        perDayMl: { min: 700, max: 960 },
        breastfeedingNote: t(
          'Cho bú theo nhu cầu. Chưa cần thêm nước hay thức ăn khác.',
          'Breastfeed on demand. No water or other food is needed yet.',
        ),
      },
      solids: null,
      sampleDay: [
        {
          slot: 'morning',
          kind: 'milk',
          text: t(
            'Sữa · bú mẹ hoặc 150–210 ml sữa công thức',
            'Milk · breastfeed or 150–210 ml of formula',
          ),
        },
        {
          slot: 'noon',
          kind: 'milk',
          text: t('Sữa · cữ bú cách nhau khoảng 3–4 giờ', 'Milk · feeds about 3–4 hours apart'),
        },
        {
          slot: 'afternoon',
          kind: 'milk',
          text: t(
            'Sữa · chưa cần nước, nước cháo hay bột; cho bé ngồi cùng mâm để làm quen',
            'Milk · no water, rice water or cereal yet; let your baby sit with the family at meals',
          ),
        },
        {
          slot: 'evening',
          kind: 'milk',
          text: t('Sữa · cữ tối trước khi ngủ', 'Milk · an evening feed before bed'),
        },
        {
          slot: 'night',
          kind: 'milk',
          text: t(
            'Sữa · bú đêm theo nhu cầu, nhiều bé bú đêm ít dần',
            'Milk · night feeds on demand; many babies need fewer',
          ),
        },
      ],
      nutrientIds: ['nut_vitamin_d', 'nut_iron'],
      tips: [
        tip(
          ['Chờ đến khoảng 6 tháng', 'Wait until around 6 months'],
          [
            'WHO khuyên bú mẹ hoàn toàn đến 6 tháng. Đòi bú nhiều, mút tay, thức đêm nhiều hơn chưa phải là dấu hiệu bé cần ăn dặm.',
            'WHO advises exclusive breastfeeding to 6 months. Wanting more feeds, chewing fists or waking more at night are not signs your baby needs solids.',
          ],
        ),
        tip(
          ['Dấu hiệu bé đã sẵn sàng', 'Signs your baby is ready'],
          [
            'Ngồi vững khi có đỡ, giữ đầu thẳng; nhìn, cầm và tự đưa đồ ăn vào miệng; nuốt được thay vì đẩy ra. Bé sinh non: hỏi bác sĩ khi nào bắt đầu.',
            'Sits with support and holds the head steady; looks at food, picks it up and brings it to the mouth; swallows rather than pushing it out. Born early? Ask the doctor when to start.',
          ],
        ),
        tip(
          ['Không cho bột vào bình sữa', 'No cereal in the bottle'],
          [
            'Bột pha trong bình không giúp bé ngủ lâu hơn, lại dễ làm bé sặc và ăn quá nhiều.',
            'Cereal in a bottle does not help your baby sleep longer, and it can cause choking and overfeeding.',
          ],
        ),
        tip(
          ['Chuẩn bị trước', 'Get ready ahead'],
          [
            'Ghế ăn có lưng tựa, thìa nhỏ mềm, cốc tập uống. Ba mẹ nên xem trước cách sơ cứu khi bé hóc trong mục Sơ cứu.',
            'A high chair with a back, a small soft spoon and a learner cup. It helps to read the choking steps in the First aid guide beforehand.',
          ],
        ),
      ],
      sources: [
        S.whoIycf,
        S.nhsStartWeaning,
        S.aapStartingSolids,
        S.aapFormulaAmount,
        S.cdcIron,
        S.aapVitaminD,
      ],
    },
  },
  {
    id: 'nst_6_8m',
    reviewerLabel: NUTRITION,
    data: {
      ageMonths: { from: 6, to: 9 },
      title: t('Bắt đầu ăn dặm', 'Starting solids'),
      summary: t(
        'Sữa vẫn là nguồn dinh dưỡng chính. Bắt đầu 2–3 thìa, tăng dần đến 2–3 bữa ăn dặm mỗi ngày, đặc và thô dần. Mỗi ngày nên có một món giàu sắt.',
        'Milk is still the main source of nutrition. Start with 2–3 spoonfuls and build up to 2–3 solid meals a day, gradually thicker and lumpier. Include an iron-rich food every day.',
      ),
      // AAP: 180–240 ml at 4–5 feeds at 6 months; NHS: about 600 ml a day at 7–9 months.
      milk: {
        perFeedMl: { min: 180, max: 240 },
        feedsPerDay: { min: 3, max: 5 },
        perDayMl: { min: 600, max: 900 },
        breastfeedingNote: t(
          'Cho bú theo nhu cầu; ăn dặm sau hoặc giữa các cữ bú.',
          'Breastfeed on demand; offer solids after or between feeds.',
        ),
      },
      solids: {
        meals: t('2–3 bữa mỗi ngày', '2–3 meals a day'),
        texture: t(
          'Sệt, không chảy khỏi thìa: nghiền mịn → lợn cợn',
          'Thick enough to stay on the spoon: smooth → lumpy mash',
        ),
      },
      sampleDay: [
        {
          slot: 'morning',
          kind: 'milk',
          text: t(
            'Sữa · bú mẹ hoặc 180–240 ml sữa công thức',
            'Milk · breastfeed or 180–240 ml of formula',
          ),
        },
        {
          slot: 'noon',
          kind: 'solids',
          text: t(
            'Ăn dặm · cháo nghiền + thịt hoặc cá, rau',
            'Solids · mashed rice porridge + meat or fish, vegetables',
          ),
        },
        {
          slot: 'afternoon',
          kind: 'milk',
          text: t('Sữa · 180–240 ml', 'Milk · 180–240 ml'),
        },
        {
          slot: 'afternoon',
          kind: 'snack',
          text: t(
            'Bữa phụ · chuối hoặc bơ nghiền, nếu bé còn đói',
            'Snack · mashed banana or avocado, if your baby is still hungry',
          ),
        },
        {
          slot: 'evening',
          kind: 'solids',
          text: t(
            'Ăn dặm · 2–3 thìa, tăng dần đến ½ chén nhỏ',
            'Solids · 2–3 spoonfuls, building up to ½ small bowl',
          ),
        },
        {
          slot: 'night',
          kind: 'milk',
          text: t('Sữa · bú theo nhu cầu', 'Milk · on demand'),
        },
      ],
      nutrientIds: ['nut_iron', 'nut_zinc', 'nut_vitamin_d', 'nut_vitamin_a'],
      tips: [
        tip(
          ['Mỗi ngày một món giàu sắt', 'An iron-rich food every day'],
          [
            'Thịt bò, gan gà, lòng đỏ trứng, cá nghiền vào cháo. Kèm rau quả giàu vitamin C giúp hấp thu sắt tốt hơn.',
            'Mash beef, chicken liver, egg yolk or fish into the porridge. Vitamin C-rich fruit and vegetables help the body absorb iron.',
          ],
        ),
        tip(
          ['Tăng dần độ đặc', 'Gradually thicker'],
          [
            'Từ cháo nghiền mịn sang lợn cợn khi bé quen. Chưa thêm muối, đường, nước mắm, hạt nêm vào phần của bé.',
            "Move from smooth to lumpy porridge as your baby gets used to it. No salt, sugar, fish sauce or stock powder in your baby's food yet.",
          ],
        ),
        tip(
          ['Không ép, kiên nhẫn với vị mới', 'No pressure, patience with new tastes'],
          [
            'Bé có thể cần thử nhiều lần, có khi hơn 10 lần, mới quen một vị. Dừng khi bé quay đi, ngậm miệng, đẩy thìa.',
            'Your baby may need many tries, sometimes more than 10, to accept a new taste. Stop when your baby turns away, closes their mouth or pushes the spoon.',
          ],
        ),
        tip(
          ['Ăn an toàn', 'Eat safely'],
          [
            'Cho bé ngồi thẳng, luôn có người lớn bên cạnh. Không cho ăn hạt nguyên, nho nguyên quả, thạch; không dùng mật ong trước 12 tháng.',
            'Sit your baby upright with an adult always beside them. No whole nuts, whole grapes or jelly cups, and no honey before 12 months.',
          ],
        ),
      ],
      sources: [
        S.whoCf2023,
        S.whoIycf,
        S.mohCf2026,
        S.unicef6to12,
        S.nhsFrom6Months,
        S.nhs7to9Months,
        S.aapFormulaAmount,
        S.cdcIron,
      ],
    },
  },
  {
    id: 'nst_9_11m',
    reviewerLabel: NUTRITION,
    data: {
      ageMonths: { from: 9, to: 12 },
      title: t('Ăn thô hơn', 'Chunkier food'),
      summary: t(
        'Bé ăn 3–4 bữa mỗi ngày, thêm 1–2 bữa phụ khi cần, thức ăn băm nhỏ, cắt miếng mềm. Cho bé tự cầm thức ăn và tập uống bằng cốc. Sữa vẫn quan trọng.',
        'Your baby eats 3–4 meals a day, plus 1–2 snacks if needed, with finely chopped food and soft pieces. Let your baby pick up food and practise drinking from a cup. Milk still matters.',
      ),
      // NHS: about 400 ml a day at 10–12 months (600 ml at 7–9); AAP: 180–240 ml per feed.
      milk: {
        perFeedMl: { min: 180, max: 240 },
        feedsPerDay: { min: 3, max: 4 },
        perDayMl: { min: 500, max: 800 },
        breastfeedingNote: t(
          'Tiếp tục cho bú theo nhu cầu, sau bữa ăn hoặc khi bé đói.',
          'Keep breastfeeding on demand, after meals or whenever hungry.',
        ),
      },
      solids: {
        meals: t('3–4 bữa + 1–2 bữa phụ', '3–4 meals + 1–2 snacks'),
        texture: t(
          'Băm nhỏ, cắt miếng mềm, thức ăn cầm tay',
          'Finely chopped, soft pieces, finger foods',
        ),
      },
      sampleDay: [
        {
          slot: 'morning',
          kind: 'milk',
          text: t(
            'Sữa · bú mẹ hoặc 180–240 ml sữa công thức',
            'Milk · breastfeed or 180–240 ml of formula',
          ),
        },
        {
          slot: 'morning',
          kind: 'solids',
          text: t(
            'Ăn dặm · cháo đặc + trứng chín kỹ, rau băm',
            'Solids · thick porridge + well-cooked egg, chopped vegetables',
          ),
        },
        {
          slot: 'noon',
          kind: 'solids',
          text: t(
            'Ăn dặm · cháo hoặc cơm nát + thịt, cá băm, rau; khoảng ½ chén nhỏ',
            'Solids · porridge or soft rice + minced meat or fish, vegetables; about ½ small bowl',
          ),
        },
        {
          slot: 'afternoon',
          kind: 'snack',
          text: t(
            'Bữa phụ · đu đủ, chuối cắt miếng mềm cho bé tự cầm',
            'Snack · soft pieces of papaya or banana to pick up',
          ),
        },
        {
          slot: 'afternoon',
          kind: 'milk',
          text: t('Sữa · 180–240 ml', 'Milk · 180–240 ml'),
        },
        {
          slot: 'evening',
          kind: 'solids',
          text: t(
            'Ăn dặm · ăn cùng giờ cả nhà, phần của bé chưa nêm',
            "Solids · eat with the family; your baby's portion unseasoned",
          ),
        },
        {
          slot: 'night',
          kind: 'milk',
          text: t(
            'Sữa · bú trước khi ngủ, bú đêm ít dần',
            'Milk · a feed before bed; fewer night feeds',
          ),
        },
      ],
      nutrientIds: ['nut_iron', 'nut_zinc', 'nut_vitamin_a', 'nut_dha'],
      tips: [
        tip(
          ['Cho bé tự cầm, tự xúc', 'Let your baby self-feed'],
          [
            'Thức ăn mềm cỡ ngón tay: cà rốt, bí đỏ hấp, trứng luộc, đậu phụ. Rơi vãi là một phần của việc học.',
            'Soft finger-sized pieces: steamed carrot or pumpkin, boiled egg, tofu. Mess is part of learning.',
          ],
        ),
        tip(
          ['Tăng độ thô, đừng xay mãi', "Add texture, don't purée for too long"],
          [
            'Bé nghiền được đồ mềm bằng lợi, chưa cần đủ răng. Ăn xay nhuyễn quá lâu có thể khiến bé khó nhận đồ thô về sau.',
            "Babies mash soft food with their gums; they don't need all their teeth. Puréeing for too long can make lumpier food harder to accept later.",
          ],
        ),
        tip(
          ['Cá khoảng 2 lần mỗi tuần', 'Fish about twice a week'],
          [
            'Cá hồi, cá nục, cá trích nấu chín, gỡ kỹ xương, cho bé đạm và DHA. Tránh cá mập, cá kiếm, cá ngừ mắt to.',
            'Well-cooked salmon, scad or herring with every bone removed gives protein and DHA. Avoid shark, swordfish and bigeye tuna.',
          ],
        ),
        tip(
          ['Tập uống bằng cốc', 'Practise with a cup'],
          [
            'Cho bé nhấp nước lọc bằng cốc trong bữa ăn. Không cho nước ép, nước ngọt, trà; chưa dùng sữa bò làm đồ uống chính.',
            "Offer sips of water from a cup at meals. No juice, sugary drinks or tea, and no cow's milk as the main drink yet.",
          ],
        ),
      ],
      sources: [
        S.whoIycf,
        S.whoCf2023,
        S.mohCf2026,
        S.unicef6to12,
        S.nhs10to12Months,
        S.nhsDrinksCups,
        S.fdaFish,
        S.nhsFoodsToAvoid,
      ],
    },
  },
  {
    id: 'nst_12_23m',
    reviewerLabel: NUTRITION,
    data: {
      ageMonths: { from: 12, to: 24 },
      title: t('Ăn cùng gia đình', 'Eating with the family'),
      summary: t(
        'Bé ăn 3–4 bữa chính và 1–2 bữa phụ, phần lớn là món của gia đình cắt nhỏ, nêm nhạt. Sữa trở thành đồ uống, khoảng 350–500 ml mỗi ngày. Tiếp tục bú mẹ nếu mẹ và bé muốn.',
        'Your child eats 3–4 meals and 1–2 snacks a day, mostly family food cut small and lightly seasoned. Milk becomes a drink, about 350–500 ml a day. Keep breastfeeding if you both want to.',
      ),
      // NHS: at least 350 ml of milk (or 2 servings of dairy) a day; AAP: about 480 ml at 12–24
      // months. Milk is a drink now, so no per-feed amount.
      milk: {
        perFeedMl: null,
        feedsPerDay: null,
        perDayMl: { min: 350, max: 500 },
        breastfeedingNote: t(
          'Tiếp tục bú mẹ đến 2 tuổi hoặc lâu hơn nếu mẹ và bé muốn.',
          'Keep breastfeeding to 2 years or beyond if you both want to.',
        ),
      },
      solids: {
        meals: t('3–4 bữa chính + 1–2 bữa phụ', '3–4 meals + 1–2 snacks'),
        texture: t(
          'Món gia đình cắt nhỏ, mềm; nêm nhạt',
          'Family food, cut small and soft; lightly seasoned',
        ),
      },
      sampleDay: [
        {
          slot: 'morning',
          kind: 'solids',
          text: t(
            'Bữa chính · cháo hoặc bún mềm cắt ngắn + trứng, rau',
            'Meal · porridge or soft noodles cut short + egg, vegetables',
          ),
        },
        {
          slot: 'noon',
          kind: 'solids',
          text: t(
            'Bữa chính · cơm nát, thịt hoặc cá, rau, canh; ¾–1 chén nhỏ',
            'Meal · soft rice, meat or fish, vegetables, soup; ¾–1 small bowl',
          ),
        },
        {
          slot: 'afternoon',
          kind: 'snack',
          text: t(
            'Bữa phụ · trái cây cắt nhỏ, sữa chua không đường',
            'Snack · chopped fruit, unsweetened yoghurt',
          ),
        },
        {
          slot: 'afternoon',
          kind: 'milk',
          text: t(
            'Sữa · 1 cốc sữa tươi nguyên kem không đường hoặc bú mẹ',
            'Milk · a cup of unsweetened whole milk, or a breastfeed',
          ),
        },
        {
          slot: 'evening',
          kind: 'solids',
          text: t(
            'Bữa chính · ăn cùng mâm gia đình, phần của bé nêm nhạt',
            "Meal · at the family table; your child's portion lightly seasoned",
          ),
        },
        {
          slot: 'night',
          kind: 'milk',
          text: t(
            'Sữa · bú mẹ hoặc 1 cốc sữa, rồi đánh răng trước khi ngủ',
            'Milk · a breastfeed or a cup of milk, then brush teeth before bed',
          ),
        },
      ],
      nutrientIds: ['nut_iron', 'nut_calcium', 'nut_vitamin_a', 'nut_dha', 'nut_iodine'],
      tips: [
        tip(
          ['Sữa là đồ uống, không thay bữa', 'Milk is a drink, not a meal'],
          [
            'Khoảng 2 cốc sữa mỗi ngày là đủ. Uống quá nhiều sữa dễ làm bé no, ăn ít bữa chính giàu sắt. Tập bỏ bình, chuyển sang cốc.',
            'About 2 cups of milk a day is enough. Too much milk fills your child up and leaves less room for iron-rich meals. Move from bottle to cup.',
          ],
        ),
        tip(
          ['Múc phần của bé trước khi nêm', "Serve your child's portion before seasoning"],
          [
            'Ăn cùng mâm nhưng nêm nhạt, dùng muối i-ốt. Hạn chế đồ ăn vặt đóng gói, nước ngọt, bánh kẹo.',
            'Eat together but season lightly, using iodised salt. Limit packaged snacks, sugary drinks and sweets.',
          ],
        ),
        tip(
          ['Ăn ít hơn có thể là bình thường', 'Eating less can be normal'],
          [
            'Sau 1 tuổi bé lớn chậm lại nên ăn thất thường. Ba mẹ chọn món, bé quyết định ăn bao nhiêu. Không ép, không dỗ ăn bằng màn hình.',
            'After age 1, growth slows and appetite varies. You choose the food; your child decides how much. No pressure, and no screens to coax eating.',
          ],
        ),
        tip(
          ['Phòng hóc', 'Prevent choking'],
          [
            'Cắt dọc nho, cà chua bi thành 4 phần; không cho ăn hạt nguyên, thạch, kẹo cứng. Cho bé ngồi yên khi ăn, không vừa chạy vừa ăn.',
            'Cut grapes and cherry tomatoes lengthwise into quarters; no whole nuts, jelly cups or hard sweets. Your child should sit while eating, not run around.',
          ],
        ),
      ],
      sources: [
        S.whoIycf,
        S.whoCf2023,
        S.mohCf2026,
        S.unicef1to2,
        S.aapDrinks,
        S.aapOneYearOld,
        S.nhsYoungChildren,
        S.cdcChoking,
      ],
    },
  },
  {
    id: 'nst_24_36m',
    reviewerLabel: NUTRITION,
    data: {
      ageMonths: { from: 24, to: 37 },
      title: t('Tự lập bữa ăn', 'Eating on their own'),
      summary: t(
        'Bé tự xúc, ngồi cùng mâm và ăn được hầu hết món của gia đình. Mỗi ngày đủ các nhóm thực phẩm qua 3 bữa chính và 1–2 bữa phụ. Hạn chế đồ ngọt, đồ ăn vặt, nước ngọt.',
        'Your child feeds themselves, sits at the family table and eats most family dishes. Aim for every food group each day across 3 meals and 1–2 snacks. Limit sweets, packaged snacks and sugary drinks.',
      ),
      // NHS: at least 350 ml of milk or 2 servings of dairy a day; AAP: 480–720 ml at 2–5 years.
      milk: {
        perFeedMl: null,
        feedsPerDay: null,
        perDayMl: { min: 350, max: 500 },
        breastfeedingNote: t(
          'Có thể tiếp tục bú mẹ nếu mẹ và bé muốn.',
          'You can keep breastfeeding if you both want to.',
        ),
      },
      solids: {
        meals: t('3 bữa chính + 1–2 bữa phụ', '3 meals + 1–2 snacks'),
        texture: t(
          'Món gia đình; vẫn cắt nhỏ đồ tròn, cứng',
          'Family food; still cut round or hard foods small',
        ),
      },
      sampleDay: [
        {
          slot: 'morning',
          kind: 'solids',
          text: t('Bữa chính · bún, phở hoặc bánh mì + trứng', 'Meal · noodles or bread + egg'),
        },
        {
          slot: 'morning',
          kind: 'snack',
          text: t('Bữa phụ · trái cây cắt miếng', 'Snack · fruit cut into pieces'),
        },
        {
          slot: 'noon',
          kind: 'solids',
          text: t(
            'Bữa chính · cơm, thịt hoặc cá hoặc đậu phụ, rau, canh',
            'Meal · rice, meat, fish or tofu, vegetables, soup',
          ),
        },
        {
          slot: 'afternoon',
          kind: 'snack',
          text: t(
            'Bữa phụ · sữa chua hoặc 1 cốc sữa, khoai lang luộc',
            'Snack · yoghurt or a cup of milk, boiled sweet potato',
          ),
        },
        {
          slot: 'evening',
          kind: 'solids',
          text: t(
            'Bữa chính · ăn cùng gia đình, bé tự xúc',
            'Meal · with the family; your child feeds themselves',
          ),
        },
        {
          slot: 'night',
          kind: 'milk',
          text: t(
            'Sữa · 1 cốc sữa nếu bé muốn, rồi đánh răng',
            'Milk · a cup of milk if wanted, then brush teeth',
          ),
        },
      ],
      nutrientIds: ['nut_calcium', 'nut_vitamin_d', 'nut_iron', 'nut_vitamin_a', 'nut_iodine'],
      tips: [
        tip(
          ['Đa dạng mỗi ngày', 'Variety every day'],
          [
            'Mỗi ngày có tinh bột, đạm (thịt, cá, trứng, đậu), sữa, rau xanh và trái cây. Thêm một ít dầu, mỡ khi nấu.',
            'Every day: starchy food, protein (meat, fish, eggs, beans), dairy, green vegetables and fruit. Add a little oil or fat when cooking.',
          ],
        ),
        tip(
          ['Bé tự xúc, ba mẹ ngồi cùng', 'Your child feeds; you sit together'],
          [
            'Ngồi ăn cùng bé, tắt tivi, điện thoại. Bữa ăn khoảng 20–30 phút; bé không ăn nữa thì cất đi, chờ bữa sau.',
            'Eat with your child with the TV and phones off. A meal takes about 20–30 minutes; if your child stops eating, clear it away and wait for the next meal.',
          ],
        ),
        tip(
          ['Hạn chế đồ ngọt', 'Go easy on sweet things'],
          [
            'Ưu tiên nước lọc và sữa không đường. Tránh nước ngọt, trà sữa, bánh kẹo: dễ sâu răng và làm bé bỏ bữa.',
            'Water and unsweetened milk first. Avoid soft drinks, milk tea and sweets: they harm teeth and spoil appetite for meals.',
          ],
        ),
        tip(
          ['Chọn sữa không đường', 'Choose unsweetened milk'],
          [
            'Sữa tươi không đường là lựa chọn tốt. Sữa công thức cho trẻ lớn không cần thiết với phần lớn bé khỏe; hỏi bác sĩ nếu không chắc.',
            'Unsweetened milk is a good choice. Growing-up formula is not needed for most healthy children; ask the doctor if unsure.',
          ],
        ),
      ],
      sources: [
        S.nhsYoungChildren,
        S.aapDrinks,
        S.unicef1to2,
        S.nhsFoodsToAvoid,
        S.ninIodisedSalt,
        S.cdcChoking,
      ],
    },
  },
];

// ---------- Nutrients (9b rows, 9d template, D03) ----------

export const seedNutrients: readonly NutritionSeed<NutrientContent>[] = [
  {
    id: 'nut_iron',
    reviewerLabel: NUTRITION,
    data: {
      key: 'iron',
      name: t('Sắt', 'Iron'),
      subtitle: t(
        'Dự trữ từ lúc sinh giảm dần · thịt, trứng, gan',
        'Stores from birth run down · meat, egg, liver',
      ),
      focus: {
        ageMonths: { from: 6, to: 37 },
        label: t('Quan trọng từ 6 tháng', 'Important from 6 months'),
        note: t(
          'Bé bú mẹ hoàn toàn: hỏi bác sĩ từ 4–6 tháng',
          'Fully breastfed: ask the doctor at 4–6 months',
        ),
      },
      why: t(
        'Bé đủ tháng sinh ra có sẵn sắt dự trữ, dùng dần trong 4–6 tháng đầu. Sau đó bé lớn nhanh mà sữa mẹ lại ít sắt, nên từ 6 tháng bé cần sắt từ bữa ăn dặm. Sắt giúp tạo máu mang oxy đi nuôi cơ thể và giúp não bộ phát triển. Sắt từ thịt, cá, trứng dễ hấp thu hơn sắt từ rau, đậu.',
        'Full-term babies are born with iron stores that last about 4–6 months. After that they grow fast while breast milk is low in iron, so from 6 months iron has to come from solid food. Iron helps make blood that carries oxygen around the body and supports brain development. Iron from meat, fish and eggs is absorbed better than iron from vegetables and beans.',
      ),
      foods: [
        t('Thịt bò', 'Beef'),
        t('Gan gà', 'Chicken liver'),
        t('Lòng đỏ trứng', 'Egg yolk'),
        t('Cá', 'Fish'),
        t('Thịt gà phần đùi', 'Dark chicken meat'),
        t('Đậu, đỗ', 'Beans and pulses'),
        t('Đậu phụ', 'Tofu'),
        t('Rau xanh đậm', 'Dark green vegetables'),
        t('Ngũ cốc tăng cường sắt', 'Iron-fortified cereal'),
      ],
      tip: t(
        'Ăn kèm rau quả giàu vitamin C (cam, ổi, cà chua, súp lơ xanh) giúp hấp thu sắt tốt hơn. Gan rất giàu vitamin A, chỉ nên ăn khoảng 1 lần mỗi tuần.',
        'Serve with vitamin C-rich fruit and vegetables (orange, guava, tomato, broccoli) to absorb iron better. Liver is very high in vitamin A, so offer it only about once a week.',
      ),
      byAge: [
        {
          ageMonths: { from: 0, to: 4 },
          label: t('0–3 tháng', '0–3 months'),
          text: t(
            'Bé đủ tháng dùng sắt dự trữ từ lúc sinh, chưa cần thêm. Bé sinh non, nhẹ cân: làm theo chỉ định bác sĩ.',
            "Full-term babies use the iron they were born with; nothing extra needed. Born early or small: follow the doctor's advice.",
          ),
        },
        {
          ageMonths: { from: 4, to: 6 },
          label: t('4–5 tháng', '4–5 months'),
          text: t(
            'Bé bú mẹ hoàn toàn: hỏi bác sĩ có cần bổ sung sắt không. Sữa công thức có tăng cường sắt thường đã đủ.',
            'Fully breastfed: ask the doctor whether an iron supplement is needed. Iron-fortified formula usually provides enough.',
          ),
        },
        {
          ageMonths: { from: 6, to: 12 },
          label: t('6–11 tháng', '6–11 months'),
          text: t(
            'Mỗi ngày có ít nhất một món giàu sắt: thịt, cá, trứng, gan, đậu nghiền. Chưa dùng sữa bò làm đồ uống chính.',
            "At least one iron-rich food a day: meat, fish, egg, liver, mashed beans. No cow's milk as the main drink yet.",
          ),
        },
        {
          ageMonths: { from: 12, to: 24 },
          label: t('12–23 tháng', '12–23 months'),
          text: t(
            'Thịt, cá hoặc trứng mỗi ngày; sữa vừa đủ để bé còn ăn bữa chính. Khoảng 12 tháng, bác sĩ có thể cho thử máu xem bé có thiếu máu không.',
            'Meat, fish or egg every day; keep milk moderate so there is room for meals. Around 12 months the doctor may check for anaemia with a blood test.',
          ),
        },
        {
          ageMonths: { from: 24, to: 37 },
          label: t('24–36 tháng', '24–36 months'),
          text: t(
            'Duy trì thịt, cá, trứng, đậu trong bữa gia đình; hạn chế bánh kẹo, nước ngọt.',
            'Keep meat, fish, eggs and beans in family meals; limit sweets and sugary drinks.',
          ),
        },
      ],
      warning: t(
        'Sắt dạng thuốc, siro chỉ dùng theo chỉ định bác sĩ. Thừa sắt có thể gây hại, uống nhầm có thể gây ngộ độc nặng: cất thuốc ngoài tầm tay trẻ.',
        "Iron medicine or syrup only as prescribed by a doctor. Too much iron can be harmful, and swallowing it by accident can cause serious poisoning: keep it out of children's reach.",
      ),
      campaign: null,
      sources: [S.whoCf2023, S.cdcIron, S.aapVitaminIron, S.aapIron2026, S.nhsIron, S.whoAnaemia],
    },
  },
  {
    id: 'nut_zinc',
    reviewerLabel: NUTRITION,
    data: {
      key: 'zinc',
      name: t('Kẽm', 'Zinc'),
      subtitle: t('Hỗ trợ tăng trưởng · thịt, cá, trứng', 'Supports growth · meat, fish, egg'),
      focus: {
        ageMonths: { from: 6, to: 24 },
        label: t('Quan trọng 6–23 tháng', 'Important at 6–23 months'),
        note: t('Có trong cùng nhóm thực phẩm giàu sắt', 'Found in the same foods as iron'),
      },
      why: t(
        'Kẽm giúp bé tăng trưởng, giúp cơ thể chống đỡ bệnh tật và vết thương mau lành. Lượng kẽm trong sữa mẹ giảm dần trong nửa năm đầu, nên từ 6 tháng bữa ăn dặm cần có thịt, cá, hải sản, trứng. Kẽm từ thịt, cá dễ hấp thu hơn từ ngũ cốc, đậu.',
        'Zinc helps your baby grow, fight off illness and heal wounds. The zinc in breast milk falls over the first half year, so from 6 months solid meals need meat, fish, seafood and eggs. Zinc from meat and fish is absorbed better than from grains and beans.',
      ),
      foods: [
        t('Thịt bò', 'Beef'),
        t('Thịt heo nạc', 'Lean pork'),
        t('Thịt gà', 'Chicken'),
        t('Cá', 'Fish'),
        t('Tôm, cua nấu chín', 'Cooked shrimp, crab'),
        t('Trứng', 'Eggs'),
        t('Đậu, đỗ', 'Beans and pulses'),
        t('Sữa chua', 'Yoghurt'),
        t('Ngũ cốc nguyên hạt', 'Whole grains'),
      ],
      tip: t(
        'Mỗi bữa ăn dặm có một ít thịt, cá hoặc trứng là cách đơn giản để bé có cả sắt và kẽm.',
        'A little meat, fish or egg in every solid meal is an easy way to give both iron and zinc.',
      ),
      byAge: [
        {
          ageMonths: { from: 0, to: 6 },
          label: t('0–5 tháng', '0–5 months'),
          text: t(
            'Sữa mẹ hoặc sữa công thức cung cấp đủ kẽm cho bé.',
            'Breast milk or formula gives your baby enough zinc.',
          ),
        },
        {
          ageMonths: { from: 6, to: 12 },
          label: t('6–11 tháng', '6–11 months'),
          text: t(
            'Thêm thịt, cá, trứng băm nhỏ vào bữa ăn dặm mỗi ngày.',
            'Add minced meat, fish or egg to solid meals every day.',
          ),
        },
        {
          ageMonths: { from: 12, to: 37 },
          label: t('12–36 tháng', '12–36 months'),
          text: t(
            'Bữa ăn đa dạng có thịt, cá, hải sản, trứng, đậu đỗ và ngũ cốc.',
            'Varied meals with meat, fish, seafood, eggs, beans and grains.',
          ),
        },
        {
          ageMonths: null,
          label: t('Khi bé tiêu chảy', 'During diarrhoea'),
          text: t(
            'Bác sĩ có thể kê kẽm trong 10–14 ngày kèm dung dịch bù nước (ORS). Vẫn cho bé bú và ăn bình thường.',
            'The doctor may prescribe zinc for 10–14 days with oral rehydration solution (ORS). Keep breastfeeding and feeding as usual.',
          ),
        },
      ],
      warning: t(
        'Kẽm dạng thuốc, siro chỉ dùng theo chỉ định bác sĩ. Dùng kéo dài khi không cần có thể gây hại.',
        'Zinc medicine or syrup only as prescribed by a doctor. Taking it for a long time when it is not needed can be harmful.',
      ),
      campaign: null,
      sources: [S.cdcZinc, S.whoCf2023, S.whoDiarrhoea, S.whoElenaZincDiarrhoea, S.unicef6to12],
    },
  },
  {
    id: 'nut_vitamin_d',
    reviewerLabel: NUTRITION,
    data: {
      key: 'vitaminD',
      name: t('Vitamin D', 'Vitamin D'),
      subtitle: t(
        'Hỏi bác sĩ nếu bé bú mẹ hoàn toàn · cá hồi, trứng',
        'Ask the doctor if fully breastfed · salmon, egg',
      ),
      focus: {
        ageMonths: { from: 0, to: 37 },
        label: t('Từ sơ sinh', 'From birth'),
        note: t(
          'Bé bú mẹ hoàn toàn hoặc một phần: hỏi bác sĩ',
          'Fully or partly breastfed: ask the doctor',
        ),
      },
      why: t(
        'Vitamin D giúp cơ thể hấp thu canxi để xương và răng chắc khỏe. Sữa mẹ có ít vitamin D, còn sữa công thức đã được bổ sung sẵn. Ánh nắng giúp da tạo vitamin D nhưng không đáng tin và không an toàn cho bé nhỏ, nên bác sĩ thường khuyên bé bú mẹ dùng vitamin D dạng giọt từ những ngày đầu.',
        'Vitamin D helps the body absorb calcium for strong bones and teeth. Breast milk has little vitamin D, while formula already has it added. Sunlight helps skin make vitamin D but is neither reliable nor safe for young babies, so doctors usually advise vitamin D drops for breastfed babies from the first days.',
      ),
      foods: [
        t('Cá hồi', 'Salmon'),
        t('Cá nục', 'Scad'),
        t('Cá mòi', 'Sardines'),
        t('Lòng đỏ trứng', 'Egg yolk'),
        t('Sữa công thức', 'Infant formula'),
        t('Sữa có bổ sung vitamin D', 'Vitamin D-fortified milk'),
      ],
      tip: t(
        'Cho bé chơi ngoài trời lúc nắng nhẹ, ở chỗ râm, mặc áo dài tay, đội mũ. Bé dưới 6 tháng tránh nắng trực tiếp; tắm nắng không thay được vitamin D bác sĩ khuyên.',
        'Play outdoors when the sun is gentle, in the shade, with long sleeves and a hat. Keep babies under 6 months out of direct sun; sunbathing does not replace the vitamin D your doctor advises.',
      ),
      byAge: [
        {
          ageMonths: { from: 0, to: 12 },
          label: t('0–11 tháng', '0–11 months'),
          text: t(
            'Bé bú mẹ hoàn toàn hoặc một phần: hỏi bác sĩ về vitamin D dạng giọt từ những ngày đầu, dùng đều đến khi bác sĩ bảo dừng.',
            'Fully or partly breastfed: ask the doctor about vitamin D drops from the first days, and give them daily until told to stop.',
          ),
        },
        {
          ageMonths: null,
          label: t('Bú sữa công thức', 'Formula-fed'),
          text: t(
            'Sữa công thức đã có vitamin D. Bé bú kết hợp: hỏi bác sĩ có cần thêm không.',
            'Formula already contains vitamin D. Combination-fed: ask the doctor whether extra is needed.',
          ),
        },
        {
          ageMonths: { from: 12, to: 37 },
          label: t('12–36 tháng', '12–36 months'),
          text: t(
            'Hỏi bác sĩ có cần tiếp tục bổ sung không; thêm cá, trứng, sữa vào bữa ăn.',
            'Ask the doctor whether to continue; include fish, eggs and milk in meals.',
          ),
        },
        {
          ageMonths: null,
          label: t('Sinh non, ít ra ngoài trời', 'Born early, rarely outdoors'),
          text: t(
            'Những bé này thường cần chú ý hơn; làm theo hướng dẫn của bác sĩ.',
            "These children often need extra attention; follow the doctor's advice.",
          ),
        },
      ],
      warning: t(
        'Vitamin D dạng giọt chỉ dùng theo chỉ định bác sĩ, đong bằng dụng cụ đi kèm. Không dùng nhiều sản phẩm có vitamin D cùng lúc: thừa vitamin D có thể gây hại.',
        'Vitamin D drops only as advised by a doctor, measured with the dropper provided. Do not combine several products containing vitamin D: too much can be harmful.',
      ),
      campaign: null,
      sources: [S.aapVitaminD, S.nhsVitaminsChildren, S.aapVitaminIron, S.aapSunSafety],
    },
  },
  {
    id: 'nut_vitamin_a',
    reviewerLabel: NUTRITION,
    data: {
      key: 'vitaminA',
      name: t('Vitamin A', 'Vitamin A'),
      subtitle: t(
        'Uống bổ sung tại trạm y tế · gan, trứng, bí đỏ',
        'Given at the health station · liver, egg, pumpkin',
      ),
      focus: {
        ageMonths: { from: 6, to: 37 },
        label: t('6–36 tháng', '6–36 months'),
        note: t(
          'Uống miễn phí tại trạm y tế, đợt 1–2/6 và 1–2/12',
          'Free at the health station, on 1–2 June and 1–2 December',
        ),
      },
      why: t(
        'Vitamin A giúp mắt nhìn tốt khi thiếu sáng, giữ da và niêm mạc khỏe, giúp bé chống đỡ bệnh nhiễm khuẩn như tiêu chảy, sởi. Ở Việt Nam, trẻ 6–36 tháng được uống vitamin A miễn phí 2 lần mỗi năm tại trạm y tế. Vitamin A tan trong dầu mỡ, nên bữa ăn có một ít dầu giúp hấp thu tốt hơn.',
        'Vitamin A helps eyes see in dim light, keeps skin and the lining of the gut and airways healthy, and helps your child fight infections such as diarrhoea and measles. In Việt Nam, children aged 6–36 months get free vitamin A twice a year at the health station. Vitamin A dissolves in fat, so a little oil in meals helps absorption.',
      ),
      foods: [
        t('Sữa mẹ', 'Breast milk'),
        t('Gan', 'Liver'),
        t('Lòng đỏ trứng', 'Egg yolk'),
        t('Bí đỏ', 'Pumpkin'),
        t('Cà rốt', 'Carrot'),
        t('Khoai lang ruột vàng', 'Orange sweet potato'),
        t('Rau ngót', 'Sweet leaf'),
        t('Rau dền', 'Amaranth greens'),
        t('Đu đủ chín', 'Ripe papaya'),
        t('Xoài chín', 'Ripe mango'),
        t('Gấc', 'Gac fruit'),
      ],
      tip: t(
        'Ngày đi uống: mang sổ tiêm chủng hoặc sổ sức khỏe, cho bé ăn nhẹ trước đó. Báo nhân viên y tế nếu bé đang ốm hoặc vừa uống sản phẩm có vitamin A trong tháng qua.',
        'On the day: bring the vaccination or health book and give your child a light snack beforehand. Tell the health worker if your child is unwell or has had a product containing vitamin A in the past month.',
      ),
      byAge: [
        {
          ageMonths: { from: 0, to: 6 },
          label: t('0–5 tháng', '0–5 months'),
          text: t(
            'Sữa mẹ, nhất là sữa non, giàu vitamin A. Bé chưa đến tuổi uống tại trạm y tế.',
            'Breast milk, especially colostrum, is rich in vitamin A. Not yet old enough for the health station rounds.',
          ),
        },
        {
          ageMonths: { from: 6, to: 12 },
          label: t('6–11 tháng', '6–11 months'),
          text: t(
            'Bắt đầu được uống tại trạm y tế, nhân viên y tế cho liều theo tuổi. Thêm trứng, rau củ màu cam vào bữa ăn dặm.',
            'Now eligible at the health station; the health worker gives the right amount for age. Add egg and orange vegetables to solids.',
          ),
        },
        {
          ageMonths: { from: 12, to: 37 },
          label: t('12–36 tháng', '12–36 months'),
          text: t(
            'Uống 2 lần mỗi năm, đợt tháng 6 và tháng 12. Bữa ăn có trứng, gan, rau xanh đậm, quả chín màu vàng cam.',
            'Twice a year, in the June and December rounds. Meals with egg, liver, dark greens and ripe orange fruit.',
          ),
        },
        {
          ageMonths: null,
          label: t('Lịch ở địa phương', 'Local schedule'),
          text: t(
            'Ngày và độ tuổi cụ thể theo thông báo của trạm y tế; một số tỉnh, thành cho trẻ uống đến dưới 5 tuổi.',
            "Exact days and ages follow your health station's announcement; some provinces include children up to 5 years.",
          ),
        },
        {
          ageMonths: null,
          label: t('Khi bé ốm', 'When your child is ill'),
          text: t(
            'Bé bị sởi, tiêu chảy kéo dài: bác sĩ có thể cho uống thêm. Luôn báo lần uống gần nhất cho nhân viên y tế.',
            'With measles or long-lasting diarrhoea, the doctor may give an extra dose. Always mention the last time your child had vitamin A.',
          ),
        },
      ],
      warning: t(
        'Vitamin A liều cao chỉ uống tại trạm y tế hoặc theo chỉ định bác sĩ. Không tự mua thêm cho bé: vitamin A tích lũy trong cơ thể, thừa có thể gây ngộ độc.',
        'High-dose vitamin A only at the health station or as prescribed by a doctor. Do not buy extra yourself: vitamin A builds up in the body and too much can be toxic.',
      ),
      // The national supplementation days (Viện Dinh dưỡng): 1–2 June and 1–2 December, free at
      // the ward or commune health station; local stations announce the exact days.
      campaign: {
        rounds: [
          { month: 6, fromDay: 1, toDay: 2 },
          { month: 12, fromDay: 1, toDay: 2 },
        ],
        ageMonths: { from: 6, to: 37 },
        place: t('Trạm y tế phường, xã', 'Ward or commune health station'),
      },
      sources: [
        S.ninVitaminA,
        S.ninVitaminA2026,
        S.skdsVitaminA2026,
        S.hcdcVitaminA,
        S.whoVitaminA2011,
        S.whoElenaVitaminA,
      ],
    },
  },
  {
    id: 'nut_calcium',
    reviewerLabel: NUTRITION,
    data: {
      key: 'calcium',
      name: t('Canxi', 'Calcium'),
      subtitle: t(
        'Cho xương, răng chắc · sữa, sữa chua, đậu phụ',
        'For strong bones and teeth · milk, yoghurt, tofu',
      ),
      focus: {
        ageMonths: { from: 12, to: 37 },
        label: t('Quan trọng từ 12 tháng', 'Important from 12 months'),
        note: t(
          'Dưới 12 tháng: sữa mẹ hoặc sữa công thức là đủ',
          'Under 12 months: breast milk or formula is enough',
        ),
      },
      why: t(
        'Canxi giúp xương và răng phát triển chắc khỏe, cùng với vitamin D và vận động. Trong năm đầu, sữa mẹ hoặc sữa công thức cho bé phần lớn canxi cần thiết. Từ 12 tháng, khi sữa không còn là bữa chính, bé cần canxi từ sữa, sữa chua, phô mai, đậu phụ, tôm, cá nhỏ và rau xanh.',
        'Calcium builds strong bones and teeth, together with vitamin D and active play. In the first year, breast milk or formula gives most of the calcium your baby needs. From 12 months, when milk is no longer the main meal, calcium comes from milk, yoghurt, cheese, tofu, shrimp, small fish and green vegetables.',
      ),
      foods: [
        t('Sữa', 'Milk'),
        t('Sữa chua', 'Yoghurt'),
        t('Phô mai tiệt trùng', 'Pasteurised cheese'),
        t('Đậu phụ', 'Tofu'),
        t('Tôm, tép', 'Shrimp'),
        t('Cua đồng nấu chín', 'Cooked paddy crab'),
        t('Cá nhỏ, gỡ xương mềm', 'Small fish, soft bones removed'),
        t('Vừng giã nhỏ', 'Ground sesame'),
        t('Rau cải xanh', 'Mustard greens'),
        t('Súp lơ xanh', 'Broccoli'),
      ],
      tip: t(
        'Từ 12 tháng, khoảng 2 cốc sữa hoặc các món từ sữa mỗi ngày là đủ. Uống quá nhiều sữa dễ làm bé no, ăn ít bữa chính giàu sắt.',
        'From 12 months, about 2 cups of milk or dairy foods a day is enough. Too much milk fills your child up and leaves less room for iron-rich meals.',
      ),
      byAge: [
        {
          ageMonths: { from: 0, to: 6 },
          label: t('0–5 tháng', '0–5 months'),
          text: t(
            'Sữa mẹ hoặc sữa công thức cung cấp canxi bé cần.',
            'Breast milk or formula gives your baby the calcium needed.',
          ),
        },
        {
          ageMonths: { from: 6, to: 12 },
          label: t('6–11 tháng', '6–11 months'),
          text: t(
            'Vẫn bú mẹ hoặc sữa công thức; có thể thêm sữa chua, phô mai tiệt trùng, đậu phụ vào bữa ăn dặm.',
            'Keep breast milk or formula; yoghurt, pasteurised cheese and tofu can be added to solids.',
          ),
        },
        {
          ageMonths: { from: 12, to: 24 },
          label: t('12–23 tháng', '12–23 months'),
          text: t(
            'Sữa tươi nguyên kem không đường làm đồ uống, khoảng 2 cốc mỗi ngày, cùng sữa chua, đậu phụ, tôm, cá.',
            'Unsweetened whole milk as a drink, about 2 cups a day, plus yoghurt, tofu, shrimp and fish.',
          ),
        },
        {
          ageMonths: { from: 24, to: 37 },
          label: t('24–36 tháng', '24–36 months'),
          text: t(
            'Duy trì sữa, sữa chua, phô mai; chọn loại không đường hoặc ít đường.',
            'Keep up milk, yoghurt and cheese; choose unsweetened or low-sugar kinds.',
          ),
        },
      ],
      warning: t(
        'Không tự cho bé uống canxi dạng thuốc để mong bé cao hơn. Chỉ dùng khi bác sĩ chỉ định: thừa canxi có thể gây táo bón và làm giảm hấp thu sắt.',
        'Do not give calcium supplements hoping your child will grow taller. Use them only if a doctor prescribes them: too much calcium can cause constipation and reduce iron absorption.',
      ),
      campaign: null,
      sources: [S.nhsCalcium, S.nhsYoungChildren, S.aapDrinks, S.nhsDrinksCups, S.unicef1to2],
    },
  },
  {
    id: 'nut_dha',
    reviewerLabel: NUTRITION,
    data: {
      key: 'dha',
      name: t('DHA (omega-3)', 'DHA (omega-3)'),
      subtitle: t(
        'Cho não và mắt · cá hồi, cá nục, trứng',
        'For brain and eyes · salmon, scad, egg',
      ),
      focus: {
        ageMonths: { from: 6, to: 24 },
        label: t('Quan trọng 6–23 tháng', 'Important at 6–23 months'),
        note: t(
          'Bú mẹ: mẹ ăn cá ít thủy ngân 2–3 lần mỗi tuần',
          'Breastfeeding: mother eats low-mercury fish 2–3 times a week',
        ),
      },
      why: t(
        'DHA là một loại chất béo omega-3, có nhiều trong não và mắt. Sữa mẹ có sẵn DHA, lượng DHA phụ thuộc vào bữa ăn của mẹ; sữa công thức thường đã bổ sung. Từ khi ăn dặm, cá ít thủy ngân và trứng là nguồn DHA tốt. Phần lớn bé ăn cá đều đặn không cần uống thêm DHA dạng viên, siro.',
        "DHA is an omega-3 fat found in large amounts in the brain and eyes. Breast milk contains DHA, depending on the mother's diet, and formula usually has it added. Once solids start, low-mercury fish and eggs are good sources. Most children who eat fish regularly do not need DHA capsules or syrups.",
      ),
      foods: [
        t('Sữa mẹ', 'Breast milk'),
        t('Cá hồi', 'Salmon'),
        t('Cá nục', 'Scad'),
        t('Cá trích', 'Herring'),
        t('Cá mòi', 'Sardines'),
        t('Trứng', 'Eggs'),
      ],
      tip: t(
        'Cho bé ăn cá khoảng 2 lần mỗi tuần, nấu chín, gỡ kỹ xương. Chọn cá ít thủy ngân; tránh cá mập, cá kiếm, cá thu vua, cá ngừ mắt to.',
        'Offer fish about twice a week, well cooked with every bone removed. Choose low-mercury fish; avoid shark, swordfish, king mackerel and bigeye tuna.',
      ),
      byAge: [
        {
          ageMonths: { from: 0, to: 6 },
          label: t('0–5 tháng', '0–5 months'),
          text: t(
            'Sữa mẹ có DHA; mẹ cho con bú nên ăn cá ít thủy ngân 2–3 lần mỗi tuần. Sữa công thức thường đã có DHA.',
            'Breast milk contains DHA; breastfeeding mothers should eat low-mercury fish 2–3 times a week. Formula usually has DHA added.',
          ),
        },
        {
          ageMonths: { from: 6, to: 12 },
          label: t('6–11 tháng', '6–11 months'),
          text: t(
            'Thêm cá nấu chín, gỡ kỹ xương, nghiền vào cháo; trứng chín kỹ.',
            'Add well-cooked fish, bones removed, mashed into porridge; well-cooked egg.',
          ),
        },
        {
          ageMonths: { from: 12, to: 37 },
          label: t('12–36 tháng', '12–36 months'),
          text: t(
            'Cá khoảng 2 lần mỗi tuần, cùng trứng và bữa ăn đa dạng của gia đình.',
            'Fish about twice a week, with eggs and varied family meals.',
          ),
        },
      ],
      warning: t(
        'Viên, siro DHA hay dầu cá chỉ dùng khi bác sĩ khuyên. Một số loại dầu gan cá có cả vitamin A, D: dùng cùng sản phẩm khác dễ thừa, có thể gây hại.',
        'DHA capsules, syrups or fish oil only if a doctor advises. Some fish liver oils also contain vitamins A and D: combined with other products, too much can be harmful.',
      ),
      campaign: null,
      sources: [S.fdaFish, S.nhsFoodsToAvoid, S.whoCf2023, S.unicef6to12],
    },
  },
  {
    id: 'nut_iodine',
    reviewerLabel: NUTRITION,
    data: {
      key: 'iodine',
      name: t('I-ốt', 'Iodine'),
      subtitle: t(
        'Cho não và tuyến giáp · cá biển, trứng, sữa',
        'For brain and thyroid · sea fish, egg, milk',
      ),
      focus: {
        ageMonths: { from: 12, to: 37 },
        label: t('Quan trọng từ 12 tháng', 'Important from 12 months'),
        note: t(
          'Dưới 12 tháng: qua sữa mẹ, mẹ dùng muối i-ốt',
          'Under 12 months: through breast milk; mother uses iodised salt',
        ),
      },
      why: t(
        'I-ốt giúp tuyến giáp làm việc bình thường, cần cho sự phát triển của não và cơ thể bé. Dưới 12 tháng, bé nhận i-ốt qua sữa mẹ (khi mẹ ăn đủ i-ốt) hoặc sữa công thức. Từ 12 tháng, bé ăn cùng gia đình: nấu ăn bằng muối i-ốt nhưng nêm nhạt, cùng cá biển, trứng, sữa.',
        "Iodine keeps the thyroid working normally and is needed for your child's brain and body to develop. Under 12 months, babies get iodine through breast milk (when the mother has enough) or formula. From 12 months, your child eats family food: cook with iodised salt but season lightly, and include sea fish, eggs and milk.",
      ),
      foods: [
        t('Cá biển', 'Sea fish'),
        t('Tôm', 'Shrimp'),
        t('Trứng', 'Eggs'),
        t('Sữa', 'Milk'),
        t('Sữa chua', 'Yoghurt'),
        t('Muối i-ốt, từ 12 tháng', 'Iodised salt, from 12 months'),
      ],
      tip: t(
        'Dùng muối i-ốt cho cả nhà nhưng nêm nhạt. Trước 12 tháng không thêm muối, nước mắm vào đồ ăn của bé; múc phần của bé ra trước khi nêm.',
        "Use iodised salt for the whole family but season lightly. Before 12 months, add no salt or fish sauce to your baby's food; take your baby's portion out before seasoning.",
      ),
      byAge: [
        {
          ageMonths: { from: 0, to: 12 },
          label: t('0–11 tháng', '0–11 months'),
          text: t(
            'Bé nhận i-ốt qua sữa mẹ hoặc sữa công thức. Mẹ cho con bú dùng muối i-ốt. Chưa thêm muối vào đồ ăn của bé.',
            "Babies get iodine through breast milk or formula. Breastfeeding mothers use iodised salt. No salt in your baby's food yet.",
          ),
        },
        {
          ageMonths: { from: 12, to: 37 },
          label: t('12–36 tháng', '12–36 months'),
          text: t(
            'Nấu bằng muối i-ốt, nêm nhạt hơn người lớn; thêm cá biển, trứng, sữa.',
            'Cook with iodised salt, more lightly than for adults; include sea fish, eggs and milk.',
          ),
        },
      ],
      warning: t(
        'Không tự cho bé uống viên i-ốt hay sản phẩm rong biển dạng viên. Thừa i-ốt cũng có thể gây hại cho tuyến giáp; chỉ bổ sung theo chỉ định bác sĩ.',
        'Do not give iodine tablets or seaweed supplements on your own. Too much iodine can also harm the thyroid; supplement only as prescribed by a doctor.',
      ),
      campaign: null,
      sources: [S.ninIodisedSalt, S.whoIodine, S.nhsIodine, S.nhsFoodsToAvoid],
    },
  },
];

// ---------- Rules (9e, D04) ----------

export const seedNutritionRules: readonly NutritionSeed<NutritionRuleContent>[] = [
  {
    id: 'nru_weight_below',
    reviewerLabel: NUTRITION,
    data: {
      metric: 'weight',
      condition: 'belowRange',
      days: null,
      ageMonths: { from: 0, to: 37 },
      // 9e banner, as designed.
      banner: t(
        '2 lần đo gần nhất của {name} thấp hơn khoảng chuẩn. Đây không phải chẩn đoán. Hãy cho bé đi khám dinh dưỡng để bác sĩ đánh giá.',
        "{name}'s 2 most recent measurements are below the normal range. This is not a diagnosis. Please take your baby for a nutrition check-up so a doctor can assess.",
      ),
      tips: [
        tip(
          ['Duy trì sữa đều đặn', 'Keep milk feeds regular'],
          [
            'Tiếp tục cho bú mẹ hoặc sữa theo nhu cầu. Không giảm cữ sữa khi bé bắt đầu ăn dặm.',
            "Keep breastfeeding or milk feeds on demand. Don't cut milk feeds when your baby starts solids.",
          ],
        ),
        tip(
          ['Bữa ăn đặc dần, đủ chất', 'Thicker, nourishing meals'],
          [
            'Từ 6 tháng: thêm thịt, cá, trứng và một ít dầu ăn vào bữa của bé. Chia nhiều bữa nhỏ nếu bé ăn ít; không ép ăn.',
            "From 6 months: add meat, fish, egg and a little cooking oil to your baby's meals. Offer smaller, more frequent meals if appetite is small; never force-feed.",
          ],
        ),
        tip(
          ['Ghi lại bữa ăn và cữ bú', 'Log meals and feeds'],
          [
            'Ghi trong Child Life vài ngày trước khi khám và mang theo, để bác sĩ dễ đánh giá.',
            'Log them in Child Life for a few days before the visit and bring them along, so the doctor can assess more easily.',
          ],
        ),
        tip(
          ['Đo lại sau 2 tuần', 'Re-measure in 2 weeks'],
          [
            'Đo cùng giờ, cùng một chiếc cân, bé mặc ít đồ. Kiểm tra lại số đã nhập cho đúng.',
            'Same time of day, same scale, light clothing. Double-check the numbers you entered.',
          ],
        ),
      ],
      remindAfterDays: 14,
      export: true,
    },
  },
  {
    id: 'nru_weight_above',
    reviewerLabel: NUTRITION,
    data: {
      metric: 'weight',
      condition: 'aboveRange',
      days: null,
      ageMonths: { from: 0, to: 37 },
      banner: t(
        'Cân nặng ở 2 lần đo gần nhất của {name} cao hơn khoảng chuẩn. Đây không phải chẩn đoán. Mỗi bé mỗi khác, hãy trao đổi với bác sĩ ở lần khám tới.',
        "{name}'s weight at the 2 most recent measurements is above the normal range. This is not a diagnosis. Every child is different; talk to the doctor at the next visit.",
      ),
      tips: [
        tip(
          ['Cho ăn theo dấu hiệu đói, no', 'Feed by hunger and fullness cues'],
          [
            'Dừng khi bé quay đi, ngậm miệng, đẩy thìa hoặc nhả bình. Không ép ăn hết, cũng không tự cắt cữ hay cho bé ăn kiêng.',
            "Stop when your child turns away, closes their mouth, pushes the spoon or lets go of the bottle. Don't make them finish, and don't cut feeds or diet on your own.",
          ],
        ),
        tip(
          ['Dỗ bé bằng vòng tay', 'Comfort with cuddles'],
          [
            'Khi bé quấy mà chưa đói, thử ôm, bế, chơi cùng bé. Không cho bé ngậm bình sữa khi ngủ.',
            'When your child is fussy but not hungry, try cuddles, carrying or play. No bottle to fall asleep with.',
          ],
        ),
        tip(
          ['Nước lọc thay đồ uống ngọt', 'Water instead of sweet drinks'],
          [
            'Từ 6 tháng, cho bé nhấp nước lọc. Tránh nước ép, nước ngọt, sữa có đường.',
            'From 6 months, offer sips of water. Avoid juice, sugary drinks and sweetened milk.',
          ],
        ),
        tip(
          ['Vận động mỗi ngày', 'Active every day'],
          [
            'Cho bé nằm sấp chơi, bò, đi lại; hạn chế ngồi lâu trong xe đẩy, ghế. Không cho bé dưới 2 tuổi xem màn hình.',
            'Tummy time, crawling and walking; limit long stretches in a pram or seat. No screen time under 2 years.',
          ],
        ),
      ],
      remindAfterDays: 30,
      export: true,
    },
  },
  {
    id: 'nru_length_below',
    reviewerLabel: NUTRITION,
    data: {
      metric: 'length',
      condition: 'belowRange',
      days: null,
      ageMonths: { from: 0, to: 37 },
      banner: t(
        'Chiều dài ở 2 lần đo gần nhất của {name} thấp hơn khoảng chuẩn. Đây không phải chẩn đoán. Hãy trao đổi với bác sĩ để bé được đo lại và đánh giá.',
        "{name}'s length at the 2 most recent measurements is below the normal range. This is not a diagnosis. Talk to the doctor so your child can be re-measured and assessed.",
      ),
      tips: [
        tip(
          ['Đo cho đúng cách', 'Measure the right way'],
          [
            'Bé dưới 2 tuổi đo nằm, cần 2 người: giữ đầu chạm thước, duỗi thẳng gối, bàn chân dựng đứng. Đo lệch rất dễ sai số.',
            'Under 2 years, measure lying down with 2 people: head against the board, knees straight, feet upright. Small slips give big errors.',
          ],
        ),
        tip(
          ['Bữa ăn đủ đạm, đa dạng', 'Protein-rich, varied meals'],
          [
            'Mỗi ngày có thịt, cá, trứng hoặc đậu, cùng sữa, rau củ, trái cây theo tuổi của bé.',
            "Every day: meat, fish, egg or beans, plus milk, vegetables and fruit suited to your child's age.",
          ],
        ),
        tip(
          ['Ngủ đủ, vận động mỗi ngày', 'Enough sleep, active play'],
          [
            'Giấc ngủ đều đặn và thời gian chơi vận động mỗi ngày đều giúp bé lớn tốt.',
            'Regular sleep and active play every day both help your child grow well.',
          ],
        ),
        tip(
          ['Mang thông tin khi đi khám', 'Bring details to the visit'],
          [
            'Bác sĩ sẽ xem cả đường tăng trưởng, chiều cao của bố mẹ và tuần tuổi lúc sinh. Mang theo các lần đo đã ghi.',
            "The doctor looks at the whole growth curve, the parents' heights and the week of birth. Bring the measurements you've logged.",
          ],
        ),
      ],
      remindAfterDays: 30,
      export: true,
    },
  },
  {
    id: 'nru_milk_outside',
    reviewerLabel: NUTRITION,
    data: {
      metric: 'milk',
      condition: 'milkOutsideStage',
      days: null,
      ageMonths: { from: 0, to: 12 },
      banner: t(
        'Mỗi bé mỗi khác: lượng sữa thay đổi theo ngày và theo bữa ăn dặm. Hãy cho bú theo dấu hiệu đói, no, và trao đổi bác sĩ nếu kéo dài hoặc bé ít tã ướt, quấy nhiều.',
        'Every baby is different: milk intake varies from day to day and with solids. Feed by hunger and fullness cues, and talk to the doctor if it goes on, or if there are few wet nappies or a lot of fussing.',
      ),
      tips: [
        tip(
          ['Theo dấu hiệu đói, no', 'Follow hunger and fullness cues'],
          [
            'Đói: mút tay, chép miệng, quay đầu tìm vú. No: nhả núm, quay đi, tay thả lỏng. Không ép bú hết bình.',
            "Hungry: sucking hands, smacking lips, rooting. Full: letting go of the teat, turning away, relaxed hands. Don't make your baby finish the bottle.",
          ],
        ),
        tip(
          ['Ghi đủ các cữ bú bình', 'Log every bottle feed'],
          [
            'Trung bình chỉ tính các cữ có ghi ml. Cữ bú mẹ trực tiếp không có lượng ml nên không được tính.',
            'The average counts only feeds logged in ml. Breastfeeds have no ml amount, so they are not counted.',
          ],
        ),
      ],
      remindAfterDays: null,
      export: false,
    },
  },
  {
    id: 'nru_no_measurement',
    reviewerLabel: NUTRITION,
    data: {
      metric: 'measurement',
      condition: 'noMeasurement',
      days: 30,
      ageMonths: { from: 0, to: 25 },
      banner: t(
        'Đã lâu chưa cập nhật cân nặng, chiều dài của {name}. Đo và ghi lại định kỳ giúp theo dõi bé lớn lên so với chuẩn WHO.',
        "{name}'s weight and length haven't been updated for a while. Measuring regularly helps you follow your child's growth against the WHO standard.",
      ),
      tips: [
        tip(
          ['Bao lâu đo một lần', 'How often to measure'],
          [
            'Trẻ dưới 2 tuổi nên được cân, đo khoảng mỗi tháng một lần, hoặc theo lịch khám của bác sĩ.',
            "Children under 2 should be weighed and measured about once a month, or as the doctor's visits allow.",
          ],
        ),
        tip(
          ['Đo ở đâu cũng được', 'Any measurement counts'],
          [
            'Có thể ghi số đo từ lần khám, tiêm chủng hoặc tự cân ở nhà, nên dùng cùng một chiếc cân.',
            'Log numbers from check-ups or vaccination visits, or weigh at home, ideally on the same scale.',
          ],
        ),
      ],
      remindAfterDays: null,
      export: false,
    },
  },
];
