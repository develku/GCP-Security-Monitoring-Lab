# Detection: IAM Role Granted (primitive roles)

| | |
|---|---|
| **MITRE ATT&CK** | [T1098.003 — Account Manipulation: Additional Cloud Roles](https://attack.mitre.org/techniques/T1098/003/) |
| **Audit log** | Admin Activity (always on, free) |
| **Severity** | High (privilege escalation / persistence) |
| **Simulation** | [`scripts/simulate/sim-iam-role-granted.sh`](../../scripts/simulate/sim-iam-role-granted.sh) |

## Why this matters

Granting `roles/owner` or `roles/editor` at the project level gives broad, durable control. Attackers do this to **escalate privilege** and **establish persistence** after an initial compromise. Legitimate grants happen too — so this detection is about *surfacing for review*, not auto-blocking.

## The signal

When someone changes IAM, GCP records a `SetIamPolicy` call and includes a **policy delta** — the exact bindings added or removed. We match on:

- `methodName = SetIamPolicy`
- a binding **delta** with `action = ADD`
- a `role` that is a primitive role (`roles/owner` or `roles/editor`)

## Cloud Logging filter (Log Explorer)

```
logName:"cloudaudit.googleapis.com%2Factivity"
protoPayload.methodName="SetIamPolicy"
protoPayload.serviceData.policyDelta.bindingDeltas.action="ADD"
(protoPayload.serviceData.policyDelta.bindingDeltas.role="roles/owner" OR
 protoPayload.serviceData.policyDelta.bindingDeltas.role="roles/editor")
```

## Run it from the CLI

```bash
gcloud logging read \
  'logName:"cloudaudit.googleapis.com%2Factivity"
   protoPayload.methodName="SetIamPolicy"
   protoPayload.serviceData.policyDelta.bindingDeltas.action="ADD"
   (protoPayload.serviceData.policyDelta.bindingDeltas.role="roles/owner" OR
    protoPayload.serviceData.policyDelta.bindingDeltas.role="roles/editor")' \
  --limit=10 --freshness=24h \
  --format="table(timestamp,
    protoPayload.authenticationInfo.principalEmail,
    protoPayload.serviceData.policyDelta.bindingDeltas.role,
    protoPayload.request.resource)"
```

## Key fields

| Field | Meaning |
|---|---|
| `protoPayload.authenticationInfo.principalEmail` | **Who** made the change |
| `protoPayload.serviceData.policyDelta.bindingDeltas.role` | **Which** role was added |
| `protoPayload.serviceData.policyDelta.bindingDeltas.member` | **To whom** the role was granted |
| `protoPayload.requestMetadata.callerIp` | Source IP of the actor |

## 📖 Reading the filter

Each line narrows the search (see [concepts §4](../../docs/01-concepts.md#4-audit-logs--the-socs-raw-material) for the fields):

- `logName:"…activity"` — only the **Admin Activity** stream (free, always on).
- `protoPayload.methodName="SetIamPolicy"` — only IAM-policy changes.
- `bindingDeltas.action="ADD"` — only *additions* of access (ignore removals).
- `role="roles/owner" OR "roles/editor"` — only the broad **primitive** roles worth alarming on.

Drop the last line and you'd catch *every* IAM change — more coverage, far more noise. Keeping it is the coverage-vs-noise tradeoff in action.

## Tuning notes

- **False positives:** legitimate admin onboarding, Terraform/CI service accounts applying IAM. Allow-list known automation `principalEmail`s.
- **Widen coverage:** add `roles/iam.securityAdmin`, `roles/resourcemanager.projectIamAdmin`, and any custom role with `setIamPolicy`.
- **Tighten:** alert only when `member` is a `user:` (human) rather than a known `serviceAccount:`.
