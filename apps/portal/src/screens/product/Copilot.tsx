import { productDraftTypes, type CopilotAnswer, type CopilotCitation, type CopilotMessage } from '@child-life/contracts';
import { ArrowUp, BookmarkPlus, MessageSquareText, Trash2 } from 'lucide-react';
import { useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { toast } from 'sonner';
import { Button as UiButton } from '@/components/ui/button';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { Textarea } from '@/components/ui/textarea';
import { cn } from '@/lib/utils';
import { useApi, useLoad } from '../../api';
import { EmptyState, Notice, Section } from '../../content-kit';
import { useNavigate } from '../../context';
import { shortDate } from '../../format';
import { Button, Loaded, Pill, type PillTone } from '../../ui';
import { productErrorId } from './Feature';
import { AuthorityPill, Meta, PathText, linkClass, shortRev } from './kit';
import type { AskResult, ConversationView, ConversationsView, DraftsView } from './types';

/**
 * Sản phẩm › Copilot (D-155, Phase 2, doc 04 §2.6): questions about the product answered from
 * approved knowledge on Claude. Each claim shows its sources; a fact without strong evidence is
 * shown as an assumption; "Lưu thành…" makes a draft, never a decision.
 */
export function CopilotScreen({ conversation }: { conversation: string | null }) {
  const [list, reloadList] = useLoad<ConversationsView>('productCopilotConversations', {}, 'conversations');
  const navigate = useNavigate();
  return (
    <div className="grid items-start gap-4 xl:grid-cols-[260px_minmax(0,1fr)] [&>*]:min-w-0">
      <div className="grid gap-4 [&>*]:min-w-0">
        <Section
          title={<FormattedMessage id="ph.copilot.history" />}
          actions={
            <Button kind="ghost" onClick={() => navigate('product', 'copilot')}>
              <FormattedMessage id="ph.copilot.new" />
            </Button>
          }
        >
          <Loaded load={list} reload={reloadList}>
            {(d) =>
              d.conversations.length === 0 ? (
                <Meta>
                  <FormattedMessage id="ph.copilot.noHistory" />
                </Meta>
              ) : (
                <ul className="grid gap-1">
                  {d.conversations.map((c) => (
                    <li key={c.id}>
                      <button
                        type="button"
                        onClick={() => navigate('product', `copilot/${c.id}`)}
                        className={cn(
                          'w-full truncate rounded-md px-2 py-1.5 text-left text-sm hover:bg-muted',
                          c.id === conversation && 'bg-muted font-medium',
                        )}
                      >
                        {c.title}
                        {c.scope !== 'global' && <span className="ml-1 font-mono text-xs text-muted-foreground">{c.scope}</span>}
                      </button>
                    </li>
                  ))}
                </ul>
              )
            }
          </Loaded>
        </Section>
        <DraftsSection />
      </div>
      {conversation ? (
        <ConversationLoader id={conversation} onDeleted={() => { reloadList(); navigate('product', 'copilot'); }} />
      ) : (
        <Thread key="new" scope="global" initial={[]} onStarted={(id) => { reloadList(); window.history.replaceState({}, '', `/product/copilot/${id}`); }} />
      )}
    </div>
  );
}

function ConversationLoader({ id, onDeleted }: { id: string; onDeleted: () => void }) {
  const api = useApi();
  const intl = useIntl();
  const [load, reload] = useLoad<ConversationView>('productCopilotConversation', { id }, id);
  return (
    <Loaded load={load} reload={reload}>
      {(c) => (
        <Thread
          key={c.id}
          scope={c.scope}
          conversationId={c.id}
          initial={c.messages}
          onDelete={async () => {
            try {
              await api.call('productCopilotDelete', { id: c.id });
              toast.success(intl.formatMessage({ id: 'ph.copilot.deleted' }));
              onDeleted();
            } catch (e) {
              toast.error(intl.formatMessage({ id: productErrorId(e) }));
            }
          }}
        />
      )}
    </Loaded>
  );
}

const suggestionIds = {
  global: ['ph.copilot.ask.g1', 'ph.copilot.ask.g2', 'ph.copilot.ask.g3', 'ph.copilot.ask.g4'],
  feature: ['ph.copilot.ask.f1', 'ph.copilot.ask.f2', 'ph.copilot.ask.f3', 'ph.copilot.ask.f4'],
};

/** One conversation: the messages, suggested first questions, and the composer. */
export function Thread({
  scope,
  conversationId: initialId,
  initial,
  onStarted,
  onDelete,
}: {
  scope: string;
  conversationId?: string;
  initial: CopilotMessage[];
  onStarted?: (id: string) => void;
  onDelete?: () => void;
}) {
  const intl = useIntl();
  const api = useApi();
  const [messages, setMessages] = useState<CopilotMessage[]>(initial);
  const [conversationId, setConversationId] = useState(initialId);
  const [text, setText] = useState('');
  const [busy, setBusy] = useState(false);
  const locale = intl.locale.startsWith('en') ? 'en' : 'vi';

  const send = async (question: string) => {
    const q = question.trim();
    if (q.length < 2 || busy) return;
    setBusy(true);
    setText('');
    setMessages((m) => [...m, { id: `pending-${m.length}`, role: 'user', text: q, at: new Date().toISOString(), answer: null }]);
    try {
      const r = await api.call<AskResult>('productCopilotAsk', {
        ...(conversationId ? { conversationId } : {}),
        scope,
        question: q,
        locale,
      });
      setMessages((m) => [...m, r.message]);
      if (!conversationId) {
        setConversationId(r.conversationId);
        onStarted?.(r.conversationId);
      }
    } catch (e) {
      setMessages((m) => m.slice(0, -1));
      setText(q);
      toast.error(intl.formatMessage({ id: productErrorId(e) }));
    } finally {
      setBusy(false);
    }
  };

  const questionFor = (i: number) => (i > 0 && messages[i - 1]?.role === 'user' ? messages[i - 1]!.text : '');

  return (
    <Section
      title={<FormattedMessage id={scope === 'global' ? 'ph.copilot.titleGlobal' : 'ph.copilot.titleFeature'} values={{ feature: scope }} />}
      hint={<FormattedMessage id="ph.copilot.hint" />}
      actions={
        onDelete ? (
          <UiButton variant="ghost" size="icon" aria-label={intl.formatMessage({ id: 'ph.copilot.delete' })} onClick={onDelete}>
            <Trash2 />
          </UiButton>
        ) : null
      }
    >
      <div className="grid gap-4">
        {messages.length === 0 && (
          <div className="grid gap-2">
            <EmptyState icon={MessageSquareText} title={<FormattedMessage id="ph.copilot.emptyTitle" />}>
              <FormattedMessage id="ph.copilot.emptyBody" />
            </EmptyState>
            <div className="flex flex-wrap justify-center gap-2">
              {suggestionIds[scope === 'global' ? 'global' : 'feature'].map((id) => (
                <UiButton key={id} variant="outline" size="sm" className="h-auto whitespace-normal text-left" onClick={() => void send(intl.formatMessage({ id }))}>
                  <FormattedMessage id={id} />
                </UiButton>
              ))}
            </div>
          </div>
        )}
        {messages.map((m, i) =>
          m.role === 'user' ? (
            <div key={m.id} className="ml-auto max-w-[85%] rounded-xl bg-muted px-3 py-2 text-sm whitespace-pre-wrap">
              {m.text}
            </div>
          ) : m.answer ? (
            <AnswerView key={m.id} answer={m.answer} question={questionFor(i)} scope={scope} conversationId={conversationId} messageId={m.id} />
          ) : null,
        )}
        {busy && (
          <p className="text-sm text-muted-foreground" role="status">
            <FormattedMessage id="ph.copilot.thinking" />
          </p>
        )}
        <form
          className="flex items-end gap-2"
          onSubmit={(e) => {
            e.preventDefault();
            void send(text);
          }}
        >
          <Textarea
            value={text}
            maxLength={1000}
            rows={2}
            aria-label={intl.formatMessage({ id: 'ph.copilot.input' })}
            placeholder={intl.formatMessage({ id: 'ph.copilot.input' })}
            onChange={(e) => setText(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter' && !e.shiftKey && !e.nativeEvent.isComposing) {
                e.preventDefault();
                void send(text);
              }
            }}
          />
          <UiButton type="submit" size="icon" disabled={busy || text.trim().length < 2} aria-label={intl.formatMessage({ id: 'ph.copilot.send' })}>
            <ArrowUp />
          </UiButton>
        </form>
        <Meta>
          <FormattedMessage id="ph.copilot.privacy" />
        </Meta>
      </div>
    </Section>
  );
}

const confidenceTone: Record<CopilotAnswer['confidence'], PillTone> = { verified: 'ok', mixed: 'wait', insufficient: 'warn' };
const claimTone: Record<string, PillTone> = { fact: 'ok', assumption: 'wait', recommendation: 'info' };

/** One answer: direct answer, claims with sources, confidence, gaps, and "Lưu thành…". */
export function AnswerView({
  answer,
  question,
  scope,
  conversationId,
  messageId,
}: {
  answer: CopilotAnswer;
  question: string;
  scope: string;
  conversationId?: string | undefined;
  messageId: string;
}) {
  const intl = useIntl();
  const [open, setOpen] = useState<string | null>(null);
  const byId = new Map(answer.citations.map((c) => [c.id, c]));
  const chip = (id: string) => (
    <button
      key={id}
      type="button"
      aria-expanded={open === id}
      onClick={() => setOpen(open === id ? null : id)}
      className={cn('rounded bg-muted px-1.5 py-0.5 font-mono text-[11.5px] hover:bg-accent', open === id && 'ring-1 ring-primary')}
    >
      {id}
    </button>
  );

  if (answer.mode === 'sources') {
    return (
      <div className="grid gap-3">
        <Notice tone={answer.reason === 'unconfigured' ? 'info' : 'warn'}>
          <FormattedMessage id={`ph.copilot.reason.${answer.reason ?? 'error'}`} />
        </Notice>
        {answer.citations.length > 0 && (
          <div className="grid gap-2">
            <p className="text-xs font-semibold text-muted-foreground">
              <FormattedMessage id="ph.copilot.related" />
            </p>
            {answer.citations.map((c) => (
              <CitationCard key={c.id} c={c} />
            ))}
          </div>
        )}
      </div>
    );
  }

  return (
    <div className="grid gap-3 rounded-xl border p-4">
      <p className="text-sm leading-6 whitespace-pre-wrap">{answer.answer}</p>
      {answer.claims.length > 0 && (
        <ul className="grid gap-2">
          {answer.claims.map((c, i) => (
            <li key={i} className="grid gap-1 text-[13.5px]">
              <div className="flex flex-wrap items-start gap-2">
                <Pill tone={claimTone[c.type] ?? 'muted'}>
                  <FormattedMessage id={`ph.claim.${c.type}`} />
                </Pill>
                <span className="min-w-0 flex-1">{c.text}</span>
              </div>
              <div className="flex flex-wrap items-center gap-1.5 pl-1">
                {c.cites.length ? c.cites.map(chip) : (
                  <span className="text-xs text-muted-foreground">
                    <FormattedMessage id="ph.section.noSource" />
                  </span>
                )}
                {c.downgraded && (
                  <span className="text-xs text-muted-foreground">
                    <FormattedMessage id="ph.copilot.downgraded" />
                  </span>
                )}
              </div>
              {open && c.cites.includes(open) && byId.get(open) && <CitationCard c={byId.get(open)!} />}
            </li>
          ))}
        </ul>
      )}
      <div className="flex flex-wrap items-center gap-2 text-[13px]">
        <Pill tone={confidenceTone[answer.confidence]}>
          <FormattedMessage id={`ph.confidence.answer.${answer.confidence}`} />
        </Pill>
        {answer.freshness.oldestCited && (
          <span className="text-muted-foreground">
            <FormattedMessage id="ph.copilot.oldest" values={{ date: shortDate(intl, answer.freshness.oldestCited) }} />
          </span>
        )}
        {answer.freshness.staleCited.length > 0 && (
          <span className="text-warning">
            <FormattedMessage id="ph.copilot.stale" values={{ ids: answer.freshness.staleCited.join(', ') }} />
          </span>
        )}
        <span className="ml-auto">
          <SaveAs answer={answer} question={question} scope={scope} conversationId={conversationId} messageId={messageId} />
        </span>
      </div>
      {answer.missingEvidence.length > 0 && (
        <Block title="ph.copilot.missing">
          <ul className="grid list-disc gap-0.5 pl-4">
            {answer.missingEvidence.map((m) => (
              <li key={m}>{m}</li>
            ))}
          </ul>
        </Block>
      )}
      {answer.implications && <Block title="ph.copilot.implications">{answer.implications}</Block>}
      {answer.suggestions.length > 0 && (
        <Block title="ph.copilot.suggestions">
          <ul className="grid list-disc gap-0.5 pl-4">
            {answer.suggestions.map((m) => (
              <li key={m}>{m}</li>
            ))}
          </ul>
        </Block>
      )}
    </div>
  );
}

function Block({ title, children }: { title: string; children: ReactNode }) {
  return (
    <div className="grid gap-1 text-[13px]">
      <p className="text-xs font-semibold text-muted-foreground">
        <FormattedMessage id={title} />
      </p>
      <div>{children}</div>
    </div>
  );
}

export function CitationCard({ c }: { c: CopilotCitation }) {
  const intl = useIntl();
  const navigate = useNavigate();
  return (
    <div className="grid gap-1 rounded-lg border bg-card p-2 text-[13px]">
      <div className="flex flex-wrap items-center gap-2">
        <span className="font-mono text-[11.5px] font-semibold">{c.id}</span>
        <AuthorityPill authority={c.authority === 'approved_section' ? 'approved_spec' : c.authority} />
        {c.status === 'draft' && (
          <Pill tone="wait">
            <FormattedMessage id="ph.section.draft" />
          </Pill>
        )}
        {c.status === 'stale' && (
          <Pill tone="warn">
            <FormattedMessage id="ph.copilot.staleChip" />
          </Pill>
        )}
        {c.date && <span className="text-muted-foreground">{shortDate(intl, c.date)}</span>}
        {c.revision && <span className="font-mono text-xs text-muted-foreground">{shortRev(c.revision)}</span>}
      </div>
      <span className="font-medium">{c.label}</span>
      {c.path && <PathText path={c.anchor ? `${c.path}#${c.anchor}` : c.path} />}
      <q className="text-muted-foreground">{c.excerpt}</q>
      {c.feature && (
        <button type="button" className={`${linkClass} justify-self-start font-mono text-[12px]`} onClick={() => navigate('product', `features/${c.feature}`)}>
          {c.feature}
        </button>
      )}
    </div>
  );
}

function SaveAs({
  answer,
  question,
  scope,
  conversationId,
  messageId,
}: {
  answer: CopilotAnswer;
  question: string;
  scope: string;
  conversationId?: string | undefined;
  messageId: string;
}) {
  const api = useApi();
  const intl = useIntl();
  const save = async (type: (typeof productDraftTypes)[number]) => {
    const evidence = answer.citations
      .map((c) => (c.path ? (c.anchor ? `${c.path}#${c.anchor}` : c.path) : c.id))
      .filter((x, i, all) => x.length >= 3 && all.indexOf(x) === i)
      .slice(0, 24);
    const body = [
      answer.answer,
      ...answer.claims.map((c) => `• [${c.type}] ${c.text}${c.cites.length ? ` (${c.cites.join(', ')})` : ''}`),
      answer.suggestions.length ? `\n${answer.suggestions.map((s) => `→ ${s}`).join('\n')}` : '',
    ]
      .filter(Boolean)
      .join('\n')
      .slice(0, 8000);
    try {
      await api.call('productHubCreateDraft', {
        type,
        feature: scope === 'global' ? (answer.features[0] ?? null) : scope,
        title: (question || answer.answer).slice(0, 160).padEnd(3, '…'),
        body: body || question,
        evidence,
        ...(conversationId ? { conversationId } : {}),
        messageId,
      });
      toast.success(intl.formatMessage({ id: 'ph.copilot.saved' }));
    } catch (e) {
      toast.error(intl.formatMessage({ id: productErrorId(e) }));
    }
  };
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <UiButton variant="ghost" size="sm">
          <BookmarkPlus />
          <FormattedMessage id="ph.copilot.saveAs" />
        </UiButton>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        {productDraftTypes.map((t) => (
          <DropdownMenuItem key={t} onSelect={() => void save(t)}>
            <FormattedMessage id={`ph.draftType.${t}`} />
          </DropdownMenuItem>
        ))}
      </DropdownMenuContent>
    </DropdownMenu>
  );
}

function DraftsSection() {
  const [load, reload] = useLoad<DraftsView>('productHubDrafts', {}, 'drafts');
  return (
    <Section title={<FormattedMessage id="ph.copilot.drafts" />} hint={<FormattedMessage id="ph.copilot.draftsHint" />} collapsible defaultOpen={false}>
      <Loaded load={load} reload={reload}>
        {(d) =>
          d.drafts.length === 0 ? (
            <Meta>
              <FormattedMessage id="ph.none" />
            </Meta>
          ) : (
            <ul className="grid gap-2 text-[13px]">
              {d.drafts.map((x) => (
                <li key={x.id} className="grid gap-0.5">
                  <span className="flex flex-wrap items-center gap-1.5">
                    <Pill tone="muted">
                      <FormattedMessage id={`ph.draftType.${x.type}`} />
                    </Pill>
                    <span className="font-medium">{x.title}</span>
                  </span>
                  <span className="text-xs text-muted-foreground">
                    {x.feature ?? '—'} · {x.createdBy}
                  </span>
                </li>
              ))}
            </ul>
          )
        }
      </Loaded>
    </Section>
  );
}
