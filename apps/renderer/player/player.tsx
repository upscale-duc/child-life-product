import { Player } from '@remotion/player';
import { useEffect, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { FPS, type MemoryStoryProps } from '../src/compositions/MemoryStory';
import { storyOf } from '../src/compositions/registry';
import type { StoryProps } from '../src/kit/core';

/**
 * Video kỷ niệm preview (D-068): the renderer's own compositions, played in the phone's WebView,
 * so what parents see before "Tạo video" is what the server renders. The app sends the props
 * through `window.childLifePreview(...)` once this page says it is ready
 * (`ChildLifePreview.postMessage('ready')`). Photos arrive as data URLs or as the sample pictures
 * served here; nothing is fetched from Child Life's storage and nothing is sent anywhere.
 */
type Message = { composition: string; props: MemoryStoryProps; startFrame?: number };

declare global {
  interface Window {
    childLifePreview?: (m: Message) => void;
    ChildLifePreview?: { postMessage: (s: string) => void };
  }
}

function Story(p: MemoryStoryProps & { composition: string }) {
  const { Component } = storyOf(p.composition);
  return <Component {...(p as StoryProps)} />;
}

function App() {
  const [message, setMessage] = useState<Message | null>(null);
  useEffect(() => {
    window.childLifePreview = setMessage;
    window.ChildLifePreview?.postMessage('ready');
  }, []);
  if (!message) return null;
  return (
    <Player
      component={Story}
      inputProps={{ ...message.props, composition: message.composition }}
      durationInFrames={storyOf(message.composition).frames(message.props as StoryProps)}
      fps={FPS}
      compositionWidth={1080}
      compositionHeight={
        (message.props as StoryProps).presentation?.format === 'portrait' ? 1350 : 1920
      }
      style={{ width: '100%', height: '100%' }}
      controls
      autoPlay
      loop
      clickToPlay
      initiallyMuted={false}
      initialFrame={message.startFrame ?? 0}
    />
  );
}

createRoot(document.getElementById('root')!).render(<App />);
