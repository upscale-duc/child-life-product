import { createHash, timingSafeEqual } from 'node:crypto';
import type { Firestore, Timestamp } from 'firebase-admin/firestore';

/**
 * "Tải tệp về" from the export email (R-187, P-123): `/exportDownload/{jobId}/{token}`. The token's
 * hash sits on the job. Each click re-checks what the Storage Rules check in the app: the job is
 * ready and not expired, and the requester is still an active Cùng nuôi of the baby (and still the
 * owner for a media export). Only then is a fresh download URL issued; the previous one stops
 * working. Nothing about the family is logged.
 */

export type ExportDownload =
  { kind: 'redirect'; url: string } | { kind: 'invalid' | 'expired' | 'denied' };

export interface DownloadIssuer {
  /** A short-lived URL for [path], served as an attachment named [filename]. */
  issue(path: string, filename: string): Promise<string>;
}

const sha = (s: string) => createHash('sha256').update(s).digest();

export async function resolveExportDownload(
  db: Firestore,
  issuer: DownloadIssuer,
  jobId: string,
  token: string,
  now: Date,
): Promise<ExportDownload> {
  if (!/^ex_[a-f0-9]{20}$/.test(jobId) || !/^[A-Za-z0-9_-]{32}$/.test(token)) {
    return { kind: 'invalid' };
  }
  const job = await db.doc(`dataJobs/${jobId}`).get();
  const hash = job.get('downloadTokenHash') as string | undefined;
  if (!job.exists || !hash || !timingSafeEqual(sha(token), Buffer.from(hash, 'hex'))) {
    return { kind: 'invalid' };
  }
  const expiresAt = job.get('expiresAt') as Timestamp | undefined;
  if (job.get('state') !== 'ready' || !expiresAt || expiresAt.toMillis() <= now.getTime()) {
    return { kind: 'expired' };
  }
  const uid = job.get('uid') as string;
  const kind = job.get('exportKind') as string;
  const member = await db.doc(`babies/${job.get('babyId') as string}/members/${uid}`).get();
  const until = member.get('accessUntilAt') as Timestamp | null | undefined;
  const allowed =
    member.exists &&
    member.get('status') === 'active' &&
    member.get('role') === 'coParent' &&
    (!until || until.toMillis() > now.getTime()) &&
    (kind !== 'media' || member.get('isOwner') === true);
  if (!allowed) return { kind: 'denied' };
  const day = (job.get('readyAt') as Timestamp | undefined)?.toDate() ?? now;
  const filename = `child-life-${kind}-${day.toISOString().slice(0, 10)}.zip`;
  return { kind: 'redirect', url: await issuer.issue(job.get('path') as string, filename) };
}
