import { useSite } from '../context';
import { Chapters } from '../sections/Chapters';
import { Cta } from '../sections/Cta';
import { Faq } from '../sections/Faq';
import { FirstYear } from '../sections/FirstYear';
import { GrowUp } from '../sections/GrowUp';
import { Health } from '../sections/Health';
import { JourneyHero } from '../sections/JourneyHero';
import { Utilities } from '../sections/Utilities';
import { WatchSection } from '../sections/Watch';
import { YourWay } from '../sections/YourWay';

/** Home page, section order per Figma v5 475:3726 (v3 mobile 362:3398 for the shared sections). */
export function Home() {
  const { c } = useSite();
  return (
    <>
      <JourneyHero />
      <Chapters />
      <FirstYear />
      <Health />
      <Utilities />
      <WatchSection />
      <YourWay />
      <GrowUp />
      <Cta title={c.journey.ctaTitle} compact />
      <Faq items={c.home.faq.items} />
    </>
  );
}
