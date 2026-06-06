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

| # | Detection | MITRE ATT&CK (Cloud) | Status |
|---|---|---|---|
| 1 | IAM role granted (primitive roles) | T1098.003 | ✅ |
| 2 | Service account key created | T1098.001 | 🚧 |
| 3 | Storage bucket made public | T1530 | ⬜ |
| 4 | Audit logging disabled | T1562.008 | ⬜ |
| 5 | Firewall opened to internet | T1562.007 | ⬜ |
| 6 | Service account created | T1136.003 | ⬜ |

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
