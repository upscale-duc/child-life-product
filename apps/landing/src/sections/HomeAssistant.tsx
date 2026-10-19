import { LumiMascot } from '../components/kit';
import { Icon, type IconName } from '../components/primitives';
import { useSite } from '../context';
import { pathOf } from '../routes';
import { TodayMock } from './ForBaby';
import { LumiChatCard } from './LumiDetail';

function Float({
  icon,
  tint,
  children,
  className,
}: {
  icon: IconName;
  tint: string;
  children: string;
  className: string;
}) {
  return (
    <span className={`assist-float ${className}`}>
      <span className={`assist-float__icon tint--${tint}`}>
        <Icon name={icon} size={12} />
      </span>
      {children}
    </span>
  );
}

/** Lumi & gợi ý cho bé (Figma 735:6128 / 736:66185; 34-landing-v8-home §6): two examples of
 *  Lumi and one of the personal "Hôm nay của bé" — each a mock-up cut off at the panel's edge, as
 *  drawn. */
export function HomeAssistant() {
  const { c, route } = useSite();
  const a = c.homePage.assistant;
  return (
    <section
      id="lumi"
      className="home-section home-section--lumi"
      aria-labelledby="assistant-title"
    >
      <div className="container home-section__inner">
        <header className="home-head reveal">
          <span className="lumi-eyebrow">
            <LumiMascot size={52} />
            <span className="eyebrow eyebrow--sleep">{a.eyebrow}</span>
          </span>
          <h2 id="assistant-title" className="home-head__title">
            {a.title}
          </h2>
          <p className="home-head__lead">{a.lead}</p>
        </header>
        <div className="assist">
          <div className="assist__panel assist__panel--chat reveal">
            <span className="assist__head">
              <LumiMascot size={44} />
              <span>
                <strong>{a.chat.title}</strong>
                <span>{a.chat.body}</span>
              </span>
            </span>
            <span className="assist__stage" aria-hidden="true">
              <LumiChatCard />
              <Float icon="check" tint="mint" className="assist-float--a">
                {a.floats[0]}
              </Float>
              <Float icon="check" tint="sleep" className="assist-float--b">
                {a.floats[1]}
              </Float>
            </span>
          </div>
          <div className="assist__panel assist__panel--today reveal">
            <span className="assist__head">
              <span className="lp-icon tint--white">
                <Icon name="today" size={22} />
              </span>
              <span>
                <strong>{a.today.title}</strong>
                <span>{a.today.body}</span>
              </span>
            </span>
            <span className="assist__stage" aria-hidden="true">
              <TodayMock />
              <Float icon="eye" tint="peach" className="assist-float--a">
                {a.floats[2]}
              </Float>
              <Float icon="sliders" tint="sun" className="assist-float--b">
                {a.floats[3]}
              </Float>
            </span>
          </div>
        </div>
        <div className="assist__cta reveal">
          <a className="home-button pressable" href={pathOf('lumi', route.locale)}>
            {a.cta}
            <Icon name="arrow-right" size={16} />
          </a>
          <p>{a.note}</p>
        </div>
      </div>
    </section>
  );
}
