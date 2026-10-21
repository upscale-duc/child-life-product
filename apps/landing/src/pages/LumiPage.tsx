import {
  LumiBenefits,
  LumiCta,
  LumiFaq,
  LumiHero,
  LumiHow,
  LumiModules,
} from '../sections/LumiDetail';

/** Lumi page, V9 order (Figma 785:9913; 39-landing-v9-lumi-and-stages A): hero, value, what Lumi
 *  understands, how it works, FAQ, Kết. The examples, ideas for your baby and the plans are gone. */
export function LumiPage() {
  return (
    <>
      <LumiHero />
      <LumiBenefits />
      <LumiModules />
      <LumiHow />
      <LumiFaq />
      <LumiCta />
    </>
  );
}
