import firstAidArt from '../assets/figma/first-aid-bandage.webp';
import { IconBox, type Tint } from '../components/kit';
import { Eyebrow, Icon, type IconName } from '../components/primitives';
import { useSite } from '../context';
import { staggerStyle } from '../motion';

const cards: { tint: Tint; icon: IconName }[] = [
  { tint: 'peach', icon: 'alert' },
  { tint: 'growth', icon: 'grid' },
  { tint: 'mint', icon: 'family' },
];

/** Tiện ích cho ba mẹ (22-landing-v4-home §4): first aid, spending and family cards. The
 *  first-aid art is the app's own "Băng bó cơ bản" illustration. */
export function Utilities() {
  const { c } = useSite();
  const u = c.home.utilities;
  const s = u.spending;
  const visuals = [
    <img
      key="aid"
      className="utility-card__art"
      src={firstAidArt}
      alt=""
      width={340}
      height={200}
      loading="lazy"
      decoding="async"
    />,
    <div key="spend" className="spend-card" aria-hidden="true">
      <span className="spend-card__head">
        <span className="spend-card__icon">
          <Icon name="cake" size={16} />
        </span>
        {s.header}
      </span>
      <strong className="spend-card__total">{s.total}</strong>
      <span className="spend-card__bar">
        <span style={{ flex: 2320 }} />
        <span style={{ flex: 1895 }} />
      </span>
      <span className="spend-card__legend">
        {s.split.map((part) => (
          <span key={part.label}>
            <i />
            {part.label} <b>{part.amount}</b>
          </span>
        ))}
      </span>
      <span className="spend-card__foot">
        <span className="spend-card__avatars">
          {s.initials.map((initial, i) => (
            <span key={i}>{initial}</span>
          ))}
        </span>
        {s.together}
      </span>
    </div>,
    <ul key="members" className="member-list" aria-hidden="true">
      {u.members.map((member) => (
        <li key={member.name}>
          <span className="member-list__avatar">{member.initial}</span>
          <strong>{member.name}</strong>
          <span>{member.role}</span>
        </li>
      ))}
    </ul>,
  ];
  return (
    <section
      id="tien-ich"
      className="section utilities container"
      aria-labelledby="utilities-title"
    >
      <header className="section-head section-head--center reveal">
        <Eyebrow tone="mint">{u.eyebrow}</Eyebrow>
        <h2 id="utilities-title" className="h2 h2--flat utilities__title">
          <span>{u.title[0]}</span> <span>{u.title[1]}</span>
        </h2>
        <p className="lead">{u.lead}</p>
      </header>
      <ul className="utilities__cards">
        {u.cards.map((card, i) => (
          <li
            key={card.title}
            className={`utility-card tint--${cards[i]!.tint} reveal`}
            style={staggerStyle(i)}
          >
            <IconBox tint="white" icon={cards[i]!.icon} size={20} className="utility-card__icon" />
            <h3>{card.title}</h3>
            <p>{card.body}</p>
            <div className="utility-card__visual">{visuals[i]}</div>
          </li>
        ))}
      </ul>
    </section>
  );
}
