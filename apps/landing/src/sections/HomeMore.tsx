import art1 from '../assets/figma/journey-art-stage1.svg';
import art2 from '../assets/figma/journey-art-stage2.svg';
import art3 from '../assets/figma/journey-art-stage3.svg';
import art4 from '../assets/figma/journey-art-stage4.svg';
import { type Tint } from '../components/kit';
import { Eyebrow, Icon, type IconName } from '../components/primitives';
import { useSite } from '../context';
import { staggerStyle } from '../motion';
import { pathOf, stageIds } from '../routes';
import { FaqList } from './Faq';

// Tiện ích cards (§7.1): icon and tint, in Figma order.
const toolLook: { icon: IconName; tint: Tint | 'error' }[] = [
  { icon: 'clock', tint: 'bottle' },
  { icon: 'star', tint: 'sun' },
  { icon: 'today', tint: 'mint' },
  { icon: 'bookmark', tint: 'peach' },
  { icon: 'alert', tint: 'error' },
  { icon: 'grid', tint: 'growth' },
  { icon: 'sliders', tint: 'sleep' },
  { icon: 'clock', tint: 'diaper' },
];

/** Tiện ích khác (Figma 735:6226 / 736:66283; §7): eight tools in one grid; the details live on
 *  the Năm đầu đời page. Mobile hides the chips, as drawn. */
export function HomeTools() {
  const { c, route } = useSite();
  const t = c.homePage.tools;
  return (
    <section
      id="tien-ich"
      className="home-section home-section--tools"
      aria-labelledby="tools-title"
    >
      <div className="container home-section__inner">
        <header className="home-head reveal">
          <Eyebrow tone="mint">{t.eyebrow}</Eyebrow>
          <h2 id="tools-title" className="home-head__title">
            {t.title}
          </h2>
        </header>
        <ul className="tools">
          {t.cards.map((card, i) => {
            const look = toolLook[i]!;
            return (
              <li key={card.title} className="tool reveal" style={staggerStyle(i % 4)}>
                <span className="tool__top">
                  <span className={`tool__icon tint--${look.tint}`}>
                    <Icon name={look.icon} size={24} />
                  </span>
                  <span className="tool__chip">{card.chip}</span>
                </span>
                <h3>{card.title}</h3>
                <p>{card.body}</p>
              </li>
            );
          })}
        </ul>
        <a
          className="home-button home-button--outline pressable reveal"
          href={pathOf('stage1', route.locale)}
        >
          {t.button}
          <Icon name="arrow-right" size={16} />
        </a>
      </div>
    </section>
  );
}

const journeyArt = [art1, art2, art3, art4];
const journeyTints = ['mint', 'sun', 'sleep', 'peach'];

/** Hành trình khi con lớn (Figma 736:65411 / 736:66345; §8): the four stages, the first "Đang có
 *  trong app", the others "Đang phát triển" (Q-039 roadmap). Every card links to its page. */
export function HomeJourney() {
  const { c, route } = useSite();
  const h = c.homePage.journey;
  const j = c.journey;
  return (
    <section id="hanh-trinh" className="home-section" aria-labelledby="journey-title">
      <div className="container home-section__inner">
        <header className="home-head reveal">
          <Eyebrow tone="mint">{h.eyebrow}</Eyebrow>
          <h2 id="journey-title" className="home-head__title">
            {h.title}
          </h2>
          <p className="home-head__lead">{h.lead}</p>
        </header>
        <ol className="stages-v8">
          {j.stages.map((stage, i) => (
            <li key={stage.name} className="reveal" style={staggerStyle(i)}>
              <a
                className={i === 0 ? 'stage-v8 is-now' : 'stage-v8'}
                href={pathOf(stageIds[i]!, route.locale)}
              >
                <span className={`stage-v8__art tint--${journeyTints[i]}`} aria-hidden="true">
                  <img
                    src={journeyArt[i]}
                    alt=""
                    width={295}
                    height={170}
                    loading="lazy"
                    decoding="async"
                  />
                </span>
                <span className="stage-v8__body">
                  <span className="stage-v8__status">
                    <Icon name={i === 0 ? 'check' : 'clock'} size={11} />
                    {i === 0 ? h.now : h.soon}
                  </span>
                  <span className="stage-v8__label">
                    {j.number.replace('{n}', String(i + 1))} · {stage.ages}
                  </span>
                  <strong className="stage-v8__title">{stage.name}</strong>
                  <span className="stage-v8__desc">{h.bodies[i]}</span>
                </span>
              </a>
            </li>
          ))}
        </ol>
      </div>
    </section>
  );
}

const pointIcons: IconName[] = ['check', 'spark', 'star', 'lock'];

/** Miễn phí, niềm tin & hỏi đáp (Figma 735:6445 / 736:66501; §9). Q-071 / D-074: "gói Lumi cao
 *  hơn" is not buyable yet. FAQ answers 2–5 are PROPOSED. */
export function HomeTrust() {
  const { c } = useSite();
  const t = c.homePage.trust;
  return (
    <section
      id="mien-phi"
      className="home-section home-section--white"
      aria-labelledby="trust-title"
    >
      <div className="container home-section__inner">
        <header className="home-head reveal">
          <Eyebrow tone="mint">{t.eyebrow}</Eyebrow>
          <h2 id="trust-title" className="home-head__title">
            {t.title}
          </h2>
        </header>
        <ul className="trust-points">
          {t.points.map((point, i) => (
            <li key={point} className="reveal" style={staggerStyle(i)}>
              <span className="lp-icon tint--mint">
                <Icon name={pointIcons[i]!} size={16} />
              </span>
              {point}
            </li>
          ))}
        </ul>
        <div id="hoi-dap" className="trust-faq">
          <FaqList items={t.faq} />
        </div>
      </div>
    </section>
  );
}
