import { LumiMascot, type Tint } from '../components/kit';
import { Icon, photos, type IconName } from '../components/primitives';
import { useSite } from '../context';
import { staggerStyle } from '../motion';
import { pathOf } from '../routes';

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

const valueLook: { icon: IconName; tint: Tint }[] = [
  { icon: 'journal', tint: 'sleep' },
  { icon: 'bookmark', tint: 'sun' },
  { icon: 'heart', tint: 'peach' },
];

/** Dành cho con (home, inside the Chặng 1 frame after Lumi). */
export function ForBabyBlock() {
  const { c, route } = useSite();
  const f = c.forBaby;
  const m = f.mock;
  return (
    <div id="danh-cho-con" className="for-baby">
      <div className="for-baby__copy reveal">
        <span className="eyebrow eyebrow--peach-ink">{f.eyebrow}</span>
        <h3 className="for-baby__title">
          <span>{f.title[0]}</span> <span>{f.title[1]}</span>
        </h3>
        <p className="for-baby__lead">{f.lead}</p>
        <ul className="for-baby__values">
          {f.values.map((value, i) => (
            <li key={value.title}>
              <span className={`lp-icon tint--${valueLook[i]!.tint}`}>
                <Icon name={valueLook[i]!.icon} size={16} className="ink--ink" />
              </span>
              <span>
                <strong>{value.title}</strong>
                <span>{value.body}</span>
              </span>
            </li>
          ))}
        </ul>
        <a
          className="lumi-button pressable"
          href={`${pathOf('lumi', route.locale)}#mot-ngay-cho-con`}
        >
          {f.cta}
          <Icon name="arrow-right" size={16} />
        </a>
        <p className="for-baby__control">
          <Icon name="check" size={14} />
          {f.control}
        </p>
      </div>
      <div className="for-baby__visual reveal" aria-hidden="true">
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
      </div>
    </div>
  );
}

const controlIcons: IconName[] = ['sliders', 'close', 'journal', 'heart'];

/** Một ngày dành riêng cho con (Lumi page, after "Một ngày cùng Lumi"): Lumi vs Hôm nay của bé,
 *  three worked examples (logged → card → you decide) and the controls. */
export function ForBabyDetail() {
  const { c } = useSite();
  const d = c.forBaby.detail;
  return (
    <section id="mot-ngay-cho-con" className="for-baby-detail" aria-labelledby="for-baby-title">
      <div className="container for-baby-detail__inner">
        <header className="section-head lp-head-left reveal">
          <span className="eyebrow eyebrow--peach-ink">{d.eyebrow}</span>
          <h2 id="for-baby-title" className="h2 h2--flat lp-h2 lp-h2--42">
            <span>{d.title[0]}</span> <span>{d.title[1]}</span>
          </h2>
          <p className="lead">{d.lead}</p>
        </header>
        <ul className="for-baby-modes reveal">
          {d.modes.map((mode, i) => (
            <li key={mode.name}>
              <span className="for-baby-modes__head">
                {i === 0 ? (
                  <LumiMascot size={40} />
                ) : (
                  <span className="lp-icon tint--peach">
                    <Icon name="today" size={20} className="ink--ink" />
                  </span>
                )}
                <span>
                  <strong>{mode.name}</strong>
                  <span>{mode.sub}</span>
                </span>
              </span>
              <span className="for-baby-modes__example">
                <Icon name={i === 0 ? 'spark' : 'eye'} size={14} />
                {mode.example}
              </span>
            </li>
          ))}
        </ul>
        <p className="for-baby-detail__note">{d.modesNote}</p>
        <ol className="for-baby-scenarios lp-rail">
          {d.scenarios.map((scenario, i) => (
            <li key={i} className="reveal" style={staggerStyle(i)}>
              <span className="for-baby-step">
                <b>1</b>
                {d.steps[0]}
              </span>
              <span className="for-baby-chips">
                {scenario.logged.map((chip) => (
                  <span key={chip} className="chat-source">
                    <Icon name="journal" size={11} />
                    {chip}
                  </span>
                ))}
              </span>
              <span className="for-baby-step">
                <b>2</b>
                {d.steps[1]}
              </span>
              <span aria-hidden="true">
                <TodayCard index={i} />
              </span>
              <span className="for-baby-step">
                <b>3</b>
                {d.steps[2]}
              </span>
              <span className="for-baby-chips">
                {scenario.decide.map((chip, k) => (
                  <span key={chip} className={k === 0 ? 'for-baby-act is-primary' : 'for-baby-act'}>
                    {chip}
                  </span>
                ))}
              </span>
            </li>
          ))}
        </ol>
        <div className="for-baby-control reveal">
          <strong>{d.controlTitle}</strong>
          <ul>
            {d.controls.map((control, i) => (
              <li key={control}>
                <Icon name={controlIcons[i]!} size={13} />
                {control}
              </li>
            ))}
          </ul>
        </div>
        <p className="for-baby-detail__note for-baby-detail__note--eye">
          <Icon name="eye" size={13} />
          {d.note}
        </p>
      </div>
    </section>
  );
}
