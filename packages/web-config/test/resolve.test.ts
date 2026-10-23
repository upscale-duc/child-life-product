import { describe, expect, it } from 'vitest';
import {
  EnvironmentConfigError,
  resolveSiteEnvironment,
  resolveWebEnvironment,
} from '../src/index.js';

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
    expect(() => resolveWebEnvironment('dev', 'landing', 'child-life-ecosystem.web.app')).toThrow();
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

describe('resolveSiteEnvironment', () => {
  it('runs the landing on its own hosts without Firebase config', () => {
    for (const host of ['childlife.app', 'www.childlife.app', 'child-life-ecosystem.web.app'])
      expect(resolveSiteEnvironment('prod', host)).toBe('prod');
    expect(resolveSiteEnvironment('dev', 'dev.childlife.app')).toBe('dev');
  });

  it('refuses the other environment hosts and unknown modes', () => {
    expect(() => resolveSiteEnvironment('prod', 'dev.childlife.app')).toThrow(/must not run/);
    expect(() => resolveSiteEnvironment('prod', 'child-life-dev-landing.web.app')).toThrow();
    expect(() => resolveSiteEnvironment('prod', 'localhost')).toThrow();
    expect(() => resolveSiteEnvironment('dev', 'childlife.app')).toThrow();
    expect(() => resolveSiteEnvironment('staging', 'localhost')).toThrow(/Unknown build mode/);
  });
});
