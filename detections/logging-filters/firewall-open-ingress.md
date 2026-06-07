# Detection: Firewall Rule Opened to the Internet

| | |
|---|---|
| **MITRE ATT&CK** | [T1562.007 — Impair Defenses: Disable or Modify Cloud Firewall](https://attack.mitre.org/techniques/T1562/007/) |
| **Audit log** | Admin Activity (always on, free) |
| **Severity** | High (attack-surface exposure / lateral movement enablement) |
| **Simulation** | [`scripts/simulate/05-sim-firewall-open.sh`](../../scripts/simulate/05-sim-firewall-open.sh) |

## Why this matters

A firewall rule allowing ingress from `0.0.0.0/0` exposes a VM to the entire internet. Attackers create these to open access to a compromised instance (e.g. expose RDP/SSH/databases), and misconfigurations create the same exposure accidentally. Opening management ports (22, 3389) to the world is especially dangerous.

## The signal

- `methodName` for firewall creation: `v1.compute.firewalls.insert`
- a source range of `0.0.0.0/0` in the request

## Cloud Logging filter (Log Explorer)

```
logName:"cloudaudit.googleapis.com%2Factivity"
protoPayload.methodName:"compute.firewalls.insert"
protoPayload.request.sourceRanges="0.0.0.0/0"
```

> `compute.firewalls.patch` catches *modifications* to existing rules — add it (`protoPayload.methodName:"compute.firewalls"`) to widen coverage.

## Run it from the CLI

```bash
gcloud logging read \
  'logName:"cloudaudit.googleapis.com%2Factivity"
   protoPayload.methodName:"compute.firewalls.insert"
   protoPayload.request.sourceRanges="0.0.0.0/0"' \
  --limit=10 --freshness=24h \
  --format="table(timestamp,
    protoPayload.authenticationInfo.principalEmail,
    protoPayload.resourceName,
    protoPayload.request.sourceRanges)"
```

## Key fields

| Field | Meaning |
|---|---|
| `protoPayload.authenticationInfo.principalEmail` | **Who** created the rule |
| `protoPayload.resourceName` | **Which** firewall rule |
| `protoPayload.request.sourceRanges` | The exposed source range (`0.0.0.0/0` = entire internet) |
| `protoPayload.request.alloweds.ports` | Which ports were opened (22/3389 = critical) |

## 📖 Reading the filter

- `logName:"…activity"` — Admin Activity stream.
- `protoPayload.methodName:"compute.firewalls.insert"` — note the `:` (substring match), so it catches versioned names like `v1.compute.firewalls.insert`. (Compare `=` = exact match, used elsewhere.)
- `protoPayload.request.sourceRanges="0.0.0.0/0"` — the rule allows traffic from the **entire internet**.

The `:` vs `=` distinction is worth remembering — substring match is how you stay robust to GCP's versioned method names.

## Tuning notes

- **Escalate** when opened ports include `22` (SSH) or `3389` (RDP) — management access to the world.
- **False positives:** intentional public-facing services (HTTP/HTTPS load balancers on 80/443). Allow-list those ports or rule-name prefixes; alert on everything else.
