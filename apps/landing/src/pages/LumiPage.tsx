import { useSite } from '../context';
import { ForBabyDetail } from '../sections/ForBaby';
import { LumiJourney } from '../sections/Lumi';
import {
  LumiBenefits,
  LumiCta,
  LumiDay,
  LumiFaq,
  LumiHero,
  LumiHow,
  LumiMore,
  LumiPlans,
} from '../sections/LumiDetail';

/** Lumi page, section order per Figma 650:4798 "Lumi · Trang chi tiết" (33-landing-lumi-page §0.1). */
export function LumiPage() {
  const { c } = useSite();
  return (
    <>
      <LumiHero />
      <LumiBenefits />
      <LumiDay />
      <ForBabyDetail />
      <LumiMore />
      <section
        id="suot-hanh-trinh"
        className="lp-section container"
        aria-labelledby="lumi-journey-title"
      >
        <LumiJourney cta={{ label: c.lumiJourney.tryNow, href: '#tai-app' }} />
      </section>
      <LumiHow />
      <LumiPlans />
      <LumiFaq />
      <LumiCta />
    </>
  );
}
