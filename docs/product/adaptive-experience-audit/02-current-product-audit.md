# 02 · Current product audit

All paths are relative to the repo root. "Age range" means what the code or published content actually covers, not what the feature could serve.

## 1. Personalization capabilities that already exist

| Capability | What it does | Code | Status |
|---|---|---|---|
| Age bands | `b0_1` < 12 m, `b1_3` < 36 m, `b3_6` < 72 m, `b6_12` open-ended | `packages/contracts/src/adaptive.ts:14-38`; Dart `apps/mobile/lib/features/adaptive/adaptive_engine.dart:9-31` | Built, tested on shared fixtures |
| Age from DOB in the child's zone | `childMonthsProvider`; null when the viewer cannot read DOB | `apps/mobile/lib/features/adaptive/experience_repository.dart:105-120` | Built |
| Goals (6) + band presets | `track_care, memories, growth_vaccines, family, spending, reminders` | `adaptive.ts:49-71` | Built |
| Widget registry + band defaults | 14 Today widget ids with goals served; ordered defaults per band | `adaptive.ts:79-139` | Built; `product` weight is 0 for all |
| Weighted ranking | 0.35 goal · 0.25 age · 0.20 usage · 0.10 recent · 0.10 product; pins first, manual order wins (P-176) | `adaptive.ts:143-340` | Built |
| Experience doc | `users/{uid}/experience/{babyId}`: goals, source, `bandApplied`, order, pinned, shown, hidden, stagePrompts | `adaptive.ts:165-194`; Rules `firebase/firestore.rules`; purge `firebase/functions/src/account.ts` | Built, rules-tested |
| Stage transition card | Once at 12/36/72 months; Áp dụng / Giữ như cũ | `apps/mobile/lib/features/adaptive/adaptive_signals.dart` (`AxStageCard`, `applyStage`) | Built |
| Usage + recency signals | Taps per widget per person × child, 28 days, **on this phone**; recency 48 h; frozen per app run | `adaptive_signals.dart` (`UsageStore`, `rankSignalsProvider`, `AdaptiveTapTracker`) | Built |
| Khám phá catalogue | "Gợi ý cho {tên} lúc này", grouped V1 catalogue, accent-insensitive search, honest no-result, "Cùng con lớn lên" + "Báo tôi khi có" | `apps/mobile/lib/features/adaptive/explore_screen.dart`; merged with Chăm sóc (D-139) | Built |
| NavBar v2 by role | Parent: Hôm nay · Kỷ niệm · Khám phá · Hồ sơ (+ Lumi); caregiver: Hôm nay · Khám phá · Hồ sơ; relative: Kỷ niệm · Hồ sơ | `apps/mobile/lib/core/widgets/cl_navigation.dart` (`tabsForRoleV2`) | Built |
| EN01 interests (personalization v1/v2) | `sleep, feeding, milestones, vaccines, nutrition, moments`, per **person** (not per child) | `packages/contracts/src/personalization.ts:27-34`; invite `apps/mobile/lib/features/today/today_personalize.dart:217-230` | Built, shown when `personalizationOffered` |
| Personalized day (server) | Age card, idea of the day, weekly focus, digest | `firebase/functions/src/personalization-v2.ts`; age cards to 24 months, corrected age (D-141) | Built |
| Analytics by band | `adaptive_*` events, `stageBand` 0–1 / 1–3 / 3–6 / 6+ with a privacy threshold | `packages/contracts/src/product-analytics.ts:234-236` | Built |
| Flags | `adaptive_experience`, `adaptive_nav` | `packages/contracts/src/config.ts:60-63, 131-132` → `off('internal')` | **Off by default** |

## 2. Feature inventory

Columns: pillar · status · problem solved · age range today (code/content) · potentially relevant · age-dependent logic · limits · reuse · change · complexity · priority. The classification is in [04](04-feature-age-matrix.md).

| Feature | Pillar | Status | Primary problem | Age today | Could serve | Age logic in code | UI/UX limits | Reuse | Change | Cx | Pri |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Care log (bú bình, bú mẹ, hút sữa, ngủ, tã) + timers | Care | Shipped | Know what happened, hand over | Any (no gate) | 0–3 (sleep 0–6) | Bottle presets from age table (D-132); trackers per child | Tiles assume feeds; no potty, no custom type | Tracker set per child, quick log | Add potty/custom types later; band trackers already | M | P2 |
| Lịch sử, Thống kê | Care | Shipped | See patterns | Any | 0–3 | None | Feeds/sleep-centric charts | Day timeline | None now | — | — |
| Nhắc nhở (rules, all-day, assignee) | Care | Shipped | Not forget | Any | 0–12 | Rule templates infant-leaning | Templates are feed/medicine | Rule engine | Age-relevant templates (school day, dentist) as content | S | P2 |
| Tiêm chủng (country schedules) | Care | Shipped | Stay on schedule | Schedules to 72 months | 0–12 (boosters to ~12, HPV later) | Due/overdue by DOB | "Sơ sinh · đã quá N ngày" fixed in §13 | Country registry | Extend schedules past 6 y where official | M | P2 |
| Tăng trưởng (WHO bands, chart) | Grow | Shipped | Is growth on track | WHO 0–5 y (`who_growth.dart:24` maxDays 1856) | 0–18 | Percentile by age/sex | Beyond 5 y: no band, chart blank? (verify) | Measurement model is age-free | Honest state > 5 y; WHO 5–19 reference later | M | P1 (state) / P3 (ref) |
| Mốc phát triển | Grow | Shipped (draft content) | Notice and record development | Seed 68 items, max range 36 months | 0–6 | Age windows, never deadlines | After 36 m: nothing suggested | Custom milestones, memory link | "Lần đầu" / achievements as custom categories | M | P2 |
| Dành cho bé hôm nay / Tuần này của bé | Grow | Shipped | Ideas suited to now | Age cards to 24 m (760 d); activities by stage | 0–3 now | Stage, corrected age (D-141) | No coverage state for 2+ | Content pipeline + review | Honest end-of-coverage; toddler-v2 draft (24 items) pending review | S | P1 |
| Nhịp lớn lên (Wonder Weeks model) | Grow | Shipped (Premium) | Understand fussy periods | 10 stages, infancy | 0–1 | Due-date based | Infant only by nature | — | Keep age-specific; hide from 1+ defaults (already) | — | — |
| Ăn dặm | Care | Shipped | Start solids safely | 6–36 m (`solids.ts:23-25,177`) | 0.5–3 | Ready/soon/too young | Ends at 36 m | — | KEEP age-specific | — | — |
| Dinh dưỡng | Grow | Shipped | What to feed | Stages to 36 m (`nutrition.ts:20`) | 0–6 | Completed months | Ends at 36 m | Content model | Extend content only with review | M | P3 |
| Thư viện (articles) | Grow | Shipped | Trusted reading | Filter to 2 y (`content_calc.dart:73-77`), buckets to 36 m (`content.ts:627-641`) | 0–12 | Stage buckets | Filter/bucket mismatch (CH-02) | Portal publishing | Align facets with buckets; "all ages" articles | S | P1 |
| Sơ cứu | Care | Shipped | Act fast in an emergency | Infant + child CPR (`first-aid.ts:92,130`) | 0–12 | Infant/child switch | — | — | KEEP | — | — |
| Chuẩn bị đi khám | Care | Shipped (Premium, D-141) | Prepare a doctor visit | Any with records | 0–12 | Uses care + growth + vaccines | Care-heavy for older kids | Visit report | Adapt sections when no care logs | S | P2 |
| Kỷ niệm (upload, albums, privacy, trash) | Remember | Shipped | Keep and share photos | Any | 0–18 | None | Prompts first-year | Everything | KEEP; add look-back | — | — |
| Tự lưu (auto photo discovery) | Remember | Shipped, beta (iOS detection) | Not miss photos | Any | 0–18 | Face match per child | Backfill offer limited | Engine, review queue | Offer "past years" pass for late joiners | M | P1 |
| Story (weekly), Memory Story video, cards, Print Studio | Remember | Shipped | Turn photos into keepsakes | Occasions birth…y1 (`keepsake_occasions.dart:10-32`) | 0–18 | Occasion by days/months | No y2+, no yearly, no school-start | Template catalogue, renderer | Yearly occasions + birthday as content | M | P1 |
| Retrospective shelf (late onboarding) | Remember | Built, flag-gated | Join late without missing out | m1/d100/m6/y1 windows | 0–3 | `context: 'retrospective'` | First-year targets only | Shelf | Extend targets to y2…y6 | S | P2 |
| Gia đình (roles, invites, relatives) | Family | Shipped | Share care and memories | Any | 0–18 | None | Copy says "baby" | — | Wording | S | P1 |
| Bàn giao, Cùng Chăm Con, care duty | Family/Care | Shipped (CCC per D-135–D-138) | Coordinate helpers | Templates < 6 m (D-136 #4); basic plan by age | 0–6 | EASY < 6 m | Feed-heavy templates | Plan tasks are generic (Tắm, Đọc sách) | Add 2+ basic plan as reviewed content | M | P3 |
| Chi tiêu (+ import) | Family | Shipped | Know what the child costs | Any | 0–18 | None | Categories infant-leaning? (verify) | — | Category set review | S | P2 |
| Lumi | Intelligence | Shipped (credits) | Log and ask fast | Any; care paths infant | 0–12 | Band example questions (flag); ageDays in care model | Recall/summary use cases thin for 3+ | Reads across modules | See [09](09-lumi-insights-strategy.md) | M | P2 |
| Smart Engagement / notifications | Intelligence | Shipped (D-092, D-098, D-099) | Timely nudges | Campaigns first-year | 0–12 | Milestone windows; no late pushes | Few triggers past 1 y | Engine, ledger, quiet hours | Yearly + birthday triggers | S | P2 |
| Living Header | Remember | Shipped (D-128) | Emotional entry | Any | 0–18 | None | — | — | KEEP | — | — |
| Premium | — | Shipped (store purchase closed) | Revenue | Any | — | — | — | — | Out of scope | — | — |

**Not found in the repo** (in scope of this search): potty/toilet tracking, school or activity calendar, yearly recap, child-facing access, learning goals. These are listed as future capabilities in [04](04-feature-age-matrix.md), not gaps to fix now.

## 3. Findings register

### AXA-01 · P0 · The cross-age experience is dark for real families
- **Current:** `adaptive_experience` and `adaptive_nav` are `off('internal')` (`packages/contracts/src/config.ts:131-132`). A first child gets the goals flow only when the *public* flag is `enabled` with `scope == 'all'` (`apps/mobile/lib/features/adaptive/adaptive_setup.dart:39-57`); otherwise 10a → 11 → 12 (trackers).
- **Impact:** a family whose first child is 5 picks feed trackers and lands on a newborn Today with Chăm sóc / Tiện ích tabs. This is the "not for me" moment the plan (§1) set out to remove.
- **Proposal:** an L3 rollout decision with a staged plan ([12 §5](12-prioritized-roadmap.md)). Before that, run the device checks plan §14 left open (Android with flags on).
- **Confidence:** High for code defaults; Low for actual dev/prod flag state (not read).

### AXA-02 · P0 · Two overlapping preference models
- **Current:** EN01 asks *interests* (`sleep, feeding, milestones, vaccines, nutrition, moments`) per person across all children (`personalization.ts:27-38`); AX asks *goals* per person × child (`adaptive.ts:49-57`). `PersonalizeInviteCard` ("Hôm nay theo cách của nhà bạn") shows on the adaptive Today too (`today_screen.dart`, above `AxStageCard`; gate `today_personalize.dart:223-230` does not check goals).
- **Impact:** a parent answers two similar questionnaires; "feeding" interest for a 7-year-old's sibling leaks across children; the words differ ("điều bạn quan tâm" vs "mục tiêu").
- **Proposal:** one model. Keep goals per person × child as the layout input; derive or retire interests for content (map `moments → memories`, `vaccines → growth_vaccines`, `sleep/feeding → track_care`, `milestones/nutrition` → content topics under growth). Hide the EN01 invite when the experience doc has `goalsSource = chosen`. L3: changes a preference surface.
- **Confidence:** High.

### AXA-03 · P1 · Today ranking covers only part of the screen
- **Current:** before the ranked widgets, Today always draws `TodayLivingHeader`, status banners, `WhatsNewBanner`, `AutoSaveTodayBanner`, `CarePlanTodaySection`, `PersonalizeInviteCard`, `PersonalizeAfterSetupGate`, `AxStageCard`; after them, the "Giao diện" row (`apps/mobile/lib/features/today/today_screen.dart`, the `ListView` children). D-140 "Sắp tới" sits inside the tiles.
- **Impact:** for a family that hides most widgets, the top of Today is still decided by fixed code, not by eligibility + preference. Each new block adds a new place where age and role must be re-checked by hand.
- **Proposal:** register these as *slots* with an eligibility predicate (role, flag, age band, data present) and a fixed priority, outside the scored list but inside the same pipeline ([11 §3](11-personalization-architecture.md)). No visual change.
- **Confidence:** High.

### AXA-04 · P1 · Age is computed in several places
- **Current:** `ageInMonths` (`adaptive.ts:22`), `monthsOld` (`nutrition.ts:351`), `ageInUnit` / `stageFor` (`content.ts`), Dart `babyAge` (`core/format/age.dart:8-26`), `lbAgeIn` (`library/content_calc.dart`), rhythm `cardAgeDays` with corrected age (D-141). CH-01 (end-of-month mismatch) was fixed by aligning rules, not by sharing code.
- **Impact:** the next rule (corrected age, upper band, time zone) must be changed in five places; drift reappears silently.
- **Proposal:** one shared vector file (JSON fixtures: 29 Feb, 30/31, 91 days, 24 m, 36 m, 72 m, preterm, zone change) run by both Dart and TS tests; keep the functions where they are.
- **Confidence:** Medium (the functions agree today per the 2026-10-21 report; drift is the risk).

### AXA-05 · P1 · Content cliffs with no honest end state
- **Current:** milestones seed max range 36 months; age cards to 24 months (760 days); library filter to 2 years while buckets reach 36 months; nutrition and solids to 36 months; WHO growth to 5 years.
- **Impact:** a parent of a 4-year-old opening Mốc phát triển, Thư viện or Dành cho bé sees empty or stale content without knowing why.
- **Proposal:** a per-content-type `coverage` (from/to months) in the registry, and one shared empty state "Nội dung cho {tuổi} đang được chuẩn bị" with what still works (custom milestone, save a moment). Do not write new developmental content without review.
- **Confidence:** High (coverage); Medium (exact empty rendering per screen, not rendered in this audit).

### AXA-06 · P1 · Newborn wording on cross-age screens
- **Current (en):** `babyPickerTitle` "Choose baby", `babyPickerAdd` "Add baby profile", `meBabies` "Baby profiles", `memberRelation` "Relation to baby", `babyNicknameRequired` "Give your baby a nickname." 282 English strings contain "baby". (vi): "Chọn bé", "Thêm hồ sơ bé", "Hồ sơ các bé", "Là ai với bé". The welcome screen already says "bắt đầu từ năm đầu đời" (`welcomeBody`).
- **Impact:** in Vietnamese "bé" is acceptable for young children but reads young for 8+; in English "baby" is wrong for a 3-year-old.
- **Proposal:** terminology rule in [08](08-content-ux-writing-strategy.md): cross-age surfaces use the child's name or "con" / "child"; care-specific infant surfaces may keep "bé" / "baby". Glossary change = L3 (canonical terms).
- **Confidence:** High.

### AXA-07 · P1 · Memories stop celebrating after the first birthday
- **Current:** keepsake occasions run birth, d7, m1…m11, d100, y1 plus skills (`apps/mobile/lib/features/keepsakes/keepsake_occasions.dart:10-32`); retrospective targets m1/d100/m6/y1 (`docs/product-audit/16-memory-campaigns.md` §72-91).
- **Impact:** the one pillar that stays valuable for years has no recurring moment after year one.
- **Proposal:** [10](10-memories-across-childhood.md): yearly birthday occasions y2…y12, "this time last year", a year-in-review, Then & Now, all on the existing catalogue and renderer. Templates are content work with owner review.
- **Confidence:** High.

### AXA-08 · P2 · Usage signal is per phone
- **Current:** `UsageStore` keeps taps on the device (plan §12). The experience doc is synced.
- **Impact:** a parent with an iPad and a phone sees two different automatic orders. Minor because manual orders win.
- **Proposal:** keep local; optionally sync a coarse per-widget count weekly in the experience doc. Low priority.
- **Confidence:** High.

### AXA-09 · P2 · No upper boundary
- **Current:** `ageBandFor` returns `b6_12` for 72+ months (`adaptive.ts:33-38`); DOB up to 18 years.
- **Impact:** a teenager gets "6–12" copy ("Những ngày đi học…"). Rare in the current audience.
- **Proposal:** keep open-ended but label as "6+" in copy (analytics already says 6+); decide Q-094 before any 12+ content.
- **Confidence:** High.

### AXA-10 · P2 · Stage card is the only transition moment
- **Current:** AX33 at 12/36/72 months, once, suggests a tidier Today.
- **Impact:** good restraint. Missing: an emotional counterpart (a chapter memory) and quietly retiring first-run empty states such as "Ghi lần đầu" for a child who never used care.
- **Proposal:** [06 §5](06-adaptive-today-and-navigation.md) transition model.
- **Confidence:** Medium.

### AXA-11 · P2 · Caregiver/relative variants not designed for older children
- **Current:** caregiver Today = care widgets only (Q-092). For a 7-year-old with a nanny who picks up from school, "care widgets" are mostly empty.
- **Impact:** helper role has little to see past toddlerhood.
- **Proposal:** for 3+ helpers, show Cùng Chăm Con tasks and reminders assigned to them; no new feature. Hypothesis until helpers of older children are observed.
- **Confidence:** Low (hypothesis).

## 4. What this audit did not verify

- Live flag state, real family counts by band, retention by band (needs portal + prod analytics).
- Fresh renders of each screen at 4 / 9 years. This is a documentation-only audit (D-133). The design brief ([13](13-ux-ui-design-brief.md)) asks for fresh goldens at 5 y and 9 y before any UI change.
- Growth chart behaviour beyond 1856 days (code returns `null` from the WHO band; screen behaviour not rendered).
