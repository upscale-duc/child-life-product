# 05 · Onboarding audit

## 1. Current flows (fact)

| Path | Steps | When | Code |
|---|---|---|---|
| **Flag off** (what real families get by default, AXA-01) | Welcome → sign-in → 10a (role/name) → 11 baby (name, DOB up to 18 y, sex, zone, photo) → 12 trackers → Hôm nay → EN01 "Hôm nay theo cách của nhà bạn" (interests) | Always unless the public flag is `enabled` + `all` | `apps/mobile/lib/features/onboarding/setup_screens.dart`, `welcome_screens.dart`, `today/today_personalize.dart` |
| **Adaptive, first child** | … → 11 with live age ("Na được 4 tuổi") and, from 12 m, "Mọi tính năng … đều dùng được cho {tên}" → goals (band presets pre-ticked, "Bỏ qua") → 12 trackers only if `track_care` → AX06 preview (ranked Today, drag) → Hôm nay | Public flag `enabled` + `scope == 'all'` only | `adaptive_setup.dart:39-57`, `SetupGoalsScreen`, `SetupPreviewScreen` |
| **Adaptive, adding a child** | Same as above | Family has `adaptive_experience` | `setupAdaptiveProvider` → `adaptiveOnProvider` |
| **Join by invite** | Code/link → role-scoped app; no baby creation, no goals (caregiver) | Always | `features/family/join_screens.dart` |
| **Late joiner photos** | Tự lưu intro on Kỷ niệm; retrospective shelf (flag) | After setup | `engagement_widgets.dart:131-141` |

Welcome copy frames the product as first-year: "Chăm sóc, thấu hiểu và lưu giữ hành trình của con — bắt đầu từ năm đầu đời." and the CTA "Bắt đầu chặng đầu cùng con" (`app_vi.arb` `welcomeBody`, `welcomeExplore`).

## 2. Friction analysis

| # | Issue | Severity | Evidence | Who it hurts |
|---|---|---|---|---|
| O-1 | Older first child gets the tracker step with bú bình/bú mẹ/ngủ/tã defaults | High | AXA-01 | Every 1+ first-time family |
| O-2 | Two preference asks: goals (adaptive) and EN01 interests after setup | High | AXA-02 | Every adaptive family |
| O-3 | Welcome says "năm đầu đời" / "chặng đầu" | Medium | `welcomeBody`, `welcomeExplore` | Parents of 1+ children deciding whether to continue |
| O-4 | Preview (AX06) asks to drag before the person has seen anything | Low | Plan §2.2 flow 1 | Everyone; mitigated by "Vào Hôm nay" |
| O-5 | No offer to bring past photos in at the moment it matters most (end of setup) for an older child | Medium | Tự lưu lives on Kỷ niệm, not in setup | Late joiners |
| O-6 | `createBabyRequest` needs ≥ 1 tracker, so 3+ children get "Tăng trưởng" as a hidden tracker | Low | D-097 Q-088 | Data model wrinkle, invisible to users |
| O-7 | Notification permission at launch (D-098) before any value for an older child | Medium (hypothesis) | D-098 | 3+ families with no care reminders |

## 3. Minimum inputs (proposal; current required/optional state of each field on 11 was not re-verified)

| Input | Need | Why | When |
|---|---|---|---|
| Child's name or nickname | **Required** | Personal Today, pushes name the child (D-094) | Setup |
| Date of birth | **Required** (explicit "chưa sinh"/due date for pregnancy is out of scope) | Age band, vaccines, growth | Setup |
| Time zone | Default to device | Correct day boundaries | Setup, prefilled |
| Sex | Optional at setup; asked when growth percentiles need it | WHO bands need it; nothing else | Contextual (Tăng trưởng) |
| Photo | Optional | Living Header | Setup or later |
| Your role / relation | Required (one tap) | Permissions, wording | Setup |
| Goals | Optional, presets pre-ticked, "Bỏ qua" | Today order | Setup (one screen) |
| Trackers | Only with `track_care` | Ghi nhanh | Setup, conditional |
| Due date (preterm) | Optional | Corrected age (D-141) | Contextual (Tuần này) |
| Country for vaccines | Inferred from locale, confirm in Tiêm chủng | Schedule | Contextual |
| Interests (EN01) | **Retire as a separate ask** (AXA-02) | Overlaps goals | Derived |

## 4. Recommended universal flow (proposal)

```
Welcome (age-neutral copy) → Sign in → You (role, name)
→ Child (name, DOB with live age, photo optional)          ← universal
→ Goals (band presets pre-ticked, Bỏ qua)                 ← adapts by band
→ [Trackers]  only if "Theo dõi bú, ngủ, tã" is ticked    ← conditional
→ [Bring the past in] only if the child is ≥ 3 months     ← conditional, skippable
→ Hôm nay (first-run state for the band)
```

- **Drop AX06 preview from the default path**, or make it a "Xem trước" link on the goals screen. Today itself is the preview, and Tuỳ chỉnh is one tap away. *(L2: changes a step, not a decision. Keep AX06 if the owner sees value in it; record as Q-AXA-3.)*
- **"Bring the past in"** is one screen: "Ảnh của {tên} từ trước đến nay đang ở trong máy? Child Life có thể tìm giúp" → Tự lưu (iOS) or pick by year; "Để sau". No upload starts without review (D-123).
- **Notifications:** for bands 3+ without care trackers, ask after the first reminder is created (the D-077 pattern), not at launch. *(L3: changes D-098.)*

## 5. Age-aware variations

| Child at setup | Goals pre-ticked | Trackers step | Past-photos step | First Today leads with |
|---|---|---|---|---|
| Newborn (0–4 w) | Theo dõi bú ngủ tã, Kỷ niệm | Yes (4 trackers) | No | "Ghi hoạt động đầu tiên" + first moment |
| 8 months | Same | Yes | Yes ("từ lúc sinh") | Ghi nhanh, Dành cho bé, Kỷ niệm |
| 2 years | Kỷ niệm, Tăng trưởng & tiêm chủng | Only if ticked (ngủ, tã) | Yes | Kỷ niệm gần đây, Tiêm chủng state |
| 5 years | Kỷ niệm, Chi tiêu, Cả nhà | No | Yes ("từ những năm trước") | Lưu khoảnh khắc hôm nay, Tạo từ kỷ niệm |
| 10 years | Kỷ niệm, Nhắc nhở, Chi tiêu | No | Yes | Kỷ niệm, nhật ký, Nhắc nhở |

Universal: name, DOB, role, goals screen (same component), the same Hôm nay. Adaptive: presets, conditional steps, first-run copy.

## 6. Progressive profiling

| Information | Collect | Trigger |
|---|---|---|
| Name, DOB, role | Immediately | Setup |
| Goals | Immediately, optional | Setup; editable in Hồ sơ › bé › mục tiêu & Hôm nay |
| Sex | Contextually | First growth measurement |
| Due date | Contextually | "Bé sinh non?" on Tuần này for < 24 m |
| Vaccine country / given doses | Contextually | First open of Tiêm chủng ("{tên} đã tiêm những mũi nào?" exists) |
| Trackers | Contextually | First tap on a log from Khám phá |
| Usage interest | Inferred | Taps (local usage signal) |
| Changing interests | Suggested, never assumed | Stage card at 12/36/72 m |
| Other caregivers | Contextually | After first value action, never forced (AX40–AX44) |

## 7. Families joining with an older child

- **Never say "late".** Copy talks about "từ trước đến nay" / "so far", not "you missed".
- **Backfill without labour:** Tự lưu past-years pass; occasion keepsakes for past birthdays from dated photos (retrospective shelf extended to y2…y6, [10](10-memories-across-childhood.md)); past milestones as custom "lần đầu" with a date in the past (already supported by custom milestones).
- **Records:** vaccine book setup asks which doses were given (exists); growth accepts past measurements with dates (verify UI).
- **No outdated pushes** for windows already passed (confirmed V1 rule, `16-memory-campaigns.md`).

## 8. Acceptance criteria for an onboarding change

- A first child of 0 m, 8 m, 2 y, 5 y, 10 y completes setup in ≤ 6 taps after DOB when goals are skipped.
- No screen in the 3+ path mentions bú, tã or "năm đầu đời".
- One preference ask per child, not two.
- vi/en × Light/Night goldens for each band path; analytics `adaptive_goals_set` by `stageBand`.
