import { Chip, IconBox, Initials, Push, type Tint } from '../components/kit';
import { Eyebrow, Fit, Photo, type IconName, type PhotoTone } from '../components/primitives';
import { useSite } from '../context';
import { staggerStyle } from '../motion';

const tiles: { tint: Tint; icon: IconName; iconTint?: Tint }[] = [
  { tint: 'mint', icon: 'plus' },
  { tint: 'sun', icon: 'clock' },
  { tint: 'peach', icon: 'family' },
  { tint: 'sleep', icon: 'spark' },
  { tint: 'growth', icon: 'star' },
  { tint: 'white', icon: 'bookmark', iconTint: 'mint' },
  { tint: 'bottle', icon: 'feed' },
  { tint: 'coral', icon: 'memories' },
];

// Photo fan of tile 8: tone, rotation, rotated bounding box (x, y, w, h).
const fan: [PhotoTone, number, number, number, number, number][] = [
  ['peach', 6, 11.5, 0, 107, 119.4],
  ['sun', -4, 77, 8.2, 103.4, 116.4],
  ['sky', 3, 156.2, 2.3, 101.6, 114.9],
];

/** Mọi thứ trong một app (12-landing-v3 §1): 4 × 2 bento with mock footers on desktop,
 *  text-only 2-column tiles on mobile. */
export function BentoGrid() {
  const { c } = useSite();
  const e = c.everything;
  const footers = [
    <div key="log" className="chip-col">
      <Chip icon="feed" ink="bottle">
        {e.logChips[0]}
      </Chip>
      <Chip icon="sleep" ink="sleep">
        {e.logChips[1]}
      </Chip>
    </div>,
    <Push key="push" size="sm" title={e.notification.title} sub={e.notification.sub} />,
    <div key="family" className="chip-col chip-col--gap">
      <Initials letters={c.hero.proofInitials} />
      <Chip icon="check" ink="mint">
        {e.familyChip}
      </Chip>
    </div>,
    <div key="week" className="chip-col">
      <Chip icon="cake" ink="ink">
        {e.weekChips[0]}
      </Chip>
      <Chip tint="accent">{e.weekChips[1]}</Chip>
    </div>,
    <div key="milestone" className="bento-milestone">
      <Photo tone="peach" className="bento-milestone__photo" />
      <span className="bento-milestone__text">
        <strong>{e.milestone.title}</strong>
        <span>{e.milestone.sub}</span>
      </span>
    </div>,
    <div key="topics" className="chip-row">
      <Chip tint="sleep">{e.topics[0]}</Chip>
      <Chip tint="sun">{e.topics[1]}</Chip>
      <Chip tint="bottle">{e.topics[2]}</Chip>
    </div>,
    <div key="foods" className="chip-row">
      {e.foods.map((food) => (
        <Chip key={food} icon="check" ink="mint">
          {food}
        </Chip>
      ))}
      <Chip ink="ink">{e.moreFoods}</Chip>
    </div>,
    <Fit key="fan" w={258} h={120} mobileScale={1} className="bento-fan">
      {fan.map(([tone, rotate, x, y, w, h]) => (
        <span
          key={tone}
          className="bento-fan__photo"
          style={{
            left: x + w / 2 - 48,
            top: y + h / 2 - 55,
            transform: `rotate(${rotate}deg)`,
          }}
        >
          <Photo tone={tone} />
        </span>
      ))}
    </Fit>,
  ];
  return (
    <ul className="bento__grid reveal-group">
      {e.tiles.map((tile, i) => {
        const look = tiles[i]!;
        return (
          <li
            key={tile.title}
            className={`bento-tile tint--${look.tint} reveal`}
            style={staggerStyle(i)}
          >
            <IconBox
              tint={look.iconTint ?? 'white'}
              icon={look.icon}
              size={20}
              className="bento-tile__icon"
            />
            <h3 className="bento-tile__title">{tile.title}</h3>
            <p className="bento-tile__body">
              <span className="only-desktop-inline">{tile.body}</span>
              <span className="only-mobile-inline">{tile.bodyShort}</span>
            </p>
            <div className="bento-tile__foot only-desktop" aria-hidden="true">
              {footers[i]}
            </div>
          </li>
        );
      })}
    </ul>
  );
}

/** The bento section of the Chặng 1 page (v2.1 `322:1809`); the home reuses only the grid. */
export function Everything() {
  const { c } = useSite();
  const e = c.everything;
  return (
    <section id="tat-ca" className="section bento container" aria-labelledby="bento-title">
      <header className="section-head section-head--center reveal">
        <Eyebrow tone="mint">{e.eyebrow}</Eyebrow>
        <h2 id="bento-title" className="h2">
          {e.title}
        </h2>
        <p className="lead">
          <span className="only-desktop-inline">{e.lead}</span>
          <span className="only-mobile-inline">{e.leadShort}</span>
        </p>
      </header>
      <BentoGrid />
    </section>
  );
}
