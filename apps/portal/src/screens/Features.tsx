import {
  flagKeys,
  staffCan,
  type Capability,
  type Flag,
  type FlagKey,
  type Flags,
  type GateReason,
  type StaffFamilyPremium,
} from '@child-life/contracts';
import { Check, CircleCheck, CircleSlash, Search, Users, X } from 'lucide-react';
import { useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { toast } from 'sonner';
import { Badge } from '@/components/ui/badge';
import { Button as UiButton } from '@/components/ui/button';
import { Checkbox } from '@/components/ui/checkbox';
import { Input } from '@/components/ui/input';
import { Switch } from '@/components/ui/switch';
import { Textarea } from '@/components/ui/textarea';
import { ToggleGroup, ToggleGroupItem } from '@/components/ui/toggle-group';
import { cn } from '@/lib/utils';
import {
  ApiError,
  useApi,
  useLoad,
  type Api,
  type AiStats,
  type FamilyList,
  type FlagsView,
} from '../api';
import {
  EmptyState,
  FilterBar,
  HelpPopover,
  Hint,
  Notice,
  SearchInput,
  Section,
  StatTiles,
  type StatItem,
} from '../content-kit';
import { useNavigate, useStaff } from '../context';
import { pct, shortDate } from '../format';
import { messages } from '../messages';
import {
  Button,
  Loaded,
  Modal,
  Page,
  Pill,
  ReasonField,
  errorMessageId,
  reasonOk,
  TableScroll,
} from '../ui';

/**
 * A10 Tính năng & phát hành: switches never change who can see what (R-189). Flags are grouped by
 * area; "Bật cho gia đình" adds families to several flags at once, and "Kiểm tra gia đình" shows
 * what one family's app is told and why a feature stays hidden (country, flag, no grant).
 */
export function FeaturesScreen() {
  const [load, reload] = useLoad<FlagsView>('staffFlags', {}, 'flags');
  const [ai] = useLoad<AiStats>('staffAi', {}, 'ai');
  return (
    <Page
      title={<FormattedMessage id="features.title" />}
      subtitle={<FormattedMessage id="features.sub" />}
    >
      <Loaded load={load} reload={reload}>
        {(data) => (
          <FeaturesView data={data} ai={ai.status === 'ok' ? ai.data : null} onChanged={reload} />
        )}
      </Loaded>
    </Page>
  );
}

/** The rollout ladder (A10): internal → 10 → 25 → 50 → 100 %. */
export const ladder = [10, 25, 50, 100] as const;

export function nextStep(flag: Flag): (typeof ladder)[number] | null {
  if (!flag.enabled || flag.scope === 'internal') return 10;
  if (flag.scope === 'all') return null;
  return ladder.find((p) => p > flag.percent) ?? null;
}

/** A switch / scope change confirmed in {@link FlagDialog} (also used by Trợ lý AI › Công tắc). */
export type FlagChange = { key: FlagKey; next: Flag; kind: 'off' | 'on' | 'step' | 'scope' };
type Change = FlagChange;

/** Flags by the area of the app they belong to; every flag is in exactly one group. */
export const flagGroups: ReadonlyArray<{ id: string; keys: readonly FlagKey[] }> = [
  {
    id: 'assistant',
    keys: [
      'assistant',
      'assistant_live',
      'assistant_writes',
      'assistant_images',
      'assistant_care',
      'assistant_upsell',
    ],
  },
  { id: 'rhythm', keys: ['rhythm', 'personalization', 'ai_assist'] },
  {
    id: 'memories',
    keys: ['memory_story', 'milestone_cards', 'ai_story_drafts', 'story_share_link', 'auto_save'],
  },
  { id: 'uploads', keys: ['media_upload', 'video_upload'] },
  { id: 'family', keys: ['invites', 'lock_widgets', 'night_auto'] },
  { id: 'billing', keys: ['premium_billing'] },
];

type StateFilter = 'all' | 'everyone' | 'some' | 'percent' | 'off';

export function flagState(f: Flag): Exclude<StateFilter, 'all'> {
  if (!f.enabled) return 'off';
  return f.scope === 'all' ? 'everyone' : f.scope === 'internal' ? 'some' : 'percent';
}

/** Initial choice for {@link BulkFamiliesDialog}. */
export type BulkInit = { families: string[]; keys: FlagKey[] };

export function FeaturesView({
  data,
  ai,
  onChanged,
}: {
  data: FlagsView;
  ai: AiStats | null;
  onChanged: () => void;
}) {
  const intl = useIntl();
  const staff = useStaff();
  const canToggle = staffCan(staff.levels, 'flags.toggle');
  const canRollout = staffCan(staff.levels, 'flags.rollout');
  const canCheck = staffCan(staff.levels, 'premium.view');
  const [change, setChange] = useState<Change | null>(null);
  const [bulk, setBulk] = useState<BulkInit | null>(null);
  const [q, setQ] = useState('');
  const [state, setState] = useState<StateFilter>('all');
  const name = (k: FlagKey) => intl.formatMessage({ id: `flag.${k}` });
  const desc = (k: FlagKey) => intl.formatMessage({ id: `flag.${k}.desc` });
  const match = (k: FlagKey) =>
    (state === 'all' || flagState(data.flags[k]) === state) &&
    (!q.trim() || `${name(k)} ${desc(k)}`.toLowerCase().includes(q.trim().toLowerCase()));
  const shown = flagKeys.filter(match);
  const count = (s: StateFilter) => flagKeys.filter((k) => flagState(data.flags[k]) === s).length;
  const pick = (s: StateFilter) => () => setState(state === s ? 'all' : s);
  const tiles: StatItem[] = [
    {
      key: 'everyone',
      label: <FormattedMessage id="features.tile.everyone" />,
      value: count('everyone'),
      active: state === 'everyone',
      onClick: pick('everyone'),
    },
    {
      key: 'some',
      label: <FormattedMessage id="features.tile.some" />,
      value: count('some'),
      tone: 'default',
      active: state === 'some',
      onClick: pick('some'),
    },
    {
      key: 'percent',
      label: <FormattedMessage id="features.tile.percent" />,
      value: count('percent'),
      tone: count('percent') ? 'warn' : 'muted',
      active: state === 'percent',
      onClick: pick('percent'),
    },
    {
      key: 'off',
      label: <FormattedMessage id="features.tile.off" />,
      value: count('off'),
      tone: count('off') ? 'error' : 'muted',
      active: state === 'off',
      onClick: pick('off'),
    },
  ];
  return (
    <div className="grid gap-4">
      {canCheck && (
        <FamilyCheck
          flags={data.flags}
          canEnable={canRollout}
          onEnable={(code, keys) => setBulk({ families: [code], keys })}
        />
      )}
      <StatTiles items={tiles} />
      <div className="overflow-hidden rounded-xl border bg-card">
        <FilterBar
          active={!!q || state !== 'all'}
          onClear={() => {
            setQ('');
            setState('all');
          }}
          shown={shown.length}
          total={flagKeys.length}
        >
          <SearchInput
            value={q}
            onChange={setQ}
            placeholder={intl.formatMessage({ id: 'features.search' })}
          />
          <HelpPopover title={<FormattedMessage id="features.howTitle" />}>
            <p className="text-muted-foreground">
              <FormattedMessage id="features.lock" />
            </p>
          </HelpPopover>
          {canRollout && (
            <UiButton className="ml-auto" onClick={() => setBulk({ families: [], keys: [] })}>
              <Users />
              <FormattedMessage id="features.bulk.open" />
            </UiButton>
          )}
        </FilterBar>
        {shown.length === 0 ? (
          <EmptyState icon={Search} title={<FormattedMessage id="features.noMatch" />} />
        ) : (
          <TableScroll min={720}>
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
              {flagGroups.map((g) => {
                const keys = g.keys.filter(match);
                if (!keys.length) return null;
                const forSome = g.keys.filter((k) => data.flags[k].scope === 'internal');
                return (
                  <tbody key={g.id}>
                    <tr className="cl-group-row">
                      <th colSpan={4} scope="rowgroup">
                        <div className="flex items-center gap-2">
                          <span>
                            <FormattedMessage id={`features.group.${g.id}`} />
                          </span>
                          <span className="font-normal text-muted-foreground">· {keys.length}</span>
                          {canRollout && forSome.length > 1 && (
                            <UiButton
                              variant="ghost"
                              size="sm"
                              className="ml-auto h-7 font-normal text-primary"
                              onClick={() => setBulk({ families: [], keys: forSome })}
                            >
                              <Users />
                              <FormattedMessage id="features.bulk.group" />
                            </UiButton>
                          )}
                        </div>
                      </th>
                    </tr>
                    {keys.map((key) => {
                      const f = data.flags[key];
                      const last = data.lastEdit[key];
                      return (
                        <tr key={key}>
                          <td className="max-w-[30rem]">
                            <span className="flex items-center gap-1 font-medium">
                              <FormattedMessage id={`flag.${key}`} />
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
                                onClick={() => setChange({ key, kind: 'scope', next: { ...f } })}
                                aria-label={intl.formatMessage(
                                  { id: 'features.scopeTitle' },
                                  { flag: name(key) },
                                )}
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
                              aria-label={name(key)}
                              disabled={!canToggle}
                              title={
                                canToggle
                                  ? undefined
                                  : intl.formatMessage({ id: 'features.toggleRole' })
                              }
                              // The change is confirmed in a dialog first (A11), so the switch only asks.
                              onCheckedChange={() =>
                                setChange({
                                  key,
                                  kind: f.enabled ? 'off' : 'on',
                                  next: { ...f, enabled: !f.enabled, notice: null },
                                })
                              }
                            />
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                );
              })}
            </table>
          </TableScroll>
        )}
      </div>
      <Section
        collapsible
        defaultOpen={false}
        title={<FormattedMessage id="features.rollout" />}
        summary={<ScopePill flag={data.flags.ai_story_drafts} />}
      >
        <RolloutLadder
          flag={data.flags.ai_story_drafts}
          ai={ai}
          canToggle={canToggle}
          canRollout={canRollout}
          onStep={setChange}
        />
      </Section>
      <Section collapsible defaultOpen={false} title={<FormattedMessage id="features.limits" />}>
        <LimitsList limits={data.limits} />
      </Section>
      <Section
        collapsible
        defaultOpen={false}
        title={<FormattedMessage id="features.recent" />}
        summary={<FormattedMessage id="features.recentCount" values={{ n: data.recent.length }} />}
      >
        <RecentList recent={data.recent} />
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
      {bulk && (
        <BulkFamiliesDialog
          flags={data.flags}
          initial={bulk}
          onClose={() => setBulk(null)}
          onDone={() => {
            setBulk(null);
            onChanged();
          }}
        />
      )}
    </div>
  );
}

/** "Mở dần · AI gợi ý câu chuyện": the ladder, its guard rails and the next step. */
export function RolloutLadder({
  flag,
  ai,
  canToggle,
  canRollout,
  onStep,
}: {
  flag: Flag;
  ai: AiStats | null;
  canToggle: boolean;
  canRollout: boolean;
  onStep: (c: Change) => void;
}) {
  const intl = useIntl();
  const step = nextStep(flag);
  const budgetUsed =
    ai && ai.budget.monthlyBudgetVnd ? ai.budget.spentVnd / ai.budget.monthlyBudgetVnd : null;
  return (
    <div className="grid gap-4">
      <ol className="ladder">
        {ladder.map((p) => {
          const current =
            flag.enabled &&
            ((flag.scope === 'percent' && flag.percent === p) ||
              (flag.scope === 'all' && p === 100));
          const passed =
            flag.enabled &&
            (flag.scope === 'all' || (flag.scope === 'percent' && flag.percent > p));
          return (
            <li
              key={p}
              className={`ladder__step ${current ? 'ladder__step--on' : passed ? 'ladder__step--done' : ''}`}
            >
              {p}%
            </li>
          );
        })}
      </ol>
      <dl className="kv kv--checks">
        <dt>
          <FormattedMessage id="features.guardReports" />
        </dt>
        <dd>
          {ai ? (
            <FormattedMessage id="features.guardReportsValue" values={{ n: ai.kpis.reports }} />
          ) : (
            '—'
          )}
        </dd>
        <dt>
          <FormattedMessage id="features.guardCost" />
        </dt>
        <dd>
          {budgetUsed === null ? (
            '—'
          ) : (
            <FormattedMessage id="features.guardCostValue" values={{ p: pct(intl, budgetUsed) }} />
          )}
        </dd>
        <dt>
          <FormattedMessage id="features.guardErrors" />
        </dt>
        <dd>
          <FormattedMessage id="features.guardErrorsValue" />
        </dd>
      </dl>
      {step !== null && (
        <div>
          <Button
            kind="primary"
            disabled={!canRollout || (!flag.enabled && !canToggle)}
            title={canRollout ? undefined : intl.formatMessage({ id: 'error.role' })}
            onClick={() =>
              onStep({
                key: 'ai_story_drafts',
                kind: flag.enabled ? 'step' : 'on',
                next: {
                  enabled: true,
                  scope: step === 100 ? 'all' : 'percent',
                  percent: step,
                  notice: null,
                },
              })
            }
          >
            <FormattedMessage id="features.openTo" values={{ p: step }} />
          </Button>
        </div>
      )}
    </div>
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

/** Recent changes as actions, who and when, and the reason they gave. */
export function RecentList({
  recent,
}: {
  recent: ReadonlyArray<{
    action: string;
    target: string;
    by: string;
    at: string;
    reason: string;
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
            {r.by.split(' ')[0]} · {shortDate(intl, r.at)} · {r.reason}
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

/** "Tắt “Tải video”", "Mở “AI gợi ý câu chuyện” lên 50%" (A10 recent, A12). */
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
  const after = (detail?.after ?? null) as Flag | null;
  const values = {
    flag: flagName,
    p: after?.scope === 'all' ? 100 : (after?.percent ?? 0),
    n: (detail?.grantGb ?? detail?.requestedGb ?? '') as number | string,
  };
  const known = [
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
    ...['reference', 'content'].flatMap((doc) =>
      ['draft', 'submit', 'approve', 'reject', 'discard', 'rollback'].map(
        (a) => `content.rhythm.${doc}.${a}`,
      ),
    ),
    'features.rhythm.rules',
    'system.videoRequeue',
    'system.videoBackfill',
  ];
  return (
    <FormattedMessage
      id={known.includes(action) ? `audit.${action}` : 'audit.other'}
      values={{ ...values, action }}
    />
  );
}

/** A10/A11 confirm: reason required, `staffSetFlag` (role `flags.toggle` for on / off), audited. */
export function FlagDialog({
  change,
  onClose,
  onDone,
}: {
  change: Change;
  onClose: () => void;
  onDone: () => void;
}) {
  const intl = useIntl();
  const api = useApi();
  const [reason, setReason] = useState('');
  const [notify, setNotify] = useState(true);
  // Families see this text as typed; the default is the Vietnamese source copy (D-012).
  const [notice, setNotice] = useState(() => defaultNotice(change.key));
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const off = change.kind === 'off';
  // "Ai được dùng" (on, or the scope cell): a few families, or every family. Percent steps stay
  // on the rollout ladder.
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
        reason: reason.trim(),
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
                : change.kind === 'scope'
                  ? 'features.scopeTitle'
                  : 'features.stepTitle'
          }
          values={{ flag, p: next.scope === 'all' ? 100 : next.percent }}
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
      <ReasonField value={reason} onChange={setReason} required />
      {off && (
        <div className="grid gap-2">
          <label className="check-row flex items-center gap-2 text-sm">
            <Checkbox checked={notify} onCheckedChange={(v) => setNotify(v === true)} />
            <FormattedMessage id="features.notify" />
          </label>
          {notify && (
            <>
              <Textarea
                rows={2}
                maxLength={280}
                value={notice}
                onChange={(e) => setNotice(e.target.value)}
                aria-label={intl.formatMessage({ id: 'features.notify' })}
              />
              <p className="text-xs text-muted-foreground">
                <FormattedMessage id="features.noticeHelp" />
              </p>
            </>
          )}
        </div>
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
        <Button
          kind={off ? 'danger' : 'primary'}
          disabled={busy || !reasonOk(reason)}
          onClick={() => void submit()}
        >
          <FormattedMessage id={off ? 'features.turnOff' : 'features.confirm'} />
        </Button>
      </div>
    </Modal>
  );
}

export function defaultNotice(key: FlagKey): string {
  return messages.vi['features.noticeDefault']!.replace('{flag}', messages.vi[`flag.${key}`]!);
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
}: {
  value: string[];
  onChange: (v: string[]) => void;
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
          aria-label={intl.formatMessage({ id: 'features.familyFind' })}
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
          <FormattedMessage id="features.familyNone" />
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

function ScopeText({ flag }: { flag: Flag }) {
  if (flag.scope === 'internal' && flag.families?.length)
    return <FormattedMessage id="impact.chosen" values={{ n: flag.families.length }} />;
  if (flag.scope === 'internal') return <FormattedMessage id="impact.internal" />;
  if (flag.scope === 'percent')
    return <FormattedMessage id="impact.percent" values={{ p: flag.percent }} />;
  return <FormattedMessage id="impact.all" />;
}

// ---------- Bật cho gia đình (several flags at once) ----------

/** Why a flag cannot take picked families: on for everyone already, or a percent rollout. */
export function bulkSkip(f: Flag): 'everyone' | 'percent' | null {
  if (f.enabled && f.scope === 'all') return 'everyone';
  if (f.scope === 'percent') return 'percent';
  return null;
}

/** The families each picked flag ends up with (the picked ones added to those it had). */
export function bulkPlan(
  flags: Flags,
  keys: readonly FlagKey[],
  families: readonly string[],
): Array<{ key: FlagKey; families: string[]; added: number }> {
  return keys
    .filter((k) => bulkSkip(flags[k]) === null)
    .map((k) => {
      const had = flags[k].scope === 'internal' ? (flags[k].families ?? []) : [];
      const all = [...new Set([...had, ...families])];
      return { key: k, families: all, added: all.length - had.length };
    });
}

/**
 * Adds families to several flags in one go (one `staffSetFlag` per flag, same reason, each in the
 * audit log). The switches stay as they are: a flag that is off keeps the list for later.
 */
export function BulkFamiliesDialog({
  flags,
  initial,
  onClose,
  onDone,
}: {
  flags: Flags;
  initial: BulkInit;
  onClose: () => void;
  onDone: () => void;
}) {
  const intl = useIntl();
  const api = useApi();
  const [families, setFamilies] = useState<string[]>(initial.families);
  const [keys, setKeys] = useState<FlagKey[]>(
    initial.keys.filter((k) => bulkSkip(flags[k]) === null),
  );
  const [reason, setReason] = useState('');
  const [progress, setProgress] = useState<number | null>(null);
  const [error, setError] = useState<{ key: FlagKey; error: ApiError } | null>(null);
  // Flags already changed by a run that then failed: closing refreshes the list behind.
  const [saved, setSaved] = useState(0);
  const close = () => (saved ? onDone() : onClose());
  const plan = bulkPlan(flags, keys, families);
  const tooMany = plan.find((p) => p.families.length > 50);
  const changes = plan.filter((p) => p.added > 0);
  const toggle = (k: FlagKey, on: boolean) =>
    setKeys((ks) => (on ? [...new Set([...ks, k])] : ks.filter((x) => x !== k)));
  const submit = async () => {
    setError(null);
    for (let i = 0; i < changes.length; i++) {
      const p = changes[i]!;
      const f = flags[p.key];
      setProgress(i);
      try {
        await api.call('staffSetFlag', {
          key: p.key,
          enabled: f.enabled,
          scope: 'internal',
          percent: 0,
          notice: f.enabled ? null : f.notice,
          families: p.families,
          reason: reason.trim(),
        });
      } catch (e) {
        // Steps already done stay done (each one is in the audit log).
        setError({ key: p.key, error: e instanceof ApiError ? e : new ApiError('unknown', null) });
        setProgress(null);
        setSaved((n) => n + i);
        return;
      }
    }
    setProgress(null);
    toast.success(
      intl.formatMessage(
        { id: 'features.bulk.done' },
        { n: changes.length, families: families.join(', ') },
      ),
    );
    onDone();
  };
  return (
    <Modal wide title={<FormattedMessage id="features.bulk.title" />} onClose={close}>
      <p className="text-sm text-muted-foreground">
        <FormattedMessage id="features.bulk.sub" />
      </p>
      <div className="grid gap-2">
        <span className="text-[13px] font-medium">
          <FormattedMessage id="features.bulk.families" />
        </span>
        <FamilyPicker value={families} onChange={setFamilies} />
      </div>
      <fieldset className="grid gap-3">
        <legend className="mb-2 flex w-full items-center text-[13px] font-medium">
          <FormattedMessage id="features.bulk.flags" />
          <span className="ml-auto text-xs font-normal text-muted-foreground tabular-nums">
            {keys.length}/{flagKeys.length}
          </span>
        </legend>
        <div className="grid gap-3 sm:grid-cols-2">
          {flagGroups.map((g) => {
            const usable = g.keys.filter((k) => bulkSkip(flags[k]) === null);
            const allOn = usable.length > 0 && usable.every((k) => keys.includes(k));
            return (
              <div key={g.id} className="grid content-start gap-1.5 rounded-lg border p-3">
                <label className="flex items-center gap-2 text-sm font-semibold">
                  <Checkbox
                    checked={allOn}
                    disabled={!usable.length}
                    onCheckedChange={(v) => usable.forEach((k) => toggle(k, v === true))}
                  />
                  <FormattedMessage id={`features.group.${g.id}`} />
                </label>
                {g.keys.map((k) => {
                  const skip = bulkSkip(flags[k]);
                  const had = families.length
                    ? families.every((c) => (flags[k].families ?? []).includes(c))
                    : false;
                  return (
                    <label
                      key={k}
                      className={cn(
                        'flex items-start gap-2 pl-6 text-sm',
                        skip && 'text-muted-foreground',
                      )}
                    >
                      <Checkbox
                        className="mt-0.5"
                        checked={keys.includes(k)}
                        disabled={!!skip}
                        onCheckedChange={(v) => toggle(k, v === true)}
                      />
                      <span className="min-w-0">
                        <FormattedMessage id={`flag.${k}`} />
                        {(skip || had || !flags[k].enabled) && (
                          <span className="block text-xs text-muted-foreground">
                            <FormattedMessage
                              id={
                                skip
                                  ? `features.bulk.skip.${skip}`
                                  : had
                                    ? 'features.bulk.already'
                                    : 'features.bulk.isOff'
                              }
                            />
                          </span>
                        )}
                      </span>
                    </label>
                  );
                })}
              </div>
            );
          })}
        </div>
      </fieldset>
      {tooMany && (
        <Notice tone="error">
          <FormattedMessage
            id="features.bulk.tooMany"
            values={{ flag: intl.formatMessage({ id: `flag.${tooMany.key}` }) }}
          />
        </Notice>
      )}
      <ReasonField value={reason} onChange={setReason} required />
      {error && (
        <Notice tone="error">
          <FormattedMessage
            id="features.bulk.failed"
            values={{ flag: intl.formatMessage({ id: `flag.${error.key}` }) }}
          />{' '}
          <FormattedMessage id={errorMessageId(error.error)} />
        </Notice>
      )}
      <div className="modal__actions">
        <span className="mr-auto self-center text-sm text-muted-foreground" role="status">
          {progress !== null ? (
            <FormattedMessage
              id="features.bulk.progress"
              values={{ n: progress + 1, total: changes.length }}
            />
          ) : families.length && keys.length ? (
            <FormattedMessage id="features.bulk.summary" values={{ n: changes.length }} />
          ) : null}
        </span>
        <Button onClick={close}>
          <FormattedMessage id="action.cancel" />
        </Button>
        <Button
          kind="primary"
          disabled={
            progress !== null ||
            !families.length ||
            !changes.length ||
            !!tooMany ||
            !reasonOk(reason)
          }
          onClick={() => void submit()}
        >
          <FormattedMessage id="features.bulk.confirm" values={{ n: changes.length }} />
        </Button>
      </div>
    </Modal>
  );
}

// ---------- Kiểm tra gia đình: what one family's app is told ----------

type Access = NonNullable<StaffFamilyPremium['access']>;

/** What a family sees in the app, by area: the flags it needs and the capabilities behind it. */
export const accessAreas: ReadonlyArray<{
  id: string;
  /** Needed for the area to show at all. */
  flags: readonly FlagKey[];
  /** Parts of the area (shown as "chưa bật: …" when off). */
  extras?: readonly FlagKey[];
  /** Premium capabilities the area opens (region + grant). */
  capabilities?: readonly Capability[];
}> = [
  {
    id: 'assistant',
    flags: ['assistant', 'assistant_live', 'assistant_writes'],
    extras: ['assistant_images', 'assistant_care', 'assistant_upsell'],
  },
  { id: 'rhythm', flags: ['rhythm'] },
  {
    id: 'personalization',
    flags: ['personalization'],
    capabilities: ['personalization.cross_module', 'rhythm.advanced'],
  },
  { id: 'aiAssist', flags: ['ai_assist'], capabilities: ['ai.assistance'] },
  { id: 'templates', flags: [], capabilities: ['templates.premium'] },
  { id: 'memories', flags: ['memory_story', 'milestone_cards'] },
  { id: 'billing', flags: ['premium_billing'] },
];

export type AreaCheck = {
  id: string;
  open: boolean;
  /** Flags the family still needs for the area. */
  missingFlags: FlagKey[];
  /** Optional parts not on for the family. */
  missingExtras: FlagKey[];
  /** The first reason a capability of the area is closed, when its flags are on. */
  reason: GateReason | null;
};

export function checkAreas(access: Access): AreaCheck[] {
  return accessAreas.map((a) => {
    const missingFlags = a.flags.filter((k) => !access.flags[k]);
    const missingExtras = (a.extras ?? []).filter((k) => !access.flags[k]);
    const closed = (a.capabilities ?? [])
      .map((c) => access.capabilities[c])
      .find((s) => !s.allowed);
    const reason = missingFlags.length ? 'FEATURE_DISABLED' : (closed?.reason ?? null);
    return { id: a.id, open: !reason, missingFlags, missingExtras, reason };
  });
}

/** "Kiểm tra gia đình": look a family up (code or email) and see what its app shows. */
export function FamilyCheck({
  flags,
  canEnable,
  onEnable,
}: {
  flags: Flags;
  canEnable: boolean;
  onEnable: (code: string, keys: FlagKey[]) => void;
}) {
  const intl = useIntl();
  const api = useApi();
  const [q, setQ] = useState('');
  const [busy, setBusy] = useState(false);
  const [problem, setProblem] = useState<string | null>(null);
  const [result, setResult] = useState<StaffFamilyPremium | null>(null);
  const look = async () => {
    if (!q.trim()) return;
    setBusy(true);
    setProblem(null);
    const r = await resolveFamilyCodes(api, q);
    if ('problem' in r) {
      setProblem(r.problem);
      setBusy(false);
      return;
    }
    try {
      setResult(await api.call<StaffFamilyPremium>('staffFamilyPremium', { code: r.codes[0] }));
    } catch (e) {
      setResult(null);
      setProblem(e instanceof ApiError ? errorMessageId(e) : 'error.generic');
    } finally {
      setBusy(false);
    }
  };
  return (
    <Section
      title={<FormattedMessage id="features.check.title" />}
      description={<FormattedMessage id="features.check.sub" />}
      actions={
        result && (
          <UiButton
            variant="ghost"
            size="sm"
            className="text-muted-foreground"
            onClick={() => {
              setResult(null);
              setQ('');
            }}
          >
            <X />
            <FormattedMessage id="features.check.clear" />
          </UiButton>
        )
      }
    >
      <div className="grid gap-4">
        <div className="flex max-w-xl gap-2">
          <Input
            value={q}
            onChange={(e) => setQ(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                e.preventDefault();
                void look();
              }
            }}
            placeholder={intl.formatMessage({ id: 'features.familyFind' })}
            aria-label={intl.formatMessage({ id: 'features.check.title' })}
          />
          <Button kind="primary" disabled={busy || !q.trim()} onClick={() => void look()}>
            <FormattedMessage id="features.check.go" />
          </Button>
        </div>
        {problem && (
          <p className="text-sm text-destructive" role="alert">
            <FormattedMessage id={problem} />
          </p>
        )}
        {result && (
          <FamilyAccessCard
            family={result}
            flags={flags}
            canEnable={canEnable}
            onEnable={(keys) => onEnable(result.code, keys)}
          />
        )}
      </div>
    </Section>
  );
}

/**
 * One family's view of the app: country and plan on top, then each area open or closed with the
 * reason and the fix (turn the flags on for it, open its country, add it to a campaign).
 */
export function FamilyAccessCard({
  family,
  flags,
  canEnable,
  onEnable,
  regionAction,
  premiumAction,
  showHeader = true,
}: {
  family: StaffFamilyPremium;
  /** All flags, to tell "off for everyone" from "not on for this family". */
  flags: Flags;
  canEnable: boolean;
  onEnable: (keys: FlagKey[]) => void;
  /** Where the region can be opened (Premium › Cấu hình); a link on other screens. */
  regionAction?: ReactNode;
  premiumAction?: ReactNode;
  /** Off where the family's code, plan and country are already shown above. */
  showHeader?: boolean;
}) {
  const intl = useIntl();
  const navigate = useNavigate();
  const access = family.access;
  if (!access) return null;
  const areas = checkAreas(access);
  const country = family.country
    ? `${regionName(intl.locale, family.country)} · ${family.country}`
    : null;
  // Only flags that are on can be opened to one more family; a switch off for everyone is
  // turned on in the table, on purpose.
  const canAdd = (k: FlagKey) => bulkSkip(flags[k]) === null && flags[k].enabled;
  const allMissing = [...new Set(areas.flatMap((a) => [...a.missingFlags, ...a.missingExtras]))];
  const enableable = allMissing.filter(canAdd);
  return (
    <div className="grid gap-3 rounded-lg border bg-background p-4">
      <div className="flex flex-wrap items-center gap-x-4 gap-y-2 text-sm">
        {showHeader && (
          <>
            <span className="font-mono font-semibold">{family.code}</span>
            <span>
              <span className="text-muted-foreground">
                <FormattedMessage id="premium.lookup.plan" />:
              </span>{' '}
              <FormattedMessage id={`premium.plan.${family.plan}`} />
            </span>
            <span className={cn(!access.regionSupported && 'text-destructive')}>
              <span className="text-muted-foreground">
                <FormattedMessage id="premium.lookup.country" />:
              </span>{' '}
              {country ?? <FormattedMessage id="premium.lookup.noCountry" />}
              {!access.regionSupported && (
                <>
                  {' '}
                  (<FormattedMessage id="features.check.regionClosed" />)
                </>
              )}
            </span>
          </>
        )}
        {access.internal && (
          <Badge variant="outline">
            <FormattedMessage id="features.check.internal" />
          </Badge>
        )}
        {canEnable && enableable.length > 0 && (
          <UiButton size="sm" className="ml-auto" onClick={() => onEnable(enableable)}>
            <Users />
            <FormattedMessage id="features.check.enableAll" values={{ n: enableable.length }} />
          </UiButton>
        )}
      </div>
      {!access.regionSupported && (
        <Notice tone="warn" action={regionAction}>
          <FormattedMessage
            id={family.country ? 'features.check.regionFix' : 'features.check.countryFix'}
            values={{ country: country ?? '' }}
          />
        </Notice>
      )}
      <ul className="grid gap-1.5">
        {areas.map((a) => {
          const offForAll = a.missingFlags.filter((k) => !flags[k].enabled);
          return (
            <li
              key={a.id}
              className="grid grid-cols-[1.25rem_minmax(0,1fr)_auto] items-start gap-2 rounded-md px-1 py-1.5 text-sm"
            >
              {a.open ? (
                <CircleCheck className="mt-0.5 size-4 text-success" aria-hidden="true" />
              ) : (
                <CircleSlash className="mt-0.5 size-4 text-muted-foreground" aria-hidden="true" />
              )}
              <span className="min-w-0">
                <span className="font-medium">
                  <FormattedMessage id={`features.area.${a.id}`} />
                </span>{' '}
                <span className="text-muted-foreground">
                  ·{' '}
                  {a.open ? (
                    <FormattedMessage id="features.check.open" />
                  ) : a.reason === 'FEATURE_DISABLED' ? (
                    <FormattedMessage
                      id={offForAll.length ? 'features.check.offForAll' : 'features.check.flagOff'}
                      values={{
                        flags: (offForAll.length ? offForAll : a.missingFlags)
                          .map((k) => intl.formatMessage({ id: `flag.${k}` }))
                          .join(', '),
                      }}
                    />
                  ) : (
                    <FormattedMessage id={`features.check.reason.${a.reason}`} />
                  )}
                </span>
                {a.open && a.missingExtras.length > 0 && (
                  <span className="block text-xs text-muted-foreground">
                    <FormattedMessage
                      id="features.check.extras"
                      values={{
                        flags: a.missingExtras
                          .map((k) => intl.formatMessage({ id: `flag.${k}` }))
                          .join(', '),
                      }}
                    />
                  </span>
                )}
              </span>
              <span className="flex shrink-0 gap-1">
                {canEnable && [...a.missingFlags, ...a.missingExtras].some(canAdd) && (
                  <UiButton
                    variant="ghost"
                    size="sm"
                    className="h-7 text-primary"
                    onClick={() => onEnable([...a.missingFlags, ...a.missingExtras].filter(canAdd))}
                  >
                    <Check />
                    <FormattedMessage id="features.check.enable" />
                  </UiButton>
                )}
                {a.reason === 'PREMIUM_REQUIRED' &&
                  (premiumAction ?? (
                    <UiButton
                      variant="ghost"
                      size="sm"
                      className="h-7 text-primary"
                      onClick={() => navigate('premium')}
                    >
                      <FormattedMessage id="features.check.toPremium" />
                    </UiButton>
                  ))}
              </span>
            </li>
          );
        })}
      </ul>
    </div>
  );
}

function regionName(locale: string, code: string): string {
  try {
    return new Intl.DisplayNames([locale], { type: 'region', fallback: 'none' }).of(code) ?? code;
  } catch {
    return code;
  }
}
