import { Chip, Toggle } from '../components/kit';
import { Eyebrow, Fit, Icon, Photo } from '../components/primitives';
import { useSite } from '../context';
import { staggerStyle } from '../motion';

// Wonder Week strip: current age week 3, this leap 4–5, later leaps 8–9 and 11–12.
const weekState = (week: number) =>
  week === 3
    ? 'now'
    : week === 4 || week === 5
      ? 'leap'
      : [8, 9, 11, 12].includes(week)
        ? 'later'
        : '';

/** Hiểu con (12-landing-v3 §3): three visual + text columns; each visual is a fixed 400 × 428
 *  composition, scaled on smaller screens (mobile = × 0.8375). */
export function Understand() {
  const { c } = useSite();
  const u = c.understand;
  const visuals = [
    <div key="age" className="know-visual tint--sun">
      <div className="know-card">
        <Photo tone="sky" className="know-card__hero" />
        <span className="chip-row">
          <Chip tint="sun">{u.age.chips[0]}</Chip>
          <Chip tint="plain">{u.age.chips[1]}</Chip>
        </span>
        <strong className="know-card__title know-card__title--sm">{u.age.title}</strong>
        {u.age.points.map((point) => (
          <span key={point} className="know-card__point">
            <Icon name="heart" size={15} className="ink--bottle" />
            {point}
          </span>
        ))}
        <span className="know-card__link">
          {u.age.footer}
          <Icon name="arrow-right" size={16} />
        </span>
      </div>
    </div>,
    <div key="wonder" className="know-visual tint--sleep">
      <div className="know-card">
        <span className="chip-row">
          <Chip tint="sleep">{u.wonder.badge}</Chip>
          <span className="spacer" />
          <Chip tint="accent">{u.wonder.countdown}</Chip>
        </span>
        <strong className="know-card__title ink--sleep">{u.wonder.title}</strong>
        <span className="know-card__meta">{u.wonder.dates}</span>
        <span className="weeks">
          {Array.from({ length: 12 }, (_, i) => (
            <span key={i} className={`weeks__cell ${weekState(i + 1)}`}>
              <span className="weeks__bar" />
              {i + 1}
            </span>
          ))}
        </span>
        <span className="know-card__label">{u.wonder.signsLabel}</span>
        <span className="chip-row">
          {u.wonder.signs.map((sign) => (
            <Chip key={sign} tint="plain" size="sm">
              {sign}
            </Chip>
          ))}
        </span>
        <span className="know-card__label">{u.wonder.learningLabel}</span>
        <span className="know-card__point">
          <Icon name="spark" size={15} className="ink--sleep" />
          {u.wonder.learning}
        </span>
      </div>
      <div className="know-row">
        <Icon name="clock" size={16} className="ink--sleep" />
        <strong>{u.wonder.reminder}</strong>
        <span className="spacer" />
        <Toggle scale={0.75} />
      </div>
    </div>,
    <div key="milestone" className="know-visual tint--peach">
      <div className="know-card">
        <span className="know-card__photos">
          <Photo tone="peach" />
          <Photo tone="sun" />
        </span>
        <span className="chip-row">
          <Chip tint="mint" icon="check">
            {u.milestone.chips[0]}
          </Chip>
          <Chip tint="peach">{u.milestone.chips[1]}</Chip>
        </span>
        <strong className="know-card__title">{u.milestone.title}</strong>
        <span className="know-card__meta know-card__meta--long">{u.milestone.note}</span>
      </div>
      <div className="know-row">
        <Icon name="memories" size={16} className="ink--bottle" />
        <strong>{u.milestone.saved}</strong>
        <span className="spacer" />
        <Icon name="chevron-right" size={14} className="know-row__chevron" />
      </div>
    </div>,
  ];
  return (
    <section id="hieu-con" className="section know container" aria-labelledby="know-title">
      <header className="section-head section-head--center reveal">
        <Eyebrow tone="sleep">{u.eyebrow}</Eyebrow>
        <h2 id="know-title" className="h2">
          {u.title}
        </h2>
        <p className="lead">
          <span className="only-desktop-inline">{u.lead}</span>
          <span className="only-mobile-inline">{u.leadShort}</span>
        </p>
      </header>
      <div className="know__cols">
        {u.columns.map((column, i) => (
          <article key={column.title} className="know__col reveal" style={staggerStyle(i)}>
            <Fit w={400} h={428} mobileScale={0.8375}>
              {visuals[i]}
            </Fit>
            <div className="know__col-text">
              <h3 className="know__col-title">{column.title}</h3>
              <p className="know__col-body">{column.body}</p>
            </div>
          </article>
        ))}
      </div>
      <p className="know__note reveal">
        <Icon name="heart" size={16} className="ink--bottle" />
        <span className="only-desktop-inline">{u.note}</span>
        <span className="only-mobile-inline">{u.noteShort}</span>
      </p>
    </section>
  );
}
