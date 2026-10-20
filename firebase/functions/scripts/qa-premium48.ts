/** Dev smoke: synthetic, test_-prefixed family only. No Auth account, push token, email or real media.
 * Calls the real request core and authenticated private renderer; leaves no family/media after cleanup.
 */
import { initializeApp, deleteApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { execFileSync } from 'node:child_process';
import { randomUUID } from 'node:crypto';
import { mkdirSync, writeFileSync, readFileSync } from 'node:fs';
import { resolve, join } from 'node:path';
import { requestMemoryStory } from '../src/keepsake-jobs.js';
import type { KeepsakePublicCatalog } from '@child-life/contracts';
const arg = process.argv.indexOf('--project');
if (arg < 0 || process.argv[arg + 1] !== 'child-life-dev') throw new Error('Dev only');
const project = 'child-life-dev';
const phase = process.argv.includes('--phase5')
  ? 5
  : process.argv.includes('--phase4')
    ? 4
    : process.argv.includes('--phase3')
      ? 3
      : process.argv.includes('--phase2')
        ? 2
        : 1;
const phase2 = phase >= 2;
const phase5 = phase === 5;
const phase4 = phase === 4;
const phase3 = phase === 3;
const app = initializeApp(
  { projectId: project, storageBucket: `${project}.firebasestorage.app` },
  `p48-${randomUUID()}`,
);
const db = getFirestore(app),
  bucket = getStorage(app).bucket();
const suffix = randomUUID().replaceAll('-', '').slice(0, 12);
const babyId = `test_p48_${suffix}`,
  familyId = `test_p48_family_${suffix}`,
  uid = `test_p48_user_${suffix}`;
const out = resolve(import.meta.dirname, `../../../artifacts/premium48-phase${phase}/dev-smoke`);
mkdirSync(out, { recursive: true });
const photoIds = Array.from(
  { length: phase5 ? 8 : phase4 ? 7 : phase2 ? 10 : 5 },
  () => `med_${randomUUID().replaceAll('-', '')}`,
);
const source = resolve(
  phase2 ? `/tmp/child-life-p48-phase${phase}-photos` : '/tmp/child-life-p48-photos',
);
const licence = JSON.parse(readFileSync(join(source, 'licence.json'), 'utf8')) as {
  file: string;
}[];
const results = [];
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));
async function cleanupStorage() {
  // Retry individual deletions: Storage can return a transient 500 during bulk cleanup.
  for (let attempt = 0; ; attempt++) {
    try {
      const [files] = await bucket.getFiles({ prefix: `babies/${babyId}/` });
      for (const file of files) await file.delete({ ignoreNotFound: true });
      const [remaining] = await bucket.getFiles({ prefix: `babies/${babyId}/` });
      if (remaining.length) throw new Error('Synthetic files remain');
      break;
    } catch {
      if (attempt === 4) throw new Error('Synthetic Storage cleanup failed after retries');
      await sleep(1000 * (attempt + 1));
    }
  }
}
try {
  await db.doc(`babies/${babyId}`).set({ familyId, nickname: 'QA sample', state: 'active' });
  await db.doc(`babies/${babyId}/members/${uid}`).set({
    uid,
    role: 'coParent',
    status: 'active',
    displayName: 'QA',
    relation: 'other',
    relationCustom: null,
  });
  await db.doc(`families/${familyId}`).set({
    country: 'VN',
    timeZone: 'Asia/Ho_Chi_Minh',
    internal: true,
    quotaBytes: 1024 ** 3,
    usedBytes: 0,
  });
  for (const [i, id] of photoIds.entries()) {
    const path = `babies/${babyId}/media/${id}/display.jpg`;
    await bucket.upload(join(source, licence[phase2 ? i : [3, 1, 6, 5, 0][i]!]!.file), {
      destination: path,
      metadata: { contentType: 'image/jpeg' },
    });
    await db.doc(`babies/${babyId}/media/${id}`).set({
      id,
      babyId,
      familyId,
      type: 'photo',
      status: 'ready',
      deleted: false,
      paths: { display: path },
    });
  }
  const catalog = (await db.doc('publicConfig/keepsakes').get()).data() as KeepsakePublicCatalog;
  const renderer = execFileSync(
    'gcloud',
    [
      'run',
      'services',
      'describe',
      'keepsake-renderer',
      '--project',
      project,
      '--region',
      'asia-southeast1',
      '--format=value(status.url)',
    ],
    { encoding: 'utf8' },
  ).trim();
  const token = execFileSync('gcloud', ['auth', 'print-identity-token'], {
    encoding: 'utf8',
  }).trim();
  for (const [id, locale, format, mute] of phase2
    ? ([
        [
          phase5
            ? 'video_premium48_09'
            : phase4
              ? 'video_premium48_07'
              : phase3
                ? 'video_premium48_05'
                : 'video_premium48_03',
          'vi',
          'story',
          false,
        ],
        [
          phase5
            ? 'video_premium48_10'
            : phase4
              ? 'video_premium48_08'
              : phase3
                ? 'video_premium48_06'
                : 'video_premium48_04',
          'en',
          'portrait',
          true,
        ],
      ] as const)
    : ([
        ['video_premium48_01', 'vi', 'story', false],
        ['video_premium48_02', 'en', 'portrait', true],
      ] as const)) {
    const template = catalog.templates.find((t) => t.id === id)!;
    const before = Date.now();
    console.log('Starting dev render', id, locale, format, mute ? 'muted' : 'default music');
    const job = await requestMemoryStory(
      db,
      {
        async dispatch(baby, jobId) {
          const response = await fetch(`${renderer}/render`, {
            method: 'POST',
            headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
            body: JSON.stringify({ babyId: baby, jobId }),
          });
          const body = await response.text();
          if (!response.ok || body !== 'done')
            throw new Error(`Renderer ${response.status}: ${body}`);
        },
      },
      uid,
      {
        requestId: randomUUID(),
        babyId,
        templateId: id,
        templateVersion: template.version,
        mediaIds: photoIds.slice(
          phase2 && id.endsWith(phase5 ? '_10' : phase4 ? '_08' : phase3 ? '_06' : '_04') ? 5 : 0,
          phase2 && id.endsWith(phase5 ? '_10' : phase4 ? '_08' : phase3 ? '_06' : '_04')
            ? phase5
              ? 8
              : phase4
                ? 7
                : 10
            : template.photos.max,
        ),
        texts: { title: '', message: '' },
        locale,
        audience: 'parents',
        occasion: null,
        ...(mute ? { musicId: null } : {}),
        presentation: {
          values: Object.fromEntries(
            template.personalization!.fields.map((f) => [
              f.key,
              phase5 && f.key === 'itemName'
                ? locale === 'vi'
                  ? 'áo cotton'
                  : 'cotton outfit'
                : phase5 && f.key === 'outgrownConfirmed'
                  ? 'true'
                  : f.key === 'thenDate'
                    ? '2026-07-01'
                    : f.key === 'nowDate'
                      ? '2026-10-01'
                      : f.type === 'month'
                        ? '01'
                        : f.key === 'babyName'
                          ? phase5
                            ? id.endsWith('_10')
                              ? 'Lily'
                              : 'Noah'
                            : 'QA sample'
                          : f.type === 'date'
                            ? '2026-09-20'
                            : f.type === 'confirmation'
                              ? 'false'
                              : '',
            ]),
          ),
          overrides: {},
          crops: Array.from({ length: template.personalization!.beats.length }, () => ({
            x: 0,
            y: 0,
            zoom: 1,
            fit: 'contain',
          })),
          format,
          reducedMotion: mute,
        },
      },
      new Date(),
      'test',
    );
    let doc = await db.doc(`babies/${babyId}/keepsakeJobs/${job.jobId}`).get();
    for (let i = 0; i < 60 && !doc.get('memoryId'); i++) {
      await sleep(1000);
      doc = await doc.ref.get();
    }
    if (doc.get('status') !== 'completed' || !doc.get('memoryId'))
      throw new Error('Render or filing did not complete');
    const media = await db
      .collection(`babies/${babyId}/media`)
      .where('generated.templateId', '==', id)
      .get();
    if (media.empty) throw new Error('Generated media missing');
    const made = media.docs[0]!;
    if (made.get('generated.format') !== format) throw new Error('Generated format lost');
    const original = made.get('paths.original') as string;
    if (!original) throw new Error('Output path missing');
    await bucket
      .file(original)
      .download({ destination: join(out, `${id}-${locale}-${format}.mp4`) });
    results.push({
      id,
      locale,
      format,
      mute,
      status: doc.get('status'),
      filed: true,
      width: doc.get('output.width'),
      height: doc.get('output.height'),
      durationMs: doc.get('output.durationMs'),
      elapsedMs: Date.now() - before,
      mediaId: made.id,
    });
    console.log('Dev render and filing passed', id);
  }
  writeFileSync(join(out, 'report.json'), JSON.stringify(results, null, 2));
} finally {
  await db.recursiveDelete(db.doc(`babies/${babyId}`));
  await db.recursiveDelete(db.doc(`families/${familyId}`));
  await cleanupStorage();
  await deleteApp(app);
  console.log('Synthetic dev family and uploaded/generated media cleaned.');
}
