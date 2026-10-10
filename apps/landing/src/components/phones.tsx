import type { CSSProperties, ReactNode } from 'react';
import { useSite } from '../context';
import type { CareKind } from '../content/types';
import { CareTile } from './mock';
import { Art, Icon, Photo, art, type PhotoTone } from './primitives';

/** Hero phones (spec §2). Figma uses raster snapshots of the Today (7a) and Album (10d) screens;
 *  they are rebuilt here at 375 pt so the English page is localized and the hero stays light. */

export function Phone({
  width,
  height,
  radius,
  screenRadius,
  children,
  style,
  className,
}: {
  width: number;
  height: number;
  radius: number;
  screenRadius: number;
  children: ReactNode;
  style?: CSSProperties;
  className?: string;
}) {
  const screenWidth = width - 16;
  return (
    <div
      className={className ? `phone ${className}` : 'phone'}
      style={{ width, height, borderRadius: radius, ...style }}
    >
      <div
        className="phone__screen"
        style={{ borderRadius: screenRadius, width: screenWidth, height: height - 16 }}
      >
        <div className="app-screen" style={{ transform: `scale(${screenWidth / 375})` }}>
          {children}
        </div>
      </div>
    </div>
  );
}

function StatusBar() {
  return (
    <div className="app-status">
      <span>9:41</span>
      <span className="app-status__dots">•••</span>
    </div>
  );
}

function BabyPill() {
  const { c } = useSite();
  return (
    <span className="app-baby">
      <Art src={art.babyFace} size={30} eager />
      <span>{c.mock.babyAge}</span>
      <Icon name="chevron-down" size={16} />
    </span>
  );
}

export function TodayScreen() {
  const { c } = useSite();
  const t = c.hero.today;
  const kinds: CareKind[] = ['bottle', 'breast', 'sleep', 'diaper', 'pump', 'growth'];
  return (
    <>
      <StatusBar />
      <div className="app-top">
        <BabyPill />
        <span className="app-round">
          <Icon name="sleep" size={20} />
        </span>
      </div>
      <div className="app-heading">
        <span className="app-date">{c.mock.date}</span>
        <span className="app-title">{t.title}</span>
      </div>
      <div className="app-tiles">
        {kinds.map((kind) => (
          <CareTile key={kind} kind={kind} text={t.tiles[kind]} />
        ))}
      </div>
      <div className="app-reminder">
        <span className="app-reminder__icon">
          <Icon name="clock" size={20} />
        </span>
        <span className="app-reminder__text">
          <span className="app-caption">{t.reminder.label}</span>
          <span className="app-reminder__title">{t.reminder.title}</span>
          <span className="app-caption">{t.reminder.when}</span>
        </span>
        <Icon name="chevron-right" size={18} />
      </div>
      <div className="app-section">
        <span>{t.section.title}</span>
        <span className="app-section__link">{t.section.link}</span>
      </div>
      <div className="app-peek" />
    </>
  );
}

export function AlbumScreen() {
  const { c } = useSite();
  const a = c.hero.album;
  const tones: PhotoTone[] = ['peach', 'sand', 'sun', 'leaf'];
  return (
    <>
      <StatusBar />
      <div className="app-top">
        <BabyPill />
        <span className="app-top__spacer" />
        <span className="app-round">
          <Icon name="sliders" size={20} />
        </span>
        <span className="app-round app-round--primary">
          <Icon name="plus" size={22} />
        </span>
      </div>
      <span className="app-title app-title--album">{a.title}</span>
      <div className="app-album-bar">
        <span>{a.count}</span>
        <span className="app-album-bar__new">
          <Icon name="plus" size={16} />
          {a.newAlbum}
        </span>
      </div>
      <div className="app-albums">
        {a.albums.map((album, i) => (
          <div key={album.name} className="app-album">
            <span className="app-album__cover">
              <Photo tone={tones[i]!} eager />
              <span className="app-album__badge">
                <Icon name={album.shared ? 'family' : 'lock'} size={15} />
              </span>
            </span>
            <span className="app-album__name">{album.name}</span>
            <span className="app-caption">{album.meta}</span>
          </div>
        ))}
      </div>
      <div className="app-segments">
        {a.segments.map((segment, i) => (
          <span key={segment} className={i === 2 ? 'is-active' : undefined}>
            {segment}
          </span>
        ))}
      </div>
      <div className="app-nav">
        <Icon name="today" size={22} />
        <span className="app-nav__active">
          <Icon name="memories" size={20} />
          {a.navActive}
        </span>
        <Icon name="family" size={22} />
        <span className="app-nav__me">{a.navInitial}</span>
      </div>
    </>
  );
}
