# 12 · Prioritized implementation roadmap

## 1. Scoring model

Each item is scored 1–5 on user value (V), age coverage (A), strategic alignment (S), retention potential (R), confidence (C), and effort (E, 5 = small), with risk noted. **Score = (V + A + S + R) × C / 5 + E.** The score orders work *within* a priority; the priority itself follows the definitions in the brief (P0 undermines usability, data or core personalization; P1 high value at reasonable cost; P2 strategic; P3 future).

## 2. Prioritized list

| ID | Item | Pri | V | A | S | R | C | E | Score | Kind | Autonomy |
|---|---|---|---|---|---|---|---|---|---|---|---|
| RM-01 | Rollout decision + staged rollout of `adaptive_experience` / `adaptive_nav` (AXA-01) | P0 | 5 | 5 | 5 | 5 | 4 | 4 | 20 | Quick win | **L3 owner** |
| RM-02 | One preference model; hide EN01 invite when goals chosen (AXA-02) | P0 | 4 | 5 | 5 | 3 | 5 | 4 | 21 | Foundation | **L3 owner** |
| RM-03 | Android device run with flags on (plan §14 open) | P0 | 3 | 5 | 4 | 3 | 5 | 4 | 19 | Verification | Engineering |
| RM-04 | Today slots in the eligibility pipeline (AXA-03) | P1 | 3 | 5 | 5 | 2 | 4 | 3 | 15 | Foundation | Engineering (no visual change) |
| RM-05 | `ChildContext` + content coverage table + shared end state (AXA-05) | P1 | 4 | 4 | 5 | 3 | 4 | 3 | 15.8 | Foundation | L2 (copy via ARB) |
| RM-06 | Age-neutral wording on cross-age surfaces (AXA-06) | P1 | 3 | 4 | 4 | 3 | 5 | 4 | 18 | Quick win | **L3** (canonical terms) |
| RM-07 | Age-neutral welcome copy (O-3) | P1 | 3 | 4 | 4 | 3 | 4 | 5 | 16.2 | Quick win | L3 (positioning copy) |
| RM-08 | Shared age vectors Dart + TS (AXA-04) | P1 | 2 | 5 | 4 | 1 | 5 | 4 | 16 | Foundation | Engineering |
| RM-09 | Yearly occasions y2…y12 + birthday keepsake suggestion (AXA-07) | P1 | 5 | 4 | 5 | 5 | 4 | 3 | 18.2 | Strategic | L3 (templates, content) |
| RM-10 | Onboarding "bring the past in" step for ≥ 3 m (O-5) | P1 | 4 | 4 | 5 | 4 | 3 | 3 | 13.2 | Experiment | L2 |
| RM-11 | Growth: honest state after 5 y | P1 | 3 | 2 | 3 | 2 | 5 | 5 | 15 | Quick win | L2 |
| RM-12 | Library facets aligned to buckets (CH-02) | P1 | 2 | 2 | 3 | 1 | 5 | 5 | 13 | Quick win | L1 |
| RM-13 | Year in review + "năm ngoái lúc này" | P2 | 5 | 4 | 5 | 5 | 3 | 2 | 13.4 | Major investment | L3 (feature) |
| RM-14 | Then & Now | P2 | 4 | 3 | 5 | 4 | 3 | 2 | 11.6 | Major investment | L3 |
| RM-15 | Retrospective shelf past y1 | P2 | 3 | 3 | 4 | 3 | 4 | 4 | 14.4 | Low-cost extension | L2 |
| RM-16 | Lumi rule intents for reads (spending total, next week, next vaccine) + coverage in context | P2 | 3 | 4 | 4 | 3 | 4 | 3 | 14.2 | Low-cost extension | L2 (AI claims: L3 if wording changes) |
| RM-17 | Notification ask after first reminder for 3+ without trackers | P2 | 3 | 3 | 3 | 3 | 3 | 4 | 11.2 | Experiment | **L3** (changes D-098) |
| RM-18 | Reminder and spending templates by band | P2 | 3 | 3 | 3 | 2 | 3 | 4 | 10.6 | Low-cost extension | L2 |
| RM-19 | "Có thể bạn cần" row on Today | P2 | 3 | 4 | 3 | 3 | 3 | 3 | 10.8 | Experiment | L2 |
| RM-20 | Milestones → "Lần đầu của {tên}" after 36 m | P2 | 3 | 3 | 4 | 3 | 3 | 3 | 10.8 | Low-cost extension | L3 (content model) |
| RM-21 | Vaccine schedules past 72 m (official data only) | P2 | 3 | 2 | 3 | 2 | 3 | 3 | 9 | Extension | L3 (health content) |
| RM-22 | Upper band "6+" copy; decide Q-094 | P2 | 1 | 2 | 2 | 1 | 4 | 5 | 9.8 | Quick win | L3 |
| RM-23 | Coarse cross-device usage sync (AXA-08) | P3 | 1 | 3 | 2 | 1 | 4 | 3 | 8.6 | Foundation | Engineering |
| RM-24 | Potty learning tracker (CH02) | P3 | 3 | 1 | 3 | 2 | 2 | 2 | 5.6 | Future | L3 |
| RM-25 | WHO 5–19 reference | P3 | 2 | 2 | 2 | 1 | 2 | 2 | 4.8 | Future | L3 |
| RM-26 | Documents vault, allergies/medicine list | P3 | 3 | 3 | 3 | 2 | 2 | 2 | 6.4 | Future | L3 (privacy) |

**Postpone deliberately:** school/homework, learning plans, child-facing access, chores and rewards, screen-time tools, social features, streaks, AI-chosen layouts, age themes.

## 3. Phases

### Phase 0 · Discovery & baseline (≈ 1–2 weeks of one engineer + owner time)
- **Scope:** RM-03; read real flag state and family counts by band; turn on the portal readout; write the age vectors (RM-08); fresh goldens of Today, Mốc, Thư viện, Tăng trưởng at 5 y and 9 y.
- **Deliverables:** baseline table (families by band, first value action, D7/D30 by band where data exists), rendered evidence pack.
- **Dependencies:** dev Firebase access, Android emulator family with flags.
- **Risks:** too few older-child families to read anything → qualitative interviews carry the signal.
- **Acceptance:** baseline published; Android adaptive screens rendered and checked; age vectors green in both runtimes.
- **Metrics:** none to move; establish.

### Phase 1 · Personalization foundation (≈ 2–3 weeks)
- **Scope:** RM-02, RM-04, RM-05, RM-11, RM-12.
- **Deliverables:** one preference model, Today slots, ChildContext + coverage, shared end state, growth 5+ state, library facets.
- **Dependencies:** owner answer on RM-02 (Q-AXA-1).
- **Risks:** EN01 users lose a familiar card → mapping keeps their topics for content.
- **Acceptance:** no screen at 5 y / 9 y shows empty content without the end state; Today eligibility debug lists a reason for every excluded block; all band goldens green.
- **Metrics:** share of Today blocks shown with zero content (target: none).

### Phase 2 · Adaptive experience in front of families (≈ 2–4 weeks, mostly rollout time)
- **Scope:** RM-01 staged rollout, RM-06, RM-07, RM-10, RM-17 (if approved), RM-19 (experiment).
- **Deliverables:** flags on for staged cohorts; wording change; bring-the-past-in step.
- **Dependencies:** Phase 0 baseline; owner decisions Q-AXA-2…5.
- **Risks:** navigation change confuses existing users → paths unchanged, Hồ sơ keeps all Tôi rows, a one-time "Chăm sóc giờ ở Khám phá" tip (**proposal**).
- **Acceptance:** onboarding acceptance from [05 §8](05-onboarding-audit.md); no deep-link regressions (route test).
- **Metrics:** first value action within 24 h by band; D7 by band vs baseline; pin/hide/restore rates; goal-step skip rate.

### Phase 3 · Cross-age feature evolution (≈ 4–8 weeks, content-bound)
- **Scope:** RM-09, RM-13, RM-15, RM-16, RM-18, RM-20, RM-21.
- **Deliverables:** yearly occasions and birthday keepsakes, year in review, retrospective past y1, Lumi read intents, band templates.
- **Dependencies:** template art and owner review; content review for any developmental text.
- **Risks:** template quality, render cost (D-124 quality tiers).
- **Acceptance:** a child turning 2, 5, 9 gets one birthday suggestion with ≥ 8 photos, none without; no push for a passed window.
- **Metrics:** keepsakes per 3+ family per year; D90 after 12 months.

### Phase 4 · Future chapter readiness (ongoing, no build commitment)
- **Scope:** RM-14 Then & Now; decide Q-094; review "Báo tôi khi có" terms; choose at most one CH02 capability (potty or routines) from data.
- **Acceptance:** a written chapter decision backed by interest data and interviews.

Effort ranges assume one engineer with the existing test infrastructure. Team capacity was not known, so they are not dates.

## 4. Success metrics (summary)

| Metric | Why | Source |
|---|---|---|
| First value action ≤ 24 h, by band | Immediate relevance | MET-01 |
| D7 / D30 / D90 by band | Retention past newborn | MET-01 `stageBand` |
| Goal skip rate | Onboarding friction | `adaptive_goals_set` |
| Pin / hide / restore | Predictability | `adaptive_customized` |
| Stage card applied vs kept | Transition acceptance | `adaptive_stage_answered` |
| Keepsakes per family per year (3+) | Memories as anchor | keepsake jobs |
| "Báo tôi khi có" by term and band | Chapter roadmap signal | `adaptive_interest` |

## 5. Validating with real families before scaling

1. **Dogfood** (internal families on dev, one per band where possible): two weeks, a diary of "what didn't fit".
2. **Interviews:** five per band (3–6, 6–12 first), task: "add your child and do what you'd usually do"; observe the first five minutes.
3. **Staged rollout:** new families only first (no migration risk), then existing families with a child ≥ 12 m, then all. Compare to the Phase 0 baseline; stop if D7 drops for 0–1.
4. **Experiments** (RM-10, RM-17, RM-19) as on/off cohorts at the family level, one at a time.
