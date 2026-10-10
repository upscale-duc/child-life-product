import { CompactBullets } from '../components/Bullets';
import { Chip, IconBox, Initials, Push, Toggle } from '../components/kit';
import { Eyebrow, Fit, at } from '../components/primitives';
import { useSite } from '../context';

/** Nhắc nhở (12-landing-v3 §2): copy left, absolute panel right on desktop; on mobile the
 *  panel is re-composed in flow between the head and the bullets. Mock UI is decorative. */
export function Reminders() {
  const { c } = useSite();
  const r = c.reminders;
  const n = r.notification;
  return (
    <section
      id="nhac-nho"
      className="section feature container split"
      aria-labelledby="reminders-title"
    >
      <div className="split__copy">
        <header className="section-head reveal">
          <Eyebrow tone="sun-ink">{r.eyebrow}</Eyebrow>
          <h2 id="reminders-title" className="h2 feature__title">
            {r.title}
          </h2>
          <p className="lead split__lead">
            <span className="only-desktop-inline">{r.lead}</span>
            <span className="only-mobile-inline">{r.leadShort}</span>
          </p>
        </header>
        <div className="flow-panel tint--sun only-mobile reveal" aria-hidden="true">
          <Push
            size="md"
            title={n.title}
            sub={n.subShort}
            actions={[n.log, n.snoozeShort, n.skip]}
          />
          <div className="rule-card rule-card--sm">
            <div className="rule-card__row">
              <IconBox tint="bottle" icon="feed" size={18} />
              <span className="rule-card__text">
                <strong>{r.rule.title}</strong>
                <span>{r.rule.sub}</span>
              </span>
              <Toggle scale={0.8} />
            </div>
          </div>
          <Chip icon="check" ink="mint">
            {r.doneShort}
          </Chip>
        </div>
        <CompactBullets
          items={[
            { icon: 'clock', tint: 'sun', ...r.bullets[0] },
            { icon: 'family', tint: 'peach', ...r.bullets[1] },
            { icon: 'check', tint: 'mint', ...r.bullets[2] },
          ]}
        />
      </div>
      <div className="split__visual only-desktop reveal">
        <Fit w={640} h={600} mobileScale={0.5234}>
          <div className="panel tint--sun" />
          <div className="pop" style={at(56, 88, { width: 400 })}>
            <Push size="lg" title={n.title} sub={n.sub} actions={[n.log, n.snooze, n.skip]} />
          </div>
          <div className="rule-card pop" style={at(204, 262, { width: 380, ['--i' as string]: 1 })}>
            <div className="rule-card__row">
              <IconBox tint="bottle" icon="feed" size={18} />
              <span className="rule-card__text">
                <strong>{r.rule.title}</strong>
                <span>{r.rule.sub}</span>
              </span>
              <Toggle scale={0.85} />
            </div>
            <div className="rule-card__row rule-card__row--tight">
              <Chip tint="mint" icon="clock">
                {r.rule.next}
              </Chip>
              <span className="spacer" />
              <Initials letters={c.hero.proofInitials.slice(0, 3)} inline />
            </div>
          </div>
          <div className="fixed-card pop" style={at(56, 410, { width: 250, ['--i' as string]: 2 })}>
            <span className="fixed-card__head">
              <IconBox tint="sleep" icon="sleep" size={18} />
              <strong>{r.fixed.title}</strong>
            </span>
            <span className="chip-row">
              {r.fixed.times.map((time) => (
                <Chip key={time} tint="plain" size="sm">
                  {time}
                </Chip>
              ))}
            </span>
          </div>
          <Chip
            icon="check"
            ink="mint"
            float
            className="chip--lg pop"
            style={at(300, 500, { ['--i' as string]: 3 })}
          >
            {r.done}
          </Chip>
        </Fit>
      </div>
    </section>
  );
}
