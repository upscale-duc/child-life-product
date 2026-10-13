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
import { useId, useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { ApiError, useApi, useLoad, type AppUpdateView, type FirstAidImage } from '../api';
import { useStaff } from '../context';
import {
  Button,
  Loaded,
  Modal,
  Page,
  Panel,
  Pill,
  ReasonField,
  TableScroll,
  errorMessageId,
  reasonOk,
} from '../ui';
import { AppUpdatePreview } from './AppUpdatePreview';
import { FieldSelect, FilePicker, IconButton } from './form-controls';
import { fileToBase64 } from './FirstAidEditor';

/**
 * Hệ thống › Cập nhật ứng dụng (D-061, v1.0 improvement UP1–UP6): the versions in each store, the
 * oldest one allowed to run (below it the app shows UP1 and stops), and "Có gì mới" — the UP2
 * sheet's rows, the UP5 banner line and the UP3/UP4 pages. Publishing takes effect on the next
 * app launch; raising a minimum is spelled out before it goes.
 */
export function AppUpdateScreen() {
  const [state, reload] = useLoad<AppUpdateView>('staffAppUpdate', {}, 'appUpdate');
  const staff = useStaff();
  return (
    <Page
      title={<FormattedMessage id="au.title" />}
      subtitle={<FormattedMessage id="au.subtitle" />}
    >
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

export function AppUpdateBody({
  view,
  canEdit,
  onPublished,
}: {
  view: AppUpdateView;
  canEdit: boolean;
  onPublished?: () => void;
}) {
  const published = view.current?.config ?? null;
  const [config, setConfig] = useState<AppUpdateConfig>(published ?? appUpdateEmpty);
  const [images, setImages] = useState<FirstAidImage[]>(view.images);
  const [confirm, setConfirm] = useState(false);
  const check = appUpdateConfigSchema.safeParse(config);
  const problems = check.success
    ? []
    : [...new Set(check.error.issues.map((i) => issueId(i.message, i.path)))];
  const changed = JSON.stringify(config) !== JSON.stringify(published ?? appUpdateEmpty);
  const ro = !canEdit;

  return (
    <div className="stack">
      <Panel title={<FormattedMessage id="au.current" />}>
        <div className="panel__pad">
          {view.current ? (
            <p>
              <FormattedMessage
                id="au.currentLine"
                values={{
                  version: <span className="mono">{view.current.version}</span>,
                  at: new Date(view.current.publishedAt).toLocaleString('vi-VN'),
                }}
              />
            </p>
          ) : (
            <p className="muted">
              <FormattedMessage id="au.none" />
            </p>
          )}
        </div>
      </Panel>

      <div className="au-layout">
        <div className="stack">
          <div className="cols cols--1-1">
            {platforms.map((p) => (
              <PlatformPanel
                key={p}
                platform={p}
                value={config[p]}
                before={published?.[p] ?? null}
                readOnly={ro}
                onChange={(v) => setConfig({ ...config, [p]: v })}
              />
            ))}
          </div>

          <Panel
            title={<FormattedMessage id="au.nudge" />}
            note={<FormattedMessage id="au.nudgeNote" />}
          >
            <div className="panel__pad">
              <NumberField
                label={<FormattedMessage id="au.snoozeDays" />}
                value={config.snoozeDays}
                min={1}
                max={30}
                readOnly={ro}
                onChange={(snoozeDays) => setConfig({ ...config, snoozeDays })}
              />
            </div>
          </Panel>

          <ReleasePanel
            value={config.release}
            images={images}
            readOnly={ro}
            onImage={(img) => setImages((all) => [img, ...all.filter((i) => i.id !== img.id)])}
            onChange={(release) => setConfig({ ...config, release })}
          />

          {canEdit && (
            <div className="fa-editbar">
              {problems.length > 0 && (
                <ul className="error" role="alert">
                  {problems.map((p) => (
                    <li key={p}>
                      <FormattedMessage id={p} />
                    </li>
                  ))}
                </ul>
              )}
              <div className="actions">
                <Button disabled={!changed} onClick={() => setConfig(published ?? appUpdateEmpty)}>
                  <FormattedMessage id="au.reset" />
                </Button>
                <Button
                  kind="primary"
                  disabled={!changed || problems.length > 0}
                  onClick={() => setConfirm(true)}
                >
                  <FormattedMessage id="au.publish" />
                </Button>
              </div>
            </div>
          )}
        </div>
        <aside className="au-layout__aside">
          <Panel title={<FormattedMessage id="au.pv.title" />}>
            <div className="panel__pad">
              <AppUpdatePreview config={config} images={images} />
            </div>
          </Panel>
        </aside>
      </div>

      <Panel title={<FormattedMessage id="au.history" />} className="panel--flush">
        <TableScroll>
          <table>
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
              {view.history.map((h) => (
                <tr key={h.version}>
                  <td className="mono">{h.version}</td>
                  <td className="nowrap">{new Date(h.publishedAt).toLocaleString('vi-VN')}</td>
                  <td className="mono">{range(h.config.ios)}</td>
                  <td className="mono">{range(h.config.android)}</td>
                  <td className="mono">{h.config.release?.version ?? '—'}</td>
                  <td>
                    {h.byName}
                    <div className="muted">{h.reason}</div>
                  </td>
                </tr>
              ))}
              {view.history.length === 0 && (
                <tr>
                  <td colSpan={6} className="muted">
                    <FormattedMessage id="au.historyEmpty" />
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </TableScroll>
      </Panel>

      {confirm && (
        <PublishModal
          before={published}
          after={config}
          onClose={() => setConfirm(false)}
          onDone={() => {
            setConfirm(false);
            onPublished?.();
          }}
        />
      )}
    </div>
  );
}

/** "1.0.5 → 1.2.0": minimum → latest. */
const range = (p: AppUpdatePlatform) => (p.latest ? `${p.minimum ?? '—'} → ${p.latest}` : '—');

/** Server-side zod messages and paths → message ids. */
function issueId(message: string, path: PropertyKey[]): string {
  if (message === 'minimum-above-latest') return 'au.err.minimumAboveLatest';
  if (message === 'store-url-required') return 'au.err.storeUrl';
  if (message === 'store' || path.includes('storeUrl')) return 'au.err.storeUrlHost';
  if (path.includes('latest') || path.includes('minimum') || path.includes('version'))
    return 'au.err.version';
  if (path[0] === 'release') return 'au.err.release';
  return 'au.err.other';
}

export function raisedMinimum(before: AppUpdatePlatform | null, after: AppUpdatePlatform) {
  return (
    !!after.minimum && (!before?.minimum || compareAppVersions(after.minimum, before.minimum) > 0)
  );
}

function PlatformPanel({
  platform,
  value,
  before,
  readOnly,
  onChange,
}: {
  platform: PlatformKey;
  value: AppUpdatePlatform;
  before: AppUpdatePlatform | null;
  readOnly: boolean;
  onChange: (v: AppUpdatePlatform) => void;
}) {
  const set = (k: keyof AppUpdatePlatform, v: string) =>
    onChange({ ...value, [k]: v.trim() === '' ? null : v.trim() });
  return (
    <Panel
      title={platform === 'ios' ? 'iOS · App Store' : 'Android · Google Play'}
      aside={
        raisedMinimum(before, value) ? (
          <Pill tone="error">
            <FormattedMessage id="au.blocks" values={{ version: value.minimum }} />
          </Pill>
        ) : null
      }
    >
      <div className="panel__pad fa-cols">
        <TextField
          label={<FormattedMessage id="au.latest" />}
          help={<FormattedMessage id="au.latestHelp" />}
          value={value.latest ?? ''}
          mono
          placeholder="1.2.0"
          readOnly={readOnly}
          onChange={(v) => set('latest', v)}
        />
        <TextField
          label={<FormattedMessage id="au.minimum" />}
          help={<FormattedMessage id="au.minimumHelp" />}
          value={value.minimum ?? ''}
          mono
          placeholder="1.0.0"
          readOnly={readOnly}
          onChange={(v) => set('minimum', v)}
        />
      </div>
      <div className="panel__pad">
        <TextField
          label={<FormattedMessage id="au.storeUrl" />}
          help={<FormattedMessage id={`au.storeUrlHelp.${platform}`} />}
          value={value.storeUrl ?? ''}
          mono
          readOnly={readOnly}
          onChange={(v) => set('storeUrl', v)}
        />
      </div>
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
  images,
  readOnly,
  onImage,
  onChange,
}: {
  value: AppUpdateRelease | null;
  images: FirstAidImage[];
  readOnly: boolean;
  onImage: (img: FirstAidImage) => void;
  onChange: (v: AppUpdateRelease | null) => void;
}) {
  return (
    <Panel
      title={<FormattedMessage id="au.release" />}
      note={<FormattedMessage id="au.releaseNote" />}
      aside={
        !readOnly && (
          <Button onClick={() => onChange(value ? null : blankRelease())}>
            <FormattedMessage id={value ? 'au.releaseRemove' : 'au.releaseAdd'} />
          </Button>
        )
      }
    >
      {value && (
        <div className="panel__pad fa-editor">
          <div className="fa-cols">
            <TextField
              label={<FormattedMessage id="au.releaseVersion" />}
              help={<FormattedMessage id="au.releaseVersionHelp" />}
              value={value.version}
              mono
              placeholder="1.2.0"
              readOnly={readOnly}
              onChange={(version) => onChange({ ...value, version: version.trim() })}
            />
          </div>
          <LocField
            label={<FormattedMessage id="au.summary" />}
            help={<FormattedMessage id="au.summaryHelp" />}
            value={value.summary}
            max={appUpdateLimits.summary}
            readOnly={readOnly}
            onChange={(summary) => onChange({ ...value, summary })}
          />

          <section className="fa-section">
            <h3 className="fa-section__title">
              <FormattedMessage id="au.highlights" />
            </h3>
            <p className="field__help">
              <FormattedMessage id="au.highlightsHelp" />
            </p>
            {value.highlights.map((h, i) => (
              <HighlightEditor
                key={i}
                value={h}
                readOnly={readOnly}
                onChange={(next) =>
                  onChange({
                    ...value,
                    highlights: value.highlights.map((x, j) => (j === i ? next : x)),
                  })
                }
                onRemove={() =>
                  onChange({ ...value, highlights: value.highlights.filter((_, j) => j !== i) })
                }
              />
            ))}
            {!readOnly && value.highlights.length < appUpdateLimits.highlights && (
              <Button
                onClick={() =>
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
                  })
                }
              >
                <FormattedMessage id="au.highlightAdd" />
              </Button>
            )}
          </section>

          <section className="fa-section">
            <h3 className="fa-section__title">
              <FormattedMessage id="au.pages" />
            </h3>
            <p className="field__help">
              <FormattedMessage id="au.pagesHelp" />
            </p>
            {value.pages.map((p, i) => (
              <PageEditor
                key={i}
                index={i}
                count={value.pages.length}
                value={p}
                images={images}
                readOnly={readOnly}
                onImage={onImage}
                onChange={(next) =>
                  onChange({ ...value, pages: value.pages.map((x, j) => (j === i ? next : x)) })
                }
                onMove={(to) => {
                  const pages = [...value.pages];
                  const [item] = pages.splice(i, 1);
                  pages.splice(to, 0, item!);
                  onChange({ ...value, pages });
                }}
                onRemove={() =>
                  onChange({ ...value, pages: value.pages.filter((_, j) => j !== i) })
                }
              />
            ))}
            {!readOnly && value.pages.length < appUpdateLimits.pages && (
              <Button
                onClick={() =>
                  onChange({
                    ...value,
                    pages: [
                      ...value.pages,
                      { image: null, title: { ...blankText }, body: { ...blankText }, where: null },
                    ],
                  })
                }
              >
                <FormattedMessage id="au.pageAdd" />
              </Button>
            )}
          </section>
        </div>
      )}
    </Panel>
  );
}

function HighlightEditor({
  value,
  readOnly,
  onChange,
  onRemove,
}: {
  value: AppUpdateHighlight;
  readOnly: boolean;
  onChange: (v: AppUpdateHighlight) => void;
  onRemove: () => void;
}) {
  const intl = useIntl();
  return (
    <div className="fa-card au-item">
      <div className="fa-cols">
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
        onChange={(title) => onChange({ ...value, title })}
      />
      <LocField
        label={<FormattedMessage id="au.itemBody" />}
        value={value.body}
        max={appUpdateLimits.highlightBody}
        readOnly={readOnly}
        onChange={(body) => onChange({ ...value, body })}
      />
      {!readOnly && (
        <Button kind="ghost" onClick={onRemove}>
          <FormattedMessage id="au.remove" />
        </Button>
      )}
    </div>
  );
}

function PageEditor({
  index,
  count,
  value,
  images,
  readOnly,
  onImage,
  onChange,
  onMove,
  onRemove,
}: {
  index: number;
  count: number;
  value: AppUpdatePage;
  images: FirstAidImage[];
  readOnly: boolean;
  onImage: (img: FirstAidImage) => void;
  onChange: (v: AppUpdatePage) => void;
  onMove: (to: number) => void;
  onRemove: () => void;
}) {
  const intl = useIntl();
  const url = images.find((i) => i.id === value.image)?.url;
  return (
    <div className="fa-card au-item">
      <div className="fa-card__head">
        <strong>
          <FormattedMessage id="au.pageN" values={{ n: index + 1 }} />
        </strong>
        {!readOnly && (
          <div className="actions">
            <IconButton
              icon="up"
              label={intl.formatMessage({ id: 'au.moveUp' })}
              disabled={index === 0}
              onClick={() => onMove(index - 1)}
            />
            <IconButton
              icon="down"
              label={intl.formatMessage({ id: 'au.moveDown' })}
              disabled={index === count - 1}
              onClick={() => onMove(index + 1)}
            />
            <Button kind="ghost" onClick={onRemove}>
              <FormattedMessage id="au.remove" />
            </Button>
          </div>
        )}
      </div>
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
        onChange={(title) => onChange({ ...value, title })}
      />
      <LocField
        label={<FormattedMessage id="au.pageBody" />}
        value={value.body}
        max={appUpdateLimits.pageBody}
        multiline
        readOnly={readOnly}
        onChange={(body) => onChange({ ...value, body })}
      />
      <LocField
        label={<FormattedMessage id="au.where" />}
        help={<FormattedMessage id="au.whereHelp" />}
        value={value.where ?? blankText}
        max={appUpdateLimits.where}
        readOnly={readOnly}
        onChange={(where) => onChange({ ...value, where: where.vi || where.en ? where : null })}
      />
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
  const [reason, setReason] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const blocks = platforms.filter((p) => raisedMinimum(before?.[p] ?? null, after[p]));
  return (
    <Modal title={<FormattedMessage id="au.confirmTitle" />} onClose={onClose}>
      <ul className="modal__sub">
        {platforms.map((p) => (
          <li key={p}>
            {p === 'ios' ? 'iOS' : 'Android'}: <span className="mono">{range(after[p])}</span>
          </li>
        ))}
        <li>
          <FormattedMessage id="au.col.release" />:{' '}
          <span className="mono">{after.release?.version ?? '—'}</span>
        </li>
      </ul>
      {blocks.map((p) => (
        <p key={p} className="modal__alert" role="alert">
          <FormattedMessage
            id="au.confirmBlocks"
            values={{ platform: p === 'ios' ? 'iOS' : 'Android', version: after[p].minimum }}
          />
        </p>
      ))}
      <ReasonField value={reason} onChange={setReason} required />
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
          disabled={busy || !reasonOk(reason)}
          onClick={() => {
            setBusy(true);
            api
              .call('staffAppUpdateSave', { config: after, reason })
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
  help,
  value,
  mono,
  placeholder,
  readOnly,
  onChange,
}: {
  label: ReactNode;
  help?: ReactNode;
  value: string;
  mono?: boolean;
  placeholder?: string;
  readOnly: boolean;
  onChange: (v: string) => void;
}) {
  const id = useId();
  return (
    <div className="field">
      <label className="field__label" htmlFor={id}>
        {label}
      </label>
      <input
        id={id}
        className={`field__input ${mono ? 'mono' : ''}`}
        value={value}
        placeholder={placeholder}
        readOnly={readOnly}
        onChange={(e) => onChange(e.target.value)}
      />
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
    <div className="field">
      <label className="field__label" htmlFor={id}>
        {label}
      </label>
      <input
        id={id}
        type="number"
        className="field__input input--sm"
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

/** Vietnamese and English side by side (D-012). */
function LocField({
  label,
  help,
  value,
  max,
  multiline,
  readOnly,
  onChange,
}: {
  label: ReactNode;
  help?: ReactNode;
  value: AppUpdateText;
  max: number;
  multiline?: boolean;
  readOnly: boolean;
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
      onChange: (e: { target: { value: string } }) =>
        onChange({ ...value, [lang]: e.target.value }),
    };
    return multiline ? <textarea rows={3} {...props} /> : <input {...props} />;
  };
  return (
    <fieldset className="fa-loc">
      <legend className="field__label">{label}</legend>
      <div className="fa-cols">
        {(['vi', 'en'] as const).map((lang) => (
          <div className="field" key={lang}>
            <label className="fa-lang" htmlFor={`${id}-${lang}`}>
              {lang === 'vi' ? 'Tiếng Việt' : 'English'} · {value[lang].length}/{max}
            </label>
            {input(lang)}
          </div>
        ))}
      </div>
      {help && <p className="field__help">{help}</p>}
    </fieldset>
  );
}
