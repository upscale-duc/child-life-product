import {
  inboxGroups,
  staffCan,
  type InboxGroup,
  type NotificationOpsConfig,
} from '@child-life/contracts';
import { useId, useState, type ReactNode } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { ApiError, useApi } from '../../api';
import { Notice, Section, useConfirm } from '../../content-kit';
import { useNavigate, useStaff } from '../../context';
import { Button } from '../../ui';
import { StatsLoader } from './Overview';
import { ErrorLine, rangeEnding } from './shared';

export function SettingsTab() {
  // The switches come with the stats (one callable reads `config/notifications`).
  const range = rangeEnding(1);
  return (
    <StatsLoader {...range}>
      {(data, reload) => <SettingsView ops={data.ops} onSaved={reload} />}
    </StatsLoader>
  );
}

const sameOps = (a: NotificationOpsConfig, b: NotificationOpsConfig) =>
  a.templatesEnabled === b.templatesEnabled &&
  a.retryEnabled === b.retryEnabled &&
  inboxGroups.every((g) => a.pushPaused[g] === b.pushPaused[g]);

function SwitchRow({
  label,
  note,
  checked,
  disabled,
  onChange,
  warn,
}: {
  label: ReactNode;
  note: ReactNode;
  checked: boolean;
  disabled: boolean;
  onChange: (v: boolean) => void;
  warn?: boolean;
}) {
  const id = useId();
  return (
    <li className="flex items-start justify-between gap-4 border-b py-3 last:border-b-0">
      <div className="grid gap-0.5">
        <Label htmlFor={id} className={warn ? 'text-destructive' : undefined}>
          {label}
        </Label>
        <span className="text-[13px] text-muted-foreground">{note}</span>
      </div>
      <Switch id={id} checked={checked} disabled={disabled} onCheckedChange={onChange} />
    </li>
  );
}

/**
 * Cài đặt: the operational switches (`config/notifications`). Anyone with notifications.view sees
 * them; changing them needs notifications.ops, and the server audits every save. Smart Engagement
 * flags stay in Tính năng & Premium.
 */
export function SettingsView({
  ops,
  onSaved,
}: {
  ops: NotificationOpsConfig;
  onSaved?: () => void;
}) {
  const intl = useIntl();
  const api = useApi();
  const staff = useStaff();
  const navigate = useNavigate();
  const canOps = staffCan(staff.levels, 'notifications.ops');
  const [saved, setSaved] = useState(ops);
  const [draft, setDraft] = useState(ops);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<ApiError | null>(null);
  const [done, setDone] = useState(false);
  const { ask, dialog } = useConfirm();
  const changed = !sameOps(draft, saved);
  const setPaused = (g: InboxGroup, paused: boolean) =>
    setDraft((d) => ({ ...d, pushPaused: { ...d.pushPaused, [g]: paused } }));
  const save = async () => {
    setBusy(true);
    setError(null);
    setDone(false);
    try {
      const res = await api.call<{ ops: NotificationOpsConfig }>('staffSetNotificationOps', {
        config: draft,
      });
      setSaved(res.ops);
      setDraft(res.ops);
      setDone(true);
      onSaved?.();
    } catch (e) {
      setError(e instanceof ApiError ? e : new ApiError('unknown', null));
    } finally {
      setBusy(false);
    }
  };
  const careTurningOff = draft.pushPaused.care && !saved.pushPaused.care;
  return (
    <div className="stack">
      {!canOps && (
        <Notice>
          <FormattedMessage id="ntf.settings.readOnly" />
        </Notice>
      )}
      {draft.pushPaused.care && (
        <Notice tone="error" title={<FormattedMessage id="ntf.settings.careWarn.title" />}>
          <FormattedMessage id="ntf.settings.careWarn" />
        </Notice>
      )}
      <ErrorLine error={error} />
      {done && !changed && (
        <Notice tone="ok">
          <FormattedMessage id="ntf.settings.saved" />
        </Notice>
      )}
      <Section
        title={<FormattedMessage id="ntf.settings.ops" />}
        description={<FormattedMessage id="ntf.settings.opsNote" />}
        actions={
          canOps && (
            <>
              {changed && (
                <Button disabled={busy} onClick={() => setDraft(saved)}>
                  <FormattedMessage id="action.cancel" />
                </Button>
              )}
              <Button
                kind="primary"
                disabled={!changed || busy}
                onClick={() =>
                  ask({
                    title: intl.formatMessage({ id: 'ntf.settings.confirm.title' }),
                    body: intl.formatMessage({
                      id: careTurningOff
                        ? 'ntf.settings.confirm.care'
                        : 'ntf.settings.confirm.body',
                    }),
                    confirmLabel: intl.formatMessage({ id: 'ntf.settings.save' }),
                    destructive: careTurningOff,
                    onConfirm: () => void save(),
                  })
                }
              >
                <FormattedMessage id="ntf.settings.save" />
              </Button>
            </>
          )
        }
      >
        <ul>
          <SwitchRow
            label={<FormattedMessage id="ntf.ops.templatesEnabled" />}
            note={<FormattedMessage id="ntf.ops.templatesEnabled.note" />}
            checked={draft.templatesEnabled}
            disabled={!canOps || busy}
            onChange={(v) => setDraft((d) => ({ ...d, templatesEnabled: v }))}
          />
          <SwitchRow
            label={<FormattedMessage id="ntf.ops.retryEnabled" />}
            note={<FormattedMessage id="ntf.ops.retryEnabled.note" />}
            checked={draft.retryEnabled}
            disabled={!canOps || busy}
            onChange={(v) => setDraft((d) => ({ ...d, retryEnabled: v }))}
          />
        </ul>
      </Section>
      <Section
        title={<FormattedMessage id="ntf.settings.push" />}
        description={<FormattedMessage id="ntf.settings.pushNote" />}
      >
        <ul>
          {inboxGroups.map((g) => (
            <SwitchRow
              key={g}
              label={
                <FormattedMessage
                  id="ntf.ops.pushFor"
                  values={{ name: intl.formatMessage({ id: `ntf.group.${g}` }) }}
                />
              }
              note={
                <FormattedMessage id={g === 'care' ? 'ntf.ops.care.note' : 'ntf.ops.group.note'} />
              }
              checked={!draft.pushPaused[g]}
              disabled={!canOps || busy}
              warn={g === 'care' && draft.pushPaused.care}
              onChange={(sending) => setPaused(g, !sending)}
            />
          ))}
        </ul>
      </Section>
      <Notice
        title={<FormattedMessage id="ntf.settings.flags.title" />}
        action={
          staffCan(staff.levels, 'features.view') ? (
            <Button onClick={() => navigate('features')}>
              <FormattedMessage id="ntf.settings.flags.open" />
            </Button>
          ) : undefined
        }
      >
        <FormattedMessage id="ntf.settings.flags" />
      </Notice>
      {dialog}
    </div>
  );
}
