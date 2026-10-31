# Product Hub · developer guide

Phase 1 (D-155). How the pieces fit, how to sync, how to add a feature.

## Pieces

| Piece | Path |
|---|---|
| Schemas, enums, coverage score | `packages/contracts/src/product-hub.ts` |
| Staff function `product`, actions `product.view/edit/approve`, audit category `product` | `packages/contracts/src/staff.ts` |
| Feature registry (hand-maintained, reviewed like code) | `docs/product-hub/registry/features.json` |
| Ingestion (pure: chunking, business-map parser, facts, conflicts, change detection) | `firebase/functions/src/product-hub-ingest.ts` |
| Server (submit, review/apply, reads, sections) | `firebase/functions/src/product-hub.ts`; callables `productHub*` in `index.ts` |
| Sync CLI | `firebase/functions/scripts/product-hub-sync.ts` |
| Portal | `apps/portal/src/screens/product/*`, `apps/portal/src/messages-product-hub.ts`, route `product` |
| Tests | `packages/contracts/test/product-hub.test.ts`, `firebase/functions/test/product-hub-ingest.test.ts`, `firebase/tests/product-hub.{integration,rules}.test.ts`, `apps/portal/test/product-hub.test.tsx` |

Collections (all staff-only, denied to clients by the rules' catch-all): `productFeatures`
(+ `productSections`, `versions`), `productSources` (+ `versions`), `productChunks`,
`productDecisions`, `productConflicts`, `productChangeSets` (+ `items`). Only single-field indexes
are used; no composite index was needed.

## Syncing

```bash
pnpm --filter @child-life/contracts run build
```

```bash
cd firebase/functions && pnpm exec tsx scripts/product-hub-sync.ts --worktree --offline
```

That dry run reads the working tree and compares it with an empty state: nothing touches Firebase.
To queue a real change set, commit first (the sync reads a revision, never the dirty tree), then:

```bash
cd firebase/functions && pnpm exec tsx scripts/product-hub-sync.ts --project child-life-dev --as you@childlife.app --submit
```

Someone else with Sản phẩm › Duyệt approves it in the portal (Sản phẩm › Nguồn tri thức › Chờ
duyệt). Only one change set can be pending; `--replace-pending` replaces it. Prod needs
`CHILD_LIFE_PROD_APPROVED=yes`. `--rev <sha>` syncs another revision; `--out file.json` writes the
change set for inspection.

What a sync never does: write `config/*`, read family data, overwrite an approved section (it marks
it stale), or apply anything without review.

## Adding or changing a feature

1. Edit `docs/product-hub/registry/features.json`: id `pillar.slug`, names vi/en, globs for
   `modules`, `functions`, `tests`, `docs`, explicit `decisions`, `dependsOn`, the four status
   fields and `confidence`. Use `hubKey` only for a `featureCatalogue` key.
2. Run the offline dry run; fix any "no file matches" warning.
3. `pnpm --filter child-life-functions exec vitest run test/product-hub-ingest.test.ts` (checks the
   registry against the schema and the hub catalogue).
4. Commit, then sync with `--submit`.

## Conflict rules (v1, deterministic)

- **plan_model**: a paragraph or heading that names Free / Plus / Pro and neither mentions Premium
  nor says "not / backlog / deferred".
- **tier**: in a feature's own documents, "<name> is / là / : Premium | Beta | Free" that differs
  from the default tier in code (Beta wins over Free: "Beta miễn phí" is a free beta).
- Approved decisions and `docs/product-hub/**` are never sources of conflicts.

Conflicts are stored open and shown with every claim; nothing picks a winner.

## Running the emulator tests beside other sessions

Use an isolated emulator config (ports 8180 / 9250 / 4510 / 4610, UI off), as in the
parallel-sessions note, then:

```bash
cd firebase/tests && firebase emulators:exec --config <isolated.json> --only firestore --project demo-child-life "FIRESTORE_EMULATOR_HOST=127.0.0.1:8180 pnpm exec vitest run product-hub"
```

## Not yet built (later slices)

PH1.8 uploads (PDF/DOCX/TXT), Copilot (Phase 2), Journeys / Decisions / Opportunities tabs
(Phase 3), Insights (Phase 4). Deploying the new callables to dev is a separate step.
