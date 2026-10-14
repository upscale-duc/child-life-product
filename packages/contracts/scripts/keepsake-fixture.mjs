// Writes the seed catalog (D-068) as the Flutter tests' fixture:
// apps/mobile/test/helpers/keepsake_seed.json. Test data only; the app reads the catalog staff
// publish from the portal (D-068 #7). Also writes the one-colour Child Life lockup the app tints
// for card `brand` layers (D-068 #10): apps/mobile/assets/logo/lockup-h-tint.svg.
// test/keepsakes.test.ts fails when either drifts.
// Run after building contracts: node packages/contracts/scripts/keepsake-fixture.mjs
import { writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { keepsakeBrandSvg, keepsakeSeedV1 } from '../dist/index.js';

const root = join(dirname(fileURLToPath(import.meta.url)), '../../..');
writeFileSync(
  join(root, 'apps/mobile/test/helpers/keepsake_seed.json'),
  `${JSON.stringify(keepsakeSeedV1, null, 2)}\n`,
);
// Black: the app recolours it with a colour filter (srcIn), keeping the band's 55 %.
writeFileSync(
  join(root, 'apps/mobile/assets/logo/lockup-h-tint.svg'),
  `${keepsakeBrandSvg('#000000')}\n`,
);
