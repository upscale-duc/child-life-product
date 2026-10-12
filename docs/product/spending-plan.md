# Chi tiêu (spending) — review and plan (2026-10-12)

Source: Figma page **v1.1**, cluster "Chi tiêu" 8a–8o, transcribed in
[`../discovery/figma-extract/19-spending.md`](../discovery/figma-extract/19-spending.md). Owner decisions
D-055 … D-057; engineering defaults P-140 (both in [`business-map.md`](business-map.md)).

## Review (what the design asks for)

- A per-baby spending book reached from a **"Chi tiêu" tile** on Chăm sóc (8a), with a first-use screen (8j).
- **This month** (8b): month navigation, total vs the monthly budget, average per day, change vs the previous
  month, spending by category, recent expenses, shortcuts to Thống kê / Ngân sách / Định kỳ, "Thêm khoản chi".
- **Add expense** (8c): amount with suggestions ("Lần trước", +100.000, +500.000), category chips (edit / add
  category), description, who paid, date, receipt photo, "Lặp lại hằng tháng".
- **History** (8f) with search and filters; **detail** (8g) with edit, delete and a link back to a vaccine dose.
- **Statistics**: last 6 months (8d: monthly stacked bars, average line, by category, by payer) and since birth
  (8e: by month of age, largest items, CSV export).
- **Monthly budget** (8h): a standing total, optional caps per category, an 80 % alert to parents.
- **Recurring items** (8i): twice a month, every N weeks, yearly; added on the day, editable after.
- **Categories** (8m–8o): shared by every baby of the family; built-in and custom; reorder, hide / show,
  add / edit (name ≤ 24, 16 icons, 8 tints), delete with the expenses moved elsewhere; "Khác" cannot be deleted.
- **Vaccination** (8k): after a dose is recorded, "Ghi chi phí mũi tiêm?" saves an expense in Y tế & tiêm chủng.
- **Family** (8l): per member and per baby, "Ghi khoản đã chi" (sees only their own items) and "Xem toàn bộ
  chi tiêu" (totals, statistics, every item). Spending is otherwise only for parents.

Not drawn (engineering fills them in, P-140): empty month, over budget, offline / pending sync, errors, search
results, the date picker, the edit form, delete confirmation, the recurring add / edit form, caregiver and
relative variants, Night care (uses the tokens, as every screen).

## Decisions

Owner (2026-10-12):
- **D-055** Rights as 8l: Cùng nuôi have everything. Người chăm sóc and Người thân see nothing by default; per
  member and per baby a Cùng nuôi can turn on **Ghi khoản đã chi** (record, and see / edit only their own
  items) and **Xem toàn bộ chi tiêu** (read every item, totals, stats, budget). Extra rights stop being
  relative-only for these two.
- **D-056** "Ai trả" lists the baby's real members (by their label: Mẹ, Bố, Bà ngoại, Cô Lan…) plus **Khác**;
  the payer is kept as a snapshot so a departed member still reads right.
- **D-057** A recurring item is **added automatically** on its due day (server, in the baby's time zone) and
  stays editable; parents get a push. Full scope in one go.

Engineering defaults (P-140, owner to confirm):
- Money is whole VND (`int`, 1 … 1 000 000 000). Full form "1.020.000 ₫" (vi) / "1,020,000 ₫" (en); short form
  "4,2 tr" / "4.2M" with one decimal; under a million the full form.
- An expense has a **date** (no time) in the baby's zone. Months are calendar months in the baby's zone.
- "Trung bình/ngày" = month total ÷ days elapsed in the month (whole month for past months).
  "So với tháng trước" = this month to date vs the previous month over the **same number of days**.
- Categories live in the **family** (`families/{familyId}/spendingCategories`). The six built-ins (Giữ trẻ & học,
  Sữa & ăn dặm, Tã & vệ sinh, Y tế & tiêm chủng, Quần áo, Khác) are shown until written, then seeded with
  fixed ids by the first Cùng nuôi who edits. Only Cùng nuôi manage categories. Delete moves the expenses,
  recurring items and the budget cap into the chosen category (callable, all babies of the family).
- Budget: per baby, one standing monthly total and an optional cap per category. A category at ≥ 90 % of its
  cap reads "Gần chạm mức · còn …"; over it reads "Vượt mức …". The 80 % push goes once per month to Cùng nuôi
  who have spending notifications on; the copy has no baby name (R-120).
- Recurring schedules: monthly on one or two days, every N weeks from a start date, yearly on a date. "Lặp lại
  hằng tháng" in 8c creates a monthly item on that day. An occurrence is a normal expense with `source:
  recurring` and a deterministic id (no duplicates on retry).
- Vaccine cost (8k) is an expense with `source: vaccine` and `sourceRef` = the dose key; the amount is
  prefilled from the last expense for the same vaccine. The dose document is unchanged. Deleting the expense
  never touches the dose; the dose detail shows the linked cost.
- Receipts: JPEG ≤ 1600 px, ≤ 4 MB at `babies/{babyId}/expenses/{uuid}.jpg`, like vaccine photos; not counted
  in the family quota (as P-133); not in the CSV.
- CSV export is built on the device and shared with the share sheet; columns date, category, description,
  amount, payer, recorded by.
- Amounts, descriptions and receipts are never logged or sent to analytics.

## Data (contracts `packages/contracts/src/spending.ts`, rules, app models)

- `babies/{babyId}/expenses/{x_<32 hex>}`: amount, categoryId, note, spentOn (yyyy-MM-dd), payer
  ({uid?, name, relation, relationCustom} | null = Khác), receiptPath, source (manual | recurring | vaccine),
  sourceRef, createdBy, author, createdAt, updatedAt, updatedBy, deleted / deletedAt / deletedBy.
  Written by the app (offline outbox, like care records); soft delete.
- `babies/{babyId}/spending/budget`: monthlyTotal, caps {categoryId: amount}, alert80, alertedMonth (server).
- `babies/{babyId}/recurringExpenses/{rx_<32 hex>}`: title, categoryId, amount, payer, schedule
  ({kind: monthly, days[1..2]} | {kind: weeks, every, startOn} | {kind: yearly, month, day}), enabled,
  nextOn (server), createdBy, author, timestamps.
- `families/{familyId}/spendingCategories/{id}`: name, icon, tint, order, hidden, builtIn, locked.
- Membership `extraRights` gains `recordSpending`, `viewSpending` (any non-owner role).

## Build steps

1. Contracts, rules (+ emulator tests), storage rules, member rights (contracts, `updateMember`, 14f), money
   formatting, models, repository, providers.
2. 8a tile, 8j first use, 8b month, 8c add / edit, 8f history, 8g detail.
3. 8m–8o categories (+ `deleteSpendingCategory` callable).
4. 8k vaccine cost, 8l rights in the member sheet.
5. 8h budget (+ 80 % alert function), 8i recurring (+ daily function).
6. 8d / 8e statistics, CSV export.

## Built (2026-10-12, branch `spending`)

All of 8a–8o; nothing is marked done in the coverage checklist until it is verified on dev devices.

- App `apps/mobile/lib/features/spending/`: models, repository, money format, figures, 8a tile (anyone with a
  spending right), 8b / 8j, 8c, 8f, 8g, 8h, 8i (+ add / edit sheet), 8d / 8e (+ CSV), 8m–8o; 8k after a dose is
  first recorded as given (not for the commune station, which is free); 8l switches in the member sheet for
  Người chăm sóc and Người thân. Pushes (`kind: spending`) open `/care/spending` on the right baby.
- Server `firebase/functions/src/spending.ts`: `deleteSpendingCategory`, `addRecurringExpenses` (daily 00:30
  Asia/Ho_Chi_Minh, each baby's own day), `spendingBudgetAlert`; `updateFamilyMember` keeps a caregiver's two
  spending rights.
- Engineering choices made while building (owner to confirm with P-140):
  - 8c "Lặp lại hằng tháng" saves that day's expense and creates the monthly item with `lastOn` = that day,
    so the daily job starts from the next month (no double entry).
  - A paused recurring item still moves `lastOn` forward, so turning it back on never back-fills.
  - Spending pushes follow the "Nhắc việc" switch in Thông báo (no separate switch yet) and go to Cùng nuôi
    only; their copy has no title, amount or baby name.
  - 8e counts gear bought before the birth in the first month ("Tháng đầu gồm đồ dùng sơ sinh"); without the
    right to read the date of birth, months count from the first expense.
  - A recorder without "Xem toàn bộ" sees a list of their own items (no totals, budget or statistics).
  - Receipts use the vaccine photo pipeline (≤1600 px JPEG, no EXIF) under `babies/{id}/expenses/`.
