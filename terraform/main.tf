terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ------------------------------------------------------------------
# D0 Raw Landing — GCS bucket for unvalidated incoming data
# ------------------------------------------------------------------
resource "google_storage_bucket" "raw_landing" {
  name          = "${var.project_id}-d0-raw-landing"
  location      = var.region
  storage_class = "STANDARD"

  # Prevents public ACLs entirely — access is only via IAM, never
  # per-object ACLs. This is a hard security boundary, not optional.
  uniform_bucket_level_access = true

  # Belt-and-braces: block any public access even if a future policy
  # change tries to allow it.
  public_access_prevention = "enforced"

  versioning {
    enabled = true
  }

  # Raw landing data is transient — auto-delete after 30 days so
  # unvalidated data doesn't accumulate indefinitely.
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  # Encryption at rest with a customer-managed key, if provided.
  # Falls back to Google-managed encryption if kms_key_name is null.
  dynamic "encryption" {
    for_each = var.kms_key_name != null ? [1] : []
    content {
      default_kms_key_name = var.kms_key_name
    }
  }

  labels = {
    environment = var.environment
    data_stage  = "d0-raw-landing"
    managed_by  = "terraform"
  }
}

# Least-privilege IAM binding: only the ingestion service account can
# write to raw landing, and only during the staging assessment window.
# The IAM condition is the "mistake-proofing" control — access isn't
# just role-scoped, it's also time-bound.
resource "google_storage_bucket_iam_member" "raw_landing_writer" {
  bucket = google_storage_bucket.raw_landing.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${var.ingestion_service_account}"

  condition {
    title       = "staging-window-only"
    description = "Write access limited to the staging assessment window"
    expression  = "request.time < timestamp(\"${var.access_expiry}\")"
  }
}

resource "google_storage_bucket_iam_member" "raw_landing_reader" {
  bucket = google_storage_bucket.raw_landing.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.pipeline_service_account}"
}

# ------------------------------------------------------------------
# D1 Staged/Enforced — BigQuery dataset for validated data
# ------------------------------------------------------------------
resource "google_bigquery_dataset" "staged_enforced" {
  dataset_id  = "d1_staged_enforced"
  location    = var.region
  description = "Validated, schema-enforced data. Row-level security applied via policies.sql."

  # No default table expiration — this is the source of truth layer,
  # not a transient landing zone.
  default_table_expiration_ms = null

  labels = {
    environment = var.environment
    data_stage  = "d1-staged-enforced"
    managed_by  = "terraform"
  }
}

# Dataset-level least privilege: the pipeline SA can write, analysts
# can only read, and nobody gets OWNER except explicitly listed admins.
resource "google_bigquery_dataset_iam_member" "pipeline_writer" {
  dataset_id = google_bigquery_dataset.staged_enforced.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${var.pipeline_service_account}"
}

resource "google_bigquery_dataset_iam_member" "analyst_reader" {
  count      = length(var.analyst_group) > 0 ? 1 : 0
  dataset_id = google_bigquery_dataset.staged_enforced.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "group:${var.analyst_group}"
}

resource "google_bigquery_table" "student_onboarding" {
  dataset_id = google_bigquery_dataset.staged_enforced.dataset_id
  table_id   = "student_onboarding"

  schema = file("${path.module}/schemas/student_onboarding.json")

  deletion_protection = false # set true once this is a real environment

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}
