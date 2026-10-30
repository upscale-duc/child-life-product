# 01 · Executive summary

## Tóm tắt cho chủ sản phẩm

Child Life **không còn là một app sơ sinh về mặt kiến trúc**: hồ sơ bé tới 18 tuổi, engine Adaptive (độ tuổi × mục tiêu → thứ tự Hôm nay), tab Khám phá/Hồ sơ, thẻ chuyển chặng 12/36/72 tháng đều đã có code và test. Vấn đề là **gia đình thật chưa thấy được điều đó**: hai cờ `adaptive_experience` và `adaptive_nav` mặc định tắt (internal), và luồng thêm bé đầu tiên chỉ hỏi mục tiêu khi cờ bật cho *tất cả*. Một gia đình mới với bé 5 tuổi vẫn đi luồng sơ sinh và mở Hôm nay ra thấy bú/ngủ/tã.

Ba việc giá trị nhất, không cần xây tính năng mới:
1. **Quyết định rollout** Adaptive (L3): bật cho người dùng thật, đo theo băng tuổi.
2. **Gom hai bộ câu hỏi cá nhân hoá** (EN01 "điều bạn quan tâm" và AX "mục tiêu") thành một, và cho mọi khối cố định trên Hôm nay đi qua cùng một lớp "đủ điều kiện".
3. **Từ ngữ theo tuổi**: các màn dùng chung (Chọn bé, Thêm hồ sơ bé, Relation to baby…) đổi sang cách gọi dùng được cho mọi tuổi; thêm nội dung Kỷ niệm sau 1 tuổi (dịp, gợi ý, nhìn lại năm).

Không nên xây Chapter 02–04 lúc này. Kỷ niệm là thứ giữ gia đình ở lại khi họ ngừng ghi bú/ngủ: hãy đầu tư vào "nhìn lại" (năm, sinh nhật, Then & Now) trên hạ tầng đã có.

---

## Maturity

| Area | Maturity | One-line evidence |
|---|---|---|
| Data model beyond infancy | **High** | `maxBabyAgeYears = 18` (`packages/contracts/src/baby.ts:45`); history is keyed by `babyId` and never reset at a birthday |
| Adaptive engine (age band × goals → Today order) | **High, but dark** | `packages/contracts/src/adaptive.ts` mirrored in `apps/mobile/lib/features/adaptive/adaptive_engine.dart`; flags `off('internal')` (`packages/contracts/src/config.ts:131-132`) |
| Stable navigation for every age | **High, but dark** | NavBar v2 Hôm nay · Kỷ niệm · Khám phá · Hồ sơ, Khám phá merged with Chăm sóc (D-139) |
| Age-relevant content after 12 months | **Low–Medium** | Milestones and stage content stop at 36 months, weekly age cards at 24 months, library filter at 2 years, keepsake occasions at 1 year (§02 inventory) |
| Age-neutral wording | **Low** | Cross-age screens say "baby" in English (`babyPickerTitle` "Choose baby", `meBabies` "Baby profiles", `memberRelation` "Relation to baby") |
| Memories as the cross-age anchor | **Medium** | Upload, albums, stories, videos, cards work at any age; prompts, occasions and campaigns are first-year |
| Lumi age awareness | **Medium** | Band-specific example questions with the flag on (plan §12); reads are module-based, health routing exists; no explicit age-scope statement in its context |

## Top findings (details in [02](02-current-product-audit.md))

| ID | Priority | Finding | Confidence |
|---|---|---|---|
| AXA-01 | **P0** | The whole cross-age experience is dark. New families with an older first child get the newborn onboarding and the newborn Today | High (code defaults); rollout state not read |
| AXA-02 | **P0** | Two preference questionnaires overlap: EN01 *interests* (per person, all children) and AX *goals* (per person × child). Both can be asked on the same Today | High |
| AXA-03 | P1 | Ranking only governs part of Today: the living header, Tự lưu banner, Cùng Chăm Con tasks, the EN01 invite and the stage card are fixed blocks outside the registry | High |
| AXA-04 | P1 | Five different age calculations exist (`ageInMonths`, `monthsOld`, `ageInUnit`, `babyAge`, rhythm `cardAgeDays`), each correct for its case but with no shared vectors | Medium |
| AXA-05 | P1 | Content coverage cliffs at 24 / 36 months with no honest "nothing more here yet" for older children in Dành cho bé, Mốc phát triển, Thư viện | High |
| AXA-06 | P1 | Newborn wording on cross-age screens (English "baby", Vietnamese "bé" in profile and family screens) | High |
| AXA-07 | P1 | Memory prompts, occasions and campaigns end at the first birthday; no yearly look-back or birthday chapter | High |
| AXA-08 | P2 | The usage signal lives on one phone only, so the same person sees different orders on two devices | High |
| AXA-09 | P2 | The 6–12 band is open-ended; a 14-year-old is "6–12" (Q-094) | High |

## Recommendation in one paragraph

Do **Option C**: keep the stable navigation for every age, and personalise content and priority only ([06](06-adaptive-today-and-navigation.md)). It is already built. Close the rollout gap, unify the preference model and the Today eligibility layer, fix wording, and add age-aware *empty states* rather than age-specific features. Invest strategically in **Memories look-back** (yearly retrospective, birthdays, Then & Now from existing media), because it is the only pillar whose value grows with every year of use. Defer all CH02–CH04-specific capabilities (school, learning, activities, child-facing features) until baseline usage by band shows where families with older children stay or leave.

## The 15 strategic questions

1. **Newborn-centric or cross-age?** The *architecture* is cross-age: an 18-year profile, age bands, a feature registry, per-child experience docs, and a nav that never changes. The *content and copy* are newborn-centric. It can evolve without a redesign.
2. **Features with value beyond year one:** Kỷ niệm (upload, albums, stories, video, cards, print), Gia đình (roles, invites), Nhắc nhở, Chi tiêu, Tiêm chủng (schedule to 72 months), Tăng trưởng (WHO to 5 years), Sơ cứu (child CPR), Lumi, Bàn giao/Cùng Chăm Con with a helper, Chuẩn bị đi khám.
3. **Evolve rather than replace:** Ghi nhanh (from feeds to sleep/potty/custom), Mốc phát triển (from motor milestones to "lần đầu" and achievements), Tăng trưởng (from WHO 0–5 to growth-reference 5–19 with a calmer display), Kỷ niệm occasions (from monthly to yearly), Lumi (from logging to recall and planning).
4. **Onboarding for an older child:** same universal steps, then one goal step with band presets, no tracker step unless care tracking is chosen, then one "bring the past in" offer (Tự lưu or pick photos by year). Never imply they are late ([05](05-onboarding-audit.md)).
5. **What drives Today?** Explicit choices first (pins, hides, manual order), then goals, then age; behaviour only breaks ties and never reorders a manual layout. That matches P-176.
6. **How much personalization?** Until a parent can predict where something is. The rule: anything the person placed stays; the app may *suggest* changes (stage card) but never moves or hides by itself; at most one automatic re-rank per app run (already frozen per run).
7. **Navigation consistent?** Yes. Hôm nay · Kỷ niệm · Khám phá · Hồ sơ for every age; roles, not ages, change the tabs.
8. **Memories for retention:** a yearly look-back and birthday chapter, "this time last year", Then & Now from existing photos, and family sharing to relatives, all from media families already store ([10](10-memories-across-childhood.md)).
9. **Lumi as the child grows:** from "log for me" to "remember for me" (find a moment, summarise a year, prepare a doctor visit, plan the week), always grounded in records, with an explicit age scope for any developmental statement ([09](09-lumi-insights-strategy.md)).
10. **Chapter transitions:** a suggestion card once per milestone (12/36/72 months, built), "Áp dụng / Giữ như cũ", nothing hidden by itself, undo in Tuỳ chỉnh. Add: retire the 0–1 empty states quietly and add a new-chapter memory moment.
11. **Highest-value without new features:** roll out Adaptive; one preference model; age-neutral wording; honest empty states past content coverage; Kỷ niệm first for 1+ when there is no tracker; yearly occasions in the existing keepsake catalogue.
12. **Foundations now:** one `ChildContext` (age, band, coverage, role, flags), one eligibility layer for every Today block, shared age vectors across Dart and TS, a `coverage` field per content type, server-synced usage (aggregated), and an upper band boundary.
13. **Do NOT build yet:** school/homework, learning plans, child-facing accounts, chores or rewards, screen-time tools, social features, gamification, AI-decided layouts, separate visual themes by age.
14. **Validate before scaling:** dogfood with internal families by band, then a measured rollout ([12 §5](12-prioritized-roadmap.md)): D7/D30 by band, first value action within 24 h, pin/hide/restore rates, stage-card answers, "Báo tôi khi có" terms, plus five short interviews per band.
15. **Minimum viable cross-age experience:** a family adds a 5-year-old and, within one minute, lands on a Today that leads with a memory action, shows reminders and spending, offers to bring older photos in, and never mentions feeds. The rest of the app is reachable through Khám phá. Almost all of it exists behind the flags.
