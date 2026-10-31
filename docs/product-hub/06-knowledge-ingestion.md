# 06 · Knowledge ingestion architecture

## 1. Shape

```
 repo @ revision ──► scripts/product-hub-sync.ts (local / CI, ADC, --as staff)
   docs/**/*.md         │ 1 discover (include/exclude)        │
   business-map.md      │ 2 parse (headings, tables, ids)     │ dry run by default:
   contracts (tiers,    │ 3 extract facts (modules, flags,    │ prints the change set
     capabilities,      │   callables, tests, decision ids)   │
     flags)             │ 4 chunk + hash                      │
   feature registry     │ 5 diff vs last applied revision     │
   seed (JSON)          ▼                                     │
            productHubSyncSubmit (staffCall, product:edit) ───┘
                        │ validates (zod), writes a pending change set
                        ▼
            Portal › Nguồn tri thức › Chờ duyệt ── approve/reject ──► productSources / Chunks /
                        │                                              Decisions / Links / Features
                        ▼                                              (+ versions, staffAudit)
            productHubBuildIndex ──► Storage productHub/index/{revision}.json.gz
                        │
 Portal upload ──► Storage ──► productHubProcessUpload (extract text) ──► change set (same queue)
```

The portal never reads the repository. The sync is a sibling of
`firebase/functions/scripts/content-release.ts` and keeps its safeguards: dry run unless
`--apply`; prod only with `CHILD_LIFE_PROD_APPROVED=yes`; every write through a callable under
the `--as` staff member, so the same schema checks and audit apply.

## 2. Steps in detail

### 2.1 Discover
- Globs from `defaultSyncConfig` in `product-hub-ingest.ts` (default in [03 §3](03-documentation-inventory.md#3-proposed-default-include--exclude-sync-config-v1)).
- Skips symlinks, files over `size_limit_kb` (indexed by headings only, flagged for review),
  anything matching secret patterns (`*.env*`, `*key*.json`, PEM headers) — refused, not
  silently skipped.
- Records repo-relative path, git blob SHA, last commit touching the file, and a content hash
  (SHA-256 of normalized text: LF, trimmed trailing spaces).
- Requires a clean revision for `--apply` (no uncommitted changes in included paths), so every
  record points at a commit someone can open. Dry runs may use a dirty tree and say so.

### 2.2 Change detection (incremental)
- Key = path; identity across moves = blob SHA. Classification against the last **applied**
  run: `added`, `changed` (same path, new hash), `moved` (same blob SHA, new path; keeps the
  source id, updates path), `deleted` (path gone, blob not found elsewhere), `unchanged`.
- Unchanged files produce nothing. Re-running the same revision is a no-op (idempotent;
  "duplicate ingestion" is impossible because chunk ids are content-addressed).

### 2.3 Parse and chunk
- Markdown → heading tree with a small built-in parser (no new dependency).
- Chunk = one heading section; sections over 4 KB split at paragraph or table-row boundaries;
  tables keep their header row in every piece; code blocks never split.
- Each chunk stores its heading path (`["7. Confirmed business rules", "7.3 Care logging"]`), an
  anchor, detected language (vi/en by diacritic ratio), and **ids mentioned** (regex
  `\b[DRPQG]-\d{3}\b`, `MET-\d+`, `S\d+`, figma node `\d+:\d+`).

### 2.4 Business-map parser
- Reads the decision tables and §12–§14 lists into `productDecisions` rows: id, kind, date (from
  the "owner, YYYY-MM-DD" text), title (first bold phrase), text, `resolves`, consequence.
- `supersedes` is taken from explicit text ("supersedes D-0xx", "replaces", "Since D-104") and
  from `Resolves` columns pointing at Q-ids → status `resolved`.
- Any row the parser cannot read is reported in the change set as `unparsed` (never dropped).

### 2.5 Fact extraction (code metadata only)
From the pinned revision, without executing app code:
- **Contracts**: import the built `@child-life/contracts` → `featureCatalogue`, `capabilities`,
  `freeCapabilities`, `premiumCapabilities`, `creditCapabilities`, `capabilityFlag`, `flagKeys`.
- **Registry seed**: `docs/product-hub/registry/features.json` (JSON, so no new dependency) — per
  feature: id, names, pillar, module globs, function file globs, hubKey, test globs, figma
  nodes, doc globs. The seed is hand-maintained and reviewed like code; the sync resolves globs to
  concrete files at the revision and reports globs that match nothing (dead references).
- **Callables**: names exported from `firebase/functions/src/index.ts` matched to the files
  listed in the seed.
- **Decision mentions in code**: `D-xxx` / `R-xxx` / `P-xxx` in comments → `implements` links
  with file:line evidence.

### 2.6 Feature association
Deterministic, in order, each link recording which rule produced it:
1. Explicit: the seed's `docs` globs.
2. Path: plan file name matches feature slug (`vaccination-plan.md` → `care.vaccines`).
3. Id bridge: chunk mentions a decision already linked to the feature.
4. Term match: feature names and aliases (vi + en, accent-folded) in headings.
Rules 3–4 create **suggested** links, approved in the review queue; 1–2 are applied directly.

### 2.7 Conflict detection (v1, deterministic)
Conflicts are only raised where a machine can compare like with like:
- **Tier claims**: chunks that state a tier for a feature ("Premium", "miễn phí", "Free",
  "beta") vs the code default tier vs the latest approved D-xxx mentioning that feature and a
  tier. Disagreement → `productConflicts` row with all claims, authorities and dates.
- **Superseded citations**: an approved section or a draft-spec chunk cites a decision whose
  status is `superseded`.
- **Dead references**: a section cites a file/line or callable that no longer exists at the
  revision.
- **Stale approvals**: a source changed after the section that cites it was approved.
Free-text contradiction finding by AI is Phase 3, and only ever produces *suggested* conflicts.

### 2.8 Review and apply
- `productHubSyncSubmit` stores the change set as `pending`. Nothing reaches the library, the
  search index or the Copilot until approved.
- Approval applies in one batch: new source versions, chunks, decisions, links; marks sections
  whose sources changed as `stale` (never rewrites them); rebuilds the index.
- Rejecting keeps the previous version active and records why (optional reason, D-090).
- **Approved narrative is never overwritten by a sync.** At most it becomes `stale` with a link
  to the diff that made it stale.

### 2.9 Uploads (Phase 1b)
- Client uploads to `productHub/uploads/...` through a signed upload URL from
  `productHubUploadStart` (type and size checked server-side: `.md .txt .pdf .docx`, ≤ 10 MB,
  ≤ 10 files per request).
- `productHubProcessUpload` (Storage trigger, not public) extracts text: Markdown/TXT as is;
  DOCX via `mammoth` (headings preserved); PDF via `pdfjs-dist` text layer (no OCR in v1;
  image-only PDFs are marked `failed: no_text`). New dependencies are function-side only and
  justified in the Phase 1b PR.
- Output enters the same change-set queue with authority defaulting to `draft_spec`.

### 2.10 Search index
- Built after each approval: BM25 over chunk text + heading path, Vietnamese accent folding,
  lowercase, simple tokenization (no stemming), id tokens kept whole. Boosts: heading match ×2,
  exact id match ×5, authority weight (verified implementation 1.0 … AI inference 0.3), feature
  scope filter.
- Stored as one gzipped JSON in Storage (~2–4 MB for ~5 k chunks), loaded and cached in memory
  by `productHubSearch` / Copilot instances (keyed by revision).
- **No embeddings in v1.** Phase 2 measures retrieval on a fixed question set (see
  [07 §6](07-ai-copilot.md#6-evaluation)); embeddings are added only if recall@8 < 0.8 on it.

## 3. Future CI synchronization

The same script runs in CI on merges that touch included paths, in **dry-run + submit** mode with
a dedicated service identity mapped to a staff role with `product: edit` only. CI never approves.
No CI exists in the repo today (deploys are `scripts/deploy.sh`), so v1 is manual.

## 4. Prompt-injection posture for ingested text

Imported text is data. It is stored and shown sanitized (Markdown rendered without raw HTML or
scripts), and in the Copilot it is passed inside clearly delimited, quoted context blocks with an
instruction that it cannot change the assistant's rules; the Copilot has no tools that write or
call out (see [08](08-security.md)).
