# 03 · Existing documentation inventory

Snapshot 2026-10-31. `docs/` holds **244 Markdown files, ~73 k lines, ~7 MB**. Outside `docs/`
there are working notes (`CLAUDE.md`, `AGENTS.md`, app READMEs), design skills
(`.claude/skills/**`, 52 files) and content seeds (`content/**`). `.claude/worktrees/**`
(762 files) are copies of the repo in other sessions' worktrees and must never be ingested.

## 1. Corpus by area and proposed default authority

Authority classes follow the brief §9.5. A document's class can be raised or lowered per file in
review; these are the **defaults the sync applies** to new files under each path.

| Path | Files | Lines | What it is | Default authority | Language |
|---|---:|---:|---|---|---|
| `docs/product/business-map.md` | 1 | 1 042 | D/R/P/Q/G registry: owner decisions, Figma rules, proposals, questions, gaps | **Parsed into decision records** — D-xxx = approved decision; R-xxx = design reference (history, D-104); P-xxx = draft spec unless a D-xxx approves it; Q-xxx = open question; G-xxx = gap | EN |
| `docs/product/*-plan.md`, `*-analysis.md` | 30 | ~11 600 | Feature plans and PM analyses (premium-v2, lumi, rhythm, auto-save, print studio, vaccination, solids, spending…) | Draft specification; sections approved by a cited D-xxx become approved specification | EN/VI |
| `docs/product/figma-coverage-checklist.md` | 1 | ~500 rows | V1 scope tracker with strict "done" definition | Design reference + implementation evidence (per row) | EN |
| `docs/product/adaptive-experience-audit/`, `content-review-2026-10/` | 20 | ~2 600 | Audits and content reviews | Research | VI/EN |
| `docs/product-audit/` | 20 | 2 406 | 2026-10-20 product audit: inventory, Memories, Lumi, journeys, gaps, smart reminders | Research (dated); evidence links to code are useful | VI |
| `docs/audits/pre-release/` + `docs/audits/*.md` | 14 | ~2 400 | Pre-release audit (bugs, UX, security, readiness, release decision) and recent audits | Research (dated) | VI/EN |
| `docs/assistant/` | 14 | 3 042 | Lumi architecture, API, tools, data, security, evaluations, runbook | Technical architecture; eval reports = research | EN |
| `docs/notifications/` | 10 | 874 | Notification platform plan → implementation report | Technical architecture / approved spec where D-cited | EN |
| `docs/product-analytics/` | 8 | 833 | Metric dictionary, event plan, data architecture | Approved specification for metrics (verify per metric) | EN |
| `docs/architecture/` | 4 | 69 | ADR-001…004 | Approved decision (technical) | EN |
| `docs/development/` (+ `slice-reports/`) | 33 | ~5 800 | Implementation plan, slice reports S0–S15, phase reviews, test reports | Implementation evidence (dated, needs revision pin) | EN |
| `docs/design/` (+ `reviews/`, `proposals/`, `explorations/`) | 36 | ~10 700 | Design-system discovery, design reviews with rendered evidence, explorations | Design reference / research | EN/VI |
| `docs/discovery/figma-extract/` | 43 | ~30 900 | Saved Figma extraction by area with node ids, images | Design reference (history, D-104/D-137) | EN/VI |
| `docs/discovery/*.md` | 2 | ~31 000 | Product-plan site extract; adaptive-experience chat log | Research (the chat log is very large and low-signal → exclude by default) | VI/EN |
| `docs/operations/` | 2 | 137 | Content release, premium rollout | Technical runbook | EN |
| `CLAUDE.md`, `AGENTS.md` | 2 | — | Working rules for engineering agents | Exclude (process, not product) | EN |
| `.claude/skills/**` | 52 | — | Design and writing skills (glossary, UX rules) | Exclude by default; optionally the `cl-ux-writing` glossary as a reference | EN |
| `content/**` | JSON + 9 `.md` | — | Published editorial content seeds | Exclude (content, not product knowledge; already in the portal's content tools) | VI |

## 2. Quality observations that shape the ingestion design

1. **Ids are the backbone.** D/R/P/Q/G ids appear across plans, code comments and reviews
   ("Cite ids in code comments where a rule is enforced", CLAUDE.md). Extracting id mentions per
   chunk gives cheap, precise feature ↔ decision ↔ code links without embeddings.
2. **Dates are in file names and headings** (`2026-10-28-…`, "Snapshot 20/10/2026"). The sync
   can use them as a freshness hint alongside git history.
3. **Many documents are snapshots, not living specs** (audits, reviews, slice reports). They are
   true *as of their date and commit*; the Hub must show that date, not present them as current.
4. **Mixed language.** Product plans are mostly English; audits and owner quotes are Vietnamese.
   Search must be accent-insensitive for Vietnamese and handle both languages; answers follow the
   portal locale.
5. **Superseded statements are explicit but scattered** ("Since D-104 … apply to V1 scope only",
   "merged (owner, 2026-10-21)"). The decision parser must capture `supersedes` / `resolves`
   columns from the business-map tables.
6. **Large files.** `adaptive-experience-chat.md` and several figma-extract files are tens of
   thousands of lines; chunking must cap chunk size and skip excluded files before reading them.
7. **Code is the implementation truth, docs are intent or history.** Example conflict already in
   the corpus: `plans-credits-analysis.md` ("proposal", Free / Plus / Pro usage tiers) vs D-075 /
   D-089 and `featureTiers = ['free','premium','beta']` in code. The Hub must show both with their
   authority, never pick silently.

## 3. Proposed default include / exclude (sync config v1)

```yaml
include:
  - docs/**/*.md
exclude:
  - docs/discovery/adaptive-experience-chat.md     # raw chat log
  - docs/**/img/**
  - docs/design/reviews/assets/**
  - "**/node_modules/**"
  - .claude/**                                      # skills + other sessions' worktrees
  - apps/**/test/**
  - content/**
  - "**/*.g.md"
size_limit_kb: 512                                  # larger files: headings-only index + owner review
```

Estimated volume after exclusions: ~240 files, ~4–5 k chunks at ~1.5 KB each, comfortably within
Firestore limits and small enough for keyword retrieval (no vector store needed in v1).
