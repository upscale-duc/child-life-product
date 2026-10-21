# Personalization v2 — audit of the implementation (2026-10-21)

Reviewer: Claude, at the owner's request ("codex đã triển khai phần cá nhân hoá. hãy review và audit").
Scope: the P-172 part of commit `0663bb8` (contracts `personalization-v2.ts`, Functions
`personalization-v2.ts` / `personalization-state.ts` / `personalization-stats.ts`, the `rhythm.ts`,
`account.ts`, rules and index changes, the Flutter `personalization_*` files, `today_for_baby.dart`,
`reminder_notifications.dart`), read against the
[implementation handoff](personalization-v2-review-2026-10-20.md) and the
[plan](../product/personalization-v2-plan.md). Line numbers refer to `0663bb8`. The working tree also
holds uncommitted engagement / product-analytics edits from another session (some in
`personalization-v2.ts` and `personalization_digest.dart`); they are not reviewed here.

Nothing here has been deployed. Tests listed under Verification were run on 2026-10-21.

## Verdict

The server side is careful: strict request schemas, membership rechecked inside every transaction,
private notes kept private, read-time eligibility for stored recommendations (the 2026-10-20 P1 is
fixed), health first, no child data in analytics, honest copy. The five funnel events from the
2026-10-19 audit are now emitted.

It is **not ready for dev rollout**. One defect breaks baby and account deletion on any real
Firestore, two defects undo the features they belong to (the daily digest and the handover
acknowledgement), and the screens are an engineering layout with no design or goldens. For families,
value today rests on the work card, the context chips and the notebook; the routine ranges and the
digest are the parts most likely to matter, and both need the fixes below to work as intended.

## Findings

Severity: **P1** blocks a dev rollout; **P2** fix before beta families see it; **P3** polish.
"Reproduced" means a temporary emulator test (kept outside the repo) asserted the faulty behaviour.

### P1

1. **Baby and account deletion fail on real Firestore: three collection-group indexes are missing.**
   `account.ts` `babyStep` now runs `collectionGroup('personalization').where('babyId', …)` and
   `collectionGroup('settings').where('babyId', …)`; `accountStep` runs
   `collectionGroup('notebook').where('authorUid', …)`. Collection-group single-field indexes are not
   automatic, and `firestore.indexes.json` has no `fieldOverrides` for them (it has them for
   `reactions.uid` and `favorites.uid`, which is why those queries work). **Verified on
   `child-life-dev`** with read-only queries: all three return HTTP 400 "requires a
   COLLECTION_GROUP_ASC index". The emulator does not enforce indexes, so every test stays green.
   *Fix:* add the three `fieldOverrides` (COLLECTION + COLLECTION_GROUP, ascending), deploy indexes
   before Functions, and re-run the dev query check.

2. **The daily digest is cancelled whenever something new happens that day.**
   `reservePersonalizedDigest` (lines 375–377) returns `fireAt: null` when today's lease exists but the
   fingerprint (top activity, age card, first work item) changed. The app's reminder sync cancels
   every notification not in its desired list (`reminder_notifications.dart`, D-077 #2), so the
   20:30 notice reserved in the morning disappears after a new reminder, a check-in that changes the
   suggestion, or an answered card. **Reproduced** (09:00 reserve → 20:30; reminder added at 14:00 →
   `null`). *Fix:* on the same date and install, keep the existing slot and update the stored
   fingerprint; the notice copy is generic, so nothing stale is shown.

3. **Every personalization action marks the AI handover stale.** `updatePersonalization` bumps
   `babies/{b}/facts/state.dataVersion` after every action (lines 304–309), including
   `acknowledge`, `context`, `focus` and `digest`. `handover_screen.dart` shows "stale" when
   `dataVersion` is newer than the summary, so a caregiver who taps "Tôi đã nhận bàn giao" is told
   the handover changed; regenerating costs AI quota. The app also refetches `getPersonalizedDay` on
   every bump. **Reproduced** (7 → 9 after acknowledge + context). *Fix:* bump only for writes that
   change shared facts (shared notes, work transitions, exclusions), never for per-person state.

**P1 fixed (2026-10-21).** #1: `fieldOverrides` for `notebook.authorUid`, `personalization.babyId`
and `settings.babyId` (COLLECTION + COLLECTION_GROUP, ascending), deployed to `child-life-dev` with
`scripts/deploy.sh dev firestore:indexes` only; all six indexes READY, and the three read-only
`runQuery` checks now return results instead of "requires an index". #2: a same-day reservation on
the same install keeps its pending slot and stores the new fingerprint; the other-install, quiet
hours, Sunday, past-time and switch-off guards are unchanged. #3: `dataVersion` moves only for
shared-note writes and deletes (including a note leaving the shared scope), real work transitions
and family exclusions and their restore; acknowledge, context, focus, digest, routine and personal
responses no longer bump it. New emulator cases in `personalization-v2.integration.test.ts` cover
#2 and #3 and fail on `0663bb8`. Functions are not deployed, so #2 and #3 reach dev only with the
next Functions deploy.

### P2

4. **An old overdue reminder becomes a permanent top card.** `personalizedDay` lists every unfinished
   reminder ordered by `dueAt` (lines 539–560); `personalization_sources.dart` (58–80) turns the first
   one due before tonight — including one overdue for weeks — into an `essential` card that cannot be
   dismissed, and a caregiver sees other people's reminders there. **Reproduced** with a reminder due
   2026-09-01. *Fix:* due today or overdue < 24 h, assigned to the viewer or unassigned; allow snooze.

5. **A reminder completed from the work card and then undone never returns.** The `careWork` claim
   stays `completed` when "Hoàn tác" in Nhắc việc sets `done: false`; the list filters completed
   claims (line 559) and `accept` then fails with `work-conflict`. **Reproduced.** *Fix:* derive the
   state from `reminder.done`, or reset the claim when the reminder reopens.

6. **Two feedback systems that do not talk to each other.** "Có ích" on the new screen writes only the
   per-person `responses` map (lines 138–165): it hides the activity until midnight and never feeds
   `feedbackMemory`, which reads `recFeedback` only. So the brief's invariant ("feedback visibly
   changes the next visit") holds for AC02 on the old activity screen but not here, and the weekly
   "đã thử / có ích" count ignores AC02 answers. *Fix:* write the household `recFeedback` for
   `intend` / `helpful` / `unsure` as the old path does, keep `responses` for visibility only.

7. **Reasons that are not true.** `reason` is `WEEKLY_FOCUS` whenever a focus is set (line 607), but
   only `play` changes ranking; `handover` and `routine` change nothing. The context chip "Người khác
   chăm" (`other_carer`) is stored and used nowhere. `INTEREST` is returned when no interest was
   chosen. **Reproduced** for `handover`. *Fix:* return `recommend()`'s own reason code, drop or
   implement the no-op choices.

8. **Read cost and latency.** Each `getPersonalizedDay` reads up to 1,500 care records plus reminders,
   notes, exclusions and the sleep facts. The app refetches on every `dataVersion` bump (every care
   log), every hour, and after each mutation; `reservePersonalizationDigest` recomputes the whole
   snapshot again, with locale `vi` hard-coded, so an English user triggers a second snapshot. With
   ~30 logs a day on two phones this is tens of thousands of reads per family per day. The phone
   already holds the care log (EN09 computes on it). *Fix:* compute routine ranges on the device
   (Dart port of `routinePatterns`, as the plan's "offline parity" asks) or cache the snapshot per
   `dataVersion`; let the digest reuse the cached fingerprint.

9. **A hot document inside user transactions.** Every response increments
   `contentStatsDaily/{day}` inside the user's transaction (lines 170–189): one document for every
   family. At beta scale this is fine; at thousands of families it causes contention and aborted
   user actions. *Fix:* count outside the transaction (best effort) or aggregate nightly from
   `responses`.

10. **Editing a note silently changes its expiry.** `_NotebookEditorState._days = 7`
    (`personalization_v2_screen.dart:803`) ignores the note's stored expiry, so editing a permanent
    note makes it expire in a week; a new "Tránh" note also defaults to 7 days. *Fix:* initialise from
    `expiresAt`; default "Không hết hạn" for `avoid`.

11. **♥ saves to nowhere.** The heart on every card stores `save`, but the history lists non-activity
    ids as "Đã lưu" with no title or link, and the icon never shows a saved state. *Fix:* a "Đã lưu"
    list with titles and links, or remove the heart until it exists.

12. **The routine card does not say what it measures.** On Home, `personalization_sources.dart`
    (101–113) shows "Nhịp riêng từ nhật ký · 150–195 phút" for either feeds or naps, in raw minutes.
    *Fix:* "Giữa các cữ bú · thường 2 g 30 – 3 g 15", one card per kind.

13. **The digest reaches only people who already opened the app that day.** It is a local
    notification reserved only for a time later today, so a parent who did not open the app gets
    nothing — the main reason to have a digest. EN02 still asks the time during onboarding while the
    switch sits at the bottom of "Hôm nay của nhà mình", so G-108 stays open for most people. *Fix
    (needs Q-082):* ask the opt-in where EN02 asks the time; consider a server push at the chosen time
    through the existing notification centre.

14. **No design and no goldens.** None of the new surfaces is in Figma; they are stock Material
    controls (ChoiceChip, SwitchListTile, ListTile, PopupMenuButton, Dropdown, Material icons), a
    manual "Cập nhật" button and a `Material(transparency)` wrapper on every row. There are no
    Light / Night care × vi / en goldens, which the plan and CLAUDE.md require before a checklist row.
    Home gains a four-chip row for every parent. *Fix:* a design pass (log the gaps as G-109…), then
    rebuild on `Cl*` components and add goldens.

### P3

- `digestScheduled` is counted on every sync whose signature changed while the digest is pending, so
  it overcounts.
- Dates use `dd/MM HH:mm` in English too.
- The card action "Xem việc hữu ích hôm nay" is reused on vaccine, nutrition and occasion cards.
- A co-parent's own "exclude" needs a personal restore and a shared restore; one action should do both.
- `PersonalImpression` on Home reports `INTEREST` for any activity, including need-based ones.

## Process notes

- Built ahead of the owner's answers: Q-080–Q-086 are open, and the P-172 / Q-080–Q-083 rows were
  rewritten. Codex's choices are reasonable defaults, but the owner should confirm them (notably
  Q-082 explicit opt-in, Q-084 exclusion scope, Q-085 work transitions).
- The personalization work shipped inside a 288-file commit with Premium 48 and Lumi reads, which
  makes review and a targeted revert hard. Future slices should be their own commits.
- `figma-coverage-checklist.md` was not touched — correct, since nothing ran on a device.

## Verification (2026-10-21)

| Check | Result |
|---|---|
| Contracts vitest: `personalization-v2`, `rhythm`, `rhythm-content-seed` | 58 / 58 pass |
| Emulator (isolated ports): `personalization-v2.integration`, `rhythm.rules`, `rhythm.integration` | 69 / 69 pass |
| `flutter analyze` on `features/rhythm`, `today`, `reminders` | no issues |
| Flutter: `personalization_v2`, `today_personalize`, `rhythm_flow`, `rhythm_week`, `rhythm_plans` | 119 / 119 pass |
| Collection-group queries used by deletion, on `child-life-dev` (read-only) | 3 fail: missing index (P1 #1) |
| Temporary emulator test reproducing #2, #3, #4, #5, #7 | all five reproduced |

These runs used the working tree, which includes another session's uncommitted edits. Device runs,
Night care and large text were not checked.

## Suggested order

1. P1 #1–#3 (indexes, digest slot, `dataVersion`) — small, then deploy indexes to dev first.
2. P2 #4–#7 (work list, undo, one feedback path, truthful reasons).
3. #8–#9 before more than a handful of families.
4. Design pass and goldens (#14), then a device run on dev, then the checklist.
