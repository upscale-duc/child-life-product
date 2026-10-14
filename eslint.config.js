import js from '@eslint/js';
import tseslint from 'typescript-eslint';

export default tseslint.config(
  {
    ignores: [
      '**/node_modules/**',
      '**/dist/**',
      'firebase/functions/deploy/**',
      'apps/renderer/build/**',
      'apps/renderer/out/**',
      'apps/renderer/dist-player/**',
      'apps/mobile/**',
      'docs/**',
    ],
  },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    files: ['**/*.mjs', 'scripts/**', 'firebase/**', 'apps/renderer/**'],
    languageOptions: { globals: { console: 'readonly', process: 'readonly' } },
  },
);
