/** Offline owner review gallery plus freshness and handoff receipts for phases 7–12. */
import { premium48FinalDesigns } from '@child-life/contracts';
import { createHash } from 'node:crypto';
import { copyFileSync, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { execFileSync } from 'node:child_process';
import sharp from 'sharp';
const root = resolve(import.meta.dirname, '../..'),
  complete = process.argv.includes('--complete');
type Photo = {
  file: string;
  download: string;
  source: string;
  creator: string;
  licence: string;
  templates: string[];
  slot: number;
};
const hash = (path: string) => createHash('sha256').update(readFileSync(path)).digest('hex');
const old: Photo[] = [],
  oldHashes = new Set<string>();
for (let phase = 1; phase <= 6; phase++) {
  const name = phase === 1 ? 'licence.json' : `premium48-phase${phase}-licence.json`,
    list = JSON.parse(readFileSync(join(root, 'design/sample-photos', name), 'utf8')) as Photo[];
  old.push(...list);
  for (const p of list) {
    const f = join(
      phase === 1 ? '/tmp/child-life-p48-photos' : `/tmp/child-life-p48-phase${phase}-photos`,
      p.file,
    );
    if (existsSync(f)) oldHashes.add(hash(f));
  }
}
const freshHashes = new Set<string>(),
  freshSources = new Set<string>();
const sourceKey = (p: Photo) => p.download.match(/\/photos\/(\d+)\//)?.[1] ?? p.source;
const oldSources = new Set(old.map(sourceKey));
const esc = (v: string) =>
  v.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('"', '&quot;');
const css = `*{box-sizing:border-box}body{margin:0;background:#faf7f1;color:#403a31;font:16px system-ui}header,main,nav{max-width:1240px;margin:auto;padding:28px}header{padding-top:48px}header img{width:160px}h1{font:44px Georgia}h2{font:30px Georgia}p{line-height:1.7;color:#756957}.grid{display:grid;grid-template-columns:1fr 1fr;gap:28px}article{background:#fffdf9;border:1px solid #e6ddcf;border-radius:12px;overflow:hidden}article h3,article p{padding:0 20px}article img,video{width:100%;max-height:720px;object-fit:contain;background:#eee6db}nav{position:sticky;top:0;background:#faf7f1f2;z-index:2;display:flex;gap:22px;flex-wrap:wrap;align-items:center;border-block:1px solid #e6ddcf}select{font:inherit;padding:10px}a{color:#60754e}footer{padding:18px;display:flex;gap:20px}.assets{display:grid;grid-template-columns:repeat(5,1fr);gap:16px}.assets img{width:100%;height:160px;object-fit:contain}.asset{padding:12px;border:1px solid #e6ddcf}.asset code{font-size:11px;overflow-wrap:anywhere}@media(max-width:700px){.grid{grid-template-columns:1fr}.assets{grid-template-columns:repeat(2,1fr)}h1{font-size:32px}}`;
for (let phase = 7; phase <= 12; phase++) {
  const out = join(root, `artifacts/premium48-phase${phase}`),
    ds = premium48FinalDesigns.filter((d) => Math.ceil(d.n / 2) === phase),
    photos = JSON.parse(
      readFileSync(join(root, `design/sample-photos/premium48-phase${phase}-licence.json`), 'utf8'),
    ) as Photo[],
    manifest = JSON.parse(
      readFileSync(join(root, `design/keepsake-art/premium48-phase${phase}-manifest.json`), 'utf8'),
    ) as { assets: { name: string; file: string }[] },
    figma = JSON.parse(
      readFileSync(join(root, `design/keepsake-art/premium48-phase${phase}-figma.json`), 'utf8'),
    ) as { boardId: string };
  mkdirSync(join(out, 'samples'), { recursive: true });
  mkdirSync(join(out, 'svg'), { recursive: true });
  copyFileSync(join(root, 'apps/mobile/assets/logo/lockup-h-tint.svg'), join(out, 'logo.svg'));
  const used = photos.map((p) => {
    const file = join(`/tmp/child-life-p48-phase${phase}-photos`, p.file),
      sha256 = hash(file),
      key = sourceKey(p);
    if (
      oldSources.has(key) ||
      freshSources.has(key) ||
      oldHashes.has(sha256) ||
      freshHashes.has(sha256)
    )
      throw new Error('Photo repeated: ' + p.file);
    freshHashes.add(sha256);
    freshSources.add(key);
    copyFileSync(file, join(out, 'samples', p.file));
    return { ...p, sha256 };
  });
  writeFileSync(
    join(out, 'photo-qa.json'),
    JSON.stringify(
      {
        count: used.length,
        distinctFromExistingCatalog: true,
        distinctAcrossNewPhases: true,
        previousPhotosHashed: oldHashes.size,
        photos: used,
      },
      null,
      2,
    ) + '\n',
  );
  for (const a of manifest.assets)
    copyFileSync(join(root, 'design/keepsake-art', a.file), join(out, 'svg', a.file));
  execFileSync('python3', [
    '-c',
    "import zipfile,pathlib,sys; p=pathlib.Path(sys.argv[1]); z=zipfile.ZipFile(p/'assets-svg.zip','w',zipfile.ZIP_DEFLATED); [z.write(f,f.name) for f in sorted((p/'svg').glob('*.svg'))]; z.close()",
    out,
  ]);
  const wrapper = (title: string, body: string) =>
    `<!doctype html><html lang="vi"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>${esc(title)}</title><style>${css}</style>${body}</html>`;
  writeFileSync(
    join(out, 'photo-credits.html'),
    wrapper(
      `Phase ${phase} · Ảnh demo`,
      `<header><a href="index.html">← Phase ${phase}</a><h1>${photos.length} ảnh mới</h1><p>Ảnh stock minh họa từ nhiều gia đình. Tên tiếng Anh là tên demo; ảnh không khẳng định cùng một bé, tuổi thực, quan hệ hay trình tự thời gian thực tế. Ngày không rõ được để trống. <a href="https://www.pexels.com/license/">Pexels License</a></p></header><main class="grid">${photos.map((p) => `<article><img src="samples/${p.file}" alt="${esc(p.creator)}"><p>${p.templates.join(' / ')} · ${p.slot + 1}<br>${esc(p.creator)} · ${esc(p.licence)}<br><a href="${esc(p.source)}">Nguồn ảnh</a></p></article>`).join('')}</main>`,
    ),
  );
  writeFileSync(
    join(out, 'assets.html'),
    wrapper(
      `Phase ${phase} · Original assets`,
      `<header><a href="index.html">← Phase ${phase}</a><h1>${manifest.assets.length} SVG mới</h1><a href="assets-svg.zip" download>Tải SVG</a> · <a href="https://www.figma.com/design/8xApPL1XnwD4n1bpr0dPhq?node-id=${figma.boardId.replace(':', '-')}">Figma editable vectors</a></header><main class="assets">${manifest.assets.map((a) => `<div class="asset" style="background:${a.name.startsWith('p48-sleep-') ? '#444C62' : '#fffdf9'}"><img src="svg/${a.file}" alt="${a.name}"><code>${a.name}</code></div>`).join('')}</main>`,
    ),
  );
  const panels = ds
    .map(
      (d) =>
        `<section><h2>${esc(d.group.vi)} / ${esc(d.group.en)}</h2><div class="grid">${['C', 'V'].map((kind) => `<article data-id="${kind}${d.n}" data-video="${kind === 'V'}" data-poster="${d.n === 22 ? 1440 : 990}"><h3>${kind}${d.n} · ${esc(d.title.vi)}</h3><p>${kind === 'V' ? d.video : d.card} ảnh${kind === 'V' ? ` · ${d.n === 22 ? 50 : 35} giây` : ''} · ${d.baby}</p>${kind === 'V' ? '<video controls playsinline preload="metadata"></video>' : '<img class="card" alt="Thiệp">'}<footer>${kind === 'V' ? '<a class="movie" download>MP4</a>' : '<a class="png" download>PNG</a><a class="jpg" download>JPEG</a>'}</footer></article>`).join('')}</div></section>`,
    )
    .join('');
  const tracks = ds
    .flatMap((d) =>
      (d.n === 20 ? ['neutral', 'tet', 'christmas'] : ['default']).map(
        (variant) =>
          `<p>${esc(d.music.vi)} / ${esc(d.music.en)}${variant === 'default' ? '' : ` · ${variant}`} · ${d.bpm} BPM<br><audio controls preload="metadata" src="p48-${d.part}${variant === 'default' ? '' : `-${variant}`}.m4a"></audio></p>`,
      ),
    )
    .join('');
  const titles = Object.fromEntries(
    ds.flatMap((d) => ['C', 'V'].map((k) => [`${k}${d.n}`, d.title])),
  );
  writeFileSync(
    join(out, 'index.html'),
    wrapper(
      `Child Life · Phase ${phase}`,
      `<header><img src="logo.svg" alt="child life"><p>PREMIUM 48 · PHASE ${phase}</p><h1>${ds.map((d) => esc(d.title.vi)).join(' · ')}</h1><p>2 thiệp + 2 video · ${manifest.assets.length} assets mới · ${photos.length} ảnh mới · nhạc gốc mới.</p></header><nav><label>Ngôn ngữ <select id="locale"><option value="vi">Tiếng Việt</option><option value="en">English</option></select></label><label>Tỷ lệ <select id="format"><option value="portrait">4:5</option><option value="story">9:16</option></select></label><a href="assets.html">Assets & Figma</a><a href="photo-credits.html">Ảnh & nguồn</a><a href="../premium48-final/index.html">Tất cả phase 7–12</a></nav><main>${panels}<h2>Nhạc mới</h2>${tracks}<p>Ảnh demo chỉ minh họa. Có thể thay ảnh và sửa lời trong editor. Mẫu 12 tháng cần đủ 12 ảnh đúng vị trí trước khi xuất; nhãn tháng chỉ hiện khi bạn xác nhận thứ tự. Logo và tên nhóm giữ theo hệ hiện tại. Chỉ dev; thiệp xuất PNG/JPEG tĩnh.</p></main><script>const titles=${JSON.stringify(titles)};function refresh(){const locale=document.getElementById('locale').value,format=document.getElementById('format').value;document.documentElement.lang=locale;for(const a of document.querySelectorAll('article[data-id]')){const id=a.dataset.id,stem=id+'-'+locale+'-'+format;a.querySelector('h3').textContent=id+' · '+titles[id][locale];if(a.dataset.video==='true'){const v=a.querySelector('video');v.pause();v.src=stem+'.mp4';v.poster=stem+'-'+a.dataset.poster+'.png';v.load();a.querySelector('.movie').href=stem+'.mp4';}else{a.querySelector('img').src=stem+'.png';a.querySelector('.png').href=stem+'.png';a.querySelector('.jpg').href=stem+'.jpg';}}}document.getElementById('locale').addEventListener('change',refresh);document.getElementById('format').addEventListener('change',refresh);refresh();</script>`,
    ),
  );
  if (complete) {
    const files = [];
    for (const d of ds)
      for (const locale of ['vi', 'en'])
        for (const format of ['story', 'portrait']) {
          const stem = join(out, `C${d.n}-${locale}-${format}`);
          await sharp(stem + '.png')
            .jpeg({ quality: 95, chromaSubsampling: '4:4:4' })
            .toFile(stem + '.jpg');
          for (const name of [
            `C${d.n}-${locale}-${format}.png`,
            `C${d.n}-${locale}-${format}.jpg`,
            `V${d.n}-${locale}-${format}.mp4`,
            `V${d.n}-${locale}-${format}-${d.n === 22 ? 1440 : 990}.png`,
          ]) {
            if (!existsSync(join(out, name))) throw new Error('Missing review media ' + name);
            files.push({ file: name, sha256: hash(join(out, name)) });
          }
        }
    writeFileSync(
      join(out, 'handoff-qa.json'),
      JSON.stringify(
        {
          phase,
          status: 'passed',
          templates: 4,
          photos: used.length,
          assets: manifest.assets.length,
          files,
        },
        null,
        2,
      ) + '\n',
    );
  }
}
const out = join(root, 'artifacts/premium48-final');
mkdirSync(out, { recursive: true });
copyFileSync(join(root, 'apps/mobile/assets/logo/lockup-h-tint.svg'), join(out, 'logo.svg'));
writeFileSync(
  join(out, 'index.html'),
  `<!doctype html><html lang="vi"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Child Life · Premium 48 · Phase 7–12</title><style>${css}</style><header><img src="logo.svg" alt="child life"><h1>Những chương tiếp theo.</h1><p>Phase 7–12 · 12 thiệp + 12 video · 121 assets gốc · 63 ảnh demo mới · 14 bản nhạc mới. Đủ Việt/Anh, 4:5 và 9:16.</p><a href="https://child-life-dev-admin.web.app">Portal dev</a> · <a href="https://www.figma.com/design/8xApPL1XnwD4n1bpr0dPhq">Figma assets</a></header><main class="grid">${[
    7, 8, 9, 10, 11, 12,
  ]
    .map((phase) => {
      const ds = premium48FinalDesigns.filter((d) => Math.ceil(d.n / 2) === phase);
      return `<article><a href="../premium48-phase${phase}/index.html"><img src="../premium48-phase${phase}/C${ds[0]!.n}-en-portrait.png" alt="Phase ${phase}"><h3>Phase ${phase} · C${ds[0]!.n}–C${ds[1]!.n} / V${ds[0]!.n}–V${ds[1]!.n}</h3></a><p>${ds.map((d) => esc(d.title.vi)).join('<br>')}</p></article>`;
    })
    .join('')}</main></html>`,
);
console.log('Six galleries ready; all 63 photos are distinct from previous phases and each other.');
