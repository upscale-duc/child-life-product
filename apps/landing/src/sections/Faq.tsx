import { Icon } from '../components/primitives';
import type { FaqItem } from '../content/types';
import { useSite } from '../context';
import { staggerStyle } from '../motion';

/** Hỏi đáp (spec §10): native <details> so answers are in the HTML for search engines;
 *  opening animates its height where the browser supports ::details-content. */
export function Faq({ items }: { items?: FaqItem[] }) {
  const { c } = useSite();
  const f = c.faq;
  return (
    <section id="hoi-dap" className="faq container" aria-labelledby="faq-title">
      <header className="faq__head reveal">
        <h2 id="faq-title" className="faq__title">
          {f.title}
        </h2>
        <p className="faq__sub">
          {f.sub[0]}
          <a href={`mailto:${c.footer.email}`}>{f.sub[1]}</a>
          {f.sub[2]}
        </p>
      </header>
      <div className="faq__list">
        {(items ?? f.items).map((item, i) => (
          <details
            key={item.q}
            className="faq-item reveal"
            open={item.open}
            style={staggerStyle(i)}
          >
            <summary>
              <h3>{item.q}</h3>
              <span className="faq-item__icons" aria-hidden="true">
                <Icon name="plus" size={20} className="faq-item__plus" />
                <Icon name="chevron-down" size={20} className="faq-item__chevron" />
              </span>
            </summary>
            <p className="faq-item__answer">{item.a}</p>
          </details>
        ))}
      </div>
    </section>
  );
}
