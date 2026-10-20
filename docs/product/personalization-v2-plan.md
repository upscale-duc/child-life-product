# Personalization v2 — consolidated analysis and plan (updated 2026-10-20)

Owner request (2026-10-19): "phân tích về cá nhân hoá này và bổ sung thêm chức năng cho hữu ích và hay
hơn. mang lại nhiều giá trị cho người dùng hơn."

Sources: the audit of 2026-10-19 (this document §1–2), `premium-personalization-plan.md` (D-072…D-077),
`solids-plan.md` §7 (D-085, D-086), `lumi-plan.md` (D-088, P-167 #10), landing V8 extract
`docs/discovery/figma-extract/36-landing-v8-lumi-and-stages.md` §A.6 ("Một ngày dành riêng cho con", the
owner-approved promise), dev Firestore read on 2026-10-19 (flags, entitlements, content version, counters).

Consolidated with [the 2026-10-20 code review](personalization-review-2026-10-20.md) at the owner's
request. This is the implementation planning reference; the review remains evidence of that audit,
not a second roadmap. The 2026-10-19 dev observations below are historical, not a fresh Firebase read.
The 2026-10-20 review checked workspace code and 49 existing engine/seed tests, not device behavior or
production. Current Lumi read capabilities must not be mistaken for a released Home insight engine.

Proposal **P-172**; owner questions **Q-080 – Q-086**; gap **G-108**. On 2026-10-20 the owner requested
implementation of v2 and the added recommendations. The core implementation is now in the workspace;
see [the implementation/review handoff](../development/personalization-v2-review-2026-10-20.md) and §12
for delivered scope, conditional items and verification. This does not approve new clinical rules or rollout.
Order of precedence: owner decisions → brief invariants → approved design → this plan. Conflicts with
existing rules are called out in §9 before the affected implementation.

## 0. Mục tiêu và phạm vi hợp nhất

**Giúp gia đình bớt phải nhớ, chọn được một việc vừa sức lúc này và bàn giao chăm bé dễ hơn.**
Giữ các nhóm A–F của bản v2, bổ sung G (hoàn cảnh hôm nay), H (bàn giao có trạng thái) và I (độ mới,
phạm vi phản hồi, đo lường). Chất lượng dữ liệu phải đi trước dự báo; người ít ghi nhật ký vẫn nhận giá trị.

| Giá trị cho gia đình                                               | Phần kế hoạch    | Ưu tiên                        |
| ------------------------------------------------------------------ | ---------------- | ------------------------------ |
| Gợi ý còn phù hợp, bỏ qua có tác dụng và nhận đúng bản tin đã chọn | I1–I3, C2/C4, B1 | Đợt 1                          |
| Một việc chính phù hợp thời gian và hoàn cảnh hôm nay              | F1, G1–G2, C3    | Đợt 2                          |
| Nhìn được nhịp riêng của con từ dữ liệu đủ tin cậy                 | A1–A4            | Đợt 2, sau kiểm tra chất lượng |
| Người chăm tiếp hiểu việc cần làm và ai đã nhận                    | H1–H2, F2        | Đợt 3                          |
| Ứng dụng nhớ điều gia đình xác nhận và điều chỉnh sau khi thử      | E1–E3, C1/C4, B2 | Đợt 3                          |

Các đợt là thứ tự phụ thuộc, chưa phải cam kết số tuần. D1 được chuẩn bị song song; D3 có điều kiện riêng.

---

## 1. What personalization is today (as built, dev 2026-10-19)

| Surface                                                          | Input                                                           | Engine                                                                                                | Plan state                               | Status                                                                                                               |
| ---------------------------------------------------------------- | --------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- | ---------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| EN01 / EN02 preferences (`users/{uid}/settings/personalization`) | 6 interests, digest time, quiet hours, "ít kiểu này hơn"        | none (stored)                                                                                         | free, per person                         | built; **digest time drives nothing** (G-108); quiet hours are used (`notifications.ts`, evening prompt)             |
| Home "Dành cho bé hôm nay" small cards                           | interests + fewer                                               | sort liked first, drop "fewer", max 3 (`today_for_baby.dart` `rankForBabyCards`)                      | free                                     | built; sources: milestone windows, current stage, 2 care articles                                                    |
| "Tuần này của {bé}" age card                                     | actual age in days                                              | narrowest published range (`ageCardFor`)                                                              | free                                     | built; 35 cards 0–760 days, all `review: null`                                                                       |
| Check-in → one suggestion → feedback → next open changes         | one observation + answers; interests; feedback memory           | `recommend()`: 3·need + 2·interest + 1·helpful − 2·recent − 4·notSuitable, cooldown 3 d, health first | group A (`personalization.cross_module`) | built; 53 activities; M18 pass on the emulator                                                                       |
| "Từ nhật ký" (DATA_INSIGHT)                                      | sleep minutes over automatic valid days                         | `sleepBaseline` 5–7 of 14 days vs last 3                                                              | `rhythm.advanced`                        | built; the diary-derived insight in this Home/check-in contract, not a statement about all app modules or Lumi reads |
| Handover SU01                                                    | facts + approved content                                        | grounded AI with `aiGate`, template fallback                                                          | `ai.assistance`                          | built; 1 real model run, 4 fallbacks on dev in 7 days                                                                |
| Ăn dặm "Gợi ý cho {bé}"                                          | meal diary, tried foods, symptoms, settings                     | rules S1–S9 on the phone (`solids_suggest.dart`)                                                      | free                                     | built 2026-10-19, not yet on a device                                                                                |
| Country-aware content                                            | `families/{f}.country`                                          | vaccine schedules (D-084), `{emergency}` numbers, VN-only campaigns (D-087)                           | free                                     | built                                                                                                                |
| Lumi care guidance                                               | same `recommend()` + interests + feedback (`assistant-care.ts`) | same engine                                                                                           | `assistant_care`                         | built                                                                                                                |
| Dinh dưỡng rules (D-083)                                         | growth and milk metrics                                         | `nutritionRuleSchema` metric / condition / days                                                       | free                                     | built                                                                                                                |

Dev state: `rhythm`, `personalization`, `ai_assist` on for 2 internal families; region `VN` open; one beta
campaign (`duckie_beta`, every capability, until 2027-01-13); content `rc_20261018_01`; contracts tests for
ranking / entitlements / seed 81 / 81; checklist §21 every row ◐ (no device run). Counters for the module
are all zero because the app emits none of `checkinSaved`, `nextActionShown`, `suggestionStarted`,
`feedbackSaved`, `capabilityGateSeen` (declared in `contracts/src/account.ts`, never called from Dart).

## 2. Why the value is thin (diagnosis)

1. **Limited Home inputs.** This engine keys on six static interests and one self-reported observation;
   its diary insight is sleep vs baseline. Feeding, diaper and growth records do not yet form a unified
   next-action feed. Other modules already interpret some data (for example solids and nutrition), and
   Lumi read work exists; reuse those sources instead of claiming that the whole app lacks interpretation.
2. **Check-in dependency.** The need-based suggestion requires a check-in; other surfaces offer age and
   module content. Validate whether parents can find something useful without another form. More push
   notifications alone do not resolve that dependency.
3. **Content ceiling.** 53 activities: at 13–24 months only 3–5 candidates each for sleep, feeding and
   soothing; with a 3-day cooldown a family that checks in twice a week exhausts a need in a fortnight.
4. **Unkept promises.** EN02's "giờ nhận gợi ý" is asked in onboarding and stored, nothing fires (G-108).
   The landing's "Một ngày dành riêng cho con" promises heart / dismiss on every card and topic hiding; the
   Lumi page promises "Lumi càng hiểu nếp nhà bạn" while Lumi has no memory beyond the conversation (P-155).
5. **A loop without evidence.** AC02 asks "Có ích?" with nothing to anchor the answer, and nobody can see
   whether suggestions are shown, tried or helpful (no events, no portal view).
6. **Six engines, one carousel.** Rhythm, Ăn dặm, Dinh dưỡng rules, milestone windows, library stage and
   keepsake occasions each personalize on their own with their own placement and dismiss semantics; the Home
   carousel (3 cards) is the only merge point and it knows nothing of Ăn dặm, Dinh dưỡng or vaccines due.
7. **Freshness is implicit.** `composeHome` (`firebase/functions/src/rhythm.ts`, latest active query)
   and `ForYouSection` (`rhythm_home.dart`, `showPrimary`) do not show an explicit expiry or current
   eligibility check for a stored recommendation. An old need or changed content can remain relevant
   in storage but unsuitable for today's invitation. This is a code-review risk, not a device reproduction.
8. **Feedback scope is ambiguous.** `feedbackMemory()` aggregates authors per baby, and `not_suitable`
   excludes the activity for that baby. That follows the existing brief, but personal dislike or lack of
   time must not accidentally become a household constraint. Also, `fewer` hides carousel topics while
   `recommend()` only removes their interest bonus: the same control has different effects.
9. **No temporary context.** A lasting interest does not say whether the person has three minutes,
   someone else is caring, or the routine changed today. New optional inputs must change actual selection.

What is **right** and must stay: health first and free; missing ≠ zero; every reason explicable; no comparison
with other babies; no child data in analytics; feedback is free data. The server ranks server-readable
sources, the phone renders and composes device-only sources under the same priority contract (F1).

## 3. Principles for v2

- **Use the log where it is reliable.** Current need and explicit constraints matter; interests break
  ties. Sparse logging still gets useful age content, family-set reminders and short activities.
- **Say "thường" (usually), never "nên" (should).** Patterns from the family's own 7–14 days, labelled as such;
  no schedules, no targets, no verdict words (P-167 #10's rule).
- **At most one optional suggestion notification per person per day**, across babies and modules,
  at the chosen time, only when fresh value exists. Family-set reminders remain a separate category.
- **Every card can be answered** (thử / có ích / không phù hợp / ít kiểu này hơn) and the answer visibly
  changes the next card.
- **One feed, one card contract, one priority order** (brief p.11): health → reminders the family set →
  current need → the baby's rhythm → milestone windows → Moments occasion → age / interest content.
- **Explicit memory, never inferred profiling.** What the app "knows about the family" is a list the family
  wrote and can edit.
- **Match the person's capacity today.** Temporary context expires; it never becomes a personality label.
- **One main action in the beta.** Up to two supporting cards, with time needed, reason, direct action and
  dismiss control; expand only if user research supports it. Existing reminder lists are not truncated.
- **Observe, do not overclaim.** Logged time is not necessarily event time; before/after is not causality;
  opening a card is not trying it; silence is not negative feedback.

## 4. Proposals (P-172)

Sizes are rough engineering complexity labels (S/M/L), not delivery commitments. Re-estimate after data,
permissions and device spikes. Copy below is a Vietnamese draft; English is drafted by engineering (D-012).

### A. "Nhịp của con" — the baby's own routine, from the log

**A1 · Facts builder v2** (server `rhythm-facts.ts` + Dart port for offline) — M.
Extends `sleepFacts` to one `facts` snapshot per baby over automatic valid days (D-073 #1):

| Metric                                                        | From                                 | Baseline / recent (reuse `RhythmRules` windows)      | Change flag                                                                                                                         |
| ------------------------------------------------------------- | ------------------------------------ | ---------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| Sleep total, night longest stretch, nap count, bedtime median | `days/{date}` + sleep records        | 5–7 of 14 days vs last 3                             | `minDeltaMinutes` / `minDeltaShare` (exists)                                                                                        |
| Feeds per day, bottle ml, median interval, night feeds        | feed records (`feedDay`)             | same windows                                         | count ± `feedDelta` (config), ml share, night feeds +1 on ≥ 2 days                                                                  |
| Wet / dirty diapers per day                                   | `diaperDay`                          | only days whose coverage is adequate for this metric | health routing only under a reviewed, age-appropriate rule; a low recorded count is not evidence of a low actual count              |
| Growth: latest measurements                                   | growth records, `who-reference.g.ts` | measurement quality and existing D-083 eligibility   | reuse the approved D-083 rule; any channel-crossing or new threshold is a separate clinical proposal, not an existing approved rule |
| Solids: new foods this week, symptom flags                    | meals (device only, D-085)           | —                                                    | feeds the Ăn dặm cards only; never leaves the phone                                                                                 |

Thresholds live in `config/rhythm` (versioned, portal PN04), not in code; the reviewer sees them (Q-069).
Quality is metric-specific: sleep coverage does not prove feeds or diapers were fully logged. Deduplicate,
handle unresolved overlaps and forgotten timers, distinguish recorded time from occurred time, and carry
`asOf`, sample count, valid-day count and insufficient/stale status. Do not turn missing records into zero.

**A2 · "Nhịp hôm nay" card** (Home, free) — M.
From the last 14 days of the same kind. Five samples is an initial floor, not evidence that a useful
prediction exists; also check coverage, spread, freshness and G1's routine-change flag. Prefer a typical
range over a precise next-event time. Draft: "Trong những ngày có ghi đủ, khoảng cách giữa các lần bú
thường khoảng …" plus the sample/valid-day count and last update. Do not call an arbitrary range a
confidence interval or promise calibrated probabilities before validation.

Footer: "Theo nhật ký 14 ngày của bé, không phải lịch." Night window follows P-167 #10. Caregivers see
only facts allowed by their existing role, not restricted measurements. Hide predictions on a health day,
when routine is marked unusual, when data is stale or quality fails; show useful non-predictive alternatives.

**A3 · More "Từ nhật ký" insights** (`rhythm.advanced`) — M.
Each change flag from A1 becomes one honest card with its numbers ("3 đêm nay bé bú đêm 3 lần, thường 1
lần") and, when published content matches the need, the suggestion follows with `DATA_INSIGHT` as its
reason; otherwise the card ends with "Mỗi bé mỗi khác. Nếu bạn lo, hỏi bác sĩ của bé." Health thresholds
route to HL01 before any card.

**A4 · "Nhắc theo nhịp"** (free) — S.
An explicit action on A2 previews an `afterLast` reminder rule (exists, `reminder-rules.ts`) with an editable
interval from the baby's qualifying history. Only confirmation saves it. Never turn a predicted range into
an alarm automatically; changing or suppressing a prediction does not silently rewrite a family-set rule.

### B. Optional, fresh daily and weekly summaries

**B1 · Daily suggestion at `digestTime`** (free) — S/M. Fixes G-108.
At the explicitly enabled EN02/EN07 time, outside quiet hours, respecting OS permission. Choosing a clock
alone must not silently enable a new channel for existing users (Q-082 remains open). Maximum one
suggestion digest per person/day across babies/modules; skip empty, unchanged, expired or suppressed
content and deduplicate with B2. Keep lock-screen text minimal; revalidate the destination when opened.

Start with the existing local reminder sync, with expiry and cancellation on known updates. A scheduled
local notification cannot promise fresh server facts at delivery when the app has not run. Use generic
wording or skip content that cannot stay valid; if send-time validation is essential, assess server push
with existing permissions, deduplication and delivery constraints. Verify restart, timezone changes,
sign-out, revoked access and multiple devices; local scheduling alone does not solve cross-device duplicates.

**B2 · Weekly letter "Tuần N của {bé}"** (free) — M.
Extend EN09's existing weekly summary with _điều nhiều nhà thấy ở tuần này_ (`ageCard.body`), _một việc
vừa sức để thử_ and applicable `watchFor`, plus what the family actually tried and wants to keep from C1/G2.
Reuse editorial content where eligible; activity history and goal summaries need new composition logic.
Use one weekly entry and notification, not an additional Monday push after Sunday's overlapping summary.

### C. Feedback that is informed, and a loop the family can see

**C1 · "Sau khi thử"** (basic feedback free; diary comparison under `rhythm.advanced`) — M.
After an intention to try, ask at an appropriate time: "Đã thử chưa?" with "Chưa thử" and, only after
confirmation, "Có ích với nhà mình không?" One optional question at a time. Distinguish intention,
confirmed attempt, completion and perceived usefulness. Reuse existing `started` as intention (not a
completed attempt); add compatible outcome fields/events, not a silent reinterpretation of old data.
Sleep first; qualifying facts may accompany feedback, without implying that the activity caused a change.
When facts are sparse, ask without numbers. No answer is not a negative outcome. Basic response and
control remain free; advanced diary comparisons retain their existing capability pending pricing decisions.

**C2 · Heart and × on every "Dành cho bé" card** (free) — S.
The landing's promise: ♥ = "Lưu lại" for every source, including an activity. Saving is not evidence of
usefulness; only C1's explicit answer writes `helpful`. × opens consistent hide/snooze/topic controls on
every source. Define `fewer` consistently as reduced nonessential frequency, not a permanent block in one
surface and just a removed bonus in another. An explicit "Ẩn chủ đề" is separate. Important family-set
reminders and health routing are not silently hidden by content preferences. Undo and restore are visible.

**C3 · Reasons that carry the data** — S.
`rhReason*` lines include the fact when one exists: "Vì đêm qua bé thức 4 lần, thường 2 (từ nhật ký)";
otherwise today's "Vì bạn vừa ghi…". Reason codes unchanged.
Facts also carry their time range and freshness; do not say "đêm qua" for older or incomplete data.

**C4 · Feedback scope and recovery** (free) — M. Depends on Q-084 and I2.
"Hôm nay bận" snoozes for this person/context; "Tôi không thích" changes personal preferences;
"Không phù hợp với bé" is an explicit baby-level exclusion under confirmed permissions. "Đã biết rồi"
reduces repeat educational content without claiming the family tried the activity. Show a confirmation of
what changed and allow recovery. Resolve conflicting authors/updates explicitly; do not silently promote a
personal response into a family constraint. This refines the existing brief's exclusion rule, not an already
approved permission change.

### D. Content depth and content feedback

**D1 · Toddler pack 12–36 months** — L (content, not code).
24–30 activities, including genuinely short options, for the needs that are thin after 12 months: sleep (nap 2 → 1, bedtime routine, night
waking), feeding (picky eating, milk after 1 year, self-feeding), soothing / behaviour (tantrums,
separation anxiety, biting), play / language. Authored as engineering drafts under D-073 #2 with sources
(WHO, AAP, NHS, CDC), `review: null`, stage-linked (stages 8–10), on the publish workflow. Q-083.

**D2 · Portal "Hiệu quả nội dung"** — M.
A nightly job aggregates into `contentStatsDaily/{date}` without uid or baby id. Separate generated
recommendations from actual visible impressions, opened, intention, confirmed attempts and explicit outcomes.
Recommendation documents do not prove a card was shown; `started` does not prove it was tried. Review
privacy before adding any per-content impression event: existing generic counters cannot supply content-level
attribution. Keep a generation/outcome report when privacy-safe impression attribution is unavailable.
PN shows sample size, response rate, not-suitable scope and version; flag issues for editorial review rather
than automatically retiring content at a fixed percentage from a small sample. I3 owns the minimum funnel;
the full portal tab follows after instrumentation works.

**D3 · Corrected age for preterm babies** — S.
Review corrected age specifically for developmental content. This changes the current actual-age contract
and brief, so obtain the domain review and owner decision in Q-086 before coding. The reviewer defines
eligibility, calculation, end point, explanation and override; do not apply it indiscriminately to feeding,
vaccines or clinical routing. Keep actual age and reference-stage age distinct in data. Until resolved,
existing behavior stays; D3 is not an automatic small fix in Phase 1.

### E. "Sổ tay nhà mình" — explicit, editable family memory

**E1 · Notebook** (`babies/{b}/notebook/{nb_<32 hex>}`) — M.
Short notes the family writes about this baby: `kind` (ngủ · dỗ · ăn · tránh · nếp nhà · người chăm ·
khác), `text` ≤ 200 chars, `authorUid`, `source` (`app` | `lumi`), `useForSuggestions` (bool), timestamps,
scope (person/baby), confirmation author/time, optional expiry and revision. Separate family observations,
personal preferences and explicit constraints. A temporary observation must not become permanent memory.
Examples: "Ngủ cần tiếng ồn trắng", "Không hợp bế rung mạnh", "Tắm 19:00, ngủ 20:00", "Bà nội chăm thứ 2–4".
Edited in Tôi › Cá nhân hoá › Sổ tay nhà mình and from a baby's profile. Child data: Rules by role
(Q-081), never analytics, in the care export, purged with the baby.

**E2 · Used by the engine** — S.
Only active, explicitly confirmed baby-level constraints of kind `tránh` carry optional structured tags from
the activity vocabulary; `recommend()` uses them as exclusions under C4's scope and permissions. Free text
alone never becomes a clinical restriction. Routine anchors (`nếp nhà` with a time) set "Thử tối
nay" to the family's bedtime and B1's wording. The reason line names the note: "Vì nhà mình ghi: ngủ cần
tiếng ồn trắng".

**E3 · Used by Lumi** — M.
With the person's `assistant` consent, Lumi's trusted context includes the notes **as data** (the existing
rule: quoted, never instructions), so "con khó ngủ" is answered with the family's own cues first. Lumi may
_propose_ a note from a message ("Nhớ là bé thích ngủ với tiếng ồn trắng" → a draft the person confirms),
never save one by itself (P-169's rule for corrections). This is the honest form of "Lumi càng hiểu nếp
nhà bạn".
The family can inspect "Điều đang dùng để cá nhân hoá", edit/delete according to role, and resolve stale
or conflicting notes. Expired notes do not enter ranking or model context; do not infer personality or emotion.

### F. One "Dành cho bé" feed for every module

**F1 · Card contract and ranked feed** — M.
`ForBabyCard` grows into a feed item: `priority` class (health · reminder · need · rhythm · milestone ·
moments · content), `source` module, `interest`, `facts` (optional numbers), `answers` (which of ♥ / thử /
× it accepts), `openedBy` (route), estimated duration, freshness/eligibility metadata and a deduplication key.
It coordinates eligible outputs; it does not replace each module's domain rules. Sources join the same provider: rhythm suggestion, A2 rhythm card, Ăn dặm
primary suggestion (today a separate Today card), Dinh dưỡng rule tips (D-083), milestone windows, stage /
articles, vaccine due within 7 days, keepsake occasion (MM03, today on Ảnh), look-back. Order per §3; caps:
one primary + up to two small cards for the beta (supersedes the earlier four-card proposal); a dismissed
item never returns the same day for the applicable scope, and a completed action does not return as unstarted.
One event produces one card across modules. Each card gives a reason, time needed, direct action and
response control. G1 filters by available time only when optional editorial duration is meaningful.
Respect current capabilities; do not downgrade a free source because it joins this feed. The Lumi page's
"Gợi ý dành cho bé" chip opens it. Family-set reminder lists remain complete outside the feed cap.

Solids meal interpretation stays on the device (D-085). Server ranks server-readable candidates; a
deterministic device compositor merges the local solids candidate and applies shared priority/dedup rules.
Test both with the same fixtures; never upload meals merely to centralize ranking.

**F2 · Role-aware feed** — S.
A Người chăm sóc sees "Hôm nay với {bé}": A2, the handover (exists), the notebook's "điều cần biết" and the
suggestion when allowed; their own interests still rank the rest. Người thân with daily-care rights: read-only
cards, no ♥ / ×. Night care palette and large text apply as everywhere.

### G. "Hôm nay nhà mình thế nào?" — temporary capacity and a chosen goal

**G1 · Optional context for today** — M.
Quick choices: "Chỉ có vài phút", "Đang bận", "Người khác chăm", "Sinh hoạt khác thường". Person-level
capacity expires at the next local day boundary (named timezone); a shared routine-change flag requires
authorized confirmation and its own expiry. Always allow skip, inspect, change and clear. No long onboarding
form and no inferred labels. Time constraints filter activities by duration; busy mode reduces optional
content and pauses suggestion digests, not family-set reminders. Suppress a rhythm prediction when the
shared routine context invalidates its baseline, not merely because one person is busy.

**G2 · One family-chosen weekly focus** — S/M.
Optional examples: "Bàn giao dễ hơn" or "Có một lúc chơi cùng con". A personal focus is editable by that
person; a shared focus follows existing co-parent authority. It acts as a tie-break after health, reminders,
eligibility and current need, never as a quota or streak. Expires/reviews at the weekly summary (B2), with
"Giữ cho tuần sau" and "Đổi". Ask only when the answer changes actual selection.

### H. "Bàn giao trong 30 giây" — coordination beyond a summary

**H1 · A concise, grounded handover** — M.
Reuse SU01's facts/fallback with last recorded care, upcoming family-set reminders, authorized notebook
notes and an `asOf` timestamp. Changes since creation are visible; it never invents a task from a prediction.
Keep basic factual coordination independent of optional AI wording (free is proposed, not a new grant).
Recipients see only facts allowed by their current role; derived summaries must not reveal restricted growth
or profile data. Explicitly shared notes only; private conversations are not copied into a handover.

**H2 · Acknowledge and track existing care work** — L; Q-085.
Explicit recipient confirmation and a linked work state (unclaimed → accepted → completed; release/reassign
by authorized actors). Store the acting member, timestamps and source reference. A transaction prevents two
people accepting the same item; idempotency prevents repeated completion. Completion of a reminder is not
evidence that a care record exists: keep logging distinct and link only a real record.

Prefer extending existing reminder assignments over a generic new Tasks product. Show offline actions as
pending until acknowledged by the server; handle simultaneous claims, revoked membership and edits/deletes
to the source. Do not automatically assign or message another member from a chat or AI summary. This new
workflow and its permissions remain proposals; no role gains writes until Q-085 is resolved.

### I. Reliability and measurement before expansion

**I1 · Freshness and eligibility on read** — M.
Give actionable suggestions a source event time, expiry and content version; recheck current age, locale,
country, publication, active constraints, health suppression and permissions before presentation. Re-rank
when relevant inputs change, not only after feedback. Keep ongoing/finished activity history distinct from
an invitation to start today. Apply expiry to offline caches and notification payloads; unavailable data
must not resurrect expired content. Switching babies/accounts clears or partitions all derived state.

**I2 · Scope-safe feedback migration** — M; Q-084.
Keep historical `not_suitable` baby-scoped as originally recorded; do not guess the author's past intent.
New personal snoozes/dislikes live per person/baby, shared exclusions under the baby. Add schema versions,
explicit scope and restore behavior; ship compatible contracts/Rules/server before clients. A personal
response must not retire the household's active recommendation for everyone. Recompute each viewer's
presentation with personal preferences while retaining shared care facts and active work.

**I3 · Minimum trustworthy funnel** — S/M.
Wire the five declared app counters, then distinguish visible impression, opened, saved, intention,
confirmed attempt, completion and explicit helpful outcome with fixed, nonidentifying dimensions.
Deduplicate rebuild/retry events. Count notification scheduled/attempted/opened separately; do not call a
scheduled local notification delivered, or a created recommendation shown. Reconcile platform limits and
privacy before reporting cross-device/family rates. No names, baby/member IDs, notes or care payloads in
analytics. D2's richer report follows this foundation.

## 5. Contracts and data

| Where                              | Change                                                                                                                                                                                                                                                                                                                                   |
| ---------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `contracts/src/rhythm.ts`          | Per-metric facts: baseline/recent, quality/status, occurred/recorded time semantics, sample/valid-day count, dispersion/range and `asOf`; extend versioned rules only with reviewed health conditions.                                                                                                                                   |
| `contracts/src/personalization.ts` | `FeedItem` priority/source/answers, duration, dedup key, source time/expiry/version; scoped feedback with restore and schema version; notebook scope/confirmation/expiry/revision; temporary context and optional weekly focus; reason facts include time and quality. Preserve old `started` meaning.                                   |
| Reminder/handover contracts        | After Q-085, source-linked claims, actor/recipient, state/version and idempotent transitions; keep reminder completion distinct from a care record and from a read acknowledgement.                                                                                                                                                      |
| `contracts/src/account.ts`         | Fixed, nonidentifying funnel dimensions from I3; scheduled/attempted/opened are distinct notification events. No child identifiers, free text, facts or notes. Content-level impression attribution needs a separate privacy design.                                                                                                     |
| Firestore                          | `babies/{b}/notebook/*`, server-only facts, shared constraints and agreed handover state; per-person/baby responses and temporary context in an owner-only user namespace; `users/{uid}/saved/{id}` for saved content; `contentStatsDaily/{date}` without member/baby IDs. Final paths/indexes in implementation spec after permissions. |
| Functions                          | I1 read-time validation and viewer-specific presentation, A1 facts, D2 aggregates, H2 transactional transitions. `composeHome` returns only authorized fact projections, never all facts just because a member can see the feed.                                                                                                         |
| App                                | F1 compositor including device-only solids, G1 quick context, E notebook/control views, C1 feedback, H handover, B1 local scheduling with validity limits, B2 one weekly summary entry. Dart ports and server logic share fixtures.                                                                                                      |
| Portal                             | Minimum funnel first; D2 editorial report with denominators/version; PN04 reviewed configuration.                                                                                                                                                                                                                                        |
| Migration/indexes                  | Deploy contracts/Rules/server before clients; preserve historical baby-scoped exclusions and intention records; specify source queries and indexes after choosing aggregation paths. No speculative blanket collection-group reads.                                                                                                      |

Privacy and logging unchanged: facts and notes are child data (Firestore, Rules, export, purge), never in
logs or analytics; counters carry no child ids. Expiry limits use immediately, not merely after a purge job.
Include notes, context, responses and handover data in applicable export/purge; revoked access removes them
from caches, notifications and future model context. Notification copy follows existing disclosure settings
and permissions; do not add care details to the lock screen merely because the feed has them.

## 6. Phases

| Phase                         | Steps                                                                                                                                    | Dependencies / exit evidence                                                                                                                                                                                  |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **1 · Trustworthy basics**    | I1 freshness, I2/C4 scope and migration, I3 minimum funnel, C2 save/hide consistency, B1 enabled digest                                  | Q-082/Q-084 before affected behavior; expiry works on server/cache, restore is correct, event counts distinguish generated/shown/attempted, no duplicate or stale suggestion notification in device cases.    |
| **2 · One useful action now** | F1 minimal shared feed, G1 optional context, G2 optional focus, C3 reasons; A1 quality first, then A2/A4                                 | Phase 1; Q-080 for access. Show useful age/reminder content with sparse logs; prove quality rejection and range suppression; domain review before new health rules. Validate device-local solids composition. |
| **3 · Family continuity**     | H1/H2 and F2 caregiver view first, then E1–E3, C1 explicit attempt/outcome, B2 combined weekly summary, D2 richer portal and A3 insights | Q-085 before claims/role changes, Q-081 before notebook permissions. Demonstrate two-device handover, permission revocation, note expiry/conflicts and compatible outcome reporting.                          |
| **Parallel / conditional**    | D1 content preparation alongside Phase 2; D3 developmental-age change separately                                                         | Q-083 for drafting, existing publish review for release; Q-086 and domain review before D3. Neither blocks basic feed improvements.                                                                           |

The earlier ≈ 2 + 5 + 5 week sizing is superseded by this dependency-based roadmap; re-estimate slices
after quality, notification and multi-caregiver spikes. Full portal analytics do not block the first beta,
but trustworthy minimum measurement does. Existing pricing/capabilities remain until a decision changes
them; proposed free factual coordination (H1) does not automatically make AI generation free.

Each step: contracts vitest, Dart ports with the same fixtures, Rules tests, emulator integration, goldens
Light / Night × vi / en, ARB parity; checklist rows only after a device run on dev (CLAUDE.md). Everything
behind the existing rollout/capability controls (`rhythm`, `personalization` and relevant module controls).
Verify rollback and old-client compatibility before expanding roles or schema. No checklist row becomes done
from this plan or the existing unit-test pass.

### Acceptance scenarios for the combined plan

| Scenario                                            | Required behavior                                                                                             |
| --------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| First day / sparse diary                            | A useful non-predictive card, correct source reason, no invented pattern or zero-filled health inference.     |
| Old need / retired content / changed age or country | Revalidate and replace/hide the invitation; do not resurrect it from offline cache or notification.           |
| Busy caregiver / another author                     | Personal snooze affects that person; shared exclusions require explicit scope and rights; restore is visible. |
| Missing feeds / duplicate records / forgotten timer | Metric-specific quality rejects unsupported conclusions, including false low-count health alerts.             |
| Unusual routine / stale sample                      | Suppress predictions; preserve family-set reminders; explain the unavailable pattern without alarm.           |
| Save / open / intend / try / helpful                | Each remains distinct in data, UI and reports; rebuilding a card does not add impressions.                    |
| Two babies / two devices / changed timezone         | Partition state and expiry correctly; deduplicate opted-in suggestion notices; opening revalidates access.    |
| Concurrent handover claims / offline completion     | One accepted actor; pending is visible; retries are idempotent; no fabricated care record.                    |
| Expired/conflicting note / permission revocation    | Exclude from ranking/model context, resolve conflicts explicitly and remove unauthorized cached projections.  |
| Solids with device-only meal data                   | Shared priority/dedup behavior without exporting meals to the ranking server.                                 |

## 7. How we will know it is useful

Primary outcome: the share of consenting beta families who can identify at least one concrete situation
the app helped with that week. Report participating-family denominator, response count/rate and usage
groups. Validate through voluntary task studies/interviews, not an identifying child analytics stream.

Use aggregate instrumentation only where I3 can measure honestly:

| Question                              | Measure                                                                                                 | Interpretation                                                                                              |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| Can people find a useful next action? | Time and success in a defined task study; specific useful situation reported                            | Compare sparse/frequent loggers and one/multiple caregivers; use consented research for family-level rates. |
| Do suggestions help after trying?     | Visible → intention → confirmed attempt → explicit helpful outcome                                      | Show response rate and sample size; do not label `started` as an attempt or a saved item as helpful.        |
| Is the diary actually usable?         | Quality-pass coverage and unavailable/stale pattern counts                                              | Segment metric/source; do not optimize logging volume or treat every active family as prediction-eligible.  |
| Is the daily moment wanted?           | Scheduled/attempted/opened, switch-offs and reported disturbance                                        | Delivery is not guaranteed; define denominators and device dedup before computing an open rate.             |
| Is the feed noise?                    | Visible impressions vs repeated/stale/wrong-context cards, hide/snooze/fewer                            | Separate intentional personal snooze from baby-level unsuitability.                                         |
| Is content right?                     | Versioned generated/outcome counts, scope and response rate; impressions only if privacy design permits | Flag for review; no automatic removal from a small-sample percentage.                                       |
| Does handover reduce uncertainty?     | Recipient understands current work without asking again; task-study/interview evidence                  | Acknowledging a handover alone is not evidence that care was completed.                                     |

Start with a voluntary two-week Beta A of 20–30 families to find usability issues; this is exploratory,
not proof of long-term efficacy. Establish baseline before setting percentage targets. The earlier 50/30/25
percent targets and automatic prune threshold are withdrawn as decision rules. App visits, time spent and
record volume are diagnostic only. Finalize any privacy-safe family/cohort reporting before claiming it
can be computed from identifier-free counters. Evaluate pricing only after evidence of usefulness.

## 8. Risks

- **Recorded counts are not actual counts.** Quality is metric-specific; a missing diaper/feed record
  cannot trigger a low-count health conclusion. Versioning a threshold does not make it clinically reviewed.
- **Patterns break when routines change.** Five samples alone are insufficient; A2 checks spread,
  coverage, freshness and explicit context. It may show no prediction. Reminder creation requires confirmation.
- **The notebook is sensitive.** Roles per Q-081, export and purge with the baby, never AI without consent,
  quoted as data (injection-safe), no analytics.
- **More cards is more noise.** Caps, one dismiss model, the digest skips when nothing is new.
- **Local scheduling is not live evaluation.** Expiry/cancellation and cross-device dedup need device
  evidence; push delivery also has limits. Do not report scheduled as sent or delivered.
- **Shared effects can override personal intent.** Q-084 defines scope and migration; Q-085 defines
  claim/reassign authority. Old exclusions are not reinterpreted, and restricted facts stay restricted in summaries.
- **Content review remains the prod gate** (Q-069, D-073 #2, D-082). v2 does not change that; D1 adds to the
  reviewer's queue, D2 tells them where to look first.
- **Landing claims.** B1, C2, A4 and E3 make four Q-039 claims true; "Lumi càng hiểu nếp nhà bạn" should be
  reworded to the explicit notebook ("Lumi nhớ những gì nhà bạn ghi lại").

## 9. Owner questions

| Q         | Question                                                                                                                                    | Proposed default                                                                                                                                                                                                                               | Needed by             |
| --------- | ------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------- |
| **Q-080** | Is "Nhịp hôm nay" (A2: a quality-qualified typical range from the baby's own diary) free for every family, or part of group A?              | Free: it is the family's own data and the caregiver's handover; A3's interpretations stay in `rhythm.advanced`                                                                                                                                 | Phase 2               |
| **Q-081** | Sổ tay nhà mình: who may write/confirm notes, is there a free limit, and may Lumi propose a note? How do scope, expiry and conflicts apply? | Proposed Cùng nuôi and Người chăm sóc write within confirmed permissions; Người thân read with daily-care rights; no limit; Lumi proposes, person confirms; expired/conflicting notes do not silently enter ranking                            | Phase 3               |
| **Q-082** | Daily suggestion (B1): explicit opt-in or enable for existing users who selected EN02 time? Remove EN02 if no digest will be shipped?       | Updated proposal: explicit enable control and OS permission; do not migrate a clock value into new consent silently. One suggestion digest/person/day, quiet hours and freshness apply.                                                        | Phase 1               |
| **Q-083** | Toddler content 12–36 months (D1): engineering drafts now under D-073 #2, or wait for the reviewer (Q-069)?                                 | Draft now with sources, `review: null`, including short activities; release through existing review.                                                                                                                                           | Parallel with Phase 2 |
| **Q-084** | Which responses may exclude for the baby, who can set/restore shared exclusions, and may the brief's current exclusion behavior be refined? | Personal snooze/dislike stays personal; baby-level exclusion is explicit. Propose Cùng nuôi manages shared exclusions; caregivers report concerns for confirmation, retaining existing clinical/symptom rules. Preserve historical exclusions. | Phase 1 C4/I2         |
| **Q-085** | May H2 add acceptance/completion/reassignment of care work, under which roles, and is basic factual coordination free?                      | Reuse reminder assignments. Co-parents assign/reassign; authorized assigned caregivers accept/complete their work; relatives read only if permitted. Factual handover proposed free, AI under existing entitlement; no generic Tasks module.   | Phase 3 H1/H2         |
| **Q-086** | May developmental activities/age cards depart from the current actual-age brief, and what corrected-age policy should apply?                | Keep existing behavior pending domain review and owner approval; reviewer specifies calculation/eligibility/end point. Do not extend to feeding, vaccines or health rules automatically.                                                       | Conditional D3        |

These are tracked proposal questions, not a request to approve the whole plan now. Resolve each before
the dependent behavior; independent groundwork and later sizing can proceed without treating silence as approval.

## 10. Not proposed, and why

- Comparing the baby with other babies or with percentile "norms" as a judgement — against the brief and
  harmful; growth stays a chart with a "hỏi bác sĩ" line from the Dinh dưỡng rules.
- Auto-generated daily schedules ("lịch ngủ cho bé") — A2 says what the baby usually does; it never
  prescribes.
- Inferring interests or personality from locale, IP or hidden usage profiles — interests stay explicit,
  feedback stays scoped, and temporary context comes from a person with an expiry.
- Streaks, badges or "you missed a day" — logging is for the baby, not for the app.
- Long-term model memory in the assistant — E is the user-visible, editable form of memory; the model gets
  it as data per message under consent, nothing is stored on the provider (`store: false`, D-003).

## 11. Evidence and maintenance

- 2026-10-19: historical audit/dev snapshot in §1 and the original P-172 analysis; not revalidated against
  live Firebase during the 2026-10-20 consolidation.
- 2026-10-20: [workspace code review](personalization-review-2026-10-20.md), including 49/49 existing
  tests across `rhythm.test.ts` and `rhythm-content-seed.test.ts`. Those audit tests did not validate the later v2 implementation,
  notifications, role changes, Rules or devices. Implementation verification is recorded separately below.
- [Google PAIR: user needs](https://pair.withgoogle.com/chapter/user-needs/),
  [feedback/control](https://pair.withgoogle.com/chapter/feedback-controls/) and
  [explainability](https://pair.withgoogle.com/chapter/explainability-trust/) inform the UX proposals;
  applying those principles here is product reasoning, not user-study evidence for Child Life.

Keep P-172 and Q-080–Q-086 in `business-map.md` aligned with this plan. Record actual owner decisions
as D-xxx and update status/evidence after implementation; do not turn document consolidation into delivery.

## 12. Implementation state — 2026-10-20

The owner explicitly requested implementation after consolidation. Code and a reviewable handoff are
available in [Personalization v2 — implementation and review](../development/personalization-v2-review-2026-10-20.md).
That file maps A–I to actual behavior, APIs, storage, authority, automated checks and remaining work.
The proposal sections above preserve the intended roadmap and must not be read as an all-delivered checklist.

Implemented core: fresh/eligible recommendations and scoped controls; daily context and personal weekly
focus; recorded diary ranges with explicit reminder preview; role-aware composed Home; confirmed notebook
and Lumi draft shortcut; factual handover and transactional existing reminder work; after-try outcomes;
existing weekly-summary extension; explicit same-day digest with cross-install reservation; anonymous
portal metrics and 24 bilingual toddler drafts available for editorial import.

A1/A3's additional clinical interpretation and D3 corrected developmental age remain conditional. Expanded
offline facts parity and shared household goals are not part of the implemented core. The toddler pack is
draft content pending review, not published. Automated checks passed as listed in the handoff; no deployment,
physical-device notification verification or Figma checklist completion is claimed.
