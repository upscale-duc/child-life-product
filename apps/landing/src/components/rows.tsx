import type { ReactNode } from 'react';
import type { MockRow as MockRowText } from '../content/types';
import { useSite } from '../context';
import { IconBox, type Tint } from './kit';
import { Photo, type IconName, type PhotoTone } from './primitives';

/** V9 illustration row ("Dòng", 37-landing-v9-home §3.1): icon, title + sub, and a trailing
 *  chip, icon trio, thumbnails or avatars. Decorative; used in Ba giá trị and 2b. */
export function MockRow({
  icon,
  tint,
  row,
  chipTint,
  trailing,
}: {
  icon: IconName;
  tint: Tint;
  row: MockRowText;
  chipTint?: Tint;
  trailing?: ReactNode;
}) {
  return (
    <span className="mrow">
      <IconBox tint={tint} icon={icon} size={14} />
      <span className="mrow__text">
        <strong>{row.title}</strong>
        <span>{row.sub}</span>
      </span>
      {row.chip ? (
        <span className={`mrow__chip tint--${chipTint ?? 'mint'}`}>{row.chip}</span>
      ) : (
        trailing
      )}
    </span>
  );
}

export function IconTrio({ items }: { items: [IconName, Tint][] }) {
  return (
    <span className="mrow__trio">
      {items.map(([icon, tint]) => (
        <IconBox key={icon} tint={tint} icon={icon} size={12} />
      ))}
    </span>
  );
}

export function Thumbs({ tones }: { tones: PhotoTone[] }) {
  return (
    <span className="mrow__thumbs">
      {tones.map((tone, i) => (
        <Photo key={i} tone={tone} />
      ))}
    </span>
  );
}

export type Person = 'mom' | 'dad' | 'grandma' | 'grandpa' | 'nanny';

/** Initial avatars (raw colours as drawn, 37 §0.2), overlapping. */
export function Avatars({ people, size = 22 }: { people: Person[]; size?: number }) {
  const { c } = useSite();
  return (
    <span className="avatars" style={{ ['--size' as string]: `${size}px` }}>
      {people.map((p) => (
        <span key={p} className={`avatar avatar--${p}`}>
          {c.homePage.people[p]}
        </span>
      ))}
    </span>
  );
}
