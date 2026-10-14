# Keepsake art library (Remember 2.0)

Original SVG artwork for Milestone Magic cards and Memory Story videos (owner, 2026-10-14: a
consistent, original library shared by cards and videos; start with 15–20 essentials, grow toward
40; no unlicensed third-party illustrations). `manifest.json` lists each asset, where it is meant to
be used and the licence (owned by Child Life).

- **Source of truth:** the `.svg` files here. Flat, rounded, pastel, the fixed palette in the
  manifest. New assets follow the same palette and style; an illustrator may redraw any of them as
  long as the name and canvas stay the same.
- **Cards** draw pictures as WebP: `pnpm --filter child-life-scripts exec tsx src/seed-keepsakes.ts
  --project child-life-dev --art` rasterises each SVG with sharp (transparent WebP, ≤ 2160 px wide)
  and uploads it as a catalog asset `art-{name}_{hash}.webp`; staff then use it in layers from the
  portal (Tệp). On prod, staff upload the same files through the portal.
- **Videos** use the same WebP assets through the template's `assets`, or the SVG directly in a
  composition (`apps/renderer`).
- **Status:** v1, drawn by engineering. Production-usable as simple flat art; the teddy face and the
  bunting are the first candidates for an illustrator pass.
