import {
  builtinRole,
  levelsForRoles,
  staffRoles,
  type StaffLevels,
  type StaffRole,
} from '@child-life/contracts';

/**
 * Staff session rules (A01, D-043): email + password or an email link and the `staff` custom
 * claim set by `scripts/create-staff.mjs`. The session stays until the member signs out or loses
 * access (D-062: no idle sign-out).
 */

export interface StaffIdentity {
  uid: string;
  email: string | null;
  name: string;
  roles: StaffRole[];
  /** Role display names from `staffMe` (roles made on the portal have their own names). */
  roleNames?: string[];
  /** What this member may open and do (P-134), from `staffMe`; templates until it answers. */
  levels: StaffLevels;
}

/**
 * The staff identity from ID-token claims, or `null` for an account without portal access. The
 * levels are the built-in templates until `staffMe` answers with the stored roles.
 */
export function staffFromClaims(
  uid: string,
  email: string | null,
  claims: Record<string, unknown>,
): StaffIdentity | null {
  if (claims.staff !== true || !Array.isArray(claims.roles)) return null;
  const roles = claims.roles.filter((r): r is StaffRole => typeof r === 'string' && r.length > 0);
  if (!roles.length) return null;
  const name = typeof claims.name === 'string' && claims.name.trim() ? claims.name : (email ?? '');
  return { uid, email, name, roles, levels: levelsForRoles(roles) };
}

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
    // Storage can be unavailable (private mode): the address is typed again.
  }
}

/** The address an email link was sent to, so opening it on the same browser needs no retyping. */
export function rememberLinkEmail(email: string | null): void {
  write(linkEmailKey, email);
}
export function linkEmail(): string | null {
  return read(linkEmailKey);
}

/** "Admin · Vận hành" order: built-in roles in matrix order, then roles made on the portal. */
export function sortedRoles(roles: readonly StaffRole[]): StaffRole[] {
  const ids = roles.map((r) => builtinRole(r) ?? r);
  return [
    ...staffRoles.filter((r) => ids.includes(r)),
    ...ids.filter((r) => !(staffRoles as readonly string[]).includes(r)),
  ];
}
