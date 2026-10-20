import {
  keepsakeTemplateSchema,
  defaultKeepsakeVideoBrand,
  type KeepsakeLayer,
  type KeepsakeTemplate,
} from './keepsakes.js';
import {
  keepsakePersonalizationSchema,
  type KeepsakePersonalization,
} from './keepsake-personalization.js';

const l = (vi: string, en: string) => ({ vi, en });
const group = l('Chào con', 'Hello, Little One');
const field = (
  key: string,
  label: ReturnType<typeof l>,
  type: 'text' | 'date' | 'time' | 'confirmation',
  max: number,
  source?: 'babyName' | 'birthDate' | 'momentDate',
) => ({ key, label, type, max, ...(source ? { source } : {}), required: key === 'babyName' });
const name = field('babyName', l('Tên bé', 'Baby’s name'), 'text', 30, 'babyName');
const birth = field(
  'birthDate',
  l('Ngày sinh (không rõ thì để trống)', 'Birth date (leave blank if unknown)'),
  'date',
  10,
  'birthDate',
);
const narrator = field(
  'narratorName',
  l('Tên hoặc cách gọi người kể', 'Narrator’s name or role'),
  'text',
  40,
);
const moment = field(
  'momentDate',
  l('Ngày khoảnh khắc (tùy chọn)', 'Moment date (optional)'),
  'date',
  10,
  'momentDate',
);
const first = field(
  'firstConfirmed',
  l('Đây là cái ôm đầu tiên, mình xác nhận', 'I confirm this was our first embrace'),
  'confirmation',
  5,
);
const c = (
  key: string,
  label: ReturnType<typeof l>,
  text: ReturnType<typeof l>,
  requires: string[] = [],
  fallback = l('', ''),
  editable = false,
  max = 160,
) => ({ key, label, text, requires, fallback, editable, max });
const arrivalFields = [
  name,
  birth,
  field('birthTime', l('Giờ sinh (tùy chọn)', 'Birth time (optional)'), 'time', 5),
  field(
    'placeName',
    l('Nơi sinh (chỉ hiện khi bạn nhập)', 'Birthplace (only shown if entered)'),
    'text',
    40,
  ),
];
const embraceFields = [name, narrator, moment, first];
const arrivalCard = keepsakePersonalizationSchema.parse({
  group,
  fields: arrivalFields,
  beats: [],
  copy: [
    c('headline', l('Nhãn', 'Label'), l('NGÀY CON ĐẾN', 'THE DAY YOU ARRIVED')),
    c(
      'title',
      l('Lời chào', 'Greeting'),
      l('Chào con, {babyName}.', 'Welcome, {babyName}.'),
      [],
      l('', ''),
      true,
    ),
    c(
      'message',
      l('Lời nhắn', 'Message'),
      l(
        'Một ngày bình thường đã trở thành ngày nhà mình luôn nhớ.',
        'An ordinary day became one we will always remember.',
      ),
      [],
      l('', ''),
      true,
    ),
    c('detail0', l('Ngày', 'Date'), l('{birthDate}', '{birthDate}'), ['birthDate']),
    c('detail1', l('Giờ', 'Time'), l('{birthTime}', '{birthTime}'), ['birthTime']),
    c('detail2', l('Nơi', 'Place'), l('{placeName}', '{placeName}'), ['placeName']),
    c('label0', l('Nhãn ngày', 'Date label'), l('NGÀY', 'DATE'), ['birthDate']),
    c('label1', l('Nhãn giờ', 'Time label'), l('GIỜ', 'TIME'), ['birthTime']),
    c('label2', l('Nhãn nơi', 'Place label'), l('NƠI SINH', 'BIRTHPLACE'), ['placeName']),
  ],
});
const embraceCard = keepsakePersonalizationSchema.parse({
  group,
  fields: embraceFields,
  beats: [],
  copy: [
    c('headline', l('Nhãn', 'Label'), l('MỘT CÁI ÔM MUỐN NHỚ', 'AN EMBRACE TO REMEMBER')),
    c(
      'title',
      l('Tiêu đề', 'Title'),
      l('Lần đầu ôm con.', 'Our first embrace.'),
      ['firstConfirmed'],
      l('Một cái ôm muốn nhớ.', 'An embrace to remember.'),
      true,
    ),
    c(
      'message',
      l('Lời nhắn', 'Message'),
      l(
        'Chưa biết hết mọi điều. Chỉ biết muốn ôm con thật lâu.',
        'So much still to learn. For now, just holding you close.',
      ),
      [],
      l('', ''),
      true,
    ),
    c(
      'signature',
      l('Người kể', 'Narrator'),
      l('{narratorName} & {babyName}', '{narratorName} & {babyName}'),
      ['narratorName'],
      l('Nhà mình & {babyName}', 'Your family & {babyName}'),
    ),
    c('detail0', l('Ngày', 'Date'), l('{momentDate}', '{momentDate}'), ['momentDate']),
  ],
});
const arrivalVideo = keepsakePersonalizationSchema.parse({
  group,
  fields: arrivalFields,
  beats: [0, 1, 2, 3, 4].map((i) => ({ slots: [i], textKey: `scene${i + 1}` })),
  copy: [
    c('title', l('Tên video', 'Video title'), l('Ngày con đến', 'The Day You Arrived')),
    c(
      'scene1',
      l('Cảnh 1 · Mở đầu', 'Scene 1 · Opening'),
      l('Ngày {birthDate}…', 'On {birthDate}…'),
      ['birthDate'],
      l('Ngày con đến…', 'The day you arrived…'),
      true,
    ),
    c(
      'scene2',
      l('Cảnh 2', 'Scene 2'),
      l('Nhà mình đón một người rất nhỏ.', 'Someone very small joined our world.'),
      [],
      l('', ''),
      true,
    ),
    c(
      'scene3',
      l('Cảnh 3', 'Scene 3'),
      l('Một bàn tay. Một cái ôm.', 'A tiny hand. An embrace.'),
      [],
      l('', ''),
      true,
    ),
    c(
      'scene4',
      l('Cảnh 4', 'Scene 4'),
      l('Và thật nhiều điều đang bắt đầu.', 'And so much just beginning.'),
      [],
      l('', ''),
      true,
    ),
    c(
      'scene5',
      l('Cảnh 5 · Kết', 'Scene 5 · Closing'),
      l('Chào con, {babyName}.', 'Welcome, {babyName}.'),
      [],
      l('', ''),
      true,
    ),
    c('detail0', l('Ngày sinh', 'Birth date'), l('{birthDate}', '{birthDate}'), ['birthDate']),
    c('detail1', l('Giờ sinh', 'Birth time'), l('{birthTime}', '{birthTime}'), ['birthTime']),
    c('detail2', l('Nơi sinh', 'Birthplace'), l('{placeName}', '{placeName}'), ['placeName']),
  ],
});
const embraceVideo = keepsakePersonalizationSchema.parse({
  group,
  fields: embraceFields,
  beats: [0, 1, 2, 3, 2].map((slot, i) => ({ slots: [slot], textKey: `scene${i + 1}` })),
  copy: [
    c(
      'title',
      l('Tên video', 'Video title'),
      l('Lần đầu ôm con', 'Our First Embrace'),
      ['firstConfirmed'],
      l('Một cái ôm muốn nhớ', 'An Embrace to Remember'),
    ),
    c(
      'scene1',
      l('Cảnh 1 · Mở đầu', 'Scene 1 · Opening'),
      l('Có một khoảnh khắc…', 'There was a moment…'),
      [],
      l('', ''),
      true,
    ),
    c(
      'scene2',
      l('Cảnh 2', 'Scene 2'),
      l('Mọi thứ quanh mình chậm lại.', 'When everything seemed to slow down.'),
      [],
      l('', ''),
      true,
    ),
    c(
      'scene3',
      l('Cảnh 3', 'Scene 3'),
      l('Con nằm gọn trong vòng tay.', 'You fit right into these arms.'),
      [],
      l('', ''),
      true,
    ),
    c(
      'scene4',
      l('Cảnh 4', 'Scene 4'),
      l('Mình bắt đầu làm quen với nhau.', 'We began getting to know each other.'),
      [],
      l('', ''),
      true,
    ),
    c(
      'scene5',
      l('Cảnh 5 · Kết', 'Scene 5 · Closing'),
      l('Cái ôm đầu tiên. Nhớ mãi.', 'Our first embrace. Always remembered.'),
      ['firstConfirmed'],
      l('Một cái ôm muốn nhớ.', 'An embrace to remember.'),
      true,
    ),
    c(
      'signature',
      l('Người kể', 'Narrator'),
      l('{narratorName} & {babyName}', '{narratorName} & {babyName}'),
      ['narratorName'],
      l('Nhà mình & {babyName}', 'Your family & {babyName}'),
    ),
    c('detail0', l('Ngày', 'Date'), l('{momentDate}', '{momentDate}'), ['momentDate']),
  ],
});

const palettes = {
  arrival: { background: '#FFF8EF', ink: '#47372F', accent: '#B9654B' },
  embrace: { background: '#EEE4D7', ink: '#443B37', accent: '#AA7662' },
};
const rect = (x: number, y: number, w: number, h: number) => ({ x, y, w, h });
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
    rect: rect(...(r as [number, number, number, number])),
    size,
    font,
    color,
    maxLines,
    weight,
    opacity: 1,
    align: 'left',
    italic: false,
  }) as KeepsakeLayer;
const photo = (r: number[]): KeepsakeLayer => ({
  type: 'photo',
  slot: 0,
  rect: rect(...(r as [number, number, number, number])),
  shape: 'rect',
  radius: 0.012,
});
const shape = (r: number[], color: string, stroke = 0): KeepsakeLayer => ({
  type: 'shape',
  shape: 'rect',
  rect: rect(...(r as [number, number, number, number])),
  color,
  radius: 0,
  stroke,
  gradientTo: null,
});
const image = (asset: string, r: number[], opacity = 1): KeepsakeLayer => ({
  type: 'image',
  asset,
  rect: rect(...(r as [number, number, number, number])),
  fit: 'fill',
  opacity,
});
const brand = (story: boolean): KeepsakeLayer => ({
  type: 'brand',
  kind: 'lockup',
  rect: rect(0.067, story ? 0.947 : 0.945, 0.22, story ? 0.018 : 0.025),
  color: 'ink',
  opacity: 0.6,
});

/** Supply real, immutable asset names on publish; no placeholder asset URLs reach the app. */
export function premium48Phase1(
  assets: Record<string, string> = {},
  music: { arrival?: string; embrace?: string } = {},
): KeepsakeTemplate[] {
  const base = (
    id: string,
    kind: 'card' | 'video',
    name: ReturnType<typeof l>,
    p: 'arrival' | 'embrace',
    personalization: KeepsakePersonalization,
  ) => ({
    id,
    version: 1,
    kind,
    name,
    personalization,
    description: group,
    tier: 'premium',
    status: 'published',
    order: p === 'arrival' ? 2 : 3,
    occasions: p === 'arrival' ? ['birth'] : [],
    ageDays: null,
    assets: Object.fromEntries(
      Object.entries({
        paperGrain: assets['p48-grain'],
        arrivalSun: assets['p48-arrival-sun'],
        embracePaper: assets['p48-embrace-paper'],
        embraceLine: assets['p48-embrace-line'],
      }).filter((e): e is [string, string] => !!e[1]),
    ),
    photos: { min: 1, max: 1 },
    scenes: [],
    texts: [],
    palette: palettes[p],
    palettes: [palettes[p]],
    durationSec: null,
    thumb: null,
    defaultMusic: null,
    preview: null,
    brand: null,
  });
  const arrival = (story: boolean): KeepsakeLayer[] => {
    const layers: KeepsakeLayer[] = [{ type: 'background', color: 'background', asset: null }];
    if (assets['p48-grain']) layers.push(image(assets['p48-grain'], [0, 0, 1, 1], 0.045));
    layers.push(
      text(
        'headline',
        [0.067, story ? 0.105 : 0.052, 0.68, 0.04],
        0.026,
        'beVietnamPro',
        'accent',
        1,
        600,
      ),
    );
    layers.push(photo([0.067, story ? 0.16 : 0.12, 0.866, story ? 0.365 : 0.415]));
    if (assets['p48-arrival-sun'])
      layers.push(
        image(assets['p48-arrival-sun'], [
          0.805,
          story ? 0.08 : 0.018,
          0.13,
          story ? 0.073 : 0.104,
        ]),
      );
    layers.push(
      text(
        'title',
        [0.067, story ? 0.562 : 0.565, 0.866, story ? 0.11 : 0.13],
        0.073,
        'lora',
        'ink',
        2,
        600,
      ),
    );
    layers.push(text('message', [0.067, story ? 0.708 : 0.72, 0.86, story ? 0.065 : 0.08], 0.034));
    const y = story ? 0.812 : 0.838;
    layers.push(shape([0.067, y - 0.018, 0.866, 0.001], '#DCCABB'));
    for (let i = 0; i < 3; i++) {
      const x = 0.067 + i * 0.298;
      layers.push(text(`label${i}`, [x, y, 0.267, 0.029], 0.026, 'beVietnamPro', 'accent', 1, 600));
      layers.push(text(`detail${i}`, [x, y + 0.032, 0.265, story ? 0.06 : 0.064], 0.028));
    }
    layers.push(brand(story));
    return layers;
  };
  const embrace = (story: boolean): KeepsakeLayer[] => {
    const layers: KeepsakeLayer[] = [
      { type: 'background', color: 'background', asset: null },
      photo([0.067, story ? 0.105 : 0.065, 0.866, story ? 0.49 : 0.54]),
    ];
    if (assets['p48-embrace-paper'])
      layers.push(
        image(assets['p48-embrace-paper'], [0, story ? 0.55 : 0.535, 1, story ? 0.45 : 0.465]),
      );
    else layers.push(shape([0, story ? 0.59 : 0.58, 1, 0.42], 'background'));
    if (assets['p48-grain'])
      layers.push(image(assets['p48-grain'], [0, story ? 0.6 : 0.6, 1, 0.4], 0.04));
    if (assets['p48-embrace-line'])
      layers.push(
        image(
          assets['p48-embrace-line'],
          [0.84, story ? 0.62 : 0.615, 0.095, story ? 0.053 : 0.076],
          0.7,
        ),
      );
    layers.push(
      text(
        'title',
        [0.067, story ? 0.655 : 0.65, 0.74, story ? 0.1 : 0.115],
        0.068,
        'lora',
        'ink',
        2,
        600,
      ),
    );
    layers.push(text('message', [0.067, story ? 0.773 : 0.79, 0.86, story ? 0.063 : 0.073], 0.034));
    layers.push(
      text(
        'signature',
        [0.067, story ? 0.862 : 0.887, 0.866, 0.027],
        0.028,
        'beVietnamPro',
        'ink',
        1,
      ),
    );
    layers.push(
      text(
        'detail0',
        [0.067, story ? 0.89 : 0.914, 0.866, 0.029],
        0.026,
        'beVietnamPro',
        'accent',
        1,
      ),
    );
    layers.push(brand(story));
    return layers;
  };
  const hints = (vi: string[], en: string[]) =>
    vi.map((v, i) => ({ hint: l(v, en[i]!), optional: false }));
  return [
    {
      ...base(
        'card_premium48_01',
        'card',
        l('Ngày con đến', 'The Day You Arrived'),
        'arrival',
        arrivalCard,
      ),
      layouts: { portrait: arrival(false), story: arrival(true) },
      composition: null,
    },
    {
      ...base(
        'card_premium48_02',
        'card',
        l('Lần đầu ôm con', 'Our First Embrace'),
        'embrace',
        embraceCard,
      ),
      layouts: { portrait: embrace(false), story: embrace(true) },
      composition: null,
    },
    {
      ...base(
        'video_premium48_01',
        'video',
        l('Ngày con đến', 'The Day You Arrived'),
        'arrival',
        arrivalVideo,
      ),
      layouts: null,
      composition: 'PremiumArrival',
      photos: { min: 5, max: 5 },
      durationSec: 35,
      brand: { ...defaultKeepsakeVideoBrand },
      defaultMusic: music.arrival ?? null,
      scenes: hints(
        [
          'Chi tiết chăn hoặc bàn tay',
          'Chân dung đầu tiên',
          'Ảnh ôm bé',
          'Gia đình hoặc người chăm',
          'Chân dung hiện tại',
        ],
        [
          'Blanket or hand detail',
          'An early portrait',
          'An embrace',
          'Family or caregiver',
          'A recent portrait',
        ],
      ),
    },
    {
      ...base(
        'video_premium48_02',
        'video',
        l('Lần đầu ôm con', 'Our First Embrace'),
        'embrace',
        embraceVideo,
      ),
      layouts: null,
      composition: 'PremiumEmbrace',
      photos: { min: 4, max: 4 },
      durationSec: 35,
      brand: { ...defaultKeepsakeVideoBrand },
      defaultMusic: music.embrace ?? null,
      scenes: hints(
        [
          'Bàn tay người lớn',
          'Khoảnh khắc gần bé',
          'Cái ôm yêu thích (kết lại)',
          'Góc nghiêng cùng nhau',
        ],
        [
          'An adult’s hand',
          'Getting close to baby',
          'Favourite embrace (reprise)',
          'Together, from another angle',
        ],
      ),
    },
  ].map((t) => keepsakeTemplateSchema.parse(t));
}
