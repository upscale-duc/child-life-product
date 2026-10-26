#!/usr/bin/env bash
# Golden freshness check (D-111): which committed baselines still match the current code.
#
# Runs the golden tests WITHOUT --update-goldens, so no baseline is ever written. For every
# mismatch Flutter writes the fresh render to test/golden/failures/<name>_testImage.png (gitignored)
# next to the baseline (<name>_masterImage.png) and the diff (<name>_isolatedDiff.png).
#
#   Current  = the baseline matched a fresh render of the current code.
#   Outdated = the baseline differs: use failures/<name>_testImage.png as the visual truth, and
#              investigate before updating (intended change elsewhere, regression, or fixture drift).
#
# Usage (macOS, from apps/mobile):
#   tool/golden_freshness.sh                          # every golden test
#   tool/golden_freshness.sh test/golden/care_golden_test.dart test/golden/history_golden_test.dart
# Output: a summary on stdout and test/golden/failures/FRESHNESS.txt.
set -uo pipefail
cd "$(dirname "$0")/.."

targets=("$@")
[ ${#targets[@]} -eq 0 ] && targets=(test/golden)

rm -rf test/golden/failures
log=$(mktemp)
flutter test --tags golden "${targets[@]}" >"$log" 2>&1
status=$?

mkdir -p test/golden/failures
report=test/golden/failures/FRESHNESS.txt
passed=$(grep -oE '\+[0-9]+' "$log" | tail -1 | tr -d '+')
{
  echo "Golden freshness check · $(date '+%Y-%m-%d %H:%M') · $(git rev-parse --short HEAD)$(git diff --quiet -- lib test || echo ' + uncommitted changes')"
  echo "Targets: ${targets[*]}"
  echo "Current (baseline matches the code): ${passed:-0}"
  echo "Outdated (baseline differs; fresh render in failures/):"
  grep -oE 'Golden "[^"]+": Pixel test failed, [0-9.]+%' "$log" |
    sed -E 's/Golden "([^"]+)": Pixel test failed, ([0-9.]+)%/  \1  (\2 % of pixels)/' | sort -u
  grep -q 'Could not be compared against non-existent file' "$log" &&
    echo "Missing baselines:" &&
    grep -oE 'non-existent file: "[^"]+"' "$log" | sed 's/^/  /' | sort -u
  echo "Other failures (not pixel diffs):"
  grep -E '\[E\]' "$log" | grep -v -f <(grep -oE 'goldens/[^"]+' "$log" | sed -E 's#.*/##; s/_(light|nightCare)_(vi|en)\.png//' | sort -u) | sed 's/^/  /' | head -20
} | tee "$report"
rm -f "$log"
exit $status
