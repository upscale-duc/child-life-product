import { Eyebrow, Icon } from '../components/primitives';
import { useSite } from '../context';
import { staggerStyle } from '../motion';

const avatarTone = ['mint', 'sleep', 'coral'] as const;

/** Quyền xem / "Riêng tư" (spec §8): three role cards and two privacy notes. */
export function Roles() {
  const { c } = useSite();
  const r = c.roles;
  return (
    <section id="rieng-tu" className="section roles container" aria-labelledby="roles-title">
      <header className="section-head section-head--center roles__head reveal">
        <Eyebrow tone="coral">{r.eyebrow}</Eyebrow>
        <h2 id="roles-title" className="h2">
          {r.title}
        </h2>
        <p className="lead">{r.lead}</p>
      </header>
      <div className="role-cards">
        {r.cards.map((card, i) => (
          <article key={card.role} className="role-card reveal" style={staggerStyle(i)}>
            <div className="role-card__head">
              <span
                className={`role-card__avatar role-card__avatar--${avatarTone[i]}`}
                aria-hidden="true"
              >
                {card.initial}
              </span>
              <span className="role-card__who">
                <h3>{card.role}</h3>
                <span>{card.description}</span>
              </span>
            </div>
            <ul className="role-card__perms">
              {card.permissions.map((perm) => (
                <li key={perm.title} className={perm.allowed ? 'is-allowed' : 'is-denied'}>
                  <Icon name={perm.allowed ? 'check' : 'lock'} size={18} />
                  <span className="role-card__perm">
                    <strong>
                      <span className="sr-only">{perm.allowed ? r.allowed : r.notAllowed}: </span>
                      {perm.title}
                    </strong>
                    <span>{perm.sub}</span>
                  </span>
                </li>
              ))}
            </ul>
          </article>
        ))}
      </div>
      <div className="notes">
        {r.notes.map((note, i) => (
          <p key={note} className="note reveal" style={staggerStyle(i)}>
            <Icon name={i === 0 ? 'lock' : 'eye'} size={20} />
            <span>{note}</span>
          </p>
        ))}
      </div>
    </section>
  );
}
