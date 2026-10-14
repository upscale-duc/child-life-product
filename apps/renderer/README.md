# Video kỷ niệm renderer

Renders Video kỷ niệm (D-068) with [Remotion](https://www.remotion.dev) on a private Cloud Run service.
The design is in `docs/product/remember-2-plan.md` §5, and the job contract is
`packages/contracts/src/keepsake-jobs.ts`.

## Licence

Remotion is free for individuals and for companies with at most 3 people (D-068 #1). A company that
grows past that needs a Remotion Company License before it keeps using it.

## How it runs

1. `requestMemoryStory` (Functions) writes `babies/{b}/keepsakeJobs/{jobId}`. The job holds a snapshot
   of the template, the photo paths and the texts.
2. Functions queue a Cloud Task, which POSTs `{babyId, jobId}` to `/render` with an OIDC token from
   `keepsake-tasks@`. The service is private: only that account may invoke it.
3. `runJob` claims the job and downloads the photos (display renditions) and music into a temp folder.
   It serves them to Chrome on 127.0.0.1 only, since child media never gets a public URL.
4. It renders `<composition>` (1080 × 1920, H.264, AAC) plus a poster frame, uploads
   `babies/{b}/media/{mediaId}/original.mp4` and `frame.jpg`, and marks the job completed.
5. `onKeepsakeJobWritten` (Functions) files the video in Kỷ niệm and sends the push to the person who
   asked (D-068 #4).

**Answers:**
- `200`: done, skipped (already handled) or failed for good.
- `500`: Cloud Tasks retries. A job gets at most 3 attempts.

**Logs:** ids, template ids, timings and error codes only. Never names, texts or paths.

## Compositions

`src/compositions/Root.tsx` lists the compositions a template may name: `FirstMonth`, `FirstWeek`,
`HundredDays` and `LittleMoments`. Adding one is a renderer deploy, never an app release. Colours,
texts, photos and music come from the template and the job, both portal-managed (D-068 #7).

## Commands

```sh
pnpm --filter child-life-renderer studio                      # Remotion Studio with sample props
pnpm --filter child-life-renderer sample <photos> <out> FirstMonth [--video]   # stills / MP4 from placeholders
node apps/renderer/scripts/compose-music.mjs <dir>                          # the two original sample tracks (WAV)
pnpm --filter child-life-renderer exec tsx scripts/make-previews.ts <photos> <dir> <out>   # Xem mẫu MP4s + M4A tracks (see preview-credits.md)
pnpm --filter child-life-renderer build                       # build/: server.js + Remotion bundle + package.json
firebase emulators:exec --only firestore "pnpm --filter child-life-renderer exec vitest run"
```

## Deploy (dev)

Run `scripts/deploy-renderer.sh dev`. It needs the owner's go-ahead the first time, because it creates
billable resources. The script does the following:
- Builds the image with Cloud Build into Artifact Registry.
- Deploys the Cloud Run service `keepsake-renderer` in asia-southeast1:
  - private, run as `keepsake-renderer@`;
  - concurrency 1, at most 3 instances, 4 vCPU / 8 GiB, 15 min timeout, min instances 0;
  - environment `STORAGE_BUCKET`.
- Creates the Cloud Tasks queue `keepsake-render` (3 attempts, back-off 30 s → 5 min).
- Grants IAM:
  - `keepsake-tasks@` → `run.invoker` on the service;
  - the Functions runtime account → `cloudtasks.enqueuer` and `iam.serviceAccountUser` on `keepsake-tasks@`;
  - `keepsake-renderer@` → Firestore user and Storage object admin.
- Writes `KEEPSAKE_RENDERER_URL` to `firebase/functions/.env.child-life-dev`.

Prod needs owner approval.
