import type {
  NutrientContent,
  NutritionRuleContent,
  NutritionStageContent,
} from '@child-life/contracts';

// Small, complete Dinh dưỡng items (D-083) for the server tests, independent of the expert seed
// (`nutrition-seed.ts`), which the content team fills on its own schedule.

const l = (vi: string, en: string) => ({ vi, en });

export function stageFixture(from = 6, to = 9, nutrientIds: string[] = []): NutritionStageContent {
  return {
    ageMonths: { from, to },
    title: l('Bắt đầu ăn dặm', 'Starting solids'),
    summary: l(
      'Bé làm quen với thức ăn đặc, sữa vẫn là nguồn chính.',
      'Baby gets to know solid food; milk is still the main source.',
    ),
    milk: {
      perFeedMl: { min: 180, max: 240 },
      feedsPerDay: { min: 4, max: 5 },
      perDayMl: { min: 600, max: 900 },
      breastfeedingNote: l('Cho bú theo nhu cầu.', 'Breastfeed on demand.'),
    },
    solids: {
      meals: l('2–3 bữa', '2–3 meals'),
      texture: l('Bột loãng → cháo rây, nghiền', 'Thin purée → mashed'),
    },
    sampleDay: [
      { slot: 'morning', kind: 'milk', text: l('Bú sữa khi thức dậy', 'Milk on waking') },
      { slot: 'noon', kind: 'solids', text: l('Cháo rây với rau', 'Sieved porridge with greens') },
    ],
    nutrientIds,
    tips: [
      {
        title: l('Cho bé tự khám phá', 'Let baby explore'),
        body: l('Để bé cầm nắm miếng thức ăn mềm.', 'Let baby hold soft pieces of food.'),
      },
    ],
    sources: [{ label: 'WHO', url: 'https://www.who.int/health-topics/complementary-feeding' }],
  };
}

export function nutrientFixture(withCampaign = false): NutrientContent {
  return {
    key: withCampaign ? 'vitaminA' : 'iron',
    name: withCampaign ? l('Vitamin A', 'Vitamin A') : l('Sắt', 'Iron'),
    subtitle: l(
      'Dự trữ từ lúc sinh giảm dần · thịt, trứng',
      'Stores from birth run low · meat, eggs',
    ),
    focus: {
      ageMonths: { from: 6, to: 24 },
      label: l('Quan trọng từ 6 tháng', 'Important from 6 months'),
      note: l('', ''),
    },
    why: l('Sắt giúp bé tạo máu và phát triển trí não.', 'Iron helps blood and brain development.'),
    foods: [l('Thịt bò', 'Beef'), l('Trứng', 'Eggs'), l('Gan gà', 'Chicken liver')],
    tip: null,
    byAge: [
      {
        ageMonths: { from: 6, to: 12 },
        label: l('6–11 tháng', '6–11 months'),
        text: l('Mỗi bữa có thịt, cá hoặc trứng.', 'Meat, fish or egg at every meal.'),
      },
    ],
    warning: l('Dạng thuốc chỉ theo chỉ định bác sĩ.', "Supplements only on a doctor's advice."),
    campaign: withCampaign
      ? {
          rounds: [
            { month: 6, fromDay: 1, toDay: 2 },
            { month: 12, fromDay: 1, toDay: 2 },
          ],
          ageMonths: { from: 6, to: 37 },
          place: l('Trạm y tế phường, xã', 'Ward health station'),
        }
      : null,
    sources: [],
  };
}

export function ruleFixture(): NutritionRuleContent {
  return {
    metric: 'weight',
    condition: 'belowRange',
    days: null,
    ageMonths: { from: 0, to: 37 },
    banner: l(
      'Hai lần cân gần nhất của bé thấp hơn khoảng chuẩn WHO. Đây không phải chẩn đoán, hãy trao đổi với bác sĩ.',
      'The last two weights are below the WHO range. This is not a diagnosis; talk to a doctor.',
    ),
    tips: [
      {
        title: l('Thêm bữa phụ', 'Add a snack'),
        body: l('Thêm một bữa phụ giàu năng lượng.', 'Add an energy-rich snack.'),
      },
    ],
    remindAfterDays: 14,
    export: true,
  };
}
