import {
  groupACapabilities,
  premiumCapabilities,
  staffCan,
  staffEntitlementsConfigSchema,
  type BetaCampaign,
  type Capability,
  type FlagKey,
  type GrantEnvironment,
  type HouseholdPlan,
  type StaffFamilyPremium,
  type StaffFamilyQuota,
} from '@child-life/contracts';
import { Plus, Search, Upload } from 'lucide-react';
import { useEffect, useId, useRef, useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl, type IntlShape } from 'react-intl';
import { toast } from 'sonner';
import { Badge } from '@/components/ui/badge';
import { Button as UiButton } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';
import {
  ApiError,
  useApi,
  useLoad,
  type Api,
  type FlagsView,
  type StaffPremiumConfig,
  type StaffPremiumView,
} from '../api';
import { EmptyState, Field, Notice, Section } from '../content-kit';
import { useStaff } from '../context';
import { ZONE } from '../format';
import {
  Button,
  Loaded,
  Modal,
  Page,
  Pill,
  ReasonField,
  RowActions,
  Segmented,
  TableScroll,
  errorMessageId,
  reasonOk,
  type PillTone,
} from '../ui';
import {
  BulkFamiliesDialog,
  FamilyAccessCard,
  FamilyPicker,
  RecentList,
  resolveFamilyCodes,
  type BulkInit,
} from './Features';
import { CheckRow, FieldSelect } from './form-controls';
import { AiPolicyLoader, FamilyQuotaView } from './PremiumOps';

/**
 * Premium & Cá nhân hoá (plan §5.6), in four tabs: beta campaigns, one family (what its app shows,
 * its grants, quota and store records), the configuration (advanced regions, video quotas, the
 * assistant credit pool) and the AI policy. Campaigns and configuration are one draft of
 * `config/entitlements`, saved together with a reason from the bar that shows while it is
 * unsaved. Every number is configuration, not a commercial commitment (Q-071); a beta campaign
 * may open any Premium feature (D-075 #1); health and logging stay free in every plan state.
 * Staff actions: `premium.view` / `premium.config` / `premium.grant` (owner, admin).
 */
export function PremiumScreen() {
  const [load, reload] = useLoad<StaffPremiumView>('staffPremium', {}, 'premium');
  return (
    <Page
      title={<FormattedMessage id="premium.title" />}
      subtitle={<FormattedMessage id="premium.sub" />}
      actions={load.status === 'ok' && <EnvPill env={load.data.environment} />}
    >
      <Loaded load={load} reload={reload}>
        {(data) => <PremiumBody data={data} onChanged={reload} />}
      </Loaded>
    </Page>
  );
}

export type PremiumTab = 'campaigns' | 'families' | 'config' | 'ai';
export const premiumTabs: PremiumTab[] = ['campaigns', 'families', 'config', 'ai'];

export function PremiumTabs({
  label,
  value,
  onChange,
  campaigns,
}: {
  label: string;
  value: PremiumTab;
  onChange: (t: PremiumTab) => void;
  /** Shown next to "Chiến dịch". */
  campaigns?: number;
}) {
  return (
    <Tabs value={value} onValueChange={(v) => onChange(v as PremiumTab)}>
      <TabsList aria-label={label}>
        {premiumTabs.map((t) => (
          <TabsTrigger key={t} value={t} className="px-3">
            <FormattedMessage id={`premium.tab.${t}`} />
            {t === 'campaigns' && campaigns !== undefined && (
              <span className="text-xs text-muted-foreground tabular-nums">{campaigns}</span>
            )}
          </TabsTrigger>
        ))}
      </TabsList>
    </Tabs>
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

/**
 * What a beta campaign may open (D-075 #1), grouped for the form: group A, Cao cấp templates, the
 * Premium assistant credit budget. Free capabilities never need a grant.
 */
export const campaignCapabilityGroups: readonly {
  id: 'groupA' | 'templates' | 'assistant';
  capabilities: readonly Capability[];
}[] = [
  { id: 'groupA', capabilities: groupACapabilities },
  { id: 'templates', capabilities: ['templates.premium'] },
  { id: 'assistant', capabilities: ['assistant.premium_budget'] },
];

/** Families travel only with "Gia đình được chọn"; the percent follows the scope. */
export function normalizeCampaign(c: BetaCampaign): BetaCampaign {
  const { families, ...rest } = c;
  return {
    ...rest,
    // Any Premium capability, in the canonical order; never a free one.
    capabilities: premiumCapabilities.filter((x) => c.capabilities.includes(x)),
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
  if (!c.capabilities.some((x) => premiumCapabilities.includes(x))) out.push('premium.issue.caps');
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

// ---------- Families picked for a campaign: will it reach them? ----------

/** The rollout flags a family needs to see what a campaign capability opens. */
export const capabilityUiFlags: Partial<Record<Capability, readonly FlagKey[]>> = {
  'personalization.cross_module': ['personalization'],
  'rhythm.advanced': ['rhythm', 'personalization'],
  'ai.assistance': ['ai_assist'],
  'assistant.premium_budget': ['assistant'],
};

export type CampaignFamilyIssue = {
  /** The family has no country, or one the campaign (or the open regions) does not cover. */
  country: 'none' | 'outside' | null;
  /** Flags the family still needs for what the campaign opens. */
  flags: FlagKey[];
};

/** Why a campaign would not show for a family, from its lookup (server truth for flags). */
export function campaignFamilyIssues(
  c: BetaCampaign,
  regions: readonly string[],
  family: StaffFamilyPremium,
): CampaignFamilyIssue {
  const covered = c.countries.length > 0 ? c.countries : regions;
  const country = !family.country
    ? 'none'
    : covered.includes(family.country) && regions.includes(family.country)
      ? null
      : 'outside';
  const needed = [...new Set(c.capabilities.flatMap((cap) => capabilityUiFlags[cap] ?? []))];
  const flags = family.access ? needed.filter((k) => !family.access!.flags[k]) : [];
  return { country, flags };
}

type FamilyCheck = StaffFamilyPremium | 'failed';

/** Looks the given families up once each (at most 12) and keeps the answers. */
export function useFamilyChecks(codes: readonly string[], version = 0) {
  const api = useApi();
  const [found, setFound] = useState<Record<string, FamilyCheck>>({});
  const asked = useRef(new Map<string, number>());
  const key = codes.slice(0, 12).join(',');
  useEffect(() => {
    let live = true;
    for (const code of key ? key.split(',') : []) {
      if (asked.current.get(code) === version) continue;
      asked.current.set(code, version);
      api
        .call<StaffFamilyPremium>('staffFamilyPremium', { code })
        .then((f) => live && setFound((m) => ({ ...m, [code]: f })))
        .catch(() => live && setFound((m) => ({ ...m, [code]: 'failed' })));
    }
    return () => {
      live = false;
    };
  }, [api, key, version]);
  return found;
}

/** One warning line per picked family the campaign will not reach as it is. */
function CampaignWarnings({
  campaign,
  regions,
  checks,
  canFix,
  onFix,
  onCheck,
}: {
  campaign: BetaCampaign;
  regions: readonly string[];
  checks: Record<string, FamilyCheck>;
  canFix: boolean;
  onFix: (code: string, keys: FlagKey[]) => void;
  /** Opens the family on the Gia đình tab. */
  onCheck?: (code: string) => void;
}) {
  const intl = useIntl();
  if (campaign.scope !== 'internal') return null;
  const rows = (campaign.families ?? [])
    .map((code) => ({ code, f: checks[code] }))
    .filter((r): r is { code: string; f: StaffFamilyPremium } => !!r.f && r.f !== 'failed')
    .map((r) => ({ ...r, issue: campaignFamilyIssues(campaign, regions, r.f) }))
    .filter((r) => r.issue.country || r.issue.flags.length);
  if (!rows.length) return null;
  return (
    <Notice tone="warn" title={<FormattedMessage id="premium.warn.title" />}>
      <ul className="mt-1 grid gap-1.5">
        {rows.map(({ code, f, issue }) => (
          <li key={code} className="flex flex-wrap items-center gap-x-2 gap-y-1">
            <span className="font-mono font-semibold">{code}</span>
            <span>
              {[
                issue.country === 'none'
                  ? intl.formatMessage({ id: 'premium.warn.noCountry' })
                  : issue.country === 'outside'
                    ? intl.formatMessage(
                        { id: 'premium.warn.outside' },
                        { country: countryName(intl.locale, f.country!) },
                      )
                    : null,
                issue.flags.length
                  ? intl.formatMessage(
                      { id: 'premium.warn.flags' },
                      {
                        flags: issue.flags
                          .map((k) => intl.formatMessage({ id: `flag.${k}` }))
                          .join(', '),
                      },
                    )
                  : null,
              ]
                .filter(Boolean)
                .join(' · ')}
            </span>
            {canFix && issue.flags.length > 0 && (
              <UiButton
                variant="link"
                size="sm"
                className="h-auto p-0"
                onClick={() => onFix(code, issue.flags)}
              >
                <FormattedMessage id="premium.warn.fix" />
              </UiButton>
            )}
            {onCheck && (
              <UiButton
                variant="link"
                size="sm"
                className="h-auto p-0"
                onClick={() => onCheck(code)}
              >
                <FormattedMessage id="premium.warn.check" />
              </UiButton>
            )}
          </li>
        ))}
      </ul>
    </Notice>
  );
}

// ---------- The screen ----------

export function PremiumBody({
  data,
  onChanged,
  now = new Date(),
  initialFamily = null,
  initialQuota = null,
  initialTab,
}: {
  data: StaffPremiumView;
  onChanged: () => void;
  now?: Date;
  /** A looked-up family (tests). */
  initialFamily?: StaffFamilyPremium | null;
  /** That family's quota and billing (tests). */
  initialQuota?: StaffFamilyQuota | null;
  initialTab?: PremiumTab;
}) {
  const intl = useIntl();
  const staff = useStaff();
  const canConfig = staffCan(staff.levels, 'premium.config');
  const canGrant = staffCan(staff.levels, 'premium.grant');
  const canFlags = staffCan(staff.levels, 'flags.rollout');
  const [tab, setTab] = useState<PremiumTab>(
    initialTab ?? (initialFamily ? 'families' : 'campaigns'),
  );
  const saved = JSON.stringify(data.config);
  const [draft, setDraft] = useState<StaffPremiumConfig>(data.config);
  // A reload after a grant keeps unsaved edits; a new stored config replaces them.
  useEffect(() => setDraft(JSON.parse(saved) as StaffPremiumConfig), [saved]);
  const dirty = JSON.stringify(draft) !== saved;
  const [editing, setEditing] = useState<{ index: number | null; campaign: BetaCampaign } | null>(
    null,
  );
  const [saving, setSaving] = useState(false);
  const [flagsLoad, reloadFlags] = useLoad<FlagsView>('staffFlags', {}, 'flags');
  const flags = flagsLoad.status === 'ok' ? flagsLoad.data.flags : null;
  const [bulk, setBulk] = useState<BulkInit | null>(null);
  // Bumped after flags change, so the family checks ask again.
  const [checkVersion, setCheckVersion] = useState(0);
  const [lookFor, setLookFor] = useState<string | null>(null);
  const campaignCodes = [
    ...new Set(
      draft.betaCampaigns.flatMap((c) => (c.scope === 'internal' ? (c.families ?? []) : [])),
    ),
  ];
  const checks = useFamilyChecks(campaignCodes, checkVersion);
  const openRegion = (country: string) => {
    if (draft.regions.advanced.includes(country)) return;
    setDraft({ ...draft, regions: { advanced: [...draft.regions.advanced, country] } });
    toast.info(
      intl.formatMessage(
        { id: 'premium.regionAdded' },
        { country: countryName(intl.locale, country) },
      ),
    );
  };
  return (
    <div className="grid gap-4">
      <PremiumTabs
        label={intl.formatMessage({ id: 'premium.tabs' })}
        value={tab}
        onChange={setTab}
        campaigns={draft.betaCampaigns.length}
      />
      {canConfig && dirty && (tab === 'campaigns' || tab === 'config' || tab === 'families') && (
        <SaveBar
          config={draft}
          saved={JSON.parse(saved) as StaffPremiumConfig}
          onDiscard={() => setDraft(JSON.parse(saved) as StaffPremiumConfig)}
          onSave={() => setSaving(true)}
        />
      )}
      {!data.stored && tab !== 'ai' && (
        <Notice tone="info">
          <FormattedMessage id="premium.notStored" />
        </Notice>
      )}
      {!canConfig && (tab === 'campaigns' || tab === 'config') && (
        <Notice tone="info">
          <FormattedMessage id="premium.readOnly" />
        </Notice>
      )}
      {tab === 'campaigns' && (
        <CampaignsSection
          config={draft}
          editable={canConfig}
          now={now}
          checks={checks}
          canFix={canFlags && !!flags}
          onFix={(code, keys) => setBulk({ families: [code], keys })}
          onCheck={(code) => {
            setLookFor(code);
            setTab('families');
          }}
          onAdd={() => setEditing({ index: null, campaign: blankCampaign(now) })}
          onEdit={(index) => setEditing({ index, campaign: draft.betaCampaigns[index]! })}
          onRemove={(index) =>
            setDraft({ ...draft, betaCampaigns: draft.betaCampaigns.filter((_, i) => i !== index) })
          }
        />
      )}
      {tab === 'families' && (
        <FamilyLookup
          key={lookFor ?? 'lookup'}
          canGrant={canGrant}
          canFlags={canFlags}
          canConfig={canConfig}
          regions={draft.regions.advanced}
          flags={flags}
          checkVersion={checkVersion}
          onChanged={onChanged}
          onEnable={(code, keys) => setBulk({ families: [code], keys })}
          onOpenRegion={openRegion}
          now={now}
          initial={initialFamily}
          initialQuota={initialQuota}
          initialCode={lookFor}
        />
      )}
      {tab === 'config' && (
        <ConfigSections
          config={draft}
          editable={canConfig}
          onChange={setDraft}
          recent={data.recent}
        />
      )}
      {tab === 'ai' && (
        // Plan §5.6 "AI policy": the limits themselves are edited on the Cấu hình tab.
        <AiPolicyLoader onOpenLimits={() => setTab('config')} />
      )}
      {editing && (
        <CampaignDialog
          initial={editing.campaign}
          index={editing.index}
          all={draft.betaCampaigns}
          regions={draft.regions.advanced}
          checkVersion={checkVersion}
          canFix={canFlags && !!flags}
          onFix={(code, keys) => setBulk({ families: [code], keys })}
          onClose={() => setEditing(null)}
          onApply={(c) => {
            setDraft(withCampaign(draft, c, editing.index));
            setEditing(null);
            toast.info(intl.formatMessage({ id: 'premium.beta.applied' }));
          }}
        />
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
      {bulk && flags && (
        <BulkFamiliesDialog
          flags={flags}
          initial={bulk}
          onClose={() => setBulk(null)}
          onDone={() => {
            setBulk(null);
            reloadFlags();
            setCheckVersion((v) => v + 1);
          }}
        />
      )}
    </div>
  );
}

/** What changed in the draft, in a few words: "1 chiến dịch, khu vực mở". */
export function draftChanges(saved: StaffPremiumConfig, draft: StaffPremiumConfig): string[] {
  const out: string[] = [];
  const ids = new Set([...saved.betaCampaigns, ...draft.betaCampaigns].map((c) => c.id));
  const changed = [...ids].filter((id) => {
    const a = saved.betaCampaigns.find((c) => c.id === id);
    const b = draft.betaCampaigns.find((c) => c.id === id);
    return JSON.stringify(a) !== JSON.stringify(b);
  }).length;
  if (changed) out.push(`campaigns:${changed}`);
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
  const parts = draftChanges(saved, config).map((c) => {
    const [what, n] = c.split(':');
    return intl.formatMessage({ id: `premium.changed.${what}` }, { n: Number(n ?? 0) });
  });
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

/** Cấu hình: open regions, video quotas, assistant credits, policy version, rules, history. */
function ConfigSections({
  config,
  editable,
  onChange,
  recent,
}: {
  config: StaffPremiumConfig;
  editable: boolean;
  onChange: (c: StaffPremiumConfig) => void;
  recent: StaffPremiumView['recent'];
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
      <Section
        collapsible
        defaultOpen={false}
        title={<FormattedMessage id="features.recent" />}
        summary={<FormattedMessage id="features.recentCount" values={{ n: recent.length }} />}
      >
        <RecentList recent={recent} />
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
    <span className="text-muted-foreground">
      <FormattedMessage id="scope.all" />
    </span>
  );
}

function CampaignsSection({
  config,
  editable,
  now,
  checks,
  canFix,
  onFix,
  onCheck,
  onAdd,
  onEdit,
  onRemove,
}: {
  config: StaffPremiumConfig;
  editable: boolean;
  now: Date;
  checks: Record<string, FamilyCheck>;
  canFix: boolean;
  onFix: (code: string, keys: FlagKey[]) => void;
  onCheck: (code: string) => void;
  onAdd: () => void;
  onEdit: (index: number) => void;
  onRemove: (index: number) => void;
}) {
  const intl = useIntl();
  const list = config.betaCampaigns;
  return (
    <Section
      flush
      title={<FormattedMessage id="premium.beta.title" />}
      description={<FormattedMessage id="premium.beta.note" />}
      actions={
        editable &&
        list.length < 20 && (
          <Button kind="primary" onClick={onAdd}>
            <Plus />
            <FormattedMessage id="premium.beta.add" />
          </Button>
        )
      }
    >
      {list.length === 0 ? (
        <EmptyState icon={Upload} title={<FormattedMessage id="premium.beta.none" />} />
      ) : (
        <ul className="divide-y">
          {list.map((c, i) => {
            const state = campaignState(c, now);
            return (
              <li key={`${c.id}-${i}`} className="grid gap-2 px-5 py-4">
                <div className="flex flex-wrap items-center gap-x-3 gap-y-1">
                  <strong className="font-mono text-[15px]">{c.id}</strong>
                  <Pill tone={state.tone}>
                    <FormattedMessage id={state.id} />
                  </Pill>
                  <span className="text-sm text-muted-foreground tabular-nums">
                    <Range from={c.validFrom} until={c.validUntil} />
                  </span>
                  {editable && (
                    <span className="ml-auto">
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
                    </span>
                  )}
                </div>
                <div className="flex flex-wrap gap-1.5">
                  {c.capabilities.map((cap) => (
                    <Badge key={cap} variant="outline" className="font-normal">
                      <FormattedMessage id={`premium.cap.${cap}`} />
                    </Badge>
                  ))}
                </div>
                <div className="flex flex-wrap items-center gap-x-4 gap-y-1 text-sm">
                  <span>
                    <span className="text-muted-foreground">
                      <FormattedMessage id="premium.col.countries" />:
                    </span>{' '}
                    {c.countries.length === 0 ? (
                      <FormattedMessage id="premium.beta.everyRegion" />
                    ) : (
                      c.countries.map((r) => countryName(intl.locale, r)).join(', ')
                    )}
                  </span>
                  <span className="flex flex-wrap items-center gap-1.5">
                    <span className="text-muted-foreground">
                      <FormattedMessage id="features.who" />:
                    </span>
                    <ScopeLabel c={c} />
                    {c.scope === 'internal' &&
                      (c.families ?? []).map((code) => (
                        <button
                          key={code}
                          type="button"
                          className="rounded-md bg-secondary px-1.5 py-0.5 font-mono text-xs hover:bg-accent"
                          title={intl.formatMessage({ id: 'premium.warn.check' })}
                          onClick={() => onCheck(code)}
                        >
                          {code}
                        </button>
                      ))}
                  </span>
                </div>
                <CampaignWarnings
                  campaign={c}
                  regions={config.regions.advanced}
                  checks={checks}
                  canFix={canFix}
                  onFix={onFix}
                  onCheck={onCheck}
                />
              </li>
            );
          })}
        </ul>
      )}
    </Section>
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
    <Field label={label} htmlFor={id}>
      <Input
        id={id}
        type="date"
        value={value}
        onChange={(e) => e.target.value && onChange(e.target.value)}
      />
    </Field>
  );
}

/** Add / edit one Beta A campaign; it lands in the draft and is saved with the whole config. */
export function CampaignDialog({
  initial,
  index,
  all,
  regions,
  checkVersion = 0,
  canFix = false,
  onFix = () => undefined,
  onClose,
  onApply,
}: {
  initial: BetaCampaign;
  index: number | null;
  all: readonly BetaCampaign[];
  regions: readonly string[];
  checkVersion?: number;
  canFix?: boolean;
  onFix?: (code: string, keys: FlagKey[]) => void;
  onClose: () => void;
  onApply: (c: BetaCampaign) => void;
}) {
  const intl = useIntl();
  const idField = useId();
  const percentField = useId();
  const [c, setC] = useState<BetaCampaign>(initial);
  const issues = campaignIssues(c, all, index);
  const countries = [...new Set([...regions, ...c.countries])];
  const checks = useFamilyChecks(c.scope === 'internal' ? (c.families ?? []) : [], checkVersion);
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
      <Field
        htmlFor={idField}
        label={<FormattedMessage id="premium.beta.id" />}
        help={<FormattedMessage id="premium.beta.idHelp" />}
      >
        <Input
          id={idField}
          className="font-mono"
          value={c.id}
          maxLength={40}
          disabled={index !== null}
          onChange={(e) => setC({ ...c, id: e.target.value.trim().toLowerCase() })}
        />
      </Field>
      <fieldset className="grid gap-2">
        <legend className="mb-1.5 text-[13px] font-medium">
          <FormattedMessage id="premium.col.capabilities" />
        </legend>
        {/* D-075 #1: any Premium feature, grouped; roles never change with a plan. */}
        <div className="grid gap-3 sm:grid-cols-3">
          {campaignCapabilityGroups.map((g) => (
            <div
              key={g.id}
              className="grid content-start gap-1.5 rounded-lg border p-3"
              role="group"
              aria-label={intl.formatMessage({ id: `premium.capGroup.${g.id}` })}
            >
              <span className="text-xs font-semibold text-muted-foreground">
                <FormattedMessage id={`premium.capGroup.${g.id}`} />
              </span>
              {g.capabilities.map((cap) => (
                <CheckRow
                  key={cap}
                  label={
                    <span className="text-sm">
                      <FormattedMessage id={`premium.cap.${cap}`} />
                    </span>
                  }
                  checked={c.capabilities.includes(cap)}
                  onChange={(on) => setC({ ...c, capabilities: toggle(c.capabilities, cap, on) })}
                />
              ))}
              {g.id !== 'groupA' && (
                <p className="text-xs text-muted-foreground">
                  <FormattedMessage id={`premium.capHelp.${g.id}`} />
                </p>
              )}
            </div>
          ))}
        </div>
        <p className="text-xs text-muted-foreground">
          <FormattedMessage id="premium.beta.capsHelp" />
        </p>
      </fieldset>
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
      <div className="grid gap-2">
        <span className="text-[13px] font-medium">
          <FormattedMessage id="premium.col.countries" />
        </span>
        {countries.length === 0 ? (
          <p className="text-xs text-muted-foreground">
            <FormattedMessage id="premium.beta.noRegions" />
          </p>
        ) : (
          <>
            <div className="flex flex-wrap gap-2">
              {countries.map((r) => {
                const on = c.countries.includes(r);
                return (
                  <UiButton
                    key={r}
                    type="button"
                    size="sm"
                    variant={on ? 'default' : 'outline'}
                    className="rounded-full"
                    aria-pressed={on}
                    onClick={() => setC({ ...c, countries: toggle(c.countries, r, !on) })}
                  >
                    {countryName(intl.locale, r)}
                  </UiButton>
                );
              })}
            </div>
            <p className="text-xs text-muted-foreground">
              <FormattedMessage id="premium.beta.countriesHelp" />
            </p>
          </>
        )}
      </div>
      <div className="grid gap-2">
        <span className="text-[13px] font-medium">
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
          <Field
            className="max-w-48"
            htmlFor={percentField}
            label={<FormattedMessage id="premium.beta.percent" />}
          >
            <Input
              id={percentField}
              type="number"
              min={1}
              max={100}
              value={c.percent}
              onChange={(e) => setC({ ...c, percent: Math.round(Number(e.target.value) || 0) })}
            />
          </Field>
        )}
        {c.scope === 'internal' && (
          <>
            <FamilyPicker
              value={c.families ?? []}
              onChange={(families) => setC({ ...c, families })}
            />
            <p className="text-xs text-muted-foreground">
              <FormattedMessage id="premium.beta.internalHelp" />
            </p>
            <CampaignWarnings
              campaign={c}
              regions={regions}
              checks={checks}
              canFix={canFix}
              onFix={onFix}
            />
          </>
        )}
      </div>
      {issues.length > 0 && (
        <Notice tone="error">
          <ul className="grid gap-0.5">
            {issues.map((id) => (
              <li key={id}>
                <FormattedMessage id={id} />
              </li>
            ))}
          </ul>
        </Notice>
      )}
      <div className="modal__actions">
        <span className="mr-auto self-center text-xs text-muted-foreground">
          <FormattedMessage id="premium.beta.applyHelp" />
        </span>
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
  const intl = useIntl();
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
      <p className="text-sm text-muted-foreground">
        <FormattedMessage id="premium.saveEffect" />
      </p>
      <dl className="kv">
        <dt>
          <FormattedMessage id="premium.regions.advanced" />
        </dt>
        <dd>{config.regions.advanced.map((r) => countryName(intl.locale, r)).join(', ') || '—'}</dd>
        <dt>
          <FormattedMessage id="premium.beta.title" />
        </dt>
        <dd>{config.betaCampaigns.map((c) => c.id).join(', ') || '—'}</dd>
      </dl>
      <ReasonField value={reason} onChange={setReason} required />
      {error && (
        <Notice tone="error">
          <FormattedMessage id={errorMessageId(error)} />
        </Notice>
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

// ---------- Tra cứu gia đình ----------

/**
 * One family's grants and, in a call of its own, its quota & billing (plan §5.6): a failure of
 * the second never hides the first.
 */
export async function lookupFamily(
  api: Api,
  code: string,
): Promise<
  | { ok: true; premium: StaffFamilyPremium; quota: StaffFamilyQuota | 'failed' }
  | { ok: false; problem: string }
> {
  try {
    const [premium, quota] = await Promise.all([
      api.call<StaffFamilyPremium>('staffFamilyPremium', { code }),
      api.call<StaffFamilyQuota>('staffFamilyQuota', { code }).catch(() => 'failed' as const),
    ]);
    return { ok: true, premium, quota };
  } catch (e) {
    return { ok: false, problem: errorMessageId(asApiError(e)) };
  }
}

function FamilyLookup({
  canGrant,
  canFlags,
  canConfig,
  regions,
  flags,
  checkVersion,
  onChanged,
  onEnable,
  onOpenRegion,
  now,
  initial,
  initialQuota,
  initialCode,
}: {
  canGrant: boolean;
  canFlags: boolean;
  canConfig: boolean;
  regions: readonly string[];
  flags: FlagsView['flags'] | null;
  checkVersion: number;
  onChanged: () => void;
  onEnable: (code: string, keys: FlagKey[]) => void;
  onOpenRegion: (country: string) => void;
  now: Date;
  initial: StaffFamilyPremium | null;
  initialQuota: StaffFamilyQuota | null;
  /** Looked up at once (a family picked on the Chiến dịch tab). */
  initialCode: string | null;
}) {
  const intl = useIntl();
  const api = useApi();
  const [code, setCode] = useState(initialCode ?? initial?.code ?? '');
  const [result, setResult] = useState<StaffFamilyPremium | null>(initial);
  // Quota & thanh toán: its own call, so a failure there never hides the grants.
  const [quota, setQuota] = useState<StaffFamilyQuota | 'failed' | null>(initialQuota);
  const [busy, setBusy] = useState(false);
  const [problem, setProblem] = useState<string | null>(null);
  const [granting, setGranting] = useState(false);
  const [revoking, setRevoking] = useState<FamilyGrant | null>(null);
  const look = async (raw: string) => {
    if (!raw.trim()) return;
    setBusy(true);
    setProblem(null);
    const found = await resolveFamilyCodes(api, raw);
    if ('problem' in found) {
      setProblem(found.problem);
      setBusy(false);
      return;
    }
    const answer = await lookupFamily(api, found.codes[0]!);
    if (answer.ok) {
      setResult(answer.premium);
      setQuota(answer.quota);
    } else {
      setResult(null);
      setQuota(null);
      setProblem(answer.problem);
    }
    setBusy(false);
  };
  // A family opened from a campaign, and a fresh look after its flags change.
  const asked = useRef<string | null>(null);
  useEffect(() => {
    const target = result?.code ?? initialCode;
    const k = `${target}:${checkVersion}`;
    if (!target || asked.current === k || (checkVersion === 0 && !initialCode)) return;
    asked.current = k;
    void look(target);
  }, [initialCode, checkVersion]);
  const done = () => {
    setGranting(false);
    setRevoking(null);
    if (result) void look(result.code);
    onChanged();
  };
  const country = result?.country ?? null;
  return (
    <div className="grid gap-4">
      <Section
        title={<FormattedMessage id="premium.lookup.title" />}
        description={<FormattedMessage id="premium.lookup.note" />}
      >
        <div className="flex max-w-xl gap-2">
          <div className="relative flex-1">
            <Search
              className="pointer-events-none absolute top-1/2 left-2.5 size-4 -translate-y-1/2 text-muted-foreground"
              aria-hidden="true"
            />
            <Input
              className="pl-8"
              value={code}
              onChange={(e) => setCode(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') {
                  e.preventDefault();
                  void look(code);
                }
              }}
              placeholder={intl.formatMessage({ id: 'features.familyFind' })}
              aria-label={intl.formatMessage({ id: 'premium.lookup.code' })}
            />
          </div>
          <Button kind="primary" disabled={busy || !code.trim()} onClick={() => void look(code)}>
            <FormattedMessage id="premium.lookup.go" />
          </Button>
        </div>
        {problem && (
          <p className="mt-2 text-sm text-destructive" role="alert">
            <FormattedMessage id={problem} />
          </p>
        )}
        {result && (
          <div className="mt-4 grid gap-4">
            <FamilyPremiumResult
              result={result}
              canGrant={canGrant}
              onGrant={() => setGranting(true)}
              onRevoke={setRevoking}
            />
          </div>
        )}
      </Section>
      {result?.access && flags && (
        <Section
          title={<FormattedMessage id="premium.access.title" />}
          description={<FormattedMessage id="premium.access.sub" />}
        >
          <FamilyAccessCard
            family={result}
            flags={flags}
            canEnable={canFlags}
            showHeader={false}
            onEnable={(keys) => onEnable(result.code, keys)}
            regionAction={
              canConfig && country && !regions.includes(country) ? (
                <UiButton size="sm" variant="outline" onClick={() => onOpenRegion(country)}>
                  <FormattedMessage
                    id="premium.access.openRegion"
                    values={{ country: countryName(intl.locale, country) }}
                  />
                </UiButton>
              ) : undefined
            }
            premiumAction={
              canGrant ? (
                <UiButton
                  variant="ghost"
                  size="sm"
                  className="h-7 text-primary"
                  onClick={() => setGranting(true)}
                >
                  <FormattedMessage id="premium.access.grant" />
                </UiButton>
              ) : undefined
            }
          />
        </Section>
      )}
      {result && quota === 'failed' && (
        <Notice tone="warn">
          <FormattedMessage id="premium.fq.error" />
        </Notice>
      )}
      {result && quota && quota !== 'failed' && quota.code === result.code && (
        <FamilyQuotaView data={quota} now={now} />
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
    </div>
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
    <div className="grid gap-4">
      <div className="flex flex-wrap items-center gap-x-6 gap-y-2 text-sm">
        <span className="font-mono text-base font-semibold">{result.code}</span>
        <span className="flex items-center gap-1.5">
          <span className="text-muted-foreground">
            <FormattedMessage id="premium.lookup.plan" />
          </span>
          <Pill tone={planTone[result.plan]}>
            <FormattedMessage id={`premium.plan.${result.plan}`} />
          </Pill>
          {result.validUntil && (
            <span className="text-muted-foreground">
              <FormattedMessage
                id="premium.lookup.until"
                values={{
                  until: fullDate(intl, new Date(Date.parse(result.validUntil) - 1).toISOString()),
                }}
              />
            </span>
          )}
        </span>
        <span>
          <span className="text-muted-foreground">
            <FormattedMessage id="premium.lookup.country" />
          </span>{' '}
          {result.country ? (
            `${countryName(intl.locale, result.country)} · ${result.country}`
          ) : (
            <span className="text-muted-foreground">
              <FormattedMessage id="premium.lookup.noCountry" />
            </span>
          )}
        </span>
        <span className="text-muted-foreground">
          <FormattedMessage id="premium.lookup.version" /> {result.entitlementVersion}
        </span>
        {canGrant && (
          <UiButton size="sm" variant="outline" className="ml-auto" onClick={onGrant}>
            <Plus />
            <FormattedMessage id="premium.grant" />
          </UiButton>
        )}
      </div>
      {result.grants.length === 0 ? (
        <p className="text-sm text-muted-foreground">
          <FormattedMessage id="premium.grants.none" />
        </p>
      ) : (
        <div className="overflow-hidden rounded-lg border">
          <TableScroll min={760}>
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
                      <span className="flex flex-wrap items-center gap-1.5 font-medium">
                        <FormattedMessage id={`premium.source.${g.source}`} />
                        {g.fromCampaign && (
                          <Pill tone="purple">
                            <FormattedMessage id="premium.grants.fromCampaign" />
                          </Pill>
                        )}
                      </span>
                      <span className="block text-xs text-muted-foreground">
                        <FormattedMessage id={`premium.env.${g.environment}`} />
                      </span>
                    </td>
                    <td>
                      <Pill tone={statusTone[g.status]}>
                        <FormattedMessage id={`premium.status.${g.status}`} />
                      </Pill>
                    </td>
                    <td className="max-w-[18rem]">{capabilityList(intl, g.capabilities)}</td>
                    <td className="nowrap tabular-nums">
                      <Range from={g.validFrom} until={g.validUntil} />
                    </td>
                    <td>
                      {g.provider ? (
                        <FormattedMessage id={`premium.provider.${g.provider}`} />
                      ) : (
                        '—'
                      )}
                      {g.autoRenew !== null && (
                        <span className="block text-xs text-muted-foreground">
                          <FormattedMessage id="premium.col.autoRenew" />:{' '}
                          <FormattedMessage id={g.autoRenew ? 'premium.yes' : 'premium.no'} />
                        </span>
                      )}
                    </td>
                    {canGrant && (
                      <td className="cell-actions">
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
