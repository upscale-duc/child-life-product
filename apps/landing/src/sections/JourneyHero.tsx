import landscape from '../assets/figma/journey-landscape.svg';
import { IconBox, type Tint } from '../components/kit';
import { Eyebrow, Fit, Icon, Photo, at, type IconName } from '../components/primitives';
import { useSite } from '../context';

const promises: [IconName, Tint][] = [
  ['plus', 'mint'],
  ['spark', 'sleep'],
  ['memories', 'peach'],
];

// Stage nodes on the road (14-landing-v3-home §2): x, y, size, chip x, chip y. Node 1 is a photo.
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

/** v3 home hero (14-landing-v3-home §2): copy + the journey landscape. The scenery is one SVG;
 *  nodes, age chips and cards stay HTML so they translate. */
export function JourneyHero() {
  const { c } = useSite();
  const h = c.home.hero;
  const stages = c.journey.stages;
  return (
    <section id="gioi-thieu" className="journey-hero container" aria-labelledby="hero-title">
      <div className="journey-hero__copy">
        <Eyebrow tone="mint" className="enter">
          {h.eyebrow}
        </Eyebrow>
        <h1 id="hero-title" className="journey-hero__title">
          <span>{h.title[0]}</span> <span>{h.title[1]}</span>
        </h1>
        <p className="journey-hero__lead">{h.lead}</p>
        <ul className="journey-hero__promises hide-mobile enter" style={{ ['--i' as string]: 1 }}>
          {h.promises.map((promise, i) => (
            <li key={promise}>
              <IconBox tint={promises[i]![1]} icon={promises[i]![0]} size={16} />
              {promise}
            </li>
          ))}
        </ul>
        <a
          className="btn btn--ink journey-hero__explore pressable enter"
          style={{ ['--i' as string]: 2 }}
          href="#hanh-trinh"
        >
          {h.explore}
          <Icon name="chevron-down" size={16} />
        </a>
      </div>
      <div className="journey-hero__visual enter" style={{ ['--i' as string]: 1 }}>
        <Fit w={620} h={580} mobileScale={0.5403}>
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
              <span className="chip chip--sm tint--white" style={at(node.chipX, node.chipY)}>
                {stages[i]!.ages}
              </span>
            </span>
          ))}
          <div className="journey-card pop" style={at(10, 110)}>
            <IconBox tint="bottle" icon="feed" size={16} />
            <span className="journey-card__text">
              <strong>{h.art.feed.title}</strong>
              <span>{h.art.feed.sub}</span>
            </span>
          </div>
          <div className="journey-card pop" style={at(0, 350, { ['--i' as string]: 1 })}>
            <Photo tone="sun" className="journey-card__photo" eager />
            <span className="journey-card__text">
              <strong>{h.art.smile.title}</strong>
              <span className="ink--mint">{h.art.smile.sub}</span>
            </span>
          </div>
          <div
            className="journey-card journey-card--line pop"
            style={at(250, 535, { ['--i' as string]: 2 })}
          >
            <Icon name="heart" size={14} className="ink--bottle" />
            {h.art.love}
          </div>
        </Fit>
      </div>
    </section>
  );
}
