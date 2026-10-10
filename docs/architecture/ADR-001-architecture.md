# ADR-001 — Modular monorepo, Flutter + Firebase, server-side authority

- **Status:** accepted (2026-10-10)
- **Context:** Engineering brief §02–03; implementation plan §3.
- **Decision:** One repository with `apps/` (mobile, landing, portal), `packages/` (contracts, web-config, vite-robots), `firebase/` (functions, rules, tests), `scripts/`, `docs/`. Flutter with Riverpod + go_router for mobile; React + TypeScript + Vite for web; Firebase (Auth, Firestore, Storage, Functions 2nd gen, Hosting) as the backend. Clients are untrusted: Rules deny by default and sensitive operations run in callable Functions with schema validation. Shared contracts are Zod schemas; Functions are bundled with esbuild so workspace packages never reach Cloud Build.
- **Consequences:** One place for schema changes; Dart models mirror the Zod contracts (generation planned in S2). Functions deploys depend on the bundle step (`build:deploy`).
