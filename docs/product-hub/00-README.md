# Product Hub · "Sản phẩm" — Phase 0

**Understand. Question. Improve.** An internal workspace in the staff portal that gives the
Product Owner one trustworthy, evidence-linked view of what Child Life does, why, how, how it is
monetized, and what to improve next.

Status (2026-10-31): **Phase 0 done; Phase 1 foundation built on the working tree, not yet deployed
or committed.** Owner defaults recorded as D-155. Built: PH1.0–PH1.6 and PH1.9 — contracts
and the `product` staff function, the 49-feature registry, the sync tool, submit/review/apply,
Overview, Catalog + feature page, Plans (read only), Sources + review queue. Not yet: the first
real sync on dev (PH1.7) and uploads (PH1.8). Guides:
[developer](guide-developer.md) · [chủ sản phẩm](guide-product-owner.md). Snapshot `e60e569b`.

| # | Deliverable | File |
|---|---|---|
| 1 | Repository discovery report | [01-repository-discovery.md](01-repository-discovery.md) |
| 2 | Feature inventory (49 features, 4 status fields, evidence) | [02-feature-inventory.md](02-feature-inventory.md) |
| 3 | Existing documentation inventory | [03-documentation-inventory.md](03-documentation-inventory.md) |
| 4, 8 | Information architecture + UX screen specifications | [04-information-architecture-and-ux.md](04-information-architecture-and-ux.md) |
| 5 | Data architecture (collections, coverage score, indexes, rules) | [05-data-architecture.md](05-data-architecture.md) |
| 6 | Knowledge ingestion architecture (sync, review, uploads, search) | [06-knowledge-ingestion.md](06-knowledge-ingestion.md) |
| 7 | AI Product Copilot architecture | [07-ai-copilot.md](07-ai-copilot.md) |
| 9 | Security and authorization | [08-security.md](08-security.md) |
| 10 | Phased implementation plan | [09-implementation-plan.md](09-implementation-plan.md) |
| 11, 12 | Risks, trade-offs, open questions | [10-risks-and-open-questions.md](10-risks-and-open-questions.md) |

## Five things to know

1. **Reuse, don't rebuild.** Staff auth and levels, `staffCall`, `staffAudit`, the draft-only
   `content-release.ts` publishing path, the OpenAI adapter, the portal UI kit and the
   "Tính năng & Premium" hub all exist. Product Hub adds a registry, a sync, a review queue and
   read views on top.
2. **Facts vs narrative.** Code facts come from a pinned revision through a trusted sync;
   product narrative is written by people (or drafted by AI) and counts only when approved.
   A sync never overwrites approved text; it marks it stale.
3. **Entitlements are read-only here.** Tiers and capabilities stay in contracts and
   `config/*`; changes stay in `/features`.
4. **Decisions stay in `business-map.md`.** The Hub mirrors D/R/P/Q/G by id and links them.
5. **Nothing is released yet**, so no feature is shown as "Released & Verified" and no usage
   numbers are shown until real data exists.

## Tóm tắt cho chủ sản phẩm

- Repo đã có rất nhiều thứ Product Hub cần: phân quyền staff, nhật ký thao tác, luồng "nháp →
  duyệt", công cụ đẩy nội dung từ repo lên Firebase, AI phía server, và hub "Tính năng &
  Premium". Product Hub dựng trên đó, không làm lại.
- Kiểm kê được **49 tính năng** (Chăm sóc 14, Lớn lên 8, Kỷ niệm 12, Trí tuệ & nền tảng 15).
  Mỗi tính năng có 4 trạng thái riêng: vòng đời, mức triển khai, mức kiểm chứng, phát hành.
  Hiện **chưa tính năng nào "đã phát hành"** vì app chưa go-live.
- Đã thấy xung đột thật để làm ví dụ: `plans-credits-analysis.md` đề xuất Free / Plus / Pro,
  còn quyết định và code là Free / Premium / Beta (D-075, D-089). Product Hub sẽ hiện cả hai và
  không tự chọn.
- Một phụ thuộc dễ bị bỏ sót: "Hiểu con" là Premium nhờ quyền `rhythm.advanced` của tính năng
  "Cá nhân hoá", nên đổi gói của "Cá nhân hoá" cũng đổi gói của "Hiểu con".
- Cần anh/chị quyết **10 câu hỏi** (Q-PH-01…10, có đề xuất mặc định) trước khi bắt đầu Phase 1,
  quan trọng nhất là: thêm quyền `product` cho staff (Q-PH-01), tên mục "Sản phẩm" (Q-PH-02) và
  ai được duyệt tri thức (Q-PH-04).
- Phase 1 ước khoảng 18–19 ngày kỹ thuật. Xong Phase 1, chủ sản phẩm duyệt được cấu trúc sản
  phẩm đã kiểm chứng mà không cần hỏi dev.
