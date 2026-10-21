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
const names = {
  paperGrain: 'p48-grain',
  milestoneDotRoute: 'p48-milestone-dot-route',
  milestonePaperStar: 'p48-milestone-paper-star',
  milestonePhotoCorners: 'p48-milestone-photo-corners',
  milestoneLabel: 'p48-milestone-label',
  milestoneStepOne: 'p48-milestone-step-one',
  milestoneStepNext: 'p48-milestone-step-next',
  milestoneStepPause: 'p48-milestone-step-pause',
  milestoneDateTag: 'p48-milestone-date-tag',
  milestoneFoldedEdge: 'p48-milestone-folded-edge',
  milestoneClosingRule: 'p48-milestone-closing-rule',
  discoverRoundWindow: 'p48-discover-round-window',
  discoverLeafPair: 'p48-discover-leaf-pair',
  discoverLeafSprig: 'p48-discover-leaf-sprig',
  discoverViewfinder: 'p48-discover-viewfinder',
  discoverThreeDots: 'p48-discover-three-dots',
  discoverJournalTab: 'p48-discover-journal-tab',
  discoverWideFrame: 'p48-discover-wide-frame',
  discoverEyePath: 'p48-discover-eye-path',
  discoverPaperSeeds: 'p48-discover-paper-seeds',
  discoverClosingLoop: 'p48-discover-closing-loop',
};
type Role = keyof typeof names;
export const premium48Phase6Slots = (_discover: boolean, beat: number): number[] =>
  beat >= 0 && beat < 5 ? [beat] : [];
function Motif({
  p,
  role,
  x,
  y,
  w,
  h,
  opacity = 1,
  transform,
}: {
  p: StoryProps;
  role: Role;
  x: number;
  y: number;
  w: number;
  h: number;
  opacity?: number;
  transform?: string | undefined;
}) {
  return (
    <Img
      src={p.artAssets?.[role] ?? art(names[role])}
      style={{
        position: 'absolute',
        left: x,
        top: y,
        width: w,
        height: h,
        objectFit: 'fill',
        opacity,
        transform,
      }}
    />
  );
}
function Picture({
  p,
  slot,
  beat,
  x,
  y,
  w,
  h,
  round = 0,
}: {
  p: StoryProps;
  slot: number;
  beat: number;
  x: number;
  y: number;
  w: number;
  h: number;
  round?: number;
}) {
  const src = p.photos[slot];
  if (!src) throw new Error('premium-photo-missing');
  const crop = p.presentation?.crops[beat] ?? { x: 0, y: 0, zoom: 1, fit: 'contain' };
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
        boxShadow: '0 8px 25px #37534F14',
        borderRadius: round,
        overflow: 'hidden',
      }}
    >
      <div
        style={{
          width: '100%',
          height: '100%',
          overflow: 'hidden',
          borderRadius: Math.max(0, round - 14),
        }}
      >
        <Img
          src={src}
          style={{
            width: '100%',
            height: '100%',
            objectFit: crop.fit ?? 'contain',
            objectPosition: `${(crop.x + 1) * 50}% ${(crop.y + 1) * 50}%`,
            transform: `scale(${crop.zoom})`,
            transformOrigin: `${(crop.x + 1) * 50}% ${(crop.y + 1) * 50}%`,
          }}
        />
      </div>
    </div>
  );
}
function Scene({
  p,
  beat,
  local,
  discover,
}: {
  p: StoryProps;
  beat: number;
  local: number;
  discover: boolean;
}) {
  const { width, height } = useVideoConfig(),
    story = height > 1500,
    reduced = p.presentation?.reducedMotion === true,
    copy = p.presentation?.copy ?? {},
    slots = p.presentation?.beats[beat]?.slots ?? premium48Phase6Slots(discover, beat),
    slot = slots[0]!;
  const value = copy[p.presentation?.beats[beat]?.textKey ?? `scene${beat + 1}`] ?? '',
    show = ramp(local, 18, 32),
    open = reduced ? 1 : ramp(local, 0, 17),
    top = story ? 305 : 224,
    ph = story ? 900 : 540,
    captionY = story ? 1370 : 916;
  const motif = (
    role: Role,
    x: number,
    y: number,
    w: number,
    h: number,
    opacity = 1,
    transform?: string,
  ) => <Motif p={p} role={role} x={x} y={y} w={w} h={h} opacity={opacity} transform={transform} />;
  const pic = (x: number, y: number, w: number, h: number, round = 0) => (
    <Picture p={p} slot={slot} beat={beat} x={x} y={y} w={w} h={h} round={round} />
  );
  const label = (v: string, x: number, y: number, w: number, size = 28) => (
    <div
      style={{
        position: 'absolute',
        left: x,
        top: y,
        width: w,
        fontFamily: font.sans,
        fontSize: size,
        lineHeight: 1.3,
        color: p.palette.ink,
        opacity: show,
        overflowWrap: 'anywhere',
      }}
    >
      {v}
    </div>
  );
  const square = story ? 760 : 510,
    cy = top + (ph - square) / 2;
  return (
    <AbsoluteFill style={{ background: p.palette.background }}>
      {motif('paperGrain', 0, 0, width, height, 0.03)}
      {!discover && (
        <>
          {motif('milestoneFoldedEdge', 18, top - 50, 38, ph + 160, 0.6)}
          <div
            style={{
              position: 'absolute',
              left: 96,
              top: top - 90,
              width: 888,
              height: 75,
              clipPath: `inset(0 ${reduced || beat >= 2 ? 0 : 100 * (1 - ramp(local, 0, 45))}% 0 0)`,
            }}
          >
            {motif('milestoneDotRoute', 0, 0, 888, 75)}
          </div>
          {beat < 2 && (
            <div
              style={{
                transform: `translateX(${reduced ? 0 : (beat === 0 ? -12 : 12) * (1 - open)}px)`,
              }}
            >
              {pic(110, top, 860, ph)}
              {motif('milestonePhotoCorners', 100, top - 10, 880, ph + 20)}
            </div>
          )}
          {beat === 2 && (
            <>
              {pic(96, top - 15, 888, ph + 30)}
              {motif('milestonePhotoCorners', 86, top - 25, 908, ph + 50)}
              {motif('milestoneStepPause', 870, top + ph - 64, 130, 130)}
            </>
          )}
          {beat === 3 && (
            <>
              {pic(150, top + 20, 780, ph - 40)}
              {motif('milestonePhotoCorners', 140, top + 10, 800, ph - 20)}
              {motif(
                'milestonePaperStar',
                844,
                top - 65,
                150,
                150,
                1,
                `scale(${reduced ? 1 : 0.9 + 0.1 * ramp(local, 0, 18)})`,
              )}
            </>
          )}
          {beat === 4 && (
            <>
              {pic(110, top, 860, ph - 30)}
              {motif('milestonePhotoCorners', 100, top - 10, 880, ph - 10)}
              {motif('milestoneClosingRule', 96, top + ph + 5, 888, 45, 0.8)}
            </>
          )}
          {beat < 2 &&
            motif(
              beat === 0 ? 'milestoneStepOne' : 'milestoneStepNext',
              860,
              top + ph - 64,
              130,
              130,
            )}
          {beat === 4 && (
            <>
              {motif('milestoneLabel', 96, captionY - 104, 888, 80)}
              {label(copy.label0 ?? '', 125, captionY - 82, 830)}
            </>
          )}
        </>
      )}
      {discover && (
        <>
          {motif('discoverPaperSeeds', 25, top - 110, 1030, ph + 220)}
          {beat === 0 && (
            <div
              style={{
                position: 'absolute',
                left: (width - square) / 2,
                top: cy,
                width: square,
                height: square,
                clipPath: `circle(${reduced ? 71 : 42 + 29 * open}% at 50% 50%)`,
              }}
            >
              {pic(0, 0, square, square, square / 2)}
              {motif('discoverRoundWindow', 0, 0, square, square)}
            </div>
          )}
          {beat === 1 && (
            <>
              {pic(130, top + 20, 820, ph - 40, 48)}
              {motif('discoverWideFrame', 120, top + 10, 840, ph - 20)}
              {motif(
                'discoverLeafPair',
                820,
                top + ph - 80,
                150,
                200,
                0.85,
                `translateY(${reduced ? 0 : 6 * Math.sin(local / 60)}px)`,
              )}
            </>
          )}
          {beat === 2 && (
            <>
              {pic(96, top, 888, ph, 32)}
              {motif('discoverWideFrame', 86, top - 10, 908, ph + 20)}
              {motif('discoverLeafSprig', 28, top + ph * 0.3, 80, 210, 0.6)}
            </>
          )}
          {beat === 3 && (
            <>
              <div
                style={{
                  position: 'absolute',
                  left: 96,
                  top,
                  width: 888,
                  height: ph,
                  clipPath: reduced
                    ? 'none'
                    : `inset(0 ${7 * (1 - open)}% 0 ${7 * (1 - open)}% round ${Math.min(320, ph / 2) * (1 - open)}px)`,
                }}
              >
                {pic(0, 0, 888, ph, 32)}
              </div>
              {motif('discoverWideFrame', 86, top - 10, 908, ph + 20)}
            </>
          )}
          {beat === 4 && (
            <>
              {pic((width - square) / 2, cy, square, square, square / 2)}
              {motif('discoverRoundWindow', (width - square) / 2, cy, square, square)}
              {motif('discoverClosingLoop', 320, cy + square + 28, 440, 85, 0.7)}
            </>
          )}
          {motif('discoverLeafPair', 870, 116, 110, 145, 0.8)}
          {beat !== 4 && motif('discoverEyePath', 96, captionY - 100, 888, 70, 0.75)}
        </>
      )}
      <div
        style={{
          position: 'absolute',
          left: 96,
          top: captionY,
          width: 888,
          height: 200,
          fontFamily: font.serif,
          fontSize: fitPremiumText(value, beat === 4 ? 64 : 60, 888),
          fontWeight: 600,
          lineHeight: 1.25,
          color: p.palette.ink,
          opacity: show,
          overflowWrap: 'anywhere',
        }}
      >
        {value}
      </div>
      {beat === 4 && (
        <>
          {label(copy.signature ?? '', 96, height - 260, 850)}
          {copy.label1 && label(copy.label1, 96, height - 210, 850, 26)}
        </>
      )}
    </AbsoluteFill>
  );
}
export function Premium48Phase6Story(p: StoryProps & { discover?: boolean }) {
  const frame = useCurrentFrame(),
    ready = usePremiumFonts(),
    { height } = useVideoConfig(),
    { beat, local } = premium48Frame(frame),
    next = beat < 4 && local >= 198 ? ramp(local, 198, 210) : 0;
  return (
    <AbsoluteFill style={{ background: p.palette.background }}>
      <Fonts />
      {ready && <Scene p={p} beat={beat} local={local} discover={p.discover === true} />}
      {ready && next > 0 && (
        <AbsoluteFill style={{ opacity: next }}>
          <Scene p={p} beat={beat + 1} local={0} discover={p.discover === true} />
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
