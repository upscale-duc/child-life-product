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
const homeGroup = l('Chào con', 'Hello, Little One');
const monthGroup = l('Tháng đầu', 'Our First Month');
const name = {
  key: 'babyName',
  label: l('Tên bé', 'Baby’s name'),
  type: 'text',
  source: 'babyName',
  max: 30,
  required: true,
} as const;
const moment = {
  key: 'momentDate',
  label: l('Ngày về nhà (tùy chọn)', 'Homecoming date (optional)'),
  type: 'date',
  source: 'momentDate',
  max: 10,
  required: false,
} as const;
const journey = {
  key: 'journeyConfirmed',
  label: l('Mình có ảnh của chuyến về nhà', 'My selection includes the journey home'),
  type: 'confirmation',
  max: 5,
  required: false,
} as const;
const birthPhoto = {
  key: 'birthPhotoConfirmed',
  label: l('Ảnh đầu tiên được chụp vào ngày sinh', 'The first photo was taken on the day of birth'),
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
const homeCard = keepsakePersonalizationSchema.parse({
  group: homeGroup,
  fields: [name, moment, journey],
  beats: [],
  copy: [
    c('headline', l('Nhãn', 'Label'), 'ĐƯA CON VỀ NHÀ', 'WELCOME HOME'),
    c('title', l('Tiêu đề', 'Title'), 'Nhà mình có con rồi.', 'Home, with you.', true),
    c(
      'message',
      l('Lời nhắn', 'Message'),
      'Từ hôm nay, góc nhỏ này có thêm một người để thương.',
      'A little place, with someone new to love.',
      true,
    ),
    c(
      'detail0',
      l('Ngày về nhà', 'Homecoming date'),
      'Ngày về nhà: {momentDate}',
      'Homecoming: {momentDate}',
      false,
      ['momentDate'],
    ),
    c(
      'photoLabel0',
      l('Ảnh thứ nhất', 'First photo'),
      'Chuyến về nhà',
      'The journey home',
      false,
      ['journeyConfirmed'],
      l('Một ngày đáng nhớ', 'A day to remember'),
    ),
    c('photoLabel1', l('Ảnh thứ hai', 'Second photo'), 'Góc nhỏ có con', 'A little place for you'),
    c('signature', l('Tên bé', 'Baby’s name'), '{babyName}', '{babyName}'),
  ],
});
const monthCard = keepsakePersonalizationSchema.parse({
  group: monthGroup,
  fields: [name],
  beats: [],
  copy: [
    c('headline', l('Nhãn', 'Label'), 'MỘT THÁNG BÊN NHAU', 'OUR FIRST MONTH'),
    c(
      'title',
      l('Tiêu đề', 'Title'),
      'Một tháng làm quen với con.',
      'One month of getting to know you.',
      true,
    ),
    c(
      'message',
      l('Lời nhắn', 'Message'),
      'Thêm hiểu con một chút, mỗi ngày.',
      'Learning a little more about you, every day.',
      true,
    ),
    c(
      'signature',
      l('Dòng kết', 'Closing line'),
      '{babyName} · Một tháng bên nhau',
      '{babyName} · Our first month together',
      true,
    ),
  ],
});
const scene = (i: number, vi: string, en: string, requires: string[] = [], fallback = l('', '')) =>
  c(`scene${i}`, l(`Cảnh ${i}`, `Scene ${i}`), vi, en, true, requires, fallback);
const homeVideo = keepsakePersonalizationSchema.parse({
  group: homeGroup,
  fields: [name, moment, journey],
  beats: [0, 1, 2, 3, 4].map((i) => ({ slots: [i], textKey: `scene${i + 1}` })),
  copy: [
    c('title', l('Tên video', 'Video title'), 'Đưa con về nhà', 'Welcome Home'),
    scene(
      1,
      'Hôm nay, mình về nhà.',
      'Today, we went home.',
      ['journeyConfirmed'],
      l('Một góc nhà, một khởi đầu.', 'A little place. A new beginning.'),
    ),
    scene(
      2,
      'Một chuyến đi thật khác.',
      'A journey unlike any other.',
      ['journeyConfirmed'],
      l('Một ngày đáng nhớ.', 'A day to remember.'),
    ),
    scene(3, 'Căn phòng vẫn thế…', 'The room looked the same…'),
    scene(4, 'Nhưng nhà mình đã có thêm con.', 'But home had someone new.'),
    scene(5, 'Chào mừng về nhà, {babyName}.', 'Welcome home, {babyName}.'),
    c('detail0', l('Ngày về nhà', 'Homecoming date'), '{momentDate}', '{momentDate}', false, [
      'momentDate',
    ]),
  ],
});
const monthVideo = keepsakePersonalizationSchema.parse({
  group: monthGroup,
  fields: [name, birthPhoto],
  beats: [[0], [1, 0], [2, 1], [3, 2, 1], [4]].map((slots, i) => ({
    slots,
    textKey: `scene${i + 1}`,
  })),
  copy: [
    c(
      'title',
      l('Tên video', 'Video title'),
      'Một tháng làm quen',
      'A Month of Getting to Know You',
    ),
    scene(
      1,
      'Một tháng trước, nhà mình đón con.',
      'A month ago, we welcomed you.',
      ['birthPhotoConfirmed'],
      l('Những ngày đầu bên con.', 'Our first days with you.'),
    ),
    scene(2, 'Những ngày đầu còn nhiều bỡ ngỡ.', 'Those first days held so much to learn.'),
    scene(3, 'Rồi từng chút một…', 'Then, little by little…'),
    scene(4, 'Nhà mình tìm được nhịp riêng.', 'We began finding our own rhythm.'),
    scene(5, 'Tròn một tháng bên {babyName}.', 'One month with {babyName}.'),
  ],
});
const palettes = {
  home: { background: '#FFFDF7', ink: '#414B34', accent: '#79815C' },
  month: { background: '#FFF4E7', ink: '#5B4034', accent: '#D99A74' },
};
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
const photo = (slot: number, r: number[], rotate = 0): KeepsakeLayer => ({
  type: 'photo',
  slot,
  rect: rect(r),
  shape: 'rect',
  radius: 0.008,
  rotate,
});
const shape = (r: number[], color: string, rotate = 0): KeepsakeLayer => ({
  type: 'shape',
  shape: 'rect',
  rect: rect(r),
  color,
  radius: 0.008,
  stroke: 0,
  gradientTo: null,
  rotate,
});
const image = (asset: string, r: number[], rotate = 0, opacity = 1): KeepsakeLayer => ({
  type: 'image',
  asset,
  rect: rect(r),
  fit: 'fill',
  rotate,
  opacity,
});
const brand = (story: boolean): KeepsakeLayer => ({
  type: 'brand',
  kind: 'lockup',
  rect: rect([0.067, 0.947, 0.22, story ? 0.018 : 0.025]),
  color: 'ink',
  opacity: 0.6,
});
const roleOf = (name: string) =>
  name.replace(/^p48-/, '').replace(/-([a-z])/g, (_, v: string) => v.toUpperCase());

/** Phase 2 is exactly two cards and two videos; original assets are supplied by immutable name. */
export function premium48Phase2(
  assets: Record<string, string> = {},
  music: { home?: string; month?: string } = {},
): KeepsakeTemplate[] {
  const art = (name: string, r: number[], rotate = 0, opacity = 1): KeepsakeLayer[] =>
    assets[name] ? [image(assets[name]!, r, rotate, opacity)] : [];
  const base = (
    id: string,
    kind: 'card' | 'video',
    isHome: boolean,
    personalization: KeepsakePersonalization,
  ) => ({
    id,
    kind,
    version: 1,
    name: isHome
      ? l('Đưa con về nhà', 'Welcome Home')
      : l('Một tháng làm quen', 'A Month of Getting to Know You'),
    description: isHome ? homeGroup : monthGroup,
    personalization,
    tier: 'premium',
    status: 'published',
    order: isHome ? 4 : 5,
    occasions: isHome ? [] : ['m1'],
    ageDays: isHome ? null : { min: 15, max: 60 },
    assets: Object.fromEntries(
      Object.entries(assets)
        .filter(
          ([key]) => key === 'p48-grain' || key.startsWith(isHome ? 'p48-home-' : 'p48-scrap-'),
        )
        .map(([key, value]) => [key === 'p48-grain' ? 'paperGrain' : roleOf(key), value]),
    ),
    photos: { min: 1, max: 1 },
    scenes: [],
    texts: [],
    palette: palettes[isHome ? 'home' : 'month'],
    palettes: [palettes[isHome ? 'home' : 'month']],
    durationSec: null,
    thumb: null,
    defaultMusic: null,
    preview: null,
    brand: null,
  });
  const home = (s: boolean): KeepsakeLayer[] => [
    { type: 'background', color: 'background', asset: null },
    ...art('p48-grain', [0, 0, 1, 1], 0, 0.04),
    ...art('p48-home-house', [0.78, s ? 0.07 : 0.027, 0.15, s ? 0.09 : 0.12]),
    text(
      'headline',
      [0.067, s ? 0.09 : 0.055, 0.68, 0.035],
      0.026,
      'beVietnamPro',
      'accent',
      1,
      600,
    ),
    text('title', [0.067, s ? 0.135 : 0.105, 0.77, s ? 0.09 : 0.12], 0.066, 'lora', 'ink', 2, 600),
    ...art('p48-home-key', [0.067, s ? 0.226 : 0.235, 0.19, s ? 0.043 : 0.06], -7),
    shape([0.061, s ? 0.31 : 0.334, 0.422, s ? 0.318 : 0.36], '#F6E7B8', -1),
    shape([0.515, s ? 0.31 : 0.334, 0.422, s ? 0.318 : 0.36], '#F6E7B8', 1),
    photo(0, [0.073, s ? 0.318 : 0.344, 0.397, s ? 0.296 : 0.332], -1),
    photo(1, [0.528, s ? 0.318 : 0.344, 0.397, s ? 0.296 : 0.332], 1),
    ...art('p48-home-window', [0.061, s ? 0.31 : 0.334, 0.422, s ? 0.318 : 0.36], -1),
    ...art('p48-home-window', [0.515, s ? 0.31 : 0.334, 0.422, s ? 0.318 : 0.36], 1),
    text('photoLabel0', [0.073, s ? 0.648 : 0.713, 0.4, 0.035], 0.026, 'beVietnamPro', 'accent', 1),
    text('photoLabel1', [0.528, s ? 0.648 : 0.713, 0.4, 0.035], 0.026, 'beVietnamPro', 'accent', 1),
    ...art('p48-home-route', [0.1, s ? 0.69 : 0.755, 0.75, s ? 0.055 : 0.055], 0, 0.65),
    text('message', [0.067, s ? 0.767 : 0.827, 0.75, s ? 0.075 : 0.07], 0.034),
    text('detail0', [0.067, s ? 0.863 : 0.91, 0.8, 0.03], 0.026, 'beVietnamPro', 'accent', 1),
    ...art('p48-home-plant', [0.842, s ? 0.787 : 0.827, 0.09, s ? 0.085 : 0.095]),
    brand(s),
  ];
  const month = (s: boolean): KeepsakeLayer[] => [
    { type: 'background', color: 'background', asset: null },
    ...art('p48-grain', [0, 0, 1, 1], 0, 0.035),
    ...art('p48-scrap-stitches', [0.014, 0.07, 0.026, s ? 0.81 : 0.8], 0, 0.5),
    ...art('p48-scrap-corner-fold', [0.86, 0.018, 0.12, s ? 0.068 : 0.096]),
    text(
      'headline',
      [0.073, s ? 0.08 : 0.045, 0.72, 0.035],
      0.026,
      'beVietnamPro',
      'accent',
      1,
      600,
    ),
    text('title', [0.073, s ? 0.126 : 0.1, 0.74, s ? 0.1 : 0.125], 0.062, 'lora', 'ink', 2, 600),
    shape([0.09, s ? 0.283 : 0.265, 0.39, s ? 0.246 : 0.278], '#FFFDF8', -3),
    photo(0, [0.104, s ? 0.292 : 0.278, 0.362, s ? 0.208 : 0.228], -3),
    shape([0.515, s ? 0.315 : 0.304, 0.39, s ? 0.246 : 0.278], '#FFFDF8', 3),
    photo(1, [0.529, s ? 0.324 : 0.317, 0.362, s ? 0.208 : 0.228], 3),
    ...art('p48-scrap-washi-ripped', [0.17, s ? 0.274 : 0.257, 0.22, s ? 0.033 : 0.047], -8),
    ...art('p48-scrap-washi-grid', [0.59, s ? 0.307 : 0.298, 0.22, s ? 0.033 : 0.047], 9),
    shape([0.245, s ? 0.571 : 0.586, 0.51, s ? 0.223 : 0.21], '#FFFDF8', -1),
    photo(2, [0.26, s ? 0.58 : 0.597, 0.48, s ? 0.184 : 0.164], -1),
    ...art('p48-scrap-photo-corners', [0.245, s ? 0.571 : 0.586, 0.51, s ? 0.223 : 0.21], -1),
    ...art('p48-scrap-month-one', [0.73, s ? 0.618 : 0.63, 0.18, s ? 0.1 : 0.14]),
    ...art('p48-scrap-pencil-loop', [0.067, s ? 0.785 : 0.78, 0.28, s ? 0.04 : 0.04], 0, 0.6),
    ...art('p48-scrap-paper-strip', [0.05, s ? 0.843 : 0.83, 0.9, s ? 0.07 : 0.075]),
    text('message', [0.08, s ? 0.853 : 0.841, 0.84, s ? 0.052 : 0.056], 0.034),
    text('signature', [0.073, s ? 0.916 : 0.918, 0.85, 0.028], 0.026, 'beVietnamPro', 'ink', 1),
    brand(s),
  ];
  const hints = (vi: string[], en: string[]) =>
    vi.map((hint, i) => ({ hint: l(hint, en[i]!), optional: false }));
  return [
    {
      ...base('card_premium48_03', 'card', true, homeCard),
      photos: { min: 2, max: 2 },
      layouts: { portrait: home(false), story: home(true) },
      composition: null,
    },
    {
      ...base('card_premium48_04', 'card', false, monthCard),
      photos: { min: 3, max: 3 },
      layouts: { portrait: month(false), story: month(true) },
      composition: null,
    },
    {
      ...base('video_premium48_03', 'video', true, homeVideo),
      photos: { min: 5, max: 5 },
      layouts: null,
      composition: 'PremiumHomecoming',
      durationSec: 35,
      brand: { ...defaultKeepsakeVideoBrand },
      defaultMusic: music.home ?? null,
      scenes: hints(
        [
          'Chuẩn bị về hoặc góc nhà',
          'Chuyến về hoặc bé ở nhà',
          'Cửa nhà hoặc góc phòng',
          'Bé trong không gian ở nhà',
          'Người thân đón bé',
        ],
        [
          'Getting ready or a corner at home',
          'Journey home or baby at home',
          'Doorway or a corner of the room',
          'Baby in the space at home',
          'Loved ones welcoming baby',
        ],
      ),
    },
    {
      ...base('video_premium48_04', 'video', false, monthVideo),
      photos: { min: 5, max: 5 },
      layouts: null,
      composition: 'PremiumFirstMonth',
      durationSec: 35,
      brand: { ...defaultKeepsakeVideoBrand },
      defaultMusic: music.month ?? null,
      scenes: hints(
        [
          'Ảnh sớm nhất bạn chọn',
          'Ảnh chăm bé những ngày đầu',
          'Khoảnh khắc giữa tháng',
          'Gần đây, cùng người chăm',
          'Chân dung đầy tháng',
        ],
        [
          'Earliest photo you selected',
          'Care in the early days',
          'An everyday moment mid-month',
          'Recently, with a caregiver',
          'A one-month portrait',
        ],
      ),
    },
  ].map((t) => keepsakeTemplateSchema.parse(t));
}
