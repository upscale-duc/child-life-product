# Forms and multi-step flows

Component choice: `cl-components` → `forms-and-feedback.md`. Copy: `cl-ux-writing`. **Don't change
business validation rules** (ranges, required fields, permissions) from here.

## 1. Reference implementations (rendered)

| Flow | Golden | Why it's the model |
|---|---|---|
| Quick log chooser | `s4/19a_quick_log` | Six large one-handed tiles in care colours; one tap → the right sheet |
| Bottle log | `s4/22_bottle` | Type switch, a big pre-filled amount ("đã điền theo lần trước"), presets (60 / 90 / 120 / 150), the last value and an age suggestion as context, milk type chips, time defaulting to "Bây giờ · 15:05", one primary "Lưu cữ bú" |
| Sleep | `s5/25a_sleep_chooser`, `25_sleep_timer`, `26_manual_sleep`, `27_overlap` | Timer vs manual entry; an overlap warning |
| Growth | `s4/28_growth` | Optional fields (head circumference "tuỳ chọn") |
| Onboarding | `s2/01_welcome` … `13_appearance` | Progress bar, back, one question per screen ("Theo dõi gì?"), reassurance ("Đổi lại lúc nào cũng được"), count in the CTA ("Xong · 4 mục") |
| Memory Story photos | `mm/mm06_photos` | Progress per slot, minimum stated, count + primary pinned |

## 2. Form principles

- **Ask only what the task needs.** Everything else is optional, visually secondary, or later.
- **Default safely:**
  - time = now;
  - the amount = the last value;
  - the type = the last used.

  Show where a default came from ("theo lần trước"). Never default anything with a safety or
  medical consequence.
- **Put the most-changed field first and biggest** (the amount in a bottle log); rare fields last.
- **One dominant primary at the bottom,** in the thumb zone and pinned (`CareSheetFrame`). Its
  label names the result ("Lưu cữ bú").
- **Validate near the field, on submit or on blur.** Keep everything entered after a recoverable
  error.
- **Save:**
  - optimistic local save → toast "Đã ghi · …" with **undo** (`commitRecord`,
    `features/care/care_sheets.dart`);
  - prefer undo over a confirm step for reversible logs;
  - confirm only destructive or irreversible actions.
- **Cancel with unsaved changes** asks once ("Huỷ và không lưu?", `cancelConfirmTitle`); otherwise
  close silently.
- **Edit uses the same sheet** as create, pre-filled, with delete reachable but not dominant.
- **Overlaps and conflicts** (two sleeps overlapping) are explained in place with a fix
  (`s5/27_overlap`).

## 3. Quick vs full entry

| Quick log (the dock "+", tiles) | Full form |
|---|---|
| Few fields, smart defaults, one tap to save | All fields, optional ones grouped |
| Opens as a sheet over the current screen | A sheet or a pushed page if long (growth, vaccines) |
| Undo via toast | Edit later from history |
| One-handed: big targets, bottom placement | Keyboard-aware; the primary stays visible |

## 4. Multi-step flows

| Concern | Pattern |
|---|---|
| Progress | `ClTopBar(progress:)` / `ClProgress` (onboarding) or a domain count ("6/8 cảnh") |
| One question per step | A title that asks it ("Theo dõi gì?"), a subtitle that reassures or explains *once* |
| Navigation | Back always available (on the first setup screen Back signs out, `setup_screens.dart:108`; say so); skip only for optional steps (the setup screens have none today); the primary advances and is disabled only with a visible reason (0 trackers picked) |
| Choices in one step | **One selection style per question.** Rendered `s2/12_trackers` mixes check tiles and radio-looking rows for the same multi-select. Use one style, or make the visual difference mean something |
| Draft persistence | Keep entered data when the app is backgrounded. **Current:** Memory Story keeps drafts (`ksVideoDeleteDraftTitle`); the onboarding setup draft is **in-memory only** (`setupDraftProvider`, `onboarding/setup_draft.dart`), so it's lost if the app is killed. Persisting it is a product change; propose, don't assume |
| Interruption recovery | Resume at the last step with the data intact; jobs that run on the server (video render) continue and notify (`mm08_rendering`) |
| Final step | Summarise what will happen, then one primary; afterwards show the result, not a dead end |
| Length | Prefer fewer steps; split only when a step would need scrolling to understand |

## 5. Night care forms

At night logging must be fastest:

- the defaults matter most;
- no bounce or celebration;
- big targets;
- the time default must respect the baby's time zone.

Check the `*_nightCare_*` goldens of every sheet changed.
