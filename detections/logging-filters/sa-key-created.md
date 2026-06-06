# Detection: Service Account Key Created

| | |
|---|---|
| **MITRE ATT&CK** | [T1098.001 — Account Manipulation: Additional Cloud Credentials](https://attack.mitre.org/techniques/T1098/001/) |
| **Audit log** | Admin Activity (always on, free) |
| **Severity** | High (credential theft / persistence) |
| **Simulation** | [`scripts/simulate/sim-sa-key-created.sh`](../../scripts/simulate/sim-sa-key-created.sh) |

## Why this matters

A service account **user-managed key** is a long-lived, downloadable credential (a JSON private key) that authenticates as the service account from anywhere — no MFA, no expiry by default. Attackers create one to **exfiltrate a portable credential** they can use outside GCP, surviving password resets and session revocation. In well-run orgs, user-managed keys are rare (workload identity is preferred), so creation is a strong signal.

## The signal

The IAM API records a distinct method when a key is minted. You'll match on that `methodName` and pull out who did it and which service account was targeted.

## Cloud Logging filter (Log Explorer)

```
logName:"cloudaudit.googleapis.com%2Factivity"
protoPayload.methodName="google.iam.admin.v1.CreateServiceAccountKey"
```

A deliberately tight two-liner: key creation is rare and uniformly suspicious, so we match every occurrence and triage in review rather than pre-filtering. To suppress a known automation account, add a negation line:

```
protoPayload.authenticationInfo.principalEmail!="ci-deployer@PROJECT_ID.iam.gserviceaccount.com"
```

## Run it from the CLI

```bash
gcloud logging read \
  'logName:"cloudaudit.googleapis.com%2Factivity"
   protoPayload.methodName="google.iam.admin.v1.CreateServiceAccountKey"' \
  --limit=10 --freshness=24h \
  --format="table(timestamp,
    protoPayload.authenticationInfo.principalEmail,
    protoPayload.request.name,
    protoPayload.requestMetadata.callerIp)"
```

## Key fields

| Field | Meaning |
|---|---|
| `protoPayload.authenticationInfo.principalEmail` | **Who** created the key |
| `protoPayload.methodName` | The API call that minted the key |
| `protoPayload.request.name` / `protoPayload.resourceName` | **Which** service account was targeted |
| `protoPayload.requestMetadata.callerIp` | Source IP of the actor |

## 📖 Reading the filter

Two lines, deliberately (see [concepts §3](../../docs/01-concepts.md#3-service-accounts--keys)):

- `logName:"…activity"` — the **Admin Activity** stream.
- `protoPayload.methodName="google.iam.admin.v1.CreateServiceAccountKey"` — the exact call that mints a downloadable key.

No extra conditions, because key creation is rare and uniformly suspicious — here, *more* coverage is the right call. The optional negation line only removes a known CI/automation account.

## Tuning notes

- **False positives:** CI/CD or Terraform provisioning that legitimately rotates keys. Allow-list known automation `principalEmail`s.
- **Escalate:** key created on a *highly privileged* service account (one holding `roles/owner`/`roles/editor`) is critical.
- **Pair with:** [`iam-role-granted`](iam-role-granted.md) — key creation *after* a fresh role grant is a classic escalation→persistence chain.
