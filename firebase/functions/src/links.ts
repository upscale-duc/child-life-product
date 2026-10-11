import { createHash, createHmac, randomBytes, randomInt, timingSafeEqual } from 'node:crypto';
import {
  ageLabel,
  createShareLinkSchema,
  linkExpiries,
  linkTokenSchema,
  localDateIn,
  passcodeLimits,
  recordCardSchema,
  revokeShareLinkSchema,
  slugOf,
  type StoryBlock,
} from '@child-life/contracts';
import {
  FieldValue,
  Timestamp,
  type DocumentSnapshot,
  type Firestore,
} from 'firebase-admin/firestore';
import type { MediaStore } from './memories.js';
import type { PageLocale } from './pages.js';

/**
 * External sharing (S13, 14h–14n). Links live in server-only `shareLinks/{token}`; the creator's
 * list ("Đã chia sẻ ra ngoài", 14m) is mirrored in `users/{uid}/sharedOut`. The page `/s/{token}`
 * renders a live projection of the saved story at view time (P-095): only photos the family can
 * see, nothing deleted, no real name or birth date unless the parent chose to show it. Images are
 * served here after the same checks. A view-only page cannot stop screenshots (R-166).
 */

export class LinkError extends Error {
  constructor(
    readonly code: 'invalid-argument' | 'failed-precondition' | 'permission-denied' | 'not-found',
    readonly reason: string,
  ) {
    super(reason);
  }
}

const HOUR_MS = 3_600_000;
const sha = (s: string) => createHash('sha256').update(s).digest('hex');
const ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
const newToken = () =>
  Array.from({ length: 16 }, () => ALPHABET[randomInt(ALPHABET.length)]).join('');

function parse<T>(
  schema: { safeParse(d: unknown): { success: boolean; data?: T } },
  data: unknown,
): T {
  const r = schema.safeParse(data);
  if (!r.success) throw new LinkError('invalid-argument', 'malformed');
  return r.data as T;
}

async function requireParent(db: Firestore, babyId: string, uid: string, now: Date) {
  const m = await db.doc(`babies/${babyId}/members/${uid}`).get();
  const until = m.get('accessUntilAt') as Timestamp | null | undefined;
  if (
    !m.exists ||
    m.get('status') !== 'active' ||
    (until && until.toMillis() <= now.getTime()) ||
    m.get('role') !== 'coParent'
  ) {
    throw new LinkError('permission-denied', 'parents-only');
  }
  return m;
}

async function savedStory(db: Firestore, babyId: string, storyId: string) {
  const story = await db.doc(`babies/${babyId}/stories/${storyId}`).get();
  // "Lưu xong mới chia sẻ ra ngoài được." (R-135)
  if (!story.exists || story.get('status') !== 'saved')
    throw new LinkError('failed-precondition', 'not-saved');
  return story;
}

// ---------- Callables ----------

/** 14k "Sao chép & chia sẻ". The passcode, when asked for, is returned once (P-096). */
export async function createShareLink(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
  webOrigin: string,
): Promise<{ token: string; url: string; passcode: string | null; expiresAt: string }> {
  const req = parse(createShareLinkSchema, data);
  const me = await requireParent(db, req.babyId, uid, now);
  const story = await savedStory(db, req.babyId, req.storyId);
  const baby = await db.doc(`babies/${req.babyId}`).get();
  if (baby.get('state') === 'deleting') throw new LinkError('failed-precondition', 'deleting');
  const key = `link_${sha(`${uid}:${req.requestId}`).slice(0, 24)}`;
  const existing = await db.doc(`users/${uid}/sharedOut/${key}`).get();
  if (existing.exists) {
    const token = existing.get('token') as string;
    return {
      token,
      url: `${webOrigin}/s/${token}-${existing.get('slug') as string}`,
      passcode: null,
      expiresAt: (existing.get('expiresAt') as Timestamp).toDate().toISOString(),
    };
  }
  const token = newToken();
  const slug = slugOf(baby.get('nickname') as string);
  const expiresAt = new Date(now.getTime() + linkExpiries[req.expiry] * HOUR_MS);
  const passcode = req.passcode ? String(randomInt(10_000)).padStart(4, '0') : null;
  const salt = randomBytes(16).toString('hex');
  const batch = db.batch();
  batch.create(db.doc(`shareLinks/${token}`), {
    babyId: req.babyId,
    storyId: req.storyId,
    createdBy: uid,
    sharerName: ((me.get('displayName') as string) ?? '').split(' ').pop() ?? '',
    slug,
    hideIdentity: req.hideIdentity,
    allowDownload: req.allowDownload,
    passcodeHash: passcode ? sha(`${salt}:${passcode}`) : null,
    salt,
    cookieKey: randomBytes(32).toString('hex'),
    views: 0,
    status: 'active',
    expiresAt,
    createdAt: now,
  });
  batch.create(db.doc(`users/${uid}/sharedOut/${key}`), {
    kind: 'link',
    token,
    slug,
    babyId: req.babyId,
    storyId: req.storyId,
    title: story.get('title'),
    coverMediaId: story.get('coverMediaId') ?? null,
    views: 0,
    status: 'active',
    expiresAt,
    passcode: passcode !== null,
    createdAt: now,
  });
  batch.create(db.collection('audit').doc(), {
    action: 'link.create',
    actor: uid,
    babyId: req.babyId,
    target: req.storyId,
    category: 'data',
    at: now,
  });
  await batch.commit();
  return {
    token,
    url: `${webOrigin}/s/${token}-${slug}`,
    passcode,
    expiresAt: expiresAt.toISOString(),
  };
}

/** 14m "Thu hồi": the link stops at once. */
export async function revokeShareLink(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<void> {
  const { token } = parse(revokeShareLinkSchema, data);
  const ref = db.doc(`shareLinks/${token}`);
  const link = await ref.get();
  if (!link.exists || link.get('createdBy') !== uid) throw new LinkError('not-found', 'not-found');
  const mirrors = await db.collection(`users/${uid}/sharedOut`).where('token', '==', token).get();
  const batch = db.batch();
  batch.update(ref, { status: 'revoked', revokedAt: now });
  mirrors.docs.forEach((d) => batch.update(d.ref, { status: 'revoked', revokedAt: now }));
  batch.create(db.collection('audit').doc(), {
    action: 'link.revoke',
    actor: uid,
    babyId: link.get('babyId'),
    target: token,
    category: 'data',
    at: now,
  });
  await batch.commit();
}

/** "Thiệp ảnh đã lưu" (R-162): recorded when a card leaves the phone. */
export async function recordCard(
  db: Firestore,
  uid: string,
  data: unknown,
  now: Date,
): Promise<void> {
  const req = parse(recordCardSchema, data);
  await requireParent(db, req.babyId, uid, now);
  const story = await savedStory(db, req.babyId, req.storyId);
  const key = `card_${sha(`${uid}:${req.requestId}`).slice(0, 24)}`;
  await db.doc(`users/${uid}/sharedOut/${key}`).set({
    kind: 'card',
    babyId: req.babyId,
    storyId: req.storyId,
    template: req.template,
    title: story.get('title'),
    coverMediaId: story.get('coverMediaId') ?? null,
    createdAt: now,
  });
}

/** Expired links close; their mirror rows move to "Đã hết hạn". */
export async function expireLinks(db: Firestore, now: Date): Promise<number> {
  const snap = await db
    .collection('shareLinks')
    .where('status', '==', 'active')
    .where('expiresAt', '<=', now)
    .limit(200)
    .get();
  for (const d of snap.docs) {
    await d.ref.update({ status: 'expired' });
    const mirrors = await db
      .collection(`users/${d.get('createdBy') as string}/sharedOut`)
      .where('token', '==', d.id)
      .get();
    for (const m of mirrors.docs) await m.ref.update({ status: 'expired' });
  }
  return snap.size;
}

// ---------- The page ----------

export interface ShareRequest {
  method: string;
  path: string;
  ip: string;
  cookies: Record<string, string>;
  form: Record<string, string>;
  locale: PageLocale;
}

export interface ShareResponse {
  status: number;
  type: 'html' | 'jpeg' | 'redirect';
  body: string | Uint8Array;
  headers: Record<string, string>;
  cookies: Array<{ name: string; value: string; maxAge: number }>;
}

const escape = (v: string) =>
  v.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

const copy = {
  vi: {
    gone: [
      'Liên kết không còn dùng được',
      'Có thể liên kết đã hết hạn, bị thu hồi hoặc gõ sai. Nhờ người gửi chia sẻ lại nhé.',
    ],
    expired: ['Liên kết đã hết hạn', 'Nhờ người gửi tạo liên kết mới nhé.'],
    passTitle: 'Nhập mật mã',
    passBody: 'Người gửi đã đặt mật mã 4 số cho câu chuyện này.',
    passWrong: 'Mật mã chưa đúng. Thử lại nhé.',
    passLocked: 'Thử sai quá nhiều lần. Đợi 15 phút rồi thử lại.',
    open: 'Mở',
    shared: (who: string) => `${who} chia sẻ`,
    noDownloadNote: 'Người gửi không cho tải ảnh về.',
    close: 'Đóng',
    prev: 'Ảnh trước',
    next: 'Ảnh sau',
    download: 'Tải ảnh',
    tagline: 'Lưu giữ kỷ niệm của bé cùng gia đình',
    getApp: 'Tải app',
    born: (d: string) => `sinh ngày ${d}`,
  },
  en: {
    gone: [
      'This link no longer works',
      'It may have expired, been revoked or mistyped. Ask the sender to share again.',
    ],
    expired: ['This link has expired', 'Ask the sender for a new link.'],
    passTitle: 'Enter the passcode',
    passBody: 'The sender set a 4-digit passcode for this story.',
    passWrong: 'That passcode isn’t right. Try again.',
    passLocked: 'Too many tries. Wait 15 minutes and try again.',
    open: 'Open',
    shared: (who: string) => `shared by ${who}`,
    noDownloadNote: 'The sender turned off photo downloads.',
    close: 'Close',
    prev: 'Previous photo',
    next: 'Next photo',
    download: 'Download photo',
    tagline: 'Keep your baby’s memories with the family',
    getApp: 'Get the app',
    born: (d: string) => `born ${d}`,
  },
} as const;

function shell(locale: PageLocale, title: string, body: string, landing: string): string {
  const t = copy[locale];
  return `<!doctype html><html lang="${locale}"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex,nofollow">
<title>${escape(title)} · Child Life</title>
<style>
body{margin:0;background:#FBF6ED;color:#173D44;font-family:'Be Vietnam Pro',system-ui,-apple-system,sans-serif}
main{max-width:520px;margin:0 auto;padding:0 0 120px}
.cover{width:100%;aspect-ratio:4/3;object-fit:cover;display:block;background:#EEF6F5}
.pad{padding:20px}h1{font-size:28px;line-height:1.25;margin:4px 0 6px}
.meta{color:#55707A;font-size:14px}.p{font-size:17px;line-height:1.65;margin:16px 0}
.grid{display:grid;grid-template-columns:repeat(3,1fr);gap:4px;margin:16px 0}
.grid img{width:100%;aspect-ratio:1;object-fit:cover;border-radius:10px;background:#EEF6F5}
.dl{display:block;font-size:12px;color:#06716D;margin-top:2px}
.note{display:flex;gap:8px;color:#55707A;font-size:13px;background:#F1EADC;border-radius:14px;padding:12px;margin-top:20px}
.card{background:#fff;border-radius:24px;padding:24px;margin:40px 20px;box-shadow:0 8px 24px #173d4414}
.banner{position:fixed;left:0;right:0;bottom:0;background:#fff;box-shadow:0 -6px 24px #173d4414;display:flex;align-items:center;gap:12px;padding:12px 16px}
.banner b{display:block}.banner span{font-size:13px;color:#55707A}.banner a{margin-left:auto;background:#087F7B;color:#fff;text-decoration:none;border-radius:999px;padding:10px 18px;font-weight:600}
input{font-size:28px;letter-spacing:12px;width:9ch;text-align:center;border:2px solid #087F7B;border-radius:14px;padding:8px;margin:12px 0}
button{background:#087F7B;color:#fff;border:0;border-radius:999px;padding:12px 24px;font-size:16px;font-weight:600}
.err{color:#A12B32}
.grid a,.cover-link{display:block}
.lb{display:none;position:fixed;inset:0;z-index:10;background:#0c1719f2;align-items:center;justify-content:center}
.lb:target{display:flex}
.lb .bg{position:absolute;inset:0}
.lb img{position:relative;max-width:100%;max-height:100%;object-fit:contain;pointer-events:none}
.lb .x,.lb .nav{position:absolute;color:#fff;text-decoration:none;font-size:30px;line-height:44px;width:44px;height:44px;text-align:center;border-radius:999px;background:#ffffff26}
.lb .x{top:16px;right:16px}.lb .prev{left:12px;top:50%;margin-top:-22px}.lb .next{right:12px;top:50%;margin-top:-22px}
.lb .lbdl{position:absolute;bottom:24px;left:50%;transform:translateX(-50%);color:#fff;font-size:14px;background:#ffffff26;border-radius:999px;padding:8px 16px;text-decoration:none}
</style></head><body><main>${body}</main>
<div class="banner"><div><b>Child Life</b><span>${escape(t.tagline)}</span></div><a href="${escape(landing)}">${escape(t.getApp)}</a></div>
</body></html>`;
}

const html = (
  status: number,
  body: string,
  cookies: ShareResponse['cookies'] = [],
): ShareResponse => ({
  status,
  type: 'html',
  body,
  headers: {
    'Cache-Control': 'private, no-store',
    'X-Robots-Tag': 'noindex, nofollow',
    'Referrer-Policy': 'no-referrer',
    'Content-Security-Policy':
      "default-src 'none'; img-src 'self'; style-src 'unsafe-inline'; form-action 'self'; base-uri 'none'; frame-ancestors 'none'",
  },
  cookies,
});

function message(
  locale: PageLocale,
  [title, body]: readonly [string, string],
  landing: string,
  status = 404,
) {
  return html(
    status,
    shell(
      locale,
      title,
      `<div class="card"><h1>${escape(title)}</h1><p class="meta">${escape(body)}</p></div>`,
      landing,
    ),
  );
}

const cookieName = (token: string) => `cl_pass_${token}`;
const seenName = (token: string) => `cl_seen_${token}`;
const passCookie = (link: DocumentSnapshot, token: string) =>
  createHmac('sha256', link.get('cookieKey') as string)
    .update(token)
    .digest('hex');

function sameSecret(a: string, b: string): boolean {
  const x = Buffer.from(a);
  const y = Buffer.from(b);
  return x.length === y.length && timingSafeEqual(x, y);
}

/** The projection (P-095): ready, not-deleted photos the family can see, in story order. */
async function projection(db: Firestore, link: DocumentSnapshot) {
  const babyId = link.get('babyId') as string;
  const story = await db.doc(`babies/${babyId}/stories/${link.get('storyId') as string}`).get();
  if (!story.exists || story.get('status') !== 'saved') return null;
  const blocks = (story.get('blocks') as StoryBlock[] | undefined) ?? [];
  const ids = [
    ...new Set([
      ...((story.get('coverMediaId') as string | null)
        ? [story.get('coverMediaId') as string]
        : []),
      ...blocks.flatMap((b) => (b.type === 'photos' ? b.items.map((i) => i.mediaId) : [])),
    ]),
  ];
  const media = ids.length
    ? await db.getAll(...ids.map((m) => db.doc(`babies/${babyId}/media/${m}`)))
    : [];
  const visible = media.filter(
    (m) =>
      m.exists &&
      m.get('status') === 'ready' &&
      m.get('deleted') !== true &&
      m.get('effectiveAudience') === 'family' &&
      m.get('type') === 'photo',
  );
  return { story, babyId, blocks, visible };
}

/** Handles GET/POST `/s/{token}[-slug]` and GET `/s/{token}/m/{mediaId}`. */
export async function handleShare(
  db: Firestore,
  store: MediaStore,
  req: ShareRequest,
  now: Date,
  landing: string,
): Promise<ShareResponse> {
  const t = copy[req.locale];
  const parts = req.path.split('/').filter(Boolean); // ['s', 'token-slug', 'm', 'mediaId']
  const token = (parts[1] ?? '').split('-')[0] ?? '';
  if (!linkTokenSchema.safeParse(token).success) return message(req.locale, t.gone, landing);
  const ref = db.doc(`shareLinks/${token}`);
  const link = await ref.get();
  if (!link.exists || link.get('status') === 'revoked') return message(req.locale, t.gone, landing);
  if (
    link.get('status') === 'expired' ||
    (link.get('expiresAt') as Timestamp).toMillis() <= now.getTime()
  ) {
    return message(req.locale, t.expired, landing, 410);
  }

  // Passcode (P-096): 5 wrong tries per 15 minutes per link and address.
  const passHash = link.get('passcodeHash') as string | null;
  const unlocked =
    !passHash || sameSecret(req.cookies[cookieName(token)] ?? '', passCookie(link, token));
  if (!unlocked) {
    const attemptsRef = db.doc(`shareLinks/${token}/attempts/${sha(req.ip).slice(0, 32)}`);
    const attempts = await attemptsRef.get();
    const since = (attempts.get('since') as Timestamp | undefined)?.toMillis() ?? 0;
    const inWindow = now.getTime() - since < passcodeLimits.windowMinutes * 60_000;
    const count = inWindow ? ((attempts.get('count') as number | undefined) ?? 0) : 0;
    const form = (error?: string) =>
      html(
        error === t.passLocked ? 429 : 401,
        shell(
          req.locale,
          t.passTitle,
          `<div class="card"><h1>${escape(t.passTitle)}</h1><p class="meta">${escape(t.passBody)}</p>
<form method="post"><input name="passcode" inputmode="numeric" pattern="[0-9]{4}" maxlength="4" autocomplete="one-time-code" required autofocus>
${error ? `<p class="err">${escape(error)}</p>` : ''}<p><button type="submit">${escape(t.open)}</button></p></form></div>`,
          landing,
        ),
      );
    if (count >= passcodeLimits.attempts) return form(t.passLocked);
    if (req.method !== 'POST') return form();
    const guess = (req.form.passcode ?? '').trim();
    if (
      /^\d{4}$/.test(guess) &&
      sameSecret(sha(`${link.get('salt') as string}:${guess}`), passHash!)
    ) {
      await attemptsRef.delete();
      return {
        status: 303,
        type: 'redirect',
        body: '',
        headers: { Location: `/s/${parts[1]}`, 'Cache-Control': 'no-store' },
        cookies: [{ name: cookieName(token), value: passCookie(link, token), maxAge: 24 * 3600 }],
      };
    }
    await attemptsRef.set({ count: count + 1, since: inWindow ? new Date(since) : now });
    return form(count + 1 >= passcodeLimits.attempts ? t.passLocked : t.passWrong);
  }

  const view = await projection(db, link);
  if (!view) return message(req.locale, t.gone, landing);

  // An image: only from the projection; the original only when downloads are allowed.
  if (parts[2] === 'm') {
    const mediaId = parts[3] ?? '';
    const item = view.visible.find((m) => m.id === mediaId);
    if (!item) return message(req.locale, t.gone, landing);
    const download = parts[4] === 'dl' && link.get('allowDownload') === true;
    const path = (
      download ? item.get('paths.original') : (item.get('paths.display') ?? item.get('paths.thumb'))
    ) as string | null;
    const bytes = path ? await store.read(path) : null;
    if (!bytes) return message(req.locale, t.gone, landing);
    return {
      status: 200,
      type: 'jpeg',
      body: bytes,
      headers: {
        'Cache-Control': 'private, max-age=300',
        'X-Robots-Tag': 'noindex',
        ...(download
          ? { 'Content-Disposition': `attachment; filename="child-life-${mediaId.slice(-8)}.jpg"` }
          : {}),
      },
      cookies: [],
    };
  }

  // The page; a view is counted once per visitor per link.
  const cookies: ShareResponse['cookies'] = [];
  if (!req.cookies[seenName(token)]) {
    await ref.update({ views: FieldValue.increment(1), lastViewAt: now });
    const mirrors = await db
      .collection(`users/${link.get('createdBy') as string}/sharedOut`)
      .where('token', '==', token)
      .get();
    for (const m of mirrors.docs) await m.ref.update({ views: FieldValue.increment(1) });
    const left = Math.max(
      60,
      Math.floor(((link.get('expiresAt') as Timestamp).toMillis() - now.getTime()) / 1000),
    );
    cookies.push({ name: seenName(token), value: '1', maxAge: left });
  }
  const baby = await db.doc(`babies/${view.babyId}`).get();
  const zone = (baby.get('timeZone.zone') as string | undefined) ?? 'Asia/Ho_Chi_Minh';
  const profile = await db.doc(`babies/${view.babyId}/restricted/profile`).get();
  const dob = profile.get('dateOfBirth') as string | undefined;
  const nickname = baby.get('nickname') as string;
  const fmt = (d: Date | string) =>
    new Intl.DateTimeFormat(req.locale === 'vi' ? 'vi-VN' : 'en-GB', {
      day: 'numeric',
      month: 'short',
      ...(typeof d === 'string' ? { year: 'numeric' } : {}),
      timeZone: zone,
    }).format(typeof d === 'string' ? new Date(`${d}T12:00:00Z`) : d);
  const metaBits = [
    nickname,
    dob ? ageLabel(dob, localDateIn(zone, now), req.locale) : null,
    link.get('hideIdentity') === false && dob ? t.born(fmt(dob)) : null,
    t.shared(link.get('sharerName') as string),
  ].filter(Boolean) as string[];
  const base = `/s/${parts[1]}/m`;
  const cover = view.visible.find((m) => m.id === view.story.get('coverMediaId'));
  const allowDownload = link.get('allowDownload') === true;
  const body: string[] = [];
  // Owner request: a tap on any photo shows it full screen (CSS :target, the page runs no script).
  const viewed: { id: string; caption: string }[] = [];
  const openFull = (id: string, caption = '') => {
    if (!viewed.some((v) => v.id === id)) viewed.push({ id, caption });
    return `#v-${escape(id)}`;
  };
  if (cover) {
    body.push(
      `<a class="cover-link" href="${openFull(cover.id)}"><img class="cover" src="${base}/${cover.id}" alt=""></a>`,
    );
  }
  body.push(
    `<div class="pad"><h1>${escape(view.story.get('title') as string)}</h1><div class="meta">${escape(metaBits.join(' · '))}</div>`,
  );
  const shown = new Set<string>();
  for (const b of view.blocks) {
    if (b.type === 'paragraph' && b.text.trim()) body.push(`<p class="p">${escape(b.text)}</p>`);
    if (b.type === 'photos') {
      const items = b.items.filter(
        (i) => view.visible.some((m) => m.id === i.mediaId) && !shown.has(i.mediaId),
      );
      if (!items.length) continue;
      body.push(
        `<div class="grid">${items
          .map((i) => {
            shown.add(i.mediaId);
            return `<div><a href="${openFull(i.mediaId, i.caption ?? '')}"><img src="${base}/${i.mediaId}" alt="${escape(i.caption ?? '')}"></a>${
              allowDownload
                ? `<a class="dl" href="${base}/${i.mediaId}/dl">${escape(t.download)}</a>`
                : ''
            }</div>`;
          })
          .join('')}</div>`,
      );
    }
  }
  // Owner request: the page does not say when the link expires.
  body.push(
    allowDownload
      ? '</div>'
      : `<div class="note">🔒 <span>${escape(t.noDownloadNote)}</span></div></div>`,
  );
  viewed.forEach((v, n) => {
    const prev = viewed[n - 1];
    const next = viewed[n + 1];
    body.push(
      `<div class="lb" id="v-${escape(v.id)}"><a class="bg" href="#_" aria-label="${escape(t.close)}"></a>` +
        `<img src="${base}/${v.id}" alt="${escape(v.caption)}">` +
        `<a class="x" href="#_" aria-label="${escape(t.close)}">×</a>` +
        (prev
          ? `<a class="nav prev" href="#v-${escape(prev.id)}" aria-label="${escape(t.prev)}">‹</a>`
          : '') +
        (next
          ? `<a class="nav next" href="#v-${escape(next.id)}" aria-label="${escape(t.next)}">›</a>`
          : '') +
        (allowDownload
          ? `<a class="lbdl" href="${base}/${v.id}/dl">${escape(t.download)}</a>`
          : '') +
        `</div>`,
    );
  });
  return html(
    200,
    shell(req.locale, view.story.get('title') as string, body.join('\n'), landing),
    cookies,
  );
}
