# Content simplification (the Simplify stage, D-110)

**Every visible element must earn its place.** Existing text, subtitles, cards, icons and badges
are not mandatory because they exist. The job is to decide what deserves to stay visible, then
make that look good. Not the other way round.

> The best interface is not the one with the least text. It is the one where every visible
> element helps the reader understand, decide, or act. Design for comprehension, not
> explanation.

This file is the canonical model. Each specialised skill holds only its own part:

| Part | Owner |
|---|---|
| Copy rules: redundant subtitles, label length, obvious-action text, internal language | `cl-ux-writing` → `references/simplifying-copy.md` |
| Structure: compact presentation, progressive disclosure, nested cards, repeated headings, settings and onboarding | `cl-screen-patterns` → `references/compact-and-decluttered.md` |
| Optional content slots; no forced subtitles or decorative containers | `cl-components` → `references/component-selection.md` §Content slots |
| Philosophy: comprehension, not explanation | `cl-design-foundations` SKILL.md |
| Review category "Content necessity & information density" | `cl-design-review` → `references/ux-quality-rubric.md` |

## 1. When

**Simplify comes after Audit and before Structure / Design.** Never polish an element you
haven't first decided to keep. It applies to every UI/UX task, including single-screen fixes,
without the owner asking for it each time.

## 2. Classify every piece of content

List every visible element on the screen (text, subtitle, helper line, badge, icon, divider,
card, CTA). Classify each one:

| Class | Means | Default action |
|---|---|---|
| **Essential** | Needed to understand the current state, decide, act correctly, read a number, avoid a mistake, or understand an error or consequence | Keep visible (PRESERVE, maybe REWRITE) |
| **Contextual** | Useful only in some circumstances: advanced explanations, feature details, rare instructions, technical background | RELOCATE to where it is needed: the state it explains (show it only when it applies), an info sheet, first-use guidance, the error state |
| **Redundant** | Repeats the heading, restates the button, explains an obvious action, duplicates something already visible, exposes implementation details, or helps no decision | REMOVE |

Don't hide information behind an extra tap merely to reduce text. Relocation is for content
that is genuinely situational.

## 3. The five actions

Choose exactly one per element, and record the non-obvious ones in the report.

| Action | Use when | Example |
|---|---|---|
| **REMOVE** | The information itself is unnecessary. Prefer deleting over rewriting | "Chi tiêu tháng này / Vì: Chi tiêu cho con" → "Chi tiêu tháng này" |
| **MERGE** | Two elements say parts of one thing | "Thông báo của Child Life / Đang bật trong cài đặt hệ thống" → "Thông báo ứng dụng · Đang bật" (keep the OS permission vs in-app preference distinction) |
| **REWRITE** | Needed, but longer or less natural than it should be | "Vào Hôm nay của Cam" → "Khám phá Hôm nay" |
| **RELOCATE** | Secondary explanation sitting in the primary hierarchy | How suggestions are personalised → contextual help, while what the setting controls stays visible |
| **PRESERVE** | Removing it would cost clarity, trust, accessibility or safety | Units, required labels, status, destructive warnings, unsaved changes, sync status, timer state, permission consequences, save confirmations, validation and error feedback, loading indicators |

**Minimalism never overrides correctness.** When unsure whether something is Essential, check
the behaviour (`cl-ux-writing` → `ui-copy-patterns.md` §5) and keep it.

## 4. Visual structure is content too

For each card, container, divider, icon, badge, CTA and large gap, ask:

1. Does this container communicate a grouping?
2. Does this icon help recognition (or is the text already enough)?
3. Does this divider improve scanning?
4. Is this CTA necessary, or does it duplicate another?
5. Is this spacing helping comprehension?
6. Could a simpler layout say the same thing?

Remove what adds complexity without comprehension. Don't make screens artificially dense: keep
44 pt targets, readable type and breathing room (`cl-design-foundations`).

## 5. Autonomy

Routine simplification is **L1 / L2** (`SKILL.md` §3):

- **L1:** removing redundant subtitles, shortening labels, simplifying descriptions, removing
  decorative elements, spacing, wrapping, hierarchy.
- **L2:** simplifying composition, merging redundant groups, redesigning settings layouts,
  onboarding presentation, progressive disclosure, simpler forms and lists.
- **L3 (owner):** business semantics, canonical feature names, permission behaviour, data
  accuracy, subscription, navigation, destructive actions, consent, privacy, Adaptive ranking or
  Customization logic.

## 6. Output of the stage

A short table in the working notes or report:

| Element | Class | Action | Why |
|---|---|---|---|
| History tile "Mọi lần đã ghi" | Redundant (restates "Lịch sử") | REMOVE | Title says it |
| Sleep-chooser footnote on switching modes | Contextual (rarely needed) | REMOVE / RELOCATE | Both options already say what they do |

Then Structure and Design work only with what survived.
