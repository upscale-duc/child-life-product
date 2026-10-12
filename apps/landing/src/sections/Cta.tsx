import { StoreBadges } from '../components/StoreBadges';
import { useSite } from '../context';

/** CTA band (spec §9). Target of the nav download buttons (#tai-app). The v3 home and Chặng 2–4
 *  pass the journey title and use the compact 40 px outer padding (14-landing-v3-home §6). */
export function Cta({ title, compact }: { title?: [string, string]; compact?: boolean }) {
  const { c } = useSite();
  const [first, second] = title ?? c.cta.title;
  return (
    <section
      id="tai-app"
      className={compact ? 'cta cta--compact container' : 'cta container'}
      aria-labelledby="cta-title"
    >
      <div className="cta__card reveal">
        <span className="cta__circle" aria-hidden="true" />
        <div className="cta__copy">
          <h2 id="cta-title" className="cta__title">
            <span>{first}</span> <span>{second}</span>
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
