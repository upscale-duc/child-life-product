import { contactEmail } from '../site';
import type { Content } from './types';

/** Vietnamese — verbatim from Figma (Website 219:1391 / 233:804) except where marked
 *  "PROPOSED": those replace Figma copy that contradicts the app (D-001, Q-008, Q-009) or fill
 *  gaps (FAQ answers 3–5, G-065). They need owner approval before prod. */
export const vi: Content = {
  locale: 'vi',
  languageName: 'Tiếng Việt',
  meta: {
    title: 'Child Life — Cùng chăm con, giữ từng khoảnh khắc con lớn lên',
    description:
      'Ứng dụng miễn phí giúp cả nhà cùng chăm con: ghi bú, ngủ, thay tã trong một chạm và lưu giữ ảnh, video, câu chuyện của con. Có trên iPhone và Android.',
    ogAlt: 'Child Life — cùng chăm con và giữ trọn tuổi thơ của con',
  },
  skipToContent: 'Bỏ qua, đến nội dung chính',
  nav: {
    homeLabel: 'Child Life — trang chủ',
    sectionsLabel: 'Các phần của trang',
    links: {
      care: 'Chăm con',
      memories: 'Kỷ niệm',
      family: 'Gia đình',
      nights: 'Ban đêm',
      faq: 'Hỏi đáp',
    },
    download: 'Tải miễn phí',
    downloadShort: 'Tải app',
    switchLabel: 'View this page in English',
    switchShort: 'EN',
  },
  languageSuggestion: {
    text: 'Trang này cũng có bằng tiếng Việt.',
    action: 'Xem bằng tiếng Việt',
    dismiss: 'Đóng',
  },
  stores: {
    appStore: { prefix: 'Tải trên', name: 'App Store' },
    googlePlay: { prefix: 'Tải trên', name: 'Google Play' },
    comingSoon: 'Child Life sắp có mặt trên {store}. Hẹn bạn sớm nhé!',
    close: 'Đóng',
  },
  mock: {
    baby: 'Teddy',
    babyAge: 'Teddy · 3 tuần',
    date: 'Thứ Năm, 8 tháng 10',
    live: {
      app: 'Child Life',
      shared: 'Cả nhà đang thấy',
      title: 'Teddy đang ngủ',
      sub: 'Từ 21:42 · Ba bắt đầu',
      timer: '1:27:06',
      wake: 'Thức dậy',
      editStart: 'Sửa giờ bắt đầu',
    },
    bottleWidget: {
      label: 'Bú bình',
      ago: '45 phút trước',
      meta: '120 ml · Mẹ ghi',
      button: '+ 120 ml',
    },
    circular: { sleep: '1:27', feed: '45p', sleepLabel: 'Ngủ', feedLabel: 'Bú' },
  },
  hero: {
    eyebrow: 'Miễn phí cho cả gia đình',
    title: ['Cùng chăm con.', 'Giữ từng khoảnh khắc', 'con lớn lên.'],
    lead: 'Một không gian riêng tư cho cả nhà: cùng chăm con, lưu ảnh, video, câu chuyện và nhìn lại hành trình con lớn lên.',
    caption: 'Miễn phí trên iPhone và Android.',
    proofInitials: ['M', 'B', 'L', 'H'],
    proof: 'Ba mẹ, người chăm và ông bà — ai cũng có chỗ của mình bên con',
    chips: [
      { title: 'Bú bình · 120 ml', sub: 'Mẹ ghi · 2 phút trước' },
      { title: 'Bà nội thương ảnh của Teddy', sub: 'vừa xong' },
    ],
    today: {
      title: 'Hôm nay',
      tiles: {
        bottle: { label: 'Bú bình', value: '120 ml', meta: ['45 phút trước', 'Mẹ ghi'] },
        breast: {
          label: 'Bú mẹ',
          value: '15 phút',
          meta: ['Kết thúc 3 giờ 35 phút trước', 'Mẹ ghi'],
        },
        sleep: { label: 'Giấc ngủ', value: 'Đã thức 2 giờ', meta: ['Dậy lúc 13:05', 'Ba ghi'] },
        diaper: { label: 'Thay tã', value: 'Tã ướt', meta: ['1h 25p trước', 'Cô Lan ghi'] },
        pump: { label: 'Hút sữa', value: '90 ml', meta: ['2 giờ trước', 'Mẹ ghi'] },
        growth: { label: 'Tăng trưởng', value: '4,3 kg', meta: ['54,5 cm', '+0,4 kg · hôm nay'] },
      },
      reminder: {
        label: 'Nhắc việc · 3',
        title: 'Tiêm 6 trong 1',
        when: 'Thứ Bảy 08:30 · còn 2 ngày',
      },
      section: { title: 'Hôm nay', link: 'Lịch sử' },
    },
    album: {
      title: 'Album',
      count: '4 album',
      newAlbum: 'Album mới',
      albums: [
        { name: 'Yêu thích', meta: '18 ảnh · 2 video', shared: false },
        { name: 'Giờ tắm', meta: '12 ảnh · 3 video', shared: true },
        { name: 'Ngủ ngoan', meta: '28 ảnh · 1 video', shared: false },
        { name: 'Bàn tay nhỏ', meta: '9 ảnh', shared: true },
      ],
      segments: ['Nhật ký', 'Ảnh', 'Album', 'Câu chuyện'],
      navActive: 'Kỷ niệm',
      navInitial: 'M',
    },
  },
  quick: {
    eyebrow: 'Khi bận tay',
    title: 'Tay bế con, vẫn ghi lại được trong một chạm.',
    lead: 'Không cần mở app, không cần nhớ giờ. Chạm ngay trên màn hình điện thoại là xong — để bạn ở bên con lâu hơn một chút.',
    labels: ['Ngay trên màn hình điện thoại', 'Cả khi điện thoại đang khoá'],
    large: {
      status: 'Đã thức 2 giờ',
      statusSub: 'Dậy lúc 13:05 · ngủ 7g50 hôm nay',
      sleepButton: 'Ngủ',
      recentTitle: 'Gần đây',
      recent: [
        { time: '14:20', label: 'Bú bình · 120 ml', who: 'Mẹ' },
        { time: '13:40', label: 'Thay tã · Ướt', who: 'Cô Lan' },
        { time: '11:45', label: 'Ngủ 1 giờ 20 phút', who: 'Ba' },
      ],
      totals: 'Hôm nay: 2 cữ bình 240 ml · 1 lần bú mẹ · 2 tã',
    },
    tiles: {
      bottle: { label: 'Bú bình', value: '45 phút' },
      breast: { label: 'Bú mẹ', value: '3g 35p' },
      sleep: { label: 'Ngủ', value: 'thức 2g' },
      diaper: { label: 'Thay tã', value: '1g 25p' },
    },
    mediumMeta: '2 cữ · ngủ 7g50 hôm nay',
    logged: { title: 'Vừa xong', meta: 'Đã ghi 120 ml · Bạn', undo: 'Hoàn tác', edit: 'Sửa' },
    note: 'Một chạm là đã ghi xong',
    steps: [
      { title: 'Chạm một lần', sub: 'Ngay khi vừa cho bé bú xong' },
      { title: 'Tự lưu lại cho bạn', sub: 'Lỡ chạm nhầm cũng sửa được ngay' },
      { title: 'Cả nhà thấy ngay', sub: 'Không ai phải hỏi lại “con ăn chưa?”' },
    ],
  },
  care: {
    eyebrow: 'Chăm sóc mỗi ngày',
    title: 'Nhìn là hiểu một ngày của con.',
    lead: 'Con đã bú bao nhiêu, ngủ được bao lâu, thay tã lúc nào — tất cả hiện rõ trong một màn hình. Không cần nhớ, không phải đoán, kể cả lúc 3 giờ sáng.',
    bullets: [
      { title: 'Cả ngày của con trong một cái nhìn', sub: 'Dễ nhận ra nhịp ăn ngủ của bé' },
      { title: 'Đếm giờ giúp bạn khi bé ngủ, khi bú mẹ', sub: 'Liếc điện thoại là biết' },
      { title: 'Có sẵn số liệu khi đưa con đi khám' },
    ],
    bottle: { label: 'Bú bình', value: '120 ml', meta: ['45 phút trước', 'Mẹ ghi'] },
    sleep: { label: 'Giấc ngủ', value: 'Đang ngủ', meta: ['01:27:06 · từ 21:42', 'Ba bắt đầu'] },
    chip: 'Vẫn đếm giờ khi bạn tắt màn hình',
    rhythm: {
      title: 'Đã ghi hôm nay',
      totals: [
        ['Bú bình', '2 cữ · 240 ml'],
        ['Bú mẹ', '1 cữ · 15 phút'],
        ['Ngủ (đã xong)', '7 giờ 50'],
        ['Thay tã', '2 lần'],
      ],
      axis: ['0h', '6h', '12h', '18h', '24h'],
      legend: ['Ngủ', 'Bú bình', 'Bú mẹ', 'Tã'],
    },
  },
  cocare: {
    eyebrow: 'Cùng chăm',
    title: 'Cả nhà cùng chăm, không ai phải hỏi lại.',
    lead: 'Ai cho bé bú, ai thay tã, ai ru ngủ — cả nhà đều thấy. Đổi ca cho nhau nhẹ nhàng, không cần nhắn tin hỏi “con ăn lúc mấy giờ?”.',
    bullets: [
      'Biết con đã được chăm đến đâu',
      'Đi làm vẫn yên tâm khi bé ở nhà với bà, với cô',
      'Không có mạng vẫn ghi được, không mất gì',
    ],
    initials: { mother: 'M', father: 'B', grandma: 'Bà', nanny: 'L' },
    chip: 'Bạn chọn quyền',
    feed: {
      title: 'Vừa ghi',
      rows: [
        ['Bú bình 120 ml', 'Ba · 13:05'],
        ['Thay tã', 'Người chăm · 14:20'],
        ['Ngủ 1 giờ 20', 'Mẹ · 15:40'],
      ],
    },
  },
  memories: {
    eyebrow: 'Kỷ niệm',
    title: 'Nơi lưu giữ trọn tuổi thơ của con.',
    lead: 'Ảnh, video và những câu chuyện nhỏ được xếp theo từng tháng tuổi của con. Không lạc giữa hàng nghìn ảnh trong điện thoại, không sợ mất — mở ra là thấy con lớn lên.',
    timeline: [
      { age: 'Ngày đầu', title: 'Về nhà' },
      { age: '5 tuần', title: 'Lần đầu cười' },
      { age: '4 tháng', title: 'Lần đầu lẫy' },
      { age: '9 tháng', title: 'Chiếc răng đầu tiên' },
      { age: '1 tuổi', title: 'Sinh nhật đầu tiên' },
      { age: '2 tuổi', title: 'Những bước chạy' },
      { age: '3 tuổi', title: 'Ngày đầu đi học' },
    ],
    timelineEnd: '…và mọi năm sau nữa',
    tiles: {
      photos: {
        title: 'Ảnh của con, gọn gàng một chỗ',
        body: 'Không còn lẫn với ảnh chụp màn hình hay hoá đơn. Đánh dấu những tấm bạn thương nhất để tìm lại trong vài giây.',
        chip: 'Yêu thích · 48',
      },
      story: {
        title: 'Câu chuyện của con',
        body: 'Từ những gì bạn đã ghi, app gợi ý thành một câu chuyện nhỏ. Bạn sửa vài chữ cho đúng giọng mình, rồi gửi tặng người thân.',
        letter: {
          greeting: 'Gửi Teddy,',
          body: 'Sáng thứ Hai, mẹ vừa hát xong câu ru quen thuộc thì con bỗng nhoẻn miệng cười. Cả nhà đứng yên mấy giây, sợ chỉ cần thở mạnh là nụ cười sẽ biến mất.',
          signature: '— Mẹ, mùa thu 2026',
        },
        moment: {
          caption: 'Lần đầu cười · 5.10',
          quote: '“Như thể con cũng thuộc lời ru ấy.”',
          tag: 'TEDDY · 3 TUẦN TUỔI',
        },
      },
      family: {
        title: 'Ông bà ở xa vẫn thấy cháu lớn',
        body: 'Có ảnh mới là ông bà được báo và thả tim ngay. Không cần gửi lẻ từng tấm qua tin nhắn.',
        notifications: [
          { initial: 'Bà', text: 'Bà nội thương ảnh của Teddy', when: 'vừa xong' },
          // PROPOSED (Q-009): Figma "Ông ngoại đã xem 12 ảnh mới" implies seen receipts, which the app does not have.
          { initial: 'Ô', text: 'Ông ngoại thương 3 ảnh mới', when: '5 phút trước' },
          { initial: 'C', text: 'Cô Lan thương câu chuyện', when: 'hôm qua' },
        ],
      },
    },
  },
  night: {
    eyebrow: 'Cho những đêm thức giấc',
    title: 'Dịu mắt cho những cữ bú lúc nửa đêm.',
    lead: 'Buổi tối, màn hình tự dịu lại: nền tối ấm, chữ to, không chói mắt. Bé ngủ tiếp, bạn cũng dễ ngủ lại.',
    checks: [
      'Tự bật vào giờ bạn chọn, không cần nhớ',
      'Nút to, một tay vẫn bấm được khi đang bế con',
    ],
    sleepWidget: { label: 'Đang ngủ', sub: 'Từ 21:42 · Ba' },
  },
  roles: {
    eyebrow: 'Riêng tư',
    title: 'Ảnh của con, chỉ người nhà mới thấy.',
    lead: 'Mỗi người trong nhà thấy đúng phần cần thấy. Bạn luôn là người quyết định.',
    allowed: 'Được',
    notAllowed: 'Không được',
    cards: [
      {
        initial: 'M',
        role: 'Ba mẹ',
        description: 'Người quyết định mọi thứ',
        permissions: [
          { allowed: true, title: 'Chăm con', sub: 'Thấy và ghi mọi việc chăm con' },
          { allowed: true, title: 'Kỷ niệm', sub: 'Giữ mọi ảnh, video, câu chuyện' },
          { allowed: true, title: 'Mời người thân', sub: 'Mời ai, cho xem gì — do bạn chọn' },
        ],
      },
      {
        initial: 'C',
        role: 'Người chăm',
        description: 'Bảo mẫu, cô giúp việc',
        permissions: [
          { allowed: true, title: 'Chăm con', sub: 'Ghi lại việc chăm bé trong ngày' },
          // PROPOSED (Q-008): the app never shows Memories to caregivers; Figma says "Gửi ảnh bé cho ba mẹ, không xem album riêng".
          { allowed: false, title: 'Kỷ niệm', sub: 'Không xem ảnh và kỷ niệm của con' },
          { allowed: false, title: 'Mời người thân', sub: 'Không' },
        ],
      },
      {
        initial: 'B',
        role: 'Người thân',
        description: 'Ông bà, cô chú',
        permissions: [
          { allowed: false, title: 'Chăm con', sub: 'Không thấy chuyện ăn ngủ hằng ngày' },
          { allowed: true, title: 'Kỷ niệm', sub: 'Xem ảnh và câu chuyện ba mẹ chia sẻ' },
          { allowed: false, title: 'Mời người thân', sub: 'Không' },
        ],
      },
    ],
    notes: [
      // PROPOSED (D-001): Figma "Ảnh mới mặc định chỉ ba mẹ thấy…" contradicts the app default (Gia đình).
      'Mỗi ảnh mới, bạn chọn ai được xem: cả gia đình hay chỉ ba mẹ. Đổi lại lúc nào cũng được.',
      'Ảnh của con không hiện trên màn hình khoá, và đường link gửi đi sẽ tự hết hạn.',
    ],
  },
  cta: {
    title: ['Bớt phải nhớ.', 'Thêm thời gian bên con.'],
    sub: 'Miễn phí trên iPhone và Android. Mời cả nhà chỉ trong một phút.',
    caption: 'Miễn phí cho cả gia đình',
  },
  faq: {
    title: 'Câu hỏi thường gặp',
    sub: ['Còn điều gì băn khoăn? Cứ ', 'nhắn cho chúng tôi', ' nhé.'],
    items: [
      {
        q: 'Child Life dành cho bé từ mấy tuổi?',
        a: 'Từ ngày con chào đời. Những năm đầu, app giúp bạn chăm con mỗi ngày; khi con lớn hơn, đây là nơi giữ lại ảnh và câu chuyện của con.',
        open: true,
      },
      {
        q: 'Có mất phí không?',
        a: 'Không. Cả gia đình dùng miễn phí, đủ chỗ cho hàng nghìn ảnh của con. Cần thêm chỗ, bạn chỉ cần nhắn cho chúng tôi.',
        open: true,
      },
      // PROPOSED answers 3–5 (G-065): not in Figma.
      {
        q: 'Ông bà không rành điện thoại có dùng được không?',
        a: 'Được. Ba mẹ gửi lời mời, ông bà chỉ cần chạm vào là xem được ảnh và câu chuyện của cháu. Màn hình đơn giản, chữ rõ, ít nút bấm.',
        open: false,
      },
      {
        q: 'Ai được xem ảnh và thông tin của con?',
        a: 'Chỉ những người bạn mời vào gia đình. Ba mẹ quyết định ai được xem gì: người chăm chỉ thấy việc chăm bé hằng ngày, người thân chỉ thấy ảnh và câu chuyện bạn chia sẻ.',
        open: false,
      },
      {
        q: 'Có dùng được trên Android không?',
        a: 'Có. Child Life có trên cả iPhone và Android, nên cả nhà dùng máy khác nhau vẫn cùng chăm con được.',
        open: false,
      },
    ],
  },
  footer: {
    copyright: '© 2026 Child Life',
    privacy: 'Quyền riêng tư',
    terms: 'Điều khoản',
    contact: 'Liên hệ',
    email: contactEmail,
    languageLabel: 'Ngôn ngữ',
    linksLabel: 'Liên kết cuối trang',
  },
  legal: {
    privacy: {
      meta: {
        title: 'Quyền riêng tư — Child Life',
        description:
          'Chính sách quyền riêng tư của Child Life: cách chúng tôi bảo vệ ảnh, video và thông tin của con bạn.',
      },
      title: 'Quyền riêng tư',
      status: 'Đang hoàn thiện',
      paragraphs: [
        'Chính sách quyền riêng tư đầy đủ của Child Life sẽ được công bố tại đây trước khi ứng dụng ra mắt.',
        'Ảnh, video và thông tin của con chỉ dành cho những người bạn mời vào gia đình. Bạn quyết định ai được xem gì.',
      ],
      contactLead: 'Nếu bạn có câu hỏi về dữ liệu của mình, hãy viết cho chúng tôi:',
    },
    terms: {
      meta: {
        title: 'Điều khoản sử dụng — Child Life',
        description: 'Điều khoản sử dụng ứng dụng Child Life.',
      },
      title: 'Điều khoản sử dụng',
      status: 'Đang hoàn thiện',
      paragraphs: [
        'Điều khoản sử dụng đầy đủ của Child Life sẽ được công bố tại đây trước khi ứng dụng ra mắt.',
      ],
      contactLead: 'Nếu bạn có câu hỏi, hãy viết cho chúng tôi:',
    },
    back: 'Về trang chủ',
  },
};
