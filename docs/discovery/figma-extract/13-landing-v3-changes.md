# 13 — Landing v3 vs v2: changes to the existing sections

Figma file `sJLG1fAXKDnDr9YI6Yx8ex` (read-only). Extracted 2026-10-10.

- Old: "Landing · Desktop v2" `219:1391` (1440 × 7734.2) / "Landing · Mobile v2" `233:804` (375 × 9272.5) — implemented in `apps/landing`, spec `11-landing-specs.md`.
- New: "Landing · Desktop v3" `321:1222` (1440 × 12267.2) / "Landing · Mobile v3" `324:45487` (375 × 14466.9).

Scope: only the 11 sections that exist in both versions (Nav, Hero, Thao tác nhanh, Chăm sóc, Cùng chăm, Tuổi thơ, Night care, Quyền xem, CTA, Hỏi đáp, Footer). The five new v3 sections (Mọi thứ trong một app, Nhắc nhở, Hiểu con, Thư viện & ăn dặm, Sơ cấp cứu) are covered separately.

Method:
1. Metadata geometry diff of every node (name/type/x/y/w/h, sequence-aligned) for each of the 22 section pairs (11 desktop + 11 mobile).
2. `get_design_context` (rendered text is authoritative) on every desktop v3 section, and on the mobile v3 Nav, Hero and Hỏi đáp. The other mobile v3 sections have node trees and geometry identical to mobile v2, and their desktop counterparts have unchanged text.

> **Layer names are stale and are the same in v2 and v3.** For example, the hero eyebrow layer is named "Ứng dụng chăm bé & lưu kỷ niệm" but renders "●  Miễn phí cho cả gia đình". The H1 layer is named "Mỗi ngày của con, cả nhà cùng…" but renders "Cùng chăm con. / Giữ từng khoảnh khắc / con lớn lên.". The caption layer is named "Miễn phí cho cả gia đình · 10…" but renders "Miễn phí trên iPhone và Android.". The proof layer is named "Ba, mẹ, bảo mẫu và ông bà…" but renders "Ba mẹ, người chăm và ông bà — …". These names are identical in v2 `219:1416–1435`, so they are **not** v3 copy changes. In the hero, only the **lead** text changed.

---

## 0. Summary

| # | Section | Desktop v2 → v3 node | Mobile v2 → v3 node | Change |
|---|---|---|---|---|
| 1 | Nav | 219:1392 → 321:1223 | 233:805 → 324:45488 | Desktop link 4 "Ban đêm" removed; new link 2 "Hiểu con" inserted. Mobile unchanged. |
| 2 | Hero | 219:1413 → 321:1235 | 233:818 → 324:45492 | **Lead copy changed** (desktop 2 → 3 lines, mobile 3 → 4 lines). Everything else unchanged. |
| 3 | Thao tác nhanh | 231:162 → 321:1287 | 233:860 → 324:45534 | None. |
| 4 | Chăm sóc | 220:1801 → 321:1335 | 233:995 → 324:45571 | None. |
| 5 | Cùng chăm | 220:1918 → 321:1368 | 233:1027 → 324:45603 | Desktop: **panel moved to the left, copy to the right** (mirrored). No text change. Mobile unchanged. |
| 6 | Tuổi thơ | 232:627 → 321:1414 | 233:1072 → 324:45648 | None. |
| 7 | Night care | 221:2845 → 321:1533 | 233:1296 → 324:45773 | None. |
| 8 | Quyền xem | 221:3347 → 321:1570 | 233:1336 → 324:45811 | None. |
| 9 | CTA | 221:3443 → 321:1650 | 233:1430 → 324:45889 | None. |
| 10 | Hỏi đáp | 221:3455 → 321:1672 | 233:1448 → 324:45907 | Q5 "Có dùng được trên Android không?" was replaced by "Nội dung gợi ý trong app do ai soạn?". **Desktop only:** new Q6 "Lịch Wonder Week có đúng với mọi bé không?". Neither new question has an answer in Figma. |
| 11 | Footer | 221:3488 → 321:1700 | 233:1477 → 324:45931 | None. |

**Section order.** The 11 shared sections keep their relative order. v3 inserts the new sections between them:

| Desktop v3 | y | h | | Mobile v3 | y | h |
|---|---|---|---|---|---|---|
| Nav | 0 | 87 | | Nav | 0 | 66 |
| Hero | 87 | 792 | | Hero | 66 | **859.2** (was 827.2) |
| *Mọi thứ trong một app (new)* | 879 | 1080 | | *M · Mọi thứ (new)* | 925.2 | 926 |
| Thao tác nhanh | 1959 | 1106 | | Thao tác nhanh | 1851.2 | 1198.7 |
| Chăm sóc | 3065 | 760 | | Chăm sóc | 3049.9 | 898.1 |
| *Nhắc nhở (new)* | 3825 | 760 | | *M · Nhắc nhở (new)* | 3947.9 | 786 |
| Cùng chăm | 4585 | 728 | | Cùng chăm | 4733.9 | 852.1 |
| *Hiểu con (new)* | 5313 | 1093 | | *M · Hiểu con (new)* | 5586.0 | 1897.4 |
| *Thư viện & ăn dặm (new)* | 6406 | 760 | | *M · Thư viện (new)* | 7483.4 | 828 |
| *Sơ cấp cứu (new)* | 7166 | 760 | | *M · Sơ cấp cứu (new)* | 8311.4 | 725 |
| Tuổi thơ | 7926 | 1499 | | Tuổi thơ | 9036.4 | 2136 |
| Night care | 9425 | 688 | | Night care | 11172.4 | 656.3 |
| Quyền xem | 10113 | 831 | | Quyền xem | 11828.7 | 1375 |
| CTA | 10944 | 415 | | CTA | 13203.7 | 361.4 |
| Hỏi đáp | 11359 | **724** (was 644) | | Hỏi đáp | 13565.1 | 749 |
| Footer | 12083 | 184.2 | | Footer | 14314.1 | 152.8 |

**Strings in `vi.ts` that v3 Figma still contradicts.** These are unchanged in v3, so the existing PROPOSED overrides stay as they are:
- `memories.tiles.family.notifications[1].text`: Figma still says "Ông ngoại đã xem 12 ảnh mới" (Q-009).
- `roles.cards[1].permissions[1]`: Figma still says ✓ "Gửi ảnh bé cho ba mẹ, không xem album riêng" (Q-008).
- `roles.notes[0]`: Figma still says "Ảnh mới mặc định chỉ ba mẹ thấy. Muốn khoe cả nhà, bạn chỉ cần chọn "Gia đình"." (D-001, R-171).
- FAQ answers for Q3 and Q4: still absent from Figma (G-065).

---

## 1. Nav

### Desktop 321:1223 (1440 × 87, unchanged)
| Key (`vi.ts`) | v2 (old) | v3 (new) |
|---|---|---|
| `nav.links.care` | Chăm con | Chăm con (unchanged, position 1) |
| — (new, position 2) | — | **Hiểu con** |
| `nav.links.memories` | Kỷ niệm (position 2) | Kỷ niệm (position 3) |
| `nav.links.family` | Gia đình (position 3) | Gia đình (position 4) |
| `nav.links.nights` | Ban đêm (position 4) | **removed** |
| `nav.links.faq` | Hỏi đáp | Hỏi đáp (unchanged, position 5) |
| `nav.download` | Tải miễn phí | Tải miễn phí (unchanged) |

New verbatim order: **"Chăm con" · "Hiểu con" · "Kỷ niệm" · "Gia đình" · "Hỏi đáp"**.

Layout:
- The links row is now 462 wide at x 709 (v2: 464 at x 707). Link widths: Chăm con 75, Hiểu con 64, Kỷ niệm 58, Gia đình 62, Hỏi đáp 59. Gap is still 36.
- The flex spacer grows from 435.1 to 437.1.
- Style is unchanged: Medium 15 `ink-muted`; CTA `ink` pill `12px 22px`, SemiBold 15 `surface`.

Implementation notes:
- `apps/landing/src/components/Chrome.tsx` `sectionIds` is currently `['cham-con','ky-niem','gia-dinh','ban-dem','hoi-dap']`. Change it to `['cham-con','hieu-con','ky-niem','gia-dinh','hoi-dap']`, where `#hieu-con` points to the new "Hiểu con" section (desktop `324:45334`, mobile `325:2533`).
- Replace the `nav.links.nights` key with a new key, for example `nav.links.understand`, in `types.ts`, `vi.ts` and `en.ts`. English draft for owner review: "Understand" or "Development". The current EN for `nights` is "Nights".
- The Night care section loses its nav anchor. It can keep `id="ban-dem"` for deep links.

### Mobile 324:45488 (375 × 66)
Unchanged: logo lockup at 0.78 scale plus a `mint-deep` "Tải app" pill. There are still no links and no menu.

---

## 2. Hero

### Desktop 321:1235 (1440 × 792; section height unchanged)
| Key | v2 (old) | v3 (new) |
|---|---|---|
| `hero.eyebrow` | ●  Miễn phí cho cả gia đình | unchanged |
| `hero.title` | Cùng chăm con. / Giữ từng khoảnh khắc / con lớn lên. | unchanged |
| `hero.lead` | Một không gian riêng tư cho cả nhà: cùng chăm con, lưu ảnh, video, câu chuyện và nhìn lại hành trình con lớn lên. | **Một không gian riêng tư cho cả nhà: ghi bú, ngủ trong một chạm, nhắc đúng lúc, gợi ý theo từng tuần tuổi — và giữ lại mọi khoảnh khắc con lớn lên.** |
| `hero.caption` | Miễn phí trên iPhone và Android. | unchanged |
| `hero.proofInitials` | M B L H | unchanged |
| `hero.proof` | Ba mẹ, người chăm và ông bà — ai cũng có chỗ của mình bên con | unchanged |
| `stores.*` | Tải trên / App Store, Tải trên / Google Play | unchanged |
| `hero.chips[0]` | Bú bình · 120 ml / Mẹ ghi · 2 phút trước | unchanged |
| `hero.chips[1]` | Bà nội thương ảnh của Teddy / vừa xong | unchanged |

The lead uses an em dash "—" with spaces.

Layout changes, all caused by the longer lead:
- Lead `321:1240` grows from 64 to **96** tall (2 → 3 lines at 608 wide, Medium 20/32 `ink-muted`).
- The Copy column `321:1236` grows from 537 to **569** tall. It is still vertically centred in the row, so its top moves from y 107.5 to **91.5**. Hero padding and the 792 height are unchanged.
- Download block y moves from 374 to 406; Proof y moves from 499 to 531. The gap is still 28.
- Visual `321:1267` (600 × 640 at 744, 56) is identical: same circle, the two phones with the same snapshots (`Snapshot · 7a Hôm nay · Người chăm sóc · Light`, `Snapshot · 10d Kỷ niệm · Album · Light`), and the same chips, positions and photo tones.

Implementation note: the CSS needs no change if the copy column is flex-centred. Only the string changes.

### Mobile 324:45492 (375 × **859.2**, was 827.2)
- Same new lead string, Medium 16/32, now **4 lines → 128 tall** (was 3 lines, 96).
- Download moves from y 319 to 351 and Visual from y 421.9 to 453.9. The section is +32 taller.
- Eyebrow, H1 (31/1.12), badges, caption (13) and the visual at 0.5583 scale are unchanged. There is still no proof row.

### English (`en.ts` `hero.lead`) — draft for owner review
Current: "A private space for the whole family to share the care and keep the photos, videos and stories of your baby growing up."
Draft: "A private space for the whole family: log feeds and sleep in one tap, get reminders at the right time and tips for every week of age — and keep every moment of your baby growing up."

The `meta.description` copy (not in Figma) may also be worth aligning with the new lead (reminders, weekly tips).

---

## 3. Thao tác nhanh ("Khi bận tay") — no change
Desktop `321:1287` (1440 × 1106), with Head `321:1288`, Stage `321:1293` and Steps `321:1316`. The full text and geometry were re-read and are identical to v2, including `quick.eyebrow/title/lead`, both labels, all widget texts, the note chip, the lock screen and the 3 steps. The step 3 sub still uses straight quotes in Figma: `Không ai phải hỏi lại "con ăn chưa?"`.
Mobile `324:45534` has identical geometry (1198.7; steps still fixed at 40 tall in Figma).

## 4. Chăm sóc — no change
Desktop `321:1335`, Row `321:1336`: panel left (640 × 600 `mint-soft`), copy right. All strings in `care.*` are identical, including the CareTiles, chip, DayRhythm, bullets, H2 width 560 and lead width 460.
Mobile `324:45571` is identical (Head → Bullets → Visual).

## 5. Cùng chăm — layout mirrored (desktop)

### Desktop 321:1368 (1440 × 728, unchanged)
| Item | v2 | v3 |
|---|---|---|
| Row children order | Copy (x 0) → Panel (x 608) | **Panel (x 0) → Copy (x 736)** |
| Copy column | 512 × 440 at (0, 80) | 512 × 440 at **(736, 80)** |
| Panel | 640 × 600 at (608, 0) | 640 × 600 at **(0, 0)** |
| Row gap / padding / heights | 96 / `64px 96px` / 600 | unchanged |

Panel internals are identical (`sunshine` bg, Illustration/Family at (67.79, 0), initials, star, "Bạn chọn quyền" FloatChip, Feed card at (32, 362)). All `cocare.*` strings are unchanged:
- "Cùng chăm"
- "Cả nhà cùng chăm, không ai phải hỏi lại."
- The lead (straight quotes in Figma `"con ăn lúc mấy giờ?"`)
- The 3 bullets
- The feed rows

In v3, Chăm sóc (panel-left) is now followed by the new Nhắc nhở and then Cùng chăm (panel-left again). The mirror follows the new sections' alternation, not a copy change.

Implementation: in `apps/landing/src/sections/Cocare.tsx`, add `split--visual-first` to the section class (as `Care.tsx` does), so the visual is ordered first at ≥ 1120 px.

### Mobile 324:45603 (375 × 852.1)
Unchanged: Head → Bullets → Visual (copy-first; the visual is not moved above).

## 6. Tuổi thơ ("Kỷ niệm") — no change
Desktop `321:1414` (Head `321:1415`, Timeline `321:1420`, Tiles `321:1479`). Identical text and geometry: all 7 timeline cards, rotations, the end label "…và mọi năm sau nữa", and the 3 tiles. Tile 3 still shows "Ông ngoại đã xem 12 ảnh mới" (the `vi.ts` PROPOSED override for Q-009 stays).
Mobile `324:45648` is identical.

## 7. Night care — no change
Desktop `321:1533` / card `321:1534`: identical copy ("Cho những đêm thức giấc", "Dịu mắt cho những cữ bú lúc nửa đêm.", lead, 2 checks) and an identical visual.
Mobile `324:45773` is identical.
Only change: it is no longer a nav target (see §1).

## 8. Quyền xem ("Riêng tư") — no change
Desktop `321:1570`: identical head, 3 role cards and 2 notes. Figma still has the caregiver ✓ "Gửi ảnh bé cho ba mẹ, không xem album riêng" and note 1 "Ảnh mới mặc định chỉ ba mẹ thấy…". The `vi.ts` overrides for Q-008 and D-001 stay.
Mobile `324:45811` is identical.

## 9. CTA — no change
Desktop `321:1650`: "Bớt phải nhớ." / "Thêm thời gian bên con."; "Miễn phí trên iPhone và Android. Mời cả nhà chỉ trong một phút."; light badges; caption "Miễn phí cho cả gia đình".
Mobile `324:45889` is identical (no caption).

## 10. Hỏi đáp

### Desktop 321:1672 (1440 × **724**, was 644)
The title, subtitle and left column are unchanged: "Câu hỏi thường gặp" and "Còn điều gì băn khoăn? Cứ nhắn cho chúng tôi nhé.".

| # | Default state | Key (`vi.ts`) | v2 question (old) | v3 question (new) | v3 answer in Figma |
|---|---|---|---|---|---|
| 1 | **open** (chevron-down) | `faq.items[0]` | Child Life dành cho bé từ mấy tuổi? | unchanged | unchanged: "Từ ngày con chào đời. Những năm đầu, app giúp bạn chăm con mỗi ngày; khi con lớn hơn, đây là nơi giữ lại ảnh và câu chuyện của con." |
| 2 | **open** (chevron-down) | `faq.items[1]` | Có mất phí không? | unchanged | unchanged: "Không. Cả gia đình dùng miễn phí, đủ chỗ cho hàng nghìn ảnh của con. Cần thêm chỗ, bạn chỉ cần nhắn cho chúng tôi." |
| 3 | closed (plus) | `faq.items[2]` | Ông bà không rành điện thoại có dùng được không? | unchanged | none (G-065; the `vi.ts` PROPOSED answer stays) |
| 4 | closed (plus) | `faq.items[3]` | Ai được xem ảnh và thông tin của con? | unchanged | none (G-065; the `vi.ts` PROPOSED answer stays) |
| 5 | closed (plus) | `faq.items[4]` | Có dùng được trên Android không? | **Nội dung gợi ý trong app do ai soạn?** | **none — new gap** |
| 6 | closed (plus) | — (new `faq.items[5]`) | — | **Lịch Wonder Week có đúng với mọi bé không?** | **none — new gap** |

- The Android question (and the `vi.ts` PROPOSED answer "Có. Child Life có trên cả iPhone và Android…") is **removed**.
- Item style is unchanged (`surface`, 1 px `separator`, radius 20, `22px 24px`, SemiBold 17 / Medium 15 at 1.55).
- The list grows from 500 to 580: the new item is 808 × 68 at y 512, with gap 12. The Row grows from 500 to 580 and the section from 644 to 724.
- Items 1–2 open and 3–6 closed by default, as in v2.

### Mobile 324:45907 (375 × 749, unchanged)
- Same as desktop for items 1–5: Q5 is now "Nội dung gợi ý trong app do ai soạn?" and the Android question is gone.
- **There is no 6th item on mobile.** "Lịch Wonder Week có đúng với mọi bé không?" is desktop-only in Figma. This is probably a designer oversight; recommend showing the same 6 questions on both breakpoints (owner to confirm).
- Item style is unchanged (`22px 18px`, SemiBold 16, answers Medium 14/1.55). There is still no subtitle. Items 1–2 are open.

Implementation:
- `content/types.ts` `faq.items` is a 5-tuple. It needs 6 entries; or render the 6th only at ≥ desktop if the owner wants Figma parity.
- Both new questions need answer copy (owner and medical/content review). The Wonder Week answer in particular makes a developmental claim. Suggested new gap id: extend G-065.

English drafts for owner review:
- Q5: "Who writes the tips in the app?"
- Q6: "Is the Wonder Weeks calendar right for every baby?"

## 11. Footer — no change
Desktop `321:1700`: divider, lockup at 0.8, "© 2026 Child Life", and "Quyền riêng tư" · "Điều khoản" · "Liên hệ".
Mobile `324:45931` is identical.

---

## Changes required in `vi.ts` / `en.ts` (existing keys only)
| Key | Action | New `vi` value |
|---|---|---|
| `nav.links.nights` | remove | — |
| `nav.links.<new>` (e.g. `understand`), inserted 2nd | add | `Hiểu con` |
| `hero.lead` | replace | `Một không gian riêng tư cho cả nhà: ghi bú, ngủ trong một chạm, nhắc đúng lúc, gợi ý theo từng tuần tuổi — và giữ lại mọi khoảnh khắc con lớn lên.` |
| `faq.items[4].q` | replace | `Nội dung gợi ý trong app do ai soạn?` (answer: none in Figma) |
| `faq.items[4].a` | replace | answer needed (old Android answer dropped) |
| `faq.items[5]` | add (`open: false`) | q `Lịch Wonder Week có đúng với mọi bé không?`; answer needed; desktop-only in Figma |

Layout/code: in `Chrome.tsx`, change the nav ids to `hieu-con` and drop `ban-dem`. In `Cocare.tsx`, add `split--visual-first` (desktop only; mobile stays copy-first).
