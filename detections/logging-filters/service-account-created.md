# Detection: Service Account Created

| | |
|---|---|
| **MITRE ATT&CK** | [T1136.003 — Create Account: Cloud Account](https://attack.mitre.org/techniques/T1136/003/) |
| **Audit log** | Admin Activity (always on, free) |
| **Severity** | Medium (persistence — attacker-controlled identity) |
| **Simulation** | [`scripts/simulate/sim-sa-created.sh`](../../scripts/simulate/sim-sa-created.sh) |

## Why this matters

A new service account is an identity an attacker can grant roles to and mint keys for — a **persistence** mechanism that survives password resets and looks like ordinary infrastructure. On its own it's medium severity; chained with a role grant and a key creation, it's a full persistence kit. The power of correlation: SA created → role granted → key created, all by the same `principalEmail` in a short window, is a high-confidence incident.

## The signal

- `methodName = google.iam.admin.v1.CreateServiceAccount`

## Cloud Logging filter (Log Explorer)

```
logName:"cloudaudit.googleapis.com%2Factivity"
protoPayload.methodName="google.iam.admin.v1.CreateServiceAccount"
```

## Run it from the CLI

```bash
gcloud logging read \
  'logName:"cloudaudit.googleapis.com%2Factivity"
   protoPayload.methodName="google.iam.admin.v1.CreateServiceAccount"' \
  --limit=10 --freshness=24h \
  --format="table(timestamp,
    protoPayload.authenticationInfo.principalEmail,
    protoPayload.response.email,
    protoPayload.requestMetadata.callerIp)"
```

## Key fields

| Field | Meaning |
|---|---|
| `protoPayload.authenticationInfo.principalEmail` | **Who** created the service account |
| `protoPayload.response.email` | The **new** service account's identity |
| `protoPayload.requestMetadata.callerIp` | Source IP of the actor |

## 📖 Reading the filter

Single condition (see [concepts §3](../../docs/01-concepts.md#3-service-accounts--keys)):

- `logName:"…activity"` — Admin Activity stream.
- `protoPayload.methodName="google.iam.admin.v1.CreateServiceAccount"` — a new service-account identity was created.

Low severity on its own — its real value is **correlation** (see the persistence-chain link in Tuning notes): SA created → role granted → key created, same actor, short window.

## Tuning notes

- **False positives:** Terraform/CI provisioning legitimately creates service accounts. Allow-list automation `principalEmail`s; alert on human-created (`user:`) ones.
- **Correlate** with [`iam-role-granted`](iam-role-granted.md) and [`sa-key-created`](sa-key-created.md) — the three together on one actor in a short window is the persistence chain worth paging on.
