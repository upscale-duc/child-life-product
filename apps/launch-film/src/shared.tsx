import React, { useEffect, useState } from 'react';
import {
  AbsoluteFill,
  Img,
  staticFile,
  useCurrentFrame,
  delayRender,
  continueRender,
  cancelRender,
} from 'remotion';
import assets from './assets.json';
import { brand } from './brand';
import { cssColor, type Layer } from './design';
import { useBrand, useTheme } from './theme';
import { Journey } from './Journey';
import { progress } from './animation';
export const asset = (name: string) => {
  const record = (assets as Record<string, { file: string }>)[name];
  if (!record) throw new Error(`Missing Figma asset: ${name}`);
  return staticFile(record.file);
};
let fonts: Promise<unknown> | undefined;
export const Fonts: React.FC = () => {
  const [handle] = useState(() => delayRender('Load local Child Life fonts'));
  useEffect(() => {
    fonts ??= Promise.all(
      [400, 500, 600, 700].map(async (weight) => {
        const suffix = weight === 400 ? 'Regular' : weight === 600 ? 'SemiBold' : 'Bold';
        const face = new FontFace(
          brand.font,
          `url(${staticFile(weight === 500 ? 'fonts/be-vietnam-pro-medium.woff2' : `fonts/BeVietnamPro-${suffix}.ttf`)})`,
          { weight: String(weight) },
        );
        await face.load();
        document.fonts.add(face);
      }),
    );
    fonts.then(() => continueRender(handle)).catch(cancelRender);
  }, [handle]);
  return null;
};
export const Typography: React.FC<{ layer: Layer }> = ({ layer: l }) => (
  <div
    style={{
      fontFamily: brand.font,
      fontWeight:
        l.fontName?.style === 'Medium'
          ? 500
          : l.fontName?.style === 'Regular'
            ? 400
            : l.fontName?.style === 'Bold'
              ? 700
              : 600,
      fontSize: l.fontSize,
      lineHeight:
        l.lineHeight?.unit === 'PERCENT'
          ? `${l.lineHeight.value}%`
          : l.lineHeight?.unit === 'PIXELS'
            ? `${l.lineHeight.value}px`
            : 'normal',
      letterSpacing:
        l.letterSpacing?.unit === 'PERCENT'
          ? `${l.letterSpacing.value / 100}em`
          : l.letterSpacing?.value,
      whiteSpace: 'pre-wrap',
      textAlign: l.textAlignHorizontal?.toLowerCase() as 'left' | 'center' | 'right',
      color:
        cssColor(l.color) ??
        (l.name === 'Headline/2'
          ? brand.mintDeep
          : l.name === 'SupportingText'
            ? brand.muted
            : brand.ink),
    }}
  >
    {l.characters}
  </div>
);
export const DeviceFrame: React.FC<{ name: string }> = ({ name }) => {
  const m = (
    assets as Record<
      string,
      {
        alphaCorrection?: number;
        offset?: { x: number; y: number; w: number; h: number };
        baseWidth?: number;
      }
    >
  )[name];
  const correction = m?.alphaCorrection ?? 1;
  const filterId = 'alpha-' + name.replace(/[^a-zA-Z0-9]/g, '-');
  return (
    <>
      {correction > 1 && Number.isFinite(correction) ? (
        <svg width="0" height="0" style={{ position: 'absolute' }}>
          <defs>
            <filter id={filterId} colorInterpolationFilters="sRGB">
              <feComponentTransfer>
                <feFuncA type="linear" slope={correction} />
              </feComponentTransfer>
            </filter>
          </defs>
        </svg>
      ) : null}
      <Img
        src={asset(name)}
        style={{
          position: m?.offset ? 'absolute' : undefined,
          left: m?.offset ? `${(m.offset.x / (m.baseWidth ?? 1)) * 100}%` : undefined,
          top: m?.offset ? `${(m.offset.y / 214.4) * 100}%` : undefined,
          width: '100%',
          height: '100%',
          objectFit: 'fill',
          filter: correction > 1 && Number.isFinite(correction) ? `url(#${filterId})` : undefined,
        }}
      />
    </>
  );
};
// The Figma A2 sheet occupies y431–812 of the 812px source screen. Keep it
// separate from the dimmed app so its entrance can move independently.
export const RecordSheet: React.FC<{ frame: number }> = ({ frame }) => {
  const open = progress(frame, 12, 30) * (1 - progress(frame, 72, 84));
  return (
    <div
      style={{
        position: 'relative',
        width: '100%',
        height: '100%',
        overflow: 'hidden',
        borderRadius: '13% / 6%',
      }}
    >
      <div
        style={{ position: 'absolute', inset: 0, clipPath: 'inset(0 0 46.9212% 0)', opacity: open }}
      >
        <DeviceFrame name="AppScreen/GhiBuBinh" />
      </div>
      <div
        data-layer="Sheet/BuBinh"
        style={{
          position: 'absolute',
          inset: 0,
          clipPath: 'inset(53.0788% 0 0 0)',
          transform: `translateY(${(1 - open) * 46.9212}%)`,
        }}
      >
        <DeviceFrame name="AppScreen/GhiBuBinh" />
      </div>
    </div>
  );
};
export const Photo: React.FC<{ layer: Layer }> = ({ layer: l }) => {
  const f = useCurrentFrame();
  const brand = useBrand();
  const isOpening = l.name.includes('MeVaBe');
  const index = Number(l.name.match(/(?:Photo0|P0)(\d)/)?.[1] ?? 1);
  return (
    <div
      style={{
        width: '100%',
        height: '100%',
        background: brand.surface,
        padding: isOpening ? 0 : l.w * 0.04,
        boxSizing: 'border-box',
        borderRadius: l.cornerRadius ?? 22,
        boxShadow: brand.shadow,
        overflow: 'hidden',
      }}
    >
      <Img
        src={asset(isOpening ? 'Photo/MeVaBe' : l.name)}
        style={{
          width: '100%',
          height: isOpening ? '100%' : l.w * 0.92,
          objectFit: 'cover',
          borderRadius: isOpening ? 0 : l.w * 0.047,
          transform: isOpening ? `scale(${1.08 - Math.min(f / 150, 1) * 0.08})` : undefined,
        }}
      />
      {!isOpening && l.h > l.w * 1.07 ? (
        <div
          style={{
            fontFamily: brand.font,
            fontSize: l.w * 0.055,
            color: brand.muted,
            textAlign: 'center',
            paddingTop: l.w * 0.025,
          }}
        >
          {index === 5 ? '1 tháng' : `Tuần ${index}`}
        </div>
      ) : null}
    </div>
  );
};
export const GrowthChart: React.FC<{ frame: number }> = ({ frame }) => {
  const brand = useBrand(),
    theme = useTheme();
  const themed = (n: string) => (theme === 'dark' ? 'v2:dark:' : '') + n;
  const p = Math.max(0, Math.min(1, (frame - 18) / 48));
  return (
    <div
      style={{
        width: 682,
        height: 740,
        background: brand.surface,
        borderRadius: 28,
        padding: 32,
        boxSizing: 'border-box',
        fontFamily: brand.font,
        color: brand.ink,
        boxShadow: '0 12px 32px #173d442e',
      }}
    >
      <div
        style={{
          display: 'flex',
          padding: 8,
          borderRadius: 28,
          background: brand.surface2,
          fontSize: 28,
          fontWeight: 600,
        }}
      >
        <div
          style={{
            flex: 1,
            textAlign: 'center',
            padding: '16px 20px',
            borderRadius: 20,
            background: brand.surface,
          }}
        >
          Cân nặng
        </div>
        <div
          style={{
            flex: 1,
            textAlign: 'center',
            padding: '16px 20px',
            color: brand.muted,
            fontWeight: 400,
          }}
        >
          Chiều dài
        </div>
      </div>
      <div style={{ display: 'flex', gap: 16, alignItems: 'center', marginTop: 24 }}>
        <b style={{ fontSize: 56 }}>4,3 kg</b>
        <span style={{ fontSize: 26, color: brand.muted }}>· 3 tuần tuổi</span>
      </div>
      <div
        style={{
          display: 'inline-block',
          padding: '12px 24px',
          borderRadius: 999,
          background: '#fdede2',
          color: '#9a4a14',
          fontSize: 24,
          fontWeight: 600,
          marginTop: 24,
        }}
      >
        +0,4 kg so với 1 thg 10
      </div>
      <div style={{ position: 'relative', width: 622, height: 404, marginTop: 24 }}>
        {[
          ['2 kg', 360],
          ['4 kg', 208.89],
          ['6 kg', 57.78],
        ].map(([t, y]) => (
          <React.Fragment key={t}>
            <div
              style={{
                position: 'absolute',
                left: 68,
                top: Number(y),
                width: 554,
                height: 2,
                background: brand.separator,
              }}
            />
            <div
              style={{
                position: 'absolute',
                left: 0,
                top: Number(y) - 14,
                fontSize: 20,
                color: brand.muted,
              }}
            >
              {t}
            </div>
          </React.Fragment>
        ))}
        <div
          style={{
            position: 'absolute',
            left: 67.4,
            top: 183.82,
            width: 324.1,
            height: 88.03,
            clipPath: `inset(0 ${(1 - p) * 100}% 0 0)`,
          }}
        >
          <Img src={asset(themed('Accent/GrowthLine'))} style={{ display: 'block' }} />
        </div>
        {[
          { x: 60, y: 261.33, t: 24, d: 16 },
          { x: 275.2, y: 208.44, t: 44, d: 16 },
          { x: 378.8, y: 174.22, t: 62, d: 24 },
        ].map((v, i) => (
          <Img
            key={i}
            src={asset(themed(i === 2 ? 'Accent/GrowthDot/3' : 'Accent/GrowthDot/1'))}
            style={{
              position: 'absolute',
              left: v.x,
              top: v.y,
              width: v.d,
              height: v.d,
              opacity: Math.max(0, Math.min(1, (frame - v.t) / 8)),
            }}
          />
        ))}
        {['Sinh', '1 tuần', '2 tuần', '3 tuần', '4 tuần', '5 tuần'].map((t, i) => (
          <div
            key={t}
            style={{
              position: 'absolute',
              left: [56, 146.6, 251.2, 358.8, 466.4, 558][i],
              top: 372,
              fontSize: 20,
              color: brand.muted,
              whiteSpace: 'nowrap',
            }}
          >
            {t}
          </div>
        ))}
      </div>
    </div>
  );
};
export const LayerView: React.FC<{ layer: Layer; frame: number }> = ({ layer: l, frame }) => {
  const brand = useBrand();
  const key = l.assetKey ?? l.name;
  if (l.name === 'Background')
    return <AbsoluteFill style={{ background: cssColor(l.color) ?? brand.cloud }} />;
  if (
    l.name.startsWith('_') ||
    l.name.includes('không render') ||
    l.name === 'Accent/LineReveal' ||
    l.opacity <= 0
  )
    return null;
  let content: React.ReactNode;
  if (l.name === 'Illustration/Journey') content = <Journey layer={l} frame={frame} />;
  else if (l.name === 'Card/Siri') content = <SiriCard layer={l} frame={frame} />;
  else if (l.characters !== undefined) content = <Typography layer={l} />;
  else if (l.name.startsWith('Photo/')) content = <Photo layer={l} />;
  else if (l.name === 'Card/GrowthChart')
    content = (
      <div
        style={{
          width: 682,
          height: 740,
          transform: `scale(${l.w / 682},${l.h / 740})`,
          transformOrigin: 'top left',
        }}
      >
        <GrowthChart frame={frame} />
      </div>
    );
  else if (l.name.startsWith('Accent/TimelineDot'))
    content = (
      <div
        style={{ width: '100%', height: '100%', background: brand.mintDeep, borderRadius: '50%' }}
      />
    );
  else if (
    l.name === 'Accent/Band' ||
    l.name === 'Accent/Sun' ||
    (l.name === 'Logo' && key === l.name)
  ) {
    const w = l.name === 'Accent/Band' ? 1920 : l.name === 'Logo' ? 440 : 260;
    const h = l.name === 'Accent/Band' ? 380 : l.name === 'Logo' ? 85.037109375 : 260;
    content = (
      <div
        style={{
          width: w,
          height: h,
          transform: `scale(${l.w / w},${l.h / h})`,
          transformOrigin: 'top left',
        }}
      >
        <Img src={asset(key)} style={{ display: 'block' }} />
      </div>
    );
  } else if (l.name === 'AppScreen/GhiBuBinh') content = <RecordSheet frame={frame} />;
  else content = <DeviceFrame name={key} />;
  if (l.alternateAssetKey)
    content = (
      <>
        <div style={{ position: 'absolute', inset: 0, opacity: 1 - (l.alternateMix ?? 0) }}>
          <DeviceFrame name={key} />
        </div>
        <div style={{ position: 'absolute', inset: 0, opacity: l.alternateMix ?? 0 }}>
          <DeviceFrame name={l.alternateAssetKey} />
        </div>
      </>
    );
  return (
    <div
      data-figma-node={l.id}
      data-layer={l.name}
      style={{
        position: 'absolute',
        left: l.x,
        top: l.y,
        width: l.w,
        height: l.h,
        opacity: l.opacity,
        transform: `rotate(${-l.rotation}deg)`,
        transformOrigin: 'center',
      }}
    >
      {content}
    </div>
  );
};

const SiriCard = ({ layer: l, frame }: { layer: Layer; frame: number }) => {
  const b = useBrand();
  const answer = l.siriAnswer;
  const width = answer ? 720 : 470;
  return (
    <div
      style={{
        width,
        height: 177,
        padding: '22px 24px',
        boxSizing: 'border-box',
        background: b.surface,
        borderRadius: 28,
        fontFamily: b.font,
        boxShadow: '0 12px 32px #173d442e',
        transform: `scale(${l.w / width},${l.h / 177})`,
        transformOrigin: 'top left',
      }}
    >
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: 10,
          fontSize: 20,
          fontWeight: 600,
          color: b.muted,
        }}
      >
        <span
          style={{
            width: 30,
            height: 30,
            borderRadius: '50%',
            background: 'linear-gradient(90deg,#7b72fa,#db60bc,#ffd166)',
            display: 'inline-block',
          }}
        />
        Hey Siri…
      </div>
      <div
        style={{
          fontSize: 26,
          lineHeight: 1.3,
          fontWeight: 600,
          color: b.ink,
          marginTop: 12,
          whiteSpace: 'nowrap',
        }}
      >
        {answer ? '“Lần bú cuối của Teddy lúc mấy giờ?”' : '“Lumi ghi cữ bú 120 ml.”'}
      </div>
      <div
        style={{
          background: b.surface2,
          borderRadius: 16,
          padding: '10px 14px',
          fontSize: 20,
          fontWeight: 600,
          color: b.mintDeep,
          marginTop: 12,
          opacity: progress(frame, 132, 144),
          whiteSpace: 'nowrap',
        }}
      >
        {answer ? '2 giờ 15 phút trước · bú bình 120 ml' : '✓ Đã ghi bú bình 120 ml lúc 9:00'}
      </div>
    </div>
  );
};
