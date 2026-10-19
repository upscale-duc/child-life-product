import type { CSSProperties, ReactNode } from 'react';
import { CompactBullets } from '../components/Bullets';
import { Eyebrow, Fit, Icon, at, type IconName } from '../components/primitives';
import { useSite } from '../context';

// W01 tiles: care accent and icon (25-landing-v5-home §3.2). Tile 3 is a running sleep timer.
const tiles: { accent: string; icon: IconName }[] = [
  { accent: 'var(--care-bottle-accent)', icon: 'feed' },
  { accent: 'var(--care-breast-accent)', icon: 'drop' },
  { accent: 'var(--care-sleep-accent)', icon: 'sleep' },
  { accent: 'var(--care-diaper-accent)', icon: 'diaper' },
  { accent: 'var(--care-pump-accent)', icon: 'drop' },
  { accent: 'var(--care-growth-accent)', icon: 'ruler' },
];

/** Apple Watch 46 mm (236 × 276 at scale 1, screen 208 × 248) drawn at `scale`. */
export function Watch({
  scale,
  children,
  style,
}: {
  scale: number;
  children: ReactNode;
  style?: CSSProperties;
}) {
  return (
    <div className="watch" style={{ ['--s' as string]: scale, ...style }}>
      <div className="watch__body">
        <span className="watch__crown" />
        <div className="watch__case">
          <div className="watch__screen">{children}</div>
        </div>
      </div>
    </div>
  );
}

export function HomeFace() {
  const { c } = useSite();
  const m = c.home.watch.mock;
  return (
    <div className="watch-face">
      <span className="watch-face__top">
        <strong>{m.baby}</strong>
        <span>{m.time}</span>
      </span>
      <div className="watch-tiles">
        {m.tiles.map((tile, i) => (
          <span
            key={tile.label}
            className={i === 2 ? 'watch-tile is-running' : 'watch-tile'}
            style={{ ['--accent' as string]: tiles[i]!.accent }}
          >
            <span className="watch-tile__head">
              <span className="watch-tile__icon">
                <Icon name={tiles[i]!.icon} size={13} />
              </span>
              {tile.label}
            </span>
            <strong>{tile.value}</strong>
            <span className="watch-tile__caption">{tile.caption}</span>
          </span>
        ))}
      </div>
    </div>
  );
}

function BreastFace() {
  const { c } = useSite();
  const b = c.home.watch.mock.breast;
  return (
    <div className="watch-face watch-face--gap">
      <span className="watch-face__top">
        <strong className="watch-face__accent">{b.title}</strong>
        <span>{c.home.watch.mock.time}</span>
      </span>
      <span className="watch-sides">
        <span className="is-active">
          <span>{b.left}</span>
          <strong>{b.leftValue}</strong>
        </span>
        <span>
          <span>{b.right}</span>
          <strong>{b.rightValue}</strong>
        </span>
      </span>
      <span className="watch-face__note">{b.total}</span>
      <span className="watch-actions">
        <span>{b.switchSide}</span>
        <span className="is-stop">{b.stop}</span>
      </span>
    </div>
  );
}

function NotifyFace() {
  const { c } = useSite();
  const n = c.home.watch.mock.notify;
  return (
    <div className="watch-face watch-face--notify">
      <span className="watch-notify__app">
        <span>
          <Icon name="clock" size={12} />
        </span>
        {n.app}
      </span>
      <strong className="watch-notify__title">{n.title}</strong>
      <span className="watch-face__note watch-face__note--left">{n.sub}</span>
      <span className="watch-pill is-bottle">{n.log}</span>
      <span className="watch-pill">{n.snooze}</span>
    </div>
  );
}

/** Trên cổ tay (25-landing-v5-home §3; a dark card in the Chặng 1 frame since 28 §3.5), copy left and three watch faces
 *  right; mobile shows the home face alone at real size. The faces are illustrative. */
export function WatchSection() {
  const { c } = useSite();
  const w = c.home.watch;
  return (
    <div id="apple-watch" className="watch-band">
      <div className="watch-band__inner">
        <div className="watch-band__copy">
          <Eyebrow tone="sunshine" className="reveal">
            {w.eyebrow}
          </Eyebrow>
          <h3 className="h2 h2--flat watch-band__title reveal">
            <span>{w.title[0]}</span> <span>{w.title[1]}</span>
          </h3>
          <p className="watch-band__lead reveal">{w.lead}</p>
          <div className="watch-band__solo only-mobile reveal" aria-hidden="true">
            <span className="watch-band__glow" />
            <Watch scale={1}>
              <HomeFace />
            </Watch>
          </div>
          <CompactBullets
            dark
            items={[
              { icon: 'check', tint: 'glass', ...w.bullets[0] },
              { icon: 'clock', tint: 'glass', ...w.bullets[1] },
              { icon: 'sleep', tint: 'glass', ...w.bullets[2] },
              { icon: 'cloud-off', tint: 'glass', ...w.bullets[3] },
            ]}
          />
          <p className="watch-band__note reveal">{w.note}</p>
        </div>
        <div className="watch-band__visual only-desktop reveal" aria-hidden="true">
          <Fit w={560} h={560} mobileScale={0.598}>
            <span className="watch-band__glow" style={at(50, 50)} />
            <Watch scale={0.95} style={at(330, 180, { opacity: 0.85 })}>
              <NotifyFace />
            </Watch>
            <Watch scale={0.95} style={at(0, 180, { opacity: 0.85 })}>
              <BreastFace />
            </Watch>
            <Watch scale={1.25} style={at(132.5, 110)}>
              <HomeFace />
            </Watch>
          </Fit>
        </div>
      </div>
    </div>
  );
}
