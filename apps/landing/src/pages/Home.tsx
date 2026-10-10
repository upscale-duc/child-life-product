import { Care } from '../sections/Care';
import { Cocare } from '../sections/Cocare';
import { Cta } from '../sections/Cta';
import { Faq } from '../sections/Faq';
import { Hero } from '../sections/Hero';
import { Memories } from '../sections/Memories';
import { Night } from '../sections/Night';
import { Quick } from '../sections/Quick';
import { Roles } from '../sections/Roles';

/** Landing page, section order per Figma 219:1391 / 233:804. */
export function Home() {
  return (
    <>
      <Hero />
      <Quick />
      <Care />
      <Cocare />
      <Memories />
      <Night />
      <Roles />
      <Cta />
      <Faq />
    </>
  );
}
