import type { CSSProperties, ReactNode } from 'react';
// Line icons are shared with the app (apps/mobile/assets/icons, stroke = currentColor).
import alert from '../../../mobile/assets/icons/alert.svg?raw';
import arrowRight from '../../../mobile/assets/icons/arrow-right.svg?raw';
import back from '../../../mobile/assets/icons/back.svg?raw';
import bookmark from '../../../mobile/assets/icons/bookmark.svg?raw';
import cake from '../../../mobile/assets/icons/cake.svg?raw';
import camera from '../../../mobile/assets/icons/camera.svg?raw';
import check from '../../../mobile/assets/icons/check.svg?raw';
import chevronDown from '../../../mobile/assets/icons/chevron-down.svg?raw';
import chevronRight from '../../../mobile/assets/icons/chevron-right.svg?raw';
import clock from '../../../mobile/assets/icons/clock.svg?raw';
import close from '../../../mobile/assets/icons/close.svg?raw';
import cloudOff from '../../../mobile/assets/icons/cloud-off.svg?raw';
import diaper from '../../../mobile/assets/icons/diaper.svg?raw';
import drop from '../../../mobile/assets/icons/drop.svg?raw';
import eye from '../../../mobile/assets/icons/eye.svg?raw';
import family from '../../../mobile/assets/icons/family.svg?raw';
import feed from '../../../mobile/assets/icons/feed.svg?raw';
import globe from '../../../mobile/assets/icons/globe.svg?raw';
import grid from '../../../mobile/assets/icons/grid.svg?raw';
import heart from '../../../mobile/assets/icons/heart.svg?raw';
import journal from '../../../mobile/assets/icons/journal.svg?raw';
import link from '../../../mobile/assets/icons/link.svg?raw';
import lock from '../../../mobile/assets/icons/lock.svg?raw';
import mail from '../../../mobile/assets/icons/mail.svg?raw';
import memories from '../../../mobile/assets/icons/memories.svg?raw';
import plus from '../../../mobile/assets/icons/plus.svg?raw';
import ruler from '../../../mobile/assets/icons/ruler.svg?raw';
import search from '../../../mobile/assets/icons/search.svg?raw';
import sleep from '../../../mobile/assets/icons/sleep.svg?raw';
import sliders from '../../../mobile/assets/icons/sliders.svg?raw';
import spark from '../../../mobile/assets/icons/spark.svg?raw';
import speaker from '../../../mobile/assets/icons/speaker.svg?raw';
import star from '../../../mobile/assets/icons/star.svg?raw';
import today from '../../../mobile/assets/icons/today.svg?raw';
import upload from '../../../mobile/assets/icons/upload.svg?raw';
import babyFace from '../../../mobile/assets/illustrations/baby-face.svg';
import miniBottle from '../../../mobile/assets/illustrations/mini-bottle.svg';
import miniDiaper from '../../../mobile/assets/illustrations/mini-diaper.svg';
import miniDrop from '../../../mobile/assets/illustrations/mini-drop.svg';
import miniMoon from '../../../mobile/assets/illustrations/mini-moon.svg';
import miniPump from '../../../mobile/assets/illustrations/mini-pump.svg';
import miniRuler from '../../../mobile/assets/illustrations/mini-ruler.svg';
import appIcon from '../assets/figma/logo-app-icon.svg';
import teddyCouch from '../assets/photos/teddy-one-couch.jpg';
import teddyEight from '../assets/photos/teddy-eight-months.jpg';
import teddyPlush from '../assets/photos/teddy-one-plush.jpg';
import teddySleep from '../assets/photos/teddy-newborn-sleep.jpg';
import teddyStroller from '../assets/photos/teddy-one-stroller.jpg';
import teddyTwoMonths from '../assets/photos/teddy-two-months.jpg';
import teddyYawn from '../assets/photos/teddy-newborn-yawn.jpg';
import logoMark from '../assets/figma/nav-logo-mark.svg';
import logoWordmark from '../assets/figma/nav-logo-wordmark.svg';
import type { CareKind } from '../content/types';

// Figma layer ids would repeat across the page; size comes from CSS (.icon svg).
const clean = (svg: string) => svg.replace(/\sid="[^"]*"/g, '').trim();

const icons = {
  alert,
  'arrow-right': arrowRight,
  back,
  bookmark,
  cake,
  camera,
  check,
  'chevron-down': chevronDown,
  'chevron-right': chevronRight,
  clock,
  close,
  'cloud-off': cloudOff,
  diaper,
  drop,
  eye,
  family,
  feed,
  globe,
  grid,
  heart,
  journal,
  link,
  lock,
  mail,
  memories,
  plus,
  ruler,
  search,
  sleep,
  sliders,
  spark,
  speaker,
  star,
  today,
  upload,
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

/** Illustration/Photo tones (Figma's 220 px library photos) → one real baby's first year, so every
 *  baby on the site is the same "Teddy" (Minnie Zhou's album, assets/photos/CREDITS.md). */
export const photos = {
  peach: teddyEight,
  sun: teddyCouch,
  sky: teddySleep,
  mint: teddyYawn,
  lilac: teddyPlush,
  rose: teddyStroller,
  sand: teddyTwoMonths,
  leaf: teddySleep,
  night: teddyYawn,
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
  tone:
    'mint' | 'peach' | 'sun' | 'sun-ink' | 'sunshine' | 'sleep' | 'night' | 'coral' | 'peach-ink';
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
