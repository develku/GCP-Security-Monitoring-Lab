# GCP Security Monitoring Lab — Implementation Plan

## Overview

A beginner-friendly Google Cloud lab that demonstrates **cloud detection engineering** — the cloud-native mirror of the on-prem Splunk detection chain (SIEM-Detection-Lab → Detection-Engineering-Lab → Attack-Simulation-Lab). You stand up audit logging in a GCP project, write detection rules against the logs, then simulate the matching attacks to prove each rule fires.

```
Enable Cloud Audit Logs   → capture who-did-what across the project
Write detection rules     → Log Explorer filters (MVP) + BigQuery SQL (enhancement)
Simulate attacks          → gcloud scripts that trigger each detection
Alert + document          → Cloud Monitoring alert policies + evidence screenshots
```

**Design constraint:** everything runs inside GCP's **Always Free tier + $300 trial credit**. A teardown script + doc keeps spend at $0. No production data, no real credentials — synthetic resources only.

## Project Structure

```
GCP-Security-Monitoring-Lab/
├── README.md
├── LICENSE
├── .gitignore
├── PLAN.md
├── docs/
│   ├── 00-prerequisites.md          # GCP account, free tier, billing alert, gcloud install
│   ├── 01-project-setup.md          # Create project, set gcloud config, enable APIs
│   ├── 02-enable-audit-logging.md   # Admin Activity vs Data Access logs, what each captures
│   ├── 03-detection-queries.md      # Walkthrough of each detection's logic + MITRE mapping
│   ├── 04-bigquery-sink.md          # (Enhancement) Export logs to BigQuery for SQL detection
│   ├── 05-alerting.md               # Log-based metrics + Cloud Monitoring alert policies
│   ├── 06-attack-simulation.md      # Safely generate each malicious event
│   └── 07-teardown.md               # Destroy resources, confirm $0 spend
├── scripts/
│   ├── setup/
│   │   ├── 01-create-project.sh     # gcloud projects create + link billing
│   │   ├── 02-enable-apis.sh        # logging, monitoring, (bigquery)
│   │   ├── 03-enable-audit-logs.sh  # Set IAM audit config policy
│   │   └── 04-create-bigquery-sink.sh   # (Enhancement) log sink → BigQuery dataset
│   ├── simulate/
│   │   ├── 02-sim-iam-role-granted.sh
│   │   ├── 03-sim-sa-key-created.sh
│   │   ├── 04-sim-public-bucket.sh
│   │   ├── 06-sim-audit-config-changed.sh
│   │   ├── 05-sim-firewall-open.sh
│   │   └── 01-sim-sa-created.sh
│   └── teardown.sh
├── detections/
│   ├── logging-filters/             # Cloud Logging query syntax (Log Explorer) — MVP
│   │   ├── iam-role-granted.md
│   │   ├── sa-key-created.md
│   │   ├── public-bucket.md
│   │   ├── audit-config-changed.md
│   │   ├── firewall-open-ingress.md
│   │   └── service-account-created.md
│   ├── bigquery-sql/                # (Enhancement) same logic as SQL over the sink
│   │   ├── iam-role-granted.sql
│   │   ├── sa-key-created.sql
│   │   └── public-bucket.sql
│   └── mitre-mapping.md             # MITRE ATT&CK Cloud matrix coverage table
├── sigma/                           # (Enhancement) Sigma rules — portfolio consistency
│   └── gcp/
│       ├── gcp_iam_role_granted.yml
│       ├── gcp_sa_key_created.yml
│       └── gcp_bucket_made_public.yml
└── screenshots/                     # Evidence: Log Explorer hits, alerts firing
```

## Detection Coverage

Six core detections, each with a matching simulation. Logging-filter form is the MVP; BigQuery SQL + Sigma are enhancements.

| # | Detection | Trigger (audit log signal) | MITRE ATT&CK (Cloud) |
|---|---|---|---|
| 1 | **IAM role granted** | `SetIamPolicy` adding `roles/owner` or `roles/editor` at project level | T1098.003 Additional Cloud Roles |
| 2 | **Service account key created** | `google.iam.admin.v1.CreateServiceAccountKey` | T1098.001 Additional Cloud Credentials |
| 3 | **Storage bucket made public** | `storage.setIamPermissions` granting `allUsers` / `allAuthenticatedUsers` | T1530 Data from Cloud Storage |
| 4 | **Audit logging disabled** | `SetIamPolicy` modifying `auditConfigs` (logging turned off) | T1562.008 Disable Cloud Logs |
| 5 | **Firewall opened to internet** | `compute.firewalls.insert` with source range `0.0.0.0/0` | T1562.007 Disable/Modify Cloud Firewall |
| 6 | **Service account created** | `google.iam.admin.v1.CreateServiceAccount` | T1136.003 Create Account: Cloud Account |

## Tools

| Tool | Purpose | Cost |
|---|---|---|
| `gcloud` CLI | Provision project, run setup + simulation scripts | Free |
| Cloud Audit Logs | Capture Admin Activity events (always-on) | Free |
| Cloud Logging (Log Explorer) | Run detection filters — the MVP detection surface | Free (50 GiB/mo) |
| Cloud Monitoring | Log-based metrics + alert policies | Free tier |
| BigQuery *(enhancement)* | SQL detection over exported logs | Free (1 TB query, 10 GB storage/mo) |
| Context7 MCP | Current GCP docs while authoring guides | Already available |

---

## Phase 0: Prerequisites & Account Setup

**Goal:** A GCP account with the free trial active, a **billing budget alert** set, and `gcloud` authenticated locally.

| Step | Files | Description |
|---|---|---|
| 0.1 | `docs/00-prerequisites.md` | Sign up for GCP free trial ($300 credit), install `gcloud`, `gcloud init`, `gcloud auth login` |
| 0.2 | `docs/00-prerequisites.md` | **Set a $1 budget alert** before creating anything — habit that proves cost-awareness |

---

## Phase 1: Project Setup & Audit Logging

**Goal:** A dedicated GCP project with Admin Activity audit logs flowing into Cloud Logging.

| Step | Files | Description |
|---|---|---|
| 1.1 | `scripts/setup/01-create-project.sh`, `docs/01-project-setup.md` | `gcloud projects create`, link billing, set default project/region |
| 1.2 | `scripts/setup/02-enable-apis.sh` | Enable logging, monitoring (and bigquery for later) APIs |
| 1.3 | `scripts/setup/03-enable-audit-logs.sh`, `docs/02-enable-audit-logging.md` | Apply IAM audit config; explain Admin Activity (free, always-on) vs Data Access (opt-in, billable) |

---

## Phase 2: Detection Rules (MVP — Log Explorer)

**Goal:** Six documented Cloud Logging filters that each isolate one suspicious event class.

| Step | Files | Description |
|---|---|---|
| 2.1 | `detections/logging-filters/iam-role-granted.md` | Filter on `protoPayload.methodName="SetIamPolicy"` + primitive-role binding delta |
| 2.2 | `detections/logging-filters/sa-key-created.md` | `CreateServiceAccountKey` method, extract actor + target SA |
| 2.3 | `detections/logging-filters/public-bucket.md` | `storage.setIamPermissions` granting `allUsers` |
| 2.4 | `detections/logging-filters/audit-config-changed.md` | `auditConfigs` removed/modified in `SetIamPolicy` delta |
| 2.5 | `detections/logging-filters/firewall-open-ingress.md` | `compute.firewalls.insert` + `sourceRanges: 0.0.0.0/0` |
| 2.6 | `detections/logging-filters/service-account-created.md` | `CreateServiceAccount` method |
| 2.7 | `detections/mitre-mapping.md` | Coverage table linking each filter to its ATT&CK Cloud technique |

> **Your hands-on contribution lands here.** During the build I'll scaffold the filter format and write the first 1–2 rules, then hand you a `TODO(human)` to write a detection filter yourself — picking the fields and match logic is the core detection-engineering judgment call worth practicing.

---

## Phase 3: Attack Simulation

**Goal:** One script per detection that safely generates the matching event, so each rule is proven to fire.

| Step | Files | Description |
|---|---|---|
| 3.1 | `scripts/simulate/02-sim-iam-role-granted.sh` | Grant `roles/editor` to a throwaway test member |
| 3.2 | `scripts/simulate/03-sim-sa-key-created.sh` | Create a key on a test service account |
| 3.3 | `scripts/simulate/04-sim-public-bucket.sh` | Add `allUsers:objectViewer` to a test bucket |
| 3.4 | `scripts/simulate/06-sim-audit-config-changed.sh` | Toggle an audit config off (then restore) |
| 3.5 | `scripts/simulate/05-sim-firewall-open.sh` | Create a `0.0.0.0/0` ingress rule |
| 3.6 | `scripts/simulate/01-sim-sa-created.sh` | Create a test service account |
| 3.7 | `docs/06-attack-simulation.md` | Run each sim, screenshot the matching Log Explorer hit |

---

## Phase 4: Alerting & Enhancements (optional)

**Goal:** Turn detections into live alerts; add BigQuery + Sigma for depth.

| Step | Files | Description |
|---|---|---|
| 4.1 | `docs/05-alerting.md` | Create a log-based metric + Cloud Monitoring alert policy for detections 1 & 4 |
| 4.2 | `scripts/setup/04-create-bigquery-sink.sh`, `docs/04-bigquery-sink.md` | Export logs to BigQuery dataset |
| 4.3 | `detections/bigquery-sql/*.sql` | Re-express 3 detections as SQL — shows you can pivot from filter to analytics |
| 4.4 | `sigma/gcp/*.yml` | Sigma versions of 3 rules — consistency with Detection-Engineering-Lab |

---

## Phase 5: Documentation & Teardown

| Step | Files | Description |
|---|---|---|
| 5.1 | `README.md` | "What This Demonstrates" table, architecture diagram, detection coverage, repo tree |
| 5.2 | `scripts/teardown.sh`, `docs/07-teardown.md` | Delete project/resources; confirm $0 spend |
| 5.3 | `screenshots/` | Curated evidence: a fired detection + a firing alert |

---

## Portfolio Synergy

| Existing Project | Connection |
|---|---|
| **SIEM-Detection-Lab** | Same role (logging infrastructure) — Splunk on-prem vs Cloud Logging in GCP |
| **Detection-Engineering-Lab** | Same craft (write rule → map to MITRE → tune); SPL ↔ Logging filter / BigQuery SQL; shares Sigma format |
| **Attack-Simulation-Lab** | Same loop (simulate → validate detection); Atomic Red Team ↔ gcloud simulation scripts |
| **AWS-Terraform-CICD-Lab** | Complements it: that lab is AWS *DevOps*; this is GCP *security monitoring* — together they show multi-cloud breadth |
| **Incident-Investigation-Portfolio** | A fired detection can seed a cloud DFIR write-up (future extension) |

## Priority if Time-Constrained

**Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 5**

Phases 0–3 + docs = a complete, credible lab (audit logging + 6 detections + proven simulations). Phase 4 (alerting/BigQuery/Sigma) is depth you can add later without blocking a first publish.

## Risks & Mitigations

| Risk | Severity | Mitigation |
|---|---|---|
| Unexpected GCP charges | High | Free-tier-only resources; $1 budget alert in Phase 0; teardown script + doc |
| Leaving the project running | Medium | `teardown.sh` deletes the whole project; documented as final step |
| Service account key committed to git | High | `.gitignore` excludes `*.json` keys; sims create keys in a temp dir, deleted after |
| Data Access logs inflating cost | Medium | Lab uses only Admin Activity logs (free); Data Access stays disabled |
| Scope creep into full Chronicle/SCC setup | Medium | Explicitly out of scope; Log Explorer is the MVP surface |
| Over-engineering | Medium | Portfolio lab — filters first, SQL/Sigma only as enhancement |

## Success Criteria

- [ ] `docs/00-prerequisites.md` gets a beginner from zero to authenticated `gcloud` with a budget alert set
- [ ] Setup scripts create a project with Admin Activity audit logging enabled
- [ ] All 6 detections documented as Log Explorer filters with MITRE ATT&CK mapping
- [ ] Each detection has a simulation script that provably triggers it (screenshot evidence)
- [ ] `detections/mitre-mapping.md` lists full Cloud ATT&CK coverage with links
- [ ] `teardown.sh` removes all resources; README confirms $0-spend design
- [ ] README has architecture diagram, "What This Demonstrates" table, and repo tree
- [ ] No real credentials, keys, or non-synthetic data anywhere in the repo
