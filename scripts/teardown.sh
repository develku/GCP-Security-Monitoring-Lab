#!/usr/bin/env bash
# Removes every resource created by the sim scripts. Idempotent — safe to re-run.
# Does NOT delete the project itself (see the final hint).
set -uo pipefail

PROJECT_ID="$(gcloud config get-value project)"
SA_EMAIL="secmon-test-sa@${PROJECT_ID}.iam.gserviceaccount.com"
BUCKET="secmon-test-bucket-${PROJECT_ID}"

echo "Tearing down test resources in ${PROJECT_ID}…"

gcloud compute firewall-rules delete secmon-test-open-ssh --quiet 2>/dev/null \
  && echo "  [-] firewall secmon-test-open-ssh" || true

gcloud storage rm --recursive "gs://${BUCKET}" --quiet 2>/dev/null \
  && echo "  [-] bucket gs://${BUCKET}" || true

gcloud projects remove-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" --role="roles/editor" \
  --condition=None --quiet 2>/dev/null \
  && echo "  [-] editor binding for test SA" || true

gcloud iam service-accounts delete "$SA_EMAIL" --quiet 2>/dev/null \
  && echo "  [-] service account ${SA_EMAIL}" || true

rm -f keys/secmon-test-sa-key.json && echo "  [-] keys/secmon-test-sa-key.json" || true

echo "Done."
echo "To remove EVERYTHING (the whole lab project): gcloud projects delete ${PROJECT_ID}"
