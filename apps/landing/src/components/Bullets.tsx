import { Icon, type IconName } from './primitives';
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
