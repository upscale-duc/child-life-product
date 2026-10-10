import { auditCategories } from '@child-life/contracts';
import { useEffect, useState } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { ApiError, useApi, useLoad, type AuditRow } from '../api';
import { downloadCsv, toCsv, when } from '../format';
import {
  Button,
  Empty,
  Loaded,
  LockNote,
  Page,
  Panel,
  Pill,
  Segmented,
  errorMessageId,
  type PillTone,
} from '../ui';
import { AuditActionText } from './Features';

type Category = 'all' | (typeof auditCategories)[number];
type Days = 1 | 7 | 30 | 90;

const categoryTone: Record<AuditRow['category'], PillTone> = {
  support: 'info',
  storage: 'wait',
  data: 'purple',
  features: 'ok',
};

/** A12 Nhật ký thao tác: append-only; only codes, actions and reasons, never family content. */
export function AuditScreen() {
  const intl = useIntl();
  const api = useApi();
  const [category, setCategory] = useState<Category>('all');
  const [days, setDays] = useState<Days>(7);
  const [q, setQ] = useState('');
  const [query, setQuery] = useState('');
  const [exportError, setExportError] = useState<ApiError | null>(null);
  useEffect(() => {
    const t = setTimeout(() => setQuery(q.trim()), 300);
    return () => clearTimeout(t);
  }, [q]);
  const req = { category, days, ...(query ? { q: query } : {}) };
  const [load, reload] = useLoad<{ rows: AuditRow[] }>(
    'staffAudit',
    req,
    `${category}|${days}|${query}`,
  );
  const exportCsv = async () => {
    setExportError(null);
    try {
      // The export is itself logged (A12 "audit.export").
      const { rows } = await api.call<{ rows: AuditRow[] }>('staffExportAudit', req);
      downloadCsv(
        `child-life-audit-${category}-${days}d.csv`,
        toCsv(
          ['at', 'actor', 'role', 'action', 'category', 'target', 'reason'],
          rows.map((r) => [r.at, r.actor, r.role, r.action, r.category, r.target, r.reason ?? '']),
        ),
      );
      reload();
    } catch (e) {
      setExportError(e instanceof ApiError ? e : new ApiError('unknown', null));
    }
  };
  return (
    <Page
      title={<FormattedMessage id="audit.title" />}
      subtitle={<FormattedMessage id="audit.sub" />}
      actions={
        <Button onClick={() => void exportCsv()}>
          <FormattedMessage id="action.exportCsv" />
        </Button>
      }
    >
      <Panel className="panel--flush">
        <div className="panel__pad toolbar">
          <input
            className="search"
            type="search"
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder={intl.formatMessage({ id: 'audit.search' })}
            aria-label={intl.formatMessage({ id: 'audit.search' })}
          />
          <Segmented
            label={intl.formatMessage({ id: 'audit.category' })}
            value={category}
            onChange={setCategory}
            options={(['all', ...auditCategories] as Category[]).map((c) => ({
              value: c,
              label: <FormattedMessage id={`auditCategory.${c}`} />,
            }))}
          />
          <select
            className="select"
            value={days}
            onChange={(e) => setDays(Number(e.target.value) as Days)}
            aria-label={intl.formatMessage({ id: 'audit.window' })}
          >
            {([1, 7, 30, 90] as Days[]).map((d) => (
              <option key={d} value={d}>
                {intl.formatMessage({ id: 'audit.lastDays' }, { n: d })}
              </option>
            ))}
          </select>
        </div>
        {exportError && (
          <p className="error panel__pad" role="alert">
            <FormattedMessage id={errorMessageId(exportError)} />
          </p>
        )}
        <Loaded load={load} reload={reload}>
          {(data) => <AuditTable rows={data.rows} now={new Date()} />}
        </Loaded>
        <div className="panel__pad">
          <LockNote>
            <FormattedMessage id="audit.lock" />
          </LockNote>
        </div>
      </Panel>
    </Page>
  );
}

export function AuditTable({ rows, now }: { rows: AuditRow[]; now: Date }) {
  const intl = useIntl();
  if (rows.length === 0) {
    return (
      <Empty>
        <FormattedMessage id="audit.empty" />
      </Empty>
    );
  }
  return (
    <table className="table">
      <thead>
        <tr>
          <th>
            <FormattedMessage id="col.time" />
          </th>
          <th>
            <FormattedMessage id="col.actor" />
          </th>
          <th>
            <FormattedMessage id="col.action" />
          </th>
          <th>
            <FormattedMessage id="col.target" />
          </th>
          <th>
            <FormattedMessage id="col.reason" />
          </th>
        </tr>
      </thead>
      <tbody>
        {rows.map((r) => (
          <tr key={r.id}>
            <td className="nowrap">{when(intl, r.at, now)}</td>
            <td>
              <strong>{r.actor}</strong>
              <br />
              <span className="muted">{r.role}</span>
            </td>
            <td>
              <AuditActionText action={r.action} target={r.target} detail={r.detail} />{' '}
              <Pill tone={categoryTone[r.category]}>
                <FormattedMessage id={`auditCategory.${r.category}`} />
              </Pill>
            </td>
            <td className="mono">{r.target}</td>
            <td>{r.reason ?? '—'}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
