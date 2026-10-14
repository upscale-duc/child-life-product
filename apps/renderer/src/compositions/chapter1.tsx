import type { ReactNode } from 'react';
import { AbsoluteFill, Easing, Img, interpolate, useCurrentFrame } from 'remotion';
import {
  AgeTag,
  Art,
  BrandCorner,
  Burst,
  Collage,
  EndCard,
  FPS,
  Fonts,
  Framed,
  H,
  LightLeak,
  Music,
  Particles,
  PhotoBlurFill,
  PhotoFill,
  SplitCompare,
  Timeline,
  Title,
  TypeReveal,
  W,
  art,
  chronological,
  clamp,
  font,
  labelAt,
  layout,
  lineAt,
  perPhoto,
  photoAt,
  sec,
  type Scene,
  type StoryProps,
} from '../kit/core';

/**
 * Chapter 01 Memory Story videos V01–V12 (docs/product/remember-2-templates.md §5). Each one
 * builds its scenes from the props; its length follows the number of photos (§4.2) and stays
 * inside the template's range (`durationSec` is the most it may take).
 */

export interface StoryDef {
  scenes: (p: StoryProps) => Scene[];
  /** The scene the poster comes from (default: the one after the intro). */
  posterScene?: (p: StoryProps) => number;
  /** Over a photo (white logo) or a flat page (palette ink), per frame. */
  onPhoto?: (p: StoryProps, frame: number) => boolean;
}

const fixed = (...s: number[]) => s.reduce((a, b) => a + b, 0);

/** The page behind a scene. */
const Page = ({ bg, children }: { bg: string; children?: ReactNode }) => (
  <AbsoluteFill style={{ backgroundColor: bg }}>{children}</AbsoluteFill>
);

// ---------------------------------------------------------------- V01 Welcome to the World

const welcomeWorld: StoryDef = {
  scenes: (p) => {
    const n = p.photos.length;
    const per = perPhoto(p.durationSec, fixed(4, 3.5, 4, 0.6), n, 2.2, 3.2);
    const { background, ink, accent } = p.palette;
    const scenes: Scene[] = [
      {
        len: sec(4),
        overlap: 24,
        exit: 'fade',
        render: (len) => <WelcomeIntro p={p} len={len} />,
      },
      {
        len: per + sec(0.6),
        overlap: 20,
        enter: 'iris',
        render: (len) => <Letterboxed src={photoAt(p, 0)} len={len} />,
      },
      {
        len: sec(3.5),
        overlap: 15,
        render: () => (
          <Page bg={background}>
            <Img
              src={art('paper-grain')}
              style={{
                position: 'absolute',
                inset: 0,
                width: '100%',
                height: '100%',
                opacity: 0.6,
              }}
            />
            <Title
              text={p.name}
              fontFamily={font.serif}
              size={120}
              weight={600}
              color={ink}
              sub={p.dateLine}
              subColor={ink}
            />
            <AbsoluteFill style={{ alignItems: 'center', justifyContent: 'center' }}>
              <div
                style={{
                  marginTop: 330,
                  fontFamily: font.sans,
                  fontWeight: 600,
                  fontSize: 44,
                  color: accent,
                }}
              >
                {p.birthStats ?? ''}
              </div>
            </AbsoluteFill>
          </Page>
        ),
      },
    ];
    for (let i = 1; i < n; i++) {
      scenes.push({
        len: per,
        overlap: 15,
        render: (len) => (
          <>
            <PhotoFill
              src={photoAt(p, i)}
              len={len}
              from={i % 2 ? 1 : 1.1}
              to={i % 2 ? 1.1 : 1}
              drift={i % 2 ? -30 : 30}
            />
            {(i === 2 || i === 5) && <LightLeak />}
          </>
        ),
      });
    }
    scenes.push({
      len: sec(4),
      render: () => (
        <EndCard closing={p.closing || ''} name={p.name} palette={p.palette} brand={p.brand} />
      ),
    });
    return scenes;
  },
};

function WelcomeIntro({ p, len }: { p: StoryProps; len: number }) {
  const f = useCurrentFrame();
  const glow = interpolate(f, [0, 45], [0, 1], clamp);
  return (
    <AbsoluteFill style={{ backgroundColor: '#000' }}>
      <AbsoluteFill
        style={{
          background: 'radial-gradient(circle at 50% 46%, rgba(255,240,215,0.55), transparent 55%)',
          opacity: glow,
        }}
      />
      <Title
        text={p.title}
        fontFamily={font.serif}
        size={88}
        weight={600}
        color="#F5EFE6"
        by="letter"
        sub={p.dateLine}
        subColor="#F5EFE6"
        delay={10}
      />
      <div style={{ opacity: interpolate(f, [len - 20, len], [1, 0], clamp) }} />
    </AbsoluteFill>
  );
}

function Letterboxed({ src, len }: { src: string; len: number }) {
  const f = useCurrentFrame();
  const bar = interpolate(f, [10, 40], [120, 0], { ...clamp, easing: Easing.inOut(Easing.cubic) });
  return (
    <>
      <PhotoFill src={src} len={len} from={1.15} to={1} grain />
      <div
        style={{
          position: 'absolute',
          left: 0,
          right: 0,
          top: 0,
          height: bar,
          backgroundColor: '#000',
        }}
      />
      <div
        style={{
          position: 'absolute',
          left: 0,
          right: 0,
          bottom: 0,
          height: bar,
          backgroundColor: '#000',
        }}
      />
    </>
  );
}

// ---------------------------------------------------------------- V02 Our First Days

const ourFirstDays: StoryDef = {
  scenes: (p) => {
    const n = p.photos.length;
    const per = perPhoto(p.durationSec, fixed(3.5, 4.5), n, 2.0, 3.0);
    const { background, ink, accent } = p.palette;
    const scenes: Scene[] = [
      {
        len: sec(3.5),
        overlap: 15,
        render: () => (
          <Page bg={background}>
            <Img
              src={art('paper-grain')}
              style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }}
            />
            <Title text={p.title} fontFamily={font.serif} size={80} weight={600} color={ink} />
            <Underline color={accent} />
          </Page>
        ),
      },
    ];
    for (let i = 0; i < n; i++) {
      scenes.push({
        len: per,
        overlap: 15,
        enter: i % 3 === 2 ? 'slideLeft' : 'fade',
        render: (len) => (
          <Page bg={background}>
            <Img
              src={art('paper-grain')}
              style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }}
            />
            {i > 0 && (
              <div
                style={{
                  position: 'absolute',
                  left: 150,
                  top: 330,
                  width: 780,
                  height: 975,
                  padding: 22,
                  backgroundColor: '#FFFFFF',
                  transform: `rotate(${i % 2 ? 3 : -3}deg)`,
                  opacity: 0.7,
                  boxShadow: '0 20px 50px rgba(0,0,0,0.15)',
                }}
              >
                <Img
                  src={photoAt(p, i - 1)}
                  style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                />
              </div>
            )}
            <Framed
              src={photoAt(p, i)}
              len={len}
              kind="polaroid"
              width={780}
              height={900}
              tilt={i % 2 ? -3 : 2}
              caption={labelAt(p, i) ?? ''}
              captionStyle={{
                fontFamily: font.script,
                fontWeight: 600,
                fontSize: 64,
                color: accent,
              }}
            />
          </Page>
        ),
      });
    }
    scenes.push({
      len: sec(4.5),
      render: () => (
        <EndCard
          closing={p.message}
          name={p.locale === 'en' ? 'Mom & Dad' : 'Ba mẹ'}
          palette={p.palette}
          brand={p.brand}
          closingSize={56}
        >
          <Img
            src={art('paper-grain')}
            style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }}
          />
        </EndCard>
      ),
    });
    return scenes;
  },
};

function Underline({ color }: { color: string }) {
  const f = useCurrentFrame();
  const d = interpolate(f, [20, 50], [600, 0], clamp);
  return (
    <svg
      style={{ position: 'absolute', left: 240, top: 1080, width: 600, height: 40 }}
      viewBox="0 0 600 40"
    >
      <path
        d="M10 25 Q150 5 300 22 T590 18"
        stroke={color}
        strokeWidth={8}
        fill="none"
        strokeLinecap="round"
        strokeDasharray={600}
        strokeDashoffset={d}
      />
    </svg>
  );
}

// ---------------------------------------------------------------- V03 Little Love Story

const littleLoveStory: StoryDef = {
  scenes: (p) => {
    const n = p.photos.length;
    const per = perPhoto(p.durationSec, fixed(3.5, 4), n, 3.0, 3.8);
    const { background, ink, accent } = p.palette;
    const scenes: Scene[] = [
      {
        len: sec(3.5),
        overlap: 18,
        render: () => (
          <Page bg={background}>
            <Particles kind="petals" count={18} colors={[accent, '#F7C4C8']} />
            <Title
              text={p.title}
              fontFamily={font.script}
              size={110}
              weight={600}
              color={ink}
              by="letter"
            />
          </Page>
        ),
      },
    ];
    for (let i = 0; i < n; i++) {
      scenes.push({
        len: per,
        overlap: 18,
        enter: 'slideLeft',
        render: (len) => (
          <Page bg={background}>
            <PhotoBlurFill
              src={photoAt(p, i)}
              len={len}
              radius={32}
              style={{ left: 64, top: 180, width: W - 128, height: H * 0.62 - 180 }}
            />
            <LoveLine text={lineAt(p, i)} color={ink} />
          </Page>
        ),
      });
    }
    scenes.push({
      len: sec(4),
      render: () => (
        <EndCard closing={p.closing || ''} name={p.name} palette={p.palette} brand={p.brand}>
          <Heart color={accent} />
        </EndCard>
      ),
    });
    return scenes;
  },
};

function LoveLine({ text, color }: { text: string; color: string }) {
  const f = useCurrentFrame();
  const o = interpolate(f, [12, 26], [0, 1], clamp);
  return (
    <div
      style={{
        position: 'absolute',
        left: 100,
        right: 100,
        top: H * 0.65,
        textAlign: 'center',
        fontFamily: font.serif,
        fontStyle: 'italic',
        fontSize: 58,
        lineHeight: 1.35,
        color,
        opacity: o,
        transform: `translateY(${(1 - o) * 16}px)`,
      }}
    >
      {text}
    </div>
  );
}

function Heart({ color }: { color: string }) {
  const f = useCurrentFrame();
  const d = interpolate(f, [10, 40], [400, 0], clamp);
  return (
    <svg viewBox="0 0 120 110" style={{ position: 'absolute', top: 480, width: 160 }}>
      <path
        d="M60 100C25 75 5 55 5 32 5 15 18 5 33 5c12 0 21 7 27 16C66 12 75 5 87 5c15 0 28 10 28 27 0 23-20 43-55 68Z"
        stroke={color}
        strokeWidth={6}
        fill="none"
        strokeDasharray={400}
        strokeDashoffset={d}
      />
    </svg>
  );
}

// ---------------------------------------------------------------- V04 Tiny Moments

function groupsOf(n: number): number[] {
  const out: number[] = [];
  const pattern = [1, 2, 3];
  let left = n;
  for (let i = 0; left > 0; i++) {
    const g = Math.min(pattern[i % 3]!, left);
    out.push(g);
    left -= g;
  }
  if (out.length > 1 && out[out.length - 1] === 1) {
    out.pop();
    out[out.length - 1]! += 1;
  }
  return out.map((g) => Math.min(g, 4));
}

const tinyMoments: StoryDef = {
  scenes: (p) => {
    const n = p.photos.length;
    // A group shares one transition: on-screen time per photo, plus one overlap per group.
    const per = perPhoto(p.durationSec, fixed(2.5, 2.5), n, 1.2, 1.8) - sec(0.5);
    const { background, ink, accent } = p.palette;
    const stickers = ['heart-soft', 'sparkle', 'smiley-doodle', 'sun-rays'];
    const scenes: Scene[] = [
      {
        len: sec(2.5),
        overlap: 12,
        render: () => (
          <Page bg={background}>
            <Particles kind="dots" count={40} colors={[accent, '#F7D67A', '#9FD8CB']} />
            <Art name="sparkle" style={{ left: 760, top: 520, width: 140 }} spin={180} />
            <Title
              text={p.title}
              fontFamily={font.round}
              size={110}
              weight={800}
              color={ink}
              by="bounce"
            />
          </Page>
        ),
      },
    ];
    let at = 0;
    groupsOf(n).forEach((g, k) => {
      const srcs = Array.from({ length: g }, (_, j) => photoAt(p, at + j));
      at += g;
      scenes.push({
        len: per * g + sec(0.5),
        overlap: 12,
        enter: k % 2 ? 'slideLeft' : 'slideUp',
        render: (len) => (
          <Page bg={background}>
            {g === 1 ? (
              <Framed
                src={srcs[0]!}
                len={len}
                kind="rounded"
                width={900}
                height={1180}
                tilt={k % 2 ? 3 : -3}
              />
            ) : (
              <Collage srcs={srcs} len={len} />
            )}
            <Art
              name={stickers[k % stickers.length]!}
              style={{ right: 70, top: 170, width: 200 }}
              delay={6}
              spin={40}
            />
            <Art
              name={stickers[(k + 2) % stickers.length]!}
              style={{ left: 60, bottom: 330, width: 170 }}
              delay={10}
              spin={-40}
            />
          </Page>
        ),
      });
    });
    scenes.push({
      len: sec(2.5),
      render: () => (
        <EndCard
          closing={p.closing || ''}
          name={p.name}
          palette={p.palette}
          brand={p.brand}
          closingFont={font.round}
          italic={false}
          closingSize={78}
        />
      ),
    });
    return scenes;
  },
};

// ---------------------------------------------------------------- V05 Growing So Fast

const growingSoFast: StoryDef = {
  scenes: (p) => {
    const order = chronological(p);
    const n = order.length;
    const per = perPhoto(p.durationSec, fixed(3, 4, 3), n, 1.8, 2.6);
    const { background, ink, accent } = p.palette;
    const scenes: Scene[] = [
      {
        len: sec(3),
        overlap: 15,
        render: (len) => (
          <Page bg={background}>
            <Title text={p.title} size={90} color={ink} />
            <ProgressBar
              color={accent}
              track={ink}
              progress={(f) => interpolate(f, [10, 50], [0, 1], clamp)}
              len={len}
            />
          </Page>
        ),
      },
    ];
    order.forEach((i, k) => {
      scenes.push({
        len: per,
        overlap: 18,
        enter: 'zoom',
        exit: 'zoom',
        render: (len) => (
          <>
            <PhotoFill src={photoAt(p, i)} len={len} from={1} to={1.08} drift={0} />
            <AgeTag label={labelAt(p, i)} bg={accent} />
            <ProgressBar
              color="#FFFFFF"
              track="#FFFFFF"
              progress={() => (n > 1 ? k / (n - 1) : 1)}
              len={len}
            />
          </>
        ),
      });
    });
    if (n > 1) {
      const a = order[0]!;
      const b = order[n - 1]!;
      const vi = p.locale !== 'en';
      scenes.push({
        len: sec(4),
        overlap: 15,
        render: (len) => (
          <SplitCompare
            a={photoAt(p, a)}
            b={photoAt(p, b)}
            labelA={labelAt(p, a) ?? (vi ? 'Lúc ấy' : 'Then')}
            labelB={labelAt(p, b) ?? (vi ? 'Bây giờ' : 'Now')}
            len={len}
            accent={accent}
            ink={ink}
            bg={background}
          />
        ),
      });
    }
    scenes.push({
      len: sec(3),
      render: () => (
        <EndCard closing={p.closing || ''} name={p.name} palette={p.palette} brand={p.brand} />
      ),
    });
    return scenes;
  },
};

function ProgressBar({
  color,
  track,
  progress,
  len,
}: {
  color: string;
  track: string;
  progress: (f: number) => number;
  len: number;
}) {
  const f = useCurrentFrame();
  const v = progress(f);
  return (
    <div
      style={{
        position: 'absolute',
        left: 90,
        right: 90,
        bottom: 210,
        height: 6,
        backgroundColor: track,
        opacity: 0.35,
        borderRadius: 3,
      }}
      data-len={len}
    >
      <div
        style={{
          position: 'absolute',
          left: 0,
          top: -9,
          width: 24,
          height: 24,
          borderRadius: 12,
          backgroundColor: color,
          transform: `translateX(${v * (W - 180 - 24)}px)`,
          opacity: 1,
        }}
      />
      <div
        style={{ width: `${v * 100}%`, height: '100%', backgroundColor: color, borderRadius: 3 }}
      />
    </div>
  );
}

// ---------------------------------------------------------------- V06 Hello, Little Smile

const helloSmile: StoryDef = {
  scenes: (p) => {
    const n = p.photos.length;
    const per = perPhoto(p.durationSec, fixed(2.5, 3), n, 2.0, 3.0);
    const { background, ink, accent } = p.palette;
    const scenes: Scene[] = [
      {
        len: sec(2.5),
        overlap: 12,
        render: () => (
          <SunnyPage bg={background} accent={accent}>
            <Art name="smiley-doodle" style={{ left: 390, top: 380, width: 300 }} spin={120} />
            <Title
              text={p.title}
              fontFamily={font.round}
              size={96}
              weight={800}
              color={ink}
              by="word"
              top={760}
            />
          </SunnyPage>
        ),
      },
    ];
    for (let i = 0; i < n; i++) {
      scenes.push({
        len: per,
        overlap: 12,
        enter: i % 2 ? 'pop' : 'slideUp',
        render: (len) => (
          <SunnyPage bg={background} accent={accent}>
            <Framed
              src={photoAt(p, i)}
              len={len}
              kind="rounded"
              width={860}
              height={1100}
              tilt={i % 2 ? 4 : -4}
            />
            <Art
              name="smiley-doodle"
              style={{ right: 60, top: 260, width: 170 }}
              delay={5}
              spin={60}
              float={10}
            />
            <Art name="sparkle" style={{ left: 70, top: 360, width: 110 }} delay={9} float={8} />
            <Art
              name="sun-rays"
              style={{ left: 60, bottom: 300, width: 170 }}
              delay={12}
              spin={-60}
            />
          </SunnyPage>
        ),
      });
    }
    scenes.push({
      len: sec(3),
      render: () => (
        <EndCard
          closing={p.closing || ''}
          name={p.name}
          palette={p.palette}
          brand={p.brand}
          closingFont={font.round}
          italic={false}
          closingSize={80}
        />
      ),
    });
    return scenes;
  },
};

function SunnyPage({ bg, accent, children }: { bg: string; accent: string; children: ReactNode }) {
  const f = useCurrentFrame();
  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(${160 + (f / FPS) * 6}deg, ${bg} 30%, ${accent}55 100%)`,
      }}
    >
      <Img
        src={art('sunburst')}
        style={{
          position: 'absolute',
          left: -160,
          top: 260,
          width: 1400,
          transform: `rotate(${(f / FPS) * 6}deg)`,
          opacity: 0.6,
        }}
      />
      {children}
    </AbsoluteFill>
  );
}

// ---------------------------------------------------------------- V07 My First Milestone

const firstMilestone: StoryDef = {
  scenes: (p) => {
    const n = p.photos.length;
    const per = perPhoto(p.durationSec, fixed(3.5, 4.5), n, 2.2, 3.2);
    const { background, ink, accent } = p.palette;
    const confetti = [accent, '#F7D67A', '#9FD8CB', '#C9B8E8', '#F4B6B8'];
    const scenes: Scene[] = [
      {
        len: sec(3.5),
        overlap: 15,
        render: () => (
          <Page bg={background}>
            <Art name="medal-rosette" style={{ left: 330, top: 300, width: 420 }} spin={30} />
            <Title
              text={p.headline || p.title}
              fontFamily={font.round}
              size={92}
              weight={800}
              color={ink}
              top={1000}
              sub={p.dateLine}
              delay={8}
            />
            <Burst at={20} colors={confetti} />
          </Page>
        ),
      },
    ];
    for (let i = 0; i < n; i++) {
      const caption = lineAt(p, i);
      scenes.push({
        len: per,
        overlap: 15,
        enter: 'slideUp',
        render: (len) => (
          <Page bg={background}>
            <Framed src={photoAt(p, i)} len={len} kind="print" width={860} height={1150} tilt={2} />
            {caption && <StickerLabel text={caption} bg={accent} />}
            <Img
              src={art('medal-rosette')}
              style={{ position: 'absolute', right: 60, top: 150, width: 150 }}
            />
          </Page>
        ),
      });
    }
    scenes.push({
      len: sec(4.5),
      render: () => (
        <EndCard
          closing={p.closing || ''}
          name={p.name}
          sub={p.dateLine}
          palette={p.palette}
          brand={p.brand}
          closingFont={font.round}
          italic={false}
          closingSize={68}
        >
          <Img src={art('medal-rosette')} style={{ position: 'absolute', top: 360, width: 200 }} />
          <Burst at={30} count={40} colors={confetti} seed="end" />
        </EndCard>
      ),
    });
    return scenes;
  },
};

function StickerLabel({ text, bg }: { text: string; bg: string }) {
  const f = useCurrentFrame();
  const s = interpolate(f, [8, 20], [0.6, 1], { ...clamp, easing: Easing.out(Easing.back(2)) });
  return (
    <div
      style={{
        position: 'absolute',
        left: 0,
        right: 0,
        bottom: 360,
        display: 'flex',
        justifyContent: 'center',
      }}
    >
      <div
        style={{
          padding: '18px 40px',
          borderRadius: 50,
          backgroundColor: bg,
          color: '#FFFFFF',
          fontFamily: font.round,
          fontWeight: 800,
          fontSize: 60,
          transform: `scale(${s}) rotate(-3deg)`,
          border: '6px solid #FFFFFF',
        }}
      >
        {text}
      </div>
    </div>
  );
}

// ---------------------------------------------------------------- V08 100 Days of Love

const hundredDaysLove: StoryDef = {
  scenes: (p) => {
    const order = chronological(p);
    const n = order.length;
    const per = perPhoto(p.durationSec, fixed(4, 6), n, 2.0, 2.6);
    const { background, ink, accent } = p.palette;
    const scenes: Scene[] = [
      {
        len: sec(4),
        overlap: 18,
        render: () => (
          <Page bg={background}>
            <Img
              src={art('cloud-scroll')}
              style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }}
            />
            <Img
              src={art('c11-frame-story')}
              style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }}
            />
            <Particles kind="petals" count={16} colors={['#F4B7B2', '#F7C4C8']} />
            <CountUp to={100} color={accent} />
            <Title
              text={p.title}
              fontFamily={font.serif}
              size={76}
              weight={600}
              italic
              color={ink}
              top={1180}
              delay={20}
            />
          </Page>
        ),
      },
    ];
    order.forEach((i, k) => {
      scenes.push({
        len: per,
        overlap: 18,
        render: (len) => (
          <Page bg={background}>
            <Img
              src={art('cloud-scroll')}
              style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }}
            />
            <Framed
              src={photoAt(p, i)}
              len={len}
              kind="arch"
              width={800}
              height={1100}
              border="#C2A15A"
            />
            <AgeTag label={labelAt(p, i)} bg={accent} kind="seal" bottom={300} />
            {k % 4 === 3 && <LightLeak color="#E8C77A" />}
          </Page>
        ),
      });
    });
    scenes.push({
      len: sec(6),
      render: () => (
        <EndCard
          closing={p.message}
          name={p.name}
          palette={p.palette}
          brand={p.brand}
          closingSize={54}
        >
          <Stamp />
        </EndCard>
      ),
    });
    return scenes;
  },
};

function CountUp({ to, color }: { to: number; color: string }) {
  const f = useCurrentFrame();
  const v = Math.round(
    interpolate(f, [8, 44], [1, to], { ...clamp, easing: Easing.out(Easing.cubic) }),
  );
  return (
    <AbsoluteFill style={{ alignItems: 'center', paddingTop: 560 }}>
      <div
        style={{ fontFamily: font.display, fontWeight: 700, fontSize: 360, color, lineHeight: 1 }}
      >
        {v}
      </div>
    </AbsoluteFill>
  );
}

function Stamp() {
  const f = useCurrentFrame();
  const s = interpolate(f, [50, 60], [1.3, 1], clamp);
  const o = interpolate(f, [50, 54], [0, 1], clamp);
  return (
    <Img
      src={art('seal-100')}
      style={{
        position: 'absolute',
        top: 300,
        width: 220,
        transform: `scale(${s}) rotate(-8deg)`,
        opacity: o,
      }}
    />
  );
}

// ---------------------------------------------------------------- V09 Half a Year With You

/** Month chapters from the labels ("Tháng 3" / "Month 3"); none without dates. */
function chapters(p: StoryProps): { label: string | null; photos: number[] }[] {
  const order = chronological(p);
  if (!p.photoInfo?.some((x) => x.label)) return [{ label: null, photos: order }];
  const out: { label: string | null; photos: number[] }[] = [];
  for (const i of order) {
    const l = labelAt(p, i);
    const last = out[out.length - 1];
    if (last && last.label === l) last.photos.push(i);
    else out.push({ label: l, photos: [i] });
  }
  return out.slice(0, 7);
}

const halfYear: StoryDef = {
  // The first photo, after the intro and its month card.
  posterScene: (p) => (chapters(p)[0]?.label ? 2 : 1),
  scenes: (p) => {
    const ch = chapters(p);
    const cards = ch.filter((c) => c.label).length;
    const n = p.photos.length;
    const per = perPhoto(p.durationSec, fixed(4, 4, cards * 0.8), n, 2.0, 2.6);
    const { background, ink, accent } = p.palette;
    const scenes: Scene[] = [
      {
        len: sec(4),
        overlap: 18,
        render: () => (
          <Page bg={background}>
            <AbsoluteFill style={{ alignItems: 'center', justifyContent: 'center' }}>
              <div
                style={{
                  fontFamily: font.display,
                  fontWeight: 700,
                  fontSize: 900,
                  color: accent,
                  opacity: 0.15,
                  lineHeight: 1,
                }}
              >
                6
              </div>
            </AbsoluteFill>
            <Title
              text={p.title}
              fontFamily={font.serif}
              size={88}
              weight={600}
              color={ink}
              sub={p.dateLine}
            />
          </Page>
        ),
      },
    ];
    let k = 0;
    const lift = Math.floor(n * 0.6);
    for (const c of ch) {
      if (c.label) {
        scenes.push({
          len: sec(0.8),
          overlap: 8,
          enter: 'slideLeft',
          render: () => (
            <Page bg={background}>
              <AbsoluteFill style={{ alignItems: 'center', justifyContent: 'center' }}>
                <div
                  style={{
                    fontFamily: font.sans,
                    fontWeight: 700,
                    fontSize: 92,
                    letterSpacing: '0.12em',
                    color: ink,
                    textTransform: 'uppercase',
                  }}
                >
                  {c.label}
                </div>
                <div style={{ width: 160, height: 4, backgroundColor: accent, marginTop: 24 }} />
              </AbsoluteFill>
            </Page>
          ),
        });
      }
      for (const i of c.photos) {
        const late = k >= lift;
        scenes.push({
          len: late ? Math.round(per * 0.85) : per,
          overlap: 15,
          render: (len) => (
            <>
              <PhotoFill
                src={photoAt(p, i)}
                len={len}
                from={late ? 1.05 : 1}
                to={late ? 1.15 : 1.08}
                drift={k % 2 ? 25 : -25}
              />
              {k === lift && <LightLeak color={accent} />}
            </>
          ),
        });
        k++;
      }
    }
    scenes.push({
      len: sec(4),
      render: () => (
        <EndCard
          closing={p.closing || ''}
          name={p.name}
          sub={p.dateLine}
          palette={p.palette}
          brand={p.brand}
        />
      ),
    });
    return scenes;
  },
};

// ---------------------------------------------------------------- V10 A Letter to My Baby

function sentences(text: string): string[] {
  return (text.match(/[^.!?…]+[.!?…]*/g) ?? []).map((s) => s.trim()).filter(Boolean);
}

const letterToBaby: StoryDef = {
  scenes: (p) => {
    const n = p.photos.length;
    const parts = sentences(p.letter ?? '');
    const { background, ink } = p.palette;
    const greeting = p.locale === 'en' ? `Dear ${p.name},` : `Gửi con, ${p.name}`;
    const scenes: Scene[] = [
      {
        len: sec(5),
        overlap: 20,
        render: () => (
          <Page bg={background}>
            <LinedPaper />
            <TypeReveal
              text={greeting}
              perFrame={1.2}
              delay={15}
              style={{
                position: 'absolute',
                left: 140,
                top: 760,
                right: 120,
                fontFamily: font.hand,
                fontSize: 96,
                color: ink,
              }}
            />
          </Page>
        ),
      },
    ];
    if (parts.length === 0) {
      const per = perPhoto(p.durationSec, fixed(5, 4), n, 2.4, 3.6);
      for (let i = 0; i < n; i++)
        scenes.push({
          len: per,
          overlap: 20,
          render: (len) => <PhotoFill src={photoAt(p, i)} len={len} />,
        });
    } else {
      // A photo per sentence (cycled), long enough to read it.
      const steps = Math.max(n, parts.length);
      const budget = sec(p.durationSec) - sec(9);
      for (let i = 0; i < steps; i++) {
        const sentence = parts[i % parts.length]!;
        const len = Math.max(
          sec(2.4),
          Math.min(sec(5), Math.round(budget / steps), sec(sentence.length * 0.06)),
        );
        scenes.push({
          len,
          overlap: 20,
          render: (l) => (
            <Page bg={background}>
              <PhotoBlurFill
                src={photoAt(p, i)}
                len={l}
                radius={28}
                style={{ left: 60, top: 140, width: W - 120, height: H * 0.55 - 140 }}
              />
              <div
                style={{
                  position: 'absolute',
                  left: 60,
                  right: 60,
                  top: H * 0.57,
                  bottom: 330,
                  backgroundColor: '#FFFDF7',
                  borderRadius: 24,
                  boxShadow: '0 10px 30px rgba(0,0,0,0.08)',
                }}
              />
              <TypeReveal
                text={sentence}
                perFrame={1.6}
                delay={8}
                style={{
                  position: 'absolute',
                  left: 120,
                  right: 120,
                  top: H * 0.6,
                  fontFamily: font.hand,
                  fontSize: 60,
                  lineHeight: 1.35,
                  color: ink,
                }}
              />
            </Page>
          ),
        });
      }
    }
    scenes.push({
      len: sec(4),
      render: () => (
        <EndCard
          closing={p.closing || ''}
          palette={p.palette}
          brand={p.brand}
          closingFont={font.hand}
          italic={false}
          closingSize={72}
        >
          <LinedPaper />
        </EndCard>
      ),
    });
    return scenes;
  },
};

function LinedPaper() {
  return (
    <AbsoluteFill
      style={{
        backgroundColor: '#FFFDF7',
        backgroundImage:
          'repeating-linear-gradient(0deg, transparent 0 86px, rgba(120,160,200,0.25) 86px 89px)',
        backgroundPosition: '0 40px',
      }}
    >
      <div
        style={{
          position: 'absolute',
          left: 110,
          top: 0,
          bottom: 0,
          width: 4,
          backgroundColor: 'rgba(232,148,154,0.5)',
        }}
      />
    </AbsoluteFill>
  );
}

// ---------------------------------------------------------------- V11 Then & Now

const thenAndNow: StoryDef = {
  scenes: (p) => {
    const order = chronological(p);
    const pairs: [number, number | null][] = [];
    for (let a = 0, b = order.length - 1; a <= b; a++, b--)
      pairs.push([order[a]!, a === b ? null : order[b]!]);
    // One pair holds longer (up to 10 s) so two photos still make a 15 s video.
    const pairLen = Math.min(
      sec(10),
      Math.max(sec(4), Math.round((sec(p.durationSec) - sec(5)) / Math.max(1, pairs.length))),
    );
    const { background, ink, accent } = p.palette;
    const vi = p.locale !== 'en';
    const scenes: Scene[] = [
      {
        len: sec(2),
        overlap: 12,
        render: () => (
          <Page bg={background}>
            <Title text={p.title} size={130} color={ink} by="letter" />
          </Page>
        ),
      },
    ];
    for (const [a, b] of pairs) {
      scenes.push({
        len: b === null ? Math.round(pairLen * 0.6) : pairLen,
        overlap: 12,
        render: (len) =>
          b === null ? (
            <PhotoFill src={photoAt(p, a)} len={len} />
          ) : (
            <SplitCompare
              a={photoAt(p, a)}
              b={photoAt(p, b)}
              labelA={labelAt(p, a) ?? (vi ? 'Lúc ấy' : 'Then')}
              labelB={labelAt(p, b) ?? (vi ? 'Bây giờ' : 'Now')}
              len={len}
              accent={accent}
              ink={ink}
              bg={background}
            />
          ),
      });
    }
    scenes.push({
      len: sec(3),
      render: () => (
        <EndCard
          closing={p.closing || ''}
          name={p.name}
          palette={p.palette}
          brand={p.brand}
          closingFont={font.sans}
          italic={false}
        />
      ),
    });
    return scenes;
  },
};

// ---------------------------------------------------------------- V12 My First Birthday

const firstBirthday: StoryDef = {
  scenes: (p) => {
    const order = chronological(p);
    const n = order.length;
    const per = perPhoto(p.durationSec, fixed(3.5, 3, 4.5), n, 1.8, 2.4);
    const { background, ink, accent } = p.palette;
    const confetti = [accent, '#F7D67A', '#9FD8CB', '#C9B8E8', '#A9CBEB'];
    const scenes: Scene[] = [
      { len: sec(3.5), overlap: 10, render: () => <Countdown /> },
      {
        len: sec(3),
        overlap: 15,
        enter: 'zoom',
        render: () => (
          <Page bg={background}>
            <Particles kind="confetti" count={50} colors={confetti} />
            <Floating name="balloons" />
            <Slam text={p.headline || '1'} color={accent} />
            <Title
              text={p.title}
              fontFamily={font.round}
              size={72}
              weight={700}
              color={ink}
              top={1250}
              delay={15}
            />
          </Page>
        ),
      },
    ];
    order.forEach((i, k) => {
      const two = k % 4 === 3 && k + 1 < n;
      scenes.push({
        len: per,
        overlap: 15,
        enter: k % 3 === 0 ? 'wipe' : 'slideLeft',
        render: (len) => (
          <Page bg={background}>
            <Particles kind="confetti" count={14} colors={confetti} seed={`c${k}`} />
            {two ? (
              <Collage srcs={[photoAt(p, i), photoAt(p, order[k + 1]!)]} len={len} />
            ) : (
              <Framed
                src={photoAt(p, i)}
                len={len}
                kind="polaroid"
                width={800}
                height={980}
                tilt={k % 2 ? 3 : -3}
              />
            )}
            <AgeTag label={labelAt(p, i)} bg={accent} bottom={320} />
          </Page>
        ),
      });
    });
    scenes.push({
      len: sec(4.5),
      render: () => (
        <EndCard
          closing={p.closing || ''}
          name={p.name}
          palette={p.palette}
          brand={p.brand}
          closingFont={font.round}
          italic={false}
          closingSize={74}
        >
          <CakeRise />
          <Burst at={sec(3)} colors={confetti} seed="cake" />
        </EndCard>
      ),
    });
    return scenes;
  },
};

function Countdown() {
  const f = useCurrentFrame();
  const step = Math.min(2, Math.floor(f / 30));
  const local = f - step * 30;
  const s = interpolate(local, [0, 15], [1.5, 1], { ...clamp, easing: Easing.out(Easing.cubic) });
  const o = interpolate(local, [0, 6, 24, 30], [0, 1, 1, 0], clamp);
  const flash = interpolate(f, [90, 105], [0, 1], clamp);
  return (
    <AbsoluteFill
      style={{ backgroundColor: '#14213D', alignItems: 'center', justifyContent: 'center' }}
    >
      <Particles kind="stars" count={30} colors={['#FFFFFF', '#F7D67A']} />
      <div
        style={{
          fontFamily: font.round,
          fontWeight: 800,
          fontSize: 460,
          color: '#FFFFFF',
          transform: `scale(${s})`,
          opacity: f < 90 ? o : 0,
        }}
      >
        {3 - step}
      </div>
      <AbsoluteFill style={{ backgroundColor: '#FFFFFF', opacity: flash }} />
    </AbsoluteFill>
  );
}

function Slam({ text, color }: { text: string; color: string }) {
  const f = useCurrentFrame();
  const s = interpolate(f, [0, 10, 16], [2, 0.92, 1], clamp);
  return (
    <AbsoluteFill style={{ alignItems: 'center', paddingTop: 560 }}>
      <div
        style={{
          fontFamily: font.round,
          fontWeight: 800,
          fontSize: text.length > 3 ? 280 : 420,
          lineHeight: 1,
          color,
          transform: `scale(${s})`,
        }}
      >
        {text}
      </div>
    </AbsoluteFill>
  );
}

function Floating({ name }: { name: string }) {
  const f = useCurrentFrame();
  const y = interpolate(f, [0, 90], [500, -300]);
  return (
    <Img
      src={art(name)}
      style={{
        position: 'absolute',
        left: 40,
        top: 300,
        width: 330,
        transform: `translateY(${y}px) rotate(${Math.sin(f / 12) * 4}deg)`,
      }}
    />
  );
}

function CakeRise() {
  const f = useCurrentFrame();
  const y = interpolate(f, [0, 25], [200, 0], { ...clamp, easing: Easing.out(Easing.back(1.4)) });
  return (
    <Img
      src={art('cake-one-candle')}
      style={{ position: 'absolute', top: 260, width: 320, transform: `translateY(${y}px)` }}
    />
  );
}

// ---------------------------------------------------------------- Registry

export const chapter1: Record<string, StoryDef> = {
  WelcomeWorld: welcomeWorld,
  OurFirstDays: ourFirstDays,
  LittleLoveStory: littleLoveStory,
  TinyMoments: tinyMoments,
  GrowingSoFast: growingSoFast,
  HelloSmile: helloSmile,
  FirstMilestone: firstMilestone,
  HundredDaysLove: hundredDaysLove,
  HalfYear: halfYear,
  LetterToBaby: letterToBaby,
  ThenAndNow: thenAndNow,
  FirstBirthday: firstBirthday,
};

/** Frames of a Chapter 01 video for these props. */
export function chapter1Frames(id: string, p: StoryProps): number {
  return layout(chapter1[id]!.scenes(p)).total;
}

/** The poster: the middle of the first photo scene (the scene after the intro). */
export function chapter1Poster(id: string, p: StoryProps): number {
  const def = chapter1[id]!;
  const scenes = def.scenes(p);
  const { starts } = layout(scenes);
  const i = Math.min(def.posterScene?.(p) ?? 1, scenes.length - 1);
  return starts[i]! + Math.floor(scenes[i]!.len / 2);
}

/** One Chapter 01 video: its scenes, the corner logo and the music. */
export function Chapter1Story(props: StoryProps & { composition: string }) {
  const def = chapter1[props.composition]!;
  const scenes = def.scenes(props);
  const { starts, total } = layout(scenes);
  const endStart = starts[starts.length - 1]!;
  // Full-bleed photo videos: a white logo with a shadow over the photos.
  const photoScenes = new Set(['GrowingSoFast', 'HalfYear', 'ThenAndNow']);
  return (
    <AbsoluteFill style={{ backgroundColor: props.palette.background }}>
      <Fonts />
      <Timeline scenes={scenes} />
      <BrandCorner
        brand={props.brand}
        until={endStart}
        tone={(f) =>
          photoScenes.has(props.composition) && f > starts[1]! && f < endStart
            ? { color: '#FFFFFF', shadow: true }
            : { color: props.palette.ink, shadow: false }
        }
      />
      <Music src={props.music} total={total} />
    </AbsoluteFill>
  );
}
