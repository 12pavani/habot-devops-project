# Habot Connect — Junior Cloud & DevOps Engineer Hiring Project

**Candidate:** Vislavath Pavani<br>
**Email:** vislavathpavani5123@gmail.com<br>
**Phone:** 6009129509<br>
**Submitted:** 11 September 2026

## 1. What this project is

Habot Connect runs a Django REST Framework (DRF) backend and a React
frontend, deployed on Google Cloud Platform (GCP), connecting parents
with Learning Support Assistants for children with learning
difficulties.

The hiring brief describes a staging incident: a developer accidentally
pushed unencrypted API credentials into the codebase, and a database
schema mismatch broke downstream analytics. This project is the fix —
three pieces of work that both resolve the immediate incident and put
permanent guardrails in place so it can't quietly happen again.

## 2. How I approached it

I treated the three tasks as one connected system rather than three
separate exercises, because in a real incident they *are* connected:

1. **First, fix where the data lives** (Task 1) — provision secure
   cloud storage with the tightest access rules the situation allows,
   so "who can touch what" is defined in code, not tribal knowledge.
2. **Then, stop the mistake from ever being committed again** (Task 2)
   — an automated gate that inspects every change *before* it can
   reach staging, and blocks it outright rather than just warning.
3. **Finally, make bad data physically unable to enter the system**
   (Task 3) — validation strict enough that an API call with an
   ambiguous or out-of-range value is rejected, not "cleaned up later."

The same data shape (a student onboarding record) is defined once and
enforced identically at three layers — the API (Django), the database
schema (BigQuery table definition), and the access-control policy
(row-level security) — so there's one source of truth instead of three
definitions that could quietly drift apart.

## 3. Tools used, and why each one

| Tool | Used for | Why this one |
|---|---|---|
| **Terraform** | Defining GCS bucket + BigQuery dataset as code | Infrastructure changes become reviewable, versioned, and repeatable instead of manual console clicks nobody remembers |
| **Google Cloud Platform (GCS + BigQuery + IAM)** | The actual cloud resources: raw data storage, the validated data warehouse, access control | This is the stack Habot Connect specified in the brief |
| **GitHub Actions** | CI/CD pipeline that lints, validates, and scans every change | Free, tightly integrated with GitHub, and easy to make a merge-blocking required check |
| **gitleaks** | Scanning commits for hardcoded secrets (API keys, credentials) | Purpose-built, well-maintained secret scanner — this is exactly what caused the original incident in the brief |
| **black** | Python code formatting | Removes all debate about formatting style — code either matches or the build fails |
| **flake8** | Python linting (catches bugs, unused imports, style issues) | Standard, lightweight Python linter |
| **Django + Django REST Framework (DRF)** | The backend API and serializer that validates incoming data | This is the backend framework Habot Connect specified |
| **pytest** | Automated tests proving the validation logic actually works | Lets you *demonstrate*, not just claim, that invalid data gets rejected |

## 4. Project structure

```
habot-devops-project/
├── README.md                     ← you are here
├── .gitignore                    ← keeps secrets/state files out of git
├── .gitleaks.toml                ← secret-scanning rules (Task 2)
├── .github/
│   └── workflows/
│       └── ci.yml                ← the CI/CD fail-closed gate (Task 2)
├── terraform/                    ← Task 1
│   ├── main.tf                   ← the actual cloud resources
│   ├── variables.tf              ← inputs (project ID, region, etc.)
│   ├── outputs.tf                ← values Terraform prints after apply
│   ├── terraform.tfvars.example  ← template for your real values
│   ├── schemas/
│   │   └── student_onboarding.json   ← BigQuery table schema
│   ├── policies/
│   │   └── rls_policies.sql      ← row-level security rules
│   └── README.md                 ← Task 1 detail
└── django/                       ← Task 3
    ├── requirements.txt
    ├── dcyn/
    │   └── validators.py         ← the DCYN yes/no validation library
    ├── onboarding/
    │   ├── models.py             ← the database model
    │   ├── serializers.py        ← the DRF validation logic
    │   ├── sample_payload.json   ← example valid/invalid data
    │   └── tests.py              ← automated proof it works
    └── README.md                 ← Task 3 detail
```

## 5. Complete setup guide 

### 5.1 Install the tools on your computer

You need four things installed. Install them in this order:

1. **Git** — [git-scm.com/downloads](https://git-scm.com/downloads).
   Confirm it worked: open a terminal and run `git --version`.
2. **Python 3.12** — [python.org/downloads](https://www.python.org/downloads/).
   Confirm: `python3 --version`.
3. **Terraform** —
   [developer.hashicorp.com/terraform/install](https://developer.hashicorp.com/terraform/install).
   Confirm: `terraform --version`.
4. **Google Cloud CLI (`gcloud`)** —
   [cloud.google.com/sdk/docs/install](https://cloud.google.com/sdk/docs/install).
   Confirm: `gcloud --version`.

### 5.2 Create a GCP project (for Task 1)

1. Go to [console.cloud.google.com](https://console.cloud.google.com) and
   sign in (or create a free account — new accounts get $300 in credit).
2. Click the project dropdown at the top → **New Project**. Name it
   something like `habot-staging-assessment`. GCP will generate a
   **Project ID** underneath — copy this, it's not the same as the name.
3. Go to **Billing** in the left menu and link a billing account (required
   to enable APIs, even though you'll stay within free-tier usage).
4. Go to **APIs & Services → Enable APIs and Services**, and enable:
   - Cloud Storage API
   - BigQuery API
   - Identity and Access Management (IAM) API
5. Authenticate your terminal to this project:
   ```bash
   gcloud auth login
   gcloud config set project YOUR_PROJECT_ID
   gcloud auth application-default login
   ```

### 5.3 Set up and run Task 1 (Terraform)

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```
Open `terraform.tfvars` in any text editor and replace the placeholder
values with your real project ID. For the two service account emails,
you can either create real service accounts in GCP (**IAM & Admin →
Service Accounts → Create**) or leave placeholder-looking emails in —
what matters for the assessment is that the Terraform code is correct
and runnable, not that every account is a live production identity.

Then:
```bash
terraform init      # downloads the Google provider
terraform plan -var-file=terraform.tfvars    # shows what WOULD be created
terraform apply -var-file=terraform.tfvars   # actually creates it (optional)
```
`terraform plan` is safe to run any number of times — it only *previews*
changes, it doesn't create anything. `terraform apply` will actually
create real cloud resources (still within free tier, but real).

### 5.4 Set up and run Task 3 (Django / DRF validation)

```bash
cd django
pip install -r requirements.txt
pytest onboarding/tests.py -v
```
You should see 5 tests pass — 1 confirming a valid submission is
accepted, and 4 confirming different kinds of bad data (out-of-range
age, ambiguous yes/no value, missing consent, free-text region) are
each correctly rejected.

### 5.5 Push everything to GitHub and trigger Task 2 (the CI gate)

```bash
# from the top-level habot-devops-project folder
git init
git add .
git commit -m "Initial commit: Terraform, CI/CD gate, DRF serializer"
```
Then on [github.com](https://github.com), click **New repository**,
leave it empty (no README/gitignore — you already have them), and copy
the commands it shows you, which look like:
```bash
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git branch -M main
git push -u origin main
```

Once pushed, go to the **Actions** tab on GitHub — you should see the
"Poka-Yoke Build Gate" workflow run automatically and pass (green).

**To prove the fail-closed behavior for your presentation:**
1. Create a new branch: `git checkout -b demo-fail-closed`
2. Add a line like `SECRET_KEY = "sk_live_fake1234567890abcdef"` to any
   file in `django/`
3. Commit and push that branch, then open a Pull Request on GitHub
4. Watch the **Actions** tab — the `secret-scan` job should fail (red)
   within seconds. Screenshot this.
5. Remove the fake secret, commit again, push — watch it turn green.
   Screenshot this too.

Those two screenshots are your evidence for the brief's requirement to
"demonstrate how your automated build gate successfully triggers a
Fail-Closed status."
