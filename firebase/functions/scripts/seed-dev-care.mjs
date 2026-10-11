// Test data for a dev account: realistic care logs, growth and the vaccination book for the babies
// the account cares for as Cùng nuôi, shaped by each baby's age (from the private profile, read here
// and never printed). Dev only; run by the owner with Application Default Credentials:
//
//   GOOGLE_CLOUD_QUOTA_PROJECT=child-life-dev node firebase/functions/scripts/seed-dev-care.mjs \
//     --project child-life-dev --email you@example.com [--days 45] [--write] [--clean]
//
// Without --write it only counts what it would add. Days that already have real logs are left
// alone, and so are doses already in the book. Seeded documents carry `seeded: true`; --clean
// removes them (records and vaccine doses) and nothing else. Output names no child data.
import { createHash, randomBytes } from 'node:crypto';
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';
import { whoReferenceRows } from '../../../packages/contracts/dist/who-reference.g.js';
import { plannedDate, scheduleFor } from '../../../packages/contracts/dist/vaccines.js';

const arg = (name) => {
  const i = process.argv.indexOf(`--${name}`);
  return i > 0 ? process.argv[i + 1] : undefined;
};
const flag = (name) => process.argv.includes(`--${name}`);
const project = arg('project');
const email = arg('email')?.trim().toLowerCase();
const days = Math.min(Math.max(Number(arg('days') ?? 45), 1), 400);
const write = flag('write');
const clean = flag('clean');
if (!project || !email) {
  console.error('Usage: --project child-life-dev --email <email> [--days 45] [--write] [--clean]');
  process.exit(1);
}
if (!project.endsWith('-dev')) {
  console.error('Test data goes to dev projects only.');
  process.exit(1);
}

initializeApp({ projectId: project });
const db = getFirestore();
const user = await getAuth().getUserByEmail(email);
const memberships = await db
  .collectionGroup('members')
  .where('uid', '==', user.uid)
  .where('status', '==', 'active')
  .get();
const parents = memberships.docs.filter((m) => m.get('role') === 'coParent');
console.log(`${parents.length} baby profile(s) as Cùng nuôi${write || clean ? '' : ' (dry run)'}`);

// ---------- Time in the baby's zone ----------

function offsetMinutes(zone, at) {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone: zone,
    hourCycle: 'h23',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  }).formatToParts(at);
  const get = (t) => Number(parts.find((p) => p.type === t).value);
  const local = Date.UTC(get('year'), get('month') - 1, get('day'), get('hour'), get('minute'));
  return Math.round((local - at.getTime()) / 60_000);
}

/** Local [day] ("2026-10-01") plus [minutes] from its midnight, as an instant. */
function at(zone, day, minutes) {
  const [y, m, d] = day.split('-').map(Number);
  const guess = Date.UTC(y, m - 1, d, 0, minutes);
  return new Date(guess - offsetMinutes(zone, new Date(guess)) * 60_000);
}

function localDay(zone, instant) {
  return new Intl.DateTimeFormat('en-CA', { timeZone: zone }).format(instant);
}

function addDays(day, n) {
  const [y, m, d] = day.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d + n)).toISOString().slice(0, 10);
}

const daysBetween = (a, b) => Math.round((Date.parse(b) - Date.parse(a)) / 864e5);

// ---------- Deterministic randomness per baby ----------

function rng(seed) {
  let h = createHash('sha256').update(seed).digest().readUInt32LE(0) || 1;
  return () => {
    h ^= h << 13;
    h ^= h >>> 17;
    h ^= h << 5;
    return (h >>> 0) / 4294967296;
  };
}

// ---------- Age-shaped rhythms ----------

const band = (age, rows) => rows.find(([until]) => age < until)[1];
const awakeMin = (age) =>
  band(age, [
    [30, [55, 80]],
    [90, [70, 100]],
    [180, [100, 150]],
    [365, [150, 210]],
    [1e9, [240, 320]],
  ]);
const napMin = (age) =>
  band(age, [
    [90, [40, 120]],
    [180, [45, 100]],
    [365, [60, 110]],
    [1e9, [90, 150]],
  ]);
const bottleMl = (age) =>
  band(age, [
    [7, [40, 70]],
    [28, [60, 110]],
    [90, [90, 150]],
    [180, [120, 180]],
    [365, [150, 220]],
    [1e9, [180, 240]],
  ]);
const nightWakes = (age) =>
  band(age, [
    [60, 3],
    [120, 2],
    [240, 1],
    [1e9, 0],
  ]);
const bedtime = (age) =>
  band(age, [
    [90, 22 * 60],
    [1e9, 20 * 60 + 30],
  ]);

/** WHO median / P3 / P97 at [ageDays] for [sex], a little above the median (z ≈ +0.3). */
function growthAt(kind, sex, ageDays) {
  const rows = whoReferenceRows[kind];
  const pick = (s) => {
    const weeks = rows.filter((r) => r.sex === s && r.unit === 'week');
    const months = rows.filter((r) => r.sex === s && r.unit === 'month');
    const [list, x] = ageDays < 13 * 7 ? [weeks, ageDays / 7] : [months, ageDays / 30.4375];
    const lo = list.filter((r) => r.age <= x).at(-1) ?? list[0];
    const hi = list.find((r) => r.age >= x) ?? list.at(-1);
    const t = hi.age === lo.age ? 0 : (x - lo.age) / (hi.age - lo.age);
    const lerp = (k) => lo[k] + (hi[k] - lo[k]) * t;
    return lerp('median') + (0.3 * (lerp('high') - lerp('median'))) / 1.88;
  };
  return sex === 'girl' || sex === 'boy' ? pick(sex) : (pick('girl') + pick('boy')) / 2;
}

// ---------- One baby ----------

for (const membership of parents) {
  const babyRef = membership.ref.parent.parent;
  const label = `baby ${parents.indexOf(membership) + 1}`;
  if (clean) {
    let removed = 0;
    for (const c of ['records', 'vaccines']) {
      const seeded = await babyRef.collection(c).where('seeded', '==', true).get();
      for (let i = 0; i < seeded.docs.length; i += 400) {
        const batch = db.batch();
        seeded.docs.slice(i, i + 400).forEach((d) => batch.delete(d.ref));
        await batch.commit();
      }
      removed += seeded.size;
    }
    console.log(`${label}: removed ${removed} seeded documents`);
    continue;
  }

  const baby = await babyRef.get();
  if ((baby.get('state') ?? 'active') !== 'active') continue;
  const profile = await babyRef.collection('restricted').doc('profile').get();
  const dob = profile.get('dateOfBirth');
  const sex = profile.get('gender');
  const zone = baby.get('timeZone.zone') ?? 'Asia/Ho_Chi_Minh';
  const trackers = new Set(
    baby.get('trackers') ?? ['bottle', 'breast', 'sleep', 'diaper', 'growth'],
  );
  if (!dob) continue;
  const now = new Date();
  const today = localDay(zone, now);
  const first = [addDays(today, -days + 1), dob].sort().at(-1);

  // Who logs: the parents and caregivers of this baby; pumping is Mum's when there is one.
  const team = (await babyRef.collection('members').where('status', '==', 'active').get()).docs
    .filter((m) => ['coParent', 'caregiver'].includes(m.get('role')))
    .map((m) => ({
      uid: m.id,
      author: {
        name: m.get('displayName'),
        relation: m.get('relation'),
        relationCustom: m.get('relationCustom') ?? null,
      },
    }));
  const mum =
    team.find((t) => t.author.relation === 'mother') ?? team.find((t) => t.uid === user.uid);

  // Real logs win: days that already have any are skipped.
  const existing = await babyRef
    .collection('records')
    .where('occurredAt', '>=', Timestamp.fromDate(at(zone, addDays(first, -1), 0)))
    .get();
  const busy = new Set(
    existing.docs
      .filter((d) => !d.get('seeded'))
      .map((d) => localDay(zone, d.get('occurredAt').toDate())),
  );

  const rand = rng(`${babyRef.id}:${first}`);
  const between = ([a, b]) => Math.round(a + rand() * (b - a));
  const records = [];
  const add = (type, start, end, data, by = team[Math.floor(rand() * team.length)] ?? mum) => {
    if (start > now || (end && end > now)) return;
    if (busy.has(localDay(zone, start)) || (end && busy.has(localDay(zone, end)))) return;
    const id = `r_${randomBytes(16).toString('hex')}`;
    const created = Timestamp.fromDate(end ?? start);
    records.push({
      id,
      babyId: babyRef.id,
      type,
      occurredAt: Timestamp.fromDate(start),
      endedAt: end ? Timestamp.fromDate(end) : null,
      data,
      createdBy: by.uid,
      author: by.author,
      createdAt: created,
      clientCreatedAt: created,
      updatedAt: created,
      updatedBy: by.uid,
      deleted: false,
      deletedAt: null,
      deletedBy: null,
      source: 'app',
      seeded: true,
    });
  };

  const feed = (age, start) => {
    const breastShare = !trackers.has('bottle')
      ? 1
      : !trackers.has('breast')
        ? 0
        : age < 90
          ? 0.6
          : 0.35;
    if (rand() < breastShare) {
      const left = between([6, 15]);
      const right = between([5, 14]);
      const end = new Date(start.getTime() + (left + right) * 60_000);
      add(
        'breast',
        start,
        end,
        {
          side: 'both',
          durationMin: left + right,
          leftMin: left,
          rightMin: right,
          endSide: rand() < 0.5 ? 'left' : 'right',
        },
        mum,
      );
      return end;
    }
    const ml = Math.round(between(bottleMl(age)) / 10) * 10;
    add('bottle', start, null, { amountMl: ml, milk: rand() < 0.55 ? 'breastMilk' : 'formula' });
    return new Date(start.getTime() + 15 * 60_000);
  };

  const diaper = (age, when) => {
    if (!trackers.has('diaper') || rand() > 0.92) return;
    const r = rand();
    add('diaper', when, null, {
      kind: r < 0.6 ? 'wet' : r < (age < 60 ? 0.85 : 0.75) ? 'both' : 'dirty',
    });
  };

  const sleep = (start, end) => {
    if (trackers.has('sleep') && end > start) add('sleep', start, end, {});
  };

  // Walk the days: morning wake → feed / awake / nap cycles → bedtime feed → the night with wakes.
  let wake = at(zone, first, between([6 * 60, 7 * 60]));
  for (let day = first; day <= today; day = addDays(day, 1)) {
    const age = daysBetween(dob, day);
    const bed = at(zone, day, bedtime(age) + between([-30, 30]));
    // Naps end by the bedtime feed, 25 minutes before bed.
    const lastNapEnd = bed.getTime() - 35 * 60_000;
    let t = wake;
    while (t.getTime() < lastNapEnd) {
      diaper(age, new Date(t.getTime() - between([2, 10]) * 60_000));
      feed(age, t);
      const napStart = new Date(t.getTime() + between(awakeMin(age)) * 60_000);
      if (napStart.getTime() >= lastNapEnd - 20 * 60_000) break;
      const napEnd = new Date(
        Math.min(napStart.getTime() + between(napMin(age)) * 60_000, lastNapEnd),
      );
      sleep(napStart, napEnd);
      if (rand() < 0.5) diaper(age, new Date(napEnd.getTime() + 3 * 60_000));
      t = new Date(napEnd.getTime() + between([0, 10]) * 60_000);
    }
    feed(age, new Date(bed.getTime() - 25 * 60_000));
    // The night: sleep with wakes for a feed (and a change for the youngest).
    const morning = at(zone, addDays(day, 1), between([6 * 60, 7 * 60 + 15]));
    const wakes = nightWakes(age);
    const span = morning.getTime() - bed.getTime();
    let from = bed;
    for (let w = 1; w <= wakes; w++) {
      const up = new Date(bed.getTime() + (span * w) / (wakes + 1) + between([-30, 30]) * 60_000);
      sleep(from, up);
      if (age < 60) diaper(age, up);
      const back = feed(age, new Date(up.getTime() + 3 * 60_000));
      from = new Date(back.getTime() + between([5, 15]) * 60_000);
    }
    sleep(from, morning);
    wake = morning;

    // Pumping once or twice a day; growth every week (and at birth).
    if (trackers.has('pump') && mum) {
      for (const hour of rand() < 0.5 ? [10] : [10, 15]) {
        const start = at(zone, day, hour * 60 + between([-40, 40]));
        const minutes = between([12, 20]);
        add(
          'pump',
          start,
          new Date(start.getTime() + minutes * 60_000),
          {
            side: 'both',
            amountMl: Math.round(between([70, 160]) / 10) * 10,
            durationMin: minutes,
          },
          mum,
        );
      }
    }
    if (trackers.has('growth') && (age === 0 || daysBetween(first, day) % 7 === 0)) {
      const weight = growthAt('weight', sex, age) * (1 + (rand() - 0.5) * 0.02);
      const length = growthAt('length', sex, age) + (rand() - 0.5) * 0.6;
      add('growth', at(zone, day, 9 * 60 + between([0, 60])), null, {
        weightKg: Math.round(weight * 100) / 100,
        lengthCm: Math.round(length * 10) / 10,
        measuredOn: day,
      });
    }
  }

  // Sổ tiêm chủng: every dose whose date has passed is given (a few days late at most), at the
  // hospital at birth and mostly at a private clinic after; doses already in the book are kept.
  const planRef = babyRef.collection('vaccinePlan').doc('main');
  const plan = await planRef.get();
  const dtp = plan.get('dtp') ?? '6in1';
  const doses = await babyRef.collection('vaccines').get();
  const have = new Set(doses.docs.map((d) => d.id));
  const vaccines = [];
  for (const def of scheduleFor(dtp)) {
    def.months.forEach((months, i) => {
      const key = `${def.id}_${i + 1}`;
      const planned = plannedDate(dob, months);
      if (have.has(key) || daysBetween(planned, today) < 3) return;
      const given = [addDays(planned, months === 0 ? 0 : between([0, 4])), today].sort()[0];
      const by = team.find((t) => t.uid === user.uid) ?? team[0];
      const place =
        months === 0 ? 'hospital' : def.programme === 'epi' && rand() < 0.5 ? 'station' : 'service';
      vaccines.push([
        key,
        {
          babyId: babyRef.id,
          vaccineId: def.id,
          dose: i + 1,
          status: 'given',
          givenOn: given,
          givenTime: months === 0 ? null : `0${between([8, 9])}:${rand() < 0.5 ? '00' : '30'}`,
          place,
          facility: place === 'service' ? 'Trung tâm tiêm chủng gần nhà' : null,
          reaction: def.id === 'dtp' && rand() < 0.5 ? 'Sốt nhẹ buổi tối, hết sau 1 ngày' : null,
          declineReason: null,
          plannedOn: null,
          photoPath: null,
          createdBy: by.uid,
          author: by.author,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
          updatedBy: by.uid,
          seeded: true,
        },
      ]);
    });
  }

  const count = (type) => records.filter((r) => r.type === type).length;
  console.log(
    `${label}: ${daysBetween(first, today) + 1} days (${busy.size} with real logs skipped) → ` +
      ['bottle', 'breast', 'sleep', 'diaper', 'pump', 'growth']
        .map((t) => `${t} ${count(t)}`)
        .join(', ') +
      `; vaccine doses ${vaccines.length}`,
  );
  if (!write) continue;

  for (let i = 0; i < records.length; i += 400) {
    const batch = db.batch();
    records.slice(i, i + 400).forEach((r) => batch.set(babyRef.collection('records').doc(r.id), r));
    await batch.commit();
  }
  const batch = db.batch();
  vaccines.forEach(([key, d]) => batch.set(babyRef.collection('vaccines').doc(key), d));
  batch.set(
    planRef,
    {
      dtp,
      setupDone: true,
      scheduleFrom: dob,
      remind: plan.get('remind') ?? true,
      recipients: plan.get('recipients') ?? [],
      bookPhotos: plan.get('bookPhotos') ?? [],
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: user.uid,
    },
    { merge: true },
  );
  await batch.commit();
  console.log(`${label}: written`);
}
