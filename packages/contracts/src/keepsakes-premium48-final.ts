/** Premium 48, phases 7–12. Authored VI/EN stories; no inferred people, dates or milestones. */
import {
  keepsakeTemplateSchema,
  defaultKeepsakeVideoBrand,
  type KeepsakeLayer,
  type KeepsakeTemplate,
  type KeepsakeComposition,
} from './keepsakes.js';
import {
  keepsakePersonalizationSchema,
  type KeepsakePersonalization,
} from './keepsake-personalization.js';
const l = (vi: string, en: string) => ({ vi, en });
export const premium48FinalDesigns = [
  {
    n: 13,
    part: 'held',
    title: l('Trong vòng tay yêu thương', 'Held With Love'),
    group: l('Gia đình', 'You & Your People'),
    palette: ['#F5E8E1', '#704C53', '#AC7869'],
    composition: 'PremiumHeldWithLove',
    card: 2,
    video: 5,
    bpm: 66,
    music: l('Vòng ôm dịu dàng', 'A Gentle Embrace'),
    baby: 'Henry',
  },
  {
    n: 14,
    part: 'generations',
    title: l('Con và ông bà', 'Across Generations'),
    group: l('Gia đình', 'You & Your People'),
    palette: ['#F2E5CF', '#625A42', '#AA705D'],
    composition: 'PremiumAcrossGenerations',
    card: 2,
    video: 5,
    bpm: 70,
    music: l('Nối những mùa thương', 'Love Across Seasons'),
    baby: 'Grace',
  },
  {
    n: 15,
    part: 'circle',
    title: l('Những người thương con', 'Your Circle of Love'),
    group: l('Gia đình', 'You & Your People'),
    palette: ['#FBF3E4', '#596348', '#D8A38C'],
    composition: 'PremiumCircleOfLove',
    card: 4,
    video: 4,
    bpm: 86,
    music: l('Quanh con là thương', 'All Around You'),
    baby: 'Jack',
  },
  {
    n: 16,
    part: 'day',
    title: l('Một ngày bên con', 'A Day With You'),
    group: l('Ngày thường', 'Everyday Magic'),
    palette: ['#FCF6E8', '#4D5D63', '#C5A05C'],
    composition: 'PremiumDayWithYou',
    card: 4,
    video: 4,
    bpm: 80,
    music: l('Nhịp ngày bình thường', 'An Ordinary Rhythm'),
    baby: 'Isla',
  },
  {
    n: 17,
    part: 'details',
    title: l('Bé xíu trong bàn tay', 'The Tiniest Details'),
    group: l('Ngày thường', 'Everyday Magic'),
    palette: ['#FAF6F0', '#66554B', '#B4AAA0'],
    composition: 'PremiumTiniestDetails',
    card: 3,
    video: 4,
    bpm: 60,
    music: l('Nhìn gần thêm chút', 'A Little Closer'),
    baby: 'Leo',
  },
  {
    n: 18,
    part: 'sleep',
    title: l('Ngủ ngoan nhé, con', 'Sleep Softly, Little One'),
    group: l('Ngày thường', 'Everyday Magic'),
    palette: ['#343C52', '#EEE4C9', '#9E91A0'],
    composition: 'PremiumSleepSoftly',
    card: 1,
    video: 4,
    bpm: 58,
    music: l('Giữ một tối yên', 'Keeping the Quiet'),
    baby: 'Sophie',
  },
  {
    n: 19,
    part: 'hundred',
    title: l('Một trăm ngày bên con', 'One Hundred Days With You'),
    group: l('Dịp đặc biệt', 'Days to Celebrate'),
    palette: ['#FFF5E8', '#903E30', '#BEA06C'],
    composition: 'PremiumHundredDays',
    card: 3,
    video: 5,
    bpm: 88,
    music: l('Trăm ngày thương nhớ', 'A Hundred Little Days'),
    baby: 'Lucas',
  },
  {
    n: 20,
    part: 'celebrate',
    title: l('Dịp lễ đầu tiên của con', 'Your First Celebration'),
    group: l('Dịp đặc biệt', 'Days to Celebrate'),
    palette: ['#FFF6E8', '#75522E', '#BE9657'],
    composition: 'PremiumFirstCelebration',
    card: 3,
    video: 5,
    bpm: 88,
    music: l('Ngày vui có con', 'Celebrating With You'),
    baby: 'Chloe',
  },
  {
    n: 21,
    part: 'adventure',
    title: l('Chuyến đi đầu tiên', 'Our First Little Adventure'),
    group: l('Dịp đặc biệt', 'Days to Celebrate'),
    palette: ['#F3E9D4', '#43696A', '#BC7C63'],
    composition: 'PremiumLittleAdventure',
    card: 3,
    video: 5,
    bpm: 96,
    music: l('Cùng con đi xa', 'A Little Further'),
    baby: 'Theo',
  },
  {
    n: 22,
    part: 'months',
    title: l('Mười hai tháng lớn lên', 'Twelve Months of You'),
    group: l('Một năm', 'A Year of You'),
    palette: ['#FCF5E8', '#415D80', '#D7A17C'],
    composition: 'PremiumTwelveMonths',
    card: 12,
    video: 12,
    bpm: 84,
    music: l('Mười hai trang yêu', 'Twelve Little Chapters'),
    baby: 'Alice',
  },
  {
    n: 23,
    part: 'birthday',
    title: l('Lá thư sinh nhật đầu tiên', 'A Letter on Your First Birthday'),
    group: l('Một năm', 'A Year of You'),
    palette: ['#FCF2E5', '#75424D', '#B89B67'],
    composition: 'PremiumBirthdayLetter',
    card: 1,
    video: 5,
    bpm: 68,
    music: l('Thư ngày một tuổi', 'A Birthday Letter'),
    baby: 'Oscar',
  },
  {
    n: 24,
    part: 'familyyear',
    title: l('Nhà mình sau một năm', 'Our Family, One Year Later'),
    group: l('Một năm', 'A Year of You'),
    palette: ['#EFE6D8', '#455B47', '#C48C70'],
    composition: 'PremiumFamilyYear',
    card: 3,
    video: 5,
    bpm: 78,
    music: l('Một năm cùng lớn', 'Our Year Together'),
    baby: 'Ruby',
  },
] as const;
export type Premium48FinalDesign = (typeof premium48FinalDesigns)[number];
type Field = KeepsakePersonalization['fields'][number];
const field = (key: string, vi: string, en: string, max = 40): Field => ({
  key,
  label: l(vi, en),
  type: 'text',
  max,
  required: false,
});
const confirm = (key: string, vi: string, en: string): Field => ({
  ...field(key, vi, en, 5),
  type: 'confirmation',
});
const name: Field = {
  ...field('babyName', 'Tên bé', 'Baby’s name', 30),
  source: 'babyName',
  required: true,
};
const date: Field = {
  ...field('momentDate', 'Ngày ghi nhận (nếu biết)', 'Date captured (if known)', 10),
  type: 'date',
};
const copy = (
  key: string,
  vi: string,
  en: string,
  requires: string[] = [],
  fallback = l('', ''),
  editable = true,
) => ({
  key,
  label: /^scene\d+$/.test(key)
    ? l(`Cảnh ${key.slice(5)}`, `Scene ${key.slice(5)}`)
    : ({
        title: l('Tiêu đề', 'Title'),
        message: l('Lời nhắn', 'Message'),
        detail0: l('Câu kết', 'Closing line'),
        detail1: l('Chữ ký', 'Signed by'),
      }[key] ?? l('Nhãn', 'Label')),
  text: l(vi, en),
  requires,
  fallback,
  editable,
  max: 160,
});
const title = (vi: string, en: string, requires: string[] = [], fallback = l('', '')) =>
  copy('title', vi, en, requires, fallback);
const message = (vi: string, en: string, requires: string[] = [], fallback = l('', '')) =>
  copy('message', vi, en, requires, fallback);
const detail = (vi: string, en: string, requires: string[] = [], fallback = l('', '')) =>
  copy('detail0', vi, en, requires, fallback);
const scene = (i: number, vi: string, en: string, requires: string[] = [], fallback = l('', '')) =>
  copy(`scene${i}`, vi, en, requires, fallback);
function content(n: number, video: boolean): { fields: Field[]; copy: ReturnType<typeof copy>[] } {
  const fields: Field[] = [name, date];
  const texts: ReturnType<typeof copy>[] = [];
  const add = (f: Field) => fields.push(f);
  if (n === 13) {
    add(
      field(
        'narratorName',
        'Tên người trong ảnh (tùy chọn)',
        'Name of the person pictured (optional)',
        30,
      ),
    );
    add(confirm('cuddleConfirmed', 'Ảnh ghi lại cái ôm', 'The photos show cuddles'));
    add(confirm('sleepConfirmed', 'Ảnh thứ ba ghi lại bé ngủ', 'Photo three shows baby sleeping'));
    texts.push(
      ...(video
        ? [
            scene(1, 'Con ở đây.', 'Here you are.'),
            scene(
              2,
              'Trong vòng tay {narratorName}.',
              'In {narratorName}’s arms.',
              ['narratorName', 'cuddleConfirmed'],
              l('Những vòng tay thương con.', 'Held with love.'),
            ),
            scene(
              3,
              'Có lúc là một giấc ngủ.',
              'Sometimes, drifting off to sleep.',
              ['sleepConfirmed'],
              l('Có lúc chỉ là một khoảng lặng.', 'Sometimes, a quiet little pause.'),
            ),
            scene(4, 'Có lúc chỉ là ngồi bên nhau.', 'Sometimes, simply being together.'),
            scene(
              5,
              'Những cái ôm làm nên nhà mình.',
              'The cuddles that make us family.',
              ['cuddleConfirmed'],
              l('Những khoảnh khắc làm nên nhà mình.', 'The moments that make us family.'),
            ),
          ]
        : [
            title(
              'Con và {narratorName}.',
              'You and {narratorName}.',
              ['narratorName'],
              l('Những vòng tay thương con.', 'Held with love.'),
            ),
            message(
              'Có những cái ôm chẳng cần lời.',
              'Some cuddles need no words.',
              ['cuddleConfirmed'],
              l('Có những yêu thương chẳng cần lời.', 'Some kinds of love need no words.'),
            ),
            detail('Một góc bình yên của nhà mình.', 'A little place of comfort, together.'),
          ]),
    );
  } else if (n === 14) {
    add(field('relativeName', 'Tên người thân (tùy chọn)', 'Relative’s name (optional)', 30));
    add(
      confirm('handsConfirmed', 'Ảnh cận ghi lại hai bàn tay', 'The detail photo shows both hands'),
    );
    add(
      confirm(
        'heldConfirmed',
        'Ảnh thứ hai là người thân bế bé',
        'Photo two shows your relative holding baby',
      ),
    );
    add(
      confirm(
        'meetingConfirmed',
        'Đây là ngày gặp nhau đã xác nhận',
        'This is a confirmed meeting day',
      ),
    );
    texts.push(
      ...(video
        ? [
            scene(
              1,
              'Có những người đã chờ được gặp con.',
              'Someone had been waiting to meet you.',
              ['meetingConfirmed'],
              l('Có những người thương con thật nhiều.', 'Someone who holds you dear.'),
            ),
            scene(
              2,
              'Hôm nay, con ở trong vòng tay ấy.',
              'Today, you were finally in those arms.',
              ['heldConfirmed', 'meetingConfirmed'],
              l('Một khoảnh khắc gần nhau.', 'A little moment together.'),
            ),
            scene(
              3,
              'Một bàn tay nhỏ, một bàn tay thân quen.',
              'A tiny hand, held by a familiar one.',
              ['handsConfirmed'],
              l('Một chi tiết nhỏ để giữ lại.', 'A little detail to keep.'),
            ),
            scene(4, 'Những câu chuyện mới bắt đầu nối tiếp.', 'New stories joining the old.'),
            scene(
              5,
              'Con và {relativeName}.',
              'You and {relativeName}.',
              ['relativeName'],
              l('Những kỷ niệm nối tiếp.', 'Memories across generations.'),
            ),
          ]
        : [
            title(
              '{babyName} và {relativeName}.',
              '{babyName} and {relativeName}.',
              ['relativeName'],
              l('Những thế hệ bên con.', 'Across generations, with you.'),
            ),
            message(
              'Một bàn tay nhỏ trong một bàn tay thân thương.',
              'A little hand, held by someone dear.',
              ['handsConfirmed'],
              l('Một khoảnh khắc nhỏ bên người thân thương.', 'A little moment with someone dear.'),
            ),
            detail(
              'Thêm một thế hệ, thêm những ngày bên nhau.',
              'Another generation. New memories together.',
            ),
          ]),
    );
  } else if (n === 15) {
    add(field('familyLabel', 'Tên gia đình (tùy chọn)', 'Family label (optional)', 30));
    add(
      confirm(
        'holdingConfirmed',
        'Ảnh thứ hai ghi lại người ôm bé',
        'Photo two shows someone holding baby',
      ),
    );
    add(
      confirm(
        'playingConfirmed',
        'Ảnh thứ ba ghi lại chơi cùng bé',
        'Photo three shows someone playing with baby',
      ),
    );
    texts.push(
      ...(video
        ? [
            scene(
              1,
              'Thế giới của con bắt đầu từ những gương mặt này.',
              'Your world began with these faces.',
            ),
            scene(
              2,
              'Người ôm con.',
              'Someone to hold you.',
              ['holdingConfirmed'],
              l('Một người thương con.', 'Someone who loves you.'),
            ),
            scene(
              3,
              'Người chơi cùng con.',
              'Someone to play with you.',
              ['playingConfirmed'],
              l('Thêm một khoảnh khắc gần nhau.', 'Another moment together.'),
            ),
            scene(
              4,
              'Người ở bên trong những ngày thường.',
              'Someone there for the everyday moments.',
            ),
            scene(
              5,
              'Bao nhiêu cách để thương một người bé xíu.',
              'So many ways to love someone so small.',
            ),
          ]
        : [
            title('Quanh con là những người thương.', 'Your circle of love.'),
            message(
              'Mỗi người một cách, cùng có mặt bên con.',
              'Different people. Their own ways of showing up.',
            ),
            detail('{familyLabel}', '{familyLabel}', ['familyLabel'], l('Nhà mình', 'Our family')),
          ]),
    );
  } else if (n === 16) {
    add(
      confirm(
        'sameDayConfirmed',
        'Ảnh cùng một ngày và đúng thứ tự sáng–tối',
        'Photos are from one day, in morning-to-evening order',
      ),
    );
    add(
      confirm(
        'routineConfirmed',
        'Ảnh có cảnh ăn, chơi và nghỉ',
        'Photos show feeding, playing and rest',
      ),
    );
    texts.push(
      ...(video
        ? [
            scene(
              1,
              'Buổi sáng, mình gặp nhau bằng một cái nhìn.',
              'Morning began with a little look.',
              ['sameDayConfirmed'],
              l('Mình gặp nhau bằng một cái nhìn.', 'A little look, together.'),
            ),
            scene(
              2,
              'Ngày trôi qua trong những việc nhỏ.',
              'The day unfolded in small moments.',
              ['sameDayConfirmed'],
              l('Những ngày trôi qua trong việc nhỏ.', 'Our days, unfolding in small moments.'),
            ),
            scene(
              3,
              'Ăn. Chơi. Rồi nghỉ một chút.',
              'Feeding. Playing. A little rest.',
              ['routineConfirmed'],
              l('Thêm một khoảnh khắc rất thường.', 'Another ordinary little moment.'),
            ),
            scene(
              4,
              'Đến tối, lại gần nhau hơn.',
              'By evening, close together again.',
              ['sameDayConfirmed'],
              l('Lại thêm những phút gần nhau.', 'More little moments together.'),
            ),
            scene(
              5,
              'Một ngày bình thường mình muốn nhớ.',
              'An ordinary day worth remembering.',
              ['sameDayConfirmed'],
              l('Những ngày bên con, mình muốn nhớ.', 'Days with you, worth remembering.'),
            ),
          ]
        : [
            title(
              'Một ngày rất thường, có con.',
              'An ordinary day, with you.',
              ['sameDayConfirmed'],
              l('Những ngày bên con.', 'Days with you.'),
            ),
            message(
              'Ăn một chút. Ngủ một chút. Ôm thêm một chút.',
              'A little feeding. A little sleeping. One more cuddle.',
              ['routineConfirmed'],
              l('Những việc nhỏ. Những phút gần nhau.', 'Small moments. A little time together.'),
            ),
            detail('Những ngày này cũng đáng giữ.', 'These days are worth keeping, too.'),
          ]),
    );
  } else if (n === 17) {
    add(confirm('handsConfirmed', 'Ảnh thứ hai là bàn tay bé', 'Photo two shows baby’s hands'));
    add(
      confirm(
        'feetConfirmed',
        'Ảnh thứ ba là bàn chân bé trong tay',
        'Photo three shows baby’s feet held in a hand',
      ),
    );
    texts.push(
      ...(video
        ? [
            scene(1, 'Nhìn gần thêm một chút…', 'A little closer…'),
            scene(
              2,
              'Những ngón tay bé xíu.',
              'The tiniest fingers.',
              ['handsConfirmed'],
              l('Một chi tiết thật bé.', 'One tiny detail.'),
            ),
            scene(
              3,
              'Bàn chân nằm gọn trong tay.',
              'Little feet, held in a hand.',
              ['feetConfirmed'],
              l('Thêm một góc nhìn thật gần.', 'Another close little look.'),
            ),
            scene(4, 'Có những điều thay đổi thật khẽ.', 'Some things change so quietly.'),
            scene(5, 'Hôm nay, mình giữ lại từng chi tiết.', 'Today, we are keeping every detail.'),
          ]
        : [
            title('Những điều bé xíu của con.', 'The tiniest details of you.'),
            message(
              'Bàn tay này. Bàn chân này. Ngày hôm nay.',
              'These hands. These feet. This very day.',
              ['handsConfirmed', 'feetConfirmed'],
              l('Những chi tiết nhỏ, ngay lúc này.', 'Little details, just as they are now.'),
            ),
            detail(
              'Muốn nhớ thật rõ, trước khi con lớn thêm.',
              'Remembering them, just as they are now.',
            ),
          ]),
    );
  } else if (n === 18) {
    add(confirm('sleepConfirmed', 'Ảnh có bé đang ngủ', 'The selected photos show baby sleeping'));
    texts.push(
      ...(video
        ? [
            scene(1, 'Ngày dài đang khép lại.', 'The day is coming to a close.'),
            scene(2, 'Những tiếng động cũng dịu hơn.', 'The sounds around us soften.'),
            scene(
              3,
              'Con nghỉ ngơi, nhà mình chậm lại.',
              'You rest, and we slow down.',
              ['sleepConfirmed'],
              l('Ở bên con, mình chậm lại.', 'With you, we slow down.'),
            ),
            scene(4, 'Giữ một chút bình yên của tối nay.', 'Keeping a little of tonight’s quiet.'),
            scene(
              5,
              'Ngủ ngoan nhé, con.',
              'Sleep softly, little one.',
              ['sleepConfirmed'],
              l('Chúc nhà mình một đêm yên.', 'Wishing us a peaceful night.'),
            ),
          ]
        : [
            title(
              'Ngủ ngoan nhé, {babyName}.',
              'Sleep softly, {babyName}.',
              ['sleepConfirmed'],
              l('Một tối bình yên.', 'A quiet evening.'),
            ),
            message('Ngày hôm nay, mình để dành ở đây.', 'Keeping a little of today, right here.'),
            detail('Mai lại cùng nhau khám phá tiếp.', 'More to discover together tomorrow.'),
          ]),
    );
  } else if (n === 19) {
    add(
      confirm(
        'hundredConfirmed',
        'Tôi chọn kỷ niệm mốc 100 ngày',
        'I choose to mark one hundred days',
      ),
    );
    add(
      confirm(
        'firstDayConfirmed',
        'Ảnh đầu là ngày chào đời đã xác nhận',
        'Photo one is the confirmed first day',
      ),
    );
    texts.push(copy('hundredMark', '100', '100', ['hundredConfirmed'], l('', ''), false));
    texts.push(
      ...(video
        ? [
            scene(
              1,
              'Ngày đầu tiên…',
              'The very first day…',
              ['firstDayConfirmed'],
              l('Từ một kỷ niệm nhỏ…', 'From one little memory…'),
            ),
            scene(2, 'Rồi từng ngày, mình hiểu nhau hơn.', 'Then, day by day, we got to know you.'),
            scene(3, 'Những thay đổi nhỏ cứ nối tiếp.', 'Little changes kept unfolding.'),
            scene(
              4,
              'Hôm nay, tròn một trăm ngày.',
              'Today marks one hundred days.',
              ['hundredConfirmed'],
              l('Giữ lại những ngày bên con.', 'Keeping these days with you.'),
            ),
            scene(5, 'Cảm ơn con vì những ngày bên nhau.', 'Thank you for these days together.'),
          ]
        : [
            title(
              '100 ngày bên {babyName}.',
              '100 days with {babyName}.',
              ['hundredConfirmed'],
              l('Những ngày bên con.', 'These days with you.'),
            ),
            message(
              'Từ cái ôm đầu tiên đến hôm nay.',
              'From that first embrace to today.',
              ['firstDayConfirmed'],
              l('Từ những phút gần nhau đến hôm nay.', 'From little moments together to today.'),
            ),
            detail(
              'Một trăm ngày, biết bao điều để nhớ.',
              'One hundred days. So much to remember.',
              ['hundredConfirmed'],
              l('Những ngày bên nhau, bao điều để nhớ.', 'Days together. So much to remember.'),
            ),
          ]),
    );
  } else if (n === 20) {
    add({
      ...field('occasionName', 'Tên dịp lễ', 'Celebration name', 32),
      required: true,
      suggestion: l('ngày vui của nhà mình', 'our family celebration'),
    });
    add({
      ...field('celebrationTheme', 'Bộ trang trí', 'Decoration theme', 12),
      required: true,
      options: [
        { value: 'neutral', label: l('Trung tính · cờ vải', 'Neutral · fabric bunting') },
        { value: 'tet', label: l('Tết · hoa và phong bao', 'Lunar New Year · blossom & envelope') },
        {
          value: 'christmas',
          label: l('Christmas · thông và sao', 'Christmas · pine & paper star'),
        },
      ],
    });
    add(
      confirm(
        'firstConfirmed',
        'Đây là lần đầu bé đón dịp này',
        'This is baby’s first time celebrating this occasion',
      ),
    );
    texts.push(copy('theme', '{celebrationTheme}', '{celebrationTheme}', [], l('', ''), false));
    texts.push(
      ...(video
        ? [
            scene(1, 'Lại đến {occasionName}.', 'It is time for {occasionName}.'),
            scene(2, 'Những điều thân quen vẫn ở đây.', 'The familiar little traditions are here.'),
            scene(3, 'Chỉ có một điều thật mới…', 'With one wonderful difference…'),
            scene(4, 'Năm nay, mình có con cùng đón.', 'This time, you are here with us.'),
            scene(
              5,
              'Dịp lễ đầu tiên của {babyName}.',
              '{babyName}’s first celebration.',
              ['firstConfirmed'],
              l('Một dịp vui có con cùng đón.', 'A celebration, with you.'),
            ),
          ]
        : [
            title(
              '{occasionName} đầu tiên của {babyName}.',
              '{babyName}’s first {occasionName}.',
              ['firstConfirmed'],
              l('{occasionName}, có con cùng đón.', '{occasionName}, with you.'),
            ),
            message(
              'Năm nay, ngày quen có thêm một gương mặt mới.',
              'A familiar celebration, with someone new.',
            ),
            detail('Kỷ niệm của nhà mình.', 'A family memory.'),
          ]),
    );
  } else if (n === 21) {
    add(field('placeName', 'Nơi đến (tùy chọn)', 'Place visited (optional)', 32));
    add(
      confirm(
        'firstConfirmed',
        'Đây là chuyến đầu đến nơi này cùng bé',
        'This is your first trip here together',
      ),
    );
    texts.push(
      ...(video
        ? [
            scene(1, 'Hôm nay, mình đi một chút xa hơn.', 'Today, we went a little further.'),
            scene(2, 'Những khung hình trên đường đi…', 'Little moments along the way…'),
            scene(
              3,
              'Và một người bạn đồng hành rất nhỏ.',
              'And brought a very little travel companion.',
            ),
            scene(
              4,
              '{placeName}, lần đầu có con cùng đến.',
              '{placeName}, our first visit with you.',
              ['placeName', 'firstConfirmed'],
              l('Một nơi mới, có con cùng đến.', 'Somewhere new, together with you.'),
            ),
            scene(5, 'Chuyến đi này, mình giữ lại.', 'A journey we will keep.'),
          ]
        : [
            title(
              'Chuyến đi đầu tiên đến {placeName}.',
              'Our first trip to {placeName}.',
              ['placeName', 'firstConfirmed'],
              l('Một chuyến đi bên con.', 'An adventure with you.'),
            ),
            message(
              'Mang theo một người nhỏ, thêm thật nhiều kỷ niệm.',
              'One little traveller. So many new memories.',
            ),
            detail('Nhà mình cùng đi.', 'Together, on the way.'),
          ]),
    );
  } else if (n === 22) {
    add(
      confirm(
        'monthsConfirmed',
        'Tôi đã đặt đủ 12 ảnh theo đúng tháng 1–12',
        'I placed all twelve photos in month 1–12 order',
      ),
    );
    texts.push(
      copy('monthLabels', 'true', 'true', ['monthsConfirmed'], l('false', 'false'), false),
    );
    if (!video)
      for (let i = 0; i < 12; i++)
        texts.push(
          copy(
            `photoLabel${i}`,
            String(i + 1).padStart(2, '0'),
            String(i + 1).padStart(2, '0'),
            ['monthsConfirmed'],
            l('', ''),
            false,
          ),
        );
    texts.push(
      ...(video
        ? [
            scene(
              1,
              'Tháng 1–3: Làm quen với thế giới.',
              'Months 1–3: Getting to know the world.',
              ['monthsConfirmed'],
              l('Những khung hình mở đầu.', 'Our opening photographs.'),
            ),
            scene(
              2,
              'Tháng 4–6: Những điều mới mỗi ngày.',
              'Months 4–6: Something new each day.',
              ['monthsConfirmed'],
              l('Những điều mới mỗi ngày.', 'Something new each day.'),
            ),
            scene(
              3,
              'Tháng 7–9: Thêm bao điều để khám phá.',
              'Months 7–9: So much to explore.',
              ['monthsConfirmed'],
              l('Thêm bao điều để khám phá.', 'So much to explore.'),
            ),
            scene(
              4,
              'Tháng 10–12: Con của hôm nay.',
              'Months 10–12: You, as you are today.',
              ['monthsConfirmed'],
              l('Những khoảnh khắc để giữ lại.', 'Little moments to keep.'),
            ),
            scene(
              5,
              'Mười hai tháng. Một câu chuyện rất riêng.',
              'Twelve months. A story all your own.',
              ['monthsConfirmed'],
              l(
                'Những tháng bên con. Một câu chuyện riêng.',
                'Months with you. A story all your own.',
              ),
            ),
          ]
        : [
            title(
              'Mười hai tháng của {babyName}.',
              'Twelve months of {babyName}.',
              ['monthsConfirmed'],
              l('Những tháng bên con.', 'Months with you.'),
            ),
            message(
              'Mỗi ô ảnh là một đoạn đường bên nhau.',
              'Every picture, a little part of our journey.',
            ),
            detail(
              'Một năm đầu đời, giữ lại bằng yêu thương.',
              'One first year, kept with love.',
              ['monthsConfirmed'],
              l(
                'Những tháng bên nhau, giữ lại bằng yêu thương.',
                'Our months together, kept with love.',
              ),
            ),
          ]),
    );
  } else if (n === 23) {
    add(field('narratorName', 'Chữ ký (tùy chọn)', 'Signed by (optional)', 30));
    if (video)
      add(
        confirm(
          'yearOrderConfirmed',
          'Ảnh thứ hai là đầu năm, thứ ba là giữa năm',
          'Photo two is from early in the year; photo three is from midyear',
        ),
      );
    texts.push(
      ...(video
        ? [
            scene(1, 'Gửi con, ngày tròn một tuổi.', 'Dear little one, on your first birthday.'),
            scene(
              2,
              'Một năm qua, nhà mình đã thay đổi nhiều.',
              'This year has changed so much for us.',
              ['yearOrderConfirmed'],
              l('Những khung hình dành cho ngày của con.', 'Photographs for your special day.'),
            ),
            scene(
              3,
              'Có những điều chỉ khi bên con mới biết.',
              'You have taught us things we never knew.',
            ),
            scene(
              4,
              'Điều muốn giữ lại không chỉ là ảnh…',
              'We are keeping more than photographs…',
            ),
            scene(
              5,
              'Mà là cảm giác được cùng con lớn lên.',
              'We are keeping the feeling of growing with you.',
            ),
          ]
        : [
            title('Gửi {babyName}, một tuổi.', 'Dear {babyName}, on your first birthday.'),
            message(
              'Không nhớ hết từng ngày, nhưng nhớ rất rõ niềm vui có con bên mình.',
              'We cannot remember every day, but we remember the joy of having you here.',
            ),
            detail(
              'Mong con luôn có người lắng nghe và một nơi để trở về.',
              'May you always have someone who listens, and a place to come home to.',
            ),
            copy(
              'detail1',
              'Thương con, {narratorName}.',
              'With love, {narratorName}.',
              ['narratorName'],
              l('Thương con, nhà mình.', 'With love, your family.'),
            ),
          ]),
    );
  } else {
    add(
      confirm(
        'familyStartConfirmed',
        'Ảnh đầu là ảnh gia đình đầu năm',
        'Photo one is your family at the start of the year',
      ),
    );
    texts.push(
      ...(video
        ? [
            scene(
              1,
              'Một năm trước, nhà mình bắt đầu chương mới.',
              'A year ago, a new chapter began.',
              ['familyStartConfirmed'],
              l('Một năm trước, con bắt đầu hành trình.', 'A year ago, your story began.'),
            ),
            scene(
              2,
              'Có những ngày vui, những ngày mệt.',
              'There were joyful days, and tiring ones.',
            ),
            scene(3, 'Có những người luôn có mặt.', 'And people who kept showing up.'),
            scene(
              4,
              'Con lớn lên giữa những điều bình thường ấy.',
              'You grew among those everyday moments.',
            ),
            scene(
              5,
              'Một năm của con. Một năm của nhà mình.',
              'Your first year. Our year together.',
            ),
          ]
        : [
            title('Con lớn một tuổi. Nhà mình cũng lớn lên.', 'You grew a year. We grew together.'),
            message(
              'Một năm học cách ở bên nhau.',
              'A year of learning to be there for each other.',
            ),
            detail(
              'Cảm ơn những người đã cùng chăm con, theo cách của mình.',
              'For everyone who helped care for you, in their own way: thank you.',
            ),
          ]),
    );
  }
  texts.push(copy('signature', '{babyName}', '{babyName}', [], l('', ''), false));
  texts.push(copy('label1', '{momentDate}', '{momentDate}', ['momentDate'], l('', ''), false));
  if (video)
    texts.push(
      title(premium48FinalDesigns[n - 13]!.title.vi, premium48FinalDesigns[n - 13]!.title.en),
    );
  return { fields, copy: texts };
}
const rect = (v: number[]) => ({ x: v[0]!, y: v[1]!, w: v[2]!, h: v[3]! });
const text = (
  field: string,
  r: number[],
  size: number,
  lines = 2,
  serif = false,
): KeepsakeLayer => ({
  type: 'text',
  field: field as 'title',
  rect: rect(r),
  size,
  maxLines: lines,
  font: serif ? 'lora' : 'beVietnamPro',
  weight: serif ? 600 : 400,
  color: 'ink',
  opacity: 1,
  align: 'left',
  italic: false,
});
const photo = (slot: number, r: number[], circle = false): KeepsakeLayer => ({
  type: 'photo',
  slot,
  rect: rect(r),
  shape: circle ? 'circle' : 'rect',
  radius: 0.012,
  rotate: 0,
});
export function premium48FinalPhase(
  phase: number,
  assets: Record<string, string> = {},
  music: Record<string, string> = {},
): KeepsakeTemplate[] {
  if (!Number.isInteger(phase) || phase < 7 || phase > 12) throw new Error('premium-phase');
  const designs = premium48FinalDesigns.filter((d) => Math.ceil(d.n / 2) === phase);
  const out: KeepsakeTemplate[] = [];
  for (const d of designs) {
    const art = (
      suffix: string,
      r: number[],
      opacity = 1,
      when?: { field: string; equals: string },
    ): KeepsakeLayer[] => {
      const asset = assets[`p48-${d.part}-${suffix}`];
      return asset
        ? [
            {
              type: 'image',
              asset,
              rect: rect(r),
              fit: 'fill',
              opacity,
              rotate: 0,
              ...(when ? { when } : {}),
            },
          ]
        : [];
    };
    const layouts = (s: boolean): KeepsakeLayer[] => {
      const header = text(
        'title',
        [0.07, s ? 0.083 : 0.064, 0.86, s ? 0.112 : 0.145],
        d.n === 23 ? 0.052 : 0.058,
        3,
        true,
      );
      const brand: KeepsakeLayer = {
        type: 'brand',
        kind: 'lockup',
        rect: rect([0.07, 0.947, 0.22, s ? 0.018 : 0.025]),
        color: 'ink',
        opacity: 0.65,
      };
      const pics: KeepsakeLayer[] = [],
        extra: KeepsakeLayer[] = [];
      const frame = (slot: number, r: number[], circle = false) => {
        pics.push(
          photo(slot, r, circle),
          ...(d.n === 22
            ? []
            : art(circle ? 'oval' : 'frame', [
                r[0]! - 0.008,
                r[1]! - 0.006,
                r[2]! + 0.016,
                r[3]! + 0.012,
              ])),
        );
      };
      if (d.n === 13) {
        frame(0, [0.075, s ? 0.255 : 0.26, 0.53, s ? 0.31 : 0.42], true);
        frame(1, [0.65, s ? 0.39 : 0.46, 0.275, s ? 0.19 : 0.245], true);
        extra.push(...art('embrace', [0.08, s ? 0.61 : 0.715, 0.82, 0.045]));
      }
      if (d.n === 14) {
        frame(0, [0.07, 0.26, 0.55, s ? 0.305 : 0.405]);
        frame(1, [0.65, 0.42, 0.28, s ? 0.2 : 0.25]);
        extra.push(...art('branch', [0.07, s ? 0.61 : 0.69, 0.83, 0.06]));
      }
      if (d.n === 15) {
        frame(0, [0.32, 0.29, 0.36, s ? 0.203 : 0.288], true);
        frame(1, [0.07, 0.25, 0.21, s ? 0.118 : 0.168], true);
        frame(2, [0.72, 0.39, 0.21, s ? 0.118 : 0.168], true);
        frame(3, [0.09, 0.52, 0.25, s ? 0.14 : 0.2], true);
        extra.push(...art('orbit', [0.06, 0.23, 0.88, s ? 0.46 : 0.51], 0.5));
      }
      if (d.n === 16) {
        for (let i = 0; i < 4; i++)
          frame(i, [
            0.07 + (i % 2) * 0.445,
            0.275 + Math.floor(i / 2) * (s ? 0.22 : 0.235),
            0.415,
            s ? 0.195 : 0.21,
          ]);
      }
      if (d.n === 17) {
        frame(0, [0.07, 0.27, 0.55, s ? 0.35 : 0.43]);
        frame(1, [0.66, 0.27, 0.27, s ? 0.16 : 0.2]);
        frame(2, [0.66, s ? 0.46 : 0.5, 0.27, s ? 0.16 : 0.2]);
      }
      if (d.n === 18) {
        frame(0, [0.2, 0.28, 0.6, s ? 0.338 : 0.48], true);
        extra.push(...art('moon', [0.77, 0.19, 0.13, s ? 0.075 : 0.1]));
      }
      if ([19, 20, 21].includes(d.n)) {
        frame(0, [0.07, 0.27, 0.86, s ? 0.29 : 0.34]);
        frame(1, [0.07, s ? 0.59 : 0.64, 0.405, s ? 0.155 : 0.17]);
        frame(2, [0.525, s ? 0.59 : 0.64, 0.405, s ? 0.155 : 0.17]);
      }
      if (d.n === 19)
        extra.push(
          ...art('numeral', [0.75, 0.17, 0.18, s ? 0.062 : 0.08], 1, {
            field: 'hundredMark',
            equals: '100',
          }),
        );
      if (d.n === 20)
        for (const theme of ['neutral', 'tet', 'christmas'])
          extra.push(
            ...art(`${theme}-corner`, [0.8, 0.17, 0.14, s ? 0.08 : 0.1], 1, {
              field: 'theme',
              equals: theme,
            }),
            ...art(`${theme}-ribbon`, [0.07, 0.235, 0.86, 0.02], 1, {
              field: 'theme',
              equals: theme,
            }),
          );
      if (d.n === 21) extra.push(...art('route', [0.07, 0.22, 0.86, 0.035]));
      if (d.n === 22) {
        for (let i = 0; i < 12; i++) {
          const x = 0.07 + (i % 3) * 0.295,
            y = 0.265 + Math.floor(i / 3) * (s ? 0.125 : 0.132);
          frame(i, [x, y, 0.27, s ? 0.102 : 0.106]);
          extra.push(text(`photoLabel${i}`, [x, y + (s ? 0.103 : 0.108), 0.27, 0.02], 0.019, 1));
        }
      }
      if (d.n === 23) {
        frame(0, [0.69, 0.27, 0.24, s ? 0.16 : 0.2]);
        extra.push(
          ...art('one', [0.73, s ? 0.5 : 0.54, 0.14, 0.19]),
          ...art('bow', [0.69, 0.23, 0.24, 0.035]),
        );
      }
      if (d.n === 24) {
        frame(0, [0.07, 0.28, 0.4, s ? 0.23 : 0.29]);
        frame(1, [0.53, 0.28, 0.4, s ? 0.23 : 0.29]);
        frame(2, [0.34, s ? 0.54 : 0.6, 0.32, s ? 0.16 : 0.18]);
        extra.push(...art('spine', [0.485, 0.27, 0.03, s ? 0.26 : 0.32]));
      }
      const letter = d.n === 23;
      return [
        { type: 'background', color: 'background', asset: null },
        ...art('margin', [0.025, 0.025, 0.95, 0.95], 0.35),
        header,
        ...pics,
        ...extra,
        text(
          'message',
          letter ? [0.07, 0.3, 0.57, s ? 0.25 : 0.26] : [0.07, s ? 0.79 : 0.835, 0.86, 0.065],
          letter ? 0.035 : 0.031,
          letter ? 5 : 2,
        ),
        text(
          'detail0',
          letter
            ? [0.07, 0.59, 0.58, s ? 0.17 : 0.19]
            : [0.07, s ? 0.87 : 0.902, 0.86, s ? 0.048 : 0.04],
          letter ? 0.032 : 0.025,
          letter ? 4 : 2,
        ),
        ...(letter ? [text('detail1', [0.07, s ? 0.8 : 0.83, 0.86, 0.055], 0.029, 2)] : []),
        text('signature', [0.65, 0.94, 0.28, 0.034], 0.026, 1),
        text('label1', [0.07, s ? 0.91 : 0.932, 0.55, 0.028], 0.021, 1),
        brand,
      ];
    };
    for (const video of [false, true]) {
      const c = content(d.n, video),
        count = video ? d.video : d.card;
      const beats = video
        ? (d.n === 22
            ? [[0, 1, 2], [3, 4, 5], [6, 7, 8], [9, 10, 11], [11]]
            : d.video === 4
              ? [[0], [1], [2], [3], [0, 1, 2, 3]]
              : [[0], [1], [2], [3], [4]]
          ).map((slots, i) => ({ slots, textKey: `scene${i + 1}` }))
        : [];
      out.push(
        keepsakeTemplateSchema.parse({
          id: `${video ? 'video' : 'card'}_premium48_${d.n}`,
          version: 1,
          kind: video ? 'video' : 'card',
          name: d.title,
          description: d.group,
          personalization: keepsakePersonalizationSchema.parse({ group: d.group, ...c, beats }),
          tier: 'premium',
          status: 'published',
          order: d.n + 1,
          occasions: [],
          ageDays: null,
          assets: Object.fromEntries(
            Object.entries(assets)
              .filter(([k]) => k.startsWith(`p48-${d.part}-`))
              .map(([k, v]) => [
                k.slice(4).replace(/-([a-z])/g, (_, v: string) => v.toUpperCase()),
                v,
              ]),
          ),
          photos: { min: count, max: count },
          scenes: video
            ? Array.from({ length: count }, (_, i) => ({
                hint:
                  d.n === 22
                    ? l(
                        `Ảnh tháng ${i + 1} (đúng vị trí)`,
                        `Month ${i + 1} photo (keep this position)`,
                      )
                    : l(`Ảnh ${i + 1} · ${d.title.vi}`, `Photo ${i + 1} · ${d.part}`),
                optional: false,
              }))
            : [],
          texts: [],
          palette: { background: d.palette[0], ink: d.palette[1], accent: d.palette[2] },
          palettes: [],
          durationSec: video ? (d.n === 22 ? 50 : 35) : null,
          thumb: null,
          preview: null,
          brand: video ? { ...defaultKeepsakeVideoBrand } : null,
          defaultMusic: video ? (music[d.part] ?? null) : null,
          layouts: video ? null : { portrait: layouts(false), story: layouts(true) },
          composition: video ? (d.composition as KeepsakeComposition) : null,
        }),
      );
    }
  }
  return out.sort((a, b) => a.kind.localeCompare(b.kind) || a.order - b.order);
}
