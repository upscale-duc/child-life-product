# Forms and feedback

Use the existing components and patterns below, and don't introduce a new feedback system. How
whole screens compose their loading, empty and error states belongs to
the `cl-screen-patterns` skill; this file covers the components.

## 1. Data entry

| Input | Component / pattern | Notes |
|---|---|---|
| Text | `ClTextField` | Caption label above the value. Inside `ClCardGroup` the group draws one stroke and each field shows only its focus ring (`ClInputGroup`); `standalone: true` gives the field its own card. Pass `textInputAction`, `autofillHints` and `keyboardType` |
| Several fields | `ClCardGroup(children: [ClTextField(…), ClTextField(…)])` | One group per topic; `FieldLabel` (care) or `MeSection` above groups |
| Invite code | `ClCodeInput` | 6 digits (P-020) |
| Time ("when it happened") | `ClTimeRow` → `showClSheet` with a `CupertinoDatePicker` | Follow `pickCareTime` (`features/care/care_sheets.dart`): a `CupertinoTheme` with `brightness` from `cl.isNightCare`, `title2` digits in `ink`, `use24hFormat`, sensible min / max |
| Duration | `pickDuration` (care) | Same sheet pattern |
| Date | Copy the `pickCareTime` sheet pattern | 17 hand-rolled picker sheets exist; reuse the closest one in your feature rather than adding another variant |
| Amount + unit | Care's `AmountInput` (`care_sheets.dart`) | `ClAmountField` is showcase-only |
| A whole form in a sheet | `CareSheetFrame(title:, titleColor:, children:, primary:)` | The primary is pinned; fields scroll |
| Keyboard | `ClKeyboardDismiss` wraps the app (a tap outside closes the keyboard); `dismissKeyboard()` on submit | — |

**Raw `TextField`** appears 23 times in 19 files. Don't add more; use `ClTextField`.

## 2. Selection

See the "Choosing" tree in `component-selection.md`:

- `ClSegmented` (2–3);
- `ClFilterChip`;
- `ClOptionRow` + `ClRadio`;
- `ClChoiceTile` / `ClSelectTile`;
- `ClToggle` / `ClSettingRow`;
- `ClRelationChip`, `ClDayPill`.

`ClSegmented` asks the caller to persist the last choice.

## 3. Validation

- **Verified gap:** `ClTextField` has **no error parameter**. Today's pattern is a local error line
  under the field: `_ErrorText` in `care_sheets.dart`, `label` in `colors.error`, wrapped in
  `Semantics(liveRegion: true)`.
- **Validate on submit,** or on blur for formats. Don't flag errors while the user is still
  typing.
- **The message says what to do** ("Nhập số từ 1 đến 500"), not just "Không hợp lệ".
- **Keep the primary enabled** where possible and explain on tap. If you disable it
  (`onPressed: null`, 40 % opacity), say why near the field.
- **Never use colour alone:** the error text is always present, not just a red stroke.

A shared field-error affordance is a component candidate (`component-evolution.md`).

## 4. Loading, processing, success, error: which is which

| Situation | Component | Behaviour |
|---|---|---|
| **Loading a screen or section** (content arriving) | `ClSkeleton` blocks shaped like the content | No spinner in the middle of the screen. Static in Night care and under Reduce Motion |
| **Processing a button's own action** | `ClButton(loading: true)` | The label stays, a spinner replaces the icon, taps are ignored, the button is not dimmed, and it is announced |
| **A blocking call started from a row, sheet or icon** (no button to spin) | `withClProgress(context, () => work())` | A full-screen blocker that appears only after 150 ms, so the app never looks frozen and nothing can be double-tapped |
| **A background task** (upload, sync, export) | `ClSyncStatus`, `UploadPill`, `ClProgress`; a toast when it finishes | The user can keep working. Capture `ClToaster.of(context)` before the `await` so a late result can still show |
| **Success** | `showClToast(message:)` + `ClHaptics.success()` at the same spot | The toast confirms what was saved ("Đã ghi · …"); undo when reversible |
| **A recoverable error from an action** | `showClToast(message:, error: true)`; offer a retry where it makes sense | Transient |
| **A recoverable error on the page** (load failed, offline) | `MeNotice(tone: MeTone.error / warn)` with what happened + what to do, and a retry action | Persistent until resolved. `ClErrorBanner` is the intended core but is showcase-only |
| **Confirming an irreversible action** | A confirm sheet (§5) | Before the action, not after |

**Off-system:** `CircularProgressIndicator` (31), `LinearProgressIndicator` (13), `SnackBar` (1),
`AlertDialog` (6), `showModalBottomSheet` (9). Don't add more.

## 5. Destructive confirmation and undo

**Prefer undo over confirm** when the action can be reversed: delete, then
`showClToast(actionLabel: l10n.undo, onAction: restore)`. Confirm only when it can't be undone
(deleting a baby, removing a member, permanent media deletion), or when it affects other people.

There is **no shared confirm component**. Five feature versions exist: `rhConfirm` (rhythm,
reused by assistant and AI consent), `confirmRemoveRecord` (milestones), `confirmDeleteMedia` (memories),
`showDeleteCategorySheet` (spending), `showDeleteBabySheet` (me). The canonical shape, as in
`rhConfirm` (`features/rhythm/rhythm_widgets.dart`):

```dart
final ok = await showClSheet<bool>(context: context, builder: (sheet) => Column(
  mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    ClSheetHeader(title: title),                      // the question, e.g. "Xoá 3 mục?" (delTitle)
    Text(body, style: cl.text.body.copyWith(color: cl.colors.inkMuted)), // the consequence, one sentence
    const SizedBox(height: ClSpace.s4),
    ClButton(label: confirm, expand: true, style: ClButtonStyle.destructive, onPressed: () => Navigator.of(sheet).pop(true)),
    const SizedBox(height: ClSpace.s2),
    ClButton(label: cancel, expand: true, style: ClButtonStyle.secondary, onPressed: () => Navigator.of(sheet).pop(false)),
    const SizedBox(height: ClSpace.s4),
  ])) ?? false;
```

Rules for confirm sheets:

- **Name the object and the consequence** ("Khôi phục được trong 30 ngày…", as
  `confirmDeleteMedia` shows).
- **The confirm verb repeats the action** ("Xoá", not "Đồng ý").
- **The cancel is `secondary`.**
- **Dismissing the sheet = cancel.**

Until a shared helper exists, reuse `rhConfirm` (it is generic) rather than writing a sixth
version. Promoting it to core is candidate #1 in `component-evolution.md`.

## 6. Progress

| Kind | Use |
|---|---|
| Steps in a flow | `ClTopBar(progress:)` / `ClProgress(value:)`, `ClPageDots` |
| An upload or background job | `UploadPill`, `ClSyncStatus` (icon + words) |
| A quota or usage | `StorageBar` (`features/me/me_widgets.dart`), `VideoQuotaCard` (Premium) |
| Time since the last event | A soft progress bar inside an insight card (pattern in `senior-ui-ux` §5.4) |
