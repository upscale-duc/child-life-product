import { IconBox, type Tint } from '../components/kit';
import { Eyebrow, Icon, type IconName } from '../components/primitives';
import { useSite } from '../context';
import { staggerStyle } from '../motion';
import { pathOf, stageIds } from '../routes';
import { stageLooks } from './Chapters';
import { BentoGrid } from './Everything';

const roles: [IconName, Tint][] = [
  ['family', 'mint'],
  ['heart', 'diaper'],
  ['memories', 'peach'],
];
const trust: IconName[] = ['lock', 'heart', 'star', 'check', 'cloud-off'];

/** Năm đầu đời (14-landing-v3-home §4): bento, family strip, trust chips, next stages. */
export function FirstYear() {
  const { c, route } = useSite();
  const f = c.home.firstYear;
  const j = c.journey;
  return (
    <section
      id="nam-dau-doi"
      className="section first-year container"
      aria-labelledby="first-year-title"
    >
      <header className="section-head section-head--center reveal">
        <Eyebrow tone="mint">{f.eyebrow}</Eyebrow>
        <h2 id="first-year-title" className="h2 h2--flat first-year__title">
          {f.title}
        </h2>
        <p className="lead">
          <span className="only-desktop-inline">{f.lead}</span>
          <span className="only-mobile-inline">{f.leadShort}</span>
        </p>
      </header>
      <BentoGrid />

      <div id="gia-dinh" className="first-year__family">
        <h3 className="first-year__subtitle reveal">
          <Icon name="family" size={20} className="ink--mint hide-mobile" />
          <span className="only-desktop-inline">{f.familyTitle}</span>
          <span className="only-mobile-inline">{f.familyTitleShort}</span>
        </h3>
        <ul className="role-strip">
          {f.roles.map((role, i) => (
            <li key={role.role} className="role-strip__card reveal" style={staggerStyle(i)}>
              <IconBox tint={roles[i]![1]} icon={roles[i]![0]} size={22} />
              <span className="role-strip__text">
                <span className="role-strip__role">{role.role}</span>
                <strong>{role.title}</strong>
                <span className="role-strip__body only-desktop-inline">{role.body}</span>
              </span>
            </li>
          ))}
        </ul>
        <ul className="trust-chips reveal">
          {f.trust.map((chip, i) => (
            <li key={chip.text} className={i === 4 ? 'hide-mobile' : undefined}>
              <Icon name={trust[i]!} size={14} />
              <span className="only-desktop-inline">{chip.text}</span>
              <span className="only-mobile-inline">{chip.short}</span>
            </li>
          ))}
        </ul>
      </div>

      <div className="first-year__next">
        <h3 className="first-year__subtitle reveal">{f.nextTitle}</h3>
        <ul className="next-stages">
          {j.stages.slice(1).map((stage, k) => {
            const i = k + 1;
            const look = stageLooks[i]!;
            return (
              <li key={stage.name} className="reveal" style={staggerStyle(k)}>
                <a
                  className={`next-stage tint--${look.tint}`}
                  href={pathOf(stageIds[i]!, route.locale)}
                >
                  <span className="next-stage__disc">
                    <Icon name={look.icon} size={20} />
                  </span>
                  <span className="next-stage__text">
                    <span className="next-stage__label">
                      {j.number.replace('{n}', String(i + 1))} · {stage.ages}
                    </span>
                    <strong>{stage.name}</strong>
                    <span className="next-stage__sub">{f.preparing}</span>
                  </span>
                </a>
              </li>
            );
          })}
        </ul>
      </div>

      <a
        className="btn btn--outline first-year__more pressable reveal"
        href={pathOf('stage1', route.locale)}
      >
        {f.more}
        <Icon name="arrow-right" size={16} />
      </a>
    </section>
  );
}
