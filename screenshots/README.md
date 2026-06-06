# Screenshots — Detection Evidence

Proof that each detection fires when its matching attack runs. Captured per [`docs/03-run-and-capture.md`](../docs/03-run-and-capture.md).

| File | Detection | Attack simulated |
|---|---|---|
| `01-iam-role-granted.png` | IAM role granted (T1098.003) | `sim-iam-role-granted.sh` |
| `02-sa-key-created.png` | SA key created (T1098.001) | `sim-sa-key-created.sh` |
| `03-public-bucket.png` | Bucket made public (T1530) | `sim-public-bucket.sh` |

> Each shows the Log Explorer query + the matching log entry. Account identifiers are scrubbed.
