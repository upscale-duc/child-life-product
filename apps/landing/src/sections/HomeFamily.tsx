import { Fragment } from 'react';
import { Eyebrow, Fit, Icon, at, type IconName } from '../components/primitives';
import { useSite } from '../context';
import { staggerStyle } from '../motion';
import { HomeFace, Watch } from './Watch';

const bulletIcons: IconName[] = ['journal', 'clock', 'eye'];
const stepTints = ['bottle', 'peach', 'mint'];
// Round watch tiles (§5.2, raw colours as drawn): the first four W01 tiles.
const roundTiles = ['#3D78D9', '#D95C85', '#6661D9', '#33996B'];

/** A round Wear OS watch (Figma 742:66966), 210 × 262.5, decorative. */
function RoundWatch() {
  const { c } = useSite();
  const tiles = c.home.watch.mock.tiles;
  return (
    <span className="round-watch">
      <span className="round-watch__strap" />
      <span className="round-watch__strap round-watch__strap--bottom" />
      <span className="round-watch__button" />
      <span className="round-watch__bezel">
        <span className="round-watch__screen">
          <span className="round-watch__time">{c.home.watch.mock.time}</span>
          <span className="round-watch__baby">{c.home.watch.mock.baby}</span>
          <span className="round-watch__tiles">
            {roundTiles.map((colour, i) => (
              <span key={colour} style={{ background: colour }}>
                <span>{i === 2 ? c.homePage.wrist.round.asleep : tiles[i]!.label}</span>
                <strong>{tiles[i]!.value}</strong>
              </span>
            ))}
          </span>
        </span>
      </span>
    </span>
  );
}

/** Cả nhà cùng chăm (Figma 735:5743 / 736:65883; §5): one situation in three steps and a trust
 *  line, then "Trên cổ tay" (742:66894). Q-047 / Q-048: the watch app is not released and Wear OS
 *  is not in V1 — shipped as designed on dev for the owner's review. */
export function HomeFamily() {
  const { c } = useSite();
  const f = c.homePage.family;
  const w = c.homePage.wrist;
  return (
    <section
      id="cham-soc"
      className="home-section home-section--white"
      aria-labelledby="family-title"
    >
      <div className="container home-section__inner">
        <div className="family">
          <div className="family__copy reveal">
            <Eyebrow tone="mint">{f.eyebrow}</Eyebrow>
            <h2 id="family-title" className="home-head__title family__title">
              {f.title}
            </h2>
            <ul className="family__bullets">
              {f.bullets.map((bullet, i) => (
                <li key={bullet}>
                  <span className="lp-icon tint--mint">
                    <Icon name={bulletIcons[i]!} size={16} />
                  </span>
                  {bullet}
                </li>
              ))}
            </ul>
            <p className="family__trust">
              <Icon name="lock" size={16} />
              {f.trust}
            </p>
          </div>
          <ol className="family__steps reveal">
            {f.steps.map((step, i) => (
              <Fragment key={step.title}>
                {i > 0 && (
                  <li className="family__arrow" aria-hidden="true">
                    <Icon name="arrow-right" size={14} />
                  </li>
                )}
                <li className="family-step" style={staggerStyle(i)}>
                  <span className="family-step__head">
                    <b className={`tint--${stepTints[i]}`}>{step.initial}</b>
                    {step.meta}
                  </span>
                  <strong>{step.title}</strong>
                  <span>{step.body}</span>
                </li>
              </Fragment>
            ))}
          </ol>
        </div>
        <div id="apple-watch" className="wrist reveal">
          <div className="wrist__copy">
            <span className="wrist__chip">{w.chip}</span>
            <h3 className="wrist__title">{w.title}</h3>
            <p className="wrist__lead">{w.lead}</p>
            <ul className="wrist__platforms">
              <li className="is-ready">
                <Icon name="check" size={12} />
                {w.apple}
              </li>
              <li>
                <Icon name="clock" size={12} />
                {w.wear}
              </li>
            </ul>
          </div>
          <div className="wrist__visual" aria-hidden="true">
            <Fit w={560} h={340} mobileScale={0.5536}>
              <span className="watch-band__glow wrist__glow" style={at(93, 17)} />
              <Watch scale={1.17} style={at(44.8, 8.5)}>
                <HomeFace />
              </Watch>
              <span style={at(316.4, 48.75)}>
                <RoundWatch />
              </span>
              <span className="wrist__label" style={at(142.9, 318)}>
                {w.apple}
              </span>
              <span className="wrist__label" style={at(391.4, 318)}>
                {w.wearLabel}
              </span>
            </Fit>
          </div>
        </div>
      </div>
    </section>
  );
}
