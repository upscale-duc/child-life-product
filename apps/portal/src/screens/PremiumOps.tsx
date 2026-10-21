import type {
  KeepsakeJobErrorCode,
  ReservationState,
  StaffAiPolicy,
  StaffFamilyQuota,
  StaffRenderJob,
  StaffRenderOps,
} from '@child-life/contracts';
import { Fragment, type ReactNode } from 'react';
import { FormattedMessage, useIntl, type IntlShape } from 'react-intl';
import { useLoad } from '../api';
import { Notice, StatTiles } from '../content-kit';
import { useNavigate } from '../context';
import { ZONE, num, pct, shortDate, vnd, when } from '../format';
import {
  Button,
  Empty,
  HBars,
  Kpi,
  Loaded,
  LockNote,
  Panel,
  Pill,
  StackedBars,
  TableScroll,
  type PillTone,
} from '../ui';

/**
 * Premium operations (plan §5.6, brief "Portal cần thêm"), read-only: the AI policy in force
 * (Tính năng & Premium › Gói Premium › Chính sách AI), one family's quota windows and store
 * records (Tính năng & Premium › Gia đình › Lượt dùng & thanh toán) and keepsake video render jobs with their quota reservations (Yêu cầu dữ liệu › Video kỷ niệm).
 * Nothing here retries a job, takes or gives back a unit, or changes a grant: a retry is the
 * family's own "Thử lại" and takes a new reservation (brief "không cho retry tạo charge/job mới").
 * Answers carry family codes and short hashes only.
 */

const fullDay = (intl: IntlShape, iso: string) =>
  intl.formatDate(iso, { day: 'numeric', month: 'numeric', year: 'numeric', timeZone: ZONE });

// ---------- Gói Premium › Chính sách AI ----------

export function AiPolicyLoader({ onOpenLimits }: { onOpenLimits: () => void }) {
  const [load, reload] = useLoad<StaffAiPolicy>('staffAiPolicy', {}, 'aiPolicy');
  return (
    <Loaded load={load} reload={reload}>
      {(data) => <AiPolicyView data={data} onOpenLimits={onOpenLimits} />}
    </Loaded>
  );
}

/** The `ai_assist` switch as one sentence. */
export function aiSwitchNote(flag: StaffAiPolicy['flag']): { id: string; tone: PillTone } {
  if (!flag.enabled) return { id: 'premium.ai.switchOff', tone: 'muted' };
  switch (flag.scope) {
    case 'internal':
      return { id: 'premium.ai.switchInternal', tone: 'wait' };
    case 'percent':
      return { id: 'premium.ai.switchPercent', tone: 'wait' };
    default:
      return { id: 'premium.ai.switchAll', tone: 'ok' };
  }
}

export function AiPolicyView({
  data,
  onOpenLimits,
}: {
  data: StaffAiPolicy;
  onOpenLimits: () => void;
}) {
  const intl = useIntl();
  const navigate = useNavigate();
  const t = data.totals;
  const b = data.budget;
  const used = b.monthlyBudgetVnd ? b.spentVnd / b.monthlyBudgetVnd : 0;
  const sw = aiSwitchNote(data.flag);
  const reasonTotal = Math.max(
    1,
    data.fallbackReasons.reduce((n, r) => n + r.count, 0),
  );
  const problems = Object.entries(data.reports.byProblem) as Array<[string, number]>;
  return (
    <div className="grid">
      <Notice tone="info">
        <FormattedMessage id="premium.ai.audit" />
      </Notice>
      <StatTiles
        items={[
          {
            key: 'generated',
            label: <FormattedMessage id="premium.ai.generated" />,
            value: num(intl, t.generated),
            foot: (
              <FormattedMessage
                id="premium.ai.generatedFoot"
                values={{ ai: t.ai, cache: t.cache }}
              />
            ),
          },
          {
            key: 'fallback',
            label: <FormattedMessage id="premium.ai.fallbackRate" />,
            value: pct(intl, t.fallbackRate),
            foot: <FormattedMessage id="premium.ai.fallbackFoot" values={{ n: t.fallback }} />,
          },
          {
            key: 'technical',
            label: <FormattedMessage id="premium.ai.technicalRate" />,
            value: pct(intl, t.technicalRate),
            foot: <FormattedMessage id="premium.ai.technicalFoot" />,
            tone: t.technicalRate !== null && t.technicalRate >= 0.1 ? 'warn' : 'default',
          },
          {
            key: 'reports',
            label: <FormattedMessage id="premium.ai.reportsOpen" />,
            value: num(intl, data.reports.open),
            foot: <FormattedMessage id="premium.ai.reportsFoot" />,
            tone: data.reports.byProblem.unsafe_advice ? 'error' : 'default',
          },
        ]}
      />
      <div className="cols cols--2-1">
        <Panel
          title={<FormattedMessage id="premium.ai.daily" />}
          note={<FormattedMessage id="premium.ai.dailyNote" />}
        >
          <StackedBars
            title={intl.formatMessage({ id: 'premium.ai.daily' })}
            series={data.days}
            labels={data.days.map((d) => shortDate(intl, `${d.day}T12:00:00+07:00`))}
            keys={(['ai', 'cache', 'fallback'] as const).map((key) => ({
              key,
              label: intl.formatMessage({ id: `premium.ai.method.${key}` }),
              className: `ai-${key}`,
            }))}
          />
        </Panel>
        <Panel title={<FormattedMessage id="premium.ai.reasons" />}>
          {data.fallbackReasons.length === 0 ? (
            <p className="muted">
              <FormattedMessage id="premium.ai.noFallback" />
            </p>
          ) : (
            <HBars
              rows={data.fallbackReasons.map((r) => ({
                label: <FormattedMessage id={`premium.ai.reason.${r.reason}`} />,
                value: num(intl, r.count),
                ratio: r.count / reasonTotal,
              }))}
            />
          )}
        </Panel>
      </div>
      <div className="cols cols--1-1">
        <Panel
          title={<FormattedMessage id="premium.ai.provider" />}
          note={<FormattedMessage id="premium.ai.noSecrets" />}
        >
          <dl className="kv">
            <dt>
              <FormattedMessage id="premium.ai.providerName" />
            </dt>
            <dd>
              <FormattedMessage id={`premium.ai.provider.${data.provider.name}`} />
            </dd>
            <dt>
              <FormattedMessage id="premium.ai.model" />
            </dt>
            <dd className="mono">{data.provider.model ?? '—'}</dd>
            <dt>
              <FormattedMessage id="premium.ai.consent" />
            </dt>
            <dd className="mono">{data.consentVersion}</dd>
            <dt>
              <FormattedMessage id="premium.ai.prompt" />
            </dt>
            <dd className="mono">{data.promptVersion}</dd>
            <dt>
              <FormattedMessage id="premium.ai.range" />
            </dt>
            <dd>
              <FormattedMessage
                id="premium.ai.rangeValue"
                values={{
                  days: data.limits.rangeDays,
                  facts: data.limits.maxFacts,
                  candidates: data.limits.maxCandidates,
                }}
              />
            </dd>
            <dt>
              <FormattedMessage id="premium.ai.timeout" />
            </dt>
            <dd>
              <FormattedMessage
                id="premium.ai.timeoutValue"
                values={{ s: Math.round(data.limits.timeoutMs / 1000) }}
              />
            </dd>
            <dt>
              <FormattedMessage id="premium.ai.cost" />
            </dt>
            <dd>{vnd(intl, data.limits.costVnd)}</dd>
          </dl>
        </Panel>
        <div className="stack">
          <Panel
            title={<FormattedMessage id="premium.ai.switch" />}
            aside={
              <Button kind="ghost" onClick={() => navigate('features')}>
                <FormattedMessage id="premium.ai.openFeatures" />
              </Button>
            }
          >
            <p>
              <Pill tone={sw.tone}>
                <FormattedMessage
                  id={sw.id}
                  values={{ n: data.flag.families, p: data.flag.percent }}
                />
              </Pill>
            </p>
            <p className="muted">
              <FormattedMessage id="premium.ai.switchNote" />
            </p>
          </Panel>
          <Panel
            title={<FormattedMessage id="premium.ai.quotas" />}
            aside={
              <Button kind="ghost" onClick={onOpenLimits}>
                <FormattedMessage id="premium.ai.openLimits" />
              </Button>
            }
          >
            {data.quotas.assistant ? (
              // D-075 #1: summaries charge the household assistant credit pool.
              <>
                <dl className="kv">
                  <dt>
                    <FormattedMessage id="premium.credits.free" />
                  </dt>
                  <dd>
                    <FormattedMessage
                      id="premium.credits.value"
                      values={{ n: data.quotas.assistant.free }}
                    />
                  </dd>
                  <dt>
                    <FormattedMessage id="premium.credits.premium" />
                  </dt>
                  <dd>
                    <FormattedMessage
                      id="premium.credits.value"
                      values={{ n: data.quotas.assistant.premium }}
                    />
                  </dd>
                </dl>
                <p className="muted">
                  <FormattedMessage id="premium.ai.creditsNote" />
                </p>
              </>
            ) : (
              <dl className="kv">
                <dt>
                  <FormattedMessage id="premium.quota.aiBaby" />
                </dt>
                <dd>
                  <FormattedMessage
                    id="premium.quota.uses"
                    values={{ n: data.quotas.perBabyPerDay }}
                  />
                </dd>
                <dt>
                  <FormattedMessage id="premium.quota.aiFamily" />
                </dt>
                <dd>
                  <FormattedMessage
                    id="premium.quota.uses"
                    values={{ n: data.quotas.perFamilyPerMonth }}
                  />
                </dd>
              </dl>
            )}
            {!data.quotas.stored && (
              <p className="muted">
                <FormattedMessage id="premium.ai.quotasDefault" />
              </p>
            )}
            <p className="muted">
              <FormattedMessage id="premium.ai.quotaNote" />
            </p>
          </Panel>
          <Panel
            title={
              <FormattedMessage
                id="ai.budget"
                values={{
                  month: intl.formatDate(`${b.month}-15`, { month: 'long', timeZone: ZONE }),
                }}
              />
            }
          >
            <p className="budget">
              <strong>{vnd(intl, b.spentVnd)}</strong> / {vnd(intl, b.monthlyBudgetVnd)} ·{' '}
              {pct(intl, used)}
            </p>
            <p className="muted">
              <FormattedMessage id="premium.ai.budgetNote" />
            </p>
          </Panel>
        </div>
      </div>
      <Panel
        title={<FormattedMessage id="premium.ai.reports" />}
        note={<FormattedMessage id="premium.ai.reportsNote" />}
      >
        <dl className="kv">
          {problems.map(([p, n]) => (
            <Fragment key={p}>
              <dt>
                <FormattedMessage id={`premium.ai.problem.${p}`} />
              </dt>
              <dd>
                {p === 'unsafe_advice' && n > 0 ? <Pill tone="error">{num(intl, n)}</Pill> : n}
              </dd>
            </Fragment>
          ))}
        </dl>
      </Panel>
    </div>
  );
}

// ---------- Gia đình › Lượt dùng & thanh toán ----------

const accountTone: Record<string, PillTone> = {
  pending: 'wait',
  active: 'ok',
  grace: 'warn',
  on_hold: 'warn',
  expired: 'muted',
  revoked: 'muted',
  refunded: 'muted',
};

function Th({ id }: { id: string }) {
  return (
    <th>
      <FormattedMessage id={id} />
    </th>
  );
}

/** One family's quota windows, held units, store accounts and store events (read-only). */
export function FamilyQuotaView({ data, now }: { data: StaffFamilyQuota; now: Date }) {
  const intl = useIntl();
  return (
    <section className="stack mt-4" aria-label={intl.formatMessage({ id: 'premium.fq.title' })}>
      <h3 className="panel__title">
        <FormattedMessage id="premium.fq.title" />
      </h3>
      <LockNote>
        <FormattedMessage id="premium.fq.noStore" />
      </LockNote>
      <div>
        <strong>
          <FormattedMessage id="premium.fq.windows" />
        </strong>
        <p className="muted">
          <FormattedMessage id="premium.fq.windowsNote" />
        </p>
      </div>
      {data.windows.length === 0 ? (
        <p className="muted">
          <FormattedMessage id="premium.fq.noWindows" />
        </p>
      ) : (
        <TableScroll min={720}>
          <table className="table">
            <thead>
              <tr>
                <Th id="premium.fq.col.window" />
                <Th id="premium.fq.col.feature" />
                <Th id="premium.fq.col.usage" />
                <Th id="premium.fq.col.resets" />
              </tr>
            </thead>
            <tbody>
              {data.windows.map((w) => (
                <tr key={w.window}>
                  <td className="mono">{w.window}</td>
                  <td>
                    <FormattedMessage id={`premium.fq.feature.${w.feature}`} />
                    <br />
                    <span className="muted">
                      <FormattedMessage id={`premium.fq.scope.${w.scope}`} />
                    </span>
                  </td>
                  <td>
                    <FormattedMessage
                      id="premium.fq.usage"
                      values={{ used: w.used, reserved: w.reserved, limit: w.limit }}
                    />
                  </td>
                  <td className="nowrap">
                    <Pill tone={w.open ? 'ok' : 'muted'}>
                      <FormattedMessage id={w.open ? 'premium.fq.open' : 'premium.fq.ended'} />
                    </Pill>{' '}
                    {w.resetsAt ? when(intl, w.resetsAt, now) : '—'}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </TableScroll>
      )}
      <p className={data.held ? '' : 'muted'}>
        <FormattedMessage id="premium.fq.held" values={{ n: data.held }} />
      </p>
      <strong>
        <FormattedMessage id="premium.fq.accounts" />
      </strong>
      {data.accounts.length === 0 ? (
        <p className="muted">
          <FormattedMessage id="premium.fq.noAccounts" />
        </p>
      ) : (
        <TableScroll min={760}>
          <table className="table">
            <thead>
              <tr>
                <Th id="premium.fq.col.account" />
                <Th id="premium.fq.col.product" />
                <Th id="premium.col.status" />
                <Th id="premium.fq.col.until" />
                <Th id="premium.fq.col.env" />
                <Th id="premium.col.autoRenew" />
              </tr>
            </thead>
            <tbody>
              {data.accounts.map((a) => (
                <tr key={a.id}>
                  <td>
                    <span className="mono">{a.id}</span>
                    <br />
                    <span className="muted">
                      <FormattedMessage id={`premium.provider.${a.provider}`} />
                    </span>
                  </td>
                  <td className="mono">{a.productId ?? '—'}</td>
                  <td>
                    <Pill tone={accountTone[a.status] ?? 'muted'}>
                      <FormattedMessage id={`premium.status.${a.status}`} />
                    </Pill>
                  </td>
                  <td className="nowrap">{a.validUntil ? fullDay(intl, a.validUntil) : '—'}</td>
                  <td>
                    <FormattedMessage id={`premium.env.${a.environment}`} />
                  </td>
                  <td>
                    {a.autoRenew === null ? (
                      '—'
                    ) : (
                      <FormattedMessage id={a.autoRenew ? 'premium.yes' : 'premium.no'} />
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </TableScroll>
      )}
      <strong>
        <FormattedMessage id="premium.fq.events" />
      </strong>
      {data.events.length === 0 ? (
        <p className="muted">
          <FormattedMessage id="premium.fq.noEvents" />
        </p>
      ) : (
        <TableScroll min={640}>
          <table className="table">
            <thead>
              <tr>
                <Th id="premium.fq.col.event" />
                <Th id="premium.fq.col.outcome" />
                <Th id="premium.fq.col.at" />
              </tr>
            </thead>
            <tbody>
              {data.events.map((e, i) => (
                <tr key={i}>
                  <td>
                    <span className="mono">{e.type}</span>
                    <br />
                    <span className="muted">
                      <FormattedMessage id={`premium.provider.${e.provider}`} />
                    </span>
                  </td>
                  <td>
                    {e.processedAt ? (
                      <span className="mono">{e.outcome ?? '—'}</span>
                    ) : (
                      <Pill tone="wait">
                        <FormattedMessage id="premium.fq.pending" />
                      </Pill>
                    )}
                  </td>
                  <td className="nowrap">{when(intl, e.at, now)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </TableScroll>
      )}
      <p className="muted">
        <FormattedMessage id="premium.fq.masked" />
      </p>
    </section>
  );
}

// ---------- Yêu cầu dữ liệu › Video kỷ niệm ----------

export function RenderOpsLoader({ toolbar }: { toolbar: ReactNode }) {
  const [load, reload] = useLoad<StaffRenderOps>('staffRenderOps', {}, 'renderOps');
  return (
    <Loaded load={load} reload={reload}>
      {(data) => <RenderOpsView data={data} now={new Date()} toolbar={toolbar} />}
    </Loaded>
  );
}

export const renderStatusTone: Record<StaffRenderJob['status'], PillTone> = {
  queued: 'info',
  rendering: 'info',
  completed: 'ok',
  failed: 'error',
};

export const reservationTone: Record<ReservationState, PillTone> = {
  reserved: 'wait',
  committed: 'ok',
  released: 'muted',
};

/** Render jobs across families: status, why a job failed, and its quota reservation. */
export function RenderOpsView({
  data,
  now,
  toolbar,
}: {
  data: StaffRenderOps;
  now: Date;
  toolbar?: ReactNode;
}) {
  const intl = useIntl();
  const k = data.kpis;
  const failures = Object.entries(data.failures) as Array<[KeepsakeJobErrorCode, number]>;
  return (
    <div className="grid">
      <div className="kpis">
        <Kpi
          label={<FormattedMessage id="render.active" />}
          value={num(intl, k.active)}
          foot={<FormattedMessage id="render.activeFoot" />}
        />
        <Kpi
          label={<FormattedMessage id="render.failed" />}
          value={num(intl, k.failed24h)}
          tone={k.failed24h ? 'error' : 'muted'}
          foot={
            failures.length ? (
              failures.map(([code, n], i) => (
                <Fragment key={code}>
                  {i > 0 && ' · '}
                  <FormattedMessage id={`render.errorShort.${code}`} /> {n}
                </Fragment>
              ))
            ) : (
              <FormattedMessage id="render.noFailures" />
            )
          }
        />
        <Kpi label={<FormattedMessage id="render.completed" />} value={num(intl, k.completed24h)} />
        <Kpi
          label={<FormattedMessage id="render.ledger" />}
          value={num(intl, k.ledgerIssues)}
          tone={k.ledgerIssues ? 'warn' : 'muted'}
          foot={<FormattedMessage id={k.ledgerIssues ? 'render.ledgerFoot' : 'render.ledgerOk'} />}
        />
      </div>
      <Panel className="panel--flush">
        <div className="panel__pad toolbar">
          {toolbar}
          <span className="muted">
            <FormattedMessage id="render.note" />
          </span>
        </div>
        {data.jobs.length === 0 ? (
          <Empty>
            <FormattedMessage id="render.empty" />
          </Empty>
        ) : (
          <TableScroll min={1040}>
            <table className="table">
              <thead>
                <tr>
                  <Th id="render.col.job" />
                  <Th id="render.col.family" />
                  <Th id="render.col.template" />
                  <Th id="col.created" />
                  <Th id="col.status" />
                  <Th id="render.col.attempts" />
                  <Th id="render.col.reason" />
                  <Th id="render.col.reservation" />
                </tr>
              </thead>
              <tbody>
                {data.jobs.map((j) => (
                  <tr key={j.code}>
                    <td className="mono">{j.code}</td>
                    <td className="mono">{j.family}</td>
                    <td>
                      <span className="mono">{j.templateId}</span>
                      {j.templateVersion !== null && (
                        <span className="muted"> · v{j.templateVersion}</span>
                      )}
                    </td>
                    <td className="nowrap">{when(intl, j.createdAt, now)}</td>
                    <td>
                      <Pill tone={renderStatusTone[j.status] ?? 'muted'}>
                        <FormattedMessage id={`render.status.${j.status}`} />
                      </Pill>
                      {j.step && j.status === 'rendering' && (
                        <>
                          <br />
                          <span className="muted">
                            <FormattedMessage id={`render.step.${j.step}`} /> ·{' '}
                            {pct(intl, j.progress)}
                          </span>
                        </>
                      )}
                    </td>
                    <td>
                      <FormattedMessage
                        id="render.attempts"
                        values={{ attempts: j.attempts, lease: j.lease }}
                      />
                    </td>
                    <td>{j.error ? <FormattedMessage id={`render.error.${j.error}`} /> : '—'}</td>
                    <td>
                      {j.reservation ? (
                        <>
                          <Pill
                            tone={
                              j.reservation.state ? reservationTone[j.reservation.state] : 'muted'
                            }
                          >
                            <FormattedMessage
                              id={`render.state.${j.reservation.state ?? 'none'}`}
                            />
                          </Pill>
                          {j.reservation.issue && (
                            <>
                              {' '}
                              <Pill tone="warn">
                                <FormattedMessage id={`render.issue.${j.reservation.issue}`} />
                              </Pill>
                            </>
                          )}
                          <br />
                          <span className="muted mono">
                            {j.reservation.window} · {j.reservation.id}
                          </span>
                        </>
                      ) : (
                        <span className="muted">
                          <FormattedMessage id="render.state.none" />
                        </span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </TableScroll>
        )}
        <div className="panel__pad">
          <LockNote>
            <FormattedMessage id="render.lock1" />
          </LockNote>
          <LockNote>
            <FormattedMessage id="render.lock2" />
          </LockNote>
          <LockNote>
            <FormattedMessage id="render.lock3" />
          </LockNote>
        </div>
      </Panel>
    </div>
  );
}
