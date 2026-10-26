# Bilingual writing: Vietnamese and English as equals

Vietnamese is the ARB **template** (source language, D-012 / D-104). English is **not** a
translation of it: both are written for native readers. They must deliver the same experience,
not the same sentence.

## 1. Parity rules

| Preserve | Means | Example (current copy) |
|---|---|---|
| **Intent** | Why the string exists | `pmErrorBodyPlain`: both reassure *you weren't charged*, then say what to do |
| **Action** | The verb does the same thing | "Ghi cữ bú" / "Log a feed": both open the same sheet |
| **State** | The same status, tense and completeness | "Chờ đồng bộ" / "Waiting to sync"; "Đã ghi" / "Logged" |
| **Meaning** | No added or dropped facts | ⚠ `imBusyReading`: vi "Đang đọc dữ liệu…" vs en "Reading…" (en drops the object; fine), but `offlineBanner` vi names "bản ghi", en doesn't. Fix by fixing vi, not by copying it |
| **Certainty** | Hedges match ("có thể" ↔ "may"; "thường" ↔ "usually") | `careSaveFailed`: "Có thể quyền của bạn đã thay đổi" / "Your access may have changed" ✓ |
| **Emotional tone** | The same warmth level; celebration stays celebration | `ksNudgeTodayTitle` keeps the 🎂 in both |
| **Personalisation** | The same placeholders, the same person | `{name}` refers to the same person in both |
| **Accessibility semantics** | Spoken labels carry the same content and units | Semantics strings are ARB strings too |

**Allowed to differ:** sentence structure, word order, length, punctuation style, and whether a
noun is spelled out (en often needs an article or a plural; vi a classifier). A vi
label + value can become an en phrase, and vice versa.

## 2. Vietnamese style

**Prefer:**

- contemporary spoken Vietnamese that parents use;
- short direct sentences;
- concrete verbs (ghi, lưu, xem, thêm, chọn, mời, xoá, thử lại);
- restrained warmth ("nhé" at most once per screen);
- "Chưa … được" for failures ("Chưa lưu được", not "Lưu thất bại").

**Avoid:**

- Hán-Việt or system words on everyday surfaces where an equally accurate plain word exists:
  "thực hiện", "tiến hành", "bản ghi", "cấu hình", "xác nhận" (as a button). Precise terms (đồng
  bộ, dữ liệu, sao lưu, quyền) stay where they are accurate: sync, privacy, backup, permissions
  and troubleshooting (`ui-copy-patterns.md` §4);
- calques from English ("Bạn có muốn…?" for every question; "được tạo bởi");
- repeating "bé" or "của bạn" in every line ("Lịch sử của bé" → "Lịch sử");
- overusing "nhà mình": it is warm, but a neutral label ("Gia đình") is clearer in navigation and
  settings;
- English loanwords where a natural vi word exists and means the same ("offline" → "chưa có
  mạng" when the cause is no connection; "credit" is an
  owner-approved exception for Lumi, D-101).

**Orthography (standardise; verified variants):**

- Tone marks go in the new style: **"xoá", "huỷ", "tuỳ", "khoẻ"** (the catalog uses "Xoá" ×144
  vs "Xóa" ×3, and "Huỷ" ×40 vs "Hủy" ×2).
- The outliers to fix when touched: `deleteRecord`, `deleteConfirmTitle`, `deletedToast` ("Xóa"),
  `cancelNoSave`, `cancelConfirmTitle` ("Hủy").

## 3. English style

**Prefer:**

- natural international English;
- familiar parenting words (feed, nap, diaper, bottle, pumping);
- sentence case everywhere, including buttons and titles;
- contractions in friendly copy ("can't", "you'll");
- **US spelling** for UI (recommended; the catalog mixes "Customise" / "Customize" and
  "Personalisation" / "Personalize"). This is an owner decision; until it's made, match the
  surrounding screen.

**Avoid:**

- word-for-word vi order ("Lời mời cho Bà" → "Invite for Grandma" ✓, but "Note of baby" ✗);
- clinical terms ("lactation session" → "breastfeeding");
- slang ("bub", "nappy" unless an owner choice);
- US-only idioms;
- Title Case ("Add to Memories" → "Add to memories" only if the feature name isn't a proper noun;
  **feature names stay capitalised**: Memories, Today, Lumi, Premium).

**Plurals:** en needs ICU plurals wherever a count meets a noun. Verified bugs: `rhythmFeeds`
"{count} feeds" (Today and History; "1 feeds"), `pickSummary` "{count} items · {photos} photos,
{videos} videos". See `localization-and-arb.md`.

## 4. Equivalent pairs (current copy; read them as a style sample)

| vi | en | Why it works |
|---|---|---|
| Ghi cữ bú | Log a feed | Same action; en needs the article |
| Ghi giấc ngủ | Log sleep | Uncountable in en |
| Ghi nhanh | Quick log | Natural noun phrase in en |
| Đã ghi · {what} | Logged · {what} | Same compact toast shape |
| Ai thấy | Who sees | Short label, same question |
| Chưa có thông báo nào | No notifications yet | "Chưa … nào" ↔ "No … yet" |
| Chưa tải được thông báo | Couldn't load notifications | "Chưa … được" ↔ "Couldn't …" |
| Khôi phục được trong 30 ngày ở "Đã xoá gần đây". | You can restore them for 30 days from "Recently deleted". | en adds the subject; meaning and number identical |
| Người thân chỉ thấy tên thân mật | Relatives only see the nickname | "tên thân mật" ↔ "nickname", not "intimate name" |
| Gặp Lumi, trợ lý của nhà bạn | Meet Lumi, your family's helper | Warmth kept; "trợ lý" ↔ "helper" (not "assistant") for tone |

## 5. Process for a new string

1. **Write vi first** (the template), in context: which component, and which state.
2. **Write en from the meaning,** not from the vi words. Read the en aloud on its own.
3. **Compare against the parity table** (§1).
4. **Check both against the glossary.**
5. **Render both** (goldens vi + en) and check fit, wrapping and truncation.
6. **Note any en/vi structural difference** in the `@description` if a reviewer might think it is
   a mistranslation.
