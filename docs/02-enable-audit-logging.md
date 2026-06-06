# 02 — Enable Audit Logging

Audit logs are the raw material every detection in this lab queries. This guide explains the four audit log streams, then enables the one opt-in stream a single detection needs.

## The four audit log streams

| Stream | On by default? | Cost | Captures | Used by |
|---|---|---|---|---|
| **Admin Activity** | ✅ Always (cannot disable) | Free | Config changes: IAM grants, key creation, firewall edits, resource create/delete | 5 of 6 detections |
| **System Event** | ✅ Always | Free | GCP-initiated changes | — |
| **Policy Denied** | ✅ Always | Free | Access blocked by policy / VPC-SC | — |
| **Data Access** | ❌ Opt-in | **Billable, high-volume** | Reads of data/config | 1 detection (public bucket) |

**Takeaway:** the moment you created the project, Admin Activity logging started recording the security-relevant control-plane events — for free, and it can't be turned off. That's why most of this lab needs zero logging setup.

## Verify Admin Activity logs are flowing

```bash
gcloud logging read 'logName:"cloudaudit.googleapis.com%2Factivity"' \
  --limit=10 --freshness=2h \
  --format="table(timestamp,
    protoPayload.authenticationInfo.principalEmail,
    protoPayload.methodName,
    resource.type)"
```

You should see your own recent actions (e.g. `SetIamPolicy`, `EnableService`). `protoPayload.methodName` is the field every detection keys off.

## Enable Data Access logging for Storage (for the public-bucket detection)

Cloud Storage IAM changes are recorded in **Data Access** logs, which are off by default. Enable `ADMIN_WRITE` only (config changes — low volume), never `DATA_READ`/`DATA_WRITE` (every object access — expensive):

```bash
./scripts/setup/03-enable-audit-logs.sh
```

> What the script does: edits the project IAM policy's `auditConfigs` to add
> `{ service: storage.googleapis.com, logType: ADMIN_WRITE }`.
> This is the *same* policy surface an attacker abuses to *disable* logging —
> which is exactly what detection [`audit-config-changed`](../detections/logging-filters/audit-config-changed.md) catches.

## Enable the Compute API (for the firewall detection)

The firewall simulation needs Compute Engine enabled (creates the `default` VPC):

```bash
gcloud services enable compute.googleapis.com
```

## Done — you now have

- [x] Confirmed Admin Activity logs are flowing (covers 5 detections)
- [x] Data Access `ADMIN_WRITE` enabled for Storage (covers the public-bucket detection)
- [x] Compute API enabled (for the firewall simulation)

Next: **[03 — Detection Queries](03-detection-queries.md)** — or jump straight to running the simulations and capturing evidence (see the README runbook).
