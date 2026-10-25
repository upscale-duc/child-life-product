// Vietnamese edition: on-screen copy and the few Figma layers whose text is English
// (problem-scene notes, chat bubbles, stage chips, CTA) are re-typeset in code with the
// Figma styles read from their SVG exports (cardStyles.json). App UI crops are already Vietnamese.
// Copy is engineering's draft from script.en.md + landing vi.ts wording — owner review (D-012).
import React from 'react';
import cardStyles from './cardStyles.json';
import { colors, FONT } from './engine';
import type { Lang } from './timeline';

const vi: Record<string, string> = {
  'Growing up,': 'Con lớn lên,',
  'one moment at a time.': 'qua từng khoảnh khắc.',
  'Child Life walks alongside your family —\nstarting with the very first year.':
    'Child Life đồng hành cùng gia đình bạn —\nbắt đầu từ năm đầu đời của con.',
  'Full of firsts.': 'Bao điều lần đầu.',
  'And a lot to keep track of.': 'Và thật nhiều thứ phải nhớ.',
  'The last feed.': 'Cữ bú vừa rồi.',
  ' The next nap.': ' Giấc ngủ sắp tới.',
  'The little updates, so everyone knows how the day is going.': 'Những cập nhật nhỏ, để cả nhà biết hôm nay của con.',
  'A smile.': 'Một nụ cười.',
  ' A sound.': ' Một tiếng bập bẹ.',
  'A moment you want to remember.': 'Một khoảnh khắc mình muốn giữ mãi.',
  'A shared space for caring for your child,': 'Không gian chung để cả nhà cùng chăm con,',
  'and keeping their story close.': 'và giữ gìn câu chuyện của con.',
  'Log it in a tap.': 'Ghi lại chỉ một chạm.',
  'Phone widget · Apple Watch · Siri': 'Widget · Apple Watch · Siri',
  'Pick up where they left off.': 'Ai chăm tiếp cũng nắm ngay.',
  'Tell Lumi.': 'Kể với Lumi.',
  'It drafts the log for you.': 'Lumi soạn sẵn ghi chép.',
  'You check it, then save.': 'Bạn xem lại, rồi mới lưu.',
  'Ideas that fit their age.': 'Gợi ý hợp tuổi con.',
  'Reminders when they matter.': 'Nhắc việc đúng lúc cần.',
  'Celebrate the firsts.': 'Mừng những lần đầu tiên.',
  'And bring your family along as your child grows.': 'Và cùng cả nhà đồng hành khi con lớn lên.',
  'Everyday photos,': 'Ảnh thường ngày,',
  'turned into keepsakes.': 'thành kỷ niệm để xem lại.',
  'The days you’re living now': 'Những ngày hôm nay',
  'are the memories you’ll treasure later.': 'là kỷ niệm trân quý mai sau.',
  'Less to keep track of.': 'Bớt điều phải nhớ.',
  'More to hold on to.': 'Thêm điều để giữ.',
  'Growing together, every step of the way.': 'Cùng con lớn lên, đồng hành từng bước.',
};

export const tr = (lang: Lang, text: string) => {
  if (lang === 'en') return text;
  const t = vi[text];
  if (t === undefined) throw new Error(`Missing Vietnamese copy for: ${text}`);
  return t;
};

// ---------- re-typeset cards ----------
const shadowNote = 'drop-shadow(0 10px 11px rgba(18,46,51,.16)) drop-shadow(0 2px 2px rgba(18,46,51,.1))';
const shadowMessage = 'drop-shadow(0 8px 12px rgba(23,61,68,.16))';
const shadowChip = 'drop-shadow(0 8px 24px rgba(23,61,68,.16))';

const viCards: Record<string, { text: string; tick?: string }> = {
  'Card/Note · Last feed · 9:10?': { text: 'Bú lúc 9:10?' },
  'Card/Note · Nap at 1:30?': { text: 'Ngủ lúc 13:30?' },
  'Card/Note · Vitamin D': { text: 'Vitamin D' },
  'Card/Note · Next nap?': { text: 'Giấc ngủ tới?' },
  'Card/Note · Vaccine · Sat': { text: 'Tiêm chủng · T7' },
  'Card/Note · Bath tonight': { text: 'Tắm tối nay' },
  'Card/Message · Did she eat yet?': { text: 'Con ăn chưa em?' },
  'Card/Message · Yes — 120 ml at 9': { text: 'Rồi — 120 ml lúc 9h', tick: '✓✓' },
  'Card/StageChip/0-12m': { text: '0–12 tháng · Đang có trong app' },
  'Card/StageChip/1-3y': { text: '1–3 tuổi · Chặng tiếp theo' },
  'Card/StageChip/3-6y': { text: '3–6 tuổi · Trong tương lai' },
  'Card/StageChip/6-12y': { text: '6–12 tuổi · Trong tương lai' },
  CTA: { text: 'childlife.app' },
};

export const hasViCard = (lang: Lang, name: string) => lang === 'vi' && name in viCards;

/** The card at its Figma (unrotated) size for `sceneId`; the caller positions, rotates and scales it. */
export const ViCard: React.FC<{ sceneId: string; name: string }> = ({ sceneId, name }) => {
  const c = viCards[name];
  const s = (cardStyles as Record<string, { h: number; rx: number; fill: string; ink: string | null }>)[`${sceneId}|${name}`];
  const base: React.CSSProperties = { fontFamily: FONT, whiteSpace: 'nowrap', display: 'inline-flex', alignItems: 'center' };
  if (name === 'CTA')
    return (
      <div style={{ ...base, fontSize: 26, gap: 10 }}>
        <span style={{ fontWeight: 600, color: colors.mintText }}>childlife.app</span>
        <span style={{ fontWeight: 500, color: colors.muted }}>· Sắp có trên iPhone và Android</span>
      </div>
    );
  if (name.startsWith('Card/StageChip'))
    return (
      <div style={{ ...base, height: s.h, padding: '0 22px', borderRadius: s.rx, background: s.fill, color: s.ink ?? colors.muted, fontSize: 18, fontWeight: 600, filter: shadowChip }}>
        {c.text}
      </div>
    );
  if (name.startsWith('Card/Message'))
    return (
      <div style={{ ...base, gap: 8, padding: '14px 18px', borderRadius: s.rx, background: s.fill, color: colors.ink, fontSize: 22, fontWeight: 500, filter: shadowMessage }}>
        {c.text}
        {c.tick ? <span style={{ fontSize: 16, fontWeight: 600, color: colors.mintText }}>{c.tick}</span> : null}
      </div>
    );
  // Note: h = text line + 2×16 padding (Figma: 30 px → 70, 24 px → 62).
  const size = Math.round((s.h - 32) / 1.27);
  return (
    <div style={{ ...base, padding: '16px 20px', borderRadius: s.rx, background: s.fill, color: colors.ink, fontSize: size, fontWeight: 600, filter: shadowNote }}>
      {c.text}
    </div>
  );
};
