import {
  premiumOverviewRanges,
  type OverviewShare,
  type PremiumOverviewRange,
  type StaffPremiumOverview,
} from '@child-life/contracts';
import { useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl, type IntlShape } from 'react-intl';
import { Bar, BarChart, CartesianGrid, XAxis, YAxis } from 'recharts';
import {
  ChartContainer,
  ChartLegend,
  ChartLegendContent,
  ChartTooltip,
  ChartTooltipContent,
  type ChartConfig,
} from '@/components/ui/chart';
import { useLoad } from '../api';
import { Kpi, Loaded, Panel, Segmented } from '../ui';

/**
 * Tính năng & Premium › Tổng quan (Figma 970:14756 PT01, D-101): Free / Premium families,
 * conversion, storage add-ons, new families and new Premium over the range, how often allowances
 * run out, store renewals and what needs a hand. Counts only, never a family's content. Revenue,
 * store fees and the cost to serve arrive with in-app purchase and cost metering: shown "—".
 */
export function PremiumOverviewLoader({ onOpenJobs }: { onOpenJobs?: () => void }) {
  const intl = useIntl();
  const [range, setRange] = useState<PremiumOverviewRange>('30d');
  const [load, reload] = useLoad<StaffPremiumOverview>(
    'staffPremiumOverview',
    { range },
    `premium-overview-${range}`,
  );
  return (
    <div className="grid min-w-0 gap-5">
      <div className="flex flex-wrap items-center gap-3">
        <p className="text-[13px] text-muted-foreground">
          <FormattedMessage id="pov.note" />
        </p>
        <span className="ml-auto">
          <Segmented
            label={intl.formatMessage({ id: 'pov.range' })}
            value={range}
            onChange={setRange}
            options={premiumOverviewRanges.map((r) => ({
              value: r,
              label: <FormattedMessage id={`pov.range.${r}`} />,
            }))}
          />
        </span>
      </div>
      <Loaded load={load} reload={reload}>
        {(data) => <PremiumOverviewView data={data} onOpenJobs={onOpenJobs} />}
      </Loaded>
    </div>
  );
}

const pct = (intl: IntlShape, s: OverviewShare) =>
  s.of > 0 ? intl.formatNumber(s.n / s.of, { style: 'percent', maximumFractionDigits: 0 }) : '—';

function Row({ label, value }: { label: ReactNode; value: ReactNode }) {
  return (
    <div className="flex items-baseline gap-3 text-[13px]">
      <span className="text-muted-foreground">{label}</span>
      <span className="ml-auto font-semibold tabular-nums">{value}</span>
    </div>
  );
}

function bucketLabel(intl: IntlShape, iso: string, range: PremiumOverviewRange) {
  const d = new Date(iso);
  if (range === '12m') {
    return intl.locale.startsWith('vi')
      ? `T${d.getUTCMonth() + 1}`
      : intl.formatDate(d, { month: 'short', timeZone: 'UTC' });
  }
  return intl.formatDate(d, { day: '2-digit', month: '2-digit', timeZone: 'UTC' });
}

export function PremiumOverviewView({
  data,
  onOpenJobs,
}: {
  data: StaffPremiumOverview;
  onOpenJobs?: () => void;
}) {
  const intl = useIntl();
  const n = (v: number) => intl.formatNumber(v);
  const f = data.families;
  const conversion = f.total > 0 ? f.premium / f.total : null;
  const money = (v: number | null) =>
    v === null ? '—' : intl.formatNumber(v, { style: 'currency', currency: 'VND' });
  const chartConfig = {
    newFamilies: {
      label: intl.formatMessage({ id: 'pov.chart.newFamilies' }),
      color: 'var(--chart-1)',
    },
    newPremium: {
      label: intl.formatMessage({ id: 'pov.chart.newPremium' }),
      color: 'var(--chart-2)',
    },
  } satisfies ChartConfig;
  const series = data.trend.map((b) => ({
    label: bucketLabel(intl, b.start, data.range),
    newFamilies: b.newFamilies,
    newPremium: b.newPremium,
  }));
  return (
    <div className="grid min-w-0 gap-4">
      <div className="grid grid-cols-2 gap-3 md:grid-cols-3 xl:grid-cols-6">
        <Kpi
          label={<FormattedMessage id="pov.kpi.free" />}
          value={n(f.free)}
          foot={
            f.growthPct === null ? (
              <FormattedMessage id="pov.kpi.newFamilies" values={{ n: f.newInRange }} />
            ) : (
              <FormattedMessage
                id="pov.kpi.growth"
                values={{ pct: `${f.growthPct > 0 ? '+' : ''}${f.growthPct}%` }}
              />
            )
          }
          tone={f.growthPct !== null && f.growthPct > 0 ? 'up' : 'muted'}
        />
        <Kpi
          label={<FormattedMessage id="pov.kpi.premium" />}
          value={n(f.premium)}
          foot={
            <FormattedMessage
              id="pov.kpi.conversion"
              values={{
                pct:
                  conversion === null
                    ? '—'
                    : intl.formatNumber(conversion, {
                        style: 'percent',
                        maximumFractionDigits: 1,
                      }),
              }}
            />
          }
        />
        <Kpi
          label={<FormattedMessage id="pov.kpi.addOns" />}
          value={n(data.addOns.total)}
          foot={
            <FormattedMessage
              id="pov.kpi.addOnsSplit"
              values={{ a: data.addOns.storage20, b: data.addOns.storage50 }}
            />
          }
        />
        <Kpi
          label={<FormattedMessage id="pov.kpi.gross" />}
          value={money(data.revenue.gross)}
          foot={<FormattedMessage id="pov.kpi.grossFoot" />}
        />
        <Kpi
          label={<FormattedMessage id="pov.kpi.net" />}
          value={money(data.revenue.net)}
          foot={<FormattedMessage id="pov.kpi.netFoot" />}
        />
        <Kpi
          label={<FormattedMessage id="pov.kpi.cost" />}
          value={money(data.revenue.costPerPremium)}
          foot={<FormattedMessage id="pov.kpi.costFoot" />}
        />
      </div>
      <Panel
        title={<FormattedMessage id="pov.chart.title" />}
        note={<FormattedMessage id="pov.chart.note" />}
      >
        <div className="px-5 pb-4">
          <ChartContainer
            config={chartConfig}
            className="aspect-auto h-[240px] w-full"
            role="img"
            aria-label={intl.formatMessage({ id: 'pov.chart.title' })}
          >
            <BarChart data={series} margin={{ top: 12, right: 12, left: 0, bottom: 0 }}>
              <CartesianGrid vertical={false} />
              <XAxis dataKey="label" tickLine={false} axisLine={false} tickMargin={8} />
              <YAxis width={36} tickLine={false} axisLine={false} allowDecimals={false} />
              <ChartTooltip
                cursor={{ fill: 'var(--muted)' }}
                content={<ChartTooltipContent className="min-w-40" />}
              />
              <ChartLegend content={<ChartLegendContent />} />
              <Bar
                dataKey="newFamilies"
                fill="var(--color-newFamilies)"
                radius={[3, 3, 0, 0]}
                maxBarSize={18}
              />
              <Bar
                dataKey="newPremium"
                fill="var(--color-newPremium)"
                radius={[3, 3, 0, 0]}
                maxBarSize={18}
              />
            </BarChart>
          </ChartContainer>
        </div>
      </Panel>
      <div className="grid gap-4 lg:grid-cols-3">
        <Panel title={<FormattedMessage id="pov.limits.title" />}>
          <div className="grid gap-3 px-5 pb-5">
            <Row
              label={<FormattedMessage id="pov.limits.lumi" />}
              value={pct(intl, data.limits.premiumLumiOut)}
            />
            <Row
              label={<FormattedMessage id="pov.limits.video" />}
              value={pct(intl, data.limits.premiumVideoOut)}
            />
            <Row
              label={<FormattedMessage id="pov.limits.storage" />}
              value={pct(intl, data.limits.storage80)}
            />
            <Row
              label={<FormattedMessage id="pov.limits.trial" />}
              value={pct(intl, data.limits.freeTrialOut)}
            />
          </div>
        </Panel>
        <Panel
          title={<FormattedMessage id="pov.renewals.title" />}
          note={
            data.renewals.active === 0 ? <FormattedMessage id="pov.renewals.none" /> : undefined
          }
        >
          <div className="grid gap-3 px-5 pb-5">
            <Row
              label={<FormattedMessage id="pov.renewals.active" />}
              value={n(data.renewals.active)}
            />
            <Row
              label={<FormattedMessage id="pov.renewals.due" />}
              value={n(data.renewals.dueInRange)}
            />
            <Row
              label={<FormattedMessage id="pov.renewals.cancelled" />}
              value={n(data.renewals.cancelled)}
            />
            <Row
              label={<FormattedMessage id="pov.renewals.issue" />}
              value={n(data.renewals.billingIssue)}
            />
            <Row
              label={<FormattedMessage id="pov.renewals.refunded" />}
              value={n(data.renewals.refunded)}
            />
          </div>
        </Panel>
        <Panel
          title={<FormattedMessage id="pov.attention.title" />}
          className="bg-amber-50 dark:bg-amber-950/30"
        >
          <div className="grid gap-3 px-5 pb-5">
            <Row
              label={<FormattedMessage id="pov.attention.jobs" />}
              value={n(data.attention.failedJobs24h)}
            />
            <Row
              label={<FormattedMessage id="pov.attention.held" />}
              value={n(data.attention.held)}
            />
            <Row
              label={<FormattedMessage id="pov.attention.unmatched" />}
              value={n(data.attention.unmatched)}
            />
            {onOpenJobs && (
              <button
                type="button"
                className="text-left text-[13px] font-semibold text-primary"
                onClick={onOpenJobs}
              >
                <FormattedMessage id="pov.attention.open" />
              </button>
            )}
          </div>
        </Panel>
      </div>
      {data.capped && (
        <p className="text-xs text-muted-foreground">
          <FormattedMessage id="pov.capped" />
        </p>
      )}
    </div>
  );
}
