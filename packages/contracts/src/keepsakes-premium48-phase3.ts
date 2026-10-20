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
const l = (vi: string, en: string) => ({ vi, en });
const group = l('Tháng đầu', 'Our First Month');
const name = {
  key: 'babyName',
  label: l('Tên bé', 'Baby’s name'),
  type: 'text',
  source: 'babyName',
  max: 30,
  required: true,
} as const;
const narrator = {
  key: 'narratorName',
  label: l('Người viết thư (tùy chọn)', 'Letter writer (optional)'),
  type: 'text',
  max: 40,
  required: false,
} as const;
const notes = [
  {
    key: 'favoriteThing',
    label: l('Điều con thích', 'Something you love'),
    suggestion: l('những cái ôm', 'cuddles'),
    type: 'text',
    max: 60,
    required: false,
  },
  {
    key: 'littleDetail',
    label: l('Nét rất riêng', 'Your little signature'),
    suggestion: l('một biểu cảm rất riêng', 'your little expressions'),
    type: 'text',
    max: 60,
    required: false,
  },
  {
    key: 'memoryLine',
    label: l('Điều muốn nhớ', 'A detail to remember'),
    suggestion: l('khoảnh khắc này', 'this little moment'),
    type: 'text',
    max: 60,
    required: false,
  },
];
const c = (
  key: string,
  label: ReturnType<typeof l>,
  vi: string,
  en: string,
  editable = false,
  requires: string[] = [],
  fallback = l('', ''),
) => ({ key, label, text: l(vi, en), editable, requires, fallback, max: 160 });
const noteCard = keepsakePersonalizationSchema.parse({
  group,
  fields: [name, ...notes],
  beats: [],
  copy: [
    c('headline', l('Nhãn', 'Label'), 'NHỮNG ĐIỀU NHỎ VỀ CON', 'LITTLE THINGS ABOUT YOU'),
    c('title', l('Tiêu đề', 'Title'), 'Con của tháng này.', 'You, this month.', true),
    c('label0', l('Nhãn điều con thích', 'Favourite label'), 'Con thích', 'You love'),
    c(
      'detail0',
      l('Điều con thích', 'Something you love'),
      '{favoriteThing}',
      '{favoriteThing}',
      true,
      ['favoriteThing'],
      l('Nhà mình đang khám phá.', 'We are still discovering.'),
    ),
    c('label1', l('Nhãn nét riêng', 'Signature label'), 'Nét rất riêng', 'Your little signature'),
    c(
      'detail1',
      l('Nét rất riêng', 'Your little signature'),
      '{littleDetail}',
      '{littleDetail}',
      true,
      ['littleDetail'],
      l('Từng chút, mình hiểu con.', 'Getting to know you, little by little.'),
    ),
    c('label2', l('Nhãn điều muốn nhớ', 'Memory label'), 'Điều muốn nhớ', 'A detail to remember'),
    c(
      'detail2',
      l('Điều muốn nhớ', 'A detail to remember'),
      '{memoryLine}',
      '{memoryLine}',
      true,
      ['memoryLine'],
      l('Một trang để mình lưu lại.', 'A page for us to keep.'),
    ),
    c('signature', l('Tên bé', 'Baby’s name'), '{babyName}', '{babyName}'),
  ],
});
const letterCard = keepsakePersonalizationSchema.parse({
  group,
  fields: [name, narrator],
  beats: [],
  copy: [
    c('headline', l('Nhãn', 'Label'), 'LÁ THƯ ĐẦY THÁNG', 'A LETTER AT ONE MONTH'),
    c(
      'title',
      l('Lời chào', 'Salutation'),
      'Gửi {babyName}, tròn một tháng tuổi.',
      'Dear {babyName}, at one month old.',
      true,
    ),
    c(
      'message',
      l('Nội dung thư', 'Letter'),
      'Cảm ơn con đã đến. Nhà mình còn nhiều điều phải học, và sẽ cùng con học từng ngày.',
      'Thank you for being here. We have so much to learn, and we will keep learning with you.',
      true,
    ),
    c(
      'signature',
      l('Chữ ký', 'Signature'),
      'Thương con, {narratorName}.',
      'With love, {narratorName}.',
      true,
      ['narratorName'],
      l('Thương con, Nhà mình.', 'With love, Your family.'),
    ),
  ],
});
const scene = (i: number, vi: string, en: string, requires: string[] = [], fallback = l('', '')) =>
  c(`scene${i}`, l(`Cảnh ${i}`, `Scene ${i}`), vi, en, true, requires, fallback);
const noteVideo = keepsakePersonalizationSchema.parse({
  group,
  fields: [name, ...notes],
  beats: [0, 1, 2, 3, 4].map((i) => ({ slots: [i], textKey: `scene${i + 1}` })),
  copy: [
    c('title', l('Tên video', 'Video title'), 'Những điều nhỏ về con', 'Little Things About You'),
    scene(1, 'Nếu kể về con lúc này…', 'If we could capture you right now…'),
    scene(
      2,
      'Sẽ bắt đầu bằng {favoriteThing}.',
      'We would start with {favoriteThing}.',
      ['favoriteThing'],
      l('Mình vẫn đang khám phá điều con thích.', 'We are still discovering what you love.'),
    ),
    scene(
      3,
      'Rồi đến {littleDetail}.',
      'Then there is {littleDetail}.',
      ['littleDetail'],
      l('Rồi đến những nét rất riêng.', 'Then, your own little ways.'),
    ),
    scene(4, 'Và khoảnh khắc này nữa.', 'And this little moment, too.'),
    scene(5, 'Những điều nhỏ làm nên một con rất riêng.', 'The little things that make you, you.'),
    c(
      'favorite',
      l('Nhãn điều con thích', 'Favourite note'),
      '{favoriteThing}',
      '{favoriteThing}',
      true,
      ['favoriteThing'],
      l('Điều con thích', 'What you love'),
    ),
    c(
      'detail',
      l('Nhãn nét riêng', 'Signature note'),
      '{littleDetail}',
      '{littleDetail}',
      true,
      ['littleDetail'],
      l('Nét rất riêng', 'Your little ways'),
    ),
    c(
      'memory',
      l('Nhãn muốn nhớ', 'Memory note'),
      '{memoryLine}',
      '{memoryLine}',
      true,
      ['memoryLine'],
      l('Điều muốn nhớ', 'A moment to keep'),
    ),
    c('signature', l('Tên bé', 'Baby’s name'), '{babyName}', '{babyName}'),
  ],
});
const letterVideo = keepsakePersonalizationSchema.parse({
  group,
  fields: [name, narrator],
  beats: [0, 1, 2, 3, 4].map((i) => ({ slots: [i], textKey: `scene${i + 1}` })),
  copy: [
    c('title', l('Tên video', 'Video title'), 'Lá thư đầy tháng', 'A Letter at One Month'),
    scene(1, 'Gửi con của một tháng tuổi…', 'Dear little one, at one month old…'),
    scene(2, 'Có những ngày thật dài.', 'Some days have felt very long.'),
    scene(3, 'Có những cái ôm chẳng muốn rời.', 'Some cuddles never long enough.'),
    scene(
      4,
      'Mình không cần làm mọi thứ thật hoàn hảo.',
      'We do not need every day to be perfect.',
    ),
    scene(5, 'Chỉ muốn có mặt, cùng con lớn lên.', 'We just want to be here, growing with you.'),
    c(
      'signature',
      l('Chữ ký', 'Signature'),
      'Thương con, {narratorName}.',
      'With love, {narratorName}.',
      true,
      ['narratorName'],
      l('Thương con, Nhà mình.', 'With love, Your family.'),
    ),
    c('baby', l('Tên bé', 'Baby’s name'), '{babyName}', '{babyName}'),
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
const photo = (r: number[], shape: 'rect' | 'circle' = 'rect'): KeepsakeLayer => ({
  type: 'photo',
  slot: 0,
  rect: rect(r),
  shape,
  radius: 0.008,
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
  rect: rect([0.067, 0.947, 0.22, s ? 0.018 : 0.025]),
  color: 'ink',
  opacity: 0.6,
});
const role = (key: string) =>
  key.replace(/^p48-/, '').replace(/-([a-z])/g, (_, v: string) => v.toUpperCase());
/** Phase 3: two single-photo cards and two five-photo videos; proposed notes require an explicit user action. */
export function premium48Phase3(
  assets: Record<string, string> = {},
  music: { observe?: string; letter?: string } = {},
): KeepsakeTemplate[] {
  const art = (key: string, r: number[], opacity = 1): KeepsakeLayer[] =>
    assets[key] ? [image(assets[key]!, r, opacity)] : [];
  const base = (
    id: string,
    kind: 'card' | 'video',
    letter: boolean,
    personalization: KeepsakePersonalization,
  ) => ({
    id,
    kind,
    version: 1,
    name: letter
      ? l('Lá thư đầy tháng', 'A Letter at One Month')
      : l('Những điều nhỏ về con', 'Little Things About You'),
    description: group,
    personalization,
    tier: 'premium',
    status: 'published',
    order: letter ? 7 : 6,
    occasions: ['m1'],
    ageDays: { min: 15, max: 60 },
    assets: Object.fromEntries(
      Object.entries(assets)
        .filter(
          ([key]) => key === 'p48-grain' || key.startsWith(letter ? 'p48-letter-' : 'p48-observe-'),
        )
        .map(([key, value]) => [key === 'p48-grain' ? 'paperGrain' : role(key), value]),
    ),
    photos: { min: 1, max: 1 },
    scenes: [],
    texts: [],
    palette: letter
      ? { background: '#F5EEE2', ink: '#4B3A36', accent: '#87494F' }
      : { background: '#FCF7ED', ink: '#4B5142', accent: '#A2AA85' },
    palettes: [],
    durationSec: null,
    thumb: null,
    defaultMusic: null,
    preview: null,
    brand: null,
  });
  const observe = (s: boolean): KeepsakeLayer[] => [
    { type: 'background', color: 'background', asset: null },
    ...art('p48-grain', [0, 0, 1, 1], 0.035),
    text('headline', [0.067, s ? 0.085 : 0.06, 0.83, 0.035], 0.026, 'beVietnamPro', 'ink', 1, 600),
    text('title', [0.067, s ? 0.14 : 0.12, 0.85, s ? 0.09 : 0.12], 0.066, 'lora', 'ink', 2, 600),
    photo([0.065, s ? 0.3 : 0.3, 0.41, s ? 0.32 : 0.43], 'circle'),
    ...art('p48-observe-oval-frame', [0.055, s ? 0.29 : 0.29, 0.43, s ? 0.34 : 0.45]),
    ...['favorite', 'detail', 'memory'].flatMap((key, i) => {
      const y = (s ? 0.295 : 0.285) + i * (s ? 0.17 : 0.175);
      return [
        ...art(
          `p48-observe-${key === 'favorite' ? 'favorite' : key === 'detail' ? 'detail' : 'memory'}-label`,
          [0.515, y, 0.43, s ? 0.14 : 0.162],
        ),
        text(`label${i}`, [0.545, y + 0.018, 0.36, 0.035], 0.026, 'beVietnamPro', 'ink', 1, 600),
        text(
          `detail${i}`,
          [0.545, y + 0.056, 0.36, s ? 0.075 : 0.1],
          0.034,
          'beVietnamPro',
          'ink',
          3,
        ),
      ];
    }),
    ...art('p48-observe-hand', [0.06, s ? 0.67 : 0.76, 0.085, s ? 0.06 : 0.08]),
    ...art('p48-observe-star', [0.39, s ? 0.66 : 0.755, 0.065, s ? 0.037 : 0.052]),
    ...art('p48-observe-pencil-rule', [0.06, 0.868, 0.6, 0.025]),
    text('signature', [0.067, 0.834, 0.8, 0.043], 0.035, 'beVietnamPro', 'ink', 1, 600),
    brand(s),
  ];
  const letter = (s: boolean): KeepsakeLayer[] => [
    { type: 'background', color: 'background', asset: null },
    ...art('p48-grain', [0, 0, 1, 1], 0.035),
    ...art('p48-letter-ruled-paper', [0.045, s ? 0.07 : 0.035, 0.91, 0.88]),
    text(
      'headline',
      [0.09, s ? 0.095 : 0.065, 0.79, 0.035],
      0.026,
      'beVietnamPro',
      'accent',
      1,
      600,
    ),
    photo([0.11, s ? 0.17 : 0.145, 0.34, s ? 0.23 : 0.272]),
    ...art('p48-letter-ribbon', [0.085, s ? 0.152 : 0.13, 0.17, s ? 0.027 : 0.035]),
    ...art('p48-letter-postage-frame', [0.7, s ? 0.18 : 0.16, 0.15, s ? 0.105 : 0.15]),
    text('title', [0.09, s ? 0.46 : 0.455, 0.82, s ? 0.115 : 0.14], 0.06, 'lora', 'ink', 3, 600),
    text(
      'message',
      [0.09, s ? 0.61 : 0.625, 0.8, s ? 0.155 : 0.185],
      0.038,
      'beVietnamPro',
      'ink',
      5,
    ),
    text(
      'signature',
      [0.09, s ? 0.84 : 0.845, 0.72, 0.06],
      0.034,
      'beVietnamPro',
      'accent',
      2,
      600,
    ),
    ...art('p48-letter-wax-seal', [0.8, s ? 0.835 : 0.84, 0.09, s ? 0.05 : 0.067]),
    ...art('p48-letter-closing-rule', [0.09, 0.91, 0.79, 0.026]),
    brand(s),
  ];
  const hints = (vi: string[], en: string[]) =>
    vi.map((v, i) => ({ hint: l(v, en[i]!), optional: false }));
  return [
    {
      ...base('card_premium48_05', 'card', false, noteCard),
      layouts: { portrait: observe(false), story: observe(true) },
      composition: null,
    },
    {
      ...base('card_premium48_06', 'card', true, letterCard),
      layouts: { portrait: letter(false), story: letter(true) },
      composition: null,
    },
    {
      ...base('video_premium48_05', 'video', false, noteVideo),
      photos: { min: 5, max: 5 },
      layouts: null,
      composition: 'PremiumLittleThings',
      durationSec: 35,
      brand: { ...defaultKeepsakeVideoBrand },
      defaultMusic: music.observe ?? null,
      scenes: hints(
        [
          'Chân dung tháng hiện tại',
          'Bé với điều con thích (nếu phù hợp)',
          'Chi tiết biểu cảm hoặc cử chỉ bạn chọn',
          'Khoảnh khắc đời thường muốn nhớ',
          'Ảnh cận gương mặt',
        ],
        [
          'A portrait from this month',
          'Baby with something they love',
          'An expression or gesture',
          'An everyday moment to keep',
          'A close portrait',
        ],
      ),
    },
    {
      ...base('video_premium48_06', 'video', true, letterVideo),
      photos: { min: 5, max: 5 },
      layouts: null,
      composition: 'PremiumMonthLetter',
      durationSec: 35,
      brand: { ...defaultKeepsakeVideoBrand },
      defaultMusic: music.letter ?? null,
      scenes: hints(
        [
          'Chân dung đầy tháng',
          'Một khoảnh khắc chăm bé',
          'Ảnh ôm sát phù hợp lời thư',
          'Ảnh đời thường không dàn dựng',
          'Ảnh cùng người viết thư',
        ],
        [
          'A one-month portrait',
          'A moment of caring for baby',
          'A close embrace matching your words',
          'An everyday, unposed moment',
          'Baby with the letter writer',
        ],
      ),
    },
  ].map((t) => keepsakeTemplateSchema.parse(t));
}
