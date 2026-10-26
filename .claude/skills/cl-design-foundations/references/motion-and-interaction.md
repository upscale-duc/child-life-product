# Motion and interaction

Sources: `ClMotion` (`core/design/tokens.g.dart`), `core/design/motion.dart`,
`core/design/haptics.dart`, `core/design/page_transitions.dart`,
`core/widgets/cl_pressable.dart`, `cl_sheet.dart`, `cl_feedback.dart`.
Decisions: D-013 (platform transitions), D-048 (system press feedback and haptics).

Don't introduce new animation systems or packages. Compose from these.

## 1. Tokens (implemented)

| Token | Value | Use (from the token comments) |
|---|---|---|
| `ClMotion.instant` / `ClCurves.instant` | 100 ms, `Cubic(0.2,0,0,1)` | Press, switch, touch response |
| `ClMotion.quick` / `ClCurves.quick` | 200 ms | Chip show / hide, sub-tab change, small notices, toast in |
| `ClMotion.standard` / `ClCurves.standard` | 350 ms, spring 0.35 / 0.86 (Android stiffness 380) | Open a sheet, full-screen photo |
| `ClMotion.exit` / `ClCurves.exit` | 250 ms, `Cubic(0.4,0,1,1)` | Close a sheet or photo, hide a toast |
| `ClMotion.gentle` / `ClCurves.gentle` | 600 ms | Story cards, milestone moments, welcome |
| `staggerDelay(i)` | 30 ms apart, max 6 | List entrance |
| `ClMotion.disabledOpacity` | 0.4 | Disabled controls |
| `ClMotion.scrimOpacity` | 0.32 | Sheet scrim |
| `standardSpring()` / `SpringCurve` | — | Implicit animations on the standard spring |

Retired by D-048, so don't use: `pressScale` (0.96) and `pressScalePhoto` (0.98). Press
feedback is opacity, not scale.

## 2. Reduce Motion (implemented)

- `context.reduceMotion` reads `MediaQuery.disableAnimations`.
- **`context.motion(ClMotion.quick)`** returns `Duration.zero` under Reduce Motion. Always wrap
  token durations with it.
- **Screens fade instead of sliding** (`ClPageTransitionsBuilder`).
- **Sheets:** a 150 ms linear fade with no slide (`ClSheetRoute`).
- **Toasts** fade only.
- **`ClSkeleton`** is static.

## 3. Night care motion (implemented)

- Sheets have no bounce: 250 ms ease-out instead of the spring.
- `ClSkeleton` has no shimmer.
- The toast has no glow (`surface2` fill instead of `ink`).
- Haptics: success only (§5).

Night care means a parent half-asleep in a dark room. Prefer stillness.

## 4. Transitions

| Movement | Implementation |
|---|---|
| Push a screen | Platform default: iOS Cupertino push with swipe-back; Android predictive back (D-013). Routes return `MaterialPage` (`app/router.dart` `_route`); `modal: true` for fullscreen dialogs |
| Shell, splash, welcome | Crossfade (`_fade` in `router.dart`) |
| Sheet | `showClSheet` → `ClSheetRoute`: standard spring in; drag past 30 % or flick > 700 to close; springs back otherwise |
| Tab change | `ClNavBar` pill, label and icon move together on the standard spring (D-048) |
| Dock | Slides away while scrolling down, returns after 8 px up (D-048) |
| Toast | Slides up 24 px in `quick`, hides after 4 s in `exit` |

Don't build custom `PageRouteBuilder` slides. Imperative `Navigator.push` in some features is
debt.

## 5. Haptics (`ClHaptics`, implemented)

Owner request (2026-10-11): haptics only where they mean something.

| Call | When | Night care |
|---|---|---|
| `ClHaptics.selection(context)` | Switching the main tab (`ClNavBar`) | Silent |
| `ClHaptics.success()` | Exactly where a success toast is shown after a save | Plays |

- **Silent by design:** taps, sheets (open and close) and confirmations.
- **Stale doc comments:** the comments in `cl_pressable.dart` and `cl_sheet.dart` still describe
  press, open and drag haptics. The code no longer plays them, and `haptics.dart` is the
  authority.
- **Raw `HapticFeedback.*` calls in features** (5: assistant, library, first aid, solids) predate
  or bypass this. Don't add more.

## 6. Press feedback (`ClPressable`, implemented)

- **Dim on touch-down, fade back on release,** with CupertinoButton timings.
- **Opacity by kind of control:**
  - `pressedOpacity` 0.4 for buttons;
  - **`ClPressable.surfaceOpacity` (0.7)** for large surfaces (rows, tiles, cards);
  - `1.0` for controls whose selection change *is* the feedback (tabs, segments).
- **Disabled** shows at 40 % opacity and ignores taps.
- **Hit area** is at least `tapMin`. A long press is optional (`onLongPress`).
- **No ripple:** the theme sets `NoSplash` and a transparent highlight. Don't add `InkWell`
  ripples.

Wrap custom tappables in `ClPressable`, never in a bare `GestureDetector`.

## 7. Loading feedback

| Situation | Use |
|---|---|
| Content loading | `ClSkeleton` blocks shaped like the content. Shimmer every 1.2 s; static in Night care and under Reduce Motion |
| A button's own action | `ClButton(loading: true)`: spinner replaces the icon, the label stays, taps are ignored, the button is not dimmed, and it is announced as a live region |
| A server call from a row, sheet or icon (no button to spin) | `withClProgress(context, () => …)`. Full-screen blocker that appears only after 150 ms |
| After a save | `showClToast` / `ClToaster` (+ undo); `ClHaptics.success()` at the same spot |
| Long progress (upload) | `ClProgress` (4 px bar), `UploadPill` |

**Off-system:** a bare `CircularProgressIndicator` (31 in features), raw `LinearProgressIndicator`
(13), `SnackBar` (1). Don't add more. How each loading, empty and error state should be laid out
belongs to the `cl-screen-patterns` skill (`screen-states.md`).

## Good / bad

```dart
// ✅
AnimatedOpacity(duration: context.motion(ClMotion.quick), curve: ClCurves.quick, …)
// ❌ raw duration, ignores Reduce Motion
AnimatedOpacity(duration: const Duration(milliseconds: 300), …)

// ✅ save from a sheet
await withClProgress(context, () => repo.save(x));
toaster.show(message: l10n.savedToast(what), actionLabel: l10n.undo, onAction: undo); // toaster = ClToaster.of(context), captured before the await
ClHaptics.success();
// ❌ extra haptic on a tap
onTap: () { HapticFeedback.lightImpact(); … }
```
