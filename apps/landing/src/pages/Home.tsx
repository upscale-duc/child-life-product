import { Closing } from '../sections/Closing';
import { HomeAssistant } from '../sections/HomeAssistant';
import { HomeFamily } from '../sections/HomeFamily';
import { HomeHero, HomeValues } from '../sections/HomeIntro';
import { HomeMemories } from '../sections/HomeMemories';
import { HomeJourney, HomeTools, HomeTrust } from '../sections/HomeMore';

/** Home page, V8 (Figma 735:5377 desktop, 736:65570 mobile; 34-landing-v8-home): what the app
 *  does, memories, caring together, Lumi, tools, the journey, free & trust with the FAQ, Kết. */
export function Home() {
  return (
    <>
      <HomeHero />
      <HomeValues />
      <HomeMemories />
      <HomeFamily />
      <HomeAssistant />
      <HomeTools />
      <HomeJourney />
      <HomeTrust />
      <Closing />
    </>
  );
}
