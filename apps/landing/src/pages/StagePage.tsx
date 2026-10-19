import type { StageId } from '../routes';
import { Closing } from '../sections/Closing';
import { FutureStage } from '../sections/Stage';

/** Chặng 2–4 (V8 template, Figma 738:7309; 36-landing-v8-lumi-and-stages B): a status band, the
 *  stage hero, three directions, links to the other stages and Kết. Chặng 1 is the Năm đầu đời
 *  page (`pages/FirstYear.tsx`). */
export function StagePage({ stage }: { stage: Exclude<StageId, 'stage1'> }) {
  return (
    <div className="stage-page" data-stage={stage}>
      <FutureStage stage={stage} />
      <Closing />
    </div>
  );
}
