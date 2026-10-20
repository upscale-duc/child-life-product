/** Original editorial-month and minimal diptych art for C07/C08/V07/V08. */
import { mkdirSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
const dir = resolve(import.meta.dirname, '../../design/keepsake-art'),
  out = resolve(import.meta.dirname, '../../artifacts/premium48-phase4');
mkdirSync(out, { recursive: true });
const C = { sand: '#EDE0C9', rust: '#B66C45', navy: '#35434D', paper: '#FFFCF6' };
const D = { chalk: '#F8F4EC', lilac: '#B5A2B4', ink: '#48434A', pale: '#E7DEE5' };
const assets: { name: string; family: string; title: string; usage: string; svg: string }[] = [];
function add(
  family: 'chapter' | 'compare',
  name: string,
  title: string,
  usage: string,
  w: number,
  h: number,
  body: string,
) {
  assets.push({
    name: `p48-${family}-${name}`,
    family,
    title,
    usage,
    svg: `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}" preserveAspectRatio="none">${body}</svg>\n`,
  });
}
add(
  'chapter',
  'month-tab',
  'Tab tháng',
  'Nhãn trống cho tháng 01–12 ở layer text riêng.',
  300,
  230,
  `<path d="M18 14h264v195l-30-18-30 18-30-18-30 18-30-18-30 18-30-18-30 18-24-18Z" fill="${C.rust}"/><path d="M34 30h231v142H34Z" fill="none" stroke="${C.sand}" stroke-width="2" opacity=".6"/>`,
);
add(
  'chapter',
  'index-rail',
  'Dải chỉ mục',
  'Mười hai vạch, nhãn tháng được render động; không chữ đóng trong SVG.',
  120,
  700,
  `<path d="M70 24v652" stroke="${C.navy}" stroke-width="2" opacity=".32"/>${Array.from({ length: 12 }, (_, i) => `<path d="M${i % 3 === 0 ? 32 : 45} ${34 + i * 57}h${i % 3 === 0 ? 49 : 36}" stroke="${i % 3 === 0 ? C.rust : C.navy}" stroke-width="${i % 3 === 0 ? 4 : 2}" opacity=".55"/>`).join('')}`,
);
add(
  'chapter',
  'hero-frame',
  'Khung ảnh chủ đạo',
  'Viền trong suốt bất đối xứng nhẹ, ảnh lớn là trung tâm.',
  800,
  920,
  `<path d="M20 900V20h760v880Z" fill="none" stroke="${C.paper}" stroke-width="24"/><path d="M22 21h758v879H22Z" fill="none" stroke="${C.navy}" stroke-width="2"/><path d="M21 920H0V0h800v20" fill="none" stroke="${C.rust}" stroke-width="3"/>`,
);
add(
  'chapter',
  'small-frame',
  'Khung ảnh phụ',
  'Viền gọn để hai ảnh nhỏ giữ cùng tỷ lệ.',
  640,
  460,
  `<rect x="16" y="16" width="608" height="428" fill="none" stroke="${C.paper}" stroke-width="24"/><path d="M16 15h608v430H16Z" fill="none" stroke="${C.navy}" stroke-width="2"/><path d="M34 431h62m446-400h62" stroke="${C.rust}" stroke-width="4"/>`,
);
add(
  'chapter',
  'spine',
  'Gáy album',
  'Khép 8px ở lề, không chuyển động qua mặt.',
  120,
  1000,
  `<path d="M28 12h64v976H28Z" fill="${C.navy}" opacity=".07"/><path d="M44 12v976m22-976v976" stroke="${C.navy}" stroke-width="2" opacity=".35"/><path d="M93 16v968" stroke="${C.paper}" stroke-width="5"/>`,
);
add(
  'chapter',
  'divider',
  'Đường phân cách biên tập',
  'Nối các dòng ghi nhớ, không dùng điểm thành tích.',
  800,
  80,
  `<path d="M18 40h764" stroke="${C.navy}" stroke-width="2"/><path d="M18 40h96" stroke="${C.rust}" stroke-width="7"/><circle cx="782" cy="40" r="5" fill="${C.rust}"/>`,
);
add(
  'chapter',
  'caption-strip',
  'Dải giấy ghi nhớ',
  'Nền nhãn biên tập; giữ chữ VI/EN bên ngoài.',
  780,
  190,
  `<path d="m13 18 752-7 3 163-751 5Z" fill="${C.paper}"/><path d="M29 30v131" stroke="${C.rust}" stroke-width="4"/><path d="M52 160h690" stroke="${C.navy}" stroke-width="1" opacity=".16"/>`,
);
add(
  'chapter',
  'crop-marks',
  'Góc canh trang',
  'Bốn góc mảnh ở ngoài ảnh.',
  800,
  900,
  `<path d="M8 70V8h62m660 0h62v62M8 830v62h62m660 0h62v-62" fill="none" stroke="${C.rust}" stroke-width="3"/>`,
);
add(
  'chapter',
  'folio',
  'Nét gấp trang',
  'Dấu trang hình học; không giả logo hoặc huy hiệu.',
  250,
  220,
  `<path d="m35 25 80 25 100-20v159l-100 17-80-24Z" fill="${C.paper}" stroke="${C.navy}" stroke-width="3"/><path d="M115 50v156m-62-62 44 13m38 3 57-10M53 73l44 13m38 3 57-10" fill="none" stroke="${C.rust}" stroke-width="3" opacity=".6"/>`,
);
add(
  'chapter',
  'masthead-rule',
  'Nét đầu trang',
  'Cặp gạch tạo nhịp như bìa tạp chí.',
  740,
  100,
  `<path d="M16 36h708M16 51h708" stroke="${C.navy}" stroke-width="2"/><path d="M16 36h170" stroke="${C.rust}" stroke-width="6"/>`,
);
add(
  'compare',
  'timeline',
  'Thanh thời gian',
  'Reveal 1.5 giây ở khoảng giấy; không mô tả thay đổi khuôn mặt.',
  900,
  130,
  `<path d="M38 65h824" stroke="${D.lilac}" stroke-width="3"/><circle cx="38" cy="65" r="20" fill="${D.chalk}" stroke="${D.ink}" stroke-width="3"/><circle cx="862" cy="65" r="20" fill="${D.chalk}" stroke="${D.ink}" stroke-width="3"/><circle cx="38" cy="65" r="5" fill="${D.lilac}"/><circle cx="862" cy="65" r="5" fill="${D.lilac}"/>`,
);
for (const after of [false, true])
  add(
    'compare',
    after ? 'anchor-after' : 'anchor-before',
    after ? 'Mốc bây giờ' : 'Mốc ngày ấy',
    'Mốc tròn tĩnh, không kèm huy hiệu hoặc đánh giá ngoại hình.',
    200,
    200,
    `<circle cx="100" cy="100" r="73" fill="${after ? D.pale : D.chalk}" stroke="${D.lilac}" stroke-width="3"/><circle cx="100" cy="100" r="49" fill="none" stroke="${D.ink}" stroke-width="2" opacity=".55"/><circle cx="100" cy="100" r="7" fill="${D.ink}"/>`,
  );
add(
  'compare',
  'photo-corners',
  'Góc giữ ảnh giấy',
  'Bốn góc mảnh, giữ hai ảnh cùng vai trò.',
  700,
  900,
  `<path d="M16 85V16h69m530 0h69v69M16 815v69h69m530 0h69v-69" fill="none" stroke="${D.chalk}" stroke-width="24"/><path d="M17 84V17h67m532 0h67v67M17 816v67h67m532 0h67v-67" fill="none" stroke="${D.lilac}" stroke-width="3"/>`,
);
add(
  'compare',
  'paper-wipe',
  'Tờ giấy chuyển khung',
  'Graphic wipe chỉ trong vùng khung ảnh; không morph.',
  700,
  900,
  `<path d="m11 8 675 5-4 878-674-4Z" fill="${D.chalk}"/><path d="M661 18v862" stroke="${D.lilac}" stroke-width="3" opacity=".7"/><path d="M674 23v852" stroke="${D.ink}" stroke-width="2" opacity=".15"/>`,
);
add(
  'compare',
  'matched-frame',
  'Viền ảnh ngang hàng',
  'Hai ảnh dùng cùng hình và kích thước.',
  700,
  900,
  `<rect x="20" y="20" width="660" height="860" fill="none" stroke="#FFFDF9" stroke-width="30"/><rect x="20" y="20" width="660" height="860" fill="none" stroke="${D.ink}" stroke-width="2"/><path d="M38 39h624v822" fill="none" stroke="${D.lilac}" stroke-width="2" opacity=".3"/>`,
);
add(
  'compare',
  'date-tag',
  'Nhãn thời điểm',
  'Nền nhãn ngày; khi ngày chưa rõ chỉ hiện Then / Now.',
  600,
  150,
  `<path d="M14 15h572v120H14Z" fill="#FFFDF9"/><path d="M14 134h572" stroke="${D.lilac}" stroke-width="3"/><path d="M32 35v76" stroke="${D.ink}" stroke-width="2" opacity=".3"/>`,
);
add(
  'compare',
  'join-line',
  'Nét nối hai mốc',
  'Nét nối trung tính, không có mũi tên tiến bộ.',
  200,
  700,
  `<path d="M100 22v656" stroke="${D.lilac}" stroke-width="2"/><circle cx="100" cy="22" r="10" fill="${D.chalk}" stroke="${D.ink}" stroke-width="2"/><circle cx="100" cy="678" r="10" fill="${D.chalk}" stroke="${D.ink}" stroke-width="2"/>`,
);
add(
  'compare',
  'paired-bracket',
  'Ngoặc đôi',
  'Hai nét đối xứng, nhấn kết nối thay vì đánh giá.',
  650,
  200,
  `<path d="M35 30H17v140h18M615 30h18v140h-18" fill="none" stroke="${D.lilac}" stroke-width="3"/><path d="M90 100h470" stroke="${D.lilac}" stroke-width="2" stroke-dasharray="2 9"/><circle cx="325" cy="100" r="7" fill="${D.ink}"/>`,
);
add(
  'compare',
  'paper-edge',
  'Mép giấy cặp ảnh',
  'Chi tiết mỏng ở rìa, giữ vùng ảnh trong suốt.',
  120,
  900,
  `<path d="m66 12 8 48-9 43 8 47-7 46 9 45-8 45 8 48-9 44 8 47-7 46 8 45-9 48 8 43-7 48 8 47-9 43 7 43-30-2V12Z" fill="${D.pale}" opacity=".6"/><path d="M45 14v866" stroke="${D.lilac}" stroke-width="2" opacity=".5"/>`,
);
for (const a of assets) writeFileSync(join(dir, `${a.name}.svg`), a.svg);
writeFileSync(
  join(dir, 'premium48-phase4-manifest.json'),
  JSON.stringify(
    {
      version: 1,
      createdOn: '2026-10-20',
      licence: 'Original Child Life vector artwork',
      assets: assets.map((a) => ({
        name: a.name,
        family: a.family,
        title: a.title,
        usage: a.usage,
        file: `${a.name}.svg`,
        templates: a.family === 'chapter' ? ['C07', 'V07'] : ['C08', 'V08'],
      })),
    },
    null,
    2,
  ) + '\n',
);
writeFileSync(join(out, 'assets.json'), JSON.stringify(assets, null, 2));
writeFileSync(
  join(out, 'assets.html'),
  `<!doctype html><html lang="vi"><meta charset="utf-8"><title>Phase 4 · Original assets</title><style>body{background:#faf7f1;color:#35434D;font:16px system-ui;max-width:1300px;margin:48px auto;padding:24px}h1,h2{font-family:Georgia}.grid{display:grid;grid-template-columns:repeat(5,1fr);gap:20px}article{background:#fffdf9;border:1px solid #e3d8c8;padding:16px;border-radius:12px}.art{height:210px;display:flex;align-items:center;justify-content:center}.art svg{max-width:100%;max-height:200px;width:auto;height:auto}h3{font-size:15px}p{font-size:13px;line-height:1.6}code{font-size:9px}</style><small>CHILD LIFE / PREMIUM 48 / PHASE 04</small><h1>Một trang tháng. Hai khoảnh khắc.</h1><p>20 vector mới · C07/C08/V07/V08 · Số tháng và ngày là text riêng.</p>${[
    'chapter',
    'compare',
  ]
    .map(
      (f) =>
        `<h2>${f === 'chapter' ? 'Trang tháng / Your Monthly Chapter' : 'Ngày ấy, bây giờ / Then & Now'}</h2><div class="grid">${assets
          .filter((a) => a.family === f)
          .map(
            (a) =>
              `<article><div class="art">${a.svg}</div><h3>${a.title}</h3><p>${a.usage}</p><code>${a.name}</code></article>`,
          )
          .join('')}</div>`,
    )
    .join('')}</html>`,
);
console.log(`Drew ${assets.length} original phase 4 SVG assets.`);
