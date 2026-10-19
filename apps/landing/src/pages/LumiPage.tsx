import { ForBabyDetail } from '../sections/ForBaby';
import {
  LumiBenefits,
  LumiCta,
  LumiDay,
  LumiFaq,
  LumiHero,
  LumiHow,
  LumiPlans,
  LumiQuickNav,
} from '../sections/LumiDetail';

/** Lumi page, V8 order (Figma 737:67153; 36-landing-v8-lumi-and-stages A): value, examples, ideas
 *  for your baby, how it works, plans, FAQ. "Còn nhiều việc" and the stage roadmap are gone. */
export function LumiPage() {
  return (
    <>
      <LumiHero />
      <LumiBenefits />
      <LumiQuickNav />
      <LumiDay />
      <ForBabyDetail />
      <LumiHow />
      <LumiPlans />
      <LumiFaq />
      <LumiCta />
    </>
  );
}
