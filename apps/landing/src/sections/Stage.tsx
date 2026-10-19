import art2 from '../assets/figma/stage-art-2.svg';
import art3 from '../assets/figma/stage-art-3.svg';
import art4 from '../assets/figma/stage-art-4.svg';
import type { Tint } from '../components/kit';
import { Eyebrow, Icon, type IconName } from '../components/primitives';
import { useSite } from '../context';
import { staggerStyle } from '../motion';
import { pathOf, stageIds, type StageId } from '../routes';

type FutureStageId = Exclude<StageId, 'stage1'>;

/** Per-stage look (36 §B.9.3; only Chặng 2 is drawn): hero art and the direction card icons. The
 *  hero band colour comes from `[data-stage]` CSS. */
const look: Record<FutureStageId, { art: string; icons: [IconName, IconName, IconName] }> = {
  stage2: { art: art2, icons: ['star', 'journal', 'clock'] },
  stage3: { art: art3, icons: ['spark', 'journal', 'heart'] },
  stage4: { art: art4, icons: ['star', 'clock', 'heart'] },
};
const cardTints: Tint[] = ['sun', 'peach', 'mint'];

/** A future stage (V8 template, Figma 738:7309; 36-landing-v8-lumi-and-stages B): the "Đang phát
 *  triển" band, the hero (primary CTA to the Năm đầu đời page; the drawn "Nhận tin…" button needs
 *  an email flow that does not exist, so it is not built), three directions (Q-039 roadmap) and
 *  the neighbouring stages. */
export function FutureStage({ stage }: { stage: FutureStageId }) {
  const { c, route } = useSite();
  const p = c.stagePage;
  const j = c.journey;
  const i = stageIds.indexOf(stage);
  const s = j.stages[i]!;
  const directions = c.lumiJourney.stages[i]!;
  const label = (n: number) => `${j.number.replace('{n}', String(n + 1))} · ${j.stages[n]!.ages}`;
  // Neighbours: the previous stage on the left, the next on the right; Chặng 4 points back to
  // Chặng 1, the one in the app.
  const links = [i - 1, i < 3 ? i + 1 : 0];
  return (
    <>
      <p className="dev-band" role="note">
        <Icon name="clock" size={16} />
        {p.band}
      </p>
      <section className="future-hero" aria-labelledby="stage-title">
        <div className="future-hero__inner container">
          <div className="future-hero__copy">
            <span className="fy-hero__chips enter">
              <span className="fy-chip fy-chip--dev">
                <Icon name="clock" size={12} />
                {p.status}
              </span>
              <span className="fy-chip">{label(i)}</span>
            </span>
            <h1 id="stage-title" className="future-hero__title">
              {s.title}
            </h1>
            <p className="future-hero__lead">
              {directions.sub} {p.lead.replace('{ages}', s.ages)}
            </p>
            <a className="home-button pressable enter" href={pathOf('stage1', route.locale)}>
              {p.useFirstYear}
            </a>
          </div>
          <span className="future-hero__art enter" aria-hidden="true">
            <img src={look[stage].art} alt="" width={592} height={385} />
          </span>
        </div>
      </section>
      <section id="dinh-huong" className="future-directions" aria-labelledby="directions-title">
        <div className="container future-directions__inner">
          <header className="home-head reveal">
            <Eyebrow tone="mint">{p.eyebrow}</Eyebrow>
            <h2 id="directions-title" className="home-head__title">
              {p.titles[i - 1]}
            </h2>
          </header>
          <ul className="future-cards">
            {directions.items.map((item, k) => (
              <li key={item.title} className="future-card reveal" style={staggerStyle(k)}>
                <span className="future-card__head">
                  <span className={`lp-icon tint--${cardTints[k]}`}>
                    <Icon name={look[stage].icons[k]!} size={20} className="ink--ink" />
                  </span>
                  <span className="future-card__chip">{c.lumiJourney.planned}</span>
                </span>
                <h3>{item.title}</h3>
                {item.body && <p>{item.body}</p>}
              </li>
            ))}
          </ul>
          <p className="future-note reveal">
            <Icon name="alert" size={14} />
            {p.note}
          </p>
        </div>
      </section>
      <nav className="future-links container" aria-label={j.prevNextLabel}>
        {links.map((n, k) => (
          <a
            key={n}
            className={n === 0 ? 'future-link is-now' : 'future-link'}
            href={pathOf(stageIds[n]!, route.locale)}
            rel={k === 0 ? 'prev' : 'next'}
          >
            <Icon name={k === 0 ? 'back' : 'arrow-right'} size={18} />
            <span className="future-link__text">
              <span>{label(n)}</span>
              <strong>{j.stages[n]!.name}</strong>
            </span>
            <span className="future-link__status">{n === 0 ? p.available : p.status}</span>
          </a>
        ))}
      </nav>
    </>
  );
}
