# 10 · Memories across childhood

## Strategic answer

**Yes, Memories can be what keeps families with Child Life after care tracking stops**, on one condition: it must give back without asking for more work. Families already take photos at every age. Today, Child Life stores them well at any age but only *celebrates* them in the first year.

**Recommendation:** make "look back" the cross-age engagement loop. Build it on the media, ages, albums, renderer and keepsake catalogue that already exist:

1. **Yearly occasions:** birthday keepsakes y2 … y12 (video, card, print) in the existing occasion registry.
2. **Year in review:** on the birthday week, a story/video of the year of age (photos dated between two birthdays).
3. **"Năm ngoái lúc này":** a quiet Today row and an optional push when photos exist ±7 days, 1+ years ago.
4. **Then & Now:** the same pose or occasion across years, chosen from dated media.
5. **Late-joiner backfill:** Tự lưu "past years" pass plus the retrospective shelf extended past y1.

## Current state (fact)

| Capability | State | Code |
|---|---|---|
| Upload, albums, privacy (default parents only), trash, quota | Shipped | `features/memories`, `firebase/functions/src/memories.ts` |
| Pagination for long histories | Fixed (MEM-02, 200 per page) | `docs/product-audit/11-implementation-report.md` #4 |
| Tự lưu (photo discovery, review-first) | Beta, iOS detection | `features/auto_save` |
| Weekly story | Shipped, vi/en (MEM-03) | `firebase/functions/src/stories.ts` |
| Memory Story video (Remotion), cards, Print Studio | Shipped | `apps/renderer`, `features/keepsakes`, `features/print_studio` |
| Occasions | birth, d7, m1–m11, d100, y1, skills (crawls, stands, laughs …) | `features/keepsakes/keepsake_occasions.dart:10-32` |
| Retrospective shelf | Built, targets m1/d100/m6/y1 | `engagement_widgets.dart:131-141`; `docs/product-audit/16-memory-campaigns.md` |
| Milestone → memory link | Built | `milestone_repository.dart` |

## Evolution by stage (illustrative, not templates)

| Stage | What families keep | Occasions | Prompt style |
|---|---|---|---|
| 0–1 | First smile, first month, 100 days, thôi nôi | Monthly + y1 (built) | Frequent, gentle |
| 1–3 | First steps, words, play | Birthdays, "lần đầu" | Weekly at most |
| 3–6 | Drawings, friends, performances | Birthdays, school start (as a memory, not a feature) | Event-driven |
| 6–12 | Trips, hobbies, achievements | Birthdays, year in review, Then & Now | Yearly, reflective |

## Shared infrastructure

All five proposals reuse: media with capture dates; the child's DOB for age at capture; the keepsake catalogue (`publicConfig/keepsakes`) and renderer; the Smart Engagement ledger (no outdated pushes, quiet hours); albums. **New pieces:** occasion definitions for years (content), a "year of age" media query (date range), a Then & Now selector (two dated photos, same album or tag), and template art (content, owner review).

## Without forcing manual documentation

- Suggest from what exists; never ask the parent to write a caption to unlock a keepsake.
- A keepsake suggestion needs enough media (for example ≥ 8 photos in the year); otherwise no suggestion.
- At most one memory nudge a week for 3+, one a month for 6+ (**hypothesis**, tune with D30 data).

## Risks

| Risk | Mitigation |
|---|---|
| Nostalgia that hurts (loss, separation) | All look-back pushes off by a single switch; never push on dates the family hid |
| Privacy (photos to relatives) | Existing per-memory audience; look-back keepsakes inherit the strictest audience of their photos |
| Cost (video renders) | Unlimited exports at plan quality (D-124); suggest, don't auto-render |
| Template quality | Owner review before any occasion goes live (keepsake template process) |

## Success measures

- Share of 3+ families creating ≥ 1 keepsake a year.
- D90 retention for families whose child crossed 12 months, with vs without a birthday keepsake.
- Late joiners: share who import past photos within 7 days.
