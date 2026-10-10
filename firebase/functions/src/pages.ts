import type { InvitePreview } from '@child-life/contracts';

/**
 * Small server-rendered pages on the landing host (plan §3.5): the invite landing `/i/{token}`
 * (QR / email link opened outside the app — shows the code to type in the app until universal
 * links exist) and the unsubscribe confirmation `/u/{token}`. No client Firestore access.
 */

export type PageLocale = 'vi' | 'en';

export function localeFromHeader(acceptLanguage: string | undefined): PageLocale {
  const first = (acceptLanguage ?? '').split(',')[0]?.trim().toLowerCase() ?? '';
  return first.startsWith('en') ? 'en' : 'vi';
}

const escape = (value: string) =>
  value.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

function page(locale: PageLocale, title: string, body: string): string {
  return `<!doctype html><html lang="${locale}"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex,nofollow">
<title>${escape(title)} · Child Life</title>
<style>
body{margin:0;background:#F6FCFB;color:#173D44;font-family:'Be Vietnam Pro',system-ui,sans-serif}
main{max-width:440px;margin:0 auto;padding:40px 20px}
.brand{font-weight:700;font-size:22px}.card{background:#fff;border-radius:24px;padding:24px;margin-top:24px;box-shadow:0 8px 24px #173d4414}
h1{font-size:26px;line-height:1.3;margin:0 0 8px}p{color:#55707A;line-height:1.55;margin:8px 0}
.code{display:inline-block;background:#EEF6F5;border-radius:14px;padding:10px 18px;font-size:28px;font-weight:600;letter-spacing:4px;color:#173D44}
ol{padding-left:20px;color:#173D44;line-height:1.7}
</style></head><body><main><div class="brand">child life</div><div class="card">${body}</div></main></body></html>`;
}

const roleLabel = {
  vi: { coParent: 'Cùng nuôi', caregiver: 'Người chăm sóc', relative: 'Người thân' },
  en: { coParent: 'Co-parent', caregiver: 'Caregiver', relative: 'Family member' },
} as const;

export function renderInvitePage(
  locale: PageLocale,
  preview: InvitePreview,
  code: string | null,
): string {
  if (preview.status !== 'valid' || !code) {
    return locale === 'vi'
      ? page(
          locale,
          'Lời mời đã hết hạn',
          '<h1>Lời mời đã hết hạn</h1><p>Nhờ người mời gửi link mới nhé.</p>',
        )
      : page(
          locale,
          'This invite has expired',
          '<h1>This invite has expired</h1><p>Ask the person who invited you to send a new link.</p>',
        );
  }
  const spaced = `${code.slice(0, 3)} ${code.slice(3)}`;
  const name = escape(preview.inviterName);
  const baby = escape(preview.babyNickname);
  const role = roleLabel[locale][preview.role];
  return locale === 'vi'
    ? page(
        locale,
        `${preview.inviterName} mời bạn`,
        `<h1>${name} mời bạn cùng chăm ${baby}</h1><p>Vai trò: ${role}</p>
<ol><li>Cài app Child Life trên điện thoại.</li><li>Mở app, chọn “Mã mời”.</li><li>Nhập mã:</li></ol>
<p><span class="code">${spaced}</span></p><p>Không quen người gửi? Bỏ qua trang này.</p>`,
      )
    : page(
        locale,
        `${preview.inviterName} invited you`,
        `<h1>${name} invited you to care for ${baby}</h1><p>Role: ${role}</p>
<ol><li>Install the Child Life app.</li><li>Open it and choose “Invite code”.</li><li>Enter the code:</li></ol>
<p><span class="code">${spaced}</span></p><p>Don't know the sender? Just close this page.</p>`,
      );
}

export function renderUnsubscribePage(locale: PageLocale, ok: boolean): string {
  if (locale === 'vi') {
    return ok
      ? page(
          locale,
          'Đã huỷ nhận email',
          '<h1>Đã huỷ nhận email</h1><p>Child Life sẽ không gửi lời mời tới địa chỉ này nữa.</p>',
        )
      : page(
          locale,
          'Liên kết không hợp lệ',
          '<h1>Liên kết không hợp lệ</h1><p>Liên kết huỷ nhận email này không còn dùng được.</p>',
        );
  }
  return ok
    ? page(
        locale,
        'Unsubscribed',
        "<h1>You're unsubscribed</h1><p>Child Life won't send invites to this address again.</p>",
      )
    : page(
        locale,
        'Invalid link',
        '<h1>This link is not valid</h1><p>This unsubscribe link can no longer be used.</p>',
      );
}
