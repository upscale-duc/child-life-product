import {
  inboxGroups,
  notificationTemplateStatuses,
  notificationTemplates,
  type InboxGroup,
  type NotificationTemplateRow,
  type NotificationTemplateStatus,
} from '@child-life/contracts';
import { ChevronRight, FileText } from 'lucide-react';
import { useMemo, useState } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import type { Load } from '../../api';
import { EmptyState, FilterBar, SearchInput, StatTiles } from '../../content-kit';
import { Panel, SelectMenu, useSort } from '../../ui';
import { CodeText, DataTable, LoadedSkeleton, PageSkeleton, StatusDot, TabHeader } from './kit';
import { TemplateStatusPill, at, destinationName, pick } from './shared';

export function TemplatesTab({
  load,
  reload,
  onOpen,
}: {
  load: Load<{ templates: NotificationTemplateRow[] }> | null;
  reload: () => void;
  onOpen: (id: string) => void;
}) {
  if (!load) return <PageSkeleton />;
  return (
    <LoadedSkeleton load={load} reload={reload}>
      {(data) => <TemplatesView rows={data.templates} onOpen={onOpen} />}
    </LoadedSkeleton>
  );
}

type GroupFilter = 'all' | InboxGroup;
type StatusFilter = 'all' | NotificationTemplateStatus | 'has_draft' | 'in_review';

/** The counts above the list; each tile filters it. */
export function templateCounts(rows: readonly NotificationTemplateRow[]) {
  return {
    total: rows.length,
    published: rows.filter((r) => r.status === 'published').length,
    builtin: rows.filter((r) => r.status === 'builtin').length,
    drafts: rows.filter((r) => r.draftState === 'draft').length,
    review: rows.filter((r) => r.draftState === 'ready_for_review').length,
    paused: rows.filter((r) => r.status === 'paused' || r.status === 'archived').length,
  };
}

/**
 * Mẫu nội dung: every template, its live version and state at a glance (status + draft in one
 * column), counts that filter, search, group / status filters and sortable columns.
 */
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
          (status === 'has_draft'
            ? r.draftState === 'draft'
            : status === 'in_review'
              ? r.draftState === 'ready_for_review'
              : r.status === status)) &&
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
    version: (r) => r.liveVersion,
    status: (r) =>
      `${r.draftState === 'ready_for_review' ? 0 : r.draftState === 'draft' ? 1 : 2}${r.status}`,
    updated: (r) => r.updatedAt ?? '',
    sent: (r) => r.sent30d,
  });
  const counts = templateCounts(rows);
  const tile = (key: StatusFilter, label: string, n: number, tone?: 'warn' | 'muted') => ({
    key,
    label: <FormattedMessage id={label} />,
    value: intl.formatNumber(n),
    tone,
    active: status === key,
    onClick: () => setStatus(status === key ? 'all' : key),
  });
  const active = q !== '' || group !== 'all' || status !== 'all';
  return (
    <div className="stack">
      <TabHeader
        title={<FormattedMessage id="ntf.tab.templates" />}
        purpose={<FormattedMessage id="ntf.purpose.templates" />}
      />
      <StatTiles
        items={[
          tile('published', 'ntf.tplStatus.published', counts.published),
          tile('in_review', 'ntf.tpl.inReview', counts.review, counts.review ? 'warn' : 'muted'),
          tile('has_draft', 'ntf.tpl.hasDraft', counts.drafts),
          tile('builtin', 'ntf.tplStatus.builtin', counts.builtin, 'muted'),
        ]}
      />
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
            options={(
              ['all', 'in_review', 'has_draft', ...notificationTemplateStatuses] as StatusFilter[]
            ).map((s) => ({
              value: s,
              label: intl.formatMessage({
                id:
                  s === 'all'
                    ? 'ntf.statusAll'
                    : s === 'has_draft'
                      ? 'ntf.tpl.hasDraft'
                      : s === 'in_review'
                        ? 'ntf.tpl.inReview'
                        : `ntf.tplStatus.${s}`,
              }),
            }))}
            onChange={setStatus}
          />
        </FilterBar>
        {sort.rows.length === 0 ? (
          <EmptyState icon={FileText} title={<FormattedMessage id="ntf.tpl.empty" />} />
        ) : (
          <DataTable min={980} label={intl.formatMessage({ id: 'ntf.tab.templates' })}>
            <table className="table">
              <thead>
                <tr>
                  {sort.th('name', <FormattedMessage id="ntf.col.template" />)}
                  {sort.th('status', <FormattedMessage id="ntf.col.state" />)}
                  {sort.th('version', <FormattedMessage id="ntf.col.liveVersion" />)}
                  {sort.th('kind', <FormattedMessage id="ntf.col.kind" />)}
                  <th>
                    <FormattedMessage id="ntf.col.languages" />
                  </th>
                  <th>
                    <FormattedMessage id="ntf.col.destination" />
                  </th>
                  {sort.th('updated', <FormattedMessage id="ntf.col.updated" />)}
                  {sort.th('sent', <FormattedMessage id="ntf.col.sent30d" />)}
                  <th>
                    <span className="sr-only">
                      <FormattedMessage id="ntf.tpl.open" />
                    </span>
                  </th>
                </tr>
              </thead>
              <tbody>
                {sort.rows.map((r) => (
                  <tr
                    key={r.id}
                    data-template={r.id}
                    className="cursor-pointer"
                    onClick={() => onOpen(r.id)}
                  >
                    <td>
                      <button
                        type="button"
                        className="text-left font-medium hover:text-primary hover:underline focus-visible:underline"
                        onClick={(e) => {
                          e.stopPropagation();
                          onOpen(r.id);
                        }}
                      >
                        {nameOf(r)}
                      </button>
                      <span className="block">
                        <CodeText value={r.id} />
                      </span>
                    </td>
                    <td>
                      <span className="flex flex-wrap items-center gap-1.5">
                        <TemplateStatusPill status={r.status} />
                        {r.draftState !== 'none' && (
                          <StatusDot tone={r.draftState === 'ready_for_review' ? 'warn' : 'wait'}>
                            <span className="text-[13px]">
                              <FormattedMessage id={`ntf.draftState.${r.draftState}`} />
                            </span>
                          </StatusDot>
                        )}
                      </span>
                    </td>
                    <td className="nowrap tabular-nums">
                      {r.liveVersion === 0 ? (
                        <FormattedMessage id="ntf.tpl.v0short" />
                      ) : (
                        <FormattedMessage id="ntf.tpl.version" values={{ v: r.liveVersion }} />
                      )}
                    </td>
                    <td>
                      <FormattedMessage id={`ntf.kind.${r.kind}`} />
                      <span className="block text-[12px] text-muted-foreground">
                        <FormattedMessage id={`ntf.group.${r.group}`} />
                      </span>
                    </td>
                    <td className="nowrap text-[13px]">
                      <LangMark on={r.hasVi} code="VI" /> <LangMark on={r.hasEn} code="EN" />
                    </td>
                    <td className="text-[13px]">{destinationName(intl, r.destination)}</td>
                    <td className="text-[13px]">
                      {r.updatedAt ? (
                        <>
                          <span className="nowrap">{at(intl, r.updatedAt)}</span>
                          {r.updatedBy && (
                            <span className="block text-muted-foreground">{r.updatedBy}</span>
                          )}
                        </>
                      ) : (
                        <span className="muted">—</span>
                      )}
                    </td>
                    <td className="text-right tabular-nums">
                      {r.sent30d === null ? '—' : intl.formatNumber(r.sent30d)}
                    </td>
                    <td className="w-8 text-muted-foreground">
                      <ChevronRight className="size-4" aria-hidden="true" />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </DataTable>
        )}
      </Panel>
    </div>
  );
}

function LangMark({ on, code }: { on: boolean; code: string }) {
  const intl = useIntl();
  return (
    <span
      className={on ? 'font-medium' : 'text-destructive line-through'}
      title={intl.formatMessage(
        { id: on ? 'ntf.tpl.langOk' : 'ntf.tpl.langMissing' },
        { lang: code },
      )}
    >
      {code}
    </span>
  );
}
