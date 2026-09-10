-- Row-Level Security policies for d1_staged_enforced.student_onboarding
--
-- NOTE: As of provider version ~5.0, Terraform's google-beta provider does
-- not have a stable first-class resource for BigQuery row access policies,
-- so these are applied as DDL after `terraform apply`. Run this with:
--
--   bq query --use_legacy_sql=false < policies/rls_policies.sql
--
-- or via `gcloud` / the BigQuery console. In a real pipeline this would run
-- as a post-apply step in CI, not a manual step — see the GitHub Actions
-- workflow (Task 2) for where this slots in.

-- Analysts can only see rows for their own assigned region. BigQuery RLS
-- has no built-in "caller's region" function, so this joins against a
-- small mapping table (analyst_region_map: user_email STRING, region STRING)
-- that HR/ops maintains — SESSION_USER() returns the caller's email.
CREATE ROW ACCESS POLICY IF NOT EXISTS region_scoped_access
ON `d1_staged_enforced.student_onboarding`
GRANT TO ("group:analysts@habot.io")
FILTER USING (
  region IN (
    SELECT region FROM `d1_staged_enforced.analyst_region_map`
    WHERE user_email = SESSION_USER()
  )
);

-- Only rows with explicit data-sharing consent are visible to the
-- analytics group at all — this is the "zero reliance on human
-- judgment" control: consent is enforced at the row level, not by
-- policy or process.
CREATE ROW ACCESS POLICY IF NOT EXISTS consent_required
ON `d1_staged_enforced.student_onboarding`
GRANT TO ("group:analysts@habot.io")
FILTER USING (consent_data_sharing = TRUE);
