# 00 — Prerequisites & Account Setup

Goal: get from a clean macOS machine to an authenticated `gcloud` CLI, a dedicated lab project, and a **budget alert** — before creating any billable resources.

> **Cost note:** Everything in this lab is designed to run inside Google Cloud's
> [Always Free tier](https://cloud.google.com/free/docs/free-cloud-features) plus the $300 free-trial credit.
> The budget alert in Step 5 is your tripwire against surprise spend.

---

## 1. Install the gcloud CLI

We use the **official interactive installer** (not Homebrew). Reason: the official installer bundles its own Python and keeps gcloud's built-in component manager (`gcloud components update`) working. The Homebrew cask disables the component manager and can conflict with a Homebrew-managed Python.

Official docs: <https://docs.cloud.google.com/sdk/docs/install-sdk>

**Apple Silicon (arm64):**

```bash
cd "$HOME"
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-darwin-arm.tar.gz
tar -xf google-cloud-cli-darwin-arm.tar.gz
rm -f google-cloud-cli-darwin-arm.tar.gz
./google-cloud-sdk/install.sh --quiet --usage-reporting=false --command-completion=true --path-update=true
```

> Intel Macs: swap `darwin-arm.tar.gz` → `darwin-x86_64.tar.gz`.
> Check your architecture with `uname -m` (`arm64` vs `x86_64`).

The installer adds gcloud to your `PATH` by appending a line to `~/.zshrc`.

## 2. Activate the PATH (open a NEW terminal)

The PATH change only applies to **new** shells.

```bash
# In a brand-new terminal window:
gcloud version          # expect: Google Cloud SDK 5xx.x.x
```

**Troubleshooting — `zsh: command not found: gcloud`:**
gcloud is installed but your shell didn't load the PATH line. Check that your `~/.zshrc` actually sources it and has no syntax error *above* the gcloud lines (an earlier error aborts the rest of the file):

```bash
grep -n google-cloud-sdk ~/.zshrc      # the path.zsh.inc line should be present
zsh -ic 'command -v gcloud'            # should print the gcloud path
```

## 3. Authenticate

Opens a browser — sign in and click **Allow**. gcloud stores a refresh token under `~/.config/gcloud/` and then acts as you.

```bash
gcloud auth login
```

## 4. Create the lab project

Project IDs are **globally unique across all of Google Cloud** and immutable. Pick a distinctive suffix; if it's taken, creation fails and you just choose another.

```bash
gcloud projects create gcp-secmon-lab-<unique> --name="GCP Security Monitoring Lab"
gcloud config set project gcp-secmon-lab-<unique>
gcloud config get-value project          # confirm the active project
```

## 5. Link billing and set a budget alert

A billing account and a project are separate resources — one billing account funds many projects, and a budget attaches to the **billing account**.

```bash
# Find your billing account ID (format: XXXXXX-XXXXXX-XXXXXX)
gcloud billing accounts list

# Link the project to it
gcloud billing projects link gcp-secmon-lab-<unique> --billing-account=XXXXXX-XXXXXX-XXXXXX
# expect: billingEnabled: true

# Enable the Budget API
gcloud services enable billingbudgets.googleapis.com

# Create a budget that emails you at 50% / 90% / 100% of spend
gcloud billing budgets create \
  --billing-account=XXXXXX-XXXXXX-XXXXXX \
  --display-name="gcp-secmon-lab budget alert" \
  --budget-amount=1<CURRENCY> \
  --threshold-rule=percent=0.5 \
  --threshold-rule=percent=0.9 \
  --threshold-rule=percent=1.0
```

> **Currency must match the billing account.** The budget amount has to be denominated in your billing account's own currency. Check it with:
> ```bash
> gcloud billing accounts describe XXXXXX-XXXXXX-XXXXXX --format="value(currencyCode)"
> ```
> Use that code as `<CURRENCY>` (e.g. `1USD`, `1AUD`, `1EUR`). A mismatch returns `INVALID_ARGUMENT`.

> **Budgets alert, they do not cap.** GCP budgets send notifications; they do not stop spending. Hard enforcement requires extra automation (a Cloud Function that disables billing). For this lab, the alert is sufficient.

---

## Security & hygiene notes

- **Never commit account-specific identifiers.** Billing account IDs, project numbers, and org IDs are kept as `XXXXXX-…` placeholders in this repo. Scrub them from any screenshot before publishing.
- The `gcloud auth login` token under `~/.config/gcloud/` is a live credential — it is **not** part of this repo and must never be committed.

Next: **[01 — Concepts](01-concepts.md)** — the ideas behind the lab (IAM, service accounts, audit logs, MITRE ATT&CK, detection engineering).
