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
  group = l('Lần đầu', 'Little Firsts');
const name = {
  key: 'babyName',
  label: l('Tên bé', 'Baby’s name'),
  type: 'text',
  source: 'babyName',
  max: 30,
  required: true,
} as const;
// A parent enters the milestone explicitly; never prefilled from age, diagnosis or upload metadata.
const milestone = {
  key: 'milestoneName',
  suggestion: l('những bước nhỏ', 'little steps'),
  label: l('Mốc bé đã làm được (bạn xác nhận)', 'Milestone your child reached (you confirm)'),
  type: 'text',
  max: 48,
  required: true,
} as const;
const moment = {
  key: 'momentDate',
  label: l('Ngày ghi nhận (nếu biết)', 'Date captured (if known)'),
  type: 'date',
  max: 10,
  required: false,
} as const;
const recorded = {
  key: 'momentPhotoConfirmed',
  label: l('Ảnh ghi lại đúng khoảnh khắc đạt mốc', 'The photos show the actual milestone moment'),
  type: 'confirmation',
  max: 5,
  required: false,
} as const;
const discovery = {
  key: 'discovery',
  label: l('Điều bé khám phá (tùy chọn)', 'What caught their attention (optional)'),
  type: 'text',
  max: 48,
  required: false,
} as const;
const object = {
  key: 'objectPhotoConfirmed',
  label: l('Ảnh thứ hai có vật bé khám phá', 'Photo two shows the object being explored'),
  type: 'confirmation',
  max: 5,
  required: false,
} as const;
const companion = {
  key: 'companionConfirmed',
  label: l(
    'Ảnh thứ tư có người cùng bé khám phá',
    'Photo four shows a companion exploring with baby',
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
const signature = c('signature', l('Tên bé', 'Baby’s name'), '{babyName}', '{babyName}');
const date = c(
  'label1',
  l('Ngày ghi nhận', 'Date captured'),
  '{momentDate}',
  '{momentDate}',
  false,
  ['momentDate'],
);
const milestoneLabel = c('label0', l('Tên mốc', 'Milestone'), '{milestoneName}', '{milestoneName}');
const milestoneCard = keepsakePersonalizationSchema.parse({
  group,
  fields: [name, milestone, moment, recorded],
  beats: [],
  copy: [
    c(
      'headline',
      l('Nhãn', 'Label'),
      'CON LÀM ĐƯỢC RỒI',
      'YOU DID IT',
      false,
      ['momentPhotoConfirmed'],
      l('MỘT MỐC MUỐN NHỚ', 'A MOMENT TO REMEMBER'),
    ),
    c(
      'title',
      l('Tiêu đề', 'Title'),
      'Con làm được rồi: {milestoneName}.',
      'You did it: {milestoneName}.',
      true,
      ['momentPhotoConfirmed'],
      l('Nhớ ngày con làm được.', 'Remembering when you did it.'),
    ),
    c(
      'message',
      l('Lời nhắn', 'Message'),
      'Theo cách của con, vào ngày của con.',
      'In your own way. In your own time.',
      true,
    ),
    c(
      'detail0',
      l('Câu kết', 'Closing line'),
      '{momentDate} · Nhà mình giữ lại ngày này.',
      '{momentDate} · A day we are keeping close.',
      true,
      ['momentDate'],
      l('Nhà mình giữ lại khoảnh khắc này.', 'A moment we are keeping close.'),
    ),
    milestoneLabel,
    signature,
  ],
});
const discoveryCard = keepsakePersonalizationSchema.parse({
  group,
  fields: [name, discovery, object],
  beats: [],
  copy: [
    c('headline', l('Nhãn', 'Label'), 'MỘT THẾ GIỚI ĐỂ KHÁM PHÁ', 'A WORLD TO DISCOVER'),
    c(
      'title',
      l('Tiêu đề', 'Title'),
      'Hôm nay, con khám phá {discovery}.',
      'Today, you discovered {discovery}.',
      true,
      ['discovery'],
      l('Hôm nay, thêm một điều mới.', 'Today, something new.'),
    ),
    c(
      'message',
      l('Lời nhắn', 'Message'),
      'Nhìn thật lâu. Chạm thật khẽ.',
      'A long look. A gentle touch.',
      true,
      ['objectPhotoConfirmed'],
      l('Nhìn thật lâu. Một góc nhìn mới.', 'A long look. A new point of view.'),
    ),
    c(
      'detail0',
      l('Câu kết', 'Closing line'),
      'Thế giới mở ra từ những điều gần nhất.',
      'A whole world, beginning close to home.',
      true,
    ),
    c(
      'label0',
      l('Nhãn khám phá', 'Discovery label'),
      '{discovery}',
      '{discovery}',
      false,
      ['discovery'],
      l('Một điều mới', 'Something new'),
    ),
    signature,
  ],
});
const milestoneVideo = keepsakePersonalizationSchema.parse({
  group,
  fields: [name, milestone, moment, recorded],
  beats: [[0], [1], [2], [3], [4]].map((slots, i) => ({ slots, textKey: `scene${i + 1}` })),
  copy: [
    c(
      'title',
      l('Tên video', 'Video title'),
      'Con làm được rồi',
      'You Did It',
      false,
      ['momentPhotoConfirmed'],
      l('Nhớ ngày con làm được', 'Remembering When You Did It'),
    ),
    sc(
      1,
      'Một lần thử…',
      'One little try…',
      ['momentPhotoConfirmed'],
      l('Một kỷ niệm nhỏ…', 'One little memory…'),
    ),
    sc(
      2,
      'Rồi thêm một lần nữa.',
      'Then another.',
      ['momentPhotoConfirmed'],
      l('Thêm một góc nhìn để nhớ.', 'Another little look back.'),
    ),
    sc(
      3,
      'Và hôm nay: {milestoneName}.',
      'And then: {milestoneName}.',
      ['momentPhotoConfirmed'],
      l('Nhớ ngày con làm được.', 'Remembering when you did it.'),
    ),
    sc(4, 'Một khoảnh khắc nhỏ, thật nhiều vui.', 'A small moment. So much joy.'),
    sc(5, 'Nhớ ngày con làm được.', 'Remembering the day you did it.'),
    milestoneLabel,
    date,
    signature,
  ],
});
const discoveryVideo = keepsakePersonalizationSchema.parse({
  group,
  fields: [name, discovery, moment, object, companion],
  beats: [[0], [1], [2], [3], [4]].map((slots, i) => ({ slots, textKey: `scene${i + 1}` })),
  copy: [
    c('title', l('Tên video', 'Video title'), 'Một thế giới để khám phá', 'A World to Discover'),
    sc(1, 'Có điều gì khiến con nhìn mãi?', 'What caught your eye today?'),
    sc(
      2,
      'Một màu sắc. Một âm thanh.',
      'A colour. A sound.',
      ['objectPhotoConfirmed'],
      l('Có thêm một góc nhìn mới.', 'Another way to see the world.'),
    ),
    sc(
      3,
      'Hôm nay là {discovery}.',
      'Today, it was {discovery}.',
      ['discovery'],
      l('Hôm nay là một điều mới.', 'Today, it was something new.'),
    ),
    sc(
      4,
      'Mình cùng con dừng lại một chút.',
      'We paused to explore it with you.',
      ['companionConfirmed'],
      l('Dừng lại, ngắm nhìn thêm một chút.', 'A little pause. A closer look.'),
    ),
    sc(5, 'Thế giới mới, qua đôi mắt con.', 'A new world, through your eyes.'),
    c(
      'label0',
      l('Nhãn khám phá', 'Discovery label'),
      '{discovery}',
      '{discovery}',
      false,
      ['discovery'],
      l('Một điều mới', 'Something new'),
    ),
    date,
    signature,
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
const photo = (slot: number, r: number[], circle = false): KeepsakeLayer => ({
  type: 'photo',
  slot,
  rect: rect(r),
  shape: circle ? 'circle' : 'rect',
  radius: 0.008,
  rotate: 0,
});
const role = (key: string) =>
  key.replace(/^p48-/, '').replace(/-([a-z])/g, (_, v: string) => v.toUpperCase());
export function premium48Phase6(
  assets: Record<string, string> = {},
  music: { milestone?: string; discover?: string } = {},
): KeepsakeTemplate[] {
  const art = (key: string, r: number[], opacity = 1): KeepsakeLayer[] =>
    assets[key]
      ? [{ type: 'image', asset: assets[key]!, rect: rect(r), fit: 'fill', rotate: 0, opacity }]
      : [];
  const brand = (s: boolean): KeepsakeLayer => ({
    type: 'brand',
    kind: 'lockup',
    rect: rect([0.065, 0.947, 0.22, s ? 0.018 : 0.025]),
    color: 'ink',
    opacity: 0.6,
  });
  const steps = (s: boolean): KeepsakeLayer[] => [
    { type: 'background', color: 'background', asset: null },
    ...art('p48-grain', [0, 0, 1, 1], 0.03),
    text('headline', [0.065, s ? 0.085 : 0.05, 0.77, 0.04], 0.025, 'beVietnamPro', 1, 600),
    text('title', [0.065, s ? 0.15 : 0.12, 0.87, s ? 0.11 : 0.14], 0.06, 'lora', 3, 600),
    ...art('p48-milestone-paper-star', [0.84, s ? 0.078 : 0.042, 0.095, s ? 0.055 : 0.075]),
    photo(0, [0.065, s ? 0.32 : 0.32, 0.25, s ? 0.19 : 0.245]),
    photo(1, [0.375, s ? 0.365 : 0.365, 0.25, s ? 0.19 : 0.245]),
    photo(2, [0.685, s ? 0.41 : 0.41, 0.25, s ? 0.19 : 0.245]),
    ...art('p48-milestone-photo-corners', [0.055, s ? 0.313 : 0.31, 0.27, s ? 0.204 : 0.265]),
    ...art('p48-milestone-photo-corners', [0.365, s ? 0.358 : 0.355, 0.27, s ? 0.204 : 0.265]),
    ...art('p48-milestone-photo-corners', [0.675, s ? 0.403 : 0.4, 0.27, s ? 0.204 : 0.265]),
    ...art('p48-milestone-dot-route', [0.065, s ? 0.635 : 0.685, 0.87, s ? 0.055 : 0.055]),
    ...art('p48-milestone-label', [0.065, s ? 0.715 : 0.75, 0.87, 0.065]),
    text('label0', [0.09, s ? 0.732 : 0.767, 0.81, 0.035], 0.028, 'beVietnamPro', 1, 600),
    text('message', [0.065, s ? 0.815 : 0.835, 0.87, 0.065], 0.032, 'beVietnamPro', 2),
    text('detail0', [0.065, s ? 0.88 : 0.898, 0.87, 0.035], 0.024, 'beVietnamPro', 1),
    text('signature', [0.65, 0.937, 0.285, 0.035], 0.025, 'beVietnamPro', 1, 600),
    brand(s),
  ];
  const world = (s: boolean): KeepsakeLayer[] => [
    { type: 'background', color: 'background', asset: null },
    ...art('p48-grain', [0, 0, 1, 1], 0.03),
    ...art('p48-discover-leaf-pair', [0.81, s ? 0.074 : 0.04, 0.12, s ? 0.075 : 0.105]),
    text('headline', [0.065, s ? 0.08 : 0.05, 0.73, 0.04], 0.025, 'beVietnamPro', 1, 600),
    text('title', [0.065, s ? 0.145 : 0.12, 0.87, s ? 0.105 : 0.14], 0.06, 'lora', 3, 600),
    photo(0, [0.065, s ? 0.31 : 0.32, 0.51, s ? 0.287 : 0.408], true),
    ...art('p48-discover-round-window', [0.055, s ? 0.304 : 0.312, 0.53, s ? 0.299 : 0.424]),
    photo(1, [0.655, s ? 0.43 : 0.46, 0.28, s ? 0.158 : 0.224], true),
    ...art('p48-discover-viewfinder', [0.645, s ? 0.424 : 0.452, 0.3, s ? 0.17 : 0.24]),
    ...art('p48-discover-three-dots', [0.59, s ? 0.45 : 0.48, 0.05, s ? 0.08 : 0.09]),
    ...art('p48-discover-leaf-sprig', [0.055, s ? 0.605 : 0.745, 0.12, s ? 0.065 : 0.075], 0.6),
    text('label0', [0.23, s ? 0.66 : 0.74, 0.705, 0.04], 0.028, 'beVietnamPro', 1, 600),
    text('message', [0.065, s ? 0.765 : 0.81, 0.87, 0.065], 0.034, 'beVietnamPro', 2),
    text('detail0', [0.065, s ? 0.855 : 0.892, 0.87, 0.045], 0.026, 'beVietnamPro', 2),
    text('signature', [0.65, 0.937, 0.285, 0.035], 0.025, 'beVietnamPro', 1, 600),
    brand(s),
  ];
  const base = (
    id: string,
    kind: 'card' | 'video',
    world: boolean,
    personalization: KeepsakePersonalization,
  ) => ({
    id,
    kind,
    version: 1,
    name: world
      ? l('Một thế giới để khám phá', 'A World to Discover')
      : l('Con làm được rồi', 'You Did It'),
    description: group,
    personalization,
    tier: 'premium',
    status: 'published',
    order: world ? 13 : 12,
    occasions: [],
    ageDays: null,
    assets: Object.fromEntries(
      Object.entries(assets)
        .filter(
          ([k]) => k === 'p48-grain' || k.startsWith(world ? 'p48-discover-' : 'p48-milestone-'),
        )
        .map(([k, v]) => [k === 'p48-grain' ? 'paperGrain' : role(k), v]),
    ),
    photos: { min: 1, max: 1 },
    scenes: [],
    texts: [],
    palette: world
      ? { background: '#F1F0E5', ink: '#46523C', accent: '#A17654' }
      : { background: '#FAF5E9', ink: '#37534F', accent: '#D6A35C' },
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
      ...base('card_premium48_11', 'card', false, milestoneCard),
      photos: { min: 3, max: 3 },
      layouts: { portrait: steps(false), story: steps(true) },
      composition: null,
    },
    {
      ...base('card_premium48_12', 'card', true, discoveryCard),
      photos: { min: 2, max: 2 },
      layouts: { portrait: world(false), story: world(true) },
      composition: null,
    },
    {
      ...base('video_premium48_11', 'video', false, milestoneVideo),
      photos: { min: 5, max: 5 },
      layouts: null,
      composition: 'PremiumYouDidIt',
      durationSec: 35,
      brand: { ...defaultKeepsakeVideoBrand },
      defaultMusic: music.milestone ?? null,
      scenes: hints(
        [
          'Ảnh chuẩn bị hoặc kỷ niệm',
          'Lần thử khác hoặc ảnh nhìn lại',
          'Ảnh mốc chính hoặc ảnh kỷ niệm',
          'Niềm vui hoặc ảnh sau đó',
          'Ảnh kết, ngày nếu biết',
        ],
        [
          'Getting ready or a memory',
          'Another try or a memory',
          'Milestone moment or a memory',
          'Joyful moment or an after-photo',
          'Closing portrait; date optional',
        ],
      ),
    },
    {
      ...base('video_premium48_12', 'video', true, discoveryVideo),
      photos: { min: 5, max: 5 },
      layouts: null,
      composition: 'PremiumWorldToDiscover',
      durationSec: 35,
      brand: { ...defaultKeepsakeVideoBrand },
      defaultMusic: music.discover ?? null,
      scenes: hints(
        [
          'Bé đang nhìn',
          'Vật khám phá hoặc góc nhìn khác của bé',
          'Tương tác hoặc ảnh bé chú ý',
          'Bé cùng người thân hoặc chân dung',
          'Góc nhìn rộng hoặc chân dung cuối',
        ],
        [
          'A curious look',
          'Object or another view of baby',
          'Interaction or an attentive portrait',
          'With a companion or a portrait',
          'A wider view or closing portrait',
        ],
      ),
    },
  ].map((t) => keepsakeTemplateSchema.parse(t));
}
