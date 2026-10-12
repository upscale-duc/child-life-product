/**
 * Every Child Life email (D-054): one branded layout and the copy of each template, in Vietnamese
 * (the source) and English. Transactional only, never marketing. Child data stays out except what
 * the sender typed for the recipient (the baby's nickname in an invite); no photos, dates of birth
 * or care details. Rendered to HTML (tables and inline styles for mail clients) plus plain text.
 */

export type Locale = 'vi' | 'en';

export interface RenderedMail {
  subject: string;
  html: string;
  text: string;
}

const brand = {
  cloud: '#F6FCFB',
  surface: '#FFFFFF',
  soft: '#EEF6F5',
  ink: '#173D44',
  muted: '#55707A',
  line: '#DCE8E7',
  mint: '#087F7B',
  mintText: '#06716D',
  sun: '#FFCF5C',
  warnBg: '#FFF4D6',
};

export const escapeHtml = (value: string) =>
  value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');

/** Blocks a template is made of, in order. */
export type Block =
  | { kind: 'text'; text: string }
  | { kind: 'facts'; rows: [string, string][] }
  | { kind: 'button'; label: string; url: string }
  | { kind: 'code'; caption: string; code: string }
  | { kind: 'quote'; text: string }
  | { kind: 'steps'; text: string }
  | { kind: 'note'; text: string }
  | { kind: 'warning'; text: string };

export interface MailContent {
  locale: Locale;
  subject: string;
  /** Inbox preview line (hidden in the body). */
  preheader: string;
  title: string;
  blocks: Block[];
  /** Why this person got the email (footer). */
  reason: string;
  unsubscribeUrl?: string;
}

const footerCopy = {
  vi: {
    tagline: 'Child Life · Riêng tư cho gia đình',
    help: 'Cần giúp? Trả lời email này, chúng tôi đọc từng thư.',
    unsubscribe: 'Huỷ nhận email',
    plainLink: 'Nút không bấm được? Mở liên kết này:',
  },
  en: {
    tagline: 'Child Life · Private for families',
    help: 'Need help? Reply to this email, we read every message.',
    unsubscribe: 'Unsubscribe',
    plainLink: 'Button not working? Open this link:',
  },
};

const p = (text: string) => escapeHtml(text).replace(/\n/g, '<br>');

function blockHtml(b: Block, locale: Locale): string {
  switch (b.kind) {
    case 'text':
      return `<tr><td style="padding-top:12px;font-size:16px;line-height:24px;color:${brand.muted}">${p(b.text)}</td></tr>`;
    case 'facts':
      return `<tr><td style="padding-top:16px"><table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:${brand.soft};border-radius:16px">${b.rows
        .map(
          ([k, v], i) =>
            `<tr><td style="padding:${i === 0 ? 14 : 6}px 16px ${i === b.rows.length - 1 ? 14 : 6}px;font-size:14px;line-height:20px;color:${brand.muted};width:1%;white-space:nowrap">${p(k)}</td><td style="padding:${i === 0 ? 14 : 6}px 16px ${i === b.rows.length - 1 ? 14 : 6}px;font-size:14px;line-height:20px;color:${brand.ink};font-weight:600">${p(v)}</td></tr>`,
        )
        .join('')}</table></td></tr>`;
    case 'button':
      return `<tr><td style="padding-top:24px"><table role="presentation" width="100%" cellpadding="0" cellspacing="0"><tr><td align="center" bgcolor="${brand.mint}" style="border-radius:999px"><a href="${escapeHtml(b.url)}" target="_blank" style="display:block;padding:16px 24px;font-size:17px;line-height:22px;font-weight:600;color:#FFFFFF;text-decoration:none;border-radius:999px">${p(b.label)}</a></td></tr></table></td></tr>
<tr><td style="padding-top:12px;font-size:12px;line-height:18px;color:${brand.muted};word-break:break-all">${p(footerCopy[locale].plainLink)} <a href="${escapeHtml(b.url)}" style="color:${brand.mintText}">${escapeHtml(b.url)}</a></td></tr>`;
    case 'code':
      return `<tr><td style="padding-top:20px;text-align:center;font-size:13px;line-height:18px;color:${brand.muted}">${p(b.caption)}</td></tr>
<tr><td style="padding-top:8px;text-align:center"><span style="display:inline-block;background:${brand.soft};border-radius:12px;padding:10px 20px;font-size:24px;line-height:30px;font-weight:700;letter-spacing:4px;color:${brand.ink}">${escapeHtml(b.code)}</span></td></tr>`;
    case 'quote':
      return `<tr><td style="padding-top:16px"><div style="border-left:3px solid ${brand.mint};padding:4px 0 4px 14px;font-size:16px;line-height:24px;color:${brand.ink}">${p(b.text)}</div></td></tr>`;
    case 'steps':
      return `<tr><td style="padding-top:16px"><div style="background:${brand.soft};border-radius:14px;padding:12px 16px;font-size:15px;line-height:22px;font-weight:600;color:${brand.ink}">${p(b.text)}</div></td></tr>`;
    case 'note':
      return `<tr><td style="padding-top:16px;font-size:13px;line-height:20px;color:${brand.muted}">${p(b.text)}</td></tr>`;
    case 'warning':
      return `<tr><td style="padding-top:16px"><div style="background:${brand.warnBg};border-radius:14px;padding:12px 16px;font-size:14px;line-height:20px;color:${brand.ink}">${p(b.text)}</div></td></tr>`;
  }
}

function blockText(b: Block): string {
  switch (b.kind) {
    case 'facts':
      return b.rows.map(([k, v]) => `${k}: ${v}`).join('\n');
    case 'button':
      return `${b.label}: ${b.url}`;
    case 'code':
      return `${b.caption}: ${b.code}`;
    case 'quote':
      return b.text
        .split('\n')
        .map((l) => `> ${l}`)
        .join('\n');
    default:
      return b.text;
  }
}

/** The shared layout: logotype, title, blocks, divider, footer (+ unsubscribe when given). */
export function layout(c: MailContent): RenderedMail {
  const f = footerCopy[c.locale];
  const html = `<!doctype html>
<html lang="${c.locale}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="color-scheme" content="light"><meta name="supported-color-schemes" content="light"><title>${escapeHtml(c.subject)}</title></head>
<body style="margin:0;padding:0;background:${brand.cloud};font-family:'Be Vietnam Pro',-apple-system,'Segoe UI',Roboto,Arial,sans-serif;color:${brand.ink};-webkit-text-size-adjust:100%">
<div style="display:none;max-height:0;overflow:hidden;opacity:0;color:transparent">${escapeHtml(c.preheader)}</div>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:${brand.cloud}"><tr><td align="center" style="padding:28px 12px">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:520px">
<tr><td style="padding:0 8px 16px"><table role="presentation" cellpadding="0" cellspacing="0"><tr><td style="width:28px;height:28px;background:${brand.mint};border-radius:9px;text-align:center;vertical-align:middle"><span style="display:inline-block;width:10px;height:10px;background:${brand.sun};border-radius:50%"></span></td><td style="padding-left:10px;font-size:20px;font-weight:700;letter-spacing:-0.2px;color:${brand.ink}">child life</td></tr></table></td></tr>
<tr><td style="background:${brand.surface};border-radius:24px;padding:28px 28px 24px">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0">
<tr><td style="font-size:24px;line-height:32px;font-weight:700;color:${brand.ink}">${p(c.title)}</td></tr>
${c.blocks.map((b) => blockHtml(b, c.locale)).join('\n')}
<tr><td style="padding-top:24px"><div style="border-top:1px solid ${brand.line}"></div></td></tr>
<tr><td style="padding-top:16px;font-size:13px;line-height:20px;color:${brand.muted}">${p(f.help)}</td></tr>
</table></td></tr>
<tr><td style="padding:16px 8px 0;font-size:12px;line-height:18px;color:${brand.muted}">${p(c.reason)}</td></tr>
<tr><td style="padding:6px 8px 0;font-size:12px;line-height:18px;color:${brand.muted}">${p(f.tagline)}${
    c.unsubscribeUrl
      ? ` · <a href="${escapeHtml(c.unsubscribeUrl)}" style="color:${brand.mintText}">${p(f.unsubscribe)}</a>`
      : ''
  }</td></tr>
</table></td></tr></table></body></html>`;
  const text = [
    c.title,
    '',
    ...c.blocks.map((b) => blockText(b)).flatMap((t) => [t, '']),
    f.help,
    '',
    c.reason,
    c.unsubscribeUrl ? `${f.tagline} · ${f.unsubscribe}: ${c.unsubscribeUrl}` : f.tagline,
  ].join('\n');
  return { subject: c.subject, html, text };
}

// ---------- Invite (Figma 14e) ----------

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

const roleHint: Record<Locale, Record<InviteMailData['role'], string>> = {
  vi: {
    coParent: 'Cùng ghi chép, xem mọi thứ và quản lý hồ sơ như cha mẹ.',
    caregiver: 'Ghi cữ bú, giấc ngủ, thay tã và xem lịch chăm bé.',
    relative: 'Xem ảnh, câu chuyện và những gì gia đình chia sẻ với bạn.',
  },
  en: {
    coParent: 'Log, see everything and manage the profile like a parent.',
    caregiver: 'Log feeds, sleep and changes and see the care schedule.',
    relative: 'See the photos, stories and whatever the family shares with you.',
  },
};

/** "15 thg 10" / "15 Oct" in Vietnam time (the expiry line of 14e). */
export function shortDate(iso: string, locale: Locale): string {
  const date = new Date(iso);
  const part = (o: Intl.DateTimeFormatOptions) =>
    new Intl.DateTimeFormat(locale === 'vi' ? 'vi-VN' : 'en-GB', {
      ...o,
      timeZone: 'Asia/Ho_Chi_Minh',
    }).format(date);
  return locale === 'vi'
    ? `${part({ day: 'numeric' })} thg ${part({ month: 'numeric' })}`
    : part({ day: 'numeric', month: 'short' });
}

export function renderInviteEmail(
  locale: Locale,
  data: InviteMailData,
  links: { webOrigin: string; unsubscribeUrl: string },
): RenderedMail {
  const vi = locale === 'vi';
  const subject = vi
    ? `${data.inviterName} mời bạn cùng chăm ${data.babyNickname}`
    : `${data.inviterName} invited you to care for ${data.babyNickname}`;
  const link = data.token ? `${links.webOrigin}/i/${data.token}` : links.webOrigin;
  const code = `${data.code.slice(0, 3)} ${data.code.slice(3)}`;
  return layout({
    locale,
    subject,
    preheader: vi
      ? `Vai trò: ${roleLabel.vi[data.role]} · mã ${code}`
      : `Role: ${roleLabel.en[data.role]} · code ${code}`,
    title: subject,
    blocks: [
      {
        kind: 'facts',
        rows: [[vi ? 'Vai trò' : 'Role', roleLabel[locale][data.role]]],
      },
      { kind: 'text', text: roleHint[locale][data.role] },
      { kind: 'button', label: vi ? 'Nhận lời mời' : 'Accept invite', url: link },
      {
        kind: 'code',
        caption: vi
          ? `Hoặc nhập mã trong app · hết hạn ${shortDate(data.expiresAt, 'vi')}`
          : `Or enter the code in the app · expires ${shortDate(data.expiresAt, 'en')}`,
        code,
      },
      {
        kind: 'note',
        text: vi
          ? 'Không quen người gửi? Bỏ qua email này, sẽ không có gì thay đổi.'
          : "Don't know the sender? Ignore this email and nothing changes.",
      },
    ],
    reason: vi
      ? 'Bạn nhận email này vì một thành viên gia đình đã mời địa chỉ này vào Child Life.'
      : 'You got this email because a family member invited this address to Child Life.',
    unsubscribeUrl: links.unsubscribeUrl,
  });
}

// ---------- Account and service mail (S11, S15, portal v1.0) ----------

/** Service mail about the account (no unsubscribe needed, never marketing). */
export const accountTemplates = [
  'storageRequestAck',
  'storageRequestStaff',
  'supportAck',
  'supportStaff',
  'babyDeleted',
  'accountDeleted',
  'ownershipOffer',
  'exportReady',
  'supportReply',
  'storageGranted',
  'storageDeclined',
  'staffInvite',
  'ownershipStaffRequest',
] as const;
export type AccountTemplate = (typeof accountTemplates)[number];

/** Only generic facts: no baby names, photos or captions (R-116 spirit); staff read the rest in the portal (P-124). */
export interface AccountMailData {
  amountGb?: number;
  usedGb?: string;
  quotaGb?: string;
  ticket?: string;
  category?: string;
  fromName?: string;
  requestId?: string;
  /** Staff-written reply or message (S15), sent as typed. */
  body?: string;
  /** Staff invitation (P-135): role names and the portal address. */
  role?: string;
  url?: string;
  /** Staff-opened ownership transfer (P-136): the masked email of the proposed owner. */
  toEmail?: string;
  /** "Tệp xuất dữ liệu đã sẵn sàng": the one-click download and the file size. */
  jobId?: string;
  token?: string | null;
  downloadUrl?: string;
  size?: string;
}

const accountPath = {
  vi: 'Child Life → Tôi → Tài khoản & đăng nhập',
  en: 'Child Life → Me → Account & sign-in',
};

export function renderAccountEmail(
  template: AccountTemplate,
  locale: Locale,
  d: AccountMailData,
  links: { adminOrigin: string } = { adminOrigin: 'https://admin.childlife.app' },
): RenderedMail {
  const vi = locale === 'vi';
  const staffReason = vi
    ? 'Bạn nhận email này vì là nhân sự Child Life.'
    : 'You got this email as a member of the Child Life team.';
  const userReason = vi
    ? 'Bạn nhận email này về tài khoản Child Life của mình.'
    : 'You got this email about your Child Life account.';
  const portal = {
    kind: 'button' as const,
    label: vi ? 'Mở cổng Vận hành' : 'Open the operations portal',
    url: links.adminOrigin,
  };
  const notYou: Block = {
    kind: 'note',
    text: vi
      ? 'Nếu không phải bạn làm việc này, hãy trả lời email này ngay để chúng tôi hỗ trợ.'
      : "If this wasn't you, reply to this email right away and we'll help.",
  };
  const c = (
    subject: string,
    preheader: string,
    blocks: Block[],
    reason = userReason,
    title = subject,
  ) => layout({ locale, subject, preheader, title, blocks, reason });
  const storageRows: [string, string][] = vi
    ? [
        ['Xin thêm', `+${d.amountGb} GB`],
        ['Đang dùng', `${d.usedGb} GB / ${d.quotaGb} GB`],
      ]
    : [
        ['Requested', `+${d.amountGb} GB`],
        ['In use', `${d.usedGb} GB of ${d.quotaGb} GB`],
      ];
  const storageFacts: Block = { kind: 'facts', rows: storageRows };
  switch (template) {
    case 'storageRequestAck':
      return vi
        ? c('Đã nhận yêu cầu thêm dung lượng', `Xin thêm +${d.amountGb} GB`, [
            storageFacts,
            {
              kind: 'text',
              text: 'Quản trị Child Life sẽ trả lời qua email, thường trong 1–2 ngày làm việc. Trong lúc chờ, ảnh và video mới sẽ đợi và tự tải lên khi có thêm chỗ.',
            },
          ])
        : c('We received your storage request', `+${d.amountGb} GB requested`, [
            storageFacts,
            {
              kind: 'text',
              text: 'The Child Life team will reply by email, usually within 1–2 business days. Meanwhile new photos and videos wait and upload once there is room.',
            },
          ]);
    case 'storageRequestStaff':
      return c(
        vi
          ? `Yêu cầu dung lượng mới · +${d.amountGb} GB`
          : `New storage request · +${d.amountGb} GB`,
        vi ? `Mã ${d.requestId}` : `Request ${d.requestId}`,
        [
          {
            kind: 'facts',
            rows: [[vi ? 'Mã yêu cầu' : 'Request', d.requestId ?? '—'], ...storageRows],
          },
          portal,
        ],
        staffReason,
      );
    case 'supportAck':
      return vi
        ? c(`Đã nhận yêu cầu hỗ trợ ${d.ticket}`, 'Chúng tôi sẽ trả lời qua email này', [
            { kind: 'facts', rows: [['Mã yêu cầu', d.ticket ?? '—']] },
            {
              kind: 'text',
              text: 'Cảm ơn bạn đã liên hệ. Chúng tôi sẽ trả lời qua email này, thường trong 1 ngày làm việc. Bạn có thể trả lời email này để bổ sung thông tin.',
            },
          ])
        : c(`We received your request ${d.ticket}`, 'We will reply to this email', [
            { kind: 'facts', rows: [['Request', d.ticket ?? '—']] },
            {
              kind: 'text',
              text: 'Thanks for getting in touch. We will reply to this email, usually within 1 business day. Reply to it to add anything.',
            },
          ]);
    case 'supportStaff':
      return c(
        vi ? `Yêu cầu hỗ trợ mới ${d.ticket}` : `New support request ${d.ticket}`,
        vi ? `Chủ đề: ${d.category}` : `Topic: ${d.category}`,
        [
          {
            kind: 'facts',
            rows: vi
              ? [
                  ['Mã', d.ticket ?? '—'],
                  ['Chủ đề', d.category ?? '—'],
                ]
              : [
                  ['Ticket', d.ticket ?? '—'],
                  ['Topic', d.category ?? '—'],
                ],
          },
          {
            kind: 'text',
            text: vi
              ? 'Nội dung chỉ xem trong cổng Vận hành.'
              : 'The message is in the operations portal only.',
          },
          portal,
        ],
        staffReason,
      );
    case 'babyDeleted':
      return vi
        ? c('Đã xoá hồ sơ bé', 'Mọi ghi chép và kỷ niệm của hồ sơ đã được xoá', [
            {
              kind: 'text',
              text: 'Mọi ghi chép, ảnh, video và câu chuyện của hồ sơ đã được xoá với cả gia đình, và các liên kết chia sẻ không còn mở được.',
            },
            { kind: 'text', text: 'Dung lượng đã được trả lại cho gia đình bạn.' },
            notYou,
          ])
        : c('The baby profile was deleted', 'Its logs and memories were deleted', [
            {
              kind: 'text',
              text: 'All of its care logs, photos, videos and stories were deleted for the whole family, and shared links no longer open.',
            },
            { kind: 'text', text: 'The storage is back in your family’s space.' },
            notYou,
          ]);
    case 'accountDeleted':
      return vi
        ? c('Tài khoản Child Life đã được xoá', 'Tài khoản và thông tin cá nhân đã được xoá', [
            { kind: 'text', text: 'Tài khoản và thông tin cá nhân của bạn đã được xoá.' },
            {
              kind: 'text',
              text: 'Ghi chép và kỷ niệm bạn đã chia sẻ vẫn ở lại với gia đình, ghi là “Người dùng đã xoá”.',
            },
            {
              kind: 'note',
              text: 'Cảm ơn bạn đã dùng Child Life. Bạn luôn có thể quay lại với một tài khoản mới.',
            },
          ])
        : c('Your Child Life account was deleted', 'Your account and personal details are gone', [
            { kind: 'text', text: 'Your account and personal details were deleted.' },
            {
              kind: 'text',
              text: 'Logs and memories you shared stay with the family, shown as “Deleted user”.',
            },
            {
              kind: 'note',
              text: 'Thank you for using Child Life. You are always welcome back with a new account.',
            },
          ]);
    case 'ownershipOffer':
      return vi
        ? c(`${d.fromName} muốn chuyển quyền chủ hồ sơ cho bạn`, 'Mở app để nhận hoặc từ chối', [
            {
              kind: 'text',
              text: 'Chủ hồ sơ quản lý gia đình, dung lượng và có thể xoá hồ sơ. Bạn mở app để nhận hoặc từ chối:',
            },
            { kind: 'steps', text: accountPath.vi },
          ])
        : c(
            `${d.fromName} wants to make you the profile owner`,
            'Open the app to accept or decline',
            [
              {
                kind: 'text',
                text: 'The owner manages the family and storage and can delete the profile. Open the app to accept or decline:',
              },
              { kind: 'steps', text: accountPath.en },
            ],
          );
    case 'exportReady': {
      const link = d.downloadUrl;
      const size: Block[] = d.size
        ? [{ kind: 'facts', rows: [[vi ? 'Dung lượng' : 'Size', d.size]] }]
        : [];
      return vi
        ? c('Tệp xuất dữ liệu đã sẵn sàng', 'Tải về trong 24 giờ', [
            {
              kind: 'text',
              text: link
                ? 'Tệp xuất dữ liệu bạn yêu cầu đã sẵn sàng. Bấm nút dưới đây để tải về (tệp .zip).'
                : 'Tệp xuất dữ liệu bạn yêu cầu đã sẵn sàng. Mở app để tải về:',
            },
            ...size,
            ...(link
              ? [
                  { kind: 'button' as const, label: 'Tải tệp về', url: link },
                  { kind: 'note' as const, text: `Hoặc mở app: ${accountPath.vi}.` },
                ]
              : [{ kind: 'steps' as const, text: accountPath.vi }]),
            {
              kind: 'warning',
              text: 'Liên kết tải hết hạn sau 24 giờ và chỉ dùng được khi bạn còn quyền với hồ sơ. Tệp có dữ liệu riêng của gia đình: đừng chuyển tiếp email này, hãy cất tệp ở nơi an toàn.',
            },
          ])
        : c('Your data export is ready', 'Download it within 24 hours', [
            {
              kind: 'text',
              text: link
                ? 'The data export you asked for is ready. Tap the button below to download it (a .zip file).'
                : 'The data export you asked for is ready. Open the app to download it:',
            },
            ...size,
            ...(link
              ? [
                  { kind: 'button' as const, label: 'Download the file', url: link },
                  { kind: 'note' as const, text: `Or open the app: ${accountPath.en}.` },
                ]
              : [{ kind: 'steps' as const, text: accountPath.en }]),
            {
              kind: 'warning',
              text: 'The link expires in 24 hours and only works while you still have access to the profile. The file holds your family’s private data: do not forward this email, and keep the file somewhere safe.',
            },
          ]);
    }
    case 'supportReply':
      return c(
        vi ? `Child Life trả lời yêu cầu ${d.ticket}` : `Child Life replied to ${d.ticket}`,
        (d.body ?? '').slice(0, 90),
        [
          { kind: 'quote', text: d.body ?? '' },
          {
            kind: 'note',
            text: vi
              ? `Mã yêu cầu ${d.ticket}. Bạn trả lời email này nếu cần thêm giúp đỡ.`
              : `Request ${d.ticket}. Reply to this email if you need more help.`,
          },
        ],
      );
    case 'storageGranted':
      return vi
        ? c(`Gia đình bạn có thêm ${d.amountGb} GB`, `Dung lượng mới: ${d.quotaGb} GB`, [
            ...(d.body ? [{ kind: 'quote' as const, text: d.body }] : []),
            { kind: 'facts', rows: [['Dung lượng mới', `${d.quotaGb} GB`]] },
            { kind: 'text', text: 'Ảnh, video đang chờ sẽ tự tải tiếp.' },
          ])
        : c(`Your family has ${d.amountGb} GB more`, `New storage: ${d.quotaGb} GB`, [
            ...(d.body ? [{ kind: 'quote' as const, text: d.body }] : []),
            { kind: 'facts', rows: [['New storage', `${d.quotaGb} GB`]] },
            { kind: 'text', text: 'Waiting photos and videos will upload by themselves.' },
          ]);
    case 'storageDeclined':
      return vi
        ? c('Về yêu cầu thêm dung lượng', 'Phản hồi từ Child Life', [
            { kind: 'quote', text: d.body ?? '' },
            {
              kind: 'note',
              text: 'Bạn có thể giải phóng chỗ trong app (Tôi → Dung lượng) hoặc trả lời email này.',
            },
          ])
        : c('About your storage request', 'A reply from Child Life', [
            { kind: 'quote', text: d.body ?? '' },
            {
              kind: 'note',
              text: 'You can free up space in the app (Me → Storage) or reply to this email.',
            },
          ]);
    case 'staffInvite':
      return vi
        ? c(
            `${d.fromName} mời bạn vào Child Life · Vận hành`,
            `Vai trò: ${d.role}`,
            [
              { kind: 'facts', rows: [['Vai trò', d.role ?? '—']] },
              {
                kind: 'text',
                text: 'Mở cổng Vận hành, chọn “Link qua email” và nhập đúng email này để đăng nhập. Lời mời hết hạn sau 7 ngày.',
              },
              { ...portal, url: d.url ?? links.adminOrigin },
            ],
            'Bạn nhận email này vì được mời vào nhóm vận hành Child Life.',
          )
        : c(
            `${d.fromName} invited you to Child Life · Operations`,
            `Role: ${d.role}`,
            [
              { kind: 'facts', rows: [['Role', d.role ?? '—']] },
              {
                kind: 'text',
                text: 'Open the operations portal, choose “Email link” and enter this email to sign in. The invitation expires in 7 days.',
              },
              { ...portal, url: d.url ?? links.adminOrigin },
            ],
            'You got this email because you were invited to the Child Life operations team.',
          );
    case 'ownershipStaffRequest':
      return vi
        ? c('Xác nhận chuyển quyền chủ hồ sơ', 'Đồng ý hoặc từ chối trong 48 giờ', [
            {
              kind: 'text',
              text: 'Hỗ trợ Child Life nhận được yêu cầu chuyển quyền chủ hồ sơ của bạn:',
            },
            {
              kind: 'facts',
              rows: [
                ['Chủ mới', d.toEmail ?? '—'],
                ['Mã yêu cầu', d.ticket ?? '—'],
              ],
            },
            { kind: 'text', text: 'Mở app để đồng ý hoặc từ chối trong 48 giờ:' },
            { kind: 'steps', text: accountPath.vi },
            {
              kind: 'warning',
              text: 'Nếu bạn không yêu cầu, hãy chọn “Không đồng ý”. Child Life không bao giờ hỏi mật khẩu của bạn.',
            },
          ])
        : c('Confirm the profile ownership transfer', 'Agree or decline within 48 hours', [
            {
              kind: 'text',
              text: 'Child Life Support received a request to transfer your profile ownership:',
            },
            {
              kind: 'facts',
              rows: [
                ['New owner', d.toEmail ?? '—'],
                ['Request', d.ticket ?? '—'],
              ],
            },
            { kind: 'text', text: 'Open the app to agree or decline within 48 hours:' },
            { kind: 'steps', text: accountPath.en },
            {
              kind: 'warning',
              text: 'If you did not ask for this, choose “Decline”. Child Life never asks for your password.',
            },
          ]);
  }
}

// ---------- Sign-in emails (D-054: instead of Firebase Auth's own) ----------

export const authTemplates = ['verifyEmail', 'resetPassword', 'signInLink'] as const;
export type AuthTemplate = (typeof authTemplates)[number];

export function renderAuthEmail(
  template: AuthTemplate,
  locale: Locale,
  d: { link: string; email: string },
): RenderedMail {
  const vi = locale === 'vi';
  const reason = vi
    ? `Email này được gửi tới ${d.email} theo yêu cầu trên Child Life.`
    : `This email was sent to ${d.email} at a request on Child Life.`;
  const ignore: Block = {
    kind: 'note',
    text: vi
      ? 'Không phải bạn yêu cầu? Bỏ qua email này, tài khoản của bạn vẫn an toàn.'
      : "Didn't ask for this? Ignore this email; your account stays safe.",
  };
  const c = (subject: string, preheader: string, blocks: Block[]) =>
    layout({ locale, subject, preheader, title: subject, blocks: [...blocks, ignore], reason });
  switch (template) {
    case 'verifyEmail':
      return vi
        ? c('Xác minh email của bạn', 'Một bước nữa để bảo vệ tài khoản', [
            {
              kind: 'text',
              text: 'Bấm nút dưới đây để xác nhận đây là email của bạn. Email đã xác minh giúp bạn lấy lại tài khoản khi quên mật khẩu.',
            },
            { kind: 'button', label: 'Xác minh email', url: d.link },
            { kind: 'note', text: 'Liên kết dùng được một lần và hết hạn sau 3 ngày.' },
          ])
        : c('Verify your email', 'One more step to protect your account', [
            {
              kind: 'text',
              text: 'Tap the button below to confirm this is your email. A verified email lets you get back in if you forget your password.',
            },
            { kind: 'button', label: 'Verify email', url: d.link },
            { kind: 'note', text: 'The link works once and expires in 3 days.' },
          ]);
    case 'resetPassword':
      return vi
        ? c('Đặt lại mật khẩu Child Life', 'Liên kết đặt lại mật khẩu, hết hạn sau 1 giờ', [
            {
              kind: 'text',
              text: 'Bạn vừa yêu cầu đặt lại mật khẩu. Bấm nút dưới đây để chọn mật khẩu mới.',
            },
            { kind: 'button', label: 'Đặt mật khẩu mới', url: d.link },
            { kind: 'note', text: 'Liên kết dùng được một lần và hết hạn sau 1 giờ.' },
          ])
        : c('Reset your Child Life password', 'Your reset link, valid for 1 hour', [
            {
              kind: 'text',
              text: 'You asked to reset your password. Tap the button below to choose a new one.',
            },
            { kind: 'button', label: 'Choose a new password', url: d.link },
            { kind: 'note', text: 'The link works once and expires in 1 hour.' },
          ]);
    case 'signInLink':
      return vi
        ? c('Đăng nhập Child Life · Vận hành', 'Liên kết đăng nhập, hết hạn sau 1 giờ', [
            {
              kind: 'text',
              text: 'Bấm nút dưới đây trên cùng trình duyệt bạn đã yêu cầu để đăng nhập cổng Vận hành.',
            },
            { kind: 'button', label: 'Đăng nhập', url: d.link },
            {
              kind: 'note',
              text: 'Liên kết dùng được một lần và hết hạn sau 1 giờ. Đừng chuyển tiếp email này.',
            },
          ])
        : c('Sign in to Child Life · Operations', 'Your sign-in link, valid for 1 hour', [
            {
              kind: 'text',
              text: 'Tap the button below in the same browser you asked from to sign in to the operations portal.',
            },
            { kind: 'button', label: 'Sign in', url: d.link },
            {
              kind: 'note',
              text: 'The link works once and expires in 1 hour. Do not forward this email.',
            },
          ]);
  }
}
