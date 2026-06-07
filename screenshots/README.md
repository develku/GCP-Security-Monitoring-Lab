# Screenshots — Detection Evidence

Proof that each detection fires when its matching attack runs. Captured per [`docs/03-run-and-capture.md`](../docs/03-run-and-capture.md).

| File | Detection | Attack simulated |
|---|---|---|
| `01-iam-role-granted.png` | IAM role granted (T1098.003) | `02-sim-iam-role-granted.sh` |
| `02-sa-key-created.png` | SA key created (T1098.001) | `03-sim-sa-key-created.sh` |
| `03-public-bucket.png` | Bucket made public (T1530) | `04-sim-public-bucket.sh` |

> Each shows the Log Explorer query + the matching log entry. Account identifiers are scrubbed.

## Alerting evidence (docs/04)

| File | Shows |
|---|---|
| `04-create-log-alert-menu.png` | Where to create the alert (Logs Explorer → Actions → Create log alert) |
| `04-alert-fired.png` | The alert email — proof the policy fired and notified |
| `04-alert-matched-log.png` | The matched log entry that triggered the alert |

## SQL correlation evidence (docs/05)

| File | Shows |
|---|---|
| `05-bigquery-sanity.png` | Sink working — recent admin-activity query returning the chain events in BigQuery |
| `05-correlation-chain.png` | The persistence-chain correlation query catching the actor (`distinct_steps: 3`, `span_minutes: 1`) |
