import {
  notificationPlaceholders,
  notificationTemplates,
  notificationTypes,
  renderTemplate,
  renderTemplateText,
  staffCan,
  templateLengthGuide,
  validateTemplateCopy,
  type LocalizedTemplateCopy,
  type NotificationPlaceholder,
  type NotificationTemplateDef,
  type NotificationTemplateDetail,
  type PlaceholderValue,
  type StaffTemplateAction,
  type TemplateIssue,
} from '@child-life/contracts';
import { useId, useMemo, useRef, useState } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { ApiError, useApi, useLoad, type Callable } from '../../api';
import {
  EditorBar,
  EditorLayout,
  Field,
  Notice,
  Section,
  useConfirm,
  useGuardedLeave,
  type MenuItem,
} from '../../content-kit';
import { useStaff } from '../../context';
import { Button, ConfirmModal, Pill, Segmented } from '../../ui';
import { DataTable, LoadedSkeleton, StatusDot, TableSkeleton } from './kit';
import { DestinationDetails, ErrorLine, TemplateStatusPill, at, pick, type Lang } from './shared';

const langs = ['vi', 'en'] as const;
const fields = ['title', 'body'] as const;
type FieldKey = `${Lang}.${(typeof fields)[number]}`;

export function TemplateEditor({ templateId, onBack }: { templateId: string; onBack: () => void }) {
  const [load, reload] = useLoad<NotificationTemplateDetail>(
    'staffNotificationTemplate',
    { templateId },
    `ntf-template:${templateId}`,
  );
  return (
    <LoadedSkeleton
      load={load}
      reload={reload}
      skeleton={
        <div className="grid grid-cols-[minmax(0,1fr)] gap-6 xl:grid-cols-[minmax(0,1fr)_minmax(340px,400px)]">
          <TableSkeleton rows={8} />
          <TableSkeleton rows={4} />
        </div>
      }
    >
      {(detail) => <TemplateEditorView initial={detail} onBack={onBack} />}
    </LoadedSkeleton>
  );
}

export const sameCopy = (a: LocalizedTemplateCopy, b: LocalizedTemplateCopy) =>
  langs.every((l) => a[l].title === b[l].title && a[l].body === b[l].body);

/** Sample values as editable text per language (a number is the same in both). */
export type SampleText = Record<string, { vi: string; en: string }>;
export function initialSample(def: NotificationTemplateDef): SampleText {
  const out: SampleText = {};
  for (const p of def.placeholders) {
    const v = def.sample[p];
    out[p] =
      v === undefined
        ? { vi: '', en: '' }
        : typeof v === 'object'
          ? { vi: v.vi, en: v.en }
          : { vi: String(v), en: String(v) };
  }
  return out;
}

/** Values for [renderTemplate]: an empty sample takes the placeholder's fallback. */
export function sampleValues(
  def: NotificationTemplateDef,
  sample: SampleText,
  lang: Lang,
): Partial<Record<string, PlaceholderValue>> {
  const out: Partial<Record<string, PlaceholderValue>> = {};
  for (const p of def.placeholders) {
    const raw = sample[p]?.[notificationPlaceholders[p].type === 'number' ? 'vi' : lang] ?? '';
    if (raw.trim() === '') continue;
    out[p] = notificationPlaceholders[p].type === 'number' ? Number(raw) : raw;
  }
  return out;
}

/** Inserts `{{name}}` into [text] at the cursor (or the end). */
export function insertAt(text: string, token: string, start: number | null, end: number | null) {
  const s = start ?? text.length;
  const e = end ?? s;
  return { text: text.slice(0, s) + token + text.slice(e), cursor: s + token.length };
}

/**
 * EN08 template editor: VI and EN title/body, placeholders inserted at the cursor, live
 * validation (the server re-checks with the same `validateTemplateCopy`), lengths of the rendered
 * sample, lock-screen previews, the destination, and the draft → review → publish workflow with
 * immutable versions (version 0 is the copy in code).
 */
export function TemplateEditorView({
  initial,
  onBack,
}: {
  initial: NotificationTemplateDetail;
  onBack: () => void;
}) {
  const intl = useIntl();
  const api = useApi();
  const staff = useStaff();
  const canEdit = staffCan(staff.levels, 'notifications.edit');
  const canPublish = staffCan(staff.levels, 'notifications.publish');
  const [detail, setDetail] = useState(initial);
  const def = notificationTemplates[detail.id];
  const base = detail.draft ?? detail.live;
  const [copy, setCopy] = useState<LocalizedTemplateCopy>(base);
  const dirty = !sameCopy(copy, base);
  const issues = useMemo(() => validateTemplateCopy(def, copy), [def, copy]);
  const [sample, setSample] = useState<SampleText>(() => initialSample(def));
  const [lang, setLang] = useState<Lang | 'both'>('vi');
  const [platform, setPlatform] = useState<'both' | 'ios' | 'android'>('both');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const [publishing, setPublishing] = useState(false);
  const [note, setNote] = useState('');
  const { ask, dialog } = useConfirm();
  const { leave, dialog: leaveDialog } = useGuardedLeave(dirty, onBack);
  const refs = useRef<Partial<Record<FieldKey, HTMLInputElement | HTMLTextAreaElement | null>>>({});
  const [focused, setFocused] = useState<FieldKey>('vi.title');
  const ids = useId();

  const call = async (name: Callable, data: unknown) => {
    setBusy(true);
    setError(null);
    try {
      const next = await api.call<NotificationTemplateDetail>(name, data);
      setDetail(next);
      setCopy(next.draft ?? next.live);
      return true;
    } catch (e) {
      setError(e instanceof ApiError ? e : new ApiError('unknown', null));
      return false;
    } finally {
      setBusy(false);
    }
  };
  const act = (action: StaffTemplateAction) => call('staffNotificationTemplateAction', action);
  const save = () => call('staffSaveNotificationTemplate', { templateId: detail.id, copy });

  const blocking = issues.filter((i) => i.code === 'empty' || i.code === 'forbidden_content');
  const setField = (key: FieldKey, value: string) => {
    const [l, f] = key.split('.') as [Lang, 'title' | 'body'];
    setCopy((c) => ({ ...c, [l]: { ...c[l], [f]: value } }));
  };
  const insert = (p: NotificationPlaceholder) => {
    const key = focused;
    const el = refs.current[key];
    const [l, f] = key.split('.') as [Lang, 'title' | 'body'];
    const res = insertAt(
      copy[l][f],
      `{{${p}}}`,
      el?.selectionStart ?? null,
      el?.selectionEnd ?? null,
    );
    setField(key, res.text);
    window.requestAnimationFrame(() => {
      el?.focus();
      el?.setSelectionRange(res.cursor, res.cursor);
    });
  };

  const menu: MenuItem[] = [];
  if (canEdit && detail.draftState !== 'none')
    menu.push({
      key: 'discard',
      label: <FormattedMessage id="ntf.tpl.discard" />,
      destructive: true,
      onSelect: () =>
        ask({
          title: intl.formatMessage({ id: 'ntf.tpl.discard.title' }),
          body: intl.formatMessage({ id: 'ntf.tpl.discard.body' }),
          confirmLabel: intl.formatMessage({ id: 'ntf.tpl.discard' }),
          destructive: true,
          onConfirm: () => void act({ templateId: detail.id, action: 'discard' }),
        }),
    });
  if (canPublish && detail.status !== 'archived' && detail.latestVersion > 0)
    menu.push({
      key: 'archive',
      label: <FormattedMessage id="ntf.tpl.archive" />,
      destructive: true,
      onSelect: () =>
        ask({
          title: intl.formatMessage({ id: 'ntf.tpl.archive.title' }),
          body: intl.formatMessage({ id: 'ntf.tpl.archive.body' }),
          confirmLabel: intl.formatMessage({ id: 'ntf.tpl.archive' }),
          destructive: true,
          onConfirm: () => void act({ templateId: detail.id, action: 'archive' }),
        }),
    });

  const step = nextStep(detail, dirty, issues.length, canEdit, canPublish);
  const actions = (
    <>
      {canEdit && detail.draftState === 'draft' && (
        <Button
          kind={step === 'submit' ? 'primary' : 'secondary'}
          disabled={busy || dirty || issues.length > 0}
          title={
            dirty
              ? intl.formatMessage({ id: 'ntf.tpl.saveFirst' })
              : issues.length
                ? intl.formatMessage({ id: 'ntf.tpl.fixFirst' })
                : undefined
          }
          onClick={() => void act({ templateId: detail.id, action: 'submit' })}
        >
          <FormattedMessage id="ntf.tpl.submit" />
        </Button>
      )}
      {canPublish && detail.draftState === 'ready_for_review' && (
        <Button
          kind={step === 'publish' ? 'primary' : 'secondary'}
          disabled={busy || dirty || issues.length > 0}
          onClick={() => setPublishing(true)}
        >
          <FormattedMessage id="ntf.tpl.publish" />
        </Button>
      )}
      {canPublish && detail.status === 'published' && (
        <Button
          disabled={busy}
          onClick={() =>
            ask({
              title: intl.formatMessage({ id: 'ntf.tpl.pause.title' }),
              body: intl.formatMessage({ id: 'ntf.tpl.pause.body' }),
              confirmLabel: intl.formatMessage({ id: 'ntf.tpl.pause' }),
              onConfirm: () => void act({ templateId: detail.id, action: 'pause' }),
            })
          }
        >
          <FormattedMessage id="ntf.tpl.pause" />
        </Button>
      )}
      {canPublish && detail.status === 'paused' && (
        <Button
          disabled={busy}
          onClick={() => void act({ templateId: detail.id, action: 'resume' })}
        >
          <FormattedMessage id="ntf.tpl.resume" />
        </Button>
      )}
    </>
  );

  const shownLangs: Lang[] = lang === 'both' ? ['vi', 'en'] : [lang];
  const shownPlatforms = platform === 'both' ? (['ios', 'android'] as const) : [platform];
  const renders = shownLangs.map((l) => ({
    lang: l,
    ...renderTemplate(copy, l, sampleValues(def, sample, l)),
  }));
  const missing = [...new Set(renders.flatMap((r) => r.missing))];
  const kindDef = notificationTypes[def.kind];

  return (
    <div>
      <EditorBar
        backLabel={<FormattedMessage id="ntf.tpl.back" />}
        onBack={leave}
        title={pick(intl, def.name)}
        titleAs="h2"
        badges={
          <>
            <TemplateStatusPill status={detail.status} />
            {detail.draftState !== 'none' && (
              <StatusDot tone={detail.draftState === 'ready_for_review' ? 'warn' : 'wait'}>
                <span className="text-[13px]">
                  <FormattedMessage id={`ntf.draftState.${detail.draftState}`} />
                </span>
              </StatusDot>
            )}
            {step && step !== 'save' && (
              <span className="hidden text-[13px] text-muted-foreground lg:inline">
                <FormattedMessage id={`ntf.tpl.next.${step}`} />
              </span>
            )}
          </>
        }
        dirty={canEdit ? dirty : undefined}
        saving={busy}
        onSave={canEdit ? () => void save() : undefined}
        saveLabel={<FormattedMessage id="ntf.tpl.saveDraft" />}
        canSave={blocking.length === 0}
        actions={actions}
        menu={menu.length ? menu : undefined}
      />
      <EditorLayout
        aside={
          <>
            <Section
              title={<FormattedMessage id="ntf.tpl.preview" />}
              description={<FormattedMessage id="ntf.tpl.previewNote" />}
            >
              <div className="grid gap-3">
                <div className="flex flex-wrap gap-2">
                  <Segmented
                    label={intl.formatMessage({ id: 'ntf.tpl.previewLang' })}
                    value={lang}
                    options={(['vi', 'en', 'both'] as const).map((l) => ({
                      value: l,
                      label: <FormattedMessage id={`ntf.preview.lang.${l}`} />,
                    }))}
                    onChange={setLang}
                  />
                  <Segmented
                    label={intl.formatMessage({ id: 'ntf.tpl.previewPlatform' })}
                    value={platform}
                    options={(['both', 'ios', 'android'] as const).map((p) => ({
                      value: p,
                      label: <FormattedMessage id={`ntf.preview.platform.${p}`} />,
                    }))}
                    onChange={setPlatform}
                  />
                </div>
                <div
                  className={
                    shownLangs.length > 1
                      ? 'grid gap-3 sm:grid-cols-2 xl:grid-cols-1'
                      : 'grid gap-3'
                  }
                >
                  {renders.map((r) => (
                    <div key={r.lang} className="grid content-start gap-3">
                      {shownLangs.length > 1 && (
                        <p className="text-[12px] font-semibold text-muted-foreground uppercase">
                          {r.lang}
                        </p>
                      )}
                      {shownPlatforms.map((p) => (
                        <LockScreenPreview
                          key={p}
                          platform={p}
                          lang={r.lang}
                          title={r.title}
                          body={r.body}
                        />
                      ))}
                    </div>
                  ))}
                </div>
                {missing.length > 0 && (
                  <Notice tone="warn">
                    <FormattedMessage
                      id="ntf.tpl.missingValues"
                      values={{ list: missing.join(', ') }}
                    />
                  </Notice>
                )}
              </div>
            </Section>
            <Section title={<FormattedMessage id="ntf.tpl.destination" />}>
              <DestinationDetails id={kindDef.destination} />
            </Section>
          </>
        }
      >
        <ErrorLine error={error} />
        {detail.status === 'paused' && (
          <Notice tone="warn" title={<FormattedMessage id="ntf.tpl.paused.title" />}>
            <FormattedMessage id="ntf.tpl.paused.body" />
          </Notice>
        )}
        {detail.status === 'archived' && (
          <Notice tone="warn">
            <FormattedMessage id="ntf.tpl.archived.body" />
          </Notice>
        )}
        {!canEdit && (
          <Notice>
            <FormattedMessage id="ntf.tpl.readOnly" />
          </Notice>
        )}
        <div className="flex flex-wrap gap-x-4 gap-y-1 text-[13px] text-muted-foreground">
          <span>
            <FormattedMessage id="ntf.col.kind" />: <FormattedMessage id={`ntf.kind.${def.kind}`} />
          </span>
          <span className="font-mono">{def.id}</span>
          <span>
            <FormattedMessage
              id={detail.liveVersion === 0 ? 'ntf.tpl.liveV0' : 'ntf.tpl.liveVn'}
              values={{ v: detail.liveVersion }}
            />
          </span>
          {detail.draftBy && (
            <span>
              <FormattedMessage id="ntf.tpl.draftBy" values={{ name: detail.draftBy }} />
            </span>
          )}
          {detail.submittedBy && (
            <span>
              <FormattedMessage id="ntf.tpl.submittedBy" values={{ name: detail.submittedBy }} />
            </span>
          )}
        </div>
        {issues.length > 0 && (
          <Notice
            tone="warn"
            title={<FormattedMessage id="ntf.tpl.issues" values={{ n: issues.length }} />}
          >
            <ul className="list-disc pl-4">
              {issues.map((i, n) => (
                <li key={n}>
                  <IssueText issue={i} withPlace />
                </li>
              ))}
            </ul>
          </Notice>
        )}
        {langs.map((l) => (
          <Section
            key={l}
            title={<FormattedMessage id={`ntf.lang.${l}`} />}
            description={<FormattedMessage id="ntf.tpl.lengthNote" />}
          >
            <div className="grid gap-4">
              {fields.map((f) => {
                const key: FieldKey = `${l}.${f}`;
                const id = `${ids}-${l}-${f}`;
                const length = renderTemplateText(copy[l][f], l, sampleValues(def, sample, l)).text
                  .length;
                const guide = templateLengthGuide[f];
                const fieldIssues = issues.filter((i) => i.language === l && i.field === f);
                const common = {
                  id,
                  value: copy[l][f],
                  readOnly: !canEdit,
                  'aria-invalid': fieldIssues.length > 0 || undefined,
                  onFocus: () => setFocused(key),
                };
                return (
                  <Field
                    key={f}
                    label={<FormattedMessage id={`ntf.tpl.field.${f}`} />}
                    htmlFor={id}
                    counter={{ n: length, max: guide.max }}
                    help={
                      length > guide.recommended ? (
                        <span className="text-warning">
                          <FormattedMessage
                            id="ntf.tpl.overRecommended"
                            values={{ n: length, max: guide.recommended }}
                          />
                        </span>
                      ) : (
                        <FormattedMessage
                          id="ntf.tpl.recommended"
                          values={{ max: guide.recommended }}
                        />
                      )
                    }
                    error={
                      fieldIssues.length ? (
                        <span className="grid">
                          {fieldIssues.map((i, n) => (
                            <span key={n}>
                              <IssueText issue={i} />
                            </span>
                          ))}
                        </span>
                      ) : undefined
                    }
                  >
                    {f === 'title' ? (
                      <Input
                        {...common}
                        ref={(el) => {
                          refs.current[key] = el;
                        }}
                        onChange={(e) => setField(key, e.target.value)}
                      />
                    ) : (
                      <Textarea
                        {...common}
                        rows={3}
                        ref={(el) => {
                          refs.current[key] = el;
                        }}
                        onChange={(e) => setField(key, e.target.value)}
                      />
                    )}
                  </Field>
                );
              })}
            </div>
          </Section>
        ))}
        <Section
          title={<FormattedMessage id="ntf.tpl.placeholders" />}
          hint={<FormattedMessage id="ntf.tpl.placeholdersHint" />}
          description={canEdit ? <FormattedMessage id="ntf.tpl.placeholdersNote" /> : undefined}
        >
          {def.placeholders.length === 0 ? (
            <p className="text-sm text-muted-foreground">
              <FormattedMessage id="ntf.tpl.noPlaceholders" />
            </p>
          ) : (
            <ul className="grid gap-2">
              {def.placeholders.map((p) => {
                const meta = notificationPlaceholders[p];
                return (
                  <li key={p} className="flex flex-wrap items-center gap-2 text-sm">
                    {canEdit ? (
                      <button
                        type="button"
                        className="rounded-full border bg-background px-2.5 py-0.5 font-mono text-[12px] outline-none hover:border-primary hover:text-primary focus-visible:ring-[3px] focus-visible:ring-ring/50"
                        onClick={() => insert(p)}
                        aria-label={intl.formatMessage({ id: 'ntf.tpl.insert' }, { name: p })}
                      >
                        {`{{${p}}}`}
                      </button>
                    ) : (
                      <code className="rounded bg-muted px-1.5 py-0.5 text-[12px]">{`{{${p}}}`}</code>
                    )}
                    <span>{pick(intl, meta.description)}</span>
                    {meta.sensitivity !== 'safe' && (
                      <Pill tone="warn">
                        <FormattedMessage id={`ntf.sensitivity.${meta.sensitivity}`} />
                      </Pill>
                    )}
                    {def.required.includes(p) && (
                      <Pill tone="info">
                        <FormattedMessage id="ntf.tpl.required" />
                      </Pill>
                    )}
                    <span className="text-[12px] text-muted-foreground">
                      <FormattedMessage
                        id="ntf.tpl.phMeta"
                        values={{
                          kind: intl.formatMessage({ id: `ntf.phType.${meta.type}` }),
                          max: meta.maxLength,
                        }}
                      />
                    </span>
                  </li>
                );
              })}
            </ul>
          )}
        </Section>
        {def.placeholders.length > 0 && (
          <Section
            title={<FormattedMessage id="ntf.tpl.sample" />}
            description={<FormattedMessage id="ntf.tpl.sampleNote" />}
            collapsible
            defaultOpen={false}
          >
            <div className="grid gap-3 sm:grid-cols-2">
              {def.placeholders.flatMap((p) =>
                (notificationPlaceholders[p].type === 'number' ? (['vi'] as const) : langs).map(
                  (l) => {
                    const id = `${ids}-sample-${p}-${l}`;
                    return (
                      <Field
                        key={`${p}-${l}`}
                        htmlFor={id}
                        label={
                          notificationPlaceholders[p].type === 'number' ? (
                            p
                          ) : (
                            <FormattedMessage
                              id="ntf.tpl.sampleFor"
                              values={{ name: p, lang: l.toUpperCase() }}
                            />
                          )
                        }
                      >
                        <Input
                          id={id}
                          inputMode={
                            notificationPlaceholders[p].type === 'number' ? 'numeric' : undefined
                          }
                          value={sample[p]?.[l] ?? ''}
                          onChange={(e) =>
                            setSample((s) => ({
                              ...s,
                              [p]:
                                notificationPlaceholders[p].type === 'number'
                                  ? { vi: e.target.value, en: e.target.value }
                                  : { ...(s[p] ?? { vi: '', en: '' }), [l]: e.target.value },
                            }))
                          }
                        />
                      </Field>
                    );
                  },
                ),
              )}
            </div>
          </Section>
        )}
        <VersionHistory
          detail={detail}
          canRollback={canPublish && !busy}
          onRollback={(version) =>
            ask({
              title: intl.formatMessage({ id: 'ntf.tpl.rollback.title' }, { v: version }),
              body: intl.formatMessage({ id: 'ntf.tpl.rollback.body' }),
              confirmLabel: intl.formatMessage({ id: 'ntf.tpl.rollback' }),
              onConfirm: () => void act({ templateId: detail.id, action: 'rollback', version }),
            })
          }
        />
      </EditorLayout>
      {publishing && (
        <ConfirmModal
          title={<FormattedMessage id="ntf.tpl.publish.title" />}
          confirm={<FormattedMessage id="ntf.tpl.publish" />}
          busy={busy}
          error={error}
          onCancel={() => setPublishing(false)}
          onConfirm={async () => {
            const ok = await act({ templateId: detail.id, action: 'publish', note: note.trim() });
            if (ok) {
              setPublishing(false);
              setNote('');
            }
          }}
        >
          <div className="grid gap-3">
            <p>
              <FormattedMessage
                id="ntf.tpl.publish.body"
                values={{ v: detail.latestVersion + 1 }}
              />
            </p>
            <label className="grid gap-1 text-[13px] font-medium">
              <FormattedMessage id="ntf.tpl.publish.note" />
              <Textarea
                rows={2}
                maxLength={200}
                value={note}
                onChange={(e) => setNote(e.target.value)}
              />
            </label>
          </div>
        </ConfirmModal>
      )}
      {dialog}
      {leaveDialog}
    </div>
  );
}

/** The one obvious next step of the workflow: Save → Submit → Publish. */
export function nextStep(
  detail: Pick<NotificationTemplateDetail, 'draftState'>,
  dirty: boolean,
  issues: number,
  canEdit: boolean,
  canPublish: boolean,
): 'save' | 'submit' | 'publish' | null {
  if (canEdit && dirty) return 'save';
  if (issues > 0) return null;
  if (canEdit && detail.draftState === 'draft') return 'submit';
  if (canPublish && detail.draftState === 'ready_for_review') return 'publish';
  return null;
}

export function IssueText({ issue, withPlace }: { issue: TemplateIssue; withPlace?: boolean }) {
  const intl = useIntl();
  const text = intl.formatMessage(
    { id: `ntf.issue.${issue.code}` },
    { name: issue.placeholder ?? '' },
  );
  if (!withPlace) return <>{text}</>;
  return (
    <>
      <FormattedMessage
        id="ntf.issue.at"
        values={{
          lang: issue.language.toUpperCase(),
          field: intl.formatMessage({ id: `ntf.tpl.field.${issue.field}` }),
        }}
      />{' '}
      {text}
    </>
  );
}

/** Lock-screen mockups (pure CSS): iOS banner-style card and Android heads-up notification. */
export function LockScreenPreview({
  platform,
  lang,
  title,
  body,
}: {
  platform: 'ios' | 'android';
  lang: Lang;
  title: string;
  body: string;
}) {
  const intl = useIntl();
  const now = intl.formatMessage({ id: `ntf.preview.now.${lang}` });
  if (platform === 'ios') {
    return (
      <figure className="grid gap-1.5">
        <figcaption className="text-[12px] font-medium text-muted-foreground">
          <FormattedMessage id="ntf.preview.ios" />
        </figcaption>
        <div className="rounded-[28px] bg-gradient-to-b from-slate-700 to-slate-900 p-3">
          <div className="rounded-2xl bg-white/85 p-3 text-slate-900 shadow-sm backdrop-blur dark:bg-white/80">
            <div className="flex items-center gap-2 text-[11px] text-slate-600">
              <span className="grid size-5 place-items-center rounded-md bg-primary text-[9px] font-bold text-primary-foreground">
                CL
              </span>
              <span className="font-medium tracking-wide uppercase">Child Life</span>
              <span className="ml-auto">{now}</span>
            </div>
            <p className="mt-1.5 line-clamp-1 text-[13px] font-semibold" data-preview="title">
              {title}
            </p>
            <p className="line-clamp-4 text-[13px] leading-snug" data-preview="body">
              {body}
            </p>
          </div>
        </div>
      </figure>
    );
  }
  return (
    <figure className="grid gap-1.5">
      <figcaption className="text-[12px] font-medium text-muted-foreground">
        <FormattedMessage id="ntf.preview.android" />
      </figcaption>
      <div className="rounded-[20px] bg-slate-800 p-3">
        <div className="rounded-xl bg-slate-100 p-3 text-slate-900 shadow-sm">
          <div className="flex items-center gap-1.5 text-[11px] text-slate-600">
            <span className="size-3.5 rounded-full bg-primary" aria-hidden="true" />
            <span>Child Life</span>
            <span aria-hidden="true">·</span>
            <span>{now}</span>
          </div>
          <p className="mt-1 line-clamp-1 text-[13px] font-medium">{title}</p>
          <p className="line-clamp-2 text-[13px] leading-snug text-slate-700">{body}</p>
        </div>
      </div>
    </figure>
  );
}

function VersionHistory({
  detail,
  canRollback,
  onRollback,
}: {
  detail: NotificationTemplateDetail;
  canRollback: boolean;
  onRollback: (version: number) => void;
}) {
  const intl = useIntl();
  const versions = [...detail.versions].sort((a, b) => b.version - a.version);
  const live = detail.status === 'paused' || detail.status === 'archived' ? 0 : detail.liveVersion;
  const rollbackCell = (version: number) =>
    canRollback && version !== live ? (
      <Button kind="ghost" onClick={() => onRollback(version)}>
        <FormattedMessage id="ntf.tpl.rollback" />
      </Button>
    ) : version === live ? (
      <Pill tone="ok">
        <FormattedMessage id="ntf.tpl.inUse" />
      </Pill>
    ) : null;
  return (
    <Section
      title={<FormattedMessage id="ntf.tpl.history" />}
      hint={<FormattedMessage id="ntf.tpl.historyHint" />}
      flush
      collapsible
      summary={intl.formatNumber(versions.length + 1)}
    >
      <DataTable min={640} tall>
        <table className="table">
          <thead>
            <tr>
              <th>
                <FormattedMessage id="ntf.col.version" />
              </th>
              <th>
                <FormattedMessage id="ntf.col.publishedAt" />
              </th>
              <th>
                <FormattedMessage id="ntf.col.publishedBy" />
              </th>
              <th>
                <FormattedMessage id="ntf.col.note" />
              </th>
              <th>
                <FormattedMessage id="ntf.col.titleVi" />
              </th>
              <th />
            </tr>
          </thead>
          <tbody>
            {versions.map((v) => (
              <tr key={v.version}>
                <td className="nowrap tabular-nums">
                  <FormattedMessage id="ntf.tpl.version" values={{ v: v.version }} />
                </td>
                <td className="nowrap">{at(intl, v.publishedAt)}</td>
                <td>{v.publishedBy}</td>
                <td>{v.note || <span className="muted">—</span>}</td>
                <td className="max-w-64 truncate">{v.copy.vi.title}</td>
                <td className="text-right">{rollbackCell(v.version)}</td>
              </tr>
            ))}
            <tr>
              <td className="nowrap">
                <FormattedMessage id="ntf.tpl.v0" />
              </td>
              <td className="muted">—</td>
              <td className="muted">—</td>
              <td className="muted">
                <FormattedMessage id="ntf.tpl.v0note" />
              </td>
              <td className="max-w-64 truncate">
                {notificationTemplates[detail.id].builtin.vi.title}
              </td>
              <td className="text-right">{rollbackCell(0)}</td>
            </tr>
          </tbody>
        </table>
      </DataTable>
      <p className="px-5 py-3 text-[13px] text-muted-foreground">
        <FormattedMessage id="ntf.tpl.pausedFallback" />
      </p>
    </Section>
  );
}
