# Child Life

Private family space for co-caring for a baby and keeping their growing-up memories. Flutter iOS/Android app, Firebase backend, landing site and staff portal on Firebase Hosting, with separate **dev** and **prod** environments. Vietnamese and English (D-012).

**Status:** S0 (environments, CI), S1 (design system) and S14 (landing, vi + en — https://child-life-dev-landing.web.app) delivered on dev — see the [S0](docs/development/slice-reports/S0.md), [S1](docs/development/slice-reports/S1.md) and [S14](docs/development/slice-reports/S14.md) reports. Product screens start in S2.

## Repository

| Path                                 | What                                                                                                      |
| ------------------------------------ | --------------------------------------------------------------------------------------------------------- |
| `apps/mobile`                        | Flutter app (iOS + Android), flavors `dev` / `prod`                                                       |
| `apps/landing`                       | Landing site + recipient web + invite links (React, Vite)                                                 |
| `apps/portal`                        | Staff portal "Child Life · Vận hành" (React, Vite)                                                        |
| `packages/contracts`                 | Shared schemas (Zod): environments, feature flags, limits, callables                                      |
| `packages/web-config`                | Web environment + locale resolution, public Firebase web config                                           |
| `packages/vite-robots`               | Keeps dev hosts out of search engines                                                                     |
| `packages/design-tokens`             | Figma tokens (`tokens.json`) → generated Dart + CSS (`pnpm --filter @child-life/design-tokens run build`) |
| `firebase/functions`                 | Cloud Functions (2nd gen, Node 22, asia-southeast1)                                                       |
| `firebase/*.rules`, `firebase/tests` | Firestore / Storage Rules and their emulator tests                                                        |
| `scripts`                            | Dev seed (refuses prod), deploy                                                                           |
| `docs`                               | Product, development, architecture (ADRs), operations, discovery                                          |

## Prerequisites

Node 22 (`.nvmrc`), pnpm 11, Flutter **3.44.8** (`.flutter-version`), Java 21, Xcode 26 + CocoaPods, Firebase CLI, gcloud.

## Setup

```bash
pnpm install
pnpm --filter @child-life/contracts --filter @child-life/web-config run build
cd apps/mobile && flutter pub get
```

## Everyday commands

```bash
pnpm typecheck && pnpm lint && pnpm test        # TypeScript packages, Functions, web
pnpm test:rules                                  # Rules tests on the emulators
cd apps/mobile && flutter analyze && flutter test
cd apps/mobile && flutter run --flavor dev       # app against child-life-dev
pnpm --filter child-life-portal dev              # portal on localhost (dev backend)
pnpm --filter child-life-landing dev             # landing on localhost (client-rendered)
pnpm --filter child-life-landing run build:dev   # prerendered landing in apps/landing/dist
```

The app must always be built with `--flavor dev` or `--flavor prod`; there is no unflavored build. Prod is refused at startup until `child-life-prod` exists.

## Environments

|                  | dev                                                                                                                                   | prod                                    |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------- |
| Firebase project | `child-life-dev`                                                                                                                      | `child-life-prod` (not created yet)     |
| App id           | `app.childlife.dev`                                                                                                                   | `app.childlife`                         |
| Site / admin     | `dev.childlife.app` / `admin.dev.childlife.app` (DNS pending; today `child-life-dev-landing.web.app`, `child-life-dev-admin.web.app`) | `childlife.app` / `admin.childlife.app` |

Deploy with `scripts/deploy.sh dev [firestore,storage,functions,hosting]`. Prod deploys require owner approval (`CHILD_LIFE_PROD_APPROVED=yes`). Seed dev config with `pnpm --filter child-life-scripts run seed:dev`.

## Documentation

| Document                                                                             | Purpose                                                                                                                                    |
| ------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------ |
| [docs/product/business-map.md](docs/product/business-map.md)                         | Entities, roles & permissions, lifecycles, side effects, failure/recovery; confirmed rules vs proposals vs open questions; owner decisions |
| [docs/development/implementation-plan.md](docs/development/implementation-plan.md)   | Architecture, environments, spikes, delivery slices, testing, operations                                                                   |
| [docs/product/figma-coverage-checklist.md](docs/product/figma-coverage-checklist.md) | Every Figma screen, state, flow and component → slice, code, tests                                                                         |
| [docs/architecture/](docs/architecture/)                                             | ADRs                                                                                                                                       |
| [docs/discovery/](docs/discovery/)                                                   | Figma extraction evidence and product-plan summary                                                                                         |

Product scope and UI come from the final Figma file `sJLG1fAXKDnDr9YI6Yx8ex` (read-only — never modify it).
