import { Icon, type IconName } from './primitives';
import type { Tint } from './kit';
import { staggerStyle } from '../motion';

export interface BulletItem {
  icon: IconName;
  /** Care colour family for the icon box and stroke. */
  tone: 'bottle' | 'sleep' | 'diaper' | 'mint' | 'sun';
  title: string;
  sub?: string;
}

/** Icon-box bullet list (spec §4–§5): 40 × 40 tinted box + SemiBold 17 title + Medium 15 sub. */
export function Bullets({ items }: { items: BulletItem[] }) {
  return (
    <ul className="bullets">
      {items.map((item, i) => (
        <li key={item.title} className="bullet reveal" style={staggerStyle(i + 2)}>
          <span className={`bullet__icon tone--${item.tone}`}>
            <Icon name={item.icon} size={20} />
          </span>
          <span className="bullet__text">
            <strong>{item.title}</strong>
            {item.sub && <span>{item.sub}</span>}
          </span>
        </li>
      ))}
    </ul>
  );
}

export interface CompactBulletItem {
  icon: IconName;
  tint: Tint;
  title: string;
  sub: string;
  subShort: string;
}

/** v3 bullet (12-landing-v3 §0.5): 36 × 36 box, SemiBold 16 / Medium 14; mobile wording below 1120.
 *  `dark` recolours it for the dark watch band (25-landing-v5-home §3.1). */
export function CompactBullets({ items, dark }: { items: CompactBulletItem[]; dark?: boolean }) {
  return (
    <ul className={dark ? 'bullets bullets--compact bullets--on-dark' : 'bullets bullets--compact'}>
      {items.map((item, i) => (
        <li key={item.title} className="bullet reveal" style={staggerStyle(i + 2)}>
          <span className={`bullet__icon tint--${item.tint}`}>
            <Icon name={item.icon} size={18} />
          </span>
          <span className="bullet__text">
            <strong>{item.title}</strong>
            <span className="only-desktop-inline">{item.sub}</span>
            <span className="only-mobile-inline">{item.subShort}</span>
          </span>
        </li>
      ))}
    </ul>
  );
}
