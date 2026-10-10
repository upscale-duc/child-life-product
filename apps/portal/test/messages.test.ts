import { describe, expect, it } from 'vitest';
import { messages } from '../src/messages';

describe('message catalogs', () => {
  it('English and Vietnamese define exactly the same message ids', () => {
    expect(Object.keys(messages.en).sort()).toEqual(Object.keys(messages.vi).sort());
  });
  it('no message is empty', () => {
    for (const catalog of Object.values(messages)) {
      for (const text of Object.values(catalog)) expect(text.trim()).not.toBe('');
    }
  });
});
