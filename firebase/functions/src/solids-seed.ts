import type { ContentBlock } from '@child-life/contracts';
import type { SeedArticle } from './content-seed.js';

/**
 * Engineering drafts of the Thư viện ăn dặm guides (D-085, plan `docs/product/solids-plan.md` §8;
 * Figma 5f): 16 articles that join the 7 solids articles in `content-seed.ts`, written in the
 * voice of a paediatric dietitian / paediatrician from WHO, Bộ Y tế / Viện Dinh dưỡng, UNICEF,
 * AAP (HealthyChildren.org), NHS, CDC, ASCIA and BSACI guidance, with the pages they rest on as
 * sources. "Nhập bản nháp mẫu" imports them as drafts and never overwrites an id that exists.
 *
 * Nothing here has been reviewed by a qualified person: every item is published with
 * `review: null` until a reviewer signs it, and `reviewerLabel` only says who is expected to
 * review. Copy rules (the same as `content-seed.ts`, plus D-085 #4): solids start at 6 months
 * (WHO: around 6 months, never before 4; an earlier start only on the baby's doctor's advice);
 * milk feeds continue; iron-rich foods and the common allergens early and kept up; no honey, salt,
 * sugar or cow's milk as the main drink before 12 months; no whole nuts, whole grapes or popcorn;
 * no doses ("theo chỉ định bác sĩ"); no stigmatising words (`nutritionForbiddenWords`); the
 * family's emergency number (`{emergency}`, D-087) named wherever allergy symptoms are. Plain text; vi is the source, en a faithful rendering (D-012).
 */

/** Who is expected to review each item (B01 "Người duyệt" filter); not a claim of review. */
const NUTRITION = 'Nhóm chuyên môn · Dinh dưỡng nhi';

const t = <T extends string | string[]>(vi: T, en: T) => ({ vi, en });
const p = (text: string): ContentBlock => ({ type: 'paragraph', text });
const h = (text: string): ContentBlock => ({ type: 'heading', text });
const ul = (...items: string[]): ContentBlock => ({ type: 'bullets', items });
const tip = (title: string, text: string): ContentBlock => ({
  type: 'callout',
  tone: 'tip',
  title,
  text,
});
const note = (title: string, text: string): ContentBlock => ({
  type: 'callout',
  tone: 'note',
  title,
  text,
});
const doctor = (title: string, text: string): ContentBlock => ({
  type: 'callout',
  tone: 'doctor',
  title,
  text,
});
/** "Gọi {emergency} ngay khi…" (D-087): red, with a button that dials the family's number. */
const urgent = (title: string, text: string): ContentBlock => ({
  type: 'callout',
  tone: 'urgent',
  title,
  text,
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
  whoDietaryDiversity: {
    label: 'WHO — Indicator: minimum dietary diversity, children 6–23 months',
    url: 'https://www.who.int/data/gho/indicator-metadata-registry/imr-details/7042',
  },
  whoAnaemia: {
    label: 'WHO — Anaemia (fact sheet)',
    url: 'https://www.who.int/news-room/fact-sheets/detail/anaemia',
  },
  whoFiveKeys: {
    label: 'WHO — Five keys to safer food manual',
    url: 'https://www.who.int/publications/i/item/9789241594639',
  },
  whoDiarrhoea: {
    label: 'WHO — Diarrhoeal disease (fact sheet)',
    url: 'https://www.who.int/news-room/fact-sheets/detail/diarrhoeal-disease',
  },
  whoSitLessPlayMore: {
    label: 'WHO — To grow up healthy, children need to sit less and play more (2019)',
    url: 'https://www.who.int/news/item/24-04-2019-to-grow-up-healthy-children-need-to-sit-less-and-play-more',
  },
  mohCf2026: {
    label:
      'Viện Dinh dưỡng — Bộ Y tế ban hành Hướng dẫn ăn bổ sung cho trẻ em từ 6 tháng đến 23 tháng tuổi (Quyết định 318/QĐ-BYT, 2026)',
    url: 'https://viendinhduong.vn/vi/professional-activities/tin-tuc-su-kien-hoi-thao-khoa-hoc/bo-y-te-ban-hanh-huong-dan-an-bo-sung-cho-tre-em-tu-6-thang-den-23-thang-tuoi-69a69db7295245a452071b94',
  },
  unicef6to12: {
    label: 'UNICEF — Feeding your baby: 6–12 months',
    url: 'https://www.unicef.org/parenting/food-nutrition/feeding-your-baby-6-12-months',
  },
  unicef1to2: {
    label: 'UNICEF — Feeding your baby: 1–2 years',
    url: 'https://www.unicef.org/parenting/food-nutrition/feeding-your-baby-1-2-years',
  },
  nhsFirstSolids: {
    label: "NHS — Your baby's first solid foods",
    url: 'https://www.nhs.uk/baby/weaning-and-feeding/babys-first-solid-foods/',
  },
  nhsHowToStart: {
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
  nhsStoringReheating: {
    label: 'NHS Best Start in Life — Storing and reheating baby food',
    url: 'https://www.nhs.uk/best-start-in-life/baby/weaning/safe-weaning/storing-and-reheating-food/',
  },
  nhsFoodsToAvoid: {
    label: 'NHS — Foods to avoid giving babies and young children',
    url: 'https://www.nhs.uk/baby/weaning-and-feeding/foods-to-avoid-giving-babies-and-young-children/',
  },
  nhsDrinksCups: {
    label: 'NHS — Drinks and cups for babies and young children',
    url: 'https://www.nhs.uk/baby/weaning-and-feeding/drinks-and-cups-for-babies-and-young-children/',
  },
  nhsFoodAllergies: {
    label: 'NHS — Food allergies in babies and young children',
    url: 'https://www.nhs.uk/baby/weaning-and-feeding/food-allergies-in-babies-and-young-children/',
  },
  nhsFussyEaters: {
    label: 'NHS — Fussy eaters',
    url: 'https://www.nhs.uk/baby/weaning-and-feeding/fussy-eaters/',
  },
  nhsYoungChildren: {
    label: 'NHS — What to feed young children',
    url: 'https://www.nhs.uk/baby/weaning-and-feeding/what-to-feed-young-children/',
  },
  nhsIron: {
    label: 'NHS — Vitamins and minerals: iron',
    url: 'https://www.nhs.uk/conditions/vitamins-and-minerals/iron/',
  },
  nhsAnaphylaxis: {
    label: 'NHS — Anaphylaxis',
    url: 'https://www.nhs.uk/conditions/anaphylaxis/',
  },
  nhsConstipation: {
    label: 'NHS — Constipation in children',
    url: 'https://www.nhs.uk/baby/health/constipation-in-children/',
  },
  nhsBottleConstipation: {
    label: 'NHS Best Start in Life — Constipation and bottle feeding',
    url: 'https://www.nhs.uk/best-start-in-life/baby/feeding-your-baby/bottle-feeding/bottle-feeding-challenges/constipation-and-bottle-feeding/',
  },
  nhsTeethingTips: {
    label: 'NHS — Tips for helping your teething baby',
    url: 'https://www.nhs.uk/baby/babys-development/teething/tips-for-helping-your-teething-baby/',
  },
  nhsDiarrhoea: {
    label: 'NHS — Diarrhoea and vomiting',
    url: 'https://www.nhs.uk/symptoms/diarrhoea-and-vomiting/',
  },
  niceConstipation: {
    label: 'NICE CG99 — Constipation in children and young people (recommendations)',
    url: 'https://www.nice.org.uk/guidance/cg99/chapter/Recommendations',
  },
  hcStartingSolids: {
    label: 'HealthyChildren.org (AAP) — Starting solid foods',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/feeding-nutrition/Pages/Starting-Solid-Foods.aspx',
  },
  hcResponsiveFeeding: {
    label: 'HealthyChildren.org (AAP) — Is your baby hungry or full? Responsive feeding explained',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/feeding-nutrition/Pages/Is-Your-Baby-Hungry-or-Full-Responsive-Feeding-Explained.aspx',
  },
  hcVitaminIron: {
    label: 'HealthyChildren.org (AAP) — Where we stand: vitamin D and iron supplements for babies',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/feeding-nutrition/Pages/Vitamin-Iron-Supplements.aspx',
  },
  hcRecommendedDrinks: {
    label: 'HealthyChildren.org (AAP) — Recommended drinks for children age 5 and younger',
    url: 'https://www.healthychildren.org/English/healthy-living/nutrition/Pages/Recommended-Drinks-for-Young-Children-Ages-0-5.aspx',
  },
  hcFruitJuice: {
    label: 'HealthyChildren.org (AAP) — Where we stand: fruit juice',
    url: 'https://www.healthychildren.org/English/healthy-living/nutrition/Pages/Where-We-Stand-Fruit-Juice.aspx',
  },
  hcChokingPrevention: {
    label: 'HealthyChildren.org (AAP) — Choking prevention',
    url: 'https://www.healthychildren.org/English/health-issues/injuries-emergencies/Pages/Choking-Prevention.aspx',
  },
  hcPickyEaters: {
    label: 'HealthyChildren.org (AAP) — Picky eaters',
    url: 'https://www.healthychildren.org/English/ages-stages/toddler/nutrition/Pages/Picky-Eaters.aspx',
  },
  hcInfantConstipation: {
    label: 'HealthyChildren.org (AAP) — Infant constipation',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/diapers-clothing/Pages/Infant-Constipation.aspx',
  },
  hcTeethingPain: {
    label: 'HealthyChildren.org (AAP) — Teething pain: how to help',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/teething-tooth-care/Pages/Teething-Pain.aspx',
  },
  hcOneYearOld: {
    label: 'HealthyChildren.org (AAP) — Feeding and nutrition tips: your 1-year-old',
    url: 'https://www.healthychildren.org/English/ages-stages/toddler/nutrition/Pages/Feeding-and-Nutrition-Your-One-Year-Old.aspx',
  },
  hcBottleToCup: {
    label:
      'HealthyChildren.org (AAP) — From bottle to cup: helping your child make a healthy transition',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/feeding-nutrition/Pages/Discontinuing-the-Bottle.aspx',
  },
  hcHighChair: {
    label: 'HealthyChildren.org (AAP) — 6 quick high chair safety tips',
    url: 'https://www.healthychildren.org/English/safety-prevention/at-home/Pages/High-Chair-Safety-Tips.aspx',
  },
  cdcHungryFull: {
    label: 'CDC — Signs your child is hungry or full',
    url: 'https://www.cdc.gov/infant-toddler-nutrition/mealtime/signs-your-child-is-hungry-or-full.html',
  },
  cdcIron: {
    label: 'CDC — Infant and toddler nutrition: iron',
    url: 'https://www.cdc.gov/infant-toddler-nutrition/vitamins-minerals/iron.html',
  },
  cdcChokingHazards: {
    label: 'CDC — Infant and toddler nutrition: choking hazards',
    url: 'https://www.cdc.gov/infant-toddler-nutrition/foods-and-drinks/choking-hazards.html',
  },
  cdcFoodsToAvoid: {
    label: 'CDC — Infant and toddler nutrition: foods and drinks to avoid or limit',
    url: 'https://www.cdc.gov/infant-toddler-nutrition/foods-and-drinks/foods-and-drinks-to-avoid-or-limit.html',
  },
  fdaFish: {
    label: 'FDA — Advice about eating fish (including for children)',
    url: 'https://www.fda.gov/food/consumers/advice-about-eating-fish',
  },
  fdaTeething: {
    label: 'U.S. FDA — Safely soothing teething pain in infants and children',
    url: 'https://www.fda.gov/consumers/consumer-updates/safely-soothing-teething-pain-infants-and-children',
  },
  asciaIntroSolids: {
    label: 'ASCIA — How to introduce solid foods to babies for allergy prevention',
    url: 'https://www.allergy.org.au/patients/allergy-prevention/ascia-how-to-introduce-solid-foods-to-babies',
  },
  asciaFoodAllergy: {
    label: 'ASCIA — Food allergy: fast facts',
    url: 'https://www.allergy.org.au/patients/fast-facts/food-allergy',
  },
  asciaFpies: {
    label: 'ASCIA — Food protein-induced enterocolitis syndrome (FPIES)',
    url: 'https://www.allergy.org.au/patients/food-other-adverse-reactions/food-protein-induced-enterocolitis-syndrome-fpies',
  },
  bsaciParents: {
    label: 'BSACI — Preventing food allergy in your baby: a summary for parents',
    url: 'https://www.bsaci.org/wp-content/uploads/2020/02/pdf_Infant-feeding-and-allergy-prevention-PARENTS-FINAL-booklet.pdf',
  },
  coulthardLumps2009: {
    label:
      "Coulthard, Harris & Emmett (2009) — Delayed introduction of lumpy foods affects child's food acceptance and feeding at 7 years, Maternal and Child Nutrition",
    url: 'https://research.birmingham.ac.uk/en/publications/delayed-introduction-of-lumpy-foods-to-children-during-the-comple',
  },
  fangupoBliss2016: {
    label:
      'Fangupo et al. (2016) — A baby-led approach to eating solids and risk of choking, Pediatrics (PubMed)',
    url: 'https://pubmed.ncbi.nlm.nih.gov/27647715/',
  },
  spillExposure2019: {
    label:
      'Spill et al. (2019) — Repeated exposure to food and food acceptability in infants and toddlers: a systematic review, Am J Clin Nutr (PubMed)',
    url: 'https://pubmed.ncbi.nlm.nih.gov/30982874/',
  },
} as const;

export const seedSolidsArticles: SeedArticle[] = [
  // ----- Bắt đầu (getting started) -----
  {
    id: 'art_solids_first_meals',
    reviewerLabel: NUTRITION,
    data: {
      library: 'solids',
      topic: 'feeding',
      subtopic: 'start',
      format: 'step_guide',
      ageWeeks: { from: 22, to: 39 },
      readingMinutes: 6,
      cover: null,
      title: t(
        'Những bữa ăn dặm đầu tiên: chuẩn bị gì?',
        "Your baby's first solid meals: what to prepare",
      ),
      summary: t(
        'Bé bắt đầu ăn dặm lúc 6 tháng. Chuẩn bị ghế, thìa, cốc, chọn món đầu tiên giàu sắt, nấu đúng độ đặc và đi qua bữa ăn đầu tiên từng bước, bình tĩnh và an toàn.',
        'Your baby starts solids at 6 months. Get the chair, spoons and cup ready, choose iron-rich first foods, cook them to the right thickness and go through the first meal step by step, calmly and safely.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Bé bắt đầu ăn dặm khi tròn 6 tháng và đã có đủ dấu hiệu sẵn sàng; bé vẫn bú mẹ hoặc bú sữa công thức như cũ. Chuẩn bị ghế ăn có đai, thìa nhỏ mềm và cốc tập uống. Món đầu tiên nên giàu sắt, nấu đặc đến mức không chảy khỏi thìa, không nêm muối, đường. Bữa đầu chỉ cần vài thìa: mục tiêu là làm quen, chưa phải ăn nhiều.',
          ),
          h('Hiểu đúng trước khi bắt đầu'),
          p(
            'WHO, Bộ Y tế (Hướng dẫn ăn bổ sung cho trẻ 6–23 tháng, 2026), UNICEF, NHS và AAP đều khuyên cho bé ăn dặm từ khoảng 6 tháng tuổi, khi sữa mẹ hoặc sữa công thức không còn đáp ứng đủ nhu cầu của bé, nhất là sắt.',
          ),
          p(
            'Child Life lấy mốc 6 tháng làm thời điểm bắt đầu. Không bao giờ cho ăn dặm trước 4 tháng. Nếu bác sĩ khuyên bé nhà mình bắt đầu sớm hơn vì lý do riêng, ví dụ bé sinh non hoặc có nguy cơ dị ứng cao, hãy làm theo bác sĩ của bé.',
          ),
          p(
            'Bé sẵn sàng khi có đủ ba dấu hiệu: ngồi được và giữ vững đầu cổ, tự cầm thức ăn đưa vào miệng, và nuốt được thay vì dùng lưỡi đẩy hết ra. Gặm tay, thức đêm nhiều hơn hay đòi bú thêm chưa phải là dấu hiệu sẵn sàng. Trong năm đầu, sữa vẫn là nguồn dinh dưỡng chính; WHO khuyên tiếp tục cho bú đến 2 tuổi hoặc lâu hơn.',
          ),
          h('Từng bước chuẩn bị và cho bé ăn bữa đầu'),
          ul(
            'Bước 1 · Chỗ ngồi: chọn ghế ăn chắc chắn, có đai an toàn gồm cả đai giữa hai chân. Bé ngồi thẳng, đối diện người lớn. Không cho ăn khi bé nằm, ngả trên xe đẩy, đang bò chơi hay ngồi trên xe máy.',
            'Bước 2 · Dụng cụ: thìa nhỏ, nông, mềm; bát nhỏ, tốt nhất có đế hút; cốc hở miệng hoặc cốc không van; yếm và một tấm lót dưới ghế. Rửa sạch bằng nước nóng và nước rửa bát, để khô ráo.',
            'Bước 3 · Chọn món: ưu tiên món giàu sắt như thịt bò, thịt lợn nạc, gà, cá, trứng nấu chín kỹ, đậu phụ, các loại đậu hoặc bột ngũ cốc tăng cường sắt. Xen với rau củ như bí đỏ, cà rốt, khoai lang, bông cải xanh, rau cải và trái cây mềm như chuối, bơ, đu đủ.',
            'Bước 4 · Nấu đúng độ đặc: cháo hoặc bột nấu đặc đến mức không chảy khỏi thìa (UNICEF); rau củ hấp mềm rồi nghiền; thịt, cá xay nhuyễn trộn vào cháo. Có thể thêm vài que rau củ hấp mềm dài cỡ ngón tay người lớn để bé tự cầm.',
            'Bước 5 · Không nêm: không thêm muối, nước mắm, hạt nêm, bột ngọt hay đường. Không dùng mật ong trước 12 tháng tuổi. Không pha bột vào bình sữa.',
            'Bước 6 · Chọn thời điểm: lúc bé tỉnh táo, vui vẻ, không quá đói hay quá mệt, và ba mẹ không vội. UNICEF gợi ý cho ăn sau cữ bú hoặc giữa hai cữ bú. Buổi sáng hoặc trưa giúp ba mẹ dễ theo dõi bé trong ngày.',
            'Bước 7 · Rửa tay: rửa tay người lớn và tay bé bằng xà phòng trước khi nấu và trước bữa ăn (UNICEF).',
            'Bước 8 · Bữa đầu tiên: thử để thức ăn chỉ còn ấm. Ngồi đối diện, nói chuyện với bé, cho bé nhìn và chạm thức ăn. Đưa thìa đến gần môi, đợi bé há miệng rồi mới cho một ít ở đầu thìa. UNICEF gợi ý bắt đầu 2–3 thìa nhỏ, ngày 2 lần, rồi tăng dần theo sức ăn của bé.',
            'Bước 9 · Theo tín hiệu của bé: bé há miệng, nghiêng người tới là muốn ăn; bé ngậm miệng, quay đi, đẩy thìa hoặc khóc là đã đủ. Dừng lại, không ép, không dỗ bằng điện thoại hay tivi.',
            'Bước 10 · Sau bữa: cho bé nhấp vài ngụm nước đun sôi để nguội bằng cốc. Bỏ phần bé đã ăn dở. Phần chưa dùng thì cất tủ lạnh trong vòng 1–2 giờ, dùng trong 2 ngày; riêng cơm, cháo cất trong vòng 1 giờ, dùng trong 24 giờ (NHS). Ghi món mới vào nhật ký ăn dặm.',
          ),
          tip(
            'Tuần đầu tiên thường diễn ra thế nào',
            'Vài ngày đầu một bữa nhỏ mỗi ngày là đủ, sau đó tăng lên hai bữa. Nhiều bé nhăn mặt, lè lưỡi, nhè ra: đó là phản xạ khi gặp vị và độ đặc mới, không có nghĩa là bé ghét món đó. NHS cho biết bé có thể cần được mời 10 lần trở lên mới quen một món. Cho từng món mới một giúp dễ nhận ra món gây phản ứng, nhưng không bắt buộc với rau, củ, quả. Trứng, đậu phộng dạng mịn, cá nên được đưa vào sớm trong những tuần đầu.',
          ),
          h('Theo dõi'),
          ul(
            'Bé hứng thú hay quay đi, ăn được khoảng bao nhiêu thìa mỗi bữa; con số này tăng dần qua các tuần.',
            'Phân thường đặc hơn, đổi màu và mùi khi bé ăn dặm; đó là bình thường. Để ý nếu phân cứng, bé rặn đau.',
            'Sau món mới: nổi mẩn, mề đay, sưng môi hoặc quanh mắt, nôn. Chụp ảnh, ngừng món đó và hỏi bác sĩ.',
            'Oẹ khi gặp thức ăn mới là bình thường: bé ồn ào, ho, đẩy thức ăn ra. Hóc thường im lặng và cần sơ cứu ngay theo mục Sơ cứu trẻ em › Hóc dị vật trong Child Life.',
            'Bé vẫn bú đủ: ăn dặm là bổ sung, chưa thay cữ bú trong những tháng đầu.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            'Bữa đầu phải ăn hết chén mới đủ chất → Bé đang học một kỹ năng mới, và sữa vẫn là nguồn dinh dưỡng chính → Vài thìa là đủ, tăng dần theo tín hiệu của bé.',
            'Bắt đầu bằng nước cháo, nước rau cho nhẹ bụng → Nước loãng chủ yếu là nước, ít năng lượng và gần như không có sắt → Cho bé ăn cháo, bột đặc vừa phải và cả phần cái.',
            'Nêm chút nước mắm cho bé chịu ăn → Thận của bé còn non và bé dễ quen vị mặn → Giữ vị tự nhiên; múc phần của bé ra trước khi nêm cho người lớn.',
            'Bé lè lưỡi đẩy ra là không hợp, bỏ hẳn món đó → Đó thường là phản xạ với vị mới → Mời lại món đó vào những ngày sau, lượng nhỏ, cạnh món bé đã quen.',
          ),
          urgent(
            'Gọi {emergency} ngay khi',
            'Sau khi ăn, bé khó thở, thở rít, sưng môi, mặt hoặc lưỡi, nôn nhiều lần, hoặc da tái, lả đi, mềm nhũn. Trong lúc chờ, xem mục Sơ cứu trẻ em trong Child Life.',
          ),
          doctor(
            'Khi nào nên hỏi bác sĩ',
            'Bé sinh non, nhẹ cân hoặc có bệnh cần chế độ ăn riêng; bé bị chàm nặng hoặc đã từng dị ứng một món (hỏi trước khi cho trứng, đậu phộng); bé hay ho sặc, nôn hoặc khó nuốt khi ăn; bé nổi mẩn, sưng môi hay nôn sau món mới.',
          ),
        ],
        en: [
          note(
            'In short',
            'Your baby starts solids at 6 months, once all the signs of readiness are there, and keeps breastfeeding or having formula as before. Get a high chair with a harness, small soft spoons and a cup ready. First foods should be iron-rich, cooked thick enough not to run off the spoon, with no salt or sugar. The first meal needs only a few spoonfuls: the goal is getting used to food, not eating a lot.',
          ),
          h('Understanding the start'),
          p(
            "WHO, Việt Nam's Ministry of Health (complementary feeding guidance for children 6–23 months, 2026), UNICEF, the NHS and the AAP all advise starting solids at around 6 months of age, when breast milk or formula no longer meets all of a baby's needs, especially for iron.",
          ),
          p(
            "Child Life uses 6 months as the time to start. Never start solids before 4 months. If your baby's doctor advises an earlier start for a particular reason, for example because your baby was born preterm or has a high risk of allergy, follow your baby's doctor.",
          ),
          p(
            'Your baby is ready when all three signs are there: they can sit and hold their head steady, pick up food and put it in their mouth, and swallow it instead of pushing it all back out with the tongue. Chewing fists, waking more at night or wanting extra feeds are not signs of readiness. Milk is still the main source of nutrition in the first year; WHO advises continuing breastfeeding to 2 years or beyond.',
          ),
          h('Step by step: preparing and giving the first meal'),
          ul(
            'Step 1 · Seat: choose a sturdy high chair with a harness, including the strap between the legs. Your baby sits upright, facing an adult. Never feed them lying down, reclining in a pushchair, crawling around or on a motorbike.',
            'Step 2 · Equipment: small, shallow, soft spoons; a small bowl, ideally with a suction base; an open or free-flow cup; a bib and a mat under the chair. Wash them in hot soapy water and let them dry.',
            'Step 3 · Choose the food: favor iron-rich foods such as beef, lean pork, chicken, fish, well-cooked egg, tofu, beans and lentils or iron-fortified baby cereal. Mix in vegetables such as pumpkin, carrot, sweet potato, broccoli and leafy greens, and soft fruit such as banana, avocado and papaya.',
            'Step 4 · Get the thickness right: cook rice porridge or cereal thick enough not to run off the spoon (UNICEF); steam vegetables until soft, then mash them; blend meat or fish finely and mix it into the porridge. You can add a few soft steamed vegetable sticks about the length of an adult finger for your baby to hold.',
            "Step 5 · Don't season: add no salt, fish sauce, stock powder, MSG or sugar. No honey before 12 months. Never put cereal in the bottle.",
            'Step 6 · Pick the moment: when your baby is alert and happy, not too hungry or tired, and you are not rushed. UNICEF suggests offering food after a breastfeed or between feeds. Morning or midday makes it easier to keep an eye on your baby through the day.',
            "Step 7 · Wash hands: wash your hands and your baby's hands with soap before preparing food and before the meal (UNICEF).",
            "Step 8 · The first meal: make sure the food is only warm. Sit facing your baby, talk to them and let them look at and touch the food. Bring the spoon near their lips and wait for them to open their mouth before offering a little on the tip. UNICEF suggests starting with 2–3 small spoonfuls twice a day, then increasing with your baby's appetite.",
            "Step 9 · Follow your baby's cues: an open mouth and leaning forward mean they want more; a closed mouth, turning away, pushing the spoon or crying mean they have had enough. Stop, never force, and don't coax with a phone or TV.",
            'Step 10 · After the meal: offer a few sips of boiled and cooled water from the cup. Throw away anything your baby has partly eaten. Refrigerate any untouched leftovers within 1–2 hours and use them within 2 days; rice and porridge go in the fridge within 1 hour and are used within 24 hours (NHS). Log the new food in the solids diary.',
          ),
          tip(
            'What the first week usually looks like',
            'For the first few days one small meal a day is enough, then move to two. Many babies grimace, push their tongue out or spit food back: this is a reflex to new tastes and textures, not a sign they dislike the food. The NHS says a baby may need to be offered a food 10 or more times before accepting it. Giving one new food at a time makes it easier to spot a food that causes a reaction, but it is optional for vegetables and fruit. Egg, smooth peanut and fish are best introduced early, in the first weeks.',
          ),
          h('What to watch'),
          ul(
            'Whether your baby is interested or turns away, and roughly how many spoonfuls they take at each meal; this grows over the weeks.',
            'Stools often get firmer and change color and smell with solids; that is normal. Watch for hard stools or painful straining.',
            'After a new food: rash, hives, swelling of the lips or around the eyes, vomiting. Take a photo, stop that food and ask the doctor.',
            'Gagging on new foods is normal: babies are noisy, cough and push food out. Choking is usually silent and needs first aid right away, following the Choking steps in the Sơ cứu trẻ em (First aid) guide in Child Life.',
            'Your baby still feeds well: solids are an addition and do not replace milk feeds in the first months.',
          ),
          h('Common myths'),
          ul(
            'The first meal has to be a full bowl to be nourishing → Your baby is learning a new skill, and milk is still the main source of nutrition → A few spoonfuls are enough; increase as your baby shows they want more.',
            'Start with rice water or vegetable water because it is gentle on the tummy → Thin liquids are mostly water, with little energy and almost no iron → Give reasonably thick porridge or cereal, with the solid ingredients.',
            "A little fish sauce will make the baby eat → Your baby's kidneys are still immature and they get used to salty tastes easily → Keep natural flavors; take your baby's portion out before seasoning for the adults.",
            'If the baby pushes food out with the tongue it does not suit them, so drop it → This is usually a reflex to a new taste → Offer it again on later days, in small amounts, next to foods your baby already knows.',
          ),
          urgent(
            'Call {emergency} now if',
            'After eating, your baby has trouble breathing, noisy breathing, swelling of the lips, face or tongue, repeated vomiting, or turns pale, limp or floppy. While you wait, see the Sơ cứu trẻ em (First aid) guide in Child Life.',
          ),
          doctor(
            'When to ask a doctor',
            'Your baby was born preterm, has low weight or a condition that needs a special diet; has severe eczema or a previous food allergy (ask before giving egg or peanut); often coughs, chokes, vomits or struggles to swallow when eating; or gets a rash, swollen lips or vomiting after a new food.',
          ),
        ],
      },
      keywords: t(
        [
          'ăn dặm',
          'bữa ăn dặm đầu tiên',
          '6 tháng',
          'chuẩn bị ăn dặm',
          'ghế ăn dặm',
          'thìa ăn dặm',
          'món đầu tiên',
          'thức ăn giàu sắt',
          'cháo',
          'độ đặc',
        ],
        [
          'starting solids',
          'first solid meal',
          '6 months',
          'getting ready for solids',
          'high chair',
          'weaning spoon',
          'first foods',
          'iron-rich foods',
          'rice porridge',
          'thickness',
        ],
      ),
      relatedArticleIds: [
        'art_solids_readiness',
        'art_solids_gear',
        'art_solids_iron_foods',
        'art_solids_choking_safety',
      ],
      milestoneIds: [],
      sources: [
        S.whoIycf,
        S.mohCf2026,
        S.unicef6to12,
        S.nhsHowToStart,
        S.nhsFirstSolids,
        S.hcStartingSolids,
        S.nhsStoringReheating,
        S.whoCf2023,
      ],
    },
  },
  {
    id: 'art_solids_methods',
    reviewerLabel: NUTRITION,
    data: {
      library: 'solids',
      topic: 'feeding',
      subtopic: 'methods',
      format: 'article',
      ageWeeks: { from: 22, to: 52 },
      readingMinutes: 6,
      cover: null,
      title: t(
        'Ăn dặm truyền thống, BLW hay kết hợp: chọn cách nào?',
        'Traditional spoon-feeding, baby-led weaning or a mix: which to choose?',
      ),
      summary: t(
        'Đút thìa, để bé tự ăn (BLW) hay kết hợp đều có thể giúp bé ăn tốt. Ưu, nhược điểm của từng cách, những điều kiện an toàn chung và cách chọn cách hợp với gia đình mình.',
        'Spoon-feeding, baby-led weaning (BLW) or a mix can all help your baby eat well. The pros and cons of each, the safety basics they share and how to choose what suits your family.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Không có cách đúng duy nhất. Đút thìa kiểu truyền thống (kể cả kiểu Nhật), BLW (bé tự cầm thức ăn) hay kết hợp đều ổn nếu bé bắt đầu lúc 6 tháng, thức ăn mềm và cắt đúng cỡ, bữa nào cũng có món giàu sắt, không nêm muối, đường, độ thô tăng dần và bé được ăn theo tín hiệu đói no. Nhiều gia đình Việt chọn kết hợp: đút cháo, bột kèm vài miếng mềm để bé tự cầm.',
          ),
          h('Hiểu đúng về ba cách ăn dặm'),
          p(
            'Ăn dặm truyền thống: người lớn đút thìa, bắt đầu bằng bột hoặc cháo nghiền mịn rồi tăng dần độ thô. Ưu điểm là dễ biết bé ăn được bao nhiêu, dễ trộn thịt, cá, trứng giàu sắt vào cháo, và quen thuộc với ông bà. Điểm cần chú ý là dễ đút quá tay, dễ giữ đồ xay nhuyễn quá lâu, và dễ thành ép ăn khi người lớn sốt ruột.',
          ),
          p(
            'Ăn dặm kiểu Nhật là một biến thể của đút thìa: nấu từng món riêng để bé nếm vị tự nhiên, tăng độ thô theo từng giai đoạn và cho bé ngồi ăn cùng người lớn. Những ý này rất tốt, nhưng ba mẹ không cần cân đo cầu kỳ hay theo đúng bảng tỉ lệ gạo nước; điều quan trọng vẫn là đủ món giàu sắt và tăng độ thô kịp lúc.',
          ),
          p(
            'BLW (baby-led weaning, ăn dặm bé chỉ huy): ngay từ đầu bé tự cầm những que thức ăn mềm, ăn cùng gia đình, người lớn không đút. Ưu điểm là bé chủ động, luyện tay, nhai và tự nhận biết khi no. Điểm cần chú ý là những tuần đầu bé ăn được ít và rơi vãi nhiều; nếu chỉ cho rau củ, trái cây, bé dễ thiếu món giàu sắt và giàu năng lượng.',
          ),
          p(
            'Về an toàn, nghiên cứu BLISS ở New Zealand (Fangupo và cộng sự, 2016, 206 trẻ) theo dõi một kiểu BLW có điều chỉnh: thức ăn mềm, cỡ dễ cầm, mỗi bữa có món giàu sắt và món giàu năng lượng. Trẻ nhóm này không bị hóc nhiều hơn nhóm ăn theo cách thông thường.',
          ),
          p(
            'Tuy vậy, ở cả hai nhóm khoảng một phần ba trẻ từng bị hóc ít nhất một lần trong giai đoạn 6–8 tháng, và nhiều trẻ vẫn được cho món dễ gây hóc. Nghĩa là cách sơ chế và việc người lớn ngồi cạnh quan trọng hơn tên phương pháp. NHS cũng khẳng định không có cách đúng hay sai và có thể kết hợp.',
          ),
          h('Chọn cách nào cho gia đình mình'),
          ul(
            'Ai thường cho bé ăn: ba mẹ, ông bà hay người giúp việc? Cách được chọn cần là cách mà người cho ăn hằng ngày làm được và đồng ý.',
            'Bé đã ngồi vững, tự cầm và đưa thức ăn vào miệng tốt chưa? BLW cần những kỹ năng này; nếu bé chưa làm được, đút thìa trước rồi thêm thức ăn cầm tay sau.',
            'Gia đình có thời gian ngồi ăn cùng bé và chấp nhận bừa bộn không?',
            'Bé sinh non, có khó khăn khi nhai nuốt hoặc tăng cân chưa tốt: hỏi bác sĩ trước khi chọn cách.',
          ),
          h('Ba mẹ có thể làm gì'),
          ul(
            'Dù chọn cách nào: bé ngồi thẳng trên ghế có đai, người lớn ngồi cạnh và nhìn bé suốt bữa ăn.',
            'Mỗi bữa có một món giàu sắt như thịt, cá, trứng, đậu phụ, các loại đậu, và thêm một ít dầu ăn hoặc mỡ để tăng năng lượng (UNICEF).',
            'Với thức ăn cầm tay: que mềm dài cỡ ngón tay người lớn, bóp nát dễ dàng giữa ngón cái và ngón trỏ; tránh món tròn, cứng, dai.',
            'Với đút thìa: đợi bé há miệng rồi mới đưa thìa, để bé tự ngậm lấy thức ăn; cho bé cầm một chiếc thìa riêng để tập.',
            'Tăng độ thô từng bước: nghiền mịn, nghiền lợn cợn, băm nhỏ, rồi cắt nhỏ. Một nghiên cứu ở Anh (Coulthard và cộng sự, 2009) thấy trẻ làm quen thức ăn lợn cợn sau 9 tháng về sau hay gặp khó khăn khi ăn hơn.',
            'Kết hợp: bắt đầu bữa bằng vài miếng mềm bé tự cầm rồi đút cháo, hoặc bữa sáng đút thìa, bữa trưa cho bé tự ăn cùng cả nhà.',
            'Thống nhất với ông bà và người trông bé: cùng quy tắc an toàn, không ép, không nêm.',
            'Trải tấm lót dưới ghế, dùng yếm có máng hứng; bừa bộn là một phần của việc học ăn.',
          ),
          tip(
            'Lo bé tự ăn được quá ít?',
            'Những tuần đầu bé ăn ít là bình thường, vì sữa vẫn là nguồn dinh dưỡng chính. Theo dõi cân nặng ở các lần khám thay vì đếm từng miếng. Nếu ba mẹ vẫn lo, có thể thêm vài thìa cháo giàu sắt sau phần bé tự ăn.',
          ),
          h('Theo dõi'),
          ul(
            'Mỗi ngày bé có ăn được món giàu sắt không, nhất là khi bé tự ăn.',
            'Oẹ khi gặp miếng mới là bình thường và giảm dần; hóc thì im lặng, bé không ho, không khóc được và cần sơ cứu ngay.',
            'Bé có tiến bộ về độ thô và kỹ năng cầm nắm qua từng tháng không.',
            'Cân nặng và chiều dài theo biểu đồ tăng trưởng ở các lần khám định kỳ.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            'BLW làm bé dễ hóc hơn → Nghiên cứu BLISS không thấy trẻ ăn BLW có điều chỉnh bị hóc nhiều hơn; nguy cơ đến từ món cứng, tròn và việc không có người lớn ngồi cạnh → Sơ chế đúng và luôn ngồi cạnh bé, dù đút thìa hay để bé tự ăn.',
            'Đút thìa là lạc hậu → Đút thìa theo tín hiệu của bé vẫn là cách tốt; điều cần tránh là ép ăn, đút khi bé đã quay đi → Đợi bé há miệng, dừng khi bé no.',
            'Ăn kiểu Nhật phải theo đúng tỉ lệ gạo nước từng giai đoạn → Đó chỉ là khung tham khảo; mỗi bé một nhịp → Chỉ cần cháo đặc không chảy khỏi thìa và tăng độ thô theo khả năng của bé.',
            'Bé chưa có răng thì chưa tự cầm ăn được → Bé nghiền thức ăn mềm bằng lợi rất tốt → Cho que mềm, bóp nát được bằng hai ngón tay.',
          ),
          urgent(
            'Gọi {emergency} ngay khi',
            'Bé hóc mà không ho, không khóc được, khó thở, tím tái, sưng môi, mặt hoặc lưỡi, hoặc lả đi sau khi ăn. Trong lúc chờ, làm theo mục Sơ cứu trẻ em › Hóc dị vật trong Child Life.',
          ),
          doctor(
            'Khi nào nên hỏi bác sĩ',
            'Bé sinh non, có khó khăn về vận động hoặc nhai nuốt; bé đã 7 tháng mà vẫn chưa ngồi được dù có đỡ; bé tăng cân chưa tốt; bé hay ho sặc, nôn khi ăn; bé nổi mẩn, sưng môi sau món mới.',
          ),
        ],
        en: [
          note(
            'In short',
            'There is no single right way. Traditional spoon-feeding (including the Japanese style), BLW (your baby feeds themselves) or a mix all work if your baby starts at 6 months, food is soft and cut to the right size, every meal has an iron-rich food, nothing is salted or sweetened, texture increases step by step and your baby is fed according to their hunger and fullness cues. Many Vietnamese families mix the two: spoon-feeding porridge or cereal with a few soft pieces for the baby to hold.',
          ),
          h('Understanding the three approaches'),
          p(
            'Traditional weaning: an adult spoon-feeds, starting with smooth cereal or porridge and gradually increasing texture. It makes it easy to see how much your baby eats and to mix iron-rich meat, fish and egg into porridge, and grandparents know it well. The things to watch are overfeeding, keeping food puréed for too long, and sliding into forcing food when adults get anxious.',
          ),
          p(
            "Japanese-style weaning is a variant of spoon-feeding: each food is cooked separately so your baby tastes its natural flavor, texture increases in stages and your baby sits and eats with the adults. These ideas are good, but you don't need to weigh everything or follow an exact rice-to-water chart; what still matters is enough iron-rich food and moving on to thicker textures in time.",
          ),
          p(
            'BLW (baby-led weaning): from the start your baby holds soft sticks of food and eats with the family, without being spoon-fed. Its strengths are that babies take the lead, practice using their hands and chewing, and learn to recognize when they are full. The things to watch are that babies eat little and drop a lot in the first weeks, and that if they are offered only vegetables and fruit they can miss out on iron-rich and energy-rich foods.',
          ),
          p(
            'On safety, the BLISS study in New Zealand (Fangupo and colleagues, 2016, 206 babies) followed a modified form of BLW: soft food, sized to hold, with an iron-rich and an energy-rich food at every meal. These babies did not choke more often than babies fed the usual way.',
          ),
          p(
            'Even so, in both groups about one in three babies choked at least once between 6 and 8 months, and many were still offered foods that pose a choking risk. In other words, how food is prepared and an adult sitting alongside matter more than the name of the method. The NHS also says there is no right or wrong way and the approaches can be combined.',
          ),
          h('Choosing what suits your family'),
          ul(
            'Who usually feeds your baby: parents, grandparents or a helper? The approach needs to be one the everyday feeder can manage and agrees with.',
            'Can your baby sit steadily, pick up food and get it into their mouth? BLW needs these skills; if your baby is not there yet, start with the spoon and add finger foods later.',
            'Does your family have time to sit and eat with your baby, and can you live with the mess?',
            'Your baby was born preterm, has trouble chewing or swallowing, or is not gaining weight well: ask the doctor before choosing.',
          ),
          h('What you can do'),
          ul(
            'Whatever you choose: your baby sits upright in a chair with a harness, and an adult sits alongside and watches them for the whole meal.',
            'Every meal includes an iron-rich food such as meat, fish, egg, tofu, beans or lentils, plus a little cooking oil or fat for energy (UNICEF).',
            'For finger foods: soft sticks about the length of an adult finger that squash easily between thumb and forefinger; avoid round, hard or chewy foods.',
            'For spoon-feeding: wait for your baby to open their mouth before offering the spoon, and let them take the food off it themselves; give them their own spoon to practice with.',
            'Increase texture step by step: smooth mash, lumpy mash, minced, then chopped. A UK study (Coulthard and colleagues, 2009) found that children who met lumpy foods after 9 months had more feeding difficulties later on.',
            'Mixing: start the meal with a few soft pieces your baby holds, then spoon-feed porridge; or spoon-feed at breakfast and let your baby feed themselves at lunch with the family.',
            'Agree on the approach with grandparents and carers: the same safety rules, no forcing, no seasoning.',
            'Put a mat under the chair and use a bib with a catch tray; mess is part of learning to eat.',
          ),
          tip(
            'Worried your baby eats too little on their own?',
            'Eating little in the first weeks is normal, because milk is still the main source of nutrition. Follow weight at checkups rather than counting every piece. If you are still worried, offer a few spoonfuls of iron-rich porridge after your baby has fed themselves.',
          ),
          h('What to watch'),
          ul(
            'Whether your baby eats an iron-rich food every day, especially when feeding themselves.',
            'Gagging on new pieces is normal and eases over time; choking is silent, your baby cannot cough or cry, and needs first aid right away.',
            'Whether your baby makes progress with textures and grasping from month to month.',
            'Weight and length on the growth chart at routine checkups.',
          ),
          h('Common myths'),
          ul(
            'BLW makes babies choke more → The BLISS study found no more choking with modified BLW; the risk comes from hard, round foods and no adult sitting alongside → Prepare food correctly and always sit with your baby, whether spoon-feeding or self-feeding.',
            "Spoon-feeding is old-fashioned → Spoon-feeding that follows your baby's cues is still a good way; what to avoid is forcing food or feeding a baby who has turned away → Wait for an open mouth and stop when your baby is full.",
            "Japanese-style weaning means following the exact rice-to-water ratio for each stage → That is only a rough guide; every baby has their own pace → All you need is porridge thick enough not to run off the spoon and textures that grow with your baby's skills.",
            'Babies without teeth cannot feed themselves → Babies mash soft food with their gums very well → Offer soft sticks that squash between two fingers.',
          ),
          urgent(
            'Call {emergency} now if',
            'Your baby is choking and cannot cough or cry, has trouble breathing, turns blue, has swelling of the lips, face or tongue, or goes limp after eating. While you wait, follow the Choking steps in the Sơ cứu trẻ em (First aid) guide in Child Life.',
          ),
          doctor(
            'When to ask a doctor',
            'Your baby was born preterm or has difficulties with movement, chewing or swallowing; is 7 months old and still cannot sit even with support; is not gaining weight well; often coughs, chokes or vomits when eating; or gets a rash or swollen lips after a new food.',
          ),
        ],
      },
      keywords: t(
        [
          'BLW',
          'ăn dặm bé chỉ huy',
          'ăn dặm truyền thống',
          'ăn dặm kiểu Nhật',
          'đút thìa',
          'ăn dặm kết hợp',
          'thức ăn cầm tay',
          'phương pháp ăn dặm',
          'hóc',
          'oẹ',
        ],
        [
          'BLW',
          'baby-led weaning',
          'traditional weaning',
          'Japanese-style weaning',
          'spoon-feeding',
          'combined approach',
          'finger foods',
          'weaning methods',
          'choking',
          'gagging',
        ],
      ),
      relatedArticleIds: [
        'art_solids_first_meals',
        'art_solids_finger_foods',
        'art_solids_choking_safety',
        'art_solids_vn_porridge',
      ],
      milestoneIds: [],
      sources: [
        S.nhsFirstSolids,
        S.nhsHowToStart,
        S.nhsChokingGagging,
        S.fangupoBliss2016,
        S.hcStartingSolids,
        S.unicef6to12,
        S.whoCf2023,
        S.coulthardLumps2009,
      ],
    },
  },
  {
    id: 'art_solids_vn_porridge',
    reviewerLabel: NUTRITION,
    data: {
      library: 'solids',
      topic: 'feeding',
      subtopic: 'textures',
      format: 'article',
      ageWeeks: { from: 22, to: 78 },
      readingMinutes: 5,
      cover: null,
      title: t(
        'Bột, cháo rây hay cháo đặc: ăn dặm kiểu Việt cho đúng',
        'Baby cereal, sieved porridge or thick congee: Vietnamese-style weaning done right',
      ),
      summary: t(
        'Bột và cháo là món ăn dặm quen thuộc của gia đình Việt. Cách nấu đủ đặc, thêm thịt cá, rau và chút dầu mỡ, tăng độ thô theo tháng và tránh những thói quen làm bát cháo kém dinh dưỡng.',
        'Baby cereal and rice porridge are familiar first foods in Vietnamese homes. How to cook them thick enough, add meat or fish, vegetables and a little fat, increase texture by month and avoid habits that make porridge less nourishing.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Bột và cháo là nền tốt cho ăn dặm nếu nấu đặc đến mức không chảy khỏi thìa và có đủ bốn phần: tinh bột, chất đạm (thịt, cá, trứng, đậu phụ), rau củ và một ít dầu hoặc mỡ. Bắt đầu lúc 6 tháng với bột hoặc cháo rây, nghiền mịn, rồi chuyển dần sang cháo nhừ, cháo đặc, cơm nát theo khả năng của bé. Không nêm muối, nước mắm, đường; không chỉ cho bé ăn nước cháo, nước hầm.',
          ),
          h('Hiểu đúng về bột và cháo'),
          p(
            'Gạo cho năng lượng, nhưng một bát cháo trắng loãng chủ yếu là nước, ít năng lượng, ít đạm và gần như không có sắt. Dạ dày của bé 6–23 tháng còn nhỏ, nên UNICEF nhấn mạnh mỗi thìa ăn đều cần giàu dinh dưỡng: cháo quá loãng có ít chất bổ, hãy nấu đặc đến mức không chảy khỏi thìa.',
          ),
          p(
            'Bộ Y tế đã ban hành Hướng dẫn ăn bổ sung cho trẻ 6–23 tháng (2026), dựa trên khuyến nghị của WHO và UNICEF và phù hợp với bữa ăn của gia đình Việt.',
          ),
          p(
            'Bột (bột gạo tự xay nấu chín, hoặc bột ngũ cốc ăn dặm) và cháo rây (cháo nấu nhừ rồi rây qua lưới) là hai cách làm mịn cho những tuần đầu. Bột ngũ cốc có tăng cường sắt là lựa chọn tiện; hãy đọc nhãn và chọn loại không thêm đường, muối. Dù là bột hay cháo, cách nghĩ quen thuộc “bát bột đủ bốn nhóm” vẫn đúng: tinh bột, chất đạm, chất béo, rau quả.',
          ),
          p(
            'Mục tiêu không phải là ăn mãi đồ mịn. Từ 6 đến 12 tháng, bé cần đi từ nghiền mịn sang lợn cợn, băm nhỏ rồi cắt nhỏ, để học nhai và làm quen với nhiều kết cấu. Từ 12 tháng, phần lớn bé có thể ăn cơm mềm cùng gia đình.',
          ),
          h('Nấu một bát bột, cháo đủ chất'),
          ul(
            'Tinh bột: gạo tẻ hoặc bột ngũ cốc; thỉnh thoảng thay bằng khoai lang, khoai tây, bí đỏ, yến mạch hay mì sợi nấu mềm để bé quen nhiều vị.',
            'Chất đạm, giàu sắt: thịt bò, thịt lợn nạc, thịt gà, cá đã gỡ hết xương, tôm, cua, trứng nấu chín kỹ, đậu phụ, đậu xanh, đậu đỏ. Xay hoặc băm nhuyễn rồi nấu chín cùng cháo. Gan giàu sắt và vitamin A, chỉ cần lượng nhỏ và không cần ăn hằng ngày.',
            'Rau củ: bí đỏ, cà rốt, rau ngót, rau cải, mồng tơi, bông cải xanh; băm nhỏ hoặc nghiền, cho vào lúc cháo gần chín. Trái cây nghiền như chuối, đu đủ, xoài, bơ cho sau bữa hoặc làm bữa phụ.',
            'Chất béo: thêm một ít dầu ăn hoặc mỡ vào bát cháo của bé để tăng năng lượng (UNICEF); không cần dầu mỡ đắt tiền.',
            'Không nêm muối, nước mắm, hạt nêm, bột ngọt, đường. Nước dùng tự nấu từ thịt, xương, rau không nêm thì dùng được, nhưng phải cho bé ăn cả phần cái.',
            'Nấu một nồi cho nhiều bữa thì chia phần, làm nguội nhanh và cất tủ lạnh trong vòng 1 giờ vì là cơm, cháo; dùng trong 24 giờ hoặc trữ đông, hâm nóng một lần duy nhất (NHS).',
          ),
          h('Tăng độ thô theo khả năng của bé'),
          ul(
            '6 tháng: bột hoặc cháo rây, xay mịn, nấu đặc; thịt, cá xay nhuyễn trộn vào. Có thể cho thêm vài que rau củ hấp mềm để bé tự cầm.',
            '7–8 tháng: cháo nấu nhừ không rây, hạt gạo vỡ; thịt cá băm nhỏ; rau thái nhỏ; bắt đầu có miếng lợn cợn mềm.',
            '9–11 tháng: cháo đặc hạt nguyên hoặc cơm nát nấu mềm; thịt cá băm hoặc cắt nhỏ; thêm thức ăn cầm tay trong mỗi bữa.',
            'Từ 12 tháng: cơm mềm và món của gia đình cắt nhỏ; múc phần của bé ra trước khi nêm.',
          ),
          tip(
            'Thử độ đặc bằng chiếc thìa',
            'Múc một thìa cháo rồi nghiêng thìa: nếu cháo chảy tuột ra như nước là quá loãng; nếu cháo bám lại trên thìa và chỉ trôi chậm là vừa. Bé mới tập có thể cần mịn hơn một chút, nhưng đừng pha loãng để bé “dễ nuốt”.',
          ),
          h('Theo dõi'),
          ul(
            'Mỗi ngày bé có thịt, cá, trứng hoặc đậu không; WHO coi bữa ăn trong ngày là đa dạng khi bé có ít nhất 5 trong 8 nhóm thực phẩm.',
            'Bé xử lý độ thô mới thế nào: oẹ nhẹ là bình thường, nhưng nôn hay sặc thường xuyên cần hỏi bác sĩ.',
            'Phân bé: cháo nhiều bột, ít rau và uống ít nước dễ làm phân cứng.',
            'Cân nặng, chiều dài ở các lần khám; một bữa ăn ít không đáng lo nếu bé vẫn chơi tốt.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            'Nước cháo, nước hầm xương là phần bổ nhất → Nước hầm chủ yếu là nước và một ít chất béo; đạm và sắt phần lớn ở lại trong thịt, cá → Băm nhỏ để bé ăn cả cái.',
            'Phải rây cháo đến 1 tuổi vì bé chưa có răng → Bé nghiền thức ăn mềm bằng lợi, và làm quen đồ lợn cợn quá muộn dễ khiến bé khó ăn về sau → Chuyển sang cháo nhừ không rây từ khoảng 7–8 tháng.',
            'Cháo ăn liền hay cháo nấu sẵn của người lớn tiện cho bé → Các loại này thường đã nêm muối, gia vị → Nấu riêng không nêm, hoặc chọn sản phẩm ăn dặm ghi rõ không thêm muối, đường.',
            'Nấu một nồi cháo buổi sáng, để trên bếp ăn cả ngày → Cơm, cháo để lâu ở nhiệt độ phòng có thể sinh độc tố mà đun lại cũng không hết → Làm nguội nhanh, cất tủ lạnh, mỗi lần chỉ hâm đủ một bữa.',
          ),
          urgent(
            'Gọi {emergency} ngay khi',
            'Sau khi ăn, bé khó thở, sưng môi, mặt hoặc lưỡi, nôn nhiều lần, hoặc da tái, lả đi, mềm nhũn.',
          ),
          doctor(
            'Khi nào nên hỏi bác sĩ',
            'Bé hay sặc, nôn khi tăng độ thô; bé đã quá 9 tháng mà vẫn chỉ ăn được đồ xay mịn; bé tăng cân chưa tốt; bé táo bón kéo dài; gia đình ăn chay hoặc bé phải kiêng nhiều món; bé nổi mẩn, sưng môi sau khi ăn một món mới.',
          ),
        ],
        en: [
          note(
            'In short',
            "Baby cereal and rice porridge are a good base for solids if they are cooked thick enough not to run off the spoon and contain all four parts: starch, protein (meat, fish, egg, tofu), vegetables and a little oil or fat. Start at 6 months with smooth cereal or sieved, mashed porridge, then move on to soft-cooked porridge, thick porridge and soft rice as your baby can manage. Add no salt, fish sauce or sugar, and don't feed your baby only the porridge water or broth.",
          ),
          h('Understanding cereal and porridge'),
          p(
            "Rice gives energy, but a bowl of thin plain porridge is mostly water, with little energy, little protein and almost no iron. A baby's stomach at 6–23 months is small, so UNICEF stresses that every spoonful should be nutritious: porridge that is too watery has fewer nutrients, so cook it thick enough not to run off the spoon.",
          ),
          p(
            "Việt Nam's Ministry of Health issued its complementary feeding guidance for children 6–23 months (2026), based on WHO and UNICEF recommendations and suited to Vietnamese family meals.",
          ),
          p(
            'Cereal (home-ground rice flour cooked through, or baby cereal) and sieved porridge (porridge cooked very soft, then pushed through a sieve) are two ways to make food smooth for the first weeks. Iron-fortified baby cereal is a convenient choice; read the label and pick one without added sugar or salt. Whether cereal or porridge, the familiar idea of "a bowl with all four groups" still holds: starch, protein, fat, and vegetables and fruit.',
          ),
          p(
            'The goal is not smooth food forever. Between 6 and 12 months, your baby needs to move from smooth to lumpy, minced and then chopped food, to learn to chew and get used to many textures. From 12 months, most babies can eat soft rice with the family.',
          ),
          h('Cooking a nourishing bowl of cereal or porridge'),
          ul(
            'Starch: plain rice or baby cereal; now and then swap in sweet potato, potato, pumpkin, oats or soft-cooked noodles so your baby gets used to many flavors.',
            'Protein, rich in iron: beef, lean pork, chicken, fish with every bone removed, shrimp, crab, well-cooked egg, tofu, mung beans, red beans. Blend or mince finely, then cook it through in the porridge. Liver is rich in iron and vitamin A; only a small amount is needed, and not every day.',
            'Vegetables: pumpkin, carrot, katuk (rau ngót), leafy greens, Malabar spinach, broccoli; mince or mash them and add them when the porridge is nearly done. Mashed fruit such as banana, papaya, mango or avocado can follow the meal or be a snack.',
            "Fat: add a little cooking oil or fat to your baby's porridge for energy (UNICEF); it doesn't need to be an expensive oil.",
            'Add no salt, fish sauce, stock powder, MSG or sugar. Unseasoned homemade stock from meat, bones or vegetables is fine, but your baby must eat the solid ingredients too.',
            'If you cook a pot for several meals, portion it, cool it quickly and refrigerate it within 1 hour because it is rice; use it within 24 hours or freeze it, and reheat it only once (NHS).',
          ),
          h('Increasing texture as your baby can manage'),
          ul(
            '6 months: smooth cereal or sieved porridge, blended and cooked thick; finely blended meat or fish mixed in. You can add a few soft steamed vegetable sticks for your baby to hold.',
            '7–8 months: soft-cooked porridge without sieving, with broken rice grains; minced meat and fish; finely chopped vegetables; soft lumps start to appear.',
            '9–11 months: thick porridge with whole grains or soft-cooked rice; minced or finely chopped meat and fish; finger foods at every meal.',
            "From 12 months: soft rice and family dishes cut small; take your baby's portion out before seasoning.",
          ),
          tip(
            'Test the thickness with a spoon',
            'Scoop up some porridge and tilt the spoon: if it runs off like water, it is too thin; if it clings to the spoon and slides off only slowly, it is right. A baby who is just starting may need it a little smoother, but don\'t thin it down to make it "easier to swallow".',
          ),
          h('What to watch'),
          ul(
            "Whether your baby has meat, fish, egg or beans every day; WHO counts a day's diet as varied when a baby eats from at least 5 of 8 food groups.",
            "How your baby copes with each new texture: mild gagging is normal, but frequent vomiting or choking needs a doctor's advice.",
            "Your baby's stools: porridge heavy on starch, light on vegetables, with little to drink, easily leads to hard stools.",
            'Weight and length at checkups; one small meal is not a worry if your baby is still playing well.',
          ),
          h('Common myths'),
          ul(
            'The porridge water and bone broth are the most nourishing part → Broth is mostly water with a little fat; most of the protein and iron stay in the meat and fish → Mince them so your baby eats the solid ingredients.',
            'Porridge must be sieved until 1 year because the baby has no teeth → Babies mash soft food with their gums, and meeting lumpy food too late can make eating harder later → Move to soft, unsieved porridge from around 7–8 months.',
            "Instant porridge or ready-made adult porridge is convenient for babies → These are usually already seasoned with salt and flavorings → Cook your baby's portion without seasoning, or choose baby products clearly labeled with no added salt or sugar.",
            'Cooking a pot of porridge in the morning and leaving it on the stove all day → Rice and porridge left at room temperature can form toxins that reheating does not remove → Cool it quickly, refrigerate it and reheat only one meal at a time.',
          ),
          urgent(
            'Call {emergency} now if',
            'After eating, your baby has trouble breathing, swelling of the lips, face or tongue, repeated vomiting, or turns pale, limp or floppy.',
          ),
          doctor(
            'When to ask a doctor',
            'Your baby often chokes or vomits as texture increases; is past 9 months and still manages only smooth food; is not gaining weight well; has ongoing constipation; your family is vegetarian or your baby has to avoid many foods; or your baby gets a rash or swollen lips after a new food.',
          ),
        ],
      },
      keywords: t(
        [
          'cháo',
          'bột ăn dặm',
          'cháo rây',
          'cháo đặc',
          'cháo hạt vỡ',
          'cơm nát',
          'độ đặc',
          'nước hầm xương',
          'dầu ăn',
          'bốn nhóm thực phẩm',
          'ăn dặm kiểu Việt',
        ],
        [
          'rice porridge',
          'baby cereal',
          'sieved porridge',
          'thick porridge',
          'broken-rice porridge',
          'soft rice',
          'thickness',
          'bone broth',
          'cooking oil',
          'four food groups',
          'Vietnamese weaning',
        ],
      ),
      relatedArticleIds: [
        'art_solids_textures_by_month',
        'art_solids_iron_foods',
        'art_solids_methods',
        'art_solids_prep_storage',
      ],
      milestoneIds: [],
      sources: [
        S.mohCf2026,
        S.unicef6to12,
        S.whoIycf,
        S.whoCf2023,
        S.whoDietaryDiversity,
        S.nhsFrom6Months,
        S.coulthardLumps2009,
        S.nhsStoringReheating,
      ],
    },
  },
  // ----- Dinh dưỡng (nutrition) -----
  {
    id: 'art_solids_iron_foods',
    reviewerLabel: NUTRITION,
    data: {
      library: 'solids',
      topic: 'feeding',
      subtopic: 'nutrition',
      format: 'article',
      ageWeeks: { from: 22, to: 104 },
      readingMinutes: 5,
      cover: null,
      title: t('Món giàu sắt cho bé từ 6 tháng', 'Iron-rich foods for babies from 6 months'),
      summary: t(
        'Từ 6 tháng, nhu cầu sắt của bé tăng mà sữa không còn đáp ứng đủ. Những thực phẩm giàu sắt dễ tìm ở chợ Việt, cách nấu cho bé và mẹo giúp cơ thể hấp thu sắt tốt hơn.',
        'From 6 months, your baby needs more iron than milk alone can provide. Iron-rich foods that are easy to find at a Vietnamese market, how to cook them for your baby, and tips to help the body absorb more iron.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Sắt giúp tạo máu và phát triển não. Lượng sắt bé dự trữ từ lúc sinh giảm dần, nên từ 6 tháng mỗi bữa ăn dặm nên có một món giàu sắt: thịt đỏ, gà, cá, trứng, đậu phụ, các loại đậu, rau lá xanh đậm hoặc ngũ cốc tăng cường sắt. Ăn kèm rau quả giàu vitamin C. Không tự mua sắt cho bé uống; chỉ bổ sung theo chỉ định của bác sĩ.',
          ),
          h('Hiểu đúng về sắt'),
          p(
            'Bé sinh đủ tháng có một lượng sắt dự trữ từ thời kỳ trong bụng mẹ. Sữa mẹ có ít sắt nhưng dễ hấp thu. Đến khoảng 6 tháng, kho dự trữ này giảm dần trong khi bé lớn nhanh, nên nhu cầu sắt vượt quá những gì sữa mang lại.',
          ),
          p(
            'Đây là một trong những lý do chính để bắt đầu ăn dặm lúc 6 tháng (WHO). Theo CDC, sắt cần cho tạo máu, phát triển não bộ và miễn dịch; không đủ sắt kéo dài có thể ảnh hưởng đến sự phát triển và khả năng học của trẻ.',
          ),
          p(
            'Có hai loại sắt. Sắt trong thịt, cá, gan được cơ thể hấp thu tốt. Sắt trong thực vật như đậu, rau lá xanh, ngũ cốc tăng cường được hấp thu kém hơn, nhưng sẽ tốt hơn nhiều khi ăn cùng rau quả giàu vitamin C hoặc cùng một ít thịt, cá. Bé sinh non, nhẹ cân lúc sinh, gia đình ăn chay, hoặc bé uống nhiều sữa bò sau 1 tuổi cần được chú ý nhiều hơn.',
          ),
          h('Thực phẩm giàu sắt dễ tìm'),
          ul(
            'Thịt bò, thịt lợn nạc, thịt gà (nhất là phần đùi), thịt vịt: xay hoặc băm nhuyễn nấu cùng cháo; khi bé lớn hơn, xé sợi mềm hoặc làm viên hấp mềm để bé tự cầm.',
            'Gan gà, gan lợn: rất giàu sắt và vitamin A; chỉ cần một lượng nhỏ, không cần ăn hằng ngày.',
            'Cá và hải sản ít thủy ngân: cá hồi, cá mòi, cá rô phi, cá tuyết, tôm. Gỡ thật kỹ xương. Tránh cá mập, cá kiếm, cá cờ, cá thu vua, cá ngừ mắt to vì nhiều thủy ngân (FDA, CDC).',
            'Trứng: nấu chín kỹ cả lòng trắng và lòng đỏ, nghiền vào cháo hoặc cắt miếng cho bé cầm.',
            'Đậu phụ, đậu đỏ, đậu đen, đậu xanh, đậu lăng: nấu thật mềm, nghiền.',
            'Rau lá xanh đậm: rau ngót, rau dền, cải bó xôi, mồng tơi, bông cải xanh; băm nhỏ trong cháo. Sắt từ rau hấp thu kém hơn, nên rau đi kèm chứ không thay được thịt, cá.',
            'Bột ngũ cốc ăn dặm tăng cường sắt: đọc nhãn, chọn loại không thêm đường.',
            'Vừng rang xay thật mịn, bơ đậu phộng mịn: cũng có sắt và là món dễ dị ứng nên cho bé làm quen sớm, từng món một.',
          ),
          h('Ba mẹ có thể làm gì để bé hấp thu sắt tốt hơn'),
          ul(
            'Ăn kèm rau quả giàu vitamin C trong cùng bữa: cam, quýt (bỏ hạt, tách múi nhỏ), đu đủ, xoài, cà chua, bông cải xanh, khoai lang (CDC).',
            'Kết hợp một ít thịt, cá với rau và đậu trong cùng bát cháo.',
            'Không cho bé uống trà, kể cả trà loãng; trà không phù hợp với trẻ nhỏ và làm giảm hấp thu sắt.',
            'Chưa dùng sữa bò tươi làm đồ uống chính trước 12 tháng (chỉ dùng trong nấu ăn). Sau 1 tuổi, AAP gợi ý khoảng 480 ml sữa mỗi ngày; uống nhiều hơn dễ làm bé ăn ít đi.',
            'Bé bú mẹ hoàn toàn trước 6 tháng hoặc bé sinh non: hỏi bác sĩ về việc bổ sung sắt; chỉ dùng theo chỉ định, đúng sản phẩm bác sĩ kê.',
          ),
          tip(
            'Một ngày ăn nhiều sắt cho bé khoảng 8 tháng',
            'Sáng: cháo thịt bò bí đỏ, vài miếng đu đủ. Trưa: cháo cá hồi rau ngót, thêm chút dầu. Bữa phụ: trứng hấp mềm hoặc sữa chua nguyên kem không đường. Chiều: cháo đậu phụ cà chua với bông cải xanh, vài múi cam nhỏ đã bỏ hạt. Bé vẫn bú mẹ hoặc bú sữa công thức như thường.',
          ),
          h('Theo dõi'),
          ul(
            'Mỗi bữa ăn dặm có một món giàu sắt không, nhất là khi bé đã ăn 2–3 bữa mỗi ngày.',
            'Gia đình ăn chay, bé ăn rất ít thịt cá, hoặc uống nhiều sữa bò và ăn ít: nên trao đổi với bác sĩ.',
            'Da hoặc niêm mạc nhợt, bé mệt, kém ăn, ít chơi: các biểu hiện này có nhiều nguyên nhân, cần bác sĩ khám chứ không tự kết luận.',
            'CDC cho biết bác sĩ thường kiểm tra máu cho trẻ quanh 12 tháng; hãy hỏi bác sĩ ở lần khám định kỳ.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            'Nước hầm xương, nước luộc thịt có nhiều sắt → Sắt nằm chủ yếu trong thớ thịt, không tan vào nước → Băm nhỏ để bé ăn cả cái.',
            'Rau dền đỏ, lòng đỏ trứng “bổ máu”, ăn nhiều là đủ sắt → Sắt từ thực vật và trứng hấp thu kém hơn sắt trong thịt, cá → Kết hợp với thịt, cá và rau quả giàu vitamin C.',
            'Thấy bé xanh xao thì mua thuốc sắt về cho uống → Uống thừa sắt có thể gây ngộ độc nặng ở trẻ nhỏ, và xanh xao có nhiều nguyên nhân → Đưa bé đi khám; chỉ dùng sắt theo chỉ định bác sĩ.',
            'Bé uống sữa nhiều là đủ chất, không cần thịt → Sữa bò có rất ít sắt, uống nhiều lại làm bé ăn ít đi → Từ 6 tháng, bé cần thức ăn giàu sắt mỗi ngày.',
          ),
          urgent(
            'Gọi {emergency} ngay khi',
            'Nghi bé nuốt phải viên sắt hay thuốc bổ của người lớn, kể cả khi bé chưa có biểu hiện gì. Đừng chờ: gọi {emergency} hoặc đưa bé đến khoa cấp cứu gần nhất.',
          ),
          doctor(
            'Khi nào nên hỏi bác sĩ',
            'Bé sinh non hoặc nhẹ cân lúc sinh; bé bú mẹ hoàn toàn và ba mẹ muốn hỏi về bổ sung sắt; gia đình ăn chay; bé da nhợt, mệt, kém ăn, ít chơi; bé đã 1 tuổi mà chưa từng được kiểm tra máu.',
          ),
        ],
        en: [
          note(
            'In short',
            "Iron helps make blood and supports brain development. The iron your baby stores at birth runs down, so from 6 months every solid meal should include an iron-rich food: red meat, chicken, fish, egg, tofu, beans and lentils, dark leafy greens or iron-fortified cereal. Serve it with fruit or vegetables rich in vitamin C. Don't buy iron for your baby yourself; give a supplement only as the doctor prescribes.",
          ),
          h('Understanding iron'),
          p(
            'A baby born at term has a store of iron built up during pregnancy. Breast milk contains little iron, but it is easily absorbed. By around 6 months this store is running down while your baby grows fast, so their iron needs go beyond what milk provides.',
          ),
          p(
            "This is one of the main reasons to start solids at 6 months (WHO). According to the CDC, iron is needed for making blood, brain development and immunity; not getting enough iron over a long time can affect a child's development and learning.",
          ),
          p(
            "There are two kinds of iron. Iron in meat, fish and liver is absorbed well. Iron in plant foods such as beans, leafy greens and fortified cereals is absorbed less well, but much better when eaten with fruit or vegetables rich in vitamin C, or with a little meat or fish. Babies born preterm or with low birth weight, babies in vegetarian families, and children who drink a lot of cow's milk after 1 year need extra attention.",
          ),
          h('Iron-rich foods that are easy to find'),
          ul(
            'Beef, lean pork, chicken (especially thigh meat), duck: blend or mince finely and cook in porridge; as your baby grows, shred it softly or make soft steamed meatballs for them to hold.',
            'Chicken or pork liver: very rich in iron and vitamin A; only a small amount is needed, and not every day.',
            'Low-mercury fish and seafood: salmon, sardines, tilapia, cod, shrimp. Remove bones carefully. Avoid shark, swordfish, marlin, king mackerel and bigeye tuna because of their high mercury (FDA, CDC).',
            'Egg: cook the white and yolk until solid, then mash into porridge or cut into pieces for your baby to hold.',
            'Tofu, red beans, black beans, mung beans, lentils: cook until very soft, then mash.',
            'Dark leafy greens: katuk (rau ngót), amaranth, spinach, Malabar spinach, broccoli; mince into porridge. Iron from vegetables is absorbed less well, so greens go alongside meat and fish rather than replacing them.',
            'Iron-fortified baby cereal: read the label and choose one without added sugar.',
            'Finely ground toasted sesame and smooth peanut butter: they contain iron too and are common allergens best introduced early, one at a time.',
          ),
          h('What you can do to help your baby absorb more iron'),
          ul(
            'Serve fruit or vegetables rich in vitamin C at the same meal: orange or mandarin (seeds removed, in small segments), papaya, mango, tomato, broccoli, sweet potato (CDC).',
            'Combine a little meat or fish with vegetables and beans in the same bowl of porridge.',
            'Never give your baby tea, even weak tea; tea is not suitable for young children and reduces iron absorption.',
            "Don't give cow's milk as the main drink before 12 months (use it only in cooking). After 1 year, the AAP suggests about 480 ml of milk a day; more than that easily makes children eat less.",
            'If your baby was exclusively breastfed before 6 months or born preterm, ask the doctor about iron supplements; use them only as prescribed, and only the product the doctor recommends.',
          ),
          tip(
            'An iron-rich day for a baby of about 8 months',
            'Breakfast: beef and pumpkin porridge, a few pieces of papaya. Lunch: salmon and katuk porridge with a little oil. Snack: soft steamed egg or plain full-fat yoghurt. Afternoon: tofu and tomato porridge with broccoli, and a few small seedless orange segments. Your baby still breastfeeds or has formula as usual.',
          ),
          h('What to watch'),
          ul(
            'Whether every solid meal includes an iron-rich food, especially once your baby has 2–3 meals a day.',
            "Your family is vegetarian, your baby eats very little meat or fish, or drinks a lot of cow's milk and eats little: talk to the doctor.",
            "Pale skin or inner eyelids, tiredness, poor appetite, playing less: these have many possible causes and need a doctor's check rather than your own conclusion.",
            "The CDC says doctors usually check children's blood around 12 months; ask about it at the routine checkup.",
          ),
          h('Common myths'),
          ul(
            'Bone broth and meat stock are full of iron → Iron stays mostly in the meat fibers and does not dissolve into the water → Mince the meat so your baby eats the solid part.',
            'Red amaranth and egg yolk "build blood", so eating lots of them gives enough iron → Iron from plants and eggs is absorbed less well than iron from meat and fish → Combine them with meat, fish and fruit or vegetables rich in vitamin C.',
            'If the baby looks pale, buy iron drops → Too much iron can cause serious poisoning in young children, and paleness has many causes → Take your baby to the doctor; use iron only as prescribed.',
            "A baby who drinks lots of milk is well nourished and doesn't need meat → Cow's milk has very little iron, and drinking a lot makes babies eat less → From 6 months, your baby needs iron-rich foods every day.",
          ),
          urgent(
            'Call {emergency} now if',
            "You think your baby has swallowed an iron tablet or an adult's supplement, even if they seem fine. Don't wait: call {emergency} or go to the nearest emergency department.",
          ),
          doctor(
            'When to ask a doctor',
            'Your baby was born preterm or with low birth weight; is exclusively breastfed and you want to ask about iron supplements; your family is vegetarian; your baby is pale, tired, eats poorly or plays less; or your baby is 1 year old and has never had a blood check.',
          ),
        ],
      },
      keywords: t(
        [
          'sắt',
          'thực phẩm giàu sắt',
          'thịt bò',
          'gan',
          'cá',
          'đậu phụ',
          'rau lá xanh',
          'vitamin C',
          'ngũ cốc tăng cường sắt',
          'xanh xao',
          'bổ sung sắt',
        ],
        [
          'iron',
          'iron-rich foods',
          'beef',
          'liver',
          'fish',
          'tofu',
          'leafy greens',
          'vitamin C',
          'iron-fortified cereal',
          'pale skin',
          'iron supplements',
        ],
      ),
      relatedArticleIds: [
        'art_vitamin_d_iron',
        'art_solids_vn_porridge',
        'art_allergen_intro',
        'art_solids_menu_6_8',
      ],
      milestoneIds: [],
      sources: [
        S.cdcIron,
        S.nhsIron,
        S.hcVitaminIron,
        S.whoAnaemia,
        S.whoCf2023,
        S.cdcFoodsToAvoid,
        S.fdaFish,
        S.mohCf2026,
      ],
    },
  },
  {
    id: 'art_solids_hunger_fullness',
    reviewerLabel: NUTRITION,
    data: {
      library: 'solids',
      topic: 'feeding',
      subtopic: 'methods',
      format: 'article',
      ageWeeks: { from: 22, to: 104 },
      readingMinutes: 4,
      cover: null,
      title: t(
        'Bé đói hay no? Cho ăn theo tín hiệu của bé',
        "Is your baby hungry or full? Feeding by your baby's cues",
      ),
      summary: t(
        'Cho ăn đáp ứng là đọc tín hiệu đói, no của bé và để bé quyết định ăn bao nhiêu. Dấu hiệu theo tuổi, cách chia vai trò giữa người lớn và bé, và vì sao không nên ép ăn hay dỗ ăn bằng điện thoại.',
        "Responsive feeding means reading your baby's hunger and fullness cues and letting them decide how much to eat. Cues by age, how adults and babies share the job, and why not to force food or coax with a phone.",
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Người lớn quyết định cho bé ăn gì, khi nào và ở đâu; bé quyết định ăn bao nhiêu. Bé đói: nhìn theo thức ăn, há miệng, nghiêng người tới, với tay. Bé no: ngậm chặt miệng, quay đầu, đẩy thìa, chơi với thức ăn. Dừng khi bé no, không ép, không dỗ bằng điện thoại hay tivi. Lượng ăn mỗi ngày mỗi khác là bình thường.',
          ),
          h('Hiểu đúng về cho ăn đáp ứng'),
          p('WHO khuyên cho trẻ ăn theo cách đáp ứng:'),
          ul(
            'Nhận ra và đáp lại tín hiệu đói, no của bé.',
            'Cho ăn chậm rãi, kiên nhẫn.',
            'Khuyến khích nhưng không ép.',
            'Nói chuyện và nhìn bé trong bữa ăn.',
          ),
          p(
            'Trẻ nhỏ sinh ra đã có khả năng tự điều chỉnh lượng ăn. Khi bị ép, bé dần bỏ qua cảm giác no của chính mình, sợ bữa ăn, dễ sặc và có khi lại ăn ít hơn.',
          ),
          p(
            'Lượng ăn của bé thay đổi theo ngày: ngày ăn nhiều, ngày ăn ít, nhất là khi mọc răng, mệt hay ốm. Sau 1 tuổi bé lớn chậm lại nên nhìn có vẻ ăn ít hơn trước (AAP). Hãy đánh giá qua nhiều ngày và qua biểu đồ tăng trưởng ở các lần khám, đừng dựa vào một bữa.',
          ),
          h('Tín hiệu đói và no theo tuổi'),
          ul(
            '6–8 tháng, bé đói: nhìn theo thức ăn, với tay về phía bát, há miệng khi thìa đến gần, phấn khích khi thấy đồ ăn (CDC).',
            '6–8 tháng, bé no: ngậm chặt miệng, quay đầu đi, đẩy thìa hoặc thức ăn ra, ăn chậm lại, mất tập trung.',
            '9–23 tháng, bé đói: chỉ tay vào thức ăn, dùng cử chỉ, âm thanh hoặc từ ngữ để xin thêm, tự bốc ăn hăng hái.',
            '9–23 tháng, bé no: lắc đầu, nói “không”, ném hoặc nghịch thức ăn, đòi xuống ghế.',
            'Khóc là tín hiệu đói muộn: mời bé ăn khi bé còn bình tĩnh thì bữa ăn dễ dàng hơn (CDC).',
          ),
          h('Ba mẹ có thể làm gì'),
          ul(
            'Giữ giờ ăn tương đối đều: WHO gợi ý 2–3 bữa mỗi ngày lúc 6–8 tháng, 3–4 bữa lúc 9–23 tháng, thêm 1–2 bữa phụ nếu bé cần.',
            'Ngồi cùng bé, nhìn bé, nói chuyện và khen nhẹ nhàng; tắt tivi, cất điện thoại.',
            'Đưa thìa đến gần, đợi bé há miệng; cho bé tự cầm thìa, tự bốc thức ăn.',
            'Bắt đầu bằng phần nhỏ, bé muốn thêm thì cho thêm.',
            'Khi bé đã ra tín hiệu no, có thể mời lại một lần; bé vẫn từ chối thì kết thúc bữa, không kéo dài bữa ăn hay bế đi rong để đút.',
            'Không dùng đồ ăn để thưởng hoặc phạt (CDC), không so sánh lượng ăn với bé khác.',
            'Thống nhất cách làm với ông bà và người trông bé.',
          ),
          tip(
            'Khi bà muốn cháu ăn thêm vài thìa',
            'Thương cháu nên muốn cháu ăn nhiều là điều dễ hiểu. Có thể nhờ bà cùng nhìn tín hiệu của bé: mời lại một lần, nếu bé vẫn ngậm miệng hay quay đi thì dừng. Ghi lượng ăn vào nhật ký ăn dặm để cả nhà thấy qua nhiều ngày bé vẫn ăn đủ.',
          ),
          h('Theo dõi'),
          ul(
            'Cân nặng, chiều dài theo biểu đồ tăng trưởng ở các lần khám định kỳ.',
            'Bé vẫn chơi, tỉnh táo, đủ tã ướt; đó là dấu hiệu tốt hơn số thìa của một bữa.',
            'Bé có ngậm thức ăn lâu, nôn ọe khi bị ép, hay sợ ghế ăn không.',
            'Không khí bữa ăn: căng thẳng kéo dài là lúc nên đổi cách làm.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            'Bé phải ăn hết bát mới đủ chất → Lượng gợi ý chỉ là trung bình, bé tự điều chỉnh theo nhu cầu → Mời, khuyến khích, dừng khi bé no.',
            'Vừa xem điện thoại vừa ăn thì bé ăn được nhiều hơn → Bé ăn mà không cảm nhận no đói, nuốt vội dễ sặc; WHO cũng khuyên trẻ dưới 2 tuổi không ngồi xem màn hình → Ăn ở bàn, cả nhà ngồi cùng, không màn hình.',
            'Bé ngậm cơm là hư, phải quát → Bé ngậm thường vì đã no, chán, mệt hoặc miếng quá khó nhai → Dừng bữa, kiểm tra độ thô và giờ ăn.',
            'Bé nhẹ cân hơn bạn cùng tuổi thì phải ép thêm → Ép ăn thường làm bé ăn ít đi và sợ bữa ăn → Đưa bé đi khám để đánh giá theo biểu đồ, và làm bữa ăn giàu dinh dưỡng hơn thay vì nhiều hơn.',
          ),
          urgent('Gọi {emergency} ngay khi', 'Bé khó thở, tím tái hoặc lả đi khi đang ăn.'),
          doctor(
            'Khi nào nên hỏi bác sĩ',
            'Bé sụt cân hoặc không tăng cân qua các lần khám; bé thường xuyên từ chối mọi thức ăn, nôn khi ăn, khó nuốt hoặc ho sặc; bé đòi ăn liên tục không ngừng; bữa ăn luôn căng thẳng khiến ba mẹ kiệt sức.',
          ),
        ],
        en: [
          note(
            'In short',
            "Adults decide what your baby eats, when and where; your baby decides how much. Hungry: watching food, opening the mouth, leaning forward, reaching. Full: mouth firmly closed, turning the head, pushing the spoon away, playing with food. Stop when your baby is full, never force, and don't coax with a phone or TV. Eating different amounts on different days is normal.",
          ),
          h('Understanding responsive feeding'),
          p('WHO advises responsive feeding:'),
          ul(
            "Recognize and respond to your baby's hunger and fullness cues.",
            'Feed slowly and patiently.',
            'Encourage without forcing.',
            'Talk to and look at your baby during meals.',
          ),
          p(
            'Young children are born able to regulate how much they eat. When forced, babies gradually ignore their own feeling of fullness, become afraid of meals, choke more easily and sometimes end up eating less.',
          ),
          p(
            'How much your baby eats changes from day to day: some days a lot, some days little, especially when teething, tired or unwell. After 1 year children grow more slowly, so they may seem to eat less than before (AAP). Judge over several days and by the growth chart at checkups, not by a single meal.',
          ),
          h('Hunger and fullness cues by age'),
          ul(
            '6–8 months, hungry: watches food, reaches toward the bowl, opens the mouth as the spoon comes near, gets excited at the sight of food (CDC).',
            '6–8 months, full: closes the mouth firmly, turns the head away, pushes the spoon or food away, slows down, loses interest.',
            '9–23 months, hungry: points at food, uses gestures, sounds or words to ask for more, feeds themselves eagerly.',
            '9–23 months, full: shakes the head, says "no", throws or plays with food, wants to get down from the chair.',
            'Crying is a late sign of hunger: offering food while your baby is still calm makes meals easier (CDC).',
          ),
          h('What you can do'),
          ul(
            'Keep fairly regular mealtimes: WHO suggests 2–3 meals a day at 6–8 months and 3–4 meals at 9–23 months, plus 1–2 snacks if your baby needs them.',
            'Sit with your baby, look at them, talk and praise gently; turn off the TV and put phones away.',
            'Bring the spoon close and wait for an open mouth; let your baby hold a spoon and pick up food themselves.',
            'Start with a small portion and offer more if your baby wants it.',
            'Once your baby shows they are full, you can offer once more; if they still refuse, end the meal, without dragging it out or carrying them around to feed them.',
            "Don't use food as a reward or punishment (CDC), and don't compare how much your baby eats with other babies.",
            'Agree on the approach with grandparents and carers.',
          ),
          tip(
            'When grandma wants the baby to eat a few more spoonfuls',
            "Wanting a grandchild to eat a lot comes from love and is easy to understand. Invite grandma to read your baby's cues with you: offer once more, and if your baby still closes their mouth or turns away, stop. Logging amounts in the solids diary shows the whole family that over several days your baby is eating enough.",
          ),
          h('What to watch'),
          ul(
            'Weight and length on the growth chart at routine checkups.',
            'Your baby still plays, is alert and has enough wet nappies; these say more than the number of spoonfuls at one meal.',
            'Whether your baby holds food in their mouth for a long time, gags when pushed to eat, or seems afraid of the high chair.',
            'The mood at mealtimes: ongoing tension is a sign to change the approach.',
          ),
          h('Common myths'),
          ul(
            'A baby must finish the bowl to be well nourished → Suggested amounts are only averages, and babies adjust to their own needs → Offer, encourage and stop when your baby is full.',
            'Babies eat more while watching a phone → They eat without noticing hunger or fullness and swallow in a hurry, which makes choking more likely; WHO also advises no sedentary screen time for children under 2 → Eat at the table, together, without screens.',
            'Holding rice in the mouth is naughty and deserves a scolding → Babies usually do this because they are full, bored, tired or the piece is too hard to chew → End the meal and check the texture and mealtime.',
            'A baby lighter than others the same age should be pushed to eat more → Forcing usually makes babies eat less and fear meals → Have your baby checked against the growth chart, and make meals more nourishing rather than bigger.',
          ),
          urgent(
            'Call {emergency} now if',
            'Your baby has trouble breathing, turns blue or goes limp while eating.',
          ),
          doctor(
            'When to ask a doctor',
            'Your baby loses weight or does not gain between checkups; often refuses all food, vomits when eating, struggles to swallow or chokes; constantly demands food without stopping; or mealtimes are always so tense that you are exhausted.',
          ),
        ],
      },
      keywords: t(
        [
          'tín hiệu đói',
          'tín hiệu no',
          'cho ăn đáp ứng',
          'ép ăn',
          'ngậm cơm',
          'xem điện thoại khi ăn',
          'lượng ăn',
          'biếng ăn',
          'ông bà cho ăn',
          'bữa ăn',
        ],
        [
          'hunger cues',
          'fullness cues',
          'responsive feeding',
          'forcing food',
          'holding food in mouth',
          'phones at mealtimes',
          'portion size',
          'poor appetite',
          'grandparents feeding',
          'mealtimes',
        ],
      ),
      relatedArticleIds: [
        'art_solids_refusal',
        'art_picky_eating_toddler',
        'art_growth_charts',
        'art_solids_first_meals',
      ],
      milestoneIds: [],
      sources: [
        S.cdcHungryFull,
        S.hcResponsiveFeeding,
        S.whoCf2023,
        S.whoIycf,
        S.unicef6to12,
        S.nhsHowToStart,
        S.hcOneYearOld,
        S.whoSitLessPlayMore,
      ],
    },
  },
  // ----- An toàn (safety) -----
  {
    id: 'art_solids_foods_to_avoid',
    reviewerLabel: NUTRITION,
    data: {
      library: 'solids',
      topic: 'feeding',
      subtopic: 'safety',
      format: 'article',
      ageWeeks: { from: 22, to: 52 },
      readingMinutes: 5,
      cover: null,
      title: t(
        'Những thực phẩm chưa nên cho bé dưới 1 tuổi',
        'Foods to hold off on before your baby turns 1',
      ),
      summary: t(
        'Mật ong, muối, đường, sữa bò làm đồ uống chính, hạt nguyên, cá nhiều thủy ngân, trà và đồ uống ngọt: vì sao bé dưới 1 tuổi chưa nên dùng, nên thay bằng gì, và những món không cần kiêng.',
        "Honey, salt, sugar, cow's milk as the main drink, whole nuts, high-mercury fish, tea and sweet drinks: why babies under 1 should not have them, what to give instead, and the foods there is no need to avoid.",
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Trước 12 tháng: không mật ong; không nêm muối, nước mắm, hạt nêm, đường; không dùng sữa bò tươi làm đồ uống chính (nấu cùng thức ăn thì được); không hạt nguyên, nho nguyên quả, bỏng ngô; không trà, cà phê, nước ngọt, nước ép, sữa gạo; tránh cá nhiều thủy ngân và đồ sống, tái. Trứng chín, đậu phộng dạng mịn, cá, tôm thì không cần kiêng, nên cho bé làm quen sớm.',
          ),
          h('Hiểu đúng'),
          p(
            'Bé dưới 1 tuổi có thận và ruột còn non, đang học nhai nuốt, và nhạy cảm với vi khuẩn, chất độc hơn người lớn. Một số món không phù hợp vì có thể gây ngộ độc hoặc hóc, một số khác vì làm bé quen vị mặn, ngọt và ăn ít đi những món bổ dưỡng. Danh sách dưới đây tổng hợp từ NHS, CDC, AAP và WHO.',
          ),
          h('Danh sách cần tránh và lý do'),
          ul(
            'Mật ong, kể cả mật ong đã nấu chín, pha nước, bôi lên núm vú giả hay dùng rơ lưỡi: có thể chứa bào tử vi khuẩn gây ngộ độc botulinum ở trẻ nhỏ, và nấu chín không diệt được bào tử (CDC, NHS).',
            'Muối, nước mắm, hạt nêm, bột canh, xì dầu, bột ngọt và đồ ăn mặn như giò, chả, xúc xích, thịt nguội, mì gói, đồ hộp: thận của bé chưa xử lý được nhiều muối (NHS, CDC).',
            'Đường và đồ ngọt: kẹo, bánh ngọt, bánh quy, sữa chua có đường, sữa đặc có đường, váng sữa ngọt. CDC khuyên trẻ dưới 2 tuổi không ăn đường bổ sung; đường gây sâu răng và làm bé quen vị ngọt.',
            'Sữa bò tươi hoặc sữa hộp làm đồ uống chính: ít sắt, tạo gánh nặng cho thận và có thể gây mất máu ẩn qua ruột (CDC). Dùng trong nấu ăn, sữa chua hoặc phô mai nguyên kem làm từ sữa đã thanh trùng thì được từ 6 tháng; uống thay sữa từ 12 tháng.',
            'Đồ uống: trà (kể cả trà loãng), cà phê, nước ngọt có ga, nước tăng lực, trà sữa, nước ép trái cây (AAP khuyên không cho trước 12 tháng), sữa gạo (NHS khuyên trẻ dưới 5 tuổi không dùng thay sữa vì có asen).',
            'Hạt nguyên hoặc giã thô như đậu phộng, hạt điều, hạnh nhân, óc chó (đến 5 tuổi); bỏng ngô; hạt dưa, hạt hướng dương; kẹo cứng, kẹo dẻo, thạch cốc nhỏ, nhất là thạch có konjac.',
            'Trái cây tròn, trơn để nguyên quả: nho, cà chua bi, nhãn, vải, chôm chôm. Bỏ hạt và cắt dọc làm tư trước khi cho bé.',
            'Cá nhiều thủy ngân: cá mập, cá kiếm, cá cờ, cá thu vua, cá ngừ mắt to (CDC, FDA). Chọn cá hồi, cá mòi, cá rô phi, cá tuyết, tôm.',
            'Đồ sống hoặc tái: trứng lòng đào, trứng sống, gỏi, sushi, thịt tái, hàu, sò, ốc chưa chín kỹ; sữa và phô mai chưa thanh trùng; phô mai mềm có mốc trắng và phô mai xanh.',
          ),
          tip(
            'Những món không cần kiêng',
            'Trứng nấu chín kỹ, đậu phộng và các loại hạt dạng bơ mịn hoặc xay mịn, cá ít thủy ngân, tôm cua nấu chín, lúa mì, đậu nành, vừng, sữa bò dùng trong nấu ăn: cho bé làm quen từ 6 tháng, từng món một, rồi duy trì đều đặn. NHS lưu ý trì hoãn trứng và đậu phộng quá 6–12 tháng tuổi có thể làm tăng nguy cơ dị ứng với chính các món này.',
          ),
          h('Ba mẹ có thể làm gì'),
          ul(
            'Múc phần của bé ra trước khi nêm cho người lớn.',
            'Đọc nhãn đồ ăn đóng gói, chọn loại không thêm muối, đường; hạn chế bánh quy, bánh gạo và đồ ăn vặt đóng gói.',
            'Đồ uống của bé dưới 1 tuổi chỉ gồm sữa mẹ hoặc sữa công thức và vài ngụm nước đun sôi để nguội bằng cốc.',
            'Dặn rõ ông bà, người trông bé: không mật ong, không nước đường, không cho nhấp trà, cà phê, bia rượu, kể cả “nhấp môi cho vui” trong ngày lễ, đám cỗ.',
            'Khi ăn ngoài hay đi cỗ: chọn món luộc, hấp chưa nêm; tránh món sống, tái, xôi dẻo miếng to và các loại hạt.',
          ),
          h('Theo dõi'),
          ul(
            'Nếu bé lỡ ăn mật ong: trong những ngày sau, để ý táo bón, bú yếu, khóc yếu, mặt kém biểu cảm, mềm nhũn, và đưa bé đi khám ngay nếu có.',
            'Nếu bé lỡ nuốt hạt nguyên hoặc miếng to: theo dõi ho, khò khè, thở nhanh kéo dài; dị vật có thể còn trong đường thở.',
            'Sau món mới, nhất là món dễ dị ứng: nổi mẩn, mề đay, sưng môi, nôn.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            'Rơ lưỡi bằng mật ong cho sạch tưa → Mật ong có thể gây ngộ độc botulinum ở bé dưới 1 tuổi → Vệ sinh miệng bằng gạc sạch thấm nước đun sôi để nguội; nếu nghi tưa miệng, hỏi bác sĩ.',
            'Nêm chút muối cho bé có sức, đỡ nhạt miệng → Thịt, cá, rau đã có sẵn lượng muối tự nhiên đủ cho bé → Không nêm, để bé quen vị tự nhiên.',
            'Cho bé nhấp trà, cà phê, nước ngọt cho biết vị → Caffeine và đường không phù hợp với trẻ nhỏ; CDC khuyên tránh đồ uống có caffeine dưới 2 tuổi → Chỉ cho nước đun sôi để nguội.',
            'Kiêng tôm cua, trứng đến 1 tuổi cho chắc → Trì hoãn không phòng được dị ứng, có khi còn làm tăng nguy cơ → Cho làm quen từ 6 tháng, dạng chín và an toàn.',
          ),
          urgent(
            'Gọi {emergency} ngay khi',
            'Bé ho không ra tiếng, khó thở, tím tái, sưng môi, mặt hoặc lưỡi, nôn nhiều lần, hoặc da tái, lả đi. Trong lúc chờ, xem mục Sơ cứu trẻ em trong Child Life.',
          ),
          doctor(
            'Khi nào nên hỏi bác sĩ',
            'Bé lỡ ăn mật ong rồi bị táo bón, bú yếu, khóc yếu hoặc mềm nhũn; bé ho, khò khè kéo dài sau khi nuốt hạt hay miếng to; bé nổi mẩn, sưng môi hoặc nôn sau món mới.',
          ),
        ],
        en: [
          note(
            'In short',
            "Before 12 months: no honey; no salt, fish sauce, stock powder or sugar; no cow's milk as the main drink (cooked into food is fine); no whole nuts, whole grapes or popcorn; no tea, coffee, soft drinks, juice or rice milk; avoid high-mercury fish and raw or undercooked food. Well-cooked egg, smooth peanut, fish and shrimp don't need to be avoided and are best introduced early.",
          ),
          h('Understanding why'),
          p(
            'Babies under 1 have immature kidneys and guts, are still learning to chew and swallow, and are more sensitive to germs and toxins than adults. Some foods are unsuitable because they can cause poisoning or choking, others because they get babies used to salty or sweet tastes and crowd out nourishing foods. The list below draws on the NHS, CDC, AAP and WHO.',
          ),
          h('What to avoid and why'),
          ul(
            'Honey, including cooked honey, honey in water, on a dummy or used to clean the tongue: it can contain bacterial spores that cause infant botulism, and cooking does not destroy the spores (CDC, NHS).',
            "Salt, fish sauce, stock powder, seasoning salt, soy sauce, MSG and salty foods such as Vietnamese pork rolls, fish cakes, sausages, cold meats, instant noodles and canned food: your baby's kidneys cannot handle much salt (NHS, CDC).",
            'Sugar and sweet foods: sweets, cakes, biscuits, sweetened yoghurt, sweetened condensed milk, sweet dairy desserts. The CDC advises no added sugar for children under 2; sugar causes tooth decay and gets babies used to sweet tastes.',
            "Cow's milk or carton milk as the main drink: it is low in iron, puts strain on the kidneys and can cause hidden blood loss from the gut (CDC). Using it in cooking, or giving pasteurized full-fat yoghurt or cheese, is fine from 6 months; as a drink instead of breast milk or formula, from 12 months.",
            'Drinks: tea (even weak), coffee, fizzy drinks, energy drinks, bubble tea, fruit juice (the AAP advises none before 12 months), rice milk (the NHS advises it should not replace milk for children under 5 because of arsenic).',
            'Whole or roughly crushed nuts such as peanuts, cashews, almonds and walnuts (until 5 years); popcorn; melon and sunflower seeds; hard sweets, gummies, small jelly cups, especially those containing konjac.',
            'Round, slippery fruit left whole: grapes, cherry tomatoes, longan, lychee, rambutan. Remove the seed and cut lengthwise into quarters before giving them.',
            'High-mercury fish: shark, swordfish, marlin, king mackerel, bigeye tuna (CDC, FDA). Choose salmon, sardines, tilapia, cod or shrimp.',
            'Raw or undercooked food: soft-boiled or raw egg, raw fish salads, sushi, rare meat, oysters, clams and snails not cooked through; unpasteurized milk and cheese; mould-ripened soft cheese and blue cheese.',
          ),
          tip(
            'Foods there is no need to avoid',
            "Well-cooked egg, peanut and other nuts as smooth butter or finely ground, low-mercury fish, cooked shrimp and crab, wheat, soy, sesame, and cow's milk used in cooking: introduce them from 6 months, one at a time, then keep giving them regularly. The NHS notes that delaying egg and peanut beyond 6–12 months of age may increase the risk of allergy to those very foods.",
          ),
          h('What you can do'),
          ul(
            "Take your baby's portion out before seasoning for the adults.",
            'Read labels on packaged food and choose products without added salt or sugar; limit biscuits, rice crackers and packaged snacks.',
            'For babies under 1, drinks are breast milk or formula plus a few sips of boiled and cooled water from a cup.',
            'Be clear with grandparents and carers: no honey, no sugar water, no sips of tea, coffee, beer or alcohol, not even "a taste for fun" at holidays and family feasts.',
            'When eating out or at family feasts: choose boiled or steamed dishes before they are seasoned; avoid raw or rare dishes, large pieces of sticky rice and nuts.',
          ),
          h('What to watch'),
          ul(
            'If your baby has eaten honey by mistake: over the following days watch for constipation, weak feeding, a weak cry, a less expressive face or floppiness, and see a doctor straight away if any appear.',
            'If your baby has swallowed a whole nut or a large piece: watch for ongoing coughing, wheezing or fast breathing; something may still be in the airway.',
            'After a new food, especially a common allergen: rash, hives, swollen lips, vomiting.',
          ),
          h('Common myths'),
          ul(
            "Cleaning the tongue with honey to clear thrush → Honey can cause infant botulism in babies under 1 → Clean the mouth with clean gauze dipped in boiled and cooled water; if you think it's thrush, ask the doctor.",
            'A pinch of salt gives babies strength and stops food tasting bland → Meat, fish and vegetables already contain all the natural salt a baby needs → Add none, so your baby gets used to natural flavors.',
            'Letting babies sip tea, coffee or soft drinks to try the taste → Caffeine and sugar are not suitable for young children; the CDC advises avoiding caffeinated drinks under 2 → Offer only boiled and cooled water.',
            'Avoid shrimp, crab and egg until 1 to be safe → Delaying does not prevent allergy and may even raise the risk → Introduce them from 6 months, cooked and in a safe form.',
          ),
          urgent(
            'Call {emergency} now if',
            'Your baby cannot cough out loud, has trouble breathing, turns blue, has swelling of the lips, face or tongue, vomits repeatedly, or turns pale or limp. While you wait, see the Sơ cứu trẻ em (First aid) guide in Child Life.',
          ),
          doctor(
            'When to ask a doctor',
            'Your baby ate honey by mistake and then has constipation, weak feeding, a weak cry or floppiness; keeps coughing or wheezing after swallowing a nut or large piece; or gets a rash, swollen lips or vomiting after a new food.',
          ),
        ],
      },
      keywords: t(
        [
          'thực phẩm cần tránh',
          'mật ong',
          'muối',
          'nước mắm',
          'đường',
          'sữa bò',
          'hạt',
          'nho',
          'cá nhiều thủy ngân',
          'trà',
          'nước ép',
          'sữa gạo',
        ],
        [
          'foods to avoid',
          'honey',
          'salt',
          'fish sauce',
          'sugar',
          "cow's milk",
          'nuts',
          'grapes',
          'high-mercury fish',
          'tea',
          'juice',
          'rice milk',
        ],
      ),
      relatedArticleIds: [
        'art_water_juice',
        'art_solids_choking_safety',
        'art_allergen_intro',
        'art_solids_reactions',
      ],
      milestoneIds: [],
      sources: [
        S.nhsFoodsToAvoid,
        S.cdcFoodsToAvoid,
        S.nhsDrinksCups,
        S.hcRecommendedDrinks,
        S.hcFruitJuice,
        S.fdaFish,
        S.cdcChokingHazards,
        S.nhsFoodAllergies,
      ],
    },
  },
  {
    id: 'art_solids_reactions',
    reviewerLabel: NUTRITION,
    data: {
      library: 'solids',
      topic: 'feeding',
      subtopic: 'allergy',
      format: 'article',
      ageWeeks: { from: 22, to: 104 },
      readingMinutes: 6,
      cover: null,
      title: t(
        'Thử món mới: nhận biết phản ứng, khi nào đi khám, khi nào gọi cấp cứu',
        "Trying new foods: spotting reactions, when to see a doctor and when it's an emergency",
      ),
      summary: t(
        'Phần lớn bé ăn món mới đều ổn. Cách phân biệt đỏ da quanh miệng, mẩn nhẹ, phản ứng muộn với phản ứng nặng, việc cần làm ngay và những dấu hiệu phải gọi cấp cứu {emergency}.',
        'Most babies are fine with new foods. How to tell redness around the mouth, a mild rash and delayed reactions from a severe reaction, what to do straight away and the signs that mean calling {emergency}.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Đa số phản ứng sau món mới là nhẹ hoặc không phải dị ứng. Phản ứng dị ứng thường xuất hiện trong vài phút đến 2 giờ sau ăn. Gọi cấp cứu {emergency} ngay nếu bé khó thở, thở rít, ho liên tục, khàn tiếng, sưng lưỡi, môi hoặc mặt, nôn nhiều lần, hoặc da tái, lả, mềm nhũn. Nếu chỉ mẩn đỏ, mề đay nhẹ: ngừng món đó, chụp ảnh, theo dõi sát và hỏi bác sĩ trước khi cho ăn lại.',
          ),
          h('Hiểu đúng các kiểu phản ứng'),
          p(
            'Phản ứng nhanh: thường trong vài phút, có thể đến 2 giờ sau ăn. Dấu hiệu nhẹ đến vừa gồm mề đay, mẩn ngứa, sưng mặt, môi hoặc quanh mắt, nôn, đau bụng (ASCIA, NHS).',
          ),
          p(
            'Phản ứng nặng nhất là sốc phản vệ: khó thở hoặc thở ồn, sưng lưỡi, sưng hoặc nghẹn họng, khò khè hay ho liên tục, khàn tiếng, lả hoặc ngất. ASCIA lưu ý trẻ nhỏ bị sốc phản vệ có thể chỉ trông tái và mềm nhũn.',
          ),
          p(
            'Phản ứng chậm: xuất hiện sau vài giờ đến vài ngày; với sữa bò, NHS cho biết có thể đến 3 ngày. Bé có thể chàm nặng lên, tiêu chảy, táo bón, nôn trớ nhiều hoặc quấy khóc kéo dài.',
          ),
          p(
            'Một dạng hiếm gặp là FPIES (hội chứng viêm ruột do đạm thức ăn): bé nôn nhiều lần, thường 1–4 giờ sau khi ăn, có thể tái, mềm nhũn, lạnh và tiêu chảy. ASCIA cho biết món hay gặp ở trẻ nhỏ là gạo, yến mạch, sữa bò và trứng. Bé nôn liên tục, tái và lả cần được cấp cứu.',
          ),
          p(
            'Nhiều biểu hiện không phải dị ứng: đỏ da quanh miệng do cà chua, cam, dâu tây kích ứng da (ASCIA, BSACI); phân đổi màu theo thức ăn như cà rốt, rau xanh, thanh long ruột đỏ; oẹ khi gặp độ thô mới; nôn một lần do ăn quá no.',
          ),
          h('Trước và trong khi thử món mới'),
          ul(
            'Chọn ngày bé khỏe; cho ăn ở nhà, vào buổi sáng hoặc trưa, để có ít nhất 2 giờ theo dõi bé sau ăn.',
            'Món dễ dị ứng như trứng, đậu phộng mịn, sữa bò, cá, tôm cua, lúa mì, đậu nành, vừng, các loại hạt: cho từng món một, bắt đầu lượng nhỏ rồi tăng dần; nếu bé ổn, duy trì ít nhất mỗi tuần một lần (ASCIA, BSACI).',
            'Với rau, củ, trái cây, cho từng món một giúp dễ nhận ra món gây phản ứng, nhưng không bắt buộc và không cần chờ nhiều ngày giữa các món.',
            'Ghi món, lượng, giờ ăn và mọi dấu hiệu bất thường vào sổ hoặc nhật ký ăn dặm.',
            'Lưu sẵn số cấp cứu {emergency} và mở trước mục Sơ cứu trẻ em › Sốc phản vệ trong Child Life. Nếu bác sĩ đã kê bút tiêm adrenaline và kế hoạch xử trí, luôn mang theo bên bé.',
          ),
          h('Ba mẹ có thể làm gì khi bé có phản ứng'),
          ul(
            'Có bất kỳ dấu hiệu nặng nào (khó thở, thở rít, ho liên tục, khàn tiếng, sưng lưỡi, nôn nhiều lần, tái, lả, mềm nhũn): gọi cấp cứu {emergency} ngay. Đặt bé nằm hoặc bế bé nằm ngang, không cho bé đứng hay đi; nếu bé khó thở thì cho ngồi. Dùng bút tiêm adrenaline nếu đã được kê, và làm theo mục Sơ cứu trẻ em › Sốc phản vệ.',
            'Mề đay, sưng nhẹ môi hoặc quanh mắt, nôn một lần, nhưng bé tỉnh táo và thở bình thường: ngừng món đó, chụp ảnh, theo dõi sát vài giờ vì phản ứng có thể nặng lên, và hỏi bác sĩ trong ngày. Không tự cho thuốc khi chưa hỏi bác sĩ hoặc dược sĩ.',
            'Phản ứng chậm như chàm nặng lên, tiêu chảy, phân có máu hoặc nhầy, nôn trớ nhiều: ghi lại và đưa bé đi khám; không tự cắt bỏ cả một nhóm thực phẩm lớn như sữa (NHS).',
            'Đỏ quanh miệng nhưng không sưng, bé vẫn vui chơi bình thường: lau sạch, thoa một lớp kem dưỡng mỏng trước bữa sau; vẫn có thể tiếp tục món đó.',
          ),
          tip(
            'Chụp ảnh và ghi lại',
            'Ảnh vết mẩn, giờ ăn, món và lượng ăn, thời điểm bắt đầu triệu chứng giúp bác sĩ quyết định bé có cần xét nghiệm hay khám chuyên khoa dị ứng không. Mang nhật ký ăn dặm theo khi đi khám.',
          ),
          h('Theo dõi'),
          ul(
            'Nếu bác sĩ xác định bé dị ứng một món: hỏi rõ kế hoạch xử trí, thuốc cần mang theo và cách đọc nhãn thực phẩm.',
            'Vẫn tiếp tục giới thiệu các món dễ dị ứng khác, trừ khi bác sĩ dặn khác (ASCIA).',
            'Nhiều trẻ hết dị ứng sữa bò và trứng khi lớn hơn (NHS); bác sĩ sẽ hướng dẫn khi nào thử lại.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            'Bôi thức ăn lên da bé để thử dị ứng → Cách này không giúp phát hiện dị ứng và có thể gây đỏ da khiến ba mẹ hiểu nhầm (BSACI) → Cho ăn lượng nhỏ và theo dõi như trên.',
            'Nổi mẩn một lần là kiêng món đó mãi mãi, kiêng luôn cả nhóm → Nhiều trường hợp không phải dị ứng, và kiêng rộng làm bữa ăn của bé kém đa dạng → Hỏi bác sĩ trước khi kiêng hoặc cho ăn lại.',
            'Bé nổi mề đay thì tắm nước lá, uống nước lá cho mát → Không giúp phản ứng dị ứng và có thể làm chậm việc đi khám → Theo dõi dấu hiệu nặng và gọi cấp cứu {emergency} khi cần.',
            'Đợi xem bé có đỡ không rồi mới gọi cấp cứu → Sốc phản vệ có thể nặng lên rất nhanh → Có dấu hiệu nặng là gọi cấp cứu {emergency} ngay.',
          ),
          urgent(
            'Gọi {emergency} ngay khi',
            'Sau khi ăn, bé khó thở, thở rít hoặc khò khè, ho liên tục, khàn tiếng hoặc khóc khàn, sưng lưỡi, sưng môi hay mặt kèm khó chịu, nôn nhiều lần, da tái, lạnh, lả đi hoặc mềm nhũn. Gọi {emergency} trước, rồi làm theo mục Sơ cứu trẻ em › Sốc phản vệ trong Child Life trong lúc chờ.',
          ),
          doctor(
            'Khi nào nên hỏi bác sĩ',
            'Bé nổi mề đay, sưng môi hoặc quanh mắt, nôn sau món mới dù đã đỡ; bé có phản ứng chậm như chàm nặng lên, tiêu chảy, phân có máu; bé nôn nhiều lần vài giờ sau cùng một món; bé bị chàm nặng hoặc đã dị ứng một món và ba mẹ muốn giới thiệu tiếp món dễ dị ứng. Đừng tự cho ăn lại món nghi ngờ khi chưa hỏi bác sĩ.',
          ),
        ],
        en: [
          note(
            'In short',
            'Most reactions after a new food are mild or not allergic at all. Allergic reactions usually appear within a few minutes to 2 hours of eating. Call {emergency} now if your baby has trouble breathing, noisy breathing, a persistent cough, a hoarse voice, swelling of the tongue, lips or face, repeated vomiting, or turns pale, limp or floppy. If there is only a red rash or mild hives: stop that food, take a photo, watch closely and ask the doctor before offering it again.',
          ),
          h('Understanding the types of reaction'),
          p(
            'Fast reactions: usually within minutes, up to 2 hours after eating. Mild to moderate signs include hives, an itchy rash, swelling of the face, lips or around the eyes, vomiting and tummy pain (ASCIA, NHS).',
          ),
          p(
            'The most severe reaction is anaphylaxis: difficult or noisy breathing, a swollen tongue, swelling or tightness in the throat, wheeze or a persistent cough, a hoarse voice, floppiness or collapse. ASCIA notes that young children with anaphylaxis may simply look pale and floppy.',
          ),
          p(
            "Delayed reactions: these appear after a few hours to a few days; with cow's milk, the NHS says up to 3 days. Your baby may have worsening eczema, diarrhea, constipation, a lot of vomiting or long periods of crying.",
          ),
          p(
            "A rare form is FPIES (food protein-induced enterocolitis syndrome): repeated vomiting, usually 1–4 hours after eating, and the baby may turn pale, floppy and cold and have diarrhea. ASCIA says the most common triggers in young children are rice, oats, cow's milk and egg. A baby who keeps vomiting, is pale and floppy needs emergency care.",
          ),
          p(
            'Many signs are not allergy: redness around the mouth from tomato, citrus or strawberry irritating the skin (ASCIA, BSACI); stools changing color with foods such as carrot, greens or red dragon fruit; gagging on a new texture; vomiting once after eating too much.',
          ),
          h('Before and while trying a new food'),
          ul(
            'Choose a day when your baby is well; offer it at home, in the morning or at midday, so you can watch them for at least 2 hours afterward.',
            "Common allergens such as egg, smooth peanut, cow's milk, fish, shellfish, wheat, soy, sesame and tree nuts: one at a time, starting with a small amount and increasing; if your baby is fine, keep giving it at least once a week (ASCIA, BSACI).",
            'For vegetables and fruit, one new food at a time makes it easier to spot the cause of a reaction, but it is optional and there is no need to wait several days between foods.',
            'Log the food, amount, time and any unusual signs in a notebook or solids diary.',
            'Save {emergency} in your phone and open the Sơ cứu trẻ em › Anaphylaxis guide in Child Life ahead of time. If the doctor has prescribed an adrenaline auto-injector and an action plan, always keep them with your baby.',
          ),
          h('What you can do if your baby has a reaction'),
          ul(
            'Any severe sign (trouble breathing, noisy breathing, persistent cough, hoarse voice, swollen tongue, repeated vomiting, pale, limp or floppy): call {emergency} now. Lay your baby down or hold them lying flat, and do not let them stand or walk; if they are struggling to breathe, let them sit. Use the adrenaline auto-injector if one was prescribed, and follow the Sơ cứu trẻ em › Anaphylaxis guide.',
            'Hives, mild swelling of the lips or around the eyes, or vomiting once, while your baby is alert and breathing normally: stop that food, take a photo, watch closely for a few hours because reactions can get worse, and ask the doctor the same day. Do not give any medicine without asking a doctor or pharmacist.',
            "Delayed reactions such as worsening eczema, diarrhea, blood or mucus in the stool, or a lot of vomiting: write them down and take your baby to the doctor; don't cut out a whole major food group such as milk on your own (NHS).",
            'Redness around the mouth with no swelling, while your baby plays as usual: wipe the skin, apply a thin layer of moisturizer before the next meal; the food can usually stay on the menu.',
          ),
          tip(
            'Take photos and keep notes',
            'A photo of the rash, the time of the meal, the food and amount, and when symptoms began help the doctor decide whether your baby needs tests or an allergy specialist. Bring the solids diary to the appointment.',
          ),
          h('What to watch'),
          ul(
            'If the doctor confirms an allergy to a food: ask for a clear action plan, which medicines to carry and how to read food labels.',
            'Keep introducing the other common allergens unless the doctor says otherwise (ASCIA).',
            "Many children outgrow cow's milk and egg allergy as they get older (NHS); the doctor will advise when to try again.",
          ),
          h('Common myths'),
          ul(
            "Rubbing food on the baby's skin to test for allergy → This does not detect allergy and can redden the skin and mislead you (BSACI) → Offer a small amount to eat and watch as above.",
            "One rash means avoiding that food forever, and its whole group → Many cases are not allergy, and broad avoidance makes your baby's diet less varied → Ask the doctor before avoiding a food or offering it again.",
            'Hives can be treated with herbal baths or herbal drinks → These do not help an allergic reaction and can delay getting care → Watch for severe signs and call {emergency} when needed.',
            'Waiting to see if the baby gets better before calling an ambulance → Anaphylaxis can get worse very quickly → Any severe sign means calling {emergency} straight away.',
          ),
          urgent(
            'Call {emergency} now if',
            'After eating, your baby has trouble breathing, noisy breathing or wheezing, a persistent cough, a hoarse voice or cry, a swollen tongue, swollen lips or face with distress, repeated vomiting, pale cold skin, or goes limp or floppy. Call {emergency} first, then follow the Sơ cứu trẻ em › Anaphylaxis guide in Child Life while you wait.',
          ),
          doctor(
            'When to ask a doctor',
            "Your baby had hives, swelling of the lips or around the eyes, or vomiting after a new food, even if it has settled; has delayed reactions such as worsening eczema, diarrhea or blood in the stool; vomits repeatedly a few hours after the same food; or has severe eczema or a known food allergy and you want to introduce more common allergens. Don't offer a suspected food again before asking the doctor.",
          ),
        ],
      },
      keywords: t(
        [
          'phản ứng thức ăn',
          'dị ứng thức ăn',
          'mề đay',
          'sưng môi',
          'sốc phản vệ',
          'FPIES',
          'nôn sau ăn',
          'đỏ quanh miệng',
          'phản ứng chậm',
          'gọi cấp cứu',
          'món mới',
        ],
        [
          'food reaction',
          'food allergy',
          'hives',
          'swollen lips',
          'anaphylaxis',
          'FPIES',
          'vomiting after food',
          'redness around the mouth',
          'delayed reaction',
          'call emergency',
          'new foods',
        ],
      ),
      relatedArticleIds: [
        'art_allergen_intro',
        'art_eczema_dry_skin',
        'art_solids_foods_to_avoid',
        'art_solids_first_meals',
      ],
      milestoneIds: [],
      sources: [
        S.nhsFoodAllergies,
        S.nhsAnaphylaxis,
        S.asciaFoodAllergy,
        S.asciaFpies,
        S.asciaIntroSolids,
        S.bsaciParents,
      ],
    },
  },
  {
    id: 'art_solids_prep_storage',
    reviewerLabel: NUTRITION,
    data: {
      library: 'solids',
      topic: 'feeding',
      subtopic: 'safety',
      format: 'step_guide',
      ageWeeks: { from: 22, to: 104 },
      readingMinutes: 5,
      cover: null,
      title: t(
        'Nấu, trữ đông và hâm nóng đồ ăn dặm an toàn',
        'Cooking, freezing and reheating baby food safely',
      ),
      summary: t(
        'Từng bước nấu một mẻ đồ ăn dặm, làm nguội, chia phần, cất tủ lạnh, trữ đông và hâm nóng đúng cách để bé ăn ngon mà không lo ngộ độc thực phẩm.',
        'Step by step: cooking a batch of baby food, cooling it, portioning it, refrigerating, freezing and reheating it the right way, so your baby eats well without the risk of food poisoning.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Rửa tay, tách đồ sống và đồ chín, nấu chín kỹ, làm nguội nhanh rồi cất lạnh trong vòng 1–2 giờ (cơm, cháo trong vòng 1 giờ). Ngăn mát: dùng trong 2 ngày, riêng cơm, cháo trong 24 giờ. Rã đông trong ngăn mát, không để ở nhiệt độ phòng, và dùng trong 24 giờ. Hâm nóng sôi đều một lần duy nhất, để nguội bớt rồi mới cho bé ăn. Phần bé ăn dở thì bỏ.',
          ),
          h('Hiểu đúng về an toàn thực phẩm cho bé'),
          p(
            'Trẻ nhỏ dễ bị tiêu chảy và ngộ độc thực phẩm hơn người lớn. WHO tóm tắt an toàn thực phẩm trong năm điều:',
          ),
          ul(
            'Giữ sạch.',
            'Tách riêng đồ sống và đồ chín.',
            'Nấu chín kỹ.',
            'Giữ thức ăn ở nhiệt độ an toàn.',
            'Dùng nước và nguyên liệu an toàn.',
          ),
          p(
            'Khí hậu nóng ẩm khiến vi khuẩn phát triển nhanh, vì vậy đồ ăn của bé không nên để lâu ở nhiệt độ phòng.',
          ),
          p(
            'Cơm và cháo cần chú ý riêng: một số vi khuẩn có sẵn trong gạo có thể sinh độc tố khi cơm, cháo để nguội lâu ngoài tủ, và hâm lại cũng không phá được độc tố này. Vì thế NHS khuyên làm nguội cơm trong vòng 1 giờ, cất ngay vào tủ lạnh, dùng trong 24 giờ và chỉ hâm lại một lần.',
          ),
          h('Ba mẹ có thể làm gì: từng bước'),
          ul(
            'Bước 1 · Chuẩn bị: rửa tay bằng xà phòng. Dùng thớt, dao riêng cho thịt cá sống và cho đồ chín. Rửa rau quả dưới vòi nước sạch. Dùng nước sạch để nấu.',
            'Bước 2 · Nấu chín kỹ: thịt chín đều đến giữa, không còn màu hồng; cá chín đục, tách thớ dễ dàng; trứng chín cả lòng trắng và lòng đỏ; cháo, súp đun sôi.',
            'Bước 3 · Làm nguội nhanh: chia thức ăn ra hộp nhỏ, nông. Có thể đặt hộp đậy kín vào chậu nước lạnh và khuấy đều để nguội nhanh. Cất vào tủ lạnh hoặc tủ đông trong vòng 1–2 giờ; cơm, cháo trong vòng 1 giờ (NHS).',
            'Bước 4 · Chia phần và dán nhãn: dùng khay đá có nắp, hộp nhỏ hoặc túi trữ đông; mỗi phần vừa một bữa. Ghi tên món và ngày nấu.',
            'Bước 5 · Bảo quản: ngăn mát dùng trong 2 ngày, riêng cơm, cháo trong 24 giờ. Thịt cá sống để trong hộp kín ở ngăn dưới cùng để không nhỏ nước lên thức ăn khác. Đồ trữ đông dùng phần nấu trước trước, đừng để quá lâu.',
            'Bước 6 · Rã đông: chuyển sang ngăn mát từ tối hôm trước, hoặc dùng chế độ rã đông của lò vi sóng; không rã đông ở nhiệt độ phòng. Dùng trong 24 giờ và không cấp đông lại.',
            'Bước 7 · Hâm nóng: chỉ hâm phần đủ một bữa, một lần duy nhất, đến khi nóng sôi đều cả phần giữa. Nếu dùng lò vi sóng, khuấy đều để không còn điểm nóng.',
            'Bước 8 · Thử nhiệt độ: để nguội bớt, khuấy đều rồi thử một ít lên cổ tay bằng thìa sạch khác; thức ăn chỉ nên còn ấm.',
            'Bước 9 · Cho bé ăn: múc lượng nhỏ ra bát riêng, bé muốn thêm thì múc tiếp. Phần bé đã ăn dở thì bỏ, không cất lại hay hâm lại.',
            'Bước 10 · Mang đi ra ngoài: dùng túi giữ lạnh có đá. Nếu không giữ lạnh được, ăn trong tối đa 4 giờ rồi bỏ phần thừa (NHS); trời nóng thì càng nên dùng sớm.',
            'Bước 11 · Vệ sinh dụng cụ: rửa bát, thìa, cốc, máy xay bằng nước nóng và nước rửa bát, tráng sạch, để khô ráo; giặt hoặc thay khăn lau bếp thường xuyên.',
          ),
          tip(
            'Mẹo trữ đông bằng khay đá',
            'Rau củ nghiền, thịt cá xay đã nấu chín có thể cấp đông trong khay đá có nắp. Khi đã đông cứng, lấy ra cho vào túi kín, ghi tên và ngày. Mỗi viên khoảng vài thìa, tiện rã đông vừa đủ và phối nhiều món trong một bữa.',
          ),
          h('Theo dõi'),
          ul(
            'Nhiệt độ tủ: ngăn mát nên từ 5 °C trở xuống, tủ đông khoảng −18 °C.',
            'Sau khi mất điện lâu, đồ trữ đông đã tan hết thì xử lý như đồ rã đông: giữ lạnh và dùng trong 24 giờ, hoặc bỏ đi nếu không chắc.',
            'Thức ăn có mùi lạ, đổi màu, sủi bọt hoặc nhớt: bỏ ngay, không nếm thử.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            'Nấu một nồi cháo buổi sáng, để trên bếp cho bé ăn cả ngày → Vi khuẩn phát triển nhanh ở nhiệt độ phòng và độc tố không mất khi đun lại → Làm nguội, cất tủ lạnh, mỗi lần chỉ hâm đủ một bữa.',
            'Hâm đi hâm lại nhiều lần cũng được, miễn là đun sôi → Mỗi lần nguội đi rồi hâm lại là thêm cơ hội cho vi khuẩn → Chỉ hâm một lần; chia phần nhỏ từ đầu.',
            'Thử độ nóng bằng cách ngậm thìa của bé → Có thể truyền vi khuẩn gây sâu răng sang bé → Thử trên cổ tay bằng một thìa khác.',
            'Đồ nấu từ hôm trước ngửi không có mùi là ăn được → Nhiều vi khuẩn gây bệnh không làm đổi mùi vị → Theo đúng mốc thời gian bảo quản.',
          ),
          urgent(
            'Gọi {emergency} ngay khi',
            'Bé lả, khó đánh thức, không uống được, hoặc khó thở, sưng môi, mặt sau khi ăn. Đừng chờ: gọi {emergency} hoặc đưa bé đến khoa cấp cứu gần nhất.',
          ),
          doctor(
            'Khi nào nên hỏi bác sĩ',
            'Bé tiêu chảy hoặc nôn sau khi ăn, nhất là khi người khác cùng ăn cũng bị; bé có dấu hiệu mất nước như ít tã ướt, môi khô, khóc không có nước mắt, li bì; phân có máu; bé sốt cao.',
          ),
        ],
        en: [
          note(
            'In short',
            'Wash your hands, keep raw and cooked food apart, cook thoroughly, cool quickly and refrigerate within 1–2 hours (rice and porridge within 1 hour). In the fridge, use within 2 days, or within 24 hours for rice and porridge. Thaw in the fridge, not at room temperature, and use within 24 hours. Reheat until steaming hot throughout, only once, and let it cool before feeding. Throw away anything your baby has partly eaten.',
          ),
          h('Understanding food safety for babies'),
          p(
            'Young children get diarrhea and food poisoning more easily than adults. WHO sums up food safety in five keys:',
          ),
          ul(
            'Keep clean.',
            'Separate raw and cooked.',
            'Cook thoroughly.',
            'Keep food at safe temperatures.',
            'Use safe water and raw materials.',
          ),
          p(
            "A hot, humid climate lets bacteria grow fast, so your baby's food should not sit at room temperature for long.",
          ),
          p(
            'Rice and porridge need special care: some bacteria naturally present in rice can produce toxins when cooked rice or porridge is left to cool slowly outside the fridge, and reheating does not destroy these toxins. That is why the NHS advises cooling rice within 1 hour, refrigerating it straight away, eating it within 24 hours and reheating it only once.',
          ),
          h('What you can do: step by step'),
          ul(
            'Step 1 · Prepare: wash your hands with soap. Use separate boards and knives for raw meat and fish and for cooked food. Rinse fruit and vegetables under clean running water. Cook with clean water.',
            'Step 2 · Cook thoroughly: meat cooked through to the middle, with no pink left; fish opaque and flaking easily; egg white and yolk solid; porridge and soups brought to the boil.',
            'Step 3 · Cool quickly: divide food into small, shallow containers. You can stand a closed container in a bowl of cold water and stir to cool it faster. Put it in the fridge or freezer within 1–2 hours; rice and porridge within 1 hour (NHS).',
            'Step 4 · Portion and label: use ice cube trays with lids, small pots or freezer bags; one portion per meal. Write the name of the dish and the date it was cooked.',
            "Step 5 · Store: use fridge food within 2 days, rice and porridge within 24 hours. Keep raw meat and fish in a closed container on the bottom shelf so it cannot drip onto other food. With frozen food, use the oldest first and don't keep it too long.",
            'Step 6 · Thaw: move it to the fridge the night before, or use the defrost setting on a microwave; never thaw at room temperature. Use within 24 hours and do not refreeze.',
            "Step 7 · Reheat: reheat only one meal's worth, only once, until steaming hot all the way through. In a microwave, stir well so no hot spots remain.",
            'Step 8 · Check the temperature: let it cool, stir, then test a little on your wrist using a separate clean spoon; the food should be just warm.',
            'Step 9 · Serve: put a small amount in a separate bowl and add more if your baby wants it. Throw away anything your baby has partly eaten; never store or reheat it again.',
            'Step 10 · Food on the go: use a cool bag with ice packs. If food cannot be kept cold, eat it within 4 hours at most and throw away leftovers (NHS); in hot weather, use it even sooner.',
            'Step 11 · Clean equipment: wash bowls, spoons, cups and the blender in hot water with washing-up liquid, rinse and let them dry; wash or change kitchen cloths often.',
          ),
          tip(
            'Freezing in ice cube trays',
            'Cooked mashed vegetables and blended meat or fish can be frozen in ice cube trays with lids. Once frozen solid, pop the cubes into a sealed bag labeled with the name and date. Each cube holds a few spoonfuls, making it easy to thaw just enough and mix several foods in one meal.',
          ),
          h('What to watch'),
          ul(
            'Fridge temperature: the fridge should be 5 °C or below, the freezer about −18 °C.',
            'After a long power cut, frozen food that has fully thawed is treated as thawed food: keep it cold and use it within 24 hours, or throw it away if you are unsure.',
            'Food that smells odd, changes color, bubbles or turns slimy: throw it away straight away, without tasting it.',
          ),
          h('Common myths'),
          ul(
            'Cooking a pot of porridge in the morning and leaving it on the stove for the baby all day → Bacteria grow fast at room temperature and toxins are not removed by reheating → Cool it, refrigerate it and reheat only one meal at a time.',
            'Reheating again and again is fine as long as it boils → Every round of cooling and reheating gives bacteria another chance → Reheat only once; portion small from the start.',
            "Testing the temperature by putting the baby's spoon in your mouth → This can pass tooth-decay bacteria to your baby → Test on your wrist with a different spoon.",
            "If yesterday's food smells fine, it's safe → Many bacteria that cause illness don't change the smell or taste → Stick to the storage times.",
          ),
          urgent(
            'Call {emergency} now if',
            "Your baby is limp, hard to wake, cannot drink, or has trouble breathing or swelling of the lips or face after eating. Don't wait: call {emergency} or go to the nearest emergency department.",
          ),
          doctor(
            'When to ask a doctor',
            'Your baby has diarrhea or vomiting after eating, especially if others who ate the same food are ill too; shows signs of dehydration such as fewer wet nappies, dry lips, crying without tears or unusual drowsiness; has blood in the stool; or has a high fever.',
          ),
        ],
      },
      keywords: t(
        [
          'trữ đông',
          'hâm nóng',
          'bảo quản đồ ăn dặm',
          'nấu một lần nhiều bữa',
          'khay đá',
          'rã đông',
          'tủ lạnh',
          'an toàn thực phẩm',
          'ngộ độc thực phẩm',
          'cơm cháo để qua đêm',
        ],
        [
          'freezing baby food',
          'reheating',
          'storing baby food',
          'batch cooking',
          'ice cube trays',
          'thawing',
          'fridge',
          'food safety',
          'food poisoning',
          'leftover rice and porridge',
        ],
      ),
      relatedArticleIds: [
        'art_solids_vn_porridge',
        'art_solids_menu_6_8',
        'art_diarrhoea_dehydration',
        'art_solids_first_meals',
      ],
      milestoneIds: [],
      sources: [
        S.nhsStoringReheating,
        S.whoFiveKeys,
        S.unicef6to12,
        S.whoIycf,
        S.whoDiarrhoea,
        S.nhsDiarrhoea,
      ],
    },
  },
  // ----- Thực đơn (menus) -----
  {
    id: 'art_solids_menu_6_8',
    reviewerLabel: NUTRITION,
    data: {
      library: 'solids',
      topic: 'feeding',
      subtopic: 'menus',
      format: 'article',
      ageWeeks: { from: 26, to: 39 },
      readingMinutes: 4,
      cover: null,
      title: t(
        'Một tuần ăn dặm mẫu cho bé 6–8 tháng',
        'A sample week of solids for babies 6–8 months',
      ),
      summary: t(
        'Gợi ý thực đơn 7 ngày bằng thực phẩm quen thuộc cho bé 6–8 tháng: số bữa, độ thô, món giàu sắt mỗi ngày và cách đưa trứng, đậu phộng, cá vào sớm.',
        'A 7-day menu idea with familiar foods for babies 6–8 months: how many meals, which textures, an iron-rich food every day and how to bring in egg, peanut and fish early.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Đây là gợi ý, không phải lịch bắt buộc. Những tuần đầu từ 6 tháng: 1–2 bữa nhỏ mỗi ngày, tăng dần lên 2–3 bữa, mỗi bữa từ vài thìa đến khoảng nửa chén nhỏ theo sức ăn của bé. Mỗi ngày có một món giàu sắt, rau hoặc trái cây, và dần thêm các món dễ dị ứng. Sữa mẹ hoặc sữa công thức vẫn là nguồn dinh dưỡng chính.',
          ),
          h('Hiểu đúng về thực đơn 6–8 tháng'),
          p(
            'UNICEF gợi ý bé bú mẹ bắt đầu với 2–3 thìa, ngày 2 lần; đến 6–8 tháng là khoảng nửa chén (chén khoảng 250 ml) thức ăn mềm, 2–3 lần mỗi ngày, thêm một bữa phụ lành mạnh như trái cây nghiền. Bé không bú mẹ cần nhiều bữa hơn một chút. WHO khuyên 6–8 tháng ăn 2–3 bữa mỗi ngày. Những con số này chỉ là trung bình: bé tự biết lượng của mình, ba mẹ theo tín hiệu đói no của bé.',
          ),
          p(
            'Về độ thô, tháng đầu bé ăn bột, cháo nghiền mịn hoặc lợn cợn nhẹ, kèm vài que rau củ mềm để tự cầm. Từ 7–8 tháng, chuyển sang cháo nhừ không rây, thịt cá băm nhỏ, rau thái nhỏ, và NHS khuyến khích cho bé tập thức ăn cầm tay. Bộ Y tế, WHO và UNICEF đều nhấn mạnh đa dạng: qua một tuần, bé nên được ăn thịt, cá, trứng, đậu, nhiều loại rau và trái cây.',
          ),
          h('Khung một ngày gợi ý'),
          ul(
            'Sáng sớm: bú mẹ hoặc sữa công thức.',
            'Bữa ăn dặm thứ nhất (giữa buổi sáng): cháo hoặc bột, một món giàu sắt, một loại rau, thêm chút dầu ăn.',
            'Trưa và đầu giờ chiều: bú như thường, ngủ trưa.',
            'Bữa ăn dặm thứ hai (chiều): một món khác với bữa sáng; từ khoảng 7–8 tháng có thể thêm bữa thứ ba hoặc một bữa phụ trái cây nghiền.',
            'Tối và đêm: bú theo nhu cầu. Trong các bữa ăn dặm, cho bé nhấp vài ngụm nước đun sôi để nguội bằng cốc.',
          ),
          h('Gợi ý 7 ngày'),
          ul(
            'Thứ Hai: cháo bí đỏ thịt lợn nạc xay; chuối nghiền.',
            'Thứ Ba: cháo cá hồi gỡ xương với rau ngót; vài que khoai lang hấp để bé tự cầm.',
            'Thứ Tư: cháo trứng (lòng trắng và lòng đỏ chín kỹ) với cà rốt; bơ nghiền.',
            'Thứ Năm: cháo thịt bò bông cải xanh; đu đủ nghiền.',
            'Thứ Sáu: cháo đậu phụ cà chua (bỏ vỏ, bỏ hạt); một ít bơ đậu phộng mịn hoà loãng trộn vào cháo, vào buổi sáng nếu là lần đầu.',
            'Thứ Bảy: cháo thịt gà phần đùi với bí xanh; vài miếng xoài chín mềm.',
            'Chủ Nhật: cháo tôm băm nhỏ với mồng tơi; sữa chua nguyên kem không đường.',
          ),
          tip(
            'Đưa món dễ dị ứng vào tuần',
            'Trứng, đậu phộng dạng mịn, cá, tôm, lúa mì (mì sợi nấu mềm, bánh mì), đậu nành (đậu phụ), vừng xay mịn và sữa bò trong nấu ăn: mỗi lần chỉ thêm một món mới, vào buổi sáng hoặc trưa. Khi bé đã ăn được mà không có phản ứng, giữ món đó trong thực đơn ít nhất mỗi tuần một lần (ASCIA).',
          ),
          h('Ba mẹ có thể làm gì'),
          ul(
            'Nấu một mẻ cháo nền, chia phần, trữ đông rau củ nghiền và thịt cá xay theo viên để phối nhanh mỗi bữa.',
            'Lặp lại món bé thích là bình thường; xoay vòng nhóm đạm và rau qua tuần là đủ đa dạng.',
            'Mời lại món bé từng nhè ra vào những ngày sau, cạnh món bé đã quen.',
            'Không nêm muối, nước mắm, đường; không mật ong; sữa bò chỉ dùng trong nấu ăn.',
          ),
          h('Theo dõi'),
          ul(
            'Sức ăn tăng dần qua các tuần, và bé vẫn bú tốt.',
            'Độ thô: đến khoảng 7–8 tháng bé đã quen cháo nhừ, đồ băm nhỏ và vài miếng cầm tay chưa.',
            'Phân và mọi phản ứng sau món mới; ghi lại trong nhật ký ăn dặm.',
            'Cân nặng, chiều dài ở lần khám định kỳ.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            'Mỗi ngày phải đủ bảy, tám món khác nhau → Đa dạng tính theo cả tuần; lặp lại món quen là bình thường → Xoay vòng thịt, cá, trứng, đậu và các loại rau.',
            'Bé 6 tháng chỉ nên ăn rau củ, trái cây, thịt cá để sau → Bé cần sắt từ thịt, cá, trứng ngay từ đầu → Có món giàu sắt trong mỗi bữa.',
            'Bữa ăn dặm thay được cữ bú → Ở tuổi này sữa vẫn là nguồn chính, ăn dặm là bổ sung → Cho bú như trước, ăn dặm sau cữ bú hoặc giữa hai cữ.',
          ),
          urgent(
            'Gọi {emergency} ngay khi',
            'Sau khi ăn, bé khó thở, sưng môi, mặt hoặc lưỡi, nôn nhiều lần, hoặc da tái, lả đi.',
          ),
          doctor(
            'Khi nào nên hỏi bác sĩ',
            'Bé tăng cân chưa tốt; bé hay nôn, sặc khi ăn hoặc chưa ăn được đồ lợn cợn lúc gần 9 tháng; bé táo bón kéo dài; bé nổi mẩn, sưng môi hoặc nôn sau món mới; bé bị chàm nặng hoặc đã dị ứng một món.',
          ),
        ],
        en: [
          note(
            'In short',
            "This is an idea, not a fixed schedule. In the first weeks from 6 months: 1–2 small meals a day, building up to 2–3 meals, each from a few spoonfuls to about half a small bowl depending on your baby's appetite. Every day includes an iron-rich food and vegetables or fruit, with the common allergens added over time. Breast milk or formula is still the main source of nutrition.",
          ),
          h('Understanding menus at 6–8 months'),
          p(
            'UNICEF suggests breastfed babies start with 2–3 spoonfuls twice a day; by 6–8 months, about half a cup (a cup is about 250 ml) of soft food 2–3 times a day, plus a healthy snack such as mashed fruit. Babies who are not breastfed need slightly more meals. WHO advises 2–3 meals a day at 6–8 months. These numbers are only averages: your baby knows their own amount, and you follow their hunger and fullness cues.',
          ),
          p(
            "For texture, in the first month your baby eats cereal or porridge mashed smooth or slightly lumpy, with a few soft vegetable sticks to hold. From 7–8 months, move to soft unsieved porridge, minced meat and fish and finely chopped vegetables, and the NHS encourages finger foods. Việt Nam's Ministry of Health, WHO and UNICEF all stress variety: over a week, your baby should eat meat, fish, egg, beans and many kinds of vegetables and fruit.",
          ),
          h('A suggested day'),
          ul(
            'Early morning: breastfeed or formula.',
            'First solid meal (mid-morning): porridge or cereal, an iron-rich food, a vegetable and a little cooking oil.',
            'Midday and early afternoon: milk feeds as usual, a nap.',
            'Second solid meal (afternoon): a different dish from the morning; from about 7–8 months you can add a third meal or a snack of mashed fruit.',
            'Evening and night: milk feeds on demand. At solid meals, offer a few sips of boiled and cooled water from a cup.',
          ),
          h('A 7-day idea'),
          ul(
            'Monday: pumpkin porridge with finely blended lean pork; mashed banana.',
            'Tuesday: porridge with boned salmon and katuk (rau ngót); a few steamed sweet potato sticks to hold.',
            'Wednesday: egg porridge (white and yolk cooked solid) with carrot; mashed avocado.',
            'Thursday: beef and broccoli porridge; mashed papaya.',
            'Friday: tofu and tomato porridge (peeled, seeds removed); a little smooth peanut butter thinned and stirred into the porridge, in the morning if it is the first time.',
            'Saturday: chicken thigh porridge with winter melon; a few pieces of soft ripe mango.',
            'Sunday: finely minced shrimp porridge with Malabar spinach; plain full-fat yoghurt.',
          ),
          tip(
            'Fitting the common allergens into the week',
            "Egg, smooth peanut, fish, shrimp, wheat (soft-cooked noodles, bread), soy (tofu), finely ground sesame and cow's milk in cooking: add only one new food at a time, in the morning or at midday. Once your baby has eaten it with no reaction, keep it on the menu at least once a week (ASCIA).",
          ),
          h('What you can do'),
          ul(
            'Cook a batch of plain porridge, portion it, and freeze mashed vegetables and blended meat or fish in cubes so each meal comes together quickly.',
            'Repeating foods your baby likes is normal; rotating proteins and vegetables over the week gives plenty of variety.',
            'Offer foods your baby spat out again on later days, next to foods they know.',
            "No salt, fish sauce or sugar; no honey; cow's milk only in cooking.",
          ),
          h('What to watch'),
          ul(
            'Appetite growing over the weeks, while your baby still feeds well.',
            'Texture: by about 7–8 months, is your baby used to soft porridge, minced food and a few finger foods?',
            'Stools and any reaction after a new food; log them in the solids diary.',
            'Weight and length at the routine checkup.',
          ),
          h('Common myths'),
          ul(
            'Every day needs seven or eight different foods → Variety counts across the week; repeating familiar foods is normal → Rotate meat, fish, egg, beans and vegetables.',
            'At 6 months babies should have only vegetables and fruit, with meat and fish later → Babies need iron from meat, fish and egg from the start → Include an iron-rich food at every meal.',
            'Solid meals can replace milk feeds → At this age milk is still the main source and solids are an addition → Keep milk feeds as before and offer solids after or between feeds.',
          ),
          urgent(
            'Call {emergency} now if',
            'After eating, your baby has trouble breathing, swelling of the lips, face or tongue, repeated vomiting, or turns pale or limp.',
          ),
          doctor(
            'When to ask a doctor',
            'Your baby is not gaining weight well; often vomits or chokes when eating, or still cannot manage lumpy food as 9 months approaches; has ongoing constipation; gets a rash, swollen lips or vomiting after a new food; or has severe eczema or a known food allergy.',
          ),
        ],
      },
      keywords: t(
        [
          'thực đơn ăn dặm',
          'thực đơn 6 tháng',
          'thực đơn 7 tháng',
          'thực đơn 8 tháng',
          'thực đơn một tuần',
          'cháo',
          'món giàu sắt',
          'số bữa',
          'món dễ dị ứng',
          'gợi ý món ăn dặm',
        ],
        [
          'weaning menu',
          '6-month menu',
          '7-month menu',
          '8-month menu',
          'weekly menu',
          'rice porridge',
          'iron-rich foods',
          'number of meals',
          'common allergens',
          'meal ideas',
        ],
      ),
      relatedArticleIds: [
        'art_solids_menu_9_11',
        'art_solids_iron_foods',
        'art_allergen_intro',
        'art_solids_prep_storage',
      ],
      milestoneIds: [],
      sources: [
        S.unicef6to12,
        S.whoIycf,
        S.whoCf2023,
        S.mohCf2026,
        S.nhsFrom6Months,
        S.nhs7to9Months,
        S.asciaIntroSolids,
        S.whoDietaryDiversity,
      ],
    },
  },
  {
    id: 'art_solids_menu_9_11',
    reviewerLabel: NUTRITION,
    data: {
      library: 'solids',
      topic: 'feeding',
      subtopic: 'menus',
      format: 'article',
      ageWeeks: { from: 39, to: 52 },
      readingMinutes: 5,
      cover: null,
      title: t('Thực đơn mẫu cho bé 9–11 tháng', 'Sample menus for babies 9–11 months'),
      summary: t(
        'Bé 9–11 tháng ăn 3–4 bữa chính và 1–2 bữa phụ, chuyển sang cháo đặc, cơm nát, thức ăn cắt nhỏ và tự cầm. Một tuần thực đơn mẫu bằng món quen thuộc và cách cân bằng với sữa.',
        'At 9–11 months babies have 3–4 meals and 1–2 snacks and move on to thick porridge, soft rice, chopped food and finger foods. A sample week with familiar dishes and how to balance it with milk.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Từ 9 tháng, bé ăn 3–4 bữa chính, mỗi bữa khoảng nửa chén nhỏ, thêm 1–2 bữa phụ nếu cần. Thức ăn chuyển từ nghiền sang cắt nhỏ: cháo đặc, cơm nát, thịt cá băm, rau thái nhỏ, và có món cầm tay trong mỗi bữa. Bé vẫn bú mẹ hoặc bú sữa công thức. Đây là gợi ý, hãy điều chỉnh theo tín hiệu đói no của bé.',
          ),
          h('Hiểu đúng về bữa ăn 9–11 tháng'),
          p(
            'WHO khuyên trẻ 9–23 tháng ăn 3–4 bữa mỗi ngày, thêm 1–2 bữa phụ tuỳ nhu cầu. UNICEF gợi ý với bé bú mẹ, mỗi bữa khoảng nửa chén (chén khoảng 250 ml), 3–4 lần mỗi ngày, cùng một bữa phụ lành mạnh; bé không bú mẹ cần 4–5 bữa và 2 bữa phụ. Thức ăn mềm nên được cắt nhỏ thay vì nghiền, và bé được thử thức ăn cầm tay.',
          ),
          p(
            'Đây là giai đoạn bé tập nhặt miếng nhỏ bằng ngón cái và ngón trỏ, cầm thìa, uống bằng cốc. NHS khuyên đến 10–12 tháng, bé ăn ba bữa mỗi ngày với thức ăn cắt nhỏ, băm và thức ăn cầm tay, tiến gần đến món của gia đình. Sữa vẫn quan trọng nhưng lượng sữa giảm dần khi bé ăn được nhiều hơn.',
          ),
          h('Khung một ngày gợi ý'),
          ul(
            'Sáng: bú hoặc uống sữa, rồi bữa sáng như cháo, bánh mì mềm, trứng.',
            'Giữa buổi sáng: bữa phụ như trái cây mềm cắt miếng, sữa chua không đường.',
            'Trưa: bữa chính cùng gia đình, phần của bé múc ra trước khi nêm.',
            'Chiều: bú hoặc uống sữa; có thể thêm bữa phụ.',
            'Tối: bữa chính; bú trước khi ngủ. Cho bé uống nước đun sôi để nguội bằng cốc trong các bữa.',
          ),
          h('Gợi ý 7 ngày'),
          ul(
            'Thứ Hai: sáng cháo thịt bò cà rốt; trưa cơm nát, cá hồi hấp gỡ xương, bí đỏ; tối cháo đậu phụ rau cải.',
            'Thứ Ba: sáng bánh mì mềm và trứng chiên không nêm cắt dải; trưa cơm nát, thịt gà xé nhỏ, canh rau ngót; tối cháo tôm bông cải xanh.',
            'Thứ Tư: sáng cháo cá rô phi rau dền; trưa mì sợi nấu mềm với thịt lợn băm, cà chua; tối cháo trứng bí xanh.',
            'Thứ Năm: sáng cháo thịt lợn khoai lang; trưa cơm nát, đậu phụ sốt cà chua ít nêm, rau luộc thái nhỏ; tối cháo cua mồng tơi.',
            'Thứ Sáu: sáng yến mạch nấu sữa công thức hoặc sữa mẹ với chuối; trưa cơm nát, cá mòi gỡ xương, bí đỏ; tối cháo thịt bò rau cải.',
            'Thứ Bảy: sáng cháo gà nấm; trưa bún mềm cắt ngắn với thịt viên hấp mềm; tối cháo đậu xanh thịt băm.',
            'Chủ Nhật: sáng trứng hấp mềm và bánh mì que; trưa cơm nát, tôm băm, canh bí; tối cháo cá hồi rau ngót.',
          ),
          tip(
            'Bữa phụ lành mạnh',
            'Bữa phụ tuỳ nhu cầu của bé: WHO và UNICEF gợi ý 1–2 bữa phụ, còn NHS cho rằng bé dưới 1 tuổi chưa cần, bé đói giữa các bữa thì cho bú thêm. Nếu cho, hãy chọn: chuối, bơ, đu đủ, xoài, lê chín cắt miếng mềm; sữa chua nguyên kem không đường; phô mai làm từ sữa thanh trùng; khoai lang hấp; bánh mì que phết mỏng bơ đậu phộng mịn. Hạn chế bánh quy ngọt, bánh gạo mặn, váng sữa ngọt và đồ ăn vặt đóng gói.',
          ),
          h('Ba mẹ có thể làm gì'),
          ul(
            'Có thức ăn cầm tay trong mỗi bữa: que rau củ mềm, miếng trứng, đậu phụ, cá gỡ xương, thịt viên mềm.',
            'Cho bé thìa riêng để tự xúc; người lớn đút hỗ trợ khi bé mệt.',
            'Cho bé ngồi ăn cùng cả nhà, tắt tivi, cất điện thoại.',
            'Sữa: bé bú mẹ tiếp tục theo nhu cầu; với bé bú bình, NHS gợi ý khoảng 400 ml sữa công thức mỗi ngày ở 10–12 tháng. Uống quá nhiều sữa dễ làm bé ăn ít đi.',
            'Vẫn không nêm muối, đường; không mật ong; nho, cà chua bi cắt dọc làm tư; không hạt nguyên.',
          ),
          h('Theo dõi'),
          ul(
            'Bé đã nhai được đồ cắt nhỏ, cơm nát chưa; oẹ nhiều với mọi miếng thô cần hỏi bác sĩ.',
            'Bé tự cầm, tự xúc tiến bộ dần.',
            'Đủ nhóm thực phẩm qua tuần: tinh bột, thịt cá trứng, đậu, sữa và chế phẩm, rau quả.',
            'Cân nặng, chiều dài ở lần khám tròn 1 tuổi.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            'Phải ăn cháo đến 1 tuổi mới được ăn cơm → Nhiều bé 9–11 tháng nhai được cơm nát nấu mềm → Thử cơm nát hoặc cháo đặc hạt nguyên khi bé đã quen đồ băm.',
            'Bé ăn ít bữa chính thì cho uống sữa thật nhiều cho đủ → Uống nhiều sữa làm bé càng ít đói khi đến bữa → Giữ lượng sữa vừa phải, bữa ăn đúng giờ.',
            'Bánh quy, bánh gạo, váng sữa là bữa phụ tốt cho bé → Nhiều loại có đường hoặc muối → Ưu tiên trái cây, sữa chua không đường, khoai củ hấp.',
          ),
          urgent(
            'Gọi {emergency} ngay khi',
            'Bé hóc không ho được, khó thở, sưng môi, mặt hoặc lưỡi, nôn nhiều lần, hoặc da tái, lả đi sau khi ăn.',
          ),
          doctor(
            'Khi nào nên hỏi bác sĩ',
            'Bé tăng cân chưa tốt; gần 1 tuổi mà bé vẫn chỉ ăn được đồ xay mịn, hay nôn hoặc sặc khi gặp miếng nhỏ; bé từ chối cả một nhóm thực phẩm lớn; bé nổi mẩn, sưng môi hoặc nôn sau món mới.',
          ),
        ],
        en: [
          note(
            'In short',
            "From 9 months, babies have 3–4 meals, each about half a small bowl, plus 1–2 snacks if needed. Food moves from mashed to chopped: thick porridge, soft rice, minced meat and fish, finely chopped vegetables, and a finger food at every meal. Your baby still breastfeeds or has formula. This is a suggestion; adjust it to your baby's hunger and fullness cues.",
          ),
          h('Understanding meals at 9–11 months'),
          p(
            'WHO advises 3–4 meals a day for children 9–23 months, plus 1–2 snacks as needed. UNICEF suggests that breastfed babies have about half a cup (a cup is about 250 ml) per meal, 3–4 times a day, with a healthy snack; babies who are not breastfed need 4–5 meals and 2 snacks. Soft foods should be chopped rather than mashed, and babies get to try finger foods.',
          ),
          p(
            'This is when babies practice picking up small pieces between thumb and forefinger, holding a spoon and drinking from a cup. The NHS says that by 10–12 months babies eat three meals a day of chopped, minced and finger foods, getting closer to family meals. Milk still matters, but the amount gradually falls as your baby eats more.',
          ),
          h('A suggested day'),
          ul(
            'Morning: a breastfeed or milk, then breakfast such as porridge, soft bread or egg.',
            'Mid-morning: a snack such as soft fruit pieces or plain yoghurt.',
            "Lunch: a main meal with the family, with your baby's portion taken out before seasoning.",
            'Afternoon: a breastfeed or milk; a snack if needed.',
            'Evening: a main meal; a feed before bed. Offer boiled and cooled water from a cup at meals.',
          ),
          h('A 7-day idea'),
          ul(
            'Monday: breakfast beef and carrot porridge; lunch soft rice, steamed boned salmon, pumpkin; dinner tofu and leafy green porridge.',
            'Tuesday: breakfast soft bread and unseasoned omelette strips; lunch soft rice, shredded chicken, katuk soup; dinner shrimp and broccoli porridge.',
            'Wednesday: breakfast tilapia and amaranth porridge; lunch soft-cooked noodles with minced pork and tomato; dinner egg and winter melon porridge.',
            'Thursday: breakfast pork and sweet potato porridge; lunch soft rice, lightly seasoned tofu in tomato sauce, finely chopped boiled vegetables; dinner crab and Malabar spinach porridge.',
            'Friday: breakfast oats cooked with formula or breast milk and banana; lunch soft rice, boned sardines, pumpkin; dinner beef and leafy green porridge.',
            'Saturday: breakfast chicken and mushroom porridge; lunch soft rice vermicelli cut short with soft steamed meatballs; dinner mung bean and minced pork porridge.',
            'Sunday: breakfast soft steamed egg and toast fingers; lunch soft rice, minced shrimp, squash soup; dinner salmon and katuk porridge.',
          ),
          tip(
            'Healthy snacks',
            'Snacks depend on your baby: WHO and UNICEF suggest 1–2 snacks, while the NHS says babies under 1 do not need them and a hungry baby between meals can have an extra milk feed. If you offer one, choose banana, avocado, papaya, mango or ripe pear in soft pieces; plain full-fat yoghurt; pasteurized cheese; steamed sweet potato; toast fingers with a thin spread of smooth peanut butter. Limit sweet biscuits, salty rice crackers, sweet dairy desserts and packaged snacks.',
          ),
          h('What you can do'),
          ul(
            'Include a finger food at every meal: soft vegetable sticks, pieces of egg, tofu, boned fish, soft meatballs.',
            'Give your baby their own spoon to feed themselves; adults help out when your baby is tired.',
            'Seat your baby at the family meal, with the TV off and phones away.',
            'Milk: breastfed babies keep feeding on demand; for bottle-fed babies, the NHS suggests about 400 ml of formula a day at 10–12 months. Drinking too much milk easily makes babies eat less.',
            'Still no salt or sugar; no honey; grapes and cherry tomatoes cut lengthwise into quarters; no whole nuts.',
          ),
          h('What to watch'),
          ul(
            "Whether your baby can chew chopped food and soft rice; a lot of gagging on every lumpy piece needs a doctor's advice.",
            'Steady progress with self-feeding by hand and spoon.',
            'All the food groups over the week: starches, meat, fish and egg, beans, milk and dairy, vegetables and fruit.',
            'Weight and length at the 1-year checkup.',
          ),
          h('Common myths'),
          ul(
            'Babies must eat porridge until 1 before they can have rice → Many babies of 9–11 months can chew soft-cooked rice → Try soft rice or thick whole-grain porridge once your baby manages minced food.',
            'If the baby eats little at meals, give lots of milk to make up → Lots of milk makes babies even less hungry at mealtimes → Keep milk moderate and meals at regular times.',
            'Biscuits, rice crackers and sweet dairy desserts are good snacks → Many contain sugar or salt → Choose fruit, plain yoghurt and steamed root vegetables.',
          ),
          urgent(
            'Call {emergency} now if',
            'Your baby is choking and cannot cough, has trouble breathing, swelling of the lips, face or tongue, repeated vomiting, or turns pale or limp after eating.',
          ),
          doctor(
            'When to ask a doctor',
            'Your baby is not gaining weight well; is nearly 1 and still manages only smooth food, or often vomits or chokes on small pieces; refuses a whole major food group; or gets a rash, swollen lips or vomiting after a new food.',
          ),
        ],
      },
      keywords: t(
        [
          'thực đơn ăn dặm',
          'thực đơn 9 tháng',
          'thực đơn 10 tháng',
          'thực đơn 11 tháng',
          'cơm nát',
          'cháo đặc',
          'bữa phụ',
          'thức ăn cầm tay',
          'tự xúc',
          'lượng sữa',
        ],
        [
          'weaning menu',
          '9-month menu',
          '10-month menu',
          '11-month menu',
          'soft rice',
          'thick porridge',
          'snacks',
          'finger foods',
          'self-feeding',
          'milk amount',
        ],
      ),
      relatedArticleIds: [
        'art_solids_menu_6_8',
        'art_solids_finger_foods',
        'art_solids_family_meals',
        'art_solids_textures_by_month',
      ],
      milestoneIds: [],
      sources: [
        S.unicef6to12,
        S.whoIycf,
        S.whoCf2023,
        S.mohCf2026,
        S.nhs7to9Months,
        S.nhs10to12Months,
        S.whoDietaryDiversity,
        S.nhsDrinksCups,
      ],
    },
  },
  // ----- Kỹ năng ăn (eating skills) -----
  {
    id: 'art_solids_finger_foods',
    reviewerLabel: NUTRITION,
    data: {
      library: 'solids',
      topic: 'feeding',
      subtopic: 'skills',
      format: 'step_guide',
      ageWeeks: { from: 26, to: 78 },
      readingMinutes: 5,
      cover: null,
      title: t(
        'Thức ăn cầm tay: bắt đầu thế nào, cắt ra sao',
        'Finger foods: how to start and how to cut them',
      ),
      summary: t(
        'Thức ăn cầm tay giúp bé luyện nhai, phối hợp tay và miệng, và tự ăn. Từng bước chọn món, cắt đúng hình dạng theo tháng tuổi, và giữ an toàn khi bé tự ăn.',
        'Finger foods help your baby practice chewing, hand-to-mouth coordination and feeding themselves. Step by step: choosing foods, cutting them to the right shape for each age, and keeping self-feeding safe.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Từ 6 tháng, bé có thể cầm những que thức ăn mềm dài cỡ ngón tay người lớn; từ khoảng 9 tháng, chuyển sang miếng nhỏ cỡ hạt đậu để bé nhặt bằng hai ngón. Mọi món đều phải bóp nát được dễ dàng giữa ngón cái và ngón trỏ. Nho, cà chua bi cắt dọc làm tư; không hạt nguyên, không bỏng ngô. Luôn ngồi cạnh bé khi bé ăn.',
          ),
          h('Hiểu đúng về thức ăn cầm tay'),
          p(
            'Tự cầm thức ăn giúp bé luyện cắn, nhai, phối hợp mắt, tay và miệng, và tự quyết định ăn bao nhiêu. NHS khuyến khích cho bé thức ăn cầm tay ngay từ khi bắt đầu ăn dặm, dù bé ăn bằng thìa hay tự ăn. Bé không cần có răng: lợi của bé đủ cứng để nghiền thức ăn mềm.',
          ),
          p(
            'Cách bé cầm thay đổi theo tuổi. Khoảng 6–8 tháng, bé nắm cả bàn tay, nên que dài dễ cầm hơn, phần thò ra khỏi nắm tay là phần bé gặm. Khoảng 9–12 tháng, bé bắt đầu nhặt bằng ngón cái và ngón trỏ, nên miếng nhỏ, mềm trở nên phù hợp. Oẹ khi tập ăn là bình thường; hóc thì im lặng và cần sơ cứu ngay.',
          ),
          h('Ba mẹ có thể làm gì: từng bước'),
          ul(
            'Bước 1 · Kiểm tra tư thế: bé ngồi thẳng trên ghế ăn có đai, không ngả, không nằm; người lớn ngồi cạnh suốt bữa.',
            'Bước 2 · Chọn món mềm: rau củ hấp như cà rốt, bí đỏ, khoai lang, bông cải xanh (để cuống làm tay cầm); trái cây chín mềm như chuối, bơ, đu đủ, xoài, lê chín; trứng luộc chín kỹ; đậu phụ; cá đã gỡ xương; thịt nấu mềm xé sợi hoặc viên hấp mềm; bánh mì nướng que; mì sợi nấu mềm.',
            'Bước 3 · Thử độ mềm: đặt miếng thức ăn giữa ngón cái và ngón trỏ rồi bóp nhẹ; phải nát dễ dàng. Nếu phải dùng lực, hãy nấu thêm.',
            'Bước 4 · Cắt theo tuổi, 6–8 tháng: que dài cỡ ngón tay người lớn, đủ dày để bé nắm. Chuối có thể bóc bớt vỏ làm tay cầm; bơ cắt lát dày, lăn qua bột yến mạch xay hoặc vừng xay mịn (khi bé đã quen vừng) cho đỡ trơn.',
            'Bước 5 · Cắt theo tuổi, từ khoảng 9 tháng: miếng nhỏ, mềm cỡ hạt đậu hoặc đầu ngón tay để bé tập nhặt bằng hai ngón; vẫn có thể cho que mềm.',
            'Bước 6 · Món tròn, trơn: nho, cà chua bi, nhãn, vải, chôm chôm phải bỏ hạt và cắt dọc làm tư hoặc nhỏ hơn. Xúc xích nên hạn chế vì mặn; nếu cho thì cắt dọc rồi thái nhỏ, không cắt khoanh tròn.',
            'Bước 7 · Món cần tránh: hạt nguyên, bỏng ngô, rau sống cứng như cà rốt sống, táo sống cắt miếng (hấp mềm hoặc nạo nhỏ thay thế), kẹo, thạch cốc, xôi dẻo miếng to.',
            'Bước 8 · Bày cho bé: đặt 2–3 miếng lên khay để bé tự chọn và tự đưa vào miệng. Không nhét thức ăn vào miệng bé, không cho ăn khi bé đang khóc, nằm hoặc chơi.',
            'Bước 9 · Khi bé oẹ: bình tĩnh, không thò tay vào miệng bé. Oẹ ồn ào, ho là bé đang tự xử lý. Nếu bé không ho được, không khóc, không thở được, gọi cấp cứu {emergency} và sơ cứu theo mục Sơ cứu trẻ em › Hóc dị vật.',
            'Bước 10 · Kết hợp với thìa: vừa cho bé cầm vừa đút cháo là cách nhiều gia đình chọn; ghi lại món và cách cắt bé đã làm quen.',
          ),
          tip(
            'Món cầm tay kiểu Việt dễ làm',
            'Que khoai lang, bí đỏ, cà rốt hấp mềm; trứng chiên không nêm cắt dải; bánh mì nướng que phết mỏng bơ đậu phộng mịn; viên thịt lợn hoặc thịt bò hấp mềm; cá hấp gỡ xương miếng to; đậu phụ hấp cắt que; chuối hấp; bông cải xanh hấp; đu đủ, xoài chín. Từ khoảng 9 tháng có thể thêm cơm tẻ nắm thành viên nhỏ, mềm.',
          ),
          h('Theo dõi'),
          ul(
            'Bé cầm và đưa thức ăn vào miệng ngày càng khéo; khoảng 9–12 tháng bắt đầu nhặt bằng hai ngón.',
            'Oẹ thường giảm dần sau vài tuần; nôn hoặc sặc thường xuyên cần hỏi bác sĩ.',
            'Những món bé xử lý tốt và những món còn khó; ghi lại để điều chỉnh độ mềm và cách cắt.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            'Chưa có răng thì chưa ăn được miếng → Lợi nghiền được thức ăn mềm → Cho que mềm từ 6 tháng.',
            'Cắt thật nhỏ ngay từ đầu cho an toàn → Bé 6 tháng chưa nhặt được miếng nhỏ, que dài dễ cầm hơn; miếng nhỏ mà cứng vẫn nguy hiểm → Độ mềm là quan trọng nhất, hình dạng theo tuổi.',
            'Bánh quy ăn dặm là thức ăn cầm tay tốt nhất → Nhiều loại có đường; NHS khuyên tránh bánh quy, bánh ăn dặm nhiều đường → Ưu tiên rau củ, trái cây, trứng, cá mềm.',
          ),
          urgent(
            'Gọi {emergency} ngay khi',
            'Bé ho không ra tiếng, không khóc, không thở được hoặc tím tái. Trong lúc chờ, làm theo mục Sơ cứu trẻ em › Hóc dị vật trong Child Life.',
          ),
          doctor(
            'Khi nào nên hỏi bác sĩ',
            'Bé thường xuyên nôn, ho sặc khi ăn; gần 9–10 tháng mà bé vẫn chưa tự đưa thức ăn vào miệng hoặc chưa ăn được miếng mềm nào; sau một lần hóc, bé vẫn ho, khò khè hoặc thở nhanh.',
          ),
        ],
        en: [
          note(
            'In short',
            'From 6 months, babies can hold soft sticks of food about the length of an adult finger; from about 9 months, move to small pea-sized pieces they can pick up with two fingers. Every food must squash easily between your thumb and forefinger. Cut grapes and cherry tomatoes lengthwise into quarters; no whole nuts, no popcorn. Always sit with your baby while they eat.',
          ),
          h('Understanding finger foods'),
          p(
            "Holding food helps babies practice biting and chewing, coordinate eyes, hands and mouth, and decide for themselves how much to eat. The NHS encourages finger foods from the start of solids, whether your baby is spoon-fed or feeds themselves. Babies don't need teeth: their gums are firm enough to mash soft food.",
          ),
          p(
            'How babies grasp changes with age. At about 6–8 months they grab with the whole hand, so long sticks are easier to hold, and the part sticking out of the fist is the part they gnaw. At about 9–12 months they start picking things up between thumb and forefinger, so small soft pieces become suitable. Gagging while learning is normal; choking is silent and needs first aid right away.',
          ),
          h('What you can do: step by step'),
          ul(
            'Step 1 · Check the position: your baby sits upright in a high chair with a harness, not reclining or lying down; an adult sits alongside for the whole meal.',
            'Step 2 · Choose soft foods: steamed vegetables such as carrot, pumpkin, sweet potato, broccoli (leave the stalk as a handle); soft ripe fruit such as banana, avocado, papaya, mango, ripe pear; well-cooked hard-boiled egg; tofu; boned fish; meat cooked tender and shredded, or soft steamed meatballs; toast fingers; soft-cooked noodles.',
            'Step 3 · Test the softness: place a piece between your thumb and forefinger and press gently; it should squash easily. If you need to press hard, cook it longer.',
            'Step 4 · Cut for age, 6–8 months: sticks about the length of an adult finger, thick enough for your baby to grip. Leave some peel on a banana as a handle; cut avocado into thick slices and roll them in ground oats or finely ground sesame (once your baby has had sesame) so they are less slippery.',
            'Step 5 · Cut for age, from about 9 months: small soft pieces the size of a pea or a fingertip for your baby to practice picking up with two fingers; soft sticks are still fine.',
            'Step 6 · Round, slippery foods: grapes, cherry tomatoes, longan, lychee and rambutan must have the seed removed and be cut lengthwise into quarters or smaller. Limit sausages because they are salty; if you give them, cut lengthwise and then into small pieces, never round slices.',
            'Step 7 · Foods to avoid: whole nuts, popcorn, hard raw vegetables such as raw carrot, raw apple pieces (steam them soft or grate them instead), sweets, jelly cups, large pieces of sticky rice.',
            "Step 8 · Serve: put 2–3 pieces on the tray and let your baby choose and bring them to their mouth. Never push food into your baby's mouth, and don't feed them while they are crying, lying down or playing.",
            "Step 9 · When your baby gags: stay calm and don't put your fingers in their mouth. Noisy gagging and coughing mean your baby is dealing with it. If they cannot cough, cry or breathe, call {emergency} and give first aid following the Sơ cứu trẻ em › Choking guide.",
            'Step 10 · Combine with the spoon: offering finger foods while spoon-feeding porridge is what many families do; note the foods and cuts your baby has got used to.',
          ),
          tip(
            'Easy Vietnamese-style finger foods',
            'Soft steamed sweet potato, pumpkin or carrot sticks; unseasoned omelette strips; toast fingers with a thin spread of smooth peanut butter; soft steamed pork or beef meatballs; large flakes of boned steamed fish; steamed tofu fingers; steamed banana; steamed broccoli; ripe papaya or mango. From about 9 months you can add small, soft balls of plain cooked rice.',
          ),
          h('What to watch'),
          ul(
            'Your baby gets better at holding food and bringing it to the mouth; at about 9–12 months they start picking up with two fingers.',
            "Gagging usually eases after a few weeks; frequent vomiting or choking needs a doctor's advice.",
            'Which foods your baby manages well and which are still hard; note them to adjust softness and cutting.',
          ),
          h('Common myths'),
          ul(
            'No teeth means no pieces → Gums can mash soft food → Offer soft sticks from 6 months.',
            'Cut everything tiny from the start to be safe → At 6 months babies cannot pick up tiny pieces and long sticks are easier to hold; small pieces that are hard are still dangerous → Softness matters most, with the shape matched to age.',
            'Baby biscuits are the best finger food → Many contain sugar; the NHS advises avoiding sugary biscuits and rusks → Choose vegetables, fruit, egg and soft fish.',
          ),
          urgent(
            'Call {emergency} now if',
            'Your baby cannot cough out loud, cannot cry or breathe, or turns blue. While you wait, follow the Choking steps in the Sơ cứu trẻ em (First aid) guide in Child Life.',
          ),
          doctor(
            'When to ask a doctor',
            'Your baby often vomits, coughs or chokes when eating; is nearly 9–10 months and still does not bring food to the mouth or manage any soft pieces; or keeps coughing, wheezing or breathing fast after a choking episode.',
          ),
        ],
      },
      keywords: t(
        [
          'thức ăn cầm tay',
          'cắt thức ăn',
          'que rau củ',
          'tự ăn',
          'nhặt bằng hai ngón',
          'oẹ',
          'hóc',
          'nho cắt tư',
          'BLW',
          'món cầm tay',
        ],
        [
          'finger foods',
          'cutting food',
          'vegetable sticks',
          'self-feeding',
          'pincer grasp',
          'gagging',
          'choking',
          'quartered grapes',
          'baby-led weaning',
          'finger food ideas',
        ],
      ),
      relatedArticleIds: [
        'art_solids_choking_safety',
        'art_solids_methods',
        'art_solids_menu_9_11',
        'art_solids_textures_by_month',
      ],
      milestoneIds: [],
      sources: [
        S.nhsChokingGagging,
        S.nhsFirstSolids,
        S.nhs7to9Months,
        S.nhs10to12Months,
        S.nhsHowToStart,
        S.cdcChokingHazards,
        S.hcChokingPrevention,
        S.fangupoBliss2016,
      ],
    },
  },
  {
    id: 'art_solids_refusal',
    reviewerLabel: NUTRITION,
    data: {
      library: 'solids',
      topic: 'feeding',
      subtopic: 'skills',
      format: 'article',
      ageWeeks: { from: 26, to: 104 },
      readingMinutes: 4,
      cover: null,
      title: t(
        'Bé từ chối món mới: kiên nhẫn 8–15 lần',
        'When your baby refuses a new food: patience for 8 to 15 tries',
      ),
      summary: t(
        'Từ chối món mới là chuyện bình thường. Vì sao nhiều bé cần được mời 8–15 lần mới chịu ăn, cách mời lại mà không tạo áp lực, và những việc nên tránh như ép, dỗ, đổi món liên tục.',
        'Refusing new foods is normal. Why many babies need a food offered 8 to 15 times before they accept it, how to keep offering without pressure, and what to avoid, such as forcing, bribing or switching foods all the time.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Nhăn mặt, lè lưỡi hay nhè món mới ra không có nghĩa là bé ghét món đó. Nhiều bé cần nếm một món khoảng 8–10 lần, có bé tới 15 lần hoặc hơn, mới quen vị. Hãy mời lại món đó vào nhiều ngày khác nhau, lượng nhỏ, đặt cạnh món bé thích, ăn cùng bé, không ép và không thưởng bằng bánh kẹo.',
          ),
          h('Hiểu đúng vì sao bé từ chối'),
          p(
            'Trẻ nhỏ thường dè dặt với vị và kết cấu lạ, nhất là vị đắng, chua của rau xanh. Đây là phản ứng tự nhiên giúp trẻ cẩn thận với thứ chưa biết, và thường giảm đi khi món đó trở nên quen thuộc. Bé cũng có thể từ chối vì đang no, mệt, mọc răng, ốm, hoặc vì miếng ăn quá khó nhai.',
          ),
          p(
            'Một tổng quan hệ thống của Spill và cộng sự (2019) gồm 21 nghiên cứu cho thấy cho trẻ dưới 2 tuổi nếm một loại rau hoặc trái cây mỗi ngày trong khoảng 8–10 ngày trở lên giúp trẻ chấp nhận món đó nhiều hơn. NHS và AAP cũng cho biết bé có thể cần được mời 10 lần trở lên mới chịu một món, một vị hay một kết cấu mới.',
          ),
          p(
            'Ngược lại, ép ăn, dỗ dành hay ra điều kiện thường phản tác dụng. AAP lưu ý ép hoặc phạt có thể khiến trẻ ghét món đó hơn, còn dùng bánh kẹo làm phần thưởng khiến bánh kẹo hấp dẫn hơn và món lành mạnh kém hấp dẫn đi.',
          ),
          h('Ba mẹ có thể làm gì'),
          ul(
            'Mời lại cùng một món vào nhiều ngày khác nhau; mỗi lần một hai thìa hoặc vài miếng là đủ.',
            'Đặt món mới cạnh món bé đã thích, hoặc trộn với món quen như cháo, khoai, một chút sữa mẹ (UNICEF).',
            'Đổi cách chế biến: nghiền, hấp thành que, nướng mềm, nấu canh, trộn cháo (NHS).',
            'Ba mẹ ăn cùng và ăn ngon lành chính món đó trước mặt bé; bé học bằng cách bắt chước.',
            'Cho bé chạm, bóp, ngửi, chơi với thức ăn; đó cũng là một bước làm quen.',
            'Bé từ chối thì bình tĩnh dọn đi, không đổi ngay sang món bé thích và không nấu riêng nhiều món theo ý bé.',
            'Khen nhẹ nhàng khi bé thử, dù chỉ một miếng nhỏ; không la mắng, không so sánh với bé khác.',
            'Giữ giờ ăn đều, hạn chế ăn vặt và uống sữa ngay sát bữa để bé đến bữa đủ đói.',
            'Ghi số lần đã mời món đó trong nhật ký ăn dặm để cả nhà cùng kiên nhẫn.',
          ),
          tip(
            'Bé đang ăn tốt bỗng từ chối',
            'Mọc răng, ốm, mệt, đi tiêm chủng, thay đổi người trông, hay giai đoạn bé mải tập bò, tập đi đều có thể làm bé ăn kém vài ngày. Tạm thời mời những món bé quen, giữ bữa ăn nhẹ nhàng, rồi mời lại món mới khi bé khỏe.',
          ),
          h('Theo dõi'),
          ul(
            'Qua một tuần, bé có ăn được món từ nhiều nhóm: tinh bột, thịt cá trứng hoặc đậu, sữa và chế phẩm, rau quả.',
            'Cân nặng, chiều dài theo biểu đồ ở các lần khám.',
            'Bé từ chối cả một nhóm thực phẩm lớn, chỉ ăn rất ít món, hoặc oẹ, nôn với mọi thức ăn thô.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            'Bé nhè ra hai ba lần là không hợp, bỏ hẳn món đó → Nhiều bé cần 8–15 lần mới quen → Tiếp tục mời lượng nhỏ vào những ngày sau.',
            'Trộn lẫn hết vào cháo để bé không nhận ra → Có thể giúp bé ăn đủ, nhưng bé cũng cần nhận ra từng vị để học thích → Xen kẽ: lúc trộn, lúc để riêng từng món.',
            'Bế đi rong, bật điện thoại cho bé ăn được nhiều → Bé ăn mà không chú ý đến món ăn, không học thích món đó và dễ sặc → Ngồi ăn tại bàn, cả nhà ăn cùng.',
            'Thưởng bánh kẹo nếu bé chịu ăn rau → Bánh kẹo trở nên hấp dẫn hơn, rau kém hấp dẫn đi → Khen bằng lời, dùng phần thưởng không phải đồ ăn.',
          ),
          urgent('Gọi {emergency} ngay khi', 'Bé khó thở, tím tái hoặc lả đi khi đang ăn.'),
          doctor(
            'Khi nào nên hỏi bác sĩ',
            'Bé sụt cân hoặc không tăng cân; bé chỉ chấp nhận rất ít món hoặc từ chối cả một nhóm thực phẩm lớn trong thời gian dài; bé đau, khóc khi ăn, hay nôn, ho sặc hoặc khó nuốt; bé gần 1 tuổi mà vẫn chỉ ăn được đồ xay mịn.',
          ),
        ],
        en: [
          note(
            'In short',
            "Grimacing, pushing the tongue out or spitting out a new food doesn't mean your baby dislikes it. Many babies need to taste a food about 8–10 times, some 15 times or more, before they get used to it. Offer it again on different days, in small amounts, next to foods your baby likes; eat with your baby, never force, and don't reward with sweets.",
          ),
          h('Understanding why babies refuse'),
          p(
            'Young children are often wary of unfamiliar tastes and textures, especially the bitter and sour tastes of green vegetables. This is a natural reaction that makes children careful with the unknown, and it usually fades as the food becomes familiar. Babies may also refuse because they are full, tired, teething or unwell, or because the piece is too hard to chew.',
          ),
          p(
            'A systematic review by Spill and colleagues (2019) of 21 studies found that letting children under 2 taste a vegetable or fruit once a day for about 8–10 days or more increases their acceptance of it. The NHS and the AAP also say a baby may need to be offered a new food, flavor or texture 10 or more times before accepting it.',
          ),
          p(
            'On the other hand, forcing, coaxing or bargaining usually backfires. The AAP notes that forcing or punishing can make children dislike a food more, and using sweets as a reward makes sweets more appealing and healthy foods less so.',
          ),
          h('What you can do'),
          ul(
            'Offer the same food again on different days; a spoonful or two or a few pieces each time is enough.',
            'Put the new food next to one your baby likes, or mix it with a familiar food such as porridge, potato or a little breast milk (UNICEF).',
            'Change how you prepare it: mashed, steamed sticks, soft roasted, in a soup, stirred into porridge (NHS).',
            'Eat the same food with your baby and clearly enjoy it; babies learn by copying.',
            'Let your baby touch, squeeze, smell and play with the food; that is also part of getting used to it.',
            'If your baby refuses, calmly take it away, without switching straight to a favorite food or cooking several dishes to order.',
            'Praise gently when your baby tries, even a small bite; no scolding and no comparing with other babies.',
            'Keep regular mealtimes and limit snacks and milk right before meals so your baby comes to the table hungry enough.',
            'Note how many times you have offered the food in the solids diary so the whole family can be patient together.',
          ),
          tip(
            'A good eater suddenly refuses',
            'Teething, illness, tiredness, vaccinations, a change of carer, or a phase of busy crawling or walking can all make a baby eat less for a few days. Offer familiar foods for now, keep meals relaxed, and bring the new food back once your baby is well.',
          ),
          h('What to watch'),
          ul(
            'Over a week, does your baby eat from many groups: starches, meat, fish, egg or beans, milk and dairy, vegetables and fruit?',
            'Weight and length on the growth chart at checkups.',
            'Your baby refuses a whole major food group, eats only a very few foods, or gags or vomits with every lumpy food.',
          ),
          h('Common myths'),
          ul(
            'If the baby spits it out two or three times, it does not suit them, so drop it → Many babies need 8–15 tries to get used to a food → Keep offering small amounts on later days.',
            'Hide everything in the porridge so the baby cannot tell → This can help your baby eat enough, but babies also need to recognize each taste to learn to like it → Alternate: sometimes mixed, sometimes each food on its own.',
            'Carrying the baby around or putting on a phone gets more food in → Your baby eats without paying attention to the food, does not learn to like it and chokes more easily → Eat sitting at the table, together as a family.',
            'Rewarding vegetables with sweets → Sweets become more appealing and vegetables less → Praise with words and use non-food rewards.',
          ),
          urgent(
            'Call {emergency} now if',
            'Your baby has trouble breathing, turns blue or goes limp while eating.',
          ),
          doctor(
            'When to ask a doctor',
            'Your baby loses weight or does not gain; accepts only a very few foods or refuses a whole major food group for a long time; has pain or cries when eating, often vomits, chokes or struggles to swallow; or is nearly 1 and still manages only smooth food.',
          ),
        ],
      },
      keywords: t(
        [
          'từ chối món mới',
          'bé không chịu ăn',
          'kén ăn',
          'nhè thức ăn',
          'mời lại nhiều lần',
          'rau xanh',
          'ép ăn',
          'dỗ ăn',
          'ăn cùng bé',
          'biếng ăn',
        ],
        [
          'refusing new foods',
          'baby will not eat',
          'fussy eating',
          'spitting out food',
          'repeated tasting',
          'green vegetables',
          'forcing food',
          'coaxing',
          'eating together',
          'poor appetite',
        ],
      ),
      relatedArticleIds: [
        'art_picky_eating_toddler',
        'art_solids_hunger_fullness',
        'art_solids_methods',
        'art_solids_family_meals',
      ],
      milestoneIds: [],
      sources: [
        S.spillExposure2019,
        S.nhsFirstSolids,
        S.nhsFussyEaters,
        S.hcPickyEaters,
        S.unicef6to12,
        S.cdcHungryFull,
        S.whoCf2023,
      ],
    },
  },
  // ----- Khi bé không khoẻ (when baby is unwell) -----
  {
    id: 'art_solids_constipation',
    reviewerLabel: NUTRITION,
    data: {
      library: 'solids',
      topic: 'feeding',
      subtopic: 'health',
      format: 'article',
      ageWeeks: { from: 22, to: 104 },
      readingMinutes: 4,
      cover: null,
      title: t('Táo bón khi bắt đầu ăn dặm', 'Constipation when starting solids'),
      summary: t(
        'Phân thay đổi khi bé bắt đầu ăn dặm là bình thường. Cách nhận biết táo bón, món ăn và đồ uống giúp phân mềm hơn, những cách dân gian nên tránh và khi nào cần đưa bé đi khám.',
        'Stools change when babies start solids, and that is normal. How to recognize constipation, foods and drinks that help soften stools, folk remedies to avoid and when to take your baby to the doctor.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Khi ăn dặm, phân bé thường đặc hơn, đổi màu và mùi; như vậy chưa phải táo bón. Táo bón là khi phân cứng, vón cục, bé rặn đau, hoặc đi ít hơn 3 lần mỗi tuần kèm phân cứng. Thêm rau, trái cây như mận, lê, đu đủ, khoai lang vào các bữa, cho bé nhấp nước bằng cốc trong bữa ăn và cho bé vận động. Không tự thụt, không nhét que hay lá vào hậu môn bé, không tự dùng thuốc nhuận tràng.',
          ),
          h('Hiểu đúng về táo bón khi ăn dặm'),
          p(
            'Bé bú mẹ hoàn toàn có thể vài ngày mới đi một lần mà phân vẫn mềm; đó là bình thường. Khi bắt đầu ăn dặm, ruột bé làm quen với thức ăn mới nên phân đặc hơn, có mùi hơn và đổi màu theo món ăn. NHS mô tả táo bón là khi bé đi ngoài ít hơn 3 lần một tuần, phân to và cứng hoặc vón thành viên nhỏ, bé phải rặn, đau hoặc có ít máu khi đi, kèm biếng ăn hay đau bụng đỡ hơn sau khi đi.',
          ),
          p('Các nguyên nhân hay gặp khi mới ăn dặm:'),
          ul(
            'Ăn nhiều tinh bột như bột gạo, cháo trắng mà ít rau quả.',
            'Uống ít nước.',
            'Sữa công thức pha đặc hơn hướng dẫn (NHS).',
            'Bé đang ốm, sốt.',
          ),
          p(
            'Khi đi ngoài đau, bé có thể nín lại, làm phân càng cứng hơn; vì vậy nên xử trí sớm (NICE).',
          ),
          h('Ba mẹ có thể làm gì'),
          ul(
            'Thêm rau và trái cây vào mỗi bữa: mận khô hoặc mận tươi nghiền, lê, đào, đu đủ, thanh long, khoai lang, bí đỏ, rau lá xanh, bông cải xanh. AAP gọi mận khô là lựa chọn quen thuộc giúp phân mềm hơn.',
            'Xen một phần ngũ cốc nguyên hạt như yến mạch, gạo lứt nấu thật nhừ, nhưng không thay toàn bộ tinh bột; NHS khuyên trẻ dưới 2 tuổi không chỉ ăn đồ nguyên cám.',
            'Đậu đỏ, đậu xanh, đậu lăng nấu nhừ, nghiền.',
            'Cho bé nhấp nước đun sôi để nguội bằng cốc trong và giữa các bữa ăn; vẫn cho bú đủ.',
            'Pha sữa công thức đúng tỉ lệ in trên hộp, không pha đặc hơn.',
            'Cho bé vận động: nằm sấp chơi, đạp chân như đạp xe, xoa bụng nhẹ theo chiều kim đồng hồ.',
            'Với bé đã lớn, tập ngồi bô một lúc sau bữa ăn, chân đặt vững, khen bé dù có đi hay không (NHS).',
            'Nước ép: AAP không khuyên cho nước ép trước 1 tuổi, nhưng khi bé táo bón, bác sĩ có thể gợi ý một ít nước ép lê hoặc táo. Chỉ dùng khi bác sĩ khuyên.',
          ),
          tip(
            'Phân đổi màu sau món mới',
            'Phân có thể cam khi bé ăn cà rốt, bí đỏ; xanh khi ăn rau; đỏ hồng khi ăn thanh long ruột đỏ, củ dền; sẫm màu khi bé dùng sắt. Nếu không chắc đó là màu thức ăn hay máu, hãy chụp ảnh và hỏi bác sĩ. Phân bạc màu, trắng như phấn hoặc có máu cần đi khám ngay.',
          ),
          h('Theo dõi'),
          ul(
            'Số lần đi ngoài mỗi tuần, độ cứng của phân và bé có rặn đau không.',
            'Máu dính quanh phân hoặc trên tã, thường do nứt hậu môn khi phân cứng.',
            'Bé ăn uống, bú, chơi có bình thường không; bụng có chướng căng không.',
            'Thay đổi đã thử và kết quả sau 1–2 tuần; ghi trong nhật ký để đưa bác sĩ xem.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            'Nhét que tăm bông, cuống rau, xà phòng vào hậu môn cho bé đi → Có thể gây trầy xước, nứt hậu môn và làm bé càng sợ đi ngoài → Điều chỉnh ăn uống, vận động và hỏi bác sĩ.',
            'Cho uống nước đường, mật ong, nước cam thảo cho “mát ruột” → Mật ong có thể gây ngộ độc botulinum ở bé dưới 1 tuổi; nước đường không cần và hại răng → Nước đun sôi để nguội, rau quả.',
            'Đổi sữa liên tục để chữa táo bón → Đổi sữa thường không giải quyết được và có thể làm bé rối → Chỉ đổi sữa khi bác sĩ khuyên.',
            'Tự mua thuốc nhuận tràng hoặc thuốc thụt cho bé → Thuốc cần đúng loại và đúng liều theo cân nặng, tuổi → Dùng theo chỉ định bác sĩ (NICE).',
          ),
          urgent(
            'Gọi {emergency} ngay khi',
            'Bé nôn ra dịch xanh, bụng chướng căng, đau quặn từng cơn, sốt kèm lả, hoặc bé li bì. Đừng chờ: gọi {emergency} hoặc đưa bé đến khoa cấp cứu gần nhất.',
          ),
          doctor(
            'Khi nào nên hỏi bác sĩ',
            'Táo bón không đỡ sau 1–2 tuần thay đổi ăn uống; bé đau nhiều khi đi ngoài, phân có máu; táo bón đã có từ những tuần đầu sau sinh; bé biếng ăn, tăng cân chưa tốt hoặc sụt cân; phân bạc màu như phấn.',
          ),
        ],
        en: [
          note(
            'In short',
            "With solids, stools usually get firmer and change color and smell; that alone is not constipation. Constipation means hard, lumpy stools, painful straining, or fewer than 3 poos a week with hard stools. Add vegetables and fruit such as plums, pears, papaya and sweet potato to meals, offer sips of water from a cup with meals and help your baby move. Don't give enemas yourself, never put sticks or leaves into your baby's bottom, and don't use laxatives on your own.",
          ),
          h('Understanding constipation when starting solids'),
          p(
            "Exclusively breastfed babies may go several days between poos while the stool stays soft; that is normal. When solids start, your baby's gut is getting used to new food, so stools get firmer, smellier and change color with what they eat. The NHS describes constipation as fewer than 3 poos a week, large hard stools or small pellets, straining, pain or a little blood when pooing, along with poor appetite or tummy pain that eases after a poo.",
          ),
          p('Common causes early in weaning:'),
          ul(
            'Lots of starch such as rice cereal or plain porridge, with few vegetables and fruit.',
            'Too little to drink.',
            'Formula made up stronger than the instructions (NHS).',
            'Being unwell or feverish.',
          ),
          p(
            'When pooing hurts, babies may hold it in, making stools even harder, which is why it is best dealt with early (NICE).',
          ),
          h('What you can do'),
          ul(
            'Add vegetables and fruit to every meal: mashed prunes or fresh plums, pear, peach, papaya, dragon fruit, sweet potato, pumpkin, leafy greens, broccoli. The AAP calls prunes a well-known choice for softening stools.',
            'Include some wholegrains such as oats or brown rice cooked very soft, but not as all of the starch; the NHS advises that children under 2 should not have only wholegrain foods.',
            'Red beans, mung beans and lentils cooked until very soft and mashed.',
            'Offer sips of boiled and cooled water from a cup with and between meals; keep milk feeds going.',
            'Make up formula exactly as printed on the tin, never stronger.',
            'Help your baby move: tummy time, bicycling the legs, gently rubbing the tummy clockwise.',
            'For older babies, practice sitting on the potty for a while after meals with feet firmly supported, and praise them whether or not they go (NHS).',
            'Juice: the AAP does not recommend juice before 1 year, but for constipation a doctor may suggest a little pear or apple juice. Use it only if the doctor advises.',
          ),
          tip(
            'Stools changing color after a new food',
            'Stools may turn orange after carrot or pumpkin, green after greens, pinkish red after red dragon fruit or beetroot, and dark when your baby takes iron. If you are not sure whether it is food color or blood, take a photo and ask the doctor. Pale, chalky white stools or blood in the stool need a doctor straight away.',
          ),
          h('What to watch'),
          ul(
            'How many times a week your baby poos, how hard the stools are and whether they strain in pain.',
            'Blood streaks on the stool or nappy, usually from a small tear when stools are hard.',
            'Whether your baby eats, feeds and plays normally, and whether the tummy is swollen and tight.',
            'What you have changed and the result after 1–2 weeks; note it in the diary to show the doctor.',
          ),
          h('Common myths'),
          ul(
            "Putting a cotton bud, a vegetable stalk or soap into the baby's bottom to make them go → This can scratch or tear the skin and make your baby more afraid to poo → Adjust food, drinks and activity, and ask the doctor.",
            'Giving sugar water, honey or licorice water to "cool the gut" → Honey can cause infant botulism in babies under 1; sugar water is not needed and harms teeth → Boiled and cooled water, vegetables and fruit.',
            'Switching formula again and again to fix constipation → Changing milk usually does not solve it and can unsettle your baby → Change formula only if the doctor advises.',
            'Buying laxatives or enemas for the baby yourself → Medicines need the right type and a dose based on weight and age → Use them only as the doctor prescribes (NICE).',
          ),
          urgent(
            'Call {emergency} now if',
            "Your baby vomits green fluid, has a swollen tight tummy, has waves of severe pain, has a fever and is limp, or is unusually drowsy. Don't wait: call {emergency} or go to the nearest emergency department.",
          ),
          doctor(
            'When to ask a doctor',
            'Constipation does not improve after 1–2 weeks of changes to food and drink; your baby has a lot of pain pooing or blood in the stool; constipation started in the first weeks after birth; your baby eats poorly, is not gaining weight well or loses weight; or stools are pale and chalky.',
          ),
        ],
      },
      keywords: t(
        [
          'táo bón',
          'táo bón khi ăn dặm',
          'phân cứng',
          'rặn',
          'chất xơ',
          'mận khô',
          'uống nước',
          'phân đổi màu',
          'thụt hậu môn',
          'thuốc nhuận tràng',
        ],
        [
          'constipation',
          'constipation with solids',
          'hard stools',
          'straining',
          'fibre',
          'prunes',
          'drinking water',
          'stool color',
          'enemas',
          'laxatives',
        ],
      ),
      relatedArticleIds: [
        'art_constipation',
        'art_water_juice',
        'art_solids_vn_porridge',
        'art_solids_menu_6_8',
      ],
      milestoneIds: [],
      sources: [
        S.nhsConstipation,
        S.niceConstipation,
        S.hcInfantConstipation,
        S.nhsBottleConstipation,
        S.nhsYoungChildren,
        S.nhsDrinksCups,
      ],
    },
  },
  {
    id: 'art_solids_sick_teething',
    reviewerLabel: NUTRITION,
    data: {
      library: 'solids',
      topic: 'feeding',
      subtopic: 'health',
      format: 'quick_qa',
      ageWeeks: { from: 22, to: 104 },
      readingMinutes: 2,
      cover: null,
      title: t(
        'Hỏi nhanh: Bé ốm hoặc mọc răng, ăn dặm thế nào?',
        'Quick Q&A: Solids when your baby is unwell or teething',
      ),
      summary: t(
        'Bé biếng ăn khi ốm hay mọc răng là chuyện thường. Ưu tiên bú và uống đủ, món mềm bé thích, ăn bù khi đã khỏe, và những dấu hiệu cần đưa bé đi khám.',
        'Babies often eat less when unwell or teething. Put milk and fluids first, offer soft foods your baby likes, make up for it once they are better, and know the signs that need a doctor.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Khi ốm hoặc mọc răng, bé ăn ít đi vài ngày là bình thường. Cho bú thường xuyên hơn và cho uống đủ; mời món mềm, mát, bé thích, chia nhiều bữa nhỏ, không ép. Khi bé khỏe lại, cho ăn thêm bữa hoặc thêm lượng trong một thời gian để bé bù lại.',
          ),
          h('Bé ốm, biếng ăn: có cần ép ăn không?'),
          p(
            'Không. WHO khuyên khi trẻ ốm, cho uống nhiều hơn, bú mẹ thường xuyên hơn, và mời những món mềm, bé thích. Cháo, súp, khoai nghiền, trái cây nghiền, sữa chua không đường là lựa chọn dễ ăn. Chia nhiều bữa nhỏ, mời khi bé tỉnh táo. Khi khỏe lại, bé thường ăn nhiều hơn; hãy cho thêm bữa để bé bù lại.',
          ),
          h('Bé tiêu chảy hoặc nôn thì sao?'),
          p(
            'Tiếp tục cho bú và cho ăn khi bé muốn, không kiêng ăn kéo dài. Bù nước bằng dung dịch bù nước ORS pha đúng hướng dẫn trên gói, uống từng ngụm nhỏ. Không dùng nước ngọt, nước ép thay ORS. Kẽm chỉ dùng theo chỉ định bác sĩ. Xem thêm bài về tiêu chảy và mất nước trong thư viện.',
          ),
          h('Mọc răng có làm bé bỏ ăn không?'),
          p(
            'Có thể. Bé đau lợi, quấy, chảy dãi, hay gặm và ăn ít hơn vài ngày (NHS). Mời món mềm, mát như sữa chua, trái cây nghiền để trong ngăn mát; cho bé gặm vòng gặm làm mát trong ngăn mát, không để ngăn đá.',
          ),
          p(
            'Không dùng gel bôi lợi chứa benzocaine hay vòng hổ phách, vòng dâu tằm đeo cổ vì nguy cơ nghẹt thở và hóc (FDA). Mọc răng không gây sốt cao hay tiêu chảy nhiều; nếu có, đó là do bệnh khác.',
          ),
          h('Khi nào cần thuốc giảm đau?'),
          p(
            'Chỉ khi bé rất khó chịu, và theo liều bác sĩ hoặc dược sĩ hướng dẫn theo cân nặng của bé. Không tự dùng thuốc của người lớn cho bé.',
          ),
          urgent(
            'Gọi {emergency} ngay khi',
            'Bé khó thở, lơ mơ, khó đánh thức, co giật, hoặc da tái, lả đi.',
          ),
          doctor(
            'Khi nào nên hỏi bác sĩ',
            'Bé bỏ bú hoặc không uống được, ít tã ướt, môi khô, khóc không có nước mắt, li bì; nôn liên tục, phân có máu; sốt cao hoặc sốt kéo dài; bé biếng ăn hơn một tuần dù đã khỏe.',
          ),
        ],
        en: [
          note(
            'In short',
            'When unwell or teething, eating less for a few days is normal. Breastfeed more often and offer enough to drink; offer soft, cool foods your baby likes in several small meals, without forcing. Once your baby is better, offer extra meals or larger amounts for a while so they can catch up.',
          ),
          h('My baby is unwell and eating little: should I make them eat?'),
          p(
            'No. WHO advises that when children are ill, they should drink more, breastfeed more often and be offered soft foods they like. Porridge, soup, mashed potato, mashed fruit and plain yoghurt are easy to eat. Offer several small meals when your baby is alert. Once better, babies usually eat more; give extra meals so they can catch up.',
          ),
          h('What about diarrhea or vomiting?'),
          p(
            "Keep breastfeeding and offering food when your baby wants it, without long periods of avoiding food. Replace fluids with oral rehydration solution (ORS) made up exactly as the packet says, given in small sips. Don't use soft drinks or juice instead of ORS. Zinc only as the doctor prescribes. See the library article on diarrhea and dehydration.",
          ),
          h('Can teething put my baby off food?'),
          p(
            'It can. Babies may have sore gums, be fussy, drool, chew on things and eat less for a few days (NHS). Offer soft, cool foods such as yoghurt and mashed fruit from the fridge; let your baby chew a teething ring chilled in the fridge, not the freezer.',
          ),
          p(
            "Don't use teething gels containing benzocaine or amber or other teething necklaces, because of the risk of strangling and choking (FDA). Teething does not cause a high fever or a lot of diarrhea; if these appear, something else is going on.",
          ),
          h('When is pain relief needed?'),
          p(
            "Only when your baby is very uncomfortable, and at the dose a doctor or pharmacist gives for your baby's weight. Never give your baby adult medicines.",
          ),
          urgent(
            'Call {emergency} now if',
            'Your baby has trouble breathing, is very drowsy or hard to wake, has a seizure, or turns pale or limp.',
          ),
          doctor(
            'When to ask a doctor',
            'Your baby refuses feeds or cannot drink, has fewer wet nappies, dry lips, cries without tears or is unusually drowsy; vomits repeatedly or has blood in the stool; has a high or lasting fever; or is still eating poorly more than a week after getting better.',
          ),
        ],
      },
      keywords: t(
        [
          'bé ốm',
          'biếng ăn khi ốm',
          'mọc răng',
          'đau lợi',
          'tiêu chảy',
          'nôn',
          'ORS',
          'ăn bù',
          'vòng hổ phách',
          'món mềm',
        ],
        [
          'sick baby',
          'poor appetite when ill',
          'teething',
          'sore gums',
          'diarrhea',
          'vomiting',
          'ORS',
          'catch-up feeding',
          'amber necklace',
          'soft foods',
        ],
      ),
      relatedArticleIds: [
        'art_teething',
        'art_diarrhoea_dehydration',
        'art_fever_when_to_call',
        'art_solids_hunger_fullness',
      ],
      milestoneIds: [],
      sources: [
        S.whoIycf,
        S.whoDiarrhoea,
        S.nhsDiarrhoea,
        S.nhsTeethingTips,
        S.hcTeethingPain,
        S.fdaTeething,
      ],
    },
  },
  // ----- Từ 12 tháng (from 12 months) -----
  {
    id: 'art_solids_family_meals',
    reviewerLabel: NUTRITION,
    data: {
      library: 'solids',
      topic: 'feeding',
      subtopic: 'family',
      format: 'article',
      ageWeeks: { from: 52, to: 156 },
      readingMinutes: 4,
      cover: null,
      title: t(
        'Từ 12 tháng: bé ăn cùng mâm cơm gia đình',
        'From 12 months: your toddler at the family table',
      ),
      summary: t(
        'Từ 1 tuổi, bé có thể ăn phần lớn món của gia đình nếu được nấu mềm, cắt nhỏ và múc ra trước khi nêm. Cách chia bữa, uống sữa, tập tự xúc và giữ bữa cơm vui vẻ, không màn hình.',
        'From 1 year, toddlers can eat most family dishes if they are cooked soft, cut small and taken out before seasoning. How to plan meals, milk, learning to self-feed and keeping meals happy and screen-free.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Từ 12 tháng, bé ăn 3–4 bữa cùng gia đình và 1–2 bữa phụ, và có thể tiếp tục bú mẹ đến 2 tuổi hoặc lâu hơn. Múc phần của bé ra trước khi nêm muối, nước mắm; nấu mềm, cắt nhỏ, gỡ xương kỹ. Sữa bò tươi nguyên kem đã thanh trùng hoặc tiệt trùng có thể làm đồ uống từ 1 tuổi. Cả nhà ngồi ăn cùng, tắt tivi, để bé tự xúc, không ép.',
          ),
          h('Hiểu đúng về bữa ăn từ 12 tháng'),
          p(
            'WHO khuyên trẻ 9–23 tháng ăn 3–4 bữa mỗi ngày và 1–2 bữa phụ tuỳ nhu cầu; UNICEF gợi ý mỗi bữa khoảng ba phần tư đến một chén. Sau 1 tuổi bé lớn chậm hơn năm đầu, nên sức ăn thay đổi nhiều theo ngày; AAP cho biết lượng ăn thường cân bằng lại qua vài ngày. Bé học ăn bằng cách nhìn và bắt chước, nên bữa cơm gia đình là lớp học tốt nhất.',
          ),
          p(
            'Mâm cơm Việt với cơm, canh, món mặn và rau rất hợp để bé ăn cùng. Điều cần chỉnh là độ mềm, kích thước miếng và lượng muối: món kho, rim, chiên thường đậm vị, nên múc phần của bé trước khi nêm hoặc ưu tiên món luộc, hấp, canh cho bé.',
          ),
          h('Ba mẹ có thể làm gì'),
          ul(
            'Nấu chung, nêm sau: múc phần của bé ra trước khi cho muối, nước mắm, bột ngọt; người lớn nêm hoặc chấm thêm. NHS cho biết trẻ nhỏ không cần thêm muối vì thức ăn đã có sẵn.',
            'Cơm nấu mềm hơn một chút hoặc dầm với canh; thịt, cá cắt miếng nhỏ, gỡ xương kỹ; rau luộc mềm thái nhỏ.',
            'Mỗi bữa có tinh bột, chất đạm (thịt, cá, trứng, đậu phụ, đậu), rau, và trái cây tráng miệng; NHS gợi ý cá béo như cá hồi, cá mòi ít nhất mỗi tuần một lần.',
            'Bữa phụ: trái cây, sữa chua không đường, phô mai làm từ sữa thanh trùng, khoai lang hấp, bánh mì; hạn chế bánh kẹo, nước ngọt, đồ ăn vặt mặn.',
            'Sữa: tiếp tục bú mẹ nếu mẹ và bé muốn. Sữa bò tươi nguyên kem đã thanh trùng hoặc tiệt trùng có thể là đồ uống chính; AAP gợi ý khoảng 480 ml mỗi ngày cho trẻ 12–24 tháng. Uống nhiều hơn dễ làm bé ăn ít và nhận ít sắt. Không dùng sữa gạo trước 5 tuổi.',
            'Tập bỏ bình, chuyển sang uống bằng cốc từ khoảng 1 tuổi (NHS, AAP).',
            'Cho bé thìa riêng, bát có đế chống trượt; chấp nhận rơi vãi, người lớn chỉ hỗ trợ khi bé mệt.',
            'Bé ngồi ghế ăn hoặc ghế nâng sát bàn, sát mâm; không bế đi rong hay chạy theo đút.',
            'Tắt tivi, cất điện thoại trong bữa. WHO không khuyến khích trẻ 1 tuổi ngồi xem màn hình, và trẻ 2–4 tuổi không quá 1 giờ mỗi ngày, càng ít càng tốt.',
            'Vẫn cẩn thận món dễ hóc: hạt nguyên đến 5 tuổi, nho và cà chua bi cắt dọc làm tư, xôi dẻo miếng to, xương cá.',
          ),
          tip(
            'Một mâm cơm và phần của bé',
            'Mâm cơm: cơm, canh cải nấu tôm, cá kho, đậu phụ sốt cà chua, rau muống luộc. Phần của bé: cơm mềm dầm với canh cải tôm múc ra trước khi nêm, phần cá lấy ra hấp trước khi kho, đậu phụ sốt cà chua ít nêm, rau luộc thái nhỏ, và vài miếng trái cây tráng miệng.',
          ),
          h('Theo dõi'),
          ul(
            'Sức ăn theo tuần chứ không theo bữa; bé vẫn chơi, khỏe là dấu hiệu tốt.',
            'Cân nặng, chiều dài theo biểu đồ ở các lần khám định kỳ.',
            'Bé có ăn đủ các nhóm thực phẩm qua tuần không, hay chỉ uống sữa.',
            'Bé có ngậm cơm lâu, bữa ăn kéo dài hay căng thẳng không.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            'Trẻ 1–2 tuổi vẫn phải ăn cháo riêng, chưa ăn cơm được → Nhiều bé ăn cơm mềm rất tốt, và chậm chuyển sang thức ăn thô dễ khiến bé kén ăn → Cho cơm mềm, cắt nhỏ, ăn cùng cả nhà.',
            'Chan nước kho, nước canh đã nêm cho bé dễ nuốt → Nhiều muối mà ít cái → Chan canh nhạt múc ra trước khi nêm và cho bé ăn cả phần cái.',
            'Đút cho nhanh, sạch, khỏi bừa → Bé mất cơ hội học tự ăn và tự nhận biết no đói → Để bé tự xúc, người lớn hỗ trợ.',
            'Uống thật nhiều sữa thay cho bữa ăn → Bé no sữa nên ăn ít, thiếu đa dạng → Giữ lượng sữa vừa phải, ưu tiên bữa ăn.',
          ),
          urgent(
            'Gọi {emergency} ngay khi',
            'Bé hóc không ho được, khó thở, sưng môi, mặt hoặc lưỡi, hoặc lả đi sau khi ăn.',
          ),
          doctor(
            'Khi nào nên hỏi bác sĩ',
            'Bé tăng cân chưa tốt hoặc sụt cân; bé chỉ uống sữa, không chịu ăn; bé khó nhai, hay nôn hoặc sặc với thức ăn thô; gia đình ăn chay hoặc bé phải kiêng nhiều món; bé nổi mẩn, sưng môi hoặc nôn sau một món mới.',
          ),
        ],
        en: [
          note(
            'In short',
            "From 12 months, toddlers have 3–4 meals with the family plus 1–2 snacks, and can keep breastfeeding to 2 years or beyond. Take your child's portion out before adding salt or fish sauce; cook soft, cut small and remove bones carefully. Pasteurized whole cow's milk can be a drink from 1 year. Eat together, turn off the TV, let your child feed themselves and never force.",
          ),
          h('Understanding meals from 12 months'),
          p(
            'WHO advises 3–4 meals a day for children 9–23 months, plus 1–2 snacks as needed; UNICEF suggests about three-quarters of a cup to a full cup per meal. After 1 year children grow more slowly than in their first year, so appetite varies a lot from day to day; the AAP says intake usually balances out over a few days. Children learn to eat by watching and copying, so the family meal is the best classroom.',
          ),
          p(
            "A Vietnamese family meal of rice, soup, a savory dish and vegetables is ideal for toddlers to share. What needs adjusting is softness, piece size and salt: braised, caramelized and fried dishes are usually strongly seasoned, so take your child's portion out before seasoning or choose boiled, steamed and soup dishes for them.",
          ),
          h('What you can do'),
          ul(
            "Cook together, season after: take your child's portion out before adding salt, fish sauce or MSG; adults season or dip at the table. The NHS says young children don't need added salt because food already contains enough.",
            'Cook rice a little softer or mash it with soup; cut meat and fish into small pieces and remove bones carefully; boil vegetables soft and chop them small.',
            'Each meal includes a starch, a protein (meat, fish, egg, tofu, beans), vegetables, and fruit for dessert; the NHS suggests oily fish such as salmon or sardines at least once a week.',
            'Snacks: fruit, plain yoghurt, pasteurized cheese, steamed sweet potato, bread; limit sweets, soft drinks and salty snacks.',
            "Milk: keep breastfeeding if you and your child want to. Pasteurized whole cow's milk can be the main drink; the AAP suggests about 480 ml a day for children 12–24 months. More than that easily means eating less and getting less iron. No rice milk before 5 years.",
            'Move away from the bottle to drinking from a cup from around 1 year (NHS, AAP).',
            'Give your child their own spoon and a non-slip bowl; accept the mess, with adults helping only when your child is tired.',
            'Seat your child in a high chair or booster at the table or beside the meal tray; never carry them around or chase them with the spoon.',
            'Turn off the TV and put phones away at meals. WHO advises no sedentary screen time for 1-year-olds, and no more than 1 hour a day for 2–4-year-olds, with less being better.',
            'Still take care with choking hazards: no whole nuts until 5, grapes and cherry tomatoes cut lengthwise into quarters, no large pieces of sticky rice, and check for fish bones.',
          ),
          tip(
            "A family meal and your child's portion",
            "The family meal: rice, mustard green and shrimp soup, braised fish, tofu in tomato sauce, boiled morning glory. Your child's portion: soft rice mashed with the shrimp soup taken out before seasoning, a piece of the fish steamed before braising, lightly seasoned tofu in tomato sauce, finely chopped boiled greens, and a few pieces of fruit for dessert.",
          ),
          h('What to watch'),
          ul(
            'Appetite over the week rather than meal by meal; a child who plays and is well is a good sign.',
            'Weight and length on the growth chart at routine checkups.',
            'Whether your child eats from all the food groups over the week, or mostly drinks milk.',
            'Whether your child holds food in their mouth for a long time, or meals drag on or feel tense.',
          ),
          h('Common myths'),
          ul(
            "Children of 1–2 still need separate porridge and can't eat rice → Many children eat soft rice very well, and moving to textured food late makes fussy eating more likely → Offer soft rice, cut small, with the family.",
            'Pouring seasoned braising liquid or soup over rice makes it easier to swallow → It adds a lot of salt and little nourishment → Use unseasoned soup taken out before seasoning, and give the solid ingredients too.',
            'Spoon-feeding is quicker and cleaner → Your child misses the chance to learn to feed themselves and to sense hunger and fullness → Let them self-feed, with adults helping.',
            'Lots of milk instead of meals → Children full of milk eat less and miss out on variety → Keep milk moderate and put meals first.',
          ),
          urgent(
            'Call {emergency} now if',
            'Your child is choking and cannot cough, has trouble breathing, swelling of the lips, face or tongue, or goes limp after eating.',
          ),
          doctor(
            'When to ask a doctor',
            'Your child is not gaining weight well or loses weight; drinks only milk and refuses food; has trouble chewing, often vomits or chokes on textured food; your family is vegetarian or your child must avoid many foods; or gets a rash, swollen lips or vomiting after a new food.',
          ),
        ],
      },
      keywords: t(
        [
          'ăn cùng gia đình',
          'mâm cơm',
          'cơm mềm',
          '12 tháng',
          'trẻ 1 tuổi',
          'sữa bò tươi',
          'tự xúc',
          'bỏ bình',
          'không màn hình',
          'nêm muối',
        ],
        [
          'family meals',
          'family table',
          'soft rice',
          '12 months',
          '1-year-old',
          "cow's milk",
          'self-feeding',
          'stopping the bottle',
          'screen-free meals',
          'salt',
        ],
      ),
      relatedArticleIds: [
        'art_picky_eating_toddler',
        'art_toddler_milk',
        'art_solids_menu_9_11',
        'art_screens_language',
      ],
      milestoneIds: [],
      sources: [
        S.unicef1to2,
        S.whoIycf,
        S.whoCf2023,
        S.nhsYoungChildren,
        S.hcOneYearOld,
        S.hcRecommendedDrinks,
        S.hcBottleToCup,
        S.whoSitLessPlayMore,
      ],
    },
  },
  {
    id: 'art_solids_gear',
    reviewerLabel: NUTRITION,
    data: {
      library: 'solids',
      topic: 'feeding',
      subtopic: 'gear',
      format: 'quick_qa',
      ageWeeks: { from: 17, to: 52 },
      readingMinutes: 2,
      cover: null,
      title: t(
        'Hỏi nhanh: Đồ dùng ăn dặm: ghế, thìa, cốc tập uống',
        'Quick Q&A: Solids gear: high chair, spoons and cups',
      ),
      summary: t(
        'Bé cần ít đồ hơn ba mẹ nghĩ: một ghế ăn chắc có đai, vài chiếc thìa mềm, bát, cốc hở miệng và yếm. Cách chọn và dùng an toàn, chuẩn bị trước khi bé bắt đầu ăn dặm lúc 6 tháng.',
        'Babies need less than you might think: a sturdy high chair with a harness, a few soft spoons, a bowl, an open cup and a bib. How to choose and use them safely, ready before your baby starts solids at 6 months.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Chỉ cần: ghế ăn chắc chắn có đai, gồm cả đai giữa hai chân; thìa nhỏ mềm; bát có đế hút; cốc hở miệng hoặc cốc không van; yếm và tấm lót sàn. Máy xay tiện nhưng không bắt buộc, nĩa và rây là đủ. Chuẩn bị trước khi bé tròn 6 tháng.',
          ),
          h('Chọn và dùng ghế ăn thế nào?'),
          p(
            'Chọn ghế chân đế rộng, khó lật; ghế gấp phải khoá chắc mỗi lần mở. Luôn cài đai, kể cả đai giữa hai chân, và không để bé đứng trên ghế.',
          ),
          p(
            'Đặt ghế xa bàn, kệ bếp để bé không đạp vào làm đổ ghế; không để bé ngồi một mình hay để anh chị leo trèo lên ghế (AAP). Bé ngồi thẳng, có chỗ để chân càng tốt. Không cho ăn trên xe đẩy ngả lưng, ghế rung hay trên xe máy.',
          ),
          h('Thìa, bát nào phù hợp?'),
          p(
            'Thìa nhỏ, nông, mềm bằng silicon hoặc nhựa dùng cho thực phẩm, nhẹ nhàng với lợi bé (NHS). Cho bé cầm một chiếc thìa riêng để tập. Bát nhỏ có đế hút đỡ bị hất đổ. Rửa bằng nước nóng và nước rửa bát, để khô ráo.',
          ),
          h('Cốc tập uống: chọn cốc gì?'),
          p(
            'Từ 6 tháng, cho bé tập nhấp nước bằng cốc hở miệng hoặc cốc không van; NHS cho biết cách này tốt cho răng hơn. Cốc có van chống tràn bắt bé phải mút như bú bình. Chỉ đựng nước hoặc sữa, không đựng nước ngọt, nước ép. Từ khoảng 1 tuổi, tập bỏ bình sữa (NHS, AAP).',
          ),
          h('Có cần túi nhai, đồ ăn dạng túi hút?'),
          p(
            'Không cần. Thức ăn mềm cắt đúng cỡ giúp bé học nhai tốt hơn túi nhai. Với đồ ăn đóng túi, đừng để bé mút trực tiếp từ túi; nặn ra thìa và chỉ dùng thỉnh thoảng (NHS). Khay đá có nắp rất tiện để trữ đông từng phần nhỏ.',
          ),
          urgent(
            'Gọi {emergency} ngay khi',
            'Bé hóc không ho được, khó thở hoặc tím tái. Trong lúc chờ, làm theo mục Sơ cứu trẻ em › Hóc dị vật trong Child Life.',
          ),
          doctor(
            'Khi nào nên hỏi bác sĩ',
            'Bé gần 6 tháng mà chưa giữ vững đầu hoặc chưa ngồi được dù có đỡ; bé có vấn đề về trương lực cơ cần ghế đặc biệt; bé hay sặc khi uống bằng cốc.',
          ),
        ],
        en: [
          note(
            'In short',
            'All you need: a sturdy high chair with a harness, including the strap between the legs; small soft spoons; a bowl with a suction base; an open or free-flow cup; a bib and a floor mat. A blender is handy but not essential; a fork and a sieve are enough. Get them ready before your baby turns 6 months.',
          ),
          h('How do I choose and use a high chair?'),
          p(
            'Choose a chair with a wide base that is hard to tip over; a folding chair must be locked every time you set it up. Always use the harness, including the strap between the legs, and never let your baby stand in the chair.',
          ),
          p(
            "Keep it away from tables and counters your baby could push against and tip it over; never leave your baby alone in it or let older children climb on it (AAP). Your baby sits upright, ideally with a footrest. Don't feed your baby in a reclined pushchair, a bouncer or on a motorbike.",
          ),
          h('Which spoons and bowls?'),
          p(
            "Small, shallow, soft spoons made of silicone or food-grade plastic are gentle on your baby's gums (NHS). Give your baby a spoon of their own to practice with. A small bowl with a suction base is harder to knock over. Wash in hot water with washing-up liquid and let them dry.",
          ),
          h('Which cup should I choose?'),
          p(
            'From 6 months, let your baby practice sipping water from an open or free-flow cup; the NHS says this is better for teeth. Non-spill cups with valves make babies suck as they would from a bottle. Use cups only for water or milk, never soft drinks or juice. From around 1 year, move away from the bottle (NHS, AAP).',
          ),
          h('Do I need a mesh feeder or food pouches?'),
          p(
            "No. Soft food cut to the right size helps your baby learn to chew better than a mesh feeder. With pouches, don't let your baby suck straight from the pouch; squeeze the food onto a spoon and use pouches only occasionally (NHS). Ice cube trays with lids are handy for freezing small portions.",
          ),
          urgent(
            'Call {emergency} now if',
            'Your baby is choking and cannot cough, has trouble breathing or turns blue. While you wait, follow the Choking steps in the Sơ cứu trẻ em (First aid) guide in Child Life.',
          ),
          doctor(
            'When to ask a doctor',
            'Your baby is nearly 6 months and still cannot hold their head steady or sit even with support; has low or high muscle tone and needs a special seat; or often chokes when drinking from a cup.',
          ),
        ],
      },
      keywords: t(
        [
          'đồ dùng ăn dặm',
          'ghế ăn dặm',
          'thìa ăn dặm',
          'cốc tập uống',
          'cốc hở miệng',
          'bát có đế hút',
          'yếm ăn',
          'túi nhai',
          'máy xay',
          'bỏ bình',
        ],
        [
          'solids gear',
          'high chair',
          'weaning spoon',
          'training cup',
          'open cup',
          'suction bowl',
          'bib',
          'mesh feeder',
          'blender',
          'stopping the bottle',
        ],
      ),
      relatedArticleIds: [
        'art_solids_first_meals',
        'art_solids_readiness',
        'art_solids_choking_safety',
        'art_pacifier_bottle_habits',
      ],
      milestoneIds: [],
      sources: [S.nhsHowToStart, S.nhsDrinksCups, S.hcHighChair, S.hcBottleToCup, S.nhsFirstSolids],
    },
  },
];
