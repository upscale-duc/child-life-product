# Portal design review harness

Renders the actual React Shell, shared components and screens with synthetic staff data.
There is no Firebase connection and no production API. Keep this separate from the production entry point.
`extract-fixtures.mjs` derives data from the existing unit-test fixtures; generated `*.fixture.js` files are ignored.
Unsupported fixture API calls return an explicit unavailable error. A mounted screen is not proof that its live workflow works.

## Reproduce

From the repository root, using the repository's Node/pnpm versions:

```sh
pnpm --filter @child-life/contracts --filter @child-life/web-config run build
node apps/portal/test/design-review/extract-fixtures.mjs
pnpm --filter child-life-portal dev --host 127.0.0.1 --port 5181
```

Open `http://127.0.0.1:5181/test/design-review/index.html?path=/features&lang=vi`.
Parameters: `path`, `lang=vi|en`, `role` (defaults to owner), `state=loading|error`.
Theme uses the normal portal theme toggle/local storage. No action in this fixture represents a live save or notification send.

Browser tooling is deliberately temporary, with no production dependency:

```sh
npm install --prefix /tmp/child-life-portal-browser playwright
node apps/portal/test/design-review/interactions.mjs
PHASE=after node apps/portal/test/design-review/capture.mjs
```

The scripts use installed Google Chrome on macOS. Override `PORTAL_CHROME` and
`PORTAL_PLAYWRIGHT_MODULE` (absolute path to `playwright/index.mjs`) on another machine.
A capture writes into `docs/design/reviews/assets/2026-10-26-portal/<PHASE>/`.
Use a new phase name to preserve previous evidence. `ROUTES='["/print-studio"]'` limits the route list;
partial runs merge entries into that phase's coverage manifest. The default after batch has 255 captures.
The six `zoom2` probes use a 720 CSS-pixel viewport at DPR 2, equivalent to the layout space of
200% zoom on a 1440px display. They do not verify OS font scaling or a screen reader.

`coverage.json` records route, locale, theme, viewport, page overflow, browser errors and rendered text.
Sample image domains ending in `.test` are intercepted with a neutral placeholder.
Analytics fixtures are intentionally sparse; several sections reuse the overview metric fixture,
so empty charts here do not establish that production analytics lacks data.

`copy-baseline.json` preserves original bilingual values for the reviewed existing keys. The
readability tests protect their interpolation variables and ICU formatting. It is historical test evidence,
not a second runtime translation catalog. Change the canonical `src/messages*.ts` catalogs only.
