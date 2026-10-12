// Creates or updates a staff account for the portal (P-134, P-135): a `staffMembers/{uid}` document
// (roles, status) and the matching claims (`staff`, `roles`, `name`). Since v1.0 staff are invited
// from the portal ("Nhân sự & phân quyền"); this script is the break-glass path, mainly for the
// first Owner. Run by the owner / Kỹ sư with Application Default Credentials:
//
//   node firebase/functions/scripts/create-staff.mjs --project child-life-dev \
//     --email owner@example.com --name "Tên" --roles owner
//
// Roles: owner, admin, ops (Vận hành), support (Hỗ trợ), eng (Kỹ sư), analyst (Phân tích),
// expert (Chuyên gia), qa (Kiểm thử: only the QA handbook, P-132). The staff member signs in on
// the portal with an email link (or sets a password through "Quên mật khẩu").
// With FIREBASE_AUTH_EMULATOR_HOST / FIRESTORE_EMULATOR_HOST set it writes to the local emulators.
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

const arg = (name) => {
  const i = process.argv.indexOf(`--${name}`);
  return i > 0 ? process.argv[i + 1] : undefined;
};
const project = arg('project');
const email = arg('email')?.trim().toLowerCase();
const name = arg('name');
const roles = (arg('roles') ?? '').split(',').filter(Boolean);
const allowed = ['owner', 'admin', 'ops', 'support', 'eng', 'analyst', 'expert', 'qa'];
if (!project || !email || !name || roles.length === 0 || roles.some((r) => !allowed.includes(r))) {
  console.error(
    `Usage: --project <id> --email <email> --name "<name>" --roles ${allowed.join(',')}`,
  );
  process.exit(1);
}
if (project.endsWith('-prod') && process.env.CONFIRM_PROD !== 'yes') {
  console.error('Refusing to touch prod without CONFIRM_PROD=yes (owner approval required).');
  process.exit(1);
}
initializeApp({ projectId: project });
const auth = getAuth();
let user;
try {
  user = await auth.getUserByEmail(email);
} catch {
  user = await auth.createUser({ email, displayName: name, emailVerified: true });
}
const now = new Date();
const ref = getFirestore().doc(`staffMembers/${user.uid}`);
const existing = await ref.get();
await ref.set(
  {
    email,
    name,
    roles,
    status: 'active',
    accessUntil: null,
    updatedAt: now,
    ...(existing.exists ? {} : { createdAt: now, lastSeenAt: null, invitedByUid: 'script' }),
  },
  { merge: true },
);
await auth.setCustomUserClaims(user.uid, { staff: true, roles, name });
console.log(`Staff ${email} (${user.uid}) roles: ${roles.join(', ')}`);
