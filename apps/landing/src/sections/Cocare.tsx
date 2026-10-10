import family from '../assets/figma/cungcham-family.svg';
import { Bullets } from '../components/Bullets';
import { Eyebrow, Fit, Icon, at, type IconName } from '../components/primitives';
import { useSite } from '../context';

/** Cùng chăm (spec §5): copy left, family panel right (mirrors Chăm sóc). */
export function Cocare() {
  const { c } = useSite();
  const k = c.cocare;
  const feedIcons: [IconName, string][] = [
    ['plus', 'bottle'],
    ['check', 'diaper'],
    ['clock', 'sleep'],
  ];
  const initials = [
    { text: k.initials.mother, size: 35.29, x: 94.12, y: 116.18, color: 'white' },
    { text: k.initials.father, size: 29.41, x: 429.41, y: 146.32, color: 'white' },
    { text: k.initials.grandma, size: 26.47, x: 420.59, y: 397.79, color: 'var(--ink)' },
    { text: k.initials.nanny, size: 26.47, x: 97.06, y: 409.56, color: 'var(--ink)' },
  ];
  return (
    <section
      id="gia-dinh"
      className="section cocare container split"
      aria-labelledby="cocare-title"
    >
      <div className="split__copy">
        <header className="section-head reveal">
          <Eyebrow tone="peach">{k.eyebrow}</Eyebrow>
          <h2 id="cocare-title" className="h2 cocare__title">
            {k.title}
          </h2>
          <p className="lead split__lead">{k.lead}</p>
        </header>
        <Bullets
          items={[
            { icon: 'check', tone: 'mint', title: k.bullets[0] },
            { icon: 'family', tone: 'sleep', title: k.bullets[1] },
            { icon: 'cloud-off', tone: 'sun', title: k.bullets[2] },
          ]}
        />
      </div>
      <div className="split__visual reveal">
        <Fit w={640} h={600} mobileScale={0.5234}>
          <div className="panel panel--sun" />
          <div className="family-art" style={at(67.79, 0)}>
            <img src={family} alt="" width={504.41} height={600} loading="lazy" decoding="async" />
            {initials.map((initial) => (
              <span
                key={initial.text + initial.x}
                className="family-art__initial"
                style={{
                  left: initial.x,
                  top: initial.y,
                  fontSize: initial.size,
                  color: initial.color,
                }}
              >
                {initial.text}
              </span>
            ))}
            <Icon name="star" size={17.6} className="family-art__star" style={at(120.59, 94.12)} />
            <span className="family-chip pop" style={at(236.76, 23.53, { ['--i' as string]: 4 })}>
              <span className="family-chip__lock">
                <Icon name="lock" size={23.5} />
              </span>
              {k.chip}
            </span>
          </div>
          <div className="feed-card" style={at(32, 362)}>
            <span className="feed-card__title">{k.feed.title}</span>
            {k.feed.rows.map(([title, sub], i) => (
              <div key={title} className="feed-card__row pop" style={{ ['--i' as string]: i + 1 }}>
                <span className={`feed-card__disc tone--${feedIcons[i]![1]}`}>
                  <Icon name={feedIcons[i]![0]} size={16} />
                </span>
                <span className="feed-card__text">
                  <span className="feed-card__row-title">{title}</span>
                  <span className="feed-card__row-sub">{sub}</span>
                </span>
              </div>
            ))}
          </div>
        </Fit>
      </div>
    </section>
  );
}
