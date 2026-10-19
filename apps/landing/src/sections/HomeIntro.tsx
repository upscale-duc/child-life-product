import landscape from '../assets/figma/journey-landscape.svg';
import { IconBox, type Tint } from '../components/kit';
import { AppCta } from '../components/StoreBadges';
import { Eyebrow, Fit, Icon, Photo, at, type IconName } from '../components/primitives';
import { useSite } from '../context';
import { staggerStyle } from '../motion';

// Stage nodes on the road (14-landing-v3-home §2, unchanged in V8): x, y, size, chip x, chip y.
const nodes: {
  x: number;
  y: number;
  size: number;
  chipX: number;
  chipY: number;
  icon?: IconName;
}[] = [
  { x: 117, y: 447, size: 86, chipX: 110, chipY: 530 },
  { x: 248, y: 348, size: 64, chipX: 246, chipY: 424, icon: 'star' },
  { x: 362, y: 282, size: 56, chipX: 356, chipY: 346, icon: 'spark' },
  { x: 475, y: 185, size: 50, chipX: 450, chipY: 246, icon: 'globe' },
];

/** Hero (V8 "1 · Hero (lai)", Figma 740:7360 / 740:7459; 34-landing-v8-home §2): what the app
 *  does, the download component inside the first screen, and the journey landscape with stage
 *  statuses. The scenery is one SVG; chips and cards stay HTML so they translate. */
export function HomeHero() {
  const { c } = useSite();
  const h = c.homePage.hero;
  const stages = c.journey.stages;
  return (
    <section id="gioi-thieu" className="home-hero" aria-labelledby="hero-title">
      <div className="home-hero__inner container">
        <div className="home-hero__copy">
          <Eyebrow tone="mint" className="enter">
            {h.eyebrow}
          </Eyebrow>
          <h1 id="hero-title" className="home-hero__title">
            {h.title}
          </h1>
          <p className="home-hero__lead">{h.lead}</p>
          <p className="home-hero__support">
            <Icon name="star" size={14} />
            {h.support}
          </p>
          <div className="enter" style={{ ['--i' as string]: 1 }}>
            <AppCta />
          </div>
          <a className="home-hero__see pressable" href="#giup-gi">
            {h.seeApp}
            <Icon name="chevron-down" size={16} />
          </a>
        </div>
        <div className="home-hero__visual enter" style={{ ['--i' as string]: 1 }}>
          <Fit w={620} h={580} mobileScale={0.5645}>
            <img
              className="journey-art__land"
              src={landscape}
              alt=""
              width={540}
              height={540}
              style={at(50, 20)}
            />
            {nodes.map((node, i) => (
              <span key={i}>
                <span
                  className={`journey-node journey-node--${i + 1}`}
                  style={at(node.x, node.y, { width: node.size, height: node.size })}
                >
                  {node.icon ? (
                    <Icon name={node.icon} size={node.size * 0.4} />
                  ) : (
                    <Photo tone="peach" eager />
                  )}
                </span>
                <span
                  className={i === 0 ? 'home-hero__chip is-now' : 'home-hero__chip'}
                  style={at(node.chipX, node.chipY)}
                >
                  {stages[i]!.ages} · {i === 0 ? h.now : h.soon}
                </span>
              </span>
            ))}
            <div className="journey-card pop" style={at(10, 110)}>
              <IconBox tint="bottle" icon="feed" size={16} />
              <span className="journey-card__text">
                <strong>{h.feed.title}</strong>
                <span>{h.feed.sub}</span>
              </span>
            </div>
            <div className="journey-card pop" style={at(0, 350, { ['--i' as string]: 1 })}>
              <Photo tone="sun" className="journey-card__photo" eager />
              <span className="journey-card__text">
                <strong>{h.smile.title}</strong>
                <span className="ink--mint">{h.smile.sub}</span>
              </span>
            </div>
            <div className="home-video-card pop" style={at(410, 380, { ['--i' as string]: 2 })}>
              <span className="home-video-card__photo">
                <Photo tone="peach" eager />
                <span className="home-video-card__play">
                  <Icon name="arrow-right" size={14} />
                </span>
              </span>
              <strong>{h.video.title}</strong>
              <span className="home-video-card__meta">
                <Icon name="camera" size={12} />
                {h.video.meta}
              </span>
            </div>
          </Fit>
          <p className="home-hero__vision">{h.vision}</p>
        </div>
      </div>
    </section>
  );
}

// Ba giá trị pictures (§3.1): row icon and tint; the mobile rows use one icon per card (§3.2).
const careRows: [IconName, Tint][] = [
  ['feed', 'bottle'],
  ['sleep', 'sleep'],
  ['diaper', 'diaper'],
];
const valueLook: { tint: string; icon: IconName; iconTint: Tint }[] = [
  { tint: 'bottle', icon: 'feed', iconTint: 'bottle' },
  { tint: 'sleep', icon: 'star', iconTint: 'sleep' },
  { tint: 'peach', icon: 'heart', iconTint: 'peach' },
];

function ValuePicture({ index }: { index: number }) {
  const { c } = useSite();
  const m = c.homePage.values.mock;
  if (index === 0)
    return (
      <span className="value-rows">
        {m.rows.map(([label, time], i) => (
          <span key={label} className="value-row">
            <IconBox tint={careRows[i]![1]} icon={careRows[i]![0]} size={14} />
            <strong>{label}</strong>
            <span>{time}</span>
          </span>
        ))}
      </span>
    );
  if (index === 1)
    return (
      <span className="value-rows">
        <span className="value-week">
          <strong>{m.week.title}</strong>
          <span>{m.week.body}</span>
        </span>
        <span className="value-row">
          <IconBox tint="sun" icon="star" size={14} />
          <strong>{m.milestone[0]}</strong>
          <span>{m.milestone[1]}</span>
        </span>
      </span>
    );
  return (
    <span className="value-photos">
      <Photo tone="peach" />
      <Photo tone="sun" />
      <Photo tone="mint" />
    </span>
  );
}

/** Ba giá trị (Figma 735:5522 / 736:65714; §3): three things the app does. Desktop cards carry a
 *  picture; mobile shows them as rows with an icon. */
export function HomeValues() {
  const { c } = useSite();
  const v = c.homePage.values;
  return (
    <section
      id="giup-gi"
      className="home-section home-section--white"
      aria-labelledby="values-title"
    >
      <div className="container home-section__inner">
        <header className="home-head reveal">
          <Eyebrow tone="mint">{v.eyebrow}</Eyebrow>
          <h2 id="values-title" className="home-head__title">
            {v.title}
          </h2>
          <p className="home-head__lead">{v.lead}</p>
        </header>
        <ul className="home-values">
          {v.cards.map((card, i) => {
            const look = valueLook[i]!;
            return (
              <li key={card.title} className="home-value reveal" style={staggerStyle(i)}>
                <span className={`home-value__picture tint--${look.tint}`} aria-hidden="true">
                  <ValuePicture index={i} />
                </span>
                <IconBox
                  tint={look.iconTint}
                  icon={look.icon}
                  size={22}
                  className="home-value__icon"
                />
                <span className="home-value__text">
                  <h3>{card.title}</h3>
                  <p>{card.body}</p>
                </span>
              </li>
            );
          })}
        </ul>
      </div>
    </section>
  );
}
