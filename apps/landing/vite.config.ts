import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';

export default defineConfig({
  plugins: [react()],
  build: {
    sourcemap: true,
    cssCodeSplit: false,
    // Photos stay files (cacheable, lazy); small SVG art may inline.
    assetsInlineLimit: (file) => (file.endsWith('.svg') ? undefined : false),
  },
  ssr: { noExternal: ['@child-life/web-config', '@child-life/contracts'] },
});
