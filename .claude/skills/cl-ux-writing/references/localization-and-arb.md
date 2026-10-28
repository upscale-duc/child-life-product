# Localisation and ARB standards

Documents the **existing** repository conventions (verified 2026-10-25). Don't invent a parallel
system.

## 1. Setup

| Item | Current |
|---|---|
| Catalogs | `apps/mobile/lib/l10n/app_vi.arb` (**template**), `app_en.arb`. 6,097 keys, full parity |
| Generator | `flutter gen-l10n` via `apps/mobile/l10n.yaml`: `template-arb-file: app_vi.arb`, `output-class: AppLocalizations`, `nullable-getter: false`, **`required-resource-attributes: true`** (every key needs an `@key` entry in vi) |
| Generated code | `app_localizations*.dart`. **Never edit by hand** |
| Access | `AppLocalizations.of(context)` (commonly `l10n`) |
| Locales | `supportedLocales = [vi, en]`; fallback **vi**; any other device language opens in **en** (D-078); in-app override in `lib/app/locale.dart` (`localeOverrideProvider`), stored per device; pushes and mail follow it |
| Widgets / Live Activities | `lib/l10n/glance_copy.dart` maps ARB getters to ids for Swift / Kotlin; placeholders are passed as literal `{x}` and filled natively, so **no ICU plurals** |
| Server copy | Push templates in `packages/contracts/src/notification-platform.ts` (Portal-editable, `docs/notifications/05-templates.md`); service mail in `firebase/functions/src/mail-templates.ts`. Both vi + en |
| Web (portal / landing) | Separate `messages.ts` catalogs with identical ids (CLAUDE.md). Out of scope here |

## 2. Adding or changing strings: the house workflow

New strings go in through a small **idempotent Python script** in `apps/mobile/tool/` (41 exist,
e.g. `tool/d1016_growth_head_strings.py`):

```python
# tool/<topic>_strings.py — header comment: decision id, date, what screens; "EN is an engineering draft for owner review."
s('growthHeadOptional', 'Vòng đầu · tùy chọn', 'Head circumference · optional',
  '28 head circumference label.' + NOTE)                        # key, vi, en, description
s('bpHead', 'Vòng đầu · {when}', 'Head · {when}', '13 baby profile tile.' + NOTE, when='String')  # placeholders
```

The script writes both files, keeps their order, and **refuses to reuse a key that already means
something else**. Then:

```bash
python3 tool/<topic>_strings.py && flutter gen-l10n
```

Edit an existing string the same way (a script, or a careful hand edit of both files). Never run a
formatter over the ARB files.

## 3. Keys

- **lowerCamelCase**, with a **feature prefix** (`as` assistant, `rh` rhythm, `pv2` paywall v2,
  `ks` keepsakes, `nt` notifications, `sd` solids, `sp` spending, `vx` vaccines, `ai` AI summary,
  `ax` adaptive …).
- **The name says what the string *is*:** `feedSheetTitle`, `memEmptyBody`, `ntLoadFailedTitle`.
  Suffixes in use: `Title`, `Body`, `Sub`, `Hint`, `Empty…`, `Failed`, `Toast`, `Semantics` / `a11y`.
- **Reuse shared action keys** (`actionSave`, `actionDone`, `actionRetry`, `actionContinue`,
  `actionNext`, `actionLater`, `actionSkip`, `undo`). Don't mint `xxDone`.
  - About 800 keys duplicate another key's vi value today. That is debt; don't add to it.
  - Exception: glance / widget keys stay separate (`glance*`), because native code reads them by
    id.
- **Don't repurpose a key for a different meaning.** Add a new key.
- **Deprecated keys:** about 258 keys appear unreferenced in `lib/` (e.g. `historySoon`,
  `statsEmpty`, `memoriesComingSoon`). Remove them only in a dedicated cleanup (check
  `glance_copy.dart` and native code first), never as a side effect.

## 4. Descriptions and placeholders

- Every key has an `@key.description`. Make it useful to a translator and a reviewer:
  - **where** it appears (screen id, component);
  - **what it is** (title, button, toast);
  - **who `{name}` is** (the baby, a member, the user; today 218 of 245 `{name}` descriptions
    don't say);
  - a decision id if one applies.
- **Placeholders** are declared with a type (today: `String` 1,181, `int` 613; only 10 of 1,794
  have a description or example):

  | Value | Type | Notes |
  |---|---|---|
  | Counts | `int`, so ICU plural can apply | — |
  | Formatted values (dates, times, amounts with units) | `String` | Formatted with the locale before passing |

- **Placeholder names say what they hold:**
  - `{count}` for plural counts;
  - `{baby}` for the child when another person is also named;
  - `{name}` only when unambiguous;
  - `{who}` for the actor;
  - `{date}`, `{time}`, `{ml}`, `{minutes}` for values.

  **Recommended:** prefer `{baby}` over `{name}` for the child in new strings. Don't rename
  existing placeholders in bulk.
- **Both languages contain the same placeholders.** Order may differ; meaning may not.

## 5. ICU

- **Plural:** en must use `{count, plural, =1{…} other{…}}` whenever a count meets a noun (237 en
  strings do). vi rarely needs it. Verified en gaps: `rhythmFeeds`, `rhythmBreast`, `pickSummary`,
  `albAppliesTo`, `dlSummary`, `albDeleteBody` (render "1 feeds", "1 items").
- **Select:** **none exist today.**
  - Role-aware or gendered variants are written as separate keys (e.g. `asLumiIntroBodyViewer`).
  - Introducing `select` (e.g. `{role, select, parent{…} other{…}}`) is acceptable for role
    wording, but it's a new pattern: use it in one place first and check `gen-l10n`.
- **Gender:** en is gender-neutral (they / their); vi avoids gendered pronouns. Keep it that way;
  gender only appears in pickers.

## 6. Dynamic text

- **No fragile concatenation.**
  - Never `'${l10n.a} ${count} ${l10n.b}'` or English glue in Dart.
  - One key holds the whole sentence with placeholders.
- **Accepted pattern: a per-language fragment** passed into a template, e.g. `logNow` "Ghi {what}"
  with `emptyFeedWhat` "cữ bú" / "a feed". Use it only when the fragment's grammar works in both
  languages (articles in en!).
- **Lists:** build them from items joined by a localised separator key, or a sentence key per
  count case. Avoid "A, B and C" assembled in Dart.
- **Dates and numbers:** format with the locale (`DateFormat(pattern, locale)`,
  `NumberFormat(…, locale)`, `ageLong`), then pass them as a `String` placeholder.

## 7. Every user-facing string is localised

This includes:

- semantics and accessibility labels;
- error messages (including those mapped from server errors);
- toasts;
- push and notification templates (server side);
- widget and Live Activity copy;
- email.

**Never hardcode** Vietnamese or English in widgets. The verified exceptions to review:

- "Tiếng Việt" / "English" self-names in keepsakes (acceptable: language names are written in
  their own language);
- generated vaccine data `features/vaccines/vaccine_schedule.g.dart` (bilingual in code);
- `features/baby/time_zones.dart` city labels;
- `care/history_screen.dart` date pattern `"d 'tháng' M"`.

## 8. Validation

```bash
cd apps/mobile && flutter gen-l10n      # fails on missing @descriptions / malformed ICU
cd apps/mobile && flutter analyze       # unused / missing getters
cd apps/mobile && flutter test --tags golden test/golden/<feature>_golden_test.dart   # renders vi + en
```

- **Parity check** (no dedicated test exists): compare the key sets of both ARB files (a 3-line
  `python3 -I` script) before committing.
- **Visual fit needs rendered evidence.** Inspect affected copy for overflow, truncation and
  plurals under `cl-design-review/references/visual-verification.md` → Visual evidence policy;
  reuse current renders rather than creating a new set for this checklist.

## 9. Bilingual review checklist

- [ ] Meaning preserved (intent, action, state, certainty).
- [ ] Each language sounds natural on its own.
- [ ] Glossary terms used; no new synonym.
- [ ] The CTA matches its destination.
- [ ] Fits the component in both languages (rendered).
- [ ] Placeholders present, correctly typed and described (who is `{name}`?).
- [ ] Plurals correct in en; counts read correctly in vi.
- [ ] Dates, times, numbers and units localised.
- [ ] Accessibility labels localised and understandable when spoken.
- [ ] `@description` explains context.
