# 04 — UX/UI audit

**Limitation, stated first.** The project's rule D-111 says visual truth comes from a fresh render, never from
stored screenshots. This audit did **not** run `tool/golden_freshness.sh` or open renders, so it makes
**no visual claims** (spacing, colour, hierarchy). UX findings below come from code, executed widget
tests and the recent rendered design reviews in `docs/design/reviews/` (latest 2026-10-29). A launch-scope
design review with fresh renders is part of the action plan ([09](09-action-plan.md)).

## What the design system already guarantees (verified in code and docs)

- Tokens are generated from one source (`packages/design-tokens`, CI check `design-tokens check`). There is
  one primary action per screen (D-105) and shared components (D-107).
- Light and Night care in every golden, vi and en in automated coverage (2,200 golden PNGs).
- Error states name the cause and give a way out (care write toasts:
  `apps/mobile/lib/features/care/care_format.dart:150-177`). D-127's standing rule: unknown is never shown as empty.
- Copy parity: 6,596 ARB keys in vi and en, no missing ids. The 28 placeholder differences are
  deliberate grammar (English plurals, the baby's name in English sentences), not defects.

## Findings

### UX-01 · P1 · The "unknown ≠ empty" protection on Today has a failing guard

This is the user-facing side of [QA-02](03-functional-bugs.md). A parent on a slow network must not see an empty Today
and log the same feed twice. Fix it before any launch build. **Confirmed by executed test**; visual effect not rendered.

### UX-02 · P1 · A paywall that cannot complete a purchase

When Premium v2 surfaces are on, CTAs lead to "Bước thanh toán sắp mở" ("the payment step is coming"). For a parent who just hit
"storage full" while saving a video of their child, this is the most anxious moment in the product, and the
answer is "not yet". See COM-01. **Recommendation:** with no billing, show no upgrade CTA. Show the honest limit
and what still works (keep on phone, delete videos), per D-126 "always a way out".
**Confirmed by code inspection** (ARB `pv2PaySoonTitle`, `pmBuyClosedTitle`).

### UX-03 · P2 · Navigation complexity across flag combinations

There are two navigation models: `adaptive_nav` is either Hôm nay · Kỷ niệm · Khám phá · Hồ sơ, or
Hôm nay · Kỷ niệm · Chăm sóc · Tiện ích (`packages/contracts/src/config.ts:56-61`). Add three roles, multi-baby, and about 40
modules whose entry points depend on flags. Every combination a user can reach needs its own
discoverability and empty-state check. Fewer launch flags (PRD-01) make this tractable.
**Product improvement opportunity**.

### UX-04 · P2 · Accessibility not verified on devices

The skills define 44 pt targets, 200 % text and contrast, and tests use semantics labels. No VoiceOver or
TalkBack pass, or 200 % text pass, on the launch-scope screens is recorded. **Documentation gap**.

### UX-05 · P2 · English copy unreviewed

See PRD-04. Risky strings include health guidance, money (spending, Premium) and privacy (audience,
sharing, deletion).

### UX-06 · P3 · Developer screens ship in the production binary

`/showcase` and `/diagnostics` are registered for every environment, and the guard always lets them through
(`apps/mobile/lib/app/route_guard.dart:276-279`). Diagnostics hides the test-crash button outside dev
(`diagnostics_screen.dart:61`) and links to Showcase (`:65`), which has no environment gate. They are not
reachable from universal links (prod paths are `/i/` and `/auth/link/` only). Remove them from prod
routes. **Confirmed by code inspection**.

## Emotional and product experience (subjective, labelled as such)

- **Trust:** strong signals. The audience is always visible, refusal messages are honest, and deletion is real. Placeholder
  legal pages (LEG-01) and a paywall that cannot take money (UX-02) undercut the "private family space" promise
  at exactly the moments trust is formed.
- **Effort:** quick log and presets are built for one-handed night use. The breadth of modules may dilute
  the calm first-week experience. Keep advanced modules off for the first cohort.
