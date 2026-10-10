import { staffRoles, type StaffRole } from '@child-life/contracts';

/**
 * Staff session rules (A01, D-043): email + password or an email link, the `staff` custom claim
 * set by `scripts/create-staff.mjs`, and sign-out after 30 minutes without activity (R-180).
 */
export const IDLE_MS = 30 * 60 * 1000;

export interface StaffIdentity {
  uid: string;
  email: string | null;
  name: string;
  roles: StaffRole[];
}

/** The staff identity from ID-token claims, or `null` for an account without portal access. */
export function staffFromClaims(
  uid: string,
  email: string | null,
  claims: Record<string, unknown>,
): StaffIdentity | null {
  if (claims.staff !== true || !Array.isArray(claims.roles)) return null;
  const roles = claims.roles.filter((r): r is StaffRole =>
    (staffRoles as readonly unknown[]).includes(r),
  );
  if (!roles.length) return null;
  const name = typeof claims.name === 'string' && claims.name.trim() ? claims.name : (email ?? '');
  return { uid, email, name, roles };
}

export function idleExpired(lastActivity: number | null, now: number): boolean {
  return lastActivity !== null && now - lastActivity >= IDLE_MS;
}

// Activity is shared between tabs through localStorage, so a busy tab keeps the others signed in.
const activityKey = 'childlife.portal.activity';
const linkEmailKey = 'childlife.portal.linkEmail';

function read(key: string): string | null {
  try {
    return globalThis.localStorage?.getItem(key) ?? null;
  } catch {
    return null;
  }
}
function write(key: string, value: string | null): void {
  try {
    if (value === null) globalThis.localStorage?.removeItem(key);
    else globalThis.localStorage?.setItem(key, value);
  } catch {
    // Storage can be unavailable (private mode); the in-memory timer still applies.
  }
}

export function readActivity(): number | null {
  const v = Number(read(activityKey));
  return Number.isFinite(v) && v > 0 ? v : null;
}
export function markActivity(now: number): void {
  write(activityKey, String(now));
}
export function clearActivity(): void {
  write(activityKey, null);
}

/** The address an email link was sent to, so opening it on the same browser needs no retyping. */
export function rememberLinkEmail(email: string | null): void {
  write(linkEmailKey, email);
}
export function linkEmail(): string | null {
  return read(linkEmailKey);
}

/** "Vận hành · Hỗ trợ" order: the matrix order, not the claim order. */
export function sortedRoles(roles: readonly StaffRole[]): StaffRole[] {
  return staffRoles.filter((r) => roles.includes(r));
}
