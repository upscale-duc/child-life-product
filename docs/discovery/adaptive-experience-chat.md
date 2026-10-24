# Adaptive Experience — ChatGPT strategy conversation (summary)

Source: owner's shared ChatGPT conversation "Phân tích cá nhân hóa theo độ tuổi" (https://chatgpt.com/share/6adc05db-a144-83ec-a1d4-ed23e5124a55), read 2026-10-24. This is a summary for engineering, not a transcript. Where it conflicts with Figma section `930:11858` (see `figma-extract/40-adaptive-experience.md`), **Figma wins** (CLAUDE.md: Figma is V1 scope).

## Owner's problem statement (turn 2, owner's words, paraphrased)

The app mainly serves 0–1 today, but some features last the child's whole journey (Chi tiêu, Kỷ niệm…). Onboarding does not lock any age, so the app must personalise **now** so families with older children can use the lifelong features, with a UI/UX plan and an architecture that lets each stage be built later.

## Strategy proposed

- **Universal Core + Age-Adaptive Experience + Progressive Chapters.** A chapter is a product roadmap concept, never a restriction on who may use the app.
- Feature groups:
  - A — Universal (any age): Moments/Kỷ niệm, Memory Studio (video, thiệp, câu chuyện), Expenses/Chi tiêu, Family, Notes, Reminders, Lumi, Notifications.
  - B — Age-specific (recommended range, not a hard lock): feeding 0–12 m, sleep 0–3 y, diaper 0–3 y, growth, milestones, Wonder Weeks, ăn dặm; future toddler/learning/goals.
  - C — Cross-chapter: same module identity, capabilities grow per chapter (Growth, Moments).
- **One design system, adaptive content & order** — no four separate Home screens. Change: module priority, Home content, quick actions, recommendations, copy. Never show unbuilt features as if they work ("Personalize what exists. Don't pretend to offer what hasn't been built.").
- **Navigation**: Home · Moments · Explore · Lumi · Family. Explore absorbs new chapter modules so the tab bar never changes. (Figma refines this to Hôm nay · Kỷ niệm · Khám phá · Hồ sơ + separate Lumi button.)
- **Onboarding**: Add child (name, birthday, photo optional) → "Family Intent" multi-select (preserve memories, daily care, development, expenses, family tasks, explore), recommend max 2–3, skippable, editable later → personalised Home.
- **Adaptive widgets**: Home = ordered widget slots with metadata (`id`, `module`, `supportedAgeMonths {min,max} | null`, `priority`, `supportedIntents`, `requiresFeature`). Distinguish **eligibility** (fits age/intent) from **availability** (feature shipped).
- **Ranking**: rule-based score — intent 35 % · age 25 % · usage frequency 20 % · recent activity 10 % · product priority 10 % (starting weights for experiment). Hard rules: only released features; pinned never moved; hidden never re-appears; no data → age + intent default.
- **Customize Home**: reorder, hide, pin, restore defaults.
- **Older children in V1**: no "come back later" message; lead with what works now (Kỷ niệm, Chi tiêu, Memory Studio, Mời người thân). Future chapters only as a small "Growing with your child" card in Explore, optionally "register interest".
- **Architecture layers**: Flutter UI → Experience Engine (age resolver, family intent, widget ranking, nav config, preferences) → Feature Registry (availability, age relevance, chapter metadata, platform, rollout) → domain modules → Firebase. Remote Config only controls config/rollout, never activates code not in the binary; manifest validated against capabilities registered in the app.
- **Data**: child profile independent of chapter — never store `chapter` on the child and gate on it. Age computed from birth date in the child's timezone; corrected age kept separately. Experience config separate from domain data (`families/{f}/experiences/{childId}` suggested; illustrative). Family-scoped records (e.g. an expense for two children) should support multiple child ids.
- **Multiple children of different ages**: child context is a first-class concept; each widget knows which child (or whole family) it runs for. No complex family dashboard yet.
- **Cold start → learning → personalised** states; never show insights without enough evidence.
- **Plan priorities**: P0 Feature Registry, age resolver, child context, family intent onboarding, adaptive Home widgets/quick actions/Explore, ranking + cold start; P1 Customize Home, analytics, chapter module registration; P2 AI recommendations.
- **Not now**: four Home variants, chapter 02–04 features, AI deciding the UI, deep personalisation without data, filler widgets, a CMS for arbitrary UI.
- **Metrics**: onboarding completion, first value action, feature adoption by age band, D7/D30 retention by age band, Home widget engagement. No child names/photos/sensitive data in events.
- **Migration**: upgrade the current app without data loss, without breaking finished modules, without re-onboarding existing users. Called the most important part.

## Turn 1 (longer-term personalisation vision, not V1)

Four levels: L1 age-aware, L2 context-aware (care data), L3 behaviour-aware, L4 predictive. V1 = L1–L2, lay L3 foundations. Ideas for later: sleep rhythm hints ("gợi ý dựa trên thói quen quan sát được"), ăn dặm journey, Development Profile, Interest Profile (1–3), Story Studio (3–6), child-directed goals (6–12), Smart Memories / Life Recap. Principles: personalisation ≠ AI; helpful without pressure (no "con đang chậm phát triển"); family controls it (why am I seeing this, edit, turn off per type). Free tier keeps basic personalisation; safety/essential development info never paywalled.
