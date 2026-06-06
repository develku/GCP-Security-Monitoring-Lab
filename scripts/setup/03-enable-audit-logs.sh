#!/usr/bin/env bash
# Enables Data Access (ADMIN_WRITE) audit logging for Cloud Storage so the
# public-bucket detection (T1530) can fire. All Admin Activity logging — which
# the other 5 detections rely on — is always on and needs no configuration.
# Requires python3 (bundled on macOS / Homebrew).
set -euo pipefail

PROJECT_ID="$(gcloud config get-value project)"
TMP="$(mktemp -d)/policy.json"
trap 'rm -rf "$(dirname "$TMP")"' EXIT

echo "[*] Fetching current IAM policy for ${PROJECT_ID}…"
gcloud projects get-iam-policy "$PROJECT_ID" --format=json > "$TMP"

echo "[*] Adding ADMIN_WRITE Data Access logging for storage.googleapis.com…"
python3 - "$TMP" <<'PY'
import json, sys
path = sys.argv[1]
p = json.load(open(path))
acs = p.setdefault("auditConfigs", [])
svc = "storage.googleapis.com"
cfg = next((c for c in acs if c.get("service") == svc), None)
if cfg is None:
    cfg = {"service": svc, "auditLogConfigs": []}
    acs.append(cfg)
types = {l.get("logType") for l in cfg["auditLogConfigs"]}
if "ADMIN_WRITE" not in types:
    cfg["auditLogConfigs"].append({"logType": "ADMIN_WRITE"})
json.dump(p, open(path, "w"))
PY
gcloud projects set-iam-policy "$PROJECT_ID" "$TMP" >/dev/null

echo "[+] Done. Storage IAM/config changes are now logged (Data Access, ADMIN_WRITE)."
echo "    DATA_READ/DATA_WRITE deliberately NOT enabled (would log every object access — costly)."
