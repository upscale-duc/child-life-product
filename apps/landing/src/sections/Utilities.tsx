import firstAidArt from '../assets/figma/first-aid-bandage.webp';
import { IconBox, type Tint } from '../components/kit';
import { Icon, type IconName } from '../components/primitives';
import { useSite } from '../context';
import { staggerStyle } from '../motion';

const cards: { tint: Tint; icon: IconName }[] = [
  { tint: 'peach', icon: 'alert' },
  { tint: 'growth', icon: 'grid' },
];

/** Tiện ích cho ba mẹ (28-landing-v5b-home §3.3): first aid and spending cards inside the
 *  Chặng 1 frame. The first-aid art is the app's own "Băng bó cơ bản" illustration. */
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
  ];
  return (
    <div id="tien-ich" className="utilities">
      <div className="utilities__head reveal">
        <h3>{u.title}</h3>
        <p>{u.lead}</p>
      </div>
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
    </div>
  );
}
