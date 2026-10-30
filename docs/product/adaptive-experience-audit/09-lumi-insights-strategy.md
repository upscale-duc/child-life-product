# 09 · Lumi & personalized insights

Builds on `docs/product/lumi-plan.md`, `docs/product-audit/06-lumi-audit.md` and `docs/audits/2026-10-29-lumi-ca-nhan-hoa-nhip.md`. Facts: Lumi has a free rule path, module reads with permission checks (`firebase/functions/src/assistant-reads.ts`), a schema'd model output, confirm-before-write drafts, a health route, credits (`assistant-usage.ts`), and band-specific example questions behind the flag (adaptive plan §12).

## 1. Three responsibilities

| Layer | Belongs here | Examples | Cost |
|---|---|---|---|
| **A · Deterministic** | Anything with one right answer | Age and band, feature availability, pins, content eligibility by coverage, notification eligibility, quiet hours, "Sắp tới" ranges, WHO bands, vaccine due dates | Free, testable |
| **B · Recommendation** | Combining records with rules and content | Idea of the day (personalization v2), "Bé dậy chưa?", reminder suggestions, retrospective shelf, "năm ngoái lúc này" | Free (rules + content) |
| **C · Conversational AI** | Language understanding and summarising | "bé bú 120ml" → a draft log, "tuần này ngủ thế nào", handover summary, a year's story caption draft, answering from records | Paid (credits) |

**Rule:** a request goes to C only when A/B cannot answer it. Today's free rule path is the right default; keep extending it (L8 "bây giờ" moved logic into rules, D-140).

## 2. Context Lumi should receive

| Context | Source | Notes |
|---|---|---|
| Age in months + band + corrected age flag | `childMonthsProvider` / server equivalent | Never DOB itself in the prompt |
| Content coverage per type | Registry (proposal, [11](11-personalization-architecture.md)) | Lets Lumi say "app chưa có nội dung cho tuổi này" |
| Enabled features for this family and role | Capabilities | Never suggest a feature the person cannot open |
| Recorded facts, on demand | `assistant-reads.ts` tools | Read, don't preload |
| Goals for this child | Experience doc | Order suggestions, not answers |
| Locale | App | vi/en |

**Not** in context: photos (unless the person attaches one), captions, other children's data, other members' private notes.

## 3. How Lumi's role evolves

| Band | Main job | Example asks |
|---|---|---|
| 0–1 | Log for me, tell me when | "Bé bú 120ml", "Lần bú cuối lúc mấy giờ?" |
| 1–3 | Summarise and remind | "Tuần này Bơ ngủ trưa thế nào?", "Nhắc tiêm mũi 18 tháng" |
| 3–6 | Remember and organise | "Tháng này chi cho Na bao nhiêu?", "Tìm ảnh Na đi biển" *(memory search: verify read support)* |
| 6+ | Recall and plan | "Tuần tới Bin có lịch gì?", "Chuẩn bị đi khám cho Bin" |

## 4. Safety & trust rules

1. **Never invent observations.** Every statement about the child cites a record ("Theo 5 lần ghi ngủ tuần này…"). No record → say so.
2. **Developmental questions:** answer with the age range from reviewed content, "nhiều trẻ…", and the "khi nào nên hỏi bác sĩ" line; never a diagnosis. Out of coverage → "Child Life chưa có nội dung cho {tuổi}; hãy hỏi bác sĩ hoặc giáo viên của con." (**proposal**)
3. **Health route stays first** (existing): red-flag terms route to first aid / call a doctor before any model call.
4. **Data minimisation:** band and months, not DOB; no photos by default; model logs follow CLAUDE.md (no child data in logs).
5. **Consent:** reading photos or sending to a model remains opt-in per use; family members' data under existing `assistantSharer` rules.
6. **Age-appropriate content:** for 6+, Lumi talks to the caregiver about the child; it is never addressed to the child.

## 5. Cost

- Rule path first (free). Measure share of requests answered by rules by band.
- Cache per-day summaries (handover already caches, D-103).
- For 3+ families, most asks are reads (totals, lists): these should be rule-answered queries, not model calls (**proposal**: add rule intents for "chi bao nhiêu", "lịch tuần tới", "mũi tiêm tới").

## 6. Avoiding generic or repeated suggestions

- Every suggestion needs a reason from data ("Vì: …", already the AX pattern).
- Personalization v2 `dislike` and "Đã ẩn" stay respected across Lumi and Today.
- No suggestion of a feature already used this week.

## 7. Measuring usefulness

| Metric | Source |
|---|---|
| Draft accepted / edited / discarded | Lumi events |
| Rule-answered share by band | Worker logs (aggregated) |
| "Có ích / Chưa rõ / Không hợp" on ideas | D-102 |
| Repeat ask within 24 h (signals a bad answer) | Aggregated |
| Credits per active family by band | `assistant-usage.ts` |
