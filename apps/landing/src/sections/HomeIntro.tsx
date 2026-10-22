import landscape from '../assets/figma/journey-landscape.svg';
import { IconBox, type Tint } from '../components/kit';
import { Avatars, IconTrio, MockRow, Thumbs, type Person } from '../components/rows';
import { AppCta } from '../components/StoreBadges';
import {
  Eyebrow,
  Fit,
  Icon,
  Photo,
  at,
  type IconName,
  type PhotoTone,
} from '../components/primitives';
import { useSite } from '../context';
import { staggerStyle } from '../motion';
import { pathOf } from '../routes';

// Stage nodes on the road (14-landing-v3-home §2): x, y, size, chip x, chip y. V9 moves chip 4
// left because its text is longer (37 §2.1).
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
  { x: 475, y: 185, size: 50, chipX: 412, chipY: 244, icon: 'globe' },
];

/** Hero (V9 "1 · Hero (lai)", Figma 785:7042 / 785:7900; 37-landing-v9-home §2): what the app
 *  does, the store badges inside the first screen, and the journey landscape with stage
 *  statuses. The scenery is one SVG; chips and cards stay HTML so they translate. */
export function HomeHero() {
  const { c } = useSite();
  const h = c.homePage.hero;
  const stages = c.journey.stages;
  const status = (i: number) => (i === 0 ? h.now : i === 1 ? h.next : h.later);
  return (
    <section id="gioi-thieu" className="home-hero" aria-labelledby="hero-title">
      <div className="home-hero__inner container">
        <div className="home-hero__copy">
          <Eyebrow tone="mint" className="enter">
            {h.eyebrow[0]}
            <strong>{h.eyebrow[1]}</strong>
          </Eyebrow>
          <h1 id="hero-title" className="home-hero__title">
            {h.title}
          </h1>
          <p className="home-hero__lead">{h.lead}</p>
          <div className="enter" style={{ ['--i' as string]: 1 }}>
            <AppCta caption={false} />
          </div>
          <a className="home-hero__see pressable" href="#giup-gi">
            {h.firstYear}
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
                  {stages[i]!.ages} · {status(i)}
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
                <strong>{h.learn.title}</strong>
                <span className="ink--mint">{h.learn.sub}</span>
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
        </div>
      </div>
    </section>
  );
}

// Ba giá trị rows (37 §3.1): icon and tint per row, then the trailing element when the row has no
// chip text.
const rowLooks: { icon: IconName; tint: Tint; chipTint?: Tint }[][] = [
  [
    { icon: 'feed', tint: 'bottle' },
    { icon: 'clock', tint: 'sun', chipTint: 'sun' },
    { icon: 'family', tint: 'mint' },
  ],
  [
    { icon: 'star', tint: 'sun', chipTint: 'mint' },
    { icon: 'spark', tint: 'sleep', chipTint: 'sleep' },
    { icon: 'journal', tint: 'mint' },
  ],
  [
    { icon: 'search', tint: 'mint' },
    { icon: 'cake', tint: 'sun', chipTint: 'sun' },
    { icon: 'lock', tint: 'sleep' },
  ],
];
const trailing = [
  [
    <IconTrio
      key="trio"
      items={[
        ['feed', 'bottle'],
        ['sleep', 'sleep'],
        ['diaper', 'diaper'],
      ]}
    />,
    null,
    <Avatars key="a" people={['mom', 'dad', 'grandma'] satisfies Person[]} />,
  ],
  [null, null, <Thumbs key="t" tones={['peach', 'sun'] satisfies PhotoTone[]} />],
  [
    <Thumbs key="t" tones={['peach', 'sun', 'peach']} />,
    null,
    <Avatars key="a" people={['mom', 'dad', 'grandpa']} />,
  ],
];
const cardTints = ['bottle', 'sleep', 'peach'];

/** Ba giá trị (V9, Figma 785:7108 / 785:7971; 37 §3): three things the app does, each with three
 *  illustration rows, and the link to everything on the Năm đầu đời page. */
export function HomeValues() {
  const { c, route } = useSite();
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
          <p className="home-head__lead home-pillars">
            {v.pillars.map((pillar, i) => (
              <span key={pillar}>
                {i > 0 && <span aria-hidden="true"> · </span>}
                {pillar}
              </span>
            ))}
          </p>
        </header>
        <ul className="home-values">
          {v.cards.map((card, i) => (
            <li key={card.title} className="home-value reveal" style={staggerStyle(i)}>
              <span className={`home-value__picture tint--${cardTints[i]}`} aria-hidden="true">
                <span className="mrows">
                  {v.rows[i]!.map((row, k) => {
                    const look = rowLooks[i]![k]!;
                    return (
                      <MockRow
                        key={row.title}
                        icon={look.icon}
                        tint={look.tint}
                        chipTint={look.chipTint}
                        row={row}
                        trailing={trailing[i]![k]}
                      />
                    );
                  })}
                </span>
              </span>
              <span className="home-value__text">
                <h3>{card.title}</h3>
                <p>{card.body}</p>
              </span>
            </li>
          ))}
        </ul>
        <a
          className="home-button home-button--lg home-button--center pressable reveal"
          href={pathOf('stage1', route.locale)}
        >
          {v.button}
          <Icon name="arrow-right" size={16} />
        </a>
      </div>
    </section>
  );
}

const restartLooks: { icon: IconName; tint: Tint; chipTint?: Tint }[] = [
  { icon: 'camera', tint: 'sun' },
  { icon: 'star', tint: 'sleep', chipTint: 'sleep' },
  { icon: 'today', tint: 'mint', chipTint: 'mint' },
];
const pointLooks: { icon: IconName; tint: Tint }[] = [
  { icon: 'heart', tint: 'bottle' },
  { icon: 'star', tint: 'sleep' },
  { icon: 'memories', tint: 'sun' },
];

/** 2b · Bắt đầu lúc nào cũng kịp (V9, Figma 786:8714 / 791:69042; 37 §4): the baby's profile —
 *  a static age choice, the timeline so far and what Child Life sorts out — next to three points.
 *  Q-039: "Tìm lại 214 ảnh" is the iOS Tự lưu beta (D-066), whose first scan looks back 30 days. */
export function HomeRestart() {
  const { c } = useSite();
  const r = c.homePage.restart;
  return (
    <section
      id="bat-dau"
      className="home-section home-section--cloud"
      aria-labelledby="restart-title"
    >
      <div className="container home-section__inner">
        <header className="home-head reveal">
          <Eyebrow tone="mint">{r.eyebrow}</Eyebrow>
          <h2 id="restart-title" className="home-head__title">
            {r.title}
          </h2>
          <p className="home-head__lead only-mobile">{r.lead}</p>
        </header>
        <div className="restart reveal">
          <div className="restart__profile" aria-hidden="true">
            <span className="restart__head">
              <IconBox tint="white" icon="heart" size={16} />
              {r.head}
            </span>
            <span className="restart__ages">
              {r.ages.map((age, i) => (
                <span key={age} className={i === 2 ? 'is-active' : undefined}>
                  {age}
                </span>
              ))}
            </span>
            <span className="restart__timeline">
              <span className="restart__track">
                <span className="restart__fill" />
                <span className="restart__thumb" />
              </span>
              <span className="restart__labels">
                {r.timeline.map((label) => (
                  <span key={label}>{label}</span>
                ))}
              </span>
            </span>
            <span className="restart__sort">
              <span className="restart__sort-label">{r.sortLabel}</span>
              {r.rows.map((row, i) => (
                <MockRow
                  key={row.title}
                  icon={restartLooks[i]!.icon}
                  tint={restartLooks[i]!.tint}
                  chipTint={restartLooks[i]!.chipTint}
                  row={row}
                  trailing={i === 0 ? <Thumbs tones={['peach', 'sun', 'peach']} /> : undefined}
                />
              ))}
            </span>
          </div>
          <div className="restart__points">
            <ul>
              {r.points.map((point, i) => (
                <li key={point.title}>
                  <IconBox tint={pointLooks[i]!.tint} icon={pointLooks[i]!.icon} size={18} />
                  <span>
                    <strong>{point.title}</strong>
                    <span>{point.body}</span>
                  </span>
                </li>
              ))}
            </ul>
            <a className="home-button home-button--outline pressable" href="#tai-app">
              {r.button}
              <Icon name="arrow-right" size={16} />
            </a>
          </div>
        </div>
      </div>
    </section>
  );
}
