# Galleries and memories

Memories is not a care tracker: it should feel warm, visual and personal, while staying fast to
navigate and unambiguous to operate. **Don't turn a memory screen into a data dashboard.**

## 1. What exists (verified in rendered goldens)

| Surface | Golden | Composition | Status |
|---|---|---|---|
| Memories tabs | `s9/10a_journal`, `10b_photos` | Big title tabs "Ảnh · Album · Nhật ký · Câu chuyện" (scroll; the 4th is cut off at 375 pt); header filter + "+" | Implemented |
| Journal (Nhật ký) | `s9/10a_journal`, `journal/*` | Week headers ("Tuần thứ 4 · 8–14 tháng 10 · 1 ảnh"); entry cards: author, time, audience icon, text, media (1 / 2 / 3–4 / 5+ layouts, `MemoryEntryCard`) | Implemented |
| Photos grid | `s9/10b_photos`, `v1i_10b_by_age_month` | Grouped by week or age; 4-column grid; video duration badge; favourite mark | Implemented |
| Selection mode | `s9/10b2_select` | Circle checks top-right, "Chọn tất cả" per group, "Xong" pill; floating bar "5 mục đã chọn" with share and delete | Implemented |
| Albums | `s10/10d_albums`, `10e_album_detail` | Covers with shadow (`ClTileShadow`) | Implemented |
| Viewer | `s10/10f_viewer_thread` | Full-screen media + comments | Implemented |
| Upload queue | `s9/10i_queue_states`, `10a_pill_*` | Pill on the tab; queue states (`QueueState`) | Implemented |
| Memory Story video (UI: "Video kỷ niệm") | `mm/mm06_photos` → `mm07_finish` → `mm08_rendering` → `mm09_ready` / `mm14_failed` | Scene slots ("6/8 cảnh đã có ảnh · Tối thiểu 6"), photo source switch, suggestions per scene, bottom count + "Tiếp tục" | Implemented |
| Milestone cards (UI: "Thiệp cột mốc"; internal "Milestone Magic") | `mm/mm10_choose`, `mm11_edit`, `cards_all_formats` | Occasion chips, format segmented (4:5 / Vuông / Story 9:16), template grid with "Cao cấp" badges | Implemented; new templates in `docs/product/remember-2-templates.md` are **Proposed** |
| Stories (articles) | `s12/14a_stories` … `14h_share` | Editor, photos, preview, share | Implemented |

## 2. Patterns

| Need | Pattern |
|---|---|
| Browse many photos | A grid grouped by a meaningful period (week of life, month, age): the group header carries the period and the count |
| Tell a story over time | The journal: entry cards with the author, relative time and the audience, media sized by count |
| Feature a moment | One large card (a milestone, "Hôm nay {name} tròn…") above the grid, at most one |
| Albums | Cover-first tiles with name + count; the empty album gets one invitation |
| Video preview | Poster + duration badge (`PlayGlyph`, "0:42"); never autoplay in grids |
| Choose a template | Previews show the real result with the baby's data; filters by occasion and format; Premium items marked, still previewable |
| Pick media for a story | A slot model ("cảnh") showing progress and the minimum; the selection count pinned at the bottom with the primary |
| Uploading / processing | Pill or tile overlay with an honest state (`screen-states.md` §2: uploaded ≠ ready) |
| Empty | `ClEmptyState` with the first action ("Chạm + để thêm ảnh…", `memEmptyBody`) |

## 3. One gesture, one meaning: modes must be visible

A media item can **open, select, edit, add to a story, download or share**. At any moment exactly
one mode is active, and the UI must show which:

| Mode | Visual signal (current implementation) |
|---|---|
| Browse (tap = open) | Plain tiles; no check circles |
| Select (tap = toggle) | Check circles on every tile; "Xong" to exit; selection bar with a count and actions |
| Fill a slot (Memory Story) | The active slot is outlined; tapping a photo fills that slot |
| Pick for a story / template | A count + limit at the bottom ("Đã chọn 6 ảnh · Có thể thêm 2") |

**Rules:**

- **A selection control never looks like an add or create action.** Circles or checks for
  selection; "+" only for adding new content.
- **While selecting, hide or disable unrelated creation affordances.** Hypothesis from
  `s9/10b2_select`: the header "+" stays visible during selection; verify the intent before
  changing.
- **The selection bar must not cover the items being selected.** Rendered in `s9/10b2_select`:
  the floating bar overlaps a grid row. Leave scroll padding under the last row.
- **Long-press = enter selection** (where supported). Keep it discoverable through a visible
  "Chọn" entry.

**Don't add new behaviours** (e.g. tap-to-select by default, swipe-to-delete on media) without
approval.

### Review grids and bulk selection (lesson from AS07 Tự lưu review, owner 2026-10-26, D-123)

Three patched attempts failed on this screen: a sheet of one-shot commands, then a stateful
"Chọn nhanh" sheet with a footer status line, then hidden near-copies counted as tiles. The
owner's verdicts:
- "chọn mấy option … ko biết là đã chọn gì … rất ko tính liên kết";
- "tiếp tục với 18 mục mà tất cả có 14 mục";
- "làm đi làm lại vẫn ko đúng và khó hiểu";
- "hai cái tabbar … chiếm nhiều diện tích".

The model that worked:

- **One unit everywhere.** Every file is a tile, and every number counts files: filters, week
  pill, 📷 / 🎬, and "Tiếp tục với n mục". Never mix "tiles" (a group counted as one) with
  "files" on the same screen.
- **Nothing that can be sent is hidden.**
  - Show near-copies together in a tinted block: "n ảnh giống nhau · đã chọn k", the app's pick
    tagged ("Rõ nhất") and pre-ticked, and one link "Chọn cả nhóm" / "Chỉ giữ ảnh rõ nhất". Not
    behind a "+n" badge.
  - Put guesses the person may overrule ("Đã có") in a folded section at the end, with a
    one-line hint. Never use a hide toggle in a sheet.
- **The ticks are the state.** Prefer inline controls (group links, one top-bar "Chọn hết / Bỏ
  chọn hết") over a bulk-selection sheet. A sheet holding selection modes separates the cause
  from its effect. If a sheet is unavoidable:
  - derive its state from the data (radio, plus "Tự chọn" when nothing matches);
  - update it in place;
  - say the active state next to the result.
- **An automatic guess** (duplicate, "Đã có", best of a group) **is a default, never a lock.**
  The person can open and tick each item.
- **Filters take one row.** Two stacked bars (chips + segmented) cost about 110 pt above the
  photos. Use `ClFilterPill`s side by side ("Tuần 6 · 14 ▾", "Ảnh & video · 14 ▾"), each opening
  a radio sheet, as on Kỷ niệm Ảnh.
- **The footer is visual, not prose.**
  - Show what will be sent as icons and numbers (📷 3 · 🎬 2 · ~0,7 GB), with the sentence kept
    as the semantics label.
  - Don't repeat the count that the CTA already says.
- **Count in the reader's terms, and don't make them compute.**
  - "Chờ bạn xem" means not yet saved, so leave out what seems saved already ("Đã có").
  - The counts on the filters are the waiting files; the CTA says how many will go. Anything
    optional the person ticks simply grows the CTA.
  - The owner removed a "5/6" ratio and a "Chưa chọn: 1 ảnh giống nhau" line as noise: show only
    what has not been uploaded, plus the CTA.
- **When fixes keep failing, stop patching and re-analyse the model** (units, what is hidden,
  where the state lives) before touching widgets.
- **Verify by tapping through.** Assert in widget tests that every count on screen agrees after
  each action, and render the folded and opened states.

## 4. Visual richness with performance

- **Photos are the hero.** Keep chrome quiet (thin meta, `caption` muted), and use warm accents
  only on memory screens (`ClChip` warm / sun).
- **Thumbnails load the small rendition first** (`MediaTile` loads the display rendition only
  when the tile is large).
- **Never decode full images in grids.**
- **Grids use fixed column counts today (3 / 4 / 5 per screen).** Keep the same count within a
  flow; an extent-based grid is a `cl-components` candidate.
- **Text over photos needs a gradient scrim** (foundations, photo overlays).

## 5. Accessibility

- **Each tile reads as one item:** "Ảnh, Tuần thứ 3"; "Video 0 phút 42 giây". Selected state is
  announced; group headers are headers.
- **Actions in the selection bar are labelled** (share, delete); destructive actions confirm or
  offer undo (`confirmDeleteMedia`, 30-day recovery).
- **Audience and privacy** ("Ai thấy") are visible on entries (the audience icon). Never hide who
  can see a memory.
