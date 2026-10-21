/** Twenty original paper-path and nature-journal assets for phase 6. */
import { mkdirSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
const dir = resolve(import.meta.dirname, '../../design/keepsake-art'),
  out = resolve(import.meta.dirname, '../../artifacts/premium48-phase6');
mkdirSync(out, { recursive: true });
const ivory = '#FAF5E9',
  teal = '#668A84',
  mango = '#D6A35C',
  mist = '#F1F0E5',
  leaf = '#80916D',
  earth = '#A17654';
const assets: { name: string; family: string; title: string; usage: string; svg: string }[] = [];
function add(
  family: 'milestone' | 'discover',
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
  'milestone',
  'dot-route',
  'Đường đi chấm',
  'Nét đi ngang có ba điểm dừng, không điểm số.',
  900,
  200,
  `<path d="M40 130C160 130 170 50 300 70s170 100 290 50 180-85 270-45" fill="none" stroke="${teal}" stroke-width="4" stroke-dasharray="2 13" stroke-linecap="round"/><circle cx="40" cy="130" r="12" fill="${ivory}" stroke="${teal}" stroke-width="3"/><circle cx="450" cy="115" r="12" fill="${ivory}" stroke="${teal}" stroke-width="3"/><circle cx="860" cy="75" r="12" fill="${mango}"/>`,
);
add(
  'milestone',
  'paper-star',
  'Ngôi sao giấy',
  'Một ngôi sao mở nhẹ ở lề; không huy chương.',
  300,
  300,
  `<path d="m150 20 36 81 88 12-65 60 17 88-76-44-77 44 17-88-65-60 89-12Z" fill="${mango}"/><path d="m150 20 1 141 123-48-89-12-35-81Z" fill="#EDCC96"/><path d="m151 161 75 100-17-88 65-60Z" fill="#BC8F4C"/><path d="m151 161-1 56-77 44Z" fill="#F1D7AA"/>`,
);
add(
  'milestone',
  'photo-corners',
  'Góc ảnh hành trình',
  'Góc giấy thoáng cho ba ảnh theo trình tự.',
  700,
  900,
  `<path d="M16 90V16h74m520 0h74v74M16 810v74h74m520 0h74v-74" fill="none" stroke="#FFFDF8" stroke-width="24"/><path d="M16 90V16h74m520 0h74v74M16 810v74h74m520 0h74v-74" fill="none" stroke="${teal}" stroke-width="3"/>`,
);
add(
  'milestone',
  'label',
  'Nhãn tên mốc',
  'Tên mốc là text xác nhận riêng, không nhãn thành tích.',
  800,
  150,
  `<path d="M16 16h768v118H16Z" fill="#FFFDF8"/><path d="M16 16v118m768-118v118" stroke="${teal}" stroke-width="5"/><path d="M40 132h720" stroke="${mango}" stroke-width="2"/>`,
);
add(
  'milestone',
  'step-one',
  'Dấu bước đầu',
  'Một dấu chấm, không con số.',
  180,
  180,
  `<circle cx="90" cy="90" r="58" fill="${ivory}" stroke="${teal}" stroke-width="3"/><circle cx="90" cy="90" r="10" fill="${teal}"/>`,
);
add(
  'milestone',
  'step-next',
  'Dấu bước tiếp',
  'Hai nét nhịp nhỏ, không so sánh trẻ.',
  180,
  180,
  `<circle cx="90" cy="90" r="58" fill="${ivory}" stroke="${teal}" stroke-width="3"/><path d="M69 90h13m16 0h13" stroke="${teal}" stroke-width="7" stroke-linecap="round"/>`,
);
add(
  'milestone',
  'step-pause',
  'Dừng tại khoảnh khắc',
  'Điểm dừng có vòng giấy, không cấp bậc.',
  180,
  180,
  `<circle cx="90" cy="90" r="62" fill="${ivory}" stroke="${mango}" stroke-width="4"/><circle cx="90" cy="90" r="40" fill="none" stroke="${teal}" stroke-width="2"/><circle cx="90" cy="90" r="9" fill="${mango}"/>`,
);
add(
  'milestone',
  'date-tag',
  'Nhãn ngày mốc',
  'Nhãn ngày tùy chọn; để trống khi chưa rõ.',
  700,
  150,
  `<path d="M20 20h660v110H20l22-55Z" fill="#FFFDF8" stroke="${teal}" stroke-width="2"/><circle cx="60" cy="75" r="6" fill="${mango}"/><path d="M94 113h555" stroke="${teal}" stroke-width="2" opacity=".25"/>`,
);
add(
  'milestone',
  'folded-edge',
  'Nếp giấy mốc',
  'Nếp gấp ở lề trang, không ảnh huy chương.',
  160,
  800,
  `<path d="M25 18h85v764H25Z" fill="${mango}" opacity=".13"/><path d="M110 18v764m-20-764v764" stroke="${teal}" stroke-width="2" opacity=".4"/><path d="m110 18 30 35-30 36" fill="none" stroke="${mango}" stroke-width="3"/>`,
);
add(
  'milestone',
  'closing-rule',
  'Nét kết hành trình',
  'Đường chấm khép lại bằng một dấu giấy.',
  850,
  100,
  `<path d="M18 50h745" stroke="${teal}" stroke-width="3" stroke-dasharray="2 13" stroke-linecap="round"/><path d="m795 26 24 24-24 24-24-24Z" fill="${mango}"/>`,
);
add(
  'discover',
  'round-window',
  'Cửa sổ tròn',
  'Viền tròn giữ vùng giữa trong suốt.',
  600,
  600,
  `<circle cx="300" cy="300" r="281" fill="none" stroke="#FFFDF8" stroke-width="24"/><circle cx="300" cy="300" r="281" fill="none" stroke="${leaf}" stroke-width="3"/><path d="M65 164a269 269 0 0 1 403-95" fill="none" stroke="${earth}" stroke-width="4" stroke-linecap="round"/>`,
);
add(
  'discover',
  'leaf-pair',
  'Hai lá giấy',
  'Lá phẳng ở biên ảnh, không thêm vật vào ảnh thật.',
  300,
  400,
  `<path d="M146 375C40 300 14 184 41 35c114 32 153 111 105 340Z" fill="${leaf}"/><path d="M146 375c-5-138 24-235 128-287 35 130-4 234-128 287Z" fill="#BAC4A6"/><path d="M146 375 71 88m75 287 91-230" fill="none" stroke="${mist}" stroke-width="3"/>`,
);
add(
  'discover',
  'leaf-sprig',
  'Nhánh lá trừu tượng',
  'Lá gấp nhẹ tối đa 8px tại lề.',
  320,
  600,
  `<path d="M160 572V37" stroke="${earth}" stroke-width="4"/><path d="M159 195C43 173 36 85 43 56c104 12 134 69 116 139Zm1 159C51 322 36 262 49 218c104 24 130 78 111 136Zm0-79c116-21 123-103 116-146-104 18-136 71-116 146Zm0 181c110-22 122-96 110-136-103 17-132 76-110 136Z" fill="${leaf}" opacity=".8"/>`,
);
add(
  'discover',
  'viewfinder',
  'Kính ngắm tròn',
  'Kính ngắm trung tính; không nhắm khuôn mặt.',
  600,
  600,
  `<circle cx="300" cy="300" r="267" fill="none" stroke="${earth}" stroke-width="3"/><path d="M300 17v37m0 492v37M17 300h37m492 0h37" stroke="${leaf}" stroke-width="5"/><circle cx="300" cy="300" r="282" fill="none" stroke="#FFFDF8" stroke-width="18"/>`,
);
add(
  'discover',
  'three-dots',
  'Ba chấm khám phá',
  'Ba chấm nối hai góc nhìn, không điểm thưởng.',
  150,
  400,
  `<circle cx="75" cy="60" r="11" fill="${earth}"/><circle cx="75" cy="200" r="9" fill="${leaf}"/><circle cx="75" cy="340" r="7" fill="${earth}" opacity=".65"/>`,
);
add(
  'discover',
  'journal-tab',
  'Tab sổ khám phá',
  'Nhãn giấy màu đất; chữ đặt ngoài SVG.',
  800,
  160,
  `<path d="m18 23 763-9 3 130-764 3Z" fill="#FFFDF8"/><path d="M38 24v120" stroke="${earth}" stroke-width="5"/><path d="M64 129h683" stroke="${leaf}" stroke-width="2" opacity=".4"/>`,
);
add(
  'discover',
  'wide-frame',
  'Khung nhìn rộng',
  'Viền trong suốt, dùng khi cửa sổ mở ra.',
  900,
  650,
  `<rect x="18" y="18" width="864" height="614" rx="34" fill="none" stroke="#FFFDF8" stroke-width="24"/><rect x="18" y="18" width="864" height="614" rx="34" fill="none" stroke="${leaf}" stroke-width="3"/><path d="M48 610h140m524-570h140" stroke="${earth}" stroke-width="3"/>`,
);
add(
  'discover',
  'eye-path',
  'Nét theo hướng nhìn',
  'Dissolve hướng sang ảnh kế, không tạo chuyển động mắt.',
  850,
  200,
  `<path d="M24 150C231 150 322 39 538 74s212 48 286-21" fill="none" stroke="${leaf}" stroke-width="3" stroke-dasharray="3 13" stroke-linecap="round"/><circle cx="24" cy="150" r="9" fill="${earth}"/><circle cx="824" cy="53" r="9" fill="${earth}"/>`,
);
add(
  'discover',
  'paper-seeds',
  'Hạt giấy',
  'Hạt giấy tĩnh bên ngoài ảnh và chữ.',
  600,
  600,
  `${[
    [45, 38, 12, 4],
    [550, 100, 9, 4],
    [28, 420, 12, 4],
    [560, 540, 10, 4],
    [220, 22, 8, 3],
    [400, 570, 9, 3],
    [580, 300, 9, 3],
    [45, 220, 8, 3],
  ]
    .map(
      ([x, y, rx, ry]) =>
        `<ellipse cx="${x}" cy="${y}" rx="${rx}" ry="${ry}" fill="${earth}" opacity=".35" transform="rotate(-25 ${x} ${y})"/>`,
    )
    .join('')}`,
);
add(
  'discover',
  'closing-loop',
  'Nét khép sổ',
  'Nét tròn chưa khép giữ mở câu chuyện khám phá.',
  600,
  160,
  `<path d="M25 82c136-94 416-94 542-8 71 47-8 94-112 62-54-17-53-72 10-77" fill="none" stroke="${leaf}" stroke-width="3" stroke-linecap="round"/><circle cx="25" cy="82" r="7" fill="${earth}"/>`,
);
for (const a of assets) writeFileSync(join(dir, a.name + '.svg'), a.svg);
writeFileSync(
  join(dir, 'premium48-phase6-manifest.json'),
  JSON.stringify(
    {
      version: 1,
      createdOn: '2026-10-21',
      licence: 'Original Child Life vector artwork',
      assets: assets.map((a) => ({
        name: a.name,
        family: a.family,
        title: a.title,
        usage: a.usage,
        file: a.name + '.svg',
        templates: a.family === 'milestone' ? ['C11', 'V11'] : ['C12', 'V12'],
      })),
    },
    null,
    2,
  ) + '\n',
);
writeFileSync(join(out, 'assets.json'), JSON.stringify(assets, null, 2));
writeFileSync(
  join(out, 'assets.html'),
  `<!doctype html><html lang="vi"><meta charset="utf-8"><title>Phase 6 · Original assets</title><style>body{max-width:1300px;margin:48px auto;padding:24px;background:#faf7f1;color:#37534f;font:16px system-ui}.grid{display:grid;grid-template-columns:repeat(5,1fr);gap:20px}article{padding:16px;background:#fffdf8;border:1px solid #deded0;border-radius:12px}.art{height:210px;display:flex;align-items:center;justify-content:center}.art svg{max-height:200px;max-width:100%;width:auto;height:auto}h3{font-size:15px}p{font-size:13px;line-height:1.6}code{font-size:9px}</style><small>CHILD LIFE / PREMIUM 48 / PHASE 06</small><h1>Từng bước nhỏ. Một thế giới mới.</h1><p>20 vector gốc mới · C11/C12/V11/V12.</p>${[
    'milestone',
    'discover',
  ]
    .map(
      (f) =>
        `<h2>${f === 'milestone' ? 'Con làm được rồi / You Did It' : 'Một thế giới để khám phá / A World to Discover'}</h2><div class="grid">${assets
          .filter((a) => a.family === f)
          .map(
            (a) =>
              `<article><div class="art">${a.svg}</div><h3>${a.title}</h3><p>${a.usage}</p><code>${a.name}</code></article>`,
          )
          .join('')}</div>`,
    )
    .join('')}</html>`,
);
console.log('Drew 20 original phase 6 assets.');
