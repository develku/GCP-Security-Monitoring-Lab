#!/usr/bin/env bash
# Simulates: IAM primitive role granted  (MITRE T1098.003)
# Detection:  detections/logging-filters/iam-role-granted.md
# Depends on: sim-sa-created.sh (grants editor to the test service account).
# Retries to tolerate service-account creation propagation (IAM is eventually
# consistent — a freshly created SA isn't usable in a binding for a few seconds).
# Safe: revoked by scripts/teardown.sh.
set -euo pipefail

PROJECT_ID="$(gcloud config get-value project)"
SA_EMAIL="secmon-test-sa@${PROJECT_ID}.iam.gserviceaccount.com"

granted=false
for attempt in 1 2 3 4 5 6; do
  if gcloud projects add-iam-policy-binding "$PROJECT_ID" \
       --member="serviceAccount:${SA_EMAIL}" \
       --role="roles/editor" \
       --condition=None >/dev/null 2>&1; then
    granted=true
    break
  fi
  echo "[*] Service account not propagated yet — retrying in 5s (${attempt}/6)…"
  sleep 5
done

if [ "$granted" = true ]; then
  echo "[+] Granted roles/editor to ${SA_EMAIL}"
  echo "    Triggers T1098.003 — see detections/logging-filters/iam-role-granted.md"
else
  echo "[!] Failed after retries. Confirm sim-sa-created.sh ran and the SA exists:" >&2
  echo "    gcloud iam service-accounts list --filter=email:secmon-test-sa" >&2
  exit 1
fi
