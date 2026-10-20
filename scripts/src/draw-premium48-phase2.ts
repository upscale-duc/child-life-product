/** Original, editable vector art for C03/C04/V03/V04. No fetched artwork or baked-in copy. */
import { mkdirSync, writeFileSync } from 'node:fs';
import { resolve, join } from 'node:path';
const dir = resolve(import.meta.dirname, '../../design/keepsake-art');
const out = resolve(import.meta.dirname, '../../artifacts/premium48-phase2');
mkdirSync(out, { recursive: true });
const home = {
  paper: '#FFFDF7',
  butter: '#F6E7B8',
  olive: '#79815C',
  dark: '#414B34',
  clay: '#B77E60',
};
const scrap = {
  cream: '#FFF4E7',
  apricot: '#D99A74',
  cocoa: '#5B4034',
  light: '#F2D6BD',
  paper: '#FFFDF8',
};
const svg = (w: number, h: number, body: string) =>
  `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}" preserveAspectRatio="none">${body}</svg>\n`;
const assets: { name: string; family: string; title: string; usage: string; svg: string }[] = [];
function add(
  family: 'home' | 'scrap',
  name: string,
  title: string,
  usage: string,
  w: number,
  h: number,
  body: string,
) {
  assets.push({ name: `p48-${family}-${name}`, family, title, usage, svg: svg(w, h, body) });
}
const H = home,
  S = scrap;
add(
  'home',
  'house',
  'Nhà giấy',
  'Hero kết; khung nhận diện C03/V03.',
  360,
  340,
  `
 <path d="M53 154 181 43 312 152 302 302 56 306Z" fill="${H.dark}" opacity=".10"/>
 <path d="M57 141 179 40 301 143 295 294 62 296Z" fill="${H.butter}"/>
 <path d="m31 150 146-127 151 124-22 23L177 62 52 172Z" fill="${H.olive}"/>
 <path d="m177 62 2 234 116-2 6-151Z" fill="${H.clay}" opacity=".09"/>
 <path d="M145 294V191q0-35 34-35t34 35v104" fill="${H.paper}"/>
 <path d="M150 294V192q0-28 29-28t29 28v102" fill="none" stroke="${H.olive}" stroke-width="3"/>
 <rect x="81" y="177" width="44" height="52" rx="3" fill="${H.paper}"/><path d="M103 178v50m-21-25h42" stroke="${H.olive}" stroke-width="3"/>
 <circle cx="197" cy="237" r="4" fill="${H.clay}"/><path d="m249 87 1-44 25 2v62" fill="${H.clay}"/>
 <path d="M80 277h48m96-9h50" stroke="${H.paper}" stroke-width="2" opacity=".6"/>`,
);
add(
  'home',
  'key',
  'Chìa khóa đồng',
  'Điểm chốt ở lề; hạ xuống ở cảnh kết.',
  320,
  140,
  `
 <g transform="rotate(-9 160 70)"><path d="M108 77h167v21h-23v19h-19V98h-27v16h-20V98h-78" fill="${H.dark}" opacity=".12"/>
 <circle cx="73" cy="68" r="47" fill="${H.butter}"/><circle cx="73" cy="68" r="24" fill="${H.paper}"/>
 <path d="M113 58h163v23h-23v18h-18V81h-27v15h-20V81h-75Z" fill="${H.clay}"/>
 <path d="M120 63h147" stroke="${H.butter}" stroke-width="3"/><path d="M42 38q24-17 47-3" fill="none" stroke="${H.paper}" stroke-width="5" stroke-linecap="round"/></g>`,
);
add(
  'home',
  'route',
  'Đường về nhà',
  'Nối ảnh ở lề; reveal theo nhịp cảnh 1/2.',
  720,
  210,
  `
 <path d="M28 160C126 160 75 45 200 51S314 191 415 143 493 33 687 53" fill="none" stroke="${H.olive}" stroke-width="5" stroke-dasharray="1 17" stroke-linecap="round"/>
 <circle cx="28" cy="160" r="10" fill="${H.clay}"/><circle cx="687" cy="53" r="14" fill="${H.butter}" stroke="${H.olive}" stroke-width="3"/>
 <circle cx="687" cy="53" r="4" fill="${H.olive}"/>`,
);
for (const side of ['left', 'right'] as const)
  add(
    'home',
    `door-${side}`,
    side === 'left' ? 'Cánh cửa trái' : 'Cánh cửa phải',
    'Hai layer riêng để mở cửa tại lề, không quét qua mặt.',
    210,
    520,
    `
 <path d="M18 13h177l-4 494H21Z" fill="${H.dark}" opacity=".10"/>
 <path d="M9 7h177l-2 494H12Z" fill="${side === 'left' ? H.olive : H.butter}"/>
 <path d="M30 29h133v202H30Zm0 231h133v217H30Z" fill="none" stroke="${side === 'left' ? H.butter : H.olive}" stroke-width="3" opacity=".55"/>
 <circle cx="${side === 'left' ? 160 : 38}" cy="252" r="7" fill="${H.clay}"/>
 <path d="M20 18v468" stroke="${H.paper}" stroke-width="2" opacity=".45"/>`,
  );
add(
  'home',
  'window',
  'Khung cửa vòm',
  'Viền quanh ảnh; vùng giữa trong suốt.',
  400,
  500,
  `
 <path d="M25 475V192C25-26 375-26 375 192v283" fill="none" stroke="${H.dark}" stroke-width="25" opacity=".08"/>
 <path d="M26 467V190C26-20 374-20 374 190v277" fill="none" stroke="${H.paper}" stroke-width="28"/>
 <path d="M26 467V190C26-20 374-20 374 190v277M10 475h380" fill="none" stroke="${H.olive}" stroke-width="5"/>
 <path d="M38 461V192C38-4 362-4 362 192v269" fill="none" stroke="${H.butter}" stroke-width="3"/>`,
);
add(
  'home',
  'tag',
  'Thẻ hành trình',
  'Chứa ngày tùy chọn bằng text VI/EN ở ngoài SVG.',
  460,
  180,
  `
 <path d="m19 43 59-29 360 5 2 146-360 6-60-33Z" fill="${H.dark}" opacity=".08"/>
 <path d="m13 37 59-29 360 5 2 146-360 6-60-33Z" fill="${H.paper}"/>
 <path d="m22 44 55-26 343 4 1 127-345 5-53-31Z" fill="none" stroke="${H.olive}" stroke-width="2" stroke-dasharray="4 6"/>
 <circle cx="56" cy="87" r="10" fill="${H.butter}"/><path d="M55 87C-12 55 6 12 75 25" fill="none" stroke="${H.clay}" stroke-width="3"/>`,
);
add(
  'home',
  'envelope',
  'Phong bì lời chào',
  'Nền cho dòng nhắn C03; kết thư V03.',
  420,
  270,
  `
 <path d="m30 51 365 5-2 197-369-4Z" fill="${H.dark}" opacity=".09"/>
 <path d="M22 45h368v197H22Z" fill="${H.butter}"/>
 <path d="m22 45 185 131L390 45" fill="${H.paper}"/><path d="m22 242 136-107m232 107L256 136" fill="none" stroke="${H.clay}" stroke-width="2" opacity=".4"/>
 <path d="m185 133 22 18 22-18" fill="none" stroke="${H.olive}" stroke-width="3"/>
 <circle cx="207" cy="169" r="19" fill="${H.olive}"/><path d="m197 169 10-8 10 8v11h-20Z" fill="${H.butter}"/>`,
);
add(
  'home',
  'plant',
  'Chậu cây góc nhà',
  'Chi tiết nhỏ ở góc khung nhà, không thay chủ thể ảnh.',
  210,
  330,
  `
 <path d="M102 241C92 179 105 113 119 50" fill="none" stroke="${H.dark}" stroke-width="4"/>
 <path d="M108 166C44 170 30 114 42 94c46-1 69 31 66 72Zm6-52c9-58 57-76 79-66-2 48-36 68-79 66ZM101 210c12-57 60-64 76-51-6 37-34 54-76 51Z" fill="${H.olive}"/>
 <path d="M64 232h91l-13 72H76Z" fill="${H.clay}"/><path d="M58 230h103v16H58Z" fill="${H.butter}"/>
 <path d="M83 256v34m13-34v34m13-34v34m13-34v34" stroke="${H.paper}" stroke-width="2" opacity=".35"/>`,
);
add(
  'home',
  'roof-frame',
  'Mái nhà ôm ảnh',
  'Chỉ viền, giữ ảnh lớn ở cảnh kết; không che gương mặt.',
  800,
  820,
  `
 <path d="M57 784V278L400 28l343 250v506" fill="none" stroke="${H.dark}" stroke-width="28" opacity=".08"/>
 <path d="M47 775V268L400 18l353 250v507" fill="none" stroke="${H.paper}" stroke-width="30"/>
 <path d="M47 775V268L400 18l353 250v507M30 784h740" fill="none" stroke="${H.olive}" stroke-width="5"/>
 <path d="m58 264 342-232 342 232" fill="none" stroke="${H.butter}" stroke-width="5"/>`,
);
add(
  'scrap',
  'washi-ripped',
  'Washi xé màu mơ',
  'Giữ ảnh trên giấy; layer ngắn, không phủ mặt.',
  540,
  130,
  `
 <path d="m18 23 17-7 10 7 12-9 11 8 13-7 14 9 14-10 16 8 13-8 14 7 16-8 14 8 12-8 18 8 17-7 14 7 18-8 16 8 18-7 17 9 13-10 19 8 17-8 17 8 17-7 15 8 16-8 14 10 18-7 16 7 17-9-13 88-14-8-16 9-19-7-12 7-17-8-19 9-16-8-17 7-18-8-15 9-18-8-16 8-18-7-15 8-17-9-17 8-16-9-17 8-17-7-16 8-17-7-16 7-17-9-16 7-17-8Z" fill="${S.apricot}" opacity=".72"/>
 <path d="M34 39h469M32 48h470M30 81h470" stroke="${S.paper}" stroke-width="1" opacity=".25"/>`,
);
add(
  'scrap',
  'washi-grid',
  'Washi ô kẻ',
  'Biến thể chức năng cho ảnh thứ hai, không đổi màu giả mẫu mới.',
  480,
  130,
  `
 <path d="m17 18 447 8-15 88-435-7 10-21-7-18 9-19Z" fill="${S.light}" opacity=".85"/>
 ${Array.from({ length: 13 }, (_, i) => `<path d="M${35 + i * 33} 20v89" stroke="${S.apricot}" stroke-width="2" opacity=".55"/>`).join('')}
 <path d="M17 47h441M16 79h437" stroke="${S.apricot}" stroke-width="2" opacity=".55"/>`,
);
add(
  'scrap',
  'corner-fold',
  'Góc giấy gập',
  'Góc trang có chiều sâu, không đặt đè ảnh.',
  200,
  200,
  `
 <path d="M22 22h152v152Z" fill="${S.cocoa}" opacity=".10"/>
 <path d="M16 16h152v152Z" fill="${S.light}"/><path d="M16 16 145 36l23 132" fill="${S.paper}"/>
 <path d="m145 36 23 132" stroke="${S.apricot}" stroke-width="2"/>`,
);
add(
  'scrap',
  'tab',
  'Tab tuần trống',
  'Nhãn tuần là text VI/EN riêng, không tự gán ngày chụp.',
  360,
  140,
  `
 <path d="M21 38q0-17 18-17h188l25 20h82v84H21Z" fill="${S.cocoa}" opacity=".08"/>
 <path d="M16 32q0-17 18-17h188l25 20h82v84H16Z" fill="${S.light}"/>
 <path d="M32 97h280" stroke="${S.apricot}" stroke-width="2" opacity=".5"/>
 <circle cx="39" cy="43" r="4" fill="${S.apricot}"/>`,
);
// The numeral is drawn as paths, avoiding font dependencies in Figma or the app.
add(
  'scrap',
  'month-one',
  'Số 01 dập nổi',
  'Kết V04; chi tiết góc C04, không lặp ở mọi cảnh.',
  380,
  340,
  `
 <g transform="translate(6 8)" fill="${S.cocoa}" opacity=".10"><path fill-rule="evenodd" d="M29 170C29-6 236-6 236 170S29 346 29 170Zm51 0c0 107 105 107 105 0S80 63 80 170Z"/><path d="m254 73 75-43h24v280h-48V99l-51 27Z"/></g>
 <g fill="${S.apricot}"><path fill-rule="evenodd" d="M29 170C29-6 236-6 236 170S29 346 29 170Zm51 0c0 107 105 107 105 0S80 63 80 170Z"/><path d="m254 73 75-43h24v280h-48V99l-51 27Z"/></g>
 <path d="M47 166c-2-120 119-153 158-46m112-21V299" fill="none" stroke="${S.paper}" stroke-width="3" opacity=".55"/>`,
);
add(
  'scrap',
  'pencil-loop',
  'Nét bút chì vòng',
  'Draw-on ở lề, nối ảnh thứ ba hoặc nhấn câu kết.',
  640,
  210,
  `
 <path d="M18 154c89-24 77 58 156 7S428 37 471 83s-116 76-134 20 195-79 282-40" fill="none" stroke="${S.cocoa}" stroke-width="3" stroke-linecap="round" opacity=".7"/>
 <path d="M21 157c86-24 76 57 155 7S430 40 472 86s-116 75-134 19 195-79 282-39" fill="none" stroke="${S.cocoa}" stroke-width="1" opacity=".25"/>`,
);
add(
  'scrap',
  'photo-corners',
  'Góc giữ ảnh',
  '4 góc trong suốt ở giữa, co giãn theo khung ảnh.',
  600,
  720,
  `
 <path d="M16 93V16h77Zm491-77h77v77ZM16 627v77h77Zm491 77h77v-77Z" fill="${S.cocoa}" opacity=".09"/>
 <path d="M10 86V10h76Zm491-76h76v76ZM10 621v76h76Zm491 76h76v-76Z" fill="${S.light}"/>
 <path d="m10 86 76-76m415 0 76 76M10 621l76 76m415 0 76-76" stroke="${S.apricot}" stroke-width="2"/>`,
);
add(
  'scrap',
  'envelope',
  'Túi lưu kỷ niệm',
  'Đựng dải lời nhắn; hình riêng với phong bì của bộ nhà.',
  420,
  280,
  `
 <path d="M29 65h364v184H29Z" fill="${S.cocoa}" opacity=".09"/>
 <path d="M24 59h364v184H24Z" fill="${S.light}"/>
 <path d="M52 25 359 19l6 160-307 6Z" fill="${S.paper}"/>
 <path d="m24 99 182 78 182-78v144H24Z" fill="${S.apricot}"/>
 <path d="M39 228h334" stroke="${S.cream}" stroke-width="2" stroke-dasharray="4 5"/>
 <path d="M81 68h242M81 92h195M81 116h215" stroke="${S.apricot}" stroke-width="2" opacity=".35"/>`,
);
add(
  'scrap',
  'paper-strip',
  'Dải giấy lời nhắn',
  'Nền câu kết C04; text thật luôn là layer riêng.',
  800,
  180,
  `
 <path d="m16 26 764-9-8 20 10 21-8 18 9 19-8 17 8 19-11 24-757 10 9-21-10-19 9-18-7-20 8-18-10-22Z" fill="${S.cocoa}" opacity=".07"/>
 <path d="m10 20 764-9-8 20 10 21-8 18 9 19-8 17 8 19-11 24-757 10 9-21-10-19 9-18-7-20 8-18-10-22Z" fill="${S.paper}"/>
 <path d="M36 139 748 129" stroke="${S.light}" stroke-width="2"/>`,
);
add(
  'scrap',
  'stitches',
  'Đường khâu trang',
  'Nhịp dọc lề trang, thay motif đường đi của bộ nhà.',
  120,
  680,
  `
 <path d="M60 18v640" stroke="${S.light}" stroke-width="3"/>
 ${Array.from({ length: 17 }, (_, i) => `<path d="m44 ${28 + i * 37} 30 21m-30 0 30-21" fill="none" stroke="${S.apricot}" stroke-width="3" stroke-linecap="round"/>`).join('')}`,
);
for (const a of assets) writeFileSync(join(dir, `${a.name}.svg`), a.svg);
const manifest = {
  version: 1,
  collection: 'premium48-phase2',
  source:
    'Original editable SVG authored for Child Life, 2026-10-20. No third-party imagery or font outlines.',
  licence: 'Original artwork for Child Life',
  assets: assets.map((a) => ({
    name: a.name,
    family: a.family,
    title: a.title,
    usage: a.usage,
    file: `${a.name}.svg`,
    templates: a.family === 'home' ? ['C03', 'V03'] : ['C04', 'V04'],
  })),
};
writeFileSync(
  join(dir, 'premium48-phase2-manifest.json'),
  JSON.stringify(manifest, null, 2) + '\n',
);
writeFileSync(join(out, 'assets.json'), JSON.stringify(assets, null, 2));
const tiles = (family: string) =>
  assets
    .filter((a) => a.family === family)
    .map(
      (a) =>
        `<article><div class="art">${a.svg}</div><h3>${a.title}</h3><p>${a.usage}</p><code>${a.name}</code></article>`,
    )
    .join('');
writeFileSync(
  join(out, 'assets.html'),
  `<!doctype html><html lang="vi"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Child Life · Phase 2 · Original assets</title><style>body{margin:0;background:#faf7f1;color:#403a31;font:16px system-ui}header,section{max-width:1240px;margin:48px auto;padding:0 24px}header{border-bottom:1px solid #ded5c6;padding-bottom:36px}h1{font:48px Georgia;margin:16px 0}h2{font:36px Georgia}small{letter-spacing:3px;color:#79815c}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:20px}article{background:#fffdf9;border:1px solid #e9dfcf;border-radius:14px;padding:18px}h3{font-size:16px}p{font-size:14px;line-height:1.6;color:#726453}code{font-size:10px;color:#9b725a}.art{height:200px;display:flex;align-items:center;justify-content:center;background:linear-gradient(45deg,#f7f3eb 25%,transparent 25%),linear-gradient(-45deg,#f7f3eb 25%,transparent 25%),linear-gradient(45deg,transparent 75%,#f7f3eb 75%),linear-gradient(-45deg,transparent 75%,#f7f3eb 75%);background-size:20px 20px;background-position:0 0,0 10px,10px -10px,-10px 0}.art svg{max-width:92%;max-height:180px;width:auto;height:auto}.palette{display:flex;gap:8px;margin:20px 0 30px}.swatch{padding:12px;border-radius:5px;font-size:12px;min-width:88px}.note{max-width:800px}</style><header><small>CHILD LIFE / PREMIUM COLLECTION / PHASE 02</small><h1>Nhà có con. Mình lớn cùng nhau.</h1><p class="note">20 vector gốc cho C03, C04, V03, V04. Hai bộ ngôn ngữ hình ảnh riêng, cùng giữ ảnh gia đình làm trung tâm. Chữ VI/EN và ngày tháng được đặt bằng layer riêng, không nằm chết trong hình.</p></header><section><small>C03 + V03 / WELCOME HOME</small><h2>Nhật ký chuyến về nhà</h2><p>Giấy cắt, khung cửa, nét đường đi. Chuyển động mở cửa và nối hành trình ở lề.</p><div class="palette">${[H.butter, H.olive, H.paper, H.clay].map((c) => `<span class="swatch" style="background:${c};color:${c === H.olive ? 'white' : '#414B34'}">${c}</span>`).join('')}</div><div class="grid">${tiles('home')}</div></section><section><small>C04 + V04 / OUR FIRST MONTH</small><h2>Scrapbook một tháng làm quen</h2><p>Washi xé, tab giấy, góc gập, nét bút chì. Ảnh đặt dần lên trang, số 01 dành cho phần kết.</p><div class="palette">${[S.cream, S.apricot, S.cocoa, S.light].map((c) => `<span class="swatch" style="background:${c};color:${c === S.cocoa ? 'white' : '#5B4034'}">${c}</span>`).join('')}</div><div class="grid">${tiles('scrap')}</div></section></html>`,
);
console.log(`Drew ${assets.length} original SVGs → ${join(out, 'assets.html')}`);
