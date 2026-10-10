import type { CSSProperties } from 'react';
import { useSite } from '../context';
import type { CareKind, CareTileText } from '../content/types';
import { Art, Icon, art, careArt, type IconName } from './primitives';

/** Illustrative app UI used inside the landing mockups (spec §3–§7). All of it is decorative:
 *  the surrounding visual is aria-hidden and the real content lives in the section copy. */

/** A running timer that keeps counting once the page is interactive (see startTicking). */
export function Tick({ value, className }: { value: string; className?: string }) {
  return (
    <span className={className ? `tabular ${className}` : 'tabular'} data-tick="">
      {value}
    </span>
  );
}

/** App CareTile at ×1 (Today grid); scale with a wrapper for the Chăm sóc panel. */
export function CareTile({
  kind,
  text,
  width,
  style,
  live,
}: {
  kind: CareKind;
  text: CareTileText;
  width?: number;
  style?: CSSProperties;
  live?: boolean;
}) {
  const [first, ...rest] = text.meta[0].split(' · ');
  return (
    <div className={`care-tile care--${kind}`} style={{ width, ...style }}>
      <span className="care-tile__label">{text.label}</span>
      <span className="care-tile__value">{text.value}</span>
      <span className="care-tile__meta">
        <span>
          {live && first ? (
            <>
              <Tick value={first} />
              {rest.length ? ` · ${rest.join(' · ')}` : ''}
            </>
          ) : (
            text.meta[0]
          )}
        </span>
        <span>{text.meta[1]}</span>
      </span>
      <Art src={careArt[kind]} className="care-tile__art" />
    </div>
  );
}

export function QuickTile({
  kind,
  label,
  value,
}: {
  kind: 'bottle' | 'breast' | 'sleep' | 'diaper';
  label: string;
  value: string;
}) {
  return (
    <div className={`quick-tile care--${kind}`}>
      <span className="quick-tile__plus">
        <Icon name="plus" size={14} />
      </span>
      <Art src={careArt[kind]} size={34} />
      <span className="quick-tile__label">{label}</span>
      <span className="quick-tile__value">{value}</span>
    </div>
  );
}

function QuickRow() {
  const { c } = useSite();
  const t = c.quick.tiles;
  return (
    <div className="quick-row">
      <QuickTile kind="bottle" {...t.bottle} />
      <QuickTile kind="breast" {...t.breast} />
      <QuickTile kind="sleep" {...t.sleep} />
      <QuickTile kind="diaper" {...t.diaper} />
    </div>
  );
}

function WidgetHeader({ meta }: { meta: string }) {
  const { c } = useSite();
  return (
    <div className="widget__header">
      <Art src={art.babyFace} size={22} />
      <span className="widget__baby">{c.mock.baby}</span>
      <span className="widget__meta">{meta}</span>
    </div>
  );
}

/** Widget/Large 364 × 382. */
export function WidgetLarge({ style }: { style?: CSSProperties }) {
  const { c } = useSite();
  const l = c.quick.large;
  const dots = [
    'var(--care-bottle-accent)',
    'var(--care-diaper-accent)',
    'var(--care-sleep-accent)',
  ];
  return (
    <div className="widget widget--large" style={style}>
      <WidgetHeader meta={c.mock.date} />
      <div className="widget__status">
        <Art src={careArt.sleep} size={36} />
        <span className="widget__status-text">
          <span className="widget__status-title">{l.status}</span>
          <span className="caption">{l.statusSub}</span>
        </span>
        <span className="widget__pill">{l.sleepButton}</span>
      </div>
      <QuickRow />
      <span className="caption caption--strong">{l.recentTitle}</span>
      <div className="widget__recent">
        {l.recent.map((row, i) => (
          <div key={row.time} className="widget__recent-row">
            <span className="dot" style={{ background: dots[i] }} />
            <span className="caption widget__time">{row.time}</span>
            <span className="widget__recent-label">{row.label}</span>
            <span className="caption">{row.who}</span>
          </div>
        ))}
      </div>
      <span className="widget__totals caption">{l.totals}</span>
    </div>
  );
}

/** Widget/Medium 364 × 170. */
export function WidgetMedium({ style }: { style?: CSSProperties }) {
  const { c } = useSite();
  return (
    <div className="widget widget--medium" style={style}>
      <WidgetHeader meta={c.quick.mediumMeta} />
      <QuickRow />
    </div>
  );
}

/** Widget/Small 170 × 170: bottle (default), bottle just logged, or sleep timer (Night). */
export function WidgetSmall({
  variant,
  style,
}: {
  variant: 'bottle' | 'logged' | 'sleep';
  style?: CSSProperties;
}) {
  const { c } = useSite();
  const b = c.mock.bottleWidget;
  if (variant === 'sleep') {
    return (
      <div className="widget widget--small widget--sleep" style={style}>
        <div className="widget__small-top">
          <Art src={careArt.sleep} size={30} />
          <span className="widget__small-label care-ink--sleep">{c.night.sleepWidget.label}</span>
        </div>
        <Tick value={c.mock.live.timer} className="widget__numeral" />
        <span className="caption">{c.night.sleepWidget.sub}</span>
        <span className="widget__button widget__button--sleep">{c.mock.live.wake}</span>
      </div>
    );
  }
  if (variant === 'logged') {
    return (
      <div className="widget widget--small widget--logged" style={style}>
        <div className="widget__small-top">
          <Art src={careArt.bottle} size={30} />
          <span className="widget__small-label care-ink--bottle">{b.label}</span>
          <span className="widget__done">
            <Icon name="check" size={12} />
          </span>
        </div>
        <span className="widget__big">{c.quick.logged.title}</span>
        <span className="caption">{c.quick.logged.meta}</span>
        <span className="widget__buttons">
          <span className="widget__button widget__button--ghost">{c.quick.logged.undo}</span>
          <span className="widget__button widget__button--ghost">{c.quick.logged.edit}</span>
        </span>
      </div>
    );
  }
  return (
    <div className="widget widget--small" style={style}>
      <div className="widget__small-top">
        <Art src={careArt.bottle} size={30} />
        <span className="widget__small-label care-ink--bottle">{b.label}</span>
      </div>
      <span className="widget__big">{b.ago}</span>
      <span className="caption">{b.meta}</span>
      <span className="widget__button widget__button--bottle">{b.button}</span>
    </div>
  );
}

/** Lock/Circular 76 × 76 with a progress ring (sleep ≈ 62 %, feed ≈ 38 %). */
export function LockCircular({
  icon,
  value,
  progress,
  radius = 38,
  style,
}: {
  icon: IconName;
  value: string;
  progress: number;
  radius?: number;
  style?: CSSProperties;
}) {
  const r = 33.84; // ring 72 inset 2, stroke 4.32
  const length = 2 * Math.PI * r;
  return (
    <div className="lock-circular" style={{ borderRadius: radius, ...style }}>
      <svg className="lock-circular__ring" viewBox="0 0 76 76" aria-hidden="true">
        <circle cx="38" cy="38" r={r} className="ring-track" />
        <circle
          cx="38"
          cy="38"
          r={r}
          className="ring-progress"
          style={{
            strokeDasharray: length,
            ['--ring-len' as string]: length,
            ['--ring-offset' as string]: length * (1 - progress),
          }}
        />
      </svg>
      <Icon name={icon} size={18} />
      <span className="lock-circular__value">{value}</span>
    </div>
  );
}

/** LiveActivity (lock screen), 364 wide at ×1; scale it with `scale`. */
export function LiveActivity({
  scale,
  radius,
  style,
}: {
  scale: number;
  radius: number;
  style?: CSSProperties;
}) {
  const { c } = useSite();
  const l = c.mock.live;
  return (
    <div
      className="live"
      style={{ borderRadius: radius / scale, transform: `scale(${scale})`, ...style }}
    >
      <div className="live__top">
        <Art src={art.appIcon} size={18} className="live__icon" />
        <span className="live__app">{l.app}</span>
        <span className="live__shared">{l.shared}</span>
      </div>
      <div className="live__main">
        <Art src={careArt.sleep} size={40} />
        <span className="live__text">
          <span className="live__title">{l.title}</span>
          <span className="live__sub">{l.sub}</span>
        </span>
        <Tick value={l.timer} className="live__timer" />
      </div>
      <div className="live__actions">
        <span className="live__button live__button--wake">{l.wake}</span>
        <span className="live__button">{l.editStart}</span>
      </div>
    </div>
  );
}

/** Lock screen 316 × 440 with Dynamic Island, clock, two circulars and the Live Activity. */
export function LockScreen({ style }: { style?: CSSProperties }) {
  const { c } = useSite();
  return (
    <div className="lockscreen" style={style}>
      <div className="lockscreen__island">
        <Art src={careArt.sleep} size={24} />
        <span className="tabular">{c.mock.circular.sleep}</span>
      </div>
      <span className="lockscreen__date">{c.mock.date}</span>
      <span className="lockscreen__clock">9:41</span>
      <LockCircular
        icon="sleep"
        value={c.mock.circular.sleep}
        progress={0.62}
        style={{ position: 'absolute', left: 64, top: 184 }}
      />
      <LockCircular
        icon="feed"
        value={c.mock.circular.feed}
        progress={0.38}
        style={{ position: 'absolute', left: 176, top: 184 }}
      />
      <LiveActivity
        scale={0.8}
        radius={24}
        style={{ position: 'absolute', left: 12.4, top: 286, transformOrigin: '0 0' }}
      />
    </div>
  );
}

/** DayRhythm at ×1 (343 wide); bar positions from spec §4 (left % / right %). */
export function DayRhythm({ style }: { style?: CSSProperties }) {
  const { c } = useSite();
  const r = c.care.rhythm;
  const keys = ['bottle', 'breast', 'sleep', 'diaper'] as const;
  const bars: [string, number, number, 'sleep' | 'event'][] = [
    ['sleep', 0, 72.92, 'sleep'],
    ['sleep', 48.96, 45.5, 'sleep'],
    ['bottle', 32.85, 66.18, 'event'],
    ['diaper', 37.73, 61.31, 'event'],
    ['breast', 47.43, 51.28, 'event'],
    ['diaper', 56.48, 42.56, 'event'],
    ['bottle', 59.23, 39.81, 'event'],
  ];
  const legend = ['sleep', 'bottle', 'breast', 'diaper'] as const;
  return (
    <div className="rhythm" style={style}>
      <span className="rhythm__title">{r.title}</span>
      <div className="rhythm__totals">
        {r.totals.map(([label, value], i) => (
          <div key={label} className="rhythm__total">
            <span className="rhythm__key" style={{ background: `var(--care-${keys[i]}-accent)` }} />
            <span className="rhythm__total-text">
              <span className="rhythm__total-label" style={{ color: `var(--care-${keys[i]}-ink)` }}>
                {label}
              </span>
              <span className="rhythm__total-value">{value}</span>
            </span>
          </div>
        ))}
      </div>
      <div className="rhythm__track">
        {bars.map(([kind, left, right, shape], i) => (
          <span
            key={i}
            className={`rhythm__bar rhythm__bar--${shape} grow-x`}
            style={{
              left: `${left}%`,
              right: `${right}%`,
              background: `var(--care-${kind}-accent)`,
              ['--i' as string]: i,
            }}
          />
        ))}
        <span className="rhythm__now" style={{ left: '62.83%', right: '36.52%' }} />
      </div>
      <div className="rhythm__axis">
        {r.axis.map((tick) => (
          <span key={tick}>{tick}</span>
        ))}
      </div>
      <div className="rhythm__legend">
        {r.legend.map((label, i) => (
          <span key={label}>
            <span
              className="rhythm__square"
              style={{ background: `var(--care-${legend[i]}-accent)` }}
            />
            {label}
          </span>
        ))}
      </div>
    </div>
  );
}
