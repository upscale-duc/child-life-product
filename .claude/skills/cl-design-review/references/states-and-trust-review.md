# States and trust review

The state model and the verified sync and upload distinctions live in `cl-screen-patterns` →
`screen-states.md`; AI wording lives in `cl-ux-writing` → `personalization-and-ai-copy.md`. This
file is how to **audit** them. Trust failures map to critical gates **G1** (business meaning),
**G3** (data loss) and **G5** (AI and health).

## 1. Inspect the implementation before judging a state

For each state the screen can reach:

1. **How the data is read:**
   - `.when(loading:, error:)`, `isLoading` / `hasError`, or `.value ?? default`.
   - The last one means **loading looks like empty** (verified on Today, History, Stats, Me).
2. **Which flags and roles branch the layout:** `readOnly`, `familyCan(…)`, `canSaveKind`,
   capabilities flags.
3. **What the success condition is:**
   - a local write (care records are optimistic, `commitRecord`);
   - a server write;
   - processing (media `QueueState.uploaded` → ready);
   - a job (`KeepsakeJobStatus`).
4. **Whether a golden shows the state.** If not, the visual side is `Not evaluated`.

## 2. Mandatory distinctions: never confuse

| Pair | How to check | Gate |
|---|---|---|
| Loading vs empty | The empty copy only renders after data has resolved | G1 (if it claims "no records") |
| Saved locally vs available to family | Care pending = `metadata.hasPendingWrites`; copy and indicators must not say "shared" while pending | G1 |
| Uploaded vs processed and ready | `QueueState.uploaded` is "bytes on the server", not visible yet | G1 |
| Cached vs current | Offline and saved copies carry "as of" or "Đang xem bản đã lưu" | G1 |
| AI interpretation vs observed fact | AI is labelled (`AiLabel`), sectioned, with a date range; facts link to their source records | G5 |
| Prediction vs certainty | "khoảng" / "around" + basis ("theo các cữ hôm nay") | G5 |
| Disabled vs missing feature | A disabled control says why; a flag-off feature doesn't appear as broken | G6 |
| Saved vs failed later | Optimistic saves that the server rejects show `careSaveFailed`; the record disappears | G3 |

## 3. State checklist

| State | Review question |
|---|---|
| Initial / first run | Does the screen teach the first action without empty walls? Do any links lead to nothing (e.g. "Xem lịch sử" with no history)? |
| Loading | Skeleton, or false "empty"? Do header strings with placeholders render broken while data loads (e.g. a greeting with an empty `{name}`)? |
| Loaded | Is the time basis visible where data ages? |
| Empty | An invitation with one action; a dashboard section hidden or one line |
| Partial | Missing parts labelled; insights suppressed when the sample is too small |
| Error | What happened + what to do + retry; the frame kept |
| Offline | A banner + item-level status; logging still possible |
| Pending sync | Item-level "Chờ đồng bộ"; no "shared" claims |
| Uploading / processing | Honest progress; "ready" only when ready |
| Success | Feedback matches the real success condition; undo where reversible |
| Stale | A notice + refresh; no stale data styled as live |
| Permission restricted | Hidden or disabled actions per role; read-only stated where helpful; never another person's state |
| Subscription restricted | Value + what Free keeps; calm; the health route never behind Premium |

## 4. AI and insights audit

Check that the layout separates and labels:

1. observed data;
2. calculated summaries (with period);
3. rule-based suggestions;
4. predictions (approximate, with basis);
5. AI interpretations (labelled, with date range and generation time; stale notice).

**Fail G5 when:**

- an insight claims a cause, a diagnosis or "abnormal" without a reliable basis;
- a prediction is shown as exact fact;
- a threshold not in the bundled WHO data or an owner-approved source is used;
- AI text appears on a health day (Handover suppresses AI text when there's a health sign: keep
  that).

## 5. Reporting

**Name the code path** for C-level state findings (file:line), and the golden for R-level ones.
**Don't invent backend behaviour:** if the success condition can't be determined from the code,
the finding is H with "Needs behavior verification".
