import type { CSSProperties } from 'react';
import { CompactBullets } from '../components/Bullets';
import { Chip, IconBox } from '../components/kit';
import { Eyebrow, Fit, Icon, Photo, at, type PhotoTone } from '../components/primitives';
import type { Article } from '../content/types';
import { useSite } from '../context';

function ArticleCard({
  article,
  tone,
  photoHeight,
  style,
}: {
  article: Article;
  tone: PhotoTone;
  photoHeight: number;
  style?: CSSProperties;
}) {
  return (
    <div className="article-card pop" style={style}>
      <Photo tone={tone} className="article-card__photo" style={{ height: photoHeight }} />
      <span className="article-card__text">
        <Chip tint="sleep" size="tag">
          {article.tag}
        </Chip>
        <strong>{article.title}</strong>
        <span>{article.meta}</span>
      </span>
    </div>
  );
}

/** Thư viện & ăn dặm (12-landing-v3 §4): copy left, absolute panel right on desktop; mobile
 *  re-composes a shorter panel in flow (search, one article row, solids). */
export function Library() {
  const { c } = useSite();
  const l = c.library;
  const s = l.solids;
  return (
    <section
      id="thu-vien"
      className="section feature container split"
      aria-labelledby="library-title"
    >
      <div className="split__copy">
        <header className="section-head reveal">
          <Eyebrow tone="mint">{l.eyebrow}</Eyebrow>
          <h2 id="library-title" className="h2 feature__title">
            {l.title}
          </h2>
          <p className="lead split__lead">
            <span className="only-desktop-inline">{l.lead}</span>
            <span className="only-mobile-inline">{l.leadShort}</span>
          </p>
        </header>
        <div
          className="flow-panel flow-panel--library tint--mint only-mobile reveal"
          aria-hidden="true"
        >
          <span className="search-bar search-bar--sm">
            <Icon name="search" size={16} />
            {l.search}
          </span>
          <div className="article-row">
            <Photo tone="night" className="article-row__photo" />
            <span className="article-card__text">
              <Chip tint="sleep" size="tag">
                {l.articles[0].tag}
              </Chip>
              <strong>{l.articles[0].title}</strong>
              <span>{l.articleMetaShort}</span>
            </span>
          </div>
          <div className="solids-card solids-card--sm">
            <span className="solids-card__head">
              <IconBox tint="bottle" icon="feed" size={18} />
              <span>
                <span>{s.label}</span>
                <strong>{s.meal}</strong>
              </span>
            </span>
            <span className="chip-row">
              {s.foods.slice(0, 4).map((food) => (
                <Chip key={food} tint="plain" size="sm">
                  {food}
                </Chip>
              ))}
              <Chip tint="sun" size="sm">
                {s.newFood}
              </Chip>
              <Chip tint="plain" size="sm">
                {s.moreShort}
              </Chip>
            </span>
          </div>
        </div>
        <CompactBullets
          items={[
            { icon: 'search', tint: 'mint', ...l.bullets[0] },
            { icon: 'bookmark', tint: 'sleep', ...l.bullets[1] },
            { icon: 'feed', tint: 'bottle', ...l.bullets[2] },
          ]}
        />
      </div>
      <div className="split__visual only-desktop reveal">
        <Fit w={640} h={600} mobileScale={0.5234}>
          <div className="panel tint--mint" />
          <span className="search-bar pop" style={at(56, 52, { width: 528 })}>
            <Icon name="search" size={18} />
            {l.search}
            <span className="spacer" />
            <Chip tint="mint">{l.ageChip}</Chip>
          </span>
          <ArticleCard
            article={l.articles[0]}
            tone="night"
            photoHeight={130}
            style={at(56, 140, { width: 260, ['--i' as string]: 1 })}
          />
          <div
            className="solids-card pop"
            style={at(322, 150, { width: 290, ['--i' as string]: 2 })}
          >
            <span className="solids-card__head">
              <IconBox tint="bottle" icon="feed" size={18} />
              <span>
                <span>{s.label}</span>
                <strong>{s.meal}</strong>
              </span>
            </span>
            <span className="solids-card__label">{s.triedLabel}</span>
            <span className="chip-row">
              {s.foods.map((food) => (
                <Chip key={food} tint="plain" size="sm">
                  {food}
                </Chip>
              ))}
              <Chip tint="sun" size="sm" icon="spark">
                {s.newFood}
              </Chip>
              <Chip tint="plain" size="sm">
                {s.more}
              </Chip>
            </span>
          </div>
          <ArticleCard
            article={l.articles[1]}
            tone="sun"
            photoHeight={100}
            style={at(120, 360, { width: 240, ['--i' as string]: 3 })}
          />
          <Chip
            icon="bookmark"
            ink="mint"
            float
            className="chip--lg pop"
            style={at(390, 500, { ['--i' as string]: 4 })}
          >
            {l.saved}
          </Chip>
        </Fit>
      </div>
    </section>
  );
}
