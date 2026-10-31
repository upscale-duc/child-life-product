import { sourceAuthorities, staffCan, type SourceAuthority } from '@child-life/contracts';
import { ArrowLeft, FileText, Inbox } from 'lucide-react';
import { useMemo, useState } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { toast } from 'sonner';
import { useApi, useLoad } from '../../api';
import { EmptyState, FilterBar, Notice, SearchInput, Section } from '../../content-kit';
import { useNavigate, useStaff } from '../../context';
import { shortDate } from '../../format';
import { Button, Loaded, Pill, Segmented, SelectMenu, TableScroll } from '../../ui';
import { productErrorId } from './Feature';
import { AuthorityPill, ConflictText, Meta, PathText, linkClass, shortRev } from './kit';
import type { ChangeSetView, ChangeSetsView, SearchView, SourceView, SourcesView } from './types';

type Part = 'library' | 'review';

export function SourcesLoader() {
  const [part, setPart] = useState<Part>('library');
  const intl = useIntl();
  return (
    <div className="grid gap-4 [&>*]:min-w-0">
      <Segmented<Part>
        label={intl.formatMessage({ id: 'ph.sources.parts' })}
        value={part}
        onChange={setPart}
        options={[
          { value: 'library', label: intl.formatMessage({ id: 'ph.sources.library' }) },
          { value: 'review', label: intl.formatMessage({ id: 'ph.sources.review' }) },
        ]}
      />
      {part === 'library' ? (
        <>
          <KnowledgeSearch />
          <LibraryLoader />
        </>
      ) : (
        <ReviewLoader />
      )}
    </div>
  );
}

/** "Tìm trong tri thức": the Copilot's search over approved documents and decisions. */
export function KnowledgeSearch() {
  const intl = useIntl();
  const api = useApi();
  const navigate = useNavigate();
  const [q, setQ] = useState('');
  const [result, setResult] = useState<SearchView | null>(null);
  const [busy, setBusy] = useState(false);
  const run = async () => {
    if (q.trim().length < 2) return;
    setBusy(true);
    try {
      setResult(await api.call<SearchView>('productHubSearch', { q: q.trim() }));
    } catch (e) {
      toast.error(intl.formatMessage({ id: productErrorId(e) }));
    } finally {
      setBusy(false);
    }
  };
  return (
    <Section title={<FormattedMessage id="ph.search.title" />}>
      <form
        className="flex flex-wrap items-center gap-2"
        onSubmit={(e) => {
          e.preventDefault();
          void run();
        }}
      >
        <SearchInput value={q} onChange={setQ} placeholder={intl.formatMessage({ id: 'ph.search.placeholder' })} className="sm:w-96" />
        <Button type="submit" disabled={busy || q.trim().length < 2}>
          <FormattedMessage id="ph.search.go" />
        </Button>
      </form>
      {result && !result.built && (
        <Meta>
          <FormattedMessage id="ph.search.notBuilt" />
        </Meta>
      )}
      {result?.built && result.hits.length === 0 && (
        <Meta>
          <FormattedMessage id="ph.search.none" />
        </Meta>
      )}
      {result?.built && result.hits.length > 0 && (
        <ul className="mt-3 grid gap-3">
          {result.hits.map((h) => (
            <li key={h.id} className="grid gap-1 text-[13px]">
              <div className="flex flex-wrap items-center gap-2">
                <AuthorityPill authority={h.authority as SourceAuthority} />
                <span className="font-medium">{h.title}</span>
              </div>
              {h.path && <PathText path={h.anchor ? `${h.path}#${h.anchor}` : h.path} />}
              <span className="text-muted-foreground [overflow-wrap:anywhere]">{h.excerpt}</span>
              {h.features.length > 0 && (
                <span className="flex flex-wrap gap-2">
                  {h.features.map((f) => (
                    <button key={f} type="button" className={`${linkClass} font-mono`} onClick={() => navigate('product', `features/${f}`)}>
                      {f}
                    </button>
                  ))}
                </span>
              )}
            </li>
          ))}
        </ul>
      )}
    </Section>
  );
}

function LibraryLoader() {
  const [load, reload] = useLoad<SourcesView>('productHubSources', {}, 'sources');
  return <Loaded load={load} reload={reload}>{(d) => <LibraryView data={d} />}</Loaded>;
}

/** Thư viện: every approved source with its authority and revision (doc 04 §2.5). */
export function LibraryView({ data }: { data: SourcesView }) {
  const intl = useIntl();
  const navigate = useNavigate();
  const [q, setQ] = useState('');
  const [authority, setAuthority] = useState<SourceAuthority | 'all'>('all');
  const shown = useMemo(() => {
    const needle = q.trim().toLowerCase();
    return data.sources.filter(
      (s) =>
        (authority === 'all' || s.authority === authority) &&
        (!needle || s.path.toLowerCase().includes(needle) || s.title.toLowerCase().includes(needle)),
    );
  }, [data.sources, q, authority]);
  if (data.sources.length === 0) {
    return (
      <Section title={<FormattedMessage id="ph.sources.library" />}>
        <EmptyState icon={FileText} title={<FormattedMessage id="ph.sources.emptyTitle" />}>
          <FormattedMessage id="ph.sources.emptyBody" />
        </EmptyState>
      </Section>
    );
  }
  return (
    <Section title={<FormattedMessage id="ph.sources.library" />} flush>
      <FilterBar
        active={q !== '' || authority !== 'all'}
        onClear={() => {
          setQ('');
          setAuthority('all');
        }}
        shown={shown.length}
        total={data.sources.length}
      >
        <SearchInput value={q} onChange={setQ} placeholder={intl.formatMessage({ id: 'ph.sources.search' })} />
        <SelectMenu
          label={intl.formatMessage({ id: 'ph.col.authority' })}
          value={authority}
          onChange={setAuthority}
          options={[
            { value: 'all', label: `${intl.formatMessage({ id: 'ph.col.authority' })}: ${intl.formatMessage({ id: 'ph.filter.all' })}` },
            ...sourceAuthorities.map((a) => ({ value: a, label: intl.formatMessage({ id: `ph.authority.${a}` }) })),
          ]}
        />
      </FilterBar>
      <TableScroll min={760}>
        <table className="table">
          <thead>
            <tr>
              <th>
                <FormattedMessage id="ph.col.source" />
              </th>
              <th>
                <FormattedMessage id="ph.col.authority" />
              </th>
              <th>
                <FormattedMessage id="ph.col.features" />
              </th>
              <th>
                <FormattedMessage id="ph.col.revision" />
              </th>
            </tr>
          </thead>
          <tbody>
            {shown.map((s) => (
              <tr key={s.id}>
                <td>
                  <button type="button" className={`${linkClass} text-left font-medium text-foreground`} onClick={() => navigate('product', `sources/${s.id}`)}>
                    {s.title}
                  </button>
                  <div className="text-muted-foreground">
                    <PathText path={s.path} />
                  </div>
                </td>
                <td>
                  <AuthorityPill authority={s.authority} />
                  {s.docDate && <div className="mt-1 text-xs text-muted-foreground">{shortDate(intl, s.docDate)}</div>}
                </td>
                <td className="text-[12.5px]">
                  {s.features.length ? (
                    s.features.map((f) => (
                      <button key={f} type="button" className={`${linkClass} mr-2 font-mono`} onClick={() => navigate('product', `features/${f}`)}>
                        {f}
                      </button>
                    ))
                  ) : (
                    <span className="text-muted-foreground">—</span>
                  )}
                </td>
                <td className="font-mono text-[12.5px]">{shortRev(s.commit)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </TableScroll>
    </Section>
  );
}

export function SourceLoader({ id }: { id: string }) {
  const [load, reload] = useLoad<SourceView>('productHubSource', { id }, id);
  return <Loaded load={load} reload={reload}>{(d) => <SourceDetail data={d} />}</Loaded>;
}

/** One source: its sections as stored (plain text, never HTML), versions and links. */
export function SourceDetail({ data }: { data: SourceView }) {
  const intl = useIntl();
  const navigate = useNavigate();
  const s = data.source;
  return (
    <div className="grid gap-4 [&>*]:min-w-0">
      <div className="flex flex-wrap items-center gap-3">
        <Button kind="ghost" onClick={() => navigate('product', 'sources')}>
          <ArrowLeft className="size-4" />
          <FormattedMessage id="ph.sources.back" />
        </Button>
        <h2 className="text-lg font-semibold">{s.title}</h2>
        <AuthorityPill authority={s.authority} />
      </div>
      <Meta>
        <PathText path={s.path} /> ·{' '}
        <FormattedMessage
          id="ph.sources.meta"
          values={{
            rev: shortRev(s.commit),
            date: s.syncedAt ? shortDate(intl, s.syncedAt) : '—',
            n: data.chunks.length,
          }}
        />
      </Meta>
      {s.status !== 'active' && (
        <Notice tone="warn">
          <FormattedMessage id={`ph.sources.status.${s.status}`} />
        </Notice>
      )}
      <div className="grid items-start gap-4 xl:grid-cols-[minmax(0,1fr)_280px]">
        <div className="grid gap-3">
          {data.chunks.map((c) => (
            <Section key={c.id} title={c.headingPath.join(' › ') || s.title}>
              <pre className="font-sans text-sm leading-6 whitespace-pre-wrap">{c.text}</pre>
            </Section>
          ))}
        </div>
        <div className="grid gap-4 [&>*]:min-w-0">
          <Section title={<FormattedMessage id="ph.col.features" />}>
            {s.features.length ? (
              <ul className="grid gap-1">
                {s.features.map((f) => (
                  <li key={f}>
                    <button type="button" className={`${linkClass} font-mono text-[12.5px]`} onClick={() => navigate('product', `features/${f}`)}>
                      {f}
                    </button>
                  </li>
                ))}
              </ul>
            ) : (
              <Meta>
                <FormattedMessage id="ph.none" />
              </Meta>
            )}
          </Section>
          <Section title={<FormattedMessage id="ph.sources.versions" />}>
            <ul className="grid gap-1 text-[13px]">
              {data.versions.map((v) => (
                <li key={v.contentHash}>
                  <span className="font-mono">{shortRev(v.commit)}</span> · {v.syncedAt ? shortDate(intl, v.syncedAt) : '—'}
                </li>
              ))}
            </ul>
          </Section>
        </div>
      </div>
    </div>
  );
}

function ReviewLoader() {
  const [load, reload] = useLoad<ChangeSetsView>('productHubChangeSets', {}, 'changeSets');
  return <Loaded load={load} reload={reload}>{(d) => <ReviewQueue data={d} />}</Loaded>;
}

const statusTone: Record<string, 'wait' | 'ok' | 'muted' | 'warn' | 'info'> = {
  pending: 'wait',
  applying: 'info',
  approved: 'ok',
  rejected: 'muted',
  superseded: 'muted',
};

/** Chờ duyệt: change sets from the sync, newest first (doc 06 §2.8). */
export function ReviewQueue({ data }: { data: ChangeSetsView }) {
  const intl = useIntl();
  const navigate = useNavigate();
  if (data.changeSets.length === 0) {
    return (
      <Section title={<FormattedMessage id="ph.sources.review" />}>
        <EmptyState icon={Inbox} title={<FormattedMessage id="ph.review.emptyTitle" />}>
          <FormattedMessage id="ph.review.emptyBody" />
        </EmptyState>
      </Section>
    );
  }
  return (
    <Section title={<FormattedMessage id="ph.sources.review" />} flush>
      <TableScroll min={680}>
        <table className="table">
          <thead>
            <tr>
              <th>
                <FormattedMessage id="ph.col.revision" />
              </th>
              <th>
                <FormattedMessage id="ph.col.status" />
              </th>
              <th>
                <FormattedMessage id="ph.col.changes" />
              </th>
              <th>
                <FormattedMessage id="ph.col.submitted" />
              </th>
            </tr>
          </thead>
          <tbody>
            {data.changeSets.map((c) => (
              <tr key={c.id}>
                <td>
                  <button type="button" className={`${linkClass} font-mono text-[12.5px]`} onClick={() => navigate('product', `sources/review/${c.id}`)}>
                    {shortRev(c.revision)}
                  </button>
                </td>
                <td>
                  <Pill tone={statusTone[c.status] ?? 'muted'}>
                    <FormattedMessage id={`ph.changeSet.status.${c.status}`} />
                  </Pill>
                </td>
                <td className="text-[13px]">
                  <FormattedMessage id="ph.changeSet.counts" values={{ ...c.summary }} />
                </td>
                <td className="text-[13px] text-muted-foreground">
                  {c.createdBy} · {c.createdAt ? shortDate(intl, c.createdAt) : '—'}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </TableScroll>
    </Section>
  );
}

export function ChangeSetLoader({ id }: { id: string }) {
  const [load, reload] = useLoad<ChangeSetView>('productHubChangeSet', { id }, id);
  return <Loaded load={load} reload={reload}>{(d) => <ChangeSetDetail data={d} onReviewed={reload} />}</Loaded>;
}

/**
 * One change set: what each source gains or loses, decisions, features and conflicts. Approve
 * needs Duyệt and is never the submitter's (except the Owner, D-155 #3).
 */
export function ChangeSetDetail({ data, onReviewed = () => undefined }: { data: ChangeSetView; onReviewed?: () => void }) {
  const intl = useIntl();
  const api = useApi();
  const navigate = useNavigate();
  const staff = useStaff();
  const [busy, setBusy] = useState(false);
  const canApprove = staffCan(staff.levels, 'product.approve');
  const own = data.createdByUid === staff.uid && !staff.roles.includes('owner');
  const review = async (decision: 'approve' | 'reject') => {
    setBusy(true);
    try {
      await api.call('productHubReviewChangeSet', { id: data.id, decision, reason: '' });
      toast.success(intl.formatMessage({ id: decision === 'approve' ? 'ph.review.approved' : 'ph.review.rejected' }));
      onReviewed();
    } catch (e) {
      toast.error(intl.formatMessage({ id: productErrorId(e) }));
    } finally {
      setBusy(false);
    }
  };
  const byChange = (c: string) => data.sources.filter((s) => s.change === c);
  return (
    <div className="grid gap-4 [&>*]:min-w-0">
      <div className="flex flex-wrap items-center gap-3">
        <Button kind="ghost" onClick={() => navigate('product', 'sources')}>
          <ArrowLeft className="size-4" />
          <FormattedMessage id="ph.sources.back" />
        </Button>
        <h2 className="font-mono text-lg font-semibold">{shortRev(data.revision)}</h2>
        <Pill tone={statusTone[data.status] ?? 'muted'}>
          <FormattedMessage id={`ph.changeSet.status.${data.status}`} />
        </Pill>
        {data.status === 'pending' && canApprove && (
          <div className="ml-auto flex gap-2">
            <Button kind="ghost" disabled={busy || own} onClick={() => review('reject')}>
              <FormattedMessage id="ph.review.reject" />
            </Button>
            <Button kind="primary" disabled={busy || own} onClick={() => review('approve')}>
              <FormattedMessage id="ph.review.approve" />
            </Button>
          </div>
        )}
      </div>
      <Meta>
        <FormattedMessage id="ph.changeSet.counts" values={{ ...data.summary }} /> ·{' '}
        <FormattedMessage id="ph.review.by" values={{ by: data.createdBy, date: data.createdAt ? shortDate(intl, data.createdAt) : '—' }} />
      </Meta>
      {data.status === 'pending' && own && (
        <Notice tone="info">
          <FormattedMessage id="ph.error.own-work" />
        </Notice>
      )}
      {data.summary.warnings.length > 0 && (
        <Notice tone="warn" title={<FormattedMessage id="ph.review.warnings" values={{ n: data.summary.warnings.length }} />}>
          <ul className="grid list-disc gap-0.5 pl-4">
            {data.summary.warnings.slice(0, 20).map((w) => (
              <li key={w}>{w}</li>
            ))}
          </ul>
        </Notice>
      )}

      {(['changed', 'moved', 'deleted', 'added'] as const).map((c) =>
        byChange(c).length ? (
          <Section
            key={c}
            title={<FormattedMessage id={`ph.review.sources.${c}`} values={{ n: byChange(c).length }} />}
            collapsible
            defaultOpen={c !== 'added'}
          >
            <ul className="grid gap-3">
              {byChange(c).map((s) => (
                <li key={s.id} className="grid gap-2">
                  <div className="flex flex-wrap items-center gap-2 text-sm">
                    <AuthorityPill authority={s.authority} />
                    <PathText path={s.path} />
                    {s.beforePath && s.beforePath !== s.path && (
                      <span className="text-xs text-muted-foreground">
                        <FormattedMessage id="ph.review.movedFrom" values={{ path: s.beforePath }} />
                      </span>
                    )}
                  </div>
                  {s.diff.map((d) => (
                    <div key={d.heading} className="grid gap-1 rounded-lg border p-2 text-[13px]">
                      <span className="font-medium">
                        <FormattedMessage id={`ph.review.diff.${d.change}`} /> · {d.heading}
                      </span>
                      <div className="grid gap-2 md:grid-cols-2">
                        {d.change !== 'added' && (
                          <pre className="rounded bg-destructive/5 p-2 font-sans whitespace-pre-wrap">{d.before}</pre>
                        )}
                        {d.change !== 'removed' && (
                          <pre className="rounded bg-primary/5 p-2 font-sans whitespace-pre-wrap">{d.after}</pre>
                        )}
                      </div>
                    </div>
                  ))}
                </li>
              ))}
            </ul>
          </Section>
        ) : null,
      )}

      {data.conflicts.length > 0 && (
        <Section title={<FormattedMessage id="ph.review.conflicts" values={{ n: data.conflicts.length }} />}>
          <ul className="grid gap-2 text-sm">
            {data.conflicts.map((c) => (
              <li key={c.id}><ConflictText conflict={c} /></li>
            ))}
          </ul>
        </Section>
      )}
      {data.features.length > 0 && (
        <Section title={<FormattedMessage id="ph.review.features" values={{ n: data.features.length }} />} collapsible defaultOpen={false}>
          <ul className="grid gap-1 text-[13px]">
            {data.features.map((f) => (
              <li key={f.id}>
                <FormattedMessage id={`ph.review.change.${f.change}`} /> · <span className="font-mono">{f.id}</span>
                {f.deadGlobs.length > 0 && <span className="text-warning"> · {f.deadGlobs.join(', ')}</span>}
              </li>
            ))}
          </ul>
        </Section>
      )}
      {data.decisions.length > 0 && (
        <Section title={<FormattedMessage id="ph.review.decisions" values={{ n: data.decisions.length }} />} collapsible defaultOpen={false}>
          <ul className="grid gap-1 text-[13px]">
            {data.decisions.slice(0, 600).map((d) => (
              <li key={d.id}>
                <FormattedMessage id={`ph.review.change.${d.change}`} /> · <span className="font-mono font-semibold">{d.id}</span> {d.title}
              </li>
            ))}
          </ul>
        </Section>
      )}
    </div>
  );
}
