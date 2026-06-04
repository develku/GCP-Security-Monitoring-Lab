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

<!-- TODO(human): write the Cloud Logging filter for this detection.
     Replace this comment block with a fenced ```...``` code block containing the filter,
     following the same shape as detections/logging-filters/iam-role-granted.md.
     See the Learn by Doing guidance for the exact methodName and the fields to surface. -->

## Key fields

| Field | Meaning |
|---|---|
| `protoPayload.authenticationInfo.principalEmail` | **Who** created the key |
| `protoPayload.methodName` | The API call that minted the key |
| `protoPayload.request.name` / `protoPayload.resourceName` | **Which** service account was targeted |
| `protoPayload.requestMetadata.callerIp` | Source IP of the actor |

## Tuning notes

- **False positives:** CI/CD or Terraform provisioning that legitimately rotates keys. Allow-list known automation `principalEmail`s.
- **Escalate:** key created on a *highly privileged* service account (one holding `roles/owner`/`roles/editor`) is critical.
- **Pair with:** [`iam-role-granted`](iam-role-granted.md) — key creation *after* a fresh role grant is a classic escalation→persistence chain.
