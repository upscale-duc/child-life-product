import { Bullets } from '../components/Bullets';
import { CareTile, DayRhythm } from '../components/mock';
import { Eyebrow, Fit, Icon, at } from '../components/primitives';
import { useSite } from '../context';

/** Chăm sóc mỗi ngày (spec §4): panel left on desktop, below the copy on mobile. */
export function Care() {
  const { c } = useSite();
  const k = c.care;
  return (
    <section
      id="cham-soc"
      className="section care container split split--visual-first"
      aria-labelledby="care-title"
    >
      <div className="split__copy">
        <header className="section-head reveal">
          <Eyebrow tone="mint">{k.eyebrow}</Eyebrow>
          <h2 id="care-title" className="h2 care__title">
            {k.title}
          </h2>
          <p className="lead split__lead">{k.lead}</p>
        </header>
        <Bullets
          items={[
            { icon: 'plus', tone: 'bottle', ...k.bullets[0] },
            { icon: 'clock', tone: 'sleep', ...k.bullets[1] },
            { icon: 'journal', tone: 'diaper', ...k.bullets[2] },
          ]}
        />
      </div>
      <div className="split__visual reveal">
        <Fit w={640} h={600} mobileScale={0.5234}>
          <div className="panel panel--mint" />
          <div
            style={at(80, 72, { transform: 'scale(1.2)', transformOrigin: '0 0' })}
            className="pop"
          >
            <CareTile kind="bottle" text={k.bottle} width={166} />
          </div>
          <div
            style={at(295.2, 72, {
              transform: 'scale(1.2)',
              transformOrigin: '0 0',
              ['--i' as string]: 1,
            })}
            className="pop"
          >
            <CareTile kind="sleep" text={k.sleep} width={166} live />
          </div>
          <span className="panel-chip pop" style={at(335.2, 44, { ['--i' as string]: 3 })}>
            <Icon name="clock" size={16} className="care-ink--sleep" />
            {k.chip}
          </span>
          <div
            style={at(83.33, 262.6, {
              transform: 'scale(1.38)',
              transformOrigin: '0 0',
              ['--i' as string]: 2,
            })}
            className="pop"
          >
            <DayRhythm style={{ width: 343 }} />
          </div>
        </Fit>
      </div>
    </section>
  );
}
