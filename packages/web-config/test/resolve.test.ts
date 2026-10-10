import { describe, expect, it } from 'vitest';
import { EnvironmentConfigError, resolveWebEnvironment } from '../src/index.js';

describe('resolveWebEnvironment', () => {
  it('accepts dev builds on dev hosts, previews and localhost', () => {
    for (const host of ['dev.childlife.app', 'child-life-dev-landing.web.app', 'localhost']) {
      expect(resolveWebEnvironment('dev', 'landing', host).firebase.projectId).toBe(
        'child-life-dev',
      );
    }
    expect(resolveWebEnvironment('dev', 'admin', 'admin.dev.childlife.app').environment).toBe(
      'dev',
    );
  });

  it('refuses a dev build served from a prod host and admin builds on the site host', () => {
    expect(() => resolveWebEnvironment('dev', 'landing', 'childlife.app')).toThrow(
      EnvironmentConfigError,
    );
    expect(() => resolveWebEnvironment('dev', 'admin', 'dev.childlife.app')).toThrow(
      /must not run/,
    );
    expect(() => resolveWebEnvironment('dev', 'landing', 'child-life-prod.web.app')).toThrow();
  });

  it('refuses prod until it is configured, and unknown modes', () => {
    expect(() => resolveWebEnvironment('prod', 'landing', 'childlife.app')).toThrow(
      /not configured/,
    );
    expect(() => resolveWebEnvironment('staging', 'landing', 'localhost')).toThrow(
      /Unknown build mode/,
    );
  });
});
