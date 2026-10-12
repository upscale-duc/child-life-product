import type { InvitePreview } from '@child-life/contracts';

/**
 * Small server-rendered pages on the landing host (plan §3.5): the invite landing `/i/{token}`
 * (D-059: the email's "Nhận lời mời" — open the app, or install it first, or type the code) and
 * the unsubscribe confirmation `/u/{token}` and the app's sign-in link `/auth/link/` opened in a
 * browser (D-064). No client Firestore access.
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
h2{font-size:17px;margin:24px 0 4px}.hint{font-size:14px}
.btn{display:block;text-align:center;background:#0B7F78;color:#fff;text-decoration:none;font-weight:600;font-size:17px;border-radius:16px;padding:15px 16px;margin:16px 0 4px}
.steps{list-style:none;padding:0;margin:8px 0 0;counter-reset:s}
.steps li{position:relative;padding:4px 0 12px 40px;counter-increment:s;color:#173D44;line-height:1.55}
.steps li:before{content:counter(s);position:absolute;left:0;top:2px;width:28px;height:28px;border-radius:50%;background:#EEF6F5;color:#0B7F78;font-weight:700;text-align:center;line-height:28px}
.stores a{display:inline-block;margin:8px 8px 0 0;padding:8px 14px;border-radius:12px;background:#173D44;color:#fff;text-decoration:none;font-size:14px;font-weight:600}
.copy{margin-left:8px;border:0;background:none;color:#0B7F78;font:inherit;font-weight:600;cursor:pointer}
.foot{font-size:14px;margin-top:20px}
</style></head><body><main><div class="brand">child life</div><div class="card">${body}</div></main></body></html>`;
}

const roleLabel = {
  vi: { coParent: 'Cùng nuôi', caregiver: 'Người chăm sóc', relative: 'Người thân' },
  en: { coParent: 'Co-parent', caregiver: 'Caregiver', relative: 'Family member' },
} as const;

export interface InvitePageLinks {
  /** The same invite on another app domain, so a tap opens the app (Universal / App Links). */
  openUrl: string;
  appStore: string | null;
  playStore: string | null;
}

const invitePageCopy = {
  vi: {
    title: (name: string, baby: string) => `${name} mời bạn cùng chăm ${baby}`,
    role: 'Vai trò',
    haveApp: 'Đã có app Child Life',
    open: 'Mở app và nhận lời mời',
    openHint: (baby: string) => `App mở ra và tự đưa bạn vào gia đình của ${baby}.`,
    noApp: 'Chưa có app',
    install: 'Cài app Child Life trên điện thoại.',
    back: 'Cài xong, quay lại trang này (hoặc bấm lại “Nhận lời mời” trong email) và bấm “Mở app và nhận lời mời”.',
    code: 'Hoặc mở app, chọn “Mã mời” và nhập mã:',
    copy: 'Sao chép',
    copied: 'Đã chép',
    stranger: 'Không quen người gửi? Bỏ qua trang này.',
  },
  en: {
    title: (name: string, baby: string) => `${name} invited you to care for ${baby}`,
    role: 'Role',
    haveApp: 'Have the Child Life app',
    open: 'Open the app and accept',
    openHint: (baby: string) => `The app opens and takes you into ${baby}'s family.`,
    noApp: "Don't have the app yet",
    install: 'Install the Child Life app on your phone.',
    back: 'Then come back to this page (or tap “Accept invite” in the email again) and tap “Open the app and accept”.',
    code: 'Or open the app, choose “Invite code” and enter:',
    copy: 'Copy',
    copied: 'Copied',
    stranger: "Don't know the sender? Just close this page.",
  },
} as const;

export function renderInvitePage(
  locale: PageLocale,
  preview: InvitePreview,
  code: string | null,
  links: InvitePageLinks,
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
  const t = invitePageCopy[locale];
  const spaced = `${code.slice(0, 3)} ${code.slice(3)}`;
  const name = escape(preview.inviterName);
  const baby = escape(preview.babyNickname);
  const stores = [
    links.appStore ? `<a href="${escape(links.appStore)}">App Store</a>` : '',
    links.playStore ? `<a href="${escape(links.playStore)}">Google Play</a>` : '',
  ].join('');
  return page(
    locale,
    t.title(preview.inviterName, preview.babyNickname),
    `<h1>${t.title(name, baby)}</h1><p>${t.role}: ${roleLabel[locale][preview.role]}</p>
<h2>${t.haveApp}</h2>
<a class="btn" href="${escape(links.openUrl)}">${t.open}</a><p class="hint">${t.openHint(baby)}</p>
<h2>${t.noApp}</h2>
<ol class="steps"><li>${t.install}${stores ? `<div class="stores">${stores}</div>` : ''}</li>
<li>${t.back}</li>
<li>${t.code}<p><span class="code">${spaced}</span><button class="copy" type="button" data-code="${code}" data-done="${t.copied}">${t.copy}</button></p></li></ol>
<p class="foot">${t.stranger}</p>
<script>document.querySelector('.copy').addEventListener('click',function(e){var b=e.currentTarget;navigator.clipboard&&navigator.clipboard.writeText(b.dataset.code).then(function(){b.textContent=b.dataset.done})})</script>`,
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

/** "Tải tệp về" from the export email when the file cannot be given (R-187). */
export function renderExportPage(
  locale: PageLocale,
  reason: 'invalid' | 'expired' | 'denied',
): string {
  const copy = {
    vi: {
      invalid: [
        'Liên kết không hợp lệ',
        'Liên kết tải này không đúng hoặc đã được thay bằng tệp mới.',
      ],
      expired: [
        'Liên kết đã hết hạn',
        'Tệp xuất chỉ giữ 24 giờ. Mở Child Life → Tôi → Tài khoản & đăng nhập để xuất lại.',
      ],
      denied: [
        'Bạn không còn quyền tải tệp này',
        'Quyền của bạn với hồ sơ đã thay đổi. Liên hệ chủ hồ sơ nếu cần.',
      ],
    },
    en: {
      invalid: [
        'This link is not valid',
        'This download link is wrong or was replaced by a newer export.',
      ],
      expired: [
        'This link has expired',
        'Exports are kept for 24 hours. Open Child Life → Me → Account & sign-in to export again.',
      ],
      denied: [
        'You can no longer download this file',
        'Your access to the profile changed. Ask the profile owner if you need it.',
      ],
    },
  }[locale][reason];
  return page(locale, copy[0]!, `<h1>${escape(copy[0]!)}</h1><p>${escape(copy[1]!)}</p>`);
}

/**
 * The app's email sign-in link (07a, D-064) opened in a browser: on the phone, the button opens
 * the app through the other domain; on a computer, the link has to be opened on the phone.
 */
export function renderSignInLinkPage(
  locale: PageLocale,
  link: { openUrl: string | null; expired: boolean },
): string {
  const t = {
    vi: {
      title: 'Mở link trong app Child Life',
      body: 'Link đăng nhập chỉ dùng được trong app Child Life, trên điện thoại bạn đã yêu cầu.',
      open: 'Mở Child Life',
      computer: 'Đang xem trên máy tính? Mở email này trên điện thoại đã cài app.',
      expiredTitle: 'Link đã hết hạn',
      expiredBody:
        'Link đăng nhập chỉ dùng được trong 15 phút. Mở app Child Life → Đăng nhập → Gửi link đăng nhập để nhận link mới.',
    },
    en: {
      title: 'Open the link in the Child Life app',
      body: 'Sign-in links only work in the Child Life app, on the phone you asked from.',
      open: 'Open Child Life',
      computer: 'On a computer? Open this email on the phone with the app.',
      expiredTitle: 'This link has expired',
      expiredBody:
        'Sign-in links work for 15 minutes. Open Child Life → Sign in → Send sign-in link to get a new one.',
    },
  }[locale];
  if (link.expired || !link.openUrl) {
    return page(
      locale,
      t.expiredTitle,
      `<h1>${escape(t.expiredTitle)}</h1><p>${escape(t.expiredBody)}</p>`,
    );
  }
  return page(
    locale,
    t.title,
    `<h1>${escape(t.title)}</h1><p>${escape(t.body)}</p>
<a class="btn" href="${escape(link.openUrl)}">${escape(t.open)}</a>
<p class="foot">${escape(t.computer)}</p>`,
  );
}
