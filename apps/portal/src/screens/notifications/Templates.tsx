import {
  inboxGroups,
  notificationTemplateStatuses,
  notificationTemplates,
  type InboxGroup,
  type NotificationTemplateRow,
  type NotificationTemplateStatus,
} from '@child-life/contracts';
import { FileText } from 'lucide-react';
import { useMemo, useState } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { useLoad } from '../../api';
import { EmptyState, FilterBar, SearchInput } from '../../content-kit';
import { Loaded, Panel, Pill, SelectMenu, TableScroll, useSort } from '../../ui';
import { TemplateStatusPill, at, destinationName, pick } from './shared';

export function TemplatesTab({ onOpen }: { onOpen: (id: string) => void }) {
  const [load, reload] = useLoad<{ templates: NotificationTemplateRow[] }>(
    'staffNotificationTemplates',
    {},
    'ntf-templates',
  );
  return (
    <Loaded load={load} reload={reload}>
      {(data) => <TemplatesView rows={data.templates} onOpen={onOpen} />}
    </Loaded>
  );
}

type GroupFilter = 'all' | InboxGroup;
type StatusFilter = 'all' | NotificationTemplateStatus | 'has_draft';

/** Mẫu nội dung: every template with its live version, status and draft, searchable and sortable. */
export function TemplatesView({
  rows,
  onOpen,
}: {
  rows: NotificationTemplateRow[];
  onOpen: (id: string) => void;
}) {
  const intl = useIntl();
  const [q, setQ] = useState('');
  const [group, setGroup] = useState<GroupFilter>('all');
  const [status, setStatus] = useState<StatusFilter>('all');
  const nameOf = (r: NotificationTemplateRow) =>
    notificationTemplates[r.id] ? pick(intl, notificationTemplates[r.id].name) : r.id;
  const filtered = useMemo(() => {
    const query = q.trim().toLowerCase();
    return rows.filter(
      (r) =>
        (group === 'all' || r.group === group) &&
        (status === 'all' ||
          (status === 'has_draft' ? r.draftState !== 'none' : r.status === status)) &&
        (!query ||
          [r.id, nameOf(r), r.kind, intl.formatMessage({ id: `ntf.kind.${r.kind}` })]
            .join(' ')
            .toLowerCase()
            .includes(query)),
    );
    // nameOf reads the locale through intl.
  }, [rows, q, group, status, intl]);
  const sort = useSort(filtered, {
    name: (r) => nameOf(r),
    kind: (r) => intl.formatMessage({ id: `ntf.kind.${r.kind}` }),
    group: (r) => intl.formatMessage({ id: `ntf.group.${r.group}` }),
    version: (r) => r.liveVersion,
    status: (r) => r.status,
    updated: (r) => r.updatedAt ?? '',
    sent: (r) => r.sent30d,
  });
  const active = q !== '' || group !== 'all' || status !== 'all';
  return (
    <Panel className="panel--flush">
      <FilterBar
        active={active}
        onClear={() => {
          setQ('');
          setGroup('all');
          setStatus('all');
        }}
        shown={filtered.length}
        total={rows.length}
      >
        <SearchInput
          value={q}
          onChange={setQ}
          placeholder={intl.formatMessage({ id: 'ntf.tpl.search' })}
        />
        <SelectMenu
          label={intl.formatMessage({ id: 'ntf.col.group' })}
          value={group}
          options={(['all', ...inboxGroups] as GroupFilter[]).map((g) => ({
            value: g,
            label: intl.formatMessage({ id: g === 'all' ? 'ntf.groupAll' : `ntf.group.${g}` }),
          }))}
          onChange={setGroup}
        />
        <SelectMenu
          label={intl.formatMessage({ id: 'ntf.col.status' })}
          value={status}
          options={(['all', ...notificationTemplateStatuses, 'has_draft'] as StatusFilter[]).map(
            (s) => ({
              value: s,
              label: intl.formatMessage({
                id:
                  s === 'all'
                    ? 'ntf.statusAll'
                    : s === 'has_draft'
                      ? 'ntf.tpl.hasDraft'
                      : `ntf.tplStatus.${s}`,
              }),
            }),
          )}
          onChange={setStatus}
        />
      </FilterBar>
      {sort.rows.length === 0 ? (
        <EmptyState icon={FileText} title={<FormattedMessage id="ntf.tpl.empty" />} />
      ) : (
        <TableScroll min={1100}>
          <table className="table">
            <thead>
              <tr>
                {sort.th('name', <FormattedMessage id="ntf.col.template" />)}
                {sort.th('kind', <FormattedMessage id="ntf.col.kind" />)}
                {sort.th('group', <FormattedMessage id="ntf.col.group" />)}
                <th>
                  <FormattedMessage id="ntf.col.languages" />
                </th>
                {sort.th('version', <FormattedMessage id="ntf.col.liveVersion" />)}
                {sort.th('status', <FormattedMessage id="ntf.col.status" />)}
                <th>
                  <FormattedMessage id="ntf.col.draft" />
                </th>
                {sort.th('updated', <FormattedMessage id="ntf.col.updated" />)}
                <th>
                  <FormattedMessage id="ntf.col.destination" />
                </th>
                {sort.th('sent', <FormattedMessage id="ntf.col.sent30d" />)}
              </tr>
            </thead>
            <tbody>
              {sort.rows.map((r) => (
                <tr key={r.id} data-template={r.id}>
                  <td>
                    <button
                      type="button"
                      className="text-left font-medium text-primary hover:underline"
                      onClick={() => onOpen(r.id)}
                    >
                      {nameOf(r)}
                    </button>
                    <span className="block font-mono text-[11px] text-muted-foreground">
                      {r.id}
                    </span>
                  </td>
                  <td>
                    <FormattedMessage id={`ntf.kind.${r.kind}`} />
                  </td>
                  <td>
                    <FormattedMessage id={`ntf.group.${r.group}`} />
                  </td>
                  <td className="nowrap">
                    <Pill tone={r.hasVi ? 'ok' : 'error'}>VI</Pill>{' '}
                    <Pill tone={r.hasEn ? 'ok' : 'error'}>EN</Pill>
                  </td>
                  <td className="nowrap tabular-nums">
                    {r.liveVersion === 0 ? (
                      <FormattedMessage id="ntf.tpl.v0short" />
                    ) : (
                      <FormattedMessage id="ntf.tpl.version" values={{ v: r.liveVersion }} />
                    )}
                  </td>
                  <td>
                    <TemplateStatusPill status={r.status} />
                  </td>
                  <td>
                    {r.draftState === 'none' ? (
                      <span className="muted">—</span>
                    ) : (
                      <Pill tone={r.draftState === 'ready_for_review' ? 'purple' : 'wait'}>
                        <FormattedMessage id={`ntf.draftState.${r.draftState}`} />
                      </Pill>
                    )}
                  </td>
                  <td className="text-[13px]">
                    {r.updatedAt ? (
                      <>
                        {at(intl, r.updatedAt)}
                        {r.updatedBy && (
                          <span className="block text-muted-foreground">{r.updatedBy}</span>
                        )}
                      </>
                    ) : (
                      <span className="muted">—</span>
                    )}
                  </td>
                  <td>{destinationName(intl, r.destination)}</td>
                  <td className="text-right tabular-nums">
                    {r.sent30d === null ? '—' : intl.formatNumber(r.sent30d)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </TableScroll>
      )}
    </Panel>
  );
}
