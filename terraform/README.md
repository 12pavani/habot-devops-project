# Task 1: Terraform Secure Staging Provisioning

**Submitted by:** [YOUR FULL NAME] — [YOUR EMAIL] — [YOUR PHONE]

## What this provisions

- **D0 Raw Landing** (`google_storage_bucket.raw_landing`) — a GCS bucket for
  unvalidated incoming data. Uniform bucket-level access + enforced public
  access prevention, versioning on, 30-day lifecycle deletion, and a
  time-bound IAM condition so write access expires automatically rather than
  relying on someone remembering to revoke it.
- **D1 Staged/Enforced** (`google_bigquery_dataset.staged_enforced`) — the
  validated BigQuery dataset, with a `student_onboarding` table matching the
  schema used in Task 3's serializer, and dataset-level IAM restricting write
  access to the pipeline service account only.
- **Row-level security** (`policies/rls_policies.sql`) — applied as DDL after
  `terraform apply`, since BigQuery row access policies aren't yet a stable
  native Terraform resource. Restricts analyst reads to their own region and
  to rows with explicit consent.

## How to run

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your actual project ID and service accounts

terraform init
terraform plan   -var-file=terraform.tfvars
terraform apply  -var-file=terraform.tfvars

# then apply row-level security
bq query --use_legacy_sql=false < policies/rls_policies.sql
```

## Design notes (for the presentation)

- **Least privilege**: every IAM binding is scoped to a single service
  account and a single role — no broad `roles/editor` or `roles/owner`
  grants.
- **Mistake-proofing over process**: the write-access IAM condition expires
  automatically (time-bound), and consent is enforced as a row-level filter
  rather than a policy analysts are trusted to follow manually.
- **`terraform.tfvars` is gitignored** — only the `.example` file is
  committed, so no real project IDs or service account emails ever land in
  version control.
