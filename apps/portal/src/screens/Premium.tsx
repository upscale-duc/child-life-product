import {
  staffCan,
  staffEntitlementsConfigSchema,
  type GrantEnvironment,
} from '@child-life/contracts';
import { useEffect, useId, useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { toast } from 'sonner';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import {
  ApiError,
  useApi,
  useLoad,
  type Api,
  type FlagsView,
  type StaffPremiumConfig,
  type StaffPremiumView,
} from '../api';
import { Field, Notice, Section } from '../content-kit';
import { useStaff } from '../context';
import { ZONE } from '../format';
import {
  Button,
  Loaded,
  Loading,
  Modal,
  Pill,
  Segmented,
  TableScroll,
  errorMessageId,
} from '../ui';
import { FlagDialog, FlagRow, billingFlag, type FlagChange } from './Features';
import { FieldSelect } from './form-controls';
import { AiPolicyLoader } from './PremiumOps';
import { PlansVersionSection } from './PremiumPlans';

/**
 * Tính năng & Premium › Gói Premium (D-089; was Premium › Cấu hình and Chính sách AI): Mua gói
 * trong app (`premium_billing`), the regions where paid Premium is sold (an admin-granted Premium
 * skips the country, D-089), video quotas, the assistant credit pool and the policy version, as
 * one draft of `config/entitlements` saved from the bar that shows while it is unsaved; the AI
 * policy in force; and the old beta campaigns, read-only, which Beta features replace. Every
 * number is configuration, not a commercial commitment (Q-071); health and logging stay free in
 * every plan state. No reason is asked (D-090).
 */

export function EnvPill({ env }: { env: GrantEnvironment }) {
  return (
    <Pill tone={env === 'production' ? 'ok' : 'wait'}>
      <FormattedMessage id={`premium.env.${env}`} />
    </Pill>
  );
}

// ---------- Dates: a day picked on the portal is a day in Vietnam ----------

const DAY = 86_400_000;

/** "2026-10-14" for an ISO instant; `end` = the last day of an exclusive end. */
export function dayInput(iso: string, end = false): string {
  const t = Date.parse(iso) - (end ? 1 : 0);
  return new Intl.DateTimeFormat('en-CA', { timeZone: ZONE }).format(new Date(t));
}

/** Start of a Vietnam day as ISO; `end` = the start of the next day (exclusive end). */
export function isoFromDay(day: string, end = false): string {
  return new Date(Date.parse(`${day}T00:00:00+07:00`) + (end ? DAY : 0)).toISOString();
}

/** Country name in the portal language ("Việt Nam", "Vietnam"); the code when unknown. */
export function countryName(locale: string, code: string): string {
  try {
    return new Intl.DisplayNames([locale], { type: 'region', fallback: 'none' }).of(code) ?? code;
  } catch {
    return code;
  }
}

const asApiError = (e: unknown) => (e instanceof ApiError ? e : new ApiError('unknown', null));

/** Sends the whole config (families as codes), checked first like the server; no reason. */
export async function savePremiumConfig(
  api: Api,
  config: StaffPremiumConfig,
): Promise<{ ok: true } | { ok: false; error: ApiError }> {
  const check = staffEntitlementsConfigSchema.safeParse(config);
  if (!check.success) return { ok: false, error: new ApiError('invalid-argument', 'malformed') };
  try {
    await api.call('staffSetPremiumConfig', { config: check.data });
    return { ok: true };
  } catch (e) {
    return { ok: false, error: asApiError(e) };
  }
}

// ---------- The tab ----------

export const planSections = ['config', 'plans', 'ai'] as const;
export type PlanSection = (typeof planSections)[number];

export function PremiumPlanLoader() {
  const [load, reload] = useLoad<StaffPremiumView>('staffPremium', {}, 'premium');
  const [flags, reloadFlags] = useLoad<FlagsView>('staffFlags', {}, 'flags');
  return (
    <Loaded load={load} reload={reload}>
      {(data) => (
        <PremiumPlanView
          data={data}
          flags={flags.status === 'ok' ? flags.data : null}
          onChanged={reload}
          onFlagsChanged={reloadFlags}
        />
      )}
    </Loaded>
  );
}

export function PremiumPlanView({
  data,
  flags,
  onChanged,
  onFlagsChanged = () => undefined,
  initialSection = 'config',
}: {
  data: StaffPremiumView;
  /** For Mua gói trong app; null while it loads. */
  flags: FlagsView | null;
  onChanged: () => void;
  onFlagsChanged?: () => void;
  now?: Date;
  initialSection?: PlanSection;
}) {
  const intl = useIntl();
  const staff = useStaff();
  const canConfig = staffCan(staff.levels, 'premium.config');
  const [section, setSection] = useState<PlanSection>(initialSection);
  const saved = JSON.stringify(data.config);
  const [draft, setDraft] = useState<StaffPremiumConfig>(data.config);
  // A reload keeps nothing unsaved by accident: a new stored config replaces the draft.
  useEffect(() => setDraft(JSON.parse(saved) as StaffPremiumConfig), [saved]);
  const dirty = JSON.stringify(draft) !== saved;
  const [saving, setSaving] = useState(false);
  return (
    <div className="grid min-w-0 gap-4">
      <div className="flex flex-wrap items-center gap-2">
        <Segmented
          label={intl.formatMessage({ id: 'hub.plan.sections' })}
          value={section}
          onChange={setSection}
          options={planSections.map((s) => ({
            value: s,
            label: <FormattedMessage id={`hub.plan.${s}`} />,
          }))}
        />
        <span className="ml-auto">
          <EnvPill env={data.environment} />
        </span>
      </div>
      {canConfig && dirty && section === 'config' && (
        <SaveBar
          config={draft}
          saved={JSON.parse(saved) as StaffPremiumConfig}
          onDiscard={() => setDraft(JSON.parse(saved) as StaffPremiumConfig)}
          onSave={() => setSaving(true)}
        />
      )}
      {section === 'config' && (
        <>
          {!data.stored && (
            <Notice tone="info">
              <FormattedMessage id="premium.notStored" />
            </Notice>
          )}
          {!canConfig && (
            <Notice tone="info">
              <FormattedMessage id="premium.readOnly" />
            </Notice>
          )}
          <BillingSwitch flags={flags} onChanged={onFlagsChanged} />
          <ConfigSections config={draft} editable={canConfig} onChange={setDraft} />
        </>
      )}
      {section === 'plans' && <PlansVersionSection config={data.config} onChanged={onChanged} />}
      {section === 'ai' && (
        // The limits themselves are edited in Cấu hình.
        <AiPolicyLoader onOpenLimits={() => setSection('config')} />
      )}
      {saving && (
        <SaveDialog
          config={draft}
          onClose={() => setSaving(false)}
          onDone={() => {
            setSaving(false);
            toast.success(intl.formatMessage({ id: 'premium.savedToast' }));
            onChanged();
          }}
        />
      )}
    </div>
  );
}

/** "Mua gói trong app": the paywall and store purchases, a switch with who sees it. */
function BillingSwitch({ flags, onChanged }: { flags: FlagsView | null; onChanged: () => void }) {
  const staff = useStaff();
  const [change, setChange] = useState<FlagChange | null>(null);
  return (
    <Section flush title={<FormattedMessage id="hub.plan.billing" />}>
      {flags ? (
        <TableScroll min={560}>
          <table className="table">
            <tbody>
              <FlagRow
                flag={billingFlag}
                value={flags.flags[billingFlag]}
                last={flags.lastEdit[billingFlag] ?? null}
                canToggle={staffCan(staff.levels, 'flags.toggle')}
                canRollout={staffCan(staff.levels, 'flags.rollout')}
                onChange={setChange}
              />
            </tbody>
          </table>
        </TableScroll>
      ) : (
        <div className="px-5 py-4">
          <Loading variant="lines" rows={4} />
        </div>
      )}
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
    </Section>
  );
}

/** What changed in the draft, in a few words: "khu vực mở, hạn mức". */
export function draftChanges(saved: StaffPremiumConfig, draft: StaffPremiumConfig): string[] {
  const out: string[] = [];
  if (JSON.stringify(saved.regions) !== JSON.stringify(draft.regions)) out.push('regions');
  if (JSON.stringify(saved.quotas) !== JSON.stringify(draft.quotas)) out.push('quotas');
  if (saved.policyVersion !== draft.policyVersion) out.push('policy');
  return out;
}

/** Stays under the header while the draft is unsaved: what changed, discard, save. */
function SaveBar({
  config,
  saved,
  onDiscard,
  onSave,
}: {
  config: StaffPremiumConfig;
  saved: StaffPremiumConfig;
  onDiscard: () => void;
  onSave: () => void;
}) {
  const intl = useIntl();
  const parts = draftChanges(saved, config).map((what) =>
    intl.formatMessage({ id: `premium.changed.${what}` }),
  );
  return (
    <div className="sticky top-14 z-10 -mx-4 flex flex-wrap items-center gap-x-3 gap-y-2 border-y border-warning/40 bg-background/95 px-4 py-2.5 backdrop-blur md:-mx-8 md:px-8">
      <span className="size-2 rounded-full bg-warning" aria-hidden="true" />
      <span className="text-sm" role="status">
        <strong className="font-medium">
          <FormattedMessage id="premium.unsaved" />
        </strong>
        {parts.length > 0 && <span className="text-muted-foreground"> · {parts.join(', ')}</span>}
      </span>
      <div className="ml-auto flex gap-2">
        <Button onClick={onDiscard}>
          <FormattedMessage id="premium.discard" />
        </Button>
        <Button kind="primary" onClick={onSave}>
          <FormattedMessage id="premium.save" />
        </Button>
      </div>
    </div>
  );
}

function NumberField({
  label,
  value,
  onChange,
  max,
}: {
  label: ReactNode;
  value: number;
  onChange: (v: number) => void;
  max?: number;
}) {
  const id = useId();
  return (
    <Field label={label} htmlFor={id}>
      <Input
        id={id}
        type="number"
        min={0}
        max={max}
        step={1}
        className="tabular-nums"
        value={value}
        onChange={(e) => onChange(Math.max(0, Math.round(Number(e.target.value) || 0)))}
      />
    </Field>
  );
}

type Window = StaffPremiumConfig['quotas']['video']['free']['window'];
const windows: Window[] = ['calendar_month', 'billing_period'];

/** Cấu hình: open regions, video quotas, assistant credits, policy version, rules. */
function ConfigSections({
  config,
  editable,
  onChange,
}: {
  config: StaffPremiumConfig;
  editable: boolean;
  onChange: (c: StaffPremiumConfig) => void;
}) {
  const intl = useIntl();
  const policyId = useId();
  const [code, setCode] = useState('');
  const [problem, setProblem] = useState(false);
  const regions = config.regions.advanced;
  const addRegion = () => {
    const c = code.trim().toUpperCase();
    if (!/^[A-Z]{2}$/.test(c) || countryName('en', c) === c) {
      setProblem(true);
      return;
    }
    setProblem(false);
    setCode('');
    if (!regions.includes(c)) onChange({ ...config, regions: { advanced: [...regions, c] } });
  };
  const video = config.quotas.video;
  const credits = config.quotas.assistant;
  const setVideo = (plan: 'free' | 'premium', v: Partial<typeof video.free>) =>
    onChange({
      ...config,
      quotas: { ...config.quotas, video: { ...video, [plan]: { ...video[plan], ...v } } },
    });
  // D-075 #1: one assistant credit pool for the chat and the AI summaries (the legacy
  // `quotas.ai` stays in the document untouched; nothing uses it any more).
  const setCredits = (v: Partial<typeof credits>) =>
    onChange({ ...config, quotas: { ...config.quotas, assistant: { ...credits, ...v } } });
  const windowOptions = windows.map((w) => ({
    value: w,
    label: intl.formatMessage({ id: `premium.window.${w}` }),
  }));
  const windowField = (plan: 'free' | 'premium') => (
    <Field label={<FormattedMessage id="premium.quota.window" />}>
      <FieldSelect
        value={video[plan].window}
        options={windowOptions}
        onChange={(window) => setVideo(plan, { window })}
        ariaLabel={intl.formatMessage({
          id:
            plan === 'free' ? 'premium.quota.videoFreeWindow' : 'premium.quota.videoPremiumWindow',
        })}
      />
    </Field>
  );
  return (
    <div className="grid gap-4">
      <Section
        title={<FormattedMessage id="premium.regions.title" />}
        description={<FormattedMessage id="premium.regions.note" />}
      >
        <div className="grid gap-3">
          {regions.length === 0 ? (
            <p className="text-sm text-muted-foreground">
              <FormattedMessage id="premium.regions.none" />
            </p>
          ) : (
            <ul className="flex flex-wrap gap-1.5">
              {regions.map((r) => (
                <li key={r}>
                  <Badge variant="secondary" className="gap-1 py-1 pr-1.5 text-sm font-normal">
                    {countryName(intl.locale, r)} · {r}
                    {editable && (
                      <button
                        type="button"
                        className="family-picker__remove"
                        aria-label={intl.formatMessage(
                          { id: 'premium.regions.remove' },
                          { name: countryName(intl.locale, r) },
                        )}
                        onClick={() =>
                          onChange({
                            ...config,
                            regions: { advanced: regions.filter((x) => x !== r) },
                          })
                        }
                      >
                        ×
                      </button>
                    )}
                  </Badge>
                </li>
              ))}
            </ul>
          )}
          {editable && (
            <div className="flex max-w-sm gap-2">
              <Input
                value={code}
                maxLength={2}
                onChange={(e) => setCode(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') {
                    e.preventDefault();
                    addRegion();
                  }
                }}
                placeholder={intl.formatMessage({ id: 'premium.regions.code' })}
                aria-label={intl.formatMessage({ id: 'premium.regions.code' })}
              />
              <Button disabled={!code.trim()} onClick={addRegion}>
                <FormattedMessage id="premium.regions.add" />
              </Button>
            </div>
          )}
          {problem && (
            <p className="text-sm text-destructive" role="alert">
              <FormattedMessage id="premium.regions.bad" />
            </p>
          )}
        </div>
      </Section>
      <Section title={<FormattedMessage id="premium.quota.title" />}>
        {editable ? (
          <div className="grid gap-4 sm:grid-cols-2">
            <NumberField
              label={<FormattedMessage id="premium.quota.videoFree" />}
              value={video.free.limit}
              onChange={(limit) => setVideo('free', { limit })}
            />
            {windowField('free')}
            <NumberField
              label={<FormattedMessage id="premium.quota.videoPremium" />}
              value={video.premium.limit}
              onChange={(limit) => setVideo('premium', { limit })}
            />
            {windowField('premium')}
          </div>
        ) : (
          <dl className="kv">
            {(['free', 'premium'] as const).map((plan) => (
              <ReadRow
                key={plan}
                label={
                  <FormattedMessage
                    id={plan === 'free' ? 'premium.quota.videoFree' : 'premium.quota.videoPremium'}
                  />
                }
              >
                <FormattedMessage
                  id="premium.quota.videoValue"
                  values={{
                    n: video[plan].limit,
                    label: intl.formatMessage({ id: `premium.window.${video[plan].window}` }),
                  }}
                />
              </ReadRow>
            ))}
          </dl>
        )}
      </Section>
      <Section
        title={<FormattedMessage id="premium.credits.title" />}
        description={<FormattedMessage id="premium.credits.note" />}
      >
        {editable ? (
          <div className="grid gap-4 sm:grid-cols-2">
            <NumberField
              label={<FormattedMessage id="premium.credits.free" />}
              value={credits.free}
              onChange={(free) => setCredits({ free })}
            />
            <NumberField
              label={<FormattedMessage id="premium.credits.premium" />}
              value={credits.premium}
              onChange={(premium) => setCredits({ premium })}
            />
            <NumberField
              label={<FormattedMessage id="premium.credits.text" />}
              value={credits.textCredits}
              max={20}
              onChange={(textCredits) => setCredits({ textCredits: Math.min(20, textCredits) })}
            />
            <NumberField
              label={<FormattedMessage id="premium.credits.image" />}
              value={credits.imageCredits}
              max={20}
              onChange={(imageCredits) => setCredits({ imageCredits: Math.min(20, imageCredits) })}
            />
          </div>
        ) : (
          <dl className="kv">
            {(
              [
                ['premium.credits.free', credits.free],
                ['premium.credits.premium', credits.premium],
                ['premium.credits.text', credits.textCredits],
                ['premium.credits.image', credits.imageCredits],
              ] as const
            ).map(([id, n]) => (
              <ReadRow key={id} label={<FormattedMessage id={id} />}>
                <FormattedMessage id="premium.credits.value" values={{ n }} />
              </ReadRow>
            ))}
          </dl>
        )}
      </Section>
      <Section
        collapsible
        defaultOpen={false}
        title={<FormattedMessage id="premium.policyVersion" />}
        summary={<span className="font-mono">{config.policyVersion}</span>}
        hint={<FormattedMessage id="premium.policyHint" />}
      >
        {editable ? (
          <Field
            className="max-w-sm"
            htmlFor={policyId}
            label={<FormattedMessage id="premium.policyVersion" />}
          >
            <Input
              id={policyId}
              className="font-mono"
              value={config.policyVersion}
              maxLength={40}
              onChange={(e) => onChange({ ...config, policyVersion: e.target.value })}
            />
          </Field>
        ) : (
          <p className="font-mono text-sm">{config.policyVersion}</p>
        )}
      </Section>
      <Section collapsible defaultOpen={false} title={<FormattedMessage id="premium.rules" />}>
        <ul className="grid list-disc gap-2 pl-5 text-sm text-muted-foreground">
          {[
            'premium.rule.config',
            'premium.rule.beta',
            'premium.rule.free',
            'premium.rule.paid',
          ].map((id) => (
            <li key={id}>
              <FormattedMessage id={id} />
            </li>
          ))}
        </ul>
      </Section>
    </div>
  );
}

function ReadRow({ label, children }: { label: ReactNode; children: ReactNode }) {
  return (
    <>
      <dt>{label}</dt>
      <dd>{children}</dd>
    </>
  );
}

/** Lưu cấu hình: what it does, then save (no reason: D-090). */
function SaveDialog({
  config,
  onClose,
  onDone,
}: {
  config: StaffPremiumConfig;
  onClose: () => void;
  onDone: () => void;
}) {
  const api = useApi();
  const intl = useIntl();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const submit = async () => {
    setBusy(true);
    setError(null);
    const res = await savePremiumConfig(api, config);
    setBusy(false);
    if (res.ok) onDone();
    else setError(res.error);
  };
  return (
    <Modal title={<FormattedMessage id="premium.saveTitle" />} onClose={onClose}>
      <p className="text-sm text-muted-foreground">
        <FormattedMessage id="premium.saveEffect" />
      </p>
      <dl className="kv">
        <dt>
          <FormattedMessage id="premium.regions.advanced" />
        </dt>
        <dd>{config.regions.advanced.map((r) => countryName(intl.locale, r)).join(', ') || '—'}</dd>
      </dl>
      {error && (
        <Notice tone="error">
          <FormattedMessage id={errorMessageId(error)} />
        </Notice>
      )}
      <div className="modal__actions">
        <Button onClick={onClose}>
          <FormattedMessage id="action.cancel" />
        </Button>
        <Button kind="primary" disabled={busy} onClick={() => void submit()}>
          <FormattedMessage id="premium.saveConfirm" />
        </Button>
      </div>
    </Modal>
  );
}
