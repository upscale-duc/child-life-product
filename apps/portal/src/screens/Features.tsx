import { flagKeys, staffCan, type Flag, type FlagKey } from '@child-life/contracts';
import { useState } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { Badge } from '@/components/ui/badge';
import { Checkbox } from '@/components/ui/checkbox';
import { Input } from '@/components/ui/input';
import { Switch } from '@/components/ui/switch';
import { ToggleGroup, ToggleGroupItem } from '@/components/ui/toggle-group';
import { ApiError, useApi, useLoad, type AiStats, type FamilyList, type FlagsView } from '../api';
import { useStaff } from '../context';
import { pct, shortDate } from '../format';
import { messages } from '../messages';
import {
  Button,
  Loaded,
  LockNote,
  Modal,
  Page,
  Panel,
  Pill,
  ReasonField,
  errorMessageId,
  reasonOk,
  TableScroll,
} from '../ui';

/** A10 Tính năng & phát hành: switches never change who can see what (R-189). */
export function FeaturesScreen() {
  const [load, reload] = useLoad<FlagsView>('staffFlags', {}, 'flags');
  const [ai] = useLoad<AiStats>('staffAi', {}, 'ai');
  return (
    <Page
      title={<FormattedMessage id="features.title" />}
      subtitle={<FormattedMessage id="features.sub" />}
    >
      <Loaded load={load} reload={reload}>
        {(data) => (
          <FeaturesView data={data} ai={ai.status === 'ok' ? ai.data : null} onChanged={reload} />
        )}
      </Loaded>
    </Page>
  );
}

/** The rollout ladder (A10): internal → 10 → 25 → 50 → 100 %. */
export const ladder = [10, 25, 50, 100] as const;

export function nextStep(flag: Flag): (typeof ladder)[number] | null {
  if (!flag.enabled || flag.scope === 'internal') return 10;
  if (flag.scope === 'all') return null;
  return ladder.find((p) => p > flag.percent) ?? null;
}

type Change = { key: FlagKey; next: Flag; kind: 'off' | 'on' | 'step' | 'scope' };

export function FeaturesView({
  data,
  ai,
  onChanged,
}: {
  data: FlagsView;
  ai: AiStats | null;
  onChanged: () => void;
}) {
  const intl = useIntl();
  const staff = useStaff();
  const canToggle = staffCan(staff.levels, 'flags.toggle');
  const canRollout = staffCan(staff.levels, 'flags.rollout');
  const [change, setChange] = useState<Change | null>(null);
  const aiFlag = data.flags.ai_story_drafts;
  const step = nextStep(aiFlag);
  const budgetUsed =
    ai && ai.budget.monthlyBudgetVnd ? ai.budget.spentVnd / ai.budget.monthlyBudgetVnd : null;
  return (
    <div className="cols cols--2-1">
      <Panel title={<FormattedMessage id="features.switches" />} className="panel--flush">
        <div className="panel__pad">
          <LockNote>
            <FormattedMessage id="features.lock" />
          </LockNote>
        </div>
        <TableScroll min={640}>
          <table className="table">
            <thead>
              <tr>
                <th>
                  <FormattedMessage id="col.feature" />
                </th>
                <th>
                  <FormattedMessage id="col.scope" />
                </th>
                <th>
                  <FormattedMessage id="col.lastEdit" />
                </th>
                <th>
                  <FormattedMessage id="col.on" />
                </th>
              </tr>
            </thead>
            <tbody>
              {flagKeys.map((key) => {
                const f = data.flags[key];
                const last = data.lastEdit[key];
                return (
                  <tr key={key}>
                    <td>
                      <strong>
                        <FormattedMessage id={`flag.${key}`} />
                      </strong>
                      <br />
                      <span className="muted">
                        <FormattedMessage id={`flag.${key}.desc`} />
                      </span>
                    </td>
                    <td>
                      {canRollout && f.scope !== 'percent' ? (
                        // "Ai được dùng": a few families, or every family.
                        <button
                          type="button"
                          className="link-button"
                          onClick={() => setChange({ key, kind: 'scope', next: { ...f } })}
                          aria-label={intl.formatMessage(
                            { id: 'features.scopeTitle' },
                            { flag: intl.formatMessage({ id: `flag.${key}` }) },
                          )}
                        >
                          <ScopePill flag={f} />
                        </button>
                      ) : (
                        <ScopePill flag={f} />
                      )}
                    </td>
                    <td className="muted">
                      {last ? `${last.by.split(' ')[0]} · ${shortDate(intl, last.at)}` : '—'}
                    </td>
                    <td>
                      <Switch
                        checked={f.enabled}
                        aria-label={intl.formatMessage({ id: `flag.${key}` })}
                        disabled={!canToggle}
                        title={
                          canToggle ? undefined : intl.formatMessage({ id: 'features.toggleRole' })
                        }
                        // The change is confirmed in a dialog first (A11), so the switch only asks.
                        onCheckedChange={() =>
                          setChange({
                            key,
                            kind: f.enabled ? 'off' : 'on',
                            next: { ...f, enabled: !f.enabled, notice: null },
                          })
                        }
                      />
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </TableScroll>
      </Panel>
      <div className="stack">
        <Panel title={<FormattedMessage id="features.rollout" />}>
          <ol className="ladder">
            {ladder.map((p) => {
              const current =
                aiFlag.enabled &&
                ((aiFlag.scope === 'percent' && aiFlag.percent === p) ||
                  (aiFlag.scope === 'all' && p === 100));
              const passed =
                aiFlag.enabled &&
                (aiFlag.scope === 'all' || (aiFlag.scope === 'percent' && aiFlag.percent > p));
              return (
                <li
                  key={p}
                  className={`ladder__step ${current ? 'ladder__step--on' : passed ? 'ladder__step--done' : ''}`}
                >
                  {p}%
                </li>
              );
            })}
          </ol>
          <dl className="kv kv--checks">
            <dt>
              <FormattedMessage id="features.guardReports" />
            </dt>
            <dd>
              {ai ? (
                <FormattedMessage id="features.guardReportsValue" values={{ n: ai.kpis.reports }} />
              ) : (
                '—'
              )}
            </dd>
            <dt>
              <FormattedMessage id="features.guardCost" />
            </dt>
            <dd>
              {budgetUsed === null ? (
                '—'
              ) : (
                <FormattedMessage
                  id="features.guardCostValue"
                  values={{ p: pct(intl, budgetUsed) }}
                />
              )}
            </dd>
            <dt>
              <FormattedMessage id="features.guardErrors" />
            </dt>
            <dd>
              <FormattedMessage id="features.guardErrorsValue" />
            </dd>
          </dl>
          {step !== null && (
            <Button
              kind="primary"
              disabled={!canRollout || (!aiFlag.enabled && !canToggle)}
              title={canRollout ? undefined : intl.formatMessage({ id: 'error.role' })}
              onClick={() =>
                setChange({
                  key: 'ai_story_drafts',
                  kind: aiFlag.enabled ? 'step' : 'on',
                  next: {
                    enabled: true,
                    scope: step === 100 ? 'all' : 'percent',
                    percent: step,
                    notice: null,
                  },
                })
              }
            >
              <FormattedMessage id="features.openTo" values={{ p: step }} />
            </Button>
          )}
        </Panel>
        <Panel title={<FormattedMessage id="features.limits" />}>
          <dl className="kv">
            <dt>
              <FormattedMessage id="limits.quota" />
            </dt>
            <dd>
              <FormattedMessage
                id="limits.quotaValue"
                values={{ n: Math.round(data.limits.familyQuotaBytes / 1024 ** 3) }}
              />
            </dd>
            <dt>
              <FormattedMessage id="limits.video" />
            </dt>
            <dd>
              {data.limits.videoMaxDurationSec === null ? (
                <FormattedMessage id="limits.unlimited" />
              ) : (
                <FormattedMessage
                  id="limits.minutes"
                  values={{ n: Math.round(data.limits.videoMaxDurationSec / 60) }}
                />
              )}
            </dd>
            <dt>
              <FormattedMessage id="limits.export" />
            </dt>
            <dd>
              <FormattedMessage
                id="limits.exportValue"
                values={{ n: data.limits.exportLinkTtlHours }}
              />
            </dd>
            <dt>
              <FormattedMessage id="limits.autoSave" />
            </dt>
            <dd>
              <FormattedMessage
                id="limits.autoSaveValue"
                values={{ n: data.limits.autoSaveItemsPerApprove }}
              />
            </dd>
          </dl>
        </Panel>
        <Panel title={<FormattedMessage id="features.recent" />}>
          {data.recent.length === 0 ? (
            <p className="muted">
              <FormattedMessage id="features.noRecent" />
            </p>
          ) : (
            <ul className="recent">
              {data.recent.map((r, i) => (
                <li key={i}>
                  <p>
                    <AuditActionText action={r.action} target={r.target} detail={r.detail} />
                  </p>
                  <p className="muted">
                    {r.by.split(' ')[0]} · {shortDate(intl, r.at)} · {r.reason}
                  </p>
                </li>
              ))}
            </ul>
          )}
        </Panel>
      </div>
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
    </div>
  );
}

export function ScopePill({ flag }: { flag: Flag }) {
  if (flag.scope === 'internal') {
    const n = flag.families?.length ?? 0;
    return (
      <Pill tone="purple">
        {n ? (
          <FormattedMessage id="scope.chosen" values={{ n }} />
        ) : (
          <FormattedMessage id="scope.internal" />
        )}
      </Pill>
    );
  }
  if (flag.scope === 'percent') {
    return (
      <Pill tone="wait">
        <FormattedMessage id="scope.percent" values={{ p: flag.percent }} />
      </Pill>
    );
  }
  return (
    <span className="muted">
      <FormattedMessage id="scope.all" />
    </span>
  );
}

/** "Tắt “Tải video”", "Mở “AI gợi ý câu chuyện” lên 50%" (A10 recent, A12). */
export function AuditActionText({
  action,
  target,
  detail,
}: {
  action: string;
  target: string;
  detail: Record<string, unknown> | null;
}) {
  const intl = useIntl();
  const flagName = (flagKeys as readonly string[]).includes(target)
    ? intl.formatMessage({ id: `flag.${target}` })
    : target;
  const after = (detail?.after ?? null) as Flag | null;
  const values = {
    flag: flagName,
    p: after?.scope === 'all' ? 100 : (after?.percent ?? 0),
    n: (detail?.grantGb ?? detail?.requestedGb ?? '') as number | string,
  };
  const known = [
    'support.claim',
    'support.reply',
    'support.macro.wifiGuide',
    'support.close',
    'support.screenshot',
    'storage.grant',
    'storage.decline',
    'jobs.rerun',
    'flags.on',
    'flags.off',
    'flags.rollout',
    'flags.families',
    'audit.export',
    'jobs.rerunRequest',
    'staff.invite',
    'staff.join',
    'staff.revokeInvite',
    'staff.roles',
    'staff.access',
    'staff.pause',
    'staff.resume',
    'staff.remove',
    'staff.saveRole',
    'staff.createRole',
    'family.view',
    'family.transferOpen',
    'family.transferCancel',
    'analytics.export',
    'reference.draft',
    'reference.submit',
    'reference.publish',
    'reference.reject',
    'reference.discard',
    'reference.rollback',
    'content.firstAid.draft',
    'content.firstAid.submit',
    'content.firstAid.approve',
    'content.firstAid.reject',
    'content.firstAid.discard',
    'content.firstAid.rollback',
    'content.firstAid.image',
    'content.keepsakes.draft',
    'content.keepsakes.submit',
    'content.keepsakes.approve',
    'content.keepsakes.reject',
    'content.keepsakes.discard',
    'content.keepsakes.rollback',
    'content.keepsakes.asset',
    'release.publish',
    'release.image',
  ];
  return (
    <FormattedMessage
      id={known.includes(action) ? `audit.${action}` : 'audit.other'}
      values={{ ...values, action }}
    />
  );
}

function FlagDialog({
  change,
  onClose,
  onDone,
}: {
  change: Change;
  onClose: () => void;
  onDone: () => void;
}) {
  const intl = useIntl();
  const api = useApi();
  const [reason, setReason] = useState('');
  const [notify, setNotify] = useState(true);
  // Families see this text as typed; the default is the Vietnamese source copy (D-012).
  const [notice, setNotice] = useState(() => defaultNotice(change.key));
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const off = change.kind === 'off';
  // "Ai được dùng" (on, or the scope cell): a few families, or every family. Percent steps stay
  // on the rollout ladder.
  const choosing =
    (change.kind === 'on' || change.kind === 'scope') && change.next.scope !== 'percent';
  const [who, setWho] = useState<'some' | 'all'>(change.next.scope === 'all' ? 'all' : 'some');
  const [families, setFamilies] = useState<string[]>(change.next.families ?? []);
  const scope = choosing ? (who === 'all' ? 'all' : 'internal') : change.next.scope;
  const next: Flag = {
    ...change.next,
    scope,
    families: scope === 'internal' ? (choosing ? families : change.next.families) : undefined,
  };
  const submit = async () => {
    setBusy(true);
    setError(null);
    try {
      const percent = next.scope === 'all' ? 100 : next.percent;
      await api.call('staffSetFlag', {
        key: change.key,
        enabled: next.enabled,
        scope: next.scope,
        percent: [0, 10, 25, 50, 100].includes(percent) ? percent : 0,
        notice: off && notify && notice.trim() ? notice.trim() : null,
        // Only a choice made here is sent; a plain on / off keeps the families picked before.
        ...(choosing && next.scope === 'internal' ? { families } : {}),
        reason: reason.trim(),
      });
      onDone();
    } catch (e) {
      setError(e instanceof ApiError ? e : new ApiError('unknown', null));
    } finally {
      setBusy(false);
    }
  };
  const flag = intl.formatMessage({ id: `flag.${change.key}` });
  return (
    <Modal
      title={
        <FormattedMessage
          id={
            off
              ? 'features.offTitle'
              : change.kind === 'on'
                ? 'features.onTitle'
                : change.kind === 'scope'
                  ? 'features.scopeTitle'
                  : 'features.stepTitle'
          }
          values={{ flag, p: next.scope === 'all' ? 100 : next.percent }}
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
      <p className="modal__sub">
        <FormattedMessage id={off ? `flag.${change.key}.offEffect` : 'features.onEffect'} />
      </p>
      {choosing && (
        <div className="field">
          <span className="field__label">
            <FormattedMessage id="features.who" />
          </span>
          <ToggleGroup
            type="single"
            variant="outline"
            value={who}
            onValueChange={(v) => v && setWho(v as 'some' | 'all')}
          >
            <ToggleGroupItem value="some">
              <FormattedMessage id="features.whoSome" />
            </ToggleGroupItem>
            <ToggleGroupItem value="all">
              <FormattedMessage id="features.whoAll" />
            </ToggleGroupItem>
          </ToggleGroup>
          {who === 'some' && <FamilyPicker value={families} onChange={setFamilies} />}
        </div>
      )}
      <dl className="kv">
        <dt>
          <FormattedMessage id="features.impact" />
        </dt>
        <dd>
          <ScopeText flag={next} />
        </dd>
      </dl>
      <ReasonField value={reason} onChange={setReason} required />
      {off && (
        <div className="field">
          <label className="check-row">
            <Checkbox checked={notify} onCheckedChange={(v) => setNotify(v === true)} />
            <FormattedMessage id="features.notify" />
          </label>
          {notify && (
            <textarea
              className="field__input"
              rows={2}
              maxLength={280}
              value={notice}
              onChange={(e) => setNotice(e.target.value)}
              aria-label={intl.formatMessage({ id: 'features.notify' })}
            />
          )}
          {notify && (
            <p className="field__help">
              <FormattedMessage id="features.noticeHelp" />
            </p>
          )}
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
          kind={off ? 'danger' : 'primary'}
          disabled={busy || !reasonOk(reason)}
          onClick={() => void submit()}
        >
          <FormattedMessage id={off ? 'features.turnOff' : 'features.confirm'} />
        </Button>
      </div>
    </Modal>
  );
}

export function defaultNotice(key: FlagKey): string {
  return messages.vi['features.noticeDefault']!.replace('{flag}', messages.vi[`flag.${key}`]!);
}

/**
 * "Một vài gia đình": by family code (F-XXXX, as Gia đình shows it) or a parent's exact email,
 * matched on the server and never shown back.
 */
function FamilyPicker({ value, onChange }: { value: string[]; onChange: (v: string[]) => void }) {
  const intl = useIntl();
  const api = useApi();
  const [q, setQ] = useState('');
  const [busy, setBusy] = useState(false);
  const [problem, setProblem] = useState<string | null>(null);
  const add = async () => {
    const text = q.trim();
    if (!text) return;
    setProblem(null);
    if (/^F-[A-Z2-9]{4}$/i.test(text)) {
      onChange([...new Set([...value, text.toUpperCase()])]);
      setQ('');
      return;
    }
    if (!text.includes('@')) {
      setProblem('features.familyHint');
      return;
    }
    setBusy(true);
    try {
      const found = await api.call<FamilyList>('staffFamilies', {
        activity: 'all',
        platform: 'all',
        storage: 'all',
        q: text,
      });
      if (found.rows.length === 0) {
        setProblem('features.familyNotFound');
      } else {
        onChange([...new Set([...value, ...found.rows.map((r) => r.code)])]);
        setQ('');
      }
    } catch (e) {
      setProblem(e instanceof ApiError ? errorMessageId(e) : 'features.familyNotFound');
    } finally {
      setBusy(false);
    }
  };
  return (
    <div className="family-picker">
      <div className="family-picker__row">
        <Input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === 'Enter') {
              e.preventDefault();
              void add();
            }
          }}
          placeholder={intl.formatMessage({ id: 'features.familyFind' })}
          aria-label={intl.formatMessage({ id: 'features.familyFind' })}
        />
        <Button disabled={busy || !q.trim()} onClick={() => void add()}>
          <FormattedMessage id="features.familyAdd" />
        </Button>
      </div>
      {problem && (
        <p className="error" role="alert">
          <FormattedMessage id={problem} />
        </p>
      )}
      {value.length === 0 ? (
        <p className="field__help">
          <FormattedMessage id="features.familyNone" />
        </p>
      ) : (
        <ul className="family-picker__list">
          {value.map((code) => (
            <li key={code}>
              <Badge variant="secondary">
                {code}
                <button
                  type="button"
                  className="family-picker__remove"
                  aria-label={intl.formatMessage({ id: 'features.familyRemove' }, { code })}
                  onClick={() => onChange(value.filter((c) => c !== code))}
                >
                  ×
                </button>
              </Badge>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

function ScopeText({ flag }: { flag: Flag }) {
  if (flag.scope === 'internal' && flag.families?.length)
    return <FormattedMessage id="impact.chosen" values={{ n: flag.families.length }} />;
  if (flag.scope === 'internal') return <FormattedMessage id="impact.internal" />;
  if (flag.scope === 'percent')
    return <FormattedMessage id="impact.percent" values={{ p: flag.percent }} />;
  return <FormattedMessage id="impact.all" />;
}
