#!/usr/bin/env bash
# Deploys Firebase resources to an explicitly named environment. There is no default project.
# Usage: scripts/deploy.sh dev|prod [firebase --only targets] [--force]
set -euo pipefail

env="${1:-}"
only="${2:-firestore,storage,functions,hosting}"
force=false
if [[ "${3:-}" == "--force" && "$#" -eq 3 ]]; then
  # Firebase requires an explicit acknowledgement when enabling a function retry policy.
  # Review the remote/local resource diff before using this option: it also accepts deletions.
  force=true
elif [[ "$#" -gt 2 ]]; then
  echo "Usage: $0 dev|prod [only] [--force]" >&2
  exit 1
fi
case "$env" in
  dev) project="child-life-dev" ;;
  prod)
    project="child-life-ecosystem"
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
deploy_args=(--project "$project" --only "$only")
if $force; then deploy_args+=(--force); fi
# Function updates sometimes fail on transient network errors; a re-run only redeploys what changed.
deployed=false
for attempt in 1 2 3; do
  if firebase deploy "${deploy_args[@]}"; then deployed=true; break; fi
  echo ">>> Deploy attempt $attempt failed; retrying" >&2
done
# "Deploy complete!" is not proof: a new revision can fail its healthcheck (old code keeps
# serving) and a callable can lose its public invoker (HTML 403). The check repairs both and ends
# with one line. It also runs after a failed deploy: the usual failure (Cloud Run CPU quota on a
# big deploy) is exactly what it repairs, after waiting for the quota. VERIFY=0 skips it.
if [[ ",$only," == *",functions"* && "${VERIFY:-1}" != "0" ]]; then
  node "$root/scripts/verify-deploy.mjs" "$env" || exit 1
fi
if ! $deployed; then
  # The check only repairs revisions that failed to start; a deploy that never created one (build
  # error, bad config) still needs a look at the lines above.
  echo ">>> firebase deploy reported errors after 3 attempts. If they were 'Quota exceeded for total allowable CPU' and the line above is ✔ verify, the deploy is complete; otherwise read the errors above." >&2
  exit 1
fi
