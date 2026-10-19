import { Care } from '../sections/Care';
import { Closing } from '../sections/Closing';
import { Cocare } from '../sections/Cocare';
import { Faq } from '../sections/Faq';
import { FirstAid } from '../sections/FirstAid';
import { FirstYearHero, Group, JumpNav, Vaccines } from '../sections/FirstYearPage';
import { Library } from '../sections/Library';
import { Memories } from '../sections/Memories';
import { Night } from '../sections/Night';
import { Quick } from '../sections/Quick';
import { Reminders } from '../sections/Reminders';
import { Roles } from '../sections/Roles';
import { Understand } from '../sections/Understand';
import { WatchSection } from '../sections/Watch';
import { YourWay } from '../sections/YourWay';

/** "Năm đầu đời" (V8, Figma 737:6362; 35-landing-v8-first-year), at the Chặng 1 path: the hero,
 *  quick links, five groups of feature sections, the FAQ and Kết. */
export function FirstYear() {
  return (
    <div className="fy-page">
      <FirstYearHero />
      <JumpNav />
      <Group index={0}>
        <Quick />
        <Care />
        <Reminders />
      </Group>
      <Group index={1}>
        <Cocare />
        <Roles />
      </Group>
      <Group index={2}>
        <Understand />
        <Vaccines />
        <Library />
        <FirstAid />
      </Group>
      <Group index={3}>
        <Memories />
      </Group>
      <Group index={4}>
        <Night />
        <div className="fy-card container">
          <YourWay />
        </div>
        <div className="fy-card container">
          <WatchSection />
        </div>
      </Group>
      <Faq />
      <Closing />
    </div>
  );
}
