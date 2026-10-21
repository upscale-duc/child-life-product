import {
  featureTiers,
  staffCan,
  systemFlagKeys,
  type Capability,
  type FeatureKey,
  type FeatureTier,
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
import { cn } from '@/lib/utils';
import { ApiError, useApi, useLoad, type Api, type AuditRow, type HubRolloutRequest } from '../api';
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
import { routePaths, subPath, useStaff } from '../context';
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
  NoticeField,
  RecentList,
  SystemSwitchesLoader,
  defaultNotice,
} from './Features';
import { HubFamilies, TierPill } from './HubFamily';
import { PremiumPlanLoader } from './Premium';

/**
 * "Tính năng & Premium" (D-089, `docs/product/features-premium-hub-plan.md`): one hub instead of
 * Tính năng & phát hành, Premium and the personalization switches. Tabs: Tính năng (the catalogue:
 * tier, Phát hành, Công tắc khẩn), Gia đình (one family's features and why, overrides, beta, "Bật
 * toàn bộ Premium"), Gói Premium (billing, regions, quotas, the AI policy), Công tắc hệ thống
 * (engineering switches, limits) and Lịch sử. The rule of plan §2.2 runs on the server
 * (`decideFeature`); the portal shows its answer. No reason is asked anywhere (D-090).
 */

export const hubTabs = ['features', 'families', 'plan', 'switches', 'history'] as const;
export type HubTab = (typeof hubTabs)[number];
const hubTabPath: Record<HubTab, string> = {
  features: '',
  families: 'families',
  plan: 'plan',
  switches: 'switches',
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
        <TabsContent value="features" className="min-w-0">
          <HubFeaturesLoader />
        </TabsContent>
        <TabsContent value="families" className="min-w-0">
          <HubFamilies />
        </TabsContent>
        <TabsContent value="plan" className="min-w-0">
          <PremiumPlanLoader />
        </TabsContent>
        <TabsContent value="switches" className="min-w-0">
          <SystemSwitchesLoader />
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

// ---------- Phát hành ----------

/** Phát hành as one choice: not released, internal (+ picked families), a share, everyone. */
export const rolloutLevels = ['off', 'internal', 'p10', 'p25', 'p50', 'all'] as const;
export type RolloutLevel = (typeof rolloutLevels)[number];

export function rolloutLevel(f: Pick<StaffHubFlagState, 'scope' | 'percent'>): RolloutLevel {
  if (f.scope === 'all' || f.percent >= 100) return 'all';
  if (f.scope === 'internal') return 'internal';
  if (f.percent >= 50) return 'p50';
  if (f.percent >= 25) return 'p25';
  if (f.percent > 0) return 'p10';
  return 'off';
}

/**
 * "Chưa phát hành" is a 0 % rollout, not the kill switch: Premium families, the beta list and
 * per-family overrides still reach it, while the kill switch turns it off for everyone.
 */
export function rolloutFields(level: RolloutLevel): Pick<HubRolloutRequest, 'scope' | 'percent'> {
  switch (level) {
    case 'off':
      return { scope: 'percent', percent: 0 };
    case 'internal':
      return { scope: 'internal' };
    case 'all':
      return { scope: 'all' };
    default:
      return { scope: 'percent', percent: Number(level.slice(1)) as 10 | 25 | 50 };
  }
}

/** What a tier change does, as a message id (`hub.tierNote.<from>.<to>`). */
export const tierNoteId = (from: FeatureTier, to: FeatureTier) => `hub.tierNote.${from}.${to}`;

// ---------- Tính năng ----------

function HubFeaturesLoader() {
  const [load, reload] = useLoad<StaffFeatureHub>('staffFeatureHub', {}, 'featureHub');
  return (
    <Loaded load={load} reload={reload}>
      {(hub) => <HubFeaturesView hub={hub} onChanged={reload} />}
    </Loaded>
  );
}

type Filter = 'all' | FeatureTier;
type Dialog =
  | { kind: 'tier'; row: StaffHubRow; tier: FeatureTier }
  | { kind: 'rollout'; row: StaffHubRow; flag: StaffHubFlagState; level: RolloutLevel }
  | { kind: 'kill'; row: StaffHubRow; flag: StaffHubFlagState };

/**
 * The catalogue by group. Each row: name (help behind "?"), Gói, Phát hành, who has it, the kill
 * switch; the row opens its detail (sub-switches, beta list, grace, overrides).
 */
export function HubFeaturesView({
  hub,
  onChanged,
  initialOpen = null,
}: {
  hub: StaffFeatureHub;
  onChanged: () => void;
  /** A row's detail open (tests). */
  initialOpen?: FeatureKey | null;
}) {
  const intl = useIntl();
  const staff = useStaff();
  const can = {
    tier: staffCan(staff.levels, 'premium.config'),
    toggle: staffCan(staff.levels, 'flags.toggle'),
    rollout: staffCan(staff.levels, 'flags.rollout'),
  };
  const [filter, setFilter] = useState<Filter>('all');
  const [q, setQ] = useState('');
  const [dialog, setDialog] = useState<Dialog | null>(null);
  const [open, setOpen] = useState<FeatureKey | null>(initialOpen);
  const name = (r: StaffHubRow) => intl.formatMessage({ id: r.labelId });
  const help = (r: StaffHubRow) => intl.formatMessage({ id: r.helpId });
  const match = (r: StaffHubRow) =>
    (filter === 'all' || r.tier === filter) &&
    (!q.trim() || `${name(r)} ${help(r)} ${r.key}`.toLowerCase().includes(q.trim().toLowerCase()));
  const shown = hub.features.filter(match);
  const count = (t: FeatureTier) => hub.features.filter((r) => r.tier === t).length;
  const p = hub.premium;
  const tiles: StatItem[] = [
    {
      key: 'families',
      label: <FormattedMessage id="hub.kpi.premiumFamilies" />,
      value: `${num(intl, p.families)}${p.capped ? '+' : ''}`,
      foot: <FormattedMessage id="hub.kpi.premiumFoot" values={{ paid: p.paid, admin: p.admin }} />,
    },
    ...featureTiers.map((t): StatItem => ({
      key: t,
      label: <FormattedMessage id={`hub.kpi.tier.${t}`} />,
      value: count(t),
      active: filter === t,
      onClick: () => setFilter(filter === t ? 'all' : t),
    })),
  ];
  const openRow = hub.features.find((r) => r.key === open) ?? null;
  const onRollout = (row: StaffHubRow, flag: StaffHubFlagState, level: RolloutLevel) =>
    setDialog({ kind: 'rollout', row, flag, level });
  const onKill = (row: StaffHubRow, flag: StaffHubFlagState) =>
    setDialog({ kind: 'kill', row, flag });
  return (
    <div className="grid min-w-0 gap-4">
      <StatTiles items={tiles} />
      <div className="overflow-hidden rounded-xl border bg-card">
        <FilterBar
          active={!!q || filter !== 'all'}
          onClear={() => {
            setQ('');
            setFilter('all');
          }}
          shown={shown.length}
          total={hub.features.length}
        >
          <SearchInput
            value={q}
            onChange={setQ}
            placeholder={intl.formatMessage({ id: 'features.search' })}
          />
        </FilterBar>
        {shown.length === 0 ? (
          <EmptyState icon={Search} title={<FormattedMessage id="features.noMatch" />} />
        ) : (
          <TableScroll min={900}>
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
                    <FormattedMessage id="hub.col.rollout" />
                  </th>
                  <th>
                    <FormattedMessage id="hub.col.families" />
                  </th>
                  <th className="w-24">
                    <FormattedMessage id="hub.col.kill" />
                  </th>
                  <th className="w-10">
                    <span className="sr-only">
                      <FormattedMessage id="hub.col.detail" />
                    </span>
                  </th>
                </tr>
              </thead>
              {hub.groups.map((g) => {
                const rows = shown.filter((r) => r.group === g);
                if (!rows.length) return null;
                return (
                  <tbody key={g}>
                    <tr className="cl-group-row">
                      <th colSpan={6} scope="rowgroup">
                        <FormattedMessage id={`hub.group.${g}`} />
                        <span className="font-normal text-muted-foreground"> · {rows.length}</span>
                      </th>
                    </tr>
                    {rows.map((row) => (
                      <FeatureRow
                        key={row.key}
                        row={row}
                        premiumFamilies={p.families}
                        can={can}
                        onTier={(tier) => setDialog({ kind: 'tier', row, tier })}
                        onRollout={onRollout}
                        onKill={onKill}
                        onOpen={() => setOpen(row.key)}
                      />
                    ))}
                  </tbody>
                );
              })}
            </table>
          </TableScroll>
        )}
      </div>
      {openRow && (
        <DetailSheet title={name(openRow)} onClose={() => setOpen(null)}>
          <FeatureDetail
            row={openRow}
            premiumFamilies={p.families}
            can={can}
            onRollout={onRollout}
            onKill={onKill}
            onChanged={onChanged}
          />
        </DetailSheet>
      )}
      {dialog?.kind === 'tier' && (
        <TierDialog
          row={dialog.row}
          tier={dialog.tier}
          onClose={() => setDialog(null)}
          onDone={() => {
            setDialog(null);
            onChanged();
          }}
        />
      )}
      {dialog?.kind === 'rollout' && (
        <RolloutDialog
          row={dialog.row}
          flag={dialog.flag}
          level={dialog.level}
          onClose={() => setDialog(null)}
          onDone={() => {
            setDialog(null);
            onChanged();
          }}
        />
      )}
      {dialog?.kind === 'kill' && (
        <KillDialog
          row={dialog.row}
          flag={dialog.flag}
          onClose={() => setDialog(null)}
          onDone={() => {
            setDialog(null);
            onChanged();
          }}
        />
      )}
    </div>
  );
}

type Can = { tier: boolean; toggle: boolean; rollout: boolean };

function FeatureRow({
  row,
  premiumFamilies,
  can,
  onTier,
  onRollout,
  onKill,
  onOpen,
}: {
  row: StaffHubRow;
  premiumFamilies: number;
  can: Can;
  onTier: (tier: FeatureTier) => void;
  onRollout: (row: StaffHubRow, flag: StaffHubFlagState, level: RolloutLevel) => void;
  onKill: (row: StaffHubRow, flag: StaffHubFlagState) => void;
  onOpen: () => void;
}) {
  const intl = useIntl();
  const name = intl.formatMessage({ id: row.labelId });
  const killed = row.flag ? !row.flag.enabled : false;
  return (
    <tr className={cn(killed && 'bg-destructive/5')}>
      <td className="max-w-[22rem]">
        <span className="flex items-center gap-1">
          <button type="button" className="link-button text-left font-medium" onClick={onOpen}>
            {name}
          </button>
          <Hint label={intl.formatMessage({ id: row.helpId })}>
            <FormattedMessage id={row.helpId} />
          </Hint>
        </span>
        {row.grace && (
          <span className="block text-xs text-muted-foreground">
            <FormattedMessage
              id="hub.grace.until"
              values={{ date: dayText(intl, row.grace.until) }}
            />
          </span>
        )}
        {row.subFlags.length > 0 && (
          <span className="block text-xs text-muted-foreground">
            <FormattedMessage id="hub.subFlags.count" values={{ n: row.subFlags.length }} />
          </span>
        )}
      </td>
      <td>
        <TierSelect row={row} disabled={!can.tier} onPick={onTier} />
      </td>
      <td>
        {row.flag ? (
          <RolloutSelect
            label={intl.formatMessage({ id: 'hub.rollout.label' }, { feature: name })}
            flag={row.flag}
            disabled={!can.rollout}
            onPick={(level) => onRollout(row, row.flag!, level)}
          />
        ) : (
          <span className="text-[13px] text-muted-foreground">
            <FormattedMessage id="hub.rollout.none" />
          </span>
        )}
      </td>
      <td className="text-[13px]">
        <FamilyCounts row={row} premiumFamilies={premiumFamilies} />
      </td>
      <td>
        {row.flag ? (
          <KillSwitch
            name={name}
            flag={row.flag}
            disabled={!can.toggle}
            onToggle={() => onKill(row, row.flag!)}
          />
        ) : (
          <span className="text-muted-foreground">—</span>
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

export function RolloutSelect({
  label,
  flag,
  disabled,
  onPick,
}: {
  label: string;
  flag: StaffHubFlagState;
  disabled: boolean;
  onPick: (level: RolloutLevel) => void;
}) {
  const intl = useIntl();
  const level = rolloutLevel(flag);
  const text = (l: RolloutLevel) =>
    intl.formatMessage(
      { id: `hub.rollout.${l === 'internal' && flag.families.length ? 'internalSome' : l}` },
      { n: flag.families.length },
    );
  if (disabled) {
    return (
      <Pill tone={level === 'all' ? 'ok' : level === 'off' ? 'muted' : 'purple'}>
        {text(level)}
      </Pill>
    );
  }
  return (
    <SelectMenu
      className="min-w-40"
      label={label}
      value={level}
      options={rolloutLevels.map((l) => ({ value: l, label: text(l) }))}
      onChange={(l) => onPick(l)}
    />
  );
}

function KillSwitch({
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
        aria-label={intl.formatMessage({ id: 'hub.kill.label' }, { feature: name })}
        disabled={disabled}
        title={disabled ? intl.formatMessage({ id: 'features.toggleRole' }) : undefined}
        // Confirmed in a dialog first (A11): turning off can show families a notice.
        onCheckedChange={onToggle}
      />
      {!flag.enabled && (
        <span className="text-xs font-medium text-destructive">
          <FormattedMessage id="hub.kill.off" />
        </span>
      )}
    </span>
  );
}

/** Who has it beyond the rollout: Premium families, the beta list, per-family overrides. */
function FamilyCounts({ row, premiumFamilies }: { row: StaffHubRow; premiumFamilies: number }) {
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
  if (!parts.length) return <span className="text-muted-foreground">—</span>;
  return (
    <span className="grid gap-0.5">
      {parts.map((p, i) => (
        <span key={i} className={i ? 'text-muted-foreground' : undefined}>
          {p}
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
 * One feature in full: its help, Gói, each switch (main and parts, e.g. the assistant's photos,
 * care, live, writes and upsell), the beta list, the 30-day grace and the overrides.
 */
export function FeatureDetail({
  row,
  premiumFamilies,
  can,
  onRollout,
  onKill,
  onChanged,
}: {
  row: StaffHubRow;
  premiumFamilies: number;
  can: Can;
  onRollout: (row: StaffHubRow, flag: StaffHubFlagState, level: RolloutLevel) => void;
  onKill: (row: StaffHubRow, flag: StaffHubFlagState) => void;
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
                    <KillSwitch
                      name={flagName}
                      flag={f}
                      disabled={!can.toggle}
                      onToggle={() => onKill(row, f)}
                    />
                  </div>
                  <RolloutSelect
                    label={intl.formatMessage({ id: 'hub.rollout.label' }, { feature: flagName })}
                    flag={f}
                    disabled={!can.rollout}
                    onPick={(level) => onRollout(row, f, level)}
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

/** Phát hành of the feature (or one of its switches); picked families for "Nội bộ" and Beta. */
export function RolloutDialog({
  row,
  flag,
  level,
  onClose,
  onDone,
}: {
  row: StaffHubRow;
  flag: StaffHubFlagState;
  level: RolloutLevel;
  onClose: () => void;
  onDone: () => void;
}) {
  const intl = useIntl();
  const api = useApi();
  const main = flag.key === row.flag?.key;
  const [families, setFamilies] = useState(flag.families);
  const [beta, setBeta] = useState(row.betaFamilies);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const name = intl.formatMessage({ id: main ? row.labelId : `flag.${flag.key}` });
  const withBeta = main && row.tier === 'beta';
  const betaChanged = JSON.stringify(beta) !== JSON.stringify(row.betaFamilies);
  return (
    <Modal
      wide={level === 'internal' || withBeta}
      title={<FormattedMessage id="hub.rollout.title" values={{ feature: name }} />}
      onClose={onClose}
    >
      <Notice tone="info">
        <FormattedMessage id={`hub.rolloutNote.${level}`} />
        {row.tier === 'premium' && (
          <>
            {' '}
            <FormattedMessage id="hub.rolloutNote.premium" />
          </>
        )}
      </Notice>
      {!flag.enabled && (
        <Notice tone="warn">
          <FormattedMessage id="hub.rolloutNote.killed" />
        </Notice>
      )}
      {level === 'internal' && (
        <div className="grid gap-2">
          <span className="text-[13px] font-medium">
            <FormattedMessage id="hub.rollout.families" />
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
          disabled={busy}
          onClick={() => {
            setBusy(true);
            setError(null);
            setFeatureRollout(api, {
              feature: row.key,
              ...(main ? {} : { flag: flag.key }),
              ...rolloutFields(level),
              ...(level === 'internal' ? { families } : {}),
              ...(withBeta && betaChanged ? { betaFamilies: beta } : {}),
            })
              .then(() => {
                toast.success(intl.formatMessage({ id: 'hub.rollout.done' }, { feature: name }));
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

/** Công tắc khẩn: off for every family at once (Premium and overrides too), with the notice. */
export function KillDialog({
  row,
  flag,
  onClose,
  onDone,
}: {
  row: StaffHubRow;
  flag: StaffHubFlagState;
  onClose: () => void;
  onDone: () => void;
}) {
  const intl = useIntl();
  const api = useApi();
  const main = flag.key === row.flag?.key;
  const name = intl.formatMessage({ id: main ? row.labelId : `flag.${flag.key}` });
  const off = flag.enabled;
  const [notify, setNotify] = useState(true);
  const [notice, setNotice] = useState(() => defaultNotice(flag.key, name));
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  return (
    <Modal
      title={
        <FormattedMessage
          id={off ? 'hub.kill.offTitle' : 'hub.kill.onTitle'}
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
        <FormattedMessage id={off ? 'hub.kill.offNote' : 'hub.kill.onNote'} />
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
            setFeatureRollout(api, {
              feature: row.key,
              ...(main ? {} : { flag: flag.key }),
              enabled: !off,
              notice: off && notify && notice.trim() ? notice.trim() : null,
            })
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
          <FormattedMessage id={off ? 'hub.kill.confirmOff' : 'hub.kill.confirmOn'} />
        </Button>
      </div>
    </Modal>
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
