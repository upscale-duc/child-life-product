import { Closing } from '../sections/Closing';
import { HomeAlerts, HomeAssistant } from '../sections/HomeAssistant';
import { HomeFamily } from '../sections/HomeFamily';
import { HomeHero, HomeRestart, HomeValues } from '../sections/HomeIntro';
import { HomeMemories } from '../sections/HomeMemories';
import { HomeJourney, HomeTools, HomeTrust } from '../sections/HomeMore';

/** Home page, V9 (Figma 785:7031 desktop, 785:7890 mobile; 37-landing-v9-home): what the app
 *  does, never too late to start, memories, caring together, Lumi, reminders, tools, the journey,
 *  free & trust with the FAQ, Kết. */
export function Home() {
  return (
    <>
      <HomeHero />
      <HomeValues />
      <HomeRestart />
      <HomeMemories />
      <HomeFamily />
      <HomeAssistant />
      <HomeAlerts />
      <HomeTools />
      <HomeJourney />
      <HomeTrust />
      <Closing />
    </>
  );
}
