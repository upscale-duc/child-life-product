import {
  featureTiers,
  staffCan,
  systemFlagKeys,
  type Capability,
  type FeatureKey,
  type FeatureTier,
  type Flag,
  type FlagKey,
  type StaffFeatureHub,
  type StaffHubFlagState,
  type StaffHubRow,
  type StaffHubTierAnswer,
} from '@child-life/contracts';
import { PanelRightOpen, Search } from 'lucide-react';
import { useEffect, useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { toast } from 'sonner';
import { Badge } from '@/components/ui/badge';
import { Button as UiButton } from '@/components/ui/button';
import { Sheet, SheetContent, SheetTitle } from '@/components/ui/sheet';
import { Switch } from '@/components/ui/switch';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { ToggleGroup, ToggleGroupItem } from '@/components/ui/toggle-group';
import { cn } from '@/lib/utils';
import {
  ApiError,
  useApi,
  useLoad,
  type Api,
  type AuditRow,
  type FlagsView,
  type HubRolloutRequest,
} from '../api';
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
import { routePaths, subPath, useNavigate, useStaff } from '../context';
import { ZONE, num, shortDate } from '../format';
import {
  Button,
  Loaded,
  Modal,
  Page,
  Pill,
  Segmented,
  SelectMenu,
  TableScroll,
  errorMessageId,
} from '../ui';
import { AuditTable } from './Audit';
import {
  FamilyPicker,
  LimitsList,
  NoticeField,
  RecentList,
  billingFlag,
  defaultNotice,
} from './Features';
import { HubFamilies, TierPill } from './HubFamily';
import { PremiumPlanLoader } from './Premium';
import { PremiumOverviewLoader } from './PremiumOverview';

/**
 * "Tính năng & Premium" (D-089, `docs/product/features-premium-hub-plan.md`): one hub instead of
 * Tính năng & phát hành, Premium and the personalization switches. Tabs: Tính năng (ONE list of
 * the catalogue features and the engineering switches, owner 2026-10-21: Gói, Ai được dùng, Bật),
 * Gia đình (one family's features and why, overrides, beta, "Bật toàn bộ Premium"), Gói Premium
 * (billing, regions, quotas, the AI policy) and Lịch sử. The rule of plan §2.2 runs on the server
 * (`decideFeature`); the portal shows its answer. No reason is asked anywhere (D-090).
 */

export const hubTabs = ['overview', 'features', 'families', 'plan', 'history'] as const;
export type HubTab = (typeof hubTabs)[number];
const hubTabPath: Record<HubTab, string> = {
  overview: 'overview',
  features: '',
  families: 'families',
  plan: 'plan',
  history: 'history',
};

/** The tab an address opens ("/features/plan"; "/premium" was the Premium page). */
export function hubTabOf(pathname: string): HubTab {
  const [first] = subPath('features', pathname);
  return hubTabs.find((t) => first !== undefined && hubTabPath[t] === first) ?? 'features';
}

export function FeatureHubScreen({ initialTab }: { initialTab?: HubTab }) {
  const intl = useIntl();
  const [tab, setTab] = useState<HubTab>(() => initialTab ?? hubTabOf(window.location.pathname));
  useEffect(() => {
    const path = hubTabPath[tab]
      ? `${routePaths.features}/${hubTabPath[tab]}`
      : routePaths.features;
    if (window.location.pathname !== path) window.history.replaceState({}, '', path);
  }, [tab]);
  return (
    <Page title={<FormattedMessage id="hub.title" />} info={<HubRules />}>
      <Tabs value={tab} onValueChange={(t) => setTab(t as HubTab)} className="min-w-0 gap-4">
        <TabsList aria-label={intl.formatMessage({ id: 'hub.tabs' })} className="max-w-full">
          {hubTabs.map((t) => (
            <TabsTrigger key={t} value={t} className="px-3">
              <FormattedMessage id={`hub.tab.${t}`} />
            </TabsTrigger>
          ))}
        </TabsList>
        <TabsContent value="overview" className="min-w-0">
          {/* PT01 Tổng quan Premium (D-101): counts only. */}
          <PremiumOverviewLoader
            onOpenJobs={() => {
              window.history.pushState({}, '', routePaths.jobs);
              window.dispatchEvent(new PopStateEvent('popstate'));
            }}
          />
        </TabsContent>
        <TabsContent value="features" className="min-w-0">
          <HubFeaturesLoader />
        </TabsContent>
        <TabsContent value="families" className="min-w-0">
          <HubFamilies />
        </TabsContent>
        <TabsContent value="plan" className="min-w-0">
          <PremiumPlanLoader />
        </TabsContent>
        <TabsContent value="history" className="min-w-0">
          <HubHistoryLoader />
        </TabsContent>
      </Tabs>
    </Page>
  );
}

/** Plan §2.2, the rule every row follows, behind the page's "i". */
function HubRules() {
  return (
    <>
      <p className="font-medium text-foreground">
        <FormattedMessage id="hub.rules.title" />
      </p>
      <ol className="grid list-decimal gap-1 pl-5">
        {(['kill', 'override', 'premium', 'beta', 'free'] as const).map((k) => (
          <li key={k}>
            <FormattedMessage id={`hub.rules.${k}`} />
          </li>
        ))}
      </ol>
    </>
  );
}

// ---------- Calls (no reason: D-090) ----------

/** The confirmation's count: `staffFeatureSetTier` with `dryRun`, which writes nothing. */
export function previewTierChange(api: Api, feature: FeatureKey, tier: FeatureTier) {
  return api.call<StaffHubTierAnswer>('staffFeatureSetTier', { feature, tier, dryRun: true });
}

/** Changes the tier; a move to Premium keeps the families that had it on it for 30 days. */
export function applyTierChange(api: Api, feature: FeatureKey, tier: FeatureTier) {
  return api.call<StaffHubTierAnswer>('staffFeatureSetTier', { feature, tier });
}

export function setFeatureRollout(api: Api, req: HubRolloutRequest) {
  return api.call<{ feature: FeatureKey; flag: FlagKey | null }>('staffFeatureSetRollout', req);
}

/**
 * What "Ai được dùng" and "Bật" change: the flag of a catalogue feature (its main one or one of
 * its parts, through `staffFeatureSetRollout`) or an engineering switch (`staffSetFlag`).
 */
export type SwitchTarget =
  | { kind: 'feature'; row: StaffHubRow; flag: StaffHubFlagState }
  | { kind: 'system'; flag: StaffHubFlagState };

const isMain = (t: SwitchTarget) => t.kind === 'feature' && t.flag.key === t.row.flag?.key;

/** Its name: the feature for a main flag, the flag otherwise. */
export const targetLabelId = (t: SwitchTarget) =>
  t.kind === 'feature' && isMain(t) ? t.row.labelId : `flag.${t.flag.key}`;

const allowedPercent = (p: number) => ([0, 10, 25, 50, 100].includes(p) ? p : 0);

/** Who uses it: everyone, picked families (and the internal group), a share, internal, nobody. */
export function setScope(
  api: Api,
  t: SwitchTarget,
  fields: Pick<HubRolloutRequest, 'scope' | 'percent' | 'families' | 'betaFamilies'>,
) {
  if (t.kind === 'feature') {
    return setFeatureRollout(api, {
      feature: t.row.key,
      ...(isMain(t) ? {} : { flag: t.flag.key }),
      ...fields,
    });
  }
  const scope = fields.scope ?? t.flag.scope;
  return api.call('staffSetFlag', {
    key: t.flag.key,
    enabled: t.flag.enabled,
    scope,
    percent: scope === 'all' ? 100 : scope === 'percent' ? allowedPercent(fields.percent ?? 0) : 0,
    notice: t.flag.enabled ? null : t.flag.notice,
    ...(fields.families ? { families: fields.families } : {}),
  });
}

/** Bật: on, or off for every family at once (with the sentence families see while it is off). */
export function setEnabled(api: Api, t: SwitchTarget, enabled: boolean, notice: string | null) {
  if (t.kind === 'feature') {
    return setFeatureRollout(api, {
      feature: t.row.key,
      ...(isMain(t) ? {} : { flag: t.flag.key }),
      enabled,
      notice,
    });
  }
  return api.call('staffSetFlag', {
    key: t.flag.key,
    enabled,
    scope: t.flag.scope,
    percent: t.flag.scope === 'all' ? 100 : allowedPercent(t.flag.percent),
    notice,
  });
}

// ---------- Ai được dùng ----------

/** One choice instead of "Phát hành" and "Phạm vi" (owner 2026-10-21). */
export const scopeChoices = ['all', 'some', 'percent', 'internal', 'none'] as const;
export type ScopeChoice = (typeof scopeChoices)[number];

export function scopeChoice(
  f: Pick<StaffHubFlagState, 'scope' | 'percent'> & { families?: string[] },
): ScopeChoice {
  if (f.scope === 'all' || f.percent >= 100) return 'all';
  if (f.scope === 'internal') return f.families?.length ? 'some' : 'internal';
  return f.percent > 0 ? 'percent' : 'none';
}

/**
 * The request for a choice. "none" is a 0 % rollout, not "Bật" off: Premium families, the beta
 * list and per-family overrides still reach it; "Thử nội bộ" clears the picked families.
 */
export function scopeFields(
  choice: ScopeChoice,
  percent: 10 | 25 | 50 = 10,
  families: string[] = [],
): Pick<HubRolloutRequest, 'scope' | 'percent' | 'families'> {
  switch (choice) {
    case 'all':
      return { scope: 'all' };
    case 'some':
      return { scope: 'internal', families };
    case 'internal':
      return { scope: 'internal', families: [] };
    case 'percent':
      return { scope: 'percent', percent };
    case 'none':
      return { scope: 'percent', percent: 0 };
  }
}

/** "none" reads by tier: not launched (Premium), only the beta list (Beta), nobody (others). */
const noneId = (tier: FeatureTier | null) =>
  tier === 'premium'
    ? 'hub.scope.none.premium'
    : tier === 'beta'
      ? 'hub.scope.none.beta'
      : 'hub.scope.none.other';

/** What a tier change does, as a message id (`hub.tierNote.<from>.<to>`). */
export const tierNoteId = (from: FeatureTier, to: FeatureTier) => `hub.tierNote.${from}.${to}`;

// ---------- Tính năng: one list ----------

/** The list's groups, in order; the catalogue's groups and the switches' areas together. */
export const listGroups = [
  'keepsakes',
  'personalization',
  'assistant',
  'records',
  'content',
  'uploads',
  'engagement',
  'family',
  'analytics',
  'other',
] as const;

const switchGroups: Partial<Record<FlagKey, (typeof listGroups)[number]>> = {
  assistant_live: 'assistant',
  assistant_writes: 'assistant',
  story_share_link: 'keepsakes',
  media_upload: 'uploads',
  video_upload: 'uploads',
  invites: 'family',
  lock_widgets: 'family',
  night_auto: 'family',
  product_analytics: 'analytics',
  // P-175 / P-178: Hôm nay by age + goals and the adaptive dock.
  adaptive_experience: 'personalization',
  adaptive_nav: 'personalization',
  // D-101: Free trial allowances, storage per plan and writer seats.
  premium_v2: 'family',
};

/** Where an engineering switch sits; one added later shows under "Khác" until it gets a group. */
export function switchGroupOf(key: FlagKey): (typeof listGroups)[number] {
  return switchGroups[key] ?? (key.startsWith('engagement') ? 'engagement' : 'other');
}

/** Engineering switches in the list: every flag outside the catalogue but Mua gói trong app. */
export const listSwitchKeys = systemFlagKeys.filter((k) => k !== billingFlag);

export type ListRow =
  | { kind: 'feature'; key: string; group: string; row: StaffHubRow }
  | {
      kind: 'system';
      key: FlagKey;
      group: string;
      flag: StaffHubFlagState;
      last: { by: string; at: string } | null;
    };

const asState = (key: FlagKey, f: Flag): StaffHubFlagState => ({
  key,
  enabled: f.enabled,
  scope: f.scope,
  percent: f.percent,
  notice: f.notice,
  families: f.families ?? [],
});

/** Catalogue features and engineering switches as one list (switches once `staffFlags` answered). */
export function listRows(hub: StaffFeatureHub, flags: FlagsView | null): ListRow[] {
  return [
    ...hub.features.map((row): ListRow => ({
      kind: 'feature',
      key: row.key,
      group: row.group,
      row,
    })),
    ...(flags
      ? listSwitchKeys.map((key): ListRow => ({
          kind: 'system',
          key,
          group: switchGroupOf(key),
          flag: asState(key, flags.flags[key]),
          last: flags.lastEdit[key] ?? null,
        }))
      : []),
  ];
}

/** On for anyone at all: a feature without a flag cannot be switched off. */
const rowOn = (r: ListRow) =>
  r.kind === 'feature' ? (r.row.flag?.enabled ?? true) : r.flag.enabled;

function HubFeaturesLoader() {
  const [load, reload] = useLoad<StaffFeatureHub>('staffFeatureHub', {}, 'featureHub');
  const [flags, reloadFlags] = useLoad<FlagsView>('staffFlags', {}, 'flags');
  return (
    <Loaded load={load} reload={reload}>
      {(hub) => (
        <HubFeaturesView
          hub={hub}
          flags={flags.status === 'ok' ? flags.data : null}
          onChanged={() => {
            reload();
            reloadFlags();
          }}
        />
      )}
    </Loaded>
  );
}

export const listFilters = ['all', 'free', 'premium', 'beta', 'system'] as const;
type ListFilter = (typeof listFilters)[number];
type Dialog =
  | { kind: 'tier'; row: StaffHubRow; tier: FeatureTier }
  | { kind: 'scope'; target: SwitchTarget; choice: ScopeChoice }
  | { kind: 'toggle'; target: SwitchTarget };
type Can = { tier: boolean; toggle: boolean; rollout: boolean };

/**
 * Tính năng: every catalogue feature and every engineering switch in ONE list by area (owner,
 * 2026-10-21), with the same columns: Tính năng (help behind "?"), Gói (Miễn phí / Premium / Beta;
 * a switch is "Kỹ thuật"), Ai được dùng, Bật (off = nobody) and the detail.
 */
export function HubFeaturesView({
  hub,
  flags,
  onChanged,
}: {
  hub: StaffFeatureHub;
  /** `staffFlags`, for the engineering switches and the limits; null while it loads. */
  flags: FlagsView | null;
  onChanged: () => void;
}) {
  const intl = useIntl();
  const staff = useStaff();
  const navigate = useNavigate();
  const can: Can = {
    tier: staffCan(staff.levels, 'premium.config'),
    toggle: staffCan(staff.levels, 'flags.toggle'),
    rollout: staffCan(staff.levels, 'flags.rollout'),
  };
  const [filter, setFilter] = useState<ListFilter>('all');
  const [onOff, setOnOff] = useState<'on' | 'off' | null>(null);
  const [q, setQ] = useState('');
  const [dialog, setDialog] = useState<Dialog | null>(null);
  const [open, setOpen] = useState<string | null>(null);
  const rows = listRows(hub, flags);
  const name = (r: ListRow) =>
    intl.formatMessage({ id: r.kind === 'feature' ? r.row.labelId : `flag.${r.key}` });
  const help = (r: ListRow) =>
    intl.formatMessage({ id: r.kind === 'feature' ? r.row.helpId : `flag.${r.key}.desc` });
  const kindOf = (r: ListRow): ListFilter => (r.kind === 'feature' ? r.row.tier : 'system');
  const query = q.trim().toLowerCase();
  const match = (r: ListRow) =>
    (filter === 'all' || kindOf(r) === filter) &&
    (onOff === null || rowOn(r) === (onOff === 'on')) &&
    (!query || `${name(r)} ${help(r)} ${r.key}`.toLowerCase().includes(query));
  const shown = rows.filter(match);
  const p = hub.premium;
  const on = rows.filter(rowOn).length;
  const tiles: StatItem[] = [
    {
      key: 'families',
      label: <FormattedMessage id="hub.kpi.premiumFamilies" />,
      value: `${num(intl, p.families)}${p.capped ? '+' : ''}`,
      foot: <FormattedMessage id="hub.kpi.premiumFoot" values={{ paid: p.paid, admin: p.admin }} />,
    },
    {
      key: 'on',
      label: <FormattedMessage id="hub.kpi.on" />,
      value: on,
      active: onOff === 'on',
      onClick: () => setOnOff(onOff === 'on' ? null : 'on'),
    },
    {
      key: 'off',
      label: <FormattedMessage id="hub.kpi.off" />,
      value: rows.length - on,
      tone: rows.length - on ? 'error' : 'muted',
      active: onOff === 'off',
      onClick: () => setOnOff(onOff === 'off' ? null : 'off'),
    },
    {
      key: 'beta',
      label: <FormattedMessage id="hub.kpi.beta" />,
      value: rows.filter((r) => kindOf(r) === 'beta').length,
    },
  ];
  const count = (f: ListFilter) =>
    f === 'all' ? rows.length : rows.filter((r) => kindOf(r) === f).length;
  const openRow = rows.find((r) => r.key === open) ?? null;
  const onScope = (target: SwitchTarget, choice: ScopeChoice) =>
    setDialog({ kind: 'scope', target, choice });
  const onToggle = (target: SwitchTarget) => setDialog({ kind: 'toggle', target });
  const done = () => {
    setDialog(null);
    onChanged();
  };
  return (
    <div className="grid min-w-0 gap-4">
      <StatTiles items={tiles} />
      <div className="overflow-hidden rounded-xl border bg-card">
        <FilterBar
          active={!!q || filter !== 'all' || onOff !== null}
          onClear={() => {
            setQ('');
            setFilter('all');
            setOnOff(null);
          }}
          shown={shown.length}
          total={rows.length}
        >
          <Segmented
            label={intl.formatMessage({ id: 'hub.filter.label' })}
            value={filter}
            onChange={setFilter}
            options={listFilters.map((f) => ({
              value: f,
              label: (
                <>
                  <FormattedMessage id={`hub.filter.${f}`} />{' '}
                  <span className="text-muted-foreground tabular-nums">{count(f)}</span>
                </>
              ),
            }))}
          />
          <SearchInput
            value={q}
            onChange={setQ}
            placeholder={intl.formatMessage({ id: 'features.search' })}
          />
        </FilterBar>
        {shown.length === 0 ? (
          <EmptyState icon={Search} title={<FormattedMessage id="features.noMatch" />} />
        ) : (
          <TableScroll min={860}>
            <table className="table">
              <thead>
                <tr>
                  <th>
                    <FormattedMessage id="hub.col.feature" />
                  </th>
                  <th>
                    <FormattedMessage id="hub.col.tier" />
                  </th>
                  <th>
                    <FormattedMessage id="hub.col.who" />
                  </th>
                  <th className="w-24">
                    <FormattedMessage id="hub.col.on" />
                  </th>
                  <th className="w-10">
                    <span className="sr-only">
                      <FormattedMessage id="hub.col.detail" />
                    </span>
                  </th>
                </tr>
              </thead>
              {listGroups.map((g) => {
                const inGroup = shown.filter((r) => r.group === g);
                if (!inGroup.length) return null;
                return (
                  <tbody key={g}>
                    <tr className="cl-group-row">
                      <th colSpan={5} scope="rowgroup">
                        <FormattedMessage id={`hub.group.${g}`} />
                        <span className="font-normal text-muted-foreground">
                          {' '}
                          · {inGroup.length}
                        </span>
                      </th>
                    </tr>
                    {inGroup.map((r) => (
                      <ListRowView
                        key={r.key}
                        r={r}
                        premiumFamilies={p.families}
                        can={can}
                        onTier={(tier) =>
                          r.kind === 'feature' && setDialog({ kind: 'tier', row: r.row, tier })
                        }
                        onScope={onScope}
                        onToggle={onToggle}
                        onOpen={() => setOpen(r.key)}
                      />
                    ))}
                  </tbody>
                );
              })}
            </table>
          </TableScroll>
        )}
        <p className="flex flex-wrap items-center gap-1 border-t px-4 py-2 text-[13px] text-muted-foreground">
          <FormattedMessage id="hub.switches.billingElsewhere" />
          <Button kind="ghost" onClick={() => navigate('features', 'plan')}>
            <FormattedMessage id="hub.tab.plan" />
          </Button>
        </p>
      </div>
      {flags && (
        <Section collapsible defaultOpen={false} title={<FormattedMessage id="features.limits" />}>
          <LimitsList limits={flags.limits} />
        </Section>
      )}
      {openRow && (
        <DetailSheet title={name(openRow)} onClose={() => setOpen(null)}>
          {openRow.kind === 'feature' ? (
            <FeatureDetail
              row={openRow.row}
              premiumFamilies={p.families}
              can={can}
              onScope={onScope}
              onToggle={onToggle}
              onChanged={onChanged}
            />
          ) : (
            <SwitchDetail r={openRow} can={can} onScope={onScope} onToggle={onToggle} />
          )}
        </DetailSheet>
      )}
      {dialog?.kind === 'tier' && (
        <TierDialog
          row={dialog.row}
          tier={dialog.tier}
          onClose={() => setDialog(null)}
          onDone={done}
        />
      )}
      {dialog?.kind === 'scope' && (
        <ScopeDialog
          target={dialog.target}
          choice={dialog.choice}
          onClose={() => setDialog(null)}
          onDone={done}
        />
      )}
      {dialog?.kind === 'toggle' && (
        <ToggleDialog target={dialog.target} onClose={() => setDialog(null)} onDone={done} />
      )}
    </div>
  );
}

function ListRowView({
  r,
  premiumFamilies,
  can,
  onTier,
  onScope,
  onToggle,
  onOpen,
}: {
  r: ListRow;
  premiumFamilies: number;
  can: Can;
  onTier: (tier: FeatureTier) => void;
  onScope: (target: SwitchTarget, choice: ScopeChoice) => void;
  onToggle: (target: SwitchTarget) => void;
  onOpen: () => void;
}) {
  const intl = useIntl();
  const feature = r.kind === 'feature' ? r.row : null;
  const name = intl.formatMessage({ id: feature ? feature.labelId : `flag.${r.key}` });
  const helpId = feature ? feature.helpId : `flag.${r.key}.desc`;
  const target: SwitchTarget | null = feature
    ? feature.flag
      ? { kind: 'feature', row: feature, flag: feature.flag }
      : null
    : r.kind === 'system'
      ? { kind: 'system', flag: r.flag }
      : null;
  const off = target ? !target.flag.enabled : false;
  return (
    <tr className={cn(off && 'bg-destructive/5')}>
      <td className="max-w-[22rem]">
        <span className="flex items-center gap-1">
          <button type="button" className="link-button text-left font-medium" onClick={onOpen}>
            {name}
          </button>
          <Hint label={intl.formatMessage({ id: helpId })}>
            <FormattedMessage id={helpId} />
            {!feature && (
              <>
                {'. '}
                <FormattedMessage id="features.whenOff" />{' '}
                <FormattedMessage id={`flag.${r.key}.offEffect`} />
              </>
            )}
          </Hint>
        </span>
        {feature?.grace && (
          <span className="block text-xs text-muted-foreground">
            <FormattedMessage
              id="hub.grace.until"
              values={{ date: dayText(intl, feature.grace.until) }}
            />
          </span>
        )}
        {feature && feature.subFlags.length > 0 && (
          <span className="block text-xs text-muted-foreground">
            <FormattedMessage id="hub.subFlags.count" values={{ n: feature.subFlags.length }} />
          </span>
        )}
      </td>
      <td>
        {feature ? (
          <TierSelect row={feature} disabled={!can.tier} onPick={onTier} />
        ) : (
          <span className="text-[13px] text-muted-foreground">
            <FormattedMessage id="hub.tier.system" />
          </span>
        )}
      </td>
      <td>
        <WhoCell
          name={name}
          tier={feature?.tier ?? null}
          target={target}
          disabled={!can.rollout}
          onScope={onScope}
        />
        {feature && (
          <span className="mt-0.5 block text-xs">
            <FamilyCounts row={feature} premiumFamilies={premiumFamilies} quiet />
          </span>
        )}
      </td>
      <td>
        {target ? (
          <OnSwitch
            name={name}
            flag={target.flag}
            disabled={!can.toggle}
            onToggle={() => onToggle(target)}
          />
        ) : (
          <span
            className="text-muted-foreground"
            title={intl.formatMessage({ id: 'hub.on.always' })}
          >
            —
          </span>
        )}
      </td>
      <td className="cell-actions">
        <UiButton
          variant="ghost"
          size="icon"
          className="size-8"
          aria-label={intl.formatMessage({ id: 'hub.detail.open' }, { feature: name })}
          title={intl.formatMessage({ id: 'hub.detail.open' }, { feature: name })}
          onClick={onOpen}
        >
          <PanelRightOpen />
        </UiButton>
      </td>
    </tr>
  );
}

/**
 * Ai được dùng. Premium rows read "Người có Premium" and offer when everyone else sees it; a
 * feature without a flag follows its tier only.
 */
function WhoCell({
  name,
  tier,
  target,
  disabled,
  onScope,
}: {
  name: string;
  tier: FeatureTier | null;
  target: SwitchTarget | null;
  disabled: boolean;
  onScope: (target: SwitchTarget, choice: ScopeChoice) => void;
}) {
  if (!target) {
    return (
      <span className="text-[13px]">
        <FormattedMessage
          id={
            tier === 'premium'
              ? 'hub.who.premium'
              : tier === 'beta'
                ? 'hub.scope.none.beta'
                : 'hub.scope.all'
          }
        />
      </span>
    );
  }
  return (
    <span className="grid justify-items-start gap-1">
      {tier === 'premium' && (
        <span className="text-[13px] font-medium">
          <FormattedMessage id="hub.who.premium" />
        </span>
      )}
      <ScopeSelect
        name={name}
        flag={target.flag}
        tier={tier}
        disabled={disabled}
        onPick={(choice) => onScope(target, choice)}
      />
    </span>
  );
}

export function ScopeSelect({
  name,
  flag,
  tier,
  disabled,
  onPick,
}: {
  name: string;
  flag: StaffHubFlagState;
  tier: FeatureTier | null;
  disabled: boolean;
  onPick: (choice: ScopeChoice) => void;
}) {
  const intl = useIntl();
  const current = scopeChoice(flag);
  const text = (c: ScopeChoice) =>
    c === 'none'
      ? intl.formatMessage({ id: noneId(tier) })
      : intl.formatMessage(
          { id: `hub.scope.${c}` },
          {
            n: flag.families.length,
            p: c === current ? flag.percent : 0,
          },
        );
  const label = intl.formatMessage(
    { id: tier === 'premium' ? 'hub.scope.labelPremium' : 'hub.scope.label' },
    { feature: name },
  );
  if (disabled) {
    return (
      <Pill tone={current === 'all' ? 'ok' : current === 'none' ? 'muted' : 'purple'}>
        {text(current)}
      </Pill>
    );
  }
  return (
    <SelectMenu
      className="min-w-44"
      label={label}
      value={current}
      options={scopeChoices.map((c) => ({ value: c, label: text(c) }))}
      onChange={(c) => onPick(c)}
    />
  );
}

/** Bật: off = nobody, whatever the tier, overrides or Premium. */
function OnSwitch({
  name,
  flag,
  disabled,
  onToggle,
}: {
  name: string;
  flag: StaffHubFlagState;
  disabled: boolean;
  onToggle: () => void;
}) {
  const intl = useIntl();
  return (
    <span className="flex items-center gap-2">
      <Switch
        checked={flag.enabled}
        aria-label={intl.formatMessage({ id: 'hub.on.label' }, { feature: name })}
        disabled={disabled}
        title={disabled ? intl.formatMessage({ id: 'features.toggleRole' }) : undefined}
        // Confirmed in a dialog first (A11): turning off can show families a notice.
        onCheckedChange={onToggle}
      />
      {!flag.enabled && (
        <span className="text-xs font-medium text-destructive">
          <FormattedMessage id="hub.on.off" />
        </span>
      )}
    </span>
  );
}

/** Who has it beyond "Ai được dùng": Premium families, the beta list, per-family overrides. */
function FamilyCounts({
  row,
  premiumFamilies,
  quiet,
}: {
  row: StaffHubRow;
  premiumFamilies: number;
  /** In the list: one muted line, and nothing when there is nothing to add. */
  quiet?: boolean;
}) {
  const parts: ReactNode[] = [];
  if (row.tier === 'premium') {
    parts.push(<FormattedMessage key="p" id="hub.count.premium" values={{ n: premiumFamilies }} />);
  }
  if (row.tier === 'beta' || row.betaFamilies.length) {
    parts.push(
      <FormattedMessage key="b" id="hub.count.beta" values={{ n: row.betaFamilies.length }} />,
    );
  }
  if (row.overrides.on || row.overrides.off) {
    parts.push(
      <FormattedMessage
        key="o"
        id="hub.count.overrides"
        values={{ on: row.overrides.on, off: row.overrides.off }}
      />,
    );
  }
  if (!parts.length) return quiet ? null : <span className="text-muted-foreground">—</span>;
  return (
    <span className={cn('flex flex-wrap gap-x-1', quiet && 'text-muted-foreground')}>
      {parts.map((part, i) => (
        <span key={i}>
          {i > 0 && '· '}
          {part}
        </span>
      ))}
    </span>
  );
}

function dayText(intl: ReturnType<typeof useIntl>, iso: string) {
  // The grace ends at an instant; the last day shown is the one before it ends.
  return intl.formatDate(new Date(Date.parse(iso) - 1), {
    day: 'numeric',
    month: 'numeric',
    year: 'numeric',
    timeZone: ZONE,
  });
}

// ---------- Detail ----------

function DetailSheet({
  title,
  onClose,
  children,
}: {
  title: string;
  onClose: () => void;
  children: ReactNode;
}) {
  const intl = useIntl();
  // Server rendering (tests) has no portal: the same content, inline.
  if (typeof document === 'undefined') {
    return (
      <section aria-label={title} className="grid gap-4">
        <h2 className="text-lg font-semibold">{title}</h2>
        {children}
      </section>
    );
  }
  return (
    <Sheet open onOpenChange={(o) => !o && onClose()}>
      <SheetContent
        side="right"
        aria-describedby={undefined}
        closeLabel={intl.formatMessage({ id: 'action.close' })}
        className="w-full gap-0 overflow-y-auto overscroll-contain sm:max-w-xl"
      >
        <SheetTitle className="border-b px-5 py-4 pr-12 text-base">{title}</SheetTitle>
        <div className="grid gap-4 p-5">{children}</div>
      </SheetContent>
    </Sheet>
  );
}

/**
 * One feature in full: its help, Gói, each switch (main and parts: the assistant's photos, care
 * and upsell), the beta list, the 30-day grace and the overrides.
 */
export function FeatureDetail({
  row,
  premiumFamilies,
  can,
  onScope,
  onToggle,
  onChanged,
}: {
  row: StaffHubRow;
  premiumFamilies: number;
  can: Can;
  onScope: (target: SwitchTarget, choice: ScopeChoice) => void;
  onToggle: (target: SwitchTarget) => void;
  onChanged: () => void;
}) {
  const intl = useIntl();
  const flags = [row.flag, ...row.subFlags].filter((f): f is StaffHubFlagState => !!f);
  // Engineering switches of the same area (the assistant's live calls and writes).
  const systemParts = systemFlagKeys.filter((k) => k.startsWith(`${row.key}_`));
  return (
    <div className="grid gap-4 text-sm">
      <p className="text-muted-foreground">
        <FormattedMessage id={row.helpId} />
      </p>
      <dl className="kv">
        <dt>
          <FormattedMessage id="hub.col.tier" />
        </dt>
        <dd className="flex flex-wrap items-center gap-2">
          <TierPill tier={row.tier} />
          {row.tier !== row.defaultTier && (
            <span className="text-xs text-muted-foreground">
              <FormattedMessage
                id="hub.detail.defaultTier"
                values={{ tier: intl.formatMessage({ id: `hub.tier.${row.defaultTier}` }) }}
              />
            </span>
          )}
          {row.credits && row.tier === 'premium' && <CreditsNote />}
        </dd>
        <dt>
          <FormattedMessage id="hub.col.families" />
        </dt>
        <dd>
          <FamilyCounts row={row} premiumFamilies={premiumFamilies} />
        </dd>
        {row.capabilities.length > 0 && (
          <>
            <dt>
              <FormattedMessage id="hub.detail.capabilities" />
            </dt>
            <dd>
              {row.capabilities
                .map((c: Capability) => intl.formatMessage({ id: `premium.cap.${c}` }))
                .join(', ')}
            </dd>
          </>
        )}
        {row.lastEdit && (
          <>
            <dt>
              <FormattedMessage id="col.lastEdit" />
            </dt>
            <dd>
              {row.lastEdit.by} · {shortDate(intl, row.lastEdit.at)}
            </dd>
          </>
        )}
      </dl>
      {row.grace && (
        <Notice tone="info">
          <FormattedMessage
            id="hub.grace.note"
            values={{
              date: dayText(intl, row.grace.until),
              from: intl.formatMessage({ id: `hub.tier.${row.grace.from}` }),
            }}
          />
        </Notice>
      )}
      {flags.length > 0 && (
        <section className="grid gap-2">
          <h3 className="text-[13px] font-semibold">
            <FormattedMessage id="hub.detail.switches" />
          </h3>
          <ul className="grid divide-y rounded-lg border">
            {flags.map((f) => {
              const target: SwitchTarget = { kind: 'feature', row, flag: f };
              const flagName = intl.formatMessage({ id: `flag.${f.key}` });
              return (
                <li key={f.key} className="grid gap-2 px-3 py-2.5">
                  <div className="flex items-start gap-2">
                    <span className="min-w-0 flex-1">
                      <span className="flex items-center gap-1 font-medium">
                        {flagName}
                        {f.key === row.flag?.key && (
                          <Badge variant="outline" className="font-normal">
                            <FormattedMessage id="hub.detail.main" />
                          </Badge>
                        )}
                      </span>
                      <span className="block text-xs text-muted-foreground">
                        <FormattedMessage id={`flag.${f.key}.desc`} />
                      </span>
                    </span>
                    <OnSwitch
                      name={flagName}
                      flag={f}
                      disabled={!can.toggle}
                      onToggle={() => onToggle(target)}
                    />
                  </div>
                  <ScopeSelect
                    name={flagName}
                    flag={f}
                    tier={row.tier}
                    disabled={!can.rollout}
                    onPick={(choice) => onScope(target, choice)}
                  />
                  {f.scope === 'internal' && f.families.length > 0 && <Codes codes={f.families} />}
                </li>
              );
            })}
          </ul>
        </section>
      )}
      {(row.tier === 'beta' || row.betaFamilies.length > 0) && (
        <BetaList row={row} canEdit={can.rollout} onChanged={onChanged} />
      )}
      {systemParts.length > 0 && (
        <p className="text-xs text-muted-foreground">
          <FormattedMessage
            id="hub.detail.systemParts"
            values={{
              flags: systemParts.map((k) => intl.formatMessage({ id: `flag.${k}` })).join(', '),
            }}
          />
        </p>
      )}
      <p className="text-xs text-muted-foreground">
        <FormattedMessage id="hub.detail.overridesNote" />
      </p>
    </div>
  );
}

/** One engineering switch: what it does, what turning it off does, who uses it. */
export function SwitchDetail({
  r,
  can,
  onScope,
  onToggle,
}: {
  r: Extract<ListRow, { kind: 'system' }>;
  can: Can;
  onScope: (target: SwitchTarget, choice: ScopeChoice) => void;
  onToggle: (target: SwitchTarget) => void;
}) {
  const intl = useIntl();
  const target: SwitchTarget = { kind: 'system', flag: r.flag };
  const name = intl.formatMessage({ id: `flag.${r.key}` });
  return (
    <div className="grid gap-4 text-sm">
      <p className="text-muted-foreground">
        <FormattedMessage id={`flag.${r.key}.desc`} />
      </p>
      <dl className="kv">
        <dt>
          <FormattedMessage id="hub.col.tier" />
        </dt>
        <dd>
          <FormattedMessage id="hub.tier.system" />
        </dd>
        <dt>
          <FormattedMessage id="features.whenOff" />
        </dt>
        <dd>
          <FormattedMessage id={`flag.${r.key}.offEffect`} />
        </dd>
        {!r.flag.enabled && r.flag.notice && (
          <>
            <dt>
              <FormattedMessage id="features.notify" />
            </dt>
            <dd>{r.flag.notice}</dd>
          </>
        )}
        {r.last && (
          <>
            <dt>
              <FormattedMessage id="col.lastEdit" />
            </dt>
            <dd>
              {r.last.by} · {shortDate(intl, r.last.at)}
            </dd>
          </>
        )}
      </dl>
      <div className="flex flex-wrap items-center gap-3 rounded-lg border px-3 py-2.5">
        <ScopeSelect
          name={name}
          flag={r.flag}
          tier={null}
          disabled={!can.rollout}
          onPick={(choice) => onScope(target, choice)}
        />
        <span className="ml-auto">
          <OnSwitch
            name={name}
            flag={r.flag}
            disabled={!can.toggle}
            onToggle={() => onToggle(target)}
          />
        </span>
      </div>
      {r.flag.scope === 'internal' && r.flag.families.length > 0 && (
        <Codes codes={r.flag.families} />
      )}
    </div>
  );
}

function Codes({ codes }: { codes: string[] }) {
  return (
    <ul className="flex flex-wrap gap-1">
      {codes.map((c) => (
        <li key={c}>
          <Badge variant="secondary" className="font-mono">
            {c}
          </Badge>
        </li>
      ))}
    </ul>
  );
}

/** The families picked for the beta, on top of the rollout; edited here as one list. */
function BetaList({
  row,
  canEdit,
  onChanged,
}: {
  row: StaffHubRow;
  canEdit: boolean;
  onChanged: () => void;
}) {
  const intl = useIntl();
  const api = useApi();
  const [codes, setCodes] = useState(row.betaFamilies);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const saved = JSON.stringify([...row.betaFamilies].sort());
  const dirty = JSON.stringify([...codes].sort()) !== saved;
  return (
    <section className="grid gap-2">
      <h3 className="text-[13px] font-semibold">
        <FormattedMessage id="hub.beta.list" values={{ n: row.betaFamilies.length }} />
      </h3>
      {canEdit ? (
        <>
          <FamilyPicker
            value={codes}
            onChange={setCodes}
            label={intl.formatMessage({ id: 'hub.beta.list' }, { n: codes.length })}
            empty="hub.beta.empty"
          />
          {error && (
            <p className="error" role="alert">
              <FormattedMessage id={errorMessageId(error)} />
            </p>
          )}
          {dirty && (
            <div>
              <Button
                kind="primary"
                disabled={busy}
                onClick={() => {
                  setBusy(true);
                  setError(null);
                  setFeatureRollout(api, { feature: row.key, betaFamilies: codes })
                    .then(() => {
                      toast.success(intl.formatMessage({ id: 'hub.beta.saved' }));
                      onChanged();
                    })
                    .catch((e: unknown) =>
                      setError(e instanceof ApiError ? e : new ApiError('unknown', null)),
                    )
                    .finally(() => setBusy(false));
                }}
              >
                <FormattedMessage id="hub.beta.save" />
              </Button>
            </div>
          )}
        </>
      ) : row.betaFamilies.length ? (
        <Codes codes={row.betaFamilies} />
      ) : (
        <p className="text-xs text-muted-foreground">
          <FormattedMessage id="hub.beta.empty" />
        </p>
      )}
    </section>
  );
}

// ---------- Dialogs ----------

/**
 * Gói: the confirmation names how many families it touches (a dry run) and, for a move to
 * Premium, the 30-day grace that keeps them on it (plan §2.4).
 */
export function TierDialog({
  row,
  tier,
  onClose,
  onDone,
  initialAnswer = null,
}: {
  row: StaffHubRow;
  tier: FeatureTier;
  onClose: () => void;
  onDone: () => void;
  /** The dry run's answer (tests). */
  initialAnswer?: StaffHubTierAnswer | null;
}) {
  const intl = useIntl();
  const api = useApi();
  const [answer, setAnswer] = useState<StaffHubTierAnswer | null>(initialAnswer);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  useEffect(() => {
    if (initialAnswer) return;
    let live = true;
    previewTierChange(api, row.key, tier)
      .then((a) => live && setAnswer(a))
      .catch(
        (e: unknown) => live && setError(e instanceof ApiError ? e : new ApiError('unknown', null)),
      );
    return () => {
      live = false;
    };
  }, [api, row.key, tier, initialAnswer]);
  const feature = intl.formatMessage({ id: row.labelId });
  const tierName = (t: FeatureTier) => intl.formatMessage({ id: `hub.tier.${t}` });
  const toPremium = tier === 'premium' && row.tier !== 'premium';
  return (
    <Modal
      title={
        <FormattedMessage
          id="hub.tier.title"
          values={{ feature, from: tierName(row.tier), to: tierName(tier) }}
        />
      }
      onClose={onClose}
    >
      {answer ? (
        <Notice tone={toPremium ? 'warn' : 'info'}>
          <FormattedMessage
            id={tierNoteId(answer.from, answer.tier)}
            values={{
              n: answer.affected,
              date: answer.graceUntil ? dayText(intl, answer.graceUntil) : '',
            }}
          />
        </Notice>
      ) : (
        !error && (
          <p className="text-sm text-muted-foreground" role="status">
            <FormattedMessage id="hub.tier.counting" />
          </p>
        )
      )}
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
          kind={toPremium ? 'danger' : 'primary'}
          disabled={busy || !answer}
          onClick={() => {
            setBusy(true);
            setError(null);
            applyTierChange(api, row.key, tier)
              .then(() => {
                toast.success(
                  intl.formatMessage({ id: 'hub.tier.done' }, { feature, tier: tierName(tier) }),
                );
                onDone();
              })
              .catch((e: unknown) =>
                setError(e instanceof ApiError ? e : new ApiError('unknown', null)),
              )
              .finally(() => setBusy(false));
          }}
        >
          <FormattedMessage id="hub.tier.confirm" values={{ tier: tierName(tier) }} />
        </Button>
      </div>
    </Modal>
  );
}

/**
 * Ai được dùng of a feature (or one of its parts) or a switch: the share for "Theo %", the families
 * for "Một số gia đình", and a Beta feature's beta list.
 */
export function ScopeDialog({
  target,
  choice,
  onClose,
  onDone,
}: {
  target: SwitchTarget;
  choice: ScopeChoice;
  onClose: () => void;
  onDone: () => void;
}) {
  const intl = useIntl();
  const api = useApi();
  const flag = target.flag;
  const row = target.kind === 'feature' ? target.row : null;
  const [percent, setPercent] = useState<10 | 25 | 50>(() =>
    flag.percent === 25 || flag.percent === 50 ? flag.percent : 10,
  );
  const [families, setFamilies] = useState(flag.families);
  const [beta, setBeta] = useState(row?.betaFamilies ?? []);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const name = intl.formatMessage({ id: targetLabelId(target) });
  const withBeta = !!row && isMain(target) && row.tier === 'beta';
  const betaChanged = JSON.stringify(beta) !== JSON.stringify(row?.betaFamilies ?? []);
  const tier = row?.tier ?? null;
  return (
    <Modal
      wide={choice === 'some' || withBeta}
      title={<FormattedMessage id="hub.scope.title" values={{ feature: name }} />}
      onClose={onClose}
    >
      <Notice tone="info">
        <FormattedMessage
          id={choice === 'none' ? noneId(tier) : `hub.scope.${choice}`}
          values={{ n: 0, p: 0 }}
        />
        {': '}
        <FormattedMessage id={`hub.scopeNote.${choice}`} />
        {tier === 'premium' && (
          <>
            {' '}
            <FormattedMessage id="hub.scopeNote.premium" />
          </>
        )}
      </Notice>
      {!flag.enabled && (
        <Notice tone="warn">
          <FormattedMessage id="hub.scopeNote.off" />
        </Notice>
      )}
      {choice === 'percent' && (
        <ToggleGroup
          type="single"
          variant="outline"
          value={String(percent)}
          aria-label={intl.formatMessage({ id: 'hub.scope.share' })}
          onValueChange={(v) => v && setPercent(Number(v) as 10 | 25 | 50)}
        >
          {([10, 25, 50] as const).map((p) => (
            <ToggleGroupItem key={p} value={String(p)} className="px-3 tabular-nums">
              {p}%
            </ToggleGroupItem>
          ))}
        </ToggleGroup>
      )}
      {choice === 'some' && (
        <div className="grid gap-2">
          <span className="text-[13px] font-medium">
            <FormattedMessage id="hub.scope.families" />
          </span>
          <FamilyPicker value={families} onChange={setFamilies} />
        </div>
      )}
      {withBeta && (
        <div className="grid gap-2">
          <span className="text-[13px] font-medium">
            <FormattedMessage id="hub.beta.list" values={{ n: beta.length }} />
          </span>
          <FamilyPicker
            value={beta}
            onChange={setBeta}
            label={intl.formatMessage({ id: 'hub.beta.list' }, { n: beta.length })}
            empty="hub.beta.empty"
          />
        </div>
      )}
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
          disabled={busy || (choice === 'some' && families.length === 0)}
          onClick={() => {
            setBusy(true);
            setError(null);
            setScope(api, target, {
              ...scopeFields(choice, percent, families),
              ...(withBeta && betaChanged ? { betaFamilies: beta } : {}),
            })
              .then(() => {
                toast.success(intl.formatMessage({ id: 'hub.scope.done' }, { feature: name }));
                onDone();
              })
              .catch((e: unknown) =>
                setError(e instanceof ApiError ? e : new ApiError('unknown', null)),
              )
              .finally(() => setBusy(false));
          }}
        >
          <FormattedMessage id="features.confirm" />
        </Button>
      </div>
    </Modal>
  );
}

/** Bật: off for every family at once (Premium and overrides too), with the in-app notice. */
export function ToggleDialog({
  target,
  onClose,
  onDone,
}: {
  target: SwitchTarget;
  onClose: () => void;
  onDone: () => void;
}) {
  const intl = useIntl();
  const api = useApi();
  const flag = target.flag;
  const name = intl.formatMessage({ id: targetLabelId(target) });
  const off = flag.enabled;
  const [notify, setNotify] = useState(true);
  const [notice, setNotice] = useState(() => defaultNotice(flag.key, name));
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  return (
    <Modal
      title={
        <FormattedMessage
          id={off ? 'hub.on.offTitle' : 'hub.on.onTitle'}
          values={{ feature: name }}
        />
      }
      icon={
        off ? (
          <span className="modal__alert" aria-hidden="true">
            !
          </span>
        ) : undefined
      }
      onClose={onClose}
    >
      <Notice tone={off ? 'warn' : 'info'}>
        {off ? (
          <>
            <FormattedMessage id={`flag.${flag.key}.offEffect`} />{' '}
            <FormattedMessage id="hub.on.offNote" />
          </>
        ) : (
          <FormattedMessage id="hub.on.onNote" />
        )}
      </Notice>
      {off && (
        <NoticeField notify={notify} onNotify={setNotify} notice={notice} onNotice={setNotice} />
      )}
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
          kind={off ? 'danger' : 'primary'}
          disabled={busy}
          onClick={() => {
            setBusy(true);
            setError(null);
            setEnabled(api, target, !off, off && notify && notice.trim() ? notice.trim() : null)
              .then(() => {
                toast.success(
                  intl.formatMessage(
                    { id: off ? 'features.done.off' : 'features.done.on' },
                    { flag: name },
                  ),
                );
                onDone();
              })
              .catch((e: unknown) =>
                setError(e instanceof ApiError ? e : new ApiError('unknown', null)),
              )
              .finally(() => setBusy(false));
          }}
        >
          <FormattedMessage id={off ? 'hub.on.confirmOff' : 'hub.on.confirmOn'} />
        </Button>
      </div>
    </Modal>
  );
}

function TierSelect({
  row,
  disabled,
  onPick,
}: {
  row: StaffHubRow;
  disabled: boolean;
  onPick: (tier: FeatureTier) => void;
}) {
  const intl = useIntl();
  const name = intl.formatMessage({ id: row.labelId });
  if (disabled || !row.tierable) {
    return (
      <span className="grid justify-items-start gap-0.5">
        <TierPill tier={row.tier} />
        {row.credits && row.tier === 'premium' && <CreditsNote />}
      </span>
    );
  }
  return (
    <span className="grid justify-items-start gap-0.5">
      <SelectMenu
        className="min-w-32"
        label={intl.formatMessage({ id: 'hub.tier.label' }, { feature: name })}
        value={row.tier}
        options={featureTiers.map((t) => ({
          value: t,
          label: intl.formatMessage({ id: `hub.tier.${t}` }),
        }))}
        onChange={(t) => t !== row.tier && onPick(t)}
      />
      {row.credits && row.tier === 'premium' && <CreditsNote />}
    </span>
  );
}

function CreditsNote() {
  return (
    <span className="text-xs text-muted-foreground">
      <FormattedMessage id="hub.tier.credits" />
    </span>
  );
}

// ---------- Lịch sử ----------

function HubHistoryLoader() {
  const [load, reload] = useLoad<StaffFeatureHub>('staffFeatureHub', {}, 'featureHub');
  return (
    <Loaded load={load} reload={reload}>
      {(hub) => <HubHistory recent={hub.recent} />}
    </Loaded>
  );
}

type AuditFeed = 'features' | 'premium';

/** The hub's latest changes (actor, action, before / after), then the audit feed by category. */
export function HubHistory({ recent }: { recent: StaffFeatureHub['recent'] }) {
  const intl = useIntl();
  const staff = useStaff();
  const [feed, setFeed] = useState<AuditFeed>('features');
  return (
    <div className="grid min-w-0 gap-4">
      <Section
        title={<FormattedMessage id="hub.history.recent" />}
        hint={<FormattedMessage id="hub.history.note" />}
      >
        <RecentList recent={recent} />
      </Section>
      {staffCan(staff.levels, 'audit.view') && (
        <Section
          flush
          title={<FormattedMessage id="hub.history.audit" />}
          actions={
            <Segmented
              label={intl.formatMessage({ id: 'audit.category' })}
              value={feed}
              onChange={setFeed}
              options={(['features', 'premium'] as const).map((c) => ({
                value: c,
                label: <FormattedMessage id={`auditCategory.${c}`} />,
              }))}
            />
          }
        >
          <AuditFeedLoader key={feed} category={feed} />
        </Section>
      )}
    </div>
  );
}

function AuditFeedLoader({ category }: { category: AuditFeed }) {
  const [load, reload] = useLoad<{ rows: AuditRow[] }>(
    'staffAudit',
    { category, days: 30 },
    `hub-audit-${category}`,
  );
  return (
    <Loaded load={load} reload={reload}>
      {(data) => <AuditTable rows={data.rows} now={new Date()} />}
    </Loaded>
  );
}
