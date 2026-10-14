import { scenes } from '../components/scenes';
import { Eyebrow, Icon } from '../components/primitives';
import { useSite } from '../context';
import { pathOf } from '../routes';
import { BentoGrid } from './Everything';
import { Utilities } from './Utilities';
import { WatchSection } from './Watch';
import { YourWay } from './YourWay';

/** "Xem đầy đủ năm đầu đời" (28-landing-v5b-home §3.6): two tilted photos and the button to the
 *  Chặng 1 page inside a mint halo. */
function FirstYearDetail() {
  const { c, route } = useSite();
  const f = c.home.firstYear;
  return (
    <div className="year-detail reveal">
      <div className="year-detail__copy">
        <Eyebrow tone="mint">{f.detail.eyebrow}</Eyebrow>
        <h3 className="year-detail__title">{f.detail.title}</h3>
        <p className="year-detail__body">{f.detail.body}</p>
      </div>
      <div className="year-detail__visual">
        <span className="year-detail__photos" aria-hidden="true">
          <img src={scenes.parentNewborn} alt="" loading="lazy" decoding="async" />
          <img src={scenes.thenBaby} alt="" loading="lazy" decoding="async" />
        </span>
        <span className="year-detail__halo">
          <a className="year-detail__button pressable" href={pathOf('stage1', route.locale)}>
            {f.more}
            <span className="year-detail__arrow">
              <Icon name="arrow-right" size={16} />
            </span>
          </a>
        </span>
      </div>
    </div>
  );
}

/** Chặng 1 · Năm đầu đời (28-landing-v5b-home §3): one mint frame around the bento, the parent
 *  tools, "Theo cách của bạn", the Apple Watch card and the link to the Chặng 1 page. */
export function FirstYear() {
  const { c } = useSite();
  const f = c.home.firstYear;
  return (
    <section id="nam-dau-doi" className="first-year" aria-labelledby="first-year-title">
      <div className="stage-frame">
        <div className="stage-frame__main">
          <header className="section-head section-head--center reveal">
            <Eyebrow tone="mint" className="eyebrow--on-frame">
              {f.eyebrow}
            </Eyebrow>
            <h2 id="first-year-title" className="h2 h2--flat first-year__title">
              {f.title}
            </h2>
            <p className="lead">
              <span className="only-desktop-inline">{f.lead}</span>
              <span className="only-mobile-inline">{f.leadShort}</span>
            </p>
          </header>
          <BentoGrid />
          <Utilities />
          <YourWay />
        </div>
        <div className="stage-frame__pad">
          <WatchSection />
        </div>
        <div className="stage-frame__pad">
          <FirstYearDetail />
        </div>
      </div>
    </section>
  );
}
