import {
  premium48FinalDesigns,
  premium48FinalPhase,
  resolveKeepsakeCopy,
  type KeepsakeTemplate,
} from '@child-life/contracts';
import { mkdirSync, writeFileSync, readFileSync, readdirSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { buildArt } from './keepsake-art.js';
const root = resolve(import.meta.dirname, '../..');
const selected = Number(process.argv[2] ?? 0);
const reuse = process.argv.includes('--reuse-art'),
  art = reuse ? [] : await buildArt();
function values(t: KeepsakeTemplate, locale: 'vi' | 'en', confirmed: boolean) {
  const d = premium48FinalDesigns.find((d) => t.id.endsWith(`_${d.n}`))!;
  return Object.fromEntries(
    t.personalization!.fields.map((f) => [
      f.key,
      f.key === 'babyName'
        ? d.baby
        : f.key === 'celebrationTheme'
          ? 'christmas'
          : f.key === 'occasionName'
            ? locale === 'vi'
              ? 'Giáng sinh'
              : 'Christmas'
            : f.type === 'confirmation'
              ? confirmed
                ? 'true'
                : 'false'
              : !confirmed
                ? ''
                : f.key === 'momentDate'
                  ? '2026-10-22'
                  : f.key === 'relativeName'
                    ? 'Rose'
                    : f.key === 'narratorName'
                      ? 'Alex'
                      : f.key === 'familyLabel'
                        ? 'Our family'
                        : f.key === 'placeName'
                          ? locale === 'vi'
                            ? 'khu vườn'
                            : 'the garden'
                          : '',
    ]),
  );
}
for (let phase = 7; phase <= 12; phase++) {
  if (selected && selected !== phase) continue;
  const ds = premium48FinalDesigns.filter((d) => Math.ceil(d.n / 2) === phase),
    parts = ds.map((d) => `p48-${d.part}-`),
    out = join(root, `artifacts/premium48-phase${phase}`);
  mkdirSync(out, { recursive: true });
  const selectedArt = reuse
    ? (
        JSON.parse(
          readFileSync(
            join(root, `design/keepsake-art/premium48-phase${phase}-manifest.json`),
            'utf8',
          ),
        ).assets as { name: string }[]
      ).map((a) => {
        const asset = readdirSync(out).find(
          (f) => f.startsWith(`art-${a.name}`.slice(0, 40) + '_') && f.endsWith('.webp'),
        );
        if (!asset) throw new Error('Cached art missing');
        return { name: a.name, asset, bytes: readFileSync(join(out, asset)) };
      })
    : art.filter((a) => parts.some((p) => a.name.startsWith(p)));
  for (const a of selectedArt) writeFileSync(join(out, a.asset), a.bytes);
  const assets = Object.fromEntries(selectedArt.map((a) => [a.name, a.asset])),
    music = Object.fromEntries(
      ds.map((d) => [d.part, `music_p48_${d.part}${d.n === 20 ? '_neutral' : ''}`]),
    );
  const templates = premium48FinalPhase(phase, assets, music),
    demos = Object.fromEntries(
      templates.map((t) => [
        t.id,
        Object.fromEntries(
          (['vi', 'en'] as const).map((locale) => [locale, values(t, locale, false)]),
        ),
      ]),
    );
  const cases = templates.flatMap((t) =>
    (['vi', 'en'] as const).flatMap((locale) =>
      [false, true].map((confirmed) => {
        const v = values(t, locale, confirmed);
        return {
          id: t.id,
          locale,
          values: v,
          expected: resolveKeepsakeCopy(t.personalization!, v, locale),
        };
      }),
    ),
  );
  const data = { templates, demos };
  writeFileSync(join(out, 'templates.json'), JSON.stringify(data, null, 2) + '\n');
  writeFileSync(
    join(root, `design/keepsake-templates/premium48-phase${phase}.json`),
    JSON.stringify(data, null, 2) + '\n',
  );
  writeFileSync(
    join(root, `packages/contracts/test/vectors/premium48-phase${phase}.json`),
    JSON.stringify({ templates, cases, demos }, null, 2) + '\n',
  );
  console.log(
    `Built phase ${phase}: ${templates.length} templates, ${selectedArt.length} assets, ${cases.length} parity cases`,
  );
}
