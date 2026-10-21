import {
  featureKeys,
  flagKeys,
  staffCan,
  systemFlagKeys,
  type Flag,
  type FlagKey,
} from '@child-life/contracts';
import { Search, X } from 'lucide-react';
import { useState } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { toast } from 'sonner';
import { Badge } from '@/components/ui/badge';
import { Checkbox } from '@/components/ui/checkbox';
import { Input } from '@/components/ui/input';
import { Switch } from '@/components/ui/switch';
import { Textarea } from '@/components/ui/textarea';
import { ToggleGroup, ToggleGroupItem } from '@/components/ui/toggle-group';
import { ApiError, useApi, useLoad, type Api, type FamilyList, type FlagsView } from '../api';
import {
  EmptyState,
  FilterBar,
  Hint,
  Notice,
  SearchInput,
  Section,
  StatTiles,
  type StatItem,
} from '../content-kit';
import { useNavigate, useStaff } from '../context';
import { shortDate } from '../format';
import { messages } from '../messages';
import { Button, Loaded, Modal, Pill, errorMessageId, TableScroll } from '../ui';

/**
 * Flags as staff switch them (A10 / A11), shared by the "Tính năng & Premium" hub (D-089): the
 * "Công tắc hệ thống" tab (engineering switches outside the feature catalogue, the limits), the
 * dialog that turns a flag on or off (with the in-app notice) or picks who uses it, the family
 * picker, and how audit lines read. No reason is asked anywhere (D-090): the server writes the
 * audit line (who, what, before / after) itself. Switches never change who can see what (R-189).
 */

/** A switch / scope change confirmed in {@link FlagDialog}. */
export type FlagChange = { key: FlagKey; next: Flag; kind: 'off' | 'on' | 'scope' };

type State = 'everyone' | 'some' | 'percent' | 'off';

export function flagState(f: Flag): State {
  if (!f.enabled) return 'off';
  return f.scope === 'all' ? 'everyone' : f.scope === 'internal' ? 'some' : 'percent';
}

/**
 * "Công tắc hệ thống" by the area of the app they belong to. Built from `systemFlagKeys`, so a
 * switch added later shows under "Khác" until it gets a group; Mua gói trong app
 * (`premium_billing`) lives on the Gói Premium tab.
 */
const systemGroupOf: Partial<Record<FlagKey, string>> = {
  assistant_live: 'assistant',
  assistant_writes: 'assistant',
  media_upload: 'uploads',
  video_upload: 'uploads',
  story_share_link: 'memories',
  invites: 'family',
  lock_widgets: 'family',
  night_auto: 'family',
  product_analytics: 'analytics',
  premium_billing: 'billing',
};
const systemGroupOrder = ['assistant', 'uploads', 'memories', 'family', 'analytics', 'engagement'];

export const billingFlag: FlagKey = 'premium_billing';

export const systemFlagGroups: ReadonlyArray<{ id: string; keys: FlagKey[] }> = (() => {
  const keys = systemFlagKeys.filter((k) => k !== billingFlag);
  const group = (k: FlagKey) =>
    systemGroupOf[k] ?? (k.startsWith('engagement') ? 'engagement' : 'other');
  return [...systemGroupOrder, 'other']
    .map((id) => ({ id, keys: keys.filter((k) => group(k) === id) }))
    .filter((g) => g.keys.length > 0);
})();

// ---------- Công tắc hệ thống ----------

export function SystemSwitchesLoader() {
  const [load, reload] = useLoad<FlagsView>('staffFlags', {}, 'flags');
  return (
    <Loaded load={load} reload={reload}>
      {(data) => <SystemSwitchesView data={data} onChanged={reload} />}
    </Loaded>
  );
}

/**
 * The engineering switches (uploads, invites, live model calls, engagement…): on/off levers with
 * who uses them, not products, so no tier. Turning one off can show families a short notice.
 */
export function SystemSwitchesView({
  data,
  onChanged,
}: {
  data: FlagsView;
  onChanged: () => void;
}) {
  const intl = useIntl();
  const staff = useStaff();
  const navigate = useNavigate();
  const canToggle = staffCan(staff.levels, 'flags.toggle');
  const canRollout = staffCan(staff.levels, 'flags.rollout');
  const [change, setChange] = useState<FlagChange | null>(null);
  const [q, setQ] = useState('');
  const [state, setState] = useState<State | 'all'>('all');
  const all = systemFlagGroups.flatMap((g) => g.keys);
  const name = (k: FlagKey) => intl.formatMessage({ id: `flag.${k}` });
  const desc = (k: FlagKey) => intl.formatMessage({ id: `flag.${k}.desc` });
  const match = (k: FlagKey) =>
    (state === 'all' || flagState(data.flags[k]) === state) &&
    (!q.trim() || `${name(k)} ${desc(k)} ${k}`.toLowerCase().includes(q.trim().toLowerCase()));
  const shown = all.filter(match);
  const count = (s: State) => all.filter((k) => flagState(data.flags[k]) === s).length;
  const pick = (s: State) => () => setState(state === s ? 'all' : s);
  const tiles: StatItem[] = (['everyone', 'some', 'percent', 'off'] as const).map((s) => ({
    key: s,
    label: <FormattedMessage id={`features.tile.${s}`} />,
    value: count(s),
    tone: s === 'off' && count(s) ? 'error' : s === 'percent' && count(s) ? 'warn' : 'default',
    active: state === s,
    onClick: pick(s),
  }));
  return (
    <div className="grid min-w-0 gap-4">
      <StatTiles items={tiles} />
      <div className="overflow-hidden rounded-xl border bg-card">
        <FilterBar
          active={!!q || state !== 'all'}
          onClear={() => {
            setQ('');
            setState('all');
          }}
          shown={shown.length}
          total={all.length}
        >
          <SearchInput
            value={q}
            onChange={setQ}
            placeholder={intl.formatMessage({ id: 'features.search' })}
          />
          <span className="ml-auto flex items-center gap-1 text-[13px] text-muted-foreground">
            <FormattedMessage id="hub.switches.billingElsewhere" />
            <Button kind="ghost" onClick={() => navigate('features', 'plan')}>
              <FormattedMessage id="hub.tab.plan" />
            </Button>
          </span>
        </FilterBar>
        {shown.length === 0 ? (
          <EmptyState icon={Search} title={<FormattedMessage id="features.noMatch" />} />
        ) : (
          <TableScroll min={680}>
            <table className="table">
              <thead>
                <tr>
                  <th>
                    <FormattedMessage id="col.feature" />
                  </th>
                  <th>
                    <FormattedMessage id="col.scope" />
                  </th>
                  <th>
                    <FormattedMessage id="col.lastEdit" />
                  </th>
                  <th className="w-20">
                    <FormattedMessage id="col.on" />
                  </th>
                </tr>
              </thead>
              {systemFlagGroups.map((g) => {
                const keys = g.keys.filter(match);
                if (!keys.length) return null;
                return (
                  <tbody key={g.id}>
                    <tr className="cl-group-row">
                      <th colSpan={4} scope="rowgroup">
                        <FormattedMessage id={`features.group.${g.id}`} />
                        <span className="font-normal text-muted-foreground"> · {keys.length}</span>
                      </th>
                    </tr>
                    {keys.map((key) => (
                      <FlagRow
                        key={key}
                        flag={key}
                        value={data.flags[key]}
                        last={data.lastEdit[key] ?? null}
                        canToggle={canToggle}
                        canRollout={canRollout}
                        onChange={setChange}
                      />
                    ))}
                  </tbody>
                );
              })}
            </table>
          </TableScroll>
        )}
      </div>
      <Section collapsible defaultOpen={false} title={<FormattedMessage id="features.limits" />}>
        <LimitsList limits={data.limits} />
      </Section>
      {change && (
        <FlagDialog
          change={change}
          onClose={() => setChange(null)}
          onDone={() => {
            setChange(null);
            onChanged();
          }}
        />
      )}
    </div>
  );
}

/** One switch: what it does (and what turning it off does, behind "?"), who uses it, the switch. */
export function FlagRow({
  flag: key,
  value: f,
  last,
  canToggle,
  canRollout,
  onChange,
}: {
  flag: FlagKey;
  value: Flag;
  last: { by: string; at: string } | null;
  canToggle: boolean;
  canRollout: boolean;
  onChange: (c: FlagChange) => void;
}) {
  const intl = useIntl();
  const name = intl.formatMessage({ id: `flag.${key}` });
  return (
    <tr>
      <td className="max-w-[30rem]">
        <span className="flex items-center gap-1 font-medium">
          {name}
          <Hint>
            <FormattedMessage id={`flag.${key}.desc`} />
            {'. '}
            <FormattedMessage id="features.whenOff" />{' '}
            <FormattedMessage id={`flag.${key}.offEffect`} />
          </Hint>
        </span>
        <span className="block truncate text-xs text-muted-foreground">
          <FormattedMessage id={`flag.${key}.desc`} />
        </span>
      </td>
      <td>
        {!f.enabled ? (
          <span className="text-muted-foreground">—</span>
        ) : canRollout && f.scope !== 'percent' ? (
          // "Ai được dùng": a few families, or every family.
          <button
            type="button"
            className="link-button"
            onClick={() => onChange({ key, kind: 'scope', next: { ...f } })}
            aria-label={intl.formatMessage({ id: 'features.scopeTitle' }, { flag: name })}
          >
            <ScopePill flag={f} />
          </button>
        ) : (
          <ScopePill flag={f} />
        )}
      </td>
      <td className="nowrap text-muted-foreground tabular-nums">
        {last ? `${last.by.split(' ')[0]} · ${shortDate(intl, last.at)}` : '—'}
      </td>
      <td>
        <Switch
          checked={f.enabled}
          aria-label={name}
          disabled={!canToggle}
          title={canToggle ? undefined : intl.formatMessage({ id: 'features.toggleRole' })}
          // Confirmed in a dialog first (A11), so the switch only asks.
          onCheckedChange={() =>
            onChange({
              key,
              kind: f.enabled ? 'off' : 'on',
              next: { ...f, enabled: !f.enabled, notice: null },
            })
          }
        />
      </td>
    </tr>
  );
}

export function LimitsList({ limits }: { limits: FlagsView['limits'] }) {
  return (
    <dl className="kv">
      <dt>
        <FormattedMessage id="limits.quota" />
      </dt>
      <dd>
        <FormattedMessage
          id="limits.quotaValue"
          values={{ n: Math.round(limits.familyQuotaBytes / 1024 ** 3) }}
        />
      </dd>
      <dt>
        <FormattedMessage id="limits.video" />
      </dt>
      <dd>
        {limits.videoMaxDurationSec === null ? (
          <FormattedMessage id="limits.unlimited" />
        ) : (
          <FormattedMessage
            id="limits.minutes"
            values={{ n: Math.round(limits.videoMaxDurationSec / 60) }}
          />
        )}
      </dd>
      <dt>
        <FormattedMessage id="limits.export" />
      </dt>
      <dd>
        <FormattedMessage id="limits.exportValue" values={{ n: limits.exportLinkTtlHours }} />
      </dd>
      <dt>
        <FormattedMessage id="limits.autoSave" />
      </dt>
      <dd>
        <FormattedMessage
          id="limits.autoSaveValue"
          values={{ n: limits.autoSaveItemsPerApprove }}
        />
      </dd>
    </dl>
  );
}

/** Recent changes as actions, who and when (and the note of older entries, which had one). */
export function RecentList({
  recent,
}: {
  recent: ReadonlyArray<{
    action: string;
    target: string;
    by: string;
    at: string;
    reason?: string | null;
    detail?: Record<string, unknown> | null;
  }>;
}) {
  const intl = useIntl();
  if (recent.length === 0) {
    return (
      <p className="text-sm text-muted-foreground">
        <FormattedMessage id="features.noRecent" />
      </p>
    );
  }
  return (
    <ul className="grid gap-3">
      {recent.map((r, i) => (
        <li key={i} className="grid gap-0.5 border-b pb-3 last:border-0 last:pb-0">
          <p className="text-sm">
            <AuditActionText action={r.action} target={r.target} detail={r.detail ?? null} />
          </p>
          <p className="text-xs text-muted-foreground">
            {[r.by.split(' ')[0], shortDate(intl, r.at), r.reason?.trim()]
              .filter(Boolean)
              .join(' · ')}
          </p>
        </li>
      ))}
    </ul>
  );
}

export function ScopePill({ flag }: { flag: Flag }) {
  if (flag.scope === 'internal') {
    const n = flag.families?.length ?? 0;
    return (
      <Pill tone="purple">
        {n ? (
          <FormattedMessage id="scope.chosen" values={{ n }} />
        ) : (
          <FormattedMessage id="scope.internal" />
        )}
      </Pill>
    );
  }
  if (flag.scope === 'percent') {
    return (
      <Pill tone="wait">
        <FormattedMessage id="scope.percent" values={{ p: flag.percent }} />
      </Pill>
    );
  }
  return (
    <span className="text-muted-foreground">
      <FormattedMessage id="scope.all" />
    </span>
  );
}

/** Audit actions with their own sentence (`audit.<action>`); others read as the action id. */
const knownActions = [
  'support.claim',
  'support.reply',
  'support.macro.wifiGuide',
  'support.close',
  'support.screenshot',
  'storage.grant',
  'storage.decline',
  'jobs.rerun',
  'flags.on',
  'flags.off',
  'flags.rollout',
  'flags.families',
  'audit.export',
  'jobs.rerunRequest',
  'staff.invite',
  'staff.join',
  'staff.revokeInvite',
  'staff.roles',
  'staff.access',
  'staff.pause',
  'staff.resume',
  'staff.remove',
  'staff.saveRole',
  'staff.createRole',
  'family.view',
  'family.transferOpen',
  'family.transferCancel',
  'analytics.export',
  'reference.draft',
  'reference.submit',
  'reference.publish',
  'reference.reject',
  'reference.discard',
  'reference.rollback',
  'content.firstAid.draft',
  'content.firstAid.submit',
  'content.firstAid.approve',
  'content.firstAid.reject',
  'content.firstAid.discard',
  'content.firstAid.rollback',
  'content.firstAid.image',
  'content.keepsakes.draft',
  'content.keepsakes.submit',
  'content.keepsakes.approve',
  'content.keepsakes.reject',
  'content.keepsakes.discard',
  'content.keepsakes.rollback',
  'content.keepsakes.asset',
  'release.publish',
  'release.image',
  'premium.config',
  'premium.grant',
  'premium.revoke',
  // Tính năng & Premium (D-089).
  'premium.full.on',
  'premium.full.off',
  'hub.tier',
  'hub.beta',
  'hub.beta.add',
  'hub.beta.remove',
  'hub.override',
  'hub.override.clear',
  ...['reference', 'content'].flatMap((doc) =>
    ['draft', 'submit', 'approve', 'reject', 'discard', 'rollback'].map(
      (a) => `content.rhythm.${doc}.${a}`,
    ),
  ),
  'features.rhythm.rules',
  'system.videoRequeue',
  'system.videoBackfill',
];

/** "Tắt “Tải video”", "Đổi gói “Video kỷ niệm” sang Premium" (A10 recent, A12, the hub). */
export function AuditActionText({
  action,
  target,
  detail,
}: {
  action: string;
  target: string;
  detail: Record<string, unknown> | null;
}) {
  const intl = useIntl();
  const flagName = (flagKeys as readonly string[]).includes(target)
    ? intl.formatMessage({ id: `flag.${target}` })
    : target;
  const after = (detail?.after ?? null) as (Flag & { state?: string }) | string | null;
  const featureKey = [detail?.feature, target].find(
    (k): k is string => typeof k === 'string' && (featureKeys as readonly string[]).includes(k),
  );
  const tier = typeof after === 'string' ? after : null;
  const values = {
    flag: flagName,
    p: typeof after === 'object' && after ? (after.scope === 'all' ? 100 : after.percent) : 0,
    n: (detail?.grantGb ?? detail?.requestedGb ?? '') as number | string,
    feature: featureKey ? intl.formatMessage({ id: `hub.feature.${featureKey}` }) : target,
    code: target,
    tier: tier && ['free', 'premium', 'beta'].includes(tier) ? tier : 'other',
    state: typeof after === 'object' && after?.state === 'on' ? 'on' : 'off',
  };
  return (
    <FormattedMessage
      id={knownActions.includes(action) ? `audit.${action}` : 'audit.other'}
      values={{ ...values, action }}
    />
  );
}

/** A10/A11 confirm: `staffSetFlag` (role `flags.toggle` for on / off), audited; no reason. */
export function FlagDialog({
  change,
  onClose,
  onDone,
}: {
  change: FlagChange;
  onClose: () => void;
  onDone: () => void;
}) {
  const intl = useIntl();
  const api = useApi();
  const [notify, setNotify] = useState(true);
  // Families see this text as typed; the default is the Vietnamese source copy (D-012).
  const [notice, setNotice] = useState(() => defaultNotice(change.key));
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const off = change.kind === 'off';
  // "Ai được dùng" (on, or the scope cell): a few families, or every family.
  const choosing =
    (change.kind === 'on' || change.kind === 'scope') && change.next.scope !== 'percent';
  const [who, setWho] = useState<'some' | 'all'>(change.next.scope === 'all' ? 'all' : 'some');
  const [families, setFamilies] = useState<string[]>(change.next.families ?? []);
  const scope = choosing ? (who === 'all' ? 'all' : 'internal') : change.next.scope;
  const next: Flag = {
    ...change.next,
    scope,
    families: scope === 'internal' ? (choosing ? families : change.next.families) : undefined,
  };
  const flag = intl.formatMessage({ id: `flag.${change.key}` });
  const submit = async () => {
    setBusy(true);
    setError(null);
    try {
      const percent = next.scope === 'all' ? 100 : next.percent;
      await api.call('staffSetFlag', {
        key: change.key,
        enabled: next.enabled,
        scope: next.scope,
        percent: [0, 10, 25, 50, 100].includes(percent) ? percent : 0,
        notice: off && notify && notice.trim() ? notice.trim() : null,
        // Only a choice made here is sent; a plain on / off keeps the families picked before.
        ...(choosing && next.scope === 'internal' ? { families } : {}),
      });
      toast.success(
        intl.formatMessage(
          {
            id: off
              ? 'features.done.off'
              : change.kind === 'on'
                ? 'features.done.on'
                : 'features.done.scope',
          },
          { flag },
        ),
      );
      onDone();
    } catch (e) {
      setError(e instanceof ApiError ? e : new ApiError('unknown', null));
    } finally {
      setBusy(false);
    }
  };
  return (
    <Modal
      title={
        <FormattedMessage
          id={
            off
              ? 'features.offTitle'
              : change.kind === 'on'
                ? 'features.onTitle'
                : 'features.scopeTitle'
          }
          values={{ flag }}
        />
      }
      onClose={onClose}
    >
      <Notice tone={off ? 'warn' : 'info'}>
        <FormattedMessage id={off ? `flag.${change.key}.offEffect` : 'features.onEffect'} />
      </Notice>
      {choosing && (
        <div className="grid gap-2">
          <span className="text-[13px] font-medium">
            <FormattedMessage id="features.who" />
          </span>
          <ToggleGroup
            type="single"
            variant="outline"
            value={who}
            onValueChange={(v) => v && setWho(v as 'some' | 'all')}
          >
            <ToggleGroupItem value="some" className="px-3">
              <FormattedMessage id="features.whoSome" />
            </ToggleGroupItem>
            <ToggleGroupItem value="all" className="px-3">
              <FormattedMessage id="features.whoAll" />
            </ToggleGroupItem>
          </ToggleGroup>
          {who === 'some' && <FamilyPicker value={families} onChange={setFamilies} />}
        </div>
      )}
      <p className="text-sm">
        <span className="text-muted-foreground">
          <FormattedMessage id="features.impact" />:
        </span>{' '}
        <strong className="font-medium">
          <ScopeText flag={next} />
        </strong>
      </p>
      {off && (
        <NoticeField notify={notify} onNotify={setNotify} notice={notice} onNotice={setNotice} />
      )}
      {error && (
        <Notice tone="error">
          <FormattedMessage id={errorMessageId(error)} />
        </Notice>
      )}
      <div className="modal__actions">
        <Button onClick={onClose}>
          <FormattedMessage id="action.cancel" />
        </Button>
        <Button kind={off ? 'danger' : 'primary'} disabled={busy} onClick={() => void submit()}>
          <FormattedMessage id={off ? 'features.turnOff' : 'features.confirm'} />
        </Button>
      </div>
    </Modal>
  );
}

/** A11 "Báo cho gia đình trong app": the sentence families see while a feature is off. */
export function NoticeField({
  notify,
  onNotify,
  notice,
  onNotice,
}: {
  notify: boolean;
  onNotify: (v: boolean) => void;
  notice: string;
  onNotice: (v: string) => void;
}) {
  const intl = useIntl();
  return (
    <div className="grid gap-2">
      <label className="check-row flex items-center gap-2 text-sm">
        <Checkbox checked={notify} onCheckedChange={(v) => onNotify(v === true)} />
        <FormattedMessage id="features.notify" />
      </label>
      {notify && (
        <>
          <Textarea
            rows={2}
            maxLength={280}
            value={notice}
            onChange={(e) => onNotice(e.target.value)}
            aria-label={intl.formatMessage({ id: 'features.notify' })}
          />
          <p className="text-xs text-muted-foreground">
            <FormattedMessage id="features.noticeHelp" />
          </p>
        </>
      )}
    </div>
  );
}

export function defaultNotice(key: FlagKey, name?: string): string {
  return messages.vi['features.noticeDefault']!.replace(
    '{flag}',
    name ?? messages.vi[`flag.${key}`]!,
  );
}

/**
 * A family code (F-XXXX) or a parent's exact email → family codes, matched on the server and
 * never shown back. `problem` is a message id.
 */
export async function resolveFamilyCodes(
  api: Api,
  raw: string,
): Promise<{ codes: string[] } | { problem: string }> {
  const text = raw.trim();
  if (/^F-[A-Z2-9]{4}$/i.test(text)) return { codes: [text.toUpperCase()] };
  if (!text.includes('@')) return { problem: 'features.familyHint' };
  try {
    const found = await api.call<FamilyList>('staffFamilies', {
      activity: 'all',
      platform: 'all',
      storage: 'all',
      q: text,
    });
    return found.rows.length
      ? { codes: found.rows.map((r) => r.code) }
      : { problem: 'features.familyNotFound' };
  } catch (e) {
    return { problem: e instanceof ApiError ? errorMessageId(e) : 'features.familyNotFound' };
  }
}

/** "Một vài gia đình": by family code (F-XXXX, as Gia đình shows it) or a parent's exact email. */
export function FamilyPicker({
  value,
  onChange,
  label,
  empty,
}: {
  value: string[];
  onChange: (v: string[]) => void;
  /** Names the field for screen readers; "Mã gia đình…" by default. */
  label?: string;
  /** What an empty list means (message id). */
  empty?: string;
}) {
  const intl = useIntl();
  const api = useApi();
  const [q, setQ] = useState('');
  const [busy, setBusy] = useState(false);
  const [problem, setProblem] = useState<string | null>(null);
  const add = async () => {
    if (!q.trim()) return;
    setProblem(null);
    setBusy(true);
    const r = await resolveFamilyCodes(api, q);
    setBusy(false);
    if ('problem' in r) setProblem(r.problem);
    else {
      onChange([...new Set([...value, ...r.codes])]);
      setQ('');
    }
  };
  return (
    <div className="grid gap-2">
      <div className="flex gap-2">
        <Input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === 'Enter') {
              e.preventDefault();
              void add();
            }
          }}
          placeholder={intl.formatMessage({ id: 'features.familyFind' })}
          aria-label={label ?? intl.formatMessage({ id: 'features.familyFind' })}
        />
        <Button disabled={busy || !q.trim()} onClick={() => void add()}>
          <FormattedMessage id="features.familyAdd" />
        </Button>
      </div>
      {problem && (
        <p className="text-sm text-destructive" role="alert">
          <FormattedMessage id={problem} />
        </p>
      )}
      {value.length === 0 ? (
        <p className="text-xs text-muted-foreground">
          <FormattedMessage id={empty ?? 'features.familyNone'} />
        </p>
      ) : (
        <ul className="flex flex-wrap gap-1.5">
          {value.map((code) => (
            <li key={code}>
              <Badge variant="secondary" className="gap-1 pr-1 font-mono">
                {code}
                <button
                  type="button"
                  className="grid size-4 place-items-center rounded-full hover:bg-muted-foreground/20"
                  aria-label={intl.formatMessage({ id: 'features.familyRemove' }, { code })}
                  onClick={() => onChange(value.filter((c) => c !== code))}
                >
                  <X className="size-3" />
                </button>
              </Badge>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

export function ScopeText({ flag }: { flag: Flag }) {
  if (flag.scope === 'internal' && flag.families?.length)
    return <FormattedMessage id="impact.chosen" values={{ n: flag.families.length }} />;
  if (flag.scope === 'internal') return <FormattedMessage id="impact.internal" />;
  if (flag.scope === 'percent')
    return <FormattedMessage id="impact.percent" values={{ p: flag.percent }} />;
  return <FormattedMessage id="impact.all" />;
}
