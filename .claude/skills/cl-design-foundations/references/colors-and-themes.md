# Colours and themes

Source: `packages/design-tokens/tokens.json` → `apps/mobile/lib/core/design/tokens.g.dart`
(`ClColors`, `ClCareColors`), exposed by `context.cl` (`core/design/cl_theme.dart`).

Contrast ratios below were computed from the token hex values (WCAG 2.x). AA requires 4.5 for
body text, and 3.0 for large text (≥ 18.66 px bold / 24 px regular) and for UI shapes.

## 1. Two palettes, one API

| | Light (`ClPalette.light`) | Night care (`ClPalette.nightCare`) |
|---|---|---|
| What it is | The brand look | A care mode for night feeds. It is **not** a generic dark theme. |
| When it is on | Default | The user picked "Tối"; or "Tự động" with a dark OS; or inside the 21:00–06:00 schedule; or while a sleep or feed timer runs (`nightCareTimerRunningProvider`, `core/appearance/`) |
| How code reads it | `cl.colors.*`, `cl.care.*`, `cl.shadows.*` | The same names; only the values change |
| Branching | — | `cl.isNightCare`, only for behaviour (no shimmer, no bounce, no haptic) or a documented exception |

- `ClTheme.lerp` fades between the two palettes.
- The status-bar icons come from `clStatusBarStyle(palette)`.
- **Never pick a colour with `isNightCare ? A : B`** when a semantic token already covers the
  role. The pair is already defined per palette.

## 2. Semantic roles

| Role | Tokens | Use for | Never |
|---|---|---|---|
| Page | `cloud` | Scaffold background (theme default) | Card fills |
| Surfaces | `surface`, `surface2` | Cards, groups, sheets (`surface`); grouped fields, secondary fills, the info notice (`surface2`) | — |
| Lines | `separator` (1.25:1), `controlBorder` (3.2:1 Light / 4.3:1 Night) | Separators: hairlines between rows. Control border: an outline that must be *seen* (`ClButtonStyle.outline`, inputs via `clInputStroke`) | Using `separator` as the only edge of an interactive control |
| Text | `ink`, `inkMuted` | Primary text and icons; secondary and meta text | `inkMuted` for the only copy of key information |
| Brand action | `mintDeep` + `onMintDeep` | Primary button fill, selected states, focus (`focusRing`) | — |
| Brand text | `mintText` | Links, "plain" buttons, emphasised words on `surface` / `mintSoft` | — |
| Brand tint | `mintSoft` | Tinted button (`ClButtonStyle.tinted`) and tinted tiles | — |
| Brand decor | `mint` | Rings, bars, glows, illustration, progress | **Any text on it, or as a text-button fill** |
| Warm | `sunshine`, `peach` (bright); `sunshineSoft`, `peachSoft` (soft); `onWarm` | Attention, memories and celebration, the "sun" chip | See the warm trap (§4) |
| Hero cards | `cardMint`, `cardSun`, `cardPeach`, `cardNight` + `onCard` | Illustration and hero cards | `onCard` on `cardNight` in Light (§4) |
| Navigation | `navBar`, `navIcon`, `navActive`, `onNavActive` | `ClNavBar` / `ClTabDock` only | Other surfaces |
| Failure | `error`, `errorSoft` | A save or load failed, an invalid field, a destructive button (`ClButtonStyle.destructive` = `errorSoft` + `error`) | Health danger |
| Danger | `danger`, `dangerSoft`, `onDanger` | Real-world danger only: first aid, call 115 (`first_aid/*`, `assistant` health card) | Ordinary errors and "overdue" |
| Live / positive | `live`, `onLive` | A running state (live timer, connected) | — |
| Pending | `pending` | Waiting or unsynced text and icons (`ClSyncStatus`) | — |
| Overlay | `scrim` | Behind sheets and dialogs (`ClSheetRoute`) | Photo overlays (see §6) |
| Brand mark | `logo*`, `appleButton*` | `ClLogo`; the Sign in with Apple button | Anything else |

## 3. Care-category colours (`cl.care.<bottle|breast|sleep|diaper|growth|pump>`)

Each category has three colours: `soft`, `ink` and `accent`. They code the category the same way
in logging, history, charts, tiles and glance widgets.

| Pair | Light | Night | Rule |
|---|---|---|---|
| `ink` on `soft` | 5.5–6.7 | 7.8–8.9 | ✅ Text and icons on a category tile |
| `ink` on `surface` | 6.2–7.7 | 9.1–10.0 | ✅ Category-coloured text on a card |
| `accent` on `surface` | 2.6–4.3 | 5.4–7.2 | ⚠️ Graphics only: chart bars, dots, rings, timer arcs |
| White on `accent` | 2.2–4.3 | 2.2–3.0 | ❌ Never put text on an accent fill |

Always pair the colour with the category's icon or label (`ClIcons.feed` / `sleep` / `diaper` …).
The colour identifies the category; the icon and text carry the meaning.

## 4. Known traps (verified)

| Trap | Numbers | Do instead |
|---|---|---|
| **`mint` is decorative** | White on `mint` 2.3 (Light); `ink` on `mint` 1.99 (Night) | Text-bearing fills use `mintDeep` + `onMintDeep` (4.85 / 8.0) or `mintSoft` + `mintText` |
| **`onWarm` on soft warm fills** | `onWarm` on `sunshineSoft` 10.7 Light → **1.10 Night**; on `peachSoft` 9.7 → **1.21** | On `sunshineSoft` / `peachSoft` use `colors.ink` (10.7–12.4 in both). `onWarm` only on the bright `sunshine` / `peach` (8.2 / 6.2 in both) |
| **`onCard` on `cardNight` in Light** | `cardNight` = `onCard` = #173D44 in Light → **1.00** | Text on `cardNight` uses `surface` (or the hero's own light ink); check both palettes |
| **Secondary button inside an info notice** | `ClButtonStyle.secondary` fill = `surface2` = info `MeNotice` fill | Put the action on a `surface` card, or use a warn / error tone |
| **`onDanger` on `danger`** | 4.14 Light, **3.03 Night**: large text only | Keep it to short, large labels with an icon (the "Gọi 115" call button); never body text on `danger`. `danger` on `dangerSoft` passes in Night (5.06) but only for large text in Light (3.58). Flagged as a token gap |
| **`live` + `onLive`, `danger` on `dangerSoft` (Light)** | 3.59 / 3.58 | Large or bold text only; keep body text in `ink` |
| **Raw `Colors.white` / `Colors.black` on surfaces** | 126 / 27 uses in features | They don't change in Night care. Use `surface` / `ink` / `scrim`. Raw values are allowed only on photos (§6) and inside the Premium palette (§7) |
| **`ClIcon` without a colour** | Falls back to `DefaultTextStyle` colour, else a hardcoded Light ink (`cl_icon.dart`) | Pass `color:` explicitly on any custom surface |

**Light-mode pairs are not automatically safe in Night care.** For any foreground/background pair
that isn't in the table in §5, render the Night care golden before trusting it.

## 5. Decision table: common situations

| Situation | Background | Foreground | Notes |
|---|---|---|---|
| Page | `cloud` (theme) | `ink` | — |
| Card or group on the page | `surface` + `shadows.card` | `ink` / `inkMuted` | D-096; `ClCardGroup` does this |
| Group inside a sheet | `surface2` (`ClCardGroup(color:)`) | `ink` | No shadow |
| Primary action | `mintDeep` | `onMintDeep` | One per screen or sheet (D-105) |
| Secondary action | `surface2` | `ink` | Not on a `surface2` parent |
| Quiet brand action | `mintSoft` | `mintText` | `ClButtonStyle.tinted` (empty-state action) |
| Link or text action | — | `mintText` | `ClButtonStyle.plain`, `ClSectionHeader` link |
| Info notice | `surface2` | `ink` title, `inkMuted` body | `MeNotice(tone: info)` |
| Attention / overdue / needs a look | `sunshineSoft` | `ink` | Warm, not alarming. Add an icon |
| Celebration / memory accent | `peachSoft` or `sunshine` | `ink` / `onWarm` respectively | Memories and milestones only |
| Save or load failed | `errorSoft` | `error` (lead), `ink` (body) | `ClErrorBanner`, `MeNotice(tone: error)` |
| Destructive button | `errorSoft` | `error` | `ClButtonStyle.destructive`; confirm in a sheet |
| Real danger (call 115) | `danger` | `onDanger` (large or bold) | First aid only |
| Waiting to sync | — | `pending` + icon + words | `ClSyncStatus` |
| Live or running | `live` / tint | `onLive` | Timers |
| Category tile or chip | `cl.care.X.soft` | `cl.care.X.ink` | With the category icon |
| Chart series | — | `cl.care.X.accent` | Never under text |
| Disabled | — | 40 % opacity (`ClMotion.disabledOpacity`, `ClPressable`) | Not a grey colour |
| Selected chip or segment | `mintDeep` or `surface` thumb | `onMintDeep` / `ink` | See `ClFilterChip`, `ClSegmented` |

## 6. Photos and media

On photos, the image is the background, so palette tokens don't apply. Current code
(`memories/memory_widgets.dart`, `memories/media_viewer.dart`) uses raw overlays:

- `Colors.black` at α 0.35–0.55 (badges, duration, play glyph);
- `Colors.black38` (dimmed tiles);
- `Colors.white70` (captions over the viewer);
- `LinearGradient` scrims for text at the edges.

- **Allowed:** raw black / white with alpha **on top of photos and video only**, plus a gradient
  scrim behind any text on a photo.
- **Gap:** there is no photo-overlay token. Reuse the existing alphas (0.35 badge, 0.55 strong) and
  don't add new ones. A semantic token is a candidate under the token protocol (SKILL.md).
- Picture tiles on a page lift with `ClTileShadow` (`shadows.tile`, D-096).

## 7. Sanctioned palettes outside the tokens

| Palette | File | Scope | Rules |
|---|---|---|---|
| **Premium v2** (`PremiumPalette`) | `features/premium/premium_style.dart` | Paywall, the Premium suggestion sheet, the inline Premium card, the family plan (`paywall_v2.dart`, `family_plan_v2.dart`) | Always dark and gold, in Light and Night care alike. Text uses `PremiumPalette.text` / `textMuted` / `textFaint`; the serif is `PremiumPalette.serif`. **Use it only on Premium surfaces**; never borrow gold for non-Premium UI. New Premium colours go into `PremiumPalette`, not inline. |
| **Lumi mascot** (`LumiColors`) | `features/assistant/lumi_button.dart` | The mascot art only | Brand art like the logo: the same in both palettes |
| Illustrations (`ClArt`, `ClLogo`) | `core/widgets/cl_art.dart` | Fixed-colour art | Decorative unless labelled |

Any other hardcoded `Color(0x…)` is debt. The largest concentrations are in `print_studio`,
`onboarding/widgets/journey_hero.dart` and `keepsakes`. Don't copy it.

## 8. Colour never carries meaning alone

Every status pairs colour with an **icon and words**: `ClSyncStatus` ("icon + words, never colour
alone") and `ClErrorBanner` (bold lead + sentence). A category also shows its icon. A chart
series also has a legend or label. A selected state also has a check or weight change
(`ClRadio`, `ClFilterChip`).

## Good / bad

```dart
// ✅ attention card that survives Night care
Container(color: cl.colors.sunshineSoft, child: Text(msg, style: cl.text.body.copyWith(color: cl.colors.ink)))
// ❌ unreadable in Night care (1.10:1)
Container(color: cl.colors.sunshineSoft, child: Text(msg, style: cl.text.body.copyWith(color: cl.colors.onWarm)))

// ✅ category tile
DecoratedBox(decoration: BoxDecoration(color: cl.care.sleep.soft), child: ClIcon(ClIcons.sleep, color: cl.care.sleep.ink))
// ❌ text on an accent fill (2.2–4.3:1)
Container(color: cl.care.sleep.accent, child: Text('Ngủ', style: TextStyle(color: Colors.white)))

// ❌ palette-blind
color: Colors.white   // on a card → use cl.colors.surface
```
