import sharp, { type OverlayOptions } from 'sharp';
import { ZipArchive } from 'archiver';
import { fileURLToPath } from 'node:url';
import type { PrintDesign } from '@child-life/contracts';

export const printDimensions = {
  '10x15': [100, 150],
  '13x18': [130, 180],
  '15x21': [150, 210],
  '15x15': [150, 150],
  '20x20': [200, 200],
} as const;
export const printPageCount = (d: PrintDesign) =>
  d.product === 'book' ? d.pages : d.product === 'five' ? 5 : d.product === 'trio' ? 3 : 1;
export function printSlots(d: PrintDesign, page: number): number[] {
  if (d.pagePhotos[page] !== undefined) return d.pagePhotos[page]!;
  if (d.product === 'book') {
    const layout =
      d.pageLayouts[page] ??
      (page === 1 ? 'text' : page > 0 && page % 2 === 0 ? 'collage' : 'portrait');
    return layout === 'text'
      ? []
      : Array.from({ length: layout === 'collage' ? 4 : 1 }, (_, i) =>
          d.mediaIds.length ? (page + i) % d.mediaIds.length : 0,
        );
  }
  const role = d.pageLayouts[page]
    ? d.pageLayouts[page] === 'text'
      ? 1
      : d.pageLayouts[page] === 'collage'
        ? 2
        : 0
    : d.product === 'single'
      ? 0
      : page;
  if (role === 1) return [];
  if (role === 2) return [1, 2, 3, 4];
  return [page === 0 ? 0 : page + 2];
}
export interface PrintSource {
  bytes: Buffer;
  width: number;
  height: number;
}
export function printQuality(d: PrintDesign, sources: PrintSource[]): number[] {
  const [w, h] = printDimensions[d.size];
  return sources.map((s) =>
    Math.floor(Math.min(s.width / ((w * 0.82) / 25.4), s.height / ((h * 0.66) / 25.4))),
  );
}
const escape = (s: string) =>
  s.replace(
    /[&<>"']/g,
    (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&apos;' })[c]!,
  );
const fontDir = fileURLToPath(new URL('./print-fonts/', import.meta.url));
process.env.FONTCONFIG_FILE ??= `${fontDir}fonts.conf`;

/** Production-sized composition, never a screenshot. Text is rendered with bundled OFL fonts. */
export async function renderPrintPage(
  d: PrintDesign,
  sources: PrintSource[],
  page: number,
  cropMarks: boolean,
): Promise<Buffer> {
  const [mmW, mmH] = printDimensions[d.size];
  const px = (mm: number) => Math.round((mm / 25.4) * 300);
  const bleed = px(3),
    mark = cropMarks ? px(5) : 0,
    inset = bleed + mark;
  const w = px(mmW),
    h = px(mmH),
    width = w + inset * 2,
    height = h + inset * 2;
  const playful = d.style === 'playful',
    timeless = d.style === 'timeless';
  const paper = playful ? '#fceef1' : timeless ? '#ece5da' : '#f8f3ea';
  const ink = playful ? '#2f4858' : timeless ? '#4a3f35' : '#3b3229';
  const accent = playful ? '#e9a23b' : timeless ? '#8c7b66' : '#b89b72';
  const isBook = d.product === 'book',
    isInfo =
      !isBook &&
      (d.pageLayouts[page] ? d.pageLayouts[page] === 'text' : d.product !== 'single' && page === 1);
  const slots = printSlots(d, page),
    bookCover = isBook && page === 0;
  const layout =
    d.pageLayouts[page] ??
    (page === 1 ? 'text' : page > 0 && page % 2 === 0 ? 'collage' : 'portrait');
  let svg = `<svg width="${width}" height="${height}" xmlns="http://www.w3.org/2000/svg"><rect width="100%" height="100%" fill="${paper}"/>`;
  const line = (x1: number, y1: number, x2: number, y2: number) =>
    `<path d="M${x1} ${y1}L${x2} ${y2}" stroke="#333" stroke-width="2"/>`;
  if (cropMarks)
    for (const x of [inset, inset + w])
      for (const y of [inset, inset + h]) {
        svg += line(x, y < height / 2 ? 0 : height - mark, x, y < height / 2 ? mark : height);
        svg += line(x < width / 2 ? 0 : width - mark, y, x < width / 2 ? mark : width, y);
      }
  if (timeless)
    for (const pad of [0.04, 0.06])
      svg += `<rect x="${inset + w * pad}" y="${inset + h * pad}" width="${w * (1 - 2 * pad)}" height="${h * (1 - 2 * pad)}" fill="none" stroke="${accent}" stroke-width="${w * 0.0034}"/>`;
  if (playful)
    for (const [x, y] of [
      [0.07, 0.06],
      [0.88, 0.1],
      [0.93, 0.8],
      [0.05, 0.85],
    ])
      svg += `<circle cx="${inset + w * x!}" cy="${inset + h * y!}" r="${w * 0.0175}" fill="${accent}"/>`;
  if (isInfo)
    svg += `<rect x="${inset + w * 0.3846}" y="${inset + h * 0.5111}" width="${w * 0.2308}" height="${h * 0.0033}" fill="${accent}"/>`;
  svg += '</svg>';
  const layers: OverlayOptions[] = [];
  async function photo(slot: number, x: number, y: number, pw: number, ph: number, circle = false) {
    const source = sources[slot];
    if (!source) throw new Error('photos-missing');
    const iw = Math.round(w * pw),
      ih = Math.round(h * ph);
    let image = sharp(source.bytes, { limitInputPixels: 80_000_000 })
      .rotate()
      .resize(iw, ih, { fit: 'cover', position: 'centre' });
    if (circle)
      image = image.composite([
        {
          input: Buffer.from(
            `<svg width="${iw}" height="${ih}"><ellipse cx="${iw / 2}" cy="${ih / 2}" rx="${iw / 2}" ry="${ih / 2}" fill="white"/></svg>`,
          ),
          blend: 'dest-in',
        },
      ]);
    layers.push({
      input: await image.png().toBuffer(),
      left: inset + Math.round(w * x),
      top: inset + Math.round(h * y),
    });
  }
  async function text(
    value: string,
    y: number,
    size: number,
    font: 'title' | 'italic' | 'body' = 'body',
    color = ink,
    maxHeight = 0.16,
  ) {
    if (!value) return;
    const family =
      font === 'body'
        ? 'Be Vietnam Pro'
        : timeless
          ? 'Cormorant Garamond'
          : playful
            ? 'Baloo 2'
            : 'Playfair Display';
    const filename =
      font === 'body'
        ? 'BeVietnamPro-Light.ttf'
        : timeless
          ? font === 'italic'
            ? 'CormorantGaramond-Italic.ttf'
            : 'CormorantGaramond.ttf'
          : playful
            ? 'Baloo2-Bold.ttf'
            : font === 'italic'
              ? 'PlayfairDisplay-Italic.ttf'
              : 'PlayfairDisplay-Regular.ttf';
    let scale = 1,
      block;
    for (let n = 0; n < 12; n++) {
      block = await sharp({
        text: {
          text: `<span foreground="${color}">${escape(value)}</span>`,
          font: `${family} ${font === 'italic' ? 'Italic ' : font === 'body' ? 'Light ' : playful ? 'Bold ' : ''}${Math.max(1, Math.round(w * size * scale))}`,
          fontfile: `${fontDir}${filename}`,
          width: Math.round(w * 0.875),
          align: 'centre',
          rgba: true,
          wrap: 'word',
        },
      })
        .png()
        .toBuffer({ resolveWithObject: true });
      if (block.info.height <= h * maxHeight) break;
      scale *= 0.91;
    }
    if (!block || block.info.height > h * maxHeight) throw new Error('text-overflow');
    layers.push({
      input: block.data,
      left: inset + Math.round((w - block.info.width) / 2),
      top: inset + Math.round(h * y),
    });
  }
  const title = d.pageTitles[page] ?? (bookCover ? `${d.title}\n${d.name}` : ''),
    subtitle = d.pageSubtitles[page] ?? '';
  if (isBook && layout === 'text') {
    await text(title, 0.28, 0.08, 'title', accent);
    await text(d.message, 0.44, 0.055, 'italic', ink, 0.4);
  } else if (isBook) {
    if (slots.length === 4)
      for (let i = 0; i < 4; i++)
        await photo(
          slots[i]!,
          0.09375 + (i % 2) * 0.425,
          0.075 + Math.floor(i / 2) * 0.425,
          0.3875,
          0.3875,
        );
    else if (slots.length)
      await photo(
        slots[0]!,
        bookCover ? 0.1333 : 0.09375,
        bookCover ? 0.12 : 0.0875,
        bookCover ? 0.7333 : 0.8125,
        bookCover ? 0.5333 : 0.625,
      );
    await text(
      title,
      bookCover ? 0.69 : slots.length === 4 ? 0.9 : 0.75,
      bookCover ? 0.08 : slots.length === 4 ? 0.05625 : 0.06875,
      'title',
      ink,
      bookCover ? 0.18 : 0.12,
    );
    if (subtitle) await text(subtitle, 0.85, 0.0375, 'body', accent);
    if (bookCover) await text(d.date.split('-').reverse().join('.'), 0.916, 0.035, 'body', accent);
  } else if (isInfo) {
    await text('HELLO, LITTLE ONE', 0.1222, 0.0423, 'body', accent);
    await text(d.name, 0.1667, 0.2077, 'title', ink, 0.23);
    await text(d.title, 0.3778, 0.0923, 'italic', accent);
    const birth = d.birthDetails.split('\n');
    if (d.showBirthDetails && birth[0]) {
      await text(d.locale === 'vi' ? 'NGÀY SINH' : 'DATE OF BIRTH', 0.5556, 0.0323, 'body', accent);
      await text(birth[0], 0.5833, 0.0654, 'title');
      if (birth.length > 1) {
        await text(
          d.locale === 'vi' ? 'CÂN NẶNG · CHIỀU DÀI' : 'WEIGHT · LENGTH',
          0.6667,
          0.0323,
          'body',
          accent,
        );
        await text(birth.slice(1).join(' · '), 0.6944, 0.0654, 'title');
      }
    }
    await text(d.message, 0.8889, 0.04615, 'italic');
  } else {
    if (slots.length === 4)
      for (let i = 0; i < 4; i++)
        await photo(
          slots[i]!,
          0.0923 + (i % 2) * 0.4231,
          0.0778 + Math.floor(i / 2) * 0.3433,
          0.3923,
          0.3258,
        );
    else if (slots.length)
      await photo(
        slots[0]!,
        playful ? 0.1429 : 0.0923,
        playful ? 0.1026 : 0.0778,
        playful ? 0.7143 : 0.8154,
        playful ? 0.5128 : 0.6356,
        playful,
      );
    await text(
      slots.length === 4 ? `${d.name} — ${d.title}` : d.name,
      slots.length === 4 ? 0.79 : playful ? 0.72 : 0.7471,
      slots.length === 4 ? 0.085 : playful ? 0.14 : 0.1385,
      'title',
    );
    if (slots.length !== 4)
      await text(
        `${d.title.toUpperCase()} · ${d.date.split('-').reverse().join('.')}`,
        playful ? 0.88 : 0.886,
        0.0423,
        'body',
        accent,
      );
  }
  return sharp(Buffer.from(svg)).composite(layers).withMetadata({ density: 300 }).png().toBuffer();
}

/** Image PDF: raster artwork at 300 DPI, exact physical page size, TrimBox = finished size. */
export async function printPdf(
  pages: Buffer[],
  design: PrintDesign,
  cropMarks: boolean,
): Promise<Buffer> {
  const [mw, mh] = printDimensions[design.size];
  const margin = 3 + (cropMarks ? 5 : 0),
    pt = (v: number) => (v / 25.4) * 72;
  const w = pt(mw + margin * 2),
    h = pt(mh + margin * 2);
  const objects: Buffer[] = [];
  const put = (s: string | Buffer) => objects.push(typeof s === 'string' ? Buffer.from(s) : s);
  put('<< /Type /Catalog /Pages 2 0 R >>');
  put(
    `<< /Type /Pages /Count ${pages.length} /Kids [${pages.map((_, i) => `${3 + i * 3} 0 R`).join(' ')}] >>`,
  );
  for (let i = 0; i < pages.length; i++) {
    const img = await sharp(pages[i]!)
      .jpeg({ quality: 98, chromaSubsampling: '4:4:4' })
      .toBuffer({ resolveWithObject: true });
    const n = 3 + i * 3;
    put(
      `<< /Type /Page /Parent 2 0 R /MediaBox [0 0 ${w} ${h}] /TrimBox [${pt(margin)} ${pt(margin)} ${pt(margin + mw)} ${pt(margin + mh)}] /Resources << /XObject << /Im ${n + 1} 0 R >> >> /Contents ${n + 2} 0 R >>`,
    );
    put(
      Buffer.concat([
        Buffer.from(
          `<< /Type /XObject /Subtype /Image /Width ${img.info.width} /Height ${img.info.height} /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length ${img.data.length} >>\nstream\n`,
        ),
        img.data,
        Buffer.from('\nendstream'),
      ]),
    );
    const content = `q ${w} 0 0 ${h} 0 0 cm /Im Do Q`;
    put(`<< /Length ${Buffer.byteLength(content)} >>\nstream\n${content}\nendstream`);
  }
  const chunks = [Buffer.from('%PDF-1.4\n')],
    offsets = [0];
  let length = chunks[0]!.length;
  objects.forEach((o, i) => {
    offsets.push(length);
    const b = Buffer.concat([Buffer.from(`${i + 1} 0 obj\n`), o, Buffer.from('\nendobj\n')]);
    chunks.push(b);
    length += b.length;
  });
  chunks.push(
    Buffer.from(
      `xref\n0 ${objects.length + 1}\n0000000000 65535 f \n${offsets
        .slice(1)
        .map((n) => `${String(n).padStart(10, '0')} 00000 n \n`)
        .join(
          '',
        )}trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n${length}\n%%EOF`,
    ),
  );
  return Buffer.concat(chunks);
}
export async function printArchive(pages: Buffer[], format: 'jpg' | 'png'): Promise<Buffer> {
  const zip = new ZipArchive({ zlib: { level: 1 } }),
    chunks: Buffer[] = [];
  const done = new Promise<Buffer>((resolve, reject) => {
    zip.on('data', (b: Buffer) => chunks.push(b));
    zip.on('error', reject);
    zip.on('end', () => resolve(Buffer.concat(chunks)));
  });
  for (let i = 0; i < pages.length; i++)
    zip.append(
      format === 'png'
        ? pages[i]!
        : await sharp(pages[i]!)
            .jpeg({ quality: 98, chromaSubsampling: '4:4:4' })
            .withMetadata({ density: 300 })
            .toBuffer(),
      { name: `print-${String(i + 1).padStart(2, '0')}.${format}` },
    );
  await zip.finalize();
  return done;
}
