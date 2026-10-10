import { describe, expect, it } from 'vitest';
import { handlePing, PingError } from '../src/ping.js';

const opId = '0b9f1c9e-6a54-4a43-9a3d-2f6d5c8f3e11';
const now = new Date('2026-10-10T00:00:00.000Z');

describe('handlePing', () => {
  it('answers a dev client from the dev project', () => {
    expect(handlePing({ clientEnvironment: 'dev', opId }, 'child-life-dev', now)).toEqual({
      ok: true,
      projectId: 'child-life-dev',
      region: 'asia-southeast1',
      serverTime: '2026-10-10T00:00:00.000Z',
      opId,
    });
  });

  it('treats demo emulator projects as dev', () => {
    expect(handlePing({ clientEnvironment: 'dev', opId }, 'demo-child-life', now).ok).toBe(true);
  });

  it('refuses a prod client talking to dev and the reverse', () => {
    expect(() => handlePing({ clientEnvironment: 'prod', opId }, 'child-life-dev', now)).toThrow(
      PingError,
    );
    expect(() => handlePing({ clientEnvironment: 'dev', opId }, 'child-life-prod', now)).toThrow(
      /does not match/,
    );
  });

  it('rejects malformed requests and unknown projects', () => {
    expect(() => handlePing({ clientEnvironment: 'dev' }, 'child-life-dev', now)).toThrow(
      /Malformed/,
    );
    expect(() => handlePing({ clientEnvironment: 'dev', opId }, 'someone-else', now)).toThrow(
      /not a Child Life environment/,
    );
  });
});
