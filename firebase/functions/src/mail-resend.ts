import type { MailSender, OutgoingMail } from './mail.js';

/**
 * Resend (D-054) through its HTTP API, no SDK. The sending domain (childlife.app, DNS at GoDaddy)
 * is verified in Resend with its DKIM / SPF records; replies go to the GoDaddy mailbox. Errors
 * carry the HTTP status and Resend's error name only, never the recipient or the content.
 */
export class ResendError extends Error {
  constructor(
    readonly status: number,
    readonly errorName: string,
  ) {
    super(`resend ${status} ${errorName}`);
  }

  /** Worth retrying later (rate limit, outage); the rest needs a person. */
  get transient() {
    return this.status === 429 || this.status >= 500;
  }
}

export function resendSender(config: {
  apiKey: string;
  from: string;
  replyTo?: string;
  fetchImpl?: typeof fetch;
}): MailSender {
  const send = config.fetchImpl ?? fetch;
  return {
    async send(mail: OutgoingMail) {
      const headers: Record<string, string> = {};
      if (mail.unsubscribeUrl) {
        headers['List-Unsubscribe'] = `<${mail.unsubscribeUrl}>`;
        headers['List-Unsubscribe-Post'] = 'List-Unsubscribe=One-Click';
      }
      const res = await send('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${config.apiKey}`,
          'Content-Type': 'application/json',
          ...(mail.idempotencyKey ? { 'Idempotency-Key': mail.idempotencyKey } : {}),
        },
        body: JSON.stringify({
          from: config.from,
          to: [mail.to],
          subject: mail.subject,
          html: mail.html,
          text: mail.text,
          ...(config.replyTo ? { reply_to: config.replyTo } : {}),
          ...(Object.keys(headers).length ? { headers } : {}),
        }),
        signal: AbortSignal.timeout(20_000),
      });
      if (!res.ok) {
        let name = 'error';
        try {
          const body = (await res.json()) as { name?: unknown };
          if (typeof body.name === 'string') name = body.name.slice(0, 60);
        } catch {
          // Not JSON: the status says enough.
        }
        throw new ResendError(res.status, name);
      }
    },
  };
}
