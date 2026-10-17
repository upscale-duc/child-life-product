# Content release: dev → prod

How the editorial content (Sơ cứu, Nhịp lớn lên, Mẫu kỷ niệm, Dữ liệu tham chiếu, Thư viện chăm bé,
Giai đoạn của bé, Mốc phát triển) and its pictures, videos and music move from `child-life-dev` to
`child-life-prod`. Tool: `firebase/functions/scripts/content-release.ts`.

## Rules it keeps

- **Nothing is published by the tool.** Import writes drafts only: each pack becomes the open draft,
  each article / stage / milestone its Nháp under the same id. In the target portal someone other
  than the importer submits, approves and publishes (D-058 two-person rule). On prod approval needs
  the qualified review (reviewer, credential, date) — the engineering drafts (D-073 #2) cannot reach
  prod users without it.
- Asset names are content hashes (`{slug}_{sha8}`), so files are copied byte for byte to the same
  paths; a file already there is the same file and is skipped.
- Every write goes through the same server functions as the portal (`firstAidDraft`, `rhythmDraft`,
  `keepsakeDraft`, `referenceDraft`, `contentImport`): the same schemas, picture checks and audit log
  (`staffAudit`, action `content.*.draft` / `content.*.import`), recorded under the `--as` staff member.
- Dry run by default. `--apply` on prod also needs `CHILD_LIFE_PROD_APPROVED=yes` (owner approval,
  as `scripts/deploy.sh`).
- An open draft in the target (someone is editing or reviewing) is not overwritten unless
  `--replace-open-drafts` is passed; an article / stage / milestone that is waiting for review or
  approved is always left alone ("busy").

## Steps

```sh
pnpm --filter @child-life/contracts run build
cd firebase/functions
gcloud auth application-default login            # once; the account needs Firestore + Storage access

# 1. Export what dev publishes (what the dev app shows), with every asset it names.
pnpm exec tsx scripts/content-release.ts export --project child-life-dev --out ~/cl-bundles/2026-10-16

# 2. Plan (dry run): what would upload, which drafts would open, what is unchanged.
pnpm exec tsx scripts/content-release.ts import --project child-life-prod \
  --bundle ~/cl-bundles/2026-10-16 --as you@childlife.app

# 3. Apply (owner approval).
CHILD_LIFE_PROD_APPROVED=yes pnpm exec tsx scripts/content-release.ts import --project child-life-prod \
  --bundle ~/cl-bundles/2026-10-16 --as you@childlife.app --apply
```

4. In `admin.childlife.app`: for each area, a second staff member reviews the draft, records the
   review and publishes. Packs: Sơ cứu, Nhịp lớn lên (reference and content), Mẫu kỷ niệm, Dữ liệu
   tham chiếu. Items: Duyệt nội dung queue (articles, stages, milestones).

`--only firstAid,rhythm,keepsakes,reference,articles,stages,milestones` limits a run to some areas.

`seeds --out <dir>` builds the same bundle from the repo seed files (`content/`,
`firebase/functions/src/content-seed.ts`), for pushing seed changes into dev as drafts:
`import --project child-life-dev --bundle <dir> --as … --apply`. Keepsakes and reference tables have
no repo seed in this format; export them from a project.

## Prerequisites on prod

- Functions and rules deployed (the portal and the draft callables exist).
- The `--as` account is active staff on prod with Nội dung · Sửa; a second staff member (and, for
  medical content, the qualified reviewer) has Nội dung · Duyệt.
- Keepsake videos need the renderer (`KEEPSAKE_RENDERER_URL`) and music licences recorded
  (`content/keepsakes.music` travels with the bundle).

## Notes

- The bundle is a folder: `bundle.json` (validated against the contracts) and `assets/<storage path>`.
  Keep it out of git (keepsake videos make it ~80 MB).
- A table with no published version on the source is the built-in v1 every project ships, so it is
  not carried.
- The staff lookup refreshes the `--as` member's "Gần nhất" time, even on a dry run.
