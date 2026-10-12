import type { DocumentSnapshot, Firestore } from 'firebase-admin/firestore';
/**
 * Transactional email (invites R-034 / Figma 14e, account and service mail, sign-in mail). Mail is
 * queued in `mail/{id}` by callables and delivered by a trigger through a provider adapter: Resend
 * since D-054 (sender hello@childlife.app, replies to the GoDaddy mailbox). The copy and layout live
 * in `mail-templates.ts`. No child data beyond what the inviter typed is ever logged.
 */
import {
  accountTemplates,
  renderAccountEmail,
  renderInviteEmail,
  type AccountMailData,
  type AccountTemplate,
  type InviteMailData,
  type Locale,
} from './mail-templates.js';

export {
  accountTemplates,
  renderAccountEmail,
  renderInviteEmail,
  type AccountMailData,
  type AccountTemplate,
  type InviteMailData,
  type Locale,
};

export interface OutgoingMail {
  to: string;
  subject: string;
  html: string;
  text: string;
  /** Only for mail that may be refused (invites); service and sign-in mail has none. */
  unsubscribeUrl?: string;
  /** The queue document id: the provider sends it once even when a retry repeats the call. */
  idempotencyKey?: string;
}

export interface MailSender {
  send(mail: OutgoingMail): Promise<void>;
}

/** Delivers one queued mail document; returns the resulting status. */
export async function deliverMail(
  doc: DocumentSnapshot,
  sender: MailSender | null,
  config: { webOrigin: string; adminOrigin?: string; functionsOrigin?: string; now: Date },
): Promise<'sent' | 'waiting-provider' | 'failed' | 'superseded'> {
  const mail = doc.data();
  if (!mail || mail.status === 'sent') return 'sent';
  if (mail.status === 'superseded') return 'superseded';
  const attempts = ((mail.attempts as number | undefined) ?? 0) + 1;
  // An invite that waited (no provider, retries) is dropped once the same invite was mailed again
  // to the same address: the newer one already went or is going out.
  if (mail.template === 'invite' && (await newerInviteMail(doc))) {
    await doc.ref.update({ status: 'superseded', attempts, updatedAt: config.now });
    return 'superseded';
  }
  if (!sender) {
    await doc.ref.update({ status: 'waiting-provider', attempts, updatedAt: config.now });
    return 'waiting-provider';
  }
  const unsubscribeUrl = `${config.webOrigin}/u/${mail.unsubscribeToken as string}`;
  try {
    const template = mail.template as string;
    const rendered =
      template === 'invite'
        ? renderInviteEmail(mail.locale as Locale, mail.data as InviteMailData, {
            webOrigin: config.webOrigin,
            unsubscribeUrl,
          })
        : (accountTemplates as readonly string[]).includes(template)
          ? renderAccountEmail(
              template as AccountTemplate,
              mail.locale as Locale,
              withDownloadUrl((mail.data ?? {}) as AccountMailData, config.functionsOrigin),
              {
                adminOrigin: config.adminOrigin ?? 'https://admin.childlife.app',
                webOrigin: config.webOrigin,
              },
            )
          : null;
    if (!rendered) throw new Error(`Unknown template ${template}`);
    await sender.send({
      to: mail.to as string,
      ...(template === 'invite' ? { unsubscribeUrl } : {}),
      idempotencyKey: `mail-${doc.id}`,
      ...rendered,
    });
    await doc.ref.update({
      status: 'sent',
      attempts,
      sentAt: config.now,
      error: null,
      // The export link lives in the email only; the queue keeps no usable copy.
      ...(template === 'exportReady' ? { 'data.token': null } : {}),
    });
    return 'sent';
  } catch (error) {
    await doc.ref.update({
      status: attempts >= 5 ? 'failed' : 'retry',
      attempts,
      error: String(error).slice(0, 300),
      updatedAt: config.now,
    });
    return 'failed';
  }
}

/** "Tải tệp về" (exportReady): the one-click link, served by the `exportDownload` Function. */
function withDownloadUrl(d: AccountMailData, functionsOrigin: string | undefined): AccountMailData {
  if (!d.jobId || !d.token || !functionsOrigin) return d;
  return { ...d, downloadUrl: `${functionsOrigin}/exportDownload/${d.jobId}/${d.token}` };
}

async function newerInviteMail(doc: DocumentSnapshot): Promise<boolean> {
  const created = doc.get('createdAt') as { toMillis(): number } | Date | undefined;
  const at = created instanceof Date ? created.getTime() : (created?.toMillis() ?? 0);
  const same = await doc.ref.parent
    .where('to', '==', doc.get('to'))
    .where('template', '==', 'invite')
    .where('data.code', '==', doc.get('data.code'))
    .get();
  return same.docs.some((d) => {
    if (d.id === doc.id) return false;
    const c = d.get('createdAt') as { toMillis(): number } | Date | undefined;
    return (c instanceof Date ? c.getTime() : (c?.toMillis() ?? 0)) > at;
  });
}

/** "Huỷ nhận email": records the suppression; returns false for unknown tokens. */
export async function unsubscribe(db: Firestore, token: string, now: Date): Promise<boolean> {
  if (!/^[A-Za-z0-9_-]{32}$/.test(token)) return false;
  const ref = db.doc(`emailUnsubscribeTokens/${token}`);
  const doc = await ref.get();
  if (!doc.exists) return false;
  await db.doc(`emailSuppressions/${doc.get('emailHash') as string}`).set({ createdAt: now });
  return true;
}
