import { LockScreen, WidgetLarge, WidgetMedium, WidgetSmall } from '../components/mock';
import { Eyebrow, Fit, Icon, at } from '../components/primitives';
import { useSite } from '../context';
import { staggerStyle } from '../motion';

/** Thao tác nhanh / "Khi bận tay" (spec §3): widgets and lock screen. */
export function Quick() {
  const { c } = useSite();
  const q = c.quick;
  return (
    <section id="cham-con" className="section quick container" aria-labelledby="quick-title">
      <header className="section-head section-head--center reveal">
        <Eyebrow tone="mint">{q.eyebrow}</Eyebrow>
        <h2 id="quick-title" className="h2">
          {q.title}
        </h2>
        <p className="lead">{q.lead}</p>
      </header>

      <div className="quick__stage reveal">
        <Fit w={1248} h={600} mobileScale={1} className="only-desktop">
          <div className="stage-bg stage-bg--desktop" />
          <span className="stage-label" style={at(56, 48)}>
            {q.labels[0]}
          </span>
          <WidgetLarge style={at(56, 100, { width: 364, height: 382 })} />
          <WidgetMedium style={at(452, 100, { width: 364, height: 170 })} />
          <WidgetSmall variant="bottle" style={at(452, 294)} />
          <WidgetSmall variant="logged" style={at(646, 294)} />
          <span className="tap" style={at(570, 410)}>
            <span className="tap__ring" />
            <span className="tap__dot" />
          </span>
          <span className="arrow-chip" style={at(608, 364)}>
            →
          </span>
          <span className="note-chip" style={at(452, 484)}>
            <Icon name="check" size={16} />
            {q.note}
          </span>
          <span className="stage-label" style={at(876, 48)}>
            {q.labels[1]}
          </span>
          <LockScreen style={at(876, 100)} />
        </Fit>
        <Fit w={335} h={697.7} mobileScale={1} className="only-mobile">
          <div className="stage-bg stage-bg--mobile" />
          <div style={at(16, 20, { transform: 'scale(0.8324)', transformOrigin: '0 0' })}>
            <WidgetMedium style={{ width: 364, height: 170 }} />
          </div>
          <div style={at(16, 175.5, { transform: 'scale(0.847)', transformOrigin: '0 0' })}>
            <WidgetSmall variant="bottle" />
          </div>
          <div style={at(175, 175.5, { transform: 'scale(0.847)', transformOrigin: '0 0' })}>
            <WidgetSmall variant="logged" />
          </div>
          <span className="tap tap--small" style={at(114, 273.5)}>
            <span className="tap__ring" />
          </span>
          <div style={at(47.5, 339.5, { transform: 'scale(0.76)', transformOrigin: '0 0' })}>
            <LockScreen />
          </div>
        </Fit>
      </div>

      <ol className="steps reveal-group">
        {q.steps.map((step, i) => (
          <li key={step.title} className="step reveal" style={staggerStyle(i)}>
            <span className="step__number" aria-hidden="true">
              {i + 1}
            </span>
            <span className="step__text">
              <strong>{step.title}</strong>
              <span>{step.sub}</span>
            </span>
          </li>
        ))}
      </ol>
    </section>
  );
}
