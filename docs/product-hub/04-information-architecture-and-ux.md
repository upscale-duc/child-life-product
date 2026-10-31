# 04 · Information architecture and UX screen specifications

Product Hub lives inside the existing staff portal (`apps/portal`), with the portal's shell,
sidebar, command palette (`cmdk`), `Page` / `Section` / `FilterBar` / `StatTiles` /
`TableScroll` / `Sheet` components and design tokens. No new visual language. Light and Dark,
vi and en, from the first screen.

## 1. Placement and routes

One new sidebar section **"Sản phẩm · Product"** with one route `product` (`/product`), tabs as
sub-paths, following the `features` / `system` pattern in `apps/portal/src/context.ts`:

| Tab | Path | Phase | Purpose |
|---|---|---|---|
| Tổng quan · Overview | `/product` | 1 | Where the product stands; every tile links to a filtered catalog |
| Tính năng · Features | `/product/features`, `/product/features/<id>` | 1 | Catalog + feature specification |
| Gói & quyền · Plans | `/product/plans` | 1 | Free / Premium by capability; links to `/features` for live changes |
| Nguồn tri thức · Sources | `/product/sources`, `/product/sources/<id>` | 1 | Document library, sync runs, review queue |
| Hỏi Copilot · Copilot | `/product/copilot`, `/product/copilot/<conversation>` | 2 | Global chat; feature chat lives in the feature page |
| Hành trình · Journeys | `/product/journeys/<id>` | 3 | End-to-end flows linked to features |
| Quyết định & cơ hội · Decisions | `/product/decisions` | 3 | D/R/P/Q/G records + opportunities |
| Hiệu quả · Insights | `/product/insights` | 4 | Feature metrics, instrumentation status |

Tabs not yet built are **not shown** (no "coming soon" tabs). The sidebar badge counts items
waiting for review (sync drafts + AI drafts), mirroring `staffBadges`.

Naming: the brief's "Product Hub" collides in Vietnamese with the existing **"Tính năng &
Premium" hub** (`/features`, also called "hub" in code: `hub.*` message ids, `FeatureHub.tsx`).
Proposed portal label **"Sản phẩm"** (en "Product"), code prefix `productHub` / `ph.*` message
ids. Final name → owner (Q-PH-02).

## 2. Screen specifications

### 2.1 Overview (`/product`)

Archetype: dashboard, one column on narrow widths.

1. **Header line**: source revision (`e60e569b`, date), last sync time, reviewer — one line, muted.
2. **StatTiles (5)**: Features · Built · In development · Designed/planned · Need verification.
   Each tile opens the catalog with that filter. Numbers come only from reviewed registry
   records; before the first review the tiles show "—" with "Chưa duyệt" (not zero).
3. **By pillar × lifecycle**: one compact table (4 rows × 4 columns), cells are links.
4. **Plans**: Free / Premium / Beta counts of tierable features + "40 features use free
   capabilities" — link to Plans.
5. **Knowledge health**: coverage distribution (bars by band 0–39 / 40–69 / 70–100), conflicts
   open, sources stale. Each a link.
6. **Recent**: last 5 decisions (D-xxx, date, one line) and last 5 knowledge changes.
7. **Analytics**: one line "Chưa có dữ liệu sử dụng — ứng dụng chưa phát hành" until Phase 4
   has real data. Never placeholder numbers.

### 2.2 Feature catalog (`/product/features`)

Archetype: dense filterable table (like `HubFeaturesView`).

- **Search** (name, id, alias, vi/en, accent-insensitive) + **FilterBar**: Pillar · Lifecycle ·
  Implementation · Verification · Tier · Platform · Coverage band. Chapter and age range are
  filters only once records carry them (Phase 1 review fills them; chapters never gate features).
- **Columns**: Feature (name + id muted) · Pillar · Lifecycle · Tier · Coverage (number + 4-step
  bar) · Verification (icon + word) · Updated. Implementation shows as a pill only when it is not
  `implemented`, so the common case stays quiet.
- Row → feature page. Filters live in the URL query so tiles and the Copilot can link to them.
- Empty: "Không có tính năng nào khớp bộ lọc" + "Xoá bộ lọc".

### 2.3 Feature page (`/product/features/<id>`)

Archetype: specification with a sticky section rail (desktop) / section select (mobile width).
The brief's 12 sections are grouped into **5 tabs** to keep scanning short:

| Tab | Brief sections | Notes |
|---|---|---|
| Tổng quan | 1 Overview · 2 User problem · 3 Value | Status strip at top: Lifecycle · Implementation · Verification · Release · Tier, each with its evidence date |
| Trải nghiệm | 4 UX · 5 Business rules | Rules in two columns: **Intended** (decision/spec, with id) and **Implemented** (code ref) — mismatch row highlighted |
| Gói & kỹ thuật | 6 Free/Premium · 7 Architecture · 8 Dependencies | Entitlement block reads live from contracts; dependency list both directions |
| Đo lường & cơ hội | 9 Metrics · 10 Issues & opportunities | Metric rows show "Đã đo / Chưa có sự kiện / Chưa có dữ liệu" |
| Nguồn & lịch sử | 11 References · 12 Change history | Each reference: authority chip, date, revision, open preview |

Right panel (desktop) / bottom sheet (narrow): **Coverage** card — score, the missing items as
a checklist with "why it counts", and "Hỏi Copilot về tính năng này" (Phase 2).

Every claim line can carry a **source chip** (`D-150`, `insights.ts:72`, `hieu-con…md §9`).
Unsupported text shows a muted "Chưa có nguồn" marker instead of being hidden.

### 2.4 Plans & entitlements (`/product/plans`)

- **Comparison table**: rows = capabilities grouped by feature; columns = Free · Premium · Beta
  campaign; cells = included / limited (with limit) / not included. Data from `entitlements.ts`,
  `features-hub.ts`, `premium-v2.ts` defaults + the live `config/features` and
  `config/entitlements` read through a callable.
- **Three-layer badge per row** (brief §8): *Intended* (plan doc) · *Approved* (D-xxx) ·
  *Runtime* (code default / live config). Disagreement → a conflict row, linked to Sources.
- **Credits**: household pools Free/Premium (D-075 #1) with what consumes them.
- **History**: entitlement-relevant decisions and `staffAudit` tier changes (read only).
- A single link **"Thay đổi trong Tính năng & Premium"** → `/features`. This tab never writes.

### 2.5 Knowledge sources (`/product/sources`)

Two tabs-in-page (Segmented): **Thư viện** (library) and **Chờ duyệt** (review queue).

- Library table: Title · Path/type · Authority · Features · Freshness (synced / stale / missing)
  · Revision. Filters: type, authority, feature, freshness. Row → source page with rendered
  Markdown preview (sanitized), heading outline, linked features/decisions, versions, conflicts.
- Review queue: one row per change set from a sync run or an upload ("12 đổi, 3 mới, 1 xoá") →
  diff view (old/new chunk text side by side) with Approve / Reject per change set, plus
  per-feature link suggestions to accept or drop.
- Upload (Phase 1b): drop zone, multiple files, `.md .txt .pdf .docx`, 10 MB each, progress,
  processing state, archive / replace version. Hidden for staff without `product: edit`.
- Sync runs: list of runs (who, when, revision, counts, dry-run or applied).

### 2.6 Copilot (Phase 2)

- Global page: conversation list (left, collapsible) + thread. Feature page: same thread
  component in a side sheet, pre-scoped.
- Suggested questions under an empty thread (4, scoped to the page).
- Each answer: direct answer first; then **Nguồn** (citations, expandable to the chunk with
  path, heading, revision, authority, freshness); **Độ chắc chắn** line (verified / mixed /
  missing evidence); related feature links.
- "Lưu thành…" menu on an answer: Cơ hội · Cải thiện UX · Làm rõ quy tắc · Việc cần kiểm tra ·
  Giả thuyết — creates a **draft** in Decisions; never approved by the act of saving.

### 2.7 Journeys, Decisions, Insights (Phases 3–4)

Specified in [09](09-implementation-plan.md); they reuse the catalog table and the
specification layout.

## 3. Interaction and content rules

- One primary action per page (Overview: none; Catalog: none; Sources: "Đồng bộ"/"Tải lên";
  review: "Duyệt"). Secondary actions in menus.
- Status words, not colours alone; icons + text for verification.
- Dates: absolute (`31/10/2026`) with relative in tooltip, as elsewhere in the portal.
- No decorative illustration, no gradient, no AI sparkle styling; the Copilot uses the portal's
  normal surfaces.
- All copy in `apps/portal/src/messages-product-hub.ts` with identical vi/en ids; Vietnamese is
  the source, English drafted by engineering (D-012, D-104 applied to the portal).
- Product knowledge **content** (feature summaries, user problem text) is stored bilingual per
  field (`{vi, en}`) with `en` allowed to be missing — the UI shows vi with an "EN chưa có" chip
  rather than machine-translating silently.
