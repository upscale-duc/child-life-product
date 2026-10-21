import type { CSSProperties } from 'react';
import { LumiMascot, type Tint } from '../components/kit';
import { Eyebrow, Fit, Icon, at, type IconName } from '../components/primitives';
import { AppCta } from '../components/StoreBadges';
import { useSite } from '../context';
import { staggerStyle } from '../motion';
import { Ask, Draft, Reply } from './Lumi';

/* The Lumi page (V9 Figma 785:9913, 39-landing-v9-lumi-and-stages; first built from 650:4798, 33).
   Every mock is HTML so its copy translates. */

const draftLook: { icon: IconName; tint: Tint }[] = [
  { icon: 'feed', tint: 'bottle' },
  { icon: 'sleep', tint: 'sleep' },
  { icon: 'diaper', tint: 'diaper' },
];

/** The chat mock-up "Mock · Chat với Lumi" (33 §2.2), also on the V8 home (34 §6). */
export function LumiChatCard({ style }: { style?: CSSProperties }) {
  const { c } = useSite();
  const m = c.lumiPage.hero.mock;
  return (
    <div className="lp-chat" style={style}>
      <span className="lp-chat__head">
        <LumiMascot size={36} />
        <span>
          <strong>{m.name}</strong>
          <span>{m.family}</span>
        </span>
      </span>
      <Ask>{m.ask}</Ask>
      <Reply>
        {m.reply}
        {m.drafts.map((d, i) => (
          <Draft key={d.title} {...draftLook[i]!} {...d} label={m.draft} />
        ))}
        <span className="lp-chat__save">{m.saveAll}</span>
      </Reply>
      <Ask>{m.ask2}</Ask>
      <Reply>{m.reply2}</Reply>
      <span className="lp-chat__composer">
        <Icon name="camera" size={16} />
        <span>{m.composer}</span>
        <span className="lp-chat__send">
          <Icon name="arrow-right" size={14} />
        </span>
      </span>
    </div>
  );
}

/** Hero (§2): copy, promise chips and the chat mock with its two floating cards. */
export function LumiHero() {
  const { c } = useSite();
  const h = c.lumiPage.hero;
  const m = h.mock;
  return (
    <section id="gioi-thieu" className="lp-hero container" aria-labelledby="lumi-title">
      <div className="lp-hero__copy reveal">
        <span className="lumi-eyebrow">
          <LumiMascot size={52} />
          <span className="eyebrow eyebrow--sleep">{h.eyebrow}</span>
        </span>
        <h1 id="lumi-title" className="lp-hero__title">
          <span>{h.title[0]}</span> <span>{h.title[1]}</span>
        </h1>
        <p className="lp-hero__lead">{h.lead}</p>
        <div className="lp-hero__actions">
          <a className="lumi-button lumi-button--lg pressable" href="#tai-app">
            {h.tryNow}
          </a>
        </div>
        <ul className="lp-hero__promises">
          {h.promises.map((promise) => (
            <li key={promise}>
              <Icon name="check" size={12} />
              {promise}
            </li>
          ))}
        </ul>
      </div>
      <div className="lp-hero__visual reveal">
        {/* 544 × 721 mock-up plus the 40 px the floats overhang on each side (§2.2). */}
        <Fit w={624} h={721} mobileScale={0.54}>
          <span className="lp-mock" style={at(40, 0)} />
          <LumiChatCard style={at(112, 48)} />
          <span className="lp-float lp-float--saved" style={at(0, 30)}>
            <span className="lp-float__check">
              <Icon name="check" size={12} />
            </span>
            {m.saved}
          </span>
          <span className="lp-float lp-float--expense" style={at(364, 613)}>
            <Draft icon="grid" tint="peach" label={m.draft} {...m.expense} />
          </span>
          <span className="lp-sample" style={at(431, 24)}>
            <Icon name="eye" size={12} />
            {m.sample}
          </span>
        </Fit>
      </div>
    </section>
  );
}

const benefitLook: { tint: Tint; icon: IconName; ink: string }[] = [
  { tint: 'bottle', icon: 'clock', ink: 'bottle' },
  { tint: 'mint', icon: 'journal', ink: 'mint' },
  { tint: 'sun', icon: 'star', ink: 'ink' },
  { tint: 'peach', icon: 'heart', ink: 'ink' },
];

/** Lợi ích (§3): four benefit cards. */
export function LumiBenefits() {
  const { c } = useSite();
  const b = c.lumiPage.benefits;
  return (
    <section id="loi-ich" className="lp-band" aria-labelledby="benefits-title">
      <div className="container">
        <header className="section-head section-head--center reveal">
          <Eyebrow tone="mint">{b.eyebrow}</Eyebrow>
          <h2 id="benefits-title" className="h2 h2--flat lp-h2">
            {b.title}
          </h2>
        </header>
        <ul className="lp-benefits">
          {b.cards.map((card, i) => {
            const look = benefitLook[i]!;
            return (
              <li key={card.title} className="lp-benefit reveal" style={staggerStyle(i)}>
                <span className={`lp-icon tint--${look.tint}`}>
                  <Icon name={look.icon} size={20} className={`ink--${look.ink}`} />
                </span>
                <h3>{card.title}</h3>
                <p>{card.body}</p>
              </li>
            );
          })}
        </ul>
      </div>
    </section>
  );
}

// Lumi hiểu cả app (39 §A.4): icon and tint per module, in Figma order.
const moduleLooks: { icon: IconName; tint: Tint }[] = [
  { icon: 'today', tint: 'bottle' },
  { icon: 'star', tint: 'sleep' },
  { icon: 'drop', tint: 'sun' },
  { icon: 'memories', tint: 'diaper' },
  { icon: 'family', tint: 'mint' },
  { icon: 'clock', tint: 'plain' },
];

/** Lumi hiểu cả app (V9, Figma 791:68734): one assistant over six parts of the app, each with a
 *  sample question and answer, then what Lumi can do. Q-039: finding photos, counting who logged
 *  and the weekly summary are not built (P-167). */
export function LumiModules() {
  const { c } = useSite();
  const m = c.lumiPage.modules;
  return (
    <section id="hieu-ca-app" className="lp-modules" aria-labelledby="modules-title">
      <div className="container lp-modules__inner">
        <header className="section-head section-head--center reveal">
          <Eyebrow tone="mint">{m.eyebrow}</Eyebrow>
          <h2 id="modules-title" className="h2 h2--flat lp-h2 lp-h2--42">
            {m.title}
          </h2>
          <p className="lead">{m.lead}</p>
        </header>
        <p className="lp-modules__pill reveal">
          <LumiMascot size={52} />
          <span>
            <strong>{c.lumiPage.hero.mock.name}</strong>
            <span>{m.sub}</span>
          </span>
        </p>
        <ul className="lp-modules__grid">
          {m.items.map((item, i) => (
            <li key={item.title} className="lp-module reveal" style={staggerStyle(i % 3)}>
              <span className="lp-module__head">
                <span className={`lp-icon tint--${moduleLooks[i]!.tint}`}>
                  <Icon name={moduleLooks[i]!.icon} size={16} />
                </span>
                <span>
                  <h3>{item.title}</h3>
                  <span>{item.sub}</span>
                </span>
              </span>
              <p className="lp-module__q">“{item.q}”</p>
              <p className="lp-module__a">
                <Icon name="spark" size={14} className="ink--mint" />
                {item.a}
              </p>
            </li>
          ))}
        </ul>
        <div className="lp-modules__can reveal">
          <span>{m.canLabel}</span>
          <ul>
            {m.can.map((item) => (
              <li key={item}>{item}</li>
            ))}
          </ul>
        </div>
      </div>
    </section>
  );
}

const trustIcons: IconName[] = ['eye', 'lock', 'alert'];

/** Cách Lumi làm việc (§7): the dark card with three steps and the trust lines. */
export function LumiHow() {
  const { c } = useSite();
  const h = c.lumiPage.how;
  return (
    <section id="cach-lam-viec" className="lp-section container" aria-labelledby="how-title">
      <div className="lp-how reveal">
        <header className="lp-how__head">
          <Eyebrow tone="sun-ink">{h.eyebrow}</Eyebrow>
          <h2 id="how-title" className="h2 h2--flat lp-h2">
            {h.title}
          </h2>
        </header>
        <ol className="lp-how__steps">
          {h.steps.map((step, i) => (
            <li key={step.title}>
              <span className="lp-how__num" aria-hidden="true">
                {i + 1}
              </span>
              <h3>{step.title}</h3>
              <p>{step.body}</p>
            </li>
          ))}
        </ol>
        <ul className="lp-how__trust">
          {h.trust.map((line, i) => (
            <li key={line}>
              <Icon name={trustIcons[i]!} size={18} />
              {line}
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}

/** Hỏi đáp (§9): the Lumi questions, first one open; native <details> as on the home. */
export function LumiFaq() {
  const { c } = useSite();
  const f = c.lumiPage.faq;
  return (
    <section id="hoi-dap" className="faq lp-faq container" aria-labelledby="faq-title">
      <header className="faq__head reveal">
        <Eyebrow tone="mint">{f.eyebrow}</Eyebrow>
        <h2 id="faq-title" className="faq__title">
          {f.title}
        </h2>
      </header>
      <div className="faq__list">
        {f.items.map((item, i) => (
          <details
            key={item.q}
            className="faq-item reveal"
            open={item.open}
            style={staggerStyle(i)}
          >
            <summary>
              <h3>{item.q}</h3>
              <span className="faq-item__icons" aria-hidden="true">
                <Icon name="plus" size={20} className="faq-item__plus" />
                <Icon name="chevron-down" size={20} className="faq-item__chevron" />
              </span>
            </summary>
            <p className="faq-item__answer">{item.a}</p>
          </details>
        ))}
      </div>
    </section>
  );
}

/** Kết (V9, Figma 785:10721): a centred gradient card. The store badges stand in for the drawn
 *  "Mở Lumi trong app" pill — the web has no link into the app's Lumi (39 §A.7), and the nav's
 *  "Bắt đầu" and the hero button land here. */
export function LumiCta() {
  const { c } = useSite();
  return (
    <section id="tai-app" className="lp-section container" aria-labelledby="cta-title">
      <div className="lp-cta reveal">
        <LumiMascot size={56} />
        <h2 id="cta-title" className="lp-cta__title">
          {c.lumiPage.cta.title}
        </h2>
        <AppCta tone="dark" />
      </div>
    </section>
  );
}
