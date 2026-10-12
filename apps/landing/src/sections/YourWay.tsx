import { CompactBullets } from '../components/Bullets';
import { Chip, Toggle } from '../components/kit';
import { Eyebrow, Fit, Icon, at } from '../components/primitives';
import { useSite } from '../context';

function CustomizeCard() {
  const { c } = useSite();
  const m = c.home.yourWay.mock;
  return (
    <div className="customize-card">
      <strong className="customize-card__title">{m.title}</strong>
      {m.rows.map((row, i) => (
        <span key={row.title} className="customize-card__row">
          <span className="customize-card__handle" />
          <span className="customize-card__text">
            <strong>{row.title}</strong>
            <span>{row.body}</span>
          </span>
          <Toggle scale={0.85} off={i === 2} />
        </span>
      ))}
      <span className="chip-row">
        {m.chips.map((chip) => (
          <Chip key={chip} tint="mint" icon="check" className="chip--5-10">
            {chip}
          </Chip>
        ))}
      </span>
    </div>
  );
}

function NightChip() {
  const { c } = useSite();
  return (
    <span className="night-chip">
      <Icon name="sleep" size={14} />
      {c.home.yourWay.mock.night}
    </span>
  );
}

/** Theo cách của bạn (22-landing-v4-home §5): copy left, "Tuỳ chỉnh Hôm nay" mock right; on
 *  mobile the panel is re-composed in flow between the head and the bullets. */
export function YourWay() {
  const { c } = useSite();
  const y = c.home.yourWay;
  return (
    <section
      id="theo-cach-cua-ban"
      className="section feature container split"
      aria-labelledby="your-way-title"
    >
      <div className="split__copy">
        <header className="section-head reveal">
          <Eyebrow tone="sun-ink">{y.eyebrow}</Eyebrow>
          <h2 id="your-way-title" className="h2 h2--flat feature__title">
            {y.title}
          </h2>
          <p className="lead split__lead">{y.lead}</p>
        </header>
        <div
          className="flow-panel flow-panel--stretch tint--sun only-mobile reveal"
          aria-hidden="true"
        >
          <CustomizeCard />
          <NightChip />
        </div>
        <CompactBullets
          items={[
            { icon: 'sliders', tint: 'sun', ...y.bullets[0] },
            { icon: 'sleep', tint: 'sleep', ...y.bullets[1] },
            { icon: 'grid', tint: 'growth', ...y.bullets[2] },
          ]}
        />
      </div>
      <div className="split__visual split__visual--600 only-desktop reveal">
        <Fit w={600} h={460} mobileScale={0.5583}>
          <div className="panel tint--sun" />
          <div className="pop" style={at(40, 40, { width: 420 })}>
            <CustomizeCard />
          </div>
          <div className="pop" style={at(40, 330, { ['--i' as string]: 1 })}>
            <NightChip />
          </div>
        </Fit>
      </div>
    </section>
  );
}
