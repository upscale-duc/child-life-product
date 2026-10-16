import type { CSSProperties, ReactNode } from 'react';
import { useSite } from '../context';
import lumiMascot from '../assets/figma/lumi-mascot-full.svg';
import { Art, Icon, art, type IconName } from './primitives';

/** Soft background + matching ink pairs used by the v3 chips, icon boxes and tiles
 *  (12-landing-v3-new-sections §0.5). `white` is surface/ink, `plain` surface-2/ink. */
export type Tint =
  | 'mint'
  | 'sun'
  | 'peach'
  | 'coral'
  | 'sleep'
  | 'bottle'
  | 'diaper'
  | 'growth'
  | 'accent'
  | 'plain'
  | 'white'
  | 'glass';

/** Text colour override (e.g. a white chip with mint text). */
export type Ink = 'mint' | 'bottle' | 'sleep' | 'growth' | 'ink';

export function Chip({
  tint = 'white',
  ink,
  icon,
  size = 'md',
  float,
  className,
  style,
  children,
}: {
  tint?: Tint;
  ink?: Ink;
  icon?: IconName;
  size?: 'md' | 'sm' | 'tag';
  float?: boolean;
  className?: string;
  style?: CSSProperties;
  children: ReactNode;
}) {
  const classes = [
    'chip',
    `chip--${size}`,
    `tint--${tint}`,
    ink && `ink--${ink}`,
    float && 'chip--float',
    className,
  ];
  return (
    <span className={classes.filter(Boolean).join(' ')} style={style}>
      {icon && <Icon name={icon} size={size === 'sm' ? 12 : 14} />}
      {children}
    </span>
  );
}

/** Rounded tinted square holding a line icon. */
export function IconBox({
  tint,
  icon,
  size,
  className,
}: {
  tint: Tint;
  icon: IconName;
  size: number;
  className?: string;
}) {
  return (
    <span className={`icon-box tint--${tint}${className ? ` ${className}` : ''}`}>
      <Icon name={icon} size={size} />
    </span>
  );
}

/** iOS-style push notification (bento, Nhắc nhở). Sizes per §0.5. */
export function Push({
  title,
  sub,
  actions,
  size,
  style,
}: {
  title: string;
  sub: string;
  actions?: [string, string, string];
  size: 'sm' | 'md' | 'lg';
  style?: CSSProperties;
}) {
  const { c } = useSite();
  return (
    <div className={`push push--${size}`} style={style}>
      <span className="push__head">
        <Art src={art.appIcon} className="push__icon" />
        <span className="push__app">{c.mock.push.app}</span>
        <span className="push__when">{c.mock.push.now}</span>
      </span>
      <span className="push__title">{title}</span>
      <span className="push__sub">{sub}</span>
      {actions && (
        <span className="push__actions">
          {actions.map((label, i) => (
            <span key={label} className={i === 0 ? 'push__action is-primary' : 'push__action'}>
              {label}
            </span>
          ))}
        </span>
      )}
    </div>
  );
}

/** App Toggle (23:262), on unless `off`; `scale` of the 51 × 31 base. Decorative. */
export function Toggle({ scale, off }: { scale: number; off?: boolean }) {
  return <span className={off ? 'toggle is-off' : 'toggle'} style={{ ['--s' as string]: scale }} />;
}

const initialTints: Tint[] = ['coral', 'sleep', 'diaper', 'mint'];

/** Family initials M · B · L · H: overlapping (bento) or inline (rule card). */
export function Initials({ letters, inline }: { letters: string[]; inline?: boolean }) {
  return (
    <span className={inline ? 'initials initials--inline' : 'initials'}>
      {letters.map((letter, i) => (
        <span key={i} className={`tint--${initialTints[i]}`} style={{ zIndex: i }}>
          {letter}
        </span>
      ))}
    </span>
  );
}

/** Lumi, the in-app assistant (Figma "Chat/Nút trợ lý" 628:9074). `size` is the 52-px bubble box;
 *  the halo and sparkles overflow it, as in the app's `LumiMascot`. Decorative. */
export function LumiMascot({
  size,
  className,
  style,
}: {
  size: number;
  className?: string;
  style?: CSSProperties;
}) {
  const k = size / 52;
  return (
    <span
      className={className ? `lumi-mascot ${className}` : 'lumi-mascot'}
      style={{ width: size, height: size, ...style }}
      aria-hidden="true"
    >
      <img
        src={lumiMascot}
        alt=""
        width={70 * k}
        height={72.5 * k}
        style={{ left: -8.9375 * k, top: -4.875 * k }}
        loading="lazy"
        decoding="async"
      />
    </span>
  );
}
