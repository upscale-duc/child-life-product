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
const name = {
  key: 'babyName',
  label: l('Tên bé', 'Baby’s name'),
  type: 'text',
  source: 'babyName',
  max: 30,
  required: true,
} as const;
const item = {
  key: 'itemName',
  label: l('Tên món đồ (tùy chọn)', 'Keepsake name (optional)'),
  type: 'text',
  max: 40,
  required: false,
} as const;
const outgrown = {
  key: 'outgrownConfirmed',
  label: l('Tôi xác nhận món đồ đã không còn vừa bé', 'I confirm this item no longer fits'),
  type: 'confirmation',
  max: 5,
  required: false,
} as const;
const stored = {
  key: 'storedDate',
  label: l('Ngày cất lại (nếu biết)', 'Date put away (if known)'),
  type: 'date',
  max: 10,
  required: false,
} as const;
const moment = {
  key: 'momentDate',
  label: l('Ngày ghi nhận (nếu biết)', 'Date captured (if known)'),
  type: 'date',
  source: 'momentDate',
  max: 10,
  required: false,
} as const;
const reaction = {
  key: 'reactionConfirmed',
  label: l(
    'Ảnh thứ ba có người thân nhìn bé cười',
    'Photo three shows a loved one reacting to the smile',
  ),
  type: 'confirmation',
  max: 5,
  required: false,
} as const;
const c = (
  key: string,
  label: ReturnType<typeof l>,
  vi: string,
  en: string,
  editable = false,
  requires: string[] = [],
  fallback = l('', ''),
) => ({ key, label, text: l(vi, en), editable, requires, fallback, max: 160 });
const sc = (i: number, vi: string, en: string, requires: string[] = [], fallback = l('', '')) =>
  c(`scene${i}`, l(`Cảnh ${i}`, `Scene ${i}`), vi, en, true, requires, fallback);
const wardrobeGroup = l('Lớn từng ngày', 'Growing Every Day'),
  smileGroup = l('Lần đầu', 'Little Firsts');
const itemCopy = [
  c(
    'label0',
    l('Nhãn món đồ', 'Keepsake label'),
    '{itemName}',
    '{itemName}',
    false,
    ['itemName'],
    l('Món đồ bé xíu', 'A tiny keepsake'),
  ),
  c(
    'label1',
    l('Ngày cất', 'Date put away'),
    'Cất lại · {storedDate}',
    'Put away · {storedDate}',
    false,
    ['storedDate'],
  ),
  c('signature', l('Tên bé', 'Baby’s name'), '{babyName}', '{babyName}'),
];
const wardrobeCard = keepsakePersonalizationSchema.parse({
  group: wardrobeGroup,
  fields: [name, item, outgrown, stored],
  beats: [],
  copy: [
    c(
      'headline',
      l('Nhãn', 'Label'),
      'NHỮNG MÓN ĐỒ ĐÃ CHẬT',
      'THE THINGS YOU OUTGREW',
      false,
      ['outgrownConfirmed'],
      l('MÓN ĐỒ MUỐN GIỮ', 'A KEEPSAKE TO KEEP'),
    ),
    c(
      'title',
      l('Tiêu đề', 'Title'),
      'Chiếc {itemName} bé xíu ấy.',
      'That tiny {itemName}.',
      true,
      ['itemName'],
      l('Một món đồ bé xíu.', 'A tiny keepsake.'),
    ),
    c(
      'message',
      l('Lời nhắn', 'Message'),
      'Đã từng vừa con đến thế.',
      'Once, it fit you just right.',
      true,
      ['outgrownConfirmed'],
      l('Một món đồ, bao điều muốn nhớ.', 'One little thing, so much to remember.'),
    ),
    c(
      'detail0',
      l('Câu kết', 'Closing line'),
      'Cất món đồ lại, giữ những ngày này bên mình.',
      'Putting it away. Keeping the memories.',
      true,
      ['storedDate'],
      l('Giữ món đồ nhỏ, giữ những ngày bên con.', 'A little keepsake. Days to remember.'),
    ),
    ...itemCopy,
  ],
});
const smileCard = keepsakePersonalizationSchema.parse({
  group: smileGroup,
  fields: [name, moment],
  beats: [],
  copy: [
    c('headline', l('Nhãn', 'Label'), 'NỤ CƯỜI MUỐN GIỮ', 'A SMILE TO KEEP'),
    c(
      'title',
      l('Tiêu đề', 'Title'),
      'Một nụ cười, cả nhà nhớ mãi.',
      'A smile we will remember.',
      true,
    ),
    c(
      'message',
      l('Lời nhắn', 'Message'),
      'Điều bé xíu làm sáng cả ngày.',
      'Something tiny that lit up the day.',
      true,
    ),
    c('label1', l('Ngày ghi nhận', 'Date captured'), '{momentDate}', '{momentDate}', false, [
      'momentDate',
    ]),
    c('signature', l('Tên bé', 'Baby’s name'), '{babyName}', '{babyName}'),
  ],
});
const wardrobeVideo = keepsakePersonalizationSchema.parse({
  group: wardrobeGroup,
  fields: [name, item, outgrown, stored],
  beats: [[0], [1], [2], [3, 0], [4]].map((slots, i) => ({ slots, textKey: `scene${i + 1}` })),
  copy: [
    c(
      'title',
      l('Tên video', 'Video title'),
      'Những món đồ đã chật',
      'The Things You Outgrew',
      false,
      ['outgrownConfirmed'],
      l('Món đồ muốn giữ', 'A Keepsake to Keep'),
    ),
    sc(1, 'Có một món đồ bé xíu…', 'There was something so tiny…'),
    sc(
      2,
      'Đã cùng con đi qua những ngày đầu.',
      'That stayed with you through the early days.',
      ['outgrownConfirmed'],
      l('Một khoảnh khắc bên con.', 'A moment with you.'),
    ),
    sc(
      3,
      'Rồi một hôm, không còn vừa nữa.',
      'Then one day, it no longer fit.',
      ['outgrownConfirmed'],
      l('Có những chi tiết mình muốn nhớ mãi.', 'Some little details are worth keeping.'),
    ),
    sc(
      4,
      'Con lớn lên. Món đồ ở lại.',
      'You grew. It stayed small.',
      ['outgrownConfirmed'],
      l('Con và món đồ nhỏ thân quen.', 'You, and a familiar little keepsake.'),
    ),
    sc(5, 'Và câu chuyện của nó vẫn ở đây.', 'Its story stays with us.'),
    ...itemCopy,
  ],
});
const smileVideo = keepsakePersonalizationSchema.parse({
  group: smileGroup,
  fields: [name, moment, reaction],
  beats: [[0], [1], [2, 1], [1], [1]].map((slots, i) => ({ slots, textKey: `scene${i + 1}` })),
  copy: [
    c('title', l('Tên video', 'Video title'), 'Nụ cười muốn giữ', 'A Smile to Keep'),
    sc(1, 'Đang là một ngày rất bình thường…', 'It was an ordinary sort of day…'),
    sc(2, 'Rồi con cười.', 'Then you smiled.'),
    sc(
      3,
      'Mọi ánh nhìn đều quay về phía con.',
      'And all eyes turned to you.',
      ['reactionConfirmed'],
      l('Chỉ muốn ngắm con thêm một chút.', 'We could watch you smile a little longer.'),
    ),
    sc(4, 'Muốn giữ lại thêm một chút nữa.', 'A moment worth holding a little longer.'),
    sc(
      5,
      'Nụ cười này, ngày {momentDate}.',
      'This smile, on {momentDate}.',
      ['momentDate'],
      l('Một nụ cười muốn giữ mãi.', 'A smile to keep, always.'),
    ),
    c('signature', l('Tên bé', 'Baby’s name'), '{babyName}', '{babyName}'),
    c('label1', l('Ngày ghi nhận', 'Date captured'), '{momentDate}', '{momentDate}', false, [
      'momentDate',
    ]),
  ],
});
const rect = (r: number[]) => ({ x: r[0]!, y: r[1]!, w: r[2]!, h: r[3]! });
const text = (
  field: string,
  r: number[],
  size: number,
  font = 'beVietnamPro',
  maxLines = 2,
  weight = 400,
): KeepsakeLayer =>
  ({
    type: 'text',
    field,
    rect: rect(r),
    size,
    font,
    color: 'ink',
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
  radius: 0.004,
  rotate: 0,
});
const role = (key: string) =>
  key.replace(/^p48-/, '').replace(/-([a-z])/g, (_, v: string) => v.toUpperCase());
/** Phase 5: confirmation-gated memories and an explicit three-photo smile reprise. */
export function premium48Phase5(
  assets: Record<string, string> = {},
  music: { wardrobe?: string; smile?: string } = {},
): KeepsakeTemplate[] {
  const art = (key: string, r: number[], opacity = 1): KeepsakeLayer[] =>
    assets[key]
      ? [{ type: 'image', asset: assets[key]!, rect: rect(r), fit: 'fill', rotate: 0, opacity }]
      : [];
  const brand = (s: boolean): Extract<KeepsakeLayer, { type: 'brand' }> => ({
    type: 'brand',
    kind: 'lockup',
    rect: rect([0.065, 0.947, 0.22, s ? 0.018 : 0.025]),
    color: 'ink',
    opacity: 0.6,
  });
  const wardrobe = (s: boolean): KeepsakeLayer[] => [
    { type: 'background', color: 'background', asset: null },
    ...art('p48-grain', [0, 0, 1, 1], 0.035),
    ...art('p48-wardrobe-hanger', [0.78, s ? 0.065 : 0.035, 0.15, s ? 0.065 : 0.09]),
    text('headline', [0.065, s ? 0.09 : 0.052, 0.69, 0.04], 0.025, 'beVietnamPro', 1, 600),
    text('title', [0.065, s ? 0.15 : 0.115, 0.87, s ? 0.09 : 0.12], 0.063, 'lora', 2, 600),
    photo(0, [0.065, s ? 0.3 : 0.29, 0.55, s ? 0.34 : 0.39]),
    ...art('p48-wardrobe-stitch-frame', [0.053, s ? 0.291 : 0.28, 0.574, s ? 0.358 : 0.41]),
    photo(1, [0.66, s ? 0.3 : 0.29, 0.275, s ? 0.16 : 0.185]),
    photo(2, [0.66, s ? 0.48 : 0.495, 0.275, s ? 0.16 : 0.185]),
    ...art('p48-wardrobe-thread-route', [0.63, s ? 0.3 : 0.29, 0.018, s ? 0.34 : 0.39]),
    ...art('p48-wardrobe-fabric-label', [0.065, s ? 0.66 : 0.7, 0.87, s ? 0.065 : 0.065]),
    text('label0', [0.09, s ? 0.678 : 0.718, 0.81, 0.035], 0.029, 'beVietnamPro', 1, 600),
    text('message', [0.065, s ? 0.755 : 0.795, 0.87, 0.065], 0.038, 'lora', 2, 600),
    text('detail0', [0.065, s ? 0.835 : 0.865, 0.87, 0.055], 0.03, 'beVietnamPro', 2),
    text('label1', [0.45, 0.907, 0.485, 0.04], 0.023, 'beVietnamPro', 1),
    text('signature', [0.065, 0.907, 0.35, 0.04], 0.025, 'beVietnamPro', 1, 600),
    brand(s),
  ];
  const smile = (s: boolean): KeepsakeLayer[] => [
    { type: 'background', color: 'background', asset: null },
    ...art('p48-grain', [0, 0, 1, 1], 0.025),
    text('headline', [0.065, s ? 0.08 : 0.045, 0.87, 0.04], 0.025, 'beVietnamPro', 1, 600),
    text('title', [0.065, s ? 0.14 : 0.105, 0.87, s ? 0.095 : 0.13], 0.066, 'lora', 2, 600),
    ...art('p48-smile-sun-arc', [0.04, s ? 0.275 : 0.27, 0.92, s ? 0.16 : 0.22]),
    photo(0, [0.105, s ? 0.345 : 0.35, 0.79, s ? 0.325 : 0.35]),
    ...art('p48-smile-sun-frame', [0.092, s ? 0.336 : 0.34, 0.816, s ? 0.343 : 0.37]),
    ...art('p48-smile-smile-curve', [0.3, s ? 0.697 : 0.724, 0.4, s ? 0.035 : 0.045]),
    text('message', [0.105, s ? 0.77 : 0.805, 0.79, 0.07], 0.037, 'lora', 2, 400),
    text('label1', [0.105, s ? 0.874 : 0.898, 0.79, 0.03], 0.025, 'beVietnamPro', 1),
    text('signature', [0.105, s ? 0.914 : 0.923, 0.79, 0.04], 0.025, 'beVietnamPro', 1, 600),
    { ...brand(s), rect: rect([0.105, 0.967, 0.22, s ? 0.016 : 0.021]) },
  ];
  const base = (
    id: string,
    kind: 'card' | 'video',
    sun: boolean,
    personalization: KeepsakePersonalization,
  ) => ({
    id,
    kind,
    version: 1,
    name: sun
      ? l('Nụ cười muốn giữ', 'A Smile to Keep')
      : l('Những món đồ đã chật', 'The Things You Outgrew'),
    description: sun ? smileGroup : wardrobeGroup,
    personalization,
    tier: 'premium',
    status: 'published',
    order: sun ? 11 : 10,
    occasions: [],
    ageDays: null,
    assets: Object.fromEntries(
      Object.entries(assets)
        .filter(([k]) => k === 'p48-grain' || k.startsWith(sun ? 'p48-smile-' : 'p48-wardrobe-'))
        .map(([k, v]) => [k === 'p48-grain' ? 'paperGrain' : role(k), v]),
    ),
    photos: { min: 1, max: 1 },
    scenes: [],
    texts: [],
    palette: sun
      ? { background: '#FFF2CD', ink: '#684D60', accent: '#D5826D' }
      : { background: '#F7F1E6', ink: '#3F5059', accent: '#BA9652' },
    palettes: [],
    durationSec: null,
    thumb: null,
    defaultMusic: null,
    preview: null,
    brand: null,
  });
  const hints = (vi: string[], en: string[]) =>
    vi.map((v, i) => ({ hint: l(v, en[i]!), optional: false }));
  return [
    {
      ...base('card_premium48_09', 'card', false, wardrobeCard),
      photos: { min: 3, max: 3 },
      layouts: { portrait: wardrobe(false), story: wardrobe(true) },
      composition: null,
    },
    {
      ...base('card_premium48_10', 'card', true, smileCard),
      layouts: { portrait: smile(false), story: smile(true) },
      composition: null,
    },
    {
      ...base('video_premium48_09', 'video', false, wardrobeVideo),
      photos: { min: 5, max: 5 },
      layouts: null,
      composition: 'PremiumOutgrownKeepsake',
      durationSec: 35,
      brand: { ...defaultKeepsakeVideoBrand },
      defaultMusic: music.wardrobe ?? null,
      scenes: hints(
        [
          'Ảnh món đồ muốn giữ',
          'Bé bên món đồ',
          'Chi tiết tay/chân hoặc món đồ',
          'Chân dung bé; cạnh ảnh món đồ đã chọn',
          'Món đồ gấp/cất hoặc ảnh thay thế',
        ],
        [
          'The little keepsake',
          'Baby with the keepsake',
          'A tiny detail of baby or the item',
          'Baby portrait beside the keepsake',
          'Folded keepsake or another photo',
        ],
      ),
    },
    {
      ...base('video_premium48_10', 'video', true, smileVideo),
      photos: { min: 3, max: 3 },
      layouts: null,
      composition: 'PremiumSmileToKeep',
      durationSec: 35,
      brand: { ...defaultKeepsakeVideoBrand },
      defaultMusic: music.smile ?? null,
      scenes: hints(
        [
          'Khoảnh khắc trước nụ cười',
          'Ảnh cười; trở lại ở cảnh 4 và 5',
          'Phản ứng người thân hoặc ảnh cận an toàn',
        ],
        [
          'An ordinary moment before the smile',
          'The smile; returns in scenes 4 and 5',
          'Loved one’s reaction or a safe detail',
        ],
      ),
    },
  ].map((t) => keepsakeTemplateSchema.parse(t));
}
