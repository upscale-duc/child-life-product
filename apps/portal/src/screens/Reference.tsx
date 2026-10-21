import {
  parseReferenceCsv,
  rowKey,
  staffCan,
  vaccineProgrammes,
  type BottleRow,
  type GrowthRow,
  type ReferenceDataset,
  type VaccineDef,
} from '@child-life/contracts';
import { useEffect, useId, useMemo, useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl, type IntlShape } from 'react-intl';
import { ApiError, useApi, useLoad, type ReferenceView } from '../api';
import { VersionBadge } from '../content-kit';
import { useOwnWorkBlocked } from '../content-policy';
import { routePaths, subPath, useStaff } from '../context';
import { ZONE } from '../format';
import {
  Button,
  errorMessageId,
  Loaded,
  Loading,
  LockNote,
  Modal,
  Page,
  Panel,
  NotesField,
  Pill,
  RejectedBy,
  Segmented,
  SelectMenu,
  TableScroll,
  type PillTone,
} from '../ui';

/**
 * Bảng tham chiếu (Figma C01–C04; P-138), under NỘI DUNG. One open version per table (Nháp /
 * Chờ duyệt); a different person with "Duyệt" publishes it to the apps, which keep their own copy
 * as fallback.
 * WHO rows are replaced only by importing a new WHO release (Q-045 default); bottle quick picks
 * and the vaccine schedule are edited here. Every step is logged (no reason asked: D-090).
 */

const datasets: ReferenceDataset[] = [
  'growth.weight',
  'growth.length',
  'bottle.quickPicks',
  'vaccines.schedule',
];
const slug: Record<ReferenceDataset, string> = {
  'growth.weight': 'weight',
  'growth.length': 'length',
  'bottle.quickPicks': 'bottle',
  'vaccines.schedule': 'vaccines',
};
const statusTone: Record<string, PillTone> = {
  draft: 'muted',
  pending: 'wait',
  published: 'ok',
  retired: 'muted',
  discarded: 'muted',
};

const asApiError = (e: unknown) => (e instanceof ApiError ? e : new ApiError('unknown', null));

function dateTime(intl: IntlShape, iso: string | null): string {
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

/** "0–6 ngày", "1–4 tuần", "2–4 tháng", "Từ 4 tháng" (weeks and months read like C02). */
export function bandLabel(intl: IntlShape, r: BottleRow): string {
  const month = (d: number) => Math.round(d / 30.4375);
  if (r.toDay === null) {
    return intl.formatMessage(
      { id: 'reference.band.from' },
      { n: month(r.fromDay), unit: 'month' },
    );
  }
  const [lo, hi, unit] =
    r.toDay <= 14
      ? [r.fromDay, r.toDay - 1, 'day']
      : r.toDay <= 56
        ? [Math.round(r.fromDay / 7), Math.round(r.toDay / 7), 'week']
        : [month(r.fromDay), month(r.toDay), 'month'];
  return intl.formatMessage({ id: 'reference.band.range' }, { lo, hi, unit });
}

export function ReferenceScreen() {
  const intl = useIntl();
  const staff = useStaff();
  const [dataset, setDataset] = useState<ReferenceDataset>(() => {
    const s = subPath('reference', window.location.pathname)[0];
    return datasets.find((d) => slug[d] === s) ?? 'growth.length';
  });
  useEffect(() => {
    const url = `${routePaths.reference}/${slug[dataset]}`;
    if (window.location.pathname !== url) window.history.replaceState({}, '', url);
  }, [dataset]);
  const [load, reload] = useLoad<ReferenceView>('staffReference', { dataset }, dataset);
  const canEdit = staffCan(staff.levels, 'reference.edit');
  const canApprove = staffCan(staff.levels, 'reference.approve');
  return (
    <Page
      title={<FormattedMessage id="reference.title" />}
      info={
        <FormattedMessage
          id={dataset === 'vaccines.schedule' ? 'reference.subVaccines' : 'reference.sub'}
        />
      }
    >
      <div className="stack">
        <Segmented
          label={intl.formatMessage({ id: 'reference.title' })}
          value={dataset}
          onChange={setDataset}
          options={datasets.map((d) => ({
            value: d,
            label: <FormattedMessage id={`reference.tab.${slug[d]}`} />,
          }))}
        />
        <Loaded load={load} reload={reload}>
          {(view) => (
            <ReferenceFor
              view={view}
              dataset={dataset}
              canEdit={canEdit}
              canApprove={canApprove}
              selfUid={staff.uid}
              onChanged={reload}
            />
          )}
        </Loaded>
      </div>
    </Page>
  );
}

/**
 * Right after a tab switch the loaded answer is still the previous table's, and the bottle and
 * vaccine editors cannot read growth rows (blank page): wait for the table that was asked for.
 */
export function ReferenceFor(props: Parameters<typeof ReferenceBody>[0]) {
  if (props.view.dataset !== props.dataset) return <Loading />;
  return <ReferenceBody key={props.dataset} {...props} />;
}

type Act = 'submit' | 'approve' | 'reject' | 'discard' | 'rollback';

export function ReferenceBody({
  view,
  dataset,
  canEdit,
  canApprove,
  selfUid,
  onChanged,
}: {
  view: ReferenceView;
  dataset: ReferenceDataset;
  canEdit: boolean;
  canApprove: boolean;
  selfUid: string;
  onChanged: () => void;
}) {
  const intl = useIntl();
  const ownWorkBlocked = useOwnWorkBlocked(selfUid);
  const [showDraft, setShowDraft] = useState(!!view.draft);
  // A draft that just appeared (saved, imported) is what the editor wants to see.
  const draftId = view.draft?.versionId ?? null;
  useEffect(() => setShowDraft(draftId !== null), [draftId]);
  const [dialog, setDialog] = useState<{ act: Act; versionId: string } | 'csv' | 'edit' | null>(
    null,
  );
  const rows = showDraft && view.draft ? view.draft.rows : view.current.rows;
  const changed = useMemo(
    () =>
      new Set(
        showDraft && view.draft ? [...view.draft.diff.added, ...view.draft.diff.changed] : [],
      ),
    [showDraft, view.draft],
  );
  const d = view.draft;
  return (
    <>
      <div className="toolbar">
        {/* The table in use as a badge; who approved it and when are in its popover. */}
        <VersionBadge
          version={view.current.label}
          details={[
            view.current.approver
              ? intl.formatMessage(
                  { id: 'reference.approvedBy' },
                  { name: view.current.approver, when: dateTime(intl, view.current.publishedAt) },
                )
              : '',
            view.current.versionId === 'builtin'
              ? intl.formatMessage({ id: 'reference.builtin' })
              : '',
          ]}
        />
        {canEdit && (
          <div className="actions">
            {dataset !== 'vaccines.schedule' && (
              <Button onClick={() => setDialog('csv')}>
                <FormattedMessage id="reference.importCsv" />
              </Button>
            )}
            {dataset !== 'growth.weight' && dataset !== 'growth.length' && (
              <Button onClick={() => setDialog('edit')}>
                <FormattedMessage id={d ? 'reference.editDraft' : 'reference.newDraft'} />
              </Button>
            )}
          </div>
        )}
      </div>

      {d && (
        <Panel
          className="draft-panel"
          title={<FormattedMessage id={`reference.status.${d.status}`} />}
          note={
            <FormattedMessage
              id="reference.draftBy"
              values={{
                name: d.author,
                when: dateTime(intl, d.updatedAt),
                added: d.diff.added.length,
                changed: d.diff.changed.length,
                removed: d.diff.removed.length,
              }}
            />
          }
          aside={
            <div className="actions">
              <Button kind="ghost" onClick={() => setShowDraft(!showDraft)}>
                <FormattedMessage
                  id={showDraft ? 'reference.showCurrent' : 'reference.showDraft'}
                />
              </Button>
              {canEdit && d.status === 'draft' && (
                <>
                  <Button onClick={() => setDialog({ act: 'discard', versionId: d.versionId })}>
                    <FormattedMessage id="reference.act.discard" />
                  </Button>
                  <Button
                    kind="primary"
                    onClick={() => setDialog({ act: 'submit', versionId: d.versionId })}
                  >
                    <FormattedMessage id="reference.act.submit" />
                  </Button>
                </>
              )}
              {canApprove && d.status === 'pending' && (
                <>
                  <Button onClick={() => setDialog({ act: 'reject', versionId: d.versionId })}>
                    <FormattedMessage id="reference.act.reject" />
                  </Button>
                  <Button
                    kind="primary"
                    disabled={ownWorkBlocked(d.authorUid)}
                    title={
                      ownWorkBlocked(d.authorUid)
                        ? intl.formatMessage({ id: 'error.same-person' })
                        : undefined
                    }
                    onClick={() => setDialog({ act: 'approve', versionId: d.versionId })}
                  >
                    <FormattedMessage id="reference.act.approve" />
                  </Button>
                </>
              )}
            </div>
          }
        >
          {d.notes && <p className="quote">{d.notes}</p>}
          {d.rejection && (
            <p className="note note--warn">
              <RejectedBy id="reference.rejected" by={d.rejection.by} reason={d.rejection.reason} />
            </p>
          )}
          {d.status === 'pending' && ownWorkBlocked(d.authorUid) && (
            <p className="muted">
              <FormattedMessage id="reference.waitOther" />
            </p>
          )}
        </Panel>
      )}

      {dataset === 'growth.weight' || dataset === 'growth.length' ? (
        <GrowthTable dataset={dataset} rows={rows as GrowthRow[]} changed={changed} />
      ) : dataset === 'bottle.quickPicks' ? (
        <BottleTable rows={rows as BottleRow[]} changed={changed} />
      ) : (
        <VaccineTable rows={rows as VaccineDef[]} changed={changed} />
      )}

      <HistoryPanel
        view={view}
        canApprove={canApprove}
        onRollback={(versionId) => setDialog({ act: 'rollback', versionId })}
      />

      {dialog === 'csv' && (
        <CsvDialog
          view={view}
          dataset={dataset}
          onClose={() => setDialog(null)}
          onDone={onChanged}
        />
      )}
      {dialog === 'edit' && (
        <EditDialog
          view={view}
          dataset={dataset}
          onClose={() => setDialog(null)}
          onDone={onChanged}
        />
      )}
      {dialog && typeof dialog === 'object' && (
        <ActDialog
          act={dialog.act}
          versionId={dialog.versionId}
          onClose={() => setDialog(null)}
          onDone={onChanged}
        />
      )}
    </>
  );
}

export function GrowthTable({
  dataset,
  rows,
  changed,
}: {
  dataset: ReferenceDataset;
  rows: GrowthRow[];
  changed: Set<string>;
}) {
  const intl = useIntl();
  const [sex, setSex] = useState<'boy' | 'girl'>('boy');
  const [unit, setUnit] = useState<'week' | 'month'>('week');
  const shown = rows.filter((r) => r.sex === sex && r.unit === unit).sort((a, b) => a.age - b.age);
  const digits = dataset === 'growth.weight' ? 2 : 1;
  const n = (v: number) =>
    intl.formatNumber(v, { minimumFractionDigits: digits, maximumFractionDigits: digits });
  return (
    <div className="cols cols--2-1">
      <Panel className="panel--flush">
        <div className="panel__pad toolbar">
          <div className="actions">
            <Segmented
              label={intl.formatMessage({ id: 'reference.sex' })}
              value={sex}
              onChange={setSex}
              options={(['boy', 'girl'] as const).map((s) => ({
                value: s,
                label: <FormattedMessage id={`reference.sex.${s}`} />,
              }))}
            />
            <Segmented
              label={intl.formatMessage({ id: 'reference.unit' })}
              value={unit}
              onChange={setUnit}
              options={(['week', 'month'] as const).map((u) => ({
                value: u,
                label: <FormattedMessage id={`reference.unit.${u}`} />,
              }))}
            />
          </div>
          <span className="muted">
            <FormattedMessage
              id={`reference.rows.${unit}`}
              values={{ n: shown.length, max: shown.at(-1)?.age ?? 0 }}
            />
          </span>
        </div>
        <TableScroll min={480}>
          <table className="table">
            <thead>
              <tr>
                <th>
                  <FormattedMessage id="reference.col.age" />
                </th>
                <th>
                  <FormattedMessage id="reference.col.low" />
                </th>
                <th>
                  <FormattedMessage id="reference.col.median" />
                </th>
                <th>
                  <FormattedMessage id="reference.col.high" />
                </th>
              </tr>
            </thead>
            <tbody>
              {shown.map((r) => (
                <tr
                  key={r.age}
                  className={changed.has(rowKey(dataset, r)) ? 'row--changed' : undefined}
                >
                  <td>
                    {r.age === 0 ? (
                      <FormattedMessage id="reference.newborn" />
                    ) : (
                      <FormattedMessage id={`reference.age.${unit}`} values={{ n: r.age }} />
                    )}
                  </td>
                  <td>{n(r.low)}</td>
                  <td>{n(r.median)}</td>
                  <td>{n(r.high)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </TableScroll>
        <div className="panel__pad">
          <LockNote>
            <FormattedMessage id="reference.whoNote" />
          </LockNote>
        </div>
      </Panel>
      <Panel title={<FormattedMessage id="reference.howApp" />}>
        <ul className="qa-prose qa-prose--list">
          {(['normal', 'below', 'above'] as const).map((b) => (
            <li key={b}>
              <FormattedMessage
                id={`reference.band.${b}`}
                values={{ b: (c: ReactNode[]) => <strong>{c}</strong> }}
              />
            </li>
          ))}
        </ul>
        <dl className="kv">
          <dt>
            <FormattedMessage id="reference.unitLabel" />
          </dt>
          <dd>{dataset === 'growth.weight' ? 'kg' : 'cm'}</dd>
          <dt>
            <FormattedMessage id="reference.source" />
          </dt>
          <dd>WHO Child Growth Standards</dd>
        </dl>
      </Panel>
    </div>
  );
}

export function BottleTable({ rows, changed }: { rows: BottleRow[]; changed: Set<string> }) {
  const intl = useIntl();
  return (
    <Panel className="panel--flush">
      <div className="panel__pad">
        <p className="note">
          <FormattedMessage id="reference.bottleNote" />
        </p>
      </div>
      <TableScroll min={520}>
        <table className="table">
          <thead>
            <tr>
              <th>
                <FormattedMessage id="reference.col.band" />
              </th>
              <th>
                <FormattedMessage id="reference.col.picks" />
              </th>
              <th>
                <FormattedMessage id="reference.col.step" />
              </th>
            </tr>
          </thead>
          <tbody>
            {[...rows]
              .sort((a, b) => a.fromDay - b.fromDay)
              .map((r) => (
                <tr
                  key={r.fromDay}
                  className={changed.has(String(r.fromDay)) ? 'row--changed' : undefined}
                >
                  <td>{bandLabel(intl, r)}</td>
                  <td>
                    <span className="chips">
                      {r.picks.map((p) => (
                        <span key={p} className="qa-tag">
                          {p} ml
                        </span>
                      ))}
                    </span>
                  </td>
                  <td>{r.stepMl} ml</td>
                </tr>
              ))}
          </tbody>
        </table>
      </TableScroll>
    </Panel>
  );
}

export function VaccineTable({ rows, changed }: { rows: VaccineDef[]; changed: Set<string> }) {
  const intl = useIntl();
  const [programme, setProgramme] = useState<'all' | (typeof vaccineProgrammes)[number]>('all');
  const vi = intl.locale.startsWith('vi');
  const doses = rows
    .filter((v) => programme === 'all' || v.programme === programme)
    .flatMap((v) => v.months.map((m, i) => ({ v, m, dose: i + 1, next: v.months[i + 1] })))
    .sort((a, b) => a.m - b.m || a.v.id.localeCompare(b.v.id));
  const total = rows.reduce((n, v) => n + v.months.length, 0);
  return (
    <Panel className="panel--flush">
      <div className="panel__pad toolbar">
        <SelectMenu
          value={programme}
          onChange={setProgramme}
          label={intl.formatMessage({ id: 'reference.col.programme' })}
          options={[
            {
              value: 'all' as typeof programme,
              label: intl.formatMessage({ id: 'reference.programme.all' }),
            },
            ...vaccineProgrammes.map((p) => ({
              value: p as typeof programme,
              label: intl.formatMessage({ id: `reference.programme.${p}` }),
            })),
          ]}
        />
        <span className="muted">
          <FormattedMessage
            id="reference.doses"
            values={{ n: total, max: Math.max(0, ...rows.flatMap((v) => v.months)) }}
          />
        </span>
      </div>
      <TableScroll min={760}>
        <table className="table">
          <thead>
            <tr>
              <th>
                <FormattedMessage id="reference.col.milestone" />
              </th>
              <th>
                <FormattedMessage id="reference.col.vaccine" />
              </th>
              <th>
                <FormattedMessage id="reference.col.dose" />
              </th>
              <th>
                <FormattedMessage id="reference.col.programme" />
              </th>
              <th>
                <FormattedMessage id="reference.col.note" />
              </th>
              <th>
                <FormattedMessage id="reference.col.next" />
              </th>
            </tr>
          </thead>
          <tbody>
            {doses.map(({ v, m, dose, next }) => (
              <tr
                key={`${v.id}_${dose}`}
                className={changed.has(v.id) ? 'row--changed' : undefined}
              >
                <td className="nowrap">
                  {m === 0 ? (
                    <FormattedMessage id="reference.newborn" />
                  ) : (
                    <FormattedMessage id="reference.age.month" values={{ n: m }} />
                  )}
                </td>
                <td>
                  <strong>{vi ? v.name.vi : v.name.en}</strong>
                </td>
                <td>{dose}</td>
                <td>
                  <FormattedMessage id={`reference.programme.${v.programme}`} />
                </td>
                <td className="muted">{vi ? v.about.vi : v.about.en}</td>
                <td className="nowrap">
                  {next === undefined ? (
                    v.yearly ? (
                      <FormattedMessage id="reference.yearly" />
                    ) : (
                      '—'
                    )
                  ) : (
                    <FormattedMessage id="reference.nextIn" values={{ n: next - m }} />
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </TableScroll>
      <div className="panel__pad">
        <LockNote>
          <FormattedMessage id="reference.vaccineNote" />
        </LockNote>
      </div>
    </Panel>
  );
}

function HistoryPanel({
  view,
  canApprove,
  onRollback,
}: {
  view: ReferenceView;
  canApprove: boolean;
  onRollback: (versionId: string) => void;
}) {
  const intl = useIntl();
  const items = view.history.filter((h) => h.status !== 'draft' && h.status !== 'pending');
  if (!items.length) return null;
  return (
    <Panel className="panel--flush" title={<FormattedMessage id="reference.history" />}>
      <TableScroll min={600}>
        <table className="table">
          <tbody>
            {items.map((h) => (
              <tr key={h.versionId}>
                <td className="mono">{h.label ?? '—'}</td>
                <td>
                  <Pill tone={statusTone[h.status] ?? 'muted'}>
                    <FormattedMessage id={`reference.status.${h.status}`} />
                  </Pill>
                </td>
                <td>
                  <FormattedMessage
                    id="reference.historyBy"
                    values={{ author: h.author, approver: h.approver ?? '—' }}
                  />
                </td>
                <td className="nowrap">{dateTime(intl, h.publishedAt ?? h.updatedAt)}</td>
                <td className="cell-actions">
                  {canApprove && h.status === 'retired' && (
                    <Button kind="ghost" onClick={() => onRollback(h.versionId)}>
                      <FormattedMessage id="reference.act.rollback" />
                    </Button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </TableScroll>
    </Panel>
  );
}

function ActDialog({
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
    <Modal title={<FormattedMessage id={`reference.confirm.${act}`} />} onClose={onClose}>
      <p className="modal__sub">
        <FormattedMessage id={`reference.confirm.${act}.note`} />
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
          kind={act === 'discard' || act === 'reject' ? 'danger' : 'primary'}
          disabled={busy}
          onClick={() => {
            setBusy(true);
            setError(null);
            api
              .call('staffReferenceAct', { versionId, action: act })
              .then(() => {
                onClose();
                onDone();
              })
              .catch((e: unknown) => setError(asApiError(e)))
              .finally(() => setBusy(false));
          }}
        >
          <FormattedMessage id={`reference.act.${act}`} />
        </Button>
      </div>
    </Modal>
  );
}

function saveDraft(
  api: ReturnType<typeof useApi>,
  dataset: ReferenceDataset,
  rows: unknown[],
  notes: string,
  source: 'edit' | 'csv',
) {
  return api.call('staffReferenceDraft', { dataset, rows, notes: notes.trim(), source });
}

/** C03 "Nhập CSV": parse in the browser, list row errors, show the difference, save a draft. */
export function CsvDialog({
  view,
  dataset,
  onClose,
  onDone,
}: {
  view: ReferenceView;
  dataset: ReferenceDataset;
  onClose: () => void;
  onDone: () => void;
}) {
  const intl = useIntl();
  const api = useApi();
  const fileId = useId();
  const growth = dataset === 'growth.weight' || dataset === 'growth.length';
  const [sex, setSex] = useState<'boy' | 'girl'>('boy');
  const [unit, setUnit] = useState<'week' | 'month'>('week');
  const [text, setText] = useState<string | null>(null);
  const [name, setName] = useState('');
  const [notes, setNotes] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const base = (view.draft?.rows ?? view.current.rows) as unknown[];
  const parsed =
    text === null ? null : parseReferenceCsv(dataset, text, growth ? { sex, unit } : {});
  // A growth file replaces one sex × unit slice; a bottle file replaces the whole table.
  const merged =
    parsed && !parsed.errors.length
      ? growth
        ? [
            ...(base as GrowthRow[]).filter((r) => !(r.sex === sex && r.unit === unit)),
            ...(parsed.rows as GrowthRow[]),
          ]
        : parsed.rows
      : null;
  const differs = merged
    ? (() => {
        const before = new Map(base.map((r) => [rowKey(dataset, r), JSON.stringify(r)]));
        return merged.filter((r) => before.get(rowKey(dataset, r)) !== JSON.stringify(r)).length;
      })()
    : 0;
  return (
    <Modal
      wide
      title={<FormattedMessage id={`reference.csvTitle.${growth ? 'growth' : 'bottle'}`} />}
      onClose={onClose}
    >
      <p className="modal__sub">
        <FormattedMessage id="reference.csvSub" />
      </p>
      {growth && (
        <div className="actions">
          <Segmented
            label={intl.formatMessage({ id: 'reference.sex' })}
            value={sex}
            onChange={setSex}
            options={(['boy', 'girl'] as const).map((s) => ({
              value: s,
              label: <FormattedMessage id={`reference.sex.${s}`} />,
            }))}
          />
          <Segmented
            label={intl.formatMessage({ id: 'reference.unit' })}
            value={unit}
            onChange={setUnit}
            options={(['week', 'month'] as const).map((u) => ({
              value: u,
              label: <FormattedMessage id={`reference.unit.${u}`} />,
            }))}
          />
        </div>
      )}
      <div className="field">
        <label className="field__label" htmlFor={fileId}>
          <FormattedMessage id="reference.csvFile" />
        </label>
        <input
          id={fileId}
          type="file"
          accept=".csv,text/csv"
          className="field__input"
          onChange={(e) => {
            const f = e.target.files?.[0];
            if (!f) return;
            setName(f.name);
            void f.text().then(setText);
          }}
        />
        <p className="field__help">
          <FormattedMessage id={`reference.csvColumns.${growth ? 'growth' : 'bottle'}`} />
        </p>
      </div>
      {parsed && (
        <ul className="steps">
          <li className={`steps__item steps__item--${parsed.errors.length ? 'failed' : 'done'}`}>
            <span aria-hidden="true">{parsed.errors.length ? '✕' : '✓'}</span>
            <FormattedMessage id="reference.csvRows" values={{ name, n: parsed.rows.length }} />
          </li>
          {parsed.errors.slice(0, 8).map((e, i) => (
            <li key={i} className="steps__item steps__item--failed">
              <span aria-hidden="true">✕</span>
              <CsvError line={e.line} message={e.message} />
            </li>
          ))}
          {merged && (
            <li className="steps__item steps__item--todo">
              <span aria-hidden="true">ⓘ</span>
              <FormattedMessage id="reference.csvDiffers" values={{ n: differs }} />
            </li>
          )}
        </ul>
      )}
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
          disabled={busy || !merged || differs === 0}
          onClick={() => {
            if (!merged) return;
            setBusy(true);
            setError(null);
            saveDraft(api, dataset, merged, notes, 'csv')
              .then(() => {
                onClose();
                onDone();
              })
              .catch((e: unknown) => setError(asApiError(e)))
              .finally(() => setBusy(false));
          }}
        >
          <FormattedMessage id="reference.saveDraft" />
        </Button>
      </div>
    </Modal>
  );
}

/** C02 / C04 editing: bands and quick picks, or vaccine doses (months, programme, note). */
function EditDialog({
  view,
  dataset,
  onClose,
  onDone,
}: {
  view: ReferenceView;
  dataset: ReferenceDataset;
  onClose: () => void;
  onDone: () => void;
}) {
  const api = useApi();
  const intl = useIntl();
  const start = (view.draft?.rows ?? view.current.rows) as unknown[];
  const [bottle, setBottle] = useState<BottleRow[]>(() =>
    dataset === 'bottle.quickPicks'
      ? [...(start as BottleRow[])].sort((a, b) => a.fromDay - b.fromDay)
      : [],
  );
  const [vaccines, setVaccines] = useState<VaccineDef[]>(() =>
    dataset === 'vaccines.schedule'
      ? (start as VaccineDef[]).map((v) => ({ ...v, months: [...v.months] }))
      : [],
  );
  const [notes, setNotes] = useState(view.draft?.notes ?? '');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const num = (s: string) => (s.trim() === '' ? Number.NaN : Number(s));
  const setBand = (i: number, patch: Partial<BottleRow>) =>
    setBottle((rows) => {
      const next = rows.map((r, j) => (j === i ? { ...r, ...patch } : r));
      // Bands join: changing where one ends moves where the next starts.
      if (patch.toDay !== undefined && next[i + 1] && patch.toDay !== null)
        next[i + 1] = { ...next[i + 1]!, fromDay: patch.toDay };
      return next;
    });
  const rows = dataset === 'bottle.quickPicks' ? bottle : vaccines;
  return (
    <Modal wide title={<FormattedMessage id="reference.editTitle" />} onClose={onClose}>
      {dataset === 'bottle.quickPicks' ? (
        <TableScroll min={640}>
          <table className="table">
            <thead>
              <tr>
                <th>
                  <FormattedMessage id="reference.col.fromDay" />
                </th>
                <th>
                  <FormattedMessage id="reference.col.toDay" />
                </th>
                <th>
                  <FormattedMessage id="reference.col.picks" />
                </th>
                <th>
                  <FormattedMessage id="reference.col.step" />
                </th>
                <th />
              </tr>
            </thead>
            <tbody>
              {bottle.map((r, i) => (
                <tr key={i}>
                  <td>{r.fromDay}</td>
                  <td>
                    <input
                      className="field__input input--sm"
                      inputMode="numeric"
                      value={r.toDay ?? ''}
                      placeholder="∞"
                      aria-label={intl.formatMessage({ id: 'reference.col.toDay' })}
                      onChange={(e) =>
                        setBand(i, { toDay: e.target.value === '' ? null : num(e.target.value) })
                      }
                    />
                  </td>
                  <td>
                    <span className="chips">
                      {r.picks.map((p, k) => (
                        <input
                          key={k}
                          className="field__input input--sm"
                          inputMode="numeric"
                          value={Number.isNaN(p) ? '' : p}
                          aria-label={intl.formatMessage({ id: 'reference.col.picks' })}
                          onChange={(e) =>
                            setBand(i, {
                              picks: r.picks.map((x, j) => (j === k ? num(e.target.value) : x)),
                            })
                          }
                        />
                      ))}
                    </span>
                  </td>
                  <td>
                    <input
                      className="field__input input--sm"
                      inputMode="numeric"
                      value={Number.isNaN(r.stepMl) ? '' : r.stepMl}
                      aria-label={intl.formatMessage({ id: 'reference.col.step' })}
                      onChange={(e) => setBand(i, { stepMl: num(e.target.value) })}
                    />
                  </td>
                  <td>
                    {bottle.length > 1 && (
                      <Button
                        kind="ghost"
                        onClick={() =>
                          setBottle((rows) => {
                            const next = rows.filter((_, j) => j !== i);
                            if (next[i] && i > 0)
                              next[i] = {
                                ...next[i]!,
                                fromDay: next[i - 1]!.toDay ?? next[i]!.fromDay,
                              };
                            if (i === 0 && next[0]) next[0] = { ...next[0], fromDay: 0 };
                            if (next.length)
                              next[next.length - 1] = { ...next[next.length - 1]!, toDay: null };
                            return next;
                          })
                        }
                      >
                        <FormattedMessage id="reference.removeRow" />
                      </Button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </TableScroll>
      ) : (
        <div className="stack">
          {vaccines.map((v, i) => (
            <div key={v.id} className="vaccine-edit">
              <strong>{intl.locale.startsWith('vi') ? v.name.vi : v.name.en}</strong>
              <label className="field">
                <span className="field__label">
                  <FormattedMessage id="reference.months" />
                </span>
                <input
                  className="field__input"
                  value={v.months.join(', ')}
                  onChange={(e) =>
                    setVaccines((list) =>
                      list.map((x, j) =>
                        j === i
                          ? {
                              ...x,
                              months: e.target.value
                                .split(',')
                                .map((s) => num(s))
                                .filter((n) => !Number.isNaN(n)),
                            }
                          : x,
                      ),
                    )
                  }
                />
              </label>
              <label className="field">
                <span className="field__label">
                  <FormattedMessage id="reference.col.programme" />
                </span>
                <select
                  className="field__input"
                  value={v.programme}
                  onChange={(e) =>
                    setVaccines((list) =>
                      list.map((x, j) =>
                        j === i
                          ? { ...x, programme: e.target.value as VaccineDef['programme'] }
                          : x,
                      ),
                    )
                  }
                >
                  {vaccineProgrammes.map((p) => (
                    <option key={p} value={p}>
                      {intl.formatMessage({ id: `reference.programme.${p}` })}
                    </option>
                  ))}
                </select>
              </label>
              <label className="field">
                <span className="field__label">
                  <FormattedMessage id="reference.noteVi" />
                </span>
                <textarea
                  className="field__input"
                  rows={2}
                  value={v.about.vi}
                  onChange={(e) =>
                    setVaccines((list) =>
                      list.map((x, j) =>
                        j === i ? { ...x, about: { ...x.about, vi: e.target.value } } : x,
                      ),
                    )
                  }
                />
              </label>
              <label className="field">
                <span className="field__label">
                  <FormattedMessage id="reference.noteEn" />
                </span>
                <textarea
                  className="field__input"
                  rows={2}
                  value={v.about.en}
                  onChange={(e) =>
                    setVaccines((list) =>
                      list.map((x, j) =>
                        j === i ? { ...x, about: { ...x.about, en: e.target.value } } : x,
                      ),
                    )
                  }
                />
              </label>
            </div>
          ))}
          <p className="field__help">
            <FormattedMessage id="reference.vaccineEditNote" />
          </p>
        </div>
      )}
      <NotesField value={notes} onChange={setNotes} />
      {error && (
        <p className="error" role="alert">
          <FormattedMessage id={errorMessageId(error)} />
        </p>
      )}
      <div className="modal__actions">
        {dataset === 'bottle.quickPicks' && (
          <Button
            onClick={() =>
              setBottle((rows) => {
                const last = rows[rows.length - 1]!;
                const split = last.fromDay + 30;
                return [
                  ...rows.slice(0, -1),
                  { ...last, toDay: split },
                  { fromDay: split, toDay: null, picks: [...last.picks], stepMl: last.stepMl },
                ];
              })
            }
          >
            <FormattedMessage id="reference.addBand" />
          </Button>
        )}
        <Button onClick={onClose}>
          <FormattedMessage id="action.cancel" />
        </Button>
        <Button
          kind="primary"
          disabled={busy}
          onClick={() => {
            setBusy(true);
            setError(null);
            saveDraft(api, dataset, rows, notes, 'edit')
              .then(() => {
                onClose();
                onDone();
              })
              .catch((e: unknown) => setError(asApiError(e)))
              .finally(() => setBusy(false));
          }}
        >
          <FormattedMessage id="reference.saveDraft" />
        </Button>
      </div>
    </Modal>
  );
}

/** The parser's row problems (codes from packages/contracts/src/reference.ts) in words (D-012). */
const csvMessage: Record<string, string> = {
  'csv-unsupported': 'reference.csv.unsupported',
  'low < median < high': 'reference.csv.lowMedianHigh',
  'toDay > fromDay': 'reference.csv.toDay',
  'picks increase': 'reference.csv.picks',
  empty: 'reference.csv.empty',
  'bands-gap': 'reference.csv.bandsGap',
  'ages-order': 'reference.csv.agesOrder',
};

export function CsvError({ line, message }: { line: number; message: string }) {
  const intl = useIntl();
  const id = message.startsWith('header:')
    ? 'reference.csv.header'
    : (csvMessage[message] ?? 'reference.csv.invalid');
  const text = intl.formatMessage({ id }, { cols: message.slice('header:'.length) });
  return <FormattedMessage id="reference.csvError" values={{ line, message: text }} />;
}
