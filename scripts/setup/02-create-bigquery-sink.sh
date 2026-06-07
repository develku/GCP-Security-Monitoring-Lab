#!/usr/bin/env bash
# Creates a BigQuery dataset + a Cloud Logging sink that routes Admin Activity
# audit logs into it, so detections can be written as SQL (see docs/05-bigquery-sql.md).
# Free-tier friendly: lab log volume is tiny (BigQuery: 1 TB query + 10 GB storage/mo free).
# Uses the bundled `bq` + `gcloud` — no alpha/beta components needed.
set -euo pipefail

PROJECT_ID="$(gcloud config get-value project)"
DATASET="secmon_logs"
SINK="secmon-bq-sink"

echo "[*] Enabling BigQuery API…"
gcloud services enable bigquery.googleapis.com >/dev/null

echo "[*] Creating BigQuery dataset ${DATASET}…"
bq --location=US mk --dataset "${PROJECT_ID}:${DATASET}" 2>/dev/null \
  && echo "    created" || echo "    (already exists, ok)"

echo "[*] Creating logging sink ${SINK} → BigQuery (partitioned tables)…"
gcloud logging sinks create "${SINK}" \
  "bigquery.googleapis.com/projects/${PROJECT_ID}/datasets/${DATASET}" \
  --log-filter='logName:"cloudaudit.googleapis.com%2Factivity"' \
  --use-partitioned-tables 2>/dev/null \
  && echo "    created" || echo "    (already exists, ok)"

echo "[*] Granting the sink's writer identity permission to write to BigQuery…"
SINK_SA="$(gcloud logging sinks describe "${SINK}" --format='value(writerIdentity)')"
# The sink's writer identity is a Google-managed service agent that is eventually
# consistent — it may not exist yet immediately after sink creation. Retry.
granted=false
for attempt in 1 2 3 4 5 6; do
  if gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
       --member="${SINK_SA}" \
       --role="roles/bigquery.dataEditor" \
       --condition=None >/dev/null 2>&1; then
    granted=true; break
  fi
  echo "    writer identity not provisioned yet — retrying in 5s (${attempt}/6)…"
  sleep 5
done
[ "$granted" = true ] || { echo "[!] Grant failed after retries. Just re-run this script." >&2; exit 1; }

echo "[+] Done. New Admin Activity logs now flow into:"
echo "    ${PROJECT_ID}.${DATASET}.cloudaudit_googleapis_com_activity"
echo "    The sink captures from NOW forward — run some sims, wait a few minutes,"
echo "    then run the queries in detections/bigquery-sql/ (see docs/05-bigquery-sql.md)."
