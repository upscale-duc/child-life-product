import {
  builtinRole,
  capLevels,
  levelAtLeast,
  levelsForRoles,
  staffCan,
  staffFunctions,
  staffLevels,
  type StaffAccess,
  type StaffFunction,
  type StaffLevel,
  type StaffLevels,
} from '@child-life/contracts';
import { useEffect, useId, useMemo, useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl, type IntlShape } from 'react-intl';
import {
  ApiError,
  useApi,
  useLoad,
  type StaffInviteRow,
  type StaffMemberRow,
  type StaffRoleRow,
  type StaffTeam,
} from '../api';
import { routePaths, subPath, useStaff } from '../context';
import { ZONE, ago } from '../format';
import {
  Button,
  Empty,
  errorMessageId,
  Kpi,
  Loaded,
  LockNote,
  Modal,
  Page,
  Panel,
  Pill,
  RowActions,
  Segmented,
  SelectMenu,
  TableScroll,
  useSort,
  type PillTone,
} from '../ui';

/**
 * Nhân sự & phân quyền (Figma A18–A21; P-134, P-135): members, roles as levels per function, and
 * invitations. Any email domain, no 2FA (owner, 2026-10-11; D-043). Owner, Admin and Kiểm thử are
 * locked roles; only "Nhân sự: Toàn quyền" (Owner) hands out Owner and Admin. Every change is in
 * the audit log (P-139); no reason is asked (D-090).
 */

type Tab = 'members' | 'roles' | 'invites';

/** Rows of the A19 matrix, grouped as drawn (plus PHÁT TRIỂN for the QA handbook). */
export const functionGroups: Array<{ group: string; fns: StaffFunction[] }> = [
  { group: 'overview', fns: ['overview', 'analyticsExport'] },
  {
    group: 'ops',
    fns: ['families', 'familyTransfer', 'support', 'storage', 'dataJobs', 'reference'],
  },
  // NỘI DUNG › Sơ cứu (D-058): Xem · Sửa · Duyệt (medical sign-off).
  { group: 'content', fns: ['content'] },
  { group: 'system', fns: ['system', 'features', 'staff', 'audit'] },
  { group: 'develop', fns: ['qa'] },
];

const levelTone: Record<StaffLevel, PillTone> = {
  none: 'muted',
  viewMasked: 'muted',
  view: 'muted',
  edit: 'ok',
  approve: 'wait',
  full: 'info',
};

const statusTone: Record<StaffMemberRow['status'], PillTone> = {
  active: 'ok',
  paused: 'muted',
  expired: 'wait',
  removed: 'muted',
};

const asApiError = (e: unknown) => (e instanceof ApiError ? e : new ApiError('unknown', null));

export function roleName(intl: IntlShape, role: string, rows: StaffRoleRow[]): string {
  const id = builtinRole(role) ?? role;
  return builtinRole(role)
    ? intl.formatMessage({ id: `role.${id}` })
    : (rows.find((r) => r.id === id)?.name ?? role);
}

/** "Sửa: Hỗ trợ, Mở rộng dung lượng" — what a member can act on (A18 "Phạm vi"). */
export function scopeOf(intl: IntlShape, levels: StaffLevels): string {
  const acts = staffFunctions.filter((f) => levelAtLeast(levels[f], 'edit'));
  if (acts.length === staffFunctions.length) return intl.formatMessage({ id: 'staff.scope.all' });
  if (!acts.length) return intl.formatMessage({ id: 'staff.scope.viewOnly' });
  return acts.map((f) => intl.formatMessage({ id: `fn.${f}` })).join(', ');
}

function untilDate(intl: IntlShape, iso: string | null): string {
  return iso
    ? intl.formatDate(iso, { day: '2-digit', month: '2-digit', year: 'numeric', timeZone: ZONE })
    : intl.formatMessage({ id: 'staff.access.unlimited' });
}

export function StaffScreen() {
  const intl = useIntl();
  const staff = useStaff();
  const canManage = staffCan(staff.levels, 'staff.manage');
  const [path, setPath] = useState(() => subPath('staff', window.location.pathname));
  useEffect(() => {
    const onPop = () => setPath(subPath('staff', window.location.pathname));
    window.addEventListener('popstate', onPop);
    return () => window.removeEventListener('popstate', onPop);
  }, []);
  const go = (segments: string[]) => {
    const url = [routePaths.staff, ...segments.map(encodeURIComponent)].join('/');
    window.history.pushState({}, '', url);
    setPath(segments);
  };
  const tab: Tab = path[0] === 'roles' ? 'roles' : path[0] === 'invites' ? 'invites' : 'members';
  const editing = tab === 'roles' ? (path[1] ?? null) : null;
  const [load, reload] = useLoad<StaffTeam>('staffTeam', {}, 'team');
  const [dialog, setDialog] = useState<
    | { kind: 'invite' }
    | { kind: 'member'; member: StaffMemberRow; op: MemberOp }
    | { kind: 'revoke'; invite: StaffInviteRow }
    | { kind: 'newRole' }
    | null
  >(null);

  return (
    <Page
      title={<FormattedMessage id="staff.title" />}
      info={<FormattedMessage id="staff.sub" />}
      actions={
        canManage && (
          <>
            {tab === 'roles' && (
              <Button onClick={() => setDialog({ kind: 'newRole' })}>
                <FormattedMessage id="staff.newRole" />
              </Button>
            )}
            <Button kind="primary" onClick={() => setDialog({ kind: 'invite' })}>
              <FormattedMessage id="staff.invite" />
            </Button>
          </>
        )
      }
    >
      <Loaded load={load} reload={reload}>
        {(team) => (
          <div className="stack">
            <div className="kpis kpis--3">
              <Kpi
                label={<FormattedMessage id="staff.kpi.members" />}
                value={intl.formatNumber(team.kpis.members)}
                foot={
                  <FormattedMessage id="staff.kpi.membersFoot" values={{ n: team.roles.length }} />
                }
              />
              <Kpi
                label={<FormattedMessage id="staff.kpi.sensitive" />}
                value={intl.formatNumber(team.kpis.sensitive)}
                foot={<FormattedMessage id="staff.kpi.sensitiveFoot" />}
              />
              <Kpi
                label={<FormattedMessage id="staff.kpi.invites" />}
                value={intl.formatNumber(team.kpis.invites)}
                foot={<FormattedMessage id="staff.kpi.invitesFoot" />}
                tone="warn"
              />
            </div>
            {editing ? (
              <RoleEditor
                team={team}
                roleId={editing}
                canManage={canManage}
                onBack={() => go(['roles'])}
                onPick={(id) => go(['roles', id])}
                onSaved={reload}
              />
            ) : (
              <Panel className="panel--flush">
                <div className="panel__pad toolbar">
                  <Segmented
                    label={intl.formatMessage({ id: 'staff.title' })}
                    value={tab}
                    onChange={(t) => go(t === 'members' ? [] : [t])}
                    options={[
                      {
                        value: 'members' as Tab,
                        label: (
                          <FormattedMessage
                            id="staff.tab.members"
                            values={{ n: team.members.length }}
                          />
                        ),
                      },
                      {
                        value: 'roles' as Tab,
                        label: (
                          <FormattedMessage
                            id="staff.tab.roles"
                            values={{ n: team.roles.length }}
                          />
                        ),
                      },
                      {
                        value: 'invites' as Tab,
                        label: (
                          <FormattedMessage
                            id="staff.tab.invites"
                            values={{ n: team.invites.length }}
                          />
                        ),
                      },
                    ]}
                  />
                </div>
                {tab === 'members' && (
                  <MemberTable
                    team={team}
                    canManage={canManage}
                    now={new Date()}
                    selfUid={staff.uid}
                    onAction={(member, op) => setDialog({ kind: 'member', member, op })}
                  />
                )}
                {tab === 'roles' && <RoleMatrix team={team} onOpen={(id) => go(['roles', id])} />}
                {tab === 'invites' && (
                  <InviteTable
                    team={team}
                    canManage={canManage}
                    onRevoke={(invite) => setDialog({ kind: 'revoke', invite })}
                  />
                )}
                <div className="panel__pad">
                  <LockNote>
                    <FormattedMessage id="staff.lock" />
                  </LockNote>
                </div>
              </Panel>
            )}
            {dialog?.kind === 'invite' && (
              <InviteDialog team={team} onClose={() => setDialog(null)} onDone={reload} />
            )}
            {dialog?.kind === 'member' && (
              <MemberDialog
                team={team}
                member={dialog.member}
                op={dialog.op}
                onClose={() => setDialog(null)}
                onDone={reload}
              />
            )}
            {dialog?.kind === 'revoke' && (
              <MemberDialog
                team={team}
                invite={dialog.invite}
                op="revokeInvite"
                onClose={() => setDialog(null)}
                onDone={reload}
              />
            )}
            {dialog?.kind === 'newRole' && (
              <NewRoleDialog
                team={team}
                onClose={() => setDialog(null)}
                onCreated={(id) => {
                  reload();
                  go(['roles', id]);
                }}
              />
            )}
          </div>
        )}
      </Loaded>
    </Page>
  );
}

type MemberOp = 'roles' | 'access' | 'pause' | 'resume' | 'remove';

/** What a manager may do to a member: never pause or remove yourself (P-134). */
export function memberActions(m: StaffMemberRow, selfUid: string): MemberOp[] {
  if (m.uid === selfUid) return ['roles', 'access'];
  return ['roles', 'access', m.status === 'active' ? 'pause' : 'resume', 'remove'];
}

export function MemberTable({
  team,
  canManage,
  now,
  selfUid,
  onAction,
}: {
  team: StaffTeam;
  canManage: boolean;
  now: Date;
  selfUid: string;
  onAction: (m: StaffMemberRow, op: MemberOp) => void;
}) {
  const intl = useIntl();
  const [q, setQ] = useState('');
  const [role, setRole] = useState('all');
  const custom = useMemo(
    () => Object.fromEntries(team.roles.map((r) => [r.id, r.levels])),
    [team.roles],
  );
  const text = q.trim().toLowerCase();
  const rows = team.members.filter(
    (m) =>
      (role === 'all' || m.roles.some((r) => (builtinRole(r) ?? r) === role)) &&
      (!text || `${m.name} ${m.email}`.toLowerCase().includes(text)),
  );
  const sort = useSort(rows, {
    member: (m) => m.name,
    access: (m) => m.accessUntil,
    last: (m) => m.lastSeenAt,
    status: (m) => m.status,
  });
  return (
    <>
      <div className="panel__pad toolbar toolbar--start">
        <input
          className="search"
          type="search"
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder={intl.formatMessage({ id: 'staff.search' })}
          aria-label={intl.formatMessage({ id: 'staff.search' })}
        />
        <SelectMenu
          value={role}
          onChange={setRole}
          label={intl.formatMessage({ id: 'staff.col.role' })}
          options={[
            { value: 'all', label: intl.formatMessage({ id: 'staff.filter.allRoles' }) },
            ...team.roles.map((r) => ({ value: r.id, label: roleName(intl, r.id, team.roles) })),
          ]}
        />
      </div>
      {rows.length === 0 ? (
        <Empty>
          <FormattedMessage id="staff.empty" />
        </Empty>
      ) : (
        <TableScroll min={920}>
          <table className="table">
            <thead>
              <tr>
                {sort.th('member', <FormattedMessage id="staff.col.member" />)}
                <th>
                  <FormattedMessage id="staff.col.role" />
                </th>
                <th>
                  <FormattedMessage id="staff.col.scope" />
                </th>
                {sort.th('access', <FormattedMessage id="staff.col.access" />)}
                {sort.th('last', <FormattedMessage id="staff.col.last" />)}
                {sort.th('status', <FormattedMessage id="staff.col.status" />)}
                {canManage && <th />}
              </tr>
            </thead>
            <tbody>
              {sort.rows.map((m) => (
                <tr key={m.uid}>
                  <td>
                    <span className="person">
                      <span className="avatar avatar--sm" aria-hidden="true">
                        {m.name.trim()[0]?.toUpperCase() ?? '?'}
                      </span>
                      <span>
                        <strong>{m.name}</strong>
                        <br />
                        <span className="muted">{m.email}</span>
                      </span>
                    </span>
                  </td>
                  <td>
                    <span className="chips">
                      {m.roles.map((r) => (
                        <Pill key={r} tone={builtinRole(r) === 'owner' ? 'wait' : 'ok'}>
                          {roleName(intl, r, team.roles)}
                        </Pill>
                      ))}
                    </span>
                  </td>
                  <td className="muted cell-scope">
                    {scopeOf(intl, levelsForRoles(m.roles, custom))}
                  </td>
                  <td className="nowrap">{untilDate(intl, m.accessUntil)}</td>
                  <td className="nowrap">{m.lastSeenAt ? ago(intl, m.lastSeenAt, now) : '—'}</td>
                  <td>
                    <Pill tone={statusTone[m.status]}>
                      <FormattedMessage id={`staff.status.${m.status}`} />
                    </Pill>
                  </td>
                  {canManage && (
                    <td className="cell-actions">
                      <RowActions
                        label={intl.formatMessage({ id: 'table.actionsFor' }, { name: m.name })}
                        actions={memberActions(m, selfUid).map((op) => ({
                          key: op,
                          label: <FormattedMessage id={`staff.action.${op}`} />,
                          onSelect: () => onAction(m, op),
                          destructive: op === 'remove',
                        }))}
                      />
                    </td>
                  )}
                </tr>
              ))}
            </tbody>
          </table>
        </TableScroll>
      )}
    </>
  );
}

export function RoleMatrix({ team, onOpen }: { team: StaffTeam; onOpen: (id: string) => void }) {
  const intl = useIntl();
  return (
    <div className="matrix-wrap">
      <ul className="legend legend--levels panel__pad">
        {staffLevels
          .filter((l) => l !== 'none')
          .map((l) => (
            <li key={l}>
              <Pill tone={levelTone[l]}>
                <FormattedMessage id={`level.${l}`} />
              </Pill>
            </li>
          ))}
      </ul>
      <table className="table matrix">
        <thead>
          <tr>
            <th>
              <FormattedMessage id="staff.col.function" />
            </th>
            {team.roles.map((r) => (
              <th key={r.id}>
                <button type="button" className="matrix__role" onClick={() => onOpen(r.id)}>
                  {roleName(intl, r.id, team.roles)}
                  {r.locked && ' 🔒'}
                </button>
                <span className="muted">
                  <FormattedMessage id="staff.roleCount" values={{ n: r.members }} />
                </span>
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {functionGroups.map((g) => (
            <FunctionGroupRows key={g.group} group={g.group} cols={team.roles.length}>
              {g.fns.map((f) => (
                <tr key={f}>
                  <td>
                    <strong>
                      <FormattedMessage id={`fn.${f}`} />
                    </strong>
                    <br />
                    <span className="muted">
                      <FormattedMessage id={`fn.${f}.note`} />
                    </span>
                  </td>
                  {team.roles.map((r) => (
                    <td key={r.id}>
                      {r.levels[f] === 'none' ? (
                        <span className="muted">—</span>
                      ) : (
                        <Pill tone={levelTone[r.levels[f]]}>
                          <FormattedMessage id={`level.${r.levels[f]}`} />
                        </Pill>
                      )}
                    </td>
                  ))}
                </tr>
              ))}
            </FunctionGroupRows>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function FunctionGroupRows({
  group,
  cols,
  children,
}: {
  group: string;
  cols: number;
  children: ReactNode;
}) {
  return (
    <>
      <tr className="matrix__group">
        <td colSpan={cols + 1}>
          <FormattedMessage id={`staff.group.${group}`} />
        </td>
      </tr>
      {children}
    </>
  );
}

export function InviteTable({
  team,
  canManage,
  onRevoke,
}: {
  team: StaffTeam;
  canManage: boolean;
  onRevoke: (i: StaffInviteRow) => void;
}) {
  const intl = useIntl();
  if (!team.invites.length) {
    return (
      <Empty>
        <FormattedMessage id="staff.invites.empty" />
      </Empty>
    );
  }
  return (
    <TableScroll min={640}>
      <table className="table">
        <thead>
          <tr>
            <th>
              <FormattedMessage id="staff.col.member" />
            </th>
            <th>
              <FormattedMessage id="staff.col.role" />
            </th>
            <th>
              <FormattedMessage id="staff.col.invitedBy" />
            </th>
            <th>
              <FormattedMessage id="staff.col.expires" />
            </th>
            {canManage && <th />}
          </tr>
        </thead>
        <tbody>
          {team.invites.map((i) => (
            <tr key={i.id}>
              <td>
                <strong>{i.name}</strong>
                <br />
                <span className="muted">{i.email}</span>
              </td>
              <td>{i.roles.map((r) => roleName(intl, r, team.roles)).join(' · ')}</td>
              <td>{i.invitedBy}</td>
              <td className="nowrap">{untilDate(intl, i.expiresAt)}</td>
              {canManage && (
                <td className="cell-actions">
                  <Button kind="ghost" onClick={() => onRevoke(i)}>
                    <FormattedMessage id="staff.action.revoke" />
                  </Button>
                </td>
              )}
            </tr>
          ))}
        </tbody>
      </table>
    </TableScroll>
  );
}

/** Roles the editor may hand out: Owner and Admin only with "Nhân sự: Toàn quyền". */
function grantable(team: StaffTeam, levels: StaffLevels) {
  const owners = staffCan(levels, 'staff.owners');
  return team.roles.filter((r) => owners || !['owner', 'admin'].includes(r.id));
}

function AccessField({
  value,
  onChange,
}: {
  value: StaffAccess;
  onChange: (a: StaffAccess) => void;
}) {
  const intl = useIntl();
  const dateId = useId();
  return (
    <div className="field">
      <span className="field__label">
        <FormattedMessage id="staff.access.label" />
      </span>
      <Segmented
        label={intl.formatMessage({ id: 'staff.access.label' })}
        value={value.kind}
        onChange={(k) =>
          onChange(
            k === 'unlimited'
              ? { kind: 'unlimited' }
              : k === 'days'
                ? { kind: 'days', days: 30 }
                : { kind: 'until', until: '' },
          )
        }
        options={(['unlimited', 'days', 'until'] as const).map((k) => ({
          value: k,
          label: <FormattedMessage id={`staff.access.${k}`} />,
        }))}
      />
      {value.kind === 'until' && (
        <input
          id={dateId}
          type="date"
          className="field__input"
          value={value.until}
          onChange={(e) => onChange({ kind: 'until', until: e.target.value })}
          aria-label={intl.formatMessage({ id: 'staff.access.until' })}
        />
      )}
    </div>
  );
}

const accessOk = (a: StaffAccess) => a.kind !== 'until' || /^\d{4}-\d{2}-\d{2}$/.test(a.until);

function RolePicker({
  team,
  value,
  onChange,
  multiple,
}: {
  team: StaffTeam;
  value: string[];
  onChange: (v: string[]) => void;
  multiple: boolean;
}) {
  const intl = useIntl();
  const staff = useStaff();
  return (
    <div
      className="role-grid"
      role="group"
      aria-label={intl.formatMessage({ id: 'staff.col.role' })}
    >
      {grantable(team, staff.levels).map((r) => {
        const on = value.includes(r.id);
        return (
          <button
            key={r.id}
            type="button"
            className={`role-card ${on ? 'role-card--on' : ''}`}
            aria-pressed={on}
            onClick={() =>
              onChange(
                multiple ? (on ? value.filter((x) => x !== r.id) : [...value, r.id]) : [r.id],
              )
            }
          >
            <strong>{roleName(intl, r.id, team.roles)}</strong>
            <span className="muted">{scopeOf(intl, r.levels)}</span>
          </button>
        );
      })}
    </div>
  );
}

function useSubmit(onDone: () => void, onClose: () => void) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const run = async (call: () => Promise<unknown>) => {
    setBusy(true);
    setError(null);
    try {
      await call();
      onDone();
      onClose();
    } catch (e) {
      setError(asApiError(e));
    } finally {
      setBusy(false);
    }
  };
  return { busy, error, run };
}

function ErrorLine({ error }: { error: ApiError | null }) {
  return error ? (
    <p className="error" role="alert">
      <FormattedMessage id={errorMessageId(error)} />
    </p>
  ) : null;
}

/** A20 "Mời thành viên". */
export function InviteDialog({
  team,
  onClose,
  onDone,
}: {
  team: StaffTeam;
  onClose: () => void;
  onDone: () => void;
}) {
  const api = useApi();
  const emailId = useId();
  const nameId = useId();
  const [email, setEmail] = useState('');
  const [name, setName] = useState('');
  const [roles, setRoles] = useState<string[]>(['support']);
  const [access, setAccess] = useState<StaffAccess>({ kind: 'unlimited' });
  const { busy, error, run } = useSubmit(onDone, onClose);
  const valid =
    /^\S+@\S+\.\S+$/.test(email.trim()) &&
    name.trim().length > 0 &&
    roles.length > 0 &&
    accessOk(access);
  return (
    <Modal wide title={<FormattedMessage id="staff.inviteTitle" />} onClose={onClose}>
      <p className="modal__sub">
        <FormattedMessage id="staff.inviteSub" />
      </p>
      <form
        className="stack"
        onSubmit={(e) => {
          e.preventDefault();
          void run(() =>
            api.call('staffInvite', {
              email: email.trim(),
              name: name.trim(),
              roles,
              access,
            }),
          );
        }}
      >
        <div className="qa-form__row">
          <div className="field">
            <label className="field__label" htmlFor={emailId}>
              <FormattedMessage id="staff.field.email" />
            </label>
            <input
              id={emailId}
              className="field__input"
              type="email"
              value={email}
              maxLength={254}
              onChange={(e) => setEmail(e.target.value)}
            />
          </div>
          <div className="field">
            <label className="field__label" htmlFor={nameId}>
              <FormattedMessage id="staff.field.name" />
            </label>
            <input
              id={nameId}
              className="field__input"
              value={name}
              maxLength={80}
              onChange={(e) => setName(e.target.value)}
            />
          </div>
        </div>
        <div className="field">
          <span className="field__label">
            <FormattedMessage id="staff.col.role" />
          </span>
          <RolePicker team={team} value={roles} onChange={setRoles} multiple={false} />
        </div>
        <AccessField value={access} onChange={setAccess} />
        <LockNote>
          <FormattedMessage id="staff.inviteNote" />
        </LockNote>
        <ErrorLine error={error} />
        <div className="modal__actions">
          <Button onClick={onClose}>
            <FormattedMessage id="action.cancel" />
          </Button>
          <Button kind="primary" type="submit" disabled={busy || !valid}>
            <FormattedMessage id="staff.inviteSend" />
          </Button>
        </div>
      </form>
    </Modal>
  );
}

/** A18 row actions and revoking an invitation (confirmed here; no reason: D-090). */
export function MemberDialog({
  team,
  member,
  invite,
  op,
  onClose,
  onDone,
}: {
  team: StaffTeam;
  member?: StaffMemberRow;
  invite?: StaffInviteRow;
  op: MemberOp | 'revokeInvite';
  onClose: () => void;
  onDone: () => void;
}) {
  const api = useApi();
  const [roles, setRoles] = useState<string[]>(member?.roles ?? []);
  const [access, setAccess] = useState<StaffAccess>({ kind: 'unlimited' });
  const { busy, error, run } = useSubmit(onDone, onClose);
  const who = member?.name ?? invite?.email ?? '';
  const valid = (op !== 'roles' || roles.length > 0) && (op !== 'access' || accessOk(access));
  return (
    <Modal
      title={<FormattedMessage id={`staff.dialog.${op}`} values={{ name: who }} />}
      onClose={onClose}
      wide={op === 'roles'}
    >
      <form
        className="stack"
        onSubmit={(e) => {
          e.preventDefault();
          const base = { op };
          void run(() =>
            api.call(
              'staffUpdateMember',
              op === 'revokeInvite'
                ? { ...base, inviteId: invite!.id }
                : op === 'roles'
                  ? { ...base, uid: member!.uid, roles }
                  : op === 'access'
                    ? { ...base, uid: member!.uid, access }
                    : { ...base, uid: member!.uid },
            ),
          );
        }}
      >
        {op === 'roles' && <RolePicker team={team} value={roles} onChange={setRoles} multiple />}
        {op === 'access' && <AccessField value={access} onChange={setAccess} />}
        {(op === 'pause' || op === 'remove') && (
          <p className="note note--warn">
            <FormattedMessage id={`staff.dialog.${op}.note`} />
          </p>
        )}
        <ErrorLine error={error} />
        <div className="modal__actions">
          <Button onClick={onClose}>
            <FormattedMessage id="action.cancel" />
          </Button>
          <Button
            kind={op === 'remove' || op === 'pause' ? 'danger' : 'primary'}
            type="submit"
            disabled={busy || !valid}
          >
            <FormattedMessage id={`staff.confirm.${op}`} />
          </Button>
        </div>
      </form>
    </Modal>
  );
}

function NewRoleDialog({
  team,
  onClose,
  onCreated,
}: {
  team: StaffTeam;
  onClose: () => void;
  onCreated: (id: string) => void;
}) {
  const api = useApi();
  const nameId = useId();
  const [name, setName] = useState('');
  const [from, setFrom] = useState('support');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const intl = useIntl();
  const template = team.roles.find((r) => r.id === from)?.levels;
  return (
    <Modal title={<FormattedMessage id="staff.newRole" />} onClose={onClose}>
      <form
        className="stack"
        onSubmit={(e) => {
          e.preventDefault();
          setBusy(true);
          setError(null);
          api
            .call<{ roleId: string }>('staffSaveRole', {
              roleId: null,
              name: name.trim(),
              levels: template,
            })
            .then((r) => {
              onClose();
              onCreated(r.roleId);
            })
            .catch((err: unknown) => setError(asApiError(err)))
            .finally(() => setBusy(false));
        }}
      >
        <div className="field">
          <label className="field__label" htmlFor={nameId}>
            <FormattedMessage id="staff.field.roleName" />
          </label>
          <input
            id={nameId}
            className="field__input"
            value={name}
            maxLength={40}
            onChange={(e) => setName(e.target.value)}
          />
        </div>
        <label className="field">
          <span className="field__label">
            <FormattedMessage id="staff.field.template" />
          </span>
          <select className="field__input" value={from} onChange={(e) => setFrom(e.target.value)}>
            {team.roles
              .filter((r) => !['owner', 'admin'].includes(r.id))
              .map((r) => (
                <option key={r.id} value={r.id}>
                  {roleName(intl, r.id, team.roles)}
                </option>
              ))}
          </select>
        </label>
        <ErrorLine error={error} />
        <div className="modal__actions">
          <Button onClick={onClose}>
            <FormattedMessage id="action.cancel" />
          </Button>
          <Button kind="primary" type="submit" disabled={busy || name.trim().length < 2}>
            <FormattedMessage id="staff.createRole" />
          </Button>
        </div>
      </form>
    </Modal>
  );
}

/** Levels a function row offers: "Xem · che" only where masking means something. */
const rowLevels = (f: StaffFunction): StaffLevel[] =>
  f === 'families' || f === 'support'
    ? ['none', 'viewMasked', 'view', 'edit', 'approve', 'full']
    : ['none', 'view', 'edit', 'approve', 'full'];

/** The highest level the editor may give this row on this role (P-134 guards, as the server). */
export function maxLevel(role: string, f: StaffFunction, mine: StaffLevels): StaffLevel {
  const capped = capLevels(role, { ...mine })[f];
  return f === 'staff' && levelAtLeast(capped, 'edit') ? 'view' : capped;
}

/** A21 "Vai trò · Hỗ trợ": levels per function, saved for everyone in the role. */
export function RoleEditor({
  team,
  roleId,
  canManage,
  onBack,
  onPick,
  onSaved,
}: {
  team: StaffTeam;
  roleId: string;
  canManage: boolean;
  onBack: () => void;
  onPick: (id: string) => void;
  onSaved: () => void;
}) {
  const intl = useIntl();
  const api = useApi();
  const staff = useStaff();
  const role = team.roles.find((r) => r.id === roleId);
  const [levels, setLevels] = useState<StaffLevels | null>(role?.levels ?? null);
  const [name, setName] = useState(role?.name ?? '');
  const [confirm, setConfirm] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  useEffect(() => {
    setLevels(role?.levels ?? null);
    setName(role?.name ?? '');
  }, [role]);
  if (!role || !levels) {
    return (
      <Panel>
        <Empty>
          <FormattedMessage id="error.notFound" />
        </Empty>
      </Panel>
    );
  }
  const editable = canManage && !role.locked;
  const changed = JSON.stringify(levels) !== JSON.stringify(role.levels) || name !== role.name;
  const label = roleName(intl, role.id, team.roles);
  return (
    <div className="role-editor">
      <Panel className="role-editor__list" title={<FormattedMessage id="staff.tab.rolesOnly" />}>
        <ul className="qa-nav">
          {team.roles.map((r) => (
            <li key={r.id}>
              <button
                type="button"
                className={`qa-nav__item ${r.id === role.id ? 'qa-nav__item--on' : ''}`}
                onClick={() => onPick(r.id)}
              >
                <span>
                  {roleName(intl, r.id, team.roles)}
                  {r.locked && ' 🔒'}
                </span>
                <span className="qa-nav__count">{intl.formatNumber(r.members)}</span>
              </button>
            </li>
          ))}
        </ul>
      </Panel>
      <Panel
        title={<FormattedMessage id="staff.roleTitle" values={{ name: label }} />}
        note={
          role.updatedBy ? (
            <FormattedMessage
              id="staff.roleEdited"
              values={{ n: role.members, name: role.updatedBy }}
            />
          ) : (
            <FormattedMessage id="staff.roleCount" values={{ n: role.members }} />
          )
        }
        aside={
          <div className="actions">
            <Button onClick={onBack}>
              <FormattedMessage id="staff.backToRoles" />
            </Button>
            {editable && (
              <Button kind="primary" disabled={!changed} onClick={() => setConfirm(true)}>
                <FormattedMessage id="staff.saveRole" />
              </Button>
            )}
          </div>
        }
      >
        {role.locked && (
          <p className="note">
            <FormattedMessage id="staff.lockedRole" />
          </p>
        )}
        {editable && !role.builtin && (
          <label className="field">
            <span className="field__label">
              <FormattedMessage id="staff.field.roleName" />
            </span>
            <input
              className="field__input"
              value={name}
              maxLength={40}
              onChange={(e) => setName(e.target.value)}
            />
          </label>
        )}
        <TableScroll min={520}>
          <table className="table">
            <tbody>
              {functionGroups.map((g) => (
                <FunctionGroupRows key={g.group} group={g.group} cols={1}>
                  {g.fns.map((f) => {
                    const max = maxLevel(role.id, f, staff.levels);
                    return (
                      <tr key={f}>
                        <td>
                          <strong>
                            <FormattedMessage id={`fn.${f}`} />
                          </strong>
                          <br />
                          <span className="muted">
                            <FormattedMessage id={`fn.${f}.note`} />
                          </span>
                        </td>
                        <td className="level-cell">
                          {editable ? (
                            <div
                              className="seg"
                              role="radiogroup"
                              aria-label={intl.formatMessage({ id: `fn.${f}` })}
                            >
                              {rowLevels(f).map((l) => (
                                <button
                                  key={l}
                                  type="button"
                                  role="radio"
                                  aria-checked={levels[f] === l}
                                  className={`seg__item ${levels[f] === l ? 'seg__item--on' : ''}`}
                                  disabled={!levelAtLeast(max, l)}
                                  onClick={() => setLevels({ ...levels, [f]: l })}
                                >
                                  <FormattedMessage id={`level.${l}`} />
                                </button>
                              ))}
                            </div>
                          ) : levels[f] === 'none' ? (
                            <span className="muted">—</span>
                          ) : (
                            <Pill tone={levelTone[levels[f]]}>
                              <FormattedMessage id={`level.${levels[f]}`} />
                            </Pill>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                </FunctionGroupRows>
              ))}
            </tbody>
          </table>
        </TableScroll>
        <LockNote>
          <FormattedMessage id="staff.roleNote" />
        </LockNote>
      </Panel>
      {confirm && (
        <Modal
          title={<FormattedMessage id="staff.saveConfirm" values={{ n: role.members }} />}
          onClose={() => setConfirm(false)}
        >
          <form
            className="stack"
            onSubmit={(e) => {
              e.preventDefault();
              setBusy(true);
              setError(null);
              api
                .call('staffSaveRole', {
                  roleId: role.id,
                  name: role.builtin ? role.name : name.trim(),
                  levels,
                })
                .then(() => {
                  setConfirm(false);
                  onSaved();
                })
                .catch((err: unknown) => setError(asApiError(err)))
                .finally(() => setBusy(false));
            }}
          >
            <ErrorLine error={error} />
            <div className="modal__actions">
              <Button onClick={() => setConfirm(false)}>
                <FormattedMessage id="action.cancel" />
              </Button>
              <Button kind="primary" type="submit" disabled={busy}>
                <FormattedMessage id="staff.saveRole" />
              </Button>
            </div>
          </form>
        </Modal>
      )}
    </div>
  );
}
