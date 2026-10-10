import { StoreBadges } from '../components/StoreBadges';
import { useSite } from '../context';

/** CTA band (spec §9). Target of the nav download buttons (#tai-app). */
export function Cta() {
  const { c } = useSite();
  return (
    <section id="tai-app" className="cta container" aria-labelledby="cta-title">
      <div className="cta__card reveal">
        <span className="cta__circle" aria-hidden="true" />
        <div className="cta__copy">
          <h2 id="cta-title" className="cta__title">
            <span>{c.cta.title[0]}</span> <span>{c.cta.title[1]}</span>
          </h2>
          <p className="cta__sub">{c.cta.sub}</p>
        </div>
        <div className="cta__download">
          <StoreBadges variant="light" />
          <p className="cta__caption">{c.cta.caption}</p>
        </div>
      </div>
    </section>
  );
}
