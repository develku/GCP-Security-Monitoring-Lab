#!/usr/bin/env bash
# Simulates: Audit logging configuration changed  (MITRE T1562.008)
# Detection:  detections/logging-filters/audit-config-changed.md
# This is the trickiest sim: audit-config changes ride on SetIamPolicy and must be
# made by editing the project IAM policy. We ADD then REMOVE a harmless ADMIN_READ
# config so the detection fires on auditConfigDeltas WITHOUT actually disabling any
# real protection. Requires python3 (bundled on macOS / Homebrew).
set -euo pipefail

PROJECT_ID="$(gcloud config get-value project)"
TMP="$(mktemp -d)/policy.json"
SVC="cloudresourcemanager.googleapis.com"

cleanup() { rm -rf "$(dirname "$TMP")"; }
trap cleanup EXIT

echo "[*] Fetching current IAM policy…"
gcloud projects get-iam-policy "$PROJECT_ID" --format=json > "$TMP"

echo "[*] Adding a temporary ADMIN_READ audit config for ${SVC} (generates an ADD delta)…"
python3 - "$TMP" "$SVC" <<'PY'
import json, sys
path, svc = sys.argv[1], sys.argv[2]
p = json.load(open(path))
p.setdefault("auditConfigs", [])
if not any(c.get("service") == svc for c in p["auditConfigs"]):
    p["auditConfigs"].append({"service": svc,
                              "auditLogConfigs": [{"logType": "ADMIN_READ"}]})
json.dump(p, open(path, "w"))
PY
gcloud projects set-iam-policy "$PROJECT_ID" "$TMP" >/dev/null

echo "[*] Removing it again (generates a REMOVE delta — the dangerous-looking case)…"
gcloud projects get-iam-policy "$PROJECT_ID" --format=json > "$TMP"
python3 - "$TMP" "$SVC" <<'PY'
import json, sys
path, svc = sys.argv[1], sys.argv[2]
p = json.load(open(path))
p["auditConfigs"] = [c for c in p.get("auditConfigs", []) if c.get("service") != svc]
json.dump(p, open(path, "w"))
PY
gcloud projects set-iam-policy "$PROJECT_ID" "$TMP" >/dev/null

echo "[+] Generated ADD + REMOVE auditConfigDeltas. No real logging was disabled."
echo "    Triggers T1562.008 — see detections/logging-filters/audit-config-changed.md"
