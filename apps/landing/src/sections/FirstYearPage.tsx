import type { ReactNode } from 'react';
import art1 from '../assets/figma/journey-art-stage1.svg';
import { CompactBullets } from '../components/Bullets';
import { AppCta } from '../components/StoreBadges';
import { Eyebrow, Fit, Icon, at, type IconName } from '../components/primitives';
import { useSite } from '../context';

/* V8 "Năm đầu đời" page (Figma 737:6362; 35-landing-v8-first-year). */

/** Hero (§2): status chips, title, the download component, and the stage-1 art at 2×. */
export function FirstYearHero() {
  const { c } = useSite();
  const h = c.firstYearPage.hero;
  const j = c.journey;
  return (
    <section id="gioi-thieu" className="fy-hero" aria-labelledby="fy-title">
      <div className="fy-hero__inner container">
        <div className="fy-hero__copy">
          <span className="fy-hero__chips enter">
            <span className="fy-chip fy-chip--now">
              <Icon name="check" size={12} />
              {h.badge}
            </span>
            <span className="fy-chip">
              {j.number.replace('{n}', '1')} · {j.stages[0].ages}
            </span>
          </span>
          <h1 id="fy-title" className="fy-hero__title">
            {h.title}
          </h1>
          <p className="fy-hero__lead">{h.lead}</p>
          <div className="enter" style={{ ['--i' as string]: 1 }}>
            <AppCta />
          </div>
        </div>
        <span className="fy-hero__art enter" style={{ ['--i' as string]: 1 }} aria-hidden="true">
          <span className="chapter__circle chapter__circle--a" />
          <span className="chapter__circle chapter__circle--b" />
          <img src={art1} alt="" width={590} height={340} />
        </span>
      </div>
    </section>
  );
}

export const groupIds = [
  'ghi-va-nhac',
  'ca-nha-cung-cham',
  'hieu-con-theo-tuoi',
  'ky-niem',
  'tien-ich',
];
const groupIcons: IconName[] = ['feed', 'family', 'star', 'heart', 'sliders'];

/** "Đi nhanh tới:" (§3): one chip per group; the chip of the group in view is highlighted by the
 *  nav's scroll-spy (`data-spy`). */
export function JumpNav() {
  const { c } = useSite();
  const p = c.firstYearPage;
  return (
    <nav className="jump" aria-label={p.jump.navLabel}>
      <div className="jump__inner container">
        <span className="jump__label">{p.jump.label}</span>
        <ul>
          {p.groups.map((group, i) => (
            <li key={group.title}>
              <a href={`#${groupIds[i]}`} data-spy={groupIds[i]}>
                <Icon name={groupIcons[i]!} size={14} />
                {group.title}
              </a>
            </li>
          ))}
        </ul>
      </div>
    </nav>
  );
}

/** A group ("Nhóm · …", §4): number pill, title, subtitle and a rule, then its sections. */
export function Group({ index, children }: { index: number; children: ReactNode }) {
  const { c } = useSite();
  const group = c.firstYearPage.groups[index]!;
  return (
    <section id={groupIds[index]} className="fy-group" aria-labelledby={`${groupIds[index]}-title`}>
      <div className="fy-group__head container reveal">
        <span className="fy-group__n" aria-hidden="true">
          {String(index + 1).padStart(2, '0')}
        </span>
        <span className="fy-group__t">
          <h2 id={`${groupIds[index]}-title`}>{group.title}</h2>
          <span>{group.sub}</span>
        </span>
        <span className="fy-group__rule" aria-hidden="true" />
      </div>
      {children}
    </section>
  );
}

// Vaccine table (§11.1): d = done, n = next / due, '' = no dose. Rows as drawn.
const doses = [
  ['d', '', '', '', '', ''],
  ['d', '', '', '', '', ''],
  ['', 'd', 'd', 'n', '', ''],
  ['', 'd', 'd', '', '', ''],
  ['', 'd', 'd', '', '', ''],
  ['', '', '', '', '', 'n'],
];

/** Lịch tiêm & tăng trưởng (§11, new): the vaccine schedule and growth card left, copy right.
 *  P-133 / D-084 vaccine book, D-049 WHO growth; D-083 nutrition content awaits review. */
export function Vaccines() {
  const { c } = useSite();
  const v = c.firstYearPage.vaccines;
  const m = v.mock;
  return (
    <section
      id="tiem-chung"
      className="section feature container split split--visual-first"
      aria-labelledby="vaccines-title"
    >
      <div className="split__copy">
        <header className="section-head reveal">
          <Eyebrow tone="mint">{v.eyebrow}</Eyebrow>
          <h2 id="vaccines-title" className="h2 feature__title">
            {v.title}
          </h2>
          <p className="lead split__lead">{v.lead}</p>
        </header>
        <CompactBullets
          items={[
            { icon: 'check', tint: 'mint', ...v.bullets[0], subShort: v.bullets[0].sub },
            { icon: 'ruler', tint: 'growth', ...v.bullets[1], subShort: v.bullets[1].sub },
            { icon: 'feed', tint: 'bottle', ...v.bullets[2], subShort: v.bullets[2].sub },
          ]}
        />
        <p className="vax-note reveal">{v.note}</p>
      </div>
      <div className="split__visual vax-visual reveal" aria-hidden="true">
        <Fit w={600} h={520} mobileScale={0.558}>
          <div className="panel tint--mint" />
          <div className="vax-card" style={at(40, 40)}>
            <strong className="vax-card__title">{m.title}</strong>
            <span className="vax-table">
              <span />
              {m.columns.map((col) => (
                <span key={col} className="vax-table__col">
                  {col}
                </span>
              ))}
              {m.rows.map((row, r) => (
                <span key={row} className="vax-table__row">
                  <span className="vax-table__label">{row}</span>
                  {doses[r]!.map((dose, k) => (
                    <span key={k} className="vax-table__cell">
                      {dose === 'd' ? (
                        <span className="vax-dot vax-dot--done">
                          <Icon name="check" size={12} />
                        </span>
                      ) : dose === 'n' ? (
                        <span className="vax-dot vax-dot--due" />
                      ) : (
                        <span className="vax-dot" />
                      )}
                    </span>
                  ))}
                </span>
              ))}
            </span>
            <span className="vax-next">
              <Icon name="clock" size={16} />
              {m.next}
            </span>
          </div>
          <div className="vax-growth" style={at(330, 370)}>
            <span>{m.growth.label}</span>
            <strong>{m.growth.value}</strong>
            <span className="vax-growth__chip">{m.growth.chip}</span>
          </div>
        </Fit>
      </div>
    </section>
  );
}
