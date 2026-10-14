/**
 * Chapter 01 (0–12 months) card templates C01–C12, as catalog data built from the creative spec
 * (`docs/product/remember-2-templates.md` §3) and the original art library
 * (`design/keepsake-art/assets.json`). Videos V01–V12 are in `keepsakes-chapter1-videos.ts`.
 *
 * Every layout is written for Dọc 4:5 and re-placed for Vuông and Story 9:16 with the spec's
 * deltas. Each format ends with the Child Life lockup (D-068 #10). Published on dev by
 * `seed-keepsakes.ts --chapter1`; for prod, `design/keepsake-templates/chapter1.json` is imported in
 * the portal (Mẫu › Nhập mẫu) and approved like any edit.
 */
import type {
  KeepsakeFormat,
  KeepsakeLayer,
  KeepsakeTemplate,
  OccasionId,
} from '@child-life/contracts';

type R = [number, number, number, number];
type Palette = { background: string; ink: string; accent: string };
type L = { vi: string; en: string };

/** Width / height of each format. */
const aspect: Record<KeepsakeFormat, number> = { portrait: 4 / 5, square: 1, story: 9 / 16 };
const formats: KeepsakeFormat[] = ['portrait', 'square', 'story'];
const rect = ([x, y, w, h]: R) => ({ x: r4(x), y: r4(y), w: r4(w), h: r4(h) });
const r4 = (n: number) => Math.round(n * 10000) / 10000;

/** A square in pixels (circles, rings) of width [w] at [x, y] in format [f]. */
const sq = (f: KeepsakeFormat, x: number, y: number, w: number): R => [x, y, w, w * aspect[f]];

/** The lockup, 16 % of the width, its height following the 5.17 : 1 aspect (D-068 #10). */
function brandAt(
  f: KeepsakeFormat,
  x: number,
  y: number,
  color = 'ink',
  opacity = 0.6,
): KeepsakeLayer {
  return {
    type: 'brand',
    kind: 'lockup',
    rect: rect([x, y, 0.16, (0.16 / 5.174) * aspect[f]]),
    color,
    opacity,
  };
}

/**
 * The photo rect that sits in [window] (fractions of [frame]) of an overlay at [frame], when both
 * are tilted [deg] about their own centres: the photo's centre is turned about the frame's.
 */
function inFrame(f: KeepsakeFormat, frame: R, window: R, deg: number): R {
  const [fx, fy, fw, fh] = frame;
  const [wx, wy, ww, wh] = window;
  const w = fw * ww;
  const h = fh * wh;
  // Work in pixels of a card 1 wide and 1/aspect tall.
  const H = 1 / aspect[f];
  const ocx = fx + fw / 2;
  const ocy = (fy + fh / 2) * H;
  const pcx = fx + fw * (wx + ww / 2);
  const pcy = (fy + fh * (wy + wh / 2)) * H;
  const a = (deg * Math.PI) / 180;
  const dx = pcx - ocx;
  const dy = pcy - ocy;
  const cx = ocx + dx * Math.cos(a) - dy * Math.sin(a);
  const cy = (ocy + dx * Math.sin(a) + dy * Math.cos(a)) / H;
  return [cx - w / 2, cy - h / 2, w, h];
}

const bg = (color: string, asset: string | null = null): KeepsakeLayer => ({
  type: 'background',
  color,
  asset,
});
const photo = (
  slot: number,
  r: R,
  shape: 'rect' | 'circle' = 'rect',
  radius = 0,
  rotate?: number,
): KeepsakeLayer => ({
  type: 'photo',
  slot,
  rect: rect(r),
  shape,
  radius,
  ...(rotate ? { rotate } : {}),
});
type TextOpts = {
  lines?: number;
  italic?: boolean;
  opacity?: number;
  caps?: boolean;
  spacing?: number;
  rotate?: number;
};
const text = (
  field: Extract<KeepsakeLayer, { type: 'text' }>['field'],
  r: R,
  font: Extract<KeepsakeLayer, { type: 'text' }>['font'],
  weight: 400 | 500 | 600 | 700,
  size: number,
  color: string,
  align: 'left' | 'center' | 'right' = 'center',
  o: TextOpts = {},
): KeepsakeLayer => ({
  type: 'text',
  field,
  rect: rect(r),
  font,
  weight,
  size,
  color,
  opacity: o.opacity ?? 1,
  align,
  italic: o.italic ?? false,
  maxLines: o.lines ?? 1,
  ...(o.rotate ? { rotate: o.rotate } : {}),
  ...(o.spacing ? { letterSpacing: o.spacing } : {}),
  ...(o.caps ? { caps: true } : {}),
});
const shape = (
  kind: 'rect' | 'circle' | 'star',
  r: R,
  color: string,
  o: { to?: string; radius?: number; stroke?: number; rotate?: number } = {},
): KeepsakeLayer => ({
  type: 'shape',
  shape: kind,
  rect: rect(r),
  color,
  gradientTo: o.to ?? null,
  radius: o.radius ?? 0,
  stroke: o.stroke ?? 0,
  ...(o.rotate ? { rotate: o.rotate } : {}),
});

const pal = (background: string, ink: string, accent: string): Palette => ({
  background,
  ink,
  accent,
});

interface CardSpec {
  id: string;
  name: L;
  tier: 'free' | 'premium';
  order: number;
  occasions: OccasionId[];
  ageDays: { min: number; max: number } | null;
  photos?: { min: number; max: number };
  texts: { key: 'title' | 'quote' | 'message' | 'headline'; default: L; max: number }[];
  palettes: Palette[];
  description: L;
  layout: (f: KeepsakeFormat, art: (name: string) => string) => KeepsakeLayer[];
}

const card = (s: CardSpec, art: (name: string) => string): KeepsakeTemplate => ({
  id: `card_${s.id}`,
  version: 1,
  kind: 'card',
  name: s.name,
  description: s.description,
  tier: s.tier,
  status: 'published',
  order: s.order,
  occasions: s.occasions,
  ageDays: s.ageDays,
  layouts: Object.fromEntries(formats.map((f) => [f, s.layout(f, art)])),
  composition: null,
  assets: {},
  photos: s.photos ?? { min: 1, max: 1 },
  scenes: [],
  texts: s.texts,
  palette: s.palettes[0]!,
  palettes: s.palettes,
  durationSec: null,
  thumb: null,
  defaultMusic: null,
  preview: null,
  brand: null,
});

/** Per-format values: [Dọc, Vuông, Story]. */
const by = <T>(f: KeepsakeFormat, v: [T, T, T]): T => v[formats.indexOf(f)]!;

const specs: CardSpec[] = [
  {
    id: 'welcome_little_one',
    name: { vi: 'Chào con', en: 'Welcome, little one' },
    description: {
      vi: 'Thiệp báo tin chào đời, kem ấm, chữ thanh',
      en: 'A warm, elegant birth announcement',
    },
    tier: 'free',
    order: 110,
    occasions: ['birth'],
    ageDays: { min: 0, max: 30 },
    texts: [
      {
        key: 'title',
        default: { vi: 'Chào con, thiên thần nhỏ', en: 'Welcome, little one' },
        max: 40,
      },
      {
        key: 'quote',
        default: { vi: 'Con là điều kỳ diệu nhất của ba mẹ', en: 'You are our sweetest miracle' },
        max: 60,
      },
    ],
    palettes: [
      pal('#F7F1E6', '#3A2E26', '#B08D57'),
      pal('#F8ECE8', '#3D2A2E', '#C08A86'),
      pal('#EEF2F0', '#25363A', '#7D9C94'),
    ],
    layout: (f, art) => [
      bg('background', art('paper-grain')),
      shape('rect', [0.07, 0.055, 0.86, 0.89], 'accent', { radius: 0.01, stroke: 0.002 }),
      {
        type: 'image',
        asset: art('leaf-sprig'),
        rect: rect([0.4, by(f, [0.063, 0.062, 0.062]), 0.2, 0.03]),
        fit: 'contain',
        opacity: 0.8,
      },
      photo(
        0,
        by(f, [
          [0.14, 0.1, 0.72, 0.52],
          [0.22, 0.1, 0.56, 0.48],
          [0.12, 0.11, 0.76, 0.5],
        ] as [R, R, R]),
        'rect',
        0.02,
      ),
      text(
        'title',
        [0.1, by(f, [0.645, 0.605, 0.64]), 0.8, 0.05],
        'lora',
        400,
        0.042,
        'ink',
        'center',
        { italic: true },
      ),
      text(
        'name',
        [0.1, by(f, [0.7, 0.655, 0.685]), 0.8, 0.085],
        'lora',
        600,
        by(f, [0.085, 0.08, 0.09]),
        'ink',
      ),
      {
        type: 'image',
        asset: art('rule-diamond'),
        rect: rect([0.3, by(f, [0.795, 0.755, 0.775]), 0.4, 0.012]),
        fit: 'contain',
        opacity: 1,
      },
      text(
        'date',
        [0.1, by(f, [0.815, 0.775, 0.79]), 0.8, 0.035],
        'beVietnamPro',
        500,
        0.028,
        'ink',
        'center',
        { opacity: 0.75 },
      ),
      text(
        'birthStats',
        [0.1, by(f, [0.853, 0.815, 0.825]), 0.8, 0.035],
        'beVietnamPro',
        600,
        0.028,
        'accent',
      ),
      ...(f === 'story'
        ? [
            text('quote', [0.12, 0.865, 0.76, 0.06], 'lora', 400, 0.036, 'ink', 'center', {
              italic: true,
              lines: 2,
            }),
          ]
        : []),
      brandAt(f, 0.42, by(f, [0.9, 0.865, 0.925])),
    ],
  },
  {
    id: 'my_first_week',
    name: { vi: 'Tuần đầu tiên', en: 'My first week' },
    description: {
      vi: 'Mây, sao nhỏ và chữ 7 ngày thật lớn',
      en: 'Clouds, tiny stars and a big "7 days"',
    },
    tier: 'free',
    order: 120,
    occasions: ['d7'],
    ageDays: { min: 5, max: 21 },
    texts: [
      {
        key: 'title',
        default: { vi: 'Tuần đầu tiên của {name}', en: "{name}'s first week" },
        max: 40,
      },
      {
        key: 'message',
        default: {
          vi: 'Bảy ngày, và ba mẹ đã yêu con hơn cả thế giới.',
          en: 'Seven days, and we already love you more than the world.',
        },
        max: 90,
      },
    ],
    palettes: [
      pal('#FBEFF1', '#3E3350', '#E88AA2'),
      pal('#ECF4FB', '#2E3B55', '#6FA3D9'),
      pal('#FFF6E3', '#4A3A28', '#E2A83B'),
    ],
    layout: (f, art) => {
      const ring = by(f, [
        sq(f, 0.205, 0.155, 0.59),
        sq(f, 0.25, 0.085, 0.5),
        sq(f, 0.19, 0.14, 0.62),
      ]);
      const inset = 0.02;
      const ph: R = [
        ring[0] + inset,
        ring[1] + inset * aspect[f],
        ring[2] - 2 * inset,
        ring[3] - 2 * inset * aspect[f],
      ];
      return [
        bg('background'),
        {
          type: 'image',
          asset: art('stars-scatter'),
          rect: rect(
            by(f, [
              [0, 0.02, 1, 0.8],
              [0, 0, 1, 0.9],
              [0, 0.05, 1, 0.6],
            ] as [R, R, R]),
          ),
          fit: 'contain',
          opacity: 0.9,
        },
        {
          type: 'image',
          asset: art('cloud-pair'),
          rect: rect([-0.05, -0.02, 0.7, 0.18]),
          fit: 'contain',
          opacity: 1,
        },
        shape('circle', ring, '#FFFFFF'),
        photo(0, ph, 'circle'),
        {
          type: 'image',
          asset: art('moon-crescent'),
          rect: rect(sq(f, 0.76, by(f, [0.12, 0.07, 0.11]), 0.13)),
          fit: 'contain',
          opacity: 1,
        },
        text(
          'ageNumber',
          [0.08, by(f, [0.625, 0.6, 0.56]), 0.4, 0.17],
          'beVietnamPro',
          700,
          by(f, [0.17, 0.15, 0.2]),
          'accent',
          'right',
        ),
        text(
          'ageUnit',
          [0.5, by(f, [0.67, 0.64, 0.6]), 0.4, 0.1],
          'dancingScript',
          600,
          by(f, [0.085, 0.075, 0.1]),
          'ink',
          'left',
        ),
        text('title', [0.08, by(f, [0.79, 0.77, 0.73]), 0.84, 0.05], 'lora', 600, 0.048, 'ink'),
        ...(f !== 'square'
          ? [
              text(
                'message',
                [0.12, by(f, [0.845, 0.845, 0.785]), 0.76, 0.07],
                'beVietnamPro',
                400,
                0.03,
                'ink',
                'center',
                { lines: by(f, [2, 2, 3]), opacity: 0.8 },
              ),
            ]
          : []),
        {
          type: 'image',
          asset: art('cloud-soft'),
          rect: rect([-0.05, by(f, [0.86, 0.84, 0.88]), 0.6, 0.12]),
          fit: 'contain',
          opacity: 1,
        },
        text(
          'date',
          [0.1, by(f, [0.915, 0.88, 0.93]), 0.8, 0.03],
          'beVietnamPro',
          500,
          0.024,
          'ink',
          'center',
          { opacity: 0.6 },
        ),
        brandAt(f, 0.42, by(f, [0.952, 0.925, 0.962])),
      ];
    },
  },
  {
    id: 'monthly_milestone',
    name: { vi: 'Mỗi tháng một mốc', en: 'Monthly milestone' },
    description: {
      vi: 'Số tháng thật lớn, bố cục kiểu tạp chí',
      en: 'Oversized month number, magazine layout',
    },
    tier: 'free',
    order: 130,
    occasions: ['m1', 'm2', 'm3', 'm4', 'm5', 'm6', 'm7', 'm8', 'm9', 'm10', 'm11', 'y1'],
    ageDays: { min: 25, max: 380 },
    texts: [
      {
        key: 'quote',
        default: {
          vi: 'Lớn thêm một chút, thương thêm thật nhiều.',
          en: 'A little bigger, loved a lot more.',
        },
        max: 60,
      },
    ],
    palettes: [
      pal('#F4F1EC', '#1E1E1E', '#D9583B'),
      pal('#141414', '#F4F1EC', '#E9C46A'),
      pal('#E6EBE3', '#1F2B24', '#4F7B5E'),
      pal('#F3E4DE', '#2B1F1C', '#B4534A'),
    ],
    layout: (f) => [
      bg('background'),
      photo(
        0,
        by(f, [
          [0.3, 0.07, 0.62, 0.6],
          [0.4, 0.06, 0.54, 0.62],
          [0.18, 0.06, 0.76, 0.56],
        ] as [R, R, R]),
      ),
      text(
        'ageNumber',
        by(f, [
          [0.04, 0.4, 0.56, 0.4],
          [0.04, 0.36, 0.52, 0.4],
          [0.04, 0.47, 0.7, 0.3],
        ] as [R, R, R]),
        'playfair',
        700,
        by(f, [0.4, 0.38, 0.4]),
        'accent',
        'left',
      ),
      text(
        'ageUnit',
        [0.07, by(f, [0.79, 0.76, 0.77]), 0.4, 0.05],
        'beVietnamPro',
        600,
        0.045,
        'ink',
        'left',
        { caps: true, spacing: 0.08 },
      ),
      shape('rect', [0.07, by(f, [0.855, 0.825, 0.83]), 0.1, 0.003], 'ink'),
      text(
        'name',
        [0.07, by(f, [0.87, 0.84, 0.845]), 0.6, 0.05],
        'beVietnamPro',
        700,
        0.05,
        'ink',
        'left',
      ),
      text(
        'date',
        [0.07, by(f, [0.925, 0.9, 0.895]), 0.5, 0.03],
        'beVietnamPro',
        500,
        0.026,
        'ink',
        'left',
        { opacity: 0.6 },
      ),
      ...(f === 'portrait'
        ? [
            text('quote', [0.5, 0.8, 0.43, 0.1], 'lora', 400, 0.028, 'ink', 'right', {
              lines: 3,
              italic: true,
              opacity: 0.8,
            }),
          ]
        : []),
      ...(f === 'story'
        ? [
            text('quote', [0.07, 0.93, 0.86, 0.05], 'lora', 400, 0.03, 'ink', 'left', {
              lines: 2,
              italic: true,
              opacity: 0.8,
            }),
          ]
        : []),
      brandAt(f, by(f, [0.77, 0.77, 0.81]), by(f, [0.93, 0.905, 0.03]), 'ink', 0.7),
    ],
  },
  {
    id: 'little_teddy',
    name: { vi: 'Gấu bông nhỏ', en: 'Little teddy bear' },
    description: {
      vi: 'Gấu bông, chăn len, khung ảnh bo tròn',
      en: 'A teddy, a knitted blanket and a soft frame',
    },
    tier: 'premium',
    order: 140,
    occasions: ['m1', 'd100', 'm2', 'm3', 'm4', 'm5', 'm6'],
    ageDays: { min: 20, max: 200 },
    texts: [
      { key: 'title', default: { vi: '{name} tròn {age}', en: '{name} is {age}' }, max: 40 },
      {
        key: 'quote',
        default: {
          vi: 'Mỗi ngày bên con là một cái ôm thật ấm.',
          en: 'Every day with you is a warm hug.',
        },
        max: 70,
      },
    ],
    // The frame art is beige: alternates keep the background.
    palettes: [
      pal('#EFE2CF', '#4A3426', '#B9804F'),
      pal('#EFE2CF', '#3B2A22', '#8A5A3C'),
      pal('#EFE2CF', '#4A3426', '#C98A2B'),
    ],
    layout: (f, art) => [
      bg('background', art('paper-grain')),
      photo(
        0,
        by(f, [
          [0.12, 0.07, 0.76, 0.62],
          [0.16, 0.06, 0.68, 0.6],
          [0.1, 0.08, 0.8, 0.56],
        ] as [R, R, R]),
        'rect',
        0.04,
      ),
      {
        type: 'image',
        asset: art(`c04-frame-${f}`),
        rect: rect([0, 0, 1, 1]),
        fit: 'fill',
        opacity: 1,
      },
      {
        type: 'image',
        asset: art('teddy-peek'),
        rect: rect(
          by(f, [
            [0.02, 0.6, 0.36, 0.224],
            [0.03, 0.55, 0.32, 0.25],
            [0.02, 0.56, 0.38, 0.166],
          ] as [R, R, R]),
        ),
        fit: 'contain',
        opacity: 1,
      },
      {
        type: 'image',
        asset: art('heart-soft'),
        rect: rect(sq(f, 0.8, by(f, [0.1, 0.08, 0.1]), 0.09)),
        fit: 'contain',
        opacity: 1,
        rotate: 12,
      },
      text(
        'title',
        by(f, [
          [0.4, 0.735, 0.54, 0.07],
          [0.38, 0.7, 0.56, 0.08],
          [0.08, 0.73, 0.84, 0.06],
        ] as [R, R, R]),
        'lora',
        700,
        0.058,
        'ink',
        by(f, ['left', 'left', 'center'] as const),
        { lines: 2 },
      ),
      ...(f !== 'square'
        ? [
            text(
              'quote',
              by(f, [
                [0.4, 0.83, 0.54, 0.07],
                [0, 0, 0, 0],
                [0.1, 0.8, 0.8, 0.07],
              ] as [R, R, R]),
              'beVietnamPro',
              400,
              0.03,
              'ink',
              by(f, ['left', 'left', 'center'] as const),
              { lines: by(f, [2, 2, 3]), opacity: 0.85 },
            ),
          ]
        : []),
      text(
        'date',
        by(f, [
          [0.4, 0.905, 0.4, 0.03],
          [0.38, 0.88, 0.4, 0.03],
          [0.1, 0.89, 0.8, 0.03],
        ] as [R, R, R]),
        'beVietnamPro',
        600,
        0.026,
        'accent',
        by(f, ['left', 'left', 'center'] as const),
      ),
      brandAt(f, by(f, [0.76, 0.78, 0.42]), by(f, [0.945, 0.925, 0.935])),
    ],
  },
  {
    id: 'blooming_love',
    name: { vi: 'Nở rộ yêu thương', en: 'Blooming with love' },
    description: { vi: 'Hoa lá màu nước, khung vòm', en: 'Watercolour flowers around an arch' },
    tier: 'premium',
    order: 150,
    occasions: [],
    ageDays: null,
    texts: [
      {
        key: 'title',
        default: { vi: 'Nở rộ trong yêu thương', en: 'Blooming with love' },
        max: 40,
      },
    ],
    palettes: [
      pal('#F6F3EC', '#2F3A31', '#C9897F'),
      pal('#F6F3EC', '#2F3A31', '#6E8E6A'),
      pal('#F6F3EC', '#3A2C2C', '#C77F7B'),
    ],
    layout: (f, art) => [
      bg('background'),
      photo(
        0,
        by(f, [
          [0.2, 0.08, 0.6, 0.58],
          [0.27, 0.06, 0.46, 0.56],
          [0.14, 0.09, 0.72, 0.52],
        ] as [R, R, R]),
      ),
      {
        type: 'image',
        asset: art(`c05-arch-${f}`),
        rect: rect([0, 0, 1, 1]),
        fit: 'fill',
        opacity: 1,
      },
      {
        type: 'image',
        asset: art('floral-garland'),
        rect: rect(
          by(f, [
            [0.42, 0.02, 0.56, 0.3],
            [0.48, 0.0, 0.5, 0.34],
            [0.4, 0.04, 0.58, 0.22],
          ] as [R, R, R]),
        ),
        fit: 'contain',
        opacity: 1,
      },
      {
        type: 'image',
        asset: art('floral-cluster'),
        rect: rect(
          by(f, [
            [0.06, 0.52, 0.36, 0.2],
            [0.1, 0.48, 0.3, 0.22],
            [0.04, 0.5, 0.38, 0.15],
          ] as [R, R, R]),
        ),
        fit: 'contain',
        opacity: 1,
      },
      text(
        'occasion',
        [0.1, by(f, [0.69, 0.65, 0.65]), 0.8, 0.04],
        'beVietnamPro',
        600,
        0.03,
        'accent',
        'center',
        { caps: true, spacing: 0.12 },
      ),
      text(
        'title',
        [0.08, by(f, [0.735, 0.69, 0.69]), 0.84, 0.065],
        'lora',
        600,
        0.058,
        'ink',
        'center',
        { italic: true, lines: by(f, [1, 1, 2]) },
      ),
      text(
        'name',
        [0.1, by(f, [0.81, 0.77, 0.775]), 0.8, 0.07],
        'dancingScript',
        600,
        0.07,
        'accent',
      ),
      text(
        'date',
        [0.1, by(f, [0.895, 0.86, 0.86]), 0.8, 0.03],
        'beVietnamPro',
        500,
        0.026,
        'ink',
        'center',
        { opacity: 0.7 },
      ),
      brandAt(f, 0.42, by(f, [0.94, 0.905, 0.915])),
    ],
  },
  {
    id: 'dreamy_star',
    name: { vi: 'Ngôi sao mơ màng', en: 'Dreamy little star' },
    description: {
      vi: 'Trăng sao, xanh đêm và vàng nhạt',
      en: 'Moon and stars in midnight blue and gold',
    },
    tier: 'premium',
    order: 160,
    occasions: [],
    ageDays: null,
    texts: [
      { key: 'title', default: { vi: 'Ngôi sao nhỏ của ba mẹ', en: 'Our little star' }, max: 40 },
      {
        key: 'quote',
        default: { vi: 'Ngủ ngoan nhé, ngôi sao nhỏ.', en: 'Sleep tight, little star.' },
        max: 50,
      },
    ],
    palettes: [
      pal('#1C2541', '#F4EBDD', '#D8B76A'),
      pal('#272042', '#F2E9F1', '#C9A3D9'),
      pal('#0F2E3D', '#EAF2F1', '#9ED0C9'),
    ],
    layout: (f, art) => {
      const ring = by(f, [
        sq(f, 0.225, 0.106, 0.55),
        sq(f, 0.29, 0.08, 0.42),
        sq(f, 0.18, 0.12, 0.64),
      ]);
      const ph: R = [
        ring[0] + 0.005,
        ring[1] + 0.005 * aspect[f],
        ring[2] - 0.01,
        ring[3] - 0.01 * aspect[f],
      ];
      return [
        bg('background'),
        {
          type: 'image',
          asset: art('stars-scatter'),
          rect: rect([0, 0, 1, 1]),
          fit: 'cover',
          opacity: 0.9,
        },
        {
          type: 'image',
          asset: art('glow-radial'),
          rect: rect([
            ring[0] - 0.12,
            ring[1] - 0.12 * aspect[f],
            ring[2] + 0.24,
            ring[3] + 0.24 * aspect[f],
          ]),
          fit: 'contain',
          opacity: 1,
        },
        photo(0, ph, 'circle'),
        shape('circle', ring, 'accent', { stroke: 0.004 }),
        {
          type: 'image',
          asset: art('moon-crescent'),
          rect: rect(sq(f, ring[0] - 0.06, ring[1] - 0.03 * aspect[f], 0.2)),
          fit: 'contain',
          opacity: 1,
        },
        shape('star', sq(f, 0.82, 0.08, 0.05), 'accent'),
        shape('star', sq(f, 0.1, by(f, [0.42, 0.42, 0.4]), 0.035), 'accent'),
        shape('star', sq(f, 0.86, by(f, [0.48, 0.45, 0.46]), 0.03), 'ink'),
        text(
          'occasion',
          [0.08, by(f, [0.6, 0.56, 0.55]), 0.84, 0.1],
          'lora',
          700,
          by(f, [0.095, 0.09, 0.11]),
          'accent',
        ),
        text(
          'title',
          [0.08, by(f, [0.705, 0.665, 0.66]), 0.84, 0.05],
          'lora',
          400,
          0.045,
          'ink',
          'center',
          { italic: true },
        ),
        {
          type: 'image',
          asset: art('cloud-pair'),
          rect: rect([0.1, by(f, [0.77, 0.74, 0.8]), 0.8, 0.12]),
          fit: 'contain',
          opacity: 0.35,
        },
        ...(f !== 'square'
          ? [
              text(
                'quote',
                [0.12, by(f, [0.82, 0.82, 0.75]), 0.76, 0.05],
                'beVietnamPro',
                400,
                0.03,
                'ink',
                'center',
                { lines: by(f, [2, 2, 3]), opacity: 0.85 },
              ),
            ]
          : []),
        text(
          'nameDate',
          [0.1, by(f, [0.915, 0.88, 0.92]), 0.8, 0.03],
          'beVietnamPro',
          600,
          0.026,
          'ink',
          'center',
          { opacity: 0.7 },
        ),
        brandAt(f, 0.42, by(f, [0.955, 0.925, 0.955])),
      ];
    },
  },
  {
    id: 'first_smile',
    name: { vi: 'Nụ cười đầu tiên', en: 'My first smile' },
    description: {
      vi: 'Màu nắng, chữ tròn vui, mặt cười',
      en: 'Sunny colours, playful type, smileys',
    },
    tier: 'free',
    order: 170,
    occasions: ['first_smile', 'laughs'],
    ageDays: { min: 21, max: 200 },
    texts: [
      { key: 'title', default: { vi: 'Nụ cười đầu tiên!', en: 'My first smile!' }, max: 30 },
      {
        key: 'quote',
        default: {
          vi: 'Nụ cười của con làm cả nhà bừng sáng.',
          en: 'Your smile lights up our whole home.',
        },
        max: 70,
      },
    ],
    palettes: [
      pal('#FFE9A8', '#3B2A14', '#E8603F'),
      pal('#CFF1E6', '#173D35', '#E86A85'),
      pal('#FFD9E4', '#41203A', '#6B4DEB'),
    ],
    layout: (f, art) => {
      const mat = by(f, [
        [0.1, 0.075, 0.8, 0.6],
        [0.17, 0.06, 0.66, 0.56],
        [0.08, 0.08, 0.84, 0.56],
      ] as [R, R, R]);
      return [
        bg('background'),
        {
          type: 'image',
          asset: art('doodles-border'),
          rect: rect([0, 0, 1, 1]),
          fit: 'fill',
          opacity: 1,
        },
        shape('rect', mat, '#FFFFFF', { radius: 0.05, rotate: -3 }),
        photo(
          0,
          [mat[0] + 0.03, mat[1] + 0.03 * aspect[f], mat[2] - 0.06, mat[3] - 0.06 * aspect[f]],
          'rect',
          0.04,
          -3,
        ),
        {
          type: 'image',
          asset: art('smiley-doodle'),
          rect: rect(sq(f, 0.72, by(f, [0.56, 0.52, 0.54]), 0.2)),
          fit: 'contain',
          opacity: 1,
          rotate: 8,
        },
        {
          type: 'image',
          asset: art('sunburst'),
          rect: rect([0.1, by(f, [0.62, 0.58, 0.6]), 0.8, 0.3]),
          fit: 'contain',
          opacity: 1,
        },
        text(
          'title',
          [0.06, by(f, [0.69, 0.66, 0.69]), 0.88, 0.1],
          'baloo',
          700,
          by(f, [0.09, 0.085, 0.1]),
          'ink',
        ),
        ...(f !== 'square'
          ? [
              text(
                'quote',
                [0.12, by(f, [0.8, 0.8, 0.79]), 0.76, 0.07],
                'beVietnamPro',
                500,
                0.032,
                'ink',
                'center',
                { lines: by(f, [2, 2, 3]) },
              ),
            ]
          : []),
        text(
          'nameDate',
          [0.1, by(f, [0.905, 0.86, 0.9]), 0.8, 0.03],
          'beVietnamPro',
          700,
          0.028,
          'accent',
        ),
        brandAt(f, 0.42, by(f, [0.948, 0.91, 0.945]), 'ink', 0.7),
      ];
    },
  },
  {
    id: 'i_can_do_it',
    name: { vi: 'Nhìn con làm được nè', en: 'Look what I can do!' },
    description: {
      vi: 'Huy chương, sticker, mừng kỹ năng mới',
      en: 'A medal and stickers for a new skill',
    },
    tier: 'free',
    order: 180,
    occasions: ['rolls_over', 'sits_up', 'crawls', 'stands', 'first_steps'],
    ageDays: { min: 90, max: 420 },
    texts: [
      { key: 'title', default: { vi: '{achievement}', en: '{achievement}' }, max: 36 },
      { key: 'headline', default: { vi: 'Kỹ năng mới', en: 'New skill' }, max: 16 },
    ],
    palettes: [
      pal('#DCEEFF', '#14253D', '#E0861A'),
      pal('#E2F5D9', '#1C3317', '#D9534F'),
      pal('#ECE4FF', '#24184A', '#D99A00'),
    ],
    layout: (f, art) => {
      const mat = by(f, [
        [0.13, 0.1, 0.74, 0.59],
        [0.17, 0.07, 0.6, 0.55],
        [0.1, 0.1, 0.8, 0.52],
      ] as [R, R, R]);
      const badge = by(f, [sq(f, 0.66, 0.55, 0.3), sq(f, 0.7, 0.47, 0.27), sq(f, 0.64, 0.5, 0.32)]);
      return [
        bg('background'),
        {
          type: 'image',
          asset: art('confetti'),
          rect: rect([0, 0, 1, 1]),
          fit: 'cover',
          opacity: 1,
        },
        shape('rect', mat, '#FFFFFF', { radius: 0.06, rotate: 2 }),
        photo(
          0,
          [
            mat[0] + 0.02,
            mat[1] + 0.015 * aspect[f] * 1.25,
            mat[2] - 0.04,
            mat[3] - 0.03 * aspect[f] * 1.25,
          ],
          'rect',
          0.05,
          2,
        ),
        {
          type: 'image',
          asset: art('washi-tape'),
          rect: rect([0.4, mat[1] - 0.02, 0.2, 0.05]),
          fit: 'contain',
          opacity: 1,
          rotate: -4,
        },
        {
          type: 'image',
          asset: art('medal-rosette'),
          rect: rect([badge[0], badge[1], badge[2], badge[3] * 1.4]),
          fit: 'contain',
          opacity: 1,
          rotate: 10,
        },
        text(
          'headline',
          [badge[0] + badge[2] * 0.2, badge[1] + badge[3] * 0.33, badge[2] * 0.6, badge[3] * 0.24],
          'baloo',
          700,
          0.028,
          'ink',
          'center',
          { lines: 2, rotate: 10 },
        ),
        text(
          'title',
          by(f, [
            [0.06, 0.72, 0.62, 0.12],
            [0.06, 0.68, 0.62, 0.12],
            [0.06, 0.68, 0.88, 0.1],
          ] as [R, R, R]),
          'baloo',
          700,
          0.072,
          'ink',
          by(f, ['left', 'left', 'center'] as const),
          { lines: 2 },
        ),
        text(
          'name',
          [0.06, by(f, [0.865, 0.83, 0.8]), by(f, [0.6, 0.6, 0.88]), 0.04],
          'beVietnamPro',
          700,
          0.04,
          'accent',
          by(f, ['left', 'left', 'center'] as const),
        ),
        text(
          'date',
          [0.06, by(f, [0.91, 0.88, 0.845]), by(f, [0.6, 0.6, 0.88]), 0.03],
          'beVietnamPro',
          600,
          0.027,
          'ink',
          by(f, ['left', 'left', 'center'] as const),
          { opacity: 0.7 },
        ),
        brandAt(f, by(f, [0.78, 0.78, 0.42]), by(f, [0.93, 0.905, 0.93]), 'ink', 0.7),
      ];
    },
  },
  {
    id: 'tiny_firsts',
    name: { vi: 'Những lần đầu xinh', en: 'Tiny firsts' },
    description: {
      vi: 'Sổ lưu niệm: polaroid, băng dính, chữ viết tay',
      en: 'Scrapbook: polaroids, tape, handwriting',
    },
    tier: 'premium',
    order: 190,
    occasions: ['first_tooth', 'first_solids', 'first_word', 'first_smile', 'laughs', 'crawls'],
    ageDays: { min: 120, max: 420 },
    photos: { min: 1, max: 2 },
    texts: [
      { key: 'title', default: { vi: '{occasion}', en: '{occasion}' }, max: 40 },
      {
        key: 'message',
        default: {
          vi: 'Hôm nay con lớn thêm một chút. Ba mẹ ghi lại để mai sau con đọc nhé.',
          en: 'Today you grew a little more. We wrote it down so you can read it one day.',
        },
        max: 140,
      },
    ],
    palettes: [pal('#E9DCC6', '#3A2F25', '#B8503A'), pal('#E9DCC6', '#24363A', '#3F7F8C')],
    layout: (f, art) => {
      // Polaroid art: 1100 × 1300 with a window at (90, 80, 920 × 960).
      const win: R = [90 / 1100, 80 / 1300, 920 / 1100, 960 / 1300];
      const frameA = by(f, [
        [0.07, 0.06, 0.5, 0.48],
        [0.1, 0.06, 0.44, 0.52],
        [0.08, 0.06, 0.56, 0.36],
      ] as [R, R, R]);
      const frameB = by(f, [
        [0.5, 0.28, 0.42, 0.4],
        [0.5, 0.2, 0.42, 0.5],
        [0.4, 0.33, 0.52, 0.33],
      ] as [R, R, R]);
      const note = by(f, [
        [0.06, 0.68, 0.88, 0.26],
        [0.06, 0.66, 0.88, 0.28],
        [0.06, 0.7, 0.88, 0.22],
      ] as [R, R, R]);
      return [
        bg('background', art('paper-grain')),
        photo(0, inFrame(f, frameA, win, -4), 'rect', 0, -4),
        {
          type: 'image',
          asset: art('polaroid-frame'),
          rect: rect(frameA),
          fit: 'fill',
          opacity: 1,
          rotate: -4,
        },
        {
          type: 'image',
          asset: art('washi-tape'),
          rect: rect([frameA[0] + frameA[2] * 0.3, frameA[1] - 0.02, 0.18, 0.05]),
          fit: 'contain',
          opacity: 1,
          rotate: -12,
        },
        {
          type: 'image',
          asset: art('pencil-heart'),
          rect: rect(inFrame(f, frameB, win, 5)),
          fit: 'contain',
          opacity: 1,
          rotate: 5,
        },
        photo(1, inFrame(f, frameB, win, 5), 'rect', 0, 5),
        {
          type: 'image',
          asset: art('polaroid-frame'),
          rect: rect(frameB),
          fit: 'fill',
          opacity: 1,
          rotate: 5,
        },
        {
          type: 'image',
          asset: art('washi-tape'),
          rect: rect([frameB[0] + frameB[2] * 0.35, frameB[1] - 0.02, 0.16, 0.045]),
          fit: 'contain',
          opacity: 1,
          rotate: 14,
        },
        {
          type: 'image',
          asset: art('pencil-doodles'),
          rect: rect([0, 0, 1, 1]),
          fit: 'fill',
          opacity: 0.8,
        },
        {
          type: 'image',
          asset: art('note-paper'),
          rect: rect(note),
          fit: 'fill',
          opacity: 1,
          rotate: -1,
        },
        text(
          'title',
          [note[0] + 0.1, note[1] + 0.025, note[2] - 0.16, 0.055],
          'lora',
          700,
          0.05,
          'ink',
          'left',
          { rotate: -1 },
        ),
        text(
          'message',
          [note[0] + 0.1, note[1] + 0.085, note[2] - 0.16, note[3] - 0.13],
          'patrickHand',
          400,
          0.034,
          'ink',
          'left',
          { lines: 4, rotate: -1 },
        ),
        text(
          'date',
          [note[0] + 0.1, note[1] + note[3] - 0.045, 0.36, 0.03],
          'patrickHand',
          400,
          0.028,
          'accent',
          'left',
          { rotate: -1 },
        ),
        text(
          'name',
          [note[0] + note[2] - 0.42, note[1] + note[3] - 0.045, 0.34, 0.03],
          'patrickHand',
          400,
          0.028,
          'accent',
          'right',
          { rotate: -1 },
        ),
        brandAt(f, 0.42, by(f, [0.95, 0.95, 0.94])),
      ];
    },
  },
  {
    id: 'then_now',
    name: { vi: 'Ngày ấy – bây giờ', en: 'Then & now' },
    description: { vi: 'Hai ảnh so sánh con lớn lên', en: 'Two photos to see how you have grown' },
    tier: 'premium',
    order: 200,
    occasions: [],
    ageDays: { min: 30, max: 420 },
    photos: { min: 2, max: 2 },
    texts: [
      {
        key: 'title',
        default: { vi: 'Con lớn nhanh quá!', en: "Look how you've grown!" },
        max: 36,
      },
    ],
    palettes: [
      pal('#FAF7F2', '#232323', '#D9653F'),
      pal('#1D1D1F', '#F5F2EC', '#F2CC8F'),
      pal('#EDF1F3', '#1F2A30', '#2F7F90'),
    ],
    layout: (f) =>
      f === 'story'
        ? [
            bg('background'),
            text('title', [0.06, 0.04, 0.88, 0.05], 'lora', 700, 0.065, 'ink'),
            shape('rect', [0.045, 0.14, 0.004, 0.72], 'ink'),
            photo(0, [0.08, 0.12, 0.84, 0.36], 'rect', 0.02),
            shape('rect', [0.1, 0.42, 0.42, 0.045], '#00000066', { radius: 0.02 }),
            text(
              'photoLabel0',
              [0.12, 0.425, 0.38, 0.04],
              'beVietnamPro',
              700,
              0.045,
              '#FFFFFF',
              'left',
            ),
            photo(1, [0.08, 0.52, 0.84, 0.36], 'rect', 0.02),
            shape('rect', [0.1, 0.82, 0.42, 0.045], '#00000066', { radius: 0.02 }),
            text(
              'photoLabel1',
              [0.12, 0.825, 0.38, 0.04],
              'beVietnamPro',
              700,
              0.045,
              '#FFFFFF',
              'left',
            ),
            shape('circle', sq(f, 0.032, 0.29, 0.03), 'accent'),
            shape('circle', sq(f, 0.032, 0.69, 0.03), 'accent'),
            text('name', [0.1, 0.905, 0.8, 0.03], 'beVietnamPro', 500, 0.03, 'ink', 'center', {
              opacity: 0.7,
            }),
            brandAt(f, 0.42, 0.95),
          ]
        : [
            bg('background'),
            text('title', [0.06, 0.05, 0.88, 0.07], 'lora', 700, 0.06, 'ink'),
            photo(
              0,
              [0.06, by(f, [0.16, 0.15, 0.16]), 0.43, by(f, [0.54, 0.55, 0.54])],
              'rect',
              0.02,
            ),
            photo(
              1,
              [0.51, by(f, [0.16, 0.15, 0.16]), 0.43, by(f, [0.54, 0.55, 0.54])],
              'rect',
              0.02,
            ),
            shape('rect', [0.12, by(f, [0.765, 0.75, 0.765]), 0.76, 0.004], 'ink'),
            shape('circle', sq(f, 0.26, by(f, [0.756, 0.738, 0.756]), 0.025), 'accent'),
            shape('circle', sq(f, 0.715, by(f, [0.756, 0.738, 0.756]), 0.025), 'accent'),
            text(
              'photoLabel0',
              [0.06, by(f, [0.79, 0.775, 0.79]), 0.43, 0.05],
              'beVietnamPro',
              700,
              0.04,
              'ink',
            ),
            text(
              'photoLabel1',
              [0.51, by(f, [0.79, 0.775, 0.79]), 0.43, 0.05],
              'beVietnamPro',
              700,
              0.04,
              'accent',
            ),
            text(
              'name',
              [0.1, by(f, [0.885, 0.87, 0.885]), 0.8, 0.04],
              'beVietnamPro',
              500,
              0.03,
              'ink',
              'center',
              { opacity: 0.7 },
            ),
            brandAt(f, 0.42, by(f, [0.94, 0.92, 0.94])),
          ],
  },
  {
    id: 'hundred_days_love',
    name: { vi: '100 ngày yêu thương', en: '100 days of love' },
    description: {
      vi: 'Kem, đỏ, vàng; hoa đào và dấu triện',
      en: 'Cream, red and gold with blossoms and a seal',
    },
    tier: 'premium',
    order: 210,
    occasions: ['d100'],
    ageDays: { min: 90, max: 130 },
    texts: [
      { key: 'headline', default: { vi: '100', en: '100' }, max: 6 },
      { key: 'title', default: { vi: 'ngày yêu thương', en: 'days of love' }, max: 30 },
      {
        key: 'quote',
        default: {
          vi: 'Trăm ngày bình an, trọn đời hạnh phúc.',
          en: 'A hundred peaceful days, a lifetime of joy.',
        },
        max: 60,
      },
    ],
    palettes: [
      pal('#F8F1E7', '#5A1F1B', '#B23A2E'),
      pal('#9E2B25', '#FCEFD9', '#E8C77A'),
      pal('#F8F1E7', '#3E2B17', '#A8842F'),
    ],
    layout: (f, art) => [
      bg('background', art('cloud-scroll')),
      photo(
        0,
        by(f, [
          [0.17, 0.07, 0.66, 0.5],
          [0.25, 0.06, 0.5, 0.48],
          [0.14, 0.08, 0.72, 0.47],
        ] as [R, R, R]),
        'rect',
        0.01,
      ),
      {
        type: 'image',
        asset: art(`c11-frame-${f}`),
        rect: rect([0, 0, 1, 1]),
        fit: 'fill',
        opacity: 1,
      },
      {
        type: 'image',
        asset: art('peach-blossom'),
        rect: rect(
          by(f, [
            [0.6, 0.0, 0.38, 0.2],
            [0.64, 0.0, 0.34, 0.24],
            [0.58, 0.02, 0.4, 0.15],
          ] as [R, R, R]),
        ),
        fit: 'contain',
        opacity: 1,
      },
      ...(f !== 'square'
        ? [
            {
              type: 'image' as const,
              asset: art('seal-100'),
              rect: rect(sq(f, 0.7, by(f, [0.47, 0.47, 0.47]), 0.16)),
              fit: 'contain' as const,
              opacity: 1,
            },
          ]
        : []),
      text(
        'headline',
        [0.1, by(f, [0.585, 0.55, 0.57]), 0.8, 0.15],
        'playfair',
        700,
        by(f, [0.16, 0.15, 0.2]),
        'accent',
      ),
      text(
        'title',
        [0.1, by(f, [0.725, 0.69, 0.72]), 0.8, 0.05],
        'lora',
        400,
        0.05,
        'ink',
        'center',
        { italic: true },
      ),
      shape('rect', [0.42, by(f, [0.79, 0.755, 0.785]), 0.16, 0.002], '#C2A15A'),
      text('name', [0.1, by(f, [0.805, 0.77, 0.8]), 0.8, 0.05], 'lora', 700, 0.05, 'ink'),
      text(
        'date',
        [0.1, by(f, [0.86, 0.83, 0.855]), 0.8, 0.03],
        'beVietnamPro',
        500,
        0.026,
        'ink',
        'center',
        { opacity: 0.7, caps: true, spacing: 0.1 },
      ),
      ...(f !== 'square'
        ? [
            text('quote', [0.12, 0.895, 0.76, 0.045], 'lora', 400, 0.03, 'ink', 'center', {
              italic: true,
              lines: 2,
            }),
          ]
        : []),
      brandAt(f, 0.42, by(f, [0.945, 0.9, 0.955])),
    ],
  },
  {
    id: 'first_birthday',
    name: { vi: 'Sinh nhật đầu tiên', en: 'My first birthday' },
    description: {
      vi: 'Bóng bay, pháo giấy, bánh kem, chữ 1 tuổi',
      en: 'Balloons, confetti, cake and a big ONE',
    },
    tier: 'free',
    order: 220,
    occasions: ['y1'],
    ageDays: { min: 350, max: 400 },
    texts: [
      { key: 'headline', default: { vi: '1 tuổi', en: 'ONE' }, max: 10 },
      {
        key: 'title',
        default: { vi: 'Mừng sinh nhật {name}!', en: 'Happy birthday, {name}!' },
        max: 40,
      },
    ],
    palettes: [
      pal('#FFF4E8', '#2F2140', '#E85A80'),
      pal('#E7F3FF', '#172A46', '#2F6FE8'),
      pal('#F6FBE3', '#24310F', '#D98A00'),
    ],
    layout: (f, art) => {
      const ring = by(f, [sq(f, 0.26, 0.14, 0.6), sq(f, 0.32, 0.1, 0.5), sq(f, 0.18, 0.15, 0.64)]);
      const ph: R = [
        ring[0] + 0.025,
        ring[1] + 0.025 * aspect[f],
        ring[2] - 0.05,
        ring[3] - 0.05 * aspect[f],
      ];
      return [
        bg('background'),
        {
          type: 'image',
          asset: art('confetti'),
          rect: rect([0, 0, 1, 1]),
          fit: 'cover',
          opacity: 1,
        },
        {
          type: 'image',
          asset: art('bunting'),
          rect: rect([0, 0, 1, 0.12]),
          fit: 'contain',
          opacity: 1,
        },
        {
          type: 'image',
          asset: art('balloons'),
          rect: rect(
            by(f, [
              [0.0, 0.08, 0.3, 0.42],
              [0.0, 0.06, 0.26, 0.4],
              [0.0, 0.1, 0.32, 0.3],
            ] as [R, R, R]),
          ),
          fit: 'contain',
          opacity: 1,
          rotate: -6,
        },
        shape('circle', ring, '#FFFFFF'),
        photo(0, ph, 'circle'),
        {
          type: 'image',
          asset: art('cake-one-candle'),
          rect: rect(sq(f, 0.7, by(f, [0.5, 0.48, 0.45]), 0.24)),
          fit: 'contain',
          opacity: 1,
        },
        text(
          'headline',
          [0.06, by(f, [0.62, 0.6, 0.55]), 0.88, 0.17],
          'baloo',
          700,
          by(f, [0.17, 0.15, 0.2]),
          'accent',
        ),
        text(
          'title',
          [0.06, by(f, [0.79, 0.77, 0.7]), 0.88, 0.06],
          'baloo',
          700,
          0.052,
          'ink',
          'center',
          { lines: by(f, [1, 1, 2]) },
        ),
        text(
          'date',
          [0.1, by(f, [0.87, 0.85, 0.8]), 0.8, 0.03],
          'beVietnamPro',
          600,
          0.028,
          'ink',
          'center',
          { opacity: 0.7 },
        ),
        brandAt(f, 0.42, by(f, [0.93, 0.9, 0.94]), 'ink', 0.7),
      ];
    },
  },
];

/** The twelve card templates with the library's uploaded asset names. */
export function chapter1Cards(art: Record<string, string>): KeepsakeTemplate[] {
  const name = (n: string) => {
    const a = art[n];
    if (!a) throw new Error(`no art asset "${n}" (design/keepsake-art/assets.json)`);
    return a;
  };
  return specs.map((s) => card(s, name));
}
