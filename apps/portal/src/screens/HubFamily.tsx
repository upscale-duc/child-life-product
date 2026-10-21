import {
  FULL_PREMIUM_GRANT_ID,
  staffCan,
  type FeatureKey,
  type FeatureOverrideState,
  type FeatureTier,
  type HouseholdPlan,
  type StaffFamilyQuota,
  type StaffHubFamily,
  type StaffHubFamilyAnswer,
  type StaffHubFamilyFeature,
} from '@child-life/contracts';
import { CircleCheck, CircleSlash, Search, Users } from 'lucide-react';
import { useId, useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl, type IntlShape } from 'react-intl';
import { toast } from 'sonner';
import { Badge } from '@/components/ui/badge';
import { Button as UiButton } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Switch } from '@/components/ui/switch';
import { ToggleGroup, ToggleGroupItem } from '@/components/ui/toggle-group';
import { cn } from '@/lib/utils';
import { ApiError, useApi, useLoad, type Api } from '../api';
import { EmptyState, Field, Notice, Section } from '../content-kit';
import { useStaff } from '../context';
import { ZONE } from '../format';
import {
  Button,
  ConfirmModal,
  Loaded,
  Modal,
  Pill,
  TableScroll,
  errorMessageId,
  type PillTone,
} from '../ui';
import { FamilyQuotaView } from './PremiumOps';

/**
 * Tính năng & Premium › Gia đình (plan §2.3): find a family by its code, an account email or a
 * baby's nickname (matched on the server, never sent back), then its plan, "Bật toàn bộ Premium"
 * (no end date by default; an admin grant skips the country, D-089), and every catalogue feature
 * with its state and why, a Bật / Tắt / Theo quy tắc override and "Thêm vào beta". Overrides are
 * per family: the household shares Premium. No reason is asked (D-090).
 */

const tierTone: Record<FeatureTier, PillTone> = { free: 'muted', premium: 'ok', beta: 'purple' };

/** Gói of a feature: Miễn phí · Premium · Beta. */
export function TierPill({ tier }: { tier: FeatureTier }) {
  return (
    <Pill tone={tierTone[tier]}>
      <FormattedMessage id={`hub.tier.${tier}`} />
    </Pill>
  );
}

// ---------- Calls ----------

export function findHubFamily(api: Api, q: string) {
  return api.call<StaffHubFamilyAnswer>('staffFeatureFamily', { q: q.trim() });
}

/** Bật / Tắt for this family, or `null` = Theo quy tắc (the override is removed). */
export function setFeatureOverride(
  api: Api,
  code: string,
  feature: FeatureKey,
  state: FeatureOverrideState | null,
) {
  return api.call('staffFeatureSetOverride', { code, feature, state });
}

/** "Bật toàn bộ Premium": no end unless a last day is picked (a Vietnam day, included). */
export function setFullPremium(api: Api, code: string, on: boolean, lastDay: string | null) {
  return api.call<{ on: boolean; until: string | null }>('staffFeatureFullPremium', {
    code,
    on,
    ...(on && lastDay ? { until: endOfDay(lastDay) } : {}),
  });
}

export function setBetaMember(api: Api, code: string, feature: FeatureKey, member: boolean) {
  return api.call('staffFeatureSetBeta', { code, feature, member });
}

/** The exclusive end of a Vietnam day ("2026-11-20" → 2026-11-20T17:00:00Z). */
export function endOfDay(day: string): string {
  return new Date(Date.parse(`${day}T00:00:00+07:00`) + 86_400_000).toISOString();
}

const asApiError = (e: unknown) => (e instanceof ApiError ? e : new ApiError('unknown', null));

/** "2026-11-30" for an exclusive end: the last Vietnam day included (a date input's value). */
const lastDayInput = (iso: string) =>
  new Intl.DateTimeFormat('en-CA', { timeZone: ZONE }).format(new Date(Date.parse(iso) - 1));

const lastDay = (intl: IntlShape, iso: string) =>
  intl.formatDate(new Date(Date.parse(iso) - 1), {
    day: 'numeric',
    month: 'numeric',
    year: 'numeric',
    timeZone: ZONE,
  });

// ---------- Search ----------

export function HubFamilies({
  initial = null,
  now = new Date(),
}: {
  /** An answer already looked up (tests). */
  initial?: StaffHubFamilyAnswer | null;
  now?: Date;
}) {
  const intl = useIntl();
  const api = useApi();
  const [q, setQ] = useState(initial?.family?.code ?? '');
  const [answer, setAnswer] = useState<StaffHubFamilyAnswer | null>(initial);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const look = async (query: string) => {
    if (!query.trim()) return;
    setBusy(true);
    setError(null);
    try {
      setAnswer(await findHubFamily(api, query));
    } catch (e) {
      setAnswer(null);
      setError(asApiError(e));
    } finally {
      setBusy(false);
    }
  };
  const family = answer?.family ?? null;
  return (
    <div className="grid min-w-0 gap-4">
      <form
        className="flex max-w-2xl flex-wrap gap-2"
        onSubmit={(e) => {
          e.preventDefault();
          void look(q);
        }}
      >
        <div className="relative min-w-0 flex-1">
          <Search
            className="pointer-events-none absolute top-1/2 left-2.5 size-4 -translate-y-1/2 text-muted-foreground"
            aria-hidden="true"
          />
          <Input
            className="pl-8"
            value={q}
            maxLength={254}
            onChange={(e) => setQ(e.target.value)}
            placeholder={intl.formatMessage({ id: 'hub.family.search' })}
            aria-label={intl.formatMessage({ id: 'hub.family.search' })}
          />
        </div>
        <Button kind="primary" type="submit" disabled={busy || !q.trim()}>
          <FormattedMessage id="hub.family.go" />
        </Button>
      </form>
      {error && (
        <p className="error" role="alert">
          <FormattedMessage id={errorMessageId(error)} />
        </p>
      )}
      {answer && !family && answer.matches.length === 0 && (
        <EmptyState icon={Users} title={<FormattedMessage id="hub.family.none" />}>
          <FormattedMessage id="hub.family.noneHelp" />
        </EmptyState>
      )}
      {answer && !family && answer.matches.length > 0 && (
        <MatchList
          answer={answer}
          onOpen={(code) => {
            setQ(code);
            void look(code);
          }}
        />
      )}
      {family && <FamilyCard family={family} now={now} onChanged={() => void look(family.code)} />}
      {!answer && !error && (
        <p className="text-sm text-muted-foreground">
          <FormattedMessage id="hub.family.hint" />
        </p>
      )}
    </div>
  );
}

/** Several families matched (an email in two families, a common nickname): pick one. */
export function MatchList({
  answer,
  onOpen,
}: {
  answer: StaffHubFamilyAnswer;
  onOpen: (code: string) => void;
}) {
  return (
    <Section
      flush
      title={<FormattedMessage id="hub.family.matches" values={{ n: answer.matches.length }} />}
      description={
        answer.matchedBy && <FormattedMessage id={`hub.family.matchedBy.${answer.matchedBy}`} />
      }
    >
      <ul className="divide-y">
        {answer.matches.map((m) => (
          <li key={m.code} className="flex flex-wrap items-center gap-x-4 gap-y-1 px-5 py-3">
            <span className="font-mono font-semibold">{m.code}</span>
            <span className="text-sm text-muted-foreground">{m.owner}</span>
            <span className="text-sm text-muted-foreground">
              <FormattedMessage id="hub.family.babies" values={{ n: m.babies }} />
            </span>
            <span className="ml-auto">
              <Button onClick={() => onOpen(m.code)}>
                <FormattedMessage id="hub.family.open" />
              </Button>
            </span>
          </li>
        ))}
      </ul>
    </Section>
  );
}

// ---------- One family ----------

const planTone: Record<HouseholdPlan, PillTone> = {
  free: 'muted',
  beta: 'purple',
  premium: 'ok',
  pending: 'wait',
  expired: 'warn',
};

const countryName = (locale: string, code: string) => {
  try {
    return new Intl.DisplayNames([locale], { type: 'region', fallback: 'none' }).of(code) ?? code;
  } catch {
    return code;
  }
};

export function FamilyCard({
  family,
  now,
  onChanged,
}: {
  family: StaffHubFamily;
  now: Date;
  onChanged: () => void;
}) {
  const intl = useIntl();
  const staff = useStaff();
  const canGrant = staffCan(staff.levels, 'premium.grant');
  const canBeta = staffCan(staff.levels, 'flags.rollout');
  const country = family.country
    ? `${countryName(intl.locale, family.country)} · ${family.country}`
    : null;
  return (
    <div className="grid min-w-0 gap-4">
      <div className="flex flex-wrap items-center gap-x-6 gap-y-2 rounded-xl border bg-card px-5 py-4 text-sm">
        <span className="font-mono text-base font-semibold">{family.code}</span>
        <span className="flex items-center gap-1.5">
          <span className="text-muted-foreground">
            <FormattedMessage id="premium.lookup.plan" />
          </span>
          <Pill tone={planTone[family.plan]}>
            <FormattedMessage id={`premium.plan.${family.plan}`} />
          </Pill>
          {family.validUntil && (
            <span className="text-muted-foreground">
              <FormattedMessage
                id="premium.lookup.until"
                values={{ until: lastDay(intl, family.validUntil) }}
              />
            </span>
          )}
        </span>
        <span>
          <span className="text-muted-foreground">
            <FormattedMessage id="premium.lookup.country" />
          </span>{' '}
          {country ?? (
            <span className="text-muted-foreground">
              <FormattedMessage id="premium.lookup.noCountry" />
            </span>
          )}
        </span>
        {family.internal && (
          <Badge variant="outline">
            <FormattedMessage id="hub.family.internal" />
          </Badge>
        )}
      </div>
      {!family.regionSupported && (
        <Notice tone="info">
          <FormattedMessage id="hub.family.regionNote" />
        </Notice>
      )}
      <FullPremium family={family} canEdit={canGrant} onChanged={onChanged} />
      <FamilyFeatures
        family={family}
        canOverride={canGrant}
        canBeta={canBeta}
        onChanged={onChanged}
      />
      <Section
        collapsible
        defaultOpen={false}
        title={<FormattedMessage id="hub.family.grants" />}
        summary={
          <FormattedMessage id="hub.family.grantsCount" values={{ n: family.grants.length }} />
        }
      >
        <GrantsTable family={family} canRevoke={canGrant} onChanged={onChanged} />
      </Section>
      <Section collapsible defaultOpen={false} title={<FormattedMessage id="hub.family.quota" />}>
        <QuotaLoader code={family.code} now={now} />
      </Section>
    </div>
  );
}

/** "Bật toàn bộ Premium": one switch; no end by default, an optional last day. */
function FullPremium({
  family,
  canEdit,
  onChanged,
}: {
  family: StaffHubFamily;
  canEdit: boolean;
  onChanged: () => void;
}) {
  const intl = useIntl();
  const [asking, setAsking] = useState<'on' | 'end' | 'off' | null>(null);
  const on = family.fullPremium.on;
  return (
    <section className="flex flex-wrap items-center gap-x-4 gap-y-2 rounded-xl border bg-card px-5 py-4">
      <div className="min-w-0 flex-1 basis-64">
        <p className="font-semibold">
          <FormattedMessage id="hub.full.title" />
        </p>
        <p className="text-[13px] text-muted-foreground">
          {on ? (
            family.fullPremium.until ? (
              <FormattedMessage
                id="hub.full.onUntil"
                values={{ until: lastDay(intl, family.fullPremium.until) }}
              />
            ) : (
              <FormattedMessage id="hub.full.onOpen" />
            )
          ) : (
            <FormattedMessage id="hub.full.help" />
          )}
        </p>
      </div>
      {on && canEdit && (
        // Turning it on again while it runs only moves the end (the credit month is kept).
        <Button kind="ghost" onClick={() => setAsking('end')}>
          <FormattedMessage id="hub.full.changeEnd" />
        </Button>
      )}
      <Switch
        checked={on}
        disabled={!canEdit}
        aria-label={intl.formatMessage({ id: 'hub.full.title' })}
        title={canEdit ? undefined : intl.formatMessage({ id: 'error.role' })}
        onCheckedChange={() => setAsking(on ? 'off' : 'on')}
      />
      {(asking === 'on' || asking === 'end') && (
        <FullPremiumDialog
          code={family.code}
          changeEnd={asking === 'end'}
          initialDay={
            asking === 'end' && family.fullPremium.until
              ? lastDayInput(family.fullPremium.until)
              : ''
          }
          onClose={() => setAsking(null)}
          onDone={() => {
            setAsking(null);
            onChanged();
          }}
        />
      )}
      {asking === 'off' && (
        <FullPremiumOff
          code={family.code}
          onClose={() => setAsking(null)}
          onDone={() => {
            setAsking(null);
            onChanged();
          }}
        />
      )}
    </section>
  );
}

export function FullPremiumDialog({
  code,
  changeEnd = false,
  initialDay = '',
  onClose,
  onDone,
}: {
  code: string;
  /** Premium is on already: only its end moves. */
  changeEnd?: boolean;
  initialDay?: string;
  onClose: () => void;
  onDone: () => void;
}) {
  const intl = useIntl();
  const api = useApi();
  const id = useId();
  const [day, setDay] = useState(initialDay);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  return (
    <Modal
      title={
        <FormattedMessage
          id={changeEnd ? 'hub.full.endTitle' : 'hub.full.onTitle'}
          values={{ code }}
        />
      }
      onClose={onClose}
    >
      {!changeEnd && (
        <p className="modal__sub">
          <FormattedMessage id="hub.full.onBody" />
        </p>
      )}
      <Field
        label={<FormattedMessage id="hub.full.until" />}
        htmlFor={id}
        help={<FormattedMessage id="hub.full.untilHelp" />}
      >
        <Input
          id={id}
          type="date"
          className="max-w-48"
          value={day}
          onChange={(e) => setDay(e.target.value)}
        />
      </Field>
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
            setFullPremium(api, code, true, day || null)
              .then(() => {
                toast.success(intl.formatMessage({ id: 'hub.full.doneOn' }, { code }));
                onDone();
              })
              .catch((e: unknown) => setError(asApiError(e)))
              .finally(() => setBusy(false));
          }}
        >
          <FormattedMessage id={changeEnd ? 'hub.full.confirmEnd' : 'hub.full.confirmOn'} />
        </Button>
      </div>
    </Modal>
  );
}

function FullPremiumOff({
  code,
  onClose,
  onDone,
}: {
  code: string;
  onClose: () => void;
  onDone: () => void;
}) {
  const intl = useIntl();
  const api = useApi();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  return (
    <ConfirmModal
      title={<FormattedMessage id="hub.full.offTitle" values={{ code }} />}
      confirm={<FormattedMessage id="hub.full.confirmOff" />}
      danger
      busy={busy}
      error={error}
      onCancel={onClose}
      onConfirm={() => {
        setBusy(true);
        setError(null);
        setFullPremium(api, code, false, null)
          .then(() => {
            toast.success(intl.formatMessage({ id: 'hub.full.doneOff' }, { code }));
            onDone();
          })
          .catch((e: unknown) => setError(asApiError(e)))
          .finally(() => setBusy(false));
      }}
    >
      <FormattedMessage id="hub.full.offBody" />
    </ConfirmModal>
  );
}

type OverrideChoice = 'on' | 'off' | 'rule';

/** Every catalogue feature for this family: has it or not and why, the override, beta. */
export function FamilyFeatures({
  family,
  canOverride,
  canBeta,
  onChanged,
}: {
  family: StaffHubFamily;
  canOverride: boolean;
  canBeta: boolean;
  onChanged: () => void;
}) {
  const intl = useIntl();
  const api = useApi();
  const [busy, setBusy] = useState<FeatureKey | null>(null);
  const [error, setError] = useState<ApiError | null>(null);
  const run = (key: FeatureKey, call: () => Promise<unknown>, done: string) => {
    setBusy(key);
    setError(null);
    call()
      .then(() => {
        toast.success(done);
        onChanged();
      })
      .catch((e: unknown) => setError(asApiError(e)))
      .finally(() => setBusy(null));
  };
  const on = family.features.filter((f) => f.on).length;
  return (
    <Section
      flush
      title={<FormattedMessage id="hub.family.features" />}
      description={
        <FormattedMessage
          id="hub.family.featuresCount"
          values={{ n: on, total: family.features.length }}
        />
      }
      hint={<FormattedMessage id="hub.family.overrideHint" />}
    >
      {error && (
        <p className="error px-5 pt-3" role="alert">
          <FormattedMessage id={errorMessageId(error)} />
        </p>
      )}
      <TableScroll min={760}>
        <table className="table">
          <thead>
            <tr>
              <th>
                <FormattedMessage id="hub.col.feature" />
              </th>
              <th>
                <FormattedMessage id="hub.col.now" />
              </th>
              <th>
                <FormattedMessage id="hub.col.override" />
              </th>
              <th>
                <span className="sr-only">
                  <FormattedMessage id="hub.col.beta" />
                </span>
              </th>
            </tr>
          </thead>
          <tbody>
            {family.features.map((f) => {
              const feature = intl.formatMessage({ id: `hub.feature.${f.key}` });
              const choice: OverrideChoice = f.override?.state ?? 'rule';
              return (
                <tr key={f.key}>
                  <td>
                    <span className="flex flex-wrap items-center gap-1.5 font-medium">
                      {feature}
                      <TierPill tier={f.tier} />
                    </span>
                  </td>
                  <td>
                    <WhyCell f={f} />
                  </td>
                  <td>
                    <ToggleGroup
                      type="single"
                      variant="outline"
                      size="sm"
                      value={choice}
                      disabled={!canOverride || busy === f.key}
                      aria-label={intl.formatMessage(
                        { id: 'hub.override.label' },
                        { feature, code: family.code },
                      )}
                      onValueChange={(v) => {
                        if (!v || v === choice) return;
                        const state = v === 'rule' ? null : (v as FeatureOverrideState);
                        run(
                          f.key,
                          () => setFeatureOverride(api, family.code, f.key, state),
                          intl.formatMessage(
                            { id: 'hub.override.done' },
                            { feature, code: family.code },
                          ),
                        );
                      }}
                    >
                      {(['on', 'off', 'rule'] as const).map((c) => (
                        <ToggleGroupItem key={c} value={c} className="px-2.5 text-xs">
                          <FormattedMessage id={`hub.override.${c}`} />
                        </ToggleGroupItem>
                      ))}
                    </ToggleGroup>
                  </td>
                  <td className="cell-actions">
                    {f.tier === 'beta' && canBeta && (
                      <UiButton
                        variant="ghost"
                        size="sm"
                        className="h-7 text-primary"
                        disabled={busy === f.key}
                        onClick={() =>
                          run(
                            f.key,
                            () => setBetaMember(api, family.code, f.key, !f.betaListed),
                            intl.formatMessage(
                              { id: f.betaListed ? 'hub.beta.removed' : 'hub.beta.added' },
                              { feature, code: family.code },
                            ),
                          )
                        }
                      >
                        <FormattedMessage id={f.betaListed ? 'hub.beta.remove' : 'hub.beta.add'} />
                      </UiButton>
                    )}
                    {f.tier === 'beta' && !canBeta && f.betaListed && (
                      <Badge variant="outline">
                        <FormattedMessage id="hub.beta.listed" />
                      </Badge>
                    )}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </TableScroll>
    </Section>
  );
}

/** "Có · Premium trả phí", "Không · chưa phát hành": the rule's answer (`hub.why.<code>`). */
export function WhyCell({ f }: { f: StaffHubFamilyFeature }) {
  const intl = useIntl();
  const detail: ReactNode[] = [];
  if (f.why === 'grace' && f.graceUntil) {
    detail.push(
      <FormattedMessage
        key="g"
        id="hub.why.until"
        values={{ date: lastDay(intl, f.graceUntil) }}
      />,
    );
  }
  if (f.override) {
    detail.push(
      <FormattedMessage
        key="o"
        id={f.override.until ? 'hub.override.byUntil' : 'hub.override.by'}
        values={{
          by: f.override.by.split(' ')[0],
          until: f.override.until ? lastDay(intl, f.override.until) : '',
        }}
      />,
    );
  }
  if (!f.on && f.visible) {
    detail.push(<FormattedMessage key="v" id="hub.why.visible" />);
  }
  return (
    <span className="flex items-start gap-2">
      {f.on ? (
        <CircleCheck className="mt-0.5 size-4 shrink-0 text-success" aria-hidden="true" />
      ) : (
        <CircleSlash className="mt-0.5 size-4 shrink-0 text-muted-foreground" aria-hidden="true" />
      )}
      <span className="grid gap-0.5">
        <span className={cn(!f.on && 'text-muted-foreground')}>
          <FormattedMessage id={`hub.why.${f.why}`} />
        </span>
        {detail.map((d, i) => (
          <span key={i} className="text-xs text-muted-foreground">
            {d}
          </span>
        ))}
      </span>
    </span>
  );
}

const statusTone: Record<StaffHubFamily['grants'][number]['status'], PillTone> = {
  pending: 'wait',
  active: 'ok',
  grace: 'warn',
  on_hold: 'warn',
  expired: 'muted',
  revoked: 'muted',
  refunded: 'muted',
};

type Grant = StaffHubFamily['grants'][number];

/**
 * Old promo grants and hand-written beta grants can be revoked here; paid grants follow the
 * store, campaign rows end with the campaign, and "Bật toàn bộ Premium" has its own switch.
 */
export function grantRevocable(g: Grant): boolean {
  return (
    !g.fromCampaign &&
    g.id !== FULL_PREMIUM_GRANT_ID &&
    (g.source === 'promo' || g.source === 'beta') &&
    /^(promo|beta)_[A-Za-z0-9_-]{1,80}$/.test(g.id) &&
    g.status !== 'revoked'
  );
}

function GrantsTable({
  family,
  canRevoke,
  onChanged,
}: {
  family: StaffHubFamily;
  canRevoke: boolean;
  onChanged: () => void;
}) {
  const intl = useIntl();
  const api = useApi();
  const [revoking, setRevoking] = useState<Grant | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  if (family.grants.length === 0) {
    return (
      <p className="text-sm text-muted-foreground">
        <FormattedMessage id="premium.grants.none" />
      </p>
    );
  }
  const range = (g: Grant) =>
    g.validUntil
      ? intl.formatMessage(
          { id: 'premium.range' },
          { from: lastDay(intl, g.validFrom), to: lastDay(intl, g.validUntil) },
        )
      : intl.formatMessage({ id: 'hub.family.noEnd' }, { from: lastDay(intl, g.validFrom) });
  return (
    <>
      <TableScroll min={680}>
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
                <FormattedMessage id="premium.col.validity" />
              </th>
              <th>
                <FormattedMessage id="premium.col.provider" />
              </th>
              {canRevoke && (
                <th>
                  <span className="sr-only">
                    <FormattedMessage id="premium.col.actions" />
                  </span>
                </th>
              )}
            </tr>
          </thead>
          <tbody>
            {family.grants.map((g) => (
              <tr key={g.id}>
                <td>
                  <span className="flex flex-wrap items-center gap-1.5 font-medium">
                    {g.id === FULL_PREMIUM_GRANT_ID ? (
                      <FormattedMessage id="hub.full.title" />
                    ) : (
                      <FormattedMessage id={`premium.source.${g.source}`} />
                    )}
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
                <td className="nowrap tabular-nums">{range(g)}</td>
                <td>
                  {g.provider ? <FormattedMessage id={`premium.provider.${g.provider}`} /> : '—'}
                </td>
                {canRevoke && (
                  <td className="cell-actions">
                    {grantRevocable(g) && (
                      <Button kind="ghost" onClick={() => setRevoking(g)}>
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
      {revoking && (
        <ConfirmModal
          title={<FormattedMessage id="premium.revokeTitle" values={{ code: family.code }} />}
          confirm={<FormattedMessage id="premium.revoke" />}
          danger
          busy={busy}
          error={error}
          onCancel={() => setRevoking(null)}
          onConfirm={() => {
            setBusy(true);
            setError(null);
            api
              .call('staffRevokeGrant', { code: family.code, grantId: revoking.id })
              .then(() => {
                setRevoking(null);
                onChanged();
              })
              .catch((e: unknown) => setError(asApiError(e)))
              .finally(() => setBusy(false));
          }}
        >
          <FormattedMessage id="premium.revokeEffect" />
        </ConfirmModal>
      )}
    </>
  );
}

/** Quota windows and store records: its own call, opened on demand. */
function QuotaLoader({ code, now }: { code: string; now: Date }) {
  const [load, reload] = useLoad<StaffFamilyQuota>('staffFamilyQuota', { code }, `quota-${code}`);
  return (
    <Loaded load={load} reload={reload}>
      {(data) => <FamilyQuotaView data={data} now={now} />}
    </Loaded>
  );
}
