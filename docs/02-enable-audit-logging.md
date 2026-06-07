# 02 — Enable Audit Logging

**Goal of this doc:** confirm audit logging works, then enable the Compute API for the firewall simulation. ~3 minutes.

> 📖 **Study first:** this doc applies [§4 of `01-concepts.md`](01-concepts.md#4-audit-logs--the-socs-raw-material) (audit logs + log-entry anatomy). If a field name below looks unfamiliar, that section explains it.

Run every command from the repo folder:

```bash
cd /path/to/GCP-Security-Monitoring-Lab   # the cloned repo folder
```

---

## Background: the four audit log streams (30-second read)

| Stream | On by default? | Cost | Captures |
|---|---|---|---|
| **Admin Activity** | ✅ Always (can't disable) | Free | Config changes: IAM grants, key creation, firewall edits |
| System Event | ✅ Always | Free | GCP-initiated changes |
| Policy Denied | ✅ Always | Free | Access blocked by policy |
| **Data Access** | ❌ Opt-in | Billable | Reads of data/config |

**All 6 detections in this lab use Admin Activity** — already on, free, and impossible to disable (even bucket-IAM changes, which are config writes, land here). So there's barely anything to set up: just verify it works (Step 1), then enable the Compute API for the firewall simulation (Step 2).

---

## Step 1 — Verify Admin Activity logs are flowing

```bash
gcloud logging read 'logName:"cloudaudit.googleapis.com%2Factivity"' \
  --limit=5 --freshness=24h \
  --format="table(timestamp, protoPayload.authenticationInfo.principalEmail, protoPayload.methodName)"
```

**This does:** reads your audit log (read-only — changes nothing).

> 📖 **What you're looking at — read each column:**
> - `TIMESTAMP` — when the action happened.
> - `PRINCIPAL_EMAIL` (`protoPayload.authenticationInfo.principalEmail`) — **who** did it.
> - `METHOD_NAME` (`protoPayload.methodName`) — **the API call they made**. This is the field every detection keys off. `SetIamPolicy` = an IAM change; `EnableService` = an API was turned on.
>
> A detection is nothing more than: "show me log entries where `methodName` = *(a suspicious call)* and *(some field)* = *(a bad value)*." Once you can read this table, you can read every detection in this lab.

**You should see** a small table of your recent actions:

```
TIMESTAMP                       PRINCIPAL_EMAIL        METHOD_NAME
2026-06-...Z                    you@example.com  SetIamPolicy
2026-06-...Z                    you@example.com  google.api.serviceusage.v1.ServiceUsage.EnableService
```

✅ If you see a table → logging works. Continue.

❌ **Empty result?** Most likely the project has just been quiet. `--freshness=24h` only shows the last 24 hours — if you haven't done anything in the project today, widen the window:

```bash
gcloud logging read 'logName:"cloudaudit.googleapis.com%2Factivity"' \
  --limit=5 --freshness=30d \
  --format="table(timestamp, protoPayload.authenticationInfo.principalEmail, protoPayload.methodName)"
```

Empty here too → confirm the active project: `gcloud config get-value project` (should be `gcp-secmon-lab-kud01`). Note: "no results" usually means your **time filter** excluded the logs, not that logging is off.

---

## Step 2 — Enable the Compute API

```bash
gcloud services enable compute.googleapis.com
```

**This does:** turns on Compute Engine (creates the `default` VPC) so the firewall simulation works. Takes ~30–60 seconds; no output on success means it worked.

**You should see** (after a pause): your prompt returns with no error, or:

```
Operation "operations/acat.p2-...-..." finished successfully.
```

---

## ✅ Done — checklist

- [x] Step 1: saw a table of recent actions (Admin Activity works)
- [x] Step 2: Compute API enabled

**Next:** **[03 — Run the Lab & Capture Evidence](03-run-and-capture.md)** — trigger the attacks and screenshot the detections firing.
