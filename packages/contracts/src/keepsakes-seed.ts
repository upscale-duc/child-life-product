import { defaultKeepsakeVideoBrand } from './keepsakes.js';
import type {
  KeepsakeCatalog,
  KeepsakeComposition,
  KeepsakeLayer,
  KeepsakeTemplate,
  OccasionId,
} from './keepsakes.js';

/**
 * The first catalog (D-068), loaded into the portal's first draft (Mẫu kỷ niệm › "Bắt đầu từ bộ
 * mẫu đầu tiên") and edited from then on there. It is not built into the app (D-068 #7). Card geometry is
 * measured from Figma MM10 / MM11 (`530:9573`, `530:9675`) for Dọc 4:5; Vuông and Story 9:16 are
 * engineering layouts of the same pieces (G-107). These first versions use no uploaded pictures;
 * staff add frames, stickers and textures as new versions.
 */

type Rect = { x: number; y: number; w: number; h: number };

const text = (
  field: 'occasion' | 'name' | 'date' | 'nameDate' | 'quote',
  rect: Rect,
  size: number,
  weight: 400 | 500 | 600 | 700,
  color: 'ink' | 'accent' | string,
  align: 'left' | 'center' = 'center',
  opacity = 1,
): KeepsakeLayer => ({
  type: 'text',
  field,
  rect,
  font: 'beVietnamPro',
  weight,
  size,
  color,
  opacity,
  align,
  italic: false,
  maxLines: field === 'quote' ? 2 : 1,
});

/** The three outline stars of MM10 / MM11, in the accent colour. */
const stars = (aspect: number): KeepsakeLayer[] =>
  [
    [0.86, 0.04],
    [0.06, 0.5],
    [0.9, 0.62],
  ].map(([x, y]) => ({
    type: 'shape',
    shape: 'star',
    rect: { x: x!, y: y!, w: 0.064, h: 0.064 * aspect },
    color: 'accent',
    gradientTo: null,
    radius: 0,
    stroke: 0.006,
  }));

const background: KeepsakeLayer = { type: 'background', color: 'background', asset: null };

/**
 * The Child Life lockup (D-068 #10): 16 % of the card's width, its height following the lockup's
 * 5.17 : 1 aspect in each format.
 */
const brand = (
  x: number,
  y: number,
  aspect: number,
  color = 'ink',
  opacity = 0.6,
): KeepsakeLayer => ({
  type: 'brand',
  kind: 'lockup',
  rect: { x, y, w: 0.16, h: Number((0.16 / 5.174 / aspect).toFixed(4)) },
  color,
  opacity,
});

const photo = (rect: Rect, shape: 'rect' | 'circle', radius = 0): KeepsakeLayer => ({
  type: 'photo',
  slot: 0,
  rect,
  shape,
  radius,
});

/** "Tròn trịa" / "Đêm sao": round photo, centred texts (MM11 at 250 × 312.5). */
function roundLayouts(): KeepsakeTemplate['layouts'] {
  const at = (aspect: number, p: Rect, y: number[], s: number[]): KeepsakeLayer[] => [
    background,
    photo(p, 'circle'),
    text('occasion', { x: 0, y: y[0]!, w: 1, h: 0.17 }, s[0]!, 700, 'accent'),
    text('name', { x: 0, y: y[1]!, w: 1, h: 0.08 }, s[1]!, 600, 'ink'),
    text('date', { x: 0, y: y[2]!, w: 1, h: 0.07 }, s[2]!, 500, 'ink', 'center', 0.6),
    text('quote', { x: 0.06, y: y[3]!, w: 0.88, h: 0.08 }, s[3]!, 600, 'accent'),
    ...stars(aspect),
    // Top left: the photo, the texts and the stars keep the rest.
    brand(0.05, 0.03, aspect),
  ];
  return {
    portrait: at(
      5 / 4,
      { x: 0.19, y: 0.08, w: 0.62, h: 0.496 },
      [0.606, 0.7725, 0.8464, 0.912],
      [0.164, 0.064, 0.052, 0.052],
    ),
    square: at(
      1,
      { x: 0.28, y: 0.06, w: 0.44, h: 0.44 },
      [0.52, 0.7, 0.77, 0.86],
      [0.13, 0.056, 0.046, 0.048],
    ),
    story: at(
      16 / 9,
      { x: 0.15, y: 0.18, w: 0.7, h: 0.394 },
      [0.61, 0.73, 0.79, 0.86],
      [0.18, 0.07, 0.056, 0.056],
    ),
  };
}

/** "Toàn ảnh": full-bleed photo, dark scrim, white text bottom left (MM10 at 165 × 206). */
function fullPhotoLayouts(): KeepsakeTemplate['layouts'] {
  const at = (aspect: number, y: number[], s: number[]): KeepsakeLayer[] => [
    background,
    photo({ x: 0, y: 0, w: 1, h: 1 }, 'rect'),
    {
      type: 'shape',
      shape: 'rect',
      rect: { x: 0, y: 0.45, w: 1, h: 0.55 },
      color: '#00000000',
      gradientTo: '#00000099',
      radius: 0,
      stroke: 0,
    },
    text('occasion', { x: 0.0625, y: y[0]!, w: 0.875, h: 0.2 }, s[0]!, 700, '#FFFFFF', 'left'),
    text(
      'nameDate',
      { x: 0.0625, y: y[1]!, w: 0.875, h: 0.06 },
      s[1]!,
      600,
      '#FFFFFF',
      'left',
      0.9,
    ),
    ...stars(aspect),
    // On the photo: white, top left.
    brand(0.0625, 0.035, aspect, '#FFFFFF', 0.85),
  ];
  return {
    portrait: at(5 / 4, [0.68, 0.92], [0.188, 0.0545]),
    square: at(1, [0.66, 0.9], [0.15, 0.05]),
    story: at(16 / 9, [0.74, 0.86], [0.17, 0.05]),
  };
}

/** "Hồng phấn": framed photo, texts bottom left (MM10 at 165 × 206). */
function framedLayouts(): KeepsakeTemplate['layouts'] {
  const at = (aspect: number, ph: number, y: number[], s: number[]): KeepsakeLayer[] => [
    background,
    photo({ x: 0.0625, y: 0.05, w: 0.875, h: ph }, 'rect', 0.05),
    text('occasion', { x: 0.0625, y: y[0]!, w: 0.875, h: 0.16 }, s[0]!, 700, 'accent', 'left'),
    text('nameDate', { x: 0.0625, y: y[1]!, w: 0.7, h: 0.06 }, s[1]!, 600, 'ink', 'left'),
    text('quote', { x: 0.0625, y: y[2]!, w: 0.875, h: 0.08 }, s[2]!, 500, 'accent', 'left'),
    ...stars(aspect),
    // Right of the name and date line.
    brand(0.7775, Number((y[1]! + (0.06 - 0.16 / 5.174 / aspect) / 2).toFixed(4)), aspect),
  ];
  return {
    portrait: at(5 / 4, 0.6, [0.68, 0.845, 0.91], [0.1515, 0.0545, 0.05]),
    square: at(1, 0.55, [0.64, 0.8, 0.88], [0.12, 0.05, 0.046]),
    story: at(16 / 9, 0.58, [0.68, 0.8, 0.86], [0.15, 0.05, 0.05]),
  };
}

const cream = { background: '#FCF5E5', ink: '#21333D', accent: '#D97359' };
const blush = { background: '#FCE8E3', ink: '#21333D', accent: '#D97359' };
const night = { background: '#1C2938', ink: '#FFFFFF', accent: '#FAD173' };
const mint = { background: '#E4F4F1', ink: '#173D44', accent: '#2BA89A' };
const sky = { background: '#E6F0FA', ink: '#21333D', accent: '#4F7FB8' };

const card = (
  id: string,
  name: { vi: string; en: string },
  tier: 'free' | 'premium',
  order: number,
  palette: typeof cream,
  layouts: KeepsakeTemplate['layouts'],
): KeepsakeTemplate => ({
  id: `card_${id}`,
  version: 1,
  kind: 'card',
  name,
  description: null,
  tier,
  status: 'published',
  order,
  occasions: [],
  ageDays: null,
  layouts,
  composition: null,
  assets: {},
  photos: { min: 1, max: 1 },
  scenes: [],
  texts: [{ key: 'quote', default: { vi: 'Yêu con thật nhiều', en: 'Loved so much' }, max: 60 }],
  palette,
  palettes: [palette, ...[cream, blush, night, mint, sky].filter((p) => p !== palette)],
  durationSec: null,
  thumb: null,
  defaultMusic: null,
  preview: null,
  brand: null,
});

/** An MM06 scene: what it shows, when its photo was taken (days since birth), its milestone. */
type SceneSpec = {
  vi: string;
  en: string;
  optional?: boolean;
  ageDays?: [number, number];
  occasion?: OccasionId;
};

const video = (
  id: string,
  composition: KeepsakeComposition,
  name: { vi: string; en: string },
  order: number,
  occasionList: OccasionId[],
  ageDays: { min: number; max: number } | null,
  photos: { min: number; max: number },
  scenes: SceneSpec[],
  title: { vi: string; en: string },
  message: { vi: string; en: string },
  durationSec: number,
  palette: typeof cream,
): KeepsakeTemplate => ({
  id: `video_${id}`,
  version: 1,
  kind: 'video',
  name,
  description: null,
  tier: 'free',
  status: 'published',
  order,
  occasions: occasionList,
  ageDays,
  layouts: null,
  composition,
  // Music and pictures are uploaded in the portal (Q-062: licensed tracks still to come).
  assets: {},
  photos,
  scenes: scenes.map((s) => ({
    hint: { vi: s.vi, en: s.en },
    optional: s.optional ?? false,
    ...(s.ageDays ? { ageDays: { min: s.ageDays[0], max: s.ageDays[1] } } : {}),
    ...(s.occasion ? { occasion: s.occasion } : {}),
  })),
  texts: [
    { key: 'title', default: title, max: 60 },
    { key: 'message', default: message, max: 140 },
  ],
  palette,
  palettes: [],
  durationSec,
  thumb: null,
  defaultMusic: null,
  preview: null,
  brand: { ...defaultKeepsakeVideoBrand },
});

export const keepsakeSeedV1: KeepsakeCatalog = {
  // D-068 #3: a free beta, Cao cấp shown but open to everyone.
  premium: { access: 'everyone', badges: true },
  // Q-062: no licensed track yet; staff add them in Thư viện nhạc.
  music: [],
  templates: [
    card('round', { vi: 'Tròn trịa', en: 'Round' }, 'free', 10, cream, roundLayouts()),
    card('full_photo', { vi: 'Toàn ảnh', en: 'Full photo' }, 'free', 20, cream, fullPhotoLayouts()),
    card('blush', { vi: 'Hồng phấn', en: 'Blush' }, 'premium', 30, blush, framedLayouts()),
    card(
      'starry_night',
      { vi: 'Đêm sao', en: 'Starry night' },
      'premium',
      40,
      night,
      roundLayouts(),
    ),
    video(
      'first_month',
      'FirstMonth',
      { vi: 'Tháng đầu tiên', en: 'The first month' },
      10,
      ['m1'],
      { min: 0, max: 45 },
      { min: 6, max: 8 },
      [
        { vi: 'Ngày chào đời', en: 'The day you were born', ageDays: [0, 3] },
        { vi: 'Tuần đầu', en: 'The first week', ageDays: [4, 10] },
        { vi: 'Tuần thứ 2', en: 'Week 2', ageDays: [11, 17] },
        { vi: 'Tuần thứ 3', en: 'Week 3', ageDays: [18, 24] },
        { vi: 'Tròn một tháng', en: 'One month old', ageDays: [25, 45], occasion: 'm1' },
        { vi: 'Bé cười', en: 'A smile', ageDays: [0, 45], occasion: 'first_smile' },
        { vi: 'Cả nhà', en: 'The whole family', ageDays: [0, 45], optional: true },
        { vi: 'Khoảnh khắc yêu thích', en: 'A favourite moment', ageDays: [0, 45], optional: true },
      ],
      { vi: 'Tháng đầu tiên của {name}', en: "{name}'s first month" },
      {
        vi: 'Một tháng qua, con dạy ba mẹ biết yêu thương nhiều hơn.',
        en: 'In one month, you taught us to love even more.',
      },
      45,
      mint,
    ),
    video(
      'first_week',
      'FirstWeek',
      { vi: '7 ngày đầu đời', en: 'The first 7 days' },
      20,
      ['d7'],
      { min: 0, max: 21 },
      { min: 4, max: 6 },
      [
        { vi: 'Ngày đầu tiên', en: 'Day one', ageDays: [0, 1] },
        { vi: 'Ngày 2–3', en: 'Days 2–3', ageDays: [1, 3] },
        { vi: 'Ngày 4–5', en: 'Days 4–5', ageDays: [3, 5] },
        { vi: 'Ngày 6–7', en: 'Days 6–7', ageDays: [5, 8], occasion: 'd7' },
        { vi: 'Ngày về nhà', en: 'Coming home', ageDays: [0, 10], optional: true },
        { vi: 'Cả nhà bên con', en: 'The family together', ageDays: [0, 21], optional: true },
      ],
      { vi: '7 ngày đầu đời của {name}', en: "{name}'s first 7 days" },
      { vi: 'Chào mừng con đến với gia đình mình.', en: 'Welcome to our family.' },
      30,
      cream,
    ),
    video(
      'hundred_days',
      'HundredDays',
      { vi: '100 ngày yêu thương', en: '100 days of love' },
      30,
      ['d100'],
      { min: 60, max: 130 },
      { min: 8, max: 10 },
      [
        { vi: 'Ngày chào đời', en: 'The day you were born', ageDays: [0, 3] },
        { vi: 'Tuần đầu', en: 'The first week', ageDays: [4, 10] },
        { vi: 'Tròn 1 tháng', en: 'One month', ageDays: [21, 40] },
        { vi: 'Ngày 50', en: 'Day 50', ageDays: [41, 55] },
        { vi: 'Tròn 2 tháng', en: 'Two months', ageDays: [56, 70] },
        { vi: 'Ngày 80', en: 'Day 80', ageDays: [71, 85] },
        { vi: 'Tròn 3 tháng', en: 'Three months', ageDays: [86, 95] },
        { vi: 'Ngày 100', en: 'Day 100', ageDays: [96, 115], occasion: 'd100' },
        { vi: 'Tiệc 100 ngày', en: 'The 100-day party', ageDays: [96, 130], optional: true },
        {
          vi: 'Cả nhà chúc mừng',
          en: 'Wishes from the family',
          ageDays: [96, 130],
          optional: true,
        },
      ],
      { vi: '100 ngày của {name}', en: "{name}'s first 100 days" },
      { vi: '100 ngày bên con là 100 ngày hạnh phúc.', en: '100 days with you, 100 happy days.' },
      60,
      blush,
    ),
    video(
      'little_moments',
      'LittleMoments',
      { vi: 'Khoảnh khắc nhỏ', en: 'Little moments' },
      40,
      [],
      null,
      { min: 3, max: 5 },
      [
        { vi: 'Gương mặt con', en: 'Your little face' },
        { vi: 'Giờ chơi', en: 'Playtime' },
        { vi: 'Ngủ ngon', en: 'Sweet dreams' },
        { vi: 'Cùng cả nhà', en: 'With the family', optional: true },
        { vi: 'Ảnh bạn thích nhất', en: 'Your favourite photo', optional: true },
      ],
      { vi: 'Khoảnh khắc nhỏ của {name}', en: "{name}'s little moments" },
      { vi: 'Những điều nhỏ bé làm nên hạnh phúc.', en: 'Little things make us happy.' },
      25,
      sky,
    ),
  ],
};
