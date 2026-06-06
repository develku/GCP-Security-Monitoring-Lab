#!/usr/bin/env bash
# Simulates: Firewall rule opened to the internet  (MITRE T1562.007)
# Detection:  detections/logging-filters/firewall-open-ingress.md
# Prereq: Compute Engine API enabled + a 'default' VPC network.
# Safe: rule allows tcp:22 from 0.0.0.0/0 but no VM is attached. Removed by teardown.sh.
set -euo pipefail

PROJECT_ID="$(gcloud config get-value project)"

gcloud compute firewall-rules create secmon-test-open-ssh \
  --project="$PROJECT_ID" \
  --direction=INGRESS --action=ALLOW --rules=tcp:22 \
  --source-ranges=0.0.0.0/0 --network=default

echo "[!] Created firewall secmon-test-open-ssh — tcp:22 open to 0.0.0.0/0"
echo "    Triggers T1562.007 — see detections/logging-filters/firewall-open-ingress.md"
echo "    Run scripts/teardown.sh after screenshotting."
