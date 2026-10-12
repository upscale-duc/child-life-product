# Nhập chi tiêu (spending import) — plan (2026-10-12)

Owner request (2026-10-12): people who like Chi tiêu should be able to bring in spending kept
elsewhere, whatever its format, with a strict flow that tells them by email when it is done.
Not drawn in Figma; screens are built from existing components and flagged for design review.

## Decisions

Owner (2026-10-12), **D-060**:
- Sources: **CSV and Excel** files with the columns found automatically (other apps' exports — Money
  Lover, MISA Money Keeper —, Google Sheets / Excel, Child Life's own CSV), plus **pasted text and
  photos** read by AI (OpenAI behind the D-003 adapter; no baby name is sent).
- **Server-side**: preview first, then the server imports in the background, then **email + push**
  to the person who imported, with what was imported and what was skipped; **undo** for 7 days.
- **Cùng nuôi only.**
- Categories named in the file are **matched by name** (marks ignored, synonyms); the rest are chosen
  by the user (new category / an existing one / Khác). Rows that already exist (same day, amount
  and description) are skipped and listed.

Engineering defaults, **P-144** (owner to confirm):
- The phone reads the file (CSV in UTF-8 / UTF-16 with `,` `;` or tab; `.xlsx`, the sheet with the
  most rows) into a grid of text and uploads it as JSON (`imports/{uid}/{importId}.json`); the old
  binary `.xls` is not read (save as `.xlsx` or CSV). Limits: 10 MB file, 5 000 rows, 40 columns.
- The server finds the header row and the columns by name (vi / en keywords, known layouts) or by
  content (the column of dates, of amounts, the longest text). Days: ISO, `dd/mm/yyyy` (or
  `mm/dd` when the file says so), `12 thg 10, 2026`, `Oct 12, 2026`, Excel serials. Money: dots or
  commas, `₫ / đ / VND`, `500k`, `1tr2`, `2 triệu`, `(500.000)`, negatives. When a file mixes
  signs, spending is the negative rows by default (Money Lover); income rows are skipped. Other
  currencies are skipped. Future days are refused.
- AI: pasted text (≤ 20 000 characters) or up to 5 photos (JPEG ≤ 1600 px) become rows with day,
  amount, description, category, payer; they then go through the same preview. Without an API
  key the two AI sources say "AI chưa sẵn sàng".
- Imported expenses are ordinary expenses with `source: import` and `sourceRef` = the import id,
  recorded by the importer, a deterministic id per row (a retry never doubles), no receipt.
- Undo soft-deletes every expense of the import (edited ones too) within 7 days. Uploaded grids
  and photos are deleted after 7 days.
- The email and the push name no baby, no amount and no description (R-120); the email links to
  the result in the app. Neither is sent for an import that was undone.

## Flow

1. Chi tiêu → "Nhập" (Cùng nuôi): Tệp CSV / Excel · Dán văn bản (AI) · Ảnh chụp (AI); recent
   imports with their status.
2. The app uploads, then calls `analyzeSpendingImport`; the server writes the reading to
   `babies/{babyId}/spendingImports/{importId}` (status `ready`).
3. Review: columns found (each can be changed), the reading options when they matter (day order,
   which rows are spending), a preview with the problems, category and payer matching, counts.
   Every change re-reads on the server.
4. "Nhập N khoản" calls `confirmSpendingImport` (status `queued`); a trigger imports in batches
   (`importing`, progress), then `done` with counts and up to 200 row problems, or `failed`.
5. Email + push; the result screen offers "Xem chi tiêu" and "Hoàn tác lần nhập".

## Data

- `babies/{babyId}/spendingImports/{im_<32 hex>}` (Functions write, Cùng nuôi read): see
  `SpendingImportDoc` in `packages/contracts/src/spending-import.ts`.
- Storage `imports/{uid}/{importId}.json` and `imports/{uid}/{importId}/{n}.jpg`: the uploader
  writes, nobody reads from the client, Functions delete after 7 days.
