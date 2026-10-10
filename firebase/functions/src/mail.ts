import type { DocumentSnapshot, Firestore } from 'firebase-admin/firestore';

/**
 * Transactional email (invites, R-034 / Figma 14e). Mail is queued in `mail/{id}` by callables
 * and delivered by a trigger through a provider adapter (AWS SES, owner decision D-020).
 * No child data beyond what the inviter typed is ever logged.
 */

export type Locale = 'vi' | 'en';

export interface OutgoingMail {
  to: string;
  subject: string;
  html: string;
  text: string;
  unsubscribeUrl: string;
}

export interface MailSender {
  send(mail: OutgoingMail): Promise<void>;
}

export interface InviteMailData {
  inviterName: string;
  babyNickname: string;
  role: 'coParent' | 'caregiver' | 'relative';
  code: string;
  token: string | null;
  expiresAt: string;
}

const roleLabel: Record<Locale, Record<InviteMailData['role'], string>> = {
  vi: { coParent: 'Cùng nuôi', caregiver: 'Người chăm sóc', relative: 'Người thân' },
  en: { coParent: 'Co-parent', caregiver: 'Caregiver', relative: 'Family member' },
};

const escape = (value: string) =>
  value.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

/** "15 thg 10" / "15 Oct" in Vietnam time (the expiry line of 14e). */
function shortDate(iso: string, locale: Locale): string {
  const date = new Date(iso);
  return locale === 'vi'
    ? `${new Intl.DateTimeFormat('vi-VN', { day: 'numeric', timeZone: 'Asia/Ho_Chi_Minh' }).format(date)} thg ${new Intl.DateTimeFormat('vi-VN', { month: 'numeric', timeZone: 'Asia/Ho_Chi_Minh' }).format(date)}`
    : new Intl.DateTimeFormat('en-GB', {
        day: 'numeric',
        month: 'short',
        timeZone: 'Asia/Ho_Chi_Minh',
      }).format(date);
}

/** Renders 14e "Mai mời bạn cùng chăm Teddy" (vi / en). */
export function renderInviteEmail(
  locale: Locale,
  data: InviteMailData,
  links: { webOrigin: string; unsubscribeUrl: string },
): Omit<OutgoingMail, 'to' | 'unsubscribeUrl'> {
  const t =
    locale === 'vi'
      ? {
          subject: `${data.inviterName} mời bạn cùng chăm ${data.babyNickname}`,
          role: `Vai trò: ${roleLabel.vi[data.role]}`,
          cta: 'Nhận lời mời',
          orCode: `Hoặc nhập mã trong app · hết hạn ${shortDate(data.expiresAt, 'vi')}`,
          ignore: 'Không quen người gửi? Bỏ qua email này.',
          footer: 'Child Life · Riêng tư cho gia đình',
          unsubscribe: 'Huỷ nhận email',
        }
      : {
          subject: `${data.inviterName} invited you to care for ${data.babyNickname}`,
          role: `Role: ${roleLabel.en[data.role]}`,
          cta: 'Accept invite',
          orCode: `Or enter the code in the app · expires ${shortDate(data.expiresAt, 'en')}`,
          ignore: "Don't know the sender? Ignore this email.",
          footer: 'Child Life · Private for families',
          unsubscribe: 'Unsubscribe',
        };
  const link = data.token ? `${links.webOrigin}/i/${data.token}` : links.webOrigin;
  const code = `${data.code.slice(0, 3)} ${data.code.slice(3)}`;
  const html = `<!doctype html><html lang="${locale}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width"></head>
<body style="margin:0;background:#F6FCFB;font-family:'Be Vietnam Pro',Arial,sans-serif;color:#173D44">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0"><tr><td align="center" style="padding:24px 12px">
<table role="presentation" width="100%" style="max-width:480px;background:#ffffff;border-radius:24px;padding:28px" cellpadding="0" cellspacing="0">
<tr><td style="font-size:22px;font-weight:700;color:#173D44">child life</td></tr>
<tr><td style="padding-top:20px;font-size:26px;line-height:34px;font-weight:700">${escape(t.subject)}</td></tr>
<tr><td style="padding-top:8px;font-size:16px;color:#55707A">${escape(t.role)}</td></tr>
<tr><td style="padding-top:20px"><a href="${escape(link)}" style="display:block;text-align:center;background:#087F7B;color:#ffffff;text-decoration:none;font-weight:600;font-size:17px;border-radius:999px;padding:16px">${escape(t.cta)}</a></td></tr>
<tr><td style="padding-top:16px;text-align:center;font-size:13px;color:#55707A">${escape(t.orCode)}</td></tr>
<tr><td style="padding-top:8px;text-align:center"><span style="display:inline-block;background:#EEF6F5;border-radius:12px;padding:8px 16px;font-size:20px;font-weight:600;letter-spacing:2px">${escape(code)}</span></td></tr>
<tr><td style="padding-top:24px;border-top:1px solid #DCE8E7;font-size:13px;color:#55707A">${escape(t.ignore)}</td></tr>
<tr><td style="padding-top:12px;font-size:12px;color:#55707A">${escape(t.footer)} · <a href="${escape(links.unsubscribeUrl)}" style="color:#06716D">${escape(t.unsubscribe)}</a></td></tr>
</table></td></tr></table></body></html>`;
  const text = [
    t.subject,
    t.role,
    `${t.cta}: ${link}`,
    `${t.orCode}: ${code}`,
    '',
    t.ignore,
    `${t.unsubscribe}: ${links.unsubscribeUrl}`,
  ].join('\n');
  return { subject: t.subject, html, text };
}

/** Delivers one queued mail document; returns the resulting status. */
export async function deliverMail(
  doc: DocumentSnapshot,
  sender: MailSender | null,
  config: { webOrigin: string; now: Date },
): Promise<'sent' | 'waiting-provider' | 'failed'> {
  const mail = doc.data();
  if (!mail || mail.status === 'sent') return 'sent';
  const attempts = ((mail.attempts as number | undefined) ?? 0) + 1;
  if (!sender) {
    await doc.ref.update({ status: 'waiting-provider', attempts, updatedAt: config.now });
    return 'waiting-provider';
  }
  const unsubscribeUrl = `${config.webOrigin}/u/${mail.unsubscribeToken as string}`;
  try {
    if (mail.template !== 'invite') throw new Error(`Unknown template ${String(mail.template)}`);
    const rendered = renderInviteEmail(mail.locale as Locale, mail.data as InviteMailData, {
      webOrigin: config.webOrigin,
      unsubscribeUrl,
    });
    await sender.send({ to: mail.to as string, unsubscribeUrl, ...rendered });
    await doc.ref.update({ status: 'sent', attempts, sentAt: config.now, error: null });
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

/** "Huỷ nhận email": records the suppression; returns false for unknown tokens. */
export async function unsubscribe(db: Firestore, token: string, now: Date): Promise<boolean> {
  if (!/^[A-Za-z0-9_-]{32}$/.test(token)) return false;
  const ref = db.doc(`emailUnsubscribeTokens/${token}`);
  const doc = await ref.get();
  if (!doc.exists) return false;
  await db.doc(`emailSuppressions/${doc.get('emailHash') as string}`).set({ createdAt: now });
  return true;
}
