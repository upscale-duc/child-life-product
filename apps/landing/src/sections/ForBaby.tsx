import { type Tint } from '../components/kit';
import { Icon, photos, type IconName } from '../components/primitives';
import { useSite } from '../context';

/* "Hôm nay của bé": personalised cards with the reason each appears (Figma 699:5798, 700:5832).
   The app's screen is apps/mobile/lib/features/today/today_for_baby.dart. */

const cardLook: { icon: IconName; tint: Tint }[] = [
  { icon: 'sleep', tint: 'sleep' },
  { icon: 'bookmark', tint: 'sun' },
  { icon: 'heart', tint: 'peach' },
];

/** One "Hôm nay của bé" card: title, body, "Vì sao bạn thấy thẻ này" and its actions. */
function TodayCard({ index }: { index: number }) {
  const { c } = useSite();
  const m = c.forBaby.mock;
  const card = m.cards[index]!;
  const look = cardLook[index]!;
  return (
    <span className="today-card">
      <span className="today-card__head">
        <span className={`lp-icon tint--${look.tint}`}>
          <Icon name={look.icon} size={16} className="ink--ink" />
        </span>
        <strong>{card.title}</strong>
      </span>
      <span className="today-card__body">
        {index === 2 && (
          <span className="today-card__photo">
            <img src={photos.peach} alt="" loading="lazy" decoding="async" />
          </span>
        )}
        {card.body}
      </span>
      <span className={`today-card__why tint--${look.tint}`}>
        <span className="today-card__why-label">
          <Icon name="eye" size={11} />
          {m.why}
        </span>
        <span className="today-card__why-text">{card.why}</span>
      </span>
      <span className="today-card__actions">
        <span className="today-card__button">
          {card.action}
          <Icon name="arrow-right" size={16} />
        </span>
        <Icon name="heart" size={14} />
        <Icon name="close" size={14} />
      </span>
    </span>
  );
}

/** "Mock · Hôm nay của bé" (699:5798), also on the V8 home (34 §6). */
export function TodayMock() {
  const { c } = useSite();
  const m = c.forBaby.mock;
  return (
    <div className="today-mock">
      <span className="today-mock__head">
        <span className="today-mock__avatar">{m.initial}</span>
        <span className="today-mock__title">
          <strong>{m.name}</strong>
          <span>{m.date}</span>
        </span>
        <span className="today-mock__sample">
          <Icon name="eye" size={11} />
          {m.sample}
        </span>
      </span>
      {m.cards.map((card, i) => (
        <TodayCard key={card.title} index={i} />
      ))}
      <span className="today-mock__foot">
        <Icon name="sliders" size={12} />
        {m.footnote}
      </span>
    </div>
  );
}
