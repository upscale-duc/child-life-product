import {
  keepsakeBrandSvg,
  resolveKeepsakeCopy,
  keepsakePersonalizationSchema,
  keepsakeCatalogSchema,
  keepsakeCompositions,
  defaultKeepsakeVideoBrand,
  keepsakeFormats,
  keepsakeLayerSchema,
  keepsakeLicenceKinds,
  keepsakeLimits,
  keepsakeMoods,
  keepsakeSeedV1,
  keepsakeTemplateAssets,
  keepsakeTemplateSchema,
  occasionIds,
  staffCan,
  type KeepsakeCatalog,
  type KeepsakeFormat,
  type KeepsakeLayer,
  type KeepsakeMusic,
  type KeepsakeTemplate,
} from '@child-life/contracts';
import { getApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getStorage, ref as storageRef, uploadBytes } from 'firebase/storage';
import { Music, Pause, Play, Plus } from 'lucide-react';
import { useEffect, useId, useMemo, useRef, useState, type CSSProperties } from 'react';
import { FormattedMessage, useIntl, type IntlShape } from 'react-intl';
import { ApiError, useApi, useLoad, type Api } from '../api';
import { SearchInput, VersionBadge } from '../content-kit';
import { routePaths, subPath, useStaff } from '../context';
import { ZONE } from '../format';
import {
  Button,
  Empty,
  Loaded,
  Modal,
  Page,
  Panel,
  NotesField,
  Pill,
  RejectedBy,
  Segmented,
  TableScroll,
  errorMessageId,
  type PillTone,
} from '../ui';
import { fileToBase64 } from './FirstAidEditor';
import { CheckRow, FieldSelect, FilePicker } from './form-controls';

/**
 * Mẫu kỷ niệm (D-068 #7, #8; plan `docs/product/remember-2-plan.md` §4.1). The catalog the app's
 * Thiệp cột mốc and Video kỷ niệm read, edited here as one draft and published the Sơ cứu way:
 * "Sửa" opens a working copy, "Lưu nháp" saves it, "Gửi duyệt" hands it to a different person
 * with "Nội dung · Duyệt", whose approval publishes `publicConfig/keepsakes` and gives every
 * changed template its next version. Template pictures and music are uploaded here (Thư viện);
 * nothing about a template is built into the app. Miễn phí / Cao cấp is set per template and,
 * for the whole catalog, whether Cao cấp is open to everyone (the beta) or hidden.
 */

export type KeepsakeStatus = 'draft' | 'pending' | 'published' | 'retired' | 'discarded';

export interface KeepsakeVersion {
  versionId: string;
  status: KeepsakeStatus;
  label: string | null;
  notes: string;
  authorName: string;
  approverName: string | null;
  createdAt: string | null;
  updatedAt: string | null;
  approvedAt: string | null;
  rejection: { by: string; reason: string } | null;
  /** The published version the draft was made from (null: unknown, older drafts). */
  basedOn?: string | null;
  templates: number;
}

export interface KeepsakeAsset {
  asset: string;
  url: string;
}

export interface KeepsakeView {
  current: { version: string; publishedAt: string; catalog: KeepsakeCatalog } | null;
  draft: (KeepsakeVersion & { status: 'draft' | 'pending'; catalog: KeepsakeCatalog }) | null;
  history: KeepsakeVersion[];
  assets: KeepsakeAsset[];
  /** Videos exported per video template id (absent: none yet; cards are not counted). */
  usage?: Record<string, { exports: number; exports30d: number }>;
  /** More jobs than the server scans: the all-time counts are a floor. */
  usageCapped?: boolean;
}

const tabs = ['templates', 'music', 'files', 'settings', 'history'] as const;
export type KeepsakeTab = (typeof tabs)[number];
type TemplateSort = 'newest' | 'display' | 'exports';

/** How often a template was used, from the server view when it sends it (backend, 2026-10-21). */
export interface TemplateUsage {
  /** Videos (cards) exported with the template, all time. */
  exports: number;
  /** The same over the last 30 days; null when the server does not count it. */
  exports30d: number | null;
}

/**
 * Per-template exports from `staffKeepsakes`, read defensively: `usage` (or `templateUsage`) as
 * `{ [templateId]: { exports, exports30d } }` or as a list of `{ templateId | id, exports,
 * exports30d }`. Null when the server sends none, and the "Video xuất nhiều nhất" sort is hidden.
 */
export function templateUsageOf(view: unknown): Map<string, TemplateUsage> | null {
  const v = view as { usage?: unknown; templateUsage?: unknown } | null;
  const raw = v?.usage ?? v?.templateUsage;
  if (!raw || typeof raw !== 'object') return null;
  const entries: Array<[unknown, unknown]> = Array.isArray(raw)
    ? raw.map((r) => [
        (r as { templateId?: unknown; id?: unknown })?.templateId ?? (r as { id?: unknown })?.id,
        r,
      ])
    : Object.entries(raw);
  const count = (x: unknown) => (typeof x === 'number' && Number.isFinite(x) && x >= 0 ? x : null);
  const out = new Map<string, TemplateUsage>();
  for (const [id, r] of entries) {
    const u = r as { exports?: unknown; exports30d?: unknown } | null;
    const exports = count(u?.exports);
    if (typeof id === 'string' && exports !== null) {
      out.set(id, { exports, exports30d: count(u?.exports30d) });
    }
  }
  return out.size ? out : null;
}

/** "/keepsakes/templates/<id>": one template open (the browser's back returns to the list). */
export const keepsakeTemplateUrl = (id: string) =>
  `${routePaths.keepsakes}/templates/${encodeURIComponent(id)}`;

function templateIdInUrl(): string | null {
  if (typeof window === 'undefined') return null;
  const [part, id] = subPath('keepsakes', window.location.pathname);
  return part === 'templates' && id ? id : null;
}

type Act = 'submit' | 'approve' | 'reject' | 'discard' | 'rollback';
type Edit = (fn: (c: KeepsakeCatalog) => void) => void;

const statusTone: Record<string, PillTone> = {
  draft: 'muted',
  pending: 'wait',
  published: 'ok',
  retired: 'muted',
  discarded: 'muted',
};

const asApiError = (e: unknown) => (e instanceof ApiError ? e : new ApiError('unknown', null));

function dateTime(intl: IntlShape, iso: string | null | undefined): string {
  return iso
    ? intl.formatDate(iso, {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        timeZone: ZONE,
      })
    : '—';
}

const textOf = (intl: IntlShape, t: { vi: string; en: string } | null | undefined) =>
  t ? (intl.locale.startsWith('vi') ? t.vi : t.en) || t.vi : '';

/** Problems to fix before saving, as "path: message" lines. */
export function catalogIssues(c: KeepsakeCatalog): string[] {
  const r = keepsakeCatalogSchema.safeParse(c);
  if (r.success) return [];
  return r.error.issues.map((i) => {
    const [, at, ...rest] = i.path;
    const id = typeof at === 'number' ? c.templates[at]?.id : undefined;
    return `${id ? `${id} · ` : ''}${rest.join('.') || i.path.join('.')}: ${i.message}`;
  });
}

export function KeepsakesScreen() {
  const staff = useStaff();
  const [load, reload] = useLoad<KeepsakeView>('staffKeepsakes', {}, 'keepsakes');
  return (
    <Page title={<FormattedMessage id="ks.title" />}>
      <Loaded load={load} reload={reload}>
        {(view) => (
          <KeepsakesBody
            view={view}
            canEdit={staffCan(staff.levels, 'content.edit')}
            canApprove={staffCan(staff.levels, 'content.approve')}
            onChanged={reload}
          />
        )}
      </Loaded>
    </Page>
  );
}

export function KeepsakesBody({
  view,
  canEdit,
  canApprove,
  onChanged,
  initialTab = 'templates',
}: {
  view: KeepsakeView;
  canEdit: boolean;
  canApprove: boolean;
  onChanged: () => void;
  initialTab?: KeepsakeTab;
}) {
  const intl = useIntl();
  const d = view.draft;
  const [showDraft, setShowDraft] = useState(!!d);
  useEffect(() => setShowDraft(!!d), [d]);
  const [editing, setEditing] = useState<KeepsakeCatalog | null>(null);
  const [dirty, setDirty] = useState(false);
  // A template opened from its address ("/keepsakes/templates/<id>", a reload or a link).
  const [selected, setSelected] = useState<number | null>(() => {
    const id = templateIdInUrl();
    const list = (d?.catalog ?? view.current?.catalog)?.templates ?? [];
    const at = id ? list.findIndex((t) => t.id === id) : -1;
    return at >= 0 ? at : null;
  });
  const [dialog, setDialog] = useState<
    { act: Act; versionId: string } | 'save' | 'import' | { add: 'card' | 'video' } | null
  >(null);
  const [assets, setAssets] = useState(view.assets);
  useEffect(() => setAssets(view.assets), [view.assets]);
  const urls = useMemo(() => new Map(assets.map((a) => [a.asset, a.url])), [assets]);
  const addAssets = (added: KeepsakeAsset[]) =>
    setAssets((list) => [...added.filter((a) => !list.some((x) => x.asset === a.asset)), ...list]);
  const [tab, setTab] = useState<KeepsakeTab>(initialTab);
  const [templateSort, setTemplateSort] = useState<TemplateSort>('newest');
  const usage = useMemo(() => templateUsageOf(view), [view]);

  const shown: KeepsakeCatalog | null =
    editing ?? (showDraft && d ? d.catalog : (view.current?.catalog ?? null));
  const issues = useMemo(() => (editing ? catalogIssues(editing) : []), [editing]);
  const published = useMemo(
    () => new Map((view.current?.catalog.templates ?? []).map((t) => [t.id, t])),
    [view.current],
  );

  useEffect(() => {
    if (!editing || !dirty) return;
    const warn = (e: BeforeUnloadEvent) => e.preventDefault();
    window.addEventListener('beforeunload', warn);
    return () => window.removeEventListener('beforeunload', warn);
  }, [editing, dirty]);

  /** What a change starts from: the open draft, else the set in use. */
  const base = d?.catalog ?? view.current?.catalog ?? null;
  // No "Sửa" mode: editors change things directly; the first change opens a working copy
  // (the bar with Huỷ / Lưu nháp). Looking at the set in use while a draft is open stays read-only.
  const editable = canEdit && (!!editing || !d || showDraft);
  /**
   * The open draft was made from an older release than the one in use (another publish came
   * after it): approving it would undo that release, so the server refuses until it is updated.
   */
  const stale =
    !!d &&
    !!view.current &&
    (d.basedOn
      ? d.basedOn !== view.current.version
      : !!d.createdAt && Date.parse(d.createdAt) < Date.parse(view.current.publishedAt));
  /** The release the working copy comes from (sent with "Lưu nháp"); undefined: keep the draft's. */
  const [workingBase, setWorkingBase] = useState<string | null | undefined>(undefined);
  /** The draft brought up to the set in use: its own new templates and tracks are kept. */
  const rebase = () => {
    if (!d || !view.current) return;
    const next = structuredClone(view.current.catalog);
    for (const t of d.catalog.templates) {
      if (!next.templates.some((x) => x.id === t.id)) next.templates.push(structuredClone(t));
    }
    for (const m of d.catalog.music) {
      if (!next.music.some((x) => x.id === m.id)) next.music.push(structuredClone(m));
    }
    setEditing(next);
    setDirty(true);
    setWorkingBase(view.current.version);
    setShowDraft(true);
  };
  const edit: Edit = (fn) => {
    if (!editing) setWorkingBase(d ? undefined : (view.current?.version ?? null));
    setEditing((c) => {
      const from = c ?? base;
      if (!from) return c;
      const next = structuredClone(from);
      fn(next);
      return next;
    });
    setDirty(true);
  };
  // The open template is in the address bar like the other editors: the browser's back returns to
  // the list instead of leaving Mẫu kỷ niệm (owner, 2026-10-21).
  const templates = useRef<KeepsakeTemplate[]>([]);
  templates.current = shown?.templates ?? [];
  useEffect(() => {
    const onPop = () => {
      const id = templateIdInUrl();
      const at = id ? templates.current.findIndex((t) => t.id === id) : -1;
      setSelected(at >= 0 ? at : null);
      if (at >= 0) setTab('templates');
    };
    window.addEventListener('popstate', onPop);
    return () => window.removeEventListener('popstate', onPop);
  }, []);
  const openTemplate = (index: number, id: string) => {
    setSelected(index);
    const url = keepsakeTemplateUrl(id);
    if (window.location.pathname !== url) window.history.pushState({ ksTemplate: true }, '', url);
    window.scrollTo(0, 0);
  };
  /** Back to the list: one step back when the list opened it, else the list's address. */
  const closeTemplate = () => {
    setSelected(null);
    if (!templateIdInUrl()) return;
    const fromList = (window.history.state as { ksTemplate?: boolean } | null)?.ksTemplate;
    if (fromList) window.history.back();
    else window.history.replaceState({}, '', routePaths.keepsakes);
  };
  const addTemplate = (t: KeepsakeTemplate) => {
    const index = (editing ?? base)?.templates.length ?? 0;
    edit((c) => {
      c.templates.push(t);
    });
    setTab('templates');
    openTemplate(index, t.id);
  };
  const start = (from: KeepsakeCatalog) => {
    setEditing(structuredClone(from));
    setDirty(false);
  };
  const stop = () => {
    if (dirty && !window.confirm(intl.formatMessage({ id: 'ks.leaveConfirm' }))) return;
    setEditing(null);
    setDirty(false);
  };
  const template = selected === null ? null : (shown?.templates[selected] ?? null);
  const counts: Partial<Record<KeepsakeTab, number>> = {
    templates: shown?.templates.length,
    music: shown?.music.length,
    files: assets.length,
    history: view.history.length,
  };

  return (
    <div className="stack">
      <div className="toolbar">
        <span className="chips">
          {/* The catalog in use as a badge; when and how many templates are in its popover. */}
          <VersionBadge
            version={view.current?.version ?? null}
            details={
              view.current
                ? [
                    intl.formatMessage(
                      { id: 'ks.publishedAt' },
                      {
                        when: dateTime(intl, view.current.publishedAt),
                        n: view.current.catalog.templates.length,
                      },
                    ),
                  ]
                : []
            }
          />
          {d && (
            <>
              <Pill tone={statusTone[d.status] ?? 'muted'}>
                <FormattedMessage id={`ks.status.${d.status}`} />
              </Pill>
              <span className="muted">
                <FormattedMessage
                  id="ks.draftBy"
                  values={{ name: d.authorName, when: dateTime(intl, d.updatedAt) }}
                />
              </span>
            </>
          )}
        </span>
        <span className="chips">
          {d && view.current && !editing && (
            <Button kind="ghost" onClick={() => setShowDraft(!showDraft)}>
              <FormattedMessage id={showDraft ? 'ks.showCurrent' : 'ks.showDraft'} />
            </Button>
          )}
          {editable && shown && (
            <Button kind="primary" onClick={() => setDialog({ add: 'card' })}>
              <Plus size={16} aria-hidden /> <FormattedMessage id="ks.new" />
            </Button>
          )}
          {canEdit && !editing && d?.status === 'draft' && (
            <>
              <Button onClick={() => setDialog({ act: 'submit', versionId: d.versionId })}>
                <FormattedMessage id="ks.act.submit" />
              </Button>
              <Button
                kind="danger"
                onClick={() => setDialog({ act: 'discard', versionId: d.versionId })}
              >
                <FormattedMessage id="ks.act.discard" />
              </Button>
            </>
          )}
          {canApprove && !editing && d?.status === 'pending' && (
            <>
              <Button
                kind="primary"
                disabled={stale}
                onClick={() => setDialog({ act: 'approve', versionId: d.versionId })}
              >
                <FormattedMessage id="ks.act.approve" />
              </Button>
              <Button onClick={() => setDialog({ act: 'reject', versionId: d.versionId })}>
                <FormattedMessage id="ks.act.reject" />
              </Button>
            </>
          )}
        </span>
      </div>
      {canEdit && !editable && (
        <p className="ks-hint">
          <FormattedMessage id="ks.viewingCurrent" />
        </p>
      )}
      {stale && !editing && view.current && (
        <div className="ks-stale" role="alert">
          <p>
            <FormattedMessage
              id="ks.stale"
              values={{ v: view.current.version, when: dateTime(intl, view.current.publishedAt) }}
            />
          </p>
          {canEdit && (
            <Button kind="primary" onClick={rebase}>
              <FormattedMessage id="ks.rebase" />
            </Button>
          )}
        </div>
      )}
      {d?.rejection && (
        <p className="error">
          <RejectedBy id="ks.rejected" by={d.rejection.by} reason={d.rejection.reason} />
        </p>
      )}

      {editing && (
        <Panel className="ks-editbar">
          <div className="toolbar">
            <strong>
              <FormattedMessage id="ks.editing" />
            </strong>
            <span className="chips">
              <Button onClick={stop}>
                <FormattedMessage id="action.cancel" />
              </Button>
              <Button kind="primary" disabled={issues.length > 0} onClick={() => setDialog('save')}>
                <FormattedMessage id="ks.saveDraft" />
              </Button>
            </span>
          </div>
          {issues.length > 0 && (
            <div role="alert">
              <p className="error">
                <FormattedMessage id="ks.issues" values={{ n: issues.length }} />
              </p>
              <ul className="ks-issues mono">
                {issues.slice(0, 12).map((i) => (
                  <li key={i}>{i}</li>
                ))}
              </ul>
            </div>
          )}
        </Panel>
      )}

      {!shown ? (
        <Panel>
          <Empty>
            <FormattedMessage id={canEdit ? 'ks.emptyEdit' : 'ks.empty'} />
          </Empty>
          {canEdit && (
            <Button kind="primary" onClick={() => start(keepsakeSeedV1)}>
              <FormattedMessage id="ks.startSeed" />
            </Button>
          )}
        </Panel>
      ) : (
        <>
          <Segmented
            label={intl.formatMessage({ id: 'ks.title' })}
            value={tab}
            onChange={(v) => {
              setTab(v);
              setSelected(null);
              if (templateIdInUrl()) window.history.replaceState({}, '', routePaths.keepsakes);
            }}
            options={tabs.map((v) => ({
              value: v,
              label: (
                <>
                  <FormattedMessage id={`ks.tab.${v}`} />
                  {counts[v] !== undefined && <span className="ks-tabcount">{counts[v]}</span>}
                </>
              ),
            }))}
          />
          {tab === 'templates' &&
            (template ? (
              <TemplateEditor
                key={template.id}
                template={template}
                index={selected!}
                editing={editable}
                edit={edit}
                published={published.get(template.id) ?? null}
                urls={urls}
                assets={assets}
                musicOptions={shown.music}
                onUploaded={addAssets}
                onBack={closeTemplate}
              />
            ) : (
              <TemplateGallery
                catalog={shown}
                sort={templateSort}
                onSort={setTemplateSort}
                editing={editable}
                onAdd={(kind) => setDialog({ add: kind })}
                onImport={() => setDialog('import')}
                published={published}
                urls={urls}
                usage={usage}
                onOpen={(index) => openTemplate(index, shown.templates[index]!.id)}
              />
            ))}
          {tab === 'music' && (
            <MusicPanel catalog={shown} editing={editable} edit={edit} assets={assets} />
          )}
          {tab === 'files' && (
            <AssetLibrary
              assets={assets}
              catalog={shown}
              canUpload={canEdit}
              onUploaded={addAssets}
            />
          )}
          {tab === 'settings' && <PremiumPanel catalog={shown} editing={editable} edit={edit} />}
        </>
      )}

      {tab === 'history' && (
        <HistoryPanel
          view={view}
          canApprove={canApprove}
          onRollback={(versionId) => setDialog({ act: 'rollback', versionId })}
        />
      )}

      {dialog === 'save' && editing && (
        <SaveDialog
          catalog={editing}
          basedOn={workingBase}
          notes={d?.notes ?? ''}
          pending={d?.status === 'pending'}
          onClose={() => setDialog(null)}
          onDone={() => {
            setEditing(null);
            setDirty(false);
            onChanged();
          }}
        />
      )}
      {dialog === 'import' && (
        <ImportDialog
          catalog={editing ?? base ?? shown ?? keepsakeSeedV1}
          assets={assets}
          onClose={() => setDialog(null)}
          onImport={(templates) => {
            setDialog(null);
            edit((c) => {
              for (const t of templates) {
                const i = c.templates.findIndex((x) => x.id === t.id);
                if (i >= 0) c.templates[i] = t;
                else c.templates.push(t);
              }
            });
            setTab('templates');
          }}
        />
      )}
      {dialog && typeof dialog === 'object' && 'add' in dialog && shown && (
        <NewTemplateDialog
          kind={dialog.add}
          catalog={editing ?? base ?? shown}
          onClose={() => setDialog(null)}
          onCreate={(t) => {
            setDialog(null);
            addTemplate(t);
          }}
        />
      )}
      {dialog && typeof dialog === 'object' && 'act' in dialog && (
        <ActDialog
          act={dialog.act}
          versionId={dialog.versionId}
          onClose={() => setDialog(null)}
          onDone={onChanged}
        />
      )}
    </div>
  );
}

// ---------- Miễn phí / Cao cấp (D-068 #8) ----------

function PremiumPanel({
  catalog,
  editing,
  edit,
}: {
  catalog: KeepsakeCatalog;
  editing: boolean;
  edit: Edit;
}) {
  const intl = useIntl();
  return (
    <Panel
      title={<FormattedMessage id="ks.premium.title" />}
      note={<FormattedMessage id="ks.premium.note" />}
    >
      <div className="stack">
        {editing ? (
          <Segmented
            label={intl.formatMessage({ id: 'ks.premium.title' })}
            value={catalog.premium.access}
            onChange={(v) =>
              edit((c) => {
                c.premium.access = v;
              })
            }
            options={(['everyone', 'subscribers', 'hidden'] as const).map((v) => ({
              value: v,
              label: <FormattedMessage id={`ks.premium.${v}`} />,
            }))}
          />
        ) : (
          <p>
            <Pill tone={catalog.premium.access === 'everyone' ? 'ok' : 'warn'}>
              <FormattedMessage id={`ks.premium.${catalog.premium.access}`} />
            </Pill>
          </p>
        )}
        <CheckRow
          label={<FormattedMessage id="ks.premium.badges" />}
          checked={catalog.premium.badges}
          disabled={!editing}
          onChange={(on) =>
            edit((c) => {
              c.premium.badges = on;
            })
          }
        />
        <p className="field__help">
          <FormattedMessage id="ks.premium.later" />
        </p>
      </div>
    </Panel>
  );
}

// ---------- Templates ----------

/** Where each asset is used in [c], for the library ("Dùng ở …"). */
function assetUses(intl: IntlShape, c: KeepsakeCatalog): Map<string, string[]> {
  const uses = new Map<string, string[]>();
  const add = (asset: string | null | undefined, label: string) => {
    if (!asset) return;
    uses.set(asset, [...(uses.get(asset) ?? []), label]);
  };
  for (const t of c.templates) {
    const name = textOf(intl, t.name);
    add(t.thumb, `${name} · ${intl.formatMessage({ id: 'ks.use.thumb' })}`);
    add(t.preview, `${name} · ${intl.formatMessage({ id: 'ks.use.preview' })}`);
    for (const a of Object.values(t.assets)) add(a, name);
    const layered = new Set<string>();
    for (const layers of Object.values(t.layouts ?? {})) {
      for (const l of layers ?? []) {
        if ('asset' in l && typeof l.asset === 'string') layered.add(l.asset);
      }
    }
    for (const a of layered) add(a, `${name} · ${intl.formatMessage({ id: 'ks.use.layer' })}`);
  }
  for (const m of c.music) add(m.asset, `♪ ${textOf(intl, m.title)}`);
  return uses;
}

const mmss = (sec: number | null | undefined) =>
  sec ? `${Math.floor(sec / 60)}:${String(sec % 60).padStart(2, '0')}` : '';

type TierFilter = 'all' | 'free' | 'premium';

/** The gallery's filters: kind, Miễn phí / Cao cấp and a name or id search. */
export function filterTemplates(
  templates: readonly KeepsakeTemplate[],
  f: { kind: 'all' | 'card' | 'video'; tier: TierFilter; q: string },
  nameOf: (t: KeepsakeTemplate) => string,
): KeepsakeTemplate[] {
  const q = f.q.trim().toLowerCase();
  return templates.filter(
    (t) =>
      (f.kind === 'all' || t.kind === f.kind) &&
      (f.tier === 'all' || t.tier === f.tier) &&
      (!q || nameOf(t).toLowerCase().includes(q) || t.id.toLowerCase().includes(q)),
  );
}

/**
 * The gallery's order: "Mới thêm trước" (new and imported templates are appended to the catalog;
 * there is no per-template creation time), "Thứ tự hiển thị", or "Video xuất nhiều nhất" (most →
 * least, from the server's per-template exports; cards count 0).
 */
export function sortTemplates(
  rows: Array<{ t: KeepsakeTemplate; i: number }>,
  sort: TemplateSort,
  usage: Map<string, TemplateUsage> | null,
) {
  const exportsOf = (t: KeepsakeTemplate) => usage?.get(t.id)?.exports ?? 0;
  const recentOf = (t: KeepsakeTemplate) => usage?.get(t.id)?.exports30d ?? 0;
  return [...rows].sort((a, b) =>
    sort === 'newest'
      ? b.i - a.i
      : sort === 'exports' && usage
        ? exportsOf(b.t) - exportsOf(a.t) || recentOf(b.t) - recentOf(a.t) || b.i - a.i
        : a.t.order - b.t.order || a.t.id.localeCompare(b.t.id),
  );
}

/** The catalog as a gallery: Thiệp cột mốc and Video kỷ niệm, each template with its picture. */
function TemplateGallery({
  catalog,
  sort,
  onSort,
  editing,
  onAdd,
  onImport,
  published,
  urls,
  usage,
  onOpen,
}: {
  catalog: KeepsakeCatalog;
  sort: TemplateSort;
  onSort: (sort: TemplateSort) => void;
  editing: boolean;
  onAdd: (kind: 'card' | 'video') => void;
  onImport: () => void;
  published: Map<string, KeepsakeTemplate>;
  urls: Map<string, string>;
  usage: Map<string, TemplateUsage> | null;
  onOpen: (index: number) => void;
}) {
  const intl = useIntl();
  const [kind, setKind] = useState<'all' | 'card' | 'video'>('all');
  const [tier, setTier] = useState<TierFilter>('all');
  const [q, setQ] = useState('');
  const sorts: TemplateSort[] = usage ? ['newest', 'display', 'exports'] : ['newest', 'display'];
  // Without the server's counts there is nothing to sort by: back to the default.
  const order = sorts.includes(sort) ? sort : 'newest';
  const shown = filterTemplates(catalog.templates, { kind, tier, q }, (t) => textOf(intl, t.name));
  const filtered = tier !== 'all' || q.trim() !== '';
  const groups = (['card', 'video'] as const).filter((k) => kind === 'all' || kind === k);
  return (
    <Panel
      className="panel--flush"
      title={<FormattedMessage id="ks.list.title" values={{ n: catalog.templates.length }} />}
      hint={<FormattedMessage id="ks.list.note" />}
      aside={
        editing && (
          <Button onClick={onImport}>
            <FormattedMessage id="ks.import" />
          </Button>
        )
      }
    >
      <div className="flex flex-wrap items-center gap-2 border-y px-4 py-3">
        <Segmented
          label={intl.formatMessage({ id: 'ks.col.kind' })}
          value={kind}
          onChange={setKind}
          options={(['all', 'card', 'video'] as const).map((v) => ({
            value: v,
            label: <FormattedMessage id={`ks.filter.${v}`} />,
          }))}
        />
        <Segmented
          label={intl.formatMessage({ id: 'ks.col.tier' })}
          value={tier}
          onChange={setTier}
          options={(['all', 'free', 'premium'] as const).map((v) => ({
            value: v,
            label: <FormattedMessage id={v === 'all' ? 'ks.tierFilter.all' : `ks.tier.${v}`} />,
          }))}
        />
        <SearchInput
          value={q}
          onChange={setQ}
          placeholder={intl.formatMessage({ id: 'ks.search' })}
          className="sm:w-56"
        />
        <FieldSelect
          ariaLabel={intl.formatMessage({ id: 'ks.sort.label' })}
          className="w-[190px] sm:ml-auto"
          value={order}
          onChange={onSort}
          options={sorts.map((value) => ({
            value,
            label: intl.formatMessage({ id: `ks.sort.${value}` }),
          }))}
        />
        {filtered && (
          <span className="text-sm text-muted-foreground" role="status">
            <FormattedMessage
              id="kit.results"
              values={{ n: shown.length, total: catalog.templates.length }}
            />
          </span>
        )}
      </div>
      <div className="stack panel__pad">
        {filtered && shown.length === 0 && (
          <Empty>
            <FormattedMessage id="ks.list.none" />
          </Empty>
        )}
        {groups.map((k) => {
          const rows = sortTemplates(
            catalog.templates
              .map((t, i) => ({ t, i }))
              .filter(({ t }) => t.kind === k && shown.includes(t)),
            order,
            usage,
          );
          if (!rows.length && (filtered || !editing)) return null;
          return (
            <section key={k} className="ks-group">
              <h3 className="ks-group__title">
                <FormattedMessage id={`ks.group.${k}`} />
                <span className="count">{rows.length}</span>
              </h3>
              <div className="ks-tiles">
                {rows.map(({ t, i }) => (
                  <TemplateTile
                    key={t.id}
                    template={t}
                    live={published.get(t.id) ?? null}
                    urls={urls}
                    music={catalog.music}
                    // Exports are counted for videos only (the server leaves cards out).
                    usage={
                      usage && t.kind === 'video'
                        ? (usage.get(t.id) ?? { exports: 0, exports30d: null })
                        : null
                    }
                    onOpen={() => onOpen(i)}
                  />
                ))}
                {editing && !filtered && (
                  <button type="button" className="ks-tile ks-tile--add" onClick={() => onAdd(k)}>
                    <Plus size={22} aria-hidden />
                    <FormattedMessage id={k === 'card' ? 'ks.addCard' : 'ks.addVideo'} />
                  </button>
                )}
              </div>
            </section>
          );
        })}
      </div>
    </Panel>
  );
}

function TemplateTile({
  template: t,
  live,
  urls,
  music,
  usage,
  onOpen,
}: {
  template: KeepsakeTemplate;
  live: KeepsakeTemplate | null;
  urls: Map<string, string>;
  music: KeepsakeMusic[];
  /** Exports from the server (null: it sends none). */
  usage: TemplateUsage | null;
  onOpen: () => void;
}) {
  const intl = useIntl();
  const video = useRef<HTMLVideoElement>(null);
  const changed =
    live && JSON.stringify({ ...live, version: 0 }) !== JSON.stringify({ ...t, version: 0 });
  const name = textOf(intl, t.name);
  const language = intl.locale.startsWith('vi') ? 'vi' : 'en';
  const coverAsset = t.thumbs && Object.keys(t.thumbs).length ? t.thumbs[language] : t.thumb;
  const previewAsset =
    t.previews && Object.keys(t.previews).length ? t.previews[language] : t.preview;
  const cover = coverAsset ? urls.get(coverAsset) : undefined;
  const preview = previewAsset ? urls.get(previewAsset) : undefined;
  const formats = keepsakeFormats.filter((f) => t.layouts?.[f]);
  const track = music.find((m) => m.id === t.defaultMusic);
  const meta =
    t.kind === 'card'
      ? formats.map((f) => intl.formatMessage({ id: `ks.formatShort.${f}` })).join(' · ')
      : [
          intl.formatMessage(
            { id: t.photos.min === t.photos.max ? 'ks.tile.photos1' : 'ks.tile.photos' },
            { min: t.photos.min, max: t.photos.max },
          ),
          track && `♪ ${textOf(intl, track.title)}`,
        ]
          .filter(Boolean)
          .join(' · ');
  const mediaHeight = 210;
  return (
    <button
      type="button"
      className="ks-tile"
      onClick={onOpen}
      onMouseEnter={() => void video.current?.play().catch(() => {})}
      onMouseLeave={() => {
        const v = video.current;
        if (v) {
          v.pause();
          v.currentTime = 4;
        }
      }}
    >
      <span className="ks-tile__media" style={{ height: mediaHeight }}>
        {t.kind === 'card' && cover ? (
          <img
            src={cover}
            alt=""
            loading="lazy"
            style={{ height: '100%', maxWidth: '100%', objectFit: 'contain' }}
          />
        ) : t.kind === 'card' && formats[0] ? (
          <CardPreview
            template={t}
            format={formats[0]}
            width={Math.round(
              (mediaHeight - 24) *
                (formats[0] === 'portrait' ? 4 / 5 : formats[0] === 'square' ? 1 : 9 / 16),
            )}
            urls={urls}
          />
        ) : (
          <span
            className="ks-tile__phone"
            style={{ background: t.palette.background, color: t.palette.ink }}
          >
            {cover && <img src={cover} alt="" loading="lazy" />}
            {preview && (
              <video
                key={preview}
                ref={video}
                src={`${preview}#t=4`}
                muted
                loop
                playsInline
                preload={cover ? 'none' : 'metadata'}
                className={cover ? 'ks-tile__hover' : undefined}
              />
            )}
            {!cover && !preview && <span className="ks-tile__placeholder">{name}</span>}
            {t.durationSec && (
              <span className="ks-tile__duration">
                <Play size={10} fill="currentColor" aria-hidden /> {mmss(t.durationSec)}
              </span>
            )}
          </span>
        )}
        {t.tier === 'premium' && (
          <span className="ks-tile__badge">
            <FormattedMessage id="ks.tier.premium" />
          </span>
        )}
        {t.status !== 'published' && (
          <span className="ks-tile__state">
            <FormattedMessage id={`ks.tstatus.${t.status}`} />
          </span>
        )}
      </span>
      <span className="ks-tile__body">
        <span className="ks-tile__name">{name}</span>
        <span className="ks-tile__meta">
          {live ? `v${live.version}` : <FormattedMessage id="ks.neverPublished" />}
          {meta && ` · ${meta}`}
        </span>
        {usage && (
          <span className="ks-tile__meta tabular-nums">
            <FormattedMessage id="ks.exports" values={{ n: usage.exports }} />
            {usage.exports30d !== null && (
              <>
                {' · '}
                <FormattedMessage id="ks.exports30d" values={{ n: usage.exports30d }} />
              </>
            )}
          </span>
        )}
        {changed && (
          <span className="ks-tile__changed">
            <FormattedMessage id="ks.willBump" />
          </span>
        )}
      </span>
    </button>
  );
}

function TemplateEditor({
  template: t,
  index,
  editing,
  edit,
  published,
  urls,
  assets,
  musicOptions,
  onUploaded,
  onBack,
}: {
  template: KeepsakeTemplate;
  index: number;
  editing: boolean;
  edit: Edit;
  published: KeepsakeTemplate | null;
  urls: Map<string, string>;
  assets: KeepsakeAsset[];
  musicOptions: KeepsakeMusic[];
  onUploaded: (added: KeepsakeAsset[]) => void;
  onBack: () => void;
}) {
  const intl = useIntl();
  const api = useApi();
  const id = useId();
  const set = (fn: (x: KeepsakeTemplate) => void) =>
    edit((c) => {
      fn(c.templates[index]!);
    });
  const formats = keepsakeFormats.filter((f) => t.layouts?.[f]);
  const [format, setFormat] = useState<KeepsakeFormat>(formats[0] ?? 'portrait');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const pictures = assets.filter((a) => a.asset.endsWith('.webp'));
  const videos = assets.filter((a) => a.asset.endsWith('.mp4'));
  const field = (label: string, input: React.ReactNode) => (
    <label className="field">
      <span className="field__label">{label}</span>
      {input}
    </label>
  );
  const num = (value: number, onChange: (n: number) => void, label: string) =>
    field(
      label,
      <input
        className="field__input ks-num"
        type="number"
        disabled={!editing}
        value={value}
        onChange={(e) => onChange(Number(e.target.value) || 0)}
      />,
    );
  const text = (value: string, onChange: (s: string) => void, label: string, max = 120) =>
    field(
      label,
      <input
        className="field__input"
        disabled={!editing}
        maxLength={max}
        value={value}
        onChange={(e) => onChange(e.target.value)}
      />,
    );
  const select = <T extends string>(
    label: string,
    value: T,
    options: { value: T; label: string }[],
    onChange: (v: T) => void,
  ) =>
    field(
      label,
      <FieldSelect disabled={!editing} value={value} options={options} onChange={onChange} />,
    );

  /** "Tải video mẫu lên": the MP4 and, from the same file, a cover at the first photo. */
  const uploadPreview = async (file: File) => {
    setBusy(true);
    setError(null);
    try {
      const base = kebab(file.name).slice(0, 33) || 'preview';
      const duration = t.durationSec ?? 30;
      const at = 2 + (duration - 6) / Math.max(1, t.photos.max) / 2;
      const [video, cover] = await uploadVideoWithCover(api, file, base, at);
      onUploaded(cover ? [video, cover] : [video]);
      set((x) => {
        const lang = intl.locale.startsWith('vi') ? 'vi' : 'en';
        x.previews = {
          ...(x.previews ?? (x.preview ? { vi: x.preview } : {})),
          [lang]: video.asset,
        };
        if (cover)
          x.thumbs = { ...(x.thumbs ?? (x.thumb ? { vi: x.thumb } : {})), [lang]: cover.asset };
        if (lang === 'vi') {
          x.preview = video.asset;
          if (cover) x.thumb = cover.asset;
        }
      });
    } catch (e) {
      setError(asApiError(e));
    } finally {
      setBusy(false);
    }
  };

  const language = intl.locale.startsWith('vi') ? 'vi' : 'en';
  const coverAsset = t.thumbs && Object.keys(t.thumbs).length ? t.thumbs[language] : t.thumb;
  const previewAsset =
    t.previews && Object.keys(t.previews).length ? t.previews[language] : t.preview;
  const cover = coverAsset ? urls.get(coverAsset) : undefined;
  const preview = previewAsset ? urls.get(previewAsset) : undefined;

  return (
    <div className="stack">
      <div className="toolbar">
        <span className="chips">
          <Button kind="ghost" onClick={onBack}>
            ← <FormattedMessage id="ks.back" />
          </Button>
          <strong className="ks-editor__title">{textOf(intl, t.name)}</strong>
          <Pill tone={t.tier === 'premium' ? 'purple' : 'info'}>
            <FormattedMessage id={`ks.tier.${t.tier}`} />
          </Pill>
          <Pill tone={t.status === 'published' ? 'ok' : 'muted'}>
            <FormattedMessage id={`ks.tstatus.${t.status}`} />
          </Pill>
        </span>
        <span className="muted">
          {published ? (
            <FormattedMessage id="ks.publishedVersion" values={{ v: published.version }} />
          ) : (
            <FormattedMessage id="ks.neverPublished" />
          )}
        </span>
      </div>

      <div className="ks-editor">
        <div className="stack">
          <Panel title={<FormattedMessage id="ks.sec.general" />}>
            <div className="ks-grid">
              {field(
                intl.formatMessage({ id: 'ks.f.id' }),
                <input
                  className="field__input mono"
                  disabled={!editing || !!published}
                  value={t.id}
                  title={published ? intl.formatMessage({ id: 'ks.f.idLocked' }) : undefined}
                  onChange={(e) => set((x) => void (x.id = e.target.value.trim()))}
                />,
              )}
              {text(
                t.name.vi,
                (s) => set((x) => void (x.name.vi = s)),
                intl.formatMessage({ id: 'ks.f.nameVi' }),
                40,
              )}
              {text(
                t.name.en,
                (s) => set((x) => void (x.name.en = s)),
                intl.formatMessage({ id: 'ks.f.nameEn' }),
                40,
              )}
              {select(
                intl.formatMessage({ id: 'ks.col.tier' }),
                t.tier,
                (['free', 'premium'] as const).map((v) => ({
                  value: v,
                  label: intl.formatMessage({ id: `ks.tier.${v}` }),
                })),
                (v) => set((x) => void (x.tier = v)),
              )}
              {select(
                intl.formatMessage({ id: 'ks.col.status' }),
                t.status,
                (['published', 'draft', 'archived'] as const).map((v) => ({
                  value: v,
                  label: intl.formatMessage({ id: `ks.tstatus.${v}` }),
                })),
                (v) => set((x) => void (x.status = v)),
              )}
              {num(
                t.order,
                (n) => set((x) => void (x.order = n)),
                intl.formatMessage({ id: 'ks.col.order' }),
              )}
            </div>
          </Panel>

          <Panel title={<FormattedMessage id="ks.sec.when" />}>
            <div className="stack">
              <fieldset className="field">
                <legend className="field__label">
                  <FormattedMessage id="ks.f.occasions" />
                </legend>
                <span className="chips">
                  {occasionIds.map((o) => (
                    <CheckRow
                      key={o}
                      label={<FormattedMessage id={`ks.occ.${o}`} />}
                      disabled={!editing}
                      checked={t.occasions.includes(o)}
                      onChange={(on) =>
                        set((x) => {
                          x.occasions = on
                            ? [...x.occasions, o]
                            : x.occasions.filter((y) => y !== o);
                        })
                      }
                    />
                  ))}
                </span>
              </fieldset>
              <div className="ks-grid">
                {field(
                  intl.formatMessage({ id: 'ks.f.age' }),
                  <span className="chips">
                    <input
                      className="field__input ks-num"
                      type="number"
                      disabled={!editing}
                      aria-label={intl.formatMessage({ id: 'ks.f.ageMin' })}
                      value={t.ageDays?.min ?? ''}
                      onChange={(e) =>
                        set((x) => {
                          const v = e.target.value === '' ? null : Number(e.target.value);
                          x.ageDays = v === null ? null : { min: v, max: x.ageDays?.max ?? v };
                        })
                      }
                    />
                    –
                    <input
                      className="field__input ks-num"
                      type="number"
                      disabled={!editing || !t.ageDays}
                      aria-label={intl.formatMessage({ id: 'ks.f.ageMax' })}
                      value={t.ageDays?.max ?? ''}
                      onChange={(e) =>
                        set((x) => {
                          if (x.ageDays) x.ageDays.max = Number(e.target.value) || 0;
                        })
                      }
                    />
                  </span>,
                )}
                {num(
                  t.photos.min,
                  (n) => set((x) => void (x.photos.min = n)),
                  intl.formatMessage({ id: 'ks.f.photosMin' }),
                )}
                {num(
                  t.photos.max,
                  (n) => set((x) => void (x.photos.max = n)),
                  intl.formatMessage({ id: 'ks.f.photosMax' }),
                )}
              </div>
            </div>
          </Panel>

          <Panel title={<FormattedMessage id="ks.sec.look" />}>
            <div className="stack">
              <fieldset className="field">
                <legend className="field__label">
                  <FormattedMessage id="ks.f.palette" />
                </legend>
                <span className="chips">
                  {(['background', 'ink', 'accent'] as const).map((k) => (
                    <label key={k} className="ks-swatch">
                      <input
                        type="color"
                        disabled={!editing}
                        value={t.palette[k]}
                        onChange={(e) =>
                          set((x) => {
                            const before = x.palette[k];
                            x.palette[k] = e.target.value.toUpperCase();
                            // The first "Màu" choice is the template's own palette.
                            if (x.palettes[0]?.[k] === before) x.palettes[0][k] = x.palette[k];
                          })
                        }
                      />
                      <span>
                        <FormattedMessage id={`ks.f.${k}`} />
                        <span className="mono muted"> {t.palette[k]}</span>
                      </span>
                    </label>
                  ))}
                </span>
              </fieldset>
              {t.personalization && (
                <details className="ks-details">
                  <summary>{textOf(intl, t.personalization.group)}</summary>
                  <JsonField
                    id={`${id}-personalization`}
                    label={textOf(intl, t.personalization.group)}
                    value={t.personalization}
                    disabled={!editing}
                    onChange={(v) => {
                      const parsed = keepsakePersonalizationSchema.parse(v);
                      set((x) => {
                        x.personalization = parsed;
                      });
                    }}
                  />
                </details>
              )}
              {t.texts.map((tx) => (
                <div key={tx.key} className="ks-grid ks-grid--2">
                  {text(
                    tx.default.vi,
                    (s) => set((x) => void (x.texts.find((y) => y.key === tx.key)!.default.vi = s)),
                    intl.formatMessage(
                      { id: 'ks.f.textVi' },
                      { label: intl.formatMessage({ id: `ks.text.${tx.key}` }) },
                    ),
                    tx.max,
                  )}
                  {text(
                    tx.default.en,
                    (s) => set((x) => void (x.texts.find((y) => y.key === tx.key)!.default.en = s)),
                    intl.formatMessage(
                      { id: 'ks.f.textEn' },
                      { label: intl.formatMessage({ id: `ks.text.${tx.key}` }) },
                    ),
                    tx.max,
                  )}
                </div>
              ))}
            </div>
          </Panel>

          {t.kind === 'card' ? (
            <Panel
              title={<FormattedMessage id="ks.layers" />}
              note={<FormattedMessage id="ks.f.layersHelp" />}
              aside={
                <span className="chips">
                  <Segmented
                    label={intl.formatMessage({ id: 'ks.col.formats' })}
                    value={format}
                    onChange={setFormat}
                    options={keepsakeFormats.map((f) => ({
                      value: f,
                      label: (
                        <>
                          <FormattedMessage id={`ks.format.${f}`} />
                          {!t.layouts?.[f] && ' ＋'}
                        </>
                      ),
                    }))}
                  />
                  {editing && t.layouts?.[format] && formats.length > 1 && (
                    <Button
                      kind="danger"
                      onClick={() =>
                        set((x) => {
                          delete x.layouts![format];
                        })
                      }
                    >
                      <FormattedMessage id="ks.f.removeFormat" />
                    </Button>
                  )}
                  {editing && !t.layouts?.[format] && (
                    <Button
                      onClick={() =>
                        set((x) => {
                          x.layouts![format] = structuredClone(x.layouts![formats[0]!]!);
                        })
                      }
                    >
                      <FormattedMessage
                        id="ks.f.addFormat"
                        values={{ name: intl.formatMessage({ id: `ks.format.${format}` }) }}
                      />
                    </Button>
                  )}
                </span>
              }
            >
              {t.layouts?.[format] && !t.layouts[format]!.some((l) => l.type === 'brand') && (
                <p className="ks-hint" role="note">
                  <FormattedMessage id="ks.brand.missing" />
                </p>
              )}
              {t.layouts?.[format] ? (
                <LayersField
                  key={`${t.id}-${format}`}
                  id={`${id}-layers`}
                  layers={t.layouts[format]!}
                  disabled={!editing}
                  onChange={(layers) =>
                    set((x) => {
                      x.layouts![format] = layers;
                    })
                  }
                />
              ) : (
                <Empty>
                  <FormattedMessage id="ks.f.noFormat" />
                </Empty>
              )}
            </Panel>
          ) : (
            <Panel
              title={<FormattedMessage id="ks.video" />}
              note={<FormattedMessage id="ks.videoNote" />}
            >
              <div className="stack">
                <div className="ks-grid ks-grid--video">
                  {select(
                    intl.formatMessage({ id: 'ks.f.composition' }),
                    t.composition ?? keepsakeCompositions[0],
                    keepsakeCompositions.map((c) => ({
                      value: c,
                      label: intl.formatMessage({ id: `ks.comp.${c}` }),
                    })),
                    (v) => set((x) => void (x.composition = v)),
                  )}
                  {num(
                    t.durationSec ?? 0,
                    (n) => set((x) => void (x.durationSec = n)),
                    intl.formatMessage({ id: 'ks.f.duration' }),
                  )}
                  {select(
                    intl.formatMessage({ id: 'ks.f.defaultMusic' }),
                    t.defaultMusic ?? '',
                    [
                      { value: '', label: intl.formatMessage({ id: 'ks.f.noMusic' }) },
                      ...musicOptions.map((m) => ({ value: m.id, label: textOf(intl, m.title) })),
                    ],
                    (v) => set((x) => void (x.defaultMusic = v || null)),
                  )}
                </div>
                <fieldset className="field">
                  <legend className="field__label">
                    <FormattedMessage id="ks.brand.title" />
                  </legend>
                  <span className="chips">
                    <CheckRow
                      label={<FormattedMessage id="ks.brand.corner" />}
                      disabled={!editing}
                      checked={!!t.brand?.corner}
                      onChange={(on) =>
                        set((x) => {
                          x.brand = { ...(x.brand ?? defaultKeepsakeVideoBrand), corner: on };
                        })
                      }
                    />
                    <CheckRow
                      label={<FormattedMessage id="ks.brand.endCard" />}
                      disabled={!editing}
                      checked={!!t.brand?.endCard}
                      onChange={(on) =>
                        set((x) => {
                          x.brand = { ...(x.brand ?? defaultKeepsakeVideoBrand), endCard: on };
                        })
                      }
                    />
                    <label className="chips">
                      <FormattedMessage id="ks.brand.opacity" />
                      <input
                        className="field__input ks-num"
                        type="number"
                        min={30}
                        max={100}
                        step={5}
                        disabled={!editing || !t.brand}
                        value={Math.round((t.brand?.opacity ?? 0.75) * 100)}
                        onChange={(e) =>
                          set((x) => {
                            const v = Math.min(100, Math.max(30, Number(e.target.value) || 75));
                            x.brand = {
                              ...(x.brand ?? defaultKeepsakeVideoBrand),
                              opacity: v / 100,
                            };
                          })
                        }
                      />
                      %
                    </label>
                  </span>
                  <p className="field__help">
                    <FormattedMessage id="ks.brand.help" />
                  </p>
                </fieldset>
                <details className="ks-details">
                  <summary>
                    <FormattedMessage id="ks.f.scenes" values={{ n: t.scenes.length }} />
                  </summary>
                  <JsonField
                    id={`${id}-scenes`}
                    label={intl.formatMessage({ id: 'ks.f.scenesJson' })}
                    value={t.scenes}
                    disabled={!editing}
                    onChange={(v) => set((x) => void (x.scenes = v as KeepsakeTemplate['scenes']))}
                  />
                </details>
              </div>
            </Panel>
          )}
        </div>

        <aside className="ks-editor__side no-scrollbar">
          <Panel title={<FormattedMessage id="ks.sec.preview" />}>
            <div className="stack">
              {t.kind === 'card' ? (
                <>
                  <div className="ks-stage">
                    {t.layouts?.[format] && (
                      <CardPreview template={t} format={format} width={236} urls={urls} />
                    )}
                  </div>
                  <p className="field__help">
                    <FormattedMessage id="ks.previewNote" />
                  </p>
                  {t.palettes.length > 1 && (
                    <span className="chips">
                      {t.palettes.map((p, i) => (
                        <CardPreview
                          key={i}
                          template={t}
                          format={format}
                          width={52}
                          urls={urls}
                          palette={p}
                        />
                      ))}
                    </span>
                  )}
                </>
              ) : (
                <>
                  <div className="ks-stage">
                    {preview ? (
                      <video
                        key={preview}
                        className="ks-preview-video"
                        src={preview}
                        poster={cover}
                        controls
                        playsInline
                        preload="none"
                      />
                    ) : (
                      <span className="ks-preview-video ks-preview-video--empty">
                        <FormattedMessage id="ks.f.previewNone" />
                      </span>
                    )}
                  </div>
                  {select(
                    intl.formatMessage({ id: 'ks.f.previewVideo' }),
                    previewAsset ?? '',
                    [
                      { value: '', label: intl.formatMessage({ id: 'ks.f.none' }) },
                      ...videos.map((a) => ({ value: a.asset, label: a.asset })),
                    ],
                    (v) =>
                      set((x) => {
                        x.previews ??= x.preview ? { vi: x.preview } : {};
                        if (v) x.previews[language] = v;
                        else delete x.previews[language];
                        if (language === 'vi') x.preview = v || null;
                      }),
                  )}
                  {editing && (
                    <FilePicker
                      id={`${id}-video`}
                      accept="video/mp4"
                      disabled={busy}
                      label={<FormattedMessage id={busy ? 'ks.f.uploading' : 'ks.f.uploadVideo'} />}
                      onFile={(f) => f && void uploadPreview(f)}
                    />
                  )}
                  {error && (
                    <p className="error" role="alert">
                      <FormattedMessage id={errorMessageId(error)} />
                    </p>
                  )}
                </>
              )}
              <div className="ks-cover">
                {cover ? (
                  <img src={cover} alt="" />
                ) : t.kind === 'video' ? (
                  <span className="ks-cover__empty">
                    <FormattedMessage id="ks.tile.noCover" />
                  </span>
                ) : (
                  <span />
                )}
                {select(
                  intl.formatMessage({ id: 'ks.f.thumb' }),
                  t.thumb ?? '',
                  [
                    { value: '', label: intl.formatMessage({ id: 'ks.f.none' }) },
                    ...pictures.map((a) => ({ value: a.asset, label: a.asset })),
                  ],
                  (v) => set((x) => void (x.thumb = v || null)),
                )}
              </div>
              <p className="field__help">
                <FormattedMessage id={t.kind === 'video' ? 'ks.f.coverHelp' : 'ks.f.thumbHelp'} />
              </p>
            </div>
          </Panel>
        </aside>
      </div>
    </div>
  );
}

/** One format's layers as JSON, checked layer by layer against the shared schema. */
function LayersField({
  id,
  layers,
  disabled,
  onChange,
}: {
  id: string;
  layers: KeepsakeLayer[];
  disabled: boolean;
  onChange: (layers: KeepsakeLayer[]) => void;
}) {
  const intl = useIntl();
  const [text, setText] = useState(() => JSON.stringify(layers, null, 2));
  const [problem, setProblem] = useState<string | null>(null);
  return (
    <div className="field">
      <label className="field__label" htmlFor={id}>
        <FormattedMessage id="ks.f.layers" />
      </label>
      <textarea
        id={id}
        className="field__input ks-json"
        rows={24}
        spellCheck={false}
        disabled={disabled}
        value={text}
        onChange={(e) => {
          setText(e.target.value);
          let parsed: unknown;
          try {
            parsed = JSON.parse(e.target.value);
          } catch (err) {
            setProblem(
              intl.formatMessage({ id: 'ks.f.jsonError' }, { message: (err as Error).message }),
            );
            return;
          }
          if (!Array.isArray(parsed) || parsed.length === 0) {
            setProblem(intl.formatMessage({ id: 'ks.f.jsonError' }, { message: '[…]' }));
            return;
          }
          for (const [i, l] of parsed.entries()) {
            const r = keepsakeLayerSchema.safeParse(l);
            if (!r.success) {
              setProblem(
                `#${i}: ${r.error.issues.map((x) => `${x.path.join('.')} ${x.message}`).join('; ')}`,
              );
              return;
            }
          }
          setProblem(null);
          onChange(parsed as KeepsakeLayer[]);
        }}
      />
      {problem && <p className="error">{problem}</p>}
    </div>
  );
}

function JsonField({
  id,
  label,
  value,
  disabled,
  onChange,
}: {
  id: string;
  label: string;
  value: unknown;
  disabled: boolean;
  onChange: (v: unknown) => void;
}) {
  const intl = useIntl();
  const [text, setText] = useState(() => JSON.stringify(value, null, 2));
  const [problem, setProblem] = useState<string | null>(null);
  return (
    <div className="field">
      <label className="field__label" htmlFor={id}>
        {label}
      </label>
      <textarea
        id={id}
        className="field__input ks-json"
        rows={12}
        spellCheck={false}
        disabled={disabled}
        value={text}
        onChange={(e) => {
          setText(e.target.value);
          try {
            onChange(JSON.parse(e.target.value));
            setProblem(null);
          } catch (err) {
            setProblem(
              intl.formatMessage({ id: 'ks.f.jsonError' }, { message: (err as Error).message }),
            );
          }
        }}
      />
      {problem && <p className="error">{problem}</p>}
    </div>
  );
}

// ---------- Preview: the app's renderer, in HTML ----------

const fonts: Record<string, string> = {
  beVietnamPro: '"Be Vietnam Pro", system-ui, sans-serif',
  lora: 'Lora, Georgia, serif',
  dancingScript: '"Dancing Script", cursive',
  playfair: '"Playfair Display", Georgia, serif',
  baloo: '"Baloo 2", system-ui, sans-serif',
  patrickHand: '"Patrick Hand", cursive',
};

/** The same drawing as the app's `KeepsakeCardView`, with sample words and a placeholder photo. */
export function CardPreview({
  template: t,
  format,
  width,
  urls,
  palette,
}: {
  template: KeepsakeTemplate;
  format: KeepsakeFormat;
  width: number;
  urls: Map<string, string>;
  palette?: KeepsakeTemplate['palette'];
}) {
  const intl = useIntl();
  const p = palette ?? t.palette;
  const aspect = format === 'portrait' ? 4 / 5 : format === 'square' ? 1 : 9 / 16;
  const h = width / aspect;
  const color = (c: string) => (c === 'background' || c === 'ink' || c === 'accent' ? p[c] : c);
  const own = (key: string) => {
    const x = t.texts.find((y) => y.key === key);
    return x
      ? textOf(intl, x.default)
          .replaceAll('{name}', 'Teddy')
          .replaceAll('{age}', intl.formatMessage({ id: 'ks.occ.m1' }))
          .replaceAll('{occasion}', intl.formatMessage({ id: 'ks.occ.m1' }))
          .replaceAll('{achievement}', intl.formatMessage({ id: 'ks.sample.achievement' }))
      : '';
  };
  // What the app fills from a 1-month-old's profile (E-2); the template's own texts as written.
  const sample: Record<string, string> = {
    occasion: intl.formatMessage({ id: 'ks.occ.m1' }),
    name: 'Teddy',
    date: '17.10.2026',
    nameDate: 'Teddy · 17.10.2026',
    quote: own('quote') ? `“${own('quote')}”` : '',
    title: own('title') || textOf(intl, t.name),
    headline: own('headline'),
    message: own('message'),
    age: intl.formatMessage({ id: 'ks.occ.m1' }),
    ageNumber: '1',
    ageUnit: intl.formatMessage({ id: 'ks.sample.unit' }),
    birthStats: '3,2 kg · 50 cm',
    photoLabel0: intl.formatMessage({ id: 'ks.sample.label0' }),
    photoLabel1: intl.formatMessage({ id: 'ks.sample.label1' }),
    ...(t.personalization
      ? resolveKeepsakeCopy(
          t.personalization,
          Object.fromEntries(
            t.personalization.fields.map((f) => [
              f.key,
              f.options?.length
                ? f.options[0]!.value
                : f.type === 'month'
                  ? '01'
                  : f.source === 'babyName'
                    ? 'Teddy'
                    : f.source === 'birthDate'
                      ? '2026-09-17'
                      : f.type === 'confirmation'
                        ? 'false'
                        : f.required && f.suggestion
                          ? textOf(intl, f.suggestion)
                          : '',
            ]),
          ),
          intl.locale.startsWith('vi') ? 'vi' : 'en',
        )
      : {}),
  };
  /** E-3: tilt about the centre. */
  const tilt = (deg: number | undefined): CSSProperties =>
    deg ? { transform: `rotate(${deg}deg)`, transformOrigin: 'center' } : {};
  const box = (r: { x: number; y: number; w: number; h: number }): CSSProperties => ({
    position: 'absolute',
    left: r.x * width,
    top: r.y * h,
    width: r.w * width,
    height: r.h * h,
  });
  return (
    <div
      className="ks-card"
      role="img"
      aria-label={textOf(intl, t.name)}
      style={{
        position: 'relative',
        width,
        height: h,
        overflow: 'hidden',
        borderRadius: width * 0.05,
      }}
    >
      {(t.layouts?.[format] ?? []).map((l, i) => {
        if (l.type === 'image' && l.when && sample[l.when.field] !== l.when.equals) return null;
        switch (l.type) {
          case 'background':
            return (
              <div
                key={i}
                style={{
                  position: 'absolute',
                  inset: 0,
                  background: color(l.color),
                  backgroundImage:
                    l.asset && urls.get(l.asset) ? `url(${urls.get(l.asset)})` : undefined,
                  backgroundSize: 'cover',
                }}
              />
            );
          case 'photo':
            return (
              <div
                key={i}
                style={{
                  ...box(l.rect),
                  ...tilt(l.rotate),
                  borderRadius: l.shape === 'circle' ? '50%' : l.radius * width,
                  background: 'linear-gradient(143deg, #CFEFEA 0%, #8FD6CB 72%)',
                }}
              />
            );
          case 'text':
            return (
              <div
                key={i}
                style={{
                  ...box(l.rect),
                  ...tilt(l.rotate),
                  fontFamily: fonts[l.font],
                  fontWeight: l.weight,
                  fontStyle: l.italic ? 'italic' : 'normal',
                  fontSize: l.size * width,
                  letterSpacing: l.letterSpacing ? `${l.letterSpacing}em` : undefined,
                  textTransform:
                    l.caps && l.font !== 'dancingScript' && l.font !== 'patrickHand'
                      ? 'uppercase'
                      : undefined,
                  lineHeight: 1.25,
                  color: color(l.color),
                  opacity: l.opacity,
                  textAlign: l.align,
                  whiteSpace: l.maxLines === 1 ? 'nowrap' : 'normal',
                  overflow: 'hidden',
                  textOverflow: 'ellipsis',
                }}
              >
                {sample[l.field]}
              </div>
            );
          case 'shape':
            if (l.shape === 'star') {
              return (
                <svg key={i} viewBox="0 0 24 24" style={{ ...box(l.rect), ...tilt(l.rotate) }}>
                  <path
                    d="M12 2.5l2.9 6.2 6.6.8-4.9 4.6 1.3 6.6L12 17.4l-5.9 3.3 1.3-6.6-4.9-4.6 6.6-.8z"
                    fill={l.stroke > 0 ? 'none' : color(l.color)}
                    stroke={color(l.color)}
                    strokeWidth={
                      l.stroke > 0 ? Math.max(1, ((l.stroke * width) / (l.rect.w * width)) * 24) : 0
                    }
                    strokeLinejoin="round"
                  />
                </svg>
              );
            }
            return (
              <div
                key={i}
                style={{
                  ...box(l.rect),
                  ...tilt(l.rotate),
                  borderRadius: l.shape === 'circle' ? '50%' : l.radius * width,
                  background:
                    l.stroke > 0
                      ? undefined
                      : l.gradientTo
                        ? `linear-gradient(${color(l.color)}, ${color(l.gradientTo)})`
                        : color(l.color),
                  border:
                    l.stroke > 0 ? `${l.stroke * width}px solid ${color(l.color)}` : undefined,
                }}
              />
            );
          case 'image':
            return urls.get(l.asset) ? (
              <img
                key={i}
                src={urls.get(l.asset)}
                alt=""
                style={{ ...box(l.rect), ...tilt(l.rotate), objectFit: l.fit, opacity: l.opacity }}
              />
            ) : (
              <div key={i} className="ks-missing" style={box(l.rect)} />
            );
          case 'brand':
            return (
              <div
                key={i}
                className="ks-brand"
                aria-label="Child Life"
                style={{ ...box(l.rect), opacity: l.opacity }}
                // Our own lockup from contracts, never user content.
                dangerouslySetInnerHTML={{ __html: keepsakeBrandSvg(color(l.color)) }}
              />
            );
        }
      })}
    </div>
  );
}

// ---------- Tệp: pictures, music and preview videos ----------

const assetTypes = [
  'image/png',
  'image/jpeg',
  'image/webp',
  'audio/mpeg',
  'audio/mp4',
  'audio/x-m4a',
  'video/mp4',
];
const extOf: Record<string, string> = {
  'image/png': 'png',
  'image/jpeg': 'jpg',
  'image/webp': 'webp',
  'audio/mpeg': 'mp3',
  'audio/mp4': 'm4a',
  'audio/x-m4a': 'm4a',
  'video/mp4': 'mp4',
};

/** Preview videos, music and big pictures go straight to Storage under this staff member's
 * incoming folder (Storage Rules); `staffKeepsakesAsset` then checks, stores and deletes it. */
async function uploadIncoming(file: Blob, name: string): Promise<string> {
  const uid = getAuth(getApp()).currentUser?.uid;
  if (!uid) throw new ApiError('unauthenticated', null);
  const path = `content/keepsakes-incoming/${uid}/${name}.${extOf[file.type] ?? 'bin'}`;
  await uploadBytes(storageRef(getStorage(getApp()), path), file, { contentType: file.type });
  return path;
}
const goesIncoming = (f: Blob) =>
  !f.type.startsWith('image/') || f.size > keepsakeLimits.assetBytes * 0.7;

async function uploadAsset(api: Api, file: Blob, name: string): Promise<KeepsakeAsset> {
  const req = goesIncoming(file)
    ? { name, incoming: await uploadIncoming(file, name) }
    : { name, data: await fileToBase64(file) };
  return api.call<KeepsakeAsset>('staffKeepsakesAsset', req);
}

/** A frame of a local video file as JPEG (the server stores it as WebP). Read from the file on
 * this computer, so it works without CORS on the bucket. Null if the browser cannot decode it. */
async function captureFrame(file: Blob, atSec: number): Promise<Blob | null> {
  const url = URL.createObjectURL(file);
  try {
    const v = document.createElement('video');
    v.muted = true;
    v.playsInline = true;
    v.preload = 'auto';
    v.src = url;
    await new Promise<void>((ok, fail) => {
      v.onloadeddata = () => ok();
      v.onerror = () => fail(new Error('video'));
    });
    v.currentTime = Math.max(0, Math.min(atSec, v.duration / 2));
    await new Promise<void>((ok, fail) => {
      v.onseeked = () => ok();
      v.onerror = () => fail(new Error('seek'));
    });
    const canvas = document.createElement('canvas');
    canvas.width = v.videoWidth;
    canvas.height = v.videoHeight;
    canvas.getContext('2d')!.drawImage(v, 0, 0);
    return await new Promise<Blob | null>((ok) => canvas.toBlob(ok, 'image/jpeg', 0.92));
  } catch {
    return null;
  } finally {
    URL.revokeObjectURL(url);
  }
}

/** An MP4 and its cover (`{name}-cover`), a frame at [atSec] taken from the same file. */
async function uploadVideoWithCover(
  api: Api,
  file: File,
  name: string,
  atSec: number,
): Promise<[KeepsakeAsset, KeepsakeAsset | null]> {
  const frame = await captureFrame(file, atSec);
  const video = await uploadAsset(api, file, name);
  const cover = frame ? await uploadAsset(api, frame, `${name.slice(0, 33)}-cover`) : null;
  return [video, cover];
}

const assetNameOk = (n: string) => /^[a-z0-9-]{2,40}$/.test(n);
const kebab = (file: string) =>
  file
    .replace(/\.[^.]+$/, '')
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/đ/gi, 'd')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 40);

type AssetKind = 'image' | 'video' | 'audio';
const kindOf = (asset: string): AssetKind =>
  asset.endsWith('.mp4') ? 'video' : /\.(mp3|m4a)$/.test(asset) ? 'audio' : 'image';
/** `first-month_1a2b3c4d.mp4` → its cover `first-month-cover_….webp`, if uploaded. */
const coverOf = (asset: string, assets: KeepsakeAsset[]) => {
  const stem = asset.replace(/_[a-f0-9]{8}\.mp4$/, '');
  return assets.find((a) => a.asset.startsWith(`${stem.slice(0, 33)}-cover_`))?.url;
};

function AssetLibrary({
  assets,
  catalog,
  canUpload,
  onUploaded,
}: {
  assets: KeepsakeAsset[];
  catalog: KeepsakeCatalog;
  canUpload: boolean;
  onUploaded: (added: KeepsakeAsset[]) => void;
}) {
  const intl = useIntl();
  const api = useApi();
  const id = useId();
  const [filter, setFilter] = useState<'all' | AssetKind>('all');
  const [file, setFile] = useState<File | null>(null);
  const [name, setName] = useState('');
  const [problem, setProblem] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const uses = useMemo(() => assetUses(intl, catalog), [intl, catalog]);
  const shown = assets.filter((a) => filter === 'all' || kindOf(a.asset) === filter);
  const count = (k: AssetKind) => assets.filter((a) => kindOf(a.asset) === k).length;
  return (
    <Panel
      title={<FormattedMessage id="ks.lib.title" />}
      note={<FormattedMessage id="ks.lib.note" />}
      aside={
        <Segmented
          label={intl.formatMessage({ id: 'ks.lib.title' })}
          value={filter}
          onChange={setFilter}
          options={(['all', 'image', 'video', 'audio'] as const).map((v) => ({
            value: v,
            label: (
              <>
                <FormattedMessage id={`ks.files.${v}`} />
                <span className="ks-tabcount">{v === 'all' ? assets.length : count(v)}</span>
              </>
            ),
          }))}
        />
      }
    >
      {canUpload && (
        <div className="ks-upload">
          <FilePicker
            id={id}
            accept={assetTypes.join(',')}
            onFile={(f) => {
              setError(null);
              setProblem(null);
              setFile(f);
              if (!f) return;
              if (!assetTypes.includes(f.type)) setProblem('ks.lib.type');
              else if (
                f.size >
                (f.type.startsWith('image/')
                  ? keepsakeLimits.assetBytes
                  : keepsakeLimits.incomingBytes)
              )
                setProblem('ks.lib.size');
              setName(kebab(f.name));
            }}
          />
          {file && (
            <>
              <input
                className="field__input mono"
                aria-label={intl.formatMessage({ id: 'ks.lib.name' })}
                value={name}
                maxLength={40}
                onChange={(e) => setName(e.target.value)}
              />
              <Button
                kind="primary"
                disabled={busy || !assetNameOk(name) || !!problem}
                onClick={() => {
                  setBusy(true);
                  setError(null);
                  (file.type === 'video/mp4'
                    ? uploadVideoWithCover(api, file, name, 4).then((r) => r.filter((a) => !!a))
                    : uploadAsset(api, file, name).then((a) => [a])
                  )
                    .then((added) => {
                      onUploaded(added);
                      setFile(null);
                    })
                    .catch((e: unknown) => setError(asApiError(e)))
                    .finally(() => setBusy(false));
                }}
              >
                <FormattedMessage id={busy ? 'ks.f.uploading' : 'ks.lib.upload'} />
              </Button>
            </>
          )}
          {file && !assetNameOk(name) && (
            <p className="error">
              <FormattedMessage id="ks.lib.badName" />
            </p>
          )}
          {problem && (
            <p className="error">
              <FormattedMessage id={problem} />
            </p>
          )}
          {error && (
            <p className="error" role="alert">
              <FormattedMessage id={errorMessageId(error)} />
            </p>
          )}
          {file?.type === 'video/mp4' && (
            <p className="field__help">
              <FormattedMessage id="ks.lib.coverAuto" />
            </p>
          )}
        </div>
      )}
      {shown.length === 0 ? (
        <Empty>
          <FormattedMessage id="ks.lib.empty" />
        </Empty>
      ) : (
        <ul className="ks-assets">
          {shown.map((a) => {
            const kind = kindOf(a.asset);
            const used = uses.get(a.asset) ?? [];
            return (
              <li key={a.asset} className="ks-asset">
                <span className={`ks-asset__media ks-asset__media--${kind}`}>
                  {kind === 'image' && <img src={a.url} alt="" loading="lazy" />}
                  {kind === 'video' && (
                    <a
                      className="ks-asset__video"
                      href={a.url}
                      target="_blank"
                      rel="noreferrer"
                      aria-label={intl.formatMessage({ id: 'ks.files.play' })}
                    >
                      {coverOf(a.asset, assets) ? (
                        <img src={coverOf(a.asset, assets)} alt="" loading="lazy" />
                      ) : (
                        <video src={`${a.url}#t=4`} muted playsInline preload="metadata" />
                      )}
                      <span className="ks-asset__play">
                        <Play size={16} fill="currentColor" aria-hidden />
                      </span>
                    </a>
                  )}
                  {kind === 'audio' && (
                    <>
                      <Music size={28} aria-hidden />
                      <audio controls preload="none" src={a.url} />
                    </>
                  )}
                </span>
                <button
                  type="button"
                  className="mono ks-asset__name"
                  title={`${a.asset} · ${intl.formatMessage({ id: 'ks.files.copy' })}`}
                  onClick={() => void navigator.clipboard?.writeText(a.asset)}
                >
                  {a.asset}
                </button>
                <span className={used.length ? 'ks-asset__uses' : 'ks-asset__uses muted'}>
                  {used.length ? used.join(' · ') : <FormattedMessage id="ks.files.unused" />}
                </span>
              </li>
            );
          })}
        </ul>
      )}
    </Panel>
  );
}

// ---------- History, dialogs ----------

function HistoryPanel({
  view,
  canApprove,
  onRollback,
}: {
  view: KeepsakeView;
  canApprove: boolean;
  onRollback: (versionId: string) => void;
}) {
  const intl = useIntl();
  return (
    <Panel title={<FormattedMessage id="ks.history.title" />}>
      {view.history.length === 0 ? (
        <Empty>
          <FormattedMessage id="ks.history.empty" />
        </Empty>
      ) : (
        <TableScroll>
          <table className="table">
            <tbody>
              {view.history.map((v) => (
                <tr key={v.versionId}>
                  <td>
                    <Pill tone={statusTone[v.status] ?? 'muted'}>
                      <FormattedMessage id={`ks.status.${v.status}`} />
                    </Pill>
                  </td>
                  <td className="mono">{v.label ?? '—'}</td>
                  <td>
                    {v.authorName}
                    {v.approverName && ` → ${v.approverName}`}
                  </td>
                  <td className="muted">{dateTime(intl, v.approvedAt ?? v.updatedAt)}</td>
                  <td className="muted">{v.notes}</td>
                  <td>
                    {canApprove && v.status === 'retired' && (
                      <Button kind="ghost" onClick={() => onRollback(v.versionId)}>
                        <FormattedMessage id="ks.act.rollback" />
                      </Button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </TableScroll>
      )}
    </Panel>
  );
}

/** `card_` / `video_` + the Vietnamese name without marks, unique in [taken]. */
export function templateIdFor(kind: 'card' | 'video', name: string, taken: string[]): string {
  const slug =
    name
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/đ/gi, 'd')
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '_')
      .replace(/^_+|_+$/g, '')
      .slice(0, 34) || 'moi';
  let id = `${kind}_${slug.length >= 2 ? slug : `${slug}_1`}`;
  for (let n = 2; taken.includes(id); n++) id = `${kind}_${slug}_${n}`;
  return id;
}

/** "＋ Mẫu mới": kind, names and the template to start from; the editor opens on it. */
function NewTemplateDialog({
  kind: initialKind,
  catalog,
  onClose,
  onCreate,
}: {
  kind: 'card' | 'video';
  catalog: KeepsakeCatalog;
  onClose: () => void;
  onCreate: (t: KeepsakeTemplate) => void;
}) {
  const intl = useIntl();
  const id = useId();
  const [kind, setKind] = useState(initialKind);
  const [vi, setVi] = useState('');
  const [en, setEn] = useState('');
  const sources = [
    ...catalog.templates.filter((t) => t.kind === kind),
    ...keepsakeSeedV1.templates.filter(
      (t) => t.kind === kind && !catalog.templates.some((x) => x.id === t.id),
    ),
  ];
  const [from, setFrom] = useState('');
  const source = sources.find((t) => t.id === from) ?? sources[0]!;
  const taken = catalog.templates.map((t) => t.id);
  const newId = templateIdFor(kind, vi, taken);
  const ok = vi.trim().length > 0 && en.trim().length > 0;
  return (
    <Modal title={<FormattedMessage id="ks.newTitle" />} onClose={onClose}>
      <div className="stack">
        <Segmented
          label={intl.formatMessage({ id: 'ks.col.kind' })}
          value={kind}
          onChange={(k) => {
            setKind(k);
            setFrom('');
          }}
          options={(['card', 'video'] as const).map((v) => ({
            value: v,
            label: <FormattedMessage id={`ks.group.${v}`} />,
          }))}
        />
        <label className="field">
          <span className="field__label">
            <FormattedMessage id="ks.f.nameVi" />
          </span>
          <input
            id={`${id}-vi`}
            className="field__input"
            maxLength={40}
            value={vi}
            onChange={(e) => setVi(e.target.value)}
          />
        </label>
        <label className="field">
          <span className="field__label">
            <FormattedMessage id="ks.f.nameEn" />
          </span>
          <input
            className="field__input"
            maxLength={40}
            value={en}
            onChange={(e) => setEn(e.target.value)}
          />
        </label>
        <label className="field">
          <span className="field__label">
            <FormattedMessage id="ks.newFrom" />
          </span>
          <FieldSelect
            value={source.id}
            options={sources.map((t) => ({ value: t.id, label: textOf(intl, t.name) }))}
            onChange={setFrom}
          />
        </label>
        <p className="field__help">
          <FormattedMessage id="ks.newHelp" values={{ id: newId }} />
        </p>
      </div>
      <div className="modal__actions">
        <Button onClick={onClose}>
          <FormattedMessage id="action.cancel" />
        </Button>
        <Button
          kind="primary"
          disabled={!ok}
          onClick={() =>
            onCreate({
              ...structuredClone(source),
              id: newId,
              version: 1,
              status: 'draft',
              tier: 'free',
              order: Math.max(0, ...catalog.templates.map((t) => t.order)) + 10,
              name: { vi: vi.trim(), en: en.trim() },
              // The look is copied; when it is suggested is the new template's own.
              occasions: [],
              ageDays: null,
              thumb: null,
              preview: null,
            })
          }
        >
          <FormattedMessage id="ks.newCreate" />
        </Button>
      </div>
    </Modal>
  );
}

/** "Nhập mẫu (JSON)": templates from a file such as `design/keepsake-templates/chapter1.json`,
 * checked against the shared schema; same ids replace, new ones are added. Their pictures must
 * already be in Tệp (the draft check says which are missing). */
function ImportDialog({
  catalog,
  assets,
  onClose,
  onImport,
}: {
  catalog: KeepsakeCatalog;
  assets: KeepsakeAsset[];
  onClose: () => void;
  onImport: (templates: KeepsakeTemplate[]) => void;
}) {
  const id = useId();
  const [templates, setTemplates] = useState<KeepsakeTemplate[] | null>(null);
  const [problem, setProblem] = useState<string | null>(null);
  const have = new Set(assets.map((a) => a.asset));
  const missing = templates
    ? [...new Set(templates.flatMap((t) => [...keepsakeTemplateAssets(t)]))].filter(
        (a) => !have.has(a),
      )
    : [];
  const replaced =
    templates?.filter((t) => catalog.templates.some((x) => x.id === t.id)).length ?? 0;
  return (
    <Modal title={<FormattedMessage id="ks.import" />} onClose={onClose}>
      <p className="modal__sub">
        <FormattedMessage id="ks.import.note" />
      </p>
      <FilePicker
        id={id}
        accept="application/json,.json"
        onFile={(f) => {
          setTemplates(null);
          setProblem(null);
          if (!f) return;
          void f
            .text()
            .then((text) => {
              const raw = JSON.parse(text) as { templates?: unknown };
              const r = keepsakeTemplateSchema.array().safeParse(raw.templates ?? raw);
              if (!r.success) {
                setProblem(
                  r.error.issues
                    .slice(0, 3)
                    .map((i) => `${i.path.join('.')}: ${i.message}`)
                    .join(' · '),
                );
                return;
              }
              setTemplates(r.data);
            })
            .catch((e: unknown) => setProblem(String(e)));
        }}
      />
      {problem && (
        <p className="error" role="alert">
          {problem}
        </p>
      )}
      {templates && (
        <p>
          <FormattedMessage
            id="ks.import.summary"
            values={{ n: templates.length, replaced, missing: missing.length }}
          />
        </p>
      )}
      {missing.length > 0 && <p className="field__help mono">{missing.slice(0, 8).join(', ')}</p>}
      <div className="modal__actions">
        <Button onClick={onClose}>
          <FormattedMessage id="action.cancel" />
        </Button>
        <Button
          kind="primary"
          disabled={!templates}
          onClick={() => templates && onImport(templates)}
        >
          <FormattedMessage id="ks.import.go" />
        </Button>
      </div>
    </Modal>
  );
}

function SaveDialog({
  catalog,
  basedOn,
  notes: initial,
  pending,
  onClose,
  onDone,
}: {
  catalog: KeepsakeCatalog;
  basedOn: string | null | undefined;
  notes: string;
  pending: boolean;
  onClose: () => void;
  onDone: () => void;
}) {
  const api = useApi();
  const [notes, setNotes] = useState(initial);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  return (
    <Modal title={<FormattedMessage id="ks.saveTitle" />} onClose={onClose}>
      <p className="modal__sub">
        <FormattedMessage id={pending ? 'ks.saveNotePending' : 'ks.saveNote'} />
      </p>
      <NotesField value={notes} onChange={setNotes} />
      {error && (
        <p className="error" role="alert">
          <FormattedMessage id={errorMessageId(error)} />
        </p>
      )}
      <div className="modal__actions">
        <Button onClick={onClose}>
          <FormattedMessage id="action.cancel" />
        </Button>
        <Button
          kind="primary"
          disabled={busy}
          onClick={() => {
            setBusy(true);
            setError(null);
            api
              .call('staffKeepsakesDraft', {
                catalog,
                notes: notes.trim(),
                ...(basedOn !== undefined ? { basedOn } : {}),
              })
              .then(() => {
                onClose();
                onDone();
              })
              .catch((e: unknown) => setError(asApiError(e)))
              .finally(() => setBusy(false));
          }}
        >
          <FormattedMessage id="ks.saveDraft" />
        </Button>
      </div>
    </Modal>
  );
}

export function ActDialog({
  act,
  versionId,
  onClose,
  onDone,
}: {
  act: Act;
  versionId: string;
  onClose: () => void;
  onDone: () => void;
}) {
  const api = useApi();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  return (
    <Modal title={<FormattedMessage id={`ks.confirm.${act}`} />} onClose={onClose}>
      <p className="modal__sub">
        <FormattedMessage id={`ks.confirm.${act}.note`} />
      </p>
      {error && (
        <p className="error" role="alert">
          <FormattedMessage id={errorMessageId(error)} />
        </p>
      )}
      <div className="modal__actions">
        <Button onClick={onClose}>
          <FormattedMessage id="action.cancel" />
        </Button>
        <Button
          kind={act === 'discard' ? 'danger' : 'primary'}
          disabled={busy}
          onClick={() => {
            setBusy(true);
            setError(null);
            api
              .call('staffKeepsakesAct', { versionId, action: act })
              .then(() => {
                onClose();
                onDone();
              })
              .catch((e: unknown) => setError(asApiError(e)))
              .finally(() => setBusy(false));
          }}
        >
          <FormattedMessage id={`ks.act.${act}`} />
        </Button>
      </div>
    </Modal>
  );
}

// ---------- Thư viện nhạc (owner, 2026-10-14) ----------

function MusicPanel({
  catalog,
  editing,
  edit,
  assets,
}: {
  catalog: KeepsakeCatalog;
  editing: boolean;
  edit: Edit;
  assets: KeepsakeAsset[];
}) {
  const intl = useIntl();
  const audioFiles = assets.filter((a) => /\.(mp3|m4a)$/.test(a.asset));
  const urls = new Map(assets.map((a) => [a.asset, a.url]));
  const player = useRef<HTMLAudioElement | null>(null);
  const [playing, setPlaying] = useState<string | null>(null);
  /** Tracks whose form is open ("Sửa" on the row, or just added). */
  const [open, setOpen] = useState<Set<string>>(new Set());
  const toggleOpen = (id: string) =>
    setOpen((s) => {
      const next = new Set(s);
      if (!next.delete(id)) next.add(id);
      return next;
    });
  useEffect(() => () => player.current?.pause(), []);
  const toggle = (m: KeepsakeMusic) => {
    player.current?.pause();
    if (playing === m.id) {
      setPlaying(null);
      return;
    }
    const url = urls.get(m.asset);
    if (!url) return;
    const audio = new Audio(url);
    audio.onended = () => setPlaying(null);
    player.current = audio;
    void audio.play().catch(() => setPlaying(null));
    setPlaying(m.id);
  };
  const set = (i: number, fn: (m: KeepsakeMusic) => void) =>
    edit((c) => {
      fn(c.music[i]!);
    });
  const usedBy = (m: KeepsakeMusic) =>
    catalog.templates.filter((t) => t.defaultMusic === m.id).map((t) => textOf(intl, t.name));
  const field = (label: string, input: React.ReactNode) => (
    <label className="field">
      <span className="field__label">{label}</span>
      {input}
    </label>
  );
  const input = (value: string, onChange: (v: string) => void, label: string, max = 120) =>
    field(
      label,
      <input
        className="field__input"
        maxLength={max}
        value={value}
        onChange={(e) => onChange(e.target.value)}
      />,
    );
  return (
    <Panel
      title={<FormattedMessage id="ks.music.title" values={{ n: catalog.music.length }} />}
      note={<FormattedMessage id="ks.music.note" />}
      aside={
        editing && (
          <Button
            onClick={() =>
              edit((c) => {
                let n = c.music.length + 1;
                while (c.music.some((m) => m.id === `music_track_${n}`)) n++;
                setOpen((s) => new Set(s).add(`music_track_${n}`));
                c.music.push({
                  id: `music_track_${n}`,
                  title: { vi: `Bài ${n}`, en: `Track ${n}` },
                  artist: '',
                  mood: 'gentle',
                  durationSec: 60,
                  asset: audioFiles[0]?.asset ?? 'track_00000000.mp3',
                  licence: { kind: 'licensed', source: '', reference: '', expiresOn: null },
                  status: 'draft',
                  order: (c.music.length + 1) * 10,
                });
              })
            }
          >
            <FormattedMessage id="ks.music.add" />
          </Button>
        )
      }
    >
      {catalog.music.length === 0 ? (
        <Empty>
          <FormattedMessage id="ks.music.empty" />
        </Empty>
      ) : (
        <ul className="ks-tracks">
          {catalog.music
            .map((m, i) => ({ m, i }))
            .sort((a, b) => a.m.order - b.m.order)
            .map(({ m, i }) => {
              const used = usedBy(m);
              if (editing && open.has(m.id)) {
                return (
                  <li key={m.id} className="ks-track ks-track--form">
                    <fieldset className="ks-trackform">
                      <legend className="mono">{m.id}</legend>
                      <div className="ks-grid">
                        {input(
                          m.title.vi,
                          (v) => set(i, (x) => void (x.title.vi = v)),
                          intl.formatMessage({ id: 'ks.music.titleVi' }),
                          60,
                        )}
                        {input(
                          m.title.en,
                          (v) => set(i, (x) => void (x.title.en = v)),
                          intl.formatMessage({ id: 'ks.music.titleEn' }),
                          60,
                        )}
                        {input(
                          m.artist,
                          (v) => set(i, (x) => void (x.artist = v)),
                          intl.formatMessage({ id: 'ks.music.col.artist' }),
                          60,
                        )}
                        {field(
                          intl.formatMessage({ id: 'ks.music.mood' }),
                          <FieldSelect
                            value={m.mood}
                            options={keepsakeMoods.map((v) => ({
                              value: v,
                              label: intl.formatMessage({ id: `ks.mood.${v}` }),
                            }))}
                            onChange={(v) => set(i, (x) => void (x.mood = v))}
                          />,
                        )}
                        {field(
                          intl.formatMessage({ id: 'ks.music.duration' }),
                          <input
                            className="field__input ks-num"
                            type="number"
                            value={m.durationSec}
                            onChange={(e) =>
                              set(i, (x) => void (x.durationSec = Number(e.target.value) || 0))
                            }
                          />,
                        )}
                        {field(
                          intl.formatMessage({ id: 'ks.music.col.file' }),
                          <FieldSelect
                            value={m.asset}
                            options={[
                              ...(audioFiles.some((a) => a.asset === m.asset)
                                ? []
                                : [{ value: m.asset, label: m.asset }]),
                              ...audioFiles.map((a) => ({ value: a.asset, label: a.asset })),
                            ]}
                            onChange={(v) => set(i, (x) => void (x.asset = v))}
                          />,
                        )}
                        {field(
                          intl.formatMessage({ id: 'ks.music.col.licence' }),
                          <FieldSelect
                            value={m.licence.kind}
                            options={keepsakeLicenceKinds.map((v) => ({
                              value: v,
                              label: intl.formatMessage({ id: `ks.licence.${v}` }),
                            }))}
                            onChange={(v) => set(i, (x) => void (x.licence.kind = v))}
                          />,
                        )}
                        {input(
                          m.licence.source,
                          (v) => set(i, (x) => void (x.licence.source = v)),
                          intl.formatMessage({ id: 'ks.licence.source' }),
                        )}
                        {input(
                          m.licence.reference,
                          (v) => set(i, (x) => void (x.licence.reference = v)),
                          intl.formatMessage({ id: 'ks.licence.reference' }),
                        )}
                        {field(
                          intl.formatMessage({ id: 'ks.licence.expires' }),
                          <input
                            className="field__input"
                            type="date"
                            value={m.licence.expiresOn ?? ''}
                            onChange={(e) =>
                              set(i, (x) => void (x.licence.expiresOn = e.target.value || null))
                            }
                          />,
                        )}
                        {field(
                          intl.formatMessage({ id: 'ks.music.col.status' }),
                          <FieldSelect
                            value={m.status}
                            options={(['published', 'draft', 'archived'] as const).map((v) => ({
                              value: v,
                              label: intl.formatMessage({ id: `ks.tstatus.${v}` }),
                            }))}
                            onChange={(v) => set(i, (x) => void (x.status = v))}
                          />,
                        )}
                        {field(
                          intl.formatMessage({ id: 'ks.col.order' }),
                          <input
                            className="field__input ks-num"
                            type="number"
                            value={m.order}
                            onChange={(e) =>
                              set(i, (x) => void (x.order = Number(e.target.value) || 0))
                            }
                          />,
                        )}
                      </div>
                      <div className="ks-trackform__done">
                        <Button onClick={() => toggleOpen(m.id)}>
                          <FormattedMessage id="ks.music.done" />
                        </Button>
                      </div>
                    </fieldset>
                  </li>
                );
              }
              return (
                <li key={m.id} className="ks-track">
                  <button
                    type="button"
                    className="ks-track__play"
                    disabled={!urls.get(m.asset)}
                    aria-label={intl.formatMessage(
                      { id: playing === m.id ? 'ks.music.pause' : 'ks.music.play' },
                      { title: textOf(intl, m.title) },
                    )}
                    onClick={() => toggle(m)}
                  >
                    {playing === m.id ? (
                      <Pause size={16} fill="currentColor" aria-hidden />
                    ) : (
                      <Play size={16} fill="currentColor" aria-hidden />
                    )}
                  </button>
                  <span className="ks-track__main">
                    <span>
                      <strong>{m.title.vi}</strong>
                      <span className="muted"> · {m.title.en}</span>
                    </span>
                    <span className="ks-track__meta">
                      {[
                        m.artist,
                        intl.formatMessage({ id: `ks.mood.${m.mood}` }),
                        mmss(m.durationSec),
                      ]
                        .filter(Boolean)
                        .join(' · ')}
                    </span>
                  </span>
                  <span className="ks-track__licence">
                    <Pill tone="info">
                      <FormattedMessage id={`ks.licence.${m.licence.kind}`} />
                    </Pill>
                    <span
                      className="ks-track__meta"
                      title={`${m.licence.source} · ${m.licence.reference}`}
                    >
                      {m.licence.source}
                      {m.licence.expiresOn && (
                        <>
                          {' · '}
                          <FormattedMessage
                            id="ks.music.until"
                            values={{ date: m.licence.expiresOn }}
                          />
                        </>
                      )}
                    </span>
                  </span>
                  <span className="ks-track__uses">
                    {used.length ? (
                      <FormattedMessage
                        id="ks.music.defaultFor"
                        values={{ names: used.join(', ') }}
                      />
                    ) : (
                      <span className="muted">
                        <FormattedMessage id="ks.music.notDefault" />
                      </span>
                    )}
                  </span>
                  <span className="chips">
                    <Pill tone={m.status === 'published' ? 'ok' : 'muted'}>
                      <FormattedMessage id={`ks.tstatus.${m.status}`} />
                    </Pill>
                    {editing && (
                      <Button kind="ghost" onClick={() => toggleOpen(m.id)}>
                        <FormattedMessage id="ks.music.edit" />
                      </Button>
                    )}
                  </span>
                </li>
              );
            })}
        </ul>
      )}
    </Panel>
  );
}
