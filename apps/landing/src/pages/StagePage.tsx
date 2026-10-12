import { useSite } from '../context';
import type { StageId } from '../routes';
import { Care } from '../sections/Care';
import { Cocare } from '../sections/Cocare';
import { Cta } from '../sections/Cta';
import { Everything } from '../sections/Everything';
import { Faq } from '../sections/Faq';
import { FirstAid } from '../sections/FirstAid';
import { Library } from '../sections/Library';
import { Memories } from '../sections/Memories';
import { Night } from '../sections/Night';
import { Quick } from '../sections/Quick';
import { Reminders } from '../sections/Reminders';
import { Roles } from '../sections/Roles';
import { StageHero, StageHighlights, StagePrevNext, StageSwitcher } from '../sections/Stage';
import { Understand } from '../sections/Understand';

/** A "Chặng" page (15-landing-v3-stages): Chặng 1 carries the v2.1 feature sections
 *  (Figma 370:50752); Chặng 2–4 share the short template (361:3457 / 3575 / 3693). */
export function StagePage({ stage }: { stage: StageId }) {
  const { c } = useSite();
  return (
    <div className="stage-page" data-stage={stage}>
      <StageSwitcher stage={stage} />
      <StageHero stage={stage} />
      {stage === 'stage1' ? (
        <>
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
          <StagePrevNext stage={stage} />
          <Cta />
          <Faq />
        </>
      ) : (
        <>
          <StageHighlights stage={stage} />
          <StagePrevNext stage={stage} />
          <Cta title={c.journey.ctaTitle} compact />
        </>
      )}
    </div>
  );
}
