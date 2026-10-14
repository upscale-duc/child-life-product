import {
  groupACapabilities,
  premiumCapabilities,
  staffCan,
  staffEntitlementsConfigSchema,
  type BetaCampaign,
  type Capability,
  type GrantEnvironment,
  type HouseholdPlan,
  type StaffFamilyPremium,
} from '@child-life/contracts';
import { useEffect, useId, useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl, type IntlShape } from 'react-intl';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import {
  ApiError,
  useApi,
  useLoad,
  type Api,
  type StaffPremiumConfig,
  type StaffPremiumView,
} from '../api';
import { useStaff } from '../context';
import { ZONE, shortDate } from '../format';
import {
  Button,
  Loaded,
  LockNote,
  Modal,
  Page,
  Panel,
  Pill,
  ReasonField,
  RowActions,
  Segmented,
  TableScroll,
  errorMessageId,
  reasonOk,
  type PillTone,
} from '../ui';
import { AuditActionText, FamilyPicker } from './Features';
import { CheckRow, FieldSelect } from './form-controls';

/**
 * Premium & Cá nhân hoá (plan §5.6): advanced regions, quotas and Beta A campaigns in
 * `config/entitlements`, and one family's plan and grants with promo grants and revokes.
 * Every number is configuration, not a commercial commitment (Q-071); Beta A never opens
 * `templates.premium`; health and logging stay free in every plan state (brief p.3).
 * Staff actions: `premium.view` / `premium.config` / `premium.grant` (owner, admin).
 */
export function PremiumScreen() {
  const [load, reload] = useLoad<StaffPremiumView>('staffPremium', {}, 'premium');
  return (
    <Page
      title={<FormattedMessage id="premium.title" />}
      subtitle={<FormattedMessage id="premium.sub" />}
      actions={load.status === 'ok' ? <EnvPill env={load.data.environment} /> : undefined}
    >
      <Loaded load={load} reload={reload}>
        {(data) => <PremiumBody data={data} onChanged={reload} />}
      </Loaded>
    </Page>
  );
}

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

function fullDate(intl: IntlShape, iso: string) {
  return intl.formatDate(iso, {
    day: 'numeric',
    month: 'numeric',
    year: 'numeric',
    timeZone: ZONE,
  });
}

/** "14/10/2026 – 13/11/2026": the end shown is the last day included. */
function Range({ from, until }: { from: string; until: string }) {
  const intl = useIntl();
  return (
    <FormattedMessage
      id="premium.range"
      values={{
        from: fullDate(intl, from),
        to: fullDate(intl, new Date(Date.parse(until) - 1).toISOString()),
      }}
    />
  );
}

/** Country name in the portal language ("Việt Nam", "Vietnam"); the code when unknown. */
export function countryName(locale: string, code: string): string {
  try {
    return new Intl.DisplayNames([locale], { type: 'region', fallback: 'none' }).of(code) ?? code;
  } catch {
    return code;
  }
}

function capabilityList(intl: IntlShape, caps: readonly Capability[]) {
  return caps.map((c) => intl.formatMessage({ id: `premium.cap.${c}` })).join(', ');
}

const asApiError = (e: unknown) => (e instanceof ApiError ? e : new ApiError('unknown', null));

// ---------- Config: pure helpers (tested) ----------

export function blankCampaign(now: Date): BetaCampaign {
  const today = dayInput(now.toISOString());
  return {
    id: '',
    capabilities: [...groupACapabilities],
    validFrom: isoFromDay(today),
    validUntil: new Date(Date.parse(isoFromDay(today)) + 30 * DAY).toISOString(),
    countries: [],
    scope: 'internal',
    percent: 0,
    families: [],
  };
}

/** Families travel only with "Gia đình được chọn"; the percent follows the scope. */
export function normalizeCampaign(c: BetaCampaign): BetaCampaign {
  const { families, ...rest } = c;
  return {
    ...rest,
    // Beta A never opens Cao cấp templates (brief p.3): only group A is ever kept.
    capabilities: groupACapabilities.filter((x) => c.capabilities.includes(x)),
    percent: c.scope === 'all' ? 100 : c.scope === 'internal' ? 0 : c.percent,
    ...(c.scope === 'internal' && families?.length ? { families: [...families] } : {}),
  };
}

/** Adds (`index` null) or replaces a campaign. */
export function withCampaign(
  config: StaffPremiumConfig,
  campaign: BetaCampaign,
  index: number | null,
): StaffPremiumConfig {
  const next = normalizeCampaign(campaign);
  const list = [...config.betaCampaigns];
  if (index === null) list.push(next);
  else list[index] = next;
  return { ...config, betaCampaigns: list };
}

/** What stops a campaign form, as message ids. */
export function campaignIssues(
  c: BetaCampaign,
  all: readonly BetaCampaign[],
  index: number | null,
): string[] {
  const out: string[] = [];
  if (!/^[a-z0-9_-]{2,40}$/.test(c.id)) out.push('premium.issue.id');
  else if (all.some((x, i) => i !== index && x.id === c.id)) out.push('premium.issue.duplicate');
  if (!c.capabilities.some((x) => groupACapabilities.includes(x))) out.push('premium.issue.caps');
  if (!(Date.parse(c.validUntil) > Date.parse(c.validFrom))) out.push('premium.issue.dates');
  if (c.scope === 'percent' && !(Number.isInteger(c.percent) && c.percent >= 1 && c.percent <= 100))
    out.push('premium.issue.percent');
  return out;
}

/** Sends the whole config (families as codes) with the reason; checked first like the server. */
export async function savePremiumConfig(
  api: Api,
  config: StaffPremiumConfig,
  reason: string,
): Promise<{ ok: true } | { ok: false; error: ApiError }> {
  const check = staffEntitlementsConfigSchema.safeParse(config);
  if (!check.success || !reasonOk(reason)) {
    return { ok: false, error: new ApiError('invalid-argument', 'malformed') };
  }
  try {
    await api.call('staffSetPremiumConfig', { config: check.data, reason: reason.trim() });
    return { ok: true };
  } catch (e) {
    return { ok: false, error: asApiError(e) };
  }
}

type FamilyGrant = StaffFamilyPremium['grants'][number];

/**
 * Only grants staff wrote (promo, or a beta written by hand) can be revoked one family at a time;
 * paid grants follow the store and campaign rows end with the campaign.
 */
export function grantRevocable(g: FamilyGrant): boolean {
  return (
    !g.fromCampaign &&
    (g.source === 'promo' || g.source === 'beta') &&
    /^(promo|beta)_[A-Za-z0-9_-]{1,80}$/.test(g.id) &&
    g.status !== 'revoked'
  );
}

// ---------- The screen ----------

export function PremiumBody({
  data,
  onChanged,
  now = new Date(),
  initialFamily = null,
}: {
  data: StaffPremiumView;
  onChanged: () => void;
  now?: Date;
  /** A looked-up family (tests). */
  initialFamily?: StaffFamilyPremium | null;
}) {
  const staff = useStaff();
  const canConfig = staffCan(staff.levels, 'premium.config');
  const canGrant = staffCan(staff.levels, 'premium.grant');
  const saved = JSON.stringify(data.config);
  const [draft, setDraft] = useState<StaffPremiumConfig>(data.config);
  // A reload after a grant keeps unsaved edits; a new stored config replaces them.
  useEffect(() => setDraft(JSON.parse(saved) as StaffPremiumConfig), [saved]);
  const dirty = JSON.stringify(draft) !== saved;
  const [editing, setEditing] = useState<{ index: number | null; campaign: BetaCampaign } | null>(
    null,
  );
  const [saving, setSaving] = useState(false);
  return (
    <div className="cols cols--2-1">
      <div className="stack">
        {!data.stored && (
          <LockNote>
            <FormattedMessage id="premium.notStored" />
          </LockNote>
        )}
        {!canConfig && (
          <LockNote>
            <FormattedMessage id="premium.readOnly" />
          </LockNote>
        )}
        <RegionsPanel config={draft} editable={canConfig} onChange={setDraft} />
        <CampaignsPanel
          config={draft}
          editable={canConfig}
          now={now}
          onAdd={() => setEditing({ index: null, campaign: blankCampaign(now) })}
          onEdit={(index) => setEditing({ index, campaign: draft.betaCampaigns[index]! })}
          onRemove={(index) =>
            setDraft({ ...draft, betaCampaigns: draft.betaCampaigns.filter((_, i) => i !== index) })
          }
        />
        {canConfig && (
          <Panel>
            <div className="flex flex-wrap items-center justify-between gap-3">
              <span className="muted">
                <FormattedMessage id={dirty ? 'premium.unsaved' : 'premium.saved'} />
              </span>
              <div className="flex flex-wrap gap-2">
                <Button
                  disabled={!dirty}
                  onClick={() => setDraft(JSON.parse(saved) as StaffPremiumConfig)}
                >
                  <FormattedMessage id="premium.discard" />
                </Button>
                <Button kind="primary" disabled={!dirty} onClick={() => setSaving(true)}>
                  <FormattedMessage id="premium.save" />
                </Button>
              </div>
            </div>
          </Panel>
        )}
        <FamilyLookup canGrant={canGrant} onChanged={onChanged} now={now} initial={initialFamily} />
      </div>
      <div className="stack">
        <Panel title={<FormattedMessage id="premium.rules" />}>
          <ul className="recent">
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
        </Panel>
        <RecentPanel recent={data.recent} />
      </div>
      {editing && (
        <CampaignDialog
          initial={editing.campaign}
          index={editing.index}
          all={draft.betaCampaigns}
          regions={draft.regions.advanced}
          onClose={() => setEditing(null)}
          onApply={(c) => {
            setDraft(withCampaign(draft, c, editing.index));
            setEditing(null);
          }}
        />
      )}
      {saving && (
        <SaveDialog
          config={draft}
          onClose={() => setSaving(false)}
          onDone={() => {
            setSaving(false);
            onChanged();
          }}
        />
      )}
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
    <div className="field">
      <label className="field__label" htmlFor={id}>
        {label}
      </label>
      <Input
        id={id}
        type="number"
        min={0}
        max={max}
        step={1}
        value={value}
        onChange={(e) => onChange(Math.max(0, Math.round(Number(e.target.value) || 0)))}
      />
    </div>
  );
}

type Window = StaffPremiumConfig['quotas']['video']['free']['window'];
const windows: Window[] = ['calendar_month', 'billing_period'];

function RegionsPanel({
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
  const ai = config.quotas.ai;
  const setVideo = (plan: 'free' | 'premium', v: Partial<typeof video.free>) =>
    onChange({
      ...config,
      quotas: { ...config.quotas, video: { ...video, [plan]: { ...video[plan], ...v } } },
    });
  const setAi = (v: Partial<typeof ai>) =>
    onChange({ ...config, quotas: { ...config.quotas, ai: { ...ai, ...v } } });
  const windowOptions = windows.map((w) => ({
    value: w,
    label: intl.formatMessage({ id: `premium.window.${w}` }),
  }));
  return (
    <Panel
      title={<FormattedMessage id="premium.regions.title" />}
      note={<FormattedMessage id="premium.regions.note" />}
    >
      <div className="stack">
        <div className="field">
          <span className="field__label">
            <FormattedMessage id="premium.regions.advanced" />
          </span>
          {regions.length === 0 ? (
            <p className="field__help">
              <FormattedMessage id="premium.regions.none" />
            </p>
          ) : (
            <ul className="family-picker__list">
              {regions.map((r) => (
                <li key={r}>
                  <Badge variant="secondary">
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
            <div className="family-picker__row">
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
            <p className="error" role="alert">
              <FormattedMessage id="premium.regions.bad" />
            </p>
          )}
        </div>
        {editable ? (
          <>
            <div className="grid gap-4 sm:grid-cols-2">
              <NumberField
                label={<FormattedMessage id="premium.quota.videoFree" />}
                value={video.free.limit}
                onChange={(limit) => setVideo('free', { limit })}
              />
              <div className="field">
                <span className="field__label">
                  <FormattedMessage id="premium.quota.window" />
                </span>
                <FieldSelect
                  value={video.free.window}
                  options={windowOptions}
                  onChange={(window) => setVideo('free', { window })}
                  ariaLabel={intl.formatMessage({ id: 'premium.quota.videoFreeWindow' })}
                />
              </div>
              <NumberField
                label={<FormattedMessage id="premium.quota.videoPremium" />}
                value={video.premium.limit}
                onChange={(limit) => setVideo('premium', { limit })}
              />
              <div className="field">
                <span className="field__label">
                  <FormattedMessage id="premium.quota.window" />
                </span>
                <FieldSelect
                  value={video.premium.window}
                  options={windowOptions}
                  onChange={(window) => setVideo('premium', { window })}
                  ariaLabel={intl.formatMessage({ id: 'premium.quota.videoPremiumWindow' })}
                />
              </div>
              <NumberField
                label={<FormattedMessage id="premium.quota.aiBaby" />}
                value={ai.perBabyPerDay}
                onChange={(perBabyPerDay) => setAi({ perBabyPerDay })}
              />
              <NumberField
                label={<FormattedMessage id="premium.quota.aiFamily" />}
                value={ai.perFamilyPerMonth}
                onChange={(perFamilyPerMonth) => setAi({ perFamilyPerMonth })}
              />
            </div>
            <div className="field">
              <label className="field__label" htmlFor={policyId}>
                <FormattedMessage id="premium.policyVersion" />
              </label>
              <Input
                id={policyId}
                value={config.policyVersion}
                maxLength={40}
                onChange={(e) => onChange({ ...config, policyVersion: e.target.value })}
              />
            </div>
          </>
        ) : (
          <dl className="kv">
            <dt>
              <FormattedMessage id="premium.quota.videoFree" />
            </dt>
            <dd>
              <FormattedMessage
                id="premium.quota.videoValue"
                values={{
                  n: video.free.limit,
                  label: intl.formatMessage({ id: `premium.window.${video.free.window}` }),
                }}
              />
            </dd>
            <dt>
              <FormattedMessage id="premium.quota.videoPremium" />
            </dt>
            <dd>
              <FormattedMessage
                id="premium.quota.videoValue"
                values={{
                  n: video.premium.limit,
                  label: intl.formatMessage({ id: `premium.window.${video.premium.window}` }),
                }}
              />
            </dd>
            <dt>
              <FormattedMessage id="premium.quota.aiBaby" />
            </dt>
            <dd>
              <FormattedMessage id="premium.quota.uses" values={{ n: ai.perBabyPerDay }} />
            </dd>
            <dt>
              <FormattedMessage id="premium.quota.aiFamily" />
            </dt>
            <dd>
              <FormattedMessage id="premium.quota.uses" values={{ n: ai.perFamilyPerMonth }} />
            </dd>
            <dt>
              <FormattedMessage id="premium.policyVersion" />
            </dt>
            <dd>{config.policyVersion}</dd>
          </dl>
        )}
      </div>
    </Panel>
  );
}

function campaignState(c: BetaCampaign, now: Date): { tone: PillTone; id: string } {
  const t = now.getTime();
  if (t < Date.parse(c.validFrom)) return { tone: 'wait', id: 'premium.campaign.upcoming' };
  if (t >= Date.parse(c.validUntil)) return { tone: 'muted', id: 'premium.campaign.ended' };
  return { tone: 'ok', id: 'premium.campaign.running' };
}

function ScopeLabel({ c }: { c: BetaCampaign }) {
  if (c.scope === 'internal') {
    const n = c.families?.length ?? 0;
    return (
      <Pill tone="purple">
        <FormattedMessage id={n ? 'scope.chosen' : 'scope.internal'} values={{ n }} />
      </Pill>
    );
  }
  if (c.scope === 'percent') {
    return (
      <Pill tone="wait">
        <FormattedMessage id="scope.percent" values={{ p: c.percent }} />
      </Pill>
    );
  }
  return (
    <span className="muted">
      <FormattedMessage id="scope.all" />
    </span>
  );
}

function CampaignsPanel({
  config,
  editable,
  now,
  onAdd,
  onEdit,
  onRemove,
}: {
  config: StaffPremiumConfig;
  editable: boolean;
  now: Date;
  onAdd: () => void;
  onEdit: (index: number) => void;
  onRemove: (index: number) => void;
}) {
  const intl = useIntl();
  const list = config.betaCampaigns;
  return (
    <Panel
      title={<FormattedMessage id="premium.beta.title" />}
      note={<FormattedMessage id="premium.beta.note" />}
      className="panel--flush"
      aside={
        editable && list.length < 20 ? (
          <Button onClick={onAdd}>
            <FormattedMessage id="premium.beta.add" />
          </Button>
        ) : undefined
      }
    >
      {list.length === 0 ? (
        <p className="panel__pad muted">
          <FormattedMessage id="premium.beta.none" />
        </p>
      ) : (
        <TableScroll min={760}>
          <table className="table">
            <thead>
              <tr>
                <th>
                  <FormattedMessage id="premium.col.campaign" />
                </th>
                <th>
                  <FormattedMessage id="premium.col.capabilities" />
                </th>
                <th>
                  <FormattedMessage id="premium.col.validity" />
                </th>
                <th>
                  <FormattedMessage id="premium.col.countries" />
                </th>
                <th>
                  <FormattedMessage id="col.scope" />
                </th>
                {editable && (
                  <th>
                    <span className="sr-only">
                      <FormattedMessage id="premium.col.actions" />
                    </span>
                  </th>
                )}
              </tr>
            </thead>
            <tbody>
              {list.map((c, i) => {
                const state = campaignState(c, now);
                return (
                  <tr key={`${c.id}-${i}`}>
                    <td>
                      <strong>{c.id}</strong>
                      <br />
                      <Pill tone={state.tone}>
                        <FormattedMessage id={state.id} />
                      </Pill>
                    </td>
                    <td>{capabilityList(intl, c.capabilities)}</td>
                    <td className="nowrap">
                      <Range from={c.validFrom} until={c.validUntil} />
                    </td>
                    <td>
                      {c.countries.length === 0 ? (
                        <span className="muted">
                          <FormattedMessage id="premium.beta.everyRegion" />
                        </span>
                      ) : (
                        c.countries.map((r) => countryName(intl.locale, r)).join(', ')
                      )}
                    </td>
                    <td>
                      <ScopeLabel c={c} />
                      {c.scope === 'internal' && (c.families?.length ?? 0) > 0 && (
                        <p className="muted">{c.families!.join(', ')}</p>
                      )}
                    </td>
                    {editable && (
                      <td>
                        <RowActions
                          label={intl.formatMessage({ id: 'premium.beta.actions' }, { id: c.id })}
                          actions={[
                            {
                              key: 'edit',
                              label: <FormattedMessage id="premium.beta.edit" />,
                              onSelect: () => onEdit(i),
                            },
                            {
                              key: 'remove',
                              label: <FormattedMessage id="premium.beta.remove" />,
                              onSelect: () => onRemove(i),
                              destructive: true,
                            },
                          ]}
                        />
                      </td>
                    )}
                  </tr>
                );
              })}
            </tbody>
          </table>
        </TableScroll>
      )}
    </Panel>
  );
}

function DayField({
  label,
  value,
  onChange,
}: {
  label: ReactNode;
  value: string;
  onChange: (day: string) => void;
}) {
  const id = useId();
  return (
    <div className="field">
      <label className="field__label" htmlFor={id}>
        {label}
      </label>
      <Input
        id={id}
        type="date"
        value={value}
        onChange={(e) => e.target.value && onChange(e.target.value)}
      />
    </div>
  );
}

/** Add / edit one Beta A campaign; it lands in the draft and is saved with the whole config. */
export function CampaignDialog({
  initial,
  index,
  all,
  regions,
  onClose,
  onApply,
}: {
  initial: BetaCampaign;
  index: number | null;
  all: readonly BetaCampaign[];
  regions: readonly string[];
  onClose: () => void;
  onApply: (c: BetaCampaign) => void;
}) {
  const intl = useIntl();
  const idField = useId();
  const percentField = useId();
  const [c, setC] = useState<BetaCampaign>(initial);
  const issues = campaignIssues(c, all, index);
  const countries = [...new Set([...regions, ...c.countries])];
  const toggle = <T,>(list: readonly T[], x: T, on: boolean) =>
    on ? [...new Set([...list, x])] : list.filter((y) => y !== x);
  return (
    <Modal
      wide
      title={
        <FormattedMessage
          id={index === null ? 'premium.beta.addTitle' : 'premium.beta.editTitle'}
          values={{ id: c.id }}
        />
      }
      onClose={onClose}
    >
      <div className="field">
        <label className="field__label" htmlFor={idField}>
          <FormattedMessage id="premium.beta.id" />
        </label>
        <Input
          id={idField}
          value={c.id}
          maxLength={40}
          disabled={index !== null}
          onChange={(e) => setC({ ...c, id: e.target.value.trim().toLowerCase() })}
        />
        <p className="field__help">
          <FormattedMessage id="premium.beta.idHelp" />
        </p>
      </div>
      <div className="field">
        <span className="field__label">
          <FormattedMessage id="premium.col.capabilities" />
        </span>
        {groupACapabilities.map((cap) => (
          <CheckRow
            key={cap}
            label={<FormattedMessage id={`premium.cap.${cap}`} />}
            checked={c.capabilities.includes(cap)}
            onChange={(on) => setC({ ...c, capabilities: toggle(c.capabilities, cap, on) })}
          />
        ))}
        <p className="field__help">
          <FormattedMessage id="premium.beta.noTemplates" />
        </p>
      </div>
      <div className="grid gap-4 sm:grid-cols-2">
        <DayField
          label={<FormattedMessage id="premium.beta.from" />}
          value={dayInput(c.validFrom)}
          onChange={(d) => setC({ ...c, validFrom: isoFromDay(d) })}
        />
        <DayField
          label={<FormattedMessage id="premium.beta.until" />}
          value={dayInput(c.validUntil, true)}
          onChange={(d) => setC({ ...c, validUntil: isoFromDay(d, true) })}
        />
      </div>
      <div className="field">
        <span className="field__label">
          <FormattedMessage id="premium.col.countries" />
        </span>
        {countries.length === 0 ? (
          <p className="field__help">
            <FormattedMessage id="premium.beta.noRegions" />
          </p>
        ) : (
          <>
            <div className="chips">
              {countries.map((r) => {
                const on = c.countries.includes(r);
                return (
                  <button
                    key={r}
                    type="button"
                    className={`chip ${on ? 'chip--on' : ''}`}
                    aria-pressed={on}
                    onClick={() => setC({ ...c, countries: toggle(c.countries, r, !on) })}
                  >
                    {countryName(intl.locale, r)}
                  </button>
                );
              })}
            </div>
            <p className="field__help">
              <FormattedMessage id="premium.beta.countriesHelp" />
            </p>
          </>
        )}
      </div>
      <div className="field">
        <span className="field__label">
          <FormattedMessage id="features.who" />
        </span>
        <Segmented
          value={c.scope}
          label={intl.formatMessage({ id: 'features.who' })}
          onChange={(scope) => setC({ ...c, scope })}
          options={(['internal', 'percent', 'all'] as const).map((s) => ({
            value: s,
            label: <FormattedMessage id={`premium.scope.${s}`} />,
          }))}
        />
        {c.scope === 'percent' && (
          <div className="field">
            <label className="field__label" htmlFor={percentField}>
              <FormattedMessage id="premium.beta.percent" />
            </label>
            <Input
              id={percentField}
              type="number"
              min={1}
              max={100}
              value={c.percent}
              onChange={(e) => setC({ ...c, percent: Math.round(Number(e.target.value) || 0) })}
            />
          </div>
        )}
        {c.scope === 'internal' && (
          <>
            <FamilyPicker
              value={c.families ?? []}
              onChange={(families) => setC({ ...c, families })}
            />
            <p className="field__help">
              <FormattedMessage id="premium.beta.internalHelp" />
            </p>
          </>
        )}
      </div>
      {issues.length > 0 && (
        <ul className="error">
          {issues.map((id) => (
            <li key={id}>
              <FormattedMessage id={id} />
            </li>
          ))}
        </ul>
      )}
      <p className="field__help">
        <FormattedMessage id="premium.beta.applyHelp" />
      </p>
      <div className="modal__actions">
        <Button onClick={onClose}>
          <FormattedMessage id="action.cancel" />
        </Button>
        <Button kind="primary" disabled={issues.length > 0} onClick={() => onApply(c)}>
          <FormattedMessage id="premium.beta.apply" />
        </Button>
      </div>
    </Modal>
  );
}

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
  const [reason, setReason] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const submit = async () => {
    setBusy(true);
    setError(null);
    const res = await savePremiumConfig(api, config, reason);
    setBusy(false);
    if (res.ok) onDone();
    else setError(res.error);
  };
  return (
    <Modal title={<FormattedMessage id="premium.saveTitle" />} onClose={onClose}>
      <p className="modal__sub">
        <FormattedMessage id="premium.saveEffect" />
      </p>
      <dl className="kv">
        <dt>
          <FormattedMessage id="premium.regions.advanced" />
        </dt>
        <dd>{config.regions.advanced.join(', ') || '—'}</dd>
        <dt>
          <FormattedMessage id="premium.beta.title" />
        </dt>
        <dd>{config.betaCampaigns.map((c) => c.id).join(', ') || '—'}</dd>
        <dt>
          <FormattedMessage id="premium.policyVersion" />
        </dt>
        <dd>{config.policyVersion}</dd>
      </dl>
      <ReasonField value={reason} onChange={setReason} required />
      {error && (
        <p className="error" role="alert">
          <FormattedMessage id={errorMessageId(error)} />
        </p>
      )}
      <div className="modal__actions">
        <Button onClick={onClose}>
          <FormattedMessage id="action.cancel" />
        </Button>
        <Button kind="primary" disabled={busy || !reasonOk(reason)} onClick={() => void submit()}>
          <FormattedMessage id="premium.saveConfirm" />
        </Button>
      </div>
    </Modal>
  );
}

function RecentPanel({ recent }: { recent: StaffPremiumView['recent'] }) {
  const intl = useIntl();
  return (
    <Panel title={<FormattedMessage id="features.recent" />}>
      {recent.length === 0 ? (
        <p className="muted">
          <FormattedMessage id="features.noRecent" />
        </p>
      ) : (
        <ul className="recent">
          {recent.map((r, i) => (
            <li key={i}>
              <p>
                <AuditActionText action={r.action} target={r.target} detail={null} />
              </p>
              <p className="muted">
                {r.by.split(' ')[0]} · {shortDate(intl, r.at)} · {r.reason}
              </p>
            </li>
          ))}
        </ul>
      )}
    </Panel>
  );
}

// ---------- Tra cứu gia đình ----------

function FamilyLookup({
  canGrant,
  onChanged,
  now,
  initial,
}: {
  canGrant: boolean;
  onChanged: () => void;
  now: Date;
  initial: StaffFamilyPremium | null;
}) {
  const intl = useIntl();
  const api = useApi();
  const [code, setCode] = useState(initial?.code ?? '');
  const [result, setResult] = useState<StaffFamilyPremium | null>(initial);
  const [busy, setBusy] = useState(false);
  const [problem, setProblem] = useState<string | null>(null);
  const [granting, setGranting] = useState(false);
  const [revoking, setRevoking] = useState<FamilyGrant | null>(null);
  const look = async (raw: string) => {
    const text = raw.trim().toUpperCase();
    if (!/^F-[A-Z2-9]{4}$/.test(text)) {
      setProblem('premium.lookup.hint');
      return;
    }
    setBusy(true);
    setProblem(null);
    try {
      setResult(await api.call<StaffFamilyPremium>('staffFamilyPremium', { code: text }));
    } catch (e) {
      setResult(null);
      setProblem(errorMessageId(asApiError(e)));
    } finally {
      setBusy(false);
    }
  };
  const done = () => {
    setGranting(false);
    setRevoking(null);
    if (result) void look(result.code);
    onChanged();
  };
  return (
    <Panel
      title={<FormattedMessage id="premium.lookup.title" />}
      note={<FormattedMessage id="premium.lookup.note" />}
    >
      <div className="family-picker__row">
        <Input
          value={code}
          onChange={(e) => setCode(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === 'Enter') {
              e.preventDefault();
              void look(code);
            }
          }}
          placeholder="F-7Q2K"
          aria-label={intl.formatMessage({ id: 'premium.lookup.code' })}
        />
        <Button kind="primary" disabled={busy || !code.trim()} onClick={() => void look(code)}>
          <FormattedMessage id="premium.lookup.go" />
        </Button>
      </div>
      {problem && (
        <p className="error" role="alert">
          <FormattedMessage id={problem} />
        </p>
      )}
      {result && (
        <FamilyPremiumResult
          result={result}
          canGrant={canGrant}
          onGrant={() => setGranting(true)}
          onRevoke={setRevoking}
        />
      )}
      {granting && result && (
        <GrantDialog
          code={result.code}
          now={now}
          onClose={() => setGranting(false)}
          onDone={done}
        />
      )}
      {revoking && result && (
        <RevokeDialog
          code={result.code}
          grant={revoking}
          onClose={() => setRevoking(null)}
          onDone={done}
        />
      )}
    </Panel>
  );
}

const planTone: Record<HouseholdPlan, PillTone> = {
  free: 'muted',
  beta: 'purple',
  premium: 'ok',
  pending: 'wait',
  expired: 'warn',
};

const statusTone: Record<FamilyGrant['status'], PillTone> = {
  pending: 'wait',
  active: 'ok',
  grace: 'warn',
  on_hold: 'warn',
  expired: 'muted',
  revoked: 'muted',
  refunded: 'muted',
};

/** One family's plan and grants; promo grants and revokes for owners and admins. */
export function FamilyPremiumResult({
  result,
  canGrant,
  onGrant,
  onRevoke,
}: {
  result: StaffFamilyPremium;
  canGrant: boolean;
  onGrant: () => void;
  onRevoke: (g: FamilyGrant) => void;
}) {
  const intl = useIntl();
  return (
    <div className="stack mt-4">
      <dl className="kv">
        <dt>
          <FormattedMessage id="premium.lookup.family" />
        </dt>
        <dd>{result.code}</dd>
        <dt>
          <FormattedMessage id="premium.lookup.plan" />
        </dt>
        <dd>
          <Pill tone={planTone[result.plan]}>
            <FormattedMessage id={`premium.plan.${result.plan}`} />
          </Pill>
          {result.validUntil && (
            <span className="muted">
              {' '}
              <FormattedMessage
                id="premium.lookup.until"
                values={{
                  until: fullDate(intl, new Date(Date.parse(result.validUntil) - 1).toISOString()),
                }}
              />
            </span>
          )}
        </dd>
        <dt>
          <FormattedMessage id="premium.lookup.country" />
        </dt>
        <dd>
          {result.country ? (
            `${countryName(intl.locale, result.country)} · ${result.country}`
          ) : (
            <span className="muted">
              <FormattedMessage id="premium.lookup.noCountry" />
            </span>
          )}
        </dd>
        <dt>
          <FormattedMessage id="premium.lookup.version" />
        </dt>
        <dd>{result.entitlementVersion}</dd>
      </dl>
      {result.grants.length === 0 ? (
        <p className="muted">
          <FormattedMessage id="premium.grants.none" />
        </p>
      ) : (
        <TableScroll min={820}>
          <table className="table">
            <thead>
              <tr>
                <th>
                  <FormattedMessage id="premium.col.source" />
                </th>
                <th>
                  <FormattedMessage id="premium.col.status" />
                </th>
                <th>
                  <FormattedMessage id="premium.col.capabilities" />
                </th>
                <th>
                  <FormattedMessage id="premium.col.validity" />
                </th>
                <th>
                  <FormattedMessage id="premium.col.provider" />
                </th>
                <th>
                  <FormattedMessage id="premium.col.autoRenew" />
                </th>
                {canGrant && (
                  <th>
                    <span className="sr-only">
                      <FormattedMessage id="premium.col.actions" />
                    </span>
                  </th>
                )}
              </tr>
            </thead>
            <tbody>
              {result.grants.map((g) => (
                <tr key={g.id}>
                  <td>
                    <strong>
                      <FormattedMessage id={`premium.source.${g.source}`} />
                    </strong>
                    {g.fromCampaign && (
                      <>
                        {' '}
                        <Pill tone="purple">
                          <FormattedMessage id="premium.grants.fromCampaign" />
                        </Pill>
                      </>
                    )}
                    <br />
                    <span className="muted">
                      <FormattedMessage id={`premium.env.${g.environment}`} />
                    </span>
                  </td>
                  <td>
                    <Pill tone={statusTone[g.status]}>
                      <FormattedMessage id={`premium.status.${g.status}`} />
                    </Pill>
                  </td>
                  <td>{capabilityList(intl, g.capabilities)}</td>
                  <td className="nowrap">
                    <Range from={g.validFrom} until={g.validUntil} />
                  </td>
                  <td>
                    {g.provider ? <FormattedMessage id={`premium.provider.${g.provider}`} /> : '—'}
                  </td>
                  <td>
                    {g.autoRenew === null ? (
                      '—'
                    ) : (
                      <FormattedMessage id={g.autoRenew ? 'premium.yes' : 'premium.no'} />
                    )}
                  </td>
                  {canGrant && (
                    <td>
                      {grantRevocable(g) && (
                        <Button kind="ghost" onClick={() => onRevoke(g)}>
                          <FormattedMessage id="premium.revoke" />
                        </Button>
                      )}
                    </td>
                  )}
                </tr>
              ))}
            </tbody>
          </table>
        </TableScroll>
      )}
      {canGrant && (
        <div>
          <Button onClick={onGrant}>
            <FormattedMessage id="premium.grant" />
          </Button>
        </div>
      )}
    </div>
  );
}

export function GrantDialog({
  code,
  now,
  onClose,
  onDone,
}: {
  code: string;
  now: Date;
  onClose: () => void;
  onDone: () => void;
}) {
  const api = useApi();
  const [caps, setCaps] = useState<Capability[]>([...groupACapabilities]);
  const [until, setUntil] = useState(() =>
    dayInput(new Date(now.getTime() + 30 * DAY).toISOString()),
  );
  const [reason, setReason] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const submit = async () => {
    setBusy(true);
    setError(null);
    try {
      await api.call<{ grantId: string }>('staffGrantPromo', {
        code,
        capabilities: premiumCapabilities.filter((c) => caps.includes(c)),
        validUntil: isoFromDay(until, true),
        reason: reason.trim(),
      });
      onDone();
    } catch (e) {
      setError(asApiError(e));
    } finally {
      setBusy(false);
    }
  };
  return (
    <Modal title={<FormattedMessage id="premium.grantTitle" values={{ code }} />} onClose={onClose}>
      <p className="modal__sub">
        <FormattedMessage id="premium.grantEffect" />
      </p>
      <div className="field">
        <span className="field__label">
          <FormattedMessage id="premium.col.capabilities" />
        </span>
        {premiumCapabilities.map((cap) => (
          <CheckRow
            key={cap}
            label={<FormattedMessage id={`premium.cap.${cap}`} />}
            checked={caps.includes(cap)}
            onChange={(on) => setCaps(on ? [...caps, cap] : caps.filter((c) => c !== cap))}
          />
        ))}
      </div>
      <DayField
        label={<FormattedMessage id="premium.beta.until" />}
        value={until}
        onChange={setUntil}
      />
      <ReasonField value={reason} onChange={setReason} required />
      {error && (
        <p className="error" role="alert">
          <FormattedMessage id={errorMessageId(error)} />
        </p>
      )}
      <div className="modal__actions">
        <Button onClick={onClose}>
          <FormattedMessage id="action.cancel" />
        </Button>
        <Button
          kind="primary"
          disabled={busy || caps.length === 0 || !reasonOk(reason)}
          onClick={() => void submit()}
        >
          <FormattedMessage id="premium.grantConfirm" />
        </Button>
      </div>
    </Modal>
  );
}

function RevokeDialog({
  code,
  grant,
  onClose,
  onDone,
}: {
  code: string;
  grant: FamilyGrant;
  onClose: () => void;
  onDone: () => void;
}) {
  const intl = useIntl();
  const api = useApi();
  const [reason, setReason] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const submit = async () => {
    setBusy(true);
    setError(null);
    try {
      await api.call('staffRevokeGrant', { code, grantId: grant.id, reason: reason.trim() });
      onDone();
    } catch (e) {
      setError(asApiError(e));
    } finally {
      setBusy(false);
    }
  };
  return (
    <Modal
      title={<FormattedMessage id="premium.revokeTitle" values={{ code }} />}
      icon={
        <span className="modal__alert" aria-hidden="true">
          !
        </span>
      }
      onClose={onClose}
    >
      <p className="modal__sub">
        <FormattedMessage id="premium.revokeEffect" />
      </p>
      <dl className="kv">
        <dt>
          <FormattedMessage id="premium.col.source" />
        </dt>
        <dd>
          <FormattedMessage id={`premium.source.${grant.source}`} />
        </dd>
        <dt>
          <FormattedMessage id="premium.col.capabilities" />
        </dt>
        <dd>{capabilityList(intl, grant.capabilities)}</dd>
        <dt>
          <FormattedMessage id="premium.col.validity" />
        </dt>
        <dd>
          <Range from={grant.validFrom} until={grant.validUntil} />
        </dd>
      </dl>
      <ReasonField value={reason} onChange={setReason} required />
      {error && (
        <p className="error" role="alert">
          <FormattedMessage id={errorMessageId(error)} />
        </p>
      )}
      <div className="modal__actions">
        <Button onClick={onClose}>
          <FormattedMessage id="action.cancel" />
        </Button>
        <Button kind="danger" disabled={busy || !reasonOk(reason)} onClick={() => void submit()}>
          <FormattedMessage id="premium.revoke" />
        </Button>
      </div>
    </Modal>
  );
}
