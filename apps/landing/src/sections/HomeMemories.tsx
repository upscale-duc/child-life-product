import { Eyebrow, Fit, Icon, Photo, type IconName } from '../components/primitives';
import { useSite } from '../context';
import { pathOf } from '../routes';
import { KeepMock } from './Keepsakes';

const alsoIcons: IconName[] = ['journal', 'heart', 'bookmark'];

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

/** Kỷ niệm (Figma 735:5598 / 736:65740; §4): the memory video large, milestone cards, then &
 *  now and the family album beside it, then "Còn có" and the link to the Năm đầu đời page. The
 *  drawn "Xem video mẫu" button has no sample video to open, so it is not built. */
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
          <p className="home-head__lead">{m.lead}</p>
        </header>
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
        <div className="mem-also reveal">
          <strong>{m.alsoLabel}</strong>
          <ul>
            {m.also.map((item, i) => (
              <li key={item}>
                <span className="lp-icon tint--peach">
                  <Icon name={alsoIcons[i]!} size={14} className="ink--ink" />
                </span>
                {item}
                {i === 2 && <span className="mem-also__soon">{m.soon}</span>}
              </li>
            ))}
          </ul>
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
