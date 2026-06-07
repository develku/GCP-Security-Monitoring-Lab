#!/usr/bin/env bash
# Simulates: Cloud Storage bucket made public  (MITRE T1530)
# Detection:  detections/logging-filters/public-bucket.md
# Detection uses the always-on Admin Activity log (bucket-IAM changes are config
# writes), so no logging setup is required.
# Safe: empty test bucket, no data. Removed by scripts/teardown.sh.
set -euo pipefail

PROJECT_ID="$(gcloud config get-value project)"
BUCKET="secmon-test-bucket-${PROJECT_ID}"

gcloud storage buckets create "gs://${BUCKET}" --location=US --project="$PROJECT_ID" 2>/dev/null \
  && echo "[+] Created bucket gs://${BUCKET}" \
  || echo "[=] Bucket gs://${BUCKET} already exists (ok)"

gcloud storage buckets add-iam-policy-binding "gs://${BUCKET}" \
  --member=allUsers --role=roles/storage.objectViewer >/dev/null

echo "[!] gs://${BUCKET} is now PUBLIC (allUsers:objectViewer). Empty bucket, no data."
echo "    Triggers T1530 — see detections/logging-filters/public-bucket.md"
echo "    Run scripts/teardown.sh promptly after screenshotting."
