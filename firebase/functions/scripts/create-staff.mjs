// Creates or updates a staff account for the portal (D-043, P-125): the `staff` claim, roles and a
// display name. Run by the owner / Kỹ thuật with Application Default Credentials:
//
//   node firebase/functions/scripts/create-staff.mjs --project child-life-dev \
//     --email linh@example.com --name "Linh Trần" --roles ops,support
//
// Roles: ops (Vận hành), support (Hỗ trợ), eng (Kỹ thuật), lead (trưởng nhóm). The staff member
// signs in on the portal with an email link (or sets a password through "Quên mật khẩu").
// With FIREBASE_AUTH_EMULATOR_HOST set it writes to the local Auth emulator instead.
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

const arg = (name) => {
  const i = process.argv.indexOf(`--${name}`);
  return i > 0 ? process.argv[i + 1] : undefined;
};
const project = arg('project');
const email = arg('email');
const name = arg('name');
const roles = (arg('roles') ?? '').split(',').filter(Boolean);
const allowed = ['ops', 'support', 'eng', 'lead'];
if (!project || !email || !name || roles.length === 0 || roles.some((r) => !allowed.includes(r))) {
  console.error(
    'Usage: --project <id> --email <email> --name "<name>" --roles ops,support,eng,lead',
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
await auth.setCustomUserClaims(user.uid, { staff: true, roles, name });
console.log(`Staff ${email} (${user.uid}) roles: ${roles.join(', ')}`);
