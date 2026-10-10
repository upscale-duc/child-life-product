import moon from '../assets/figma/nightcare-moon.svg';
import { LiveActivity, LockCircular, WidgetSmall } from '../components/mock';
import { Eyebrow, Fit, Icon, at } from '../components/primitives';
import { useSite } from '../context';
import { staggerStyle } from '../motion';

// Starfield 232:862–232:876 (cx, cy, r, opacity); drawn inline so the stars can twinkle.
const stars: [number, number, number, number][] = [
  [21, 21, 1, 0.5],
  [118.5, 74.5, 1.5, 0.6],
  [216, 128, 2, 0.7],
  [312, 180, 1, 0.8],
  [409.5, 33.5, 1.5, 0.5],
  [507, 87, 2, 0.6],
  [43, 139, 1, 0.7],
  [140.5, 192.5, 1.5, 0.8],
  [238, 46, 2, 0.5],
  [334, 98, 1, 0.6],
  [431.5, 151.5, 1.5, 0.7],
  [529, 205, 2, 0.8],
  [65, 57, 1, 0.5],
  [162.5, 110.5, 1.5, 0.6],
];

/** Night care (spec §7). The card renders in the Night care palette (data-palette). */
export function Night() {
  const { c } = useSite();
  const n = c.night;
  return (
    <section id="ban-dem" className="section night container" aria-labelledby="night-title">
      <div className="night__card reveal" data-palette="night-care">
        <div className="night__copy">
          <header className="section-head">
            <Eyebrow tone="night">{n.eyebrow}</Eyebrow>
            <h2 id="night-title" className="h2 night__title">
              {n.title}
            </h2>
            <p className="lead night__lead">{n.lead}</p>
          </header>
          <ul className="night__checks">
            {n.checks.map((check, i) => (
              <li key={check} className="reveal" style={staggerStyle(i + 2)}>
                <Icon name="check" size={18} />
                {check}
              </li>
            ))}
          </ul>
        </div>
        <div className="night__visual">
          <Fit w={600} h={560} mobileScale={0.4917}>
            <svg
              className="starfield"
              width="600"
              height="560"
              viewBox="0 0 600 560"
              aria-hidden="true"
            >
              <defs>
                <radialGradient
                  id="night-glow"
                  cx="0"
                  cy="0"
                  r="1"
                  gradientUnits="userSpaceOnUse"
                  gradientTransform="translate(310 280) scale(260)"
                >
                  <stop stopColor="#6673CC" stopOpacity="0.4" />
                  <stop offset="1" stopColor="#6673CC" stopOpacity="0" />
                </radialGradient>
              </defs>
              <circle cx="310" cy="280" r="260" fill="url(#night-glow)" />
              {stars.map(([cx, cy, r, opacity], i) => (
                <circle
                  key={i}
                  className="star"
                  cx={cx}
                  cy={cy}
                  r={r}
                  fill="white"
                  fillOpacity={opacity}
                  style={{ ['--i' as string]: i % 5 }}
                />
              ))}
            </svg>
            <img
              className="night__moon"
              src={moon}
              alt=""
              width={123.2}
              height={123.2}
              style={at(420, 40)}
              loading="lazy"
            />
            <div className="pop" style={at(40, 170)}>
              <LiveActivity scale={1.15} radius={24} style={{ transformOrigin: '0 0' }} />
            </div>
            <WidgetSmall variant="sleep" style={at(40, 380, { ['--i' as string]: 1 })} />
            <WidgetSmall variant="bottle" style={at(226, 380, { ['--i' as string]: 2 })} />
            <div style={at(410, 290, { transform: 'scale(1.3)', transformOrigin: '0 0' })}>
              <LockCircular
                icon="sleep"
                value={c.mock.circular.sleep}
                progress={0.62}
                radius={29.2}
              />
            </div>
            <div style={at(410, 400, { transform: 'scale(1.3)', transformOrigin: '0 0' })}>
              <LockCircular
                icon="feed"
                value={c.mock.circular.feed}
                progress={0.38}
                radius={29.2}
              />
            </div>
          </Fit>
        </div>
      </div>
    </section>
  );
}
