import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { describe, expect, it } from 'vitest';
import { ResendError, resendSender } from '../src/mail-resend.js';
import {
  accountTemplates,
  authTemplates,
  renderAccountEmail,
  renderAuthEmail,
  inviteLinkUrl,
  renderInviteEmail,
  type AccountMailData,
  type Locale,
  type RenderedMail,
} from '../src/mail-templates.js';

// Every Child Life email (D-054), vi and en, with sample data only.
const sample: AccountMailData = {
  amountGb: 20,
  usedGb: '14.6',
  quotaGb: '15',
  ticket: 'CL-1042',
  category: 'Dung lượng',
  fromName: 'Mai',
  requestId: 'sr_3f2a',
  body: 'Chào bạn,\nChúng tôi đã thêm dung lượng cho gia đình.',
  role: 'Hỗ trợ · Vận hành',
  url: 'https://admin.dev.childlife.app',
  toEmail: 'ba***@gmail.com',
};
const invite = {
  inviterName: 'Mai',
  babyNickname: 'Teddy',
  role: 'caregiver' as const,
  code: '482913',
  token: 'tok_abc',
  expiresAt: '2026-10-15T03:00:00Z',
};

function all(locale: Locale): [string, RenderedMail][] {
  return [
    [
      'invite',
      renderInviteEmail(locale, invite, {
        webOrigin: 'https://childlife.app',
        unsubscribeUrl: 'https://childlife.app/u/xyz',
      }),
    ],
    ...accountTemplates.map(
      (t) =>
        [
          t,
          renderAccountEmail(t, locale, sample, { adminOrigin: 'https://admin.childlife.app' }),
        ] as [string, RenderedMail],
    ),
    ...authTemplates.map(
      (t) =>
        [
          t,
          renderAuthEmail(t, locale, {
            link: 'https://child-life-dev.firebaseapp.com/__/auth/action?mode=x&oobCode=abc',
            email: 'mai@example.com',
          }),
        ] as [string, RenderedMail],
    ),
  ];
}

describe('templates', () => {
  it('every template renders in vi and en with a subject, HTML and plain text', () => {
    for (const locale of ['vi', 'en'] as const) {
      const mails = all(locale);
      expect(mails).toHaveLength(1 + accountTemplates.length + authTemplates.length);
      for (const [, m] of mails) {
        expect(m.subject.length).toBeGreaterThan(5);
        expect(m.subject).not.toContain('undefined');
        expect(m.html).toContain(`<html lang="${locale}">`);
        expect(m.html).toContain('child life');
        expect(m.text).not.toContain('<');
        expect(m.text).not.toContain('undefined');
      }
    }
  });

  it('the invite keeps 14e: subject, button link, code and unsubscribe', () => {
    const m = renderInviteEmail('vi', invite, {
      webOrigin: 'https://childlife.app',
      unsubscribeUrl: 'https://childlife.app/u/xyz',
    });
    expect(m.subject).toBe('Mai mời bạn cùng chăm Teddy');
    expect(m.html).toContain('href="https://childlife.app/i/tok_abc"');
    expect(m.html).toContain('482 913');
    expect(m.html).toContain('Hoặc nhập mã trong app · hết hạn 15 thg 10');
    expect(m.html).toContain('Huỷ nhận email');
    expect(m.text).toContain('Nhận lời mời: https://childlife.app/i/tok_abc');
  });

  it('with a OneLink, "Nhận lời mời" opens the app and joins, even after installing', () => {
    const url = new URL(
      inviteLinkUrl('tok_abc', 'https://dev.childlife.app', 'https://childlife.onelink.me/AbCd'),
    );
    expect(url.origin + url.pathname).toBe('https://childlife.onelink.me/AbCd');
    expect(Object.fromEntries(url.searchParams)).toEqual({
      deep_link_value: 'invite',
      deep_link_sub1: 'tok_abc',
      af_web_dp: 'https://dev.childlife.app/i/tok_abc',
      pid: 'invite_email',
    });
    const m = renderInviteEmail('en', invite, {
      webOrigin: 'https://dev.childlife.app',
      unsubscribeUrl: 'https://dev.childlife.app/u/xyz',
      oneLink: 'https://childlife.onelink.me/AbCd',
    });
    expect(m.text).toContain('https://childlife.onelink.me/AbCd?deep_link_value=invite');
  });

  it('service mail has no unsubscribe; staff mail points at the portal', () => {
    const staff = renderAccountEmail('staffInvite', 'vi', sample);
    expect(staff.subject).toBe('Mai mời bạn vào Child Life · Vận hành');
    expect(staff.html).toContain('href="https://admin.dev.childlife.app"');
    expect(staff.html).not.toContain('Huỷ nhận email');
    const transfer = renderAccountEmail('ownershipStaffRequest', 'en', sample);
    expect(transfer.text).toContain('New owner: ba***@gmail.com');
    expect(transfer.text).toContain('Request: CL-1042');
  });

  it('what people typed is escaped', () => {
    const m = renderAccountEmail('supportReply', 'vi', {
      ticket: 'CL-1',
      body: '<script>alert(1)</script>\nDòng 2',
    });
    expect(m.html).not.toContain('<script>');
    expect(m.html).toContain('&lt;script&gt;');
    expect(m.html).toContain('<br>Dòng 2');
    expect(m.text).toContain('> Dòng 2');
  });

  it('sign-in mail carries the link and the address it was sent to', () => {
    const m = renderAuthEmail('resetPassword', 'vi', {
      link: 'https://x.test/a?b=1&c=2',
      email: 'mai@example.com',
    });
    expect(m.subject).toBe('Đặt lại mật khẩu Child Life');
    expect(m.html).toContain('href="https://x.test/a?b=1&amp;c=2"');
    expect(m.html).toContain('mai@example.com');
  });

  // MAIL_PREVIEW_DIR=… pnpm vitest run test/mail-templates.test.ts writes a gallery for review.
  it.runIf(process.env.MAIL_PREVIEW_DIR)('writes the preview gallery', () => {
    const dir = process.env.MAIL_PREVIEW_DIR!;
    mkdirSync(dir, { recursive: true });
    const cards = (['vi', 'en'] as const)
      .flatMap((locale) =>
        all(locale).map(([name, m]) => {
          const file = `${name}.${locale}.html`;
          writeFileSync(join(dir, file), m.html);
          return `<section><h2>${name} · ${locale}</h2><p><b>${m.subject.replace(/</g, '&lt;')}</b></p><iframe src="${file}" loading="lazy"></iframe></section>`;
        }),
      )
      .join('\n');
    writeFileSync(
      join(dir, 'index.html'),
      `<!doctype html><meta charset="utf-8"><title>Child Life emails</title><style>body{font-family:system-ui;background:#e9efee;margin:0;padding:24px}main{display:grid;grid-template-columns:repeat(auto-fill,minmax(380px,1fr));gap:24px}section{background:#fff;border-radius:16px;padding:12px}h2{font-size:13px;color:#55707a;margin:4px 0}p{margin:4px 0 8px;font-size:14px}iframe{width:100%;height:720px;border:0;border-radius:12px}</style><h1>Child Life · email templates</h1><main>${cards}</main>`,
    );
  });
});

describe('Resend', () => {
  it('posts one mail with reply-to, idempotency and unsubscribe headers', async () => {
    const calls: { url: string; init: RequestInit }[] = [];
    const sender = resendSender({
      apiKey: 're_test',
      from: 'Child Life <hello@childlife.app>',
      replyTo: 'hello@childlife.app',
      fetchImpl: (async (url: string, init: RequestInit) => {
        calls.push({ url, init });
        return new Response(JSON.stringify({ id: 'em_1' }), { status: 200 });
      }) as typeof fetch,
    });
    await sender.send({
      to: 'a@example.com',
      subject: 'S',
      html: '<p>h</p>',
      text: 't',
      unsubscribeUrl: 'https://childlife.app/u/xyz',
      idempotencyKey: 'mail-1',
    });
    expect(calls[0]!.url).toBe('https://api.resend.com/emails');
    const headers = calls[0]!.init.headers as Record<string, string>;
    expect(headers.Authorization).toBe('Bearer re_test');
    expect(headers['Idempotency-Key']).toBe('mail-1');
    const body = JSON.parse(calls[0]!.init.body as string);
    expect(body).toMatchObject({
      from: 'Child Life <hello@childlife.app>',
      to: ['a@example.com'],
      reply_to: 'hello@childlife.app',
      headers: { 'List-Unsubscribe': '<https://childlife.app/u/xyz>' },
    });
  });

  it('errors carry the status and name only', async () => {
    const sender = resendSender({
      apiKey: 're_test',
      from: 'x',
      fetchImpl: (async () =>
        new Response(JSON.stringify({ name: 'rate_limit_exceeded', message: 'to a@x' }), {
          status: 429,
        })) as unknown as typeof fetch,
    });
    const error = await sender
      .send({ to: 'a@example.com', subject: 's', html: 'h', text: 't' })
      .catch((e: unknown) => e);
    expect(error).toBeInstanceOf(ResendError);
    expect((error as ResendError).transient).toBe(true);
    expect(String(error)).not.toContain('a@');
  });
});
