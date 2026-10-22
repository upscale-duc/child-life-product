import {
  engagementPolicySchema,
  inboxGroups,
  staffCan,
  type EngagementPolicy,
  type InboxGroup,
  type NotificationOpsConfig,
  type NotificationOpsResponse,
} from '@child-life/contracts';
import { useId, useMemo, useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { ApiError, useApi, type Load } from '../../api';
import { Field, Notice, Section, useConfirm } from '../../content-kit';
import { useNavigate, useStaff } from '../../context';
import { Button } from '../../ui';
import { LoadedSkeleton, PageSkeleton, StatusDot, TabHeader } from './kit';
import { ErrorLine } from './shared';

export function SettingsTab({
  load,
  reload,
}: {
  load: Load<NotificationOpsResponse> | null;
  reload: () => void;
}) {
  if (!load) return <PageSkeleton />;
  return (
    <LoadedSkeleton load={load} reload={reload}>
      {(data) => <SettingsView data={data} onSaved={reload} />}
    </LoadedSkeleton>
  );
}

const sameOps = (a: NotificationOpsConfig, b: NotificationOpsConfig) =>
  a.templatesEnabled === b.templatesEnabled &&
  a.retryEnabled === b.retryEnabled &&
  inboxGroups.every((g) => a.pushPaused[g] === b.pushPaused[g]);

function SwitchRow({
  label,
  note,
  checked,
  disabled,
  onChange,
  warn,
}: {
  label: ReactNode;
  note: ReactNode;
  checked: boolean;
  disabled: boolean;
  onChange: (v: boolean) => void;
  warn?: boolean;
}) {
  const id = useId();
  return (
    <li className="flex items-start justify-between gap-4 border-b py-3 last:border-b-0">
      <div className="grid gap-0.5">
        <Label htmlFor={id} className={warn ? 'text-destructive' : undefined}>
          {label}
        </Label>
        <span className="text-[13px] text-muted-foreground">{note}</span>
      </div>
      <div className="flex shrink-0 items-center gap-2">
        <span className="text-[13px] text-muted-foreground" aria-hidden="true">
          <FormattedMessage id={checked ? 'ntf.on' : 'ntf.off'} />
        </span>
        <Switch id={id} checked={checked} disabled={disabled} onCheckedChange={onChange} />
      </div>
    </li>
  );
}

// ---------- Smart Engagement policy (D-092) ----------

type NumberField =
  | 'dailyCap'
  | 'weeklyCap'
  | 'reducedDismissals'
  | 'pausedDismissals'
  | 'ignoredThreshold'
  | 'completionQuietHours'
  | 'spacingMinutes'
  | 'deviceLeaseDays';

/** Bounds mirror `engagementPolicySchema` (the server validates the same schema). */
export const policyFields: Array<{
  key: NumberField;
  min: number;
  max: number;
  unit: 'count' | 'hours' | 'minutes' | 'days';
}> = [
  { key: 'dailyCap', min: 1, max: 1, unit: 'count' },
  { key: 'weeklyCap', min: 1, max: 3, unit: 'count' },
  { key: 'spacingMinutes', min: 60, max: 240, unit: 'minutes' },
  { key: 'completionQuietHours', min: 48, max: 168, unit: 'hours' },
  { key: 'reducedDismissals', min: 2, max: 10, unit: 'count' },
  { key: 'pausedDismissals', min: 3, max: 20, unit: 'count' },
  { key: 'ignoredThreshold', min: 3, max: 20, unit: 'count' },
  { key: 'deviceLeaseDays', min: 1, max: 60, unit: 'days' },
];

export type PolicyChange = { field: string; before: string; after: string };

/** What a save changes, field by field (shown in the confirmation). */
export function policyDiff(before: EngagementPolicy, after: EngagementPolicy): PolicyChange[] {
  const out: PolicyChange[] = [];
  if (before.approved !== after.approved)
    out.push({ field: 'approved', before: String(before.approved), after: String(after.approved) });
  for (const f of policyFields)
    if (before[f.key] !== after[f.key])
      out.push({ field: f.key, before: String(before[f.key]), after: String(after[f.key]) });
  for (const k of ['from', 'to'] as const)
    if (before.quietDefault[k] !== after.quietDefault[k])
      out.push({
        field: `quiet.${k}`,
        before: before.quietDefault[k],
        after: after.quietDefault[k],
      });
  return out;
}

/** Field keys with an invalid value (bounds, whole numbers, HH:mm). */
export function policyErrors(policy: EngagementPolicy): Set<string> {
  const res = engagementPolicySchema.safeParse(policy);
  if (res.success) return new Set();
  return new Set(
    res.error.issues.map((i) =>
      i.path[0] === 'quietDefault' ? `quiet.${String(i.path[1])}` : String(i.path[0]),
    ),
  );
}

function PolicyPanel({
  data,
  canOps,
  onSaved,
}: {
  data: NotificationOpsResponse;
  canOps: boolean;
  onSaved: (next: NotificationOpsResponse) => void;
}) {
  const intl = useIntl();
  const api = useApi();
  const ids = useId();
  const { ask, dialog } = useConfirm();
  const [draft, setDraft] = useState<EngagementPolicy>(data.engagementPolicy);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const [done, setDone] = useState(false);
  const changes = useMemo(() => policyDiff(data.engagementPolicy, draft), [data, draft]);
  const errors = useMemo(() => policyErrors(draft), [draft]);
  const fieldName = (f: string) =>
    f.startsWith('quiet.')
      ? `${intl.formatMessage({ id: 'ntf.policy.quiet' })} · ${intl.formatMessage({ id: `ntf.policy.${f}` })}`
      : intl.formatMessage({ id: `ntf.policy.${f}` });
  const shown = (field: string, v: string) =>
    field === 'approved' ? intl.formatMessage({ id: v === 'true' ? 'ntf.on' : 'ntf.off' }) : v;
  const save = async () => {
    setBusy(true);
    setError(null);
    setDone(false);
    try {
      const next = await api.call<NotificationOpsResponse>('staffSetEngagementPolicy', {
        policy: draft,
      });
      setDraft(next.engagementPolicy);
      setDone(true);
      onSaved(next);
    } catch (e) {
      setError(e instanceof ApiError ? e : new ApiError('unknown', null));
    } finally {
      setBusy(false);
    }
  };
  const turningOff = data.engagementPolicy.approved && !draft.approved;
  const turningOn = !data.engagementPolicy.approved && draft.approved;
  const confirm = () =>
    ask({
      title: intl.formatMessage({ id: 'ntf.policy.confirm.title' }),
      body: (
        <span className="grid gap-2">
          {turningOff && (
            <strong className="text-destructive">
              <FormattedMessage id="ntf.policy.confirm.off" />
            </strong>
          )}
          {turningOn && (
            <strong>
              <FormattedMessage id="ntf.policy.confirm.on" />
            </strong>
          )}
          <span className="grid gap-1">
            {changes.map((c) => (
              <span key={c.field} className="flex flex-wrap gap-x-2">
                <span className="text-foreground">{fieldName(c.field)}:</span>
                <span className="line-through">{shown(c.field, c.before)}</span>
                <span aria-hidden="true">→</span>
                <span className="sr-only">
                  <FormattedMessage id="ntf.policy.to" />
                </span>
                <span className="font-medium text-foreground">{shown(c.field, c.after)}</span>
              </span>
            ))}
          </span>
        </span>
      ),
      confirmLabel: intl.formatMessage({ id: 'ntf.policy.save' }),
      destructive: turningOff,
      onConfirm: () => void save(),
    });
  const disabled = !canOps || busy;
  return (
    <Section
      title={<FormattedMessage id="ntf.policy.title" />}
      description={<FormattedMessage id="ntf.policy.note" />}
      actions={
        canOps && (
          <>
            {changes.length > 0 && (
              <Button disabled={busy} onClick={() => setDraft(data.engagementPolicy)}>
                <FormattedMessage id="action.cancel" />
              </Button>
            )}
            <Button
              kind="primary"
              disabled={busy || changes.length === 0 || errors.size > 0}
              onClick={confirm}
            >
              <FormattedMessage id="ntf.policy.save" />
            </Button>
          </>
        )
      }
    >
      <div className="grid gap-4">
        {!data.engagementPolicyStored && (
          <Notice tone="warn" title={<FormattedMessage id="ntf.policy.notStored.title" />}>
            <FormattedMessage id="ntf.policy.notStored" />
          </Notice>
        )}
        <ErrorLine error={error} />
        {done && changes.length === 0 && (
          <Notice tone="ok">
            <FormattedMessage id="ntf.policy.saved" />
          </Notice>
        )}
        <ul>
          <SwitchRow
            label={<FormattedMessage id="ntf.policy.approved" />}
            note={<FormattedMessage id="ntf.policy.approved.note" />}
            checked={draft.approved}
            disabled={disabled}
            warn={!draft.approved}
            onChange={(approved) => setDraft((d) => ({ ...d, approved }))}
          />
        </ul>
        <div className="grid gap-4 sm:grid-cols-2">
          {policyFields.map((f) => {
            const id = `${ids}-${f.key}`;
            const value = draft[f.key];
            const fixed = f.min === f.max;
            return (
              <Field
                key={f.key}
                htmlFor={id}
                label={<FormattedMessage id={`ntf.policy.${f.key}`} />}
                help={
                  <span className="grid">
                    <span>
                      <FormattedMessage id={`ntf.policy.${f.key}.note`} />
                    </span>
                    <span>
                      <FormattedMessage
                        id={fixed ? 'ntf.policy.fixed' : 'ntf.policy.range'}
                        values={{
                          min: f.min,
                          max: f.max,
                          unit: intl.formatMessage({ id: `ntf.policy.unit.${f.unit}` }),
                        }}
                      />
                    </span>
                  </span>
                }
                error={
                  errors.has(f.key) ? (
                    <FormattedMessage
                      id="ntf.policy.outOfRange"
                      values={{ min: f.min, max: f.max }}
                    />
                  ) : undefined
                }
              >
                <div className="flex items-center gap-2">
                  <Input
                    id={id}
                    type="number"
                    inputMode="numeric"
                    className="w-28 tabular-nums"
                    min={f.min}
                    max={f.max}
                    step={1}
                    value={Number.isNaN(value) ? '' : value}
                    readOnly={fixed}
                    disabled={disabled}
                    aria-invalid={errors.has(f.key) || undefined}
                    onChange={(e) =>
                      setDraft((d) => ({
                        ...d,
                        [f.key]: e.target.value === '' ? NaN : Number(e.target.value),
                      }))
                    }
                  />
                  <span className="text-[13px] text-muted-foreground">
                    <FormattedMessage id={`ntf.policy.unit.${f.unit}`} />
                  </span>
                </div>
              </Field>
            );
          })}
          <Field
            label={<FormattedMessage id="ntf.policy.quiet" />}
            help={<FormattedMessage id="ntf.policy.quiet.note" />}
            error={
              errors.has('quiet.from') || errors.has('quiet.to') ? (
                <FormattedMessage id="ntf.policy.badTime" />
              ) : undefined
            }
          >
            <div className="flex flex-wrap items-center gap-2">
              {(['from', 'to'] as const).map((k) => (
                <label key={k} className="flex items-center gap-1.5 text-[13px]">
                  <FormattedMessage id={`ntf.policy.quiet.${k}`} />
                  <Input
                    type="time"
                    className="w-28"
                    value={draft.quietDefault[k]}
                    disabled={disabled}
                    onChange={(e) =>
                      setDraft((d) => ({
                        ...d,
                        quietDefault: { ...d.quietDefault, [k]: e.target.value },
                      }))
                    }
                  />
                </label>
              ))}
            </div>
          </Field>
        </div>
      </div>
      {dialog}
    </Section>
  );
}

/**
 * Cài đặt: the operational switches (`config/notifications`) and the Smart Engagement policy
 * (D-092). Anyone with notifications.view sees them; changing them needs notifications.ops, and
 * the server audits every save. Per-scenario flags stay in Tính năng & Premium.
 */
export function SettingsView({
  data,
  onSaved,
}: {
  data: NotificationOpsResponse;
  onSaved?: () => void;
}) {
  const intl = useIntl();
  const api = useApi();
  const staff = useStaff();
  const navigate = useNavigate();
  const canOps = staffCan(staff.levels, 'notifications.ops');
  const [current, setCurrent] = useState(data);
  const saved = current.ops;
  const [draft, setDraft] = useState(data.ops);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const [done, setDone] = useState(false);
  const { ask, dialog } = useConfirm();
  const changed = !sameOps(draft, saved);
  const setPaused = (g: InboxGroup, paused: boolean) =>
    setDraft((d) => ({ ...d, pushPaused: { ...d.pushPaused, [g]: paused } }));
  const save = async () => {
    setBusy(true);
    setError(null);
    setDone(false);
    try {
      const res = await api.call<{ ops: NotificationOpsConfig }>('staffSetNotificationOps', {
        config: draft,
      });
      setCurrent((c) => ({ ...c, ops: res.ops }));
      setDraft(res.ops);
      setDone(true);
      onSaved?.();
    } catch (e) {
      setError(e instanceof ApiError ? e : new ApiError('unknown', null));
    } finally {
      setBusy(false);
    }
  };
  const careTurningOff = draft.pushPaused.care && !saved.pushPaused.care;
  return (
    <div className="stack">
      <TabHeader
        title={<FormattedMessage id="ntf.tab.settings" />}
        purpose={<FormattedMessage id="ntf.purpose.settings" />}
      />
      {!canOps && (
        <Notice>
          <FormattedMessage id="ntf.settings.readOnly" />
        </Notice>
      )}
      {draft.pushPaused.care && (
        <Notice tone="error" title={<FormattedMessage id="ntf.settings.careWarn.title" />}>
          <FormattedMessage id="ntf.settings.careWarn" />
        </Notice>
      )}
      <ErrorLine error={error} />
      {done && !changed && (
        <Notice tone="ok">
          <FormattedMessage id="ntf.settings.saved" />
        </Notice>
      )}
      <Section
        title={<FormattedMessage id="ntf.settings.ops" />}
        description={<FormattedMessage id="ntf.settings.opsNote" />}
        actions={
          canOps && (
            <>
              {changed && (
                <Button disabled={busy} onClick={() => setDraft(saved)}>
                  <FormattedMessage id="action.cancel" />
                </Button>
              )}
              <Button
                kind="primary"
                disabled={!changed || busy}
                onClick={() =>
                  ask({
                    title: intl.formatMessage({ id: 'ntf.settings.confirm.title' }),
                    body: intl.formatMessage({
                      id: careTurningOff
                        ? 'ntf.settings.confirm.care'
                        : 'ntf.settings.confirm.body',
                    }),
                    confirmLabel: intl.formatMessage({ id: 'ntf.settings.save' }),
                    destructive: careTurningOff,
                    onConfirm: () => void save(),
                  })
                }
              >
                <FormattedMessage id="ntf.settings.save" />
              </Button>
            </>
          )
        }
      >
        <h3 className="mt-1 text-[13px] font-semibold text-muted-foreground uppercase">
          <FormattedMessage id="ntf.settings.content" />
        </h3>
        <ul>
          <SwitchRow
            label={<FormattedMessage id="ntf.ops.templatesEnabled" />}
            note={<FormattedMessage id="ntf.ops.templatesEnabled.note" />}
            checked={draft.templatesEnabled}
            disabled={!canOps || busy}
            onChange={(v) => setDraft((d) => ({ ...d, templatesEnabled: v }))}
          />
          <SwitchRow
            label={<FormattedMessage id="ntf.ops.retryEnabled" />}
            note={<FormattedMessage id="ntf.ops.retryEnabled.note" />}
            checked={draft.retryEnabled}
            disabled={!canOps || busy}
            onChange={(v) => setDraft((d) => ({ ...d, retryEnabled: v }))}
          />
        </ul>
        <h3 className="mt-4 text-[13px] font-semibold text-muted-foreground uppercase">
          <FormattedMessage id="ntf.settings.push" />
        </h3>
        <p className="text-[13px] text-muted-foreground">
          <FormattedMessage id="ntf.settings.pushNote" />
        </p>
        <ul>
          {inboxGroups.map((g) => (
            <SwitchRow
              key={g}
              label={
                <FormattedMessage
                  id="ntf.ops.pushFor"
                  values={{ name: intl.formatMessage({ id: `ntf.group.${g}` }) }}
                />
              }
              note={
                <FormattedMessage id={g === 'care' ? 'ntf.ops.care.note' : 'ntf.ops.group.note'} />
              }
              checked={!draft.pushPaused[g]}
              disabled={!canOps || busy}
              warn={g === 'care'}
              onChange={(sending) => setPaused(g, !sending)}
            />
          ))}
        </ul>
      </Section>
      <PolicyPanel
        data={current}
        canOps={canOps}
        onSaved={(next) => {
          setCurrent(next);
          onSaved?.();
        }}
      />
      <Notice
        title={<FormattedMessage id="ntf.settings.flags.title" />}
        action={
          staffCan(staff.levels, 'features.view') ? (
            <Button onClick={() => navigate('features')}>
              <FormattedMessage id="ntf.settings.flags.open" />
            </Button>
          ) : undefined
        }
      >
        <FormattedMessage id="ntf.settings.flags" />
      </Notice>
      <p className="text-[12px] text-muted-foreground">
        <StatusDot
          tone={current.engagementPolicyStored && current.engagementPolicy.approved ? 'ok' : 'warn'}
        >
          <FormattedMessage
            id={
              current.engagementPolicyStored && current.engagementPolicy.approved
                ? 'ntf.policy.state.on'
                : 'ntf.policy.state.off'
            }
          />
        </StatusDot>
      </p>
      {dialog}
    </div>
  );
}
