/**
 * Generates platform token files from tokens.json (single source of truth, Figma Foundations 17:467):
 *  - apps/mobile/lib/core/design/tokens.g.dart
 *  - packages/design-tokens/dist/tokens.css
 * `--check` fails if the committed outputs are stale (used in CI).
 */
import { execFileSync } from 'node:child_process';
import { mkdirSync, mkdtempSync, readFileSync, writeFileSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';

type Shadow = [number, number, number, number, string];
interface Tokens {
  color: Record<'light' | 'nightCare', Record<string, string>>;
  care: Record<'light' | 'nightCare', Record<string, Record<'soft' | 'ink' | 'accent', string>>>;
  typography: {
    family: string;
    styles: Record<
      string,
      { size: number; lineHeight: number; weight: number; letterSpacing: number; tabular?: boolean }
    >;
  };
  space: Record<string, number>;
  radius: Record<string, number>;
  shadow: Record<'light' | 'nightCare', Record<string, Shadow[] | string>>;
  motion: Record<string, unknown>;
}

const pkgRoot = join(import.meta.dirname, '..');
const repoRoot = join(pkgRoot, '..', '..');
const tokens = JSON.parse(readFileSync(join(pkgRoot, 'tokens.json'), 'utf8')) as Tokens;
const check = process.argv.includes('--check');

const camel = (name: string) => name.replace(/-([a-z0-9])/g, (_, c: string) => c.toUpperCase());
const isMeta = (key: string) => key.startsWith('$');

/** #RRGGBB or #RRGGBBAA → Dart 0xAARRGGBB. */
function dartColor(hex: string): string {
  const h = hex.replace('#', '').toUpperCase();
  const rgb = h.slice(0, 6);
  const alpha = h.length === 8 ? h.slice(6, 8) : 'FF';
  return `Color(0x${alpha}${rgb})`;
}

function cssColor(hex: string): string {
  const h = hex.replace('#', '');
  if (h.length === 6) return `#${h.toLowerCase()}`;
  const [r, g, b, a] = [0, 2, 4, 6].map((i) => parseInt(h.slice(i, i + 2), 16)) as [
    number,
    number,
    number,
    number,
  ];
  return `rgb(${r} ${g} ${b} / ${(a / 255).toFixed(3)})`;
}

const colorNames = Object.keys(tokens.color.light);
for (const mode of ['nightCare'] as const) {
  const missing = colorNames.filter((n) => !(n in tokens.color[mode]));
  if (missing.length) throw new Error(`${mode} is missing colours: ${missing.join(', ')}`);
}
const careNames = Object.keys(tokens.care.light);
const shadowNames = Object.keys(tokens.shadow.light).filter((k) => !isMeta(k));

interface TimedToken {
  ms: number;
  cubic?: [number, number, number, number];
  spring?: {
    response: number;
    dampingFraction: number;
    androidDampingRatio: number;
    androidStiffness: number;
  };
  webCubic?: [number, number, number, number];
  usage: string;
}
const motionEntries = Object.entries(tokens.motion).filter(([k]) => !isMeta(k));
const timed = motionEntries.filter(([, v]) => typeof v === 'object') as [string, TimedToken][];
const scalars = motionEntries.filter(([, v]) => typeof v === 'number') as [string, number][];

function dartMotion(): string[] {
  const lines = [
    '/// Motion tokens (Figma Motion spec 269:41). Use names, never raw numbers.',
    'abstract final class ClMotion {',
  ];
  for (const [name, t] of timed) {
    lines.push(`  /// ${t.usage}`);
    lines.push(`  static const Duration ${name} = Duration(milliseconds: ${t.ms});`);
    if (t.cubic) lines.push(`  static const Curve ${name}Curve = Cubic(${t.cubic.join(', ')});`);
    if (t.spring) {
      lines.push(`  static const double ${name}SpringResponse = ${t.spring.response};`);
      lines.push(
        `  static const double ${name}SpringDampingFraction = ${t.spring.dampingFraction};`,
      );
      lines.push(`  static const double ${name}AndroidStiffness = ${t.spring.androidStiffness};`);
      lines.push(
        `  static const double ${name}AndroidDampingRatio = ${t.spring.androidDampingRatio};`,
      );
    }
  }
  for (const [name, v] of scalars) {
    lines.push(
      Number.isInteger(v) && /Ms$|Max$|shift(Toast|Chip)$/.test(name)
        ? `  static const int ${name} = ${v};`
        : `  static const double ${name} = ${v};`,
    );
  }
  lines.push('}', '');
  return lines;
}

function cssMotion(): string[] {
  const lines: string[] = [];
  for (const [name, t] of timed) {
    lines.push(`  --motion-${name}: ${t.ms}ms;`);
    const cubic = t.cubic ?? t.webCubic;
    if (cubic) lines.push(`  --ease-${name}: cubic-bezier(${cubic.join(', ')});`);
  }
  for (const [name, v] of scalars)
    lines.push(`  --motion-${name.replace(/[A-Z]/g, (c) => '-' + c.toLowerCase())}: ${v};`);
  return lines;
}

// ---------------------------------------------------------------- Dart
function dartShadows(list: Shadow[]): string {
  if (list.length === 0) return '[]';
  return `[${list
    .map(
      ([x, y, blur, spread, c]) =>
        `BoxShadow(offset: Offset(${x}, ${y}), blurRadius: ${blur}, spreadRadius: ${spread}, color: ${dartColor(c)})`,
    )
    .join(', ')}]`;
}

const dart: string[] = [
  '// GENERATED by packages/design-tokens/scripts/generate.ts from tokens.json — do not edit.',
  '// Source: Figma Foundations 17:467 and Motion spec 269:19.',
  '// ignore_for_file: public_member_api_docs',
  '',
  "import 'package:flutter/animation.dart';\nimport 'package:flutter/painting.dart';",
  '',
  '/// Semantic colours for one palette (Light or Night care).',
  'class ClColors {',
  `  const ClColors({${colorNames.map((n) => `required this.${camel(n)}`).join(', ')}});`,
  ...colorNames.map((n) => `  final Color ${camel(n)};`),
  '',
  '  /// Blends two palettes, so switching Light ↔ Night care fades instead of snapping.',
  `  static ClColors lerp(ClColors a, ClColors b, double t) => ClColors(${colorNames
    .map((n) => `${camel(n)}: Color.lerp(a.${camel(n)}, b.${camel(n)}, t)!`)
    .join(', ')});`,
  '}',
  '',
  ...(['light', 'nightCare'] as const).map(
    (mode) =>
      `const ClColors ${mode}Colors = ClColors(${colorNames.map((n) => `${camel(n)}: ${dartColor(tokens.color[mode][n]!)}`).join(', ')});\n`,
  ),
  '/// soft = background · ink = text/icon on soft (≥5.5:1) · accent = bars/charts, never text (52:4493).',
  'class ClCareColor {',
  '  const ClCareColor({required this.soft, required this.ink, required this.accent});',
  '  final Color soft;',
  '  final Color ink;',
  '  final Color accent;',
  '',
  '  static ClCareColor lerp(ClCareColor a, ClCareColor b, double t) => ClCareColor(soft: Color.lerp(a.soft, b.soft, t)!, ink: Color.lerp(a.ink, b.ink, t)!, accent: Color.lerp(a.accent, b.accent, t)!);',
  '}',
  '',
  'class ClCareColors {',
  `  const ClCareColors({${careNames.map((n) => `required this.${n}`).join(', ')}});`,
  ...careNames.map((n) => `  final ClCareColor ${n};`),
  '',
  `  static ClCareColors lerp(ClCareColors a, ClCareColors b, double t) => ClCareColors(${careNames
    .map((n) => `${n}: ClCareColor.lerp(a.${n}, b.${n}, t)`)
    .join(', ')});`,
  '}',
  '',
  ...(['light', 'nightCare'] as const).map(
    (mode) =>
      `const ClCareColors ${mode}CareColors = ClCareColors(${careNames
        .map((n) => {
          const c = tokens.care[mode][n]!;
          return `${n}: ClCareColor(soft: ${dartColor(c.soft)}, ink: ${dartColor(c.ink)}, accent: ${dartColor(c.accent)})`;
        })
        .join(', ')});\n`,
  ),
  'class ClShadows {',
  `  const ClShadows({${shadowNames.map((n) => `required this.${camel(n.replace('shadow-', ''))}`).join(', ')}});`,
  ...shadowNames.map((n) => `  final List<BoxShadow> ${camel(n.replace('shadow-', ''))};`),
  '',
  `  static ClShadows lerp(ClShadows a, ClShadows b, double t) => ClShadows(${shadowNames
    .map((n) => camel(n.replace('shadow-', '')))
    .map((n) => `${n}: BoxShadow.lerpList(a.${n}, b.${n}, t)!`)
    .join(', ')});`,
  '}',
  '',
  ...(['light', 'nightCare'] as const).map(
    (mode) =>
      `const ClShadows ${mode}Shadows = ClShadows(${shadowNames
        .map(
          (n) =>
            `${camel(n.replace('shadow-', ''))}: ${dartShadows(tokens.shadow[mode][n] as Shadow[])}`,
        )
        .join(', ')});\n`,
  ),
  'abstract final class ClSpace {',
  ...Object.entries(tokens.space).map(
    ([k, v]) => `  static const double ${camel(k.replace('space-', 's'))} = ${v};`,
  ),
  '}',
  '',
  'abstract final class ClRadius {',
  ...Object.entries(tokens.radius).map(
    ([k, v]) => `  static const double ${camel(k.replace('radius-', ''))} = ${v};`,
  ),
  '}',
  '',
  '/// Text style specs (Figma 18:351). Font family is applied by the theme.',
  'class ClTextSpec {',
  '  const ClTextSpec({required this.size, required this.lineHeight, required this.weight, required this.letterSpacing, this.tabular = false});',
  '  final double size;',
  '  final double lineHeight;',
  '  final int weight;',
  '  final double letterSpacing;',
  '  final bool tabular;',
  '}',
  '',
  'abstract final class ClTextSpecs {',
  `  static const String family = '${tokens.typography.family}';`,
  ...Object.entries(tokens.typography.styles).map(
    ([k, s]) =>
      `  static const ClTextSpec ${camel(k)} = ClTextSpec(size: ${s.size}, lineHeight: ${s.lineHeight}, weight: ${s.weight}, letterSpacing: ${s.letterSpacing}${s.tabular ? ', tabular: true' : ''});`,
  ),
  '}',
  '',
  ...dartMotion(),
  '',
];

// ---------------------------------------------------------------- CSS
function cssShadows(list: Shadow[]): string {
  return list.length === 0
    ? 'none'
    : list.map(([x, y, b, s, c]) => `${x}px ${y}px ${b}px ${s}px ${cssColor(c)}`).join(', ');
}
const block = (mode: 'light' | 'nightCare') => [
  ...colorNames.map((n) => `  --${n}: ${cssColor(tokens.color[mode][n]!)};`),
  ...careNames.flatMap((n) =>
    (['soft', 'ink', 'accent'] as const).map(
      (p) => `  --care-${n}-${p}: ${cssColor(tokens.care[mode][n]![p])};`,
    ),
  ),
  ...shadowNames.map((n) => `  --${n}: ${cssShadows(tokens.shadow[mode][n] as Shadow[])};`),
];
const css = [
  '/* GENERATED by packages/design-tokens/scripts/generate.ts from tokens.json — do not edit. */',
  ':root {',
  `  --font-family: '${tokens.typography.family}', system-ui, sans-serif;`,
  ...Object.entries(tokens.space).map(([k, v]) => `  --${k}: ${v}px;`),
  ...Object.entries(tokens.radius).map(([k, v]) => `  --${k}: ${v}px;`),
  ...cssMotion(),
  ...Object.entries(tokens.typography.styles).flatMap(([k, s]) => [
    `  --text-${k}: ${s.weight} ${s.size}px/${s.lineHeight}px var(--font-family);`,
    `  --text-${k}-tracking: ${s.letterSpacing}px;`,
  ]),
  ...block('light'),
  '}',
  '',
  '/* Nested scope: a single section rendered in Night care (e.g. the landing Night section). */',
  ':root[data-theme="night-care"],',
  '[data-palette="night-care"] {',
  ...block('nightCare'),
  '}',
  '',
  '@media (prefers-color-scheme: dark) {',
  '  :root:not([data-theme="light"]) {',
  ...block('nightCare').map((l) => `  ${l}`),
  '  }',
  '}',
  '',
].join('\n');

const outputs: [string, string][] = [
  [join(repoRoot, 'apps/mobile/lib/core/design/tokens.g.dart'), dart.join('\n')],
  [join(pkgRoot, 'dist/tokens.css'), css],
];

/** Dart output is run through `dart format` so CI's format check and the stale check agree. */
function formatDart(source: string): string {
  const dir = mkdtempSync(join(tmpdir(), 'cl-tokens-'));
  const file = join(dir, 'tokens.g.dart');
  writeFileSync(file, source);
  execFileSync('dart', ['format', file], { stdio: 'ignore' });
  return readFileSync(file, 'utf8');
}
outputs[0]![1] = formatDart(outputs[0]![1]);

let stale = false;
for (const [path, content] of outputs) {
  if (check) {
    if (!existsSync(path) || readFileSync(path, 'utf8') !== content) {
      console.error(`stale: ${path}`);
      stale = true;
    }
    continue;
  }
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, content);
  console.log(`wrote ${path}`);
}
if (stale) process.exit(1);
