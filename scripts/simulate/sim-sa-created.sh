#!/usr/bin/env bash
# Simulates: Service Account Created  (MITRE T1136.003)
# Detection:  detections/logging-filters/service-account-created.md
# Safe: creates a disposable test service account. Removed by scripts/teardown.sh.
set -euo pipefail

SA="secmon-test-sa"
PROJECT_ID="$(gcloud config get-value project)"

gcloud iam service-accounts create "$SA" \
  --display-name="SecMon detection test SA" \
  --project="$PROJECT_ID" 2>/dev/null \
  && echo "[+] Created service account: ${SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
  || echo "[=] Service account ${SA} already exists (ok)"

echo "    Triggers T1136.003 — see detections/logging-filters/service-account-created.md"
