# 06 · Adaptive Today & navigation

## 1. What drives Today (recommendation)

Priority order, highest first. This is the existing engine's order made explicit, plus the slots from AXA-03.

1. **Eligibility**: the feature exists, flag on, role allows, data or content coverage exists for this child. Never surface a feature that is not usable.
2. **Explicit choices**: pinned (in pin order) → manual order → shown / hidden. Never overridden.
3. **Goals** for this child (0.35).
4. **Age band default** (0.25), frozen at `bandApplied` until the person accepts a stage card.
5. **Behaviour**: usage (0.20) and recency (0.10), frozen per app run, never moving a manual order.
6. **Product priority** (0.10, all 0 today). Keep at 0 until there is a reason; it is the lever for introducing a new feature, and it must decay (see [11 §4](11-personalization-architecture.md)).

**On the 35/25/20/10/10 hypothesis:** keep it. With goals and age at 60 %, behaviour cannot overturn intent, which is the property that matters. Do not tune it before there are D30 numbers by band; tune with the `adaptive_widget_opened` data, one change at a time.

## 2. Layout elements

| Element | Behaviour |
|---|---|
| Living Header (photo, greeting, child pill) | **Always visible** |
| Status banners (offline, sync, update) | **Event-triggered**, system |
| Tự lưu "ảnh mới" banner | **Event-triggered** (new candidates), dismissible |
| Cùng Chăm Con tasks | **Contextual** (assigned tasks exist), toggle in Tuỳ chỉnh |
| Stage card AX33 | **Event-triggered**, once per milestone |
| Ranked widgets | **Reorderable, pinnable, hideable** |
| EN01 invite | **Remove** on adaptive (AXA-02) |
| Tuỳ chỉnh Hôm nay link | **Always visible** (owner device test, plan §13 #2) |
| "Giao diện" row | **Always visible** at the end |

## 3. Five reference Todays

All share one structure: header → system/event slots → ranked widgets → Tuỳ chỉnh. Only the ranked part and the copy differ. Names are illustrative.

### 3.1 Newborn (Teddy, 3 weeks), goals skipped
- **Header:** photo or avatar, "Chào buổi sáng, Teddy ☀️", sub "Nhịp hôm nay của con, ghi nhanh trong một chạm."
- **Order:** Nhịp hôm nay (tiles + Sắp tới) → Dành cho bé hôm nay → Nhắc nhở → Kỷ niệm gần đây → Tăng trưởng. Ăn dặm absent (no coverage at 3 w; eligibility removes it).
- **Quick actions:** the tiles themselves (one-tap bottle presets, D-132).
- **Emotional:** first moment card if no photo yet ("Lưu khoảnh khắc đầu tiên").
- **Empty:** "+ Ghi lần đầu" pill per tile (built).
- **Why:** care is the job; frequency is high; one-handed at night.

### 3.2 8 months (Mây), goals = track_care, memories
- **Order:** Nhịp hôm nay → Dành cho bé hôm nay → Ăn dặm hôm nay → Nhắc nhở (vaccines due) → Kỷ niệm gần đây → Tăng trưởng.
- **Emotional:** monthly keepsake when m8 arrives (existing occasion).
- **Why:** care still daily, solids start, memory moments monthly.

### 3.3 2 years (Bơ), goals skipped
- **Order (b1_3 default):** Kỷ niệm gần đây → Ghi nhanh (ngủ, tã only) → Dành cho bé (to 24 m, then end-of-coverage state) → Nhắc nhở → Tăng trưởng.
- **Emotional:** "Hôm nay con lại khám phá thêm điều mới."; birthday keepsake near the 2nd birthday (**new occasion**, [10](10-memories-across-childhood.md)).
- **Empty:** if no photos, "Lưu khoảnh khắc đầu tiên" + Tự lưu offer.
- **Why:** memories lead, light logging stays one tap away.

### 3.4 5 years (Na), goals = memories, spending, family
- **Order:** Lưu khoảnh khắc hôm nay → Tạo từ kỷ niệm → Chi tiêu tháng này → Cả nhà cùng xem → Nhắc nhở.
- **No** Ghi nhanh, **no** Dành cho bé (no coverage), **no** Ăn dặm.
- **Emotional:** "Lưu lại một khoảnh khắc nhỏ — mai này sẽ thành câu chuyện lớn."; "Năm ngoái lúc này" when a photo from ±7 days a year ago exists (**proposal**).
- **Why:** input is occasional, output (videos, cards, sharing) is the value.

### 3.5 9 years (Bin), goals skipped
- **Order (b6_12 default):** Kỷ niệm gần đây → Nhắc nhở → Chi tiêu → Tăng trưởng.
- **Emotional:** year look-back on the birthday; Then & Now when photos span ≥ 3 years (**proposal**).
- **Copy:** "6+" framing; avoid "bé" in greetings (use the name).
- **Why:** weekly or event-driven use; records and memories.

## 4. Behaviour rules (existing, keep)

| Situation | Behaviour |
|---|---|
| Frequently used | Rises by usage, only in a ranked (untouched) layout |
| Rarely used | Stays where the age/goal put it; never auto-hidden |
| Recently completed | Recency bump for 48 h |
| Repeatedly dismissed suggestions | Personalization v2 `dislike` / "Không hợp" (D-102) for ideas; widgets are hidden only by the person |
| Pinned | First, in pin order, never moves |
| Changing interests | Goals editable; stage card suggests |
| Birthday | Nothing changes until the person presses Áp dụng |

## 5. Transitions (AXA-10)

- **Keep** AX33 as is (once, suggests, undo).
- **Add** a quiet retirement of first-run states: "Ghi lần đầu" pills disappear for a band where the tracker is off by default.
- **Add** a memory moment for the milestone ("Một năm của {tên}" story/video suggestion on the birthday week), separate from the layout card, so the emotional moment does not depend on accepting a layout change.
- **Never** move a pinned item, delete a widget, or change tabs at a birthday.

## 6. Empty states and introducing features

- One **"Có thể bạn cần"** row at most per Today, below the ranked list, from Khám phá's "Gợi ý cho {tên} lúc này", only for features with zero use and coverage for this child; dismiss = hidden for that child for 90 days (**proposal**, L2).
- Feature first-use empty states use the band's language (e.g. Chi tiêu for 5 y: "Học phí, đồ dùng, sinh nhật — ghi một lần, xem cả năm.").

## 7. Multi-child

**Fact:** everything is keyed by `babyId`; the experience doc is per person × child; switching shows a skeleton, toast "Đang xem {tên} · {tuổi}" and a 200 ms crossfade (plan §14); limit 3 managed profiles.
**Recommendations:**
- Tabs never change between children (they change by role only).
- Each child's Today follows its own band and goals; the person's pins are per child.
- Memories may later offer "Cả nhà" (all children) as an album filter; **DEFER** until families with 2+ children are measured.

## 8. Navigation: option A / B / C

| Option | Predictability | Discoverability | Cognitive load | Scalability | Verdict |
|---|---|---|---|---|---|
| A · Fully consistent, same content | High | Low (newborn content for all) | High for older kids | Low | No |
| B · Age-adaptive tabs | Low (tabs change at birthdays) | Medium | Medium | Low (new tabs per chapter) | No |
| **C · Stable tabs, personalised content and priority** | **High** | **High** (Khám phá has everything) | **Low** | **High** (new chapters add rows and widgets) | **Yes: already built** |

**Recommendation:** Option C, which is NavBar v2 + Khám phá (D-139). No navigation redesign. Care, Grow and Remember stay as **product concepts and Khám phá sections**, not tabs. Features outside the band stay discoverable through Khám phá search and groups; future capabilities appear only in "Cùng con lớn lên" as not yet available.
