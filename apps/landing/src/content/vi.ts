import { contactEmail } from '../site';
import type { Content } from './types';

/** Vietnamese — verbatim from Figma (Website 219:1391 / 233:804) except where marked
 *  "PROPOSED": those replace Figma copy that contradicts the app (D-001, Q-008, Q-009) or fill
 *  gaps (FAQ answers 3–5, G-065). They need owner approval before prod. */
export const vi: Content = {
  locale: 'vi',
  languageName: 'Tiếng Việt',
  meta: {
    title: 'Child Life — Cùng con lớn lên, đồng hành từng bước',
    description:
      'Ứng dụng miễn phí giúp cả nhà cùng chăm con, hiểu con qua từng tuần tuổi và lưu giữ hành trình con lớn lên — bắt đầu từ năm đầu đời. Có trên iPhone và Android.',
    ogAlt: 'Child Life — cùng con lớn lên, đồng hành từng bước',
  },
  skipToContent: 'Bỏ qua, đến nội dung chính',
  nav: {
    homeLabel: 'Child Life — trang chủ',
    sectionsLabel: 'Các phần của trang',
    links: {
      care: 'Chăm sóc',
      memories: 'Kỷ niệm',
      lumi: 'Lumi',
      firstYear: 'Năm đầu đời',
      faq: 'Hỏi đáp',
    },
    start: 'Bắt đầu',
    download: 'Tải miễn phí',
    menuOpen: 'Mở menu',
    menuClose: 'Đóng menu',
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
    caption: 'Tải miễn phí trên iPhone và Android.',
    // Owner, 2026-10-19: before the listings exist the badges are pictures with this line.
    captionSoon: 'Sắp có trên iPhone và Android.',
    close: 'Đóng',
  },
  closing: {
    title: 'Bắt đầu từ năm đầu đời của con.',
    sub: 'Ghi chép, nhắc nhở và kỷ niệm — cả nhà cùng một nơi.',
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
    push: { app: 'CHILD LIFE', now: 'bây giờ' },
  },
  hero: {
    proofInitials: ['M', 'B', 'L', 'H'],
  },
  quick: {
    eyebrow: 'Khi bận tay',
    title: 'Ghi nhanh từ widget và màn hình khoá.',
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
  // v3 home + stage pages (Figma 358:2901 / 362:3398, 370:50752, 361:3457 / 3575 / 3693).
  // Lumi page (Figma 650:4798). Q-039: the plans (Free · Plus · Pro, prices) are not the app's
  // single Premium plan (33-landing-lumi-page §16); FAQ answers 2–6 are PROPOSED.
  lumiPage: {
    meta: {
      title: 'Lumi — trợ lý của cả nhà trong Child Life',
      description:
        'Kể một câu, Lumi soạn sẵn bản ghi bú, ngủ, thay tã; chụp hoá đơn thành khoản chi; hỏi gì cũng trả lời từ nhật ký của con. Bạn xem lại rồi mới lưu.',
    },
    hero: {
      eyebrow: 'Lumi · Trợ lý đồng hành trong Child Life',
      title: ['Nhắn một câu.', 'Lumi soạn sẵn bản ghi.'],
      lead: 'Lumi là trợ lý của cả nhà trong Child Life. Gõ như đang nhắn tin, chụp một tấm ảnh hay hỏi một câu — Lumi soạn sẵn bản ghi, trả lời từ chính nhật ký của con và gợi ý một việc nhỏ cho hôm nay.',
      tryNow: 'Mở Lumi trong app',
      plans: 'Xem các gói',
      promises: [
        'Bạn xác nhận trước khi lưu',
        'Trả lời từ nhật ký của con',
        'Cả nhà dùng theo quyền',
      ],
      mock: {
        name: 'Lumi',
        family: 'Trợ lý của nhà Teddy',
        ask: 'Con bú 120 ml lúc 9h, ngủ từ 9h30, thay tã lúc 10h',
        reply: 'Mình soạn 3 bản nháp, bạn xem lại rồi lưu nhé:',
        drafts: [
          { title: 'Bú bình · 120 ml', sub: '9:00' },
          { title: 'Giấc ngủ', sub: 'từ 9:30' },
          { title: 'Thay tã', sub: '10:00' },
        ],
        draft: 'Nháp',
        saveAll: 'Lưu cả 3',
        ask2: 'Mấy hôm nay con hay khó ngủ buổi tối',
        reply2:
          '3 tối gần đây có 2 lần bạn ghi “khó vào giấc”, đều sau 21h. Muốn xem lại các giấc quanh đó không?',
        composer: 'Kể, hỏi hoặc gửi ảnh cho Lumi…',
        saved: 'Đã lưu 3 bản ghi vào Nhật ký',
        expense: { title: 'Bỉm · 289.000 ₫', sub: 'Từ ảnh hoá đơn → Chi tiêu' },
        sample: 'Ví dụ minh hoạ',
      },
    },
    benefits: {
      eyebrow: 'Lumi giúp gì cho nhà bạn',
      title: 'Bớt việc phải nhớ, thêm thời gian bên con.',
      cards: [
        {
          title: 'Nhanh khi tay đang bận',
          body: 'Một câu thay cho nhiều lần chạm. Lumi tách thành từng bản ghi đúng mục.',
        },
        {
          title: 'Hiểu con từ chính nhật ký',
          body: 'Hỏi gì Lumi cũng trả lời từ dữ liệu nhà bạn đã ghi, kèm nguồn để mở lại.',
        },
        {
          title: 'Một việc nhỏ cho hôm nay',
          body: 'Gợi ý vừa sức theo tuổi và những gì bạn đã ghi — bạn chọn điều phù hợp.',
        },
        {
          title: 'Giữ lại từng khoảnh khắc',
          body: 'Từ ảnh trong máy thành thiệp, đoạn phim nhỏ cho những cột mốc đầu đời.',
        },
      ],
    },
    day: {
      eyebrow: 'Một ngày cùng Lumi',
      title: 'Từ cữ bú sáng sớm đến video cuối tháng.',
      lead: 'Sáu khoảnh khắc quen thuộc, mỗi lúc chỉ cần một câu hoặc một tấm ảnh.',
      cards: [
        {
          time: '06:30',
          title: 'Đang bế con, vẫn ghi kịp',
          body: 'Kể một câu, Lumi soạn sẵn bản ghi.',
        },
        {
          time: '10:15',
          title: 'Hoá đơn thành khoản chi',
          body: 'Chụp hoá đơn, Lumi điền sẵn số tiền.',
        },
        {
          time: '13:00',
          title: 'Hỏi nhanh, biết ngay',
          body: 'Trả lời từ nhật ký, kèm nguồn để mở lại.',
        },
        {
          time: '17:30',
          title: 'Hôm nay con ăn gì?',
          body: 'Món hợp tuổi, tránh món con từng phản ứng.',
        },
        {
          time: '21:30',
          title: 'Mấy hôm nay con khó ngủ',
          body: 'Đặt các ghi nhận gần đây cạnh nhau.',
        },
        {
          time: 'Cuối tháng',
          title: 'Tròn tháng, thành phim nhỏ',
          body: 'Chọn ảnh và mẫu, có ngay video đầy tháng.',
        },
      ],
    },
    quickNav: {
      label: 'Trên trang này:',
      items: ['Ví dụ', 'Gợi ý dành cho bé', 'Cách hoạt động', 'Các gói', 'Hỏi đáp'],
    },
    how: {
      eyebrow: 'Lumi làm việc thế nào',
      title: 'Lumi soạn sẵn. Bạn là người quyết định.',
      steps: [
        { title: 'Kể, hỏi hoặc chụp', body: 'Gõ như nhắn tin, hoặc gửi ảnh hoá đơn, giấy dặn.' },
        { title: 'Lumi soạn nháp', body: 'Tách đúng mục, hỏi lại chỗ thiếu hoặc chưa rõ.' },
        { title: 'Bạn xem và lưu', body: 'Sửa, bỏ hoặc lưu từng bản. Lumi không tự lưu.' },
      ],
      trust: [
        'Chỉ người trong nhà, theo quyền bạn cấp',
        'Ảnh gửi cho Lumi chỉ để đọc nội dung, bạn chọn có giữ ảnh gốc hay không',
        'Lumi không thay bác sĩ và không chẩn đoán. Khi lo lắng về sức khoẻ, Lumi chỉ tới hướng dẫn an toàn và số khẩn cấp',
      ],
    },
    plans: {
      eyebrow: 'Xem các gói',
      title: 'Bắt đầu miễn phí. Thêm lượt khi nhà bạn cần.',
      lead: 'Các gói có cùng tính năng. Khác nhau ở lượt hỗ trợ Lumi và số video kỷ niệm mỗi tháng.',
      monthly: 'Theo tháng',
      yearly: 'Theo năm',
      perMonth: '/ tháng',
      perYear: '/ năm',
      credits: 'lượt hỗ trợ / tháng',
      tiers: [
        {
          name: 'Free',
          tagline: 'Để bắt đầu',
          credits: '30',
          photos: '≈ 10 ảnh hoá đơn, giấy dặn',
          videos: '1 video kỷ niệm / tháng',
          price: '0đ',
          yearPrice: '0đ',
          sub: 'Không cần thẻ thanh toán',
          yearSub: 'Không cần thẻ thanh toán',
          button: 'Bắt đầu miễn phí',
        },
        {
          name: 'Plus',
          tagline: 'Cho ngày nhiều việc',
          credits: '300',
          photos: '≈ 100 ảnh hoá đơn, giấy dặn',
          videos: '5 video kỷ niệm / tháng',
          price: '79.000đ',
          yearPrice: '790.000đ',
          sub: 'hoặc 790.000đ/năm · tiết kiệm 2 tháng',
          yearSub: '≈ 65.800đ/tháng · tiết kiệm 2 tháng',
          button: 'Nâng cấp lên Plus',
        },
        {
          name: 'Pro',
          tagline: 'Cho cả nhà dùng nhiều',
          credits: '1.000',
          photos: '≈ 330 ảnh hoá đơn, giấy dặn',
          videos: '15 video kỷ niệm / tháng',
          price: '179.000đ',
          yearPrice: '1.790.000đ',
          sub: 'hoặc 1.790.000đ/năm · tiết kiệm 2 tháng',
          yearSub: '≈ 149.200đ/tháng · tiết kiệm 2 tháng',
          button: 'Nâng cấp lên Pro',
        },
      ],
      features: {
        all: 'Tất cả việc Lumi làm được',
        templates: 'Mọi mẫu thiệp & video',
        drafts: 'Sửa, xác nhận nháp không tính thêm lượt',
      },
      note: 'Giá đã gồm VAT, thanh toán qua App Store / Google Play. Gói năm tiết kiệm 2 tháng. Huỷ gia hạn bất cứ lúc nào trong cài đặt cửa hàng.',
      table: {
        caption: 'So sánh các gói',
        feature: 'Tính năng',
        price: 'Giá mỗi tháng',
        credits: 'Lượt hỗ trợ mỗi tháng',
        rows: [
          'Ghi nhật ký bằng một câu',
          'Hỏi đáp từ nhật ký của con',
          'Đọc ảnh hoá đơn, giấy dặn (≈3 lượt/ảnh)',
          'Nhìn lại mấy ngày & gợi ý cho hôm nay',
          'Tóm tắt tuần cho cả nhà',
          'Nhịp lớn lên của riêng con',
          'Mọi mẫu thiệp & video',
        ],
        videos: 'Xuất video kỷ niệm mỗi tháng',
        fallback: 'Ghi trực tiếp & hướng dẫn an toàn khi hết lượt',
        yes: 'Có',
      },
      creditsInfo: {
        title: 'Lượt hỗ trợ là gì?',
        // D-088: routine logs and quick reads cost 0 (owner, 2026-10-19). PROPOSED wording.
        body: 'Lượt chỉ tính khi Lumi cần suy nghĩ thêm cho bạn. Lượt làm mới đầu mỗi kỳ.',
        rules: [
          ['Ghi bú, ngủ, tã thường ngày hoặc xem nhanh nhật ký', 'Không tính'],
          ['Một câu dài hoặc câu hỏi Lumi cần suy nghĩ', '1 lượt'],
          ['Đọc một ảnh hoá đơn, giấy dặn', '≈ 3 lượt'],
          ['Hỏi lại, sửa hay xác nhận nháp trong cùng việc', 'Không tính'],
          ['Lỗi hệ thống, thử lại', 'Không tính'],
          ['Hết lượt', 'Vẫn ghi trực tiếp, xem nhật ký bình thường'],
        ],
      },
    },
    faq: {
      eyebrow: 'Hỏi đáp',
      title: 'Những điều ba mẹ hay hỏi về Lumi.',
      items: [
        {
          q: 'Lumi có tự ghi vào nhật ký không?',
          a: 'Không. Lumi soạn nháp, bạn xem lại và bấm lưu. Bạn có thể sửa hoặc bỏ từng bản.',
          open: true,
        },
        {
          q: 'Hết lượt hỗ trợ thì sao?',
          a: 'Bạn vẫn ghi trực tiếp và xem nhật ký như bình thường; hướng dẫn sức khoẻ thiết yếu vẫn mở. Lượt được làm mới đầu kỳ tiếp theo.',
          open: false,
        },
        {
          q: 'Gói Free có bị thiếu tính năng không?',
          a: 'Không. Mọi việc Lumi làm đều có trong gói Free; các gói chỉ khác nhau ở số lượt mỗi tháng.',
          open: false,
        },
        {
          q: 'Có thể đổi gói giữa chừng không?',
          a: 'Có. Bạn đổi gói trong ứng dụng; gia hạn và huỷ do App Store / Google Play quản lý.',
          open: false,
        },
        {
          q: 'Ai trong nhà dùng chung lượt?',
          a: 'Cả nhà dùng chung một quỹ lượt của hộ. Chỉ chủ hộ mua và quản lý gói.',
          open: false,
        },
        {
          q: 'Thông tin của con được dùng thế nào?',
          a: 'Lumi chỉ đọc những gì bạn gửi và phần nhật ký bạn được quyền xem, để trả lời và soạn nháp. Bạn đồng ý trước khi dùng và tắt được bất cứ lúc nào.',
          open: false,
        },
      ],
    },
    cta: {
      title: 'Để Lumi lo phần ghi chép. Bạn dành thời gian cho con.',
      plans: 'Xem các gói',
    },
  },
  // V8 home (Figma 735:5377 / 736:65570, 34-landing-v8-home). Q-039: claims in §K of that spec
  // (Apple Watch, Wear OS "Sắp có", seen receipts, reminder recipients, Lumi plans).
  homePage: {
    hero: {
      eyebrow: 'Child Life · Bắt đầu từ năm đầu đời',
      title: 'Cùng chăm con, giữ từng khoảnh khắc con lớn lên.',
      lead: 'Ghi bú, ngủ, tã để cả nhà cùng theo dõi. Lưu ảnh, tạo video và giữ lại những lần đầu tiên của con.',
      support: 'Bắt đầu với năm đầu đời. Tiếp tục đồng hành khi con lớn.',
      seeApp: 'Xem app hoạt động',
      vision: 'Hệ sinh thái đồng hành cùng con — từ ngày đầu đời đến khi trưởng thành.',
      now: 'Đang có trong app',
      soon: 'Sắp tới',
      feed: { title: 'Bú bình · 120 ml', sub: 'Ba vừa ghi · 2 phút trước' },
      smile: { title: 'Lần đầu con cười', sub: 'Đã lưu vào Kỷ niệm' },
      video: { title: 'Video đầy tháng của Teddy', meta: '0:45 · từ ảnh bạn chọn' },
    },
    values: {
      eyebrow: 'Child Life giúp gì',
      title: 'Child Life giúp gia đình bạn ba việc.',
      lead: 'Mỗi phần đều dùng được ngay trong năm đầu đời của con.',
      cards: [
        {
          title: 'Chăm con mỗi ngày',
          body: 'Ghi bú, ngủ, tã và đặt nhắc nhở. Cả nhà cùng biết con vừa được chăm thế nào.',
        },
        {
          title: 'Hiểu con từng giai đoạn',
          body: 'Xem nhật ký, theo dõi mốc phát triển và tìm nội dung theo tuổi của bé.',
        },
        {
          title: 'Giữ những điều đáng nhớ',
          body: 'Lưu ảnh riêng tư, tạo thiệp và video từ những khoảnh khắc của con.',
        },
      ],
      mock: {
        rows: [
          ['Bú bình 120 ml', '9:00'],
          ['Ngủ 1 giờ 20 phút', '10:40'],
          ['Thay tã', '11:05'],
        ],
        week: {
          title: 'Tuần này của bé · 4 tháng',
          body: 'Bé thường bắt đầu với lấy đồ vật. Gợi ý: đặt đồ chơi trong tầm tay.',
        },
        milestone: ['Mốc: Biết lẫy', 'đã ghi'],
      },
    },
    memories: {
      eyebrow: 'Kỷ niệm',
      title: 'Những tấm ảnh hôm nay, thành kỷ niệm để mai này xem lại.',
      lead: 'Chọn ảnh của con để tạo video đầy tháng, thiệp cột mốc hoặc lưu vào album riêng của gia đình.',
      video: {
        title: 'Video kỷ niệm',
        body: 'Chọn ảnh và mẫu, có ngay video đầy tháng, 100 ngày hay thôi nôi để gửi cả nhà.',
        button: 'Xem video mẫu',
      },
      card: {
        title: 'Thiệp cột mốc',
        body: 'Tròn tháng, 100 ngày, lần đầu biết lẫy — chọn mẫu và ảnh, gửi cho ông bà.',
        bodyShort: 'Chọn mẫu và ảnh, gửi cho ông bà.',
      },
      thenNow: {
        title: 'Ngày ấy & bây giờ',
        body: 'Đặt hai tấm ảnh cạnh nhau để thấy con lớn thế nào.',
        bodyShort: 'Hai tấm ảnh, thấy con lớn thế nào.',
      },
      // Q-009: seen receipts are not built; PROPOSED "thương" instead of Figma's "đã xem".
      album: {
        title: 'Album gia đình riêng tư',
        body: 'Ông bà ở xa vẫn theo dõi cháu.',
        initial: 'B',
        seen: 'Bà nội thương 3 ảnh mới',
      },
      alsoLabel: 'Còn có:',
      also: ['Nhật ký của con', 'Lời nhắn cho con', 'Sách năm đầu đời'],
      soon: 'Sắp có',
      button: 'Xem các mẫu kỷ niệm',
    },
    family: {
      eyebrow: 'Cả nhà cùng chăm',
      title: 'Ba vừa ghi, mẹ đã thấy. Không ai phải hỏi lại.',
      bullets: [
        'Ghi và xem chung một nhật ký.',
        'Nhắc nhở đúng người đang chăm bé.',
        'Ba mẹ, người chăm và người thân có quyền xem khác nhau.',
      ],
      trust: 'Bạn chọn ai được xem ảnh và thông tin của con.',
      steps: [
        {
          initial: 'B',
          meta: 'Ba · 09:00',
          title: 'Ba ghi cữ bú',
          body: 'Bú bình 120 ml — một chạm là xong.',
        },
        {
          initial: 'M',
          meta: 'Mẹ · 09:01',
          title: 'Mẹ thấy ngay',
          body: '“Ba vừa ghi: Bú bình 120 ml lúc 9:00.”',
        },
        {
          initial: '✓',
          meta: 'Cả nhà',
          title: 'Không cần hỏi lại',
          body: 'Cữ tiếp theo đã có nhắc cho người đang chăm.',
        },
      ],
    },
    // Q-047 / Q-048: the watch app is not released; Wear OS is not in V1.
    wrist: {
      chip: 'Trên cổ tay',
      title: 'Đang bế con? Ghi ngay trên đồng hồ.',
      lead: 'Một chạm để ghi bú, ngủ, tã — cả nhà thấy ngay trên điện thoại.',
      apple: 'Apple Watch',
      wear: 'Đồng hồ Android (Wear OS) · Sắp có',
      wearLabel: 'Wear OS',
      round: { asleep: 'Đang ngủ' },
    },
    assistant: {
      eyebrow: 'Lumi · Trợ lý trong Child Life',
      title: 'Nhắn một câu, Lumi lo phần ghi chép.',
      lead: 'Lumi soạn nháp từ lời bạn nhắn và trả lời từ nhật ký của con. Khi mở app, bạn cũng thấy gợi ý liên quan đến những gì đã ghi.',
      chat: {
        title: 'Bạn nhắn, Lumi lo phần ghi',
        body: 'Một câu thành nhiều bản ghi. Hỏi là có câu trả lời từ nhật ký.',
      },
      today: {
        title: 'Bạn mở app, điều cần xem đã có',
        body: 'Gợi ý xuất hiện kèm lý do — vì những gì bạn đã ghi.',
      },
      floats: [
        'Đã lưu 3 bản ghi',
        'Bạn xác nhận trước khi lưu',
        'Có lý do cho từng gợi ý',
        'Ẩn hoặc sửa bất cứ lúc nào',
      ],
      cta: 'Khám phá Lumi',
      note: 'Ví dụ minh hoạ. Lumi hỗ trợ nhập chữ và ảnh; bạn kiểm tra và bấm lưu.',
    },
    tools: {
      eyebrow: 'Tiện ích',
      title: 'Và những tiện ích nhỏ cho mỗi ngày.',
      cards: [
        {
          title: 'Nhắc bú, ngủ',
          body: 'Nhắc đúng cữ cho người đang chăm.',
          chip: 'Cữ tiếp · 11:30',
        },
        { title: 'Mốc phát triển', body: 'Đánh dấu và lưu những lần đầu.', chip: 'Biết lẫy ✓' },
        { title: 'Gợi ý theo tuổi', body: 'Mỗi tuần, điều thường gặp ở tuổi bé.', chip: 'Tuần 16' },
        {
          title: 'Thư viện chăm bé & ăn dặm',
          body: 'Bài ngắn, công thức theo giai đoạn.',
          chip: 'Cháo bí đỏ',
        },
        { title: 'Sơ cứu trẻ em', body: 'Hướng dẫn từng bước khi cần gấp.', chip: 'Hóc dị vật' },
        {
          title: 'Sổ chi tiêu cho bé',
          body: 'Ba mẹ cùng xem tiền đã chi cho con.',
          chip: '289.000 ₫',
        },
        {
          title: 'Tuỳ chỉnh & chế độ đêm',
          body: 'Chỉ hiện điều bạn cần; dịu mắt ban đêm.',
          chip: 'Chế độ đêm',
        },
        { title: 'Apple Watch', body: 'Ghi nhanh ngay trên đồng hồ.', chip: 'Ghi 1 chạm' },
      ],
      button: 'Xem tất cả trong Năm đầu đời',
    },
    journey: {
      eyebrow: 'Hành trình',
      title: 'Con lớn, hành trình vẫn tiếp tục.',
      lead: 'Hôm nay Child Life dành cho năm đầu đời. Những chặng sau đang được phát triển cùng các gia đình.',
      now: 'Đang có trong app',
      soon: 'Đang phát triển',
      bodies: [
        'Chăm con, hiểu con và giữ kỷ niệm năm đầu.',
        'Chơi, tập nói và những thói quen đầu tiên.',
        'Câu hỏi “vì sao”, tranh vẽ và lời con kể.',
        'Sở thích, dự án nhỏ và kế hoạch của con.',
      ],
    },
    // Answers 2–5 are not in Figma: PROPOSED (owner review). Q-071: the app has one Premium plan.
    trust: {
      eyebrow: 'Miễn phí & niềm tin',
      title: 'Bắt đầu miễn phí. Gia đình bạn giữ quyền kiểm soát.',
      points: [
        'Ghi chép, nhắc nhở, mốc phát triển và kỷ niệm cơ bản dùng miễn phí.',
        'Lumi có sẵn với số lượt dùng miễn phí giới hạn mỗi tháng.',
        'Cần thêm lượt? Có thể chọn gói Lumi cao hơn bất cứ lúc nào.',
        'Gia đình chọn ai được xem ảnh và thông tin của con.',
      ],
      faq: [
        {
          q: 'App hiện dành cho bé mấy tuổi?',
          a: 'Hiện Child Life tập trung vào năm đầu đời, từ khi con chào đời đến 12 tháng. Các chặng sau đang được phát triển.',
          open: true,
        },
        {
          q: 'Có mất phí không?',
          a: 'Ghi chép, nhắc nhở, mốc phát triển và kỷ niệm cơ bản dùng miễn phí cho cả gia đình. Lumi có số lượt miễn phí mỗi tháng; cần nhiều hơn thì nâng cấp gói.',
          open: false,
        },
        {
          q: 'Ông bà và người chăm dùng thế nào?',
          a: 'Ba mẹ mời ông bà, người thân hoặc người chăm vào gia đình. Người chăm ghi và xem việc chăm bé hằng ngày; ông bà, người thân xem ảnh và câu chuyện ba mẹ chia sẻ.',
          open: false,
        },
        {
          q: 'Ai xem được ảnh và thông tin của con?',
          a: 'Chỉ những người bạn mời vào gia đình. Ba mẹ quyết định ai được xem gì: người chăm chỉ thấy việc chăm bé hằng ngày, người thân chỉ thấy ảnh và câu chuyện bạn chia sẻ.',
          open: false,
        },
        {
          q: 'Hết lượt Lumi thì sao?',
          a: 'Bạn vẫn ghi trực tiếp và xem nhật ký như bình thường; hướng dẫn sức khoẻ thiết yếu vẫn mở. Lượt được làm mới đầu kỳ tiếp theo.',
          open: false,
        },
      ],
    },
  },
  // V8 "Năm đầu đời" page (Figma 737:6362, 35-landing-v8-first-year).
  firstYearPage: {
    meta: {
      title: 'Năm đầu đời của con — Child Life',
      description:
        'Ghi chép và nhắc nhở cho cả nhà, gợi ý theo tuổi, sơ cứu, ăn dặm và nơi giữ kỷ niệm của con — dùng được ngay hôm nay.',
    },
    hero: {
      badge: 'Đang có trong app',
      title: 'Năm đầu đời của con, gọn trong một app.',
      lead: 'Ghi chép và nhắc nhở cho cả nhà, gợi ý theo tuổi, sơ cứu, ăn dặm và nơi giữ kỷ niệm của con — dùng được ngay hôm nay.',
    },
    jump: { label: 'Đi nhanh tới:', navLabel: 'Đi nhanh tới các nhóm' },
    groups: [
      { title: 'Ghi & nhắc', sub: 'Ghi trong vài chạm, nhắc đúng lúc.' },
      { title: 'Cả nhà cùng chăm', sub: 'Ba mẹ, ông bà và người chăm cùng một nhật ký.' },
      { title: 'Hiểu con theo tuổi', sub: 'Mốc, tiêm chủng, bài đọc và sơ cứu theo tuổi của bé.' },
      { title: 'Kỷ niệm', sub: 'Giữ lại những lần đầu tiên của con.' },
      { title: 'Tiện ích', sub: 'Chế độ đêm, tuỳ chỉnh màn hình và Apple Watch.' },
    ],
    // P-133 / D-084 vaccine book; D-049 WHO growth; D-083 nutrition content awaits review.
    vaccines: {
      eyebrow: 'Sức khoẻ của con',
      title: 'Lịch tiêm và biểu đồ tăng trưởng.',
      lead: 'Biết con đã tiêm gì, sắp tiêm gì, lớn lên ra sao — không cần lục sổ.',
      bullets: [
        {
          title: 'Lịch tiêm theo tháng tuổi',
          sub: 'Đánh dấu mũi đã tiêm, nhắc trước ngày tiêm cho cả nhà.',
        },
        {
          title: 'Cân nặng, chiều dài theo chuẩn WHO',
          sub: 'Biểu đồ dễ đọc, không chấm điểm hay so sánh con.',
        },
        {
          title: 'Dinh dưỡng theo giai đoạn',
          sub: 'Lượng sữa tham khảo và nhóm chất cần chú ý theo tuổi.',
        },
      ],
      note: 'Nội dung tham khảo, được chuyên môn rà soát. Lịch tiêm cụ thể theo hướng dẫn của cơ sở y tế.',
      mock: {
        title: 'Lịch tiêm chủng · Teddy',
        columns: ['Sơ sinh', '2 th', '3 th', '4 th', '6 th', '9 th'],
        rows: ['Viêm gan B', 'Lao', '6 trong 1', 'Phế cầu', 'Rota', 'Sởi'],
        done: 'Đã tiêm',
        due: 'Sắp tới',
        next: 'Mũi tiếp theo: 6 trong 1 · lần 3 · 17/11',
        growth: { label: 'Cân nặng', value: '7,8 kg', chip: 'Trong khoảng chuẩn WHO' },
      },
    },
  },
  // V8 future-stage template (Figma 738:7309, 36-landing-v8-lumi-and-stages B). Q-039: roadmap.
  // Titles for Chặng 3 and 4 are PROPOSED (only Chặng 2 is drawn).
  stagePage: {
    band: 'Đang phát triển — chặng này chưa có trong app. Hiện Child Life dành cho năm đầu đời (0–12 tháng).',
    status: 'Đang phát triển',
    available: 'Đang có trong app',
    lead: 'Đây là định hướng cho chặng {ages}; phạm vi và thời điểm ra mắt sẽ được cập nhật.',
    useFirstYear: 'Dùng Child Life cho năm đầu đời',
    eyebrow: 'Những điều đang được chuẩn bị',
    titles: [
      'Ba trải nghiệm cho tuổi chập chững.',
      'Ba trải nghiệm cho chặng 3–6 tuổi.',
      'Ba trải nghiệm cho chặng 6–12 tuổi.',
    ],
    note: 'Các trải nghiệm trên là định hướng đang được phát triển, chưa có trong ứng dụng.',
  },
  // v6 (Figma 678:5614). Q-039: stages 2–4 are a roadmap ("Định hướng").
  lumiJourney: {
    planned: 'Định hướng',
    stages: [
      {
        sub: 'Nhẹ nhàng hơn cho cả nhà.',
        items: [
          { title: 'Kể một lần, ghi đúng chỗ.' },
          { title: 'Hỏi về nhật ký của con.' },
          { title: 'Gợi ý món ăn dặm hôm nay.' },
        ],
      },
      {
        sub: 'Bớt nghĩ chơi gì, thêm những điều cùng con thử.',
        items: [
          {
            title: 'Hôm nay chơi gì cùng con?',
            body: 'Gợi ý hoạt động ngắn theo tuổi, sở thích đã ghi và những vật dụng có sẵn.',
          },
          {
            title: 'Từng lời đầu tiên, không bị quên.',
            body: 'Gom những câu nói ngộ nghĩnh, tiếng cười và bước tiến nhỏ thành nhật ký của con.',
          },
          {
            title: 'Cùng xây những thói quen nhỏ.',
            body: 'Chuẩn bị những bước đơn giản cho giờ ngủ, đánh răng hay thu dọn đồ chơi, theo cách gia đình lựa chọn.',
          },
        ],
      },
      {
        sub: 'Thêm ý tưởng cho những câu hỏi không ngừng.',
        items: [
          {
            title: '“Vì sao?” cũng thành giờ chơi.',
            body: 'Biến điều con tò mò thành câu chuyện, trò chơi hoặc hoạt động để cùng khám phá.',
          },
          {
            title: 'Một ngày của con, dễ kể lại hơn.',
            body: 'Từ vài ghi chú của ba mẹ, gợi ý câu hỏi để cùng con trò chuyện về ngày ở lớp.',
          },
          {
            title: 'Bức vẽ nhỏ, câu chuyện lớn.',
            body: 'Giữ tác phẩm cùng lời con kể, rồi gom thành bộ sưu tập qua từng năm.',
          },
        ],
      },
      {
        sub: 'Đồng hành gần hơn, dành chỗ cho con tự lớn.',
        items: [
          {
            title: 'Ý tưởng của con có nơi bắt đầu.',
            body: 'Cùng chia một dự án nhỏ thành những bước vừa sức — trồng cây, làm mô hình hay viết truyện.',
          },
          {
            title: 'Kế hoạch do con cùng lựa chọn.',
            body: 'Chuẩn bị lịch học, việc nhà và thời gian cho sở thích; ba mẹ và con cùng điều chỉnh.',
          },
          {
            title: 'Một năm nhìn bằng mắt con.',
            body: 'Gom thành quả, câu chuyện và điều con tự hào thành cuốn kỷ niệm có tiếng nói của chính con.',
          },
        ],
      },
    ],
  },
  // "Dành cho con" (Figma 699:5798, home) and "Một ngày dành riêng cho con" (700:5832, Lumi page).
  // Q-039: meal ideas come from library content still awaiting expert review (the design says so).
  forBaby: {
    mock: {
      initial: 'T',
      name: 'Hôm nay của Teddy',
      date: 'Thứ Năm · 3 điều đáng chú ý',
      sample: 'Ví dụ minh hoạ',
      why: 'Vì sao bạn thấy thẻ này',
      cards: [
        {
          title: 'Nhìn lại giấc ngủ',
          body: '2 tối gần đây con khó vào giấc, đều sau 21h.',
          why: 'Bạn đã ghi nhận “khó vào giấc” trong 2 ngày gần đây.',
          action: 'Xem các ghi nhận liên quan',
        },
        {
          title: 'Ý tưởng cho bữa tiếp theo',
          body: 'Cháo bí đỏ yến mạch · Khoai lang nghiền',
          why: 'Dựa trên tuổi, món đã thử và phản ứng bạn ghi.',
          action: 'Xem món và nguyên liệu',
        },
        {
          title: 'Giữ lại nụ cười đầu tiên',
          body: '3 ảnh bạn chọn hôm qua đã sẵn sàng.',
          why: 'Bạn vừa đánh dấu mốc “mỉm cười đáp lại”.',
          action: 'Tạo thiệp từ ảnh đã chọn',
        },
      ],
      footnote: 'Bạn chọn chủ đề hiện ở đây, ẩn hoặc sửa bất cứ lúc nào.',
    },
    detail: {
      eyebrow: 'Một ngày dành riêng cho con',
      title: ['Không cần nghĩ ra câu hỏi.', 'Điều đáng chú ý đã chờ sẵn.'],
      lead: 'Mỗi khi mở app, “Hôm nay của bé” đặt lên trước những thông tin và gợi ý đáng chú ý cho chính con — kèm lý do vì sao chúng xuất hiện.',
      modes: [
        {
          name: 'Lumi',
          sub: 'Bạn kể hoặc hỏi — Lumi xử lý giúp.',
          example: '“Con bú 120 ml lúc 9h” → Lumi soạn sẵn bản ghi để bạn lưu.',
        },
        {
          name: 'Hôm nay của bé',
          sub: 'Bạn mở app — điều đáng chú ý đã có sẵn.',
          example:
            'Không cần hỏi: thẻ “Nhìn lại giấc ngủ” xuất hiện vì bạn đã ghi khó vào giấc 2 tối.',
        },
      ],
      modesNote:
        'Hai trải nghiệm dùng chung những gì gia đình đã ghi, nhưng phục vụ hai lúc khác nhau.',
      steps: ['Ba mẹ đã ghi', 'Hôm nay ba mẹ thấy', 'Bạn quyết định'],
      scenarios: [
        {
          logged: ['Khó vào giấc · T3', 'Khó vào giấc · T4', '6 giấc ngủ'],
          decide: ['Xem các ghi nhận liên quan', 'Ẩn chủ đề giấc ngủ tuần này'],
        },
        {
          logged: ['7 tháng', 'Đã thử: bí đỏ, khoai lang', 'Đã ghi phản ứng: trứng'],
          decide: ['Xem món và nguyên liệu', 'Lưu món để thử', 'Không phù hợp'],
        },
        {
          logged: ['Mốc: mỉm cười đáp lại', '3 ảnh đã chọn'],
          decide: ['Tạo thiệp từ ảnh đã chọn', 'Để sau'],
        },
      ],
      controlTitle: 'Bạn luôn kiểm soát:',
      controls: [
        'Chọn chủ đề quan tâm',
        'Ẩn gợi ý không hợp',
        'Sửa thông tin đã ghi',
        'Cho biết điều hữu ích',
      ],
      note: 'Ví dụ minh hoạ. Gợi ý món ăn, hoạt động lấy từ thư viện nội dung đang chờ chuyên môn duyệt; chỉ giới thiệu như tính năng có sẵn khi đã triển khai.',
    },
  },
  // Q-039: stages 2–4 describe features beyond the V1 scope.
  journey: {
    label: 'Hành trình',
    number: 'Chặng {n}',
    prevNextLabel: 'Các chặng',
    stages: [
      {
        name: 'Những ngày đầu đời',
        ages: '0–12 tháng',
        title: 'Những ngày đầu đời.',
        lead: 'Làm quen với nhau qua từng cữ bú, giấc ngủ — và giữ lại những lần đầu tiên của con.',
      },
      {
        name: 'Con tập khám phá',
        ages: '1–3 tuổi',
        title: 'Con tập khám phá.',
        lead: 'Cùng con chập chững, bập bẹ những từ đầu tiên và tập những thói quen nhỏ.',
      },
      {
        name: 'Tò mò và lớn khôn',
        ages: '3–6 tuổi',
        title: 'Tò mò và lớn khôn.',
        lead: 'Cùng con chơi, đọc, vẽ và trả lời những câu hỏi “vì sao” không ngừng.',
      },
      {
        name: 'Thế giới riêng của con',
        ages: '6–12 tuổi',
        title: 'Thế giới riêng của con.',
        lead: 'Đồng hành nhẹ nhàng khi con tự lập, có sở thích và những ước mơ riêng.',
      },
    ],
  },
  home: {
    lumi: {
      mock: {
        logAsk: 'Con bú 120 ml lúc 9h, ngủ từ 9h30',
        drafts: [
          { title: 'Bú bình · 120 ml', sub: '9:00' },
          { title: 'Giấc ngủ', sub: 'từ 9:30' },
        ],
        draft: 'Nháp',
        dataAsk: 'Hôm nay con bú thế nào?',
        dataAnswer: '5 cữ bú bình · tổng 580 ml. Cữ gần nhất lúc 14:20.',
        dataSource: 'Mở nhật ký nguồn',
        sleepAsk: 'Mấy hôm nay con khó vào giấc',
        sleepAnswer:
          '3 tối gần đây có 2 ghi nhận khó vào giấc, đều sau 21h. Xem lại các giấc quanh đó nhé?',
        sleepSources: ['6 giấc ngủ', '2 ghi chú'],
        mealAsk: 'Hôm nay cho Teddy ăn gì?',
        mealAnswer: 'Gợi ý cho bé 7 tháng, đã bỏ trứng vì từng ghi nổi mẩn:',
        meals: ['Cháo bí đỏ', 'Khoai lang nghiền'],
        receipt: {
          title: 'Bỉm · 289.000 ₫',
          sub: 'Chi tiêu · hôm nay',
          note: 'Ngày trên hoá đơn mờ — Lumi hỏi lại trước khi lưu.',
          amount: '289.000 ₫',
        },
        video: 'Một tháng đầu của Teddy · 0:45',
      },
    },
    keepsakes: {
      mock: {
        video: {
          template: 'Mẫu · Năm đầu đời',
          caption: 'Lần đầu biết lẫy · 4 tháng',
          time: '0:16 / 0:45',
          music: 'Nhạc: Ru con nhẹ nhàng',
          milestones: '3 cột mốc',
        },
        card: {
          title: '100 ngày',
          sub: 'Teddy · 18.01.2027',
          options: ['1 tháng', '100 ngày', 'Lần đầu biết lẫy'],
          save: 'Lưu ảnh PNG',
        },
        journal: {
          initial: 'M',
          name: 'Mẹ',
          time: '12/10 · 21:30',
          text: 'Hôm nay con nhìn theo mẹ cả buổi, cười khúc khích khi nghe mẹ hát.',
          duration: '0:18',
          saved: 'Đã lưu vào dòng thời gian kỷ niệm',
        },
        thenNow: {
          then: '1 tháng',
          now: '12 tháng',
          video: 'Tạo video chuyển cảnh',
          collage: 'Lưu ảnh ghép',
        },
        voice: {
          initial: 'B',
          length: '0:32',
          from: 'Bà nội · lời nhắn giọng nói',
          textInitial: 'Ba',
          textName: 'Ba',
          text: '“Con trai của ba, mỗi ngày bên con là một ngày vui.”',
          privacy: 'Chỉ gia đình nghe được',
        },
        book: {
          cover: ['Năm đầu đời', 'của Teddy'],
          month: 'Tháng 6',
          caption: 'Bữa ăn dặm đầu tiên',
          pdf: 'PDF · 48 trang',
          print: 'Đặt in sách ảnh',
        },
      },
    },
    // v5 (Figma 475:4503). Q-039: the watch app is not released yet.
    watch: {
      eyebrow: 'Apple Watch',
      title: ['Tay bế con,', 'vẫn ghi kịp từng cữ.'],
      lead: 'Ghi bú, ngủ, tã ngay trên đồng hồ chỉ với một chạm — không cần tìm điện thoại.',
      bullets: [
        {
          title: 'Ghi trong một chạm',
          sub: 'Bú bình xoay núm chọn ml, tã ướt hay bẩn chỉ một lần chạm.',
          subShort: 'Xoay núm chọn ml, tã ướt hay bẩn một chạm.',
        },
        {
          title: 'Bấm giờ bú mẹ, ngủ, hút sữa',
          sub: 'Đổi bên, dừng nhanh — kể cả chạm hai ngón khi tay bận.',
          subShort: 'Đổi bên, dừng nhanh khi tay bận.',
        },
        {
          title: 'Nhắc đúng lúc, xem nhanh',
          sub: 'Thông báo có sẵn nút ghi; mặt đồng hồ hiện cữ trước bao lâu.',
          subShort: 'Thông báo có nút ghi; mặt đồng hồ hiện cữ trước.',
        },
        {
          title: 'Không cần điện thoại bên cạnh',
          sub: 'Ghi lưu trên đồng hồ, tự đồng bộ cho cả nhà khi có mạng.',
          subShort: 'Lưu trên đồng hồ, tự đồng bộ khi có mạng.',
        },
      ],
      note: 'Dành cho Apple Watch, đi kèm ứng dụng iPhone',
      mock: {
        baby: 'Teddy',
        time: '9:41',
        tiles: [
          { label: 'Bú bình', value: '2:15', caption: 'từ cữ trước' },
          { label: 'Bú mẹ', value: '3:35', caption: 'từ cữ trước' },
          { label: 'Ngủ', value: '0:42', caption: 'đang ngủ' },
          { label: 'Tã', value: '1:25', caption: 'từ lần trước' },
          { label: 'Hút sữa', value: '5:10', caption: 'từ lần trước' },
          { label: 'Nhắc', value: '17:00', caption: 'nhắc bú' },
        ],
        breast: {
          title: 'Bú mẹ',
          left: 'Trái',
          leftValue: '8:12',
          right: 'Phải',
          rightValue: '4:20',
          total: 'Tổng 12:32 · đang bú bên trái',
          switchSide: 'Đổi bên',
          stop: 'Dừng',
        },
        notify: {
          app: 'CHILD LIFE',
          title: 'Đến giờ nhắc bú bạn đã đặt',
          sub: 'Cữ trước 14:45 · 120 ml',
          log: 'Ghi bú bình 120 ml',
          snooze: 'Nhắc lại sau 15 phút',
        },
      },
    },
    yourWay: {
      eyebrow: 'Theo cách của bạn',
      title: 'Ứng dụng của nhà bạn, theo nhịp của nhà bạn.',
      lead: 'Chỉ hiện những gì bạn cần. Bớt đi những gì bạn không dùng.',
      bullets: [
        {
          title: 'Bật, tắt và sắp xếp màn hình Hôm nay',
          sub: 'Bú bình hay bú mẹ, có hút sữa hay không — tuỳ nhà bạn.',
          subShort: 'Bú bình hay bú mẹ, có hút sữa hay không — tuỳ nhà bạn.',
        },
        {
          title: 'Chế độ đêm',
          sub: 'Màn hình tối, chữ to, ghi nhanh lúc 3 giờ sáng.',
          subShort: 'Màn hình tối, chữ to, ghi nhanh lúc 3 giờ sáng.',
        },
        {
          title: 'Danh mục chi tiêu riêng',
          sub: 'Thêm, sửa, ẩn danh mục cho đúng cách nhà bạn chi.',
          subShort: 'Thêm, sửa, ẩn danh mục cho đúng cách nhà bạn chi.',
        },
      ],
      mock: {
        title: 'Tuỳ chỉnh Hôm nay',
        rows: [
          { title: 'Ô theo dõi nhanh', body: 'Bú, ngủ, tã, hút sữa, tăng trưởng' },
          { title: 'Nhắc nhở sắp tới', body: '3 nhắc đang bật' },
          { title: 'Nhịp trong ngày', body: 'Biểu đồ 24 giờ' },
        ],
        chips: ['Bú bình', 'Bú mẹ', 'Ngủ', 'Thay tã', 'Hút sữa'],
        night: 'Chế độ đêm dịu mắt',
      },
    },
  },
  // Q-039: reminder promises (interval rules, recipients, actions, auto-off) go beyond R-091.
  reminders: {
    eyebrow: 'Nhắc nhở',
    title: 'Nhắc cữ bú, giấc ngủ cho đúng người.',
    lead: 'Đặt nhắc bú, ngủ theo giờ cố định hoặc tự tính từ lần ghi gần nhất. Một người ghi xong, nhắc tự tắt với mọi người.',
    leadShort:
      'Nhắc bú, ngủ theo giờ cố định hoặc tự tính từ lần ghi gần nhất. Một người ghi xong, nhắc tự tắt với mọi người.',
    bullets: [
      {
        title: 'Hai cách nhắc',
        sub: 'Giờ cố định, hoặc sau lần bú, ngủ gần nhất',
        subShort: 'Giờ cố định, hoặc sau lần ghi gần nhất',
      },
      {
        title: 'Chọn ai nhận nhắc',
        sub: 'Ba mẹ và người chăm — không làm phiền ông bà',
        subShort: 'Ba mẹ và người chăm',
      },
      {
        title: 'Xử lý ngay trên thông báo',
        sub: 'Ghi, báo lại sau hoặc bỏ qua chỉ một chạm',
        subShort: 'Ghi, báo lại hoặc bỏ qua',
      },
    ],
    notification: {
      title: 'Đến giờ nhắc bú bạn đã đặt',
      sub: 'Lần bú gần nhất 11:45 · 3 giờ trước',
      subShort: 'Lần bú gần nhất 11:45',
      log: 'Ghi lần bú',
      snooze: 'Báo lại 15 phút',
      snoozeShort: 'Báo lại',
      skip: 'Bỏ qua',
    },
    rule: { title: 'Nhắc bú', sub: '3 giờ sau lần bú gần nhất', next: 'Tiếp theo 14:45' },
    fixed: { title: 'Nhắc chuẩn bị ngủ', times: ['09:00', '13:00', '19:30'] },
    done: 'Ba Tuấn đã ghi lúc 14:52 · nhắc tự tắt',
    doneShort: 'Ba Tuấn đã ghi · nhắc tự tắt',
  },
  understand: {
    eyebrow: 'Hiểu con',
    title: 'Gợi ý theo tuổi: tuần này của bé.',
    lead: 'Gợi ý theo đúng tuổi của con, lịch Wonder Week dự kiến và những mốc đáng nhớ — để bạn bớt lo và tận hưởng nhiều hơn.',
    leadShort: 'Gợi ý theo đúng tuổi, lịch Wonder Week dự kiến và những mốc đáng nhớ.',
    columns: [
      {
        title: 'Gợi ý theo tuổi',
        body: 'Mỗi giai đoạn một thẻ ngắn: bé đang thế nào, ba mẹ có thể thử gì, kèm bài viết và mốc liên quan.',
      },
      {
        title: 'Wonder Week',
        body: 'Lịch dự kiến theo ngày dự sinh, nhắc trước 3 ngày. Đọc bé đang học gì và ghi lại những gì bạn thấy ở con.',
      },
      {
        title: 'Mốc phát triển',
        body: 'Chọn mốc gợi ý hoặc tự tạo mốc riêng như “Lần đầu về quê”. Thêm ảnh, ghi chú — và lưu thành kỷ niệm.',
      },
    ],
    age: {
      chips: ['3–4 tuần', 'Teddy · 3 tuần'],
      title: 'Bé nhìn theo mặt người, nghe giọng quen',
      points: ['Nói chuyện, hát nhẹ khi bé thức', 'Cho bé nằm sấp vài phút, có người lớn bên cạnh'],
      footer: '2 bài viết · 2 mốc thường gặp',
    },
    wonder: {
      badge: 'Wonder Week 1',
      countdown: 'Còn 3 ngày',
      title: 'Cảm giác thay đổi',
      dates: 'Dự kiến tuần 4–5 · 11/10 – 18/10',
      signsLabel: 'Biểu hiện thường gặp',
      signs: ['Quấy hơn', 'Bám ba mẹ', 'Ngủ xáo trộn'],
      learningLabel: 'Bé đang học gì',
      learning: 'Cảm nhận rõ hơn âm thanh, ánh sáng, mùi',
      reminder: 'Nhắc trước 3 ngày',
    },
    milestone: {
      chips: ['Đã quan sát', 'Giao tiếp'],
      title: 'Mỉm cười đáp lại',
      note: '08/10/2026 · Mẹ ghi · “Bé cười khi mẹ hát sau cữ bú sáng.”',
      saved: 'Đã lưu vào Kỷ niệm',
    },
    note: 'Nội dung do đội chuyên môn Child Life soạn và rà soát. Lịch Wonder Week chỉ là dự kiến — mỗi bé có nhịp riêng, app không chấm điểm hay so sánh con.',
    noteShort:
      'Nội dung do đội chuyên môn soạn và rà soát. Lịch Wonder Week chỉ là dự kiến — mỗi bé có nhịp riêng.',
  },
  library: {
    eyebrow: 'Thư viện & ăn dặm',
    title: 'Thư viện chăm bé và ăn dặm.',
    lead: 'Thư viện chăm bé và thư viện ăn dặm do đội chuyên môn soạn, rà soát và cập nhật. Tìm theo chủ đề, độ tuổi — lưu lại để đọc khi cần.',
    leadShort:
      'Do đội chuyên môn soạn và rà soát. Tìm theo chủ đề, độ tuổi — lưu lại để đọc khi cần.',
    bullets: [
      {
        title: 'Tìm và lọc nhanh',
        sub: 'Theo chủ đề, độ tuổi, thời gian đọc',
        subShort: 'Theo chủ đề, độ tuổi',
      },
      {
        title: 'Lưu để đọc lại',
        sub: 'Bài nào được cập nhật, bạn sẽ thấy ngay',
        subShort: 'Bài cập nhật, bạn thấy ngay',
      },
      {
        title: 'Nhật ký ăn dặm',
        sub: 'Bữa ăn, lượng bé ăn và những món bé đã thử',
        subShort: 'Bữa ăn và những món bé đã thử',
      },
    ],
    search: 'Bé hay giật mình khi ngủ…',
    ageChip: '0–3 tháng',
    articles: [
      {
        tag: 'Giấc ngủ',
        title: 'Giấc ngủ của bé sơ sinh',
        meta: '6 phút đọc · đội chuyên môn rà soát',
      },
      {
        tag: 'Ăn dặm · Công thức',
        title: 'Cháo bí đỏ cho bé mới tập',
        meta: '15 phút · 6–7 tháng',
      },
    ],
    articleMetaShort: '6 phút đọc',
    solids: {
      label: 'Ăn dặm hôm nay',
      meal: 'Cháo bí đỏ · 4 thìa',
      triedLabel: 'Món bé đã thử · 14',
      foods: ['Gạo', 'Bí đỏ', 'Cà rốt', 'Bơ', 'Chuối'],
      newFood: 'Khoai lang',
      more: '+8',
      moreShort: '+9',
    },
    saved: 'Đã lưu vào Thư viện',
  },
  firstAid: {
    eyebrow: 'Sơ cấp cứu',
    title: 'Sơ cứu trẻ em: hướng dẫn từng bước.',
    lead: 'Những tình huống nhỏ thường gặp ở trẻ — sốt, ngã, bỏng nhẹ, côn trùng cắn — được giải thích ngắn gọn, nhẹ nhàng để bạn bình tĩnh chăm con.',
    leadShort:
      'Sốt, ngã, bỏng nhẹ, côn trùng cắn — giải thích ngắn gọn, nhẹ nhàng để bạn bình tĩnh chăm con.',
    bullets: [
      {
        title: 'Tình huống thường gặp',
        sub: 'Sốt, ngã, bỏng nhẹ, hóc dị vật, côn trùng cắn…',
        subShort: 'Sốt, ngã, bỏng nhẹ, hóc dị vật, côn trùng cắn…',
      },
      {
        title: 'Từng bước, có hình minh hoạ',
        sub: 'Dễ đọc cả khi đang bế con',
        subShort: 'Dễ đọc cả khi đang bế con',
      },
      {
        title: 'Rà soát cùng chuyên gia y tế',
        sub: 'Luôn nhắc bạn hỏi bác sĩ khi cần',
        subShort: 'Luôn nhắc bạn hỏi bác sĩ khi cần',
      },
    ],
    card: {
      title: 'Sơ cấp cứu',
      sub: 'Hướng dẫn từng bước, dễ làm theo',
      topics: ['Hóc dị vật', 'Sốt', 'Bỏng nhẹ', 'Ngã, va đập', 'Côn trùng cắn', 'Chảy máu cam'],
      step: {
        label: 'Bỏng nhẹ · bước 1/4',
        text: 'Giữ bình tĩnh, làm theo từng bước có hình minh hoạ',
      },
    },
  },
  care: {
    eyebrow: 'Chăm sóc mỗi ngày',
    title: 'Nhật ký một ngày của con, nhìn là hiểu.',
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
    title: 'Cả nhà ghi chung một nhật ký.',
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
    title: 'Ảnh, thiệp, video và nhật ký của con.',
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
    title: 'Chế độ đêm cho những cữ bú khuya.',
    lead: 'Buổi tối, màn hình tự dịu lại: nền tối ấm, chữ to, không chói mắt. Bé ngủ tiếp, bạn cũng dễ ngủ lại.',
    checks: [
      'Tự bật vào giờ bạn chọn, không cần nhớ',
      'Nút to, một tay vẫn bấm được khi đang bế con',
    ],
    sleepWidget: { label: 'Đang ngủ', sub: 'Từ 21:42 · Ba' },
  },
  roles: {
    eyebrow: 'Riêng tư',
    title: 'Bạn chọn ai được xem ảnh và thông tin của con.',
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
      // PROPOSED answers 3–6 (G-065): not in Figma.
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
        q: 'Nội dung gợi ý trong app do ai soạn?',
        a: 'Đội chuyên môn của Child Life soạn, rà soát và cập nhật các thẻ theo tuổi, bài viết và hướng dẫn trong app. Nội dung chỉ để tham khảo, không thay lời khuyên của bác sĩ — khi con có dấu hiệu bất thường, hãy hỏi bác sĩ.',
        open: false,
      },
      {
        q: 'Lịch Wonder Week có đúng với mọi bé không?',
        a: 'Không hẳn. Lịch được tính dự kiến theo ngày dự sinh của con, còn mỗi bé có nhịp riêng — có bé sớm hơn, có bé muộn hơn. App không chấm điểm hay so sánh con, chỉ giúp bạn biết trước để bớt lo.',
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
