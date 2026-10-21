import type { ReactNode } from 'react';
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

/** The growing-up rail (1248 × 580): polaroids alternate above and below and land as the rail
 *  reaches them. Shown small in step 2. */
function Timeline() {
  const { c } = useSite();
  const m = c.memories;
  const late = (k: number) => k >= 5;
  return (
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
                  <span className={`polaroid__age${late(k) ? ' is-late' : ''}`}>{item.age}</span>
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
  );
}

/** The art of each step (38 §14.5–§14.9): the V8 tile art reused, plus the new pieces. Each is a
 *  612 × 280 or 400 × 280 composition, decorative. */
function StepArt({ index }: { index: number }) {
  const { c } = useSite();
  const m = c.memories;
  const t = m.tiles;
  switch (index) {
    case 0:
      return (
        <>
          <span className="flow-box" style={at(202, 30, { width: 400, height: 240 })}>
            <div className="tile__group tile__group--grid">
              {(['mint', 'peach', 'sun', 'lilac', 'sky', 'leaf'] as PhotoTone[]).map((tone, i) => (
                <Photo
                  key={tone}
                  tone={tone}
                  className="grid-photo pop"
                  style={{ ['--i' as string]: i }}
                />
              ))}
              <span className="grid-chip pop" style={{ ['--i' as string]: 6 }}>
                <Icon name="bookmark" size={14} />
                {t.photos.chip}
              </span>
            </div>
          </span>
          <span className="flow-found" style={at(28, 56)}>
            <span className="flow-found__head">
              <span className="lp-icon tint--mint">
                <Icon name="search" size={14} />
              </span>
              {m.found.title}
            </span>
            <span className="flow-found__sub">{m.found.sub}</span>
            <span className="flow-found__buttons">
              <span className="is-primary">{m.found.saveAll}</span>
              <span>{m.found.pick}</span>
            </span>
          </span>
        </>
      );
    case 1:
      return (
        <>
          <span className="flow-views" style={at(193, 18)}>
            {m.views.map((view, i) => (
              <span key={view} className={i === 0 ? 'is-active' : undefined}>
                {view}
              </span>
            ))}
          </span>
          <span className="flow-timeline" style={at(90.83, 66, { width: 430.345, height: 200 })}>
            <Timeline />
          </span>
        </>
      );
    case 2:
      return (
        <>
          <span className="flow-video" style={at(30, 40)}>
            <Photo tone="peach" />
          </span>
          <span className="flow-play" style={at(108, 93)}>
            <Icon name="arrow-right" size={18} />
          </span>
          <span className="flow-clip" style={at(40, 200)}>
            {m.clip}
          </span>
          <span className="flow-card" style={at(218, 92)}>
            <Photo tone="sun" />
            <strong>{m.card.title}</strong>
            <span>{m.card.meta}</span>
          </span>
        </>
      );
    case 3:
      return (
        <span className="flow-box" style={at(0, 20, { width: 400, height: 240 })}>
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
        </span>
      );
    default:
      return (
        <>
          <span className="flow-box" style={at(0, -10, { width: 400, height: 240 })}>
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
          </span>
          <span className="flow-share" style={at(31, 230)}>
            <span>{m.share.label}</span>
            {m.share.targets.map((target) => (
              <span key={target} className="flow-share__chip">
                {target}
              </span>
            ))}
          </span>
        </>
      );
  }
}

// Art tint per step (38 §14.5–§14.9; raw tints mapped to the nearest token, leaf green kept raw).
const artTints = ['mint', 'sleep', 'sun', 'peach', 'leaf'];

function StepCard({ index, wide }: { index: number; wide?: boolean }) {
  const { c } = useSite();
  const m = c.memories;
  const step = m.steps[index]!;
  const w = wide ? 612 : 400;
  return (
    <li
      className={wide ? 'flow-step flow-step--wide reveal' : 'flow-step reveal'}
      style={staggerStyle(index)}
    >
      <span className={`flow-step__art tint--${artTints[index]}`} aria-hidden="true">
        <Fit w={w} h={280} mobileScale={335 / w}>
          <StepArt index={index} />
        </Fit>
      </span>
      <span className="flow-step__text">
        <span className="flow-step__chip">{m.stepChip.replace('{n}', String(index + 1))}</span>
        <h3>{step.title}</h3>
        <p>{step.body}</p>
        <span className="flow-step__tags">
          {step.tags.map((tag) => (
            <span key={tag}>{tag}</span>
          ))}
        </span>
      </span>
    </li>
  );
}

function Strip({ children }: { children: ReactNode }) {
  return (
    <ol className="flow-strip" aria-hidden="true">
      {children}
    </ol>
  );
}

/** Tuổi thơ / "Kỷ niệm" (V9, Figma 785:9495; 38-landing-v9-first-year §14): five steps from the
 *  photos on the phone to stories the family keeps — a strip, then two wide and three cards.
 *  Q-039: Tự lưu is an iOS beta (D-066); comments are not built (D-034); stories are written from
 *  text (D-041). */
export function Memories() {
  const { c } = useSite();
  const m = c.memories;
  return (
    <section className="memories" aria-labelledby="memories-title">
      <div className="section container">
        <header className="section-head section-head--center memories__head reveal">
          <Eyebrow tone="sun">{m.eyebrow}</Eyebrow>
          <h2 id="memories-title" className="h2">
            {m.title}
          </h2>
          <p className="lead">{m.lead}</p>
        </header>
        <div className="flow">
          <Strip>
            {m.steps.map((step, i) => (
              <li key={step.label}>
                {i > 0 && <Icon name="arrow-right" size={14} />}
                <span className="flow-strip__pill">
                  <b>{i + 1}</b>
                  {step.label}
                </span>
              </li>
            ))}
          </Strip>
          <ol className="flow-row">
            <StepCard index={0} wide />
            <StepCard index={1} wide />
          </ol>
          <ol className="flow-row" start={3}>
            <StepCard index={2} />
            <StepCard index={3} />
            <StepCard index={4} />
          </ol>
        </div>
      </div>
    </section>
  );
}
