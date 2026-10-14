import type { ReactNode } from 'react';
import { Eyebrow, Fit, Icon, Photo, at, type IconName } from '../components/primitives';
import { scenes } from '../components/scenes';
import { useSite } from '../context';
import { staggerStyle } from '../motion';

const looks: { tint: string; icon: IconName }[] = [
  { tint: 'sleep', icon: 'camera' },
  { tint: 'sun', icon: 'grid' },
  { tint: 'peach', icon: 'journal' },
  { tint: 'bottle', icon: 'memories' },
  { tint: 'mint', icon: 'speaker' },
  { tint: 'card-sun', icon: 'bookmark' },
];

// Waveform bar heights of the voice message (Figma 522:4263).
const wave = [
  8, 26, 12, 25, 17, 22, 21, 19, 23, 15, 25, 11, 26, 10, 25, 14, 24, 18, 21, 22, 17, 24,
];

function Pill({ icon, ink, children }: { icon: IconName; ink: string; children: ReactNode }) {
  return (
    <span className="keep-pill">
      <Icon name={icon} size={14} className={`ink--${ink}`} />
      {children}
    </span>
  );
}

/** The six illustrations (28-landing-v5b-home §5.2), each a 432 × 280 composition. */
function Mock({ index }: { index: number }) {
  const { c } = useSite();
  const m = c.home.keepsakes.mock;
  switch (index) {
    case 0:
      return (
        <>
          <div className="keep-video" style={at(58, 28)}>
            <img src={scenes.firstYearVideo} alt="" loading="lazy" decoding="async" />
            <span className="keep-video__scrim" />
            <span className="keep-video__template">{m.video.template}</span>
            <span className="keep-video__play">
              <Icon name="arrow-right" size={18} />
            </span>
            <strong className="keep-video__caption">{m.video.caption}</strong>
            <span className="keep-video__time">{m.video.time}</span>
            <span className="keep-video__track">
              <span />
            </span>
          </div>
          <span style={at(58, 236)}>
            <Pill icon="speaker" ink="sleep">
              {m.video.music}
            </Pill>
          </span>
          <span style={at(262, 236)}>
            <Pill icon="star" ink="growth">
              {m.video.milestones}
            </Pill>
          </span>
        </>
      );
    case 1:
      return (
        <>
          <div className="keep-card" style={at(37.5, 27.5)}>
            <Photo tone="mint" className="keep-card__photo" />
            <strong>{m.card.title}</strong>
            <span>{m.card.sub}</span>
          </div>
          {[
            [236, 26],
            [400, 40],
            [400, 250],
          ].map(([x, y]) => (
            <span key={`${x}-${y}`} className="keep-star" style={at(x!, y!)}>
              <Icon name="star" size={16} />
            </span>
          ))}
          <span className="keep-options" style={at(262, 66)}>
            {m.card.options.map((option, i) => (
              <span key={option} className={i === 1 ? 'is-selected' : undefined}>
                <Icon name={i === 1 ? 'check' : 'star'} size={12} />
                {option}
              </span>
            ))}
          </span>
          <span style={at(262, 200)}>
            <Pill icon="upload" ink="mint">
              {m.card.save}
            </Pill>
          </span>
        </>
      );
    case 2:
      return (
        <div className="keep-post" style={at(48, 22, { width: 336 })}>
          <span className="keep-post__head">
            <span className="keep-post__avatar">{m.journal.initial}</span>
            <span>
              <strong>{m.journal.name}</strong>
              <span>{m.journal.time}</span>
            </span>
          </span>
          <p>{m.journal.text}</p>
          <span className="keep-post__media">
            <Photo tone="sky" />
            <Photo tone="sun" />
            <span className="keep-post__video">
              <Photo tone="leaf" />
              <span>{m.journal.duration}</span>
            </span>
          </span>
          <span className="keep-post__saved">
            <Icon name="check" size={12} />
            {m.journal.saved}
          </span>
        </div>
      );
    case 3:
      return (
        <>
          <div className="keep-compare" style={at(48, 22)}>
            <img
              className="keep-compare__then"
              src={scenes.thenBaby}
              alt=""
              loading="lazy"
              decoding="async"
            />
            <img src={scenes.nowBaby} alt="" loading="lazy" decoding="async" />
            <span className="keep-compare__divider" />
            <span className="keep-compare__handle">
              <Icon name="back" size={12} />
              <Icon name="arrow-right" size={12} />
            </span>
            <span className="keep-compare__label" style={at(12, 12)}>
              {m.thenNow.then}
            </span>
            <span className="keep-compare__label keep-compare__label--right">{m.thenNow.now}</span>
          </div>
          <span style={at(48, 232)}>
            <Pill icon="camera" ink="bottle">
              {m.thenNow.video}
            </Pill>
          </span>
          <span style={at(240, 232)}>
            <Pill icon="grid" ink="bottle">
              {m.thenNow.collage}
            </Pill>
          </span>
        </>
      );
    case 4:
      return (
        <>
          <div className="keep-voice" style={at(40, 30)}>
            <span className="keep-avatar tint--sleep">{m.voice.initial}</span>
            <span className="keep-voice__play">
              <Icon name="arrow-right" size={14} />
            </span>
            <span className="keep-voice__wave">
              {wave.map((h, i) => (
                <i key={i} style={{ height: h }} />
              ))}
            </span>
            <span className="keep-voice__length">{m.voice.length}</span>
          </div>
          <span className="keep-voice__from" style={at(58, 92)}>
            {m.voice.from}
          </span>
          <div className="keep-text" style={at(110, 122)}>
            <span className="keep-avatar tint--bottle">{m.voice.textInitial}</span>
            <span>
              <strong>{m.voice.textName}</strong>
              <span>{m.voice.text}</span>
            </span>
          </div>
          <span style={at(40, 228)}>
            <Pill icon="lock" ink="mint">
              {m.voice.privacy}
            </Pill>
          </span>
        </>
      );
    default:
      return (
        <>
          <div className="keep-book" style={at(42.4, 27.9)}>
            <span className="keep-book__cover">
              <Photo tone="sand" />
              <strong>
                <span>{m.book.cover[0]}</span> <span>{m.book.cover[1]}</span>
              </strong>
            </span>
            <span className="keep-book__page">
              <strong>{m.book.month}</strong>
              <span className="keep-book__grid">
                <Photo tone="sky" />
                <Photo tone="rose" />
                <Photo tone="sun" />
                <Photo tone="mint" />
              </span>
              <span className="keep-book__caption">{m.book.caption}</span>
            </span>
          </div>
          <span style={at(46, 236)}>
            <Pill icon="bookmark" ink="mint">
              {m.book.pdf}
            </Pill>
          </span>
          <span style={at(206, 236)}>
            <Pill icon="upload" ink="mint">
              {m.book.print}
            </Pill>
          </span>
        </>
      );
  }
}

/** Kỷ niệm của con (28-landing-v5b-home §5.2): six ways to keep and retell memories. The
 *  illustrations are decorative app mock-ups; on narrow screens the cards scroll sideways. */
export function Keepsakes() {
  const { c } = useSite();
  const k = c.home.keepsakes;
  return (
    <div id="ky-niem" className="keepsakes">
      <header className="section-head section-head--center reveal">
        <Eyebrow tone="mint">{k.eyebrow}</Eyebrow>
        <h2 className="h2 h2--flat">{k.title}</h2>
        <p className="lead">{k.lead}</p>
      </header>
      <ul className="keepsakes__grid">
        {k.cards.map((card, i) => (
          <li key={card.title} className="keep-tile reveal" style={staggerStyle(i % 3)}>
            <div className={`keep-tile__art tint--${looks[i]!.tint}`} aria-hidden="true">
              <Fit w={432} h={280} mobileScale={0.6944}>
                <Mock index={i} />
              </Fit>
            </div>
            <div className="keep-tile__body">
              <span className="keep-tile__format">
                <Icon name={looks[i]!.icon} size={13} />
                {card.format}
              </span>
              <h3>{card.title}</h3>
              <p>{card.body}</p>
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}
