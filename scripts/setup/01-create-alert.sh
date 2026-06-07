#!/usr/bin/env bash
# Creates an email notification channel + a log-based alert policy for the
# IAM-role-granted detection (T1098.003), so the detection fires a real alert.
#
# Requires the alpha/beta gcloud components:
#   gcloud components install beta alpha
# Usage:
#   ALERT_EMAIL="you@example.com" ./scripts/setup/01-create-alert.sh
set -euo pipefail

: "${ALERT_EMAIL:?Set ALERT_EMAIL to the address that should receive alerts}"
PROJECT_ID="$(gcloud config get-value project)"

echo "[*] Creating email notification channel for ${ALERT_EMAIL}…"
CHANNEL_ID=$(gcloud beta monitoring channels create \
  --display-name="SecMon Lab Email" \
  --type=email \
  --channel-labels=email_address="${ALERT_EMAIL}" \
  --format="value(name)")
echo "    channel: ${CHANNEL_ID}"

echo "[*] Applying log-based alert policy from alerting/iam-role-granted-alert.yaml…"
TMP="$(mktemp -d)/policy.yaml"
trap 'rm -rf "$(dirname "$TMP")"' EXIT
sed "s|CHANNEL_ID|${CHANNEL_ID}|" alerting/iam-role-granted-alert.yaml > "$TMP"
gcloud alpha monitoring policies create --policy-from-file="$TMP"

echo "[+] Alert policy created in ${PROJECT_ID}."
echo "    Trigger it: ./scripts/simulate/01-sim-sa-created.sh && ./scripts/simulate/02-sim-iam-role-granted.sh"
echo "    The alert fires and emails ${ALERT_EMAIL} within ~1-2 minutes."
