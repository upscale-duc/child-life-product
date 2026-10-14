#!/usr/bin/env bash
# Deploys Firebase resources to an explicitly named environment. There is no default project.
# Usage: scripts/deploy.sh dev|prod [firebase --only targets, e.g. "firestore:rules,storage,functions"]
set -euo pipefail

env="${1:-}"
only="${2:-firestore,storage,functions,hosting}"
case "$env" in
  dev) project="child-life-dev" ;;
  prod)
    project="child-life-prod"
    if [[ "${CHILD_LIFE_PROD_APPROVED:-}" != "yes" ]]; then
      echo "Production deploys need owner approval: set CHILD_LIFE_PROD_APPROVED=yes for this run." >&2
      exit 1
    fi
    ;;
  *) echo "Usage: $0 dev|prod [only]" >&2; exit 1 ;;
esac

root="$(cd "$(dirname "$0")/.." && pwd)"
echo ">>> Deploying [$only] to $env ($project)"
# Build only what is deployed: plain "hosting" is every site; "hosting:<target>" one of them.
all_hosting=false
[[ ",$only," == *",hosting,"* ]] && all_hosting=true
if $all_hosting || [[ "$only" == *hosting:landing* || "$only" == *hosting:admin* ]]; then
  pnpm --dir "$root" --filter child-life-landing --filter child-life-portal run "build:$env"
fi
# Video kỷ niệm preview page (D-068): the renderer's compositions with @remotion/player.
if $all_hosting || [[ "$only" == *hosting:player* ]]; then
  pnpm --dir "$root" --filter child-life-renderer run build:player
fi
cd "$root"
# Function updates sometimes fail on transient network errors; a re-run only redeploys what changed.
for attempt in 1 2 3; do
  if firebase deploy --project "$project" --only "$only"; then exit 0; fi
  echo ">>> Deploy attempt $attempt failed; retrying" >&2
done
exit 1
