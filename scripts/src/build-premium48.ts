/** Generate the four catalog templates and local art for review. No Firebase writes. */
import {
  premium48Phase1,
  premium48Phase2,
  premium48Phase3,
  premium48Phase4,
  premium48Phase5,
  resolveKeepsakeCopy,
} from '@child-life/contracts';
import { mkdirSync, writeFileSync } from 'node:fs';
import { resolve, join } from 'node:path';
import { buildArt } from './keepsake-art.js';
const phase = process.argv.includes('--phase5')
  ? 5
  : process.argv.includes('--phase4')
    ? 4
    : process.argv.includes('--phase3')
      ? 3
      : process.argv.includes('--phase2')
        ? 2
        : 1;
const out = resolve(import.meta.dirname, `../../artifacts/premium48-phase${phase}`);
mkdirSync(out, { recursive: true });
const art = (await buildArt()).filter((a) =>
  phase === 5
    ? /^p48-(wardrobe-|smile-|grain$)/.test(a.name)
    : phase === 4
      ? /^p48-(chapter-|compare-|grain$)/.test(a.name)
      : phase === 3
        ? /^p48-(observe-|letter-|grain$)/.test(a.name)
        : phase === 2
          ? /^p48-(home-|scrap-|grain$)/.test(a.name)
          : /^p48-(arrival-|embrace-|grain$)/.test(a.name),
);
for (const a of art) writeFileSync(join(out, a.asset), a.bytes);
const assets = Object.fromEntries(art.map((a) => [a.name, a.asset]));
const templates =
  phase === 5
    ? premium48Phase5(assets, { wardrobe: 'music_p48_wardrobe', smile: 'music_p48_smile' })
    : phase === 4
      ? premium48Phase4(assets, { chapter: 'music_p48_chapter', compare: 'music_p48_compare' })
      : phase === 3
        ? premium48Phase3(assets, { observe: 'music_p48_observe', letter: 'music_p48_letter' })
        : phase === 2
          ? premium48Phase2(assets, { home: 'music_p48_home', month: 'music_p48_month' })
          : premium48Phase1(assets, { arrival: 'music_p48_arrival', embrace: 'music_p48_embrace' });
writeFileSync(
  resolve(import.meta.dirname, `../../design/keepsake-templates/premium48-phase${phase}.json`),
  JSON.stringify({ templates }, null, 2) + '\n',
);
writeFileSync(join(out, 'templates.json'), JSON.stringify({ templates }, null, 2) + '\n');
const cases = [];
for (const t of templates)
  for (const locale of ['vi', 'en'] as const)
    for (const first of [false, true]) {
      const values = Object.fromEntries(
        t.personalization!.fields.map((f) => [
          f.key,
          phase === 5 && f.key === 'itemName'
            ? first
              ? locale === 'vi'
                ? 'áo cotton'
                : 'cotton outfit'
              : ''
            : phase === 5 && f.key === 'storedDate'
              ? first
                ? '2026-10-20'
                : ''
              : phase === 4 && f.key === 'monthNumber'
                ? first
                  ? '12'
                  : '01'
                : phase === 4 && f.key === 'thenDate'
                  ? first
                    ? '2026-07-01'
                    : ''
                  : phase === 4 && f.key === 'nowDate'
                    ? first
                      ? '2026-10-01'
                      : ''
                    : phase === 4 && f.key === 'discovery'
                      ? first
                        ? locale === 'vi'
                          ? 'bàn tay bé xíu'
                          : 'tiny hands'
                        : ''
                      : phase === 4 && f.key === 'memoryLine'
                        ? first
                          ? locale === 'vi'
                            ? 'một buổi chiều bên nhau'
                            : 'an afternoon together'
                          : ''
                        : f.key === 'babyName'
                          ? phase === 5
                            ? t.id.endsWith('_10')
                              ? 'Lily'
                              : 'Noah'
                            : 'Bảo An'
                          : f.key === 'birthDate'
                            ? '2026-09-17'
                            : f.key === 'birthTime'
                              ? '09:35'
                              : f.key === 'placeName'
                                ? 'Đà Nẵng'
                                : f.key === 'momentDate'
                                  ? '2026-09-18'
                                  : f.key === 'narratorName'
                                    ? 'Mẹ Linh'
                                    : f.suggestion
                                      ? first
                                        ? f.suggestion[locale]
                                        : ''
                                      : f.type === 'confirmation'
                                        ? first
                                          ? 'true'
                                          : 'false'
                                        : '',
        ]),
      );
      cases.push({
        id: t.id,
        locale,
        values,
        expected: resolveKeepsakeCopy(t.personalization!, values, locale),
      });
    }
writeFileSync(
  resolve(
    import.meta.dirname,
    `../../packages/contracts/test/vectors/premium48${phase >= 2 ? `-phase${phase}` : ''}.json`,
  ),
  JSON.stringify({ templates, cases }, null, 2) + '\n',
);
console.log(
  `Built ${templates.length} templates, ${art.length} original art assets, ${cases.length} cross-language fixtures.`,
);
