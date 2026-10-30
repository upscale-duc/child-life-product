# 14 · Decision log

Items marked **L3** need the product owner; once decided, they move into `docs/product/business-map.md` as D-xxx (the next free id after D-141) with the owner's words. This file uses local ids (Q-AXA-n) so it does not collide with business-map numbering.

## 0. Decided (2026-10-30, D-143)

The owner answered on this log: "ko cần rollout từng đợt vì app chưa golive. bỏ năm đầu đời ở onboarding luôn. thêm dịp sinh nhật. gộp vào mục tiêu luôn. đổi tên của con luôn."

| Id | Answer | Done in |
|---|---|---|
| Q-AXA-2 | No staged rollout (not live yet): both flags on for all from launch | Flag values are set in the portal (`config/flags`); code defaults unchanged |
| Q-AXA-5 | "năm đầu đời" / "chặng đầu" removed from onboarding | `tool/d143_child_terms_strings.py` (`welcomeBody`, `welcomeExplore`, `a11yJourney`) |
| Q-AXA-7 | Birthdays every year, 2–12 | `occasions.y2…y12` (contracts), `Occasion.y2…y12`, portal labels, `tool/d143_birthday_strings.py` |
| Q-AXA-1 | Goals replace EN01 interests | `interestsForGoals` (contracts + Dart), `readPreferences(db, uid, babyId)`, `contentPreferencesProvider`, EN01 step and invite skipped with Adaptive |
| Q-AXA-4 | Child's name / "con" / "child" on cross-age screens | `tool/d143_child_terms_strings.py`; glossary §7 |

Still open below: Q-AXA-3, Q-AXA-6, Q-AXA-8, Q-AXA-9.

## 1. Proposed decisions (owner, L3)

| Id | Question | Recommendation | Trade-off | Blocks |
|---|---|---|---|---|
| Q-AXA-1 | Merge EN01 interests into per-child goals for layout; keep interests only as content topics? | **Yes** | One less ask; existing EN01 answers survive as topics | RM-02 |
| Q-AXA-2 | Roll out `adaptive_experience` + `adaptive_nav`: new families first, then families with a child ≥ 12 m, then all? | **Yes, staged**, after Phase 0 baseline and Android check | Earlier rollout gives data sooner; nav change for existing users is the main risk | RM-01 |
| Q-AXA-3 | Keep the AX06 preview step in setup? | **Make it optional** ("Xem trước" link) | Fewer steps vs a "this is for you" moment | RM-01 |
| Q-AXA-4 | Cross-age term: "con" / child's name instead of "bé" / "baby" on profile, family, switcher, invites? | **Yes for English everywhere cross-age; Vietnamese "con" on cross-age rows, "bé" kept in infant care** | Canonical term change across app and portal | RM-06 |
| Q-AXA-5 | Welcome copy without "năm đầu đời"? | **Yes**; keep "chặng đầu" honesty in Khám phá's "Cùng con lớn lên" | Positioning vs honesty about content depth | RM-07 |
| Q-AXA-6 | Ask notification permission after the first reminder for 3+ children without care trackers? | **Experiment** | D-098 chose launch-time ask for every family | RM-17 |
| Q-AXA-7 | Yearly birthday occasions y2…y12 and a year in review in the keepsake catalogue? | **Yes**, templates through the existing review | Template work; render cost under D-124 | RM-09, RM-13 |
| Q-AXA-8 | Q-094: upper band | **Keep "6+" open-ended**, no 12+ content | Teen families are rare in the current audience | RM-22 |
| Q-AXA-9 | Show "Có thể bạn cần" (one unused feature) on Today? | **Experiment** for 1+ only | Discovery vs crowding | RM-19 |

## 2. Engineering decisions inside existing authority (L1/L2, no owner stop)

| Id | Decision | Basis |
|---|---|---|
| E-1 | Today fixed blocks become registry slots with eligibility; no visual change | P-175 architecture |
| E-2 | One `ChildContext` + coverage constants in contracts, tested against seeds | AXA-04, AXA-05 |
| E-3 | Shared age vectors for Dart and TS | CH-01 follow-up |
| E-4 | Growth after 5 y shows trend without percentile | Honesty rule (AX00 rule 2) |
| E-5 | Library facets aligned to content buckets | CH-02 |

## 3. Assumptions

- The audience is mostly 0–2 today; older-child families are a minority. (Unverified: Phase 0 reads it.)
- Families keep taking photos at every age; the value of Child Life for 3+ is organising and celebrating them. (Hypothesis.)
- Daily opens fall after 12 months for most families. (Hypothesis consistent with care-log nature.)
- Remote flag state on dev and prod was not read.

## 4. Open questions for research

| Question | Method |
|---|---|
| Why do families with a child ≥ 12 m stop opening the app? | Interviews + D30 by band |
| Do 3–6 families use Chi tiêu and Nhắc nhở enough to lead Today? | Widget taps by band |
| Would late joiners import years of photos? | S4 experiment conversion |
| Which CH02 need (potty, routines, behaviour) is strongest? | "Báo tôi khi có" terms + interviews |
| Is "bé" acceptable to parents of 6–10-year-olds in Vietnamese? | Five-second copy test |

## 5. Trade-offs recorded

- **Stable nav over age-adaptive nav:** predictability wins; age moves content only.
- **Rules over ML:** few explicit inputs; explainable reasons ("Vì: …") need deterministic scoring.
- **Memories over new CH02–CH04 features:** cross-age value now, on existing infrastructure; new chapter features wait for data.
- **Suggest over auto-change at birthdays:** less "smart", more trustworthy.
