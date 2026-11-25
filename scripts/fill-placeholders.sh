#!/bin/bash
# Fills the lab placeholders with your real values. Run once, on the jumpbox,
# from the repo root:  bash scripts/fill-placeholders.sh <github-user> <first-image-tag>
set -e
GITHUB_USER=${1:?usage: bash scripts/fill-placeholders.sh <github-user> <first-image-tag>}
IMAGE_TAG=${2:?usage: bash scripts/fill-placeholders.sh <github-user> <first-image-tag>}
: "${ECR_REPO:?ECR_REPO is not set. Log in again so /etc/profile.d/lab.sh is loaded}"

helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets >/dev/null 2>&1 || true
helm repo update sealed-secrets >/dev/null
SS_CHART=$(helm search repo sealed-secrets/sealed-secrets -o json | jq -r '.[0].version')

echo "GitHub user        : $GITHUB_USER"
echo "ECR repository     : $ECR_REPO"
echo "First image tag    : $IMAGE_TAG"
echo "Sealed Secrets chart: $SS_CHART"

FILES=$(grep -rl "__[A-Z_]*__" app gitops)
sed -i \
  -e "s#__GITHUB_USER__#$GITHUB_USER#g" \
  -e "s#__ECR_REPO__#$ECR_REPO#g" \
  -e "s#__IMAGE_TAG__#$IMAGE_TAG#g" \
  -e "s#__SS_CHART__#$SS_CHART#g" \
  $FILES
echo
echo "Updated files:"
echo "$FILES"
echo
if grep -rn "__[A-Z_]*__" app gitops; then
  echo "Some placeholders are left. Check the lines above."
  exit 1
fi
echo "All placeholders filled."
