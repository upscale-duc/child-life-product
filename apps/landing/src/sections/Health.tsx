import { CompactBullets } from '../components/Bullets';
import { Chip } from '../components/kit';
import { Eyebrow, Fit, Icon, at } from '../components/primitives';
import { useSite } from '../context';

// Vaccine grid marks per row (22-landing-v4-home §3.1): d = given, n = next due, . = not yet.
const marks = ['d.....', 'd.....', '.ddn..', '.dd...', '.dd...', '.....n'];

/** "Lịch tiêm chủng" mock: `columns` / `rows` limit the grid (mobile shows 4 × 5). */
function VaccineCard({ columns = 6, rows = 6 }: { columns?: number; rows?: number }) {
  const { c } = useSite();
  const m = c.home.health.mock;
  return (
    <div className="vaccine-card" style={{ ['--cols' as string]: columns }}>
      <strong className="vaccine-card__title">{m.title}</strong>
      <div className="vaccine-grid">
        <span />
        {m.columns.slice(0, columns).map((col) => (
          <span key={col} className="vaccine-grid__head">
            {col}
          </span>
        ))}
        {m.rows.slice(0, rows).map((row, r) => (
          <div key={row} className="vaccine-grid__row">
            <span className="vaccine-grid__name">{row}</span>
            {[...marks[r]!.slice(0, columns)].map((mark, i) => (
              <span key={i} className="vaccine-grid__cell">
                {mark === 'd' ? (
                  <span className="vaccine-mark is-done">
                    <Icon name="check" size={12} />
                  </span>
                ) : (
                  <span className={mark === 'n' ? 'vaccine-mark is-next' : 'vaccine-mark'} />
                )}
              </span>
            ))}
          </div>
        ))}
      </div>
      <span className="vaccine-card__next">
        <Icon name="clock" size={16} />
        {m.next}
      </span>
    </div>
  );
}

function GrowthCard() {
  const { c } = useSite();
  const m = c.home.health.mock;
  return (
    <div className="growth-card">
      <span className="growth-card__label">{m.growthLabel}</span>
      <strong>{m.growthValue}</strong>
      <Chip tint="mint" size="sm">
        {m.growthChip}
      </Chip>
    </div>
  );
}

/** Sức khoẻ (22-landing-v4-home §3): vaccine and growth mocks left, copy right; on mobile the
 *  panel is re-composed in flow (a 4 × 5 grid) between the head and the bullets. */
export function Health() {
  const { c } = useSite();
  const h = c.home.health;
  return (
    <section
      id="suc-khoe"
      className="section feature container split split--visual-first"
      aria-labelledby="health-title"
    >
      <div className="split__copy">
        <header className="section-head reveal">
          <Eyebrow tone="mint">{h.eyebrow}</Eyebrow>
          <h2 id="health-title" className="h2 h2--flat feature__title">
            {h.title}
          </h2>
          <p className="lead split__lead">{h.lead}</p>
        </header>
        <div
          className="flow-panel flow-panel--health tint--mint only-mobile reveal"
          aria-hidden="true"
        >
          <VaccineCard columns={4} rows={5} />
          <GrowthCard />
        </div>
        <CompactBullets
          items={[
            { icon: 'check', tint: 'mint', ...h.bullets[0] },
            { icon: 'ruler', tint: 'growth', ...h.bullets[1] },
            { icon: 'feed', tint: 'bottle', ...h.bullets[2] },
          ]}
        />
        <p className="feature__footnote reveal">{h.footnote}</p>
      </div>
      <div className="split__visual split__visual--600 only-desktop reveal">
        <Fit w={600} h={520} mobileScale={0.5583}>
          <div className="panel tint--mint" />
          <div className="pop" style={at(40, 40, { width: 440 })}>
            <VaccineCard />
          </div>
          <div className="pop" style={at(330, 370, { width: 240, ['--i' as string]: 1 })}>
            <GrowthCard />
          </div>
        </Fit>
      </div>
    </section>
  );
}
