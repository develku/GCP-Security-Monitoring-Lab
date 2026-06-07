# 03 — Run the Lab & Capture Evidence

**Goal:** trigger 3 attacks, watch each detection catch them, and screenshot the proof. ~20 minutes.

> 💰 **Cost & safety:** every attack creates a disposable `secmon-test-*` resource (a test service account, a key, a public bucket). They cost ~nothing, but **run `scripts/teardown.sh` at the end** (Step 5) so nothing is left exposed.

Run everything from the repo folder:

```bash
cd /path/to/GCP-Security-Monitoring-Lab   # the cloned repo folder
```

---

## Step 0 — Create the test identity

The first two attacks act on a test service account, so create it first:

```bash
./scripts/simulate/sim-sa-created.sh
```

**You should see:**

```
[+] Created service account: secmon-test-sa@gcp-secmon-lab-kud01.iam.gserviceaccount.com
    Triggers T1136.003 — see detections/logging-filters/service-account-created.md
```

---

## How each attack works (the pattern, repeated 3×)

For each hero detection you'll: **(a)** run the sim → **(b)** wait 1–2 min for logs → **(c)** confirm via CLI → **(d)** screenshot in the console.

### 🦸 HERO 1 — IAM role granted (T1098.003)

> 📖 **The attack:** the sim grants `roles/editor` to the test service account. In a real breach, an attacker who compromised one identity grants themselves (or a SA they control) a broad **primitive role** — instant privilege escalation that persists until someone notices. The detection watches `SetIamPolicy` for added owner/editor bindings. ([concepts §2](01-concepts.md#2-identity--iam-identity-and-access-management))

**(a) Run the attack:**

```bash
./scripts/simulate/sim-iam-role-granted.sh
```

Expect: `[+] Granted roles/editor to secmon-test-sa@…`

**(b) Wait ~1–2 minutes** (logs take a moment to appear).

**(c) Confirm via CLI:**

```bash
gcloud logging read \
  'logName:"cloudaudit.googleapis.com%2Factivity"
   protoPayload.methodName="SetIamPolicy"
   protoPayload.serviceData.policyDelta.bindingDeltas.role="roles/editor"' \
  --limit=3 --freshness=1h \
  --format="table(timestamp, protoPayload.authenticationInfo.principalEmail, protoPayload.serviceData.policyDelta.bindingDeltas.role)"
```

Expect a row showing your email + `roles/editor`. **That's the detection working.**

**(d) Screenshot in the console:**

1. Open <https://console.cloud.google.com/logs/query?project=gcp-secmon-lab-kud01>
2. Paste this into the query box and click **Run query**:

   ```
   logName:"cloudaudit.googleapis.com%2Factivity"
   protoPayload.methodName="SetIamPolicy"
   protoPayload.serviceData.policyDelta.bindingDeltas.role="roles/editor"
   ```

3. Click the matching log entry to expand it.
4. Screenshot the **query box + the expanded entry** in one frame.
5. Save as `screenshots/01-iam-role-granted.png`.

![IAM role grant (roles/editor) caught by the SetIamPolicy detection in Log Explorer](../screenshots/01-iam-role-granted.png)

---

### 🦸 HERO 2 — Service account key created (T1098.001)

> 📖 **The attack:** the sim creates a downloadable JSON key for the test SA. That key is a long-lived credential usable from anywhere, surviving password resets and session revocation — classic credential theft + persistence. The detection watches for the `CreateServiceAccountKey` call. ([concepts §3](01-concepts.md#3-service-accounts--keys))

**(a)** `./scripts/simulate/sim-sa-key-created.sh` → expect `[+] Created key for … keys/secmon-test-sa-key.json`

**(b)** Wait ~1–2 min.

**(c) Confirm via CLI:**

```bash
gcloud logging read \
  'logName:"cloudaudit.googleapis.com%2Factivity"
   protoPayload.methodName="google.iam.admin.v1.CreateServiceAccountKey"' \
  --limit=3 --freshness=1h \
  --format="table(timestamp, protoPayload.authenticationInfo.principalEmail, protoPayload.request.name)"
```

**(d) Screenshot:** same console URL, paste this filter, run, expand, capture, save as `screenshots/02-sa-key-created.png`:

```
logName:"cloudaudit.googleapis.com%2Factivity"
protoPayload.methodName="google.iam.admin.v1.CreateServiceAccountKey"
```

![Service-account key creation caught by the CreateServiceAccountKey detection](../screenshots/02-sa-key-created.png)

---

### 🦸 HERO 3 — Storage bucket made public (T1530)

> 📖 **The attack:** the sim grants `allUsers` read access to a test bucket — exposing it to the entire internet, one of the most common causes of cloud data breaches. The detection watches the **Admin Activity** log for `storage.setIamPermissions` (bucket-IAM changes are config writes, so they're logged for free — no extra setup). ([concepts §2](01-concepts.md#2-identity--iam-identity-and-access-management))

**(a)** `./scripts/simulate/sim-public-bucket.sh` → expect `[!] gs://secmon-test-bucket-… is now PUBLIC`

**(b)** Wait ~1–2 min.

**(c) Confirm via CLI:**

```bash
gcloud logging read \
  'logName:"cloudaudit.googleapis.com%2Factivity"
   protoPayload.methodName="storage.setIamPermissions"' \
  --limit=3 --freshness=1h \
  --format="table(timestamp, protoPayload.authenticationInfo.principalEmail, resource.labels.bucket_name)"
```

> If this is empty, wait another minute (logs can lag) and re-run — bucket-IAM changes are in the always-on Admin Activity log, so there's no logging setup to miss.

**(d) Screenshot:** console, paste this filter, run, expand, capture, save as `screenshots/03-public-bucket.png`:

```
logName:"cloudaudit.googleapis.com%2Factivity"
protoPayload.methodName="storage.setIamPermissions"
```

![Public-bucket exposure caught by the storage.setIamPermissions detection](../screenshots/03-public-bucket.png)

---

## 📸 Screenshot rules (for all 3)

- Capture the **query/filter + the matching entry** together — proves the rule selects the event.
- **Scrub before saving:** your `principalEmail` is your real Gmail — blur it if you prefer. Crop out the project number.
- Save all three into the `screenshots/` folder with the names above.

---

## Step 5 — Tear down (don't skip)

```bash
./scripts/teardown.sh
```

**You should see** lines removing the firewall (if created), bucket, SA binding, service account, and the local key file. This returns the project to a clean, $0 state.

```bash
Tearing down test resources in gcp-secmon-lab-kud01…
  [-] bucket gs://secmon-test-bucket-gcp-secmon-lab-kud01
bindings:
- members:
  - serviceAccount:932465506700@cloudservices.gserviceaccount.com
  role: roles/compute.instanceGroupManagerServiceAgent
- members:
  - serviceAccount:service-932465506700@compute-system.iam.gserviceaccount.com
  role: roles/compute.serviceAgent
- members:
  - serviceAccount:932465506700-compute@developer.gserviceaccount.com
  role: roles/editor
- members:
  - user:you@example.com
  role: roles/owner
etag: BwZToAYHjmQ=
version: 1
  [-] editor binding for test SA
  [-] service account secmon-test-sa@gcp-secmon-lab-kud01.iam.gserviceaccount.com
  [-] keys/secmon-test-sa-key.json
Done.
To remove EVERYTHING (the whole lab project): gcloud projects delete gcp-secmon-lab-kud01
```

---

## ✅ Done — checklist

- [x] `screenshots/01-iam-role-granted.png`
- [x] `screenshots/02-sa-key-created.png`
- [x] `screenshots/03-public-bucket.png`
- [x] `teardown.sh` run — no test resources left (verified: SA + bucket gone)

**Next:** tell me when the 3 screenshots are saved — I'll wire them into the README, then we flip the repo to **public** and add your **CV line**.
