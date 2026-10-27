// Browser review only: derive representative data from existing unit-test fixtures.
import ts from 'typescript';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const here = path.dirname(fileURLToPath(import.meta.url));
const selections = {
  system: ['health', 'ai'],
  hub: ['hub', 'flagsView', 'premiumView'],
  content: ['articleView', 'stageView', 'fullArticle', 'itemOf'],
  v1: ['team', 'list', 'growth', 'feats'],
  'first-aid': ['view'],
  rhythm: ['view', 'rulesView'],
  notifications: ['stats', 'opsResponse', 'tplDetail', 'timeline'],
  'app-update': ['view'],
  assistant: ['usage'],
  'product-analytics': ['result'],
  qa: ['cases', 'results', 'run'],
  nutrition: ['stageRows', 'nutrientRows', 'ruleRows', 'view'],
  solids: ['foodRows', 'recipeRows', 'view'],
};
for (const [name, exports] of Object.entries(selections)) {
  const input = fs.readFileSync(path.join(here, `../${name}.test.tsx`), 'utf8');
  const sf = ts.createSourceFile(
    name + '.tsx',
    input,
    ts.ScriptTarget.Latest,
    true,
    ts.ScriptKind.TSX,
  );
  const declarations = new Map();
  for (const node of sf.statements) {
    if (ts.isVariableStatement(node))
      for (const d of node.declarationList.declarations)
        if (ts.isIdentifier(d.name)) declarations.set(d.name.text, node);
    if (ts.isFunctionDeclaration(node) && node.name) declarations.set(node.name.text, node);
  }
  const used = new Set(exports),
    chosen = new Set();
  const visit = (node) => {
    if (ts.isIdentifier(node)) used.add(node.text);
    ts.forEachChild(node, visit);
  };
  let changed = true;
  while (changed) {
    changed = false;
    for (const key of [...used]) {
      const n = declarations.get(key);
      if (n && !chosen.has(n)) {
        chosen.add(n);
        visit(n);
        changed = true;
      }
    }
  }
  const imports = sf.statements
    .filter(ts.isImportDeclaration)
    .filter(
      (n) =>
        !['vitest', 'node:fs', 'node:path', 'react-dom/server'].includes(n.moduleSpecifier.text),
    )
    .map((n) => {
      let raw = n.getText(sf);
      const spec = n.moduleSpecifier.text;
      if (spec.startsWith('../src/')) raw = raw.replace(spec, spec.replace('../src/', '/src/'));
      if (spec === './fixtures') raw = raw.replace(spec, '/test/fixtures');
      return raw;
    });
  const code = [
    ...imports,
    ...sf.statements.filter((n) => chosen.has(n)).map((n) => n.getText(sf)),
    `export {${exports.join(',')}};`,
  ].join('\n');
  const js = ts.transpileModule(code, {
    compilerOptions: {
      target: ts.ScriptTarget.ES2022,
      module: ts.ModuleKind.ESNext,
      jsx: ts.JsxEmit.ReactJSX,
    },
  }).outputText;
  fs.writeFileSync(
    path.join(here, `${name}.fixture.js`),
    '// Generated test data; run extract-fixtures.mjs. Never imported by production.\n' + js,
  );
}
