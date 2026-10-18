import { useState } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { toast } from 'sonner';
import { useApi, useLoad } from './api';
import { useStaff } from './context';
import { CheckRow } from './screens/form-controls';
import { asApiError } from './screens/content-common';
import { Button, Modal, Panel, Pill, ReasonField, errorMessageId, reasonOk } from './ui';

/** `staffContentPolicy` (D-079): who approves content and reference data. */
export interface ContentPolicyView {
  ownerSelfApprove: boolean;
  reviewRequiredOnProd: boolean;
  canChange: boolean;
}

export const useContentPolicy = () =>
  useLoad<ContentPolicyView>('staffContentPolicy', {}, 'content-policy');

/**
 * Whether [uid]'s own work is closed to me: the two-person rule (D-058, P-138), unless I am the
 * Owner and the policy lets the Owner approve their own (D-079). The server checks again.
 */
export function useOwnWorkBlocked(selfUid: string) {
  const staff = useStaff();
  const [policy] = useContentPolicy();
  const ownerMay =
    policy.status === 'ok' && policy.data.ownerSelfApprove && staff.roles.includes('owner');
  return (uid: string | null | undefined) => uid === selfUid && !ownerMay;
}

/** "Chính sách duyệt": both switches; the Owner changes them with a reason (audited). */
export function ContentPolicyPanel() {
  const intl = useIntl();
  const api = useApi();
  const [policy, reload] = useContentPolicy();
  const [editing, setEditing] = useState(false);
  const [selfApprove, setSelfApprove] = useState(false);
  const [review, setReview] = useState(true);
  const [reason, setReason] = useState('');
  const [busy, setBusy] = useState(false);
  if (policy.status !== 'ok') return null;
  const p = policy.data;
  const onOff = (on: boolean) => (
    <Pill tone={on ? 'ok' : 'muted'}>
      <FormattedMessage id={on ? 'policy.on' : 'policy.off'} />
    </Pill>
  );
  const save = async () => {
    setBusy(true);
    try {
      await api.call('staffSetContentPolicy', {
        ownerSelfApprove: selfApprove,
        reviewRequiredOnProd: review,
        reason,
      });
      toast.success(intl.formatMessage({ id: 'policy.saved' }));
      setEditing(false);
      reload();
    } catch (e) {
      toast.error(intl.formatMessage({ id: errorMessageId(asApiError(e)) }));
    } finally {
      setBusy(false);
    }
  };
  return (
    <Panel title={<FormattedMessage id="policy.title" />}>
      <dl className="kv">
        <dt>
          <FormattedMessage id="policy.selfApprove" />
        </dt>
        <dd>{onOff(p.ownerSelfApprove)}</dd>
        <dt>
          <FormattedMessage id="policy.reviewOnProd" />
        </dt>
        <dd>{onOff(p.reviewRequiredOnProd)}</dd>
      </dl>
      <p className="muted">
        <FormattedMessage id="policy.note" />
      </p>
      {p.canChange && (
        <Button
          onClick={() => {
            setSelfApprove(p.ownerSelfApprove);
            setReview(p.reviewRequiredOnProd);
            setReason('');
            setEditing(true);
          }}
        >
          <FormattedMessage id="policy.change" />
        </Button>
      )}
      {editing && (
        <Modal title={<FormattedMessage id="policy.title" />} onClose={() => setEditing(false)}>
          <CheckRow
            label={<FormattedMessage id="policy.selfApprove" />}
            checked={selfApprove}
            onChange={setSelfApprove}
          />
          <CheckRow
            label={<FormattedMessage id="policy.reviewOnProd" />}
            checked={review}
            onChange={setReview}
          />
          <ReasonField value={reason} onChange={setReason} required />
          <div className="modal__actions">
            <Button onClick={() => setEditing(false)}>
              <FormattedMessage id="action.cancel" />
            </Button>
            <Button kind="primary" disabled={busy || !reasonOk(reason)} onClick={save}>
              <FormattedMessage id="policy.save" />
            </Button>
          </div>
        </Modal>
      )}
    </Panel>
  );
}
