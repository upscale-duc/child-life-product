import type { Plugin } from 'vite';

/** Dev builds must never be indexed (implementation plan §3.7). */
export function robotsPolicy(indexable: (mode: string) => boolean): Plugin {
  let mode = 'dev';
  return {
    name: 'child-life-robots',
    configResolved(config) {
      mode = config.mode;
    },
    transformIndexHtml() {
      return indexable(mode)
        ? []
        : [
            {
              tag: 'meta',
              attrs: { name: 'robots', content: 'noindex, nofollow' },
              injectTo: 'head',
            },
          ];
    },
    generateBundle() {
      this.emitFile({
        type: 'asset',
        fileName: 'robots.txt',
        source: indexable(mode)
          ? 'User-agent: *\nDisallow: /s/\nDisallow: /i/\n'
          : 'User-agent: *\nDisallow: /\n',
      });
    },
  };
}
