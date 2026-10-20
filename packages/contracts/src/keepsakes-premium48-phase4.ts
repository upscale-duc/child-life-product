import {
  defaultKeepsakeVideoBrand,
  keepsakeTemplateSchema,
  type KeepsakeLayer,
  type KeepsakeTemplate,
} from './keepsakes.js';
import {
  keepsakePersonalizationSchema,
  type KeepsakePersonalization,
} from './keepsake-personalization.js';
const l = (vi: string, en: string) => ({ vi, en }),
  group = l('Lớn từng ngày', 'Growing Every Day');
const name = {
  key: 'babyName',
  label: l('Tên bé', 'Baby’s name'),
  type: 'text',
  source: 'babyName',
  max: 30,
  required: true,
} as const;
const month = {
  key: 'monthNumber',
  label: l('Tháng tuổi (01–12)', 'Month (01–12)'),
  type: 'month',
  max: 2,
  required: true,
} as const;
const discovery = {
  key: 'discovery',
  label: l('Điều con khám phá (tùy chọn)', 'A new discovery (optional)'),
  type: 'text',
  max: 60,
  required: false,
} as const;
const memory = {
  key: 'memoryLine',
  label: l('Điều muốn nhớ (tùy chọn)', 'A memory to keep (optional)'),
  type: 'text',
  max: 60,
  required: false,
} as const;
const dates = [
  {
    key: 'thenDate',
    label: l('Ngày ảnh trước (nếu biết)', 'Earlier photo date (if known)'),
    type: 'date',
    max: 10,
    required: false,
  },
  {
    key: 'nowDate',
    label: l('Ngày ảnh sau (nếu biết)', 'Later photo date (if known)'),
    type: 'date',
    max: 10,
    required: false,
  },
] as const;
const range = { start: 'thenDate', end: 'nowDate' };
const c = (
  key: string,
  label: ReturnType<typeof l>,
  vi: string,
  en: string,
  editable = false,
  requires: string[] = [],
  fallback = l('', ''),
) => ({ key, label, text: l(vi, en), editable, requires, fallback, max: 160 });
const dateCopy = [
  c(
    'photoLabel0',
    l('Ảnh trước', 'Earlier photo'),
    'Ngày ấy · {thenDate}',
    'Then · {thenDate}',
    false,
    ['thenDate', 'nowDate'],
    l('Ngày ấy', 'Then'),
  ),
  c(
    'photoLabel1',
    l('Ảnh sau', 'Later photo'),
    'Bây giờ · {nowDate}',
    'Now · {nowDate}',
    false,
    ['thenDate', 'nowDate'],
    l('Bây giờ', 'Now'),
  ),
  c('detail1', l('Số ngày', 'Days apart'), '{elapsedDays}', '{elapsedDays}', false, [
    'elapsedDays',
  ]),
  c('detail2', l('Đơn vị ngày', 'Days unit'), '{elapsedUnit}', '{elapsedUnit}', false, [
    'elapsedDays',
  ]),
];
const chapterCard = keepsakePersonalizationSchema.parse({
  group,
  fields: [name, month, discovery, memory],
  beats: [],
  copy: [
    c('headline', l('Nhãn', 'Label'), 'TRANG THÁNG CỦA CON', 'YOUR MONTHLY CHAPTER'),
    c(
      'title',
      l('Tiêu đề', 'Title'),
      'Tháng {monthNumber} của {babyName}.',
      '{babyName}, month {monthNumber}.',
      true,
      ['monthNumber'],
      l('Một trang tháng của {babyName}.', 'A monthly page for {babyName}.'),
    ),
    c('ageNumber', l('Số tháng', 'Month number'), '{monthNumber}', '{monthNumber}'),
    c('ageUnit', l('Nhãn tháng', 'Month label'), 'THÁNG', 'MONTH'),
    c(
      'message',
      l('Khám phá', 'Discovery'),
      'Tháng này, con khám phá {discovery}.',
      'This month, you discovered {discovery}.',
      true,
      ['discovery'],
      l('Thêm những điều mới mỗi ngày.', 'Something new, every day.'),
    ),
    c(
      'detail0',
      l('Điều muốn nhớ', 'Memory'),
      'Nhà mình muốn giữ lại: {memoryLine}.',
      'A memory we are keeping: {memoryLine}.',
      true,
      ['memoryLine'],
    ),
  ],
});
const compareCard = keepsakePersonalizationSchema.parse({
  group,
  fields: [name, ...dates],
  dateRange: range,
  beats: [],
  copy: [
    c('headline', l('Nhãn', 'Label'), 'NGÀY ẤY, BÂY GIỜ', 'THEN & NOW'),
    c(
      'title',
      l('Tiêu đề', 'Title'),
      'Ngày ấy. Bây giờ. Vẫn là con.',
      'Then. Now. Always you.',
      true,
    ),
    c(
      'message',
      l('Lời nhắn', 'Message'),
      'Nhìn hai tấm ảnh mới thấy con đã lớn thêm biết bao.',
      'Two photos, and so much growing in between.',
      true,
    ),
    ...dateCopy,
    c('signature', l('Tên bé', 'Baby’s name'), '{babyName}', '{babyName}'),
  ],
});
const scene = (i: number, vi: string, en: string, requires: string[] = [], fallback = l('', '')) =>
  c(`scene${i}`, l(`Cảnh ${i}`, `Scene ${i}`), vi, en, true, requires, fallback);
const chapterVideo = keepsakePersonalizationSchema.parse({
  group,
  fields: [name, month, discovery, memory],
  beats: [[0], [1, 0], [2], [3, 1], [4, 0, 1, 2, 3]].map((slots, i) => ({
    slots,
    textKey: `scene${i + 1}`,
  })),
  copy: [
    c('title', l('Tên video', 'Video title'), 'Trang tháng của con', 'Your Monthly Chapter'),
    scene(
      1,
      'Chương tháng {monthNumber}.',
      'Chapter: month {monthNumber}.',
      ['monthNumber'],
      l('Một chương tháng của con.', 'A monthly chapter of you.'),
    ),
    scene(2, 'Có điều quen thuộc…', 'Some things felt familiar…'),
    scene(
      3,
      'Có một khám phá mới: {discovery}.',
      'One new discovery: {discovery}.',
      ['discovery'],
      l('Thêm những điều mới mỗi ngày.', 'Something new, every day.'),
    ),
    scene(4, 'Và những ngày chỉ đơn giản là ở bên nhau.', 'And days spent simply being together.'),
    scene(5, 'Một tháng nữa được giữ lại.', 'Another month, kept close.'),
    c('month', l('Số tháng', 'Month number'), '{monthNumber}', '{monthNumber}'),
    c('signature', l('Tên bé', 'Baby’s name'), '{babyName}', '{babyName}'),
    c(
      'detail0',
      l('Ghi nhớ cuối', 'Closing memory'),
      'Giữ lại: {memoryLine}.',
      'Keeping: {memoryLine}.',
      true,
      ['memoryLine'],
    ),
  ],
});
const compareVideo = keepsakePersonalizationSchema.parse({
  group,
  fields: [name, ...dates],
  dateRange: range,
  beats: [[0], [0], [0, 1], [1], [0, 1]].map((slots, i) => ({ slots, textKey: `scene${i + 1}` })),
  copy: [
    c('title', l('Tên video', 'Video title'), 'Ngày ấy, bây giờ', 'Then & Now'),
    scene(1, 'Đây là con, ngày ấy.', 'This was you, then.'),
    scene(
      2,
      'Một khoảnh khắc tưởng như vừa mới hôm qua.',
      'A moment that still feels like yesterday.',
    ),
    scene(
      3,
      'Giữa hai tấm ảnh là bao ngày bên nhau.',
      'So many days together between these pictures.',
    ),
    scene(4, 'Và đây là con, bây giờ.', 'And this is you, now.'),
    scene(5, 'Lớn thêm rồi, {babyName} ơi.', 'Look how you have grown, {babyName}.'),
    ...dateCopy,
    c('signature', l('Tên bé', 'Baby’s name'), '{babyName}', '{babyName}'),
  ],
});
const rect = (r: number[]) => ({ x: r[0]!, y: r[1]!, w: r[2]!, h: r[3]! });
const text = (
  field: string,
  r: number[],
  size: number,
  font = 'beVietnamPro',
  color = 'ink',
  maxLines = 2,
  weight = 400,
): KeepsakeLayer =>
  ({
    type: 'text',
    field,
    rect: rect(r),
    size,
    font,
    color,
    maxLines,
    weight,
    opacity: 1,
    align: 'left',
    italic: false,
  }) as KeepsakeLayer;
const photo = (slot: number, r: number[]): KeepsakeLayer => ({
  type: 'photo',
  slot,
  rect: rect(r),
  shape: 'rect',
  radius: 0.003,
  rotate: 0,
});
const image = (asset: string, r: number[], opacity = 1): KeepsakeLayer => ({
  type: 'image',
  asset,
  rect: rect(r),
  fit: 'fill',
  rotate: 0,
  opacity,
});
const brand = (s: boolean): KeepsakeLayer => ({
  type: 'brand',
  kind: 'lockup',
  rect: rect([0.065, 0.947, 0.22, s ? 0.018 : 0.025]),
  color: 'ink',
  opacity: 0.6,
});
const role = (key: string) =>
  key.replace(/^p48-/, '').replace(/-([a-z])/g, (_, v: string) => v.toUpperCase());
/** Four phase 4 templates. Dates are supplied by parents; intervals are derived, never inferred. */
export function premium48Phase4(
  assets: Record<string, string> = {},
  music: { chapter?: string; compare?: string } = {},
): KeepsakeTemplate[] {
  const art = (key: string, r: number[], opacity = 1): KeepsakeLayer[] =>
    assets[key] ? [image(assets[key]!, r, opacity)] : [];
  const base = (
    id: string,
    kind: 'card' | 'video',
    compare: boolean,
    personalization: KeepsakePersonalization,
  ) => ({
    id,
    kind,
    version: 1,
    name: compare
      ? l('Ngày ấy, bây giờ', 'Then & Now')
      : l('Trang tháng của con', 'Your Monthly Chapter'),
    description: group,
    personalization,
    tier: 'premium',
    status: 'published',
    order: compare ? 9 : 8,
    occasions: [],
    ageDays: null,
    assets: Object.fromEntries(
      Object.entries(assets)
        .filter(
          ([key]) =>
            key === 'p48-grain' || key.startsWith(compare ? 'p48-compare-' : 'p48-chapter-'),
        )
        .map(([key, value]) => [key === 'p48-grain' ? 'paperGrain' : role(key), value]),
    ),
    photos: { min: 1, max: 1 },
    scenes: [],
    texts: [],
    palette: compare
      ? { background: '#F8F4EC', ink: '#48434A', accent: '#B5A2B4' }
      : { background: '#EDE0C9', ink: '#35434D', accent: '#B66C45' },
    palettes: [],
    durationSec: null,
    thumb: null,
    defaultMusic: null,
    preview: null,
    brand: null,
  });
  const chapter = (s: boolean): KeepsakeLayer[] => [
    { type: 'background', color: 'background', asset: null },
    ...art('p48-grain', [0, 0, 1, 1], 0.035),
    ...art('p48-chapter-masthead-rule', [0.065, s ? 0.07 : 0.04, 0.72, 0.018]),
    text('headline', [0.065, s ? 0.106 : 0.078, 0.7, 0.035], 0.026, 'beVietnamPro', 'ink', 1, 600),
    text('title', [0.065, s ? 0.16 : 0.13, 0.7, s ? 0.095 : 0.13], 0.065, 'lora', 'ink', 2, 600),
    ...art('p48-chapter-month-tab', [0.805, s ? 0.074 : 0.045, 0.135, s ? 0.1 : 0.142]),
    text(
      'ageNumber',
      [0.822, s ? 0.085 : 0.062, 0.108, s ? 0.052 : 0.07],
      0.085,
      'lora',
      '#FFFCF6',
      1,
      600,
    ),
    text(
      'ageUnit',
      [0.82, s ? 0.14 : 0.137, 0.11, 0.029],
      0.026,
      'beVietnamPro',
      '#FFFCF6',
      1,
      600,
    ),
    photo(0, [0.065, s ? 0.3 : 0.3, 0.56, s ? 0.355 : 0.415]),
    ...art('p48-chapter-hero-frame', [0.053, s ? 0.29 : 0.29, 0.584, s ? 0.375 : 0.435]),
    photo(1, [0.665, s ? 0.3 : 0.3, 0.27, s ? 0.165 : 0.195]),
    ...art('p48-chapter-small-frame', [0.655, s ? 0.292 : 0.292, 0.29, s ? 0.181 : 0.211]),
    photo(2, [0.665, s ? 0.49 : 0.52, 0.27, s ? 0.165 : 0.195]),
    ...art('p48-chapter-small-frame', [0.655, s ? 0.482 : 0.512, 0.29, s ? 0.181 : 0.211]),
    ...art('p48-chapter-divider', [0.065, s ? 0.695 : 0.745, 0.87, 0.018]),
    text(
      'message',
      [0.065, s ? 0.735 : 0.78, 0.87, s ? 0.06 : 0.07],
      0.034,
      'beVietnamPro',
      'ink',
      2,
    ),
    text(
      'detail0',
      [0.065, s ? 0.835 : 0.86, 0.87, s ? 0.06 : 0.07],
      0.034,
      'beVietnamPro',
      'ink',
      2,
    ),
    brand(s),
  ];
  const compare = (s: boolean): KeepsakeLayer[] => [
    { type: 'background', color: 'background', asset: null },
    ...art('p48-grain', [0, 0, 1, 1], 0.03),
    text('headline', [0.065, s ? 0.085 : 0.05, 0.87, 0.035], 0.026, 'beVietnamPro', 'ink', 1, 600),
    text('title', [0.065, s ? 0.14 : 0.105, 0.87, s ? 0.095 : 0.13], 0.062, 'lora', 'ink', 2, 600),
    text(
      'photoLabel0',
      [0.065, s ? 0.275 : 0.25, 0.375, s ? 0.05 : 0.058],
      0.026,
      'beVietnamPro',
      'ink',
      2,
      600,
    ),
    text(
      'photoLabel1',
      [0.56, s ? 0.275 : 0.25, 0.375, s ? 0.05 : 0.058],
      0.026,
      'beVietnamPro',
      'ink',
      2,
      600,
    ),
    photo(0, [0.065, s ? 0.35 : 0.34, 0.375, s ? 0.29 : 0.35]),
    photo(1, [0.56, s ? 0.35 : 0.34, 0.375, s ? 0.29 : 0.35]),
    ...art('p48-compare-matched-frame', [0.055, s ? 0.343 : 0.333, 0.395, s ? 0.304 : 0.364]),
    ...art('p48-compare-matched-frame', [0.55, s ? 0.343 : 0.333, 0.395, s ? 0.304 : 0.364]),
    text('detail1', [0.449, s ? 0.45 : 0.46, 0.102, 0.043], 0.032, 'beVietnamPro', 'ink', 1, 600),
    text('detail2', [0.449, s ? 0.49 : 0.51, 0.102, 0.035], 0.026, 'beVietnamPro', 'ink', 1),
    ...art('p48-compare-timeline', [0.085, s ? 0.676 : 0.726, 0.83, s ? 0.035 : 0.045]),
    text(
      'message',
      [0.065, s ? 0.765 : 0.805, 0.87, s ? 0.08 : 0.08],
      0.034,
      'beVietnamPro',
      'ink',
      3,
    ),
    text(
      'signature',
      [0.065, s ? 0.883 : 0.907, 0.87, 0.032],
      0.026,
      'beVietnamPro',
      'ink',
      1,
      600,
    ),
    brand(s),
  ];
  const hints = (vi: string[], en: string[]) =>
    vi.map((v, i) => ({ hint: l(v, en[i]!), optional: false }));
  return [
    {
      ...base('card_premium48_07', 'card', false, chapterCard),
      photos: { min: 3, max: 3 },
      layouts: { portrait: chapter(false), story: chapter(true) },
      composition: null,
    },
    {
      ...base('card_premium48_08', 'card', true, compareCard),
      photos: { min: 2, max: 2 },
      layouts: { portrait: compare(false), story: compare(true) },
      composition: null,
    },
    {
      ...base('video_premium48_07', 'video', false, chapterVideo),
      photos: { min: 5, max: 5 },
      layouts: null,
      composition: 'PremiumMonthlyChapter',
      durationSec: 35,
      brand: { ...defaultKeepsakeVideoBrand },
      defaultMusic: music.chapter ?? null,
      scenes: hints(
        [
          'Ảnh tiêu biểu tháng',
          'Khoảnh khắc quen thuộc',
          'Ảnh khám phá mới (nếu có)',
          'Ảnh gia đình đời thường',
          'Chân dung cuối tháng',
        ],
        [
          'A portrait from this month',
          'A familiar everyday moment',
          'A discovery, if applicable',
          'An everyday family moment',
          'An end-of-month portrait',
        ],
      ),
    },
    {
      ...base('video_premium48_08', 'video', true, compareVideo),
      photos: { min: 2, max: 2 },
      layouts: null,
      composition: 'PremiumThenNow',
      durationSec: 35,
      brand: { ...defaultKeepsakeVideoBrand },
      defaultMusic: music.compare ?? null,
      scenes: hints(
        ['Ảnh trước; không cần biết ngày', 'Ảnh sau; không cần biết ngày'],
        ['Earlier photo; date optional', 'Later photo; date optional'],
      ),
    },
  ].map((t) => keepsakeTemplateSchema.parse(t));
}
