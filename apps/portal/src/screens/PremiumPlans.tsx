import {
  adjustmentApprovalThreshold,
  lumiTasks,
  premiumPlansSchema,
  staffCan,
  type PremiumPlans,
  type StaffProposal,
} from '@child-life/contracts';
import { useEffect, useId, useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { toast } from 'sonner';
import { Input } from '@/components/ui/input';
import { ApiError, useApi, useLoad, type StaffPremiumConfig } from '../api';
import { EmptyState, Field, Notice, Section } from '../content-kit';
import { useStaff } from '../context';
import {
  Button,
  ConfirmModal,
  Loaded,
  Pill,
  TableScroll,
  errorMessageId,
  type PillTone,
} from '../ui';
import { FieldSelect } from './form-controls';

/**
 * Premium v2 on the portal (Figma 958:13863, D-101): PT03 plans & limits as a version that runs
 * only once a second person approves it, the proposals waiting (plans and large adjustments),
 * PT02 the manual adjustment of a family's current allowance and PT04 the refund of a video's
 * lượt. The two-person rule follows the D-079 switch; no reason is asked (D-090).
 */

const asApiError = (e: unknown) => (e instanceof ApiError ? e : new ApiError('unknown', null));

const money = (locale: string, v: number, currency: 'VND' | 'USD') =>
  new Intl.NumberFormat(locale, { style: 'currency', currency, maximumFractionDigits: 2 }).format(
    v,
  );

/** The rows of PT03 "Gói & hạn mức" with Free | Premium values, as text. */
function planRows(plans: PremiumPlans, locale: string, t: (id: string, v?: object) => string) {
  const addOns = plans.storageAddOns.map((a) => `${a.gb}`).join(' / ') || '—';
  return [
    {
      key: 'lumiCredits',
      free: t('pv2.plans.lumiFree', { n: plans.free.lumiCreditsOneTime }),
      premium: t('pv2.plans.lumiPremium', { n: plans.premium.lumiCreditsPerCycle }),
    },
    {
      key: 'videoExports',
      free: t('pv2.plans.videoFree'),
      premium: t('pv2.plans.videoPremium'),
    },
    {
      key: 'storageGB',
      free: String(plans.free.storageGB),
      premium: t('pv2.plans.storagePremium', { n: plans.premium.storageGB, addOns }),
    },
    {
      key: 'caregiverSeats',
      free: String(plans.free.caregiverSeats),
      premium: String(plans.premium.caregiverSeats),
    },
    { key: 'premiumTemplates', free: t('pv2.plans.no'), premium: t('pv2.plans.yes') },
    {
      key: 'priceVn',
      free: '0',
      premium: `${money(locale, plans.premium.price.vn.month, 'VND')} / ${money(locale, plans.premium.price.vn.year, 'VND')}`,
    },
    {
      key: 'priceIntl',
      free: '0',
      premium: `${money(locale, plans.premium.price.intl.month, 'USD')} / ${money(locale, plans.premium.price.intl.year, 'USD')}`,
    },
    { key: 'creditTopUps', free: t('pv2.plans.no'), premium: t('pv2.plans.no') },
  ];
}

/** Leaf paths whose values differ ("premium.storageGB: 10 → 20"). */
export function planChanges(a: PremiumPlans, b: PremiumPlans): string[] {
  const out: string[] = [];
  const walk = (x: unknown, y: unknown, path: string) => {
    if (x !== null && typeof x === 'object' && y !== null && typeof y === 'object') {
      for (const k of new Set([...Object.keys(x), ...Object.keys(y)])) {
        walk(
          (x as Record<string, unknown>)[k],
          (y as Record<string, unknown>)[k],
          path ? `${path}.${k}` : k,
        );
      }
    } else if (JSON.stringify(x) !== JSON.stringify(y)) {
      out.push(`${path}: ${JSON.stringify(x)} → ${JSON.stringify(y)}`);
    }
  };
  walk(a, b, '');
  return out;
}

function PlansTable({ plans }: { plans: PremiumPlans }) {
  const intl = useIntl();
  const t = (id: string, v?: object) => intl.formatMessage({ id }, v as never);
  return (
    <TableScroll min={560}>
      <table className="table">
        <thead>
          <tr>
            <th>
              <FormattedMessage id="pv2.plans.key" />
            </th>
            <th>
              <FormattedMessage id="pv2.plans.free" />
            </th>
            <th>
              <FormattedMessage id="pv2.plans.premium" />
            </th>
          </tr>
        </thead>
        <tbody>
          {planRows(plans, intl.locale, t).map((r) => (
            <tr key={r.key}>
              <td>
                <FormattedMessage id={`pv2.plans.${r.key}`} />
              </td>
              <td className="tabular-nums">{r.free}</td>
              <td className="tabular-nums">{r.premium}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </TableScroll>
  );
}

function IntField({
  label,
  value,
  onChange,
  min = 0,
  step = 1,
}: {
  label: ReactNode;
  value: number;
  onChange: (v: number) => void;
  min?: number;
  step?: number;
}) {
  const id = useId();
  return (
    <Field label={label} htmlFor={id}>
      <Input
        id={id}
        type="number"
        min={min}
        step={step}
        className="tabular-nums"
        value={value}
        onChange={(e) => {
          const n = Number(e.target.value);
          onChange(Number.isFinite(n) ? (step === 1 ? Math.round(n) : n) : 0);
        }}
      />
    </Field>
  );
}

/** The values a version changes; prices and add-ons too (PV00), every one editable. */
function PlansEditor({
  plans,
  onChange,
}: {
  plans: PremiumPlans;
  onChange: (p: PremiumPlans) => void;
}) {
  const set = (fn: (p: PremiumPlans) => void) => {
    const next = structuredClone(plans);
    fn(next);
    onChange(next);
  };
  const f = (id: string) => <FormattedMessage id={id} />;
  return (
    <div className="grid gap-4">
      <div className="grid gap-4 sm:grid-cols-2">
        <IntField
          label={<>{f('pv2.plans.lumiCredits')} · Free</>}
          value={plans.free.lumiCreditsOneTime}
          onChange={(v) => set((p) => void (p.free.lumiCreditsOneTime = v))}
        />
        <IntField
          label={<>{f('pv2.plans.lumiCredits')} · Premium</>}
          value={plans.premium.lumiCreditsPerCycle}
          onChange={(v) => set((p) => void (p.premium.lumiCreditsPerCycle = v))}
        />
        <IntField
          label={<>{f('pv2.plans.storageGB')} · Free</>}
          step={0.5}
          value={plans.free.storageGB}
          onChange={(v) => set((p) => void (p.free.storageGB = v))}
        />
        <IntField
          label={<>{f('pv2.plans.storageGB')} · Premium</>}
          step={0.5}
          value={plans.premium.storageGB}
          onChange={(v) => set((p) => void (p.premium.storageGB = v))}
        />
        <IntField
          label={<>{f('pv2.plans.caregiverSeats')} · Free</>}
          min={1}
          value={plans.free.caregiverSeats}
          onChange={(v) => set((p) => void (p.free.caregiverSeats = v))}
        />
        <IntField
          label={<>{f('pv2.plans.caregiverSeats')} · Premium</>}
          min={1}
          value={plans.premium.caregiverSeats}
          onChange={(v) => set((p) => void (p.premium.caregiverSeats = v))}
        />
        <IntField
          label={<>{f('pv2.plans.priceVn')} · 1</>}
          value={plans.premium.price.vn.month}
          onChange={(v) => set((p) => void (p.premium.price.vn.month = v))}
        />
        <IntField
          label={<>{f('pv2.plans.priceVn')} · 12</>}
          value={plans.premium.price.vn.year}
          onChange={(v) => set((p) => void (p.premium.price.vn.year = v))}
        />
        <IntField
          label={<>{f('pv2.plans.priceIntl')} · 1</>}
          step={0.01}
          value={plans.premium.price.intl.month}
          onChange={(v) => set((p) => void (p.premium.price.intl.month = v))}
        />
        <IntField
          label={<>{f('pv2.plans.priceIntl')} · 12</>}
          step={0.01}
          value={plans.premium.price.intl.year}
          onChange={(v) => set((p) => void (p.premium.price.intl.year = v))}
        />
      </div>
      <div className="grid gap-4 sm:grid-cols-3">
        {lumiTasks.map((task) => (
          <IntField
            key={task}
            label={<FormattedMessage id={`pv2.task.${task}`} />}
            value={plans.taskCosts[task] ?? 0}
            onChange={(v) => set((p) => void (p.taskCosts[task] = v))}
          />
        ))}
      </div>
    </div>
  );
}

/** PT03 with the proposals waiting; part of Tính năng & Premium › Gói Premium. */
export function PlansVersionSection({
  config,
  onChanged,
}: {
  config: StaffPremiumConfig;
  onChanged: () => void;
}) {
  const intl = useIntl();
  const api = useApi();
  const staff = useStaff();
  const canConfig = staffCan(staff.levels, 'premium.config');
  const [proposals, reloadProposals] = useLoad<StaffProposal[]>(
    'staffPremiumProposals',
    {},
    'premium-proposals',
  );
  const [draft, setDraft] = useState<PremiumPlans | null>(null);
  const [version, setVersion] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const versionId = useId();
  const running = config.plansVersion;
  const send = async () => {
    if (!draft) return;
    const name = version.trim();
    if (name === running) {
      setError(new ApiError('invalid-argument', 'same-version'));
      return;
    }
    const check = premiumPlansSchema.safeParse(draft);
    if (!check.success) {
      setError(new ApiError('invalid-argument', 'malformed'));
      return;
    }
    setBusy(true);
    setError(null);
    try {
      await api.call('staffProposePlans', { version: name, plans: check.data });
      toast.success(intl.formatMessage({ id: 'pv2.plans.submitted' }, { version: name }));
      setDraft(null);
      setVersion('');
      reloadProposals();
    } catch (e) {
      setError(asApiError(e));
    } finally {
      setBusy(false);
    }
  };
  return (
    <div className="grid gap-4">
      <Section
        title={<FormattedMessage id="pv2.plans.title" />}
        description={<FormattedMessage id="pv2.plans.note" />}
        actions={
          <span className="flex items-center gap-2">
            <Pill tone="ok">
              <FormattedMessage id="pv2.plans.running" values={{ version: running }} />
            </Pill>
            {canConfig && !draft && (
              <Button onClick={() => setDraft(structuredClone(config.plans))}>
                <FormattedMessage id="pv2.plans.edit" />
              </Button>
            )}
          </span>
        }
      >
        {draft ? (
          <div className="grid gap-4">
            <Field label={<FormattedMessage id="pv2.plans.version" />} htmlFor={versionId}>
              <Input
                id={versionId}
                value={version}
                maxLength={40}
                placeholder="2.1"
                onChange={(e) => setVersion(e.target.value)}
              />
            </Field>
            <PlansEditor plans={draft} onChange={setDraft} />
            {error && (
              <Notice tone="error">
                <FormattedMessage
                  id={
                    error.reason === 'same-version'
                      ? 'pv2.plans.sameVersion'
                      : errorMessageId(error)
                  }
                />
              </Notice>
            )}
            <div className="flex flex-wrap gap-2">
              <Button
                kind="primary"
                disabled={busy || !/^[0-9A-Za-z][0-9A-Za-z.-]{0,39}$/.test(version.trim())}
                onClick={() => void send()}
              >
                <FormattedMessage id="pv2.plans.submit" />
              </Button>
              <Button onClick={() => setDraft(null)}>
                <FormattedMessage id="pv2.plans.cancel" />
              </Button>
            </div>
          </div>
        ) : (
          <div className="grid gap-4">
            <PlansTable plans={config.plans} />
            <div>
              <h4 className="mb-2 text-sm font-medium">
                <FormattedMessage id="pv2.plans.taskCosts" />
              </h4>
              <ul className="grid gap-1 text-sm sm:grid-cols-2">
                {lumiTasks.map((task) => (
                  <li key={task} className="flex justify-between gap-4">
                    <FormattedMessage id={`pv2.task.${task}`} />
                    <span className="tabular-nums">{config.plans.taskCosts[task] ?? 0}</span>
                  </li>
                ))}
              </ul>
              <p className="mt-2 text-xs text-muted-foreground">
                <FormattedMessage id="pv2.plans.taskCostsNote" />
              </p>
            </div>
          </div>
        )}
      </Section>
      <Loaded load={proposals} reload={reloadProposals}>
        {(list) => (
          <ProposalsList
            list={list}
            current={config.plans}
            onChanged={() => {
              reloadProposals();
              onChanged();
            }}
          />
        )}
      </Loaded>
    </div>
  );
}

const statusTone: Record<StaffProposal['status'], PillTone> = {
  pending: 'warn',
  approved: 'ok',
  rejected: 'muted',
};

export function ProposalsList({
  list,
  current,
  onChanged,
}: {
  list: StaffProposal[];
  current: PremiumPlans;
  onChanged: () => void;
}) {
  const intl = useIntl();
  const api = useApi();
  const staff = useStaff();
  const [deciding, setDeciding] = useState<{ p: StaffProposal; approve: boolean } | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const pending = list.filter((p) => p.status === 'pending');
  const recent = list.filter((p) => p.status !== 'pending').slice(0, 5);
  const canDecide = (p: StaffProposal) =>
    staffCan(staff.levels, p.kind === 'plans' ? 'premium.config' : 'premium.grant');
  const title = (p: StaffProposal) =>
    p.kind === 'plans'
      ? intl.formatMessage({ id: 'pv2.proposals.plans' }, { version: p.version })
      : intl.formatMessage(
          { id: 'pv2.proposals.adjustment' },
          {
            code: p.adjustment?.code,
            signed: `${(p.adjustment?.amount ?? 0) > 0 ? '+' : ''}${p.adjustment?.amount ?? 0}`,
            feature: p.adjustment?.feature,
          },
        );
  const when = (iso: string) =>
    new Intl.DateTimeFormat(intl.locale, { dateStyle: 'short', timeStyle: 'short' }).format(
      new Date(iso),
    );
  return (
    <Section title={<FormattedMessage id="pv2.proposals.title" />}>
      {pending.length === 0 ? (
        <EmptyState title={<FormattedMessage id="pv2.proposals.none" />} />
      ) : (
        <ul className="grid gap-3">
          {pending.map((p) => {
            const changes = p.plans ? planChanges(current, p.plans) : [];
            return (
              <li key={p.id} className="grid gap-2 rounded-lg border p-3">
                <div className="flex flex-wrap items-center gap-2">
                  <span className="font-medium">{title(p)}</span>
                  <Pill tone={statusTone[p.status]}>
                    <FormattedMessage id={`pv2.status.${p.status}`} />
                  </Pill>
                  <span className="text-xs text-muted-foreground">
                    <FormattedMessage id="pv2.proposals.by" values={{ by: p.by, at: when(p.at) }} />
                  </span>
                </div>
                {p.kind === 'plans' && (
                  <div className="text-sm">
                    <span className="text-muted-foreground">
                      <FormattedMessage id="pv2.proposals.changes" />:{' '}
                    </span>
                    {changes.length === 0 ? (
                      <FormattedMessage id="pv2.proposals.noChange" />
                    ) : (
                      <ul className="mt-1 grid gap-0.5 font-mono text-xs">
                        {changes.map((c) => (
                          <li key={c}>{c}</li>
                        ))}
                      </ul>
                    )}
                  </div>
                )}
                {canDecide(p) && (
                  <div className="flex flex-wrap items-center gap-2">
                    <Button kind="primary" onClick={() => setDeciding({ p, approve: true })}>
                      <FormattedMessage id="pv2.proposals.approve" />
                    </Button>
                    <Button onClick={() => setDeciding({ p, approve: false })}>
                      <FormattedMessage id="pv2.proposals.reject" />
                    </Button>
                    {p.mine && (
                      <span className="text-xs text-muted-foreground">
                        <FormattedMessage id="pv2.proposals.mine" />
                      </span>
                    )}
                  </div>
                )}
              </li>
            );
          })}
        </ul>
      )}
      {recent.length > 0 && (
        <ul className="mt-3 grid gap-1 text-sm text-muted-foreground">
          {recent.map((p) => (
            <li key={p.id} className="flex flex-wrap gap-2">
              <span>{title(p)}</span>
              <span>·</span>
              <FormattedMessage id={`pv2.status.${p.status}`} />
              {p.decidedBy && <span>· {p.decidedBy}</span>}
            </li>
          ))}
        </ul>
      )}
      {deciding && (
        <ConfirmModal
          title={
            <FormattedMessage
              id={deciding.approve ? 'pv2.proposals.approveTitle' : 'pv2.proposals.rejectTitle'}
            />
          }
          confirm={
            <FormattedMessage
              id={deciding.approve ? 'pv2.proposals.approve' : 'pv2.proposals.reject'}
            />
          }
          danger={!deciding.approve}
          busy={busy}
          error={error}
          onCancel={() => {
            setDeciding(null);
            setError(null);
          }}
          onConfirm={() => {
            setBusy(true);
            setError(null);
            api
              .call('staffDecidePremiumProposal', {
                id: deciding.p.id,
                approve: deciding.approve,
              })
              .then(() => {
                toast.success(intl.formatMessage({ id: 'pv2.proposals.done' }));
                setDeciding(null);
                onChanged();
              })
              .catch((e: unknown) => setError(asApiError(e)))
              .finally(() => setBusy(false));
          }}
        >
          {deciding.approve && (
            <FormattedMessage
              id={
                deciding.p.kind === 'plans'
                  ? 'pv2.proposals.approveEffect'
                  : 'pv2.proposals.approveAdjustEffect'
              }
            />
          )}
        </ConfirmModal>
      )}
    </Section>
  );
}

/** PT02 "Điều chỉnh thủ công" for one family (Tính năng & Premium › Gia đình). */
export function AdjustUsagePanel({ code, onDone }: { code: string; onDone: () => void }) {
  const intl = useIntl();
  const api = useApi();
  const staff = useStaff();
  const [feature, setFeature] = useState<'lumi' | 'video'>('lumi');
  const [amount, setAmount] = useState(0);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const featureId = useId();
  useEffect(() => setError(null), [feature, amount]);
  if (!staffCan(staff.levels, 'premium.grant')) return null;
  const submit = async () => {
    setBusy(true);
    setError(null);
    try {
      const r = await api.call<{ status: 'applied' | 'pending'; before?: number; after?: number }>(
        'staffAdjustUsage',
        { code, feature, amount },
      );
      toast.success(
        r.status === 'applied'
          ? intl.formatMessage({ id: 'pv2.adjust.applied' }, { before: r.before, after: r.after })
          : intl.formatMessage({ id: 'pv2.adjust.pending' }),
      );
      setAmount(0);
      onDone();
    } catch (e) {
      setError(asApiError(e));
    } finally {
      setBusy(false);
    }
  };
  return (
    <Section
      title={<FormattedMessage id="pv2.adjust.title" />}
      description={
        <FormattedMessage id="pv2.adjust.note" values={{ n: adjustmentApprovalThreshold }} />
      }
    >
      <div className="grid gap-4 sm:grid-cols-[1fr_1fr_auto] sm:items-end">
        <Field label={<FormattedMessage id="pv2.adjust.feature" />} htmlFor={featureId}>
          <FieldSelect
            id={featureId}
            value={feature}
            options={[{ value: 'lumi', label: intl.formatMessage({ id: 'pv2.adjust.lumi' }) }]}
            onChange={setFeature}
          />
        </Field>
        <IntField
          label={<FormattedMessage id="pv2.adjust.amount" />}
          min={-1000}
          value={amount}
          onChange={(v) => setAmount(Math.max(-1000, Math.min(1000, v)))}
        />
        <Button kind="primary" disabled={busy || amount === 0} onClick={() => void submit()}>
          <FormattedMessage id="pv2.adjust.submit" />
        </Button>
      </div>
      {error && (
        <Notice tone="error" className="mt-3">
          <FormattedMessage id={errorMessageId(error)} />
        </Notice>
      )}
    </Section>
  );
}

/** PT04 "Hoàn lượt" on a video job of Render ops. */
export function RefundJobButton({ family, job }: { family: string; job: string }) {
  const intl = useIntl();
  const api = useApi();
  const staff = useStaff();
  const [open, setOpen] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  if (!staffCan(staff.levels, 'premium.grant')) return null;
  return (
    <>
      <Button kind="ghost" onClick={() => setOpen(true)}>
        <FormattedMessage id="pv2.refund.action" />
      </Button>
      {open && (
        <ConfirmModal
          title={<FormattedMessage id="pv2.refund.title" values={{ job }} />}
          confirm={<FormattedMessage id="pv2.refund.action" />}
          busy={busy}
          error={error}
          onCancel={() => {
            setOpen(false);
            setError(null);
          }}
          onConfirm={() => {
            setBusy(true);
            setError(null);
            api
              .call<{ outcome: 'refunded' | 'already' }>('staffRefundVideoJob', {
                code: family,
                job,
              })
              .then((r) => {
                toast.success(
                  intl.formatMessage({
                    id: r.outcome === 'refunded' ? 'pv2.refund.done' : 'pv2.refund.already',
                  }),
                );
                setOpen(false);
              })
              .catch((e: unknown) => setError(asApiError(e)))
              .finally(() => setBusy(false));
          }}
        >
          <FormattedMessage id="pv2.refund.effect" />
        </ConfirmModal>
      )}
    </>
  );
}
