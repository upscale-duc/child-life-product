# ADR-004 — Media upload, processing and serving (S9, interim for SP-2 / SP-3)

- **Status:** accepted for V1 on dev (2026-10-10). Revisit when SP-2 and SP-3 run on real devices with a real media corpus.
- **Context:**
  - The plan (§3.3–3.4) calls for resumable native uploads, server processing (thumbnails, video renditions, metadata stripped) and short-lived signed URLs.
  - SP-2 (background upload) and SP-3 (processing and playback) need real phones and a corpus of iPhone and Android media. Neither is available yet: there is no Apple team and no device matrix.
  - S9 must still ship memories that work end to end on the emulators and on dev.

## Decision

1. **Upload session first.**
   - The `createMemorySession` callable creates the memory, its items and the batch.
   - It reserves quota per item in a transaction on `families/{f}` (P-031).
   - Items that do not fit stay on the device as `waitingQuota` (R-121) and retry with `reserveMemoryUploads`.
   - Retries with the same ids are idempotent.
2. **The app uploads to a reserved slot.**
   - The upload uses the Firebase Storage SDK (resumable inside a process) to `babies/{b}/uploads/{mediaId}`, plus `{mediaId}.poster` for videos.
   - Storage Rules read the item in Firestore (cross-service Rules). Only the uploader can write, only while the item is `uploading`, within the declared size and with the declared content type.
   - The device keeps its own persisted queue. Items survive an app kill and resume on the next launch, which is SP-2's documented fallback for iOS. A URLSession / WorkManager background transfer stays the SP-2 target.
3. **Photos become JPEG on the device** (SP-3 fallback for HEIC). The server then re-encodes every photo with `sharp`:
   - auto-orient;
   - `original.jpg` ≤ 4096 px, `display.jpg` ≤ 1600, `thumb.jpg` ≤ 480;
   - **no metadata is kept**, so EXIF and GPS are dropped from originals and renditions (P-033).
   - The type is checked from the first bytes, never from the declared type. Anything else becomes `unreadable` and its reservation is released.
4. **Videos are stored as recorded** (MP4 / QuickTime, sniffed from the `ftyp` box).
   - The device makes a poster frame, which the server turns into `poster.jpg` and `thumb.jpg`.
   - There are no renditions yet (SP-3).
   - **Known gap:** a video's own metadata (it can contain a location) is not stripped until SP-3 brings a transcoding step.
5. **Serving through Rules, not signed URLs.**
   - The app reads `babies/{b}/media/{m}/*` with the Storage SDK and caches the bytes on the device; media files are immutable.
   - Storage Rules apply the same audience checks as Firestore:
     - Cùng nuôi see everything;
     - relatives see only ready, not-deleted items whose `effectiveAudience` is `family` (D-002, P-035);
     - caregivers see nothing.
   - This needs no URL-signing IAM. Access is re-checked on every read, so a changed audience or a removed member takes effect at once. There is no CDN.
   - Signed URLs remain an option for long videos if playback after a full download proves too slow (SP-3).
6. **`sharp` is installed by Cloud Build.**
   - It stays external to the esbuild bundle and is listed in `deploy/package.json`.
   - The generated lockfile carries the Linux binaries.

## Consequences

- **IAM on dev:**
  - The Storage service agent needs `roles/firebaserules.firestoreServiceAgent` for the cross-service Rules. It was granted on `child-life-dev` on 2026-10-10.
  - The Cloud Storage service agent needs `roles/pubsub.publisher` for the finalize trigger.
  - Prod needs both, with owner approval.
- **Limits:**
  - Raw photo uploads are capped at 50 MB.
  - Videos are capped by `config/limits.videoMaxBytes` (D-011).
  - The batch size is capped by `config/limits.mediaItemsPerAdd` (R-102).
- **Notifications:** one generic notice per batch is recorded in `babies/{b}/notifications/{batchId}` (P-030, R-120). Delivery to devices comes with S10.
- **Revisit when:** SP-2 measures kill-and-resume on devices, or SP-3 measures HEIC/HEVC handling, playback and cost.
