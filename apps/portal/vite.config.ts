import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';
import { robotsPolicy } from '@child-life/vite-robots';

export default defineConfig({
  plugins: [react(), robotsPolicy(() => false)],
  build: { sourcemap: true },
});
