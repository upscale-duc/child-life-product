import { Icon } from '../components/primitives';
import { useSite } from '../context';

/** Privacy / Terms. Placeholder until the owner supplies the legal text (plan S14). */
export function Legal({ page }: { page: 'privacy' | 'terms' }) {
  const { c, homePath } = useSite();
  const legal = c.legal[page];
  return (
    <article className="legal container">
      <p className="legal__status enter">{legal.status}</p>
      <h1 className="legal__title enter" style={{ ['--i' as string]: 1 }}>
        {legal.title}
      </h1>
      <div className="legal__body enter" style={{ ['--i' as string]: 2 }}>
        {legal.paragraphs.map((p) => (
          <p key={p}>{p}</p>
        ))}
        <p>
          {legal.contactLead} <a href={`mailto:${c.footer.email}`}>{c.footer.email}</a>
        </p>
      </div>
      <a className="legal__back pressable enter" href={homePath} style={{ ['--i' as string]: 3 }}>
        <Icon name="chevron-right" size={18} className="legal__back-icon" />
        {c.legal.back}
      </a>
    </article>
  );
}
