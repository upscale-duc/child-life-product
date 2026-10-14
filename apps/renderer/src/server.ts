import { renderTaskSchema } from '@child-life/contracts';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { stat } from 'node:fs/promises';
import { createServer } from 'node:http';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { runJob, type RenderStore } from './job';
import { remotionRenderer } from './remotion-renderer';
import { serveFolder } from './serve';

/**
 * Cloud Run entry (private: only the Cloud Tasks service account may invoke it, so requests here
 * are already authenticated by IAM). POST /render {babyId, jobId}; GET /healthz.
 * Answers 200 when the job is done, skipped or failed for good, 500 to have Cloud Tasks retry.
 */
const bucketName = process.env.STORAGE_BUCKET;
if (!bucketName) throw new Error('STORAGE_BUCKET is not set');
initializeApp();
const db = getFirestore();
const bucket = getStorage().bucket(bucketName);

const store: RenderStore = {
  download: async (path, dest) => {
    await bucket.file(path).download({ destination: dest });
  },
  upload: async (src, path, contentType) => {
    await bucket.upload(src, { destination: path, contentType, resumable: false });
    return (await stat(src)).size;
  },
  delete: async (path) => {
    await bucket.file(path).delete({ ignoreNotFound: true });
  },
};

// The compositions bundle sits next to this file in the image (`build/` is copied to /app), so
// /app/bundle. A missing bundle stops the start-up instead of failing every job.
const bundleDir = fileURLToPath(new URL('./bundle', import.meta.url));
await stat(join(bundleDir, 'index.html'));
const renderer = await remotionRenderer(bundleDir);

const server = createServer(async (req, res) => {
  if (req.method === 'GET' && req.url === '/healthz') {
    res.writeHead(200).end('ok');
    return;
  }
  if (req.method !== 'POST' || req.url !== '/render') {
    res.writeHead(404).end();
    return;
  }
  const chunks: Buffer[] = [];
  for await (const c of req) chunks.push(c as Buffer);
  let task;
  try {
    task = renderTaskSchema.parse(JSON.parse(Buffer.concat(chunks).toString('utf8')));
  } catch {
    res.writeHead(400).end();
    return;
  }
  try {
    const outcome = await runJob(
      { db, store, renderer, serve: serveFolder, now: () => new Date() },
      task.babyId,
      task.jobId,
    );
    res.writeHead(outcome === 'retry' ? 500 : 200).end(outcome);
  } catch (e) {
    console.error('render request failed', {
      jobId: task.jobId,
      error: e instanceof Error ? e.name : 'unknown',
    });
    res.writeHead(500).end();
  }
});
server.listen(Number(process.env.PORT ?? 8080), () => console.info('renderer ready'));
