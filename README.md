# GCP Security Monitoring Lab

> Cloud detection engineering on Google Cloud — the cloud-native mirror of an on-prem SIEM detection chain. Enable audit logging, write detection rules against the logs, then simulate the matching attacks to prove each rule fires.

![Status](https://img.shields.io/badge/status-in%20progress-yellow)
![Cloud](https://img.shields.io/badge/cloud-Google%20Cloud-blue)
![Cost](https://img.shields.io/badge/cost-free%20tier-green)

## What this demonstrates

| Skill | Evidence |
|---|---|
| Cloud audit logging | Enable + query GCP Admin Activity logs ([`docs/`](docs/)) |
| Detection engineering | Cloud Logging filters mapped to MITRE ATT&CK ([`detections/`](detections/)) |
| Attack simulation | Scripts that trigger each detection to validate it ([`scripts/simulate/`](scripts/simulate/)) |
| Cloud cost discipline | Free-tier-only design + budget alert + teardown ([`docs/00-prerequisites.md`](docs/00-prerequisites.md)) |
| Secure-by-default repo | Credential-guarding `.gitignore`, no secrets in history |

## Architecture

```
gcloud CLI ──> GCP Project ──> Cloud Audit Logs (Admin Activity, free)
                                        │
                                        ├──> Log Explorer filters  ── detection rules (MVP)
                                        ├──> BigQuery sink          ── SQL detections (enhancement)
                                        └──> Cloud Monitoring       ── alert policies
                                        ▲
              scripts/simulate/*.sh ────┘  (generate the malicious events to validate detections)
```

## Detection coverage

| # | Detection | MITRE ATT&CK (Cloud) | Filter | Evidence |
|---|---|---|---|---|
| 1 | [IAM role granted (primitive roles)](detections/logging-filters/iam-role-granted.md) | T1098.003 | ✅ | ✅ [screenshot](screenshots/01-iam-role-granted.png) |
| 2 | [Service account key created](detections/logging-filters/sa-key-created.md) | T1098.001 | ✅ | ✅ [screenshot](screenshots/02-sa-key-created.png) |
| 3 | [Storage bucket made public](detections/logging-filters/public-bucket.md) | T1530 | ✅ | ✅ [screenshot](screenshots/03-public-bucket.png) |
| 4 | [Audit logging disabled](detections/logging-filters/audit-config-changed.md) | T1562.008 | ✅ | validated locally |
| 5 | [Firewall opened to internet](detections/logging-filters/firewall-open-ingress.md) | T1562.007 | ✅ | validated locally |
| 6 | [Service account created](detections/logging-filters/service-account-created.md) | T1136.003 | ✅ | validated locally |

All six detections query the always-on, free **Admin Activity** audit log. See [`detections/mitre-mapping.md`](detections/mitre-mapping.md) for the full ATT&CK coverage + the correlation chain.

## Evidence

Each detection was validated by simulating the matching attack and confirming it fires (see [`docs/03-run-and-capture.md`](docs/03-run-and-capture.md)).

**IAM role granted (T1098.003)** — `SetIamPolicy` adding `roles/editor`:
![IAM role grant caught in Log Explorer](screenshots/01-iam-role-granted.png)

**Service account key created (T1098.001)** — `CreateServiceAccountKey`:
![SA key creation caught in Log Explorer](screenshots/02-sa-key-created.png)

**Storage bucket made public (T1530)** — `storage.setIamPermissions`:
![Public bucket exposure caught in Log Explorer](screenshots/03-public-bucket.png)

## Repository structure

See [`PLAN.md`](PLAN.md) for the full implementation plan, phases, and success criteria.

```
docs/         Numbered setup + walkthrough guides
detections/   Cloud Logging filters (+ BigQuery SQL, Sigma)
scripts/      Setup + attack-simulation + teardown scripts
```

## Getting started

Follow the numbered guides in order:

1. [`docs/00-prerequisites.md`](docs/00-prerequisites.md) — install gcloud, create a project, set a budget alert.
2. [`docs/01-concepts.md`](docs/01-concepts.md) — **study first:** the ideas behind the lab (IAM, service accounts, audit logs, MITRE ATT&CK, detection engineering).
3. [`docs/02-enable-audit-logging.md`](docs/02-enable-audit-logging.md) — turn on the audit logs the detections query.
4. [`docs/03-run-and-capture.md`](docs/03-run-and-capture.md) — run the attack simulations and screenshot each detection firing.

Evidence lands in [`screenshots/`](screenshots/).

## License

[MIT](LICENSE)
