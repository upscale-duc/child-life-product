# Lumi (Child Life Assistant chat) — test plan

> Owner, 2026-10-16: "Bạn cần có kế hoạch test với chatbox cho nhiều trường hợp khác nhau, chứ test là
> lỗi." This plan replaces "try it on the phone and see": every message type is a scripted
> conversation, every reply is checked against rules that make a dead end impossible to miss, and
> every bug found on a device becomes a case before it is fixed.

First run and findings: [`test-report-lumi-2026-10-16.md`](test-report-lumi-2026-10-16.md). Older
evidence (unit, Rules, integration, goldens, the 73-case live eval) stays as described in
[`evaluation.md`](evaluation.md) and [`eval-2026-10-15.md`](eval-2026-10-15.md); this plan adds the
end-to-end layer on top of them.

## 1. Scope

In scope: everything a person can do in the Lumi chat with typed text or a photo.

- Care logs the app has (`care_models.dart` `CareType`): bottle, breast, sleep, pump, diaper,
  growth, plus the running timers (sleep, breastfeeding) and observations (Nhịp sinh hoạt).
- Chi tiêu (typed and photographed expenses), Nhắc việc (reminders), questions about logged data,
  care guidance and recipes, health signs, small talk / help / out of scope.
- Every role (Cùng nuôi, Người chăm sóc with and without "Ghi khoản đã chi", relative with and
  without daily care), the shared thread and private threads, consent, credits, feature flags,
  question expiry, cancel, provider failures, retries.
- What the app shows for every server reply (the real chat screen).

Out of scope here (other plans): Rules unit tests, store purchases, push delivery, App Check,
real Cloud Run contention, model accuracy beyond the catalogue (see `evaluation.md` §6).

## 2. Layers

| Layer                     | What runs                                                                                                                                                                                                                                                                                                  | Model                                                                                                  | Proves                                                                                                                                                                                                    | Where                                         |
| ------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------- |
| a. Conversation simulator | Each case of the catalogue as a whole conversation through the **real callables and worker**: `quoteTask` → `startTask` → `runAssistantTask` → `submitClarification` / `patchDraft` / `confirmDrafts` / `cancelTask` → `getAssistantTask`, on the Firestore emulator (isolated ports), synthetic household | **fake** (scripted replies, CI, every run) or **live** (the real OpenAI gateway, owner-approved spend) | The server turns a reading into the right drafts / question / answer, charges right, keeps money private, saves records the app can read                                                                  | `firebase/tests/assistant-e2e/`               |
| b. Invariants             | §4, on **every snapshot after every turn**, plus a "fix and save" probe that does what the app's fix controls can do, then saves twice (same request id)                                                                                                                                                   | same run                                                                                               | No dead end, no field the app cannot fix, no silent future log, credits per policy, spending never shared, saved documents pass the app's create Rules and show in the app's lists, no duplicate on retry | `invariants.ts`                               |
| c. App replay             | Every snapshot of (a) exported as a JSON fixture (times moved to the app tests' clock) and rendered by the **real `AssistantChatScreen`** with the repository fake fed with it; again at 2× text                                                                                                           | —                                                                                                      | The missing field is named in plain words, a fix control is on the card, a clean draft saves in one tap, the server's chips are on screen, nothing throws or overflows                                    | `apps/mobile/test/features/assistant_replay/` |
| d. Device (manual)        | §8 checklist, only what (a)–(c) cannot see                                                                                                                                                                                                                                                                 | real                                                                                                   | Voice, keyboard, haptics, Night care at night, push, real network                                                                                                                                         | owner                                         |

Two model modes, one catalogue:

- **Fake** — each case scripts the reply a correct model gives under the current prompt (the v4
  rules: evidence words, `"time"` in `missingFields` when no time was said, `phase` for ongoing
  states). Fields the running code's strict schema does not know are dropped, so a reply written
  for a newer prompt still runs on older code. A kind the contracts do not have yet is written
  `"diaper|meal"`: the first one the code knows is used. Device-bug cases script what the
  deployed model actually returned. Deterministic: 0 network, ~1 minute for the catalogue.
- **Live** — the same cases with the real `openAiModelGateway` (strict schema, `store: false`,
  temperature 0, the production prompt). Wording is skipped (the engine's template), photos stay
  fake. The key comes from Secret Manager into the run's environment only, never printed or
  written; a hard call budget (`--max-calls`) stops the run.

## 3. Scenario catalogue

`firebase/tests/assistant-e2e/cases/*.json` — 216 cases (202 Vietnamese incl. no-diacritics, typos
and voice-like run-ons, 14 English), synthetic only. Anchor: Thursday 2026-10-15,
`Asia/Ho_Chi_Minh`, 14:20 unless a case says 07:10 (morning), 21:30 (evening) or 01:08 (night).

| File                       | Group            | Cases | Covers                                                                                                                                                                                                                                                                                                                                            |
| -------------------------- | ---------------- | ----- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `00-device-bugs.json`      | device           | 8     | the owner's device bugs DEV-1…DEV-4 (exact messages, the deployed model's replies)                                                                                                                                                                                                                                                                |
| `10-care-bottle.json`      | care.bottle      | 25    | complete · no diacritics · voice run-on · missing time (chip, typed, unreadable) · missing amount · AM-PM asked / resolved · last night said in the morning · oz · future refusal · yesterday · hôm kia · duplicate · correction before / after save · other milk · over the limit · English · replayed request · "8g", "tám giờ rưỡi", "nửa đêm" |
| `11-care-breast.json`      | care.breast      | 14    | complete · just now · no side · missing time (chip, typed) · end time + length · AM-PM · future · side correction · duplicate · no diacritics · English · too long · never ml                                                                                                                                                                     |
| `12-care-sleep.json`       | care.sleep       | 18    | span · overnight · duration only (chip, typed, prompt-literal) · woke time + length · nap · just woke · future end · end before start · AM-PM · overlap · correction · no diacritics · English · yesterday · voice · answer after 30 min                                                                                                          |
| `13-care-ongoing.json`     | care.ongoing     | 8     | "đang ngủ", "baby is sleeping now", since 13h, "dậy rồi", "đang cho bú bên trái", "bú xong rồi", already running, nothing running                                                                                                                                                                                                                 |
| `14-care-other-types.json` | care.types       | 12    | pump, diaper, growth: complete · no time · yesterday · no diacritics · English                                                                                                                                                                                                                                                                    |
| `15-observation.json`      | care.observation | 5     | new skill · prompt-literal missing time · fussy · eats less · uncertain day / night                                                                                                                                                                                                                                                               |
| `20-multi-intent.json`     | multi            | 10    | feed + sleep · two feeds · feed + money · one item without time · sleep + nurse · diaper + bottle · feed + reminder · three feeds · English · log + question                                                                                                                                                                                      |
| `30-expenses.json`         | expense          | 20    | 500k, 1tr2, 50 nghìn, 350.000đ, 1.5tr, 2 triệu, 4 triệu, $20, €15, bare "200" / "500" · categories (built-in, unknown → Khác) · hôm qua / hôm kia · merchant · duplicate · roles (caregiver with / without the right, relative) · mixed message by Cùng nuôi · money only the model sees · the expense hint                                       |
| `31-reminders.json`        | reminder         | 14    | mai 9h (AM-PM) · thứ 6 all day · assignee by role words (bố, mẹ) · this afternoon · medicine (siro → notice; "hạ sốt" → health) · caregiver refused · 20/10 · thứ 2 tuần sau · no diacritics · English · no date · a time already past                                                                                                            |
| `40-reads.json`            | read             | 11    | today / yesterday / week / credits / compare · no diacritics · relative with and without daily care · "read or log?" answered · English · empty day                                                                                                                                                                                               |
| `41-care.json`             | care             | 6     | sleep concern (questions answered) · meal ideas · the food safety net · no date of birth · `assistant_care` off · English                                                                                                                                                                                                                         |
| `42-health.json`           | health           | 7     | fever, breathing, seizure (no diacritics), English, a log with fever, at 0 credits, a sign only the model reads                                                                                                                                                                                                                                   |
| `43-talk.json`             | talk             | 11    | thanks, hello, ok, English, "vừa ghi rồi", weather, poem, injection, "giúp mình với", "Lumi làm được gì?", emoji                                                                                                                                                                                                                                  |
| `50-roles.json`            | roles            | 9     | caregiver logs (shared), caregiver logs + father saves, relatives refused, father's expense private, caregiver observation, father's reminder, caregiver reads, caregiver with the spending right (mixed)                                                                                                                                         |
| `60-gating.json`           | gating           | 13    | no consent · out of credits (log, small talk) · `assistant` / `assistant_live` / `assistant_writes` off · question expired · cancel · provider error / timeout · rejected output · last credit · consent withdrawn mid-question                                                                                                                   |
| `70-photos.json`           | photo            | 5     | receipt (date to confirm, total incl. tax), clear date, blurry, caregiver, USD (fake image reader)                                                                                                                                                                                                                                                |
| `80-multi-turn.json`       | flow             | 12    | "ngủ 9 tiếng" → "21:00 tối qua" → save · "bú mẹ 20 phút" → "Vừa xong" → save · typed answer · unreadable answer → edit → save · edit amount → save · save retried · log then ask · AM-PM then edit side · save two · reminder assignee → save · expense → save · correction chain                                                                 |
| `90-robustness.json`       | robust           | 8     | caps, emoji, mixed vi/en, typos, voice fillers, 9h15, "kém 15", a long message                                                                                                                                                                                                                                                                    |

The care-type matrix (complete / missing time / missing amount / ambiguous AM-PM / duration only /
ongoing / correction / duplicate / past day / future refusal) is filled per type where the type has
that dimension (a diaper has no amount; growth has no time of day).

### Case format

```jsonc
{
  "id": "bot-04-missing-time-chip", // unique, stable (baselines and fixtures use it)
  "group": "care.bottle",
  "anchor": "14:20",
  "locale": "vi",
  "as": "MOM", // MOM DAD NANNY NANNY_SPEND AUNT GRANDMA
  "world": {
    "seed": ["bottle0800"],
    "off": ["assistant_writes"],
    "noConsent": ["MOM"],
    "quota": 0,
    "dob": null,
  },
  "turns": [
    {
      "say": "bé bú 120ml",
      "model": {
        "i": [
          {
            "k": "bottle",
            "f": { "amountMl": 120 },
            "ev": { "amountMl": "120ml" },
            "miss": ["time"],
          },
        ],
      },
      "answers": [{ "field": "time.missing", "choice": 1 }],
    }, // chip index / id, member, or "text"
    { "confirm": "all" }, // also: patch, cancel, withdrawConsent
  ],
  "expect": {
    "outcome": "drafts",
    "kinds": ["bottle"],
    "ready": true,
    "asks": ["time.missing"],
    "values": { "0.occurredAt": "D0 13:50" },
    "visibility": "shared",
    "credits": 1,
    "saved": 1,
  },
  "device": "DEV-2", // when it reproduces a device bug
}
```

`expect` is the **correct** behaviour (api.md, the owner's decisions), never "what the code does
today". Model reply keys: `i` intents (`k` kind, `f` fields, `ev` evidence words, `miss`, `unc`,
`cp` corrects previous), `reads`, `clar`, `care`, `health`, `talk`, `oos`, `raw`, `error`.

## 4. Invariants

Checked on every snapshot (after start, after each answer, edit, save, cancel) and at the end.
Severity: **P0** dead end, privacy, wrong or silent record · **P1** wrong field, extra tap, missed
item, wrong question · **P2** copy.

| Id                                           | Rule                                                                                                                                                                                                  | Sev.                         | Layer      |
| -------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------- | ---------- |
| `NR_FIELD_UNKNOWN`                           | every flagged field (missing ∪ uncertain) is a field of the draft's kind                                                                                                                              | P0                           | a          |
| `NR_MISSING_BUT_SET`                         | a field listed as missing has no value                                                                                                                                                                | P1 (P0 if no fix in the app) | a          |
| `NR_NO_CONTROL`                              | every flagged field has a control in the app (`field_controls.json`: inline fix row or editor field)                                                                                                  | P0 no editor / P1            | a          |
| `NR_NOTHING_NAMED`                           | a `needs_review` draft names at least one field or problem                                                                                                                                            | P1                           | a          |
| `DEAD_END`                                   | at least one forward action: an answerable question (chips or free text), a draft that saves or can be fixed, an answer, or an explained failure; never stuck in `queued` / `processing`              | P0                           | a          |
| `FIX_DOES_NOT_CLEAR`                         | the app's fix (fill what is empty, confirm the flagged fields) leaves the draft saveable                                                                                                              | P0                           | a (probe)  |
| `FALSE_UNAVAILABLE`                          | never "Chưa có nơi lưu / App chưa có module" for a care type the app logs                                                                                                                             | P0                           | a          |
| `DROPPED_ITEM`                               | an item of a mixed message that gets no draft is named, with a way to log it                                                                                                                          | P1                           | a          |
| `WRONG_KIND` / `WRONG_VALUE_SILENT`          | no draft of another kind or with a wrong value that saves without review                                                                                                                              | P0                           | a (expect) |
| `FUTURE_LOG`                                 | no completed log after the send time unless flagged; no saved record in the future                                                                                                                    | P0                           | a          |
| `CHIP_FUTURE` / `CHIP_EMPTY`                 | time chips never in the future; labels in vi and en                                                                                                                                                   | P1 / P2                      | a          |
| `CREDITS_POLICY` / `CREDITS_LEAK`            | usage per outcome (drafts / answer commit 1; question holds; health, small talk, help, fallback, failures release; nothing left reserved)                                                             | P1                           | a          |
| `PRIVACY_VISIBILITY` / `PRIVACY_SHARED_LEAK` | a task with money (words, an expense draft, `SPENDING_PRIVATE`) is private; no message of a private task and no money words in the shared thread; another member's `getAssistantTask` is `NOT_MEMBER` | P0                           | a          |
| `SAVE_FAILED` / `SAVE_REFUSED_READY`         | a saveable draft saves; a draft shown ready is not refused at save                                                                                                                                    | P0 / P1                      | a          |
| `SAVE_SHAPE` / `SAVE_RULES`                  | the saved document passes the contracts schema and the app's own **create Rules** as its author (`@firebase/rules-unit-testing`, the Rules-test pattern; `source` set to the app's value)             | P0                           | a          |
| `SAVE_NOT_LISTED`                            | the saved record is returned by the app's query (care log day range, Chi tiêu, Nhắc việc ordered by `dueAt`, timers)                                                                                  | P0                           | a          |
| `SAVE_DUPLICATE`                             | the same save sent twice (same request id) writes nothing more                                                                                                                                        | P0                           | a          |
| `EXPECT_*`                                   | outcome, kinds, ready, flagged fields, values, questions asked (an extra one = extra taps), visibility, credits, records saved, notice codes, model calls (fake)                                      | P1 (P0 visibility)           | a          |
| `RENDER_ERROR`                               | the chat screen renders the snapshot without an exception                                                                                                                                             | P0                           | c          |
| `DRAFT_NOT_SHOWN`                            | every pending draft has a card (an app build that cannot show a kind = dead end)                                                                                                                      | P0                           | c          |
| `FIELD_NOT_NAMED`                            | each flagged field is named on the card in plain words (`field_controls.json` `words`)                                                                                                                | P1                           | c          |
| `NO_FIX_CONTROL`                             | a flagged card has a fix on it (inline fix panel, a tappable field, "Sửa" / "Chọn ngày giờ")                                                                                                          | P0                           | c          |
| `READY_NOT_SAVEABLE`                         | a clean draft is ticked with an enabled "Lưu …" (or its own save, or "Vẫn lưu" for a duplicate)                                                                                                       | P0                           | c          |
| `CHIP_NOT_SHOWN`                             | every chip of the server's question is on screen                                                                                                                                                      | P0                           | c          |
| `LARGE_TEXT_OVERFLOW`                        | nothing overflows at 2× text on a 375-wide phone                                                                                                                                                      | P1                           | c          |

`apps/mobile/test/features/assistant_replay/field_controls.json` is the single map field → app
control → plain words; the server harness and the replay test both read it, and the replay test
checks it against the app. Update it with the app.

## 5. Pass criteria

| Gate                                                                                                                                       | Criteria                                                                                                                                                                                                                                |
| ------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| CI (every push touching `firebase/functions/src/assistant*`, `packages/contracts/src/assistant*`, `apps/mobile/lib/features/assistant/**`) | fake run and app replay: **no violation outside the baselines** (`known-failures.json`, `known_failures.json`); the run fails on a new code, and reports a baselined code that is gone so the entry is removed in the fix's commit      |
| Before every dev deploy of assistant code, and before every app build for a device                                                         | the CI gate, plus: **0 P0 outside the baselines** and every baselined P0 has an owner-accepted bug id in the report; the device-bug cases (`00-device-bugs.json`, `fixtures/device/`) pass or are baselined with the bug they reproduce |
| On a prompt or model change (`assistantPromptVersion`, `OPENAI_MODEL`)                                                                     | live run of the catalogue (owner-approved budget): 0 privacy P0, 0 `WRONG_KIND` / `WRONG_VALUE_SILENT` on cases the fake run passes, cost and latency recorded in a dated report                                                        |
| Release to real families (prod)                                                                                                            | all of the above on the release commit, the §8 device checklist signed by the owner, and no open P0                                                                                                                                     |

## 6. When it runs

| When                                                                                       | What                                                                             | Who                                        |
| ------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------- | ------------------------------------------ |
| Every change to assistant server / contracts / app code                                    | fake run + app replay (≈ 1 min + ≈ 20 s)                                         | the engineer (CI when the pipeline exists) |
| Before `scripts/deploy.sh dev …` with assistant functions                                  | the same, on the commit being deployed                                           | the engineer                               |
| Before an app build for a device (`flutter run --flavor dev`, TestFlight / internal track) | the same, plus the replay of `fixtures/device/` (old drafts live 24 h on phones) | the engineer                               |
| Prompt / model change, before a release, weekly while Lumi is in beta                      | live run (≤ the approved call budget)                                            | engineer, owner approves the spend         |
| A device bug is reported                                                                   | §9 first, then fix                                                               | engineer                                   |

## 7. How to run

```sh
# Once per shell: build the shared contracts (the harness imports them like the Functions).
pnpm --filter @child-life/contracts run build

# a + b, fake model (isolated emulator ports 8287 / 4527 / 4627; another session's emulators keep running)
TMPDIR=<private scratch dir> firebase emulators:exec --only firestore --project demo-child-life-e2e \
  --config firebase/tests/assistant-e2e/firebase.e2e.json \
  "pnpm --dir firebase/tests exec tsx assistant-e2e/run.ts --mode fake [--export-fixtures] [--only id,id] [--group care.] [--strict]"
#   → summary on stdout, <out>/summary.md, <out>/results.json, <out>/snapshots/<case>.json
#   --export-fixtures rewrites apps/mobile/test/features/assistant_replay/fixtures/*.json (not device/)

# a + b, live model (owner-approved spend; the key never printed or written)
OPENAI_API_KEY="$(gcloud secrets versions access latest --secret=OPENAI_API_KEY --project child-life-dev)" \
  firebase emulators:exec … "pnpm --dir firebase/tests exec tsx assistant-e2e/run.ts --mode live --max-calls 250"

# c, app replay (from apps/mobile)
flutter test test/features/assistant_replay/
flutter test test/features/assistant_replay/ --dart-define=REPLAY_STRICT=true          # every violation fails
flutter test test/features/assistant_replay/ --dart-define=REPLAY_FIXTURES=<dir>       # another fixture set (e.g. a live run's)
#   → build/assistant_replay/results.jsonl

# checks for the harness itself
npx tsc -p firebase/tests/assistant-e2e/tsconfig.json && npx eslint firebase/tests/assistant-e2e
```

## 8. Owner's device checklist (what automation cannot cover)

Run on one iPhone and one Android, dev build, the day before a release. Each line: ✓ / ✗ + a
screenshot for ✗ (then §9).

1. **Voice**: hold the mic, say "bé bú một trăm hai mươi ml lúc tám giờ sáng" in a normal room and
   with a TV on; the transcript and the draft match; release early / cancel by sliding away.
2. **Voice, accents and run-ons**: a Northern and a Southern speaker each say "ờ bé vừa ngủ dậy,
   ngủ được hai tiếng"; the start question appears, the chip saves.
3. **Keyboard**: Vietnamese Telex and VNI typing in the composer (no lost diacritics, no doubled
   letters); the keyboard never hides the chips or the save bar; "Gửi" on the keyboard sends once.
4. **Feel**: haptics on send / save / error; the typing indicator never hangs more than 10 s on a
   good network; scrolling while a reply arrives does not jump.
5. **Night care at night**: Night care on, room lights off, 2–4 am: chips, review rows and "Lưu"
   are readable without full brightness; no white flash when the chat opens.
6. **Push**: a reminder saved from chat rings on the right phone at the right time (all-day at
   the chosen hour), and on the assignee's phone; a caregiver's saved feed shows on the mother's
   phone within a minute.
7. **Real network**: airplane mode while "Đang chuẩn bị" → the message is kept and resent once;
   a weak 3G network does not double-charge (Lượt còn lại before / after).
8. **Two phones, one baby**: mother and father open the shared thread together; a timer started
   from chat on one phone is running on the other; "Kết thúc" on either ends it once.
9. **Large text**: system font at the largest size: the review rows and chips stay tappable.
10. **Camera**: a real receipt in shop light; a crumpled one; the photo permission denied, then
    allowed from Settings.

## 9. When a bug is found (every device bug → a case first)

1. Write down the exact message(s), the time on the phone, the role, what was shown, and the
   chip(s) tapped (a screenshot is enough). No real child data in the case: replace names.
2. Add a case to `cases/00-device-bugs.json` with `"device": "DEV-<n>"`, the exact words, the
   anchor time, and `expect` = what should have happened. In `model`, script what the deployed
   model returned (read it from the task's `textReading` on dev if needed, never from logs with
   content); if unknown, the reply the prompt asks for.
3. Run the fake harness with `--only <id>`: it must **fail** with the violation the owner saw (a
   dead end → `DEAD_END` / `NO_FIX_CONTROL`; wrong field → `NR_MISSING_BUT_SET`; …). If it passes,
   the harness misses something: add the invariant or the expectation first.
4. Export fixtures; if the bug is in the app, the replay test must fail on it too; copy the
   fixture to `fixtures/device/` so old drafts on phones stay covered after the server fix.
5. Fix the code. The case passes; remove its entry from the baselines in the same commit; the
   report of the next run says "fixed".
6. If the model caused it, add the same words to the live run of the next prompt change.

## 10. Limits

- The fake model proves the server and app logic for the replies we scripted; it cannot prove the
  real model returns them. The live run measures that, for this catalogue only (single labeller,
  one run per case, temperature 0).
- The app replay renders snapshots and reads widgets; it does not tap through every fix (the
  probe in (a) does the server side of it) and checks "named" by words on the card.
- The Rules shape check moves reminders by whole days to the real clock (the Rules compare with
  the real request time); records keep their synthetic times.
- Photos run only with the fake image reader.
