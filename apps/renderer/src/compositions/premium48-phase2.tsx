import {
  AbsoluteFill,
  Audio,
  Easing,
  Img,
  interpolate,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion';
import { BrandLogo, Fonts, art, clamp, font, type StoryProps } from '../kit/core';
import { fitPremiumText, premium48Frame, usePremiumFonts } from './premium48';

const ramp = (f: number, a: number, b: number) =>
  interpolate(f, [a, b], [0, 1], { ...clamp, easing: Easing.bezier(0.22, 1, 0.36, 1) });
const assetNames = {
  paperGrain: 'p48-grain',
  homeHouse: 'p48-home-house',
  homeKey: 'p48-home-key',
  homeRoute: 'p48-home-route',
  homeDoorLeft: 'p48-home-door-left',
  homeDoorRight: 'p48-home-door-right',
  homeWindow: 'p48-home-window',
  homeTag: 'p48-home-tag',
  homeEnvelope: 'p48-home-envelope',
  homePlant: 'p48-home-plant',
  homeRoofFrame: 'p48-home-roof-frame',
  scrapWashiRipped: 'p48-scrap-washi-ripped',
  scrapWashiGrid: 'p48-scrap-washi-grid',
  scrapCornerFold: 'p48-scrap-corner-fold',
  scrapTab: 'p48-scrap-tab',
  scrapMonthOne: 'p48-scrap-month-one',
  scrapPencilLoop: 'p48-scrap-pencil-loop',
  scrapPhotoCorners: 'p48-scrap-photo-corners',
  scrapEnvelope: 'p48-scrap-envelope',
  scrapPaperStrip: 'p48-scrap-paper-strip',
  scrapStitches: 'p48-scrap-stitches',
};
type Role = keyof typeof assetNames;
function Motif({
  p,
  role,
  x,
  y,
  w,
  h,
  rotate = 0,
  opacity = 1,
  scaleX = 1,
}: {
  p: StoryProps;
  role: Role;
  x: number;
  y: number;
  w: number;
  h: number;
  rotate?: number;
  opacity?: number;
  scaleX?: number;
}) {
  return (
    <Img
      src={p.artAssets?.[role] ?? art(assetNames[role])}
      style={{
        position: 'absolute',
        left: x,
        top: y,
        width: w,
        height: h,
        opacity,
        transform: `rotate(${rotate}deg) scaleX(${scaleX})`,
        objectFit: 'fill',
      }}
    />
  );
}

function Picture({
  p,
  slot,
  beat,
  local,
  x,
  y,
  w,
  h,
  rotate = 0,
  arch = false,
  house = false,
}: {
  p: StoryProps;
  slot: number;
  beat: number;
  local: number;
  x: number;
  y: number;
  w: number;
  h: number;
  rotate?: number;
  arch?: boolean;
  house?: boolean;
}) {
  const src = p.photos[slot];
  if (!src) throw new Error('premium-photo-missing');
  const reduced = p.presentation?.reducedMotion === true;
  const sourceBeat = p.presentation?.beats.findIndex((b) => b.slots[0] === slot) ?? beat;
  const crop = p.presentation?.crops[sourceBeat < 0 ? beat : sourceBeat] ?? {
    x: 0,
    y: 0,
    zoom: 1,
    fit: 'contain',
  };
  const enter = ramp(local, 0, 17);
  return (
    <div
      style={{
        position: 'absolute',
        left: x,
        top: y,
        width: w,
        height: h,
        padding: 14,
        boxSizing: 'border-box',
        background: '#FFFDF8',
        boxShadow: '0 8px 24px #403A3112',
        transform: `translateY(${reduced ? 0 : 20 * (1 - enter)}px) rotate(${reduced ? 0 : rotate}deg)`,
        borderRadius: '3px',
        clipPath: arch
          ? `path("M ${w * 0.065} ${h * 0.95} V ${h * 0.38} C ${w * 0.065} ${h * -0.04} ${w * 0.935} ${h * -0.04} ${w * 0.935} ${h * 0.38} V ${h * 0.95} Z")`
          : house
            ? 'polygon(50% 4%,92% 34%,92% 93%,8% 93%,8% 34%)'
            : undefined,
      }}
    >
      <div
        style={{
          width: '100%',
          height: '100%',
          overflow: 'hidden',
          borderRadius: '1px',
          background: p.palette.background,
        }}
      >
        <Img
          src={src}
          style={{
            width: '100%',
            height: '100%',
            objectFit: crop.fit ?? 'contain',
            objectPosition: `${(crop.x + 1) * 50}% ${(crop.y + 1) * 50}%`,
            transform: `scale(${crop.zoom * (reduced ? 1 : 1 + 0.025 * ramp(local, 0, 191))})`,
          }}
        />
      </div>
    </div>
  );
}

export function premium48Phase2Slots(month: boolean, beat: number): number[] {
  return month ? ([[0], [1, 0], [2, 1], [3, 2, 1], [4]][beat] ?? []) : [beat];
}

function Scene({
  p,
  beat,
  local,
  month,
}: {
  p: StoryProps;
  beat: number;
  local: number;
  month: boolean;
}) {
  const { width, height } = useVideoConfig();
  const top = 192,
    ph = height - 712;
  const reduced = p.presentation?.reducedMotion === true;
  const spec = p.presentation?.beats[beat];
  const slots = spec?.slots ?? premium48Phase2Slots(month, beat);
  const primary = slots[0] ?? beat;
  const copy = p.presentation?.copy ?? {};
  const text = copy[spec?.textKey ?? `scene${beat + 1}`] ?? '';
  const opacity = ramp(local, 18, 32);
  const size = fitPremiumText(text, beat === 4 ? 72 : 64, width - 192);
  const picture = (
    slot: number,
    x: number,
    y: number,
    w: number,
    h: number,
    rotate = 0,
    arch = false,
  ) => (
    <Picture
      key={slot}
      p={p}
      slot={slot}
      beat={beat}
      local={local}
      x={x}
      y={y}
      w={w}
      h={h}
      rotate={rotate}
      arch={arch}
    />
  );
  const motif = (
    role: Role,
    x: number,
    y: number,
    w: number,
    h: number,
    rotate = 0,
    opacity = 1,
  ) => (
    <Motif
      p={p}
      role={role}
      x={x}
      y={y}
      w={w}
      h={h}
      rotate={reduced ? 0 : rotate}
      opacity={opacity}
    />
  );
  return (
    <AbsoluteFill style={{ background: p.palette.background }}>
      {motif('paperGrain', 0, 0, width, height, 0, 0.035)}
      {!month && (
        <>
          {beat === 0 && (
            <>
              {picture(primary, 110, top + 40, 860, ph - 80, -1)}
              {motif('homeHouse', 842, top - 68, 130, 123)}
              {motif('homeTag', 105, top - 44, 350, 137)}
              <div
                style={{
                  position: 'absolute',
                  left: 198,
                  top: top + 3,
                  width: 240,
                  color: p.palette.accent,
                  fontFamily: font.sans,
                  fontSize: 24,
                  opacity,
                }}
              >
                {copy.detail0 ?? (p.locale === 'en' ? 'WELCOME HOME' : 'ĐƯA CON VỀ NHÀ')}
              </div>
            </>
          )}
          {beat === 1 && (
            <>
              {picture(primary, 164, top, 752, ph - 100, 1)}
              <div
                style={{
                  position: 'absolute',
                  left: 96,
                  top: top + ph - 138,
                  width: 888,
                  height: 220,
                  clipPath: `inset(0 ${reduced ? 0 : 100 * (1 - ramp(local, 0, 65))}% 0 0)`,
                }}
              >
                {motif('homeRoute', 0, 0, 888, 220)}
              </div>
              {motif('homeKey', 36, top + 20, 188, 82, -15)}
            </>
          )}
          {beat === 2 && (
            <>
              {picture(primary, 180, top, 720, ph, 0, true)}
              <Motif
                p={p}
                role="homeDoorLeft"
                x={54}
                y={top + 35}
                w={104}
                h={ph - 35}
                scaleX={reduced ? 1 : 1 - 0.9 * ramp(local, 0, 24)}
              />
              <Motif
                p={p}
                role="homeDoorRight"
                x={922}
                y={top + 35}
                w={104}
                h={ph - 35}
                scaleX={reduced ? 1 : 1 - 0.9 * ramp(local, 0, 24)}
              />
              {motif('homePlant', 890, top + ph - 140, 115, 181)}
            </>
          )}
          {beat === 3 && (
            <>
              {picture(primary, 122, top - 12, 836, ph + 30, 0, true)}
              {motif('homeWindow', 122, top - 12, 836, ph + 30)}
              {motif('homeEnvelope', 30, top + ph - 106, 190, 122, -5)}
            </>
          )}
          {beat === 4 && (
            <>
              <Picture
                p={p}
                slot={primary}
                beat={beat}
                local={local}
                x={113}
                y={top - 20}
                w={854}
                h={ph + 72}
                house
              />
              {motif('homeRoofFrame', 113, top - 20, 854, ph + 72)}
              <div
                style={{
                  transform: `translateY(${reduced ? 0 : -18 * (1 - ramp(local, 0, 35))}px)`,
                }}
              >
                {motif('homeKey', 842, top + ph - 14, 164, 72, 8)}
              </div>
            </>
          )}
        </>
      )}
      {month && (
        <>
          {motif('scrapStitches', 28, top - 28, 24, ph + 80, 0, 0.45)}
          {motif('scrapCornerFold', 952, 42, 100, 100)}
          {beat === 0 && (
            <>
              {picture(primary, 140, top + 36, 800, ph - 50, -2)}
              {motif('scrapWashiRipped', 336, top + 5, 350, 84, -5)}
              {motif('scrapTab', 116, top - 56, 310, 120)}
            </>
          )}
          {beat === 1 && (
            <>
              {picture(slots[1] ?? 0, 96, top + 28, 432, ph * 0.68, -4)}
              {picture(primary, 278, top + 54, 690, ph * 0.88, 3)}
              {motif('scrapWashiGrid', 442, top + 18, 300, 82, 8)}
              {motif('scrapPhotoCorners', 278, top + 54, 690, ph * 0.88, 3)}
            </>
          )}
          {beat === 2 && (
            <>
              {picture(slots[1] ?? 1, 76, top + 54, 360, ph * 0.66, -3)}
              {picture(primary, 451, top, 556, ph * 0.88, 2)}
              {motif('scrapWashiRipped', 320, top + ph * 0.35, 260, 63, -14)}
              {motif('scrapPencilLoop', 122, top + ph - 60, 760, 150, 0, 0.65)}
            </>
          )}
          {beat === 3 && (
            <>
              {picture(primary, 80, top + 30, 620, ph * 0.9, -2)}
              {picture(slots[1] ?? 2, 721, top + 45, 282, ph * 0.43, 3)}
              {picture(slots[2] ?? 1, 724, top + ph * 0.5 + 30, 272, ph * 0.4, -2)}
              {motif('scrapWashiGrid', 778, top + 20, 170, 46, 6)}
              {motif('scrapEnvelope', 34, top + ph - 76, 160, 107, -6)}
            </>
          )}
          {beat === 4 && (
            <>
              {picture(primary, 168, top + 34, 744, ph - 34, -1)}
              {motif('scrapPhotoCorners', 168, top + 34, 744, ph - 34, -1)}
              {motif('scrapMonthOne', 64, top - 44, 190, 170)}
            </>
          )}
          {beat === 0 && (
            <div
              style={{
                position: 'absolute',
                left: 143,
                top: top - 22,
                width: 266,
                color: p.palette.ink,
                fontFamily: font.sans,
                fontSize: 24,
                opacity,
              }}
            >
              {p.locale === 'en' ? 'OUR FIRST MONTH' : 'THÁNG ĐẦU BÊN CON'}
            </div>
          )}
          {motif('scrapPaperStrip', 62, height - 453, 956, 180, 0, 0.95)}
        </>
      )}
      <div
        style={{
          position: 'absolute',
          left: 96,
          top: height - 432,
          width: width - 192,
          color: p.palette.ink,
          fontFamily: font.serif,
          fontWeight: 600,
          fontSize: size,
          lineHeight: 1.25,
          opacity,
          transform: `translateY(${reduced ? 0 : 12 * (1 - opacity)}px)`,
        }}
      >
        {text}
      </div>
      {beat === 4 && copy.detail0 && (
        <div
          style={{
            position: 'absolute',
            left: 96,
            top: height - 250,
            width: width - 192,
            color: p.palette.accent,
            fontFamily: font.sans,
            fontSize: 28,
            lineHeight: 1.3,
            opacity,
          }}
        >
          {copy.detail0}
        </div>
      )}
    </AbsoluteFill>
  );
}

export function Premium48Phase2Story(p: StoryProps & { month?: boolean }) {
  const frame = useCurrentFrame();
  const ready = usePremiumFonts();
  const { height } = useVideoConfig();
  const { beat, local } = premium48Frame(frame);
  const nextOpacity = beat < 4 && local >= 198 ? ramp(local, 198, 210) : 0;
  return (
    <AbsoluteFill style={{ background: p.palette.background }}>
      <Fonts />
      {ready && <Scene p={p} beat={beat} local={local} month={p.month === true} />}
      {ready && nextOpacity > 0 && (
        <AbsoluteFill style={{ opacity: nextOpacity }}>
          <Scene p={p} beat={beat + 1} local={0} month={p.month === true} />
        </AbsoluteFill>
      )}
      {p.brand?.corner && beat < 4 && (
        <div style={{ position: 'absolute', left: 96, top: 80 }}>
          <BrandLogo width={190} color={p.palette.ink} opacity={p.brand.opacity} />
        </div>
      )}
      {p.brand?.endCard && beat === 4 && (
        <div style={{ position: 'absolute', left: 96, top: height - 148 }}>
          <BrandLogo
            width={260}
            color={p.palette.ink}
            opacity={p.brand.opacity * ramp(local, 18, 32)}
          />
        </div>
      )}
      {p.music && (
        <Audio
          src={p.music}
          volume={(f) => interpolate(f, [0, 12, 1014, 1049], [0, 1, 1, 0], clamp)}
        />
      )}
    </AbsoluteFill>
  );
}
