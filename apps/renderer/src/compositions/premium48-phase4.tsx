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
  chapterMonthTab: 'p48-chapter-month-tab',
  chapterIndexRail: 'p48-chapter-index-rail',
  chapterHeroFrame: 'p48-chapter-hero-frame',
  chapterSmallFrame: 'p48-chapter-small-frame',
  chapterSpine: 'p48-chapter-spine',
  chapterDivider: 'p48-chapter-divider',
  chapterCaptionStrip: 'p48-chapter-caption-strip',
  chapterCropMarks: 'p48-chapter-crop-marks',
  chapterFolio: 'p48-chapter-folio',
  chapterMastheadRule: 'p48-chapter-masthead-rule',
  compareTimeline: 'p48-compare-timeline',
  compareAnchorBefore: 'p48-compare-anchor-before',
  compareAnchorAfter: 'p48-compare-anchor-after',
  comparePhotoCorners: 'p48-compare-photo-corners',
  comparePaperWipe: 'p48-compare-paper-wipe',
  compareMatchedFrame: 'p48-compare-matched-frame',
  compareDateTag: 'p48-compare-date-tag',
  compareJoinLine: 'p48-compare-join-line',
  comparePairedBracket: 'p48-compare-paired-bracket',
  comparePaperEdge: 'p48-compare-paper-edge',
};
type Role = keyof typeof names;
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
        opacity,
        objectFit: 'fill',
        transform,
      }}
    />
  );
}
export const premium48Phase4Slots = (compare: boolean, beat: number): number[] =>
  compare
    ? ([[0], [0], [0, 1], [1], [0, 1]][beat] ?? [])
    : ([[0], [1, 0], [2], [3, 1], [4, 0, 1, 2, 3]][beat] ?? []);
function Picture({
  p,
  beat,
  slot,
  cropBeat = beat,
  local,
  x,
  y,
  w,
  h,
  extraZoom = 0,
}: {
  p: StoryProps;
  beat: number;
  slot: number;
  cropBeat?: number;
  local: number;
  x: number;
  y: number;
  w: number;
  h: number;
  extraZoom?: number;
}) {
  const src = p.photos[slot];
  if (!src) throw new Error('premium-photo-missing');
  const crop = p.presentation?.crops[cropBeat] ?? { x: 0, y: 0, zoom: 1, fit: 'contain' },
    reduced = p.presentation?.reducedMotion === true;
  const zoom = crop.zoom * (reduced ? 1 : 1 + extraZoom * ramp(local, 33, 191));
  return (
    <div
      style={{
        position: 'absolute',
        left: x,
        top: y,
        width: w,
        height: h,
        padding: 12,
        boxSizing: 'border-box',
        background: '#FFFCF8',
        boxShadow: '0 7px 22px #35434D12',
      }}
    >
      <div style={{ width: '100%', height: '100%', overflow: 'hidden' }}>
        <Img
          src={src}
          style={{
            width: '100%',
            height: '100%',
            objectFit: crop.fit ?? 'contain',
            objectPosition: `${(crop.x + 1) * 50}% ${(crop.y + 1) * 50}%`,
            transform: `scale(${zoom})`,
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
  compare,
}: {
  p: StoryProps;
  beat: number;
  local: number;
  compare: boolean;
}) {
  const { width, height } = useVideoConfig(),
    top = 192,
    ph = height - 730,
    reduced = p.presentation?.reducedMotion === true;
  const copy = p.presentation?.copy ?? {},
    slots = p.presentation?.beats[beat]?.slots ?? premium48Phase4Slots(compare, beat),
    primary = slots[0] ?? 0;
  const value = copy[p.presentation?.beats[beat]?.textKey ?? `scene${beat + 1}`] ?? '',
    show = ramp(local, 18, 32),
    progress = reduced ? 1 : ramp(local, 0, 17);
  const motif = (
    role: Role,
    x: number,
    y: number,
    w: number,
    h: number,
    opacity = 1,
    transform?: string,
  ) => <Motif p={p} role={role} x={x} y={y} w={w} h={h} opacity={opacity} transform={transform} />;
  const picture = (
    slot: number,
    x: number,
    y: number,
    w: number,
    h: number,
    cropBeat = beat,
    extraZoom = 0,
  ) => (
    <Picture
      p={p}
      beat={beat}
      slot={slot}
      cropBeat={cropBeat}
      local={local}
      x={x}
      y={y}
      w={w}
      h={h}
      extraZoom={extraZoom}
    />
  );
  const dateLabel = (slot: number, x: number, y: number, w: number) => (
    <div
      style={{
        position: 'absolute',
        left: x,
        top: y,
        width: w,
        fontFamily: font.sans,
        fontSize: 28,
        lineHeight: 1.3,
        color: p.palette.ink,
        opacity: show,
        overflowWrap: 'anywhere',
      }}
    >
      {copy[slot === 0 ? 'photoLabel0' : 'photoLabel1']}
    </div>
  );
  const pairH = Math.min(ph - 70, 760),
    pairY = top + (ph - 70 - pairH) / 2;
  const pair = () => (
    <>
      {picture(0, 74, pairY, 402, pairH, beat === 4 ? 4 : 2)}
      {picture(1, 604, pairY, 402, pairH, 3)}
      {motif('compareMatchedFrame', 74, pairY, 402, pairH)}
      {motif('compareMatchedFrame', 604, pairY, 402, pairH)}
      {dateLabel(0, 88, pairY + pairH + 18, 384)}
      {dateLabel(1, 618, pairY + pairH + 18, 384)}
      <div
        style={{
          position: 'absolute',
          left: 488,
          top: pairY + pairH * 0.42,
          width: 104,
          textAlign: 'center',
          color: p.palette.ink,
          fontFamily: font.sans,
          fontSize: 30,
          lineHeight: 1.4,
          opacity: show,
        }}
      >
        {copy.detail1}
        <br />
        {copy.detail2}
      </div>
    </>
  );
  const centerCaption = !compare && beat === 3;
  const captionY = centerCaption ? height / 2 - 82 : height - 425;
  return (
    <AbsoluteFill style={{ background: p.palette.background }}>
      {motif('paperGrain', 0, 0, width, height, 0.035)}
      {!compare && (
        <>
          {motif('chapterIndexRail', 28, top - 25, 40, ph + 75, 0.45)}
          {beat === 0 && (
            <>
              {picture(primary, 96, top, 888, ph)}
              {motif('chapterHeroFrame', 84, top - 12, 912, ph + 24)}
              {!reduced && local < 18 && (
                <svg
                  width={888}
                  height={ph}
                  viewBox={`0 0 888 ${ph}`}
                  style={{ position: 'absolute', left: 96, top, opacity: 1 - progress }}
                >
                  <defs>
                    <mask id="p48-month-opening">
                      <rect width="888" height={ph} fill="white" />
                      <text
                        x="444"
                        y={ph * 0.78}
                        fontFamily={font.serif}
                        fontWeight="600"
                        fontSize={Math.min(ph * 0.9, 680)}
                        textAnchor="middle"
                        fill="black"
                      >
                        {copy.month ?? ''}
                      </text>
                    </mask>
                  </defs>
                  <rect
                    width="888"
                    height={ph}
                    fill={p.palette.background}
                    mask="url(#p48-month-opening)"
                  />
                </svg>
              )}
            </>
          )}
          {beat === 1 && (
            <>
              {picture(primary, 96, top, 570, ph)}
              {picture(
                slots[1] ?? 0,
                96 + (704 - 96) * progress,
                top,
                888 + (280 - 888) * progress,
                ph + (ph * 0.46 - ph) * progress,
                0,
              )}
              {motif('chapterSmallFrame', 694, top - 10, 300, ph * 0.46 + 20)}
              {motif('chapterCaptionStrip', 704, top + ph * 0.55, 280, ph * 0.25)}
              <div
                style={{
                  position: 'absolute',
                  left: 729,
                  top: top + ph * 0.6,
                  width: 225,
                  fontSize: 30,
                  fontFamily: font.sans,
                  color: p.palette.ink,
                  opacity: show,
                }}
              >
                {p.locale === 'en' ? 'THE EVERYDAY' : 'NHỮNG ĐIỀU QUEN'}
              </div>
            </>
          )}
          {beat === 2 && (
            <>
              {picture(
                primary,
                704 + (96 - 704) * progress,
                top,
                280 + (888 - 280) * progress,
                ph * 0.46 + (ph - ph * 0.46) * progress,
              )}
              {motif('chapterHeroFrame', 84, top - 12, 912, ph + 24, progress)}
              {motif('chapterCropMarks', 78, top - 18, 924, ph + 36)}
            </>
          )}
          {beat === 3 && (
            <>
              {picture(primary, 96, 190, 650, height / 2 - 310)}
              {picture(slots[1] ?? 1, 334, height / 2 + 150, 650, height / 2 - 310, 1)}
              {motif('chapterDivider', 96, height / 2 - 116, 888, 52)}
              {motif('chapterDivider', 96, height / 2 + 102, 888, 52)}
            </>
          )}
          {beat === 4 && (
            <>
              {picture(primary, 96, top, 550, ph)}
              {[0, 1, 2, 3].map((i) => (
                <Picture
                  key={i}
                  p={p}
                  beat={beat}
                  slot={slots[i + 1] ?? i}
                  cropBeat={i}
                  local={local}
                  x={674 + (i % 2) * 158}
                  y={top + Math.floor(i / 2) * (ph / 2 + 10)}
                  w={148}
                  h={ph / 2 - 10}
                />
              ))}
              {motif(
                'chapterSpine',
                48,
                top - 12,
                30,
                ph + 24,
                0.75,
                `translateX(${reduced ? 0 : 8 * ramp(local, 0, 35)}px)`,
              )}
              {motif('chapterFolio', 930, top + ph - 42, 96, 84)}
            </>
          )}
          {motif('chapterMonthTab', 856, 108, 144, 110)}
          <div
            style={{
              position: 'absolute',
              left: 874,
              top: 128,
              width: 108,
              textAlign: 'center',
              fontFamily: font.serif,
              fontSize: 54,
              fontWeight: 600,
              color: '#FFFCF6',
              opacity: show,
            }}
          >
            {copy.month}
          </div>
        </>
      )}
      {compare && (
        <>
          {motif('comparePaperEdge', 20, top - 20, 42, ph + 70, 0.45)}
          {beat === 0 && (
            <>
              {picture(0, 96, top, 700, ph)}
              {motif('comparePhotoCorners', 84, top - 12, 724, ph + 24)}
              {motif('compareAnchorBefore', 842, top + ph * 0.33, 130, 130)}
              {dateLabel(0, 110, top + ph + 20, 700)}
            </>
          )}
          {beat === 1 && (
            <>
              {picture(0, 96, top, 700, ph, 1, 0.02)}
              {motif('comparePhotoCorners', 84, top - 12, 724, ph + 24)}
              {dateLabel(0, 110, top + ph + 20, 700)}
              {motif('comparePairedBracket', 829, top + ph * 0.2, 145, 90)}
            </>
          )}
          {beat === 2 && (
            <>
              {pair()}
              <div
                style={{
                  position: 'absolute',
                  left: 498,
                  top: top + ph * 0.12,
                  width: 84,
                  height: ph * 0.25,
                  clipPath: `inset(0 0 ${reduced ? 0 : 100 * (1 - ramp(local, 0, 45))}% 0)`,
                }}
              >
                {motif('compareJoinLine', 0, 0, 84, ph * 0.25)}
              </div>
            </>
          )}
          {beat === 3 && (
            <>
              {picture(1, 96, top, 888, ph)}
              {!reduced && local < 18 && (
                <div
                  style={{
                    position: 'absolute',
                    left: 96,
                    top,
                    width: 888,
                    height: ph,
                    clipPath: `inset(0 0 0 ${progress * 100}%)`,
                  }}
                >
                  {picture(0, 0, 0, 888, ph, 0)}
                  {motif('comparePaperWipe', 0, 0, 888, ph, 0.72)}
                </div>
              )}
              {motif('comparePhotoCorners', 84, top - 12, 912, ph + 24)}
              {dateLabel(1, 110, top + ph + 20, 840)}
            </>
          )}
          {beat === 4 && (
            <>
              {pair()}
              {motif('compareTimeline', 96, pairY + pairH + 100, 888, 60, 0.6)}
            </>
          )}
        </>
      )}
      <div
        style={{
          position: 'absolute',
          left: 96,
          top: captionY,
          width: width - 192,
          height: 180,
          fontFamily: font.serif,
          fontSize: fitPremiumText(value, beat === 4 ? 68 : centerCaption ? 56 : 62, width - 192),
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
        <div
          style={{
            position: 'absolute',
            left: 96,
            top: height - 250,
            width: 888,
            fontFamily: font.sans,
            fontSize: 28,
            lineHeight: 1.3,
            color: p.palette.ink,
            opacity: show,
          }}
        >
          {copy.signature}
          {copy.detail0 && <> · {copy.detail0}</>}
        </div>
      )}
    </AbsoluteFill>
  );
}
export function Premium48Phase4Story(p: StoryProps & { compare?: boolean }) {
  const frame = useCurrentFrame(),
    ready = usePremiumFonts(),
    { height } = useVideoConfig(),
    { beat, local } = premium48Frame(frame),
    next = beat < 4 && local >= 198 ? ramp(local, 198, 210) : 0;
  return (
    <AbsoluteFill style={{ background: p.palette.background }}>
      <Fonts />
      {ready && <Scene p={p} beat={beat} local={local} compare={p.compare === true} />}
      {ready && next > 0 && (
        <AbsoluteFill style={{ opacity: next }}>
          <Scene p={p} beat={beat + 1} local={0} compare={p.compare === true} />
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
