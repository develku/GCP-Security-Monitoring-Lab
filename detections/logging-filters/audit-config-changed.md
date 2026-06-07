# Detection: Audit Logging Configuration Changed

| | |
|---|---|
| **MITRE ATT&CK** | [T1562.008 — Impair Defenses: Disable or Modify Cloud Logs](https://attack.mitre.org/techniques/T1562/008/) |
| **Audit log** | Admin Activity (always on, free) |
| **Severity** | Critical (defense evasion — attacker blinding the SOC) |
| **Simulation** | [`scripts/simulate/06-sim-audit-config-changed.sh`](../../scripts/simulate/06-sim-audit-config-changed.sh) |

## Why this matters

Disabling or narrowing audit logging is a classic **defense-evasion** move — an attacker turns off the very telemetry that would catch their next action. Critically, **changes to the audit config are themselves recorded in Admin Activity** (which can't be disabled), so the act of tampering leaves a trace even as the attacker tries to go dark. This is one of the highest-priority rules in any SOC.

## The signal

Audit config changes ride on a `SetIamPolicy` call, and GCP records them as structured **`auditConfigDeltas`** in the policy delta. A `REMOVE` action means logging was turned off for a service/type.

## Cloud Logging filter (Log Explorer)

```
logName:"cloudaudit.googleapis.com%2Factivity"
protoPayload.methodName="SetIamPolicy"
protoPayload.serviceData.policyDelta.auditConfigDeltas:*
```

To focus on *disabling* specifically, add:

```
protoPayload.serviceData.policyDelta.auditConfigDeltas.action="REMOVE"
```

## Run it from the CLI

```bash
gcloud logging read \
  'logName:"cloudaudit.googleapis.com%2Factivity"
   protoPayload.methodName="SetIamPolicy"
   protoPayload.serviceData.policyDelta.auditConfigDeltas:*' \
  --limit=10 --freshness=24h \
  --format="table(timestamp,
    protoPayload.authenticationInfo.principalEmail,
    protoPayload.serviceData.policyDelta.auditConfigDeltas.action,
    protoPayload.serviceData.policyDelta.auditConfigDeltas.service)"
```

## Key fields

| Field | Meaning |
|---|---|
| `protoPayload.authenticationInfo.principalEmail` | **Who** changed the audit config |
| `protoPayload.serviceData.policyDelta.auditConfigDeltas.action` | `ADD` / `REMOVE` (REMOVE = logging disabled) |
| `protoPayload.serviceData.policyDelta.auditConfigDeltas.service` | Which service's logging changed (`allServices` = everything) |
| `protoPayload.serviceData.policyDelta.auditConfigDeltas.logType` | `ADMIN_READ` / `DATA_READ` / `DATA_WRITE` |

## 📖 Reading the filter

(See [concepts §4](../../docs/01-concepts.md#4-audit-logs--the-socs-raw-material)):

- `logName:"…activity"` — Admin Activity, which **cannot be disabled** — so the act of tampering is always recorded, even as the attacker tries to go dark.
- `protoPayload.methodName="SetIamPolicy"` — audit-config changes ride on this call.
- `…auditConfigDeltas:*` — the entry *contains* an audit-config change (`:*` means "this field exists").
- optional `…action="REMOVE"` — narrows to logging being *turned off* (the dangerous case vs. just adding logging).

## Tuning notes

- **Severity escalation:** `service="allServices"` with `action="REMOVE"` is a near-certain incident — treat as Critical, page immediately.
- **False positives:** rare. Legitimate audit-config changes happen during initial project hardening — expect a burst at setup, near-zero after. Any change in steady state warrants review.
