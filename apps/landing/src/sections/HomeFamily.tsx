import { IconBox, type Tint } from '../components/kit';
import { Avatars, type Person } from '../components/rows';
import { Eyebrow, Fit, Icon, Photo, at, type IconName } from '../components/primitives';
import { useSite } from '../context';
import { HomeFace, Watch } from './Watch';

const bulletIcons: IconName[] = ['journal', 'clock', 'eye'];
// Family illustration (37 §6.1): member avatar, role icon and desktop position.
const members: { person: Person; icon: IconName; x: number; y: number }[] = [
  { person: 'dad', icon: 'check', x: 16, y: 40 },
  { person: 'mom', icon: 'star', x: 463, y: 40 },
  { person: 'grandpa', icon: 'eye', x: 16, y: 150 },
  { person: 'nanny', icon: 'feed', x: 471, y: 150 },
];
const handoverLooks: { icon: IconName; tint: Tint }[] = [
  { icon: 'feed', tint: 'bottle' },
  { icon: 'sleep', tint: 'sleep' },
  { icon: 'clock', tint: 'sun' },
];
const platformIcons: IconName[] = ['check', 'clock', 'check', 'check', 'check'];
const controlIcons: IconName[] = ['feed', 'sleep', 'diaper'];

function PhotoCard() {
  const { c } = useSite();
  return (
    <span className="fam-photo">
      <Photo tone="sun" />
      <span className="fam-photo__lock">
        <Icon name="lock" size={12} />
        {c.homePage.family.lock}
      </span>
    </span>
  );
}

function MemberPill({ index }: { index: number }) {
  const { c } = useSite();
  const m = c.homePage.family.members[index]!;
  const look = members[index]!;
  return (
    <span className="fam-member">
      <Avatars people={[look.person]} size={34} />
      <span className="fam-member__text">
        <strong>{m.name}</strong>
        <span>
          <Icon name={look.icon} size={10} />
          {m.role}
        </span>
      </span>
    </span>
  );
}

function Handover() {
  const { c } = useSite();
  const h = c.homePage.family.handover;
  return (
    <span className="fam-handover">
      <span className="fam-handover__head">
        <IconBox tint="sun" icon="link" size={14} />
        <strong>{h.title}</strong>
        <span>{h.time}</span>
      </span>
      <span className="fam-handover__items">
        {h.items.map((item, i) => (
          <span key={item.title} className="fam-handover__item">
            <IconBox tint={handoverLooks[i]!.tint} icon={handoverLooks[i]!.icon} size={12} />
            <span>
              <strong>{item.title}</strong>
              <span>{item.sub}</span>
            </span>
          </span>
        ))}
      </span>
      <span className="fam-handover__note">
        <Icon name="journal" size={12} />
        {h.note}
      </span>
      <span className="fam-handover__done">
        <Avatars people={['nanny']} size={20} />
        {h.done}
        <Icon name="check" size={12} />
      </span>
    </span>
  );
}
// Round watch tiles (§5.2, raw colours as drawn): the first four W01 tiles.
const roundTiles = ['#3D78D9', '#D95C85', '#6661D9', '#33996B'];

/** A round Wear OS watch (Figma 742:66966), 210 × 262.5, decorative. */
function RoundWatch() {
  const { c } = useSite();
  const tiles = c.home.watch.mock.tiles;
  return (
    <span className="round-watch">
      <span className="round-watch__strap" />
      <span className="round-watch__strap round-watch__strap--bottom" />
      <span className="round-watch__button" />
      <span className="round-watch__bezel">
        <span className="round-watch__screen">
          <span className="round-watch__time">{c.home.watch.mock.time}</span>
          <span className="round-watch__baby">{c.home.watch.mock.baby}</span>
          <span className="round-watch__tiles">
            {roundTiles.map((colour, i) => (
              <span key={colour} style={{ background: colour }}>
                <span>{i === 2 ? c.homePage.wrist.round.asleep : tiles[i]!.label}</span>
                <strong>{tiles[i]!.value}</strong>
              </span>
            ))}
          </span>
        </span>
      </span>
    </span>
  );
}

/** Cả nhà cùng chăm (V9, Figma 785:7290 / 785:8118; 37 §6): who is in the family and what each
 *  can do, a shift handover, then "Trên cổ tay" with the watch, widget, iOS Controls and Siri.
 *  Q-039 / Q-047 / Q-048: the watch app is unreleased, Wear OS is not in V1, Siri and iOS Controls
 *  have no D/R entry, comments and parent roles are not built — shipped on dev for review. */
export function HomeFamily() {
  const { c } = useSite();
  const f = c.homePage.family;
  const w = c.homePage.wrist;
  return (
    <section
      id="cham-soc"
      className="home-section home-section--white"
      aria-labelledby="family-title"
    >
      <div className="container home-section__inner">
        <div className="family">
          <div className="family__copy reveal">
            <Eyebrow tone="mint">{f.eyebrow}</Eyebrow>
            <h2 id="family-title" className="home-head__title family__title">
              {f.title}
            </h2>
            <ul className="family__bullets">
              {f.bullets.map((bullet, i) => (
                <li key={bullet}>
                  <span className="lp-icon tint--mint">
                    <Icon name={bulletIcons[i]!} size={16} />
                  </span>
                  {bullet}
                </li>
              ))}
            </ul>
            <p className="family__trust">
              <Icon name="lock" size={16} />
              {f.trust}
            </p>
          </div>
          {/* Gia đình · minh hoạ (787:8881): absolute on desktop, a flow layout on mobile (792:8915). */}
          <div className="fam-illus reveal" aria-hidden="true">
            <div className="only-desktop">
              <Fit w={640} h={454} mobileScale={0.55}>
                <span className="fam-illus__panel" />
                <span style={at(195, 28, { width: 250 })}>
                  <PhotoCard />
                </span>
                {members.map((m, i) => (
                  <span key={m.person} style={at(m.x, m.y)}>
                    <MemberPill index={i} />
                  </span>
                ))}
                <span style={at(32, 258, { width: 576 })}>
                  <Handover />
                </span>
              </Fit>
            </div>
            <div className="fam-flow only-mobile">
              <PhotoCard />
              <span className="fam-flow__members">
                {members.map((m, i) => (
                  <MemberPill key={m.person} index={i} />
                ))}
              </span>
              <Handover />
            </div>
          </div>
        </div>
        <div id="apple-watch" className="wrist reveal">
          <div className="wrist__copy">
            <span className="wrist__chip">{w.chip}</span>
            <h3 className="wrist__title">{w.title}</h3>
            <p className="wrist__lead">
              <span className="only-desktop-inline">{w.lead}</span>
              <span className="only-mobile-inline">{w.leadShort}</span>
            </p>
            <ul className="wrist__platforms">
              {w.platforms.map((platform, i) => (
                <li key={platform} className={i === 1 ? undefined : 'is-ready'}>
                  <Icon name={platformIcons[i]!} size={12} />
                  {platform}
                </li>
              ))}
            </ul>
            <div className="quicklog" aria-hidden="true">
              <span className="quicklog__tile">
                <span className="quicklog__label">{w.widget.label}</span>
                <span className="quicklog__widget">
                  <span>{w.widget.baby}</span>
                  <strong>{w.widget.value}</strong>
                  <span className="quicklog__icons">
                    <IconBox tint="bottle" icon="feed" size={12} />
                    <IconBox tint="sleep" icon="sleep" size={12} />
                    <IconBox tint="diaper" icon="diaper" size={12} />
                  </span>
                </span>
              </span>
              <span className="quicklog__tile">
                <span className="quicklog__label">{w.controls.label}</span>
                <span className="quicklog__controls">
                  {w.controls.items.map((item, i) => (
                    <span key={item}>
                      <b>
                        <Icon name={controlIcons[i]!} size={18} />
                      </b>
                      {item}
                    </span>
                  ))}
                </span>
              </span>
            </div>
            <div className="siri" aria-hidden="true">
              <span className="siri__head">
                <span className="siri__orb" />
                {w.siri.head}
              </span>
              {w.siri.lines.map((line) => (
                <span key={line.say} className="siri__line">
                  <strong>{line.say}</strong>
                  <span>
                    <Icon name="check" size={11} />
                    {line.reply}
                  </span>
                </span>
              ))}
            </div>
          </div>
          <div className="wrist__visual" aria-hidden="true">
            <Fit w={560} h={340} mobileScale={0.5536}>
              <span className="watch-band__glow wrist__glow" style={at(93, 17)} />
              <Watch scale={1.17} style={at(44.8, 8.5)}>
                <HomeFace />
              </Watch>
              <span style={at(316.4, 48.75)}>
                <RoundWatch />
              </span>
              <span className="wrist__label" style={at(142.9, 318)}>
                {w.apple}
              </span>
              <span className="wrist__label" style={at(391.4, 318)}>
                {w.wearLabel}
              </span>
            </Fit>
          </div>
        </div>
      </div>
    </section>
  );
}
