import { defaultKeepsakeVideoBrand } from './keepsakes.js';
import type { KeepsakeComposition, KeepsakeTemplate, OccasionId } from './keepsakes.js';

/**
 * Chapter 01 Memory Story templates V01–V12 (docs/product/remember-2-templates.md §5): data only;
 * motion is in the renderer's compositions of the same name. `durationSec` is the longest the
 * video may run; the composition fits the photos inside it. Default music is set when the
 * catalog is published with its tracks (`scripts/src/seed-keepsakes.ts`).
 */

type L = { vi: string; en: string };
const pal = (background: string, ink: string, accent: string) => ({ background, ink, accent });

interface VideoSpec {
  id: string;
  composition: KeepsakeComposition;
  name: L;
  description: L;
  tier: 'free' | 'premium';
  order: number;
  occasions: OccasionId[];
  ageDays: { min: number; max: number } | null;
  photos: { min: number; max: number };
  durationSec: number;
  palettes: ReturnType<typeof pal>[];
  texts: { key: KeepsakeTemplate['texts'][number]['key']; default: L; max: number }[];
  scenes: Scene[];
}

const video = (s: VideoSpec): KeepsakeTemplate => ({
  id: `video_${s.id}`,
  version: 1,
  kind: 'video',
  name: s.name,
  description: s.description,
  tier: s.tier,
  status: 'published',
  order: s.order,
  occasions: s.occasions,
  ageDays: s.ageDays,
  layouts: null,
  composition: s.composition,
  assets: {},
  photos: s.photos,
  scenes: s.scenes,
  texts: s.texts,
  palette: s.palettes[0]!,
  palettes: s.palettes,
  durationSec: s.durationSec,
  thumb: null,
  defaultMusic: null,
  preview: null,
  brand: { ...defaultKeepsakeVideoBrand },
});

type Scene = KeepsakeTemplate['scenes'][number];
/**
 * An MM06 scene — what it shows, when its photo was taken (days since birth; none: any photo,
 * newest first) and the milestone it shows. Optional scenes add to the video when filled.
 */
const sc = (
  vi: string,
  en: string,
  ageDays?: [number, number],
  more: { optional?: boolean; occasion?: OccasionId } = {},
): Scene => ({
  hint: { vi, en },
  optional: more.optional ?? false,
  ...(ageDays ? { ageDays: { min: ageDays[0], max: ageDays[1] } } : {}),
  ...(more.occasion ? { occasion: more.occasion } : {}),
});
const opt = { optional: true };
/** Month k of life (1 = the first), in days since birth. */
const month = (k: number): [number, number] => [
  Math.round((k - 1) * 30.44),
  Math.round(k * 30.44) - 1,
];
const months = (ks: number[], optional: number[] = []) =>
  ks.map((k) => sc(`Tháng ${k}`, `Month ${k}`, month(k), { optional: optional.includes(k) }));

export const keepsakeChapter1Videos: KeepsakeTemplate[] = [
  video({
    id: 'welcome_world',
    composition: 'WelcomeWorld',
    name: { vi: 'Chào con đến với thế giới', en: 'Welcome to the world' },
    description: {
      vi: 'Điện ảnh, từ tối ra sáng, piano nhẹ',
      en: 'Cinematic, dark to light, soft piano',
    },
    tier: 'free',
    order: 310,
    occasions: ['birth'],
    ageDays: { min: 0, max: 45 },
    photos: { min: 5, max: 8 },
    durationSec: 30,
    palettes: [pal('#0E0D0C', '#F5EFE6', '#D9B77E'), pal('#F7F1E6', '#3A2E26', '#B08D57')],
    scenes: [
      sc('Khoảnh khắc chào đời', 'The moment you arrived', [0, 2]),
      sc('Lần đầu ôm con', 'The first cuddle', [0, 3]),
      sc('Bàn tay, bàn chân bé xíu', 'Tiny hands and feet', [0, 14]),
      sc('Con ngủ say', 'Fast asleep', [0, 30]),
      sc('Ngày về nhà', 'Coming home', [1, 14]),
      sc('Cả nhà bên con', 'The family together', [0, 45], opt),
      sc('Gương mặt con', 'Your little face', [0, 45], opt),
      sc('Khoảnh khắc yêu thích', 'A favourite moment', [0, 45], opt),
    ],
    texts: [
      { key: 'title', default: { vi: 'Chào con, {name}', en: 'Hello, {name}' }, max: 40 },
      {
        key: 'closing',
        default: {
          vi: 'Chào mừng con đến với thế giới của ba mẹ.',
          en: 'Welcome to our world, little one.',
        },
        max: 70,
      },
    ],
  }),
  video({
    id: 'our_first_days',
    composition: 'OurFirstDays',
    name: { vi: 'Những ngày đầu bên nhau', en: 'Our first days' },
    description: {
      vi: 'Ảnh in xếp chồng, giấy lụa, ấm áp',
      en: 'Stacked prints on linen, cozy and warm',
    },
    tier: 'free',
    order: 320,
    occasions: ['d7', 'm1'],
    ageDays: { min: 3, max: 45 },
    photos: { min: 6, max: 10 },
    durationSec: 35,
    palettes: [pal('#F3ECE2', '#3B302A', '#C07A55'), pal('#EEF0EA', '#2E3A33', '#6E8E6A')],
    scenes: [
      sc('Ngày đầu tiên', 'Day one', [0, 1]),
      sc('Những ngày ở viện', 'In the hospital', [0, 4]),
      sc('Ngày về nhà', 'Coming home', [1, 10]),
      sc('Giấc ngủ đầu đời', 'First naps', [0, 14]),
      sc('Giờ bú', 'Feeding time', [0, 30]),
      sc('Giờ tắm', 'Bath time', [3, 30]),
      sc('Trong vòng tay ba', 'In Dad’s arms', [0, 45], opt),
      sc('Bên mẹ', 'With Mom', [0, 45], opt),
      sc('Ông bà, người thân', 'Family visits', [0, 45], opt),
      sc('Tròn một tháng', 'One month old', [25, 45], { optional: true, occasion: 'm1' }),
    ],
    texts: [
      {
        key: 'title',
        default: { vi: 'Những ngày đầu bên nhau', en: 'Our first days together' },
        max: 40,
      },
      {
        key: 'message',
        default: {
          vi: 'Cảm ơn con đã đến, làm ba mẹ của con là món quà lớn nhất.',
          en: 'Thank you for coming to us. Being your parents is our greatest gift.',
        },
        max: 140,
      },
    ],
  }),
  video({
    id: 'little_love_story',
    composition: 'LittleLoveStory',
    name: { vi: 'Chuyện tình nhỏ', en: 'Little love story' },
    description: { vi: 'Mỗi ảnh một câu yêu thương', en: 'A line of love with every photo' },
    tier: 'premium',
    order: 330,
    occasions: ['m1', 'm2', 'm3'],
    ageDays: { min: 20, max: 120 },
    photos: { min: 5, max: 8 },
    durationSec: 35,
    palettes: [pal('#F7E9E6', '#4A2C33', '#C76D7E'), pal('#EFE9F4', '#3A2C4A', '#8B6BB5')],
    scenes: [
      sc('Ngày con đến', 'The day you came', [0, 7]),
      sc('Bàn tay bé xíu', 'Your tiny hand', [0, 120]),
      sc('Con ngủ ngon', 'Sleeping soundly', [0, 120]),
      sc('Ba mẹ và con', 'Us, with you', [0, 120]),
      sc('Một khoảnh khắc lặng', 'A quiet moment', [0, 120]),
      sc('Bình yên ở nhà', 'Calm at home', [0, 120], opt),
      sc('Nụ cười của con', 'Your smile', [21, 120], { optional: true, occasion: 'first_smile' }),
      sc('Ảnh gần đây', 'A recent photo', undefined, opt),
    ],
    texts: [
      {
        key: 'title',
        default: { vi: 'Chuyện tình nhỏ bắt đầu…', en: 'A little love story began…' },
        max: 40,
      },
      {
        key: 'lines',
        default: {
          vi: 'Ngày con đến, mọi thứ đều đổi khác.\nBàn tay bé xíu nắm lấy tim ba mẹ.\nMỗi tiếng thở của con là một bài hát.\nBa mẹ học yêu thương từ con.\nChậm thôi con, ba mẹ muốn nhớ hết.\nCon là bình yên của nhà mình.\nNụ cười con làm ngày dài ngắn lại.\nVà câu chuyện mới chỉ bắt đầu.',
          en: 'The day you came, everything changed.\nYour tiny hand holds our hearts.\nEvery breath you take is a lullaby.\nYou taught us a new kind of love.\nSlow down, we want to remember it all.\nYou are the calm of our home.\nYour smile makes the long days short.\nAnd the story has only begun.',
        },
        max: 600,
      },
      {
        key: 'closing',
        default: { vi: 'Con là tình yêu lớn nhất của ba mẹ.', en: 'You are our greatest love.' },
        max: 60,
      },
    ],
  }),
  video({
    id: 'tiny_moments',
    composition: 'TinyMoments',
    name: { vi: 'Khoảnh khắc xinh', en: 'Tiny moments' },
    description: { vi: 'Ghép ảnh, sticker, nhịp vui', en: 'Collages, stickers and a bouncy beat' },
    tier: 'free',
    order: 340,
    occasions: [],
    ageDays: null,
    photos: { min: 6, max: 12 },
    durationSec: 25,
    palettes: [
      pal('#FFF1D6', '#2D2A32', '#E85555'),
      pal('#DDF4FF', '#1D2B3A', '#E09A00'),
      pal('#E9F9E4', '#203522', '#E5638A'),
    ],
    scenes: [
      sc('Gương mặt đáng yêu', 'That cute face'),
      sc('Bàn chân xinh', 'Little feet'),
      sc('Giờ chơi', 'Playtime'),
      sc('Giờ ăn', 'Mealtime'),
      sc('Giờ tắm', 'Bath time'),
      sc('Ngủ ngon', 'Sweet dreams'),
      sc('Đi chơi', 'Out and about', undefined, opt),
      sc('Đồ chơi yêu thích', 'A favourite toy', undefined, opt),
      sc('Biểu cảm hài hước', 'A funny face', undefined, opt),
      sc('Cùng cả nhà', 'With the family', undefined, opt),
      sc('Khoảnh khắc bất ngờ', 'A surprise moment', undefined, opt),
      sc('Ảnh bạn thích nhất', 'Your favourite photo', undefined, opt),
    ],
    texts: [
      { key: 'title', default: { vi: 'Những khoảnh khắc nhỏ', en: 'Tiny moments' }, max: 30 },
      {
        key: 'closing',
        default: { vi: 'Khoảnh khắc nhỏ, kỷ niệm lớn.', en: 'Little moments, big memories.' },
        max: 50,
      },
    ],
  }),
  video({
    id: 'growing_so_fast',
    composition: 'GrowingSoFast',
    name: { vi: 'Lớn nhanh quá', en: 'Growing so fast' },
    description: {
      vi: 'Dòng thời gian, nhãn tuổi, trước – sau',
      en: 'A timeline with ages, then and now',
    },
    tier: 'premium',
    order: 350,
    occasions: ['m2', 'm3', 'm4', 'm5', 'm6', 'm7', 'm8', 'm9', 'm10', 'm11', 'y1'],
    ageDays: { min: 45, max: 400 },
    photos: { min: 6, max: 12 },
    durationSec: 40,
    palettes: [pal('#F2F5F7', '#1C2A33', '#24907F'), pal('#FBF3EA', '#33261B', '#D06A4C')],
    scenes: [
      sc('Lúc mới sinh', 'Newborn', [0, 14]),
      sc('Tháng đầu', 'The first month', [15, 45]),
      ...months([2, 3, 4, 5, 6, 7, 8, 9, 10], [2, 3, 4, 5, 6, 7, 8, 9, 10]),
      sc('Bây giờ', 'Now'),
    ],
    texts: [
      {
        key: 'title',
        default: { vi: 'Con lớn nhanh quá!', en: 'Look how much you’ve grown!' },
        max: 40,
      },
      {
        key: 'closing',
        default: {
          vi: 'Mỗi ngày một lớn, mỗi ngày một thương.',
          en: 'Growing every day, loved every day.',
        },
        max: 60,
      },
    ],
  }),
  video({
    id: 'hello_smile',
    composition: 'HelloSmile',
    name: { vi: 'Chào nụ cười xinh', en: 'Hello, little smile' },
    description: { vi: 'Nắng vàng, mặt cười, vui tươi', en: 'Sunshine, smileys and joy' },
    tier: 'free',
    order: 360,
    occasions: ['first_smile', 'laughs'],
    ageDays: { min: 21, max: 240 },
    photos: { min: 4, max: 8 },
    durationSec: 25,
    palettes: [pal('#FFE29A', '#3B2A14', '#E8603F'), pal('#FFD6E0', '#40213A', '#6B4DEB')],
    scenes: [
      sc('Nụ cười đầu tiên', 'The first smile', [21, 120], { occasion: 'first_smile' }),
      sc('Cười tít mắt', 'Eyes smiling too', [21, 240]),
      sc('Cười với ba', 'Smiling at Dad', [21, 240]),
      sc('Cười với mẹ', 'Smiling at Mom', [21, 240]),
      sc('Cười khanh khách', 'Giggles', [60, 240], { optional: true, occasion: 'laughs' }),
      sc('Mặt hài hước', 'A funny face', [21, 240], opt),
      sc('Vừa chơi vừa cười', 'Laughing at play', [21, 240], opt),
      sc('Nụ cười gần đây', 'A recent smile', undefined, opt),
    ],
    texts: [
      {
        key: 'title',
        default: { vi: 'Nụ cười đầu tiên ấy…', en: 'That first little smile…' },
        max: 40,
      },
      {
        key: 'closing',
        default: { vi: 'Cười thật nhiều nhé, mặt trời nhỏ!', en: 'Keep smiling, little sunshine!' },
        max: 50,
      },
    ],
  }),
  video({
    id: 'first_milestone',
    composition: 'FirstMilestone',
    name: { vi: 'Cột mốc đầu tiên', en: 'My first milestone' },
    description: {
      vi: 'Huy chương, pháo giấy, tự hào',
      en: 'A medal, confetti and a proud moment',
    },
    tier: 'free',
    order: 370,
    occasions: ['rolls_over', 'sits_up', 'crawls', 'stands', 'first_steps'],
    ageDays: { min: 90, max: 420 },
    photos: { min: 4, max: 8 },
    durationSec: 30,
    palettes: [pal('#DCEEFF', '#14253D', '#E0861A'), pal('#E2F5D9', '#1C3317', '#D9534F')],
    scenes: [
      sc('Chuẩn bị', 'Getting ready'),
      sc('Cố gắng', 'Trying hard'),
      sc('Gần được rồi', 'Almost there'),
      sc('Làm được rồi!', 'Did it!'),
      sc('Ăn mừng', 'Celebrating', undefined, opt),
      sc('Ba mẹ cổ vũ', 'Cheering you on', undefined, opt),
      sc('Thêm lần nữa', 'One more time', undefined, opt),
      sc('Tự hào quá', 'So proud', undefined, opt),
    ],
    texts: [
      {
        key: 'headline',
        default: { vi: 'Nhìn con làm được nè!', en: 'Look what I can do!' },
        max: 36,
      },
      {
        key: 'lines',
        default: {
          vi: 'Cố lên nào!\nGần được rồi!\nLàm được rồi!',
          en: 'Here we go!\nAlmost there!\nDid it!',
        },
        max: 300,
      },
      {
        key: 'closing',
        default: {
          vi: 'Thêm một bước nhỏ, thêm một kỷ niệm lớn.',
          en: 'Another little step, another big memory.',
        },
        max: 60,
      },
    ],
  }),
  video({
    id: 'hundred_days_love',
    composition: 'HundredDaysLove',
    name: { vi: 'Trăm ngày yêu thương', en: '100 days of love' },
    description: {
      vi: 'Kem, đỏ, vàng; hoa đào và dấu triện',
      en: 'Cream, red and gold; blossoms and a seal',
    },
    tier: 'premium',
    order: 380,
    occasions: ['d100'],
    ageDays: { min: 90, max: 130 },
    photos: { min: 8, max: 12 },
    durationSec: 40,
    palettes: [pal('#F8F1E7', '#5A1F1B', '#B23A2E'), pal('#9E2B25', '#FCEFD9', '#E8C77A')],
    scenes: [
      sc('Ngày chào đời', 'The day you were born', [0, 3]),
      sc('Tuần đầu', 'The first week', [4, 10]),
      sc('Ngày 20', 'Day 20', [11, 25], opt),
      sc('Tròn 1 tháng', 'One month', [26, 40]),
      sc('Ngày 50', 'Day 50', [41, 55]),
      sc('Tròn 2 tháng', 'Two months', [56, 70]),
      sc('Ngày 80', 'Day 80', [71, 85]),
      sc('Tròn 3 tháng', 'Three months', [86, 95]),
      sc('Ngày 100', 'Day 100', [96, 115], { occasion: 'd100' }),
      sc('Tiệc 100 ngày', 'The 100-day party', [96, 130], opt),
      sc('Cả nhà chúc mừng', 'Wishes from the family', [96, 130], opt),
      sc('Khoảnh khắc yêu thích', 'A favourite moment', [0, 130], opt),
    ],
    texts: [
      { key: 'title', default: { vi: '100 ngày yêu thương', en: '100 days of love' }, max: 30 },
      {
        key: 'message',
        default: {
          vi: 'Cả nhà chúc con trăm ngày bình an, một đời hạnh phúc.',
          en: 'With love from all of us: a hundred peaceful days and a lifetime of joy.',
        },
        max: 140,
      },
    ],
  }),
  video({
    id: 'half_year',
    composition: 'HalfYear',
    name: { vi: 'Nửa năm bên con', en: 'Half a year with you' },
    description: {
      vi: 'Từng tháng một, như một thước phim',
      en: 'Month by month, like a documentary',
    },
    tier: 'premium',
    order: 390,
    occasions: ['m6'],
    ageDays: { min: 170, max: 220 },
    photos: { min: 8, max: 12 },
    durationSec: 45,
    palettes: [pal('#F1EEE8', '#22262A', '#2F7F90'), pal('#1D1F22', '#EDE7DD', '#E0B15C')],
    scenes: [
      sc('Tháng 1 · Mới chào đời', 'Month 1 · Newborn', [0, 14]),
      sc('Tháng 1', 'Month 1', [15, 29]),
      ...[2, 3, 4, 5].flatMap((k) => [
        sc(`Tháng ${k}`, `Month ${k}`, month(k)),
        sc(`Tháng ${k} · thêm ảnh`, `Month ${k} · one more`, month(k), opt),
      ]),
      sc('Tháng 6', 'Month 6', month(6)),
      sc('Sáu tháng rồi!', 'Six months!', [170, 220], { occasion: 'm6' }),
    ],
    texts: [
      {
        key: 'title',
        default: { vi: 'Sáu tháng yêu con', en: 'Six months of loving you' },
        max: 40,
      },
      {
        key: 'closing',
        default: {
          vi: 'Và hành trình của chúng ta chỉ mới bắt đầu.',
          en: 'And our journey is just beginning.',
        },
        max: 60,
      },
    ],
  }),
  video({
    id: 'letter_to_baby',
    composition: 'LetterToBaby',
    name: { vi: 'Thư gửi con', en: 'A letter to my baby' },
    description: {
      vi: 'Lá thư viết tay, ảnh hiện dần',
      en: 'A handwritten letter with your photos',
    },
    tier: 'premium',
    order: 400,
    occasions: [],
    ageDays: null,
    photos: { min: 5, max: 10 },
    durationSec: 45,
    palettes: [pal('#F5EFE3', '#2E2620', '#9C6B4E'), pal('#EEF1F5', '#22303D', '#4E6F93')],
    scenes: [
      sc('Ngày con đến', 'The day you came', [0, 7]),
      sc('Lần đầu ba mẹ bế con', 'Our first cuddle', [0, 7]),
      sc('Mỗi sáng bên con', 'Mornings with you'),
      sc('Con lớn lên từng ngày', 'Growing day by day'),
      sc('Con hôm nay', 'You, today'),
      ...Array.from({ length: 5 }, () =>
        sc('Khoảnh khắc yêu thích', 'A favourite moment', undefined, opt),
      ),
    ],
    texts: [
      {
        key: 'letter',
        default: {
          vi: 'Con yêu, ba mẹ viết cho con vài dòng để mai sau con đọc. Ngày con đến, ba mẹ đã khóc vì hạnh phúc. Từ đó, mỗi sáng thức dậy đều có lý do để mỉm cười. Con cứ lớn lên thật bình an, ba mẹ sẽ luôn ở đây.',
          en: "Dear little one, we're writing a few lines for you to read one day. The day you arrived, we cried with happiness. Since then, every morning has a reason to smile. Grow up safe and happy — we'll always be right here.",
        },
        max: 400,
      },
      {
        key: 'closing',
        default: { vi: 'Thương con thật nhiều, Ba & Mẹ', en: 'With all our love, Mom & Dad' },
        max: 50,
      },
    ],
  }),
  video({
    id: 'then_and_now',
    composition: 'ThenAndNow',
    name: { vi: 'Ngày ấy – bây giờ', en: 'Then & now' },
    description: {
      vi: 'Trước – sau, gọn và bất ngờ',
      en: 'Before and after, clean and surprising',
    },
    tier: 'free',
    order: 410,
    occasions: [],
    ageDays: { min: 30, max: 420 },
    photos: { min: 2, max: 6 },
    durationSec: 25,
    palettes: [pal('#FAFAF8', '#111111', '#D9653F'), pal('#111111', '#FAFAF8', '#F2CC8F')],
    scenes: [
      sc('Lúc ấy', 'Then', [0, 45]),
      sc('Bây giờ', 'Now'),
      sc('Lúc ấy · ảnh 2', 'Then · photo 2', [0, 90], opt),
      sc('Bây giờ · ảnh 2', 'Now · photo 2', undefined, opt),
      sc('Lúc ấy · ảnh 3', 'Then · photo 3', [0, 90], opt),
      sc('Bây giờ · ảnh 3', 'Now · photo 3', undefined, opt),
    ],
    texts: [
      { key: 'title', default: { vi: 'Lúc ấy…', en: 'Then…' }, max: 20 },
      {
        key: 'closing',
        default: { vi: 'Con đã lớn thật nhiều!', en: 'You’ve grown so much!' },
        max: 40,
      },
    ],
  }),
  video({
    id: 'first_birthday',
    composition: 'FirstBirthday',
    name: { vi: 'Sinh nhật đầu tiên', en: 'My first birthday' },
    description: {
      vi: 'Đếm ngược, bóng bay, cả năm đầu đời',
      en: 'A countdown, balloons and the whole first year',
    },
    tier: 'free',
    order: 420,
    occasions: ['y1'],
    ageDays: { min: 350, max: 400 },
    photos: { min: 10, max: 15 },
    durationSec: 45,
    palettes: [pal('#FFF4E8', '#2F2140', '#E85A80'), pal('#E7F3FF', '#172A46', '#2F6FE8')],
    scenes: [
      ...months([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], [7, 9, 11]),
      sc('Sinh nhật 1 tuổi', 'The first birthday', [350, 400], { occasion: 'y1' }),
      sc('Bánh sinh nhật', 'The birthday cake', [350, 400], opt),
      sc('Cả nhà mừng con', 'The family celebrates', [350, 400], opt),
    ],
    texts: [
      { key: 'headline', default: { vi: '1 tuổi', en: 'ONE' }, max: 10 },
      {
        key: 'title',
        default: { vi: 'Một năm đầu tiên của {name}', en: "{name}'s first year" },
        max: 40,
      },
      {
        key: 'closing',
        default: { vi: 'Chúc mừng sinh nhật đầu tiên, {name}!', en: 'Happy 1st birthday, {name}!' },
        max: 50,
      },
    ],
  }),
];
