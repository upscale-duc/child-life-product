import { Eyebrow, Fit, Icon, Photo, at, type PhotoTone } from '../components/primitives';
import { useSite } from '../context';
import { staggerStyle } from '../motion';

const tones: PhotoTone[] = ['sand', 'sun', 'mint', 'peach', 'lilac', 'leaf', 'sky'];
// Rotated bounding boxes from spec §6 (x, y, w, h, rotation); the 170 × 188 card is centred in each.
const boxes: [number, number, number, number, number][] = [
  [-31.7, 51, 176.6, 196.8, 2],
  [155, 334.1, 176.6, 196.8, -2],
  [330, 51, 174.9, 195.4, 1.5],
  [515, 333.9, 180.6, 197.0, -2],
  [688.3, 51, 176.6, 196.8, 2],
  [875, 335.6, 174.9, 195.4, -1.5],
  [1051.7, 51, 173.3, 193.9, 1],
];

/** Tuổi thơ / "Kỷ niệm" (spec §6): growing-up timeline and three memory tiles. */
export function Memories() {
  const { c } = useSite();
  const m = c.memories;
  const t = m.tiles;
  const late = (k: number) => k >= 5;

  return (
    <section id="ky-niem" className="memories" aria-labelledby="memories-title">
      <div className="section container">
        <header className="section-head section-head--center memories__head reveal">
          <Eyebrow tone="sun">{m.eyebrow}</Eyebrow>
          <h2 id="memories-title" className="h2">
            {m.title}
          </h2>
          <p className="lead">{m.lead}</p>
        </header>

        {/* Desktop: horizontal rail, polaroids alternate above and below; they land as the rail reaches them. */}
        <div className="timeline-wide reveal">
          <Fit w={1248} h={580} mobileScale={1}>
            <span className="timeline-wide__rail grow-x" style={at(24, 288)} />
            {m.timeline.map((item, k) => {
              const [x, y, w, h, rotation] = boxes[k]!;
              return (
                <span key={item.title}>
                  <span
                    className={`timeline-wide__stem${k % 2 ? ' is-down' : ''}`}
                    style={at(59 + 180 * k, k % 2 ? 300 : 242)}
                  />
                  <span
                    className={`node${late(k) ? ' node--late' : ''} pop`}
                    style={at(51 + 180 * k, 281, { ['--i' as string]: k })}
                  />
                  <span
                    className="polaroid-slot"
                    style={at(x + (w - 170) / 2, y + (h - 188) / 2, {
                      ['--r' as string]: `${rotation}deg`,
                      ['--i' as string]: k,
                    })}
                  >
                    <span className="polaroid">
                      <span className="polaroid__window">
                        <Photo tone={tones[k]!} />
                      </span>
                      <span className="polaroid__caption">
                        <span className={`polaroid__age${late(k) ? ' is-late' : ''}`}>
                          {item.age}
                        </span>
                        <span className="polaroid__title">{item.title}</span>
                      </span>
                    </span>
                  </span>
                </span>
              );
            })}
            <span className="timeline-wide__end" style={at(1090, 304)}>
              {m.timelineEnd}
            </span>
          </Fit>
        </div>

        {/* Mobile: vertical list, no rotation. */}
        <ol className="timeline-list" aria-hidden="true">
          {m.timeline.map((item, k) => (
            <li key={item.title} className="timeline-list__row reveal" style={staggerStyle(k)}>
              <span className={`node${late(k) ? ' node--late' : ''}`} />
              <span className="timeline-list__card">
                <span className="timeline-list__window">
                  <Photo tone={tones[k]!} />
                </span>
                <span className="polaroid__caption">
                  <span className={`polaroid__age${late(k) ? ' is-late' : ''}`}>{item.age}</span>
                  <span className="polaroid__title">{item.title}</span>
                </span>
              </span>
            </li>
          ))}
          <li className="timeline-list__end reveal">{m.timelineEnd}</li>
        </ol>

        <div className="tiles">
          <article className="tile reveal" style={staggerStyle(0)}>
            <div className="tile__art tone-bg--mint" aria-hidden="true">
              <div className="tile__group tile__group--grid">
                {(['mint', 'peach', 'sun', 'lilac', 'sky', 'leaf'] as PhotoTone[]).map(
                  (tone, i) => (
                    <Photo
                      key={tone}
                      tone={tone}
                      className="grid-photo pop"
                      style={{ ['--i' as string]: i }}
                    />
                  ),
                )}
                <span className="grid-chip pop" style={{ ['--i' as string]: 6 }}>
                  <Icon name="bookmark" size={14} />
                  {t.photos.chip}
                </span>
              </div>
            </div>
            <div className="tile__text">
              <h3>{t.photos.title}</h3>
              <p>{t.photos.body}</p>
            </div>
          </article>

          <article className="tile reveal" style={staggerStyle(1)}>
            <div className="tile__art tone-bg--sun" aria-hidden="true">
              <div className="tile__group tile__group--story">
                <div className="story-card story-card--letter" style={at(10, 31.7)}>
                  <span className="story-card__mini" style={at(110.3, 9.9)}>
                    <Photo tone="lilac" />
                  </span>
                  <span className="script" style={at(13, 22, { fontSize: 15 })}>
                    {t.story.letter.greeting}
                  </span>
                  {[76, 88, 100, 112, 124, 136, 148].map((y) => (
                    <span key={y} className="story-card__rule" style={at(13, y)} />
                  ))}
                  <span className="story-card__body" style={at(13, 67)}>
                    {t.story.letter.body}
                  </span>
                  <span className="script story-card__signature" style={at(69, 166)}>
                    {t.story.letter.signature}
                  </span>
                  <span className="story-card__brand" style={at(125, 188)}>
                    Child Life
                  </span>
                </div>
                <div className="story-card story-card--moment" style={at(149.3, 6.6)}>
                  <span className="story-card__polaroid" style={at(16, 18)}>
                    <span className="story-card__photo">
                      <Photo tone="mint" />
                    </span>
                    <span className="script story-card__caption">{t.story.moment.caption}</span>
                  </span>
                  <span className="story-card__quote">{t.story.moment.quote}</span>
                  <span className="story-card__tag">{t.story.moment.tag}</span>
                  <span className="story-card__brand" style={at(125, 188)}>
                    Child Life
                  </span>
                </div>
              </div>
            </div>
            <div className="tile__text">
              <h3>{t.story.title}</h3>
              <p>{t.story.body}</p>
            </div>
          </article>

          <article className="tile reveal" style={staggerStyle(2)}>
            <div className="tile__art tone-bg--peach" aria-hidden="true">
              <div className="tile__group tile__group--notes">
                {t.family.notifications.map((note, i) => (
                  <span
                    key={note.text}
                    className="notice slide-in"
                    style={at(14 * i, 66 * i, { ['--i' as string]: i })}
                  >
                    <span className={`notice__avatar notice__avatar--${i}`}>{note.initial}</span>
                    <span className="notice__text">
                      <span className="notice__title">{note.text}</span>
                      <span className="notice__when">{note.when}</span>
                    </span>
                    <Icon
                      name="heart"
                      size={16}
                      className={i === 0 ? 'notice__heart is-beating' : 'notice__heart'}
                    />
                  </span>
                ))}
              </div>
            </div>
            <div className="tile__text">
              <h3>{t.family.title}</h3>
              <p>{t.family.body}</p>
            </div>
          </article>
        </div>
      </div>
    </section>
  );
}
