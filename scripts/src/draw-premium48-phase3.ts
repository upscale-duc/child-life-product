/** Original editable vector assets for C05/C06/V05/V06. No fetched illustrations or baked-in text. */
import { mkdirSync, writeFileSync } from 'node:fs';
import { resolve, join } from 'node:path';
const dir = resolve(import.meta.dirname, '../../design/keepsake-art');
const out = resolve(import.meta.dirname, '../../artifacts/premium48-phase3');
mkdirSync(out, { recursive: true });
const O = { paper: '#FCF7ED', sage: '#A2AA85', ink: '#4B5142', light: '#E5E8D5' };
const L = { paper: '#F5EEE2', wine: '#87494F', tan: '#BCA68D', light: '#E9DCCC' };
const assets: { name: string; family: string; title: string; usage: string; svg: string }[] = [];
function add(
  family: 'observe' | 'letter',
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
  'observe',
  'hand',
  'Bàn tay bé',
  'Icon nét tay bên nhãn; không đặt lên mặt.',
  220,
  250,
  `<path d="M61 220c-7-26-39-60-38-77 1-17 18-13 32 6l10 13-10-90c-2-19 18-21 21-2l12 62-3-93c0-20 22-19 23 0l8 88 9-91c2-19 23-17 21 2l-5 93 17-68c5-19 25-12 20 6l-12 99c-3 29-17 40-16 62" fill="${O.light}" stroke="${O.ink}" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/><path d="M72 180c14-23 37-29 55-17m-34 48c13-7 27-8 39-3" fill="none" stroke="${O.sage}" stroke-width="3" stroke-linecap="round"/>`,
);
add(
  'observe',
  'foot',
  'Dấu chân nhỏ',
  'Nhãn nét riêng; không dùng như dấu vân chân thật.',
  200,
  280,
  `<path d="M66 239c-17-11-14-37-2-62 14-27 4-55 16-76 10-18 36-19 53-4 27 23 32 62 11 86-15 18-15 47-30 56-14 9-35 8-48 0Z" fill="${O.light}" stroke="${O.ink}" stroke-width="3"/><g fill="${O.sage}"><ellipse cx="138" cy="53" rx="24" ry="30" transform="rotate(20 138 53)"/><ellipse cx="94" cy="46" rx="15" ry="20"/><ellipse cx="65" cy="64" rx="12" ry="16" transform="rotate(-20 65 64)"/><ellipse cx="45" cy="88" rx="10" ry="13"/><ellipse cx="35" cy="113" rx="8" ry="11"/></g><path d="M81 220c10-2 19-1 26 3" stroke="${O.sage}" stroke-width="3" fill="none"/>`,
);
add(
  'observe',
  'star',
  'Ngôi sao mực',
  'Điểm nhấn nhãn điều muốn nhớ.',
  220,
  220,
  `<path d="m110 24 22 54 59 8-45 39 12 60-49-31-51 31 12-59-43-40 60-8Z" fill="${O.light}" stroke="${O.ink}" stroke-width="3" stroke-linejoin="round"/><path d="m108 42 18 46 44 6" fill="none" stroke="${O.sage}" stroke-width="3"/><path d="m189 29 9-12m-5 39 17-2M30 174l-13 8" stroke="${O.sage}" stroke-width="3" stroke-linecap="round"/>`,
);
for (const [i, name] of ['favorite-label', 'detail-label', 'memory-label'].entries())
  add(
    'observe',
    name,
    ['Nhãn điều con thích', 'Nhãn nét riêng', 'Nhãn muốn nhớ'][i]!,
    'Nền nhãn trống; nội dung VI/EN nằm ở layer riêng.',
    520,
    210,
    `<path d="M15 23q-2-13 17-13l458 5q20 1 16 20l-9 152q-1 13-18 13l-452-8q-17-1-15-19Z" fill="${i === 1 ? O.light : '#FFFDF8'}"/><path d="M27 31q-2-9 14-8l434 6q13 0 12 12l-8 130q-1 10-15 10l-423-7q-12 0-12-12Z" fill="none" stroke="${O.sage}" stroke-width="2" ${i === 2 ? 'stroke-dasharray="4 6"' : ''}/><circle cx="34" cy="24" r="5" fill="${O.ink}" opacity=".25"/>`,
  );
add(
  'observe',
  'oval-frame',
  'Viền oval sổ quan sát',
  'Khung trong suốt quanh ảnh; crop do người dùng đặt.',
  600,
  760,
  `<ellipse cx="300" cy="380" rx="277" ry="352" fill="none" stroke="#FFFDF8" stroke-width="22"/><ellipse cx="300" cy="380" rx="283" ry="359" fill="none" stroke="${O.sage}" stroke-width="3"/><path d="M98 147C148 72 210 40 280 31M356 733c61-9 103-39 146-86" stroke="${O.ink}" stroke-width="2" fill="none" opacity=".5"/>`,
);
add(
  'observe',
  'ink-dots',
  'Chấm mực',
  'Nhịp nhỏ ở lề trang.',
  270,
  120,
  `<g fill="${O.ink}" opacity=".35"><circle cx="32" cy="58" r="7"/><circle cx="59" cy="38" r="3"/><circle cx="86" cy="70" r="4"/><circle cx="145" cy="46" r="6"/><circle cx="177" cy="77" r="3"/><circle cx="223" cy="49" r="5"/><circle cx="241" cy="81" r="2"/></g>`,
);
add(
  'observe',
  'pencil-rule',
  'Nét gạch sổ tay',
  'Đường gạch dưới chữ, không phải chữ viết tay giả.',
  740,
  90,
  `<path d="M24 44C164 22 334 53 714 32M42 58c176-9 318 5 621-3" fill="none" stroke="${O.sage}" stroke-width="3" stroke-linecap="round" opacity=".7"/>`,
);
add(
  'observe',
  'margin-bracket',
  'Ngoặc ghi chú',
  'Nối nhãn với ảnh ở lề; không tự đoán vị trí chi tiết.',
  190,
  520,
  `<path d="M158 22H62q-30 0-30 30v174q0 34-19 34 19 0 19 34v174q0 30 30 30h96" fill="none" stroke="${O.sage}" stroke-width="4" stroke-linecap="round"/><circle cx="159" cy="22" r="7" fill="${O.light}"/><circle cx="159" cy="498" r="7" fill="${O.light}"/>`,
);
add(
  'letter',
  'envelope-back',
  'Lưng phong bì',
  'Lớp sau ảnh; hình phong bì mới riêng C06/V06.',
  700,
  420,
  `<path d="m25 133 321-113 329 116v255H25Z" fill="${L.tan}"/><path d="m25 133 321 161 329-158" fill="none" stroke="${L.wine}" stroke-width="3" opacity=".28"/><path d="M43 148v226h614" fill="none" stroke="${L.paper}" stroke-width="2" opacity=".65"/>`,
);
add(
  'letter',
  'envelope-front',
  'Mặt phong bì',
  'Lớp trước khi ảnh trượt ra; chỉ che mép dưới ảnh.',
  700,
  300,
  `<path d="m22 22 326 159L678 22v251H22Z" fill="${L.light}"/><path d="m22 273 241-138 85 46 88-44 242 136" fill="${L.paper}"/><path d="m22 273 241-138m415 138L436 137" fill="none" stroke="${L.tan}" stroke-width="3"/><path d="M42 281h616" stroke="${L.wine}" stroke-width="2" opacity=".2"/>`,
);
add(
  'letter',
  'envelope-flap',
  'Nắp phong bì',
  'Layer riêng; mở như đồ họa, không quét mặt.',
  700,
  230,
  `<path d="M20 18h660L353 215q-6 3-12 0Z" fill="${L.tan}"/><path d="m37 29 309 173L663 29" fill="none" stroke="${L.paper}" stroke-width="3" opacity=".6"/>`,
);
add(
  'letter',
  'wax-seal',
  'Dấu sáp trơn',
  'Không huy hiệu, không giả chữ ký hay con dấu thật.',
  220,
  220,
  `<path d="m110 18 19 8 20 1 13 15 19 8 5 19 13 17-3 20 4 20-13 16-6 20-19 7-14 16-21-1-20 7-18-10-20-2-12-16-18-10-3-21-9-18 7-19 1-20 15-13 8-18 20-4Z" fill="${L.wine}"/><circle cx="110" cy="110" r="67" fill="none" stroke="${L.paper}" stroke-width="3" opacity=".45"/><path d="M60 91c12-37 50-51 77-36M149 154l9-10" fill="none" stroke="${L.paper}" stroke-width="3" opacity=".45" stroke-linecap="round"/>`,
);
add(
  'letter',
  'ruled-paper',
  'Giấy thư kẻ mờ',
  'Nền thư với đường kẻ thưa; chữ được render riêng.',
  800,
  1000,
  `<path d="m18 16 762 4-6 961-757 5Z" fill="#FFFDF9"/><path d="M47 38v917" stroke="${L.wine}" stroke-width="2" opacity=".12"/>${Array.from({ length: 12 }, (_, i) => `<path d="M69 ${90 + i * 72}h666" stroke="${L.tan}" stroke-width="1" opacity=".23"/>`).join('')}`,
);
add(
  'letter',
  'postage-frame',
  'Khung tem trống',
  'Nhãn tháng, để trống thay vì huy hiệu.',
  220,
  250,
  `<path d="M19 17h182v216H19Z" fill="${L.paper}" stroke="${L.tan}" stroke-width="10" stroke-dasharray="8 9"/><rect x="40" y="38" width="140" height="174" fill="none" stroke="${L.wine}" stroke-width="2"/><path d="M66 183h88" stroke="${L.tan}" stroke-width="2"/>`,
);
add(
  'letter',
  'ribbon',
  'Dải ruy băng vải',
  'Điểm neo ngoài góc ảnh.',
  520,
  150,
  `<path d="m20 28 473-13-26 54 29 48-476 12 27-52Z" fill="${L.wine}" opacity=".85"/><path d="m40 40 430-10M43 111l424-12" stroke="${L.paper}" stroke-width="2" opacity=".5"/>`,
);
add(
  'letter',
  'fold',
  'Nếp giấy thư',
  'Chi tiết cạnh giấy giữ trống vùng đọc.',
  200,
  240,
  `<path d="M17 18h166v200Z" fill="${L.tan}" opacity=".3"/><path d="M17 18h166L91 106Z" fill="#FFFDF9"/><path d="m91 106 92 112V18" fill="${L.paper}"/><path d="m91 106 92 112" stroke="${L.tan}" stroke-width="2"/>`,
);
add(
  'letter',
  'monogram-frame',
  'Khung chữ cái',
  'Khung trống cho tên/chữ cái người dùng; không chữ giả.',
  300,
  300,
  `<ellipse cx="150" cy="150" rx="106" ry="128" fill="none" stroke="${L.tan}" stroke-width="3"/><ellipse cx="150" cy="150" rx="98" ry="120" fill="none" stroke="${L.wine}" stroke-width="1"/><path d="M120 23h60m-60 254h60" stroke="${L.wine}" stroke-width="3"/>`,
);
add(
  'letter',
  'closing-rule',
  'Dòng kết thư',
  'Nét kẻ và chấm mực, không mô phỏng chữ ký.',
  740,
  100,
  `<path d="M26 51h235m218 0h235" stroke="${L.tan}" stroke-width="2"/><path d="m355 51 15-10 15 10-15 11Z" fill="${L.wine}"/><circle cx="320" cy="51" r="3" fill="${L.wine}"/><circle cx="420" cy="51" r="3" fill="${L.wine}"/>`,
);
for (const a of assets) writeFileSync(join(dir, `${a.name}.svg`), a.svg);
writeFileSync(
  join(dir, 'premium48-phase3-manifest.json'),
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
        templates: a.family === 'observe' ? ['C05', 'V05'] : ['C06', 'V06'],
      })),
    },
    null,
    2,
  ) + '\n',
);
writeFileSync(join(out, 'assets.json'), JSON.stringify(assets, null, 2));
writeFileSync(
  join(out, 'assets.html'),
  `<!doctype html><html lang="vi"><meta charset="utf-8"><title>Phase 3 · Original assets</title><style>body{background:#faf7f1;color:#4B5142;font:16px system-ui;max-width:1300px;margin:48px auto;padding:24px}h1,h2{font-family:Georgia}.grid{display:grid;grid-template-columns:repeat(5,1fr);gap:20px}article{background:#fffdf9;border:1px solid #e3d8c8;padding:16px;border-radius:12px}.art{height:210px;display:flex;align-items:center;justify-content:center}.art svg{max-width:100%;max-height:200px;width:auto;height:auto}h3{font-size:15px}p{font-size:13px;line-height:1.6}code{font-size:9px}</style><small>CHILD LIFE / PREMIUM 48 / PHASE 03</small><h1>Những điều nhỏ. Những dòng thương.</h1><p>20 vector mới · C05/C06/V05/V06 · Nội dung VI/EN ở layer riêng.</p>${[
    'observe',
    'letter',
  ]
    .map(
      (f) =>
        `<h2>${f === 'observe' ? 'Sổ quan sát bé / Little Things About You' : 'Thư lưu niệm / A Letter at One Month'}</h2><div class="grid">${assets
          .filter((a) => a.family === f)
          .map(
            (a) =>
              `<article><div class="art">${a.svg}</div><h3>${a.title}</h3><p>${a.usage}</p><code>${a.name}</code></article>`,
          )
          .join('')}</div>`,
    )
    .join('')}</html>`,
);
console.log(`Drew ${assets.length} original phase 3 SVG assets.`);
