#!/usr/bin/env bash
# Simulates: Service account key created  (MITRE T1098.001)
# Detection:  detections/logging-filters/sa-key-created.md
# Depends on: sim-sa-created.sh.
# Safe: key is written to keys/ (gitignored) and deleted by scripts/teardown.sh.
set -euo pipefail

PROJECT_ID="$(gcloud config get-value project)"
SA_EMAIL="secmon-test-sa@${PROJECT_ID}.iam.gserviceaccount.com"

mkdir -p keys
gcloud iam service-accounts keys create "keys/secmon-test-sa-key.json" \
  --iam-account="$SA_EMAIL"

echo "[+] Created key for ${SA_EMAIL} -> keys/secmon-test-sa-key.json (gitignored)"
echo "[!] This is a live credential. teardown.sh deletes it; never commit keys/."
echo "    Triggers T1098.001 — see detections/logging-filters/sa-key-created.md"
