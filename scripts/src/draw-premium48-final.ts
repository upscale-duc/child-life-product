/** Original vector library for phases 7–12. All paths are code-native, editable SVG. */
import { premium48FinalDesigns } from '@child-life/contracts';
import { mkdirSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
const root = resolve(import.meta.dirname, '../..'),
  dir = join(root, 'design/keepsake-art');
mkdirSync(dir, { recursive: true });
for (let phase = 7; phase <= 12; phase++) {
  const manifest: { name: string; file: string; title: string; width: number; height: number }[] =
    [];
  for (const d of premium48FinalDesigns.filter((d) => Math.ceil(d.n / 2) === phase)) {
    const ink = d.palette[1],
      a = d.palette[2],
      paper = d.palette[0];
    const path = (v: string, c: string = ink, w = 3) =>
      `<path d="${v}" fill="none" stroke="${c}" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round"/>`;
    const ellipse = (x: number, y: number, rx: number, ry: number, c: string = ink, w = 3) =>
      `<ellipse cx="${x}" cy="${y}" rx="${rx}" ry="${ry}" fill="none" stroke="${c}" stroke-width="${w}"/>`;
    const dot = (x: number, y: number, r: number, c: string = a) =>
      `<circle cx="${x}" cy="${y}" r="${r}" fill="${c}"/>`;
    const leaf = (x: number, y: number, flip = 1) =>
      `<path d="M${x} ${y}q${45 * flip} -80 ${10 * flip} -125q${-42 * flip} 45 ${-10 * flip} 125" fill="${a}" opacity=".65"/>`;
    const star = (x: number, y: number) =>
      `<path d="M${x} ${y - 36}l10 25 27 10-27 10-10 27-10-27-27-10 27-10Z" fill="${a}"/>`;
    const common: Record<string, string> = {
      frame: `<rect x="14" y="14" width="772" height="772" rx="${d.n === 14 ? 4 : 18}" fill="none" stroke="${a}" stroke-width="3"/>${path('M29 60V29H60M740 29H771V60M771 740V771H740M60 771H29V740', ink, 2)}`,
      oval: ellipse(400, 400, 386, 386, a, 4) + ellipse(400, 400, 374, 382, ink, 1.5),
      margin: path(`M30 145V30H145M655 30H770V145M770 655V770H655M145 770H30V655`, a, 2),
      label: `<path d="M80 310H720L760 400 720 490H80L40 400Z" fill="${paper}" stroke="${a}" stroke-width="3"/>${dot(90, 400, 9)}`,
      closing: path(`M50 400Q215 ${350 + d.n} 400 400T750 400`, a, 3) + dot(400, 400, 6),
    };
    const special: Record<string, Record<string, string>> = {
      held: {
        embrace: path(
          'M90 450C30 230 250 150 400 300C550 150 770 230 710 450M160 470C220 610 580 610 640 470',
          a,
          5,
        ),
        ribbon: path('M75 430Q250 250 400 430T725 430', a, 12),
        nested: ellipse(400, 400, 310, 360) + ellipse(400, 400, 280, 340, a),
        nameplate: path('M130 340H670M130 460H670', a),
        fold: path('M100 200Q400 280 700 200M100 600Q400 520 700 600', a),
      },
      generations: {
        branch:
          path('M80 640Q350 450 680 130', ink, 4) +
          leaf(210, 540) +
          leaf(410, 360, -1) +
          leaf(550, 230),
        connection: path('M90 480Q250 180 400 400T710 320', a, 5),
        doubleframe:
          '<rect x="35" y="45" width="730" height="710" fill="none" stroke="' +
          a +
          '" stroke-width="3"/><rect x="55" y="25" width="690" height="750" fill="none" stroke="' +
          ink +
          '" stroke-width="2"/>',
        archive: path('M100 160H700M100 190H380M100 640H700', a),
        seal: ellipse(400, 400, 130, 130, a) + leaf(400, 470),
      },
      circle: {
        orbit:
          ellipse(400, 400, 330, 280, a, 3) +
          [0, 1, 2, 3]
            .map((i) =>
              dot(
                400 + 330 * Math.cos((i * Math.PI) / 2),
                400 + 280 * Math.sin((i * Math.PI) / 2),
                14,
                i % 2 ? a : ink,
              ),
            )
            .join(''),
        connection: path('M100 400Q200 120 400 240T700 400Q550 700 400 560T100 400', a, 4),
        dots: [0, 1, 2, 3, 4, 5].map((i) => dot(120 + i * 110, 400, 9 + (i % 3) * 3)).join(''),
        petal: ellipse(310, 400, 150, 100, a) + ellipse(490, 400, 150, 100, ink),
        centre: ellipse(400, 400, 100, 100, a) + dot(400, 400, 12),
      },
      day: {
        sun:
          ellipse(400, 400, 100, 100, a, 5) +
          [0, 1, 2, 3, 4, 5, 6, 7]
            .map((i) => {
              const t = (i * Math.PI) / 4;
              return path(
                `M${400 + 140 * Math.cos(t)} ${400 + 140 * Math.sin(t)}L${400 + 185 * Math.cos(t)} ${400 + 185 * Math.sin(t)}`,
                a,
                5,
              );
            })
            .join(''),
        cloud: path(
          'M160 470C80 350 220 240 300 310C360 170 560 230 560 340C720 310 750 500 590 510H190',
          ink,
          6,
        ),
        moon:
          '<path d="M490 160C180 190 160 610 500 650C280 560 310 280 490 160Z" fill="' + a + '"/>',
        timeline:
          path('M70 400H730', a, 4) +
          [0, 1, 2, 3].map((i) => dot(100 + i * 200, 400, 15, ink)).join(''),
        contact: [0, 1, 2, 3, 4, 5, 6, 7]
          .map(
            (i) =>
              `<rect x="${55 + i * 95}" y="355" width="35" height="90" rx="5" fill="${a}" opacity=".6"/>`,
          )
          .join(''),
      },
      details: {
        film:
          path('M65 130H735V670H65Z', ink, 2) +
          [0, 1, 2, 3, 4, 5]
            .map(
              (i) =>
                `<rect x="${100 + i * 110}" y="85" width="40" height="20" fill="${a}"/><rect x="${100 + i * 110}" y="695" width="40" height="20" fill="${a}"/>`,
            )
            .join(''),
        rule:
          path('M70 400H730', a, 2) +
          [0, 1, 2, 3, 4, 5, 6].map((i) => path(`M${100 + i * 100} 385V415`, ink, 2)).join(''),
        caption: path('M80 310H560M80 380H720M80 450H380', a, 3),
        cotton: path(
          'M110 250Q250 300 380 250T690 250M110 400Q250 450 380 400T690 400M110 550Q250 600 380 550T690 550',
          a,
          1,
        ),
        viewfinder: path('M250 130H130V250M550 130H670V250M670 550V670H550M250 670H130V550', a, 4),
      },
      sleep: {
        moon:
          '<path d="M510 120C160 140 140 670 540 680C260 550 290 270 510 120Z" fill="' + a + '"/>',
        stars:
          star(140, 170) + star(630, 240) + star(330, 660) + dot(560, 580, 6) + dot(200, 450, 5),
        arch: path('M160 690V340C160 30 640 30 640 340V690', a, 5),
        constellation:
          path('M110 530L260 220 450 390 670 150', a, 2) +
          dot(110, 530, 9) +
          dot(260, 220, 12) +
          dot(450, 390, 8) +
          dot(670, 150, 10),
        horizon: path('M60 570Q250 470 400 530T740 570', a, 3),
      },
      hundred: {
        numeral: path(
          'M80 290L150 250V550M385 250C230 250 230 550 385 550C540 550 540 250 385 250M650 250C495 250 495 550 650 550C805 550 805 250 650 250',
          ink,
          18,
        ),
        ring: ellipse(400, 400, 300, 300, a, 14) + ellipse(400, 400, 275, 275, ink, 2),
        gold: [0, 1, 2, 3, 4, 5, 6]
          .map((i) => dot(100 + i * 100, 350 + 40 * Math.sin(i), 7 + (i % 3) * 2))
          .join(''),
        chapter: path('M80 470V330H720V470', a, 4),
        fold: path('M80 100H720L680 160H120Z', a, 3),
      },
      celebrate: {
        'neutral-corner':
          path('M80 260Q380 450 720 200', ink, 3) +
          '<path d="M180 310L220 470 300 355M440 340L500 490 550 310" fill="' +
          a +
          '"/>',
        'neutral-ribbon': path('M35 350Q225 460 400 350T765 350', a, 8),
        'tet-corner':
          path('M160 700Q300 410 630 140', '#76543F', 5) +
          [0, 1, 2]
            .map((i) => {
              const x = 270 + i * 150,
                y = 540 - i * 150;
              return (
                [0, 1, 2, 3, 4]
                  .map(
                    (j) =>
                      `<ellipse cx="${x}" cy="${y - 25}" rx="18" ry="30" transform="rotate(${j * 72} ${x} ${y})" fill="#DCA182"/>`,
                  )
                  .join('') + dot(x, y, 10, '#B95746')
              );
            })
            .join(''),
        'tet-ribbon':
          '<path d="M60 360H740V440H60Z" fill="#B95746"/><path d="M320 280H480V520H320Z" fill="#B95746"/>' +
          path('M320 280L400 340 480 280', '#EBCB8B', 4),
        'christmas-corner':
          path('M140 680L620 160', '#426858', 5) +
          [0, 1, 2, 3, 4]
            .map((i) => path(`M${220 + i * 70} ${590 - i * 75}l-80 -15m80 15l5 90`, '#426858', 14))
            .join('') +
          star(640, 150),
        'christmas-ribbon': path('M50 400Q220 320 400 400T750 400', '#426858', 9),
      },
      adventure: {
        route:
          '<path d="M60 520C210 100 310 690 460 300S680 530 750 240" fill="none" stroke="' +
          a +
          '" stroke-width="7" stroke-dasharray="3 19" stroke-linecap="round"/>',
        tag:
          '<path d="M180 130H620V600L400 730 180 600Z" fill="none" stroke="' +
          a +
          '" stroke-width="5"/>' +
          ellipse(400, 220, 25, 25, ink),
        stamp: path('M110 160H690V640H110Z', a, 7) + path('M150 200H650V600H150Z', ink, 2),
        ticket: path('M100 260H700V540H100Z', a, 4) + path('M230 260V540', a, 3),
        compass:
          ellipse(400, 400, 220, 220, a) +
          path('M400 200V600M200 400H600M400 270L460 460 400 420 340 460Z', ink, 3),
      },
      months: {
        tabs: [0, 1, 2, 3]
          .map(
            (i) =>
              `<path d="M${80 + i * 180} 300h130v200l-65-35-65 35Z" fill="${i % 2 ? a : ink}" opacity=".65"/>`,
          )
          .join(''),
        grid:
          [1, 2].map((i) => path(`M${100 + i * 200} 100V700`, a, 2)).join('') +
          [1, 2, 3].map((i) => path(`M100 ${100 + i * 150}H700`, a, 2)).join(''),
        spine: path('M330 60V740M360 60V740M430 60V740', a, 3),
        seasons: ellipse(270, 300, 120, 120, a) + ellipse(530, 500, 120, 120, ink),
        year: path('M120 160H680M120 640H680', a, 5) + dot(400, 400, 16),
      },
      birthday: {
        one: path('M250 240L420 150V650M270 650H580', a, 15),
        bow: path(
          'M400 400C150 110 70 560 400 400C730 100 740 570 400 400L280 660M400 400L530 660',
          a,
          8,
        ),
        envelope: path(
          'M140 150H660V650H140ZM140 150L400 410 660 150M140 650L320 420M660 650L480 420',
          a,
          4,
        ),
        underline: path('M120 400Q300 450 680 390', ink, 4),
        ribbon: path('M100 350H700V450H100M280 350L250 600 400 530 550 600 520 350', a, 5),
      },
      familyyear: {
        spine: path('M375 70V730M400 70V730M425 70V730', a, 3),
        stitch:
          '<path d="M60 400Q250 270 400 400T740 400" fill="none" stroke="' +
          ink +
          '" stroke-width="5" stroke-dasharray="8 12"/>',
        album:
          path(
            'M80 160Q250 100 400 160Q550 100 720 160V650Q550 590 400 650Q250 590 80 650Z',
            a,
            5,
          ) + path('M400 160V650', ink, 3),
        year: ellipse(400, 400, 200, 200, a) + path('M270 400H530', ink, 3),
        sunset: path('M100 510H700M230 510A170 170 0 0 1 570 510', a, 8),
      },
    };
    // Celebration has six theme drawings; omit the generic oval to keep the library focused.
    const all = { ...common, ...special[d.part] };
    for (const [suffix, body] of Object.entries(all)) {
      const name = `p48-${d.part}-${suffix}`,
        file = `${name}.svg`;
      writeFileSync(
        join(dir, file),
        `<svg xmlns="http://www.w3.org/2000/svg" width="800" height="800" viewBox="0 0 800 800">${body}</svg>\n`,
      );
      manifest.push({ name, file, title: `${d.title.en} · ${suffix}`, width: 800, height: 800 });
    }
  }
  writeFileSync(
    join(dir, `premium48-phase${phase}-manifest.json`),
    JSON.stringify({ phase, assets: manifest }, null, 2) + '\n',
  );
  console.log(`Phase ${phase}: ${manifest.length} original SVGs`);
}
