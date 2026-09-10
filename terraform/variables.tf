variable "project_id" {
  description = "GCP project ID (the auto-generated ID, not the display name)."
  type        = string
}

variable "region" {
  description = "GCP region for all resources."
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment label, e.g. staging, dev."
  type        = string
  default     = "staging"
}

variable "ingestion_service_account" {
  description = "Service account email allowed to write to the raw landing bucket."
  type        = string
}

variable "pipeline_service_account" {
  description = "Service account email that reads raw data and writes to BigQuery."
  type        = string
}

variable "analyst_group" {
  description = "Optional Google group email for read-only analyst access to BigQuery. Leave blank to skip."
  type        = string
  default     = ""
}

variable "access_expiry" {
  description = "RFC3339 timestamp after which the raw-landing write IAM condition expires."
  type        = string
  default     = "2026-12-31T23:59:59Z"
}

variable "kms_key_name" {
  description = "Optional customer-managed KMS key for bucket encryption. Leave null to use Google-managed encryption."
  type        = string
  default     = null
}
