# Apple Watch asset catalog (plan docs/product/apple-watch-plan.md): the app's own icons
# (assets/icons/*.svg, the Figma Icon/* set) as template images, and the flavor app icons, so the
# watch never keeps a second copy to edit by hand. SVG `currentColor` becomes black because the
# images render as templates (tinted in SwiftUI). Idempotent. Usage: python3 tool/watch_assets.py
import json, pathlib, shutil

ICONS = ['feed', 'drop', 'sleep', 'diaper', 'bell', 'check', 'cloud-off', 'retry']

app = pathlib.Path(__file__).resolve().parent.parent
catalog = app / 'ios' / 'watch' / 'Assets.xcassets'
catalog.mkdir(parents=True, exist_ok=True)
info = {'author': 'xcode', 'version': 1}
(catalog / 'Contents.json').write_text(json.dumps({'info': info}, indent=2) + '\n')

for name in ICONS:
    folder = catalog / f'Icon-{name}.imageset'
    if folder.exists():
        shutil.rmtree(folder)
    folder.mkdir()
    svg = (app / 'assets' / 'icons' / f'{name}.svg').read_text().replace('currentColor', '#000000')
    (folder / f'{name}.svg').write_text(svg)
    (folder / 'Contents.json').write_text(json.dumps({
        'images': [{'filename': f'{name}.svg', 'idiom': 'universal'}],
        'info': info,
        'properties': {'preserves-vector-representation': True, 'template-rendering-intent': 'template'},
    }, indent=2) + '\n')

# App icons per flavor, from the iOS sets (one 1024 px image; watchOS crops it to a circle).
for flavor in ('dev', 'prod'):
    src = app / 'ios' / 'Runner' / 'Assets.xcassets' / f'AppIcon-{flavor}.appiconset' / 'icon-light.png'
    folder = catalog / f'AppIcon-{flavor}.appiconset'
    if folder.exists():
        shutil.rmtree(folder)
    folder.mkdir()
    shutil.copy(src, folder / 'icon.png')
    (folder / 'Contents.json').write_text(json.dumps({
        'images': [{'filename': 'icon.png', 'idiom': 'universal', 'platform': 'watchos', 'size': '1024x1024'}],
        'info': info,
    }, indent=2) + '\n')

print(len(ICONS), 'icons + 2 app icons ->', catalog.relative_to(app))
