import { CompactBullets } from '../components/Bullets';
import { IconBox, type Tint } from '../components/kit';
import { Eyebrow, Photo, type IconName } from '../components/primitives';
import { useSite } from '../context';

const topics: [IconName, Tint][] = [
  ['alert', 'peach'],
  ['drop', 'sun'],
  ['spark', 'bottle'],
  ['heart', 'sleep'],
  ['eye', 'diaper'],
  ['drop', 'mint'],
];

/** The app's first-aid card at × 1 (mobile size); desktop shows it × 1.25 (12-landing-v3 §5). */
function FirstAidCard() {
  const { c } = useSite();
  const card = c.firstAid.card;
  return (
    <div className="aid-card">
      <span className="aid-card__head">
        <IconBox tint="peach" icon="heart" size={20} />
        <span>
          <strong>{card.title}</strong>
          <span>{card.sub}</span>
        </span>
      </span>
      <span className="aid-card__topics">
        {card.topics.map((topic, i) => (
          <span key={topic} className="aid-card__topic">
            <IconBox tint={topics[i]![1]} icon={topics[i]![0]} size={14} />
            {topic}
          </span>
        ))}
      </span>
      <span className="aid-card__step">
        <Photo tone="peach" className="aid-card__photo" />
        <span>
          <strong>{card.step.label}</strong>
          <span>{card.step.text}</span>
        </span>
      </span>
    </div>
  );
}

/** Sơ cấp cứu (12-landing-v3 §5): panel left, copy right on desktop; head then panel on
 *  mobile, without bullets. */
export function FirstAid() {
  const { c } = useSite();
  const f = c.firstAid;
  return (
    <section
      id="so-cap-cuu"
      className="section feature container split split--visual-first"
      aria-labelledby="first-aid-title"
    >
      <div className="split__copy">
        <header className="section-head reveal">
          <Eyebrow tone="peach">{f.eyebrow}</Eyebrow>
          <h2 id="first-aid-title" className="h2 feature__title">
            {f.title}
          </h2>
          <p className="lead split__lead">
            <span className="only-desktop-inline">{f.lead}</span>
            <span className="only-mobile-inline">{f.leadShort}</span>
          </p>
        </header>
        <div className="only-desktop">
          <CompactBullets
            items={[
              { icon: 'heart', tint: 'peach', ...f.bullets[0] },
              { icon: 'eye', tint: 'sun', ...f.bullets[1] },
              { icon: 'check', tint: 'mint', ...f.bullets[2] },
            ]}
          />
        </div>
      </div>
      <div className="split__visual reveal" aria-hidden="true">
        <div className="aid-panel tint--peach">
          <div className="pop">
            <FirstAidCard />
          </div>
        </div>
      </div>
    </section>
  );
}
