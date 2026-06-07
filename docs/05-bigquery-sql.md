# 05 — BigQuery SQL detections (catch the _chain_)

Your 6 filters each catch one event. This doc adds the detection a filter **can't** express: a **correlation** — multiple events by the same actor in sequence. ~15 minutes.

> 📖 **Study — why this needs SQL:** a Log Explorer filter matches _one_ log entry. The persistence chain (`create SA → grant role → mint key`) is _three_ events by one actor in a short window. To detect the **sequence** you must correlate events — `GROUP BY actor` + `HAVING` over a time window. That's SQL's job, not a filter's. This is the single most "senior" detection in the lab. ([concepts §6](01-concepts.md#6-detection-engineering--the-loop))

---

## Step 1 — Route logs into BigQuery

A **log sink** continuously copies matching logs from Cloud Logging into a BigQuery dataset you can query with SQL.

```bash
cd /path/to/GCP-Security-Monitoring-Lab
./scripts/setup/02-create-bigquery-sink.sh
```

**This does:** enables BigQuery, makes the `secmon_logs` dataset, creates the sink (filtering to Admin Activity logs), and grants the sink permission to write. Free-tier friendly — lab volume is tiny.

> ⚠️ **The sink captures from _now_ forward** — it does not backfill old logs. So you must generate activity _after_ creating it (Step 2).

## Step 2 — Generate activity (so there's data to query)

Run the persistence chain — these become the rows your correlation query will catch:

```bash
./scripts/simulate/01-sim-sa-created.sh
./scripts/simulate/02-sim-iam-role-granted.sh
./scripts/simulate/03-sim-sa-key-created.sh
```

**Wait ~2–5 minutes** for the sink to deliver the logs into BigQuery.

## Step 3 — Run the queries

Open the BigQuery console: <https://console.cloud.google.com/bigquery?project=gcp-secmon-lab-kud01>

**(a) Sanity check** — paste [`detections/bigquery-sql/recent-admin-activity.sql`](../detections/bigquery-sql/recent-admin-activity.sql) and **Run**. You should see your recent `SetIamPolicy`, `CreateServiceAccount`, `CreateServiceAccountKey` rows. _(If empty, the logs haven't landed yet — wait and retry.)_

**(b) The correlation detection** — paste [`detections/bigquery-sql/correlation-persistence-chain.sql`](../detections/bigquery-sql/correlation-persistence-chain.sql) and **Run**. It returns **one row per actor** who did all three chain steps within 30 minutes — i.e. it caught the _sequence_, not just the individual events.

> CLI alternative: `bq query --use_legacy_sql=false < detections/bigquery-sql/correlation-persistence-chain.sql`

**Screenshot** the correlation query + its result → save as `screenshots/05-correlation-chain.png`.

### Evidence

Sanity query — the sink is live and the chain events landed in BigQuery (`actor` scrubbed):

![BigQuery: recent-admin-activity query returning the chain events](../screenshots/05-bigquery-sanity.png)

The correlation detection — **one actor, all 3 chain stages inside the window** (`distinct_steps: 3`, `span_minutes: 1`). No single filter can produce this row:

![BigQuery: persistence-chain correlation query returning the offending actor](../screenshots/05-correlation-chain.png)

---

## Step 4 — Clean up (when fully done)

The sims' resources are removed by `./scripts/teardown.sh`. To remove the BigQuery infrastructure itself:

```bash
gcloud logging sinks delete secmon-bq-sink --quiet
bq rm -r -f --dataset gcp-secmon-lab-kud01:secmon_logs
```

**Expected output** — the `[-]` lines confirm each removal:

```
Tearing down test resources in PROJECT_ID…
  [-] editor binding for test SA
  [-] service account secmon-test-sa@PROJECT_ID.iam.gserviceaccount.com
  [-] keys/secmon-test-sa-key.json
Done.
```

> **Nuclear option:** to delete *everything* — the whole project — run `gcloud projects delete PROJECT_ID` (recoverable for ~30 days).

---

## ✅ Done — checklist

- [x] Sink created; logs flowing into `secmon_logs`
- [x] Chain sims run → rows present in BigQuery
- [x] Correlation query returns the actor → `screenshots/05-correlation-chain.png`

With this, the GCP lab demonstrates the full range: **single-event filters → live alerting → multi-event correlation.** That progression — from "match a thing" to "catch a sequence" — is exactly the detection-engineering maturity curve.
