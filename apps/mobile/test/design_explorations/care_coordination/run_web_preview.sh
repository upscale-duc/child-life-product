#!/usr/bin/env bash
# Host the isolated Flutter mockup without adding web support to the shipping mobile project.
set -euo pipefail
mobile_root=$(cd "$(dirname "$0")/../../.." && pwd)
preview_root=$(mktemp -d /tmp/childlife-care-preview.XXXXXX)
mkdir -p "$preview_root/web"
cp "$mobile_root/pubspec.yaml" "$preview_root/pubspec.yaml"
cp "$mobile_root/pubspec.lock" "$preview_root/pubspec.lock"
ln -s "$mobile_root/lib" "$preview_root/lib"
ln -s "$mobile_root/test" "$preview_root/test"
ln -s "$mobile_root/assets" "$preview_root/assets"
# Reuse already-generated production localizations read-only, never regenerate through the symlink.
python3 - "$preview_root/pubspec.yaml" <<'PY'
import sys
from pathlib import Path
p=Path(sys.argv[1])
p.write_text(p.read_text().replace('  generate: true', '  generate: false'))
PY
cat > "$preview_root/web/index.html" <<'HTML'
<!doctype html>
<html lang="vi"><head>
<base href="/">
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Child Life — Care coordination prototype</title>
</head><body><script src="flutter_bootstrap.js" async></script></body></html>
HTML
cd "$preview_root"
flutter pub get > "$preview_root/pub-get.log" 2>&1
printf 'Isolated preview directory: %s\n' "$preview_root"
exec flutter run -d web-server --web-hostname 127.0.0.1 --web-port "${1:-8268}" \
  -t test/design_explorations/care_coordination/preview.dart
