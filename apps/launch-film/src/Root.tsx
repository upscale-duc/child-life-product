import { Composition, Folder } from 'remotion';
import { Film, scenes } from './Film';
import { Fonts } from './shared';
import { Music } from './Music';
import { timeline, FPS, TOTAL_FRAMES } from './timeline';
import { IntroFilm, IntroScene } from './intro/IntroFilm';
import { films } from './intro/timeline';
export const Root = () => (
  <>
    {(['en', 'vi'] as const).map((lang) => {
      const film = films[lang];
      const tag = lang === 'en' ? '' : '-VI';
      return (
        <Folder key={lang} name={`ProductIntroV2${tag}`}>
          <Composition id={`ChildLifeIntroV2${tag}`} component={IntroFilm} width={1920} height={1080} fps={FPS} durationInFrames={film.total} defaultProps={{ lang, muted: false }} />
          {film.scenes.map((s) => (
            <Composition key={s.id} id={`${s.id}${tag}`} component={IntroScene} width={1920} height={1080} fps={FPS} durationInFrames={s.duration} defaultProps={{ id: s.id, lang }} />
          ))}
        </Folder>
      );
    })}
    <Composition
      id="ChildLifeLaunchV2"
      component={Film}
      width={1920}
      height={1080}
      fps={FPS}
      durationInFrames={TOTAL_FRAMES}
      defaultProps={{ theme: 'light' }}
    />
    <Composition
      id="ChildLifeLaunchV2Vertical"
      component={Film}
      width={1080}
      height={1920}
      fps={FPS}
      durationInFrames={TOTAL_FRAMES}
      defaultProps={{ theme: 'light' }}
    />
    <Composition
      id="ChildLifeLaunch"
      component={Film}
      width={1920}
      height={1080}
      fps={FPS}
      durationInFrames={TOTAL_FRAMES}
      defaultProps={{ theme: 'light' }}
    />
    <Composition
      id="ChildLifeLaunchVertical"
      component={Film}
      width={1080}
      height={1920}
      fps={FPS}
      durationInFrames={TOTAL_FRAMES}
      defaultProps={{ theme: 'light' }}
    />
    <Folder name="Scenes">
      {timeline.map((s, i) => {
        const C = scenes[i];
        const Preview = () => (
          <>
            <Fonts />
            <Music startAtSeconds={s.from / FPS} />
            <C />
          </>
        );
        return (
          <Composition
            key={s.id}
            id={s.id}
            component={Preview}
            width={1920}
            height={1080}
            fps={FPS}
            durationInFrames={s.duration}
          />
        );
      })}
    </Folder>
    <Folder name="Vertical">
      {timeline.map((s, i) => {
        const C = scenes[i];
        const Preview = () => (
          <>
            <Fonts />
            <Music startAtSeconds={s.from / FPS} />
            <C />
          </>
        );
        return (
          <Composition
            key={s.id}
            id={`${s.id}-Vertical`}
            component={Preview}
            width={1080}
            height={1920}
            fps={FPS}
            durationInFrames={s.duration}
          />
        );
      })}
    </Folder>
  </>
);
