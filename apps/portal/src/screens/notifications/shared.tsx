import {
  destinationChain,
  notificationDestinations,
  notificationTemplates,
  staffCan,
  type NotificationDeliveryState,
  type NotificationDestinationId,
  type NotificationStatCounts,
  type NotificationStatMetric,
  type NotificationTemplateStatus,
  type StaffLevels,
} from '@child-life/contracts';
import { ArrowRight } from 'lucide-react';
import { useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl, type IntlShape } from 'react-intl';
import { Input } from '@/components/ui/input';
import type { ApiError } from '../../api';
import { ZONE, pct } from '../../format';
import { Button, Pill, SelectMenu, errorMessageId, type PillTone } from '../../ui';

/**
 * Notifications & Engagement (P-174, docs/notifications/): shared helpers for the tabs. Every
 * label comes from the `ntf.*` catalog (D-012); the contract's bilingual strings (trigger,
 * recipients, destination screens) are picked by the Portal's language.
 */

// ---------- Tabs and addresses ----------

export const notificationTabs = [
  'overview',
  'templates',
  // "Gửi thử" (D-092): a real push to the staff member's own phone, dev only.
  'test',
  'catalog',
  'delivery',
  'journeys',
  'timeline',
  'analytics',
  'settings',
] as const;
export type NotificationTab = (typeof notificationTabs)[number];

/** The page opens with notifications.view, or notifications.edit (content experts: Templates). */
export function canOpenNotifications(levels: StaffLevels): boolean {
  return staffCan(levels, 'notifications.view') || staffCan(levels, 'notifications.edit');
}

/**
 * Tabs a staff member may open: Templates with view or edit; the family timeline with its own
 * (audited) permission; everything else with notifications.view.
 */
export function visibleTabs(levels: StaffLevels): NotificationTab[] {
  const view = staffCan(levels, 'notifications.view');
  return notificationTabs.filter((t) =>
    t === 'templates'
      ? view || staffCan(levels, 'notifications.edit')
      : t === 'test'
        ? staffCan(levels, 'notifications.edit')
        : t === 'timeline'
          ? staffCan(levels, 'notifications.timeline')
          : view,
  );
}

export interface NtfLocation {
  tab: NotificationTab;
  /** `/notifications/templates/<id>`: the editor. */
  template?: string;
  /** `/notifications/timeline/F-XXXX`: a family's timeline. */
  code?: string;
}

export const NTF_BASE = '/notifications';

/** "/notifications/templates/care.rule_due" → { tab: 'templates', template: 'care.rule_due' }. */
export function locationOf(pathname: string, allowed: readonly NotificationTab[]): NtfLocation {
  const rest = pathname.startsWith(`${NTF_BASE}/`)
    ? pathname
        .slice(NTF_BASE.length + 1)
        .split('/')
        .filter(Boolean)
        .map((s) => {
          try {
            return decodeURIComponent(s);
          } catch {
            return s;
          }
        })
    : [];
  const [first, second] = rest;
  const fallback: NtfLocation = { tab: allowed[0] ?? 'overview' };
  const tab = notificationTabs.find((t) => t === (first ?? 'overview'));
  if (!tab || !allowed.includes(tab)) return fallback;
  if (tab === 'templates' && second && second in notificationTemplates)
    return { tab, template: second };
  if (tab === 'timeline' && second) {
    const code = normalizeFamilyCode(second);
    return code ? { tab, code } : { tab };
  }
  return { tab };
}

export function pathOf(loc: NtfLocation): string {
  if (loc.tab === 'overview') return NTF_BASE;
  if (loc.tab === 'templates' && loc.template)
    return `${NTF_BASE}/templates/${encodeURIComponent(loc.template)}`;
  if (loc.tab === 'timeline' && loc.code) return `${NTF_BASE}/timeline/${loc.code}`;
  return `${NTF_BASE}/${loc.tab}`;
}

/** "f-7q2k " → "F-7Q2K"; null when it is not a family code. */
export function normalizeFamilyCode(raw: string): string | null {
  const code = raw.trim().toUpperCase();
  return /^F-[A-Z2-9]{4}$/.test(code) ? code : null;
}

// ---------- Language ----------

export type Lang = 'vi' | 'en';
export const langOf = (intl: IntlShape): Lang => (intl.locale.startsWith('en') ? 'en' : 'vi');
/** The contract's `{ vi, en }` copy in the Portal's language. */
export const pick = (intl: IntlShape, text: { vi: string; en: string }) => text[langOf(intl)];

/** A translated label when the catalog has one, else the raw value (a newer server's code). */
export function labelOr(intl: IntlShape, id: string, raw: string): string {
  return intl.messages[id] ? intl.formatMessage({ id }) : raw;
}

// ---------- Dates ----------

/** Today in Vietnam ("2026-10-22"). */
export function vnToday(now = new Date()): string {
  return new Intl.DateTimeFormat('en-CA', { timeZone: ZONE }).format(now);
}

const addDays = (day: string, n: number) =>
  new Date(Date.parse(`${day}T00:00:00Z`) + n * 86_400_000).toISOString().slice(0, 10);

/** The last [days] days, today included (Vietnam days). */
export function rangeEnding(days: number, now = new Date()): { from: string; to: string } {
  const to = vnToday(now);
  return { from: addDays(to, -(days - 1)), to };
}

/** The server takes at most 92 days, `from` ≤ `to`, nothing after today. */
export const MAX_RANGE_DAYS = 92;
export function validRange(from: string, to: string, now = new Date()): boolean {
  const day = /^\d{4}-\d{2}-\d{2}$/;
  if (!day.test(from) || !day.test(to)) return false;
  if (Number.isNaN(Date.parse(from)) || Number.isNaN(Date.parse(to))) return false;
  if (from > to || to > vnToday(now)) return false;
  return (Date.parse(to) - Date.parse(from)) / 86_400_000 < MAX_RANGE_DAYS;
}

/** "22/10/2026 09:41" in Vietnam time. */
export function at(intl: IntlShape, iso: string | null | undefined): string {
  if (!iso) return '—';
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return '—';
  return intl.formatDate(d, { dateStyle: 'short', timeStyle: 'short', timeZone: ZONE });
}

/** "22/10/2026" for a yyyy-mm-dd day. */
export function dayLabel(intl: IntlShape, day: string): string {
  return intl.formatDate(`${day}T05:00:00Z`, { dateStyle: 'short', timeZone: ZONE });
}

export type RangeChoice = { preset: '7' | '30' | '90' | 'custom'; from: string; to: string };
export const defaultRange = (days: 7 | 30 | 90 = 7): RangeChoice => ({
  preset: String(days) as RangeChoice['preset'],
  ...rangeEnding(days),
});

/** 7 / 30 / 90 days or a custom range (≤ 92 days), like Phân tích sản phẩm. */
export function RangePicker({
  value,
  onChange,
}: {
  value: RangeChoice;
  onChange: (v: RangeChoice) => void;
}) {
  const intl = useIntl();
  const [preset, setPreset] = useState(value.preset);
  const [from, setFrom] = useState(value.from);
  const [to, setTo] = useState(value.to);
  const [invalid, setInvalid] = useState(false);
  return (
    <div className="flex flex-wrap items-end gap-2">
      <SelectMenu
        label={intl.formatMessage({ id: 'ntf.range' })}
        value={preset}
        options={[
          ...(['7', '30', '90'] as const).map((d) => ({
            value: d,
            label: intl.formatMessage({ id: 'ntf.range.days' }, { n: Number(d) }),
          })),
          { value: 'custom' as const, label: intl.formatMessage({ id: 'ntf.range.custom' }) },
        ]}
        onChange={(p) => {
          setPreset(p);
          setInvalid(false);
          if (p !== 'custom') onChange({ preset: p, ...rangeEnding(Number(p)) });
        }}
      />
      {preset === 'custom' && (
        <>
          <label className="grid gap-1 text-[13px] font-medium">
            <FormattedMessage id="ntf.range.from" />
            <Input
              type="date"
              className="w-40"
              value={from}
              max={vnToday()}
              onChange={(e) => setFrom(e.target.value)}
            />
          </label>
          <label className="grid gap-1 text-[13px] font-medium">
            <FormattedMessage id="ntf.range.to" />
            <Input
              type="date"
              className="w-40"
              value={to}
              max={vnToday()}
              onChange={(e) => setTo(e.target.value)}
            />
          </label>
          <Button
            onClick={() => {
              const ok = validRange(from, to);
              setInvalid(!ok);
              if (ok) onChange({ preset: 'custom', from, to });
            }}
          >
            <FormattedMessage id="ntf.range.apply" />
          </Button>
        </>
      )}
      {invalid && (
        <p className="error w-full" role="alert">
          <FormattedMessage id="ntf.range.invalid" values={{ max: MAX_RANGE_DAYS }} />
        </p>
      )}
    </div>
  );
}

// ---------- Counts and rates ----------

/** Adds up stat counters (a missing metric counts as 0 inside a day that has data). */
export function sumCounts(list: readonly NotificationStatCounts[]): NotificationStatCounts {
  const out: NotificationStatCounts = {};
  for (const counts of list) {
    for (const [k, v] of Object.entries(counts) as Array<[NotificationStatMetric, number]>) {
      out[k] = (out[k] ?? 0) + (v ?? 0);
    }
  }
  return out;
}

/** numerator / denominator; null (shown "—") when the denominator is 0 or unknown, never 0 %. */
export function rate(numerator: number | null | undefined, denominator: number | null | undefined) {
  if (numerator == null || denominator == null || denominator <= 0) return null;
  return numerator / denominator;
}

export function rateText(intl: IntlShape, value: number | null): string {
  return value === null ? '—' : pct(intl, value, 1);
}

export const rateIds = ['acceptance', 'open', 'read', 'navigation', 'failure'] as const;
export type RateId = (typeof rateIds)[number];
export const rateDefinition: Record<
  RateId,
  { numerator: NotificationStatMetric; denominator: NotificationStatMetric }
> = {
  acceptance: { numerator: 'accepted', denominator: 'attempted' },
  open: { numerator: 'opened', denominator: 'inbox' },
  read: { numerator: 'read', denominator: 'inbox' },
  navigation: { numerator: 'navigated', denominator: 'opened' },
  failure: { numerator: 'failed', denominator: 'attempted' },
};

export interface RateRow {
  id: RateId;
  numerator: number;
  denominator: number;
  value: number | null;
}

/** The five rates of a set of counters (zero denominators give null, shown as "—"). */
export function notificationRates(counts: NotificationStatCounts): RateRow[] {
  return rateIds.map((id) => {
    const d = rateDefinition[id];
    const numerator = counts[d.numerator] ?? 0;
    const denominator = counts[d.denominator] ?? 0;
    return { id, numerator, denominator, value: rate(numerator, denominator) };
  });
}

/** Days in the response that have data (on or after `sourceStartDay`). */
export function daysWithData<T extends { day: string }>(
  days: readonly T[],
  sourceStartDay: string | null,
): T[] {
  if (!sourceStartDay) return [];
  return days.filter((d) => d.day >= sourceStartDay);
}

// ---------- Pills ----------

const deliveryTone: Record<NotificationDeliveryState, PillTone> = {
  pending: 'wait',
  scheduled: 'wait',
  attempted: 'info',
  accepted: 'ok',
  rejected: 'error',
  retry_pending: 'warn',
  failed: 'error',
  cancelled: 'muted',
  unknown: 'muted',
};

export function DeliveryPill({ state }: { state: NotificationDeliveryState | null }) {
  const intl = useIntl();
  if (!state) return <span className="muted">—</span>;
  return (
    <Pill tone={deliveryTone[state] ?? 'muted'}>
      {labelOr(intl, `ntf.delivery.${state}`, state)}
    </Pill>
  );
}

const templateTone: Record<NotificationTemplateStatus, PillTone> = {
  builtin: 'muted',
  draft: 'wait',
  ready_for_review: 'purple',
  published: 'ok',
  paused: 'warn',
  archived: 'muted',
};

export function TemplateStatusPill({ status }: { status: NotificationTemplateStatus }) {
  return (
    <Pill tone={templateTone[status] ?? 'muted'}>
      <FormattedMessage id={`ntf.tplStatus.${status}`} />
    </Pill>
  );
}

export function OnOffPill({ on, onId, offId }: { on: boolean; onId: string; offId: string }) {
  return (
    <Pill tone={on ? 'ok' : 'muted'}>
      <FormattedMessage id={on ? onId : offId} />
    </Pill>
  );
}

// ---------- Names ----------

/** The template's name in the Portal's language, or its id for an unknown one. */
export function templateName(intl: IntlShape, id: string | null): string {
  if (!id || id === 'none') return intl.formatMessage({ id: 'ntf.template.none' });
  const def = (
    notificationTemplates as Record<
      string,
      (typeof notificationTemplates)[keyof typeof notificationTemplates] | undefined
    >
  )[id];
  return def ? pick(intl, def.name) : id;
}

export function destinationName(intl: IntlShape, id: NotificationDestinationId | null): string {
  if (!id) return '—';
  const d = notificationDestinations[id];
  return d ? pick(intl, d.screen) : id;
}

/** "Nhắc việc → Hộp thông báo": where the app goes when the destination cannot open. */
export function FallbackChain({ id }: { id: NotificationDestinationId }) {
  const intl = useIntl();
  const chain = destinationChain(id);
  return (
    <span className="inline-flex flex-wrap items-center gap-1">
      {chain.map((d, i) => (
        <span key={d} className="inline-flex items-center gap-1">
          {i > 0 && <ArrowRight className="size-3 text-muted-foreground" aria-hidden="true" />}
          <span className={i === 0 ? 'font-medium' : undefined}>{destinationName(intl, d)}</span>
        </span>
      ))}
    </span>
  );
}

/** Screen, params, permission, fallback chain and completion of one destination. */
export function DestinationDetails({ id }: { id: NotificationDestinationId }) {
  const intl = useIntl();
  const d = notificationDestinations[id];
  if (!d) return <span>{id}</span>;
  return (
    <dl className="grid grid-cols-[minmax(0,9rem)_minmax(0,1fr)] gap-x-3 gap-y-1.5 text-sm">
      <dt className="text-muted-foreground">
        <FormattedMessage id="ntf.dest.screen" />
      </dt>
      <dd className="font-medium">{pick(intl, d.screen)}</dd>
      <dt className="text-muted-foreground">
        <FormattedMessage id="ntf.dest.path" />
      </dt>
      <dd className="font-mono text-[13px] break-all">{d.path}</dd>
      <dt className="text-muted-foreground">
        <FormattedMessage id="ntf.dest.params" />
      </dt>
      <dd>
        <ParamList id={id} />
      </dd>
      <dt className="text-muted-foreground">
        <FormattedMessage id="ntf.dest.permission" />
      </dt>
      <dd>
        <FormattedMessage id={`ntf.permission.${d.permission}`} />
      </dd>
      <dt className="text-muted-foreground">
        <FormattedMessage id="ntf.dest.fallback" />
      </dt>
      <dd>
        <FallbackChain id={id} />
      </dd>
      <dt className="text-muted-foreground">
        <FormattedMessage id="ntf.dest.completion" />
      </dt>
      <dd>
        {d.completion ? pick(intl, d.completion) : <FormattedMessage id="ntf.dest.openIsPoint" />}
      </dd>
    </dl>
  );
}

export function ParamList({ id }: { id: NotificationDestinationId }) {
  const d = notificationDestinations[id];
  if (!d.params.length)
    return (
      <span className="text-muted-foreground">
        <FormattedMessage id="ntf.dest.noParams" />
      </span>
    );
  return (
    <span className="flex flex-wrap gap-1">
      {d.params.map((p) => (
        <code key={p.key} className="rounded bg-muted px-1.5 py-0.5 text-[12px]">
          {p.key}
          {!p.required && (
            <span className="ml-1 font-sans text-muted-foreground">
              <FormattedMessage id="ntf.dest.optional" />
            </span>
          )}
        </code>
      ))}
    </span>
  );
}

// ---------- Errors ----------

const ntfReasons = [
  'stale',
  'template-invalid',
  'not-retryable',
  'invalid',
  'not-found',
  // Gửi thử (D-092)
  'dev-only',
  'test-recipient',
  'no-draft',
  'rate-limited',
  'not-a-member',
];

/** The callables' own reasons first, then the portal-wide mapping. */
export function ntfErrorId(error: ApiError): string {
  if (error.reason && ntfReasons.includes(error.reason)) return `ntf.error.${error.reason}`;
  return errorMessageId(error);
}

export function ErrorLine({ error }: { error: ApiError | null }) {
  if (!error) return null;
  return (
    <p className="error" role="alert">
      <FormattedMessage id={ntfErrorId(error)} />
    </p>
  );
}

/** A label with a definition behind "?"; used for KPI tiles and rate headers. */
export function Labelled({ label, hint }: { label: ReactNode; hint?: ReactNode }) {
  return (
    <span className="inline-flex items-center gap-1">
      {label}
      {hint}
    </span>
  );
}
