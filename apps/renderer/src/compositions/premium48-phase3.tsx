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
  observeHand: 'p48-observe-hand',
  observeFoot: 'p48-observe-foot',
  observeStar: 'p48-observe-star',
  observeFavoriteLabel: 'p48-observe-favorite-label',
  observeDetailLabel: 'p48-observe-detail-label',
  observeMemoryLabel: 'p48-observe-memory-label',
  observeOvalFrame: 'p48-observe-oval-frame',
  observeInkDots: 'p48-observe-ink-dots',
  observePencilRule: 'p48-observe-pencil-rule',
  observeMarginBracket: 'p48-observe-margin-bracket',
  letterEnvelopeBack: 'p48-letter-envelope-back',
  letterEnvelopeFront: 'p48-letter-envelope-front',
  letterEnvelopeFlap: 'p48-letter-envelope-flap',
  letterWaxSeal: 'p48-letter-wax-seal',
  letterRuledPaper: 'p48-letter-ruled-paper',
  letterPostageFrame: 'p48-letter-postage-frame',
  letterRibbon: 'p48-letter-ribbon',
  letterFold: 'p48-letter-fold',
  letterMonogramFrame: 'p48-letter-monogram-frame',
  letterClosingRule: 'p48-letter-closing-rule',
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
        objectFit: 'fill',
        opacity,
        transform,
      }}
    />
  );
}
function Picture({
  p,
  beat,
  local,
  x,
  y,
  w,
  h,
  oval = false,
  slide = false,
}: {
  p: StoryProps;
  beat: number;
  local: number;
  x: number;
  y: number;
  w: number;
  h: number;
  oval?: boolean;
  slide?: boolean;
}) {
  const slot = p.presentation?.beats[beat]?.slots[0] ?? beat,
    src = p.photos[slot];
  if (!src) throw new Error('premium-photo-missing');
  const crop = p.presentation?.crops[beat] ?? { x: 0, y: 0, zoom: 1, fit: 'contain' },
    reduced = p.presentation?.reducedMotion === true;
  return (
    <div
      style={{
        position: 'absolute',
        left: x,
        top: y,
        width: w,
        height: h,
        padding: oval ? 0 : 12,
        boxSizing: 'border-box',
        background: oval ? p.palette.background : '#FFFDF9',
        borderRadius: oval ? '50%' : 3,
        overflow: 'hidden',
        transform: `translateY(${!reduced && slide ? 36 * (1 - ramp(local, 0, 17)) : 0}px)`,
        boxShadow: oval ? undefined : '0 9px 25px #47372F10',
      }}
    >
      <div
        style={{
          width: '100%',
          height: '100%',
          overflow: 'hidden',
          borderRadius: oval ? '50%' : 0,
        }}
      >
        <Img
          src={src}
          style={{
            width: '100%',
            height: '100%',
            objectFit: crop.fit ?? 'contain',
            objectPosition: `${(crop.x + 1) * 50}% ${(crop.y + 1) * 50}%`,
            transform: `scale(${crop.zoom * (reduced ? 1 : 1 + 0.018 * ramp(local, 33, 191))})`,
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
  letter,
}: {
  p: StoryProps;
  beat: number;
  local: number;
  letter: boolean;
}) {
  const { width, height } = useVideoConfig(),
    ph = height - 720,
    top = 192;
  const copy = p.presentation?.copy ?? {},
    reduced = p.presentation?.reducedMotion === true;
  const value = copy[p.presentation?.beats[beat]?.textKey ?? `scene${beat + 1}`] ?? '';
  const show = ramp(local, 18, 32),
    size = fitPremiumText(value, beat === 4 ? 68 : 62, width - 192);
  const motif = (
    role: Role,
    x: number,
    y: number,
    w: number,
    h: number,
    opacity = 1,
    transform?: string,
  ) => <Motif p={p} role={role} x={x} y={y} w={w} h={h} opacity={opacity} transform={transform} />;
  const picture = (x: number, y: number, w: number, h: number, oval = false, slide = false) => (
    <Picture p={p} beat={beat} local={local} x={x} y={y} w={w} h={h} oval={oval} slide={slide} />
  );
  const label = (i: number, x: number, y: number, w: number, h: number, entry = true) => {
    const key = ['favorite', 'detail', 'memory'][i]!,
      text = copy[key] ?? '',
      role = (['observeFavoriteLabel', 'observeDetailLabel', 'observeMemoryLabel'] as const)[i]!;
    if (typeof document !== 'undefined') {
      const ctx = document.createElement('canvas').getContext('2d');
      if (ctx) {
        ctx.font = `28px ${font.sans}`;
        let line = '',
          count = 1;
        for (const word of text.split(/\s+/)) {
          if (ctx.measureText(word).width > 208) throw new Error('personalization-note-overflow');
          const next = line ? `${line} ${word}` : word;
          if (ctx.measureText(next).width > 208) {
            count++;
            line = word;
          } else line = next;
        }
        if (count > 2) throw new Error('personalization-note-overflow');
      }
    }
    const move = reduced || !entry ? 0 : (i === 1 ? -24 : 24) * (1 - ramp(local, 0, 17));
    return (
      <div
        key={key}
        style={{
          position: 'absolute',
          left: x,
          top: y,
          width: w,
          height: h,
          opacity: entry ? show : 1,
          transform: `translateX(${move}px)`,
        }}
      >
        {motif(role, 0, 0, w, h)}
        {motif((['observeHand', 'observeFoot', 'observeStar'] as const)[i]!, w - 49, 12, 34, 40)}
        <div
          style={{
            position: 'absolute',
            left: 22,
            top: 24,
            width: w - 62,
            color: p.palette.ink,
            fontFamily: font.sans,
            fontSize: 28,
            lineHeight: 1.3,
            overflowWrap: 'anywhere',
          }}
        >
          {text}
        </div>
      </div>
    );
  };
  return (
    <AbsoluteFill style={{ background: p.palette.background }}>
      {motif('paperGrain', 0, 0, width, height, 0.035)}
      {!letter && (
        <>
          {motif('observeInkDots', 760, 110, 200, 90, 0.5)}
          {beat === 0 && (
            <>
              {picture(166, top, 748, ph, true)}
              {motif('observeOvalFrame', 148, top - 16, 784, ph + 32)}
              {motif('observeStar', 86, top + ph - 92, 110, 110)}
              <div
                style={{
                  position: 'absolute',
                  left: 96,
                  top: height - 480,
                  fontFamily: font.sans,
                  fontSize: 28,
                  color: p.palette.ink,
                  opacity: show,
                }}
              >
                {p.locale === 'en' ? 'YOU, THIS MONTH' : 'CON CỦA THÁNG NÀY'}
              </div>
            </>
          )}
          {beat === 1 && (
            <>
              {picture(100, top + 12, 620, ph - 24, true)}
              {motif('observeOvalFrame', 85, top - 2, 650, ph + 4)}
              {label(0, 719, top + ph * 0.32, 280, 194)}
              {motif('observeMarginBracket', 740, top + ph * 0.55, 100, ph * 0.3)}
            </>
          )}
          {beat === 2 && (
            <>
              {picture(370, top + 12, 610, ph - 24, true)}
              {motif('observeOvalFrame', 355, top - 2, 640, ph + 4)}
              {label(1, 70, top + ph * 0.3, 290, 210)}
              {motif('observeFoot', 92, top + ph * 0.7, 80, 112)}
            </>
          )}
          {beat === 3 && (
            <>
              {picture(96, top, width - 192, ph, false, true)}
              {label(0, 108, top + ph + 12, 270, 112, false)}
              {label(1, 405, top + ph + 12, 270, 112, false)}
              {motif('observeStar', 889, top - 50, 100, 100)}
            </>
          )}
          {beat === 4 && (
            <>
              {picture(85, top + 12, 565, ph - 24, true)}
              {motif('observeOvalFrame', 70, top - 2, 595, ph + 4)}
              {[0, 1, 2].map((i) => label(i, 682, top + 12 + (i * (ph - 196)) / 2, 320, 172))}
              {motif('observePencilRule', 100, top + ph + 24, 850, 70)}
            </>
          )}
        </>
      )}
      {letter && (
        <>
          {motif('letterRuledPaper', 60, 145, width - 120, height - 360)}
          {beat === 0 && (
            <>
              {motif('letterEnvelopeBack', 126, top + ph * 0.48, 828, ph * 0.55)}
              {picture(216, top + 20, 648, ph * 0.78, false, true)}
              {motif('letterEnvelopeFront', 126, top + ph * 0.77, 828, ph * 0.26)}
              {motif(
                'letterEnvelopeFlap',
                126,
                top + ph * 0.72,
                828,
                ph * 0.2,
                1,
                `scaleY(${reduced ? -1 : 1 - 2 * ramp(local, 0, 17)})`,
              )}
              {motif('letterWaxSeal', 864, top + ph - 100, 96, 96)}
            </>
          )}
          {beat === 1 && (
            <>
              {motif('letterEnvelopeBack', 106, top + ph * 0.3, 868, ph * 0.72)}
              {picture(164, top, 752, ph * 0.9, false, true)}
              {motif('letterEnvelopeFront', 106, top + ph * 0.82, 868, ph * 0.2)}
            </>
          )}
          {beat === 2 && (
            <>
              {picture(96, top, width - 192, ph)}
              {motif('letterRibbon', 75, top - 26, 240, 70)}
              {motif('letterWaxSeal', 880, top + ph - 60, 92, 92)}
            </>
          )}
          {beat === 3 && (
            <>
              {picture(132, top + 18, 816, ph - 36)}
              {motif('letterFold', 870, top - 25, 120, 144)}
              {motif('letterClosingRule', 102, top + ph + 15, 876, 86)}
            </>
          )}
          {beat === 4 && (
            <>
              {picture(130, top, 820, ph)}
              {motif('letterEnvelopeBack', 854, top + ph - 85, 170, 102)}
              {motif('letterEnvelopeFront', 854, top + ph - 35, 170, 73)}
              {motif('letterClosingRule', 96, height - 204, width - 192, 32)}
            </>
          )}
        </>
      )}
      <div
        style={{
          position: 'absolute',
          left: 96,
          top: height - (letter ? 430 : beat === 3 ? 400 : 428),
          width: width - 192,
          height: 190,
          color: p.palette.ink,
          fontFamily: font.serif,
          fontSize: size,
          fontWeight: 600,
          lineHeight: 1.25,
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
            top: height - 252,
            width: width - 192,
            color: letter ? p.palette.accent : p.palette.ink,
            fontFamily: font.sans,
            fontSize: 32,
            lineHeight: 1.3,
            opacity: letter ? ramp(local, 52, 70) : show,
            overflowWrap: 'anywhere',
          }}
        >
          {copy.signature}
        </div>
      )}
      {letter && beat === 0 && (
        <div
          style={{
            position: 'absolute',
            left: 230,
            top: top - 42,
            width: 600,
            fontFamily: font.sans,
            fontSize: 28,
            color: p.palette.accent,
            opacity: show,
          }}
        >
          {copy.baby}
        </div>
      )}
    </AbsoluteFill>
  );
}
export function Premium48Phase3Story(p: StoryProps & { monthLetter?: boolean }) {
  const frame = useCurrentFrame(),
    ready = usePremiumFonts(),
    { height } = useVideoConfig(),
    { beat, local } = premium48Frame(frame);
  const next = beat < 4 && local >= 198 ? ramp(local, 198, 210) : 0;
  return (
    <AbsoluteFill style={{ background: p.palette.background }}>
      <Fonts />
      {ready && <Scene p={p} beat={beat} local={local} letter={p.monthLetter === true} />}
      {ready && next > 0 && (
        <AbsoluteFill style={{ opacity: next }}>
          <Scene p={p} beat={beat + 1} local={0} letter={p.monthLetter === true} />
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
