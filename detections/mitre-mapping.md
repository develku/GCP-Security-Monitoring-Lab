# MITRE ATT&CK Coverage — Cloud Matrix

Each detection in this lab maps to a technique in the [MITRE ATT&CK Cloud matrix](https://attack.mitre.org/matrices/enterprise/cloud/). The chain below reflects a realistic post-compromise progression: gain a foothold → create identities → grant them power → mint portable credentials → expose data → blind the defender.

| Detection | Technique | Tactic | Audit log |
|---|---|---|---|
| [IAM role granted](logging-filters/iam-role-granted.md) | [T1098.003](https://attack.mitre.org/techniques/T1098/003/) — Additional Cloud Roles | Privilege Escalation / Persistence | Admin Activity |
| [Service account created](logging-filters/service-account-created.md) | [T1136.003](https://attack.mitre.org/techniques/T1136/003/) — Create Account: Cloud Account | Persistence | Admin Activity |
| [SA key created](logging-filters/sa-key-created.md) | [T1098.001](https://attack.mitre.org/techniques/T1098/001/) — Additional Cloud Credentials | Persistence | Admin Activity |
| [Bucket made public](logging-filters/public-bucket.md) | [T1530](https://attack.mitre.org/techniques/T1530/) — Data from Cloud Storage | Collection / Exfiltration | Admin Activity |
| [Firewall opened](logging-filters/firewall-open-ingress.md) | [T1562.007](https://attack.mitre.org/techniques/T1562/007/) — Disable/Modify Cloud Firewall | Defense Evasion | Admin Activity |
| [Audit logging disabled](logging-filters/audit-config-changed.md) | [T1562.008](https://attack.mitre.org/techniques/T1562/008/) — Disable/Modify Cloud Logs | Defense Evasion | Admin Activity |

## The correlation story

The single highest-value alert isn't any one rule — it's the **chain**:

```
CreateServiceAccount  →  SetIamPolicy (role grant)  →  CreateServiceAccountKey
   (T1136.003)              (T1098.003)                   (T1098.001)
```

Same `principalEmail`, same short time window = an attacker building a durable, portable foothold. Individually these are Medium/High; together they're a high-confidence, page-now incident. A future enhancement (BigQuery / log-based metrics) can detect the *sequence*, not just the individual events.

## Evidence status

| Detection | Filter written | Simulated | Screenshot evidence |
|---|---|---|---|
| IAM role granted | ✅ | ✅ | ✅ |
| SA key created | ✅ | ✅ | ✅ |
| Bucket made public | ✅ | ✅ | ✅ |
| Service account created | ✅ | ✅ | — documented |
| Firewall opened | ✅ | ⬜ | — documented |
| Audit logging disabled | ✅ | ⬜ | — documented |

> "hero" = fully deployed + simulated + screenshotted for v1. "documented" = filter + sim script present, validated locally.
