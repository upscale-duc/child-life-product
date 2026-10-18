import {
  staffCan,
  type ArticleDraft,
  type ContentKind,
  type EditorialAction,
  type ReferenceMilestoneDraft,
  type StageDraft,
} from '@child-life/contracts';
import { BadgeCheck, ExternalLink, Pencil } from 'lucide-react';
import { useState } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { Badge } from '@/components/ui/badge';
import { Button as UiButton } from '@/components/ui/button';
import { cn } from '@/lib/utils';
import { useLoad } from '../api';
import {
  EmptyState,
  FilterBar,
  HelpPopover,
  Notice,
  OverflowMenu,
  SearchInput,
  StatTiles,
} from '../content-kit';
import { ContentPolicyPanel, useOwnWorkBlocked } from '../content-policy';
import { routePaths, useStaff } from '../context';
import { Loaded, Page, SelectMenu } from '../ui';
import { ArticlePreview } from './Articles';
import {
  ActDialog,
  ContentImagesProvider,
  PreviewCard,
  StatusCell,
  WorkflowMain,
  actionsFor,
  dateTime,
  reviewOf,
  stageAgeText,
  textOf,
  useContentList,
  weeksLabel,
  workflowMenu,
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
 * qualified review; never the person who edited last unless the policy lets the Owner approve
 * alone, D-058 / D-079), "Đã duyệt" the publish step (Nháp → Chờ duyệt → Đã duyệt → Xuất bản),
 * and "Cần rà soát lại" the items whose 12-month re-review date has passed. The count tiles are
 * the tabs; the list sits next to the selected item, its next step on top.
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
      actions={
        <HelpPopover title={<FormattedMessage id="review.howTitle" />}>
          <ReviewSteps />
          <p className="text-muted-foreground">
            <FormattedMessage id="review.howBody" />
          </p>
        </HelpPopover>
      }
    >
      <Loaded load={load} reload={reload}>
        {(view) => <ReviewBody view={view} onChanged={reload} />}
      </Loaded>
    </Page>
  );
}

/** Nháp → Chờ duyệt → Đã duyệt → Đã xuất bản. */
export function ReviewSteps() {
  return (
    <ol className="cl-steps">
      {(['draft', 'in_review', 'approved', 'published'] as const).map((s) => (
        <li key={s}>
          <FormattedMessage id={`content.status.${s}`} />
        </li>
      ))}
    </ol>
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
  const [q, setQ] = useState('');
  const [kind, setKind] = useState<'all' | ContentKind>('all');
  const counts: Record<QueueTab, number> = {
    in_review: queueRows(view.rows, 'in_review').length,
    approved: queueRows(view.rows, 'approved').length,
    due: queueRows(view.rows, 'due').length,
  };
  const inTab = queueRows(view.rows, tab);
  const rows = inTab.filter(
    (r) =>
      (kind === 'all' || r.kind === kind) &&
      (!q.trim() || `${r.title.vi} ${r.title.en}`.toLowerCase().includes(q.trim().toLowerCase())),
  );
  const current = rows.find((r) => r.id === selected) ?? null;
  const can = {
    edit: staffCan(staff.levels, 'content.edit'),
    approve: staffCan(staff.levels, 'content.approve'),
  };
  return (
    <div className="grid gap-4">
      <StatTiles
        items={tabs.map((t) => ({
          key: t,
          label: <FormattedMessage id={`review.tab.${t}`} />,
          value: counts[t],
          tone: counts[t] ? (t === 'due' ? 'error' : 'warn') : 'muted',
          foot: <FormattedMessage id={`review.tabFoot.${t}`} />,
          active: tab === t,
          onClick: () => {
            setTab(t);
            setSelected(null);
          },
        }))}
      />
      {!can.approve && (
        <Notice tone="info">
          <FormattedMessage id="review.viewOnly" />
        </Notice>
      )}
      <div className="grid items-start gap-4 lg:grid-cols-[minmax(300px,2fr)_minmax(0,3fr)]">
        <div className="overflow-hidden rounded-xl border bg-card lg:sticky lg:top-[4.5rem]">
          <div className="flex items-center gap-2 border-b px-4 pt-3 pb-2">
            <h2 className="text-[15px] font-semibold">
              <FormattedMessage id={`review.tab.${tab}`} />
            </h2>
            <span className="text-sm text-muted-foreground tabular-nums">{inTab.length}</span>
          </div>
          <FilterBar
            active={!!q || kind !== 'all'}
            onClear={() => {
              setQ('');
              setKind('all');
            }}
            shown={rows.length}
            total={inTab.length}
          >
            <SearchInput
              className="sm:w-full lg:w-full"
              value={q}
              onChange={setQ}
              placeholder={intl.formatMessage({ id: 'review.search' })}
            />
            <SelectMenu
              label={intl.formatMessage({ id: 'review.col.kind' })}
              value={kind}
              onChange={setKind}
              options={[
                { value: 'all', label: intl.formatMessage({ id: 'review.kind.all' }) },
                ...(['article', 'stage', 'milestone'] as const).map((k) => ({
                  value: k,
                  label: intl.formatMessage({ id: `review.kind.${k}` }),
                })),
              ]}
            />
          </FilterBar>
          {rows.length ? (
            <ul className="max-h-[calc(100svh-16rem)] divide-y overflow-y-auto">
              {rows.map((r) => (
                <li key={r.id}>
                  <button
                    type="button"
                    aria-current={r.id === selected ? 'true' : undefined}
                    className={cn(
                      'grid w-full gap-1 px-4 py-3 text-left transition-colors hover:bg-muted/60',
                      r.id === selected && 'bg-accent/70 hover:bg-accent/70',
                    )}
                    onClick={() => setSelected(r.id)}
                  >
                    <span className="flex items-center gap-2">
                      <Badge variant="outline" className="font-normal">
                        <FormattedMessage id={`review.kind.${r.kind}`} />
                      </Badge>
                      <span className="truncate text-xs text-muted-foreground">
                        {ageOf(intl, r)}
                      </span>
                    </span>
                    <span className="line-clamp-2 font-medium">
                      {textOf(intl, r.title) || r.id}
                    </span>
                    <span className="text-xs text-muted-foreground tabular-nums">
                      {tab === 'due' ? (
                        <FormattedMessage
                          id="review.dueOn"
                          values={{ due: r.live?.reviewDueOn.split('-').reverse().join('/') }}
                        />
                      ) : (
                        <>
                          {tab === 'approved'
                            ? r.approverName
                            : (r.submittedByName ?? r.lastEditorName)}{' '}
                          · {dateTime(intl, r.updatedAt)}
                        </>
                      )}
                    </span>
                  </button>
                </li>
              ))}
            </ul>
          ) : (
            <EmptyState
              icon={BadgeCheck}
              title={
                <FormattedMessage id={inTab.length ? 'content.noMatch' : `review.empty.${tab}`} />
              }
            />
          )}
        </div>
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
          <div className="rounded-xl border border-dashed bg-card">
            <EmptyState title={<FormattedMessage id="review.pick" />}>
              <FormattedMessage id={`review.pickHint.${tab}`} />
            </EmptyState>
          </div>
        )}
      </div>
      <ContentPolicyPanel />
    </div>
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

/** The decision steps are buttons; taking an item off the app goes behind "⋯". */
const reviewSteps: readonly EditorialAction[] = ['reject', 'approve', 'publish', 'reconfirm'];

/** The selected item: its next step, who did what, notes and sources, then the app preview. */
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
  const actions: EditorialAction[] = actionsFor(row, can).filter(
    (a) => a !== 'archive' && a !== 'submit',
  );
  const main = reviewSteps.filter((a) => actions.includes(a));
  const rest = actions.filter((a) => !main.includes(a));
  const sources = (item.data.sources as Array<{ label: string; url: string }> | undefined) ?? [];
  const review = reviewOf(item);
  const editorUrl = `${editorRoute[row.kind]}/${encodeURIComponent(row.id)}`;
  const facts: Array<[string, string | null | undefined]> = [
    ['review.lastEditor', row.lastEditorName],
    ['review.submittedBy', row.submittedByName],
    ['review.approvedBy', row.approverName],
    ['content.reviewerLabel', row.reviewerLabel ?? '—'],
  ];
  return (
    <section className="grid gap-4">
      <div className="grid gap-3 rounded-xl border bg-card p-5">
        <div className="flex flex-wrap items-center gap-2">
          <Badge variant="outline" className="font-normal">
            <FormattedMessage id={`review.kind.${row.kind}`} />
          </Badge>
          <StatusCell row={row} />
        </div>
        <div className="flex flex-wrap items-start gap-3">
          <h2 className="min-w-0 flex-1 text-lg leading-7 font-semibold tracking-tight">
            {textOf(intl, row.title) || row.id}
          </h2>
          <div className="flex flex-wrap items-center gap-2">
            <UiButton variant="outline" size="sm" asChild>
              <a href={editorUrl}>
                <Pencil />
                <FormattedMessage id="review.openEditor" />
              </a>
            </UiButton>
            <WorkflowMain actions={main} onPick={setAct} />
            <OverflowMenu items={workflowMenu(rest, setAct)} />
          </div>
        </div>
        {sameEditor && (row.status === 'in_review' || row.live?.dueForReview) && (
          <Notice tone="warn">
            <FormattedMessage id="content.act.samePerson" />
          </Notice>
        )}
        <dl className="grid gap-x-6 gap-y-2 text-sm sm:grid-cols-2">
          {facts
            .filter(([, v]) => v)
            .map(([id, v]) => (
              <div key={id} className="grid gap-0.5">
                <dt className="text-xs text-muted-foreground">
                  <FormattedMessage id={id} />
                </dt>
                <dd>{v}</dd>
              </div>
            ))}
          {row.live && (
            <div className="grid gap-0.5">
              <dt className="text-xs text-muted-foreground">
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
            </div>
          )}
        </dl>
        {item.notes && (
          <Notice tone="info" title={<FormattedMessage id="content.notes" />}>
            {item.notes}
          </Notice>
        )}
        <div className="grid gap-1.5">
          <span className="text-[13px] font-medium">
            <FormattedMessage id="content.sources" />{' '}
            <span className="text-muted-foreground tabular-nums">{sources.length}</span>
          </span>
          {sources.length ? (
            <ul className="grid gap-1 text-sm">
              {sources.map((s, i) => (
                <li key={i}>
                  <a
                    href={s.url}
                    target="_blank"
                    rel="noreferrer noopener"
                    className="inline-flex items-center gap-1 text-primary hover:underline"
                  >
                    {s.label}
                    <ExternalLink className="size-3.5" aria-hidden="true" />
                  </a>
                </li>
              ))}
            </ul>
          ) : (
            <Notice tone="warn">
              <FormattedMessage id="review.noSources" />
            </Notice>
          )}
        </div>
      </div>
      <PreviewCard lang={lang} onLang={setLang}>
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
      </PreviewCard>
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
    </section>
  );
}
