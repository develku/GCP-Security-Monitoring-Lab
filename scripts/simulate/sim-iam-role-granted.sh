#!/usr/bin/env bash
# Simulates: IAM primitive role granted  (MITRE T1098.003)
# Detection:  detections/logging-filters/iam-role-granted.md
# Depends on: sim-sa-created.sh (grants editor to the test service account).
# Safe: revoked by scripts/teardown.sh.
set -euo pipefail

PROJECT_ID="$(gcloud config get-value project)"
SA_EMAIL="secmon-test-sa@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/editor" \
  --condition=None >/dev/null

echo "[+] Granted roles/editor to ${SA_EMAIL}"
echo "    Triggers T1098.003 — see detections/logging-filters/iam-role-granted.md"
