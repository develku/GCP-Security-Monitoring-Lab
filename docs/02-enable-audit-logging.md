# 02 — Enable Audit Logging

**Goal of this doc:** confirm logging works, then turn on the one extra log stream a single detection needs. ~5 minutes.

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

**You should see** a small table of your recent actions:

```
TIMESTAMP                       PRINCIPAL_EMAIL        METHOD_NAME
2026-06-...Z                    you@example.com  SetIamPolicy
2026-06-...Z                    you@example.com  google.api.serviceusage.v1.ServiceUsage.EnableService
```

✅ If you see a table → logging works. Continue.
❌ Empty / error → confirm the active project: `gcloud config get-value project` (should be `gcp-secmon-lab-kud01`).

---

## Step 2 — Enable Data Access logging for Storage

```bash
./scripts/setup/03-enable-audit-logs.sh
```

**This does:** turns on `ADMIN_WRITE` Data Access logging for Cloud Storage, so the public-bucket detection can fire. (It does **not** enable per-object read logging — that would be costly.)

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
