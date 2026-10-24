# Adaptive Experience: review and plan (2026-10-24)

Sources:
- Figma section **"Adaptive Experience"** `930:11858` (AX00 – AX45, NavBar v2 · Adaptive `917:3012`), extracted in `docs/discovery/figma-extract/40-adaptive-experience.md` with screenshots in `img/ax/`.
- The owner's strategy conversation, summarised in `docs/discovery/adaptive-experience-chat.md`.

Where the two disagree, **Figma wins**, because it is V1 scope (CLAUDE.md).

Status: phases A–E are in the workspace (§8–§12), uncommitted, dark behind `adaptive_experience` / `adaptive_nav`; nothing is deployed and nothing has been tried on a phone. Owner decisions: D-097. Engineering proposals P-175 … P-178, questions Q-087 … Q-094 and the design gap note G-110 are in the business map.

---

## 1. The product problem (PM / PO view)

Child Life is built for the first year, but nothing stops a family adding a 4-year-old or a 9-year-old. Several modules already work for any age: Kỷ niệm, Video & thiệp, Chi tiêu, Nhắc nhở, Gia đình, Tăng trưởng, Tiêm chủng, Sơ cứu, Lumi.

Today the whole experience assumes a newborn. Three things show it:
- Hôm nay opens on bú/ngủ/tã tiles.
- The dock is Hôm nay · Kỷ niệm · Chăm sóc · Tiện ích.
- Content stops at 36 months.

A parent of a 4-year-old lands on a feeding tracker and concludes "not for me", even though most of what they would value is already built.

**Goal:** a parent of a child of any age reaches *useful, honest* value on the first day, and the app grows with the child without a redesign at every new chapter.

**Non-goals for V1:** new age-specific features (toddler activities, learning, goals and projects), AI deciding the layout, and four separate Home screens.

### 1.1 Who it serves

| Segment | What they need on day 1 | What V1 already has |
|---|---|---|
| 0–1 (Teddy) | Log care in one tap; reminders; first memories; growth | Everything (the current app) |
| 1–3 (Bơ) | Memories first; light sleep/diaper logging; vaccine boosters, growth | Kỷ niệm, quick log, reminders, vaccines, growth |
| 3–6 (Na) | Memories, video/cards, spending (childcare and school), family sharing | Kỷ niệm, Kỷ niệm 2.0, Chi tiêu, Gia đình, reminders |
| 6–12 (Bin) | Journal and memories, school reminders, spending, growth | The same, with diary framing |
| Several children of different ages | Each child "feels right"; quick switching | Switcher (per-baby data, max 3) |
| Caregiver (Người chăm bé) | Care tools only | Hôm nay · Khám phá · Hồ sơ |
| Relative (Người thân) | Shared memories only | Kỷ niệm · Hồ sơ |

### 1.2 Value proposition and principles

These are settled by AX00 and shared with the conversation:
1. **No feature is locked by age.** Age and goals only order suggestions and set the "Gợi ý cho …" labels.
2. **Personalise what exists, never pretend.** Future chapters appear only as the dashed "Cùng con lớn lên · Đang phát triển · chưa có trong app" card and in an honest no-result search (AX45).
3. **The family stays in control.** Pin, hide, reorder and restore. Pinned items never move. Hidden items never come back by themselves. Every suggestion says why ("Vì: …", "Theo mục tiêu …").
4. **Growing up never takes anything away.** At 12, 36 and 72 months the app *suggests* a tidier Today once, and history always stays.
5. **One child, one context.** Goals and the Today layout are stored per child, and switching child shows the new child's world.

### 1.3 Success measures

These come from the conversation, mapped onto the existing MET-01 product analytics. Event names are closed (P-163), so new events need a contract change (§5.8):
- Onboarding completion by age band, and the goal-step skip rate.
- **First value action** within 24 h: first log, first moment, first expense, first reminder or first invite, by band.
- D7 and D30 retention by age band. The key question is whether families with children over 1 stay.
- Today widget engagement: taps per widget per band, plus pin, hide and restore rates.
- "Báo tôi khi có" interest by band and by search term. This is the roadmap signal for chapters 2–4.

No child name, date of birth, photo or caption is ever included, only the band (CLAUDE.md security).

---

## 2. UX analysis

### 2.1 Information architecture (NavBar v2 · Adaptive)

| Role | Tabs | Lumi | FAB "+" |
|---|---|---|---|
| Cùng nuôi (parent) | Hôm nay · Kỷ niệm · Khám phá · Hồ sơ | yes | Hôm nay, Kỷ niệm |
| Người chăm bé | Hôm nay · Khám phá · Hồ sơ | per D-072 | Hôm nay |
| Người thân | Kỷ niệm · Hồ sơ | no | no |

- **Khám phá** replaces *both* Chăm sóc and Tiện ích (and the R1–R5 proposal in `21-care-utilities-tabs.md`). It is the full V1 catalogue, regrouped and re-subtitled per age, with a "Gợi ý cho {tên} lúc này" group on top.
- **Hồ sơ** replaces "Tôi", which is currently opened from the header avatar. The avatar leaves the header and the child switcher pill takes its place.

The key architectural point is that **new chapters add rows to Khám phá and widgets to Hôm nay; the tab bar never changes again.**

### 2.2 Flows

1. **Add a child (any age)**, AX01 → AX03/AX04 → [AX05 if the "Theo dõi bú, ngủ, tã" goal is chosen] → AX06 → Hôm nay.
   - Live age helper ("Na được 4 tuổi 7 tháng").
   - Beyond the first year, an info card says "Mọi tính năng … đều dùng được cho Na".
   - Goals are pre-selected by age with a "Gợi ý cho 4 tuổi" badge, multi-select, and "Bỏ qua" is allowed.
   - The preview ranks Today with reasons and can be reordered.
   - The step count is **computed from the chosen goals**, not from age (fixes the AX01 "1/4" vs AX02 "1/3" mismatch).
2. **Hôm nay by age** (AX10–AX13), with a greeting and sub-line per band, widgets in ranked order, and "Tuỳ chỉnh Hôm nay" at the end.
3. **Tuỳ chỉnh Hôm nay** (AX14): goal chips with "Sửa", then "Đang hiện" and "Đã ẩn" lists. Each row has a drag handle, a pin and a switch, plus a reason subtitle. It ends with "Khôi phục gợi ý theo tuổi của {tên}".
4. **Switch child** (AX30 → AX31 / AX32):
   - The sheet lists managed children youngest first, then a "Bạn được mời vào" group, each with the viewer's role.
   - Switching clears the old child's content immediately and shows a skeleton plus the toast "Đang xem Na · 4 tuổi", with a 200 ms crossfade.
   - The current tab is kept when the role allows it; otherwise it falls back (relative → Kỷ niệm).
5. **Stage transition** (AX33): a card appears once at 12, 36 and 72 months with pre-checked options and "Áp dụng" / "Giữ như cũ". It never auto-hides anything, and the change can be undone in Tuỳ chỉnh.
6. **Khám phá** (AX20, AX21, AX45):
   - Search with age-ordered examples.
   - "Gợi ý cho …" on top, then the catalogue.
   - The "Cùng con lớn lên" card with "Báo tôi khi có".
   - An honest empty search that offers a V1 route instead ("Lưu vào Kỷ niệm").
7. **Hồ sơ** (AX34): the person, Các bé ("mục tiêu & Hôm nay" per child), Gia đình, Cài đặt.
8. **First run** (AX40–AX44): the first log or first moment comes first and there is no forced invite. Notification permission is asked after the first reminder. From 1–3 up, a "Tìm lại ảnh … · Beta miễn phí" card appears. Kỷ niệm says "Mặc định chỉ ba mẹ thấy".

### 2.3 UX issues found, with the recommended resolution

The full list is in the extraction (§ Open questions, 30 items). The ones that change behaviour are below; each has a business-map id.

| # | Issue | Recommendation (engineering default until the owner decides) |
|---|---|---|
| 1 | The drawn Todays disagree with one another. AX10, AX11, AX12, AX13 and AX14 follow the AX00 "thứ tự mặc định" row. AX06 (Na, the same preset goals as AX12) puts Cả nhà 4th and Nhắc nhở 5th. Read literally ("goal = serves a chosen goal"), the AX00 weights reproduce AX06 only | Keep the weights, but score the **goal term relative to the age preset** (§4.4): +1 for a goal the person added, −1 for a preset goal they removed. With the presets, Today is exactly the AX00 default (5 of 6 frames); AX06 is treated as the outlier (Q-087) |
| 2 | AX41 shows quick log for a 1–3 child without the care goal, but its own note says quick log only appears after "Chọn theo dõi" | **The quick-log widget follows the child's trackers.** At add-child, the default trackers come from the band (0–1: bú bình, bú mẹ, ngủ, tã; 1–3: ngủ, tã; 3+: none). AX05 edits them when the care goal is on. This satisfies both AX11 ("Ngủ, tã (gợi ý)") and the AX41 note (Q-088) |
| 3 | "Ẩn theo gợi ý tuổi" (AX14) could read as an auto-hide | It means **hidden by default when the layout was created**, never hidden later. The engine freezes defaults at the band that was applied (§4.4) |
| 4 | Goals and layout "per child": per person or shared? P-061 kept the layout per device | **Per person × child, synced** (`users/{uid}/experience/{babyId}`). The goal ("what do *you* want help with") is personal, and Mẹ and Ba may differ. Moving off the device makes Hồ sơ › "mục tiêu & Hôm nay" work on every phone. This supersedes P-061 for Today only (P-175, Q-089) |
| 5 | Hồ sơ lacks Gói/Premium, Góp ý, version, language, Night care schedule and sign-out | Keep AX34's four groups and add a fifth group, "Ứng dụng", holding every current "Tôi" row that AX34 does not show. Nothing is removed (Q-090, G-110) |
| 6 | No Night care twin anywhere, and the "Đêm" pill only appears on 0–1 | Night care keeps working for every age (tokens already exist); the pill shows when the child has a care tracker on, not by age (Q-091) |
| 7 | No time-zone field on AX02 | Default to the device zone, as today; the field shows on every add-child (AX01 layout) |
| 8 | Caregiver Today and Khám phá are not drawn | Caregivers see the parent-owned trackers and care widgets only; no goals step (they do not create babies); Tuỳ chỉnh is allowed (their own layout). Khám phá shows care, safety and Lumi rows the role can open (Q-092) |
| 9 | Beta limit of 3 managed profiles | Already the add-baby limit in the switcher; record it in `config/limits` (Q-093) |
| 10 | "Báo tôi khi có" has no confirmation state | Record interest (analytics), then turn the button into "Đã ghi nhận · sẽ báo trong app" plus a toast. No push or e-mail without separate consent (G-110) |
| 11 | Past 12 years | The 6–12 band is open-ended ("6+") until a chapter 4/5 decision (Q-094) |
| 12 | Who may change the trackers (AX05, "Tuỳ chỉnh theo dõi · theo từng bé")? | Unchanged: Cùng nuôi only, as today (baby trackers are a family fact) |

---

## 3. What already exists (current-state map)

- **Dock:** `ClTab {today, memories, care, utilities}`, `tabsForRole()` (`apps/mobile/lib/core/widgets/cl_navigation.dart:21-41`). The shell is in `features/home/home_shell.dart`, and the go_router `StatefulShellRoute` is in `app/router.dart:246-626`.
- **Today:** `TodaySection` and `TodayLayout` (`features/today/today_layout.dart`).
  - Section order is static and there is no pin.
  - The layout is stored per device per baby in SharedPreferences (`today.layout.<babyId>`).
  - The customise sheet is `showTodayCustomizeSheet`.
- **Age:** `babyAge()` (`core/format/age.dart`) and content stages up to 36 months (`packages/contracts/src/content.ts`). There are no 0–1 / 1–3 / 3–6 / 6–12 bands.
- **Child:** `Baby.trackers` and `Baby.timeZone`; the date of birth is in `babies/{id}/restricted/profile`. The active child is `selectedBabyIdProvider` (SharedPreferences), and everything downstream is keyed by `family(babyId)`.
- **Onboarding:** 10a → 11 → 12 (trackers). The date-of-birth picker goes back 18 years. There is no goal step. The closest thing is EN01 interests, which are per person and only shown under `rhythm`.
- **Deep links that hard-code tab paths:** notification destinations (`packages/contracts/src/notification-platform.ts`, mirrored in `notification_destinations.dart`), Lumi read links (`firebase/functions/src/assistant-reads.ts`), engagement ENG-04, the glance bridge, and rule notifications.
- **Highest ids before this plan:** D-096, R-200, P-174, Q-086, G-109.

---

## 4. Solution architecture

### 4.1 Layers

The conversation's model is kept, sized to what V1 needs:

```
Flutter UI      Hôm nay · Kỷ niệm · Khám phá · Hồ sơ · Lumi
                       │  (renders widgets by id; knows nothing about age)
Experience      ageBand(dob, tz, today) · goals · rankToday() · catalogue sections
engine          pure functions in packages/contracts/src/adaptive.ts, mirrored in
                apps/mobile/lib/features/adaptive/adaptive_engine.dart (same fixtures)
                       │
Feature         static registry: id, module, status (released | beta | planned),
registry        age relevance per band, goals served, route, flag/capability/role gate
                       │  availability = status ∧ flag ∧ role ∧ capability (runtime)
Domain modules  care · memories · spending · reminders · growth · vaccines · family · Lumi
                       │
Firebase        users/{uid}/experience/{babyId} (layout, goals) · babies/{id}.trackers
                config/flags (adaptive_experience, adaptive_nav)
```

- **The registry is code**, versioned with the binary. Remote config only switches what the binary already contains (conversation §8.1).
- **Eligibility vs availability:** a widget is *eligible* when its age band and goals fit. It is *available* only when its feature is released, the flag is on, the viewer's role allows it and the capability is granted. Only available widgets are ranked.
- **The chapter is product metadata, never a field on the child.** The band is always derived from the date of birth.

### 4.2 Age resolver

- `ageInMonths(dob, todayInChildZone)` counts calendar months in the child's `timeZone` (falling back to the device zone).
- `ageBand`:
  - `b0_1`: under 12 months
  - `b1_3`: 12–35 months
  - `b3_6`: 36–71 months
  - `b6_12`: 72 months and over; open-ended for now (Q-094)
- **Stage milestones:** 12, 36 and 72 months.
- When the date of birth is unreadable (for example a caregiver without `viewBabyInfo`), the band is `null`. The engine then uses the care-first default (`b0_1` order) without age labels and never shows a stage card.

### 4.3 Goals (AX03 / AX04)

`track_care` ("Theo dõi bú, ngủ, tã"), `memories` ("Lưu giữ kỷ niệm"), `growth_vaccines` ("Tăng trưởng & tiêm chủng"), `family` ("Cả nhà cùng chăm & cùng xem"), `spending` ("Chi tiêu cho con"), `reminders` ("Nhắc nhở việc của bé").

**Presets** (AX00 "Mục tiêu gợi ý sẵn"):

| Band | Preset goals |
|---|---|
| 0–1 | `track_care`, `memories` |
| 1–3 | `memories`, `growth_vaccines` |
| 3–6 | `memories`, `spending`, `family` |
| 6–12 | `memories`, `reminders`, `spending` |

The display order of the goal list is the presets first, then the rest in a fixed order. "Bỏ qua" stores `goalsSource: 'skipped'` and uses the presets.

### 4.4 Today widgets and ranking

**Widget ids.** The existing sections are kept by name so saved data maps 1:1:

| Id | Name | Goals served | Notes |
|---|---|---|---|
| `tiles` | Nhịp hôm nay / Ghi nhanh | track_care | only when the child has ≥1 tracker |
| `reminders` | Nhắc nhở | reminders | "Vì: Luôn có" when no goal matches |
| `recent_memories` | Kỷ niệm gần đây / nhật ký | memories | |
| `moment_today` | Lưu khoảnh khắc hôm nay | memories | 3–6 hero |
| `create_from_memories` | Tạo từ kỷ niệm (Video & thiệp) | memories | needs `milestone_cards` or `memory_story` |
| `growth` | Tăng trưởng | growth_vaccines | caregivers excluded (as today) |
| `spending` | Chi tiêu tháng này | spending | needs viewAll |
| `family_view` | Cả nhà cùng xem | family | Cùng nuôi only |
| `vaccine` | Mũi tiêm sắp tới | growth_vaccines | |
| `forYou`, `solids`, `quickActions`, `rhythm` | existing | — | kept with their current gates |

**Score**, with weights as drawn (AX00, initial values for experiment, kept in one constant so analytics can tune them):

```
score = 0.35·goal + 0.25·age + 0.20·usage + 0.10·recent + 0.10·product
goal    = [serves a chosen goal] − [serves a goal of the band's preset]   ∈ {−1, 0, 1}
          (the AX00 default list already encodes the preset goals, so the presets change nothing)
age     = 1 − index/len in the band's default list (AX00 "thứ tự mặc định"); 0 if absent
usage   = this person's opens of the widget's module over 28 days, normalised to the top module (0 at cold start)
recent  = 1 if the module had activity for this child in the last 48 h, else 0
product = per-widget constant from the registry (0–1; all 0 at launch)
ties    → band default index, then registry order
```

Band default lists (AX00, with the existing sections in their D-076 places):

| Band | Default list |
|---|---|
| 0–1 | tiles, forYou, solids, reminders, recent_memories, growth |
| 1–3 | recent_memories, tiles, forYou, solids, reminders, growth |
| 3–6 | moment_today, create_from_memories, spending, reminders, family_view |
| 6–12 | recent_memories, reminders, spending, growth |

`vaccine`, `quickActions` and `rhythm` stay opt-in, as today.

**Hard rules**, which override the score:
1. Unavailable widgets are never listed.
2. Pinned widgets come first, in pin order, and never move.
3. Hidden widgets never re-appear by themselves.
4. With no data, the age default plus the goals apply.
5. **Once the person drags** (AX06 or AX14), their order is kept as is. Widgets that become available later (a feature released afterwards) follow it, by score. Usage and recency never reshuffle a manual order (P-176).

**Visibility, so that a birthday never auto-hides anything:**
- `visible(w) = shown∋w ? true : hidden∋w ? false : defaultVisible(w, bandApplied, goals)`, where `defaultVisible` = in the band's default list ∨ serves a goal the person *added* beyond the band's presets (the presets are already in the list; a 0–1 child does not get Lưu khoảnh khắc hôm nay just because Lưu giữ kỷ niệm is preset).
- `bandApplied` is stored. It changes only when the person presses "Áp dụng" (AX33), "Khôi phục gợi ý theo tuổi" (AX14) or edits the goals.
- The current band is only used to decide whether to *offer* AX33.

**Worked examples.** Unit tests in both languages pin these.
- **Na, 4 years, preset goals:** every goal term is 0, so the order is the age order. That gives moment_today, create_from_memories, spending, reminders, family_view, which is AX12 and AX14.
- **Na, the person adds "Tăng trưởng & tiêm chủng":** growth scores .35 and goes to the top. That is above moment_today (.25), and growth becomes visible.
- **Teddy, 2 months, the person unticks "Theo dõi bú, ngủ, tã":** tiles scores −.35 + .25 = −.10 and goes to the bottom. Tiles still show while the child has trackers on, because removing a goal never hides on its own.

### 4.5 Storage: `users/{uid}/experience/{babyId}`

```ts
{
  v: 1,
  goals: Goal[],                       // ≤ 6, unique
  goalsSource: 'chosen' | 'skipped' | 'migrated',
  bandApplied: 'b0_1' | 'b1_3' | 'b3_6' | 'b6_12',
  order: WidgetId[],                   // manual order; [] = ranked
  pinned: WidgetId[], shown: WidgetId[], hidden: WidgetId[],
  stagePrompts: { m12?: 'applied' | 'kept', m36?: …, m72?: … },
  updatedAt: serverTimestamp
}
```

- **Rules:** the owner reads and writes it while still a member of the baby (`memberDoc(babyId)` exists), and the schema is validated as in `validPersonalization`. Deleting the baby, or the person leaving it, purges the document (the existing account/baby purge lists).
- **Offline:** Firestore persistence plus a SharedPreferences mirror for a first frame without flicker (D-091 "Home renders from cache").
- **Migration**, the first time the doc is missing:
  - Read `today.layout.<babyId>` and map `order` to `order` and `hidden` to `hidden` (marked as manual, since the person chose it).
  - Set `goalsSource: 'migrated'`, with goals = presets for the band and `bandApplied` = the current band.
  - **Existing users never see onboarding again**, and their Today is unchanged until they tap Tuỳ chỉnh or a stage card (P-177).

### 4.6 Navigation v2 and route migration

The shell branches change; the paths do not.
- `/care/*` and `/utilities/*` stay as real routes, pushed above the Khám phá root.
- New roots are `/explore` and `/profile`. `/me` redirects to `/profile`.
- Every notification destination, Lumi read link, ENG-04 link and glance link therefore keeps working. A route test enumerates `notificationDestinations` and the Lumi links and asserts that each one resolves (P-178).
- This also fixes the stale `spendingRoute = '/care/spending'` (`firebase/functions/src/spending.ts:59`).

**Swap behind `adaptive_nav`:**
- `tabsForRole` gains a v2 table.
- `ClTab` gains `explore` and `profile`.
- The old `care` and `utilities` stay for the flag-off path until the flag is removed.
- The header avatar is replaced by the switcher pill only when the flag is on.

### 4.7 Khám phá catalogue

The catalogue is static data built from the registry.
- **Sections:** "Gợi ý cho {tên} lúc này" (the top 4 by the same score without usage) · "Dùng suốt hành trình của con" · "Sức khoẻ & an toàn" · "Gia đình & trợ lý" · "Theo dõi chăm sóc".
- Row subtitles can vary per band (AX20 vs AX21).
- **Search:** local, accent-insensitive, over titles, subtitles and synonyms (vi and en). No result → the AX45 card.
- "Cùng con lớn lên" lists planned chapters from the registry (`status: planned`). They are never tappable as features.

### 4.8 Analytics (contract change, MET-01)

New closed events:
- `onboarding_goals_set` (band, goal count, skipped)
- `today_widget_opened` (band, widget id)
- `today_customized` (action: pin | hide | show | reorder | restore)
- `stage_prompt_answered` (milestone, applied)
- `explore_interest` (band, source: card | search, with a normalised term from a fixed list, never free text)

All of them are no-ops while `product_analytics` is off.

### 4.9 Flags

- `adaptive_experience` (internal at first) gates: adaptive Today ranking, new widgets, the AX14 customise v2 and the onboarding goal steps. Off = today's Today.
- `adaptive_nav` gates the dock v2, Khám phá, Hồ sơ and the switcher pill. It requires `adaptive_experience`.

---

## 5. Implementation plan by phase

Each phase is shippable and dark-launched. "Done" follows CLAUDE.md: dev Firebase, iOS and Android, Light and Night care, code and test paths filled in the coverage checklist.

### Phase A: foundation (no visible change)
- Contracts `packages/contracts/src/adaptive.ts`: bands, milestones, goals, presets, widget registry, `rankToday`, catalogue, experience doc schema. Tests in `packages/contracts/test/adaptive.test.ts`.
- Flags `adaptive_experience` and `adaptive_nav` in `config.ts` (default off/internal), plus portal labels.
- Dart `apps/mobile/lib/features/adaptive/`:
  - `adaptive_engine.dart`: the same algorithm as the contract, with tests on the same fixtures.
  - `experience_repository.dart`: Firestore doc, local mirror and migration from `today.layout.*`.
- Firestore Rules for `users/{uid}/experience/{babyId}` and a rules test.
- **Exit:** `pnpm typecheck`, `pnpm test`, `flutter test` and `pnpm test:rules` are green; the AX06 / AX10–AX13 fixtures are pinned.

### Phase B: adaptive Hôm nay (behind `adaptive_experience`)
- New widgets: Kỷ niệm gần đây, Lưu khoảnh khắc hôm nay, Tạo từ kỷ niệm, Tăng trưởng, Cả nhà cùng xem, using existing repositories (memories, growth, family).
- A greeting and sub-line per band (ARB, vi and en).
- Empty states AX40–AX43 (first log, first moment, Tìm lại ảnh card gated on `auto_save`, first expense, first reminder).
- The AX14 customise screen v2: goal chips, pin, Đang hiện / Đã ẩn, reasons, restore. It replaces the sheet when the flag is on.
- Notification permission after the first reminder (already D-077; check it on this path).
- Goldens for 4 bands × Light/Night × vi/en.

### Phase C: onboarding for any age
- AX01/AX02 changes: live age helper, the "Mọi tính năng…" card beyond 12 months, the time-zone row.
- AX03/AX04 goals with presets and "Bỏ qua".
- AX05 tracker choice when `track_care` is chosen; otherwise trackers come from the band defaults (§2.3 #2).
- AX06 preview with drag; it writes the experience doc.
- The step count is computed from the goals.
- Hồ sơ › child › "mục tiêu & Hôm nay" reuses AX04 and AX14 (not drawn: G-110).

### Phase D: navigation v2 (behind `adaptive_nav`)
- Dock v2 by role; Lumi and FAB placement (FAB on Hôm nay and Kỷ niệm only); relatives get no Lumi or FAB.
- **Khám phá:** catalogue, search, "Cùng con lớn lên", "Báo tôi khi có", AX45.
- **Hồ sơ:** AX34 plus the "Ứng dụng" group carrying the rest of Tôi.
- **Switcher pill and sheet** (AX30): role subtitles, the "Bạn được mời vào" group and the limit row. The switch shows a skeleton, a toast and a 200 ms crossfade, and keeps the tab when the role allows (AX31/AX32).
- Route migration tests (§4.6).
- Update the business-map §5 "Tabs" row (stale).

### Phase E: stage transition, analytics, honesty loop
- The AX33 card at 12, 36 and 72 months, once each; Áp dụng / Giữ như cũ; undo via Tuỳ chỉnh.
- MET-01 events (§4.8) and the portal readout by band.
- Lumi suggested questions per band (AX00 "Lumi gợi ý hỏi"), where the assistant entry supports chips.

### Phase F: hardening
- Night care pass, English copy review list, device test (iOS and Android), coverage checklist rows, and removing the flag-off code paths after rollout.

**Ordering and parallelism:** A blocks everything. After A, B and C can run in parallel (different files), and D can start its route tests. E needs B and D.

---

## 6. Risks

| Risk | Mitigation |
|---|---|
| The nav change breaks deep links and notification taps | Paths unchanged; destinations enumerated in a route test; flag-gated |
| Ranking feels random and erodes trust | Age + goals dominate (60 %); a manual order is never reshuffled; reasons are shown |
| A birthday silently changes Today | `bandApplied` freezes the defaults; AX33 only suggests |
| Per-device layout (P-061) users lose their arrangement | One-time migration into the synced doc |
| Older-child families still churn | Measure D7/D30 by band and "Báo tôi khi có" terms; these decide chapter 2 |
| Child data in analytics | Band only; no names or dates of birth; search terms from a fixed list |

---

## 7. Decisions needed from the owner

These are mirrored as Q-087 … Q-094.
1. **Q-087:** Score the goal term relative to the age preset, so that AX10–AX14 are the cold-start Todays and AX06's order (Cả nhà before Nhắc nhở) is the outlier? Or should AX06 win, which would also reorder AX10 and AX11?
2. **Q-088:** Quick log follows the child's trackers, with band defaults at add-child (1–3: ngủ, tã)?
3. **Q-089:** Goals and Today layout per person × child, synced (superseding P-061 for Today)?
4. **Q-090:** Hồ sơ keeps every current Tôi row in an extra "Ứng dụng" group?
5. **Q-091:** Night care for every age; the "Đêm" pill shown when a care tracker is on?
6. **Q-092:** Caregiver Today and Khám phá as described in §2.3 #8?
7. **Q-093:** The Beta limit of 3 managed profiles goes into `config/limits`: per person, not counting invited children?
8. **Q-094:** Children over 12 stay in the 6–12 experience until a later chapter?

---

## 8. Phase A: what is in the workspace (2026-10-24)

Uncommitted, dark (`adaptive_experience` off/internal), nothing deployed, no UI change.

| Piece | Path |
|---|---|
| Engine contract: bands, milestones, goals and presets, widget registry, band defaults, AX00 weights, `rankToday`, `stagePromptDue`, `applyBand`, `experienceSchema` | `packages/contracts/src/adaptive.ts` (exported from `index.ts`) |
| Contract tests: AX10–AX14 cold-start orders, AX14 hidden-by-default, added/removed goals, pins/hides, usage vs manual order, AX33 once per milestone, schema | `packages/contracts/test/adaptive.test.ts` (14) |
| Dart mirror, same fixtures, plus `migrateTodayLayout` (P-177) | `apps/mobile/lib/features/adaptive/adaptive_engine.dart`, `apps/mobile/test/features/adaptive_engine_test.dart` (12) |
| Flags `adaptive_experience`, `adaptive_nav` → `getCapabilities.features.adaptiveExperience / adaptiveNav` → `PremiumFeatures` | `packages/contracts/src/config.ts`, `entitlements.ts`; `firebase/functions/src/entitlements.ts`; `apps/mobile/lib/features/premium/premium_models.dart` |
| Portal labels (vi/en), hub group "Cá nhân hoá" | `apps/portal/src/messages.ts`, `src/screens/FeatureHub.tsx`, `test/hub.test.tsx` |
| Rules `users/{uid}/experience/{babyId}` (owner only, active member, schema, `babyId` = path, server time) | `firebase/firestore.rules`, `firebase/tests/experience.rules.test.ts` (5) |
| Purge with the baby; collection-group index on `babyId` | `firebase/functions/src/account.ts`, `firebase/firestore.indexes.json` |

Checks run: contracts 907 tests, functions 502, portal 318, rules (experience + rhythm) on isolated emulator ports, Flutter adaptive + Today + assistant + nav tests, `pnpm typecheck`, `flutter analyze` on the touched files. `pnpm lint` fails only in other sessions' files (`apps/launch-film`, `scripts/verify-deploy.mjs`).

## 9. Phase B: adaptive Hôm nay (2026-10-24, D-097)

Uncommitted, behind `adaptive_experience` (off = the old Today, unchanged; full suite of 4000 Flutter tests green, goldens included).

| Piece | Path |
|---|---|
| Repository `users/{uid}/experience/{babyId}` + phone copy; age band from DOB in the child's zone; first server-confirmed miss seeds the doc (freezes `bandApplied`); migration from `today.layout.<babyId>` (P-177); notifier (goals, show/hide, pin, reorder, restore) | `apps/mobile/lib/features/adaptive/experience_repository.dart` |
| Availability by role/flag/data (caregiver: care only, D-097 Q-092; relative: read-only care) and the ranked Today | same file, `availableWidgetsProvider`, `adaptiveTodayProvider` |
| Greeting per band + first-run twin (AX10–AX13, AX40–AX43); widgets Kỷ niệm gần đây / Lưu khoảnh khắc đầu tiên, Lưu khoảnh khắc hôm nay, Tạo từ kỷ niệm, Tăng trưởng, Cả nhà cùng xem; "Tuỳ chỉnh Hôm nay" link | `apps/mobile/lib/features/adaptive/today_adaptive.dart` |
| AX14 Tuỳ chỉnh Hôm nay (route `/customize-today`): goal chips + "Sửa", Đang hiện (drag, pin, switch, reason), Đã ẩn ("Ẩn theo gợi ý tuổi"), "Khôi phục gợi ý theo tuổi"; draft until "Xong" | same file, `AxCustomizeScreen`; `apps/mobile/lib/app/router.dart` |
| AX03/AX04 goals screen (reused by AX14 "Sửa"; onboarding in phase C) | same file, `AxGoalsScreen` |
| Today wiring: flag on → greeting + ranked widgets; existing sections reused as they are | `apps/mobile/lib/features/today/today_screen.dart` |
| Copy: 80 ARB ids, vi + en (English drafted by engineering, D-012) | `apps/mobile/lib/l10n/app_vi.arb`, `app_en.arb` |
| Tests: widget (7) and goldens (8 cases × Light/Night × vi/en) | `apps/mobile/test/features/adaptive_today_test.dart`, `test/golden/adaptive_golden_test.dart`, `test/golden/goldens/ax/`, `test/helpers/adaptive_fixtures.dart` |

**Known differences from Figma (to close in later phases):**
- Chi tiêu tháng này and Nhắc nhở still use their current cards, not the AX card with the stacked bar (AX12/AX13).
- The tiles have no "Nhịp hôm nay · Xem lịch sử" header, and the empty tiles are the current "Chưa có / Chạm để ghi", not the "Ghi lần đầu" pill (AX40).
- The child switcher pill and the dock are unchanged (phase D).
- There is no "Tìm lại ảnh … · Beta" card yet (needs `auto_save`).
- Afternoon and evening greetings are engineering wording (G-110).
- Usage and recency signals are not collected yet, so ranking runs on age + goals only (phase E).

**Before trying it on dev:** deploy `firestore:rules`, `firestore:indexes` and the `entitlements` / `account` functions with `scripts/deploy.sh dev …`, after checking that HEAD carries the peers' latest rules (shared-tree rules deploy). Then turn on `adaptive_experience` for an internal family in the portal.

## 10. Phase C: adding a child of any age (2026-10-24)

Uncommitted. The flow is on when adding a child to a family with `adaptive_experience`, or for a first child only once the public flag is `enabled` with scope `all`: a first child has no family yet, so no per-family rollout can be evaluated. Off = 10a → 11 → 12, unchanged. All Flutter tests pass; `auto_save_test` failed once in a full run and passes on its own, and that file is untouched here.

| Step | What it does | Code |
|---|---|---|
| 11 (AX01/AX02) | Live age under the date ("Na được 4 tuổi"); from 12 months the card "Mọi tính năng của Child Life đều dùng được cho {tên}" with the age's chips. Its footnote says "Chăm sóc và Tiện ích" until `adaptive_nav` puts Khám phá in place | `setup_screens.dart` `babyFormFields(ageInfo:)`, `adaptive_setup.dart` `SetupAgeInfoCard` |
| Goals (AX03/AX04), `/setup/goals` | The band's presets first, pre-ticked, with "Gợi ý cho {tuổi}"; "Bỏ qua" keeps the presets and records `skipped` | `SetupGoalsScreen` |
| 12 (AX05), only with "Theo dõi bú, ngủ, tã" | Opens once with the band's trackers; "Tiếp" instead of creating | `TrackersScreen` (adaptive branch) |
| Preview (AX06), `/setup/preview` | The ranked Hôm nay with "Vì: …", drag to reorder; "Vào Hôm nay của {tên}" creates the child and writes `users/{uid}/experience/{babyId}` (goals, source, band, order) | `SetupPreviewScreen`, `createSetupBaby` (shared with 12) |

**Decisions made while building:**
- **Trackers by band (Q-088).** 0–1 gets bú bình, bú mẹ, ngủ, tã. 1–3 gets ngủ, tã. **From 3 years the child gets Tăng trưởng**, not "none", because `createBabyRequest` requires at least one tracker. The quick log still starts hidden for those bands (it is not in their default list), so nothing extra shows on Hôm nay.
- **Progress bar.** The existing setup chrome stays, with the progress computed from the steps the goals imply. AX's "Bước n/N" text is not used, to stay consistent with 10a/11.
- **Kỷ niệm 2.0 in the preview.** A first child never sees "Tạo từ kỷ niệm", because its beta cannot be known before the family exists. When adding a child, it shows if this family has the beta.

**Tests:** `apps/mobile/test/features/adaptive_setup_test.dart` (8); goldens `ax02_baby_4y`, `ax04_setup_goals_4y`, `ax06_preview_4y` × Light/Night × vi/en in `test/golden/goldens/ax/`. The setup screens compute age from today's date, as 11 already does, so these goldens show "4 tuổi" until 12 Mar 2027. Regenerate them then, or give setup a clock.

## 11. Phase D: navigation v2 (2026-10-24)

Uncommitted, behind `adaptive_nav`; the server sends it only together with `adaptive_experience`. With the flag off the dock is Hôm nay · Kỷ niệm · Chăm sóc · Tiện ích, exactly as before. All 4081 Flutter tests pass. The four "foundations" showcase goldens were refreshed because the icon set gained `profile`.

| Piece | Code |
|---|---|
| Tabs by role: parent Hôm nay · Kỷ niệm · Khám phá · Hồ sơ; caregiver Hôm nay · Khám phá · Hồ sơ; relative Kỷ niệm · Hồ sơ (+ Hôm nay with daily care, D-018) | `core/widgets/cl_navigation.dart` `tabsForRoleV2`, `ClTab.explore/profile` |
| **Lumi at the end of the dock row, outside the tab bar** (owner, 2026-10-24). The "+" still floats above the right end on Hôm nay / Kỷ niệm; there is no Lumi for relatives (AX32) and none without the `assistant` flag. The first-run Lumi tooltip still works there | `ClTabDock.trailing`; `features/home/home_shell.dart` |
| Shell: two new branches `/explore`, `/profile`. The v1 branches and paths are kept, so `/care/*` and `/utilities/*` (notification destinations, Lumi read links, ENG-04, glance) open unchanged and light "Khám phá" | `app/router.dart`, `app/route_guard.dart`, `dockTabOf` |
| Header: the switcher pill leads; the Tôi avatar is gone (Hồ sơ is a tab) | `BabyHeader` |
| Khám phá (AX20/AX21/AX45): "Gợi ý cho {tên} lúc này" per band, the whole V1 list grouped (Dùng suốt hành trình · Sức khoẻ & an toàn · Gia đình & trợ lý · Theo dõi chăm sóc · Hiểu con & phát triển), gated by role and flags as in Chăm sóc / Tiện ích. Search ignores Vietnamese marks; no result is honest, with "Lưu vào Kỷ niệm". "Cùng con lớn lên" is a dashed card; "Báo tôi khi có" is kept per person on the phone and becomes "Đã ghi nhận" (the MET-01 event follows in phase E) | `features/adaptive/explore_screen.dart` |
| Hồ sơ (AX34): Tôi as a tab root with no back button. "Các bé" first: managed children, youngest first, each opening its "mục tiêu & Hôm nay" (AX14 for that child); "Thêm" adds one. Every Tôi row stays (Q-090) | `features/me/me_screen.dart` `MeScreen(asTab:)`, `features/adaptive/profile_children.dart` |
| `Icon/profile` drawn in the line style (no export in the icon set) | `assets/icons/profile.svg` |
| Tests: `test/features/adaptive_nav_test.dart` (9); goldens `ax20_explore_0_1`, `ax21_explore_3_6`, `ax45_explore_none`, `ax34_profile`, `ax_dock_v2` | `test/golden/goldens/ax/` |

**Not done in D (left for later):**
- Chăm sóc and Tiện ích are still reachable as screens. The Khám phá row "Tất cả công cụ chăm sóc" opens Chăm sóc for Dinh dưỡng, Ăn dặm, Wonder Weeks, Giai đoạn and Thư viện, so their live subtitles are not duplicated.
- The AX30 switcher sheet is still today's sheet: no role line under each name, no "Bạn được mời vào" group. The AX31 skeleton, toast and 200 ms crossfade are not done either.
- The switcher pill label is today's ("Teddy · 3 tuần"), not "{tên} · {tuổi}" in bands.
- No route test enumerates every notification destination against the v2 shell. The paths are unchanged, so the existing destination tests still apply.

## 12. Phase E: stage card, analytics, signals, Lumi (2026-10-24)

Uncommitted and behind `adaptive_experience`. All 4092 Flutter tests, 907 contracts tests, 502 functions tests and 318 portal tests pass, and the analytics + experience integration suites pass on isolated emulator ports. `pnpm typecheck` is green.

| Piece | Code |
|---|---|
| **AX33 stage card** (Hôm nay, above the widgets): offered once at 12, 36 and 72 months when the child's band is newer than the one applied. Options are pre-ticked. At 12 months: Kỷ niệm first, bú bình/bú mẹ/hút sữa off the quick log (this phone's tile hides; trackers stay the family's), keep ngủ/tã. At 36: lead with Lưu khoảnh khắc, hide the quick log. At 72: lead with Kỷ niệm/nhật ký, keep Tăng trưởng. "Áp dụng" / "Giữ như cũ" are recorded per milestone; nothing is hidden or moved without the press; undo via Tuỳ chỉnh | `features/adaptive/adaptive_signals.dart` `AxStageCard`, `applyStage` |
| **Ranking signals:** usage = taps on each Hôm nay widget, this person × this child, last 28 days, on the phone only, normalised to the most-used widget. Recency = care logs / growth / photos in the last 48 h. Both are **frozen per app run**, so Hôm nay never reshuffles under the finger, and they never move a manual order (P-176) | `UsageStore`, `rankSignalsProvider`, `AdaptiveTapTracker` |
| **MET-01 events** (closed, `detail` closed too): `adaptive_goals_set` (chosen / skipped), `adaptive_widget_opened` (widget id), `adaptive_customized` (pin, unpin, hide, show, reorder, goals, restore), `adaptive_stage_answered` (applied / kept), `adaptive_interest` (card / search; never the search text). The server keeps `detail` in `template`, puts the module at `personalization`, and adds a **`stageBand`** (0–1 / 1–3 / 3–6 / 6+) next to `ageBand`, which stops at `12m_plus` and is unchanged | `packages/contracts/src/product-analytics.ts`, `firebase/functions/src/product-analytics-store.ts` |
| **Lumi by age** (AX00 "Lumi gợi ý hỏi"): with the flag on, the empty chat's examples follow the band. 0–1: "Lần bú cuối lúc mấy giờ?". 1–3: "Tuần này {tên} ngủ trưa thế nào?". 3–6: "Tháng này đã chi cho {tên} bao nhiêu?". 6+: "Tuần tới {tên} có lịch gì?" plus an expense example. The composer chips drop "Ghi bú" from 1 year and the care chips from 3 years, giving "Ghi chi tiêu" instead. Flag off: unchanged | `features/assistant/assistant_screens.dart` |
| Tests | `test/features/adaptive_signals_test.dart` (7); `packages/contracts/test/adaptive.test.ts` (event schema); `firebase/tests/product-analytics.integration.test.ts` (stageBand, no name, free text refused); golden `ax33_stage_12m` |

**Not done (follow-ups):**
- The portal "Phân tích sản phẩm" readout does not filter or group by `stageBand` / adaptive events yet. The facts are recorded and the readout needs its own change.
- Remaining design gaps G-110: the AX30/AX31 switcher sheet and switch motion, the Chi tiêu / Nhắc nhở AX cards, the "Nhịp hôm nay" header and the "Ghi lần đầu" tile pill.
- None of phases A–E has been tried on a phone or on dev Firebase. A dev deploy needs `firestore:rules`, `firestore:indexes` and `functions` (entitlements, account, product analytics). Then turn on `adaptive_experience` and `adaptive_nav` for an internal family.
