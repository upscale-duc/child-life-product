import art2 from '../assets/figma/stage-art-2.svg';
import art3 from '../assets/figma/stage-art-3.svg';
import art4 from '../assets/figma/stage-art-4.svg';
import { Chip, LumiMascot, type Ink, type Tint } from '../components/kit';
import { Eyebrow, Icon } from '../components/primitives';
import { useSite } from '../context';
import { staggerStyle } from '../motion';
import { pathOf, stageIds } from '../routes';
import { LumiJourney } from './Lumi';

// Cards for Chặng 2–4 (Figma 649:6853 / 6875 / 6898): illustration, tint and ink as drawn. Their
// stage-3 / stage-4 colours differ from Hành trình (32-landing-v6-home §5.3).
const cards: { art: string; tint: Tint; ink: Ink }[] = [
  { art: art2, tint: 'sun', ink: 'growth' },
  { art: art3, tint: 'peach', ink: 'bottle' },
  { art: art4, tint: 'sleep', ink: 'sleep' },
];

/** Các chặng tiếp theo (28 §4, 32-landing-v6-home §5–§6): the four-step path, a card per coming
 *  stage with what Lumi will do there, then "Lumi · suốt hành trình". */
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
          const look = cards[k]!;
          return (
            <li key={stage.name} className="next-card reveal" style={staggerStyle(k)}>
              <div className="next-card__art">
                <img
                  src={look.art}
                  alt=""
                  width={400}
                  height={260}
                  loading="lazy"
                  decoding="async"
                />
                <span className={`next-card__num ink--${look.ink}`} aria-hidden="true">
                  {i + 1}
                </span>
                <span className="next-card__soon">{s.soon}</span>
              </div>
              <div className="next-card__body">
                <span className={`next-card__label ink--${look.ink}`}>{label(i)}</span>
                <h3>{stage.name}</h3>
                <p>{stage.lead}</p>
                <span className="chip-row">
                  {stage.chips.map((chip) => (
                    <Chip key={chip} tint={look.tint} ink={look.ink} className="next-card__chip">
                      {chip}
                    </Chip>
                  ))}
                </span>
                <a className="next-card__lumi" href="#lumi-hanh-trinh">
                  <LumiMascot size={24} />
                  <span>
                    <span className="next-card__lumi-label">{s.lumiLabel}</span>
                    <strong>{s.lumiTeasers[k]}</strong>
                  </span>
                </a>
                <a className="next-card__link pressable" href={pathOf(stageIds[i]!, route.locale)}>
                  {s.preview.replace('{n}', String(i + 1))}
                  <Icon name="arrow-right" size={16} />
                </a>
              </div>
            </li>
          );
        })}
      </ul>
      <LumiJourney cta={{ label: c.lumiJourney.explore, href: pathOf('lumi', route.locale) }} />
    </section>
  );
}
