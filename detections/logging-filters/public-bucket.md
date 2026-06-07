# Detection: Cloud Storage Bucket Made Public

| | |
|---|---|
| **MITRE ATT&CK** | [T1530 — Data from Cloud Storage](https://attack.mitre.org/techniques/T1530/) |
| **Audit log** | Admin Activity (always on, free) |
| **Severity** | High (data exposure / exfiltration) |
| **Simulation** | [`scripts/simulate/04-sim-public-bucket.sh`](../../scripts/simulate/04-sim-public-bucket.sh) |

## Why this matters

Granting `allUsers` or `allAuthenticatedUsers` on a bucket exposes its objects to the entire internet. This is one of the most common cloud data-breach causes — accidental or attacker-driven exfiltration staging.

## The signal

- `methodName = storage.setIamPermissions` — a bucket IAM change. Because changing IAM is an admin/config write, Cloud Storage records it in the **Admin Activity** log (always on, free — no setup needed).
- the entry contains a binding for the special members `allUsers` or `allAuthenticatedUsers`.

## Cloud Logging filter (Log Explorer)

```
logName:"cloudaudit.googleapis.com%2Factivity"
protoPayload.methodName="storage.setIamPermissions"
```

This catches every bucket IAM change — then you confirm the public grant by inspecting the entry (see "Reading the filter" for how to tighten it).

## Run it from the CLI

```bash
gcloud logging read \
  'logName:"cloudaudit.googleapis.com%2Factivity"
   protoPayload.methodName="storage.setIamPermissions"' \
  --limit=10 --freshness=24h \
  --format="table(timestamp,
    protoPayload.authenticationInfo.principalEmail,
    resource.labels.bucket_name)"
```

## Key fields

| Field | Meaning |
|---|---|
| `protoPayload.authenticationInfo.principalEmail` | **Who** changed the bucket policy |
| `resource.labels.bucket_name` | **Which** bucket was exposed |
| `protoPayload.methodName` | The IAM-change call (`storage.setIamPermissions`) |
| `protoPayload.requestMetadata.callerIp` | Source IP of the actor |

## 📖 Reading the filter

(See [concepts §2](../../docs/01-concepts.md#2-identity--iam-identity-and-access-management) for `allUsers`):

- `logName:"…activity"` — the **Admin Activity** stream. Bucket IAM changes are config writes, so they land here automatically — no Data Access opt-in required.
- `protoPayload.methodName="storage.setIamPermissions"` — a bucket IAM change.

**Tightening to public-only:** the special members (`allUsers`/`allAuthenticatedUsers`) appear inside the log entry's binding data. Matching on `methodName` alone catches *all* bucket IAM changes (more coverage, some noise); to focus on public grants, expand the matched entry in Log Explorer and confirm the `allUsers` member, or add a `protoPayload.request` member condition once you've inspected your entry's exact shape.

## Tuning notes

- **False positives:** intentionally public buckets (static website hosting, public datasets). Allow-list known-public bucket names.
- **Prevent, don't just detect:** pair with the org policy `storage.publicAccessPrevention` to *block* public buckets — defense-in-depth talking point.
