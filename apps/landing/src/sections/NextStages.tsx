import { Chip } from '../components/kit';
import { Eyebrow, Icon } from '../components/primitives';
import { scenes, type Scene } from '../components/scenes';
import { useSite } from '../context';
import { staggerStyle } from '../motion';
import { pathOf, stageIds } from '../routes';
import { stageLooks } from './Chapters';

const photos: Scene[] = ['toddler', 'preschool', 'schoolAge'];

/** Các chặng tiếp theo (28-landing-v5b-home §4): the four-step path and a card per coming stage,
 *  each linking to its stage page. Stage colours follow Hành trình (§11.5). */
export function NextStages() {
  const { c, route } = useSite();
  const s = c.home.stages;
  const j = c.journey;
  const label = (n: number) => `${j.number.replace('{n}', String(n + 1))} · ${j.stages[n]!.ages}`;
  return (
    <section id="cac-chang" className="section next container" aria-labelledby="next-title">
      <header className="section-head section-head--center reveal">
        <Eyebrow tone="mint">{s.eyebrow}</Eyebrow>
        <h2 id="next-title" className="h2 h2--flat">
          {s.title}
        </h2>
        <p className="lead">{s.lead}</p>
      </header>
      <ol className="next__path reveal" aria-label={j.label}>
        {j.stages.map((stage, i) => (
          <li key={stage.name} className={i === 0 ? 'is-current' : undefined}>
            <a href={i === 0 ? '#nam-dau-doi' : pathOf(stageIds[i]!, route.locale)}>
              <span className="next__num">{i + 1}</span>
              {i === 0 ? `${s.firstName} · ${s.current}` : stage.ages}
            </a>
          </li>
        ))}
      </ol>
      <ul className="next__cards">
        {j.stages.slice(1).map((stage, k) => {
          const i = k + 1;
          const look = stageLooks[i]!;
          return (
            <li
              key={stage.name}
              className={`next-card tint-ink--${look.tint} reveal`}
              style={staggerStyle(k)}
            >
              <div className={`next-card__art tint--${look.tint}`}>
                <img src={scenes[photos[k]!]} alt="" loading="lazy" decoding="async" />
                <span className="next-card__num" aria-hidden="true">
                  {i + 1}
                </span>
                <span className="next-card__soon">{s.soon}</span>
              </div>
              <div className="next-card__body">
                <span className="next-card__label">{label(i)}</span>
                <h3>{stage.name}</h3>
                <p>{stage.lead}</p>
                <span className="chip-row">
                  {stage.chips.map((chip) => (
                    <Chip key={chip} tint={look.tint} className="next-card__chip">
                      {chip}
                    </Chip>
                  ))}
                </span>
                <a className="next-card__link pressable" href={pathOf(stageIds[i]!, route.locale)}>
                  {s.preview.replace('{n}', String(i + 1))}
                  <Icon name="arrow-right" size={16} />
                </a>
              </div>
            </li>
          );
        })}
      </ul>
    </section>
  );
}
