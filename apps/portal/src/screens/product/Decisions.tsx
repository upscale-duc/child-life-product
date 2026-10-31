import {
  decisionKinds,
  opportunityEfforts,
  opportunityLevels,
  opportunityPriorities,
  opportunityStatuses,
  type OpportunityStatus,
  type ProductOpportunity,
} from '@child-life/contracts';
import { ArrowLeft, Inbox, Lightbulb, Plus } from 'lucide-react';
import { useMemo, useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { toast } from 'sonner';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { useApi, useLoad } from '../../api';
import { EmptyState, FilterBar, Notice, SearchInput, Section } from '../../content-kit';
import { useNavigate, useStaff } from '../../context';
import { shortDate } from '../../format';
import { Button, Loaded, Modal, Pill, Segmented, SelectMenu, TableScroll, type PillTone } from '../../ui';
import { productErrorId } from './Feature';
import { AuthorityPill, ConflictText, Meta, PathText, linkClass, shortRev } from './kit';
import type { ConflictsView, DecisionDetailView, DecisionsView, DraftsView, OpportunitiesView } from './types';

/**
 * Sản phẩm › Quyết định (D-155, Phase 3): the D/R/P/Q/G registry as it stands in the business
 * map, the opportunities being worked on, the conflicts between sources and the drafts saved from
 * Copilot. Decisions themselves are made in the business map; nothing here approves one.
 */
export const decisionsParts = ['decisions', 'opportunities', 'conflicts', 'drafts'] as const;
export type DecisionsPart = (typeof decisionsParts)[number];

export function DecisionsScreen({ part, decision }: { part: DecisionsPart; decision: string | null }) {
  const intl = useIntl();
  const navigate = useNavigate();
  return (
    <div className="grid gap-4 [&>*]:min-w-0">
      <Segmented<DecisionsPart>
        label={intl.formatMessage({ id: 'ph.decisions.parts' })}
        value={part}
        onChange={(p) => navigate('product', p === 'decisions' ? 'decisions' : `decisions/${p}`)}
        options={decisionsParts.map((p) => ({ value: p, label: intl.formatMessage({ id: `ph.decisions.part.${p}` }) }))}
      />
      {part === 'decisions' && (decision ? <DecisionLoader id={decision} /> : <DecisionsLoader />)}
      {part === 'opportunities' && <OpportunitiesLoader />}
      {part === 'conflicts' && <ConflictsLoader />}
      {part === 'drafts' && <DraftsLoader />}
    </div>
  );
}

// ---------- Decisions ----------

const decisionTone: Record<string, PillTone> = { approved: 'ok', superseded: 'warn', open: 'wait', resolved: 'muted', recorded: 'muted' };

function DecisionsLoader() {
  const [load, reload] = useLoad<DecisionsView>('productHubDecisions', {}, 'decisions');
  return <Loaded load={load} reload={reload}>{(d) => <DecisionsView data={d} />}</Loaded>;
}

export function DecisionsView({ data }: { data: DecisionsView }) {
  const intl = useIntl();
  const navigate = useNavigate();
  const [kind, setKind] = useState<string>('all');
  const [status, setStatus] = useState<string>('all');
  const [q, setQ] = useState('');
  const shown = useMemo(() => {
    const needle = q.trim().toLowerCase();
    return data.decisions.filter(
      (d) =>
        (kind === 'all' || d.kind === kind) &&
        (status === 'all' || d.status === status) &&
        (!needle || d.id.toLowerCase() === needle || `${d.title} ${d.excerpt}`.toLowerCase().includes(needle)),
    );
  }, [data.decisions, kind, status, q]);
  const open = Object.entries(data.openByFeature).sort(([a], [b]) => (a === '—' ? 1 : b === '—' ? -1 : a.localeCompare(b)));
  const link = (id: string) => (
    <button key={id} type="button" className={`${linkClass} font-mono text-[12px]`} onClick={() => navigate('product', `decisions/${id}`)}>
      {id}
    </button>
  );
  return (
    <div className="grid items-start gap-4 xl:grid-cols-[minmax(0,1fr)_300px] [&>*]:min-w-0">
      <Section title={<FormattedMessage id="ph.decisions.title" />} hint={<FormattedMessage id="ph.decisions.hint" />} flush>
        <FilterBar
          active={kind !== 'all' || status !== 'all' || q !== ''}
          onClear={() => {
            setKind('all');
            setStatus('all');
            setQ('');
          }}
          shown={shown.length}
          total={data.decisions.length}
        >
          <SearchInput value={q} onChange={setQ} placeholder={intl.formatMessage({ id: 'ph.decisions.search' })} />
          <SelectMenu
            label={intl.formatMessage({ id: 'ph.decisions.kind' })}
            value={kind}
            onChange={setKind}
            options={[
              { value: 'all', label: `${intl.formatMessage({ id: 'ph.decisions.kind' })}: ${intl.formatMessage({ id: 'ph.filter.all' })}` },
              ...decisionKinds.map((k) => ({ value: k, label: intl.formatMessage({ id: `ph.decisionKind.${k}` }) })),
            ]}
          />
          <SelectMenu
            label={intl.formatMessage({ id: 'ph.col.status' })}
            value={status}
            onChange={setStatus}
            options={[
              { value: 'all', label: `${intl.formatMessage({ id: 'ph.col.status' })}: ${intl.formatMessage({ id: 'ph.filter.all' })}` },
              ...['approved', 'superseded', 'open', 'resolved', 'recorded'].map((s) => ({ value: s, label: intl.formatMessage({ id: `ph.decision.status.${s}` }) })),
            ]}
          />
        </FilterBar>
        <TableScroll min={720}>
          <table className="table">
            <thead>
              <tr>
                <th className="w-20">Id</th>
                <th>
                  <FormattedMessage id="ph.decisions.col.title" />
                </th>
                <th>
                  <FormattedMessage id="ph.col.status" />
                </th>
                <th>
                  <FormattedMessage id="ph.decisions.col.links" />
                </th>
              </tr>
            </thead>
            <tbody>
              {shown.slice(0, 300).map((d) => (
                <tr key={d.id}>
                  <td>{link(d.id)}</td>
                  <td>
                    <span className="font-medium">{d.title}</span>
                    {d.date && <div className="text-xs text-muted-foreground">{shortDate(intl, d.date)}</div>}
                  </td>
                  <td>
                    <Pill tone={decisionTone[d.status] ?? 'muted'}>
                      <FormattedMessage id={`ph.decision.status.${d.status}`} />
                    </Pill>
                  </td>
                  <td className="text-[12px]">
                    <Chain label="ph.decisions.supersededBy" ids={d.supersededBy} link={link} />
                    <Chain label="ph.decisions.supersedes" ids={d.supersedes} link={link} />
                    <Chain label="ph.decisions.resolves" ids={d.resolves} link={link} />
                    <Chain label="ph.decisions.resolvedBy" ids={d.resolvedBy} link={link} />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </TableScroll>
        {shown.length > 300 && (
          <div className="px-4 py-3">
            <Meta>
              <FormattedMessage id="ph.decisions.more" values={{ n: shown.length - 300 }} />
            </Meta>
          </div>
        )}
      </Section>
      <Section title={<FormattedMessage id="ph.decisions.openByFeature" />} hint={<FormattedMessage id="ph.decisions.openHint" />}>
        {open.length === 0 ? (
          <Meta>
            <FormattedMessage id="ph.none" />
          </Meta>
        ) : (
          <ul className="grid gap-2 text-[13px]">
            {open.map(([f, ids]) => (
              <li key={f} className="grid gap-0.5">
                {f === '—' ? (
                  <span className="text-muted-foreground">
                    <FormattedMessage id="ph.decisions.noFeature" />
                  </span>
                ) : (
                  <button type="button" className={`${linkClass} justify-self-start font-mono`} onClick={() => navigate('product', `features/${f}`)}>
                    {f}
                  </button>
                )}
                <span className="flex flex-wrap gap-1.5">{ids.slice(0, 40).map(link)}</span>
              </li>
            ))}
          </ul>
        )}
      </Section>
    </div>
  );
}

function Chain({ label, ids, link }: { label: string; ids: string[]; link: (id: string) => ReactNode }) {
  if (!ids.length) return null;
  return (
    <div className="flex flex-wrap items-center gap-1">
      <span className="text-muted-foreground">
        <FormattedMessage id={label} />
      </span>
      {ids.map(link)}
    </div>
  );
}

function DecisionLoader({ id }: { id: string }) {
  const [load, reload] = useLoad<DecisionDetailView>('productHubDecision', { id }, id);
  return <Loaded load={load} reload={reload}>{(d) => <DecisionDetail data={d} />}</Loaded>;
}

export function DecisionDetail({ data }: { data: DecisionDetailView }) {
  const intl = useIntl();
  const navigate = useNavigate();
  const d = data.decision;
  const link = (x: string) => (
    <button key={x} type="button" className={`${linkClass} font-mono text-[12.5px]`} onClick={() => navigate('product', `decisions/${x}`)}>
      {x}
    </button>
  );
  return (
    <div className="grid gap-4 [&>*]:min-w-0">
      <div className="flex flex-wrap items-center gap-3">
        <Button kind="ghost" onClick={() => navigate('product', 'decisions')}>
          <ArrowLeft className="size-4" />
          <FormattedMessage id="ph.decisions.back" />
        </Button>
        <h2 className="font-mono text-lg font-semibold">{d.id}</h2>
        <Pill tone={decisionTone[d.status] ?? 'muted'}>
          <FormattedMessage id={`ph.decision.status.${d.status}`} />
        </Pill>
        <span className="text-sm text-muted-foreground">
          <FormattedMessage id={`ph.decisionKind.${d.kind}`} />
          {d.date ? ` · ${shortDate(intl, d.date)}` : ''}
        </span>
      </div>
      {data.supersededBy.length > 0 && (
        <Notice tone="warn">
          <FormattedMessage id="ph.decisions.supersededNotice" values={{ ids: data.supersededBy.join(', ') }} />
        </Notice>
      )}
      <Section title={d.title}>
        <p className="text-sm leading-6 whitespace-pre-wrap">{d.text}</p>
        <Meta>
          <PathText path={`${d.source.path}:${d.source.line}`} /> · {shortRev(d.source.commit)}
        </Meta>
      </Section>
      <div className="grid gap-4 md:grid-cols-2 [&>*]:min-w-0">
        <Section title={<FormattedMessage id="ph.decisions.links" />}>
          <div className="grid gap-1 text-[13px]">
            <Chain label="ph.decisions.supersededBy" ids={data.supersededBy} link={link} />
            <Chain label="ph.decisions.supersedes" ids={d.supersedes} link={link} />
            <Chain label="ph.decisions.resolves" ids={d.resolves} link={link} />
            <Chain label="ph.decisions.resolvedBy" ids={data.resolvedBy} link={link} />
            {!data.supersededBy.length && !d.supersedes.length && !d.resolves.length && !data.resolvedBy.length && (
              <Meta>
                <FormattedMessage id="ph.none" />
              </Meta>
            )}
          </div>
        </Section>
        <Section title={<FormattedMessage id="ph.col.features" />}>
          {d.features.length ? (
            <span className="flex flex-wrap gap-2">
              {d.features.map((f) => (
                <button key={f} type="button" className={`${linkClass} font-mono text-[12.5px]`} onClick={() => navigate('product', `features/${f}`)}>
                  {f}
                </button>
              ))}
            </span>
          ) : (
            <Meta>
              <FormattedMessage id="ph.decisions.noFeature" />
            </Meta>
          )}
          {data.opportunities.length > 0 && (
            <ul className="mt-3 grid gap-1 text-[13px]">
              {data.opportunities.map((o) => (
                <li key={o.id}>
                  <FormattedMessage id={`ph.opp.status.${o.status}`} /> · {o.title}
                </li>
              ))}
            </ul>
          )}
        </Section>
      </div>
    </div>
  );
}

// ---------- Opportunities ----------

const oppTone: Record<OpportunityStatus, PillTone> = { proposed: 'muted', triaged: 'wait', accepted: 'ok', declined: 'muted', done: 'info' };
const nextStatuses: Record<OpportunityStatus, OpportunityStatus[]> = {
  proposed: ['triaged', 'declined'],
  triaged: ['accepted', 'declined', 'proposed'],
  accepted: ['done', 'triaged'],
  declined: ['proposed'],
  done: [],
};

function OpportunitiesLoader() {
  const [load, reload] = useLoad<OpportunitiesView>('productHubOpportunities', {}, 'opportunities');
  return <Loaded load={load} reload={reload}>{(d) => <OpportunitiesView data={d} onChanged={reload} />}</Loaded>;
}

export function OpportunitiesView({ data, onChanged = () => undefined }: { data: OpportunitiesView; onChanged?: () => void }) {
  const intl = useIntl();
  const api = useApi();
  const staff = useStaff();
  const navigate = useNavigate();
  const [status, setStatus] = useState<OpportunityStatus | 'all' | 'active'>('active');
  const [editing, setEditing] = useState<ProductOpportunity | 'new' | null>(null);
  const shown = data.opportunities.filter((o) =>
    status === 'all' ? true : status === 'active' ? ['proposed', 'triaged', 'accepted'].includes(o.status) : o.status === status,
  );
  const move = async (o: ProductOpportunity, to: OpportunityStatus) => {
    try {
      await api.call('productHubOpportunityStatus', { id: o.id, status: to, note: '' });
      toast.success(intl.formatMessage({ id: 'ph.opp.moved' }, { status: intl.formatMessage({ id: `ph.opp.status.${to}` }) }));
      onChanged();
    } catch (e) {
      toast.error(intl.formatMessage({ id: productErrorId(e) }));
    }
  };
  const canMove = (o: ProductOpportunity, to: OpportunityStatus) =>
    to === 'accepted' || to === 'declined'
      ? data.canApprove && (o.createdByUid !== staff.uid || staff.roles.includes('owner'))
      : data.canEdit;
  return (
    <Section
      title={<FormattedMessage id="ph.decisions.part.opportunities" />}
      hint={<FormattedMessage id="ph.opp.hint" />}
      actions={
        data.canEdit ? (
          <Button kind="primary" onClick={() => setEditing('new')}>
            <Plus className="size-4" />
            <FormattedMessage id="ph.opp.new" />
          </Button>
        ) : null
      }
    >
      <div className="grid gap-3">
        <SelectMenu
          label={intl.formatMessage({ id: 'ph.col.status' })}
          value={status}
          onChange={setStatus}
          options={[
            { value: 'active', label: intl.formatMessage({ id: 'ph.opp.filter.active' }) },
            { value: 'all', label: intl.formatMessage({ id: 'ph.filter.all' }) },
            ...opportunityStatuses.map((s) => ({ value: s, label: intl.formatMessage({ id: `ph.opp.status.${s}` }) })),
          ]}
          className="w-56"
        />
        {shown.length === 0 ? (
          <EmptyState icon={Lightbulb} title={<FormattedMessage id="ph.opp.emptyTitle" />}>
            <FormattedMessage id="ph.opp.emptyBody" />
          </EmptyState>
        ) : (
          <ul className="grid gap-3">
            {shown.map((o) => (
              <li key={o.id} className="grid gap-2 rounded-xl border p-3">
                <div className="flex flex-wrap items-center gap-2">
                  <Pill tone={oppTone[o.status]}>
                    <FormattedMessage id={`ph.opp.status.${o.status}`} />
                  </Pill>
                  <span className="font-medium">{o.title}</span>
                  <span className="text-xs text-muted-foreground">
                    <FormattedMessage id="ph.opp.meta" values={{ impact: intl.formatMessage({ id: `ph.opp.level.${o.impact}` }), effort: o.effort.toUpperCase(), priority: o.priority.toUpperCase() }} />
                  </span>
                  {o.feature && (
                    <button type="button" className={`${linkClass} font-mono text-[12px]`} onClick={() => navigate('product', `features/${o.feature}`)}>
                      {o.feature}
                    </button>
                  )}
                </div>
                <p className="text-[13.5px] whitespace-pre-wrap">{o.problem}</p>
                {o.hypothesis && (
                  <p className="text-[13px] text-muted-foreground">
                    <FormattedMessage id="ph.opp.hypothesisLabel" /> {o.hypothesis}
                  </p>
                )}
                {o.evidence.length > 0 && (
                  <div className="flex flex-wrap gap-1.5">
                    {o.evidence.map((e) => (
                      <code key={e} className="rounded bg-muted px-1.5 py-0.5 font-mono text-[11.5px] break-all">
                        {e}
                      </code>
                    ))}
                  </div>
                )}
                <div className="flex flex-wrap items-center gap-2">
                  {nextStatuses[o.status]
                    .filter((to) => canMove(o, to))
                    .map((to) => (
                      <Button key={to} kind={to === 'accepted' ? 'primary' : 'ghost'} onClick={() => void move(o, to)}>
                        <FormattedMessage id={`ph.opp.to.${to}`} />
                      </Button>
                    ))}
                  {data.canEdit && ['proposed', 'triaged'].includes(o.status) && (
                    <Button kind="ghost" onClick={() => setEditing(o)}>
                      <FormattedMessage id="ph.section.edit" />
                    </Button>
                  )}
                  <span className="ml-auto text-xs text-muted-foreground">
                    {o.createdBy}
                    {o.updatedAt ? ` · ${shortDate(intl, o.updatedAt)}` : ''}
                  </span>
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>
      {editing && <OpportunityForm initial={editing === 'new' ? null : editing} onClose={() => setEditing(null)} onSaved={() => { setEditing(null); onChanged(); }} />}
    </Section>
  );
}

function OpportunityForm({ initial, onClose, onSaved }: { initial: ProductOpportunity | null; onClose: () => void; onSaved: () => void }) {
  const intl = useIntl();
  const api = useApi();
  const [f, setF] = useState({
    title: initial?.title ?? '',
    feature: initial?.feature ?? '',
    problem: initial?.problem ?? '',
    hypothesis: initial?.hypothesis ?? '',
    proposal: initial?.proposal ?? '',
    successCriteria: initial?.successCriteria ?? '',
    evidence: (initial?.evidence ?? []).join('\n'),
    impact: initial?.impact ?? 'medium',
    effort: initial?.effort ?? 'm',
    priority: initial?.priority ?? 'p2',
  });
  const [busy, setBusy] = useState(false);
  const set = (k: keyof typeof f) => (v: string) => setF((x) => ({ ...x, [k]: v }));
  const save = async () => {
    setBusy(true);
    try {
      const evidence = f.evidence.split('\n').map((x) => x.trim()).filter((x) => x.length >= 3);
      await api.call('productHubSaveOpportunity', {
        ...(initial ? { id: initial.id } : {}),
        title: f.title,
        feature: f.feature.trim() || null,
        problem: f.problem,
        hypothesis: f.hypothesis,
        proposal: f.proposal,
        successCriteria: f.successCriteria,
        evidence,
        decisions: evidence.filter((x) => /^D-\d{3}$/.test(x)),
        impact: f.impact,
        effort: f.effort,
        priority: f.priority,
      });
      toast.success(intl.formatMessage({ id: 'ph.opp.saved' }));
      onSaved();
    } catch (e) {
      toast.error(intl.formatMessage({ id: productErrorId(e) }));
    } finally {
      setBusy(false);
    }
  };
  const field = (k: keyof typeof f, label: string, rows = 0) => (
    <label className="grid gap-1 text-sm font-medium">
      <FormattedMessage id={label} />
      {rows ? <Textarea rows={rows} value={f[k]} onChange={(e) => set(k)(e.target.value)} /> : <Input value={f[k]} onChange={(e) => set(k)(e.target.value)} />}
    </label>
  );
  return (
    <Modal title={<FormattedMessage id={initial ? 'ph.opp.edit' : 'ph.opp.new'} />} onClose={onClose} wide>
      <form
        className="grid gap-3"
        onSubmit={(e) => {
          e.preventDefault();
          void save();
        }}
      >
        {field('title', 'ph.opp.f.title')}
        {field('feature', 'ph.opp.f.feature')}
        {field('problem', 'ph.opp.f.problem', 3)}
        {field('hypothesis', 'ph.opp.f.hypothesis', 2)}
        {field('proposal', 'ph.opp.f.proposal', 2)}
        {field('successCriteria', 'ph.opp.f.success', 2)}
        {field('evidence', 'ph.opp.f.evidence', 2)}
        <div className="flex flex-wrap gap-3">
          <SelectMenu label={intl.formatMessage({ id: 'ph.opp.f.impact' })} value={f.impact} onChange={set('impact')} options={opportunityLevels.map((x) => ({ value: x, label: `${intl.formatMessage({ id: 'ph.opp.f.impact' })}: ${intl.formatMessage({ id: `ph.opp.level.${x}` })}` }))} />
          <SelectMenu label={intl.formatMessage({ id: 'ph.opp.f.effort' })} value={f.effort} onChange={set('effort')} options={opportunityEfforts.map((x) => ({ value: x, label: `${intl.formatMessage({ id: 'ph.opp.f.effort' })}: ${x.toUpperCase()}` }))} />
          <SelectMenu label={intl.formatMessage({ id: 'ph.opp.f.priority' })} value={f.priority} onChange={set('priority')} options={opportunityPriorities.map((x) => ({ value: x, label: `${intl.formatMessage({ id: 'ph.opp.f.priority' })}: ${x.toUpperCase()}` }))} />
        </div>
        <div className="flex justify-end gap-2">
          <Button kind="ghost" onClick={onClose}>
            <FormattedMessage id="action.cancel" />
          </Button>
          <Button kind="primary" type="submit" disabled={busy || f.title.trim().length < 3 || !f.problem.trim()}>
            <FormattedMessage id="ph.opp.save" />
          </Button>
        </div>
      </form>
    </Modal>
  );
}

// ---------- Conflicts ----------

const conflictTone: Record<string, PillTone> = { suggested: 'info', open: 'warn', resolved: 'ok', accepted_difference: 'muted', dismissed: 'muted' };

function ConflictsLoader() {
  const [load, reload] = useLoad<ConflictsView>('productHubConflicts', { status: 'all' }, 'conflicts');
  return <Loaded load={load} reload={reload}>{(d) => <ConflictsView data={d} onChanged={reload} />}</Loaded>;
}

export function ConflictsView({ data, onChanged = () => undefined }: { data: ConflictsView; onChanged?: () => void }) {
  const intl = useIntl();
  const api = useApi();
  const navigate = useNavigate();
  const [status, setStatus] = useState<string>('active');
  const [closing, setClosing] = useState<{ id: string; action: 'resolve' | 'accept_difference' } | null>(null);
  const shown = data.conflicts.filter((c) => (status === 'all' ? true : status === 'active' ? c.status === 'open' || c.status === 'suggested' : c.status === status));
  const act = async (id: string, action: string, note = '', decision: string | null = null) => {
    try {
      await api.call('productHubConflictAct', { id, action, note, decision });
      toast.success(intl.formatMessage({ id: `ph.conflict.done.${action}` }));
      setClosing(null);
      onChanged();
    } catch (e) {
      toast.error(intl.formatMessage({ id: productErrorId(e) }));
    }
  };
  return (
    <Section title={<FormattedMessage id="ph.decisions.part.conflicts" />} hint={<FormattedMessage id="ph.conflict.hint" />}>
      <div className="grid gap-3">
        <SelectMenu
          label={intl.formatMessage({ id: 'ph.col.status' })}
          value={status}
          onChange={setStatus}
          className="w-56"
          options={[
            { value: 'active', label: intl.formatMessage({ id: 'ph.conflict.filter.active' }) },
            { value: 'all', label: intl.formatMessage({ id: 'ph.filter.all' }) },
            ...['suggested', 'open', 'resolved', 'accepted_difference', 'dismissed'].map((s) => ({ value: s, label: intl.formatMessage({ id: `ph.conflict.status.${s}` }) })),
          ]}
        />
        {shown.length === 0 ? (
          <EmptyState icon={Inbox} title={<FormattedMessage id="ph.conflict.emptyTitle" />} />
        ) : (
          <ul className="grid gap-3">
            {shown.map((c) => (
              <li key={c.id} className="grid gap-2 rounded-xl border p-3">
                <div className="flex flex-wrap items-center gap-2">
                  <Pill tone={conflictTone[c.status] ?? 'muted'}>
                    <FormattedMessage id={`ph.conflict.status.${c.status}`} />
                  </Pill>
                  {c.topic === 'ai_suggested' && (
                    <Pill tone="info">
                      <FormattedMessage id="ph.conflict.byClaude" />
                    </Pill>
                  )}
                  <span className="min-w-0 flex-1 text-sm">
                    <ConflictText conflict={c} />
                  </span>
                  {c.feature && (
                    <button type="button" className={`${linkClass} font-mono text-[12px]`} onClick={() => navigate('product', `features/${c.feature}`)}>
                      {c.feature}
                    </button>
                  )}
                </div>
                {c.claims.map((cl, i) => (
                  <div key={i} className="grid gap-1 border-l-2 pl-3 text-[13px]">
                    <div className="flex flex-wrap items-center gap-2">
                      <AuthorityPill authority={cl.authority} />
                      <PathText path={cl.anchor ? `${cl.path}#${cl.anchor}` : cl.path} />
                      {cl.date && <span className="text-muted-foreground">{shortDate(intl, cl.date)}</span>}
                    </div>
                    <q className="text-muted-foreground [overflow-wrap:anywhere]">{cl.text}</q>
                  </div>
                ))}
                {c.resolution && (
                  <Meta>
                    <FormattedMessage
                      id="ph.conflict.resolution"
                      values={{ by: c.resolution.by, note: c.resolution.note || '—', decision: c.resolution.decision ?? '—' }}
                    />
                  </Meta>
                )}
                <div className="flex flex-wrap gap-2">
                  {c.status === 'suggested' && data.canEdit && (
                    <>
                      <Button onClick={() => void act(c.id, 'accept')}>
                        <FormattedMessage id="ph.conflict.accept" />
                      </Button>
                      <Button kind="ghost" onClick={() => void act(c.id, 'dismiss')}>
                        <FormattedMessage id="ph.conflict.dismiss" />
                      </Button>
                    </>
                  )}
                  {c.status === 'open' && data.canApprove && (
                    <>
                      <Button onClick={() => setClosing({ id: c.id, action: 'resolve' })}>
                        <FormattedMessage id="ph.conflict.resolve" />
                      </Button>
                      <Button kind="ghost" onClick={() => setClosing({ id: c.id, action: 'accept_difference' })}>
                        <FormattedMessage id="ph.conflict.acceptDifference" />
                      </Button>
                    </>
                  )}
                  {['resolved', 'accepted_difference', 'dismissed'].includes(c.status) && data.canApprove && (
                    <Button kind="ghost" onClick={() => void act(c.id, 'reopen')}>
                      <FormattedMessage id="ph.conflict.reopen" />
                    </Button>
                  )}
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>
      {closing && <CloseConflict action={closing.action} onClose={() => setClosing(null)} onSubmit={(note, decision) => void act(closing.id, closing.action, note, decision)} />}
    </Section>
  );
}

function CloseConflict({ action, onClose, onSubmit }: { action: 'resolve' | 'accept_difference'; onClose: () => void; onSubmit: (note: string, decision: string | null) => void }) {
  const [note, setNote] = useState('');
  const [decision, setDecision] = useState('');
  const valid = /^[DRPQG]-\d{3}$/.test(decision.trim());
  return (
    <Modal title={<FormattedMessage id={action === 'resolve' ? 'ph.conflict.resolve' : 'ph.conflict.acceptDifference'} />} onClose={onClose}>
      <form
        className="grid gap-3"
        onSubmit={(e) => {
          e.preventDefault();
          onSubmit(note.trim(), valid ? decision.trim() : null);
        }}
      >
        <p className="text-sm text-muted-foreground">
          <FormattedMessage id={`ph.conflict.${action}Body`} />
        </p>
        <label className="grid gap-1 text-sm font-medium">
          <FormattedMessage id="ph.conflict.note" />
          <Textarea rows={3} value={note} onChange={(e) => setNote(e.target.value)} />
        </label>
        <label className="grid gap-1 text-sm font-medium">
          <FormattedMessage id="ph.conflict.decision" />
          <Input value={decision} placeholder="D-157" onChange={(e) => setDecision(e.target.value)} />
        </label>
        <div className="flex justify-end gap-2">
          <Button kind="ghost" onClick={onClose}>
            <FormattedMessage id="action.cancel" />
          </Button>
          <Button kind="primary" type="submit" disabled={!note.trim() && !valid}>
            <FormattedMessage id="ph.conflict.confirm" />
          </Button>
        </div>
      </form>
    </Modal>
  );
}

// ---------- Drafts ----------

function DraftsLoader() {
  const [load, reload] = useLoad<DraftsView>('productHubDrafts', {}, 'drafts');
  return <Loaded load={load} reload={reload}>{(d) => <DraftsView data={d} onChanged={reload} />}</Loaded>;
}

export function DraftsView({ data, onChanged = () => undefined }: { data: DraftsView; onChanged?: () => void }) {
  const intl = useIntl();
  const api = useApi();
  const navigate = useNavigate();
  const act = async (id: string, action: 'promote' | 'dismiss') => {
    try {
      await api.call('productHubDraftAct', { id, action });
      toast.success(intl.formatMessage({ id: action === 'promote' ? 'ph.draft.promoted' : 'ph.draft.dismissed' }));
      onChanged();
      if (action === 'promote') navigate('product', 'decisions/opportunities');
    } catch (e) {
      toast.error(intl.formatMessage({ id: productErrorId(e) }));
    }
  };
  const pending = data.drafts.filter((d) => d.status === 'draft');
  return (
    <Section title={<FormattedMessage id="ph.decisions.part.drafts" />} hint={<FormattedMessage id="ph.copilot.draftsHint" />}>
      {pending.length === 0 ? (
        <EmptyState icon={Inbox} title={<FormattedMessage id="ph.draft.emptyTitle" />}>
          <FormattedMessage id="ph.draft.emptyBody" />
        </EmptyState>
      ) : (
        <ul className="grid gap-3">
          {pending.map((d) => (
            <li key={d.id} className="grid gap-2 rounded-xl border p-3">
              <div className="flex flex-wrap items-center gap-2">
                <Pill tone="muted">
                  <FormattedMessage id={`ph.draftType.${d.type}`} />
                </Pill>
                <span className="font-medium">{d.title}</span>
                <span className="text-xs text-muted-foreground">
                  {d.feature ?? '—'} · {d.createdBy}
                  {d.createdAt ? ` · ${shortDate(intl, d.createdAt)}` : ''}
                </span>
              </div>
              <p className="line-clamp-6 text-[13px] whitespace-pre-wrap">{d.body}</p>
              <div className="flex gap-2">
                <Button onClick={() => void act(d.id, 'promote')}>
                  <FormattedMessage id="ph.draft.promote" />
                </Button>
                <Button kind="ghost" onClick={() => void act(d.id, 'dismiss')}>
                  <FormattedMessage id="ph.draft.dismiss" />
                </Button>
              </div>
            </li>
          ))}
        </ul>
      )}
    </Section>
  );
}
