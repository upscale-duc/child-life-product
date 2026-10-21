import {
  appUpdateConfigSchema,
  appUpdateEmpty,
  appUpdateIcons,
  appUpdateLimits,
  appUpdateTones,
  compareAppVersions,
  staffCan,
  type AppUpdateConfig,
  type AppUpdateHighlight,
  type AppUpdatePage,
  type AppUpdatePlatform,
  type AppUpdateRelease,
  type AppUpdateText,
} from '@child-life/contracts';
import { ChevronRight, History, Maximize2, Smartphone } from 'lucide-react';
import { useId, useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { Button as UiButton } from '@/components/ui/button';
import { Sheet, SheetContent, SheetTitle } from '@/components/ui/sheet';
import { Switch } from '@/components/ui/switch';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { cn } from '@/lib/utils';
import { ApiError, useApi, useLoad, type AppUpdateView, type FirstAidImage } from '../api';
import { useStaff } from '../context';
import { Button, Loaded, Modal, Page, Panel, Pill, TableScroll, errorMessageId } from '../ui';
import { AppIcon, AppUpdatePreview } from './AppUpdatePreview';
import { FieldSelect, FilePicker, IconButton } from './form-controls';
import { fileToBase64 } from './FirstAidEditor';

/**
 * Hệ thống › Cập nhật ứng dụng (D-061, v1.0 improvement UP1–UP6): the versions in each store, the
 * oldest one allowed to run (below it the app shows UP1 and stops), and "Có gì mới" — the UP2
 * sheet's rows, the UP5 banner line and the UP3/UP4 pages. Publishing takes effect on the next
 * app launch; raising a minimum is spelled out before it goes.
 *
 * Laid out for small desktops (owner, 2026-10-13): three tabs instead of one long form, the
 * publish bar pinned to the bottom with the problems per tab, the preview beside the form when
 * there is room (else in a sheet), and the history in a sheet.
 */
export function AppUpdateScreen() {
  const [state, reload] = useLoad<AppUpdateView>('staffAppUpdate', {}, 'appUpdate');
  const staff = useStaff();
  return (
    <Page title={<FormattedMessage id="au.title" />} info={<FormattedMessage id="au.subtitle" />}>
      <Loaded load={state} reload={reload}>
        {(view) => (
          <AppUpdateBody
            view={view}
            canEdit={staffCan(staff.levels, 'release.edit')}
            onPublished={reload}
          />
        )}
      </Loaded>
    </Page>
  );
}

const platforms = ['ios', 'android'] as const;
type PlatformKey = (typeof platforms)[number];
type Tab = 'versions' | 'release' | 'pages';
type Issue = { path: PropertyKey[]; message: string; code: string };

const platformName: Record<PlatformKey, string> = {
  ios: 'iOS · App Store',
  android: 'Android · Google Play',
};

/** Which tab a schema problem belongs to. */
function tabOf(path: PropertyKey[]): Tab {
  if (path[0] !== 'release') return 'versions';
  return path[1] === 'pages' ? 'pages' : 'release';
}

const startsWith = (path: PropertyKey[], prefix: PropertyKey[]) =>
  prefix.every((p, i) => path[i] === p);

export function AppUpdateBody({
  view,
  canEdit,
  onPublished,
  initialTab = 'versions',
}: {
  view: AppUpdateView;
  canEdit: boolean;
  onPublished?: () => void;
  /** Tests open a given tab; the screen starts on Phiên bản. */
  initialTab?: Tab;
}) {
  const intl = useIntl();
  const published = view.current?.config ?? null;
  const [config, setConfig] = useState<AppUpdateConfig>(published ?? appUpdateEmpty);
  const [images, setImages] = useState<FirstAidImage[]>(view.images);
  const [tab, setTab] = useState<Tab>(initialTab);
  const [confirm, setConfirm] = useState(false);
  const [history, setHistory] = useState(false);
  const [preview, setPreview] = useState(false);
  // Empty-field problems show once someone tries to publish; wrong values show right away.
  const [attempted, setAttempted] = useState(false);
  const check = appUpdateConfigSchema.safeParse(config);
  const issues: Issue[] = check.success ? [] : check.error.issues;
  const changed = JSON.stringify(config) !== JSON.stringify(published ?? appUpdateEmpty);
  const ro = !canEdit;
  const count = (t: Tab) => issues.filter((i) => tabOf(i.path) === t).length;
  const errorAt = (prefix: PropertyKey[]): string | null => {
    const hit = issues.find((i) => startsWith(i.path, prefix));
    if (!hit) return null;
    // A field not filled in yet is not an error until someone tries to publish.
    if (hit.code === 'too_small' && !attempted) return null;
    return issueId(hit.message, hit.path);
  };
  const publish = () => {
    if (issues.length) {
      setAttempted(true);
      setTab(tabOf(issues[0]!.path));
      // Once the tab has drawn its errors, bring the first one into view and focus it.
      setTimeout(() => {
        const first = document.querySelector<HTMLElement>('.au-main [aria-invalid="true"]');
        first?.scrollIntoView({ block: 'center', behavior: 'smooth' });
        first?.focus({ preventScroll: true });
      }, 50);
      return;
    }
    setConfirm(true);
  };

  return (
    <div className="au">
      <StatusCard
        view={view}
        onHistory={() => setHistory(true)}
        historyLabel={intl.formatMessage({ id: 'au.historyOpen' }, { n: view.history.length })}
      />

      <div className="au-layout">
        <Tabs value={tab} onValueChange={(v) => setTab(v as Tab)} className="au-main min-w-0 gap-4">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <TabsList>
              {(['versions', 'release', 'pages'] as const).map((t) => (
                <TabsTrigger key={t} value={t} className="gap-1.5 px-3">
                  <FormattedMessage id={`au.tab.${t}`} />
                  {t === 'release' && config.release && (
                    <span className="text-xs text-muted-foreground">
                      {config.release.highlights.length}/{appUpdateLimits.highlights}
                    </span>
                  )}
                  {t === 'pages' && config.release && (
                    <span className="text-xs text-muted-foreground">
                      {config.release.pages.length}/{appUpdateLimits.pages}
                    </span>
                  )}
                  {count(t) > 0 && (attempted || t === 'versions') && (
                    <span
                      className="inline-flex size-5 items-center justify-center rounded-full bg-destructive/15 text-[11px] font-semibold text-destructive"
                      aria-label={intl.formatMessage({ id: 'au.state.issues' }, { n: count(t) })}
                    >
                      {count(t)}
                    </span>
                  )}
                </TabsTrigger>
              ))}
            </TabsList>
            <UiButton
              variant="outline"
              size="sm"
              // Hidden once the preview sits beside the form (the `au` container, 900 px).
              className="@min-[900px]/au:hidden"
              onClick={() => setPreview(true)}
            >
              <Smartphone />
              <FormattedMessage id="au.pv.title" />
            </UiButton>
          </div>

          <TabsContent value="versions" className="stack">
            <VersionsPanel
              config={config}
              published={published}
              readOnly={ro}
              errorAt={errorAt}
              rulesAt={(prefix) =>
                issues
                  .filter((i) => i.path.length === prefix.length && startsWith(i.path, prefix))
                  .map((i) => issueId(i.message, i.path))
              }
              onChange={(p, v) => setConfig({ ...config, [p]: v })}
            />
            <Panel
              title={<FormattedMessage id="au.nudge" />}
              note={<FormattedMessage id="au.nudgeNote" />}
            >
              <NumberField
                label={<FormattedMessage id="au.snoozeDays" />}
                value={config.snoozeDays}
                min={1}
                max={30}
                readOnly={ro}
                onChange={(snoozeDays) => setConfig({ ...config, snoozeDays })}
              />
            </Panel>
          </TabsContent>

          <TabsContent value="release" className="stack">
            <ReleasePanel
              value={config.release}
              readOnly={ro}
              errorAt={errorAt}
              onChange={(release) => setConfig({ ...config, release })}
            />
          </TabsContent>

          <TabsContent value="pages" className="stack">
            <PagesPanel
              value={config.release}
              images={images}
              readOnly={ro}
              errorAt={errorAt}
              onImage={(img) => setImages((all) => [img, ...all.filter((i) => i.id !== img.id)])}
              onChange={(release) => setConfig({ ...config, release })}
              onTurnOn={() => setTab('release')}
            />
          </TabsContent>
        </Tabs>

        <aside className="au-aside no-scrollbar">
          <Panel
            title={<FormattedMessage id="au.pv.title" />}
            aside={
              <UiButton
                variant="ghost"
                size="icon"
                className="size-8"
                aria-label={intl.formatMessage({ id: 'au.pv.bigger' })}
                title={intl.formatMessage({ id: 'au.pv.bigger' })}
                onClick={() => setPreview(true)}
              >
                <Maximize2 />
              </UiButton>
            }
          >
            <AppUpdatePreview config={config} images={images} />
          </Panel>
        </aside>
      </div>

      {canEdit && (
        <div className="au-bar" role="region" aria-label={intl.formatMessage({ id: 'au.publish' })}>
          <p className="au-bar__state" aria-live="polite">
            {attempted && issues.length > 0 ? (
              <span className="text-destructive">
                <FormattedMessage id="au.state.issues" values={{ n: issues.length }} />
              </span>
            ) : (
              <FormattedMessage id={changed ? 'au.state.dirty' : 'au.state.clean'} />
            )}
          </p>
          <div className="actions">
            <Button disabled={!changed} onClick={() => setConfig(published ?? appUpdateEmpty)}>
              <FormattedMessage id="au.reset" />
            </Button>
            <Button kind="primary" disabled={!changed} onClick={publish}>
              <FormattedMessage id="au.publish" />
            </Button>
          </div>
        </div>
      )}

      <Sheet open={history} onOpenChange={setHistory}>
        <SheetContent
          side="right"
          aria-describedby={undefined}
          closeLabel={intl.formatMessage({ id: 'action.close' })}
          className="w-full gap-0 overflow-y-auto sm:max-w-2xl"
        >
          <div className="border-b px-6 py-5">
            <SheetTitle className="text-base">
              <FormattedMessage id="au.history" />
            </SheetTitle>
          </div>
          <HistoryTable history={view.history} />
        </SheetContent>
      </Sheet>

      <Sheet open={preview} onOpenChange={setPreview}>
        <SheetContent
          side="right"
          aria-describedby={undefined}
          closeLabel={intl.formatMessage({ id: 'action.close' })}
          className="no-scrollbar w-full gap-0 overflow-y-auto sm:max-w-sm"
        >
          <div className="border-b px-6 py-5">
            <SheetTitle className="text-base">
              <FormattedMessage id="au.pv.title" />
            </SheetTitle>
          </div>
          <div className="p-4">
            <AppUpdatePreview config={config} images={images} reserve={230} />
          </div>
        </SheetContent>
      </Sheet>

      {confirm && (
        <PublishModal
          before={published}
          after={config}
          onClose={() => setConfirm(false)}
          onDone={() => {
            setConfirm(false);
            setAttempted(false);
            onPublished?.();
          }}
        />
      )}
    </div>
  );
}

/** "Đang áp dụng": one line instead of a whole panel, the history one click away. */
function StatusCard({
  view,
  onHistory,
  historyLabel,
}: {
  view: AppUpdateView;
  onHistory: () => void;
  historyLabel: string;
}) {
  const c = view.current;
  return (
    <div className="au-status">
      <div className="min-w-0">
        <p className="au-status__label">
          <FormattedMessage id="au.current" />
        </p>
        {c ? (
          <p className="au-status__line">
            <FormattedMessage
              id="au.currentLine"
              values={{
                version: <span className="mono">{c.version}</span>,
                at: new Date(c.publishedAt).toLocaleString('vi-VN'),
              }}
            />
            <span className="au-status__ranges">
              {platforms.map((p) => (
                <span key={p}>
                  {p === 'ios' ? 'iOS' : 'Android'}{' '}
                  <span className="mono">{range(c.config[p])}</span>
                </span>
              ))}
              <span>
                <FormattedMessage id="au.col.release" />{' '}
                <span className="mono">{c.config.release?.version ?? '—'}</span>
              </span>
            </span>
          </p>
        ) : (
          <p className="au-status__line muted">
            <FormattedMessage id="au.none" />
          </p>
        )}
      </div>
      <UiButton variant="outline" size="sm" onClick={onHistory} disabled={!view.history.length}>
        <History />
        {historyLabel}
      </UiButton>
    </div>
  );
}

function HistoryTable({ history }: { history: AppUpdateView['history'] }) {
  return (
    <TableScroll min={560}>
      <table className="table">
        <thead>
          <tr>
            <th>
              <FormattedMessage id="au.col.version" />
            </th>
            <th>
              <FormattedMessage id="au.col.at" />
            </th>
            <th>iOS</th>
            <th>Android</th>
            <th>
              <FormattedMessage id="au.col.release" />
            </th>
            <th>
              <FormattedMessage id="au.col.by" />
            </th>
          </tr>
        </thead>
        <tbody>
          {history.map((h) => (
            <tr key={h.version}>
              <td className="mono">{h.version}</td>
              <td className="nowrap">{new Date(h.publishedAt).toLocaleString('vi-VN')}</td>
              <td className="mono">{range(h.config.ios)}</td>
              <td className="mono">{range(h.config.android)}</td>
              <td className="mono">{h.config.release?.version ?? '—'}</td>
              <td>
                {h.byName}
                {h.reason && <div className="muted">{h.reason}</div>}
              </td>
            </tr>
          ))}
          {history.length === 0 && (
            <tr>
              <td colSpan={6} className="muted">
                <FormattedMessage id="au.historyEmpty" />
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </TableScroll>
  );
}

/** "1.0.5 → 1.2.0": minimum → latest. */
const range = (p: AppUpdatePlatform) => (p.latest ? `${p.minimum ?? '—'} → ${p.latest}` : '—');

/** zod messages and paths → message ids. */
function issueId(message: string, path: PropertyKey[]): string {
  if (message === 'minimum-above-latest') return 'au.err.minimumAboveLatest';
  if (message === 'store-url-required') return 'au.err.storeUrl';
  if (message === 'store' || path.includes('storeUrl')) return 'au.err.storeUrlHost';
  if (path.includes('latest') || path.includes('minimum') || path.includes('version'))
    return 'au.err.version';
  const last = path[path.length - 1];
  if (last === 'vi' || last === 'en') return 'au.err.loc';
  if (path[0] === 'release') return 'au.err.release';
  return 'au.err.other';
}

export function raisedMinimum(before: AppUpdatePlatform | null, after: AppUpdatePlatform) {
  return (
    !!after.minimum && (!before?.minimum || compareAppVersions(after.minimum, before.minimum) > 0)
  );
}

type ErrorAt = (prefix: PropertyKey[]) => string | null;

/** Both stores in one table: the same three questions for iOS and Android. */
function VersionsPanel({
  config,
  published,
  readOnly,
  errorAt,
  rulesAt,
  onChange,
}: {
  config: AppUpdateConfig;
  published: AppUpdateConfig | null;
  readOnly: boolean;
  errorAt: ErrorAt;
  rulesAt: (path: PropertyKey[]) => string[];
  onChange: (p: PlatformKey, v: AppUpdatePlatform) => void;
}) {
  const intl = useIntl();
  return (
    <Panel
      title={<FormattedMessage id="au.versions" />}
      note={<FormattedMessage id="au.versionsNote" />}
    >
      <div className="au-versions">
        <div className="au-versions__head" aria-hidden="true">
          <span />
          <span>
            <FormattedMessage id="au.latest" />
          </span>
          <span>
            <FormattedMessage id="au.minimum" />
          </span>
          <span>
            <FormattedMessage id="au.storeUrl" />
          </span>
        </div>
        {platforms.map((p) => {
          const value = config[p];
          const set = (k: keyof AppUpdatePlatform, v: string) =>
            onChange(p, { ...value, [k]: v.trim() === '' ? null : v.trim() });
          // The object-level rules (minimum ≤ latest, a link for a latest) both sit at [p].
          const rules = rulesAt([p]);
          const ruleOn = (k: keyof AppUpdatePlatform) =>
            k === 'minimum' && rules.includes('au.err.minimumAboveLatest')
              ? 'au.err.minimumAboveLatest'
              : k === 'storeUrl' && rules.includes('au.err.storeUrl')
                ? 'au.err.storeUrl'
                : null;
          const field = (k: keyof AppUpdatePlatform, placeholder: string) => (
            <TextField
              label={intl.formatMessage({ id: `au.${k}` })}
              labelClassName="au-versions__label"
              value={value[k] ?? ''}
              mono
              placeholder={placeholder}
              readOnly={readOnly}
              error={errorAt([p, k]) ?? ruleOn(k)}
              onChange={(v) => set(k, v)}
            />
          );
          return (
            <div key={p} className="au-versions__row" role="group" aria-label={platformName[p]}>
              <div className="au-versions__name">
                <strong>{platformName[p]}</strong>
                {raisedMinimum(published?.[p] ?? null, value) && (
                  <Pill tone="error">
                    <FormattedMessage id="au.blocks" values={{ version: value.minimum }} />
                  </Pill>
                )}
              </div>
              {field('latest', '1.2.0')}
              {field('minimum', '1.0.0')}
              {field(
                'storeUrl',
                p === 'ios' ? 'https://apps.apple.com/…' : 'https://play.google.com/…',
              )}
            </div>
          );
        })}
      </div>
      <dl className="au-legend">
        <dt>
          <FormattedMessage id="au.latest" />
        </dt>
        <dd>
          <FormattedMessage id="au.latestHelp" />
        </dd>
        <dt>
          <FormattedMessage id="au.minimum" />
        </dt>
        <dd>
          <FormattedMessage id="au.minimumHelp" />
        </dd>
        <dt>
          <FormattedMessage id="au.storeUrl" />
        </dt>
        <dd>
          <FormattedMessage id="au.storeUrlHelp.ios" />{' '}
          <FormattedMessage id="au.storeUrlHelp.android" />
        </dd>
      </dl>
    </Panel>
  );
}

const blankText: AppUpdateText = { vi: '', en: '' };
const blankRelease = (): AppUpdateRelease => ({
  version: '',
  summary: { ...blankText },
  highlights: [],
  pages: [],
});

function ReleasePanel({
  value,
  readOnly,
  errorAt,
  onChange,
}: {
  value: AppUpdateRelease | null;
  readOnly: boolean;
  errorAt: ErrorAt;
  onChange: (v: AppUpdateRelease | null) => void;
}) {
  const intl = useIntl();
  const [open, setOpen] = useState(0);
  const switchId = useId();
  return (
    <>
      <Panel
        title={<FormattedMessage id="au.release" />}
        note={<FormattedMessage id="au.releaseNote" />}
        aside={
          <label className="check-row" htmlFor={switchId}>
            <Switch
              id={switchId}
              checked={!!value}
              disabled={readOnly}
              onCheckedChange={(on) => onChange(on ? blankRelease() : null)}
            />
            <FormattedMessage id="au.releaseOn" />
          </label>
        }
      >
        {value ? (
          <div className="stack">
            <div className="au-release-version">
              <TextField
                label={<FormattedMessage id="au.releaseVersion" />}
                help={<FormattedMessage id="au.releaseVersionHelp" />}
                value={value.version}
                mono
                placeholder="1.2.0"
                readOnly={readOnly}
                error={errorAt(['release', 'version'])}
                onChange={(version) => onChange({ ...value, version: version.trim() })}
              />
            </div>
            <LocField
              label={<FormattedMessage id="au.summary" />}
              help={<FormattedMessage id="au.summaryHelp" />}
              value={value.summary}
              max={appUpdateLimits.summary}
              readOnly={readOnly}
              error={errorAt(['release', 'summary'])}
              onChange={(summary) => onChange({ ...value, summary })}
            />
          </div>
        ) : (
          <p className="muted">
            <FormattedMessage id="au.releaseOff" />
          </p>
        )}
      </Panel>

      {value && (
        <Panel
          title={
            <FormattedMessage
              id="au.highlightsCount"
              values={{ n: value.highlights.length, max: appUpdateLimits.highlights }}
            />
          }
          note={<FormattedMessage id="au.highlightsHelp" />}
          aside={
            !readOnly &&
            value.highlights.length < appUpdateLimits.highlights && (
              <Button
                onClick={() => {
                  setOpen(value.highlights.length);
                  onChange({
                    ...value,
                    highlights: [
                      ...value.highlights,
                      {
                        icon: 'spark',
                        tone: 'mint',
                        title: { ...blankText },
                        body: { ...blankText },
                      },
                    ],
                  });
                }}
              >
                <FormattedMessage id="au.highlightAdd" />
              </Button>
            )
          }
        >
          {value.highlights.length === 0 ? (
            <p className="muted">
              <FormattedMessage id="au.highlightsEmpty" />
            </p>
          ) : (
            <div className="au-list">
              {value.highlights.map((h, i) => (
                <ListItem
                  key={i}
                  open={open === i}
                  onToggle={() => setOpen(open === i ? -1 : i)}
                  lead={<AppIcon name={h.icon} size={18} />}
                  title={h.title.vi || intl.formatMessage({ id: 'au.untitled' })}
                  kicker={intl.formatMessage({ id: 'au.highlightN' }, { n: i + 1 })}
                  invalid={!!errorAt(['release', 'highlights', i])}
                  actions={
                    !readOnly && (
                      <IconButton
                        icon="remove"
                        label={intl.formatMessage({ id: 'au.remove' })}
                        onClick={() =>
                          onChange({
                            ...value,
                            highlights: value.highlights.filter((_, j) => j !== i),
                          })
                        }
                      />
                    )
                  }
                >
                  <HighlightFields
                    value={h}
                    readOnly={readOnly}
                    errorAt={(p) => errorAt(['release', 'highlights', i, ...p])}
                    onChange={(next) =>
                      onChange({
                        ...value,
                        highlights: value.highlights.map((x, j) => (j === i ? next : x)),
                      })
                    }
                  />
                </ListItem>
              ))}
            </div>
          )}
        </Panel>
      )}
    </>
  );
}

function HighlightFields({
  value,
  readOnly,
  errorAt,
  onChange,
}: {
  value: AppUpdateHighlight;
  readOnly: boolean;
  errorAt: (path: PropertyKey[]) => string | null;
  onChange: (v: AppUpdateHighlight) => void;
}) {
  const intl = useIntl();
  return (
    <div className="stack">
      <div className="au-pair">
        <SelectField
          label={<FormattedMessage id="au.icon" />}
          value={value.icon}
          options={appUpdateIcons.map((i) => ({ value: i, label: i }))}
          readOnly={readOnly}
          onChange={(icon) => onChange({ ...value, icon: icon as AppUpdateHighlight['icon'] })}
        />
        <SelectField
          label={<FormattedMessage id="au.tone" />}
          value={value.tone}
          options={appUpdateTones.map((t) => ({
            value: t,
            label: intl.formatMessage({ id: `au.tone.${t}` }),
          }))}
          readOnly={readOnly}
          onChange={(tone) => onChange({ ...value, tone: tone as AppUpdateHighlight['tone'] })}
        />
      </div>
      <LocField
        label={<FormattedMessage id="au.itemTitle" />}
        value={value.title}
        max={appUpdateLimits.title}
        readOnly={readOnly}
        error={errorAt(['title'])}
        onChange={(title) => onChange({ ...value, title })}
      />
      <LocField
        label={<FormattedMessage id="au.itemBody" />}
        value={value.body}
        max={appUpdateLimits.highlightBody}
        readOnly={readOnly}
        error={errorAt(['body'])}
        onChange={(body) => onChange({ ...value, body })}
      />
    </div>
  );
}

function PagesPanel({
  value,
  images,
  readOnly,
  errorAt,
  onImage,
  onChange,
  onTurnOn,
}: {
  value: AppUpdateRelease | null;
  images: FirstAidImage[];
  readOnly: boolean;
  errorAt: ErrorAt;
  onImage: (img: FirstAidImage) => void;
  onChange: (v: AppUpdateRelease) => void;
  onTurnOn: () => void;
}) {
  const intl = useIntl();
  const [open, setOpen] = useState(0);
  if (!value) {
    return (
      <Panel title={<FormattedMessage id="au.pages" />}>
        <div className="stack">
          <p className="muted">
            <FormattedMessage id="au.pagesNeedRelease" />
          </p>
          <div className="actions">
            <Button onClick={onTurnOn}>
              <FormattedMessage id="au.tab.release" />
            </Button>
          </div>
        </div>
      </Panel>
    );
  }
  const move = (from: number, to: number) => {
    const pages = [...value.pages];
    const [item] = pages.splice(from, 1);
    pages.splice(to, 0, item!);
    onChange({ ...value, pages });
    setOpen(to);
  };
  return (
    <Panel
      title={
        <FormattedMessage
          id="au.pagesCount"
          values={{ n: value.pages.length, max: appUpdateLimits.pages }}
        />
      }
      note={<FormattedMessage id="au.pagesHelp" />}
      aside={
        !readOnly &&
        value.pages.length < appUpdateLimits.pages && (
          <Button
            onClick={() => {
              setOpen(value.pages.length);
              onChange({
                ...value,
                pages: [
                  ...value.pages,
                  { image: null, title: { ...blankText }, body: { ...blankText }, where: null },
                ],
              });
            }}
          >
            <FormattedMessage id="au.pageAdd" />
          </Button>
        )
      }
    >
      {value.pages.length === 0 ? (
        <p className="muted">
          <FormattedMessage id="au.pagesEmpty" />
        </p>
      ) : (
        <div className="au-list">
          {value.pages.map((p, i) => {
            const url = images.find((img) => img.id === p.image)?.url;
            return (
              <ListItem
                key={i}
                open={open === i}
                onToggle={() => setOpen(open === i ? -1 : i)}
                lead={
                  url ? (
                    <img className="au-list__thumb" src={url} alt="" />
                  ) : (
                    <span className="au-list__thumb au-list__thumb--empty" />
                  )
                }
                title={p.title.vi || intl.formatMessage({ id: 'au.untitled' })}
                kicker={intl.formatMessage({ id: 'au.pageN' }, { n: i + 1 })}
                invalid={!!errorAt(['release', 'pages', i])}
                actions={
                  !readOnly && (
                    <>
                      <IconButton
                        icon="up"
                        label={intl.formatMessage({ id: 'au.moveUp' })}
                        disabled={i === 0}
                        onClick={() => move(i, i - 1)}
                      />
                      <IconButton
                        icon="down"
                        label={intl.formatMessage({ id: 'au.moveDown' })}
                        disabled={i === value.pages.length - 1}
                        onClick={() => move(i, i + 1)}
                      />
                      <IconButton
                        icon="remove"
                        label={intl.formatMessage({ id: 'au.remove' })}
                        onClick={() =>
                          onChange({ ...value, pages: value.pages.filter((_, j) => j !== i) })
                        }
                      />
                    </>
                  )
                }
              >
                <PageFields
                  value={p}
                  images={images}
                  url={url}
                  readOnly={readOnly}
                  errorAt={(path) => errorAt(['release', 'pages', i, ...path])}
                  onImage={onImage}
                  onChange={(next) =>
                    onChange({ ...value, pages: value.pages.map((x, j) => (j === i ? next : x)) })
                  }
                />
              </ListItem>
            );
          })}
        </div>
      )}
    </Panel>
  );
}

function PageFields({
  value,
  images,
  url,
  readOnly,
  errorAt,
  onImage,
  onChange,
}: {
  value: AppUpdatePage;
  images: FirstAidImage[];
  url: string | undefined;
  readOnly: boolean;
  errorAt: (path: PropertyKey[]) => string | null;
  onImage: (img: FirstAidImage) => void;
  onChange: (v: AppUpdatePage) => void;
}) {
  return (
    <div className="stack">
      <div className="au-page">
        <div className="au-page__image">
          {url ? (
            <img src={url} alt="" />
          ) : (
            <span className="muted">
              <FormattedMessage id="au.noImage" />
            </span>
          )}
        </div>
        <div className="stack">
          <SelectField
            label={<FormattedMessage id="au.image" />}
            value={value.image ?? ''}
            options={[
              { value: '', label: '—' },
              ...images.map((i) => ({ value: i.id, label: i.id })),
            ]}
            readOnly={readOnly}
            onChange={(image) => onChange({ ...value, image: image || null })}
          />
          {!readOnly && (
            <ImageUpload
              onUploaded={(img) => {
                onImage(img);
                onChange({ ...value, image: img.id });
              }}
            />
          )}
        </div>
      </div>
      <LocField
        label={<FormattedMessage id="au.itemTitle" />}
        value={value.title}
        max={appUpdateLimits.title}
        readOnly={readOnly}
        error={errorAt(['title'])}
        onChange={(title) => onChange({ ...value, title })}
      />
      <LocField
        label={<FormattedMessage id="au.pageBody" />}
        value={value.body}
        max={appUpdateLimits.pageBody}
        multiline
        readOnly={readOnly}
        error={errorAt(['body'])}
        onChange={(body) => onChange({ ...value, body })}
      />
      <LocField
        label={<FormattedMessage id="au.where" />}
        help={<FormattedMessage id="au.whereHelp" />}
        value={value.where ?? blankText}
        max={appUpdateLimits.where}
        readOnly={readOnly}
        error={errorAt(['where'])}
        onChange={(where) => onChange({ ...value, where: where.vi || where.en ? where : null })}
      />
    </div>
  );
}

/** One row of a list that opens to its fields: the list stays short, one item edits at a time. */
function ListItem({
  open,
  onToggle,
  lead,
  kicker,
  title,
  invalid,
  actions,
  children,
}: {
  open: boolean;
  onToggle: () => void;
  lead: ReactNode;
  kicker: string;
  title: string;
  invalid: boolean;
  actions?: ReactNode;
  children: ReactNode;
}) {
  const bodyId = useId();
  return (
    <div className={cn('au-item', open && 'au-item--open', invalid && 'au-item--invalid')}>
      <div className="au-item__head">
        <button
          type="button"
          className="au-item__toggle"
          aria-expanded={open}
          aria-controls={bodyId}
          onClick={onToggle}
        >
          <ChevronRight className="au-item__chevron size-4" aria-hidden="true" />
          {lead}
          <span className="min-w-0">
            <span className="au-item__kicker">{kicker}</span>
            <span className="au-item__title">{title}</span>
          </span>
        </button>
        {actions && <div className="au-item__actions">{actions}</div>}
      </div>
      {open && (
        <div className="au-item__body" id={bodyId}>
          {children}
        </div>
      )}
    </div>
  );
}

function ImageUpload({ onUploaded }: { onUploaded: (img: FirstAidImage) => void }) {
  const api = useApi();
  const id = useId();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  return (
    <div className="field">
      <label className="field__label" htmlFor={id}>
        <FormattedMessage id="au.upload" />
      </label>
      <FilePicker
        id={id}
        accept="image/png,image/jpeg,image/webp"
        disabled={busy}
        onFile={(file) => {
          if (!file) return;
          const name =
            file.name
              .toLowerCase()
              .replace(/\.[a-z0-9]+$/, '')
              .replace(/[^a-z0-9-]+/g, '-')
              .replace(/^-+|-+$/g, '')
              .slice(0, 40) || 'anh';
          setBusy(true);
          setError(null);
          fileToBase64(file)
            .then((data) =>
              api.call<FirstAidImage>('staffAppUpdateImage', {
                name: name.length >= 2 ? name : `anh-${name}`,
                data,
              }),
            )
            .then(onUploaded)
            .catch((err: unknown) =>
              setError(err instanceof ApiError ? err : new ApiError('unknown', null)),
            )
            .finally(() => setBusy(false));
        }}
      />
      {busy && (
        <p className="field__help">
          <FormattedMessage id="au.uploading" />
        </p>
      )}
      {error && (
        <p className="error" role="alert">
          <FormattedMessage id={errorMessageId(error)} />
        </p>
      )}
    </div>
  );
}

/** What changes, side by side, before it is published (no reason: D-090). */
function PublishModal({
  before,
  after,
  onClose,
  onDone,
}: {
  before: AppUpdateConfig | null;
  after: AppUpdateConfig;
  onClose: () => void;
  onDone: () => void;
}) {
  const api = useApi();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const blocks = platforms.filter((p) => raisedMinimum(before?.[p] ?? null, after[p]));
  const rows: Array<{ key: string; label: ReactNode; was: string; next: string }> = [
    ...platforms.map((p) => ({
      key: p,
      label: p === 'ios' ? 'iOS' : 'Android',
      was: before ? range(before[p]) : '—',
      next: range(after[p]),
    })),
    {
      key: 'release',
      label: <FormattedMessage id="au.col.release" />,
      was: before?.release?.version ?? '—',
      next: after.release?.version ?? '—',
    },
    {
      key: 'snooze',
      label: <FormattedMessage id="au.snoozeDays" />,
      was: before ? String(before.snoozeDays) : '—',
      next: String(after.snoozeDays),
    },
  ];
  return (
    <Modal title={<FormattedMessage id="au.confirmTitle" />} onClose={onClose}>
      <table className="table au-diff">
        <thead>
          <tr>
            <th />
            <th>
              <FormattedMessage id="au.diff.now" />
            </th>
            <th>
              <FormattedMessage id="au.diff.next" />
            </th>
          </tr>
        </thead>
        <tbody>
          {rows.map((r) => (
            <tr key={r.key} className={r.was !== r.next ? 'au-diff__changed' : undefined}>
              <th scope="row">{r.label}</th>
              <td className="mono">{r.was}</td>
              <td className="mono">{r.next}</td>
            </tr>
          ))}
        </tbody>
      </table>
      {blocks.map((p) => (
        <p key={p} className="note note--warn" role="alert">
          <FormattedMessage
            id="au.confirmBlocks"
            values={{ platform: p === 'ios' ? 'iOS' : 'Android', version: after[p].minimum }}
          />
        </p>
      ))}
      {error && (
        <p className="error" role="alert">
          <FormattedMessage id={errorMessageId(error)} />
        </p>
      )}
      <div className="modal__actions">
        <Button onClick={onClose}>
          <FormattedMessage id="au.cancel" />
        </Button>
        <Button
          kind={blocks.length ? 'danger' : 'primary'}
          disabled={busy}
          onClick={() => {
            setBusy(true);
            api
              .call('staffAppUpdateSave', { config: after })
              .then(onDone)
              .catch((e: unknown) =>
                setError(e instanceof ApiError ? e : new ApiError('unknown', null)),
              )
              .finally(() => setBusy(false));
          }}
        >
          <FormattedMessage id="au.publishNow" />
        </Button>
      </div>
    </Modal>
  );
}

// ---------- Fields ----------

function TextField({
  label,
  labelClassName,
  help,
  value,
  mono,
  placeholder,
  readOnly,
  error,
  onChange,
}: {
  label: ReactNode;
  /** The versions table hides it behind its column header when it is a table. */
  labelClassName?: string;
  help?: ReactNode;
  value: string;
  mono?: boolean;
  placeholder?: string;
  readOnly: boolean;
  error?: string | null;
  onChange: (v: string) => void;
}) {
  const id = useId();
  return (
    <div className="field">
      <label className={cn('field__label', labelClassName)} htmlFor={id}>
        {label}
      </label>
      <input
        id={id}
        className={cn('field__input', mono && 'mono')}
        value={value}
        placeholder={placeholder}
        readOnly={readOnly}
        aria-invalid={!!error || undefined}
        aria-describedby={error ? `${id}-error` : undefined}
        onChange={(e) => onChange(e.target.value)}
      />
      {error && (
        <p className="field__error" id={`${id}-error`}>
          <FormattedMessage id={error} />
        </p>
      )}
      {help && <p className="field__help">{help}</p>}
    </div>
  );
}

function NumberField({
  label,
  value,
  min,
  max,
  readOnly,
  onChange,
}: {
  label: ReactNode;
  value: number;
  min: number;
  max: number;
  readOnly: boolean;
  onChange: (v: number) => void;
}) {
  const id = useId();
  return (
    <div className="field au-number">
      <label className="field__label" htmlFor={id}>
        {label}
      </label>
      <input
        id={id}
        type="number"
        className="field__input"
        min={min}
        max={max}
        value={value}
        readOnly={readOnly}
        onChange={(e) => onChange(Math.round(Number(e.target.value)))}
      />
    </div>
  );
}

function SelectField({
  label,
  value,
  options,
  readOnly,
  onChange,
}: {
  label: ReactNode;
  value: string;
  options: Array<{ value: string; label: string }>;
  readOnly: boolean;
  onChange: (v: string) => void;
}) {
  const id = useId();
  return (
    <div className="field">
      <label className="field__label" htmlFor={id}>
        {label}
      </label>
      <FieldSelect
        id={id}
        value={value}
        options={options}
        disabled={readOnly}
        onChange={onChange}
      />
    </div>
  );
}

/** Vietnamese and English (D-012): side by side when there is room, stacked when not. */
function LocField({
  label,
  help,
  value,
  max,
  multiline,
  readOnly,
  error,
  onChange,
}: {
  label: ReactNode;
  help?: ReactNode;
  value: AppUpdateText;
  max: number;
  multiline?: boolean;
  readOnly: boolean;
  error?: string | null;
  onChange: (v: AppUpdateText) => void;
}) {
  const id = useId();
  const input = (lang: 'vi' | 'en') => {
    const props = {
      id: `${id}-${lang}`,
      className: 'field__input',
      value: value[lang],
      maxLength: max,
      readOnly,
      'aria-invalid': (!!error && !value[lang].trim()) || undefined,
      onChange: (e: { target: { value: string } }) =>
        onChange({ ...value, [lang]: e.target.value }),
    };
    return multiline ? <textarea rows={3} {...props} /> : <input {...props} />;
  };
  return (
    <fieldset className="au-loc">
      <legend className="field__label">{label}</legend>
      <div className="au-loc__grid">
        {(['vi', 'en'] as const).map((lang) => (
          <div className="field" key={lang}>
            <label className="au-loc__lang" htmlFor={`${id}-${lang}`}>
              <span>{lang === 'vi' ? 'Tiếng Việt' : 'English'}</span>
              <span>
                {value[lang].length}/{max}
              </span>
            </label>
            {input(lang)}
          </div>
        ))}
      </div>
      {error && (
        <p className="field__error">
          <FormattedMessage id={error} />
        </p>
      )}
      {help && <p className="field__help">{help}</p>}
    </fieldset>
  );
}
