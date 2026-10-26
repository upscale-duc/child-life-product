# Numbers, dates, times and units

**Principle:** use a visual presentation (stat, row value, chart, strip) when it improves scanning,
comparison or a decision. Keep numbers in a natural sentence when the sentence is clearer.

A sentence with two numbers is not automatically a problem: "Bé ngủ từ 20:30 đến 06:00." /
"Your baby slept from 20:30 to 06:00." is fine.

**Move to a visual** when the reader must **compare** values, **scan** several values, or when
there are **3+ numbers** competing in one sentence. The current
`lastNightInsight` ("Đêm qua bú {count} cữ, khoảng nghỉ dài nhất {gap} ({from}–{to}).") carries
four values, which is a candidate for count + longest-gap tiles. The layout patterns are in
`cl-screen-patterns` → `insights-and-data-visualization.md`.

## 1. Current formatting in the app (verified)

| What | Implementation | Note |
|---|---|---|
| Time of day | `DateFormat('HH:mm')` (19 call sites) and `DateFormat.Hm(locale)`. **24-hour in both languages** | vi expects 24-hour. For en, 24-hour is internationally acceptable. Following the device's 12 / 24-hour setting (`MediaQuery.alwaysUse24HourFormat`) is an **owner decision**, not a silent change |
| Short date | `DateFormat('dd/MM')` (14), `'d/M'` (4), `'d MMM'` with locale (15) | Day-first in both languages (not US month-first). That's acceptable for international English; keep it |
| Full date | `'dd/MM/yyyy'` (9). **`'dd.MM.yyyy'` (print studio, 5)** is an outlier | Prefer `dd/MM/yyyy` |
| Weekday | `'EEEE'`, `'EEEE, d MMM'` with locale | Pass the locale so en gets "Monday" |
| ISO `yyyy-MM-dd` | IDs and payloads (12) | **Never shown** in UI; one suspected display site is `print_studio/print_address_editor.dart:207` (verify by rendering) |
| Numbers | `NumberFormat.decimalPattern` (9) / `currency` | vi uses `.` for thousands and `,` for decimals; en uses `,` and `.`. Always format with the locale |
| Age | `ageLong` / `ageShort` (`lib/core/format/age.dart`) + ARB plurals (`ageMonths`) | Always use these; never hand-build ages |
| Time zones | Baby time zone (`features/baby/time_zones.dart`); D-078 families abroad | Show times in the baby's zone; say so when it differs from the device |

## 2. Presentation by data type

| Data | Visual form | In a sentence | vi | en |
|---|---|---|---|---|
| Feeding quantity | Value + unit: "120 ml" | "Bú bình 120 ml lúc 07:30" | `ml` (lowercase, space before) | `ml`; never "oz" unless an owner-approved unit setting |
| Feeding count | Stat "6 cữ" | "6 cữ hôm nay" | "{count} cữ" | ICU plural: "1 feed / 6 feeds" |
| Sleep duration | "9 giờ 40 phút"; compact "9g 40p" only where space forces it | "Ngủ 9 giờ 40 phút" | giờ / phút | "9 h 40 min" or "9 hr 40 min"; spoken: "9 hours 40 minutes" |
| Start–end | "20:30–06:00" with an en dash | "từ 20:30 đến 06:00" | — | "20:30–06:00"; in a sentence "from 20:30 to 06:00" |
| Ongoing | "Đang ngủ · từ 21:27 · 1 giờ 5 phút" | — | — | "Asleep · since 21:27 · 1 hr 5 min" |
| Relative time | "2 giờ trước · 07:30" (relative first) | — | "vừa xong", "2 giờ trước", "Hôm qua" | "just now", "2 hr ago", "Yesterday" |
| Diaper count | Stat + kinds (ướt / bẩn) | "3 lần thay tã" | — | ICU plural |
| Weight | "6,2 kg" (vi decimal comma, via `NumberFormat('#0.#', locale)` in `features/care/care_format.dart`) | — | `kg`, one decimal | "6.2 kg" |
| Height / length | "62 cm" | — | `cm` | "62 cm" |
| Age | "3 tháng 2 tuần" via `ageLong` | "Bé được 3 tháng" | — | "3 months old" (plural) |
| Milestone date | "24/10" this year; "24/10/2025" otherwise; "Hôm nay" / "Hôm qua" | — | — | the same pattern; "Today", "Yesterday" |
| Percentage | Bar or ring + "80%" | "đã dùng 80% ngân sách" | no space before % in vi UI (current: "80%") | "80%" |
| Trend | Number + direction + basis: "Gần đây ít hơn khoảng 2 giờ so với trước" (D-102) | Keep the basis visible | — | "About 2 hours less than before, recently" → better "About 2 hr less than the previous weeks" |
| Credits | "Còn 12 credit" (Premium v2) | — | "credit" (D-101) | "12 credits left" (plural) |
| Storage | "3,4 GB / 5 GB" + bar | — | GB | "3.4 GB of 5 GB" |
| Price | Store-formatted price string (never hand-format) | "{price}/tháng" | — | "{price}/month" |
| Subscription period | "Gia hạn {date}" | — | — | "Renews {date}" |

**Units are attached** ("120 ml"), never dropped ("120"). Never write minutes without a unit.

## 3. Pluralisation and dynamic values

- **vi has no plural inflection.** "{count} cữ" is correct for any count, so vi strings rarely
  need ICU plural (60 vi strings use it, mostly to mirror en).
- **en must use ICU plural whenever a count meets a noun:**
  `{count, plural, =1{1 feed} other{{count} feeds}}`.
- **Verified en plural bugs:** `rhythmFeeds` / `rhythmBreast` ("{count} feeds", Today and
  History), `pickSummary`, `albAppliesTo`, `dlSummary`, `albDeleteBody`. The `glanceUpload*`
  strings are filled in Swift (no ICU), so word them to be count-proof.
- **Pass numbers as numbers** (`int` / `num` placeholders) so `gen-l10n` formats them per locale.
  Don't pre-format into a string unless there's a unit formatter.

## 4. Screen readers

- Visual abbreviations need a spoken form:
  - "9g 40p" → "9 giờ 40 phút";
  - "1:24:08" → "1 giờ 24 phút 8 giây";
  - "24/10" → "24 tháng 10" / "October 24";
  - "–" ranges → "từ … đến …" / "from … to …".
- `ClTabularText(semanticsLabel:)` takes the spoken form. Build it from ARB strings, never by
  concatenating English.
- A tile reads as one sentence: "Bú bình, 120 ml, 2 giờ trước" / "Bottle, 120 ml, 2 hours ago".
- Never let a unit-less number be read alone ("120").
