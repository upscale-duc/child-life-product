# Content and localisation review

**`cl-ux-writing` is the source of truth.** This file defines how to *check* copy on a reviewed
screen.

## 1. Procedure

1. **List the ARB keys the screen uses:** `grep -noE "l10n\.[a-zA-Z0-9]+" <screen file>`. Include
   called helpers.
2. **For each key, read vi + en + `@description`** in `apps/mobile/lib/l10n/app_{vi,en}.arb`.
3. **Read the rendered vi and en goldens side by side.** Copy problems often appear only when
   rendered (wrapping, truncation, plurals).
4. **Check against:**
   - the glossary (terms + both statuses);
   - the voice and tone for the context;
   - the copy patterns;
   - the numbers file;
   - the AI copy file.

## 2. Checklist

| Check | Evidence |
|---|---|
| vi / en **meaning parity:** intent, action, state, certainty, placeholders | ARB (C) + render (R) |
| Natural phrasing in **each** language | ARB + render |
| **Terminology:** glossary terms; the same concept named the same across screens (e.g. "Nhắc việc" vs "Nhắc nhở" between Today paths) | R across screens |
| **CTAs** name their result and match the destination | R + C (route) |
| **Errors:** what happened → what to do; no raw codes | C |
| **Numbers, dates, times, units** per locale; units attached; no wrapping between value and unit | R |
| **Plurals** in en (e.g. `rhythmFeeds` "1 feeds", rendered in `s6/20_history_nightCare_en`) | R / C |
| **Text expansion:** neither language truncates essential information | R in both locales |
| **Long names:** greeting, chips, "{who} ghi" | Usually **not evaluated** (no fixtures) |
| **AI uncertainty:** basis, period, "khoảng" / "around" | R + C |
| **Premium wording:** value, what Free keeps, no pressure | R |
| **Privacy and consent wording:** complete and visible; changes need the owner | R + C |

## 3. Rules the reviewer must not break

- **Verified business meaning.** A proposed rewrite of a status, permission, error or explanation
  must match what the code does. If you can't confirm it, label the proposal
  **`Needs behavior verification`** and keep the current wording in the recommendation.
- **Technical terms are allowed when they're more accurate** (sync, backup, offline, permissions).
  Don't recommend vaguer friendly words that change the meaning.
- **Terminology statuses:**
  - Respect **implementation status** (Implemented / Approved · Planned / Proposed / Deprecated /
    Verify) and **terminology status** (Verified / Recommended / Owner decision).
  - Absence from ARB or Flutter doesn't mean unapproved: check `business-map.md`.
  - Ambiguous items (e.g. Plus / Pro) → "requires roadmap verification", not a verdict.
- **Canonical term changes** → owner approval; flag them, don't decide them.
- **Copy findings belong in the review report** with their `cl-ux-writing` audit id when one exists
  (e.g. "= cl-ux-writing #1").

## 4. Severity cues

| Severity | Examples |
|---|---|
| Blocker | vi and en say materially different things about money, health, data or permissions; a wrong CTA destination |
| High | Broken plural on a primary surface; an essential value truncated in one language |
| Medium | Two names for one concept on adjacent screens |
| Low | Spelling variant; a slightly unnatural phrase |
