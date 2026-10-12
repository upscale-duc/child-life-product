import { useSite } from '../context';
import { Chapters } from '../sections/Chapters';
import { Cta } from '../sections/Cta';
import { Faq } from '../sections/Faq';
import { FirstYear } from '../sections/FirstYear';
import { GrowUp } from '../sections/GrowUp';
import { JourneyHero } from '../sections/JourneyHero';

/** v3 home page, section order per Figma 358:2901 / 362:3398. */
export function Home() {
  const { c } = useSite();
  return (
    <>
      <JourneyHero />
      <Chapters />
      <FirstYear />
      <GrowUp />
      <Cta title={c.journey.ctaTitle} compact />
      <Faq items={c.home.faq.items} />
    </>
  );
}
