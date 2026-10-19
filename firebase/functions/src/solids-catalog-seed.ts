import type {
  FoodAllergen,
  FoodContent,
  FoodGroup,
  IngredientUnit,
  RecipeContent,
  TextureStage,
} from '@child-life/contracts';

/**
 * Ăn dặm catalogue and recipes (D-085, P-164; plan `docs/product/solids-plan.md` §3 #8–#10, §8):
 * engineering drafts written as a paediatric nutrition expert from WHO, Bộ Y tế / Viện Dinh dưỡng,
 * UNICEF, AAP, CDC, FDA, NHS and ASCIA guidance. "Nhập bản nháp mẫu" imports them as Nháp under
 * these ids; nothing claims a review it has not had, and `reviewerLabel` only says who is expected
 * to review.
 *
 * Foods (`fd_…`): common foods for Vietnamese babies from 6 months, in the seven 5e groups, with
 * the nine common allergens (ASCIA, BSACI), `ironRich` as 9d Sắt counts it (meat, liver, fish, egg,
 * legumes, tofu, dark leafy greens, iron-fortified cereal; not shrimp, squid, broccoli, nut or seed
 * pastes, which carry little iron per baby portion), `minAgeMonths` 6 except honey and drinks that
 * replace milk (12) and popcorn (36, AAP: not before 4), preparation per texture stage and the
 * choking advice (NHS, CDC, AAP). Choking hazards, salty processed meats and drinks are kept for
 * the picker but never suggested (`suggest: false`); nuts appear only as smooth pastes. `priority`
 * favours iron-rich foods and first vegetables (plan §7 S2, S5, S6).
 *
 * Recipes (`rcp_…`): Vietnamese home cooking first, every food that matters linked to the
 * catalogue (water and aromatics that are removed may stay free names). Never salt, sugar, nước
 * mắm, hạt nêm, bột ngọt, soy sauce or honey for the baby's portion ("không nêm"); family dishes
 * take the baby's portion out before seasoning. Recipes that introduce an allergen say so gently
 * (egg fully cooked, peanut and tree nuts only as thinned smooth paste, a small amount in the
 * morning, `{emergency}` for breathing trouble or swelling, D-087). Storage follows NHS (rice within 1 hour and 24
 * hours, other food within 1–2 hours and 2 days, reheat once). Plain text; vi is the source, en a
 * faithful rendering (D-012).
 */

export interface SolidsSeed<T> {
  id: string;
  reviewerLabel: string | null;
  data: T;
}

/** Who is expected to review each item; not a claim of review. */
const NUTRITION = 'Nhóm chuyên môn · Dinh dưỡng nhi';

type Loc = { vi: string; en: string };
type Source = { label: string; url: string };
type Pair = [vi: string, en: string];

const t = (vi: string, en: string): Loc => ({ vi, en });
const none = t('', '');

// ---------- Sources (the pages `solids-seed.ts` cites, opened 2026-10-18) ----------

const S = {
  whoCf2023: {
    label:
      'WHO — Guideline for complementary feeding of infants and young children 6–23 months of age (2023)',
    url: 'https://www.who.int/publications/i/item/9789240081864',
  },
  whoFiveKeys: {
    label: 'WHO — Five keys to safer food manual',
    url: 'https://www.who.int/publications/i/item/9789241594639',
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
  nhsYoungChildren: {
    label: 'NHS — What to feed young children',
    url: 'https://www.nhs.uk/baby/weaning-and-feeding/what-to-feed-young-children/',
  },
  nhsIron: {
    label: 'NHS — Vitamins and minerals: iron',
    url: 'https://www.nhs.uk/conditions/vitamins-and-minerals/iron/',
  },
  hcChokingPrevention: {
    label: 'HealthyChildren.org (AAP) — Choking prevention',
    url: 'https://www.healthychildren.org/English/health-issues/injuries-emergencies/Pages/Choking-Prevention.aspx',
  },
  hcRecommendedDrinks: {
    label: 'HealthyChildren.org (AAP) — Recommended drinks for children age 5 and younger',
    url: 'https://www.healthychildren.org/English/healthy-living/nutrition/Pages/Recommended-Drinks-for-Young-Children-Ages-0-5.aspx',
  },
  hcOneYearOld: {
    label: 'HealthyChildren.org (AAP) — Feeding and nutrition tips: your 1-year-old',
    url: 'https://www.healthychildren.org/English/ages-stages/toddler/nutrition/Pages/Feeding-and-Nutrition-Your-One-Year-Old.aspx',
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
  asciaIntroSolids: {
    label: 'ASCIA — How to introduce solid foods to babies for allergy prevention',
    url: 'https://www.allergy.org.au/patients/allergy-prevention/ascia-how-to-introduce-solid-foods-to-babies',
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
} as const satisfies Record<string, Source>;

// ---------- Foods ----------

type Prep = FoodContent['prep'][number];
const prep =
  (texture: TextureStage) =>
  (vi: string, en: string): Prep => ({ texture, text: t(vi, en) });
const smooth = prep('smooth');
const mashed = prep('mashed');
const pieces = prep('softPieces');
const finger = prep('finger');
const family = prep('family');

/** The family stage most foods share from about 12 months. */
const FAMILY_CUT = family(
  'Ăn cùng món của cả nhà, cắt nhỏ, mềm; múc phần của bé ra trước khi nêm.',
  "Share the family dish, cut small and soft; take your child's portion out before seasoning.",
);

const FISH_BONES: Pair = [
  'Gỡ thật kỹ xương và da; miết từng miếng bằng tay trước khi cho bé.',
  'Remove every bone and the skin; feel each piece with your fingers before serving.',
];
const ROUND_FRUIT: Pair = [
  'Tròn, trơn, có hạt to: bóc vỏ, bỏ hạt và cắt nhỏ; không bao giờ cho cả quả.',
  'Round, slippery and with a large seed: peel, deseed and chop; never give it whole.',
];
const WHOLE_BEANS: Pair = [
  'Hạt đậu nguyên chắc, tròn: nghiền hoặc bóp dẹt từng hạt cho bé nhỏ.',
  'Whole beans are firm and round: mash or squash each one flat for young babies.',
];
const TREE_NUT: Pair = [
  'Không cho hạt nguyên hoặc giã thô cho trẻ dưới 5 tuổi; chỉ dùng dạng bơ mịn pha loãng hoặc xay thật mịn.',
  'No whole or roughly crushed nuts under age 5; use only smooth nut butter, thinned, or very finely ground nuts.',
];

interface FoodSpec {
  name: Pair;
  syn?: [vi: string[], en: string[]];
  group: FoodGroup;
  allergen?: FoodAllergen;
  iron?: boolean;
  /** Default 6 (the diary opens at 6 months). */
  minAge?: number;
  /** Default true. */
  suggest?: boolean;
  priority: number;
  choking?: Pair;
  prep: Prep[];
  sources?: Source[];
}

/** A catalogue entry; sources follow what the entry says (iron, allergen, fish, choking, age). */
function food(id: string, f: FoodSpec): SolidsSeed<FoodContent> {
  const minAgeMonths = f.minAge ?? 6;
  const sources: Source[] = [S.nhsFrom6Months];
  if (f.iron) sources.push(S.cdcIron);
  if (f.allergen) sources.push(S.asciaIntroSolids);
  if (f.allergen === 'fish' || f.allergen === 'shellfish') sources.push(S.fdaFish);
  if (f.choking) sources.push(S.nhsChokingGagging);
  if (minAgeMonths > 6) sources.push(S.nhsFoodsToAvoid);
  sources.push(...(f.sources ?? []));
  return {
    id,
    reviewerLabel: NUTRITION,
    data: {
      name: t(...f.name),
      synonyms: { vi: f.syn?.[0] ?? [], en: f.syn?.[1] ?? [] },
      group: f.group,
      allergen: f.allergen ?? null,
      ironRich: f.iron ?? false,
      minAgeMonths,
      prep: f.prep,
      chokingNote: f.choking ? t(...f.choking) : none,
      suggest: f.suggest ?? true,
      priority: f.priority,
      sources: [...new Map(sources.map((s) => [s.url, s])).values()],
    },
  };
}

const vegetables: SolidsSeed<FoodContent>[] = [
  food('fd_pumpkin', {
    name: ['Bí đỏ', 'Pumpkin'],
    syn: [
      ['bí ngô', 'bí rợ'],
      ['squash', 'kabocha', 'butternut'],
    ],
    group: 'vegetable',
    priority: 90,
    prep: [
      smooth(
        'Gọt vỏ, bỏ hạt, hấp mềm rồi nghiền hoặc xay mịn với chút sữa của bé hay nước hấp.',
        "Peel, deseed and steam until soft, then mash or blend smooth with a little of your baby's milk or the steaming water.",
      ),
      mashed(
        'Hấp mềm, nghiền bằng nĩa để còn lợn cợn, trộn vào cháo.',
        'Steam until soft and fork-mash, leaving soft lumps; stir into congee.',
      ),
      finger(
        'Cắt que dài cỡ ngón tay người lớn, hấp đến khi bóp nát dễ dàng giữa hai ngón tay.',
        'Cut into sticks the length of an adult finger and steam until they squash easily between two fingers.',
      ),
      pieces(
        'Hấp mềm, cắt hạt lựu cỡ hạt đậu để bé tập nhặt.',
        'Steam until soft and dice into pea-sized pieces for your baby to pick up.',
      ),
      FAMILY_CUT,
    ],
  }),
  food('fd_carrot', {
    name: ['Cà rốt', 'Carrot'],
    syn: [['củ cà rốt'], ['carrots']],
    group: 'vegetable',
    priority: 85,
    choking: [
      'Cà rốt sống rất cứng, dễ gây hóc: không cho bé miếng hay que sống. Luôn nấu đến khi bóp nát được; từ 12 tháng có thể nạo sợi thật mịn.',
      'Raw carrot is hard and a choking risk: no raw pieces or sticks. Always cook it until it squashes easily; from 12 months it can be finely grated.',
    ],
    prep: [
      smooth(
        'Gọt vỏ, cắt nhỏ, hấp hoặc luộc thật mềm rồi xay mịn.',
        'Peel and chop, steam or boil until very soft, then blend smooth.',
      ),
      mashed(
        'Nấu mềm, nghiền thô hoặc băm nhỏ trộn cháo.',
        'Cook until soft, then mash roughly or chop finely into congee.',
      ),
      finger(
        'Cắt que dài cỡ ngón tay, hấp 12–15 phút đến khi bóp nát được.',
        'Cut into finger-length sticks and steam for 12–15 minutes until they squash easily.',
      ),
      pieces('Nấu mềm, thái hạt lựu nhỏ.', 'Cook until soft and dice small.'),
      FAMILY_CUT,
    ],
  }),
  food('fd_broccoli', {
    name: ['Bông cải xanh', 'Broccoli'],
    syn: [['súp lơ xanh'], ['calabrese']],
    group: 'vegetable',
    priority: 75,
    prep: [
      smooth(
        'Hấp mềm phần hoa, xay mịn hoặc nghiền cùng khoai, cháo.',
        'Steam the florets until soft and blend, or mash them into potato or congee.',
      ),
      finger(
        'Hấp mềm cả bông nhỏ, giữ cuống dài làm tay cầm cho bé.',
        'Steam small whole florets until soft, leaving a long stalk as a handle.',
      ),
      pieces('Hấp mềm, cắt nhỏ phần hoa.', 'Steam until soft and chop the florets small.'),
      FAMILY_CUT,
    ],
  }),
  food('fd_cauliflower', {
    name: ['Súp lơ trắng', 'Cauliflower'],
    syn: [['bông cải trắng'], []],
    group: 'vegetable',
    priority: 55,
    prep: [
      smooth(
        'Hấp mềm, xay mịn; trộn với bí đỏ hoặc khoai tây cho dễ ăn.',
        'Steam until soft and blend; mix with pumpkin or potato.',
      ),
      finger(
        'Hấp mềm bông nhỏ, giữ cuống làm tay cầm.',
        'Steam small florets until soft, keeping the stalk as a handle.',
      ),
      pieces('Hấp mềm, cắt nhỏ.', 'Steam until soft and chop small.'),
    ],
  }),
  food('fd_katuk', {
    name: ['Rau ngót', 'Katuk'],
    syn: [['bồ ngót'], ['sweet leaf', 'star gooseberry leaves']],
    group: 'vegetable',
    iron: true,
    priority: 80,
    prep: [
      smooth(
        'Tuốt lá, rửa sạch, nấu chín trong cháo rồi xay mịn cùng cháo.',
        'Strip and wash the leaves, cook them in congee, then blend with it.',
      ),
      mashed(
        'Băm thật nhỏ, cho vào cháo lúc gần chín, đun thêm vài phút.',
        'Chop very finely and add to congee near the end; cook a few more minutes.',
      ),
      pieces(
        'Thái nhỏ lá, nấu mềm trong cháo đặc hoặc canh.',
        'Chop the leaves small and cook until soft in thick congee or soup.',
      ),
      family(
        'Canh rau ngót của cả nhà: múc phần của bé trước khi nêm, thái nhỏ lá.',
        "Family katuk soup: take your child's portion before seasoning and chop the leaves small.",
      ),
    ],
  }),
  food('fd_amaranth', {
    name: ['Rau dền', 'Amaranth greens'],
    syn: [
      ['rau dền đỏ', 'rau dền cơm'],
      ['Chinese spinach', 'red amaranth'],
    ],
    group: 'vegetable',
    iron: true,
    priority: 75,
    prep: [
      smooth(
        'Dùng lá và ngọn non, luộc chín, xay mịn trộn cháo; rau dền đỏ làm món có màu tím đỏ.',
        'Use the leaves and tender tips, boil and blend into congee; red amaranth turns food purple-red.',
      ),
      mashed('Băm nhỏ, nấu trong cháo lợn cợn.', 'Chop finely and cook into lumpy congee.'),
      pieces(
        'Thái nhỏ, nấu mềm trong canh hoặc cháo đặc.',
        'Chop small and cook until soft in soup or thick congee.',
      ),
      FAMILY_CUT,
    ],
  }),
  food('fd_malabar_spinach', {
    name: ['Mồng tơi', 'Malabar spinach'],
    syn: [['mùng tơi'], ['Ceylon spinach', 'vine spinach']],
    group: 'vegetable',
    iron: true,
    priority: 70,
    prep: [
      smooth(
        'Dùng lá, nấu chín trong cháo hoặc luộc rồi xay mịn; rau nhớt, mát, giúp phân mềm.',
        'Use the leaves, cook them in congee or boil, then blend; the slippery leaves help keep stools soft.',
      ),
      mashed(
        'Băm thật nhỏ, cho vào cháo lúc gần chín.',
        'Chop very finely and stir into congee near the end.',
      ),
      pieces(
        'Thái nhỏ, nấu trong canh cua, canh tôm.',
        'Chop small and cook in crab or shrimp soup.',
      ),
      FAMILY_CUT,
    ],
  }),
  food('fd_spinach', {
    name: ['Cải bó xôi', 'Spinach'],
    syn: [
      ['rau chân vịt', 'rau bina'],
      ['English spinach', 'baby spinach'],
    ],
    group: 'vegetable',
    iron: true,
    priority: 70,
    prep: [
      smooth(
        'Chần chín lá, xay mịn với cháo, khoai tây hoặc đậu phụ.',
        'Blanch the leaves until wilted and blend with congee, potato or tofu.',
      ),
      mashed('Băm nhỏ, trộn cháo hoặc khoai nghiền.', 'Chop finely into congee or mashed potato.'),
      pieces(
        'Thái nhỏ, cho vào trứng tráng, súp hoặc mì.',
        'Chop small into omelette, soup or noodles.',
      ),
      FAMILY_CUT,
    ],
  }),
  food('fd_jute_leaves', {
    name: ['Rau đay', 'Jute leaves'],
    syn: [['rau đay đỏ'], ['jute mallow', 'molokhia']],
    group: 'vegetable',
    iron: true,
    priority: 50,
    prep: [
      mashed(
        'Tuốt lá, băm thật nhỏ, nấu trong cháo hoặc canh cua; rau nhớt, dễ nuốt.',
        'Strip the leaves, chop very finely and cook in congee or crab soup; they are slippery and easy to swallow.',
      ),
      pieces('Thái nhỏ, nấu mềm trong canh.', 'Chop small and cook until soft in soup.'),
      FAMILY_CUT,
    ],
  }),
  food('fd_water_spinach', {
    name: ['Rau muống', 'Water spinach'],
    syn: [['rau muống nước'], ['morning glory', 'kangkong']],
    group: 'vegetable',
    priority: 40,
    choking: [
      'Cọng rau muống dai, nhiều xơ: chỉ dùng lá và ngọn non, thái thật nhỏ; không cho bé cọng dài.',
      'Water spinach stems are tough and stringy: use only the leaves and tender tips, chopped very finely; no long stems.',
    ],
    prep: [
      mashed(
        'Dùng lá non, luộc chín, băm thật nhỏ trộn cháo.',
        'Boil the young leaves, chop very finely and mix into congee.',
      ),
      pieces('Lá luộc mềm thái nhỏ.', 'Soft boiled leaves, chopped small.'),
      FAMILY_CUT,
    ],
  }),
  food('fd_choy_sum', {
    name: ['Cải ngọt', 'Choy sum'],
    syn: [['cải ngồng'], ['Chinese flowering cabbage']],
    group: 'vegetable',
    priority: 60,
    prep: [
      smooth(
        'Luộc chín phần lá, xay mịn với cháo.',
        'Boil the leaves until soft and blend with congee.',
      ),
      mashed(
        'Băm nhỏ lá, cho vào cháo lúc gần chín.',
        'Chop the leaves finely into congee near the end.',
      ),
      pieces(
        'Luộc mềm, thái nhỏ cả lá và cọng non.',
        'Boil until soft and chop the leaves and tender stems small.',
      ),
      FAMILY_CUT,
    ],
  }),
  food('fd_bok_choy', {
    name: ['Cải thìa', 'Bok choy'],
    syn: [['cải chíp', 'cải bẹ trắng'], ['pak choi']],
    group: 'vegetable',
    priority: 55,
    prep: [
      mashed(
        'Luộc mềm, băm nhỏ trộn cháo hoặc mì.',
        'Boil until soft and chop finely into congee or noodles.',
      ),
      pieces(
        'Luộc mềm, thái nhỏ phần bẹ và lá.',
        'Boil until soft and chop the stems and leaves small.',
      ),
      FAMILY_CUT,
    ],
  }),
  food('fd_chayote', {
    name: ['Su su', 'Chayote'],
    syn: [['quả su su'], ['choko', 'mirliton']],
    group: 'vegetable',
    priority: 50,
    prep: [
      smooth(
        'Gọt vỏ, bỏ hạt, hấp mềm rồi xay mịn.',
        'Peel, remove the seed, steam until soft and blend.',
      ),
      finger(
        'Cắt que dài, hấp mềm đến khi bóp nát được.',
        'Cut into long sticks and steam until they squash easily.',
      ),
      pieces('Hấp hoặc luộc mềm, thái hạt lựu.', 'Steam or boil until soft and dice.'),
      FAMILY_CUT,
    ],
  }),
  food('fd_zucchini', {
    name: ['Bí ngòi', 'Zucchini'],
    syn: [['bí ngồi'], ['courgette']],
    group: 'vegetable',
    priority: 55,
    prep: [
      smooth(
        'Hấp mềm cả vỏ, xay mịn hoặc nghiền.',
        'Steam until soft, skin on, and blend or mash.',
      ),
      finger(
        'Cắt que dài cỡ ngón tay, hấp mềm; để vỏ giúp que đỡ nát.',
        'Cut into finger-length sticks and steam until soft; the skin helps them hold together.',
      ),
      pieces('Hấp mềm, thái hạt lựu.', 'Steam until soft and dice.'),
      FAMILY_CUT,
    ],
  }),
  food('fd_winter_melon', {
    name: ['Bí xanh', 'Winter melon'],
    syn: [['bí đao'], ['ash gourd', 'wax gourd']],
    group: 'vegetable',
    priority: 55,
    prep: [
      smooth(
        'Gọt vỏ, bỏ ruột, nấu mềm trong cháo rồi xay mịn.',
        'Peel, remove the pith, cook in congee until soft and blend.',
      ),
      mashed('Nấu mềm, nghiền thô trong cháo.', 'Cook until soft and mash roughly into congee.'),
      pieces(
        'Thái hạt lựu, nấu canh đến khi mềm trong.',
        'Dice and cook in soup until soft and translucent.',
      ),
      FAMILY_CUT,
    ],
  }),
  food('fd_bottle_gourd', {
    name: ['Bầu', 'Bottle gourd'],
    syn: [
      ['quả bầu', 'trái bầu'],
      ['calabash', 'opo squash'],
    ],
    group: 'vegetable',
    priority: 45,
    prep: [
      smooth(
        'Gọt vỏ, nấu mềm rồi xay mịn với cháo.',
        'Peel, cook until soft and blend with congee.',
      ),
      mashed('Nấu mềm, nghiền thô.', 'Cook until soft and mash roughly.'),
      pieces('Thái hạt lựu, nấu canh mềm.', 'Dice and cook in soup until soft.'),
      FAMILY_CUT,
    ],
  }),
  food('fd_luffa', {
    name: ['Mướp', 'Luffa'],
    syn: [
      ['mướp hương', 'mướp ngọt'],
      ['sponge gourd', 'loofah'],
    ],
    group: 'vegetable',
    priority: 45,
    prep: [
      smooth(
        'Gọt vỏ, nấu mềm trong cháo rồi xay mịn.',
        'Peel, cook in congee until soft and blend.',
      ),
      mashed(
        'Nấu mềm, nghiền thô trộn cháo tôm hoặc cua.',
        'Cook until soft and mash roughly into shrimp or crab congee.',
      ),
      pieces('Thái hạt lựu, nấu canh mềm.', 'Dice and cook in soup until soft.'),
      FAMILY_CUT,
    ],
  }),
  food('fd_kohlrabi', {
    name: ['Su hào', 'Kohlrabi'],
    syn: [['củ su hào'], []],
    group: 'vegetable',
    priority: 40,
    choking: [
      'Su hào sống rất cứng: luôn nấu mềm, không cho miếng sống.',
      'Raw kohlrabi is very hard: always cook it soft; no raw pieces.',
    ],
    prep: [
      smooth(
        'Gọt kỹ vỏ xơ, luộc thật mềm rồi xay mịn.',
        'Peel off the fibrous skin, boil until very soft and blend.',
      ),
      finger(
        'Cắt que, luộc hoặc hấp đến khi bóp nát được.',
        'Cut into sticks and boil or steam until they squash easily.',
      ),
      pieces('Luộc mềm, thái hạt lựu.', 'Boil until soft and dice.'),
      FAMILY_CUT,
    ],
  }),
  food('fd_cabbage', {
    name: ['Bắp cải', 'Cabbage'],
    syn: [['cải bắp'], ['white cabbage']],
    group: 'vegetable',
    priority: 40,
    prep: [
      mashed('Luộc mềm, băm nhỏ trộn cháo.', 'Boil until soft and chop finely into congee.'),
      pieces('Luộc hoặc xào mềm, thái nhỏ.', 'Boil or stir-fry until soft and chop small.'),
      FAMILY_CUT,
    ],
  }),
  food('fd_tomato', {
    name: ['Cà chua', 'Tomato'],
    syn: [['cà chua chín'], ['ripe tomato']],
    group: 'vegetable',
    priority: 55,
    prep: [
      smooth(
        'Chần, bóc vỏ, bỏ hạt, nấu nhừ rồi xay mịn trộn cháo; vitamin C giúp hấp thu sắt.',
        'Blanch, peel, deseed, cook down and blend into congee; its vitamin C helps iron absorption.',
      ),
      finger(
        'Quả chín mềm, bóc vỏ, cắt múi cau to cho bé cầm.',
        'Ripe, soft tomato, peeled and cut into large wedges to hold.',
      ),
      pieces('Bóc vỏ, bỏ hạt, thái hạt lựu.', 'Peel, deseed and dice.'),
      FAMILY_CUT,
    ],
  }),
  food('fd_cherry_tomato', {
    name: ['Cà chua bi', 'Cherry tomatoes'],
    syn: [['cà chua bi đỏ', 'cà chua bi vàng'], ['grape tomatoes']],
    group: 'vegetable',
    suggest: false,
    priority: 5,
    choking: [
      'Tròn, trơn, vừa khít đường thở của trẻ: luôn cắt dọc làm tư hoặc nhỏ hơn, không bao giờ cho cả quả.',
      "Round, slippery and the size of a child's airway: always cut lengthwise into quarters or smaller, never whole.",
    ],
    prep: [
      pieces(
        'Cắt dọc làm tư hoặc nhỏ hơn, bỏ bớt hạt.',
        'Cut lengthwise into quarters or smaller and remove some seeds.',
      ),
      family(
        'Cắt dọc làm tư trước khi cho vào đĩa của bé.',
        "Quarter lengthwise before putting them on your child's plate.",
      ),
    ],
  }),
  food('fd_beetroot', {
    name: ['Củ dền', 'Beetroot'],
    syn: [['củ cải đỏ'], ['beet']],
    group: 'vegetable',
    priority: 40,
    choking: [
      'Củ dền sống cứng: luôn nấu mềm, không cho miếng sống.',
      'Raw beetroot is hard: always cook it soft; no raw pieces.',
    ],
    prep: [
      smooth(
        'Luộc hoặc hấp thật mềm, bóc vỏ, xay mịn; phân và nước tiểu có thể đỏ, không đáng lo.',
        'Boil or steam until very soft, peel and blend; stools and urine may turn red, which is harmless.',
      ),
      finger(
        'Luộc mềm, cắt que; dễ nhuộm màu áo, nên dùng yếm.',
        'Boil until soft and cut into sticks; it stains, so use a bib.',
      ),
      pieces('Luộc mềm, thái hạt lựu.', 'Boil until soft and dice.'),
    ],
  }),
  food('fd_green_beans', {
    name: ['Đậu cô ve', 'Green beans'],
    syn: [
      ['đậu que', 'đậu ve'],
      ['string beans', 'French beans'],
    ],
    group: 'vegetable',
    priority: 50,
    prep: [
      smooth('Tước xơ, luộc thật mềm rồi xay mịn.', 'String, boil until very soft and blend.'),
      finger(
        'Tước xơ, luộc hoặc hấp mềm nguyên quả để bé cầm gặm.',
        'String, then boil or steam whole until soft for your baby to hold and gnaw.',
      ),
      pieces('Luộc mềm, thái khúc nhỏ.', 'Boil until soft and cut into small pieces.'),
      FAMILY_CUT,
    ],
  }),
  food('fd_okra', {
    name: ['Đậu bắp', 'Okra'],
    syn: [['mướp tây'], ["lady's fingers"]],
    group: 'vegetable',
    priority: 40,
    prep: [
      finger(
        'Luộc hoặc hấp mềm nguyên quả, cắt bỏ cuống cứng; bé cầm gặm.',
        'Boil or steam whole until soft and trim the hard stem end; your baby holds and gnaws.',
      ),
      pieces('Luộc mềm, thái lát mỏng.', 'Boil until soft and slice thinly.'),
      FAMILY_CUT,
    ],
  }),
  food('fd_eggplant', {
    name: ['Cà tím', 'Eggplant'],
    syn: [['cà dái dê'], ['aubergine', 'brinjal']],
    group: 'vegetable',
    priority: 35,
    prep: [
      mashed(
        'Hấp hoặc nướng mềm, bỏ vỏ, nghiền thô.',
        'Steam or roast until soft, remove the skin and mash roughly.',
      ),
      finger(
        'Nướng hoặc hấp mềm, cắt que dày còn vỏ để dễ cầm.',
        'Roast or steam until soft and cut into thick sticks, skin on for grip.',
      ),
      FAMILY_CUT,
    ],
  }),
  food('fd_cucumber', {
    name: ['Dưa chuột', 'Cucumber'],
    syn: [['dưa leo'], []],
    group: 'vegetable',
    priority: 20,
    choking: [
      'Dưa chuột sống giòn: cắt que to dài hơn nắm tay bé để gặm; không cắt khoanh nhỏ hay hạt lựu cho bé dưới 12 tháng.',
      "Raw cucumber is crunchy: cut thick spears longer than your baby's fist for gnawing; no small rounds or dice before 12 months.",
    ],
    prep: [
      finger(
        'Gọt vỏ, bỏ ruột, cắt que to dài để bé gặm khi mọc răng; bỏ đi miếng bị cắn vỡ ra.',
        'Peel, deseed and cut into thick long spears to gnaw when teething; take away any piece that breaks off.',
      ),
      pieces(
        'Từ 12 tháng: thái lát mỏng rồi cắt nhỏ, hoặc nạo sợi.',
        'From 12 months: slice thinly and chop, or grate.',
      ),
    ],
  }),
  food('fd_mushroom', {
    name: ['Nấm', 'Mushrooms'],
    syn: [
      ['nấm rơm', 'nấm hương', 'nấm đùi gà', 'nấm kim châm'],
      ['straw mushrooms', 'shiitake', 'king oyster mushrooms', 'enoki'],
    ],
    group: 'vegetable',
    priority: 30,
    choking: [
      'Nấm dai, trơn: nấu chín kỹ và băm nhỏ; nấm kim châm cắt thật ngắn; tránh miếng to.',
      'Mushrooms are chewy and slippery: cook them well and chop finely; cut enoki very short; avoid large pieces.',
    ],
    prep: [
      mashed('Nấu chín kỹ, băm nhỏ trộn cháo.', 'Cook well and chop finely into congee.'),
      pieces(
        'Thái hạt lựu nhỏ, xào hoặc nấu mềm.',
        'Dice small and stir-fry or simmer until soft.',
      ),
      FAMILY_CUT,
    ],
  }),
  food('fd_onion', {
    name: ['Hành tây', 'Onion'],
    syn: [['củ hành tây'], ['brown onion', 'white onion']],
    group: 'vegetable',
    priority: 25,
    prep: [
      mashed(
        'Nấu hoặc xào thật mềm, băm nhỏ cùng thịt, rau cho món thơm hơn.',
        'Cook or sauté until very soft and chop finely with meat or vegetables for flavour.',
      ),
      pieces('Xào mềm, thái nhỏ.', 'Sauté until soft and chop small.'),
      FAMILY_CUT,
    ],
  }),
  food('fd_spring_onion', {
    name: ['Hành lá', 'Spring onion'],
    syn: [['hành hoa'], ['scallion', 'green onion']],
    group: 'vegetable',
    suggest: false,
    priority: 10,
    prep: [
      mashed(
        'Thái thật nhỏ, cho vào cháo, canh lúc gần chín cho thơm.',
        'Chop very finely and add to congee or soup near the end for aroma.',
      ),
      FAMILY_CUT,
    ],
  }),
  food('fd_garlic', {
    name: ['Tỏi', 'Garlic'],
    syn: [['tép tỏi'], ['garlic clove']],
    group: 'vegetable',
    suggest: false,
    priority: 5,
    prep: [
      mashed(
        'Băm nhỏ, phi nhẹ với dầu hoặc nấu cùng thịt, rau để tạo mùi thơm thay cho gia vị mặn.',
        'Mince and sauté gently in oil, or cook with meat and vegetables, for flavour instead of salty seasoning.',
      ),
      FAMILY_CUT,
    ],
  }),
  food('fd_dill', {
    name: ['Thì là', 'Dill'],
    syn: [['rau thì là'], []],
    group: 'vegetable',
    suggest: false,
    priority: 5,
    prep: [
      mashed(
        'Thái thật nhỏ, cho vào cháo cá hoặc canh cá khi tắt bếp cho thơm.',
        'Chop very finely and add to fish congee or soup off the heat for aroma.',
      ),
      FAMILY_CUT,
    ],
  }),
  food('fd_bell_pepper', {
    name: ['Ớt chuông', 'Bell pepper'],
    syn: [
      ['ớt ngọt', 'ớt Đà Lạt'],
      ['capsicum', 'sweet pepper'],
    ],
    group: 'vegetable',
    priority: 30,
    prep: [
      smooth(
        'Nướng hoặc hấp mềm, bóc vỏ mỏng, xay mịn.',
        'Roast or steam until soft, peel off the thin skin and blend.',
      ),
      finger(
        'Nướng hoặc hấp mềm, bóc vỏ, cắt dải dày.',
        'Roast or steam until soft, peel and cut into thick strips.',
      ),
      pieces('Xào hoặc hấp mềm, thái hạt lựu.', 'Sauté or steam until soft and dice.'),
      FAMILY_CUT,
    ],
  }),
  food('fd_asparagus', {
    name: ['Măng tây', 'Asparagus'],
    syn: [['măng tây xanh'], []],
    group: 'vegetable',
    priority: 35,
    prep: [
      smooth(
        'Bỏ gốc xơ, hấp mềm rồi xay mịn.',
        'Snap off the woody ends, steam until soft and blend.',
      ),
      finger(
        'Bỏ gốc xơ, hấp mềm nguyên ngọn để bé cầm gặm.',
        'Snap off the woody ends and steam whole spears until soft to hold and gnaw.',
      ),
      pieces('Hấp mềm, cắt khúc nhỏ.', 'Steam until soft and cut into small pieces.'),
    ],
  }),
];

const fruits: SolidsSeed<FoodContent>[] = [
  food('fd_banana', {
    name: ['Chuối', 'Banana'],
    syn: [['chuối tiêu', 'chuối sứ', 'chuối cau', 'chuối già'], ['ripe banana']],
    group: 'fruit',
    priority: 70,
    prep: [
      smooth(
        'Chọn quả chín, nghiền mịn bằng nĩa; thêm chút sữa của bé nếu đặc.',
        "Choose a ripe one and mash it smooth with a fork; add a little of your baby's milk if thick.",
      ),
      mashed('Nghiền thô, để lợn cợn mềm.', 'Mash roughly, leaving soft lumps.'),
      finger(
        'Bóc bớt vỏ, để phần vỏ dưới làm tay cầm, hoặc cắt khúc dài rồi bổ dọc.',
        'Peel partly and leave the bottom of the skin as a handle, or cut long pieces and split them lengthwise.',
      ),
      pieces('Cắt miếng nhỏ cỡ đầu ngón tay.', 'Cut into fingertip-sized pieces.'),
    ],
  }),
  food('fd_avocado', {
    name: ['Quả bơ', 'Avocado'],
    syn: [['bơ', 'trái bơ', 'bơ sáp'], []],
    group: 'fruit',
    priority: 70,
    prep: [
      smooth(
        'Nạo quả bơ chín, nghiền mịn; trộn với chuối, khoai lang hoặc sữa chua.',
        'Scoop out ripe avocado and mash smooth; mix with banana, sweet potato or yogurt.',
      ),
      finger(
        'Cắt lát dày, lăn qua yến mạch xay hoặc vừng xay mịn cho đỡ trơn, dễ cầm.',
        'Cut into thick slices and roll in ground oats or ground sesame so they are easier to hold.',
      ),
      pieces('Cắt hạt lựu từ quả chín mềm.', 'Dice ripe, soft avocado.'),
    ],
  }),
  food('fd_papaya', {
    name: ['Đu đủ', 'Papaya'],
    syn: [['đu đủ chín'], ['pawpaw']],
    group: 'fruit',
    priority: 65,
    prep: [
      smooth(
        'Chọn quả chín, bỏ hạt, nạo hoặc nghiền mịn.',
        'Choose ripe papaya, remove the seeds and scrape or mash smooth.',
      ),
      finger('Cắt que dày từ quả chín mềm.', 'Cut thick sticks from ripe, soft papaya.'),
      pieces('Cắt hạt lựu.', 'Dice.'),
    ],
  }),
  food('fd_dragon_fruit', {
    name: ['Thanh long', 'Dragon fruit'],
    syn: [
      ['thanh long ruột đỏ', 'thanh long ruột trắng'],
      ['pitaya', 'pitahaya'],
    ],
    group: 'fruit',
    priority: 55,
    prep: [
      smooth(
        'Nạo thịt quả, nghiền mịn; hạt nhỏ không cần bỏ. Ruột đỏ có thể làm phân, nước tiểu đỏ.',
        'Scoop and mash smooth; the tiny seeds are fine. Red-fleshed fruit can turn stools and urine red.',
      ),
      finger('Cắt que dày, bỏ vỏ.', 'Cut into thick sticks, skin removed.'),
      pieces('Cắt hạt lựu.', 'Dice.'),
    ],
  }),
  food('fd_mango', {
    name: ['Xoài', 'Mango'],
    syn: [['xoài cát', 'xoài chín', 'xoài keo'], ['ripe mango']],
    group: 'fruit',
    priority: 60,
    prep: [
      smooth(
        'Chọn quả chín, nạo thịt, nghiền mịn.',
        'Choose a ripe mango, scoop out the flesh and mash smooth.',
      ),
      finger(
        'Cắt miếng dài, dày từ quả chín mềm, lăn qua yến mạch xay cho đỡ trơn.',
        'Cut long, thick slices from ripe mango and roll them in ground oats so they are less slippery.',
      ),
      pieces('Cắt hạt lựu.', 'Dice.'),
    ],
  }),
  food('fd_watermelon', {
    name: ['Dưa hấu', 'Watermelon'],
    syn: [['dưa hấu đỏ', 'dưa hấu vàng'], []],
    group: 'fruit',
    priority: 45,
    choking: ['Bỏ hết hạt đen trước khi cho bé.', 'Remove all the black seeds first.'],
    prep: [
      finger(
        'Bỏ hạt, cắt que dày dài cho bé cầm.',
        'Remove the seeds and cut into thick long sticks to hold.',
      ),
      pieces('Bỏ hạt, cắt hạt lựu.', 'Remove the seeds and dice.'),
    ],
  }),
  food('fd_apple', {
    name: ['Táo', 'Apple'],
    syn: [['táo tây'], []],
    group: 'fruit',
    priority: 50,
    choking: [
      'Táo sống cứng, dễ gây hóc: hấp hoặc luộc mềm, hoặc nạo thật mịn; không cho miếng táo sống.',
      'Raw apple is hard and a choking risk: steam or poach it soft, or grate it finely; no raw apple pieces.',
    ],
    prep: [
      smooth(
        'Gọt vỏ, bỏ lõi, hấp mềm rồi nghiền hoặc xay mịn.',
        'Peel, core and steam until soft, then mash or blend.',
      ),
      finger(
        'Cắt múi cau dày, hấp đến khi bóp nát được.',
        'Cut into thick wedges and steam until they squash easily.',
      ),
      pieces(
        'Hấp mềm, cắt nhỏ; từ 12 tháng có thể nạo sợi sống thật mịn.',
        'Steam until soft and chop; from 12 months, finely grated raw apple is fine.',
      ),
    ],
  }),
  food('fd_pear', {
    name: ['Lê', 'Pear'],
    syn: [['quả lê'], []],
    group: 'fruit',
    priority: 45,
    choking: [
      'Lê còn cứng cũng dễ hóc như táo sống: hấp mềm trước khi cho bé.',
      'A firm pear is as risky as raw apple: steam it soft first.',
    ],
    prep: [
      smooth(
        'Gọt vỏ, bỏ lõi; lê chín mềm nghiền sống, lê còn cứng thì hấp mềm rồi nghiền.',
        'Peel and core; mash a ripe, soft pear raw, or steam a firm one until soft first.',
      ),
      finger(
        'Lê chín thật mềm cắt que dày; lê cứng hấp mềm trước.',
        'Cut a very ripe pear into thick sticks; steam a firm one first.',
      ),
      pieces('Cắt nhỏ miếng lê chín mềm.', 'Chop ripe, soft pear small.'),
    ],
  }),
  food('fd_orange', {
    name: ['Cam', 'Orange'],
    syn: [['cam sành', 'cam canh'], []],
    group: 'fruit',
    priority: 45,
    prep: [
      finger(
        'Cắt múi cau cả vỏ, bỏ hạt để bé mút phần thịt; hoặc tách múi, bóc màng.',
        'Cut into wedges with the peel on and the seeds out for sucking, or segment and remove the membrane.',
      ),
      pieces(
        'Bóc màng, bỏ hạt, cắt nhỏ tép cam.',
        'Remove the membrane and seeds and chop the flesh small.',
      ),
    ],
  }),
  food('fd_mandarin', {
    name: ['Quýt', 'Mandarin'],
    syn: [
      ['quýt hồng', 'quýt đường'],
      ['tangerine', 'clementine'],
    ],
    group: 'fruit',
    priority: 35,
    choking: [
      'Múi quýt nguyên có màng dai và hạt: bỏ hạt, bóc màng, cắt nhỏ cho bé dưới 12 tháng.',
      'Whole segments have tough membranes and seeds: deseed, remove the membrane and chop for babies under 12 months.',
    ],
    prep: [
      pieces(
        'Bóc màng, bỏ hạt, cắt nhỏ tép quýt.',
        'Remove the membrane and seeds and chop the flesh small.',
      ),
      family(
        'Từ 12 tháng: múi quýt bỏ hạt, cắt đôi.',
        'From 12 months: deseeded segments cut in half.',
      ),
    ],
  }),
  food('fd_grape', {
    name: ['Nho', 'Grapes'],
    syn: [['nho xanh', 'nho đỏ', 'nho đen'], []],
    group: 'fruit',
    suggest: false,
    priority: 5,
    choking: [
      'Nho nguyên quả là nguyên nhân gây hóc hay gặp ở trẻ nhỏ: luôn bỏ hạt, cắt dọc làm tư cho đến khi trẻ ít nhất 5 tuổi.',
      'Whole grapes are a common cause of choking in young children: always deseed and cut them lengthwise into quarters until at least age 5.',
    ],
    prep: [
      pieces(
        'Bỏ hạt, cắt dọc làm tư hoặc nhỏ hơn.',
        'Deseed and cut lengthwise into quarters or smaller.',
      ),
      family(
        'Luôn cắt dọc làm tư, kể cả khi bé đã lớn hơn.',
        'Always quarter lengthwise, even as your child gets older.',
      ),
    ],
  }),
  food('fd_longan', {
    name: ['Nhãn', 'Longan'],
    syn: [['nhãn lồng', 'nhãn xuồng'], []],
    group: 'fruit',
    suggest: false,
    priority: 5,
    choking: ROUND_FRUIT,
    prep: [pieces('Bóc vỏ, bỏ hạt, cắt nhỏ cùi nhãn.', 'Peel, deseed and chop the flesh small.')],
  }),
  food('fd_lychee', {
    name: ['Vải', 'Lychee'],
    syn: [['vải thiều', 'trái vải'], ['litchi']],
    group: 'fruit',
    suggest: false,
    priority: 5,
    choking: ROUND_FRUIT,
    prep: [pieces('Bóc vỏ, bỏ hạt, cắt nhỏ cùi vải.', 'Peel, deseed and chop the flesh small.')],
  }),
  food('fd_rambutan', {
    name: ['Chôm chôm', 'Rambutan'],
    syn: [['chôm chôm nhãn'], []],
    group: 'fruit',
    suggest: false,
    priority: 5,
    choking: ROUND_FRUIT,
    prep: [
      pieces(
        'Bóc vỏ, bỏ hạt và lớp vỏ lụa cứng, cắt nhỏ.',
        'Peel, remove the seed and its papery coat, and chop small.',
      ),
    ],
  }),
  food('fd_kiwi', {
    name: ['Kiwi', 'Kiwi fruit'],
    syn: [['quả kiwi'], ['kiwifruit']],
    group: 'fruit',
    priority: 35,
    prep: [
      smooth(
        'Gọt vỏ, nghiền mịn quả chín; vị chua có thể làm đỏ da quanh miệng.',
        'Peel and mash ripe kiwi; the acidity can redden the skin around the mouth.',
      ),
      finger('Gọt vỏ, cắt múi dày.', 'Peel and cut into thick wedges.'),
      pieces('Cắt hạt lựu.', 'Dice.'),
    ],
  }),
  food('fd_strawberry', {
    name: ['Dâu tây', 'Strawberries'],
    syn: [['dâu Đà Lạt'], []],
    group: 'fruit',
    priority: 35,
    prep: [
      smooth(
        'Rửa kỹ, bỏ cuống, nghiền mịn hoặc trộn sữa chua; có thể làm đỏ da quanh miệng.',
        'Wash well, hull and mash, or mix into yogurt; it can redden the skin around the mouth.',
      ),
      finger(
        'Quả to chín mềm, bỏ cuống, cắt dọc làm đôi hoặc làm tư.',
        'Large ripe berries, hulled and cut lengthwise in halves or quarters.',
      ),
      pieces('Cắt nhỏ cỡ hạt đậu.', 'Chop into pea-sized pieces.'),
    ],
  }),
  food('fd_blueberry', {
    name: ['Việt quất', 'Blueberries'],
    syn: [['quả việt quất'], []],
    group: 'fruit',
    priority: 30,
    choking: [
      'Quả nhỏ, tròn: bóp dẹt hoặc cắt đôi, cắt tư cho bé dưới 12 tháng; không cho cả nắm.',
      'Small and round: squash flat or cut into halves or quarters before 12 months; never a handful.',
    ],
    prep: [
      smooth('Nghiền nát hoặc xay cùng sữa chua, yến mạch.', 'Mash, or blend into yogurt or oats.'),
      pieces('Bóp dẹt từng quả hoặc cắt tư.', 'Squash each berry flat or cut it into quarters.'),
    ],
  }),
  food('fd_pineapple', {
    name: ['Dứa', 'Pineapple'],
    syn: [['thơm', 'khóm'], []],
    group: 'fruit',
    priority: 25,
    prep: [
      pieces(
        'Bỏ mắt và lõi xơ cứng, thái nhỏ phần thịt chín mềm; vị chua có thể làm đỏ quanh miệng.',
        'Remove the eyes and hard core and chop the ripe flesh small; the acidity can redden the skin around the mouth.',
      ),
      finger(
        'Cắt que dài từ phần thịt chín, bỏ lõi; bé mút và gặm.',
        'Cut long sticks of ripe flesh, core removed, to suck and gnaw.',
      ),
      FAMILY_CUT,
    ],
  }),
  food('fd_sapodilla', {
    name: ['Hồng xiêm', 'Sapodilla'],
    syn: [
      ['sapôchê', 'xa pô chê'],
      ['chikoo', 'sapota'],
    ],
    group: 'fruit',
    priority: 35,
    choking: [
      'Hạt đen trơn, có mấu nhọn: bỏ hết hạt trước khi cho bé.',
      'The black seeds are slippery and hooked: remove them all first.',
    ],
    prep: [
      smooth(
        'Chọn quả chín mềm, bỏ vỏ và hạt, nghiền mịn.',
        'Choose a soft, ripe fruit, remove the skin and seeds and mash smooth.',
      ),
      pieces('Bỏ hạt, cắt nhỏ.', 'Remove the seeds and chop small.'),
    ],
  }),
  food('fd_custard_apple', {
    name: ['Na', 'Custard apple'],
    syn: [
      ['mãng cầu ta', 'mãng cầu dai'],
      ['sugar apple', 'sweetsop'],
    ],
    group: 'fruit',
    priority: 25,
    choking: [
      'Nhiều hạt đen trơn, dễ hóc: bỏ hết hạt, chỉ dùng phần thịt.',
      'Many slippery black seeds that can choke: remove them all and use only the flesh.',
    ],
    prep: [
      smooth(
        'Bỏ hết hạt, nghiền mịn phần thịt quả chín.',
        'Remove every seed and mash the ripe flesh smooth.',
      ),
      pieces('Bỏ hạt, xé nhỏ múi.', 'Deseed and pull the segments into small pieces.'),
    ],
  }),
  food('fd_star_apple', {
    name: ['Vú sữa', 'Star apple'],
    syn: [['trái vú sữa'], ['milk fruit', 'caimito']],
    group: 'fruit',
    priority: 25,
    choking: [
      'Bỏ hết hạt và lớp màng sát vỏ có nhựa.',
      'Remove all the seeds and the sticky layer under the skin.',
    ],
    prep: [
      smooth(
        'Bổ đôi, nạo phần thịt mềm, bỏ hạt, nghiền mịn.',
        'Halve, scoop out the soft flesh, remove the seeds and mash smooth.',
      ),
      pieces('Bỏ hạt, cắt nhỏ phần thịt.', 'Remove the seeds and chop the flesh small.'),
    ],
  }),
  food('fd_melon', {
    name: ['Dưa lưới', 'Cantaloupe'],
    syn: [
      ['dưa vàng', 'dưa lê'],
      ['rockmelon', 'muskmelon', 'honeydew'],
    ],
    group: 'fruit',
    priority: 35,
    prep: [
      smooth('Nạo thịt quả chín, nghiền mịn.', 'Scrape out the ripe flesh and mash smooth.'),
      finger(
        'Bỏ hạt, cắt que dày từ quả chín mềm.',
        'Deseed and cut thick sticks from ripe, soft melon.',
      ),
      pieces('Cắt hạt lựu.', 'Dice.'),
    ],
  }),
];

const grains: SolidsSeed<FoodContent>[] = [
  food('fd_rice', {
    name: ['Gạo tẻ', 'Rice'],
    syn: [
      ['gạo', 'cơm', 'cháo', 'cháo trắng'],
      ['white rice', 'congee', 'rice porridge'],
    ],
    group: 'grain',
    priority: 80,
    prep: [
      smooth(
        'Nấu cháo thật nhừ rồi rây hoặc xay mịn, đặc đến mức không chảy khỏi thìa.',
        'Cook congee until very soft, then sieve or blend it, thick enough not to run off the spoon.',
      ),
      mashed(
        'Khoảng 7–8 tháng: cháo nhừ không rây, hạt gạo vỡ, lợn cợn mềm.',
        'Around 7–8 months: soft unsieved congee with broken grains and soft lumps.',
      ),
      pieces(
        'Khoảng 9–11 tháng: cháo đặc hạt nguyên hoặc cơm nát nấu mềm.',
        'Around 9–11 months: thick congee with whole grains, or very soft rice.',
      ),
      finger(
        'Từ khoảng 9 tháng: cơm tẻ nấu mềm nắm thành viên nhỏ hoặc thỏi dẹt.',
        'From about 9 months: soft-cooked rice pressed into small balls or flat logs.',
      ),
      family(
        'Từ khoảng 12 tháng: cơm mềm cùng mâm với gia đình.',
        'From about 12 months: soft rice at the family table.',
      ),
    ],
  }),
  food('fd_brown_rice', {
    name: ['Gạo lứt', 'Brown rice'],
    syn: [['gạo lức'], ['wholegrain rice']],
    group: 'grain',
    priority: 30,
    prep: [
      smooth(
        'Ngâm vài giờ, nấu thật nhừ rồi xay mịn; nên trộn với gạo tẻ.',
        'Soak for a few hours, cook until very soft and blend; best mixed with white rice.',
      ),
      pieces(
        'Nấu cơm nát với nhiều nước, trộn cùng gạo tẻ.',
        'Cook very soft with plenty of water, mixed with white rice.',
      ),
      family(
        'Trộn một phần gạo lứt vào cơm cả nhà, xen kẽ với các loại tinh bột khác.',
        "Mix some brown rice into the family's rice, and rotate it with other starches.",
      ),
    ],
  }),
  food('fd_fortified_cereal', {
    name: ['Bột ăn dặm tăng cường sắt', 'Iron-fortified baby cereal'],
    syn: [
      ['bột ngũ cốc ăn dặm', 'bột gạo ăn dặm', 'bột ăn dặm'],
      ['infant cereal', 'baby rice cereal', 'baby cereal'],
    ],
    group: 'grain',
    iron: true,
    priority: 85,
    prep: [
      smooth(
        'Pha với nước ấm, sữa mẹ hoặc sữa công thức theo bao bì, đặc đến mức không chảy khỏi thìa. Chọn loại không thêm đường, muối.',
        'Mix with warm water, breast milk or formula as the pack says, thick enough to stay on the spoon. Choose one with no added sugar or salt.',
      ),
      mashed(
        'Trộn vào cháo, rau củ nghiền hoặc trái cây để thêm sắt. Đọc nhãn: một số loại có sữa hoặc lúa mì.',
        'Stir into congee, mashed vegetables or fruit for extra iron. Read the label: some contain milk or wheat.',
      ),
      finger(
        'Trộn với chuối nghiền, áp chảo thành bánh mềm cắt que.',
        'Mix with mashed banana and pan-cook into soft pancakes cut into fingers.',
      ),
    ],
  }),
  food('fd_oats', {
    name: ['Yến mạch', 'Oats'],
    syn: [
      ['yến mạch cán', 'bột yến mạch', 'cháo yến mạch'],
      ['rolled oats', 'porridge oats', 'oatmeal'],
    ],
    group: 'grain',
    priority: 55,
    prep: [
      smooth(
        'Xay mịn yến mạch cán, nấu với nước hoặc sữa của bé đến khi sánh mịn.',
        "Grind rolled oats fine and cook with water or your baby's milk until smooth and creamy.",
      ),
      mashed(
        'Nấu yến mạch cán đến khi mềm, để nguyên hạt.',
        'Cook rolled oats until soft, leaving the flakes whole.',
      ),
      finger(
        'Trộn với chuối nghiền, nướng hoặc áp chảo thành bánh mềm cắt que.',
        'Mix with mashed banana and bake or pan-cook into soft fingers.',
      ),
      family(
        'Cháo yến mạch, bánh yến mạch cùng gia đình.',
        'Oat porridge or oat bakes with the family.',
      ),
    ],
  }),
  food('fd_wheat_noodles', {
    name: ['Mì sợi', 'Wheat noodles'],
    syn: [
      ['mì tươi', 'mì udon', 'mì sợi lúa mì'],
      ['udon', 'fresh noodles'],
    ],
    group: 'grain',
    allergen: 'wheat',
    priority: 45,
    prep: [
      mashed(
        'Luộc thật mềm, cắt sợi ngắn 1–2 cm, trộn cùng thịt, rau. Không dùng mì gói vì rất mặn.',
        'Boil until very soft, cut into 1–2 cm lengths and mix with meat and vegetables. Skip instant noodles: they are very salty.',
      ),
      finger(
        'Luộc mềm, để sợi dài vừa phải cho bé bốc.',
        'Boil until soft and leave medium lengths for your baby to grab.',
      ),
      family(
        'Mì nước cùng gia đình, phần nước dùng của bé không nêm, cắt sợi ngắn.',
        "Noodle soup with the family; your child's broth unseasoned and the noodles cut short.",
      ),
    ],
  }),
  food('fd_rice_vermicelli', {
    name: ['Bún', 'Rice vermicelli'],
    syn: [
      ['bún tươi', 'bún gạo', 'bún khô'],
      ['rice noodles', 'bun'],
    ],
    group: 'grain',
    priority: 40,
    prep: [
      mashed(
        'Trần qua nước sôi, cắt ngắn 1–2 cm, trộn cùng thịt cá và rau.',
        'Blanch in boiling water, cut into 1–2 cm lengths and mix with meat or fish and vegetables.',
      ),
      finger(
        'Trần mềm, để sợi vừa phải cho bé bốc.',
        'Blanch until soft and leave medium lengths to grab.',
      ),
      family(
        'Bún cá, bún thịt cùng gia đình; cắt sợi ngắn, nước dùng của bé không nêm.',
        "Fish or pork noodle soup with the family; noodles cut short, your child's broth unseasoned.",
      ),
    ],
  }),
  food('fd_pho_noodles', {
    name: ['Bánh phở', 'Flat rice noodles'],
    syn: [
      ['phở', 'hủ tiếu', 'bánh canh'],
      ['pho noodles', 'rice sticks'],
    ],
    group: 'grain',
    priority: 35,
    prep: [
      mashed(
        'Trần mềm, cắt nhỏ 1–2 cm, trộn cùng thịt bò, gà băm.',
        'Blanch until soft, cut into 1–2 cm pieces and mix with minced beef or chicken.',
      ),
      finger(
        'Trần mềm, cắt dải ngắn cho bé bốc.',
        'Blanch until soft and cut short strips to grab.',
      ),
      family(
        'Phở cùng gia đình: nước dùng của bé không nêm, thịt chín kỹ, bánh phở cắt ngắn.',
        "Pho with the family: your child's broth unseasoned, the meat well cooked, the noodles cut short.",
      ),
    ],
  }),
  food('fd_glass_noodles', {
    name: ['Miến', 'Glass noodles'],
    syn: [
      ['miến dong', 'bún tàu', 'miến đậu xanh'],
      ['cellophane noodles', 'mung bean vermicelli'],
    ],
    group: 'grain',
    priority: 20,
    choking: [
      'Sợi miến trơn, dai: luôn cắt thật ngắn.',
      'Glass noodles are slippery and chewy: always cut them very short.',
    ],
    prep: [
      mashed(
        'Ngâm mềm, nấu chín, cắt thật ngắn trộn canh, cháo.',
        'Soak, cook and cut very short into soup or congee.',
      ),
      family(
        'Miến gà, miến lươn cùng gia đình; cắt ngắn, phần của bé không nêm.',
        "Chicken or eel glass-noodle soup with the family; cut short, your child's portion unseasoned.",
      ),
    ],
  }),
  food('fd_bread', {
    name: ['Bánh mì', 'Bread'],
    syn: [
      ['bánh mì gối', 'bánh mì sandwich', 'bánh mì nguyên cám'],
      ['toast', 'sandwich bread', 'wholemeal bread'],
    ],
    group: 'grain',
    allergen: 'wheat',
    priority: 45,
    choking: [
      'Ruột bánh mì mềm dễ vón cục trong miệng: nướng nhẹ, cắt que, không cho miếng to mềm dẻo. Chọn loại ít muối, không đường.',
      'Soft bread can form a doughy lump in the mouth: toast it lightly, cut fingers, avoid big soft pieces. Choose lower-salt bread with no added sugar.',
    ],
    prep: [
      finger(
        'Nướng nhẹ cho se mặt, cắt que dài; phết mỏng bơ quả nghiền, bơ đậu phộng mịn hoặc vừng xay.',
        'Toast lightly and cut into fingers; spread thinly with mashed avocado, smooth peanut butter or sesame paste.',
      ),
      pieces(
        'Nướng nhẹ, cắt miếng nhỏ cỡ đầu ngón tay.',
        'Toast lightly and cut into fingertip-sized pieces.',
      ),
      FAMILY_CUT,
    ],
  }),
  food('fd_pasta', {
    name: ['Nui', 'Pasta'],
    syn: [
      ['mì Ý', 'nui ống', 'nui xoắn', 'nui sò'],
      ['macaroni', 'spaghetti', 'fusilli'],
    ],
    group: 'grain',
    allergen: 'wheat',
    priority: 35,
    prep: [
      mashed(
        'Luộc thật mềm, băm nhỏ hoặc nghiền cùng sốt rau củ.',
        'Boil until very soft and chop or mash into a vegetable sauce.',
      ),
      finger(
        'Nui xoắn hoặc nui ống to luộc mềm để bé bốc.',
        'Fusilli or large tubes boiled soft for your baby to pick up.',
      ),
      pieces('Luộc mềm, cắt nhỏ.', 'Boil until soft and chop.'),
      FAMILY_CUT,
    ],
  }),
  food('fd_wheat_flour', {
    name: ['Bột mì', 'Wheat flour'],
    syn: [
      ['bột mỳ', 'bột mì đa dụng'],
      ['plain flour', 'all-purpose flour'],
    ],
    group: 'grain',
    allergen: 'wheat',
    priority: 20,
    prep: [
      finger(
        'Làm bánh kếp, bánh hấp mềm cùng trứng, chuối, rau củ; nấu chín kỹ.',
        'Use for soft pancakes or steamed cakes with egg, banana or vegetables; cook them through.',
      ),
      family(
        'Dùng làm sốt, áo bánh, bánh bao cùng gia đình.',
        'Use for sauces, coatings and steamed buns with the family.',
      ),
    ],
  }),
  food('fd_potato', {
    name: ['Khoai tây', 'Potato'],
    syn: [['củ khoai tây'], ['potatoes']],
    group: 'grain',
    priority: 60,
    prep: [
      smooth(
        'Gọt vỏ, hấp hoặc luộc mềm, nghiền mịn với chút sữa của bé; không xay lâu kẻo bị dẻo.',
        "Peel, steam or boil until soft and mash with a little of your baby's milk; don't over-blend or it turns gluey.",
      ),
      mashed('Nghiền thô, trộn cá, thịt hoặc rau.', 'Mash roughly with fish, meat or vegetables.'),
      finger(
        'Cắt que dày, hấp hoặc nướng mềm.',
        'Cut into thick wedges and steam or bake until soft.',
      ),
      pieces('Hấp mềm, cắt hạt lựu.', 'Steam until soft and dice.'),
      FAMILY_CUT,
    ],
  }),
  food('fd_sweet_potato', {
    name: ['Khoai lang', 'Sweet potato'],
    syn: [
      ['khoai lang mật', 'khoai lang tím', 'khoai lang Nhật'],
      ['purple sweet potato', 'kumara'],
    ],
    group: 'grain',
    priority: 85,
    prep: [
      smooth(
        'Gọt vỏ, hấp mềm, nghiền mịn; vị ngọt tự nhiên, dễ ăn cho bữa đầu.',
        'Peel, steam until soft and mash smooth; naturally sweet and easy for first meals.',
      ),
      mashed('Nghiền thô, trộn cháo hoặc thịt xay.', 'Mash roughly into congee or minced meat.'),
      finger(
        'Cắt que dài cỡ ngón tay, hấp hoặc nướng đến khi bóp nát được.',
        'Cut into finger-length sticks and steam or bake until they squash easily.',
      ),
      pieces('Hấp mềm, cắt hạt lựu.', 'Steam until soft and dice.'),
      FAMILY_CUT,
    ],
  }),
  food('fd_taro', {
    name: ['Khoai môn', 'Taro'],
    syn: [
      ['khoai sọ', 'môn sáp'],
      ['dasheen', 'eddoe'],
    ],
    group: 'grain',
    priority: 35,
    prep: [
      smooth(
        'Gọt vỏ (đeo găng nếu ngứa tay), luôn nấu chín kỹ rồi nghiền mịn.',
        'Peel (wear gloves if it itches) and always cook it through before mashing smooth.',
      ),
      mashed('Nấu chín kỹ trong cháo, nghiền thô.', 'Cook through in congee and mash roughly.'),
      pieces('Nấu chín kỹ, cắt hạt lựu mềm.', 'Cook through and dice soft.'),
      FAMILY_CUT,
    ],
  }),
  food('fd_purple_yam', {
    name: ['Khoai mỡ', 'Purple yam'],
    syn: [
      ['củ mỡ', 'khoai tía', 'củ cái'],
      ['ube', 'water yam'],
    ],
    group: 'grain',
    priority: 25,
    prep: [
      smooth(
        'Gọt vỏ, nấu chín kỹ, nghiền mịn; màu tím tự nhiên.',
        'Peel, cook through and mash smooth; naturally purple.',
      ),
      mashed(
        'Nạo nhỏ, nấu trong canh, cháo đến khi sánh mềm.',
        'Grate and cook in soup or congee until thick and soft.',
      ),
      FAMILY_CUT,
    ],
  }),
  food('fd_corn', {
    name: ['Ngô ngọt', 'Sweet corn'],
    syn: [
      ['bắp', 'ngô', 'bắp ngọt', 'bắp Mỹ'],
      ['corn', 'maize'],
    ],
    group: 'grain',
    priority: 30,
    choking: [
      'Hạt ngô nguyên có vỏ dai: với bé dưới 12 tháng, xay dập hoặc lọc bỏ vỏ; không cho bé bỏng ngô.',
      'Whole kernels have tough skins: for babies under 12 months, blend them or sieve out the skins; no popcorn.',
    ],
    prep: [
      smooth(
        'Luộc chín, tách hạt, xay mịn và lọc bỏ vỏ hạt.',
        'Boil, cut off the kernels, blend and sieve out the skins.',
      ),
      mashed(
        'Xay dập hạt ngô, nấu trong cháo, súp.',
        'Pulse the kernels and cook into congee or soup.',
      ),
      family(
        'Từ 12 tháng: hạt ngô mềm trong súp, cơm chiên; xay dập nếu bé còn hay oẹ.',
        'From 12 months: soft kernels in soup or fried rice; pulse them if your child still gags often.',
      ),
    ],
  }),
  food('fd_quinoa', {
    name: ['Hạt diêm mạch', 'Quinoa'],
    syn: [['quinoa', 'hạt quinoa'], []],
    group: 'grain',
    priority: 20,
    prep: [
      smooth(
        'Vo kỹ, nấu mềm với nhiều nước rồi xay mịn.',
        'Rinse well, cook soft in plenty of water and blend.',
      ),
      mashed(
        'Nấu mềm, trộn vào cháo hoặc rau nghiền.',
        'Cook soft and stir into congee or mashed vegetables.',
      ),
      FAMILY_CUT,
    ],
  }),
  food('fd_sticky_rice', {
    name: ['Gạo nếp', 'Glutinous rice'],
    syn: [
      ['nếp', 'xôi', 'nếp cái hoa vàng'],
      ['sticky rice', 'sweet rice'],
    ],
    group: 'grain',
    suggest: false,
    priority: 5,
    choking: [
      'Xôi dẻo dính, dễ vón và gây hóc: không cho bé miếng xôi; nếu dùng, chỉ nấu ít nếp lẫn trong cháo nhừ.',
      'Sticky rice clumps and can choke: no lumps of it; if used, cook a little into very soft congee.',
    ],
    prep: [
      mashed(
        'Nấu lẫn một ít nếp với gạo tẻ thành cháo thật nhừ.',
        'Cook a little with white rice into very soft congee.',
      ),
    ],
  }),
  food('fd_popcorn', {
    name: ['Bỏng ngô', 'Popcorn'],
    syn: [['bắp rang', 'bỏng'], []],
    group: 'grain',
    minAge: 36,
    suggest: false,
    priority: 0,
    choking: [
      'Bỏng ngô dễ bị hít vào đường thở: không cho trẻ dưới 4 tuổi (AAP).',
      'Popcorn is easily inhaled into the airway: not for children under 4 (AAP).',
    ],
    prep: [],
    sources: [S.hcChokingPrevention, S.cdcChokingHazards],
  }),
  // No sweetener group in 5e: honey sits with the starches and sugars ("bột đường").
  food('fd_honey', {
    name: ['Mật ong', 'Honey'],
    syn: [['mật ong rừng'], []],
    group: 'grain',
    minAge: 12,
    suggest: false,
    priority: 0,
    prep: [
      family(
        'Chỉ dùng từ 12 tháng, kể cả mật ong đã nấu chín; trước đó có thể gây ngộ độc botulinum. Hạn chế vì là đường.',
        'Only from 12 months, even cooked into food; before then it can cause infant botulism. Keep it small: it is a sugar.',
      ),
    ],
    sources: [S.cdcFoodsToAvoid],
  }),
];

const animalProteins: SolidsSeed<FoodContent>[] = [
  food('fd_chicken', {
    name: ['Thịt gà', 'Chicken'],
    syn: [
      ['đùi gà', 'ức gà', 'gà ta', 'gà xay'],
      ['chicken thigh', 'chicken breast', 'minced chicken'],
    ],
    group: 'animalProtein',
    iron: true,
    priority: 90,
    choking: [
      'Gỡ hết xương nhỏ, sụn và da dai trước khi cho bé.',
      'Remove all small bones, gristle and tough skin first.',
    ],
    prep: [
      smooth(
        'Bỏ da, xương, nấu chín kỹ rồi xay nhuyễn với cháo hoặc nước luộc; phần đùi nhiều sắt hơn ức.',
        'Skin and bone it, cook through and blend with congee or the cooking water; thigh has more iron than breast.',
      ),
      mashed(
        'Băm hoặc xay thô, nấu chín trong cháo.',
        'Mince or pulse coarsely and cook through in congee.',
      ),
      finger(
        'Đùi gà hầm mềm xé dải to cỡ ngón tay, hoặc viên gà hấp mềm.',
        'Slow-cooked thigh pulled into finger-sized strips, or soft steamed chicken balls.',
      ),
      pieces('Xé nhỏ hoặc thái hạt lựu thịt gà mềm.', 'Shred or dice tender chicken.'),
      FAMILY_CUT,
    ],
  }),
  food('fd_chicken_liver', {
    name: ['Gan gà', 'Chicken liver'],
    syn: [['gan'], ['liver']],
    group: 'animalProtein',
    iron: true,
    priority: 75,
    prep: [
      smooth(
        'Luộc hoặc hấp chín kỹ, không còn hồng, nghiền mịn trộn cháo. Gan giàu vitamin A: lượng nhỏ, khoảng 1 lần mỗi tuần.',
        'Boil or steam until cooked through with no pink, then mash into congee. Liver is rich in vitamin A: a little, about once a week.',
      ),
      mashed(
        'Băm nhỏ gan đã chín kỹ, trộn cháo cùng rau.',
        'Chop well-cooked liver finely into congee with vegetables.',
      ),
      pieces(
        'Thái miếng nhỏ gan chín, hoặc làm pa tê mềm không nêm phết bánh mì.',
        'Cut cooked liver small, or make a soft unseasoned pâté for toast.',
      ),
    ],
    sources: [S.nhsIron],
  }),
  food('fd_pork_liver', {
    name: ['Gan lợn', 'Pork liver'],
    syn: [['gan heo'], []],
    group: 'animalProtein',
    iron: true,
    priority: 60,
    prep: [
      smooth(
        'Bỏ gân, ngâm rửa sạch, luộc chín kỹ rồi nghiền mịn. Giàu vitamin A: lượng nhỏ, khoảng 1 lần mỗi tuần.',
        'Trim, soak and rinse, boil until cooked through and mash smooth. Rich in vitamin A: a little, about once a week.',
      ),
      mashed('Băm nhỏ gan đã chín kỹ, trộn cháo.', 'Chop well-cooked liver finely into congee.'),
      pieces('Thái miếng nhỏ gan chín kỹ.', 'Cut well-cooked liver into small pieces.'),
    ],
    sources: [S.nhsIron],
  }),
  food('fd_beef', {
    name: ['Thịt bò', 'Beef'],
    syn: [
      ['thăn bò', 'bắp bò', 'bò xay', 'thịt bò băm'],
      ['minced beef', 'ground beef', 'beef shin'],
    ],
    group: 'animalProtein',
    iron: true,
    priority: 95,
    choking: [
      'Thịt bò dễ dai: xay, băm nhuyễn hoặc hầm thật mềm; không cho miếng thịt dai phải nhai lâu.',
      'Beef can be tough: mince it or slow-cook it until very tender; no chewy chunks that need long chewing.',
    ],
    prep: [
      smooth(
        'Xay nhuyễn, nấu chín kỹ trong cháo hoặc nước rồi xay mịn lần nữa; không còn màu hồng.',
        'Mince finely, cook through in congee or water and blend again; no pink left.',
      ),
      mashed(
        'Băm nhỏ, đánh tơi khi nấu để không vón, trộn cháo lợn cợn.',
        'Mince and break it up while cooking so it does not clump; mix into lumpy congee.',
      ),
      finger(
        'Bò hầm thật mềm xé dải dài, hoặc thỏi bò xay hấp mềm cỡ ngón tay.',
        'Slow-cooked beef pulled into long strips, or soft steamed finger-sized logs of minced beef.',
      ),
      pieces(
        'Thịt bò hầm mềm thái nhỏ, hoặc bò băm xào mềm.',
        'Tender stewed beef chopped small, or soft-cooked mince.',
      ),
      FAMILY_CUT,
    ],
  }),
  food('fd_pork', {
    name: ['Thịt lợn nạc', 'Lean pork'],
    syn: [
      ['thịt heo', 'thịt nạc vai', 'thịt thăn', 'thịt băm'],
      ['pork loin', 'minced pork', 'pork shoulder'],
    ],
    group: 'animalProtein',
    iron: true,
    priority: 80,
    prep: [
      smooth(
        'Xay nhuyễn, nấu chín kỹ trong cháo, xay mịn lại.',
        'Mince finely, cook through in congee and blend again.',
      ),
      mashed(
        'Băm nhỏ, đánh tơi khi nấu, trộn cháo lợn cợn.',
        'Mince and break it up while cooking; mix into lumpy congee.',
      ),
      finger(
        'Viên thịt hấp mềm hoặc thịt nạc vai hầm mềm xé dải.',
        'Soft steamed meatballs, or slow-cooked shoulder pulled into strips.',
      ),
      pieces(
        'Thịt băm rim mềm không nêm, hoặc thịt luộc thái nhỏ.',
        'Unseasoned simmered mince, or boiled pork chopped small.',
      ),
      FAMILY_CUT,
    ],
  }),
  food('fd_duck', {
    name: ['Thịt vịt', 'Duck'],
    syn: [['vịt', 'ngan'], ['muscovy duck']],
    group: 'animalProtein',
    iron: true,
    priority: 35,
    choking: [
      'Bỏ da, mỡ và xương nhỏ; thịt vịt dai hơn gà nên băm nhỏ.',
      'Remove the skin, fat and small bones; duck is chewier than chicken, so mince it.',
    ],
    prep: [
      mashed(
        'Bỏ da, nấu chín kỹ, băm nhuyễn trộn cháo.',
        'Skin it, cook through and mince finely into congee.',
      ),
      pieces('Thịt vịt hầm mềm xé nhỏ.', 'Tender stewed duck shredded small.'),
      FAMILY_CUT,
    ],
  }),
  food('fd_frog', {
    name: ['Thịt ếch', 'Frog'],
    syn: [['ếch đồng', 'đùi ếch'], ['frog legs']],
    group: 'animalProtein',
    iron: true,
    priority: 30,
    choking: [
      'Ếch có nhiều xương nhỏ: lọc lấy thịt, miết kỹ bằng tay. Luôn nấu chín kỹ.',
      'Frog has many small bones: take the meat off and feel it carefully. Always cook it through.',
    ],
    prep: [
      smooth(
        'Lọc thịt, nấu chín kỹ trong cháo rồi xay mịn.',
        'Take the meat off the bone, cook it through in congee and blend.',
      ),
      mashed(
        'Băm nhỏ thịt đã lọc xương, nấu chín kỹ trong cháo.',
        'Mince the boned meat and cook it through in congee.',
      ),
      pieces('Thịt ếch chín mềm xé nhỏ.', 'Tender cooked frog meat shredded small.'),
    ],
  }),
  food('fd_egg', {
    name: ['Trứng gà', 'Egg'],
    syn: [
      ['trứng', 'lòng đỏ trứng', 'lòng trắng trứng'],
      ["hen's egg", 'egg yolk', 'egg white'],
    ],
    group: 'animalProtein',
    allergen: 'egg',
    iron: true,
    priority: 85,
    prep: [
      smooth(
        'Luộc chín kỹ cả lòng trắng và lòng đỏ, nghiền mịn với chút sữa của bé hoặc trộn cháo.',
        "Hard-boil until the white and yolk are both firm, then mash smooth with a little of your baby's milk or into congee.",
      ),
      finger(
        'Trứng luộc chín cắt múi cau, hoặc trứng tráng chín kỹ không nêm cắt dải.',
        'Hard-boiled egg cut into wedges, or a well-cooked unseasoned omelette cut into strips.',
      ),
      pieces(
        'Trứng chín kỹ cắt hạt lựu, hoặc trứng bác chín.',
        'Well-cooked egg diced, or fully set scrambled egg.',
      ),
      family(
        'Trứng hấp, trứng chiên chín kỹ cùng gia đình; chưa dùng trứng lòng đào, trứng sống.',
        'Steamed or fried egg, fully cooked, with the family; no runny or raw egg yet.',
      ),
    ],
    sources: [S.bsaciParents],
  }),
  food('fd_quail_egg', {
    name: ['Trứng cút', 'Quail eggs'],
    syn: [['trứng chim cút'], []],
    group: 'animalProtein',
    allergen: 'egg',
    iron: true,
    priority: 35,
    choking: [
      'Trứng cút luộc nguyên quả tròn, trơn, vừa khít đường thở: luôn cắt làm tư hoặc nghiền.',
      'A whole boiled quail egg is round, slippery and airway-sized: always quarter or mash it.',
    ],
    prep: [
      smooth(
        'Luộc chín kỹ, bóc vỏ, nghiền mịn trộn cháo.',
        'Hard-boil, peel and mash smooth into congee.',
      ),
      pieces(
        'Luộc chín kỹ, cắt làm tư hoặc nhỏ hơn.',
        'Hard-boil and cut into quarters or smaller.',
      ),
    ],
  }),
  food('fd_salmon', {
    name: ['Cá hồi', 'Salmon'],
    syn: [['phi lê cá hồi'], ['salmon fillet']],
    group: 'animalProtein',
    allergen: 'fish',
    iron: true,
    priority: 75,
    choking: FISH_BONES,
    prep: [
      smooth(
        'Hấp chín đến khi thịt đục, gỡ hết xương và da, nghiền mịn hoặc xay cùng cháo.',
        'Steam until opaque, remove all bones and skin, then mash or blend with congee.',
      ),
      finger(
        'Hấp chín, để miếng to dễ cầm sau khi đã kiểm tra xương bằng tay.',
        'Steam and leave large, easy-to-hold flakes after checking for bones by hand.',
      ),
      pieces(
        'Gỡ thành vụn nhỏ trộn cơm nát, mì hoặc khoai nghiền.',
        'Flake small into soft rice, noodles or mashed potato.',
      ),
      FAMILY_CUT,
    ],
  }),
  food('fd_basa', {
    name: ['Cá basa', 'Basa fish'],
    syn: [
      ['cá tra', 'cá ba sa', 'cá basa phi lê'],
      ['pangasius', 'catfish fillet'],
    ],
    group: 'animalProtein',
    allergen: 'fish',
    iron: true,
    priority: 65,
    choking: FISH_BONES,
    prep: [
      smooth(
        'Hấp hoặc luộc chín, bỏ phần mỡ bụng, nghiền mịn với cháo.',
        'Steam or poach, trim the belly fat and mash smooth with congee.',
      ),
      finger(
        'Hấp chín, để miếng to cỡ hai ngón tay.',
        'Steam and leave pieces about two fingers wide.',
      ),
      pieces('Gỡ vụn nhỏ trộn cháo đặc, cơm nát.', 'Flake small into thick congee or soft rice.'),
      FAMILY_CUT,
    ],
  }),
  food('fd_tilapia', {
    name: ['Cá rô phi', 'Tilapia'],
    syn: [['cá diêu hồng', 'cá điêu hồng'], ['red tilapia']],
    group: 'animalProtein',
    allergen: 'fish',
    iron: true,
    priority: 55,
    choking: FISH_BONES,
    prep: [
      smooth(
        'Hấp chín, gỡ kỹ xương, nghiền mịn với cháo.',
        'Steam, bone carefully and mash smooth with congee.',
      ),
      mashed('Gỡ vụn nhỏ, nấu trong cháo nhừ.', 'Flake small and cook into soft congee.'),
      pieces(
        'Gỡ miếng nhỏ trộn cơm nát hoặc bún.',
        'Flake into small pieces with soft rice or noodles.',
      ),
      FAMILY_CUT,
    ],
  }),
  food('fd_snakehead', {
    name: ['Cá lóc', 'Snakehead fish'],
    syn: [['cá quả', 'cá chuối', 'cá tràu'], ['murrel']],
    group: 'animalProtein',
    allergen: 'fish',
    iron: true,
    priority: 55,
    choking: FISH_BONES,
    prep: [
      smooth(
        'Hấp hoặc luộc chín với lát gừng, gỡ kỹ xương, nghiền mịn trộn cháo.',
        'Steam or poach with a slice of ginger, bone carefully and mash into congee.',
      ),
      mashed(
        'Gỡ vụn nhỏ, nấu trong cháo nhừ cùng rau.',
        'Flake small and cook into soft congee with greens.',
      ),
      pieces(
        'Gỡ miếng nhỏ trong cháo đặc hoặc canh chua phần của bé.',
        "Small flakes in thick congee or your child's portion of sour soup.",
      ),
      FAMILY_CUT,
    ],
  }),
  food('fd_cod', {
    name: ['Cá tuyết', 'Cod'],
    syn: [['cá tuyết phi lê'], ['codfish', 'cod fillet']],
    group: 'animalProtein',
    allergen: 'fish',
    iron: true,
    priority: 45,
    choking: FISH_BONES,
    prep: [
      smooth(
        'Hấp chín, gỡ xương, nghiền mịn với khoai tây hoặc cháo.',
        'Steam, bone and mash smooth with potato or congee.',
      ),
      finger('Hấp chín, để miếng to dễ cầm.', 'Steam and leave large flakes to hold.'),
      pieces('Gỡ vụn nhỏ.', 'Flake small.'),
    ],
  }),
  food('fd_carp', {
    name: ['Cá chép', 'Carp'],
    syn: [['cá chép ta'], ['common carp']],
    group: 'animalProtein',
    allergen: 'fish',
    iron: true,
    priority: 25,
    choking: [
      'Cá chép nhiều xương dăm nhỏ: chỉ dùng thịt lọc thật kỹ, nghiền rồi kiểm tra lại bằng tay.',
      'Carp has many fine bones: use only carefully filleted flesh, mash it and check again by hand.',
    ],
    prep: [
      smooth(
        'Hấp chín, lọc kỹ xương dăm, nghiền mịn nấu cháo.',
        'Steam, remove every fine bone and mash into congee.',
      ),
      mashed(
        'Thịt cá đã lọc xương băm nhỏ, nấu cháo.',
        'Mince the boned flesh and cook it into congee.',
      ),
    ],
  }),
  food('fd_eel', {
    name: ['Lươn', 'Eel'],
    syn: [
      ['lươn đồng', 'thịt lươn'],
      ['swamp eel', 'rice-field eel'],
    ],
    group: 'animalProtein',
    allergen: 'fish',
    iron: true,
    priority: 30,
    choking: [
      'Lươn có xương sống và xương nhỏ: chỉ dùng thịt đã lọc sạch xương, nấu chín kỹ.',
      'Eel has a spine and fine bones: use only fully boned meat, cooked through.',
    ],
    prep: [
      mashed(
        'Thịt lươn đã lọc xương, luộc chín, xé nhỏ nấu cháo.',
        'Boned eel, poached and shredded into congee.',
      ),
      pieces(
        'Xé sợi nhỏ trong cháo đặc hoặc miến.',
        'Shred finely into thick congee or glass noodles.',
      ),
      FAMILY_CUT,
    ],
  }),
  food('fd_shrimp', {
    name: ['Tôm', 'Shrimp'],
    syn: [['tôm sú', 'tôm thẻ', 'tôm đồng', 'tép'], ['prawns']],
    group: 'animalProtein',
    allergen: 'shellfish',
    priority: 50,
    choking: [
      'Tôm nguyên con dai, trơn: bóc vỏ, bỏ chỉ đen, băm nhỏ hoặc cắt nhỏ theo tuổi.',
      'Whole shrimp are chewy and slippery: peel, devein and mince or chop them for the age.',
    ],
    prep: [
      smooth(
        'Bóc vỏ, bỏ chỉ, nấu chín kỹ rồi xay mịn với cháo.',
        'Peel, devein, cook through and blend with congee.',
      ),
      mashed(
        'Băm nhỏ, nấu chín đỏ đều trong cháo.',
        'Mince and cook in congee until pink all through.',
      ),
      finger(
        'Từ khoảng 9 tháng: chả tôm hấp mềm cắt que.',
        'From about 9 months: soft steamed shrimp cakes cut into fingers.',
      ),
      pieces('Tôm chín cắt nhỏ cỡ hạt đậu.', 'Cooked shrimp cut into pea-sized pieces.'),
      FAMILY_CUT,
    ],
  }),
  food('fd_crab', {
    name: ['Cua', 'Crab'],
    syn: [
      ['cua đồng', 'cua biển', 'ghẹ', 'riêu cua'],
      ['rice-field crab', 'mud crab', 'blue swimmer crab'],
    ],
    group: 'animalProtein',
    allergen: 'shellfish',
    priority: 40,
    choking: [
      'Lọc kỹ mảnh vỏ cứng: cua đồng giã nhuyễn, lọc lấy nước nhiều lần; cua biển chỉ dùng thịt đã kiểm tra.',
      'Remove every bit of shell: pound rice-field crab and strain it several times; for sea crab use only checked meat.',
    ],
    prep: [
      mashed(
        'Riêu cua đồng nấu chín kỹ trộn cháo, hoặc thịt cua biển băm nhỏ.',
        'Well-cooked rice-field crab curds stirred into congee, or minced sea-crab meat.',
      ),
      pieces(
        'Thịt cua chín xé nhỏ trong cháo, canh.',
        'Cooked crab meat shredded into congee or soup.',
      ),
      FAMILY_CUT,
    ],
  }),
  food('fd_clam', {
    name: ['Ngao', 'Clams'],
    syn: [
      ['nghêu', 'hến', 'ngao trắng'],
      ['baby clams', 'basket clams'],
    ],
    group: 'animalProtein',
    allergen: 'shellfish',
    iron: true,
    priority: 35,
    choking: [
      'Thịt ngao dai: chỉ dùng con còn sống, nấu đến khi vỏ mở, bỏ vỏ và băm nhỏ.',
      'Clam meat is chewy: use only live clams, cook until the shells open, then shell and mince.',
    ],
    prep: [
      mashed(
        'Luộc chín, tách thịt, rửa sạch cát, băm nhỏ nấu cháo.',
        'Boil, take out the meat, rinse off any grit and mince it into congee.',
      ),
      pieces(
        'Thịt ngao chín băm nhỏ trong cháo đặc, canh.',
        'Minced cooked clam in thick congee or soup.',
      ),
      FAMILY_CUT,
    ],
  }),
  food('fd_oyster', {
    name: ['Hàu', 'Oysters'],
    syn: [['hàu sữa'], []],
    group: 'animalProtein',
    allergen: 'shellfish',
    iron: true,
    priority: 20,
    choking: [
      'Chỉ dùng hàu nấu chín kỹ, băm nhỏ; không bao giờ cho bé ăn hàu sống hay tái.',
      'Use only thoroughly cooked oysters, minced; never raw or lightly cooked.',
    ],
    prep: [
      mashed(
        'Rửa sạch, nấu chín kỹ, băm nhỏ trộn cháo.',
        'Clean, cook thoroughly and mince into congee.',
      ),
      pieces(
        'Hàu chín kỹ cắt nhỏ trong cháo đặc.',
        'Thoroughly cooked oyster chopped into thick congee.',
      ),
    ],
  }),
  food('fd_squid', {
    name: ['Mực', 'Squid'],
    syn: [['mực ống', 'mực lá'], ['calamari']],
    group: 'animalProtein',
    allergen: 'shellfish',
    priority: 10,
    choking: [
      'Mực dai, khó nhai, dễ hóc: xay nhuyễn làm chả hấp; không cho khoanh mực.',
      'Squid is rubbery and a choking risk: blend it into steamed cakes; no squid rings.',
    ],
    prep: [
      mashed('Xay nhuyễn, nấu chín kỹ trong cháo.', 'Blend and cook through in congee.'),
      finger(
        'Chả mực tự làm, hấp mềm không nêm, cắt que.',
        'Homemade unseasoned squid cake, steamed soft and cut into fingers.',
      ),
    ],
  }),
  food('fd_sausage', {
    name: ['Xúc xích', 'Sausage'],
    syn: [
      ['xúc xích tiệt trùng', 'lạp xưởng', 'thịt nguội'],
      ['hot dog', 'frankfurter', 'ham'],
    ],
    group: 'animalProtein',
    minAge: 12,
    suggest: false,
    priority: 0,
    choking: [
      'Khoanh xúc xích tròn vừa khít đường thở của trẻ: nếu cho, cắt dọc làm tư rồi thái nhỏ. Nhiều muối, chỉ thỉnh thoảng.',
      "Round slices can block a child's airway: if given, cut it lengthwise into quarters, then chop. Salty, so only now and then.",
    ],
    prep: [
      family(
        'Hạn chế vì nhiều muối; nếu cho, cắt dọc làm tư rồi thái nhỏ.',
        'Limit it because it is salty; if given, quarter it lengthwise and chop small.',
      ),
    ],
    sources: [S.cdcChokingHazards],
  }),
  food('fd_gio_lua', {
    name: ['Giò lụa', 'Vietnamese pork roll'],
    syn: [
      ['chả lụa', 'giò', 'chả'],
      ['cha lua', 'pork sausage roll'],
    ],
    group: 'animalProtein',
    minAge: 12,
    suggest: false,
    priority: 0,
    choking: [
      'Dai và mặn: thái mỏng rồi cắt nhỏ, chỉ thỉnh thoảng cho trẻ trên 1 tuổi.',
      'Chewy and salty: slice thinly and chop, and only now and then after age 1.',
    ],
    prep: [
      family(
        'Hạn chế vì đã nêm sẵn khá mặn; thái mỏng, cắt nhỏ.',
        'Limit it: it is already quite salty; slice thinly and chop small.',
      ),
    ],
  }),
];

const legumesNuts: SolidsSeed<FoodContent>[] = [
  food('fd_mung_bean', {
    name: ['Đậu xanh', 'Mung beans'],
    syn: [
      ['đỗ xanh', 'đậu xanh cà vỏ', 'đậu xanh nguyên hạt'],
      ['split mung beans', 'green gram'],
    ],
    group: 'legumeNut',
    iron: true,
    priority: 65,
    prep: [
      smooth(
        'Dùng đậu cà vỏ, ngâm 2–3 giờ, nấu nhừ rồi xay mịn hoặc nấu cùng cháo.',
        'Use split, hulled beans, soak 2–3 hours, cook until very soft and blend, or cook into congee.',
      ),
      mashed(
        'Nấu nhừ, nghiền thô trộn cháo.',
        'Cook until very soft and mash roughly into congee.',
      ),
      finger(
        'Đậu nấu nhừ trộn khoai, nặn thỏi dài, hấp mềm.',
        'Mix very soft beans with potato, shape into logs and steam.',
      ),
      FAMILY_CUT,
    ],
  }),
  food('fd_red_bean', {
    name: ['Đậu đỏ', 'Adzuki beans'],
    syn: [
      ['đỗ đỏ', 'đậu đỏ hạt nhỏ'],
      ['red beans', 'azuki'],
    ],
    group: 'legumeNut',
    iron: true,
    priority: 45,
    choking: WHOLE_BEANS,
    prep: [
      smooth(
        'Ngâm qua đêm, nấu thật nhừ, xay mịn và lọc bớt vỏ.',
        'Soak overnight, cook until very soft, blend and sieve out some of the skins.',
      ),
      mashed(
        'Nấu nhừ, nghiền thô trộn cháo.',
        'Cook until very soft and mash roughly into congee.',
      ),
      pieces('Đậu nấu nhừ bóp dẹt từng hạt.', 'Very soft beans squashed flat one by one.'),
    ],
  }),
  food('fd_black_bean', {
    name: ['Đậu đen', 'Black beans'],
    syn: [['đỗ đen', 'đậu đen xanh lòng'], ['black turtle beans']],
    group: 'legumeNut',
    iron: true,
    priority: 40,
    choking: WHOLE_BEANS,
    prep: [
      smooth(
        'Ngâm qua đêm, nấu thật nhừ, xay mịn với cháo.',
        'Soak overnight, cook until very soft and blend with congee.',
      ),
      mashed('Nấu nhừ, nghiền thô.', 'Cook until very soft and mash roughly.'),
      pieces('Đậu nấu nhừ bóp dẹt từng hạt.', 'Very soft beans squashed flat one by one.'),
    ],
  }),
  food('fd_lentil', {
    name: ['Đậu lăng', 'Lentils'],
    syn: [
      ['đậu lăng đỏ', 'đậu lăng nâu'],
      ['red lentils', 'brown lentils'],
    ],
    group: 'legumeNut',
    iron: true,
    priority: 45,
    prep: [
      smooth(
        'Vo sạch, nấu 15–20 phút đến khi nhừ, xay mịn; không cần ngâm.',
        'Rinse, simmer for 15–20 minutes until very soft and blend; no soaking needed.',
      ),
      mashed(
        'Nấu nhừ, nghiền thô với rau củ.',
        'Cook until very soft and mash roughly with vegetables.',
      ),
      family(
        'Súp đậu lăng, cà ri đậu lăng cùng gia đình; phần của bé không nêm.',
        "Lentil soup or dal with the family; your child's portion unseasoned.",
      ),
    ],
  }),
  food('fd_chickpea', {
    name: ['Đậu gà', 'Chickpeas'],
    syn: [['đậu chickpea'], ['garbanzo beans', 'hummus']],
    group: 'legumeNut',
    iron: true,
    priority: 25,
    choking: [
      'Hạt đậu gà nguyên tròn, chắc: nghiền hoặc làm hummus mịn; bóp dẹt từng hạt nếu cho bé cầm.',
      'Whole chickpeas are round and firm: mash them or make smooth hummus; squash each one flat for finger food.',
    ],
    prep: [
      smooth(
        'Ngâm qua đêm, nấu nhừ, xay mịn với chút dầu ô liu và nước (hummus không muối).',
        'Soak overnight, cook until very soft and blend with a little olive oil and water (unsalted hummus).',
      ),
      pieces('Đậu nấu nhừ bóp dẹt từng hạt.', 'Very soft chickpeas squashed flat.'),
    ],
  }),
  food('fd_peas', {
    name: ['Đậu Hà Lan', 'Green peas'],
    syn: [['đậu hà lan hạt', 'đậu Hòa Lan'], ['garden peas']],
    group: 'legumeNut',
    priority: 40,
    choking: [
      'Hạt nhỏ, tròn: nghiền hoặc bóp dẹt cho bé dưới 12 tháng.',
      'Small and round: mash or squash them flat for babies under 12 months.',
    ],
    prep: [
      smooth(
        'Luộc mềm, xay mịn và lọc bớt vỏ.',
        'Boil until soft, blend and sieve out some skins.',
      ),
      mashed('Luộc mềm, nghiền dập.', 'Boil until soft and crush.'),
      pieces('Luộc mềm, bóp dẹt từng hạt.', 'Boil until soft and squash each pea flat.'),
      FAMILY_CUT,
    ],
  }),
  food('fd_tofu', {
    name: ['Đậu phụ', 'Tofu'],
    syn: [
      ['đậu hũ', 'tàu hũ', 'đậu khuôn'],
      ['bean curd', 'firm tofu'],
    ],
    group: 'legumeNut',
    allergen: 'soy',
    iron: true,
    priority: 65,
    prep: [
      smooth(
        'Hấp hoặc luộc qua, nghiền mịn trộn cháo hoặc rau nghiền.',
        'Steam or blanch, then mash smooth into congee or mashed vegetables.',
      ),
      finger(
        'Hấp hoặc áp chảo ít dầu, cắt que dài cỡ ngón tay.',
        'Steam or pan-fry in a little oil and cut into finger-length sticks.',
      ),
      pieces('Cắt hạt lựu mềm.', 'Cut into soft dice.'),
      family(
        'Đậu sốt cà chua, đậu nhồi thịt cùng gia đình; phần của bé không nêm.',
        "Tofu in tomato sauce or stuffed tofu with the family; your child's portion unseasoned.",
      ),
    ],
  }),
  food('fd_silken_tofu', {
    name: ['Đậu phụ non', 'Silken tofu'],
    syn: [['đậu hũ non', 'tàu hũ non'], ['soft tofu']],
    group: 'legumeNut',
    allergen: 'soy',
    priority: 45,
    prep: [
      smooth(
        'Hấp qua cho nóng đều rồi để nguội, nghiền mịn; không dùng tàu hũ nước đường.',
        'Steam until hot through, cool and mash smooth; not the sweet tofu pudding.',
      ),
      mashed('Trộn với rau củ nghiền hoặc cháo.', 'Mix with mashed vegetables or congee.'),
    ],
  }),
  food('fd_edamame', {
    name: ['Đậu nành non', 'Edamame'],
    syn: [['đậu nành Nhật', 'đậu nành tươi'], ['green soybeans']],
    group: 'legumeNut',
    allergen: 'soy',
    iron: true,
    priority: 20,
    choking: [
      'Hạt đậu nành non tròn, chắc: bóc vỏ, luộc mềm rồi nghiền hoặc bóp dẹt; không cho cả hạt.',
      'Edamame beans are round and firm: shell, boil soft and mash or squash them flat; never whole.',
    ],
    prep: [
      smooth(
        'Bóc vỏ, luộc mềm, xay mịn với chút nước.',
        'Shell, boil soft and blend with a little water.',
      ),
      pieces('Luộc mềm, bóp dẹt từng hạt.', 'Boil soft and squash each bean flat.'),
    ],
  }),
  food('fd_soy_milk', {
    name: ['Sữa đậu nành (uống)', 'Soy milk (as a drink)'],
    syn: [['sữa đậu nành'], ['soya milk']],
    group: 'legumeNut',
    allergen: 'soy',
    minAge: 12,
    suggest: false,
    priority: 5,
    prep: [
      family(
        'Từ 12 tháng: chọn loại không đường, có bổ sung canxi; sữa đậu nành tự làm chưa thay được sữa.',
        'From 12 months: choose unsweetened, calcium-fortified soy milk; homemade soy milk does not replace milk.',
      ),
    ],
    sources: [S.nhsDrinksCups],
  }),
  food('fd_peanut_butter', {
    name: ['Bơ đậu phộng mịn', 'Smooth peanut butter'],
    syn: [
      ['bơ lạc', 'đậu phộng', 'lạc', 'đậu phộng xay mịn'],
      ['peanut', 'peanut paste', 'ground peanuts'],
    ],
    group: 'legumeNut',
    allergen: 'peanut',
    priority: 60,
    choking: [
      'Không cho đậu phộng nguyên hạt hoặc giã thô (đến 5 tuổi). Bơ đậu phộng đặc dễ dính vòm họng: pha loãng, không phết lớp dày.',
      'No whole or roughly crushed peanuts (until age 5). Thick peanut butter can stick to the palate: thin it and never spread it thickly.',
    ],
    prep: [
      smooth(
        'Pha loãng với nước ấm hoặc sữa của bé, trộn vào cháo, khoai nghiền. Chọn loại 100% đậu phộng, không muối, không đường.',
        "Thin with warm water or your baby's milk and stir into congee or mashed potato. Choose 100% peanut, no salt or sugar.",
      ),
      finger(
        'Phết thật mỏng lên que bánh mì nướng hoặc que chuối.',
        'Spread very thinly on toast fingers or banana sticks.',
      ),
    ],
    sources: [S.bsaciParents],
  }),
  food('fd_sesame_paste', {
    name: ['Vừng xay mịn', 'Sesame paste'],
    syn: [
      ['mè xay mịn', 'bơ vừng', 'tahini', 'vừng', 'mè'],
      ['tahini', 'ground sesame', 'sesame seeds'],
    ],
    group: 'legumeNut',
    allergen: 'sesame',
    priority: 45,
    prep: [
      smooth(
        'Rang vừng rồi xay thật mịn, hoặc dùng tahini; trộn ít vào cháo, khoai nghiền, sữa chua.',
        'Toast and grind sesame very fine, or use tahini; stir a little into congee, mashed potato or yogurt.',
      ),
      finger(
        'Phết mỏng lên bánh mì nướng que, hoặc lăn que bơ, chuối qua vừng xay.',
        'Spread thinly on toast fingers, or roll avocado or banana sticks in ground sesame.',
      ),
      family(
        'Rắc vừng rang lên cơm, rau của cả nhà.',
        "Sprinkle toasted sesame over the family's rice and vegetables.",
      ),
    ],
  }),
  food('fd_cashew_butter', {
    name: ['Bơ hạt điều mịn', 'Cashew butter'],
    syn: [
      ['hạt điều xay mịn', 'hạt điều'],
      ['cashew paste', 'ground cashews', 'cashew'],
    ],
    group: 'legumeNut',
    allergen: 'treeNut',
    priority: 30,
    choking: TREE_NUT,
    prep: [
      smooth(
        'Pha loãng với nước ấm hoặc sữa của bé, trộn vào cháo, yến mạch. Chọn loại không muối, không đường.',
        "Thin with warm water or your baby's milk and stir into congee or oats. Choose one without salt or sugar.",
      ),
      finger('Phết thật mỏng lên bánh mì nướng que.', 'Spread very thinly on toast fingers.'),
    ],
  }),
  food('fd_almond_butter', {
    name: ['Bơ hạnh nhân mịn', 'Almond butter'],
    syn: [
      ['hạnh nhân xay mịn', 'bột hạnh nhân', 'hạnh nhân'],
      ['ground almonds', 'almond meal', 'almond'],
    ],
    group: 'legumeNut',
    allergen: 'treeNut',
    priority: 25,
    choking: TREE_NUT,
    prep: [
      smooth(
        'Pha loãng, trộn vào cháo, yến mạch hoặc sữa chua; bột hạnh nhân xay mịn trộn vào bánh.',
        'Thin it and stir into congee, oats or yogurt; finely ground almond can go into bakes.',
      ),
      finger('Phết thật mỏng lên bánh mì nướng que.', 'Spread very thinly on toast fingers.'),
    ],
  }),
  food('fd_walnut_paste', {
    name: ['Óc chó xay nhuyễn', 'Walnut paste'],
    syn: [
      ['bơ óc chó', 'hạt óc chó', 'óc chó'],
      ['ground walnuts', 'walnut butter', 'walnut'],
    ],
    group: 'legumeNut',
    allergen: 'treeNut',
    priority: 20,
    choking: TREE_NUT,
    prep: [
      smooth(
        'Xay óc chó thật nhuyễn thành bột mịn hoặc bơ, trộn ít vào cháo, yến mạch.',
        'Grind walnuts to a fine powder or butter and stir a little into congee or oats.',
      ),
    ],
  }),
];

const dairy: SolidsSeed<FoodContent>[] = [
  food('fd_yogurt', {
    name: ['Sữa chua nguyên kem', 'Full-fat yogurt'],
    syn: [
      ['sữa chua không đường', 'da ua', 'sữa chua Hy Lạp'],
      ['plain yogurt', 'yoghurt', 'Greek yogurt'],
    ],
    group: 'dairy',
    allergen: 'milk',
    priority: 60,
    prep: [
      smooth(
        'Chọn loại nguyên kem, không đường, đã thanh trùng; ăn thẳng hoặc trộn trái cây nghiền.',
        'Choose full-fat, unsweetened, pasteurized yogurt; serve it plain or with mashed fruit.',
      ),
      mashed('Trộn trái cây nghiền thô hoặc yến mạch.', 'Mix with roughly mashed fruit or oats.'),
      family(
        'Bữa phụ cùng gia đình; tránh sữa chua có đường, sữa chua uống, váng sữa.',
        'A snack with the family; avoid sweetened yogurt, yogurt drinks and dairy desserts.',
      ),
    ],
  }),
  food('fd_cheese', {
    name: ['Phô mai', 'Cheese'],
    syn: [
      ['pho mát', 'phô mai miếng', 'phô mai bào'],
      ['mozzarella', 'cheddar', 'grated cheese'],
    ],
    group: 'dairy',
    allergen: 'milk',
    priority: 40,
    choking: [
      'Khối phô mai cứng cắt hạt lựu dễ hóc: bào sợi hoặc cắt que mỏng. Chọn loại thanh trùng; tránh phô mai mềm có mốc.',
      'Cubes of firm cheese can choke: grate it or cut thin sticks. Choose pasteurized cheese; avoid mould-ripened soft cheese.',
    ],
    prep: [
      smooth(
        'Bào sợi mịn, cho vào cháo, khoai nghiền khi còn nóng cho tan chảy.',
        'Grate finely and stir into hot congee or mashed potato to melt.',
      ),
      finger(
        'Cắt que mỏng hoặc bào sợi; chọn loại ít muối như mozzarella.',
        'Cut thin sticks or grate; choose a lower-salt cheese like mozzarella.',
      ),
      family(
        'Phô mai bào lên nui, trứng, rau cùng gia đình.',
        'Grated over pasta, eggs or vegetables with the family.',
      ),
    ],
  }),
  food('fd_cow_milk_cooking', {
    name: ['Sữa bò (nấu ăn)', "Cow's milk (in cooking)"],
    syn: [['sữa tươi nấu ăn', 'sữa bò tươi'], ['whole milk in cooking']],
    group: 'dairy',
    allergen: 'milk',
    priority: 35,
    prep: [
      smooth(
        'Sữa tươi nguyên kem, không đường, thanh trùng, dùng để nấu cháo, bột, súp hay nghiền khoai.',
        'Full-fat, unsweetened, pasteurized milk for cooking congee, cereal, soups or mashed potato.',
      ),
      family(
        'Trước 12 tháng chỉ dùng trong món ăn, chưa dùng làm đồ uống thay sữa mẹ, sữa công thức.',
        'Before 12 months use it only in food, not as a drink instead of breast milk or formula.',
      ),
    ],
    sources: [S.nhsDrinksCups],
  }),
  food('fd_cow_milk_drink', {
    name: ['Sữa tươi (uống)', "Cow's milk (as a drink)"],
    syn: [
      ['sữa bò', 'sữa tươi nguyên kem', 'sữa hộp'],
      ['whole milk', 'full-fat milk'],
    ],
    group: 'dairy',
    allergen: 'milk',
    minAge: 12,
    suggest: false,
    priority: 5,
    prep: [
      family(
        'Từ 12 tháng: sữa tươi nguyên kem, không đường, uống bằng cốc; khoảng 480 ml mỗi ngày là đủ (AAP).',
        'From 12 months: full-fat, unsweetened milk from a cup; about 480 ml a day is enough (AAP).',
      ),
    ],
    sources: [S.hcRecommendedDrinks, S.nhsDrinksCups],
  }),
  food('fd_ricotta', {
    name: ['Phô mai tươi', 'Fresh cheese'],
    syn: [
      ['ricotta', 'phô mai cottage', 'phô mai kem'],
      ['ricotta', 'cottage cheese', 'cream cheese'],
    ],
    group: 'dairy',
    allergen: 'milk',
    priority: 30,
    prep: [
      smooth(
        'Chọn loại đã thanh trùng, ít muối; trộn vào rau củ nghiền hoặc trái cây.',
        'Choose a pasteurized, lower-salt fresh cheese; mix it into mashed vegetables or fruit.',
      ),
      finger('Phết lên bánh mì nướng que.', 'Spread on toast fingers.'),
    ],
  }),
];

const fats: SolidsSeed<FoodContent>[] = [
  food('fd_vegetable_oil', {
    name: ['Dầu ăn thực vật', 'Vegetable oil'],
    syn: [
      ['dầu ăn', 'dầu đậu nành', 'dầu hạt cải', 'dầu hướng dương'],
      ['cooking oil', 'canola oil', 'sunflower oil'],
    ],
    group: 'fat',
    priority: 45,
    prep: [
      smooth(
        'Thêm khoảng 1 thìa cà phê dầu vào bát cháo, bột đã nấu chín để tăng năng lượng.',
        'Stir about 1 teaspoon of oil into a cooked bowl of congee or cereal for energy.',
      ),
      family(
        'Dùng ít dầu khi xào, áp chảo; ưu tiên luộc, hấp, nấu canh.',
        'Use a little oil for stir-frying or pan-frying; favour boiling, steaming and soups.',
      ),
    ],
    sources: [S.unicef6to12],
  }),
  food('fd_olive_oil', {
    name: ['Dầu ô liu', 'Olive oil'],
    syn: [['dầu oliu', 'dầu ô-liu'], ['extra virgin olive oil']],
    group: 'fat',
    priority: 35,
    prep: [
      smooth(
        'Trộn ít dầu vào rau củ nghiền, cháo hoặc cá nghiền đã nấu chín.',
        'Stir a little into cooked mashed vegetables, congee or fish.',
      ),
      finger(
        'Quét mỏng lên que rau củ hấp hoặc nướng.',
        'Brush thinly over steamed or roasted vegetable sticks.',
      ),
    ],
  }),
  food('fd_gac_oil', {
    name: ['Dầu gấc', 'Gac oil'],
    syn: [['dầu gấc nguyên chất'], ['gac fruit oil']],
    group: 'fat',
    priority: 30,
    prep: [
      smooth(
        'Trộn vài giọt đến nửa thìa cà phê vào bát cháo đã nấu chín; giàu tiền vitamin A, không cần dùng mỗi bữa.',
        'Stir a few drops to half a teaspoon into cooked congee; rich in provitamin A, no need for every meal.',
      ),
    ],
  }),
  food('fd_lard', {
    name: ['Mỡ lợn', 'Lard'],
    syn: [['mỡ heo', 'mỡ nước'], ['pork fat']],
    group: 'fat',
    priority: 20,
    prep: [
      smooth(
        'Thắng mỡ sạch, cho ít vào cháo đã nấu; xen kẽ với dầu thực vật.',
        'Render clean pork fat and stir a little into cooked congee; alternate with vegetable oil.',
      ),
    ],
  }),
  food('fd_butter', {
    name: ['Bơ lạt', 'Unsalted butter'],
    syn: [['bơ động vật', 'bơ nhạt', 'bơ không muối'], ['butter']],
    group: 'fat',
    allergen: 'milk',
    priority: 25,
    prep: [
      smooth(
        'Cho ít bơ lạt vào khoai, rau củ nghiền hoặc cháo khi còn ấm.',
        'Stir a little unsalted butter into warm mashed potato, vegetables or congee.',
      ),
      family(
        'Dùng ít khi nấu nui, súp, bánh cho cả nhà.',
        'Use a little in pasta, soups and bakes for the family.',
      ),
    ],
  }),
  food('fd_sesame_oil', {
    name: ['Dầu vừng', 'Sesame oil'],
    syn: [['dầu mè', 'dầu mè đen'], ['toasted sesame oil']],
    group: 'fat',
    allergen: 'sesame',
    priority: 15,
    prep: [
      smooth(
        'Vài giọt cho thơm cháo, súp đã nấu chín; có protein vừng nên dùng khi bé đã ăn vừng ổn.',
        'A few drops to flavour cooked congee or soup; it contains sesame protein, so use it once sesame suits your baby.',
      ),
      family(
        'Vài giọt trong món xào, trộn của cả nhà.',
        'A few drops in family stir-fries and dressings.',
      ),
    ],
  }),
  food('fd_coconut_milk', {
    name: ['Nước cốt dừa', 'Coconut milk'],
    syn: [['cốt dừa', 'nước dừa nạo'], ['coconut cream']],
    group: 'fat',
    priority: 15,
    prep: [
      smooth(
        'Dùng ít nước cốt dừa tự vắt hoặc loại không đường để nấu cháo, súp khoai; nhiều chất béo bão hoà nên chỉ dùng ít.',
        'Use a little fresh or unsweetened coconut milk in congee or sweet potato soup; it is high in saturated fat, so keep it small.',
      ),
      family(
        'Cà ri không cay, canh khoai nấu cốt dừa cùng gia đình; phần của bé không nêm.',
        "Mild curry or coconut tuber soup with the family; your child's portion unseasoned.",
      ),
    ],
  }),
];

export const seedFoods: readonly SolidsSeed<FoodContent>[] = [
  ...vegetables,
  ...fruits,
  ...grains,
  ...animalProteins,
  ...legumesNuts,
  ...dairy,
  ...fats,
];

// ---------- Recipes ----------

type Ingredient = RecipeContent['ingredients'][number];

/** One ingredient; `foodId` null only for water and aromatics that are removed. */
const ing = (
  foodId: string | null,
  name: Pair,
  qty: number | null,
  unit: IngredientUnit | null,
  note?: Pair,
): Ingredient => ({ foodId, name: t(...name), qty, unit, note: note ? t(...note) : none });
const water = (ml: number): Ingredient => ing(null, ['Nước', 'Water'], ml, 'ml');
const oil = (qty: number, unit: IngredientUnit, note?: Pair): Ingredient =>
  ing('fd_vegetable_oil', ['Dầu ăn', 'Cooking oil'], qty, unit, note);

/** vi and en steps written side by side, so the two lists always have the same length. */
const steps = (...pairs: Pair[]) => ({ vi: pairs.map((p) => p[0]), en: pairs.map((p) => p[1]) });

const STORE_RICE = t(
  'Làm nguội nhanh, cất tủ lạnh trong vòng 1 giờ, dùng trong 24 giờ hoặc chia phần trữ đông, rã đông trong ngăn mát. Hâm một lần cho nóng sôi đều, để còn ấm rồi cho bé ăn. Bỏ phần bé ăn dở.',
  "Cool quickly and refrigerate within 1 hour; use within 24 hours, or freeze in portions and thaw in the fridge. Reheat once until piping hot all through and serve warm. Throw away your baby's leftovers.",
);
const STORE_COOKED = t(
  'Làm nguội, cất tủ lạnh trong vòng 1–2 giờ, dùng trong 2 ngày hoặc chia phần trữ đông, rã đông trong ngăn mát. Hâm một lần cho nóng đều, để còn ấm rồi cho bé ăn. Bỏ phần bé ăn dở.',
  "Cool and refrigerate within 1–2 hours; use within 2 days, or freeze in portions and thaw in the fridge. Reheat once until hot all through and serve warm. Throw away your baby's leftovers.",
);

/** Allergen introduction, said once and the same way in every recipe that needs it. */
const firstTime = (vi: string, en: string): Pair => [
  `Lần đầu ăn ${vi}: cho một lượng nhỏ vào buổi sáng, ở nhà, khi bé khoẻ; theo dõi nổi mẩn, nôn, sưng môi. Gọi cấp cứu {emergency} ngay nếu bé khó thở, sưng môi hoặc lưỡi, lả đi.`,
  `The first time with ${en}: give a small amount in the morning, at home, when your baby is well; watch for a rash, vomiting or swollen lips. Call {emergency} now if your baby has trouble breathing, a swollen lip or tongue, or goes floppy.`,
];

function recipe(id: string, data: Omit<RecipeContent, 'cover'>): SolidsSeed<RecipeContent> {
  return { id, reviewerLabel: NUTRITION, data: { ...data, cover: null } };
}

export const seedRecipes: readonly SolidsSeed<RecipeContent>[] = [
  // ----- 6–8 months: smooth, then soft lumps; soft finger foods for self-feeding -----
  recipe('rcp_chao_ray_ga_bi_do', {
    title: t('Cháo rây thịt gà bí đỏ', 'Smooth congee with chicken and pumpkin'),
    summary: t(
      'Bát cháo đầu tiên đủ bốn nhóm: gạo, thịt gà giàu sắt, bí đỏ và chút dầu, xay mịn và đặc đến mức không chảy khỏi thìa.',
      'A first bowl with all four groups: rice, iron-rich chicken, pumpkin and a little oil, blended smooth and thick enough to stay on the spoon.',
    ),
    ageMonths: { from: 6, to: 9 },
    texture: 'smooth',
    methods: ['spoon'],
    servings: 3,
    prepMinutes: 10,
    cookMinutes: 40,
    ingredients: [
      ing('fd_rice', ['Gạo tẻ', 'Rice'], 30, 'g'),
      ing('fd_chicken', ['Thịt gà phần đùi', 'Chicken thigh'], 40, 'g', [
        'bỏ da, xương',
        'skin and bones removed',
      ]),
      ing('fd_pumpkin', ['Bí đỏ', 'Pumpkin'], 60, 'g', ['gọt vỏ, bỏ hạt', 'peeled and deseeded']),
      water(400),
      oil(1, 'tsp', ['mỗi bát', 'per bowl']),
    ],
    steps: steps(
      [
        'Vo gạo, ngâm 30 phút cho mềm hạt. Rửa tay và dụng cụ sạch sẽ.',
        'Rinse the rice and soak it for 30 minutes. Wash your hands and utensils.',
      ],
      [
        'Nấu gạo với nước, lửa nhỏ, khuấy thỉnh thoảng khoảng 30 phút đến khi cháo nhừ.',
        'Simmer the rice in the water, stirring now and then, for about 30 minutes until very soft.',
      ],
      [
        'Trong lúc đó, băm hoặc xay nhuyễn thịt gà; bí đỏ cắt miếng nhỏ.',
        'Meanwhile, mince or blend the chicken finely and cut the pumpkin into small pieces.',
      ],
      [
        'Cho thịt gà vào cháo, khuấy tan để thịt không vón; thêm bí đỏ, nấu thêm 10 phút đến khi thịt chín kỹ và bí mềm.',
        'Stir the chicken into the congee so it does not clump, add the pumpkin and cook for 10 more minutes until the chicken is cooked through and the pumpkin is soft.',
      ],
      [
        'Xay hoặc rây cả nồi cho thật mịn. Không nêm muối, đường hay nước mắm.',
        'Blend or sieve the whole pot until very smooth. No salt, sugar or fish sauce.',
      ],
      [
        'Múc một phần ra bát, thêm dầu ăn, khuấy đều. Thử độ đặc: cháo bám thìa, trôi chậm là vừa; quá đặc thì pha thêm chút nước sôi hoặc sữa của bé.',
        "Spoon a portion into a bowl and stir in the oil. Test it: the congee should cling to the spoon and slide off slowly; if too thick, loosen it with a little boiled water or your baby's milk.",
      ],
      [
        'Để nguội đến khi chỉ còn ấm, thử trên cổ tay rồi mới cho bé ăn, bắt đầu vài thìa nhỏ.',
        'Let it cool until just warm, test it on your wrist, then start with a few small spoonfuls.',
      ],
    ),
    storage: STORE_RICE,
    tip: t(
      'Bé mới ăn vài thìa là bình thường. Có thể thay thịt gà bằng thịt bò, thịt lợn nạc hoặc cá đã gỡ xương, thay bí đỏ bằng cà rốt hay khoai lang.',
      'A few spoonfuls is normal at first. Swap the chicken for beef, lean pork or boned fish, and the pumpkin for carrot or sweet potato.',
    ),
    relatedArticleIds: [
      'art_solids_first_meals',
      'art_solids_vn_porridge',
      'art_solids_iron_foods',
      'art_solids_prep_storage',
    ],
    sources: [S.mohCf2026, S.unicef6to12, S.nhsFrom6Months, S.nhsStoringReheating],
  }),
  recipe('rcp_bot_bo_ca_rot', {
    title: t('Bột ăn dặm thịt bò cà rốt', 'Iron-fortified baby cereal with beef and carrot'),
    summary: t(
      'Bột ngũ cốc tăng cường sắt nấu cùng thịt bò xay và cà rốt: hai nguồn sắt trong một bát, mịn cho những tuần đầu.',
      'Iron-fortified baby cereal with minced beef and carrot: two sources of iron in one bowl, smooth for the first weeks.',
    ),
    ageMonths: { from: 6, to: 9 },
    texture: 'smooth',
    methods: ['spoon'],
    servings: 2,
    prepMinutes: 10,
    cookMinutes: 20,
    ingredients: [
      ing('fd_beef', ['Thịt bò thăn', 'Lean beef'], 30, 'g', ['xay nhuyễn', 'finely minced']),
      ing('fd_carrot', ['Cà rốt', 'Carrot'], 40, 'g'),
      ing(
        'fd_fortified_cereal',
        ['Bột ăn dặm tăng cường sắt', 'Iron-fortified baby cereal'],
        3,
        'tbsp',
        ['loại không đường, không muối', 'unsweetened and unsalted'],
      ),
      water(200),
      oil(1, 'tsp'),
    ],
    steps: steps(
      [
        'Cà rốt gọt vỏ, cắt nhỏ. Thịt bò rửa sạch, xay hoặc băm thật nhuyễn.',
        'Peel and chop the carrot. Rinse the beef and mince it very finely.',
      ],
      [
        'Đun sôi nước, cho cà rốt vào nấu 10 phút đến khi mềm.',
        'Bring the water to the boil and cook the carrot for 10 minutes until soft.',
      ],
      [
        'Cho thịt bò vào, dùng thìa đánh tơi để thịt không vón cục, nấu thêm 5–7 phút đến khi chín kỹ, không còn màu hồng.',
        'Add the beef and break it up with a spoon so it does not clump; cook for 5–7 more minutes until cooked through with no pink.',
      ],
      [
        'Xay mịn thịt và cà rốt cùng nước luộc.',
        'Blend the beef and carrot smooth with the cooking water.',
      ],
      [
        'Để bớt nóng rồi rắc từ từ bột ăn dặm vào, khuấy đều đến khi sánh mịn, đặc đến mức không chảy khỏi thìa; làm theo hướng dẫn trên bao bì.',
        'Let it cool a little, then sprinkle in the cereal, stirring until smooth and thick enough to stay on the spoon; follow the pack instructions.',
      ],
      ['Thêm dầu ăn, khuấy đều. Không nêm.', 'Stir in the oil. No seasoning.'],
      [
        'Thử độ ấm trên cổ tay trước khi cho bé ăn.',
        'Test the temperature on your wrist before feeding.',
      ],
    ),
    storage: t(
      'Bột đã pha nên ăn ngay. Phần thịt và cà rốt xay (chưa pha bột) có thể làm nguội, chia khay đá trữ đông; rã đông trong ngăn mát, hâm nóng sôi đều một lần rồi mới pha bột.',
      'Mixed cereal is best eaten straight away. The blended beef and carrot (before the cereal goes in) can be cooled and frozen in an ice-cube tray; thaw in the fridge and reheat once until piping hot before mixing.',
    ),
    tip: t(
      'Từ khoảng 7–8 tháng, thay bột bằng cháo nhừ và để thịt, cà rốt lợn cợn hơn. Ăn kèm vài thìa đu đủ hoặc cam nghiền giúp hấp thu sắt tốt hơn.',
      'From about 7–8 months, swap the cereal for soft congee and leave the beef and carrot lumpier. A few spoonfuls of papaya or orange alongside help iron absorption.',
    ),
    relatedArticleIds: [
      'art_solids_iron_foods',
      'art_solids_first_meals',
      'art_solids_vn_porridge',
    ],
    sources: [S.cdcIron, S.mohCf2026, S.unicef6to12, S.nhsStoringReheating],
  }),
  recipe('rcp_que_rau_cu_hap', {
    title: t(
      'Que khoai lang, bí đỏ và bông cải hấp',
      'Steamed sweet potato, pumpkin and broccoli sticks',
    ),
    summary: t(
      'Món cầm tay đầu tiên cho bé tập tự ăn: rau củ cắt que dài cỡ ngón tay, hấp đến khi bóp nát dễ dàng.',
      'A first finger food for self-feeding: vegetables cut into finger-length sticks and steamed until they squash easily.',
    ),
    ageMonths: { from: 6, to: 12 },
    texture: 'finger',
    methods: ['blw'],
    servings: 2,
    prepMinutes: 10,
    cookMinutes: 15,
    ingredients: [
      ing('fd_sweet_potato', ['Khoai lang', 'Sweet potato'], 60, 'g'),
      ing('fd_pumpkin', ['Bí đỏ', 'Pumpkin'], 60, 'g'),
      ing('fd_broccoli', ['Bông cải xanh', 'Broccoli'], 50, 'g', [
        'để cuống dài làm tay cầm',
        'stalks left long as handles',
      ]),
      ing('fd_olive_oil', ['Dầu ô liu', 'Olive oil'], 1, 'tsp', ['tuỳ chọn', 'optional']),
    ],
    steps: steps(
      [
        'Gọt vỏ khoai lang và bí đỏ, cắt que dài cỡ ngón tay người lớn, dày khoảng 1,5 cm để bé dễ nắm.',
        'Peel the sweet potato and pumpkin and cut them into sticks the length of an adult finger and about 1.5 cm thick, easy for a baby to grasp.',
      ],
      [
        'Tách bông cải thành từng bông nhỏ, giữ phần cuống dài làm tay cầm.',
        'Break the broccoli into small florets, keeping long stalks as handles.',
      ],
      [
        'Hấp khoai lang và bí đỏ 12–15 phút, bông cải 6–8 phút, đến khi mềm.',
        'Steam the sweet potato and pumpkin for 12–15 minutes and the broccoli for 6–8 minutes, until soft.',
      ],
      [
        'Thử độ mềm: bóp một que giữa ngón cái và ngón trỏ, phải nát dễ dàng. Nếu còn cứng, hấp thêm.',
        'Test: squeeze a stick between your thumb and forefinger; it should squash easily. If not, steam it longer.',
      ],
      [
        'Để nguội đến khi chỉ còn ấm; có thể quét mỏng chút dầu ô liu. Không nêm.',
        'Let them cool until just warm; brush with a little olive oil if you like. No seasoning.',
      ],
      [
        'Cho bé ngồi thẳng trên ghế ăn có đai, đặt 2–3 que lên khay để bé tự cầm. Luôn ngồi cạnh bé suốt bữa.',
        'Sit your baby upright in a high chair with straps and put 2–3 sticks on the tray to pick up. Stay with your baby for the whole meal.',
      ],
      [
        'Bé oẹ khi tập ăn là bình thường; bình tĩnh, không thò tay vào miệng bé. Nếu bé không ho, không khóc, không thở được, gọi cấp cứu {emergency} và sơ cứu hóc dị vật.',
        'Gagging while learning is normal; stay calm and keep your fingers out of their mouth. If your baby cannot cough, cry or breathe, call {emergency} and start choking first aid.',
      ],
    ),
    storage: STORE_COOKED,
    tip: t(
      'Bé 6–8 tháng nắm cả bàn tay nên que dài dễ cầm hơn miếng nhỏ. Nếu nhà mình ăn dặm kết hợp, có thể đút thêm cháo bằng thìa trong cùng bữa.',
      'At 6–8 months babies grab with the whole hand, so long sticks are easier than small pieces. If you combine methods, spoon-feed some congee at the same meal.',
    ),
    relatedArticleIds: [
      'art_solids_finger_foods',
      'art_solids_choking_safety',
      'art_solids_methods',
    ],
    sources: [S.nhsChokingGagging, S.nhsFrom6Months, S.hcChokingPrevention, S.fangupoBliss2016],
  }),
  recipe('rcp_chao_bi_do_trung', {
    title: t('Cháo bí đỏ trứng gà', 'Pumpkin congee with egg'),
    summary: t(
      'Món giúp bé làm quen trứng từ 6 tháng: trứng luộc chín kỹ nghiền mịn trong cháo bí đỏ. Lần đầu cho một lượng nhỏ, vào buổi sáng.',
      'A way to introduce egg from 6 months: well-cooked egg mashed smooth into pumpkin congee. Start with a small amount, in the morning.',
    ),
    ageMonths: { from: 6, to: 12 },
    texture: 'smooth',
    methods: ['spoon'],
    servings: 2,
    prepMinutes: 10,
    cookMinutes: 35,
    ingredients: [
      ing('fd_rice', ['Gạo tẻ', 'Rice'], 25, 'g'),
      ing('fd_pumpkin', ['Bí đỏ', 'Pumpkin'], 50, 'g'),
      ing('fd_egg', ['Trứng gà', 'Egg'], 1, 'piece', ['luộc chín kỹ', 'hard-boiled']),
      water(350),
      oil(1, 'tsp'),
    ],
    steps: steps(
      [
        'Nấu gạo với nước, lửa nhỏ khoảng 30 phút đến khi cháo nhừ; cho bí đỏ cắt nhỏ vào trong 10 phút cuối.',
        'Simmer the rice in the water for about 30 minutes until very soft, adding the chopped pumpkin for the last 10 minutes.',
      ],
      [
        'Luộc trứng 10 phút, đến khi lòng trắng và lòng đỏ đều chín kỹ, không còn lòng đào.',
        'Boil the egg for 10 minutes, until the white and the yolk are both firm, not runny.',
      ],
      [
        'Bóc vỏ trứng, nghiền mịn với một ít cháo.',
        'Peel the egg and mash it smooth with a little congee.',
      ],
      [
        'Xay mịn cháo bí đỏ, trộn trứng nghiền vào. Lần đầu chỉ dùng khoảng 1–2 thìa cà phê trứng, những lần sau tăng dần.',
        'Blend the pumpkin congee smooth and stir in the mashed egg. The first time, use only about 1–2 teaspoons of egg and increase it over the next meals.',
      ],
      [
        'Thêm dầu ăn, không nêm muối hay nước mắm. Để còn ấm rồi cho bé ăn.',
        'Stir in the oil; no salt or fish sauce. Serve warm.',
      ],
      firstTime('trứng', 'egg'),
      [
        'Nếu bé ăn ổn, cho trứng đều đặn vài lần mỗi tuần để duy trì.',
        'If it goes well, keep egg in the menu a few times a week.',
      ],
    ),
    storage: STORE_RICE,
    tip: t(
      'Có thể thay cháo bằng khoai lang hoặc bí đỏ nghiền. Trứng lòng đào và trứng sống chưa dùng cho bé.',
      'You can use mashed sweet potato or pumpkin instead of congee. Runny or raw egg is not for babies.',
    ),
    relatedArticleIds: ['art_allergen_intro', 'art_solids_reactions', 'art_solids_first_meals'],
    sources: [S.asciaIntroSolids, S.nhsFoodAllergies, S.bsaciParents, S.nhsFrom6Months],
  }),
  recipe('rcp_chuoi_bo_dau_phong', {
    title: t('Chuối nghiền bơ đậu phộng', 'Mashed banana with smooth peanut butter'),
    summary: t(
      'Cách đơn giản để bé làm quen đậu phộng: bơ đậu phộng mịn pha loãng trộn chuối chín. Không bao giờ dùng đậu phộng nguyên hạt hay giã thô.',
      'A simple way to introduce peanut: thinned smooth peanut butter mixed into ripe banana. Never whole or roughly crushed peanuts.',
    ),
    ageMonths: { from: 6, to: 12 },
    texture: 'smooth',
    methods: ['spoon'],
    servings: 1,
    prepMinutes: 5,
    cookMinutes: 0,
    ingredients: [
      ing('fd_banana', ['Chuối chín', 'Ripe banana'], 0.5, 'piece'),
      ing('fd_peanut_butter', ['Bơ đậu phộng mịn', 'Smooth peanut butter'], 0.5, 'tsp', [
        '100% đậu phộng, không muối',
        '100% peanut, unsalted',
      ]),
      ing(null, ['Nước ấm hoặc sữa của bé', "Warm water or your baby's milk"], 1, 'tsp'),
    ],
    steps: steps(
      [
        'Pha bơ đậu phộng với nước ấm hoặc sữa mẹ, sữa công thức, khuấy đến khi loãng và mịn, không còn dính đặc.',
        'Mix the peanut butter with warm water, breast milk or formula until thin and smooth, no longer thick and sticky.',
      ],
      ['Nghiền chuối thật mịn bằng nĩa.', 'Mash the banana very smooth with a fork.'],
      [
        'Trộn đều bơ đậu phộng đã pha loãng vào chuối.',
        'Stir the thinned peanut butter into the banana.',
      ],
      [
        'Lần đầu: cho bé ăn một lượng nhỏ khoảng đầu thìa cà phê vào buổi sáng, ở nhà; nếu sau 10–15 phút bé vẫn ổn, cho ăn tiếp phần còn lại.',
        'The first time, offer a small amount on the tip of a teaspoon in the morning, at home; if your baby is fine after 10–15 minutes, offer the rest.',
      ],
      [
        'Theo dõi bé khoảng 2 giờ: nổi mẩn, mề đay, nôn, sưng môi. Gọi cấp cứu {emergency} ngay nếu bé khó thở, ho, khò khè, sưng môi hoặc lưỡi, lả đi.',
        'Watch your baby for about 2 hours for a rash, hives, vomiting or swollen lips. Call {emergency} now if your baby has trouble breathing, coughs or wheezes, has a swollen lip or tongue, or goes floppy.',
      ],
      [
        'Nếu bé ăn ổn, duy trì đậu phộng khoảng 2 lần mỗi tuần (ASCIA).',
        'If it goes well, keep peanut in the menu about twice a week (ASCIA).',
      ],
    ),
    storage: t(
      'Làm đến đâu ăn đến đó; chuối nghiền để lâu sẽ thâm. Bỏ phần bé ăn dở.',
      "Make it just before eating; mashed banana browns quickly. Throw away your baby's leftovers.",
    ),
    tip: t(
      'Nếu bé bị chàm nặng hoặc đã có dị ứng thức ăn, hỏi bác sĩ trước khi cho bé làm quen đậu phộng. Có thể trộn bơ đậu phộng vào cháo hoặc khoai lang nghiền thay cho chuối.',
      'If your baby has severe eczema or a known food allergy, ask your doctor before introducing peanut. You can stir the peanut butter into congee or mashed sweet potato instead of banana.',
    ),
    relatedArticleIds: ['art_allergen_intro', 'art_solids_reactions', 'art_solids_foods_to_avoid'],
    sources: [S.asciaIntroSolids, S.nhsFoodAllergies, S.bsaciParents, S.nhsFoodsToAvoid],
  }),
  recipe('rcp_ca_hoi_khoai_tay', {
    title: t('Cá hồi hấp nghiền với khoai tây và bông cải', 'Salmon mash with potato and broccoli'),
    summary: t(
      'Món làm quen cá: cá hồi hấp gỡ kỹ xương, nghiền cùng khoai tây và bông cải xanh. Cá hồi ít thủy ngân, có sắt và chất béo tốt.',
      'A first fish dish: steamed salmon, carefully boned and mashed with potato and broccoli. Salmon is low in mercury and has iron and healthy fats.',
    ),
    ageMonths: { from: 6, to: 10 },
    texture: 'smooth',
    methods: ['spoon'],
    servings: 2,
    prepMinutes: 10,
    cookMinutes: 20,
    ingredients: [
      ing('fd_salmon', ['Cá hồi phi lê', 'Salmon fillet'], 40, 'g', ['bỏ da', 'skinless']),
      ing('fd_potato', ['Khoai tây', 'Potato'], 80, 'g'),
      ing('fd_broccoli', ['Bông cải xanh', 'Broccoli'], 30, 'g'),
      ing('fd_olive_oil', ['Dầu ô liu', 'Olive oil'], 1, 'tsp'),
      ing(null, ['Sữa của bé hoặc nước hấp', "Your baby's milk or steaming water"], 2, 'tbsp'),
    ],
    steps: steps(
      [
        'Khoai tây gọt vỏ, cắt miếng; bông cải tách bông nhỏ.',
        'Peel and chop the potato; break the broccoli into small florets.',
      ],
      [
        'Hấp khoai tây 15 phút; đặt cá hồi và bông cải lên hấp cùng trong 8–10 phút cuối, đến khi cá chín đục, tách thớ dễ dàng.',
        'Steam the potato for 15 minutes, adding the salmon and broccoli for the last 8–10 minutes, until the fish is opaque and flakes easily.',
      ],
      [
        'Gỡ cá thành vụn, dùng tay miết kỹ để loại hết xương nhỏ.',
        'Flake the fish and feel it carefully with your fingers to remove every small bone.',
      ],
      [
        'Nghiền hoặc xay khoai tây, bông cải và cá với dầu ô liu và sữa của bé đến khi mịn. Không nêm muối.',
        "Mash or blend the potato, broccoli and fish with the olive oil and your baby's milk until smooth. No salt.",
      ],
      firstTime('cá', 'fish'),
      ['Để còn ấm rồi cho bé ăn.', 'Serve warm.'],
    ),
    storage: STORE_COOKED,
    tip: t(
      'Chọn cá ít thủy ngân như cá hồi, cá basa, cá rô phi, cá tuyết; tránh cá mập, cá kiếm, cá thu vua. Từ 8–9 tháng nghiền thô hơn để bé tập nhai.',
      'Choose low-mercury fish such as salmon, basa, tilapia or cod; avoid shark, swordfish and king mackerel. From 8–9 months mash it more roughly so your baby practises chewing.',
    ),
    relatedArticleIds: ['art_solids_iron_foods', 'art_allergen_intro', 'art_solids_foods_to_avoid'],
    sources: [S.fdaFish, S.asciaIntroSolids, S.nhsFrom6Months, S.nhsStoringReheating],
  }),
  recipe('rcp_bo_dau_phu_non', {
    title: t('Bơ nghiền với đậu phụ non', 'Avocado and silken tofu mash'),
    summary: t(
      'Món mịn, béo, gần như không cần nấu, giúp bé làm quen đậu nành: đậu phụ non hấp qua rồi nghiền cùng quả bơ chín.',
      'A smooth, creamy dish that needs almost no cooking and introduces soy: silken tofu, briefly steamed, mashed with ripe avocado.',
    ),
    ageMonths: { from: 6, to: 10 },
    texture: 'smooth',
    methods: ['spoon', 'blw'],
    servings: 1,
    prepMinutes: 5,
    cookMinutes: 5,
    ingredients: [
      ing('fd_avocado', ['Quả bơ chín', 'Ripe avocado'], 40, 'g'),
      ing('fd_silken_tofu', ['Đậu phụ non', 'Silken tofu'], 40, 'g'),
    ],
    steps: steps(
      [
        'Hấp đậu phụ non 3–5 phút cho nóng đều rồi để nguội.',
        'Steam the silken tofu for 3–5 minutes until hot through, then let it cool.',
      ],
      ['Nạo thịt quả bơ chín.', 'Scoop out the ripe avocado.'],
      [
        'Nghiền bơ và đậu phụ với nhau bằng nĩa đến khi mịn; thêm chút sữa của bé nếu đặc.',
        "Mash the avocado and tofu together with a fork until smooth; loosen with a little of your baby's milk if thick.",
      ],
      firstTime('đậu nành', 'soy'),
      [
        'Đút bằng thìa, hoặc đặt sẵn một ít lên thìa để bé tự cầm đưa vào miệng. Không nêm.',
        'Spoon-feed it, or load a spoon and let your baby bring it to their mouth. No seasoning.',
      ],
    ),
    storage: t(
      'Ăn ngay sau khi làm; bơ để lâu bị thâm và mất ngon. Không trữ đông. Bỏ phần bé ăn dở.',
      "Eat straight away; avocado browns and loses flavour. Do not freeze. Throw away your baby's leftovers.",
    ),
    tip: t(
      'Khi bé lớn hơn, cắt bơ và đậu phụ thành que để bé tự cầm. Có thể thay đậu phụ non bằng khoai lang hấp nghiền.',
      'As your baby grows, cut avocado and tofu into sticks to hold. You can use mashed steamed sweet potato instead of tofu.',
    ),
    relatedArticleIds: ['art_allergen_intro', 'art_solids_methods', 'art_solids_first_meals'],
    sources: [S.asciaIntroSolids, S.nhsFoodAllergies, S.nhsFrom6Months],
  }),
  recipe('rcp_sua_chua_du_du', {
    title: t('Sữa chua nguyên kem với đu đủ nghiền', 'Full-fat yogurt with mashed papaya'),
    summary: t(
      'Bữa phụ nhẹ giúp bé làm quen sữa bò qua sữa chua: sữa chua nguyên kem không đường trộn đu đủ chín nghiền.',
      "A light snack that introduces cow's milk through yogurt: full-fat, unsweetened yogurt with mashed ripe papaya.",
    ),
    ageMonths: { from: 6, to: 12 },
    texture: 'smooth',
    methods: ['spoon'],
    servings: 1,
    prepMinutes: 5,
    cookMinutes: 0,
    ingredients: [
      ing('fd_yogurt', ['Sữa chua nguyên kem', 'Full-fat yogurt'], 3, 'tbsp', [
        'không đường, đã thanh trùng',
        'unsweetened, pasteurized',
      ]),
      ing('fd_papaya', ['Đu đủ chín', 'Ripe papaya'], 40, 'g'),
    ],
    steps: steps(
      [
        'Gọt vỏ, bỏ hạt đu đủ, nghiền thật mịn.',
        'Peel and deseed the papaya and mash it very smooth.',
      ],
      [
        'Để sữa chua ra ngoài vài phút cho bớt lạnh.',
        'Leave the yogurt out for a few minutes to take the chill off.',
      ],
      [
        'Trộn đu đủ với sữa chua; trái cây đã đủ ngọt tự nhiên.',
        'Mix the papaya into the yogurt; the fruit is sweet enough on its own.',
      ],
      firstTime('sữa chua', 'yogurt'),
      [
        'Trong năm đầu, sữa mẹ hoặc sữa công thức vẫn là đồ uống chính; sữa bò chỉ dùng trong món ăn như thế này.',
        "In the first year, breast milk or formula stays the main drink; cow's milk is used only in food like this.",
      ],
    ),
    storage: t(
      'Trộn đến đâu ăn đến đó. Sữa chua chưa mở giữ trong ngăn mát theo hạn dùng; đu đủ đã cắt đậy kín, dùng trong ngày.',
      'Mix just before eating. Keep unopened yogurt in the fridge within its date; cover cut papaya and use it the same day.',
    ),
    tip: t(
      'Có thể thay đu đủ bằng chuối, xoài hoặc lê hấp nghiền. Tránh sữa chua có đường, váng sữa ngọt và sữa chua uống.',
      'Swap the papaya for banana, mango or steamed pear. Avoid sweetened yogurt, sweet dairy desserts and yogurt drinks.',
    ),
    relatedArticleIds: ['art_allergen_intro', 'art_solids_foods_to_avoid', 'art_water_juice'],
    sources: [S.asciaIntroSolids, S.nhsFoodsToAvoid, S.nhsDrinksCups, S.nhsFrom6Months],
  }),
  recipe('rcp_chao_dau_xanh_thit_lon', {
    title: t('Cháo đậu xanh thịt lợn rau ngót', 'Mung bean congee with pork and katuk'),
    summary: t(
      'Cháo nhừ không rây, lợn cợn nhẹ để bé tập nhai: thịt lợn nạc và đậu xanh cho sắt, rau ngót thêm rau xanh.',
      'Soft, unsieved congee with gentle lumps for chewing practice: lean pork and mung beans for iron, katuk for greens.',
    ),
    ageMonths: { from: 7, to: 12 },
    texture: 'mashed',
    methods: ['spoon'],
    servings: 3,
    prepMinutes: 15,
    cookMinutes: 45,
    ingredients: [
      ing('fd_rice', ['Gạo tẻ', 'Rice'], 30, 'g'),
      ing('fd_mung_bean', ['Đậu xanh cà vỏ', 'Split mung beans'], 15, 'g', [
        'ngâm 2 giờ',
        'soaked for 2 hours',
      ]),
      ing('fd_pork', ['Thịt lợn nạc', 'Lean pork'], 40, 'g', ['băm nhỏ', 'minced']),
      ing('fd_katuk', ['Rau ngót', 'Katuk'], 15, 'g', ['lá non', 'young leaves']),
      water(450),
      oil(1, 'tsp'),
    ],
    steps: steps(
      [
        'Vo gạo, ngâm cùng đậu xanh khoảng 2 giờ cho mềm.',
        'Rinse the rice and soak it with the mung beans for about 2 hours.',
      ],
      [
        'Nấu gạo và đậu xanh với nước, lửa nhỏ khoảng 35 phút đến khi nhừ, khuấy thỉnh thoảng cho khỏi dính.',
        'Simmer the rice and beans in the water for about 35 minutes until very soft, stirring now and then so they do not stick.',
      ],
      [
        'Cho thịt lợn băm vào, đánh tơi và nấu đến khi chín kỹ.',
        'Add the minced pork, break it up and cook until cooked through.',
      ],
      [
        'Rau ngót rửa sạch, băm thật nhỏ, cho vào khi cháo gần chín, đun thêm 3–5 phút.',
        'Wash the katuk, chop it very finely and add it near the end; cook for 3–5 more minutes.',
      ],
      [
        'Dùng thìa dầm hoặc xay ngắt quãng để cháo còn lợn cợn nhẹ, không rây. Không nêm muối, nước mắm.',
        'Mash with a spoon or pulse briefly so the congee keeps gentle lumps; do not sieve. No salt or fish sauce.',
      ],
      [
        'Múc ra bát, thêm dầu ăn, để còn ấm rồi cho bé ăn.',
        'Spoon into a bowl, stir in the oil and serve warm.',
      ],
    ),
    storage: STORE_RICE,
    tip: t(
      'Nếu bé còn oẹ nhiều với độ lợn cợn, xay mịn hơn một chút rồi tăng dần độ thô qua từng tuần. Có thể thay rau ngót bằng mồng tơi hoặc cải bó xôi.',
      'If your baby still gags a lot on lumps, blend it a little smoother and increase the texture week by week. Swap the katuk for Malabar spinach or spinach.',
    ),
    relatedArticleIds: [
      'art_solids_textures_by_month',
      'art_solids_vn_porridge',
      'art_solids_iron_foods',
    ],
    sources: [S.mohCf2026, S.nhs7to9Months, S.coulthardLumps2009, S.nhsStoringReheating],
  }),
  recipe('rcp_vien_bo_khoai_lang', {
    title: t('Thỏi thịt bò khoai lang hấp mềm', 'Soft steamed beef and sweet potato fingers'),
    summary: t(
      'Món cầm tay giàu sắt cho bé tự ăn: thịt bò xay trộn khoai lang, nặn thỏi dài cỡ ngón tay và hấp mềm.',
      'An iron-rich finger food for self-feeding: minced beef mixed with sweet potato, shaped into finger-length logs and steamed soft.',
    ),
    ageMonths: { from: 6, to: 18 },
    texture: 'finger',
    methods: ['blw', 'spoon'],
    servings: 3,
    prepMinutes: 15,
    cookMinutes: 20,
    ingredients: [
      ing('fd_beef', ['Thịt bò xay', 'Minced beef'], 100, 'g'),
      ing('fd_sweet_potato', ['Khoai lang', 'Sweet potato'], 80, 'g', [
        'hấp chín, nghiền',
        'steamed and mashed',
      ]),
      ing('fd_oats', ['Yến mạch cán', 'Rolled oats'], 2, 'tbsp', ['xay mịn', 'finely ground']),
    ],
    steps: steps(
      [
        'Khoai lang gọt vỏ, hấp chín mềm rồi nghiền nhuyễn, để nguội.',
        'Peel the sweet potato, steam it soft, mash it and let it cool.',
      ],
      [
        'Trộn đều thịt bò xay, khoai lang và yến mạch xay mịn đến khi hỗn hợp dẻo, nặn được. Không nêm.',
        'Mix the beef, sweet potato and ground oats until the mixture holds together. No seasoning.',
      ],
      [
        'Nặn thành thỏi dài cỡ ngón tay người lớn, dày khoảng 1,5 cm, hoặc viên dẹt.',
        'Shape into logs the length of an adult finger and about 1.5 cm thick, or into flat patties.',
      ],
      [
        'Xếp lên đĩa có lót giấy nến, hấp 15–20 phút đến khi chín kỹ, bên trong không còn màu hồng.',
        'Lay them on a plate lined with baking paper and steam for 15–20 minutes until cooked through with no pink inside.',
      ],
      [
        'Thử độ mềm: bóp giữa hai ngón tay phải nát dễ dàng.',
        'Test: it should squash easily between two fingers.',
      ],
      [
        'Để nguội đến ấm, đặt 2–3 thỏi lên khay cho bé tự cầm và ngồi cạnh bé suốt bữa. Bé ăn thìa thì nghiền thỏi thịt vào cháo.',
        'Cool until warm, put 2–3 logs on the tray for your baby to hold and stay close for the whole meal. For spoon feeding, mash a log into congee.',
      ],
    ),
    storage: t(
      'Làm nguội, cất tủ lạnh trong vòng 1–2 giờ, dùng trong 2 ngày. Có thể trữ đông thỏi sống hoặc đã hấp theo từng phần; hấp lại một lần cho nóng đều.',
      'Cool and refrigerate within 1–2 hours; use within 2 days. Freeze raw or steamed logs in portions; re-steam once until hot all through.',
    ),
    tip: t(
      'Có thể thay thịt bò bằng thịt lợn nạc hoặc thịt gà xay, thay khoai lang bằng bí đỏ. Thịt đỏ là nguồn sắt dễ hấp thu, nên có trong bữa của bé vài lần mỗi tuần.',
      'Swap the beef for lean pork or chicken mince, and the sweet potato for pumpkin. Red meat is an easily absorbed source of iron, good to offer a few times a week.',
    ),
    relatedArticleIds: [
      'art_solids_finger_foods',
      'art_solids_iron_foods',
      'art_solids_methods',
      'art_solids_choking_safety',
    ],
    sources: [S.cdcIron, S.nhsChokingGagging, S.nhsFrom6Months, S.nhsStoringReheating],
  }),
  recipe('rcp_chao_gan_ga_ca_rot', {
    title: t('Cháo gan gà cà rốt', 'Chicken liver and carrot congee'),
    summary: t(
      'Gan gà rất giàu sắt và vitamin A: chỉ cần một lượng nhỏ, khoảng một lần mỗi tuần, nấu chín kỹ trong cháo nhừ lợn cợn.',
      'Chicken liver is very rich in iron and vitamin A: a small amount about once a week, cooked through in soft, lumpy congee.',
    ),
    ageMonths: { from: 7, to: 12 },
    texture: 'mashed',
    methods: ['spoon'],
    servings: 3,
    prepMinutes: 15,
    cookMinutes: 40,
    ingredients: [
      ing('fd_rice', ['Gạo tẻ', 'Rice'], 30, 'g'),
      ing('fd_chicken_liver', ['Gan gà', 'Chicken liver'], 20, 'g'),
      ing('fd_carrot', ['Cà rốt', 'Carrot'], 40, 'g'),
      water(400),
      oil(1, 'tsp'),
    ],
    steps: steps(
      [
        'Gan gà cắt bỏ gân, phần xanh nếu có, ngâm nước lạnh 15 phút rồi rửa sạch.',
        'Trim the chicken liver of sinew and any green parts, soak it in cold water for 15 minutes and rinse.',
      ],
      [
        'Nấu gạo với nước khoảng 30 phút đến khi nhừ; cho cà rốt cắt nhỏ vào nấu cùng.',
        'Simmer the rice in the water for about 30 minutes until very soft, cooking the chopped carrot with it.',
      ],
      [
        'Luộc hoặc hấp gan đến khi chín kỹ, cắt ra bên trong không còn màu hồng.',
        'Boil or steam the liver until cooked through, with no pink inside when cut.',
      ],
      [
        'Nghiền gan thật nhuyễn, cho vào cháo, khuấy đều, đun sôi lại.',
        'Mash the liver very finely, stir it into the congee and bring it back to the boil.',
      ],
      [
        'Dầm cháo để còn lợn cợn nhẹ. Thêm dầu ăn, không nêm.',
        'Mash the congee, leaving gentle lumps. Stir in the oil; no seasoning.',
      ],
      ['Để còn ấm rồi cho bé ăn.', 'Serve warm.'],
    ),
    storage: STORE_RICE,
    tip: t(
      'Gan nhiều vitamin A nên chỉ cần khoảng một lần mỗi tuần; những ngày khác dùng thịt bò, thịt lợn, cá. Có thể thay gan gà bằng gan lợn.',
      'Liver is high in vitamin A, so about once a week is enough; on other days use beef, pork or fish. Pork liver works too.',
    ),
    relatedArticleIds: [
      'art_solids_iron_foods',
      'art_solids_vn_porridge',
      'art_solids_textures_by_month',
    ],
    sources: [S.cdcIron, S.nhsIron, S.mohCf2026, S.nhs7to9Months],
  }),
  recipe('rcp_chao_tom_bi_xanh', {
    title: t('Cháo tôm bí xanh', 'Shrimp and winter melon congee'),
    summary: t(
      'Món giúp bé làm quen tôm: tôm bóc vỏ băm nhỏ, nấu chín kỹ cùng bí xanh trong cháo nhừ. Lần đầu cho ít và theo dõi bé.',
      'A way to introduce shrimp: peeled, minced shrimp cooked through with winter melon in soft congee. Start small and watch your baby.',
    ),
    ageMonths: { from: 8, to: 13 },
    texture: 'mashed',
    methods: ['spoon'],
    servings: 3,
    prepMinutes: 15,
    cookMinutes: 40,
    ingredients: [
      ing('fd_rice', ['Gạo tẻ', 'Rice'], 30, 'g'),
      ing('fd_shrimp', ['Tôm tươi', 'Fresh shrimp'], 40, 'g', [
        'bóc vỏ, bỏ chỉ đen',
        'peeled and deveined',
      ]),
      ing('fd_winter_melon', ['Bí xanh', 'Winter melon'], 60, 'g'),
      ing('fd_spring_onion', ['Hành lá', 'Spring onion'], 1, 'piece', [
        'tuỳ chọn, thái nhỏ',
        'optional, finely chopped',
      ]),
      water(400),
      oil(1, 'tsp'),
    ],
    steps: steps(
      [
        'Nấu gạo với nước khoảng 30 phút đến khi nhừ.',
        'Simmer the rice in the water for about 30 minutes until very soft.',
      ],
      [
        'Tôm bóc vỏ, bỏ chỉ đen, rửa sạch, băm nhỏ. Bí xanh gọt vỏ, bỏ ruột, thái hạt lựu nhỏ.',
        'Peel, devein, rinse and mince the shrimp. Peel the winter melon, remove the pith and dice it small.',
      ],
      [
        'Cho bí xanh vào cháo nấu 5 phút, rồi cho tôm vào, khuấy tơi, nấu thêm 3–4 phút đến khi tôm chín đỏ, đục đều.',
        'Cook the winter melon in the congee for 5 minutes, then stir in the shrimp and cook for 3–4 more minutes until pink and opaque all through.',
      ],
      [
        'Rắc hành lá thái thật nhỏ, tắt bếp. Không nêm muối hay nước mắm: tôm đã có vị ngọt tự nhiên.',
        'Sprinkle with very finely chopped spring onion and turn off the heat. No salt or fish sauce: shrimp is naturally sweet.',
      ],
      [
        'Dầm nhẹ để cháo còn lợn cợn mềm; thêm dầu ăn.',
        'Mash lightly, leaving soft lumps, and stir in the oil.',
      ],
      firstTime('tôm', 'shrimp'),
    ),
    storage: STORE_RICE,
    tip: t(
      'Tôm thuộc nhóm hải sản có vỏ, một nhóm dễ dị ứng. Nếu bé ăn ổn, tiếp tục cho tôm đều đặn để duy trì. Có thể thay bí xanh bằng mướp hoặc bí ngòi.',
      'Shrimp is a shellfish, one of the common allergens. If it goes well, keep offering it regularly. Swap the winter melon for luffa or zucchini.',
    ),
    relatedArticleIds: ['art_allergen_intro', 'art_solids_reactions', 'art_solids_vn_porridge'],
    sources: [S.asciaIntroSolids, S.nhsFoodAllergies, S.nhs7to9Months, S.nhsStoringReheating],
  }),
  // ----- 9–11 months: thick congee, soft rice, small soft pieces, finger foods at every meal -----
  recipe('rcp_chao_ca_loc_rau_ngot', {
    title: t('Cháo cá lóc rau ngót', 'Snakehead fish congee with katuk'),
    summary: t(
      'Cháo đặc hạt nguyên với cá lóc gỡ kỹ xương và rau ngót thái nhỏ, giúp bé tập nhai những miếng mềm.',
      'Thick whole-grain congee with carefully boned snakehead fish and chopped katuk, to practise chewing soft pieces.',
    ),
    ageMonths: { from: 9, to: 13 },
    texture: 'softPieces',
    methods: ['spoon'],
    servings: 3,
    prepMinutes: 15,
    cookMinutes: 40,
    ingredients: [
      ing('fd_rice', ['Gạo tẻ', 'Rice'], 40, 'g'),
      ing('fd_snakehead', ['Cá lóc phi lê', 'Snakehead fillet'], 60, 'g'),
      ing('fd_katuk', ['Rau ngót', 'Katuk'], 20, 'g'),
      ing(null, ['Gừng', 'Ginger'], 1, 'piece', [
        'một lát, vớt bỏ sau khi hấp',
        'one slice, removed after steaming',
      ]),
      water(500),
      oil(1, 'tsp'),
    ],
    steps: steps(
      [
        'Vo gạo, nấu với nước khoảng 30 phút đến khi hạt gạo nở mềm nhưng còn nguyên hạt.',
        'Rinse the rice and simmer it in the water for about 30 minutes until the grains are soft but still whole.',
      ],
      [
        'Cá lóc rửa sạch, hấp hoặc luộc với một lát gừng 8–10 phút đến khi chín đục.',
        'Rinse the fish and steam or poach it with the ginger slice for 8–10 minutes until opaque.',
      ],
      [
        'Gỡ cá thành miếng nhỏ cỡ hạt đậu, dùng tay miết kỹ để loại hết xương.',
        'Flake the fish into pea-sized pieces, feeling carefully with your fingers to remove every bone.',
      ],
      ['Rau ngót rửa sạch, thái nhỏ.', 'Wash the katuk and chop it small.'],
      [
        'Cho cá và rau ngót vào cháo, đun thêm 3–5 phút. Không nêm muối, nước mắm.',
        'Add the fish and katuk to the congee and cook for 3–5 more minutes. No salt or fish sauce.',
      ],
      [
        'Thêm dầu ăn, để còn ấm rồi cho bé ăn. Có thể để riêng vài miếng cá to đã gỡ xương cho bé tự cầm.',
        'Stir in the oil and serve warm. Keep a few larger boned flakes aside for your baby to pick up.',
      ],
    ),
    storage: STORE_RICE,
    tip: t(
      'Ở tuổi này bé học nhai bằng lợi, nên đừng xay mịn mãi. Nếu bé oẹ, thử miếng nhỏ hơn nhưng vẫn giữ độ thô.',
      "At this age babies learn to chew with their gums, so don't keep blending everything smooth. If your baby gags, try smaller pieces but keep the texture.",
    ),
    relatedArticleIds: [
      'art_solids_textures_by_month',
      'art_solids_menu_9_11',
      'art_solids_vn_porridge',
    ],
    sources: [S.mohCf2026, S.nhs7to9Months, S.fdaFish, S.nhsStoringReheating],
  }),
  recipe('rcp_chao_luon_bi_do', {
    title: t('Cháo lươn bí đỏ', 'Eel and pumpkin congee'),
    summary: t(
      'Món cháo quen thuộc của nhiều gia đình Việt, nấu riêng cho bé: thịt lươn lọc sạch xương, bí đỏ và hành lá, không nêm.',
      'A congee many Vietnamese families know, cooked separately for your baby: fully boned eel, pumpkin and spring onion, unseasoned.',
    ),
    ageMonths: { from: 10, to: 24 },
    texture: 'softPieces',
    methods: ['spoon'],
    servings: 3,
    prepMinutes: 20,
    cookMinutes: 40,
    ingredients: [
      ing('fd_rice', ['Gạo tẻ', 'Rice'], 40, 'g'),
      ing('fd_eel', ['Thịt lươn đã lọc xương', 'Boned eel'], 50, 'g'),
      ing('fd_pumpkin', ['Bí đỏ', 'Pumpkin'], 60, 'g'),
      ing('fd_spring_onion', ['Hành lá', 'Spring onion'], 1, 'piece'),
      ing(null, ['Gừng', 'Ginger'], 1, 'piece', ['một lát, vớt bỏ', 'one slice, removed']),
      water(500),
      oil(1, 'tsp'),
    ],
    steps: steps(
      [
        'Nhờ người bán làm sạch nhớt và lọc xương lươn. Ở nhà rửa lại, luộc hoặc hấp với gừng 10 phút đến khi chín kỹ.',
        'Ask the seller to clean and bone the eel. At home rinse it again and poach or steam it with the ginger for 10 minutes until cooked through.',
      ],
      [
        'Để nguội, xé thịt lươn thành sợi nhỏ, miết kỹ bằng tay để chắc chắn không còn xương.',
        'Let it cool, shred the eel finely and feel it carefully with your fingers to be sure no bones are left.',
      ],
      [
        'Nấu gạo với nước khoảng 30 phút; cho bí đỏ thái hạt lựu vào khi cháo gần nhừ.',
        'Simmer the rice in the water for about 30 minutes, adding the diced pumpkin when it is nearly soft.',
      ],
      [
        'Cho thịt lươn vào, đun sôi lại 3 phút. Rắc hành lá thái nhỏ.',
        'Add the eel and simmer for 3 more minutes. Sprinkle with chopped spring onion.',
      ],
      [
        'Phần của bé không nêm. Nếu nấu cho cả nhà, múc phần của bé ra trước rồi mới nêm phần người lớn.',
        "Your baby's portion stays unseasoned. If cooking for the family, take it out first and season the adults' portion afterwards.",
      ],
      ['Thêm dầu ăn, để còn ấm rồi cho bé ăn.', 'Stir in the oil and serve warm.'],
    ),
    storage: STORE_RICE,
    tip: t(
      'Lươn là cá nước ngọt, giàu đạm; lần đầu ăn cho lượng nhỏ và theo dõi bé. Không tìm được lươn lọc xương thì thay bằng cá lóc hoặc cá basa phi lê.',
      "Eel is a freshwater fish rich in protein; offer a small amount the first time and watch your baby. If you can't find boned eel, use snakehead or basa fillet.",
    ),
    relatedArticleIds: [
      'art_solids_vn_porridge',
      'art_solids_menu_9_11',
      'art_solids_choking_safety',
    ],
    sources: [S.mohCf2026, S.fdaFish, S.nhs10to12Months, S.nhsStoringReheating],
  }),
  recipe('rcp_chao_cua_mong_toi', {
    title: t('Cháo cua đồng mồng tơi', 'Rice-field crab congee with Malabar spinach'),
    summary: t(
      'Cua đồng giã lọc lấy nước, nấu riêu cùng cháo và mồng tơi thái nhỏ: món quê dịu mát, giúp bé làm quen cua, một món thuộc nhóm giáp xác dễ dị ứng.',
      'Rice-field crab pounded and strained into curds, cooked into congee with Malabar spinach: a gentle country dish that introduces crab, a crustacean and common allergen.',
    ),
    ageMonths: { from: 9, to: 24 },
    texture: 'softPieces',
    methods: ['spoon'],
    servings: 3,
    prepMinutes: 25,
    cookMinutes: 40,
    ingredients: [
      ing('fd_rice', ['Gạo tẻ', 'Rice'], 40, 'g'),
      ing('fd_crab', ['Cua đồng', 'Rice-field crab'], 100, 'g', [
        'loại tươi, còn sống',
        'fresh, live',
      ]),
      ing('fd_malabar_spinach', ['Mồng tơi', 'Malabar spinach'], 30, 'g'),
      water(600),
      oil(1, 'tsp'),
    ],
    steps: steps(
      [
        'Nấu gạo với 400 ml nước khoảng 30 phút đến khi nhừ.',
        'Simmer the rice in 400 ml of the water for about 30 minutes until soft.',
      ],
      [
        'Cua rửa thật sạch, bóc yếm và mai, khêu gạch để riêng. Giã hoặc xay nhuyễn phần thân cua.',
        'Scrub the crabs, remove the apron and top shell and set the roe aside. Pound or blend the bodies finely.',
      ],
      [
        'Hoà cua giã với 200 ml nước còn lại, lọc qua rây 2–3 lần để bỏ hết vỏ cứng.',
        'Mix the pounded crab with the remaining 200 ml of water and strain it 2–3 times to remove all the shell.',
      ],
      [
        'Đun nước cua lửa vừa, khuấy nhẹ đến khi riêu cua nổi lên và chín kỹ; cho gạch cua vào.',
        'Heat the crab liquid over medium heat, stirring gently, until the curds rise and are cooked through; add the roe.',
      ],
      [
        'Đổ nước cua và riêu vào nồi cháo, thêm mồng tơi thái nhỏ, đun 3 phút. Không nêm muối hay nước mắm.',
        'Pour the crab liquid and curds into the congee, add the chopped Malabar spinach and simmer for 3 minutes. No salt or fish sauce.',
      ],
      [
        'Múc ra bát, thêm dầu ăn. Kiểm tra lại bằng thìa để chắc không còn mảnh vỏ.',
        'Spoon into a bowl and stir in the oil. Check with a spoon that no bits of shell are left.',
      ],
      firstTime('cua', 'crab'),
    ),
    storage: STORE_RICE,
    tip: t(
      'Nếu bé đã ăn tôm ổn, cua là cách tiếp theo để duy trì nhóm giáp xác. Có thể thay mồng tơi bằng rau đay hoặc rau ngót.',
      'If shrimp went well, crab is a good next way to keep crustaceans in the menu. Swap the Malabar spinach for jute leaves or katuk.',
    ),
    relatedArticleIds: ['art_allergen_intro', 'art_solids_reactions', 'art_solids_menu_9_11'],
    sources: [S.asciaIntroSolids, S.nhsFoodAllergies, S.mohCf2026, S.nhsStoringReheating],
  }),
  recipe('rcp_mi_bo_cai_ngot', {
    title: t('Mì sợi thịt bò cải ngọt', 'Wheat noodles with beef and choy sum'),
    summary: t(
      'Món giúp bé làm quen lúa mì: mì sợi nấu mềm cắt ngắn, thịt bò băm và cải ngọt trong nước dùng không nêm.',
      'A way to introduce wheat: soft noodles cut short, minced beef and choy sum in an unseasoned broth.',
    ),
    ageMonths: { from: 9, to: 18 },
    texture: 'softPieces',
    methods: ['spoon', 'blw'],
    servings: 2,
    prepMinutes: 10,
    cookMinutes: 15,
    ingredients: [
      ing('fd_wheat_noodles', ['Mì sợi lúa mì', 'Wheat noodles'], 40, 'g', [
        'loại không có gói gia vị',
        'without a flavour sachet',
      ]),
      ing('fd_beef', ['Thịt bò', 'Beef'], 40, 'g', ['băm nhỏ', 'minced']),
      ing('fd_choy_sum', ['Cải ngọt', 'Choy sum'], 30, 'g'),
      ing('fd_carrot', ['Cà rốt', 'Carrot'], 30, 'g'),
      water(300),
      oil(1, 'tsp'),
    ],
    steps: steps(
      [
        'Luộc mì trong nồi nước riêng đến khi thật mềm, vớt ra, cắt sợi ngắn khoảng 2 cm.',
        'Boil the noodles in a separate pan until very soft, drain and cut them into 2 cm lengths.',
      ],
      [
        'Đun sôi nước, cho cà rốt thái nhỏ vào nấu 8 phút.',
        'Bring the water to the boil and cook the chopped carrot for 8 minutes.',
      ],
      [
        'Thêm thịt bò băm, đánh tơi, nấu đến khi chín kỹ.',
        'Add the minced beef, break it up and cook until cooked through.',
      ],
      [
        'Cho cải ngọt thái nhỏ vào, đun 2–3 phút đến khi mềm.',
        'Add the chopped choy sum and cook for 2–3 minutes until soft.',
      ],
      [
        'Cho mì vào nồi, đảo đều, thêm dầu ăn. Không nêm muối, hạt nêm hay nước mắm.',
        'Add the noodles, stir and add the oil. No salt, stock powder or fish sauce.',
      ],
      [
        'Bé ăn thìa: múc mì cùng chút nước. Bé tự ăn: vớt mì và rau ra khay để bé bốc.',
        'For spoon feeding, serve the noodles with a little broth. For self-feeding, lift the noodles and vegetables onto the tray to grab.',
      ],
      firstTime('lúa mì', 'wheat'),
    ),
    storage: STORE_COOKED,
    tip: t(
      'Không dùng mì gói cho bé vì gói gia vị và sợi mì rất mặn. Có thể thay mì bằng nui hoặc bánh phở.',
      'Skip instant noodles: the sachet and the noodles are very salty. You can use pasta or flat rice noodles instead.',
    ),
    relatedArticleIds: ['art_allergen_intro', 'art_solids_menu_9_11', 'art_solids_foods_to_avoid'],
    sources: [S.asciaIntroSolids, S.nhs10to12Months, S.nhsFoodsToAvoid, S.nhsStoringReheating],
  }),
  recipe('rcp_banh_chuoi_yen_mach', {
    title: t('Bánh chuối yến mạch áp chảo', 'Banana and oat pancakes'),
    summary: t(
      'Bánh mềm cầm tay chỉ ba nguyên liệu: chuối chín, trứng và yến mạch. Chuối đã đủ ngọt tự nhiên.',
      'Soft finger pancakes from just three ingredients: ripe banana, egg and oats. The banana makes them sweet enough.',
    ),
    ageMonths: { from: 9, to: 37 },
    texture: 'finger',
    methods: ['blw'],
    servings: 3,
    prepMinutes: 5,
    cookMinutes: 10,
    ingredients: [
      ing('fd_banana', ['Chuối chín', 'Ripe banana'], 1, 'piece'),
      ing('fd_egg', ['Trứng gà', 'Egg'], 1, 'piece'),
      ing('fd_oats', ['Yến mạch cán', 'Rolled oats'], 4, 'tbsp', ['xay mịn', 'finely ground']),
      oil(1, 'tsp', ['để chống dính', 'for the pan']),
    ],
    steps: steps(
      ['Nghiền chuối thật nhuyễn.', 'Mash the banana well.'],
      [
        'Đập trứng vào, thêm yến mạch xay, trộn đều thành hỗn hợp sệt. Để 5 phút cho yến mạch ngấm.',
        'Beat in the egg, add the ground oats and mix to a thick batter. Leave it for 5 minutes to soak.',
      ],
      [
        'Làm nóng chảo chống dính trên lửa nhỏ, quét mỏng dầu.',
        'Heat a non-stick pan over low heat and brush it with a little oil.',
      ],
      [
        'Múc từng thìa hỗn hợp, dàn mỏng thành bánh nhỏ. Áp chảo mỗi mặt 2–3 phút đến khi chín kỹ bên trong, không còn ướt.',
        'Drop in spoonfuls and spread them into small thin pancakes. Cook for 2–3 minutes on each side until cooked through, with no wet batter inside.',
      ],
      [
        'Để nguội, cắt bánh thành dải dài cỡ ngón tay, hoặc miếng nhỏ khi bé đã nhặt được bằng hai ngón.',
        'Let them cool and cut them into finger-length strips, or into small pieces once your baby picks up with two fingers.',
      ],
      [
        'Đặt lên khay cho bé tự cầm, ngồi cạnh bé suốt bữa.',
        'Put them on the tray for your baby to hold, and stay close for the whole meal.',
      ],
    ),
    storage: t(
      'Làm nguội, cất hộp kín trong tủ lạnh, dùng trong 2 ngày; có thể trữ đông từng chiếc, lót giấy nến. Hâm lại bằng chảo hoặc nồi hấp cho nóng đều.',
      'Cool and keep in a closed box in the fridge for up to 2 days, or freeze them separately between sheets of baking paper. Reheat in a pan or steamer until hot all through.',
    ),
    tip: t(
      'Món có trứng: chỉ làm khi bé đã ăn trứng ổn. Có thể thêm vài thìa bí đỏ nghiền, hoặc một ít vừng xay mịn nếu bé đã quen vừng.',
      'These contain egg: make them once egg suits your baby. You can add a few spoonfuls of mashed pumpkin, or a little ground sesame once sesame is familiar.',
    ),
    relatedArticleIds: ['art_solids_finger_foods', 'art_allergen_intro', 'art_solids_menu_9_11'],
    sources: [S.nhsChokingGagging, S.nhs10to12Months, S.asciaIntroSolids],
  }),
  recipe('rcp_com_nat_thit_lon_bi_xanh', {
    title: t('Cơm nát với canh thịt lợn bí xanh', 'Soft rice with pork and winter melon soup'),
    summary: t(
      'Bước chuyển từ cháo sang cơm: cơm nấu nát, chan canh bí xanh thịt băm không nêm, như một bữa cơm gia đình thu nhỏ.',
      'The step from congee to rice: very soft rice with an unseasoned winter melon and pork soup, like a small family meal.',
    ),
    ageMonths: { from: 10, to: 18 },
    texture: 'softPieces',
    methods: ['spoon'],
    servings: 2,
    prepMinutes: 15,
    cookMinutes: 35,
    ingredients: [
      ing('fd_rice', ['Gạo tẻ', 'Rice'], 40, 'g', [
        'nấu nát với nhiều nước',
        'cooked soft in plenty of water',
      ]),
      ing('fd_pork', ['Thịt lợn nạc', 'Lean pork'], 50, 'g', ['băm', 'minced']),
      ing('fd_winter_melon', ['Bí xanh', 'Winter melon'], 80, 'g'),
      ing('fd_spring_onion', ['Hành lá', 'Spring onion'], 1, 'piece'),
      water(500),
    ],
    steps: steps(
      [
        'Nấu cơm nát: vo gạo, nấu với lượng nước gấp khoảng 3–4 lần gạo đến khi hạt cơm mềm, nở bung.',
        'Cook soft rice: rinse the rice and cook it in about 3–4 times its volume of water until the grains are soft and burst.',
      ],
      [
        'Thịt lợn băm nhỏ. Bí xanh gọt vỏ, bỏ ruột, thái hạt lựu nhỏ.',
        'Mince the pork. Peel the winter melon, remove the pith and dice it small.',
      ],
      [
        'Đun sôi nước, cho thịt vào, đánh tơi, hớt bọt, nấu 5 phút.',
        'Bring the water to the boil, add the pork, break it up, skim and cook for 5 minutes.',
      ],
      [
        'Cho bí xanh vào, nấu 8–10 phút đến khi bí mềm trong. Rắc hành lá thái nhỏ. Không nêm.',
        'Add the winter melon and cook for 8–10 minutes until soft and translucent. Sprinkle with chopped spring onion. No seasoning.',
      ],
      [
        'Múc cơm nát ra bát, chan canh, dùng thìa dầm nhẹ bí và thịt cho vừa cỡ bé nhai được.',
        'Spoon the rice into a bowl, ladle the soup over and press the melon and pork with a spoon to a size your baby can chew.',
      ],
      [
        'Nếu nấu chung cho cả nhà, múc phần canh của bé ra trước rồi mới nêm phần người lớn.',
        "If it is the family's soup, take your baby's portion out first and season the rest afterwards.",
      ],
    ),
    storage: STORE_RICE,
    tip: t(
      'Cho bé ăn cùng giờ với cả nhà để bé học theo. Đặt thêm vài miếng bí xanh, thịt viên mềm lên khay cho bé tự bốc.',
      'Feed your baby at the family mealtime so they learn by copying. Put a few pieces of melon or soft meatball on the tray to pick up.',
    ),
    relatedArticleIds: [
      'art_solids_textures_by_month',
      'art_solids_family_meals',
      'art_solids_menu_9_11',
    ],
    sources: [S.mohCf2026, S.nhs10to12Months, S.nhsStoringReheating],
  }),
  recipe('rcp_ca_basa_hap_bi_ngoi', {
    title: t('Cá basa hấp với bí ngòi và cà rốt', 'Steamed basa with zucchini and carrot'),
    summary: t(
      'Món hấp nhẹ nhàng cho bé vừa bốc vừa xúc: cá basa miếng to dễ cầm, rau củ cắt que hấp mềm.',
      'A gentle steamed dish for grabbing or spooning: big, easy-to-hold pieces of basa and soft steamed vegetable sticks.',
    ),
    ageMonths: { from: 9, to: 24 },
    texture: 'finger',
    methods: ['blw', 'spoon'],
    servings: 2,
    prepMinutes: 10,
    cookMinutes: 15,
    ingredients: [
      ing('fd_basa', ['Cá basa phi lê', 'Basa fillet'], 80, 'g'),
      ing('fd_zucchini', ['Bí ngòi', 'Zucchini'], 60, 'g'),
      ing('fd_carrot', ['Cà rốt', 'Carrot'], 50, 'g'),
      ing('fd_dill', ['Thì là', 'Dill'], null, null, ['thái nhỏ, tuỳ chọn', 'chopped, optional']),
      ing('fd_olive_oil', ['Dầu ô liu', 'Olive oil'], 1, 'tsp'),
    ],
    steps: steps(
      [
        'Cà rốt và bí ngòi gọt vỏ, cắt que dài cỡ ngón tay.',
        'Peel the carrot and zucchini and cut them into finger-length sticks.',
      ],
      [
        'Hấp cà rốt trước 8 phút, rồi cho bí ngòi và cá vào hấp thêm 7–8 phút đến khi cá chín đục, rau mềm.',
        'Steam the carrot for 8 minutes, then add the zucchini and fish and steam for 7–8 more minutes until the fish is opaque and the vegetables are soft.',
      ],
      [
        'Kiểm tra cá bằng tay, bỏ xương, da và phần mỡ bụng nếu có. Để miếng cá to cỡ hai ngón tay để bé dễ cầm.',
        'Check the fish by hand and remove any bones, skin and belly fat. Leave pieces about two fingers wide so they are easy to hold.',
      ],
      [
        'Rưới chút dầu ô liu, rắc thì là thái nhỏ. Không nêm.',
        'Drizzle with a little olive oil and sprinkle with chopped dill. No seasoning.',
      ],
      [
        'Bé tự ăn: bày cá và que rau lên khay. Bé ăn thìa: dầm cá và rau thành miếng nhỏ, trộn với cơm nát.',
        'For self-feeding, put the fish and sticks on the tray. For spoon feeding, mash them into small pieces and mix with soft rice.',
      ],
      ['Ngồi cạnh bé suốt bữa.', 'Stay with your baby for the whole meal.'],
    ),
    storage: STORE_COOKED,
    tip: t(
      'Cá basa mềm, ít xương dăm, giá dễ chịu; có thể thay bằng cá hồi, cá rô phi, cá tuyết. Nên có cá trong bữa của bé khoảng 1–2 lần mỗi tuần.',
      'Basa is soft, has few fine bones and is affordable; salmon, tilapia or cod work too. Aim to offer fish about once or twice a week.',
    ),
    relatedArticleIds: ['art_solids_finger_foods', 'art_solids_methods', 'art_solids_iron_foods'],
    sources: [S.fdaFish, S.nhsChokingGagging, S.nhs10to12Months, S.nhsStoringReheating],
  }),
  recipe('rcp_dau_phu_sot_ca_chua', {
    title: t('Đậu phụ sốt cà chua thịt băm', 'Tofu in tomato sauce with minced pork'),
    summary: t(
      'Món cơm nhà quen thuộc nấu cho bé: đậu phụ mềm, thịt băm và cà chua chín, không nêm, ăn cùng cơm nát hoặc cháo đặc.',
      'A familiar home dish made for your baby: soft tofu, minced pork and ripe tomato, unseasoned, with soft rice or thick congee.',
    ),
    ageMonths: { from: 9, to: 24 },
    texture: 'softPieces',
    methods: ['spoon', 'blw'],
    servings: 3,
    prepMinutes: 10,
    cookMinutes: 15,
    ingredients: [
      ing('fd_tofu', ['Đậu phụ', 'Tofu'], 100, 'g'),
      ing('fd_pork', ['Thịt lợn nạc', 'Lean pork'], 40, 'g', ['băm', 'minced']),
      ing('fd_tomato', ['Cà chua chín', 'Ripe tomato'], 1, 'piece'),
      ing('fd_spring_onion', ['Hành lá', 'Spring onion'], 1, 'piece'),
      oil(2, 'tsp'),
      water(50),
    ],
    steps: steps(
      [
        'Cà chua chần nước sôi, bóc vỏ, bỏ hạt, băm nhỏ. Đậu phụ cắt hạt lựu cỡ đầu ngón tay.',
        'Blanch, peel, deseed and chop the tomato. Cut the tofu into fingertip-sized cubes.',
      ],
      [
        'Đun nóng dầu, cho cà chua vào đảo đến khi nhừ thành sốt.',
        'Heat the oil and cook the tomato until it breaks down into a sauce.',
      ],
      [
        'Thêm thịt băm, đánh tơi, nấu đến khi chín kỹ.',
        'Add the minced pork, break it up and cook until cooked through.',
      ],
      [
        'Cho đậu phụ và chút nước vào, đun liu riu 5 phút cho đậu ngấm sốt. Không nêm muối, nước mắm, đường.',
        'Add the tofu and the water and simmer gently for 5 minutes so the tofu soaks up the sauce. No salt, fish sauce or sugar.',
      ],
      [
        'Rắc hành lá thái nhỏ, để còn ấm.',
        'Sprinkle with chopped spring onion and let it cool to warm.',
      ],
      [
        'Bé ăn thìa: ăn cùng cơm nát hoặc cháo đặc. Bé tự ăn: vớt vài miếng đậu cho bé bốc.',
        'For spoon feeding, serve with soft rice or thick congee. For self-feeding, lift a few tofu cubes onto the tray.',
      ],
      firstTime('đậu nành', 'soy'),
    ),
    storage: STORE_COOKED,
    tip: t(
      'Cà chua giàu vitamin C giúp hấp thu sắt từ đậu phụ và thịt. Nếu nấu chung cho cả nhà, múc phần của bé ra trước khi nêm.',
      "Tomato's vitamin C helps your baby absorb the iron in the tofu and pork. If it is the family's dish, take your baby's portion out before seasoning.",
    ),
    relatedArticleIds: ['art_solids_iron_foods', 'art_solids_menu_9_11', 'art_solids_family_meals'],
    sources: [S.cdcIron, S.mohCf2026, S.nhs10to12Months, S.nhsStoringReheating],
  }),
  recipe('rcp_banh_mi_vung_bo', {
    title: t('Bánh mì nướng que phết vừng và bơ', 'Toast fingers with sesame paste and avocado'),
    summary: t(
      'Món cầm tay giúp bé làm quen vừng và lúa mì: bánh mì nướng nhẹ cắt que, phết mỏng vừng xay mịn trộn bơ nghiền.',
      'A finger food that introduces sesame and wheat: lightly toasted bread fingers spread thinly with sesame paste and mashed avocado.',
    ),
    ageMonths: { from: 9, to: 24 },
    texture: 'finger',
    methods: ['blw'],
    servings: 1,
    prepMinutes: 5,
    cookMinutes: 3,
    ingredients: [
      ing('fd_bread', ['Bánh mì gối', 'Sandwich bread'], 1, 'piece', [
        'một lát, loại ít muối',
        'one slice, lower-salt',
      ]),
      ing('fd_sesame_paste', ['Vừng xay mịn', 'Sesame paste'], 1, 'tsp'),
      ing('fd_avocado', ['Quả bơ chín', 'Ripe avocado'], 30, 'g'),
    ],
    steps: steps(
      [
        'Nướng nhẹ lát bánh mì đến khi se mặt, không giòn cứng; cắt bỏ phần viền cứng.',
        'Toast the bread lightly until just dry on the surface, not hard; cut off any hard crust.',
      ],
      ['Cắt bánh thành que dài cỡ ngón tay.', 'Cut it into finger-length strips.'],
      [
        'Nghiền bơ chín, trộn với vừng xay mịn; nếu vừng đặc, pha thêm vài giọt nước ấm.',
        'Mash the avocado with the sesame paste, loosening it with a few drops of warm water if thick.',
      ],
      [
        'Phết thật mỏng hỗn hợp lên que bánh; không phết lớp dày dính.',
        'Spread it very thinly over the fingers; never a thick, sticky layer.',
      ],
      firstTime('vừng', 'sesame'),
      [
        'Đặt 2–3 que lên khay, ngồi cạnh bé suốt bữa.',
        'Put 2–3 fingers on the tray and stay close for the whole meal.',
      ],
    ),
    storage: t(
      'Làm đến đâu ăn đến đó; bơ nghiền để lâu bị thâm. Bánh mì chưa nướng có thể trữ đông từng lát.',
      'Make it just before eating; mashed avocado browns. Untoasted bread can be frozen slice by slice.',
    ),
    tip: t(
      'Ruột bánh mì mềm dễ vón trong miệng, nên nướng nhẹ cho se mặt. Khi bé đã quen, có thể thay vừng bằng bơ đậu phộng mịn hoặc bơ hạt điều mịn.',
      'Soft bread can form a doughy lump, so toast it lightly. Once your baby is used to it, swap the sesame for smooth peanut or cashew butter.',
    ),
    relatedArticleIds: [
      'art_allergen_intro',
      'art_solids_finger_foods',
      'art_solids_choking_safety',
    ],
    sources: [S.asciaIntroSolids, S.nhsChokingGagging, S.bsaciParents, S.nhs10to12Months],
  }),
  recipe('rcp_cha_ga_rau_cu_hap', {
    title: t('Chả gà rau củ hấp', 'Steamed chicken and vegetable patties'),
    summary: t(
      'Chả gà hấp mềm như chả mẹ làm, không nêm, thêm cà rốt và rau ngót: dễ cầm, dễ nhai, tiện mang theo.',
      'Soft steamed chicken loaf like a homemade cha, unseasoned, with carrot and katuk: easy to hold, easy to chew, easy to take along.',
    ),
    ageMonths: { from: 9, to: 24 },
    texture: 'finger',
    methods: ['blw', 'spoon'],
    servings: 4,
    prepMinutes: 20,
    cookMinutes: 20,
    ingredients: [
      ing('fd_chicken', ['Thịt gà xay, phần đùi', 'Minced chicken thigh'], 150, 'g'),
      ing('fd_carrot', ['Cà rốt', 'Carrot'], 40, 'g', ['nạo nhỏ', 'finely grated']),
      ing('fd_katuk', ['Rau ngót', 'Katuk'], 15, 'g', ['băm nhỏ', 'finely chopped']),
      ing('fd_egg', ['Trứng gà', 'Egg'], 1, 'piece', [
        'khi bé đã ăn trứng ổn',
        'once egg suits your baby',
      ]),
      oil(1, 'tsp', ['phết khuôn', 'for the dish']),
    ],
    steps: steps(
      [
        'Cà rốt gọt vỏ, nạo nhỏ; rau ngót rửa sạch, băm nhỏ.',
        'Peel and finely grate the carrot; wash and finely chop the katuk.',
      ],
      [
        'Trộn thịt gà xay, cà rốt, rau ngót và trứng đến khi quyện. Không nêm.',
        'Mix the chicken, carrot, katuk and egg until well combined. No seasoning.',
      ],
      [
        'Phết mỏng dầu vào đĩa hoặc khuôn, dàn hỗn hợp dày khoảng 2 cm.',
        'Oil a heatproof dish lightly and spread the mixture about 2 cm thick.',
      ],
      [
        'Hấp 20 phút đến khi chả chín kỹ, ấn vào thấy chắc và nước chảy ra trong.',
        'Steam for 20 minutes until cooked through: firm to the touch, with clear juices.',
      ],
      [
        'Để nguội, cắt thành que dài cỡ ngón tay hoặc miếng nhỏ cỡ đầu ngón tay.',
        'Let it cool and cut into finger-length sticks or fingertip-sized pieces.',
      ],
      [
        'Bé tự ăn: bày lên khay. Bé ăn thìa: dầm chả vào cháo đặc hoặc cơm nát.',
        'For self-feeding, put it on the tray. For spoon feeding, mash it into thick congee or soft rice.',
      ],
    ),
    storage: STORE_COOKED,
    tip: t(
      'Có thể thay thịt gà bằng thịt lợn nạc hoặc cá basa xay. Chả nguội vẫn mềm nên tiện mang theo khi ra ngoài, giữ trong túi giữ lạnh.',
      'Swap the chicken for lean pork or minced basa. It stays soft when cold, so it travels well in a cool bag.',
    ),
    relatedArticleIds: [
      'art_solids_finger_foods',
      'art_solids_menu_9_11',
      'art_solids_prep_storage',
    ],
    sources: [S.nhsChokingGagging, S.nhs10to12Months, S.cdcIron, S.nhsStoringReheating],
  }),
  recipe('rcp_yen_mach_le_hat_dieu', {
    title: t('Yến mạch nấu sữa, lê hấp và bơ hạt điều', 'Oat porridge with pear and cashew butter'),
    summary: t(
      'Bữa sáng ấm áp giúp bé làm quen hạt cây: yến mạch nấu với sữa, lê hấp nghiền và bơ hạt điều mịn pha loãng.',
      'A warm breakfast that introduces tree nuts: oats cooked in milk, steamed mashed pear and thinned smooth cashew butter.',
    ),
    ageMonths: { from: 9, to: 24 },
    texture: 'mashed',
    methods: ['spoon'],
    servings: 2,
    prepMinutes: 5,
    cookMinutes: 10,
    ingredients: [
      ing('fd_oats', ['Yến mạch cán', 'Rolled oats'], 30, 'g'),
      ing('fd_cow_milk_cooking', ['Sữa tươi nguyên kem', 'Full-fat milk'], 150, 'ml', [
        'hoặc sữa mẹ, sữa công thức',
        'or breast milk or formula',
      ]),
      ing('fd_pear', ['Lê', 'Pear'], 0.5, 'piece'),
      ing('fd_cashew_butter', ['Bơ hạt điều mịn', 'Cashew butter'], 1, 'tsp'),
      water(100),
    ],
    steps: steps(
      [
        'Lê gọt vỏ, bỏ lõi, cắt nhỏ, hấp 8 phút đến khi mềm rồi nghiền thô.',
        'Peel, core and chop the pear, steam it for 8 minutes until soft and mash it roughly.',
      ],
      [
        'Nấu yến mạch với nước và sữa trên lửa nhỏ, khuấy đều 5–7 phút đến khi sánh mềm.',
        'Cook the oats with the water and milk over low heat, stirring, for 5–7 minutes until soft and creamy.',
      ],
      [
        'Pha bơ hạt điều với một thìa yến mạch nóng cho tan loãng, rồi trộn đều vào nồi.',
        'Loosen the cashew butter with a spoonful of the hot porridge, then stir it through the pan.',
      ],
      [
        'Múc ra bát, cho lê nghiền lên trên; lê đã đủ ngọt.',
        'Spoon into a bowl and top with the mashed pear, which is sweet enough.',
      ],
      firstTime('hạt điều', 'cashew'),
      [
        'Không bao giờ cho bé hạt điều nguyên hoặc giã thô. Để còn ấm rồi cho bé ăn.',
        'Never give whole or roughly crushed cashews. Serve warm.',
      ],
    ),
    storage: t(
      'Nên ăn ngay khi vừa nấu. Phần chưa dùng làm nguội, cất tủ lạnh trong vòng 1–2 giờ, dùng trong 2 ngày; hâm lại một lần, pha thêm chút nước cho mềm.',
      'Best eaten freshly cooked. Cool and refrigerate any untouched porridge within 1–2 hours and use within 2 days; reheat once, loosening it with a little water.',
    ),
    tip: t(
      'Trước 12 tháng chưa dùng sữa tươi làm đồ uống, nhưng nấu trong món ăn như thế này thì được. Có thể thay hạt điều bằng bơ hạnh nhân mịn để bé làm quen thêm loại hạt khác.',
      "Before 12 months cow's milk is not a drink, but cooking with it like this is fine. Swap the cashew for smooth almond butter to introduce another tree nut.",
    ),
    relatedArticleIds: ['art_allergen_intro', 'art_solids_foods_to_avoid', 'art_solids_menu_9_11'],
    sources: [S.asciaIntroSolids, S.bsaciParents, S.nhsFoodsToAvoid, S.nhsDrinksCups],
  }),
  // ----- 12–23 months: family food, cut small, the child's portion taken out before seasoning -----
  recipe('rcp_pho_bo_cho_be', {
    title: t('Phở bò cho bé', 'Beef pho for little ones'),
    summary: t(
      'Bát phở của gia đình làm nhỏ lại cho bé: nước dùng xương hầm không nêm, bánh phở cắt ngắn, thịt bò chín kỹ thái mỏng.',
      "The family's pho made small: unseasoned bone broth, noodles cut short and well-cooked beef sliced thin.",
    ),
    ageMonths: { from: 12, to: 37 },
    texture: 'family',
    methods: ['spoon', 'blw'],
    servings: 2,
    prepMinutes: 15,
    cookMinutes: 90,
    ingredients: [
      ing(null, ['Xương bò', 'Beef bones'], 300, 'g', ['để hầm nước dùng', 'for the broth']),
      ing('fd_pho_noodles', ['Bánh phở', 'Flat rice noodles'], 60, 'g'),
      ing('fd_beef', ['Thịt bò thăn', 'Beef sirloin'], 50, 'g'),
      ing('fd_onion', ['Hành tây', 'Onion'], 0.5, 'piece'),
      ing('fd_spring_onion', ['Hành lá', 'Spring onion'], 1, 'piece'),
      ing(null, ['Gừng nướng', 'Charred ginger'], 1, 'piece', [
        'một lát, vớt bỏ',
        'one slice, removed',
      ]),
      water(1500),
    ],
    steps: steps(
      [
        'Chần xương bò qua nước sôi, rửa sạch. Hầm xương với nước, hành tây và gừng nướng trên lửa nhỏ khoảng 90 phút, hớt bọt thường xuyên.',
        'Blanch the bones in boiling water and rinse. Simmer them gently with the water, onion and charred ginger for about 90 minutes, skimming often.',
      ],
      [
        'Lọc nước dùng. Múc phần của bé ra trước; phần người lớn nêm sau.',
        "Strain the broth. Take your child's portion out first; season the adults' broth afterwards.",
      ],
      [
        'Luộc thịt bò trong nước dùng đến khi chín kỹ, không dùng thịt tái; vớt ra thái thật mỏng ngang thớ rồi cắt nhỏ.',
        'Cook the beef in the broth until well done, never rare; slice it very thinly across the grain, then chop it.',
      ],
      [
        'Trần bánh phở qua nước sôi cho mềm, cắt ngắn khoảng 3–4 cm.',
        'Blanch the noodles until soft and cut them into 3–4 cm lengths.',
      ],
      [
        'Cho bánh phở và thịt bò vào bát, chan nước dùng, rắc hành lá thái nhỏ.',
        'Put the noodles and beef in a bowl, ladle the broth over and sprinkle with chopped spring onion.',
      ],
      [
        'Để nguội bớt, cho bé tự xúc hoặc bốc bánh phở và thịt; người lớn hỗ trợ khi cần.',
        'Let it cool a little and let your child spoon or pick up the noodles and beef, helping when needed.',
      ],
    ),
    storage: t(
      'Nước dùng không nêm làm nguội nhanh, cất tủ lạnh dùng trong 2 ngày hoặc trữ đông từng phần; hâm sôi kỹ một lần. Bánh phở và thịt nên làm mới mỗi bữa.',
      'Cool unseasoned broth quickly and refrigerate it for up to 2 days, or freeze it in portions; bring it to a full boil once to reheat. Make the noodles and beef fresh each meal.',
    ),
    tip: t(
      'Phở hàng quán thường mặn và hay dùng thịt tái; nấu ở nhà giúp bé ăn cùng cả nhà mà không quá mặn. Không cho bé ớt, tương ớt.',
      'Restaurant pho is usually salty and often uses rare beef; cooking at home lets your child share the meal without the salt. No chilli or chilli sauce for children.',
    ),
    relatedArticleIds: [
      'art_solids_family_meals',
      'art_picky_eating_toddler',
      'art_solids_foods_to_avoid',
    ],
    sources: [S.unicef1to2, S.nhsYoungChildren, S.hcOneYearOld, S.nhsStoringReheating],
  }),
  recipe('rcp_bun_ca_ro_phi', {
    title: t('Bún cá rô phi cà chua thì là', 'Rice noodle soup with tilapia, tomato and dill'),
    summary: t(
      'Bún cá kiểu Hà Nội làm nhẹ cho bé: cá rô phi áp chảo gỡ kỹ xương, nước dùng cà chua, thì là thơm, bún cắt ngắn.',
      'A light Hanoi-style fish noodle soup for children: pan-seared tilapia carefully boned, tomato broth, fragrant dill and short noodles.',
    ),
    ageMonths: { from: 12, to: 37 },
    texture: 'family',
    methods: ['spoon', 'blw'],
    servings: 2,
    prepMinutes: 15,
    cookMinutes: 25,
    ingredients: [
      ing('fd_rice_vermicelli', ['Bún tươi', 'Fresh rice vermicelli'], 60, 'g'),
      ing('fd_tilapia', ['Cá rô phi phi lê', 'Tilapia fillet'], 80, 'g'),
      ing('fd_tomato', ['Cà chua', 'Tomato'], 1, 'piece'),
      ing('fd_dill', ['Thì là', 'Dill'], null, null, ['vài nhánh', 'a few sprigs']),
      ing('fd_spring_onion', ['Hành lá', 'Spring onion'], 1, 'piece'),
      oil(2, 'tsp'),
      water(400),
    ],
    steps: steps(
      [
        'Cá rửa sạch, thấm khô, áp chảo với chút dầu đến khi chín vàng hai mặt; gỡ thịt cá, bỏ hết xương.',
        'Rinse and pat the fish dry, pan-sear it in a little oil until golden and cooked on both sides, then flake it and remove every bone.',
      ],
      [
        'Cà chua thái múi cau nhỏ, xào với dầu đến khi mềm, đổ nước vào đun sôi 5 phút.',
        'Cut the tomato into small wedges, cook it in oil until soft, add the water and boil for 5 minutes.',
      ],
      [
        'Cho cá vào nồi, đun sôi lại, thả thì là và hành lá thái nhỏ. Phần của bé không nêm.',
        "Add the fish, bring back to the boil and add the chopped dill and spring onion. Your child's portion stays unseasoned.",
      ],
      [
        'Trần bún qua nước sôi, cắt ngắn 3–4 cm.',
        'Blanch the noodles and cut them into 3–4 cm lengths.',
      ],
      [
        'Cho bún vào bát, múc cá, cà chua và nước dùng lên trên.',
        'Put the noodles in a bowl and top with the fish, tomato and broth.',
      ],
      [
        'Nếu nấu cho cả nhà, múc phần của bé ra trước rồi mới nêm phần người lớn.',
        "If cooking for the family, take your child's portion out first and season the rest afterwards.",
      ],
    ),
    storage: t(
      'Nên ăn trong bữa. Nước dùng và cá chưa ăn đến làm nguội, cất tủ lạnh trong vòng 1 giờ, dùng trong 24 giờ; bún để riêng, trần lại khi ăn.',
      'Best eaten at the meal. Cool any untouched broth and fish, refrigerate within 1 hour and use within 24 hours; keep the noodles separate and blanch them again to serve.',
    ),
    tip: t(
      'Gỡ cá trên đĩa sáng màu để dễ thấy xương. Có thể thay cá rô phi bằng cá basa hay cá lóc.',
      'Flake the fish on a light-coloured plate so bones are easy to see. Basa or snakehead work too.',
    ),
    relatedArticleIds: [
      'art_solids_family_meals',
      'art_solids_choking_safety',
      'art_picky_eating_toddler',
    ],
    sources: [S.unicef1to2, S.fdaFish, S.nhsYoungChildren, S.nhsStoringReheating],
  }),
  recipe('rcp_com_canh_bi_do_tom', {
    title: t('Cơm mềm với canh bí đỏ nấu tôm', 'Soft rice with pumpkin and shrimp soup'),
    summary: t(
      'Bữa cơm gia đình đơn giản cho bé từ 1 tuổi: cơm nấu mềm, canh bí đỏ tôm băm, thêm rau luộc cắt nhỏ.',
      'A simple family meal from 1 year: soft rice, pumpkin soup with minced shrimp and chopped boiled greens.',
    ),
    ageMonths: { from: 12, to: 37 },
    texture: 'family',
    methods: ['spoon', 'blw'],
    servings: 3,
    prepMinutes: 15,
    cookMinutes: 30,
    ingredients: [
      ing('fd_rice', ['Gạo tẻ', 'Rice'], 50, 'g'),
      ing('fd_shrimp', ['Tôm', 'Shrimp'], 60, 'g', ['bóc vỏ, bỏ chỉ đen', 'peeled and deveined']),
      ing('fd_pumpkin', ['Bí đỏ', 'Pumpkin'], 100, 'g'),
      ing('fd_choy_sum', ['Cải ngọt', 'Choy sum'], 40, 'g'),
      ing('fd_spring_onion', ['Hành lá', 'Spring onion'], 1, 'piece'),
      oil(1, 'tsp'),
      water(500),
    ],
    steps: steps(
      [
        'Nấu cơm mềm hơn cơm người lớn một chút bằng cách thêm nước.',
        "Cook the rice a little softer than adults' rice by adding more water.",
      ],
      [
        'Tôm băm nhỏ, xào sơ với chút dầu cho thơm.',
        'Mince the shrimp and stir-fry it briefly in a little oil.',
      ],
      [
        'Đun sôi nước, cho bí đỏ cắt miếng nhỏ vào nấu 10 phút đến khi mềm.',
        'Bring the water to the boil and cook the pumpkin, cut small, for 10 minutes until soft.',
      ],
      [
        'Cho tôm vào, đun thêm 3 phút đến khi chín kỹ; rắc hành lá. Múc phần của bé ra trước khi nêm.',
        "Add the shrimp and cook for 3 more minutes until cooked through; sprinkle with spring onion. Take your child's portion out before seasoning.",
      ],
      ['Luộc cải ngọt, thái nhỏ.', 'Boil the choy sum and chop it small.'],
      [
        'Xới cơm, chan canh, dầm nhẹ bí đỏ; đặt rau và vài miếng bí lên khay cho bé tự bốc.',
        'Serve the rice with the soup, pressing the pumpkin lightly; put greens and a few pumpkin pieces on the tray to pick up.',
      ],
    ),
    storage: STORE_RICE,
    tip: t(
      'Từ 12 tháng bé có thể ăn cùng mâm với gia đình: ghế ăn ngang bàn, cùng giờ, cùng món, chỉ khác là phần của bé không nêm và cắt nhỏ hơn.',
      'From 12 months your child can share the family meal: high chair at the table, same time, same food, just unseasoned and cut smaller.',
    ),
    relatedArticleIds: [
      'art_solids_family_meals',
      'art_picky_eating_toddler',
      'art_solids_textures_by_month',
    ],
    sources: [S.unicef1to2, S.nhsYoungChildren, S.mohCf2026, S.nhsStoringReheating],
  }),
  recipe('rcp_banh_ca_hoi_khoai_tay', {
    title: t('Bánh cá hồi khoai tây áp chảo', 'Salmon and potato cakes'),
    summary: t(
      'Bánh mềm cầm tay từ cá hồi, khoai tây và hành lá, áp chảo ít dầu: bữa phụ giàu đạm cho cả bé và người lớn.',
      'Soft finger cakes of salmon, potato and spring onion, pan-fried in a little oil: a protein-rich snack for children and adults alike.',
    ),
    ageMonths: { from: 12, to: 37 },
    texture: 'finger',
    methods: ['blw'],
    servings: 4,
    prepMinutes: 15,
    cookMinutes: 25,
    ingredients: [
      ing('fd_salmon', ['Cá hồi', 'Salmon'], 100, 'g'),
      ing('fd_potato', ['Khoai tây', 'Potato'], 150, 'g'),
      ing('fd_egg', ['Trứng gà', 'Egg'], 1, 'piece'),
      ing('fd_spring_onion', ['Hành lá', 'Spring onion'], 1, 'piece'),
      ing('fd_wheat_flour', ['Bột mì', 'Wheat flour'], 2, 'tbsp', ['để áo bánh', 'for coating']),
      oil(1, 'tbsp'),
    ],
    steps: steps(
      ['Khoai tây gọt vỏ, hấp chín, nghiền nhuyễn.', 'Peel, steam and mash the potato.'],
      [
        'Hấp cá hồi 10 phút, gỡ bỏ da và xương, dầm nhỏ.',
        'Steam the salmon for 10 minutes, remove the skin and bones and flake it.',
      ],
      [
        'Trộn khoai, cá, trứng và hành lá thái nhỏ. Không nêm.',
        'Mix the potato, salmon, egg and chopped spring onion. No seasoning.',
      ],
      [
        'Nặn bánh dẹt cỡ lòng bàn tay bé, lăn nhẹ qua bột mì.',
        "Shape flat cakes the size of your child's palm and dust them with flour.",
      ],
      [
        'Áp chảo chống dính với ít dầu, lửa vừa, mỗi mặt 3–4 phút đến khi vàng và chín kỹ.',
        'Pan-fry in a non-stick pan with a little oil over medium heat for 3–4 minutes on each side until golden and cooked through.',
      ],
      [
        'Để nguội, cắt đôi hoặc thành dải cho bé cầm.',
        'Let them cool and cut them in half or into strips to hold.',
      ],
    ),
    storage: STORE_COOKED,
    tip: t(
      'Có thể thay cá hồi bằng cá basa, cá rô phi; thay khoai tây bằng khoai lang. Ăn kèm rau luộc và vài miếng cà chua cắt nhỏ.',
      'Swap the salmon for basa or tilapia and the potato for sweet potato. Serve with boiled greens and some chopped tomato.',
    ),
    relatedArticleIds: [
      'art_solids_finger_foods',
      'art_solids_family_meals',
      'art_solids_iron_foods',
    ],
    sources: [S.fdaFish, S.nhsYoungChildren, S.nhsChokingGagging, S.nhsStoringReheating],
  }),
  recipe('rcp_trung_hap_thit', {
    title: t('Trứng hấp thịt băm', 'Steamed egg with minced pork'),
    summary: t(
      'Món chả trứng hấp quen thuộc của mâm cơm Việt, nấu mềm, không nêm cho bé: trứng, thịt băm, nấm, cà rốt và hành lá.',
      'The steamed egg and pork loaf of many Vietnamese family meals, soft and unseasoned for children: egg, minced pork, mushroom, carrot and spring onion.',
    ),
    ageMonths: { from: 12, to: 37 },
    texture: 'family',
    methods: ['spoon', 'blw'],
    servings: 3,
    prepMinutes: 10,
    cookMinutes: 25,
    ingredients: [
      ing('fd_egg', ['Trứng gà', 'Eggs'], 2, 'piece'),
      ing('fd_pork', ['Thịt lợn nạc', 'Lean pork'], 60, 'g', ['băm', 'minced']),
      ing('fd_mushroom', ['Nấm hương', 'Shiitake'], 2, 'piece', [
        'ngâm mềm, băm thật nhỏ',
        'soaked and very finely chopped',
      ]),
      ing('fd_carrot', ['Cà rốt', 'Carrot'], 30, 'g', ['nạo nhỏ', 'finely grated']),
      ing('fd_spring_onion', ['Hành lá', 'Spring onion'], 1, 'piece'),
      oil(1, 'tsp', ['phết bát', 'for the bowl']),
    ],
    steps: steps(
      [
        'Nấm ngâm mềm, băm thật nhỏ; cà rốt nạo nhỏ; hành lá thái nhỏ.',
        'Soak and finely chop the mushrooms; grate the carrot; chop the spring onion.',
      ],
      [
        'Đánh tan trứng, trộn với thịt băm, nấm, cà rốt và hành lá. Không nêm.',
        'Beat the eggs and mix in the pork, mushroom, carrot and spring onion. No seasoning.',
      ],
      [
        'Đổ vào bát chịu nhiệt đã phết dầu, hấp lửa vừa 20–25 phút đến khi chín kỹ, mặt chả chắc, cắm đũa không còn nước đục.',
        'Pour into an oiled heatproof bowl and steam over medium heat for 20–25 minutes until fully set, with no cloudy liquid when pierced with a chopstick.',
      ],
      [
        'Để nguội bớt, cắt miếng vuông nhỏ hoặc dải dài.',
        'Let it cool a little and cut it into small squares or long strips.',
      ],
      [
        'Ăn cùng cơm mềm và canh rau. Người lớn ăn kèm nước chấm riêng; phần của bé để nguyên vị.',
        "Serve with soft rice and a vegetable soup. Adults can add their own dipping sauce; your child's portion stays plain.",
      ],
    ),
    storage: STORE_COOKED,
    tip: t(
      'Món này có cả trứng và thịt nên bữa đó chỉ cần thêm canh rau và cơm. Có thể thay nấm bằng mồng tơi băm nhỏ.',
      'With both egg and pork, this dish only needs rice and a vegetable soup alongside. You can use chopped Malabar spinach instead of mushroom.',
    ),
    relatedArticleIds: [
      'art_solids_family_meals',
      'art_solids_iron_foods',
      'art_picky_eating_toddler',
    ],
    sources: [S.unicef1to2, S.nhsYoungChildren, S.cdcIron, S.nhsStoringReheating],
  }),
  recipe('rcp_nui_pho_mai_bong_cai', {
    title: t('Nui sốt phô mai bông cải xanh', 'Pasta with cheese sauce and broccoli'),
    summary: t(
      'Nui mềm trong sốt sữa và phô mai với bông cải xanh; phần của bé không nêm vì phô mai đã có vị mặn nhẹ.',
      "Soft pasta in a milk and cheese sauce with broccoli; your child's portion needs no seasoning because the cheese is already slightly salty.",
    ),
    ageMonths: { from: 12, to: 37 },
    texture: 'family',
    methods: ['spoon', 'blw'],
    servings: 3,
    prepMinutes: 10,
    cookMinutes: 20,
    ingredients: [
      ing('fd_pasta', ['Nui', 'Pasta'], 60, 'g'),
      ing('fd_broccoli', ['Bông cải xanh', 'Broccoli'], 60, 'g'),
      ing('fd_cow_milk_cooking', ['Sữa tươi nguyên kem', 'Full-fat milk'], 120, 'ml'),
      ing('fd_cheese', ['Phô mai cheddar hoặc mozzarella', 'Cheddar or mozzarella'], 25, 'g', [
        'bào sợi',
        'grated',
      ]),
      ing('fd_butter', ['Bơ lạt', 'Unsalted butter'], 1, 'tsp'),
      ing('fd_wheat_flour', ['Bột mì', 'Wheat flour'], 1, 'tsp'),
    ],
    steps: steps(
      [
        'Luộc nui mềm hơn bình thường một chút; bông cải tách nhỏ, luộc hoặc hấp mềm, thái nhỏ.',
        'Boil the pasta a little softer than usual; break the broccoli into small florets, boil or steam until soft and chop.',
      ],
      [
        'Đun chảy bơ lạt trên lửa nhỏ, cho bột mì vào khuấy 1 phút.',
        'Melt the butter over low heat, stir in the flour and cook for 1 minute.',
      ],
      [
        'Đổ sữa từ từ, khuấy liên tục đến khi sánh nhẹ.',
        'Pour in the milk slowly, stirring all the time, until lightly thickened.',
      ],
      [
        'Tắt bếp, cho phô mai bào vào khuấy tan. Không nêm vì phô mai đã có vị mặn nhẹ.',
        'Turn off the heat and stir in the cheese until melted. No seasoning: the cheese is already slightly salty.',
      ],
      [
        'Trộn nui và bông cải với sốt. Để nguội bớt; bé có thể tự bốc nui hoặc xúc bằng thìa.',
        'Toss the pasta and broccoli in the sauce. Let it cool a little; your child can pick up the pasta or use a spoon.',
      ],
    ),
    storage: STORE_COOKED,
    tip: t(
      'Chọn phô mai thanh trùng, ít muối; tránh phô mai mềm có mốc. Có thể thêm cá hồi hoặc thịt gà xé để bữa có thêm đạm.',
      'Choose a pasteurized, lower-salt cheese and avoid mould-ripened soft cheese. Add flaked salmon or shredded chicken for more protein.',
    ),
    relatedArticleIds: ['art_solids_family_meals', 'art_toddler_milk', 'art_picky_eating_toddler'],
    sources: [S.unicef1to2, S.nhsYoungChildren, S.nhsFoodsToAvoid, S.nhsStoringReheating],
  }),
  recipe('rcp_com_nam_ga_rau_cu', {
    title: t('Cơm nắm gà rau củ', 'Chicken and vegetable rice balls'),
    summary: t(
      'Cơm nắm nhỏ mềm trộn thịt gà xé và rau củ thái hạt lựu: dễ cầm, tiện mang đi chơi hay đi nhà trẻ.',
      'Small soft rice balls with shredded chicken and diced vegetables: easy to hold and handy for outings or nursery.',
    ),
    ageMonths: { from: 12, to: 37 },
    texture: 'finger',
    methods: ['blw'],
    servings: 3,
    prepMinutes: 15,
    cookMinutes: 30,
    ingredients: [
      ing('fd_rice', ['Gạo tẻ', 'Rice'], 60, 'g', ['nấu mềm, dẻo', 'cooked soft and sticky']),
      ing('fd_chicken', ['Thịt gà', 'Chicken'], 60, 'g'),
      ing('fd_carrot', ['Cà rốt', 'Carrot'], 30, 'g'),
      ing('fd_peas', ['Đậu Hà Lan', 'Green peas'], 20, 'g', ['dầm dập', 'crushed']),
      ing('fd_sesame_paste', ['Vừng rang xay', 'Ground toasted sesame'], 1, 'tsp', [
        'lăn bên ngoài, tuỳ chọn',
        'for rolling, optional',
      ]),
    ],
    steps: steps(
      [
        'Nấu cơm mềm, dẻo hơn bình thường; để còn ấm.',
        'Cook the rice softer and stickier than usual and keep it warm.',
      ],
      [
        'Thịt gà luộc chín kỹ, xé nhỏ rồi băm sơ.',
        'Boil the chicken until cooked through, shred it and chop it roughly.',
      ],
      [
        'Cà rốt thái hạt lựu nhỏ, luộc cùng đậu Hà Lan đến khi mềm; dầm dập đậu Hà Lan.',
        'Dice the carrot small and boil it with the peas until soft; crush the peas.',
      ],
      [
        'Trộn cơm với gà và rau củ. Không nêm.',
        'Mix the rice with the chicken and vegetables. No seasoning.',
      ],
      [
        'Rửa tay sạch, nắm thành viên nhỏ cỡ quả bóng bàn, nén vừa chặt để không vỡ.',
        'With clean hands, press into small balls the size of a ping-pong ball, firm enough to hold together.',
      ],
      [
        'Lăn qua vừng xay nếu thích. Cho bé ngồi ăn, không vừa đi vừa ăn.',
        'Roll in ground sesame if you like. Your child eats sitting down, never while walking about.',
      ],
    ),
    storage: t(
      'Làm nguội nhanh, cất tủ lạnh trong vòng 1 giờ, dùng trong 24 giờ. Mang đi chơi: để trong hộp kín với túi giữ lạnh và ăn trong vòng 4 giờ.',
      'Cool quickly, refrigerate within 1 hour and use within 24 hours. For outings, pack them in a closed box with a cool bag and eat within 4 hours.',
    ),
    tip: t(
      'Dùng gạo tẻ, không dùng gạo nếp vì xôi dẻo dính dễ gây hóc. Có thể thay gà bằng cá hồi hoặc thịt bò băm.',
      'Use ordinary rice, not glutinous rice, which clumps and can choke. Swap the chicken for salmon or minced beef.',
    ),
    relatedArticleIds: [
      'art_solids_finger_foods',
      'art_solids_choking_safety',
      'art_solids_prep_storage',
    ],
    sources: [S.nhsChokingGagging, S.unicef1to2, S.nhsStoringReheating, S.cdcChokingHazards],
  }),
  recipe('rcp_sup_ga_ngo', {
    title: t('Súp gà ngô ngọt', 'Chicken and sweet corn soup'),
    summary: t(
      'Súp gà ngô quen thuộc làm cho bé: gà xé, ngô xay dập, cà rốt và trứng, sánh nhẹ, không nêm phần của bé.',
      "The familiar chicken and corn soup made for children: shredded chicken, crushed corn, carrot and egg, lightly thickened, your child's portion unseasoned.",
    ),
    ageMonths: { from: 12, to: 37 },
    texture: 'family',
    methods: ['spoon'],
    servings: 3,
    prepMinutes: 15,
    cookMinutes: 30,
    ingredients: [
      ing('fd_chicken', ['Thịt gà', 'Chicken'], 80, 'g'),
      ing('fd_corn', ['Ngô ngọt', 'Sweet corn'], 0.5, 'piece', [
        'nửa bắp, tách hạt',
        'half a cob, kernels cut off',
      ]),
      ing('fd_carrot', ['Cà rốt', 'Carrot'], 30, 'g'),
      ing('fd_egg', ['Trứng gà', 'Egg'], 1, 'piece'),
      ing('fd_spring_onion', ['Hành lá', 'Spring onion'], 1, 'piece'),
      ing(null, ['Bột năng', 'Tapioca starch'], 1, 'tsp', [
        'hoà với nước lạnh',
        'mixed with cold water',
      ]),
      water(600),
    ],
    steps: steps(
      [
        'Luộc gà đến khi chín kỹ, vớt ra xé sợi nhỏ; giữ lại nước luộc.',
        'Boil the chicken until cooked through, shred it finely and keep the cooking water.',
      ],
      [
        'Xay dập hạt ngô với chút nước luộc gà để vỡ vỏ hạt; cà rốt thái hạt lựu nhỏ.',
        'Pulse the corn kernels with a little of the broth to break the skins; dice the carrot small.',
      ],
      [
        'Cho ngô, cà rốt vào nồi nước luộc gà, nấu 10 phút đến khi mềm.',
        'Cook the corn and carrot in the broth for 10 minutes until soft.',
      ],
      [
        'Cho gà xé vào, đổ bột năng đã hoà vào từ từ, khuấy đều đến khi súp sánh.',
        'Add the chicken, then stir in the starch mixture slowly until the soup thickens.',
      ],
      [
        'Đánh tan trứng, rót thành dòng nhỏ vào nồi đang sôi, khuấy nhẹ, đun thêm 1–2 phút để trứng chín kỹ.',
        'Beat the egg and pour it in a thin stream into the boiling soup, stirring gently; cook for 1–2 more minutes so the egg is fully cooked.',
      ],
      [
        'Rắc hành lá. Múc phần của bé ra trước, để nguội bớt; phần người lớn nêm sau.',
        "Sprinkle with spring onion. Take your child's portion out and let it cool a little; season the adults' soup afterwards.",
      ],
    ),
    storage: STORE_COOKED,
    tip: t(
      'Hạt ngô nguyên có vỏ dai: với bé còn hay oẹ, xay dập kỹ hơn hoặc lọc bớt vỏ. Có thể thay ngô bằng bí đỏ hoặc nấm thái nhỏ.',
      'Whole corn kernels have tough skins: if your child still gags often, crush them more or sieve out some skins. Pumpkin or chopped mushroom can replace the corn.',
    ),
    relatedArticleIds: [
      'art_solids_family_meals',
      'art_solids_sick_teething',
      'art_solids_choking_safety',
    ],
    sources: [S.unicef1to2, S.nhsYoungChildren, S.nhsChokingGagging, S.nhsStoringReheating],
  }),
  recipe('rcp_bo_xao_rau_cu', {
    title: t('Thịt bò xào rau củ thái hạt lựu', 'Stir-fried beef with diced vegetables'),
    summary: t(
      'Món xào nhanh cho bữa cơm chung: thịt bò thái nhỏ mềm, bí ngòi, cà rốt, ớt chuông; phần của bé không nêm.',
      "A quick stir-fry for the family meal: tender beef cut small with zucchini, carrot and bell pepper; your child's portion unseasoned.",
    ),
    ageMonths: { from: 12, to: 37 },
    texture: 'family',
    methods: ['spoon', 'blw'],
    servings: 3,
    prepMinutes: 15,
    cookMinutes: 10,
    ingredients: [
      ing('fd_beef', ['Thịt bò', 'Beef'], 100, 'g', [
        'thái mỏng ngang thớ',
        'thinly sliced across the grain',
      ]),
      ing('fd_carrot', ['Cà rốt', 'Carrot'], 40, 'g'),
      ing('fd_zucchini', ['Bí ngòi', 'Zucchini'], 50, 'g'),
      ing('fd_bell_pepper', ['Ớt chuông', 'Bell pepper'], 40, 'g'),
      ing('fd_garlic', ['Tỏi', 'Garlic'], 1, 'piece', ['một tép, băm', 'one clove, minced']),
      oil(2, 'tsp'),
    ],
    steps: steps(
      [
        'Thịt bò thái mỏng ngang thớ, rồi cắt nhỏ cỡ đầu ngón tay để bé dễ nhai.',
        'Slice the beef thinly across the grain, then cut it into fingertip-sized pieces that are easy to chew.',
      ],
      [
        'Cà rốt, bí ngòi, ớt chuông thái hạt lựu; luộc sơ cà rốt 5 phút cho mềm trước.',
        'Dice the carrot, zucchini and bell pepper; parboil the carrot for 5 minutes first.',
      ],
      [
        'Phi thơm tỏi với dầu, cho thịt bò vào xào lửa lớn đến khi chín kỹ, không còn màu hồng, rồi trút ra.',
        'Fry the garlic in the oil, add the beef and stir-fry over high heat until cooked through with no pink, then set it aside.',
      ],
      [
        'Xào rau củ với chút nước đến khi mềm, cho thịt vào đảo đều.',
        'Stir-fry the vegetables with a splash of water until soft, then return the beef and toss.',
      ],
      [
        'Múc phần của bé ra trước, rồi mới nêm phần người lớn. Ăn cùng cơm mềm.',
        "Take your child's portion out first, then season the rest for the adults. Serve with soft rice.",
      ],
    ),
    storage: STORE_COOKED,
    tip: t(
      'Thịt bò xào lâu dễ dai: xào nhanh lửa lớn, hoặc dùng thịt bò băm nếu bé chưa nhai giỏi. Ớt chuông giàu vitamin C giúp hấp thu sắt từ thịt.',
      "Beef toughens if cooked too long: stir-fry it quickly over high heat, or use mince if your child isn't chewing well yet. Bell pepper's vitamin C helps absorb the iron in the beef.",
    ),
    relatedArticleIds: [
      'art_solids_iron_foods',
      'art_solids_family_meals',
      'art_solids_choking_safety',
    ],
    sources: [S.cdcIron, S.unicef1to2, S.nhsYoungChildren, S.nhsStoringReheating],
  }),
  recipe('rcp_chao_ngao_rau_cai', {
    title: t('Cháo ngao rau cải', 'Clam congee with greens'),
    summary: t(
      'Cháo ngao ngọt thanh, nhiều sắt, hợp những ngày bé mệt hoặc mọc răng; thịt ngao băm nhỏ để bé dễ nhai.',
      'A light, naturally sweet clam congee rich in iron, good for days when your child is unwell or teething; the clam meat is minced for easy chewing.',
    ),
    ageMonths: { from: 12, to: 37 },
    texture: 'softPieces',
    methods: ['spoon'],
    servings: 3,
    prepMinutes: 20,
    cookMinutes: 40,
    ingredients: [
      ing('fd_rice', ['Gạo tẻ', 'Rice'], 40, 'g'),
      ing('fd_clam', ['Ngao', 'Clams'], 300, 'g', ['cả vỏ, còn sống', 'in the shell, live']),
      ing('fd_choy_sum', ['Cải ngọt', 'Choy sum'], 30, 'g'),
      ing('fd_spring_onion', ['Hành lá', 'Spring onion'], 1, 'piece'),
      ing(null, ['Gừng', 'Ginger'], 1, 'piece', ['một lát, vớt bỏ', 'one slice, removed']),
      water(600),
    ],
    steps: steps(
      [
        'Ngâm ngao trong nước vo gạo 2–3 giờ cho nhả cát, rửa sạch.',
        'Soak the clams in rice-rinsing water for 2–3 hours to release their grit, then rinse.',
      ],
      [
        'Luộc ngao với gừng đến khi vỏ mở hết, bỏ những con không mở. Tách lấy thịt, rửa lại, băm nhỏ; lọc nước luộc qua rây để bỏ cát.',
        'Boil the clams with the ginger until all the shells open, discarding any that stay closed. Take out the meat, rinse and mince it; strain the cooking water to remove grit.',
      ],
      [
        'Nấu gạo với nước luộc ngao và phần nước còn lại khoảng 30 phút đến khi cháo nhừ.',
        'Simmer the rice in the clam water and the remaining water for about 30 minutes until soft.',
      ],
      [
        'Cho thịt ngao và cải ngọt thái nhỏ vào, đun 3 phút. Rắc hành lá.',
        'Add the clam meat and chopped choy sum and cook for 3 minutes. Sprinkle with spring onion.',
      ],
      [
        'Phần của bé không nêm; nước ngao đã có vị ngọt và hơi mặn tự nhiên.',
        "Your child's portion stays unseasoned; clam broth is naturally sweet and a little salty.",
      ],
      firstTime('ngao', 'clams'),
    ),
    storage: STORE_RICE,
    tip: t(
      'Chọn ngao còn sống, vỏ khép chặt hoặc khép lại khi chạm vào. Có thể thay ngao bằng hến hoặc tôm.',
      'Choose live clams with shells that are closed or close when tapped. Basket clams or shrimp work too.',
    ),
    relatedArticleIds: ['art_solids_sick_teething', 'art_solids_iron_foods', 'art_allergen_intro'],
    sources: [S.unicef1to2, S.asciaIntroSolids, S.whoFiveKeys, S.nhsStoringReheating],
  }),
  // ----- 24–36 months: the family's dishes, mild and unseasoned for the child -----
  recipe('rcp_ca_ri_ga_khoai_lang', {
    title: t(
      'Cà ri gà khoai lang nước cốt dừa, không cay',
      'Mild chicken curry with sweet potato and coconut milk',
    ),
    summary: t(
      'Phiên bản không cay cho cả nhà: gà, khoai lang, cà rốt hầm mềm trong nước cốt dừa và chút bột cà ri nhẹ, ăn cùng bánh mì hoặc bún.',
      'A mild version for the whole family: chicken, sweet potato and carrot simmered soft in coconut milk with a little mild curry powder, served with bread or noodles.',
    ),
    ageMonths: { from: 24, to: 37 },
    texture: 'family',
    methods: ['spoon', 'blw'],
    servings: 4,
    prepMinutes: 20,
    cookMinutes: 40,
    ingredients: [
      ing('fd_chicken', ['Đùi gà rút xương', 'Boneless chicken thigh'], 200, 'g'),
      ing('fd_sweet_potato', ['Khoai lang', 'Sweet potato'], 150, 'g'),
      ing('fd_carrot', ['Cà rốt', 'Carrot'], 80, 'g'),
      ing('fd_onion', ['Hành tây', 'Onion'], 0.5, 'piece'),
      ing('fd_coconut_milk', ['Nước cốt dừa', 'Coconut milk'], 100, 'ml'),
      ing(null, ['Bột cà ri không cay', 'Mild curry powder'], 1, 'tsp', [
        'loại không pha muối',
        'a blend without salt',
      ]),
      oil(1, 'tbsp'),
      water(400),
    ],
    steps: steps(
      [
        'Gà cắt miếng vừa ăn; khoai lang và cà rốt cắt khúc; hành tây thái múi.',
        'Cut the chicken into bite-sized pieces, the sweet potato and carrot into chunks and the onion into wedges.',
      ],
      [
        'Phi thơm hành tây với dầu, cho bột cà ri vào đảo nhanh trên lửa nhỏ.',
        'Soften the onion in the oil, then stir in the curry powder briefly over low heat.',
      ],
      [
        'Cho gà vào xào đến khi săn, đổ nước vào, hầm 15 phút.',
        'Add the chicken and cook until it firms up, pour in the water and simmer for 15 minutes.',
      ],
      [
        'Thêm cà rốt, khoai lang, hầm tiếp 15–20 phút đến khi mềm và gà chín kỹ.',
        'Add the carrot and sweet potato and simmer for 15–20 more minutes until soft and the chicken is cooked through.',
      ],
      [
        'Đổ nước cốt dừa, đun sôi lại rồi tắt bếp.',
        'Pour in the coconut milk, bring back to the boil and turn off the heat.',
      ],
      [
        'Múc phần của bé ra trước khi nêm phần người lớn; xé gà và cắt khoai thành miếng nhỏ cho bé.',
        "Take your child's portion out before seasoning the adults' curry; shred the chicken and cut the vegetables small.",
      ],
      [
        'Ăn cùng bánh mì, bún hoặc cơm. Người lớn thích cay thì thêm ớt vào bát riêng.',
        'Serve with bread, rice noodles or rice. Adults who like it hot can add chilli to their own bowls.',
      ],
    ),
    storage: STORE_COOKED,
    tip: t(
      'Bột cà ri mua sẵn có loại đã pha muối; đọc nhãn và chọn loại không muối, không cay. Nước cốt dừa nhiều chất béo bão hoà, chỉ cần một ít cho thơm.',
      'Some ready-made curry powders contain salt; read the label and choose a mild one without salt. Coconut milk is high in saturated fat, so a little is enough for flavour.',
    ),
    relatedArticleIds: ['art_solids_family_meals', 'art_picky_eating_toddler'],
    sources: [S.unicef1to2, S.nhsYoungChildren, S.nhsStoringReheating],
  }),
  recipe('rcp_canh_chua_ca_loc', {
    title: t('Canh chua cá lóc cho cả nhà', 'Sour snakehead fish soup for the whole family'),
    summary: t(
      'Canh chua miền Nam chua dịu từ me, dứa và cà chua, có cá lóc và đậu bắp; phần của bé không nêm và được gỡ kỹ xương.',
      "A southern sour soup, gently tangy from tamarind, pineapple and tomato, with snakehead fish and okra; your child's portion unseasoned and carefully boned.",
    ),
    ageMonths: { from: 24, to: 37 },
    texture: 'family',
    methods: ['spoon', 'blw'],
    servings: 4,
    prepMinutes: 20,
    cookMinutes: 25,
    ingredients: [
      ing('fd_snakehead', ['Cá lóc cắt khúc', 'Snakehead fish steaks'], 250, 'g'),
      ing('fd_tomato', ['Cà chua', 'Tomatoes'], 2, 'piece'),
      ing('fd_pineapple', ['Dứa', 'Pineapple'], 80, 'g'),
      ing('fd_okra', ['Đậu bắp', 'Okra'], 4, 'piece'),
      ing('fd_spring_onion', ['Hành lá', 'Spring onion'], 1, 'piece'),
      ing(null, ['Me chua', 'Tamarind pulp'], 1, 'tbsp', [
        'dầm lấy nước, bỏ bã',
        'soaked and strained',
      ]),
      ing(null, ['Rau om, ngò gai', 'Rice paddy herb, sawtooth coriander'], null, null, [
        'tuỳ chọn',
        'optional',
      ]),
      water(1000),
    ],
    steps: steps(
      [
        'Cá lóc làm sạch, cắt khúc; me dầm với nước nóng, lọc lấy nước chua.',
        'Clean and cut the fish into steaks; mash the tamarind in hot water and strain off the sour liquid.',
      ],
      [
        'Cà chua thái múi, dứa thái miếng nhỏ, đậu bắp thái lát xéo.',
        'Cut the tomatoes into wedges, the pineapple into small pieces and the okra into slanted slices.',
      ],
      [
        'Đun sôi nước với nước me, cho cá vào nấu 8–10 phút đến khi chín kỹ, hớt bọt.',
        'Bring the water and tamarind liquid to the boil, add the fish and cook for 8–10 minutes until cooked through, skimming.',
      ],
      [
        'Cho dứa, cà chua vào nấu 3 phút, rồi thêm đậu bắp đun 2 phút.',
        'Add the pineapple and tomatoes for 3 minutes, then the okra for 2 more.',
      ],
      [
        'Rắc hành lá, rau thơm. Múc phần của bé ra trước khi nêm phần người lớn.',
        "Add the spring onion and herbs. Take your child's portion out before seasoning the rest.",
      ],
      [
        'Gỡ cá của bé trên đĩa sáng màu, bỏ hết xương; cắt đậu bắp, dứa thành miếng nhỏ. Ăn cùng cơm mềm.',
        "Flake your child's fish on a light-coloured plate and remove every bone; cut the okra and pineapple small. Serve with soft rice.",
      ],
    ),
    storage: STORE_COOKED,
    tip: t(
      'Canh chua ngoài hàng thường khá ngọt và mặn; phần của bé ở nhà chỉ có vị chua ngọt tự nhiên của dứa và cà chua. Nếu bé chê chua, giảm bớt nước me.',
      "Restaurant sour soup is often quite sweet and salty; your child's portion at home keeps just the natural sweet-sour taste of pineapple and tomato. If it is too sour for your child, use less tamarind.",
    ),
    relatedArticleIds: [
      'art_solids_family_meals',
      'art_solids_choking_safety',
      'art_picky_eating_toddler',
    ],
    sources: [S.unicef1to2, S.fdaFish, S.nhsYoungChildren, S.nhsStoringReheating],
  }),
  recipe('rcp_com_chien_trung_rau_cu', {
    title: t('Cơm chiên trứng rau củ ít dầu', 'Egg fried rice with vegetables, light on oil'),
    summary: t(
      'Cách dùng cơm nguội an toàn: cơm đã cất tủ lạnh chiên với trứng, đậu Hà Lan, cà rốt, ngô, ít dầu, phần của bé không nêm.',
      "Using leftover rice safely: refrigerated rice fried with egg, peas, carrot and corn in a little oil, your child's portion unseasoned.",
    ),
    ageMonths: { from: 24, to: 37 },
    texture: 'family',
    methods: ['spoon', 'blw'],
    servings: 3,
    prepMinutes: 10,
    cookMinutes: 10,
    ingredients: [
      ing('fd_rice', ['Cơm nguội', 'Cooked rice, chilled'], 1.5, 'bowl', [
        'đã cất tủ lạnh, dưới 24 giờ',
        'refrigerated, under 24 hours',
      ]),
      ing('fd_egg', ['Trứng gà', 'Eggs'], 2, 'piece'),
      ing('fd_peas', ['Đậu Hà Lan', 'Green peas'], 30, 'g'),
      ing('fd_carrot', ['Cà rốt', 'Carrot'], 30, 'g'),
      ing('fd_corn', ['Ngô ngọt', 'Sweet corn'], 30, 'g', ['tách hạt', 'kernels']),
      ing('fd_spring_onion', ['Hành lá', 'Spring onion'], 1, 'piece'),
      oil(1, 'tbsp'),
    ],
    steps: steps(
      [
        'Dùng cơm đã làm nguội và cất tủ lạnh trong vòng 1 giờ sau khi nấu, và dùng trong 24 giờ. Không dùng cơm để qua đêm ngoài tủ.',
        'Use rice that was cooled and refrigerated within 1 hour of cooking, within 24 hours. Never use rice left out overnight.',
      ],
      [
        'Luộc mềm cà rốt thái hạt lựu, đậu Hà Lan và hạt ngô 5–7 phút.',
        'Boil the diced carrot, peas and corn for 5–7 minutes until soft.',
      ],
      [
        'Đánh tan trứng, chiên chín kỹ với chút dầu, đảo tơi rồi trút ra.',
        'Beat the eggs, scramble them in a little oil until fully set and set aside.',
      ],
      [
        'Cho cơm vào chảo với dầu còn lại, đảo đến khi nóng đều và bốc hơi.',
        'Fry the rice in the remaining oil, tossing, until steaming hot all through.',
      ],
      [
        'Thêm rau củ và trứng, đảo đều, rắc hành lá. Múc phần của bé ra trước khi nêm phần người lớn.',
        "Add the vegetables and egg, toss and sprinkle with spring onion. Take your child's portion out before seasoning the rest.",
      ],
      [
        'Để nguội bớt; bé có thể tự xúc bằng thìa hoặc bốc. Nếu bé còn hay oẹ, dầm dập hạt đậu và hạt ngô.',
        'Let it cool a little; your child can use a spoon or fingers. If your child still gags often, crush the peas and corn.',
      ],
    ),
    storage: t(
      'Cơm chiên nên ăn hết trong bữa. Không cất lại và hâm lần nữa, vì cơm đã được hâm nóng một lần khi chiên.',
      'Eat the fried rice at the meal. Do not store and reheat it again: frying was its one reheat.',
    ),
    tip: t(
      'Chiên ít dầu trên chảo chống dính. Có thể thêm tôm băm hoặc thịt gà xé để bữa nhiều đạm hơn.',
      'Use a non-stick pan and little oil. Add minced shrimp or shredded chicken for more protein.',
    ),
    relatedArticleIds: [
      'art_solids_prep_storage',
      'art_solids_family_meals',
      'art_picky_eating_toddler',
    ],
    sources: [S.nhsStoringReheating, S.whoFiveKeys, S.unicef1to2, S.nhsYoungChildren],
  }),
  recipe('rcp_cha_ca_thi_la', {
    title: t('Chả cá thì là áp chảo', 'Fish cakes with dill'),
    summary: t(
      'Chả cá tự làm từ cá basa xay với thì là và hành lá, không nêm, áp chảo ít dầu: thay cho chả cá bán sẵn vốn khá mặn.',
      'Homemade fish cakes of minced basa with dill and spring onion, unseasoned and pan-fried in a little oil: an alternative to shop-bought fish cakes, which are quite salty.',
    ),
    ageMonths: { from: 24, to: 37 },
    texture: 'finger',
    methods: ['blw', 'spoon'],
    servings: 4,
    prepMinutes: 20,
    cookMinutes: 15,
    ingredients: [
      ing('fd_basa', ['Cá basa phi lê', 'Basa fillet'], 200, 'g'),
      ing('fd_dill', ['Thì là', 'Dill'], 2, 'tbsp', ['thái nhỏ', 'chopped']),
      ing('fd_spring_onion', ['Hành lá', 'Spring onion'], 1, 'piece'),
      ing('fd_egg', ['Trứng gà', 'Egg'], 1, 'piece'),
      ing(null, ['Bột năng', 'Tapioca starch'], 1, 'tbsp'),
      oil(1, 'tbsp'),
    ],
    steps: steps(
      [
        'Cá basa thấm khô, kiểm tra kỹ xương, cắt nhỏ rồi xay nhuyễn cùng trứng.',
        'Pat the basa dry, check it carefully for bones, chop it and blend it with the egg.',
      ],
      [
        'Trộn cá xay với thì là, hành lá thái nhỏ và bột năng đến khi dẻo. Không nêm.',
        'Mix the fish with the dill, chopped spring onion and starch until it holds together. No seasoning.',
      ],
      [
        'Xoa chút dầu vào tay, nặn thành miếng dẹt nhỏ, dày khoảng 1 cm.',
        'With lightly oiled hands, shape small flat cakes about 1 cm thick.',
      ],
      [
        'Áp chảo chống dính với ít dầu, lửa vừa, mỗi mặt 3–4 phút đến khi vàng và chín kỹ bên trong.',
        'Pan-fry in a non-stick pan with a little oil over medium heat for 3–4 minutes on each side until golden and cooked through.',
      ],
      [
        'Để nguội, cắt dải dài hoặc miếng nhỏ cho bé cầm. Ăn cùng cơm mềm và rau luộc.',
        'Let them cool and cut them into strips or small pieces to hold. Serve with soft rice and boiled greens.',
      ],
      [
        'Người lớn ăn kèm nước chấm riêng; phần của bé để nguyên vị.',
        "Adults can add their own dipping sauce; your child's portion stays plain.",
      ],
    ),
    storage: STORE_COOKED,
    tip: t(
      'Chả cá bán sẵn thường đã nêm khá mặn; tự làm ở nhà giúp bé quen vị cá tự nhiên. Có thể hấp thay vì áp chảo.',
      'Shop-bought fish cakes are usually quite salty; making them at home keeps the natural taste of fish. You can steam them instead of frying.',
    ),
    relatedArticleIds: [
      'art_solids_family_meals',
      'art_solids_finger_foods',
      'art_solids_foods_to_avoid',
    ],
    sources: [S.fdaFish, S.nhsYoungChildren, S.unicef1to2, S.nhsStoringReheating],
  }),
];
