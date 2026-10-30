# 04 · Feature × age matrix

**Legend.** Relevance per band: ●●● primary · ●● useful · ● occasional · — not relevant. **Class:** KEEP / ADAPT / EXTEND / BUILD / DEFER / RECONSIDER. **Type:** AS = age-specific, CA = cross-age, EV = evolving, FU = future. **Level:** personalization level from [07](07-feature-personalization-spec.md) (L0 universal … L3 capability evolution). **Status:** S = shipped, B = built behind a flag, D = draft content, — = not built.

| Feature | 0–1 | 1–3 | 3–6 | 6–12 | Type | Class | Level | Status | Why |
|---|---|---|---|---|---|---|---|---|---|
| Bú bình / bú mẹ / hút sữa | ●●● | ● | — | — | AS | KEEP | L0 | S | Valuable and finite; already off Ghi nhanh at 12 m via AX33 |
| Ngủ, timers | ●●● | ●● | ● | — | EV | ADAPT | L2 | S | Naps fade; keep for sleep issues, off by default from 3 y |
| Tã | ●●● | ●● | — | — | AS | KEEP | L0 | S | Potty learning is the natural next step (future) |
| Potty / toilet learning | — | ●● | ● | — | FU | DEFER | L3 | — | Real need 2–3 y [E]; build only if CH02 usage justifies |
| Custom care type ("Uống thuốc", "Đánh răng") | ● | ●● | ●● | ● | FU | DEFER | L3 | — | Generic types risk clutter; validate first |
| Lịch sử, Thống kê | ●●● | ●● | ● | ● | CA | KEEP | L0 | S | Shows whatever was logged |
| Sắp tới (W1) | ●●● | ● | — | — | AS | KEEP | L0 | S | Computed from own logs; disappears with no data |
| Nhắc nhở | ●● | ●● | ●●● | ●●● | CA | ADAPT | L1 | S | Templates by band (content) |
| Tiêm chủng | ●●● | ●●● | ●● | ● | CA | EXTEND | L1 | S (to 72 m) | Extend official schedules past 6 y where they exist |
| Tăng trưởng | ●●● | ●●● | ●● | ● | EV | EXTEND | L2 | S (WHO 0–5) | Measurements are age-free; interpretation ends at 5 y |
| Chuẩn bị đi khám | ●●● | ●● | ●● | ● | CA | ADAPT | L2 | S | Lead with growth/vaccines when no care logs |
| Sơ cứu | ●●● | ●●● | ●● | ●● | CA | KEEP | L1 | S | Infant/child switch exists |
| Mốc phát triển | ●●● | ●●● | ● | — | EV | EXTEND | L3 | D (to 36 m) | Becomes "lần đầu" and achievements, saved as memories |
| Dành cho bé hôm nay / Tuần này | ●●● | ●● | — | — | AS | ADAPT | L1 | D (to 24 m) | Honest end-of-coverage; toddler content after review |
| Nhịp lớn lên (Wonder Weeks) | ●●● | — | — | — | AS | KEEP | L0 | S | Infancy only by its model |
| Ăn dặm | ●● | ●●● | — | — | AS | KEEP | L0 | S (6–36 m) | Finite by nature |
| Dinh dưỡng | ●● | ●● | ● | ● | EV | DEFER | L1 | S (to 36 m) | Extend content only with review |
| Thư viện | ●●● | ●● | ● | ● | CA | ADAPT | L1 | S | Align filter with buckets; mark all-age articles |
| Kỷ niệm (upload, albums, privacy) | ●●● | ●●● | ●●● | ●●● | CA | KEEP | L0 | S | The cross-age core |
| Tự lưu | ●●● | ●●● | ●●● | ●●● | CA | EXTEND | L2 | S (beta) | Past-years pass for late joiners |
| Story / video / cards / print | ●●● | ●●● | ●●● | ●●● | EV | EXTEND | L2 | S | Occasions after y1 |
| Year look-back / birthday chapter | ● | ●●● | ●●● | ●●● | FU | BUILD | L3 | — | Strategic: [10](10-memories-across-childhood.md) |
| Then & Now | ● | ●● | ●●● | ●●● | FU | BUILD | L3 | — | Reuses media + ages |
| Retrospective shelf | ●● | ●●● | ●●● | ●● | EV | EXTEND | L1 | B | Targets past y1 |
| Gia đình, relatives | ●●● | ●●● | ●●● | ●●● | CA | ADAPT | L1 | S | Wording only |
| Bàn giao | ●●● | ●● | ● | — | AS | KEEP | L0 | S | Care-log based |
| Cùng Chăm Con | ●●● | ●● | ●● | ● | EV | ADAPT | L1 | S | Tasks are generic; plan templates are age content |
| Chi tiêu | ●● | ●● | ●●● | ●●● | CA | ADAPT | L1 | S | Category labels by band (verify set) |
| Lumi | ●●● | ●● | ●● | ●● | EV | ADAPT | L2 | S | From logging to recall ([09](09-lumi-insights-strategy.md)) |
| Smart Engagement | ●●● | ●● | ● | ● | EV | ADAPT | L1 | S | Fewer, event-driven triggers past 1 y |
| Living Header | ●●● | ●●● | ●●● | ●●● | CA | KEEP | L0 | S | Photo-led, age-free |
| Khám phá, "Cùng con lớn lên" | ●●● | ●●● | ●●● | ●●● | CA | KEEP | L1 | B | Built |
| School / activity calendar | — | — | ● | ●● | FU | DEFER | L3 | — | Reminders cover the minimum |
| Documents vault (health book scans) | ● | ● | ● | ●● | FU | DEFER | L3 | — | Privacy cost; validate demand |
| Child-facing access | — | — | — | ● | FU | RECONSIDER | — | — | Caregivers are the users; child data risks |
| Gamification / streaks | — | — | — | — | — | RECONSIDER | — | — | Against "technology handles the routine" |

## Reading the matrix

- **Cross-age already:** 13 shipped features are relevant in all four bands and need no capability change, only KEEP or ADAPT: Lịch sử, Nhắc nhở, Chuẩn bị đi khám, Sơ cứu, Thư viện, Kỷ niệm, Gia đình, Cùng Chăm Con, Chi tiêu, Lumi, Smart Engagement, Living Header, Khám phá. The gap is presentation, wording and occasions, not features.
- **Evolving:** sleep, growth, milestones, keepsakes, Lumi, engagement. Each keeps its data model; the inputs and wording shift.
- **Build only two things strategically:** the year look-back / birthday chapter and Then & Now. Both are Memories, both reuse the renderer and media.
- **Age-specific features stay age-specific:** they fall out of the default Today by band, stay reachable in Khám phá, and are never deleted.
