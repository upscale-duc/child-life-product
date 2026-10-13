import tailwindcss from '@tailwindcss/vite';
import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';
import { robotsPolicy } from '@child-life/vite-robots';

export default defineConfig({
  plugins: [react(), tailwindcss(), robotsPolicy(() => false)],
  // shadcn/ui components import from "@/…" (D-063); Vite resolves "/src" from the project root.
  resolve: { alias: { '@': '/src' } },
  build: { sourcemap: true },
});
