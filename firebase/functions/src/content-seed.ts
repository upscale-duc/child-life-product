import type { ContentBlock, StageContent, ArticleContent } from '@child-life/contracts';
import { seedSolidsArticles } from './solids-seed.js';

/**
 * Engineering drafts of the editorial library (D-073 #2, "làm nội dung như 1 chuyên môn"; owner,
 * 2026-10-15: "những nội dung bài viết hãy soạn như chuyên gia"): the Thư viện chăm bé and Ăn dặm
 * articles and the 16 "Giai đoạn của bé" stage cards, written in the voice of the relevant
 * specialist (paediatrician, paediatric nurse, IBCLC lactation consultant, paediatric dietitian,
 * child-development and perinatal mental-health clinicians) from public guidance — WHO, UNICEF,
 * AAP / HealthyChildren.org, CDC, NHS, NICE, Bộ Y tế — with the pages they rest on as sources.
 *
 * Nothing here has been reviewed by a qualified person. Every item is published with
 * `review: null`, so the app shows it as illustrative ("Nội dung minh hoạ · chờ chuyên môn duyệt")
 * until a reviewer signs it; `reviewerLabel` only says who is expected to review it.
 * `staffContentSeed` (`content-library.ts`) imports these as drafts and never overwrites an id
 * that already exists.
 *
 * Article shape (4d): "Tóm tắt nhanh" note → "Hiểu đúng" → "Ba mẹ có thể làm gì" → "Theo dõi" →
 * "Hiểu lầm thường gặp" (common Vietnamese practices, corrected without blame) → the doctor
 * callout(s) "Khi nào nên hỏi bác sĩ / gọi 115" last. Emergency procedures are not repeated: the
 * text points to the offline Sơ cứu trẻ em guide. Text is plain (no markup); vi is the source, en
 * a faithful rendering (D-012). No brands; no medicine doses except a published standard
 * (vitamin D), otherwise "hỏi bác sĩ/dược sĩ liều theo cân nặng".
 */
export interface SeedArticle {
  id: string;
  reviewerLabel: string | null;
  data: ArticleContent;
}
export interface SeedStage {
  id: string;
  reviewerLabel: string | null;
  data: StageContent;
}

/** Who is expected to review each item (B01 "Người duyệt" filter); not a claim of review. */
const PAEDS = 'Nhóm chuyên môn · Nhi khoa';
const DEV = 'Nhóm chuyên môn · Phát triển trẻ em';
const LACTATION = 'Nhóm chuyên môn · Tư vấn sữa mẹ (IBCLC)';
const NUTRITION = 'Nhóm chuyên môn · Dinh dưỡng nhi';
const NURSING = 'Nhóm chuyên môn · Điều dưỡng nhi';
const PERINATAL = 'Nhóm chuyên môn · Sức khoẻ tâm thần chu sinh';

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

// ---------- Sources (specific pages, opened when the text was written) ----------

const S = {
  cdcMilestones: {
    label: 'CDC — Learn the Signs. Act Early.: Milestones by age',
    url: 'https://www.cdc.gov/act-early/milestones/index.html',
  },
  whoComplementary: {
    label: 'WHO — Complementary feeding',
    url: 'https://www.who.int/health-topics/complementary-feeding',
  },
  whoDiarrhoea: {
    label: 'WHO — Diarrhoeal disease (fact sheet)',
    url: 'https://www.who.int/news-room/fact-sheets/detail/diarrhoeal-disease',
  },
  whoSitLessPlayMore: {
    label: 'WHO — To grow up healthy, children need to sit less and play more (2019)',
    url: 'https://www.who.int/news/item/24-04-2019-to-grow-up-healthy-children-need-to-sit-less-and-play-more',
  },
  aapSafeSleep: {
    label: 'American Academy of Pediatrics — Safe sleep',
    url: 'https://www.aap.org/en/patient-care/safe-sleep/',
  },
  hcSafeSleep: {
    label: "HealthyChildren.org (AAP) — A parent's guide to safe sleep",
    url: 'https://www.healthychildren.org/English/ages-stages/baby/sleep/Pages/A-Parents-Guide-to-Safe-Sleep.aspx',
  },
  hcTummyTime: {
    label: 'HealthyChildren.org (AAP) — Back to sleep, tummy to play',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/sleep/Pages/Back-to-Sleep-Tummy-to-Play.aspx',
  },
  hcBaby: {
    label: 'HealthyChildren.org (AAP) — Baby',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/Pages/default.aspx',
  },
  hcBreastfeeding: {
    label: 'HealthyChildren.org (AAP) — Breastfeeding',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/breastfeeding/Pages/default.aspx',
  },
  hcTeething: {
    label: 'HealthyChildren.org (AAP) — Teething and tooth care',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/teething-tooth-care/Pages/default.aspx',
  },
  nhsBabyDevelopment: {
    label: "NHS — Your baby's development",
    url: 'https://www.nhs.uk/baby/babys-development/',
  },
  nhsSleep: {
    label: 'NHS — Helping your baby to sleep',
    url: 'https://www.nhs.uk/baby/caring-for-a-newborn/helping-your-baby-to-sleep/',
  },
  nhsSids: {
    label: 'NHS — Sudden infant death syndrome (SIDS)',
    url: 'https://www.nhs.uk/baby/caring-for-a-newborn/sudden-infant-death-syndrome-sids/',
  },
  nhsReflux: {
    label: 'NHS — Reflux in babies',
    url: 'https://www.nhs.uk/conditions/reflux-in-babies/',
  },
  nhsFever: {
    label: 'NHS — Fever in children',
    url: 'https://www.nhs.uk/symptoms/fever-in-children/',
  },
  nhsCold: {
    label: 'NHS — Common cold',
    url: 'https://www.nhs.uk/conditions/common-cold/',
  },
  nhsDiarrhoea: {
    label: 'NHS — Diarrhoea and vomiting',
    url: 'https://www.nhs.uk/symptoms/diarrhoea-and-vomiting/',
  },
  nhsTeething: {
    label: 'NHS — Baby teething symptoms',
    url: 'https://www.nhs.uk/baby/babys-development/teething/baby-teething-symptoms/',
  },
  unicefParenting: {
    label: 'UNICEF — Parenting',
    url: 'https://www.unicef.org/parenting/',
  },
  cdc2m: {
    label: 'CDC — Learn the Signs. Act Early.: Milestones by 2 months',
    url: 'https://www.cdc.gov/act-early/milestones/2-months.html',
  },
  cdc4m: {
    label: 'CDC — Learn the Signs. Act Early.: Milestones by 4 months',
    url: 'https://www.cdc.gov/act-early/milestones/4-months.html',
  },
  cdc6m: {
    label: 'CDC — Learn the Signs. Act Early.: Milestones by 6 months',
    url: 'https://www.cdc.gov/act-early/milestones/6-months.html',
  },
  cdc9m: {
    label: 'CDC — Learn the Signs. Act Early.: Milestones by 9 months',
    url: 'https://www.cdc.gov/act-early/milestones/9-months.html',
  },
  cdc12m: {
    label: 'CDC — Learn the Signs. Act Early.: Milestones by 1 year',
    url: 'https://www.cdc.gov/act-early/milestones/1-year.html',
  },
  cdc15m: {
    label: 'CDC — Learn the Signs. Act Early.: Milestones by 15 months',
    url: 'https://www.cdc.gov/act-early/milestones/15-months.html',
  },
  cdc18m: {
    label: 'CDC — Learn the Signs. Act Early.: Milestones by 18 months',
    url: 'https://www.cdc.gov/act-early/milestones/18-months.html',
  },
  cdc24m: {
    label: 'CDC — Learn the Signs. Act Early.: Milestones by 2 years',
    url: 'https://www.cdc.gov/act-early/milestones/2-years.html',
  },
  aHcGettingBabyToSleep: {
    label: 'HealthyChildren.org (AAP) — Getting your baby to sleep',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/sleep/Pages/Getting-Your-Baby-to-Sleep.aspx',
  },
  aAasmSleepDuration: {
    label:
      'American Academy of Sleep Medicine — Recommended amount of sleep for pediatric populations (consensus statement, 2016)',
    url: 'https://aasm.org/resources/pdf/pediatricsleepdurationconsensus.pdf',
  },
  aNhsBreastfeedingFirstDays: {
    label: 'NHS — Breastfeeding: the first few days',
    url: 'https://www.nhs.uk/baby/breastfeeding-and-bottle-feeding/breastfeeding/the-first-few-days/',
  },
  aHcFeedingHowOften: {
    label: 'HealthyChildren.org (AAP) — How often and how much should your baby eat?',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/feeding-nutrition/Pages/How-Often-and-How-Much-Should-Your-Baby-Eat.aspx',
  },
  aPmRivkeesCircadian: {
    label:
      'Rivkees SA — Emergence and influences of circadian rhythmicity in infants (Clin Perinatol 2004, PubMed)',
    url: 'https://pubmed.ncbi.nlm.nih.gov/15289029/',
  },
  aPmKennawayMelatonin: {
    label:
      'Kennaway DJ et al. — Development of melatonin production in infants and the impact of prematurity (J Clin Endocrinol Metab 1992, PubMed)',
    url: 'https://pubmed.ncbi.nlm.nih.gov/1639937/',
  },
  aPmHarrisonLight: {
    label:
      'Harrison Y — Daytime exposure to light and night-time sleep in 6–12-week-old infants (J Sleep Res 2004, PubMed)',
    url: 'https://pubmed.ncbi.nlm.nih.gov/15560769/',
  },
  aAapSafeSleep2022News: {
    label:
      'American Academy of Pediatrics — AAP updates safe sleep recommendations: back is best (2022)',
    url: 'https://www.aap.org/en/news-room/news-releases/aap/2022/american-academy-of-pediatrics-updates-safe-sleep-recommendations-back-is-best/',
  },
  aPmMoonSafeSleep2022: {
    label:
      'Moon RY et al. (AAP) — Sleep-related infant deaths: updated 2022 recommendations (Pediatrics, PubMed)',
    url: 'https://pubmed.ncbi.nlm.nih.gov/35726558/',
  },
  aFdaPositioners: {
    label:
      'U.S. FDA — Recommendations for parents and caregivers about the use of baby products (sleep positioners)',
    url: 'https://www.fda.gov/medical-devices/baby-products-sids-prevention-claims/recommendations-parentscaregivers-about-use-baby-products',
  },
  aHcHeadShape: {
    label:
      "HealthyChildren.org (AAP) — When a baby's head is misshapen: positional skull deformities",
    url: 'https://www.healthychildren.org/English/health-issues/conditions/Cleft-Craniofacial/Pages/Positional-Skull-Deformities-and-Torticollis.aspx',
  },
  aHcCalmingFussy: {
    label: 'HealthyChildren.org (AAP) — Calming a fussy baby',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/crying-colic/Pages/Calming-A-Fussy-Baby.aspx',
  },
  aNationwideInfantSleep: {
    label: "Nationwide Children's Hospital — Sleep in infants",
    url: 'https://www.nationwidechildrens.org/specialties/sleep-disorder-center/sleep-in-infants',
  },
  aNationwideToddlerSleep: {
    label: "Nationwide Children's Hospital — Sleep in toddlers",
    url: 'https://www.nationwidechildrens.org/specialties/sleep-disorder-center/sleep-in-toddlers',
  },
  aNhsFormulaMakingUp: {
    label: 'NHS — How to make up baby formula',
    url: 'https://www.nhs.uk/baby/breastfeeding-and-bottle-feeding/bottle-feeding/making-up-baby-formula/',
  },
  aPmPriceSleepIntervention: {
    label:
      'Price AM et al. — Five-year follow-up of harms and benefits of behavioral infant sleep intervention (Pediatrics 2012, PubMed)',
    url: 'https://pubmed.ncbi.nlm.nih.gov/22966034/',
  },
  aPmGradisarSleepIntervention: {
    label:
      'Gradisar M et al. — Behavioral interventions for infant sleep problems: a randomized controlled trial (Pediatrics 2016, PubMed)',
    url: 'https://pubmed.ncbi.nlm.nih.gov/27221288/',
  },
  aPmScherCrawling: {
    label:
      'Scher A, Cohen D — Sleep as a mirror of developmental transitions in infancy: the case of crawling (2015, PubMed)',
    url: 'https://pubmed.ncbi.nlm.nih.gov/25704736/',
  },
  aHcSwaddling: {
    label: 'HealthyChildren.org (AAP) — Swaddling: is it safe for your baby?',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/diapers-clothing/Pages/Swaddling-Is-it-Safe.aspx',
  },
  aIhdiSwaddling: {
    label: 'International Hip Dysplasia Institute — Hip-healthy swaddling',
    url: 'https://hipdysplasia.org/infant-child/hip-healthy-swaddling/',
  },
  aNhsDdh: {
    label: 'NHS — Developmental dysplasia of the hip',
    url: 'https://www.nhs.uk/conditions/developmental-dysplasia-of-the-hip/',
  },
  aNhsColic: { label: 'NHS — Colic', url: 'https://www.nhs.uk/conditions/colic/' },
  aNhsSoothingCrying: {
    label: 'NHS — Soothing a crying baby',
    url: 'https://www.nhs.uk/baby/caring-for-a-newborn/soothing-a-crying-baby/',
  },
  aHcColic: {
    label: 'HealthyChildren.org (AAP) — Colic relief tips for parents',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/crying-colic/Pages/Colic.aspx',
  },
  aHcRespondingCries: {
    label: "HealthyChildren.org (AAP) — Responding to your baby's cries",
    url: 'https://www.healthychildren.org/English/ages-stages/baby/crying-colic/Pages/Responding-to-Your-Babys-Cries.aspx',
  },
  aCdcAht: {
    label: 'CDC — About abusive head trauma',
    url: 'https://www.cdc.gov/child-abuse-neglect/about/about-abusive-head-trauma.html',
  },
  aPmSungReuteri: {
    label:
      'Sung V et al. — Lactobacillus reuteri to treat infant colic: a meta-analysis (Pediatrics 2018, PubMed)',
    url: 'https://pubmed.ncbi.nlm.nih.gov/29279326/',
  },
  aNhsMeningitisSymptoms: {
    label: 'NHS — Meningitis (symptoms in babies)',
    url: 'https://www.nhs.uk/conditions/meningitis/',
  },
  whoVietnamBreastfeeding: {
    label: 'WHO Viet Nam — Breastfeeding',
    url: 'https://www.who.int/vietnam/health-topics/breastfeeding',
  },
  nhsBfFirstDays: {
    label: 'NHS — Breastfeeding: the first few days',
    url: 'https://www.nhs.uk/baby/breastfeeding-and-bottle-feeding/breastfeeding/the-first-few-days/',
  },
  nhsBfEnoughMilk: {
    label: 'NHS — Is my baby getting enough breast milk?',
    url: 'https://www.nhs.uk/baby/breastfeeding-and-bottle-feeding/breastfeeding-problems/enough-milk/',
  },
  nhsBfPositioning: {
    label: 'NHS — Breastfeeding: positioning and attachment',
    url: 'https://www.nhs.uk/baby/breastfeeding-and-bottle-feeding/breastfeeding/positioning-and-attachment/',
  },
  nhsBfBreastPain: {
    label: 'NHS — Breast pain and breastfeeding (engorgement, blocked ducts, mastitis)',
    url: 'https://www.nhs.uk/baby/breastfeeding-and-bottle-feeding/breastfeeding-problems/breast-pain/',
  },
  hcBfEnoughMilk: {
    label: 'HealthyChildren.org (AAP) — How to tell if your baby is getting enough breast milk',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/breastfeeding/Pages/How-to-Tell-if-Baby-is-Getting-Enough-Milk.aspx',
  },
  hcFirstMonthGrowth: {
    label: "HealthyChildren.org (AAP) — Your baby's first month: growth and physical appearance",
    url: 'https://www.healthychildren.org/English/ages-stages/baby/Pages/First-Month-Physical-Appearance-and-Growth.aspx',
  },
  cdcFluBreastfeeding: {
    label: 'CDC — Influenza (flu) and breastfeeding',
    url: 'https://www.cdc.gov/breastfeeding-special-circumstances/hcp/illnesses-conditions/flu.html',
  },
  nhsBfExpressing: {
    label: 'NHS — Expressing and storing breast milk',
    url: 'https://www.nhs.uk/baby/breastfeeding-and-bottle-feeding/breastfeeding/expressing-breast-milk/',
  },
  cdcBreastMilkStorage: {
    label: 'CDC — Breast milk storage and preparation',
    url: 'https://www.cdc.gov/breastfeeding/breast-milk-preparation-and-storage/handling-breastmilk.html',
  },
  cdcBreastPumpClean: {
    label: 'CDC — How to clean and sanitize breast pumps',
    url: 'https://www.cdc.gov/hygiene/about/about-breast-pump-hygiene.html',
  },
  nhsMakingFormula: {
    label: 'NHS — How to make up baby formula',
    url: 'https://www.nhs.uk/baby/breastfeeding-and-bottle-feeding/bottle-feeding/making-up-baby-formula/',
  },
  nhsBottleFeedingAdvice: {
    label: 'NHS — Bottle feeding advice',
    url: 'https://www.nhs.uk/baby/breastfeeding-and-bottle-feeding/bottle-feeding/advice/',
  },
  nhsSterilisingBottles: {
    label: 'NHS — Sterilising baby bottles',
    url: 'https://www.nhs.uk/baby/breastfeeding-and-bottle-feeding/bottle-feeding/sterilising-baby-bottles/',
  },
  nhsFormulaTypes: {
    label: 'NHS — Types of formula',
    url: 'https://www.nhs.uk/baby/breastfeeding-and-bottle-feeding/bottle-feeding/types-of-formula/',
  },
  cdcFormulaPrep: {
    label: 'CDC — Infant formula preparation and storage',
    url: 'https://www.cdc.gov/infant-toddler-nutrition/formula-feeding/preparation-and-storage.html',
  },
  hcFormulaWater: {
    label: 'HealthyChildren.org (AAP) — How to safely prepare formula with water',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/formula-feeding/Pages/How-to-Safely-Prepare-Formula-with-Water.aspx',
  },
  hcFormulaAmount: {
    label: 'HealthyChildren.org (AAP) — Amount and schedule of baby formula feedings',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/formula-feeding/Pages/Amount-and-Schedule-of-Formula-Feedings.aspx',
  },
  hcStartingSolidsCereal: {
    label: 'HealthyChildren.org (AAP) — Starting solid foods',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/feeding-nutrition/Pages/Starting-Solid-Foods.aspx',
  },
  hcWhyBabiesSpitUp: {
    label: 'HealthyChildren.org (AAP) — Why babies spit up',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/feeding-nutrition/Pages/Why-Babies-Spit-Up.aspx',
  },
  hcRefluxGerd: {
    label: 'HealthyChildren.org (AAP) — Gastroesophageal reflux (GER) and GERD',
    url: 'https://www.healthychildren.org/English/health-issues/conditions/abdominal/Pages/GERD-Reflux.aspx',
  },
  hcPyloricStenosis: {
    label: 'HealthyChildren.org (AAP) — Hypertrophic pyloric stenosis: forceful vomiting in babies',
    url: 'https://www.healthychildren.org/English/health-issues/conditions/abdominal/Pages/Hypertrophic-Pyloric-Stenosis-HPS-Babies-Forceful-Vomiting.aspx',
  },
  hcRefluxSafeSleep: {
    label: 'HealthyChildren.org (AAP) — What is the safest sleep solution for my baby with reflux?',
    url: 'https://www.healthychildren.org/English/tips-tools/ask-the-pediatrician/Pages/What-is-the-safest-sleep-solution-for-my-baby-with-reflux.aspx',
  },
  hcBurpingHiccups: {
    label: 'HealthyChildren.org (AAP) — Baby burping, hiccups and spit-up',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/feeding-nutrition/Pages/baby-burping-hiccups-and-spit-up.aspx',
  },
  nhsVitaminsChildren: {
    label: 'NHS — Vitamins for children',
    url: 'https://www.nhs.uk/baby/weaning-and-feeding/vitamins-for-children/',
  },
  hcVitaminD: {
    label: 'HealthyChildren.org (AAP) — Vitamin D for babies, children and adolescents',
    url: 'https://www.healthychildren.org/English/healthy-living/nutrition/Pages/vitamin-d-on-the-double.aspx',
  },
  hcVitaminIronSupplements: {
    label: 'HealthyChildren.org (AAP) — Where we stand: vitamin D and iron supplements for babies',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/feeding-nutrition/Pages/Vitamin-Iron-Supplements.aspx',
  },
  hcIronGuidance2026: {
    label:
      'HealthyChildren.org (AAP) — Iron deficiency and iron deficiency anemia: AAP updates guidance (2026)',
    url: 'https://www.healthychildren.org/English/news/Pages/iron-deficiency-anemia-prevention-screening-treatment-AAP-updates-guidance.aspx',
  },
  hcAnemia: {
    label: 'HealthyChildren.org (AAP) — Iron deficiency and anemia in babies, children and teens',
    url: 'https://www.healthychildren.org/English/health-issues/conditions/chronic/Pages/Anemia-and-Your-Child.aspx',
  },
  hcSunSafety: {
    label: 'HealthyChildren.org (AAP) — Sun safety',
    url: 'https://www.healthychildren.org/English/safety-prevention/at-play/Pages/Sun-Safety.aspx',
  },
  nhsIron: {
    label: 'NHS — Vitamins and minerals: iron',
    url: 'https://www.nhs.uk/conditions/vitamins-and-minerals/iron/',
  },
  ruhIronChildrensDiets: {
    label: "Royal United Hospitals Bath NHS Foundation Trust — Iron in children's diets (leaflet)",
    url: 'https://www.ruh.nhs.uk/patients/patient_information/PAE032_Iron_in_childrens_diets.pdf',
  },
  cNhsFirstSolids: {
    label: "NHS — Your baby's first solid foods",
    url: 'https://www.nhs.uk/baby/weaning-and-feeding/babys-first-solid-foods/',
  },
  cNhsFoodsToAvoid: {
    label: 'NHS — Foods to avoid giving babies and young children',
    url: 'https://www.nhs.uk/baby/weaning-and-feeding/foods-to-avoid-giving-babies-and-young-children/',
  },
  cNhsDrinksCups: {
    label: 'NHS — Drinks and cups for babies and young children',
    url: 'https://www.nhs.uk/baby/weaning-and-feeding/drinks-and-cups-for-babies-and-young-children/',
  },
  cNhsFoodAllergies: {
    label: 'NHS — Food allergies in babies and young children',
    url: 'https://www.nhs.uk/baby/weaning-and-feeding/food-allergies-in-babies-and-young-children/',
  },
  cNhsChoking: {
    label: 'NHS — How to stop a child from choking',
    url: 'https://www.nhs.uk/baby/first-aid-and-safety/first-aid/how-to-stop-a-child-from-choking/',
  },
  cWhoIycfFactSheet: {
    label: 'WHO — Infant and young child feeding (fact sheet)',
    url: 'https://www.who.int/news-room/fact-sheets/detail/infant-and-young-child-feeding',
  },
  cWhoCfGuideline2023: {
    label:
      'WHO — Guideline for complementary feeding of infants and young children 6–23 months of age (2023)',
    url: 'https://www.who.int/publications/i/item/9789240081864',
  },
  cWhoDietaryDiversity: {
    label: 'WHO — Indicator: minimum dietary diversity, children 6–23 months',
    url: 'https://www.who.int/data/gho/indicator-metadata-registry/imr-details/7042',
  },
  cUnicefFeeding6to12: {
    label: 'UNICEF — Feeding your baby: 6–12 months',
    url: 'https://www.unicef.org/parenting/food-nutrition/feeding-your-baby-6-12-months',
  },
  cUnicefFeeding1to2: {
    label: 'UNICEF — Feeding your baby: 1–2 years',
    url: 'https://www.unicef.org/parenting/food-nutrition/feeding-your-baby-1-2-years',
  },
  cHcStartingSolids: {
    label: 'HealthyChildren.org (AAP) — Starting solid foods',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/feeding-nutrition/Pages/Starting-Solid-Foods.aspx',
  },
  cHcRecommendedDrinks: {
    label: 'HealthyChildren.org (AAP) — Recommended drinks for children age 5 and younger',
    url: 'https://www.healthychildren.org/English/healthy-living/nutrition/Pages/Recommended-Drinks-for-Young-Children-Ages-0-5.aspx',
  },
  cHcFruitJuice: {
    label: 'HealthyChildren.org (AAP) — Where we stand: fruit juice',
    url: 'https://www.healthychildren.org/English/healthy-living/nutrition/Pages/Where-We-Stand-Fruit-Juice.aspx',
  },
  cHcFormulaWater: {
    label: 'HealthyChildren.org (AAP) — How to safely prepare baby formula with water',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/formula-feeding/Pages/how-to-safely-prepare-formula-with-water.aspx',
  },
  cHcChokingPrevention: {
    label: 'HealthyChildren.org (AAP) — Choking prevention',
    url: 'https://www.healthychildren.org/English/health-issues/injuries-emergencies/Pages/Choking-Prevention.aspx',
  },
  cHcToothDecayBaby: {
    label: "HealthyChildren.org (AAP) — Why it's important to take care of baby teeth",
    url: 'https://www.healthychildren.org/English/ages-stages/baby/teething-tooth-care/Pages/How-to-Prevent-Tooth-Decay-in-Your-Baby.aspx',
  },
  cHcEarlyPeanut2019: {
    label:
      'HealthyChildren.org (AAP) — AAP clinical report highlights early introduction of peanut-based foods to prevent allergies (2019)',
    url: 'https://www.healthychildren.org/English/news/Pages/Early-Introduction-of-Peanut-based-Foods-to-Prevent-Allergies.aspx',
  },
  cCdcChokingHazards: {
    label: 'CDC — Infant and toddler nutrition: choking hazards',
    url: 'https://www.cdc.gov/infant-toddler-nutrition/foods-and-drinks/choking-hazards.html',
  },
  cFdaKonjacJellyCups: {
    label: 'FDA — Recall notice for konjac fruit jelly cups (choking hazard, import alert 33-15)',
    url: 'https://www.fda.gov/safety/recalls-market-withdrawals-safety-alerts/rong-shing-trading-ny-inc-brooklyn-ny-recalling-its-211oz-600g-xi-zhi-liang-fruit-jelly-cup',
  },
  cFdaFishAdvice: {
    label:
      'FDA — Advice about eating fish (for those who might become pregnant, are pregnant, breastfeeding, and children)',
    url: 'https://www.fda.gov/food/consumers/advice-about-eating-fish',
  },
  cGoshButtonBatteries: {
    label: 'Great Ormond Street Hospital (NHS) — Button batteries: using them safely',
    url: 'https://www.gosh.nhs.uk/conditions-and-treatments/conditions-we-treat/button-batteries-using-them-safely/',
  },
  cAsciaIntroSolids: {
    label: 'ASCIA — How to introduce solid foods to babies for allergy prevention',
    url: 'https://www.allergy.org.au/patients/allergy-prevention/ascia-how-to-introduce-solid-foods-to-babies',
  },
  cBsaciParentSummary: {
    label: 'BSACI — Preventing food allergy in your baby: a summary for parents',
    url: 'https://www.bsaci.org/wp-content/uploads/2020/02/pdf_Infant-feeding-and-allergy-prevention-PARENTS-FINAL-booklet.pdf',
  },
  cCsaciEatEarly: {
    label: 'CSACI and Canadian Paediatric Society — Eat early, eat often: food allergy prevention',
    url: 'https://www.csaci.ca/wp-content/uploads/2026/05/Eat-Early-Eat-Often-Food-Allergy-Prevention.pdf',
  },
  cAafpNiaidPeanut: {
    label:
      'American Family Physician — Peanut allergy prevention: guidelines from the NIAID (2017)',
    url: 'https://www.aafp.org/pubs/afp/issues/2017/0715/p130.html',
  },
  cCoulthardLumps2009: {
    label:
      "Coulthard, Harris & Emmett (2009) — Delayed introduction of lumpy foods affects child's food acceptance and feeding at 7 years, Maternal and Child Nutrition",
    url: 'https://research.birmingham.ac.uk/en/publications/delayed-introduction-of-lumpy-foods-to-children-during-the-comple',
  },
  niceFeverNg143: {
    label: 'NICE NG143 — Fever in under 5s: assessment and initial management (recommendations)',
    url: 'https://www.nice.org.uk/guidance/ng143/chapter/Recommendations',
  },
  nhsHandFootMouth: {
    label: 'NHS — Hand, foot and mouth disease',
    url: 'https://www.nhs.uk/conditions/hand-foot-mouth-disease/',
  },
  hcFebrileSeizures: {
    label: 'HealthyChildren.org (AAP) — Febrile seizures',
    url: 'https://www.healthychildren.org/English/health-issues/conditions/fever/Pages/Febrile-Seizures.aspx',
  },
  hcIbuprofenDosing: {
    label: 'HealthyChildren.org (AAP) — Ibuprofen for fever and pain',
    url: 'https://www.healthychildren.org/English/safety-prevention/at-home/medication-safety/Pages/Ibuprofen-for-Fever-and-Pain.aspx',
  },
  whoDengueFactSheet: {
    label: 'WHO — Dengue and severe dengue (fact sheet)',
    url: 'https://www.who.int/news-room/fact-sheets/detail/dengue-and-severe-dengue',
  },
  nhtwDengueHomeCare: {
    label: 'Bệnh viện Nhi Trung ương — Chăm sóc trẻ bị sốt xuất huyết tại nhà',
    url: 'https://benhviennhitrunguong.gov.vn/cham-soc-tre-bi-sot-xuat-huyet-tai-nha.html',
  },
  nhtwHfmdGuide: {
    label: 'Bệnh viện Nhi Trung ương — Hướng dẫn chẩn đoán bệnh tay chân miệng',
    url: 'https://benhviennhitrunguong.gov.vn/huong-dan-chan-doan-benh-tay-chan-mieng.html',
  },
  hcChildrenAndColds: {
    label: 'HealthyChildren.org (AAP) — Children and colds',
    url: 'https://www.healthychildren.org/English/health-issues/conditions/ear-nose-throat/Pages/Children-and-Colds.aspx',
  },
  hcCoughColdRemedies: {
    label: 'HealthyChildren.org (AAP) — Coughs and colds: medicines or home remedies?',
    url: 'https://www.healthychildren.org/English/health-issues/conditions/chest-lungs/Pages/Coughs-and-Colds-Medicines-or-Home-Remedies.aspx',
  },
  fdaKidsCoughCold: {
    label: 'U.S. FDA — Should you give kids medicine for coughs and colds?',
    url: 'https://www.fda.gov/consumers/consumer-updates/should-you-give-kids-medicine-coughs-and-colds',
  },
  mhraCoughColdChildren: {
    label: 'MHRA (UK) Drug Safety Update — Over-the-counter cough and cold medicines for children',
    url: 'https://www.gov.uk/drug-safety-update/over-the-counter-cough-and-cold-medicines-for-children',
  },
  whoImciChartBooklet: {
    label: 'WHO — Integrated Management of Childhood Illness (IMCI) chart booklet, 2014',
    url: 'https://cdn.who.int/media/docs/default-source/mca-documents/child/imci-integrated-management-of-childhood-illness/imci-in-service-training/imci-chart-booklet.pdf?sfvrsn=f63af425_1',
  },
  poisonOrgVapourRub: {
    label: 'National Capital Poison Center (Poison Control, US) — Is Vicks VapoRub safe?',
    url: 'https://www.poison.org/articles/is-vicks-vaporub-safe',
  },
  nhsNewcastleSteamBurns: {
    label: 'Newcastle upon Tyne Hospitals NHS — Burns warning: risks of steam inhalation',
    url: 'https://www.newcastle-hospitals.nhs.uk/news/burns-warning-risks-of-steam-inhalation/',
  },
  niceGastroCg84: {
    label:
      'NICE CG84 — Diarrhoea and vomiting caused by gastroenteritis in under 5s (recommendations)',
    url: 'https://www.nice.org.uk/guidance/cg84/chapter/Recommendations',
  },
  msfWhoRehydrationPlans: {
    label:
      'MSF Clinical guidelines — Appendix 14: WHO rehydration plans for patients with diarrhoea',
    url: 'https://medicalguidelines.msf.org/en/viewport/mme/english/appendix-14-plan-rehydration-who-32408338.html',
  },
  nhsNewbornJaundice: {
    label: 'NHS — Jaundice in babies',
    url: 'https://www.nhs.uk/conditions/jaundice-in-babies/',
  },
  niceJaundiceCg98: {
    label: 'NICE CG98 — Jaundice in newborn babies under 28 days (recommendations)',
    url: 'https://www.nice.org.uk/guidance/cg98/chapter/Recommendations',
  },
  niceJaundiceCg98Context: {
    label: 'NICE CG98 — Jaundice in newborn babies under 28 days (context)',
    url: 'https://www.nice.org.uk/guidance/cg98/chapter/Context',
  },
  hcNewbornJaundice: {
    label: 'HealthyChildren.org (AAP) — Jaundice in newborns',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/Pages/Jaundice.aspx',
  },
  aafpAapHyperbili2022: {
    label:
      'American Family Physician — Hyperbilirubinemia in newborns: updated guidelines from the AAP (2023)',
    url: 'https://www.aafp.org/afp/2023/0600/practice-guidelines-hyperbilirubinemia-newborns',
  },
  byt13TiemChung2026: {
    label: 'Bộ Y tế — Thông tư 13/2026/TT-BYT quy định về hoạt động tiêm chủng (toàn văn)',
    url: 'https://hethongphapluat.com/thong-tu-13-2026-tt-byt-quy-dinh-ve-hoat-dong-tiem-chung-do-bo-truong-bo-y-te-ban-hanh.html',
  },
  vinmecEpiUnder1: {
    label: 'Vinmec — Những vắc xin phải tiêm cho trẻ dưới 1 tuổi (tiêm chủng mở rộng)',
    url: 'https://www.vinmec.com/vie/bai-viet/nhung-vac-xin-phai-tiem-cho-tre-duoi-1-tuoi-vi',
  },
  nhsSixInOneSideEffects: {
    label: 'NHS — 6-in-1 vaccine (including side effects)',
    url: 'https://www.nhs.uk/vaccinations/6-in-1-vaccine/',
  },
  cdcAfterVaccinesInfant: {
    label: 'CDC — Care for your child after vaccinations (infants)',
    url: 'https://www.cdc.gov/vaccines/parents/~local/modules/by-age/after-vaccinations-infant-swaddle.html',
  },
  cdcDtapVis: {
    label: 'CDC — DTaP vaccine information statement',
    url: 'https://www.cdc.gov/vaccines/hcp/current-vis/dtap.html',
  },
  whoPainAtVaccination: {
    label: 'WHO — Reducing pain at the time of vaccination: WHO position paper (WER 2015)',
    url: 'https://www.who.int/publications/i/item/who-wer9039',
  },
  nswBcgVietnamese: {
    label: 'NSW Health — Vắc-xin BCG phòng ngừa bệnh lao: thông tin cho gia đình (tiếng Việt)',
    url: 'https://www.health.nsw.gov.au/Infectious/tuberculosis/Documents/Language/bcg-information-vie.pdf',
  },
  phacAnaphylaxisCig: {
    label:
      'Public Health Agency of Canada — Canadian Immunization Guide: anaphylaxis and other acute reactions following vaccination',
    url: 'https://www.canada.ca/en/public-health/services/publications/healthy-living/canadian-immunization-guide-part-2-vaccine-safety/page-4-early-vaccine-reactions-including-anaphylaxis.html',
  },
  niceConstipationCg99: {
    label: 'NICE CG99 — Constipation in children and young people (recommendations)',
    url: 'https://www.nice.org.uk/guidance/cg99/chapter/Recommendations',
  },
  nhsConstipationChildren: {
    label: 'NHS — Constipation in children',
    url: 'https://www.nhs.uk/baby/health/constipation-in-children/',
  },
  nhsBottleConstipation: {
    label: 'NHS Best Start in Life — Constipation and bottle feeding',
    url: 'https://www.nhs.uk/best-start-in-life/baby/feeding-your-baby/bottle-feeding/bottle-feeding-challenges/constipation-and-bottle-feeding/',
  },
  hcInfantConstipation: {
    label: 'HealthyChildren.org (AAP) — Infant constipation',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/diapers-clothing/Pages/Infant-Constipation.aspx',
  },
  hcRecommendedDrinks: {
    label: 'HealthyChildren.org (AAP) — Recommended drinks for young children ages 0–5',
    url: 'https://www.healthychildren.org/English/healthy-living/nutrition/Pages/Recommended-Drinks-for-Young-Children-Ages-0-5.aspx',
  },
  eHcBathingNewborn: {
    label: 'HealthyChildren.org (AAP) — Bathing your baby',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/bathing-skin-care/Pages/Bathing-Your-Newborn.aspx',
  },
  eNhsWashingBathing: {
    label: 'NHS — Washing and bathing your baby',
    url: 'https://www.nhs.uk/baby/caring-for-a-newborn/washing-and-bathing-your-baby/',
  },
  eWhoPostnatal2013: {
    label:
      'WHO — Postnatal care of the mother and newborn: highlights from the WHO 2013 guidelines',
    url: 'https://www.who.int/docs/default-source/mca-documents/nbh/brief-postnatal-care-for-mothers-and-newborns-highlights-from-the-who-2013-guidelines.pdf',
  },
  ePbbBathingNewborn: {
    label: 'Pregnancy, Birth and Baby (Australian Government) — Bathing your newborn',
    url: 'https://www.pregnancybirthbaby.org.au/babies/daily-care/bathing-your-newborn-infographic',
  },
  eHcBabyRoomSafe: {
    label:
      "HealthyChildren.org (AAP) — Make baby's room safe: parent checklist (baby and talcum powder)",
    url: 'https://www.healthychildren.org/English/safety-prevention/at-home/Pages/Make-Babys-Room-Safe.aspx',
  },
  eCcShavingThicker: {
    label: 'Cleveland Clinic — Will shaving make your hair grow back thicker?',
    url: 'https://health.clevelandclinic.org/does-shaving-make-hair-thicker',
  },
  eAadEczemaBabies: {
    label: 'American Academy of Dermatology — How to treat eczema in babies',
    url: 'https://www.aad.org/public/diseases/eczema/childhood/treating/treat-babies',
  },
  eHcUmbilicalCord: {
    label: 'HealthyChildren.org (AAP) — Umbilical cord care in newborns',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/bathing-skin-care/Pages/Umbilical-Cord-Care.aspx',
  },
  eMedlineCordCare: {
    label: 'MedlinePlus (U.S. National Library of Medicine) — Umbilical cord care in newborns',
    url: 'https://medlineplus.gov/ency/article/001926.htm',
  },
  eNhsUmbilicalHernia: {
    label: 'NHS — Umbilical hernia',
    url: 'https://www.nhs.uk/conditions/umbilical-hernia/',
  },
  eNhsNappyRash: {
    label: 'NHS — Nappy rash',
    url: 'https://www.nhs.uk/baby/caring-for-a-newborn/nappy-rash/',
  },
  eHcDiaperRash: {
    label:
      'HealthyChildren.org (AAP) — Diaper rash: causes, prevention, treatment and when to call a doctor',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/diapers-clothing/Pages/Diaper-Rash.aspx',
  },
  eNesTopicalSteroids: {
    label: 'National Eczema Society (UK) — Topical steroids',
    url: 'https://www.eczema.org.uk/support/topical-steroids',
  },
  eNhsAtopicEczema: {
    label: 'NHS — Atopic eczema',
    url: 'https://www.nhs.uk/conditions/atopic-eczema/',
  },
  eNhsEmollients: {
    label: 'NHS — Emollients',
    url: 'https://www.nhs.uk/tests-and-treatments/emollients/',
  },
  eHcEczema: {
    label: 'HealthyChildren.org (AAP) — Eczema in children',
    url: 'https://www.healthychildren.org/English/health-issues/conditions/skin/Pages/Eczema.aspx',
  },
  eAadSteroidsChild: {
    label:
      'American Academy of Dermatology — Eczema treatment: corticosteroids applied to the skin (children)',
    url: 'https://www.aad.org/public/diseases/eczema/childhood/treating/corticosteroids-applied-to-skin',
  },
  eDermnetEczemaHerpeticum: {
    label: 'DermNet — Eczema herpeticum',
    url: 'https://dermnetnz.org/topics/eczema-herpeticum',
  },
  eHcPeanutEarly: {
    label:
      'HealthyChildren.org (AAP) — Early introduction of peanut-based foods to prevent allergies',
    url: 'https://www.healthychildren.org/English/news/Pages/Early-Introduction-of-Peanut-based-Foods-to-Prevent-Allergies.aspx',
  },
  eMhraHerbalSteroids: {
    label: "MHRA (UK) — Natural doesn't mean safe: herbal medicines found to contain steroids",
    url: 'https://www.gov.uk/government/news/natural-doesnt-mean-safe-herbal-medicines-found-to-contain-steroids',
  },
  eNhsTeethingTips: {
    label: 'NHS — Tips for helping your teething baby',
    url: 'https://www.nhs.uk/baby/babys-development/teething/tips-for-helping-your-teething-baby/',
  },
  eHcTeethingPain: {
    label: 'HealthyChildren.org (AAP) — Teething pain: how to help',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/teething-tooth-care/Pages/Teething-Pain.aspx',
  },
  eFdaTeething: {
    label: 'U.S. FDA — Safely soothing teething pain in infants and children',
    url: 'https://www.fda.gov/consumers/consumer-updates/safely-soothing-teething-pain-infants-and-children',
  },
  eNhsChildrenTeeth: {
    label: "NHS — Taking care of children's teeth",
    url: 'https://www.nhs.uk/live-well/healthy-teeth-and-gums/taking-care-of-childrens-teeth/',
  },
  eHcOralHealthEarly: {
    label: 'HealthyChildren.org (AAP) — Good oral health starts early: AAP policy explained',
    url: 'https://www.healthychildren.org/English/healthy-living/oral-health/Pages/Brushing-Up-on-Oral-Health-Never-Too-Early-to-Start.aspx',
  },
  eHcPreventDecay: {
    label: 'HealthyChildren.org (AAP) — How to prevent tooth decay in your baby',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/teething-tooth-care/Pages/How-to-Prevent-Tooth-Decay-in-Your-Baby.aspx',
  },
  eNhsDrinksCups: {
    label: 'NHS — Drinks and cups for babies and young children',
    url: 'https://www.nhs.uk/baby/weaning-and-feeding/drinks-and-cups-for-babies-and-young-children/',
  },
  nhsFlatHeadF: {
    label: 'NHS — Flat head syndrome (plagiocephaly and brachycephaly)',
    url: 'https://www.nhs.uk/conditions/flat-head-syndrome-plagiocephaly-brachycephaly/',
  },
  nhsBabyMovesF: {
    label: 'NHS Best Start in Life — Baby moves (tummy time)',
    url: 'https://www.nhs.uk/best-start-in-life/baby/baby-moves/',
  },
  nhsKeepActiveF: {
    label: 'NHS — How to keep your baby or toddler active',
    url: 'https://www.nhs.uk/baby/babys-development/play-and-learning/keep-baby-or-toddler-active/',
  },
  cdcMilestones4mF: {
    label: 'CDC — Learn the Signs. Act Early.: Milestones by 4 months',
    url: 'https://www.cdc.gov/act-early/milestones/4-months.html',
  },
  cdcMilestones9mF: {
    label: 'CDC — Learn the Signs. Act Early.: Milestones by 9 months',
    url: 'https://www.cdc.gov/act-early/milestones/9-months.html',
  },
  cdcMilestones15mF: {
    label: 'CDC — Learn the Signs. Act Early.: Milestones by 15 months',
    url: 'https://www.cdc.gov/act-early/milestones/15-months.html',
  },
  cdcMilestones2yF: {
    label: 'CDC — Learn the Signs. Act Early.: Milestones by 2 years',
    url: 'https://www.cdc.gov/act-early/milestones/2-years.html',
  },
  harvardServeReturnF: {
    label: 'Center on the Developing Child, Harvard University — Serve and return',
    url: 'https://developingchild.harvard.edu/key-concept/serve-and-return/',
  },
  hcSharedReadingF: {
    label:
      'HealthyChildren.org (AAP) — Beyond literacy: shared reading starting at birth offers lifelong benefits (2024)',
    url: 'https://www.healthychildren.org/English/news/Pages/beyond-literacy-shared-reading-starting-in-infancy-offers-lifelong-benefits.aspx',
  },
  hcShareBooksF: {
    label: 'HealthyChildren.org (AAP) — How to share books with your baby',
    url: 'https://www.healthychildren.org/English/ages-stages/baby/Pages/how-to-share-books-with-your-baby.aspx',
  },
  nhsLearnToTalkF: {
    label: 'NHS — Help your baby learn to talk',
    url: 'https://www.nhs.uk/baby/babys-development/play-and-learning/help-your-baby-learn-to-talk/',
  },
  hcAvoidTvF: {
    label: 'HealthyChildren.org (AAP) — Why to avoid TV for infants and toddlers',
    url: 'https://www.healthychildren.org/English/family-life/Media/Pages/Why-to-Avoid-TV-Before-Age-2.aspx',
  },
  hcInfantScreens5CsF: {
    label:
      "HealthyChildren.org (AAP) — Kids and screen time: the 5 C's questions to ask for infants",
    url: 'https://www.healthychildren.org/English/family-life/Media/Pages/infants-and-screen-time-5-cs-questions-to-ask.aspx',
  },
  hcDigitalWorld2026F: {
    label:
      'HealthyChildren.org (AAP) — Creating a child-friendly digital world: AAP releases new media recommendations (2026)',
    url: 'https://www.healthychildren.org/English/news/Pages/creating-a-child-friendly-digital-world-AAP-releases-new-media-recommendations.aspx',
  },
  hcLanguageDelayF: {
    label: 'HealthyChildren.org (AAP) — Language delay',
    url: 'https://www.healthychildren.org/English/ages-stages/toddler/Pages/Language-Delay.aspx',
  },
  hcSeparationAnxietyF: {
    label: "HealthyChildren.org (AAP) — How to ease your child's separation anxiety",
    url: 'https://www.healthychildren.org/English/ages-stages/toddler/Pages/Soothing-Your-Childs-Separation-Anxiety.aspx',
  },
  nhsSeparationAnxietyF: {
    label: 'NHS — Separation anxiety',
    url: 'https://www.nhs.uk/baby/babys-development/behaviour/separation-anxiety/',
  },
  nhsChildAnxietyF: {
    label: 'NHS — Anxiety in children',
    url: 'https://www.nhs.uk/mental-health/children-and-young-adults/advice-for-parents/anxiety-in-children/',
  },
  zttSeparationAnxietyF: {
    label: 'ZERO TO THREE — Separation anxiety',
    url: 'https://www.zerotothree.org/resource/separation-anxiety/',
  },
  vnChildHotline111F: {
    label: 'LuatVietnam — 111 là số Tổng đài quốc gia bảo vệ trẻ em (miễn phí)',
    url: 'https://luatvietnam.vn/tin-van-ban-moi/111-la-so-tong-dai-quoc-gia-bao-ve-tre-em-186-16851-article.html',
  },
  nhsBabyToddlerSafetyF: {
    label: 'NHS — Baby and toddler safety',
    url: 'https://www.nhs.uk/baby/first-aid-and-safety/safety/baby-and-toddler-safety/',
  },
  hcBabyWalkersF: {
    label: 'HealthyChildren.org (AAP) — Baby walkers: a dangerous choice',
    url: 'https://www.healthychildren.org/English/safety-prevention/at-home/Pages/baby-walkers-a-dangerous-choice.aspx',
  },
  nhsHeadInjuryF: {
    label: 'NHS — Head injury and concussion',
    url: 'https://www.nhs.uk/conditions/head-injury-and-concussion/',
  },
  whoVnDrowning2025F: {
    label:
      'WHO Viet Nam — Drowning rates not reducing fast enough, says the MOH, WHO and partners (2025)',
    url: 'https://www.who.int/vietnam/news/detail/25-07-2025-drowning-rates-not-reducing-fast-enough--says-the-moh--who-and-partners-on-world-drowning-prevention-day',
  },
  cpscAnchorItF: {
    label: 'U.S. CPSC — Anchor It! (furniture and TV tip-over prevention)',
    url: 'https://www.cpsc.gov/Safety-Education/Safety-Education-Centers/AnchorItgov',
  },
  khChokingF: {
    label: 'KidsHealth (Nemours) — Choking prevention',
    url: 'https://kidshealth.org/en/parents/choking.html',
  },
  hcCarSeatsFamiliesF: {
    label: 'HealthyChildren.org (AAP) — Car seats: information for families',
    url: 'https://www.healthychildren.org/English/safety-prevention/on-the-go/Pages/Car-Safety-Seats-Information-for-Families.aspx',
  },
  hcAirBagF: {
    label: 'HealthyChildren.org (AAP) — Air bag safety for children',
    url: 'https://www.healthychildren.org/English/safety-prevention/on-the-go/Pages/Air-Bag-Safety.aspx',
  },
  whoRoadInjuriesF: {
    label: 'WHO — Road traffic injuries (fact sheet)',
    url: 'https://www.who.int/news-room/fact-sheets/detail/road-traffic-injuries',
  },
  lsvnChildCarSeatLawF: {
    label:
      'Tạp chí Luật sư Việt Nam — Một số lưu ý về quy định mới đối với ô tô gia đình chở trẻ em từ 01/7 (khoản 3 Điều 10 Luật TTATGTĐB 2024, sửa đổi bởi Luật 118/2025/QH15)',
    url: 'https://lsvn.vn/mot-so-luu-y-ve-quy-dinh-moi-doi-voi-o-to-gia-dinh-cho-tre-em-tu-01-7-a174069.html',
  },
  vnRoadLawArt33F: {
    label: 'Luật Trật tự, an toàn giao thông đường bộ 2024 (số 36/2024/QH15) — Điều 33',
    url: 'https://hethongphapluat.com/luat-trat-tu-an-toan-giao-thong-duong-bo-2024/dieu-33',
  },
  nhsPndOverviewF: {
    label: 'NHS — Postnatal depression (symptoms, getting help, treatment)',
    url: 'https://www.nhs.uk/mental-health/conditions/postnatal-depression/',
  },
  nhsPostpartumPsychosisF: {
    label: 'NHS — Postpartum psychosis',
    url: 'https://www.nhs.uk/mental-health/conditions/post-partum-psychosis/',
  },
  whoPerinatalMentalHealthF: {
    label: 'WHO — Perinatal mental health',
    url: 'https://www.who.int/teams/mental-health-and-substance-use/promotion-prevention/perinatal-mental-health',
  },
  paternalDepressionMetaF: {
    label:
      'Paulson & Bazemore (JAMA 2010) — Prenatal and postpartum depression in fathers: a meta-analysis (RTI International)',
    url: 'https://www.rti.org/publication/prenatal-postpartum-depression-fathers-association-maternal-depression-meta-analysis',
  },
  ngayMaiHotlineF: {
    label: 'Đường dây nóng Ngày Mai — Dự án hỗ trợ người trẻ trầm cảm',
    url: 'https://duongdaynongngaymai.vn/',
  },
};

// ---------- Articles: Thư viện chăm bé and Ăn dặm ----------

export const seedArticles: SeedArticle[] = [
  // ----- Giấc ngủ & quấy khóc (sleep, crying) -----
  {
    id: 'art_newborn_sleep',
    reviewerLabel: PAEDS,
    data: {
      library: 'care',
      topic: 'sleep',
      format: 'article',
      ageWeeks: { from: 0, to: 13 },
      readingMinutes: 6,
      cover: null,
      title: t(
        'Giấc ngủ của bé sơ sinh: ngủ nhiều, giấc ngắn, thức dậy bú đêm',
        'Newborn sleep: lots of it, in short stretches, with night feeds',
      ),
      summary: t(
        'Bé sơ sinh ngủ nhiều nhưng từng giấc ngắn, thức dậy bú cả ngày lẫn đêm và chưa phân biệt ngày đêm. Hiểu đúng nhịp ngủ giúp ba mẹ bớt lo, cho bé bú đủ và đặt bé ngủ an toàn.',
        'Newborns sleep a lot, but in short stretches, waking to feed day and night without knowing day from night yet. Knowing this rhythm helps you worry less, feed enough and keep every sleep safe.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Trong 3 tháng đầu, bé ngủ nhiều giấc ngắn rải đều cả ngày lẫn đêm và thức dậy để bú. Đó là sinh lý bình thường, không phải bé “ngủ kém”. Ba mẹ cho bé bú theo nhu cầu, nhận ra sớm lúc bé buồn ngủ, và đặt bé nằm ngửa trên mặt phẳng chắc trong mọi giấc ngủ.',
          ),
          h('Hiểu đúng giấc ngủ của bé sơ sinh'),
          p(
            'Tổng thời gian ngủ của bé sơ sinh dao động khá rộng. Tài liệu của Viện Hàn lâm Nhi khoa Hoa Kỳ (AAP) nêu khoảng 16–17 tiếng mỗi ngày, Dịch vụ Y tế Anh (NHS) nói có thể khoảng 18 tiếng, nhưng mỗi giấc thường chỉ 1–2 tiếng. Hiệp hội Y học Giấc ngủ Hoa Kỳ (AASM) không đưa ra số giờ khuyến nghị cho bé dưới 4 tháng, vì ở tuổi này khoảng bình thường quá rộng. Vì vậy ba mẹ không cần so bé với một con số cố định.',
          ),
          p(
            'Bé hay thức vì dạ dày còn nhỏ và cần bú thường xuyên: trong vài tuần đầu, bé bú ít nhất 8–12 cữ, có khi nhiều hơn, trong 24 giờ, kể cả ban đêm. Bú đêm còn giúp duy trì nguồn sữa mẹ. Ngoài ra, một phần lớn giấc ngủ của bé là giấc ngủ động, tức ngủ nông: bé có thể cựa quậy, nhăn mặt, mỉm cười, ư ử, mắt động đậy dưới mí, nhịp thở lúc nhanh lúc chậm mà vẫn đang ngủ.',
          ),
          p(
            'Đồng hồ sinh học của bé chưa hoàn thiện. Nghiên cứu cho thấy nhịp tiết melatonin, nội tiết tố giúp buồn ngủ về đêm, thường chỉ rõ dần từ khoảng 9–12 tuần tuổi, và nhịp thức ngủ theo ngày đêm thường hình thành sau khoảng 2 tháng; ở bé sinh non có thể muộn hơn. Đến khoảng 4 tháng, chu kỳ ngủ của bé mới đều đặn hơn.',
          ),
          h('Ba mẹ có thể làm gì'),
          h('Nhận ra lúc bé buồn ngủ'),
          ul(
            'Dấu hiệu sớm: ánh mắt lơ đãng, nhìn xa xăm, quay mặt đi, cử động chậm lại, ngáp.',
            'Dấu hiệu muộn: dụi mắt, quấy, khóc, ưỡn người. Khi bé đã quá mệt, dỗ ngủ thường khó hơn.',
            'Thời gian bé thức thoải mái giữa hai giấc ở những tuần đầu khá ngắn, kể cả lúc bú. Hãy nhìn bé nhiều hơn nhìn đồng hồ.',
          ),
          h('Cho bú đủ, cả ngày lẫn đêm'),
          p(
            'Cho bé bú khi bé có dấu hiệu đói như mút tay, chép miệng, rúc tìm vú, đừng đợi đến lúc bé khóc to. Nếu bé ngủ li bì, khó đánh thức để bú, đang vàng da, sinh non hoặc chưa lấy lại cân nặng lúc sinh, hãy hỏi bác sĩ hay nữ hộ sinh xem có cần đánh thức bé để bú không và sau bao lâu. Khi bé đã tăng cân tốt, bác sĩ sẽ cho biết ba mẹ có thể chờ bé tự thức hay không.',
          ),
          h('Ban đêm'),
          ul(
            'Dùng đèn mờ, nói khẽ, hạn chế chơi đùa khi cho bú hay thay tã đêm.',
            'Khi bé cựa quậy, ư ử, hãy chờ một chút xem bé có tự ngủ lại không trước khi bế lên; nếu bé đói thật thì cho bú.',
            'Ban ngày để phòng sáng, sinh hoạt bình thường, giúp bé dần nhận ra ngày và đêm.',
          ),
          h('Mỗi giấc ngủ đều cần an toàn'),
          ul(
            'Đặt bé nằm ngửa trong mọi giấc ngủ, kể cả giấc ngủ ngắn ban ngày.',
            'Nôi hoặc cũi có nệm phẳng, chắc, ga bọc chặt; không gối, chăn dày, thú bông, quây đệm.',
            'Bé ngủ chung phòng với ba mẹ nhưng trên chỗ ngủ riêng, ít nhất trong 6 tháng đầu.',
            'Phòng thoáng, không để bé quá nóng, không đội mũ khi ngủ trong nhà, không khói thuốc.',
            'Nếu bé ngủ quên trên ghế ô tô, xe đẩy, địu hay ghế rung, chuyển bé sang nằm ngửa trên mặt phẳng khi có thể.',
          ),
          tip(
            'Ba mẹ cũng cần ngủ',
            'Tranh thủ chợp mắt khi bé ngủ và chia ca đêm với người thân, ví dụ vắt sẵn sữa để người kia cho bé bú một cữ. Khi thấy mình quá mệt, đừng ôm bé nằm trên sofa hay ghế bành, vì rất dễ ngủ quên.',
          ),
          h('Theo dõi'),
          p(
            'Ghi lại cữ bú, tã ướt và giấc ngủ trong vài ngày, có thể ghi trong Child Life, giúp ba mẹ thấy nhịp của bé và có thông tin rõ ràng khi đi khám.',
          ),
          ul(
            'Số cữ bú trong 24 giờ và bé có bú hăng không.',
            'Tã ướt, phân đều đặn mỗi ngày; bé tăng cân đúng hẹn khám.',
            'Bé có dễ đánh thức để bú không; lúc thức có tỉnh táo, nhìn theo mặt người không.',
            'Màu da (vàng da) và nhịp thở khi ngủ.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            '“Bé ngủ càng nhiều càng tốt, cứ để ngủ cho ngoan”: nhiều nhà vì thương con nên không nỡ đánh thức. Nhưng bé sơ sinh ngủ li bì, bỏ nhiều cữ bú có thể là dấu hiệu bé mệt, vàng da nặng hoặc chưa đủ sữa. Nên: cho bú ít nhất 8–12 cữ một ngày và hỏi bác sĩ nếu bé khó đánh thức để bú.',
            '“Cho bé ăn bột, uống nước cháo cho no lâu, ngủ dài”: ông bà mong cháu no và ngủ ngon. Nhưng ăn sớm không giúp bé ngủ xuyên đêm, và bé dưới 6 tháng chỉ cần sữa mẹ hoặc sữa công thức. Nên: bú theo nhu cầu, đợi khoảng 6 tháng mới bắt đầu ăn dặm.',
            '“Bé giật mình, vặn mình khi ngủ là do thiếu canxi”: phần lớn là phản xạ giật mình và cử động của giấc ngủ động, rất thường gặp ở bé khoẻ. Nên: không tự cho bé uống canxi hay thuốc; nếu bé co giật, mắt trợn, tím tái hoặc lả đi, gọi 115.',
            '“Ủ bé thật ấm, đội mũ, đắp chăn dày cho bé ngủ ngon”: ông bà làm vì sợ cháu lạnh. Nhưng quá nóng làm tăng nguy cơ đột tử và chăn dày có thể trùm lên mặt bé. Nên: mặc cho bé nhiều hơn người lớn tối đa một lớp mỏng, không đội mũ khi ngủ trong nhà, sờ ngực hoặc gáy để kiểm tra.',
          ),
          doctor(
            'Gọi 115 hoặc đến cấp cứu ngay khi',
            'Bé khó thở, thở rút lõm ngực, thở rên; môi hoặc mặt tím tái, xám; bé lả mềm, không phản ứng hoặc rất khó đánh thức; bé co giật; thóp phồng.',
          ),
          doctor(
            'Đưa bé đi khám trong ngày khi',
            'Bé dưới 3 tháng có nhiệt độ từ 38 °C trở lên; bỏ bú hoặc bú rất kém nhiều cữ liền; ít tã ướt hơn hẳn bình thường; vàng da lan rộng hoặc đậm lên; khóc thét hoặc khóc yếu khác thường; ngáy to kèm những lúc ngừng thở khi ngủ.',
          ),
        ],
        en: [
          note(
            'In short',
            'In the first 3 months, babies sleep in many short stretches spread across day and night, waking to feed. That is normal physiology, not "bad sleep". Feed on demand, spot sleepy cues early, and lay your baby on their back on a firm, flat surface for every sleep.',
          ),
          h('Understanding newborn sleep'),
          p(
            "Total sleep in newborns varies widely. The American Academy of Pediatrics (AAP) says about 16–17 hours a day and the UK's NHS says it can be around 18 hours, but each stretch is often only 1–2 hours. The American Academy of Sleep Medicine (AASM) gives no recommended hours for babies under 4 months because the normal range is so wide at this age. So there is no need to measure your baby against one fixed number.",
          ),
          p(
            "Babies wake often because their tummies are small and they need frequent feeds: in the first few weeks they feed at least 8–12 times, sometimes more, in 24 hours, nights included. Night feeds also help keep up the breast milk supply. On top of that, a large share of a newborn's sleep is active, light sleep: your baby may wriggle, grimace, smile, grunt, move their eyes under the lids and breathe faster then slower, and still be asleep.",
          ),
          p(
            "Your baby's body clock is not mature yet. Research shows that the rhythm of melatonin, the hormone that makes us sleepy at night, usually only becomes clear from about 9–12 weeks, and a day–night sleep–wake rhythm usually develops after about 2 months; it may come later in babies born early. Sleep cycles become more regular at around 4 months.",
          ),
          h('What you can do'),
          h('Spotting sleepiness'),
          ul(
            'Early signs: a faraway gaze, staring into space, turning away, slower movements, yawning.',
            'Late signs: rubbing eyes, fussing, crying, arching. Once a baby is overtired, settling is usually harder.',
            'In the early weeks the time a baby can stay happily awake between sleeps is short, feeds included. Watch your baby more than the clock.',
          ),
          h('Feeding enough, day and night'),
          p(
            'Feed when your baby shows hunger cues such as sucking hands, smacking lips or rooting for the breast, rather than waiting for loud crying. If your baby is very drowsy and hard to wake for feeds, has jaundice, was born early or has not yet regained birth weight, ask your doctor or midwife whether to wake them for feeds and how often. Once your baby is gaining well, the doctor will tell you whether you can wait for them to wake.',
          ),
          h('At night'),
          ul(
            'Use dim light, speak softly and keep play to a minimum during night feeds and diaper changes.',
            'When your baby stirs or grunts, wait a moment to see if they settle back before picking them up; if they are truly hungry, feed them.',
            'Keep daytime bright with normal household activity so your baby gradually learns day from night.',
          ),
          h('Every sleep should be a safe sleep'),
          ul(
            'Lay your baby on their back for every sleep, including short daytime naps.',
            'Use a crib or bassinet with a firm, flat mattress and a fitted sheet; no pillows, thick blankets, soft toys or bumpers.',
            'Have your baby sleep in your room but in their own sleep space, for at least the first 6 months.',
            'Keep the room airy, do not let your baby overheat, no hat for sleep indoors, no smoke.',
            'If your baby falls asleep in a car seat, stroller, carrier or bouncer, move them onto their back on a flat surface when you can.',
          ),
          tip(
            'You need sleep too',
            "Nap when your baby sleeps and share night duty with family, for example by expressing milk so someone else can do one feed. If you feel very tired, don't lie down holding your baby on a sofa or armchair, because it is very easy to fall asleep.",
          ),
          h('What to watch'),
          p(
            'Noting feeds, wet diapers and sleep for a few days, for example in Child Life, helps you see your baby’s rhythm and gives clear information to share at check-ups.',
          ),
          ul(
            'How many feeds in 24 hours, and whether your baby feeds eagerly.',
            'Wet diapers and regular stools each day; weight gain at check-ups.',
            'Whether your baby wakes easily for feeds and is alert when awake, following faces.',
            'Skin colour (jaundice) and breathing during sleep.',
          ),
          h('Common misconceptions'),
          ul(
            '"The more a baby sleeps, the better, just let them sleep": many families can’t bear to wake a sleeping baby. But a newborn who is very drowsy and skips many feeds may be unwell, have significant jaundice or not be getting enough milk. Instead: feed at least 8–12 times a day and ask a doctor if your baby is hard to wake for feeds.',
            '"Give rice cereal or rice water so the baby stays full and sleeps longer": grandparents hope the baby will be full and sleep well. But early solids do not help babies sleep through the night, and under 6 months babies need only breast milk or formula. Instead: feed on demand and wait until around 6 months to start solids.',
            '"Startling and squirming in sleep means a calcium deficiency": most of it is the startle reflex and the movements of active sleep, very common in healthy babies. Instead: do not give calcium or any medicine on your own; if your baby has a fit, eyes rolling, turns blue or goes limp, call 115.',
            '"Wrap the baby warmly, add a hat and a thick blanket for good sleep": grandparents do this for fear of the cold. But overheating raises the risk of sudden infant death and thick blankets can cover the face. Instead: dress your baby in at most one light layer more than an adult, no hat for sleep indoors, and feel the chest or back of the neck to check.',
          ),
          doctor(
            'Call 115 or go to the emergency department now if',
            'Your baby has trouble breathing, the chest pulls in or they grunt with each breath; lips or face look blue or grey; they are limp, unresponsive or very hard to wake; they have a fit; the soft spot (fontanelle) bulges.',
          ),
          doctor(
            'See a doctor the same day if',
            'Your baby is under 3 months with a temperature of 38 °C or higher; refuses or feeds very poorly for several feeds in a row; has far fewer wet diapers than usual; jaundice spreads or deepens; has a high-pitched or unusually weak cry; snores loudly with pauses in breathing during sleep.',
          ),
        ],
      },
      keywords: t(
        [
          'ngủ',
          'sơ sinh',
          'giấc ngủ ngắn',
          'thức đêm',
          'bú đêm',
          'dấu hiệu buồn ngủ',
          'giấc ngủ động',
          'đồng hồ sinh học',
        ],
        [
          'sleep',
          'newborn',
          'short naps',
          'night waking',
          'night feeds',
          'sleepy cues',
          'active sleep',
          'body clock',
        ],
      ),
      relatedArticleIds: [
        'art_safe_sleep',
        'art_day_night',
        'art_breastfeeding_start',
        'art_crying_colic',
      ],
      milestoneIds: [],
      sources: [
        S.nhsSleep,
        S.aHcGettingBabyToSleep,
        S.aAasmSleepDuration,
        S.aNhsBreastfeedingFirstDays,
        S.aHcFeedingHowOften,
        S.aPmKennawayMelatonin,
        S.aPmRivkeesCircadian,
        S.hcSafeSleep,
      ],
    },
  },
  {
    id: 'art_safe_sleep',
    reviewerLabel: PAEDS,
    data: {
      library: 'care',
      topic: 'sleep',
      format: 'article',
      ageWeeks: { from: 0, to: 52 },
      readingMinutes: 6,
      cover: null,
      title: t(
        'Ngủ an toàn, phòng đột tử: nằm ngửa, nôi riêng, mặt phẳng chắc',
        'Safe sleep and SIDS: on the back, own crib, firm flat surface',
      ),
      summary: t(
        'Mỗi giấc ngủ của bé, ngày hay đêm, đều nên an toàn cho đến khi bé tròn 1 tuổi. Vài thói quen đơn giản giúp giảm rõ rệt nguy cơ đột tử và ngạt khi ngủ.',
        'Every sleep, day or night, should be a safe sleep until your baby turns one. A few simple habits clearly lower the risk of sudden infant death and suffocation in sleep.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Đặt bé nằm ngửa, một mình, trên nệm phẳng và chắc trong nôi hoặc cũi riêng đặt trong phòng ba mẹ, ít nhất 6 tháng đầu. Không gối, chăn dày, gối chặn, quây đệm; không để bé quá nóng; không khói thuốc. Bú mẹ và cho ngậm ti giả khi ngủ cũng giúp giảm nguy cơ.',
          ),
          h('Hiểu đúng về đột tử và ngạt khi ngủ'),
          p(
            'Hội chứng đột tử ở trẻ sơ sinh (SIDS) là khi một bé khoẻ mạnh tử vong đột ngột trong lúc ngủ mà không tìm ra nguyên nhân. Bên cạnh đó còn có các tai nạn khi ngủ như ngạt do chăn gối, bị người lớn đè, kẹt giữa nệm và tường. Chỉ riêng ở Mỹ, mỗi năm khoảng 3.500 trẻ tử vong liên quan đến giấc ngủ. Phần lớn các ca này có thể giảm nguy cơ bằng cách sắp xếp chỗ ngủ đúng, và các khuyến nghị dưới đây áp dụng cho mọi giấc ngủ đến khi bé tròn 1 tuổi.',
          ),
          p(
            'Bé nhỏ chưa đủ sức quay đầu hay đẩy vật mềm ra khỏi mặt. Khi nằm sấp, nằm nghiêng hoặc úp mặt vào gối, chăn, đường thở của bé dễ bị cản trở. Nằm nghiêng gần như nguy hiểm ngang nằm sấp vì bé rất dễ lật úp. Bé bị trào ngược cũng nên ngủ nằm ngửa trên mặt phẳng.',
          ),
          h('Ba mẹ có thể làm gì'),
          ul(
            'Nằm ngửa trong mọi giấc ngủ, ngày cũng như đêm. Khi bé đã tự lật được cả hai chiều, có thể để bé tự chọn tư thế, nhưng lúc đặt xuống vẫn đặt nằm ngửa.',
            'Mặt phẳng, chắc, không dốc: nôi, cũi hoặc cũi gấp có nệm vừa khít, chỉ dùng ga bọc chặt. Bề mặt dốc hơn 10 độ không an toàn cho bé ngủ.',
            'Chỗ ngủ trống: không gối, chăn dày, nệm lót mềm, thú bông, quây đệm, gối chặn hay đồ định vị tư thế. Cần giữ ấm thì dùng túi ngủ mặc được hoặc mặc thêm một lớp áo.',
            'Chung phòng, riêng giường: đặt nôi của bé cạnh giường ba mẹ, ít nhất trong 6 tháng đầu. Cách này có thể giảm nguy cơ đột tử tới 50%.',
            'Không ngủ cùng bé trên sofa hay ghế bành: nguy cơ ở đây cao hơn giường rất nhiều.',
            'Không quá nóng: mặc cho bé nhiều hơn người lớn tối đa một lớp; không đội mũ khi ngủ trong nhà; phòng thoáng. Bé ra mồ hôi, nóng ngực, da đỏ là đang quá nóng.',
            'Không dùng chăn, túi ngủ hay đồ quấn có gắn vật nặng, và không chèn túi gạo hay vật nặng lên người bé.',
            'Bú mẹ nếu có thể: sữa mẹ giúp giảm nguy cơ đột tử, bú càng lâu càng được bảo vệ.',
            'Ti giả: có thể cho bé ngậm khi đặt ngủ, không cần nhét lại khi ti rơi ra; với bé bú mẹ, đợi đến khi việc bú mẹ đã ổn định. Không đeo ti giả vào cổ hay ghim vào áo bé.',
            'Không khói thuốc: không hút thuốc lá, thuốc lá điện tử khi mang thai, trong nhà, trên xe hay gần bé.',
            'Cho bé tiêm chủng đầy đủ, đúng lịch.',
            'Ghế ô tô, xe đẩy, xích đu, địu không phải chỗ ngủ: nếu bé ngủ quên trên đó, chuyển bé sang nằm ngửa trên mặt phẳng ngay khi có thể.',
          ),
          h('Nếu gia đình vẫn ngủ chung giường'),
          p(
            'Các tổ chức chưa hoàn toàn thống nhất ở điểm này: AAP khuyên không ngủ chung giường với bé trong bất kỳ hoàn cảnh nào, còn NHS (Anh) hướng dẫn cách ngủ chung bớt nguy hiểm vì biết nhiều gia đình vẫn làm vậy. Lựa chọn an toàn nhất vẫn là nôi riêng sát giường ba mẹ. Nếu bé ngủ chung giường, dù có chủ đích hay lỡ ngủ quên khi cho bú, hãy:',
          ),
          ul(
            'Dùng nệm phẳng, chắc; đặt bé nằm ngửa, tránh xa gối và chăn; không quấn bé.',
            'Không để trẻ khác hay vật nuôi ngủ cùng; không bao giờ để bé một mình trên giường người lớn.',
            'Bảo đảm bé không thể rơi xuống hay kẹt giữa nệm và tường.',
            'Không ngủ chung nếu bé sinh non (trước 37 tuần) hoặc nặng dưới 2,5 kg lúc sinh; nếu ba hoặc mẹ hút thuốc, đã uống rượu bia, dùng chất kích thích hay thuốc gây buồn ngủ, hoặc đang quá mệt.',
          ),
          h('Theo dõi'),
          ul(
            'Mỗi lần đặt bé ngủ, nhìn nhanh: bé nằm ngửa, đầu và mặt không bị che, trong nôi không có đồ mềm.',
            'Khi bé có dấu hiệu tập lật, ngừng quấn ngay và kiểm tra nôi không có khe hở dễ kẹt.',
            'Hình dạng đầu: nếu một bên đầu bẹt, tăng thời gian nằm sấp chơi khi bé thức, đổi đầu nằm của bé trong nôi, bế và cho bú đổi tay.',
            'Ông bà, người giúp việc, nhà trẻ có biết và làm đúng các nguyên tắc này không.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            '“Cho bé nằm sấp ngủ cho ngon giấc, đầu tròn đẹp”: nhiều gia đình tin vậy vì thấy bé nằm sấp ngủ say hơn. Nhưng nằm sấp làm tăng rõ nguy cơ đột tử. Nên: luôn đặt bé nằm ngửa khi ngủ; cho bé nằm sấp chơi khi bé thức và có người lớn trông.',
            '“Dùng gối lõm chống méo đầu, gối chặn hai bên cho bé khỏi lật”: ba mẹ mua vì thương con. Nhưng FDA (Hoa Kỳ) cảnh báo đồ định vị tư thế có thể gây ngạt, AAP cho biết gối chỉnh đầu không an toàn và không có bằng chứng hiệu quả. Đầu bẹt do tư thế chủ yếu là vấn đề thẩm mỹ, không ảnh hưởng não. Nên: nằm sấp chơi khi thức, đổi hướng nằm.',
            '“Cho bé ngủ võng cho êm, dễ ru”: võng rất quen thuộc với nhiều nhà. Nhưng võng cong, mềm, không phẳng; bé dễ gập cằm vào ngực hoặc úp mặt vào vải. Nên: có thể đưa võng nhẹ để dỗ khi có người lớn ngồi cạnh, nhưng khi bé đã ngủ thì chuyển bé sang nằm ngửa trong nôi.',
            '“Bà ôm cháu ngủ chung cho ấm, cho cháu khỏi giật mình”: tình thương của ông bà rất quý. Nhưng giường người lớn có chăn gối mềm, người lớn ngủ say có thể đè lên bé. Nên: bà dỗ cháu ngủ rồi đặt cháu vào nôi sát giường; nếu vẫn ngủ chung, làm theo các điều ở phần trên.',
          ),
          doctor(
            'Gọi 115 hoặc đến cấp cứu ngay khi',
            'Bé ngừng thở, tím tái, da xám hoặc nhợt, mềm nhũn, không phản ứng. Trong lúc chờ, làm theo hướng dẫn Hồi sức tim phổi (CPR) trong mục Sơ cứu trẻ em của Child Life.',
          ),
          doctor(
            'Khi nào nên hỏi bác sĩ',
            'Bé ngáy to, thở khò khè hoặc có những lúc ngừng thở khi ngủ; bé hay trào ngược khiến ba mẹ lo khi cho nằm ngửa; đầu bé bẹt rõ một bên hoặc bé luôn quay đầu về một phía; bé sinh non hoặc có bệnh lý cần hướng dẫn chỗ ngủ riêng.',
          ),
        ],
        en: [
          note(
            'In short',
            "Lay your baby on their back, alone, on a firm flat mattress in their own crib or bassinet in your room, for at least the first 6 months. No pillows, thick blankets, side positioners or bumpers; don't let your baby overheat; no smoke. Breastfeeding and offering a pacifier for sleep also lower the risk.",
          ),
          h('Understanding sudden infant death and sleep accidents'),
          p(
            'Sudden infant death syndrome (SIDS) is when a healthy baby dies suddenly during sleep and no cause is found. There are also sleep accidents such as suffocation in bedding, being rolled on by an adult, or getting trapped between mattress and wall. In the United States alone, about 3,500 babies die each year from sleep-related causes. Much of this risk can be lowered by setting up sleep correctly, and the advice below applies to every sleep until your baby turns one.',
          ),
          p(
            "Young babies aren't strong enough to turn their head or push soft things away from their face. Lying on the tummy or side, or with the face pressed into a pillow or blanket, can block the airway. Side sleeping is nearly as dangerous as tummy sleeping because babies easily roll face down. Babies with reflux should also sleep on their back on a flat surface.",
          ),
          h('What you can do'),
          ul(
            'On the back for every sleep, day and night. Once your baby can roll both ways on their own, they can choose their position, but still lay them down on their back.',
            'Flat, firm, not tilted: a crib, bassinet or play yard with a snug-fitting mattress and only a fitted sheet. Any surface inclined more than 10 degrees is unsafe for sleep.',
            'A clear sleep space: no pillows, thick blankets, soft mattress toppers, soft toys, bumpers, side positioners or other positioning devices. For warmth, use a wearable sleep sack or one extra layer of clothing.',
            "Same room, separate bed: put your baby's crib next to your bed for at least the first 6 months. This can lower the risk of SIDS by up to 50%.",
            'Never sleep with your baby on a sofa or armchair: the risk there is far higher than in a bed.',
            'Not too warm: dress your baby in at most one layer more than an adult; no hat for sleep indoors; keep the room airy. Sweating, a hot chest or flushed skin mean your baby is too hot.',
            'Do not use weighted blankets, weighted sleep sacks or weighted swaddles, and never place rice bags or other weights on your baby.',
            'Breastfeed if you can: breast milk lowers the risk of SIDS, and the longer it is given the more it protects.',
            "Pacifier: you can offer one when you lay your baby down, and there's no need to put it back if it falls out; for breastfed babies, wait until breastfeeding is well established. Never hang a pacifier around the neck or clip it to clothing.",
            'No smoke: no cigarettes or e-cigarettes during pregnancy, at home, in the car or near your baby.',
            'Keep vaccinations complete and on schedule.',
            'Car seats, strollers, swings and carriers are not for sleep: if your baby falls asleep in one, move them onto their back on a flat surface as soon as you can.',
          ),
          h('If your family still shares a bed'),
          p(
            "Organisations don't fully agree here: the AAP advises against bed-sharing under any circumstances, while the UK's NHS gives advice on making it less dangerous because many families do it. The safest choice is still a separate crib right next to your bed. If your baby does end up in your bed, planned or after dozing off during a feed:",
          ),
          ul(
            'Use a firm, flat mattress; lay your baby on their back, away from pillows and covers; do not swaddle.',
            'No other children or pets in the bed; never leave your baby alone in an adult bed.',
            'Make sure your baby cannot fall out or get trapped between the mattress and the wall.',
            'Do not bed-share if your baby was born early (before 37 weeks) or weighed under 2.5 kg at birth, or if either parent smokes, has drunk alcohol, has taken drugs or medicine that causes drowsiness, or is extremely tired.',
          ),
          h('What to watch'),
          ul(
            'Each time you lay your baby down, check quickly: on the back, head and face uncovered, nothing soft in the crib.',
            'When your baby shows signs of trying to roll, stop swaddling straight away and check the crib has no gaps your baby could get trapped in.',
            "Head shape: if one side looks flat, give more supervised tummy time while awake, alternate which end of the crib your baby's head is at, and switch arms when holding and feeding.",
            'Whether grandparents, helpers and childcare staff know and follow these rules.',
          ),
          h('Common misconceptions'),
          ul(
            '"Tummy sleeping helps babies sleep deeply and gives a nice round head": many families believe this because babies seem to sleep more soundly on their tummy. But tummy sleeping clearly raises the risk of SIDS. Instead: always lay your baby on their back to sleep; give tummy time while awake with an adult watching.',
            '"Use a hollow anti-flat-head pillow and bolsters on both sides so the baby can’t roll": parents buy these out of love. But the US FDA warns that sleep positioners can cause suffocation, and the AAP says head-shaping pillows are unsafe with no evidence they work. Positional flat head is mainly cosmetic and does not affect the brain. Instead: tummy time while awake, vary head position.',
            '"Let the baby sleep in a hammock, it’s soft and easy to rock": hammocks are part of daily life in many homes. But a hammock is curved, soft and not flat; a baby can easily slump chin to chest or press their face into the fabric. Instead: you can gently swing the hammock to soothe while an adult sits right there, but once your baby is asleep, move them onto their back in a crib.',
            '"Grandma cuddles the baby in her bed to keep warm and stop the startles": grandparents’ love is precious. But adult beds have soft pillows and covers, and a deeply sleeping adult can roll onto a baby. Instead: grandma can settle the baby, then lay them in a crib next to the bed; if you still share a bed, follow the steps above.',
          ),
          doctor(
            'Call 115 or go to the emergency department now if',
            'Your baby stops breathing, turns blue, grey or very pale, goes floppy or does not respond. While you wait, follow the CPR guide in the Sơ cứu trẻ em (First aid) section of Child Life.',
          ),
          doctor(
            'When to ask a doctor',
            'Your baby snores loudly, wheezes or seems to pause breathing in sleep; reflux makes you worried about back sleeping; one side of the head is clearly flat or your baby always turns their head one way; your baby was born early or has a condition that needs specific sleep advice.',
          ),
        ],
      },
      keywords: t(
        [
          'ngủ an toàn',
          'đột tử',
          'SIDS',
          'nằm ngửa',
          'ngủ chung giường',
          'ngủ chung phòng',
          'gối chặn',
          'ngủ võng',
          'quá nóng',
          'ti giả',
        ],
        [
          'safe sleep',
          'sudden infant death',
          'SIDS',
          'back to sleep',
          'bed-sharing',
          'room-sharing',
          'sleep positioner',
          'hammock',
          'overheating',
          'pacifier',
        ],
      ),
      relatedArticleIds: [
        'art_newborn_sleep',
        'art_swaddling',
        'art_tummy_time',
        'art_sleep_by_age',
      ],
      milestoneIds: ['rolls_over'],
      sources: [
        S.aAapSafeSleep2022News,
        S.aPmMoonSafeSleep2022,
        S.hcSafeSleep,
        S.nhsSids,
        S.aFdaPositioners,
        S.aHcHeadShape,
      ],
    },
  },
  {
    id: 'art_day_night',
    reviewerLabel: PAEDS,
    data: {
      library: 'care',
      topic: 'sleep',
      format: 'article',
      ageWeeks: { from: 2, to: 26 },
      readingMinutes: 5,
      cover: null,
      title: t('Giúp bé phân biệt ngày và đêm', 'Helping your baby tell day from night'),
      summary: t(
        'Đồng hồ sinh học của bé hình thành dần trong vài tháng đầu. Ánh sáng ban ngày, đêm tối yên tĩnh và một nếp đi ngủ đều đặn giúp bé dần ngủ dài hơn về đêm.',
        "Your baby's body clock develops gradually over the first few months. Daylight, calm dark nights and a steady bedtime routine help your baby slowly sleep longer at night.",
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Bé mới sinh chưa biết ngày và đêm; nhịp này thường rõ dần sau khoảng 2–3 tháng. Ba mẹ giúp bé bằng ánh sáng và sinh hoạt ban ngày, đêm tối và yên, cùng một nếp đi ngủ ngắn lặp lại mỗi tối. Bú đêm vẫn bình thường trong nhiều tháng.',
          ),
          h('Hiểu đúng đồng hồ sinh học của bé'),
          p(
            'Sau khi chào đời, bé phải tự xây dựng đồng hồ sinh học của mình. Các nghiên cứu cho thấy nhịp thức ngủ và nhịp tiết nội tiết tố theo ngày đêm thường rõ dần sau khoảng 2 tháng tuổi; melatonin, chất giúp cơ thể buồn ngủ về đêm, bắt đầu được tiết theo nhịp từ khoảng 9–12 tuần. Ở bé sinh non, nhịp này thường hình thành muộn hơn.',
          ),
          p(
            'Ánh sáng là một tín hiệu quan trọng để chỉnh đồng hồ này. Một nghiên cứu theo dõi bé 6–12 tuần tuổi tại nhà thấy những bé ngủ đêm tốt hơn được tiếp xúc nhiều ánh sáng hơn vào đầu giờ chiều. Vì vậy các hướng dẫn đều khuyên giữ ban ngày sáng, sinh động và ban đêm tối, yên.',
          ),
          p(
            'Ngay cả khi đồng hồ sinh học đã hình thành, bé vẫn thức dậy để bú. Từ 3–6 tháng, một số bé ngủ một mạch 5–8 tiếng hoặc hơn vào ban đêm, nhưng không phải bé nào cũng vậy, và điều đó không có nghĩa là bé có vấn đề.',
          ),
          h('Ba mẹ có thể làm gì'),
          h('Ban ngày: sáng và sinh động'),
          ul(
            'Buổi sáng mở rèm, cho bé ở nơi có ánh sáng tự nhiên; tránh để nắng gắt chiếu thẳng vào bé.',
            'Trò chuyện, hát, chơi và cho bé nằm sấp chơi khi bé thức, có người lớn trông.',
            'Giấc ngủ ngày có thể diễn ra trong tiếng sinh hoạt bình thường, không cần tối om hay im phăng phắc.',
            'AAP gợi ý không để một giấc ngủ ngày kéo dài quá 3 tiếng; có thể nhẹ nhàng đánh thức bé để bú và chơi. Nhưng đừng cắt bớt giấc ngủ ngày khi bé đang buồn ngủ, vì bé quá mệt thường khó ngủ hơn.',
          ),
          h('Ban đêm: tối, yên và nhẹ nhàng'),
          ul(
            'Dùng đèn ngủ mờ khi cho bú, thay tã; tránh bật đèn sáng.',
            'Nói khẽ, ít nhìn vào mắt và không chơi đùa; xong cữ bú, thay tã thì đặt bé lại vào nôi.',
            'Chỉ thay tã đêm khi cần, ví dụ tã bẩn hoặc quá ướt.',
            'Khi bé lớn hơn, tập đặt bé xuống lúc bé buồn ngủ nhưng còn thức để bé quen tự chìm vào giấc ngủ; ở bé sơ sinh không phải lúc nào cũng làm được, không sao cả.',
          ),
          h('Một nếp đi ngủ đơn giản'),
          p(
            'Từ khoảng 2–3 tháng, ba mẹ có thể bắt đầu một nếp ngắn mỗi tối theo cùng thứ tự, ví dụ: lau người hoặc tắm, thay tã và đồ ngủ, giảm bớt đèn, bú, hát một bài ru quen rồi đặt bé vào nôi. Quan trọng là lặp lại đều đặn, không cần cầu kỳ. Giờ đi ngủ tương đối cố định mỗi tối cũng giúp nhịp ngủ của bé ổn định hơn.',
          ),
          tip(
            'Nhất quán quan trọng hơn hoàn hảo',
            'Cả nhà nên thống nhất vài tín hiệu chính: sáng sủa ban ngày, đèn mờ ban đêm, cùng một bài hát ru. Khi bé ốm hay đi chơi xa, nếp ngủ có thể xáo trộn; hãy nhẹ nhàng quay lại nếp cũ khi mọi thứ ổn định.',
          ),
          h('Theo dõi'),
          p(
            'Ghi lại giờ ngủ, giờ thức và các cữ bú trong vài ngày giúp ba mẹ thấy bé đang dần ngủ nhiều hơn về đêm, kể cả khi từng đêm còn chập chờn.',
          ),
          ul(
            'Tổng giấc ngủ đêm và giấc dài nhất trong đêm có tăng dần theo tuần không.',
            'Bé có tỉnh táo, vui vẻ khi thức, bú tốt và tăng cân đều không.',
            'Bé có hay khóc nhiều vào chiều tối không; khóc chiều tối rất thường gặp ở những tuần đầu và giảm dần.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            '“Bé ngủ ngày cả buổi là ngoan, cứ để ngủ, tối thức thì thay nhau bế”: nhiều nhà nghĩ vậy cho đỡ vất vả ban ngày. Nhưng giấc ngày quá dài dễ khiến bé thức chơi về đêm. Nên: nếu một giấc ngày kéo dài quá 3 tiếng, nhẹ nhàng đánh thức bé để bú và chơi trong ánh sáng.',
            '“Phải giữ phòng tối om, cấm mọi tiếng động cả ngày cho bé ngủ”: ý định rất tốt, nhưng bé cần ánh sáng và âm thanh ban ngày để phân biệt ngày đêm. Nên: ban ngày sinh hoạt bình thường, chỉ giữ tối và yên vào ban đêm.',
            '“Cho bé ăn bột sớm, pha sữa đặc hơn để bé no lâu, ngủ xuyên đêm”: ông bà mong cháu no bụng. Nhưng ăn dặm sớm không giúp bé ngủ xuyên đêm, còn cho thêm bột sữa quá hướng dẫn có thể làm bé táo bón hoặc mất nước. Nên: pha đúng tỷ lệ trên hộp, đợi khoảng 6 tháng mới ăn dặm.',
          ),
          doctor(
            'Khi nào nên hỏi bác sĩ',
            'Bé ngủ li bì, khó đánh thức để bú; bú kém, ít tã ướt hoặc chậm tăng cân; khóc thét, khóc kéo dài rất khó dỗ; ngáy to kèm những lúc ngừng thở. Đưa bé đi khám trong ngày nếu bé dưới 3 tháng có nhiệt độ từ 38 °C trở lên. Gọi 115 nếu bé khó thở, tím tái, co giật hoặc lả mềm.',
          ),
        ],
        en: [
          note(
            'In short',
            'Newborns cannot tell day from night yet; this rhythm usually becomes clearer after about 2–3 months. Help your baby with light and activity by day, dark quiet nights, and a short bedtime routine repeated each evening. Night feeds remain normal for many months.',
          ),
          h("Understanding your baby's body clock"),
          p(
            'After birth, babies have to build their own body clock. Studies show that day–night rhythms in sleep and hormones usually become clearer after about 2 months; melatonin, which makes the body sleepy at night, starts being released in a rhythm from about 9–12 weeks. In babies born early, this rhythm usually develops later.',
          ),
          p(
            'Light is an important signal for setting this clock. A study that followed babies aged 6–12 weeks at home found that those who slept better at night had more light exposure in the early afternoon. That is why guidance consistently says to keep days bright and lively and nights dark and quiet.',
          ),
          p(
            "Even once the body clock is in place, babies still wake to feed. From 3–6 months some babies sleep 5–8 hours or more at a stretch at night, but not all do, and that doesn't mean anything is wrong.",
          ),
          h('What you can do'),
          h('Daytime: bright and lively'),
          ul(
            'Open the curtains in the morning and keep your baby in natural light; avoid harsh direct sun on your baby.',
            'Talk, sing and play, and give supervised tummy time while your baby is awake.',
            "Daytime naps can happen with normal household sounds; it doesn't need to be pitch dark or silent.",
            "The AAP suggests not letting any one daytime nap go beyond 3 hours; you can gently wake your baby to feed and play. But don't cut naps short when your baby is sleepy, because overtired babies often find it harder to settle.",
          ),
          h('Night-time: dark, quiet and calm'),
          ul(
            'Use a dim night light for feeds and diaper changes; avoid bright lights.',
            'Speak softly, keep eye contact and play to a minimum; after feeding and changing, put your baby back in the crib.',
            'Change diapers at night only when needed, for example when dirty or very wet.',
            "As your baby gets older, practise laying them down drowsy but awake so they get used to falling asleep on their own; with newborns it won't always work, and that's fine.",
          ),
          h('A simple bedtime routine'),
          p(
            "From around 2–3 months you can start a short routine each evening in the same order, for example: a wash or bath, fresh diaper and sleepwear, lights down, a feed, a familiar lullaby, then into the crib. What matters is repeating it regularly; it doesn't need to be elaborate. A fairly fixed bedtime each night also helps your baby's sleep rhythm settle.",
          ),
          tip(
            'Consistency beats perfection',
            'The whole family can agree on a few key signals: bright days, a dim lamp at night and the same lullaby. Illness or travel can upset sleep for a while; gently return to your usual routine once things settle.',
          ),
          h('What to watch'),
          p(
            'Noting sleep, wake times and feeds for a few days helps you see that your baby is gradually sleeping more at night, even when individual nights are still broken.',
          ),
          ul(
            'Whether total night sleep and the longest night stretch grow week by week.',
            'Whether your baby is alert and content when awake, feeds well and gains weight steadily.',
            'Whether your baby cries a lot in the late afternoon and evening; evening crying is very common in the early weeks and eases over time.',
          ),
          h('Common misconceptions'),
          ul(
            '"A baby who sleeps all day is a good baby; let them sleep and take turns holding them at night": many families think this makes daytime easier. But very long daytime sleeps can leave a baby wide awake at night. Instead: if a daytime nap goes beyond 3 hours, gently wake your baby to feed and play in the light.',
            '"Keep the room pitch dark and ban all noise all day so the baby sleeps": a kind intention, but babies need daytime light and sound to learn day from night. Instead: carry on normally by day, and keep things dark and quiet only at night.',
            '"Start cereal early or make formula thicker so the baby stays full and sleeps through": grandparents want the baby to be full. But early solids do not help babies sleep through the night, and adding extra formula powder can make a baby constipated or dehydrated. Instead: make formula exactly as the pack says, and wait until around 6 months for solids.',
          ),
          doctor(
            'When to ask a doctor',
            'Your baby is very drowsy and hard to wake for feeds; feeds poorly, has few wet diapers or gains weight slowly; has a high-pitched cry or long, inconsolable crying; snores loudly with pauses in breathing. See a doctor the same day if your baby is under 3 months with a temperature of 38 °C or higher. Call 115 if your baby has trouble breathing, turns blue, has a fit or goes limp.',
          ),
        ],
      },
      keywords: t(
        [
          'ngày đêm',
          'nếp ngủ',
          'ngủ đêm',
          'thức đêm',
          'đồng hồ sinh học',
          'melatonin',
          'ánh sáng',
          'giấc ngủ ngày',
        ],
        [
          'day and night',
          'bedtime routine',
          'night sleep',
          'night waking',
          'body clock',
          'melatonin',
          'daylight',
          'naps',
        ],
      ),
      relatedArticleIds: [
        'art_newborn_sleep',
        'art_sleep_by_age',
        'art_safe_sleep',
        'art_crying_colic',
      ],
      milestoneIds: [],
      sources: [
        S.nhsSleep,
        S.aHcGettingBabyToSleep,
        S.aHcCalmingFussy,
        S.aPmRivkeesCircadian,
        S.aPmKennawayMelatonin,
        S.aPmHarrisonLight,
        S.aNationwideInfantSleep,
        S.aNhsFormulaMakingUp,
      ],
    },
  },
  {
    id: 'art_sleep_by_age',
    reviewerLabel: PAEDS,
    data: {
      library: 'care',
      topic: 'sleep',
      format: 'article',
      ageWeeks: { from: 13, to: 104 },
      readingMinutes: 6,
      cover: null,
      title: t(
        'Giấc ngủ theo tháng tuổi: số giờ, giấc ngày và “khủng hoảng giấc ngủ”',
        'Sleep by age: hours, naps and so-called "sleep regressions"',
      ),
      summary: t(
        'Bé 4–12 tháng cần khoảng 12–16 tiếng, trẻ 1–2 tuổi khoảng 11–14 tiếng mỗi ngày, tính cả giấc ngày. Giấc ngủ có thể xáo trộn quanh 4, 8–10 và 18 tháng; phần lớn sẽ qua.',
        'Babies aged 4–12 months need about 12–16 hours and children aged 1–2 about 11–14 hours a day, naps included. Sleep may wobble around 4, 8–10 and 18 months; most of it passes.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Số giờ ngủ phù hợp là một khoảng rộng, không phải một con số. Những đợt bé ngủ kém hơn quanh 4 tháng, 8–10 tháng hay 18 tháng thường gắn với các bước phát triển mới và chỉ tạm thời. Nếp ngủ đều đặn, đặt bé xuống khi buồn ngủ nhưng còn thức, và sự kiên nhẫn là nền tảng.',
          ),
          h('Hiểu đúng: bé cần ngủ bao nhiêu?'),
          p(
            'Theo đồng thuận của Hiệp hội Y học Giấc ngủ Hoa Kỳ (AASM), bé 4–12 tháng nên ngủ 12–16 tiếng và trẻ 1–2 tuổi ngủ 11–14 tiếng trong 24 giờ, tính cả giấc ngày. NHS (Anh) đưa con số gần tương tự, khoảng 12–15 tiếng cho trẻ trên 12 tháng. Hãy nhìn vào cả ngày của bé, bé có tỉnh táo, vui vẻ, ăn tốt không, thay vì so với bé nhà khác.',
          ),
          p(
            'Giấc ngày giảm dần theo tuổi. Bé 2 tháng thường ngủ 2–4 giấc ngày, đến 12 tháng còn 1–2 giấc; khoảng 18 tháng, phần lớn trẻ chỉ còn một giấc trưa dài khoảng 1,5–3 tiếng. Thời điểm chuyển đổi khác nhau ở mỗi bé; nếu bé nhiều ngày liền không chịu ngủ một giấc mà vẫn vui vẻ đến giấc sau, có thể bé đang sẵn sàng bớt một giấc.',
          ),
          p(
            'Thức giấc ban đêm là bình thường ở mọi lứa tuổi: bé nào cũng tỉnh dậy chốc lát nhiều lần mỗi đêm; khác nhau ở chỗ bé tự ngủ lại được hay cần ba mẹ giúp. Bé 6 tháng thức dậy rồi ngủ lại sau vài phút là chuyện bình thường. Từ 6–12 tháng, một số bé không còn cần bú đêm, nhưng nhiều bé vẫn bú đêm và điều đó không có gì sai.',
          ),
          h('Những đợt “khủng hoảng giấc ngủ”'),
          p(
            '“Khủng hoảng giấc ngủ” (sleep regression) là cách gọi phổ biến trên mạng, không phải chẩn đoán y khoa, và bằng chứng khoa học về việc chúng xảy ra đúng mốc tuổi còn hạn chế. Nhiều bé đi qua những mốc này mà không thay đổi gì. Tuy vậy, có những lý do phát triển hợp lý khiến giấc ngủ xáo trộn tạm thời:',
          ),
          ul(
            'Khoảng 4 tháng: chu kỳ ngủ của bé trở nên đều đặn và giống người lớn hơn, bé dễ tỉnh giữa các chu kỳ; bé cũng đang tập lật và chú ý nhiều hơn tới xung quanh.',
            'Khoảng 8–10 tháng: bé học bò, vịn đứng, bắt đầu ngại người lạ và lo khi xa ba mẹ. Một nghiên cứu theo dõi bé từ 5 đến 11 tháng thấy bé thức đêm nhiều hơn quanh thời điểm bắt đầu biết bò.',
            'Khoảng 18 tháng: bé muốn tự lập, hay phản đối giờ đi ngủ, lo xa cách, và đang chuyển từ hai giấc ngày sang một giấc.',
            'Ốm, thay đổi nếp sinh hoạt, đi xa, đổi người chăm hay bắt đầu đi nhà trẻ cũng có thể làm giấc ngủ chập chờn một thời gian.',
          ),
          h('Ba mẹ có thể làm gì'),
          ul(
            'Giữ giờ thức dậy buổi sáng và giờ đi ngủ tương đối cố định, kể cả cuối tuần.',
            'Duy trì một nếp đi ngủ ngắn, êm, cùng thứ tự: tắm hoặc lau người, đánh răng khi bé đã có răng, đọc truyện, hát ru, tắt đèn.',
            'Đặt bé vào nôi khi bé buồn ngủ nhưng còn thức, để bé tập tự chìm vào giấc ngủ.',
            'Không cho bé ngậm bình sữa đi ngủ; cho bú xong rồi mới đặt bé xuống, vì sữa đọng trong miệng dễ gây sâu răng.',
            'Phòng ngủ tối, yên, thoáng mát.',
            'Không cắt giấc ngủ ngày để mong bé ngủ đêm dài hơn, vì bé quá mệt thường ngủ kém hơn; tránh giấc ngủ ngày quá muộn, sát giờ đi ngủ.',
            'Khi bé thức đêm, chờ một chút xem bé có tự ngủ lại không; nếu cần, dỗ ngắn, nhẹ nhàng, ít đèn, ít trò chuyện.',
            'Trong đợt xáo trộn, giữ nếp cũ hết mức có thể; tránh tạo thói quen mới khó bỏ như phải bế đi rong hay lên giường ba mẹ mới ngủ.',
            'Từ khoảng 12 tháng có thể cho bé một vật quen như khăn nhỏ hay thú bông để ôm; trước 12 tháng không để đồ mềm trong nôi.',
          ),
          h('Về các phương pháp “luyện ngủ”'),
          p(
            'Một số gia đình chọn luyện ngủ khi bé thức đêm nhiều và cả nhà kiệt sức. Các cách thường được nghiên cứu gồm: vào dỗ theo những khoảng thời gian dài dần, ngồi cạnh nôi rồi lùi ghế xa dần qua các đêm, hoặc lùi giờ đi ngủ đến lúc bé thật sự buồn ngủ rồi sớm dần lên. Các thử nghiệm ở bé từ 6 tháng trở lên cho thấy những cách này giúp bé ngủ nhanh hơn, ít thức đêm hơn, và không thấy hại về cảm xúc, hành vi hay sự gắn bó với cha mẹ khi theo dõi 1 năm và 5 năm sau. Đây là lựa chọn của mỗi gia đình, không bắt buộc; không luyện ngủ cũng không có gì sai. Nên hỏi bác sĩ trước khi bắt đầu, nhất là khi bé đang ốm hay chậm tăng cân.',
          ),
          h('Theo dõi'),
          ul(
            'Ghi giờ ngủ, giờ thức, số lần thức đêm trong 1–2 tuần để thấy xu hướng, thay vì lo theo từng đêm.',
            'Bé có ngáy to thường xuyên, thở bằng miệng, có lúc ngừng thở khi ngủ không.',
            'Ban ngày bé có quá cáu kỉnh, buồn ngủ bất thường hay khó tập trung chơi không.',
            'Sức khoẻ của chính ba mẹ: thiếu ngủ kéo dài có thể ảnh hưởng tâm trạng và sức khoẻ tinh thần.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            '“Bé 6 tháng mà còn bú đêm là thiếu chất, phải cho ăn thêm bột buổi tối”: ông bà lo cháu đói. Nhưng bú đêm vẫn bình thường ở nhiều bé trong năm đầu. Nên: cho bé ăn dặm đủ bữa theo tuổi trong ngày, không ép ăn thêm buổi tối; hỏi bác sĩ nếu bé chậm tăng cân.',
            '“Bé khó ngủ, hay giật mình là do thiếu canxi, phải cho uống bổ sung”: đây là niềm tin rất phổ biến. Thức đêm ở bé khoẻ mạnh thường liên quan đến phát triển và thói quen ngủ. Nên: không tự cho bé uống canxi, thuốc an thần hay thuốc ngủ; bổ sung vitamin theo hướng dẫn của bác sĩ.',
            '“Phải bế đi rong, đưa võng thật lâu bé mới ngủ”: ông bà dỗ cháu bằng cả tấm lòng. Nhưng nếu lần nào cũng phải bế rong mới ngủ, bé sẽ cần đúng điều đó mỗi lần tỉnh giấc ban đêm. Nên: dỗ cho bé dịu lại rồi đặt vào nôi khi bé còn hơi thức.',
            '“Luyện ngủ là để bé khóc đến khi tự ngủ cho ngoan”: luyện ngủ không có nghĩa là bỏ mặc bé, và bé dưới 6 tháng cần được đáp ứng khi khóc. Nên: nếu chọn luyện ngủ, chỉ bắt đầu khi bé từ khoảng 6 tháng, khoẻ mạnh, và cả nhà có kế hoạch thống nhất.',
          ),
          doctor(
            'Khi nào nên hỏi bác sĩ',
            'Bé ngáy to gần như mỗi đêm, thở khò khè hoặc có những lúc ngừng thở khi ngủ; bé thức đêm kèm sốt, đau tai hay quấy khóc bất thường; ban ngày bé lờ đờ hoặc quá cáu kỉnh; bé chậm tăng cân; giấc ngủ của bé khiến ba mẹ kiệt sức hay buồn chán kéo dài. Gọi 115 nếu bé khó thở, tím tái, co giật hoặc lả mềm khó đánh thức.',
          ),
        ],
        en: [
          note(
            'In short',
            'The right amount of sleep is a wide range, not a single number. Rough patches around 4 months, 8–10 months or 18 months are usually linked to new developmental steps and are temporary. A steady routine, laying your baby down drowsy but awake, and patience are the foundation.',
          ),
          h('Understanding: how much sleep does my child need?'),
          p(
            "According to the American Academy of Sleep Medicine (AASM) consensus, babies aged 4–12 months should sleep 12–16 hours and children aged 1–2 years 11–14 hours in 24 hours, naps included. The UK's NHS gives similar figures, about 12–15 hours for children over 12 months. Look at your child's whole day, whether they are alert, cheerful and eating well, rather than comparing with other children.",
          ),
          p(
            'Daytime naps shrink with age. At 2 months babies often take 2–4 naps, and by 12 months 1–2; by around 18 months most toddlers have just one long afternoon nap of about 1.5–3 hours. The timing of each switch varies; if your child refuses a nap for many days in a row yet stays happy until the next sleep, they may be ready to drop one.',
          ),
          p(
            "Night waking is normal at every age: all babies wake briefly several times a night; the difference is whether they settle back on their own or need your help. It's normal for a 6-month-old to wake and fall back asleep after a few minutes. Between 6 and 12 months some babies no longer need night feeds, but many still have them, and that is fine.",
          ),
          h('So-called "sleep regressions"'),
          p(
            '"Sleep regression" is a popular term online, not a medical diagnosis, and the scientific evidence that it happens at set ages is limited. Many babies pass these ages with no change at all. Still, there are sensible developmental reasons why sleep may be unsettled for a while:',
          ),
          ul(
            'Around 4 months: sleep cycles become more regular and adult-like, so babies surface more easily between cycles; they are also learning to roll and paying more attention to the world.',
            'Around 8–10 months: babies learn to crawl and pull to stand, and start to be wary of strangers and anxious when apart from parents. A study following babies from 5 to 11 months found more night waking around the time they started crawling.',
            'Around 18 months: toddlers want independence, often protest at bedtime, feel separation anxiety, and are moving from two naps to one.',
            'Illness, a change of routine, travel, a new carer or starting childcare can also unsettle sleep for a while.',
          ),
          h('What you can do'),
          ul(
            'Keep wake-up time and bedtime fairly fixed, weekends included.',
            'Keep a short, calm bedtime routine in the same order: bath or wash, brushing teeth once they have some, a story, a lullaby, lights out.',
            'Lay your baby in the crib drowsy but awake so they learn to fall asleep on their own.',
            "Don't put your baby to bed with a bottle; finish the feed first, then lay them down, because milk pooling in the mouth can cause tooth decay.",
            'Keep the bedroom dark, quiet and comfortably cool.',
            "Don't cut daytime naps hoping for longer nights, because overtired children often sleep worse; avoid naps that are too late, close to bedtime.",
            'When your baby wakes at night, wait a moment to see if they resettle; if needed, soothe briefly and gently, with little light and little talk.',
            'During a rough patch, keep your usual routine as much as possible; avoid starting new habits that are hard to undo, such as walking them to sleep or bringing them into your bed.',
            'From around 12 months you can offer a familiar comfort object such as a small cloth or soft toy; before 12 months keep soft items out of the crib.',
          ),
          h('About "sleep training"'),
          p(
            "Some families choose sleep training when their baby wakes a lot at night and everyone is exhausted. Approaches that have been studied include: checking in at gradually longer intervals, sitting by the crib and moving the chair further away over several nights, or moving bedtime later to when the baby is truly sleepy and then gradually earlier. Trials in babies aged 6 months and older found these methods helped babies fall asleep faster and wake less, with no harm seen to emotions, behaviour or the parent–child bond at follow-ups 1 year and 5 years later. It's each family's choice, not a must; not sleep training is fine too. Talk to a doctor before starting, especially if your baby is unwell or gaining weight slowly.",
          ),
          h('What to watch'),
          ul(
            'Log sleep, wake times and night wakings for 1–2 weeks to see the trend, rather than worrying night by night.',
            'Whether your child snores loudly most nights, breathes through the mouth, or seems to pause breathing in sleep.',
            'Whether your child is very irritable, unusually sleepy or struggles to focus on play during the day.',
            "Your own health: long-term sleep loss can affect a parent's mood and mental health.",
          ),
          h('Common misconceptions'),
          ul(
            '"A 6-month-old who still feeds at night is lacking nutrients and needs extra cereal at dinner": grandparents worry the baby is hungry. But night feeds are still normal for many babies in the first year. Instead: offer age-appropriate solid meals through the day without forcing extra food in the evening; ask a doctor if weight gain is slow.',
            '"Poor sleep and startling mean a calcium deficiency, so give supplements": this is a very common belief. Night waking in healthy children is usually about development and sleep habits. Instead: do not give calcium, sedatives or sleep medicine on your own; give vitamins only as your doctor advises.',
            '"Only long walks in arms or a long swing in the hammock will get the baby to sleep": grandparents soothe with all their heart. But if a baby always needs to be walked to sleep, they will need exactly that every time they wake at night. Instead: soothe until your baby is calm, then lay them in the crib while still a little awake.',
            '"Sleep training means leaving the baby to cry until they give up": sleep training does not mean ignoring your baby, and babies under 6 months need a response when they cry. Instead: if you choose sleep training, start only from around 6 months, when your baby is well, and with a plan the whole family agrees on.',
          ),
          doctor(
            'When to ask a doctor',
            'Your child snores loudly almost every night, wheezes or seems to pause breathing in sleep; wakes at night with fever, ear pain or unusual crying; is drowsy or very irritable during the day; is gaining weight slowly; or your child’s sleep leaves you exhausted or low for a long time. Call 115 if your child has trouble breathing, turns blue, has a fit or is limp and hard to wake.',
          ),
        ],
      },
      keywords: t(
        [
          'giấc ngủ theo tuổi',
          'số giờ ngủ',
          'giấc ngủ ngày',
          'giảm giấc ngày',
          'khủng hoảng giấc ngủ',
          'thức đêm',
          'bú đêm',
          'luyện ngủ',
          'nếp đi ngủ',
          'ngủ 4 tháng',
        ],
        [
          'sleep by age',
          'sleep hours',
          'naps',
          'dropping naps',
          'sleep regression',
          'night waking',
          'night feeds',
          'sleep training',
          'bedtime routine',
          '4-month sleep',
        ],
      ),
      relatedArticleIds: [
        'art_day_night',
        'art_safe_sleep',
        'art_separation_anxiety',
        'art_parent_wellbeing',
      ],
      milestoneIds: ['rolls_over', 'crawls', 'stranger_wariness', 'stands'],
      sources: [
        S.aAasmSleepDuration,
        S.nhsSleep,
        S.aNationwideInfantSleep,
        S.aNationwideToddlerSleep,
        S.aHcGettingBabyToSleep,
        S.aPmPriceSleepIntervention,
        S.aPmGradisarSleepIntervention,
        S.aPmScherCrawling,
      ],
    },
  },
  {
    id: 'art_swaddling',
    reviewerLabel: PAEDS,
    data: {
      library: 'care',
      topic: 'sleep',
      format: 'quick_qa',
      ageWeeks: { from: 0, to: 17 },
      readingMinutes: 2,
      cover: null,
      title: t(
        'Hỏi nhanh: Quấn chũn cho bé — khi nào, cách nào, khi nào ngừng',
        'Quick Q&A: Swaddling — when, how and when to stop',
      ),
      summary: t(
        'Quấn có thể giúp bé sơ sinh dịu và ngủ yên hơn, nhưng phải quấn đúng: luôn nằm ngửa, vừa khít ở ngực, rộng ở hông, không quá nóng, và ngừng khi bé tập lật.',
        'Swaddling can help newborns calm down and sleep more peacefully, but only when done right: always on the back, snug at the chest, loose at the hips, not too hot, stopped once rolling starts.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Quấn hoặc quấn chũn có thể giúp bé nhỏ dễ dịu, dễ ngủ, nhưng không giúp phòng đột tử. Luôn đặt bé nằm ngửa, để chân bé co và dạng tự nhiên, dùng vải mỏng, và ngừng quấn ngay khi bé có dấu hiệu tập lật.',
          ),
          h('Quấn có lợi gì?'),
          p(
            'Quấn đúng cách có thể giúp nhiều bé sơ sinh dịu lại và ngủ yên hơn. Tuy vậy, AAP lưu ý quấn không làm giảm nguy cơ đột tử; bé đang được quấn mà bị lật sấp còn có nguy cơ cao hơn.',
          ),
          h('Quấn thế nào cho đúng?'),
          p(
            'Dùng khăn mỏng, thoáng. Quấn vừa khít phần tay và ngực, chừa khoảng 2–3 ngón tay giữa ngực bé và khăn. Phần dưới để rộng cho chân bé co lên và dạng ra hai bên tự nhiên như tư thế ếch. Túi quấn chũn may sẵn nên có phần chân rộng, không bó sát đùi. Luôn đặt bé nằm ngửa.',
          ),
          h('Quấn chặt, duỗi thẳng chân cho “chân thẳng” có đúng không?'),
          p(
            'Không. Ông bà thường làm vậy vì mong cháu chân đẹp, nhưng chân bé nhỏ hơi cong là bình thường. Kéo thẳng và ép hai chân vào nhau có thể làm khớp háng phát triển không tốt (loạn sản khớp háng). Ở Nhật Bản, sau khi bỏ cách quấn duỗi thẳng chân, tỷ lệ trật khớp háng ở trẻ giảm rõ rệt.',
          ),
          h('Khi nào ngừng quấn?'),
          p(
            'Ngừng ngay khi bé có dấu hiệu cố lật người. AAP cho biết việc này thường xảy ra khoảng 3–4 tháng, nhưng có bé sớm hơn, từ khoảng 2 tháng. Sau đó có thể cho bé dùng túi ngủ để hở tay.',
          ),
          h('Trời nóng có nên quấn không?'),
          p(
            'Quấn dễ làm bé quá nóng. Chỉ dùng vải mỏng, không mặc nhiều lớp bên trong, không đội mũ. Nếu bé ra mồ hôi, tóc ẩm, má đỏ, nổi rôm hay thở nhanh, hãy nới bớt hoặc thôi quấn.',
          ),
          h('Có nên dùng đồ quấn có gắn vật nặng?'),
          p(
            'Không. AAP khuyên không dùng đồ quấn hay chăn có gắn vật nặng vì có thể đè lên ngực và phổi bé. Cũng không quấn bé khi ngủ chung giường với người lớn.',
          ),
          doctor(
            'Khi nào nên hỏi bác sĩ',
            'Hai chân bé trông dài ngắn khác nhau, có tiếng lục cục khi cử động háng, một chân cử động khác chân kia; bé có nguy cơ loạn sản khớp háng như nằm ngôi mông khi mang thai hoặc người nhà từng bị. Gọi 115 nếu bé khó thở, tím tái hoặc lả mềm.',
          ),
        ],
        en: [
          note(
            'In short',
            'Swaddling, with a wrap or a zip-up swaddle sack, can help young babies calm down and settle, but it does not prevent SIDS. Always lay your baby on their back, let the legs bend up and out naturally, use thin fabric, and stop as soon as your baby shows signs of trying to roll.',
          ),
          h('What are the benefits of swaddling?'),
          p(
            'Swaddling done correctly can help many newborns calm down and sleep more peacefully. However, the AAP notes that swaddling does not lower the risk of SIDS, and a swaddled baby who rolls onto their tummy is at higher risk.',
          ),
          h('How do I swaddle correctly?'),
          p(
            "Use a thin, breathable cloth. Wrap the arms and chest snugly, leaving about 2–3 fingers' space between the chest and the wrap. Keep the lower part loose so the legs can bend up and out to the sides naturally, like a frog. Ready-made swaddle sacks should have a roomy leg pouch that doesn't squeeze the thighs. Always lay your baby on their back.",
          ),
          h('Should I wrap tightly with straight legs "so the legs grow straight"?'),
          p(
            'No. Grandparents often do this hoping for straight legs, but slightly curved legs are normal in young babies. Pulling the legs straight and pressing them together can harm hip development (hip dysplasia). In Japan, after the practice of swaddling with straight legs was dropped, hip dislocation in infants fell sharply.',
          ),
          h('When should I stop swaddling?'),
          p(
            'Stop as soon as your baby shows signs of trying to roll. The AAP says this usually happens around 3–4 months, but some babies start earlier, from about 2 months. After that you can use a sleep sack with arms free.',
          ),
          h('Should I swaddle in hot weather?'),
          p(
            'Swaddling can easily make a baby too hot. Use only thin fabric, no extra layers underneath and no hat. If your baby is sweating, has damp hair, red cheeks, heat rash or fast breathing, loosen the wrap or stop swaddling.',
          ),
          h('Can I use a weighted swaddle?'),
          p(
            "No. The AAP advises against weighted swaddles or blankets because they can press on the baby's chest and lungs. Also, don't swaddle a baby who is sharing a bed with an adult.",
          ),
          doctor(
            'When to ask a doctor',
            "Your baby's legs look different lengths, the hips click when moved, or one leg moves differently from the other; your baby has a higher chance of hip dysplasia, for example breech position in pregnancy or a family history. Call 115 if your baby has trouble breathing, turns blue or goes limp.",
          ),
        ],
      },
      keywords: t(
        ['quấn chũn', 'quấn bé', 'khớp háng', 'loạn sản khớp háng', 'tập lật', 'túi ngủ'],
        ['swaddling', 'swaddle', 'hips', 'hip dysplasia', 'rolling', 'sleep sack'],
      ),
      relatedArticleIds: ['art_safe_sleep', 'art_crying_colic', 'art_newborn_sleep'],
      milestoneIds: ['rolls_over'],
      sources: [
        S.aHcSwaddling,
        S.aIhdiSwaddling,
        S.hcSafeSleep,
        S.aAapSafeSleep2022News,
        S.aNhsDdh,
        S.nhsSids,
      ],
    },
  },
  {
    id: 'art_crying_colic',
    reviewerLabel: PAEDS,
    data: {
      library: 'care',
      topic: 'sleep',
      format: 'article',
      ageWeeks: { from: 0, to: 20 },
      readingMinutes: 6,
      cover: null,
      title: t(
        'Bé quấy khóc và khóc dạ đề: cách dỗ, khi nào cần lo, không bao giờ lắc bé',
        'Crying and colic: soothing, when to worry, and never shaking a baby',
      ),
      summary: t(
        'Bé sơ sinh khóc nhiều nhất quanh 6–8 tuần rồi giảm dần đến 3–4 tháng. Hiểu khóc dạ đề, cách dỗ an toàn, dấu hiệu cần đi khám và cách giữ bình tĩnh khi quá mệt.',
        'Newborn crying peaks around 6–8 weeks and eases by 3–4 months. Understand colic, safe soothing, the signs that need a doctor, and how to stay calm when you are exhausted.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Khóc là cách bé giao tiếp. Lượng khóc thường tăng từ khoảng 2 tuần tuổi, nhiều nhất quanh 6–8 tuần rồi giảm dần đến 3–4 tháng, hay vào chiều tối. Bé khóc nhiều nhưng vẫn bú tốt, tăng cân đều thường là khóc dạ đề lành tính. Dù mệt đến đâu, không bao giờ được lắc bé.',
          ),
          h('Hiểu đúng về khóc và khóc dạ đề'),
          p(
            'Bé sơ sinh thường khóc 1–4 tiếng mỗi ngày. Lượng khóc tăng dần từ khoảng 2 tuần tuổi, cao nhất quanh 6–8 tuần, khi đó nhiều bé quấy khoảng 3 tiếng một ngày, rồi giảm còn 1–2 tiếng lúc 3–4 tháng. Đây là một giai đoạn phát triển bình thường, không có nghĩa là ba mẹ chăm sai.',
          ),
          p(
            'Khóc dạ đề (colic) là khi bé khoẻ mạnh nhưng khóc rất nhiều, khó dỗ mà không rõ lý do. Có hai cách định nghĩa khác nhau: NHS (Anh) dùng “quy tắc số 3”, tức khóc hơn 3 tiếng một ngày, hơn 3 ngày một tuần, kéo dài ít nhất 1 tuần; còn tiêu chuẩn Rome IV mà bác sĩ dùng không đòi số giờ, chỉ cần bé dưới 5 tháng, khóc quấy kéo dài lặp lại không rõ nguyên nhân, người chăm không dỗ được, và bé không sốt, không ốm, vẫn tăng cân tốt. Cơn khóc thường vào chiều tối; bé có thể đỏ mặt, nắm chặt tay, co chân lên bụng, ưỡn lưng.',
          ),
          p(
            'Nguyên nhân chưa rõ. Nhiều bé nhạy cảm với kích thích và khó tự dịu. Dưới 5% trường hợp liên quan đến nhạy cảm với thức ăn như đạm sữa bò; trào ngược hay táo bón cũng có thể khiến bé khóc. Khóc dạ đề thường hết khi bé 3–4 tháng, có bé kéo dài đến 6 tháng.',
          ),
          h('Ba mẹ có thể làm gì'),
          h('Kiểm tra nhu cầu trước'),
          p(
            'Bé có đói không, tã có bẩn không, có quá nóng hay quá lạnh, có mệt, buồn ngủ hay bị kích thích quá nhiều không? Bé nhỏ không thể “hư” vì được bế: đáp lại tiếng khóc sớm trong những tháng đầu giúp bé khóc ít hơn về lâu dài.',
          ),
          h('Cách dỗ an toàn'),
          ul(
            'Bế áp sát người, da kề da, đung đưa nhẹ nhàng, đi lại trong nhà hoặc dùng địu đúng cách, luôn nhìn thấy mặt bé.',
            'Âm thanh đều như tiếng “suỵt” khẽ, tiếng quạt hay máy tạo tiếng ồn trắng: đặt máy xa bé, không đặt trong nôi hay trên thành nôi, mở nhỏ và không bật quá lâu.',
            'Cho bé mút: bú mẹ, ti giả hoặc mút ngón tay.',
            'Bế nghiêng hoặc đặt bé nằm sấp ngang trên đùi, xoa lưng khi bé thức; khi bé ngủ thì đặt lại nằm ngửa trong nôi.',
            'Quấn bé bằng khăn mỏng khi bé còn nhỏ và chưa tập lật (xem bài Hỏi nhanh về quấn chũn).',
            'Tắm nước ấm, hát ru, đẩy xe đi dạo. Nếu bé ngủ trên ghế ô tô hay xe đẩy, chuyển bé sang nằm ngửa trên mặt phẳng khi có thể.',
            'Khi cho bú, giữ đầu bé cao hơn, vỗ ợ hơi sau bú, tránh cho bú quá nhiều.',
            'Thử một cách trong vài phút, đừng đổi liên tục; có lúc bé chỉ cần ít kích thích hơn và được đặt nằm yên.',
          ),
          p(
            'Về chế độ ăn của mẹ, NHS cho rằng mẹ cho con bú không cần đổi chế độ ăn, còn AAP gợi ý có thể thử bỏ từng thứ như sữa bò hay cà phê trong khoảng 2 tuần. Cách an toàn là không tự kiêng nhiều thứ, chỉ thử khi đã hỏi bác sĩ. Với men vi sinh và thuốc nhỏ chống đầy hơi, NHS không khuyến nghị vì thiếu bằng chứng; một phân tích gộp thấy chủng lợi khuẩn L. reuteri DSM17938 giúp giảm khóc ở bé bú mẹ nhưng chưa đủ dữ liệu ở bé bú sữa công thức. Hãy hỏi bác sĩ trước khi cho bé dùng bất kỳ loại nào.',
          ),
          h('Khi ba mẹ thấy mình sắp không chịu nổi'),
          p(
            'Tiếng khóc kéo dài có thể khiến bất kỳ ai căng thẳng, bực bội. Đó là cảm giác bình thường, không có nghĩa ba mẹ là người xấu. Điều quan trọng là có sẵn kế hoạch an toàn:',
          ),
          ul(
            'Đặt bé nằm ngửa an toàn trong nôi không có chăn gối, đóng cửa và ra phòng khác khoảng 10 phút để hít thở, uống nước, gọi điện cho ai đó.',
            'Quay lại xem bé đều đặn; khi đã bình tĩnh mới bế và dỗ tiếp.',
            'Nhờ người thân thay ca. Chỉ giao bé cho người kiên nhẫn, không nóng tính.',
            'Không bao giờ lắc, tung, xóc mạnh hay đánh bé. Lắc bé có thể gây chảy máu trong não, mù, chậm phát triển hoặc tử vong.',
          ),
          h('Theo dõi'),
          p(
            'Ghi lại giờ bé khóc, thời gian khóc, cữ bú, tã và giấc ngủ trong vài ngày, có thể ghi trong Child Life, để đưa bác sĩ xem. Nhật ký giúp phân biệt khóc theo giờ quen thuộc với khóc bất thường.',
          ),
          ul(
            'Bé có bú tốt, tăng cân đều, đủ tã ướt không.',
            'Tiếng khóc có khác thường không: thét the thé, yếu ớt hay rên.',
            'Có kèm sốt, nôn, phân có máu, phát ban, ho hay khó thở không.',
            'Khóc nhiều có kéo dài sau 4 tháng không.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            '“Bé khóc đêm là do vía, bị trêu, phải đốt vía, cúng vía”: nhiều gia đình làm vì thương con và mong bé yên giấc. Khóc chiều tối là giai đoạn sinh lý bình thường; điều quan trọng là không bỏ sót dấu hiệu bệnh. Nên: nếu vẫn giữ phong tục, tránh khói, lửa, hương, than gần bé, và đưa bé đi khám khi có dấu hiệu bất thường.',
            '“Cạo gió, đánh cảm, xoa dầu nóng cho bé hết khóc”: ông bà làm theo kinh nghiệm cũ. Nhưng da bé sơ sinh rất mỏng, dễ trầy xước và kích ứng. Nên: không cạo gió, không bôi dầu nóng cho bé; dỗ bằng bế ấm và xoa lưng nhẹ.',
            '“Cho bé uống nước lá, nước sắc, thuốc nam, nước đường cho hết đau bụng”: ông bà mong cháu dễ chịu. Nhưng bé dưới 6 tháng chỉ cần sữa, và các loại thảo dược chưa có bằng chứng giúp giảm khóc dạ đề. Nên: không cho bé uống gì ngoài sữa nếu bác sĩ không chỉ định; hỏi bác sĩ trước khi dùng bất kỳ loại giọt, men hay thuốc nào.',
            '“Đưa võng thật mạnh, xóc mạnh, tung bé lên cho bé nín”: người dỗ thường không nghĩ là nguy hiểm. Nhưng rung lắc mạnh có thể làm tổn thương não của bé. Nên: chỉ đung đưa nhẹ nhàng, êm; khi thấy mình đang bực, đặt bé vào nôi và rời đi vài phút.',
          ),
          doctor(
            'Gọi 115 hoặc đến cấp cứu ngay khi',
            'Bé khóc thét the thé, khóc yếu hoặc rên khác hẳn mọi khi; lả mềm, khó đánh thức, không phản ứng; khó thở, tím tái hoặc da xám, nhợt, loang lổ; co giật; thóp phồng; phát ban không mất khi ấn; nôn ra dịch xanh; nghi bé bị ngã hay bị lắc.',
          ),
          doctor(
            'Đưa bé đi khám trong ngày khi',
            'Bé dưới 3 tháng có nhiệt độ từ 38 °C trở lên; bỏ bú hoặc bú rất kém; nôn nhiều, nôn vọt; phân có máu; ít tã ướt; chậm tăng cân; khóc nhiều kéo dài sau 4 tháng; hoặc ba mẹ thấy kiệt sức, không thể đối phó.',
          ),
        ],
        en: [
          note(
            'In short',
            'Crying is how babies communicate. It usually increases from about 2 weeks, peaks around 6–8 weeks and eases by 3–4 months, often in the late afternoon and evening. A baby who cries a lot but feeds well and gains weight steadily usually has harmless colic. However tired you are, never shake a baby.',
          ),
          h('Understanding crying and colic'),
          p(
            "Newborns commonly cry 1–4 hours a day. Crying builds from about 2 weeks, peaks around 6–8 weeks, when many babies fuss for about 3 hours a day, and drops to 1–2 hours by 3–4 months. This is a normal stage of development and doesn't mean you are doing anything wrong.",
          ),
          p(
            'Colic is when a healthy baby cries a great deal and is hard to settle for no clear reason. There are two different definitions: the UK\'s NHS uses the "rule of three", meaning crying more than 3 hours a day, more than 3 days a week, for at least 1 week; the Rome IV criteria used by doctors set no number of hours, only that the baby is under 5 months, has repeated, prolonged crying with no obvious cause that carers can\'t prevent or settle, and has no fever or illness and is growing well. Bouts are often in the evening; babies may go red, clench their fists, pull their knees up or arch their back.',
          ),
          p(
            "The cause is not clear. Many babies are sensitive to stimulation and find it hard to calm themselves. Fewer than 5% of cases are linked to a food sensitivity such as cow's milk protein; reflux or constipation can also make a baby cry. Colic usually stops by 3–4 months, and in some babies lasts until 6 months.",
          ),
          h('What you can do'),
          h('Check needs first'),
          p(
            'Is your baby hungry, is the diaper dirty, are they too hot or cold, tired, sleepy or overstimulated? You cannot spoil a young baby by holding them: responding to crying promptly in the first months helps babies cry less overall.',
          ),
          h('Safe ways to soothe'),
          ul(
            "Hold your baby close, skin to skin, sway gently, walk around or use a carrier correctly, always able to see your baby's face.",
            'Steady sounds such as a soft "shush", a fan or a white noise machine: keep the machine far from your baby, never in or on the crib, at low volume and not on for long.',
            'Let your baby suck: breastfeeding, a pacifier or their fingers.',
            'Hold your baby on their side, or lay them tummy-down across your lap and rub their back while awake; once asleep, put them back on their back in the crib.',
            'Swaddle in a thin wrap while your baby is young and not yet trying to roll (see the swaddling quick Q&A).',
            'Try a warm bath, a lullaby or a walk in the stroller. If your baby falls asleep in a car seat or stroller, move them onto their back on a flat surface when you can.',
            'During feeds keep the head higher, burp afterwards and avoid overfeeding.',
            'Try one approach for a few minutes rather than switching constantly; sometimes a baby just needs less stimulation and to be laid down quietly.',
          ),
          p(
            "On the breastfeeding mother's diet, the NHS says there is no need to change it, while the AAP suggests trying to remove one item at a time, such as dairy or caffeine, for about 2 weeks. The safest approach is not to cut out lots of foods on your own, and to try only after talking to a doctor. Probiotics and anti-colic drops are not recommended by the NHS because the evidence is lacking; a meta-analysis found that the probiotic strain L. reuteri DSM17938 reduced crying in breastfed babies, but there was not enough data for formula-fed babies. Ask a doctor before giving your baby any of these.",
          ),
          h('When you feel you can’t cope'),
          p(
            "Long crying can make anyone stressed and frustrated. That is a normal feeling and doesn't make you a bad parent. What matters is having a safety plan ready:",
          ),
          ul(
            'Lay your baby safely on their back in a crib with no blankets or pillows, close the door and go to another room for about 10 minutes to breathe, have a drink or call someone.',
            'Go back and check on your baby regularly; pick them up and soothe again only once you feel calm.',
            'Ask family to take a turn. Only leave your baby with someone patient who does not lose their temper.',
            'Never shake, throw, jerk or hit a baby. Shaking can cause bleeding in the brain, blindness, developmental problems or death.',
          ),
          h('What to watch'),
          p(
            'Note when and how long your baby cries, plus feeds, diapers and sleep for a few days, for example in Child Life, to show the doctor. A diary helps tell familiar daily crying apart from unusual crying.',
          ),
          ul(
            'Whether your baby feeds well, gains weight steadily and has enough wet diapers.',
            'Whether the cry sounds unusual: high-pitched, weak or moaning.',
            'Whether there is fever, vomiting, blood in the stool, a rash, cough or trouble breathing.',
            'Whether heavy crying continues beyond 4 months.',
          ),
          h('Common misconceptions'),
          ul(
            '"Night crying is caused by spirits, so burn things or make offerings to calm the baby": many families do this out of love and a wish for peaceful nights. Evening crying is a normal physiological stage; what matters is not missing signs of illness. Instead: if you keep the custom, keep smoke, flames, incense and charcoal away from your baby, and see a doctor if anything seems unusual.',
            '"Coin-rub the skin or apply hot balm to stop the crying": grandparents follow old experience. But newborn skin is very thin and easily scratched and irritated. Instead: no coining and no hot balms on your baby; soothe with warm cuddles and gentle back rubs.',
            '"Give herbal water, decoctions, traditional remedies or sugar water for tummy ache": grandparents want the baby to feel better. But babies under 6 months need only milk, and herbal remedies have no evidence of easing colic. Instead: give nothing but milk unless a doctor advises otherwise; ask a doctor before using any drops, probiotics or medicines.',
            '"Swing the hammock hard, jiggle or toss the baby to stop the crying": people soothing a baby often do not see the danger. But vigorous shaking can injure the brain. Instead: rock only gently and smoothly; when you feel angry, put your baby in the crib and step away for a few minutes.',
          ),
          doctor(
            'Call 115 or go to the emergency department now if',
            'Your baby has a high-pitched, weak or moaning cry unlike their usual one; is floppy, hard to wake or unresponsive; has trouble breathing, turns blue or has grey, pale or blotchy skin; has a fit; a bulging soft spot; a rash that does not fade when pressed; green vomit; or may have been dropped or shaken.',
          ),
          doctor(
            'See a doctor the same day if',
            'Your baby is under 3 months with a temperature of 38 °C or higher; refuses feeds or feeds very poorly; vomits a lot or forcefully; has blood in the stool; has few wet diapers; is gaining weight slowly; heavy crying continues beyond 4 months; or you feel exhausted and unable to cope.',
          ),
        ],
      },
      keywords: t(
        [
          'quấy khóc',
          'khóc dạ đề',
          'colic',
          'dỗ bé',
          'khóc đêm',
          'hội chứng rung lắc',
          'không lắc bé',
          'tiếng ồn trắng',
          'đầy hơi',
          'men vi sinh',
        ],
        [
          'crying',
          'colic',
          'infant colic',
          'soothing',
          'night crying',
          'shaken baby syndrome',
          'never shake',
          'white noise',
          'wind',
          'probiotics',
        ],
      ),
      relatedArticleIds: [
        'art_swaddling',
        'art_spit_up_hiccups',
        'art_parent_wellbeing',
        'art_fever_when_to_call',
      ],
      milestoneIds: ['calms_when_held'],
      sources: [
        S.aNhsColic,
        S.aNhsSoothingCrying,
        S.aHcColic,
        S.aHcRespondingCries,
        S.aCdcAht,
        S.aPmSungReuteri,
        S.nhsReflux,
        S.aNhsMeningitisSymptoms,
      ],
    },
  },

  // ----- Bú & sữa (feeding) -----
  {
    id: 'art_breastfeeding_start',
    reviewerLabel: LACTATION,
    data: {
      library: 'care',
      topic: 'feeding',
      format: 'article',
      ageWeeks: { from: 0, to: 13 },
      readingMinutes: 7,
      cover: null,
      title: t(
        'Những tuần đầu bú mẹ: khớp ngậm, cữ bú và dấu hiệu bé đủ sữa',
        'The first weeks of breastfeeding: latch, feeds and signs of enough milk',
      ),
      summary: t(
        'Da kề da, bú trong giờ đầu, bú theo nhu cầu 8–12 cữ mỗi ngày và một khớp ngậm tốt là nền tảng. Đếm tã ướt, tã bẩn và theo dõi cân nặng để biết bé đủ sữa.',
        'Skin-to-skin, a first feed within the hour, feeding on demand 8–12 times a day and a good latch are the foundation. Count wet and dirty diapers and track weight to know your baby is getting enough.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Cho bé da kề da và bú mẹ trong giờ đầu sau sinh, sau đó bú theo nhu cầu, thường 8–12 cữ mỗi 24 giờ. Sữa non tuy ít nhưng là thức ăn hoàn hảo cho bé sơ sinh, bé không cần nước hay sữa nào khác. Cách đáng tin nhất để biết bé đủ sữa là đếm tã ướt, tã bẩn và theo dõi cân nặng.',
          ),
          h('Hiểu đúng về những tuần đầu bú mẹ'),
          p(
            'WHO và UNICEF khuyên cho bé bú mẹ trong 1 giờ đầu sau sinh và bú mẹ hoàn toàn trong 6 tháng đầu, không thêm thức ăn hay đồ uống nào, kể cả nước lọc, trừ khi có chỉ định y tế. Da kề da ngay sau sinh, kể cả sau mổ, giúp bé ấm, bình tĩnh và dễ tìm vú.',
          ),
          p(
            'Sữa non là sữa vàng, sánh của những ngày đầu, được WHO gọi là thức ăn hoàn hảo cho trẻ sơ sinh. Sữa non rất cô đặc nên mỗi cữ bé chỉ cần một lượng nhỏ. Khoảng 2–4 ngày sau sinh, ngực mẹ căng đầy hơn: đó là lúc sữa “về”.',
          ),
          p(
            'Sữa mẹ hoạt động theo kiểu cung – cầu: bé bú càng thường xuyên và rút sữa càng hiệu quả thì ngực càng tạo nhiều sữa. Trong những tuần đầu, bé thường bú khoảng 8–12 lần mỗi 24 giờ, cả ngày lẫn đêm, có lúc bú dồn gần như mỗi giờ (bú cụm). Bú cụm là bình thường, không có nghĩa là mẹ thiếu sữa.',
          ),
          p(
            'Bé sụt cân trong mấy ngày đầu là bình thường; theo AAP, mức sụt thường không quá khoảng 8–10% cân nặng lúc sinh. Phần lớn bé lấy lại cân nặng lúc sinh vào khoảng 2 tuần tuổi và gần như tất cả vào 3 tuần tuổi.',
          ),
          h('Ba mẹ có thể làm gì'),
          h('Trong mỗi cữ bú'),
          ul(
            'Cho bú khi thấy dấu hiệu đói sớm: cựa quậy, quay đầu tìm vú, há miệng, mút tay. Khóc là dấu hiệu đói muộn; dỗ bé dịu lại rồi mới cho bú.',
            'Ôm bé sát người, đầu và thân bé thẳng hàng, mũi bé ngang núm vú. Để đầu bé hơi ngửa ra sau, không giữ chặt gáy bé.',
            'Chờ bé há miệng thật rộng rồi đưa bé vào vú, cằm chạm vú trước. Đưa bé đến với vú, không ấn vú vào miệng bé.',
            'Dấu hiệu ngậm tốt: thấy quầng vú phía trên môi trên nhiều hơn phía dưới môi dưới, má bé căng tròn (không hóp), bé mút nhanh vài cái rồi chuyển sang mút chậm, sâu, nghe tiếng nuốt.',
            'Lúc đầu mẹ có thể thấy căng kéo, nhưng không nên đau suốt cữ. Nếu đau, đưa ngón tay út sạch vào khoé miệng bé để bé nhả vú rồi cho ngậm lại.',
            'Để bé bú hết một bên và tự nhả ra, rồi mời bên còn lại. Không cần canh đồng hồ.',
            'Cho bú cả ngày lẫn đêm. Nếu bé ngủ li bì trong tuần đầu, đánh thức nhẹ để bú.',
          ),
          h('Khi ngực đau hoặc căng'),
          ul(
            'Đau, nứt, chảy máu đầu vú thường do khớp ngậm chưa tốt. Nhờ nữ hộ sinh hoặc tư vấn viên sữa mẹ xem một cữ bú để chỉnh sớm.',
            'Căng sữa: cho bú theo nhu cầu; nếu quá căng, vắt tay một ít cho mềm quầng vú rồi cho bé ngậm, chỉ vắt đủ cho dễ chịu, không cố vắt kiệt. Chườm mát hoặc túi lạnh bọc khăn giữa các cữ để đỡ sưng đau; tránh chườm nóng lâu.',
            'Cục cứng, đau trong vú (tắc tia sữa) hoặc viêm vú: tiếp tục cho bú bên đó như thường lệ, không bóp nặn hay xoa bóp mạnh vào cục cứng. Chỉ vuốt rất nhẹ trên da từ vùng đau về phía nách, chườm mát, và hỏi bác sĩ về thuốc giảm đau, chống viêm dùng được khi cho con bú. Xử trí sớm để tránh nặng lên.',
            'Bé khó ngậm, bú rất lâu mà vẫn đói, bú có tiếng “tặc tặc”, hoặc mẹ vẫn đau dù đã chỉnh tư thế: hỏi bác sĩ về dính phanh lưỡi.',
            'Mẹ cần uống thuốc: hỏi bác sĩ hoặc dược sĩ và nói rõ đang cho con bú. Rất ít thuốc thông thường buộc mẹ phải ngừng cho bú.',
          ),
          tip(
            'Tìm hỗ trợ sớm',
            'Khó khăn lúc đầu rất thường gặp và phần lớn sửa được. Hỏi nữ hộ sinh, phòng khám nhi hoặc tư vấn viên sữa mẹ ngay trong tuần đầu, đừng đợi đến khi quá mệt.',
          ),
          h('Theo dõi những gì'),
          ul(
            'Tã ướt: ngày 1–2 khoảng 1–2 tã; ngày 3–4 từ 3 tã trở lên và nặng dần; từ ngày 5 ít nhất 6 tã ướt nặng mỗi 24 giờ, nước tiểu nhạt màu.',
            'Phân: phân su đen, dính trong 1–2 ngày đầu, chuyển dần sang xanh nâu; từ khoảng ngày 4–5 có ít nhất 2 lần phân vàng, mềm hoặc lỏng mỗi ngày.',
            'Trong cữ bú: nghe thấy bé nuốt; sau cữ ngực mẹ mềm hơn, bé thả lỏng, thoả mãn.',
            'Cân nặng: cân lại theo hẹn của bác sĩ trong 1–2 tuần đầu.',
            'Màu da và lòng trắng mắt: vàng da lan rộng hoặc đậm lên cần cho bác sĩ xem.',
          ),
          p('Ghi cữ bú và số tã trong Child Life giúp ba mẹ trả lời dễ hơn khi bác sĩ hỏi.'),
          h('Hiểu lầm thường gặp'),
          ul(
            '“Sữa non bẩn, phải vắt bỏ” → Sữa non không bẩn; WHO coi đây là thức ăn hoàn hảo cho bé sơ sinh. → Cho bé bú ngay trong giờ đầu, không vắt bỏ giọt nào.',
            '“Cho bé uống chút nước đường, nước cam thảo hay nước lọc cho sạch miệng” → Ông bà làm vì thương cháu, nhưng bé không cần; nước làm bé no giả, bú mẹ ít đi và thêm nguy cơ nhiễm khuẩn. → Trong 6 tháng đầu chỉ bú mẹ, không cho thêm nước hay đồ uống nào trừ khi bác sĩ chỉ định.',
            '“Sữa mẹ loãng, ít, phải cho bú bình thêm ngay” → Nhìn màu sữa không biết được sữa tốt hay không, và những ngày đầu bé chỉ cần lượng nhỏ. Thêm sữa công thức sớm khiến bé bú mẹ ít hơn và ngực tạo ít sữa đi. → Dựa vào tã và cân nặng; nếu lo bé thiếu sữa, gặp nhân viên y tế trước khi tự thêm sữa công thức.',
            '“Phải ăn móng giò, kiêng đủ thứ mới có sữa” → Món ăn nấu vì thương mẹ là điều quý, nhưng mẹ không cần chế độ ăn đặc biệt, còn kiêng khem dễ làm mẹ thiếu chất. Lượng sữa phụ thuộc chủ yếu vào việc bé bú thường xuyên, ngậm đúng. → Ăn đa dạng, uống nước khi khát, cho bú theo nhu cầu.',
            '“Mẹ bị cảm cúm thì phải ngừng cho bú” → Cúm không lây qua sữa mẹ, và sữa mẹ có kháng thể giúp bảo vệ bé. → Rửa tay trước khi bế bé, có thể đeo khẩu trang, tiếp tục cho bú; hỏi bác sĩ nếu mẹ ốm nặng hoặc cần dùng thuốc.',
          ),
          doctor(
            'Gọi 115 hoặc đến cấp cứu ngay khi',
            'Bé khó thở, tím tái hoặc có lúc ngừng thở; bé li bì, rất khó đánh thức, không chịu bú; bé có dấu hiệu mất nước rõ như rất ít hoặc không có tã ướt, môi khô, thóp lõm. Cũng gọi 115 nếu mẹ thấy rất mệt, lả đi hoặc lơ mơ, nhất là khi đang sốt.',
          ),
          doctor(
            'Đưa bé đi khám sớm (trong ngày) khi',
            'Từ ngày 5 bé có ít hơn 6 tã ướt mỗi ngày, nước tiểu sẫm màu hoặc vẫn đi phân su; bé bú ít hơn 8 cữ mỗi ngày hoặc thường ngủ thiếp trước khi nuốt được nhiều; vàng da lan rộng, đậm lên; bé dưới 3 tháng sốt từ 38 °C trở lên; bé chưa lấy lại cân nặng lúc sinh sau 2 tuần. Mẹ nên đi khám khi một vùng vú sưng, nóng, đỏ, đau kèm sốt hoặc mệt như cúm, không đỡ sau 12–24 giờ, hoặc đầu vú nứt, chảy máu.',
          ),
        ],
        en: [
          note(
            'In short',
            'Hold your baby skin-to-skin and breastfeed within the first hour after birth, then feed on demand, usually 8–12 times every 24 hours. Colostrum comes in small amounts but is the perfect food for a newborn, and your baby needs no water or other milk. The most reliable way to know your baby is getting enough is to count wet and dirty diapers and track their weight.',
          ),
          h('Understanding the first weeks of breastfeeding'),
          p(
            'WHO and UNICEF recommend breastfeeding within 1 hour of birth and exclusively for the first 6 months, with no other food or drink, not even water, unless there is a medical reason. Skin-to-skin contact straight after birth, including after a caesarean, keeps your baby warm and calm and helps them find the breast.',
          ),
          p(
            'Colostrum is the thick, golden milk of the first days, which WHO calls the perfect food for the newborn. It is very concentrated, so your baby only needs a small amount at each feed. Around 2–4 days after birth your breasts feel fuller: this is your milk “coming in”.',
          ),
          p(
            'Breast milk works on supply and demand: the more often your baby feeds and the better they remove milk, the more milk your breasts make. In the first weeks babies usually feed about 8–12 times in 24 hours, day and night, sometimes almost every hour (cluster feeding). Cluster feeding is normal and does not mean you are short of milk.',
          ),
          p(
            'Losing some weight in the first few days is normal; according to the AAP, the loss is usually no more than about 8–10% of birth weight. Most babies are back to their birth weight by about 2 weeks of age, and almost all by 3 weeks.',
          ),
          h('What you can do'),
          h('At each feed'),
          ul(
            'Feed when you see early hunger cues: stirring, turning to find the breast, opening the mouth, sucking on hands. Crying is a late hunger sign; calm your baby first, then feed.',
            "Hold your baby close, head and body in a straight line, nose level with your nipple. Let their head tip back slightly and don't hold the back of their head firmly.",
            'Wait for a wide-open mouth, then bring your baby to the breast, chin touching first. Bring your baby to the breast rather than pushing the breast into their mouth.',
            'Signs of a good latch: more of the areola showing above the top lip than below the bottom lip, full rounded cheeks (not sucked in), a few quick sucks followed by slow, deep sucks, and audible swallowing.',
            "You may feel a pulling sensation at first, but it shouldn't hurt throughout the feed. If it hurts, slip a clean little finger into the corner of your baby's mouth to break the latch, then try again.",
            'Let your baby finish one breast and come off by themselves, then offer the other. No need to watch the clock.',
            'Feed day and night. If your baby is very sleepy in the first week, wake them gently for feeds.',
          ),
          h('When your breasts are sore or full'),
          ul(
            'Sore, cracked or bleeding nipples are usually caused by a shallow latch. Ask a midwife or breastfeeding counsellor to watch a feed and help early.',
            'Engorgement: feed responsively; if very full, hand express a little to soften the areola before your baby latches, only enough to feel comfortable, not to empty the breast. Use cool packs wrapped in cloth between feeds to ease swelling and pain; avoid prolonged heat.',
            'A hard, painful lump (blocked duct) or mastitis: keep feeding from that breast as usual and do not squeeze or massage the lump hard. Use only very light strokes over the skin from the sore area towards the armpit, cool packs, and ask a doctor about pain and anti-inflammatory medicines that are safe while breastfeeding. Act early so it does not get worse.',
            'If your baby struggles to latch, feeds for a very long time and is still hungry, makes clicking sounds, or you still have pain after fixing the position: ask a doctor about tongue-tie.',
            'If you need medicine: ask a doctor or pharmacist and tell them you are breastfeeding. Very few common medicines mean you have to stop breastfeeding.',
          ),
          tip(
            'Get help early',
            "Early difficulties are very common and most can be fixed. Ask a midwife, your baby clinic or a breastfeeding counsellor in the first week; don't wait until you are exhausted.",
          ),
          h('What to watch'),
          ul(
            'Wet diapers: days 1–2 about 1–2; days 3–4 at least 3 and getting heavier; from day 5 at least 6 heavy wet diapers every 24 hours, with pale urine.',
            'Poo: black, sticky meconium for the first 1–2 days, changing to greenish brown; from around day 4–5 at least 2 yellow, soft or runny poos a day.',
            'During feeds: you can hear your baby swallowing; afterwards your breasts feel softer and your baby is relaxed and content.',
            'Weight: go back for weigh-ins as your doctor advises in the first 1–2 weeks.',
            'Skin and whites of the eyes: yellowing that is spreading or deepening should be checked by a doctor.',
          ),
          p(
            'Logging feeds and diapers in Child Life makes it easier to answer the doctor’s questions.',
          ),
          h('Common myths'),
          ul(
            '“Colostrum is dirty and should be expressed and thrown away” → Colostrum is not dirty; WHO calls it the perfect food for the newborn. → Breastfeed within the first hour and keep every drop.',
            "“Give a little sugar water, liquorice water or plain water to clean the mouth” → Grandparents do this out of love, but babies don't need it; water fills them up, means less breastfeeding and adds a risk of infection. → For the first 6 months give only breast milk, no water or other drinks unless a doctor advises it.",
            "“Breast milk is thin and scarce, so add a bottle straight away” → You can't judge milk by its colour, and in the first days babies only need small amounts. Adding formula early means less breastfeeding and less milk made. → Go by diapers and weight; if you are worried about supply, see a health worker before adding formula yourself.",
            "“You must eat pig's trotter soup and avoid lots of foods to make milk” → Food cooked with love for a new mother is precious, but you don't need a special diet, and avoiding foods can leave you short of nutrients. Milk supply depends mainly on frequent feeding and a good latch. → Eat a varied diet, drink when thirsty and feed on demand.",
            '“A mother with a cold or flu must stop breastfeeding” → Flu is not passed on through breast milk, and breast milk contains antibodies that help protect your baby. → Wash your hands before holding your baby, wear a mask if you like and keep breastfeeding; ask a doctor if you are very unwell or need medicine.',
          ),
          doctor(
            'Call 115 or go to the emergency department now if',
            'Your baby has trouble breathing, turns blue or has pauses in breathing; is very drowsy, very hard to wake or will not feed; or shows clear signs of dehydration such as very few or no wet diapers, a dry mouth or a sunken soft spot. Call too if you, the mother, feel very unwell, faint or confused, especially with a fever.',
          ),
          doctor(
            'See a doctor the same day if',
            "From day 5 your baby has fewer than 6 wet diapers a day, dark urine or is still passing meconium; feeds fewer than 8 times a day or often falls asleep before swallowing much; has yellow skin that is spreading or deepening; is under 3 months with a temperature of 38 °C or higher; or isn't back to birth weight after 2 weeks. See a doctor yourself if part of a breast is swollen, hot, red and painful with fever or flu-like feelings and not better within 12–24 hours, or if your nipples are cracked and bleeding.",
          ),
        ],
      },
      keywords: t(
        [
          'bú mẹ',
          'khớp ngậm',
          'sữa non',
          'cữ bú',
          'bú cụm',
          'tã ướt',
          'căng sữa',
          'viêm vú',
          'dính phanh lưỡi',
          'da kề da',
        ],
        [
          'breastfeeding',
          'latch',
          'colostrum',
          'feeds',
          'cluster feeding',
          'wet diapers',
          'engorgement',
          'mastitis',
          'tongue-tie',
          'skin-to-skin',
        ],
      ),
      relatedArticleIds: [
        'art_expressing_storing_milk',
        'art_formula_bottle',
        'art_newborn_jaundice',
        'art_vitamin_d_iron',
      ],
      milestoneIds: [],
      sources: [
        S.whoVietnamBreastfeeding,
        S.nhsBfFirstDays,
        S.nhsBfPositioning,
        S.nhsBfEnoughMilk,
        {
          label:
            'Academy of Breastfeeding Medicine — Clinical Protocol #36: The mastitis spectrum (revised 2022)',
          url: 'https://www.bfmed.org/protocols',
        },
        S.hcBfEnoughMilk,
        S.hcFirstMonthGrowth,
        S.cdcFluBreastfeeding,
      ],
    },
  },
  {
    id: 'art_expressing_storing_milk',
    reviewerLabel: LACTATION,
    data: {
      library: 'care',
      topic: 'feeding',
      format: 'step_guide',
      ageWeeks: { from: 0, to: 52 },
      readingMinutes: 5,
      cover: null,
      title: t(
        'Vắt và trữ sữa mẹ an toàn: từng bước',
        'Expressing and storing breast milk safely: step by step',
      ),
      summary: t(
        'Cách vắt sữa bằng tay hoặc máy, vệ sinh bộ vắt, thời gian giữ sữa ở nhiệt độ phòng, tủ lạnh, tủ đông, và cách rã đông, hâm ấm an toàn cho bé.',
        'How to express by hand or pump, clean your pump kit, how long milk keeps at room temperature, in the fridge and freezer, and how to thaw and warm it safely.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Rửa tay, dùng dụng cụ sạch, dán nhãn ngày giờ và cất lạnh càng sớm càng tốt. Theo CDC: nhiệt độ phòng (25 °C trở xuống) tối đa 4 giờ, ngăn mát tối đa 4 ngày, tủ đông tốt nhất trong 6 tháng. Không rã đông hay hâm sữa bằng lò vi sóng.',
          ),
          h('Hiểu đúng về vắt và trữ sữa'),
          p(
            'Mẹ có thể cần vắt sữa khi phải xa bé, khi đi làm lại, khi bé chưa ngậm hoặc bú tốt, hoặc khi ngực căng khó chịu. Ngực tạo sữa theo lượng sữa được lấy ra, nên vắt đều đặn giúp duy trì nguồn sữa. Ngược lại, khi chỉ căng sữa, mẹ chỉ nên vắt đủ cho dễ chịu, vì vắt nhiều sẽ làm ngực tạo thêm sữa.',
          ),
          p(
            'Sữa mẹ vẫn có thể nhiễm khuẩn nếu dụng cụ bẩn hoặc để ở nơi nóng quá lâu. Các tổ chức đưa ra mốc thời gian khác nhau: CDC (Mỹ) cho phép giữ ở ngăn mát tối đa 4 ngày, còn NHS (Anh) cho tới 8 ngày nếu tủ luôn ở 4 °C hoặc lạnh hơn. Nhà ở Việt Nam thường nóng, tủ lạnh hay được mở và có lúc mất điện, nên bài này theo mốc thận trọng hơn của CDC.',
          ),
          h('Ba mẹ có thể làm gì'),
          ul(
            'Bước 1 · Chuẩn bị: rửa tay bằng xà phòng khoảng 20 giây. Lắp bộ vắt sạch, kiểm tra không có vết mốc hay cặn sữa. Dùng bình hoặc túi trữ sữa chuyên dụng có nắp kín, không dùng túi nilon thông thường.',
            'Bước 2 · Giúp sữa xuống: ngồi thoải mái, chườm ấm, xoa nhẹ ngực từ phía nách về núm vú. Nhìn ảnh hoặc ôm áo của bé cũng giúp sữa dễ xuống.',
            'Bước 3 · Vắt tay: khum tay đỡ ngực, đặt ngón cái và ngón trỏ thành hình chữ C cách núm vú vài centimet. Bóp nhẹ, thả ra, lặp lại đều nhịp. Không trượt ngón tay trên da, không bóp vào núm vú.',
            'Bước 4 · Khi sữa chảy chậm: xoay vị trí ngón tay quanh quầng vú, rồi đổi sang bên kia. Lặp lại vài lượt.',
            'Bước 5 · Dùng máy hút: chọn cỡ phễu vừa, bắt đầu ở lực hút nhẹ rồi tăng dần; lực mạnh ngay từ đầu dễ gây đau và tổn thương núm vú.',
            'Bước 6 · Dán nhãn và cất ngay: ghi ngày giờ vắt, chia phần nhỏ khoảng 60–120 ml (vừa một cữ), chừa khoảng trống ở miệng bình nếu cấp đông. Để sâu trong tủ, không để ở cánh cửa tủ vì nhiệt độ ở đó dao động.',
            'Bước 7 · Vệ sinh bộ vắt: tháo rời, tráng sữa dưới vòi nước, rửa với nước rửa trong một chậu riêng (không đặt thẳng vào bồn rửa bát), để khô tự nhiên trên khăn sạch. Tiệt trùng ít nhất mỗi ngày một lần, ví dụ đun sôi 5 phút, nhất là khi bé dưới 2 tháng, sinh non hoặc sức đề kháng yếu.',
            'Bước 8 · Rã đông: tốt nhất để qua đêm trong ngăn mát; cần nhanh thì ngâm bình đậy kín trong nước ấm. Không dùng lò vi sóng, không đun trực tiếp trên bếp.',
            'Bước 9 · Cho bé dùng: lắc nhẹ cho đều, nhỏ vài giọt lên cổ tay để thử độ ấm. Bé có thể uống sữa ở nhiệt độ phòng hoặc sữa mát. Sữa bé bú còn thừa phải bỏ đi trong vòng 2 giờ.',
          ),
          h('Sữa giữ được bao lâu'),
          ul(
            'Nhiệt độ phòng từ 25 °C trở xuống: tối đa 4 giờ. Phòng nóng hơn thì đừng dựa vào mốc này, hãy cất lạnh ngay sau khi vắt.',
            'Túi hoặc thùng giữ lạnh có túi đá: tối đa 24 giờ, sau đó chuyển vào tủ lạnh hoặc dùng.',
            'Ngăn mát tủ lạnh (khoảng 4 °C): tối đa 4 ngày. Không dùng kịp thì cấp đông ngay.',
            'Ngăn đá nhỏ nằm trong tủ lạnh: NHS khuyên chỉ giữ khoảng 2 tuần.',
            'Tủ đông riêng (khoảng −18 °C): tốt nhất trong 6 tháng, chấp nhận được đến 12 tháng.',
            'Sữa rã đông trong ngăn mát: dùng trong 24 giờ kể từ khi tan hết (CDC); NHS khuyên dùng ngay. Không cấp đông lại.',
            'Sữa đã để về nhiệt độ phòng hoặc đã hâm ấm: dùng trong 2 giờ.',
          ),
          tip(
            'Khi mất điện',
            'Giữ cửa tủ đóng kín. Nếu mất điện lâu, chuyển sữa sang thùng giữ lạnh có nhiều túi đá. Sữa đã tan hết thì xử lý như sữa rã đông: giữ lạnh, dùng trong 24 giờ, không cấp đông lại.',
          ),
          h('Theo dõi'),
          ul(
            'Nhiệt độ tủ: nếu tủ không ổn định, khoảng 5–10 °C, NHS khuyên dùng sữa trong 3 ngày.',
            'Lượng vắt được mỗi ngày: nếu giảm rõ nhiều ngày liền dù vắt đều, hỏi tư vấn viên sữa mẹ.',
            'Ngực: cục cứng đau, vùng đỏ nóng, đầu vú nứt hay đau khi hút cần được xem sớm.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            '“Hâm sữa bằng lò vi sóng cho nhanh” → Lò vi sóng làm sữa nóng không đều, có điểm rất nóng có thể gây bỏng miệng bé. → Ngâm bình kín trong nước ấm và thử trên cổ tay.',
            '“Sữa mẹ để ngoài cả ngày cũng không sao” → Ở nhiệt độ phòng vi khuẩn phát triển nhanh, nhất là khi trời nóng. → Cất lạnh trong vòng 4 giờ, càng sớm càng tốt; mang túi giữ lạnh khi đi làm.',
            '“Sữa bé bú dở để dành cho cữ sau” → Sau khi bé bú, sữa đã lẫn nước bọt của bé. → Bỏ phần thừa trong vòng 2 giờ; chia phần nhỏ để đỡ phí.',
            '“Sữa rã đông dùng không hết thì cấp đông lại” → Sữa đã rã đông không được cấp đông lại. → Chỉ rã đông lượng đủ cho một hai cữ.',
          ),
          doctor(
            'Khi nào nên hỏi bác sĩ',
            'Mẹ nên đi khám khi một vùng vú sưng, đỏ, nóng, đau kèm sốt hoặc mệt như cúm; đầu vú nứt, chảy máu hoặc đau kéo dài khi vắt. Đưa bé đi khám nếu bé bú kém, ít tã ướt, nôn nhiều hoặc tiêu chảy. Gọi 115 nếu bé khó thở, tím tái hoặc li bì; nếu bé sặc sữa, xem hướng dẫn trong mục Sơ cứu trẻ em của Child Life.',
          ),
        ],
        en: [
          note(
            'In short',
            'Wash your hands, use clean equipment, label the date and time and chill milk as soon as you can. According to the CDC: up to 4 hours at room temperature (25 °C or cooler), up to 4 days in the fridge, and ideally within 6 months in the freezer. Never thaw or warm milk in a microwave.',
          ),
          h('Understanding expressing and storing milk'),
          p(
            "You may need to express when you are apart from your baby, going back to work, when your baby can't yet latch or feed well, or when your breasts feel uncomfortably full. Your breasts make milk according to how much is removed, so expressing regularly helps keep up your supply. On the other hand, if you are just engorged, express only enough to feel comfortable, because expressing more makes your breasts produce more.",
          ),
          p(
            'Breast milk can still pick up germs from dirty equipment or from being kept warm too long. Guidelines give different time limits: the CDC (US) allows up to 4 days in the fridge, while the NHS (UK) allows up to 8 days if the fridge is always at 4 °C or colder. Homes in Vietnam are often hot, fridges are opened often and power cuts happen, so this guide follows the more cautious CDC limits.',
          ),
          h('What you can do'),
          ul(
            'Step 1 · Get ready: wash your hands with soap for about 20 seconds. Put together a clean pump kit and check it for mould or milk residue. Use breast milk storage bottles or bags with tight lids, not ordinary plastic bags.',
            'Step 2 · Help your milk flow: sit comfortably, use warmth and gently stroke your breast from the armpit towards the nipple. Looking at a photo of your baby or holding their clothes can help the milk let down.',
            "Step 3 · Hand expressing: cup your breast, then make a C shape with your thumb and forefinger a few centimetres from the nipple. Squeeze gently, release and repeat in a steady rhythm. Don't slide your fingers over the skin or squeeze the nipple itself.",
            'Step 4 · When the flow slows: move your fingers around the areola, then switch to the other breast. Repeat a few times.',
            'Step 5 · Using a pump: choose a flange that fits, start on low suction and increase gradually; strong suction from the start can hurt and damage the nipple.',
            'Step 6 · Label and store straight away: write the date and time, store in small portions of about 60–120 ml (one feed), and leave space at the top if freezing. Keep milk at the back, not in the door, where the temperature changes.',
            'Step 7 · Clean the pump kit: take it apart, rinse off milk under running water, wash with soap in a separate basin (not directly in the sink) and air-dry on a clean towel. Sanitise at least once a day, for example by boiling for 5 minutes, especially if your baby is under 2 months, was born early or has a weakened immune system.',
            "Step 8 · Thawing: ideally overnight in the fridge; if you need it quickly, stand the sealed container in warm water. No microwave, and don't heat it directly on the stove.",
            'Step 9 · Feeding: swirl gently to mix and test a few drops on your wrist. Your baby can drink it at room temperature or cool. Throw away any milk left over from a feed within 2 hours.',
          ),
          h('How long milk keeps'),
          ul(
            "Room temperature of 25 °C or cooler: up to 4 hours. If the room is hotter, don't rely on this limit; chill the milk as soon as you have expressed.",
            'Cool bag or box with ice packs: up to 24 hours, then move it to a fridge or use it.',
            "Fridge (about 4 °C): up to 4 days. If you won't use it in time, freeze it straight away.",
            'Small ice compartment inside a fridge: the NHS advises keeping milk there for only about 2 weeks.',
            'Separate freezer (about −18 °C): ideally within 6 months, up to 12 months is acceptable.',
            'Milk thawed in the fridge: use within 24 hours of being fully thawed (CDC); the NHS advises using it straight away. Never refreeze.',
            'Milk brought to room temperature or warmed: use within 2 hours.',
          ),
          tip(
            'During a power cut',
            'Keep the fridge and freezer doors closed. If the cut is long, move milk to a cool box with plenty of ice packs. Treat milk that has fully thawed as thawed milk: keep it cold, use within 24 hours and never refreeze.',
          ),
          h('What to watch'),
          ul(
            'Fridge temperature: if your fridge is unreliable, around 5–10 °C, the NHS advises using milk within 3 days.',
            'How much you express each day: if it drops clearly for several days despite regular expressing, ask a breastfeeding counsellor.',
            'Your breasts: a painful lump, a red hot area, cracked nipples or pain while pumping should be checked early.',
          ),
          h('Common myths'),
          ul(
            "“Warm milk in the microwave to save time” → Microwaves heat unevenly and create very hot spots that can scald your baby's mouth. → Stand the sealed bottle in warm water and test on your wrist.",
            '“Breast milk can sit out all day” → Germs grow quickly at room temperature, especially in hot weather. → Chill within 4 hours, the sooner the better; take a cool bag to work.',
            '“Save a half-finished bottle for the next feed” → Once your baby has fed, the milk contains their saliva. → Throw leftovers away within 2 hours; store small portions to cut waste.',
            "“Refreeze thawed milk if it isn't all used” → Thawed breast milk must never be refrozen. → Thaw only enough for one or two feeds.",
          ),
          doctor(
            'When to ask a doctor',
            'See a doctor yourself if part of a breast is swollen, red, hot and painful with fever or flu-like feelings, or if your nipples are cracked, bleeding or keep hurting when you express. Take your baby to a doctor if they feed poorly, have fewer wet diapers, vomit a lot or have diarrhoea. Call 115 (Vietnam emergency) if your baby has trouble breathing, turns blue or is very drowsy; if your baby chokes on milk, see the Sơ cứu trẻ em (First aid) guide in Child Life.',
          ),
        ],
      },
      keywords: t(
        [
          'vắt sữa',
          'trữ sữa',
          'máy hút sữa',
          'vắt tay',
          'rã đông sữa',
          'hâm sữa',
          'túi trữ sữa',
          'mất điện',
          'đi làm lại',
        ],
        [
          'expressing',
          'storing milk',
          'breast pump',
          'hand expressing',
          'thawing milk',
          'warming milk',
          'milk storage bags',
          'power cut',
          'back to work',
        ],
      ),
      relatedArticleIds: ['art_breastfeeding_start', 'art_formula_bottle', 'art_parent_wellbeing'],
      milestoneIds: [],
      sources: [S.cdcBreastMilkStorage, S.nhsBfExpressing, S.cdcBreastPumpClean, S.nhsBfBreastPain],
    },
  },
  {
    id: 'art_formula_bottle',
    reviewerLabel: PAEDS,
    data: {
      library: 'care',
      topic: 'feeding',
      format: 'article',
      ageWeeks: { from: 0, to: 52 },
      readingMinutes: 6,
      cover: null,
      title: t(
        'Pha sữa công thức và cho bé bú bình an toàn',
        'Making up formula and bottle feeding safely',
      ),
      summary: t(
        'Pha từng cữ bằng nước đun sôi, đúng số muỗng gạt ngang, dùng trong 2 giờ, tiệt trùng dụng cụ và cho bé bú theo tín hiệu no, đói của bé.',
        "Make each feed with boiled water and level scoops, use it within 2 hours, sterilise equipment and feed to your baby's hunger and fullness cues.",
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Sữa bột không vô trùng: pha từng cữ bằng nước đun sôi còn nóng từ 70 °C trở lên, đúng số muỗng gạt ngang, làm nguội nhanh rồi cho bú. Sữa đã pha dùng trong 2 giờ, sữa thừa sau cữ bỏ đi. Cho bú theo tín hiệu của bé, không ép hết bình, không bao giờ chống bình.',
          ),
          h('Hiểu đúng về sữa công thức'),
          p(
            'Sữa công thức là nguồn dinh dưỡng thay thế an toàn khi được pha và bảo quản đúng cách. Dù bé bú bình hoàn toàn hay kết hợp với bú mẹ, hai điều quan trọng nhất là vệ sinh và pha đúng tỉ lệ. Sữa bột có thể chứa một lượng nhỏ vi khuẩn, vì vậy nước pha phải đủ nóng và sữa đã pha không được để lâu, nhất là với bé dưới 2 tháng, bé sinh non hoặc sức đề kháng yếu.',
          ),
          p(
            'Pha đặc hơn hướng dẫn có thể làm bé táo bón và mất nước; pha loãng hơn khiến bé không đủ chất và có thể nguy hiểm. Vì vậy luôn pha đúng tỉ lệ ghi trên hộp, không tự thay đổi.',
          ),
          p(
            'Các tổ chức khác nhau một chút về nước pha. NHS (Anh) khuyên mọi bé đều pha bằng nước vừa đun sôi, để nguội không quá 30 phút để nước còn từ 70 °C trở lên. CDC và AAP (Mỹ) chỉ yêu cầu bước nước nóng này cho bé dưới 2 tháng, sinh non hoặc suy giảm miễn dịch, còn lại có thể dùng nước máy an toàn. Ở Việt Nam, nên theo cách thận trọng: luôn đun sôi nước.',
          ),
          p(
            'Về lượng sữa, theo AAP: tuần đầu bé thường bú khoảng 30–60 ml mỗi cữ, đến khoảng 1 tháng tăng dần lên 90–120 ml mỗi cữ, cách nhau khoảng 3–4 giờ; bé thường không cần quá khoảng 960 ml mỗi ngày. Đây chỉ là con số trung bình, mỗi bé một nhịp, hãy nhìn tín hiệu của bé.',
          ),
          h('Ba mẹ có thể làm gì'),
          h('Vệ sinh dụng cụ'),
          ul(
            'Rửa tay bằng xà phòng và lau sạch mặt bàn trước khi pha sữa.',
            'Rửa bình, núm ti ngay sau mỗi cữ bằng nước rửa ấm và cọ riêng, rồi tráng sạch.',
            'Tiệt trùng bình và núm ti cho đến khi bé ít nhất 12 tháng: luộc ngập nước ít nhất 10 phút, hoặc dùng máy tiệt trùng hơi nước theo hướng dẫn.',
            'Để dụng cụ trong nồi hoặc máy tiệt trùng đến khi dùng; lấy ra thì lắp ngay núm và nắp.',
          ),
          h('Pha từng cữ'),
          ul(
            'Bước 1 · Đun sôi nước sạch, để nguội không quá 30 phút để nước còn khoảng 70 °C trở lên. Nước trong phích để từ lâu có thể không còn đủ nóng.',
            'Bước 2 · Rót nước vào bình trước, đúng vạch theo hướng dẫn trên hộp.',
            'Bước 3 · Dùng đúng muỗng đi kèm hộp, gạt ngang bằng dao sạch, không nén, đúng số muỗng hướng dẫn.',
            'Bước 4 · Đậy nắp, lắc đều. Làm nguội nhanh bằng cách để bình đã đậy dưới vòi nước mát hoặc ngâm trong bát nước mát.',
            'Bước 5 · Nhỏ vài giọt lên mặt trong cổ tay: âm ấm hoặc mát, không nóng.',
            'Bước 6 · Cho bú ngay. Sữa đã pha dùng trong 2 giờ và trong 1 giờ kể từ khi bé bắt đầu bú; sữa thừa sau cữ bỏ đi. Tốt nhất pha cữ nào dùng cữ nấy; nếu buộc phải pha sẵn, CDC cho phép cất ngay vào ngăn mát và dùng trong 24 giờ.',
          ),
          h('Cho bú theo tín hiệu của bé'),
          ul(
            'Bế bé gần như ngồi, đỡ đầu, nhìn và trò chuyện với bé. Những tuần đầu, nên để ba mẹ hoặc người chăm chính cho bú phần lớn các cữ.',
            'Chạm núm ti vào môi để bé tự há miệng ngậm. Giữ bình gần như nằm ngang, chỉ hơi nghiêng để sữa chảy đều, bé ít nuốt hơi.',
            'Cho bé nghỉ giữa chừng và vỗ ợ hơi sau mỗi khoảng 60–90 ml.',
            'Bé no khi bú chậm lại, quay đi, nhả ti, đẩy bình hoặc cựa quậy, lơ đãng. Dừng lại, không ép bé bú hết bình.',
            'Không bao giờ chống bình để bé tự bú và không để bé ngậm bình ngủ, vì bé có thể bị sặc.',
          ),
          note(
            'Bé dưới 6 tháng có cần uống thêm nước?',
            'Sữa công thức pha đúng đã đủ nước cho bé. NHS cho biết khi trời nóng, bé bú bình dưới 6 tháng có thể cần vài ngụm nước đun sôi để nguội; hãy hỏi bác sĩ trước, và không bao giờ pha loãng sữa để “thêm nước”.',
          ),
          h('Theo dõi'),
          ul(
            'Số cữ và lượng mỗi cữ, nhất là khi bé đổi sữa hoặc bị ốm.',
            'Tã ướt: từ cuối tuần đầu khoảng 6 tã trở lên mỗi ngày, nước tiểu nhạt màu.',
            'Phân: phân cứng, bé rặn khó có thể do pha đặc hơn hướng dẫn; kiểm tra lại cách đong.',
            'Cân nặng và chiều dài ở mỗi lần khám.',
            'Nôn trớ nhiều, nổi mẩn hoặc tiêu chảy sau khi bú.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            '“Pha đặc cho bé mau lớn” → Ông bà mong cháu bụ bẫm, nhưng thừa bột so với nước có thể làm bé táo bón, mất nước. → Đúng số muỗng gạt ngang, đúng lượng nước.',
            '“Cho thêm bột, nước cháo hay ngũ cốc vào bình cho bé no lâu, ngủ ngon” → Bé có thể bị sặc và ăn nhiều hơn mức cần, dễ tăng cân quá mức; AAP khuyên không cho bột ngũ cốc vào bình trừ khi bác sĩ chỉ định. → Trong bình chỉ có sữa; ăn dặm bằng thìa khi bé sẵn sàng, khoảng 6 tháng.',
            '“Sữa đặc có đường cũng là sữa” → Sữa đặc rất nhiều đường, không phải sữa công thức và không dùng cho bé dưới 1 tuổi. → Chỉ dùng sữa mẹ hoặc sữa công thức dành cho trẻ nhũ nhi.',
            '“Pha sẵn một bình rồi ủ ấm cả đêm cho tiện” → Sữa ấm để lâu là môi trường tốt cho vi khuẩn phát triển. → Pha cữ nào dùng cữ nấy; chuẩn bị sẵn bình sạch, hộp sữa và ấm đun nước để pha nhanh khi bé dậy.',
          ),
          doctor(
            'Gọi 115 hoặc đến cấp cứu ngay khi',
            'Bé khó thở, tím tái hoặc sặc sữa mà không hồi lại nhanh (xem hướng dẫn trong mục Sơ cứu trẻ em của Child Life); bé li bì, khó đánh thức; nôn ra dịch xanh hoặc có máu; môi, mặt sưng hoặc nổi mẩn kèm khó thở sau khi bú.',
          ),
          doctor(
            'Đưa bé đi khám sớm (trong ngày) khi',
            'Bé bỏ nhiều cữ hoặc bú kém; ít tã ướt, nước tiểu sẫm; nôn vọt nhiều lần; tiêu chảy; nổi mẩn sau khi bú; không tăng cân; bé dưới 3 tháng sốt từ 38 °C trở lên.',
          ),
        ],
        en: [
          note(
            'In short',
            "Powdered formula is not sterile: make each feed with boiled water still at 70 °C or above, use level scoops, cool it quickly and feed. Use made-up formula within 2 hours and throw away what's left after a feed. Feed to your baby's cues, don't make them finish the bottle and never prop the bottle.",
          ),
          h('Understanding formula'),
          p(
            'Formula is a safe alternative source of nutrition when it is made up and stored correctly. Whether your baby is fully bottle-fed or also breastfed, the two most important things are hygiene and the right proportions. Powdered formula can contain small amounts of germs, so the water must be hot enough and made-up formula must not be kept for long, especially for babies under 2 months, born early or with a weakened immune system.',
          ),
          p(
            "Making feeds stronger than directed can cause constipation and dehydration; making them weaker means your baby doesn't get enough nutrition and can be dangerous. So always use the proportions on the tin and don't change them.",
          ),
          p(
            'Guidelines differ slightly on the water. The NHS (UK) advises making every feed with freshly boiled water left to cool for no more than 30 minutes, so it is still at 70 °C or above. The CDC and AAP (US) only require this hot-water step for babies under 2 months, born early or with weakened immunity, and otherwise allow safe tap water. In Vietnam, take the cautious route: always boil the water.',
          ),
          p(
            "On amounts, according to the AAP: in the first week babies usually take about 30–60 ml per feed, rising to 90–120 ml per feed by about 1 month, every 3–4 hours or so; babies usually don't need more than about 960 ml a day. These are only averages; every baby has their own rhythm, so watch your baby's cues.",
          ),
          h('What you can do'),
          h('Keeping equipment clean'),
          ul(
            'Wash your hands with soap and wipe down the surface before making up a feed.',
            'Wash bottles and teats right after each feed in warm soapy water with a dedicated brush, then rinse.',
            'Sterilise bottles and teats until your baby is at least 12 months old: boil fully covered in water for at least 10 minutes, or use a steam steriliser following its instructions.',
            'Leave equipment in the pan or steriliser until needed; when you take it out, put the teat and lid on straight away.',
          ),
          h('Making each feed'),
          ul(
            'Step 1 · Boil clean water and leave it to cool for no more than 30 minutes so it is still around 70 °C or above. Water that has been in a thermos for a long time may not be hot enough.',
            'Step 2 · Pour the water into the bottle first, to the line given on the tin.',
            'Step 3 · Use only the scoop that comes with the tin, level it with a clean knife without packing it down, and add the number of scoops directed.',
            'Step 4 · Put the lid on and shake well. Cool it quickly by holding the capped bottle under cold running water or standing it in a bowl of cool water.',
            'Step 5 · Test a few drops on the inside of your wrist: lukewarm or cool, not hot.',
            "Step 6 · Feed straight away. Use made-up formula within 2 hours, and within 1 hour of your baby starting the feed; throw away what's left afterwards. It's best to make each feed fresh; if you must make one ahead, the CDC allows putting it straight into the fridge and using it within 24 hours.",
          ),
          h("Feeding to your baby's cues"),
          ul(
            'Hold your baby fairly upright with their head supported, looking at them and talking. In the early weeks, try to have parents or the main carer give most feeds.',
            'Touch the teat to their lips so they open their mouth and take it in. Hold the bottle almost horizontal, tipped just enough for a steady flow so your baby swallows less air.',
            'Let your baby pause during the feed and burp them after every 60–90 ml or so.',
            'Your baby is full when they slow down, turn away, let go of the teat, push the bottle away or get fidgety and distracted. Stop then; never force them to finish the bottle.',
            'Never prop a bottle for your baby to feed alone and never let them fall asleep sucking on a bottle, as they could choke.',
          ),
          note(
            'Do babies under 6 months need extra water?',
            'Correctly made formula gives your baby enough fluid. The NHS says that in hot weather, formula-fed babies under 6 months may need a few sips of cooled boiled water; ask your doctor first, and never water down formula to “add water”.',
          ),
          h('What to watch'),
          ul(
            'How many feeds and how much at each, especially when changing formula or when your baby is ill.',
            'Wet diapers: from the end of the first week about 6 or more a day, with pale urine.',
            'Poo: hard poo and straining can be a sign feeds are made too strong; check how you measure.',
            'Weight and length at each check-up.',
            'Frequent vomiting, a rash or diarrhoea after feeds.',
          ),
          h('Common myths'),
          ul(
            '“Make it thicker so the baby grows faster” → Grandparents want a chubby grandchild, but too much powder for the water can cause constipation and dehydration. → Level scoops, the right amount of water.',
            '“Add rice flour, rice water or cereal to the bottle so the baby stays full and sleeps well” → Your baby could choke and take in more than they need, gaining too much weight; the AAP advises against cereal in a bottle unless a doctor recommends it. → Only milk goes in the bottle; start solids with a spoon when your baby is ready, around 6 months.',
            '“Sweetened condensed milk is milk too” → Condensed milk is very high in sugar, is not infant formula and should not be given to babies under 1. → Use only breast milk or infant formula.',
            '“Make up one bottle and keep it warm all night” → Warm milk left standing is ideal for germs to grow. → Make each feed fresh; keep a clean bottle, the tin and a kettle ready so you can make it quickly when your baby wakes.',
          ),
          doctor(
            'Call 115 or go to the emergency department now if',
            'Your baby has trouble breathing, turns blue or chokes on milk and does not recover quickly (see the Sơ cứu trẻ em (First aid) guide in Child Life); is very drowsy or hard to wake; vomits green fluid or blood; or has swelling of the lips or face, or a rash with breathing difficulty, after a feed.',
          ),
          doctor(
            'See a doctor the same day if',
            'Your baby misses several feeds or feeds poorly; has fewer wet diapers or dark urine; vomits forcefully again and again; has diarrhoea; gets a rash after feeds; is not gaining weight; or is under 3 months with a temperature of 38 °C or higher.',
          ),
        ],
      },
      keywords: t(
        [
          'sữa công thức',
          'bú bình',
          'pha sữa',
          'tiệt trùng bình',
          'núm ti',
          'nước pha sữa',
          'lượng sữa',
          'sữa đặc',
          'chống bình',
          'ợ hơi',
        ],
        [
          'formula',
          'bottle feeding',
          'making up feeds',
          'sterilising bottles',
          'teat',
          'water for formula',
          'formula amounts',
          'condensed milk',
          'propping bottle',
          'burping',
        ],
      ),
      relatedArticleIds: [
        'art_breastfeeding_start',
        'art_spit_up_hiccups',
        'art_vitamin_d_iron',
        'art_water_juice',
      ],
      milestoneIds: [],
      sources: [
        S.nhsMakingFormula,
        S.nhsBottleFeedingAdvice,
        S.nhsSterilisingBottles,
        S.nhsFormulaTypes,
        S.cdcFormulaPrep,
        S.hcFormulaWater,
        S.hcFormulaAmount,
        S.hcStartingSolidsCereal,
      ],
    },
  },
  {
    id: 'art_spit_up_hiccups',
    reviewerLabel: PAEDS,
    data: {
      library: 'care',
      topic: 'feeding',
      format: 'article',
      ageWeeks: { from: 0, to: 26 },
      readingMinutes: 5,
      cover: null,
      title: t(
        'Bé ọc sữa, trớ và nấc cụt: khi nào bình thường, khi nào cần khám',
        "Spit-up and hiccups: what's normal and when to see a doctor",
      ),
      summary: t(
        'Ọc sữa và nấc cụt rất thường gặp ở bé nhỏ và giảm dần khi bé lớn. Cách giúp bé bớt trớ, vì sao bé vẫn phải ngủ ngửa, và những dấu hiệu cần đưa bé đi khám.',
        'Spit-up and hiccups are very common in young babies and ease as they grow. How to reduce spit-up, why babies still sleep on their back, and the signs that need a doctor.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Ọc sữa (trào ngược sinh lý) rất thường gặp, thường bắt đầu trong vài tuần đầu, nhiều nhất khoảng 4–5 tháng và hết dần vào khoảng 1 tuổi. Bé vẫn vui, bú tốt, tăng cân đều thì không cần thuốc. Bé luôn ngủ ngửa trên mặt phẳng, kể cả bé hay trớ.',
          ),
          h('Hiểu đúng về ọc sữa và nấc cụt'),
          p(
            'Ở bé nhỏ, cơ ở chỗ nối thực quản và dạ dày chưa khép chặt, dạ dày lại nhỏ, nên sữa dễ trào lên miệng, nhất là khi bé bú no, nuốt hơi hoặc bị xoay trở ngay sau bú. Theo AAP, trào ngược thường bắt đầu khi bé 2–3 tuần, nhiều nhất lúc 4–5 tháng và hết ở phần lớn bé đủ tháng vào 9–12 tháng. NHS cũng cho biết tình trạng này thường bắt đầu trước 8 tuần và cải thiện vào khoảng 1 tuổi, khi cơ khỏe dần.',
          ),
          p(
            'Ọc sữa thường nhẹ nhàng, lượng ít (dù trông có vẻ nhiều trên áo), bé không phải gắng sức và không khó chịu; nhiều bé “trớ mà vẫn vui”. Nôn thì khác: sữa bị tống ra mạnh, lượng nhiều, bé rướn người, có khi lặp lại sau mỗi cữ. Một số bé trào ngược mà không trớ ra ngoài, biểu hiện bằng ho, nấc khi bú, quấy khóc, ưỡn người.',
          ),
          p(
            'Nấc cụt cũng rất phổ biến ở bé nhỏ, hay gặp trong hoặc sau cữ bú. Nấc thường làm ba mẹ lo hơn là làm bé khó chịu, và tự hết.',
          ),
          h('Ba mẹ có thể làm gì'),
          ul(
            'Cho bú ở tư thế đầu cao hơn bụng. Cho bú khi bé vừa có dấu hiệu đói, chưa khóc to, để bé ít nuốt hơi.',
            'Vỗ ợ hơi giữa cữ và cuối cữ: bé bú bình sau mỗi khoảng 60–90 ml, bé bú mẹ khi đổi bên.',
            'Chia cữ nhỏ hơn, gần nhau hơn nếu bé có vẻ bú quá no; không ép bé bú hết bình.',
            'Bế bé thẳng người ít nhất 20 phút sau bú, tránh đè ép bụng, tránh nhún nhảy hay chơi mạnh ngay sau bú.',
            'Bú bình: kiểm tra núm ti có chảy quá nhanh không, giữ bình gần nằm ngang để bé bú thong thả.',
            'Khi ngủ: luôn đặt bé nằm ngửa trên mặt phẳng, chắc. Không kê cao đầu nôi, không dùng gối chặn, gối chống trào ngược hay ghế nằm nghiêng để ngủ.',
            'Nấc cụt: đổi tư thế, vỗ ợ hơi, giúp bé thư giãn. Nếu nấc kéo dài 5–10 phút, cho bé bú thêm một chút thường sẽ hết. Không cần làm bé giật mình.',
          ),
          note(
            'Đừng tự dùng thuốc hay làm đặc sữa',
            'Không tự mua thuốc chống trào ngược, không tự cho bột vào sữa cho đặc, không đổi sữa liên tục. Bột làm đặc hoặc sữa chống trào ngược chỉ dùng khi bác sĩ chỉ định; bác sĩ cũng có thể xem bé có dị ứng đạm sữa bò hay không.',
          ),
          tip(
            'Nếu bé bị sặc sữa',
            'Bé ho sặc, tím tái sau khi trớ: làm theo hướng dẫn trong mục Sơ cứu trẻ em của Child Life (Sặc sữa) và gọi 115 nếu bé không thở lại bình thường.',
          ),
          h('Theo dõi'),
          ul(
            'Bé có vui vẻ, bú tốt, tăng cân đều theo các lần khám không.',
            'Kiểu trớ: trào nhẹ hay phun vọt mạnh; có lặp lại sau mỗi cữ không.',
            'Màu dịch trớ: sữa trắng hoặc sữa vón là thường gặp; màu xanh lá, vàng hoặc có máu là bất thường.',
            'Bé có quấy khóc, ưỡn người, từ chối bú khi bú không.',
            'Số tã ướt mỗi ngày, phân có máu không, bụng có chướng không.',
            'Tuổi: trớ mới bắt đầu sau 6 tháng, hoặc kéo dài quá 1 tuổi, cần cho bác sĩ xem.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            '“Bé hay trớ thì cho nằm gối cao hoặc nằm nghiêng khi ngủ” → Ông bà làm vậy vì sợ cháu sặc, nhưng kê cao đầu không làm giảm trào ngược, tư thế nửa nằm nửa ngồi còn có thể làm trào ngược nặng hơn, và nằm nghiêng, nằm sấp làm tăng nguy cơ đột tử. Bé khỏe nằm ngửa không dễ bị sặc hơn vì có phản xạ bảo vệ đường thở. → Luôn cho bé ngủ ngửa trên mặt phẳng.',
            '“Bé trớ nhiều là do sữa mẹ không hợp, phải chuyển sang sữa ngoài” → Trớ gặp ở cả bé bú mẹ lẫn bú bình, chủ yếu do cơ ở dạ dày chưa trưởng thành. → Tiếp tục cho bú mẹ; nếu lo, hỏi bác sĩ trước khi đổi sữa.',
            '“Bé nấc là do lạnh bụng, phải ủ thật ấm hoặc cho uống nước” → Nấc ở bé nhỏ thường liên quan đến lúc bú như bú no, nuốt hơi; bé dưới 6 tháng không cần uống nước. → Vỗ ợ hơi, cho bú thêm một chút, giữ bé thoải mái.',
          ),
          doctor(
            'Gọi 115 hoặc đến cấp cứu ngay khi',
            'Bé sặc, tím tái, khó thở hoặc có lúc ngừng thở; nôn ra dịch xanh lá hoặc có máu; bé li bì, khó đánh thức; bụng chướng căng, bé đau dữ dội; bé nôn liên tục không giữ được sữa và có dấu hiệu mất nước.',
          ),
          doctor(
            'Đưa bé đi khám sớm khi',
            'Bé khoảng 2–8 tuần tuổi nôn vọt mạnh sau các cữ bú rồi lại đòi bú ngay (cần khám trong ngày để loại trừ hẹp môn vị); bé từ chối bú, quấy khóc, ưỡn người mỗi lần bú; ít tã ướt; có máu trong phân; không tăng cân; bé dưới 3 tháng sốt từ 38 °C trở lên; trớ mới bắt đầu sau 6 tháng hoặc kéo dài quá 1 tuổi.',
          ),
        ],
        en: [
          note(
            'In short',
            'Spit-up (normal reflux) is very common. It usually starts in the first few weeks, peaks at around 4–5 months and fades by about 1 year. If your baby is happy, feeding well and gaining weight, no medicine is needed. Babies always sleep on their back on a flat surface, even if they spit up a lot.',
          ),
          h('Understanding spit-up and hiccups'),
          p(
            "In young babies the muscle where the food pipe meets the stomach isn't fully tight yet, and the stomach is small, so milk easily comes back up, especially when your baby is full, has swallowed air or is moved around straight after a feed. According to the AAP, reflux usually starts at 2–3 weeks, peaks at 4–5 months and goes away in most full-term babies by 9–12 months. The NHS also says it usually starts before 8 weeks and improves by about 1 year as the muscle gets stronger.",
          ),
          p(
            "Spit-up is usually gentle and small in amount (even if it looks a lot on clothes); your baby doesn't strain and isn't bothered, and many are “happy spitters”. Vomiting is different: milk is forced out, in larger amounts, your baby heaves, and it may happen after every feed. Some babies have reflux without bringing milk up, showing it by coughing or hiccupping during feeds, fussing and arching their back.",
          ),
          p(
            'Hiccups are also very common in young babies, often during or after feeds. They usually bother parents more than babies, and they stop on their own.',
          ),
          h('What you can do'),
          ul(
            "Feed with your baby's head higher than their tummy. Feed at early hunger cues, before loud crying, so they swallow less air.",
            'Burp during and at the end of feeds: after every 60–90 ml or so for bottle-fed babies, and when switching sides for breastfed babies.',
            "Offer smaller, more frequent feeds if your baby seems over-full; don't make them finish the bottle.",
            'Hold your baby upright for at least 20 minutes after a feed, with no pressure on the tummy and no bouncing or lively play straight after.',
            'Bottle feeding: check the teat is not flowing too fast and hold the bottle almost horizontal so your baby can feed at an easy pace.',
            'For sleep: always lay your baby on their back on a firm, flat surface. Do not raise the head of the crib, and do not use wedges, anti-reflux pillows or inclined seats for sleep.',
            "Hiccups: change position, burp and help your baby relax. If they last 5–10 minutes, a little more feed usually stops them. There's no need to startle your baby.",
          ),
          note(
            "Don't use medicines or thicken feeds yourself",
            "Don't buy anti-reflux medicine, add powder to thicken milk or keep switching formula on your own. Thickeners and anti-reflux formula are only for use when a doctor advises them; the doctor may also check for cow's milk protein allergy.",
          ),
          tip(
            'If your baby chokes on milk',
            "If your baby coughs, splutters or turns blue after spitting up: follow the Sơ cứu trẻ em (First aid) guide in Child Life (Milk choking) and call 115 (Vietnam emergency) if they don't start breathing normally again.",
          ),
          h('What to watch'),
          ul(
            'Whether your baby is happy, feeding well and gaining weight steadily at check-ups.',
            'How the milk comes up: gently or in a forceful spray; after every feed or not.',
            'Colour: white or curdled milk is common; green, yellow or bloody vomit is not.',
            'Whether your baby cries, arches their back or refuses during feeds.',
            'Wet diapers each day, any blood in the poo, and whether the tummy is swollen.',
            'Age: spit-up that starts after 6 months, or continues past 1 year, should be checked by a doctor.',
          ),
          h('Common myths'),
          ul(
            '“A baby who spits up should sleep on a raised pillow or on their side” → Grandparents fear choking, but raising the head does not reduce reflux, semi-upright positions may worsen it, and side or tummy sleeping raises the risk of sudden infant death. Healthy babies on their back are not more likely to choke: reflexes protect their airway. → Always lay your baby on their back on a flat surface.',
            "“Lots of spit-up means breast milk doesn't suit the baby, so switch to formula” → Spit-up happens in breastfed and bottle-fed babies alike, mainly because the stomach muscle is still immature. → Keep breastfeeding; if you are worried, talk to a doctor before changing milk.",
            "“Hiccups mean a cold tummy, so wrap the baby up or give water” → Hiccups in young babies are usually linked to feeding, such as being full or swallowing air; babies under 6 months don't need water. → Burp, offer a little more feed and keep your baby comfortable.",
          ),
          doctor(
            'Call 115 or go to the emergency department now if',
            "Your baby chokes, turns blue, has trouble breathing or pauses in breathing; vomits green fluid or blood; is very drowsy or hard to wake; has a tight, swollen tummy and seems in severe pain; or keeps vomiting, can't keep milk down and shows signs of dehydration.",
          ),
          doctor(
            'See a doctor soon if',
            'Your baby, aged about 2–8 weeks, vomits forcefully after feeds and then wants to feed again straight away (see a doctor the same day to rule out pyloric stenosis); refuses feeds, cries or arches at every feed; has fewer wet diapers; has blood in the poo; is not gaining weight; is under 3 months with a temperature of 38 °C or higher; or spit-up starts after 6 months or continues past 1 year.',
          ),
        ],
      },
      keywords: t(
        [
          'ọc sữa',
          'trớ sữa',
          'nấc cụt',
          'trào ngược',
          'ợ hơi',
          'nôn vọt',
          'hẹp môn vị',
          'ngủ ngửa',
          'gối chống trào ngược',
        ],
        [
          'spit-up',
          'posseting',
          'hiccups',
          'reflux',
          'burping',
          'projectile vomiting',
          'pyloric stenosis',
          'back to sleep',
          'reflux wedge',
        ],
      ),
      relatedArticleIds: [
        'art_formula_bottle',
        'art_breastfeeding_start',
        'art_safe_sleep',
        'art_crying_colic',
      ],
      milestoneIds: [],
      sources: [
        S.nhsReflux,
        S.hcRefluxGerd,
        S.hcWhyBabiesSpitUp,
        S.hcBurpingHiccups,
        S.hcRefluxSafeSleep,
        S.hcPyloricStenosis,
        S.nhsFormulaTypes,
      ],
    },
  },
  {
    id: 'art_vitamin_d_iron',
    reviewerLabel: NUTRITION,
    data: {
      library: 'care',
      topic: 'feeding',
      format: 'article',
      ageWeeks: { from: 0, to: 104 },
      readingMinutes: 6,
      cover: null,
      title: t(
        'Vitamin D và sắt cho bé: ai cần bổ sung, bổ sung thế nào',
        'Vitamin D and iron for babies: who needs a supplement and how',
      ),
      summary: t(
        'Bé bú mẹ cần vitamin D mỗi ngày từ những ngày đầu; kho sắt từ lúc sinh dùng dần trong vài tháng đầu. Khi nào cần bổ sung, nguồn thực phẩm giàu sắt, và những điều không nên tự làm.',
        'Breastfed babies need daily vitamin D from the first days; iron stores from birth are used up over the first months. When to supplement, iron-rich foods and what not to do on your own.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Sữa mẹ là thức ăn tốt nhất nhưng ít vitamin D, nên bé bú mẹ (hoàn toàn hoặc một phần) cần bổ sung vitamin D mỗi ngày từ những ngày đầu; AAP khuyên 400 IU/ngày. Kho sắt có sẵn từ lúc sinh dùng dần trong mấy tháng đầu; sau đó bé cần sắt từ thức ăn dặm, và bé bú mẹ hoàn toàn có thể cần thêm sắt theo chỉ định bác sĩ.',
          ),
          h('Hiểu đúng về vitamin D'),
          p(
            'Vitamin D giúp cơ thể hấp thu canxi để xương chắc khỏe; thiếu kéo dài có thể gây còi xương. Sữa mẹ chứa ít vitamin D, còn sữa công thức đã được bổ sung sẵn.',
          ),
          p(
            'AAP khuyên bé bú mẹ hoàn toàn hoặc một phần uống 400 IU (10 microgam) vitamin D mỗi ngày, bắt đầu từ những ngày đầu sau sinh. NHS khuyên 8,5–10 microgam mỗi ngày cho bé bú mẹ, từ lúc sinh đến 1 tuổi. Với bé bú sữa công thức, các tổ chức dùng mốc khác nhau: NHS cho rằng không cần bổ sung nếu bé uống trên 500 ml sữa công thức mỗi ngày, còn AAP dùng mốc cao hơn: dưới khoảng 1 lít (32 oz) sữa công thức mỗi ngày thì cần bổ sung. Vì vậy bé bú kết hợp nên hỏi bác sĩ để quyết định.',
          ),
          p(
            'Ánh nắng giúp da tạo vitamin D, nhưng không phải nguồn đáng tin và an toàn cho bé nhỏ: AAP khuyên giữ bé dưới 6 tháng tránh nắng trực tiếp, và NHS lưu ý trẻ nhỏ vẫn cần uống vitamin D dù có thời gian ở ngoài trời.',
          ),
          h('Hiểu đúng về sắt'),
          p(
            'Sắt cần để tạo hồng cầu mang oxy đi khắp cơ thể và cho não bé phát triển. Bé đủ tháng sinh ra có sẵn kho sắt, đủ dùng trong khoảng 4 tháng đầu; đến khoảng 6 tháng kho sắt giảm dần, trong khi sữa mẹ ít sắt, nên bé cần thức ăn dặm giàu sắt.',
          ),
          p(
            'Thiếu sắt khá thường gặp ở trẻ nhỏ, nhất là tuổi tập đi. Bé thiếu sắt có thể xanh xao, mệt, ít chơi, hay quấy, ăn kém, hoặc thích nhai những thứ không phải đồ ăn. Bé sinh non, nhẹ cân có kho sắt ít hơn nên thường cần bổ sung sớm theo chỉ định của bác sĩ.',
          ),
          h('Ba mẹ có thể làm gì'),
          h('Vitamin D'),
          ul(
            'Bé bú mẹ hoàn toàn hoặc một phần: hỏi bác sĩ ngay trong lần khám đầu về giọt vitamin D 400 IU mỗi ngày, và cho uống đều đến khi bác sĩ bảo dừng.',
            'Đọc kỹ nhãn để biết bao nhiêu giọt hoặc ml là 400 IU, vì mỗi sản phẩm có nồng độ khác nhau. Dùng đúng dụng cụ đong đi kèm.',
            'Không cho bé dùng hai sản phẩm có vitamin D cùng lúc, ví dụ dầu gan cá cùng với vitamin tổng hợp, để tránh thừa.',
            'Sau 1 tuổi: hỏi bác sĩ có cần tiếp tục không; NHS khuyên trẻ 1–4 tuổi bổ sung 10 microgam mỗi ngày.',
          ),
          h('Sắt'),
          ul(
            'Bé đủ tháng bú mẹ hoàn toàn: các hướng dẫn khác nhau. AAP (báo cáo năm 2026) khuyên bổ sung sắt từ khoảng 4 tháng, hoặc chậm nhất khi bắt đầu ăn dặm giàu sắt quanh 6 tháng; NHS (Anh) không khuyên bổ sung thường quy cho bé đủ tháng khoẻ mạnh mà chú trọng món giàu sắt khi ăn dặm. Liều tính theo cân nặng, vì vậy hỏi bác sĩ, không tự mua.',
            'Bé sinh non, nhẹ cân: thường cần bổ sung sắt từ vài tuần tuổi; làm đúng theo chỉ định của bác sĩ.',
            'Từ khoảng 6 tháng: mỗi ngày có món giàu sắt trong bữa ăn dặm như thịt bò, thịt gà phần đùi, cá, lòng đỏ trứng, đậu lăng, đậu phụ, bột ngũ cốc ăn dặm có bổ sung sắt.',
            'Sắt từ thịt, cá được hấp thu tốt hơn sắt từ rau, đậu. Ăn kèm rau quả giàu vitamin C như cam, ổi, cà chua, súp lơ xanh giúp hấp thu sắt từ thực vật tốt hơn.',
            'Gan giàu sắt nhưng cũng rất nhiều vitamin A, chỉ nên cho ăn khoảng một lần mỗi tuần.',
            'Không dùng sữa bò, sữa tươi làm đồ uống chính trước 12 tháng. Sau 1 tuổi, giữ tổng lượng sữa dưới khoảng 700 ml mỗi ngày (AAP: dưới 24 oz) để bé còn ăn được bữa chính giàu sắt.',
            'Cất mọi loại thuốc sắt, vitamin có sắt trên cao, đóng nắp kỹ, ngoài tầm với của trẻ.',
          ),
          tip(
            'Nếu ba mẹ đang chờ bé tiếp theo',
            'Kẹp dây rốn muộn hơn khoảng 30–60 giây giúp bé nhận thêm máu giàu sắt từ nhau thai. Ba mẹ có thể trao đổi trước với bác sĩ sản khoa.',
          ),
          h('Theo dõi'),
          ul(
            'Ghi lại mỗi ngày bé đã uống vitamin D chưa để không quên hoặc cho trùng liều.',
            'Lượng sữa công thức bé uống mỗi ngày, để bác sĩ biết bé có cần thêm vitamin D không.',
            'Bé xanh xao, mệt, ít chơi, hay quấy, ăn kém, hoặc thích nhai đất, giấy, đá lạnh.',
            'Bé 9–12 tháng chủ yếu bú mẹ: hỏi bác sĩ về xét nghiệm kiểm tra thiếu sắt, vì AAP khuyên tầm soát ở độ tuổi này.',
            'Bé trên 1 tuổi uống rất nhiều sữa nhưng ăn ít bữa chính.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            '“Tắm nắng buổi sáng là đủ vitamin D, khỏi uống” → Ông bà quen cho cháu tắm nắng vì thương, nhưng lượng vitamin D da tạo ra phụ thuộc thời tiết, giờ trong ngày, màu da, quần áo, và AAP khuyên bé dưới 6 tháng tránh nắng trực tiếp. → Vẫn cho bé uống vitamin D theo hướng dẫn; khi ra ngoài, cho bé ở chỗ râm, mặc đồ dài tay, đội mũ.',
            '“Vitamin, siro bổ, thuốc sắt càng uống nhiều càng tốt” → Thừa vitamin D có hại, và sắt liều cao có thể gây ngộ độc nặng, thậm chí tử vong ở trẻ nhỏ. → Chỉ dùng khi bác sĩ khuyên, đúng liều, không dùng nhiều sản phẩm cùng lúc.',
            '“Cho bé uống sữa tươi, sữa bò thay sữa mẹ cho chắc xương” → Trước 12 tháng, sữa bò có thể gây mất máu ẩn qua phân và làm giảm hấp thu sắt. → Dưới 1 tuổi chỉ dùng sữa mẹ hoặc sữa công thức; sau 1 tuổi sữa bò là đồ uống, không thay bữa ăn.',
            '“Ăn nhiều rau dền, rau ngót là đủ sắt bổ máu” → Sắt từ rau được hấp thu kém hơn sắt từ thịt, cá. → Kết hợp thịt, cá, trứng với rau và trái cây giàu vitamin C.',
          ),
          doctor(
            'Gọi 115 hoặc đến cấp cứu ngay khi',
            'Bé nuốt nhầm thuốc sắt, vitamin hoặc thuốc của người lớn, kể cả khi bé chưa có biểu hiện gì: mang theo vỏ hộp và xem hướng dẫn trong mục Sơ cứu trẻ em của Child Life. Gọi ngay nếu bé nôn nhiều, nôn ra máu, li bì hoặc khó thở.',
          ),
          doctor(
            'Khi nào nên hỏi bác sĩ',
            'Trước khi bắt đầu, đổi hoặc ngừng vitamin D hay sắt; bé sinh non hoặc nhẹ cân; bé xanh xao, mệt, ăn kém, hay quấy; bé trên 1 tuổi uống rất nhiều sữa và ăn ít; bé bú kết hợp và ba mẹ không chắc bé có cần thêm vitamin D không.',
          ),
        ],
        en: [
          note(
            'In short',
            'Breast milk is the best food but is low in vitamin D, so breastfed babies (fully or partly) need a vitamin D supplement every day from the first days; the AAP recommends 400 IU a day. The iron stores your baby is born with are used up over the first months; after that your baby needs iron from solid foods, and exclusively breastfed babies may need extra iron as advised by a doctor.',
          ),
          h('Understanding vitamin D'),
          p(
            'Vitamin D helps the body absorb calcium for strong bones; a long-term shortage can cause rickets. Breast milk contains little vitamin D, while infant formula already has it added.',
          ),
          p(
            'The AAP recommends 400 IU (10 micrograms) of vitamin D a day for fully or partly breastfed babies, starting in the first few days after birth. The NHS recommends 8.5–10 micrograms a day for breastfed babies from birth to 1 year. For formula-fed babies, guidelines use different thresholds: the NHS says no supplement is needed if your baby drinks more than 500 ml of formula a day, while the AAP uses a higher threshold: supplement if your baby drinks less than about 1 litre (32 oz) of formula a day. So if your baby is combination-fed, ask your doctor.',
          ),
          p(
            'Sunlight helps skin make vitamin D, but it is not a reliable or safe source for young babies: the AAP advises keeping babies under 6 months out of direct sunlight, and the NHS notes that young children still need vitamin drops even if they spend time outdoors.',
          ),
          h('Understanding iron'),
          p(
            "Iron is needed to make red blood cells that carry oxygen around the body, and for your baby's brain development. Full-term babies are born with iron stores that last about the first 4 months; by about 6 months these stores run down and breast milk is low in iron, so your baby needs iron-rich solid foods.",
          ),
          p(
            'Iron deficiency is fairly common in young children, especially toddlers. A baby short of iron may look pale, be tired, play less, be fussy, eat poorly or want to chew things that are not food. Babies born early or small have smaller iron stores and often need supplements early, as advised by their doctor.',
          ),
          h('What you can do'),
          h('Vitamin D'),
          ul(
            'Fully or partly breastfed babies: ask your doctor at the first check-up about vitamin D drops of 400 IU a day, and give them every day until your doctor says to stop.',
            'Read the label to see how many drops or ml make 400 IU, as strengths differ between products. Use the measuring device that comes with it.',
            "Don't give two products containing vitamin D at the same time, such as cod liver oil plus a multivitamin, to avoid too much.",
            'After age 1: ask your doctor whether to continue; the NHS recommends 10 micrograms a day for children aged 1–4.',
          ),
          h('Iron'),
          ul(
            'Exclusively breastfed full-term babies: guidance differs. The AAP (2026 report) recommends iron from about 4 months, or at the latest when iron-rich solids start around 6 months; the NHS (UK) does not routinely supplement healthy term babies and focuses on iron-rich solids. The dose depends on weight, so ask your doctor rather than buying one yourself.',
            "Babies born early or small: often need iron from a few weeks of age; follow your doctor's advice exactly.",
            'From about 6 months: include an iron-rich food in solids every day, such as beef, dark chicken meat, fish, egg yolk, lentils, tofu or iron-fortified baby cereal.',
            'Iron from meat and fish is absorbed better than iron from vegetables and beans. Serving fruit and vegetables rich in vitamin C, such as orange, guava, tomato or broccoli, helps the body absorb iron from plants.',
            'Liver is rich in iron but also very high in vitamin A, so offer it only about once a week.',
            "Don't give cow's milk as a main drink before 12 months. After age 1, keep total milk under about 700 ml a day (AAP: under 24 oz) so your child still has room for iron-rich meals.",
            'Keep all iron medicines and vitamins containing iron up high, tightly closed and out of reach of children.',
          ),
          tip(
            'If you are expecting another baby',
            'Waiting an extra 30–60 seconds before clamping the umbilical cord lets more iron-rich blood pass from the placenta to the baby. You can discuss this with your obstetrician in advance.',
          ),
          h('What to watch'),
          ul(
            "Note each day whether your baby has had their vitamin D so you don't forget or double up.",
            'How much formula your baby drinks a day, so your doctor can tell whether extra vitamin D is needed.',
            'Paleness, tiredness, less play, fussiness, poor eating, or wanting to chew soil, paper or ice.',
            'Babies of 9–12 months who are mainly breastfed: ask your doctor about a blood test for iron deficiency, as the AAP recommends screening at this age.',
            'A child over 1 who drinks a lot of milk but eats little at meals.',
          ),
          h('Common myths'),
          ul(
            '“Morning sunbathing gives enough vitamin D, so no drops are needed” → Grandparents sun their grandchildren out of love, but how much vitamin D the skin makes depends on the weather, time of day, skin colour and clothing, and the AAP advises keeping babies under 6 months out of direct sun. → Keep giving vitamin D as advised; outdoors, keep your baby in the shade with long sleeves and a hat.',
            '“The more vitamins, tonics and iron, the better” → Too much vitamin D is harmful, and high doses of iron can cause serious poisoning and even death in young children. → Use them only when a doctor advises, at the right dose, and never several products at once.',
            "“Give fresh cow's milk instead of breast milk for strong bones” → Before 12 months, cow's milk can cause hidden blood loss in the stool and reduce iron absorption. → Under 1, use only breast milk or formula; after 1, cow's milk is a drink, not a replacement for meals.",
            '“Plenty of amaranth or sweet leaf greens gives enough iron for the blood” → Iron from vegetables is absorbed less well than iron from meat and fish. → Combine meat, fish and eggs with vegetables and fruit rich in vitamin C.',
          ),
          doctor(
            'Call 115 or go to the emergency department now if',
            "Your child swallows iron tablets, vitamins or an adult's medicine by accident, even if they seem fine: take the packaging with you and see the Sơ cứu trẻ em (First aid) guide in Child Life. Call 115 (Vietnam emergency) straight away if your child vomits a lot, vomits blood, is very drowsy or has trouble breathing.",
          ),
          doctor(
            'When to ask a doctor',
            'Before starting, changing or stopping vitamin D or iron; if your baby was born early or small; if your child is pale, tired, eating poorly or very fussy; if a child over 1 drinks a lot of milk and eats little; or if your baby is combination-fed and you are unsure whether they need extra vitamin D.',
          ),
        ],
      },
      keywords: t(
        [
          'vitamin D',
          'sắt',
          'thiếu máu thiếu sắt',
          'còi xương',
          'tắm nắng',
          'bổ sung vitamin',
          'thực phẩm giàu sắt',
          'sữa bò',
          'bé sinh non',
          'ngộ độc sắt',
        ],
        [
          'vitamin D',
          'iron',
          'iron deficiency anaemia',
          'rickets',
          'sunbathing',
          'vitamin supplements',
          'iron-rich foods',
          "cow's milk",
          'premature baby',
          'iron poisoning',
        ],
      ),
      relatedArticleIds: [
        'art_breastfeeding_start',
        'art_formula_bottle',
        'art_solids_readiness',
        'art_solids_textures_by_month',
      ],
      milestoneIds: [],
      sources: [
        S.hcVitaminD,
        S.nhsVitaminsChildren,
        S.hcSunSafety,
        S.hcVitaminIronSupplements,
        S.hcIronGuidance2026,
        S.hcAnemia,
        S.nhsIron,
        S.ruhIronChildrensDiets,
      ],
    },
  },

  // ----- Ăn dặm (solids library) -----
  {
    id: 'art_solids_readiness',
    reviewerLabel: NUTRITION,
    data: {
      library: 'solids',
      topic: 'feeding',
      format: 'article',
      ageWeeks: { from: 17, to: 39 },
      readingMinutes: 6,
      cover: null,
      title: t(
        'Bắt đầu ăn dặm: dấu hiệu bé sẵn sàng và vì sao nên chờ khoảng 6 tháng',
        'Starting solids: signs your baby is ready and why to wait until around 6 months',
      ),
      summary: t(
        'Khoảng 6 tháng là thời điểm phù hợp để bắt đầu ăn dặm. Ba dấu hiệu bé đã sẵn sàng, cách chọn những món đầu tiên giàu sắt và các thói quen nên tránh.',
        'Around 6 months is the right time to start solids. The three signs your baby is ready, how to choose iron-rich first foods, and habits to avoid.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'WHO, Viện Hàn lâm Nhi khoa Hoa Kỳ (AAP) và NHS (Anh) đều khuyên bắt đầu ăn dặm khi bé khoảng 6 tháng và vẫn tiếp tục cho bú. Hãy nhìn vào ba dấu hiệu: bé ngồi giữ vững đầu, tự đưa thức ăn vào miệng, và nuốt được chứ không đẩy ra. Ngay từ những bữa đầu, ưu tiên món giàu sắt và không nêm muối, đường.',
          ),
          h('Hiểu đúng về thời điểm ăn dặm'),
          p(
            'Trong khoảng 6 tháng đầu, sữa mẹ hoặc sữa công thức cung cấp đủ năng lượng và dưỡng chất cho bé. Từ khoảng 6 tháng, nhu cầu của bé tăng lên mà sữa không còn đáp ứng đủ, đặc biệt là sắt, nên bé cần thêm thức ăn. WHO khuyên bắt đầu ăn bổ sung lúc 6 tháng và tiếp tục cho bú đến 2 tuổi hoặc lâu hơn; cho ăn quá sớm hay quá muộn đều có thể khiến bé chậm lớn.',
          ),
          p(
            'Chờ đến khoảng 6 tháng cũng giúp bé có thời gian phát triển: ngồi vững hơn, biết đảo thức ăn trong miệng, nhai và nuốt. Nhờ vậy nhiều bé chuyển sang thức ăn nghiền, lợn cợn và thức ăn cầm tay nhanh hơn. Ăn dặm không chỉ là “cho ăn thêm” mà là bé học một kỹ năng mới. Mỗi bé một nhịp, có bé sẵn sàng sớm hoặc muộn hơn vài tuần.',
          ),
          p(
            'Nếu bé sinh non, hãy hỏi bác sĩ thời điểm bắt đầu phù hợp. Các hội dị ứng Anh (BSACI) và Úc (ASCIA) nhấn mạnh không cho bé ăn dặm trước 4 tháng tuổi.',
          ),
          h('Ba dấu hiệu bé đã sẵn sàng'),
          ul(
            'Bé ngồi được và giữ vững đầu cổ.',
            'Bé phối hợp mắt, tay và miệng: nhìn thức ăn, cầm lấy và tự đưa vào miệng.',
            'Bé nuốt được thức ăn thay vì dùng lưỡi đẩy hết ra ngoài.',
          ),
          p(
            'Theo NHS, ba dấu hiệu này thường xuất hiện cùng lúc vào khoảng 6 tháng. Bé cũng có thể há miệng khi thìa đến gần và tỏ ra thích thú khi nhìn người lớn ăn.',
          ),
          tip(
            'Những điều chưa phải dấu hiệu sẵn sàng',
            'Gặm tay, thức dậy ban đêm nhiều hơn hay đòi bú thêm là hành vi bình thường ở tuổi này, chưa chắc bé đói hay cần ăn dặm. Ăn dặm cũng không giúp bé ngủ xuyên đêm. Trong lúc chờ, cho bé bú thêm một chút thường là đủ.',
          ),
          h('Ba mẹ có thể làm gì'),
          ul(
            'Chọn lúc bé tỉnh táo, không quá đói hay quá mệt và ba mẹ không vội. Bé vẫn bú như thường; sữa vẫn là nguồn dinh dưỡng chính trong năm đầu.',
            'Cho bé ngồi thẳng trên ghế ăn có đai, ba mẹ ngồi đối diện và ở cạnh bé suốt bữa ăn.',
            'Bắt đầu với vài thìa nhỏ hoặc vài miếng; UNICEF gợi ý 2–3 thìa, ngày 2 lần, rồi tăng dần theo sức ăn của bé. Đừng lo bé ăn được bao nhiêu, quan trọng là làm quen.',
            'Ưu tiên món giàu sắt ngay từ đầu: thịt, cá, trứng nấu chín kỹ, đậu phụ, các loại đậu, ngũ cốc tăng cường sắt. Xen với rau củ, kể cả loại hơi đắng như bông cải xanh, rau cải, và trái cây như chuối, bơ, đu đủ.',
            'Cháo hoặc bột nấu đặc đến mức không chảy khỏi thìa, rau củ hấp mềm nghiền, hoặc miếng mềm dài cỡ ngón tay để bé tự cầm.',
            'Đút thìa, cho bé tự ăn (BLW) hay kết hợp đều được; điều quan trọng là thức ăn mềm, an toàn và bé được ăn đa dạng.',
            'Không nêm muối, nước mắm, hạt nêm hay đường vào đồ ăn của bé. Không cho mật ong trước 12 tháng tuổi vì nguy cơ ngộ độc botulinum.',
            'Sữa bò tươi có thể dùng để nấu cùng thức ăn từ khoảng 6 tháng, nhưng chưa dùng làm đồ uống chính trước 1 tuổi.',
            'Cho ăn theo tín hiệu của bé: đợi bé há miệng rồi mới đưa thìa; bé ngậm chặt miệng hoặc quay đầu đi là đã đủ. Không ép, không dỗ ăn bằng tivi hay điện thoại.',
            'Trứng, đậu phộng, cá, tôm cua, lúa mì có thể cho từ khoảng 6 tháng, mỗi lần một món mới với lượng nhỏ.',
            'Cho bé tập nhấp vài ngụm nước đun sôi để nguội bằng cốc trong bữa ăn.',
          ),
          h('Theo dõi'),
          ul(
            'Bé hứng thú hay quay đi, ăn được khoảng bao nhiêu thìa hoặc miếng mỗi bữa.',
            'Món mới đã thử và phản ứng sau ăn: nổi mẩn, sưng môi mặt, nôn, tiêu chảy.',
            'Phân thường đổi màu và đặc hơn khi bé ăn dặm; để ý nếu bé đi ngoài khó, phân cứng.',
            'Cân nặng, chiều dài ở các lần khám định kỳ. Có thể ghi lại món ăn và phản ứng của bé trong Child Life để đưa bác sĩ xem.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            'Cho ăn dặm từ 3–4 tháng để bé “cứng cáp”, ngủ ngon → Ông bà thường làm vậy vì sợ cháu đói, nhưng trước khoảng 6 tháng bé chưa sẵn sàng về kỹ năng ăn, và ăn dặm sớm không giúp bé ngủ xuyên đêm → Chờ đến khoảng 6 tháng và đủ ba dấu hiệu; nếu bé có vẻ đói nhiều, cho bú thêm và hỏi bác sĩ.',
            'Pha bột vào bình sữa cho bé no lâu → Bé dễ sặc, khó tự điều chỉnh lượng ăn và không học được cách ăn bằng thìa → Bình sữa chỉ dùng cho sữa; bột, cháo cho ăn bằng thìa khi bé đã sẵn sàng.',
            'Bắt đầu bằng nước cháo loãng, nước rau hay nước hầm xương cho “dễ tiêu” → Nước loãng chủ yếu là nước, ít năng lượng, còn đạm và sắt phần lớn nằm trong miếng thịt, cá → Cho bé ăn cả cái: cháo đặc vừa phải, thịt cá nghiền hoặc băm nhuyễn.',
            'Phải theo đúng một trường phái: truyền thống, kiểu Nhật hay BLW → Theo NHS, không có cách đúng hay sai, và bé tự ăn không làm tăng nguy cơ hóc so với đút thìa nếu thức ăn mềm và có người lớn ngồi cạnh → Chọn cách hợp với gia đình, có thể kết hợp, và tăng dần độ thô theo khả năng của bé.',
          ),
          doctor(
            'Khi nào nên hỏi bác sĩ',
            'Bé sinh non, nhẹ cân hoặc có bệnh cần chế độ ăn riêng; bé đã quá 6 tháng một thời gian mà vẫn chưa có các dấu hiệu sẵn sàng hoặc luôn từ chối thức ăn; bé hay ho sặc, nôn, khó nuốt khi ăn; bé chậm tăng cân; bé bị chàm nặng hoặc đã từng dị ứng thức ăn. Gọi 115 nếu bé khó thở, tím tái, lả đi khi hoặc sau khi ăn, và xem mục Sơ cứu trẻ em › Hóc dị vật hoặc Sốc phản vệ trong Child Life.',
          ),
        ],
        en: [
          note(
            'In short',
            'WHO, the American Academy of Pediatrics (AAP) and the NHS (UK) all advise starting solids at around 6 months while continuing milk feeds. Look for three signs: your baby sits with a steady head, puts food in their mouth by themselves, and swallows it rather than pushing it out. From the first meals, favor iron-rich foods and add no salt or sugar.',
          ),
          h('Understanding the timing'),
          p(
            'For about the first 6 months, breast milk or formula gives your baby all the energy and nutrients they need. From around 6 months, their needs grow beyond what milk alone can provide, especially for iron, so they need food as well. WHO advises starting complementary foods at 6 months and continuing breastfeeding to 2 years or beyond; starting too early or too late can both slow growth.',
          ),
          p(
            'Waiting until around 6 months also gives your baby time to develop: to sit more steadily and to move food around the mouth, chew and swallow. Many babies then move on to mashed, lumpy and finger foods more quickly. Starting solids is not just "extra food" but a new skill to learn. Every baby has their own pace; some are ready a few weeks earlier or later.',
          ),
          p(
            'If your baby was born preterm, ask the doctor when to start. The British (BSACI) and Australian (ASCIA) allergy societies stress not starting solids before 4 months of age.',
          ),
          h('Three signs your baby is ready'),
          ul(
            'Your baby can sit and hold their head steady.',
            'Your baby coordinates eyes, hands and mouth: looks at food, picks it up and puts it in their mouth by themselves.',
            'Your baby swallows food instead of pushing it all back out with the tongue.',
          ),
          p(
            'According to the NHS, these three signs usually appear together at around 6 months. Your baby may also open their mouth as the spoon comes near and seem interested when watching adults eat.',
          ),
          tip(
            'Things that are not signs of readiness',
            'Chewing fists, waking more at night or wanting extra milk feeds are normal at this age and do not necessarily mean your baby is hungry or needs solids. Starting solids will not make your baby sleep through the night. Until they are ready, a little extra milk is usually enough.',
          ),
          h('What you can do'),
          ul(
            'Pick a time when your baby is alert, not too hungry or tired, and you are not rushed. Keep milk feeds as usual; milk is still the main source of nutrition in the first year.',
            'Sit your baby upright in a high chair with a harness, sit facing them and stay with them for the whole meal.',
            "Start with a few small spoonfuls or a few pieces; UNICEF suggests 2–3 spoonfuls twice a day, then increase with your baby's appetite. Don't worry about how much they eat; getting used to food is what matters.",
            'Favor iron-rich foods from the start: well-cooked meat, fish and egg, tofu, beans and lentils, iron-fortified cereals. Mix in vegetables, including slightly bitter ones such as broccoli and leafy greens, and fruit such as banana, avocado and papaya.',
            'Make rice porridge or cereal thick enough not to run off the spoon, steam and mash vegetables, or offer soft finger-length pieces for your baby to hold.',
            'Spoon-feeding, baby-led weaning (BLW) or a mix all work; what matters is that food is soft, safe and varied.',
            "Don't add salt, fish sauce, stock powder or sugar to your baby's food. No honey before 12 months because of the risk of infant botulism.",
            "Cow's milk can be used in cooking from around 6 months, but not as a main drink before 1 year.",
            "Follow your baby's cues: wait for them to open their mouth before offering the spoon; a firmly closed mouth or turned head means they have had enough. Never force, and don't use TV or phones to coax them to eat.",
            'Egg, peanut, fish, shellfish and wheat can be offered from around 6 months, one new food at a time in small amounts.',
            'Let your baby practice taking a few sips of boiled and cooled water from a cup with meals.',
          ),
          h('What to watch'),
          ul(
            'Whether your baby is interested or turns away, and roughly how many spoonfuls or pieces they eat at each meal.',
            'New foods tried and any reaction afterward: rash, swollen lips or face, vomiting, diarrhea.',
            'Stools often change color and get firmer with solids; watch for hard stools or straining.',
            'Weight and length at routine checkups. You can log foods and reactions in Child Life to show the doctor.',
          ),
          h('Common myths'),
          ul(
            'Starting solids at 3–4 months makes babies "sturdier" and sleep better → Grandparents often do this because they worry the baby is hungry, but before around 6 months babies are not developmentally ready to eat, and early solids do not help them sleep through → Wait until around 6 months and all three signs; if your baby seems very hungry, offer extra milk and ask the doctor.',
            'Adding cereal to the bottle keeps babies full longer → Babies can choke more easily, cannot regulate how much they take and do not learn to eat from a spoon → Use the bottle only for milk; give cereal and porridge from a spoon once your baby is ready.',
            'Starting with thin rice water, vegetable water or bone broth because it is "easier to digest" → Thin liquids are mostly water with little energy, while most of the protein and iron stay in the meat and fish → Give your baby the solids: reasonably thick porridge, with meat or fish mashed or finely minced.',
            'You must stick to one method: traditional, Japanese-style or BLW → According to the NHS there is no right or wrong way, and self-feeding does not raise the risk of choking compared with spoon-feeding when food is soft and an adult sits alongside → Choose what suits your family, combine methods if you like, and increase texture as your baby can manage.',
          ),
          doctor(
            'When to ask a doctor',
            'Your baby was born preterm, has low weight or a condition that needs a special diet; your baby is well past 6 months and still shows no signs of readiness or always refuses food; your baby often coughs, chokes, vomits or struggles to swallow when eating; poor weight gain; severe eczema or a previous food allergy. Call 115 (Vietnam emergency) if your baby has trouble breathing, turns blue or goes limp during or after eating, and see the Sơ cứu trẻ em (First aid) guide in Child Life for Choking or Anaphylaxis.',
          ),
        ],
      },
      keywords: t(
        [
          'ăn dặm',
          'ăn bổ sung',
          '6 tháng',
          'dấu hiệu sẵn sàng',
          'BLW',
          'ăn dặm kiểu Nhật',
          'món đầu tiên',
          'thức ăn giàu sắt',
          'cháo',
          'bột ăn dặm',
        ],
        [
          'starting solids',
          'complementary feeding',
          '6 months',
          'signs of readiness',
          'baby-led weaning',
          'Japanese-style weaning',
          'first foods',
          'iron-rich foods',
          'rice porridge',
          'baby cereal',
        ],
      ),
      relatedArticleIds: [
        'art_solids_textures_by_month',
        'art_solids_choking_safety',
        'art_allergen_intro',
        'art_vitamin_d_iron',
      ],
      milestoneIds: ['sits_up', 'mouths_objects', 'reaches_for_toy'],
      sources: [
        S.cWhoIycfFactSheet,
        S.cWhoCfGuideline2023,
        S.cNhsFirstSolids,
        S.cNhsFoodsToAvoid,
        S.cHcStartingSolids,
        S.cUnicefFeeding6to12,
        S.cBsaciParentSummary,
      ],
    },
  },
  {
    id: 'art_solids_choking_safety',
    reviewerLabel: PAEDS,
    data: {
      library: 'solids',
      topic: 'feeding',
      format: 'article',
      ageWeeks: { from: 22, to: 104 },
      readingMinutes: 6,
      cover: null,
      title: t(
        'Ăn dặm an toàn: phân biệt oẹ với hóc và cách phòng hóc nghẹn',
        'Safe solids: telling gagging from choking, and preventing choking',
      ),
      summary: t(
        'Oẹ là phản xạ bình thường khi bé tập ăn, còn hóc là cấp cứu. Tư thế ăn an toàn, những món dễ gây hóc và cách sơ chế cho trẻ nhỏ.',
        'Gagging is a normal reflex while babies learn to eat; choking is an emergency. Safe eating positions, high-risk foods and how to prepare them for young children.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Oẹ khi tập ăn là bình thường: bé ồn ào, ho, đẩy thức ăn ra. Hóc thường im lặng: bé không ho ra tiếng, không khóc, không thở được và cần sơ cứu ngay. Phòng hóc bằng ba việc: bé ngồi thẳng và có người lớn ngồi cùng, thức ăn mềm và cắt đúng cỡ, không ăn khi đang chạy chơi hay trên xe.',
          ),
          h('Hiểu đúng: oẹ khác hóc'),
          p(
            'Khi mới tập ăn, phản xạ oẹ giúp bé đẩy miếng thức ăn quá to ra phía trước miệng. Theo NHS, lúc oẹ bé có thể chảy nước mắt, thè lưỡi, nôn khan hoặc nôn ra một ít. Trông có vẻ đáng sợ, nhưng đó là cách bé học điều chỉnh lượng thức ăn có thể nhai và nuốt. Ba mẹ hãy bình tĩnh, ngồi cạnh, không thò tay vào miệng bé và để bé tự xử lý.',
          ),
          p(
            'Hóc xảy ra khi thức ăn hoặc dị vật chặn đường thở. Nếu bé còn ho to, khóc được thì hãy để bé tự ho và theo dõi sát. Nếu bé ho không ra tiếng, im lặng, không khóc được, không hít vào được hoặc môi tím tái, đó là cấp cứu: gọi 115 và làm ngay theo hướng dẫn trong mục Sơ cứu trẻ em › Hóc dị vật của Child Life.',
          ),
          p(
            'Trẻ nhỏ dễ hóc vì kỹ năng nhai nghiền chưa hoàn thiện và hay cho mọi thứ vào miệng. AAP khuyên tránh các thức ăn nguy cơ cao cho đến ít nhất 4 tuổi, còn NHS khuyên không cho các loại hạt nguyên hạt trước 5 tuổi; nên theo mốc 5 tuổi, an toàn hơn.',
          ),
          h('Ba mẹ có thể làm gì'),
          h('Tư thế và thói quen khi ăn'),
          ul(
            'Bé luôn ngồi thẳng khi ăn, tốt nhất trên ghế ăn có đai; không cho ăn khi bé nằm, ngả lưng hay đang bò.',
            'Người lớn ngồi cùng và nhìn bé suốt bữa. Để ý anh chị nhỏ, vì các bé hay đút đồ ăn hoặc đồ chơi nhỏ cho em.',
            'Không cho bé ăn khi đang chạy, đi lại, chơi đùa, ngồi ô tô hay trên xe máy đang chạy.',
            'Bữa ăn bình tĩnh, không vội; tắt tivi, cất điện thoại để bé tập trung nhai nuốt.',
            'Mỗi lần đưa một lượng nhỏ, chờ bé nuốt hết rồi mới đưa tiếp. Không đút khi bé đang khóc, ngậm miệng hoặc quay đi.',
          ),
          h('Sơ chế những món dễ hóc'),
          ul(
            'Nho, cà chua bi: cắt làm tư (NHS). Nhãn, vải, chôm chôm cũng tròn và trơn: bỏ hạt, cắt thật nhỏ.',
            'Lạc (đậu phộng), hạt điều, hạnh nhân: không cho nguyên hạt hoặc giã thô trước 5 tuổi. Dùng bột hạt xay mịn hoặc bơ hạt mịn trộn vào cháo, phết mỏng lên bánh, không đút cả thìa bơ hạt đặc.',
            'Xúc xích, lạp xưởng: hạn chế vì nhiều muối; nếu cho thì cắt dọc rồi thái thật nhỏ, không cắt khoanh tròn.',
            'Rau củ sống cứng, táo: hấp hoặc luộc mềm, hoặc nạo nhỏ.',
            'Thịt nấu mềm, băm hoặc xé nhỏ, tránh miếng to và dai. Cá gỡ thật kỹ xương, kể cả xương dăm.',
            'Xôi, bánh dày, bánh trôi, bánh nếp dẻo dính dễ mắc họng: tốt nhất chưa cho bé nhỏ; khi bé lớn và nhai tốt, chỉ cho miếng rất nhỏ và ngồi cạnh.',
            'Thạch rau câu, thạch trái cây dạng cốc nhỏ để hút, nhất là loại có bột konjac: không cho trẻ nhỏ. FDA (Mỹ) ghi nhận loại thạch cốc nhỏ có konjac đã gây tử vong do hóc ở trẻ em và cấm nhập khẩu.',
            'Kẹo cứng, kẹo dẻo, kẹo cao su, bỏng ngô, hạt dưa, hạt hướng dương: không cho trẻ nhỏ.',
            'Món cứng, tròn nên cắt nhỏ không quá khoảng 1 cm (AAP); thức ăn cầm tay nên mềm, dài cỡ ngón tay người lớn để bé dễ cầm (NHS).',
          ),
          h('Theo dõi'),
          ul(
            'Bé hay oẹ với kết cấu nào; oẹ thường giảm dần khi bé quen. Nôn, sặc nhiều lần trong bữa cần hỏi bác sĩ.',
            'Sau một lần hóc hay sặc, bé vẫn ho, khò khè, thở nhanh: dị vật có thể còn trong đường thở.',
            'Đồ vật nhỏ quanh bé như pin cúc áo, nam châm, hạt cườm, đồng xu, đồ chơi có chi tiết rời: cất xa tầm tay.',
            'Ba mẹ và người trông bé nên học sơ cứu hóc dị vật; mở trước mục Sơ cứu trẻ em trong Child Life để làm quen.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            'Bé không chịu ăn thì bịt mũi, đổ thìa thức ăn vào → Cả nhà làm vậy vì lo bé đói, nhưng khi bị bịt mũi bé phải há miệng hít vào, thức ăn có thể sặc vào đường thở → Không ép; dừng bữa khi bé từ chối và mời lại vào bữa sau.',
            'Vừa ăn vừa chơi, xem điện thoại hay chở đi dạo bằng xe máy cho bé ăn được nhiều → Khi chạy nhảy hoặc mải nhìn màn hình, bé nuốt vội, dễ hóc; trên xe lại khó xử trí kịp → Cho bé ngồi một chỗ, bữa ăn gọn gàng, không kéo dài.',
            'Nhai mớm cho bé “cho mềm” → Nước bọt người lớn có thể truyền vi khuẩn gây sâu răng và mầm bệnh khác sang bé → Nghiền, băm bằng dụng cụ sạch; không nếm rồi dùng chung thìa với bé.',
            'Thấy bé oẹ là quay lại cháo xay nhuyễn → Oẹ là một phần của việc học ăn, NHS khuyên tiếp tục cho bé tập thức ăn lợn cợn → Giữ độ thô phù hợp, ngồi cạnh bé và bình tĩnh.',
            'Khi bé hóc thì dốc ngược bé lên hoặc thò tay móc họng → Có thể đẩy dị vật vào sâu hơn → Làm theo các bước đúng độ tuổi trong mục Sơ cứu trẻ em › Hóc dị vật.',
          ),
          doctor(
            'Gọi 115 hoặc đến cấp cứu ngay khi',
            'Bé ho không ra tiếng, không khóc, không thở được, tím tái hoặc lả đi; bé bất tỉnh sau khi hóc; nghi bé nuốt pin cúc áo hoặc nam châm, kể cả khi bé chưa có triệu chứng gì. Gọi 115 hoặc đến viện ngay; không gây nôn, và không cho bé ăn uống gì trừ khi nhân viên y tế hay trung tâm chống độc hướng dẫn. Ở Mỹ, trung tâm chống độc có thể hướng dẫn cho trẻ trên 1 tuổi uống mật ong trên đường đến viện khi nuốt pin cúc áo.',
          ),
          doctor(
            'Đưa bé đi khám trong ngày khi',
            'Sau một lần hóc hoặc sặc, dù dị vật đã ra, bé vẫn ho, khò khè, thở nhanh, khó nuốt, chảy nhiều nước dãi hoặc đau khi nuốt; bé thường xuyên ho sặc hoặc nôn trong bữa ăn.',
          ),
        ],
        en: [
          note(
            'In short',
            'Gagging while learning to eat is normal: babies are noisy, cough and push food out. Choking is usually silent: your baby cannot cough out loud, cry or breathe, and needs first aid right away. Prevent choking in three ways: your baby sits upright with an adult beside them, food is soft and cut to the right size, and no eating while running around or on a vehicle.',
          ),
          h('Understanding gagging vs choking'),
          p(
            "When babies start solids, the gag reflex helps them push a piece that is too big to the front of the mouth. According to the NHS, a gagging baby may have watery eyes, push the tongue out, retch or bring up a little food. It can look scary, but it is how babies learn to manage how much they can chew and swallow. Stay calm, sit beside them, don't put your fingers in their mouth and let them sort it out.",
          ),
          p(
            'Choking happens when food or an object blocks the airway. If your baby is still coughing loudly or crying, let them keep coughing and watch closely. If the cough is silent, they cannot cry, cannot breathe in or their lips turn blue, it is an emergency: call 115 and follow the Choking steps in the Sơ cứu trẻ em (First aid) guide in Child Life straight away.',
          ),
          p(
            'Young children choke easily because their chewing skills are still developing and they put everything in their mouths. The AAP advises keeping high-risk foods away until at least 4 years, while the NHS advises no whole nuts before 5 years; follow the safer age of 5.',
          ),
          h('What you can do'),
          h('Position and mealtime habits'),
          ul(
            'Your baby always sits upright to eat, ideally in a high chair with a harness; never feed them lying down, reclining or crawling.',
            'An adult sits with your baby and watches them for the whole meal. Keep an eye on young siblings, who often give babies food or small toys.',
            'No eating while running, walking, playing, in a car or on a moving motorbike.',
            'Keep meals calm and unhurried; turn off the TV and put phones away so your baby can focus on chewing and swallowing.',
            "Offer a small amount at a time and wait until it is swallowed before the next. Don't feed your baby while they are crying, have their mouth closed or turn away.",
          ),
          h('Preparing high-risk foods'),
          ul(
            'Grapes and cherry tomatoes: cut into quarters (NHS). Longan, lychee and rambutan are also round and slippery: remove the seed and cut very small.',
            'Peanuts, cashews, almonds: no whole or roughly crushed nuts before 5 years. Use finely ground nuts or smooth nut butter mixed into porridge or spread thinly on bread, never a spoonful of thick nut butter.',
            'Sausages and Chinese sausage: limit because they are salty; if you give them, cut lengthwise and then into tiny pieces, never into round slices.',
            'Hard raw vegetables and apple: steam or boil until soft, or grate.',
            'Cook meat until tender, then mince or shred it, avoiding large chewy chunks. Remove all fish bones carefully, including the fine ones.',
            'Sticky rice, bánh dày, bánh trôi and other glutinous rice cakes are sticky and can lodge in the throat: best not given to young babies; once your child is older and chews well, offer only tiny pieces and sit with them.',
            'Jelly, especially small cup jellies made to be sucked out and those containing konjac: do not give to young children. The FDA (US) notes that small konjac jelly cups have caused choking deaths in children and bans their import.',
            'Hard sweets, gummies, chewing gum, popcorn, melon seeds and sunflower seeds: not for young children.',
            'Cut hard, round foods into pieces no bigger than about 1 cm (AAP); finger foods should be soft and about the length of an adult finger so your baby can hold them (NHS).',
          ),
          h('What to watch'),
          ul(
            "Which textures make your baby gag; gagging usually eases as they get used to them. Frequent vomiting or choking during meals needs a doctor's advice.",
            'After a choking or coughing episode, ongoing coughing, wheezing or fast breathing: something may still be in the airway.',
            'Small objects around your baby such as button batteries, magnets, beads, coins and toys with loose parts: keep them out of reach.',
            'Parents and carers should learn first aid for choking; open the Sơ cứu trẻ em (First aid) guide in Child Life ahead of time to get familiar with it.',
          ),
          h('Common myths'),
          ul(
            'If a baby refuses food, hold the nose and pour the spoonful in → Families do this because they worry the baby is hungry, but with the nose held the baby must open the mouth to breathe in and food can be inhaled into the airway → Never force; end the meal when your baby refuses and offer food again at the next one.',
            'Eating while playing, watching a phone or riding around on a motorbike helps babies eat more → Running around or staring at a screen makes babies swallow in a hurry and choke more easily, and on a vehicle you cannot help them in time → Seat your baby in one place and keep meals short and focused.',
            'Pre-chewing food for the baby "to soften it" → Adult saliva can pass tooth-decay bacteria and other germs to the baby → Mash or mince with clean utensils, and don\'t taste food and then use the same spoon for your baby.',
            'Going back to smooth purée as soon as the baby gags → Gagging is part of learning to eat, and the NHS advises continuing to offer lumpy textures → Keep the texture suitable, sit with your baby and stay calm.',
            'Holding a choking baby upside down or hooking a finger into the throat → This can push the object further in → Follow the age-appropriate steps in the Sơ cứu trẻ em › Choking guide.',
          ),
          doctor(
            'Call 115 or go to the emergency department now if',
            'Your child cannot cough out loud, cannot cry or breathe, turns blue or goes limp; becomes unconscious after choking; or you think they swallowed a button battery or magnet, even with no symptoms yet. Call emergency services (115 in Việt Nam) or go to hospital now; do not make them vomit, and give nothing to eat or drink unless a health worker or poison centre tells you to. In the US, poison centres may advise honey for children over 1 on the way to hospital after a button battery.',
          ),
          doctor(
            'See a doctor the same day if',
            'After choking or coughing on food, even if the object came out, your child still coughs, wheezes, breathes fast, has trouble swallowing, drools a lot or has pain when swallowing; or often coughs, chokes or vomits during meals.',
          ),
        ],
      },
      keywords: t(
        [
          'hóc',
          'hóc dị vật',
          'oẹ',
          'nghẹn',
          'sặc',
          'ăn dặm an toàn',
          'nho',
          'thạch',
          'đậu phộng',
          'xương cá',
          'pin cúc áo',
          'nhai mớm',
        ],
        [
          'choking',
          'choking on food',
          'gagging',
          'food stuck',
          'coughing on food',
          'safe solids',
          'grapes',
          'jelly cups',
          'peanuts',
          'fish bones',
          'button battery',
          'pre-chewing',
        ],
      ),
      relatedArticleIds: [
        'art_solids_readiness',
        'art_solids_textures_by_month',
        'art_home_safety_falls',
        'art_car_motorbike',
      ],
      milestoneIds: ['pincer_grasp', 'mouths_objects', 'sits_up'],
      sources: [
        S.cNhsFirstSolids,
        S.cNhsChoking,
        S.cNhsFoodsToAvoid,
        S.cHcChokingPrevention,
        {
          label:
            'National Capital Poison Center (US) — Button battery ingestion triage and treatment guideline',
          url: 'https://www.poison.org/battery/guideline',
        },
        S.cFdaKonjacJellyCups,
        S.cHcToothDecayBaby,
        S.cGoshButtonBatteries,
      ],
    },
  },
  {
    id: 'art_allergen_intro',
    reviewerLabel: PAEDS,
    data: {
      library: 'solids',
      topic: 'feeding',
      format: 'article',
      ageWeeks: { from: 22, to: 60 },
      readingMinutes: 6,
      cover: null,
      title: t(
        'Cho bé làm quen thực phẩm dễ gây dị ứng: trứng, đậu phộng, tôm cua…',
        'Introducing allergenic foods: egg, peanut, shellfish and more',
      ),
      summary: t(
        'Cho bé làm quen sớm và đều đặn với trứng, đậu phộng, hải sản… từ khoảng 6 tháng có thể giúp giảm nguy cơ dị ứng. Cách cho từng món, dấu hiệu cần theo dõi, khi nào hỏi bác sĩ.',
        'Offering egg, peanut, seafood and other allergens early and regularly, from around 6 months, may help lower allergy risk. How to give each food, what to watch for, and when to ask a doctor.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Kiêng trứng, đậu phộng hay tôm cua không giúp phòng dị ứng, trì hoãn lâu còn có thể làm tăng nguy cơ. Khi bé đã ăn dặm (khoảng 6 tháng), cho từng món một với lượng nhỏ, ở nhà, vào ban ngày, rồi duy trì ít nhất mỗi tuần một lần. Bé bị chàm nặng hoặc đã dị ứng một món: hỏi bác sĩ trước.',
          ),
          h('Hiểu đúng về dị ứng thức ăn'),
          p(
            'Dị ứng thức ăn là khi hệ miễn dịch phản ứng nhầm với một loại protein trong thức ăn. Các món hay gây dị ứng ở trẻ nhỏ gồm trứng, sữa bò, đậu phộng (lạc), các loại hạt như hạt điều, óc chó, vừng (mè), đậu nành, lúa mì, cá và hải sản có vỏ như tôm, cua.',
          ),
          p(
            'Trước đây nhiều nơi khuyên kiêng các món này càng lâu càng tốt. Nghiên cứu LEAP cho thấy trẻ có nguy cơ cao được ăn đậu phộng đều đặn từ sớm giảm khoảng 80% nguy cơ dị ứng đậu phộng. Từ đó, AAP, NHS và các hội dị ứng Anh (BSACI), Úc (ASCIA), Canada (CSACI) đều khuyên không trì hoãn các món dễ dị ứng. NHS lưu ý trì hoãn trứng và đậu phộng quá 6–12 tháng tuổi có thể làm tăng nguy cơ dị ứng với chính các món này.',
          ),
          p(
            'Phần lớn bé ăn các món này lần đầu đều không sao, phản ứng nặng rất hiếm gặp. Chuẩn bị trước giúp ba mẹ bình tĩnh hơn. Mỗi bé một nhịp: chỉ bắt đầu khi bé đã ăn dặm được vài món thông thường.',
          ),
          h('Ba mẹ có thể làm gì'),
          h('Trước khi bắt đầu'),
          ul(
            'Bé đã ăn được vài món thông thường như cháo, bột, rau củ nghiền và có đủ dấu hiệu sẵn sàng ăn dặm.',
            'Bé có chàm (viêm da cơ địa) nặng, đã dị ứng một món, hoặc nhà có người dị ứng thức ăn, hen, viêm mũi dị ứng: hỏi bác sĩ trước. Hướng dẫn NIAID (Mỹ, 2017) khuyên trẻ chàm nặng hoặc dị ứng trứng nên được bác sĩ đánh giá và có thể ăn đậu phộng sớm, từ 4–6 tháng; trẻ chàm nhẹ đến vừa: khoảng 6 tháng.',
            'Chọn ngày bé khoẻ, không sốt, không tiêu chảy. Cho ăn ở nhà, vào buổi sáng hoặc trưa, khi bé sẽ còn thức ít nhất 2 giờ sau đó để ba mẹ theo dõi.',
          ),
          h('Cách cho từng món'),
          ul(
            'Mỗi lần chỉ một món mới. Bắt đầu khoảng ¼–½ thìa cà phê; nếu bé ổn, tăng dần trong vài ngày tiếp theo (BSACI).',
            'Trứng: luộc chín kỹ cả lòng trắng và lòng đỏ, nghiền trộn vào cháo, bột hoặc rau củ nghiền.',
            'Đậu phộng và các loại hạt: dùng bơ hạt mịn hoặc bột hạt xay thật mịn. BSACI gợi ý hoà 1 thìa cà phê bơ đậu phộng mịn với 1 thìa canh nước ấm hoặc sữa của bé, hoặc trộn vào cháo, rau củ nghiền. Không bao giờ cho hạt nguyên hoặc giã thô.',
            'Sữa bò: dùng trong nấu ăn, sữa chua hoặc phô mai tiệt trùng nguyên kem, không đường từ khoảng 6 tháng; chưa dùng làm đồ uống chính trước 1 tuổi.',
            'Cá, tôm, cua: nấu chín kỹ, gỡ sạch xương và vỏ, băm hoặc nghiền nhỏ. Chọn cá ít thuỷ ngân như cá hồi, cá rô phi, cá tuyết; tránh cá mập, cá kiếm, cá cờ, cá thu vua.',
            'Lúa mì, đậu nành, vừng: mì sợi hoặc bánh mì nấu mềm, đậu phụ, vừng rang xay mịn trộn vào cháo.',
            'Khi bé đã ăn mà không có phản ứng, duy trì món đó đều đặn, ít nhất mỗi tuần một lần (ASCIA, BSACI, CSACI). Cho một lần rồi thôi có thể làm mất tác dụng phòng ngừa.',
          ),
          tip(
            'Đỏ quanh miệng chưa chắc là dị ứng',
            'Cà chua, cam quýt, dâu tây có thể làm đỏ da quanh miệng do kích ứng, không phải dị ứng, và không cần kiêng. Cũng đừng bôi thử thức ăn lên da bé: cách này không giúp phát hiện dị ứng (BSACI).',
          ),
          h('Theo dõi'),
          p(
            'Phản ứng thường xuất hiện trong vài phút, có thể đến 2 giờ sau ăn; với sữa bò đôi khi muộn hơn, tới vài ngày (NHS).',
          ),
          ul(
            'Phản ứng nhẹ đến vừa: nổi mề đay, mẩn ngứa, sưng môi, mặt hoặc quanh mắt, nôn, đau bụng. Ngừng món đó, chụp ảnh vết mẩn và hỏi bác sĩ trước khi cho lại.',
            'Phản ứng nặng (sốc phản vệ, hiếm gặp): khó thở, thở rít, khò khè, ho liên tục, khàn tiếng, sưng lưỡi, da tái, bé lả hoặc mềm nhũn. Gọi 115 ngay và làm theo mục Sơ cứu trẻ em › Sốc phản vệ trong Child Life.',
            'Phản ứng chậm: chàm nặng lên, tiêu chảy hoặc táo bón, nôn trớ nhiều, bé từ chối ăn. Ghi lại món, lượng, giờ ăn và triệu chứng trong Child Life để đưa bác sĩ xem.',
          ),
          p(
            'Nếu bé phản ứng với một món, vẫn tiếp tục giới thiệu các món dễ dị ứng khác, trừ khi bác sĩ dặn khác (ASCIA). Đừng tự cắt bỏ cả một nhóm thực phẩm lớn như sữa vì bé có thể thiếu chất (NHS).',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            'Kiêng tôm cua, trứng, đậu phộng đến 1–2 tuổi cho “khỏi dị ứng” → Ông bà dặn vậy vì thương cháu, nhưng trì hoãn không phòng được dị ứng, có khi còn làm tăng nguy cơ → Cho bé làm quen từ khoảng 6 tháng, từng món, dạng an toàn, rồi duy trì đều.',
            'Mẹ cho con bú phải kiêng hải sản, đậu phộng, sữa bò để con không bị dị ứng → AAP và BSACI cho biết việc mẹ kiêng không giúp phòng dị ứng cho con, lại làm bữa ăn của mẹ nghèo chất → Mẹ ăn uống đa dạng; chỉ kiêng khi bác sĩ chỉ định vì bé đã được chẩn đoán dị ứng.',
            'Bôi thức ăn lên da bé để “thử” trước → Không giúp phát hiện dị ứng, lại có thể gây đỏ da khiến ba mẹ hiểu nhầm → Thử bằng đường ăn với lượng nhỏ và theo dõi như trên.',
            'Bé ăn tôm một lần thấy ổn là xong, lâu lâu mới cho lại → Duy trì đều đặn mới giữ được tác dụng phòng ngừa → Đưa món đó vào thực đơn hằng tuần.',
          ),
          doctor(
            'Gọi 115 ngay khi',
            'Sau khi ăn, bé khó thở, thở rít, khò khè, ho liên tục, khàn tiếng, sưng lưỡi hoặc họng, tím tái, da tái lạnh, lả đi hay mềm nhũn. Gọi 115 và trong lúc chờ, làm theo mục Sơ cứu trẻ em › Sốc phản vệ trong Child Life.',
          ),
          doctor(
            'Hỏi bác sĩ trước hoặc sớm khi',
            'Bé bị chàm nặng, đã dị ứng một món ăn, hoặc nhà có người dị ứng thức ăn; bé nổi mề đay, sưng môi mặt hoặc nôn sau khi ăn một món mới; chàm nặng lên, tiêu chảy, nôn hoặc quấy khóc kéo dài nghi liên quan đến một món ăn. Đừng tự cho ăn lại món nghi dị ứng khi chưa hỏi bác sĩ.',
          ),
        ],
        en: [
          note(
            'In short',
            'Avoiding egg, peanut or shellfish does not prevent allergy, and long delays may even raise the risk. Once your baby has started solids (around 6 months), offer one new food at a time in a small amount, at home, during the day, then keep giving it at least once a week. If your baby has severe eczema or already reacted to a food, ask the doctor first.',
          ),
          h('Understanding food allergy'),
          p(
            "A food allergy happens when the immune system wrongly reacts to a protein in food. Common triggers in young children include egg, cow's milk, peanut, tree nuts such as cashew and walnut, sesame, soy, wheat, fish, and shellfish such as shrimp and crab.",
          ),
          p(
            'In the past, families were often told to avoid these foods for as long as possible. The LEAP study showed that high-risk babies who ate peanut regularly from early on had about 80% lower risk of peanut allergy. Since then, the AAP, the NHS and the British (BSACI), Australian (ASCIA) and Canadian (CSACI) allergy societies all advise not delaying allergenic foods. The NHS notes that delaying egg and peanut beyond 6–12 months of age may increase the risk of allergy to those foods.',
          ),
          p(
            'Most babies have no problem the first time they eat these foods, and severe reactions are very rare. Being prepared helps you stay calm. Every baby has their own pace: start only once your baby is eating a few everyday foods.',
          ),
          h('What you can do'),
          h('Before you start'),
          ul(
            'Your baby already eats a few everyday foods such as porridge, cereal or mashed vegetables and shows all the signs of readiness for solids.',
            'If your baby has severe eczema, has reacted to a food, or someone in the family has food allergy, asthma or hay fever: ask the doctor first. The US NIAID guidelines (2017) advise that babies with severe eczema or egg allergy be assessed by a doctor and may have peanut early, from 4–6 months; babies with mild to moderate eczema at around 6 months.',
            'Choose a day when your baby is well, with no fever or diarrhea. Offer the food at home, in the morning or at midday, when your baby will be awake for at least 2 hours afterward so you can watch them.',
          ),
          h('How to offer each food'),
          ul(
            'Only one new food at a time. Start with about ¼–½ teaspoon; if your baby is fine, increase gradually over the next few days (BSACI).',
            'Egg: boil until both white and yolk are fully cooked, then mash into porridge, cereal or mashed vegetables.',
            "Peanut and tree nuts: use smooth nut butter or very finely ground nuts. BSACI suggests mixing 1 teaspoon of smooth peanut butter with 1 tablespoon of warm water or your baby's milk, or stirring it into porridge or mashed vegetables. Never give whole or roughly crushed nuts.",
            "Cow's milk: use it in cooking, or offer pasteurized full-fat unsweetened yogurt or cheese from around 6 months; not as a main drink before 1 year.",
            'Fish, shrimp, crab: cook thoroughly, remove all bones and shells, and mince or mash. Choose low-mercury fish such as salmon, tilapia and cod; avoid shark, swordfish, marlin and king mackerel.',
            'Wheat, soy, sesame: soft-cooked noodles or bread, tofu, toasted sesame ground fine and stirred into porridge.',
            'Once your baby has eaten a food without a reaction, keep giving it regularly, at least once a week (ASCIA, BSACI, CSACI). Giving it once and then stopping may cancel out the protective effect.',
          ),
          tip(
            'Redness around the mouth is not always allergy',
            "Tomato, citrus and strawberries can redden the skin around the mouth through irritation, not allergy, and need not be avoided. Don't rub food on your baby's skin to test either: it does not help detect allergy (BSACI).",
          ),
          h('What to watch'),
          p(
            "Reactions usually appear within minutes and can take up to 2 hours after eating; with cow's milk they are sometimes later, up to a few days (NHS).",
          ),
          ul(
            'Mild to moderate reactions: hives, itchy rash, swelling of the lips, face or around the eyes, vomiting, tummy pain. Stop that food, take a photo of the rash and ask the doctor before offering it again.',
            'Severe reaction (anaphylaxis, rare): trouble breathing, noisy breathing, wheezing, persistent cough, hoarse voice, swollen tongue, pale skin, baby floppy or limp. Call 115 now and follow the Anaphylaxis steps in the Sơ cứu trẻ em (First aid) guide in Child Life.',
            'Delayed reactions: worsening eczema, diarrhea or constipation, frequent vomiting, refusing food. Log the food, amount, time and symptoms in Child Life to show the doctor.',
          ),
          p(
            "If your baby reacts to one food, keep introducing the other allergenic foods unless the doctor advises otherwise (ASCIA). Don't cut out a major food group such as milk on your own, as your baby could miss out on nutrients (NHS).",
          ),
          h('Common myths'),
          ul(
            'Avoid shrimp, crab, egg and peanut until 1–2 years "to prevent allergy" → Grandparents advise this out of love, but delaying does not prevent allergy and may even raise the risk → Introduce them from around 6 months, one at a time, in a safe form, then keep giving them.',
            "Breastfeeding mothers must avoid seafood, peanut and cow's milk so the baby won't become allergic → The AAP and BSACI say maternal avoidance does not prevent allergy in the baby, and it makes the mother's diet poorer → Eat a varied diet; avoid foods only if a doctor advises it because your baby has a diagnosed allergy.",
            'Rubbing food on the baby\'s skin to "test" first → It does not detect allergy and can cause redness that is easily misread → Test by eating a small amount and watch as described above.',
            'Once the baby has eaten shrimp without trouble, it is fine to offer it only rarely → Regular eating is what keeps the protective effect → Make that food part of the weekly menu.',
          ),
          doctor(
            'Call 115 now if',
            'After eating, your baby has trouble breathing, noisy breathing, wheezing, persistent coughing, a hoarse voice, a swollen tongue or throat, turns blue, has pale cold skin, or goes limp or floppy. Call 115 and, while you wait, follow the Anaphylaxis steps in the Sơ cứu trẻ em (First aid) guide in Child Life.',
          ),
          doctor(
            'Ask a doctor first, or soon, if',
            "Your baby has severe eczema, has reacted to a food, or someone in the family has food allergy; hives, swollen lips or face, or vomiting after a new food; worsening eczema, diarrhea, vomiting or long crying spells that seem linked to a food. Don't offer a suspected food again before asking the doctor.",
          ),
        ],
      },
      keywords: t(
        [
          'dị ứng thức ăn',
          'dị ứng',
          'trứng',
          'đậu phộng',
          'lạc',
          'tôm cua',
          'hải sản',
          'sữa bò',
          'mề đay',
          'sốc phản vệ',
          'chàm',
          'kiêng ăn',
        ],
        [
          'food allergy',
          'allergy',
          'egg',
          'peanut',
          'groundnut',
          'shrimp and crab',
          'seafood',
          "cow's milk",
          'hives',
          'anaphylaxis',
          'eczema',
          'food avoidance',
        ],
      ),
      relatedArticleIds: [
        'art_solids_readiness',
        'art_eczema_dry_skin',
        'art_solids_textures_by_month',
        'art_solids_choking_safety',
      ],
      milestoneIds: [],
      sources: [
        S.cNhsFoodAllergies,
        S.cNhsFoodsToAvoid,
        S.cHcEarlyPeanut2019,
        S.cAafpNiaidPeanut,
        S.cAsciaIntroSolids,
        S.cBsaciParentSummary,
        S.cCsaciEatEarly,
        S.cFdaFishAdvice,
      ],
    },
  },
  {
    id: 'art_solids_textures_by_month',
    reviewerLabel: NUTRITION,
    data: {
      library: 'solids',
      topic: 'feeding',
      format: 'article',
      ageWeeks: { from: 22, to: 104 },
      readingMinutes: 5,
      cover: null,
      title: t(
        'Ăn dặm theo tháng: số bữa, độ thô và thực đơn từ 6 đến 24 tháng',
        'Solids month by month: meals, textures and menus from 6 to 24 months',
      ),
      summary: t(
        'Từ cháo nghiền đến cơm gia đình: số bữa, độ thô và lượng ăn gợi ý theo WHO, UNICEF, NHS, cùng cách giúp bé ăn đa dạng theo nhịp riêng của mình.',
        'From mashed porridge to family meals: meals, textures and suggested amounts from WHO, UNICEF and the NHS, and how to help your baby eat a varied diet at their own pace.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Tăng dần độ thô theo khả năng của bé: nghiền mịn hoặc lợn cợn lúc 6 tháng, băm nhỏ và thức ăn cầm tay từ 7–9 tháng, đồ ăn gia đình cắt nhỏ quanh 12 tháng. Mỗi ngày nên có thịt, cá hoặc trứng cùng rau và trái cây. Lượng ăn chỉ là gợi ý: hãy theo tín hiệu no, đói của bé.',
          ),
          h('Hiểu đúng về độ thô và số bữa'),
          p(
            'Ăn dặm là quá trình bé học nhai, đảo thức ăn trong miệng và nuốt. NHS khuyên chuyển từ đồ xay nhuyễn sang nghiền, lợn cợn và thức ăn cầm tay ngay khi bé làm được; có bé thích thức ăn lợn cợn ngay từ đầu, có bé cần thêm thời gian. Bé không cần đủ răng mới ăn được đồ thô, vì thức ăn mềm có thể nghiền bằng lưỡi và lợi.',
          ),
          p(
            'Một nghiên cứu theo dõi gần 7.800 trẻ ở Anh (Coulthard và cộng sự, 2009) cho thấy trẻ được làm quen thức ăn lợn cợn sau 9 tháng tuổi về sau ăn ít rau, trái cây hơn và gặp nhiều khó khăn khi ăn hơn lúc 7 tuổi. Vì vậy không nên cho bé ăn đồ xay nhuyễn quá lâu.',
          ),
          p(
            'Sữa mẹ hoặc sữa công thức vẫn rất quan trọng trong năm đầu; WHO khuyên tiếp tục cho bú đến 2 tuổi hoặc lâu hơn. Với trẻ bú mẹ, WHO khuyên 6–8 tháng ăn 2–3 bữa mỗi ngày, 9–23 tháng ăn 3–4 bữa, thêm 1–2 bữa phụ nếu bé cần.',
          ),
          h('Ba mẹ có thể làm gì'),
          h('6 tháng: làm quen'),
          ul(
            'Bắt đầu 2–3 thìa nhỏ, ngày 2 lần (UNICEF), tăng dần theo sức ăn của bé.',
            'Cháo hoặc bột nấu đặc đến mức không chảy khỏi thìa; rau củ hấp nghiền; thịt, cá, trứng chín kỹ nghiền mịn hoặc băm nhuyễn.',
            'Có thể cho thêm que rau củ hấp mềm, chuối, bơ chín để bé tự cầm.',
          ),
          h('7–9 tháng: nghiền thô, băm nhỏ, tự cầm'),
          ul(
            'Khoảng 2–3 bữa chính, mỗi bữa khoảng nửa chén nhỏ (UNICEF), thêm một bữa phụ như chuối nghiền, đu đủ.',
            'Chuyển sang cháo hạt vỡ hoặc cháo nấu nhừ, thịt cá băm, rau củ thái hạt lựu mềm. NHS khuyên có thức ăn cầm tay trong mỗi bữa.',
            'Thức ăn cầm tay mềm, dài cỡ ngón tay người lớn, bóp nát được giữa hai ngón tay: cà rốt, bí đỏ, khoai lang hấp; trứng luộc chín; đậu phụ; cá gỡ xương.',
          ),
          h('9–12 tháng: cắt nhỏ, tập tự xúc'),
          ul(
            'Khoảng 3–4 bữa chính, mỗi bữa khoảng nửa chén nhỏ, thêm 1–2 bữa phụ (WHO, UNICEF).',
            'Thức ăn cắt nhỏ thay vì nghiền: cháo đặc hoặc cơm nát, thịt băm, rau thái nhỏ. Bé bắt đầu nhặt miếng nhỏ bằng ngón cái và ngón trỏ, uống bằng cốc thành thạo hơn.',
            'Cho bé cầm một chiếc thìa riêng để tập xúc; rơi vãi là một phần của việc học.',
          ),
          h('12–24 tháng: ăn cùng gia đình'),
          ul(
            'Khoảng 3–4 bữa chính và 1–2 bữa phụ; UNICEF gợi ý mỗi bữa khoảng ¾ đến 1 chén nhỏ.',
            'Bé ăn được phần lớn món của gia đình như cơm mềm, thịt cá thái nhỏ, rau luộc mềm. Múc phần của bé ra trước khi nêm muối, nước mắm.',
            'Sữa bò tươi nguyên kem tiệt trùng có thể dùng làm đồ uống từ 12 tháng; tập bỏ bình, chuyển sang uống bằng cốc.',
            'Cá nên chọn loại ít thuỷ ngân như cá hồi, cá rô phi, cá tuyết, tôm; FDA gợi ý trẻ 1–3 tuổi ăn khoảng 2 lần mỗi tuần, mỗi lần khoảng 30 g.',
          ),
          tip(
            'Mẹo: đếm nhóm thực phẩm',
            'WHO và UNICEF coi một ngày ăn của trẻ 6–23 tháng là đa dạng khi có ít nhất 5 trong 8 nhóm: sữa mẹ; ngũ cốc, khoai củ; đậu, hạt; sữa và chế phẩm sữa; thịt, cá; trứng; rau quả giàu vitamin A như bí đỏ, cà rốt, xoài, đu đủ; rau quả khác. UNICEF cũng khuyên thêm một ít dầu hoặc mỡ vào bữa ăn của bé để tăng năng lượng.',
          ),
          h('Theo dõi'),
          ul(
            'Tín hiệu đói: nhìn theo thức ăn, há miệng, đưa tay vào miệng. Tín hiệu no: ngậm miệng, quay đi, đẩy thìa, chơi với thức ăn.',
            'Cân nặng, chiều dài theo biểu đồ tăng trưởng ở các lần khám; một bữa ăn ít không đáng lo nếu bé vẫn chơi tốt và tăng cân đều.',
            'Bé có xử lý được độ thô mới không: oẹ nhẹ là bình thường, nhưng nôn hay sặc thường xuyên cần hỏi bác sĩ.',
            'Số nhóm thực phẩm mỗi ngày và các món mới bé đã thử; có thể ghi nhanh trong Child Life.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            'Xay nhuyễn đến 1 tuổi vì “chưa có răng thì chưa ăn thô được” → Ông bà sợ cháu hóc, nhưng bé nghiền được thức ăn mềm bằng lợi, và chậm làm quen đồ thô có thể khiến bé kén ăn về sau → Tăng độ thô từng bước, mềm và cắt đúng cỡ.',
            'Chỉ chan nước hầm xương, bỏ phần cái → Nhiều người tin “chất bổ nằm trong nước”, nhưng nước hầm chủ yếu là nước và một ít chất béo, còn đạm và sắt phần lớn ở lại trong thịt, cá → Băm nhỏ để bé ăn cả cái; WHO khuyên trẻ 6–23 tháng ăn thịt, cá hoặc trứng mỗi ngày.',
            'Nêm muối, nước mắm, hạt nêm cho bé “ăn ngon miệng” → Thận bé còn non; NHS khuyên không thêm muối, đường, và WHO khuyên trẻ nhỏ không ăn thức ăn nhiều đường, muối → Múc phần bé trước khi nêm; dùng vị tự nhiên của rau củ, thịt cá.',
            'Bé phải ăn hết bát mới đủ chất, nên dỗ dành, ép ăn → Ép ăn làm bé sợ bữa ăn, dễ sặc và khó tự nhận biết no đói → Cho ăn đáp ứng theo khuyến nghị của WHO: mời, khen, khuyến khích bé tự ăn và dừng khi bé no.',
          ),
          doctor(
            'Khi nào nên hỏi bác sĩ',
            'Bé chậm tăng cân hoặc sụt cân; đã quá 9 tháng mà bé vẫn chỉ ăn được đồ xay nhuyễn, hay nôn hoặc sặc khi ăn đồ có hạt; bé từ chối cả một nhóm thực phẩm lớn trong thời gian dài; bé táo bón, tiêu chảy hoặc nổi mẩn sau ăn; gia đình ăn chay hoặc bé phải kiêng nhiều món. Gọi 115 nếu bé khó thở, tím tái hoặc lả đi khi ăn.',
          ),
        ],
        en: [
          note(
            'In short',
            "Increase texture as your baby can manage: smooth or lumpy mash at 6 months, minced food and finger foods from 7–9 months, chopped family food around 12 months. Every day should include meat, fish or egg, plus vegetables and fruit. Amounts are only a guide: follow your baby's hunger and fullness cues.",
          ),
          h('Understanding textures and meals'),
          p(
            'Starting solids is how babies learn to chew, move food around the mouth and swallow. The NHS advises moving from smooth purées to mashed, lumpy and finger foods as soon as your baby can manage them; some babies like lumpy food from the start, others need more time. Babies do not need a full set of teeth for textured food, because soft food can be mashed with the tongue and gums.',
          ),
          p(
            'A study following nearly 7,800 children in the UK (Coulthard and colleagues, 2009) found that children first given lumpy food after 9 months ate fewer vegetables and fruit and had more feeding difficulties at 7 years. So avoid keeping your baby on smooth purée for too long.',
          ),
          p(
            'Breast milk or formula is still very important in the first year; WHO advises continuing breastfeeding to 2 years or beyond. For breastfed children, WHO advises 2–3 meals a day at 6–8 months and 3–4 meals at 9–23 months, plus 1–2 snacks if needed.',
          ),
          h('What you can do'),
          h('6 months: getting started'),
          ul(
            "Start with 2–3 small spoonfuls twice a day (UNICEF), increasing with your baby's appetite.",
            'Rice porridge or cereal thick enough not to run off the spoon; steamed mashed vegetables; well-cooked meat, fish and egg mashed smooth or finely minced.',
            'You can also offer soft steamed vegetable sticks, banana or ripe avocado for your baby to hold.',
          ),
          h('7–9 months: mashed, minced, self-feeding'),
          ul(
            'About 2–3 main meals, each about half a small bowl (UNICEF), plus a snack such as mashed banana or papaya.',
            'Move on to broken-rice porridge or well-cooked porridge, minced meat and fish, and soft diced vegetables. The NHS advises including finger foods at every meal.',
            'Finger foods should be soft, about the length of an adult finger, and squash easily between two fingers: steamed carrot, pumpkin, sweet potato; hard-boiled egg; tofu; boneless fish.',
          ),
          h('9–12 months: chopped food, learning to use a spoon'),
          ul(
            'About 3–4 main meals, each about half a small bowl, plus 1–2 snacks (WHO, UNICEF).',
            'Chopped rather than mashed food: thick porridge or soft rice, minced meat, finely chopped vegetables. Your baby starts picking up small pieces with thumb and forefinger and drinks from a cup more confidently.',
            'Give your baby their own spoon to practice with; spills are part of learning.',
          ),
          h('12–24 months: eating with the family'),
          ul(
            'About 3–4 main meals and 1–2 snacks; UNICEF suggests about ¾ to 1 small bowl per meal.',
            'Your child can eat most family dishes such as soft rice, chopped meat and fish, and soft boiled vegetables. Serve their portion before adding salt or fish sauce.',
            "Pasteurized whole cow's milk can be a main drink from 12 months; start moving from the bottle to a cup.",
            'Choose low-mercury fish such as salmon, tilapia, cod and shrimp; the FDA suggests about 2 servings a week for children aged 1–3, each about 30 g.',
          ),
          tip(
            'Tip: count the food groups',
            "WHO and UNICEF consider a day's diet for children 6–23 months diverse when it includes at least 5 of 8 groups: breast milk; grains, roots and tubers; pulses, nuts and seeds; dairy; meat and fish; eggs; vitamin A-rich fruit and vegetables such as pumpkin, carrot, mango and papaya; other fruit and vegetables. UNICEF also advises adding a little oil or fat to your baby's meals for energy.",
          ),
          h('What to watch'),
          ul(
            'Hunger cues: watching food, opening the mouth, hands to mouth. Fullness cues: closing the mouth, turning away, pushing the spoon away, playing with food.',
            'Weight and length on the growth chart at checkups; one small meal is no worry if your baby plays well and gains weight steadily.',
            "Whether your baby can manage new textures: mild gagging is normal, but frequent vomiting or choking needs a doctor's advice.",
            'The number of food groups each day and new foods tried; you can note them quickly in Child Life.',
          ),
          h('Common myths'),
          ul(
            'Keep food puréed until 1 year because "no teeth means no textures" → Grandparents fear choking, but babies can mash soft food with their gums, and late introduction of textures may lead to fussier eating later → Increase texture step by step, keeping food soft and cut to size.',
            'Serving only bone broth and leaving the solids → Many believe "the goodness is in the broth", but broth is mostly water with a little fat, while most of the protein and iron stay in the meat and fish → Mince the solids so your baby eats them; WHO advises meat, fish or egg every day for children 6–23 months.',
            'Adding salt, fish sauce or stock powder so the baby "enjoys the food" → Babies\' kidneys are immature; the NHS advises no added salt or sugar, and WHO advises that young children not eat foods high in sugar or salt → Serve your baby\'s portion before seasoning, and rely on the natural flavors of vegetables, meat and fish.',
            'The baby must finish the bowl to get enough, so coax or force → Forcing makes babies fear mealtimes, raises the risk of choking and makes it harder for them to recognize hunger and fullness → Feed responsively as WHO recommends: offer, praise, encourage self-feeding and stop when your baby is full.',
          ),
          doctor(
            'When to ask a doctor',
            'Your baby gains weight slowly or loses weight; is past 9 months and still only manages purées, or often vomits or chokes on textured food; refuses a whole major food group for a long time; has constipation, diarrhea or a rash after eating; or the family is vegetarian or your baby must avoid many foods. Call 115 (Vietnam emergency) if your baby has trouble breathing, turns blue or goes limp while eating.',
          ),
        ],
      },
      keywords: t(
        [
          'thực đơn ăn dặm',
          'ăn dặm theo tháng',
          'số bữa',
          'độ thô',
          'thức ăn cầm tay',
          'cháo',
          'lượng ăn',
          'nhóm thực phẩm',
          'kén ăn',
          'nước hầm xương',
          'ăn cùng gia đình',
        ],
        [
          'weaning menu',
          'solids by month',
          'number of meals',
          'texture',
          'finger foods',
          'rice porridge',
          'portion size',
          'food groups',
          'fussy eating',
          'bone broth',
          'family meals',
        ],
      ),
      relatedArticleIds: [
        'art_solids_readiness',
        'art_solids_choking_safety',
        'art_allergen_intro',
        'art_water_juice',
      ],
      milestoneIds: ['sits_up', 'transfers_hands', 'pincer_grasp', 'uses_objects_right'],
      sources: [
        S.cWhoIycfFactSheet,
        S.cWhoCfGuideline2023,
        S.cWhoDietaryDiversity,
        S.cUnicefFeeding6to12,
        S.cUnicefFeeding1to2,
        S.cNhsFirstSolids,
        S.cCoulthardLumps2009,
        S.cFdaFishAdvice,
      ],
    },
  },
  {
    id: 'art_water_juice',
    reviewerLabel: NUTRITION,
    data: {
      library: 'solids',
      topic: 'feeding',
      format: 'quick_qa',
      ageWeeks: { from: 0, to: 104 },
      readingMinutes: 2,
      cover: null,
      title: t(
        'Hỏi nhanh: Nước lọc và nước trái cây cho bé — khi nào, bao nhiêu?',
        'Quick Q&A: Water and juice for babies — when, and how much?',
      ),
      summary: t(
        'Bé dưới 6 tháng chỉ cần sữa. Từ 6 tháng tập nhấp nước bằng cốc; nước ép trái cây không cần trước 1 tuổi. Lượng gợi ý theo tuổi và những thức uống nên tránh.',
        'Babies under 6 months need only milk. From 6 months, offer sips of water from a cup; juice is not needed before 1 year. Suggested amounts by age and drinks to avoid.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Dưới 6 tháng: chỉ sữa mẹ hoặc sữa công thức, không cần uống nước. Từ 6 tháng: vài ngụm nước đun sôi để nguội bằng cốc trong bữa ăn. Không cần nước ép trước 1 tuổi; sau đó, nếu cho, thật ít và ưu tiên trái cây nguyên quả.',
          ),
          h('Bé dưới 6 tháng có cần uống nước không?'),
          p(
            'Không. WHO khuyên 6 tháng đầu bé chỉ bú mẹ, không cần cả nước; trời nóng thì cho bú thường xuyên hơn. Sữa công thức pha đúng tỉ lệ cũng đủ nước. Uống nước sớm làm bé bú ít đi; uống quá nhiều nước hoặc bú sữa pha loãng có thể gây ngộ độc nước, thậm chí co giật (AAP). NHS cho rằng bé bú sữa công thức có thể cần vài ngụm nước đun sôi để nguội khi trời rất nóng; hãy hỏi bác sĩ trước.',
          ),
          h('Từ 6 đến 12 tháng uống nước thế nào?'),
          p(
            'Khi bắt đầu ăn dặm, cho bé tập nhấp nước bằng cốc hở miệng hoặc cốc không van trong bữa ăn (NHS). AAP gợi ý khoảng 120–240 ml nước mỗi ngày; sữa vẫn là đồ uống chính. Nên dùng nước đun sôi để nguội.',
          ),
          h('Sau 1 tuổi thì sao?'),
          p(
            'Nước lọc và sữa là hai đồ uống chính. AAP gợi ý trẻ 12–24 tháng uống khoảng 240–960 ml nước và khoảng 480 ml sữa mỗi ngày. Từ 1 tuổi nên tập bỏ bình, uống bằng cốc (NHS).',
          ),
          h('Khi nào được uống nước ép trái cây?'),
          p(
            'AAP khuyên không cho nước ép trước 12 tháng. Từ 1 tuổi, nếu cho, chỉ dùng nước ép 100% không thêm đường, tối đa khoảng 120 ml mỗi ngày, uống bằng cốc trong bữa ăn và không cho trước khi ngủ. NHS khuyên pha loãng và chỉ cho trong bữa ăn để bảo vệ răng. Trái cây nguyên quả tốt hơn vì có chất xơ.',
          ),
          h('Hiểu lầm: nước đường, nước cam thảo, nước lá giúp bé “mát”, đỡ táo bón?'),
          p(
            'Ông bà cho uống vì thương cháu, nhưng các loại nước này không cần và làm bé bú ít đi; đường gây sâu răng, nước lá chưa rõ độ an toàn với trẻ nhỏ. Không cho mật ong trước 12 tháng. Bé táo bón thì hỏi bác sĩ.',
          ),
          h('Hiểu lầm: cho bé nhấp sữa đặc có đường, trà, cà phê, nước ngọt không sao?'),
          p(
            'Không nên. WHO khuyên trẻ 6–23 tháng không dùng đồ uống có đường và sữa đặc. Trà, cà phê, nước ngọt có ga không phù hợp với bé vì chứa caffeine, đường hoặc axit hại men răng (NHS, AAP).',
          ),
          doctor(
            'Khi nào nên hỏi bác sĩ',
            'Bé ít tã ướt, môi khô, thóp lõm, li bì; bé tiêu chảy, nôn nhiều, sốt hoặc bú kém khi trời nóng. Gọi 115 hoặc đến cấp cứu ngay nếu bé phù mặt, lơ mơ hay co giật sau khi uống nhiều nước hoặc bú sữa pha loãng.',
          ),
        ],
        en: [
          note(
            'In short',
            'Under 6 months: only breast milk or formula, no water needed. From 6 months: a few sips of boiled and cooled water from a cup with meals. No juice is needed before 1 year; after that, if you give any, keep it small and prefer whole fruit.',
          ),
          h('Does a baby under 6 months need water?'),
          p(
            'No. WHO advises breast milk only for the first 6 months, not even water; in hot weather, just breastfeed more often. Correctly made formula also provides enough water. Early water makes babies feed less; too much water or diluted formula can cause water intoxication and even seizures (AAP). The NHS says formula-fed babies may need a few sips of boiled and cooled water in very hot weather; ask the doctor first.',
          ),
          h('How should a baby drink water from 6 to 12 months?'),
          p(
            'When solids start, let your baby practice sipping water from an open cup or a free-flow cup without a valve at mealtimes (NHS). The AAP suggests about 120–240 ml of water a day; milk is still the main drink. Use boiled and cooled water.',
          ),
          h('What about after 1 year?'),
          p(
            'Water and milk are the two main drinks. The AAP suggests about 240–960 ml of water and about 480 ml of milk a day for children aged 12–24 months. From 1 year, start moving off the bottle and drinking from a cup (NHS).',
          ),
          h('When can my baby have fruit juice?'),
          p(
            'The AAP advises no juice before 12 months. From 1 year, if you give any, use only 100% juice with no added sugar, up to about 120 ml a day, from a cup with a meal and never at bedtime. The NHS advises diluting juice and giving it only at mealtimes to protect teeth. Whole fruit is better because it has fiber.',
          ),
          h(
            'Myth: sugar water, licorice water or herbal "cooling" drinks help babies and ease constipation?',
          ),
          p(
            'Grandparents give these out of love, but they are not needed and make babies feed less; sugar causes tooth decay, and herbal drinks have no proven safety for babies. No honey before 12 months. If your baby is constipated, ask the doctor.',
          ),
          h('Myth: a sip of sweetened condensed milk, tea, coffee or soda does no harm?'),
          p(
            'Avoid them. WHO advises that children 6–23 months have no sugar-sweetened drinks or condensed milk. Tea, coffee and fizzy drinks are not suitable for babies because they contain caffeine, sugar or acids that damage tooth enamel (NHS, AAP).',
          ),
          doctor(
            'When to ask a doctor',
            'Fewer wet diapers, dry lips, a sunken soft spot, unusual drowsiness; diarrhea, frequent vomiting, fever or poor feeding in hot weather. Call 115 (Vietnam emergency) or go to the emergency department now if your baby has a puffy face, becomes drowsy or has a seizure after drinking a lot of water or diluted formula.',
          ),
        ],
      },
      keywords: t(
        [
          'nước lọc',
          'uống nước',
          'nước ép',
          'nước trái cây',
          'cốc tập uống',
          'trời nóng',
          'ngộ độc nước',
          'nước đường',
          'sữa đặc',
          'sữa bò',
        ],
        [
          'water',
          'drinking water',
          'juice',
          'fruit juice',
          'sippy cup',
          'hot weather',
          'water intoxication',
          'sugar water',
          'condensed milk',
          "cow's milk",
        ],
      ),
      relatedArticleIds: [
        'art_solids_textures_by_month',
        'art_formula_bottle',
        'art_diarrhoea_dehydration',
        'art_constipation',
      ],
      milestoneIds: [],
      sources: [
        S.cWhoIycfFactSheet,
        S.cWhoCfGuideline2023,
        S.cNhsDrinksCups,
        S.cHcRecommendedDrinks,
        S.cHcFruitJuice,
        S.cHcFormulaWater,
      ],
    },
  },

  // ----- Sốt & ốm vặt (illness) -----
  {
    id: 'art_fever_when_to_call',
    reviewerLabel: PAEDS,
    data: {
      library: 'care',
      topic: 'illness',
      format: 'article',
      ageWeeks: { from: 0, to: 104 },
      readingMinutes: 6,
      cover: null,
      title: t(
        'Khi bé sốt: chăm sóc tại nhà và lúc nào cần đi khám',
        'When your baby has a fever: care at home and when to get help',
      ),
      summary: t(
        'Sốt là cách cơ thể chống nhiễm trùng. Tuổi của bé và cách bé bú, chơi, phản ứng quan trọng hơn con số trên nhiệt kế. Bé dưới 3 tháng sốt từ 38 °C cần được khám ngay.',
        "Fever is the body's way of fighting infection. Your baby's age and how they feed, play and respond matter more than the number. A baby under 3 months with 38 °C or more needs a doctor now.",
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Bé được coi là sốt khi nhiệt độ từ 38 °C trở lên. Bé dưới 3 tháng sốt từ 38 °C cần được khám ngay; với bé lớn hơn, việc bé bú, chơi, tỉnh táo ra sao nói lên nhiều hơn con số. Thuốc hạ sốt là để bé dễ chịu, không phải để kéo nhiệt độ về bình thường bằng mọi giá.',
          ),
          h('Hiểu đúng về sốt'),
          p(
            'Sốt là phản ứng tự nhiên, lành mạnh khi cơ thể chống lại nhiễm trùng, phần lớn do virus. Nhiệt độ thường trở lại bình thường sau 1–4 ngày. Bản thân cơn sốt không làm hại não bé. Khoảng 3–4 trên 100 trẻ có thể bị co giật khi sốt, hay gặp nhất quanh 12–18 tháng tuổi; cơn giật rất đáng sợ với ba mẹ nhưng thường không để lại hậu quả lâu dài, và thuốc hạ sốt không ngăn được co giật.',
          ),
          p(
            'Ở Việt Nam, ba mẹ cần nhớ thêm hai bệnh có sốt hay gặp: sốt xuất huyết và tay chân miệng. Với sốt xuất huyết, giai đoạn nguy hiểm thường đến đúng lúc bé bắt đầu hạ sốt, nên “hết sốt” chưa chắc là đã khỏi.',
          ),
          h('Ba mẹ có thể làm gì'),
          ul(
            'Đo bằng nhiệt kế điện tử. Bé dưới 4 tuần: đo ở nách. Bé từ 4 tuần: đo ở nách, hoặc dùng nhiệt kế hồng ngoại đo tai theo đúng hướng dẫn. Sờ trán chỉ để nghi ngờ, không thay được nhiệt kế. Cách đo từng bước có trong mục Sơ cứu trẻ em › Đo thân nhiệt của Child Life.',
            'Cho bú mẹ hoặc bú sữa thường xuyên hơn; với bé đang bú mẹ, sữa mẹ là thức uống tốt nhất. Bé đã ăn dặm có thể uống thêm từng ngụm nước.',
            'Mặc vừa đủ: một lớp quần áo mỏng, thoáng, phòng mát vừa phải. Không ủ chăn, không quấn chặt, nhưng cũng không cởi hết đồ của bé.',
            'Không lau người bằng nước để hạ sốt, không chườm đá, không lau cồn hay giấm.',
            'Cho bé nghỉ ở nhà, chưa đi nhà trẻ khi còn sốt. Kiểm tra bé cả trong đêm.',
            'Mỗi lần đo, ghi lại giờ, nhiệt độ, cữ bú, số tã ướt và thuốc đã dùng (có thể ghi trong Child Life) để đưa bác sĩ xem.',
          ),
          h('Thuốc hạ sốt: dùng khi bé khó chịu'),
          p(
            'Paracetamol hoặc ibuprofen giúp bé dễ chịu hơn; NICE (Anh) khuyên chỉ dùng khi bé có vẻ mệt, quấy, khó chịu, và dừng khi bé đã thoải mái. Ở Việt Nam: nhiều hướng dẫn lấy mốc từ 38,5 °C để cho thuốc. Dù theo cách nào, mục tiêu vẫn là giúp bé dễ chịu, không phải làm nhiệt độ về bình thường.',
          ),
          ul(
            'Bé dưới 3 tháng có sốt: đưa đi khám trước, chỉ dùng thuốc khi bác sĩ hướng dẫn.',
            'Paracetamol: theo NHS dùng được từ 2 tháng tuổi.',
            'Ibuprofen: NHS cho phép từ 3 tháng và nặng trên 5 kg, còn AAP (Mỹ) khuyên bé dưới 6 tháng chỉ dùng khi bác sĩ chỉ định; nên theo cách thận trọng hơn. Không dùng ibuprofen khi bé mất nước, bị thuỷ đậu, hoặc có thể đang bị sốt xuất huyết.',
            'Không bao giờ dùng aspirin cho trẻ dưới 16 tuổi. Không cho uống cùng lúc hai thuốc hạ sốt, không tự xen kẽ hai thuốc khi chưa được bác sĩ dặn.',
            'Hỏi bác sĩ hoặc dược sĩ liều theo cân nặng của bé, dùng dụng cụ đong đi kèm, và kiểm tra các thuốc khác bé đang dùng có trùng hoạt chất không.',
          ),
          h('Theo dõi những gì'),
          ul(
            'Bé có tỉnh táo, có cười, có chơi khi hạ sốt không. Đây là dấu hiệu rất đáng tin.',
            'Lượng bú và số tã ướt; dấu hiệu mất nước: môi miệng khô, khóc không có nước mắt, mắt trũng, thóp lõm.',
            'Nhịp thở khi bé nằm yên, và da bé: nếu có ban, ấn một cốc thuỷ tinh lên; ban không mất màu khi ấn là dấu hiệu cần cấp cứu.',
            'Số ngày sốt: sốt từ 5 ngày trở lên cần được khám, dù bé trông vẫn ổn.',
          ),
          h('Sốt xuất huyết và tay chân miệng: dấu hiệu cần đi viện'),
          p(
            'Sốt xuất huyết thường gây sốt cao 2–7 ngày. Ở vùng đang có dịch, Bệnh viện Nhi Trung ương khuyên đưa bé sốt cao từ ngày thứ 2 đi khám để được theo dõi. Đưa bé đến viện ngay khi bé mệt, lừ đừ, tay chân lạnh, đau bụng, nôn, chảy máu cam hoặc chảy máu chân răng, đi ngoài phân đen, tiểu ít, nhất là lúc vừa hạ sốt. Khi nghi sốt xuất huyết, chỉ dùng paracetamol, không dùng ibuprofen hay aspirin (WHO).',
          ),
          p(
            'Tay chân miệng hay gặp ở trẻ dưới 5 tuổi, với sốt, loét miệng và nốt phỏng ở bàn tay, bàn chân, mông. Theo Bệnh viện Nhi Trung ương, cần đưa bé đi khám lại ngay khi bé sốt cao từ 39 °C, giật mình, lừ đừ, run tay chân, quấy khóc, bứt rứt khó ngủ, nôn nhiều, đi loạng choạng, thở nhanh, khó thở, vã mồ hôi, tay chân lạnh hoặc da nổi vân tím.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            '“Ủ thật ấm cho ra mồ hôi là hết sốt.” Ông bà thường làm vậy vì thương cháu, nhưng ủ kín khiến nhiệt khó toả ra và bé dễ mất nước hơn. Nên mặc một lớp mỏng, thoáng và cho bú nhiều hơn.',
            '“Chườm đá, lau cồn, lau giấm cho nhanh hạ.” Nước lạnh có thể làm bé run và khó chịu hơn; cồn ngấm qua da có thể gây ngộ độc. Hướng dẫn hiện nay không khuyên lau người để hạ sốt; hãy để bé mặc thoáng và dùng thuốc đúng liều khi bé khó chịu.',
            '“Cạo gió, đánh cảm cho bé.” Cạo gió làm bé đau, để lại vết bầm trên da và không chữa được nguyên nhân gây sốt; điều đáng lo nhất là có thể làm chậm việc đi khám. Hãy theo dõi các dấu hiệu nặng ở trên.',
            '“Dán miếng hạ sốt là đủ.” Miếng dán có thể làm bé thấy mát ở trán, nhưng không thay được việc cho bú đủ, theo dõi bé và đi khám khi cần.',
            '“Sốt là phải có kháng sinh.” Phần lớn sốt ở trẻ nhỏ do virus, kháng sinh không có tác dụng. Chỉ dùng kháng sinh khi bác sĩ khám và kê đơn.',
          ),
          doctor(
            'Gọi 115 hoặc đến cấp cứu ngay khi',
            'Bé dưới 3 tháng sốt từ 38 °C; co giật (xem mục Sơ cứu trẻ em › Co giật trong Child Life); khó thở, thở rên, rút lõm lồng ngực; môi, lưỡi tím tái hoặc da tái, nổi vân; li bì, khó đánh thức; khóc yếu, khóc thét hoặc khóc liên tục; ban không mất màu khi ấn cốc; cổ cứng; thóp phồng; dấu hiệu nặng của sốt xuất huyết hoặc tay chân miệng ở trên. Đừng chờ, gọi 115 ngay.',
          ),
          doctor(
            'Đưa bé đi khám trong ngày khi',
            'Bé 3–6 tháng sốt từ 39 °C; sốt từ 5 ngày trở lên; bú kém, ít tã ướt hoặc có dấu hiệu mất nước; sốt cao từ ngày thứ 2 khi đang ở vùng có sốt xuất huyết; đau tai hoặc có ban mới; bé có vẻ mệt hơn so với lần khám trước; hoặc ba mẹ thấy lo. Cảm nhận của ba mẹ luôn đáng được lắng nghe.',
          ),
        ],
        en: [
          note(
            'In short',
            'A fever is a temperature of 38 °C or higher. A baby under 3 months with 38 °C or more needs to be seen straight away; in older babies, how they feed, play and stay alert tells you more than the number. Fever medicine is for comfort, not for bringing the temperature down at all costs.',
          ),
          h('Understanding fever'),
          p(
            "Fever is a natural, healthy response to infection, most often a virus. The temperature usually returns to normal within 1–4 days. A fever itself does not harm your baby's brain. About 3–4 in 100 children have a fit with a fever, most often around 12–18 months; it is frightening for parents but usually has no lasting effects, and fever medicine does not prevent these fits.",
          ),
          p(
            'In Vietnam, keep two common fever illnesses in mind: dengue and hand, foot and mouth disease. With dengue, the dangerous phase often comes just as the fever starts to fall, so "the fever is gone" does not always mean your baby is better.',
          ),
          h('What you can do'),
          ul(
            'Use a digital thermometer. Under 4 weeks: under the armpit. From 4 weeks: under the armpit, or an infrared ear thermometer used as directed. Feeling the forehead only raises suspicion; it does not replace a thermometer. Step-by-step instructions are in the Sơ cứu trẻ em (First aid) › Taking a temperature guide in Child Life.',
            'Offer breast or formula feeds more often; for a breastfed baby, breast milk is the best drink. Babies on solids can also have sips of water.',
            "Dress them just right: one light, airy layer and a comfortably cool room. Don't bundle them up or wrap them tightly, but don't strip them naked either.",
            "Don't sponge your baby with water to bring the fever down, and don't use ice, alcohol or vinegar.",
            'Keep your baby at home, away from nursery, while the fever lasts. Check on them during the night.',
            'Each time you measure, note the time, temperature, feeds, wet diapers and any medicine given (you can log this in Child Life) to show the doctor.',
          ),
          h('Fever medicine: for when your baby is uncomfortable'),
          p(
            'Paracetamol or ibuprofen can make your baby more comfortable; NICE (UK) advises using them only when your baby seems distressed and stopping once they are comfortable. In Việt Nam: many guidelines use 38.5 °C as the point to give medicine. Either way, the aim is comfort, not a normal temperature.',
          ),
          ul(
            'Under 3 months with a fever: see a doctor first, and only give medicine if the doctor advises it.',
            'Paracetamol: the NHS says it can be given from 2 months of age.',
            "Ibuprofen: the NHS allows it from 3 months and over 5 kg, while the AAP (US) advises babies under 6 months take it only if a doctor says so; follow the more cautious advice. Don't give ibuprofen if your baby is dehydrated, has chickenpox or might have dengue.",
            "Never give aspirin to anyone under 16. Don't give two fever medicines at the same time, and don't alternate them unless a doctor tells you to.",
            "Ask a doctor or pharmacist for the dose for your baby's weight, use the measuring device that comes with it, and check that other medicines your baby takes don't contain the same ingredient.",
          ),
          h('What to watch'),
          ul(
            'Whether your baby is alert, smiles and plays when the fever comes down. This is a very reliable sign.',
            'Feeds and wet diapers; signs of dehydration: dry lips and mouth, no tears when crying, sunken eyes, a sunken soft spot.',
            'Breathing while your baby is lying still, and their skin: if there is a rash, press a glass on it; a rash that does not fade under the glass needs emergency care.',
            'How many days the fever has lasted: a fever of 5 days or more needs a check-up, even if your baby seems fine.',
          ),
          h('Dengue and hand, foot and mouth disease: signs that need a hospital'),
          p(
            "Dengue usually causes a high fever for 2–7 days. Where there is an outbreak, Vietnam National Children's Hospital advises taking a child with a high fever from day 2 to be checked and followed. Go to hospital straight away if your child is tired, listless, has cold hands and feet, tummy pain, vomiting, a nosebleed or bleeding gums, black poo or passes little urine, especially just as the fever falls. If dengue is possible, use only paracetamol, never ibuprofen or aspirin (WHO).",
          ),
          p(
            "Hand, foot and mouth disease is common in children under 5, with fever, mouth ulcers and blisters on the hands, feet and bottom. Vietnam National Children's Hospital advises going back to the doctor straight away if your child has a fever of 39 °C or higher, startles or jerks, is listless, has trembling arms or legs, cries or is restless and can't sleep, vomits a lot, walks unsteadily, breathes fast or with difficulty, sweats heavily, or has cold hands and feet or blotchy purple skin.",
          ),
          h('Common misconceptions'),
          ul(
            '"Wrap them up warm to sweat the fever out." Grandparents often do this out of love, but bundling traps heat and makes dehydration more likely. Dress your baby in one light layer and offer more feeds.',
            '"Ice packs, or rubbing with alcohol or vinegar, bring it down faster." Cold water can make your baby shiver and feel worse; alcohol can be absorbed through the skin and cause poisoning. Current guidance does not recommend sponging to lower a fever; dress your baby lightly and give medicine at the right dose when they are uncomfortable.',
            '"Coin rubbing (cạo gió) to draw out the illness." It hurts, leaves bruises and does not treat the cause of the fever; the biggest worry is that it can delay getting medical care. Watch for the warning signs above instead.',
            '"A cooling patch is enough." A patch may make the forehead feel cooler, but it does not replace feeding well, watching your baby and seeing a doctor when needed.',
            '"A fever needs antibiotics." Most fevers in young children are caused by viruses, which antibiotics do not treat. Only use antibiotics when a doctor has examined your baby and prescribed them.',
          ),
          doctor(
            'Call 115 or go to the emergency department now if',
            'Your baby is under 3 months with 38 °C or more; has a fit (see Sơ cứu trẻ em (First aid) › Seizure in Child Life); struggles to breathe, grunts or the chest pulls in; has blue lips or tongue, or pale, blotchy skin; is floppy or hard to wake; has a weak, high-pitched or continuous cry; a rash that does not fade under a glass; a stiff neck; a bulging soft spot; or the dengue or hand, foot and mouth warning signs above. (115 is the emergency number in Vietnam.)',
          ),
          doctor(
            'See a doctor the same day if',
            "Your baby is 3–6 months with 39 °C or more; the fever has lasted 5 days or more; they feed poorly, have fewer wet diapers or show signs of dehydration; they have had a high fever from day 2 in an area with dengue; they have ear pain or a new rash; they seem more unwell than when last seen; or you are worried. A parent's instinct always deserves to be heard.",
          ),
        ],
      },
      keywords: t(
        [
          'sốt',
          'nhiệt độ',
          'nhiệt kế',
          'hạ sốt',
          'paracetamol',
          'co giật do sốt',
          'sốt xuất huyết',
          'tay chân miệng',
          'mất nước',
          'cấp cứu',
        ],
        [
          'fever',
          'temperature',
          'thermometer',
          'fever medicine',
          'paracetamol',
          'febrile seizure',
          'dengue',
          'hand foot and mouth',
          'dehydration',
          'emergency',
        ],
      ),
      relatedArticleIds: [
        'art_cold_cough',
        'art_diarrhoea_dehydration',
        'art_after_vaccines',
        'art_breastfeeding_start',
      ],
      milestoneIds: [],
      sources: [
        S.nhsFever,
        S.niceFeverNg143,
        S.hcFebrileSeizures,
        S.hcIbuprofenDosing,
        S.whoDengueFactSheet,
        S.nhtwDengueHomeCare,
        S.nhtwHfmdGuide,
        S.nhsHandFootMouth,
      ],
    },
  },
  {
    id: 'art_cold_cough',
    reviewerLabel: PAEDS,
    data: {
      library: 'care',
      topic: 'illness',
      format: 'article',
      ageWeeks: { from: 0, to: 104 },
      readingMinutes: 5,
      cover: null,
      title: t(
        'Cảm lạnh, ho, nghẹt mũi ở bé: chăm sóc an toàn tại nhà',
        'Colds, coughs and a blocked nose: safe care at home',
      ),
      summary: t(
        'Cảm lạnh do virus thường khỏi sau 7–10 ngày, ho có thể kéo dài hơn. Ba mẹ giúp bé dễ thở, bú đủ, tránh thuốc ho cảm và dầu nóng cho bé nhỏ, và biết đếm nhịp thở để nhận ra lúc cần đi khám.',
        'Viral colds usually clear in 7–10 days, though a cough can last longer. Help your baby breathe and feed, avoid cough and cold medicines and hot rubs for little ones, and learn to count breaths to spot trouble.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Cảm lạnh do virus, kháng sinh không chữa được, và bé thường đỡ dần sau 7–10 ngày; riêng ho có thể kéo dài thêm vài tuần. Nước muối sinh lý, hút mũi nhẹ và cho bú cữ nhỏ là đủ cho phần lớn bé. Hãy đếm nhịp thở và nhìn ngực bé: thở nhanh hay rút lõm lồng ngực là lúc cần đi khám.',
          ),
          h('Hiểu đúng về cảm lạnh'),
          p(
            'Cảm lạnh là nhiễm virus ở mũi họng, rất hay gặp ở trẻ nhỏ, nhất là khi bé bắt đầu đi nhà trẻ. Bé có thể sổ mũi, nghẹt mũi, hắt hơi, ho, sốt nhẹ, quấy và bú kém hơn. Triệu chứng thường rõ nhất trong 2–3 ngày đầu rồi đỡ dần sau 7–10 ngày. Ho giúp làm sạch đường thở nên có thể còn kéo dài sau khi bé đã hết sổ mũi.',
          ),
          p(
            'Bé nhỏ chưa biết xì mũi, nên chỉ cần nghẹt mũi là bé dễ bú ngắt quãng, ngủ chập chờn. Vì vậy, việc quan trọng nhất là giữ mũi thông trước cữ bú và giấc ngủ, đồng thời để ý nhịp thở của bé.',
          ),
          h('Ba mẹ có thể làm gì'),
          ul(
            'Nhỏ 2–3 giọt nước muối sinh lý vào mỗi bên mũi để làm loãng dịch, rồi hút nhẹ ở lỗ mũi bằng dụng cụ hút mũi cho trẻ; làm trước cữ bú và trước khi ngủ.',
            'Cho bú cữ nhỏ, thường xuyên hơn; bé bú mẹ thì tiếp tục bú mẹ. Bé từ 6 tháng có thể uống thêm từng ngụm nước.',
            'Nếu không khí trong phòng khô, có thể dùng máy tạo ẩm phun sương mát và vệ sinh máy hằng ngày; không dùng loại phun hơi nóng.',
            'Bé vẫn ngủ nằm ngửa trên mặt phẳng, chắc; không kê gối hay kê nghiêng nệm, kể cả khi bé nghẹt mũi.',
            'Bé từ 1 tuổi bị ho: có thể cho 2–5 ml mật ong khi cần (AAP). Không cho bé dưới 12 tháng dùng mật ong dưới bất kỳ hình thức nào vì nguy cơ ngộ độc botulinum.',
            'Rửa tay thường xuyên, che miệng khi ho, không hút thuốc trong nhà, hạn chế người đang ốm hôn bé.',
            'Nếu bé sốt, chăm theo bài “Khi bé sốt”.',
          ),
          h('Thuốc ho, thuốc cảm và dầu bôi'),
          p(
            'Thuốc ho, thuốc cảm không kê đơn chưa được chứng minh có ích ở trẻ nhỏ và có thể gây hại. FDA (Mỹ) không khuyên dùng cho trẻ dưới 2 tuổi, AAP không khuyên dùng dưới 4 tuổi, còn cơ quan quản lý thuốc Anh (MHRA) khuyên không dùng dưới 6 tuổi. Với bé dưới 2 tuổi, đừng dùng; với bé lớn hơn, chỉ dùng khi bác sĩ khuyên.',
          ),
          p(
            'Dầu bôi có long não (camphor) hoặc bạc hà (menthol) chỉ dùng cho trẻ từ 2 tuổi, bôi trên ngực, cổ, không bôi vào trong hay quanh mũi. Trẻ nhỏ rất nhạy với long não: nuốt phải có thể gây nôn, co giật. Kháng sinh không chữa cảm lạnh; chỉ dùng khi bác sĩ khám và kê đơn.',
          ),
          h('Theo dõi những gì'),
          ul(
            'Đếm nhịp thở trong đủ 1 phút khi bé nằm yên hoặc đang ngủ. Theo WHO, bé thở nhanh khi: dưới 2 tháng từ 60 lần mỗi phút, 2–12 tháng từ 50 lần, 1–5 tuổi từ 40 lần.',
            'Nhìn ngực bé: phần dưới lồng ngực lõm vào mỗi khi hít vào (rút lõm lồng ngực), cánh mũi phập phồng, thở rên hay thở rít là dấu hiệu khó thở.',
            'Lượng bú, uống và số tã ướt trong ngày.',
            'Sốt bao nhiêu độ, kéo dài mấy ngày; bé có đau tai hoặc chảy dịch tai không.',
            'Diễn biến: bé đỡ dần mỗi ngày, hay nặng lên sau khi đã đỡ.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            '“Xông lá, xông tinh dầu cho bé.” Nhà mình xông vì mong bé thông mũi nhanh, nhưng nồi nước nóng là nguyên nhân gây bỏng hay gặp ở trẻ, còn hiệu quả thì không rõ. Ngồi trong phòng tắm có hơi ấm từ vòi sen, nhỏ nước muối và hút mũi an toàn hơn.',
            '“Chanh đào ngâm mật ong, quất chưng mật ong cho bé dưới 1 tuổi.” Mật ong có thể chứa bào tử gây ngộ độc botulinum ở trẻ dưới 12 tháng. Với bé dưới 1 tuổi, chỉ cần bú đủ, nước muối và hút mũi.',
            '“Bôi dầu gió, dầu tràm lên ngực, mũi, lòng bàn chân.” Dầu nóng có thể làm rát da, khó chịu cho đường thở và gây ngộ độc nếu bé nuốt phải. Bé dưới 2 tuổi thì không bôi; bé lớn hơn, hỏi bác sĩ trước.',
            '“Cạo gió, kiêng gió, đóng kín cửa.” Cảm lạnh do virus lây qua giọt bắn và tay, không phải do “trúng gió”. Phòng thoáng, sạch, đủ ấm và rửa tay bảo vệ bé tốt hơn.',
            '“Ra hiệu thuốc mua kháng sinh cho nhanh khỏi.” Kháng sinh không tác dụng với virus, lại có thể gây tiêu chảy, dị ứng và làm vi khuẩn kháng thuốc. Chỉ dùng khi bác sĩ kê đơn.',
          ),
          doctor(
            'Gọi 115 hoặc đến cấp cứu ngay khi',
            'Bé khó thở, rút lõm lồng ngực, thở rên hoặc thở rít khi nằm yên; môi, lưỡi tím tái; có lúc ngừng thở; không bú, không uống được; li bì, khó đánh thức; co giật. Đừng chờ, gọi 115 ngay.',
          ),
          doctor(
            'Đưa bé đi khám trong ngày khi',
            'Bé dưới 3 tháng có bất kỳ dấu hiệu ốm nào, nhất là sốt từ 38 °C; thở nhanh theo ngưỡng ở trên; bú kém, ít tã ướt; đau tai hoặc chảy dịch tai; sốt trên 3 ngày hoặc trên 38,9 °C; nước mũi kéo dài quá 10–14 ngày; ho trên 3 tuần; không đỡ sau 10 ngày hoặc nặng lên sau khi đã đỡ.',
          ),
        ],
        en: [
          note(
            'In short',
            "Colds are caused by viruses, antibiotics do not cure them, and most babies improve after 7–10 days, though a cough can last a few more weeks. Saline drops, gentle suction and smaller feeds are enough for most babies. Count your baby's breaths and watch their chest: fast breathing or the chest pulling in means it is time to see a doctor.",
          ),
          h('Understanding colds'),
          p(
            'A cold is a viral infection of the nose and throat. It is very common in young children, especially once they start nursery. Your baby may have a runny or blocked nose, sneezing, a cough, a mild temperature, and be fussier and feed less. Symptoms are usually worst in the first 2–3 days and ease over 7–10 days. Coughing clears the airways, so it can carry on after the runny nose has gone.',
          ),
          p(
            "Babies can't blow their nose yet, so even a blocked nose can make feeds stop-start and sleep restless. The most important things are to clear the nose before feeds and sleep, and to keep an eye on your baby's breathing.",
          ),
          h('What you can do'),
          ul(
            'Put 2–3 drops of saline in each nostril to loosen mucus, then gently suction just inside the nostril with a baby nasal aspirator; do this before feeds and before sleep.',
            'Offer smaller, more frequent feeds; keep breastfeeding if you breastfeed. From 6 months, your baby can also have sips of water.',
            "If the air in the room is dry, you can use a cool-mist humidifier and clean it every day; don't use a warm-mist one.",
            'Your baby should still sleep on their back on a firm, flat surface; no pillows and no tilting the mattress, even with a blocked nose.',
            'From 1 year, for a cough: you can give 2–5 ml of honey as needed (AAP). Never give honey in any form to babies under 12 months because of the risk of infant botulism.',
            'Wash hands often, cover coughs, keep smoke out of the home and stop anyone who is unwell from kissing your baby.',
            'If your baby has a fever, follow the "When your baby has a fever" article.',
          ),
          h('Cough and cold medicines and rubs'),
          p(
            "Over-the-counter cough and cold medicines have not been shown to help young children and can cause harm. The FDA (US) advises against them under 2 years, the AAP under 4 years, and the UK medicines regulator (MHRA) under 6 years. For babies under 2, don't use them; for older children, only use them if a doctor advises it.",
          ),
          p(
            "Rubs with camphor or menthol are only for children aged 2 and over, on the chest and neck, never in or around the nose. Young children are very sensitive to camphor: swallowing it can cause vomiting and fits. Antibiotics don't cure colds; only use them when a doctor has examined your baby and prescribed them.",
          ),
          h('What to watch'),
          ul(
            'Count breaths for a full minute while your baby is lying still or asleep. According to WHO, breathing is fast if it is 60 or more a minute under 2 months, 50 or more at 2–12 months, or 40 or more at 1–5 years.',
            'Watch the chest: the lower chest sinking in with each breath (chest indrawing), flaring nostrils, grunting or a harsh noise when breathing in are signs of breathing difficulty.',
            'How much your baby feeds and drinks, and how many wet diapers a day.',
            'How high the temperature is and for how many days; whether your baby has ear pain or fluid from the ear.',
            'The overall course: getting a little better each day, or worse after starting to improve.',
          ),
          h('Common misconceptions'),
          ul(
            '"Steam with leaves or essential oils." Families do this hoping to clear the nose fast, but bowls of hot water are a common cause of scalds in children, and the benefit is unclear. Sitting in a steamy bathroom with the shower running, saline drops and suction are safer.',
            '"Lime or kumquat with honey for babies under 1." Honey can contain spores that cause botulism in babies under 12 months. Under 1 year, good feeding, saline and suction are all your baby needs.',
            '"Rub medicated oil or cajeput oil on the chest, nose or soles of the feet." Hot oils can sting the skin, irritate the airways and poison a child who swallows them. Don\'t use them under 2 years; for older children, ask a doctor first.',
            '"Coin rubbing, avoiding drafts, keeping every window shut." Colds are viruses spread by droplets and hands, not by "catching the wind". A clean, airy, comfortably warm room and handwashing protect your baby better.',
            '"Buy antibiotics at the pharmacy to get better faster." Antibiotics don\'t work on viruses, and they can cause diarrhoea, allergies and resistant bacteria. Only use them when a doctor prescribes them.',
          ),
          doctor(
            'Call 115 or go to the emergency department now if',
            'Your baby struggles to breathe, the chest pulls in, or they grunt or make a harsh noise breathing while resting; has blue lips or tongue; has pauses in breathing; cannot feed or drink; is floppy or hard to wake; or has a fit. (115 is the emergency number in Vietnam.)',
          ),
          doctor(
            'See a doctor the same day if',
            'Your baby is under 3 months with any sign of illness, especially 38 °C or more; breathes fast by the counts above; feeds poorly or has fewer wet diapers; has ear pain or fluid from the ear; has a fever for more than 3 days or above 38.9 °C; a runny nose for more than 10–14 days; a cough for more than 3 weeks; or is not better after 10 days or gets worse after improving.',
          ),
        ],
      },
      keywords: t(
        [
          'cảm lạnh',
          'ho',
          'nghẹt mũi',
          'sổ mũi',
          'nước muối sinh lý',
          'hút mũi',
          'thở nhanh',
          'rút lõm lồng ngực',
          'mật ong',
          'thuốc ho',
          'xông',
        ],
        [
          'cold',
          'cough',
          'blocked nose',
          'runny nose',
          'saline drops',
          'nasal aspirator',
          'fast breathing',
          'chest indrawing',
          'honey',
          'cough medicine',
          'steam',
        ],
      ),
      relatedArticleIds: ['art_fever_when_to_call', 'art_safe_sleep', 'art_breastfeeding_start'],
      milestoneIds: [],
      sources: [
        S.nhsCold,
        S.hcChildrenAndColds,
        S.hcCoughColdRemedies,
        S.fdaKidsCoughCold,
        S.mhraCoughColdChildren,
        S.whoImciChartBooklet,
        S.poisonOrgVapourRub,
        S.nhsNewcastleSteamBurns,
      ],
    },
  },
  {
    id: 'art_diarrhoea_dehydration',
    reviewerLabel: PAEDS,
    data: {
      library: 'care',
      topic: 'illness',
      format: 'article',
      ageWeeks: { from: 0, to: 104 },
      readingMinutes: 5,
      cover: null,
      title: t(
        'Tiêu chảy, nôn và mất nước: bù nước đúng cách cho bé',
        'Diarrhoea, vomiting and dehydration: giving fluids the right way',
      ),
      summary: t(
        'Tiêu chảy, nôn ở trẻ nhỏ thường do virus và tự khỏi. Quan trọng nhất là tiếp tục cho bú, bù nước bằng ORS pha đúng cách từng thìa nhỏ và nhận ra sớm dấu hiệu mất nước.',
        'Diarrhoea and vomiting in young children are usually viral and pass on their own. What matters most is to keep feeding, give correctly mixed ORS in small spoonfuls and spot dehydration early.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Đừng nhịn ăn, đừng ngưng sữa. Tiếp tục bú mẹ, sữa công thức pha đúng tỉ lệ, và cho bé uống dung dịch bù nước (ORS) pha đúng lượng nước ghi trên gói, từng thìa nhỏ. Bé ít tã ướt, lừ đừ, mắt trũng hay thóp lõm cần được khám ngay.',
          ),
          h('Hiểu đúng về tiêu chảy và nôn'),
          p(
            'Tiêu chảy là đi phân lỏng hoặc toàn nước, nhiều lần hơn hẳn so với bình thường của bé. Bé bú mẹ hoàn toàn thường đi phân mềm, sệt nhiều lần mỗi ngày; đó không phải tiêu chảy nếu bé vẫn bú tốt, lên cân. Phần lớn tiêu chảy, nôn ở trẻ nhỏ do virus, như virus rota: nôn thường hết sau 1–2 ngày, tiêu chảy thường hết sau 5–7 ngày.',
          ),
          p(
            'Điều đáng lo nhất là mất nước, vì cơ thể nhỏ của bé mất nước và muối rất nhanh qua phân và chất nôn. Bé dưới 1 tuổi (nhất là dưới 6 tháng), bé sinh nhẹ cân, bé đi ngoài trên 5 lần hoặc nôn trên 2 lần trong 24 giờ, và bé bỏ bú trong lúc ốm có nguy cơ mất nước cao hơn.',
          ),
          h('Ba mẹ có thể làm gì'),
          ul(
            'Tiếp tục cho bú mẹ và cho bú nhiều lần hơn. Bé bú sữa công thức: pha đúng tỉ lệ như thường lệ, không pha loãng.',
            'Cho uống ORS (oresol) để bù nước: pha đúng thể tích nước sạch ghi trên gói, không chia nhỏ gói, không tự thêm đường hay muối. Pha sai tỉ lệ có thể gây hại cho bé.',
            'Cách cho uống: bé dưới 2 tuổi, đút từng thìa cà phê (khoảng 5 ml) mỗi 1–2 phút, không dùng bình bú; bé lớn hơn uống từng ngụm bằng cốc. Nếu bé nôn, chờ 10 phút rồi cho tiếp, chậm hơn (WHO).',
            'Lượng ORS sau mỗi lần đi ngoài và tổng lượng trong ngày tuỳ cân nặng và mức mất nước: hỏi nhân viên y tế hoặc dược sĩ. Dung dịch đã pha chỉ dùng trong thời gian ghi trên gói; quá thời gian thì đổ đi và pha mới.',
            'Kẽm: WHO khuyến cáo trẻ tiêu chảy dùng kẽm trong 10–14 ngày để mau khỏi, nhất là ở các nước thu nhập thấp và trung bình như Việt Nam; ở Anh, Mỹ, Úc, kẽm không được dùng thường quy. Dùng theo hướng dẫn của nhân viên y tế.',
            'Bé đã ăn dặm: tiếp tục cho ăn món quen, dễ tiêu, chia nhiều bữa nhỏ.',
            'Tránh nước ngọt có ga và nước ép trái cây vì có thể làm tiêu chảy nặng hơn.',
            'Không tự dùng thuốc cầm tiêu chảy hay thuốc chống nôn cho bé; NHS khuyên không dùng thuốc cầm tiêu chảy cho trẻ dưới 12 tuổi. Xem thêm mục Sơ cứu trẻ em › Ngộ độc thực phẩm trong Child Life.',
            'Rửa tay bằng xà phòng sau khi thay tã và trước khi pha sữa, chuẩn bị đồ ăn; rửa sạch bình sữa, đồ chơi.',
            'Vắc xin rota (dạng uống) giúp phòng một nguyên nhân tiêu chảy nặng hay gặp; hỏi bác sĩ về thời điểm cho bé uống.',
          ),
          h('Theo dõi những gì'),
          ul(
            'Số lần đi ngoài, số lần nôn, màu chất nôn, và phân có máu hay không.',
            'Lượng bú, lượng ORS bé uống được và số tã ướt.',
            'Dấu hiệu mất nước: ít tã ướt hơn hẳn; môi, miệng khô; khóc ít hoặc không có nước mắt; mắt trũng; thóp lõm; bé lừ đừ hoặc quấy bất thường.',
            'Dấu hiệu nặng: da tái, nổi vân, tay chân lạnh, thở nhanh, li bì, khó đánh thức.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            '“Tiêu chảy thì phải nhịn ăn, ngưng sữa cho ruột nghỉ.” Ông bà lo bé ăn vào lại đi ngoài, nhưng nhịn ăn làm bé yếu, mất nước nhanh và lâu khỏi hơn. Nên tiếp tục bú mẹ, bú sữa và ăn bữa quen.',
            '“Pha sữa loãng cho dễ tiêu.” Sữa loãng làm bé thiếu năng lượng mà không giúp hết tiêu chảy. Hãy pha đúng tỉ lệ.',
            '“Kiêng tanh, kiêng dầu mỡ, chỉ ăn cháo trắng với muối.” Kiêng quá nhiều khiến bé thiếu chất đúng lúc cần hồi phục. Cho bé ăn món quen, dễ tiêu, đủ đạm, chia nhỏ bữa.',
            '“Tự nấu nước cháo muối, nước đường muối, pha ORS theo cảm tính.” Lượng muối, đường không chuẩn có thể làm bé mất nước nặng hơn. Ưu tiên ORS pha đúng hướng dẫn trên gói; nếu chưa có ORS, tiếp tục cho bú và đưa bé đến cơ sở y tế.',
            '“Uống thuốc cầm tiêu chảy cho nhanh khỏi.” Thuốc cầm tiêu chảy có thể gây biến chứng nguy hiểm ở trẻ nhỏ; chỉ dùng thuốc khi bác sĩ chỉ định.',
          ),
          doctor(
            'Gọi 115 hoặc đến cấp cứu ngay khi',
            'Bé nôn ra dịch xanh lá hoặc vàng xanh, nôn ra máu hay chất như bã cà phê; li bì, khó đánh thức; da tái, nổi vân, tay chân lạnh; thở nhanh; co giật; bụng chướng căng hoặc đau dữ dội. Đừng chờ, gọi 115 ngay.',
          ),
          doctor(
            'Đưa bé đi khám trong ngày khi',
            'Bé dưới 1 tuổi bị tiêu chảy hoặc nôn mà ba mẹ lo lắng, nhất là bé dưới 3 tháng hoặc sốt từ 38 °C; có bất kỳ dấu hiệu mất nước nào; không uống được hoặc nôn hết mọi thứ; phân có máu; bé từ 3 tháng sốt từ 39 °C; tiêu chảy quá 7 ngày hoặc nôn quá 2 ngày.',
          ),
        ],
        en: [
          note(
            'In short',
            "Don't stop food and don't stop milk. Keep breastfeeding, make formula at the usual strength, and give oral rehydration solution (ORS) mixed with exactly the amount of water on the packet, in small spoonfuls. A baby with fewer wet diapers, who is listless, has sunken eyes or a sunken soft spot needs to be seen straight away.",
          ),
          h('Understanding diarrhoea and vomiting'),
          p(
            "Diarrhoea means runny or watery poo, much more often than is usual for your baby. Exclusively breastfed babies often pass soft, loose poo many times a day; that isn't diarrhoea if they feed well and gain weight. Most diarrhoea and vomiting in young children is caused by viruses such as rotavirus: vomiting usually stops within 1–2 days and diarrhoea within 5–7 days.",
          ),
          p(
            "The main worry is dehydration, because a baby's small body loses water and salts quickly through poo and vomit. Babies under 1 year (especially under 6 months), babies born small, babies who have had more than 5 diarrhoeal poos or vomited more than twice in 24 hours, and babies who stop feeding while ill are at higher risk.",
          ),
          h('What you can do'),
          ul(
            'Keep breastfeeding and offer feeds more often. If your baby has formula, make it up at the usual strength; never dilute it.',
            "Give ORS (oral rehydration salts) to replace fluids: mix it with exactly the volume of clean water on the packet, don't split sachets, and don't add sugar or salt. Getting the mix wrong can harm your baby.",
            'How to give it: under 2 years, a teaspoon (about 5 ml) every 1–2 minutes, not from a bottle; older children take sips from a cup. If your baby vomits, wait 10 minutes, then carry on more slowly (WHO).',
            'How much ORS to give after each loose poo and over the day depends on weight and how dehydrated your baby is: ask a health worker or pharmacist. Only use made-up solution within the time on the packet; after that, throw it away and make fresh.',
            'Zinc: WHO recommends zinc for 10–14 days for children with diarrhoea to help them recover faster, especially in low- and middle-income countries such as Việt Nam; in the UK, US and Australia zinc is not given routinely. Give it as a health worker advises.',
            'Babies on solids: keep offering familiar, easy foods in small, frequent meals.',
            'Avoid fizzy drinks and fruit juice, which can make diarrhoea worse.',
            "Don't give medicine to stop diarrhoea or vomiting unless a doctor prescribes it; the NHS advises no anti-diarrhoea medicine for children under 12. See also Sơ cứu trẻ em (First aid) › Food poisoning in Child Life.",
            'Wash your hands with soap after diaper changes and before making up feeds or food; clean bottles and toys well.',
            'The rotavirus vaccine (given by mouth) protects against a common cause of severe diarrhoea; ask your doctor when your baby should have it.',
          ),
          h('What to watch'),
          ul(
            'How many times your baby has diarrhoea or vomits, the colour of the vomit, and whether there is blood in the poo.',
            'How much your baby feeds, how much ORS they take, and how many wet diapers.',
            'Signs of dehydration: far fewer wet diapers; dry lips and mouth; few or no tears; sunken eyes; a sunken soft spot; unusually listless or irritable.',
            'Serious signs: pale or blotchy skin, cold hands and feet, fast breathing, very drowsy or hard to wake.',
          ),
          h('Common misconceptions'),
          ul(
            '"With diarrhoea, stop food and milk to rest the gut." Grandparents worry that food goes straight through, but going without food makes babies weaker, more dehydrated and slower to recover. Keep breastfeeding, giving milk and familiar meals.',
            '"Make formula weaker so it is easier to digest." Diluted milk leaves your baby short of energy and does not stop diarrhoea. Make it up at the right strength.',
            '"Avoid fish, meat and oil; just plain rice porridge with salt." Cutting out too many foods leaves your baby short of nutrients just when they need to recover. Offer familiar, easy food with enough protein, in small meals.',
            '"Home-made salty rice water or sugar-salt water, or ORS mixed by eye." The wrong amounts of salt and sugar can make dehydration worse. Use ORS mixed exactly as the packet says; if you have none, keep feeding and take your baby to a health facility.',
            '"Anti-diarrhoea medicine to stop it quickly." These medicines can cause dangerous complications in young children; only use medicine a doctor prescribes.',
          ),
          doctor(
            'Call 115 or go to the emergency department now if',
            'Your baby vomits green or yellow-green fluid, blood or something like coffee grounds; is very drowsy or hard to wake; has pale or blotchy skin and cold hands and feet; breathes fast; has a fit; or has a tight, swollen or very painful tummy. (115 is the emergency number in Vietnam.)',
          ),
          doctor(
            'See a doctor the same day if',
            'Your baby is under 1 year with diarrhoea or vomiting and you are worried, especially if under 3 months or with 38 °C or more; shows any sign of dehydration; cannot drink or vomits everything; has blood in the poo; is 3 months or older with 39 °C or more; has diarrhoea for more than 7 days or vomiting for more than 2 days.',
          ),
        ],
      },
      keywords: t(
        [
          'tiêu chảy',
          'nôn',
          'mất nước',
          'ORS',
          'oresol',
          'kẽm',
          'rota',
          'thóp lõm',
          'nước cháo muối',
        ],
        [
          'diarrhoea',
          'vomiting',
          'dehydration',
          'ORS',
          'oral rehydration',
          'zinc',
          'rotavirus',
          'sunken soft spot',
          'rice water',
        ],
      ),
      relatedArticleIds: [
        'art_fever_when_to_call',
        'art_formula_bottle',
        'art_breastfeeding_start',
        'art_water_juice',
      ],
      milestoneIds: [],
      sources: [
        S.whoDiarrhoea,
        S.nhsDiarrhoea,
        S.niceGastroCg84,
        S.msfWhoRehydrationPlans,
        S.niceFeverNg143,
      ],
    },
  },
  {
    id: 'art_newborn_jaundice',
    reviewerLabel: PAEDS,
    data: {
      library: 'care',
      topic: 'illness',
      format: 'article',
      ageWeeks: { from: 0, to: 8 },
      readingMinutes: 5,
      cover: null,
      title: t(
        'Vàng da sơ sinh: nhận biết, chăm sóc và khi nào cần khám',
        'Newborn jaundice: spotting it, caring for your baby and when to get help',
      ),
      summary: t(
        'Khoảng 6 trên 10 trẻ đủ tháng bị vàng da trong tuần đầu, phần lớn vô hại. Vàng da trong 24 giờ đầu, kéo dài quá 2 tuần hoặc kèm phân bạc màu cần khám ngay. Phơi nắng không chữa được vàng da.',
        'About 6 in 10 term babies get jaundice in the first week, and most cases are harmless. Jaundice in the first 24 hours, lasting over 2 weeks or with pale poo needs a doctor. Sunlight does not treat it.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Vàng da sơ sinh rất hay gặp và thường tự hết. Cho bé bú đủ, kiểm tra màu da dưới ánh sáng tốt mỗi ngày, và để ý màu phân. Vàng da xuất hiện trong 24 giờ đầu, lan rộng, kéo dài quá 14 ngày hoặc kèm phân nhạt màu là lúc cần đưa bé đi khám.',
          ),
          h('Hiểu đúng về vàng da sơ sinh'),
          p(
            'Bilirubin là sắc tố vàng sinh ra khi hồng cầu cũ bị phân huỷ. Gan của bé mới sinh còn non nên thải bilirubin chậm, bilirubin tích lại làm da và lòng trắng mắt vàng. Khoảng 60% trẻ đủ tháng và 80% trẻ sinh non bị vàng da trong tuần đầu (NICE). Vàng da thường rõ nhất vào khoảng ngày thứ 3 và hay hết sau khoảng 2 tuần (NHS).',
          ),
          p(
            'Phần lớn vàng da là vô hại. Nhưng nếu bilirubin lên quá cao mà không được điều trị, hiếm khi có thể gây tổn thương não. Vì vậy, nhận ra sớm và đo bilirubin đúng lúc rất quan trọng. Khi cần, bé được điều trị bằng chiếu đèn, là cách điều trị chuẩn và hiệu quả. Khoảng 10% bé bú mẹ vẫn còn vàng da lúc 1 tháng tuổi; thường lành tính, nhưng vẫn cần bác sĩ kiểm tra để loại trừ bệnh gan, đường mật.',
          ),
          h('Ba mẹ có thể làm gì'),
          h('Kiểm tra vàng da tại nhà'),
          ul(
            'Cởi đồ bé ở nơi đủ sáng, tốt nhất là ánh sáng tự nhiên ban ngày.',
            'Ấn nhẹ ngón tay lên da bé rồi buông ra: màu vàng thấy rõ hơn ở chỗ da vừa trắng lại.',
            'Nhìn lòng trắng mắt và lợi (nướu). Với bé da sẫm màu, vàng da khó thấy hơn; nhìn thêm dưới lưỡi, bên trong má.',
            'Vàng da thường bắt đầu ở mặt rồi lan xuống ngực, bụng, tay chân. Vàng lan xuống bụng, tay chân hoặc đậm dần là lúc cần cho bé đi đo bilirubin.',
            'Mắt nhìn chỉ để nghi ngờ; không thể đoán mức bilirubin bằng mắt.',
          ),
          h('Cho bú đủ'),
          ul(
            'Cho bé bú mẹ ít nhất 8–12 lần mỗi ngày trong những ngày đầu; đánh thức bé ngủ nhiều để bú.',
            'Bú đủ giúp bé đi ngoài nhiều hơn, và bilirubin được thải ra ngoài qua phân.',
            'Nếu bé bú yếu, ngủ li bì, hoặc mẹ lo không đủ sữa, hãy gặp nhân viên y tế sớm. Khi cần bổ sung, bác sĩ sẽ hướng dẫn dùng sữa mẹ vắt hoặc sữa công thức, không phải nước hay nước đường.',
            'Giữ giấy ra viện và kết quả đo bilirubin, đi tái khám đúng hẹn.',
          ),
          h('Theo dõi những gì'),
          ul(
            'Màu da, màu mắt mỗi ngày dưới ánh sáng tốt: vàng lan rộng hơn hay nhạt dần.',
            'Màu phân và nước tiểu: phân nhạt màu, trắng như phấn hoặc màu đất sét, nước tiểu vàng sẫm thấm màu tã có thể là dấu hiệu bệnh gan, đường mật; càng phát hiện sớm càng tốt.',
            'Số cữ bú, số tã ướt, tã bẩn mỗi ngày.',
            'Bé có tỉnh táo, bú khỏe không; bé quá buồn ngủ, khó đánh thức, quấy hoặc khóc thét bất thường là dấu hiệu nặng.',
          ),
          p(
            'Vàng da kéo dài bao lâu thì cần khám? NICE (Anh) khuyên kiểm tra mọi bé đủ tháng còn vàng da sau 14 ngày và bé sinh non sau 21 ngày; AAP (Mỹ) cho rằng vàng da ở bé bú mẹ có thể kéo dài đến khoảng 1 tháng. Bài này theo mốc thận trọng hơn: đưa bé đi khám nếu còn vàng da sau 14 ngày (sinh non: 21 ngày).',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            '“Phơi nắng sáng cho bé hết vàng da.” Ông bà hay làm vậy vì thương cháu, nhưng NICE và AAP đều cho rằng ánh nắng không phải cách điều trị vàng da an toàn: hiệu quả không đủ, bé lại dễ bị cháy nắng, nhiễm lạnh hoặc quá nóng. Ánh sáng ban ngày chỉ giúp nhìn rõ màu da; nếu cần điều trị, bé sẽ được chiếu đèn.',
            '“Cho uống nước lá, nước nhân trần, nước đường cho mát gan.” Bé dưới 6 tháng chỉ cần sữa mẹ hoặc sữa công thức. AAP khuyến cáo không cho uống nước hay nước đường để phòng hoặc giảm vàng da; nước lá còn có nguy cơ không sạch và làm bé bú ít đi.',
            '“Mẹ phải kiêng ăn để sữa không làm con vàng.” Kiêng khem chung chung chỉ làm mẹ mệt, ít sữa. Mẹ nên ăn uống đầy đủ, đa dạng. Nếu bé được chẩn đoán thiếu men G6PD, hãy hỏi bác sĩ về thực phẩm và thuốc mẹ, bé cần tránh, như đậu tằm, và không dùng băng phiến để cất quần áo, chăn màn của bé.',
            '“Vàng da do sữa mẹ thì phải ngừng cho bú.” NICE nhấn mạnh rằng thường vẫn tiếp tục cho bú được; bú nhiều còn giúp bé thải bilirubin. Chỉ thay đổi cách cho bú khi bác sĩ đã khám và hướng dẫn.',
          ),
          doctor(
            'Gọi 115 hoặc đến cấp cứu ngay khi',
            'Bé vàng da trong 24 giờ đầu sau sinh; bé li bì, rất khó đánh thức hoặc bỏ bú; khóc thét the thé; co giật; bé dưới 3 tháng sốt từ 38 °C. Xem thêm mục Sơ cứu trẻ em › Vàng da sơ sinh trong Child Life. Đừng chờ, gọi 115 ngay.',
          ),
          doctor(
            'Đưa bé đi khám trong ngày khi',
            'Vàng da đậm lên hoặc lan xuống bụng, tay chân; lòng trắng mắt vàng rõ; bé bú kém, ít tã ướt; phân nhạt màu như phấn hoặc nước tiểu vàng sẫm; còn vàng da sau 14 ngày (bé sinh non: sau 21 ngày); bé đã được chiếu đèn mà ba mẹ thấy vàng trở lại; hoặc ba mẹ thấy lo.',
          ),
        ],
        en: [
          note(
            'In short',
            'Newborn jaundice is very common and usually clears on its own. Feed your baby well, check their skin in good light every day, and watch the colour of their poo. Jaundice in the first 24 hours, jaundice that spreads, lasts more than 14 days, or comes with pale poo means your baby needs to see a doctor.',
          ),
          h('Understanding newborn jaundice'),
          p(
            "Bilirubin is a yellow pigment made when old red blood cells break down. A newborn's liver is still immature and clears bilirubin slowly, so it builds up and turns the skin and the whites of the eyes yellow. About 60% of term babies and 80% of preterm babies get jaundice in the first week (NICE). It is usually most noticeable around day 3 and often goes after about 2 weeks (NHS).",
          ),
          p(
            'Most jaundice is harmless. But if bilirubin gets very high and is not treated, it can rarely cause brain damage. That is why spotting it early and measuring bilirubin at the right time matter. When treatment is needed, babies have phototherapy (light treatment), which is the standard, effective treatment. About 10% of breastfed babies are still jaundiced at 1 month; this is usually harmless, but a doctor still needs to check for liver or bile duct problems.',
          ),
          h('What you can do'),
          h('Checking for jaundice at home'),
          ul(
            'Undress your baby somewhere bright, ideally in natural daylight.',
            'Press a finger lightly on the skin and let go: yellow shows up more clearly where the skin has just gone pale.',
            'Look at the whites of the eyes and the gums. Jaundice is harder to see on brown or black skin; also look under the tongue and inside the cheeks.',
            'Jaundice usually starts on the face and spreads to the chest, tummy, arms and legs. Yellow spreading to the tummy, arms or legs, or getting deeper, means your baby needs a bilirubin check.',
            "Looking only raises suspicion; you can't judge the bilirubin level by eye.",
          ),
          h('Feeding well'),
          ul(
            'Breastfeed at least 8–12 times a day in the first days; wake a sleepy baby for feeds.',
            'Feeding well helps your baby poo more, and bilirubin leaves the body in the poo.',
            "If your baby feeds weakly, is very sleepy, or you're worried about your milk supply, see a health worker early. If extra feeds are needed, the doctor will advise expressed breast milk or formula, not water or sugar water.",
            'Keep the discharge papers and bilirubin results, and go to follow-up checks on time.',
          ),
          h('What to watch'),
          ul(
            "Your baby's skin and eye colour each day in good light: is the yellow spreading or fading?",
            "The colour of poo and pee: pale, chalky white or clay-coloured poo, or dark yellow pee that stains the diaper, can be a sign of liver or bile duct disease; the earlier it's found, the better.",
            'Number of feeds, wet diapers and dirty diapers each day.',
            'Whether your baby is alert and feeding strongly; a baby who is very sleepy, hard to wake, fussy or has an unusual high-pitched cry is showing serious signs.',
          ),
          p(
            'How long is too long? NICE (UK) advises checking every term baby still jaundiced after 14 days and every preterm baby after 21 days; the AAP (US) says jaundice in breastfed babies can last up to about 1 month. This article follows the more cautious timing: see a doctor if your baby is still jaundiced after 14 days (preterm: 21 days).',
          ),
          h('Common misconceptions'),
          ul(
            '"Morning sun will clear the jaundice." Grandparents often do this out of love, but NICE and the AAP both say sunlight is not a safe treatment for jaundice: it is not effective enough, and babies can get sunburnt, chilled or overheated. Daylight only helps you see the colour; if treatment is needed, your baby will have phototherapy.',
            '"Give herbal water, artemisia tea or sugar water to cool the liver." Babies under 6 months only need breast milk or formula. The AAP advises against water or sugar water to prevent or lower jaundice; herbal drinks may also be unclean and make babies feed less.',
            '"Mum must avoid certain foods so her milk doesn\'t make the baby yellow." General food restrictions only leave mums tired and with less milk. Eat a full, varied diet. If your baby is diagnosed with G6PD deficiency, ask the doctor which foods and medicines you and your baby should avoid, such as fava beans, and do not use naphthalene mothballs with your baby’s clothes or bedding.',
            '"Breast milk jaundice means you must stop breastfeeding." NICE stresses that breastfeeding can usually continue; feeding often even helps clear bilirubin. Only change how you feed after a doctor has examined your baby and advised you.',
          ),
          doctor(
            'Call 115 or go to the emergency department now if',
            'Your baby has jaundice in the first 24 hours after birth; is very drowsy, very hard to wake or refuses feeds; has a high-pitched cry; has a fit; or is under 3 months with 38 °C or more. See also the Sơ cứu trẻ em (First aid) › Newborn jaundice guide in Child Life. (115 is the emergency number in Vietnam.)',
          ),
          doctor(
            'See a doctor the same day if',
            'The yellow gets deeper or spreads to the tummy, arms or legs; the whites of the eyes are clearly yellow; your baby feeds poorly or has fewer wet diapers; the poo is pale or chalky or the pee is dark yellow; jaundice lasts beyond 14 days (preterm: beyond 21 days); the yellow comes back after phototherapy; or you are worried.',
          ),
        ],
      },
      keywords: t(
        [
          'vàng da sơ sinh',
          'bilirubin',
          'chiếu đèn',
          'phơi nắng',
          'vàng da sữa mẹ',
          'phân bạc màu',
          'cữ bú',
          'G6PD',
        ],
        [
          'newborn jaundice',
          'bilirubin',
          'phototherapy',
          'sunlight',
          'breast milk jaundice',
          'pale poo',
          'feeds',
          'G6PD',
        ],
      ),
      relatedArticleIds: ['art_breastfeeding_start', 'art_formula_bottle', 'art_umbilical_cord'],
      milestoneIds: [],
      sources: [
        S.nhsNewbornJaundice,
        S.niceJaundiceCg98,
        S.niceJaundiceCg98Context,
        S.hcNewbornJaundice,
        S.aafpAapHyperbili2022,
      ],
    },
  },
  {
    id: 'art_after_vaccines',
    reviewerLabel: PAEDS,
    data: {
      library: 'care',
      topic: 'illness',
      format: 'step_guide',
      ageWeeks: { from: 0, to: 104 },
      readingMinutes: 5,
      cover: null,
      title: t(
        'Chăm sóc bé sau tiêm chủng: từng bước',
        'Caring for your baby after vaccinations: step by step',
      ),
      summary: t(
        'Sau tiêm, bé có thể đau, sưng chỗ tiêm, sốt nhẹ, quấy vài ngày. Ở lại điểm tiêm ít nhất 30 phút, theo dõi bé ở nhà ít nhất 24 giờ, chăm đúng cách và biết khi nào cần đi khám.',
        'After vaccines, babies may have a sore, swollen injection site, a mild fever and some fussiness for a few days. Stay at least 30 minutes, watch at home for at least 24 hours, and know when to get help.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Tiêm chủng bảo vệ bé khỏi nhiều bệnh nặng. Phản ứng thường gặp đều nhẹ và tự hết sau vài ngày. Ở lại điểm tiêm ít nhất 30 phút, theo dõi ở nhà ít nhất 24 giờ; không cần cho uống thuốc hạ sốt trước khi tiêm.',
          ),
          h('Hiểu đúng về phản ứng sau tiêm'),
          p(
            'Vắc xin giúp hệ miễn dịch làm quen với mầm bệnh, nên một vài phản ứng nhẹ là bình thường: sưng, đau chỗ tiêm; sốt; mệt, ngủ nhiều; bú kém; nôn hoặc đi ngoài lỏng nhẹ; quấy. Phản ứng nặng như sốc phản vệ rất hiếm (khoảng 1,3 ca trên một triệu liều) và phần lớn xảy ra trong 30 phút đầu, đôi khi muộn hơn vài giờ.',
          ),
          p(
            'Ở Việt Nam: theo lịch tiêm chủng mở rộng, bé được tiêm viêm gan B trong 24 giờ đầu sau sinh, BCG (phòng lao) trong tháng đầu, và vắc xin 5 trong 1 lúc 2, 3, 4 tháng tuổi. Lịch có thể được cập nhật, nên hãy theo sổ tiêm chủng và hướng dẫn của trạm y tế. Ở nước khác, lịch và loại vắc xin khác nhau; hãy theo lịch của nơi bạn sống.',
          ),
          p(
            'Vắc xin BCG có diễn biến riêng: ngay sau tiêm nổi một nốt phồng nhỏ; khoảng 2–6 tuần sau xuất hiện nốt đỏ, có thể mưng mủ hoặc thành vết loét nông, rồi lành sau vài tháng, để lại sẹo nhỏ. Đây là diễn biến mong đợi.',
          ),
          h('Bước 1 · Trước và trong khi tiêm'),
          ul(
            'Mang sổ tiêm chủng. Báo nhân viên y tế nếu bé đang ốm, sốt, có dị ứng, hoặc từng phản ứng mạnh với lần tiêm trước.',
            'Không cho bé uống thuốc hạ sốt, giảm đau trước khi tiêm để “phòng sốt”; WHO không khuyến cáo việc này.',
            'Bế bé trong lòng suốt lúc tiêm. Nếu được, cho bé bú mẹ ngay trước hoặc trong khi tiêm để bé dịu đau (WHO).',
          ),
          h('Bước 2 · Ở lại điểm tiêm ít nhất 30 phút'),
          ul(
            'Ở lại ít nhất 30 phút, kể cả khi bé đã ngủ ngon. Ở Việt Nam đây là quy định của Bộ Y tế; nhiều nước khác khuyên khoảng 15 phút.',
            'Nhìn mặt, môi, nhịp thở và da bé. Nổi mẩn lan nhanh, sưng môi hoặc mặt, thở khò khè, khó thở, tím tái, lả đi: báo nhân viên y tế ngay. Nếu xảy ra khi đã về nhà, gọi 115 và mở mục Sơ cứu trẻ em › Sốc phản vệ trong Child Life.',
          ),
          h('Bước 3 · Chăm bé ở nhà 24–48 giờ đầu'),
          ul(
            'Theo dõi bé ít nhất 24 giờ: toàn trạng, tinh thần, ăn, ngủ, thở, phát ban và chỗ tiêm; nên để ý thêm trong vài ngày sau.',
            'Cho bú mẹ hoặc bú sữa thường xuyên hơn; một số bé bú ít hơn trong khoảng 24 giờ sau tiêm.',
            'Chỗ tiêm sưng, đỏ, đau: đắp khăn sạch, mát, ẩm. Không xoa bóp, day ấn chỗ tiêm.',
            'Bé vẫn được tắm, lau người như bình thường; lau khô nhẹ nhàng chỗ tiêm.',
            'Nếu bé sốt hoặc quấy vì đau: chăm theo bài “Khi bé sốt”. Thuốc hạ sốt chỉ dùng khi bé khó chịu; hỏi bác sĩ hoặc dược sĩ liều theo cân nặng. Không dùng aspirin. Ở Anh: sau mũi vắc xin não mô cầu B (MenB) lúc 8 và 12 tuần, NHS khuyên cho bé uống paracetamol ngay sau tiêm để phòng sốt; nếu bạn sống ở Anh, hãy làm theo tờ hướng dẫn đó.',
          ),
          h('Bước 4 · Chăm vết tiêm BCG'),
          ul(
            'Giữ chỗ tiêm sạch, khô, để hở; không dán băng dính, không bôi kem, thuốc mỡ hay bất cứ thứ gì.',
            'Không nặn, không chích nốt mủ; để vết loét tự đóng vảy và tự bong.',
            'Nếu vết loét chảy dịch, che hờ bằng miếng gạc khô, sạch, thoáng khí.',
            'Báo nơi tiêm nếu vết loét xuất hiện ngay trong 2–3 ngày sau tiêm, hoặc đã 6 tuần mà chỗ tiêm không có phản ứng gì.',
          ),
          h('Theo dõi những gì'),
          ul(
            'Nhiệt độ, giờ đo và thuốc đã dùng.',
            'Vùng sưng đỏ quanh chỗ tiêm to dần hay nhỏ lại.',
            'Tiếng khóc của bé: khóc liên tục không dỗ được từ 3 giờ trở lên là phản ứng ít gặp, cần báo bác sĩ.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            '“Chườm nóng, đắp lá, đắp khoai tây, bôi dầu lên chỗ tiêm cho tan.” Bà thường làm vì thương cháu đau, nhưng đồ đắp không sạch có thể gây nhiễm trùng, dầu nóng làm rát da. Chỉ cần khăn sạch, mát, ẩm; riêng vết BCG thì để khô, không bôi gì.',
            '“Kiêng tắm sau tiêm.” Bé vẫn được tắm như bình thường, chỉ cần lau khô nhẹ chỗ tiêm.',
            '“Cho uống hạ sốt trước cho chắc.” WHO không khuyến cáo cho thuốc giảm đau, hạ sốt trước hoặc lúc tiêm; paracetamol dùng phòng trước có thể làm giảm đáp ứng của một vài loại vắc xin. Chỉ dùng khi bé thật sự sốt, khó chịu.',
          ),
          doctor(
            'Gọi 115 hoặc đến cấp cứu ngay khi',
            'Bé khó thở, thở khò khè hoặc thở rít; sưng môi, mặt, lưỡi; nổi mẩn lan nhanh kèm tím tái, lả đi hoặc li bì; co giật; bé dưới 3 tháng sốt từ 38 °C. Đừng chờ, gọi 115 ngay.',
          ),
          doctor(
            'Đưa bé đi khám trong ngày khi',
            'Bé sốt từ 39 °C; khóc thét, quấy liên tục không dỗ được từ 3 giờ trở lên; bỏ bú, bú kém, ngủ li bì; phát ban; vùng sưng đỏ lan rộng, nóng, đau tăng hoặc chảy mủ (ngoài diễn biến bình thường của vết BCG); phản ứng thông thường kéo dài quá 24 giờ mà không đỡ; hoặc ba mẹ thấy lo.',
          ),
        ],
        en: [
          note(
            'In short',
            "Vaccines protect your baby from many serious diseases. Common reactions are mild and pass within a few days. Stay at the clinic for at least 30 minutes, watch your baby at home for at least 24 hours, and don't give fever medicine before the injection.",
          ),
          h('Understanding vaccine reactions'),
          p(
            'Vaccines help the immune system get to know a germ, so a few mild reactions are normal: a sore or swollen injection site; fever; tiredness or extra sleep; feeding less; some vomiting or loose poo; fussiness. Serious reactions such as anaphylaxis are very rare (about 1.3 per million doses) and mostly happen within the first 30 minutes, occasionally a few hours later.',
          ),
          p(
            'In Việt Nam: under the expanded immunisation programme, babies get hepatitis B in the first 24 hours after birth, BCG (against tuberculosis) in the first month, and the 5-in-1 vaccine at 2, 3 and 4 months. The schedule can change, so follow your baby’s vaccination record and your local health station. Other countries use different schedules and vaccines; follow the schedule where you live.',
          ),
          p(
            'BCG has its own course: a small raised blister right after the injection; about 2–6 weeks later a red spot appears, which may fill with pus or become a shallow sore, then heals over a few months, leaving a small scar. This is the expected course.',
          ),
          h('Step 1 · Before and during the injection'),
          ul(
            'Bring the vaccination record. Tell the health worker if your baby is ill, has a fever, has allergies, or reacted strongly to a previous vaccine.',
            'Don\'t give fever or pain medicine before the injection to "prevent a fever"; WHO does not recommend this.',
            'Hold your baby on your lap throughout. If you can, breastfeed just before or during the injection to ease the pain (WHO).',
          ),
          h('Step 2 · Stay at the clinic for at least 30 minutes'),
          ul(
            'Stay at least 30 minutes, even if your baby has fallen asleep. In Việt Nam this is a Ministry of Health rule; many other countries advise about 15 minutes.',
            "Watch your baby's face, lips, breathing and skin. A fast-spreading rash, swollen lips or face, wheezing, trouble breathing, turning blue or going limp: tell the health worker immediately. If it happens after you get home, call 115 and open Sơ cứu trẻ em (First aid) › Anaphylaxis in Child Life.",
          ),
          h('Step 3 · Care at home in the first 24–48 hours'),
          ul(
            'Watch your baby for at least 24 hours: general condition, alertness, feeding, sleep, breathing, rashes and the injection site; keep an eye on them for a few more days.',
            'Offer breast or formula feeds more often; some babies feed less for about 24 hours after vaccines.',
            "For a swollen, red or sore injection site: hold a clean, cool, damp cloth on it. Don't rub or press on the site.",
            'Your baby can be bathed or washed as usual; pat the injection site dry gently.',
            'If your baby has a fever or is fussy with pain: follow the "When your baby has a fever" article. Only use fever medicine if your baby is uncomfortable; ask a doctor or pharmacist for the dose for their weight. Never give aspirin. In the UK: the NHS advises infant paracetamol right after the MenB jab (8 and 12 weeks); follow its leaflet.',
          ),
          h('Step 4 · Caring for the BCG site'),
          ul(
            "Keep the site clean, dry and uncovered; don't put on a sticking plaster, cream, ointment or anything else.",
            "Don't squeeze or prick the spot; let the sore scab over and the scab fall off by itself.",
            'If the sore is weeping, cover it loosely with a clean, dry gauze that lets air through.',
            'Tell the clinic if a sore appears within 2–3 days of the injection, or if there is no reaction at the site after 6 weeks.',
          ),
          h('What to watch'),
          ul(
            'Temperature, the time you measured it and any medicine given.',
            'Whether the red, swollen area around the injection site is getting bigger or smaller.',
            "Your baby's crying: non-stop crying that you can't soothe for 3 hours or more is an uncommon reaction that you should report to a doctor.",
          ),
          h('Common misconceptions'),
          ul(
            '"Hot compresses, leaves, potato slices or medicated oil on the injection site to make it go down." Grandmothers often do this because they hate to see the baby in pain, but unclean poultices can cause infection and hot oils sting the skin. A clean, cool, damp cloth is all you need; for BCG, keep it dry and put nothing on it.',
            '"No bathing after vaccines." Your baby can be bathed as usual; just pat the injection site dry gently.',
            '"Give fever medicine beforehand, just in case." WHO does not recommend pain or fever medicine before or at the time of vaccination; paracetamol given in advance may weaken the response to some vaccines. Only use it if your baby actually has a fever or is uncomfortable.',
          ),
          doctor(
            'Call 115 or go to the emergency department now if',
            'Your baby has trouble breathing, wheezing or noisy breathing; swelling of the lips, face or tongue; a fast-spreading rash with blue colour, going limp or very drowsy; a fit; or is under 3 months with 38 °C or more. (115 is the emergency number in Vietnam.)',
          ),
          doctor(
            'See a doctor the same day if',
            "Your baby has a fever of 39 °C or more; cries or fusses non-stop and can't be soothed for 3 hours or more; refuses feeds, feeds poorly or is very sleepy; has a rash; the redness spreads, feels hot, gets more painful or oozes pus (beyond the normal course of BCG); usual reactions last more than 24 hours without improving; or you are worried.",
          ),
        ],
      },
      keywords: t(
        [
          'tiêm chủng',
          'vắc xin',
          'sau tiêm',
          'sốt sau tiêm',
          'BCG',
          'sốc phản vệ',
          'chỗ tiêm sưng',
          'tiêm chủng mở rộng',
        ],
        [
          'vaccination',
          'vaccine',
          'after vaccines',
          'fever after vaccines',
          'BCG',
          'anaphylaxis',
          'swollen injection site',
          'immunisation programme',
        ],
      ),
      relatedArticleIds: ['art_fever_when_to_call', 'art_crying_colic', 'art_breastfeeding_start'],
      milestoneIds: [],
      sources: [
        S.byt13TiemChung2026,
        S.vinmecEpiUnder1,
        S.nhsSixInOneSideEffects,
        {
          label: 'UKHSA (GOV.UK) — MenB vaccine and paracetamol',
          url: 'https://www.gov.uk/government/publications/menb-vaccine-and-paracetamol',
        },
        S.cdcDtapVis,
        S.whoPainAtVaccination,
        S.nswBcgVietnamese,
        S.phacAnaphylaxisCig,
      ],
    },
  },
  {
    id: 'art_constipation',
    reviewerLabel: PAEDS,
    data: {
      library: 'care',
      topic: 'illness',
      format: 'article',
      ageWeeks: { from: 0, to: 104 },
      readingMinutes: 5,
      cover: null,
      title: t(
        'Táo bón ở trẻ nhỏ: khi nào bình thường, khi nào cần khám',
        'Constipation in babies and toddlers: what is normal and when to get help',
      ),
      summary: t(
        'Bé bú mẹ có thể vài ngày mới đi ngoài một lần mà vẫn bình thường. Táo bón thật là phân cứng, khô, đi đau. Pha sữa đúng tỉ lệ, ăn đủ chất xơ, và không tự thụt hay nhét gì vào hậu môn bé.',
        "A breastfed baby can go several days without a poo and still be fine. Real constipation means hard, dry, painful poos. Make formula correctly, offer fibre, and never put anything into your baby's bottom yourself.",
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Số lần đi ngoài không quan trọng bằng độ mềm của phân và việc bé có khỏe, lên cân không. Rặn đỏ mặt mà phân vẫn mềm là bình thường. Táo bón thật cần được xử lý đúng: chỉnh cách pha sữa, ăn uống, và khi cần thì dùng thuốc theo chỉ định bác sĩ.',
          ),
          h('Hiểu đúng về táo bón'),
          p(
            'Số lần đi ngoài của bé thay đổi rất nhiều. Trong tháng đầu, bé bú mẹ thường đi nhiều lần mỗi ngày; đi ít hơn một lần mỗi ngày có thể là dấu hiệu bé bú chưa đủ (AAP). Sau khoảng 6 tuần, bé bú mẹ hoàn toàn có thể vài ngày, thậm chí một tuần mới đi một lần mà vẫn bình thường, nếu phân mềm và bé bú tốt, lên cân. Bé bú sữa công thức thường đi gần như mỗi ngày, có khi cách 1–2 ngày.',
          ),
          p(
            'Bé nhỏ hay rặn, đỏ mặt, thậm chí khóc khi đi ngoài. Nếu phân ra vẫn mềm, đó là bé đang tập phối hợp giữa rặn và thả lỏng cơ hậu môn, không phải táo bón.',
          ),
          p(
            'Táo bón thật là khi phân cứng, khô, vón cục hoặc lổn nhổn như phân dê; bé đi ít hơn 3 lần mỗi tuần (trừ bé bú mẹ hoàn toàn sau 6 tuần tuổi); bé rặn đau, có thể có vệt máu do nứt hậu môn. Táo bón hay gặp khi bé đổi sữa, bắt đầu ăn dặm, uống ít nước, bị ốm hoặc lúc tập ngồi bô.',
          ),
          h('Ba mẹ có thể làm gì'),
          h('Bé dưới 6 tháng'),
          ul(
            'Bé bú mẹ: tiếp tục cho bú theo nhu cầu, cho bú nhiều cữ hơn; bé bú mẹ hoàn toàn không cần uống thêm nước.',
            'Bé bú sữa công thức: pha đúng lượng bột và nước ghi trên hộp, dùng muỗng đi kèm; thừa bột có thể gây táo bón và mất nước. NHS gợi ý có thể cho bé uống thêm ít nước đun sôi để nguội giữa vài cữ; hãy hỏi bác sĩ trước.',
            'Nhẹ nhàng co duỗi chân bé như đạp xe, hoặc xoa bụng khi bé đang thoải mái.',
            'Không tự cho uống nước ép, nước rau hay thuốc. AAP có nhắc đến một lượng nhỏ nước ép lê, táo cho bé trên 1 tháng bị táo bón, nhưng cũng không khuyên trẻ dưới 1 tuổi uống nước ép; chỉ dùng khi bác sĩ khuyên.',
          ),
          h('Bé từ 6 tháng đến 2 tuổi'),
          ul(
            'Cho ăn nhiều rau và trái cây giàu chất xơ trong bữa ăn dặm, như mận khô, lê, đu đủ chín, khoai lang, các loại đậu, ngũ cốc nguyên hạt.',
            'Bé 6–12 tháng: cho uống nước lọc bằng cốc, khoảng 120–240 ml mỗi ngày (AAP).',
            'Bé 12–24 tháng: sữa tươi nguyên kem khoảng 2 cốc (khoảng 480 ml) mỗi ngày là đủ; uống quá nhiều sữa có thể khiến bé ít ăn rau, trái cây. Cho uống thêm nước lọc.',
            'Bé tập ngồi bô: cho ngồi sau bữa ăn, chân chạm sàn hoặc bệ kê; khen bé dù có đi hay không, không la mắng.',
            'Cho bé vận động, bò, đi, chơi nhiều trong ngày.',
          ),
          tip(
            'Nếu bác sĩ kê thuốc',
            'Khi bé đã táo bón thật, NICE cho rằng chỉ thay đổi ăn uống thường chưa đủ. Bác sĩ có thể kê thuốc làm mềm phân phù hợp lứa tuổi, đôi khi cần dùng vài tháng. Dùng đúng liều và không tự ngưng đột ngột.',
          ),
          h('Theo dõi những gì'),
          ul(
            'Số lần đi ngoài mỗi tuần và hình dạng phân: mềm, cứng, vón cục.',
            'Bé có đau, rặn trên 10 phút mà không ra, có vệt máu trên phân không.',
            'Bé có bú, ăn tốt, tăng cân đều không; bụng có chướng, bé có nôn không.',
            'Những thay đổi gần đây: đổi sữa, bắt đầu ăn dặm, ốm, đi nhà trẻ, tập ngồi bô.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            '“Nhét que, mẩu xà phòng, cuống lá mồng tơi, cuống rau muống vào hậu môn cho bé đi.” Ông bà làm vì muốn bé đỡ khó chịu ngay, nhưng việc này có thể làm trầy, rách hậu môn và gây nhiễm trùng; bé càng đau càng sợ đi ngoài. Không đưa bất cứ vật gì vào hậu môn bé.',
            '“Thụt nước xà phòng cho nhanh.” Xà phòng có thể gây kích ứng, tổn thương niêm mạc ruột. Thụt hay thuốc đặt chỉ dùng khi bác sĩ chỉ định; ngay cả khi táo bón nặng, NICE vẫn ưu tiên thuốc uống.',
            '“Pha sữa đặc cho con chắc bụng.” Thừa bột làm bé táo bón và mất nước. Pha đúng tỉ lệ ghi trên hộp.',
            '“Cho uống nước rau ngót, nước cam từ khi bé vài tuần tuổi.” Bé dưới 6 tháng chỉ cần sữa mẹ hoặc sữa công thức; nước rau có thể làm bé bú ít đi. Hỏi bác sĩ nếu bé táo bón.',
            '“Vài ngày không đi là phải dùng thuốc.” Nếu bé bú mẹ, phân mềm, bé vui vẻ và lên cân, chưa cần làm gì.',
          ),
          doctor(
            'Gọi 115 hoặc đến cấp cứu ngay khi',
            'Bé nôn ra dịch xanh lá; bụng chướng căng kèm nôn; đau bụng dữ dội; li bì, khó đánh thức; đi ngoài ra nhiều máu. Đừng chờ, gọi 115 ngay.',
          ),
          doctor(
            'Đưa bé đi khám sớm khi',
            'Bé đủ tháng chưa đi phân su trong 48 giờ đầu; bé dưới 8 tuần chưa đi ngoài 2–3 ngày; táo bón ngay từ những tuần đầu đời; phân nhỏ dẹt như sợi ruy băng; bé chậm tăng cân, bú kém; có vệt máu trên phân; táo bón không đỡ sau vài ngày điều chỉnh ăn uống.',
          ),
        ],
        en: [
          note(
            'In short',
            'How often your baby poos matters less than how soft the poo is and whether your baby is well and gaining weight. Straining and going red with a soft poo is normal. Real constipation needs the right care: checking how formula is made, adjusting food and drinks, and, when needed, medicine prescribed by a doctor.',
          ),
          h('Understanding constipation'),
          p(
            "How often babies poo varies a lot. In the first month, breastfed babies usually poo several times a day; less than once a day may mean your baby isn't getting enough milk (AAP). After about 6 weeks, exclusively breastfed babies can go several days or even a week between poos and still be fine, as long as the poo is soft and they feed well and gain weight. Formula-fed babies usually poo most days, sometimes with 1–2 days in between.",
          ),
          p(
            "Young babies often strain, go red in the face and even cry when pooing. If the poo that comes out is soft, your baby is learning to push and relax the bottom muscles at the same time; it isn't constipation.",
          ),
          p(
            'Real constipation means hard, dry, lumpy poos or small pellets like rabbit droppings; fewer than 3 poos a week (except exclusively breastfed babies after 6 weeks); painful straining, sometimes with streaks of blood from a small tear. It often starts with a change of milk, starting solids, not drinking enough, an illness, or potty training.',
          ),
          h('What you can do'),
          h('Under 6 months'),
          ul(
            'Breastfed babies: keep feeding on demand and offer more feeds; exclusively breastfed babies do not need extra water.',
            'Formula-fed babies: use exactly the amount of powder and water on the tin, with the scoop provided; too much powder can cause constipation and dehydration. The NHS suggests offering a little cooled boiled water between some feeds; ask a doctor first.',
            "Gently move your baby's legs in a cycling motion, or massage their tummy while they are relaxed.",
            "Don't give juice, vegetable water or medicines on your own. The AAP mentions a small amount of pear or apple juice for constipated babies over 1 month, but also advises no juice under 1 year; only use it if a doctor recommends it.",
          ),
          h('From 6 months to 2 years'),
          ul(
            'Offer plenty of fibre-rich fruit and vegetables at mealtimes, such as prunes, pears, ripe papaya, sweet potato, beans and lentils, and wholegrains.',
            '6–12 months: offer water from a cup, about 120–240 ml a day (AAP).',
            "12–24 months: about 2 cups (around 480 ml) of whole cow's milk a day is enough; too much milk can leave less room for fruit and vegetables. Offer water as well.",
            'Potty training: have your child sit after meals with their feet flat on the floor or a step; praise them whether or not they poo, and never scold.',
            'Help your child move, crawl, walk and play a lot each day.',
          ),
          tip(
            'If the doctor prescribes medicine',
            "Once a child is truly constipated, NICE says diet changes alone are usually not enough. A doctor may prescribe a stool softener suitable for your child's age, sometimes for several months. Give the right dose and don't stop suddenly.",
          ),
          h('What to watch'),
          ul(
            'How many poos a week and what they look like: soft, hard or lumpy.',
            'Whether your baby is in pain, strains for more than 10 minutes without success, or has blood streaks on the poo.',
            'Whether your baby feeds and eats well and gains weight steadily; whether the tummy is swollen or they are vomiting.',
            'Recent changes: new milk, starting solids, illness, starting nursery, potty training.',
          ),
          h('Common misconceptions'),
          ul(
            '"Put a stick, a sliver of soap or a vegetable stalk into the bottom to get things moving." Grandparents do this to ease the baby straight away, but it can scratch or tear the bottom and cause infection; the more it hurts, the more your baby fears pooing. Never put anything into your baby\'s bottom.',
            '"A soapy-water enema works fast." Soap can irritate and damage the lining of the bowel. Enemas and suppositories are only for when a doctor prescribes them; even for severe constipation, NICE prefers medicine by mouth first.',
            '"Make formula thicker so the baby feels full." Too much powder causes constipation and dehydration. Follow the ratio on the tin.',
            '"Give leafy-green water or orange juice from a few weeks old." Babies under 6 months only need breast milk or formula; vegetable water can make them feed less. Ask a doctor if your baby is constipated.',
            '"A few days without a poo means medicine." If your baby is breastfed, the poo is soft, and they are happy and gaining weight, nothing needs to be done.',
          ),
          doctor(
            'Call 115 or go to the emergency department now if',
            'Your baby vomits green fluid; has a tight, swollen tummy with vomiting; has severe tummy pain; is very drowsy or hard to wake; or passes a lot of blood. (115 is the emergency number in Vietnam.)',
          ),
          doctor(
            'See a doctor soon if',
            'A term baby has not passed meconium (the first poo) within 48 hours of birth; a baby under 8 weeks has not pooed for 2–3 days; constipation started in the first weeks of life; the poo is thin like a ribbon; your baby is gaining weight slowly or feeding poorly; there are blood streaks on the poo; or constipation does not improve after a few days of diet changes.',
          ),
        ],
      },
      keywords: t(
        [
          'táo bón',
          'đi ngoài',
          'phân cứng',
          'rặn',
          'pha sữa',
          'chất xơ',
          'mận khô',
          'thụt hậu môn',
          'phân su',
          'ngồi bô',
        ],
        [
          'constipation',
          'pooing',
          'hard poo',
          'straining',
          'making formula',
          'fibre',
          'prunes',
          'enema',
          'meconium',
          'potty training',
        ],
      ),
      relatedArticleIds: [
        'art_formula_bottle',
        'art_solids_readiness',
        'art_solids_textures_by_month',
        'art_water_juice',
      ],
      milestoneIds: [],
      sources: [
        S.niceConstipationCg99,
        S.nhsConstipationChildren,
        S.nhsBottleConstipation,
        S.hcInfantConstipation,
        S.hcRecommendedDrinks,
      ],
    },
  },

  // ----- Chăm hằng ngày & răng miệng (daily care, teeth) -----
  {
    id: 'art_bathing_at_home',
    reviewerLabel: NURSING,
    data: {
      library: 'care',
      topic: 'daily_care',
      format: 'step_guide',
      ageWeeks: { from: 0, to: 52 },
      readingMinutes: 6,
      cover: null,
      title: t(
        'Tắm cho bé tại nhà: an toàn, nhẹ nhàng, từng bước',
        'Bathing your baby at home: safe, gentle, step by step',
      ),
      summary: t(
        'Bé không cần tắm lâu hay kỳ cọ mới sạch. Nước ấm vừa, đồ dùng để sẵn, tắm nhanh gọn và không rời mắt khỏi bé dù chỉ một giây là những điều quan trọng nhất.',
        "Your baby doesn't need long baths or scrubbing to be clean. Warm (not hot) water, everything ready, a quick bath and never taking your eyes off your baby, even for a second, matter most.",
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Trong năm đầu, tắm 2–3 lần mỗi tuần là đủ cho da bé; trời nóng ẩm, ba mẹ có thể tắm nhanh hoặc lau rửa cho bé hằng ngày. Nước ấm vừa (khoảng 37–38 °C), tắm 5–10 phút, dùng nước sạch hoặc sữa tắm dịu nhẹ không mùi. Luôn giữ một tay trên người bé: bé có thể đuối nước chỉ trong vài phân nước.',
          ),
          h('Hiểu đúng về tắm cho bé'),
          p(
            'Da bé mỏng và dễ mất nước. Tắm quá lâu, nước quá nóng hay dùng nhiều xà phòng dễ làm da khô, nứt và ngứa. Vì vậy mục tiêu của buổi tắm là sạch vừa đủ, giữ ấm và an toàn, không phải kỳ cọ thật kỹ.',
          ),
          p(
            'Tổ chức Y tế Thế giới (WHO) khuyên chờ ít nhất 24 giờ sau sinh mới tắm lần đầu để bé giữ được thân nhiệt. Về số lần tắm, các hướng dẫn hơi khác nhau: Viện Hàn lâm Nhi khoa Hoa Kỳ (AAP) cho rằng khoảng 3 lần mỗi tuần trong năm đầu có thể là đủ, trang thông tin sức khoẻ của Chính phủ Úc nói 2–3 lần, còn NHS (Anh) nói bé không cần tắm mỗi ngày. Ở Việt Nam trời nóng ẩm, bé đổ mồ hôi nhiều, ba mẹ có thể tắm nhanh cho bé hằng ngày, miễn là nước ấm vừa, thời gian ngắn và dưỡng ẩm nếu da khô. Ngày không tắm, chỉ cần lau mặt, cổ, nách, tay và vùng tã.',
          ),
          p(
            'Trước khi cuống rốn rụng (thường trong 1–2 tuần đầu), AAP khuyên chỉ lau người bằng khăn ấm thay vì ngâm bé trong chậu. Cách chăm rốn có trong bài Chăm rốn sơ sinh.',
          ),
          h('Ba mẹ có thể làm gì'),
          h('Bước 1 · Chuẩn bị trước khi bế bé'),
          ul(
            'Chọn lúc bé tỉnh táo, vui vẻ; tránh ngay sau cữ bú hoặc khi bé đang đói, buồn ngủ.',
            'Phòng ấm, không có gió lùa: tắt quạt hoặc điều hoà thổi thẳng vào bé, khép cửa sổ, nhưng không cần đóng kín bít.',
            'Để sẵn trong tầm tay: khăn mềm, tã, quần áo sạch, bông gòn, khăn lau mặt, sữa tắm (nếu dùng) và kem dưỡng không mùi.',
            'Dùng chậu tắm riêng của bé, đặt chắc chắn. Không coi ghế tắm hay phao tắm là dụng cụ an toàn: chúng có thể lật hoặc tuột khỏi chậu.',
            'Nếu nhà dùng bình nóng lạnh, AAP khuyên đặt nhiệt độ nước nóng tối đa khoảng 49 °C để giảm nguy cơ bỏng.',
          ),
          h('Bước 2 · Pha và thử nước'),
          p(
            'Cho nước lạnh vào trước rồi mới thêm nước nóng, khuấy đều để không còn chỗ nóng. Thử bằng khuỷu tay hoặc mặt trong cổ tay: nước phải ấm, không nóng. Nếu có nhiệt kế đo nước, khoảng 37–38 °C là vừa. Với bé sơ sinh, mực nước khoảng 5 cm là đủ. Không tắm bé dưới vòi nước đang chảy.',
          ),
          h('Bước 3 · Tắm nhẹ nhàng, nhanh gọn'),
          ul(
            'Lau mặt trước bằng bông gòn nhúng nước ấm; mỗi mắt dùng một miếng bông mới, lau từ khoé trong ra ngoài.',
            'Chỉ lau vành tai và sau tai; không ngoáy tăm bông vào trong tai hay lỗ mũi.',
            'Một tay đỡ đầu, cổ và vai bé, tay kia nhẹ nhàng đặt bé vào nước, chân xuống trước; đầu bé luôn ở trên mặt nước.',
            'Rửa cổ, nách, tay, ngực, chân và các nếp gấp; vùng tã rửa sau cùng. Không cần kỳ cọ.',
            'Gội đầu 2–3 lần mỗi tuần là đủ, dùng thật ít dầu gội hoặc sữa tắm dịu nhẹ rồi tráng sạch.',
            'Cả buổi tắm chỉ nên khoảng 5–10 phút để bé không bị lạnh và da không bị khô.',
          ),
          h('Bước 4 · Lau khô, dưỡng da, mặc đồ'),
          p(
            'Bế bé ra, quấn ngay vào khăn và thấm khô nhẹ nhàng, nhất là các nếp ở cổ, nách, bẹn và sau tai. Nếu da khô, thoa một lớp mỏng kem dưỡng không mùi. Mặc tã, quần áo cho bé rồi đổ nước trong chậu đi ngay.',
          ),
          h('Bước 5 · Cắt móng tay'),
          p(
            'Móng bé mọc nhanh và sắc, dễ cào xước mặt. Cắt bằng kéo đầu tròn hoặc bấm móng dành cho trẻ nhỏ, hoặc dũa nhẹ, vào lúc bé ngủ hay đang thư thái.',
          ),
          note(
            'Không bao giờ để bé một mình trong nước',
            'Kể cả một giây để nghe điện thoại hay lấy khăn. Bé có thể đuối nước chỉ trong vài phân nước mà không phát ra tiếng động. Nếu phải rời đi, quấn khăn và bế bé theo. Không giao bé cho anh chị nhỏ trông lúc tắm.',
          ),
          h('Theo dõi'),
          ul(
            'Da: khô, bong vảy, mẩn đỏ, nứt hay rỉ dịch sau khi tắm (xem bài Chàm và da khô).',
            'Rốn: còn ướt lâu, đỏ lan ra da bụng, có mủ hay mùi hôi.',
            'Bé run, tím môi hoặc khóc nhiều mỗi lần tắm: rút ngắn thời gian, làm ấm phòng, chuẩn bị đồ kỹ hơn.',
            'Vùng tã đỏ, rát: xem bài Hăm tã.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            '“Trong tháng phải kiêng tắm, ốm cũng phải kiêng.” Ông bà lo cháu nhiễm lạnh là có lý, nhưng lâu ngày không tắm thì mồ hôi, sữa trớ, phân đọng lại, bé dễ hăm và nổi mẩn. Nên tắm nhanh bằng nước ấm trong phòng kín gió và lau khô ngay; khi bé ốm, lau người bằng khăn ấm hoặc tắm thật nhanh.',
            '“Tắm nước lá chè xanh, lá khế, lá trầu không cho sạch rôm, sạch mẩn.” Nước lá không vô khuẩn, khó biết đậm nhạt, có thể gây kích ứng hoặc dị ứng da, và nước lá đun để nguội chưa đủ dễ gây bỏng. Nên dùng nước sạch ấm; nếu bé có mẩn, hãy để bác sĩ xem.',
            '“Xoa rượu gừng, dầu gió cho ấm người sau khi tắm.” Cồn làm khô và xót làn da mỏng của bé; một số dầu xoa có long não (camphor) đã gây co giật ở trẻ nhỏ, kể cả khi chỉ xoa nhiều lần lên da. Nên lau khô, mặc ấm vừa đủ và dùng kem dưỡng không mùi.',
            '“Bôi phấn rôm cho khô da, đỡ rôm sảy.” AAP khuyên không dùng phấn rôm cho bé vì bột hít phải có thể gây tổn thương phổi nặng. Nên thấm khô kỹ các nếp da và cho bé mặc đồ cotton mỏng, thoáng.',
            '“Cạo lông mày, cắt lông mi cho bé để sau này mọc dày.” Cạo hay cắt không làm sợi lông mọc dày hơn, còn dao kéo sát mắt bé rất dễ gây tai nạn. Hãy để lông mày, lông mi phát triển tự nhiên.',
          ),
          doctor(
            'Gọi 115 hoặc đến cấp cứu ngay khi',
            'Bé bị sặc nước, ngừng thở, tím tái hay lả đi sau khi trượt xuống nước; bé bị bỏng nước nóng rộng, sâu, phồng rộp lớn hoặc ở mặt, tay, bộ phận sinh dục. Trong lúc chờ, làm theo mục Sơ cứu trẻ em của Child Life (Hồi sức tim phổi, Bỏng nước sôi).',
          ),
          doctor(
            'Đưa bé đi khám sớm (trong ngày) khi',
            'Bé dưới 3 tháng có nhiệt độ từ 38 °C trở lên; da quanh rốn đỏ lan, sưng, có mủ hay mùi hôi; da nổi mẩn lan rộng, nứt, rỉ dịch hay đóng vảy vàng; vết bỏng nhỏ nhưng phồng rộp.',
          ),
        ],
        en: [
          note(
            'In short',
            "In the first year, 2–3 baths a week are enough for your baby's skin; in hot, humid weather you can give a quick bath or a wash every day. Use warm water (about 37–38 °C), keep it to 5–10 minutes, with plain water or a mild fragrance-free wash. Always keep a hand on your baby: babies can drown in a few centimetres of water.",
          ),
          h('Understanding bath time'),
          p(
            'Baby skin is thin and loses moisture easily. Long baths, hot water or lots of soap can leave it dry, cracked and itchy. So the aim of a bath is to be clean enough, warm and safe, not scrubbed spotless.',
          ),
          p(
            "The World Health Organization (WHO) advises waiting at least 24 hours after birth before the first bath, so your baby can keep warm. Advice on how often differs a little: the American Academy of Pediatrics (AAP) says about 3 baths a week in the first year may be enough, Australian government advice says 2–3, and the NHS (UK) says babies don't need a bath every day. In Vietnam's hot, humid climate babies sweat a lot, so a quick daily bath is fine as long as the water is warm (not hot), the bath is short and you moisturise if the skin is dry. On other days, just wash the face, neck, armpits, hands and diaper area.",
          ),
          p(
            'Until the umbilical cord stump falls off (usually within the first 1–2 weeks), the AAP advises sponge baths with a warm cloth instead of putting your baby in the tub. Cord care is covered in Umbilical cord care.',
          ),
          h('What you can do'),
          h('Step 1 · Get ready before you pick your baby up'),
          ul(
            'Choose a time when your baby is awake and content; avoid straight after a feed or when they are hungry or sleepy.',
            "A warm room with no draughts: turn off fans or air conditioning blowing at your baby and close the windows, but the room doesn't need to be sealed shut.",
            'Have everything within reach: soft towel, diaper, clean clothes, cotton wool, a face cloth, baby wash (if using) and a fragrance-free moisturiser.',
            "Use your baby's own bath, set firmly in place. Don't rely on bath seats or rings for safety: they can tip over or come away from the bath.",
            'If your home has a water heater, the AAP advises setting the hot water to no more than about 49 °C to lower the risk of scalds.',
          ),
          h('Step 2 · Run and test the water'),
          p(
            'Put the cold water in first, then add hot, and mix well so there are no hot spots. Test with your elbow or the inside of your wrist: it should feel warm, not hot. With a bath thermometer, about 37–38 °C is right. For a newborn, about 5 cm of water is enough. Never bathe your baby under running water.',
          ),
          h('Step 3 · Wash gently and quickly'),
          ul(
            'Wipe the face first with cotton wool dipped in warm water; use a fresh piece for each eye and wipe from the inner corner outwards.',
            'Clean only the outer ear and behind the ears; never put cotton buds inside the ears or nostrils.',
            "Support your baby's head, neck and shoulders with one hand and gently lower them into the water feet first with the other; keep their head above the water at all times.",
            'Wash the neck, armpits, arms, chest, legs and skin folds; wash the diaper area last. No need to scrub.',
            'Washing the hair 2–3 times a week is enough, with very little mild shampoo or baby wash, rinsed off well.',
            "The whole bath should take about 5–10 minutes so your baby doesn't get cold and the skin doesn't dry out.",
          ),
          h('Step 4 · Dry, moisturise, dress'),
          p(
            'Lift your baby out, wrap them straight away in the towel and pat dry gently, especially the creases at the neck, armpits, groin and behind the ears. If the skin is dry, apply a thin layer of fragrance-free moisturiser. Put on the diaper and clothes, then empty the bath straight away.',
          ),
          h('Step 5 · Trim the nails'),
          p(
            'Baby nails grow fast and are sharp enough to scratch the face. Use round-ended baby scissors or baby nail clippers, or file gently, while your baby is asleep or relaxed.',
          ),
          note(
            'Never leave your baby alone in water',
            'Not even for a second to answer the phone or grab a towel. Babies can drown in a few centimetres of water without making a sound. If you have to leave, wrap your baby in the towel and take them with you. Never leave an older child in charge at bath time.',
          ),
          h('What to watch'),
          ul(
            'Skin: dryness, flaking, red patches, cracks or weeping after baths (see Eczema and dry skin).',
            'Belly button: staying moist, redness spreading onto the tummy, pus or a bad smell.',
            'Shivering, blue lips or a lot of crying at every bath: shorten the bath, warm the room and get things ready beforehand.',
            'A red, sore diaper area: see Diaper rash.',
          ),
          h('Common misconceptions'),
          ul(
            '“No baths in the first month, or when the baby is ill.” Grandparents are right to worry about a chill, but without washing, sweat, spilled milk and stool build up and babies get rashes more easily. Give a quick bath in warm water in a draught-free room and dry straight away; when your baby is ill, sponge with a warm cloth or keep the bath very short.',
            "“Bathe in leaf water (green tea, star fruit or betel leaves) to clear heat rash.” Leaf water isn't sterile, its strength is hard to judge, it can irritate the skin or trigger allergy, and boiled leaf water that hasn't cooled enough can scald. Use clean warm water, and have a doctor look at any rash.",
            '“Rub on ginger wine or medicated oil to warm the baby after a bath.” Alcohol dries and stings thin baby skin, and some rubbing oils contain camphor, which has caused seizures in young children even when only rubbed on the skin repeatedly. Dry your baby well, dress them warmly enough and use a fragrance-free moisturiser.',
            '“Use baby powder to keep the skin dry and stop heat rash.” The AAP advises against baby or talcum powder because inhaled powder can seriously damage the lungs. Pat skin folds dry and dress your baby in thin, breathable cotton.',
            "“Shave the eyebrows or trim the eyelashes so they grow back thicker.” Shaving or cutting doesn't make hair grow back thicker, and blades near the eyes can easily cause injury. Let eyebrows and eyelashes grow naturally.",
          ),
          doctor(
            'Call 115 or go to the emergency department now if',
            'Your baby has inhaled water, stops breathing, turns blue or goes limp after slipping under; or has a scald that is large, deep, with big blisters, or on the face, hands or genitals. While you wait, follow the Sơ cứu trẻ em (First aid) guide in Child Life (CPR, Scald).',
          ),
          doctor(
            'See a doctor the same day if',
            'Your baby is under 3 months with a temperature of 38 °C or higher; the skin around the belly button is red and spreading, swollen, has pus or smells bad; a rash is spreading, cracked, weeping or has yellow crusts; or a small burn has blistered.',
          ),
        ],
      },
      keywords: t(
        [
          'tắm bé',
          'nhiệt độ nước tắm',
          'lau người',
          'kiêng tắm',
          'phấn rôm',
          'cắt móng tay',
          'đuối nước',
          'tắm nước lá',
        ],
        [
          'baby bath',
          'bath water temperature',
          'sponge bath',
          'bathing taboo',
          'baby powder',
          'nail trimming',
          'drowning',
          'leaf bath',
        ],
      ),
      relatedArticleIds: [
        'art_umbilical_cord',
        'art_eczema_dry_skin',
        'art_diaper_rash',
        'art_home_safety_falls',
      ],
      milestoneIds: [],
      sources: [
        S.eHcBathingNewborn,
        S.eNhsWashingBathing,
        S.eWhoPostnatal2013,
        S.ePbbBathingNewborn,
        S.eHcBabyRoomSafe,
        S.eAadEczemaBabies,
        S.eCcShavingThicker,
      ],
    },
  },
  {
    id: 'art_umbilical_cord',
    reviewerLabel: NURSING,
    data: {
      library: 'care',
      topic: 'daily_care',
      format: 'step_guide',
      ageWeeks: { from: 0, to: 5 },
      readingMinutes: 5,
      cover: null,
      title: t(
        'Chăm rốn sơ sinh: giữ sạch, giữ khô, chờ rốn tự rụng',
        'Umbilical cord care: keep it clean and dry, let it fall off',
      ),
      summary: t(
        'Cuống rốn thường tự rụng trong khoảng 5–15 ngày. Chỉ cần giữ rốn sạch, khô, không bôi đắp gì, và biết những dấu hiệu nhiễm trùng cần đưa bé đi khám ngay.',
        'The cord stump usually falls off by itself within about 5–15 days. Keep it clean and dry, put nothing on it, and know the signs of infection that need a doctor straight away.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Với bé sinh ở cơ sở y tế, WHO khuyến nghị giữ rốn sạch và khô, không bôi đắp gì. Cuống rốn thường tự rụng trong khoảng 5–15 ngày. Da quanh rốn đỏ lan, có mủ, mùi hôi, hoặc bé sốt, bú kém, li bì là lý do đưa bé đi khám ngay.',
          ),
          h('Hiểu đúng về cuống rốn'),
          p(
            'Sau khi dây rốn được kẹp và cắt, phần cuống còn lại sẽ khô dần, chuyển sang màu nâu sẫm rồi tự bong. Theo MedlinePlus (Thư viện Y khoa Quốc gia Hoa Kỳ), việc này thường xảy ra trong khoảng 5–15 ngày; AAP cho biết cuống rốn nên rụng trước khi bé được 3 tuần tuổi. Giữ rốn khô, thoáng giúp quá trình này diễn ra thuận lợi; ẩm ướt và bẩn làm tăng nguy cơ nhiễm khuẩn.',
          ),
          p(
            'Lúc rốn rụng, có thể thấy vài giọt máu dính trên tã, điều này thường là bình thường. Đôi khi ở chân rốn còn một cục thịt nhỏ màu hồng, ẩm, rỉ dịch vàng nhạt, gọi là u hạt rốn; nhiều trường hợp tự hết trong khoảng một tuần, nếu không bác sĩ sẽ xử lý đơn giản tại phòng khám.',
          ),
          p(
            'Về thuốc sát khuẩn: WHO khuyến nghị chăm rốn khô, sạch cho bé sinh ở cơ sở y tế và ở nơi tỷ lệ tử vong sơ sinh thấp. Dung dịch chlorhexidine 7,1% chỉ được WHO khuyên bôi hằng ngày trong tuần đầu cho bé sinh tại nhà ở nơi tử vong sơ sinh cao. AAP cũng cho biết không cần bôi cồn. Nếu nơi sinh dặn khác, hãy làm theo nhân viên y tế đã khám cho bé.',
          ),
          h('Ba mẹ có thể làm gì'),
          h('Bước 1 · Rửa tay trước khi chạm vào rốn'),
          p(
            'Rửa tay bằng xà phòng và nước sạch trước khi thay tã hay chạm vào vùng rốn. Ông bà và người chăm bé cũng vậy.',
          ),
          h('Bước 2 · Giữ rốn khô, thoáng'),
          ul(
            'Gấp mép trên của tã xuống dưới cuống rốn để nước tiểu không thấm lên và rốn được thoáng.',
            'Mặc áo cotton rộng; không quấn chặt bụng, không băng kín hay dùng đai rốn.',
            'Cho đến khi rốn rụng, lau người cho bé bằng khăn ấm thay vì ngâm bé trong chậu.',
          ),
          h('Bước 3 · Lau sạch khi rốn bị bẩn'),
          p(
            'Chỉ cần lau khi rốn dính nước tiểu hoặc phân: dùng bông gòn hoặc gạc sạch nhúng nước ấm, lau nhẹ quanh chân rốn rồi thấm khô. Không cần bôi cồn, thuốc đỏ, nghệ hay rắc bột gì lên rốn.',
          ),
          h('Bước 4 · Để rốn tự rụng'),
          p(
            'Không kéo, giật hay cắt cuống rốn, kể cả khi chỉ còn dính một chút. Sau khi rụng, tiếp tục giữ chân rốn sạch và khô cho đến khi lành hẳn.',
          ),
          h('Theo dõi'),
          ul(
            'Mỗi lần thay tã, nhìn chân rốn: da quanh rốn có đỏ, sưng, có mủ hay mùi hôi không.',
            'Bé bú có tốt không; có li bì, ít cử động hay người mềm hơn bình thường không.',
            'Đo nhiệt độ khi bé có vẻ nóng hoặc lạnh bất thường (xem Đo thân nhiệt trong mục Sơ cứu trẻ em của Child Life).',
            'Ngày cuống rốn rụng. AAP dùng mốc 3 tuần, MedlinePlus dùng mốc 4 tuần; nên hỏi bác sĩ nếu sau 3 tuần rốn vẫn chưa rụng.',
            'Cục thịt hồng ở chân rốn: hẹn khám nếu sau khoảng một tuần vẫn không hết.',
          ),
          tip(
            'Rốn lồi khi bé khóc',
            'Một khối phồng mềm ở rốn, to hơn khi bé khóc hay rặn, thường là thoát vị rốn và rất hay gặp. Phần lớn tự liền khi bé lớn: AAP cho biết thường trong 12–18 tháng, NHS cho biết hầu hết hết trước khoảng 5 tuổi. Hãy cho bác sĩ xem trong lần khám định kỳ.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            '“Bôi nghệ, rắc bột kháng sinh hay đắp lá cho rốn mau khô, mau lành.” Bà và mẹ làm vì thương bé, nhưng các chất này có thể không sạch, giữ ẩm, gây kích ứng và che lấp dấu hiệu nhiễm trùng. WHO khuyến nghị chăm rốn khô, sạch, không bôi đắp gì.',
            '“Phải băng kín rốn hoặc quấn đai rốn để gió không lọt vào, rốn không bị lồi.” Băng kín làm rốn ẩm, lâu khô và dễ nhiễm khuẩn hơn. Nên để rốn thoáng và gấp tã dưới rốn.',
            '“Rốn lồi thì lấy đồng xu ép rồi băng lại.” AAP khuyên không dán đồng xu hay bất cứ vật gì lên rốn; phần lớn thoát vị rốn tự khỏi. Cứ để tự nhiên và hỏi bác sĩ khi đi khám.',
            '“Rốn chưa rụng thì không được lau rửa gì cho bé.” Bé vẫn cần được giữ sạch: lau người bằng khăn ấm, chỉ tránh ngâm rốn trong nước.',
          ),
          doctor(
            'Gọi 115 hoặc đến cấp cứu ngay khi',
            'Rốn chảy máu liên tục, ấn nhẹ bằng gạc sạch vẫn không cầm; bé li bì, khó đánh thức, người mềm nhũn hoặc bỏ bú; bé khó thở, tím tái; khối phồng ở rốn cứng, đổi màu, kèm bé nôn hoặc khóc thét không dỗ được.',
          ),
          doctor(
            'Đưa bé đi khám sớm (trong ngày) khi',
            'Da quanh rốn đỏ, sưng hoặc đỏ lan ra bụng; rốn có mủ, dịch vàng mùi hôi; bé khóc khi chạm vào rốn hay vùng da xung quanh; bé dưới 3 tháng có nhiệt độ từ 38 °C trở lên; bé bú kém hơn hẳn.',
          ),
        ],
        en: [
          note(
            'In short',
            'For babies born in a health facility, WHO recommends keeping the cord clean and dry with nothing put on it. The stump usually falls off by itself within about 5–15 days. Redness spreading around the belly button, pus, a bad smell, or a baby with a fever, poor feeding or unusual drowsiness needs a doctor straight away.',
          ),
          h('Understanding the cord stump'),
          p(
            'After the cord is clamped and cut, the remaining stump slowly dries, turns dark brown and falls off. According to MedlinePlus (U.S. National Library of Medicine), this usually happens within about 5–15 days; the AAP says the stump should fall off by the time your baby is 3 weeks old. Keeping it dry and open to the air helps; damp and dirt raise the risk of infection.',
          ),
          p(
            'When the stump comes off you may see a few drops of blood on the diaper, which is usually normal. Sometimes a small, moist pink lump stays at the base and oozes pale yellow fluid. This is an umbilical granuloma; many clear up within about a week, and if not, a doctor can treat it simply in the clinic.',
          ),
          p(
            'About antiseptics: WHO recommends clean, dry cord care for babies born in health facilities and in places with low newborn mortality. WHO advises daily 7.1% chlorhexidine in the first week only for babies born at home where newborn mortality is high. The AAP also says alcohol is not needed. If your birth facility told you otherwise, follow the health worker who examined your baby.',
          ),
          h('What you can do'),
          h('Step 1 · Wash your hands before touching the cord'),
          p(
            'Wash your hands with soap and clean water before changing diapers or touching the belly button area. Grandparents and other carers should do the same.',
          ),
          h('Step 2 · Keep the cord dry and open to the air'),
          ul(
            "Fold the top of the diaper down below the stump so urine doesn't soak it and air can reach it.",
            "Dress your baby in a loose cotton top; don't wrap the tummy tightly, cover the cord or use a belly binder.",
            'Until the stump falls off, give sponge baths with a warm cloth instead of putting your baby in the tub.',
          ),
          h('Step 3 · Clean it only when it gets dirty'),
          p(
            'Clean the cord only if it gets urine or stool on it: use clean cotton wool or gauze dipped in warm water, wipe gently around the base, then pat dry. There is no need for alcohol, antiseptic dyes, turmeric or powders.',
          ),
          h('Step 4 · Let it fall off by itself'),
          p(
            "Don't pull, tug or cut the stump, even if it is hanging by a thread. After it falls off, keep the belly button clean and dry until it has fully healed.",
          ),
          h('What to watch'),
          ul(
            'At every diaper change, look at the base of the cord: is the skin around it red or swollen, is there pus or a bad smell?',
            'Is your baby feeding well? Are they unusually drowsy, moving less or floppier than usual?',
            "Take your baby's temperature if they seem unusually hot or cold (see Đo thân nhiệt, Taking a temperature, in the Sơ cứu trẻ em first aid guide in Child Life).",
            'The day the stump falls off. The AAP uses 3 weeks and MedlinePlus 4 weeks as the cut-off; ask a doctor if it is still attached after 3 weeks.',
            "A pink lump at the base: book a check if it hasn't gone after about a week.",
          ),
          tip(
            'A belly button that bulges when your baby cries',
            'A soft bulge at the belly button that gets bigger with crying or straining is usually an umbilical hernia, and it is very common. Most close as the child grows: the AAP says often by 12–18 months, and the NHS says most go by about age 5. Have it checked at a routine visit.',
          ),
          h('Common misconceptions'),
          ul(
            '“Put turmeric, antibiotic powder or leaves on the cord so it dries and heals faster.” Families do this out of love, but these substances may not be clean, can keep the area moist, irritate the skin and hide signs of infection. WHO recommends clean, dry cord care with nothing applied.',
            '“Cover the cord tightly or use a belly binder to keep out the wind and stop it bulging.” A tight covering keeps the cord moist, slows drying and makes infection more likely. Leave it open to the air with the diaper folded below.',
            '“Press a coin on a bulging belly button and tape it down.” The AAP advises against taping a coin or anything else over the belly button; most umbilical hernias close on their own. Leave it be and ask the doctor at a check-up.',
            "“Don't wash the baby at all until the cord falls off.” Your baby still needs to be kept clean: sponge with a warm cloth and just avoid soaking the cord.",
          ),
          doctor(
            'Call 115 or go to the emergency department now if',
            "The cord keeps bleeding even with gentle pressure from clean gauze; your baby is very drowsy, hard to wake, floppy or refusing feeds; has trouble breathing or turns blue; or a bulge at the belly button becomes hard or changes colour and your baby vomits or screams and can't be comforted.",
          ),
          doctor(
            'See a doctor the same day if',
            'The skin around the belly button is red, swollen or the redness is spreading onto the tummy; there is pus or smelly yellow discharge; your baby cries when the cord or nearby skin is touched; your baby is under 3 months with a temperature of 38 °C or higher; or is feeding much less than usual.',
          ),
        ],
      },
      keywords: t(
        [
          'rốn',
          'cuống rốn',
          'rụng rốn',
          'nhiễm trùng rốn',
          'u hạt rốn',
          'rốn lồi',
          'thoát vị rốn',
          'chlorhexidine',
        ],
        [
          'belly button',
          'umbilical cord stump',
          'cord falling off',
          'cord infection',
          'umbilical granuloma',
          'outie belly button',
          'umbilical hernia',
          'chlorhexidine',
        ],
      ),
      relatedArticleIds: [
        'art_bathing_at_home',
        'art_fever_when_to_call',
        'art_newborn_jaundice',
        'art_diaper_rash',
      ],
      milestoneIds: [],
      sources: [
        S.eWhoPostnatal2013,
        S.eHcUmbilicalCord,
        S.eMedlineCordCare,
        S.eNhsWashingBathing,
        S.eNhsUmbilicalHernia,
        S.eHcBathingNewborn,
        S.nhsFever,
      ],
    },
  },
  {
    id: 'art_diaper_rash',
    reviewerLabel: NURSING,
    data: {
      library: 'care',
      topic: 'daily_care',
      format: 'article',
      ageWeeks: { from: 0, to: 104 },
      readingMinutes: 4,
      cover: null,
      title: t(
        'Hăm tã: nhận biết, chăm sóc và phòng ngừa',
        'Diaper rash: spotting it, caring for it, preventing it',
      ),
      summary: t(
        'Hăm tã rất hay gặp và thường đỡ sau vài ngày nếu giữ vùng tã sạch, khô và bôi kem bảo vệ. Hăm do nấm, nhiễm khuẩn hay kèm sốt thì cần bác sĩ xem.',
        'Diaper rash is very common and usually improves within a few days if you keep the area clean and dry and use a barrier cream. Yeast or bacterial rashes, or a rash with fever, need a doctor.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Phần lớn hăm tã là do da tiếp xúc lâu với nước tiểu, phân và bị cọ xát. Thay tã thường xuyên, rửa bằng nước ấm, thấm khô, cho da thoáng và bôi kem có kẽm oxit hoặc vaseline thường giúp da đỡ trong 2–3 ngày. Không tự bôi kem có corticoid hay phấn rôm.',
          ),
          h('Hiểu đúng về hăm tã'),
          p(
            'Vùng da trong tã luôn ẩm, ấm và bị cọ xát. Nước tiểu và phân, nhất là khi bé tiêu chảy, làm lớp bảo vệ của da yếu đi; da đỏ, rát, có khi trợt. Tã quá chật hoặc kém thấm hút, khăn ướt có cồn hay hương liệu, xà phòng, bột giặt, và một số thuốc như kháng sinh cũng khiến bé dễ hăm hơn.',
          ),
          p(
            'Hăm do kích ứng thường là những mảng hồng hoặc đỏ ở chỗ da chạm vào tã, còn các nếp bẹn thường bình thường. Hăm do nấm Candida thường đỏ tươi, bóng, bờ rõ, có những nốt đỏ nhỏ rải rác quanh rìa, nặng ở các nếp bẹn, hay gặp sau khi bé dùng kháng sinh. Nhiễm khuẩn hiếm hơn, có thể có mụn mủ, phỏng nước, vảy vàng hoặc rỉ dịch. Còn chàm (viêm da cơ địa) ở trẻ nhỏ thường ở mặt, da đầu và ít khi ở vùng tã.',
          ),
          h('Ba mẹ có thể làm gì'),
          h('Mỗi lần thay tã'),
          ul(
            'Thay ngay khi tã ướt hoặc bẩn, kể cả ban đêm nếu bé đi ngoài.',
            'Rửa bằng nước ấm với khăn mềm hoặc bông gòn; nếu dùng khăn ướt, chọn loại không cồn, không mùi. Khi da đã trợt, dội nước nhẹ thay vì chà lau.',
            'Thấm khô nhẹ nhàng, không chà xát; để da khô thoáng vài phút trước khi mặc tã.',
            'Bôi kem bảo vệ có kẽm oxit hoặc vaseline lên vùng da đỏ. AAP khuyên bôi lớp dày, còn NHS nói một lớp mỏng mỗi lần thay tã; điều quan trọng là bôi đều đặn sau mỗi lần thay. Kem còn sạch thì không cần lau đi, chỉ bôi thêm lên trên.',
            'Đóng tã vừa vặn, không quá chặt, nhất là ban đêm.',
          ),
          h('Trong ngày'),
          ul(
            'Cho bé những lúc không mặc tã, nằm trên khăn hoặc tấm lót, để da thoáng khí.',
            'Dùng tã thấm hút tốt; với tã vải, thay thường xuyên hơn và giặt xả thật sạch.',
            'Khi da đang hăm, có thể tắm nước ấm mỗi ngày; không dùng xà phòng, sữa tắm tạo bọt hay sản phẩm có hương liệu ở vùng tã, và bôi lại kem sau khi tắm.',
            'Khi bé tiêu chảy, thay tã thường xuyên hơn và bôi kem bảo vệ ngay từ đầu.',
          ),
          tip(
            'Nghi do sản phẩm mới?',
            'Nếu hăm xuất hiện sau khi đổi loại tã, khăn ướt hay kem, hãy đổi sang loại khác trong khoảng 2 tuần để xem da có đỡ không.',
          ),
          h('Theo dõi'),
          ul(
            'Vùng hăm đỡ dần hay lan rộng sau 2–3 ngày chăm sóc.',
            'Có nốt đỏ rải rác quanh rìa, mảng đỏ tươi ở nếp bẹn, mụn mủ, phỏng nước, vảy vàng hay chỗ rỉ dịch không.',
            'Bé có sốt, có quấy khóc nhiều khi thay tã hay khi đi tiểu không.',
            'Số lần đi ngoài và tính chất phân; ba mẹ có thể ghi lại tã trong Child Life để đưa bác sĩ xem.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            '“Bôi phấn rôm cho khô, cho đỡ hăm.” Phấn không chữa được hăm, mà bé có thể hít bột vào phổi; AAP và NHS đều khuyên không dùng phấn rôm cho bé. Nên thấm khô và dùng kem bảo vệ.',
            '“Rửa bằng nước lá trầu không, lá chè xanh đun cho sát khuẩn.” Nhà mình làm vì muốn bé mau khỏi, nhưng nước lá có thể làm da đang trợt xót và kích ứng thêm, và không thay được việc giữ khô, bôi kem. Nên rửa bằng nước ấm sạch.',
            '“Ra hiệu thuốc mua kem có corticoid, bôi vài hôm là khỏi.” Vùng tã là vùng da mỏng; Hội Chàm Anh khuyên không bôi corticoid ở vùng sinh dục, hậu môn nếu không có hướng dẫn. Hăm do nấm lại cần thuốc kháng nấm. Hãy để bác sĩ chọn đúng thuốc và đúng số ngày.',
            '“Xoa dầu tràm, dầu gió cho ấm, cho mau lành.” Tinh dầu và dầu xoa làm vùng da đang tổn thương xót và dễ kích ứng hơn, không chữa được hăm. Nên dùng kem bảo vệ không mùi.',
          ),
          doctor(
            'Đưa bé đi khám sớm (trong ngày) khi',
            'Bé dưới 3 tháng có nhiệt độ từ 38 °C trở lên; bé sốt kèm hăm; vùng da sưng, nóng, rất đau hoặc lan nhanh; bé li bì, bỏ bú, ít tã ướt hơn hẳn (dấu hiệu mất nước khi tiêu chảy).',
          ),
          doctor(
            'Khi nào nên hỏi bác sĩ',
            'Hăm không đỡ hoặc nặng hơn sau 2–3 ngày chăm sóc tại nhà; có mảng đỏ tươi ở nếp bẹn kèm nốt đỏ rải rác, nhất là khi bé đang hoặc vừa dùng kháng sinh; có mụn mủ, phỏng nước, vảy vàng, rỉ dịch hay bong da; hăm lan ra ngoài vùng tã; bé rất khó chịu.',
          ),
        ],
        en: [
          note(
            'In short',
            "Most diaper rash comes from skin being in contact with urine and stool for too long, plus rubbing. Changing often, washing with warm water, patting dry, diaper-free time and a cream with zinc oxide or petroleum jelly usually help within 2–3 days. Don't use steroid creams on your own, or baby powder.",
          ),
          h('Understanding diaper rash'),
          p(
            "Skin inside a diaper is always damp, warm and rubbed. Urine and stool, especially with diarrhoea, weaken the skin's protective layer, so it becomes red, sore and sometimes raw. Tight or poorly absorbent diapers, wipes with alcohol or fragrance, soap, detergent and some medicines such as antibiotics also make rash more likely.",
          ),
          p(
            'An irritant rash usually shows as pink or red patches where the diaper touches, while the groin creases look normal. A yeast (Candida) rash is usually bright red and shiny with sharp edges and small red spots scattered around the border, worst in the creases, and often follows antibiotics. Bacterial infection is less common and can cause pimples with pus, blisters, yellow crusts or weeping. Eczema (atopic dermatitis) in babies usually affects the face and scalp and rarely the diaper area.',
          ),
          h('What you can do'),
          h('At every change'),
          ul(
            'Change wet or dirty diapers straight away, including at night if your baby has pooed.',
            'Clean with warm water and a soft cloth or cotton wool; if you use wipes, choose alcohol-free, fragrance-free ones. If the skin is raw, rinse gently instead of wiping.',
            'Pat dry gently without rubbing, and let the skin air for a few minutes before the next diaper.',
            "Apply a barrier cream with zinc oxide or petroleum jelly to the red skin. The AAP advises a thick layer, while the NHS says a thin layer at each change; what matters most is applying it at every change. If the cream is still clean, don't wipe it off, just add more on top.",
            "Fasten the diaper so it fits well but isn't tight, especially overnight.",
          ),
          h('During the day'),
          ul(
            'Give your baby diaper-free time lying on a towel or mat so the skin can breathe.',
            'Use well-absorbing diapers; with cloth diapers, change more often and rinse them very well after washing.',
            'While the rash lasts, a daily warm bath is fine; avoid soap, bubble bath and fragranced products on the diaper area, and reapply cream after the bath.',
            'When your baby has diarrhoea, change more often and use barrier cream from the start.',
          ),
          tip(
            'Could it be a new product?',
            'If the rash started after switching diapers, wipes or creams, try a different product for about 2 weeks to see if the skin improves.',
          ),
          h('What to watch'),
          ul(
            'Is the rash getting better or spreading after 2–3 days of care?',
            'Scattered red spots around the edge, bright red creases, pus spots, blisters, yellow crusts or weeping skin?',
            'Does your baby have a fever, or cry a lot at diaper changes or when peeing?',
            'How often your baby poos and what it looks like; you can log diapers in Child Life to show the doctor.',
          ),
          h('Common misconceptions'),
          ul(
            "“Use baby powder to dry the skin and ease the rash.” Powder doesn't treat rash and your baby may breathe it into the lungs; both the AAP and the NHS advise against baby powder. Pat dry and use a barrier cream.",
            "“Wash with boiled betel or green tea leaf water to kill germs.” Families do this to help the baby heal fast, but leaf water can sting and further irritate raw skin, and it can't replace keeping the area dry and using cream. Wash with clean warm water.",
            '“Buy a steroid cream at the pharmacy and it will clear in a few days.” The diaper area has thin skin; the UK National Eczema Society advises against using steroids on the genital or anal area without guidance. A yeast rash needs an antifungal instead. Let a doctor choose the right treatment and how long to use it.',
            "“Rub on cajeput or medicated oil to warm and heal the skin.” Essential and rubbing oils sting damaged skin and make irritation more likely; they don't treat rash. Use a fragrance-free barrier cream.",
          ),
          doctor(
            'See a doctor the same day if',
            'Your baby is under 3 months with a temperature of 38 °C or higher; has a fever with the rash; the skin is swollen, hot, very painful or the rash is spreading fast; or your baby is very drowsy, refusing feeds or has far fewer wet diapers (signs of dehydration with diarrhoea).',
          ),
          doctor(
            'When to ask a doctor',
            "The rash hasn't improved or is worse after 2–3 days of home care; there are bright red creases with scattered red spots, especially during or after antibiotics; there are pus spots, blisters, yellow crusts, weeping or peeling skin; the rash spreads beyond the diaper area; or your baby is very uncomfortable.",
          ),
        ],
      },
      keywords: t(
        [
          'hăm tã',
          'hăm bỉm',
          'kem chống hăm',
          'kẽm oxit',
          'hăm do nấm',
          'thay tã',
          'phấn rôm',
          'vùng tã đỏ',
        ],
        [
          'diaper rash',
          'nappy rash',
          'barrier cream',
          'zinc oxide',
          'yeast rash',
          'diaper change',
          'baby powder',
          'red diaper area',
        ],
      ),
      relatedArticleIds: [
        'art_eczema_dry_skin',
        'art_diarrhoea_dehydration',
        'art_bathing_at_home',
        'art_fever_when_to_call',
      ],
      milestoneIds: [],
      sources: [
        S.eNhsNappyRash,
        S.eHcDiaperRash,
        S.eHcEczema,
        S.eHcBabyRoomSafe,
        S.eNesTopicalSteroids,
        S.nhsFever,
      ],
    },
  },
  {
    id: 'art_eczema_dry_skin',
    reviewerLabel: PAEDS,
    data: {
      library: 'care',
      topic: 'daily_care',
      format: 'article',
      ageWeeks: { from: 0, to: 104 },
      readingMinutes: 6,
      cover: null,
      title: t(
        'Chàm (viêm da cơ địa) và da khô ở trẻ nhỏ: chăm da mỗi ngày',
        'Eczema (atopic dermatitis) and dry skin in young children: everyday skin care',
      ),
      summary: t(
        'Chàm là do hàng rào bảo vệ của da yếu, không lây và không phải do ba mẹ chăm sai. Dưỡng ẩm đều đặn, tắm ngắn bằng nước ấm và dùng đúng thuốc bác sĩ kê giúp bé dễ chịu hơn nhiều.',
        "Eczema comes from a weak skin barrier; it isn't contagious and isn't caused by anything you did. Regular moisturising, short warm baths and using prescribed treatment correctly make a big difference.",
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Chăm chàm dựa trên ba việc: thoa thật nhiều kem dưỡng ẩm không mùi ít nhất 2 lần mỗi ngày, kể cả khi da đã đỡ; tắm ngắn 5–10 phút bằng nước ấm, không xà phòng; và dùng thuốc bôi bác sĩ kê đúng cách khi da bùng phát. Không tự ý kiêng ăn hay bôi thuốc không rõ nguồn gốc.',
          ),
          h('Hiểu đúng về chàm và da khô'),
          p(
            'Ở nhiều bé bị chàm, lớp ngoài cùng của da không giữ nước tốt và không ngăn tốt chất kích ứng, vi khuẩn. Da vì thế khô, ngứa; bé gãi làm da tổn thương thêm và lại càng ngứa. Chàm thường có tính gia đình, hay có đợt nặng lên rồi đỡ, và không lây.',
          ),
          p(
            'Ở trẻ nhũ nhi, chàm thường bắt đầu ở má, mặt và da đầu, ít khi ở vùng tã. Khi bé lớn hơn, chàm hay xuất hiện ở nếp khuỷu tay, khoeo chân, cổ. Nhiều bé đỡ dần theo tuổi, nhưng khó đoán trước bé nào sẽ hết.',
          ),
          p(
            'Những yếu tố hay làm chàm nặng lên: xà phòng, bột giặt, nóng bức hoặc thay đổi nhiệt độ, một số loại vải, bụi nhà, lông thú, nhiễm khuẩn da. Trẻ bị chàm hay bị dị ứng thức ăn kèm theo, nhưng thức ăn không phải là nguyên nhân gây chàm; không nên tự ý kiêng ăn khi bác sĩ chưa dặn.',
          ),
          h('Ba mẹ có thể làm gì'),
          h('Dưỡng ẩm là việc chính mỗi ngày'),
          ul(
            'Thoa kem dưỡng ẩm không mùi lên toàn thân ít nhất 2 lần mỗi ngày, nhiều hơn nếu da khô; NHS gợi ý có thể 3–4 lần mỗi ngày và không lo dùng quá nhiều.',
            'Kem đặc hoặc thuốc mỡ (như vaseline) thường giữ ẩm tốt hơn sữa dưỡng dạng lỏng hay dầu.',
            'Vuốt nhẹ theo chiều lông mọc, không chà xát. Lấy kem bằng thìa sạch hoặc chai có vòi bơm để kem trong hũ không bị nhiễm bẩn.',
            'Tiếp tục dưỡng ẩm cả khi da đã lành, vì da bé vẫn dễ khô trở lại.',
          ),
          h('Khi tắm'),
          ul(
            'Tắm bằng nước ấm, không nóng, khoảng 5–10 phút; không kỳ cọ.',
            'Không dùng xà phòng, sữa tắm tạo bọt hay sản phẩm có hương liệu; có thể dùng chính kem dưỡng để làm sạch, hoặc sữa rửa dịu nhẹ không mùi cho những chỗ bẩn.',
            'Thấm khô nhẹ rồi thoa kem dưỡng ngay sau khi tắm.',
            'Kem dưỡng làm chậu và sàn rất trơn: giữ chắc bé, trải thảm chống trơn và rửa chậu sau khi tắm.',
          ),
          h('Thuốc bôi bác sĩ kê'),
          p(
            'Khi da đỏ, ngứa nhiều, bác sĩ có thể kê thuốc bôi có corticoid loại nhẹ phù hợp với trẻ nhỏ. Nhiều ba mẹ sợ “corticoid làm mỏng da”, nhưng khi dùng đúng loại, đúng chỗ và đúng số ngày bác sĩ dặn, nguy cơ tác dụng phụ thấp và lợi ích lớn hơn nhiều. Bôi quá ít hoặc ngưng quá sớm vì sợ lại khiến chàm dai dẳng. Về thứ tự, Hội Da liễu Hoa Kỳ (AAD) hướng dẫn bôi thuốc ngay sau tắm rồi mới thoa kem dưỡng, còn NHS gợi ý hai thứ cách nhau 20–30 phút; hãy làm theo cách bác sĩ của bé dặn.',
          ),
          h('Giảm gãi, phòng nhiễm trùng'),
          ul(
            'Cắt ngắn móng tay; với bé nhỏ có thể đeo bao tay chống cào.',
            'Mặc quần áo cotton mềm, thoáng; tránh mặc quá ấm hay quấn nhiều lớp khiến bé đổ mồ hôi.',
            'Giặt đồ bằng bột giặt dịu nhẹ, không mùi, xả kỹ.',
            'Người đang bị mụn rộp ở môi (herpes) không nên hôn bé; mọi người rửa tay trước khi bế bé.',
          ),
          h('Chàm và dị ứng thức ăn'),
          p(
            'Bé bị chàm nặng từ sớm, phải dùng thuốc bôi kê đơn, có nguy cơ dị ứng thức ăn cao hơn. AAP khuyên ba mẹ của những bé này trao đổi với bác sĩ trước khi ăn dặm: có thể bé cần được kiểm tra và làm quen sớm với thực phẩm có đậu phộng từ khoảng 4–6 tháng, dưới sự hướng dẫn của nhân viên y tế. Xem thêm bài Giới thiệu thực phẩm dễ gây dị ứng. Mẹ đang cho con bú không cần kiêng ăn, trừ khi bác sĩ dặn.',
          ),
          h('Theo dõi'),
          ul(
            'Chỗ da nào hay bùng phát, mức độ ngứa, bé có mất ngủ vì gãi không.',
            'Điều gì trùng với đợt nặng lên: trời nóng, đổ mồ hôi, sản phẩm mới, bột giặt mới, ốm.',
            'Dấu hiệu nhiễm trùng: vảy vàng như mật ong, rỉ dịch, mụn mủ, da sưng, nóng, đau.',
            'Bé nổi mẩn, sưng môi, sưng mắt hay nôn ngay sau khi ăn món mới: ghi lại món đó và báo bác sĩ.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            '“Bé bị chàm thì kiêng tắm cho đỡ.” Không tắm làm mồ hôi, bụi bẩn đọng lại và da dễ nhiễm khuẩn hơn. Nên tắm ngắn bằng nước ấm, không xà phòng, rồi thoa kem dưỡng ngay.',
            '“Tắm nước lá cho hết chàm.” Ông bà mong cháu khỏi nhanh, nhưng nước lá có thể làm da đang tổn thương kích ứng thêm và không thay được dưỡng ẩm. Nên dùng nước ấm sạch và kem dưỡng không mùi.',
            '“Mẹ và bé phải kiêng tôm, cua, trứng, sữa bò.” Thức ăn không gây chàm; tự kiêng dễ làm bữa ăn của bé, và của mẹ đang cho bú, thiếu chất. Chỉ kiêng khi bác sĩ đã xác định bé dị ứng món đó.',
            '“Bôi sữa mẹ lên chàm là khỏi.” Mới có rất ít nghiên cứu nhỏ, bằng chứng chưa chắc chắn; sữa mẹ không thay được kem dưỡng hay thuốc bác sĩ kê. Nếu muốn thử, hãy hỏi bác sĩ và vẫn dưỡng ẩm đều.',
            '“Thuốc nam, kem gia truyền bôi là hết ngay.” Cơ quan quản lý dược của Anh từng phát hiện kem quảng cáo là thảo dược trị chàm lại chứa corticoid rất mạnh không ghi trên nhãn, có hại cho trẻ nhỏ khi bôi lâu, diện rộng. Chỉ dùng thuốc rõ nguồn gốc, theo hướng dẫn của bác sĩ hoặc dược sĩ.',
          ),
          doctor(
            'Gọi 115 hoặc đến cấp cứu ngay khi',
            'Trên vùng chàm nổi nhiều mụn nước hoặc vết loét tròn nhỏ như bị đục lỗ, lan nhanh, kèm sốt hoặc bé mệt lả (có thể là chàm bội nhiễm virus herpes, một cấp cứu da liễu); bé khó thở, sưng môi, lưỡi, mặt sau khi ăn (xem Sốc phản vệ trong mục Sơ cứu trẻ em của Child Life).',
          ),
          doctor(
            'Đưa bé đi khám sớm (trong ngày) khi',
            'Chàm có vảy vàng, rỉ dịch, mụn mủ, sưng, nóng, đau; chàm đột ngột nặng lên hay lan nhanh; bé sốt hoặc trông mệt. Hẹn khám nếu chàm không đỡ dù đã chăm đúng cách, bé mất ngủ vì ngứa, hoặc ba mẹ còn lo lắng về thuốc bôi.',
          ),
        ],
        en: [
          note(
            'In short',
            "Eczema care rests on three things: plenty of fragrance-free moisturiser at least twice a day, even when the skin looks better; short 5–10 minute baths in warm water without soap; and using the treatment your doctor prescribes correctly during flares. Don't cut out foods on your own or use creams of unknown origin.",
          ),
          h('Understanding eczema and dry skin'),
          p(
            "In many babies with eczema, the outer layer of the skin doesn't hold water well or keep out irritants and germs. The skin becomes dry and itchy; scratching damages it further and makes it itch even more. Eczema often runs in families, tends to flare and settle, and is not contagious.",
          ),
          p(
            'In babies, eczema usually starts on the cheeks, face and scalp, and rarely in the diaper area. As children grow, it often appears in the elbow creases, behind the knees and on the neck. Many children improve with age, but it is hard to predict who will outgrow it.',
          ),
          p(
            "Common triggers include soap, detergent, heat or temperature changes, some fabrics, house dust, pet hair and skin infections. Children with eczema often have food allergies too, but food does not cause eczema; don't cut out foods unless a doctor tells you to.",
          ),
          h('What you can do'),
          h('Moisturising is the main daily job'),
          ul(
            "Apply a fragrance-free moisturiser all over at least twice a day, more if the skin is dry; the NHS suggests 3–4 times a day is fine and you can't overuse it.",
            'Thick creams or ointments (such as petroleum jelly) usually work better than lotions or oils.',
            "Smooth it on gently in the direction of hair growth rather than rubbing. Use a clean spoon or a pump bottle so the tub doesn't get contaminated.",
            'Keep moisturising after the skin has healed, because it dries out again easily.',
          ),
          h('At bath time'),
          ul(
            "Bathe in warm, not hot, water for about 5–10 minutes; don't scrub.",
            'Avoid soap, bubble bath and fragranced products; you can wash with the moisturiser itself, or a mild fragrance-free cleanser on dirty areas only.',
            'Pat partly dry, then apply moisturiser straight after the bath.',
            'Moisturisers make the bath and floor very slippery: hold your baby securely, use a non-slip mat and wash the bath afterwards.',
          ),
          h('Prescribed creams'),
          p(
            "When the skin is red and very itchy, a doctor may prescribe a mild steroid cream suitable for young children. Many parents fear that “steroids thin the skin”, but used as directed, in the right strength, place and number of days, the risk of side effects is low and the benefits are much greater. Using too little or stopping too soon out of fear keeps eczema going. On order, the American Academy of Dermatology (AAD) advises the medicine straight after the bath and then moisturiser, while the NHS suggests leaving 20–30 minutes between them; follow what your baby's doctor tells you.",
          ),
          h('Less scratching, fewer infections'),
          ul(
            'Keep nails short; young babies can wear scratch mittens.',
            'Dress your baby in soft, breathable cotton; avoid overdressing or many layers that make them sweat.',
            'Wash clothes in a mild, fragrance-free detergent and rinse well.',
            'Anyone with a cold sore should not kiss your baby; everyone should wash their hands before holding them.',
          ),
          h('Eczema and food allergy'),
          p(
            "Babies with severe early eczema that needs prescription treatment have a higher risk of food allergy. The AAP advises parents of these babies to talk to their doctor before starting solids: they may need testing and early introduction of peanut-containing foods from around 4–6 months, under a health worker's guidance. See Introducing allergenic foods. Breastfeeding mothers don't need to avoid any foods unless a doctor advises it.",
          ),
          h('What to watch'),
          ul(
            'Which areas flare, how itchy your baby is, and whether scratching disturbs their sleep.',
            'What coincides with flares: hot weather, sweating, a new product, a new detergent, illness.',
            'Signs of infection: honey-coloured crusts, weeping, pus spots, skin that is swollen, hot or painful.',
            'A rash, swollen lips or eyes, or vomiting soon after a new food: note the food and tell the doctor.',
          ),
          h('Common misconceptions'),
          ul(
            "“A baby with eczema shouldn't be bathed.” Without washing, sweat and dirt build up and the skin gets infected more easily. Give a short warm bath without soap, then moisturise straight away.",
            "“Bathe in leaf water to clear eczema.” Grandparents want the baby to heal quickly, but leaf water can further irritate damaged skin and can't replace moisturiser. Use clean warm water and a fragrance-free moisturiser.",
            "“Mother and baby must avoid shrimp, crab, eggs and cow's milk.” Food doesn't cause eczema; cutting foods out on your own can leave your baby's diet, and a breastfeeding mother's, short of nutrients. Only avoid a food once a doctor has confirmed your baby is allergic to it.",
            "“Putting breast milk on eczema cures it.” There are only a few small studies and the evidence is uncertain; breast milk can't replace moisturiser or prescribed treatment. If you want to try it, ask your doctor and keep moisturising.",
            '“Herbal or family-recipe creams clear it straight away.” The UK medicines regulator has found creams sold as herbal eczema remedies that contained a very strong steroid not listed on the label, which can harm young children when used over large areas or for long. Only use products of known origin, as advised by a doctor or pharmacist.',
          ),
          doctor(
            'Call 115 or go to the emergency department now if',
            'Eczema suddenly develops many small blisters or round, punched-out sores that spread fast, with fever or a very unwell baby (this may be eczema herpeticum, a skin emergency); or your baby has trouble breathing or a swollen lip, tongue or face after eating (see Sốc phản vệ, Anaphylaxis, in the Sơ cứu trẻ em first aid guide in Child Life).',
          ),
          doctor(
            'See a doctor the same day if',
            "The eczema has yellow crusts, weeping, pus spots, or is swollen, hot or painful; it suddenly gets worse or spreads fast; or your baby has a fever or seems unwell. Book a visit if the eczema isn't improving despite good care, itching keeps your baby awake, or you have worries about prescribed creams.",
          ),
        ],
      },
      keywords: t(
        [
          'chàm',
          'viêm da cơ địa',
          'chàm sữa',
          'da khô',
          'kem dưỡng ẩm',
          'corticoid bôi',
          'ngứa',
          'dị ứng thức ăn',
        ],
        [
          'eczema',
          'atopic dermatitis',
          'baby eczema',
          'dry skin',
          'moisturiser',
          'steroid cream',
          'itching',
          'food allergy',
        ],
      ),
      relatedArticleIds: [
        'art_allergen_intro',
        'art_bathing_at_home',
        'art_diaper_rash',
        'art_solids_readiness',
      ],
      milestoneIds: [],
      sources: [
        S.eNhsAtopicEczema,
        S.eNhsEmollients,
        S.eHcEczema,
        S.eAadEczemaBabies,
        S.eAadSteroidsChild,
        S.eDermnetEczemaHerpeticum,
        S.eHcPeanutEarly,
        S.eMhraHerbalSteroids,
      ],
    },
  },
  {
    id: 'art_teething',
    reviewerLabel: PAEDS,
    data: {
      library: 'care',
      topic: 'teething',
      format: 'article',
      ageWeeks: { from: 17, to: 104 },
      readingMinutes: 6,
      cover: null,
      title: t(
        'Mọc răng và chăm sóc răng miệng cho bé',
        "Teething and caring for your baby's teeth",
      ),
      summary: t(
        'Phần lớn bé mọc chiếc răng đầu tiên khoảng 6 tháng, sớm hay muộn hơn đều có thể bình thường. Cách giúp bé dễ chịu an toàn, đánh răng với kem có fluor từ chiếc răng đầu tiên và phòng sâu răng sớm.',
        'Most babies get their first tooth at around 6 months, though earlier or later can be normal. Safe ways to soothe, brushing with fluoride toothpaste from the first tooth, and preventing early tooth decay.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Mọc răng có thể làm bé chảy dãi, gặm cắn, quấy hơn, nhưng không gây sốt từ 38 °C, tiêu chảy hay bệnh nặng. Xoa lợi bằng ngón tay sạch hoặc cho gặm vòng ngậm làm mát; không dùng gel gây tê, vòng hổ phách, mật ong. Từ chiếc răng đầu tiên, chải răng 2 lần mỗi ngày với lượng kem có fluor nhỏ như hạt gạo.',
          ),
          h('Hiểu đúng về mọc răng'),
          p(
            'Phần lớn bé bắt đầu mọc răng khoảng 6 tháng tuổi, nhưng có bé mọc trước 4 tháng, có bé sau 12 tháng, và hiếm khi bé sinh ra đã có răng. Thứ tự thường gặp: răng cửa giữa khoảng 6 tháng, răng cửa bên khoảng 8 tháng, răng hàm thứ nhất khoảng 12 tháng, răng nanh khoảng 18 tháng, răng hàm thứ hai khoảng 24 tháng. Răng ở hàm dưới thường nhú trước răng tương ứng ở hàm trên. Hầu hết trẻ có đủ bộ răng sữa lúc 2–3 tuổi.',
          ),
          p(
            'Khi răng sắp nhú, bé có thể: lợi đỏ, sưng ở chỗ răng mọc; chảy nhiều nước dãi, nổi mẩn quanh miệng hoặc đỏ một bên má; dụi tai; hay gặm cắn; quấy và ngủ kém hơn. Nhiều bé chỉ khó chịu vài ngày, có bé gần như không có biểu hiện gì.',
          ),
          p(
            'NHS cho biết bé có thể hơi ấm người nhưng dưới 38 °C, còn AAP nhấn mạnh mọc răng không gây sốt. Cả hai thống nhất: nếu bé sốt từ 38 °C trở lên, tiêu chảy, nôn hay trông mệt, đừng đổ cho mọc răng mà hãy tìm nguyên nhân khác và hỏi bác sĩ.',
          ),
          h('Ba mẹ có thể làm gì'),
          h('Giúp bé dễ chịu khi mọc răng'),
          ul(
            'Rửa tay sạch rồi xoa nhẹ lợi bé bằng ngón tay.',
            'Cho bé gặm vòng ngậm nướu loại đặc, chắc (không chứa nước bên trong); có thể để ngăn mát tủ lạnh nhưng không để ngăn đá, vì đồ đông cứng có thể làm đau lợi. Không buộc vòng ngậm vào cổ bé.',
            'Bé đã ăn dặm có thể gặm miếng trái cây mềm để mát như dưa lưới, luôn có người lớn ngồi cạnh trông.',
            'Lau nước dãi thường xuyên; thoa một lớp vaseline mỏng quanh miệng trước khi bé bú, ngủ để đỡ mẩn.',
            'Ôm ấp, chơi cùng bé để bé quên cơn khó chịu.',
            'Nếu bé rất khó chịu, hỏi bác sĩ hoặc dược sĩ về thuốc giảm đau phù hợp và liều theo cân nặng của bé; không dùng aspirin cho trẻ.',
          ),
          h('Chăm sóc răng miệng từ sớm'),
          ul(
            'Trước khi có răng: có thể lau lợi bằng khăn hoặc gạc sạch, ẩm sau khi bú, thật nhẹ nhàng.',
            'Từ chiếc răng đầu tiên: chải răng 2 lần mỗi ngày, buổi sáng và lần cuối trước khi ngủ, bằng bàn chải lông mềm cỡ nhỏ.',
            'Dưới 3 tuổi: chỉ dùng một lớp kem đánh răng có fluor nhỏ bằng hạt gạo, điều này AAP và NHS cùng khuyên. NHS khuyên chọn kem có ít nhất 1.000 ppm fluor, xem trên vỏ hộp. Từ 3–6 tuổi: lượng bằng hạt đậu.',
            'Không cần súc miệng lại bằng nước sau khi chải; khi bé biết nhổ, cho bé nhổ bọt nhưng không súc, để fluor còn tác dụng. Cất kem đánh răng xa tầm tay bé.',
            'Ba mẹ chải răng cho bé; theo AAP, trẻ thường cần người lớn giúp đến khoảng 8 tuổi.',
            'Đưa bé đi khám răng khi mọc chiếc răng đầu tiên, chậm nhất trước sinh nhật đầu tiên.',
          ),
          h('Phòng sâu răng sớm'),
          ul(
            'Không cho bé ngậm bình sữa đi ngủ hay ngủ quên với bình: đường trong sữa đọng lâu trên răng.',
            'Tập cho bé uống bằng cốc từ khoảng 6 tháng; NHS khuyên hạn chế bú bình sau 1 tuổi.',
            'Không cho bé uống nước ngọt, sữa có đường; trẻ dưới 1 tuổi không cần nước trái cây.',
            'Không nếm thức ăn bằng thìa của bé, không ngậm núm vú giả trước khi đưa bé, không nhai mớm: vi khuẩn gây sâu răng có thể truyền từ miệng người lớn sang bé.',
          ),
          h('Theo dõi'),
          ul(
            'Ngày mọc chiếc răng đầu tiên và các răng tiếp theo.',
            'Đốm trắng đục trên răng, nhất là sát viền lợi, hoặc vết nâu: dấu hiệu răng đang mất khoáng, nên cho nha sĩ xem sớm.',
            'Nhiệt độ khi bé quấy: đo bằng nhiệt kế thay vì đoán là do mọc răng.',
            'Mảng trắng trên lưỡi, mặt trong má kèm bé bú kém: có thể là tưa miệng (nấm), cần cho bác sĩ xem.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            '“Rơ lưỡi bằng mật ong cho sạch tưa.” Bà thương cháu nên muốn miệng bé thật sạch, nhưng trẻ dưới 12 tháng không được dùng mật ong dưới bất kỳ hình thức nào vì nguy cơ ngộ độc botulinum, còn rơ mạnh dễ làm xước miệng bé. Nếu thấy mảng trắng trong miệng, hãy cho bác sĩ xem thay vì tự rơ.',
            '“Chấm mật ong, đường lên lợi hay vòng ngậm cho bé đỡ đau.” Ngoài nguy cơ của mật ong, đường gây sâu răng ngay từ những chiếc răng đầu tiên. Nên dùng vòng ngậm sạch, làm mát.',
            '“Đeo vòng hổ phách, vòng dâu tằm cho bé đỡ quấy khi mọc răng.” Cơ quan Quản lý Thực phẩm và Dược phẩm Hoa Kỳ (FDA) và AAP cảnh báo vòng cổ, vòng tay mọc răng (hổ phách, gỗ, đá, silicon) đã gây hóc và siết cổ, có trường hợp tử vong. Tốt nhất không đeo bất kỳ loại vòng nào cho bé.',
            '“Gel bôi lợi, viên vi lượng đồng căn trị mọc răng là an toàn.” FDA khuyên không dùng thuốc bôi chứa benzocaine hoặc lidocaine cho bé mọc răng và cảnh báo cả sản phẩm vi lượng đồng căn. NHS không cấm hẳn gel dành riêng cho trẻ nhỏ nhưng cho rằng chưa đủ bằng chứng hiệu quả. An toàn nhất là không dùng.',
            '“Răng sữa rồi cũng thay, sâu cũng không sao.” Răng sữa giúp bé nhai, tập nói và giữ chỗ cho răng vĩnh viễn; răng sâu gây đau và nhiễm trùng. Hãy chăm răng sữa thật kỹ, và không để bé ngậm bình sữa khi ngủ đêm.',
          ),
          doctor(
            'Gọi 115 hoặc đến cấp cứu ngay khi',
            'Bé hóc hạt vòng, mảnh vòng ngậm hay vật nhỏ, khó thở, tím tái (xem Hóc dị vật trong mục Sơ cứu trẻ em của Child Life); bé co giật, li bì khó đánh thức; bé nuốt nhiều kem đánh răng hay thuốc bôi lợi rồi có biểu hiện bất thường (xem Uống nhầm thuốc, hoá chất).',
          ),
          doctor(
            'Đưa bé đi khám khi',
            'Bé dưới 3 tháng có nhiệt độ từ 38 °C trở lên, hoặc bé 3–6 tháng từ 39 °C trở lên: khám ngay trong ngày. Hẹn khám khi bé sốt, tiêu chảy, nôn, bỏ bú hay ít tã ướt; lợi sưng to, chảy mủ; răng có đốm trắng đục, vết nâu hoặc bé đau khi ăn.',
          ),
        ],
        en: [
          note(
            'In short',
            'Teething can bring drooling, chewing and extra fussiness, but it does not cause a fever of 38 °C or more, diarrhoea or serious illness. Rub the gums with a clean finger or offer a chilled teething ring; avoid numbing gels, amber necklaces and honey. From the first tooth, brush twice a day with a rice-grain smear of fluoride toothpaste.',
          ),
          h('Understanding teething'),
          p(
            'Most babies start teething at around 6 months, but some start before 4 months and others after 12, and rarely a baby is born with a tooth. The usual order: central front teeth around 6 months, the teeth beside them around 8 months, first molars around 12 months, canines around 18 months and second molars around 24 months. Bottom teeth often come through before the matching top ones. Most children have all their baby teeth by 2–3 years.',
          ),
          p(
            'As a tooth comes through your baby may have red, swollen gums where it is erupting; lots of drool, a rash around the mouth or one flushed cheek; ear rubbing; more chewing; more fussing and poorer sleep. Many babies are only uncomfortable for a few days, and some show hardly any signs.',
          ),
          p(
            "The NHS says your baby may feel slightly warm but below 38 °C, while the AAP stresses that teething does not cause fever. Both agree: if your baby has a temperature of 38 °C or more, diarrhoea, vomiting or seems unwell, don't blame teething; look for another cause and ask a doctor.",
          ),
          h('What you can do'),
          h('Soothing a teething baby'),
          ul(
            "Wash your hands and gently rub your baby's gums with a finger.",
            "Offer a solid, firm teething ring (not liquid-filled); you can chill it in the fridge but not the freezer, because frozen-hard objects can hurt the gums. Never tie a teether around your baby's neck.",
            'A baby who has started solids can chew on a piece of chilled soft fruit such as melon, always with an adult sitting beside them.',
            'Wipe drool often, and put a thin layer of petroleum jelly around the mouth before feeds and naps to protect the skin.',
            'Cuddle and play with your baby to take their mind off the discomfort.',
            "If your baby is very uncomfortable, ask a doctor or pharmacist about a suitable pain reliever and the dose for your baby's weight; never give aspirin to children.",
          ),
          h('Caring for teeth from the start'),
          ul(
            'Before teeth: you can gently wipe the gums with a clean, damp cloth or gauze after feeds.',
            'From the first tooth: brush twice a day, in the morning and last thing before sleep, with a small soft-bristled brush.',
            'Under 3: use only a smear of fluoride toothpaste the size of a grain of rice, which the AAP and NHS both advise. The NHS recommends toothpaste with at least 1,000 ppm fluoride (check the box). Ages 3–6: a pea-sized amount.',
            'No need to rinse with water after brushing; once your child can spit, have them spit out the foam but not rinse, so the fluoride keeps working. Keep toothpaste out of reach.',
            "Parents do the brushing; the AAP says children usually need an adult's help until about age 8.",
            'Take your baby for a dental check when the first tooth appears, and by their first birthday at the latest.',
          ),
          h('Preventing early tooth decay'),
          ul(
            "Don't put your baby to bed with a bottle or let them fall asleep with one: the sugars in milk linger on the teeth.",
            'Introduce a cup from around 6 months; the NHS advises discouraging bottles after age 1.',
            "No sweetened drinks or sugary milks; babies under 1 don't need fruit juice.",
            "Don't taste food from your baby's spoon, put their pacifier in your mouth, or pre-chew food for them: decay-causing bacteria can pass from an adult's mouth to the baby.",
          ),
          h('What to watch'),
          ul(
            'When the first tooth and the following ones appear.',
            'Chalky white spots on the teeth, especially along the gum line, or brown marks: signs the tooth is losing minerals, so see a dentist early.',
            "Your baby's temperature when they are fussy: measure it with a thermometer rather than assuming it's teething.",
            'White patches on the tongue or inside the cheeks with poor feeding: this may be oral thrush, so have a doctor check.',
          ),
          h('Common misconceptions'),
          ul(
            "“Clean the tongue with honey to clear thrush.” Grandparents want the baby's mouth spotless, but babies under 12 months must not have honey in any form because of the risk of botulism, and vigorous rubbing can scratch the mouth. If you see white patches, have a doctor look instead of scrubbing.",
            '“Dab honey or sugar on the gums or teether to ease the pain.” Besides the honey risk, sugar causes decay from the very first teeth. Use a clean, chilled teething ring.',
            '“An amber or mulberry-wood bracelet calms a teething baby.” The U.S. Food and Drug Administration (FDA) and the AAP warn that teething necklaces and bracelets (amber, wood, marble, silicone) have caused choking and strangulation, including deaths. It is best not to put any jewellery on your baby.',
            "“Teething gels and homeopathic teething tablets are safe.” The FDA advises against benzocaine or lidocaine products for teething and also warns about homeopathic products. The NHS doesn't rule out gels made for young children but says there is little evidence they work. The safest choice is not to use them.",
            "“Baby teeth fall out anyway, so decay doesn't matter.” Baby teeth help children chew, learn to talk and hold space for adult teeth; decayed teeth cause pain and infection. Look after baby teeth carefully, and don't let your baby sleep with a bottle at night.",
          ),
          doctor(
            'Call 115 or go to the emergency department now if',
            'Your baby chokes on a bead, a piece of a teether or a small object and struggles to breathe or turns blue (see Hóc dị vật, Choking, in the Sơ cứu trẻ em first aid guide in Child Life); has a seizure or is very drowsy and hard to wake; or has swallowed a lot of toothpaste or teething gel and seems unwell (see Uống nhầm thuốc, hoá chất, Poisoning).',
          ),
          doctor(
            'When to see a doctor',
            'Under 3 months with a temperature of 38 °C or higher, or 3–6 months with 39 °C or higher: see a doctor the same day. Book a visit for fever, diarrhoea, vomiting, refusing feeds or fewer wet diapers; very swollen gums or pus; or chalky white spots or brown marks on the teeth, or pain when eating.',
          ),
        ],
      },
      keywords: t(
        [
          'mọc răng',
          'răng sữa',
          'chảy dãi',
          'vòng ngậm nướu',
          'đánh răng',
          'kem có fluor',
          'sâu răng',
          'khám răng',
          'vòng hổ phách',
          'rơ lưỡi',
        ],
        [
          'teething',
          'baby teeth',
          'drooling',
          'teething ring',
          'toothbrushing',
          'fluoride toothpaste',
          'tooth decay',
          'first dental visit',
          'amber necklace',
          'tongue cleaning',
        ],
      ),
      relatedArticleIds: [
        'art_fever_when_to_call',
        'art_formula_bottle',
        'art_water_juice',
        'art_solids_textures_by_month',
      ],
      milestoneIds: ['mouths_objects', 'hands_to_mouth'],
      sources: [
        S.nhsTeething,
        S.eNhsTeethingTips,
        S.eHcTeethingPain,
        S.eFdaTeething,
        S.eNhsChildrenTeeth,
        S.eHcOralHealthEarly,
        S.eHcPreventDecay,
        S.eNhsDrinksCups,
      ],
    },
  },

  // ----- Phát triển, an toàn, ba mẹ (development, safety, parents) -----
  {
    id: 'art_tummy_time',
    reviewerLabel: DEV,
    data: {
      library: 'care',
      topic: 'development',
      format: 'step_guide',
      ageWeeks: { from: 0, to: 26 },
      readingMinutes: 5,
      cover: null,
      title: t(
        'Cho bé nằm sấp: bắt đầu từ ngày đầu, tăng dần từng chút',
        'Tummy time: start from day one, build up bit by bit',
      ),
      summary: t(
        'Nằm sấp khi bé thức và luôn có người lớn bên cạnh giúp bé khỏe cổ, vai, tay và giảm nguy cơ bẹt đầu. Bắt đầu vài phút mỗi lần, vài lần mỗi ngày, tăng dần theo nhịp của bé.',
        'Tummy time while your baby is awake and supervised builds neck, shoulder and arm strength and lowers the risk of a flat head. Start with a few minutes, a few times a day, and build up.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Cho bé nằm sấp khi bé thức và luôn có người lớn bên cạnh, bắt đầu ngay từ những ngày đầu về nhà: mỗi lần vài phút, vài lần mỗi ngày, rồi tăng dần. Nằm sấp giúp bé khỏe cổ, vai, tay và giảm nguy cơ bẹt đầu. Khi ngủ, bé luôn nằm ngửa.',
          ),
          h('Hiểu đúng về nằm sấp'),
          p(
            'Để phòng đột tử, bé luôn được đặt nằm ngửa khi ngủ. Vì vậy, những lúc bé thức, nằm sấp là cơ hội để bé tập ngóc đầu, chống khuỷu tay rồi chống thẳng tay, làm nền cho lật, ngồi và bò sau này. Hộp sọ của bé còn mềm, nên đổi tư thế khi thức cũng giúp phần sau đầu bớt bị đè, giảm nguy cơ bẹt đầu do tư thế.',
          ),
          p(
            'Viện Hàn lâm Nhi khoa Hoa Kỳ (AAP) hướng dẫn có thể bắt đầu từ ngày bé về nhà, 2–3 lần mỗi ngày, mỗi lần 3–5 phút, tăng dần để đạt tổng cộng 15–30 phút mỗi ngày khi bé khoảng 7 tuần tuổi. Tổ chức Y tế Thế giới (WHO) khuyến nghị trẻ dưới 1 tuổi nằm sấp ít nhất 30 phút mỗi ngày, chia thành nhiều lần khi thức, và không bị giữ một chỗ (ghế rung, xe đẩy, địu, ghế ô tô) quá 1 giờ mỗi lần. Hai hướng dẫn bổ sung cho nhau: bắt đầu ngắn, tăng dần và hướng tới ít nhất 30 phút mỗi ngày.',
          ),
          h('Ba mẹ có thể làm gì: từng bước'),
          ul(
            'Bước 1 · Chọn lúc bé tỉnh táo, vui vẻ, ví dụ sau khi thức dậy hoặc sau khi thay tã. Tránh cho nằm sấp ngay sau cữ bú no vì bé dễ khó chịu, dễ trớ sữa.',
            'Bước 2 · Những tuần đầu, bắt đầu trên ngực ba mẹ: ba mẹ ngả lưng, đặt bé nằm sấp trên ngực, mặt đối mặt; bé sẽ cố ngóc đầu để nhìn ba mẹ. Chỉ làm khi người lớn hoàn toàn tỉnh táo, không có nguy cơ ngủ quên. Cũng có thể cho bé nằm sấp ngang trên đùi.',
            'Bước 3 · Chuyển xuống sàn: trải thảm hoặc khăn sạch trên mặt sàn phẳng, chắc. Không cho bé nằm sấp trên giường cao, sofa, nệm lún hay gối.',
            'Bước 4 · Đỡ một chút nếu cần: đặt một chiếc khăn nhỏ cuộn tròn dưới ngực và nách để bé dễ chống tay. Người lớn luôn ở ngay cạnh, mắt nhìn bé.',
            'Bước 5 · Nằm xuống ngang tầm mắt bé: trò chuyện, hát, làm mặt vui; đặt gương an toàn cho trẻ em hoặc đồ chơi màu tương phản phía trước; lần lượt đặt đồ chơi bên trái rồi bên phải để bé quay đầu cả hai phía.',
            'Bước 6 · Tăng dần: bắt đầu 3–5 phút mỗi lần, 2–3 lần mỗi ngày. Bé quấy thì lật ngửa cho bé nghỉ, lát sau thử lại. Mỗi tuần thêm vài phút hoặc thêm một lần.',
            'Bước 7 · Đi theo mốc của bé: khoảng 2 tháng, bé ngẩng đầu khi nằm sấp; khoảng 4 tháng, bé chống được khuỷu tay; khoảng 6 tháng, bé chống thẳng tay và lật từ sấp sang ngửa. Khi bé đã lật, bò, hãy tiếp tục cho bé chơi tự do trên sàn an toàn.',
          ),
          tip(
            'Nếu bé không thích nằm sấp',
            'Rất nhiều bé phản đối lúc đầu, điều này bình thường. Hãy thử trên ngực hoặc đùi ba mẹ, chia thành nhiều lần thật ngắn, gắn với mỗi lần thay tã, đặt đồ chơi trong tầm với và luôn có gương mặt, giọng nói của ba mẹ trước mặt bé.',
          ),
          h('Theo dõi'),
          ul(
            'Tổng thời gian nằm sấp mỗi ngày, cộng dồn các lần ngắn.',
            'Bé có quay đầu đều sang cả hai bên không, hay luôn nghiêng hoặc quay về một phía.',
            'Hình dạng đầu khi nhìn từ trên xuống: có chỗ bẹt một bên hay bẹt phía sau không.',
            'Bé ngẩng đầu, chống tay, lật có tiến bộ dần theo tháng không.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            '“Bé chưa cứng cổ thì chưa cho nằm sấp, nằm sấp sớm hại cột sống”: ông bà lo vì thương cháu, nhưng nằm sấp chính là cách giúp cổ bé cứng cáp. AAP hướng dẫn bắt đầu ngay từ ngày bé về nhà, trên ngực ba mẹ hoặc trên sàn, khi bé thức và có người trông.',
            '“Dùng gối lõm, gối chống bẹp đầu cho đầu tròn”: gối, đệm định hình là đồ mềm không nên để trong chỗ ngủ của bé dưới 1 tuổi vì nguy cơ ngạt thở, và AAP lưu ý không có bằng chứng các sản phẩm quảng cáo “phòng đột tử” có tác dụng. Cách phòng bẹt đầu là cho bé nằm sấp khi thức, đổi bên bế, bên bú và hướng đầu khi đặt bé nằm.',
            '“Cho bé nằm võng, ghế rung hay địu, bế suốt ngày cho ngoan”: bế ẵm rất tốt cho sự gắn bó, nhưng bé cũng cần thời gian tự do trên sàn. WHO khuyên không giữ bé một chỗ quá 1 giờ mỗi lần. Nếu bé ngủ thiếp trên võng, địu hay ghế, hãy chuyển bé xuống mặt phẳng, chắc, nằm ngửa.',
            '“Cho bé ngủ sấp cho ngon giấc, đỡ giật mình”: nằm sấp chỉ dành cho lúc bé thức và có người lớn trông. Khi ngủ, kể cả giấc ngắn ban ngày, bé luôn nằm ngửa. Nếu bé thiu thiu ngủ khi đang nằm sấp, hãy nhẹ nhàng lật bé nằm ngửa.',
          ),
          doctor(
            'Khi nào nên hỏi bác sĩ',
            'Đầu bé luôn nghiêng hoặc quay về một phía, hay bé khó quay đầu sang bên kia; đầu có chỗ bẹt rõ hoặc ngày càng bẹt; khoảng 4 tháng bé vẫn chưa giữ đầu vững khi được bế, hoặc chưa chống được khuỷu tay khi nằm sấp; bé cứng đờ hoặc mềm nhũn bất thường; bé mất kỹ năng đã từng làm được. Ba mẹ cứ hỏi sớm trong lần khám định kỳ, không cần chờ.',
          ),
        ],
        en: [
          note(
            'In short',
            'Give your baby tummy time while they are awake and an adult is always beside them, starting from the first days at home: a few minutes at a time, a few times a day, then build up. Tummy time strengthens the neck, shoulders and arms and lowers the risk of a flat head. For sleep, your baby always goes on their back.',
          ),
          h('Understanding tummy time'),
          p(
            "To prevent sudden infant death, babies are always put on their back to sleep. So when your baby is awake, tummy time is their chance to practise lifting their head, pushing up on their elbows and then on straight arms, laying the groundwork for rolling, sitting and crawling. A baby's skull is still soft, so changing position while awake also takes pressure off the back of the head and lowers the risk of a positional flat head.",
          ),
          p(
            'The American Academy of Pediatrics (AAP) says you can start the day your baby comes home, 2–3 times a day for 3–5 minutes each time, building up to a total of 15–30 minutes a day by about 7 weeks of age. The World Health Organization (WHO) recommends that babies under 1 year spend at least 30 minutes a day on their tummy, spread across several awake periods, and are not kept in one place (bouncer, stroller, carrier, car seat) for more than 1 hour at a time. The two fit together: start short, build up, and aim for at least 30 minutes a day.',
          ),
          h('What you can do: step by step'),
          ul(
            'Step 1 · Pick a time when your baby is alert and content, for example after waking or after a diaper change. Avoid tummy time straight after a full feed, when your baby is more likely to be uncomfortable or spit up.',
            'Step 2 · In the first weeks, start on your chest: lean back and lay your baby tummy-down on your chest, face to face; they will try to lift their head to see you. Only do this when you are fully awake and not at risk of dozing off. You can also lay your baby tummy-down across your lap.',
            'Step 3 · Move to the floor: spread a clean mat or towel on a flat, firm floor. Avoid tummy time on a raised bed, sofa, soft mattress or pillow.',
            'Step 4 · Give a little support if needed: place a small rolled-up towel under the chest and armpits to make pushing up easier. An adult stays right beside your baby, watching.',
            "Step 5 · Get down to your baby's eye level: talk, sing and pull happy faces; put a baby-safe mirror or a high-contrast toy in front; place toys to the left and then the right so your baby turns their head both ways.",
            'Step 6 · Build up: start with 3–5 minutes at a time, 2–3 times a day. If your baby fusses, roll them onto their back for a break and try again later. Each week, add a few minutes or one more session.',
            "Step 7 · Follow your baby's milestones: by about 2 months, babies hold their head up on their tummy; by about 4 months, they push up on their elbows; by about 6 months, they push up on straight arms and roll from tummy to back. Once your baby rolls and crawls, keep giving them free play on a safe floor.",
          ),
          tip(
            "If your baby doesn't like tummy time",
            'Lots of babies protest at first, and that is normal. Try your chest or lap, break it into many very short sessions, pair it with each diaper change, put toys within reach, and keep your face and voice in front of your baby.',
          ),
          h('What to watch'),
          ul(
            'Total tummy time each day, adding up the short sessions.',
            'Whether your baby turns their head equally to both sides, or always tilts or turns to one side.',
            'The shape of the head seen from above: any flat spot on one side or at the back.',
            'Whether head lifting, pushing up and rolling improve month by month.',
          ),
          h('Common misconceptions'),
          ul(
            "“No tummy time until the neck is strong; early tummy time harms the spine”: grandparents worry out of love, but tummy time is exactly how a baby's neck gets strong. The AAP advises starting from the day your baby comes home, on your chest or on the floor, while your baby is awake and watched.",
            '“Use a hollow or anti-flat-head pillow to keep the head round”: pillows and shaped cushions are soft items that don’t belong in the sleep space of a baby under 1 because of the risk of suffocation, and the AAP notes there is no evidence that products sold to prevent sudden infant death work. Instead, give tummy time while awake and switch the side you carry and feed on and the way your baby lies.',
            '“Keep the baby in a hammock, bouncer or carrier, or held all day, so they stay calm”: holding your baby is wonderful for bonding, but babies also need free time on the floor. WHO advises not keeping a baby in one place for more than 1 hour at a time. If your baby falls asleep in a hammock, carrier or seat, move them onto a flat, firm surface, on their back.',
            '“Let the baby sleep on their tummy so they sleep better and startle less”: tummy time is only for when your baby is awake and an adult is watching. For sleep, including short daytime naps, your baby always goes on their back. If your baby gets drowsy on their tummy, gently roll them onto their back.',
          ),
          doctor(
            'When to ask a doctor',
            "Your baby always tilts or turns their head to one side, or has trouble turning it the other way; there is a clear or worsening flat spot on the head; at around 4 months your baby still can't hold their head steady when held, or can't push up on their elbows on their tummy; your baby seems unusually stiff or floppy; your baby loses a skill they once had. Ask early at a routine check-up; there is no need to wait.",
          ),
        ],
      },
      keywords: t(
        [
          'nằm sấp',
          'tập cổ',
          'ngóc đầu',
          'bẹt đầu',
          'méo đầu',
          'vận động',
          'lật',
          'gối chống bẹp đầu',
        ],
        [
          'tummy time',
          'neck strength',
          'head lifting',
          'flat head',
          'plagiocephaly',
          'motor skills',
          'rolling',
          'anti-flat-head pillow',
        ],
      ),
      relatedArticleIds: [
        'art_safe_sleep',
        'art_talk_play_first_year',
        'art_home_safety_falls',
        'art_newborn_sleep',
      ],
      milestoneIds: ['lifts_head', 'pushes_up_arms', 'rolls_over', 'reaches_for_toy'],
      sources: [
        S.hcTummyTime,
        S.whoSitLessPlayMore,
        S.nhsFlatHeadF,
        S.nhsBabyMovesF,
        S.hcSafeSleep,
        S.cdcMilestones4mF,
      ],
    },
  },
  {
    id: 'art_talk_play_first_year',
    reviewerLabel: DEV,
    data: {
      library: 'care',
      topic: 'development',
      format: 'article',
      ageWeeks: { from: 0, to: 52 },
      readingMinutes: 5,
      cover: null,
      title: t(
        'Trò chuyện, đọc sách và chơi cùng bé trong năm đầu',
        'Talking, reading and playing with your baby in the first year',
      ),
      summary: t(
        'Bé học nói và học về thế giới qua những lần “qua lại” với người lớn. Trò chuyện, đọc sách, hát và chơi mỗi ngày từ khi mới sinh, kèm gợi ý theo tháng và các dấu hiệu nên hỏi bác sĩ.',
        'Babies learn to talk and understand the world through back-and-forth moments with adults. Talk, read, sing and play every day from birth, with ideas by month and signs to ask a doctor about.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Bé học nói và học về thế giới qua những lần “qua lại” với người lớn: bé nhìn, ê a, cười, chỉ tay, và ba mẹ đáp lại. Trò chuyện, đọc sách, hát và chơi cùng bé mỗi ngày, ngay từ khi mới sinh, là món quà quý nhất. Không cần đồ chơi đắt tiền hay màn hình.',
          ),
          h('Hiểu đúng: bé học qua tương tác qua lại'),
          p(
            'Ngay từ khi mới sinh, bé đã lắng nghe giọng nói và chăm chú nhìn khuôn mặt người thân. Mỗi khi bé phát ra một “tín hiệu”, như nhìn, ê a, khóc, cười hay chỉ tay, và người lớn đáp lại, những kết nối trong não bé được xây dựng và củng cố. Trung tâm Phát triển Trẻ em của Đại học Harvard gọi đó là tương tác “giao bóng và đỡ bóng” (serve and return), giống như hai người chuyền bóng qua lại.',
          ),
          p(
            'Đọc sách cùng bé nên bắt đầu từ giai đoạn sơ sinh. AAP khuyến khích cha mẹ đọc cùng con từ khi mới sinh, vì việc này xây nền móng cho cảm xúc, nhận thức, ngôn ngữ và khả năng đọc sau này. WHO cũng khuyên những lúc bé ngồi yên, hãy đọc sách và kể chuyện cùng bé.',
          ),
          p(
            'Nếu nhà nói hai ngôn ngữ, ba mẹ cứ yên tâm. Dịch vụ Y tế Quốc gia Anh (NHS) khuyên mỗi người hãy nói với bé bằng ngôn ngữ mình thấy thoải mái nhất; trẻ thích nghi tốt khi ba và mẹ dùng hai thứ tiếng khác nhau. Điều quan trọng là bé được nghe nhiều lời nói trực tiếp, ấm áp.',
          ),
          h('Ba mẹ có thể làm gì'),
          ul(
            'Để ý xem bé đang nhìn gì, quan tâm điều gì, và cùng nhìn với bé.',
            'Đáp lại bằng nụ cười, lời nói hoặc cử chỉ, rồi gọi tên thứ bé đang nhìn: “À, con mèo! Mèo kêu meo meo.”',
            'Chờ đến lượt bé: đếm thầm vài giây để bé kịp “trả lời”, dù chỉ là một tiếng ê a hay một cái nhìn.',
            'Kể cho bé nghe ba mẹ đang làm gì khi thay tã, tắm, nấu ăn. Dùng câu ngắn, giọng ấm; nhắc lại và nói rộng thêm điều bé vừa “nói”: bé nói “bóng”, ba mẹ đáp “Đúng rồi, quả bóng đỏ”.',
            'Bắt chước âm thanh bé phát ra để bé thấy mình được lắng nghe.',
            'Khi bé quay đi, ngáp, ưỡn người hay quấy, đó là lúc bé cần nghỉ. Dừng lại, lát sau chơi tiếp.',
          ),
          h('Gợi ý chơi theo tháng'),
          ul(
            '0–3 tháng: bế bé gần, mặt đối mặt để bé ngắm; nói chuyện, hát ru; cho bé nằm sấp chơi khi thức. Khoảng 2 tháng, bé thường mỉm cười khi được nói chuyện và phát ra những âm thanh khác tiếng khóc.',
            '3–6 tháng: “nói chuyện” qua lại với tiếng ê a của bé; cho bé với, cầm lục lạc, đồ chơi; soi gương cùng bé. Khoảng 4 tháng, bé thường ê a đáp lại và quay đầu về phía giọng nói; khoảng 6 tháng, bé cười thành tiếng và thích thay phiên tạo âm thanh với ba mẹ.',
            '6–9 tháng: chơi ú òa, đập hai món đồ vào nhau, bỏ đồ vào hộp rồi lấy ra; gọi tên bé thường xuyên. Khoảng 9 tháng, bé bập bẹ “ma ma ma”, “ba ba ba”, giơ tay đòi bế và nhìn khi được gọi tên.',
            '9–12 tháng: chỉ tay và gọi tên đồ vật, vẫy tay “bye bye”, vỗ tay theo bài hát, lăn bóng qua lại. Khoảng 12 tháng, nhiều bé gọi “ba”, “mẹ” có chủ đích và hiểu chữ “không”.',
          ),
          tip(
            'Đọc sách với bé nhỏ',
            'Chọn sách bìa cứng hoặc sách vải, hình to, màu tương phản, có vần điệu. Mỗi lần chỉ vài phút; khi bé nhìn đi chỗ khác, ưỡn lưng hay quấy là lúc dừng, không cần đọc hết. Bé gặm sách hay muốn đọc đi đọc lại một quyển đều là bình thường.',
          ),
          h('Theo dõi'),
          ul(
            'Bé có giật mình hay quay về phía âm thanh, giọng nói không.',
            'Bé có đáp lại khi ba mẹ nói chuyện: nhìn, cười, ê a, bập bẹ.',
            'Các mốc giao tiếp mới theo tháng như cười thành tiếng, bập bẹ, quay lại khi được gọi tên, vẫy tay, chỉ tay. Ba mẹ có thể ghi lại các mốc này trong Child Life để mang theo khi đi khám.',
            'Bé có mất đi kỹ năng nào đã từng làm được không.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            '“Bé còn đỏ hỏn, chưa hiểu gì, nói chuyện làm gì”: bé tiếp nhận nhiều hơn ta nghĩ. Mỗi câu nói, mỗi nụ cười đáp lại đều giúp xây dựng não bộ của bé. Hãy trò chuyện với bé ngay từ những ngày đầu.',
            '“Nói hai thứ tiếng làm bé bị rối, chậm nói”: nói với bé bằng ngôn ngữ ba mẹ thoải mái nhất là tốt nhất, và trẻ thích nghi tốt với hai ngôn ngữ. Nếu lo bé chậm nói, hãy hỏi bác sĩ thay vì tự kết luận là do song ngữ.',
            '“Mở nhạc thiếu nhi, hoạt hình trên điện thoại cũng là dạy bé”: bé nhỏ học ngôn ngữ chủ yếu từ người thật nói chuyện trực tiếp với mình. WHO khuyến nghị trẻ dưới 1 tuổi không xem màn hình; gọi video với ông bà thì khác vì bé có người tương tác thật. Xem thêm bài Màn hình và phát triển ngôn ngữ.',
            '“Phải mua đồ chơi thông minh, đắt tiền thì bé mới giỏi”: nồi, thìa gỗ, hộp giấy và giọng nói của ba mẹ đã là đồ chơi tuyệt vời. Điều bé cần nhất là có người chơi cùng.',
          ),
          doctor(
            'Khi nào nên hỏi bác sĩ',
            'Hãy hỏi sớm, không cần chờ, nếu: khoảng 2 tháng bé không phản ứng với tiếng động lớn hoặc không nhìn mặt người; khoảng 4 tháng bé không ê a, không quay về phía giọng nói; khoảng 6 tháng bé không cười thành tiếng, không đáp lại khi được trò chuyện; khoảng 9 tháng bé chưa bập bẹ, không nhìn khi được gọi tên; khoảng 12 tháng bé chưa vẫy tay, chưa gọi ba mẹ; bé mất kỹ năng đã có ở bất kỳ tuổi nào; ba mẹ nghi bé nghe kém. Bác sĩ có thể cho bé đo thính lực, kể cả khi bé đã sàng lọc thính lực sơ sinh.',
          ),
        ],
        en: [
          note(
            'In short',
            'Babies learn to talk and understand the world through back-and-forth moments with adults: your baby looks, coos, smiles or points, and you respond. Talking, reading, singing and playing together every day, from birth, is the best gift you can give. No expensive toys or screens needed.',
          ),
          h('Understanding how babies learn: back and forth'),
          p(
            'From birth, babies listen to voices and study the faces of the people close to them. Each time your baby sends a signal, such as looking, cooing, crying, smiling or pointing, and an adult responds, connections in their brain are built and strengthened. The Center on the Developing Child at Harvard University calls this serve and return, like two people passing a ball back and forth.',
          ),
          p(
            'Reading together should start in the newborn period. The AAP encourages parents to read with their children from birth, because it builds the foundation for social-emotional, thinking, language and literacy skills. WHO also advises that when your baby is sitting still, you read and tell stories together.',
          ),
          p(
            "If your family speaks two languages, there's no need to worry. The UK National Health Service (NHS) advises each person to talk to the baby in the language they feel most comfortable with; children adapt well when each parent uses a different language. What matters is that your baby hears plenty of warm, face-to-face talk.",
          ),
          h('What you can do'),
          ul(
            'Notice what your baby is looking at or interested in, and look at it together.',
            'Respond with a smile, words or a gesture, then name what your baby is looking at: “Oh, a cat! The cat says meow.”',
            "Wait for your baby's turn: count a few seconds in your head so they can “answer”, even with just a coo or a look.",
            'Tell your baby what you are doing while you change a diaper, give a bath or cook. Use short sentences and a warm voice; repeat and build on what your baby “says”: your baby says “ball”, you reply “Yes, a red ball”.',
            'Copy the sounds your baby makes so they know they are being heard.',
            'When your baby looks away, yawns, arches or fusses, they need a break. Stop, and play again later.',
          ),
          h('Play ideas by month'),
          ul(
            '0–3 months: hold your baby close, face to face, so they can study you; talk and sing lullabies; give tummy time while awake. By about 2 months, babies often smile when you talk to them and make sounds other than crying.',
            '3–6 months: have “conversations” with your baby’s coos; let them reach for and hold rattles and toys; look in the mirror together. By about 4 months, babies often coo back and turn their head toward your voice; by about 6 months, they laugh out loud and enjoy taking turns making sounds with you.',
            '6–9 months: play peekaboo, bang two objects together, put things into a box and take them out; say your baby’s name often. By about 9 months, babies babble “mamama” and “bababa”, lift their arms to be picked up and look when you call their name.',
            '9–12 months: point to and name objects, wave bye-bye, clap along to songs, roll a ball back and forth. By about 12 months, many babies call a parent “mama” or “dada” on purpose and understand “no”.',
          ),
          tip(
            'Reading with little ones',
            'Choose board or cloth books with big pictures, bold contrast and rhymes. A few minutes at a time is enough; when your baby looks away, arches their back or fusses, it is time to stop, with no need to finish the book. Chewing books and wanting the same book again and again are both normal.',
          ),
          h('What to watch'),
          ul(
            'Whether your baby startles at or turns toward sounds and voices.',
            'Whether your baby responds when you talk: looking, smiling, cooing, babbling.',
            'New communication milestones month by month, such as laughing, babbling, turning when called, waving and pointing. You can log these milestones in Child Life to take along to check-ups.',
            'Whether your baby loses any skill they once had.',
          ),
          h('Common misconceptions'),
          ul(
            '“A newborn understands nothing, so why talk to them?”: babies take in more than we think. Every word and every answering smile helps build your baby’s brain. Talk with your baby from the very first days.',
            '“Two languages will confuse the baby and delay speech”: talking in the language you are most comfortable with is best, and children adapt well to two languages. If you are worried about late talking, ask a doctor rather than assuming bilingualism is the cause.',
            '“Kids’ songs and cartoons on the phone teach the baby too”: young babies learn language mainly from real people talking with them face to face. WHO recommends no screen time for babies under 1; video calls with grandparents are different because a real person is interacting with your baby. See also the article on Screens and language development.',
            '“You need smart, expensive toys for a clever baby”: pots, wooden spoons, cardboard boxes and your voice are wonderful toys. What your baby needs most is someone to play with.',
          ),
          doctor(
            'When to ask a doctor',
            "Ask early, without waiting, if: at about 2 months your baby doesn't react to loud sounds or look at faces; at about 4 months doesn't coo or turn toward your voice; at about 6 months doesn't laugh or respond when you talk; at about 9 months isn't babbling or doesn't look when you call their name; at about 12 months isn't waving or calling a parent; loses a skill they had, at any age; or you think your baby may not hear well. The doctor can arrange a hearing test, even if your baby passed newborn hearing screening.",
          ),
        ],
      },
      keywords: t(
        [
          'trò chuyện',
          'chơi cùng bé',
          'đọc sách',
          'hát ru',
          'giao tiếp',
          'ngôn ngữ',
          'song ngữ',
          'bập bẹ',
          'ú òa',
        ],
        [
          'talking',
          'play',
          'reading',
          'singing',
          'communication',
          'language',
          'bilingual',
          'babbling',
          'peekaboo',
        ],
      ),
      relatedArticleIds: ['art_screens_language', 'art_tummy_time', 'art_separation_anxiety'],
      milestoneIds: [
        'coos',
        'takes_turns_sounds',
        'babbles',
        'responds_to_name',
        'peekaboo',
        'waves_bye',
      ],
      sources: [
        S.harvardServeReturnF,
        S.hcSharedReadingF,
        S.hcShareBooksF,
        S.nhsLearnToTalkF,
        S.cdcMilestones,
        S.cdcMilestones9mF,
        S.whoSitLessPlayMore,
      ],
    },
  },
  {
    id: 'art_screens_language',
    reviewerLabel: DEV,
    data: {
      library: 'care',
      topic: 'development',
      format: 'article',
      ageWeeks: { from: 0, to: 104 },
      readingMinutes: 5,
      cover: null,
      title: t(
        'Màn hình và phát triển ngôn ngữ của bé',
        "Screens and your child's language development",
      ),
      summary: t(
        'Trẻ nhỏ học nói từ người thật, không phải từ màn hình. Khuyến nghị của WHO và AAP theo độ tuổi, cách giảm màn hình trong nhà, các hiểu lầm phổ biến và những dấu hiệu chậm nói cần đi khám.',
        'Young children learn to talk from real people, not screens. WHO and AAP guidance by age, ways to cut screens at home, common myths, and the late-talking signs that need a check-up.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Trẻ nhỏ học nói từ người thật, không phải từ màn hình. WHO khuyến nghị trẻ dưới 2 tuổi không xem màn hình, trẻ 2 tuổi không quá 1 giờ mỗi ngày, càng ít càng tốt; gọi video với người thân có người lớn ngồi cùng thì được. Tắt ti vi nền, không cho xem khi ăn, và đưa bé đi khám sớm nếu bé chậm nói.',
          ),
          h('Hiểu đúng: vì sao màn hình ảnh hưởng đến việc học nói'),
          p(
            'Bé học nói qua hàng nghìn lần trò chuyện qua lại: nhìn mặt, nghe giọng, được đáp lại. Theo AAP, não trẻ cần khoảng 18 tháng mới hiểu được rằng hình ảnh trên màn hình tượng trưng cho đồ vật thật, nên bé nhỏ học được rất ít từ video, kể cả chương trình gắn mác “giáo dục”. Xem màn hình trước 18 tháng tuổi có liên quan đến chậm phát triển ngôn ngữ, cùng các vấn đề về giấc ngủ và sự chú ý.',
          ),
          p(
            'Ti vi bật làm nền cũng ảnh hưởng: theo AAP, khi có trẻ nhỏ bên cạnh, cha mẹ thường nói khoảng 940 từ mỗi giờ, nhưng khi ti vi bật thì con số này giảm khoảng 770 từ. Điện thoại của người lớn cũng vậy: mỗi lần ba mẹ cúi vào màn hình, cuộc “chuyền bóng” với bé bị ngắt quãng.',
          ),
          p(
            'Các tổ chức có khác nhau một chút. WHO (2019): dưới 1 tuổi không xem màn hình; 1 tuổi không ngồi xem màn hình; 2 tuổi không quá 1 giờ mỗi ngày, càng ít càng tốt. AAP: tránh màn hình trước 18 tháng, trừ gọi video với người thân; sau đó nếu cho xem thì chọn nội dung dành cho trẻ, xem cùng bé và giới hạn khoảng 1 giờ mỗi ngày. Chính sách năm 2026 của AAP nhấn mạnh thêm chất lượng nội dung, bối cảnh và giữ những khoảng thời gian không màn hình như bữa ăn. Lựa chọn an toàn hơn là theo mốc chặt hơn của WHO.',
          ),
          h('Ba mẹ có thể làm gì'),
          ul(
            'Dưới 2 tuổi: tốt nhất chưa cho bé xem ti vi, điện thoại, máy tính bảng. Gọi video với ông bà, người thân ở xa thì được; người lớn ngồi cùng và chỉ cho bé ai đang nói chuyện.',
            'Nếu bé gần 2 tuổi đã có lúc xem: chọn nội dung dành cho trẻ nhỏ, nhịp chậm, không quảng cáo; ngồi cùng bé, gọi tên, đặt câu hỏi, nhắc lại điều bé thấy; xem ngắn rồi tắt hẳn.',
            'Từ 2 tuổi: tổng thời gian màn hình không quá 1 giờ mỗi ngày, càng ít càng tốt, và vẫn xem cùng bé.',
            'Tắt ti vi khi không ai xem; không bật ti vi, video làm nền khi bé chơi.',
            'Bữa ăn không màn hình: ngồi cùng bàn, trò chuyện về món ăn, màu sắc, mùi vị.',
            'Không dùng điện thoại để dỗ bé nín khóc hay ru ngủ; hãy bế, vỗ về, hát. Bé học cách bình tĩnh lại nhờ sự giúp đỡ của người lớn.',
            'Ba mẹ cất điện thoại khi cho bé bú, khi chơi và trong giờ đi ngủ của bé.',
            'Thay màn hình bằng đọc sách, hát, kể chuyện, chơi trên sàn và ra ngoài trời.',
          ),
          tip(
            'Khi bé đã quen đòi điện thoại',
            'Đừng giật lấy đột ngột. Báo trước: “Xem hết bài này mình cất nhé”, rồi chuyển ngay sang một việc bé thích như đọc sách, chơi bóng. Cất thiết bị khỏi tầm mắt bé, và cả nhà, kể cả ông bà, cùng thống nhất một cách làm.',
          ),
          h('Theo dõi'),
          ul(
            'Tổng thời gian bé tiếp xúc với màn hình mỗi ngày, kể cả ti vi bật nền và lúc ăn.',
            'Bé có quay lại khi được gọi tên, có chỉ tay để đòi hay để khoe, có bắt chước âm thanh, lời nói không.',
            'Số từ bé nói được và khi nào bé bắt đầu ghép hai từ. Ghi lại các mốc này trong Child Life giúp ba mẹ trao đổi với bác sĩ dễ hơn.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            '“Cho xem YouTube, hoạt hình tiếng Anh để bé giỏi ngoại ngữ”: trẻ nhỏ học được rất ít từ video; ngôn ngữ đến từ trò chuyện trực tiếp. Hãy nói với bé thật nhiều bằng ngôn ngữ ba mẹ thoải mái nhất. Nếu muốn bé học thêm một thứ tiếng, cách hiệu quả là có người thật nói chuyện, đọc sách, hát với bé bằng ngôn ngữ đó.',
            '“Vừa ăn vừa xem điện thoại thì bé mới chịu ăn”: ông bà, ba mẹ làm vậy vì sợ bé đói, nhưng AAP khuyên không dùng màn hình để đánh lạc hướng khi bé ăn, để màn hình không trở thành cách duy nhất giúp bé bình tĩnh. Bữa ăn còn là lúc bé học từ mới. Hãy tắt màn hình, cho bé ăn từng ít một và theo tín hiệu đói, no của bé.',
            '“Con trai chậm nói, quý nhân chậm nói, cứ chờ”: theo AAP, khoảng 1 trong 5 trẻ biết nói muộn hơn bạn cùng tuổi và chậm nói đơn thuần đôi khi chỉ là tạm thời, nhưng chậm nói cũng có thể là dấu hiệu của nghe kém, chậm phát triển hoặc rối loạn phổ tự kỷ. Các mốc cần đi khám áp dụng cho mọi bé, trai hay gái. CDC khuyên “hành động sớm”: đi khám không mất gì, còn chờ đợi có thể làm chậm việc hỗ trợ bé.',
            '“Bật ti vi cho vui nhà, bé có xem đâu”: ngay cả khi không ai xem, ti vi nền vẫn làm người lớn nói với bé ít đi rất nhiều và khiến bé khó tập trung chơi. Hãy tắt khi không xem.',
          ),
          doctor(
            'Khi nào nên đưa bé đi khám (đo thính lực, đánh giá phát triển)',
            'Khoảng 12 tháng bé chưa bập bẹ, chưa dùng cử chỉ như vẫy tay “bye bye”; khoảng 15 tháng chưa nói từ nào ngoài “ba”, “mẹ” hoặc chưa chỉ tay để đòi; khoảng 18 tháng chưa nói được ít nhất 3 từ; 2 tuổi chưa ghép hai từ như “uống sữa”; bé không quay lại khi được gọi tên; bé mất kỹ năng nói hay giao tiếp đã có, ở bất kỳ tuổi nào. Bác sĩ có thể cho bé đo thính lực, kể cả khi bé đã sàng lọc thính lực sơ sinh, và giới thiệu đánh giá ngôn ngữ.',
          ),
        ],
        en: [
          note(
            'In short',
            'Young children learn to talk from real people, not screens. WHO recommends no screen time under 2 and no more than 1 hour a day at age 2, with less being better; video calls with family, with an adult alongside, are fine. Turn off background TV, keep screens away from meals, and see a doctor early if your child is late to talk.',
          ),
          h('Understanding why screens affect learning to talk'),
          p(
            "Babies learn to talk through thousands of back-and-forth exchanges: watching faces, hearing voices, being answered. According to the AAP, it takes around 18 months for a child's brain to understand that pictures on a screen stand for real things, so babies learn very little from videos, even ones labelled “educational”. Screen viewing before 18 months is linked to delays in language development, as well as problems with sleep and attention.",
          ),
          p(
            "Background TV matters too: according to the AAP, parents speak about 940 words an hour around a young child, but with the TV on this drops by about 770 words. Adults' phones are similar: every time you look down at a screen, the game of catch with your baby is interrupted.",
          ),
          p(
            "The guidelines differ slightly. WHO (2019): no screen time under 1; no sedentary screen time at age 1; no more than 1 hour a day at age 2, less is better. AAP: avoid screens before 18 months, except video calls with family; after that, if you allow screens, choose content made for young children, watch together and keep it to about 1 hour a day. The AAP's 2026 policy adds emphasis on content quality, context and keeping screen-free times such as meals. The safer choice is to follow WHO's stricter limits.",
          ),
          h('What you can do'),
          ul(
            'Under 2: ideally no TV, phone or tablet viewing yet. Video calls with grandparents and family far away are fine; an adult sits alongside and shows your child who is talking.',
            'If your child, nearly 2, already watches sometimes: choose slow-paced content made for young children without ads; sit together, name things, ask questions, repeat what they see; keep it short, then switch off completely.',
            'From age 2: no more than 1 hour of screen time a day in total, less is better, still watching together.',
            "Turn the TV off when nobody is watching; don't leave TV or videos on in the background while your child plays.",
            'Screen-free meals: sit at the table together and talk about the food, its colours, smells and tastes.',
            "Don't use a phone to stop crying or to get your child to sleep; hold, soothe and sing instead. Children learn to calm down with an adult's help.",
            "Put your phone away during feeds, playtime and your child's bedtime.",
            'Swap screens for books, songs, stories, floor play and time outdoors.',
          ),
          tip(
            'When your child is used to asking for the phone',
            "Don't snatch it away suddenly. Give a warning: “When this song ends, we'll put it away”, then move straight to something your child enjoys, like a book or a ball game. Keep devices out of sight, and agree on one approach as a family, grandparents included.",
          ),
          h('What to watch'),
          ul(
            'Total screen exposure each day, including background TV and mealtimes.',
            'Whether your child turns when called by name, points to ask for or show things, and copies sounds and words.',
            'How many words your child says and when they start putting two words together. Logging these milestones in Child Life makes it easier to talk them through with a doctor.',
          ),
          h('Common misconceptions'),
          ul(
            '“English cartoons and YouTube will make my child good at languages”: young children learn very little from video; language comes from face-to-face conversation. Talk with your child a lot in the language you are most comfortable with. If you want your child to learn another language, the effective way is a real person talking, reading and singing with them in that language.',
            '“My child only eats while watching the phone”: families do this out of worry that the child will go hungry, but the AAP advises against using screens to distract children while eating, so screens do not become their only way to calm down. Mealtimes are also a time to learn new words. Switch off, offer small amounts and follow your child’s hunger and fullness cues.',
            '“Boys talk late; late talkers are lucky, just wait”: according to the AAP, about 1 in 5 children talk later than their peers and a simple delay is sometimes temporary, but late talking can also signal hearing loss, developmental delay or autism spectrum disorder. The check-up milestones apply to every child, boy or girl. The CDC says “act early”: waiting can delay help.',
            "“The TV is just on for company; the baby isn't watching”: even when nobody is watching, background TV makes adults talk to children much less and makes it harder for children to focus on play. Turn it off when it isn't being watched.",
          ),
          doctor(
            'When to see a doctor (hearing test, developmental check)',
            "At about 12 months your child isn't babbling or using gestures like waving bye-bye; at about 15 months says no words besides “mama” or “dada”, or doesn't point to ask for things; at about 18 months doesn't say at least 3 words; at 2 years doesn't put two words together, like “more milk”; doesn't turn when called by name; or loses speech or social skills they had, at any age. The doctor can arrange a hearing test, even if your child passed newborn hearing screening, and refer for a language assessment.",
          ),
        ],
      },
      keywords: t(
        [
          'màn hình',
          'ti vi',
          'điện thoại',
          'YouTube',
          'chậm nói',
          'ngôn ngữ',
          'ti vi nền',
          'vừa ăn vừa xem',
          'đo thính lực',
          'gọi video',
        ],
        [
          'screens',
          'TV',
          'phone',
          'YouTube',
          'late talking',
          'language',
          'background TV',
          'eating with screens',
          'hearing test',
          'video calls',
        ],
      ),
      relatedArticleIds: ['art_talk_play_first_year', 'art_sleep_by_age', 'art_separation_anxiety'],
      milestoneIds: [
        'babbles',
        'responds_to_name',
        'first_word',
        'points_to_ask',
        'says_three_words',
        'two_word_phrases',
      ],
      sources: [
        S.whoSitLessPlayMore,
        S.hcAvoidTvF,
        S.hcInfantScreens5CsF,
        S.hcDigitalWorld2026F,
        S.hcLanguageDelayF,
        S.cdcMilestones15mF,
        S.cdcMilestones2yF,
        S.nhsLearnToTalkF,
      ],
    },
  },
  {
    id: 'art_separation_anxiety',
    reviewerLabel: DEV,
    data: {
      library: 'care',
      topic: 'development',
      format: 'article',
      ageWeeks: { from: 26, to: 104 },
      readingMinutes: 5,
      cover: null,
      title: t(
        'Bé bám ba mẹ, sợ người lạ: hiểu và đồng hành cùng bé',
        'Clinginess and fear of strangers: understanding and supporting your child',
      ),
      summary: t(
        'Lo âu xa cách và ngại người lạ là giai đoạn phát triển bình thường, rõ nhất quanh 9–18 tháng. Cách chào tạm biệt, tập xa nhau, chuẩn bị đi nhà trẻ và khi nào nên hỏi bác sĩ.',
        'Separation anxiety and wariness of strangers are a normal stage, strongest around 9–18 months. How to say goodbye, practise being apart, prepare for childcare, and when to ask a doctor.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Bé khóc, bám ba mẹ khi phải xa hay sợ người lạ là một giai đoạn phát triển bình thường, thường rõ quanh 9 tháng và dịu dần khi bé 2–3 tuổi. Chào tạm biệt ngắn gọn, không lén đi, giữ lời hứa quay lại và tập xa nhau từng chút sẽ giúp bé thấy an toàn.',
          ),
          h('Hiểu đúng về lo âu xa cách'),
          p(
            'Khoảng giữa năm đầu, bé dần hiểu rằng người và đồ vật vẫn tồn tại khi khuất khỏi tầm mắt. Bé biết ba mẹ đi đến một nơi bé không theo được, nhưng chưa hiểu rằng ba mẹ sẽ quay lại. Vì vậy bé khóc, bám chặt, đòi theo. Đây là dấu hiệu bé đã gắn bó với người chăm sóc mình, không phải bé “hư”.',
          ),
          p(
            'Theo NHS, lo âu xa cách rất thường gặp từ khoảng 6 tháng đến 3 tuổi và thường hết khi bé khoảng 2–3 tuổi. AAP cho biết phần lớn bé thể hiện rõ quanh 9 tháng, và nhiều bé có thêm một đợt quanh 15–18 tháng. Cùng giai đoạn này, bé hay ngại người lạ: theo CDC, khoảng 9 tháng nhiều bé rụt rè, bám ba mẹ hoặc sợ hãi khi gặp người lạ, và phản ứng (nhìn theo, với tay, khóc) khi ba mẹ rời đi. Bé đói, mệt hay ốm thì càng khó xa ba mẹ hơn.',
          ),
          h('Ba mẹ có thể làm gì'),
          ul(
            'Tập xa nhau từng chút: bắt đầu bằng vài phút để bé ở với người quen trong nhà, rồi kéo dài dần, sau đó thử ở nơi ít quen hơn.',
            'Chơi ú òa, giấu đồ chơi dưới khăn cho bé tìm: những trò này giúp bé hiểu “khuất đi rồi sẽ quay lại”.',
            'Tạo nghi thức chào tạm biệt ngắn và giống nhau mỗi ngày: ôm, hôn, một câu chào quen thuộc rồi đi. Chào vui vẻ, tự tin, vì bé cảm nhận được nỗi lo của ba mẹ.',
            'Không lén đi khi bé không để ý. Hãy luôn chào bé, kể cả khi biết bé sẽ khóc.',
            'Nói thời gian theo cách bé hiểu, như “Con ngủ trưa dậy là mẹ về”, và giữ đúng lời hứa.',
            'Đã chào thì đi, không quay lại “thăm” giữa chừng, vì bé sẽ phải chia tay thêm một lần nữa.',
            'Chọn lúc bé đã ăn no, ngủ đủ cho những lần tập xa nhau; tránh lúc bé đang ốm.',
            'Để lại một vật gợi nhớ như áo có mùi của mẹ, ảnh gia đình hay đồ chơi yêu thích. Với bé dưới 12 tháng, vật mềm này chỉ dùng khi bé thức; không để gối, thú bông, chăn mềm trong chỗ ngủ của bé.',
            'Với người lạ: để bé quan sát từ trong vòng tay ba mẹ, cho bé thời gian làm quen, không ép bé để người lạ bế.',
            'Khi bắt đầu đi nhà trẻ hay có người trông mới: cho bé làm quen dần vài buổi có ba mẹ ở cùng, giữ cùng một người đưa đón và một nếp sinh hoạt ổn định.',
          ),
          tip(
            'Câu nói gợi ý khi chào',
            '“Mẹ đi làm đây. Con chơi với bà nhé. Con ngủ trưa dậy là mẹ về đón. Mẹ thương con!” Nói xong, ôm bé, trao bé cho người chăm sóc và đi, dù bé đang khóc. Sau đó hỏi người trông xem bé dịu lại sau bao lâu.',
          ),
          h('Theo dõi'),
          ul(
            'Sau khi ba mẹ đi, bé cần bao lâu để bình tĩnh lại (hỏi người trông bé).',
            'Những điều làm bé khó xa hơn: đói, buồn ngủ, ốm, mới chuyển nhà, có người chăm mới.',
            'Bé có quen dần qua từng tuần không, có chơi, ăn, ngủ được khi ba mẹ vắng mặt không.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            '“Lẻn đi lúc bé không để ý cho đỡ khóc”: cách này khiến bé lo rằng ba mẹ có thể biến mất bất cứ lúc nào, nên bé càng bám hơn và khó tin rằng ba mẹ sẽ quay lại. Chào ngắn gọn rồi đi giúp bé an tâm hơn về lâu dài.',
            '“Dọa ông kẹ, ba bị, công an bắt cho bé nín”: người lớn dọa vì muốn bé nín nhanh, nhưng thêm nỗi sợ vào lúc bé đang lo xa ba mẹ chỉ làm bé bất an hơn. Hãy gọi tên cảm xúc: “Con buồn vì mẹ đi làm, mẹ hiểu”, rồi vỗ về bé.',
            '“Cứ để bé khóc cho quen, dỗ nhiều thành hư”: được đáp lại khi cần giúp bé cảm thấy an toàn và dần tự tin xa ba mẹ hơn. Tập xa nhau từng chút, có người quen dỗ dành, khác hẳn với bỏ mặc bé khóc một mình.',
            '“Bé bám mẹ là do chiều quá, bế nhiều”: theo NHS, lo âu xa cách là một giai đoạn phát triển bình thường. Bé bám ba mẹ vì bé đã gắn bó, không phải vì được thương nhiều. Sự ân cần của ba mẹ là nền tảng để bé mạnh dạn khám phá sau này.',
          ),
          doctor(
            'Khi nào nên hỏi bác sĩ',
            'Bé quá hoảng sợ mỗi lần xa ba mẹ, khóc rất lâu sau khi ba mẹ đi, hoặc tình trạng kéo dài nhiều tuần không đỡ; lo âu nặng ảnh hưởng đến ăn, ngủ, sinh hoạt, nhất là sau 3 tuổi; bé ít nhìn mắt, không cười đáp, không quay lại khi được gọi tên, chưa chỉ tay hay vẫy tay khoảng 12–15 tháng; bé mất kỹ năng đã có. Nếu bé đột ngột sợ hãi một người hay một nơi cụ thể, hoặc có vết thương không rõ lý do, hãy cho bé đi khám; ở Việt Nam, ba mẹ có thể gọi Tổng đài quốc gia bảo vệ trẻ em 111 (miễn phí).',
          ),
        ],
        en: [
          note(
            'In short',
            'Crying and clinging when apart, or fear of strangers, is a normal stage of development, usually strongest around 9 months and easing by age 2–3. Short goodbyes, never sneaking away, keeping your promise to come back and practising being apart bit by bit help your child feel safe.',
          ),
          h('Understanding separation anxiety'),
          p(
            "Around the middle of the first year, babies start to understand that people and things still exist when out of sight. Your baby knows you are going somewhere they can't follow, but doesn't yet understand that you will come back. So they cry, cling and want to follow. It is a sign that your baby has bonded with the people who care for them, not that they are being “naughty”.",
          ),
          p(
            'According to the NHS, separation anxiety is very common from about 6 months to 3 years and usually stops at around age 2–3. The AAP says most babies show it clearly around 9 months, and many have another wave around 15–18 months. In the same period babies are often wary of strangers: according to the CDC, at about 9 months many babies are shy, clingy or fearful around strangers, and react (look, reach or cry) when a parent leaves. Hunger, tiredness or illness make separations harder.',
          ),
          h('What you can do'),
          ul(
            'Practise being apart bit by bit: start with a few minutes with someone familiar at home, then stretch the time, then try less familiar places.',
            'Play peekaboo and hide a toy under a cloth for your baby to find: these games help them learn that things that disappear come back.',
            "Create a short goodbye ritual that is the same every day: a hug, a kiss, a familiar phrase, then go. Say goodbye cheerfully and confidently, because babies pick up on a parent's worry.",
            'Never sneak away when your child is not looking. Always say goodbye, even if you know there will be tears.',
            'Describe time in ways your child understands, such as “I’ll be back when you wake up from your nap”, and keep your promise.',
            'Once you have said goodbye, leave; don’t come back to “visit” midway, because your child would have to say goodbye all over again.',
            'Practise separations when your child is fed and rested; avoid times when they are unwell.',
            'Leave something that reminds your child of you, such as a top that smells of you, a family photo or a favourite toy. For babies under 12 months, use a soft comfort item only while awake; no pillows, soft toys or soft blankets in the sleep space.',
            'With strangers: let your child watch from your arms, give them time to warm up, and don’t make them go to a stranger.',
            'When starting childcare or a new carer: build up over a few sessions with you there, keep the same person doing drop-off and pick-up, and keep a steady routine.',
          ),
          tip(
            'What you might say at goodbye',
            '“Mummy’s going to work now. You play with Grandma. When you wake up from your nap, I’ll come and get you. I love you!” Then give a hug, hand your child to their carer and go, even if they are crying. Later, ask the carer how long it took your child to settle.',
          ),
          h('What to watch'),
          ul(
            'How long your child takes to calm down after you leave (ask the carer).',
            'What makes separations harder: hunger, tiredness, illness, a recent move, a new carer.',
            'Whether your child gets used to it week by week, and can play, eat and sleep while you are away.',
          ),
          h('Common misconceptions'),
          ul(
            '“Sneak away while the baby isn’t looking so there are no tears”: this makes children worry that you could vanish at any moment, so they cling more and find it harder to trust that you will come back. A short goodbye and then leaving helps them feel more secure in the long run.',
            '“Threaten the bogeyman or the police to stop the crying”: adults say this hoping the child will stop quickly, but adding fear when a child is already anxious about separation only makes them more insecure. Name the feeling instead: “You’re sad because Mummy’s going to work, I understand”, then comfort your child.',
            '“Just let them cry it out; too much comforting spoils them”: being responded to when they need it helps children feel safe and gradually more confident about being apart. Practising separations bit by bit, with a familiar person to comfort them, is very different from leaving a child to cry alone.',
            '“The baby is clingy because they’re spoilt and held too much”: according to the NHS, separation anxiety is a normal stage of development. Children cling because they have bonded, not because they are loved too much. Your warmth is the foundation for confident exploring later on.',
          ),
          doctor(
            'When to ask a doctor',
            'Your child is extremely distressed at every separation, stays upset for a long time after you leave, or it goes on for weeks without improving; anxiety is severe and affects eating, sleeping or daily life, especially after age 3; your child makes little eye contact, doesn’t smile back, doesn’t turn when called, or isn’t pointing or waving by about 12–15 months; or loses skills they had. If your child suddenly fears a particular person or place, or has unexplained injuries, have them checked; in Việt Nam you can also call the national child protection hotline 111 (free).',
          ),
        ],
      },
      keywords: t(
        [
          'lo âu xa cách',
          'bám mẹ',
          'sợ người lạ',
          'đi nhà trẻ',
          'chào tạm biệt',
          'khóc khi mẹ đi',
          'gắn bó',
        ],
        [
          'separation anxiety',
          'clingy',
          'fear of strangers',
          'starting childcare',
          'saying goodbye',
          'crying when parent leaves',
          'attachment',
        ],
      ),
      relatedArticleIds: [
        'art_sleep_by_age',
        'art_talk_play_first_year',
        'art_safe_sleep',
        'art_parent_wellbeing',
      ],
      milestoneIds: ['stranger_wariness', 'peekaboo', 'finds_hidden', 'checks_back'],
      sources: [
        S.hcSeparationAnxietyF,
        S.nhsSeparationAnxietyF,
        S.nhsChildAnxietyF,
        S.zttSeparationAnxietyF,
        S.cdcMilestones9mF,
        S.hcSafeSleep,
        S.vnChildHotline111F,
      ],
    },
  },
  {
    id: 'art_home_safety_falls',
    reviewerLabel: PAEDS,
    data: {
      library: 'care',
      topic: 'daily_care',
      format: 'article',
      ageWeeks: { from: 0, to: 104 },
      readingMinutes: 6,
      cover: null,
      title: t(
        'An toàn trong nhà: phòng ngã, đuối nước, bỏng và ngộ độc',
        'Home safety: preventing falls, drowning, burns and poisoning',
      ),
      summary: t(
        'Những việc cụ thể để phòng ngã, đuối nước, bỏng, ngộ độc và hóc cho bé dưới 2 tuổi, cách theo dõi sau khi bé ngã đập đầu và khi nào phải gọi 115.',
        'Practical steps to prevent falls, drowning, burns, poisoning and choking for children under 2, how to watch your child after a bump to the head, and when to call 115.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Nhiều tai nạn của trẻ nhỏ xảy ra ngay trong nhà và có thể phòng được. Không bao giờ để bé một mình trên giường, sofa hay bàn thay tã; chặn cầu thang, cửa sổ, ban công; đổ bỏ hoặc đậy kín mọi vật chứa nước; cất thuốc, hóa chất, pin cúc áo; để đồ nóng xa tầm tay bé. Mỗi khi bé biết thêm một kỹ năng vận động, hãy rà soát lại nhà.',
          ),
          h('Hiểu đúng: vì sao bé dễ gặp tai nạn trong nhà'),
          p(
            'Kỹ năng của bé thay đổi rất nhanh: hôm nay bé chỉ nằm yên, ngày mai bé có thể lật lần đầu; vài tháng sau bé đã bò, vịn đứng, leo trèo và cho mọi thứ vào miệng. Bé chưa biết sợ độ cao, nước hay đồ nóng. Người lớn không thể nhìn bé suốt 24 giờ, nên cách hiệu quả là vừa trông bé, vừa làm cho ngôi nhà an toàn hơn.',
          ),
          p(
            'Ở Việt Nam, theo Bộ Y tế và WHO, đuối nước vẫn là một trong những nguyên nhân gây tử vong hàng đầu ở trẻ em. Với trẻ nhỏ, nguy cơ không chỉ ở sông, ao, hồ: bé có thể chết đuối chỉ trong 5 cm nước, tức là trong chậu tắm, xô, thau, chum, lu hay bể nước ngay trong nhà.',
          ),
          h('Ba mẹ có thể làm gì: phòng ngã'),
          ul(
            'Thay tã trên tấm lót đặt dưới sàn. Không để bé một mình trên giường, sofa hay bàn thay tã dù chỉ một giây, kể cả khi bé “chưa biết lật”.',
            'Đặt ghế rung, nôi xách tay, ghế ô tô của bé dưới sàn, không đặt trên bàn, kệ bếp hay giường.',
            'Lắp cửa chặn an toàn ở đầu và chân cầu thang trước khi bé biết bò.',
            'Cửa sổ: lắp khóa hoặc chốt hãm để cửa chỉ mở được dưới 6,5 cm. Ban công, lan can, tay vịn cầu thang có khe hở rộng hơn 6,5 cm thì che bằng tấm chắn hoặc lưới an toàn. Không kê ghế, giường, bàn, chậu cây sát cửa sổ hay lan can để bé không trèo lên được.',
            'Bắt vít cố định tủ, kệ sách, tủ quần áo vào tường; đặt ti vi trên kệ thấp, chắc chắn, đẩy sát vào trong hoặc gắn lên tường.',
            'Không dùng xe tập đi có bánh xe.',
          ),
          h('Phòng đuối nước và bỏng'),
          ul(
            'Luôn ở trong tầm với của bé suốt thời gian tắm và đổ nước ngay sau khi tắm xong. Nếu phải rời đi, dù chỉ một lát, hãy bế bé theo.',
            'Xô, chậu, thau, chum, lu, bể nước: đổ hết nước sau khi dùng hoặc đậy nắp chắc chắn mà bé không mở được; đóng cửa nhà tắm, nhà vệ sinh.',
            'Không bế bé khi đang cầm đồ uống nóng hay bát canh nóng. Đồ uống nóng vẫn có thể gây bỏng 15 phút sau khi pha.',
            'Ấm siêu tốc, phích nước, nồi cơm điện đặt sâu vào trong, xa mép bàn, dây điện không thòng xuống. Nấu bằng bếp phía trong và xoay cán nồi vào trong.',
            'Không dùng khăn trải bàn mà bé có thể kéo khi trên bàn đang có đồ nóng.',
            'Pha nước tắm: cho nước lạnh trước rồi thêm nước nóng, thử bằng khuỷu tay trước khi cho bé vào.',
          ),
          h('Phòng ngộ độc, hóc và các nguy cơ khác'),
          ul(
            'Thuốc, kể cả thuốc bổ và thuốc của ông bà, khóa trong tủ hoặc để trên cao, khuất tầm mắt bé.',
            'Nước tẩy, nước lau sàn, dầu hỏa, thuốc diệt côn trùng để trên cao hoặc trong tủ có chốt; không bao giờ chiết sang chai nước uống.',
            'Pin cúc áo (trong điều khiển, đồ chơi, cân điện tử) và nam châm nhỏ phải cất xa bé; nếu nuốt phải, chúng có thể gây bỏng và tổn thương nặng bên trong cơ thể.',
            'Đồ vật nhỏ như cúc áo, đồng xu, hạt, nắp chai, bóng bay xẹp: mẹo kiểm tra nhanh là món nào lọt qua lõi cuộn giấy vệ sinh thì quá nhỏ, có thể gây hóc, hãy cất đi.',
            'Dây rèm, dây mành buộc gọn trên cao và cố định vào tường; giữ dây sạc, dây điện xa giường, cũi của bé.',
            'Ổ điện thấp dùng nắp che; rút điện các thiết bị khi không dùng.',
            'Nếu có thể, lắp thiết bị báo khói và kiểm tra hằng tháng.',
          ),
          tip(
            'Mẹo: nhìn nhà bằng tầm mắt của bé',
            'Hãy bò một vòng quanh nhà ở độ cao của bé. Ba mẹ sẽ thấy những thứ bé có thể với tới, kéo xuống, chui vào hay cho vào miệng. Lặp lại mỗi khi bé biết lật, bò, vịn đứng hay leo trèo.',
          ),
          h('Theo dõi'),
          ul(
            'Kỹ năng vận động sắp tới của bé (lật, bò, vịn đứng, đi, leo) để chuẩn bị trước, không đợi đến khi bé đã làm được.',
            'Sau mỗi lần bé ngã hay va đập đầu, có người lớn ở cạnh theo dõi bé ít nhất 24 giờ: bé có tỉnh táo, bú ăn, chơi như bình thường không, có nôn, lừ đừ hay quấy khác thường không. Bé vẫn có thể ngủ bình thường nếu mệt.',
            'Ghi lại giờ, độ cao, bé ngã xuống mặt gì và các dấu hiệu sau đó để kể với bác sĩ khi cần.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            '“Bé chưa biết lật, đặt trên giường một chút không sao”: lần lật đầu tiên có thể xảy ra bất cứ lúc nào, đúng lúc ba mẹ quay đi. Khi cần rời tay, hãy đặt bé xuống sàn hoặc vào cũi.',
            '“Xe tập đi giúp bé nhanh biết đi”: theo AAP, xe tập đi không giúp bé biết đi mà còn có thể làm bé biết đi muộn hơn; bé có thể lao xuống cầu thang, với tới đồ nóng, hóa chất, thậm chí rơi xuống nước. AAP kêu gọi cấm sản xuất và bán xe tập đi có bánh xe, và Canada đã cấm loại xe này. Thay vào đó, cho bé chơi trên sàn và vịn đồ đạc chắc chắn để tập đứng.',
            '“Chum, lu, xô nước trong nhà thấp, bé không với tới đâu”: bé biết bò, vịn đứng có thể chúi đầu vào trong; chỉ 5 cm nước đã đủ gây đuối nước. Hãy đậy kín hoặc đổ bỏ.',
            '“Bé ngã đập đầu thì lăn trứng gà, xoa dầu là khỏi”: ông bà làm vì thương cháu, nhưng các cách này không giúp phát hiện chấn thương bên trong. Hãy chườm lạnh bằng túi đá bọc khăn từng đợt ngắn và quan sát kỹ các dấu hiệu nguy hiểm bên dưới. Đừng cho rằng bé nôn chỉ vì “sợ”: nôn sau va đập là lý do để đưa bé đi khám.',
          ),
          doctor(
            'Gọi 115 hoặc đến cấp cứu ngay khi',
            'Sau va đập đầu: bé bất tỉnh, li bì, khó đánh thức hoặc co giật; ngã từ độ cao trên 1 mét hay hơn 5 bậc cầu thang; bé dưới 1 tuổi có bầm, sưng hay vết rách lớn trên đầu; chảy dịch trong hoặc máu từ tai, mũi; đầu có chỗ lõm; bé thay đổi hành vi, yếu tay chân. Nghi bé nuốt pin cúc áo, nam châm, uống nhầm thuốc hay hóa chất; bé bị đuối nước, kể cả khi đã tỉnh lại. Trong lúc chờ, xem mục Sơ cứu trẻ em của Child Life (Hồi sức tim phổi, Uống nhầm thuốc, hoá chất, Bỏng nước sôi, Gãy xương).',
          ),
          doctor(
            'Đưa bé đi khám trong ngày khi',
            'Bé nôn sau khi bị va đập đầu; bé đau, không chịu cử động tay hay chân sau khi ngã; bé bị bỏng; hoặc ba mẹ thấy lo lắng vì bất kỳ điều gì sau một tai nạn.',
          ),
        ],
        en: [
          note(
            'In short',
            'Many accidents involving young children happen at home, and they can be prevented. Never leave your baby alone on a bed, sofa or changing table; block stairs, windows and balconies; empty or tightly cover anything holding water; lock away medicines, chemicals and button batteries; keep hot things out of reach. Each time your child learns a new movement skill, check your home again.',
          ),
          h('Understanding why young children have accidents at home'),
          p(
            "Your baby's skills change very fast: today they lie still, tomorrow they may roll for the first time; a few months later they crawl, pull to stand, climb and put everything in their mouth. They have no sense of danger around heights, water or heat. No adult can watch a child every second, so the effective approach is to supervise and make your home safer.",
          ),
          p(
            'In Vietnam, according to the Ministry of Health and WHO, drowning remains a leading cause of death among children. For young children the risk isn’t only rivers, ponds and lakes: a baby can drown in as little as 5 cm of water, which means a bath, bucket, basin, water jar or water tank inside the home.',
          ),
          h('What you can do: preventing falls'),
          ul(
            'Change diapers on a mat on the floor. Never leave your baby alone on a bed, sofa or changing table, even for a second, even if they “can’t roll yet”.',
            'Keep bouncers, carry cots and car seats on the floor, never on a table, kitchen counter or bed.',
            'Fit safety gates at the top and bottom of stairs before your baby starts crawling.',
            'Windows: fit locks or catches so they open less than 6.5 cm. Cover gaps wider than 6.5 cm in balconies, railings and banisters with boards or safety netting. Keep chairs, beds, tables and plant pots away from windows and railings so your child can’t climb up.',
            'Screw cabinets, bookcases and wardrobes to the wall; put the TV on a low, sturdy stand pushed well back, or mount it on the wall.',
            "Don't use a baby walker with wheels.",
          ),
          h('Preventing drowning and burns'),
          ul(
            'Stay within reach for the whole bath and empty the water as soon as you finish. If you have to step away, even briefly, take your baby with you.',
            'Buckets, basins, tubs, water jars and tanks: empty them after use or cover them with a lid your child cannot open; keep bathroom and toilet doors shut.',
            "Don't hold your baby while holding a hot drink or a bowl of hot soup. A hot drink can still scald 15 minutes after it was made.",
            'Push electric kettles, thermos flasks and rice cookers well back from the edge, with no cords hanging down. Cook on the back burners and turn pan handles inward.',
            'Avoid tablecloths your child could pull while there is something hot on the table.',
            'Running a bath: put cold water in first, then add hot, and test with your elbow before your baby goes in.',
          ),
          h('Preventing poisoning, choking and other hazards'),
          ul(
            "Lock medicines away or keep them high up and out of sight, including supplements and grandparents' medicines.",
            'Keep bleach, floor cleaner, kerosene and insect sprays high up or in a latched cupboard; never decant them into drinking bottles.',
            'Keep button batteries (in remotes, toys, kitchen scales) and small magnets away from children; if swallowed, they can cause burns and serious internal injury.',
            'Small objects such as buttons, coins, beads, bottle caps and deflated balloons: a quick check is that anything that passes through a toilet-roll tube is too small and a choking risk, so put it away.',
            "Tie blind and curtain cords up high and fix them to the wall; keep charger and electrical cords away from your child's bed or crib.",
            'Cover low power sockets; unplug appliances when not in use.',
            'If you can, fit a smoke alarm and test it every month.',
          ),
          tip(
            "Tip: see your home from your child's eye level",
            'Crawl around your home at your child’s height. You will spot things they could reach, pull down, crawl into or put in their mouth. Repeat each time your child learns to roll, crawl, pull up or climb.',
          ),
          h('What to watch'),
          ul(
            "Your child's next movement skills (rolling, crawling, pulling up, walking, climbing), so you can prepare ahead rather than after they've happened.",
            'After any fall or bump to the head, have an adult stay with your child for at least 24 hours: are they alert, feeding, eating and playing as usual; any vomiting, drowsiness or unusual fussiness? Your child can still sleep normally if tired.',
            'Note the time, the height, what your child landed on and any signs afterwards, to tell the doctor if needed.',
          ),
          h('Common misconceptions'),
          ul(
            '“The baby can’t roll yet, a moment on the bed is fine”: the first roll can happen at any time, just as you turn away. When you need your hands free, put your baby on the floor or in the crib.',
            '“A baby walker helps them walk sooner”: according to the AAP, walkers don’t help babies learn to walk and may delay walking; babies in walkers can roll down stairs and reach hot things, chemicals or even water. The AAP calls for a ban on making and selling wheeled baby walkers, and Canada has banned them. Instead, let your baby play on the floor and pull up on sturdy furniture.',
            '“The water jar or bucket is low, the baby can’t reach it”: a baby who crawls or pulls to stand can tip head first into it; just 5 cm of water is enough to drown. Cover it tightly or empty it.',
            '“After a bump to the head, roll a boiled egg over it or rub on oil and it will be fine”: grandparents do this out of love, but these remedies don’t help detect an injury inside. Use a wrapped ice pack in short bursts and watch closely for the danger signs below. Don’t assume vomiting is just “fright”: vomiting after a head bump is a reason to see a doctor.',
          ),
          doctor(
            'Call 115 (Vietnam emergency) or go to the emergency department now if',
            'After a head bump: your child is unconscious, very drowsy, hard to wake or has a seizure; fell from more than 1 metre or more than 5 stairs; is under 1 year old and has a bruise, swelling or large cut on the head; has clear fluid or blood from the ears or nose; has a dent in the head; behaves differently or has weakness in an arm or leg. Your child may have swallowed a button battery, magnet, medicine or chemical; any drowning incident, even if your child is now awake. Meanwhile, see the Sơ cứu trẻ em (First aid) guide in Child Life (CPR, Swallowed medicine or chemicals, Scalds, Broken bone).',
          ),
          doctor(
            'See a doctor the same day if',
            'Your child vomits after a head bump; is in pain or won’t move an arm or leg after a fall; has a burn; or you are worried about anything after an accident.',
          ),
        ],
      },
      keywords: t(
        [
          'an toàn trong nhà',
          'phòng ngã',
          'ngã giường',
          'xe tập đi',
          'đuối nước',
          'chum vại',
          'bỏng',
          'ngộ độc',
          'pin cúc áo',
          'ban công',
          'chấn thương đầu',
          'hóc dị vật',
        ],
        [
          'home safety',
          'fall prevention',
          'falling off bed',
          'baby walker',
          'drowning',
          'water jars',
          'burns',
          'poisoning',
          'button batteries',
          'balcony',
          'head injury',
          'choking',
        ],
      ),
      relatedArticleIds: [
        'art_car_motorbike',
        'art_bathing_at_home',
        'art_solids_choking_safety',
        'art_safe_sleep',
      ],
      milestoneIds: [
        'rolls_over',
        'crawls',
        'stands',
        'cruises',
        'first_steps',
        'climbs_furniture',
      ],
      sources: [
        S.nhsBabyToddlerSafetyF,
        S.whoVnDrowning2025F,
        S.hcBabyWalkersF,
        S.nhsHeadInjuryF,
        S.cpscAnchorItF,
        S.khChokingF,
      ],
    },
  },
  {
    id: 'art_car_motorbike',
    reviewerLabel: PAEDS,
    data: {
      library: 'care',
      topic: 'daily_care',
      format: 'article',
      ageWeeks: { from: 0, to: 104 },
      readingMinutes: 6,
      cover: null,
      title: t(
        'Chở bé an toàn: ghế ô tô và chuyện đi xe máy',
        'Travelling safely with your baby: car seats and motorbikes',
      ),
      summary: t(
        'Ghế ô tô đúng cách, quy định mới về trẻ em trên ô tô từ 1/7/2026, và lời khuyên thẳng thắn khi chở bé bằng xe máy: vì sao nên tránh, và nếu bất khả kháng thì giảm nguy cơ thế nào.',
        'Using a car seat correctly, the new Vietnamese rule on children in cars from 1 July 2026, and frank advice on motorbikes: why to avoid them with a baby and how to reduce the risk if you must.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Trên ô tô, bé luôn ngồi ghế an toàn phù hợp, quay mặt về sau càng lâu càng tốt, ở hàng ghế sau, không bao giờ bế trên đùi. Từ 1/7/2026, luật yêu cầu trẻ dưới 10 tuổi và cao dưới 1,35 m không ngồi cùng hàng ghế người lái và phải dùng thiết bị an toàn phù hợp. Không có cách chở em bé bằng xe máy nào thật sự an toàn: hãy tránh khi có thể.',
          ),
          h('Hiểu đúng: vì sao bé cần ghế riêng'),
          p(
            'Khi ô tô phanh gấp hay va chạm, cơ thể bé bị hất đi với lực rất lớn: vòng tay người lớn không thể giữ nổi bé, còn dây an toàn của người lớn không được thiết kế cho trẻ nhỏ. Theo WHO, dùng thiết bị an toàn cho trẻ trên ô tô có thể giảm 71% số ca tử vong ở trẻ nhũ nhi. Ghế quay mặt về phía sau đỡ cả đầu, cổ và lưng của bé, những phần còn rất non yếu.',
          ),
          p(
            'Theo khoản 3 Điều 10 Luật Trật tự, an toàn giao thông đường bộ 2024 (được lùi hiệu lực, áp dụng từ 1/7/2026): khi chở trẻ em dưới 10 tuổi và chiều cao dưới 1,35 m trên ô tô, người lái không được cho trẻ ngồi cùng hàng ghế với mình (trừ xe chỉ có một hàng ghế) và phải sử dụng, hướng dẫn sử dụng thiết bị an toàn phù hợp cho trẻ. Xe kinh doanh vận tải hành khách được miễn nghĩa vụ thiết bị, nhưng nguy cơ với bé thì như nhau, nên mang theo ghế của bé khi đi taxi nếu có thể.',
          ),
          p(
            'Với xe máy, luật cho phép người lái chở tối đa hai người khi có trẻ em dưới 12 tuổi, và người được chở phải đội mũ bảo hiểm đạt quy chuẩn kỹ thuật quốc gia, cài quai đúng quy cách (Điều 33). Theo WHO, đội mũ bảo hiểm đúng cách giảm tới 74% nguy cơ chấn thương sọ não. Nhưng xe máy không có chỗ nào giữ và che chắn em bé như ghế ô tô.',
          ),
          h('Đi ô tô: ba mẹ có thể làm gì'),
          ul(
            'Từ chuyến đầu tiên rời bệnh viện về nhà, đặt bé trong ghế an toàn phù hợp với cân nặng của bé. Bé sinh non nên được kiểm tra trước khi xuất viện xem có ngồi ghế nửa nằm an toàn không.',
            'Cho bé ngồi quay mặt về phía sau càng lâu càng tốt, đến khi bé đạt giới hạn cân nặng hoặc chiều cao cao nhất mà nhà sản xuất ghế cho phép.',
            'Lắp ghế ở hàng ghế sau. Tuyệt đối không đặt ghế quay mặt về sau ở ghế trước có túi khí đang hoạt động: túi khí bung có thể gây chấn thương não nặng, kể cả khi va chạm ở tốc độ thấp. AAP khuyên trẻ dưới 13 tuổi luôn ngồi hàng ghế sau.',
            'Cài dây đai ôm sát: không véo được phần dây thừa ở vai, khóa ngực ngang nách. Đọc kỹ hướng dẫn lắp của ghế và của xe.',
            'Không mặc áo khoác phao, áo dày cho bé bên dưới dây đai; mặc lớp mỏng, cài dây xong rồi đắp chăn hay áo bên ngoài.',
            'Không bao giờ bế bé trên tay hay trên đùi khi xe đang chạy, kể cả quãng đường ngắn.',
            'Ghế ô tô chỉ dùng khi đi xe. Nếu bé ngủ trong ghế, khi đến nơi hãy chuyển bé ra mặt phẳng, chắc, nằm ngửa. Đi đường dài nên dừng nghỉ, cho bé ra khỏi ghế một lúc.',
            'Không bao giờ để bé một mình trong xe, dù chỉ một phút: xe đóng kín nóng lên rất nhanh và có thể gây say nóng nguy hiểm đến tính mạng.',
          ),
          h('Xe máy: lời khuyên thẳng thắn'),
          p(
            'Không có cách chở em bé bằng xe máy nào được xem là an toàn. Với trẻ nhỏ, nhất là dưới 1 tuổi, lựa chọn tốt hơn là đi ô tô hoặc taxi có ghế phù hợp, hoặc hoãn chuyến đi khi có thể. Nếu bất khả kháng phải đi xe máy, những điều dưới đây chỉ giúp giảm bớt nguy cơ, không làm chuyến đi trở nên an toàn:',
          ),
          ul(
            'Đi quãng ngắn, chậm, ban ngày; tránh đường đông, giờ cao điểm, trời mưa.',
            'Người lái chỉ tập trung lái. Một người lớn khác ngồi phía sau, ôm giữ bé chắc chắn.',
            'Không địu bé trước ngực người lái, không cho bé đứng hay ngồi phía trước tay lái, trên yên trước hay trên bình xăng.',
            'Bé đủ lớn để đội mũ: chọn mũ dành cho trẻ em, đạt quy chuẩn, vừa khít đầu bé và cài quai đúng cách. Không đội mũ người lớn cho bé vì mũ quá rộng sẽ xô lệch, tuột ra khi va chạm.',
            'Che nắng, mưa, bụi cho bé nhưng không trùm kín mặt, để bé luôn thở thông thoáng và người lớn nhìn thấy mặt bé.',
            'Giữ chân bé tránh xa ống xả nóng và bánh xe.',
          ),
          h('Theo dõi'),
          ul(
            'Cân nặng, chiều cao của bé so với giới hạn ghi trên nhãn ghế, để biết khi nào cần chuyển ghế.',
            'Mỗi lần lên xe: dây đai có ôm sát không, ghế có được lắp chắc không, bé có thở êm, sắc mặt bình thường không, nhất là với bé sơ sinh, bé sinh non.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            '“Bế trên tay là an toàn nhất, mẹ ôm chặt rồi”: người lớn bế bé vì thương, nhưng khi va chạm, lực tác động lớn đến mức không ai giữ nổi bé, và bé còn có thể bị chính người lớn đè lên. Chỉ ghế an toàn phù hợp mới bảo vệ được bé.',
            '“Đi gần, đi chậm thì không cần ghế”: va chạm có thể xảy ra trên bất kỳ quãng đường nào, và quy định áp dụng cho mọi chuyến đi. Hãy cài bé vào ghế ở mọi chuyến.',
            '“Bế bé sơ sinh từ viện về bằng xe máy, quấn kín là được”: quấn kín không bảo vệ bé khi ngã xe, còn che mặt bé khiến người lớn khó thấy bé có thở bình thường không. Hãy chuẩn bị trước taxi hoặc ô tô và ghế phù hợp cho ngày xuất viện.',
            '“Địu bé trước ngực, hoặc cho bé đứng phía trước người lái cho dễ trông”: khi phanh gấp hay ngã, bé ở phía trước hứng va đập đầu tiên và có thể bị kẹp giữa người lái và tay lái. Không chở bé ở phía trước người lái.',
            '“Đội tạm mũ của người lớn cho bé”: mũ quá rộng không bảo vệ được đầu bé. Chỉ dùng mũ trẻ em đúng cỡ, đạt quy chuẩn, cài quai đúng.',
          ),
          doctor(
            'Gọi 115 ngay khi',
            'Sau tai nạn giao thông, bé bất tỉnh, không thở hoặc thở bất thường, co giật, chảy máu nhiều, bị va đập mạnh vào đầu, nghi chấn thương đầu, cổ, lưng hoặc gãy xương. Không bế xốc bé; làm theo hướng dẫn Tai nạn giao thông trong mục Sơ cứu trẻ em của Child Life.',
          ),
          doctor(
            'Đưa bé đi khám trong ngày khi',
            'Bé vừa ngã xe hay bị va chạm, kể cả khi trông có vẻ bình thường; bé dưới 1 tuổi bị va đập vào đầu; bé nôn, lừ đừ, quấy khác thường, đau hoặc không chịu cử động tay chân sau tai nạn; bé bị bỏng do ống xả.',
          ),
        ],
        en: [
          note(
            'In short',
            "In a car, your baby always rides in a suitable car seat, rear-facing for as long as possible, in the back seat, never on a lap. From 1 July 2026, Vietnamese law requires children under 10 and shorter than 1.35 m not to sit in the driver's row and to use a suitable child restraint. There is no truly safe way to carry a baby on a motorbike: avoid it whenever you can.",
          ),
          h('Understanding why your baby needs their own seat'),
          p(
            "When a car brakes hard or crashes, a baby's body is thrown with enormous force: an adult's arms cannot hold on, and adult seat belts are not designed for small children. According to WHO, child restraints can reduce deaths among infants by 71%. A rear-facing seat supports the whole head, neck and back, the parts of a baby's body that are still most fragile.",
          ),
          p(
            "Under Article 10(3) of Vietnam's 2024 Law on Road Traffic Order and Safety (its start was postponed; it applies from 1 July 2026): when a car carries a child under 10 years old and shorter than 1.35 m, the driver must not let the child sit in the same row as the driver (except in cars with only one row) and must use, or instruct the use of, a suitable child safety device. Commercial passenger vehicles are exempt from the device requirement, but the risk to your baby is the same, so bring your baby's seat in a taxi if you can.",
          ),
          p(
            'For motorbikes, the law allows a rider to carry at most two passengers when one is a child under 12, and passengers must wear a helmet meeting the national technical standard with the strap fastened correctly (Article 33). According to WHO, wearing a helmet correctly reduces the risk of brain injury by up to 74%. But a motorbike has nothing that holds and shields a baby the way a car seat does.',
          ),
          h('In the car: what you can do'),
          ul(
            'From the very first ride home from hospital, put your baby in a car seat suited to their weight. Babies born early should be checked before discharge to make sure they can ride safely in a semi-reclined seat.',
            "Keep your baby rear-facing for as long as possible, until they reach the highest weight or height allowed by the seat's manufacturer.",
            'Install the seat in the back. Never put a rear-facing seat in a front seat with an active airbag: an inflating airbag can cause serious brain injury, even in a low-speed crash. The AAP advises that children under 13 always ride in the back seat.',
            "Make the harness snug: you shouldn't be able to pinch any slack at the shoulders, and the chest clip sits at armpit level. Read the seat's and the car's installation instructions carefully.",
            "Don't put a puffy jacket or thick clothes under the harness; dress your baby in thin layers, buckle up, then put a blanket or jacket over the top.",
            'Never hold your baby in your arms or on your lap while the car is moving, even for a short trip.',
            'Car seats are only for travel. If your baby falls asleep in the seat, move them onto a flat, firm surface on their back when you arrive. On long journeys, stop for breaks and take your baby out of the seat for a while.',
            'Never leave your baby alone in the car, even for a minute: a closed car heats up very fast and can cause life-threatening heatstroke.',
          ),
          h('Motorbikes: frank advice'),
          p(
            'No way of carrying a baby on a motorbike is considered safe. For young children, especially under 1 year, the better choice is a car or taxi with a suitable seat, or postponing the trip if you can. If a motorbike ride truly cannot be avoided, the points below only reduce the risk; they do not make the trip safe:',
          ),
          ul(
            'Keep trips short, slow and in daylight; avoid busy roads, rush hour and rain.',
            'The rider only rides. Another adult sits behind and holds the baby securely.',
            "Never carry a baby in a carrier on the rider's chest, and never let a child stand or sit in front of the handlebars, on the front of the seat or on the fuel tank.",
            "Once your child is big enough for a helmet: choose a children's helmet that meets the standard, fits snugly and has the strap fastened correctly. Don't use an adult helmet, which is too big and will shift or come off in a crash.",
            "Shield your baby from sun, rain and dust but don't cover their face, so they can always breathe freely and you can see them.",
            "Keep your child's feet away from the hot exhaust pipe and the wheels.",
          ),
          h('What to watch'),
          ul(
            "Your baby's weight and height against the limits on the seat label, so you know when to change seats.",
            'Every ride: is the harness snug, is the seat installed firmly, is your baby breathing easily with normal colour, especially newborns and babies born early.',
          ),
          h('Common misconceptions'),
          ul(
            '“Holding the baby is safest, I’ve got a tight grip”: parents hold babies out of love, but in a crash the forces are so great that no one can hold on, and the baby can even be crushed by the adult. Only a suitable car seat protects your baby.',
            '“It’s a short, slow trip, no need for a seat”: crashes can happen on any trip, and the rule applies to every journey. Buckle your baby into the seat every time.',
            '“Bringing a newborn home from hospital by motorbike is fine if they’re well wrapped”: wrapping does not protect a baby in a fall, and covering their face makes it hard to see if they are breathing normally. Arrange a taxi or car and a suitable seat for discharge day in advance.',
            '“Carry the baby on your chest, or let them stand in front of the rider, so you can keep an eye on them”: in a sudden stop or fall, a child in front takes the first impact and can be crushed between the rider and the handlebars. Never carry a child in front of the rider.',
            "“An adult's helmet will do for now”: a helmet that is too big cannot protect a child's head. Only use a correctly sized children's helmet that meets the standard, with the strap fastened properly.",
          ),
          doctor(
            'Call 115 (Vietnam emergency) now if',
            "After a traffic accident, your child is unconscious, not breathing or breathing abnormally, has a seizure, is bleeding heavily, took a hard knock to the head, or may have a head, neck, back injury or broken bone. Don't pick them up abruptly; follow the Traffic accident steps in the Sơ cứu trẻ em (First aid) guide in Child Life.",
          ),
          doctor(
            'See a doctor the same day if',
            'Your child has just fallen from a vehicle or been in a collision, even if they seem fine; a baby under 1 has bumped their head; your child vomits, is drowsy, unusually fussy, in pain or won’t move an arm or leg after an accident; or has a burn from an exhaust pipe.',
          ),
        ],
      },
      keywords: t(
        [
          'ghế ô tô',
          'ghế an toàn trẻ em',
          'quay mặt về sau',
          'túi khí',
          'xe máy',
          'mũ bảo hiểm trẻ em',
          'luật giao thông 2024',
          'trẻ dưới 10 tuổi',
          'địu khi lái xe',
          'xuất viện',
        ],
        [
          'car seat',
          'child restraint',
          'rear-facing',
          'airbag',
          'motorbike',
          "children's helmet",
          '2024 road traffic law',
          'children under 10',
          'carrier while riding',
          'hospital discharge',
        ],
      ),
      relatedArticleIds: ['art_home_safety_falls', 'art_safe_sleep'],
      milestoneIds: [],
      sources: [
        S.hcCarSeatsFamiliesF,
        S.hcAirBagF,
        S.whoRoadInjuriesF,
        S.lsvnChildCarSeatLawF,
        S.vnRoadLawArt33F,
        S.hcSafeSleep,
        S.nhsKeepActiveF,
      ],
    },
  },
  {
    id: 'art_parent_wellbeing',
    reviewerLabel: PERINATAL,
    data: {
      library: 'care',
      topic: 'daily_care',
      format: 'article',
      ageWeeks: { from: 0, to: 104 },
      readingMinutes: 7,
      cover: null,
      title: t(
        'Ba mẹ cũng cần được chăm: mệt mỏi, buồn sau sinh và trầm cảm sau sinh',
        'Parents need care too: exhaustion, baby blues and postnatal depression',
      ),
      summary: t(
        'Phân biệt buồn sau sinh với trầm cảm sau sinh ở cả mẹ và ba, cách nghỉ ngơi và nhận giúp đỡ, điều trị có hiệu quả, và nơi tìm hỗ trợ ở Việt Nam. Gọi 115 nếu có nguy hiểm tức thời.',
        'How to tell baby blues from postnatal depression in mothers and fathers, ways to rest and accept help, treatments that work, and where to find support in Vietnam. Call 115 in immediate danger.',
      ),
      body: {
        vi: [
          note(
            'Tóm tắt nhanh',
            'Mệt mỏi và buồn thoáng qua trong vài ngày đầu sau sinh rất thường gặp và thường hết trong 2 tuần. Nếu buồn, lo âu kéo dài hơn 2 tuần hoặc nặng dần, đó có thể là trầm cảm sau sinh, một bệnh có thể chữa được, gặp ở cả mẹ và ba. Hãy nói ra và tìm hỗ trợ sớm; gọi 115 nếu có ý nghĩ làm hại bản thân hoặc bé.',
          ),
          h('Hiểu đúng: buồn sau sinh và trầm cảm sau sinh'),
          p(
            'Trong vài ngày đầu sau sinh, rất nhiều mẹ thấy buồn, dễ khóc, lo lắng hay cáu gắt. Tình trạng này thường được gọi là “buồn sau sinh” (baby blues) và thường tự hết trong vòng 2 tuần sau sinh. Nếu kéo dài hơn, nặng hơn hay mẹ thấy không xoay xở nổi, cần tìm hỗ trợ.',
          ),
          p(
            'Trầm cảm sau sinh thì khác: kéo dài, nặng hơn và cần được điều trị. Theo WHO, khoảng 13% phụ nữ mới sinh trên thế giới gặp một rối loạn tâm thần, chủ yếu là trầm cảm, và ở các nước đang phát triển tỷ lệ này cao hơn, gần 20%, tức khoảng 1 trong 5 người. Trầm cảm có thể bắt đầu từ khi mang thai đến một năm sau sinh. Ba và người chăm sóc cũng có thể bị: một phân tích tổng hợp nhiều nghiên cứu ghi nhận khoảng 1 trong 10 người cha bị trầm cảm trong thai kỳ hoặc năm đầu sau sinh.',
          ),
          p(
            'Dấu hiệu thường gặp: buồn bã, mất hứng thú với hầu hết mọi việc; thấy vô vọng, không thể xoay xở; tự trách, thấy mình là cha mẹ tồi; lo âu, sợ hãi liên tục; cáu gắt, bồn chồn; khó ngủ ngay cả khi có thời gian nghỉ; khó tập trung; khó gắn bó với bé; có ý nghĩ tự làm hại bản thân hoặc làm hại bé. Nhiều người ngại nói ra vì sợ bị phán xét hay sợ bị tách khỏi con; theo NHS, điều đó rất hiếm khi xảy ra và nhân viên y tế sẽ hỗ trợ ba mẹ.',
          ),
          p(
            'Loạn thần sau sinh hiếm gặp, khoảng 1 trong 1.000 bà mẹ, nhưng là tình trạng cấp cứu: thường khởi phát đột ngột trong vài ngày đến 2 tuần đầu, với ảo giác, niềm tin kỳ lạ, kích động, lú lẫn hoặc tâm trạng thay đổi rất nhanh. Người bệnh có thể không nhận ra mình đang bệnh, nên người thân cần hành động.',
          ),
          h('Ba mẹ có thể làm gì'),
          ul(
            'Ưu tiên giấc ngủ: ngủ khi bé ngủ ít nhất một giấc mỗi ngày; chia ca đêm giữa ba và mẹ (người kia bế dỗ, thay tã, cho bé bú bình sữa mẹ đã vắt hoặc sữa công thức nếu gia đình dùng) để mỗi người có một quãng ngủ dài hơn.',
            'Khi quá buồn ngủ lúc cho bé bú đêm, hãy đặt bé về chỗ ngủ riêng trước khi mình ngủ. Tránh ngủ quên khi đang bế bé trên sofa hay ghế bành vì nguy cơ cho bé rất cao.',
            'Ăn đủ bữa, uống đủ nước, ra ngoài hít thở không khí, đi bộ nhẹ khi sức khỏe cho phép.',
            'Nhận và nhờ giúp đỡ cụ thể: “Bà trông cháu giúp con 2 tiếng để con ngủ”, “Anh nấu bữa tối nhé”.',
            'Nói ra cảm xúc với người mình tin tưởng; trò chuyện với những ba mẹ khác cũng đang nuôi con nhỏ.',
            'Hạ bớt tiêu chuẩn: nhà chưa gọn, khách chưa tiếp cũng không sao. Mỗi ngày chỉ cần vài việc nhỏ.',
            'Ở lần khám sau sinh, hãy kể thật với bác sĩ sản hay nữ hộ sinh về tâm trạng của mình; có những bảng câu hỏi ngắn giúp sàng lọc trầm cảm sau sinh.',
            'Điều trị có hiệu quả: trò chuyện trị liệu như liệu pháp nhận thức hành vi, và thuốc khi cần. Nhiều thuốc chống trầm cảm dùng được khi cho con bú; hãy báo bác sĩ là mình đang cho con bú để được chọn thuốc phù hợp, không tự ý dùng hay ngừng thuốc.',
            'Khi bé khóc mãi và ba mẹ thấy mình sắp mất bình tĩnh: đặt bé nằm ngửa trong nôi an toàn, ra chỗ khác vài phút để hít thở, nhờ người khác thay tay. Không bao giờ lắc bé.',
            'Người thân: để ý những thay đổi của mẹ và ba, lắng nghe không phán xét, giúp việc nhà và cùng đi khám.',
          ),
          tip(
            'Ông bà là điểm tựa quý',
            'Sự giúp đỡ của ông bà trong những tháng đầu là điểm mạnh của nhiều gia đình Việt. Hãy để ông bà giúp những việc giúp ba mẹ được nghỉ ngơi, và cùng nhau thống nhất cách chăm bé an toàn; khi có khác biệt, có thể nhờ bác sĩ giải thích cho cả nhà.',
          ),
          h('Theo dõi'),
          ul(
            'Tâm trạng mỗi ngày: buồn, lo âu, cáu gắt đã kéo dài bao lâu, đỡ dần hay nặng thêm.',
            'Giấc ngủ: có ngủ được khi bé ngủ và có người trông giúp không.',
            'Ăn uống, sức lực, khả năng chăm sóc bản thân và chăm bé.',
            'Tâm trạng của người còn lại: ba hay mẹ cũng cần được hỏi han.',
          ),
          h('Hiểu lầm thường gặp'),
          ul(
            '“Ở cữ phải kiêng tắm gội, ở trong phòng kín cả tháng”: nghỉ ngơi sau sinh là cần thiết và người thân dặn dò vì thương mẹ, nhưng kiêng khem quá mức và ở một mình trong phòng kín có thể khiến mẹ thấy bí bách, cô đơn hơn. Mẹ có thể tắm nhanh bằng nước ấm, lau khô, ở phòng thoáng, đủ ấm và gặp gỡ người thân. Nếu sinh mổ, hỏi bác sĩ cách giữ vết mổ khi tắm.',
            '“Buồn sau sinh là do yếu đuối, nghĩ nhiều”: trầm cảm sau sinh là một bệnh, không phải lỗi hay tính cách của ai, và thường cải thiện khi được điều trị.',
            '“Đi khám tâm thần là bị điên, xấu hổ lắm”: bác sĩ tâm thần, chuyên gia tâm lý điều trị cả những vấn đề rất phổ biến như lo âu, trầm cảm. Khám sớm giúp ba mẹ khỏe lại sớm và bé được chăm sóc tốt hơn.',
            '“Làm mẹ ai cũng thế, phải tự chịu đựng”: mệt thì ai cũng mệt, nhưng buồn kéo dài hơn 2 tuần, mất hứng thú, thấy vô vọng thì không phải chuyện “ai cũng thế”. Tìm giúp đỡ là việc làm vì cả mẹ và bé.',
            '“Đàn ông không bị trầm cảm sau sinh”: ba cũng có thể bị trầm cảm trong thai kỳ của vợ và năm đầu sau sinh. Ba cũng xứng đáng được hỏi han, chia sẻ và đi khám khi cần.',
          ),
          doctor(
            'Gọi 115 hoặc đến cấp cứu ngay khi',
            'Ba mẹ có ý nghĩ hoặc kế hoạch tự làm hại bản thân hay làm hại bé; người mẹ sau sinh đột ngột nghe, thấy những điều không có thật, có niềm tin kỳ lạ, kích động, lú lẫn hoặc tâm trạng thay đổi rất nhanh. Đừng để người đó ở một mình với bé; người thân hãy gọi giúp.',
          ),
          doctor(
            'Tìm hỗ trợ sớm khi',
            'Buồn, lo âu, mất hứng thú kéo dài hơn 2 tuần hoặc nặng dần; khó gắn bó với bé; không ngủ được dù có thời gian. Nơi có thể tìm đến: bác sĩ sản, nữ hộ sinh hay bác sĩ nhi của bé ở lần khám gần nhất; khoa tâm thần, phòng khám tâm lý của bệnh viện lớn. Ở Việt Nam: ví dụ Viện Sức khỏe Tâm thần, Bệnh viện Bạch Mai; Đường dây nóng Ngày Mai 096 306 1414 (hỗ trợ người trầm cảm, không trực 24/7, xem giờ trực trên website). Lo cho an toàn của trẻ: Tổng đài quốc gia bảo vệ trẻ em 111. Ở nước khác: hỏi bác sĩ về đường dây hỗ trợ nơi bạn sống.',
          ),
        ],
        en: [
          note(
            'In short',
            'Feeling tired and briefly low in the first days after birth is very common and usually passes within 2 weeks. If low mood or anxiety lasts more than 2 weeks or gets worse, it may be postnatal depression, a treatable illness that affects both mothers and fathers. Talk about it and get support early; call 115 if you have thoughts of harming yourself or your baby.',
          ),
          h('Understanding baby blues and postnatal depression'),
          p(
            "In the first few days after birth, many mothers feel low, tearful, anxious or irritable. This is often called the “baby blues” and usually goes away on its own within 2 weeks of the birth. If it lasts longer, gets worse or you feel you can't cope, get support.",
          ),
          p(
            'Postnatal depression is different: it lasts, it is more severe and it needs treatment. According to WHO, about 13% of women who have just given birth worldwide experience a mental disorder, mainly depression, and in developing countries the rate is higher, close to 20%, or about 1 in 5. Depression can begin in pregnancy or at any point up to a year after birth. Fathers and partners can be affected too: a meta-analysis of many studies found about 1 in 10 fathers had depression during pregnancy or the first year after birth.',
          ),
          p(
            'Common signs: feeling low and losing interest in most things; feeling hopeless or unable to cope; blaming yourself or feeling like a bad parent; constant anxiety or fear; irritability or restlessness; trouble sleeping even when you have the chance; trouble concentrating; difficulty bonding with your baby; thoughts of harming yourself or your baby. Many parents hold back for fear of being judged or of their baby being taken away; according to the NHS, that is very rare and health workers will support you.',
          ),
          p(
            'Postpartum psychosis is rare, affecting about 1 in 1,000 mothers, but it is an emergency: it usually starts suddenly within days to the first 2 weeks, with hallucinations, unusual beliefs, agitation, confusion or very fast mood changes. The person may not realise they are ill, so family members need to act.',
          ),
          h('What you can do'),
          ul(
            'Make sleep a priority: sleep when your baby sleeps at least once a day; split the night between both parents (one soothes, changes diapers and gives a bottle of expressed breast milk, or formula if your family uses it) so each of you gets a longer stretch of sleep.',
            'If you are very sleepy during a night feed, put your baby back in their own sleep space before you fall asleep. Avoid dozing off while holding your baby on a sofa or armchair, as the risk to your baby is very high.',
            'Eat regular meals, drink enough water, get some fresh air and take gentle walks when you feel able.',
            'Accept and ask for specific help: “Could you watch the baby for 2 hours so I can sleep?”, “Could you cook dinner tonight?”.',
            'Share your feelings with someone you trust; talk with other parents of young babies.',
            'Lower the bar: an untidy house or visitors not yet received is fine. A few small things each day is enough.',
            'At your postnatal check, tell your obstetrician or midwife honestly how you are feeling; short questionnaires can help screen for postnatal depression.',
            "Treatment works: talking therapies such as cognitive behavioural therapy, and medication when needed. Many antidepressants can be used while breastfeeding; tell your doctor you are breastfeeding so they can choose a suitable medicine, and don't start or stop medicine on your own.",
            'If your baby keeps crying and you feel close to losing control: lay your baby on their back in a safe crib, step away for a few minutes to breathe, and ask someone to take over. Never shake a baby.',
            'Family members: notice changes in both parents, listen without judging, help with housework and go to appointments together.',
          ),
          tip(
            'Grandparents are a precious support',
            "Grandparents' help in the early months is a real strength of many Vietnamese families. Let them take on tasks that give you rest, and agree together on safe ways to care for the baby; where views differ, a doctor can explain to the whole family.",
          ),
          h('What to watch'),
          ul(
            'Your mood each day: how long low mood, anxiety or irritability have lasted, and whether they are easing or getting worse.',
            'Sleep: whether you can sleep when your baby sleeps and someone is helping.',
            'Eating, energy, and your ability to look after yourself and your baby.',
            'The other parent’s mood: fathers and mothers both need to be asked how they are.',
          ),
          h('Common misconceptions'),
          ul(
            '“During confinement (ở cữ), no bathing or hair washing; stay in a closed room for a month”: rest after birth matters and the advice comes from love, but very strict rules and being alone in a closed room can leave a mother feeling stifled and lonely. A quick warm shower, drying off well, an airy, warm room and seeing family are fine. After a caesarean, ask your doctor about bathing.',
            '“Feeling low after birth is weakness or overthinking”: postnatal depression is an illness, not anyone’s fault or character flaw, and it usually improves with treatment.',
            '“Seeing a psychiatrist means you are mad, it’s shameful”: psychiatrists and psychologists treat very common problems such as anxiety and depression. Getting help early means parents recover sooner and the baby is better cared for.',
            '“Every mother goes through it, you just have to endure it”: every parent gets tired, but low mood for more than 2 weeks, loss of interest and hopelessness are not just “what everyone goes through”. Seeking help is something you do for both you and your baby.',
            "“Men don't get postnatal depression”: fathers can also become depressed during their partner's pregnancy and the first year after birth. They deserve to be asked how they are, to share, and to see a doctor when needed.",
          ),
          doctor(
            'Call 115 (Vietnam emergency) or go to the emergency department now if',
            "A parent has thoughts or plans of harming themselves or the baby; a new mother suddenly hears or sees things that aren't there, has strange beliefs, is agitated or confused, or has very rapid mood swings. Don't leave that person alone with the baby; family members should make the call.",
          ),
          doctor(
            'Get support early if',
            'Low mood, anxiety or loss of interest last more than 2 weeks or get worse; you find it hard to bond with your baby; you cannot sleep even when you have the chance. Where to turn: your obstetrician, midwife or your baby’s doctor at the next visit; the psychiatry department or psychology clinic of a major hospital. In Việt Nam: for example the Institute of Mental Health at Bạch Mai Hospital; the Ngày Mai hotline 096 306 1414 (not 24/7; check its hours). Concerned about a child’s safety: the national child protection hotline 111. Elsewhere: ask your doctor for your national helpline.',
          ),
        ],
      },
      keywords: t(
        [
          'trầm cảm sau sinh',
          'buồn sau sinh',
          'mệt mỏi',
          'lo âu',
          'loạn thần sau sinh',
          'ở cữ',
          'ba trầm cảm',
          'thiếu ngủ',
          'hỗ trợ tâm lý',
          'sức khỏe tâm thần',
        ],
        [
          'postnatal depression',
          'baby blues',
          'exhaustion',
          'anxiety',
          'postpartum psychosis',
          'confinement',
          'fathers depression',
          'sleep deprivation',
          'emotional support',
          'mental health',
        ],
      ),
      relatedArticleIds: [
        'art_crying_colic',
        'art_breastfeeding_start',
        'art_newborn_sleep',
        'art_safe_sleep',
      ],
      milestoneIds: [],
      sources: [
        S.nhsPndOverviewF,
        S.nhsPostpartumPsychosisF,
        S.whoPerinatalMentalHealthF,
        S.paternalDepressionMetaF,
        S.hcSafeSleep,
        S.ngayMaiHotlineF,
        S.vnChildHotline111F,
      ],
    },
  },
  // ----- Review 2026-10-16: added topics -----
  {
    id: 'art_bronchiolitis_rsv',
    reviewerLabel: 'Nhóm chuyên môn · Nhi khoa',
    data: {
      library: 'care',
      topic: 'illness',
      format: 'article',
      ageWeeks: { from: 0, to: 104 },
      readingMinutes: 5,
      cover: null,
      title: {
        vi: 'Viêm tiểu phế quản và virus RSV: chăm bé tại nhà, khi nào cần đi viện',
        en: 'Bronchiolitis and RSV: caring for your baby at home and when to get help',
      },
      summary: {
        vi: 'Viêm tiểu phế quản hay gặp ở bé dưới 2 tuổi, nhất là dưới 6 tháng, thường do virus RSV. Phần lớn bé khỏi tại nhà; điều quan trọng là giữ bé bú đủ và nhận ra sớm lúc bé thở khó.',
        en: 'Bronchiolitis is common under age 2, especially under 6 months, and is usually caused by RSV. Most babies get better at home; what matters is keeping feeds going and spotting breathing trouble early.',
      },
      body: {
        vi: [
          {
            type: 'callout',
            tone: 'note',
            title: 'Tóm tắt nhanh',
            text: 'Viêm tiểu phế quản bắt đầu như cảm lạnh rồi bé ho nhiều, thở nhanh, có thể khò khè. Bệnh thường nặng nhất vào ngày 3–5 và đỡ dần trong 2–3 tuần. Không có thuốc diệt virus: kháng sinh, thuốc ho, khí dung tại nhà không giúp. Cho bé bú cữ nhỏ, thường xuyên, và đi khám ngay khi bé thở nhanh, rút lõm ngực hay bú dưới một nửa so với bình thường.',
          },
          { type: 'heading', text: 'Hiểu đúng về viêm tiểu phế quản' },
          {
            type: 'paragraph',
            text: 'Viêm tiểu phế quản là nhiễm virus ở những ống dẫn khí nhỏ nhất trong phổi. Các ống này sưng lên và tiết nhiều đờm nên bé thở khó hơn. Virus hợp bào hô hấp (RSV) là nguyên nhân hay gặp nhất, ngoài ra còn nhiều virus khác. Theo NHS, bệnh hay gặp ở trẻ dưới 2 tuổi, nhất là dưới 6 tháng, và lây qua giọt bắn khi ho, hắt hơi, qua tay và đồ vật.',
          },
          {
            type: 'paragraph',
            text: 'Bệnh thường bắt đầu như cảm lạnh: sổ mũi, nghẹt mũi, ho nhẹ, có thể sốt nhẹ. Sau 2–3 ngày, bé ho nhiều hơn, thở nhanh, có tiếng khò khè hoặc rít, và bú kém đi vì vừa bú vừa thở rất mệt. Triệu chứng thường nặng nhất vào ngày thứ 3–5 rồi đỡ dần; riêng ho có thể kéo dài 2–3 tuần mà vẫn là diễn biến hay gặp.',
          },
          {
            type: 'paragraph',
            text: 'Phần lớn bé khỏi tại nhà. Theo NICE, bé dễ bị nặng hơn nếu dưới 3 tháng tuổi, sinh non, có bệnh tim, bệnh phổi mạn tính, bệnh thần kinh cơ hoặc suy giảm miễn dịch. Với những bé này, ba mẹ nên cho đi khám sớm ngay khi mới có dấu hiệu.',
          },
          { type: 'heading', text: 'Ba mẹ có thể làm gì' },
          {
            type: 'bullets',
            items: [
              'Cho bú cữ nhỏ, thường xuyên hơn, cho bé nghỉ giữa cữ để thở. Bé bú mẹ thì tiếp tục bú mẹ. Bé từ 6 tháng có thể uống thêm từng ngụm nước.',
              'Nếu nghẹt mũi làm bé khó bú, nhỏ vài giọt nước muối sinh lý vào mũi trước cữ bú và trước khi ngủ, rồi hút nhẹ ở lỗ mũi, không đưa dụng cụ sâu vào trong.',
              'Đếm nhịp thở của bé trong đủ 1 phút khi bé nằm yên, vài lần mỗi ngày, và ghi lại cùng lượng bú, số tã ướt (có thể ghi trong Child Life).',
              'Bé vẫn ngủ nằm ngửa trên mặt phẳng, chắc; không kê gối hay nâng đầu nệm.',
              'Nếu bé sốt và khó chịu, chăm theo bài “Khi bé sốt”; hỏi bác sĩ hoặc dược sĩ liều thuốc theo cân nặng.',
              'Giữ nhà không khói thuốc; người lớn rửa tay trước khi bế bé; người đang ho, sổ mũi hạn chế hôn và bế bé nhỏ.',
              'Cho bé nghỉ ở nhà, chưa đi nhà trẻ đến khi khoẻ lại, để bé hồi phục và đỡ lây cho trẻ khác.',
            ],
          },
          {
            type: 'callout',
            tone: 'note',
            title: 'Những thuốc không giúp',
            text: 'Kháng sinh không có tác dụng với virus. NICE khuyên không dùng thường quy thuốc giãn phế quản, corticoid, khí dung nước muối ưu trương hay vỗ rung lồng ngực cho viêm tiểu phế quản. Không tự mua thuốc ho, thuốc long đờm cho bé dưới 2 tuổi. Nếu bé cần thở oxy hay bù dịch, việc đó được làm ở bệnh viện.',
          },
          { type: 'heading', text: 'Phòng bệnh' },
          {
            type: 'paragraph',
            text: 'Bú mẹ, nhà không khói thuốc, rửa tay và tránh cho bé nhỏ tiếp xúc người đang ốm giúp giảm nguy cơ. Ở một số nước như Anh, Úc, Mỹ, Canada đã có vắc xin RSV tiêm cho mẹ khi mang thai và thuốc kháng thể tiêm cho bé trước hoặc trong mùa RSV; đối tượng được dùng khác nhau theo từng nước. Ở Việt Nam: hãy hỏi bác sĩ sản hoặc bác sĩ nhi xem các biện pháp này có sẵn không và bé có thuộc nhóm nên dùng không.',
          },
          { type: 'heading', text: 'Theo dõi' },
          {
            type: 'bullets',
            items: [
              'Nhịp thở khi bé nằm yên: theo WHO, thở nhanh là từ 60 lần mỗi phút ở bé dưới 2 tháng, từ 50 lần ở bé 2–12 tháng, từ 40 lần ở trẻ 1–5 tuổi.',
              'Ngực và mũi: phần dưới lồng ngực lõm vào khi hít vào, cánh mũi phập phồng, đầu gật gù theo nhịp thở, thở rên.',
              'Lượng bú so với bình thường và số tã ướt trong 24 giờ.',
              'Màu môi, lưỡi, và những lúc bé ngừng thở, nhất là ở bé nhỏ.',
              'Diễn biến: đỡ dần sau ngày thứ 5, hay nặng lên, sốt lại sau khi đã đỡ.',
            ],
          },
          { type: 'heading', text: 'Hiểu lầm thường gặp' },
          {
            type: 'bullets',
            items: [
              '“Khò khè là phải dùng kháng sinh cho nhanh khỏi”: nhiều nhà lo bé “viêm phổi” nên tự mua kháng sinh. Viêm tiểu phế quản do virus; kháng sinh không giúp mà còn có thể gây tiêu chảy, dị ứng. Nên: chỉ dùng kháng sinh khi bác sĩ khám và kê đơn.',
              '“Xông lá, xông tinh dầu, hơ nóng cho thông phổi”: nồi nước nóng dễ gây bỏng, tinh dầu kích ứng đường thở của bé nhỏ. Nên: nhỏ nước muối, hút mũi nhẹ, cho bú cữ nhỏ.',
              '“Mua máy khí dung về nhà xông cho bé”: thuốc và nước muối khí dung không được khuyên dùng thường quy cho viêm tiểu phế quản, dùng sai còn làm bé mệt hơn. Nên: chỉ khí dung khi bác sĩ chỉ định.',
              '“Bé ho thì kiêng tắm, ủ thật kín”: ủ kín dễ làm bé nóng và thở nhanh hơn. Nên: mặc vừa đủ, phòng thoáng, tắm nhanh bằng nước ấm và lau khô.',
            ],
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Gọi 115 hoặc đến cấp cứu ngay khi',
            text: 'Bé có lúc ngừng thở, môi hoặc lưỡi tím tái; thở rất khó, rút lõm ngực nhiều, thở rên; thở từ 70 lần mỗi phút trở lên; li bì, khó đánh thức hoặc lả mềm; không bú, không uống được. Đừng chờ, gọi 115 ngay.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Đưa bé đi khám trong ngày khi',
            text: 'Bé dưới 3 tháng có dấu hiệu ốm, nhất là sốt từ 38 °C; thở nhanh theo ngưỡng ở trên; bú dưới khoảng một nửa so với bình thường; ít tã ướt hơn hẳn hoặc không có tã ướt trong 12 giờ; bé sinh non hay có bệnh tim, phổi; sốt cao kéo dài hoặc nặng hơn sau ngày thứ 5; hoặc ba mẹ thấy lo. Nếu bé nặng lên nhanh, gọi 115.',
          },
        ],
        en: [
          {
            type: 'callout',
            tone: 'note',
            title: 'In short',
            text: 'Bronchiolitis starts like a cold, then your baby coughs more, breathes fast and may wheeze. It is usually worst on days 3–5 and settles over 2–3 weeks. There is no medicine that kills the virus: antibiotics, cough medicines and home nebulisers do not help. Offer smaller, more frequent feeds, and get your baby seen straight away if they breathe fast, the chest pulls in or they take less than half their usual feeds.',
          },
          { type: 'heading', text: 'Understanding bronchiolitis' },
          {
            type: 'paragraph',
            text: 'Bronchiolitis is a viral infection of the smallest airways in the lungs. They swell and fill with mucus, so breathing becomes harder work. Respiratory syncytial virus (RSV) is the most common cause, but other viruses can cause it too. According to the NHS, it mostly affects children under 2, especially under 6 months, and spreads through droplets from coughs and sneezes, hands and objects.',
          },
          {
            type: 'paragraph',
            text: 'It usually begins like a cold: a runny or blocked nose, a mild cough, perhaps a mild temperature. After 2–3 days your baby coughs more, breathes fast, may wheeze or whistle, and feeds less because feeding and breathing at once is tiring. Symptoms are usually worst on days 3–5 and then ease; the cough can last 2–3 weeks and still be part of the usual course.',
          },
          {
            type: 'paragraph',
            text: 'Most babies recover at home. According to NICE, babies are more likely to become seriously unwell if they are under 3 months, were born early, or have heart disease, chronic lung disease, a neuromuscular condition or a weakened immune system. Get these babies checked early, as soon as symptoms start.',
          },
          { type: 'heading', text: 'What you can do' },
          {
            type: 'bullets',
            items: [
              'Offer smaller, more frequent feeds and let your baby pause to breathe. Keep breastfeeding if you breastfeed. From 6 months, your baby can also have sips of water.',
              'If a blocked nose makes feeding hard, put a few drops of saline in each nostril before feeds and sleep, then suction gently just inside the nostril, never deep into the nose.',
              'Count your baby’s breaths for a full minute while they lie still, a few times a day, and note it with feeds and wet diapers (you can log these in Child Life).',
              'Your baby still sleeps on their back on a firm, flat surface; no pillows and no raising the head of the mattress.',
              'If your baby has a fever and is uncomfortable, follow the “When your baby has a fever” article; ask a doctor or pharmacist for the dose for their weight.',
              'Keep the home smoke-free; adults wash their hands before holding your baby; anyone with a cough or cold avoids kissing or holding a young baby.',
              'Keep your baby home from childcare until they are well again, to recover and to avoid passing it on.',
            ],
          },
          {
            type: 'callout',
            tone: 'note',
            title: 'Medicines that do not help',
            text: 'Antibiotics do not work on viruses. NICE advises against routine bronchodilators, steroids, hypertonic saline nebulisers or chest physiotherapy for bronchiolitis. Do not buy cough or mucus medicines for a baby under 2. If your baby needs oxygen or extra fluids, that is done in hospital.',
          },
          { type: 'heading', text: 'Prevention' },
          {
            type: 'paragraph',
            text: 'Breastfeeding, a smoke-free home, handwashing and keeping young babies away from people who are ill all lower the risk. Some countries, such as the UK, Australia, the US and Canada, now offer an RSV vaccine in pregnancy and an antibody injection for babies before or during the RSV season; who is eligible differs by country. In Việt Nam: ask your obstetrician or your baby’s doctor whether these are available and whether your baby should have one.',
          },
          { type: 'heading', text: 'What to watch' },
          {
            type: 'bullets',
            items: [
              'Breathing rate at rest: according to WHO, fast breathing is 60 or more a minute under 2 months, 50 or more at 2–12 months and 40 or more at 1–5 years.',
              'Chest and nose: the lower chest sucking in with each breath, flaring nostrils, head bobbing with breaths, grunting.',
              'How much your baby feeds compared with usual, and wet diapers in 24 hours.',
              'The colour of lips and tongue, and any pauses in breathing, especially in young babies.',
              'The overall course: easing after day 5, or getting worse, or a fever returning after improving.',
            ],
          },
          { type: 'heading', text: 'Common misconceptions' },
          {
            type: 'bullets',
            items: [
              '“Wheezing needs antibiotics to clear it fast”: many families fear pneumonia and buy antibiotics themselves. Bronchiolitis is viral; antibiotics do not help and can cause diarrhoea or allergy. Instead: use antibiotics only when a doctor has examined your baby and prescribed them.',
              '“Steam with leaves or essential oils to open the lungs”: bowls of hot water cause scalds and oils irritate a young baby’s airways. Instead: saline drops, gentle suction and small, frequent feeds.',
              '“Buy a nebuliser and use it at home”: nebulised medicines and saline are not recommended routinely for bronchiolitis, and the wrong use can tire your baby more. Instead: use a nebuliser only when a doctor prescribes it.',
              '“A coughing baby should not be bathed and must be bundled up”: bundling makes your baby hot and breathe faster. Instead: dress them just right, keep the room airy, give a quick warm bath and dry them well.',
            ],
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Call 115 (Việt Nam) or local emergency services now if',
            text: 'Your baby has pauses in breathing or blue lips or tongue; struggles to breathe, with marked chest pulling in or grunting; breathes 70 or more times a minute; is floppy, very drowsy or hard to wake; or cannot feed or drink. Do not wait.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'See a doctor the same day if',
            text: 'Your baby is under 3 months with any sign of illness, especially 38 °C or more; breathes fast by the counts above; takes less than about half their usual feeds; has far fewer wet diapers or none in 12 hours; was born early or has a heart or lung condition; has a high fever that lasts or is worse after day 5; or you are worried. If your baby gets worse quickly, call emergency services.',
          },
        ],
      },
      keywords: {
        vi: [
          'viêm tiểu phế quản',
          'RSV',
          'khò khè',
          'thở nhanh',
          'rút lõm lồng ngực',
          'ho kéo dài',
        ],
        en: [
          'bronchiolitis',
          'RSV',
          'wheezing',
          'fast breathing',
          'chest indrawing',
          'lingering cough',
        ],
      },
      relatedArticleIds: [
        'art_cold_cough',
        'art_fever_when_to_call',
        'art_safe_sleep',
        'art_breastfeeding_start',
      ],
      milestoneIds: [],
      sources: [
        { label: 'NHS — Bronchiolitis', url: 'https://www.nhs.uk/conditions/bronchiolitis/' },
        {
          label: 'NICE NG9 — Bronchiolitis in children: diagnosis and management (recommendations)',
          url: 'https://www.nice.org.uk/guidance/ng9/chapter/Recommendations',
        },
        {
          label: 'HealthyChildren.org (AAP) — Bronchiolitis',
          url: 'https://www.healthychildren.org/English/health-issues/conditions/chest-lungs/Pages/Bronchiolitis.aspx',
        },
        {
          label: "HealthyChildren.org (AAP) — RSV: when it's more than just a cold",
          url: 'https://www.healthychildren.org/English/health-issues/conditions/chest-lungs/Pages/RSV-When-its-More-Than-Just-a-Cold.aspx',
        },
        {
          label: 'WHO — Integrated Management of Childhood Illness (IMCI) chart booklet, 2014',
          url: 'https://cdn.who.int/media/docs/default-source/mca-documents/child/imci-integrated-management-of-childhood-illness/imci-in-service-training/imci-chart-booklet.pdf?sfvrsn=f63af425_1',
        },
      ],
    },
  },
  {
    id: 'art_hfmd',
    reviewerLabel: 'Nhóm chuyên môn · Nhi khoa',
    data: {
      library: 'care',
      topic: 'illness',
      format: 'article',
      ageWeeks: { from: 13, to: 156 },
      readingMinutes: 4,
      cover: null,
      title: {
        vi: 'Tay chân miệng ở trẻ nhỏ: chăm tại nhà và dấu hiệu phải đi viện ngay',
        en: 'Hand, foot and mouth disease: home care and the signs that need hospital now',
      },
      summary: {
        vi: 'Tay chân miệng hay gặp ở trẻ dưới 5 tuổi, phần lớn nhẹ và tự khỏi sau 7–10 ngày. Ở châu Á, một số chủng virus có thể gây biến chứng thần kinh, nên ba mẹ cần biết các dấu hiệu nặng như giật mình, sốt cao khó hạ.',
        en: 'Hand, foot and mouth disease is common under age 5 and is usually mild, clearing in 7–10 days. In Asia some strains can affect the nervous system, so know the serious signs, such as sudden jerks or a high fever that will not come down.',
      },
      body: {
        vi: [
          {
            type: 'callout',
            tone: 'note',
            title: 'Tóm tắt nhanh',
            text: 'Bé sốt, loét miệng, nổi nốt đỏ hoặc phỏng nước ở lòng bàn tay, bàn chân, mông. Chăm tại nhà: cho uống đủ, ăn đồ mềm, mát, hạ sốt khi bé khó chịu, rửa tay thật kỹ. Đưa bé đến viện ngay nếu bé giật mình, sốt từ 39 °C hoặc sốt kéo dài từ 48 giờ, nôn nhiều, lừ đừ, đi loạng choạng hay thở nhanh.',
          },
          { type: 'heading', text: 'Hiểu đúng về tay chân miệng' },
          {
            type: 'paragraph',
            text: 'Tay chân miệng do một nhóm virus đường ruột (enterovirus) gây ra, hay gặp nhất là Coxsackie A16 và Enterovirus A71 (EV71). Bệnh lây qua nước bọt, dịch nốt phỏng, phân, qua tay và đồ chơi; virus còn theo phân ra ngoài nhiều tuần sau khi bé đã khỏi. Trẻ dưới 5 tuổi hay mắc nhất, nhất là khi đi nhà trẻ.',
          },
          {
            type: 'paragraph',
            text: 'Thường bé sốt nhẹ hoặc vừa, đau họng, chảy dãi, ăn kém vì loét miệng, rồi nổi nốt đỏ hoặc phỏng nước ở lòng bàn tay, lòng bàn chân, đầu gối, mông. Phần lớn bé đỡ sau 7–10 ngày. Theo WHO, EV71 có thể gây biến chứng như viêm màng não, viêm não, liệt; các đợt dịch nặng chủ yếu gặp ở châu Á – Thái Bình Dương, nên ở Việt Nam và các nước trong vùng, ba mẹ cần theo dõi bé sát hơn trong những ngày đầu.',
          },
          {
            type: 'paragraph',
            text: 'Ở Việt Nam: tay chân miệng hay tăng vào mùa tựu trường. Hướng dẫn trong nước nhấn mạnh việc theo dõi giật mình và sốt cao, và trẻ thường được cho nghỉ ở nhà, không đến nhà trẻ khoảng 7–14 ngày đầu của bệnh; hãy làm theo hướng dẫn của trạm y tế và nhà trường. Ở Anh, NHS cho rằng trẻ có thể đi học lại khi đã khoẻ.',
          },
          { type: 'heading', text: 'Ba mẹ có thể làm gì' },
          {
            type: 'bullets',
            items: [
              'Cho bé uống đủ: bú mẹ, bú sữa thường xuyên hơn; bé lớn uống nước mát, sữa từng ngụm nhỏ. Thức ăn mềm, nguội hoặc mát, ít chua, ít mặn để đỡ rát miệng.',
              'Hạ sốt khi bé khó chịu bằng thuốc hạ sốt cho trẻ, đúng liều theo cân nặng; hỏi bác sĩ hoặc dược sĩ. Không dùng aspirin. Mặc thoáng, không ủ ấm.',
              'Không chọc vỡ nốt phỏng; giữ da sạch, khô; cắt ngắn móng tay bé.',
              'Không tự bôi thuốc, xanh methylen hay đắp lá lên nốt phỏng, vết loét miệng khi bác sĩ chưa dặn.',
              'Rửa tay bằng xà phòng sau khi thay tã, lau mũi, dọn phân và trước khi chuẩn bị đồ ăn; lau rửa đồ chơi, tay nắm cửa, sàn nhà bằng chất tẩy rửa thông thường.',
              'Cho bé nghỉ ở nhà, tách khỏi trẻ nhỏ khác, không dùng chung thìa, cốc, khăn.',
              'Ghi lại nhiệt độ, giờ đo, số lần giật mình nếu có và lượng ăn uống (có thể ghi trong Child Life) để kể với bác sĩ.',
            ],
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'Giật mình là thế nào?',
            text: 'Đó là những cái giật nảy người đột ngột, hay xảy ra lúc bé sắp ngủ hoặc vừa ngủ, như bị ai làm cho hoảng. Nếu trước đây bé không hay như vậy mà nay bé giật mình, dù chỉ một lần, hãy đưa bé đi khám ngay và kể rõ bé giật bao nhiêu lần.',
          },
          { type: 'heading', text: 'Theo dõi' },
          {
            type: 'bullets',
            items: [
              'Nhiệt độ: sốt từ 39 °C, sốt khó hạ hoặc kéo dài từ 48 giờ.',
              'Giật mình, run tay chân, đi đứng loạng choạng, nhìn ngơ ngác hay mắt nhìn lệch.',
              'Lượng ăn uống và số tã ướt: loét miệng khiến bé dễ bỏ ăn uống, mất nước.',
              'Nhịp thở, màu da, tay chân có lạnh, da có nổi vân tím không.',
              'Giấc ngủ: quấy khóc, bứt rứt, khó ngủ khác hẳn mọi khi.',
            ],
          },
          { type: 'heading', text: 'Hiểu lầm thường gặp' },
          {
            type: 'bullets',
            items: [
              '“Hết sốt, nốt khô là khỏi, đi học được ngay”: virus còn theo phân ra ngoài nhiều tuần. Nên: theo hướng dẫn nghỉ học của trạm y tế, nhà trường, và tiếp tục rửa tay kỹ.',
              '“Kiêng tắm, kiêng nước để nốt không lan”: nước không làm bệnh lan. Nên: tắm nhanh bằng nước ấm, thấm khô nhẹ, không chà xát nốt phỏng.',
              '“Bị một lần rồi thì không bị lại”: nhiều chủng virus gây tay chân miệng nên bé có thể mắc lại. Nên: duy trì rửa tay, vệ sinh đồ chơi.',
              '“Giật mình là do sợ, do vía”: ở trẻ bị tay chân miệng, giật mình có thể là dấu hiệu virus ảnh hưởng thần kinh. Nên: đưa bé đi khám ngay.',
            ],
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Gọi 115 hoặc đến viện ngay khi',
            text: 'Bé giật mình, run chi, đi loạng choạng, yếu tay chân; co giật; li bì, khó đánh thức; thở nhanh, thở khó; vã mồ hôi, tay chân lạnh, da nổi vân tím; nôn nhiều; sốt từ 39 °C hoặc sốt kéo dài từ 48 giờ. Đừng chờ, gọi 115 hoặc đến bệnh viện ngay.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Đưa bé đi khám trong ngày khi',
            text: 'Bé dưới 6 tháng bị tay chân miệng; bé bỏ ăn uống, ít tã ướt hoặc có dấu hiệu mất nước; quấy khóc, bứt rứt, khó ngủ; nốt phỏng sưng đỏ, có mủ; bé có bệnh mạn tính; hoặc ba mẹ thấy lo. Nếu bé nặng lên nhanh, gọi 115.',
          },
        ],
        en: [
          {
            type: 'callout',
            tone: 'note',
            title: 'In short',
            text: 'Fever, mouth ulcers and red spots or blisters on the palms, soles and bottom. At home: keep up drinks, offer soft, cool food, treat fever when your baby is uncomfortable and wash hands carefully. Go to hospital straight away if your child has sudden jerks, a fever of 39 °C or more or lasting 48 hours, vomits a lot, is listless, walks unsteadily or breathes fast.',
          },
          { type: 'heading', text: 'Understanding hand, foot and mouth disease' },
          {
            type: 'paragraph',
            text: 'Hand, foot and mouth disease is caused by a group of gut viruses (enteroviruses), most often Coxsackie A16 and Enterovirus A71 (EV71). It spreads through saliva, fluid from blisters, stools, hands and toys, and the virus can stay in the stools for weeks after your child is well. Children under 5 are most often affected, especially at childcare.',
          },
          {
            type: 'paragraph',
            text: 'Usually there is a mild or moderate fever, a sore throat, drooling and poor eating because of mouth ulcers, then red spots or blisters on the palms, soles, knees and bottom. Most children improve within 7–10 days. According to WHO, EV71 can cause complications such as meningitis, encephalitis and paralysis; severe outbreaks have mainly occurred in the Asia-Pacific region, so in Việt Nam and neighbouring countries watch your child more closely in the first days.',
          },
          {
            type: 'paragraph',
            text: 'In Việt Nam: cases often rise when school starts. Local guidance stresses watching for sudden jerks and high fever, and children are usually kept home from childcare for about the first 7–14 days of the illness; follow your health station and childcare provider. In the UK, the NHS says children can go back once they feel well.',
          },
          { type: 'heading', text: 'What you can do' },
          {
            type: 'bullets',
            items: [
              'Keep up fluids: breastfeed or bottle-feed more often; older children can sip cool water or milk. Offer soft, cool food that is not acidic or salty, so it stings less.',
              'Treat fever when your child is uncomfortable with a children’s fever medicine at the right dose for their weight; ask a doctor or pharmacist. Never give aspirin. Dress them lightly; do not bundle them up.',
              'Do not pop the blisters; keep the skin clean and dry; keep nails short.',
              'Do not put creams, dyes or leaves on the blisters or mouth ulcers unless a doctor advises it.',
              'Wash hands with soap after diaper changes, wiping noses and cleaning up stools, and before preparing food; clean toys, door handles and floors with ordinary household cleaner.',
              'Keep your child at home, away from other young children, with their own spoon, cup and towel.',
              'Note temperatures and times, any jerks and how much your child eats and drinks (you can log these in Child Life) to tell the doctor.',
            ],
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'What do the “jerks” look like?',
            text: 'They are sudden startle-like jerks of the whole body, often as your child falls asleep or soon after, as if something frightened them. If your child did not usually do this and now does, even once, take them to be seen straight away and say how many times it happened.',
          },
          { type: 'heading', text: 'What to watch' },
          {
            type: 'bullets',
            items: [
              'Temperature: 39 °C or more, a fever that will not come down, or one lasting 48 hours or more.',
              'Sudden jerks, trembling arms or legs, unsteady walking, a vacant stare or eyes not looking the same way.',
              'How much your child eats and drinks and how many wet diapers: mouth ulcers make children refuse food and drink and become dehydrated.',
              'Breathing rate, skin colour, cold hands and feet, blotchy purple skin.',
              'Sleep: crying, restlessness or trouble sleeping that is unlike your child.',
            ],
          },
          { type: 'heading', text: 'Common misconceptions' },
          {
            type: 'bullets',
            items: [
              '“Once the fever is gone and spots are dry, they can go straight back”: the virus stays in stools for weeks. Instead: follow your health station’s and childcare’s advice, and keep up careful handwashing.',
              '“No baths, or the spots will spread”: water does not spread the illness. Instead: a quick warm bath, pat dry and do not rub the blisters.',
              '“Once is enough, they cannot get it again”: several viruses cause it, so children can catch it more than once. Instead: keep up handwashing and cleaning toys.',
              '“The jerks are just fright, or spirits”: in hand, foot and mouth disease, jerks can be a sign the virus is affecting the nervous system. Instead: get your child seen straight away.',
            ],
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Call 115 (Việt Nam) or go to hospital now if',
            text: 'Your child has sudden jerks, trembling limbs, unsteady walking or weak arms or legs; has a fit; is very drowsy or hard to wake; breathes fast or with difficulty; is sweating with cold hands and feet or blotchy purple skin; vomits a lot; or has a fever of 39 °C or more or lasting 48 hours. Do not wait; call your local emergency number or go to hospital.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'See a doctor the same day if',
            text: 'Your baby is under 6 months; your child refuses food and drink, has fewer wet diapers or signs of dehydration; is crying, restless or cannot sleep; has red, swollen or pus-filled blisters; has a long-term condition; or you are worried. If your child gets worse quickly, call emergency services.',
          },
        ],
      },
      keywords: {
        vi: ['tay chân miệng', 'EV71', 'giật mình', 'loét miệng', 'nốt phỏng', 'nghỉ học'],
        en: [
          'hand foot and mouth',
          'EV71',
          'sudden jerks',
          'mouth ulcers',
          'blisters',
          'staying home from childcare',
        ],
      },
      relatedArticleIds: [
        'art_fever_when_to_call',
        'art_diarrhoea_dehydration',
        'art_medicine_safety',
        'art_cold_cough',
      ],
      milestoneIds: [],
      sources: [
        {
          label: 'Bệnh viện Nhi Trung ương — Hướng dẫn chẩn đoán bệnh tay chân miệng',
          url: 'https://benhviennhitrunguong.gov.vn/huong-dan-chan-doan-benh-tay-chan-mieng.html',
        },
        {
          label: 'NHS — Hand, foot and mouth disease',
          url: 'https://www.nhs.uk/conditions/hand-foot-mouth-disease/',
        },
        {
          label: 'WHO — Enterovirus 71 (vaccine standardization page)',
          url: 'https://www.who.int/teams/health-product-policy-and-standards/standards-and-specifications/norms-and-standards/vaccine-standardization/enterovirus-71',
        },
        {
          label: 'WHO Western Pacific — Hand, foot and mouth disease (surveillance archive)',
          url: 'https://www.who.int/westernpacific/emergencies/surveillance/archives/hand-foot-and-mouth-disease',
        },
      ],
    },
  },
  {
    id: 'art_growth_charts',
    reviewerLabel: 'Nhóm chuyên môn · Nhi khoa',
    data: {
      library: 'care',
      topic: 'development',
      format: 'article',
      ageWeeks: { from: 0, to: 104 },
      readingMinutes: 4,
      cover: null,
      title: {
        vi: 'Cân nặng, chiều dài, vòng đầu: đọc biểu đồ tăng trưởng mà không lo lắng',
        en: 'Weight, length and head size: reading growth charts without worry',
      },
      summary: {
        vi: 'Biểu đồ tăng trưởng của WHO cho thấy bé đang lớn theo đường của riêng mình. Điều quan trọng là xu hướng qua nhiều lần đo, không phải một con số hay so với bé nhà khác.',
        en: 'WHO growth charts show your baby growing along their own curve. What matters is the trend across several measurements, not a single number or a comparison with other babies.',
      },
      body: {
        vi: [
          {
            type: 'callout',
            tone: 'note',
            title: 'Tóm tắt nhanh',
            text: 'Bách phân vị cho biết bé so với trẻ khoẻ cùng tuổi, cùng giới: bách phân vị 25 nghĩa là khoảng 25 trên 100 bé nhẹ hơn. Bé ở bách phân vị thấp hay cao đều có thể khoẻ mạnh. Hãy để ý khi đường của bé đi ngang, tụt hoặc vọt qua nhiều vạch, và cân đo ở cơ sở y tế với cân, thước chuẩn.',
          },
          { type: 'heading', text: 'Hiểu đúng về biểu đồ tăng trưởng' },
          {
            type: 'paragraph',
            text: 'Chuẩn tăng trưởng trẻ em của WHO (2006) được xây dựng từ trẻ bú mẹ, khoẻ mạnh, được chăm sóc tốt ở sáu nước, nên mô tả cách trẻ nên lớn khi được nuôi dưỡng tốt. Nhiều nước dùng chuẩn này cho trẻ dưới 2 tuổi, trong đó có Việt Nam, Anh (biểu đồ UK-WHO) và Mỹ. Có biểu đồ riêng cho bé trai, bé gái; bé sinh non được chấm theo tuổi hiệu chỉnh.',
          },
          {
            type: 'paragraph',
            text: 'Ba chỉ số chính trong 2 năm đầu là cân nặng, chiều dài (đo nằm) và vòng đầu. Mỗi đường cong trên biểu đồ là một bách phân vị. Không có bách phân vị “đúng”: bé ở đường thứ 9 và bé ở đường thứ 91 đều có thể khoẻ. Điều bác sĩ xem là bé có lớn đều theo một đường hay không, và cân nặng có tương xứng với chiều dài không.',
          },
          {
            type: 'paragraph',
            text: 'Những ngày đầu bé sụt cân là thường gặp; phần lớn bé lấy lại cân nặng lúc sinh vào khoảng 2 tuần tuổi. Trong vài tháng đầu, đường của bé có thể dịch lên xuống một chút trước khi ổn định. Sau 1 tuổi, bé lớn chậm hơn hẳn và thường ăn ít đi so với cân nặng.',
          },
          { type: 'heading', text: 'Ba mẹ có thể làm gì' },
          {
            type: 'bullets',
            items: [
              'Cân, đo ở trạm y tế hoặc phòng khám, mỗi lần dùng cùng loại cân, bé cởi bớt quần áo và tháo tã. Cân ở nhà dễ lệch vài trăm gam.',
              'Dưới 2 tuổi, chiều dài được đo khi bé nằm thẳng trên thước đo, có hai người cùng giữ bé.',
              'Ghi lại các lần đo trong Child Life hoặc sổ theo dõi sức khoẻ của bé để nhìn được xu hướng qua nhiều tháng.',
              'Bé sinh non: chấm theo tuổi hiệu chỉnh đến khoảng 2 tuổi, theo hướng dẫn của bác sĩ (xem bài Bé sinh non và tuổi hiệu chỉnh).',
              'Không cần cân bé hằng ngày: cân nặng dao động theo cữ bú, cữ đi ngoài. Với bé khoẻ, cân theo lịch khám là đủ.',
              'Cho bé ăn theo tín hiệu đói no; không ép ăn hay pha sữa đặc hơn hướng dẫn để bé “lên ký”.',
            ],
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'So bé với chính bé',
            text: 'Ba mẹ cao thì con thường cao hơn, ba mẹ nhỏ người thì con thường nhỏ hơn. So với con nhà hàng xóm hay với một “cân nặng chuẩn” trên mạng dễ làm ba mẹ lo không cần thiết. Hãy nhìn đường cong của chính bé qua nhiều tháng.',
          },
          { type: 'heading', text: 'Theo dõi' },
          {
            type: 'bullets',
            items: [
              'Đường cân nặng, chiều dài, vòng đầu qua các lần đo: lên đều, đi ngang hay tụt.',
              'Cân nặng cắt xuống qua hai vạch bách phân vị chính trở lên, hoặc đi ngang nhiều tháng.',
              'Vòng đầu tăng rất nhanh, vượt nhiều vạch, hoặc gần như không tăng.',
              'Ăn uống, đi ngoài, tâm trạng và mức hoạt động của bé, quan trọng không kém con số.',
            ],
          },
          { type: 'heading', text: 'Hiểu lầm thường gặp' },
          {
            type: 'bullets',
            items: [
              '“Bé phải nằm trên đường giữa mới là khoẻ”: đường giữa chỉ là bách phân vị 50; một nửa số trẻ khoẻ nằm dưới đường này. Nên: xem bé có lớn đều theo đường của mình không.',
              '“Bé mũm mĩm mới là khoẻ, gầy là suy dinh dưỡng”: bé tăng cân vượt nhiều vạch cũng cần bác sĩ xem, còn bé thon gọn mà lớn đều thường khoẻ. Nên: hỏi bác sĩ khi lo, đừng tự ép ăn.',
              '“Chậm lên cân thì mua thuốc bổ, men, siro cho ăn ngon”: các sản phẩm này không thay được bữa ăn đủ chất và có loại có tác dụng phụ. Nên: đưa bé khám để tìm nguyên nhân.',
              '“Sau 1 tuổi ăn ít đi là biếng ăn”: tốc độ lớn chậm lại nên bé cần ăn ít hơn so với cân nặng. Nên: theo dõi đường cong; bé vẫn lớn đều thì không cần lo.',
            ],
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Khi nào nên hỏi bác sĩ',
            text: 'Cân nặng tụt qua hai vạch bách phân vị chính, đi ngang nhiều tháng, hoặc bé sụt cân; bé chưa lấy lại cân nặng lúc sinh sau 2 tuần; vòng đầu tăng rất nhanh hoặc không tăng; chiều dài gần như không tăng; bé bú, ăn kém kéo dài, nôn nhiều, tiêu chảy kéo dài; hoặc ba mẹ thấy lo. Đưa bé đi khám ngay nếu thóp phồng căng kèm nôn, li bì, hoặc bé mệt lả.',
          },
        ],
        en: [
          {
            type: 'callout',
            tone: 'note',
            title: 'In short',
            text: 'A percentile compares your baby with healthy babies of the same age and sex: the 25th percentile means about 25 in 100 babies weigh less. Babies on low or high percentiles can both be healthy. Watch for a curve that flattens, drops or climbs across several lines, and have your baby weighed and measured at a clinic with proper equipment.',
          },
          { type: 'heading', text: 'Understanding growth charts' },
          {
            type: 'paragraph',
            text: 'The WHO Child Growth Standards (2006) were built from healthy, breastfed, well-cared-for children in six countries, so they describe how children should grow when well nourished. Many countries use them for children under 2, including Việt Nam, the UK (UK-WHO charts) and the US. There are separate charts for boys and girls; babies born early are plotted by corrected age.',
          },
          {
            type: 'paragraph',
            text: 'The three main measures in the first two years are weight, length (measured lying down) and head circumference. Each curve on the chart is a percentile. There is no “right” percentile: a baby on the 9th line and one on the 91st can both be healthy. What the doctor looks at is whether your baby grows steadily along a line, and whether weight is in proportion to length.',
          },
          {
            type: 'paragraph',
            text: 'Losing some weight in the first days is common; most babies are back to birth weight by about 2 weeks. In the first months your baby’s curve may shift a little before it settles. After the first birthday, growth slows a lot and toddlers often eat less for their size.',
          },
          { type: 'heading', text: 'What you can do' },
          {
            type: 'bullets',
            items: [
              'Have your baby weighed and measured at a clinic, on the same kind of scale each time, undressed and without a diaper. Home scales can be off by a few hundred grams.',
              'Under 2, length is measured with your baby lying straight on a measuring board, held by two people.',
              'Record each measurement in Child Life or your baby’s health record so you can see the trend over months.',
              'Babies born early: plot by corrected age until about age 2, as your doctor advises (see Babies born early and corrected age).',
              'There is no need to weigh your baby every day: weight goes up and down with feeds and stools. For a healthy baby, weighing at scheduled check-ups is enough.',
              'Feed to your baby’s hunger and fullness cues; never force-feed or make formula stronger to “add weight”.',
            ],
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'Compare your baby with themselves',
            text: 'Tall parents tend to have taller children and smaller parents smaller ones. Comparing with the neighbours’ baby or a “standard weight” online can cause needless worry. Look at your own baby’s curve over several months.',
          },
          { type: 'heading', text: 'What to watch' },
          {
            type: 'bullets',
            items: [
              'The weight, length and head curves across visits: rising steadily, flattening or dropping.',
              'Weight falling across two or more major percentile lines, or staying flat for several months.',
              'Head size growing very fast across several lines, or hardly growing.',
              'How your baby eats, poos, plays and how lively they are, which matters as much as the numbers.',
            ],
          },
          { type: 'heading', text: 'Common misconceptions' },
          {
            type: 'bullets',
            items: [
              '“A healthy baby must be on the middle line”: the middle line is just the 50th percentile; half of healthy babies are below it. Instead: check that your baby grows steadily along their own line.',
              '“Chubby means healthy, slim means malnourished”: a baby climbing across many lines also needs a check, and a slim baby growing steadily is usually healthy. Instead: ask the doctor if you are worried; do not force-feed.',
              '“Slow weight gain needs tonics, probiotics or appetite syrups”: these do not replace good meals and some have side effects. Instead: take your baby to the doctor to find the cause.',
              '“Eating less after age 1 means a feeding problem”: growth slows, so toddlers need less food for their size. Instead: follow the curve; if it is steady, there is no need to worry.',
            ],
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'When to ask a doctor',
            text: 'Weight drops across two major percentile lines, stays flat for months, or your baby loses weight; your baby is not back to birth weight after 2 weeks; head size grows very fast or not at all; length hardly increases; long-lasting poor feeding, frequent vomiting or diarrhoea; or you are worried. Get your baby seen at once if the soft spot bulges with vomiting or drowsiness, or your baby seems very unwell.',
          },
        ],
      },
      keywords: {
        vi: [
          'biểu đồ tăng trưởng',
          'bách phân vị',
          'cân nặng',
          'chiều dài',
          'vòng đầu',
          'chậm tăng cân',
        ],
        en: [
          'growth chart',
          'percentile',
          'weight',
          'length',
          'head circumference',
          'slow weight gain',
        ],
      },
      relatedArticleIds: [
        'art_preterm_corrected_age',
        'art_breastfeeding_start',
        'art_picky_eating_toddler',
        'art_solids_textures_by_month',
      ],
      milestoneIds: [],
      sources: [
        {
          label: 'WHO — Child growth standards',
          url: 'https://www.who.int/tools/child-growth-standards',
        },
        {
          label: 'RCPCH — UK-WHO growth charts, 0–4 years',
          url: 'https://www.rcpch.ac.uk/resources/uk-who-growth-charts-0-4-years',
        },
        {
          label:
            "HealthyChildren.org (AAP) — Your baby's first month: growth and physical appearance",
          url: 'https://www.healthychildren.org/English/ages-stages/baby/Pages/First-Month-Physical-Appearance-and-Growth.aspx',
        },
        {
          label: 'WHO — Infant and young child feeding (fact sheet)',
          url: 'https://www.who.int/news-room/fact-sheets/detail/infant-and-young-child-feeding',
        },
      ],
    },
  },
  {
    id: 'art_preterm_corrected_age',
    reviewerLabel: 'Nhóm chuyên môn · Phát triển trẻ em',
    data: {
      library: 'care',
      topic: 'development',
      format: 'article',
      ageWeeks: { from: 0, to: 104 },
      readingMinutes: 4,
      cover: null,
      title: {
        vi: 'Bé sinh non: tuổi hiệu chỉnh, mốc phát triển và những điều ba mẹ nên biết',
        en: 'Babies born early: corrected age, milestones and what to know',
      },
      summary: {
        vi: 'Với bé sinh trước 37 tuần, ba mẹ dùng tuổi hiệu chỉnh khi đối chiếu mốc phát triển và tăng trưởng, thường đến khoảng 2 tuổi. Lịch tiêm chủng vẫn theo ngày sinh.',
        en: 'For babies born before 37 weeks, use corrected age when comparing milestones and growth, usually until about age 2. Vaccinations still follow the date of birth.',
      },
      body: {
        vi: [
          {
            type: 'callout',
            tone: 'note',
            title: 'Tóm tắt nhanh',
            text: 'Tuổi hiệu chỉnh là tuổi tính từ ngày sinh trừ đi số tuần bé sinh sớm so với 40 tuần. Bé 4 tháng tuổi sinh lúc 32 tuần, tức sớm 8 tuần, có tuổi hiệu chỉnh khoảng 2 tháng. Dùng tuổi hiệu chỉnh cho mốc phát triển và biểu đồ tăng trưởng đến khoảng 2 tuổi; tiêm chủng theo tuổi thật, trừ khi bác sĩ dặn khác.',
          },
          { type: 'heading', text: 'Hiểu đúng về tuổi hiệu chỉnh' },
          {
            type: 'paragraph',
            text: 'Thai kỳ đủ tháng khoảng 40 tuần. Bé sinh non đã có ít tuần phát triển trong bụng mẹ hơn, nên khi so với các mốc dành cho bé đủ tháng, ba mẹ trừ đi số tuần sinh sớm. AAP khuyên dùng tuổi hiệu chỉnh khi đánh giá sự phát triển của bé sinh non; phần lớn bé dần bắt kịp bạn cùng tuổi vào khoảng 2 tuổi, bé sinh rất non có thể cần lâu hơn.',
          },
          {
            type: 'paragraph',
            text: 'Cách tính: lấy 40 trừ số tuần thai lúc sinh, ra số tuần sinh sớm; rồi lấy tuổi thật trừ số tuần đó. Ví dụ bé sinh lúc 34 tuần là sớm 6 tuần; khi bé được 3 tháng, khoảng 13 tuần, theo ngày sinh, tuổi hiệu chỉnh là khoảng 7 tuần.',
          },
          {
            type: 'paragraph',
            text: 'Trong Child Life, các khoảng tham khảo của mốc phát triển hiện được tính theo ngày sinh. Nếu bé sinh non, hãy cộng thêm số tuần sinh sớm khi đọc các khoảng này, và đừng lo nếu bé đạt mốc muộn hơn so với tuổi thật.',
          },
          { type: 'heading', text: 'Ba mẹ có thể làm gì' },
          {
            type: 'bullets',
            items: [
              'Ghi rõ tuần thai lúc sinh và ngày dự sinh trong hồ sơ của bé, và nói với mọi bác sĩ khám cho bé rằng bé sinh non.',
              'Đối chiếu mốc phát triển như lẫy, ngồi, cười, bập bẹ theo tuổi hiệu chỉnh đến khoảng 2 tuổi.',
              'Tiêm chủng theo tuổi thật tính từ ngày sinh, đúng lịch; bé sinh non dễ bị bệnh nặng hơn nên càng cần tiêm đúng hẹn. Hỏi bác sĩ nếu bé còn nằm viện hoặc có bệnh lý riêng.',
              'Ăn dặm: hỏi bác sĩ thời điểm phù hợp; với bé sinh non, bác sĩ thường dựa trên cả tuổi thật, tuổi hiệu chỉnh và các dấu hiệu sẵn sàng của bé.',
              'Vitamin D và sắt: bé sinh non thường cần bổ sung sớm hơn, liều khác; làm đúng theo chỉ định của bác sĩ.',
              'Ngủ an toàn như mọi bé: nằm ngửa, nôi riêng, mặt phẳng, chắc; không ngủ chung giường với bé sinh non.',
              'Đi tái khám đúng hẹn: mắt, thính lực, tăng trưởng và phát triển, theo chỉ định của bác sĩ.',
              'Hạn chế người ốm đến thăm, rửa tay trước khi bế bé, nhất là trong mùa cúm và RSV.',
            ],
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'Ba mẹ cũng cần được nghỉ',
            text: 'Thời gian nằm viện, ở phòng sơ sinh và những tháng đầu ở nhà có thể rất căng thẳng. Hãy nhận giúp đỡ, nói ra cảm xúc, và tìm hỗ trợ nếu thấy buồn, lo kéo dài (xem bài Ba mẹ cũng cần được chăm).',
          },
          { type: 'heading', text: 'Theo dõi' },
          {
            type: 'bullets',
            items: [
              'Mốc phát triển theo tuổi hiệu chỉnh: bé có tiến bộ dần theo tháng không.',
              'Tăng trưởng trên biểu đồ theo tuổi hiệu chỉnh hoặc biểu đồ dành cho bé sinh non.',
              'Bú, ăn, nhịp thở khi ngủ, những lúc ngừng thở hay tím tái.',
              'Trương lực cơ: người quá mềm, quá cứng, hay dùng một bên người nhiều hơn.',
            ],
          },
          { type: 'heading', text: 'Hiểu lầm thường gặp' },
          {
            type: 'bullets',
            items: [
              '“Sinh non thì cho ăn dặm sớm, uống thêm thuốc bổ cho mau bắt kịp”: ăn khi chưa sẵn sàng dễ sặc và không giúp bé lớn nhanh hơn. Nên: theo hướng dẫn dinh dưỡng của bác sĩ.',
              '“Sinh non thì hoãn tiêm chủng cho cứng cáp”: bé sinh non dễ mắc bệnh nặng hơn và vắc xin vẫn hiệu quả. Nên: tiêm theo tuổi thật, trừ khi bác sĩ dặn khác.',
              '“Bé chậm hơn bạn cùng tháng là có vấn đề”: so với tuổi thật thì đạt mốc muộn hơn là điều được dự đoán. Nên: so theo tuổi hiệu chỉnh và hỏi bác sĩ khi lo.',
              '“Ủ thật ấm, đóng kín phòng cho bé non khỏi lạnh”: bé cần ấm vừa đủ, còn quá nóng làm tăng nguy cơ đột tử. Nên: mặc vừa đủ, sờ gáy hoặc ngực để kiểm tra.',
            ],
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Gọi 115 hoặc đến cấp cứu ngay khi',
            text: 'Bé ngừng thở, tím tái, thở rên hay rút lõm ngực; li bì, khó đánh thức, lả mềm; co giật; bé dưới 3 tháng tuổi thật có nhiệt độ từ 38 °C trở lên, hoặc thân nhiệt thấp dưới 36 °C.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Khi nào nên hỏi bác sĩ',
            text: 'Bé chưa đạt mốc so với tuổi hiệu chỉnh, mất kỹ năng đã có, quá mềm hoặc quá cứng; bú kém, chậm tăng cân; ba mẹ lo về mắt hay khả năng nghe của bé; hoặc ba mẹ chưa chắc cách tính tuổi hiệu chỉnh cho bé.',
          },
        ],
        en: [
          {
            type: 'callout',
            tone: 'note',
            title: 'In short',
            text: 'Corrected age is the age from the date of birth minus the number of weeks your baby was born before 40 weeks. A 4-month-old born at 32 weeks, 8 weeks early, has a corrected age of about 2 months. Use corrected age for milestones and growth charts until about age 2; vaccinations follow actual age unless the doctor says otherwise.',
          },
          { type: 'heading', text: 'Understanding corrected age' },
          {
            type: 'paragraph',
            text: 'A full-term pregnancy is about 40 weeks. A baby born early had fewer weeks of growth in the womb, so when comparing with milestones for term babies, take off the weeks they were early. The AAP advises using corrected age to assess a preterm baby’s development; most catch up with children their age by about 2 years, and babies born very early may take longer.',
          },
          {
            type: 'paragraph',
            text: 'How to work it out: 40 minus the weeks of pregnancy at birth gives the weeks early; then subtract that from actual age. For example, a baby born at 34 weeks is 6 weeks early; at 3 months, about 13 weeks, from birth, the corrected age is about 7 weeks.',
          },
          {
            type: 'paragraph',
            text: 'In Child Life, the reference windows for milestones are currently counted from the date of birth. If your baby was born early, add the weeks they were early when you read these windows, and do not worry if milestones come later than their actual age suggests.',
          },
          { type: 'heading', text: 'What you can do' },
          {
            type: 'bullets',
            items: [
              'Record the weeks of pregnancy at birth and the due date in your baby’s profile, and tell every doctor who sees your baby that they were born early.',
              'Compare milestones such as rolling, sitting, smiling and babbling with corrected age until about age 2.',
              'Vaccinate by actual age from birth, on time; babies born early are more likely to get seriously ill, so on-time vaccines matter even more. Ask the doctor if your baby is still in hospital or has a specific condition.',
              'Solids: ask your doctor when to start; for babies born early, doctors usually weigh up actual age, corrected age and your baby’s signs of readiness.',
              'Vitamin D and iron: babies born early often need supplements sooner and at different doses; follow your doctor exactly.',
              'Safe sleep as for every baby: on the back, in their own crib, on a firm flat surface; do not bed-share with a baby born early.',
              'Keep follow-up appointments for eyes, hearing, growth and development, as your doctor advises.',
              'Limit visits from anyone who is ill and wash hands before holding your baby, especially in flu and RSV season.',
            ],
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'You need rest too',
            text: 'Time in hospital, in the neonatal unit and the first months at home can be very stressful. Accept help, talk about how you feel, and get support if low mood or worry lasts (see Parents need care too).',
          },
          { type: 'heading', text: 'What to watch' },
          {
            type: 'bullets',
            items: [
              'Milestones by corrected age: whether your baby makes steady progress month by month.',
              'Growth plotted by corrected age or on a chart for babies born early.',
              'Feeding, breathing during sleep, any pauses in breathing or turning blue.',
              'Muscle tone: very floppy or very stiff, or using one side of the body more.',
            ],
          },
          { type: 'heading', text: 'Common misconceptions' },
          {
            type: 'bullets',
            items: [
              '“Babies born early should start solids sooner and take tonics to catch up”: eating before they are ready raises choking risk and does not speed up growth. Instead: follow your doctor’s feeding plan.',
              '“Delay vaccines until a preterm baby is stronger”: babies born early are more at risk of serious illness, and vaccines still work. Instead: vaccinate by actual age unless the doctor says otherwise.',
              '“Being behind babies born the same month means a problem”: compared with actual age, later milestones are expected. Instead: compare with corrected age and ask the doctor if you are worried.',
              '“Bundle up a preterm baby and seal the room”: babies need to be warm enough, but overheating raises the risk of sudden infant death. Instead: dress them sensibly and feel the back of the neck or chest.',
            ],
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Call 115 (Việt Nam) or local emergency services now if',
            text: 'Your baby stops breathing, turns blue, grunts or the chest pulls in; is floppy, very drowsy or hard to wake; has a fit; or is under 3 months of actual age with a temperature of 38 °C or more, or a low temperature under 36 °C.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'When to ask a doctor',
            text: 'Your baby has not reached milestones for their corrected age, loses a skill, or seems very floppy or very stiff; feeds poorly or gains weight slowly; you have concerns about their eyes or hearing; or you are unsure how to work out their corrected age.',
          },
        ],
      },
      keywords: {
        vi: [
          'sinh non',
          'tuổi hiệu chỉnh',
          'ngày dự sinh',
          'mốc phát triển',
          'tiêm chủng',
          'phòng sơ sinh',
        ],
        en: [
          'premature',
          'corrected age',
          'due date',
          'milestones',
          'vaccinations',
          'neonatal unit',
        ],
      },
      relatedArticleIds: [
        'art_growth_charts',
        'art_safe_sleep',
        'art_vitamin_d_iron',
        'art_parent_wellbeing',
      ],
      milestoneIds: ['rolls_over', 'sits_up', 'first_smile'],
      sources: [
        {
          label: 'HealthyChildren.org (AAP) — Corrected age for preemies',
          url: 'https://www.healthychildren.org/English/ages-stages/baby/preemie/Pages/Corrected-Age-For-Preemies.aspx',
        },
        {
          label: 'HealthyChildren.org (AAP) — Preemie',
          url: 'https://www.healthychildren.org/English/ages-stages/baby/preemie/Pages/default.aspx',
        },
        {
          label: 'NICE NG72 — Developmental follow-up of children and young people born preterm',
          url: 'https://www.nice.org.uk/guidance/ng72',
        },
        {
          label: 'WHO — Preterm birth (fact sheet)',
          url: 'https://www.who.int/news-room/fact-sheets/detail/preterm-birth',
        },
        {
          label: "HealthyChildren.org (AAP) — A parent's guide to safe sleep",
          url: 'https://www.healthychildren.org/English/ages-stages/baby/sleep/Pages/A-Parents-Guide-to-Safe-Sleep.aspx',
        },
      ],
    },
  },
  {
    id: 'art_picky_eating_toddler',
    reviewerLabel: 'Nhóm chuyên môn · Dinh dưỡng nhi',
    data: {
      library: 'solids',
      topic: 'feeding',
      format: 'article',
      ageWeeks: { from: 52, to: 104 },
      readingMinutes: 4,
      cover: null,
      title: {
        vi: 'Bé 1–2 tuổi biếng ăn, kén ăn: hiểu đúng và cho ăn không ép',
        en: 'Fussy eating at 1–2 years: understanding it and feeding without pressure',
      },
      summary: {
        vi: 'Sau 1 tuổi, bé lớn chậm lại nên thường ăn ít đi và kén hơn. Ép ăn làm bữa ăn căng thẳng và bé càng sợ ăn. Chia rõ việc của người lớn và của bé, cùng sự kiên nhẫn, giúp bé ăn đa dạng dần.',
        en: 'After age 1 growth slows, so toddlers often eat less and become choosier. Pressure makes meals tense and children more wary of food. Clear roles for you and your child, and patience, help them eat a wider range over time.',
      },
      body: {
        vi: [
          {
            type: 'callout',
            tone: 'note',
            title: 'Tóm tắt nhanh',
            text: 'Ba mẹ quyết định cho ăn gì, khi nào, ở đâu; bé quyết định ăn bao nhiêu. Mời món mới nhiều lần, có khi 10–15 lần bé mới chịu. Không ép, không dỗ bằng màn hình, không thưởng bằng đồ ngọt. Nếu bé vẫn lớn đều, chơi tốt, kén ăn thường chỉ là một giai đoạn.',
          },
          { type: 'heading', text: 'Hiểu đúng về biếng ăn, kén ăn' },
          {
            type: 'paragraph',
            text: 'Trong năm đầu, bé lớn rất nhanh; sang năm thứ hai, tốc độ lớn chậm hẳn nên nhu cầu ăn so với cân nặng cũng giảm. Theo AAP, trẻ tuổi tập đi ăn lúc nhiều lúc ít, có ngày ăn rất ít, có ngày ăn nhiều, và lượng ăn cộng lại cả tuần thường vẫn đủ.',
          },
          {
            type: 'paragraph',
            text: 'Ngại món mới là một giai đoạn hay gặp từ khoảng 18 tháng đến vài tuổi. Bé cần thấy, ngửi, chạm và nếm một món nhiều lần mới quen; NHS lưu ý có khi phải mời 10–15 lần. Ép ăn, đút khi bé đã quay đi hay doạ nạt làm bé gắn bữa ăn với căng thẳng và càng kén hơn.',
          },
          {
            type: 'paragraph',
            text: 'Ở nhiều gia đình, “biếng ăn” là nỗi lo rất lớn, và bữa ăn hay kéo dài cả tiếng với điện thoại, bế đi rong hay đuổi theo bé. Ý định là thương con, nhưng cách này khiến bé không nhận ra cảm giác đói, no của chính mình.',
          },
          { type: 'heading', text: 'Ba mẹ có thể làm gì' },
          {
            type: 'bullets',
            items: [
              'Chia ngày thành 3 bữa chính và 2 bữa phụ vào giờ tương đối cố định; giữa các bữa chỉ uống nước, không ăn vặt, uống sữa liên tục.',
              'Ngồi ăn cùng cả nhà, ở bàn hoặc ghế ăn, tắt tivi, cất điện thoại. Mỗi bữa khoảng 20–30 phút; bé thôi ăn thì dọn đi, không kéo dài.',
              'Mỗi bữa có ít nhất một món bé đã quen và thích, bên cạnh một lượng nhỏ món mới. Cho bé tự xúc, tự bốc, chấp nhận bày bừa.',
              'Mời món mới nhiều lần, nhiều cách: hấp, xào, cắt sợi, trộn cháo. Người lớn ăn cùng món đó và tỏ ra ngon miệng.',
              'Khen khi bé thử, không khen chê theo lượng ăn. Không dùng đồ ngọt làm phần thưởng hay hình phạt.',
              'Giữ sữa vừa phải: sau 1 tuổi, khoảng 2 cốc sữa, tức khoảng 480 ml mỗi ngày, là đủ; uống quá nhiều sữa hay nước ép làm bé no và ăn ít bữa chính.',
              'Phần ăn vừa với bé: khoảng ¾ đến 1 chén nhỏ mỗi bữa (UNICEF); bé đòi thêm thì cho thêm.',
              'Cho bé vận động, chơi ngoài trời, ngủ đủ: bé mệt hay buồn ngủ thường ăn kém.',
            ],
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'Việc của ba mẹ, việc của bé',
            text: 'Ba mẹ chọn món, giờ ăn và chỗ ngồi; bé chọn ăn hay không và ăn bao nhiêu trong những món đã bày. Khi người lớn thôi giành phần quyết định lượng ăn, bữa ăn thường dễ chịu hơn và bé dần ăn tốt hơn.',
          },
          { type: 'heading', text: 'Theo dõi' },
          {
            type: 'bullets',
            items: [
              'Đường cân nặng, chiều cao trên biểu đồ qua các lần khám.',
              'Số nhóm thực phẩm bé ăn trong ngày và trong tuần, không chỉ một bữa.',
              'Những món bé chịu ăn: còn bao nhiêu món, có đang ít dần không.',
              'Bé có hay nôn, sặc, oẹ, đau khi nhai nuốt, táo bón kéo dài không.',
            ],
          },
          { type: 'heading', text: 'Hiểu lầm thường gặp' },
          {
            type: 'bullets',
            items: [
              '“Bé phải ăn hết bát mới đủ chất”: bé biết khi nào mình no; ép ăn làm bé sợ bữa ăn và dễ sặc. Nên: mời, để bé tự quyết lượng, dọn đi khi bé no.',
              '“Cho xem điện thoại thì bé mới chịu há miệng”: bé nuốt mà không để ý mình đang ăn gì, no hay chưa. Nên: tắt màn hình, trò chuyện về món ăn.',
              '“Biếng ăn thì mua siro, men, thuốc cho ăn ngon”: các sản phẩm này không giải quyết nguyên nhân, có loại gây buồn ngủ hay tác dụng phụ khác. Nên: đưa bé khám nếu bé chậm lớn, đừng tự mua thuốc.',
              '“Bé chê rau thì thôi, đừng cho nữa”: bé cần nhiều lần làm quen. Nên: tiếp tục bày một ít rau mỗi bữa, không ép.',
              '“Cho uống thêm sữa bù bữa ăn”: sữa nhiều quá làm bé no và ít ăn món giàu sắt. Nên: giữ sữa khoảng 480 ml mỗi ngày, ưu tiên bữa chính.',
            ],
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Khi nào nên hỏi bác sĩ',
            text: 'Bé sụt cân, đường cân nặng tụt qua hai vạch bách phân vị hoặc đi ngang nhiều tháng; bé chỉ ăn rất ít món và ngày càng ít đi; hay nôn, sặc, oẹ khi ăn, khó nhai nuốt; táo bón hay tiêu chảy kéo dài; bé xanh xao, mệt; bé chậm nói hay ít giao tiếp kèm theo; hoặc bữa ăn trở thành cuộc chiến khiến cả nhà căng thẳng. Gọi 115 nếu bé hóc, khó thở hoặc tím tái khi ăn.',
          },
        ],
        en: [
          {
            type: 'callout',
            tone: 'note',
            title: 'In short',
            text: 'You decide what, when and where your toddler eats; your toddler decides how much. Offer new foods many times; it can take 10–15 tries. No forcing, no screens to coax, no sweets as rewards. If your child is growing steadily and playing well, fussy eating is usually a phase.',
          },
          { type: 'heading', text: 'Understanding fussy eating' },
          {
            type: 'paragraph',
            text: 'Babies grow very fast in the first year; in the second year growth slows a lot, so toddlers need less food for their size. According to the AAP, toddlers’ appetites go up and down, with very small days and big days, and intake over a whole week is usually enough.',
          },
          {
            type: 'paragraph',
            text: 'Wariness of new foods is a common phase from around 18 months to the early school years. Children need to see, smell, touch and taste a food many times before accepting it; the NHS notes it can take 10–15 tries. Forcing, spoon-feeding after they turn away or threats link meals with stress and make fussiness worse.',
          },
          {
            type: 'paragraph',
            text: 'In many families, “not eating” is a huge worry, and meals can stretch to an hour with phones, walking around or chasing the child. The intention is loving, but it stops children noticing their own hunger and fullness.',
          },
          { type: 'heading', text: 'What you can do' },
          {
            type: 'bullets',
            items: [
              'Plan 3 meals and 2 snacks at fairly regular times; between them offer only water, with no grazing on snacks or milk.',
              'Eat together at the table or in a high chair, TV off, phones away. Keep meals to about 20–30 minutes; when your child stops, clear the food without dragging it out.',
              'Include at least one familiar food your child likes at each meal, alongside a small amount of something new. Let them self-feed and accept the mess.',
              'Offer new foods many times and in different ways: steamed, stir-fried, cut in strips, mixed into porridge. Eat the same food yourself and enjoy it.',
              'Praise trying, not the amount eaten. Never use sweets as a reward or punishment.',
              'Keep milk moderate: after age 1, about 2 cups, around 480 ml a day, is enough; too much milk or juice fills children up so they eat less at meals.',
              'Child-sized portions: about ¾ to 1 small bowl per meal (UNICEF); give more if they ask.',
              'Make sure your child is active, plays outdoors and sleeps enough: tired children often eat poorly.',
            ],
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'Your job, your child’s job',
            text: 'You choose the food, the time and the place; your child chooses whether and how much to eat from what is offered. When adults stop deciding the amount, meals usually become calmer and children gradually eat better.',
          },
          { type: 'heading', text: 'What to watch' },
          {
            type: 'bullets',
            items: [
              'Weight and height on the growth chart at check-ups.',
              'How many food groups your child eats over a day and a week, not just one meal.',
              'The foods your child accepts: how many, and whether the list is shrinking.',
              'Frequent vomiting, choking, gagging, pain when chewing or swallowing, or ongoing constipation.',
            ],
          },
          { type: 'heading', text: 'Common misconceptions' },
          {
            type: 'bullets',
            items: [
              '“They must finish the bowl to get enough”: children know when they are full; forcing makes them fear meals and raises choking risk. Instead: offer, let them decide how much, and clear away when they are done.',
              '“They only open their mouth while watching a phone”: children then swallow without noticing what they eat or whether they are full. Instead: screens off, and talk about the food.',
              '“Buy syrups, probiotics or appetite medicine”: these do not fix the cause and some cause drowsiness or other side effects. Instead: see a doctor if your child is not growing well; do not buy medicines yourself.',
              '“They refused vegetables, so stop offering them”: children need many tries. Instead: keep putting a little on the plate at each meal, without pressure.',
              '“Top up with extra milk instead of meals”: too much milk fills children up and crowds out iron-rich foods. Instead: keep milk to about 480 ml a day and put meals first.',
            ],
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'When to ask a doctor',
            text: 'Your child loses weight, or the weight curve drops across two percentile lines or stays flat for months; eats very few foods and the list keeps shrinking; often vomits, chokes or gags, or struggles to chew and swallow; has ongoing constipation or diarrhoea; looks pale or tired; also has language or social concerns; or mealtimes have become a battle that stresses the whole family. Call emergency services (115 in Việt Nam) if your child chokes, struggles to breathe or turns blue while eating.',
          },
        ],
      },
      keywords: {
        vi: ['biếng ăn', 'kén ăn', 'ép ăn', 'món mới', 'bữa phụ', 'xem điện thoại khi ăn'],
        en: [
          'poor appetite',
          'fussy eating',
          'force-feeding',
          'new foods',
          'snacks',
          'screens at meals',
        ],
      },
      relatedArticleIds: [
        'art_solids_textures_by_month',
        'art_toddler_milk',
        'art_growth_charts',
        'art_screens_language',
      ],
      milestoneIds: ['uses_objects_right', 'two_hands_task'],
      sources: [
        {
          label: 'HealthyChildren.org (AAP) — Picky eaters',
          url: 'https://www.healthychildren.org/English/ages-stages/toddler/nutrition/Pages/Picky-Eaters.aspx',
        },
        {
          label: 'NHS — Fussy eaters',
          url: 'https://www.nhs.uk/baby/weaning-and-feeding/fussy-eaters/',
        },
        {
          label: 'UNICEF — Feeding your baby: 1–2 years',
          url: 'https://www.unicef.org/parenting/food-nutrition/feeding-your-baby-1-2-years',
        },
        {
          label: 'WHO — Infant and young child feeding (fact sheet)',
          url: 'https://www.who.int/news-room/fact-sheets/detail/infant-and-young-child-feeding',
        },
        {
          label: 'HealthyChildren.org (AAP) — Recommended drinks for young children ages 0–5',
          url: 'https://www.healthychildren.org/English/healthy-living/nutrition/Pages/Recommended-Drinks-for-Young-Children-Ages-0-5.aspx',
        },
      ],
    },
  },
  {
    id: 'art_toddler_milk',
    reviewerLabel: 'Nhóm chuyên môn · Dinh dưỡng nhi',
    data: {
      library: 'solids',
      topic: 'feeding',
      format: 'quick_qa',
      ageWeeks: { from: 48, to: 104 },
      readingMinutes: 2,
      cover: null,
      title: {
        vi: 'Hỏi nhanh: Bé từ 1 tuổi uống sữa gì, bao nhiêu là đủ?',
        en: 'Quick Q&A: Milk from age 1 — which kind, and how much?',
      },
      summary: {
        vi: 'Từ 12 tháng, bé có thể uống sữa bò tươi nguyên kem tiệt trùng và tiếp tục bú mẹ. Sữa công thức “tăng trưởng” cho trẻ trên 1 tuổi không cần thiết với phần lớn bé khoẻ.',
        en: 'From 12 months, toddlers can drink pasteurised whole cow’s milk and keep breastfeeding. “Growing-up” formula for children over 1 is not needed for most healthy toddlers.',
      },
      body: {
        vi: [
          {
            type: 'callout',
            tone: 'note',
            title: 'Tóm tắt nhanh',
            text: 'Sau 1 tuổi: tiếp tục bú mẹ nếu mẹ và bé muốn; nếu không bú mẹ, khoảng 2 cốc sữa bò tươi nguyên kem tiệt trùng mỗi ngày là đủ. Sữa công thức cho trẻ tập đi không có lợi hơn sữa bò ở bé khoẻ (AAP 2023).',
          },
          { type: 'heading', text: 'Có cần sữa công thức tăng trưởng không?' },
          {
            type: 'paragraph',
            text: 'Phần lớn bé không cần. Báo cáo năm 2023 của AAP cho biết các loại sữa công thức cho trẻ tập đi không có lợi hơn sữa bò ở trẻ khoẻ trên 12 tháng, thường có thêm đường và đắt hơn. NHS cũng cho rằng sữa tăng trưởng không cần thiết. Bé có bệnh lý, dị ứng hay chậm tăng cân sẽ được bác sĩ hướng dẫn loại sữa riêng.',
          },
          { type: 'heading', text: 'Uống bao nhiêu sữa là đủ?' },
          {
            type: 'paragraph',
            text: 'AAP gợi ý trẻ 12–24 tháng uống khoảng 2–3 cốc, tức 480–720 ml sữa nguyên kem mỗi ngày, và nên giữ dưới khoảng 700 ml để bé còn ăn được bữa chính giàu sắt. Uống bằng cốc, tập bỏ bình, không ngậm bình sữa đi ngủ.',
          },
          { type: 'heading', text: 'Sữa hạt, sữa đậu nành có thay được không?' },
          {
            type: 'paragraph',
            text: 'Nhiều loại sữa hạt ít đạm và năng lượng hơn sữa bò. NHS cho biết sữa đậu nành không đường, có bổ sung canxi có thể dùng từ 1 tuổi khi cần, và không cho trẻ dưới 5 tuổi uống sữa gạo. Bé dị ứng sữa bò hay nhà ăn chay thì hỏi bác sĩ.',
          },
          { type: 'heading', text: 'Hiểu lầm: sữa càng đắt bé càng cao, càng thông minh?' },
          {
            type: 'paragraph',
            text: 'Chiều cao và trí não phụ thuộc vào di truyền, bữa ăn đa dạng, giấc ngủ, vận động và sự gắn bó với người chăm. Uống quá nhiều sữa còn làm bé biếng ăn và dễ thiếu sắt.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Khi nào nên hỏi bác sĩ',
            text: 'Bé dị ứng hoặc không dung nạp sữa bò; gia đình ăn chay; bé chậm tăng cân, xanh xao, uống rất nhiều sữa mà ăn ít; hoặc bé có bệnh lý cần chọn sữa riêng.',
          },
        ],
        en: [
          {
            type: 'callout',
            tone: 'note',
            title: 'In short',
            text: 'After age 1: keep breastfeeding if you both want to; if not, about 2 cups of pasteurised whole cow’s milk a day is enough. Toddler formula offers no advantage over cow’s milk for healthy toddlers (AAP 2023).',
          },
          { type: 'heading', text: 'Is growing-up formula needed?' },
          {
            type: 'paragraph',
            text: 'Most toddlers do not. The AAP’s 2023 report says toddler formulas offer no benefit over cow’s milk for healthy children over 12 months, often contain added sugar and cost more. The NHS also says growing-up milks are not needed. A child with a medical condition, allergy or slow weight gain will get specific advice from their doctor.',
          },
          { type: 'heading', text: 'How much milk is enough?' },
          {
            type: 'paragraph',
            text: 'The AAP suggests about 2–3 cups, 480–720 ml, of whole milk a day at 12–24 months, staying under about 700 ml so there is room for iron-rich meals. Use a cup, move away from the bottle and no bottle at bedtime.',
          },
          { type: 'heading', text: 'Can plant milks replace it?' },
          {
            type: 'paragraph',
            text: 'Many plant milks have less protein and energy than cow’s milk. The NHS says unsweetened, calcium-fortified soya drinks can be used from age 1 if needed, and rice drinks should not be given under 5. If your child has a cow’s milk allergy or the family is vegan, ask the doctor.',
          },
          { type: 'heading', text: 'Myth: pricier milk makes children taller and smarter?' },
          {
            type: 'paragraph',
            text: 'Height and brain development depend on genes, varied meals, sleep, activity and close relationships. Too much milk can even blunt appetite and lead to low iron.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'When to ask a doctor',
            text: 'Your child has a cow’s milk allergy or intolerance; the family is vegetarian or vegan; your child gains weight slowly, looks pale, or drinks lots of milk but eats little; or has a condition that needs a specific milk.',
          },
        ],
      },
      keywords: {
        vi: ['sữa tăng trưởng', 'sữa tươi', 'sữa công thức', 'sữa hạt', 'bỏ bình'],
        en: ['growing-up milk', 'cow’s milk', 'formula', 'plant milk', 'stopping the bottle'],
      },
      relatedArticleIds: [
        'art_water_juice',
        'art_vitamin_d_iron',
        'art_picky_eating_toddler',
        'art_teething',
      ],
      milestoneIds: [],
      sources: [
        {
          label:
            "HealthyChildren.org (AAP) — Why most toddlers don't need toddler formula (2023 clinical report)",
          url: 'https://www.healthychildren.org/English/news/Pages/why-most-toddlers-dont-need-toddler-formula.aspx',
        },
        {
          label: 'HealthyChildren.org (AAP) — Recommended drinks for young children ages 0–5',
          url: 'https://www.healthychildren.org/English/healthy-living/nutrition/Pages/Recommended-Drinks-for-Young-Children-Ages-0-5.aspx',
        },
        {
          label: 'NHS — Drinks and cups for babies and young children',
          url: 'https://www.nhs.uk/baby/weaning-and-feeding/drinks-and-cups-for-babies-and-young-children/',
        },
        {
          label: 'NHS — What to feed young children',
          url: 'https://www.nhs.uk/baby/weaning-and-feeding/what-to-feed-young-children/',
        },
        {
          label: 'WHO — Infant and young child feeding (fact sheet)',
          url: 'https://www.who.int/news-room/fact-sheets/detail/infant-and-young-child-feeding',
        },
      ],
    },
  },
  {
    id: 'art_toddler_tantrums',
    reviewerLabel: 'Nhóm chuyên môn · Phát triển trẻ em',
    data: {
      library: 'care',
      topic: 'development',
      format: 'article',
      ageWeeks: { from: 52, to: 156 },
      readingMinutes: 4,
      cover: null,
      title: {
        vi: 'Bé ăn vạ, nổi cáu: hiểu và giúp bé bình tĩnh mà không đánh mắng',
        en: 'Tantrums: understanding them and helping your toddler calm down without smacking',
      },
      summary: {
        vi: 'Ăn vạ rất hay gặp từ khoảng 1 đến 3 tuổi, khi bé có nhiều mong muốn nhưng chưa nói được và chưa biết tự kiềm chế. Giữ bình tĩnh, giữ an toàn và nhất quán giúp cơn ăn vạ qua nhanh hơn.',
        en: 'Tantrums are very common from about 1 to 3 years, when toddlers want a lot but cannot yet say it or hold themselves back. Staying calm, keeping everyone safe and being consistent help tantrums pass faster.',
      },
      body: {
        vi: [
          {
            type: 'callout',
            tone: 'note',
            title: 'Tóm tắt nhanh',
            text: 'Ăn vạ là một phần của sự phát triển, không phải bé hư hay ba mẹ dạy sai. Lúc bé đang ăn vạ, giữ bé an toàn, ở gần, nói ít và bình tĩnh; không nhượng bộ điều đã nói không, và không đánh. Phòng trước bằng giờ giấc đều, báo trước khi chuyển việc và cho bé chọn giữa hai điều.',
          },
          { type: 'heading', text: 'Hiểu đúng về ăn vạ' },
          {
            type: 'paragraph',
            text: 'Từ khoảng 1 tuổi, bé muốn tự làm và có nhiều mong muốn, nhưng chưa đủ lời để nói ra, còn phần não giúp kiềm chế cảm xúc vẫn đang phát triển. Khi bất lực, mệt, đói hay bị từ chối, bé có thể khóc thét, nằm lăn ra sàn, đá, đánh hay nín thở. NHS cho biết ăn vạ hay gặp ở trẻ 18 tháng đến 3 tuổi và thường giảm dần khi bé nói giỏi hơn.',
          },
          {
            type: 'paragraph',
            text: 'Cơn ăn vạ thường ngắn, vài phút. Bé không cố tình làm khó ba mẹ; đó là cách bé xả một cảm xúc quá lớn. Điều bé cần là người lớn giữ bình tĩnh, giữ ranh giới và giúp bé dịu lại.',
          },
          {
            type: 'paragraph',
            text: 'Đánh đòn hay doạ nạt có thể làm bé nín ngay lúc đó, nhưng WHO và AAP cho biết trừng phạt thân thể làm tăng hành vi hung hăng và lo âu về lâu dài, và không dạy bé cách tự kiềm chế. Nhiều nước đã cấm đánh trẻ, kể cả trong gia đình.',
          },
          { type: 'heading', text: 'Ba mẹ có thể làm gì' },
          { type: 'heading', text: 'Phòng trước' },
          {
            type: 'bullets',
            items: [
              'Giữ giờ ăn, giờ ngủ đều; mang theo đồ ăn nhẹ khi ra ngoài; tránh đi chợ, đi chơi lúc bé quá mệt.',
              'Báo trước khi chuyển việc: “Chơi thêm một lần cầu trượt rồi mình về nhé.”',
              'Cho bé chọn giữa hai điều ba mẹ đều đồng ý: “Con mặc áo đỏ hay áo xanh?”',
              'Khen cụ thể khi bé làm tốt: “Con đợi đến lượt giỏi quá.”',
            ],
          },
          { type: 'heading', text: 'Khi bé đang ăn vạ' },
          {
            type: 'bullets',
            items: [
              'Giữ an toàn: dời đồ cứng, đồ vỡ; nếu bé đánh, đá, nhẹ nhàng giữ tay hoặc bế bé ra chỗ khác.',
              'Ở gần, nói ít, giọng bình tĩnh; gọi tên cảm xúc: “Con giận vì phải về.” Không tranh luận, giảng giải khi bé đang khóc.',
              'Không nhượng bộ điều đã nói không chỉ vì bé khóc to; nếu nhượng bộ, bé học được rằng ăn vạ là cách có được điều mình muốn.',
              'Khi bé dịu lại, ôm bé, nói ngắn gọn điều vừa xảy ra rồi chuyển sang việc khác. Không cần phạt thêm.',
              'Khi ba mẹ thấy mình sắp nổi nóng: hít thở sâu, nhờ người khác trông bé vài phút. Không bao giờ lắc hay đánh bé.',
            ],
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'Cả nhà cùng một cách',
            text: 'Bé dễ rối khi mẹ nói không còn bà lại cho. Ông bà, ba mẹ và người trông bé nên thống nhất vài nguyên tắc chính: không đánh, không nhượng bộ khi bé ăn vạ, và cùng một cách dỗ bé.',
          },
          { type: 'heading', text: 'Theo dõi' },
          {
            type: 'bullets',
            items: [
              'Cơn ăn vạ hay xảy ra lúc nào: đói, buồn ngủ, khi chuyển việc, khi có người lạ.',
              'Mỗi cơn kéo dài bao lâu và có thưa dần theo tháng không.',
              'Bé có tự làm đau mình như đập đầu, cắn mình, hay làm đau người khác không.',
              'Lời nói và cách giao tiếp: bé có chỉ tay, nói được từ, hiểu lời ba mẹ không.',
            ],
          },
          { type: 'heading', text: 'Hiểu lầm thường gặp' },
          {
            type: 'bullets',
            items: [
              '“Bé ăn vạ là do chiều quá, phải đánh cho chừa”: ăn vạ là một giai đoạn phát triển; đánh làm bé sợ chứ không dạy bé tự kiềm chế. Nên: giữ bình tĩnh, giữ ranh giới, khen khi bé làm tốt.',
              '“Bé khóc thì đưa ngay điện thoại, kẹo cho êm”: cách này làm bé ăn vạ nhiều hơn để có thứ mình muốn. Nên: chờ bé dịu lại rồi chuyển sang việc khác.',
              '“Doạ ông kẹ, công an, doạ bỏ bé lại cho nín”: thêm nỗi sợ khiến bé bất an hơn. Nên: ở gần và gọi tên cảm xúc của bé.',
              '“Bé nín thở đến tím tái là do giận dai, cứ mặc kệ”: cơn nín thở thường không nguy hiểm, nhưng lần đầu nên cho bác sĩ xem, và bác sĩ có thể kiểm tra thiếu sắt. Nên: đặt bé nằm nghiêng ở chỗ an toàn, ở cạnh bé đến khi bé thở lại.',
            ],
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Gọi 115 hoặc đến cấp cứu ngay khi',
            text: 'Bé ngất, tím tái kéo dài, co giật hoặc không tỉnh lại nhanh sau cơn nín thở; hoặc bé bị thương nặng trong lúc ăn vạ.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Khi nào nên hỏi bác sĩ',
            text: 'Bé có cơn nín thở lần đầu; ăn vạ rất thường xuyên, nhiều lần mỗi ngày hoặc thường kéo dài trên 15 phút; bé hay tự làm đau mình hay làm đau người khác; ăn vạ ngày càng nặng hoặc vẫn nhiều sau 4 tuổi; bé chậm nói, ít giao tiếp hoặc mất kỹ năng đã có; hoặc ba mẹ thấy kiệt sức, khó kiềm chế.',
          },
        ],
        en: [
          {
            type: 'callout',
            tone: 'note',
            title: 'In short',
            text: 'Tantrums are part of development, not a sign of a naughty child or bad parenting. During a tantrum, keep your child safe, stay close, say little and stay calm; do not give in on a “no”, and never hit. Prevent them with regular routines, warnings before changes and a choice between two options.',
          },
          { type: 'heading', text: 'Understanding tantrums' },
          {
            type: 'paragraph',
            text: 'From about age 1, toddlers want to do things themselves and want many things, but lack the words to say so, and the parts of the brain that manage feelings are still developing. When frustrated, tired, hungry or told no, they may scream, throw themselves on the floor, kick, hit or hold their breath. The NHS says tantrums are common from 18 months to 3 years and usually ease as talking improves.',
          },
          {
            type: 'paragraph',
            text: 'Most tantrums last a few minutes. Your toddler is not trying to make life hard for you; it is how they let out a feeling that is too big. What they need is an adult who stays calm, keeps the limit and helps them settle.',
          },
          {
            type: 'paragraph',
            text: 'Smacking or threats may stop crying in the moment, but WHO and the AAP say physical punishment increases aggression and anxiety over time and does not teach self-control. Many countries have banned physical punishment of children, including at home.',
          },
          { type: 'heading', text: 'What you can do' },
          { type: 'heading', text: 'Preventing tantrums' },
          {
            type: 'bullets',
            items: [
              'Keep regular meal and sleep times; take a snack when you go out; avoid shopping or outings when your child is overtired.',
              'Warn before a change: “One more go on the slide, then we go home.”',
              'Offer a choice between two options you are happy with: “Red top or blue top?”',
              'Praise specific good moments: “You waited for your turn so well.”',
            ],
          },
          { type: 'heading', text: 'During a tantrum' },
          {
            type: 'bullets',
            items: [
              'Keep everyone safe: move hard or breakable things; if your child hits or kicks, gently hold their hands or carry them somewhere else.',
              'Stay close, say little, speak calmly, and name the feeling: “You’re cross because we have to go.” Do not argue or explain while they are crying.',
              'Do not give in on a “no” because the crying is loud; if you do, your child learns that tantrums work.',
              'When your child calms down, hug them, say briefly what happened and move on. No extra punishment is needed.',
              'If you feel close to losing your temper: breathe deeply and ask someone else to watch your child for a few minutes. Never shake or hit a child.',
            ],
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'One approach for the whole family',
            text: 'Toddlers get confused when a parent says no and a grandparent says yes. Parents, grandparents and carers can agree on a few key rules: no hitting, no giving in to tantrums, and the same way of comforting your child.',
          },
          { type: 'heading', text: 'What to watch' },
          {
            type: 'bullets',
            items: [
              'When tantrums tend to happen: hungry, sleepy, at changes of activity, around new people.',
              'How long each one lasts and whether they become less frequent over the months.',
              'Whether your child hurts themselves, such as head-banging or biting, or hurts others.',
              'Talking and communicating: whether your child points, uses words and understands you.',
            ],
          },
          { type: 'heading', text: 'Common misconceptions' },
          {
            type: 'bullets',
            items: [
              '“Tantrums mean a spoilt child who needs a smack”: tantrums are a stage of development; hitting makes children afraid but does not teach self-control. Instead: stay calm, keep the limit and praise good moments.',
              '“Hand over the phone or sweets to stop the crying”: this teaches more tantrums to get things. Instead: wait for your child to calm down, then move on.',
              '“Threaten the bogeyman, the police or leaving them behind”: adding fear makes children less secure. Instead: stay close and name their feelings.',
              '“Breath-holding until blue is just stubbornness, ignore it”: breath-holding spells are usually harmless, but have the first one checked by a doctor, who may test for low iron. Instead: lay your child on their side somewhere safe and stay with them until they breathe again.',
            ],
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Call 115 (Việt Nam) or local emergency services now if',
            text: 'Your child faints and stays blue, has a fit or does not come round quickly after breath-holding; or is badly hurt during a tantrum.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'When to ask a doctor',
            text: 'Your child has a first breath-holding spell; tantrums happen many times a day or often last more than 15 minutes; your child often hurts themselves or others; tantrums get worse or are still frequent after age 4; there are concerns about talking or social skills, or lost skills; or you feel exhausted and struggle to stay in control.',
          },
        ],
      },
      keywords: {
        vi: ['ăn vạ', 'nổi cáu', 'nín thở', 'đánh đòn', 'kỷ luật tích cực', 'cảm xúc'],
        en: [
          'tantrums',
          'meltdowns',
          'breath-holding',
          'smacking',
          'positive discipline',
          'feelings',
        ],
      },
      relatedArticleIds: [
        'art_separation_anxiety',
        'art_screens_language',
        'art_sleep_by_age',
        'art_parent_wellbeing',
      ],
      milestoneIds: ['checks_back', 'notices_upset', 'two_word_phrases'],
      sources: [
        {
          label: 'NHS — Temper tantrums',
          url: 'https://www.nhs.uk/baby/babys-development/behaviour/temper-tantrums/',
        },
        {
          label: 'HealthyChildren.org (AAP) — Temper tantrums',
          url: 'https://www.healthychildren.org/English/family-life/family-dynamics/communication-discipline/Pages/Temper-Tantrums.aspx',
        },
        {
          label: 'HealthyChildren.org (AAP) — Where we stand: spanking',
          url: 'https://www.healthychildren.org/English/family-life/family-dynamics/communication-discipline/Pages/Where-We-Stand-Spanking.aspx',
        },
        {
          label: 'WHO — Corporal punishment and health (fact sheet)',
          url: 'https://www.who.int/news-room/fact-sheets/detail/corporal-punishment-and-health',
        },
      ],
    },
  },
  {
    id: 'art_newborn_skin_rashes',
    reviewerLabel: 'Nhóm chuyên môn · Điều dưỡng nhi',
    data: {
      library: 'care',
      topic: 'daily_care',
      format: 'article',
      ageWeeks: { from: 0, to: 52 },
      readingMinutes: 4,
      cover: null,
      title: {
        vi: 'Da bé sơ sinh: mụn sữa, ban đỏ, rôm sảy, vết bớt và khi nào cần lo',
        en: 'Newborn skin: milk spots, newborn rash, heat rash, birthmarks and when to worry',
      },
      summary: {
        vi: 'Da bé mới sinh hay nổi những nốt, mảng vô hại và tự hết. Biết phân biệt chúng với ban cần cấp cứu, và giữ bé mát vừa đủ, giúp ba mẹ bớt lo.',
        en: 'Newborn skin often shows harmless spots and patches that clear on their own. Knowing them from a rash that needs emergency care, and keeping your baby comfortably cool, takes away a lot of worry.',
      },
      body: {
        vi: [
          {
            type: 'callout',
            tone: 'note',
            title: 'Tóm tắt nhanh',
            text: 'Mụn trắng li ti, ban đỏ sơ sinh, mụn sơ sinh, cứt trâu và rôm sảy đều rất hay gặp và thường tự hết. Không nặn, không bôi thuốc hay đắp lá. Ban không mất màu khi ấn cốc, nốt mủ hay phỏng nước kèm sốt, hoặc bé dưới 3 tháng sốt từ 38 °C cần khám ngay.',
          },
          { type: 'heading', text: 'Hiểu đúng về da bé sơ sinh' },
          {
            type: 'paragraph',
            text: 'Trong vài tuần đầu, da bé đang thích nghi với môi trường bên ngoài, nên hay nổi nốt và đổi màu. Những biểu hiện thường gặp và vô hại gồm:',
          },
          {
            type: 'bullets',
            items: [
              'Mụn trắng li ti (mụn sữa): nốt trắng nhỏ ở mũi, má, cằm, tự hết sau vài tuần.',
              'Ban đỏ sơ sinh: mảng đỏ có chấm trắng hoặc vàng ở giữa, xuất hiện vài ngày đầu, lúc có lúc mất, bé vẫn bú tốt, không sốt; tự hết sau vài ngày đến 2 tuần.',
              'Mụn sơ sinh: mụn đỏ nhỏ ở má, trán, hay gặp khoảng 2–4 tuần tuổi, thường tự hết sau vài tuần đến vài tháng.',
              'Cứt trâu: mảng vảy vàng, nhờn trên da đầu, không ngứa, không gây hại.',
              'Rôm sảy: chấm đỏ hoặc mụn nước li ti ở cổ, ngực, lưng, nếp gấp khi bé bị nóng, ra nhiều mồ hôi.',
              'Vết bớt xanh: mảng xanh xám ở lưng, mông, rất hay gặp ở bé châu Á; không phải vết bầm, thường mờ dần trong vài năm.',
              'Vết đỏ nhạt ở gáy, mí mắt, giữa trán: thường nhạt dần.',
            ],
          },
          {
            type: 'paragraph',
            text: 'Bướu máu là nốt đỏ tươi nổi gồ, thường xuất hiện vài tuần sau sinh, lớn nhanh trong vài tháng rồi nhỏ dần. Phần lớn không cần điều trị, nhưng nên cho bác sĩ xem sớm nếu bướu ở gần mắt, môi, mũi, vùng tã, lớn rất nhanh hoặc bị loét.',
          },
          { type: 'heading', text: 'Ba mẹ có thể làm gì' },
          {
            type: 'bullets',
            items: [
              'Tắm nhanh bằng nước ấm, thấm khô; không cần nhiều xà phòng, không chà xát.',
              'Không nặn mụn, không cạy vảy da đầu bằng móng tay. Với cứt trâu, NHS gợi ý gội đầu thường xuyên bằng dầu gội dịu nhẹ, làm mềm vảy bằng kem dưỡng không mùi rồi chải nhẹ bằng lược mềm.',
              'Rôm sảy: cho bé mặc đồ cotton mỏng, rộng; giữ phòng mát, thoáng; tránh kem đặc và phấn rôm. Rôm thường đỡ sau vài ngày khi bé bớt nóng.',
              'Chụp ảnh vết bớt, bướu máu mỗi vài tuần để bác sĩ so sánh.',
              'Ghi vết bớt xanh vào hồ sơ của bé để người chăm khác và nhân viên y tế không nhầm với vết bầm.',
              'Giặt quần áo của bé bằng bột giặt dịu nhẹ, không mùi, xả kỹ.',
            ],
          },
          { type: 'heading', text: 'Theo dõi' },
          {
            type: 'bullets',
            items: [
              'Ban có mất màu khi ấn nhẹ một cốc thuỷ tinh lên không.',
              'Bé có sốt, bú kém, li bì hay quấy khác thường không.',
              'Nốt có mủ, phỏng nước lan rộng, vảy vàng, rỉ dịch không.',
              'Màu da vàng: xem bài Vàng da sơ sinh.',
            ],
          },
          { type: 'heading', text: 'Hiểu lầm thường gặp' },
          {
            type: 'bullets',
            items: [
              '“Tắm nước lá chè xanh, lá khế cho hết rôm”: nước lá không sạch, khó biết đậm nhạt và có thể làm da kích ứng. Nên: tắm nước ấm sạch, mặc thoáng.',
              '“Bôi phấn rôm cho khô”: bé có thể hít bột vào phổi. Nên: giữ bé mát và khô, không dùng phấn.',
              '“Ủ thật ấm cho rôm mọc ra hết”: ủ nóng làm rôm nặng hơn và tăng nguy cơ đột tử khi ngủ. Nên: mặc nhiều hơn người lớn tối đa một lớp mỏng.',
              '“Nặn mụn sữa cho sạch”: nặn dễ gây nhiễm trùng. Nên: để mụn tự hết.',
              '“Vết xanh ở mông là do bị đánh, bị ngã”: bớt xanh có từ lúc sinh và rất hay gặp ở bé châu Á. Nên: chụp ảnh, ghi vào hồ sơ; còn vết bầm mới xuất hiện ở bé chưa biết lẫy thì cần bác sĩ xem.',
            ],
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Gọi 115 hoặc đến cấp cứu ngay khi',
            text: 'Bé có ban hoặc chấm đỏ, tím không mất màu khi ấn cốc, nhất là kèm sốt hay bé mệt; bé li bì, khó đánh thức hoặc khó thở; phỏng nước lan nhanh kèm sốt, hoặc da đỏ, bong tróc trên diện rộng.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Đưa bé đi khám trong ngày khi',
            text: 'Bé dưới 3 tháng có nhiệt độ từ 38 °C trở lên; nốt có mủ, phỏng nước, vảy vàng hoặc rỉ dịch; ban kèm bú kém; bướu máu ở gần mắt, môi, mũi, vùng tã, lớn nhanh hoặc loét; có vết bầm ở bé chưa biết lẫy; hoặc ba mẹ thấy lo.',
          },
        ],
        en: [
          {
            type: 'callout',
            tone: 'note',
            title: 'In short',
            text: 'Milk spots, newborn rash, baby acne, cradle cap and heat rash are all very common and usually clear by themselves. Do not squeeze them or apply creams or leaves. A rash that does not fade under a glass, pus spots or blisters with fever, or a baby under 3 months with 38 °C or more needs to be seen straight away.',
          },
          { type: 'heading', text: 'Understanding newborn skin' },
          {
            type: 'paragraph',
            text: 'In the first weeks, your baby’s skin is adjusting to life outside the womb, so spots and colour changes are common. Usual, harmless ones include:',
          },
          {
            type: 'bullets',
            items: [
              'Milk spots (milia): tiny white spots on the nose, cheeks and chin that go within a few weeks.',
              'Newborn rash (erythema toxicum): red blotches with a white or yellow dot in the middle in the first days, coming and going in a baby who feeds well with no fever; it clears within days to 2 weeks.',
              'Baby acne: small red spots on the cheeks and forehead, often at 2–4 weeks, which usually clear within weeks to a few months.',
              'Cradle cap: yellow, greasy scales on the scalp that are not itchy or harmful.',
              'Heat rash: tiny red spots or blisters on the neck, chest, back and skin folds when your baby is hot and sweaty.',
              'Slate-grey patches (Mongolian spots): blue-grey patches on the back and bottom, very common in Asian babies; they are not bruises and usually fade over a few years.',
              'Pale pink marks on the back of the neck, eyelids or forehead (stork marks): these usually fade.',
            ],
          },
          {
            type: 'paragraph',
            text: 'A strawberry mark (infantile haemangioma) is a raised bright red lump that usually appears a few weeks after birth, grows quickly for some months, then shrinks. Most need no treatment, but have it checked early if it is near the eye, lips, nose or diaper area, grows very fast or breaks down into a sore.',
          },
          { type: 'heading', text: 'What you can do' },
          {
            type: 'bullets',
            items: [
              'Give quick warm baths and pat dry; little or no soap, no scrubbing.',
              'Do not squeeze spots or pick at scalp scales. For cradle cap, the NHS suggests regular washing with a mild baby shampoo, softening the scales with an unperfumed moisturiser, then brushing gently with a soft brush.',
              'Heat rash: dress your baby in thin, loose cotton, keep the room cool and airy, and avoid thick creams and talc. It usually settles within days once your baby is cooler.',
              'Photograph birthmarks or strawberry marks every few weeks so the doctor can compare.',
              'Note slate-grey patches in your baby’s health record so other carers and health workers do not mistake them for bruises.',
              'Wash your baby’s clothes in a mild, fragrance-free detergent and rinse well.',
            ],
          },
          { type: 'heading', text: 'What to watch' },
          {
            type: 'bullets',
            items: [
              'Whether a rash fades when you press a glass on it.',
              'Fever, poor feeding, unusual sleepiness or fussing.',
              'Pus spots, spreading blisters, yellow crusts or weeping skin.',
              'Yellow skin: see Newborn jaundice.',
            ],
          },
          { type: 'heading', text: 'Common misconceptions' },
          {
            type: 'bullets',
            items: [
              '“Bathe in green tea or star fruit leaf water to clear heat rash”: leaf water is not clean, its strength is unknown and it can irritate skin. Instead: clean warm water and light clothing.',
              '“Use talc to dry the skin”: babies can breathe the powder into their lungs. Instead: keep your baby cool and dry, without powder.',
              '“Wrap them up warm to bring the rash out”: heat makes it worse and raises the risk of sudden infant death in sleep. Instead: at most one light layer more than an adult.',
              '“Squeeze milk spots to clean them”: this can cause infection. Instead: leave them to clear on their own.',
              '“Blue marks on the bottom mean the baby was hit or fell”: slate-grey patches are present from birth and very common in Asian babies. Instead: photograph and record them; any new bruise on a baby who is not yet rolling needs a doctor’s check.',
            ],
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Call 115 (Việt Nam) or local emergency services now if',
            text: 'Your baby has red or purple spots that do not fade under a glass, especially with fever or if they seem unwell; is very drowsy, hard to wake or struggling to breathe; or has blisters spreading fast with fever, or widespread red, peeling skin.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'See a doctor the same day if',
            text: 'Your baby is under 3 months with a temperature of 38 °C or more; has pus spots, blisters, yellow crusts or weeping skin; has a rash with poor feeding; has a strawberry mark near the eye, lips, nose or diaper area, or one that grows fast or forms a sore; has a bruise but is not yet rolling; or you are worried.',
          },
        ],
      },
      keywords: {
        vi: ['rôm sảy', 'mụn sữa', 'ban đỏ sơ sinh', 'cứt trâu', 'bớt xanh', 'bướu máu'],
        en: [
          'heat rash',
          'milk spots',
          'newborn rash',
          'cradle cap',
          'Mongolian spots',
          'strawberry mark',
        ],
      },
      relatedArticleIds: [
        'art_bathing_at_home',
        'art_eczema_dry_skin',
        'art_newborn_jaundice',
        'art_heat_cold_safety',
      ],
      milestoneIds: [],
      sources: [
        {
          label: 'NHS — Rashes in babies and children',
          url: 'https://www.nhs.uk/conditions/rashes-babies-and-children/',
        },
        {
          label: 'NHS — Heat rash (prickly heat)',
          url: 'https://www.nhs.uk/conditions/heat-rash-prickly-heat/',
        },
        { label: 'NHS — Birthmarks', url: 'https://www.nhs.uk/conditions/birthmarks/' },
        { label: 'NHS — Cradle cap', url: 'https://www.nhs.uk/conditions/cradle-cap/' },
        {
          label:
            "HealthyChildren.org (AAP) — Make baby's room safe: parent checklist (baby and talcum powder)",
          url: 'https://www.healthychildren.org/English/safety-prevention/at-home/Pages/Make-Babys-Room-Safe.aspx',
        },
        { label: 'NHS — Fever in children', url: 'https://www.nhs.uk/symptoms/fever-in-children/' },
      ],
    },
  },
  {
    id: 'art_heat_cold_safety',
    reviewerLabel: 'Nhóm chuyên môn · Nhi khoa',
    data: {
      library: 'care',
      topic: 'daily_care',
      format: 'article',
      ageWeeks: { from: 0, to: 104 },
      readingMinutes: 4,
      cover: null,
      title: {
        vi: 'Giữ bé vừa ấm, vừa mát: trời nóng, điều hoà, trời lạnh và sưởi an toàn',
        en: 'Keeping your baby comfortable in heat and cold: air conditioning, fans and safe heating',
      },
      summary: {
        vi: 'Bé nhỏ dễ bị nóng quá hoặc lạnh quá. Cách mặc, dùng điều hoà, quạt, che nắng cho bé, và vì sao không bao giờ đốt than sưởi trong phòng kín.',
        en: 'Young babies overheat and get cold easily. How to dress them, use air conditioning and fans, protect them from the sun, and why never to burn charcoal for heat in a closed room.',
      },
      body: {
        vi: [
          {
            type: 'callout',
            tone: 'note',
            title: 'Tóm tắt nhanh',
            text: 'Mặc cho bé nhiều hơn người lớn tối đa một lớp mỏng; sờ ngực hoặc gáy để biết bé có nóng không. Trời nóng: cho bú nhiều hơn, phòng thoáng, tránh nắng gắt, không trùm kín xe đẩy. Trời lạnh: mặc nhiều lớp mỏng, không đội mũ khi ngủ trong nhà. Không bao giờ đốt than, củi để sưởi trong phòng kín.',
          },
          { type: 'heading', text: 'Hiểu đúng: vì sao bé dễ nóng, dễ lạnh' },
          {
            type: 'paragraph',
            text: 'Bé nhỏ có diện tích da lớn so với cân nặng và chưa tự điều chỉnh thân nhiệt tốt như người lớn. Quá nóng khi ngủ làm tăng nguy cơ đột tử; nóng kéo dài khi trời oi bức dễ làm bé mất nước, kiệt sức vì nóng. Bé sơ sinh nhẹ cân, sinh non lại dễ bị lạnh.',
          },
          {
            type: 'paragraph',
            text: 'Than củi, lò than, bếp gas hay máy phát điện cháy trong phòng kín sinh ra khí CO (carbon monoxide), không màu, không mùi. Khí này có thể gây ngộ độc và tử vong cho cả mẹ và bé trong một đêm. Ở Việt Nam: thói quen sưởi than, hơ than cho mẹ và bé khi ở cữ vẫn còn ở nhiều nơi; đây là nguy cơ ngộ độc khí CO cần tránh hẳn.',
          },
          { type: 'heading', text: 'Ba mẹ có thể làm gì' },
          { type: 'heading', text: 'Khi trời nóng' },
          {
            type: 'bullets',
            items: [
              'Cho bú mẹ, bú bình thường xuyên hơn; bé dưới 6 tháng bú mẹ hoàn toàn không cần uống thêm nước. Bé đã ăn dặm có thể uống thêm từng ngụm nước.',
              'Mặc đồ cotton mỏng, sáng màu; ở trong nhà, bé có thể chỉ mặc áo mỏng và tã.',
              'Dùng điều hoà hoặc quạt để phòng mát dễ chịu với người lớn mặc đồ mỏng; không để gió thổi thẳng vào bé, vệ sinh máy định kỳ, đặt quạt chắc chắn, có lồng chắn, xa tầm tay bé.',
              'Bé dưới 6 tháng: tránh nắng trực tiếp, cho bé ở chỗ râm, mặc đồ dài tay mỏng, đội mũ rộng vành khi ra ngoài. Từ 6 tháng: thêm kem chống nắng SPF từ 30 trên vùng da hở; AAP cho phép bôi một lượng nhỏ cho bé nhỏ hơn ở chỗ không che được.',
              'Không trùm khăn, chăn lên xe đẩy để che nắng: bên trong có thể nóng lên rất nhanh. Dùng mái che của xe và đi vào chỗ râm.',
              'Không bao giờ để bé một mình trong ô tô, dù chỉ một phút.',
            ],
          },
          { type: 'heading', text: 'Khi trời lạnh' },
          {
            type: 'bullets',
            items: [
              'Mặc nhiều lớp mỏng thay vì một áo thật dày; cởi bớt khi vào nhà hoặc lên xe.',
              'Khi ra ngoài, đội mũ, đi tất cho bé; khi ngủ trong nhà, không đội mũ, không đắp chăn dày, dùng túi ngủ hoặc mặc thêm một lớp.',
              'Máy sưởi điện, đèn sưởi: đặt xa giường, nôi, rèm và đồ vải; có lồng chắn; không để chạy suốt đêm sát bé; không để túi chườm nóng trong nôi.',
              'Không đốt than, củi, lò than để sưởi hay hơ trong phòng ngủ. Nếu nhà nấu bằng bếp gas hay lò than, mở cửa thông gió và không đặt bếp trong phòng ngủ.',
            ],
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'Kiểm tra nhanh',
            text: 'Sờ ngực, lưng hoặc gáy bé, đừng dựa vào tay chân vì tay chân bé thường mát hơn. Gáy ướt mồ hôi, đỏ, nóng là bé đang nóng; ngực mát, môi tím, run là bé đang lạnh.',
          },
          { type: 'heading', text: 'Theo dõi' },
          {
            type: 'bullets',
            items: [
              'Số tã ướt, màu nước tiểu, môi miệng có khô không khi trời nóng.',
              'Bé có ra nhiều mồ hôi, đỏ bừng, thở nhanh, li bì không.',
              'Nhiệt độ phòng ngủ và khe thông gió khi đóng kín cửa để bật điều hoà hay sưởi.',
              'Cả nhà cùng đau đầu, buồn nôn, chóng mặt, mệt lả trong phòng có sưởi than hay lửa: dấu hiệu nghi ngộ độc khí CO.',
            ],
          },
          { type: 'heading', text: 'Hiểu lầm thường gặp' },
          {
            type: 'bullets',
            items: [
              '“Ở cữ phải ủ thật kín, sưởi than cho ấm”: khí than trong phòng kín có thể gây ngộ độc chết người, còn ủ quá nóng làm tăng nguy cơ đột tử. Nên: phòng thoáng, ấm vừa, mặc vừa đủ.',
              '“Bật điều hoà là bé bị cảm”: cảm lạnh do virus, không phải do điều hoà. Nên: để nhiệt độ dễ chịu, không thổi thẳng vào bé, giữ máy sạch.',
              '“Tay chân bé lạnh là bé lạnh, phải mặc thêm”: tay chân bé thường mát. Nên: sờ ngực hoặc gáy để kiểm tra.',
              '“Tắm nắng giữa trưa cho có vitamin D”: nắng gắt dễ làm bé cháy nắng, kiệt sức vì nóng. Nên: cho bé uống vitamin D theo hướng dẫn, ra ngoài lúc mát, ở chỗ râm.',
            ],
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Gọi 115 hoặc đến cấp cứu ngay khi',
            text: 'Bé li bì, khó đánh thức, co giật, thở nhanh hoặc khó thở sau khi bị nóng; da nóng đỏ, khô, bé lả đi; cả nhà nghi ngộ độc khí than: đưa mọi người ra chỗ thoáng ngay, tắt nguồn đốt nếu an toàn, rồi gọi 115; bé tím tái, người lạnh, mềm nhũn.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Đưa bé đi khám trong ngày khi',
            text: 'Bé dưới 3 tháng có nhiệt độ từ 38 °C trở lên hoặc dưới 36 °C; bé ít tã ướt, môi khô, bú kém khi trời nóng; bé bị cháy nắng phỏng rộp; rôm sảy có mủ hoặc kèm sốt; hoặc ba mẹ thấy lo.',
          },
        ],
        en: [
          {
            type: 'callout',
            tone: 'note',
            title: 'In short',
            text: 'Dress your baby in at most one light layer more than an adult, and feel the chest or back of the neck to check. In heat: feed more often, keep rooms airy, avoid strong sun and never cover a pram or stroller. In cold: use several thin layers, and no hat for sleep indoors. Never burn charcoal or wood for heat in a closed room.',
          },
          { type: 'heading', text: 'Understanding why babies overheat and get cold' },
          {
            type: 'paragraph',
            text: 'Young babies have a lot of skin for their weight and cannot control their temperature as well as adults. Overheating during sleep raises the risk of sudden infant death; long spells of heat can lead to dehydration and heat exhaustion. Small and premature newborns also get cold easily.',
          },
          {
            type: 'paragraph',
            text: 'Charcoal, coal stoves, gas burners or generators burning in a closed room produce carbon monoxide (CO), which has no colour or smell. It can poison and kill both mother and baby in a single night. In Việt Nam: warming a new mother and baby with a charcoal burner during the confinement month is still practised in many places; it is a carbon monoxide risk to avoid completely.',
          },
          { type: 'heading', text: 'What you can do' },
          { type: 'heading', text: 'In hot weather' },
          {
            type: 'bullets',
            items: [
              'Breastfeed or bottle-feed more often; exclusively breastfed babies under 6 months do not need extra water. Babies on solids can have sips of water.',
              'Dress your baby in thin, light-coloured cotton; indoors, a light top and a diaper may be enough.',
              'Use air conditioning or a fan so the room feels comfortable to an adult in light clothes; do not aim the airflow at your baby, clean the unit regularly, and keep fans stable, guarded and out of reach.',
              'Under 6 months: keep out of direct sun, in the shade, in thin long sleeves and a wide-brimmed hat outdoors. From 6 months: add SPF 30 or higher sunscreen on exposed skin; the AAP allows a small amount on younger babies where skin cannot be covered.',
              'Do not cover a pram or stroller with a cloth or blanket for shade: it can heat up very fast inside. Use the hood and stay in the shade.',
              'Never leave your baby alone in a car, even for a minute.',
            ],
          },
          { type: 'heading', text: 'In cold weather' },
          {
            type: 'bullets',
            items: [
              'Use several thin layers rather than one thick one; take layers off indoors or in the car.',
              'Outdoors, add a hat and socks; for sleep indoors, no hat and no thick quilts; use a sleep sack or one extra layer.',
              'Electric heaters and heat lamps: keep them away from beds, cribs, curtains and fabric, with a guard; do not run them all night close to your baby; no hot-water bottles in the crib.',
              'Never burn charcoal, wood or coal for heating or warming in a bedroom. If you cook with gas or a charcoal stove, keep the area ventilated and never put it in a bedroom.',
            ],
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'A quick check',
            text: 'Feel your baby’s chest, back or the back of the neck, not the hands and feet, which are usually cooler. A sweaty, red, hot neck means too hot; a cool chest, bluish lips or shivering means too cold.',
          },
          { type: 'heading', text: 'What to watch' },
          {
            type: 'bullets',
            items: [
              'In hot weather: wet diapers, urine colour and whether the lips and mouth are dry.',
              'Heavy sweating, flushed skin, fast breathing or drowsiness.',
              'Bedroom temperature, and ventilation when doors are shut for air conditioning or heating.',
              'Several people with headache, nausea, dizziness or weakness in a room with a charcoal burner or flame: a warning sign of carbon monoxide poisoning.',
            ],
          },
          { type: 'heading', text: 'Common misconceptions' },
          {
            type: 'bullets',
            items: [
              '“During confinement, seal the room and use a charcoal burner”: charcoal fumes in a closed room can kill, and overheating raises the risk of sudden infant death. Instead: an airy, comfortably warm room and sensible clothing.',
              '“Air conditioning gives babies colds”: colds are caused by viruses, not air conditioning. Instead: keep it comfortable, not aimed at your baby, and clean.',
              '“Cold hands mean a cold baby who needs more clothes”: babies’ hands and feet are often cool. Instead: check the chest or the back of the neck.',
              '“Midday sunbathing for vitamin D”: strong sun can burn and overheat babies. Instead: give vitamin D as advised and go out in cooler hours, in the shade.',
            ],
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Call 115 (Việt Nam) or local emergency services now if',
            text: 'Your baby is very drowsy, hard to wake, has a fit, or breathes fast or with difficulty after getting hot; has hot, red, dry skin and is floppy; you suspect carbon monoxide poisoning: get everyone into fresh air at once, turn off the source if it is safe, then call; or your baby is blue, cold and floppy.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'See a doctor the same day if',
            text: 'Your baby is under 3 months with a temperature of 38 °C or more, or under 36 °C; has fewer wet diapers, dry lips or poor feeding in hot weather; has sunburn with blisters; has heat rash with pus spots or fever; or you are worried.',
          },
        ],
      },
      keywords: {
        vi: ['trời nóng', 'điều hoà', 'say nóng', 'sưởi than', 'khí CO', 'chống nắng'],
        en: [
          'hot weather',
          'air conditioning',
          'heat exhaustion',
          'charcoal heating',
          'carbon monoxide',
          'sun protection',
        ],
      },
      relatedArticleIds: [
        'art_safe_sleep',
        'art_newborn_skin_rashes',
        'art_vitamin_d_iron',
        'art_parent_wellbeing',
      ],
      milestoneIds: [],
      sources: [
        {
          label: 'NHS — Heatwave: how to cope in hot weather',
          url: 'https://www.nhs.uk/live-well/seasonal-health/heatwave-how-to-cope-in-hot-weather/',
        },
        {
          label: 'NHS — Heat exhaustion and heatstroke',
          url: 'https://www.nhs.uk/conditions/heat-exhaustion-heatstroke/',
        },
        {
          label: 'NHS — Carbon monoxide poisoning',
          url: 'https://www.nhs.uk/conditions/carbon-monoxide-poisoning/',
        },
        {
          label: 'HealthyChildren.org (AAP) — Sun safety',
          url: 'https://www.healthychildren.org/English/safety-prevention/at-play/Pages/Sun-Safety.aspx',
        },
        {
          label: 'NHS — Sudden infant death syndrome (SIDS)',
          url: 'https://www.nhs.uk/baby/caring-for-a-newborn/sudden-infant-death-syndrome-sids/',
        },
        {
          label: "HealthyChildren.org (AAP) — A parent's guide to safe sleep",
          url: 'https://www.healthychildren.org/English/ages-stages/baby/sleep/Pages/A-Parents-Guide-to-Safe-Sleep.aspx',
        },
      ],
    },
  },
  {
    id: 'art_medicine_safety',
    reviewerLabel: 'Nhóm chuyên môn · Nhi khoa',
    data: {
      library: 'care',
      topic: 'illness',
      format: 'step_guide',
      ageWeeks: { from: 0, to: 104 },
      readingMinutes: 4,
      cover: null,
      title: {
        vi: 'Cho bé dùng thuốc an toàn: đúng thuốc, đúng liều, đúng cách',
        en: 'Giving your baby medicine safely: the right medicine, dose and method',
      },
      summary: {
        vi: 'Phần lớn sai sót thuốc ở trẻ nhỏ có thể phòng được: liều theo cân nặng, đong bằng xi lanh có vạch, không dùng thuốc người lớn và chỉ dùng kháng sinh khi bác sĩ kê.',
        en: 'Most medicine mistakes in young children can be prevented: dose by weight, measure with a marked syringe, never use adult medicines, and use antibiotics only when a doctor prescribes them.',
      },
      body: {
        vi: [
          {
            type: 'callout',
            tone: 'note',
            title: 'Tóm tắt nhanh',
            text: 'Trước khi cho bé uống bất kỳ thuốc nào, hãy biết tên hoạt chất, liều theo cân nặng của bé, khoảng cách giữa các liều và liều tối đa trong ngày. Đong bằng xi lanh hoặc cốc có vạch đi kèm, không dùng thìa ăn. Không tự dùng kháng sinh, aspirin, thuốc của người lớn, hay thuốc ho cảm cho bé dưới 2 tuổi.',
          },
          { type: 'heading', text: 'Hiểu đúng: vì sao trẻ nhỏ dễ gặp sai sót thuốc' },
          {
            type: 'paragraph',
            text: 'Liều thuốc của trẻ tính theo cân nặng, và cùng một tên thuốc có nhiều nồng độ, ví dụ paracetamol dạng giọt và dạng siro. Đong bằng thìa ăn có thể sai gấp đôi. AAP khuyên dùng dụng cụ có vạch ml đi kèm thuốc, không dùng thìa trong bếp.',
          },
          {
            type: 'paragraph',
            text: 'Một số thuốc người lớn hay dùng lại nguy hiểm với trẻ nhỏ: aspirin không dùng cho trẻ dưới 16 tuổi; FDA và cơ quan quản lý thuốc châu Âu không cho dùng codein ở trẻ dưới 12 tuổi, FDA cũng không cho dùng tramadol ở tuổi này; FDA không khuyên dùng thuốc ho cảm không kê đơn cho trẻ dưới 2 tuổi.',
          },
          {
            type: 'paragraph',
            text: 'Kháng sinh chỉ diệt vi khuẩn, không chữa cảm lạnh, cúm hay phần lớn các ca sốt do virus. Dùng kháng sinh không cần thiết gây tiêu chảy, dị ứng và làm vi khuẩn kháng thuốc, điều WHO coi là một mối đe doạ lớn cho sức khoẻ toàn cầu. Ở Việt Nam: kháng sinh là thuốc kê đơn; chỉ dùng khi bác sĩ đã khám và kê.',
          },
          { type: 'heading', text: 'Bước 1 · Trước khi dùng thuốc' },
          {
            type: 'bullets',
            items: [
              'Hỏi bác sĩ hoặc dược sĩ: thuốc này để làm gì, liều bao nhiêu theo cân nặng hiện tại của bé, mấy lần một ngày, dùng trong bao lâu.',
              'Đọc nhãn: tên hoạt chất, nồng độ (ví dụ mg trong mỗi ml), hạn dùng. Kiểm tra các thuốc khác bé đang dùng có trùng hoạt chất không, nhất là paracetamol trong thuốc cảm.',
              'Nói với bác sĩ nếu bé sinh non, có bệnh gan, thận, tim, thiếu men G6PD hay từng dị ứng thuốc.',
            ],
          },
          { type: 'heading', text: 'Bước 2 · Đong và cho uống' },
          {
            type: 'bullets',
            items: [
              'Dùng xi lanh uống thuốc hoặc cốc có vạch ml đi kèm; không dùng thìa ăn, không ước lượng.',
              'Bé nhỏ: bế nửa ngồi, bơm từ từ vào phía trong má, không bơm thẳng vào họng.',
              'Không trộn thuốc vào cả bình sữa hay bát cháo: bé không ăn hết sẽ không đủ liều.',
              'Bé nôn ngay sau khi uống: hỏi dược sĩ có nên cho lại không, đừng tự cho thêm.',
            ],
          },
          { type: 'heading', text: 'Bước 3 · Ghi lại và theo dõi' },
          {
            type: 'bullets',
            items: [
              'Ghi giờ, tên thuốc và liều mỗi lần cho uống (có thể ghi trong Child Life), nhất là khi nhiều người cùng chăm bé, để tránh cho trùng liều.',
              'Dùng kháng sinh đủ số ngày bác sĩ dặn, kể cả khi bé đã đỡ; không để dành kháng sinh thừa cho lần sau hay cho trẻ khác.',
              'Để ý phản ứng: nổi mẩn, sưng môi, khó thở, nôn nhiều, li bì.',
            ],
          },
          { type: 'heading', text: 'Bước 4 · Cất giữ an toàn' },
          {
            type: 'bullets',
            items: [
              'Cất mọi thuốc, kể cả vitamin, sắt và thuốc của ông bà, trên cao, trong tủ có khoá, nắp chống trẻ em đóng chặt.',
              'Không gọi thuốc là “kẹo”; tránh uống thuốc trước mặt bé để bé không bắt chước.',
              'Bỏ thuốc hết hạn và siro đã mở quá thời gian ghi trên nhãn.',
            ],
          },
          { type: 'heading', text: 'Hiểu lầm thường gặp' },
          {
            type: 'bullets',
            items: [
              '“Ra hiệu thuốc mua kháng sinh cho nhanh khỏi”: phần lớn sốt, ho ở trẻ nhỏ do virus. Nên: chỉ dùng kháng sinh khi bác sĩ khám và kê đơn.',
              '“Thuốc người lớn, bẻ nửa viên cho bé là được”: liều và thành phần có thể không phù hợp, có thuốc nguy hiểm với trẻ. Nên: chỉ dùng thuốc dành cho trẻ, đúng liều theo cân nặng.',
              '“Thuốc nam, thuốc gia truyền thì lành, không hại”: một số sản phẩm không rõ thành phần, từng bị phát hiện lẫn corticoid mạnh. Nên: hỏi bác sĩ, dược sĩ trước khi dùng bất cứ thứ gì.',
              '“Sốt cao thì cho uống hai loại hạ sốt cùng lúc cho nhanh”: dễ quá liều. Nên: dùng một loại đúng liều; chỉ xen kẽ khi bác sĩ dặn.',
            ],
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Gọi 115 hoặc đến cấp cứu ngay khi',
            text: 'Bé uống nhầm thuốc, uống quá liều hay uống thuốc của người lớn, kể cả khi chưa có biểu hiện gì: mang theo vỏ thuốc và xem mục Sơ cứu trẻ em › Uống nhầm thuốc, hoá chất trong Child Life; bé khó thở, sưng môi, lưỡi, mặt hoặc nổi mẩn lan nhanh sau khi dùng thuốc; bé li bì hoặc co giật.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Hỏi bác sĩ hoặc dược sĩ khi',
            text: 'Ba mẹ chưa chắc liều theo cân nặng; bé nổi mẩn nhẹ, nôn hay tiêu chảy khi đang dùng thuốc; bé không đỡ sau thời gian bác sĩ dặn; hoặc bé đang dùng nhiều thuốc cùng lúc. Nếu bé nặng lên nhanh, gọi 115.',
          },
        ],
        en: [
          {
            type: 'callout',
            tone: 'note',
            title: 'In short',
            text: 'Before giving any medicine, know the active ingredient, the dose for your baby’s weight, the time between doses and the most allowed in a day. Measure with the syringe or marked cup that comes with it, never a kitchen spoon. Do not give antibiotics on your own, aspirin, adult medicines, or cough and cold medicines under age 2.',
          },
          { type: 'heading', text: 'Understanding why young children are at risk' },
          {
            type: 'paragraph',
            text: 'Children’s doses depend on weight, and the same medicine comes in different strengths, such as paracetamol drops and syrup. A kitchen spoon can give double the dose. The AAP advises using the ml-marked device that comes with the medicine, not kitchen spoons.',
          },
          {
            type: 'paragraph',
            text: 'Some common adult medicines are dangerous for young children: no aspirin under 16; the FDA and the European Medicines Agency say no codeine under 12, and the FDA also says no tramadol at that age; the FDA advises against over-the-counter cough and cold medicines under age 2.',
          },
          {
            type: 'paragraph',
            text: 'Antibiotics only kill bacteria; they do not treat colds, flu or most viral fevers. Unnecessary antibiotics cause diarrhoea and allergy and drive resistant bacteria, which WHO calls a major threat to global health. In Việt Nam: antibiotics are prescription medicines; use them only when a doctor has examined your child and prescribed them.',
          },
          { type: 'heading', text: 'Step 1 · Before you give it' },
          {
            type: 'bullets',
            items: [
              'Ask the doctor or pharmacist: what it is for, the dose for your child’s current weight, how many times a day and for how long.',
              'Read the label: active ingredient, strength (for example mg per ml) and expiry date. Check other medicines your child takes for the same ingredient, especially paracetamol in cold remedies.',
              'Tell the doctor if your child was born early, has liver, kidney or heart disease, G6PD deficiency or any medicine allergy.',
            ],
          },
          { type: 'heading', text: 'Step 2 · Measure and give' },
          {
            type: 'bullets',
            items: [
              'Use an oral syringe or the ml-marked cup supplied; no kitchen spoons, no guessing.',
              'For a baby: hold them semi-upright and squirt slowly into the inside of the cheek, not straight down the throat.',
              'Do not mix medicine into a whole bottle or bowl: if your child does not finish it, they miss part of the dose.',
              'If your child vomits straight after a dose, ask the pharmacist whether to repeat it rather than giving more yourself.',
            ],
          },
          { type: 'heading', text: 'Step 3 · Record and watch' },
          {
            type: 'bullets',
            items: [
              'Write down the time, medicine and dose each time (you can log it in Child Life), especially when several people care for your child, to avoid double doses.',
              'Finish the antibiotic course the doctor prescribed, even if your child is better; never keep leftovers for next time or for another child.',
              'Watch for reactions: rash, swollen lips, breathing trouble, a lot of vomiting or drowsiness.',
            ],
          },
          { type: 'heading', text: 'Step 4 · Store safely' },
          {
            type: 'bullets',
            items: [
              'Keep all medicines, including vitamins, iron and grandparents’ medicines, up high in a locked cupboard with child-resistant caps closed.',
              'Never call medicine “sweets”; avoid taking your own medicine in front of your child so they do not copy you.',
              'Throw away expired medicines and opened syrups past the time on the label.',
            ],
          },
          { type: 'heading', text: 'Common misconceptions' },
          {
            type: 'bullets',
            items: [
              '“Buy antibiotics at the pharmacy to get better faster”: most fevers and coughs in young children are viral. Instead: antibiotics only when a doctor examines your child and prescribes them.',
              '“Half an adult tablet will do”: the dose and ingredients may be wrong and some are dangerous for children. Instead: use only children’s medicines, dosed by weight.',
              '“Herbal and family remedies are gentle and harmless”: some have unknown contents and have been found to contain strong steroids. Instead: ask a doctor or pharmacist before using anything.',
              '“For a high fever, give two fever medicines together”: this risks overdose. Instead: use one at the right dose; alternate only if a doctor tells you to.',
            ],
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Call 115 (Việt Nam) or local emergency services now if',
            text: 'Your child swallows the wrong medicine, too much, or an adult’s medicine, even with no symptoms yet: take the packaging and see Sơ cứu trẻ em (First aid) › Swallowed medicine or chemicals in Child Life; your child has trouble breathing, swollen lips, tongue or face, or a fast-spreading rash after a medicine; or is very drowsy or has a fit.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Ask a doctor or pharmacist if',
            text: 'You are unsure of the dose for your child’s weight; your child gets a mild rash, vomiting or diarrhoea while on a medicine; is not better after the time the doctor gave; or is taking several medicines at once. If your child gets worse quickly, call emergency services.',
          },
        ],
      },
      keywords: {
        vi: [
          'liều thuốc',
          'kháng sinh',
          'xi lanh uống thuốc',
          'quá liều',
          'thuốc người lớn',
          'cất thuốc',
        ],
        en: [
          'medicine dose',
          'antibiotics',
          'oral syringe',
          'overdose',
          'adult medicines',
          'medicine storage',
        ],
      },
      relatedArticleIds: [
        'art_fever_when_to_call',
        'art_cold_cough',
        'art_vitamin_d_iron',
        'art_home_safety_falls',
      ],
      milestoneIds: [],
      sources: [
        {
          label: 'HealthyChildren.org (AAP) — Using liquid medicines',
          url: 'https://www.healthychildren.org/English/safety-prevention/at-home/medication-safety/Pages/Using-Liquid-Medicines.aspx',
        },
        {
          label:
            'U.S. FDA — Drug safety communication: FDA restricts use of codeine and tramadol in children (2017)',
          url: 'https://www.fda.gov/Drugs/DrugSafety/ucm549679.htm',
        },
        {
          label:
            'European Medicines Agency — Codeine-containing medicines for cough and cold in children',
          url: 'https://www.ema.europa.eu/en/medicines/human/referrals/codeine-containing-medicinal-products-treatment-cough-cold-paediatric-patients',
        },
        {
          label: 'WHO — Antimicrobial resistance (fact sheet)',
          url: 'https://www.who.int/news-room/fact-sheets/detail/antimicrobial-resistance',
        },
        {
          label: 'U.S. FDA — Should you give kids medicine for coughs and colds?',
          url: 'https://www.fda.gov/consumers/consumer-updates/should-you-give-kids-medicine-coughs-and-colds',
        },
        {
          label: 'NHS — Paracetamol for children',
          url: 'https://www.nhs.uk/medicines/paracetamol-for-children/',
        },
        {
          label:
            "MHRA (UK) — Natural doesn't mean safe: herbal medicines found to contain steroids",
          url: 'https://www.gov.uk/government/news/natural-doesnt-mean-safe-herbal-medicines-found-to-contain-steroids',
        },
      ],
    },
  },
  // ----- Added 2026-10-18 (D-080): night waking, weaning, work, dummies, dengue, thrush, ears,
  // eyes, childcare, flat head, first steps, genital care. Engineering drafts, review null. -----
  {
    id: 'art_night_waking_settling',
    reviewerLabel: 'Nhóm chuyên môn · Nhi khoa',
    data: {
      library: 'care',
      topic: 'sleep',
      format: 'article',
      ageWeeks: {
        from: 26,
        to: 104,
      },
      readingMinutes: 7,
      cover: null,
      title: {
        vi: 'Bé 6–24 tháng hay thức đêm: hiểu nguyên nhân và giúp bé tự ngủ lại',
        en: 'Night waking at 6–24 months: why it happens and how to help your child resettle',
      },
      summary: {
        vi: 'Tỉnh giấc giữa đêm là bình thường; điều ba mẹ có thể giúp là cách bé ngủ lại. Bài viết giải thích thói quen gắn với giấc ngủ, các cách dỗ từ từ, sự đồng lòng giữa người chăm và khi nào thức đêm là dấu hiệu bệnh.',
        en: 'Waking in the night is normal; what you can help with is how your child falls back asleep. This covers sleep associations, gradual settling methods, carers working together and when night waking points to illness.',
      },
      body: {
        vi: [
          {
            type: 'callout',
            tone: 'note',
            title: 'Tóm tắt nhanh',
            text: 'Bé nào cũng tỉnh giấc vài lần mỗi đêm; điều thay đổi được là cách bé chìm lại vào giấc ngủ. Hãy thay đổi từ từ, để mọi người chăm cùng làm một cách, và luôn nghĩ đến bệnh trước khi tập cho bé tự ngủ.',
          },
          {
            type: 'heading',
            text: 'Thức đêm thế nào là bình thường?',
          },
          {
            type: 'paragraph',
            text: 'Giấc ngủ của bé gồm nhiều chu kỳ ngắn hơn người lớn. Cuối mỗi chu kỳ, bé hay trở mình, cựa quậy, có khi ê a hoặc khóc ngắn rồi ngủ tiếp. Theo AAP, bé 6 tháng thức dậy rồi tự ngủ lại sau vài phút là bình thường. NHS cho biết trong khoảng 6–12 tháng, một số bé không còn cần bú đêm, nhưng mọc răng, đói hay ốm vẫn có thể làm bé thức. Ở tuổi 1–2, lo xa ba mẹ, tập đi hay bắt đầu đi nhà trẻ cũng khiến bé thức nhiều hơn một thời gian. Số giờ ngủ theo từng tuổi có trong bài Giấc ngủ theo tháng tuổi.',
          },
          {
            type: 'paragraph',
            text: 'Không phải bé nào thức đêm cũng cần “sửa”. Nếu bé thức một hai lần, ngủ lại nhanh, ban ngày vui khoẻ và cả nhà vẫn ổn, ba mẹ cứ tiếp tục như hiện tại. Nên cân nhắc thay đổi khi bé thức nhiều lần mỗi đêm, chỉ ngủ lại khi được bú, bế hay đưa võng, kéo dài nhiều tuần, và ba mẹ đang kiệt sức.',
          },
          {
            type: 'heading',
            text: 'Thói quen gắn với giấc ngủ là gì?',
          },
          {
            type: 'paragraph',
            text: 'Khi tỉnh giữa đêm, bé thường muốn có lại đúng những điều đã có lúc bé thiếp đi. Nếu bé ngủ thiếp trên ngực mẹ, trong vòng tay, trên võng đang đưa hay khi đang ngậm bình, lúc tỉnh giữa hai chu kỳ bé sẽ tìm lại điều đó và gọi ba mẹ. Đây không phải là bé “hư”, mà là cách bé học. AAP lưu ý bé được bế hoặc ru đến khi ngủ hẳn có thể khó tự ngủ lại khi thức giữa đêm.',
          },
          {
            type: 'paragraph',
            text: 'Ba mẹ không cần bỏ hết những khoảnh khắc âu yếm. Bú mẹ, ôm ấp, hát ru vẫn là phần đẹp của buổi tối. Mục tiêu chỉ là bước cuối cùng, lúc bé chìm vào giấc ngủ, diễn ra ở chỗ ngủ của bé.',
          },
          {
            type: 'heading',
            text: 'Nếp đi ngủ giúp bé dễ ngủ lại',
          },
          {
            type: 'bullets',
            items: [
              'Cho bú hoặc uống sữa ở đầu nếp đi ngủ, rồi mới đánh răng, đọc truyện; như vậy bé không quen “bú là ngủ”.',
              'Giữ nếp ngủ ngắn, khoảng 20–30 phút, cùng một thứ tự, ở chính phòng bé ngủ, đèn dịu.',
              'Đặt bé xuống khi bé đã buồn ngủ nhưng còn thức, kèm một câu chúc ngủ ngon quen thuộc.',
              'Giữ điều kiện lúc bé thiếp đi giống lúc nửa đêm: nếu bật đèn ngủ hay tiếng ồn đều thì để suốt đêm, không tắt sau khi bé ngủ.',
              'Bắt đầu nếp ngủ khi thấy bé dụi mắt, ngáp, nhìn xa xăm; bé quá mệt thường khó ngủ và hay thức hơn.',
              'Từ 12 tháng có thể cho bé một vật quen để ôm; với bé dưới 12 tháng, chỗ ngủ vẫn trống, không gối, chăn dày hay thú bông (xem bài Ngủ an toàn).',
            ],
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'Chờ một chút trước khi vào',
            text: 'Bé cựa quậy, ê a hay khóc ngắn không phải lúc nào cũng cần ba mẹ. Chờ vài phút xem bé có tự ngủ lại không. Nếu bé khóc to, hoảng hốt hoặc có vẻ đau, hãy đến với bé ngay.',
          },
          {
            type: 'heading',
            text: 'Giúp bé ngủ lại: các cách từ từ',
          },
          {
            type: 'paragraph',
            text: 'Không có một cách duy nhất đúng. Hãy chọn cách hợp với bé và gia đình, và bắt đầu khi bé khoẻ, không trong đợt ốm, mọc răng hay vừa có thay đổi lớn như đi nhà trẻ, chuyển nhà. Mỗi cách cần vài ngày đến vài tuần kiên trì.',
          },
          {
            type: 'bullets',
            items: [
              'Dỗ tại chỗ: khi bé thức, đến xoa lưng, vỗ nhẹ, nói nhỏ nhưng để bé nằm yên ở chỗ ngủ; qua từng đêm giảm dần mức dỗ, từ vỗ sang chỉ đặt tay, rồi chỉ nói.',
              'Bớt dần thói quen cũ: nếu bé chỉ ngủ khi được bú, rút ngắn dần cữ bú trước ngủ và dừng khi bé còn thức; nếu bé quen được bế, bế đến khi bé dịu rồi đặt xuống.',
              'Ngồi cạnh rồi lùi dần: ngồi cạnh chỗ ngủ đến khi bé ngủ, vài đêm lại lùi ghế xa hơn, cuối cùng ra ngoài cửa.',
              'Vào dỗ cách quãng dài dần: đặt bé xuống, ra khỏi phòng; nếu bé khóc, vào dỗ ngắn sau 2 phút, lần sau 4 phút, rồi 6 phút, không bế bé ra. Cách này thường dùng từ khoảng 6 tháng.',
              'Lùi giờ đi ngủ: nếu bé nằm rất lâu mới ngủ, tạm cho bé đi ngủ muộn hơn 15–30 phút, đúng lúc bé buồn ngủ thật, rồi kéo sớm dần.',
            ],
          },
          {
            type: 'paragraph',
            text: 'Nhiều ba mẹ lo các cách có để bé khóc sẽ làm tổn thương sự gắn bó. Một thử nghiệm ở Úc năm 2016 với bé 6–16 tháng thấy cách vào dỗ cách quãng dài dần và cách lùi giờ đi ngủ đều giúp bé ngủ nhanh hơn, không làm tăng hormone căng thẳng và không ảnh hưởng đến sự gắn bó an toàn giữa bé và mẹ một năm sau. Một nghiên cứu lớn hơn ở Úc theo dõi trẻ đến 6 tuổi cũng không thấy khác biệt về cảm xúc, hành vi hay sự gần gũi với cha mẹ. Nếu ba mẹ không muốn để bé khóc, các cách nhẹ nhàng hơn vẫn dùng được, chỉ có thể lâu hơn. Dù chọn cách nào, đó không phải là bỏ mặc bé.',
          },
          {
            type: 'heading',
            text: 'Mọi người chăm cùng một cách',
          },
          {
            type: 'paragraph',
            text: 'Bé học nhanh nhất khi mọi người phản ứng giống nhau. Nếu mẹ dỗ tại chỗ nhưng bà bế ra võng, hay ba pha bình mỗi lần bé thức, bé sẽ khóc lâu hơn để chờ cách mình thích nhất. Trước khi bắt đầu, cả nhà nên thống nhất: bé ngủ ở đâu, ai dậy đêm nào, làm gì khi bé thức, và sau bao lâu thì xem lại.',
          },
          {
            type: 'paragraph',
            text: 'Ông bà thương cháu, nghe cháu khóc là xót. Hãy giải thích rằng cách mới không bỏ mặc bé mà giúp bé ngủ ngon hơn, và nhờ ông bà giữ cùng nếp đi ngủ khi trông bé ngủ trưa. Ba mẹ có thể chia ca để mỗi người được ngủ một mạch vài đêm trong tuần.',
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'Ghi lại để thấy tiến bộ',
            text: 'Ghi giờ bé thức, cách dỗ và bao lâu bé ngủ lại trong Child Life suốt 1–2 tuần. Tiến bộ thường đến từng chút, và vài đêm đầu có thể khó hơn trước khi khá lên.',
          },
          {
            type: 'heading',
            text: 'Khi thức đêm là dấu hiệu sức khoẻ',
          },
          {
            type: 'bullets',
            items: [
              'Ốm: sốt, nghẹt mũi, ho làm bé thức và quấy hơn. Khi bé ốm, hãy dỗ và chăm bé như bé cần, tạm dừng việc tập ngủ đến khi bé khoẻ hẳn.',
              'Đau tai: bé kéo tai, khóc nhiều hơn khi nằm, thường kèm sốt hoặc vừa bị cảm.',
              'Ngứa và khó chịu: chàm, hăm, táo bón có thể làm bé thức nhiều lần.',
              'Ngáy và ngừng thở khi ngủ: bé ngáy to gần như mỗi đêm, thở bằng miệng, có lúc ngừng thở rồi thở hắt, ngủ vặn mình, vã mồ hôi; ban ngày mệt, cáu kỉnh. Nguyên nhân hay gặp là VA và amidan to; bé cần được khám.',
              'Thiếu sắt: bé sinh non, nhẹ cân, ăn ít thịt cá, hoặc uống quá nhiều sữa bò dễ thiếu sắt. Thiếu sắt có thể làm bé xanh xao, mệt, và một số nghiên cứu thấy liên quan với ngủ không yên. Bác sĩ có thể cho xét nghiệm máu; đừng tự cho bé uống sắt.',
              'Đói: bé ăn dặm ít hoặc chậm tăng cân có thể thức vì đói thật; hãy xem lại bữa ăn ban ngày với bác sĩ.',
            ],
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Khi nào nên đưa bé đi khám',
            text: 'Bé ngáy to gần như mỗi đêm, có lúc ngừng thở, thở hắt hoặc thở gắng sức khi ngủ; thức đêm kèm sốt, đau tai, nôn hay khóc thét không dỗ được; ban ngày lờ đờ, xanh xao, chậm tăng cân; gãi ngứa nhiều về đêm; thức đêm kéo dài nhiều tuần dù đã giữ nếp ngủ đều; hoặc ba mẹ kiệt sức, buồn bã. Gọi 115 nếu bé tím tái, khó thở hoặc khó đánh thức.',
          },
        ],
        en: [
          {
            type: 'callout',
            tone: 'note',
            title: 'In short',
            text: 'Every child wakes several times a night; what can change is how they drift back to sleep. Make changes gradually, have every carer respond the same way, and always think about illness before working on independent settling.',
          },
          {
            type: 'heading',
            text: 'How much night waking is normal?',
          },
          {
            type: 'paragraph',
            text: "A baby's sleep is made up of cycles that are shorter than an adult's. At the end of each cycle, babies often turn, stir, babble or cry briefly and then go back to sleep. The AAP says it is normal for a 6-month-old to wake and fall back asleep after a few minutes. The NHS notes that between 6 and 12 months some babies no longer need night feeds, but teething, hunger or illness can still wake them. Between 1 and 2, separation anxiety, learning to walk or starting childcare can also bring more waking for a while. Sleep hours by age are covered in Sleep by age.",
          },
          {
            type: 'paragraph',
            text: 'Not every child who wakes at night needs “fixing”. If your child wakes once or twice, resettles quickly, is happy and well in the day and the family is coping, carry on as you are. It is worth making changes when your child wakes many times a night, only resettles with a feed, a cuddle or a swing in the hammock, this has gone on for weeks and you are exhausted.',
          },
          {
            type: 'heading',
            text: 'What are sleep associations?',
          },
          {
            type: 'paragraph',
            text: 'When they wake in the night, children usually want exactly what they had when they fell asleep. If your child drifts off at the breast, in your arms, in a moving hammock or with a bottle, then between cycles they look for the same thing and call for you. This is not being “naughty”; it is how they learn. The AAP notes that babies who are held or rocked until fully asleep may find it hard to fall back asleep when they wake in the night.',
          },
          {
            type: 'paragraph',
            text: "You don't need to give up the cosy moments. Breastfeeds, cuddles and lullabies are still a lovely part of the evening. The aim is only that the last step, the moment your child falls asleep, happens in their own sleep space.",
          },
          {
            type: 'heading',
            text: 'A bedtime routine that makes resettling easier',
          },
          {
            type: 'bullets',
            items: [
              "Give the breastfeed or milk at the start of the routine, then teeth and a story, so your child doesn't learn that “feeding means sleeping”.",
              'Keep the routine short, about 20–30 minutes, in the same order, in the room where your child sleeps, with soft light.',
              'Lay your child down drowsy but awake, with a familiar goodnight phrase.',
              'Keep conditions at sleep time the same as in the middle of the night: if you use a night light or steady background sound, leave it on all night rather than switching it off once they are asleep.',
              'Start the routine when you see eye rubbing, yawning or staring into space; overtired children often struggle to settle and wake more.',
              'From 12 months you can offer a familiar comfort object; under 12 months, keep the sleep space bare, with no pillows, thick blankets or soft toys (see Safe sleep).',
            ],
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'Pause before you go in',
            text: "Stirring, babbling or a short cry doesn't always need you. Wait a few minutes to see whether your child resettles. If they cry hard, sound panicked or seem to be in pain, go to them straight away.",
          },
          {
            type: 'heading',
            text: 'Helping your child resettle: gradual methods',
          },
          {
            type: 'paragraph',
            text: 'There is no single right way. Choose what suits your child and family, and start when your child is well, not during an illness, teething or just after a big change such as starting childcare or moving house. Each method takes a few days to a few weeks of patience.',
          },
          {
            type: 'bullets',
            items: [
              'Settling in place: when your child wakes, go in and rub their back, pat gently or talk softly while they stay lying in their sleep space; over the nights, do a little less each time, from patting to just a hand resting, then just your voice.',
              'Fading an old habit: if your child only falls asleep feeding, gradually shorten the bedtime feed and stop while they are still awake; if they are used to being held, hold them until calm, then lay them down.',
              'Sitting nearby, then moving away: sit next to the sleep space until your child falls asleep, and every few nights move your chair further away, finally to the doorway.',
              'Checking in at longer intervals: lay your child down and leave the room; if they cry, go in briefly after 2 minutes, then 4, then 6, without picking them up. This is usually used from around 6 months.',
              'Bedtime fading: if your child lies awake for a long time, temporarily move bedtime 15–30 minutes later, to when they are truly sleepy, then bring it gradually earlier.',
            ],
          },
          {
            type: 'paragraph',
            text: 'Many parents worry that methods involving some crying might harm attachment. A 2016 Australian trial in babies aged 6–16 months found that checking in at longer intervals and bedtime fading both helped babies fall asleep faster, did not raise stress hormone levels and did not affect secure attachment between baby and mother a year later. A larger Australian study following children to age 6 also found no differences in emotions, behaviour or closeness to parents. If you would rather not let your child cry, gentler methods can still work, though they may take longer. Whatever you choose, it is not leaving your child alone.',
          },
          {
            type: 'heading',
            text: 'Every carer, the same approach',
          },
          {
            type: 'paragraph',
            text: 'Children learn fastest when everyone responds the same way. If mum settles in place but grandma carries the baby to the hammock, or dad makes up a bottle at every waking, your child will cry longer, waiting for the response they like best. Before you start, agree as a family: where your child sleeps, who gets up on which night, what to do when they wake, and when you will review how it is going.',
          },
          {
            type: 'paragraph',
            text: "Grandparents love their grandchildren and find the crying hard to hear. Explain that the new approach doesn't abandon the child but helps them sleep better, and ask them to keep the same routine when they look after naps. Parents can take turns so that each of you gets a full night's sleep a few nights a week.",
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'Keep a log to see progress',
            text: 'Note waking times, how you settled your child and how long it took in Child Life for 1–2 weeks. Progress usually comes bit by bit, and the first few nights can be harder before things improve.',
          },
          {
            type: 'heading',
            text: 'When night waking is a health sign',
          },
          {
            type: 'bullets',
            items: [
              'Illness: fever, a blocked nose or a cough make children wake and fuss more. When your child is unwell, comfort and care for them as they need, and pause sleep changes until they are fully better.',
              'Ear pain: pulling at the ear, crying more when lying down, often with a fever or after a cold.',
              'Itching and discomfort: eczema, nappy rash or constipation can cause repeated waking.',
              'Snoring and pauses in breathing: loud snoring most nights, mouth breathing, pauses in breathing followed by gasps, restless sleep, heavy sweating; daytime tiredness or irritability. Enlarged adenoids and tonsils are a common cause; your child needs to be seen.',
              "Iron deficiency: children born early or small, who eat little meat or fish, or who drink too much cow's milk are more likely to lack iron. It can cause paleness and tiredness, and some studies link it with restless sleep. A doctor can arrange a blood test; don't give iron supplements on your own.",
              'Hunger: a child who eats few solids or is gaining weight slowly may truly wake from hunger; review daytime meals with your doctor.',
            ],
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'When to see a doctor',
            text: "Your child snores loudly most nights, pauses breathing, gasps or works hard to breathe in sleep; wakes with fever, ear pain, vomiting or a high-pitched cry you can't soothe; is drowsy, pale or gaining weight slowly; scratches a lot at night; keeps waking for weeks despite a steady routine; or you are exhausted or low. Call 115 (Việt Nam) or local emergency services if your child turns blue, struggles to breathe or is hard to wake.",
          },
        ],
      },
      keywords: {
        vi: [
          'thức đêm',
          'dỗ ngủ',
          'tự ngủ lại',
          'luyện ngủ',
          'nếp đi ngủ',
          'thói quen ngủ',
          'ngáy',
          'ngừng thở khi ngủ',
          'thiếu sắt',
        ],
        en: [
          'night waking',
          'settling',
          'self-settling',
          'sleep training',
          'bedtime routine',
          'sleep associations',
          'snoring',
          'sleep apnoea',
          'iron deficiency',
        ],
      },
      relatedArticleIds: [
        'art_sleep_by_age',
        'art_safe_sleep',
        'art_night_weaning',
        'art_vitamin_d_iron',
      ],
      milestoneIds: [],
      sources: [
        {
          label: 'HealthyChildren.org (AAP) — Getting your baby to sleep',
          url: 'https://www.healthychildren.org/English/ages-stages/baby/sleep/Pages/Getting-Your-Baby-to-Sleep.aspx',
        },
        {
          label: 'NHS — Helping your baby to sleep',
          url: 'https://www.nhs.uk/baby/caring-for-a-newborn/helping-your-baby-to-sleep/',
        },
        {
          label:
            'Canadian Paediatric Society (Caring for Kids) — Healthy sleep for your baby and child',
          url: 'https://caringforkids.cps.ca/handouts/pregnancy-and-babies/healthy_sleep_for_your_baby_and_child',
        },
        {
          label:
            'PubMed — Pediatrics 2016: Behavioral interventions for infant sleep problems: a randomized controlled trial',
          url: 'https://pubmed.ncbi.nlm.nih.gov/27221288/',
        },
        {
          label:
            'PubMed — Pediatrics 2012: Five-year follow-up of harms and benefits of behavioral infant sleep intervention: randomized trial',
          url: 'https://pubmed.ncbi.nlm.nih.gov/22966034/',
        },
      ],
    },
  },
  {
    id: 'art_night_weaning',
    reviewerLabel: 'Nhóm chuyên môn · Tư vấn sữa mẹ (IBCLC)',
    data: {
      library: 'care',
      topic: 'feeding',
      format: 'article',
      ageWeeks: {
        from: 26,
        to: 156,
      },
      readingMinutes: 5,
      cover: null,
      title: {
        vi: 'Cai bú đêm và cai sữa nhẹ nhàng: khi nào, làm từng bước thế nào',
        en: 'Night weaning and stopping breast or bottle feeds gently: when and how',
      },
      summary: {
        vi: 'Không có tuổi “phải” cai sữa; WHO khuyên bú mẹ đến 2 tuổi hoặc lâu hơn. Khi mẹ và bé sẵn sàng, bớt từng cữ một, dỗ bé bằng cách khác và chăm ngực mẹ để tránh căng tức, viêm tuyến vú.',
        en: 'There is no age you “must” wean; WHO recommends breastfeeding to 2 years or beyond. When you are both ready, drop one feed at a time, comfort your child in other ways and look after your breasts to avoid engorgement and mastitis.',
      },
      body: {
        vi: [
          {
            type: 'callout',
            tone: 'note',
            title: 'Tóm tắt nhanh',
            text: 'Cai bú đêm hay cai sữa hẳn là quyết định của mẹ và bé, không có mốc tuổi bắt buộc. Làm chậm, bớt từng cữ một, giúp bé dễ chịu hơn và ngực mẹ ít bị căng tức hay viêm.',
          },
          {
            type: 'heading',
            text: 'Bú mẹ đến bao lâu?',
          },
          {
            type: 'paragraph',
            text: 'WHO và UNICEF khuyên cho bé bú mẹ hoàn toàn trong 6 tháng đầu, sau đó ăn dặm và tiếp tục bú mẹ đến 2 tuổi hoặc lâu hơn. AAP cũng khuyên tiếp tục bú mẹ đến 2 tuổi hoặc hơn, miễn là mẹ và bé đều muốn. NHS nhấn mạnh việc dừng lúc nào là do mẹ và bé quyết định. Thôi cho bú sớm hơn vì đi làm, vì sức khoẻ hay vì hoàn cảnh không phải là thất bại.',
          },
          {
            type: 'heading',
            text: 'Khi nào bé không còn cần bú đêm?',
          },
          {
            type: 'paragraph',
            text: 'Không có mốc chung cho mọi bé. NHS cho biết cữ đêm thường thưa dần từ khoảng 3–6 tháng, và trong khoảng 6–12 tháng một số bé không còn cần bú đêm để đủ chất. Nhiều bé khác, nhất là bé bú mẹ, vẫn bú đêm đến tuổi tập đi, và điều đó vẫn bình thường. Bé bú đêm không chỉ vì đói mà còn để được gần mẹ, được an ủi.',
          },
          {
            type: 'paragraph',
            text: 'Bé có thể sẵn sàng bớt cữ đêm khi bé ăn dặm tốt, tăng cân đều theo biểu đồ, bú ban ngày đủ, và cữ đêm chỉ mút lơ mơ vài phút rồi ngủ. Bé sinh non, nhẹ cân, chậm tăng cân hoặc có bệnh lý: hỏi bác sĩ trước khi bớt cữ đêm.',
          },
          {
            type: 'heading',
            text: 'Cai bú đêm từng bước',
          },
          {
            type: 'bullets',
            items: [
              'Chọn lúc bé khoẻ, không ốm, không đau vì mọc răng, và không trùng với thay đổi lớn như mẹ vừa đi làm lại hay bé mới đi nhà trẻ.',
              'Cho bé ăn dặm và bú đủ ban ngày, nhất là bữa tối và cữ bú đầu nếp đi ngủ, để bé bù lượng sữa ban đêm.',
              'Tách bú khỏi giấc ngủ: cho bú ở đầu nếp đi ngủ, rồi mới đọc truyện và đặt bé xuống khi còn thức.',
              'Bớt mỗi lần một cữ đêm, bắt đầu từ cữ bé có vẻ ít cần nhất, chờ vài đêm cho bé quen rồi mới bớt tiếp.',
              'Rút ngắn dần: bú mẹ thì bớt 1–2 phút mỗi cữ sau vài đêm; bú bình thì bớt khoảng 30 ml mỗi vài đêm. Khi chỉ còn rất ít, thay hẳn bằng dỗ.',
              'Những đêm đầu, nhờ ba hoặc người thân dỗ bé khi bé thức; bé bú mẹ thường đòi bú nhiều hơn khi ngửi thấy mẹ ở gần.',
              'Không cho bé ngậm bình đi ngủ, không thay sữa bằng nước đường hay nước trái cây trong bình.',
            ],
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'Dỗ bé không cần ti mẹ hay bình',
            text: 'Ôm bé, xoa lưng, hát một câu ru quen, cho vài ngụm nước bằng cốc nếu bé trên 6 tháng, và từ 12 tháng có thể cho bé ôm một vật quen. Bé có thể phản đối vài đêm; hãy ở bên bé, bình tĩnh và làm giống nhau mỗi đêm.',
          },
          {
            type: 'heading',
            text: 'Cai sữa hẳn: chậm mà chắc',
          },
          {
            type: 'paragraph',
            text: 'AAP và NHS đều khuyên bỏ một cữ mỗi lần. Khi bé và ngực mẹ đã quen, thường sau vài ngày đến một tuần, mới bỏ tiếp cữ khác. Cả quá trình có thể mất vài tuần đến vài tháng. Cữ sáng sớm và cữ trước khi ngủ thường là cữ bé giữ lâu nhất, nên để lại sau cùng. Mẹ cũng có thể giữ lại một hai cữ mà cả hai thích.',
          },
          {
            type: 'bullets',
            items: [
              'Tránh những dấu hiệu gợi bé đòi bú: không ngồi vào chỗ quen cho bú, không thay áo trước mặt bé; đổi chỗ, đổi hoạt động vào giờ bé hay đòi.',
              'Ôm ấp, chơi, đọc truyện nhiều hơn để bù cho sự gần gũi khi bú.',
              'Đánh lạc hướng bằng bữa phụ, đồ uống trong cốc, đi dạo hay một trò chơi mới.',
              'Ông bà có thể khuyên bôi dầu gió, ớt lên ngực hay gửi bé đi xa vài hôm cho “dứt”. Cách này làm bé hoảng sợ, có thể làm cay mắt, rát miệng bé, và cai đột ngột dễ khiến ngực mẹ căng tức, viêm. Nên cai từ từ như trên.',
            ],
          },
          {
            type: 'heading',
            text: 'Bé uống gì thay cữ bú?',
          },
          {
            type: 'paragraph',
            text: 'Dưới 1 tuổi, sữa mẹ hoặc sữa công thức vẫn là thức uống chính: mỗi cữ bú mẹ bỏ đi được thay bằng sữa mẹ vắt hoặc sữa công thức, từ 6 tháng có thể cho uống bằng cốc. Không dùng sữa bò tươi làm thức uống chính trước 1 tuổi. Từ 1 tuổi, khi bé đã ăn đa dạng, NHS cho biết không cần cữ thay thế; lượng và loại sữa phù hợp có trong bài Bé từ 1 tuổi uống sữa gì.',
          },
          {
            type: 'heading',
            text: 'Chăm ngực mẹ khi cai sữa',
          },
          {
            type: 'bullets',
            items: [
              'Giảm từ từ là cách tốt nhất để phòng căng tức và viêm tuyến vú.',
              'Nếu ngực căng khó chịu, vắt tay hoặc hút ra một ít, vừa đủ cho dễ chịu; không vắt cạn, vì vắt cạn báo cho cơ thể tiếp tục tạo nhiều sữa.',
              'Chườm mát khoảng 10 phút, mặc áo ngực vừa vặn, nâng đỡ tốt; không bó chặt ngực.',
              'Không tự dùng thuốc làm mất sữa; nếu cần, hỏi bác sĩ.',
              'Một vùng ngực sưng, nóng, đỏ, đau hoặc có cục cứng, kèm sốt, ớn lạnh, mệt như cúm có thể là viêm tuyến vú; nếu không đỡ sau 12–24 giờ tự chăm, mẹ nên đi khám.',
              'Nhiều mẹ thấy cảm xúc lẫn lộn khi thôi cho bú. Hãy chia sẻ với người thân, và tìm hỗ trợ nếu buồn bã kéo dài.',
            ],
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Khi nào nên đưa bé đi khám',
            text: 'Bé ít tã ướt hơn hẳn, nước tiểu sẫm, môi khô, lừ đừ; bé sụt cân hoặc chậm tăng cân sau khi bớt cữ; bé từ chối cả cốc lẫn bình và uống rất ít; bé thức đêm kèm sốt, đau tai hay khóc bất thường. Mẹ nên đi khám khi ngực sưng nóng đỏ đau kèm sốt không đỡ sau 12–24 giờ. Gọi 115 nếu bé lả, khó đánh thức hoặc có dấu hiệu mất nước nặng.',
          },
        ],
        en: [
          {
            type: 'callout',
            tone: 'note',
            title: 'In short',
            text: 'Stopping night feeds or weaning altogether is a decision for you and your child, with no required age. Going slowly, one feed at a time, is easier on your child and less likely to leave your breasts engorged or inflamed.',
          },
          {
            type: 'heading',
            text: 'How long to breastfeed?',
          },
          {
            type: 'paragraph',
            text: 'WHO and UNICEF recommend exclusive breastfeeding for the first 6 months, then solid foods alongside continued breastfeeding to 2 years or beyond. The AAP also advises continuing to 2 years or beyond, as long as mother and child both want to. The NHS stresses that when to stop is up to you and your baby. Stopping earlier because of work, health or circumstances is not a failure.',
          },
          {
            type: 'heading',
            text: 'When does a baby no longer need night feeds?',
          },
          {
            type: 'paragraph',
            text: 'There is no single age for every baby. The NHS says night feeds usually become less frequent from around 3–6 months, and that between 6 and 12 months some babies no longer need them for nutrition. Many others, especially breastfed babies, still feed at night into toddlerhood, and that is normal too. Night feeds are not only about hunger; they are also about closeness and comfort.',
          },
          {
            type: 'paragraph',
            text: 'Your baby may be ready to drop night feeds when they eat solids well, grow steadily along their chart, feed well in the day, and night feeds are just a few sleepy minutes of sucking. If your baby was born early or small, is gaining weight slowly or has a health condition, ask your doctor before cutting night feeds.',
          },
          {
            type: 'heading',
            text: 'Night weaning step by step',
          },
          {
            type: 'bullets',
            items: [
              'Choose a time when your child is well, not ill or in pain from teething, and not alongside a big change such as you returning to work or starting childcare.',
              'Make sure your child eats and feeds well in the day, especially the evening meal and the feed at the start of the bedtime routine, so they can make up for night milk.',
              'Separate feeding from falling asleep: feed at the start of the bedtime routine, then read a story and lay your child down awake.',
              'Drop one night feed at a time, starting with the one your child seems to need least, and wait a few nights before dropping the next.',
              'Shorten gradually: for breastfeeds, cut 1–2 minutes from each feed every few nights; for bottles, reduce by about 30 ml every few nights. When very little is left, replace it with comforting.',
              'For the first few nights, ask your partner or another family member to settle your child when they wake; breastfed children often ask to feed more when they can smell their mother nearby.',
              "Don't put your child to bed with a bottle, and don't swap milk for sugary water or juice in the bottle.",
            ],
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'Comfort without the breast or bottle',
            text: 'Cuddle, rub their back, sing a familiar lullaby, offer a few sips of water from a cup if they are over 6 months, and from 12 months a familiar comfort object. Your child may protest for a few nights; stay with them, stay calm and do the same thing each night.',
          },
          {
            type: 'heading',
            text: 'Stopping altogether: slow and steady',
          },
          {
            type: 'paragraph',
            text: 'The AAP and NHS both advise dropping one feed at a time. Once your child and your breasts have adjusted, usually after a few days to a week, drop another. The whole process can take a few weeks to several months. The early-morning and bedtime feeds are usually the last to go, so leave them until the end. You can also keep one or two feeds you both enjoy.',
          },
          {
            type: 'bullets',
            items: [
              "Avoid cues that prompt a feed: don't sit in your usual feeding spot or change clothes in front of your child; change places and activities at the times they usually ask.",
              'Offer more cuddles, play and stories to make up for the closeness of feeding.',
              'Distract with a snack, a drink from a cup, a walk or a new game.',
              'Grandparents may suggest putting menthol oil or chilli on the breast, or sending the child away for a few days to make a clean break. This frightens children, can sting their eyes and mouth, and stopping suddenly makes engorgement and mastitis more likely. Wean gradually as above instead.',
            ],
          },
          {
            type: 'heading',
            text: 'What to give instead of a feed',
          },
          {
            type: 'paragraph',
            text: "Under 1 year, breast milk or formula is still the main drink: replace each dropped breastfeed with expressed breast milk or formula, from a cup if your baby is over 6 months. Cow's milk is not suitable as a main drink before 1 year. From 1 year, once your child eats a variety of foods, the NHS says no replacement feed is needed; the right type and amount of milk are covered in Milk from age 1.",
          },
          {
            type: 'heading',
            text: 'Looking after your breasts while weaning',
          },
          {
            type: 'bullets',
            items: [
              'Cutting down gradually is the best way to prevent engorgement and mastitis.',
              "If your breasts feel uncomfortably full, hand express or pump a little, just enough to feel comfortable; don't empty them, as that tells your body to keep making plenty of milk.",
              "Use a cold compress for about 10 minutes and wear a well-fitting, supportive bra; don't bind your breasts.",
              "Don't take medicines to dry up milk on your own; ask a doctor if needed.",
              "A swollen, hot, red or painful area or a hard lump, with fever, chills or flu-like tiredness, may be mastitis; if it isn't better after 12–24 hours of self-care, see a doctor.",
              'Many mothers have mixed feelings when breastfeeding ends. Talk to people close to you, and seek support if low mood lasts.',
            ],
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'When to see a doctor',
            text: "Your child has far fewer wet nappies, dark urine, a dry mouth or is listless; loses weight or grows slowly after feeds are cut; refuses both cup and bottle and drinks very little; or wakes at night with fever, ear pain or unusual crying. See a doctor yourself if a red, hot, painful breast with fever isn't better after 12–24 hours. Call 115 (Việt Nam) or local emergency services if your child is floppy, hard to wake or severely dehydrated.",
          },
        ],
      },
      keywords: {
        vi: [
          'cai sữa',
          'cai bú đêm',
          'bú đêm',
          'cai bú mẹ',
          'cai bình',
          'căng tức ngực',
          'viêm tuyến vú',
          'bú mẹ đến 2 tuổi',
        ],
        en: [
          'weaning',
          'night weaning',
          'night feeds',
          'stopping breastfeeding',
          'stopping the bottle',
          'engorgement',
          'mastitis',
          'breastfeeding to 2 years',
        ],
      },
      relatedArticleIds: [
        'art_toddler_milk',
        'art_night_waking_settling',
        'art_pacifier_bottle_habits',
        'art_expressing_storing_milk',
      ],
      milestoneIds: [],
      sources: [
        {
          label: 'WHO — Infant and young child feeding (fact sheet)',
          url: 'https://www.who.int/news-room/fact-sheets/detail/infant-and-young-child-feeding',
        },
        {
          label: 'HealthyChildren.org (AAP) — Weaning your baby',
          url: 'https://www.healthychildren.org/English/ages-stages/baby/breastfeeding/Pages/Weaning-Your-Baby.aspx',
        },
        {
          label: 'NHS — How to stop breastfeeding',
          url: 'https://www.nhs.uk/baby/breastfeeding-and-bottle-feeding/breastfeeding/how-to-stop/',
        },
        {
          label: 'NHS — Helping your baby to sleep (night feeds)',
          url: 'https://www.nhs.uk/baby/caring-for-a-newborn/helping-your-baby-to-sleep/',
        },
        {
          label: 'NHS — Mastitis',
          url: 'https://www.nhs.uk/conditions/mastitis/',
        },
      ],
    },
  },
  {
    id: 'art_back_to_work_breastfeeding',
    reviewerLabel: 'Nhóm chuyên môn · Tư vấn sữa mẹ (IBCLC)',
    data: {
      library: 'care',
      topic: 'feeding',
      format: 'step_guide',
      ageWeeks: {
        from: 6,
        to: 104,
      },
      readingMinutes: 5,
      cover: null,
      title: {
        vi: 'Đi làm lại mà vẫn cho con bú mẹ: chuẩn bị và duy trì từng bước',
        en: 'Going back to work and keeping breastfeeding: step by step',
      },
      summary: {
        vi: 'Chuẩn bị từ vài tuần trước, tập cho bé bú bình hoặc uống cốc, trữ vừa đủ sữa, hút sữa đều ở chỗ làm, hướng dẫn người chăm cho bú theo nhịp bé, và cho bú nhiều hơn khi ở nhà.',
        en: 'Plan a few weeks ahead, help your baby take a bottle or cup, store just enough milk, pump regularly at work, show carers how to pace feeds, and breastfeed more when you are together.',
      },
      body: {
        vi: [
          {
            type: 'callout',
            tone: 'note',
            title: 'Tóm tắt nhanh',
            text: 'Đi làm lại không có nghĩa là phải thôi cho bú. Chuẩn bị sớm, hút sữa đều khi xa bé và cho bú nhiều hơn khi ở bên bé giúp giữ nguồn sữa.',
          },
          {
            type: 'heading',
            text: 'Bước 1: Lên kế hoạch từ 4–6 tuần trước',
          },
          {
            type: 'bullets',
            items: [
              'Trao đổi với nơi làm việc trước ngày đi làm: một chỗ riêng tư, sạch để hút sữa (không phải nhà vệ sinh), tủ lạnh để trữ sữa, chỗ rửa dụng cụ và giờ nghỉ để hút.',
              'Hỏi về việc đi làm giữa tuần để tuần đầu ngắn hơn, làm bán thời gian một thời gian, hoặc gửi bé gần nơi làm để có thể cho bú giờ nghỉ.',
              'Chọn máy hút phù hợp; máy hút đôi giúp tiết kiệm thời gian. Tập hút hoặc vắt tay ở nhà cho quen.',
              'Chọn người chăm bé và nói trước cách cho bé ăn sữa mẹ. Ở mỗi nước, quyền lợi của mẹ cho con bú khác nhau; hãy tìm hiểu quy định nơi ba mẹ sống.',
            ],
          },
          {
            type: 'paragraph',
            text: 'Ở Việt Nam: theo Bộ luật Lao động 2019, mẹ nuôi con dưới 12 tháng tuổi được nghỉ 60 phút mỗi ngày trong giờ làm việc mà vẫn hưởng đủ lương, và không phải làm đêm, làm thêm giờ hay đi công tác xa nếu mẹ không đồng ý. Thời gian nghỉ thai sản là 6 tháng. Hãy trao đổi với nơi làm để dùng 60 phút này cho việc hút sữa hoặc cho bé bú.',
          },
          {
            type: 'heading',
            text: 'Bước 2: Tập cho bé bú bình hoặc uống cốc',
          },
          {
            type: 'bullets',
            items: [
              'Khi việc bú mẹ đã ổn định, thường sau ít nhất 4 tuần, cho bé thử sữa mẹ vắt bằng bình khoảng 1–2 tuần trước khi đi làm.',
              'Để người khác cho bé bú bình, như ba, bà hay người trông bé; bé thường dễ nhận hơn khi mẹ không ở gần.',
              'Thử khi bé hơi đói chứ chưa đói lả. Nếu bé từ chối, thử lúc khác, đổi tư thế hoặc đổi núm ti chảy chậm.',
              'Cốc nhỏ không nắp cũng là một lựa chọn thay bình; từ 6 tháng thì càng nên tập cho bé uống cốc.',
            ],
          },
          {
            type: 'heading',
            text: 'Bước 3: Trữ một ít sữa, đừng hút quá nhiều',
          },
          {
            type: 'paragraph',
            text: 'Khoảng 2–3 tuần trước khi đi làm, hút thêm một lần mỗi ngày, thường vào buổi sáng sau cữ bú đầu tiên, lúc ngực nhiều sữa. Chỉ cần đủ cho một hai ngày đầu và một ít dự phòng; sau đó, sữa hút ở chỗ làm hôm nay sẽ dùng cho bé ngày mai. Hút quá nhiều có thể làm thừa sữa, căng tức, tắc tia sữa và khiến mẹ thêm mệt.',
          },
          {
            type: 'bullets',
            items: [
              'Trữ mỗi túi khoảng 60–120 ml, bằng một cữ bé ăn, để không phí sữa; ghi ngày và chừa chỗ vì sữa nở khi đông đá.',
              'Rã đông trong ngăn mát và dùng trong 24 giờ; không cấp đông lại sữa đã rã đông. Thời gian trữ chi tiết có trong bài Vắt và trữ sữa mẹ an toàn.',
            ],
          },
          {
            type: 'heading',
            text: 'Bước 4: Hút sữa ở nơi làm việc',
          },
          {
            type: 'bullets',
            items: [
              'Hút vào những giờ bé thường bú ở nhà. Với ngày làm 8 tiếng, thường cần 2–3 lần, ví dụ giữa buổi sáng, giờ trưa và giữa buổi chiều; bé càng nhỏ càng cần hút thường hơn.',
              'Mỗi lần thường 10–15 phút, chưa kể thời gian đi lại và rửa dụng cụ. AAP khuyên hút ít nhất 10 phút ngay cả khi sữa đã chảy chậm, để giữ nguồn sữa.',
              'Rửa tay trước khi hút và rửa sạch dụng cụ sau mỗi lần; nếu không có chỗ rửa, mang thêm bộ phụ kiện để thay.',
              'Cất sữa vào tủ lạnh, hoặc túi giữ lạnh có túi đá đông lạnh; trong túi giữ lạnh như vậy, sữa giữ được đến 24 giờ. Về nhà thì cho vào tủ lạnh hoặc cấp đông. Ghi tên và ngày lên bình.',
              'Nhìn ảnh bé, nghe đoạn ghi âm tiếng bé, thở chậm và xoa nhẹ ngực trước khi hút giúp sữa xuống dễ hơn.',
            ],
          },
          {
            type: 'heading',
            text: 'Bước 5: Hướng dẫn người chăm cho bú bình theo nhịp bé',
          },
          {
            type: 'bullets',
            items: [
              'Cho bé ăn khi bé có dấu hiệu đói như mút tay, quay đầu tìm vú, chứ không cứng nhắc theo đồng hồ hay chờ bé khóc.',
              'Bế bé gần như ngồi thẳng, đỡ đầu; chạm núm ti vào môi trên để bé tự há miệng ngậm, không đẩy núm vào miệng.',
              'Giữ bình gần nằm ngang, chỉ nghiêng đủ để núm ti có sữa, để bé tự điều chỉnh nhịp bú; cho bé nghỉ, ợ hơi giữa chừng và đổi bên tay như khi bú mẹ.',
              'Dừng khi bé có dấu hiệu no: nhả núm, quay đi, mút chậm hay ngủ thiếp. Không ép bé uống hết bình.',
              'Sữa đã hâm hoặc để ở nhiệt độ phòng dùng trong 2 giờ; sữa bé bú dở bỏ đi sau 2 giờ.',
              'Tránh cho bé bú bình sát giờ mẹ về, để bé còn muốn bú mẹ khi gặp mẹ.',
            ],
          },
          {
            type: 'heading',
            text: 'Bước 6: Cho bú nhiều hơn khi ở bên bé',
          },
          {
            type: 'paragraph',
            text: 'Cho bé bú ngay khi đón bé, buổi tối, ban đêm và những ngày nghỉ. Nhiều bé ăn ít khi xa mẹ rồi bú nhiều hơn vào chiều tối và ban đêm; đây gọi là “bú đảo ngược” và là điều bình thường. Khi đó mẹ có thể cần hút ít hơn vào ban ngày. Đặt nôi của bé trong phòng ba mẹ giúp mẹ cho bú đêm đỡ mệt mà vẫn giữ bé ngủ an toàn.',
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'Khi sữa có vẻ ít đi',
            text: 'Lượng sữa hút được hay giảm vào cuối tuần làm việc, thường do bỏ lỡ hoặc rút ngắn lần hút. Hút đủ lần, đủ lâu, cho bú nhiều hơn vào ngày nghỉ, uống đủ nước và nghỉ ngơi thường giúp sữa về lại. Nếu sữa vẫn giảm, hãy gặp chuyên viên tư vấn sữa mẹ.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Khi nào nên đưa bé đi khám',
            text: 'Bé ít tã ướt hơn hẳn, nước tiểu sẫm, môi khô, lừ đừ; bé từ chối cả bình lẫn cốc gần như cả ngày; bé chậm tăng cân. Mẹ nên đi khám khi ngực có vùng sưng, nóng, đỏ, đau kèm sốt, ớn lạnh mà không đỡ sau 12–24 giờ, hoặc khi mẹ buồn bã, lo âu kéo dài. Gọi 115 nếu bé lả, khó đánh thức.',
          },
        ],
        en: [
          {
            type: 'callout',
            tone: 'note',
            title: 'In short',
            text: "Going back to work doesn't mean you have to stop breastfeeding. Planning early, pumping regularly while you are apart and breastfeeding more when you are together help protect your milk supply.",
          },
          {
            type: 'heading',
            text: 'Step 1: Plan 4–6 weeks ahead',
          },
          {
            type: 'bullets',
            items: [
              'Talk to your employer before you go back: a clean, private space to pump (not a toilet), a fridge for milk, somewhere to wash pump parts, and break times to pump.',
              'Ask about starting mid-week so the first week is shorter, working part-time for a while, or using childcare near work so you can breastfeed on breaks.',
              'Choose a suitable pump; a double pump saves time. Practise pumping or hand expressing at home first.',
              "Choose your baby's carer and explain in advance how to feed breast milk. Rights for breastfeeding employees differ by country; check the rules where you live.",
            ],
          },
          {
            type: 'paragraph',
            text: 'In Việt Nam: under the 2019 Labour Code, a mother caring for a child under 12 months is entitled to 60 minutes off each working day with full pay, and cannot be required to work nights, overtime or long-distance business trips unless she agrees. Maternity leave is 6 months. Talk to your employer about using the 60 minutes to pump or to breastfeed your baby.',
          },
          {
            type: 'heading',
            text: 'Step 2: Help your baby take a bottle or cup',
          },
          {
            type: 'bullets',
            items: [
              'Once breastfeeding is going well, usually after at least 4 weeks, offer expressed milk in a bottle about 1–2 weeks before you go back.',
              "Have someone else give the bottle, such as your partner, a grandparent or the carer; babies often accept it more easily when their mother isn't close by.",
              'Try when your baby is a little hungry but not starving. If they refuse, try again another time, change position or try a slow-flow teat.',
              'A small open cup is another option instead of a bottle; from 6 months it is a good time to start cup drinking anyway.',
            ],
          },
          {
            type: 'heading',
            text: "Step 3: Store a little milk, don't over-pump",
          },
          {
            type: 'paragraph',
            text: 'About 2–3 weeks before you go back, add one pumping session a day, usually in the morning after the first feed, when your breasts are fullest. You only need enough for the first day or two plus a little in reserve; after that, milk you pump at work today feeds your baby tomorrow. Pumping too much can cause oversupply, engorgement and blocked ducts, and leaves you more tired.',
          },
          {
            type: 'bullets',
            items: [
              'Store about 60–120 ml per bag, the amount of one feed, to avoid waste; write the date and leave space at the top, as milk expands when frozen.',
              'Thaw milk in the fridge and use it within 24 hours; never refreeze thawed milk. Detailed storage times are in Expressing and storing breast milk safely.',
            ],
          },
          {
            type: 'heading',
            text: 'Step 4: Pumping at work',
          },
          {
            type: 'bullets',
            items: [
              'Pump at the times your baby would usually feed. For an 8-hour day this is often 2–3 times, for example mid-morning, lunchtime and mid-afternoon; the younger your baby, the more often you may need to pump.',
              'Each session usually takes 10–15 minutes, plus time to get there and wash up. The AAP suggests pumping for at least 10 minutes even after the flow slows, to protect your supply.',
              'Wash your hands before pumping and clean the parts after each use; if there is no sink, bring spare sets.',
              'Keep milk in a fridge, or in an insulated cool bag with frozen ice packs, where it keeps for up to 24 hours. At home, put it in the fridge or freezer. Label it with your name and the date.',
              'Looking at a photo of your baby, listening to a recording of them, breathing slowly and gently massaging your breasts before pumping can help your milk flow.',
            ],
          },
          {
            type: 'heading',
            text: 'Step 5: Show carers how to pace bottle feeds',
          },
          {
            type: 'bullets',
            items: [
              'Feed when your baby shows hunger cues such as sucking their hands or turning to root, rather than strictly by the clock or waiting for crying.',
              'Hold your baby fairly upright with their head supported; touch the teat to the upper lip so they open wide and take it, rather than pushing it in.',
              'Keep the bottle close to horizontal, tilted just enough to fill the teat, so your baby controls the pace; allow pauses and burps, and switch sides as with breastfeeding.',
              'Stop when your baby shows they are full: letting go of the teat, turning away, sucking slowly or falling asleep. Never push them to finish the bottle.',
              'Use warmed or room-temperature milk within 2 hours; throw away leftover milk from a feed after 2 hours.',
              'Avoid giving a bottle just before you get home, so your baby is keen to breastfeed when you arrive.',
            ],
          },
          {
            type: 'heading',
            text: 'Step 6: Breastfeed more when you are together',
          },
          {
            type: 'paragraph',
            text: "Breastfeed as soon as you pick your baby up, in the evening, at night and on days off. Many babies eat less while apart and feed more in the evening and at night; this is called “reverse cycling” and is normal. If it happens, you may need to pump less during the day. Keeping your baby's cot in your room makes night feeds less tiring while keeping sleep safe.",
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'If your supply seems to drop',
            text: 'Pumped amounts often dip towards the end of the working week, usually because sessions were missed or cut short. Pumping often enough and for long enough, breastfeeding more on days off, drinking enough and resting usually bring it back. If it keeps falling, see a lactation consultant.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'When to see a doctor',
            text: "Your baby has far fewer wet nappies, dark urine, a dry mouth or is listless; refuses both bottle and cup for most of the day; or is gaining weight slowly. See a doctor yourself if a swollen, hot, red, painful area of the breast with fever or chills isn't better after 12–24 hours, or if low mood or anxiety lasts. Call 115 (Việt Nam) or local emergency services if your baby is floppy or hard to wake.",
          },
        ],
      },
      keywords: {
        vi: [
          'đi làm lại',
          'hút sữa',
          'hút sữa ở công ty',
          'trữ sữa',
          'bú bình theo nhịp',
          'bú đảo ngược',
          'nghỉ cho con bú',
          'giữ nguồn sữa',
        ],
        en: [
          'back to work',
          'pumping',
          'pumping at work',
          'storing milk',
          'paced bottle feeding',
          'reverse cycling',
          'breastfeeding breaks',
          'milk supply',
        ],
      },
      relatedArticleIds: [
        'art_expressing_storing_milk',
        'art_breastfeeding_start',
        'art_night_weaning',
        'art_parent_wellbeing',
      ],
      milestoneIds: [],
      sources: [
        {
          label: "Office on Women's Health (US HHS) — Breastfeeding and going back to work",
          url: 'https://womenshealth.gov/breastfeeding/breastfeeding-home-work-and-public/breastfeeding-and-going-back-work',
        },
        {
          label: 'CDC — Breastfeeding and returning to your workplace',
          url: 'https://www.cdc.gov/infant-toddler-nutrition/breastfeeding/returning-to-your-workplace.html',
        },
        {
          label:
            'HealthyChildren.org (AAP) — Expressing breast milk at work: tips for nursing parents',
          url: 'https://www.healthychildren.org/English/ages-stages/baby/breastfeeding/Pages/Expressing-Breastmilk-on-the-Job.aspx',
        },
        {
          label: 'CDC — Breast milk storage and preparation',
          url: 'https://www.cdc.gov/breastfeeding/breast-milk-preparation-and-storage/handling-breastmilk.html',
        },
        {
          label:
            "Alder Hey Children's NHS Foundation Trust — Paced responsive feeding (bottle feeding)",
          url: 'https://www.alderhey.nhs.uk/conditions/patient-information-leaflets/paced-responsive-feeding-bottle-feeding/',
        },
        {
          label: 'Cổng PBGDPL TP. Cần Thơ — Bộ luật Lao động số 45/2019/QH14 (Điều 137, Điều 139)',
          url: 'https://pbgdpl.cantho.gov.vn/attachment/261',
        },
      ],
    },
  },
  {
    id: 'art_pacifier_bottle_habits',
    reviewerLabel: 'Nhóm chuyên môn · Nhi khoa',
    data: {
      library: 'care',
      topic: 'daily_care',
      format: 'quick_qa',
      ageWeeks: {
        from: 26,
        to: 156,
      },
      readingMinutes: 2,
      cover: null,
      title: {
        vi: 'Hỏi nhanh: Cai ti giả và bình sữa — khi nào, cách nào?',
        en: 'Quick Q&A: Giving up the dummy and the bottle — when and how?',
      },
      summary: {
        vi: 'Tập uống cốc từ 6 tháng, bỏ bình quanh 1 tuổi, không ngậm bình đi ngủ, và thu hẹp dần ti giả sau 1 tuổi để bảo vệ răng và tai của bé.',
        en: "Start cup drinking from 6 months, phase out the bottle around age 1, no bottle in bed, and gradually limit the dummy after age 1 to protect your child's teeth and ears.",
      },
      body: {
        vi: [
          {
            type: 'callout',
            tone: 'note',
            title: 'Tóm tắt nhanh',
            text: 'Ti giả và bình sữa giúp bé dễ chịu, nhưng dùng lâu có thể ảnh hưởng răng và tai. Tập cốc từ 6 tháng, bỏ bình quanh 1 tuổi, và sau 1 tuổi chỉ dùng ti giả khi ngủ.',
          },
          {
            type: 'heading',
            text: 'Khi nào nên bỏ bình sữa?',
          },
          {
            type: 'paragraph',
            text: 'NHS khuyên không cho bé bú bình nữa từ 1 tuổi; AAP khuyên giảm dần và bỏ hẳn trong khoảng 12–18 tháng. Child Life theo cách thận trọng hơn: bắt đầu bớt bình quanh 1 tuổi và cố gắng bỏ hẳn trước 18 tháng.',
          },
          {
            type: 'heading',
            text: 'Bỏ bình thế nào cho nhẹ nhàng?',
          },
          {
            type: 'paragraph',
            text: 'Bỏ các cữ bình giữa ngày trước, cữ trước khi ngủ sau cùng. Cho bé uống sữa bằng cốc trong bữa ăn. Thay bình lúc đi ngủ bằng ôm ấp, đọc truyện, hát ru. Mọi người chăm bé cùng làm giống nhau.',
          },
          {
            type: 'heading',
            text: 'Tập uống cốc từ khi nào?',
          },
          {
            type: 'paragraph',
            text: 'Từ khoảng 6 tháng, cho bé uống vài ngụm nước bằng cốc không nắp hoặc cốc không van trong bữa ăn. Cốc có van khiến bé vẫn mút như bú bình; cốc mở tốt hơn cho răng. Đổ vương một chút là bình thường.',
          },
          {
            type: 'heading',
            text: 'Ngậm bình đi ngủ có hại gì?',
          },
          {
            type: 'paragraph',
            text: 'Sữa hay nước ngọt đọng quanh răng suốt đêm dễ gây sâu răng sớm. Bú bình khi nằm cũng làm tăng nguy cơ viêm tai. Hãy cho bé uống xong, đánh răng, rồi mới đặt bé ngủ. Không cho đồ uống có đường vào bình.',
          },
          {
            type: 'heading',
            text: 'Ti giả dùng đến bao giờ?',
          },
          {
            type: 'paragraph',
            text: 'Dưới 1 tuổi, cho bé ngậm ti giả khi ngủ có thể giảm nguy cơ đột tử, nên không cần vội bỏ. AAP cho biết mút mạnh kéo dài quá khoảng 2–4 tuổi có thể làm lệch răng; Hội Nhi khoa Canada khuyên bỏ trước 3–4 tuổi và lưu ý ti giả có thể làm bé hay bị viêm tai. Child Life theo cách thận trọng hơn: sau 1 tuổi chỉ dùng khi ngủ, cố gắng bỏ quanh 2 tuổi, sớm hơn nếu bé hay viêm tai.',
          },
          {
            type: 'heading',
            text: 'Cai ti giả thế nào?',
          },
          {
            type: 'paragraph',
            text: 'Giới hạn dần, chỉ dùng ở chỗ ngủ. Khen khi bé không cần ti, dùng bảng dán sao, cho bé tự “tạm biệt” ti. Không quát mắng, chê cười, không bôi ớt hay dầu gió. Không nhúng ti vào đường, mật ong, không buộc dây quanh cổ bé.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Khi nào nên đưa bé đi khám',
            text: 'Răng có đốm trắng đục, vệt nâu hoặc lỗ sâu; răng cửa hô, khớp cắn lệch; bé hay đau tai, kéo tai, sốt hoặc chảy dịch tai; bé gần 2 tuổi vẫn bú bình nhiều mà ăn ít, xanh xao.',
          },
        ],
        en: [
          {
            type: 'callout',
            tone: 'note',
            title: 'In short',
            text: 'Dummies and bottles comfort children, but long use can affect teeth and ears. Start a cup from 6 months, phase out the bottle around age 1, and after age 1 keep the dummy for sleep only.',
          },
          {
            type: 'heading',
            text: 'When should the bottle go?',
          },
          {
            type: 'paragraph',
            text: 'The NHS advises discouraging bottle feeding from age 1; the AAP advises cutting down gradually and finishing between 12 and 18 months. Child Life follows the more cautious advice: start cutting down around age 1 and aim to stop completely before 18 months.',
          },
          {
            type: 'heading',
            text: 'How do I phase out the bottle gently?',
          },
          {
            type: 'paragraph',
            text: 'Drop the daytime bottles first and the bedtime bottle last. Offer milk in a cup at meals. Replace the bedtime bottle with cuddles, a story and a lullaby. Make sure every carer does the same.',
          },
          {
            type: 'heading',
            text: 'When should cup drinking start?',
          },
          {
            type: 'paragraph',
            text: 'From around 6 months, offer sips of water from an open cup or a free-flow cup without a valve at meals. Valved cups keep children sucking like a bottle; open cups are better for teeth. A little spilling is normal.',
          },
          {
            type: 'heading',
            text: "What's wrong with a bottle in bed?",
          },
          {
            type: 'paragraph',
            text: 'Milk or sweet drinks pooling around the teeth all night can cause early tooth decay. Bottle feeding while lying down also raises the risk of ear infections. Finish the drink, brush teeth, then lay your child down. Never put sugary drinks in a bottle.',
          },
          {
            type: 'heading',
            text: 'How long can a dummy be used?',
          },
          {
            type: 'paragraph',
            text: 'Under 1 year, a dummy at sleep time may lower the risk of SIDS, so there is no rush to stop. The AAP says strong sucking beyond about 2–4 years can affect tooth alignment; the Canadian Paediatric Society advises stopping by 3–4 years and notes dummies may lead to repeated ear infections. Child Life follows the more cautious advice: after age 1 use it for sleep only, aim to stop around 2, sooner if your child gets frequent ear infections.',
          },
          {
            type: 'heading',
            text: 'How do I wean off the dummy?',
          },
          {
            type: 'paragraph',
            text: "Limit it gradually to the sleep space. Praise your child when they manage without it, use a sticker chart, and let them say “bye-bye” to it. Don't scold or tease, and don't put chilli or menthol oil on it. Never dip it in sugar or honey or tie it around their neck.",
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'When to see a doctor',
            text: 'Chalky white spots, brown marks or holes on the teeth; front teeth sticking out or a misaligned bite; frequent ear pain, ear pulling, fever or ear discharge; or a child nearing 2 who still drinks a lot from bottles, eats little and looks pale.',
          },
        ],
      },
      keywords: {
        vi: [
          'ti giả',
          'núm vú giả',
          'cai bình',
          'uống cốc',
          'sâu răng',
          'viêm tai',
          'ngậm bình đi ngủ',
        ],
        en: [
          'dummy',
          'pacifier',
          'stopping the bottle',
          'cup drinking',
          'tooth decay',
          'ear infections',
          'bottle in bed',
        ],
      },
      relatedArticleIds: [
        'art_teething',
        'art_toddler_milk',
        'art_night_weaning',
        'art_water_juice',
      ],
      milestoneIds: [],
      sources: [
        {
          label:
            'HealthyChildren.org (AAP) — From bottle to cup: helping your child make a healthy transition',
          url: 'https://www.healthychildren.org/English/ages-stages/baby/feeding-nutrition/Pages/Discontinuing-the-Bottle.aspx',
        },
        {
          label:
            'HealthyChildren.org (AAP) — Baby pacifiers and thumb sucking: what parents need to know',
          url: 'https://www.healthychildren.org/English/ages-stages/baby/crying-colic/Pages/Pacifiers-and-Thumb-Sucking.aspx',
        },
        {
          label: 'Canadian Paediatric Society (Caring for Kids) — Pacifiers (soothers)',
          url: 'https://caringforkids.cps.ca/handouts/pregnancy-and-babies/pacifiers',
        },
        {
          label: 'Canadian Paediatric Society (Caring for Kids) — Ear infections',
          url: 'https://caringforkids.cps.ca/handouts/health-conditions-and-treatments/ear_infections',
        },
        {
          label: 'NHS — Drinks and cups for babies and young children',
          url: 'https://www.nhs.uk/baby/weaning-and-feeding/drinks-and-cups-for-babies-and-young-children/',
        },
      ],
    },
  },
  {
    id: 'art_dengue_mosquito',
    reviewerLabel: 'Nhóm chuyên môn · Nhi khoa',
    data: {
      library: 'care',
      topic: 'illness',
      format: 'article',
      ageWeeks: {
        from: 0,
        to: 156,
      },
      readingMinutes: 7,
      cover: null,
      title: {
        vi: 'Sốt xuất huyết ở trẻ nhỏ: dấu hiệu nguy hiểm và cách phòng muỗi cho bé',
        en: 'Dengue in babies and toddlers: warning signs and protecting your child from mosquitoes',
      },
      summary: {
        vi: 'Sốt xuất huyết do muỗi vằn truyền, hay gặp ở Việt Nam và Đông Nam Á. Giai đoạn nguy hiểm thường đến khi bé vừa hạ sốt. Cho bé bú, uống đủ, chỉ dùng paracetamol, và chống muỗi đốt cả ngày lẫn đêm.',
        en: 'Dengue is spread by Aedes mosquitoes and is common in Việt Nam and South-East Asia. The dangerous phase often comes as the fever falls. Keep your child drinking, use only paracetamol, and prevent bites day and night.',
      },
      body: {
        vi: [
          {
            type: 'callout',
            tone: 'note',
            title: 'Tóm tắt nhanh',
            text: 'Sốt xuất huyết là bệnh do virus dengue, lây qua muỗi vằn đốt, hay gặp ở Việt Nam và nhiều nước Đông Nam Á. Bệnh thường gây sốt cao 2–7 ngày; giai đoạn nguy hiểm hay đến đúng lúc bé bắt đầu hạ sốt. Cho bé bú, uống đủ, chỉ hạ sốt bằng paracetamol, không tự dùng ibuprofen hay aspirin, và đưa bé đi khám ngay khi có dấu hiệu cảnh báo.',
          },
          {
            type: 'heading',
            text: 'Vì sao gia đình ở Việt Nam và Đông Nam Á cần biết',
          },
          {
            type: 'paragraph',
            text: 'Virus dengue do muỗi vằn (muỗi Aedes) truyền. Loại muỗi này đẻ trứng ở chỗ nước đọng quanh nhà và đốt cả ban ngày lẫn ban đêm. Bệnh có ở hầu hết các tỉnh thành Việt Nam và phổ biến ở Thái Lan, Singapore, Malaysia, Indonesia, Philippines. Gia đình ở nước ngoài đưa bé về thăm quê hay du lịch trong vùng cũng cần phòng bệnh như người sống tại chỗ.',
          },
          {
            type: 'paragraph',
            text: 'Hiện chưa có thuốc đặc trị sốt xuất huyết. Phần lớn người bệnh khỏi sau 1–2 tuần, nhưng một số chuyển nặng với thoát huyết tương, sốc hoặc chảy máu. Bé nhỏ chưa nói được mình đau ở đâu, nên ba mẹ cần nhìn vào cách bé bú, chơi và tỉnh táo ra sao.',
          },
          {
            type: 'heading',
            text: 'Ba giai đoạn của bệnh',
          },
          {
            type: 'bullets',
            items: [
              'Giai đoạn sốt (thường 2–7 ngày): sốt cao đột ngột, bé quấy, bỏ bú hoặc biếng ăn, có thể nôn, nổi ban, có chấm đỏ dưới da hoặc chảy máu cam nhẹ. Trẻ nhỏ thường không kể được đau đầu, đau mỏi người như người lớn.',
              'Giai đoạn nguy hiểm (bắt đầu khi sốt lui, thường kéo dài 24–48 giờ): nhiều bé khỏe dần, nhưng ở một số bé, huyết tương thoát ra khỏi lòng mạch và bệnh có thể nặng lên rất nhanh, chỉ trong vài giờ. Vì vậy hết sốt chưa có nghĩa là đã khỏi.',
              'Giai đoạn hồi phục: bé ăn ngon hơn, tiểu nhiều hơn, tỉnh táo hơn. Một số bé nổi ban ngứa hoặc bong da nhẹ. Vẫn cần tái khám theo hẹn.',
            ],
          },
          {
            type: 'heading',
            text: 'Dấu hiệu cảnh báo: đưa bé đến viện ngay',
          },
          {
            type: 'paragraph',
            text: 'Theo WHO, CDC (Mỹ) và Bệnh viện Nhi Trung ương, những dấu hiệu dưới đây cần được khám ngay, nhất là khi bé vừa hạ sốt:',
          },
          {
            type: 'bullets',
            items: [
              'Đau bụng: bé ôm bụng, co chân, khóc khi chạm vào bụng.',
              'Nôn nhiều lần (CDC lấy mốc từ 3 lần trong 24 giờ), nôn liên tục, hoặc không bú, không uống được.',
              'Chảy máu chân răng, chảy máu cam, nôn ra máu, đi ngoài phân đen hoặc có máu, nhiều chấm xuất huyết mới trên da.',
              'Bé lừ đừ, li bì, khó đánh thức, hoặc ngược lại vật vã, bứt rứt, quấy khóc khác thường.',
              'Tay chân lạnh, da xanh tái hoặc nổi vân, vã mồ hôi.',
              'Tiểu ít: số tã ướt ít hẳn so với mọi ngày.',
              'Thở nhanh, thở mệt.',
            ],
          },
          {
            type: 'heading',
            text: 'Chăm bé tại nhà khi bác sĩ cho theo dõi ở nhà',
          },
          {
            type: 'bullets',
            items: [
              'Cho bé bú mẹ hoặc bú sữa thường xuyên hơn. Bé đã ăn dặm có thể uống thêm nước lọc hoặc oresol pha đúng hướng dẫn trên gói, chia nhiều lần, từng ngụm nhỏ.',
              'Theo dõi cữ bú, số tã ướt, nhiệt độ và các dấu hiệu cảnh báo mỗi vài giờ, cả ban đêm. Ghi lại để đưa bác sĩ xem (có thể ghi trong Child Life).',
              'Ở Việt Nam: Bệnh viện Nhi Trung ương khuyên tránh nước có ga và đồ ăn, đồ uống màu đỏ hoặc nâu đen, để ba mẹ dễ nhận ra nếu bé nôn ra máu hay đi ngoài phân đen.',
              'Đi khám lại đúng hẹn, kể cả khi bé đã hết sốt; bác sĩ thường cho xét nghiệm máu nhiều lần để theo dõi.',
              'Cho bé nằm màn cả ngày lẫn đêm khi đang ốm, để muỗi không đốt bé rồi truyền bệnh sang người khác trong nhà.',
            ],
          },
          {
            type: 'heading',
            text: 'Thuốc: chỉ paracetamol, không tự điều trị',
          },
          {
            type: 'paragraph',
            text: 'WHO khuyên dùng paracetamol để giảm đau, hạ sốt và tránh ibuprofen, aspirin vì chúng làm tăng nguy cơ chảy máu. Bệnh viện Nhi Trung ương cũng nhấn mạnh không dùng ibuprofen hạ sốt cho trẻ bị sốt xuất huyết. Aspirin không bao giờ dùng cho trẻ dưới 16 tuổi. Hỏi bác sĩ hoặc dược sĩ liều paracetamol theo cân nặng và khoảng cách giữa các lần.',
          },
          {
            type: 'bullets',
            items: [
              'Không tự cho bé uống kháng sinh: sốt xuất huyết do virus, kháng sinh không có tác dụng.',
              'Không tự truyền dịch, tiêm thuốc cho bé ở nhà hay ở nơi không đủ điều kiện theo dõi; bù dịch qua đường truyền phải do bác sĩ tính toán và theo dõi sát.',
              'Không dùng thuốc không rõ nguồn gốc, thuốc nam, thuốc bắc, và không cạo gió cho bé; những cách này không chữa được bệnh và có thể làm chậm việc đi khám.',
            ],
          },
          {
            type: 'heading',
            text: 'Phòng muỗi đốt cho bé',
          },
          {
            type: 'paragraph',
            text: 'Cách bảo vệ bé tốt nhất là không để muỗi chạm vào da bé và không cho muỗi có chỗ đẻ trứng. Với bé nhỏ, màn, quần áo và lưới chắn là lớp bảo vệ chính.',
          },
          {
            type: 'bullets',
            items: [
              'Cho bé ngủ màn cả giấc ngày lẫn giấc đêm. Phủ màn hoặc lưới chống muỗi lên nôi, xe đẩy và địu khi ra ngoài.',
              'Mặc cho bé áo dài tay, quần dài, tất mỏng bằng vải thoáng mát, để bé được che kín mà không bị nóng.',
              'Lắp lưới chống muỗi ở cửa sổ, cửa ra vào; đóng cửa không có lưới vào lúc nhiều muỗi.',
              'Mỗi tuần dành khoảng 10 phút diệt lăng quăng: đậy kín lu, khạp, bể chứa nước; thay nước bình hoa; lật úp chậu, xô; dọn chai lọ, vỏ dừa, lốp xe cũ và rác có thể đọng nước.',
            ],
          },
          {
            type: 'heading',
            text: 'Thuốc chống muỗi bôi da: dùng từ khi nào?',
          },
          {
            type: 'paragraph',
            text: 'Các cơ quan y tế không hoàn toàn giống nhau. Theo CDC (Mỹ), thuốc chống muỗi chứa DEET, picaridin hoặc IR3535 dùng được cho trẻ không giới hạn tuổi; sản phẩm chứa dầu khuynh diệp chanh (OLE) hoặc PMD không dùng cho trẻ dưới 3 tuổi. WHO cũng khuyên dùng DEET, picaridin hoặc IR3535. Bang Victoria (Úc) thận trọng hơn: bé dưới 12 tháng nên ở trong nhà khi nhiều muỗi, mặc đồ dài, dùng màn. Child Life theo cách thận trọng: trong năm đầu, bé dựa chủ yếu vào màn và quần áo, chỉ bôi thuốc chống muỗi khi thật cần.',
          },
          {
            type: 'bullets',
            items: [
              'Chọn sản phẩm có nhãn ghi rõ dùng được cho tuổi của bé; hỏi bác sĩ hoặc dược sĩ nếu bé còn nhỏ hoặc da nhạy cảm.',
              'Người lớn bôi vào tay mình rồi xoa nhẹ lên vùng da hở của bé. Không bôi lên tay bé (bé hay mút tay, dụi mắt), quanh mắt, miệng, vết xước hay chỗ da đang kích ứng.',
              'Chỉ bôi vừa đủ lên da hở hoặc mặt ngoài quần áo. Không dùng loại kết hợp kem chống nắng với chống muỗi.',
              'Khi vào nhà, rửa sạch chỗ da đã bôi bằng xà phòng và nước.',
              'Không để bé tự cầm, tự xịt thuốc chống muỗi; cất xa tầm tay trẻ. Permethrin chỉ dùng để tẩm quần áo, màn, không bôi lên da.',
            ],
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'Mẹo nhỏ',
            text: 'Đặt nhắc việc hằng tuần để cả nhà cùng đi một vòng đổ nước đọng: đĩa lót chậu cây, khay hứng nước, xô chậu, đồ chơi ngoài sân. Không có lăng quăng thì không có sốt xuất huyết.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Gọi 115 hoặc đến cấp cứu ngay khi',
            text: 'Bé li bì, khó đánh thức hoặc vật vã, bứt rứt; tay chân lạnh, da tái hoặc nổi vân; đau bụng nhiều; nôn liên tục, không bú, không uống được; chảy máu chân răng, chảy máu cam, nôn ra máu, đi ngoài phân đen; tiểu rất ít; thở nhanh, thở mệt; co giật. Những dấu hiệu này hay xuất hiện khi bé vừa hạ sốt. Đừng chờ, gọi 115 ngay.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Đưa bé đi khám trong ngày khi',
            text: 'Bé sốt cao từ ngày thứ 2 khi đang ở vùng có sốt xuất huyết hoặc vừa đi về từ vùng có dịch; có chấm đỏ, ban dưới da; bú kém, ít tã ướt; hoặc ba mẹ thấy lo. Bé dưới 3 tháng sốt từ 38 °C cần được khám ngay. Nếu bác sĩ đã cho theo dõi tại nhà, đi khám lại đúng hẹn kể cả khi bé đã hết sốt.',
          },
        ],
        en: [
          {
            type: 'callout',
            tone: 'note',
            title: 'In short',
            text: 'Dengue is a viral illness spread by Aedes mosquito bites, common in Việt Nam and many South-East Asian countries. It usually causes a high fever for 2–7 days; the dangerous phase often comes just as the fever starts to fall. Keep your child feeding and drinking, use only paracetamol for fever, never ibuprofen or aspirin on your own, and get medical help straight away if any warning sign appears.',
          },
          {
            type: 'heading',
            text: 'Why families in Việt Nam and South-East Asia need to know',
          },
          {
            type: 'paragraph',
            text: 'The dengue virus is spread by Aedes mosquitoes, which breed in standing water around the home and bite during the day as well as at night. Dengue is found in almost every province of Việt Nam and is common in Thailand, Singapore, Malaysia, Indonesia and the Philippines. Families living abroad who take their child home or travel in the region need the same protection as people who live there.',
          },
          {
            type: 'paragraph',
            text: "There is no specific medicine that cures dengue. Most people recover within 1–2 weeks, but some develop severe dengue with plasma leakage, shock or bleeding. Young children can't tell you where it hurts, so watch how your child feeds, plays and stays alert.",
          },
          {
            type: 'heading',
            text: 'The three phases of dengue',
          },
          {
            type: 'bullets',
            items: [
              "Fever phase (usually 2–7 days): a sudden high fever, fussiness, poor feeding or eating, sometimes vomiting, a rash, tiny red spots under the skin or a mild nosebleed. Young children usually can't describe a headache or body aches the way adults do.",
              'Critical phase (starts as the fever falls, usually lasts 24–48 hours): many children get better, but in some, plasma leaks out of the blood vessels and the illness can become severe very quickly, within hours. So no fever does not yet mean recovered.',
              'Recovery phase: your child eats better, passes more urine and is more alert. Some get an itchy rash or mild peeling. Keep any follow-up appointments.',
            ],
          },
          {
            type: 'heading',
            text: 'Warning signs: take your child to hospital now',
          },
          {
            type: 'paragraph',
            text: "According to WHO, the CDC (US) and Vietnam National Children's Hospital, the signs below need to be checked straight away, especially just after the fever has come down:",
          },
          {
            type: 'bullets',
            items: [
              'Tummy pain: your child holds their tummy, pulls up their legs or cries when it is touched.',
              'Repeated vomiting (the CDC uses 3 or more times in 24 hours), constant vomiting, or not feeding or drinking at all.',
              'Bleeding gums, a nosebleed, vomiting blood, black or bloody poo, or many new tiny bleeding spots on the skin.',
              'Your child is listless, very drowsy or hard to wake, or the opposite: agitated, restless or crying in an unusual way.',
              'Cold hands and feet, pale or blotchy skin, cold sweats.',
              'Passing little urine: far fewer wet diapers than usual.',
              'Fast or laboured breathing.',
            ],
          },
          {
            type: 'heading',
            text: 'Caring for your child at home when the doctor says it is safe',
          },
          {
            type: 'bullets',
            items: [
              'Offer breast or formula feeds more often. Babies on solids can also have water or oral rehydration solution made up exactly as the packet says, in small sips, often.',
              'Every few hours, including at night, check feeds, wet diapers, temperature and the warning signs. Write them down for the doctor (you can log them in Child Life).',
              "In Việt Nam: Vietnam National Children's Hospital advises avoiding fizzy drinks and red or dark brown foods and drinks, so it is easier to spot vomited blood or black poo.",
              'Go back to every follow-up appointment, even once the fever has gone; doctors often repeat blood tests to track the illness.',
              "Keep your sick child under a net day and night, so mosquitoes can't bite them and pass the virus to others at home.",
            ],
          },
          {
            type: 'heading',
            text: 'Medicines: paracetamol only, no self-treatment',
          },
          {
            type: 'paragraph',
            text: "WHO advises paracetamol for pain and fever and avoiding ibuprofen and aspirin, because they increase the risk of bleeding. Vietnam National Children's Hospital also stresses never using ibuprofen for fever in a child with dengue. Aspirin is never given to anyone under 16. Ask a doctor or pharmacist for the paracetamol dose for your child's weight and how far apart doses should be.",
          },
          {
            type: 'bullets',
            items: [
              "Don't give antibiotics on your own: dengue is caused by a virus, and antibiotics don't work against it.",
              "Don't arrange drips or injections at home or anywhere without proper monitoring; fluids through a drip must be worked out and closely monitored by a doctor.",
              "Don't use medicines of unknown origin or herbal remedies, and don't do coin rubbing (cạo gió); these don't treat dengue and can delay getting care.",
            ],
          },
          {
            type: 'heading',
            text: 'Protecting your child from mosquito bites',
          },
          {
            type: 'paragraph',
            text: "The best protection is to keep mosquitoes off your child's skin and give them nowhere to breed. For young babies, nets, clothing and screens are the main line of defence.",
          },
          {
            type: 'bullets',
            items: [
              'Use a net for daytime naps as well as at night. Cover the cot, stroller and baby carrier with mosquito netting when you are out.',
              'Dress your child in long sleeves, long trousers and thin socks made of breathable fabric, so they are covered without overheating.',
              'Fit screens on windows and doors; keep unscreened doors closed when mosquitoes are around.',
              'Spend about 10 minutes each week getting rid of mosquito larvae: cover water jars and tanks, change the water in vases, turn buckets and basins upside down, and clear away bottles, coconut shells, old tyres and rubbish that can hold water.',
            ],
          },
          {
            type: 'heading',
            text: 'Repellents on the skin: from what age?',
          },
          {
            type: 'paragraph',
            text: 'Health bodies do not fully agree. The CDC (US) says repellents containing DEET, picaridin or IR3535 can be used on children with no age restriction, while products with oil of lemon eucalyptus (OLE) or PMD should not be used under 3 years. WHO also recommends DEET, picaridin or IR3535. Victoria (Australia) is more cautious: babies under 12 months should stay indoors when mosquitoes are active, wear long clothing and use nets. Child Life follows the cautious approach: in the first year, babies rely mainly on nets and clothing, with repellent only when really needed.',
          },
          {
            type: 'bullets',
            items: [
              "Choose a product labelled as suitable for your child's age; ask a doctor or pharmacist if your baby is very young or has sensitive skin.",
              "Put the repellent on your own hands first, then gently spread it on your child's exposed skin. Don't put it on their hands (they suck their hands and rub their eyes), around the eyes or mouth, or on cuts or irritated skin.",
              "Use just enough to cover exposed skin or the outside of clothing. Don't use combined sunscreen and repellent products.",
              'When you come indoors, wash the treated skin with soap and water.',
              'Never let your child hold or spray repellent; store it out of reach. Permethrin is only for treating clothes and nets, never for the skin.',
            ],
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'Tip',
            text: 'Set a weekly reminder for the whole family to walk around the home and tip out standing water: plant saucers, drip trays, buckets and outdoor toys. No larvae, no dengue.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Call 115 (Việt Nam) or local emergency services now if',
            text: "Your child is listless, hard to wake, agitated or restless; has cold hands and feet, pale or blotchy skin; bad tummy pain; keeps vomiting or can't feed or drink; bleeding gums, a nosebleed, vomits blood or has black poo; passes very little urine; breathes fast or with effort; or has a fit. These signs often appear just as the fever falls. Don't wait: call emergency services.",
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'See a doctor the same day if',
            text: 'Your child has had a high fever from day 2 while in an area with dengue, or has just come back from one; has red spots or a rash under the skin; feeds poorly or has fewer wet diapers; or you are worried. A baby under 3 months with 38 °C or more must be seen straight away. If the doctor has said to watch at home, go back as arranged even if the fever has gone.',
          },
        ],
      },
      keywords: {
        vi: [
          'sốt xuất huyết',
          'dengue',
          'muỗi vằn',
          'chống muỗi',
          'ngủ màn',
          'diệt lăng quăng',
          'paracetamol',
          'dấu hiệu cảnh báo',
        ],
        en: [
          'dengue',
          'dengue fever',
          'Aedes mosquito',
          'insect repellent',
          'mosquito net',
          'standing water',
          'paracetamol',
          'warning signs',
        ],
      },
      relatedArticleIds: [
        'art_fever_when_to_call',
        'art_medicine_safety',
        'art_diarrhoea_dehydration',
        'art_heat_cold_safety',
      ],
      milestoneIds: [],
      sources: [
        {
          label: 'WHO — Dengue and severe dengue (fact sheet)',
          url: 'https://www.who.int/news-room/fact-sheets/detail/dengue-and-severe-dengue',
        },
        {
          label: 'CDC — Clinical signs and symptoms of dengue',
          url: 'https://www.cdc.gov/dengue/hcp/clinical-signs/index.html',
        },
        {
          label: 'CDC — Preventing mosquito bites',
          url: 'https://www.cdc.gov/mosquitoes/prevention/index.html',
        },
        {
          label:
            'CDC Yellow Book — Mosquitoes, ticks and other arthropods (repellents and children)',
          url: 'https://www.cdc.gov/yellow-book/hcp/environmental-hazards-risks/mosquitoes-ticks-and-other-arthropods.html',
        },
        {
          label: 'Victoria State Government (Australia) — Insect repellent',
          url: 'https://www.vic.gov.au/insect-repellent',
        },
        {
          label: 'Bệnh viện Nhi Trung ương — Chăm sóc trẻ bị sốt xuất huyết tại nhà',
          url: 'https://benhviennhitrunguong.gov.vn/cham-soc-tre-bi-sot-xuat-huyet-tai-nha.html',
        },
      ],
    },
  },
  {
    id: 'art_thrush_cradle_cap',
    reviewerLabel: 'Nhóm chuyên môn · Nhi khoa',
    data: {
      library: 'care',
      topic: 'illness',
      format: 'article',
      ageWeeks: {
        from: 0,
        to: 26,
      },
      readingMinutes: 6,
      cover: null,
      title: {
        vi: 'Tưa lưỡi và cứt trâu ở bé: phân biệt, chăm sóc và khi nào cần khám',
        en: 'Oral thrush and cradle cap: how to tell, how to care, when to see a doctor',
      },
      summary: {
        vi: 'Tưa lưỡi là nấm miệng, cần bác sĩ khám và kê thuốc; mẹ đang cho bú có thể cần chữa cùng lúc. Cứt trâu thường vô hại và tự hết: làm mềm vảy, gội nhẹ, chải mềm, không cạy.',
        en: "Oral thrush is a yeast infection that needs a doctor to examine and prescribe; a breastfeeding mother may need treating too. Cradle cap is harmless and clears by itself: soften, wash gently, brush softly, don't pick.",
      },
      body: {
        vi: [
          {
            type: 'callout',
            tone: 'note',
            title: 'Tóm tắt nhanh',
            text: 'Tưa lưỡi (nấm miệng) là những mảng trắng trong miệng bé, không lau đi được như cặn sữa. Bệnh do nấm Candida, cần bác sĩ khám và kê thuốc; nếu mẹ đang cho bú, cả mẹ và bé thường cần chữa cùng lúc. Cứt trâu (viêm da tiết bã) là vảy vàng, nhờn trên da đầu, vô hại và thường tự hết: làm mềm, gội nhẹ, chải mềm, không cạy.',
          },
          {
            type: 'heading',
            text: 'Tưa lưỡi là gì?',
          },
          {
            type: 'paragraph',
            text: 'Nấm Candida vốn sống sẵn trong miệng. Khi niêm mạc miệng bị kích ứng hay trầy xước, nấm có thể phát triển quá mức và gây tưa. Bé nhỏ, bé ngậm núm vú giả hay núm bình lâu, hoặc vừa dùng kháng sinh dễ bị hơn. Tưa lưỡi hay gặp và thường không nguy hiểm, nhưng có thể làm bé khó chịu, quấy và bú kém.',
          },
          {
            type: 'heading',
            text: 'Tưa lưỡi hay cặn sữa?',
          },
          {
            type: 'bullets',
            items: [
              'Cặn sữa: lớp trắng mỏng, thường chỉ ở mặt lưỡi, lau nhẹ bằng gạc sạch thấm nước là hết, và tự nhạt đi sau cữ bú một lúc.',
              'Tưa lưỡi: mảng trắng hoặc trắng xám như sữa đông, có thể ở lưỡi, lợi, vòm miệng, mặt trong má hoặc môi; lau nhẹ không đi, hoặc lau ra thì bên dưới đỏ, có thể rớm máu.',
              'Dấu hiệu đi kèm: bé quấy khi bú, nhả vú, bỏ bú; có lớp trắng ở môi; hăm tã đỏ, bóng ở nếp da, có chấm đỏ nhỏ và khó khỏi (có thể là nấm ở vùng tã).',
              'Chỉ lau thử thật nhẹ một lần để phân biệt. Không cố cạo, rơ mạnh cho sạch mảng trắng.',
            ],
          },
          {
            type: 'heading',
            text: 'Điều trị: cần bác sĩ khám và kê đơn',
          },
          {
            type: 'paragraph',
            text: 'Tưa nhẹ đôi khi tự hết, nhưng Child Life khuyên cho bé đi khám khi thấy mảng trắng, nhất là bé dưới 4 tháng. NHS (Anh) cho biết gel bôi miệng bán tại nhà thuốc chỉ dành cho bé từ 4 tháng; bé nhỏ hơn cần bác sĩ khám và kê thuốc. Thuốc chống nấm dạng gel hoặc dạng nước phải chạm vào chỗ có tưa mới có tác dụng.',
          },
          {
            type: 'bullets',
            items: [
              'Dùng đúng thuốc, đúng số lần bác sĩ dặn; hỏi bác sĩ hoặc dược sĩ cách bôi và liều theo tuổi, cân nặng của bé.',
              'Dùng đủ thời gian, kể cả khi mảng trắng đã hết; Hội Nhi khoa Canada khuyên dùng tiếp thêm 2 ngày sau khi hết.',
              'Thuốc thường giúp đỡ sau vài ngày. Nếu sau khoảng 1 tuần không đỡ, hoặc bé bú kém, đưa bé đi khám lại.',
              'Không tự dùng thuốc của người lớn, thuốc kê cho bé khác hay thuốc không rõ nguồn gốc.',
            ],
          },
          {
            type: 'heading',
            text: 'Mẹ đang cho con bú: nấm ở đầu ti',
          },
          {
            type: 'paragraph',
            text: 'Nấm có thể truyền qua lại giữa miệng bé và đầu ti mẹ. Nghĩ đến nấm khi mẹ đột nhiên đau cả hai đầu ti hoặc hai bên ngực sau cữ bú, dù trước đó cho bú không đau; cơn đau có thể kéo dài đến một giờ sau mỗi cữ. Đầu ti có thể đỏ, hồng, nhạy cảm, quầng vú bong vảy. Nếu chỉ đau một bên, mẹ sốt, hoặc có mảng đỏ nóng trên một bên vú, nhiều khả năng là nguyên nhân khác như tắc tia sữa hay viêm vú, mẹ cần đi khám.',
          },
          {
            type: 'bullets',
            items: [
              'Theo NHS, nếu mẹ hoặc bé bị nấm, cả hai cần được chữa cùng lúc vì nấm dễ lây qua lại. Mẹ đi khám để được kê thuốc phù hợp cho đầu ti.',
              'Mẹ vẫn cho con bú bình thường trong thời gian chữa.',
              'Sữa vắt ra trong lúc đang chữa nên cho bé dùng luôn; NHS khuyên không trữ đông để dùng sau vì có thể làm nấm quay lại.',
              'Rửa tay kỹ sau khi thay tã và sau khi bôi thuốc; dùng khăn riêng; thay miếng lót thấm sữa thường xuyên, chọn loại không có lớp nhựa; giặt áo ngực bằng nước nóng.',
            ],
          },
          {
            type: 'heading',
            text: 'Vệ sinh bình sữa, núm vú giả và đồ chơi',
          },
          {
            type: 'bullets',
            items: [
              'Tiệt trùng bình sữa và núm bình sau mỗi lần dùng; tiệt trùng núm vú giả thường xuyên.',
              'Rửa sạch và tiệt trùng các bộ phận máy hút sữa chạm vào sữa, cùng đồ chơi bé hay ngậm.',
              'NHS gợi ý thay núm bình và miếng bảo vệ đầu ti mới mỗi tuần để phòng nấm.',
              'Không cho bé ngậm bình đi ngủ hay ngậm núm quá lâu; mút quá lâu làm niêm mạc miệng dễ bị kích ứng và nhiễm nấm hơn.',
            ],
          },
          {
            type: 'paragraph',
            text: 'Ở Việt Nam: nhiều gia đình có thói quen rơ lưỡi cho bé hằng ngày bằng khăn hoặc gạc quấn ngón tay chấm nước muối, mật ong, hoặc giã lá cây rồi bôi lên lưỡi. Ông bà làm vì muốn miệng cháu sạch, nhưng miệng bé không cần rơ mới sạch. Chà xát dễ làm xước niêm mạc, khiến nấm dễ bám hơn; muối và lá cây không chữa được nấm; còn mật ong không dùng cho trẻ dưới 12 tháng vì nguy cơ ngộ độc botulinum.',
          },
          {
            type: 'heading',
            text: 'Cứt trâu (viêm da tiết bã) là gì?',
          },
          {
            type: 'paragraph',
            text: 'Cứt trâu là những mảng vảy vàng hoặc trắng, nhờn, đóng thành lớp trên da đầu bé, đôi khi có ở mặt, sau tai, lông mày hoặc vùng tã. Đây là tình trạng vô hại, không do bẩn, không do dị ứng và không lây. Bé thường không ngứa, không đau. Phần lớn tự hết sau vài tuần đến vài tháng, và thường hết trước 1 tuổi.',
          },
          {
            type: 'heading',
            text: 'Chăm sóc cứt trâu tại nhà',
          },
          {
            type: 'bullets',
            items: [
              'Làm mềm vảy: xoa nhẹ một lớp kem dưỡng ẩm không mùi, dầu dừa hoặc sáp dầu khoáng lên chỗ có vảy. Với vảy dày, AAP gợi ý để qua đêm rồi gội.',
              'Chải nhẹ bằng bàn chải lông mềm hoặc lược mềm dành cho em bé để vảy bong ra, rồi gội bằng dầu gội dịu nhẹ dành cho em bé.',
              'Gội đầu đều đặn, khoảng cách ngày. Không dùng xà phòng, dầu gội người lớn hay sản phẩm có hương liệu.',
              'Không cạy, gỡ vảy bằng móng tay hay lược sắc: dễ trầy da và nhiễm trùng. Tóc có thể rụng theo vảy và sẽ mọc lại.',
              'NHS khuyên không dùng dầu ô liu và dầu lạc (dầu đậu phộng) để làm mềm vảy.',
              'Hỏi bác sĩ trước khi dùng dầu gội hay kem có thuốc.',
            ],
          },
          {
            type: 'paragraph',
            text: 'Ở Việt Nam: một số gia đình gỡ cứt trâu bằng móng tay, lược bí, hoặc gội, đắp nước lá cho bé. Cạy gỡ làm trầy da, còn nước lá có thể gây kích ứng da non của bé. Cứ kiên nhẫn làm mềm và chải nhẹ, vảy sẽ bong dần.',
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'Mẹo nhỏ',
            text: 'Bôi dầu hoặc kem làm mềm vảy một lúc trước giờ tắm, rồi chải nhẹ theo vòng tròn khi gội. Làm từng ít một qua nhiều ngày, không cần gỡ sạch trong một lần.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Gọi 115 hoặc đến cấp cứu ngay khi',
            text: 'Bé bỏ bú hoàn toàn, rất ít tã ướt, môi miệng khô; li bì, lả mềm hoặc khó đánh thức; khóc yếu hoặc khóc thét không dỗ được; khó thở; bé dưới 3 tháng sốt từ 38 °C. Đừng chờ, gọi 115 ngay.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Đưa bé đi khám khi',
            text: 'Thấy mảng trắng trong miệng bé, nhất là bé dưới 4 tháng; bé quấy hoặc bú kém khi bú; tưa không đỡ sau khoảng 1 tuần dùng thuốc; mẹ đau đầu ti khi cho bú; hăm tã đỏ khó khỏi. Với cứt trâu: không đỡ sau vài tuần chăm sóc; lan ra nhiều vùng trên cơ thể; vảy chảy máu, chảy dịch, có mủ, sưng hoặc có mùi; hoặc bé có vẻ ngứa, đau.',
          },
        ],
        en: [
          {
            type: 'callout',
            tone: 'note',
            title: 'In short',
            text: "Oral thrush is white patches in your baby's mouth that don't wipe off the way milk does. It is caused by the yeast Candida and needs a doctor to examine and prescribe treatment; if you are breastfeeding, mother and baby usually need treating at the same time. Cradle cap (seborrhoeic dermatitis) is yellow, greasy scales on the scalp; it is harmless and usually clears by itself: soften, wash gently, brush softly, don't pick.",
          },
          {
            type: 'heading',
            text: 'What is oral thrush?',
          },
          {
            type: 'paragraph',
            text: 'Candida yeast normally lives in the mouth. When the lining of the mouth is irritated or damaged, the yeast can overgrow and cause thrush. Young babies, babies who suck on a dummy or bottle teat for long periods, and babies who have recently had antibiotics are more likely to get it. Thrush is common and usually not serious, but it can make your baby uncomfortable, fussy and feed poorly.',
          },
          {
            type: 'heading',
            text: 'Thrush or milk residue?',
          },
          {
            type: 'bullets',
            items: [
              'Milk residue: a thin white coating, usually only on the top of the tongue, that comes off with a gentle wipe of a clean damp gauze and fades a while after a feed.',
              "Thrush: white or greyish patches like cottage cheese, on the tongue, gums, roof of the mouth, inside the cheeks or lips; they don't come off with a gentle wipe, or leave red, sometimes bleeding spots underneath.",
              "Other signs: fussing at the breast or bottle, pulling off, refusing feeds; a white film on the lips; a red, shiny diaper rash in the skin folds with small red spots that won't clear (possibly yeast in the diaper area).",
              "Wipe very gently just once to tell them apart. Don't scrape or rub hard to clean off white patches.",
            ],
          },
          {
            type: 'heading',
            text: 'Treatment needs a doctor and a prescription',
          },
          {
            type: 'paragraph',
            text: 'Mild thrush sometimes clears on its own, but Child Life recommends having your baby seen when you notice white patches, especially under 4 months. The NHS (UK) says the mouth gel sold in pharmacies is only for babies from 4 months; younger babies need a doctor to examine them and prescribe. An antifungal gel or liquid only works if it touches the patches.',
          },
          {
            type: 'bullets',
            items: [
              "Use the right medicine as often as the doctor says; ask a doctor or pharmacist how to apply it and the dose for your baby's age and weight.",
              'Use it for the full time, even after the patches have gone; the Canadian Paediatric Society advises continuing for 2 days after they clear.',
              'Treatment usually helps within a few days. If there is no improvement after about a week, or your baby feeds poorly, go back to the doctor.',
              "Don't use adult medicines, medicine prescribed for another child, or products of unknown origin.",
            ],
          },
          {
            type: 'heading',
            text: 'Breastfeeding mothers: thrush on the nipples',
          },
          {
            type: 'paragraph',
            text: "Thrush can pass back and forth between your baby's mouth and your nipples. Think of thrush if you suddenly have pain in both nipples or both breasts after feeds when feeding did not hurt before; the pain can last up to an hour after each feed. Nipples may look red or pink, feel sensitive, or the areola may be flaky. If the pain is on one side only, you have a fever, or there is a hot red patch on one breast, another cause such as a blocked duct or mastitis is more likely, and you need to be seen.",
          },
          {
            type: 'bullets',
            items: [
              'The NHS says that if either of you has thrush, you both need treating at the same time because it spreads easily between you. See a doctor for a suitable treatment for your nipples.',
              'Keep breastfeeding as usual during treatment.',
              'Give your baby any milk you express during treatment; the NHS advises not freezing it for later because that may bring the thrush back.',
              'Wash your hands well after diaper changes and after applying treatment; use separate towels; change breast pads often and choose ones without a plastic backing; wash bras on a hot wash.',
            ],
          },
          {
            type: 'heading',
            text: 'Cleaning bottles, dummies and toys',
          },
          {
            type: 'bullets',
            items: [
              'Sterilise bottles and teats after every use, and sterilise dummies regularly.',
              'Clean and sterilise breast pump parts that touch milk, and toys your baby puts in their mouth.',
              'The NHS suggests replacing teats and nipple shields every week to help prevent thrush.',
              "Don't let your baby fall asleep sucking a bottle or suck on a teat for very long; prolonged sucking irritates the lining of the mouth and makes thrush more likely.",
            ],
          },
          {
            type: 'paragraph',
            text: "In Việt Nam: many families clean the baby's tongue every day (rơ lưỡi) with a cloth or gauze wrapped round a finger and dipped in salt water or honey, or rub crushed herbal leaves on the tongue. Grandparents do this to keep the baby's mouth clean, but a baby's mouth does not need scrubbing. Rubbing can damage the lining and help yeast take hold; salt and leaves don't treat thrush; and honey must not be given to babies under 12 months because of the risk of botulism.",
          },
          {
            type: 'heading',
            text: 'What is cradle cap (seborrhoeic dermatitis)?',
          },
          {
            type: 'paragraph',
            text: "Cradle cap is yellow or white, greasy scales that build up on a baby's scalp, sometimes also on the face, behind the ears, on the eyebrows or in the diaper area. It is harmless, not caused by poor hygiene or allergy, and not contagious. It usually isn't itchy or painful. Most cases clear by themselves within weeks to months, usually by 1 year.",
          },
          {
            type: 'heading',
            text: 'Caring for cradle cap at home',
          },
          {
            type: 'bullets',
            items: [
              'Soften the scales: gently massage a fragrance-free moisturiser, coconut oil or petroleum jelly into the scaly areas. For thick scales, the AAP suggests leaving it on overnight, then washing.',
              'Brush gently with a soft baby brush or baby comb to loosen the scales, then wash with a mild baby shampoo.',
              "Wash the hair regularly, about every other day. Don't use soap, adult shampoo or fragranced products.",
              "Don't pick or scrape the scales with fingernails or a fine-toothed comb: it can break the skin and cause infection. Some hair may come away with the scales and will grow back.",
              'The NHS advises against olive oil and peanut oil for softening the scales.',
              'Ask a doctor before using a medicated shampoo or cream.',
            ],
          },
          {
            type: 'paragraph',
            text: "In Việt Nam: some families pick cradle cap off with a fingernail or a fine-toothed lice comb, or wash and compress the scalp with herbal leaf water. Picking breaks the skin, and leaf water can irritate a baby's delicate skin. Be patient: soften and brush gently, and the scales will come away bit by bit.",
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'Tip',
            text: 'Apply the oil or moisturiser a while before bath time, then brush gently in small circles while you wash. Do a little at a time over several days; there is no need to clear it all at once.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Call 115 (Việt Nam) or local emergency services now if',
            text: "Your baby refuses all feeds, has very few wet diapers or a dry mouth; is listless, floppy or hard to wake; has a weak, high-pitched or inconsolable cry; struggles to breathe; or is under 3 months with a temperature of 38 °C or more. Don't wait: call emergency services.",
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'See a doctor if',
            text: "You see white patches in your baby's mouth, especially under 4 months; your baby fusses or feeds poorly; thrush hasn't improved after about a week of treatment; your nipples hurt when feeding; or a red diaper rash won't clear. For cradle cap: no improvement after a few weeks of care; it spreads over much of the body; the crusts bleed, ooze, have pus, look swollen or smell; or your baby seems itchy or in pain.",
          },
        ],
      },
      keywords: {
        vi: [
          'tưa lưỡi',
          'nấm miệng',
          'cứt trâu',
          'viêm da tiết bã',
          'nấm đầu ti',
          'rơ lưỡi',
          'tiệt trùng bình sữa',
          'cặn sữa',
        ],
        en: [
          'oral thrush',
          'mouth thrush',
          'cradle cap',
          'seborrhoeic dermatitis',
          'nipple thrush',
          'tongue cleaning',
          'sterilising bottles',
          'milk tongue',
        ],
      },
      relatedArticleIds: [
        'art_newborn_skin_rashes',
        'art_breastfeeding_start',
        'art_formula_bottle',
        'art_diaper_rash',
      ],
      milestoneIds: [],
      sources: [
        {
          label: 'NHS — Oral thrush (mouth thrush)',
          url: 'https://www.nhs.uk/conditions/oral-thrush-in-babies/',
        },
        {
          label: 'NHS 111 Wales — Breastfeeding and thrush',
          url: 'https://111.wales.nhs.uk/livewell/pregnancy/breastfeedingthrush/',
        },
        {
          label: 'Canadian Paediatric Society (Caring for Kids) — Thrush',
          url: 'https://caringforkids.cps.ca/handouts/pregnancy-and-babies/thrush',
        },
        {
          label: 'HealthyChildren.org (AAP) — Thrush and other Candida infections',
          url: 'https://www.healthychildren.org/English/health-issues/conditions/infections/Pages/Thrush-and-Other-Candida-Infections.aspx',
        },
        {
          label: 'NHS — Cradle cap',
          url: 'https://www.nhs.uk/conditions/cradle-cap/',
        },
        {
          label: 'HealthyChildren.org (AAP) — What is cradle cap?',
          url: 'https://www.healthychildren.org/English/ages-stages/baby/bathing-skin-care/Pages/Cradle-Cap.aspx',
        },
      ],
    },
  },
  {
    id: 'art_ear_infection',
    reviewerLabel: 'Nhóm chuyên môn · Nhi khoa',
    data: {
      library: 'care',
      topic: 'illness',
      format: 'article',
      ageWeeks: {
        from: 13,
        to: 156,
      },
      readingMinutes: 6,
      cover: null,
      title: {
        vi: 'Viêm tai giữa ở trẻ nhỏ: nhận biết, giảm đau và khi nào cần kháng sinh',
        en: 'Middle ear infections in young children: signs, pain relief and when antibiotics help',
      },
      summary: {
        vi: 'Viêm tai giữa hay đến sau cảm lạnh. Phần lớn tự khỏi trong vài ngày, và giảm đau là việc quan trọng nhất. Bác sĩ quyết định cho kháng sinh ngay hay theo dõi. Không nhỏ, nhét gì vào tai khi chưa có đơn.',
        en: 'Middle ear infections often follow a cold. Most clear within a few days, and pain relief matters most. The doctor decides between antibiotics now or watchful waiting. Put nothing in the ear unless prescribed.',
      },
      body: {
        vi: [
          {
            type: 'callout',
            tone: 'note',
            title: 'Tóm tắt nhanh',
            text: 'Viêm tai giữa là nhiễm trùng ở khoang phía sau màng nhĩ, rất hay gặp ở trẻ nhỏ và thường đến sau cảm lạnh. Phần lớn tự khỏi trong khoảng 3 ngày, có khi đến 1 tuần. Việc ba mẹ cần làm trước tiên là giảm đau cho bé. Kháng sinh cần cho một số bé, do bác sĩ quyết định sau khi soi tai. Không nhỏ, nhét gì vào tai bé khi chưa có đơn.',
          },
          {
            type: 'heading',
            text: 'Vì sao bé hay bị viêm tai sau cảm lạnh?',
          },
          {
            type: 'paragraph',
            text: 'Tai giữa thông với họng qua một ống nhỏ gọi là vòi nhĩ. Ở trẻ nhỏ, ống này ngắn, hẹp và nằm ngang hơn ở người lớn. Khi bé cảm lạnh, niêm mạc mũi họng sưng làm vòi nhĩ bị tắc, dịch ứ lại sau màng nhĩ, và vi khuẩn hoặc virus dễ phát triển ở đó. Vì vậy, viêm tai thường xuất hiện vài ngày sau khi bé sổ mũi, ho.',
          },
          {
            type: 'heading',
            text: 'Dấu hiệu ở bé chưa biết nói',
          },
          {
            type: 'bullets',
            items: [
              'Kéo, dụi, cào tai kèm quấy khóc. Lưu ý: nhiều bé kéo tai chỉ để tự dỗ, nên kéo tai mà không kèm dấu hiệu nào khác chưa chắc là viêm tai.',
              'Sốt, quấy hơn hẳn, khó ngủ, hay thức giấc, khóc nhiều khi nằm.',
              'Bỏ bú, biếng ăn.',
              'Ít phản ứng với âm thanh, không quay về phía tiếng gọi như mọi khi.',
              'Dịch vàng, mủ hoặc lẫn máu chảy ra từ tai.',
              'Bé đã biết đi có thể mất thăng bằng, hay ngã hơn.',
            ],
          },
          {
            type: 'heading',
            text: 'Giảm đau cho bé',
          },
          {
            type: 'bullets',
            items: [
              'Thuốc giảm đau là phần chính của việc chăm bé viêm tai, kể cả khi bé có dùng kháng sinh. Hỏi bác sĩ hoặc dược sĩ liều theo cân nặng của bé.',
              'Bé dưới 6 tháng: CDC (Mỹ) khuyên chỉ dùng paracetamol, và Hội Nhi khoa Canada khuyên không cho bé dưới 6 tháng dùng ibuprofen khi chưa hỏi bác sĩ. Bé lớn hơn chỉ dùng ibuprofen khi bé vẫn bú, uống được.',
              'Không bao giờ dùng aspirin cho trẻ.',
              'Đặt khăn ướt mát hoặc hơi ấm lên vành tai ngoài khoảng 20 phút có thể giúp bé dễ chịu (AAP). Thử nhiệt độ khăn trước, không để quá nóng hay quá lạnh.',
              'Cho bé bú, uống đủ và nghỉ ngơi. Khi bú bình, bế bé đầu cao hơn bụng.',
              'Không dùng thuốc thông mũi hay thuốc kháng histamin để chữa viêm tai: NHS cho biết không có bằng chứng giúp ích.',
            ],
          },
          {
            type: 'heading',
            text: 'Kháng sinh ngay hay theo dõi?',
          },
          {
            type: 'paragraph',
            text: 'AAP cho biết khoảng 80% ca viêm tai ở trẻ tự khỏi không cần thuốc, còn kháng sinh có thể gây tác dụng phụ như tiêu chảy, phát ban. Vì vậy với ca nhẹ, bác sĩ có thể theo dõi 2–3 ngày, hoặc kê đơn nhưng dặn chỉ dùng nếu bé không đỡ. Theo hướng dẫn năm 2013 của AAP (Mỹ), bác sĩ thường cho kháng sinh ngay khi:',
          },
          {
            type: 'bullets',
            items: [
              'Bé dưới 6 tháng bị viêm tai giữa.',
              'Bé 6–23 tháng bị viêm cả hai tai, hoặc có dịch chảy ra từ tai.',
              'Bé ở bất kỳ tuổi nào có triệu chứng nặng: đau nhiều, sốt từ 39 °C, hoặc triệu chứng kéo dài hơn 2–3 ngày, nặng dần.',
              'Bé có bệnh nền hoặc hệ miễn dịch yếu.',
            ],
          },
          {
            type: 'paragraph',
            text: 'Bé từ 2 tuổi bị viêm tai nhẹ, không chảy dịch tai, thường có thể được theo dõi trước. Ở Anh, NHS khuyên bé dưới 12 tháng nghi viêm tai nên được bác sĩ khám, và bé dưới 12 tháng đau cả hai tai cần được khám gấp. Child Life theo cách thận trọng: bé dưới 2 tuổi nghi viêm tai nên được đi khám để bác sĩ soi tai và quyết định.',
          },
          {
            type: 'bullets',
            items: [
              'Nếu được kê kháng sinh: cho bé uống đủ liều, đủ ngày theo đơn, kể cả khi bé đã đỡ.',
              'Nếu bác sĩ cho theo dõi: đưa bé khám lại khi sau 2–3 ngày không đỡ hoặc nặng hơn.',
              'Không tự mua kháng sinh, không dùng lại thuốc thừa của lần trước hay của anh chị em.',
            ],
          },
          {
            type: 'heading',
            text: 'Không nhỏ, nhét gì vào tai bé',
          },
          {
            type: 'paragraph',
            text: 'Chỉ nhỏ thuốc vào tai khi bác sĩ đã khám và kê đơn. Không dùng tăm bông, ngón tay hay vật gì để ngoáy tai bé (NHS). Nếu có dịch chảy ra, chỉ lau nhẹ phần ngoài vành tai bằng bông sạch. Giữ cho nước và dầu gội không vào tai khi tắm cho đến khi khỏi.',
          },
          {
            type: 'paragraph',
            text: 'Ở Việt Nam: một số gia đình nhỏ dầu, nước tỏi, nước lá cây hoặc sữa mẹ vào tai bé để chữa đau tai. Những cách này chưa được chứng minh có tác dụng; nếu màng nhĩ đã thủng, chất lỏng có thể vào sâu bên trong và gây hại thêm. Hãy giảm đau cho bé và cho bé đi khám.',
          },
          {
            type: 'heading',
            text: 'Ứ dịch tai giữa và thính lực',
          },
          {
            type: 'paragraph',
            text: 'Sau một đợt viêm, dịch có thể đọng lại sau màng nhĩ vài tuần (ứ dịch tai giữa, còn gọi là “tai keo”). Bé thường không đau nhưng có thể nghe kém hơn một thời gian. AAP cho biết khoảng 90% trường hợp dịch tự hết trong 1–2 tháng, và tổn thương thính lực lâu dài rất hiếm. Nếu bé có vẻ nghe kém kéo dài, chậm nói, hoặc viêm tai nhiều lần, hãy cho bé khám lại để kiểm tra thính lực; một số bé cần đặt ống thông khí nhỏ qua màng nhĩ.',
          },
          {
            type: 'heading',
            text: 'Phòng viêm tai cho bé',
          },
          {
            type: 'bullets',
            items: [
              'Cho bé bú mẹ: CDC khuyên bú mẹ hoàn toàn đến 6 tháng và tiếp tục ít nhất đến 12 tháng.',
              'Không để bé hít khói thuốc lá, kể cả khói bám trên quần áo, đồ đạc.',
              'Tiêm chủng đầy đủ, gồm vắc xin phế cầu và vắc xin cúm hằng năm theo tư vấn của bác sĩ.',
              'Không cho bé bú bình khi nằm thẳng, không để bé ngậm bình đi ngủ.',
              'Rửa tay thường xuyên để bé bớt cảm lạnh, nhất là khi bé đi nhà trẻ.',
              'Núm vú giả: nếu bé hay bị viêm tai, Hội Nhi khoa Canada khuyên giảm dùng núm vú giả.',
              'Chuyển dần từ bình sang cốc vào khoảng 1 tuổi.',
            ],
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'Mẹo nhỏ',
            text: 'Ghi lại giờ cho thuốc giảm đau, nhiệt độ và giấc ngủ của bé trong Child Life. Khi đi khám lại, bác sĩ dễ biết bé đã đỡ hay chưa và có cần đổi cách chữa không.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Gọi 115 hoặc đến cấp cứu ngay khi',
            text: 'Vùng sau tai sưng, đỏ, đau, đẩy vành tai ra phía trước; bé cổ cứng, khó cúi đầu; li bì, khó đánh thức hoặc quấy khóc dữ dội không dỗ được; nôn nhiều lần; co giật; ban không mất màu khi ấn cốc; bé dưới 3 tháng sốt từ 38 °C. Đừng chờ, gọi 115 ngay.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Đưa bé đi khám trong ngày khi',
            text: 'Bé dưới 6 tháng nghi viêm tai; bé dưới 2 tuổi đau tai, nhất là đau cả hai tai; có dịch, mủ hoặc máu chảy ra từ tai; sốt từ 39 °C; đau nhiều dù đã dùng thuốc giảm đau; không đỡ sau 2–3 ngày, hoặc vẫn đau sau 2 ngày dùng kháng sinh; sốt quá 48 giờ; bé có vẻ nghe kém.',
          },
        ],
        en: [
          {
            type: 'callout',
            tone: 'note',
            title: 'In short',
            text: "A middle ear infection is an infection in the space behind the eardrum. It is very common in young children and often follows a cold. Most clear up within about 3 days, sometimes up to a week. The first thing to do is ease your child's pain. Some children need antibiotics; the doctor decides after looking in the ear. Put nothing in your child's ear unless it has been prescribed.",
          },
          {
            type: 'heading',
            text: 'Why do ear infections follow colds?',
          },
          {
            type: 'paragraph',
            text: 'The middle ear is connected to the throat by a small tube called the Eustachian tube. In young children this tube is shorter, narrower and more horizontal than in adults. During a cold, the swollen lining of the nose and throat blocks the tube, fluid builds up behind the eardrum, and bacteria or viruses can grow there. That is why ear infections often start a few days after a runny nose or cough.',
          },
          {
            type: 'heading',
            text: "Signs in a baby who can't talk yet",
          },
          {
            type: 'bullets',
            items: [
              'Pulling, rubbing or scratching at the ear along with crying. Note: many babies tug their ears just to soothe themselves, so ear pulling on its own, with no other signs, is not necessarily an infection.',
              'Fever, being much fussier than usual, trouble sleeping, waking often, crying more when lying down.',
              'Refusing feeds or food.',
              'Responding less to sounds, not turning to your voice as usual.',
              'Yellow, pus-like or bloody fluid coming out of the ear.',
              'A child who walks may lose their balance or fall more often.',
            ],
          },
          {
            type: 'heading',
            text: 'Easing the pain',
          },
          {
            type: 'bullets',
            items: [
              "Pain medicine is the main part of caring for an ear infection, even if your child also takes antibiotics. Ask a doctor or pharmacist for the dose for your child's weight.",
              'Under 6 months: the CDC (US) advises paracetamol only, and the Canadian Paediatric Society says not to give ibuprofen to babies under 6 months without asking a doctor first. Older children should only have ibuprofen if they are feeding and drinking.',
              'Never give aspirin to children.',
              'A cool or slightly warm wet cloth on the outer ear for about 20 minutes may help (AAP). Test the temperature first so it is not too hot or too cold.',
              'Keep up feeds and fluids and let your child rest. When bottle-feeding, hold your baby with their head higher than their tummy.',
              "Don't use decongestants or antihistamines for an ear infection: the NHS says there is no evidence they help.",
            ],
          },
          {
            type: 'heading',
            text: 'Antibiotics now or watchful waiting?',
          },
          {
            type: 'paragraph',
            text: "The AAP says about 80% of ear infections in children clear up without medicine, and antibiotics can cause side effects such as diarrhoea and rashes. So for mild cases, the doctor may suggest watching for 2–3 days, or give a prescription to use only if your child doesn't improve. Under the AAP (US) 2013 guideline, doctors usually give antibiotics straight away when:",
          },
          {
            type: 'bullets',
            items: [
              'A baby under 6 months has a middle ear infection.',
              'A child aged 6–23 months has an infection in both ears, or fluid coming out of the ear.',
              'A child of any age has severe symptoms: a lot of pain, a fever of 39 °C or more, or symptoms lasting more than 2–3 days and getting worse.',
              'A child has a long-term condition or a weakened immune system.',
            ],
          },
          {
            type: 'paragraph',
            text: 'Children aged 2 and over with a mild infection and no fluid coming from the ear can often be watched first. In the UK, the NHS advises that babies under 12 months with a suspected ear infection see a GP, and that babies under 12 months with earache in both ears are seen urgently. Child Life follows the more cautious approach: a child under 2 with a suspected ear infection should be seen so a doctor can look in the ear and decide.',
          },
          {
            type: 'bullets',
            items: [
              'If antibiotics are prescribed: give the full course as directed, even when your child seems better.',
              'If the doctor suggests watching: go back if your child is not better after 2–3 days or gets worse.',
              "Don't buy antibiotics without a prescription or use leftovers from a previous illness or a sibling.",
            ],
          },
          {
            type: 'heading',
            text: "Put nothing in your child's ear",
          },
          {
            type: 'paragraph',
            text: "Only use ear drops when a doctor has examined your child and prescribed them. Don't use cotton buds, a finger or anything else to clean inside the ear (NHS). If fluid is coming out, gently wipe only the outer ear with clean cotton wool. Keep water and shampoo out of the ear when bathing until it has healed.",
          },
          {
            type: 'paragraph',
            text: "In Việt Nam: some families put oil, garlic juice, herbal leaf water or breast milk in a child's ear to treat earache. None of these has been shown to work, and if the eardrum has a hole, liquid can get deeper inside and cause further harm. Ease the pain and have your child seen instead.",
          },
          {
            type: 'heading',
            text: 'Glue ear and hearing',
          },
          {
            type: 'paragraph',
            text: "After an infection, fluid can stay behind the eardrum for a few weeks (otitis media with effusion, also called glue ear). It usually doesn't hurt but can make hearing duller for a while. The AAP says the fluid clears by itself within 1–2 months in about 90% of children, and lasting hearing damage is very rare. If your child seems to hear poorly for a long time, is slow to talk, or has many ear infections, go back to have their hearing checked; some children need small ventilation tubes placed in the eardrum.",
          },
          {
            type: 'heading',
            text: 'Preventing ear infections',
          },
          {
            type: 'bullets',
            items: [
              'Breastfeed if you can: the CDC advises breastfeeding only until 6 months and continuing for at least 12 months.',
              'Keep your child away from tobacco smoke, including smoke left on clothes and furniture.',
              'Keep vaccinations up to date, including the pneumococcal vaccine and a yearly flu vaccine as your doctor advises.',
              "Don't bottle-feed your baby lying flat, and don't put them to bed with a bottle.",
              'Wash hands often to cut down on colds, especially once your child starts nursery.',
              'Dummies: if your child gets ear infections often, the Canadian Paediatric Society advises cutting down dummy use.',
              'Move from bottle to cup around 1 year.',
            ],
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'Tip',
            text: 'Log pain medicine times, temperatures and sleep in Child Life. At the follow-up visit, the doctor can see whether your child is improving and whether treatment needs to change.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Call 115 (Việt Nam) or local emergency services now if',
            text: "There is swelling, redness and pain behind the ear that pushes the ear forward; your child has a stiff neck and can't bend their head forward; is very drowsy, hard to wake or crying in a way you can't settle; vomits repeatedly; has a fit; has a rash that does not fade under a glass; or is under 3 months with 38 °C or more. Don't wait: call emergency services.",
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'See a doctor the same day if',
            text: 'Your baby is under 6 months with a possible ear infection; a child under 2 has earache, especially in both ears; fluid, pus or blood is coming from the ear; the fever is 39 °C or more; pain is severe despite pain medicine; there is no improvement after 2–3 days, or still pain after 2 days of antibiotics; the fever lasts more than 48 hours; or your child seems not to hear well.',
          },
        ],
      },
      keywords: {
        vi: [
          'viêm tai giữa',
          'đau tai',
          'chảy mủ tai',
          'kháng sinh',
          'ứ dịch tai giữa',
          'thính lực',
          'kéo tai',
          'vắc xin phế cầu',
        ],
        en: [
          'middle ear infection',
          'earache',
          'ear discharge',
          'antibiotics',
          'glue ear',
          'hearing',
          'ear pulling',
          'pneumococcal vaccine',
        ],
      },
      relatedArticleIds: [
        'art_cold_cough',
        'art_fever_when_to_call',
        'art_medicine_safety',
        'art_after_vaccines',
      ],
      milestoneIds: [],
      sources: [
        {
          label: 'HealthyChildren.org (AAP) — Ear infections in children: information for parents',
          url: 'https://www.healthychildren.org/English/health-issues/conditions/ear-nose-throat/Pages/Ear-Infection-Information.aspx',
        },
        {
          label: 'HealthyChildren.org (AAP) — Ear infection questions (symptom checker)',
          url: 'https://www.healthychildren.org/English/tips-tools/symptom-checker/Pages/symptomviewer.aspx?symptom=Ear+Infection+Questions',
        },
        {
          label:
            'American Family Physician — Should children with acute otitis media routinely be treated with antibiotics? (summary of the AAP 2013 guideline)',
          url: 'https://www.aafp.org/pubs/afp/issues/2013/1001/od2.html',
        },
        {
          label: 'CDC — Ear infection basics',
          url: 'https://www.cdc.gov/ear-infection/about/index.html',
        },
        {
          label: 'NHS — Ear infections',
          url: 'https://www.nhs.uk/conditions/ear-infections/',
        },
        {
          label: 'Canadian Paediatric Society (Caring for Kids) — Ear infections',
          url: 'https://caringforkids.cps.ca/handouts/health-conditions-and-treatments/ear_infections',
        },
      ],
    },
  },
  {
    id: 'art_eye_discharge',
    reviewerLabel: 'Nhóm chuyên môn · Nhi khoa',
    data: {
      library: 'care',
      topic: 'illness',
      format: 'article',
      ageWeeks: {
        from: 0,
        to: 156,
      },
      readingMinutes: 6,
      cover: null,
      title: {
        vi: 'Mắt bé có ghèn, chảy nước mắt: tắc tuyến lệ, đau mắt đỏ và khi nào cần khám gấp',
        en: 'Sticky and watery eyes: blocked tear ducts, conjunctivitis and when to get help fast',
      },
      summary: {
        vi: 'Bé sơ sinh chảy nước mắt, có ghèn thường do tắc tuyến lệ và tự hết trước 1 tuổi. Đau mắt đỏ hay do virus. Mi sưng đỏ, bé dưới 1 tháng có mủ ở mắt, chấn thương mắt hay đồng tử trắng cần khám gấp.',
        en: 'Watery, sticky eyes in newborns are usually a blocked tear duct that clears by age 1. Conjunctivitis is often viral. Red swollen lids, pus in a baby under 1 month, an eye injury or a white pupil need urgent care.',
      },
      body: {
        vi: [
          {
            type: 'callout',
            tone: 'note',
            title: 'Tóm tắt nhanh',
            text: 'Phần lớn mắt bé có ghèn (dử mắt), chảy nước mắt là do tắc tuyến lệ hoặc đau mắt đỏ và không nguy hiểm. Lau mắt bằng nước đun sôi để nguội, rửa tay kỹ, và chỉ nhỏ thuốc khi bác sĩ kê đơn. Cần khám gấp khi mi mắt sưng đỏ, bé dưới 1 tháng có mắt đỏ nhiều mủ, mắt bị thương hay dính hoá chất, đồng tử có ánh trắng trên ảnh, hoặc mắt lệch kéo dài.',
          },
          {
            type: 'heading',
            text: 'Tắc tuyến lệ ở bé sơ sinh',
          },
          {
            type: 'paragraph',
            text: 'Nước mắt thường chảy qua một ống nhỏ ở góc trong mắt xuống mũi. Khoảng 1 trên 10 bé sơ sinh có ống này chưa thông (AAP), đôi khi cả hai bên. Bé chảy nước mắt liên tục kể cả khi không khóc, có ghèn trắng hoặc vàng ở góc mắt, mi dính khi ngủ dậy, nhưng lòng trắng mắt không đỏ và mi không sưng. Ba mẹ thường thấy rõ khi bé khoảng 1–2 tháng, lúc bé tiết nhiều nước mắt hơn. Hơn 9 trên 10 trường hợp tự thông trước 1 tuổi.',
          },
          {
            type: 'heading',
            text: 'Lau mắt và xoa túi lệ đúng cách',
          },
          {
            type: 'bullets',
            items: [
              'Rửa tay trước và sau khi lau mắt cho bé.',
              'Dùng bông gòn sạch thấm nước đun sôi để nguội, lau nhẹ từ góc trong (cạnh mũi) ra góc ngoài. Mỗi lần lau dùng một miếng bông mới, mỗi mắt một miếng riêng.',
              'Nếu ghèn khô dính mi, đặt bông ẩm lên một lúc cho mềm rồi mới lau, không cạy.',
              'Ghèn chuyển thành mủ nhiều, mi dính chặt hoặc mắt đỏ: có thể đã nhiễm trùng, cần cho bác sĩ khám để kê thuốc nhỏ mắt.',
              'Bé quá 12 tháng vẫn chảy nước mắt: bác sĩ có thể giới thiệu khám chuyên khoa mắt; một số bé cần thủ thuật thông lệ đạo.',
            ],
          },
          {
            type: 'paragraph',
            text: 'Xoa túi lệ không bắt buộc, và các hướng dẫn chưa giống nhau. AAP cho biết có bác sĩ khuyên làm, có bác sĩ không; nếu làm, dùng đầu tăm bông ấn nhẹ ở góc trong mắt, đẩy nhẹ lên trên, không quá một lần mỗi ngày. Một bệnh viện thuộc NHS (Anh) hướng dẫn dùng ngón tay út đã rửa sạch, ấn nhẹ giữa góc trong mắt và sống mũi rồi vuốt xuống phía miệng, tối đa 10 lần, ngày 2 lần. Child Life khuyên ba mẹ chỉ xoa khi bác sĩ đã chỉ trực tiếp, và làm đúng như bác sĩ hướng dẫn.',
          },
          {
            type: 'heading',
            text: 'Đau mắt đỏ (viêm kết mạc)',
          },
          {
            type: 'paragraph',
            text: 'Đau mắt đỏ làm lòng trắng mắt đỏ hoặc hồng, chảy nước mắt, cộm, có ghèn, thường ở cả hai mắt. Do virus: mắt hồng, chảy nhiều nước, ít mủ, hay đi kèm cảm lạnh; kháng sinh không có tác dụng và bệnh tự khỏi. Do vi khuẩn: nhiều mủ vàng hoặc xanh, mi dính chặt khi ngủ dậy và mủ lại xuất hiện trong ngày; bác sĩ có thể kê thuốc nhỏ mắt kháng sinh. Đau mắt đỏ do dị ứng thì không lây.',
          },
          {
            type: 'bullets',
            items: [
              'Lau sạch ghèn bằng nước đun sôi để nguội trước mỗi lần nhỏ thuốc, vì thuốc khó thấm qua mủ.',
              'Mọi loại thuốc nhỏ mắt, kể cả thuốc kháng sinh, chỉ dùng khi bác sĩ khám và kê đơn. Không dùng thuốc nhỏ mắt của người lớn, của người khác hay lọ đã mở từ lần trước.',
              'Rửa tay sau khi chạm vào mắt bé; dùng khăn mặt, gối riêng; giặt khăn, vỏ gối bằng nước nóng.',
              'Đi nhà trẻ: NHS cho biết trẻ không cần nghỉ trừ khi mệt; AAP gợi ý bé đau mắt có mủ đi học lại khi mủ còn ít, sau 24 giờ nhỏ kháng sinh. Hãy hỏi thêm quy định của nhà trẻ.',
              'Gọi bác sĩ nếu đã nhỏ thuốc hơn 3 ngày mà vẫn còn mủ.',
            ],
          },
          {
            type: 'heading',
            text: 'Những điều không nên làm',
          },
          {
            type: 'paragraph',
            text: 'Ở Việt Nam: một số gia đình nhỏ sữa mẹ, nước lá, nước muối tự pha vào mắt bé, hoặc đắp lá lên mắt. Các hướng dẫn mà bài này tham khảo chỉ khuyên lau mắt bằng nước đun sôi để nguội. Sữa mẹ và nước lá không phải thuốc nhỏ mắt, không chữa được nguyên nhân, có thể mang thêm vi khuẩn vào mắt và làm chậm việc đi khám. Cũng không tự nhỏ thuốc có corticoid hay thuốc không rõ nguồn gốc cho bé.',
          },
          {
            type: 'heading',
            text: 'Những dấu hiệu cần khám gấp',
          },
          {
            type: 'bullets',
            items: [
              'Mi mắt sưng đỏ, nóng, đau, thường ở một bên, có thể kèm sốt: có thể là nhiễm trùng mô quanh mắt, cần khám ngay.',
              'Bé dưới 1 tháng, nhất là 2 tuần đầu sau sinh, có mắt đỏ, nhiều mủ hoặc mi sưng. NHS khuyên bé dưới 30 ngày tuổi có mắt đỏ, có ghèn cần được khám gấp, vì nhiễm trùng mắt mắc phải lúc sinh có thể ảnh hưởng đến mắt nếu chữa chậm.',
              'Mắt bị va đập, trầy xước, có dị vật hoặc dính hoá chất, vôi, chất tẩy rửa: làm theo mục Sơ cứu trẻ em › Tổn thương ở mắt trong Child Life, rồi đưa bé đi khám ngay.',
              'Đồng tử (con ngươi) có ánh trắng thay vì ánh đỏ trên ảnh chụp có đèn flash, hoặc thấy được khi nhìn trong ánh sáng yếu. Hiếm gặp, nhưng có thể là dấu hiệu của u nguyên bào võng mạc; NHS khuyên đặt lịch khám gấp.',
              'Mắt lệch (lác): bé dưới 3 tháng thỉnh thoảng lệch mắt là thường gặp. Mắt lệch liên tục ở bất kỳ tuổi nào, hoặc vẫn lúc lệch lúc không sau 3 tháng tuổi, cần cho bé khám mắt; chữa sớm giúp phòng nhược thị.',
              'Bé đau mắt nhiều, sợ ánh sáng, nhìn mờ, lòng đen (giác mạc) bị đục, hoặc mắt rất đỏ.',
            ],
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'Mẹo nhỏ',
            text: 'Đun sôi nước rồi để nguội trong cốc có nắp, dùng trong ngày. Chuẩn bị sẵn bông gòn sạch và một túi nhỏ để bỏ ngay bông đã dùng, tránh vương ghèn mủ ra gối, đồ chơi của bé.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Gọi 115 hoặc đến cấp cứu ngay khi',
            text: 'Mắt dính hoá chất, vôi, chất tẩy rửa (xối rửa ngay theo mục Sơ cứu trẻ em › Tổn thương ở mắt); mắt bị vật sắc đâm, chảy máu hoặc biến dạng; mi mắt sưng đỏ kèm sốt cao, bé lừ đừ, li bì; bé dưới 3 tháng sốt từ 38 °C. Đừng chờ, gọi 115 ngay.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Đưa bé đi khám trong ngày khi',
            text: 'Bé dưới 1 tháng có mắt đỏ, có mủ hoặc mi sưng; mi mắt đỏ, sưng; có cục đỏ ở góc trong mắt; mắt đau, sợ ánh sáng, nhìn mờ, lòng đen đục; mủ nhiều; đã nhỏ thuốc 3 ngày vẫn còn mủ. Đặt lịch khám mắt sớm khi thấy ánh trắng ở đồng tử hoặc mắt lệch kéo dài.',
          },
        ],
        en: [
          {
            type: 'callout',
            tone: 'note',
            title: 'In short',
            text: 'Most sticky, watery eyes in babies are caused by a blocked tear duct or conjunctivitis and are not serious. Clean the eyes with cooled boiled water, wash your hands well, and only use eye drops a doctor has prescribed. Get urgent help for red swollen eyelids, a baby under 1 month with a red eye and a lot of pus, an eye injury or chemical in the eye, a white glow in the pupil in photos, or an eye that keeps turning.',
          },
          {
            type: 'heading',
            text: 'Blocked tear ducts in newborns',
          },
          {
            type: 'paragraph',
            text: "Tears normally drain through a small duct at the inner corner of the eye into the nose. In about 1 in 10 newborns this duct is not fully open (AAP), sometimes on both sides. The eye waters all the time, even when your baby isn't crying, there is white or yellow sticky discharge in the corner and the lids stick together after sleep, but the white of the eye is not red and the lids are not swollen. Parents often notice it at 1–2 months, when babies make more tears. More than 9 in 10 open by themselves before age 1.",
          },
          {
            type: 'heading',
            text: 'Cleaning the eye and massaging the tear sac',
          },
          {
            type: 'bullets',
            items: [
              "Wash your hands before and after cleaning your baby's eyes.",
              'Dip clean cotton wool in cooled boiled water and wipe gently from the inner corner (by the nose) outwards. Use a fresh piece for each wipe and a separate piece for each eye.',
              "If dried discharge is stuck to the lashes, hold a damp piece on it for a moment to soften it before wiping; don't pick it off.",
              'If the discharge turns to a lot of pus, the lids are stuck shut or the eye is red, it may be infected: have a doctor check and prescribe drops.',
              'Still watering after 12 months: the doctor may refer your child to an eye specialist; some children need a procedure to open the duct.',
            ],
          },
          {
            type: 'paragraph',
            text: "Massaging the tear sac is optional, and guidance differs. The AAP says some doctors recommend it and others don't; if you do it, use a cotton bud to press gently at the inner corner of the eye, pushing slightly upwards, no more than once a day. One NHS hospital (UK) describes using a clean little finger to press gently between the inner corner of the eye and the bridge of the nose, then sliding it down towards the mouth, up to 10 strokes twice a day. Child Life suggests only massaging once a doctor has shown you how, and doing it exactly as they showed you.",
          },
          {
            type: 'heading',
            text: 'Conjunctivitis (pink eye)',
          },
          {
            type: 'paragraph',
            text: "Conjunctivitis makes the white of the eye red or pink, watery, gritty and sticky, usually in both eyes. Viral: pink, very watery, little pus, often with a cold; antibiotics don't help and it gets better by itself. Bacterial: lots of yellow or green pus, lids glued shut after sleep and pus that comes back during the day; the doctor may prescribe antibiotic eye drops. Allergic conjunctivitis is not contagious.",
          },
          {
            type: 'bullets',
            items: [
              "Clean away the discharge with cooled boiled water before each dose of drops, because drops don't work well through pus.",
              "Use any eye drops, including antibiotic drops, only when a doctor has examined your child and prescribed them. Don't use adult eye drops, someone else's, or a bottle opened during an earlier illness.",
              "Wash your hands after touching your child's eyes; use separate face cloths and pillows; wash towels and pillowcases on a hot wash.",
              "Nursery: the NHS says children don't need to stay away unless they feel very unwell; the AAP suggests a child with pus can go back once there is only a little pus, after 24 hours of antibiotic drops. Check your nursery's own rules too.",
              'Call the doctor if there is still pus after more than 3 days of drops.',
            ],
          },
          {
            type: 'heading',
            text: 'What not to do',
          },
          {
            type: 'paragraph',
            text: "In Việt Nam: some families put breast milk, herbal leaf water or homemade salt water in a baby's eye, or place leaves over the eye. The guidance this article follows only advises cleaning with cooled boiled water. Breast milk and leaf water are not eye medicine, don't treat the cause, can bring more germs into the eye and can delay getting care. Also don't use steroid drops or eye drops of unknown origin on your child.",
          },
          {
            type: 'heading',
            text: 'Signs that need urgent care',
          },
          {
            type: 'bullets',
            items: [
              'Red, swollen, hot, painful eyelids, usually on one side, possibly with fever: this may be an infection of the tissue around the eye and needs to be seen now.',
              'A baby under 1 month, especially in the first 2 weeks after birth, with a red eye, a lot of pus or swollen lids. The NHS advises that a baby under 30 days old with red, sticky eyes is seen urgently, because an eye infection picked up at birth can affect the eye if treated late.',
              'An eye that has been hit, scratched, has something in it, or has been splashed with chemicals, lime or cleaning products: follow the Sơ cứu trẻ em (First aid) › Eye injury guide in Child Life, then get your child seen straight away.',
              'A white glow instead of a red reflection in the pupil in flash photos, or seen in dim light. This is rare but can be a sign of retinoblastoma; the NHS advises asking for an urgent appointment.',
              'A turning eye (squint): an eye that wanders now and then is common under 3 months. An eye that turns all the time at any age, or still comes and goes after 3 months, needs an eye check; early treatment helps prevent a lazy eye.',
              'Your child has a lot of eye pain, is bothered by light, has blurred vision, a cloudy cornea (the clear front of the eye), or a very red eye.',
            ],
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'Tip',
            text: "Boil water and let it cool in a covered cup to use that day. Keep clean cotton wool ready and a small bag to throw used pieces away straight away, so discharge doesn't end up on your baby's pillow or toys.",
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Call 115 (Việt Nam) or local emergency services now if',
            text: "A chemical, lime or cleaning product gets in the eye (rinse straight away as in Sơ cứu trẻ em (First aid) › Eye injury); the eye is pierced by something sharp, is bleeding or looks misshapen; red swollen eyelids come with a high fever or your child is listless or very drowsy; or a baby under 3 months has 38 °C or more. Don't wait: call emergency services.",
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'See a doctor the same day if',
            text: 'A baby under 1 month has a red eye, pus or swollen lids; the eyelids are red and swollen; there is a red lump at the inner corner of the eye; the eye hurts, light bothers your child, vision is blurred or the cornea looks cloudy; there is a lot of pus; or there is still pus after 3 days of drops. Book an eye check soon if you notice a white pupil or an eye that keeps turning.',
          },
        ],
      },
      keywords: {
        vi: [
          'ghèn mắt',
          'dử mắt',
          'chảy nước mắt',
          'tắc tuyến lệ',
          'đau mắt đỏ',
          'viêm kết mạc',
          'mắt lác',
          'đồng tử trắng',
        ],
        en: [
          'sticky eye',
          'eye discharge',
          'watery eye',
          'blocked tear duct',
          'pink eye',
          'conjunctivitis',
          'squint',
          'white pupil',
        ],
      },
      relatedArticleIds: [
        'art_cold_cough',
        'art_fever_when_to_call',
        'art_medicine_safety',
        'art_home_safety_falls',
      ],
      milestoneIds: [],
      sources: [
        {
          label: 'HealthyChildren.org (AAP) — Tear duct, blocked (symptom checker)',
          url: 'https://www.healthychildren.org/English/tips-tools/symptom-checker/Pages/symptomviewer.aspx?symptom=Tear+Duct+-+Blocked',
        },
        {
          label: 'HealthyChildren.org (AAP) — Eye, pus or discharge (symptom checker)',
          url: 'https://www.healthychildren.org/English/tips-tools/symptom-checker/Pages/symptomviewer.aspx?symptom=Eye+-+Pus+or+Discharge',
        },
        {
          label: 'Hull University Teaching Hospitals NHS Trust — Blocked tear ducts in babies',
          url: 'https://www.hey.nhs.uk/patient-leaflet/blocked-tear-ducts-in-babies/',
        },
        {
          label: 'NHS — Conjunctivitis',
          url: 'https://www.nhs.uk/conditions/conjunctivitis/',
        },
        {
          label: 'NHS — Symptoms of retinoblastoma',
          url: 'https://www.nhs.uk/conditions/retinoblastoma/symptoms/',
        },
        {
          label: 'NHS — Squint',
          url: 'https://www.nhs.uk/conditions/squint/',
        },
      ],
    },
  },
  {
    id: 'art_starting_childcare',
    reviewerLabel: 'Nhóm chuyên môn · Phát triển trẻ em',
    data: {
      library: 'care',
      topic: 'development',
      format: 'article',
      ageWeeks: {
        from: 26,
        to: 156,
      },
      readingMinutes: 7,
      cover: null,
      title: {
        vi: 'Bé đi nhà trẻ hoặc có người chăm mới: chọn nơi gửi, làm quen và ốm vặt',
        en: 'Starting nursery or a new carer: choosing, settling in and the first colds',
      },
      summary: {
        vi: 'Chọn nơi gửi an toàn, cho bé làm quen dần, chào tạm biệt ngắn gọn và đón đúng hẹn. Vài tháng đầu bé hay ốm vặt; cho bé ở nhà khi sốt, nôn hoặc tiêu chảy.',
        en: 'Choose a safe setting, settle your child in gradually, keep goodbyes short and pick up on time. Expect lots of colds at first; keep your child home with a fever, vomiting or diarrhoea.',
      },
      body: {
        vi: [
          {
            type: 'callout',
            tone: 'note',
            title: 'Tóm tắt nhanh',
            text: 'Chọn nơi có ít trẻ trên mỗi người chăm, cho bé ngủ nằm ngửa, giữ vệ sinh tốt và có quy định rõ về ốm và dị ứng. Cho bé làm quen dần, luôn chào tạm biệt và quay lại đúng hẹn. Bé khóc khi chia tay là bình thường. Vài tháng đầu bé hay ốm vặt; cho bé ở nhà khi sốt, nôn hoặc tiêu chảy.',
          },
          {
            type: 'heading',
            text: 'Chọn nơi gửi: nên hỏi những gì',
          },
          {
            type: 'paragraph',
            text: 'Dù là nhà trẻ, nhóm trẻ gia đình, người giúp việc hay ông bà, ba mẹ nên đến xem vào giờ đang trông trẻ, quan sát cách người chăm nói chuyện, ôm ấp và để trẻ chơi. Hội Nhi khoa Canada khuyên hỏi xem cơ sở có được cấp phép không, ba mẹ có được ghé thăm bất ngờ không, và nói chuyện với phụ huynh đang gửi con ở đó.',
          },
          {
            type: 'bullets',
            items: [
              'Số trẻ trên mỗi người chăm: AAP (Mỹ) khuyên mỗi người chăm tối đa 3 bé dưới 12 tháng, nhóm không quá 6 bé; với bé 13–35 tháng, tối đa 4 bé cho mỗi người, nhóm không quá 8 bé. Quy định mỗi nơi khác nhau; càng ít trẻ trên một người càng tốt.',
              'Ngủ an toàn: bé dưới 1 tuổi được đặt nằm ngửa ở mọi giấc, trên mặt phẳng chắc, không gối, chăn hay thú bông, không ngủ trong ghế ngồi, xe đẩy hay địu. Luôn có người trông, kể cả lúc trẻ ngủ.',
              'Vệ sinh: người chăm rửa tay sau khi thay tã, lau mũi và trước khi cho ăn; chỗ thay tã tách khỏi chỗ chuẩn bị đồ ăn; đồ chơi được rửa thường xuyên.',
              'Khi trẻ ốm: có quy định bằng văn bản về khi nào trẻ phải ở nhà và cách báo cho ba mẹ; chỉ cho trẻ dùng thuốc khi có hướng dẫn rõ ràng, và ghi lại giờ cho thuốc.',
              'Dị ứng và bệnh mạn tính: hỏi cách họ tránh thực phẩm bé bị dị ứng, ai biết dùng thuốc cấp cứu nếu bé được bác sĩ kê, và có kế hoạch xử trí bằng văn bản không.',
              'An toàn: người chăm được học sơ cứu và hồi sức tim phổi cho trẻ; chỉ người lớn đã đăng ký mới được đón bé; nơi trông trẻ không có khói thuốc, kể cả thuốc lá điện tử.',
              'Người chăm ổn định: hỏi người chăm làm ở đây bao lâu và ai thay khi họ nghỉ. Trẻ nhỏ gắn bó tốt hơn với một vài người quen thuộc.',
            ],
          },
          {
            type: 'paragraph',
            text: 'Ở Việt Nam: nhà trẻ, trường mầm non công lập, dân lập và tư thục cần được chính quyền cấp xã, phường cho phép thành lập và cho phép hoạt động giáo dục. Ba mẹ có thể đề nghị xem quyết định này, hoặc hỏi Ủy ban nhân dân xã, phường nơi cơ sở đặt địa điểm. Với người trông trẻ tại nhà, hãy tìm hiểu kỹ như với một cơ sở: kinh nghiệm, người giới thiệu, cách cho bé ngủ và cho bé ăn.',
          },
          {
            type: 'heading',
            text: 'Làm quen dần, chào tạm biệt rõ ràng',
          },
          {
            type: 'paragraph',
            text: 'Hội Nhi khoa Canada khuyên chuyển tiếp từ từ để nơi mới trở nên quen thuộc trước ngày đầu tiên ở cả ngày, và chuẩn bị tinh thần rằng bé cần vài ngày đến vài tuần để thích nghi.',
          },
          {
            type: 'bullets',
            items: [
              'Những ngày đầu: ở lại cùng bé một lúc, sau đó để bé lại một thời gian ngắn, rồi tăng dần. Nếu được, cho bé bắt đầu đi trước khi ba mẹ đi làm lại một, hai tuần.',
              'Mang theo một món đồ quen từ nhà, như khăn nhỏ hay đồ chơi, nếu nơi gửi cho phép. Với bé dưới 1 tuổi, không để đồ này trong chỗ ngủ.',
              'Giữ một nghi thức tạm biệt ngắn, giống nhau mỗi ngày: ôm, hôn, vẫy tay và nói khi nào ba mẹ quay lại, ví dụ “Ngủ trưa dậy, ăn chiều xong là mẹ đón”.',
              'Luôn chào trước khi đi, đừng lén đi lúc bé không để ý. Lén đi có thể khiến bé hoảng hơn và khó tin tưởng hơn ở những lần sau.',
              'Chào xong thì đi, đừng quay lại nhiều lần. Phần lớn trẻ nín sau khi ba mẹ đi ít phút; ba mẹ có thể nhắn hỏi người chăm.',
              'Đón đúng giờ, rồi dành thời gian âu yếm, chơi cùng bé khi về nhà. Hỏi người chăm về ngày của bé: ăn, ngủ, chơi và tâm trạng.',
            ],
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'Bé khóc khi chia tay là bình thường',
            text: 'Từ khoảng 6–8 tháng đến 2 tuổi, nhiều bé sợ xa ba mẹ và dè chừng người lạ. Đây là dấu hiệu bé gắn bó với ba mẹ, không phải ba mẹ làm sai. Nếu sau vài tuần bé vẫn rất sợ hãi khi đến nơi gửi, ăn ngủ kém kéo dài, hoặc sợ một người cụ thể, hãy nói chuyện với người chăm và cân nhắc lại lựa chọn.',
          },
          {
            type: 'heading',
            text: 'Thông tin cần giao cho người chăm',
          },
          {
            type: 'bullets',
            items: [
              'Sổ tiêm chủng: cho bé tiêm đủ mũi và đúng hẹn trước khi đi nhà trẻ. Tiêm chủng là cách tốt nhất bảo vệ bé khỏi các bệnh dễ lây như sởi, thuỷ đậu và cúm.',
              'Nếp sinh hoạt: tên gọi ở nhà, giờ ngủ và cách dỗ ngủ, giờ ăn, lượng sữa, cách hâm sữa mẹ trữ, món bé chưa ăn hoặc không ăn được.',
              'Sức khoẻ: dị ứng, bệnh mạn tính, thuốc đang dùng, và kế hoạch xử trí cấp cứu do bác sĩ viết nếu có.',
              'Liên lạc: số điện thoại của ba mẹ và hai người lớn khác, phòng khám hoặc bác sĩ của bé, và danh sách những người được phép đón bé.',
              'Đồ dùng: quần áo dự phòng, tã, khăn, bình sữa hoặc cốc, tất cả ghi tên bé.',
            ],
          },
          {
            type: 'heading',
            text: 'Vài tháng đầu: bé ốm vặt nhiều hơn',
          },
          {
            type: 'paragraph',
            text: 'Theo Hội Nhi khoa Canada, phần lớn trẻ nhỏ bị cảm lạnh 8–10 lần mỗi năm, và trẻ ít ốm dần khi lớn hơn. Khi mới đi nhà trẻ, bé gặp nhiều virus mới nên có thể ốm nối tiếp nhau trong mùa đầu. Rửa tay cho bé và cả nhà khi đón bé về, tiêm chủng đủ và cho bé ngủ đủ giúp hạn chế lây bệnh.',
          },
          {
            type: 'heading',
            text: 'Khi nào nên cho bé ở nhà',
          },
          {
            type: 'paragraph',
            text: 'Các tổ chức có mốc hơi khác nhau. Bài này theo cách thận trọng hơn, kết hợp hướng dẫn của AAP (Mỹ) và NHS (Anh). Luôn làm theo cả quy định riêng của nơi gửi trẻ.',
          },
          {
            type: 'bullets',
            items: [
              'Sốt: cho bé ở nhà đến khi đã hết sốt ít nhất 24 giờ mà không cần dùng thuốc hạ sốt (AAP). Đừng cho thuốc hạ sốt để bé đi học được.',
              'Nôn hoặc tiêu chảy: cho bé ở nhà đến khi đã hết nôn và tiêu chảy ít nhất 48 giờ (NHS). Mốc này chặt hơn mốc của AAP.',
              'Phát ban kèm sốt hoặc bé khác thường: cho bé ở nhà đến khi được bác sĩ khám và loại trừ bệnh lây. Ban không mất màu khi ấn cốc thuỷ tinh lên cần đi cấp cứu ngay.',
              'Bé mệt, quấy nhiều, thở khó hoặc không thể chơi, sinh hoạt như bình thường, dù không sốt.',
              'Thuỷ đậu: ở nhà đến khi tất cả nốt đã đóng vảy. Vết loét da chảy dịch không che kín được, và các bệnh lây khác đã được chẩn đoán: hỏi bác sĩ và nơi gửi trẻ khi nào bé đi lại được.',
              'Sổ mũi, ho nhẹ, không sốt và bé vẫn chơi được: theo AAP và NHS, thường không cần nghỉ.',
            ],
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'Lên kế hoạch cho ngày bé ốm',
            text: 'Bé đi nhà trẻ sẽ có những ngày phải nghỉ. Hãy tính trước ai trông bé khi bé ốm, để không phải gửi bé khi chưa khoẻ.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Khi nào nên đưa bé đi khám',
            text: 'Gọi 115 hoặc đến cấp cứu ngay khi bé khó thở, tím tái, li bì khó đánh thức, co giật, hoặc có ban không mất màu khi ấn cốc. Đưa bé đi khám trong ngày khi bé sốt từ 5 ngày trở lên, ăn uống kém, ít tã ướt, nôn nhiều; khi bé ốm nối tiếp mà ngày càng mệt hơn; hoặc khi bé thay đổi rõ sau khi có người chăm mới, như sợ hãi một người cụ thể, thu mình, có vết bầm hay vết thương không rõ lý do.',
          },
        ],
        en: [
          {
            type: 'callout',
            tone: 'note',
            title: 'In short',
            text: 'Choose a setting with few children per carer, back-to-sleep for babies, good hygiene and clear rules on illness and allergies. Settle your child in gradually, always say goodbye and come back when you said you would. Crying at drop-off is normal. Expect lots of minor illnesses in the first months; keep your child home with a fever, vomiting or diarrhoea.',
          },
          {
            type: 'heading',
            text: 'Choosing care: what to ask',
          },
          {
            type: 'paragraph',
            text: 'Whether it is a nursery, a home-based carer, a nanny or grandparents, visit while children are being cared for and watch how the carers talk to, comfort and play with them. The Canadian Paediatric Society suggests asking whether the setting is licensed and whether you can drop in unannounced, and talking to parents whose children already go there.',
          },
          {
            type: 'bullets',
            items: [
              'Children per carer: the AAP (US) recommends no more than 3 babies under 12 months per carer, in groups of up to 6; for 13–35 months, no more than 4 per carer, in groups of up to 8. Rules differ by country; the fewer children per adult, the better.',
              'Safe sleep: babies under 1 are put down on their back for every sleep, on a firm flat surface with no pillows, blankets or soft toys, and not left to sleep in seats, buggies or slings. Children are supervised at all times, including while asleep.',
              'Hygiene: carers wash their hands after nappy changes and wiping noses and before handling food; the changing area is separate from where food is prepared; toys are cleaned regularly.',
              'Illness: there is a written policy on when children must stay home and how parents are contacted; medicine is only given with clear written instructions, and the time is recorded.',
              'Allergies and long-term conditions: ask how they keep your child away from foods they are allergic to, who can give emergency medicine if your child has been prescribed it, and whether there is a written action plan.',
              'Safety: carers are trained in first aid and child CPR; only registered adults can collect your child; the setting is smoke-free and vape-free.',
              'Stable carers: ask how long staff have been there and who covers when they are away. Young children settle best with a few familiar people.',
            ],
          },
          {
            type: 'paragraph',
            text: "In Việt Nam: public and private nurseries and kindergartens need permission from the commune or ward authorities to be set up and to provide care and education. You can ask to see this decision, or check with the local commune or ward People's Committee. With a carer who looks after children at home, check just as carefully: experience, references, and how they handle sleep and feeding.",
          },
          {
            type: 'heading',
            text: 'Settle in gradually, say a clear goodbye',
          },
          {
            type: 'paragraph',
            text: 'The Canadian Paediatric Society advises a gradual start so the new place feels familiar before the first full day, and to expect a settling-in period of days or weeks.',
          },
          {
            type: 'bullets',
            items: [
              'The first days: stay with your child for a while, then leave them for a short time, and build up gradually. If you can, start a week or two before you go back to work.',
              'Bring a familiar comforter from home, such as a small cloth or toy, if the setting allows. For babies under 1, keep it out of the cot.',
              "Keep a short goodbye ritual that is the same every day: a hug, a kiss, a wave, and when you will be back, such as “After your nap and snack, I'll come and get you”.",
              "Always say goodbye; don't slip away while your child isn't looking. Sneaking off can make children more upset and less trusting next time.",
              "Once you have said goodbye, leave; don't keep coming back. Most children calm down a few minutes after their parent goes, and you can message the carer to check.",
              "Pick up on time, then make time for cuddles and play at home. Ask the carer about your child's day: eating, sleeping, play and mood.",
            ],
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'Crying at goodbye is normal',
            text: 'From around 6–8 months to 2 years, many children fear being apart from their parents and are wary of strangers. It is a sign of a healthy bond, not something you did wrong. If after a few weeks your child is still very frightened of going, is eating or sleeping poorly, or fears one particular person, talk to the carer and think again about the arrangement.',
          },
          {
            type: 'heading',
            text: 'Information to hand over to the carer',
          },
          {
            type: 'bullets',
            items: [
              "Vaccination record: make sure your child's vaccines are up to date before starting. Vaccines are the best protection against easily spread illnesses such as measles, chickenpox and flu.",
              "Daily routine: the name your child is called at home, nap times and how they settle, mealtimes, milk amounts, how to warm stored breast milk, and foods your child hasn't had yet or can't eat.",
              "Health: allergies, long-term conditions, current medicines, and any written emergency plan from your child's doctor.",
              "Contacts: phone numbers for both parents and two other adults, your child's clinic or doctor, and a list of who may collect your child.",
              "Supplies: spare clothes, nappies, cloths, and bottles or cups, all labelled with your child's name.",
            ],
          },
          {
            type: 'heading',
            text: 'The first months: more minor illnesses',
          },
          {
            type: 'paragraph',
            text: 'According to the Canadian Paediatric Society, most young children have 8–10 colds a year, and they get ill less often as they grow. When children start nursery they meet many new viruses, so one illness may follow another in the first season. Washing hands for your child and the whole family after pick-up, keeping vaccines up to date and good sleep all help to limit the spread.',
          },
          {
            type: 'heading',
            text: 'When to keep your child at home',
          },
          {
            type: 'paragraph',
            text: "Organisations set slightly different rules. This article follows the more cautious option, combining AAP (US) and NHS (UK) advice. Always follow your setting's own policy as well.",
          },
          {
            type: 'bullets',
            items: [
              "Fever: keep your child home until they have had no fever for at least 24 hours without fever medicine (AAP). Don't give fever medicine so they can go in.",
              'Vomiting or diarrhoea: keep your child home until 48 hours after the last episode (NHS). This is stricter than the AAP rule.',
              'A rash with fever or a change in behaviour: keep your child home until a doctor has checked them and ruled out an infection that spreads. A rash that does not fade under a pressed glass needs emergency care.',
              "Your child is tired, very unsettled, has trouble breathing or can't join in normal activities, even without a fever.",
              "Chickenpox: stay home until every spot has crusted over. For weeping skin sores that can't be covered, and other diagnosed infections, ask the doctor and the setting when your child can return.",
              'A runny nose or mild cough with no fever, and your child is playing as usual: AAP and NHS advice is that they usually do not need to stay home.',
            ],
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'Plan for sick days',
            text: 'A child at nursery will have days at home. Plan ahead for who will look after them when they are ill, so you are not forced to send them in before they are well.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'When to see a doctor',
            text: 'Call emergency services or go to the emergency department straight away if your child struggles to breathe, turns blue, is floppy or hard to wake, has a fit, or has a rash that does not fade under a glass. See a doctor the same day for a fever lasting 5 days or more, poor eating or drinking, fewer wet nappies or a lot of vomiting; if one illness follows another and your child seems more and more unwell; or if your child changes clearly after starting with a new carer, such as fearing one person, withdrawing, or having unexplained bruises or injuries.',
          },
        ],
      },
      keywords: {
        vi: [
          'đi nhà trẻ',
          'người trông trẻ',
          'làm quen nhà trẻ',
          'sợ xa ba mẹ',
          'ốm vặt',
          'nghỉ học khi ốm',
          'tỷ lệ trẻ trên cô',
          'tiêm chủng',
        ],
        en: [
          'nursery',
          'childcare',
          'settling in',
          'separation anxiety',
          'frequent colds',
          'keeping child home sick',
          'staff ratio',
          'vaccinations',
        ],
      },
      relatedArticleIds: [
        'art_separation_anxiety',
        'art_cold_cough',
        'art_fever_when_to_call',
        'art_diarrhoea_dehydration',
      ],
      milestoneIds: ['stranger_wariness', 'knows_familiar_faces', 'waves_bye'],
      sources: [
        {
          label: 'HealthyChildren.org (AAP) — Choosing a child care center',
          url: 'https://www.healthychildren.org/English/family-life/work-and-child-care/Pages/choosing-a-child-care-center.aspx',
        },
        {
          label: 'HealthyChildren.org (AAP) — When to keep your child home from child care',
          url: 'https://www.healthychildren.org/English/family-life/work-and-child-care/Pages/when-to-keep-your-child-home-from-child-care.aspx',
        },
        {
          label:
            'Caring for Kids (Canadian Paediatric Society) — Child care: making the best choice for your family',
          url: 'https://caringforkids.cps.ca/handouts/behavior-and-development/child_care',
        },
        {
          label: 'Caring for Kids (Canadian Paediatric Society) — Common infections and your child',
          url: 'https://caringforkids.cps.ca/handouts/health-conditions-and-treatments/common_infections_and_your_child',
        },
        {
          label: 'NHS — Is my child too ill for school?',
          url: 'https://www.nhs.uk/live-well/is-my-child-too-ill-for-school/',
        },
        {
          label:
            'Cổng thông tin Chính phủ — Chủ tịch UBND cấp xã có thẩm quyền thành lập trường mầm non, tiểu học, trung học cơ sở',
          url: 'https://xaydungchinhsach.chinhphu.vn/chu-tich-ubnd-cap-xa-co-tham-quyen-thanh-lap-truong-mam-non-tieu-hoc-trung-hoc-co-so-119250614082831617.htm',
        },
      ],
    },
  },
  {
    id: 'art_flat_head',
    reviewerLabel: 'Nhóm chuyên môn · Nhi khoa',
    data: {
      library: 'care',
      topic: 'development',
      format: 'article',
      ageWeeks: {
        from: 0,
        to: 52,
      },
      readingMinutes: 5,
      cover: null,
      title: {
        vi: 'Bé bị bẹp đầu, vẹo cổ: phòng ngừa, cho bé nằm sấp và khi nào cần khám',
        en: 'Flat head and a tight neck: prevention, tummy time and when to see a doctor',
      },
      summary: {
        vi: 'Bẹp đầu do tư thế rất hay gặp, không hại não và thường đỡ dần. Vẫn luôn cho bé ngủ nằm ngửa; cho nằm sấp khi thức, đổi tư thế, bế nhiều hơn. Không dùng gối chống bẹp đầu.',
        en: "A flat spot from lying in one position is common, does not harm the brain and usually improves. Keep back-sleeping; add tummy time, change positions and hold your baby more. Don't use head-shaping pillows.",
      },
      body: {
        vi: [
          {
            type: 'callout',
            tone: 'note',
            title: 'Tóm tắt nhanh',
            text: 'Đầu bé bị bẹp một bên hoặc phía sau rất hay gặp, không ảnh hưởng tới não và thường đỡ dần khi bé lớn. Vẫn luôn cho bé ngủ nằm ngửa. Cho bé nằm sấp khi thức, đổi hướng nằm, bế bé nhiều hơn và hạn chế thời gian trong ghế. Không dùng gối chống bẹp đầu. Cho bác sĩ xem nếu bé luôn nghiêng đầu một bên hoặc dáng đầu bất thường.',
          },
          {
            type: 'heading',
            text: 'Vì sao đầu bé bị bẹp?',
          },
          {
            type: 'paragraph',
            text: 'Xương sọ của bé nhỏ còn mềm nên dễ phẳng đi ở chỗ bé hay tì lên. Có thể bẹp một bên phía sau, làm tai và trán bên đó hơi lệch ra trước, hoặc bẹp đều cả phía sau khiến đầu trông rộng. Theo AAP, phần lớn trường hợp xuất hiện trong khoảng 4–12 tuần đầu. Bé sinh non, sinh đôi, hay quay đầu về một phía, hoặc ít được nằm sấp dễ gặp hơn. Bẹp đầu do tư thế chỉ ảnh hưởng dáng đầu, không làm hại não hay trí tuệ của bé.',
          },
          {
            type: 'paragraph',
            text: 'Vẹo cổ là khi cơ ở một bên cổ bị căng, ngắn, khiến bé hay nghiêng đầu về một vai và khó quay sang phía còn lại. Vì bé luôn tì đầu một bên, đầu dễ bị bẹp bên đó. AAP cho biết vẹo cổ bẩm sinh thường được phát hiện trong 6–8 tuần đầu, đôi khi sờ thấy một cục nhỏ ở cơ cổ. Bác sĩ có thể hướng dẫn ba mẹ các động tác kéo giãn nhẹ nhàng hoặc giới thiệu bé đến chuyên viên vật lý trị liệu. Điều trị sớm cho kết quả tốt hơn.',
          },
          {
            type: 'heading',
            text: 'Ngủ nằm ngửa: không thay đổi vì bẹp đầu',
          },
          {
            type: 'paragraph',
            text: 'Đặt bé nằm ngửa ở mọi giấc ngủ là cách quan trọng nhất để giảm nguy cơ đột tử ở trẻ nhỏ. NHS (Anh) nhấn mạnh không đổi sang cho bé ngủ sấp hay ngủ nghiêng để tránh bẹp đầu. Dáng đầu có thể cải thiện dần; còn đột tử thì không thể cứu vãn.',
          },
          {
            type: 'heading',
            text: 'Những việc ba mẹ làm được mỗi ngày',
          },
          {
            type: 'bullets',
            items: [
              'Cho bé nằm sấp khi thức và có người lớn ngay bên cạnh, từ những ngày đầu: vài phút mỗi lần, nhiều lần trong ngày. AAP khuyên tăng dần đến tổng cộng 15–30 phút mỗi ngày khi bé khoảng 7 tuần, và nhiều hơn khi bé lớn.',
              'Đổi hướng nằm: luân phiên đặt đầu bé ở hai đầu nôi theo từng ngày, để bé quay sang các phía khác nhau khi nhìn ba mẹ, cửa sổ hay ánh đèn. Bé vẫn nằm ngửa.',
              'Đổi tay bế và bên cho bú, kể cả khi bú bình, để bé quay đầu luân phiên hai bên.',
              'Khi bé thức và nằm ngửa, đặt đồ chơi, nói chuyện với bé ở phía bé ít quay sang.',
              'Bế bé thẳng người hoặc địu đúng cách nhiều hơn, để đầu bé không tì lâu lên mặt phẳng.',
              'Hạn chế thời gian bé nằm trong ghế ô tô, ghế rung, xích đu và xe đẩy dạng ghế. Ghế ô tô là để đi xe; tới nơi thì bế bé ra. Nếu bé ngủ thiếp trong ghế, chuyển bé sang nằm ngửa trong nôi.',
              'Kiểm tra dáng đầu sau khi tắm, lúc tóc còn ướt: nhìn từ trên xuống, phía sau đầu nên tròn đều, hai tai ngang nhau, trán và hai bên đầu cân đối.',
            ],
          },
          {
            type: 'paragraph',
            text: 'Ở Việt Nam: gối chống bẹp đầu, gối lõm, gối hạt và đệm chặn hai bên vẫn được bán rộng rãi và hay được người thân khuyên dùng. Các loại này không được khuyến nghị.',
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'Không dùng gối chống bẹp đầu',
            text: 'Gối chống bẹp đầu và các loại đệm định hình không giúp phòng bẹp đầu mà có thể làm bé ngạt thở. AAP khuyên bé ngủ trên mặt phẳng chắc, không gối, không chăn, không thú bông, và cho biết FDA (Mỹ) không thấy bằng chứng các loại gối này có tác dụng. Đặt bé nằm thẳng trên nệm phẳng, không kê gì dưới đầu.',
          },
          {
            type: 'heading',
            text: 'Mũ chỉnh hình đầu: quyết định của bác sĩ chuyên khoa',
          },
          {
            type: 'paragraph',
            text: 'Theo NHS, bẹp đầu thường đỡ dần trong 1–2 năm đầu khi bé ngồi, bò và ít nằm hơn. Với trường hợp bẹp vừa hoặc nặng không cải thiện khi đã đổi tư thế đến khoảng 5–6 tháng, AAP cho biết có thể cân nhắc mũ chỉnh hình do chuyên gia đo và làm riêng; mũ phải đội gần như cả ngày trong nhiều tháng. NHS thì không cung cấp mũ vì chưa đủ bằng chứng mũ có hiệu quả. Vì bằng chứng chưa thống nhất, đây là quyết định cần bác sĩ chuyên khoa khám và trao đổi kỹ với ba mẹ, không nên tự mua.',
          },
          {
            type: 'heading',
            text: 'Khi dáng đầu méo không phải do tư thế',
          },
          {
            type: 'paragraph',
            text: 'Hiếm hơn, đầu méo là do dính khớp sọ sớm: các đường nối giữa xương sọ liền lại quá sớm. Tình trạng này không đỡ khi đổi tư thế và thường cần phẫu thuật. Hãy cho bác sĩ xem nếu thấy:',
          },
          {
            type: 'bullets',
            items: [
              'Một gờ cứng sờ thấy dọc theo đường nối xương sọ, ví dụ trên đỉnh đầu hoặc giữa trán.',
              'Dáng đầu bất thường từ lúc mới sinh và không tròn lại sau vài tuần, như đầu dài và hẹp, trán nhọn hình tam giác, hoặc một bên trán và lông mày bị kéo lên.',
              'Thóp trước không còn sờ thấy sớm, trước 1 tuổi, hoặc kích thước đầu bé có vẻ khác thường so với tuổi.',
              'Dáng đầu ngày càng méo hơn dù ba mẹ đã đổi tư thế và cho bé nằm sấp đều đặn.',
            ],
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Khi nào nên đưa bé đi khám',
            text: 'Bé luôn nghiêng đầu về một bên hoặc khó quay đầu sang một phía; bé chỉ chịu nhìn hay bú một bên dù đã được khuyến khích bên kia; sờ thấy cục ở cổ; độ nghiêng không đỡ sau vài tuần tập; đầu bẹp ngày càng rõ, hai bên mặt trông lệch, hoặc có dấu hiệu dính khớp sọ ở trên. Bé lớn hơn đột ngột bị vẹo cổ kèm đau, sốt hoặc không chịu cử động cổ cần được khám ngay.',
          },
        ],
        en: [
          {
            type: 'callout',
            tone: 'note',
            title: 'In short',
            text: "A flat spot on one side or the back of the head is very common, does not affect the brain and usually improves as your baby grows. Always put your baby to sleep on their back. Give tummy time while awake, vary their position, hold them more and limit time in seats. Don't use head-shaping pillows. See a doctor if your baby always tilts their head or their head shape looks unusual.",
          },
          {
            type: 'heading',
            text: 'Why do babies get a flat head?',
          },
          {
            type: 'paragraph',
            text: "A young baby's skull is soft, so it flattens where it rests most. The flat spot may be on one side at the back, pushing the ear and forehead on that side slightly forward, or across the whole back, making the head look wide. According to the AAP, most cases appear between 4 and 12 weeks. Premature babies, twins, babies who prefer turning one way and babies who get little tummy time are more likely to have it. A positional flat head affects only the shape, not the brain or your baby's development.",
          },
          {
            type: 'paragraph',
            text: 'Torticollis is when a muscle on one side of the neck is tight and short, so the baby tilts their head towards one shoulder and finds it hard to turn the other way. Because the head always rests on one side, that side tends to flatten. The AAP says congenital torticollis is usually noticed in the first 6–8 weeks, sometimes with a small lump in the neck muscle. A doctor may show you gentle stretches or refer your baby to a physiotherapist. Starting early gives better results.',
          },
          {
            type: 'heading',
            text: "Back to sleep: don't change it because of a flat spot",
          },
          {
            type: 'paragraph',
            text: 'Placing your baby on their back for every sleep is the most important way to lower the risk of sudden infant death. The NHS (UK) stresses that you should not switch to tummy or side sleeping to prevent a flat head. Head shape can improve over time; sudden infant death cannot be undone.',
          },
          {
            type: 'heading',
            text: 'What you can do every day',
          },
          {
            type: 'bullets',
            items: [
              'Give tummy time while your baby is awake and an adult is right there, from the first days: a few minutes at a time, several times a day. The AAP suggests building up to 15–30 minutes in total a day by about 7 weeks, and more as your baby grows.',
              "Change direction: alternate which end of the cot your baby's head is at each day, so they turn different ways to look at you, the window or the light. They still sleep on their back.",
              'Switch the arm you hold your baby in and the side you feed from, including bottle feeds, so they turn their head both ways.',
              'When your baby is awake on their back, put toys and talk to them on the side they turn to less.',
              'Hold your baby upright or carry them in a sling used safely more often, so the head is not resting on a flat surface for long.',
              'Limit time in car seats, bouncers, swings and seat-style buggies. A car seat is for travelling; take your baby out when you arrive. If they fall asleep in a seat, move them onto their back in the cot.',
              "Check your baby's head after a bath, when the hair is wet: looking from above, the back should be evenly round, the ears level, and the forehead and sides balanced.",
            ],
          },
          {
            type: 'paragraph',
            text: 'In Việt Nam: head-shaping pillows, pillows with a hollow, filled pillows and side wedges are widely sold and often recommended by relatives. None of these is recommended.',
          },
          {
            type: 'callout',
            tone: 'tip',
            title: "Don't use head-shaping pillows",
            text: 'Head-shaping pillows and positioning cushions do not prevent a flat head and can cause suffocation. The AAP advises a firm, flat sleep surface with no pillows, blankets or soft toys, and notes that the US FDA has found no evidence these pillows work. Lay your baby on a flat mattress with nothing under the head.',
          },
          {
            type: 'heading',
            text: 'Helmets: a decision for a specialist',
          },
          {
            type: 'paragraph',
            text: 'According to the NHS, a flat head usually improves over 1–2 years as babies sit, crawl and spend less time lying down. For moderate or severe flattening that has not improved with repositioning by about 5–6 months, the AAP says a custom helmet fitted by a specialist may be considered; it is worn almost all day for several months. The NHS does not provide helmets because there is not enough evidence that they work. As the evidence is mixed, this is a decision for a specialist to make with you after an examination, not something to buy yourself.',
          },
          {
            type: 'heading',
            text: 'When an unusual head shape is not positional',
          },
          {
            type: 'paragraph',
            text: 'Less often, an unusual head shape is caused by craniosynostosis, when the seams between the skull bones join too early. It does not improve with repositioning and usually needs surgery. Show a doctor if you notice:',
          },
          {
            type: 'bullets',
            items: [
              'A hard ridge along a seam of the skull, for example over the top of the head or down the middle of the forehead.',
              'An unusual shape from birth that does not round out after a few weeks, such as a long narrow head, a pointed triangular forehead, or one side of the forehead and eyebrow pulled up.',
              "The soft spot can no longer be felt early, before 1 year, or your baby's head size seems unusual for their age.",
              'A shape that keeps getting worse even though you have been changing positions and doing tummy time regularly.',
            ],
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'When to see a doctor',
            text: 'Your baby always tilts their head to one side or has trouble turning one way; they will only look or feed to one side despite encouragement; you feel a lump in the neck; the tilt does not improve after a few weeks of exercises; the flat spot is getting worse, the face looks uneven, or you see any of the craniosynostosis signs above. An older baby who suddenly develops a painful tilted neck, a fever, or will not move their neck needs to be seen straight away.',
          },
        ],
      },
      keywords: {
        vi: [
          'bẹp đầu',
          'méo đầu',
          'vẹo cổ',
          'nằm sấp',
          'gối chống bẹp đầu',
          'mũ chỉnh hình đầu',
          'dính khớp sọ',
          'ngủ nằm ngửa',
        ],
        en: [
          'flat head',
          'plagiocephaly',
          'torticollis',
          'tummy time',
          'head-shaping pillow',
          'helmet therapy',
          'craniosynostosis',
          'back to sleep',
        ],
      },
      relatedArticleIds: [
        'art_tummy_time',
        'art_safe_sleep',
        'art_car_motorbike',
        'art_preterm_corrected_age',
      ],
      milestoneIds: ['lifts_head', 'pushes_up_arms'],
      sources: [
        {
          label: 'NHS — Flat head syndrome (plagiocephaly and brachycephaly)',
          url: 'https://www.nhs.uk/conditions/plagiocephaly-brachycephaly/',
        },
        {
          label:
            "HealthyChildren.org (AAP) — When a baby's head is misshapen: positional skull deformities",
          url: 'https://www.healthychildren.org/English/health-issues/conditions/Cleft-Craniofacial/Pages/Positional-Skull-Deformities-and-Torticollis.aspx',
        },
        {
          label: 'HealthyChildren.org (AAP) — Head tilt (torticollis)',
          url: 'https://www.healthychildren.org/english/health-issues/conditions/cleft-craniofacial/pages/head-tilt.aspx',
        },
        {
          label: 'HealthyChildren.org (AAP) — Uneven head shape in babies: craniosynostosis',
          url: 'https://www.healthychildren.org/English/health-issues/conditions/Cleft-Craniofacial/Pages/Uneven-Head-Shape-Craniosynostosis.aspx',
        },
        {
          label: 'NHS — Craniosynostosis',
          url: 'https://www.nhs.uk/conditions/craniosynostosis/',
        },
        {
          label:
            'HealthyChildren.org (AAP) — Safe sleep: back is best, avoid soft bedding, inclined surfaces and bed sharing',
          url: 'https://www.healthychildren.org/English/news/Pages/safe-sleep-back-is-best-avoid-soft-bedding-inclined-surfaces-and-bedsharing.aspx',
        },
      ],
    },
  },
  {
    id: 'art_first_steps',
    reviewerLabel: 'Nhóm chuyên môn · Phát triển trẻ em',
    data: {
      library: 'care',
      topic: 'development',
      format: 'article',
      ageWeeks: {
        from: 36,
        to: 104,
      },
      readingMinutes: 5,
      cover: null,
      title: {
        vi: 'Bé tập đi: mốc bình thường, giày dép, xe tập đi và khi nào cần khám',
        en: 'Learning to walk: the normal range, first shoes, baby walkers and when to check',
      },
      summary: {
        vi: 'Trẻ khoẻ mạnh tự đi trong khoảng 8 đến gần 18 tháng. Cho bé chân trần trong nhà, không dùng xe tập đi có bánh, chắn cầu thang, và cho bé đi khám nếu 18 tháng chưa tự đi.',
        en: "Healthy children take their first steps anywhere from about 8 to nearly 18 months. Go barefoot indoors, skip wheeled baby walkers, gate the stairs, and see a doctor if your child isn't walking by 18 months.",
      },
      body: {
        vi: [
          {
            type: 'callout',
            tone: 'note',
            title: 'Tóm tắt nhanh',
            text: 'Mỗi bé đi những bước đầu tiên vào một thời điểm khác nhau; theo WHO, trẻ khoẻ mạnh tự đi trong khoảng 8 đến gần 18 tháng. Cho bé chơi nhiều trên sàn và đi chân trần trong nhà. Không dùng xe tập đi có bánh xe. Chân bẹt và chân hơi vòng kiềng ở tuổi này thường là bình thường. Cho bé đi khám nếu 18 tháng bé chưa tự đi, hoặc bé mất kỹ năng đã có.',
          },
          {
            type: 'heading',
            text: 'Bé tập đi qua từng giai đoạn',
          },
          {
            type: 'paragraph',
            text: 'Trước khi đi, bé thường ngồi vững, bò hoặc trườn, vịn đồ để đứng lên, rồi vịn ghế, bàn đi ngang (đi men). Có bé không bò mà lết mông rồi đi luôn; điều này thường không đáng lo nếu bé vẫn tiến bộ đều. Những bước đầu tiên bé thường dạng chân rộng, giơ tay cao để giữ thăng bằng và hay ngã ngồi.',
          },
          {
            type: 'paragraph',
            text: 'Nghiên cứu của WHO trên trẻ khoẻ mạnh ở năm quốc gia cho thấy khoảng bình thường rất rộng: vịn đồ đi được trong khoảng 6–14 tháng, tự đứng một mình khoảng 7–17 tháng, và tự đi khoảng 8–18 tháng. CDC (Mỹ) dùng mốc phần lớn trẻ đã tự đi không cần vịn lúc 18 tháng. Với bé sinh non, hãy tính theo tuổi hiệu chỉnh.',
          },
          {
            type: 'heading',
            text: 'Giúp bé tập đi',
          },
          {
            type: 'bullets',
            items: [
              'Cho bé nhiều thời gian chơi trên sàn sạch, an toàn để bé tự bò, vịn và đứng dậy. Không cần ép bé đứng hay dắt tay bé đi thật lâu.',
              'Xếp đồ đạc chắc chắn gần nhau để bé đi men, và đặt đồ chơi xa một chút để bé có lý do bước tới.',
              'Xe đẩy đồ chơi có tay cầm, chắc, khó lật có thể dùng khi bé đã tự đứng được, và luôn có người lớn trông.',
              'Trong nhà, để bé đi chân trần: bé cảm nhận mặt sàn, các cơ bàn chân được vận động, và ít trơn trượt hơn đi tất.',
            ],
          },
          {
            type: 'heading',
            text: 'Chọn đôi giày đầu tiên',
          },
          {
            type: 'paragraph',
            text: 'AAP cho biết bàn chân bé phát triển tốt nhất khi không bị bó trong giày. Giày chủ yếu để bảo vệ chân khi bé đi ngoài trời, trên mặt đất nóng, sỏi đá hoặc có vật sắc.',
          },
          {
            type: 'bullets',
            items: [
              'Đế mềm, dẻo, có rãnh chống trơn; mũi giày đủ rộng để các ngón chân cử động.',
              'Vừa chân: đầu ngón cái cách mũi giày khoảng một ngón tay người lớn. Chân bé lớn rất nhanh, nên kiểm tra khoảng mỗi tháng; đôi đầu tiên có thể chỉ đi được 2–3 tháng.',
              'Có quai hoặc khoá giữ chắc gót để giày không tuột khi bé bước.',
              'Không cần giày đắt tiền hay giày “chỉnh hình” khi chân bé không có vấn đề gì. Đi chân trần còn tốt hơn đi giày chật.',
            ],
          },
          {
            type: 'heading',
            text: 'Xe tập đi: không an toàn, không giúp bé đi sớm',
          },
          {
            type: 'paragraph',
            text: 'AAP khuyên không dùng xe tập đi có bánh xe và kêu gọi cấm bán loại xe này. Ngồi trong xe tập đi, bé có thể lao đi gần 1 mét trong 1 giây, nhanh hơn phản xạ của người lớn đứng ngay cạnh. Mỗi năm có hàng nghìn trẻ phải vào viện vì xe tập đi, hay gặp nhất là lao xuống cầu thang gây gãy xương và chấn thương đầu; bé còn có thể với tới đồ nóng, thuốc, hoặc lao vào chỗ có nước. Xe tập đi cũng không giúp bé biết đi sớm hơn, thậm chí có thể làm chậm.',
          },
          {
            type: 'paragraph',
            text: 'Ở Việt Nam: xe tập đi (xe tròn có bánh) vẫn được bán rộng rãi và hay được tặng khi bé biết ngồi. Nếu muốn bé có chỗ chơi ở tư thế đứng, hãy chọn bàn chơi đứng cố định không có bánh xe, hoặc một khu quây an toàn trên sàn.',
          },
          {
            type: 'heading',
            text: 'Phòng ngã khi bé bắt đầu đi',
          },
          {
            type: 'bullets',
            items: [
              'Lắp cổng chắn ở đầu và chân cầu thang; chặn lối ra ban công, sân thượng; cửa sổ có khoá hoặc song chắn.',
              'Cố định tủ, kệ, ti vi vào tường và bọc góc bàn nhọn, vì bé hay vịn đồ để đứng lên.',
              'Để phích, nồi nước nóng, thuốc và hoá chất ngoài tầm với; úp hoặc đậy kín xô, chậu nước.',
              'Ngã ngồi, ngã nhẹ khi tập đi là chuyện thường; ở gần bé và để bé tự đứng dậy.',
            ],
          },
          {
            type: 'heading',
            text: 'Chân bẹt, chân vòng kiềng: thường là bình thường',
          },
          {
            type: 'bullets',
            items: [
              'Bàn chân bẹt: hầu hết trẻ nhỏ có bàn chân bẹt; vòm bàn chân thường hình thành dần trong khoảng 3–10 tuổi (NHS). Không cần giày đặc biệt nếu bé không đau.',
              'Chân vòng kiềng: nhiều trẻ có chân hơi cong ra ngoài đến khoảng 2 tuổi, sau đó chân hơi chụm gối (chân chữ X) đến khoảng 6–7 tuổi, rồi thẳng dần (AAP). Nắn hay bó chân không cần thiết và không giúp ích.',
              'Đi kiễng chân: hay gặp khi bé mới tập đi. AAP khuyên cho bé đi khám nếu bé vẫn đi kiễng chân sau 2 tuổi.',
              'Ngón chân quay vào trong khi đi: hay gặp và phần lớn tự hết khi bé lớn.',
            ],
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'Đừng so với con nhà hàng xóm',
            text: 'Bé đi sớm hay muộn trong khoảng bình thường không nói lên bé thông minh hay khoẻ hơn. Điều quan trọng là bé tiến bộ dần: hôm nay vịn đứng, tháng sau đi men, rồi tự bước.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Khi nào nên đưa bé đi khám',
            text: 'Bé 18 tháng chưa tự đi, hoặc 15 tháng chưa muốn vịn đứng, đi men; bé mất kỹ năng đã có; bé vẫn thường xuyên đi kiễng chân sau 2 tuổi, hoặc chỉ kiễng một chân; đi khập khiễng, nhất là kèm đau, sưng, sốt hoặc không chịu đứng; chỉ một chân bị cong, chân cong nặng hoặc cong hơn sau 2 tuổi; bé hay ngã bất thường, khó đứng dậy, phải chống tay lên đùi để đứng, hoặc đi lạch bạch. Sau cú ngã, gọi 115 nếu bé bất tỉnh, co giật, nôn nhiều lần hoặc lơ mơ.',
          },
        ],
        en: [
          {
            type: 'callout',
            tone: 'note',
            title: 'In short',
            text: "Every child takes their first steps at a different time; WHO data show healthy children start walking alone anywhere from about 8 to nearly 18 months. Give plenty of floor play and let them go barefoot indoors. Don't use a wheeled baby walker. Flat feet and mildly bowed legs are usually normal at this age. See a doctor if your child isn't walking alone by 18 months or loses skills they had.",
          },
          {
            type: 'heading',
            text: 'Learning to walk, step by step',
          },
          {
            type: 'paragraph',
            text: 'Before walking, babies usually sit steadily, crawl or creep, pull up to stand on furniture, then walk sideways holding on to chairs and tables (cruising). Some skip crawling, shuffle on their bottom and then walk; this is usually fine if they keep making progress. First steps are typically wide-legged, with arms held up for balance and plenty of sitting down with a bump.',
          },
          {
            type: 'paragraph',
            text: 'A WHO study of healthy children in five countries found a very wide normal range: walking while holding on at about 6–14 months, standing alone at about 7–17 months, and walking alone at about 8–18 months. The CDC (US) uses 18 months as the age by which most children walk without holding on. For babies born early, use their corrected age.',
          },
          {
            type: 'heading',
            text: 'Helping your child walk',
          },
          {
            type: 'bullets',
            items: [
              'Give lots of time on a clean, safe floor so your child can crawl, pull up and stand by themselves. There is no need to make them stand or walk them by the hands for long periods.',
              'Arrange sturdy furniture close together for cruising, and put toys a little out of reach to give them a reason to step.',
              "A sturdy push-along toy with a handle that doesn't tip easily can be used once your child can stand alone, always with an adult watching.",
              'Indoors, let your child go barefoot: they can feel the floor, the foot muscles work, and they slip less than in socks.',
            ],
          },
          {
            type: 'heading',
            text: 'Choosing first shoes',
          },
          {
            type: 'paragraph',
            text: "The AAP says babies' feet develop best when they are not confined in shoes. Shoes are mainly to protect the feet outdoors, on hot ground, gravel or where there may be sharp objects.",
          },
          {
            type: 'bullets',
            items: [
              'Soft, flexible, non-slip soles, with a toe box wide enough for the toes to move.',
              "Good fit: about an adult finger's width between the big toe and the end of the shoe. Feet grow fast, so check about once a month; a first pair may last only 2–3 months.",
              "A strap or fastening that holds the heel so the shoe doesn't slip off.",
              "There is no need for expensive or “corrective” shoes if your child's feet are healthy. Going barefoot is better than wearing shoes that are too tight.",
            ],
          },
          {
            type: 'heading',
            text: 'Baby walkers: unsafe and no help with walking',
          },
          {
            type: 'paragraph',
            text: 'The AAP advises against wheeled baby walkers and has called for a ban on their sale. In a walker a baby can move almost a metre in a second, faster than an adult standing right next to them can react. Walkers send thousands of children to hospital each year, most often from falling down stairs, causing broken bones and head injuries; children can also reach hot things or medicines, or roll into water. Walkers do not help children walk sooner and may even delay walking.',
          },
          {
            type: 'paragraph',
            text: 'In Việt Nam: wheeled baby walkers are widely sold and often given as gifts once a baby can sit. If you want a place for your child to play standing up, choose a stationary activity centre with no wheels, or a safe fenced play area on the floor.',
          },
          {
            type: 'heading',
            text: 'Preventing falls once your child is on the move',
          },
          {
            type: 'bullets',
            items: [
              'Fit safety gates at the top and bottom of stairs; block access to balconies and roof terraces; use window locks or guards.',
              'Fix cabinets, shelves and TVs to the wall and cover sharp table corners, because children pull up on furniture.',
              'Keep flasks, pans of hot water, medicines and chemicals out of reach; empty or cover buckets and basins of water.',
              'Small tumbles while learning are normal; stay close and let your child get back up by themselves.',
            ],
          },
          {
            type: 'heading',
            text: 'Flat feet and bow legs: usually normal',
          },
          {
            type: 'bullets',
            items: [
              'Flat feet: most young children have flat feet; the arch usually develops between about 3 and 10 years (NHS). No special shoes are needed if there is no pain.',
              'Bow legs: many children are bow-legged until about 2, then knock-kneed until about 6–7, and then the legs gradually straighten (AAP). Massaging or binding the legs is not needed and does not help.',
              'Toe walking: common when children first learn to walk. The AAP advises a check-up if your child still walks on their toes after age 2.',
              'Toes turning in while walking: common, and it usually fades as children grow.',
            ],
          },
          {
            type: 'callout',
            tone: 'tip',
            title: 'Try not to compare',
            text: 'Walking earlier or later within the normal range does not mean a child is cleverer or stronger. What matters is steady progress: pulling up today, cruising next month, then stepping alone.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'When to see a doctor',
            text: "Your child isn't walking alone at 18 months, or at 15 months shows no interest in pulling up or cruising; loses skills they had; still often walks on their toes after 2, or on one foot only; limps, especially with pain, swelling, fever or refusing to stand; has only one bowed leg, severe bowing, or bowing that gets worse after 2; falls unusually often, struggles to get up, pushes on their thighs to stand, or waddles. After a fall, call emergency services if your child is unconscious, has a fit, vomits repeatedly or is drowsy.",
          },
        ],
      },
      keywords: {
        vi: [
          'tập đi',
          'bước đi đầu tiên',
          'đi men',
          'xe tập đi',
          'giày tập đi',
          'bàn chân bẹt',
          'chân vòng kiềng',
          'đi kiễng chân',
        ],
        en: [
          'learning to walk',
          'first steps',
          'cruising',
          'baby walker',
          'first shoes',
          'flat feet',
          'bow legs',
          'toe walking',
        ],
      },
      relatedArticleIds: [
        'art_home_safety_falls',
        'art_preterm_corrected_age',
        'art_vitamin_d_iron',
        'art_talk_play_first_year',
      ],
      milestoneIds: ['stands', 'cruises', 'first_steps', 'climbs_furniture', 'runs'],
      sources: [
        {
          label: 'WHO — Motor development milestones: windows of achievement',
          url: 'https://www.who.int/tools/child-growth-standards/standards/motor-development-milestones',
        },
        {
          label: 'CDC — Important milestones: your child by 18 months',
          url: 'https://www.cdc.gov/act-early/milestones/18-months.html',
        },
        {
          label: 'HealthyChildren.org (AAP) — Baby walkers: a dangerous choice',
          url: 'https://www.healthychildren.org/English/safety-prevention/at-home/Pages/Baby-Walkers-A-Dangerous-Choice.aspx',
        },
        {
          label: 'HealthyChildren.org (AAP) — Shoes for active toddlers',
          url: 'https://www.healthychildren.org/English/ages-stages/toddler/Pages/Shoes-for-Active-Toddlers.aspx',
        },
        {
          label: 'HealthyChildren.org (AAP) — Bowlegs and knock-knees',
          url: 'https://www.healthychildren.org/English/health-issues/conditions/orthopedic/Pages/Bowlegs-and-Knock-Knees.aspx',
        },
        {
          label: 'NHS — Flat feet',
          url: 'https://www.nhs.uk/conditions/flat-feet/',
        },
      ],
    },
  },
  {
    id: 'art_genital_care',
    reviewerLabel: 'Nhóm chuyên môn · Điều dưỡng nhi',
    data: {
      library: 'care',
      topic: 'daily_care',
      format: 'step_guide',
      ageWeeks: {
        from: 0,
        to: 104,
      },
      readingMinutes: 5,
      cover: null,
      title: {
        vi: 'Vệ sinh vùng kín cho bé trai và bé gái: từng bước',
        en: "Cleaning your baby's genitals, girls and boys: step by step",
      },
      summary: {
        vi: 'Rửa vùng kín bằng nước ấm mỗi lần thay tã. Bé gái lau từ trước ra sau. Bé trai không kéo bao quy đầu, vì nó tự tách dần trong nhiều năm. Biết các dấu hiệu cần đi khám.',
        en: "Wash the genital area with warm water at every change. Wipe girls front to back. Don't pull back a boy's foreskin; it separates on its own over years. Know the signs that need a doctor.",
      },
      body: {
        vi: [
          {
            type: 'callout',
            tone: 'note',
            title: 'Tóm tắt nhanh',
            text: 'Vùng kín của bé chỉ cần rửa nhẹ bằng nước ấm mỗi lần thay tã và khi tắm. Với bé gái, luôn lau từ trước ra sau. Với bé trai, không kéo bao quy đầu ra: lúc nhỏ bao quy đầu còn dính, và sẽ tự tách dần trong nhiều năm. Dịch trắng hay chút máu trên tã bé gái trong vài ngày đầu là bình thường.',
          },
          {
            type: 'heading',
            text: 'Chuẩn bị',
          },
          {
            type: 'bullets',
            items: [
              'Rửa tay. Chuẩn bị nước ấm sạch, bông hoặc khăn mềm, hoặc khăn ướt không mùi, không cồn.',
              'Tã sạch, khăn khô, và kem bảo vệ da nếu bé hay bị hăm.',
              'Không dùng xà phòng có mùi thơm, phấn rôm, dung dịch sát khuẩn hay tăm bông cho vùng kín của bé.',
            ],
          },
          {
            type: 'heading',
            text: 'Bước 1: Làm sạch vùng tã',
          },
          {
            type: 'paragraph',
            text: 'Dùng phần sạch của tã cũ lau bớt phân, rồi rửa bằng nước ấm, nhớ lau cả các nếp da ở bẹn và đùi. Thay tã ngay sau khi bé tè hoặc đi ngoài; bé nhỏ có thể cần thay 10–12 lần mỗi ngày.',
          },
          {
            type: 'heading',
            text: 'Bước 2: Với bé gái',
          },
          {
            type: 'bullets',
            items: [
              'Luôn lau từ trước ra sau, từ âm hộ về phía hậu môn, mỗi lượt lau dùng một miếng bông sạch, để vi khuẩn từ phân không vào âm đạo và đường tiểu.',
              'Nếu phân dính vào giữa hai môi âm hộ, nhẹ nhàng lau sạch; không cần banh rộng hay rửa sâu vào bên trong.',
              'Vài ngày đầu sau sinh, có thể thấy dịch trắng trên tã, đôi khi lẫn chút máu như một kỳ kinh nhỏ. Đó là do nội tiết tố của mẹ truyền sang và sẽ tự hết (NHS). Theo AAP, dịch lẫn máu thường không kéo dài quá 3–4 ngày.',
              'Có thể thấy một mẩu da hồng nhỏ ở cửa âm đạo do màng trinh hơi sưng vì nội tiết tố của mẹ. Đây là bình thường và sẽ nhỏ dần trong 2–4 tuần (AAP).',
            ],
          },
          {
            type: 'heading',
            text: 'Bước 3: Với bé trai',
          },
          {
            type: 'bullets',
            items: [
              'Rửa dương vật, bìu và vùng xung quanh bằng nước ấm như phần còn lại của vùng tã, nhớ lau cả nếp da dưới bìu.',
              'Không kéo bao quy đầu ra để rửa. Lúc mới sinh, bao quy đầu dính vào đầu dương vật và tự tách dần trong nhiều tháng đến nhiều năm. Theo NHS, phần lớn trẻ đến khoảng 5 tuổi mới kéo được bao quy đầu, có trẻ đến 10 tuổi hoặc muộn hơn.',
              'Cố kéo bao quy đầu khi chưa tách có thể gây đau, chảy máu và rách da.',
              'Bao quy đầu phồng lên khi bé tè rồi xẹp xuống, dòng tiểu vẫn bình thường và bé không đau: thường là bình thường (NHS).',
              'Những cục trắng như hạt ngọc dưới da bao quy đầu là chất bựa bình thường, sẽ tự thoát ra khi bao quy đầu tách dần; không cần nặn.',
              'Khi bao quy đầu đã tự tách, thỉnh thoảng có thể kéo nhẹ đến chỗ dễ kéo, tráng nước rồi kéo trở lại như cũ. Khi bé lớn, dạy bé tự làm.',
            ],
          },
          {
            type: 'paragraph',
            text: 'Ở Việt Nam: nhiều người thân vẫn khuyên tuột bao quy đầu cho bé hằng ngày “để vệ sinh” hoặc để “không bị hẹp”. AAP và NHS không khuyên làm vậy: bao quy đầu chưa tách là bình thường, và kéo ép có thể gây đau, rách da. Nếu lo bao quy đầu hẹp, hãy hỏi bác sĩ.',
          },
          {
            type: 'heading',
            text: 'Bước 4: Nếu bé trai đã cắt bao quy đầu',
          },
          {
            type: 'paragraph',
            text: 'Cắt bao quy đầu hay không là lựa chọn của mỗi gia đình, tuỳ văn hoá, tôn giáo và tư vấn y tế. Sau khi cắt, làm theo hướng dẫn của nơi thực hiện. Theo AAP, đầu dương vật thường hơi đỏ và có thể có dịch vàng trong vài ngày đầu, hết dần trong khoảng một tuần; giữ sạch và lau nhẹ phân dính vào.',
          },
          {
            type: 'heading',
            text: 'Bước 5: Lau khô và giữ da khoẻ',
          },
          {
            type: 'bullets',
            items: [
              'Thấm khô nhẹ bằng khăn mềm, không chà xát. Nếu trời ấm, để bé không mặc tã một lúc.',
              'Thoa một lớp kem bảo vệ da nếu bé hay bị hăm, rồi mặc tã sạch và rửa tay.',
            ],
          },
          {
            type: 'heading',
            text: 'Những điều nên để ý khi thay tã',
          },
          {
            type: 'bullets',
            items: [
              'Dính môi âm hộ: hai môi nhỏ dính vào nhau một phần, hay gặp do kích ứng vùng tã. Phần lớn không cần điều trị và tự tách khi bé lớn (AAP). Không tự tách bằng tay.',
              'Tinh hoàn: khi tắm, để ý xem bìu có đủ hai tinh hoàn không. Tinh hoàn chưa xuống thường tự xuống trong 12 tuần đầu; nếu không, bác sĩ sẽ giới thiệu bé đến chuyên khoa (NHS).',
              'Cục phồng mềm ở bẹn, bìu hoặc môi lớn, to lên khi bé khóc, rặn và nhỏ lại khi bé nằm yên, có thể là thoát vị bẹn và cần được khám. Bìu sưng mềm do có nước cũng hay gặp ở bé sơ sinh; bác sĩ sẽ phân biệt hai tình trạng này (AAP).',
            ],
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Gọi 115 hoặc đến cấp cứu ngay khi',
            text: 'Bao quy đầu bị kéo lui mà không trở lại được, đầu dương vật sưng và đau; hoặc cục ở bẹn, bìu hay môi lớn trở nên cứng, đau, đỏ hoặc tím, không xẹp khi bé nằm yên, nhất là khi bé nôn, quấy khóc không dỗ được hoặc bụng chướng.',
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Khi nào nên đưa bé đi khám',
            text: 'Bao quy đầu đỏ, sưng, đau, có mủ hoặc mùi hôi; bé đau hay khóc khi tè, dòng tiểu chỉ nhỏ giọt, hoặc bao quy đầu phồng kèm đau; vết cắt bao quy đầu đỏ kéo dài, sưng hoặc có vết loét đóng vảy vàng; môi âm hộ dính che lỗ tiểu, bé tè khó, nước tiểu rỉ ra sau khi tè hoặc hay bị nhiễm trùng tiểu; dịch âm đạo lẫn máu kéo dài, nhiều hoặc có mùi hôi; có cục phồng ở bẹn, bìu hoặc môi lớn; bìu thiếu một hoặc cả hai tinh hoàn.',
          },
        ],
        en: [
          {
            type: 'callout',
            tone: 'note',
            title: 'In short',
            text: "Your baby's genitals only need a gentle wash with warm water at each nappy change and at bath time. For girls, always wipe from front to back. For boys, don't pull the foreskin back: it is attached when they are small and separates by itself over years. A white discharge or a little blood in a baby girl's nappy in the first days is normal.",
          },
          {
            type: 'heading',
            text: 'Get ready',
          },
          {
            type: 'bullets',
            items: [
              'Wash your hands. Have clean warm water and cotton wool or a soft cloth ready, or fragrance-free, alcohol-free baby wipes.',
              'A clean nappy, a dry towel, and barrier cream if your baby gets nappy rash.',
              "Don't use perfumed soap, talcum powder, antiseptics or cotton buds on your baby's genitals.",
            ],
          },
          {
            type: 'heading',
            text: 'Step 1: Clean the nappy area',
          },
          {
            type: 'paragraph',
            text: 'Use a clean part of the old nappy to wipe away most of the poo, then wash with warm water, including the skin folds at the groin and thighs. Change the nappy soon after every wee or poo; young babies may need 10–12 changes a day.',
          },
          {
            type: 'heading',
            text: 'Step 2: For girls',
          },
          {
            type: 'bullets',
            items: [
              "Always wipe from front to back, from the vulva towards the bottom, with a fresh piece of cotton wool each time, so germs from poo don't get into the vagina or urinary tract.",
              'If poo gets between the labia, gently wipe it away; there is no need to spread them wide or wash inside.',
              "In the first days after birth you may see a white discharge in the nappy, sometimes with a little blood like a tiny period. It comes from the mother's hormones and soon stops (NHS). According to the AAP, blood-tinged discharge usually lasts no more than 3–4 days.",
              "You may see a small pink tag of tissue at the vaginal opening, a slightly swollen hymen caused by the mother's hormones. It is normal and shrinks over 2–4 weeks (AAP).",
            ],
          },
          {
            type: 'heading',
            text: 'Step 3: For boys',
          },
          {
            type: 'bullets',
            items: [
              'Wash the penis, scrotum and surrounding skin with warm water like the rest of the nappy area, including the fold under the scrotum.',
              "Don't pull back the foreskin to clean. At birth it is attached to the head of the penis and separates gradually over months to years. According to the NHS, most foreskins don't pull back until around age 5, and some not until 10 or later.",
              "Forcing a foreskin that hasn't separated can cause pain, bleeding and tears in the skin.",
              'A foreskin that balloons while your son wees and then goes down, with a normal stream and no pain, is usually normal (NHS).',
              "White, pearl-like lumps under the foreskin are normal smegma that works its way out as the foreskin separates; don't squeeze them.",
              'Once the foreskin has separated on its own, you can occasionally ease it back only as far as it goes easily, rinse, then return it. As your son grows, teach him to do this himself.',
            ],
          },
          {
            type: 'paragraph',
            text: "In Việt Nam: relatives often still advise pulling back a baby's foreskin every day “to keep it clean” or “so it won't be tight”. The AAP and NHS do not recommend this: a foreskin that hasn't separated is normal, and forcing it can cause pain and tears. If you are worried the foreskin is tight, ask a doctor.",
          },
          {
            type: 'heading',
            text: 'Step 4: If your son has been circumcised',
          },
          {
            type: 'paragraph',
            text: "Whether to circumcise is each family's choice, shaped by culture, religion and medical advice. Afterwards, follow the instructions from where it was done. According to the AAP, the tip often looks red with some yellow discharge for the first few days, fading within about a week; keep it clean and gently wipe away any poo.",
          },
          {
            type: 'heading',
            text: 'Step 5: Dry and protect the skin',
          },
          {
            type: 'bullets',
            items: [
              "Pat dry gently with a soft towel; don't rub. If it's warm enough, give your baby some nappy-free time.",
              'Apply a thin layer of barrier cream if your baby is prone to nappy rash, put on a clean nappy, and wash your hands.',
            ],
          },
          {
            type: 'heading',
            text: 'Things to look out for at nappy changes',
          },
          {
            type: 'bullets',
            items: [
              "Labial adhesions: the inner labia partly stick together, often after nappy-area irritation. Most need no treatment and separate as the child grows (AAP). Don't try to pull them apart.",
              'Testicles: at bath time, check that both testicles are in the scrotum. An undescended testicle often comes down by itself in the first 12 weeks; if not, the doctor will refer your son to a specialist (NHS).',
              'A soft bulge in the groin, scrotum or labia that grows when your baby cries or strains and shrinks when they are relaxed may be an inguinal hernia and needs a check. A soft, fluid-filled swelling of the scrotum is also common in newborns; a doctor can tell the two apart (AAP).',
            ],
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'Call emergency services or go to the emergency department now if',
            text: "The foreskin has been pulled back and won't return, with a swollen, painful tip; or a lump in the groin, scrotum or labia becomes hard, painful, red or dark and doesn't go down when your baby is calm, especially with vomiting, crying that can't be soothed or a swollen tummy.",
          },
          {
            type: 'callout',
            tone: 'doctor',
            title: 'When to see a doctor',
            text: 'The foreskin is red, swollen, sore, has pus or smells bad; your son has pain or cries when weeing, the stream is only a trickle, or the foreskin balloons with pain; a circumcision wound stays red, swells or has crusty yellow sores; labial adhesions cover the urine opening, your daughter struggles to wee, dribbles afterwards or keeps getting urine infections; vaginal discharge with blood lasts, is heavy or smells bad; there is a bulge in the groin, scrotum or labia; one or both testicles are missing from the scrotum.',
          },
        ],
      },
      keywords: {
        vi: [
          'vệ sinh vùng kín',
          'bao quy đầu',
          'tuột bao quy đầu',
          'cắt bao quy đầu',
          'dính môi âm hộ',
          'thoát vị bẹn',
          'tinh hoàn ẩn',
          'thay tã',
        ],
        en: [
          'genital care',
          'foreskin',
          'retracting foreskin',
          'circumcision',
          'labial adhesions',
          'inguinal hernia',
          'undescended testicle',
          'nappy change',
        ],
      },
      relatedArticleIds: ['art_diaper_rash', 'art_bathing_at_home', 'art_newborn_skin_rashes'],
      milestoneIds: [],
      sources: [
        {
          label: "NHS — How to change your baby's nappy",
          url: 'https://www.nhs.uk/baby/caring-for-a-newborn/how-to-change-your-babys-nappy/',
        },
        {
          label: "HealthyChildren.org (AAP) — How to care for your baby's penis",
          url: 'https://www.healthychildren.org/English/ages-stages/baby/bathing-skin-care/Pages/Caring-For-Your-Sons-Penis.aspx',
        },
        {
          label: 'NHS — Tight foreskin (phimosis)',
          url: 'https://www.nhs.uk/conditions/phimosis/',
        },
        {
          label: 'HealthyChildren.org (AAP) — Labial adhesions in babies and children',
          url: 'https://www.healthychildren.org/English/health-issues/conditions/genitourinary-tract/Pages/Labial-Adhesions.aspx',
        },
        {
          label: 'HealthyChildren.org (AAP) — Inguinal hernia in infants and children',
          url: 'https://www.healthychildren.org/English/health-issues/conditions/abdominal/Pages/Inguinal-Hernia.aspx',
        },
        {
          label: 'NHS — Undescended testicles',
          url: 'https://www.nhs.uk/conditions/undescended-testicles/',
        },
      ],
    },
  },
  ...seedSolidsArticles,
];

// ---------- Stage content: Giai đoạn của bé (the 16 fixed buckets) ----------
//
// "Bé đang thế nào" are observable behaviours with wide normal ranges (CDC "Learn the Signs. Act
// Early." 2022 checklists, WHO MGRS motor windows, NHS); "Ba mẹ có thể thử" are concrete play and
// care ideas with the reason in the same line. Ranges are typical, never deadlines.

const FAMILY = ['coParent', 'caregiver'] as const;
const FAMILY_PLAY = ['coParent', 'caregiver', 'relative'] as const;

export const seedStages: SeedStage[] = [
  {
    id: 'stg_w0',
    reviewerLabel: PAEDS,
    data: {
      age: { unit: 'week', from: 0, to: 3 },
      title: t(
        'Những ngày đầu: bú, ngủ và làm quen',
        'The first days: feeding, sleep, getting to know you',
      ),
      doing: t(
        [
          'Bé ngủ phần lớn thời gian và thức dậy bú khoảng 8–12 lần mỗi ngày đêm; có lúc các cữ bú dồn sát nhau.',
          'Bé nhìn rõ nhất những gì ở gần, cỡ khoảng cách tới mặt ba mẹ khi bế, và thích ngắm khuôn mặt người.',
          'Giật mình, mút, nắm chặt ngón tay và quay đầu tìm vú là những phản xạ bình thường của trẻ sơ sinh.',
        ],
        [
          'Your baby sleeps most of the time and wakes to feed about 8–12 times a day and night; feeds sometimes bunch up.',
          'Your baby sees close things best, about the distance to your face when you hold them, and loves looking at faces.',
          'Startling, sucking, gripping your finger and turning to root for the breast are normal newborn reflexes.',
        ],
      ),
      tryThis: t(
        [
          'Ôm bé da kề da trên ngực ba mẹ: giúp bé giữ ấm, dịu lại và bú tốt hơn.',
          'Cho bú khi bé có dấu hiệu đói sớm như mút tay, quay đầu tìm vú, trước khi bé khóc: bé ngậm bắt vú dễ hơn.',
          'Mọi giấc ngủ: đặt bé nằm ngửa trong nôi riêng, nệm phẳng, không gối chăn, cùng phòng với ba mẹ.',
        ],
        [
          'Hold your baby skin to skin on your chest: it keeps them warm, calms them and helps feeding.',
          'Feed at early hunger cues like hand-sucking or rooting, before crying: a calm baby latches more easily.',
          'For every sleep: on the back, in their own crib, flat mattress, no pillows or quilts, in your room.',
        ],
      ),
      articleIds: ['art_breastfeeding_start', 'art_newborn_jaundice'],
      milestoneIds: ['follows_faces', 'calms_when_held', 'recognises_voices'],
      audience: [...FAMILY],
      cover: null,
      sources: [S.hcBreastfeeding, S.aapSafeSleep, S.cdc2m],
    },
  },
  {
    id: 'stg_w3',
    reviewerLabel: DEV,
    data: {
      age: { unit: 'week', from: 3, to: 5 },
      title: t(
        'Bé nhìn theo mặt người, nghe giọng quen',
        'Watching faces, knowing familiar voices',
      ),
      doing: t(
        [
          'Bé có thể dõi mắt theo mặt ba mẹ một đoạn ngắn khi ba mẹ di chuyển chậm sang một bên.',
          'Bé dịu lại khi được bế áp vào người hay nghe giọng quen; nhiều bé quấy nhiều hơn vào chiều tối.',
          'Mỗi lần thức, bé tỉnh táo lâu hơn một chút, nhưng vẫn ngủ phần lớn thời gian cả ngày lẫn đêm.',
        ],
        [
          'Your baby may follow your face a short way with their eyes as you slowly move to one side.',
          'Your baby calms when held close or hearing a familiar voice; many babies are fussier in the evening.',
          'Each awake spell is a little longer, but your baby still sleeps most of the day and night.',
        ],
      ),
      tryThis: t(
        [
          'Ghé mặt cách bé 20–30 cm, nói chậm, mỉm cười rồi chờ bé phản ứng: đó là những “cuộc trò chuyện” đầu tiên.',
          'Cho bé nằm sấp trên ngực ba mẹ vài phút mỗi lần bé thức, luôn có người lớn trông: cổ và vai bé khỏe dần.',
          'Khi bé khóc dai mà ba mẹ thấy căng thẳng, đặt bé nằm ngửa trong nôi, ra ngoài vài phút; không bao giờ lắc bé.',
        ],
        [
          'Bring your face 20–30 cm away, talk slowly, smile and wait for a response: your first “conversations”.',
          'Lay your baby on your chest for a few minutes each awake time, always watched: neck and shoulders get stronger.',
          'If long crying gets too much, lay your baby on their back in the crib and step out for a few minutes; never shake a baby.',
        ],
      ),
      articleIds: ['art_crying_colic', 'art_tummy_time'],
      milestoneIds: ['follows_faces', 'calms_when_held', 'recognises_voices'],
      audience: [...FAMILY],
      cover: null,
      sources: [S.cdc2m, S.hcTummyTime, S.nhsBabyDevelopment],
    },
  },
  {
    id: 'stg_m1',
    reviewerLabel: DEV,
    data: {
      age: { unit: 'month', from: 1, to: 2 },
      title: t('Nụ cười đầu tiên đáp lại ba mẹ', 'The first smile back at you'),
      doing: t(
        [
          'Khoảng 6–8 tuần, nhiều bé bắt đầu mỉm cười đáp lại khi ba mẹ cười và nói chuyện với bé.',
          'Bé phát ra âm thanh ngoài tiếng khóc và giật mình hoặc chú ý khi có tiếng động lớn.',
          'Khi nằm sấp, bé nhấc đầu lên được trong chốc lát và cử động đều cả hai tay, hai chân.',
        ],
        [
          'Around 6–8 weeks many babies start smiling back when you smile and talk to them.',
          'Your baby makes sounds other than crying and startles or reacts to loud sounds.',
          'On their tummy your baby lifts their head briefly, and moves both arms and both legs.',
        ],
      ),
      tryThis: t(
        [
          'Bắt chước tiếng ư a của bé rồi dừng lại chờ bé “đáp”: trò chuyện qua lại là nền móng của ngôn ngữ.',
          'Nằm sấp nhiều lần ngắn mỗi ngày khi bé thức, đặt đồ chơi hoặc mặt ba mẹ ngang tầm mắt bé.',
          'Bế ẵm, vỗ về khi bé khóc không làm bé “hư”: bé học được rằng thế giới an toàn và có người đáp lại.',
        ],
        [
          'Copy your baby’s coos, then pause for a “reply”: this back-and-forth is the foundation of language.',
          'Do several short tummy times a day while awake, with a toy or your face at eye level.',
          'Picking up and comforting a crying baby does not spoil them: they learn the world is safe and responsive.',
        ],
      ),
      articleIds: ['art_talk_play_first_year', 'art_crying_colic'],
      milestoneIds: ['first_smile', 'looks_at_toy', 'lifts_head', 'follows_faces'],
      audience: [...FAMILY],
      cover: null,
      sources: [S.cdc2m, S.nhsBabyDevelopment, S.hcTummyTime],
    },
  },
  {
    id: 'stg_m2',
    reviewerLabel: DEV,
    data: {
      age: { unit: 'month', from: 2, to: 3 },
      title: t('Giữ đầu vững hơn khi nằm sấp', 'A steadier head during tummy time'),
      doing: t(
        [
          'Khi nằm sấp, bé nâng đầu cao và lâu hơn; một số bé đã chống được lên cẳng tay.',
          'Bé ê a những âm “ơ”, “a”, ngắm nghía bàn tay mình và hay đưa tay lên miệng.',
          'Bé cười nhiều hơn với người quen và có thể nhìn theo một món đồ chơi di chuyển chậm.',
        ],
        [
          'On their tummy your baby lifts their head higher and for longer; some already prop up on their forearms.',
          'Your baby coos “ooh” and “aah”, studies their hands and often brings them to their mouth.',
          'Your baby smiles more at familiar people and may follow a slowly moving toy with their eyes.',
        ],
      ),
      tryThis: t(
        [
          'Nằm sấp vài lần mỗi ngày khi bé thức; WHO khuyên cộng dồn ít nhất 30 phút mỗi ngày với trẻ chưa biết bò.',
          'Đưa lục lạc hoặc đồ chơi màu tương phản chậm sang hai bên để bé tập nhìn theo, rồi để bé chạm thử.',
          'Đưa bé tiêm chủng đúng lịch mốc 2 tháng và ghi lại phản ứng sau tiêm để trao đổi với cán bộ y tế.',
        ],
        [
          'Tummy time several times a day while awake; WHO advises at least 30 minutes in total for babies not yet crawling.',
          'Move a rattle or high-contrast toy slowly side to side so your baby tracks it, then let them touch it.',
          'Keep the 2-month vaccination appointment and note any reaction afterwards to discuss with the health worker.',
        ],
      ),
      articleIds: ['art_tummy_time', 'art_after_vaccines'],
      milestoneIds: ['lifts_head', 'hands_to_mouth', 'coos', 'first_smile'],
      audience: [...FAMILY],
      cover: null,
      sources: [S.cdc2m, S.cdc4m, S.whoSitLessPlayMore],
    },
  },
  {
    id: 'stg_m3',
    reviewerLabel: DEV,
    data: {
      age: { unit: 'month', from: 3, to: 4 },
      title: t('Với tay, nắm đồ chơi', 'Reaching for and grasping toys'),
      doing: t(
        [
          'Bé giữ đầu vững khi được bế, chống cẳng tay khi nằm sấp và vung tay về phía đồ chơi.',
          'Bé nắm được đồ chơi đặt vào tay và đưa mọi thứ lên miệng để khám phá.',
          'Bé tự cười để gọi ba mẹ, cười khúc khích và quay đầu về phía giọng nói quen.',
        ],
        [
          'Your baby holds their head steady when held, props on forearms on their tummy and swings at toys.',
          'Your baby holds a toy put in their hand and brings everything to their mouth to explore.',
          'Your baby smiles to get your attention, chuckles and turns towards a familiar voice.',
        ],
      ),
      tryThis: t(
        [
          'Đặt đồ chơi nhẹ, an toàn trong tầm với khi bé nằm ngửa hoặc nằm sấp để bé tập vươn tay, đập và nắm.',
          'Gọi tên bé và trò chuyện từ hai phía khác nhau để bé tập quay đầu tìm tiếng nói.',
          'Chọn đồ chơi to hơn miệng bé, không có chi tiết nhỏ hay dây dài, vì bé sẽ cho mọi thứ vào miệng.',
        ],
        [
          'Put light, safe toys within reach when your baby is on their back or tummy so they practice reaching and grasping.',
          'Call your baby’s name and talk from different sides so they practice turning towards your voice.',
          'Choose toys bigger than your baby’s mouth, with no small parts or long strings: everything goes in the mouth.',
        ],
      ),
      articleIds: ['art_talk_play_first_year', 'art_tummy_time'],
      milestoneIds: [
        'holds_toy',
        'turns_to_voice',
        'smiles_for_attention',
        'laughs',
        'pushes_up_arms',
      ],
      audience: [...FAMILY],
      cover: null,
      sources: [S.cdc4m, S.hcBaby],
    },
  },
  {
    id: 'stg_m4',
    reviewerLabel: PAEDS,
    data: {
      age: { unit: 'month', from: 4, to: 5 },
      title: t('Cười thành tiếng và tập lẫy', 'Laughing out loud and learning to roll'),
      doing: t(
        [
          'Nhiều bé bắt đầu lẫy từ sấp sang ngửa; có bé lẫy sớm, có bé muộn hơn vài tuần.',
          'Bé cười thành tiếng, “đáp lời” bằng âm thanh khi ba mẹ nói chuyện và thích thổi phì phì.',
          'Giấc ngủ có thể xáo trộn, bé thức đêm nhiều hơn dù trước đó ngủ khá yên; thường chỉ là tạm thời.',
        ],
        [
          'Many babies start rolling from tummy to back; some roll early, others a few weeks later.',
          'Your baby laughs out loud, “answers” with sounds when you talk and loves blowing raspberries.',
          'Sleep may get bumpy, with more night waking after a settled spell; it is usually temporary.',
        ],
      ),
      tryThis: t(
        [
          'Bé sắp lẫy: không để bé một mình trên giường, sofa hay bàn thay tã, kể cả vài giây.',
          'Ngừng quấn chũn khi bé có dấu hiệu tập lẫy; vẫn đặt bé nằm ngửa mỗi khi bắt đầu ngủ.',
          'Chưa cần ăn dặm: sữa mẹ hoặc sữa công thức vẫn đủ đến khoảng 6 tháng; bé sinh non thì hỏi bác sĩ.',
        ],
        [
          'Rolling is coming: never leave your baby alone on a bed, sofa or changing table, even for a few seconds.',
          'Stop swaddling once your baby shows signs of rolling; still lay them on their back to start every sleep.',
          'No solids yet: breast milk or formula is enough until about 6 months; if born early, ask the doctor.',
        ],
      ),
      articleIds: ['art_sleep_by_age', 'art_home_safety_falls'],
      milestoneIds: [
        'rolls_over',
        'laughs',
        'takes_turns_sounds',
        'reaches_for_toy',
        'blows_raspberries',
      ],
      audience: [...FAMILY],
      cover: null,
      sources: [S.cdc4m, S.cdc6m, S.hcSafeSleep],
    },
  },
  {
    id: 'stg_m5',
    reviewerLabel: DEV,
    data: {
      age: { unit: 'month', from: 5, to: 6 },
      title: t(
        'Tò mò với mọi thứ, chuẩn bị ăn dặm',
        'Curious about everything, getting ready for solids',
      ),
      doing: t(
        [
          'Bé với lấy đồ mình thích, cho đồ vào miệng để khám phá và thích ngắm mình trong gương.',
          'Bé nhận ra người quen, lẫy được và chống thẳng tay khi nằm sấp; khi ngồi bé chống tay đỡ người.',
          'Nhiều bé chú ý khi người lớn ăn; các dấu hiệu sẵn sàng ăn dặm thường rõ dần quanh 6 tháng.',
        ],
        [
          'Your baby reaches for things they want, mouths them to explore and loves looking in a mirror.',
          'Your baby knows familiar people, rolls and pushes up on straight arms; sitting, they lean on their hands.',
          'Many babies watch adults eat; the signs of readiness for solids usually become clear around 6 months.',
        ],
      ),
      tryThis: t(
        [
          'Cho bé tập ngồi có đỡ trên sàn, đặt đồ chơi phía trước để bé chống tay và giữ thăng bằng.',
          'Đọc sách tranh, chỉ và gọi tên thứ bé đang nhìn: bé học từ ngữ qua những lúc cùng chú ý.',
          'Tìm hiểu trước về ăn dặm: dấu hiệu sẵn sàng, món giàu sắt và những thực phẩm dễ gây hóc.',
        ],
        [
          'Help your baby practice sitting on the floor with support, a toy in front so they lean and balance.',
          'Read picture books, point and name what your baby looks at: shared attention builds words.',
          'Read up on solids now: readiness signs, iron-rich first foods and foods that are choking risks.',
        ],
      ),
      articleIds: ['art_solids_readiness', 'art_vitamin_d_iron'],
      milestoneIds: [
        'reaches_for_toy',
        'mouths_objects',
        'enjoys_mirror',
        'knows_familiar_faces',
        'rolls_over',
        'sits_up',
      ],
      audience: [...FAMILY],
      cover: null,
      sources: [S.cdc6m, S.whoComplementary, S.nhsBabyDevelopment],
    },
  },
  {
    id: 'stg_m6',
    reviewerLabel: NUTRITION,
    data: {
      age: { unit: 'month', from: 6, to: 7 },
      title: t('Bắt đầu ăn dặm, ngồi vững dần', 'Starting solids, sitting more steadily'),
      doing: t(
        [
          'Nhiều bé ngồi được khi có đỡ hoặc chống tay; một số bé đã ngồi vững không cần đỡ.',
          'Bé bập bẹ chuỗi âm như “ba ba”, “ma ma” và chuyền đồ từ tay này sang tay kia.',
          'Bé mím môi hoặc quay mặt đi khi đã no: đó là cách bé “nói” rằng mình đủ rồi.',
        ],
        [
          'Many babies sit with support or leaning on their hands; some already sit steadily on their own.',
          'Your baby babbles strings like “ba-ba” and “ma-ma” and passes things from hand to hand.',
          'Your baby closes their lips or turns away when full: that is how they tell you they have had enough.',
        ],
      ),
      tryThis: t(
        [
          'Bắt đầu vài thìa mỗi ngày rồi tăng dần lên 2–3 bữa, ưu tiên món giàu sắt; vẫn cho bú như trước.',
          'Giới thiệu từng món dễ dị ứng như trứng nấu chín kỹ, bơ đậu phộng pha loãng; không cần trì hoãn.',
          'Cho bé ngồi thẳng khi ăn, luôn có người lớn bên cạnh; không cho ăn khi bé đang nằm, chạy chơi hay khóc.',
        ],
        [
          'Start with a few spoonfuls a day, building up to 2–3 meals, iron-rich foods first; keep milk feeds as before.',
          'Introduce common allergens one at a time, like well-cooked egg or thinned peanut butter; no need to delay.',
          'Sit your baby upright to eat, always with an adult; never feed while lying down, playing or crying.',
        ],
      ),
      articleIds: ['art_solids_readiness', 'art_solids_choking_safety'],
      milestoneIds: ['sits_up', 'transfers_hands', 'babbles', 'responds_to_name', 'peekaboo'],
      audience: [...FAMILY],
      cover: null,
      sources: [S.whoComplementary, S.cdc6m, S.cdc9m],
    },
  },
  {
    id: 'stg_m7',
    reviewerLabel: DEV,
    data: {
      age: { unit: 'month', from: 7, to: 8 },
      title: t(
        'Ngồi vững, tập bò và ngại người lạ',
        'Sitting up, starting to crawl, wary of strangers',
      ),
      doing: t(
        [
          'Nhiều bé ngồi vững, bắt đầu trườn hoặc bò; có bé bỏ qua bò và chuyển thẳng sang vịn đứng.',
          'Bé có thể ngại người lạ và bám ba mẹ hơn: dấu hiệu bé đã phân biệt được người quen.',
          'Bé đập hai đồ vật vào nhau, tìm đồ vừa rơi khỏi tầm mắt và giơ tay đòi bế.',
        ],
        [
          'Many babies sit steadily and start to creep or crawl; some skip crawling and go straight to pulling up.',
          'Your baby may be wary of strangers and cling to you: a sign they now know who is familiar.',
          'Your baby bangs two things together, looks for things that drop out of sight and lifts arms to be picked up.',
        ],
      ),
      tryThis: t(
        [
          'Kiểm tra an toàn ở tầm thấp: bịt ổ điện, cất vật nhỏ, cố định kệ tủ, chặn cầu thang, đậy chum vại nước.',
          'Chơi ú òa và giấu đồ dưới khăn: bé học rằng người và vật vẫn còn đó dù tạm khuất.',
          'Tăng dần độ thô của thức ăn, từ nghiền mịn sang nghiền còn lợn cợn, và cho bé cầm thức ăn mềm.',
        ],
        [
          'Check safety at floor level: cover sockets, clear small objects, anchor furniture, gate stairs, cover water jars.',
          'Play peekaboo and hide toys under a cloth: your baby learns people and things still exist out of sight.',
          'Move gradually from smooth to lumpier mashed food, and let your baby hold soft finger foods.',
        ],
      ),
      articleIds: ['art_separation_anxiety', 'art_home_safety_falls'],
      milestoneIds: [
        'crawls',
        'stranger_wariness',
        'bangs_objects',
        'looks_for_dropped',
        'lifts_arms',
        'sits_up',
      ],
      audience: [...FAMILY_PLAY],
      cover: null,
      sources: [S.cdc9m, S.cdc6m, S.unicefParenting],
    },
  },
  {
    id: 'stg_m8',
    reviewerLabel: DEV,
    data: {
      age: { unit: 'month', from: 8, to: 9 },
      title: t('Bò khắp nơi, bập bẹ nhiều âm', 'Crawling everywhere, babbling away'),
      doing: t(
        [
          'Bé tự ngồi dậy, bò hoặc trườn khắp nơi và có thể bắt đầu vịn đồ để đứng lên.',
          'Bé bập bẹ nhiều chuỗi âm khác nhau và quay lại khi được gọi tên.',
          'Bé có thể khóc khi ba mẹ rời đi; lo âu xa cách thường bắt đầu rõ ở khoảng tuổi này.',
        ],
        [
          'Your baby gets to sitting alone, crawls or shuffles everywhere and may start pulling up on furniture.',
          'Your baby babbles many different strings of sounds and looks when you call their name.',
          'Your baby may cry when you leave; separation anxiety often becomes noticeable around this age.',
        ],
      ),
      tryThis: t(
        [
          'Chào tạm biệt ngắn gọn, vui vẻ thay vì lẻn đi, và báo khi quay lại: bé học rằng ba mẹ luôn trở về.',
          'Cho bé tự bốc thức ăn mềm cắt miếng nhỏ và tập uống vài ngụm nước bằng cốc không nắp.',
          'Gọi tên cảm xúc của bé bằng lời, nét mặt và giọng nói: “Con buồn vì mẹ đi làm, mẹ hiểu mà.”',
        ],
        [
          'Say a short, cheerful goodbye instead of sneaking away, and say hello when back: your baby learns you return.',
          'Let your baby feed themselves soft food in small pieces and take sips of water from an open cup.',
          'Name your baby’s feelings with words, face and voice: “You’re sad Mum is going to work. I understand.”',
        ],
      ),
      articleIds: ['art_separation_anxiety', 'art_solids_textures_by_month'],
      milestoneIds: [
        'crawls',
        'stands',
        'babbles',
        'responds_to_name',
        'stranger_wariness',
        'lifts_arms',
      ],
      audience: [...FAMILY_PLAY],
      cover: null,
      sources: [S.cdc9m, S.whoComplementary],
    },
  },
  {
    id: 'stg_m9',
    reviewerLabel: DEV,
    data: {
      age: { unit: 'month', from: 9, to: 10 },
      title: t('Nhặt đồ bằng hai ngón, vịn đứng', 'Pincer grip and pulling up to stand'),
      doing: t(
        [
          'Bé nhặt đồ nhỏ bằng ngón cái và ngón trỏ, kể cả những thứ không nên cho vào miệng.',
          'Bé vịn đứng, một số bé bắt đầu vịn đi men theo đồ đạc.',
          'Bé hiểu nhiều hơn những gì bé nói được: dừng lại khi nghe “không”, tìm đồ ba mẹ vừa giấu.',
        ],
        [
          'Your baby picks up small things between thumb and forefinger, including things that should not go in the mouth.',
          'Your baby pulls up to stand, and some start cruising along furniture.',
          'Your baby understands more than they can say: pauses at “no” and finds a toy you just hid.',
        ],
      ),
      tryThis: t(
        [
          'Cúi sát sàn tìm và cất vật nhỏ như pin cúc áo, hạt, đồng xu: đây là tuổi bé rất dễ hóc dị vật.',
          'Dạy bé vẫy tay “bai bai”, vỗ tay theo bài hát và chơi trò “đến lượt con, đến lượt mẹ”.',
          'Cho bé ăn 3–4 bữa mỗi ngày cùng cả nhà, món mềm cắt nhỏ, để bé tự bốc và tập cầm thìa.',
        ],
        [
          'Get down to floor level and clear small things like button batteries, nuts and coins: choking risk is high now.',
          'Teach waving “bye-bye”, clapping along to songs and “my turn, your turn” games.',
          'Offer 3–4 meals a day with the family, soft food cut small, and let your baby self-feed and try a spoon.',
        ],
      ),
      articleIds: ['art_solids_choking_safety', 'art_home_safety_falls'],
      milestoneIds: [
        'pincer_grasp',
        'stands',
        'cruises',
        'understands_no',
        'finds_hidden',
        'waves_bye',
      ],
      audience: [...FAMILY_PLAY],
      cover: null,
      sources: [S.cdc12m, S.cdc9m, S.whoComplementary],
    },
  },
  {
    id: 'stg_m10',
    reviewerLabel: DEV,
    data: {
      age: { unit: 'month', from: 10, to: 11 },
      title: t('Vịn đi men, hiểu lời và bắt chước', 'Cruising, understanding and copying'),
      doing: t(
        [
          'Nhiều bé vịn đi men quanh bàn ghế; có bé đứng một mình được trong giây lát.',
          'Bé bỏ đồ vào hộp rồi lấy ra, bắt chước cử chỉ như vẫy tay, vỗ tay.',
          'Bé có thể gọi “ba”, “mẹ” có chủ đích hoặc dùng một âm riêng cho người thân.',
        ],
        [
          'Many babies cruise around furniture; some stand alone for a moment.',
          'Your baby puts things into a container and takes them out, and copies gestures like waving and clapping.',
          'Your baby may say “mama” or “dada” on purpose, or use a special sound for a loved one.',
        ],
      ),
      tryThis: t(
        [
          'Cho bé đẩy thùng giấy hay đồ chơi đẩy chắc chắn để tập đi trên sàn an toàn; không dùng xe tập đi có bánh.',
          'Khi bé chỉ hoặc nói, đáp lại và nói thêm: bé nói “bóng”, ba mẹ nói “Quả bóng đỏ đây rồi!”',
          'Khóa tủ thuốc, hóa chất; để phích nước, nồi canh nóng xa mép bàn vì bé với cao hơn mỗi ngày.',
        ],
        [
          'Let your baby push an empty box or a sturdy push toy to practise walking on a safe floor; avoid wheeled baby walkers.',
          'When your baby points or says a word, answer and add more: “Ball!” becomes “Yes, the red ball!”',
          'Lock away medicines and chemicals; keep flasks and hot pots away from table edges as your baby reaches higher.',
        ],
      ),
      articleIds: ['art_talk_play_first_year', 'art_home_safety_falls'],
      milestoneIds: ['cruises', 'container_play', 'waves_bye', 'first_word', 'stands'],
      audience: [...FAMILY_PLAY],
      cover: null,
      sources: [S.cdc12m, S.hcBaby],
    },
  },
  {
    id: 'stg_m11',
    reviewerLabel: DEV,
    data: {
      age: { unit: 'month', from: 11, to: 12 },
      title: t(
        'Sắp tròn 1 tuổi: bước chân và từ đầu tiên',
        'Nearly one: first steps and first words',
      ),
      doing: t(
        [
          'Có bé đã tự đi vài bước, có bé chưa: nhiều bé biết đi trong khoảng từ 9 đến 18 tháng.',
          'Bé có thể nói từ đầu tiên, hiểu nhiều từ quen và làm theo yêu cầu đơn giản kèm cử chỉ.',
          'Bé thích tự ăn, nhặt đồ nhỏ khéo hơn và uống được bằng cốc không nắp khi có người cầm giúp.',
        ],
        [
          'Some babies take a few steps alone, others not yet: many walk somewhere between 9 and 18 months.',
          'Your baby may say a first word, understands many familiar words and follows simple requests with a gesture.',
          'Your baby loves feeding themselves, picks up small things more deftly and drinks from an open cup you hold.',
        ],
      ),
      tryThis: t(
        [
          'Cho bé ăn cùng mâm với gia đình: món mềm, cắt nhỏ, nêm nhạt; chưa dùng mật ong trước 12 tháng.',
          'Đọc sách có hình to, chỉ và hỏi “Con mèo đâu?”, chờ bé chỉ: bé học từ qua trò hỏi đáp.',
          'Đối chiếu sổ tiêm chủng với cán bộ y tế và cho bé khám răng lần đầu quanh mốc 1 tuổi.',
        ],
        [
          'Let your baby eat with the family: soft, small pieces, lightly seasoned; no honey before 12 months.',
          'Read books with big pictures, point and ask “Where’s the cat?”, then wait: question games build words.',
          'Check the vaccination record with your health worker, and plan a first dental check around the first birthday.',
        ],
      ),
      articleIds: ['art_solids_textures_by_month', 'art_teething'],
      milestoneIds: [
        'first_steps',
        'first_word',
        'cruises',
        'pincer_grasp',
        'waves_bye',
        'finds_hidden',
        'container_play',
      ],
      audience: [...FAMILY_PLAY],
      cover: null,
      sources: [S.cdc12m, S.whoComplementary, S.hcTeething],
    },
  },
  {
    id: 'stg_m12',
    reviewerLabel: DEV,
    data: {
      age: { unit: 'month', from: 12, to: 15 },
      title: t(
        'Chập chững những bước đầu và muốn tự làm',
        'Toddling first steps, wanting to do it alone',
      ),
      doing: t(
        [
          'Bé tập đi những bước đầu, tự bốc ăn và thử dùng đồ vật đúng cách như cốc, lược, điện thoại.',
          'Bé chỉ tay để đòi thứ mình muốn, vỗ tay khi vui và thử nói thêm vài từ ngoài “ba”, “mẹ”.',
          'Bé chồng được hai khối, ôm thơm người thân và bắt chước trẻ khác khi chơi.',
        ],
        [
          'Your toddler takes first steps, feeds themselves with fingers and tries to use things the right way.',
          'Your toddler points to ask for things, claps when excited and tries a few words besides “mama” and “dada”.',
          'Your toddler stacks two blocks, hugs and kisses family and copies other children at play.',
        ],
      ),
      tryThis: t(
        [
          'Nhắc lại và nói rộng từ bé dùng: bé nói “ba”, ba mẹ nói “Ba đi làm về rồi!”',
          'Mỗi ngày đọc sách, hát kèm cử chỉ; tránh cho bé xem màn hình, trừ gọi video với người thân.',
          'Bé cần khoảng 11–14 giờ ngủ mỗi ngày kể cả giấc ngày; giữ giờ ngủ, giờ ăn đều đặn.',
        ],
        [
          'Repeat and expand your toddler’s words: “Dada!” becomes “Yes, Dada’s home from work!”',
          'Read and sing with actions every day; avoid screens apart from video calls with family.',
          'Toddlers need about 11–14 hours of sleep a day including naps; keep sleep and meal times regular.',
        ],
      ),
      articleIds: ['art_screens_language', 'art_sleep_by_age'],
      milestoneIds: [
        'first_steps',
        'points_to_ask',
        'uses_objects_right',
        'claps_excited',
        'stacks_blocks',
        'shows_affection',
        'first_word',
      ],
      audience: [...FAMILY_PLAY],
      cover: null,
      sources: [S.cdc15m, S.cdc12m, S.whoSitLessPlayMore],
    },
  },
  {
    id: 'stg_m15',
    reviewerLabel: DEV,
    data: {
      age: { unit: 'month', from: 15, to: 18 },
      title: t(
        'Bé chỉ trỏ, tập nói và khám phá không ngừng',
        'Pointing, talking and always exploring',
      ),
      doing: t(
        [
          'Bé đi một mình vững hơn, tự trèo lên xuống ghế và bắt đầu vẽ nguệch ngoạc.',
          'Bé chỉ để cho ba mẹ xem điều thú vị, cố nói từ ba từ trở lên và làm theo lời dặn một bước.',
          'Bé đi khám phá rồi ngoái lại tìm ba mẹ; những cơn ăn vạ bắt đầu xuất hiện, rất bình thường ở tuổi này.',
        ],
        [
          'Your toddler walks alone more steadily, climbs on and off chairs and starts to scribble.',
          'Your toddler points to show you interesting things, tries three or more words and follows one-step directions.',
          'Your toddler explores, then looks back for you; tantrums start to appear, which is very normal at this age.',
        ],
      ),
      tryThis: t(
        [
          'Gọi tên cảm xúc và cho bé chọn giữa hai thứ, như “áo đỏ hay áo xanh?”, để bé thấy mình được lắng nghe.',
          'Cho bé uống bằng cốc không nắp và tự xúc thìa; chấp nhận bày bừa, để bé tự quyết ăn bao nhiêu.',
          'Bé trèo giỏi: chặn cửa sổ, ban công, cố định tủ kệ và ti vi; không kê ghế cạnh cửa sổ.',
        ],
        [
          'Name feelings and offer a choice of two, like “red top or blue top?”, so your toddler feels heard.',
          'Let your toddler drink from an open cup and use a spoon; accept the mess and let them decide how much to eat.',
          'Your climber needs safe windows and balconies, anchored furniture and TV, and no chairs next to windows.',
        ],
      ),
      articleIds: ['art_screens_language', 'art_home_safety_falls'],
      milestoneIds: [
        'points_to_show',
        'says_three_words',
        'follows_direction',
        'climbs_furniture',
        'scribbles',
        'checks_back',
      ],
      audience: [...FAMILY_PLAY],
      cover: null,
      sources: [S.cdc18m, S.cdc15m, S.whoSitLessPlayMore],
    },
  },
  {
    id: 'stg_m18',
    reviewerLabel: DEV,
    data: {
      age: { unit: 'month', from: 18, to: 24 },
      title: t(
        'Ghép hai từ, chơi giả vờ và rất tự lập',
        'Two-word phrases, pretend play, independence',
      ),
      doing: t(
        [
          'Vốn từ của bé tăng nhanh; gần 2 tuổi, nhiều bé ghép được hai từ như “uống sữa”, “mẹ bế”.',
          'Bé chạy, đá bóng, bước lên vài bậc cầu thang và tự xúc ăn bằng thìa.',
          'Bé chơi giả vờ, để ý khi người khác buồn và nhìn nét mặt ba mẹ để biết nên phản ứng thế nào.',
        ],
        [
          'Your toddler’s vocabulary grows fast; near 2, many put two words together like “more milk”.',
          'Your toddler runs, kicks a ball, walks up a few stairs and eats with a spoon.',
          'Your toddler pretend plays, notices when someone is upset and checks your face in new situations.',
        ],
      ),
      tryThis: t(
        [
          'Nói lại đúng từ bé phát âm chưa rõ mà không bắt bé nhắc lại: bé nói “ữa”, ba mẹ nói “Con muốn uống sữa à?”',
          'Chơi đồ hàng, ru gấu bông ngủ, nhờ bé cất đồ chơi vào giỏ và khen sự cố gắng của bé.',
          'Hỏi bác sĩ nếu bé chưa nói vài từ, chưa chỉ tay, chưa ghép từ gần 2 tuổi, hoặc bé mất kỹ năng đã có.',
        ],
        [
          'Say unclear words back correctly without making your toddler repeat: “ilk” becomes “You want some milk?”',
          'Play kitchen, put teddy to bed, ask your toddler to tidy toys into a basket and praise the effort.',
          'Ask a doctor if your toddler has few words, does not point, is not joining words near 2, or loses skills.',
        ],
      ),
      articleIds: ['art_screens_language', 'art_separation_anxiety'],
      milestoneIds: [
        'two_word_phrases',
        'pretend_play',
        'kicks_ball',
        'runs',
        'notices_upset',
        'two_hands_task',
      ],
      audience: [...FAMILY_PLAY],
      cover: null,
      sources: [S.cdc24m, S.cdc18m, S.whoSitLessPlayMore],
    },
  },
  // 24–36 months (D-080), from docs/product/content-review-2026-10/library-24-36-months.json.
  {
    id: 'stg_m24',
    reviewerLabel: 'Nhóm chuyên môn · Phát triển trẻ em',
    data: {
      age: {
        unit: 'month',
        from: 24,
        to: 30,
      },
      title: {
        vi: 'Câu ngắn, câu hỏi và trí tưởng tượng',
        en: 'Short sentences and a big imagination',
      },
      doing: {
        vi: [
          'Bé ghép từ thành câu ngắn có từ chỉ hành động như “chó chạy”; nhiều bé nói khoảng 50 từ, gọi tên đồ vật trong sách.',
          'Bé bật nhảy hai chân, vặn nắp hộp, xoay tay nắm cửa và tự cởi được áo khoác đã mở cúc.',
          'Bé chơi giả vờ, coi khối gỗ là cái bánh, chơi cạnh các bạn và hay gọi “nhìn con này!”.',
        ],
        en: [
          'Your child puts words together with an action, like “doggie run”; many say about 50 words and name things in books.',
          'Your child jumps with both feet, unscrews lids, turns door handles and takes off an open jacket.',
          'Your child pretends a block is a cake, plays next to other children and calls “look at me!”.',
        ],
      },
      tryThis: {
        vi: [
          'Đọc sách tranh mỗi ngày, hỏi “Cái gì đây?”, “Bạn đang làm gì?” rồi chờ bé trả lời: bé học từ qua hỏi đáp.',
          'Bé đã mở được cửa, nắp lọ: khoá cửa ban công, cầu thang; cất thuốc, hoá chất trên cao, trong tủ khoá.',
          'Cho bé giúp việc nhỏ như cất đồ chơi, xếp dép, và dặn hai bước: “Cất xe rồi đi rửa tay nhé.”',
        ],
        en: [
          'Read picture books daily, ask “What’s this?” or “What is she doing?” and wait: question games build words.',
          'They can open doors and jars now: lock balcony and stair doors, keep medicines and chemicals high and locked.',
          'Let your child help with small jobs like tidying toys, and give two-step requests: “Park the car, then wash hands.”',
        ],
      },
      articleIds: ['art_toddler_tantrums', 'art_screens_language'],
      milestoneIds: [
        'action_word_phrases',
        'jumps_two_feet',
        'twists_lids',
        'pretend_with_objects',
        'two_step_directions',
        'plays_near_children',
        'shows_look_at_me',
      ],
      audience: ['coParent', 'caregiver', 'relative'],
      cover: null,
      sources: [
        {
          label: 'CDC — Learn the Signs. Act Early.: Milestones by 30 months',
          url: 'https://www.cdc.gov/act-early/milestones/30-months.html',
        },
        {
          label: 'AAP · HealthyChildren.org · Developmental milestones: 2 year olds',
          url: 'https://www.healthychildren.org/English/ages-stages/toddler/Pages/Developmental-Milestones-2-Year-Olds.aspx',
        },
        {
          label: 'WHO — To grow up healthy, children need to sit less and play more (2019)',
          url: 'https://www.who.int/news/item/24-04-2019-to-grow-up-healthy-children-need-to-sit-less-and-play-more',
        },
      ],
    },
  },
  {
    id: 'stg_m30',
    reviewerLabel: 'Nhóm chuyên môn · Phát triển trẻ em',
    data: {
      age: {
        unit: 'month',
        from: 30,
        to: 36,
      },
      title: {
        vi: 'Hỏi “tại sao”, trò chuyện và sẵn sàng đi lớp',
        en: 'Asking “why”, chatting and getting ready for preschool',
      },
      doing: {
        vi: [
          'Bé trò chuyện qua lại vài lượt, hỏi “ai”, “cái gì”, “ở đâu”, nói được tên mình; người ngoài hiểu phần lớn lời bé.',
          'Bé tự xúc ăn bằng nĩa, thìa, xâu hạt to, tự mặc quần rộng hay áo khoác và vẽ theo được nét tròn.',
          'Bé để ý các bạn, nhập vào chơi cùng, và khi chia tay ở nhà trẻ thường dịu lại trong khoảng 10 phút.',
        ],
        en: [
          'Your child chats back and forth, asks who, what and where, says their name, and others understand most of it.',
          'Your child uses a fork, threads large beads, pulls on loose trousers or a jacket and copies a circle.',
          'Your child notices other children and joins in, and usually settles within about 10 minutes of a goodbye.',
        ],
      },
      tryThis: {
        vi: [
          'Trả lời câu hỏi “tại sao” ngắn gọn, đúng, và hỏi lại bé: “Con nghĩ vì sao?” để bé tập suy nghĩ, diễn đạt.',
          'Tập đi vệ sinh khi bé có dấu hiệu sẵn sàng như báo khi tã ướt, giữ tã khô lâu; khen, không la mắng khi bé lỡ.',
          'Chuẩn bị đi lớp: kể trước về lớp, đến thăm cùng bé, giữ nghi thức chào ngắn và đón đúng giờ đã hứa.',
        ],
        en: [
          'Answer “why” questions briefly and honestly, and ask back: “Why do you think?” so your child practises explaining.',
          'Start toilet training when your child shows readiness, like telling you about a wet diaper; praise, never scold.',
          'Prepare for preschool: talk about it, visit together, keep goodbyes short and pick up when you promised.',
        ],
      },
      articleIds: ['art_separation_anxiety', 'art_toddler_tantrums'],
      milestoneIds: [
        'asks_questions',
        'back_and_forth_talk',
        'uses_fork',
        'draws_circle',
        'settles_after_goodbye',
      ],
      audience: ['coParent', 'caregiver', 'relative'],
      cover: null,
      sources: [
        {
          label: 'CDC — Learn the Signs. Act Early.: Milestones by 3 years',
          url: 'https://www.cdc.gov/act-early/milestones/3-years.html',
        },
        {
          label: 'NHS — How to potty train',
          url: 'https://www.nhs.uk/baby/babys-development/potty-training-and-bedwetting/how-to-potty-train/',
        },
        {
          label: 'AAP · HealthyChildren.org · Developmental milestones: 2 year olds',
          url: 'https://www.healthychildren.org/English/ages-stages/toddler/Pages/Developmental-Milestones-2-Year-Olds.aspx',
        },
      ],
    },
  },
];
