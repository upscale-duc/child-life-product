// Renders the favicon / app icons and the Open Graph images with a local Chrome.
// Usage (macOS, Chrome installed): node scripts/render-brand-assets.mjs
// Outputs are committed under public/; re-run when the logo or hero copy changes.
import { execFileSync } from 'node:child_process';
import { copyFileSync, mkdirSync, mkdtempSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const chrome = process.env.CHROME ?? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const work = mkdtempSync(join(tmpdir(), 'cl-brand-'));
const pub = (...p) => join(root, 'public', ...p);
const asset = (name) => pathToFileURL(join(root, 'src/assets/figma', name)).href;
const font = (name) => pathToFileURL(pub('fonts', name)).href;
mkdirSync(pub('icons'), { recursive: true });
mkdirSync(pub('og'), { recursive: true });

function shoot(name, html, width, height, out) {
  const file = join(work, `${name}.html`);
  writeFileSync(file, html);
  execFileSync(
    chrome,
    [
      '--headless=new',
      '--disable-gpu',
      '--hide-scrollbars',
      '--force-device-scale-factor=1',
      '--default-background-color=00000000',
      `--window-size=${width},${height}`,
      `--screenshot=${out}`,
      pathToFileURL(file).href,
    ],
    { stdio: 'ignore' },
  );
  console.log(`wrote ${out}`);
}

// Logo/Mark (Figma) — rounded for the browser tab, full-bleed for platform icons (they round it).
const mark = readFileSync(join(root, 'src/assets/figma/nav-logo-mark.svg'), 'utf8');
copyFileSync(join(root, 'src/assets/figma/nav-logo-mark.svg'), pub('icons/favicon.svg'));
const fullBleed = mark
  .replace(/<mask[\s\S]*?<\/mask>/, '')
  .replace(/<g mask="[^"]*">/, '<g>')
  .replace(/<path id="Frame" d="[^"]*"/, '<path id="Frame" d="M0 0H34V34H0Z"');
const iconHtml = (size, inset) => `<!doctype html><html><body style="margin:0;background:#2CBFB3">
<div style="width:${size}px;height:${size}px;display:grid;place-items:center;background:#2CBFB3">
<div style="width:${size - 2 * inset}px;height:${size - 2 * inset}px">${fullBleed.replace('<svg ', '<svg style="width:100%;height:100%" ')}</div></div></body></html>`;
shoot('apple', iconHtml(180, 0), 180, 180, pub('icons/apple-touch-icon.png'));
shoot('i192', iconHtml(192, 0), 192, 192, pub('icons/icon-192.png'));
shoot('i512', iconHtml(512, 0), 512, 512, pub('icons/icon-512.png'));

// Open Graph 1200 × 630: the v3 home hero and one image per stage page. Copy mirrors
// src/content/{vi,en}.ts (home.hero, journey.stages) — re-run when it changes.
const stageLook = [
  { soft: '#E6F7F5', ink: '#06716D', icon: null },
  { soft: '#FFF4D6', ink: '#173D44', icon: 'star' },
  { soft: '#EDEEFC', ink: '#4447A8', icon: 'spark' },
  { soft: '#FFE3DA', ink: '#1D5F99', icon: 'globe' },
];
const og = {
  vi: {
    eyebrow: 'Child Life · Hành trình lớn lên',
    title: ['Cùng con lớn lên,', 'đồng hành từng bước.'],
    caption: 'Miễn phí trên iPhone và Android',
    stage: 'Chặng',
    stages: [
      [
        '0–12 tháng',
        'Những ngày đầu đời.',
        'Làm quen với nhau qua từng cữ bú, giấc ngủ — và giữ lại những lần đầu tiên của con.',
      ],
      [
        '1–3 tuổi',
        'Con tập khám phá.',
        'Cùng con chập chững, bập bẹ những từ đầu tiên và tập những thói quen nhỏ.',
      ],
      [
        '3–6 tuổi',
        'Tò mò và lớn khôn.',
        'Cùng con chơi, đọc, vẽ và trả lời những câu hỏi “vì sao” không ngừng.',
      ],
      [
        '6–12 tuổi',
        'Thế giới riêng của con.',
        'Đồng hành nhẹ nhàng khi con tự lập, có sở thích và những ước mơ riêng.',
      ],
    ],
  },
  en: {
    eyebrow: 'Child Life · Growing up together',
    title: ['Grow up together,', 'one step at a time.'],
    caption: 'Free on iPhone and Android',
    stage: 'Stage',
    stages: [
      [
        '0–12 months',
        'The very first days.',
        "Getting to know each other one feed and one nap at a time — and keeping your child's firsts.",
      ],
      [
        '1–3 years',
        'Exploring the world.',
        'Toddling, first words and small new habits, together.',
      ],
      [
        '3–6 years',
        'Curious and growing.',
        'Playing, reading, drawing and answering an endless stream of “why?”.',
      ],
      [
        '6–12 years',
        'A world of their own.',
        'Gently by their side as they grow independent, with interests and dreams of their own.',
      ],
    ],
  },
};
const icon = (name, colour) =>
  readFileSync(join(root, '../mobile/assets/icons', `${name}.svg`), 'utf8')
    .replace(/currentColor/g, colour)
    .replace('<svg ', '<svg style="width:100%;height:100%" ');
const page = (
  locale,
  body,
  css = '',
) => `<!doctype html><html lang="${locale}"><head><meta charset="utf-8"><style>
@font-face{font-family:BVP;font-weight:500;src:url(${font('be-vietnam-pro-medium.woff2')})}
@font-face{font-family:BVP;font-weight:600;src:url(${font('be-vietnam-pro-semibold.woff2')})}
@font-face{font-family:BVP;font-weight:700;src:url(${font('be-vietnam-pro-bold.woff2')})}
*{box-sizing:border-box}body{margin:0;width:1200px;height:630px;overflow:hidden;position:relative;background:#F6FCFB;font-family:BVP;color:#173D44}
.copy{position:absolute;left:80px;top:72px;width:560px;display:flex;flex-direction:column;gap:26px}
.lockup{display:flex;align-items:center;gap:12px}.lockup img:first-child{width:46px;height:46px}.lockup img:last-child{height:36px}
.pill{align-self:flex-start;padding:10px 18px;border-radius:999px;font-weight:600;font-size:22px}
h1{margin:0;font-weight:700;line-height:1.1;text-wrap:balance}h1 span{display:block}
.cap{font-weight:500;font-size:24px;line-height:1.45;color:#55707A}
${css}</style></head><body>${body}</body></html>`;
const lockup = `<div class="lockup"><img src="${asset('nav-logo-mark.svg')}"><img src="${asset('nav-logo-wordmark.svg')}"></div>`;

for (const [locale, t] of Object.entries(og)) {
  // Home: the journey landscape (540 → 500 px) with the four stage rings on its road.
  const k = 500 / 540;
  const rings = [
    [117, 447, 86, '#087F7B'],
    [248, 348, 64, '#FFD166'],
    [362, 282, 56, '#6C6FD8'],
    [475, 185, 50, '#3B8FD9'],
  ]
    .map(
      ([x, y, size, colour], i) =>
        `<span class="ring" style="left:${(x - 50) * k}px;top:${(y - 20) * k}px;width:${size * k}px;height:${size * k}px;border-color:${colour}">${
          i === 0 ? `<img src="${asset('baby-0d3f8.jpg')}">` : ''
        }</span>`,
    )
    .join('');
  shoot(
    `og-${locale}`,
    page(
      locale,
      `<div class="land"><img src="${asset('journey-landscape.svg')}">${rings}</div>
<div class="copy">${lockup}<span class="pill" style="background:#E6F7F5;color:#06716D">${t.eyebrow}</span>
<h1 style="font-size:${locale === 'vi' ? 50 : 54}px;white-space:nowrap">${t.title.map((l) => `<span>${l}</span>`).join('')}</h1><span class="cap">${t.caption}</span></div>`,
      `.land{position:absolute;right:60px;top:65px;width:500px;height:500px;border-radius:44px;overflow:hidden}
.land>img{width:500px;height:500px;display:block}
.ring{position:absolute;border:4px solid;border-radius:50%;background:#fff;overflow:hidden}
.ring img{width:100%;height:100%;object-fit:cover}`,
    ),
    1200,
    630,
    pub('og', `${locale}.png`),
  );

  // Stage pages: age chip, stage title and lead next to the stage panel (number + photo/icon).
  t.stages.forEach(([ages, title, lead], i) => {
    const look = stageLook[i];
    const centre = look.icon
      ? `<span class="disc">${icon(look.icon, look.ink)}</span>`
      : `<span class="photo"><img src="${asset('baby-0d3f8.jpg')}"></span>`;
    shoot(
      `og-${locale}-stage${i + 1}`,
      page(
        locale,
        `<div class="panel"><span class="c a"></span><span class="c b"></span><span class="c d"></span><span class="num">${i + 1}</span>${centre}</div>
<div class="copy">${lockup}<span class="pill" style="background:${look.soft};color:${look.ink}">${t.stage} ${i + 1} · ${ages}</span>
<h1 style="font-size:60px">${title}</h1><span class="cap">${lead}</span></div>`,
        `.panel{position:absolute;right:60px;top:85px;width:460px;height:460px;border-radius:44px;background:${look.soft};overflow:hidden}
.c{position:absolute;border-radius:50%;background:#fff}.a{left:220px;top:150px;width:330px;height:330px;opacity:.45}.b{left:-50px;top:-50px;width:190px;height:190px;opacity:.35}.d{left:350px;top:-25px;width:120px;height:120px;opacity:.5}
.num{position:absolute;left:26px;top:170px;font-weight:700;font-size:200px;line-height:1;color:${look.ink};opacity:.1}
.disc,.photo{position:absolute;left:50%;top:50%;transform:translate(-50%,-50%);border-radius:50%}
.disc{width:200px;height:200px;background:#fff;padding:55px}
.photo{width:220px;height:220px;border:8px solid #fff;overflow:hidden;background:#EEF6F5}.photo img{width:100%;height:100%;object-fit:cover}`,
      ),
      1200,
      630,
      pub('og', `${locale}-stage${i + 1}.png`),
    );
  });
}
