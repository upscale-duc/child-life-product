# 07 · Feature personalization specification

**Levels.** L0 universal · L1 content adaptation (words, examples, defaults) · L2 experience adaptation (inputs, order, suggested actions) · L3 capability evolution (new function). The rule: **choose the lowest level that removes a real mismatch.** Age alone is not a reason.

| Feature | Min level | What changes | What stays | Evidence / reason |
|---|---|---|---|---|
| Care log | L2 | Default trackers by band (built); AX33 removes feeds from Ghi nhanh at 12 m (suggested) | Data model, history, manual access | Built (D-097 Q-088) |
| Nhắc nhở | L1 | Suggested templates per band | Engine, assignee, all-day | Templates are content |
| Tiêm chủng | L1 → L3 later | Extend country schedule data beyond 72 m where official | Book, overdue logic | `vaccines.ts` max 72 m |
| Tăng trưởng | L2 | 0–5 y: WHO percentile band. 5+ y: show the measurements and the trend, say "Không có bảng WHO cho tuổi này trong app" until a 5–19 reference is added and reviewed | Measurement model | `who_growth.dart:24` |
| Mốc phát triển | L3 (light) | After 36 m: no reference list; offer "Lần đầu của {tên}" custom moments with a date, saved to Kỷ niệm | Custom milestones, memory link | Seed max 36 m |
| Dành cho bé / Tuần này | L1 | Coverage end state; toddler-v2 after review | Content pipeline | Age cards to 24 m |
| Thư viện | L1 | Facets aligned to buckets; "Mọi lứa tuổi" tag | Publishing | CH-02 |
| Sơ cứu | L1 | Already infant/child | — | `first-aid.ts` |
| Chuẩn bị đi khám | L2 | Without care logs, lead with growth, vaccines, questions | Report | D-141 U1 |
| Kỷ niệm | L0 | — | Everything | Age-free |
| Tự lưu | L2 | Late joiners: a "past years" pass, grouped by year of age | Review-first (D-123) | — |
| Story / video / cards | L2 | Occasions after y1 (yearly birthday, year in review) | Renderer, catalogue, quotas | AXA-07 |
| Gia đình | L1 | Wording ("con", child's name) | Roles, invites | AXA-06 |
| Cùng Chăm Con | L1 | Age-based plan templates as reviewed content (D-136 #1) | Tasks, shifts | Templates < 6 m today |
| Chi tiêu | L1 | Category suggestions by band (học phí, ngoại khoá) — verify the current category set first | Model | Hypothesis |
| Lumi | L2 | Example questions by band (built); capability tiers by band ([09](09-lumi-insights-strategy.md)) | Tools, credits, safety | Plan §12 |
| Smart Engagement | L1 | Triggers by band: yearly occasions instead of monthly | Ledger, quiet hours, no late pushes | `16-memory-campaigns.md` |
| Living Header | L0 | Greeting per band (built) | — | — |

## Detail for the examples in the brief

### Growth
- **Fact:** the measurement model stores weight, height, head with a date; WHO bands to 1856 days (5 years) and return `null` after.
- **Proposal:** never show a blank or a broken chart. For 5+: list and trend line with "Theo dõi theo thời gian" and no percentile. Hide head circumference input after 36 m by default (rarely measured outside clinics) [H]. Adding WHO 5–19 BMI-for-age is L3, needs domain review.

### Milestones
- **Fact:** 68 reference items in 0–36 months; custom milestones exist; milestones link to memories.
- **Proposal:** the concept evolves from "developmental milestone" (observe and record) to "lần đầu" and "điều con tự hào" (record and celebrate). Same storage, a different template set, no reference windows after 36 m. **Never** present school-age expectations as norms.

### Memories
See [10](10-memories-across-childhood.md). L0 for storage, L2 for prompts and occasions.

### Health records
Cross-age: vaccines, growth history, visit prep, first aid. Future (DEFER): documents vault, allergies list, medicines list. Allergies and medicines are sensitive health data; build only with a clear use (doctor visit, caregiver handover) and owner privacy review.

### Family collaboration
0–3: shifts and handover. 3–6: pickups, tasks, costs. 6–12: reminders and shared memories with relatives. The existing roles already fit; only the default tasks and wording change.

### Daily activities
The care record is typed by tracker; adding generic types ("Đánh răng", "Đọc sách") is possible (Cùng Chăm Con already has non-log tasks, D-138). **Recommendation:** keep generic routines in Cùng Chăm Con tasks, not as new care trackers, so Thống kê stays meaningful. Potty learning is the one tracker worth a future L3 for CH02.

### Lumi
Must know: age (months), band, coverage of each content type, which features are on for this family and role, and what is recorded. See [09](09-lumi-insights-strategy.md).
