import { useState } from 'react';
import { LumiMascot, type Tint } from '../components/kit';
import { Eyebrow, Fit, Icon, at, type IconName } from '../components/primitives';
import { StoreBadges } from '../components/StoreBadges';
import { scenes } from '../components/scenes';
import { useSite } from '../context';
import { staggerStyle } from '../motion';
import { Ask, Draft, FeatureMock, Reply, Source } from './Lumi';

/* The Lumi page (Figma 650:4798, 33-landing-lumi-page). Every mock is HTML so its copy translates. */

/** Hero (§2): copy, promise chips and the chat mock with its two floating cards. */
export function LumiHero() {
  const { c } = useSite();
  const h = c.lumiPage.hero;
  const m = h.mock;
  const draftLook: { icon: IconName; tint: Tint }[] = [
    { icon: 'feed', tint: 'bottle' },
    { icon: 'sleep', tint: 'sleep' },
    { icon: 'diaper', tint: 'diaper' },
  ];
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
          <a className="lp-outline pressable" href="#goi">
            {h.plans}
            <Icon name="chevron-down" size={16} />
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
          <div className="lp-chat" style={at(112, 48)}>
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

// Một ngày (§4): illustration tint per card and the matching home feature mock (log, receipt,
// data, meal, sleep, video).
const dayLook: { tint: Tint; mock: number }[] = [
  { tint: 'bottle', mock: 0 },
  { tint: 'peach', mock: 4 },
  { tint: 'mint', mock: 1 },
  { tint: 'sun', mock: 3 },
  { tint: 'sleep', mock: 2 },
  { tint: 'coral', mock: 5 },
];

/** Một ngày cùng Lumi (§4): six moments, each with a chat mock. */
export function LumiDay() {
  const { c } = useSite();
  const d = c.lumiPage.day;
  return (
    <section id="mot-ngay" className="lp-section container" aria-labelledby="day-title">
      <header className="lp-split-head reveal">
        <div>
          <Eyebrow tone="sleep">{d.eyebrow}</Eyebrow>
          <h2 id="day-title" className="h2 h2--flat lp-h2 lp-h2--40">
            {d.title}
          </h2>
        </div>
        <p>{d.lead}</p>
      </header>
      <ul className="lp-day lp-rail">
        {d.cards.map((card, i) => {
          const look = dayLook[i]!;
          return (
            <li key={card.title} className="lumi-feature reveal" style={staggerStyle(i % 3)}>
              <div
                className={`lumi-feature__art tint--${look.tint}${look.mock === 5 ? ' lumi-feature__art--flush' : ''}`}
                aria-hidden="true"
              >
                <FeatureMock index={look.mock} />
              </div>
              <div className="lumi-feature__text">
                <span className="lp-time">
                  <Icon name="clock" size={12} />
                  {card.time}
                </span>
                <h3>{card.title}</h3>
                <p>{card.body}</p>
              </div>
            </li>
          );
        })}
      </ul>
    </section>
  );
}

const moreTints: Tint[] = ['growth', 'mint', 'sleep', 'sun'];

function MoreMock({ index }: { index: number }) {
  const { c } = useSite();
  const m = c.lumiPage.more.mock;
  switch (index) {
    case 0:
      return (
        <span className="lp-note-row">
          <span className="lp-note">
            {m.note.map((line) => (
              <span key={line}>{line}</span>
            ))}
          </span>
          <span className="lp-note-row__chips">
            {m.reminders.map((r) => (
              <Source key={r} icon="clock">
                {r}
              </Source>
            ))}
          </span>
        </span>
      );
    case 1:
    case 2: {
      const box = index === 1 ? m.week : m.rhythm;
      return (
        <span className="lp-mini-card">
          <strong>{box.title}</strong>
          <span>{box.body}</span>
        </span>
      );
    }
    default:
      return (
        <>
          <Ask>{m.ask}</Ask>
          <Reply>{m.reply}</Reply>
        </>
      );
  }
}

/** Còn nhiều việc (§5): four more things Lumi does. */
export function LumiMore() {
  const { c } = useSite();
  const m = c.lumiPage.more;
  return (
    <section id="viec-khac" className="lp-band" aria-labelledby="more-title">
      <div className="container">
        <header className="section-head lp-head-left reveal">
          <Eyebrow tone="mint">{m.eyebrow}</Eyebrow>
          <h2 id="more-title" className="h2 h2--flat lp-h2">
            {m.title}
          </h2>
          <p className="lead">{m.lead}</p>
        </header>
        <ul className="lp-more lp-rail">
          {m.cards.map((card, i) => (
            <li
              key={card.title}
              className="lumi-feature lp-more__card reveal"
              style={staggerStyle(i)}
            >
              <div className={`lumi-feature__art tint--${moreTints[i]}`} aria-hidden="true">
                <MoreMock index={i} />
              </div>
              <div className="lumi-feature__text">
                <h3>{card.title}</h3>
                <p>{card.body}</p>
              </div>
            </li>
          ))}
        </ul>
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

/** Gói (§8): period toggle, three plans, price note, comparison table and the credit rules.
 *  Q-039 / 33 §16: the plans and prices are not approved; the page is dev-only (noindex). The
 *  monthly state is prerendered; "Theo năm" swaps the prices once the page is interactive. */
export function LumiPlans() {
  const { c } = useSite();
  const p = c.lumiPage.plans;
  const [yearly, setYearly] = useState(false);
  const periods = [
    { yearly: false, label: p.monthly },
    { yearly: true, label: p.yearly },
  ];
  const features: { icon: IconName; text: (i: number) => string }[] = [
    { icon: 'check', text: () => p.features.all },
    { icon: 'camera', text: (i) => p.tiers[i]!.photos },
    { icon: 'heart', text: (i) => p.tiers[i]!.videos },
    { icon: 'grid', text: () => p.features.templates },
    { icon: 'check', text: () => p.features.drafts },
  ];
  const yes = (
    <span className="lp-yes" role="img" aria-label={p.table.yes}>
      <Icon name="check" size={13} />
    </span>
  );
  return (
    <section id="goi" className="lp-plans" aria-labelledby="plans-title">
      <div className="container lp-plans__inner">
        <header className="section-head section-head--center reveal">
          <Eyebrow tone="mint">{p.eyebrow}</Eyebrow>
          <h2 id="plans-title" className="h2 h2--flat lp-h2">
            {p.title}
          </h2>
          <p className="lead">{p.lead}</p>
        </header>
        <div
          className="lp-period reveal"
          role="radiogroup"
          aria-label={`${p.monthly} / ${p.yearly}`}
        >
          {periods.map((period) => (
            <button
              key={period.label}
              type="button"
              role="radio"
              aria-checked={yearly === period.yearly}
              className={yearly === period.yearly ? 'is-selected' : undefined}
              onClick={() => setYearly(period.yearly)}
              onKeyDown={(e) => {
                if (['ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown'].includes(e.key)) {
                  e.preventDefault();
                  setYearly(!yearly);
                  const other = e.currentTarget.parentElement?.querySelector<HTMLButtonElement>(
                    `button:not(:nth-child(${period.yearly ? 2 : 1}))`,
                  );
                  other?.focus();
                }
              }}
              tabIndex={yearly === period.yearly ? 0 : -1}
            >
              {period.label}
            </button>
          ))}
        </div>
        <ul className="lp-tiers">
          {p.tiers.map((tier, i) => (
            <li
              key={tier.name}
              className={`lp-tier lp-tier--${tier.name.toLowerCase()} reveal`}
              style={staggerStyle(i)}
            >
              <span className="lp-tier__head">
                {i > 0 && (
                  <span className="lp-tier__badge" aria-hidden="true">
                    <Icon name="spark" size={14} />
                  </span>
                )}
                <h3>{tier.name}</h3>
                <span className="lp-tier__tagline">{tier.tagline}</span>
              </span>
              <span className="lp-tier__credits">
                <strong>{tier.credits}</strong>
                <span>{p.credits}</span>
              </span>
              <ul className="lp-tier__features">
                {features.map((f, k) => (
                  <li key={k}>
                    <Icon name={f.icon} size={16} />
                    {f.text(i)}
                  </li>
                ))}
              </ul>
              <span className="lp-tier__price">
                <strong>{yearly ? tier.yearPrice : tier.price}</strong>
                <span>{yearly ? p.perYear : p.perMonth}</span>
              </span>
              <span className={i === 0 ? 'lp-tier__sub' : 'lp-tier__sub lp-tier__sub--mint'}>
                {yearly ? tier.yearSub : tier.sub}
              </span>
              <a className="lp-tier__button pressable" href="#tai-app">
                {tier.button}
              </a>
            </li>
          ))}
        </ul>
        <p className="lp-plans__note reveal">
          <Icon name="alert" size={14} />
          {p.note}
        </p>
        <div className="lp-table-wrap reveal">
          <table className="lp-table">
            <caption className="sr-only">{p.table.caption}</caption>
            <thead>
              <tr>
                <th scope="col">
                  <span className="sr-only">{p.table.feature}</span>
                </th>
                {p.tiers.map((tier) => (
                  <th key={tier.name} scope="col">
                    {tier.name}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              <tr>
                <th scope="row">{p.table.credits}</th>
                {p.tiers.map((tier) => (
                  <td key={tier.name}>{tier.credits}</td>
                ))}
              </tr>
              {p.table.rows.map((row) => (
                <tr key={row}>
                  <th scope="row">{row}</th>
                  {p.tiers.map((tier) => (
                    <td key={tier.name}>{yes}</td>
                  ))}
                </tr>
              ))}
              <tr>
                <th scope="row">{p.table.videos}</th>
                {p.tiers.map((tier) => (
                  <td key={tier.name}>{tier.videos.replace(/\D.*$/, '')}</td>
                ))}
              </tr>
              <tr>
                <th scope="row">{p.table.fallback}</th>
                {p.tiers.map((tier) => (
                  <td key={tier.name}>{yes}</td>
                ))}
              </tr>
            </tbody>
          </table>
        </div>
        <div className="lp-credits reveal">
          <div className="lp-credits__intro">
            <span className="lp-icon tint--sleep">
              <Icon name="spark" size={18} />
            </span>
            <h3>{p.creditsInfo.title}</h3>
            <p>{p.creditsInfo.body}</p>
          </div>
          <dl className="lp-credits__rules">
            {p.creditsInfo.rules.map(([label, value], i) => (
              <div key={label}>
                <dt>{label}</dt>
                <dd className={i === 2 || i === 3 ? 'is-free' : undefined}>{value}</dd>
              </div>
            ))}
          </dl>
        </div>
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

/** Kết (§10): the download target. Store badges replace the drawn "Dùng thử Lumi" pill so the
 *  nav's "Tải app" lands on something that installs the app. */
export function LumiCta() {
  const { c } = useSite();
  const k = c.lumiPage.cta;
  return (
    <section id="tai-app" className="lp-section container" aria-labelledby="cta-title">
      <div className="lp-cta reveal">
        <div className="lp-cta__copy">
          <LumiMascot size={56} />
          <h2 id="cta-title" className="lp-cta__title">
            {k.title}
          </h2>
          <div className="lp-cta__actions">
            <StoreBadges variant="light" />
            <a className="lp-cta__plans" href="#goi">
              {k.plans}
            </a>
          </div>
        </div>
        <span className="lp-cta__photo">
          <img src={scenes.nowBaby} alt="" loading="lazy" decoding="async" />
        </span>
      </div>
    </section>
  );
}
