import {
  acquisitionSchema,
  analyticsRequestSchema,
  defaultLimits,
  localDateIn,
} from '@child-life/contracts';
import { FieldValue, Timestamp, type DocumentData, type Firestore } from 'firebase-admin/firestore';
import { AccountError, type AccountCaller } from './account.js';
import { parse, requireStaff, staffAudit, type Staff } from './staff.js';

/**
 * Phân tích (Figma A13 / A14, P-137): first-party and aggregate-only, no analytics SDK.
 *
 * - "Hoạt động" (a family, a Vietnam calendar day) = a member opened the app that day (the device
 *   heartbeat `lastActiveAt`) or wrote a care record, a memory or a story.
 * - `familyActivity/{familyId}` keeps the active days (last 400), the platforms seen and, per ISO
 *   week, which features the family used. The device trigger and the nightly rollup feed it.
 * - `statsDaily/{yyyy-mm-dd}` holds one finished day: DAU / WAU / MAU (all, iOS, Android), D30,
 *   new families by channel and platform, feature counts, storage, app versions and the cohort
 *   table. The portal reads these documents only.
 */

const ZONE = 'Asia/Ho_Chi_Minh';
const DAY_MS = 86_400_000;
const ms = (v: unknown) =>
  v instanceof Timestamp ? v.toMillis() : v instanceof Date ? v.getTime() : 0;

export const features = [
  'feeding',
  'sleep',
  'diaper',
  'pump',
  'growth',
  'vaccines',
  'memories',
  'stories',
  'reminders',
] as const;
export type Feature = (typeof features)[number];
const careFeature: Record<string, Feature> = {
  bottle: 'feeding',
  breast: 'feeding',
  sleep: 'sleep',
  diaper: 'diaper',
  pump: 'pump',
  growth: 'growth',
};

/** Vietnam calendar day of an instant ("2026-10-11"). */
export const dayOf = (at: Date) => localDateIn(ZONE, at);
/** Start of a Vietnam day as an instant. */
const startOf = (day: string) => new Date(`${day}T00:00:00+07:00`);
const addDays = (day: string, n: number) =>
  dayOf(new Date(startOf(day).getTime() + n * DAY_MS + 3_600_000));

/** ISO week of a Vietnam day ("2026-W41"). */
export function isoWeek(day: string): string {
  const d = new Date(`${day}T00:00:00Z`);
  const dow = (d.getUTCDay() + 6) % 7;
  d.setUTCDate(d.getUTCDate() - dow + 3);
  const year = d.getUTCFullYear();
  const jan4 = new Date(Date.UTC(year, 0, 4));
  const week =
    1 +
    Math.round(((d.getTime() - jan4.getTime()) / DAY_MS - 3 + ((jan4.getUTCDay() + 6) % 7)) / 7);
  return `${year}-W${String(week).padStart(2, '0')}`;
}
const mondayOf = (day: string) => {
  const d = new Date(`${day}T00:00:00Z`);
  return addDays(day, -((d.getUTCDay() + 6) % 7));
};

/** Once per account: "website" (Play install referrer from the landing links), "store" or "unknown". */
export async function recordAcquisition(
  db: Firestore,
  caller: AccountCaller,
  data: unknown,
  now: Date,
) {
  const r = acquisitionSchema.safeParse(data);
  if (!r.success) throw new AccountError('invalid-argument', 'malformed');
  const ref = db.doc(`users/${caller.uid}`);
  await db.runTransaction(async (tx) => {
    const user = await tx.get(ref);
    if (user.get('acquisition')) return;
    tx.set(ref, { acquisition: { channel: r.data.channel, at: now } }, { merge: true });
  });
  return {};
}

/** The families a person belongs to (active memberships). */
async function familiesOf(db: Firestore, uid: string): Promise<string[]> {
  const ms_ = await db
    .collectionGroup('members')
    .where('uid', '==', uid)
    .where('status', '==', 'active')
    .select('babyId')
    .get();
  const babyIds = [...new Set(ms_.docs.map((m) => m.get('babyId') as string))];
  if (!babyIds.length) return [];
  const babies = await db.getAll(...babyIds.map((b) => db.doc(`babies/${b}`)));
  return [...new Set(babies.map((b) => b.get('familyId') as string).filter(Boolean))];
}

/** Device trigger: a new heartbeat day marks every family of that person active on that day. */
export async function markDeviceActivity(
  db: Firestore,
  uid: string,
  before: DocumentData | undefined,
  after: DocumentData | undefined,
) {
  const at = ms(after?.lastActiveAt);
  if (!at || at === ms(before?.lastActiveAt)) return 0;
  const day = dayOf(new Date(at));
  const platform = after?.platform as string | undefined;
  const families = await familiesOf(db, uid);
  for (const f of families) {
    await db.doc(`familyActivity/${f}`).set(
      {
        days: { [day]: true },
        ...(platform === 'ios' || platform === 'android'
          ? { platforms: FieldValue.arrayUnion(platform) }
          : {}),
      },
      { merge: true },
    );
  }
  return families.length;
}

interface FamilyFacts {
  id: string;
  createdAt: number;
  ownerUid: string;
  usedBytes: number;
  quotaBytes: number;
  photoBytes: number;
  videoBytes: number;
}

/** Families with the facts the rollup needs (one read per family). */
async function familyFacts(db: Firestore) {
  const snap = await db
    .collection('families')
    .select('createdAt', 'ownerUid', 'usedBytes', 'quotaBytes', 'usage')
    .get();
  return snap.docs.map((d): FamilyFacts => {
    const usage =
      (d.get('usage') as Record<string, { photoBytes?: number; videoBytes?: number }>) ?? {};
    return {
      id: d.id,
      createdAt: ms(d.get('createdAt')),
      ownerUid: d.get('ownerUid') as string,
      usedBytes: (d.get('usedBytes') as number) ?? 0,
      quotaBytes: (d.get('quotaBytes') as number) ?? defaultLimits.familyQuotaBytes,
      photoBytes: Object.values(usage).reduce((n, u) => n + (u.photoBytes ?? 0), 0),
      videoBytes: Object.values(usage).reduce((n, u) => n + (u.videoBytes ?? 0), 0),
    };
  });
}

/** Writes made on one day, by family: which features and how many uses. */
async function dayWrites(db: Firestore, day: string) {
  const from = startOf(day);
  const to = new Date(from.getTime() + DAY_MS);
  const counts = Object.fromEntries(features.map((f) => [f, 0])) as Record<Feature, number>;
  const byBaby = new Map<string, Set<Feature>>();
  const add = (babyId: string | undefined, f: Feature) => {
    counts[f]++;
    if (!babyId) return;
    if (!byBaby.has(babyId)) byBaby.set(babyId, new Set());
    byBaby.get(babyId)!.add(f);
  };
  const babyOf = (d: FirebaseFirestore.QueryDocumentSnapshot) =>
    (d.get('babyId') as string | undefined) ?? d.ref.parent.parent?.id;
  const range = (group: string, fields: string[]) =>
    db
      .collectionGroup(group)
      .where('createdAt', '>=', from)
      .where('createdAt', '<', to)
      .select(...fields)
      .get();
  const [records, media, stories, vaccines, rules, reminders] = await Promise.all([
    range('records', ['babyId', 'type']),
    range('media', ['babyId']),
    range('stories', ['babyId']),
    range('vaccines', ['babyId']),
    range('reminderRules', ['babyId']),
    range('reminders', ['babyId']),
  ]);
  for (const r of records.docs) {
    const f = careFeature[r.get('type') as string];
    if (f) add(babyOf(r), f);
  }
  for (const d of media.docs) add(babyOf(d), 'memories');
  for (const d of stories.docs) add(babyOf(d), 'stories');
  for (const d of vaccines.docs) add(babyOf(d), 'vaccines');
  for (const d of [...rules.docs, ...reminders.docs]) add(babyOf(d), 'reminders');
  const babyIds = [...byBaby.keys()];
  const babies = babyIds.length
    ? await db.getAll(...babyIds.map((b) => db.doc(`babies/${b}`)))
    : [];
  const byFamily = new Map<string, Set<Feature>>();
  for (const b of babies) {
    const f = b.get('familyId') as string | undefined;
    if (!f) continue;
    const set = byFamily.get(f) ?? new Set<Feature>();
    for (const x of byBaby.get(b.id)!) set.add(x);
    byFamily.set(f, set);
  }
  return { counts, byFamily };
}

type PlatformSplit = { all: number; ios: number; android: number };
const split = (): PlatformSplit => ({ all: 0, ios: 0, android: 0 });

/**
 * Nightly (00:30 Vietnam) for the day that just ended, or any past day (backfill): marks write
 * activity, then computes the day's document from `familyActivity`, `families` and devices.
 */
export async function rollupDay(db: Firestore, day: string, now: Date) {
  const writes = await dayWrites(db, day);
  const week = isoWeek(day);
  for (const [f, used] of writes.byFamily) {
    await db
      .doc(`familyActivity/${f}`)
      .set(
        { days: { [day]: true }, weeks: { [week]: FieldValue.arrayUnion(...used) } },
        { merge: true },
      );
  }

  const [families, activity] = await Promise.all([
    familyFacts(db),
    db.collection('familyActivity').get(),
  ]);
  const act = new Map(activity.docs.map((d) => [d.id, d.data()]));
  const active = (id: string, from: string, to: string) => {
    const days = (act.get(id)?.days ?? {}) as Record<string, boolean>;
    return Object.keys(days).some((d) => d >= from && d <= to);
  };
  const platformsOf = (id: string) => (act.get(id)?.platforms as string[] | undefined) ?? [];
  const tally = (from: string) => {
    const t = split();
    for (const f of families) {
      if (!active(f.id, from, day)) continue;
      t.all++;
      const p = platformsOf(f.id);
      if (p.includes('ios')) t.ios++;
      if (p.includes('android')) t.android++;
    }
    return t;
  };
  const dau = tally(day);
  const wau = tally(addDays(day, -6));
  const mau = tally(addDays(day, -29));

  // D30: families created 27–33 days before `day`, active on days 28–32 after creation.
  const cohort30 = families.filter((f) => {
    const age = Math.round(
      (startOf(day).getTime() - startOf(dayOf(new Date(f.createdAt))).getTime()) / DAY_MS,
    );
    return f.createdAt && age >= 30 && age <= 36;
  });
  const kept30 = cohort30.filter((f) => {
    const created = dayOf(new Date(f.createdAt));
    return active(f.id, addDays(created, 28), addDays(created, 32));
  });

  // New families of the day: channel from how the owner arrived, platform from their devices.
  const born = families.filter((f) => f.createdAt && dayOf(new Date(f.createdAt)) === day);
  const newFamilies = { ...split(), invite: 0, website: 0, store: 0 };
  for (const f of born) {
    newFamilies.all++;
    const [user, joined] = await Promise.all([
      db.doc(`users/${f.ownerUid}`).get(),
      db
        .collectionGroup('members')
        .where('uid', '==', f.ownerUid)
        .where('status', '==', 'active')
        .select('isOwner', 'joinedAt', 'createdAt', 'inviteId')
        .get(),
    ]);
    const invited = joined.docs.some((m) => m.get('isOwner') !== true && m.get('inviteId'));
    const channel = invited
      ? 'invite'
      : (user.get('acquisition.channel') as string) === 'website'
        ? 'website'
        : 'store';
    newFamilies[channel]++;
    const devices = await db.collection(`users/${f.ownerUid}/devices`).select('platform').get();
    const p = new Set(devices.docs.map((d) => d.get('platform') as string));
    if (p.has('ios')) newFamilies.ios++;
    if (p.has('android')) newFamilies.android++;
  }

  // Feature use: this ISO week's families per feature (of the week's active families).
  const weekFamilies = Object.fromEntries(features.map((f) => [f, split()])) as Record<
    Feature,
    PlatformSplit
  >;
  for (const f of families) {
    const used = ((act.get(f.id)?.weeks ?? {}) as Record<string, string[]>)[week] ?? [];
    const p = platformsOf(f.id);
    for (const x of used as Feature[]) {
      if (!weekFamilies[x]) continue;
      weekFamilies[x].all++;
      if (p.includes('ios')) weekFamilies[x].ios++;
      if (p.includes('android')) weekFamilies[x].android++;
    }
  }
  const weekActive = tally(mondayOf(day));
  const relatives = await db
    .collectionGroup('members')
    .where('role', '==', 'relative')
    .where('status', '==', 'active')
    .select('babyId')
    .get();
  const relativeBabies = [...new Set(relatives.docs.map((m) => m.get('babyId') as string))];
  const relativeFamilies = new Set(
    (relativeBabies.length
      ? await db.getAll(...relativeBabies.map((b) => db.doc(`babies/${b}`)))
      : []
    )
      .map((b) => b.get('familyId') as string)
      .filter(Boolean),
  );

  // Storage from one source (`families.usedBytes` and the per-baby usage by type).
  const used = families.reduce((n, f) => n + f.usedBytes, 0);
  const photo = families.reduce((n, f) => n + f.photoBytes, 0);
  const video = families.reduce((n, f) => n + f.videoBytes, 0);
  const storage = {
    usedBytes: used,
    photoBytes: photo,
    videoBytes: video,
    otherBytes: Math.max(0, used - photo - video),
    baseFamilies: families.filter((f) => f.quotaBytes <= defaultLimits.familyQuotaBytes).length,
    expandedFamilies: families.filter((f) => f.quotaBytes > defaultLimits.familyQuotaBytes).length,
    over80Families: families.filter((f) => f.quotaBytes > 0 && f.usedBytes / f.quotaBytes >= 0.8)
      .length,
  };

  // App versions of devices active in the last 30 days (devices, not families).
  const devices = await db
    .collectionGroup('devices')
    .where('lastActiveAt', '>=', startOf(addDays(day, -29)))
    .select('platform', 'appVersion', 'signedOutAt')
    .get();
  const versions = new Map<string, number>();
  for (const d of devices.docs) {
    if (d.get('signedOutAt')) continue;
    const key = `${d.get('platform')}|${d.get('appVersion') ?? '?'}`;
    versions.set(key, (versions.get(key) ?? 0) + 1);
  }

  // Retention by sign-up week: the last 8 ISO weeks, T0…T7 = active in week n after the cohort week.
  const thisMonday = mondayOf(day);
  const cohorts = Array.from({ length: 8 }, (_, i) => {
    const monday = addDays(thisMonday, -7 * (7 - i));
    const sunday = addDays(monday, 6);
    const members = families.filter((f) => {
      const c = f.createdAt ? dayOf(new Date(f.createdAt)) : '';
      return c >= monday && c <= sunday;
    });
    const weeks = Math.floor(
      (startOf(thisMonday).getTime() - startOf(monday).getTime()) / (7 * DAY_MS),
    );
    const retention = Array.from({ length: weeks + 1 }, (_, n) => {
      if (!members.length) return null;
      const from = addDays(monday, 7 * n);
      const to = addDays(from, 6) > day ? day : addDays(from, 6);
      return members.filter((f) => active(f.id, from, to)).length / members.length;
    });
    return { week: isoWeek(monday), families: members.length, retention };
  });

  const doc = {
    date: day,
    dau,
    wau,
    mau,
    d30: cohort30.length ? kept30.length / cohort30.length : null,
    totalFamilies: families.length,
    newFamilies,
    features: writes.counts,
    weekFamilies,
    weekActive,
    relativeFamilies: relativeFamilies.size,
    storage,
    versions: [...versions.entries()]
      .map(([k, n]) => ({ platform: k.split('|')[0]!, version: k.split('|')[1]!, devices: n }))
      .sort((a, b) => b.devices - a.devices),
    cohorts,
    computedAt: now,
  };
  await db.doc(`statsDaily/${day}`).set(doc);
  return doc;
}

/** The day that just ended in Vietnam (the nightly job's target). */
export const yesterday = (now: Date) => dayOf(new Date(now.getTime() - DAY_MS));

/** Rebuilds missing days (deploy-time backfill), oldest first. */
export async function backfillDays(db: Firestore, now: Date, count: number) {
  const done: string[] = [];
  for (let i = count; i >= 1; i--) {
    const day = dayOf(new Date(now.getTime() - i * DAY_MS));
    if ((await db.doc(`statsDaily/${day}`).get()).exists) continue;
    await rollupDay(db, day, now);
    done.push(day);
  }
  return done;
}

type Stats = Awaited<ReturnType<typeof rollupDay>>;

const pick = (s: PlatformSplit, platform: 'all' | 'ios' | 'android') => s[platform];
const avg = (xs: number[]) => (xs.length ? xs.reduce((a, b) => a + b, 0) / xs.length : 0);
const change = (cur: number, prev: number) => (prev ? (cur - prev) / prev : null);

/** `staffAnalytics`: A13 (growth) or A14 (features) for a range, from `statsDaily` only. */
export async function analytics(db: Firestore, staff: Staff | null, data: unknown, now: Date) {
  requireStaff(staff, 'analytics.view');
  const req = parse(analyticsRequestSchema, data);
  const last = yesterday(now);
  const from = addDays(last, -(2 * req.days - 1));
  const snap = await db
    .collection('statsDaily')
    .where('date', '>=', from)
    .where('date', '<=', last)
    .orderBy('date')
    .get();
  const all = snap.docs.map((d) => d.data() as Stats);
  const split0 = addDays(last, -(req.days - 1));
  const cur = all.filter((s) => s.date >= split0);
  const prev = all.filter((s) => s.date < split0);
  const latest = cur[cur.length - 1] ?? null;
  const prevLatest = prev[prev.length - 1] ?? null;
  const p = req.platform;
  const base = {
    range: { from: split0, to: last },
    days: cur.length,
    computedAt: latest ? latest.computedAt : null,
  };
  if (!latest) return { ...base, empty: true as const };

  if (req.tab === 'growth') {
    const sum = (xs: Stats[], k: 'invite' | 'website' | 'store') =>
      xs.reduce((n, s) => n + s.newFamilies[k], 0);
    const newCount = (xs: Stats[], pf: 'all' | 'ios' | 'android') =>
      xs.reduce((n, s) => n + s.newFamilies[pf], 0);
    const stick = (s: Stats | null) =>
      s && pick(s.mau, p) ? pick(s.dau, p) / pick(s.mau, p) : null;
    return {
      ...base,
      empty: false as const,
      kpis: {
        dau: {
          value: pick(latest.dau, p),
          change: prevLatest ? change(pick(latest.dau, p), pick(prevLatest.dau, p)) : null,
        },
        wau: {
          value: pick(latest.wau, p),
          change: prevLatest ? change(pick(latest.wau, p), pick(prevLatest.wau, p)) : null,
        },
        mau: {
          value: pick(latest.mau, p),
          change: prevLatest ? change(pick(latest.mau, p), pick(prevLatest.mau, p)) : null,
        },
        stickiness: {
          value: stick(latest),
          points:
            prevLatest && stick(prevLatest) !== null && stick(latest) !== null
              ? stick(latest)! - stick(prevLatest)!
              : null,
        },
        d30: {
          value: latest.d30,
          points:
            prevLatest?.d30 != null && latest.d30 != null ? latest.d30 - prevLatest.d30 : null,
        },
      },
      series: cur.map((s) => ({
        date: s.date,
        dau: pick(s.dau, p),
        wau: pick(s.wau, p),
        mau: pick(s.mau, p),
      })),
      channels: {
        invite: sum(cur, 'invite'),
        website: sum(cur, 'website'),
        store: sum(cur, 'store'),
      },
      platforms: { ios: newCount(cur, 'ios'), android: newCount(cur, 'android') },
      newFamilies: newCount(cur, 'all'),
      cohorts: latest.cohorts,
      totalFamilies: latest.totalFamilies,
    };
  }

  const perDay = (xs: Stats[], f: (typeof features)[number]) => avg(xs.map((s) => s.features[f]));
  const careKeys = ['feeding', 'sleep', 'diaper', 'pump'] as const;
  const care = (xs: Stats[]) => avg(xs.map((s) => careKeys.reduce((n, k) => n + s.features[k], 0)));
  const weekActive = pick(latest.weekActive, p);
  return {
    ...base,
    empty: false as const,
    kpis: {
      carePerDay: { value: care(cur), change: prev.length ? change(care(cur), care(prev)) : null },
      memoriesPerWeek: {
        value: perDay(cur, 'memories') * 7,
        change: prev.length ? change(perDay(cur, 'memories'), perDay(prev, 'memories')) : null,
      },
      storiesPerWeek: {
        value: perDay(cur, 'stories') * 7,
        change: prev.length ? change(perDay(cur, 'stories'), perDay(prev, 'stories')) : null,
      },
      relativesShare: {
        value: latest.totalFamilies ? latest.relativeFamilies / latest.totalFamilies : null,
        points:
          prevLatest && prevLatest.totalFamilies && latest.totalFamilies
            ? latest.relativeFamilies / latest.totalFamilies -
              prevLatest.relativeFamilies / prevLatest.totalFamilies
            : null,
      },
    },
    features: features.map((f) => ({
      feature: f,
      share: weekActive ? pick(latest.weekFamilies[f], p) / weekActive : null,
      perDay: perDay(cur, f),
      change: prev.length ? change(perDay(cur, f), perDay(prev, f)) : null,
    })),
    storage: latest.storage,
    versions: latest.versions.filter((v) => p === 'all' || v.platform === p),
  };
}

/** "Xuất CSV" (A13 / A14): the aggregates on screen; needs "Phân tích · xuất CSV", logged. */
export async function exportAnalytics(
  db: Firestore,
  staff: Staff | null,
  data: unknown,
  now: Date,
) {
  const s = requireStaff(staff, 'analytics.export');
  const req = parse(analyticsRequestSchema, data);
  const result = await analytics(db, staff, data, now);
  const batch = db.batch();
  staffAudit(
    batch,
    db,
    s,
    {
      action: 'analytics.export',
      category: 'analytics',
      target: `${req.tab}:${req.days}d:${req.platform}`,
      reason: null,
    },
    now,
  );
  await batch.commit();
  return result;
}
