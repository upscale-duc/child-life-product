import {
  staffCan,
  type ArticleDraft,
  type ContentKind,
  type EditorialAction,
  type ReferenceMilestoneDraft,
  type StageDraft,
} from '@child-life/contracts';
import { useState } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { useLoad } from '../api';
import { ContentPolicyPanel, useOwnWorkBlocked } from '../content-policy';
import { routePaths, useStaff } from '../context';
import { Button, Empty, Kpi, Loaded, Page, Panel, Segmented, TableScroll } from '../ui';
import { ArticlePreview } from './Articles';
import {
  ActDialog,
  ContentImagesProvider,
  LangTabs,
  StatusCell,
  WorkflowButtons,
  actionsFor,
  dateTime,
  reviewOf,
  stageAgeText,
  textOf,
  useContentList,
  weeksLabel,
  type ContentItemView,
  type ContentQueueView,
  type ContentRow,
  type Lang,
} from './content-common';
import { MilestonePreview, milestoneAgeText } from './Milestones';
import { StagePreview } from './Stages';

/**
 * Duyệt nội dung (Figma B03 `317:43747`, B04 `317:43979`; D-076 #7): one queue across articles,
 * stage content and reference milestones. "Chờ duyệt" is the review step (checklist, sources, the
 * qualified review; never the person who edited last, D-058), "Đã duyệt" the publish step
 * (Nháp → Chờ duyệt → Đã duyệt → Xuất bản), and "Cần rà soát lại" the items whose 12-month
 * re-review date has passed.
 */

export type QueueTab = 'in_review' | 'approved' | 'due';
const tabs: QueueTab[] = ['in_review', 'approved', 'due'];

export function queueRows(rows: ContentRow[], tab: QueueTab): ContentRow[] {
  return rows.filter((r) => (tab === 'due' ? !!r.live?.dueForReview : r.status === tab));
}

const editorRoute: Record<ContentKind, string> = {
  article: routePaths.articles,
  stage: routePaths.stages,
  milestone: routePaths.milestones,
};

export function ContentReviewScreen() {
  const [load, reload] = useContentList<ContentQueueView>('queue');
  return (
    <Page
      title={<FormattedMessage id="review.title" />}
      subtitle={<FormattedMessage id="review.sub" />}
    >
      <Loaded load={load} reload={reload}>
        {(view) => <ReviewBody view={view} onChanged={reload} />}
      </Loaded>
    </Page>
  );
}

export function ReviewBody({
  view,
  onChanged,
  initialTab = 'in_review',
  initialSelected = null,
}: {
  view: ContentQueueView;
  onChanged: () => void;
  initialTab?: QueueTab;
  initialSelected?: string | null;
}) {
  const intl = useIntl();
  const staff = useStaff();
  const [tab, setTab] = useState<QueueTab>(initialTab);
  const [selected, setSelected] = useState<string | null>(initialSelected);
  const counts: Record<QueueTab, number> = {
    in_review: queueRows(view.rows, 'in_review').length,
    approved: queueRows(view.rows, 'approved').length,
    due: queueRows(view.rows, 'due').length,
  };
  const rows = queueRows(view.rows, tab);
  const current = rows.find((r) => r.id === selected) ?? null;
  const can = {
    edit: staffCan(staff.levels, 'content.edit'),
    approve: staffCan(staff.levels, 'content.approve'),
  };
  return (
    <>
      <div className="kpis kpis--3">
        {tabs.map((t) => (
          <Kpi
            key={t}
            label={<FormattedMessage id={`review.tab.${t}`} />}
            value={counts[t]}
            tone={counts[t] ? (t === 'due' ? 'error' : 'warn') : 'muted'}
          />
        ))}
      </div>
      <ol className="cl-steps" aria-label={intl.formatMessage({ id: 'review.steps' })}>
        {(['draft', 'in_review', 'approved', 'published'] as const).map((s) => (
          <li
            key={s}
            className={
              (tab === 'in_review' && s === 'in_review') || (tab === 'approved' && s === 'approved')
                ? 'cl-steps__on'
                : ''
            }
          >
            <FormattedMessage id={`content.status.${s}`} />
          </li>
        ))}
      </ol>
      {!can.approve && (
        <p className="note">
          <FormattedMessage id="review.viewOnly" />
        </p>
      )}
      <ContentPolicyPanel />
      <div className="cols cols--list">
        <Panel className="panel--flush">
          <div className="toolbar cl-toolbar">
            <Segmented
              label={intl.formatMessage({ id: 'review.title' })}
              value={tab}
              onChange={(t) => {
                setTab(t);
                setSelected(null);
              }}
              options={tabs.map((t) => ({
                value: t,
                label: (
                  <FormattedMessage
                    id="review.tabCount"
                    values={{ n: counts[t], tab: intl.formatMessage({ id: `review.tab.${t}` }) }}
                  />
                ),
              }))}
            />
          </div>
          {rows.length ? (
            <TableScroll min={520}>
              <table className="table">
                <thead>
                  <tr>
                    <th>
                      <FormattedMessage id="review.col.kind" />
                    </th>
                    <th>
                      <FormattedMessage id="content.col.title" />
                    </th>
                    <th>
                      <FormattedMessage id={tab === 'due' ? 'review.col.due' : 'review.col.by'} />
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {rows.map((r) => (
                    <tr
                      key={r.id}
                      className={`cl-row ${r.id === selected ? 'table__row--on' : ''}`}
                      onClick={() => setSelected(r.id)}
                    >
                      <td className="nowrap">
                        <FormattedMessage id={`review.kind.${r.kind}`} />
                      </td>
                      <td>
                        <button
                          type="button"
                          className="link-button"
                          onClick={() => setSelected(r.id)}
                        >
                          {textOf(intl, r.title) || r.id}
                        </button>
                        <div className="muted">{ageOf(intl, r)}</div>
                      </td>
                      <td className="nowrap">
                        {tab === 'due' ? (
                          r.live?.reviewDueOn.split('-').reverse().join('/')
                        ) : (
                          <>
                            {tab === 'approved'
                              ? r.approverName
                              : (r.submittedByName ?? r.lastEditorName)}
                            <div className="muted">{dateTime(intl, r.updatedAt)}</div>
                          </>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </TableScroll>
          ) : (
            <Empty>
              <FormattedMessage id={`review.empty.${tab}`} />
            </Empty>
          )}
        </Panel>
        {current ? (
          <ContentImagesProvider canUpload={false}>
            <ReviewPanel
              key={`${current.id}:${current.updatedAt}`}
              row={current}
              requireReview={view.requireReview}
              today={view.today}
              staffUid={staff.uid}
              can={can}
              onChanged={() => {
                setSelected(null);
                onChanged();
              }}
            />
          </ContentImagesProvider>
        ) : (
          <Panel>
            <Empty>
              <FormattedMessage id="review.pick" />
            </Empty>
          </Panel>
        )}
      </div>
    </>
  );
}

function ageOf(intl: ReturnType<typeof useIntl>, r: ContentRow): string {
  if (r.ageWeeks) return weeksLabel(intl, r.ageWeeks);
  if (r.age) return stageAgeText(intl, r.age);
  const m = r.ageRange as { unit: 'weeks' | 'months'; from: number; to: number } | undefined;
  return m ? milestoneAgeText(intl, m) : '';
}

function ReviewPanel({
  row,
  requireReview,
  today,
  staffUid,
  can,
  onChanged,
}: {
  row: ContentRow;
  requireReview: boolean;
  today: string;
  staffUid: string;
  can: { edit: boolean; approve: boolean };
  onChanged: () => void;
}) {
  const [item, reload] = useLoad<ContentItemView>(
    'staffContentItem',
    { kind: row.kind, id: row.id },
    `review:${row.kind}:${row.id}:${row.updatedAt}`,
  );
  return (
    <Loaded load={item} reload={reload}>
      {(view) => (
        <ReviewDetail
          item={view}
          requireReview={requireReview}
          today={today}
          staffUid={staffUid}
          can={can}
          onChanged={onChanged}
        />
      )}
    </Loaded>
  );
}

/** The selected item: who did what, sources, preview and the step's actions. */
export function ReviewDetail({
  item,
  requireReview,
  today,
  staffUid,
  can,
  onChanged,
}: {
  item: ContentItemView;
  requireReview: boolean;
  today: string;
  staffUid: string;
  can: { edit: boolean; approve: boolean };
  onChanged: () => void;
}) {
  const intl = useIntl();
  const [lang, setLang] = useState<Lang>('vi');
  const [act, setAct] = useState<EditorialAction | null>(null);
  const row = item.row;
  const ownWorkBlocked = useOwnWorkBlocked(staffUid);
  const sameEditor = ownWorkBlocked(item.lastEditorUid);
  const actions = actionsFor(row, can).filter((a) => a !== 'archive' && a !== 'submit');
  const sources = (item.data.sources as Array<{ label: string; url: string }> | undefined) ?? [];
  const review = reviewOf(item);
  return (
    <Panel
      title={textOf(intl, row.title) || row.id}
      note={<FormattedMessage id={`review.kind.${row.kind}`} />}
      aside={<StatusCell row={row} />}
    >
      <div className="stack">
        <dl className="kv">
          <dt>
            <FormattedMessage id="review.lastEditor" />
          </dt>
          <dd>{row.lastEditorName}</dd>
          {row.submittedByName && (
            <>
              <dt>
                <FormattedMessage id="review.submittedBy" />
              </dt>
              <dd>{row.submittedByName}</dd>
            </>
          )}
          {row.approverName && (
            <>
              <dt>
                <FormattedMessage id="review.approvedBy" />
              </dt>
              <dd>{row.approverName}</dd>
            </>
          )}
          <dt>
            <FormattedMessage id="content.reviewerLabel" />
          </dt>
          <dd>{row.reviewerLabel ?? '—'}</dd>
          {row.live && (
            <>
              <dt>
                <FormattedMessage id="review.live" />
              </dt>
              <dd>
                <FormattedMessage
                  id="review.liveLine"
                  values={{
                    n: row.live.revision,
                    due: row.live.reviewDueOn.split('-').reverse().join('/'),
                  }}
                />
              </dd>
            </>
          )}
        </dl>
        {item.notes && <p className="note">{item.notes}</p>}
        <div>
          <strong>
            <FormattedMessage id="content.sources" />
          </strong>
          {sources.length ? (
            <ul className="cl-source-list">
              {sources.map((s, i) => (
                <li key={i}>
                  <a href={s.url} target="_blank" rel="noreferrer noopener">
                    {s.label}
                  </a>
                </li>
              ))}
            </ul>
          ) : (
            <p className="error">
              <FormattedMessage id="review.noSources" />
            </p>
          )}
        </div>
        {sameEditor && (row.status === 'in_review' || row.live?.dueForReview) && (
          <p className="note note--warn">
            <FormattedMessage id="content.act.samePerson" />
          </p>
        )}
        <WorkflowButtons actions={actions} onPick={setAct} />
        <div className="toolbar">
          <strong>
            <FormattedMessage id="content.preview" />
          </strong>
          <LangTabs value={lang} onChange={setLang} />
        </div>
        {row.kind === 'article' && (
          <ArticlePreview data={item.data as unknown as ArticleDraft} lang={lang} review={review} />
        )}
        {row.kind === 'stage' && (
          <StagePreview
            data={item.data as unknown as StageDraft}
            lang={lang}
            articles={[]}
            milestones={[]}
            review={review}
          />
        )}
        {row.kind === 'milestone' && (
          <MilestonePreview
            data={item.data as unknown as ReferenceMilestoneDraft}
            lang={lang}
            review={review}
          />
        )}
        <Button
          kind="ghost"
          onClick={() => {
            window.location.assign(`${editorRoute[row.kind]}/${encodeURIComponent(row.id)}`);
          }}
        >
          <FormattedMessage id="review.openEditor" />
        </Button>
      </div>
      {act && (
        <ActDialog
          kind={row.kind}
          id={row.id}
          action={act}
          title={textOf(intl, row.title)}
          requireReview={requireReview}
          today={today}
          sameEditor={sameEditor}
          onClose={() => setAct(null)}
          onDone={() => {
            setAct(null);
            onChanged();
          }}
        />
      )}
    </Panel>
  );
}
