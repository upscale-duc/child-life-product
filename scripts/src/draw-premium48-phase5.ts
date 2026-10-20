/** Original textile-memory and sunshine artwork. No embedded copy or third-party clipart. */
import { mkdirSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
const dir = resolve(import.meta.dirname, '../../design/keepsake-art'),
  out = resolve(import.meta.dirname, '../../artifacts/premium48-phase5');
mkdirSync(out, { recursive: true });
const cotton = '#F7F1E6',
  denim = '#7E94A2',
  ochre = '#BA9652',
  vanilla = '#FFF2CD',
  coral = '#D5826D',
  plum = '#684D60';
const assets: { name: string; family: string; title: string; usage: string; svg: string }[] = [];
function add(
  family: 'wardrobe' | 'smile',
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
  'wardrobe',
  'hanger',
  'Móc áo gỗ',
  'Nét móc áo ở lề; giữ ngoài khuôn mặt.',
  400,
  260,
  `<path d="M190 77c-40-51 47-79 53-29 2 19-37 24-37 46v21" fill="none" stroke="${ochre}" stroke-width="11" stroke-linecap="round"/><path d="m206 114 171 101c9 7 4 22-8 22H32c-13 0-18-15-7-23Z" fill="${ochre}"/><path d="m62 215 144-78 129 78Z" fill="${cotton}"/>`,
);
add(
  'wardrobe',
  'fabric-label',
  'Nhãn vải',
  'Nền nhãn trống; tên món đồ và ngày là text riêng.',
  800,
  150,
  `<path d="M9 12h782v126H9Z" fill="#FFFCF7" stroke="${denim}" stroke-width="2"/><path d="M23 26h754v98H23Z" fill="none" stroke="${denim}" stroke-width="2" stroke-dasharray="7 8"/><path d="M45 14v122m710-122v122" stroke="${ochre}" stroke-width="2" opacity=".5"/>`,
);
add(
  'wardrobe',
  'thread-route',
  'Sợi chỉ nối ký ức',
  'Nét cong không số đo; nối mép các khung ảnh.',
  160,
  800,
  `<path d="M85 12C-6 111 155 167 78 265S-8 404 80 490s81 181 0 296" fill="none" stroke="${denim}" stroke-width="4" stroke-linecap="round" stroke-dasharray="9 10"/>`,
);
add(
  'wardrobe',
  'stitch-frame',
  'Viền chỉ may',
  'Giữa khung trong suốt; không thước phát triển.',
  800,
  900,
  `<rect x="14" y="14" width="772" height="872" rx="12" fill="none" stroke="#FFFCF7" stroke-width="25"/><rect x="15" y="15" width="770" height="870" rx="12" fill="none" stroke="${denim}" stroke-width="3" stroke-dasharray="8 10"/><path d="m30 38 17-17m706 858 17-17" stroke="${ochre}" stroke-width="4"/>`,
);
add(
  'wardrobe',
  'memory-box',
  'Ô hộp ký ức',
  'Hộp giấy chỉ mở ở viền, không phủ lên ảnh.',
  800,
  700,
  `<path d="M20 100h760v576H20Z" fill="none" stroke="${denim}" stroke-width="5"/><path d="m20 100 82-78h594l84 78M102 22v77m594-77v77" fill="none" stroke="${ochre}" stroke-width="5"/><path d="M46 128h708v521H46Z" fill="none" stroke="${denim}" stroke-width="2" stroke-dasharray="8 10"/><path d="M340 659h120" stroke="${ochre}" stroke-width="8" stroke-linecap="round"/>`,
);
add(
  'wardrobe',
  'box-lid',
  'Nắp hộp giấy',
  'Mở nhẹ theo cạnh; không xoay ảnh.',
  800,
  140,
  `<path d="m22 99 70-77h616l70 77Z" fill="${cotton}" stroke="${ochre}" stroke-width="4"/><path d="M22 100h756v22H22Z" fill="${denim}" opacity=".3"/><path d="M94 23h612" stroke="#FFFCF7" stroke-width="5"/>`,
);
add(
  'wardrobe',
  'folded-cloth',
  'Nếp vải gấp',
  'Vải gấp hình học ở vùng giấy trống.',
  420,
  300,
  `<path d="m30 90 91-65 258 25v192l-91 35L30 243Z" fill="${denim}" opacity=".28"/><path d="m30 90 258 26 91-66M288 116v161M56 219l206 19m-205-97 205 22" fill="none" stroke="${denim}" stroke-width="4"/><path d="m93 47 249 27" stroke="${ochre}" stroke-width="4" stroke-dasharray="9 9"/>`,
);
add(
  'wardrobe',
  'button-pair',
  'Hai nút áo',
  'Chi tiết may mặc, không huy hiệu.',
  250,
  180,
  `<circle cx="77" cy="84" r="55" fill="${cotton}" stroke="${ochre}" stroke-width="4"/><circle cx="187" cy="110" r="42" fill="${cotton}" stroke="${denim}" stroke-width="3"/>${[
    [65, 73],
    [89, 73],
    [65, 97],
    [89, 97],
    [177, 101],
    [197, 101],
    [177, 119],
    [197, 119],
  ]
    .map(([x, y]) => `<circle cx="${x}" cy="${y}" r="4" fill="${denim}"/>`)
    .join('')}`,
);
add(
  'wardrobe',
  'date-tab',
  'Tab ngày cất',
  'Nhãn nhỏ trống cho ngày tùy chọn.',
  520,
  150,
  `<path d="M16 14h487v121H16l18-60Z" fill="#FFFCF7" stroke="${denim}" stroke-width="2"/><circle cx="57" cy="75" r="7" fill="none" stroke="${ochre}" stroke-width="3"/><path d="M82 116h391" stroke="${denim}" stroke-width="2" stroke-dasharray="6 8"/>`,
);
add(
  'wardrobe',
  'seam-divider',
  'Đường may cuối trang',
  'Đường chỉ gọn chia ảnh và lời nhắn.',
  850,
  80,
  `<path d="M12 40h826" stroke="${denim}" stroke-width="2" stroke-dasharray="8 8"/><path d="m398 26 27 28 27-28" fill="none" stroke="${ochre}" stroke-width="3"/>`,
);
add(
  'smile',
  'sun-arc',
  'Cung mặt trời',
  'Cung và tia nằm sau viền ảnh, không che mặt.',
  900,
  380,
  `<path d="M130 350a320 320 0 0 1 640 0" fill="none" stroke="${coral}" stroke-width="4"/>${Array.from(
    { length: 13 },
    (_, i) => {
      const a = Math.PI + (i / 12) * Math.PI;
      const x = 450 + 363 * Math.cos(a),
        y = 350 + 363 * Math.sin(a),
        xx = 450 + 394 * Math.cos(a),
        yy = 350 + 394 * Math.sin(a);
      return `<path d="M${x.toFixed(1)} ${y.toFixed(1)} ${xx.toFixed(1)} ${yy.toFixed(1)}" stroke="${coral}" stroke-width="5" stroke-linecap="round"/>`;
    },
  ).join('')}`,
);
add(
  'smile',
  'sun-frame',
  'Khung nắng',
  'Viền ảnh sáng; vùng ảnh luôn trong suốt.',
  800,
  900,
  `<rect x="18" y="18" width="764" height="864" rx="9" fill="none" stroke="#FFFCF4" stroke-width="28"/><rect x="18" y="18" width="764" height="864" rx="9" fill="none" stroke="${plum}" stroke-width="2"/><path d="M38 864h145m434-828h145" stroke="${coral}" stroke-width="4"/>`,
);
add(
  'smile',
  'smile-curve',
  'Nét cong nụ cười',
  'Một nét ở dưới ảnh, không đặt trên mặt.',
  600,
  120,
  `<path d="M30 22q270 150 540 0" fill="none" stroke="${coral}" stroke-width="5" stroke-linecap="round"/><circle cx="30" cy="22" r="6" fill="${plum}"/><circle cx="570" cy="22" r="6" fill="${plum}"/>`,
);
add(
  'smile',
  'ray-fan',
  'Quạt tia nắng',
  'Mở 18 frame khi ảnh cười hiện, không nhấp nháy.',
  400,
  400,
  `${Array.from({ length: 9 }, (_, i) => {
    const a = -Math.PI * 0.88 + i * Math.PI * 0.1;
    return `<path d="M${200 + 110 * Math.cos(a)} ${300 + 110 * Math.sin(a)} ${200 + 180 * Math.cos(a)} ${300 + 180 * Math.sin(a)}" stroke="${coral}" stroke-width="6" stroke-linecap="round"/>`;
  }).join('')}`,
);
add(
  'smile',
  'quiet-ring',
  'Vòng nắng yên',
  'Khung cảnh mở tĩnh; không animate trước nụ cười.',
  500,
  500,
  `<circle cx="250" cy="250" r="202" fill="none" stroke="${coral}" stroke-width="3" opacity=".5"/><path d="M250 31a219 219 0 0 1 219 219" fill="none" stroke="${plum}" stroke-width="2" opacity=".25"/>`,
);
add(
  'smile',
  'caption-paper',
  'Giấy ghi nụ cười',
  'Dải giấy ngắn cho câu kết và ngày.',
  800,
  200,
  `<path d="m14 18 771-6 3 174-774 2Z" fill="#FFFCF4"/><path d="M35 167h730" stroke="${coral}" stroke-width="2"/><path d="M35 38h42" stroke="${plum}" stroke-width="4"/>`,
);
add(
  'smile',
  'reaction-bracket',
  'Ngoặc ghép phản ứng',
  'Kết nối ảnh phản ứng và ảnh cười.',
  300,
  500,
  `<path d="M55 22H28v456h27m190-456h27v456h-27" fill="none" stroke="${coral}" stroke-width="4"/><path d="M90 250h120" stroke="${plum}" stroke-width="2" stroke-dasharray="3 10"/>`,
);
add(
  'smile',
  'day-tab',
  'Tab ngày',
  'Nhãn ngày nhỏ; bỏ khi không biết ngày.',
  550,
  140,
  `<rect x="12" y="12" width="526" height="116" rx="58" fill="${vanilla}" stroke="${coral}" stroke-width="2"/><path d="M40 70h40m390 0h40" stroke="${plum}" stroke-width="3"/>`,
);
add(
  'smile',
  'soft-speckles',
  'Hạt giấy nắng',
  'Chấm tĩnh thưa ở ngoài vùng ảnh.',
  600,
  600,
  `${[
    [30, 50, 5],
    [100, 150, 3],
    [550, 40, 5],
    [520, 290, 3],
    [50, 480, 4],
    [580, 570, 6],
    [240, 25, 3],
    [320, 580, 3],
    [20, 310, 3],
    [450, 80, 3],
    [120, 570, 3],
    [570, 420, 3],
  ]
    .map(([x, y, r]) => `<circle cx="${x}" cy="${y}" r="${r}" fill="${coral}" opacity=".38"/>`)
    .join('')}`,
);
add(
  'smile',
  'closing-rays',
  'Nắng cuối trang',
  'Ba tia tĩnh ở cạnh logo/câu kết.',
  400,
  180,
  `<path d="M115 147 92 93m108 45V40m86 108 31-53" stroke="${coral}" stroke-width="5" stroke-linecap="round"/><path d="M150 167q50-32 100 0" fill="none" stroke="${plum}" stroke-width="3"/>`,
);
for (const a of assets) writeFileSync(join(dir, a.name + '.svg'), a.svg);
writeFileSync(
  join(dir, 'premium48-phase5-manifest.json'),
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
        file: a.name + '.svg',
        templates: a.family === 'wardrobe' ? ['C09', 'V09'] : ['C10', 'V10'],
      })),
    },
    null,
    2,
  ) + '\n',
);
writeFileSync(join(out, 'assets.json'), JSON.stringify(assets, null, 2));
writeFileSync(
  join(out, 'assets.html'),
  `<!doctype html><html lang="vi"><meta charset="utf-8"><title>Phase 5 · Original artwork</title><style>body{background:#faf7f1;color:#3f5059;font:16px system-ui;max-width:1300px;margin:48px auto;padding:24px}.grid{display:grid;grid-template-columns:repeat(5,1fr);gap:20px}article{background:#fffdf9;border:1px solid #e3d8c8;padding:16px;border-radius:12px}.art{height:210px;display:flex;align-items:center;justify-content:center}.art svg{max-width:100%;max-height:200px;width:auto;height:auto}h3{font-size:15px}p{font-size:13px;line-height:1.6}code{font-size:9px}</style><small>CHILD LIFE / PREMIUM 48 / PHASE 05</small><h1>Món đồ nhỏ. Nụ cười sáng.</h1><p>20 vector gốc mới · C09/C10/V09/V10.</p>${[
    'wardrobe',
    'smile',
  ]
    .map(
      (f) =>
        `<h2>${f === 'wardrobe' ? 'Tủ đồ ký ức / Little keepsakes' : 'Một ngày đầy nắng / A Smile to Keep'}</h2><div class="grid">${assets
          .filter((a) => a.family === f)
          .map(
            (a) =>
              `<article><div class="art">${a.svg}</div><h3>${a.title}</h3><p>${a.usage}</p><code>${a.name}</code></article>`,
          )
          .join('')}</div>`,
    )
    .join('')}</html>`,
);
console.log(`Drew ${assets.length} original phase 5 SVG assets.`);
