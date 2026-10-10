import type { CSSProperties, ReactNode } from 'react';
// Line icons are shared with the app (apps/mobile/assets/icons, stroke = currentColor).
import alert from '../../../mobile/assets/icons/alert.svg?raw';
import arrowRight from '../../../mobile/assets/icons/arrow-right.svg?raw';
import bookmark from '../../../mobile/assets/icons/bookmark.svg?raw';
import cake from '../../../mobile/assets/icons/cake.svg?raw';
import check from '../../../mobile/assets/icons/check.svg?raw';
import chevronDown from '../../../mobile/assets/icons/chevron-down.svg?raw';
import chevronRight from '../../../mobile/assets/icons/chevron-right.svg?raw';
import clock from '../../../mobile/assets/icons/clock.svg?raw';
import close from '../../../mobile/assets/icons/close.svg?raw';
import cloudOff from '../../../mobile/assets/icons/cloud-off.svg?raw';
import drop from '../../../mobile/assets/icons/drop.svg?raw';
import eye from '../../../mobile/assets/icons/eye.svg?raw';
import family from '../../../mobile/assets/icons/family.svg?raw';
import feed from '../../../mobile/assets/icons/feed.svg?raw';
import globe from '../../../mobile/assets/icons/globe.svg?raw';
import heart from '../../../mobile/assets/icons/heart.svg?raw';
import journal from '../../../mobile/assets/icons/journal.svg?raw';
import lock from '../../../mobile/assets/icons/lock.svg?raw';
import mail from '../../../mobile/assets/icons/mail.svg?raw';
import memories from '../../../mobile/assets/icons/memories.svg?raw';
import plus from '../../../mobile/assets/icons/plus.svg?raw';
import search from '../../../mobile/assets/icons/search.svg?raw';
import sleep from '../../../mobile/assets/icons/sleep.svg?raw';
import sliders from '../../../mobile/assets/icons/sliders.svg?raw';
import spark from '../../../mobile/assets/icons/spark.svg?raw';
import star from '../../../mobile/assets/icons/star.svg?raw';
import today from '../../../mobile/assets/icons/today.svg?raw';
import babyFace from '../../../mobile/assets/illustrations/baby-face.svg';
import miniBottle from '../../../mobile/assets/illustrations/mini-bottle.svg';
import miniDiaper from '../../../mobile/assets/illustrations/mini-diaper.svg';
import miniDrop from '../../../mobile/assets/illustrations/mini-drop.svg';
import miniMoon from '../../../mobile/assets/illustrations/mini-moon.svg';
import miniPump from '../../../mobile/assets/illustrations/mini-pump.svg';
import miniRuler from '../../../mobile/assets/illustrations/mini-ruler.svg';
import baby0d3f8 from '../assets/figma/baby-0d3f8.jpg';
import baby1025f from '../assets/figma/baby-1025f.jpg';
import baby22456 from '../assets/figma/baby-22456.jpg';
import baby2d978 from '../assets/figma/baby-2d978.jpg';
import baby4222e from '../assets/figma/baby-4222e.jpg';
import baby4470d from '../assets/figma/baby-4470d.jpg';
import baby5d2ff from '../assets/figma/baby-5d2ff.jpg';
import baby61240 from '../assets/figma/baby-61240.jpg';
import babyAe95e from '../assets/figma/baby-ae95e.jpg';
import appIcon from '../assets/figma/logo-app-icon.svg';
import logoMark from '../assets/figma/nav-logo-mark.svg';
import logoWordmark from '../assets/figma/nav-logo-wordmark.svg';
import type { CareKind } from '../content/types';

// Figma layer ids would repeat across the page; size comes from CSS (.icon svg).
const clean = (svg: string) => svg.replace(/\sid="[^"]*"/g, '').trim();

const icons = {
  alert,
  'arrow-right': arrowRight,
  bookmark,
  cake,
  check,
  'chevron-down': chevronDown,
  'chevron-right': chevronRight,
  clock,
  close,
  'cloud-off': cloudOff,
  drop,
  eye,
  family,
  feed,
  globe,
  heart,
  journal,
  lock,
  mail,
  memories,
  plus,
  search,
  sleep,
  sliders,
  spark,
  star,
  today,
};
const cleaned = Object.fromEntries(Object.entries(icons).map(([k, v]) => [k, clean(v)])) as Record<
  IconName,
  string
>;

export type IconName = keyof typeof icons;

/** Decorative line icon (24 grid, stroke follows `color`). */
export function Icon({
  name,
  size = 20,
  className,
  style,
}: {
  name: IconName;
  size?: number;
  className?: string;
  style?: CSSProperties;
}) {
  return (
    <span
      className={className ? `icon ${className}` : 'icon'}
      style={{ width: size, height: size, ...style }}
      aria-hidden="true"
      dangerouslySetInnerHTML={{ __html: cleaned[name] }}
    />
  );
}

export const careArt: Record<CareKind, string> = {
  bottle: miniBottle,
  breast: miniDrop,
  sleep: miniMoon,
  diaper: miniDiaper,
  pump: miniPump,
  growth: miniRuler,
};

/** Illustration/Photo tones → the raster baby photos used in Figma (spec §14). */
export const photos = {
  mint: baby61240,
  peach: baby0d3f8,
  sun: baby22456,
  sky: baby4222e,
  lilac: baby1025f,
  sand: baby5d2ff,
  leaf: babyAe95e,
  rose: baby4470d,
  night: baby2d978,
};
export type PhotoTone = keyof typeof photos;

export const art = { babyFace, appIcon, miniMoon, miniBottle };

/** Decorative <img>: empty alt, lazy unless it is above the fold. */
export function Art({
  src,
  size,
  className,
  style,
  eager,
}: {
  src: string;
  size?: number;
  className?: string;
  style?: CSSProperties;
  eager?: boolean;
}) {
  return (
    <img
      src={src}
      alt=""
      width={size}
      height={size}
      className={className}
      style={style}
      loading={eager ? 'eager' : 'lazy'}
      decoding="async"
      draggable={false}
    />
  );
}

export function Photo({
  tone,
  className,
  style,
  eager,
}: {
  tone: PhotoTone;
  className?: string;
  style?: CSSProperties;
  eager?: boolean;
}) {
  return (
    <span className={className ? `photo ${className}` : 'photo'} style={style} data-tone={tone}>
      <img
        src={photos[tone]}
        alt=""
        width={220}
        height={220}
        loading={eager ? 'eager' : 'lazy'}
        decoding="async"
        draggable={false}
      />
    </span>
  );
}

/** Logo/Lockup Horizontal (mark 34 + 9.52 + wordmark 132.4 × 26.52) at a given scale. */
export function Lockup({ scale = 1, label }: { scale?: number; label?: string }) {
  return (
    <span
      className="lockup"
      style={{ gap: 9.52 * scale }}
      role={label ? 'img' : undefined}
      aria-label={label}
    >
      <img src={logoMark} alt="" width={34 * scale} height={34 * scale} />
      <img src={logoWordmark} alt="" width={132.4 * scale} height={26.52 * scale} />
    </span>
  );
}

/** Renders a fixed-size desktop composition and scales it to the available width (spec §13).
 *  `mobileScale` is the Figma scale at 375 and is used until JS measures the real width. */
export function Fit({
  w,
  h,
  mobileScale,
  className,
  children,
}: {
  w: number;
  h: number;
  mobileScale: number;
  className?: string;
  children: ReactNode;
}) {
  return (
    <div
      className={className ? `fit ${className}` : 'fit'}
      data-fit-w={w}
      style={{ aspectRatio: `${w} / ${h}`, maxWidth: w, ['--fit-m' as string]: mobileScale }}
      aria-hidden="true"
    >
      <div className="fit__stage" style={{ width: w, height: h }}>
        {children}
      </div>
    </div>
  );
}

export function Eyebrow({
  children,
  tone,
  className,
}: {
  children: ReactNode;
  tone: 'mint' | 'peach' | 'sun' | 'sun-ink' | 'sleep' | 'night' | 'coral';
  className?: string;
}) {
  return (
    <p className={`eyebrow eyebrow--${tone}${className ? ` ${className}` : ''}`}>{children}</p>
  );
}

/** Absolute placement inside a composition, in design pixels. */
export const at = (left: number, top: number, extra?: CSSProperties): CSSProperties => ({
  position: 'absolute',
  left,
  top,
  ...extra,
});
