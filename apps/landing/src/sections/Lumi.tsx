import type { CSSProperties, ReactNode } from 'react';
import { LumiMascot, type Tint } from '../components/kit';
import { Fit, Icon, at, type IconName } from '../components/primitives';
import { scenes } from '../components/scenes';
import { useSite } from '../context';
import { staggerStyle } from '../motion';
import { pathOf } from '../routes';

/* ---------- Chat mock parts (the app's Chat/Tin nhắn and Chat/Thẻ nháp, 31-chat-assistant) ---------- */

export function Ask({ children }: { children: ReactNode }) {
  return (
    <span className="chat-row chat-row--parent">
      <span className="chat-bubble chat-bubble--parent">{children}</span>
    </span>
  );
}

export function Reply({ children }: { children: ReactNode }) {
  return (
    <span className="chat-row">
      <span className="chat-avatar">
        <Icon name="spark" size={12} />
      </span>
      <span className="chat-bubble">{children}</span>
    </span>
  );
}

export function Source({ icon, children }: { icon: IconName; children: ReactNode }) {
  return (
    <span className="chat-source">
      <Icon name={icon} size={11} />
      {children}
    </span>
  );
}

export function Draft({
  icon,
  tint,
  title,
  sub,
  label,
}: {
  icon: IconName;
  tint: Tint;
  title: string;
  sub: string;
  label: string;
}) {
  return (
    <span className="chat-draft">
      <span className={`chat-draft__icon tint--${tint}`}>
        <Icon name={icon} size={16} />
      </span>
      <span className="chat-draft__text">
        <strong>{title}</strong>
        <span>{sub}</span>
      </span>
      <span className="chat-draft__chip">{label}</span>
    </span>
  );
}

/* ---------- Lumi block in the Chặng 1 frame (32-landing-v6-home §4) ---------- */

// Orbit chips (§4.2): position in the 516 × 340 stage, icon circle tint, icon, icon ink.
const orbit: { x: number; y: number; tint: Tint; icon: IconName; ink: string }[] = [
  { x: 0, y: 0, tint: 'bottle', icon: 'feed', ink: 'bottle' },
  { x: 262, y: 22, tint: 'sleep', icon: 'sleep', ink: 'sleep' },
  { x: -18, y: 140, tint: 'sun', icon: 'bookmark', ink: 'ink' },
  { x: 327, y: 140, tint: 'peach', icon: 'camera', ink: 'ink' },
  { x: 10, y: 268, tint: 'growth', icon: 'camera', ink: 'growth' },
  { x: 266, y: 290, tint: 'mint', icon: 'journal', ink: 'mint' },
];

const featureTints = ['bottle', 'mint', 'sleep', 'sun', 'peach', 'coral'] as const;

function OrbitChip({ i, style }: { i: number; style?: CSSProperties }) {
  const { c } = useSite();
  const o = orbit[i]!;
  return (
    <span className="lumi-chip" style={style}>
      <span className={`lumi-chip__icon tint--${o.tint}`}>
        <Icon name={o.icon} size={14} className={`ink--${o.ink}`} />
      </span>
      {c.home.lumi.suggestions[i]}
    </span>
  );
}

export function FeatureMock({ index }: { index: number }) {
  const { c } = useSite();
  const m = c.home.lumi.mock;
  switch (index) {
    case 0:
      return (
        <>
          <Ask>{m.logAsk}</Ask>
          <Draft icon="feed" tint="bottle" label={m.draft} {...m.drafts[0]} />
          <Draft icon="sleep" tint="sleep" label={m.draft} {...m.drafts[1]} />
        </>
      );
    case 1:
      return (
        <>
          <Ask>{m.dataAsk}</Ask>
          <Reply>
            {m.dataAnswer}
            <Source icon="link">{m.dataSource}</Source>
          </Reply>
        </>
      );
    case 2:
      return (
        <>
          <Ask>{m.sleepAsk}</Ask>
          <Reply>
            {m.sleepAnswer}
            <span className="chat-sources">
              <Source icon="sleep">{m.sleepSources[0]}</Source>
              <Source icon="journal">{m.sleepSources[1]}</Source>
            </span>
          </Reply>
        </>
      );
    case 3:
      return (
        <>
          <Ask>{m.mealAsk}</Ask>
          <Reply>
            {m.mealAnswer}
            <span className="chat-sources chat-sources--column">
              {m.meals.map((meal) => (
                <Source key={meal} icon="bookmark">
                  {meal}
                </Source>
              ))}
            </span>
          </Reply>
        </>
      );
    case 4:
      return (
        <>
          <span className="chat-receipt-row">
            <span className="chat-receipt">
              <i />
              <i />
              <i />
              <b>{m.receipt.amount}</b>
            </span>
            <Draft
              icon="grid"
              tint="white"
              label={m.draft}
              title={m.receipt.title}
              sub={m.receipt.sub}
            />
          </span>
          <span className="chat-note">{m.receipt.note}</span>
        </>
      );
    default:
      return (
        <span className="chat-video">
          <img src={scenes.thenBaby} alt="" loading="lazy" decoding="async" />
          <span className="chat-video__play">
            <Icon name="arrow-right" size={16} />
          </span>
          <span className="chat-video__chip">
            <Icon name="camera" size={11} />
            {m.video}
          </span>
        </span>
      );
  }
}

/** Lumi in the Chặng 1 frame (32-landing-v6-home §4): intro with the suggestion orbit, then six
 *  features each shown as a chat mock-up. */
export function LumiBlock() {
  const { c, route } = useSite();
  const l = c.home.lumi;
  return (
    <div id="lumi" className="lumi-block">
      <div className="lumi-block__head">
        <div className="lumi-block__copy reveal">
          <span className="lumi-eyebrow">
            <LumiMascot size={44} />
            <span className="eyebrow eyebrow--sleep">{l.eyebrow}</span>
          </span>
          <h3 id="lumi-title" className="lumi-block__title">
            {l.title}
          </h3>
          <p className="lumi-block__lead">{l.lead}</p>
          <a className="lumi-button pressable" href={pathOf('lumi', route.locale)}>
            {l.cta}
            <Icon name="arrow-right" size={16} />
          </a>
        </div>
        <div className="lumi-orbit only-desktop reveal" aria-hidden="true">
          <Fit w={516} h={340} mobileScale={0.57}>
            <span className="lumi-orbit__glow" style={at(118, 50)} />
            <span className="lumi-orbit__ring lumi-orbit__ring--1" style={at(158, 70)} />
            <span className="lumi-orbit__ring lumi-orbit__ring--2" style={at(28, 20)} />
            {[
              [354, 158, '#FFD166'],
              [24, 176, '#2CBFB3'],
              [404, 286, '#6C6FD8'],
              [134, 26, '#FFA58D'],
            ].map(([x, y, color]) => (
              <span
                key={color}
                className="lumi-orbit__dot"
                style={at(x as number, y as number, { background: color as string })}
              />
            ))}
            <LumiMascot size={104} style={at(206, 112)} />
            <span className="lumi-name" style={at(215.5, 220)}>
              {l.name}
              <span className="lumi-name__dots">
                <i />
                <i />
                <i />
              </span>
            </span>
            {orbit.map((o, i) => (
              <OrbitChip key={i} i={i} style={at(o.x, o.y)} />
            ))}
          </Fit>
        </div>
        <div className="lumi-orbit-mobile only-mobile reveal" aria-hidden="true">
          <LumiMascot size={72} />
          <span className="lumi-orbit-mobile__chips">
            {orbit.map((_, i) => (
              <OrbitChip key={i} i={i} />
            ))}
          </span>
        </div>
      </div>
      <ul className="lumi-features">
        {l.features.map((feature, i) => (
          <li key={feature.title} className="lumi-feature reveal" style={staggerStyle(i % 3)}>
            <div
              className={`lumi-feature__art tint--${featureTints[i]}${i === 5 ? ' lumi-feature__art--flush' : ''}`}
              aria-hidden="true"
            >
              <FeatureMock index={i} />
            </div>
            <div className="lumi-feature__text">
              <h4>{feature.title}</h4>
              <p>{feature.body}</p>
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}

/* ---------- Lumi · suốt hành trình (32-landing-v6-home §6), shared with the Lumi page ---------- */

const stageChips: Tint[] = ['mint', 'sun', 'peach', 'sleep'];

/** Lumi growing stage by stage: head, a path where the mascot grows, four stage columns and an
 *  outro. `cta` is the outro button (home → the Lumi page; Lumi page → the download band). */
export function LumiJourney({ cta }: { cta: { label: string; href: string } }) {
  const { c } = useSite();
  const lj = c.lumiJourney;
  const j = c.journey;
  return (
    <div id="lumi-hanh-trinh" className="lumi-journey">
      <div className="lumi-journey__head reveal">
        <div className="lumi-journey__title">
          <span className="lumi-eyebrow">
            <LumiMascot size={36} />
            <span className="eyebrow eyebrow--sleep">{lj.eyebrow}</span>
          </span>
          <h3 id="lumi-journey-title">{lj.title}</h3>
        </div>
        <p>{lj.lead}</p>
      </div>
      <div className="lumi-path only-desktop" aria-hidden="true">
        <span className="lumi-path__line" />
        <span className="lumi-path__progress" />
        {[54, 32.2, 37.2, 42.2].map((size, i) => (
          <span key={i} className={`lumi-path__node lumi-path__node--${i + 1}`}>
            {i > 0 && <span className="lumi-path__ring" />}
            <LumiMascot size={size} style={{ opacity: [1, 0.57, 0.69, 0.81][i] }} />
          </span>
        ))}
      </div>
      <ol className="lumi-stages">
        {lj.stages.map((stage, i) => (
          <li
            key={stage.sub}
            className={i === 0 ? 'lumi-stage is-current reveal' : 'lumi-stage reveal'}
            style={staggerStyle(i)}
          >
            <span className="lumi-stage__head">
              <span className={`lumi-stage__chip tint--${stageChips[i]}`}>
                {j.number.replace('{n}', String(i + 1))} · {j.stages[i]!.ages}
              </span>
              <span className={i === 0 ? 'lumi-stage__status is-current' : 'lumi-stage__status'}>
                <Icon name={i === 0 ? 'check' : 'clock'} size={11} />
                {i === 0 ? lj.current : lj.planned}
              </span>
            </span>
            <strong className="lumi-stage__name">
              {i === 0 ? c.home.stages.firstName : j.stages[i]!.name}
            </strong>
            <span className="lumi-stage__sub">{stage.sub}</span>
            <ul className="lumi-stage__items">
              {stage.items.map((item) => (
                <li key={item.title}>
                  <Icon name="spark" size={14} />
                  <span>
                    <strong>{item.title}</strong>
                    {item.body && <span>{item.body}</span>}
                  </span>
                </li>
              ))}
            </ul>
          </li>
        ))}
      </ol>
      <div className="lumi-journey__outro reveal">
        <span>
          <strong>{lj.outroTitle}</strong>
          <span>{lj.outroBody}</span>
        </span>
        <a className="lumi-button pressable" href={cta.href}>
          {cta.label}
          <Icon name="arrow-right" size={16} />
        </a>
      </div>
    </div>
  );
}
