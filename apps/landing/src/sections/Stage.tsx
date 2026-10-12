import { Eyebrow, Icon, Photo, type IconName, type PhotoTone } from '../components/primitives';
import { useSite } from '../context';
import { pathOf, stageIds, type StageId } from '../routes';
import { staggerStyle } from '../motion';

/** Per-stage art (15-landing-v3-stages §0.2, §8): eyebrow tone, panel icon, highlight icons,
 *  quote photo. Colours come from `[data-stage]` in features.css. */
const stageArt: Record<
  StageId,
  {
    tone: 'mint' | 'sun-ink' | 'sleep' | 'peach';
    icon: IconName;
    highlights: [IconName, IconName, IconName];
    photo: PhotoTone;
  }
> = {
  stage1: { tone: 'mint', icon: 'star', highlights: ['star', 'clock', 'heart'], photo: 'peach' },
  stage2: { tone: 'sun-ink', icon: 'star', highlights: ['star', 'clock', 'heart'], photo: 'sun' },
  stage3: { tone: 'sleep', icon: 'spark', highlights: ['spark', 'journal', 'heart'], photo: 'sky' },
  stage4: { tone: 'peach', icon: 'globe', highlights: ['star', 'check', 'lock'], photo: 'leaf' },
};

export const stageIndex = (stage: StageId) => stageIds.indexOf(stage);

/** "Hành trình ›" + the four stage pills (§2). */
export function StageSwitcher({ stage }: { stage: StageId }) {
  const { c, route, homePath } = useSite();
  const j = c.journey;
  return (
    <nav className="switcher container" aria-label={j.label}>
      <a className="switcher__crumb" href={`${homePath}#hanh-trinh`}>
        {j.label}
        <Icon name="chevron-right" size={14} />
      </a>
      <ol className="switcher__list">
        {stageIds.map((id, i) => (
          <li key={id}>
            <a
              className={id === stage ? 'switcher__pill is-active' : 'switcher__pill'}
              href={pathOf(id, route.locale)}
              aria-current={id === stage ? 'page' : undefined}
            >
              <strong>{j.number.replace('{n}', String(i + 1))}</strong>
              <span>{j.stages[i]!.name}</span>
            </a>
          </li>
        ))}
      </ol>
    </nav>
  );
}

/** Stage hero (§3): copy + illustration panel (photo on Chặng 1, icon on 2–4). */
export function StageHero({ stage }: { stage: StageId }) {
  const { c } = useSite();
  const i = stageIndex(stage);
  const s = c.journey.stages[i]!;
  const look = stageArt[stage];
  return (
    <section className="stage-hero container" aria-labelledby="stage-title">
      <div className="stage-hero__copy">
        <Eyebrow tone={look.tone} className="enter">
          {c.journey.number.replace('{n}', String(i + 1))} · {s.ages}
        </Eyebrow>
        <h1 id="stage-title" className="stage-hero__title">
          {s.title}
        </h1>
        <p className="stage-hero__lead">{s.lead}</p>
        <ul className="stage-hero__chips enter" style={{ ['--i' as string]: 1 }}>
          {s.chips.map((chip) => (
            <li key={chip} className={`eyebrow eyebrow--${look.tone}`}>
              {chip}
            </li>
          ))}
        </ul>
      </div>
      <div className="stage-art enter" style={{ ['--i' as string]: 2 }} aria-hidden="true">
        <span className="stage-art__circle stage-art__circle--a" />
        <span className="stage-art__circle stage-art__circle--b" />
        <span className="stage-art__circle stage-art__circle--c" />
        <span className="stage-art__number">{i + 1}</span>
        {stage === 'stage1' ? (
          <Photo tone="peach" className="stage-art__photo" eager />
        ) : (
          <span className="stage-art__disc">
            <Icon name={look.icon} size={90} />
          </span>
        )}
      </div>
    </section>
  );
}

/** "Ở chặng này, Child Life cùng ba mẹ" (§4), Chặng 2–4. */
export function StageHighlights({ stage }: { stage: StageId }) {
  const { c } = useSite();
  const s = c.journey.stages[stageIndex(stage)]!;
  const look = stageArt[stage];
  if (!s.highlights || !s.quote) return null;
  return (
    <section className="stage-highlights container" aria-labelledby="highlights-title">
      <h2 id="highlights-title" className="stage-highlights__title reveal">
        {c.journey.highlightsTitle}
      </h2>
      <ul className="stage-highlights__cards">
        {s.highlights.map((item, i) => (
          <li key={item.title} className="stage-card reveal" style={staggerStyle(i)}>
            <span className="stage-card__icon">
              <Icon name={look.highlights[i]!} size={22} />
            </span>
            <h3>{item.title}</h3>
            <p>{item.body}</p>
          </li>
        ))}
      </ul>
      <div className="stage-quote reveal">
        <Photo tone={look.photo} className="stage-quote__photo" />
        <p>{s.quote}</p>
      </div>
    </section>
  );
}

/** Previous / next stage (§5). Chặng 1 has no previous; Chặng 4's next returns to the journey. */
export function StagePrevNext({ stage }: { stage: StageId }) {
  const { c, route, homePath } = useSite();
  const j = c.journey;
  const i = stageIndex(stage);
  const title = (n: number) => `${j.number.replace('{n}', String(n + 1))} · ${j.stages[n]!.name}`;
  const prev = stageIds[i - 1];
  const next = stageIds[i + 1];
  return (
    <nav className="prev-next container" aria-label={j.prevNextLabel}>
      {prev ? (
        <a className="prev-next__card" href={pathOf(prev, route.locale)} rel="prev">
          <span className="prev-next__label">{j.prev}</span>
          <strong>{title(i - 1)}</strong>
        </a>
      ) : (
        <span className="prev-next__spacer" />
      )}
      {next ? (
        <a
          className="prev-next__card prev-next__card--next"
          href={pathOf(next, route.locale)}
          rel="next"
        >
          <span className="prev-next__label">{j.next}</span>
          <strong>{title(i + 1)}</strong>
        </a>
      ) : (
        <a className="prev-next__card prev-next__card--next" href={`${homePath}#hanh-trinh`}>
          <span className="prev-next__label">{j.backLabel}</span>
          <strong>{j.backTitle}</strong>
        </a>
      )}
    </nav>
  );
}
