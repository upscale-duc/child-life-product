import { useSite } from '../context';
import { Chapters } from '../sections/Chapters';
import { Cta } from '../sections/Cta';
import { Faq } from '../sections/Faq';
import { FirstYear } from '../sections/FirstYear';
import { GrowUp } from '../sections/GrowUp';
import { JourneyHero } from '../sections/JourneyHero';
import { NextStages } from '../sections/NextStages';

/** Home page, section order per Figma v5b 475:3726 (2026-10-13) (v3 mobile 362:3398 for the shared sections). */
export function Home() {
  const { c } = useSite();
  return (
    <>
      <JourneyHero />
      <Chapters />
      <FirstYear />
      <NextStages />
      <GrowUp />
      <Cta title={c.journey.ctaTitle} compact />
      <Faq items={c.home.faq.items} />
    </>
  );
}
