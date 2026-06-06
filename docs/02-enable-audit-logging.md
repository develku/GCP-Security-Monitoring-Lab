# 02 — Enable Audit Logging

**Goal of this doc:** confirm logging works, then turn on the one extra log stream a single detection needs. ~5 minutes.

> 📖 **Study first:** this doc applies [§4 of `01-concepts.md`](01-concepts.md#4-audit-logs--the-socs-raw-material) (audit logs + log-entry anatomy). If a field name below looks unfamiliar, that section explains it.

Run every command from the repo folder:

```bash
cd "/Users/kud/Library/Mobile Documents/com~apple~CloudDocs/Programming/github_repo/GCP-Security-Monitoring-Lab"
```

---

## Background: the four audit log streams (30-second read)

| Stream | On by default? | Cost | Captures |
|---|---|---|---|
| **Admin Activity** | ✅ Always (can't disable) | Free | Config changes: IAM grants, key creation, firewall edits |
| System Event | ✅ Always | Free | GCP-initiated changes |
| Policy Denied | ✅ Always | Free | Access blocked by policy |
| **Data Access** | ❌ Opt-in | Billable | Reads of data/config |

5 of our 6 detections use **Admin Activity** (already on, free). Only the *public-bucket* detection needs **Data Access** turned on for Storage. That's all the setup below does.

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

## Step 2 — Enable Data Access logging for Storage

```bash
./scripts/setup/03-enable-audit-logs.sh
```

**This does:** turns on `ADMIN_WRITE` Data Access logging for Cloud Storage, so the public-bucket detection can fire. (It does **not** enable per-object read logging — that would be costly.)

> 📖 **Why this step exists — and a security lesson:** Cloud Storage IAM changes (like making a bucket public) are recorded in the **Data Access** stream, which is off by default ([§4](01-concepts.md#4-audit-logs--the-socs-raw-material)). So we turn it on — but only `ADMIN_WRITE` (config changes), never `DATA_READ`/`DATA_WRITE` (every file access = huge log volume = real cost). **The lesson:** logging is a cost/visibility tradeoff. You enable exactly the streams a detection needs, no more.
>
> Notice the symmetry: this script *enables* logging by editing the project's `auditConfigs`; an attacker would *disable* logging the same way — which is precisely what detection [`audit-config-changed`](../detections/logging-filters/audit-config-changed.md) catches. **The thing you harden is the thing they attack.**

**You should see:**

```
[*] Fetching current IAM policy for gcp-secmon-lab-kud01…
[*] Adding ADMIN_WRITE Data Access logging for storage.googleapis.com…
Updated IAM policy for project [gcp-secmon-lab-kud01].
[+] Done. Storage IAM/config changes are now logged (Data Access, ADMIN_WRITE).
```

---

## Step 3 — Enable the Compute API

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
- [x] Step 2: "Updated IAM policy" (Storage Data Access on)
- [x] Step 3: Compute API enabled

**Next:** **[03 — Run the Lab & Capture Evidence](03-run-and-capture.md)** — trigger the attacks and screenshot the detections firing.
