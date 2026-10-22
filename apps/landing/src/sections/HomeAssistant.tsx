import { IconBox, LumiMascot, Toggle, type Tint } from '../components/kit';
import { Eyebrow, Icon, type IconName } from '../components/primitives';
import { useSite } from '../context';
import { staggerStyle } from '../motion';
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
        <AskLumi />
        <div className="assist__cta reveal">
          <a className="home-button pressable" href={pathOf('lumi', route.locale)}>
            {a.cta}
            <Icon name="arrow-right" size={16} />
          </a>
        </div>
      </div>
    </section>
  );
}

const foodTints: Tint[] = ['sun', 'bottle', 'sun', 'diaper'];
const activityLooks: { icon: IconName; tint: Tint }[] = [
  { icon: 'heart', tint: 'bottle' },
  { icon: 'journal', tint: 'sun' },
];
const bars = [42, 48, 30, 54, 60, 36, 48];

/** One answer of "Thử hỏi Lumi" (37 §7.1), shown as pictures and tags rather than text. */
function Answer({ index }: { index: number }) {
  const { c } = useSite();
  const a = c.homePage.assistant.ask;
  switch (index) {
    case 0:
      return (
        <>
          <span className="ask-foods">
            {a.foods.map((food, i) => (
              <span key={food} className={`tint--${foodTints[i]}`}>
                {food}
              </span>
            ))}
          </span>
          <span className="ask-note">{a.foodsNote}</span>
        </>
      );
    case 1:
      return (
        <>
          {a.activities.map((item, i) => (
            <span key={item.title} className="ask-activity">
              <IconBox tint={activityLooks[i]!.tint} icon={activityLooks[i]!.icon} size={12} />
              <strong>{item.title}</strong>
              <span>{item.time}</span>
            </span>
          ))}
        </>
      );
    case 2:
      return (
        <>
          <span className="ask-chart">
            {a.days.map((day, i) => (
              <span key={day}>
                <i className={i === 6 ? 'is-today' : undefined} style={{ height: bars[i] }} />
                {day}
              </span>
            ))}
          </span>
          <span className="ask-week">
            <span className="tint--sleep">{a.week[0]}</span>
            <span className="tint--bottle">{a.week[1]}</span>
          </span>
        </>
      );
    default:
      return (
        <>
          <strong className="ask-last">{a.last.value}</strong>
          <span className="ask-note">{a.last.meta}</span>
          <span className="ask-next">
            <Icon name="clock" size={12} />
            {a.last.next}
          </span>
        </>
      );
  }
}

/** "Thử hỏi Lumi" (Figma 788:8801): four questions, each answered with a small picture. */
function AskLumi() {
  const { c } = useSite();
  const a = c.homePage.assistant.ask;
  return (
    <div className="ask">
      <p className="ask__head">
        <IconBox tint="sleep" icon="spark" size={14} />
        <strong>{a.title}</strong>
        <span className="only-desktop-inline">{a.sub}</span>
      </p>
      <ul className="ask__cards">
        {a.questions.map((question, i) => (
          <li key={question} className="ask-card reveal" style={staggerStyle(i)}>
            <span className="ask-card__q">{question}</span>
            <span className="ask-card__a" aria-hidden="true">
              <span className="ask-card__lumi">
                <IconBox tint="mint" icon="spark" size={10} />
                Lumi
              </span>
              <Answer index={i} />
            </span>
          </li>
        ))}
      </ul>
    </div>
  );
}

const moduleLooks: { icon: IconName; tint: Tint }[] = [
  { icon: 'today', tint: 'bottle' },
  { icon: 'star', tint: 'sleep' },
  { icon: 'drop', tint: 'sun' },
  { icon: 'memories', tint: 'mint' },
];
const noticeLooks: { icon: IconName; chip: number; tint: Tint }[] = [
  { icon: 'camera', chip: 3, tint: 'mint' },
  { icon: 'cake', chip: 3, tint: 'mint' },
  { icon: 'star', chip: 1, tint: 'sleep' },
  { icon: 'drop', chip: 2, tint: 'sun' },
];

/** 5b · Không bỏ lỡ những khoảnh khắc quan trọng (V9, Figma 789:8811 / 793:8899; 37 §8):
 *  notification topics (the toggles are a picture, not settings) and a lock screen. Q-039: the
 *  app's notification settings are grouped differently; occasion nudges cannot be turned off
 *  (D-068 #9); reminders fire on the creating device (R-091). */
export function HomeAlerts() {
  const { c } = useSite();
  const a = c.homePage.alerts;
  return (
    <section
      id="nhac-nho"
      className="home-section home-section--white"
      aria-labelledby="alerts-title"
    >
      <div className="container home-section__inner">
        <div className="alerts">
          <div className="alerts__copy">
            <header className="home-head reveal">
              <Eyebrow tone="mint">{a.eyebrow}</Eyebrow>
              <h2 id="alerts-title" className="home-head__title">
                {a.title}
              </h2>
              <p className="home-head__lead">
                <span className="only-desktop-inline">{a.lead}</span>
                <span className="only-mobile-inline">{a.leadShort}</span>
              </p>
            </header>
            <ul className="alerts__modules reveal">
              {a.modules.map((module, i) => (
                <li key={module.title}>
                  <IconBox tint={moduleLooks[i]!.tint} icon={moduleLooks[i]!.icon} size={14} />
                  <span className="alerts__text">
                    <strong>{module.title}</strong>
                    <span>{module.body}</span>
                  </span>
                  <span className="alerts__toggle" aria-hidden="true">
                    <Toggle scale={0.78} />
                  </span>
                </li>
              ))}
            </ul>
            <p className="alerts__note reveal">{a.note}</p>
          </div>
          <div className="lock reveal" aria-hidden="true">
            <span className="lock__date">{a.date}</span>
            <strong className="lock__time">{a.time}</strong>
            {a.notices.map((notice, i) => {
              const look = noticeLooks[i]!;
              return (
                <span key={notice.title} className="lock-notice">
                  <span className="lock-notice__app">
                    <Icon name={look.icon} size={16} />
                  </span>
                  <span className="lock-notice__text">
                    <span className="lock-notice__head">
                      <strong>{notice.title}</strong>
                      <span>{notice.when}</span>
                    </span>
                    <span className="lock-notice__body">
                      <span className="only-desktop-inline">{notice.body}</span>
                      <span className="only-mobile-inline">{notice.bodyShort}</span>
                    </span>
                    <span className={`lock-notice__chip tint--${look.tint}`}>
                      {a.modules[look.chip]!.title}
                    </span>
                  </span>
                </span>
              );
            })}
            <span className="lock__more">{a.more}</span>
          </div>
        </div>
      </div>
    </section>
  );
}
