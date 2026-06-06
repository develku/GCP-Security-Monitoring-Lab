# Detection: Cloud Storage Bucket Made Public

| | |
|---|---|
| **MITRE ATT&CK** | [T1530 — Data from Cloud Storage](https://attack.mitre.org/techniques/T1530/) |
| **Audit log** | **Data Access** (⚠️ opt-in — see prerequisite) |
| **Severity** | High (data exposure / exfiltration) |
| **Simulation** | [`scripts/simulate/sim-public-bucket.sh`](../../scripts/simulate/sim-public-bucket.sh) |

## ⚠️ Prerequisite — enable Data Access logging for Storage

Unlike the other detections, Cloud Storage IAM changes are recorded in **Data Access** audit logs, which are **off by default**. Enable `ADMIN_WRITE` for Cloud Storage (low volume — this is config activity, not object reads):

```bash
# Add to your audit config (see docs/02-enable-audit-logging.md):
#   service: storage.googleapis.com
#   auditLogConfigs: { logType: ADMIN_WRITE }
```

> Do **not** enable `DATA_READ`/`DATA_WRITE` for Storage in this lab — those log every object access and can get expensive. `ADMIN_WRITE` captures IAM/config changes only.

## Why this matters

Granting `allUsers` or `allAuthenticatedUsers` on a bucket exposes its objects to the entire internet. This is one of the most common cloud data-breach causes — accidental or attacker-driven exfiltration staging.

## The signal

- `methodName = storage.setIamPermissions`
- a binding added for the special members `allUsers` or `allAuthenticatedUsers`

## Cloud Logging filter (Log Explorer)

```
logName:"cloudaudit.googleapis.com%2Fdata_access"
protoPayload.methodName="storage.setIamPermissions"
(protoPayload.serviceData.policyDelta.bindingDeltas.member="allUsers" OR
 protoPayload.serviceData.policyDelta.bindingDeltas.member="allAuthenticatedUsers")
protoPayload.serviceData.policyDelta.bindingDeltas.action="ADD"
```

## Run it from the CLI

```bash
gcloud logging read \
  'logName:"cloudaudit.googleapis.com%2Fdata_access"
   protoPayload.methodName="storage.setIamPermissions"
   (protoPayload.serviceData.policyDelta.bindingDeltas.member="allUsers" OR
    protoPayload.serviceData.policyDelta.bindingDeltas.member="allAuthenticatedUsers")' \
  --limit=10 --freshness=24h \
  --format="table(timestamp,
    protoPayload.authenticationInfo.principalEmail,
    resource.labels.bucket_name,
    protoPayload.serviceData.policyDelta.bindingDeltas.member)"
```

## Key fields

| Field | Meaning |
|---|---|
| `protoPayload.authenticationInfo.principalEmail` | **Who** changed the bucket policy |
| `resource.labels.bucket_name` | **Which** bucket was exposed |
| `protoPayload.serviceData.policyDelta.bindingDeltas.member` | The public principal that was granted |
| `protoPayload.serviceData.policyDelta.bindingDeltas.role` | What access level (e.g. `roles/storage.objectViewer`) |

## 📖 Reading the filter

(See [concepts §2](../../docs/01-concepts.md#2-identity--iam-identity-and-access-management) for `allUsers`):

- `logName:"…data_access"` — the **Data Access** stream, *not* Admin Activity. This is why you enabled it in doc 02; without that, this detection sees nothing.
- `protoPayload.methodName="storage.setIamPermissions"` — a bucket IAM change.
- `member="allUsers" OR "allAuthenticatedUsers"` — the two special members that mean "public".
- `action="ADD"` — access was *granted* (not revoked).

## Tuning notes

- **False positives:** intentionally public buckets (static website hosting, public datasets). Allow-list known-public bucket names.
- **Prevent, don't just detect:** pair with the org policy `storage.publicAccessPrevention` to *block* public buckets — defense-in-depth talking point.
