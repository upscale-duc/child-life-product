import { type FeatureSection, type FeatureSectionKey } from '@child-life/contracts';
import { ArrowLeft, MessageSquareText } from 'lucide-react';
import { useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { toast } from 'sonner';
import { Sheet, SheetContent, SheetTitle } from '@/components/ui/sheet';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Textarea } from '@/components/ui/textarea';
import { ApiError, useApi, useLoad } from '../../api';
import { Notice, Section } from '../../content-kit';
import { useNavigate } from '../../context';
import { shortDate } from '../../format';
import { Button, Loaded, Pill, errorMessageId } from '../../ui';
import {
  AuthorityPill,
  ConflictText,
  CoverageMeter,
  Meta,
  PathText,
  VerificationText,
  linkClass,
  shortRev,
  useLocalName,
} from './kit';
import type { FeatureView, SectionVersionsView } from './types';
import { Thread } from './Copilot';
import { InstrumentationPill } from './Insights';

/** Errors of the Sản phẩm callables that have their own words. */
export function productErrorId(e: unknown): string {
  if (!(e instanceof ApiError)) return 'error.generic';
  const own = [
    'own-work',
    'not-pending',
    'no-draft',
    'pending-exists',
    'no-changes',
    'copilot-limit-hour',
    'copilot-limit-day',
    'copilot-limit-global',
    'copilot-unconfigured',
    'copilot-invalid',
    'opportunity-closed',
    'bad-transition',
    'note-required',
  ];
  return e.reason && own.includes(e.reason) ? `ph.error.${e.reason}` : errorMessageId(e);
}

export const featureTabs = ['overview', 'experience', 'technical', 'measure', 'sources'] as const;
type FeatureTab = (typeof featureTabs)[number];
/** The brief's twelve sections, grouped into five tabs (doc 04 §2.3). */
const tabSections: Record<FeatureTab, FeatureSectionKey[]> = {
  overview: ['summary', 'problem', 'value'],
  experience: ['ux', 'rules', 'edgeCases'],
  technical: ['access'],
  measure: ['metrics', 'issues'],
  sources: ['decisions'],
};

export function FeatureLoader({ id }: { id: string }) {
  const [load, reload] = useLoad<FeatureView>('productHubFeature', { id }, id);
  return <Loaded load={load} reload={reload}>{(d) => <FeatureView data={d} onChanged={reload} />}</Loaded>;
}

export function FeatureView({ data, onChanged = () => undefined }: { data: FeatureView; onChanged?: () => void }) {
  const intl = useIntl();
  const navigate = useNavigate();
  const name = useLocalName();
  const f = data.feature;
  const [tab, setTab] = useState<FeatureTab>('overview');
  const [asking, setAsking] = useState(false);
  const section = (k: FeatureSectionKey) => data.sections.find((s) => s.key === k)!;
  const sections = (keys: FeatureSectionKey[]) =>
    keys.map((k) => (
      <SectionCard key={k} feature={f.id} section={section(k)} canEdit={data.canEdit} canApprove={data.canApprove} onChanged={onChanged} />
    ));

  return (
    <div className="grid gap-4 [&>*]:min-w-0">
      <div className="flex flex-wrap items-center gap-3">
        <Button kind="ghost" onClick={() => navigate('product', 'features')}>
          <ArrowLeft className="size-4" />
          <FormattedMessage id="ph.feature.back" />
        </Button>
        <h2 className="text-lg font-semibold">{name(f.name, f.id)}</h2>
        <span className="font-mono text-xs text-muted-foreground">{f.id}</span>
        <span className="ml-auto">
          <Button onClick={() => setAsking(true)}>
            <MessageSquareText className="size-4" />
            <FormattedMessage id="ph.copilot.askFeature" />
          </Button>
        </span>
      </div>
      {asking && typeof document !== 'undefined' && (
        <Sheet open onOpenChange={(o) => !o && setAsking(false)}>
          <SheetContent
            side="right"
            aria-describedby={undefined}
            closeLabel={intl.formatMessage({ id: 'action.close' })}
            className="w-full gap-0 overflow-y-auto overscroll-contain sm:max-w-2xl"
          >
            <SheetTitle className="border-b px-5 py-4 pr-12 text-base">
              <FormattedMessage id="ph.copilot.titleFeature" values={{ feature: f.id }} />
            </SheetTitle>
            <div className="p-4">
              <Thread scope={f.id} initial={[]} />
            </div>
          </SheetContent>
        </Sheet>
      )}

      {/* Four fields, never one status (doc 05 §3). */}
      <dl className="grid grid-cols-2 gap-3 rounded-xl border bg-card px-4 py-3 text-sm sm:grid-cols-4 xl:grid-cols-7">
        <Status label="ph.col.pillar" value={<FormattedMessage id={`ph.pillar.${f.pillar}`} />} />
        <Status label="ph.col.lifecycle" value={<FormattedMessage id={`ph.lifecycle.${f.lifecycle}`} />} />
        <Status label="ph.col.implementation" value={<FormattedMessage id={`ph.implementation.${f.implementation}`} />} />
        <Status label="ph.col.verification" value={<VerificationText value={f.verification} />} />
        <Status label="ph.col.release" value={<FormattedMessage id={`ph.release.${f.release}`} />} />
        <Status label="ph.col.tier" value={<FormattedMessage id={`ph.tier.${data.access.liveTier ?? data.access.defaultTier ?? 'none'}`} />} />
        <Status label="ph.col.coverage" value={<CoverageMeter score={data.coverage.score} />} />
      </dl>
      <Meta>
        <FormattedMessage
          id="ph.feature.synced"
          values={{
            rev: shortRev(f.revision),
            date: f.syncedAt ? shortDate(intl, f.syncedAt) : '—',
            platforms: f.platforms.map((p) => intl.formatMessage({ id: `ph.platform.${p}` })).join(' · '),
            confidence: intl.formatMessage({ id: `ph.confidence.${f.confidence}` }),
          }}
        />
      </Meta>
      {f.note && <Notice tone="info">{f.note}</Notice>}
      {data.conflicts.some((c) => c.status === 'open') && (
        <Notice tone="warn" title={<FormattedMessage id="ph.feature.conflictTitle" values={{ n: data.conflicts.filter((c) => c.status === 'open').length }} />}>
          <FormattedMessage id="ph.feature.conflictBody" />
        </Notice>
      )}
      {data.supersededCitations.length > 0 && (
        <Notice tone="warn">
          <FormattedMessage
            id="ph.feature.supersededCitations"
            values={{ ids: data.supersededCitations.map((c) => c.id).join(', ') }}
          />
        </Notice>
      )}

      <div className="grid items-start gap-4 xl:grid-cols-[minmax(0,1fr)_300px]">
        <Tabs value={tab} onValueChange={(t) => setTab(t as FeatureTab)} className="min-w-0 gap-4">
          <TabsList aria-label={intl.formatMessage({ id: 'ph.feature.tabs' })} className="max-w-full overflow-x-auto">
            {featureTabs.map((t) => (
              <TabsTrigger key={t} value={t} className="px-3">
                <FormattedMessage id={`ph.feature.tab.${t}`} />
              </TabsTrigger>
            ))}
          </TabsList>
          <TabsContent value="overview" className="grid gap-4 [&>*]:min-w-0">
            {sections(tabSections.overview)}
          </TabsContent>
          <TabsContent value="experience" className="grid gap-4 [&>*]:min-w-0">
            {sections(tabSections.experience)}
          </TabsContent>
          <TabsContent value="technical" className="grid gap-4 [&>*]:min-w-0">
            <AccessBlock data={data} />
            {sections(tabSections.technical)}
            <FactsBlock data={data} />
          </TabsContent>
          <TabsContent value="measure" className="grid gap-4 [&>*]:min-w-0">
            <Notice tone="info">
              <FormattedMessage id="ph.feature.metricsNote" />
            </Notice>
            <MetricsBlock metrics={data.metrics ?? []} />
            {sections(tabSections.measure)}
          </TabsContent>
          <TabsContent value="sources" className="grid gap-4 [&>*]:min-w-0">
            <SourcesBlock data={data} onChanged={onChanged} />
            {sections(tabSections.sources)}
          </TabsContent>
        </Tabs>
        <CoveragePanel data={data} />
      </div>
    </div>
  );
}

function Status({ label, value }: { label: string; value: ReactNode }) {
  return (
    <div className="grid gap-0.5">
      <dt className="text-xs text-muted-foreground">
        <FormattedMessage id={label} />
      </dt>
      <dd className="font-medium">{value}</dd>
    </div>
  );
}

/** Score, what is missing and why it counts (doc 05 §4); never AI-written. */
export function CoveragePanel({ data }: { data: FeatureView }) {
  const c = data.coverage;
  return (
    <Section title={<FormattedMessage id="ph.coverage.title" />} hint={<FormattedMessage id="ph.coverage.hint" />}>
      <div className="grid gap-3">
        <CoverageMeter score={c.score} />
        {c.capped && (
          <Meta>
            <FormattedMessage id="ph.coverage.capped" />
          </Meta>
        )}
        <ul className="grid gap-1.5 text-sm">
          {c.dimensions.map((d) => (
            <li key={d.key} className="flex items-baseline gap-2">
              <span aria-hidden="true" className={d.earned >= d.weight ? 'text-primary' : d.earned > 0 ? 'text-warning' : 'text-muted-foreground'}>
                {d.earned >= d.weight ? '●' : d.earned > 0 ? '◐' : '○'}
              </span>
              <span className="min-w-0 flex-1">
                <FormattedMessage id={`ph.dim.${d.key}`} />
                <span className="sr-only">
                  {' '}
                  <FormattedMessage id={`ph.dimState.${d.state}`} />
                </span>
              </span>
              <span className="text-xs text-muted-foreground tabular-nums">
                {d.earned}/{d.weight}
              </span>
            </li>
          ))}
        </ul>
        {c.missing.length > 0 && (
          <div className="grid gap-1">
            <p className="text-xs font-semibold text-muted-foreground">
              <FormattedMessage id="ph.coverage.next" />
            </p>
            <ul className="grid list-disc gap-1 pl-4 text-[13px]">
              {c.missing.map((m) => (
                <li key={m}>
                  <FormattedMessage id={`ph.next.${m}`} />
                </li>
              ))}
            </ul>
          </div>
        )}
      </div>
    </Section>
  );
}

function SectionCard({
  feature,
  section,
  canEdit,
  canApprove,
  onChanged,
}: {
  feature: string;
  section: FeatureSection;
  canEdit: boolean;
  canApprove: boolean;
  onChanged: () => void;
}) {
  const intl = useIntl();
  const api = useApi();
  const [editing, setEditing] = useState(false);
  const [history, setHistory] = useState(false);
  const [busy, setBusy] = useState(false);
  const base = section.draft ?? section.approved;
  const [vi, setVi] = useState(base?.body.vi ?? '');
  const [en, setEn] = useState(base?.body.en ?? '');
  const [sources, setSources] = useState((base?.sources ?? []).join('\n'));
  const k = section.key;

  const run = async (name: 'productHubSaveSection' | 'productHubSectionAct', data: unknown, done: string) => {
    setBusy(true);
    try {
      await api.call(name, data);
      toast.success(intl.formatMessage({ id: done }));
      setEditing(false);
      onChanged();
    } catch (e) {
      toast.error(intl.formatMessage({ id: productErrorId(e) }));
    } finally {
      setBusy(false);
    }
  };

  return (
    <Section
      title={<FormattedMessage id={`ph.section.${k}`} />}
      hint={<FormattedMessage id={`ph.section.${k}.hint`} />}
      actions={
        canEdit && !editing ? (
          <Button kind="ghost" onClick={() => setEditing(true)}>
            <FormattedMessage id={base ? 'ph.section.edit' : 'ph.section.write'} />
          </Button>
        ) : null
      }
    >
      <div className="grid gap-3">
        {section.stale && (
          <Notice tone="warn">
            <FormattedMessage id="ph.section.stale" values={{ paths: section.stale.paths.join(', ') }} />
          </Notice>
        )}
        {section.approved && section.approved.version > 1 && (
          <span>
            <Button kind="ghost" onClick={() => setHistory((h) => !h)}>
              <FormattedMessage id={history ? 'ph.history.hide' : 'ph.history.show'} values={{ n: section.approved.version - 1 }} />
            </Button>
          </span>
        )}
        {history && <VersionHistory feature={feature} sectionKey={k} />}
        {section.approved ? (
          <Body version={section.approved} meta={<FormattedMessage
            id="ph.section.approvedMeta"
            values={{ v: section.approved.version, by: section.approved.by, approver: section.approved.approvedBy, date: shortDate(intl, section.approved.approvedAt) }}
          />} />
        ) : !section.draft ? (
          <Meta>
            <FormattedMessage id="ph.section.empty" />
          </Meta>
        ) : null}
        {section.draft && !editing && (
          <div className="grid gap-2 rounded-lg border border-dashed p-3">
            <div className="flex flex-wrap items-center gap-2">
              <Pill tone="wait">
                <FormattedMessage id={section.draft.origin === 'ai' ? 'ph.section.aiDraft' : 'ph.section.draft'} />
              </Pill>
              <span className="text-xs text-muted-foreground">
                {section.draft.by} · {shortDate(intl, section.draft.at)}
              </span>
            </div>
            <Body version={section.draft} />
            <div className="flex flex-wrap gap-2">
              {canApprove && (
                <Button kind="primary" disabled={busy} onClick={() => run('productHubSectionAct', { feature, key: k, action: 'approve' }, 'ph.section.approved')}>
                  <FormattedMessage id="ph.section.approve" />
                </Button>
              )}
              {canEdit && (
                <Button kind="ghost" disabled={busy} onClick={() => run('productHubSectionAct', { feature, key: k, action: 'discard' }, 'ph.section.discarded')}>
                  <FormattedMessage id="ph.section.discard" />
                </Button>
              )}
            </div>
          </div>
        )}
        {editing && (
          <form
            className="grid gap-2"
            onSubmit={(e) => {
              e.preventDefault();
              void run(
                'productHubSaveSection',
                {
                  feature,
                  key: k,
                  body: { vi, en },
                  sources: sources.split('\n').map((s) => s.trim()).filter(Boolean),
                },
                'ph.section.saved',
              );
            }}
          >
            <label className="grid gap-1 text-sm font-medium">
              <FormattedMessage id="ph.section.vi" />
              <Textarea value={vi} onChange={(e) => setVi(e.target.value)} required rows={5} />
            </label>
            <label className="grid gap-1 text-sm font-medium">
              <FormattedMessage id="ph.section.en" />
              <Textarea value={en} onChange={(e) => setEn(e.target.value)} rows={4} />
            </label>
            <label className="grid gap-1 text-sm font-medium">
              <FormattedMessage id="ph.section.sources" />
              <Textarea
                value={sources}
                onChange={(e) => setSources(e.target.value)}
                rows={3}
                placeholder={intl.formatMessage({ id: 'ph.section.sourcesPlaceholder' })}
              />
            </label>
            <div className="flex flex-wrap gap-2">
              <Button kind="primary" type="submit" disabled={busy || !vi.trim()}>
                <FormattedMessage id="ph.section.saveDraft" />
              </Button>
              <Button kind="ghost" disabled={busy} onClick={() => setEditing(false)}>
                <FormattedMessage id="action.cancel" />
              </Button>
            </div>
          </form>
        )}
      </div>
    </Section>
  );
}

function Body({ version, meta }: { version: { body: { vi: string; en: string }; sources: string[] }; meta?: ReactNode }) {
  const intl = useIntl();
  const en = intl.locale.startsWith('en');
  const text = en && version.body.en ? version.body.en : version.body.vi;
  return (
    <div className="grid gap-2">
      {/* Plain text, never HTML: knowledge text is data (doc 08 §5). */}
      <p className="text-sm leading-6 whitespace-pre-wrap">{text}</p>
      {en && !version.body.en && (
        <span>
          <Pill tone="muted">
            <FormattedMessage id="ph.section.noEnglish" />
          </Pill>
        </span>
      )}
      {version.sources.length > 0 ? (
        <div className="flex flex-wrap gap-1.5">
          {version.sources.map((s) => (
            <code key={s} className="rounded bg-muted px-1.5 py-0.5 font-mono text-[11.5px] break-all">
              {s}
            </code>
          ))}
        </div>
      ) : (
        <span className="text-xs text-muted-foreground">
          <FormattedMessage id="ph.section.noSource" />
        </span>
      )}
      {meta && <span className="text-xs text-muted-foreground">{meta}</span>}
    </div>
  );
}

function AccessBlock({ data }: { data: FeatureView }) {
  const navigate = useNavigate();
  const a = data.access;
  return (
    <Section
      title={<FormattedMessage id="ph.access.title" />}
      actions={
        <Button kind="ghost" onClick={() => navigate('features')}>
          <FormattedMessage id="ph.access.change" />
        </Button>
      }
    >
      <dl className="grid grid-cols-[auto_1fr] gap-x-4 gap-y-2 text-sm">
        {a.hubKey ? (
          <>
            <dt className="text-muted-foreground">
              <FormattedMessage id="ph.access.defaultTier" />
            </dt>
            <dd>
              <FormattedMessage id={`ph.tier.${a.defaultTier}`} />
            </dd>
            <dt className="text-muted-foreground">
              <FormattedMessage id="ph.access.liveTier" />
            </dt>
            <dd>{a.liveTier ? <FormattedMessage id={`ph.tier.${a.liveTier}`} /> : <FormattedMessage id="ph.access.liveDefault" />}</dd>
            <dt className="text-muted-foreground">
              <FormattedMessage id="ph.access.credits" />
            </dt>
            <dd>
              <FormattedMessage id={a.credits ? 'ph.yes' : 'ph.no'} />
            </dd>
            <dt className="text-muted-foreground">
              <FormattedMessage id="ph.access.flags" />
            </dt>
            <dd className="font-mono text-xs">{a.flags.join(', ') || '—'}</dd>
          </>
        ) : (
          <>
            <dt className="text-muted-foreground">
              <FormattedMessage id="ph.access.noHub" />
            </dt>
            <dd />
          </>
        )}
        <dt className="text-muted-foreground">
          <FormattedMessage id="ph.access.capabilities" />
        </dt>
        <dd className="font-mono text-xs">{a.capabilities.join(', ') || '—'}</dd>
      </dl>
    </Section>
  );
}

function List({ title, items, empty }: { title: string; items: ReactNode[]; empty?: string }) {
  return (
    <div className="grid gap-1">
      <p className="text-xs font-semibold text-muted-foreground">
        <FormattedMessage id={title} /> · {items.length}
      </p>
      {items.length ? (
        <ul className="grid gap-0.5">{items}</ul>
      ) : (
        <Meta>
          <FormattedMessage id={empty ?? 'ph.none'} />
        </Meta>
      )}
    </div>
  );
}

function FactsBlock({ data }: { data: FeatureView }) {
  const navigate = useNavigate();
  const facts = data.feature.facts;
  const paths = (xs: string[]) =>
    xs.slice(0, 30).map((p) => (
      <li key={p}>
        <PathText path={p} />
      </li>
    ));
  return (
    <Section
      title={<FormattedMessage id="ph.facts.title" />}
      description={<FormattedMessage id="ph.facts.description" values={{ rev: shortRev(data.feature.revision) }} />}
    >
      <div className="grid gap-4 md:grid-cols-2">
        <List title="ph.facts.modules" items={paths(facts.modules)} />
        <List title="ph.facts.functions" items={paths(facts.functions)} />
        <List
          title="ph.facts.callables"
          items={facts.callables.map((c) => (
            <li key={c} className="font-mono text-[12.5px]">
              {c}
            </li>
          ))}
        />
        <List title="ph.facts.tests" items={paths(facts.tests)} empty="ph.facts.noTests" />
        <List
          title="ph.facts.citations"
          items={facts.codeCitations.slice(0, 20).map((c) => (
            <li key={c.id} className="text-[12.5px]">
              <span className="font-mono font-semibold">{c.id}</span> · <PathText path={c.at} />
            </li>
          ))}
        />
        <List
          title="ph.facts.dependencies"
          items={[
            ...data.feature.dependsOn.map((d) => (
              <li key={`up-${d}`} className="text-[13px]">
                <FormattedMessage id="ph.facts.upstream" />{' '}
                <button type="button" className={`${linkClass} font-mono`} onClick={() => navigate('product', `features/${d}`)}>
                  {d}
                </button>
              </li>
            )),
            ...data.dependents.map((d) => (
              <li key={`down-${d}`} className="text-[13px]">
                <FormattedMessage id="ph.facts.downstream" />{' '}
                <button type="button" className={`${linkClass} font-mono`} onClick={() => navigate('product', `features/${d}`)}>
                  {d}
                </button>
              </li>
            )),
          ]}
        />
        {facts.figma.length > 0 && (
          <List
            title="ph.facts.figma"
            items={facts.figma.map((n) => (
              <li key={n} className="font-mono text-[12.5px]">
                {n}
              </li>
            ))}
          />
        )}
      </div>
      {facts.deadGlobs.length > 0 && (
        <Notice tone="warn" className="mt-4">
          <FormattedMessage id="ph.facts.dead" values={{ globs: facts.deadGlobs.join(', ') }} />
        </Notice>
      )}
    </Section>
  );
}

function SourcesBlock({ data, onChanged }: { data: FeatureView; onChanged: () => void }) {
  const intl = useIntl();
  const navigate = useNavigate();
  return (
    <>
      <Section
        title={<FormattedMessage id="ph.conflicts.title" />}
        actions={data.canEdit ? <FindConflicts feature={data.feature.id} onDone={onChanged} /> : null}
      >
        {data.conflicts.length === 0 ? (
          <Meta>
            <FormattedMessage id="ph.conflict.noneForFeature" />
          </Meta>
        ) : (
          <ul className="grid gap-3">
            {data.conflicts.map((c) => (
              <li key={c.id} className="grid gap-2 rounded-lg border p-3">
                <div className="flex flex-wrap items-center gap-2">
                  <Pill tone={c.status === 'open' ? 'warn' : 'muted'}>
                    <FormattedMessage id={`ph.conflict.status.${c.status}`} />
                  </Pill>
                  <span className="text-sm"><ConflictText conflict={c} /></span>
                </div>
                {c.claims.map((cl, i) => (
                  <div key={i} className="grid gap-1 border-l-2 pl-3 text-[13px]">
                    <div className="flex flex-wrap items-center gap-2">
                      <AuthorityPill authority={cl.authority} />
                      <PathText path={cl.anchor ? `${cl.path}#${cl.anchor}` : cl.path} />
                      {cl.date && <span className="text-muted-foreground">{shortDate(intl, cl.date)}</span>}
                    </div>
                    <q className="text-muted-foreground">{cl.text}</q>
                  </div>
                ))}
              </li>
            ))}
          </ul>
        )}
      </Section>
      <Section title={<FormattedMessage id="ph.sources.forFeature" values={{ n: data.sources.length }} />}>
        {data.sources.length === 0 ? (
          <Meta>
            <FormattedMessage id="ph.sources.noneForFeature" />
          </Meta>
        ) : (
          <ul className="grid gap-2">
            {data.sources.map((s) => (
              <li key={s.id} className="flex flex-wrap items-center gap-2 text-sm">
                <AuthorityPill authority={s.authority} />
                <button type="button" className={`${linkClass} text-left`} onClick={() => navigate('product', `sources/${s.id}`)}>
                  {s.title}
                </button>
                <PathText path={s.path} />
                {s.docDate && <span className="text-xs text-muted-foreground">{shortDate(intl, s.docDate)}</span>}
              </li>
            ))}
          </ul>
        )}
      </Section>
      <Section title={<FormattedMessage id="ph.decisions.forFeature" values={{ n: data.decisions.length }} />}>
        {data.decisions.length === 0 ? (
          <Meta>
            <FormattedMessage id="ph.none" />
          </Meta>
        ) : (
          <ul className="grid gap-2 text-sm">
            {data.decisions.map((d) => (
              <li key={d.id} className="flex gap-2">
                <span className="font-mono text-[12.5px] font-semibold">{d.id}</span>
                <span className="min-w-0 flex-1">{d.title}</span>
                <Pill tone={d.status === 'superseded' ? 'warn' : d.status === 'open' ? 'wait' : 'muted'}>
                  <FormattedMessage id={`ph.decision.status.${d.status}`} />
                </Pill>
              </li>
            ))}
          </ul>
        )}
      </Section>
    </>
  );
}

/** "Tìm mâu thuẫn": Claude reads this feature's sources; what it finds waits as a suggestion. */
function FindConflicts({ feature, onDone }: { feature: string; onDone: () => void }) {
  const intl = useIntl();
  const api = useApi();
  const [busy, setBusy] = useState(false);
  return (
    <Button
      kind="ghost"
      disabled={busy}
      onClick={async () => {
        setBusy(true);
        try {
          const r = await api.call<{ added: number; skipped: number }>('productCopilotFindConflicts', {
            feature,
            locale: intl.locale.startsWith('en') ? 'en' : 'vi',
          });
          toast.success(intl.formatMessage({ id: 'ph.conflict.found' }, { n: r.added }));
          onDone();
        } catch (e) {
          toast.error(intl.formatMessage({ id: productErrorId(e) }));
        } finally {
          setBusy(false);
        }
      }}
    >
      <FormattedMessage id={busy ? 'ph.conflict.finding' : 'ph.conflict.find'} />
    </Button>
  );
}

/** Lines only in one of two texts: enough to see what an approval changed. */
export function lineDiff(before: string, after: string) {
  const a = before.split('\n');
  const b = after.split('\n');
  return { removed: a.filter((l) => l.trim() && !b.includes(l)), added: b.filter((l) => l.trim() && !a.includes(l)) };
}

function VersionHistory({ feature, sectionKey }: { feature: string; sectionKey: string }) {
  const intl = useIntl();
  const [load, reload] = useLoad<SectionVersionsView>('productHubSectionVersions', { feature, key: sectionKey }, `${feature}/${sectionKey}`);
  return (
    <Loaded load={load} reload={reload}>
      {(d) => {
        const chain = [d.current, ...d.versions].filter((v): v is NonNullable<typeof v> => !!v);
        return (
          <ol className="grid gap-3 rounded-lg border bg-muted/30 p-3 text-[13px]">
            {chain.slice(1).map((v, i) => {
              const next = chain[i]!;
              const diff = lineDiff(v.body.vi, next.body.vi);
              return (
                <li key={v.version} className="grid gap-1">
                  <span className="font-medium">
                    <FormattedMessage
                      id="ph.history.version"
                      values={{ from: v.version, to: next.version, by: next.approvedBy, date: shortDate(intl, next.approvedAt) }}
                    />
                  </span>
                  {diff.removed.map((l) => (
                    <span key={`-${l}`} className="rounded bg-destructive/10 px-1.5 whitespace-pre-wrap">
                      − {l}
                    </span>
                  ))}
                  {diff.added.map((l) => (
                    <span key={`+${l}`} className="rounded bg-primary/10 px-1.5 whitespace-pre-wrap">
                      + {l}
                    </span>
                  ))}
                  {!diff.removed.length && !diff.added.length && (
                    <span className="text-muted-foreground">
                      <FormattedMessage id="ph.history.sourcesOnly" />
                    </span>
                  )}
                </li>
              );
            })}
          </ol>
        );
      }}
    </Loaded>
  );
}

/** The dictionary metrics linked to this feature and what the code measures (Phase 4). */
function MetricsBlock({ metrics }: { metrics: NonNullable<FeatureView['metrics']> }) {
  const navigate = useNavigate();
  return (
    <Section
      title={<FormattedMessage id="ph.feature.metrics" values={{ n: metrics.length }} />}
      actions={
        <Button kind="ghost" onClick={() => navigate('product', 'insights')}>
          <FormattedMessage id="ph.feature.allMetrics" />
        </Button>
      }
    >
      {metrics.length === 0 ? (
        <Meta>
          <FormattedMessage id="ph.feature.noMetrics" />
        </Meta>
      ) : (
        <ul className="grid gap-2 text-sm">
          {metrics.map((m) => (
            <li key={m.id} className="flex flex-wrap items-center gap-2">
              <span className="font-mono text-[12.5px] font-semibold">{m.id}</span>
              <span className="min-w-0 flex-1">{m.name}</span>
              <InstrumentationPill value={m.instrumentation} />
            </li>
          ))}
        </ul>
      )}
    </Section>
  );
}
