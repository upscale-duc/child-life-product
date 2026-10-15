# Mốc phát triển: seed content notes (for expert review)

`milestones.seed.json` follows `milestoneSeedSchema` (`packages/contracts/src/milestones.ts`); `packages/contracts/test/milestones.test.ts` checks coverage, the design's ids and the banned words. The portal imports the items as drafts; the dev seed publishes them through `publishedFromSeed` (dev only).

## 0. Status: engineering draft, not approved

- Drafted by engineering per **D-073 #2** ("làm nội dung như 1 chuyên môn đi. Người duyệt sau") from public guidance only. **No clinician has reviewed it.** Every item publishes with `review: null`, `illustrative: true` ("Nội dung minh hoạ · chờ chuyên môn duyệt"); prod needs a signed review (`milestonePublishProblems`, D-058). Nothing here may be called reviewed or expert-written.
- Vietnamese is primary (Northern, "bé", "ba mẹ", "bạn"); English is a parallel draft, British spelling (D-012).

## 1. Contents (`mst_20261015_02`)

- **56 items**: motor 16, communication 15, cognitive 12, social-emotional 13; months 0–24; `illustration: null` everywhere.
- `howToRecognise` (2–3 sentences): what it looks like at home, how to tell it from a look-alike, one gentle way to invite it, plus a safety line where the skill brings a new risk.
- `talkToDoctor` on **all 56** (motor 16, communication 15, cognitive 12, social-emotional 13). See §3.
- Design items keep their ids, groups, Figma titles and ranges; ids shared with Kỷ niệm presets mean the same thing.

## 2. Review pass 2 (2026-10-15): what changed

- **Ranges checked line by line** against the CDC 2022 checklists (Zubler et al. 2022, Tables 3–6, read in full text from PMC9680195; all eight CDC pages also read). One change: `shows_affection` **12–18 → 12–16** (CDC 15 mo "Shows you affection"; 18 was 3 months past the checklist age). Its `order` 450 → 435 so the list stays sorted.
- **`pretend_play`** kept at **18–24**, retitled "Bắt chước việc nhà, chơi giả vờ đơn giản" / "Copies chores, simple pretend play". It now covers only what CDC/AAP place by 24 months: copying chores (CDC 18 mo), simple play with toys (CDC 18 mo), toy food on a plate (CDC 24 mo), "begins make-believe play" (AAP, 2 year olds). It says outright that using one object for another (a block as food) comes later, around 30 months (CDC 30-month item, Zubler Table 5). Rejected alternative: moving it past 24 months would break the 0–24 scope.
- **Doctor notes added to 43 items** (13 → 56). The 2022 checklists dropped separate warning signs: not reaching a checklist milestone, losing a skill, or a parent's concern is itself the "act early" trigger (Zubler 2022; CDC pages). So every checklist item gets a note; `crawls` (not on the CDC lists) and `recognises_voices` get one as motor and hearing anchors.
- Doctor ages realigned to the window end: `first_word` 16 → 15 (CDC 15 mo), `responds_to_name` 12 → 9 (CDC 9 mo), `babbles` 12 → 10, `turns_to_voice` 6 → 5. Loss of skills is named in the language, social and walking anchors.
- **PMID fixed**: the WHO motor windows paper is **16817682** (Acta Paediatr Suppl 450:86–95). The old 16817681 is the WHO growth-standards paper. Checked via NCBI E-utilities.
- `howToRecognise` rewritten for `follows_faces`, `recognises_voices`, `looks_at_toy`, `two_word_phrases`, `pretend_play` (each lacked a look-alike line).
- Sources: `first_steps` now cites AAP "Baby walkers: a dangerous choice" (backs the walker line). `stranger_wariness` cites AAP 8–12 months (stranger wariness belongs there, not 4–7). `shows_affection` adds Zubler 2022.

## 3. How ranges and doctor notes were set

- **Window** = "tham khảo {from}–{to} tháng", never a deadline. `from` is roughly when many babies start. `to` is the CDC checklist age (≥75% of children) or up to +1 month (+2 from 15 months on). Out of window is only "chưa ghi".
- **Gross motor**: WHO MGRS 1st–99th percentile windows, rounded inwards: sitting 3.8–9.2 → `sits_up` 5–9; crawling 5.2–13.5 → `crawls` 6–13; standing with assistance 4.8–11.4 → `stands` 7–12; walking with assistance 5.9–13.7 → `cruises` 9–13; walking alone 8.2–17.6 → `first_steps` 9–18. Values confirmed in the PubMed abstract.
- **Locked design ranges kept**: `first_smile` 1–3, `lifts_head` 1–4, `coos` 2–4, `recognises_voices` 0–3, `follows_faces` 0–2, `calms_when_held` 0–2. All match CDC 2/4 months.
- **Doctor note pattern**: "Nếu đến khoảng {window end} tháng mà bé chưa …, hãy nhắc với / hỏi bác sĩ của bé ở lần khám tới, hoặc sớm hơn nếu bạn thấy lo." For the 0–2 month items the age is "2–3 tháng". The note never names a condition. Sound and speech items add a hearing check; one-sided use, floppiness or stiffness, and loss of skills are named where apt. For an isolated social or cognitive item the note says the doctor looks at it "chung với các mốc khác".
- Two notes say when not to wait: `calms_when_held` (crying unlike usual, poor feeding, fever) and `mouths_objects` (choking → 115).
- **Age** counts from the date of birth; corrected age is not applied (§5).

## 4. Wording rules

- The test bans: vi "chậm phát triển", "bất thường", "tự kỷ", "rối loạn", "chẩn đoán", "phải đạt", "bình thường"; en "delay", "abnormal", "autism", "disorder", "diagnos", "must ", "normal". This pass also kept " late", "behind" and "should" out of the English (checked by script).
- Plain text only. The en dash appears only in ranges. `first_smile` keeps the Figma sentence and its em dash, and its whole text is unchanged (goldens render it).
- `coos` has a deliberately short note. The widget test "removing a record goes back to 3b" fails when the coos detail page grows by a long note (lazy page, scroll position). Fix the test before lengthening the note.

## 5. Verified, not verified, and open questions

- **Verified 2026-10-15**:
  - All eight CDC `act-early/milestones/*.html` pages read through a web fetch; item wording matches Zubler Tables 3–6. curl gets 403 (bot block).
  - All HealthyChildren.org, NHS and WHO URLs return 200 with matching titles.
  - The DOI redirects to the Pediatrics article.
  - PMIDs 16817682 and 35132439 (Zubler) checked.
- **Not verified**:
  1. pubmed.ncbi.nlm.nih.gov pages answer scripted requests with a bot check (203). The PMID itself was checked through the NCBI API.
  2. publications.aap.org returns 403, so the article page was not read; the full text came from PMC.
  3. The WHO page links the windows tables but does not show them in text.
  4. AAP pages were checked by title only, not read in full. Exception: the "2 year olds" page was read for "Begins make-believe play" and "Kicks a ball".
  5. "Around two and a half" for object substitution relies on the CDC 30-month item (Zubler Table 5). The CDC 30-month page is not cited.
  6. These claims come from general clinical teaching, not from a cited page:
     - early strong hand preference is worth mentioning;
     - persistent toe-walking is worth mentioning;
     - a newborn screen that was passed does not rule out later hearing loss;
     - "some babies skip crawling" (WHO: 4.3% did not crawl on hands and knees).
  7. 115 as Việt Nam's emergency number is local knowledge, not cited.
- **For the reviewer / owner**:
  - Is a doctor note on all 56 items right, or too much? Tone of the notes.
  - Doctor ages at the window end versus the CDC age (up to 1–2 months later).
  - Hearing-check wording for families without newborn screening.
  - Walker advice tone ("xe tập đi" is common).
  - Corrected age for babies born early.
  - Aligning with the Bộ Y tế "Sổ theo dõi sức khỏe bà mẹ và trẻ em".
  - Regional word choice ("lẫy", "bai bai", "măm", "ầu ơ", "ú òa").
  - Locked `follows_faces` 0–2 sits in the cognitive group (CDC: "Watches you as you move", cognitive). Its title "Nhìn theo mặt người" mixes that with "Looks at your face" (CDC social-emotional). Acceptable, but worth a look.
