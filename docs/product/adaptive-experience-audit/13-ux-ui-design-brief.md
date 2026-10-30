# 13 · UX/UI design brief

**For:** whoever updates the design (Figma or Flutter). **Authority:** the Flutter app is the source of truth for screens it already improved (D-104); the AX section `930:11858` is history for those. Figma is read-only for this project's agents (CLAUDE.md), so Figma updates are made by a person or a separate, explicitly authorized design task. Before changing any screen, render it fresh at the reference ages (D-111) and use the cl-* skills.

**Identity rule:** one Child Life. No age themes, no childish decoration, no new tokens without a real need (D-106). Content hierarchy and feature prominence may adapt; brand, components and interactions do not.

## 1. Screens and variants

| # | Screen | Variants needed | Change | Components (reuse) | Roadmap |
|---|---|---|---|---|---|
| S1 | Welcome | 1 | Age-neutral body and CTA | Existing hero | RM-07 |
| S2 | Setup · child (11) | Newborn, 2 y, 10 y | Already has live age + "Mọi tính năng…" card; check wording | `SetupAgeInfoCard` | RM-06 |
| S3 | Setup · goals | 0–1, 1–3, 3–6, 6+ | Unchanged; remove the duplicate EN01 ask downstream | `SetupGoalsScreen` | RM-02 |
| S4 | Setup · bring the past in (**new**) | iOS with Tự lưu, Android / no permission | One screen, two actions ("Tìm ảnh giúp tôi", "Để sau") | Onboarding layout, `ClButton` primary + text | RM-10 |
| S5 | Hôm nay | 3 w, 8 m, 2 y, 5 y, 9 y × first-run / used | Order and copy per [06 §3](06-adaptive-today-and-navigation.md); no EN01 card when goals chosen | AX widgets, `ReminderPeek(ax:)`, `AxSpending` | RM-01, RM-02, RM-04 |
| S6 | Content end state (**new state, not screen**) | Mốc, Dành cho bé, Thư viện, Dinh dưỡng | One shared empty state: line + one action | `MeNotice` (info) or existing empty-state widget; no secondary button inside an info notice (known contrast issue) | RM-05 |
| S7 | Tăng trưởng > 5 y | With and without measurements | Trend + list, "không có bảng WHO cho tuổi này" | `growth_chart.dart` | RM-11 |
| S8 | Birthday keepsake suggestion | 2 y, 5 y, 9 y; enough / not enough photos | A Today card on the birthday week + a Kỷ niệm shelf entry | `AxCreateFromMemories`, retrospective shelf | RM-09 |
| S9 | Stage card AX33 | 12, 36, 72 m | Copy review for 36/72 (G-110 open) | `AxStageCard` | — |
| S10 | Profile / family wording | vi, en | "baby" → child / name on cross-age rows | Existing rows | RM-06 |
| S11 | Khám phá | 0–1, 3–6, 6+ | No change (D-139); verify "Cùng con lớn lên" copy | `explore_screen.dart` | — |
| S12 | Caregiver Hôm nay (older child) | 5 y with assigned tasks | Tasks + reminders, not empty care tiles (AXA-11, hypothesis) | `CarePlanTodaySection`, `ReminderPeek` | RM-04 |

## 2. Interaction changes

- None to navigation, gestures or tab structure.
- The EN01 invite disappears for people who chose goals.
- A new optional onboarding step (S4), skippable, never blocking.
- A shared end state replaces blank content lists.

## 3. Content changes

Use the [08 §3](08-content-ux-writing-strategy.md) matrix as the draft. Every string goes through ARB with vi + en; English marked for owner review.

## 4. Edge cases

| Case | Expected |
|---|---|
| DOB unreadable (caregiver without baby info) | Care-first order, no age words, no stage card |
| Child switch between a newborn and a 9-year-old | Today changes order, tabs unchanged, toast "Đang xem Bin · 9 tuổi" |
| Pinned tiles on a 3-year-old | Stay pinned, stage card does not move them |
| Child born preterm | Corrected age in Tuần này only (D-141); band from actual age |
| DOB edited from 2 y to 5 y | Band changes; `bandApplied` unchanged until the stage card; one card, for the highest milestone reached (fact: `stagePromptDue` in `adaptive.ts:342-347`). "Áp dụng" keeps pins and hides but resets a manual order (`applyBand`); the card copy should say so |
| Child ≥ 12 y | "6+" copy; no school-age claims |
| No photos at all (older child) | Today leads with "Lưu khoảnh khắc", S4 offer |
| Relative viewing a 9-year-old | Kỷ niệm · Hồ sơ only; shared memories only |
| Night care at any age | Same tokens; "Đêm" pill only with a care tracker on (Q-091) |
| 200 % text, vi long strings | No truncation of essential status; wrap |

## 5. Design acceptance criteria

1. Fresh renders at 3 w, 8 m, 2 y, 5 y, 9 y × Light / Night × vi / en for S5, S6, S7, S8.
2. No 3+ render shows bú, tã, "sơ sinh" or "năm đầu đời" outside an explicit care screen the person opened.
3. One dominant primary action per screen or sheet (D-105).
4. Every visible element earns its place (D-110); no explanatory subtitle where the section says it.
5. All colours, type, spacing from tokens; contrast checked in Night care (soft warm fills take `colors.ink`).
6. 44 pt targets; semantics labels in both languages.
7. cl-design-review score recorded with before/after evidence; only intended goldens updated.
