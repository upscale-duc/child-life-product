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
      journey: 'Hành trình',
      firstYear: 'Năm đầu đời',
      watch: 'Apple Watch',
      stages: 'Các chặng',
      memories: 'Kỷ niệm',
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
    push: { app: 'CHILD LIFE', now: 'bây giờ' },
  },
  hero: {
    eyebrow: 'Miễn phí cho cả gia đình',
    title: ['Cùng chăm con.', 'Giữ từng khoảnh khắc', 'con lớn lên.'],
    lead: 'Một không gian riêng tư cho cả nhà: ghi bú, ngủ trong một chạm, nhắc đúng lúc, gợi ý theo từng tuần tuổi — và giữ lại mọi khoảnh khắc con lớn lên.',
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
  // v3 home + stage pages (Figma 358:2901 / 362:3398, 370:50752, 361:3457 / 3575 / 3693).
  // Q-039: stages 2–4 describe features beyond the V1 scope.
  journey: {
    label: 'Hành trình',
    number: 'Chặng {n}',
    prevNextLabel: 'Các chặng',
    highlightsTitle: 'Ở chặng này, Child Life cùng ba mẹ',
    prev: '← Chặng trước',
    next: 'Chặng tiếp theo →',
    backLabel: 'Quay lại',
    backTitle: 'Toàn bộ hành trình',
    ctaTitle: ['Bắt đầu hành trình cùng con', 'ngay hôm nay.'],
    stages: [
      {
        name: 'Những ngày đầu đời',
        ages: '0–12 tháng',
        title: 'Những ngày đầu đời.',
        lead: 'Làm quen với nhau qua từng cữ bú, giấc ngủ — và giữ lại những lần đầu tiên của con.',
        chips: ['Chăm con mỗi ngày', 'Hiểu từng tuần tuổi', 'Lưu giữ khoảnh khắc'],
        highlights: null,
        quote: null,
      },
      {
        name: 'Con tập khám phá',
        ages: '1–3 tuổi',
        title: 'Con tập khám phá.',
        lead: 'Cùng con chập chững, bập bẹ những từ đầu tiên và tập những thói quen nhỏ.',
        chips: ['Nếp sinh hoạt', 'Chơi & vận động', 'Từ đầu tiên'],
        highlights: [
          {
            title: 'Những bước chân đầu tiên',
            body: 'Ghi lại khi con chập chững, bập bẹ từ đầu tiên và những chuyến đi xa đầu đời.',
          },
          {
            title: 'Nếp nhỏ mỗi ngày',
            body: 'Cả nhà cùng nắm giờ ăn, giờ ngủ của con, nhẹ nhàng tập những thói quen đầu tiên.',
          },
          {
            title: 'Chơi cùng con',
            body: 'Những ý tưởng chơi, vận động và trò chuyện vừa với tuổi của con.',
          },
        ],
        quote: 'Những bước chân đầu tiên, những lần cả nhà vỡ oà — đều đáng được giữ lại.',
      },
      {
        name: 'Tò mò và lớn khôn',
        ages: '3–6 tuổi',
        title: 'Tò mò và lớn khôn.',
        lead: 'Cùng con chơi, đọc, vẽ và trả lời những câu hỏi “vì sao” không ngừng.',
        chips: ['Học qua chơi', 'Cảm xúc', 'Tác phẩm của con'],
        highlights: [
          {
            title: 'Học qua chơi',
            body: 'Cùng con đọc truyện, vẽ tranh và làm những món đồ nhỏ xinh.',
          },
          {
            title: 'Những câu hỏi “vì sao”',
            body: 'Giữ lại điều con tò mò và những câu nói ngộ nghĩnh của con.',
          },
          {
            title: 'Lớn khôn từng chút',
            body: 'Cùng con tập tự làm và gọi tên những cảm xúc của mình.',
          },
        ],
        quote: 'Mỗi câu hỏi “vì sao” của con là một kỷ niệm nhỏ, đáng được lưu lại.',
      },
      {
        name: 'Thế giới riêng của con',
        ages: '6–12 tuổi',
        title: 'Thế giới riêng của con.',
        lead: 'Đồng hành nhẹ nhàng khi con tự lập, có sở thích và những ước mơ riêng.',
        chips: ['Sở thích', 'Tự lập', 'Nhìn lại hành trình'],
        highlights: [
          {
            title: 'Điều con yêu thích',
            body: 'Lưu lại sở thích, dự án và những thành quả con tự hào.',
          },
          {
            title: 'Tự lập theo cách của con',
            body: 'Cả nhà cùng đặt mục tiêu nhỏ, con chủ động thực hiện.',
          },
          {
            title: 'Khoảng riêng của con',
            body: 'Đồng hành mà vẫn tôn trọng thế giới riêng con đang lớn dần.',
          },
        ],
        quote: 'Con có thế giới riêng rồi. Ba mẹ vẫn ở đây, mỗi khi con cần.',
      },
    ],
  },
  home: {
    hero: {
      eyebrow: 'Child Life · Hành trình lớn lên',
      title: ['Cùng con lớn lên,', 'đồng hành từng bước.'],
      lead: 'Hệ sinh thái giúp cha mẹ chăm sóc, thấu hiểu và đồng hành cùng con — từ những ngày đầu đời đến khi trưởng thành.',
      promises: [
        'Chăm sóc con mỗi ngày, cả nhà cùng phối hợp',
        'Thấu hiểu con qua từng giai đoạn lớn lên',
        'Đồng hành và lưu giữ hành trình của con',
      ],
      explore: 'Xem hành trình của con',
      art: {
        feed: { title: 'Bú bình · 120 ml', sub: 'Mẹ ghi · 2 phút trước' },
        smile: { title: 'Lần đầu con cười', sub: 'Đã lưu vào Kỷ niệm' },
        love: 'Bà nội thương ảnh của Teddy',
      },
    },
    chapters: {
      eyebrow: 'Hành trình lớn lên',
      title: 'Đi cùng con qua từng chặng.',
      lead: 'Mỗi giai đoạn con lớn lên, Child Life cùng ba mẹ chăm con, hiểu con và giữ lại những điều đáng nhớ.',
      available: 'Có trên app',
      explore: 'Khám phá năm đầu đời',
      view: 'Xem chặng này',
    },
    firstYear: {
      eyebrow: 'Chặng 1 · Năm đầu đời',
      title: 'Năm đầu đời của con, nhẹ nhàng hơn cho cả nhà.',
      lead: 'Chăm con mỗi ngày, hiểu con từng tuần và giữ lại những lần đầu tiên — tất cả trong một ứng dụng.',
      leadShort: 'Chăm con mỗi ngày, hiểu con từng tuần và giữ lại những lần đầu tiên.',
      more: 'Xem chi tiết năm đầu đời',
      detail: {
        eyebrow: 'Chặng 1 · 0–12 tháng',
        title: 'Xem đầy đủ năm đầu đời',
        body: 'Từng phần chi tiết: ghi nhanh, nhắc nhở, lịch tiêm, ăn dặm, sơ cứu, chế độ đêm và quyền xem của cả nhà.',
      },
    },
    // v5b (Figma 475:3726, 2026-10-13). Q-039: stages 2–4 and the keepsake products are not in V1.
    stages: {
      eyebrow: 'Các chặng tiếp theo',
      title: 'Con lớn, Child Life lớn theo con.',
      lead: 'Sau năm đầu đời, mỗi chặng mang đến cách chăm mới, điều mới cần để ý và những kỷ niệm mới. Các chặng này đang được chuẩn bị.',
      firstName: 'Năm đầu đời',
      current: 'đang có',
      soon: 'Sắp ra mắt',
      preview: 'Xem trước chặng {n}',
    },
    keepsakes: {
      eyebrow: 'Kỷ niệm của con',
      title: 'Không chỉ để lưu, mà để kể lại.',
      lead: 'Video, thiệp, nhật ký, lời nhắn và cả một cuốn sách — tạo từ chính ảnh và câu chữ của gia đình bạn.',
      cards: [
        {
          format: 'Video MP4',
          title: 'Câu chuyện kỷ niệm',
          body: 'Video kỷ niệm theo mẫu có sẵn, kết hợp ảnh, chữ, nhạc và các cột mốc của con.',
        },
        {
          format: 'Ảnh PNG/JPG',
          title: 'Phép màu cột mốc',
          body: 'Thiệp cột mốc thật đẹp: tròn 1 tháng, 100 ngày, lần đầu biết lẫy… lưu ảnh hoặc gửi cho cả nhà.',
        },
        {
          format: 'Nhật ký',
          title: 'Khoảnh khắc nhỏ',
          body: 'Một bài viết ngắn kèm ảnh hoặc video, lưu thẳng vào dòng thời gian kỷ niệm của con.',
        },
        {
          format: 'Ảnh / Video',
          title: 'Ngày ấy và bây giờ',
          body: 'So sánh ảnh của con ở hai thời điểm, có thể tạo video chuyển cảnh từ ngày ấy sang bây giờ.',
        },
        {
          format: 'Giọng nói + chữ',
          title: 'Lời yêu thương của gia đình',
          body: 'Lời nhắn bằng giọng nói hoặc chữ từ ba mẹ, ông bà — giữ lại để con nghe khi lớn.',
        },
        {
          format: 'PDF / Sách ảnh in',
          title: 'Sách năm đầu đời',
          body: 'Cuốn sách tổng hợp hành trình 12 tháng đầu đời của con — tải PDF hoặc đặt in thành sách ảnh.',
        },
      ],
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
    growUp: {
      eyebrow: 'Một hồ sơ, lớn lên cùng con',
      title: 'Những gì bạn lưu hôm nay, con sẽ còn xem lại khi lớn.',
      body: 'Từ sinh nhật đầu tiên đến ngày con vào lớp 1, rồi những ước mơ tuổi 12 — hành trình của con nằm trọn ở một nơi, không mất đi khi con lớn.',
      bodyShort: 'Từ sinh nhật đầu tiên đến những ước mơ tuổi 12 — tất cả ở một nơi.',
      years: [
        { year: '1 tuổi', caption: '2027 · Sinh nhật đầu tiên' },
        { year: '6 tuổi', caption: '2032 · Ngày đầu vào lớp 1' },
        { year: '12 tuổi', caption: '2038 · Những ước mơ riêng' },
      ],
    },
    faq: {
      items: [
        {
          q: 'Child Life là gì?',
          a: 'Hệ sinh thái giúp cha mẹ chăm sóc, thấu hiểu và đồng hành cùng con qua từng chặng lớn lên. Ứng dụng hiện tập trung vào năm đầu đời của con.',
          open: true,
        },
        {
          q: 'Child Life dành cho bé mấy tuổi?',
          a: 'Từ ngày con chào đời. Năm đầu, app giúp cả nhà chăm con mỗi ngày; những chặng tiếp theo sẽ cùng con lớn lên đến tuổi trưởng thành.',
          open: true,
        },
        // PROPOSED answers 3–9 (G-065): not in Figma.
        {
          q: 'Khi con lớn, ảnh và hồ sơ của con có còn không?',
          a: 'Còn. Ảnh, video và câu chuyện của con ở lại trong gia đình bạn cho đến khi chính bạn xoá, và bạn có thể tải về bất cứ lúc nào.',
          open: false,
        },
        {
          q: 'Có mất phí không?',
          a: 'Không. Cả gia đình dùng miễn phí, đủ chỗ cho hàng nghìn ảnh của con. Cần thêm chỗ, bạn chỉ cần nhắn cho chúng tôi.',
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
          q: 'Sơ cứu trong app có thay thế bác sĩ không?',
          a: 'Không. Hướng dẫn sơ cứu trong app chỉ để tham khảo khi chờ hỗ trợ y tế, không thay thế chẩn đoán của bác sĩ. Khi con nguy kịch, hãy gọi 115 ngay.',
          open: false,
        },
        {
          q: 'Ai xem được chi tiêu của gia đình?',
          a: 'Mặc định chỉ ba mẹ (thành viên Cùng nuôi) thấy chi tiêu. Ba mẹ có thể cho người khác ghi khoản mình đã chi, hoặc xem toàn bộ, trong phần Gia đình.',
          open: false,
        },
        {
          q: 'Có dùng Child Life trên Apple Watch được không?',
          a: 'Có, nếu bạn dùng iPhone. Kết nối đồng hồ một lần từ ứng dụng trên iPhone, sau đó bạn ghi bú, ngủ, thay tã và bấm giờ ngay trên Apple Watch, kể cả khi điện thoại không ở bên cạnh. Hiện chưa có ứng dụng cho đồng hồ Android.',
          open: false,
        },
      ],
    },
    // Chặng 1 frame (Figma 524:4030). Q-039: some claims go beyond the app (22 §12, 28 §12).
    utilities: {
      title: 'Tiện ích cho ba mẹ',
      lead: 'Những thứ nhỏ giúp ngày làm cha mẹ nhẹ hơn — có sẵn trong tab Tiện ích.',
      cards: [
        {
          title: 'Sơ cứu trẻ em',
          body: '25 tình huống thường gặp, từng bước có hình minh hoạ, đọc to hướng dẫn. Dùng được cả khi không có mạng.',
        },
        {
          title: 'Sổ chi tiêu chung cho bé',
          body: 'Mọi khoản chi cho con ở một chỗ. Ba và mẹ cùng ghi, cùng xem một sổ như nhau — biết con cần gì, cả nhà đã lo đến đâu.',
        },
      ],
      spending: {
        header: 'Chi cho Teddy · tháng này',
        total: '4.215.000 ₫',
        split: [
          { label: 'Mẹ ghi', amount: '2.320.000 ₫' },
          { label: 'Ba ghi', amount: '1.895.000 ₫' },
        ],
        initials: ['M', 'B'],
        together: 'Ba và mẹ cùng xem như nhau',
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
  // v3 sections (Figma 321:1222 / 324:45487). Mobile wording in the *Short keys.
  everything: {
    eyebrow: 'Tất cả trong một app',
    title: 'Mọi điều về con, ở cùng một nơi.',
    lead: 'Từ cữ bú lúc nửa đêm đến lần đầu con cười — ghi lại thật nhanh, hiểu con hơn mỗi tuần và giữ trọn tuổi thơ của con.',
    leadShort: 'Ghi lại thật nhanh, hiểu con hơn mỗi tuần và giữ trọn tuổi thơ của con.',
    tiles: [
      {
        title: 'Ghi trong một chạm',
        body: 'Bú, ngủ, tã — ngay trên màn hình chính, cả khi đang bế con.',
        bodyShort: 'Bú, ngủ, tã ngay trên màn hình chính',
      },
      {
        title: 'Nhắc đúng lúc',
        body: 'Nhắc bú, ngủ theo giờ cố định hoặc sau lần ghi gần nhất.',
        bodyShort: 'Giờ cố định hoặc sau lần ghi gần nhất',
      },
      {
        title: 'Cả nhà cùng chăm',
        body: 'Ba mẹ, người chăm, ông bà — ai cũng biết con vừa thế nào.',
        bodyShort: 'Ai cũng biết con vừa thế nào',
      },
      {
        title: 'Hiểu con theo tuần',
        body: 'Thẻ theo tuổi và lịch Wonder Week dự kiến cho từng giai đoạn.',
        bodyShort: 'Thẻ theo tuổi & Wonder Week',
      },
      {
        title: 'Mốc phát triển',
        body: 'Ghi lại lần đầu con cười, lẫy, ngồi — kèm ảnh và ghi chú.',
        bodyShort: 'Lần đầu cười, lẫy, ngồi…',
      },
      {
        title: 'Thư viện chăm bé',
        body: 'Bài viết ngắn về bú, ngủ, mọc răng, sốt — đội chuyên môn rà soát.',
        bodyShort: 'Đội chuyên môn rà soát',
      },
      {
        title: 'Ăn dặm nhẹ nhàng',
        body: 'Nhật ký bữa ăn, món bé đã thử và công thức cho từng giai đoạn.',
        bodyShort: 'Nhật ký & công thức',
      },
      {
        title: 'Giữ trọn tuổi thơ',
        body: 'Ảnh, video và câu chuyện của con — riêng tư cho người nhà.',
        bodyShort: 'Ảnh, video, câu chuyện',
      },
    ],
    logChips: ['Bú bình · 120 ml', 'Đang ngủ 1:27'],
    notification: { title: 'Đến giờ nhắc bú bạn đã đặt', sub: 'Lần bú gần nhất 11:45' },
    familyChip: 'Ba Tuấn vừa ghi thay tã',
    weekChips: ['3 tuần tuổi', 'Wonder Week 1 · còn 3 ngày'],
    milestone: { title: 'Mỉm cười đáp lại', sub: 'Đã quan sát · 08/10' },
    topics: ['Giấc ngủ', 'Mọc răng', 'Bú & sữa'],
    foods: ['Bí đỏ', 'Cà rốt', 'Bơ'],
    moreFoods: '+11 món',
  },
  // Q-039: reminder promises (interval rules, recipients, actions, auto-off) go beyond R-091.
  reminders: {
    eyebrow: 'Nhắc nhở',
    title: 'Nhắc đúng lúc, cả nhà cùng biết.',
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
        sub: 'Bố mẹ và người chăm — không làm phiền ông bà',
        subShort: 'Bố mẹ và người chăm',
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
    title: 'Hiểu con hơn, mỗi tuần một chút.',
    lead: 'Gợi ý theo đúng tuổi của con, lịch Wonder Week dự kiến và những mốc đáng nhớ — để bạn bớt lo và tận hưởng nhiều hơn.',
    leadShort: 'Gợi ý theo đúng tuổi, lịch Wonder Week dự kiến và những mốc đáng nhớ.',
    columns: [
      {
        title: 'Thẻ theo tuổi',
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
    title: 'Băn khoăn gì, có bài đọc ngắn và dễ hiểu.',
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
    title: 'Khi con gặp chuyện bất ngờ, bạn đã có sẵn hướng dẫn.',
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
