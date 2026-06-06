# 01 — Concepts (study this first)

A primer on the ideas this lab is built from. Read it once to understand *why* the commands in `02` and `03` do what they do. Every detection later maps back to something here.

---

## 1. The GCP resource hierarchy

Google Cloud organizes everything in a tree:

```
Organization              (your company / domain — optional for personal accounts)
└── Folder                (optional grouping)
    └── Project           ← the main unit. Our lab lives in ONE project: gcp-secmon-lab-kud01
        └── Resources     (buckets, VMs, service accounts, firewall rules…)
```

- A **project** is the billing + security boundary. Resources, IAM policies, and logs all belong to a project.
- A **billing account** is *separate* from the project — it pays for one or many projects. (That's why your budget alert attaches to the billing account, not the project.)

**Why it matters for security:** permissions and logging are scoped to levels of this tree. "Who can do what" is answered at the project level for us.

---

## 2. Identity & IAM (Identity and Access Management)

IAM answers one question: **who can do what, on which resource.**

- **Member** — *who*. Forms you'll see:
  - `user:alice@gmail.com` — a human
  - `serviceAccount:bot@project.iam.gserviceaccount.com` — a non-human identity (an app/script)
  - `group:...`, and the dangerous special ones: `allUsers` (literally anyone on the internet) and `allAuthenticatedUsers` (any Google account).
- **Role** — *what they can do*. A bundle of permissions.
  - **Primitive roles** (broad, legacy): `roles/owner`, `roles/editor`, `roles/viewer`. Editor/Owner are powerful — granting them is a red flag.
  - **Predefined roles** (scoped): e.g. `roles/storage.objectViewer`.
  - **Custom roles** (you define).
- **Binding** — the link: *this member* has *this role*.
- **`SetIamPolicy`** — the API call that changes bindings. **Memorize this name** — three of our detections watch for it.

**Why attackers care:** granting themselves `roles/editor` = instant broad control (privilege escalation), and it persists until someone notices.

---

## 3. Service accounts & keys

A **service account (SA)** is an identity for *software*, not a person — apps use it to call GCP APIs.

- A SA can be granted roles (just like a user).
- A **user-managed key** is a downloadable JSON private key that authenticates *as* that SA — **from anywhere, no MFA, no expiry by default.**

**Why attackers love SA keys:** a stolen key is a portable, long-lived credential that survives password resets and session revocation. Creating one (`CreateServiceAccountKey`) is a classic persistence + credential-theft move. In well-run orgs, user-managed keys are rare — so creation stands out.

The persistence kit, end to end:
```
CreateServiceAccount  →  SetIamPolicy (grant it a role)  →  CreateServiceAccountKey
   (new identity)          (give it power)                    (portable credential)
```

---

## 4. Audit logs — the SOC's raw material

GCP records control-plane activity as **audit logs**. Four streams:

| Stream | Default | Cost | Captures |
|---|---|---|---|
| **Admin Activity** | always on | free | config changes (create/modify/delete, IAM) |
| System Event | always on | free | GCP-initiated changes |
| Policy Denied | always on | free | blocked-by-policy attempts |
| **Data Access** | opt-in | billable | reads of data/config |

### Anatomy of a log entry (learn these fields)

Every detection is just a filter over these fields:

| Field | Meaning | Example |
|---|---|---|
| `logName` | which stream | `…cloudaudit.googleapis.com%2Factivity` (the `%2F` is a URL-encoded `/`) |
| `protoPayload.methodName` | **the API call made** — the single most important field | `SetIamPolicy`, `CreateServiceAccountKey` |
| `protoPayload.authenticationInfo.principalEmail` | **who** did it | `attacker@gmail.com` |
| `protoPayload.requestMetadata.callerIp` | **from where** | `203.0.113.5` |
| `protoPayload.resourceName` | **what** was acted on | `projects/.../serviceAccounts/...` |
| `protoPayload.serviceData.policyDelta` | the exact IAM change (bindings added/removed, audit-config changes) | — |

**Key idea:** an attacker who steals creds and acts leaves an *attributed, immutable* trail here — and they can't disable Admin Activity logging to hide it.

---

## 5. MITRE ATT&CK — the shared language of detection

[MITRE ATT&CK](https://attack.mitre.org/) is a public catalog of real adversary behavior, organized as:

- **Tactics** — the *why* (the goal): Persistence, Privilege Escalation, Defense Evasion, Collection…
- **Techniques** — the *how* (the method), with IDs: `T1098.001` (Additional Cloud Credentials), `T1530` (Data from Cloud Storage)…

We use the [**Cloud matrix**](https://attack.mitre.org/matrices/enterprise/cloud/). Mapping each detection to a technique ID is standard SOC practice — it lets teams measure *coverage* ("which attacker behaviors can we detect?") in a common vocabulary every analyst recognizes.

---

## 6. Detection engineering — the loop

A **detection** turns raw logs into an alert. The craft:

1. **Signal** — what does the attack look like in the logs? (which `methodName`, which field values)
2. **Filter** — write the query that isolates *just* that signal.
3. **Validate** — simulate the attack, confirm the rule fires (this lab's whole point).
4. **Tune** — reduce false positives (e.g. allow-list legitimate automation) without creating false negatives.

A good detection balances **coverage** (catches the real attack) against **noise** (doesn't fire on benign activity). That tradeoff — not the syntax — is the actual skill.

### Why simulate attacks from your own (owner) account?

A fair question: in this lab *you* run the "attacks", as the project owner. If you're the one doing it, what's the point?

- **A detection matches the *event*, not *who you are*.** When you grant `roles/editor`, the audit log entry is **structurally identical** to one a real attacker would produce using stolen owner credentials. The filter fires on the event signature, not your intent. So triggering it yourself generates real telemetry that proves: *if this happens in production, my rule catches it.* That's **detection validation** (a.k.a. purple teaming) — you're testing the sensor, not pretending to be a hacker.
- **Running as a privileged account is the realistic case.** The most common cloud breach pattern is a **compromised privileged identity** — an attacker phishes an admin, steals a key, or hijacks a session, then operates *as* that legitimate account. "The owner grants editor to a new principal" isn't unrealistic; it's the textbook compromised-admin attack. Detections also catch **insider threats and honest mistakes** — surfacing risky actions regardless of malice.
- **Production adds a judgment layer (tuning).** In the lab every actor is "expected" (it's you). In production you allow-list known admins/automation and alert on **anomalies** — an editor grant from an unusual IP, at an odd hour, to an unknown service account. The raw rule catches the event; tuning decides when it's worth waking someone up (see each detection's *Tuning notes*).

**Bottom line:** a detection you've never triggered is a guess; one you've triggered and watched fire is validated. The simulation is how you turn "I think this works" into evidence.

---

**Next:** **[02 — Enable Audit Logging](02-enable-audit-logging.md)** — put section 4 into practice.
