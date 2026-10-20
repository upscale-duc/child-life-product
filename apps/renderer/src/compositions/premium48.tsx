import { useEffect, useState, type CSSProperties } from 'react';
import {
  AbsoluteFill,
  Audio,
  Easing,
  Img,
  cancelRender,
  continueRender,
  delayRender,
  interpolate,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion';
import { BrandLogo, Fonts, art, clamp, font, type StoryProps } from '../kit/core';

export const PREMIUM48_FRAMES = 1050;
export const PREMIUM48_POSTER = 990;
const ease = Easing.bezier(0.22, 1, 0.36, 1);
const ramp = (f: number, a: number, b: number) =>
  interpolate(f, [a, b], [0, 1], { ...clamp, easing: ease });

/** Fixed 5×210-frame beats, including transitions. Photo slots remain independent. */
export function premium48Frame(frame: number) {
  return { beat: Math.min(4, Math.floor(frame / 210)), local: frame % 210 };
}

export function usePremiumFonts() {
  const [handle] = useState(() => delayRender('Premium fonts'));
  const [ready, setReady] = useState(false);
  useEffect(() => {
    Promise.all([
      document.fonts.load('600 72px Lora'),
      document.fonts.load('400 48px BVP'),
      document.fonts.load('600 32px BVP'),
    ])
      .then(() => setReady(true))
      .catch((e: unknown) => cancelRender(e));
  }, [handle]);
  useEffect(() => {
    if (ready) continueRender(handle);
  }, [ready, handle]);
  return ready;
}

export function fitPremiumText(text: string, max: number, width: number): number {
  // Same font and two-line bounds as the mobile preflight. Never ellipsise an exported name.
  if (typeof document === 'undefined') return max;
  const ctx = document.createElement('canvas').getContext('2d');
  if (!ctx) return max;
  for (let size = max; size >= 36; size -= 2) {
    ctx.font = `600 ${size}px Lora`;
    const words = text.split(/\s+/);
    let line = '',
      lines = 1,
      valid = true;
    for (const word of words) {
      if (ctx.measureText(word).width > width) {
        valid = false;
        break;
      }
      const next = line ? `${line} ${word}` : word;
      if (ctx.measureText(next).width > width) {
        lines++;
        line = word;
      } else line = next;
    }
    if (valid && lines <= 2) return size;
  }
  throw new Error('personalization-text-overflow');
}

function Beat({
  p,
  beat,
  local,
  embrace,
}: {
  p: StoryProps;
  beat: number;
  local: number;
  embrace: boolean;
}) {
  const { width, height } = useVideoConfig();
  const presentation = p.presentation;
  const b = presentation?.beats[beat];
  const slot = b?.slots[0] ?? beat;
  const src = p.photos[slot];
  if (!src) throw new Error('premium-photo-missing');
  const copy = presentation?.copy ?? {};
  const text = copy[b?.textKey ?? `scene${beat + 1}`] ?? '';
  const reduced = presentation?.reducedMotion === true;
  const progress = ramp(local, 0, 209);
  const crop = presentation?.crops[beat] ?? { x: 0, y: 0, zoom: 1, fit: 'contain' };
  const hold = embrace && beat === 4 && local >= 90;
  const zoom = crop.zoom * (reduced ? 1 : 1 + 0.035 * (hold ? ramp(90, 0, 209) : progress));
  const opacity = ramp(local, 18, 32);
  const caption = fitPremiumText(text, beat === 4 ? 72 : 64, width - 192);
  const metadata =
    beat === 4
      ? embrace
        ? [copy.signature, copy.detail0].filter(Boolean).join(' · ')
        : copy.detail0
      : !embrace && beat === 0
        ? [copy.detail1, copy.detail2].filter(Boolean).join(' · ')
        : '';
  const photoTop = 180;
  const photoHeight = height - 720;
  const paper: CSSProperties = { position: 'absolute', backgroundColor: p.palette.background };
  return (
    <AbsoluteFill style={{ backgroundColor: p.palette.background }}>
      <Img
        src={p.artAssets?.paperGrain ?? art('p48-grain')}
        style={{ position: 'absolute', width: '100%', height: '100%', opacity: 0.045 }}
      />
      <div
        style={{
          ...paper,
          left: 84,
          top: photoTop - 12,
          width: width - 168,
          height: photoHeight + 24,
          border: `1px solid ${p.palette.accent}40`,
          boxShadow: '0 6px 24px #47372F0C',
        }}
      />
      <div
        style={{
          position: 'absolute',
          left: 96,
          top: photoTop,
          width: width - 192,
          height: photoHeight,
          overflow: 'hidden',
          borderRadius: embrace ? 12 : 2,
          transform:
            !reduced && embrace && beat === 3
              ? `rotate(${-2 + ramp(local, 0, 18) * 2}deg)`
              : undefined,
          clipPath:
            !reduced && !embrace && beat === 0
              ? `inset(0 ${48 * (1 - ramp(local, 0, 18))}% 0 ${48 * (1 - ramp(local, 0, 18))}%)`
              : undefined,
        }}
      >
        <Img
          src={src}
          style={{
            width: '100%',
            height: '100%',
            objectFit: crop.fit ?? 'contain',
            objectPosition: `${(crop.x + 1) * 50}% ${(crop.y + 1) * 50}%`,
            transform: `scale(${zoom})`,
          }}
        />
      </div>
      {!embrace && beat === 3 && (
        <div
          style={{
            position: 'absolute',
            left: width / 2 - 4,
            top: photoTop,
            width: 8,
            height: photoHeight,
            background: p.palette.background,
            boxShadow: '0 0 14px #47372F33',
          }}
        />
      )}
      {!embrace && beat === 2 && (
        <svg width={width} height={height} style={{ position: 'absolute', inset: 0 }}>
          <path
            d={`M84 ${photoTop + photoHeight - 80} Q40 ${photoTop + photoHeight + 24} 170 ${photoTop + photoHeight + 32}`}
            fill="none"
            stroke={p.palette.accent}
            strokeWidth={2.5}
            pathLength={1}
            strokeDasharray={1}
            strokeDashoffset={reduced ? 0 : 1 - ramp(local, 0, 36)}
          />
        </svg>
      )}
      {!embrace && (
        <Img
          src={p.artAssets?.arrivalSun ?? art('p48-arrival-sun')}
          style={{
            position: 'absolute',
            width: 116,
            height: 116,
            top: photoTop - 60,
            right: 65,
            opacity: 0.9,
            transform: `rotate(${reduced ? 0 : -8 + ramp(local, 0, 18) * 8}deg)`,
          }}
        />
      )}
      {embrace && (
        <>
          <Img
            src={p.artAssets?.embracePaper ?? art('p48-embrace-paper')}
            style={{
              position: 'absolute',
              left: 0,
              top: photoTop + photoHeight - 54,
              width,
              height: 150,
            }}
          />
          <svg width={width} height={height} style={{ position: 'absolute', top: 0, left: 0 }}>
            <path
              d={`M88 ${photoTop + photoHeight - 60} C28 ${photoTop + photoHeight - 190}, 70 ${photoTop + 65}, 210 ${photoTop + 22}`}
              fill="none"
              stroke={p.palette.accent}
              strokeWidth={2.5}
              pathLength={1}
              strokeDasharray={1}
              strokeDashoffset={reduced ? 0 : 1 - ramp(local, 0, 36)}
              opacity={0.65}
            />
          </svg>
        </>
      )}
      <div
        style={{
          position: 'absolute',
          left: 96,
          top: height - 480,
          width: width - 192,
          fontFamily: font.serif,
          fontWeight: 600,
          fontSize: caption,
          lineHeight: 1.25,
          color: p.palette.ink,
          opacity,
          transform: `translateY(${reduced ? 0 : 12 * (1 - opacity)}px)`,
        }}
      >
        {text}
      </div>
      <div
        style={{
          position: 'absolute',
          left: 96,
          top: height - 304,
          width: width - 192,
          fontFamily: font.sans,
          fontSize: 28,
          lineHeight: 1.3,
          color: p.palette.accent,
          opacity,
        }}
      >
        {metadata}
      </div>
    </AbsoluteFill>
  );
}

export function Premium48Story(p: StoryProps & { embrace?: boolean }) {
  const frame = useCurrentFrame();
  const ready = usePremiumFonts();
  const { width, height } = useVideoConfig();
  const { beat, local } = premium48Frame(frame);
  const nextOpacity = beat < 4 && local >= 198 ? ramp(local, 198, 210) : 0;
  return (
    <AbsoluteFill style={{ backgroundColor: p.palette.background }}>
      <Fonts />
      {ready && <Beat p={p} beat={beat} local={local} embrace={p.embrace === true} />}
      {ready && nextOpacity > 0 && (
        <AbsoluteFill style={{ opacity: nextOpacity }}>
          <Beat p={p} beat={beat + 1} local={0} embrace={p.embrace === true} />
        </AbsoluteFill>
      )}
      {p.brand?.corner && beat < 4 && (
        <div style={{ position: 'absolute', left: 96, top: 92 }}>
          <BrandLogo width={190} color={p.palette.ink} opacity={p.brand.opacity} />
        </div>
      )}
      {p.brand?.endCard && beat === 4 && (
        <div style={{ position: 'absolute', left: 96, top: height - 184, width: width - 192 }}>
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
