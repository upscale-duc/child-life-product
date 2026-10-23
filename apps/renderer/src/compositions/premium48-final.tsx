import { AbsoluteFill, Audio, Img, interpolate, useCurrentFrame, useVideoConfig } from 'remotion';
import { BrandLogo, Fonts, art, clamp, font, type StoryProps } from '../kit/core';
import { fitPremiumText, usePremiumFonts } from './premium48';
import { premium48FinalDesigns } from '@child-life/contracts';
const ramp = (f: number, a: number, b: number) => interpolate(f, [a, b], [0, 1], clamp);
export function premium48FinalFrame(n: number, frame: number) {
  const limits = n === 22 ? [0, 330, 660, 990, 1320, 1500] : [0, 210, 420, 630, 840, 1050];
  const beat = Math.min(
    4,
    limits.findIndex((v, i) => i < 5 && frame >= v && frame < limits[i + 1]!),
  );
  const safe = Math.max(0, beat);
  return { beat: safe, local: frame - limits[safe]!, length: limits[safe + 1]! - limits[safe]! };
}
/** Exact V22 cue sheet: title 45 frames, each hero 75, group holds, grid then final hero. */
export function premium48MonthSlot(frame: number): number | null {
  if (frame < 45 || (frame >= 1320 && frame < 1410)) return null;
  if (frame >= 1410) return 11;
  const group = Math.min(3, Math.floor(frame / 330)),
    start = group === 0 ? 45 : group * 330;
  const local = frame - start;
  return local < 225 ? group * 3 + Math.floor(local / 75) : null;
}
function Scene({
  p,
  n,
  beat,
  local,
  length,
  frame,
}: {
  p: StoryProps;
  n: number;
  beat: number;
  local: number;
  length: number;
  frame: number;
}) {
  const { height } = useVideoConfig(),
    s = height > 1500,
    d = premium48FinalDesigns[n - 13]!,
    copy = p.presentation?.copy ?? {},
    reduced = p.presentation?.reducedMotion === true;
  const slots =
    p.presentation?.beats[beat]?.slots ??
    (d.video === 4 ? (beat === 4 ? [0, 1, 2, 3] : [beat]) : [beat]);
  const top = s ? 270 : 220,
    ph = s ? 940 : 570,
    captionY = s ? 1360 : 920,
    show = ramp(local, 18, 32),
    progress = ramp(local, 33, length - 19);
  const motif = (suffix: string, x: number, y: number, w: number, h: number, opacity = 1) => {
    const role = `${d.part}-${suffix}`.replace(/-([a-z])/g, (_, v: string) => v.toUpperCase());
    return (
      <Img
        src={p.artAssets?.[role] ?? art(`p48-${d.part}-${suffix}`)}
        style={{
          position: 'absolute',
          left: x,
          top: y,
          width: w,
          height: h,
          opacity,
          objectFit: 'fill',
        }}
      />
    );
  };
  const picture = (
    slot: number,
    x: number,
    y: number,
    w: number,
    h: number,
    shape: 'rect' | 'oval' | 'arch' = 'rect',
    zoom = 1,
  ) => {
    const src = p.photos[slot];
    if (!src) throw new Error('premium-photo-missing');
    const crop = p.presentation?.crops[beat] ?? { x: 0, y: 0, zoom: 1, fit: 'contain' };
    return (
      <div
        key={slot}
        style={{
          position: 'absolute',
          left: x,
          top: y,
          width: w,
          height: h,
          padding: 12,
          boxSizing: 'border-box',
          background: n === 18 ? '#EEE4C91C' : '#FFFDFA',
          borderRadius: shape === 'oval' ? '50%' : shape === 'arch' ? '48% 48% 12px 12px' : 8,
          overflow: 'hidden',
          boxShadow: '0 8px 24px #382C2110',
        }}
      >
        <div style={{ width: '100%', height: '100%', overflow: 'hidden', borderRadius: 'inherit' }}>
          <Img
            src={src}
            style={{
              width: '100%',
              height: '100%',
              objectFit: crop.fit ?? 'contain',
              objectPosition: `${(crop.x + 1) * 50}% ${(crop.y + 1) * 50}%`,
              transform: `scale(${crop.zoom * (reduced ? 1 : zoom)})`,
              transformOrigin: `${(crop.x + 1) * 50}% ${(crop.y + 1) * 50}%`,
            }}
          />
        </div>
      </div>
    );
  };
  const hero = (shape: 'rect' | 'oval' | 'arch' = 'rect', zoom = 1) =>
    picture(slots[0]!, 96, top, 888, ph, shape, zoom);
  const grid = (items: number[], columns: number, y = top, h = ph) => {
    const rows = Math.ceil(items.length / columns),
      gap = 22,
      cw = (888 - gap * (columns - 1)) / columns,
      ch = (h - gap * (rows - 1)) / rows;
    return items.map((slot, i) =>
      picture(
        slot,
        96 + (i % columns) * (cw + gap),
        y + Math.floor(i / columns) * (ch + gap),
        cw,
        ch,
        n === 15 ? 'oval' : 'rect',
      ),
    );
  };
  const label = (v: string, x: number, y: number, w = 888, size = 28) => (
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
  let visual: React.ReactNode;
  if (n === 13) {
    const ovalW = beat === 1 ? 820 : 760;
    visual = (
      <>
        {motif('nested', 140, top - 40, 800, ph + 80, 0.45)}
        {picture(slots[0]!, 540 - ovalW / 2, top, ovalW, ph, 'oval', 1 + 0.02 * progress)}
        {motif('embrace', 180, top + ph + 28, 720, 85, 0.75)}
      </>
    );
  } else if (n === 14) {
    visual = (
      <>
        <div style={{ transform: `translateY(${reduced ? 0 : 12 * (1 - ramp(local, 0, 17))}px)` }}>
          {hero()}
          {motif('doubleframe', 80, top - 16, 920, ph + 32)}
        </div>
        {beat >= 2 && (
          <div
            style={{ clipPath: `inset(0 ${reduced ? 0 : 100 * (1 - ramp(local, 0, 36))}% 0 0)` }}
          >
            {motif('connection', 96, top + ph + 24, 888, 65, 0.8)}
          </div>
        )}
        {motif('branch', 890, top - 85, 95, 180, 0.7)}
      </>
    );
  } else if (n === 15) {
    visual =
      beat === 4 ? (
        <>
          {motif('orbit', 60, top - 24, 960, ph + 48, 0.6)}
          {picture(0, 330, top + ph * 0.18, 420, ph * 0.48, 'oval')}
          {picture(1, 96, top, 240, ph * 0.3, 'oval')}
          {picture(2, 740, top + ph * 0.48, 240, ph * 0.3, 'oval')}
          {picture(3, 130, top + ph * 0.68, 270, ph * 0.3, 'oval')}
        </>
      ) : (
        <>
          {motif('orbit', 80, top - 20, 920, ph + 40, 0.55)}
          {picture(slots[0]!, s ? 190 : 240, top + 20, s ? 700 : 600, ph - 40, 'oval')}
          {motif('dots', 160, top + ph + 26, 760, 45)}
        </>
      );
  } else if (n === 16) {
    visual = (
      <>
        {beat === 4 ? grid([0, 1, 2, 3], 2) : hero()}
        {motif('contact', 96, top - 40, 888, 30, 0.65)}
        {motif('timeline', 96, top + ph + 26, 888, 55, 0.6)}
        {copy.scene1?.startsWith('Morning') || copy.scene1?.startsWith('Buổi sáng')
          ? motif(beat === 0 ? 'sun' : beat === 3 ? 'moon' : 'cloud', 850, 100, 120, 120, 0.8)
          : null}
      </>
    );
  } else if (n === 17) {
    visual = (
      <>
        {beat === 4 ? grid([0, 1, 2, 3], 2) : hero('rect', 1 + 0.02 * progress)}
        {motif('film', 80, top - 16, 920, ph + 32, 0.7)}
        {motif('rule', 96, top + ph + 28, 888, 35, 0.6)}
      </>
    );
  } else if (n === 18) {
    visual = (
      <>
        {motif(
          'stars',
          30,
          40,
          1020,
          height - 130,
          reduced ? 0.26 : 0.26 + 0.06 * Math.sin(frame / 180),
        )}
        {motif('moon', 810, 95, 150, 160, 0.75)}
        {beat === 4 ? picture(2, 180, top, 720, ph, 'arch') : hero('arch')}
        {motif('arch', 82, top - 36, 916, ph + 55, 0.75)}
      </>
    );
  } else if (n === 19) {
    visual = (
      <>
        {hero(beat === 1 || beat === 2 ? 'oval' : 'rect')}
        {motif('ring', 80, top - 16, 920, ph + 32, 0.5)}
        {copy.hundredMark === '100' && motif('numeral', 780, top - 130, 200, 130)}
        {motif('gold', 96, top + ph + 22, 888, 50, 0.65)}
      </>
    );
  } else if (n === 20) {
    const theme = ['tet', 'christmas'].includes(copy.theme ?? '') ? copy.theme! : 'neutral';
    visual = (
      <>
        <div
          style={{
            position: 'absolute',
            inset: 0,
            clipPath: reduced ? 'none' : `inset(0 ${5 * (1 - ramp(local, 0, 17))}% 0 0)`,
          }}
        >
          {hero()}
        </div>
        {motif(`${theme}-corner`, 825, 90, 160, 165)}
        {motif(`${theme}-ribbon`, 96, top + ph + 15, 888, 55, 0.8)}
      </>
    );
  } else if (n === 21) {
    visual = (
      <>
        {hero()}
        {motif('route', 96, top + ph + 16, 888, 70, 0.75)}
        {motif('tag', 60, top - 95, 110, 135, 0.85)}
        {beat === 3 && motif('stamp', 820, top - 110, 145, 125, 0.8)}
      </>
    );
  } else if (n === 22) {
    const slot = premium48MonthSlot(frame),
      groupSlots = Array.from({ length: 3 }, (_, i) => beat * 3 + i),
      all = Array.from({ length: 12 }, (_, i) => i);
    visual = (
      <>
        {frame < 45 ? (
          <>
            {motif('spine', 20, top, 50, ph, 0.5)}
            {label(p.title, 96, top + ph * 0.38, 888, 56)}
          </>
        ) : slot === null ? (
          grid(frame >= 1320 ? all : groupSlots, 3, top, ph)
        ) : (
          <>
            {picture(slot, 160, top, 760, ph)}
            {copy.monthLabels === 'true' &&
              label(`${p.locale === 'vi' ? 'Tháng' : 'Month'} ${slot + 1}`, 96, top - 75, 888, 30)}
          </>
        )}
        {motif('tabs', 96, top + ph + 18, 888, 60, 0.6)}
      </>
    );
  } else if (n === 23) {
    visual = (
      <>
        {motif('envelope', 55, top - 40, 970, ph + 80, 0.35)}
        {picture(slots[0]!, 180, top + 10, 720, ph - 20)}
        {motif('bow', 800, top - 60, 160, 140, 0.75)}
        {beat === 4 && motif('one', 820, top + ph - 135, 130, 155, 0.7)}
        {motif('underline', 96, top + ph + 22, 888, 55, 0.65)}
      </>
    );
  } else {
    visual = (
      <>
        {motif('album', 65, top - 25, 950, ph + 50, 0.4)}
        {beat === 4 ? grid([0, 3], 2) : beat === 3 ? picture(3, 96, top, 888, ph) : hero()}
        {motif('spine', 520, top - 20, 40, ph + 40, 0.6)}
        {motif('stitch', 96, top + ph + 18, 888, 65, 0.7)}
      </>
    );
  }
  const value = copy[p.presentation?.beats[beat]?.textKey ?? `scene${beat + 1}`] ?? '';
  return (
    <AbsoluteFill style={{ background: p.palette.background }}>
      {motif('margin', 20, 20, 1040, height - 40, 0.28)}
      {visual}
      <div
        style={{
          position: 'absolute',
          left: 96,
          top: captionY,
          width: 888,
          height: 180,
          fontFamily: font.serif,
          fontSize: fitPremiumText(value, beat === 4 ? 62 : 58, 888),
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
          {label(copy.signature ?? '', 96, height - 255)}
          {label(copy.label1 ?? '', 96, height - 205, 888, 26)}
        </>
      )}
    </AbsoluteFill>
  );
}
export function Premium48FinalStory(p: StoryProps & { number: number }) {
  const frame = useCurrentFrame(),
    ready = usePremiumFonts(),
    { height } = useVideoConfig(),
    n = p.number,
    { beat, local, length } = premium48FinalFrame(n, frame),
    frames = n === 22 ? 1500 : 1050,
    next = beat < 4 && local >= length - 12 ? ramp(local, length - 12, length) : 0;
  return (
    <AbsoluteFill style={{ background: p.palette.background }}>
      <Fonts />
      {ready && <Scene p={p} n={n} beat={beat} local={local} length={length} frame={frame} />}
      {ready && next > 0 && (
        <AbsoluteFill style={{ opacity: next }}>
          <Scene
            p={p}
            n={n}
            beat={beat + 1}
            local={0}
            length={n === 22 && beat === 3 ? 180 : n === 22 ? 330 : 210}
            frame={frame + length - local}
          />
        </AbsoluteFill>
      )}
      {p.brand?.corner && beat < 4 && (
        <div style={{ position: 'absolute', left: 96, top: 80 }}>
          <BrandLogo width={190} color={p.palette.ink} opacity={p.brand.opacity} />
        </div>
      )}
      {p.brand?.endCard && beat === 4 && (
        <div style={{ position: 'absolute', left: 96, top: height - 145 }}>
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
          volume={(f) => interpolate(f, [0, 12, frames - 36, frames - 1], [0, 1, 1, 0], clamp)}
        />
      )}
    </AbsoluteFill>
  );
}
