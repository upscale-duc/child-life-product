import { Care } from '../sections/Care';
import { Cocare } from '../sections/Cocare';
import { Cta } from '../sections/Cta';
import { Everything } from '../sections/Everything';
import { Faq } from '../sections/Faq';
import { FirstAid } from '../sections/FirstAid';
import { Hero } from '../sections/Hero';
import { Library } from '../sections/Library';
import { Memories } from '../sections/Memories';
import { Night } from '../sections/Night';
import { Quick } from '../sections/Quick';
import { Reminders } from '../sections/Reminders';
import { Roles } from '../sections/Roles';
import { Understand } from '../sections/Understand';

/** Landing page, section order per Figma v3 321:1222 / 324:45487. */
export function Home() {
  return (
    <>
      <Hero />
      <Everything />
      <Quick />
      <Care />
      <Reminders />
      <Cocare />
      <Understand />
      <Library />
      <FirstAid />
      <Memories />
      <Night />
      <Roles />
      <Cta />
      <Faq />
    </>
  );
}
