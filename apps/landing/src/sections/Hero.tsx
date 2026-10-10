import { Phone, AlbumScreen, TodayScreen } from '../components/phones';
import { Eyebrow, Fit, Photo, at } from '../components/primitives';
import { StoreBadges } from '../components/StoreBadges';
import { useSite } from '../context';

/** Hero (spec §2). The headline and lead paint immediately (they are the LCP); the eyebrow,
 *  badges and the visual enter on load in CSS, so nothing waits for JS. */
export function Hero() {
  const { c } = useSite();
  const h = c.hero;
  const avatarFills = [
    'var(--peach-soft)',
    'var(--sunshine-soft)',
    'var(--mint-soft)',
    'var(--surface-2)',
  ];
  return (
    <section id="gioi-thieu" className="hero container" aria-labelledby="hero-title">
      <div className="hero__copy">
        <Eyebrow tone="mint" className="eyebrow--hero enter">
          <span aria-hidden="true">{'●  '}</span>
          {h.eyebrow}
        </Eyebrow>
        <h1 id="hero-title" className="display">
          <span>{h.title[0]}</span> <span className="display__accent">{h.title[1]}</span>{' '}
          <span className="display__accent">{h.title[2]}</span>
        </h1>
        <p className="hero__lead">{h.lead}</p>
        <div className="hero__download enter" style={{ ['--i' as string]: 1 }}>
          <StoreBadges variant="dark" />
          <p className="hero__caption">{h.caption}</p>
        </div>
        <div className="hero__proof enter" style={{ ['--i' as string]: 2 }}>
          <span className="hero__avatars" aria-hidden="true">
            {h.proofInitials.map((initial, i) => (
              <span key={i} style={{ background: avatarFills[i], zIndex: i }}>
                {initial}
              </span>
            ))}
          </span>
          <span>{h.proof}</span>
        </div>
      </div>
      <div className="hero__visual">
        <Fit w={600} h={640} mobileScale={0.5583}>
          <span className="hero__circle" style={at(30, 40)} />
          <div className="hero__phone hero__phone--a" style={at(49.2, 69.95)}>
            <Phone width={270} height={560} radius={43.2} screenRadius={37.8}>
              <TodayScreen />
            </Phone>
          </div>
          <div className="hero__phone hero__phone--b" style={at(264.1, 27.2)}>
            <Phone width={290} height={600} radius={46.4} screenRadius={40.6}>
              <AlbumScreen />
            </Phone>
          </div>
          {h.chips.map((chip, i) => (
            <div
              key={chip.title}
              className={`hero__chip hero__chip--${i + 1}`}
              style={i === 0 ? at(-40, 470) : at(300, 560)}
            >
              <div className="float-chip">
                <Photo tone={i === 0 ? 'peach' : 'mint'} className="float-chip__thumb" eager />
                <span className="float-chip__text">
                  <span className="float-chip__title">{chip.title}</span>
                  <span className="float-chip__sub">{chip.sub}</span>
                </span>
              </div>
            </div>
          ))}
        </Fit>
      </div>
    </section>
  );
}
