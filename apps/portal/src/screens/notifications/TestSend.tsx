import {
  NOTIFICATION_TEST_HOURLY_LIMIT,
  inboxGroups,
  notificationDestinations,
  notificationTemplateIds,
  notificationTemplates,
  notificationTypes,
  renderTemplate,
  type NotificationEntryDetail,
  type NotificationTemplateDetail,
  type NotificationTemplateRow,
  type NotificationTestResult,
  type NotificationTestTargets,
  type StaffSendTestNotification,
} from '@child-life/contracts';
import { Send, ShieldAlert } from 'lucide-react';
import { useEffect, useMemo, useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl, type IntlShape } from 'react-intl';
import { ApiError, useApi, useLoad, type Load } from '../../api';
import { EmptyState, Field, Notice, Section, useConfirm } from '../../content-kit';
import { Button, Pill, Segmented, SelectMenu } from '../../ui';
import {
  CodeText,
  LoadedSkeleton,
  PageSkeleton,
  StatusDot,
  TabHeader,
  useOptionalLoad,
} from './kit';
import { LockScreenPreview, initialSample, sampleValues } from './TemplateEditor';
import { TransitionList, versionLabel } from './Timeline';
import { ErrorLine, destinationName, labelOr, pick, type Lang } from './shared';

type Family = NotificationTestTargets['families'][number];
type Member = Family['members'][number];

/** "Cùng nuôi 2" from the role and the masked ref; "Bạn" is added by the caller. */
export function memberLabel(intl: IntlShape, m: Pick<Member, 'ref' | 'role'>): string {
  const n = /^m(\d{1,2})$/.exec(m.ref)?.[1];
  const id = `ntf.recipient.${m.role}`;
  if (n && intl.messages[id]) return intl.formatMessage({ id }, { n: Number(n) });
  return labelOr(intl, `memberRole.${m.role}`, m.role);
}

/** Whether the template list says a draft exists (only then can a draft be sent). */
export function hasDraft(rows: readonly NotificationTemplateRow[] | null, templateId: string) {
  return !!rows?.find((r) => r.id === templateId && r.draftState !== 'none');
}

/** The default target: the staff member's own account in their own family, else the first. */
export function defaultTarget(
  targets: NotificationTestTargets,
): { code: string; recipient: string } | null {
  for (const f of targets.families) {
    const me = f.members.find((m) => m.me);
    if (me) return { code: f.code, recipient: me.ref };
  }
  const f = targets.families[0];
  const m = f?.members[0];
  return f && m ? { code: f.code, recipient: m.ref } : null;
}

/** Polling of the sent row stops once the app reported where the tap led, or after 2 minutes. */
export const POLL_MS = 3000;
export const POLL_MAX = 40;
export const pollDone = (d: NotificationEntryDetail | null, polls: number) =>
  polls >= POLL_MAX || (d !== null && d.navigated !== null);

export function TestSendTab({
  templates,
}: {
  templates: Load<{ templates: NotificationTemplateRow[] }> | null;
}) {
  const [load, reload] = useLoad<NotificationTestTargets>(
    'staffNotificationTestTargets',
    {},
    'ntf-test-targets',
  );
  const rows = templates?.status === 'ok' ? templates.data.templates : null;
  return (
    <div className="stack">
      <TabHeader
        title={<FormattedMessage id="ntf.tab.test" />}
        purpose={<FormattedMessage id="ntf.purpose.test" />}
      />
      <LoadedSkeleton load={load} reload={reload} skeleton={<PageSkeleton />}>
        {(targets) => <TestSendView targets={targets} rows={rows} onSent={reload} />}
      </LoadedSkeleton>
    </div>
  );
}

/**
 * Gửi thử (D-092): pick a notification, its copy and one of your own (or an internal family's)
 * accounts, see the lock-screen preview, send a real push and follow it live until the tap.
 */
export function TestSendView({
  targets,
  rows,
  onSent,
  initialResult = null,
}: {
  targets: NotificationTestTargets;
  rows: readonly NotificationTemplateRow[] | null;
  onSent?: () => void;
  initialResult?: NotificationTestResult | null;
}) {
  const intl = useIntl();
  const api = useApi();
  const { ask, dialog } = useConfirm();
  const first = defaultTarget(targets);
  const [templateId, setTemplateId] = useState<string>(notificationTemplateIds[0]);
  const [copy, setCopy] = useState<'live' | 'draft'>('live');
  const [code, setCode] = useState(first?.code ?? '');
  const [recipient, setRecipient] = useState(first?.recipient ?? '');
  const [baby, setBaby] = useState(1);
  const [variant, setVariant] = useState<'normal' | 'missing_target'>('normal');
  const [lang, setLang] = useState<Lang>(intl.locale.startsWith('en') ? 'en' : 'vi');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const [result, setResult] = useState<NotificationTestResult | null>(initialResult);
  const [used, setUsed] = useState(targets.usedThisHour);

  if (!targets.enabled)
    return (
      <Notice tone="warn" title={<FormattedMessage id="ntf.test.devOnly.title" />}>
        <FormattedMessage id="ntf.test.devOnly" />
      </Notice>
    );
  if (!targets.families.length || !first)
    return <EmptyState title={<FormattedMessage id="ntf.test.noTargets" />} />;

  const def = notificationTemplates[templateId as keyof typeof notificationTemplates];
  const kindDef = notificationTypes[def.kind];
  const draftOk = hasDraft(rows, templateId);
  const family = targets.families.find((f) => f.code === code) ?? targets.families[0]!;
  const member = family.members.find((m) => m.ref === recipient) ?? family.members[0];
  const limitReached = used >= NOTIFICATION_TEST_HOURLY_LIMIT;

  const send = async () => {
    if (!member) return;
    setBusy(true);
    setError(null);
    const request: StaffSendTestNotification = {
      templateId: def.id,
      copy: copy === 'draft' && draftOk ? 'draft' : 'live',
      code: family.code,
      recipient: member.ref,
      baby: Math.min(baby, Math.max(1, family.babies)),
      variant,
    };
    try {
      const res = await api.call<NotificationTestResult>('staffSendTestNotification', request);
      setResult(res);
      setUsed((u) => u + 1);
      onSent?.();
    } catch (e) {
      setError(e instanceof ApiError ? e : new ApiError('unknown', null));
    } finally {
      setBusy(false);
    }
  };

  const groups = inboxGroups.map((g) => ({
    group: g,
    ids: notificationTemplateIds.filter(
      (id) => notificationTypes[notificationTemplates[id].kind].group === g,
    ),
  }));

  return (
    <div className="grid items-start gap-6 xl:grid-cols-[minmax(0,1fr)_minmax(340px,420px)]">
      <div className="grid min-w-0 gap-4">
        <Section title={<FormattedMessage id="ntf.test.what" />}>
          <div className="grid gap-4">
            <Field label={<FormattedMessage id="ntf.col.template" />} htmlFor="ntf-test-template">
              <select
                id="ntf-test-template"
                className="h-9 w-full rounded-md border bg-background px-3 text-sm"
                value={templateId}
                onChange={(e) => {
                  setTemplateId(e.target.value);
                  if (!hasDraft(rows, e.target.value)) setCopy('live');
                }}
              >
                {groups.map((g) => (
                  <optgroup
                    key={g.group}
                    label={intl.formatMessage({ id: `ntf.group.${g.group}` })}
                  >
                    {g.ids.map((id) => (
                      <option key={id} value={id}>
                        {pick(intl, notificationTemplates[id].name)} ·{' '}
                        {intl.formatMessage({ id: `ntf.kind.${notificationTemplates[id].kind}` })}
                      </option>
                    ))}
                  </optgroup>
                ))}
              </select>
            </Field>
            <p className="flex flex-wrap items-center gap-2 text-[13px] text-muted-foreground">
              <span>
                <FormattedMessage id="ntf.test.opens" />{' '}
                <span className="font-medium text-foreground">
                  {pick(intl, notificationDestinations[kindDef.destination].screen)}
                </span>
              </span>
              {kindDef.engagement.length > 0 && (
                <Pill tone="muted">
                  {kindDef.engagement.join(', ')} · <FormattedMessage id="ntf.test.engScenario" />
                </Pill>
              )}
            </p>
            <div className="grid gap-1.5">
              <span className="text-[13px] font-medium">
                <FormattedMessage id="ntf.test.copy" />
              </span>
              <div
                className="flex flex-wrap gap-2"
                role="radiogroup"
                aria-label={intl.formatMessage({ id: 'ntf.test.copy' })}
              >
                {(['live', 'draft'] as const).map((c) => (
                  <label
                    key={c}
                    className={`flex items-center gap-2 rounded-md border px-3 py-1.5 text-sm ${c === 'draft' && !draftOk ? 'opacity-50' : ''}`}
                  >
                    <input
                      type="radio"
                      name="ntf-test-copy"
                      value={c}
                      checked={copy === c}
                      disabled={c === 'draft' && !draftOk}
                      onChange={() => setCopy(c)}
                    />
                    <FormattedMessage id={`ntf.test.copy.${c}`} />
                  </label>
                ))}
              </div>
              {!draftOk && (
                <span className="text-[12px] text-muted-foreground">
                  <FormattedMessage id="ntf.test.noDraft" />
                </span>
              )}
            </div>
          </div>
        </Section>
        <Section title={<FormattedMessage id="ntf.test.who" />}>
          <div className="grid gap-4">
            <div
              className="grid gap-1.5"
              role="radiogroup"
              aria-label={intl.formatMessage({ id: 'ntf.col.family' })}
            >
              <span className="text-[13px] font-medium">
                <FormattedMessage id="ntf.col.family" />
              </span>
              <div className="flex flex-wrap gap-2">
                {targets.families.map((f) => (
                  <label
                    key={f.code}
                    data-family={f.code}
                    className="flex items-center gap-2 rounded-md border px-3 py-1.5 text-sm"
                  >
                    <input
                      type="radio"
                      name="ntf-test-family"
                      checked={family.code === f.code}
                      onChange={() => {
                        setCode(f.code);
                        setRecipient((f.members.find((m) => m.me) ?? f.members[0])?.ref ?? '');
                        setBaby(1);
                      }}
                    />
                    <span className="font-mono">{f.code}</span>
                    {f.mine && (
                      <Pill tone="ok">
                        <FormattedMessage id="ntf.test.mine" />
                      </Pill>
                    )}
                    {f.internal && (
                      <Pill tone="muted">
                        <FormattedMessage id="ntf.test.internal" />
                      </Pill>
                    )}
                  </label>
                ))}
              </div>
            </div>
            <div
              className="grid gap-1.5"
              role="radiogroup"
              aria-label={intl.formatMessage({ id: 'ntf.col.recipient' })}
            >
              <span className="text-[13px] font-medium">
                <FormattedMessage id="ntf.col.recipient" />
              </span>
              <ul className="grid gap-1.5">
                {family.members.map((m) => (
                  <li key={m.ref}>
                    <label className="flex flex-wrap items-center gap-2 rounded-md border px-3 py-2 text-sm">
                      <input
                        type="radio"
                        name="ntf-test-member"
                        checked={member?.ref === m.ref}
                        onChange={() => setRecipient(m.ref)}
                      />
                      <span className="font-medium">{memberLabel(intl, m)}</span>
                      {m.me && (
                        <Pill tone="ok">
                          <FormattedMessage id="ntf.test.me" />
                        </Pill>
                      )}
                      <span className="ml-auto text-[12px] text-muted-foreground">
                        <FormattedMessage id="ntf.test.devices" values={{ n: m.devices }} />
                      </span>
                    </label>
                  </li>
                ))}
              </ul>
              {member && member.devices === 0 && (
                <p className="text-[12px] text-warning">
                  <FormattedMessage id="ntf.test.noDevice" />
                </p>
              )}
            </div>
            {family.babies > 1 && (
              <SelectMenu
                label={intl.formatMessage({ id: 'ntf.test.baby' })}
                value={baby}
                options={Array.from({ length: family.babies }, (_, i) => ({
                  value: i + 1,
                  label: intl.formatMessage({ id: 'ntf.test.babyN' }, { n: i + 1 }),
                }))}
                onChange={setBaby}
              />
            )}
            <div className="grid gap-1.5">
              <span className="text-[13px] font-medium">
                <FormattedMessage id="ntf.test.variant" />
              </span>
              <Segmented
                label={intl.formatMessage({ id: 'ntf.test.variant' })}
                value={variant}
                options={(['normal', 'missing_target'] as const).map((v) => ({
                  value: v,
                  label: <FormattedMessage id={`ntf.test.variant.${v}`} />,
                }))}
                onChange={setVariant}
              />
              <span className="text-[12px] text-muted-foreground">
                <FormattedMessage id={`ntf.test.variant.${variant}.note`} />
              </span>
            </div>
          </div>
        </Section>
        <ErrorLine error={error} />
        <div className="flex flex-wrap items-center gap-3">
          <Button
            kind="primary"
            disabled={busy || !member || limitReached}
            onClick={() =>
              member?.me
                ? void send()
                : ask({
                    title: intl.formatMessage({ id: 'ntf.test.confirm.title' }),
                    body: intl.formatMessage(
                      { id: 'ntf.test.confirm.body' },
                      { name: member ? memberLabel(intl, member) : '', code: family.code },
                    ),
                    confirmLabel: intl.formatMessage({ id: 'ntf.test.send' }),
                    onConfirm: () => void send(),
                  })
            }
          >
            <Send className="size-4" aria-hidden="true" />
            <FormattedMessage id="ntf.test.send" />
          </Button>
          <span
            className={`text-[13px] tabular-nums ${limitReached ? 'text-destructive' : 'text-muted-foreground'}`}
          >
            <FormattedMessage
              id="ntf.test.used"
              values={{ n: used, max: NOTIFICATION_TEST_HOURLY_LIMIT }}
            />
          </span>
        </div>
      </div>
      <div className="grid min-w-0 gap-4">
        <TestPreview
          templateId={def.id}
          copy={copy === 'draft' && draftOk ? 'draft' : 'live'}
          lang={lang}
          onLang={setLang}
        />
        {result && <TestResultPanel result={result} />}
        <HowToCheck />
      </div>
      {dialog}
    </div>
  );
}

/** The lock screens with the template's sample values (the server sends exactly these). */
function TestPreview({
  templateId,
  copy,
  lang,
  onLang,
}: {
  templateId: string;
  copy: 'live' | 'draft';
  lang: Lang;
  onLang: (l: Lang) => void;
}) {
  const intl = useIntl();
  const def = notificationTemplates[templateId as keyof typeof notificationTemplates];
  const [load] = useOptionalLoad<NotificationTemplateDetail>(
    true,
    'staffNotificationTemplate',
    { templateId },
    `ntf-template:${templateId}`,
  );
  const detail = load?.status === 'ok' && load.data.id === templateId ? load.data : null;
  const text = (copy === 'draft' ? detail?.draft : detail?.live) ?? def.builtin;
  const sample = useMemo(() => initialSample(def), [def]);
  const r = renderTemplate(text, lang, sampleValues(def, sample, lang));
  return (
    <Section
      title={<FormattedMessage id="ntf.tpl.preview" />}
      description={<FormattedMessage id="ntf.test.previewNote" />}
      actions={
        <Segmented
          label={intl.formatMessage({ id: 'ntf.tpl.previewLang' })}
          value={lang}
          options={(['vi', 'en'] as const).map((l) => ({
            value: l,
            label: <FormattedMessage id={`ntf.preview.lang.${l}`} />,
          }))}
          onChange={onLang}
        />
      }
    >
      <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-1">
        <LockScreenPreview platform="ios" lang={lang} title={r.title} body={r.body} />
        <LockScreenPreview platform="android" lang={lang} title={r.title} body={r.body} />
      </div>
    </Section>
  );
}

/** What was sent, where a tap goes, and the row followed live until the app reports the tap. */
export function TestResultPanel({ result }: { result: NotificationTestResult }) {
  const intl = useIntl();
  const params = Object.entries(result.params);
  return (
    <Section
      title={<FormattedMessage id="ntf.test.result" />}
      description={
        <FormattedMessage
          id="ntf.test.resultNote"
          values={{ code: result.code, v: versionLabel(intl, result.templateVersion) }}
        />
      }
    >
      <div className="grid gap-3 text-sm" data-test-entry={result.entry}>
        <dl className="grid grid-cols-[minmax(0,8rem)_minmax(0,1fr)] gap-x-3 gap-y-1.5">
          <dt className="text-muted-foreground">
            <FormattedMessage id="ntf.col.destination" />
          </dt>
          <dd className="font-medium">{destinationName(intl, result.destination)}</dd>
          <dt className="text-muted-foreground">
            <FormattedMessage id="ntf.dest.params" />
          </dt>
          <dd className="grid gap-0.5">
            {params.length === 0 ? (
              <span className="text-muted-foreground">
                <FormattedMessage id="ntf.dest.noParams" />
              </span>
            ) : (
              params.map(([k, v]) => (
                <span key={k} className="flex gap-2 font-mono text-[12px]">
                  <span className="text-muted-foreground">{k}</span>
                  <CodeText value={v} />
                </span>
              ))
            )}
          </dd>
          <dt className="text-muted-foreground">
            <FormattedMessage id="ntf.test.devicesLabel" />
          </dt>
          <dd>
            <FormattedMessage
              id="ntf.test.accepted"
              values={{ a: result.accepted, c: result.devices }}
            />
          </dd>
        </dl>
        {result.missing.length > 0 && (
          <Notice tone="warn">
            <FormattedMessage id="ntf.test.missing" values={{ list: result.missing.join(', ') }} />
          </Notice>
        )}
        {result.devices === 0 && (
          <Notice tone="warn">
            <FormattedMessage id="ntf.test.noDevice" />
          </Notice>
        )}
        <p className="text-[12px] text-muted-foreground">
          <FormattedMessage id="ntf.acceptedNotDelivered" />
        </p>
        {result.testSuggestion && (
          <Notice>
            <FormattedMessage id="ntf.test.suggestion" />
          </Notice>
        )}
        <LiveStatus code={result.code} entry={result.entry} />
      </div>
    </Section>
  );
}

function Step({ done, children }: { done: boolean | null; children: ReactNode }) {
  return (
    <li>
      {/* Not reached yet reads as waiting (muted), not as a second kind of success. */}
      <StatusDot tone={done ? 'ok' : 'muted'}>
        <span className={done ? undefined : 'text-muted-foreground'}>{children}</span>
      </StatusDot>
    </li>
  );
}

/** Polls the sent row every 3 s for up to 2 min: delivery → opened → where the tap led. */
export function LiveStatus({
  code,
  entry,
  initial = null,
}: {
  code: string;
  entry: string;
  initial?: NotificationEntryDetail | null;
}) {
  const intl = useIntl();
  const api = useApi();
  const [detail, setDetail] = useState<NotificationEntryDetail | null>(initial);
  const [polls, setPolls] = useState(0);
  const done = pollDone(detail, polls);
  useEffect(() => {
    if (done) return;
    let live = true;
    const timer = window.setTimeout(
      () => {
        api
          .call<NotificationEntryDetail>('staffNotificationDetail', { code, entry })
          .then((d) => live && setDetail(d))
          .catch(() => undefined)
          .finally(() => live && setPolls((p) => p + 1));
      },
      polls === 0 ? 500 : POLL_MS,
    );
    return () => {
      live = false;
      window.clearTimeout(timer);
    };
  }, [api, code, entry, polls, done]);
  return (
    <div className="grid gap-2 rounded-lg border p-3">
      <p className="flex items-center gap-2 text-[13px] font-semibold">
        <FormattedMessage id="ntf.test.live" />
        <span className="font-normal text-muted-foreground" role="status">
          <FormattedMessage id={done ? 'ntf.test.live.stopped' : 'ntf.test.live.watching'} />
        </span>
      </p>
      <ol className="grid gap-1 text-sm">
        <Step done={detail ? !!detail.pushAttempted : false}>
          <FormattedMessage id="ntf.detail.pushAttempted" />
        </Step>
        <Step done={detail ? !!detail.providerAccepted : false}>
          <FormattedMessage id="ntf.detail.providerAccepted" />
        </Step>
        <Step done={detail ? !!detail.opened : false}>
          <FormattedMessage id="ntf.detail.opened" />
          {detail?.openSurface && (
            <>
              {' · '}
              <FormattedMessage id={`ntf.test.surface.${detail.openSurface}`} />
            </>
          )}
        </Step>
        <Step done={detail?.navigated ? detail.navigated === 'navigated' : false}>
          <FormattedMessage id="ntf.detail.navigation" />
          {detail?.navigated && (
            <>
              {': '}
              {intl.formatMessage({ id: `ntf.nav.${detail.navigated}` })}
            </>
          )}
        </Step>
      </ol>
      {detail && <TransitionList timeline={detail.timeline} />}
    </div>
  );
}

function HowToCheck() {
  return (
    <Section title={<FormattedMessage id="ntf.test.howto" />} collapsible defaultOpen>
      <div className="grid gap-2">
        <div className="flex items-start gap-2 text-[13px] text-muted-foreground">
          <ShieldAlert className="mt-0.5 size-4 shrink-0" aria-hidden="true" />
          <FormattedMessage id="ntf.test.howto.note" />
        </div>
        <ol className="list-decimal pl-5 text-sm">
          {(['lock', 'tap', 'inbox', 'swipe'] as const).map((s) => (
            <li key={s}>
              <FormattedMessage id={`ntf.test.howto.${s}`} />
            </li>
          ))}
        </ol>
      </div>
    </Section>
  );
}
