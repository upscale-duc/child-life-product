#!/usr/bin/env bash
# Deploys the Video kỷ niệm renderer (D-068, apps/renderer) and what feeds it: the Cloud Run service
# `keepsake-renderer` (private), the Cloud Tasks queue `keepsake-render`, two service accounts and
# their IAM. Creates billable resources: the first run on dev needs the owner's go-ahead, prod needs
# CHILD_LIFE_PROD_APPROVED=yes. Re-running only updates. Then deploy functions so they pick up
# KEEPSAKE_RENDERER_URL (scripts/deploy.sh <env> functions).
# Usage: scripts/deploy-renderer.sh dev|prod
set -euo pipefail

env="${1:-}"
case "$env" in
  dev) project="child-life-dev" ;;
  prod)
    project="child-life-prod"
    if [[ "${CHILD_LIFE_PROD_APPROVED:-}" != "yes" ]]; then
      echo "Production needs owner approval: set CHILD_LIFE_PROD_APPROVED=yes for this run." >&2
      exit 1
    fi
    ;;
  *) echo "Usage: $0 dev|prod" >&2; exit 1 ;;
esac
region="asia-southeast1"
root="$(cd "$(dirname "$0")/.." && pwd)"
bucket="$project.firebasestorage.app"
number="$(gcloud projects describe "$project" --format='value(projectNumber)')"
renderer_sa="keepsake-renderer@$project.iam.gserviceaccount.com"
tasks_sa="keepsake-tasks@$project.iam.gserviceaccount.com"
functions_sa="$number-compute@developer.gserviceaccount.com"
g() { gcloud --project "$project" --quiet "$@"; }

echo ">>> APIs"
g services enable run.googleapis.com cloudtasks.googleapis.com artifactregistry.googleapis.com cloudbuild.googleapis.com

echo ">>> Service accounts"
g iam service-accounts describe "$renderer_sa" >/dev/null 2>&1 ||
  g iam service-accounts create keepsake-renderer --display-name "Video kỷ niệm renderer"
g iam service-accounts describe "$tasks_sa" >/dev/null 2>&1 ||
  g iam service-accounts create keepsake-tasks --display-name "Video kỷ niệm tasks"
# The renderer reads jobs and photos, writes outputs and job state; nothing else.
g projects add-iam-policy-binding "$project" --member "serviceAccount:$renderer_sa" --role roles/datastore.user --condition=None >/dev/null
gcloud storage buckets add-iam-policy-binding "gs://$bucket" --member "serviceAccount:$renderer_sa" --role roles/storage.objectAdmin >/dev/null
# Functions enqueue tasks that carry the tasks account's OIDC token.
g projects add-iam-policy-binding "$project" --member "serviceAccount:$functions_sa" --role roles/cloudtasks.enqueuer --condition=None >/dev/null
g iam service-accounts add-iam-policy-binding "$tasks_sa" --member "serviceAccount:$functions_sa" --role roles/iam.serviceAccountUser >/dev/null

echo ">>> Image"
pnpm --dir "$root" --filter child-life-renderer run build
g artifacts repositories describe keepsake --location "$region" >/dev/null 2>&1 ||
  g artifacts repositories create keepsake --repository-format docker --location "$region"
image="$region-docker.pkg.dev/$project/keepsake/renderer:$(git -C "$root" rev-parse --short HEAD)-$(date +%s)"
g builds submit "$root/apps/renderer" --tag "$image" --region "$region"

echo ">>> Cloud Run"
g run deploy keepsake-renderer --image "$image" --region "$region" \
  --no-allow-unauthenticated --service-account "$renderer_sa" \
  --concurrency 1 --max-instances 3 --min-instances 0 --cpu 4 --memory 8Gi --timeout 900 \
  --execution-environment gen2 --cpu-boost --set-env-vars "STORAGE_BUCKET=$bucket"
g run services add-iam-policy-binding keepsake-renderer --region "$region" \
  --member "serviceAccount:$tasks_sa" --role roles/run.invoker >/dev/null
url="$(g run services describe keepsake-renderer --region "$region" --format 'value(status.url)')"

echo ">>> Cloud Tasks"
if g tasks queues describe keepsake-render --location "$region" >/dev/null 2>&1; then
  g tasks queues update keepsake-render --location "$region" --max-attempts 3 \
    --min-backoff 30s --max-backoff 300s --max-concurrent-dispatches 3 --max-dispatches-per-second 1
else
  g tasks queues create keepsake-render --location "$region" --max-attempts 3 \
    --min-backoff 30s --max-backoff 300s --max-concurrent-dispatches 3 --max-dispatches-per-second 1
fi

echo "KEEPSAKE_RENDERER_URL=$url" > "$root/firebase/functions/.env.$project"
echo ">>> Renderer at $url. Now: scripts/deploy.sh $env functions"
