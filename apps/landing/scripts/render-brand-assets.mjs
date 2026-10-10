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

// Open Graph 1200 × 630, copy from the hero (src/content/{vi,en}.ts → hero).
const og = {
  vi: {
    eyebrow: 'Miễn phí cho cả gia đình',
    title: ['Cùng chăm con.', 'Giữ từng khoảnh khắc', 'con lớn lên.'],
    caption: 'Có trên iPhone và Android',
  },
  en: {
    eyebrow: 'Free for the whole family',
    title: ['Care for your baby together.', 'Keep every moment', 'as they grow.'],
    caption: 'On iPhone and Android',
  },
};
for (const [locale, t] of Object.entries(og)) {
  const html = `<!doctype html><html lang="${locale}"><head><meta charset="utf-8"><style>
@font-face{font-family:BVP;font-weight:600;src:url(${font('be-vietnam-pro-semibold.woff2')})}
@font-face{font-family:BVP;font-weight:700;src:url(${font('be-vietnam-pro-bold.woff2')})}
*{box-sizing:border-box}body{margin:0;width:1200px;height:630px;overflow:hidden;background:#F6FCFB;font-family:BVP;color:#173D44}
.circle{position:absolute;right:-90px;top:-40px;width:640px;height:640px;border-radius:50%;background:#E6F7F5}
.copy{position:absolute;left:80px;top:72px;width:690px;display:flex;flex-direction:column;gap:28px}
.lockup{display:flex;align-items:center;gap:12px}.lockup img:first-child{width:46px;height:46px}.lockup img:last-child{height:36px}
.pill{align-self:flex-start;padding:10px 18px;border-radius:999px;background:#E6F7F5;color:#06716D;font-weight:600;font-size:22px}
h1{margin:0;font-weight:700;font-size:${locale === 'vi' ? 60 : 54}px;line-height:1.1;letter-spacing:-1.3px}h1 span{display:block;text-wrap:balance}h1 span+span{color:#06716D}
.cap{font-weight:600;font-size:22px;color:#55707A}
.panel{position:absolute;right:56px;top:84px;width:360px;height:430px;border-radius:44px;background:#FFD166;overflow:hidden;box-shadow:0 30px 60px rgba(13,38,38,.18);rotate:3deg}
.panel img{position:absolute;left:0;top:0;width:360px;height:428px}
</style></head><body><div class="circle"></div>
<div class="panel"><img src="${asset('cungcham-family.svg')}"></div>
<div class="copy"><div class="lockup"><img src="${asset('nav-logo-mark.svg')}"><img src="${asset('nav-logo-wordmark.svg')}"></div>
<span class="pill">● ${t.eyebrow}</span><h1>${t.title.map((l) => `<span>${l}</span>`).join('')}</h1><span class="cap">${t.caption}</span></div>
</body></html>`;
  shoot(`og-${locale}`, html, 1200, 630, pub('og', `${locale}.png`));
}
