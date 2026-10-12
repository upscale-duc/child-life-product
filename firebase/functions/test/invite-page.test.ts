import { describe, expect, it } from 'vitest';
import { inviteHostsFor, inviteOpenUrl } from '../src/env.js';
import { renderInvitePage } from '../src/pages.js';

// The invite web page (D-059): "Mở app và nhận lời mời" on another app domain, the steps for
// someone without the app, and the code to type.
const token = 'AbCdEfGhIjKlMnOpQrStUvWxYz012345';
const preview = {
  status: 'valid' as const,
  babyNickname: 'Teddy',
  inviterName: 'Mai',
  inviterRelation: 'mother' as const,
  inviterRelationCustom: null,
  role: 'caregiver' as const,
  relation: 'grandmother' as const,
  relationCustom: null,
  extraRights: null,
  expiresAt: '2026-10-15T03:00:00.000Z',
  alreadyMember: false,
};

describe('invite page', () => {
  it('the button opens the app through the other domain', () => {
    expect(inviteHostsFor('child-life-dev')).toEqual([
      'dev.childlife.app',
      'child-life-dev-landing.web.app',
    ]);
    expect(inviteOpenUrl('child-life-dev', 'dev.childlife.app', token)).toBe(
      `https://child-life-dev-landing.web.app/i/${token}`,
    );
    expect(inviteOpenUrl('child-life-dev', 'child-life-dev-landing.web.app', token)).toBe(
      `https://dev.childlife.app/i/${token}`,
    );
    expect(inviteOpenUrl('child-life-prod', 'childlife.app', token)).toBe(
      `https://childlife.app/i/${token}`,
    );
  });

  it('shows the open button, the install steps and the code', () => {
    const html = renderInvitePage('vi', preview as never, '482913', {
      openUrl: `https://child-life-dev-landing.web.app/i/${token}`,
      appStore: null,
      playStore: 'https://play.google.com/store/apps/details?id=app.childlife',
    });
    expect(html).toContain('Mai mời bạn cùng chăm Teddy');
    expect(html).toContain(
      `<a class="btn" href="https://child-life-dev-landing.web.app/i/${token}">Mở app và nhận lời mời</a>`,
    );
    expect(html).toContain('Cài app Child Life trên điện thoại.');
    expect(html).toContain('Google Play');
    expect(html).not.toContain('App Store');
    expect(html).toContain('<span class="code">482 913</span>');
    const en = renderInvitePage('en', preview as never, '482913', {
      openUrl: 'x',
      appStore: null,
      playStore: null,
    });
    expect(en).toContain('Open the app and accept');
    expect(en).not.toContain('class="stores"');
  });

  it('names are escaped; a closed invite says so', () => {
    const html = renderInvitePage(
      'vi',
      { ...preview, inviterName: '<b>Mai</b>' } as never,
      '482913',
      { openUrl: 'x', appStore: null, playStore: null },
    );
    expect(html).toContain('&lt;b&gt;Mai&lt;/b&gt; mời bạn');
    expect(
      renderInvitePage('vi', { status: 'expired' }, null, {
        openUrl: 'x',
        appStore: null,
        playStore: null,
      }),
    ).toContain('Lời mời đã hết hạn');
  });
});
