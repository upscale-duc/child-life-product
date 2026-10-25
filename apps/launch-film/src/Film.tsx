import { AbsoluteFill, Series, useCurrentFrame, useVideoConfig } from 'remotion';
import { timeline } from './timeline';
import { sceneLayers } from './animation';
import { isBridge } from './Scene';
import { Fonts, LayerView } from './shared';
import { brand } from './brand';
import { S04QuickLog } from './scenes/S04QuickLog';
import { S08Lumi } from './scenes/S08Lumi';
import { S09Today } from './scenes/S09Today';
import { ThemeContext, useBrand, useTheme, type Theme } from './theme';
import { Music } from './Music';
import { S01Opening } from './scenes/S01Opening';
import { S02Intro } from './scenes/S02Intro';
import { S03Care } from './scenes/S03Care';
import { S05Grow } from './scenes/S05Grow';
import { S06Remember } from './scenes/S06Remember';
import { S07Family } from './scenes/S07Family';
import { S10Personal } from './scenes/S10Personal';
import { S11Brand } from './scenes/S11Brand';
export const scenes = [
  S01Opening,
  S02Intro,
  S03Care,
  S04QuickLog,
  S05Grow,
  S06Remember,
  S07Family,
  S08Lumi,
  S09Today,
  S10Personal,
  S11Brand,
];
export const Film = ({ theme = 'light' }: { theme?: Theme }) => (
  <ThemeContext.Provider value={theme}>
    <FilmContent />
  </ThemeContext.Provider>
);
const FilmContent = () => {
  const brand = useBrand(),
    theme = useTheme();
  const f = useCurrentFrame(),
    { width } = useVideoConfig();
  const active = timeline.find((s) => f >= s.from && f < s.from + s.duration) ?? timeline[10];
  const local = f - active.from;
  return (
    <AbsoluteFill style={{ background: brand.cloud }}>
      <Fonts />
      <Music />
      <Series>
        {timeline.map((s, i) => {
          const Component = scenes[i];
          return (
            <Series.Sequence key={s.id} name={`${s.id} ${s.name}`} durationInFrames={s.duration}>
              <Component inFilm />
            </Series.Sequence>
          );
        })}
      </Series>
      <AbsoluteFill style={{ pointerEvents: 'none', zIndex: 0 }}>
        {sceneLayers(active.id, local, width === 1080, theme)
          .filter((l) => isBridge(l.name))
          .map((l) => (
            <LayerView key={l.name} layer={l} frame={local} />
          ))}
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
