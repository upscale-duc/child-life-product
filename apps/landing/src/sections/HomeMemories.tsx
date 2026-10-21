import { Avatars } from '../components/rows';
import { Eyebrow, Fit, Icon, Photo, type PhotoTone } from '../components/primitives';
import { useSite } from '../context';
import { staggerStyle } from '../motion';
import { pathOf } from '../routes';
import { KeepMock } from './Keepsakes';

/** Picture of each memory step (37 §5.1), 170 × 72, decorative. */
function StepArt({ index }: { index: number }) {
  const { c } = useSite();
  const m = c.homePage.memories;
  const photos = (tones: PhotoTone[]) =>
    tones.map((tone, i) => <Photo key={i} tone={tone} className="mem-step__photo" />);
  switch (index) {
    case 0:
      return photos(['peach', 'sun', 'peach']);
    case 1:
      return (
        <>
          {photos(['peach', 'sun'])}
          <span className="mem-step__check">
            <Icon name="check" size={12} />
          </span>
        </>
      );
    case 2:
      return (
        <>
          <span className="mem-step__tile tint--sleep">
            <Icon name="arrow-right" size={18} />
          </span>
          <span className="mem-step__tile tint--sun">
            <Icon name="cake" size={18} />
          </span>
        </>
      );
    case 3:
      return <Avatars people={['mom', 'dad', 'grandma', 'grandpa']} size={28} />;
    case 4:
      return <span className="mem-step__quote">{m.quote}</span>;
    default:
      return (
        <span className="mem-step__firsts">
          {m.firsts.map((first) => (
            <span key={first}>{first}</span>
          ))}
        </span>
      );
  }
}

/** A keepsake mock-up (432 × 280, Keepsakes) shown as a crop: `shift` moves it up by a share of
 *  its width so the drawn band shows (34-landing-v8-home §4.1). */
function Crop({ index, tint, shift }: { index: number; tint: string; shift: number }) {
  return (
    <span className={`mem-crop tint--${tint}`} aria-hidden="true">
      <span className="mem-crop__stage" style={{ marginTop: `${-shift}%` }}>
        <Fit w={432} h={280} mobileScale={0.6944}>
          <KeepMock index={index} />
        </Fit>
      </span>
    </span>
  );
}

/** Kỷ niệm (V9, Figma 785:7166 / 785:7996; 37 §5): six steps from finding photos to milestones,
 *  then the memory video, milestone cards, then & now and the family album, and the link to the
 *  Năm đầu đời page. The drawn "Xem video mẫu" has no sample video to open, so it is not built. */
export function HomeMemories() {
  const { c, route } = useSite();
  const m = c.homePage.memories;
  return (
    <section
      id="ky-niem"
      className="home-section home-section--warm"
      aria-labelledby="memories-title"
    >
      <div className="container home-section__inner">
        <header className="home-head home-head--wide reveal">
          <Eyebrow tone="peach-ink">{m.eyebrow}</Eyebrow>
          <h2 id="memories-title" className="home-head__title">
            {m.title}
          </h2>
          <p className="home-head__lead only-mobile">{m.lead}</p>
        </header>
        <ol className="mem-steps">
          {m.steps.map((step, i) => (
            <li key={step.title} className="mem-step reveal" style={staggerStyle(i % 3)}>
              <span className="mem-step__head" aria-hidden="true">
                <span className="mem-step__n">{i + 1}</span>
                {i < m.steps.length - 1 && <Icon name="arrow-right" size={14} />}
              </span>
              <span className="mem-step__art" aria-hidden="true">
                <StepArt index={i} />
              </span>
              <strong className="mem-step__title">{step.title}</strong>
              <span className="mem-step__sub">{step.sub}</span>
              <span className="mem-step__tags">
                {step.tags.map((tag) => (
                  <span key={tag}>{tag}</span>
                ))}
              </span>
            </li>
          ))}
        </ol>
        <div className="mem-grid">
          <article className="mem-card mem-card--video reveal">
            <span className="mem-card__art mem-card__art--video tint--sleep" aria-hidden="true">
              <Fit w={432} h={300} mobileScale={0.75}>
                <span className="mem-video-stage">
                  <KeepMock index={0} />
                </span>
              </Fit>
            </span>
            <span className="mem-card__text">
              <h3>{m.video.title}</h3>
              <p>{m.video.body}</p>
            </span>
          </article>
          <div className="mem-side">
            <article className="mem-card mem-card--row mem-card--wide reveal">
              <span className="mem-card__art mem-card__art--band">
                <Crop index={1} tint="sun" shift={12} />
              </span>
              <span className="mem-card__text">
                <h3>{m.card.title}</h3>
                <p>
                  <span className="only-desktop-inline">{m.card.body}</span>
                  <span className="only-mobile-inline">{m.card.bodyShort}</span>
                </p>
              </span>
            </article>
            <div className="mem-pair">
              <article className="mem-card mem-card--row reveal">
                <span className="mem-card__art">
                  <Crop index={3} tint="bottle" shift={4} />
                </span>
                <span className="mem-card__text">
                  <h3>{m.thenNow.title}</h3>
                  <p>
                    <span className="only-desktop-inline">{m.thenNow.body}</span>
                    <span className="only-mobile-inline">{m.thenNow.bodyShort}</span>
                  </p>
                </span>
              </article>
              <article className="mem-card mem-card--row reveal">
                <span className="mem-card__art mem-album tint--peach" aria-hidden="true">
                  <span className="mem-album__photos">
                    <Photo tone="peach" />
                    <Photo tone="sky" />
                    <Photo tone="mint" />
                  </span>
                  <span className="mem-album__seen">
                    <b>{m.album.initial}</b>
                    {m.album.seen}
                  </span>
                </span>
                <span className="mem-card__text">
                  <h3>{m.album.title}</h3>
                  <p>{m.album.body}</p>
                </span>
              </article>
            </div>
          </div>
        </div>
        <a
          className="home-button pressable reveal"
          href={`${pathOf('stage1', route.locale)}#ky-niem`}
        >
          {m.button}
          <Icon name="arrow-right" size={16} />
        </a>
      </div>
    </section>
  );
}
