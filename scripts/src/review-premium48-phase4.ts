/** Package the exact Flutter cards and Remotion videos into an offline owner-review gallery. */
import { createHash } from 'node:crypto';
import { existsSync, readFileSync, writeFileSync, copyFileSync, mkdirSync } from 'node:fs';
import { join, resolve } from 'node:path';
import sharp from 'sharp';
const root = resolve(import.meta.dirname, '../..'),
  out = join(root, 'artifacts/premium48-phase4');
const photos = JSON.parse(
  readFileSync(join(root, 'design/sample-photos/premium48-phase4-licence.json'), 'utf8'),
) as { file: string; creator: string; source: string; licence: string; download: string }[];
const old = JSON.parse(readFileSync(join(root, 'design/sample-photos/licence.json'), 'utf8')) as {
  file: string;
  download: string;
}[];
const hash = (path: string) => createHash('sha256').update(readFileSync(path)).digest('hex');
old.push(
  ...JSON.parse(
    readFileSync(join(root, 'design/sample-photos/premium48-phase2-licence.json'), 'utf8'),
  ),
);
old.push(
  ...JSON.parse(
    readFileSync(join(root, 'design/sample-photos/premium48-phase3-licence.json'), 'utf8'),
  ),
);
const oldHashes = new Set(
  old.map((p) => {
    const dir = [
      '/tmp/child-life-p48-photos',
      '/tmp/child-life-p48-phase2-photos',
      '/tmp/child-life-p48-phase3-photos',
    ].find((d) => existsSync(join(d, p.file)));
    if (!dir) throw new Error('Previous sample missing for freshness check');
    return hash(join(dir, p.file));
  }),
);
const used = photos.map((p) => ({
  ...p,
  sha256: hash(join('/tmp/child-life-p48-phase4-photos', p.file)),
}));
if (
  used.length !== 7 ||
  new Set(used.map((p) => p.sha256)).size !== 7 ||
  used.some((p) => oldHashes.has(p.sha256))
)
  throw new Error('Fresh preview photo check failed');
writeFileSync(
  join(out, 'photo-qa.json'),
  JSON.stringify({ count: 7, distinctFromExistingCatalog: true, photos: used }, null, 2),
);
const sampleDir = join(out, 'samples');
mkdirSync(sampleDir, { recursive: true });
for (const p of photos)
  copyFileSync(join('/tmp/child-life-p48-phase4-photos', p.file), join(sampleDir, p.file));
for (const id of ['C07', 'C08'])
  for (const locale of ['vi', 'en'])
    for (const format of ['portrait', 'story']) {
      const file = join(out, `${id}-${locale}-${format}`);
      if (!existsSync(file + '.png')) throw new Error(`Card not rendered: ${file}`);
      await sharp(file + '.png')
        .jpeg({ quality: 95, chromaSubsampling: '4:4:4' })
        .toFile(file + '.jpg');
    }
for (const id of ['V07', 'V08'])
  for (const locale of ['vi', 'en'])
    for (const format of ['portrait', 'story'])
      if (!existsSync(join(out, `${id}-${locale}-${format}.mp4`)))
        throw new Error(`Video not rendered: ${id}/${locale}/${format}`);
const esc = (s: string) =>
  s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('"', '&quot;');
writeFileSync(
  join(out, 'photo-credits.html'),
  `<!doctype html><html lang="vi"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Phase 4 · Ảnh demo mới / New demo photos</title><style>body{max-width:1100px;margin:40px auto;padding:0 20px;font:16px system-ui;color:#414b34;background:#fffdf7}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:24px}img{width:100%;height:240px;object-fit:contain;background:#f3ecdf}p{font-size:14px;line-height:1.6}a{color:#79815c}</style><a href="index.html">← Preview phase 4</a><h1>7 ảnh demo mới / 7 new demo photos</h1><p>Hai bộ ảnh riêng cho V07 và V08; không trùng bộ ảnh của catalog cũ. Ảnh minh họa, không khẳng định quan hệ gia đình hoặc khoảng thời gian thực tế giữa hai ảnh. Demo C08/V08 để trống ngày, không tính thời gian từ ảnh stock.</p><main>${photos.map((p, i) => `<article><img src="samples/${p.file}" alt="${esc(p.creator)}"><h3>${i < 5 ? 'V07' : 'V08'} · ${(i % 5) + 1}</h3><p>${esc(p.creator)} · ${esc(p.licence)}<br><a href="${esc(p.source)}">Nguồn ảnh / Photo source</a></p></article>`).join('')}</main><p><a href="https://www.pexels.com/license/">Pexels License</a></p></html>`,
);
const panel = (id: string, video: boolean) =>
  `<article data-id="${id}" data-video="${video}"><header><span class="id">${id}</span><h3 data-title="${id}"></h3><p class="count">${video ? (id === 'V08' ? '2 ảnh · 35 giây' : '5 ảnh · 35 giây') : id === 'C07' ? '3 ảnh' : '2 ảnh'}</p></header>${video ? '<video controls playsinline preload="metadata"></video>' : '<img class="card" alt="Thiệp phase 4">'}<footer>${video ? '<a class="download movie" download>MP4</a>' : '<a class="download png" download>PNG</a><a class="download jpg" download>JPEG</a>'}</footer></article>`;
writeFileSync(
  join(out, 'index.html'),
  `<!doctype html><html lang="vi"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Child Life · Premium 48 · Phase 4</title><style>*{box-sizing:border-box}body{margin:0;background:#faf7f1;color:#403a31;font:16px system-ui}main,nav,.intro{max-width:1260px;margin:auto;padding:28px}.intro{padding-top:56px}h1{font:48px Georgia;margin:16px 0}h2{font:32px Georgia;margin:8px 0 28px}h3{font:24px Georgia;margin:10px 0}.eyebrow,.id{font-size:12px;letter-spacing:2px;color:#79815c}.intro p{max-width:800px;line-height:1.7;color:#756957}.toolbar{display:flex;gap:20px;align-items:center;flex-wrap:wrap;position:sticky;top:0;background:#faf7f1ed;backdrop-filter:blur(10px);z-index:2;border-block:1px solid #e6ddcf}select{font:inherit;background:#fffdf8;color:#414b34;padding:10px 14px;border:1px solid #d7cdbd;border-radius:8px}.grid{display:grid;grid-template-columns:1fr 1fr;gap:32px;margin-bottom:64px}article{border:1px solid #e9dfcf;border-radius:16px;overflow:hidden;background:#fffdf8}article header{padding:24px}.count{font-size:14px;color:#756957}video,.card{display:block;object-fit:contain;width:100%;max-height:740px;background:#ede4d6}footer{display:flex;gap:12px;padding:20px}a{color:#68754b}a.download{border:1px solid #d9cdbb;border-radius:8px;text-decoration:none;padding:8px 16px}nav{display:flex;gap:24px;flex-wrap:wrap;font-size:14px}.note{color:#756957;font-size:14px;line-height:1.7;margin-bottom:48px}@media(max-width:700px){.grid{grid-template-columns:1fr}h1{font-size:36px}.intro,main,nav{padding:20px}}</style><div class="intro"><span class="eyebrow">CHILD LIFE / PREMIUM COLLECTION / PHASE 04</span><h1>Một trang tháng. Hai khoảnh khắc.</h1><p>2 thiệp + 2 video · 20 asset mới · 7 ảnh demo mới. Thử cả tiếng Việt, English và hai tỷ lệ trước khi chọn ảnh riêng để tạo kỷ niệm của nhà mình.</p></div><div class="toolbar"><nav><label>Ngôn ngữ <select id="locale"><option value="vi">Tiếng Việt</option><option value="en">English</option></select></label><label>Tỷ lệ <select id="format"><option value="portrait">4:5</option><option value="story">9:16</option></select></label><a href="assets.html">20 asset gốc</a><a href="photo-credits.html">7 ảnh demo & nguồn</a><a href="https://www.figma.com/design/8xApPL1XnwD4n1bpr0dPhq?node-id=16-3">Figma</a></nav></div><main><span class="eyebrow">C07 + V07</span><h2>Lớn từng ngày / Growing Every Day</h2><div class="grid">${panel('C07', false)}${panel('V07', true)}</div><span class="eyebrow">C08 + V08</span><h2>Lớn từng ngày / Growing Every Day</h2><div class="grid">${panel('C08', false)}${panel('V08', true)}</div><p class="note">Bản dùng thử phase 4. Video có đầu vào ảnh, đổi/tắt nhạc và chuyển động nhẹ. Thiệp xem chuyển động 4 giây trong app, xuất PNG/JPEG tĩnh. Nhạc demo là score gốc tổng hợp. Chưa nghiệm thu bản in vật lý.</p></main><script>const titles={C07:{vi:'Trang tháng của con',en:'Your Monthly Chapter'},V07:{vi:'Trang tháng của con',en:'Your Monthly Chapter'},C08:{vi:'Ngày ấy, bây giờ',en:'Then & Now'},V08:{vi:'Ngày ấy, bây giờ',en:'Then & Now'}};function refresh(){const locale=document.getElementById('locale').value,format=document.getElementById('format').value;document.documentElement.lang=locale;for(const article of document.querySelectorAll('article')){const id=article.dataset.id,video=article.dataset.video==='true',stem=id+'-'+locale+'-'+format;article.querySelector('h3').textContent=titles[id][locale];if(video){const v=article.querySelector('video');v.pause();v.src=stem+'.mp4';v.poster=stem+'-990.png';v.load();article.querySelector('.movie').href=stem+'.mp4';}else{article.querySelector('img').src=stem+'.png';article.querySelector('.png').href=stem+'.png';article.querySelector('.jpg').href=stem+'.jpg';}}}document.getElementById('locale').addEventListener('change',refresh);document.getElementById('format').addEventListener('change',refresh);refresh();</script></html>`,
);
console.log('Phase 4 gallery ready: 8 card PNG/JPEGs, 8 MP4s, 7 fresh photos with credits.');
