import { defineConfig } from 'vitest/config';

// Rules tests run against the emulators started by `pnpm test:rules` (firebase emulators:exec).
export default defineConfig({
  test: { fileParallelism: false, testTimeout: 20_000 },
});
