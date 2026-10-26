---
name: cl-ux-writing
description: Bilingual (Vietnamese + English) UX writing and localisation for Child Life. Use whenever user-facing text is written, changed or reviewed — ARB strings in apps/mobile/lib/l10n, button labels, titles, empty / error / loading / success copy, confirmations, toasts, push and notification templates, onboarding, Premium / paywall copy, Lumi and AI insight wording, accessibility labels, numbers / dates / units in text — and when choosing a product term (glossary), adding ARB keys or placeholders, fixing plurals, or auditing copy. Works alone for copy-only tasks; routed from senior-ui-ux for screen work.
---

# Child Life UX writing (vi + en)

Both languages are first-class. **Vietnamese is the ARB template; English is written for native
readers, not translated word for word.** The shipped ARB copy is the source of truth (D-104). Don't
silently rename an established product concept. Autonomy (`senior-ui-ux` §3, D-109):

- **L1, no approval:** clearer copy within approved terminology, both languages.
- **L3, owner:** changes to canonical terms, or to legal, consent or privacy wording, or material
  changes to AI or health claims. Isolate them and continue with the rest.

**Comprehension beats word count.** Shorter is better only while the meaning stays clear.

**Every line must earn its place (D-110).** Before improving a string, decide whether it should
exist: remove subtitles that restate the title, text explaining obvious actions, internal or
technical language and explanations that repeat what is visible. Prefer deletion over rewriting;
keep meaningful instructions, status and error feedback. Rules: `references/simplifying-copy.md`.
In a structural redesign (D-112), copy is decided after the structure: let grouping and headings
carry meaning, then write only the labels the new structure still needs.

**Non-negotiable: preserve verified business meaning.** Every proposal keeps the product's real
behaviour. Before rewriting a status, action, permission, error or explanation:

1. find the current key and wording;
2. read the business rules (`docs/product/business-map.md`) and the code that triggers it;
3. state what the system actually does (when, for whom, what has or hasn't happened);
4. check that the new wording says exactly that.

If the behaviour is uncertain, mark the proposal **`Needs behavior verification`** and keep the
accurate current wording. Never present unverified wording as an approved replacement.
Details: `references/ui-copy-patterns.md` §5.

## Ten questions before writing

1. What must the reader understand, and what should they do next?
2. What is the shortest *natural* way to say it?
3. What deserves visual emphasis, and is that a number or a state?
4. Which form fits: label, value, sentence, list, or action?
5. What is the moment: tracking, night, health, celebration, error, Premium, or Lumi?
6. How would a Vietnamese parent say it?
7. How would a native English app say it?
8. Do both carry the same intent, action, state, certainty, tone and placeholders?
9. How does it read in every state (empty, loading, error, partial, role, plural, long name)?
10. Have I rendered both languages (goldens vi + en, 200 % text)?

## Always

- **Voice:** warm, calm, clear, never judging. Address the reader as "bạn" / "you"; the child is
  "bé" / "your baby" or `{name}`.
- **Technical terms depend on context.**
  - Plain wording is the default on everyday surfaces.
  - Precise terms (đồng bộ / sync, offline, sao lưu / backup, quyền / access, dữ liệu / data)
    belong where they help understanding: sync, offline storage, backups, privacy, permissions,
    account security, troubleshooting.
  - Never replace a technical term with friendlier words that change its meaning.
- **Glossary terms only** (`references/terminology-glossary.md`). Each entry has two separate
  statuses:
  - implementation: Implemented / Approved · Planned / Proposed / Deprecated / Verify;
  - terminology: Verified / Recommended / Owner decision.

  Absence from the code doesn't mean unapproved: check `business-map.md`.
- **Reuse the shared action keys** (`actionSave`, `actionDone`, `actionRetry`, `actionLater`,
  `undo` …).
- **Buttons:**
  - a specific verb that names the result ("Ghi cữ bú" / "Log a feed");
  - the confirm verb repeats the action ("Xoá", not "Đồng ý");
  - a longer label is fine when clearer.
- **Errors:** what happened, then what to do. "Chưa … được" / "Couldn't …". Never blame, never
  show raw codes.
- **Empty states:** what's missing, then (why), then one action.
- **Numbers:** use a visual (stat, row value) when it helps scanning or comparison. A natural
  sentence with numbers is fine when clearer ("Bé ngủ từ 20:30 đến 06:00"). Always attach units;
  format per locale; give a spoken form for screen readers.
- **AI and personalisation:** keep observed facts, calculated summaries, pattern suggestions,
  predictions ("khoảng" / "around") and AI interpretations distinct. No diagnosis, no "bé đang
  thiếu ngủ", no claim that Lumi "saw" or "understood" beyond the logs.
- **Premium:** clear value and what Free keeps. No guilt, fear of missing milestones, or false
  urgency.
- **ARB:**
  - every user-facing string, including semantics and errors, goes in both files with a useful
    `@description` (say who `{name}` is);
  - en uses ICU plurals when a count meets a noun;
  - no string concatenation in Dart;
  - add strings via a `tool/<topic>_strings.py` script, then `flutter gen-l10n`.
- **Verify on rendered goldens** in vi and en: fit, truncation, plurals.

## References (load what the task needs)

| File | Load when |
|---|---|
| `references/voice-and-tone.md` | Choosing tone for a context: tracking, memories, night, health, error, Premium, Lumi, family, onboarding |
| `references/bilingual-writing.md` | Writing or reviewing vi and en together; parity rules; vi orthography; en style |
| `references/terminology-glossary.md` | Naming anything: features, care types, roles, plans, AI, actions. Separate implementation and terminology statuses; internal names (Memory Story, Milestone Magic) and landing-only tiers (Plus / Pro) |
| `references/simplifying-copy.md` | Every copy task first: removing redundant subtitles and helper text, shortening labels, internal language, setting names, what to preserve |
| `references/ui-copy-patterns.md` | Copy for a specific UI element (titles … paywalls), notifications and push, technical terms by context (§4), the verified-meaning procedure (§5), content priority |
| `references/numbers-dates-and-units.md` | Quantities, durations, times, dates, ages, weights, prices, credits, storage, plurals, spoken numbers |
| `references/personalization-and-ai-copy.md` | Insights, predictions, Lumi wording, the child's name and age, family activity, smart suggestions |
| `references/localization-and-arb.md` | Adding or changing keys, placeholders, ICU, glance / widget copy, push templates, validation commands, the bilingual checklist |
| `references/content-audit.md` | The current findings (25, prioritised, each with a behaviour-verification status), strengths to keep, and the review rubric (blockers vs recommendations) |

**Boundaries:**

- Which component holds the text belongs to `cl-components`.
- Screen layout and states composition belong to `cl-screen-patterns`.
- Visual type and colour come from `cl-design-foundations`.
- Final review belongs to `cl-design-review` (copy checks: `content-and-localization-review.md`).
- Lumi's generated text comes from server prompts (`firebase/functions/src/ai.ts`,
  `assistant-*.ts`). Don't change them from here.

## Before finishing

- [ ] Nothing redundant left: no subtitle restating its title, no obvious-action explanation,
      no internal language; Essential feedback preserved.
- [ ] vi and en each sound native; meaning, certainty and placeholders match.
- [ ] Glossary terms; no new synonym; no silent rename.
- [ ] Verbs say what happens; the CTA matches its destination.
- [ ] Plurals, dates, numbers and units are correct per locale; spoken forms exist.
- [ ] The proposal preserves verified behaviour, or it is marked `Needs behavior verification`.
- [ ] Technical terms only where they are clearer or more accurate; no guilt or pressure; no
      unsupported AI certainty.
- [ ] Both ARB files and `@description`s updated via a script; `flutter gen-l10n` passes.
- [ ] Rendered in vi and en (and 200 % where the text grew); nothing essential truncated.
