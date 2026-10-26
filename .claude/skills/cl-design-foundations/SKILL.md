---
name: cl-design-foundations
description: Child Life's visual foundations for the Flutter app — choosing colour tokens and safe foreground/background pairs, typography roles (cl.text.*), ClSpace spacing, ClRadius, surfaces and elevation, motion and haptics, Light vs Night care, and accessibility (44 pt, 200 % text, contrast, semantics). Use when building or changing any visual in apps/mobile (colours, text styles, padding, radius, shadows, animations, Night care bugs, contrast or readability fixes), when tempted to write a raw Color/fontSize/radius/EdgeInsets literal, and when a design need seems to require a new token. Routed from the senior-ui-ux master skill; works on its own for foundation-only fixes.
---

# Child Life design foundations

The Flutter code is the source of truth (D-104). Tokens live in
`packages/design-tokens/tokens.json`, are generated into `apps/mobile/lib/core/design/tokens.g.dart`
(never edit that file by hand), and are read through `context.cl` (`core/design/cl_theme.dart`):
`cl.colors`, `cl.care`, `cl.shadows`, `cl.text`, `cl.isNightCare`, plus `ClSpace`, `ClRadius` and
`ClMotion`.

**Design for comprehension, not explanation (D-110).** Hierarchy, layout, typography, colour
roles and familiar interaction patterns carry the meaning. Don't compensate for an unclear design
with more explanatory text, extra icons, badges or containers; fix the hierarchy instead. Every
visible element must earn its place (`senior-ui-ux` → `references/content-simplification.md`),
while 44 pt targets, readable type, contrast and breathing room stay.
A structural redesign (D-112) uses the same tokens: new compositions never justify new raw
values; a real gap goes through the token protocol.

These rules guide judgement; they are not absolutes. When a rule and the rendered result
disagree, trust readability and accessibility, then record why.

## Always

1. **Use semantic tokens. Never write new raw values:** no `Color(0x…)`, `Colors.*`,
   `fontSize:`, `FontWeight.w700`, `BorderRadius.circular(<n>)`, or literal
   `EdgeInsets` / `SizedBox` numbers. Existing literals are debt: fix them when you touch them; don't copy them.
2. **Choose the colour pair by role, and check it holds in Night care.**
   - `mint` is decorative: never put text on it. Text-bearing fills use `mintDeep` +
     `onMintDeep`, or `mintSoft` + `mintText`.
   - On `sunshineSoft` / `peachSoft`, use `colors.ink`. `onWarm` is only for the bright
     `sunshine` / `peach` (`onWarm` on a soft fill is 1.1:1 in Night care).
   - `error` means something failed; `danger` is for real-world danger only (first aid).
   - Care colours: `cl.care.X.ink` on `.soft` for text and icons; `.accent` for graphics only.
3. **Never let colour carry meaning alone.** Pair it with an icon and words.
4. **Typography comes from the role map** (`references/typography.md`).
   - One `largeTitle` per screen; `headline` for sections; `body` for row titles; `label` /
     `caption` in `inkMuted` for secondary text.
   - Anything numeric that changes goes through `ClTabularText`.
   - Never shrink text to gain density.
5. **Spacing:**
   - gutter `ClSpace.s4`;
   - `s6` between sections;
   - `s3` from a heading to its content and between stacked cards;
   - `s4` inside cards;
   - tappables at least 44 pt (`ClPressable` does this).
6. **Surfaces:**
   - page `cloud`;
   - page-level card `surface` + `shadows.card` (D-096, `ClCardGroup`);
   - flat `surface2` inside cards and sheets;
   - no shadowed card inside a shadowed card.
   - In Night care, card shadows are empty, so fills must carry the hierarchy.
7. **Radius from `ClRadius`:**
   - `card` 24 for page cards;
   - `control` 12 for inputs and icon tiles;
   - `pill` for buttons and chips;
   - `tile` 28, `sheet` 32, `hero` 36 for their roles.
   - Variation between card purposes comes from content and accent, not new values (D-107).
8. **Motion:**
   - token durations wrapped in `context.motion(...)` (Reduce Motion becomes zero);
   - platform screen transitions (D-013);
   - `ClPressable` opacity press (D-048);
   - haptics only via `ClHaptics.selection` (tab switch) and `ClHaptics.success` (with a success
     toast).
9. **Verify on images:** Light and Night care × vi and en goldens, plus one 200 % text render for
   new or changed layouts.

## Sanctioned exceptions (don't spread them)

- **Photos and video:**
  - raw black / white overlays at the existing alphas;
  - a gradient scrim behind any text;
  - `ClTileShadow` for picture tiles.
- **Premium surfaces:** `PremiumPalette` and its serif (`features/premium/premium_style.dart`), dark
  and gold in both palettes. Only on Premium UI. New Premium colours go into `PremiumPalette`.
- **Brand art:** `LumiColors` (the mascot), `ClArt`, `ClLogo`.

## Token evolution protocol (D-106)

When no token fits a legitimate need:

1. **Check existing tokens** (`tokens.json`, `tokens.g.dart`) and the role tables in
   `references/`.
2. **Check usage across the app.** `grep -rn` the literal or pattern in `apps/mobile/lib` and
   count the uses and features.
3. **Decide whether the need is genuinely reusable:** a semantic role used in 2+ features, not
   one screen's taste.
4. **Prefer an existing semantic token** if the rendered result is as good or better.
5. **Otherwise, propose** a semantic name, its value(s) in **both palettes**, the evidence (counts,
   screens), contrast where relevant, and which call sites would migrate.
6. **Ask the owner and wait for approval.** Don't edit tokens before that. New tokens are **L3**
   (`senior-ui-ux` §3, D-109); using existing tokens differently is L1 / L2 and needs no approval.
7. **After approval:**
   - edit `tokens.json`;
   - run `pnpm --filter @child-life/design-tokens run build` (Dart + `dist/tokens.css`), and
     `run check` to confirm the outputs are current;
   - add a D-xxx row to `docs/product/business-map.md`.
8. **Verify the affected screens on goldens** (Light, Night, vi, en) and update the foundations
   golden (`test/golden/showcase_golden_test.dart`).

Candidates already documented, **not implemented**:

- a dense row-title style (15/20 · 600);
- a 6 px gap;
- a medium card radius (~16–20);
- a photo-overlay token;
- a safe `danger` foreground pair.

Never write them as if they existed.

## References (load the one you need)

| File | Load when |
|---|---|
| `references/colors-and-themes.md` | Picking colours, Night care issues, status / category / photo / Premium colours, the decision table, contrast numbers |
| `references/typography.md` | Choosing text styles, hierarchy, `ClTabularText`, type-scale gaps |
| `references/spacing-and-layout.md` | Padding, gaps, gutters, touch spacing, responsive and Dynamic Type layout |
| `references/elevation-and-surfaces.md` | Surface levels, shadows, nested cards, radius, D-107 variation |
| `references/motion-and-interaction.md` | Animations, transitions, Reduce Motion, haptics, press and loading feedback |
| `references/accessibility.md` | Targets, 200 % text, contrast, semantics, numbers for screen readers, Night care readability |

**Related skills.**

- The master workflow is `senior-ui-ux`.
- Component choice and the future `ClCard` family belong to `cl-components`.
- The layout of loading, empty and error states belongs to `cl-screen-patterns`.

## Quick self-check before finishing

- [ ] No new raw colour, size, radius, weight or spacing literal.
- [ ] Every foreground/background pair is from the safe list, or checked in Night care.
- [ ] Hierarchy uses scale styles; numbers that change are tabular.
- [ ] One elevated level per region; Night care still separates surfaces.
- [ ] 44 pt targets; 200 % text renders; status not by colour alone.
- [ ] Motion uses tokens and `context.motion`; no new haptics.
- [ ] Any new token went through the protocol with approval.
