// Seeds the LOCAL emulators for trying the staff portal (S15) end to end:
//
//   firebase emulators:start --only auth,firestore,functions --project child-life-dev
//   node firebase/functions/scripts/seed-portal-emulators.mjs
//   pnpm --filter child-life-portal exec vite --mode dev   (with VITE_CL_EMULATORS=true)
//
// It creates a family through the real callables (a help ticket, a storage request), a failed
// account deletion, and three staff accounts that exist only in the Auth emulator:
//   staff.ops@example.com (ops + support), staff.eng@example.com (eng),
//   staff.lead@example.com (lead) — password below, emulator only.
// Refuses to run unless the emulator hosts are local.
/* global fetch */
import { randomUUID } from 'node:crypto';
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

const project = 'child-life-dev';
const host = process.env.EMULATOR_HOST ?? '127.0.0.1';
process.env.FIREBASE_AUTH_EMULATOR_HOST ??= `${host}:9099`;
process.env.FIRESTORE_EMULATOR_HOST ??= `${host}:8080`;
for (const v of [process.env.FIREBASE_AUTH_EMULATOR_HOST, process.env.FIRESTORE_EMULATOR_HOST]) {
  if (!/^(127\.0\.0\.1|localhost):\d+$/.test(v)) {
    console.error(`Refusing: ${v} is not a local emulator.`);
    process.exit(1);
  }
}
const PASSWORD = 'portal-e2e-only';
const authUrl = `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1`;
const fnUrl = (name) => `http://${host}:5001/${project}/asia-southeast1/${name}`;

async function signUp(email) {
  const res = await fetch(`${authUrl}/accounts:signUp?key=emulator`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ email, password: PASSWORD, returnSecureToken: true }),
  });
  const body = await res.json();
  if (!res.ok) throw new Error(`signUp ${email}: ${JSON.stringify(body.error)}`);
  return body;
}
async function signIn(email) {
  const res = await fetch(`${authUrl}/accounts:signInWithPassword?key=emulator`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ email, password: PASSWORD, returnSecureToken: true }),
  });
  const body = await res.json();
  if (!res.ok) throw new Error(`signIn ${email}: ${JSON.stringify(body.error)}`);
  return body;
}
async function call(name, idToken, data) {
  const res = await fetch(fnUrl(name), {
    method: 'POST',
    headers: { 'content-type': 'application/json', authorization: `Bearer ${idToken}` },
    body: JSON.stringify({ data }),
  });
  const body = await res.json();
  if (!res.ok) throw new Error(`${name}: ${JSON.stringify(body.error)}`);
  return body.result;
}

initializeApp({ projectId: project });
const auth = getAuth();
const db = getFirestore();

// A parent with a baby, a help ticket with diagnostics, and a storage request.
const created = await signUp('mai.portal@example.com');
await auth.updateUser(created.localId, { emailVerified: true });
const mom = await signIn('mai.portal@example.com');
const { babyId } = await call('createBabyProfile', mom.idToken, {
  requestId: randomUUID(),
  nickname: 'Na',
  dateOfBirth: '2026-08-01',
  gender: 'girl',
  timeZone: { mode: 'auto', zone: 'Asia/Ho_Chi_Minh' },
  avatarPreset: 1,
  trackers: ['bottle', 'breast', 'sleep', 'diaper'],
  self: { displayName: 'Nguyễn Mai', relation: 'mother' },
});
const familyId = (await db.doc(`babies/${babyId}`).get()).get('familyId');
const GB = 1024 ** 3;
await db.doc(`families/${familyId}`).update({
  usedBytes: Math.round(9.6 * GB),
  usage: { [babyId]: { photoBytes: Math.round(5.1 * GB), videoBytes: Math.round(4.2 * GB) } },
});
await call('createHelpTicket', mom.idToken, {
  requestId: randomUUID(),
  category: 'memories',
  message: 'Không tải được video lên album\nMình chọn video 2 phút mà app cứ báo "chưa tải được".',
  diagnostics: {
    platform: 'ios',
    appVersion: '1.0.3',
    osVersion: '18.1',
    deviceModel: 'iPhone 13',
    role: 'owner',
    pendingUploads: 1,
    lastSyncAt: new Date().toISOString(),
  },
  locale: 'vi',
});
await call('requestMoreStorage', mom.idToken, {
  requestId: randomUUID(),
  babyId,
  amountGb: 10,
  message: 'Con thứ hai sắp sinh, cả nhà quay video nhiều.',
});

// A member whose account deletion stopped at the auth step.
const member = await signUp('member.portal@example.com');
const now = new Date();
// Written as done first so the create trigger skips it, then marked failed.
const failedJob = db.doc('deletionJobs/acct_portal_seed_failed');
await failedJob.set({ state: 'done' });
await failedJob.set({
  kind: 'account',
  uid: member.localId,
  requestedBy: member.localId,
  email: 'member.portal@example.com',
  locale: 'vi',
  steps: ['memberships', 'authored', 'personal', 'auth', 'finish'],
  step: 3,
  state: 'failed',
  failedStep: 'auth',
  attempts: 3,
  createdAt: new Date(now.getTime() - 2 * 3_600_000),
  updatedAt: now,
});

// Staff (claims as `create-staff.mjs` sets them).
for (const [email, name, roles] of [
  ['staff.ops@example.com', 'Linh Trần', ['ops', 'support']],
  ['staff.eng@example.com', 'Minh Phạm', ['eng']],
  ['staff.lead@example.com', 'An Lê', ['lead']],
]) {
  const { localId } = await signUp(email);
  await auth.setCustomUserClaims(localId, { staff: true, roles, name });
}
console.log('Seeded: 1 family, 1 help ticket, 1 storage request, 1 failed deletion, 3 staff.');
