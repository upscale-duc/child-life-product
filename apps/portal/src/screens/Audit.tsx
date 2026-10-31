import { auditCategories } from '@child-life/contracts';
import { useEffect, useState } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { ApiError, useApi, useLoad, type AuditRow } from '../api';
import { downloadCsv, toCsv, when } from '../format';
import {
  Button,
  Empty,
  errorMessageId,
  Loaded,
  LockNote,
  Page,
  Panel,
  Pill,
  Segmented,
  SelectMenu,
  TableScroll,
  useSort,
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
  families: 'high',
  staff: 'muted',
  reference: 'ok',
  content: 'purple',
  analytics: 'info',
  premium: 'high',
  notifications: 'wait',
  product: 'info',
};

/**
 * A12 Nhật ký thao tác: append-only; codes, actions and before / after, never family content.
 * No reason is asked any more (D-090); older lines show the note they had.
 */
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
      info={<FormattedMessage id="audit.sub" />}
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
          <SelectMenu
            value={days}
            onChange={setDays}
            label={intl.formatMessage({ id: 'audit.window' })}
            options={([1, 7, 30, 90] as Days[]).map((d) => ({
              value: d,
              label: intl.formatMessage({ id: 'audit.lastDays' }, { n: d }),
            }))}
          />
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
  const sort = useSort(rows, {
    at: (r) => r.at,
    actor: (r) => r.actor,
    action: (r) => r.category,
  });
  if (rows.length === 0) {
    return (
      <Empty>
        <FormattedMessage id="audit.empty" />
      </Empty>
    );
  }
  return (
    <TableScroll min={760}>
      <table className="table">
        <thead>
          <tr>
            {sort.th('at', <FormattedMessage id="col.time" />)}
            {sort.th('actor', <FormattedMessage id="col.actor" />)}
            {sort.th('action', <FormattedMessage id="col.action" />)}
            <th>
              <FormattedMessage id="col.target" />
            </th>
          </tr>
        </thead>
        <tbody>
          {sort.rows.map((r) => (
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
                {/* Lines from before D-090 may carry the note that was asked then. */}
                {r.reason && (
                  <span className="block text-xs text-muted-foreground">“{r.reason}”</span>
                )}
              </td>
              <td className="mono">{r.target}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </TableScroll>
  );
}
