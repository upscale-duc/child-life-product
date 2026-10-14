import { keepsakeCompositions } from '@child-life/contracts';
import { describe, expect, it } from 'vitest';
import { posterFrame, sceneFrames } from '../src/compositions/MemoryStory';
import { compositions } from '../src/compositions/Root';

describe('compositions', () => {
  it('the renderer has exactly the compositions the catalog may name', () => {
    expect(Object.keys(compositions).sort()).toEqual([...keepsakeCompositions].sort());
  });

  it('scenes share what the intro and outro leave; the poster is inside the first photo', () => {
    expect(sceneFrames(45, 6)).toBeGreaterThan(30 * 4);
    expect(posterFrame(45, 6)).toBeGreaterThan(60);
    expect(posterFrame(45, 6)).toBeLessThan(60 + sceneFrames(45, 6));
  });
});
