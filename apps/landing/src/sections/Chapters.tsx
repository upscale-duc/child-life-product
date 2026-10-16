import art1 from '../assets/figma/journey-art-stage1.svg';
import art2 from '../assets/figma/journey-art-stage2.svg';
import art3 from '../assets/figma/journey-art-stage3.svg';
import art4 from '../assets/figma/journey-art-stage4.svg';
import { Chip, type Tint } from '../components/kit';
import { Eyebrow, Icon, Photo, type IconName } from '../components/primitives';
import { useSite } from '../context';
import { staggerStyle } from '../motion';
import { pathOf, stageIds } from '../routes';

/** Tint and icon of each stage (Chặng 1 shows a photo). Shared with FirstYear's next stages. */
export const stageLooks: { tint: Tint; icon: IconName }[] = [
  { tint: 'mint', icon: 'star' },
  { tint: 'sun', icon: 'star' },
  { tint: 'sleep', icon: 'spark' },
  { tint: 'peach', icon: 'globe' },
];

/** Illustrations of the four stages (Figma 688:18 … 688:88, 32-landing-v6-home §3). */
const journeyArt = [art1, art2, art3, art4];

/** Hành trình (14-landing-v3-home §3, art since v6): the four stage cards, each linking to its
 *  page. */
export function Chapters() {
  const { c, route } = useSite();
  const h = c.home.chapters;
  const j = c.journey;
  return (
    <section
      id="hanh-trinh"
      className="section chapters container"
      aria-labelledby="chapters-title"
    >
      <header className="section-head section-head--center reveal">
        <Eyebrow tone="mint">{h.eyebrow}</Eyebrow>
        <h2 id="chapters-title" className="h2 h2--flat">
          {h.title}
        </h2>
        <p className="lead">{h.lead}</p>
      </header>
      <ol className="chapters__list">
        {j.stages.map((stage, i) => {
          const look = stageLooks[i]!;
          return (
            <li
              key={stage.name}
              className={`chapter tint-ink--${look.tint}${i === 0 ? ' is-current' : ''} reveal`}
              style={staggerStyle(i)}
            >
              <div className={`chapter__art tint--${look.tint}`} aria-hidden="true">
                <span className="chapter__circle chapter__circle--a" />
                <span className="chapter__circle chapter__circle--b" />
                <span className="chapter__number">{i + 1}</span>
                <img
                  className="chapter__illustration"
                  src={journeyArt[i]}
                  alt=""
                  width={295}
                  height={170}
                  loading="lazy"
                  decoding="async"
                />
              </div>
              <span className={`chapter__thumb tint--${look.tint}`} aria-hidden="true">
                {i === 0 ? <Photo tone="peach" /> : <Icon name={look.icon} size={26} />}
              </span>
              <div className="chapter__body">
                <span className="chapter__label">
                  {j.number.replace('{n}', String(i + 1))} · {stage.ages}
                  {i === 0 && (
                    <Chip tint="mint" size="tag" className="chapter__badge">
                      {h.available}
                    </Chip>
                  )}
                </span>
                <h3 className="chapter__title">{stage.name}</h3>
                <p className="chapter__lead">{stage.lead}</p>
                <span className="chip-row chapter__chips">
                  {stage.chips.map((chip) => (
                    <Chip key={chip} tint={look.tint} size="sm">
                      {chip}
                    </Chip>
                  ))}
                </span>
                <a className="chapter__link" href={pathOf(stageIds[i]!, route.locale)}>
                  {i === 0 ? h.explore : h.view}
                  <Icon name="arrow-right" size={14} />
                </a>
              </div>
            </li>
          );
        })}
      </ol>
    </section>
  );
}
