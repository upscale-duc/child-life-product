# Chi tiêu currencies — plan (2026-10-15)

Owner decision **D-075 #4** ("Chi tiêu gets other currencies — app phục vụ nước ngoài nữa", resolves
Q-077). Engineering choices are **P-162** in [`business-map.md`](business-map.md), owner to confirm.
Not drawn in Figma: the picker, the "Tiền tệ chính" row and the "Ngoài ra" lines reuse existing
components and are flagged for design review.

## Data

- `currency` (ISO 4217) on `babies/{b}/expenses/{x}`, `recurringExpenses/{rx}` and
  `spending/budget`. **Optional**: a document without it is VND, so everything written before and
  every old app (which keeps writing VND without the field) stays valid. This app always writes it.
- `amount` (and budget totals / caps) is an integer in the currency's **minor units** with the ISO
  exponent: VND 0 (đồng, unchanged), USD / EUR / … 2 (cents), JPY / KRW 0.
- 16 currencies, each with a ceiling in minor units (`currencyInfo` in
  `packages/contracts/src/spending.ts`, Rules `currencyMax()`, app `spCurrencies` — keep the three
  in step): VND 1 000 000 000 (as before), USD / EUR / GBP / CHF 1 000 000.00, AUD / CAD / NZD / SGD
  2 000 000.00, JPY ¥200 000 000, KRW ₩2 000 000 000, TWD / THB 50 000 000.00, HKD / CNY
  10 000 000.00, MYR 5 000 000.00.
- Household currency: `families/{f}/spendingSettings/main` `{currency, updatedAt, updatedBy}`. Read
  by anyone with a spending right on one of the family's babies, written by any **Cùng nuôi** (like
  the categories; the brief's "set by the owner" read as the parents). Unset → the family's country
  (`currencyForCountry`, D-072 #3 country) → VND.

## Behaviour

- **Add / edit (8c), vaccine cost (8k), recurring (8i)**: the amount shows the currency's sign as a
  picker ("₫ ▾"); default the household's (8k: the last cost's currency). Decimal keypad for
  currencies with cents; "+100.000 / +500.000" become "+10 / +50" whole units; "Lần trước" only in
  the same currency. Changing currency keeps the whole number typed.
- **Totals never add two currencies.** 8b, Hôm nay, Tiện ích, 8d / 8e count the household currency;
  other currencies show apart ("Ngoài ra: 2.000 ¥ · 12,50 $", "Không cộng vào tổng (tiền tệ khác)");
  the recent list and history rows show every item in its own currency; a day header and the
  category-delete sheet list one total per currency. No conversion anywhere.
- **Budget (8h)**: carries a currency (the household's when saved) and counts only that currency;
  the server's 80 % push sums the budget currency only. The screen starts with the "Tiền tệ chính"
  row (Cùng nuôi change it there). If the household changes currency, the old budget is no longer
  shown on 8b and the budget screen starts empty with a note until saved again.
- **Formatting** (intl, by locale): VND exactly as before ("1.020.000 ₫" / "1,020,000 ₫", "4,2 tr");
  others with their decimals and a symbol that tells the dollars apart ($, A$, C$, NZ$, S$, HK$, NT$,
  CN¥…): "12,50 $" (vi) / "$12.50" (en); compact from 10 000 units.
- **CSV export**: a "Tiền tệ / Currency" column after the amount; the amount is plain in the
  currency's units ("12.50", "1020000").
- **Import (D-060)**: a row keeps the currency it names (amount cell or currency column: codes,
  ₫ đ € £ ₩ ฿ US$ S$ NT$ RM…); "$" alone is the household's dollar if it uses one, else USD; "¥"
  alone is CNY for a CNY household, else JPY. Rows naming nothing are in the household currency
  (stored on the import as `currency`, so a later household change does not alter a previewed
  import). A currency Chi tiêu does not keep (INR, IDR…) is still skipped as `other-currency`.
  Duplicates compare currency too (VND keys unchanged). The preview total is per currency
  (`total.currency` + `total.others`); the AI reader returns each row's currency.
- **Assistant**: `expenseCurrencySupported` = the 16 currencies; the expense writer writes `currency`
  and the minor units under that currency's ceiling; the duplicate check compares the same currency.
  A missing, unclear ("$" alone) or unsupported currency still needs review.

## Not done / follow-ups

- Old app versions show a non-VND expense as đồng and add it into their totals; nothing can fix
  that except updating (consider a minimum version once this ships).
- The assistant's own form list (`supportedCurrencies` in `assistant.ts` and
  `assistant_rules.dart`, 11 codes) is narrower than Chi tiêu's 16; THB, HKD, CNY, CHF, MYR receipts
  stay in review until the assistant widens it. Its chat cards still print `"{minor} {code}"` for
  non-VND totals (the assistant app can use `money()` from `spending_format.dart`).
- No per-currency switch in statistics (only the household currency is charted).
- Portal: no spending screens, nothing to change.

## Code and tests

- Contracts `packages/contracts/src/spending.ts` (currency block), `spending-import.ts`
  (`detectCurrency`, `parseAmount(…, household)`), `assistant.ts` (`expenseCurrencySupported`).
- Rules `firebase/firestore.rules` ("Chi tiêu currencies" blocks); storage rules unchanged.
- Functions `spending.ts` (`householdCurrency`, recurring, budget alert, category caps),
  `spending-import.ts`, `ai.ts` (import extractor), `assistant-writers-images.ts`.
- App `apps/mobile/lib/features/spending/spending_currency.dart` + format / calc / models /
  repository / screens, Hôm nay card, Tiện ích tile.
- Tests: contracts `test/spending*.test.ts`; functions `test/spending-import.test.ts`,
  `test/assistant-image-model.test.ts`; emulator `firebase/tests/spending.rules`,
  `spending.integration`, `spending-import.integration`, `assistant-images.{rules,integration}`;
  app `test/features/spending_currency_test.dart`, `spending_test.dart` (currencies group),
  `spending_calc_test.dart`; goldens `test/golden/goldens/sp/cur_*` (+ 8c, 8h, 8k updated).
